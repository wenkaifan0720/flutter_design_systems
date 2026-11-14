/// The pickers group's demo: the date picker inline (calendar and typed),
/// with bounds and a refused weekday; the range picker; the docked picker
/// under its field; the dialogs that raise each; then the time picker's
/// dial on the 12-hour clock, the vibrant dial on the 24-hour clock, the
/// typed time and the time scroll; and the wheel picker, of sizes and of
/// months.
library;

import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

import '../kit.dart';

/// The pickers group's demo, in [brightness].
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  liveSections: const <Widget>[
    _Dialogs(),
    _Calendar(),
    _Typed(),
    _Range(),
    _Docked(),
    _DialogSurface(),
    _Dial(),
    _Vibrant(),
    _Input(),
    _Scroll(),
    _Calendars(),
    _Colors(),
  ],
  sections: const <Widget>[
    _Calendar(),
    _Typed(),
    _Range(),
    _Docked(),
    _Dialogs(),
    _DialogSurface(),
    _Dial(),
    _Vibrant(),
    _Input(),
    _Scroll(),
    _Calendars(),
    _Colors(),
  ],
);

/// A fixed "today", so the demo renders the same every day.
final DateTime _today = DateTime(2026, 9, 12);

/// A picker on its own rounded card, at its own width.
class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    Widget card = ExpressiveSurface(
      shape: t.shapes.extraLarge,
      color: t.colors.surfaceContainerHigh,
      child: child,
    );
    if (KitLiveViewport.of(context) &&
        (child is ExpressiveDatePicker || child is ExpressiveDateRangePicker)) {
      card = ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: card,
      );
    }
    return Align(alignment: AlignmentDirectional.centerStart, child: card);
  }
}

class _Calendar extends StatefulWidget {
  const _Calendar();

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  DateTime? _day = DateTime(2026, 9, 18);

  @override
  Widget build(BuildContext context) => kitSection(
    'Date picker · weekdays, this month and next',
    children: <Widget>[
      _Card(
        child: ExpressiveDatePicker(
          selected: _day,
          onChanged: (d) => setState(() => _day = d),
          currentDate: _today,
          firstDate: DateTime(2026, 9, 1),
          lastDate: DateTime(2026, 10, 31),
          selectableDayPredicate: (d) =>
              d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
        ),
      ),
    ],
  );
}

class _Typed extends StatefulWidget {
  const _Typed();

  @override
  State<_Typed> createState() => _TypedState();
}

class _TypedState extends State<_Typed> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) => kitSection(
    'Typed date',
    children: <Widget>[
      _Card(
        child: ExpressiveDatePicker(
          selected: _day,
          onChanged: (d) => setState(() => _day = d),
          currentDate: _today,
          initialMode: ExpressiveDatePickerMode.input,
        ),
      ),
    ],
  );
}

class _Range extends StatefulWidget {
  const _Range();

  @override
  State<_Range> createState() => _RangeState();
}

class _RangeState extends State<_Range> {
  DateTime? _start = DateTime(2026, 9, 14);
  DateTime? _end = DateTime(2026, 9, 19);

  @override
  Widget build(BuildContext context) => kitSection(
    'Date range',
    children: <Widget>[
      _Card(
        child: ExpressiveDateRangePicker(
          start: _start,
          end: _end,
          currentDate: _today,
          onChanged: (s, e) => setState(() {
            _start = s;
            _end = e;
          }),
        ),
      ),
    ],
  );
}

class _Docked extends StatefulWidget {
  const _Docked();

  @override
  State<_Docked> createState() => _DockedState();
}

class _DockedState extends State<_Docked> {
  DateTime? _day = DateTime(2026, 9, 22);

  @override
  Widget build(BuildContext context) => kitSection(
    'Docked',
    children: <Widget>[
      ExpressiveDockedDatePicker(
        label: 'Check-in',
        value: _day,
        currentDate: _today,
        supportingText: 'Tap the calendar to pick',
        onChanged: (d) => setState(() => _day = d),
      ),
      // Day first, as the app's other dates read ("Sat 3 Oct 2026").
      ExpressiveDockedDatePicker(
        label: 'Check-out',
        value: _day,
        currentDate: _today,
        format: (d) =>
            '${ExpressiveFormat.weekday(d)} ${ExpressiveFormat.date(d)}',
        onChanged: (d) => setState(() => _day = d),
      ),
      const ExpressiveDockedDatePicker(label: 'Unavailable'),
    ],
  );
}

class _Dialogs extends StatefulWidget {
  const _Dialogs();

  @override
  State<_Dialogs> createState() => _DialogsState();
}

class _DialogsState extends State<_Dialogs> {
  String _result = 'Nothing chosen yet';

  void _show(String what) {
    if (mounted) setState(() => _result = what);
  }

  String _clock(({int hour, int minute}) t) => ExpressiveFormat.time(
    context,
    DateTime(_today.year, _today.month, _today.day, t.hour, t.minute),
  );

  @override
  Widget build(BuildContext context) {
    final actions = <ExpressiveButton>[
      ExpressiveFilledButton.tonal(
        'Date',
        icon: ExpressiveSymbols.calendarToday,
        onPressed: () async {
          final d = await showExpressiveDatePicker(
            context: context,
            initialDate: DateTime(2026, 9, 18),
            today: _today,
          );
          if (d != null) _show('Date: ${ExpressiveFormat.date(d)}');
        },
      ),
      ExpressiveFilledButton.tonal(
        'Range',
        icon: ExpressiveSymbols.calendarMonth,
        onPressed: () async {
          final r = await showExpressiveDateRangePicker(
            context: context,
            today: _today,
          );
          if (r != null) {
            _show(
              'Range: ${ExpressiveFormat.date(r.start)} to '
              '${ExpressiveFormat.date(r.end)}',
            );
          }
        },
      ),
      ExpressiveFilledButton.tonal(
        'Delivery day',
        icon: ExpressiveSymbols.calendarMonth,
        onPressed: () async {
          final d = await showExpressiveDialog<DateTime>(
            context: context,
            builder: (context) => const _DeliveryDialog(),
          );
          if (d != null) _show('Delivery: ${ExpressiveFormat.date(d)}');
        },
      ),
      ExpressiveFilledButton.tonal(
        'Time',
        icon: ExpressiveSymbols.schedule,
        onPressed: () async {
          final t = await showExpressiveTimePicker(
            context: context,
            initialHour: 9,
            initialMinute: 30,
            is24Hour: false,
          );
          if (t != null) _show('Time: ${_clock(t)}');
        },
      ),
      ExpressiveFilledButton.tonal(
        'Vibrant time',
        icon: ExpressiveSymbols.schedule,
        onPressed: () async {
          final t = await showExpressiveTimePicker(
            context: context,
            initialHour: 18,
            initialMinute: 45,
            vibrant: true,
          );
          if (t != null) _show('Time: ${_clock(t)}');
        },
      ),
      ExpressiveFilledButton.tonal(
        'Scroll time',
        icon: ExpressiveSymbols.unfoldMore,
        onPressed: () async {
          final t = await showExpressiveTimePicker(
            context: context,
            initialHour: 7,
            initialMinute: 5,
            initialMode: ExpressiveTimePickerMode.scroll,
          );
          if (t != null) _show('Time: ${_clock(t)}');
        },
      ),
    ];
    return kitSection(
      'Dialogs',
      children: <Widget>[
        if (KitLiveViewport.of(context))
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: ExpressiveMenu(
              modal: false,
              label: 'Picker dialogs',
              entries: <ExpressiveMenuEntry>[
                for (final action in actions)
                  ExpressiveMenuItem(
                    action.label,
                    icon: action.icon,
                    onPressed: action.onPressed,
                  ),
              ],
              builder: (context, menu) => ExpressiveFilledButton.tonal(
                'Choose a picker',
                key: const ValueKey('gallery-picker-dialogs'),
                icon: ExpressiveSymbols.calendarMonth,
                onPressed: menu.toggle,
              ),
            ),
          )
        else
          Wrap(spacing: kitGap, runSpacing: kitGap, children: actions),
        Text(_result),
      ],
    );
  }
}

/// The date dialog put together by hand: a titled picker that refuses
/// weekends, confirmed with "Deliver".
class _DeliveryDialog extends StatefulWidget {
  const _DeliveryDialog();

  @override
  State<_DeliveryDialog> createState() => _DeliveryDialogState();
}

class _DeliveryDialogState extends State<_DeliveryDialog> {
  DateTime? _day;

  @override
  Widget build(BuildContext context) => ExpressiveDatePickerDialog(
    dismiss: ExpressiveTextButton(
      'Cancel',
      onPressed: () => Navigator.of(context).pop(),
    ),
    confirm: ExpressiveTextButton(
      'Deliver',
      onPressed: _day == null ? null : () => Navigator.of(context).pop(_day),
    ),
    child: ExpressiveDatePicker(
      title: 'Pick a delivery day',
      selected: _day,
      currentDate: _today,
      initialMonth: _today,
      firstDate: _today,
      selectableDayPredicate: (d) =>
          d.weekday != DateTime.saturday && d.weekday != DateTime.sunday,
      onChanged: (d) => setState(() => _day = d),
    ),
  );
}

class _DialogSurface extends StatefulWidget {
  const _DialogSurface();

  @override
  State<_DialogSurface> createState() => _DialogSurfaceState();
}

class _DialogSurfaceState extends State<_DialogSurface> {
  var _mode = ExpressiveTimePickerMode.input;
  final ExpressiveTimePickerController _time = ExpressiveTimePickerController(
    hour: 8,
    minute: 15,
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Time dialog, laid out in place',
    children: <Widget>[
      Center(
        child: ExpressiveTimePickerDialog(
          title: 'Enter time',
          modeToggle: ExpressiveTimePickerModeToggle(
            mode: _mode,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          dismiss: ExpressiveTextButton(
            'Cancel',
            onPressed: () =>
                setState(() => _mode = ExpressiveTimePickerMode.input),
          ),
          confirm: ExpressiveTextButton(
            'OK',
            onPressed: () => showExpressiveSnackBar(context, 'Time selected'),
          ),
          child: _mode == ExpressiveTimePickerMode.input
              ? ExpressiveTimeInput(controller: _time)
              : ExpressiveTimePicker(controller: _time),
        ),
      ),
    ],
  );
}

class _Dial extends StatefulWidget {
  const _Dial();

  @override
  State<_Dial> createState() => _DialState();
}

class _DialState extends State<_Dial> {
  final ExpressiveTimePickerController _time = ExpressiveTimePickerController(
    hour: 9,
    minute: 30,
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Time picker · 12-hour',
    children: <Widget>[
      Center(
        child: ExpressiveTimePicker(
          controller: _time,
          layout: ExpressiveTimePickerLayout.vertical,
        ),
      ),
    ],
  );
}

class _Vibrant extends StatefulWidget {
  const _Vibrant();

  @override
  State<_Vibrant> createState() => _VibrantState();
}

class _VibrantState extends State<_Vibrant> {
  final ExpressiveTimePickerController _time = ExpressiveTimePickerController(
    hour: 18,
    minute: 45,
    is24Hour: true,
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Vibrant · 24-hour',
    children: <Widget>[
      Center(
        child: ExpressiveTimePicker(
          controller: _time,
          vibrant: true,
          layout: ExpressiveTimePickerLayout.vertical,
        ),
      ),
    ],
  );
}

class _Input extends StatefulWidget {
  const _Input();

  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  final ExpressiveTimePickerController _time = ExpressiveTimePickerController(
    hour: 14,
    minute: 5,
  )..selection = ExpressiveTimeSelection.minute;

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Typed time',
    children: <Widget>[Center(child: ExpressiveTimeInput(controller: _time))],
  );
}

class _Scroll extends StatefulWidget {
  const _Scroll();

  @override
  State<_Scroll> createState() => _ScrollState();
}

class _ScrollState extends State<_Scroll> {
  final ExpressiveTimePickerController _time = ExpressiveTimePickerController(
    hour: 7,
    minute: 5,
  );

  @override
  void dispose() {
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => kitSection(
    'Time scroll',
    children: <Widget>[Center(child: ExpressiveTimeScroll(controller: _time))],
  );
}

// Catalog specimens (docs/architecture/component-catalog.md): fixed dates,
// so every capture draws the same month.

/// The calendar with a day chosen, on its dialog container.
Widget kitSpecimenDatePickerDay() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return DecoratedBox(
      decoration: ShapeDecoration(
        color: t.colors.surfaceContainerHigh,
        shape: t.shapes.extraLarge,
      ),
      child: ExpressiveDatePicker(
        selected: DateTime(2026, 9, 18),
        currentDate: DateTime(2026, 9, 14),
        onChanged: (_) {},
      ),
    );
  },
);

/// A range across a weekend, on its dialog container.
Widget kitSpecimenDateRangeWeekend() => Builder(
  builder: (context) {
    final t = context.expressiveTheme;
    return SafeArea(
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: t.colors.surfaceContainerHigh,
          shape: t.shapes.extraLarge,
        ),
        child: ExpressiveDateRangePicker(
          start: DateTime(2026, 9, 18),
          end: DateTime(2026, 9, 21),
          currentDate: DateTime(2026, 9, 14),
          onChanged: (_, _) {},
        ),
      ),
    );
  },
);

/// The docked field showing the chosen date.
Widget kitSpecimenDockedDateCheckIn() => ExpressiveDockedDatePicker(
  label: 'Check-in',
  value: DateTime(2026, 9, 18),
  currentDate: DateTime(2026, 9, 14),
  supportingText: 'Tap the calendar to pick',
  onChanged: (_) {},
);

/// The clock dial at 8:15 AM, the hour being chosen.
Widget kitSpecimenTimePickerDial() => Center(
  child: ExpressiveTimePicker(
    controller: ExpressiveTimePickerController(hour: 8, minute: 15),
  ),
);

/// The hour and minute as two fields.
Widget kitSpecimenTimeInputFields() => Center(
  child: ExpressiveTimeInput(
    controller: ExpressiveTimePickerController(hour: 18, minute: 45),
  ),
);

/// The hour and minute as two wheels.
Widget kitSpecimenTimeScrollWheels() => Center(
  child: ExpressiveTimeScroll(
    controller: ExpressiveTimePickerController(hour: 7, minute: 5),
  ),
);

final DateTime _calendarToday = DateTime(2026, 11, 10);

class _Calendars extends StatefulWidget {
  const _Calendars();

  @override
  State<_Calendars> createState() => _CalendarsState();
}

class _CalendarsState extends State<_Calendars> {
  DateTime? _day = DateTime(2026, 11, 12);
  DateTime? _from = DateTime(2026, 11, 16);
  DateTime? _to = DateTime(2026, 11, 20);

  @override
  Widget build(BuildContext context) => kitSection(
    'Calendar · a day, or a range',
    children: <Widget>[
      Wrap(
        spacing: ExpressiveSpacing.s24,
        runSpacing: ExpressiveSpacing.s24,
        children: <Widget>[
          SizedBox(
            width: 340,
            child: ExpressiveCalendar(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              currentDate: _calendarToday,
              value: _day,
              onChanged: (d) => setState(() => _day = d),
            ),
          ),
          SizedBox(
            width: 340,
            child: ExpressiveCalendar.range(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027, 12, 31),
              currentDate: _calendarToday,
              start: _from,
              end: _to,
              onChanged: (a, b) => setState(() {
                _from = a;
                _to = b;
              }),
            ),
          ),
        ],
      ),
    ],
  );
}

/// November with a week's stay chosen.
Widget kitSpecimenCalendarRange() => SizedBox(
  width: 340,
  child: ExpressiveCalendar.range(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    currentDate: _calendarToday,
    start: DateTime(2026, 11, 16),
    end: DateTime(2026, 11, 20),
    onChanged: (_, _) {},
  ),
);

class _Colors extends StatefulWidget {
  const _Colors();

  @override
  State<_Colors> createState() => _ColorsState();
}

class _ColorsState extends State<_Colors> {
  Color _brand = const Color(0xFF6750A4);

  @override
  Widget build(BuildContext context) => kitSection(
    'Colour picker · drag the area and sliders, or type a hex',
    children: <Widget>[
      Align(
        alignment: AlignmentDirectional.centerStart,
        child: SizedBox(
          width: 320,
          child: ExpressiveColorPicker(
            value: _brand,
            showAlpha: true,
            onChanged: (c) => setState(() => _brand = c),
          ),
        ),
      ),
    ],
  );
}

/// The picker on a violet, its opacity slider shown.
Widget kitSpecimenColorPicker() => SizedBox(
  width: 320,
  child: ExpressiveColorPicker(
    value: const Color(0xFF6750A4),
    showAlpha: true,
    onChanged: (_) {},
  ),
);
