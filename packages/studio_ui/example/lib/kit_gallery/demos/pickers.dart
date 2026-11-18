import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';

import '../kit.dart';

final _first = DateTime(2026, 11);
final _last = DateTime(2027, 2, 28);
final _today = DateTime(2026, 11, 16);

/// Calendars, wheels, the colour and range pickers, chips, stars, files.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Calendars, wheels and pickers',
  sections: [
    KitSection(
      title: 'Date pickers',
      note: 'A display window that opens a calendar under glass; the chosen day sits in a slot, today has a lamp.',
      children: [
        kitState<DateTime?>(
          DateTime(2026, 11, 20),
          (context, v, set) => StudioDatePicker(
            label: 'Release date',
            value: v,
            firstDate: _first,
            lastDate: _last,
            currentDate: _today,
            onChanged: set,
          ),
        ),
        kitState<StudioDateRange?>(
          null,
          (context, v, set) => StudioDateRangePicker(
            label: 'Recording days',
            value: v,
            firstDate: _first,
            lastDate: _last,
            currentDate: _today,
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Calendar',
      note: 'The month on its own; arrows move by day, Page keys by month.',
      children: [
        kitState<DateTime?>(
          DateTime(2026, 11, 20),
          (context, v, set) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 328,
              child: StudioCalendar(
                firstDate: _first,
                lastDate: _last,
                currentDate: _today,
                selectedDate: v,
                onDateChanged: set,
              ),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Thumbwheels',
      note: 'Drums behind a window, turned by a drag or the arrows.',
      children: [
        KitRow(
          children: [
            kitState<StudioTime>(
              const StudioTime(hour: 9, minute: 30),
              (context, v, set) => StudioTimePicker(
                value: v,
                semanticLabel: 'Goes out at',
                onChanged: set,
              ),
            ),
            kitState<int>(
              3,
              (context, v, set) => StudioWheelPicker<int>(
                items: const [1, 2, 3, 4, 5, 6, 7, 8],
                value: v,
                labelOf: (n) => 'Take $n',
                semanticLabel: 'Take',
                onChanged: set,
              ),
            ),
          ],
        ),
      ],
    ),
    KitSection(
      title: 'Range fader',
      note: 'Two caps on one slot, lit between them.',
      children: [
        kitState<StudioRangeValues>(
          const StudioRangeValues(10, 40),
          (context, v, set) => StudioRangeFader(
            values: v,
            max: 90,
            divisions: 18,
            startLabel: 'Shortest',
            endLabel: 'Longest',
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Colour',
      note: 'A field and a hue slot under glass; a monogram tint, say.',
      children: [
        kitState<Color>(
          const Color(0xFF3E7CB1),
          (context, v, set) => Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 300,
              child: StudioColorPicker(value: v, onChanged: set),
            ),
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Chips',
      note: 'Small latching keys with a lamp; a removable one has its own key.',
      children: [
        kitState<Set<String>>(
          const {'Interviews'},
          (context, v, set) => KitRow(
            children: [
              for (final t in const ['Interviews', 'Science', 'Music'])
                StudioChip(
                  label: t,
                  selected: v.contains(t),
                  onSelected: (on) => set(on ? {...v, t} : ({...v}..remove(t))),
                ),
              StudioChip(
                label: 'Long reads',
                onDeleted: () => kitFeedback(context, 'Removed'),
              ),
              const StudioChip(label: 'Locked', enabled: false),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Rating',
      note: 'Five star lenses; the chosen ones lit.',
      children: [
        kitState<int>(
          4,
          (context, v, set) => StudioRating(
            value: v,
            semanticLabel: 'Your rating',
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'File drop',
      note:
          'A dashed recess to drop on or press; each file a row with its bar.',
      children: [
        Builder(
          builder: (context) => StudioFileDrop(
            label: 'Audio',
            hint: 'WAV or MP3, up to 500 MB',
            onChoose: () => kitFeedback(context, 'Choose a file'),
            onRemove: (_) => kitFeedback(context, 'Removed'),
            files: const [
              StudioFile(name: 'take-3.wav', bytes: 48200000, progress: 0.4),
              StudioFile(name: 'intro.mp3', bytes: 3100000),
            ],
          ),
        ),
        const StudioFileDrop(
          label: 'Cover',
          onChoose: null,
          error: 'The cover must be square.',
        ),
      ],
    ),
  ],
);
