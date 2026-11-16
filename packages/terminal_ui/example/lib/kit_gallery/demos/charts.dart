/// Charts in the grid: `TermLineChart` and `TermAreaChart` in braille dots,
/// `TermBarChart` and `TermSparkline` in blocks.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitChartsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'charts',
  sections: kitParts(const [
    ('a line chart', 'LineChart'),
    ('an area chart', 'AreaChart'),
    ('bars', 'BarChart'),
    ('a sparkline', 'Sparkline'),
  ]),
);
