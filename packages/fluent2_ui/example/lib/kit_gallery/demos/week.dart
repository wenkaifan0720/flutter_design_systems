/// The week strip heading a team calendar: today marked, a day picked,
/// dots on the days that hold meetings, a week starting on Sunday, and an
/// inert strip.
library;

import 'package:flutter/material.dart';
import 'package:fluent2_ui/fluent2_ui.dart';

import '../kit.dart';

final DateTime _today = DateTime(2026, 11, 3);

bool _meetings(DateTime day) => const {2, 3, 5, 6}.contains(day.day);

Widget kitWeekDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Week strip',
  sections: [
    // The live strip starts on today; the catalog's today specimen
    // (kitSpecimenWeekToday) draws the same, so the page shows it once.
    kitSection('Pick a day, today picked', children: [const _Week()]),
    kitSection('Another day picked', children: [kitSpecimenWeekPicked()]),
    kitSection(
      'Starting on Sunday, inert',
      children: [
        Fluent2WeekStrip(
          value: _today,
          today: _today,
          hasEvents: _meetings,
          firstDayOfWeek: DateTime.sunday,
        ),
      ],
    ),
  ],
);

/// This week with today picked and the meeting days dotted.
Widget kitSpecimenWeekToday() => Fluent2WeekStrip(
  value: _today,
  today: _today,
  hasEvents: _meetings,
  onChanged: (_) {},
);

/// Thursday picked, today still marked.
Widget kitSpecimenWeekPicked() => Fluent2WeekStrip(
  value: DateTime(2026, 11, 5),
  today: _today,
  hasEvents: _meetings,
  onChanged: (_) {},
);

class _Week extends StatefulWidget {
  const _Week();

  @override
  State<_Week> createState() => _WeekState();
}

class _WeekState extends State<_Week> {
  DateTime _day = _today;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: Fluent2Spacing.m,
      children: [
        Fluent2WeekStrip(
          value: _day,
          today: _today,
          hasEvents: _meetings,
          onChanged: (day) => setState(() => _day = day),
        ),
        Text(
          _meetings(_day)
              ? '${Fluent2DateBlock.spoken(_day)}: Design review at 10:00'
              : '${Fluent2DateBlock.spoken(_day)}: no meetings',
          style: t.body1.c(t.textSecondary),
        ),
      ],
    );
  }
}
