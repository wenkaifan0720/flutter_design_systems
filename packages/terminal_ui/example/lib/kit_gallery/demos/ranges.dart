/// Sliders, ratings and meters: `TermSlider`, `TermRangeSlider`,
/// `TermRating` and `TermMeter`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitRangesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'ranges',
  sections: kitParts(const [
    ('a slider', 'Slider'),
    ('a range', 'RangeSlider'),
    ('a rating', 'Rating'),
    ('a meter', 'Meter'),
  ]),
);
