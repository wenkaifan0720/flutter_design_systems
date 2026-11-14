/// [FrostedSelect], [FrostedDatePicker], [FrostedTimePicker] and
/// [FrostedWheelPicker], and their show functions.
library;

import 'package:flutter/material.dart';
import 'package:frosted_ui/frosted_ui.dart';

import '../kit.dart';

Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Select & pickers',
  sections: [
    kitSection(
      'Select',
      children: [
        KitHeld<String?>(
          null,
          (v, set) => FrostedSelect<String>(
            label: 'Room',
            helper: 'Where the meeting is held',
            value: v,
            onChanged: set,
            options: const [
              FrostedSelectOption('k', 'Kitchen'),
              FrostedSelectOption('s', 'Study'),
              FrostedSelectOption('g', 'Garden', note: 'Outdoors'),
            ],
          ),
        ),
        // Wrong and disabled are two states, shown apart: a field asking
        // for a choice stays live under its red rim.
        KitHeld<String?>(
          null,
          (v, set) => FrostedSelect<String>(
            label: 'Team',
            error: v == null ? 'Choose a team' : null,
            value: v,
            onChanged: set,
            options: const [
              FrostedSelectOption('a', 'Alpha'),
              FrostedSelectOption('b', 'Beta'),
            ],
          ),
        ),
        const FrostedSelect<String>(
          label: 'Building',
          helper: 'Set by your office',
          value: 'n',
          options: [FrostedSelectOption('n', 'North wing')],
          onChanged: null,
        ),
      ],
    ),
    kitSection(
      'Date',
      children: [
        KitHeld<DateTime?>(
          DateTime(2026, 11, 12),
          (v, set) => FrostedDatePicker(
            value: v,
            currentDate: kitToday,
            first: DateTime(2026, 11, 3),
            last: DateTime(2027, 6, 30),
            onChanged: set,
          ),
        ),
      ],
    ),
    kitSection(
      'Time',
      children: [
        KitHeld<FrostedTime>(
          const FrostedTime(hour: 9, minute: 30),
          (v, set) =>
              FrostedTimePicker(value: v, minuteInterval: 5, onChanged: set),
        ),
      ],
    ),
    kitSection(
      'Wheel',
      children: [
        // A wheel as wide as the time picker's block, at the line's start
        // (filling a desktop column it was a band across the whole page).
        KitHeld<int>(
          2,
          (v, set) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostedWheelPicker<int>(
              label: 'Guests',
              value: v,
              onChanged: set,
              width: 360,
              options: [
                for (var n = 1; n <= 12; n++) FrostedSelectOption(n, '$n'),
              ],
            ),
          ),
        ),
      ],
    ),
    kitSection(
      'Raised',
      children: [
        Builder(
          builder: (context) => kitRow([
            FrostedButton.glass(
              'Pick a date',
              onPressed: () => showFrostedDatePicker(
                context,
                initialDate: DateTime(2026, 11, 12),
                currentDate: kitToday,
              ),
            ),
            FrostedButton.glass(
              'Pick a time',
              onPressed: () => showFrostedTimePicker(
                context,
                initialTime: const FrostedTime(hour: 18, minute: 0),
              ),
            ),
          ]),
        ),
      ],
    ),
  ],
);

/// A due date on its wheels.
Widget kitSpecimenDatePicker() => FrostedDatePicker(
  value: DateTime(2026, 10, 30),
  first: DateTime(2026),
  last: DateTime(2027, 12, 31),
  currentDate: DateTime(2026, 10, 28),
  onChanged: (_) {},
);

/// A reminder's time.
Widget kitSpecimenTimePicker() => FrostedTimePicker(
  value: const FrostedTime(hour: 9, minute: 30),
  onChanged: (_) {},
);

/// How many share a bill.
Widget kitSpecimenWheelPicker() => FrostedWheelPicker<int>(
  label: 'Split between',
  options: [for (var n = 1; n <= 8; n++) FrostedSelectOption(n, '$n')],
  value: 3,
  onChanged: (_) {},
);
