/// The select group's demo: the exposed dropdown on filled and outlined
/// fields, Expressive's rounded and tonal forms, options with icons and
/// supporting lines, error, disabled and a disabled option, the open state
/// as it looks, and the combobox filtering as you type — every select live.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The select group's demo, in [brightness].
Widget kitSelectDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Select',
  sections: const <Widget>[
    _Styles(),
    _Expressive(),
    _Rich(),
    _Open(),
    _States(),
    _Combobox(),
  ],
);

const List<ExpressiveSelectOption<String>> _sizes =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption<String>('s', 'Small'),
      ExpressiveSelectOption<String>('m', 'Medium'),
      ExpressiveSelectOption<String>('l', 'Large'),
      ExpressiveSelectOption<String>('xl', 'Extra large'),
    ];

const List<ExpressiveSelectOption<String>> _delivery =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption<String>(
        'pickup',
        'Pick up in store',
        icon: ExpressiveSymbols.storefront,
        supportingText: 'Ready in 2 hours',
      ),
      ExpressiveSelectOption<String>(
        'standard',
        'Standard delivery',
        icon: ExpressiveSymbols.localShipping,
        supportingText: '3–5 days',
      ),
      ExpressiveSelectOption<String>(
        'express',
        'Express delivery',
        icon: ExpressiveSymbols.bolt,
        supportingText: 'Tomorrow before noon',
      ),
    ];

const List<ExpressiveSelectOption<String>> _plans =
    <ExpressiveSelectOption<String>>[
      ExpressiveSelectOption<String>('free', 'Free'),
      ExpressiveSelectOption<String>('plus', 'Plus'),
      ExpressiveSelectOption<String>('team', 'Team', enabled: false),
    ];

const List<String> _cities = <String>[
  'Amsterdam',
  'Barcelona',
  'Berlin',
  'Copenhagen',
  'Dublin',
  'Lisbon',
  'London',
  'Madrid',
  'Oslo',
  'Paris',
  'Porto',
  'Prague',
  'Rome',
  'Vienna',
];

/// A live select holding its own value.
class _Live extends StatefulWidget {
  const _Live({
    required this.options,
    required this.label,
    this.initial,
    this.style = ExpressiveTextFieldKind.filled,
    this.rounded = false,
    this.tonal = false,
    this.placeholder,
    this.leading,
    this.supportingText,
    this.errorText,
    this.enabled = true,
  });

  final List<ExpressiveSelectOption<String>> options;
  final String label;
  final String? initial;
  final ExpressiveTextFieldKind style;
  final bool rounded;
  final bool tonal;
  final String? placeholder;
  final Widget? leading;
  final String? supportingText;
  final String? errorText;
  final bool enabled;

  @override
  State<_Live> createState() => _LiveState();
}

class _LiveState extends State<_Live> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) => ExpressiveSelect<String>(
    options: widget.options,
    value: _value,
    onChanged: (value) => setState(() => _value = value),
    kind: widget.style,
    rounded: widget.rounded,
    tonal: widget.tonal,
    label: widget.label,
    hintText: widget.placeholder,
    leading: widget.leading,
    helperText: widget.supportingText,
    errorText: widget.errorText,
    enabled: widget.enabled,
  );
}

class _Styles extends StatelessWidget {
  const _Styles();

  @override
  Widget build(BuildContext context) => kitSection(
    'Filled and outlined',
    children: <Widget>[
      for (final style in ExpressiveTextFieldKind.values) ...<Widget>[
        _Live(
          style: style,
          options: _sizes,
          label: 'Size',
          placeholder: 'Choose a size',
        ),
        _Live(
          style: style,
          options: _sizes,
          label: 'Size',
          initial: 'm',
          supportingText: 'Fits true to size',
        ),
      ],
    ],
  );
}

class _Expressive extends StatelessWidget {
  const _Expressive();

  @override
  Widget build(BuildContext context) => kitSection(
    'Expressive rounded and tonal',
    children: const <Widget>[
      _Live(
        rounded: true,
        options: _sizes,
        label: 'Size',
        initial: 'l',
        leading: Icon(ExpressiveSymbols.sell),
      ),
      _Live(
        rounded: true,
        tonal: true,
        options: _sizes,
        label: 'Size',
        initial: 's',
        leading: Icon(ExpressiveSymbols.sell),
      ),
      _Live(
        style: ExpressiveTextFieldKind.outlined,
        rounded: true,
        tonal: true,
        options: _sizes,
        label: 'Size',
        initial: 'xl',
      ),
    ],
  );
}

class _Rich extends StatelessWidget {
  const _Rich();

  @override
  Widget build(BuildContext context) => kitSection(
    'Options with icons and a second line',
    children: const <Widget>[
      _Live(
        options: _delivery,
        label: 'Delivery',
        initial: 'standard',
        leading: Icon(ExpressiveSymbols.localShipping),
        supportingText: 'Free over €40',
      ),
    ],
  );
}

/// The open state as it looks: the field with its arrow turned up, the
/// menu at the field's width below it.
class _Open extends StatefulWidget {
  const _Open();

  @override
  State<_Open> createState() => _OpenState();
}

class _OpenState extends State<_Open> {
  var _selected = 'm';
  final _controller = TextEditingController(text: 'Medium');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// The width a select's field takes in a wide window: the text field's
  /// own (Compose's 280dp minimum), as the live selects above it stand.
  static const double _fieldWidth = 280;

  /// [child] as a select draws it: from [ExpressiveSelect.wideFrom], at its
  /// field's width at its column's start (its menu as wide as its field);
  /// at the select's widest (320) it stood out past the selects above.
  Widget _asSelect(BuildContext context, Widget child) =>
      MediaQuery.sizeOf(context).width < ExpressiveSelect.wideFrom
      ? child
      : Align(
          alignment: AlignmentDirectional.centerStart,
          child: SizedBox(width: _fieldWidth, child: child),
        );

  @override
  Widget build(BuildContext context) => kitSection(
    'Open',
    children: <Widget>[
      _asSelect(
        context,
        ExpressiveTextField(
          controller: _controller,
          readOnly: true,
          label: 'Size',
          trailing: const ExpressiveSelectTrailingIcon(expanded: true),
        ),
      ),
      _asSelect(
        context,
        ExpressiveMenuSurface(
          groups: <ExpressiveMenuGroup>[
            ExpressiveMenuGroup(<ExpressiveMenuEntry>[
              for (final option in _sizes)
                ExpressiveMenuRadioItem(
                  option.label,
                  selected: option.value == _selected,
                  check: false,
                  onSelected: () => setState(() {
                    _selected = option.value;
                    _controller.text = option.label;
                  }),
                ),
            ]),
          ],
        ),
      ),
    ],
  );
}

class _States extends StatelessWidget {
  const _States();

  @override
  Widget build(BuildContext context) => kitSection(
    'Error, disabled and a disabled option',
    children: const <Widget>[
      _Live(
        options: _sizes,
        label: 'Size',
        placeholder: 'Choose a size',
        errorText: 'Choose a size to add it to your bag',
      ),
      _Live(
        style: ExpressiveTextFieldKind.outlined,
        options: _sizes,
        label: 'Size',
        initial: 'm',
        enabled: false,
        supportingText: 'Sold out in other sizes',
      ),
      _Live(
        options: _plans,
        label: 'Plan',
        initial: 'free',
        supportingText: 'Team opens when you invite someone',
      ),
    ],
  );
}

class _Combobox extends StatelessWidget {
  const _Combobox();

  static final List<ExpressiveSelectOption<String>> _options =
      <ExpressiveSelectOption<String>>[
        for (final city in _cities)
          ExpressiveSelectOption<String>(
            city,
            city,
            icon: ExpressiveSymbols.locationOn,
          ),
      ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Combobox: type to filter',
    children: <Widget>[
      ExpressiveCombobox<String>(
        options: _options,
        label: 'Destination',
        hintText: 'Try “por”',
        leading: const Icon(ExpressiveSymbols.flight),
        helperText: 'Pick a city or type your own',
      ),
      ExpressiveCombobox<String>(
        kind: ExpressiveTextFieldKind.outlined,
        rounded: true,
        options: _options,
        label: 'Departing from',
        // Its options carry icons: the field's own leaves them their place.
        leading: const Icon(ExpressiveSymbols.locationOn),
      ),
      _ComboboxNoMatch(options: _options),
    ],
  );
}

/// A combobox holding words no city fits: opened, its menu says so.
class _ComboboxNoMatch extends StatefulWidget {
  const _ComboboxNoMatch({required this.options});

  final List<ExpressiveSelectOption<String>> options;

  @override
  State<_ComboboxNoMatch> createState() => _ComboboxNoMatchState();
}

class _ComboboxNoMatchState extends State<_ComboboxNoMatch> {
  final TextEditingController _text = TextEditingController(text: 'Atlantis');

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ExpressiveCombobox<String>(
    controller: _text,
    options: widget.options,
    label: 'Arriving at',
    leading: const Icon(ExpressiveSymbols.flight),
    helperText: 'Open it: no city is called that',
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// The closed field showing the chosen city.
Widget kitSpecimenSelectCity() => ExpressiveSelect<String>(
  options: const <ExpressiveSelectOption<String>>[
    ExpressiveSelectOption<String>('lisbon', 'Lisbon'),
    ExpressiveSelectOption<String>('porto', 'Porto'),
    ExpressiveSelectOption<String>('faro', 'Faro'),
  ],
  value: 'porto',
  onChanged: (_) {},
  label: 'City',
  leading: const Icon(ExpressiveSymbols.locationOn),
);

/// The editable field with its hint, before anything is typed.
Widget kitSpecimenComboboxDestination() => const ExpressiveCombobox<String>(
  options: <ExpressiveSelectOption<String>>[
    ExpressiveSelectOption<String>('lisbon', 'Lisbon'),
    ExpressiveSelectOption<String>('porto', 'Porto'),
  ],
  label: 'Destination',
  leading: Icon(ExpressiveSymbols.flight),
  helperText: 'Pick a city or type your own',
);
