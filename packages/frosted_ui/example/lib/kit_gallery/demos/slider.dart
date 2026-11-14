/// [FrostedSlider]: a continuous one, a stepped one on its beads, one with its
/// own words for the screen reader and an inert one; [FrostedRangeSlider]:
/// a span between two knobs.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitSliderDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Slider',
  sections: [
    kitSection(
      'Continuous',
      children: [
        _Held(
          0.35,
          (v, set) => FrostedSlider(value: v, label: 'Reach', onChanged: set),
        ),
      ],
    ),
    kitSection(
      'Stepped',
      children: [
        _Held(
          60,
          (v, set) => FrostedSlider(
            value: v,
            min: 0,
            max: 100,
            divisions: 10,
            label: 'Alert at',
            semanticFormatterCallback: (v) => '${v.round()}% of budget',
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Range',
      children: [
        KitHeld<DesignRangeValues>(
          const DesignRangeValues(20, 80),
          (span, set) => FrostedRangeSlider(
            values: span,
            max: 100,
            divisions: 20,
            minGap: 10,
            startLabel: 'Lowest',
            endLabel: 'Highest',
            semanticFormatterCallback: (v) => '${v.round()}',
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Inert',
      children: [
        const FrostedSlider(value: 0.5, label: 'Locked', onChanged: null),
      ],
    ),
    kitSection(
      'Specimens',
      children: [kitSpecimenSliderContinuous(), kitSpecimenSliderStepped()],
    ),
  ],
);

/// A continuous slider a third of the way.
Widget kitSpecimenSliderContinuous() =>
    FrostedSlider(value: 0.35, label: 'Reach', onChanged: (_) {});

/// A stepped slider on its beads, 60 of 100.
Widget kitSpecimenSliderStepped() => FrostedSlider(
  value: 60,
  min: 0,
  max: 100,
  divisions: 10,
  label: 'Alert at',
  semanticFormatterCallback: (v) => '${v.round()}% of budget',
  onChanged: (_) {},
);

/// The page's own value, kept for the demo.
class _Held extends StatefulWidget {
  const _Held(this.initial, this.builder);

  final double initial;
  final Widget Function(double value, ValueChanged<double> set) builder;

  @override
  State<_Held> createState() => _HeldState();
}

class _HeldState extends State<_Held> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

/// A price between two thumbs.
Widget kitSpecimenRangeSlider() => FrostedRangeSlider(
  values: const DesignRangeValues(20, 80),
  max: 100,
  onChanged: (_) {},
  startLabel: 'Lowest price',
  endLabel: 'Highest price',
);
