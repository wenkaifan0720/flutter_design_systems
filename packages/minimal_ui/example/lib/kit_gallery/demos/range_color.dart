/// A slider with two thumbs, and a colour picker: the shade area, hue and
/// alpha tracks, a hex field and swatches.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

String _dollars(double v) => '\$${v.round()}';

Widget kitRangeColorDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Range slider & colour picker',
  sections: [
    kitSection(
      'Range',
      children: [
        const _Price(),
        kitNote(
          'Each thumb is its own slider to the keyboard and a screen reader; '
          'they never cross.',
        ),
      ],
    ),
    kitSection(
      'Stepped',
      children: [
        MinimalRangeSlider(
          label: 'Hours',
          values: const DesignRangeValues(9, 17),
          min: 0,
          max: 24,
          divisions: 24,
          format: (v) => '${v.round()}:00',
          onChanged: (_) {},
        ),
        const MinimalRangeSlider(
          label: 'Locked',
          values: DesignRangeValues(0.2, 0.6),
        ),
      ],
    ),
    kitSection('Colour', children: const [_Colour()]),
  ],
);

class _Price extends StatefulWidget {
  const _Price();

  @override
  State<_Price> createState() => _PriceState();
}

class _PriceState extends State<_Price> {
  DesignRangeValues _price = const DesignRangeValues(40, 220);

  @override
  Widget build(BuildContext context) => MinimalRangeSlider(
    label: 'Price',
    values: _price,
    min: 0,
    max: 400,
    minGap: 20,
    format: _dollars,
    onChanged: (v) => setState(() => _price = v),
  );
}

const List<Color> _swatches = [
  Color(0xFF111827),
  Color(0xFF2563EB),
  Color(0xFF059669),
  Color(0xFFD97706),
  Color(0xFFDC2626),
  Color(0xFF7C3AED),
];

class _Colour extends StatefulWidget {
  const _Colour();

  @override
  State<_Colour> createState() => _ColourState();
}

class _ColourState extends State<_Colour> {
  Color _colour = const Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: MinimalColorPicker(
      value: _colour,
      showAlpha: true,
      swatches: _swatches,
      onChanged: (c) => setState(() => _colour = c),
    ),
  );
}

// --- catalog specimens -------------------------------------------------------

/// A price range between two thumbs.
Widget kitSpecimenRangeSlider() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalRangeSlider(
    label: 'Price',
    values: const DesignRangeValues(40, 220),
    min: 0,
    max: 400,
    format: _dollars,
    onChanged: (_) {},
  ),
);

/// The picker on a blue, with swatches.
Widget kitSpecimenColorPicker() => Center(
  child: SizedBox(
    width: 300,
    child: MinimalColorPicker(
      value: const Color(0xFF2563EB),
      swatches: _swatches,
      onChanged: (_) {},
    ),
  ),
);
