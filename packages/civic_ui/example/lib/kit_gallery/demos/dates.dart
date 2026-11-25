// Calendar, dates and times: a date typed or chosen from a calendar, a
// range of days, a time typed, a month's calendar on its own, and a time
// chosen from a flat wheel.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';

import '../kit.dart';

Widget kitDatesDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Calendar, dates & times',
  intro:
      'Typing comes first: a date someone knows is quickest typed. The '
      'calendar helps with one they need to see.',
  sections: const [_Pickers(), _Calendar(), _Wheel()],
);

class _Pickers extends StatefulWidget {
  const _Pickers();

  @override
  State<_Pickers> createState() => _PickersState();
}

class _PickersState extends State<_Pickers> {
  DateTime? _start = DateTime(2026, 11, 24);
  RawDateRange? _stay;
  RawTimeOfDay? _arrival = const RawTimeOfDay(hour: 9, minute: 30);

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Date picker, date range & time',
    caption:
        'The date in the reader’s order, with a button that opens the '
        'calendar under it.',
    spacing: CivicSpacing.s32,
    children: [
      CivicDatePicker(
        labelText: 'When do you want the permit to start?',
        helperText:
            'For example, ${CivicDatePicker.exampleOf(context, DateTime(2026, 3, 27))}',
        value: _start,
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: (day) => setState(() => _start = day),
      ),
      CivicDateRangePicker(
        labelText: 'When will your visitor stay?',
        helperText: 'A visitor permit lasts up to 14 days.',
        value: _stay,
        firstDate: DateTime(2026),
        lastDate: DateTime(2026, 12, 31),
        onChanged: (range) => setState(() => _stay = range),
      ),
      CivicTimeInput(
        labelText: 'What time will you arrive?',
        value: _arrival,
        onChanged: (time) => setState(() => _arrival = time),
      ),
    ],
  );
}

class _Calendar extends StatefulWidget {
  const _Calendar();

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  final _days = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    selectedDate: DateTime(2026, 11, 24),
    // Collections are not made on Sundays.
    selectable: (day) => day.weekday != DateTime.sunday,
  );

  @override
  void dispose() {
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Calendar',
    caption:
        'Square days. Chosen is solid, today is bold over a short rule, and '
        'a day that can’t be chosen is struck through.',
    children: [CivicCalendar(controller: _days, onChanged: (_) {})],
  );
}

class _Wheel extends StatefulWidget {
  const _Wheel();

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  List<int> _slot = const [9, 2];

  @override
  Widget build(BuildContext context) {
    // Hour then minute, left to right in every language, as Material's time
    // picker keeps them: right to left, the minutes come first.
    final words = RawWidgetsLocalizations.of(context);
    final hour = RawPickerColumn(
      itemCount: 24,
      itemLabel: (i) => words.formatHour(
        RawTimeOfDay(hour: i, minute: 0),
        alwaysUse24HourFormat: true,
      ),
      semanticLabel: words.timePickerHourLabel,
    );
    final minute = RawPickerColumn(
      itemCount: 4,
      itemLabel: (i) =>
          words.formatMinute(RawTimeOfDay(hour: 0, minute: i * 15)),
      semanticLabel: words.timePickerMinuteLabel,
    );
    final ltr = Directionality.of(context) == TextDirection.ltr;
    return KitSection(
      title: 'Wheel picker',
      caption:
          'Flat, not a drum: a straight list, the chosen row across the '
          'middle with the chosen rule down its start.',
      children: [
        CivicWheelPicker(
          labelText: 'Collection time',
          columns: (_) => ltr ? [hour, minute] : [minute, hour],
          selection: ltr ? _slot : _slot.reversed.toList(),
          onChanged: (next) =>
              setState(() => _slot = ltr ? next : next.reversed.toList()),
        ),
      ],
    );
  }
}
