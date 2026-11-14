/// [FrostedCalendar]: a month of days to choose one from, laid in place;
/// [FrostedDateRangePicker]: two months to choose a span across.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitCalendarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Calendar',
  sections: [
    kitSection(
      'A day',
      children: [
        KitHeld<DateTime?>(
          DateTime(2026, 11, 14),
          (day, set) => FrostedCalendar(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            currentDate: kitToday,
            value: day,
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Weekdays only',
      children: [
        FrostedCalendar(
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          currentDate: kitToday,
          selectableDayPredicate: (day) => day.weekday <= DateTime.friday,
          onChanged: (_) {},
        ),
      ],
    ),
    kitSection(
      'A span',
      children: [
        KitHeld<DesignDateRange?>(
          DesignDateRange(DateTime(2026, 11, 20), DateTime(2026, 11, 27)),
          (span, set) => FrostedDateRangePicker(
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            currentDate: kitToday,
            value: span,
            onChanged: set,
          ),
        ),
      ],
    ),
  ],
);

/// October, today ringed and the 30th chosen.
Widget kitSpecimenCalendar() => FrostedCalendar(
  firstDate: DateTime(2026),
  lastDate: DateTime(2027, 12, 31),
  currentDate: DateTime(2026, 10, 28),
  value: DateTime(2026, 10, 30),
  onChanged: (_) {},
);

/// Lisbon in May: the trip's first and last days and the days between.
Widget kitSpecimenDateRange() => FrostedDateRangePicker(
  firstDate: DateTime(2026),
  lastDate: DateTime(2027, 12, 31),
  currentDate: DateTime(2026, 5, 1),
  months: 1,
  value: DesignDateRange(DateTime(2026, 5, 14), DateTime(2026, 5, 19)),
  onChanged: (_) {},
);
