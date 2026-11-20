/// Clay's pickers: the calendar, date and range fields, the wheels, the time
/// field and the colour well.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';

import '../kit.dart';

final _first = DateTime(2026);
final _last = DateTime(2027, 12, 31);
final _today = DateTime(2026, 11, 19);

/// The pickers page.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  sections: const [
    KitSection(
      title: 'A calendar',
      note:
          'Days pressed into a slab; the chosen day a raised coral ball, '
          'today ringed. Arrows walk the days, Page Up and Down the months.',
      maxWidth: 420,
      children: [_Calendar()],
    ),
    KitSection(
      title: 'Date fields',
      note:
          'A well that opens the calendar in a sheet; a range takes two taps.',
      maxWidth: 420,
      children: [_Dates()],
    ),
    KitSection(
      title: 'Wheels and times',
      note:
          'Drums turned in a well, the chosen row raised in its middle; the '
          'time field opens them in a sheet.',
      children: [_Times()],
    ),
    KitSection(
      title: 'Colour',
      note: 'A swatch well and a hue groove, the pick a clay ball.',
      maxWidth: 420,
      children: [_Colour()],
    ),
  ],
);

class _Calendar extends StatelessWidget {
  const _Calendar();

  @override
  Widget build(BuildContext context) => KitLive<DateTime?>(
    _today,
    (context, day, set) => ClayCard(
      child: ClayCalendar(
        firstDate: _first,
        lastDate: _last,
        selectedDate: day,
        currentDate: _today,
        onDateChanged: set,
      ),
    ),
  );
}

class _Dates extends StatelessWidget {
  const _Dates();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitLive<DateTime?>(
        DateTime(2026, 11, 23),
        (context, day, set) => ClayDatePicker(
          label: 'Starts on',
          value: day,
          firstDate: _first,
          lastDate: _last,
          currentDate: _today,
          onChanged: set,
        ),
      ),
      const SizedBox(height: ClaySpacing.regular),
      KitLive<ClayDateRange?>(
        ClayDateRange(
          start: DateTime(2026, 12, 22),
          end: DateTime(2026, 12, 28),
        ),
        (context, range, set) => ClayDateRangePicker(
          label: 'A break',
          helper: 'Streaks pause over these days.',
          value: range,
          firstDate: _first,
          lastDate: _last,
          currentDate: _today,
          onChanged: set,
        ),
      ),
    ],
  );
}

class _Times extends StatelessWidget {
  const _Times();

  @override
  Widget build(BuildContext context) {
    final time = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClayFieldLabel('Wake time'),
        KitLive<ClayTime>(
          const ClayTime(hour: 7, minute: 30),
          (context, time, set) => ClayTimePicker(
            value: time,
            onChanged: set,
            semanticLabel: 'Wake time',
          ),
        ),
      ],
    );
    final duration = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ClayFieldLabel('Duration'),
        KitLive<int>(
          15,
          (context, n, set) => ClayWheelPicker<int>(
            items: const [5, 10, 15, 20, 30, 45, 60],
            value: n,
            labelOf: (n) => '$n min',
            onChanged: set,
            semanticLabel: 'Duration',
          ),
        ),
      ],
    );
    final wheels = ClayCard(
      child: LayoutBuilder(
        // Side by side where both drums keep their width; one over the
        // other on a phone.
        builder: (context, box) => box.maxWidth >= 480
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: time),
                  const SizedBox(width: ClaySpacing.regular),
                  Expanded(child: duration),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  time,
                  const SizedBox(height: ClaySpacing.large),
                  duration,
                ],
              ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        wheels,
        const SizedBox(height: ClaySpacing.regular),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: KitLive<ClayTime?>(
              const ClayTime(hour: 21, minute: 0),
              (context, time, set) => ClayTimeField(
                label: 'Remind me at',
                value: time,
                onChanged: set,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Colour extends StatelessWidget {
  const _Colour();

  @override
  Widget build(BuildContext context) => KitLive<Color>(
    const Color(0xFFF08A6B),
    (context, colour, set) => ClayCard(
      child: ClayColorPicker(value: colour, onChanged: set),
    ),
  );
}
