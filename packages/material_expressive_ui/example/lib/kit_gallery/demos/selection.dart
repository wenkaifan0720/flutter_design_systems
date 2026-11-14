/// The selection group's demo: the checkbox (checked, unchecked,
/// indeterminate, error, disabled), the radio group, the switch with and
/// without its thumb icons, and each control's labelled row — every one
/// live, so press, focus and hover show on the real thing.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The selection group's demo, in [brightness].
Widget kitSelectionDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Selection controls',
  sections: const <Widget>[
    _CheckboxStates(),
    _Checklist(),
    _RadioStates(),
    _Delivery(),
    _SwitchStates(),
    _Settings(),
  ],
);

/// A caption under a control in a state grid.
Widget _caption(BuildContext context, String text) {
  final t = context.expressiveTheme;
  return Text(
    text,
    style: t.type.labelMedium.copyWith(color: t.colors.onSurfaceVariant),
  );
}

/// One control over its caption, which is its name: the two are one node to
/// assistive technology.
Widget _cell(BuildContext context, String caption, Widget control) =>
    MergeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[control, _caption(context, caption)],
      ),
    );

/// Controls in a wrapping grid, each over its caption.
Widget _grid(BuildContext context, List<(String, Widget)> cells) => Wrap(
  spacing: ExpressiveSpacing.s16,
  runSpacing: ExpressiveSpacing.s8,
  children: <Widget>[
    for (final (caption, control) in cells) _cell(context, caption, control),
  ],
);

class _CheckboxStates extends StatefulWidget {
  const _CheckboxStates();

  @override
  State<_CheckboxStates> createState() => _CheckboxStatesState();
}

class _CheckboxStatesState extends State<_CheckboxStates> {
  bool _live = true;
  bool? _tri;

  @override
  Widget build(BuildContext context) => kitSection(
    'Checkbox',
    children: <Widget>[
      _grid(context, <(String, Widget)>[
        (
          'Tap me',
          ExpressiveCheckbox(
            value: _live,
            onChanged: (v) => setState(() => _live = v),
          ),
        ),
        (
          'Tri-state',
          ExpressiveCheckbox(
            value: _tri,
            tristate: true,
            onChanged: (_) => setState(
              () => _tri = switch (_tri) {
                false => true,
                true => null,
                null => false,
              },
            ),
          ),
        ),
        ('Unchecked', const _LiveCheckbox(value: false)),
        ('Checked', const _LiveCheckbox(value: true)),
        ('Mixed', const _LiveCheckbox(value: null, tristate: true)),
      ]),
      _grid(context, <(String, Widget)>[
        ('Error', const _LiveCheckbox(value: false, isError: true)),
        ('Error on', const _LiveCheckbox(value: true, isError: true)),
        ('Disabled', ExpressiveCheckbox(value: false, onChanged: null)),
        ('Disabled on', ExpressiveCheckbox(value: true, onChanged: null)),
        (
          'Disabled mixed',
          ExpressiveCheckbox(value: null, tristate: true, onChanged: null),
        ),
      ]),
    ],
  );
}

class _LiveCheckbox extends StatefulWidget {
  const _LiveCheckbox({
    required this.value,
    this.tristate = false,
    this.isError = false,
  });

  final bool? value;
  final bool tristate;
  final bool isError;

  @override
  State<_LiveCheckbox> createState() => _LiveCheckboxState();
}

class _LiveCheckboxState extends State<_LiveCheckbox> {
  late bool? _value = widget.value;

  @override
  Widget build(BuildContext context) => ExpressiveCheckbox(
    value: _value,
    tristate: widget.tristate,
    isError: widget.isError,
    onChanged: (_) => setState(
      () => _value = widget.tristate
          ? switch (_value) {
              false => true,
              true => null,
              null => false,
            }
          : _value != true,
    ),
  );
}

/// A packing list: a "pack everything" parent over its items, the parent
/// indeterminate while some are packed.
class _Checklist extends StatefulWidget {
  const _Checklist();

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  var _accepted = false;
  final Map<String, bool> _items = <String, bool>{
    'Rain shell': true,
    'Trail snacks': false,
    'Headlamp': false,
  };

  bool? get _all {
    final packed = _items.values.where((v) => v).length;
    if (packed == 0) return false;
    return packed == _items.length ? true : null;
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Checkbox rows',
    children: <Widget>[
      ExpressiveCheckboxRow(
        label: 'Pack everything',
        supportingText: 'Weekend hike, 3 items',
        value: _all,
        tristate: true,
        onChanged: (v) => setState(() {
          for (final key in _items.keys) {
            _items[key] = v;
          }
        }),
      ),
      for (final entry in _items.entries)
        ExpressiveCheckboxRow(
          label: entry.key,
          value: entry.value,
          onChanged: (v) => setState(() => _items[entry.key] = v),
        ),
      ExpressiveCheckboxRow(
        label: 'Accept the trail rules',
        supportingText: 'Required before you book',
        value: _accepted,
        isError: true,
        onChanged: (value) => setState(() => _accepted = value),
      ),
      const ExpressiveCheckboxRow(
        label: 'Bear canister (sold out)',
        value: false,
        enabled: false,
        onChanged: _ignore,
      ),
    ],
  );
}

void _ignore(bool _) {}

void _noop() {}

class _RadioStates extends StatefulWidget {
  const _RadioStates();

  @override
  State<_RadioStates> createState() => _RadioStatesState();
}

class _RadioStatesState extends State<_RadioStates> {
  int _pick = 0;

  @override
  Widget build(BuildContext context) => kitSection(
    'Radio button',
    children: <Widget>[
      _grid(context, <(String, Widget)>[
        for (var i = 0; i < 3; i++)
          (
            'Option ${i + 1}',
            ExpressiveRadio(
              selected: _pick == i,
              onPressed: () => setState(() => _pick = i),
            ),
          ),
        // Disabled, not non-interactive: a radio with no callback drops its
        // 48dp target (Compose's onClick = null) and would sit off the
        // row's centre line beside the live ones.
        (
          'Disabled',
          const ExpressiveRadio(
            selected: false,
            enabled: false,
            onPressed: _noop,
          ),
        ),
        (
          'Disabled on',
          const ExpressiveRadio(
            selected: true,
            enabled: false,
            onPressed: _noop,
          ),
        ),
      ]),
      for (final (i, label) in <String>[
        'Pick up in store',
        'Ship to me',
      ].indexed)
        ExpressiveRadioRow(
          label: label,
          selected: _pick == i,
          onPressed: () => setState(() => _pick = i),
        ),
    ],
  );
}

class _Delivery extends StatefulWidget {
  const _Delivery();

  @override
  State<_Delivery> createState() => _DeliveryState();
}

class _DeliveryState extends State<_Delivery> {
  String _speed = 'standard';

  @override
  Widget build(BuildContext context) => kitSection(
    'Radio group',
    children: <Widget>[
      ExpressiveRadioGroup<String>(
        semanticLabel: 'Delivery speed',
        value: _speed,
        onChanged: (v) => setState(() => _speed = v),
        options: const <ExpressiveRadioOption<String>>[
          ExpressiveRadioOption<String>(
            value: 'standard',
            label: 'Standard',
            supportingText: 'Free · 3 to 5 days',
          ),
          ExpressiveRadioOption<String>(
            value: 'express',
            label: 'Express',
            supportingText: '\$6 · tomorrow',
          ),
          ExpressiveRadioOption<String>(
            value: 'courier',
            label: 'Same-day courier',
            supportingText: 'Not available at your address',
            enabled: false,
          ),
        ],
      ),
    ],
  );
}

class _SwitchStates extends StatefulWidget {
  const _SwitchStates();

  @override
  State<_SwitchStates> createState() => _SwitchStatesState();
}

class _SwitchStatesState extends State<_SwitchStates> {
  bool _plain = true;
  bool _icon = true;
  bool _both = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Switch',
    children: <Widget>[
      _grid(context, <(String, Widget)>[
        (
          'Plain',
          ExpressiveSwitch(
            value: _plain,
            onChanged: (v) => setState(() => _plain = v),
          ),
        ),
        (
          'Check icon',
          ExpressiveSwitch(
            value: _icon,
            checkedIcon: Icon(ExpressiveSymbols.check),
            onChanged: (v) => setState(() => _icon = v),
          ),
        ),
        (
          'Both icons',
          ExpressiveSwitch(
            value: _both,
            checkedIcon: Icon(ExpressiveSymbols.check),
            uncheckedIcon: Icon(ExpressiveSymbols.close),
            onChanged: (v) => setState(() => _both = v),
          ),
        ),
      ]),
      _grid(context, <(String, Widget)>[
        ('Disabled off', ExpressiveSwitch(value: false, onChanged: null)),
        ('Disabled on', ExpressiveSwitch(value: true, onChanged: null)),
        (
          'Disabled icon',
          ExpressiveSwitch(
            value: true,
            checkedIcon: Icon(ExpressiveSymbols.check),
            onChanged: null,
          ),
        ),
      ]),
    ],
  );
}

class _Settings extends StatefulWidget {
  const _Settings();

  @override
  State<_Settings> createState() => _SettingsState();
}

class _SettingsState extends State<_Settings> {
  bool _quiet = true;
  bool _digest = false;
  bool _location = true;

  @override
  Widget build(BuildContext context) => kitSection(
    'Switch rows',
    children: <Widget>[
      ExpressiveSwitchRow(
        label: 'Quiet hours',
        supportingText: '10 pm to 7 am, calls from favourites ring',
        value: _quiet,
        checkedIcon: Icon(ExpressiveSymbols.bedtime),
        onChanged: (v) => setState(() => _quiet = v),
      ),
      ExpressiveSwitchRow(
        label: 'Weekly digest',
        value: _digest,
        onChanged: (v) => setState(() => _digest = v),
      ),
      ExpressiveSwitchRow(
        label: 'Share trip location',
        value: _location,
        checkedIcon: Icon(ExpressiveSymbols.check),
        uncheckedIcon: Icon(ExpressiveSymbols.close),
        onChanged: (v) => setState(() => _location = v),
      ),
      const ExpressiveSwitchRow(
        label: 'Managed by your workspace',
        value: true,
        enabled: false,
        onChanged: _ignore,
      ),
    ],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A checked box beside an unchecked one.
Widget kitSpecimenCheckboxPair() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    ExpressiveCheckbox(value: true, onChanged: (_) {}, semanticLabel: 'Tent'),
    ExpressiveCheckbox(value: false, onChanged: (_) {}, semanticLabel: 'Stove'),
  ],
);

/// A checked row with its supporting line.
Widget kitSpecimenCheckboxRowChecked() => const ExpressiveCheckboxRow(
  label: 'Pack the rain shell',
  supportingText: 'Showers after noon',
  value: true,
  onChanged: _ignore,
);

/// Three delivery speeds, one chosen and one unavailable.
Widget kitSpecimenRadioGroupDelivery() => ExpressiveRadioGroup<String>(
  semanticLabel: 'Delivery speed',
  value: 'express',
  onChanged: (_) {},
  options: const <ExpressiveRadioOption<String>>[
    ExpressiveRadioOption<String>(
      value: 'standard',
      label: 'Standard',
      supportingText: 'Free · 3 to 5 days',
    ),
    ExpressiveRadioOption<String>(
      value: 'express',
      label: 'Express',
      supportingText: '\$6 · tomorrow',
    ),
    ExpressiveRadioOption<String>(
      value: 'courier',
      label: 'Same-day courier',
      supportingText: 'Not available at your address',
      enabled: false,
    ),
  ],
);

/// A switch on beside one off.
Widget kitSpecimenSwitchPair() => Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: <Widget>[
    ExpressiveSwitch(value: true, onChanged: (_) {}, semanticLabel: 'Wi-Fi'),
    const SizedBox(width: ExpressiveSpacing.s24),
    ExpressiveSwitch(
      value: false,
      onChanged: (_) {},
      semanticLabel: 'Bluetooth',
    ),
  ],
);

/// A settings row, on.
Widget kitSpecimenSwitchRowOn() => const ExpressiveSwitchRow(
  label: 'Trip reminders',
  supportingText: 'A day before you leave',
  value: true,
  onChanged: _ignore,
);
