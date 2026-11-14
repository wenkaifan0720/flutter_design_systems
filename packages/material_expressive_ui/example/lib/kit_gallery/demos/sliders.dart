/// The sliders group's demo: the five track sizes (with inset icons on the
/// thick ones), stops with the value indicator, the centred track, the
/// range slider, vertical sliders as a mixer, the disabled states, and the
/// quantity stepper on a cart — every control live, so press, drag, focus
/// and the indicator show on the real thing.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

import '../kit.dart';

/// The sliders group's demo, in [brightness].
Widget kitSlidersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Sliders',
  sections: const <Widget>[
    _Sizes(),
    _Stops(),
    _Centred(),
    _Range(),
    _Mixer(),
    _Disabled(),
    _Cart(),
  ],
);

/// A caption over a control.
Widget _caption(BuildContext context, String text, [String? value]) {
  final t = context.expressiveTheme;
  return Row(
    children: <Widget>[
      Expanded(
        child: Text(
          text,
          style: t.type.labelLarge.copyWith(color: t.colors.onSurface),
        ),
      ),
      if (value != null)
        Text(
          value,
          style: t.type.labelLarge.copyWith(color: t.colors.onSurfaceVariant),
        ),
    ],
  );
}

/// A captioned control.
Widget _labelled(
  BuildContext context,
  String caption,
  Widget control, [
  String? value,
]) => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[_caption(context, caption, value), control],
);

String _percent(double v) => '${(v * 100).round()}%';

class _Sizes extends StatefulWidget {
  const _Sizes();

  @override
  State<_Sizes> createState() => _SizesState();
}

class _SizesState extends State<_Sizes> {
  final Map<ExpressiveSliderSize, double> _values =
      <ExpressiveSliderSize, double>{
        ExpressiveSliderSize.extraSmall: 0.35,
        ExpressiveSliderSize.small: 0.5,
        ExpressiveSliderSize.medium: 0.62,
        ExpressiveSliderSize.large: 0.4,
        ExpressiveSliderSize.extraLarge: 0.72,
      };

  static const Map<ExpressiveSliderSize, (String, IconData?)> _labels =
      <ExpressiveSliderSize, (String, IconData?)>{
        ExpressiveSliderSize.extraSmall: ('XS · Playback', null),
        ExpressiveSliderSize.small: ('S · Text size', null),
        ExpressiveSliderSize.medium: ('M · Volume', ExpressiveSymbols.volumeUp),
        ExpressiveSliderSize.large: (
          'L · Brightness',
          ExpressiveSymbols.lightMode,
        ),
        ExpressiveSliderSize.extraLarge: (
          'XL · Warmth',
          ExpressiveSymbols.thermostat,
        ),
      };

  @override
  Widget build(BuildContext context) => kitSection(
    'Sizes',
    children: <Widget>[
      for (final size in ExpressiveSliderSize.values)
        _labelled(
          context,
          _labels[size]!.$1,
          ExpressiveSlider(
            value: _values[size]!,
            size: size,
            icon: _labels[size]!.$2,
            semanticLabel: _labels[size]!.$1,
            valueLabel: _percent,
            onChanged: (v) => setState(() => _values[size] = v),
          ),
          _percent(_values[size]!),
        ),
    ],
  );
}

class _Stops extends StatefulWidget {
  const _Stops();

  @override
  State<_Stops> createState() => _StopsState();
}

class _StopsState extends State<_Stops> {
  double _rating = 6;
  double _roast = 2;

  static const List<String> _roasts = <String>[
    'Light',
    'Medium-light',
    'Medium',
    'Medium-dark',
    'Dark',
  ];

  @override
  Widget build(BuildContext context) => kitSection(
    'Stops and ticks',
    children: <Widget>[
      _labelled(
        context,
        'Rate the walk',
        ExpressiveSlider(
          value: _rating,
          min: 0,
          max: 10,
          steps: 9,
          semanticLabel: 'Rate the walk',
          valueLabel: (v) => '${v.round()}',
          onChanged: (v) => setState(() => _rating = v),
        ),
        '${_rating.round()} / 10',
      ),
      _labelled(
        context,
        'Roast',
        ExpressiveSlider(
          value: _roast,
          min: 0,
          max: 4,
          steps: 3,
          size: ExpressiveSliderSize.medium,
          semanticLabel: 'Roast',
          valueLabel: (v) => _roasts[v.round()],
          onChanged: (v) => setState(() => _roast = v),
        ),
        _roasts[_roast.round()],
      ),
    ],
  );
}

class _Centred extends StatefulWidget {
  const _Centred();

  @override
  State<_Centred> createState() => _CentredState();
}

class _CentredState extends State<_Centred> {
  double _exposure = 0.6;
  double _balance = -2;

  String _signed(double v, [int digits = 1]) =>
      '${v > 0 ? '+' : ''}${v.toStringAsFixed(digits)}';

  @override
  Widget build(BuildContext context) => kitSection(
    'Centred',
    children: <Widget>[
      _labelled(
        context,
        'Exposure',
        ExpressiveSlider(
          value: _exposure,
          min: -2,
          max: 2,
          centered: true,
          size: ExpressiveSliderSize.small,
          semanticLabel: 'Exposure',
          valueLabel: _signed,
          onChanged: (v) => setState(() => _exposure = v),
        ),
        _signed(_exposure),
      ),
      _labelled(
        context,
        'Balance',
        ExpressiveSlider(
          value: _balance,
          min: -5,
          max: 5,
          steps: 9,
          centered: true,
          semanticLabel: 'Balance',
          valueLabel: (v) => _signed(v, 0),
          onChanged: (v) => setState(() => _balance = v),
        ),
        _balance == 0
            ? 'Centre'
            : '${_balance.abs().round()} ${_balance < 0 ? 'left' : 'right'}',
      ),
    ],
  );
}

class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  double _low = 40;
  double _high = 180;
  double _from = 8;
  double _to = 18;

  String _hour(double v) => '${v.round().toString().padLeft(2, '0')}:00';

  @override
  Widget build(BuildContext context) => kitSection(
    'Range',
    children: <Widget>[
      _labelled(
        context,
        'Price per night',
        ExpressiveRangeSlider(
          start: _low,
          end: _high,
          min: 0,
          max: 300,
          valueLabel: (v) => '\$${v.round()}',
          startSemanticLabel: 'Lowest price',
          endSemanticLabel: 'Highest price',
          onChanged: (s, e) => setState(() {
            _low = s;
            _high = e;
          }),
        ),
        '\$${_low.round()} – \$${_high.round()}',
      ),
      _labelled(
        context,
        'Quiet hours',
        ExpressiveRangeSlider(
          start: _from,
          end: _to,
          min: 6,
          max: 24,
          steps: 17,
          size: ExpressiveSliderSize.small,
          valueLabel: _hour,
          startSemanticLabel: 'Quiet from',
          endSemanticLabel: 'Quiet until',
          onChanged: (s, e) => setState(() {
            _from = s;
            _to = e;
          }),
        ),
        '${_hour(_from)} – ${_hour(_to)}',
      ),
    ],
  );
}

class _Mixer extends StatefulWidget {
  const _Mixer();

  @override
  State<_Mixer> createState() => _MixerState();
}

class _MixerState extends State<_Mixer> {
  final List<double> _bands = <double>[0.7, 0.45, 0.3, 0.55, 0.8];

  static const List<String> _names = <String>['60', '250', '1k', '4k', '12k'];

  static const List<ExpressiveSliderSize> _sizes = <ExpressiveSliderSize>[
    ExpressiveSliderSize.extraSmall,
    ExpressiveSliderSize.small,
    ExpressiveSliderSize.medium,
    ExpressiveSliderSize.small,
    ExpressiveSliderSize.extraSmall,
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Vertical',
      children: <Widget>[
        SizedBox(
          height: ExpressiveSpacing.s72 * 3,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              for (var i = 0; i < _bands.length; i++)
                Column(
                  children: <Widget>[
                    Expanded(
                      child: ExpressiveVerticalSlider(
                        value: _bands[i],
                        size: _sizes[i],
                        topToBottom: false,
                        semanticLabel: '${_names[i]} Hz',
                        valueLabel: _percent,
                        onChanged: (v) => setState(() => _bands[i] = v),
                      ),
                    ),
                    const SizedBox(height: ExpressiveSpacing.s4),
                    Text(
                      _names[i],
                      style: t.type.labelMedium.copyWith(
                        color: t.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Disabled extends StatelessWidget {
  const _Disabled();

  @override
  Widget build(BuildContext context) => kitSection(
    'Disabled',
    children: <Widget>[
      _labelled(
        context,
        'Download quality',
        const ExpressiveSlider(
          value: 0.6,
          steps: 3,
          onChanged: null,
          semanticLabel: 'Download quality',
        ),
      ),
      _labelled(
        context,
        'Delivery window',
        const ExpressiveRangeSlider(
          start: 0.2,
          end: 0.7,
          size: ExpressiveSliderSize.small,
          startSemanticLabel: 'Deliver from',
          endSemanticLabel: 'Deliver until',
          onChanged: null,
        ),
      ),
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: const ExpressiveNumberField(value: 1, onChanged: null),
      ),
    ],
  );
}

class _Cart extends StatefulWidget {
  const _Cart();

  @override
  State<_Cart> createState() => _CartState();
}

class _CartState extends State<_Cart> {
  final List<(String, String, int)> _items = <(String, String, int)>[
    ('Cold brew concentrate', '1 L bottle', 12),
    ('Oat milk', 'Barista edition', 4),
    ('Sourdough loaf', 'Baked this morning', 7),
  ];
  final List<int> _counts = <int>[2, 1, 0];
  int _guests = 4;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return kitSection(
      'Quantity stepper',
      children: <Widget>[
        for (var i = 0; i < _items.length; i++)
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _items[i].$1,
                      style: t.type.bodyLarge.copyWith(
                        color: t.colors.onSurface,
                      ),
                    ),
                    Text(
                      '${_items[i].$2} · \$${_items[i].$3}',
                      style: t.type.bodyMedium.copyWith(
                        color: t.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              ExpressiveNumberField(
                value: _counts[i],
                max: 9,
                label: _items[i].$1,
                onChanged: (v) => setState(() => _counts[i] = v),
              ),
            ],
          ),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Guests',
                style: t.type.bodyLarge.copyWith(color: t.colors.onSurface),
              ),
            ),
            ExpressiveNumberField(
              value: _guests,
              min: 1,
              max: 12,
              label: 'Guests',
              format: (v) => v == 1 ? '1 guest' : '$v guests',
              onChanged: (v) => setState(() => _guests = v),
            ),
          ],
        ),
      ],
    );
  }
}

// Catalog specimens (docs/architecture/component-catalog.md).

/// A continuous volume with its glyph on the track.
Widget kitSpecimenSliderVolume() => ExpressiveSlider(
  value: 0.6,
  size: ExpressiveSliderSize.medium,
  icon: ExpressiveSymbols.volumeUp,
  semanticLabel: 'Volume',
  onChanged: (_) {},
);

/// Three bands of an equaliser, stood on end.
Widget kitSpecimenVerticalSliderBands() => SizedBox(
  height: ExpressiveSpacing.s72 * 3,
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: <Widget>[
      for (final (value, name) in const <(double, String)>[
        (0.7, '60 Hz'),
        (0.4, '1 kHz'),
        (0.55, '8 kHz'),
      ])
        ExpressiveVerticalSlider(
          value: value,
          topToBottom: false,
          size: ExpressiveSliderSize.medium,
          semanticLabel: name,
          onChanged: (_) {},
        ),
    ],
  ),
);

/// A price range between two handles.
Widget kitSpecimenRangeSliderPrice() => ExpressiveRangeSlider(
  start: 60,
  end: 180,
  min: 0,
  max: 300,
  startSemanticLabel: 'Lowest price',
  endSemanticLabel: 'Highest price',
  onChanged: (_, _) {},
);

/// Two guests between − and +.
Widget kitSpecimenQuantityStepperGuests() => Center(
  child: ExpressiveNumberField(
    value: 2,
    min: 1,
    max: 8,
    label: 'Guests',
    onChanged: (_) {},
  ),
);
