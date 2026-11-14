/// [FrostedWeekStrip]: a week of kept, missed and coming days under the prism's
/// light, pressed to toggle, and a report that takes no press.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitWeekDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Week strip',
  sections: [
    kitSection('Press a day to toggle it', children: [const _Week()]),
    kitSection(
      'A report',
      children: [
        FrostedWeekStrip(
          start: DateTime(2026, 10, 19),
          days: const [
            FrostedDayStatus.complete,
            FrostedDayStatus.missed,
            FrostedDayStatus.complete,
            FrostedDayStatus.complete,
            FrostedDayStatus.complete,
            FrostedDayStatus.missed,
            FrostedDayStatus.complete,
          ],
        ),
      ],
    ),
    kitSection('Specimen', children: [kitSpecimenWeekStrip()]),
  ],
);

/// The week of October 26th: four kept, one missed, today and two to come.
Widget kitSpecimenWeekStrip() => FrostedWeekStrip(
  start: DateTime(2026, 10, 26),
  days: const [
    FrostedDayStatus.complete,
    FrostedDayStatus.complete,
    FrostedDayStatus.missed,
    FrostedDayStatus.complete,
    FrostedDayStatus.current,
    FrostedDayStatus.upcoming,
    FrostedDayStatus.upcoming,
  ],
  onChanged: (_) {},
);

/// The page's own week, a press flipping a day between kept and missed.
class _Week extends StatefulWidget {
  const _Week();

  @override
  State<_Week> createState() => _WeekState();
}

class _WeekState extends State<_Week> {
  final _days = [
    FrostedDayStatus.complete,
    FrostedDayStatus.complete,
    FrostedDayStatus.missed,
    FrostedDayStatus.complete,
    FrostedDayStatus.current,
    FrostedDayStatus.upcoming,
    FrostedDayStatus.upcoming,
  ];
  static final _start = DateTime(2026, 10, 26);

  @override
  Widget build(BuildContext context) => FrostedWeekStrip(
    start: _start,
    days: _days,
    hue: context.frostedTheme.hues.seafoam,
    onChanged: (date) => setState(() {
      final i = date.difference(_start).inDays;
      _days[i] = switch (_days[i]) {
        FrostedDayStatus.complete => FrostedDayStatus.missed,
        FrostedDayStatus.missed ||
        FrostedDayStatus.current => FrostedDayStatus.complete,
        FrostedDayStatus.upcoming => FrostedDayStatus.upcoming,
      };
    }),
  );
}
