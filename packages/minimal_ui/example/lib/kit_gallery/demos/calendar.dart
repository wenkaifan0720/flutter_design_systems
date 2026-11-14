/// A month to pick a day from, two months (side by side where both fit),
/// and the range field that opens them.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

final DateTime _today = DateTime(2026, 8, 28);
final DateTime _first = DateTime(2025, 1, 1);
final DateTime _last = DateTime(2027, 12, 31);

Widget kitCalendarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Calendar & date range',
  sections: [
    kitSection(
      'One day',
      children: [
        const _Day(),
        kitNote(
          'Arrows move by day and week, Page Up and Down by month; weekends '
          'are closed here.',
        ),
      ],
    ),
    kitSection(
      'Range field',
      children: [
        const _Range(),
        kitNote('Pick the first day, then the last; it closes on the second.'),
      ],
    ),
    kitSection(
      'Two months',
      children: [
        MinimalCalendar(
          firstDate: _first,
          lastDate: _last,
          today: _today,
          months: 2,
          value: DateTime(2026, 8, 20),
          onChanged: (_) {},
        ),
        kitNote(
          'Side by side where both fit, one over the other on a phone; one '
          'day picked. A range is drawn in the range field\'s own panel, '
          'above.',
        ),
      ],
    ),
  ],
);

class _Day extends StatefulWidget {
  const _Day();

  @override
  State<_Day> createState() => _DayState();
}

class _DayState extends State<_Day> {
  DateTime? _day = DateTime(2026, 8, 31);

  @override
  Widget build(BuildContext context) => MinimalCalendar(
    firstDate: _first,
    lastDate: _last,
    today: _today,
    value: _day,
    selectable: (d) => d.weekday < DateTime.saturday,
    onChanged: (d) => setState(() => _day = d),
  );
}

class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  DesignDateRange? _stay = DesignDateRange(
    DateTime(2026, 8, 28),
    DateTime(2026, 9, 3),
  );

  @override
  Widget build(BuildContext context) => MinimalDateRangePicker(
    label: 'Stay',
    hint: 'Check-in – check-out',
    firstDate: _first,
    lastDate: _last,
    today: _today,
    value: _stay,
    onChanged: (r) => setState(() => _stay = r),
  );
}

// --- catalog specimens -------------------------------------------------------

/// A month, today underlined and a day chosen.
Widget kitSpecimenCalendar() => Center(
  child: MinimalCalendar(
    firstDate: _first,
    lastDate: _last,
    today: _today,
    value: DateTime(2026, 8, 31),
    onChanged: (_) {},
  ),
);

/// The range field, a week chosen.
Widget kitSpecimenDateRangePicker() => Padding(
  padding: const EdgeInsets.all(MinimalSpacing.s16),
  child: MinimalDateRangePicker(
    label: 'Stay',
    firstDate: _first,
    lastDate: _last,
    today: _today,
    value: DesignDateRange(DateTime(2026, 8, 28), DateTime(2026, 9, 3)),
    onChanged: (_) {},
  ),
);
