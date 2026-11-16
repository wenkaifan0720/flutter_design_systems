/// Dates, times and colour: `TermDatePicker`, `TermDateRangePicker`,
/// `TermTimeField`, `TermCalendar` and `TermColorPicker`.
library;

import 'package:flutter/widgets.dart';

import '../kit.dart';

Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'pickers',
  sections: kitParts(const [
    ('a date', 'DatePicker'),
    ('a range of dates', 'DateRangePicker'),
    ('a time', 'TimePicker'),
    ('a calendar', 'Calendar'),
    ('a colour', 'ColorPicker'),
  ]),
);
