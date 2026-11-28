// A date field holding a day can be emptied: a Clear key under its
// calendar calls onChanged with null and closes the calendar, so the field
// shows its hint again. An empty field's calendar has no Clear, nor has a
// field the form must have (clearable: false). The span field the same. The key's word is ui_core's for emptying a field, in the
// app's language, and it stands at the calendar's end in either direction.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

final DateTime _day = DateTime(2026, 11, 20);
final StudioDateRange _span = StudioDateRange(
  start: DateTime(2026, 11, 20),
  end: DateTime(2026, 11, 24),
);

Widget _app(Widget field, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, app) => StudioHost(child: app!),
      home: Directionality(
        textDirection: direction,
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(width: 360, child: field),
          ),
        ),
      ),
    );

/// A date field that keeps what it is handed, and the values it was handed.
Widget _date(List<DateTime?> seen, DateTime? first) {
  var value = first;
  return StatefulBuilder(
    builder: (context, setState) => StudioDatePicker(
      labelText: 'Release date',
      value: value,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (d) => setState(() {
        seen.add(d);
        value = d;
      }),
    ),
  );
}

Widget _range(List<StudioDateRange?> seen, StudioDateRange? first) {
  var value = first;
  return StatefulBuilder(
    builder: (context, setState) => StudioDateRangePicker(
      labelText: 'Recording days',
      value: value,
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      onChanged: (r) => setState(() {
        seen.add(r);
        value = r;
      }),
    ),
  );
}

String _clear(WidgetTester tester) =>
    RawWidgetsLocalizations.of(tester.element(find.byType(StudioCalendar).last))
        .clearButtonTooltip;

void main() {
  testWidgets('a chosen day clears: onChanged gets null, the hint is back', (
    tester,
  ) async {
    final seen = <DateTime?>[];
    await tester.pumpWidget(_app(_date(seen, _day)));
    final words = RawWidgetsLocalizations.of(
      tester.element(find.byType(StudioDatePicker)),
    );
    await tester.tap(find.text(words.formatMediumDate(_day)));
    await tester.pumpAndSettle();
    expect(find.byType(StudioCalendar), findsOneWidget);
    await tester.tap(find.text(_clear(tester)));
    await tester.pumpAndSettle();
    expect(seen, [null]);
    expect(find.byType(StudioCalendar), findsNothing);
    expect(find.text('Choose a day'), findsOneWidget);
    expect(find.text(words.formatMediumDate(_day)), findsNothing);
  });

  testWidgets('an empty date field offers no Clear', (tester) async {
    await tester.pumpWidget(_app(_date([], null)));
    await tester.tap(find.text('Choose a day'));
    await tester.pumpAndSettle();
    expect(find.byType(StudioCalendar), findsOneWidget);
    expect(find.text(_clear(tester)), findsNothing);
  });

  testWidgets('a day the form must have offers no Clear', (tester) async {
    await tester.pumpWidget(
      _app(
        StudioDatePicker(
          labelText: 'Release date',
          value: _day,
          clearable: false,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.tap(find.byType(StudioDatePicker));
    await tester.pumpAndSettle();
    expect(find.byType(StudioCalendar), findsOneWidget);
    expect(find.text(_clear(tester)), findsNothing);
  });

  testWidgets('a chosen span clears too', (tester) async {
    final seen = <StudioDateRange?>[];
    await tester.pumpWidget(_app(_range(seen, _span)));
    await tester.tap(find.byType(StudioDateRangePicker));
    await tester.pumpAndSettle();
    await tester.tap(find.text(_clear(tester)));
    await tester.pumpAndSettle();
    expect(seen, [null]);
    expect(find.text('Choose the days'), findsOneWidget);
    await tester.tap(find.text('Choose the days'));
    await tester.pumpAndSettle();
    expect(find.text(_clear(tester)), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets('Clear stands at the calendar\'s end, ${direction.name}', (
      tester,
    ) async {
      await tester.pumpWidget(_app(_date([], _day), direction: direction));
      await tester.tap(find.byType(StudioDatePicker));
      await tester.pumpAndSettle();
      final calendar = tester.getRect(find.byType(StudioCalendar));
      final key = tester.getRect(find.text(_clear(tester)));
      expect(key.top, greaterThanOrEqualTo(calendar.bottom));
      if (direction == TextDirection.ltr) {
        expect(key.center.dx, greaterThan(calendar.center.dx));
      } else {
        expect(key.center.dx, lessThan(calendar.center.dx));
      }
    });
  }
}
