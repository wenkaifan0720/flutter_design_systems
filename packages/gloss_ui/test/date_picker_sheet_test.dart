// Below 600 wide a date field's calendar rises in a sheet titled Select date,
// as Material's date pickers open full width on a phone: the panel, as wide as
// a phone's field, stood over the labels round it. The month stands at most
// 400 wide, centred, its name at the sheet title's edge; from 600 the panel
// opens as before.
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Widget _app(Widget picker, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [RawWidgetsLocalizations.delegate],
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: GlossHost(
          theme: GlossThemeData.light(),
          darkTheme: GlossThemeData.dark(),
          child: navigator!,
        ),
      ),
      home: GlossScaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(alignment: Alignment.topCenter, child: picker),
        ),
      ),
    );

Future<void> _at(WidgetTester tester, double width) async {
  tester.view.physicalSize = Size(width, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('at 390 a date field opens a sheet: Select date, a day picks', (
    tester,
  ) async {
    await _at(tester, 390);
    DateTime? picked;
    await tester.pumpWidget(
      _app(
        GlossDatePicker(
          labelText: 'Cook on',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (day) => picked = day,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsNothing);
    await tester.tap(find.byType(GlossDatePicker));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsOneWidget);
    final month = tester.getRect(find.byType(GlossCalendar));
    // The sheet's width, centred, its days whole.
    expect(month.width, greaterThan(300));
    expect(month.width, lessThanOrEqualTo(400));
    expect(month.center.dx, moreOrLessEquals(195, epsilon: 1));
    await tester.tap(find.text('24'));
    await tester.pumpAndSettle();
    expect(picked, DateTime(2026, 11, 24));
    expect(find.text('Select date'), findsNothing);
    expect(find.byType(GlossCalendar), findsNothing);
  });

  testWidgets('at 390 a date range field opens a sheet of one month', (
    tester,
  ) async {
    await _at(tester, 390);
    GlossDateRange? picked;
    await tester.pumpWidget(
      _app(
        GlossDateRangePicker(
          labelText: 'Plan',
          value: null,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          currentDate: DateTime(2026, 11, 20),
          onChanged: (range) => picked = range,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlossDateRangePicker));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsOneWidget);
    expect(find.byType(GlossCalendar), findsOneWidget);
    await tester.tap(find.text('21'));
    await tester.pump();
    await tester.tap(find.text('23'));
    await tester.pumpAndSettle();
    expect(picked?.start, DateTime(2026, 11, 21));
    expect(picked?.end, DateTime(2026, 11, 23));
    expect(find.text('Select date'), findsNothing);
  });

  for (final direction in TextDirection.values) {
    testWidgets("at 390 the month's name starts at the sheet title's edge, "
        '${direction.name}', (tester) async {
      await _at(tester, 390);
      await tester.pumpWidget(
        _app(
          GlossDatePicker(
            labelText: 'Cook on',
            value: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            onChanged: (_) {},
          ),
          direction: direction,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(GlossDatePicker));
      await tester.pumpAndSettle();
      final title = tester.getRect(find.text('Select date'));
      final name = tester.getRect(find.text('November 2026'));
      if (direction == TextDirection.ltr) {
        expect(name.left, moreOrLessEquals(title.left, epsilon: 0.5));
      } else {
        expect(name.right, moreOrLessEquals(title.right, epsilon: 0.5));
      }
    });
  }

  testWidgets('at 560 the sheet holds a month 400 wide at most, centred', (
    tester,
  ) async {
    await _at(tester, 560);
    await tester.pumpWidget(
      _app(
        GlossDatePicker(
          labelText: 'Cook on',
          value: DateTime(2026, 11, 20),
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlossDatePicker));
    await tester.pumpAndSettle();
    final month = tester.getRect(find.byType(GlossCalendar));
    expect(month.width, lessThanOrEqualTo(400));
    expect(month.center.dx, moreOrLessEquals(280, epsilon: 1));
  });

  testWidgets('at 640 the calendar opens in its panel under the field', (
    tester,
  ) async {
    await _at(tester, 640);
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 358,
          child: GlossDatePicker(
            labelText: 'Cook on',
            value: DateTime(2026, 11, 20),
            firstDate: DateTime(2026),
            lastDate: DateTime(2027, 12, 31),
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final field = tester.getRect(find.byType(GlossDatePicker));
    await tester.tap(find.byType(GlossDatePicker));
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsNothing);
    final month = tester.getRect(find.byType(GlossCalendar));
    expect(month.top, greaterThan(field.bottom));
  });

  testWidgets('a disabled date field opens nothing at 390', (tester) async {
    await _at(tester, 390);
    await tester.pumpWidget(
      _app(
        GlossDatePicker(
          labelText: 'Cook on',
          value: null,
          firstDate: DateTime(2026),
          lastDate: DateTime(2027, 12, 31),
          onChanged: null,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(GlossDatePicker), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('Select date'), findsNothing);
    expect(find.byType(GlossCalendar), findsNothing);
  });
}
