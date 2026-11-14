/// Calendar and clock values, inline and raised in the look's own sheets.
library;

import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import '../kit.dart';

Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Dates and times',
  sections: [
    kitSection('A day', children: [kitSpecimenDatePicker()]),
    kitSection('A time', children: [kitSpecimenTimePicker()]),
    kitSection('A month laid open', children: [kitSpecimenCalendar()]),
    kitSection('A span of days', children: [kitSpecimenDateRangePicker()]),
    kitSection(
      'Raise a picker',
      children: [
        Builder(
          builder: (context) => Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              NeumorphicButton(
                'Choose a date',
                onPressed: () => showNeumorphicDatePicker(
                  context,
                  value: DateTime(2026, 11, 6),
                ),
              ),
              NeumorphicButton(
                'Choose a time',
                onPressed: () => showNeumorphicTimePicker(
                  context,
                  value: const NeumorphicTime(9, 30),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);
Widget kitSpecimenDatePicker() {
  var value = DateTime(2026, 11, 6);
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicDatePicker(
      value: value,
      today: DateTime(2026, 11, 6),
      first: DateTime(2026, 11, 1),
      last: DateTime(2027, 1, 31),
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

Widget kitSpecimenTimePicker() {
  var value = const NeumorphicTime(9, 30);
  return StatefulBuilder(
    builder: (context, setState) => NeumorphicTimePicker(
      value: value,
      minuteStep: 15,
      twentyFour: false,
      onChanged: (v) => setState(() => value = v),
    ),
  );
}

// The gallery's one today, 12 November 2026, as its date picker's: two calendars with two todays disagreed on a page.
Widget kitSpecimenCalendar() => kitHeld<DesignCalendarController>(
  () => DesignCalendarController(
    firstDate: DateTime(2026, 1),
    lastDate: DateTime(2026, 12, 31),
    selectedDate: DateTime(2026, 11, 14),
    currentDate: DateTime(2026, 11, 12),
  ),
  (context, controller) => NeumorphicCalendar(controller: controller),
);

Widget kitSpecimenDateRangePicker() => kitHeld<DesignCalendarController>(
  () => DesignCalendarController(
    firstDate: DateTime(2026, 1),
    lastDate: DateTime(2026, 12, 31),
    mode: DesignCalendarMode.range,
    selectedRange: DesignDateRange(
      DateTime(2026, 11, 14),
      DateTime(2026, 11, 18),
    ),
    currentDate: DateTime(2026, 11, 12),
  ),
  (context, controller) => NeumorphicDateRangePicker(controller: controller),
);
