/// Gloss's pickers: date and range fields that open a porcelain calendar,
/// the calendar itself, the time drums, a wheel and the colour well.
library;

import 'package:material_ui/material_ui.dart';
import 'package:gloss_ui/gloss_ui.dart';

import '../kit.dart';

/// The pickers page.
Widget kitPickersDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Pickers',
  sections: const [
    KitSection(
      title: 'Date fields',
      note: 'A well that opens the calendar on a porcelain panel.',
      children: [_DateFields()],
    ),
    KitSection(title: 'The calendar', children: [_Calendars()]),
    KitSection(
      title: 'Drums',
      note: 'A drum turns in a well; the chosen row sits under a clear lens.',
      children: [_Drums()],
    ),
    KitSection(title: 'The colour well', children: [_Colour()]),
  ],
);

final _first = DateTime(2026, 11);
final _last = DateTime(2027, 1, 31);

class _DateFields extends StatefulWidget {
  const _DateFields();

  @override
  State<_DateFields> createState() => _DateFieldsState();
}

class _DateFieldsState extends State<_DateFields> {
  DateTime? _day = DateTime(2026, 11, 20);
  GlossDateRange? _week;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 360),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GlossDatePicker(
          label: 'Cook on',
          value: _day,
          firstDate: _first,
          lastDate: _last,
          currentDate: DateTime(2026, 11, 16),
          onChanged: (d) => setState(() => _day = d),
        ),
        const SizedBox(height: GlossSpacing.regular),
        GlossDateRangePicker(
          label: 'Plan for',
          hint: 'Pick the days',
          value: _week,
          firstDate: _first,
          lastDate: _last,
          currentDate: DateTime(2026, 11, 16),
          onChanged: (r) => setState(() => _week = r),
        ),
      ],
    ),
  );
}

class _Calendars extends StatefulWidget {
  const _Calendars();

  @override
  State<_Calendars> createState() => _CalendarsState();
}

class _CalendarsState extends State<_Calendars> {
  DateTime _day = DateTime(2026, 11, 20);
  GlossDateRange _range = GlossDateRange(
    start: DateTime(2026, 12, 7),
    end: DateTime(2026, 12, 11),
  );

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GlossSpacing.large,
    runSpacing: GlossSpacing.large,
    children: [
      _captioned(
        'One day',
        GlossCalendar(
          firstDate: _first,
          lastDate: _last,
          selectedDate: _day,
          currentDate: DateTime(2026, 11, 16),
          onDateChanged: (d) => setState(() => _day = d),
        ),
      ),
      _captioned(
        'A stretch of days',
        GlossCalendar.range(
          firstDate: _first,
          lastDate: _last,
          selectedRange: _range,
          currentDate: DateTime(2026, 11, 16),
          onRangeChanged: (r) => setState(() => _range = r),
        ),
      ),
    ],
  );
}

/// A calendar 320 wide in a well, under a line saying what it picks.
Widget _captioned(String caption, Widget calendar) => Builder(
  builder: (context) => SizedBox(
    width: 320,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(caption, style: context.glossTheme.textTheme.secondary),
        const SizedBox(height: GlossSpacing.small),
        // On a page the calendar sits in a well, as every group does.
        GlossSurface(
          face: GlossFace.well(
            context.glossTheme.colors,
            radius: GlossMetrics.wellRadius,
          ),
          child: Padding(
            padding: const EdgeInsets.all(GlossSpacing.small),
            child: calendar,
          ),
        ),
      ],
    ),
  ),
);

class _Drums extends StatefulWidget {
  const _Drums();

  @override
  State<_Drums> createState() => _DrumsState();
}

class _DrumsState extends State<_Drums> {
  GlossTime _time = const GlossTime(hour: 18, minute: 30);
  int _servings = 4;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: GlossSpacing.large,
    runSpacing: GlossSpacing.large,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      GlossTimePicker(
        value: _time,
        semanticLabel: 'Dinner',
        onChanged: (t) => setState(() => _time = t),
      ),
      GlossWheelPicker<int>(
        items: const [1, 2, 3, 4, 5, 6, 7, 8],
        value: _servings,
        labelOf: (n) =>
            glossPlural(context, n, one: '1 serving', other: '$n servings'),
        semanticLabel: 'Servings',
        onChanged: (n) => setState(() => _servings = n),
      ),
    ],
  );
}

class _Colour extends StatefulWidget {
  const _Colour();

  @override
  State<_Colour> createState() => _ColourState();
}

class _ColourState extends State<_Colour> {
  Color _colour = const Color(0xFF2E9E7A);

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 320),
    child: GlossColorPicker(
      value: _colour,
      onChanged: (c) => setState(() => _colour = c),
    ),
  );
}
