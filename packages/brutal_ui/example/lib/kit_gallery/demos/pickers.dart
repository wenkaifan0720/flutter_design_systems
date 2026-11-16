import 'package:flutter/material.dart';
import 'package:brutal_ui/brutal_ui.dart';

import '../kit.dart';

/// Pickers: the month as a table, a date and a span in a field, wheels, a
/// time and a colour.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  sections: const [_Pickers()],
);

class _Pickers extends StatefulWidget {
  const _Pickers();

  @override
  State<_Pickers> createState() => _PickersState();
}

class _PickersState extends State<_Pickers> {
  static final _first = DateTime(2026, 11);
  static final _last = DateTime(2027, 2, 28);
  static final _today = DateTime(2026, 11, 14);
  DateTime _day = DateTime(2026, 11, 19);
  DateTime? _when;
  BrutalDateRange? _span = BrutalDateRange(
    start: DateTime(2026, 11, 17),
    end: DateTime(2026, 11, 22),
  );
  int _count = 2;
  BrutalTime _doors = const BrutalTime(hour: 19, minute: 30);
  Color _tint = const Color(0xFFB8F02E);

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Calendar',
        note:
            'The month as a table on shared rules. The chosen day is ink; '
            'today stands heavy over a bar.',
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 360,
              child: BrutalCalendar(
                firstDate: _first,
                lastDate: _last,
                currentDate: _today,
                selectedDate: _day,
                onDateChanged: (d) => setState(() => _day = d),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'A span',
        note: 'Its ends ink, its middle lime.',
        children: [
          BrutalCalendar.range(
            firstDate: _first,
            lastDate: _last,
            currentDate: _today,
            selectedRange: _span,
            months: MediaQuery.sizeOf(context).width >= 600 ? 2 : 1,
            onRangeChanged: (r) => setState(() => _span = r),
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'In a field',
        note: 'A field that drops the month; a chosen day closes it.',
        children: [
          BrutalDatePicker(
            label: 'Date',
            value: _when,
            firstDate: _first,
            lastDate: _last,
            currentDate: _today,
            onChanged: (d) => setState(() => _when = d),
          ),
          BrutalDateRangePicker(
            label: 'Dates',
            value: _span,
            firstDate: _first,
            lastDate: _last,
            currentDate: _today,
            onChanged: (r) => setState(() => _span = r),
          ),
          BrutalDatePicker(
            label: 'Date',
            value: DateTime(2026, 11, 21),
            firstDate: _first,
            lastDate: _last,
            onChanged: null,
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Wheels',
        note:
            'Flat rows that scroll and snap; the chosen one heavy between '
            'two rules.',
        children: [
          Wrap(
            spacing: BrutalSpacing.large,
            runSpacing: BrutalSpacing.large,
            children: [
              BrutalWheelPicker<int>(
                items: const [1, 2, 3, 4, 5, 6, 7, 8],
                value: _count,
                labelOf: (n) => n == 1 ? '1 ticket' : '$n tickets',
                semanticLabel: 'Tickets',
                onChanged: (n) => setState(() => _count = n),
              ),
              BrutalTimePicker(
                value: _doors,
                semanticLabel: 'Doors open',
                onChanged: (t) => setState(() => _doors = t),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Colour',
        note: 'A ruled field of colour, a hue track, the colour and its code.',
        children: [
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 320,
              child: BrutalColorPicker(
                value: _tint,
                onChanged: (c) => setState(() => _tint = c),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

// Catalog specimens (metadata.yaml): one still per part, drawn the same in
// every preset (on fixed dates, so every still is the same); the stage
// chooses the preset.

Widget kitSpecimenCalendar() => kitState(
  DateTime(2026, 11, 14),
  (context, day, change) => BrutalCalendar(
    firstDate: DateTime(2026, 11),
    lastDate: DateTime(2026, 12, 31),
    currentDate: DateTime(2026, 11, 12),
    selectedDate: day,
    onDateChanged: change,
  ),
);

Widget kitSpecimenDatePicker() => kitState<DateTime?>(
  DateTime(2026, 11, 14),
  (context, day, change) => BrutalDatePicker(
    label: 'Date',
    value: day,
    onChanged: change,
    firstDate: DateTime(2026, 11),
    lastDate: DateTime(2026, 12, 31),
    currentDate: DateTime(2026, 11, 12),
  ),
);

Widget kitSpecimenDateRangePicker() => kitState<BrutalDateRange?>(
  BrutalDateRange(start: DateTime(2026, 11, 14), end: DateTime(2026, 11, 16)),
  (context, span, change) => BrutalDateRangePicker(
    label: 'Dates',
    value: span,
    onChanged: change,
    firstDate: DateTime(2026, 11),
    lastDate: DateTime(2026, 12, 31),
    currentDate: DateTime(2026, 11, 12),
  ),
);

Widget kitSpecimenWheelPicker() => kitState(
  2,
  (context, count, change) => Center(
    child: BrutalWheelPicker<int>(
      items: const [1, 2, 3, 4, 5, 6],
      value: count,
      onChanged: change,
      labelOf: (n) => n == 1 ? '1 ticket' : '$n tickets',
      semanticLabel: 'Tickets',
    ),
  ),
);

Widget kitSpecimenTimePicker() => kitState(
  const BrutalTime(hour: 19, minute: 30),
  (context, time, change) => Center(
    child: BrutalTimePicker(
      value: time,
      onChanged: change,
      semanticLabel: 'Doors',
    ),
  ),
);

Widget kitSpecimenColorPicker() => kitState(
  const Color(0xFF3355FF),
  (context, colour, change) =>
      BrutalColorPicker(value: colour, onChanged: change),
);
