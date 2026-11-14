/// Fluent 2's range and score controls by its spec: the slider (both
/// sizes, stepped, with its value, disabled), the spin button (outline
/// and filled, at a bound, formatted, disabled), the rating (the three
/// colours, the sizes, halves, disabled) and the rating display (with
/// its value and count, compact), each live.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

import '../kit.dart';

class _Live<T> extends StatefulWidget {
  const _Live(this.initial, this.builder);

  final T initial;
  final Widget Function(T value, ValueChanged<T> set) builder;

  @override
  State<_Live<T>> createState() => _LiveState<T>();
}

class _LiveState<T> extends State<_Live<T>> {
  late T _value = widget.initial;

  @override
  Widget build(BuildContext context) =>
      widget.builder(_value, (v) => setState(() => _value = v));
}

Widget kitSliderDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Slider, spin button, rating',
  sections: [
    kitSection('Slider', children: [kitSpecimenSlider()]),
    kitSection(
      'Slider, small and stepped',
      children: [kitSpecimenSliderStepped()],
    ),
    kitSection(
      'Slider, disabled',
      children: [
        const Fluent2Slider(
          label: 'Meeting volume',
          value: 40,
          onChanged: null,
        ),
      ],
    ),
    kitSection('Spin button', children: [kitSpecimenSpinButton()]),
    kitSection(
      'Spin button, at its bounds',
      children: [kitSpecimenSpinBounds()],
    ),
    kitSection('Rating', children: [kitSpecimenRating()]),
    kitSection('Rating, colours', children: [kitSpecimenRatingColors()]),
    kitSection(
      'Rating, sizes and halves',
      children: [
        for (final size in Fluent2RatingSize.values)
          _Live<double>(
            3.5,
            (v, set) => Fluent2Rating(
              label: 'Rate the ${kitSay(size)} sample',
              value: v,
              allowHalf: true,
              size: size,
              color: Fluent2RatingColor.brand,
              onChanged: set,
            ),
          ),
        const Fluent2Rating(
          label: 'Rating, disabled',
          value: 2,
          onChanged: null,
        ),
      ],
    ),
    kitSection('Rating display', children: [kitSpecimenRatingDisplay()]),
    kitSection(
      'Rating display, compact',
      children: [kitSpecimenRatingCompact()],
    ),
  ],
);

Widget kitSpecimenSlider() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _Live<double>(
      60,
      (v, set) => Fluent2Slider(label: 'Volume', value: v, onChanged: set),
    ),
    _Live<double>(
      30,
      (v, set) => Fluent2Slider(
        label: 'Keep deleted files',
        value: v,
        min: 0,
        max: 90,
        valueLabel: (v) => '${v.round()} days',
        onChanged: set,
      ),
    ),
  ],
);

Widget kitSpecimenSliderStepped() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    _Live<double>(
      2,
      (v, set) => Fluent2Slider(
        label: 'Reminder, hours before',
        value: v,
        min: 0,
        max: 8,
        step: 1,
        valueLabel: (v) => '${v.round()} h',
        onChanged: set,
      ),
    ),
    _Live<double>(
      40,
      (v, set) => Fluent2Slider(
        label: 'Thumbnail size',
        value: v,
        size: Fluent2SliderSize.small,
        onChanged: set,
      ),
    ),
  ],
);

Widget kitSpecimenSpinButton() => kitRow([
  _Live<num>(
    6,
    (v, set) => Fluent2SpinButton(
      label: 'Seats',
      value: v,
      min: 1,
      max: 50,
      onChanged: set,
    ),
  ),
  _Live<num>(
    30,
    (v, set) => Fluent2SpinButton(
      label: 'Meeting length',
      value: v,
      min: 15,
      max: 240,
      step: 15,
      format: (n) => '$n min',
      appearance: Fluent2InputAppearance.filledDarker,
      onChanged: set,
    ),
  ),
  _Live<num>(
    2,
    (v, set) => Fluent2SpinButton(
      label: 'Copies',
      value: v,
      min: 1,
      size: Fluent2InputSize.small,
      onChanged: set,
    ),
  ),
]);

Widget kitSpecimenSpinBounds() => kitRow([
  Fluent2SpinButton(
    label: 'Seats, at the least',
    value: 1,
    min: 1,
    max: 50,
    onChanged: (_) {},
  ),
  Fluent2SpinButton(
    label: 'Seats, at the most',
    value: 50,
    min: 1,
    max: 50,
    onChanged: (_) {},
  ),
  const Fluent2SpinButton(label: 'Seats, disabled', value: 6, onChanged: null),
]);

Widget kitSpecimenRating() => _Live<double>(
  3,
  (v, set) =>
      Fluent2Rating(label: 'Rate this meeting', value: v, onChanged: set),
);

Widget kitSpecimenRatingColors() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    for (final color in Fluent2RatingColor.values)
      _Live<double>(
        4,
        (v, set) => Fluent2Rating(
          label: 'Rate the ${kitSay(color)} sample',
          value: v,
          color: color,
          size: Fluent2RatingSize.large,
          onChanged: set,
        ),
      ),
  ],
);

Widget kitSpecimenRatingDisplay() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.s,
  children: [
    Fluent2RatingDisplay(value: 4.5, count: 1160),
    Fluent2RatingDisplay(
      value: 4,
      count: 38,
      color: Fluent2RatingColor.marigold,
      size: Fluent2RatingSize.large,
    ),
    Fluent2RatingDisplay(
      value: 3.5,
      color: Fluent2RatingColor.brand,
      size: Fluent2RatingSize.extraLarge,
    ),
  ],
);

Widget kitSpecimenRatingCompact() => const Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: Fluent2Spacing.s,
  children: [
    Fluent2RatingDisplay(value: 4.7, count: 212, compact: true),
    Fluent2RatingDisplay(
      value: 4.2,
      count: 1160,
      compact: true,
      color: Fluent2RatingColor.marigold,
      size: Fluent2RatingSize.large,
    ),
  ],
);
