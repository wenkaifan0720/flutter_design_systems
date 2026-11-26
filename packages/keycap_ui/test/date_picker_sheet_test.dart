// Below 600 wide a date, date range or time field opens its month or its
// wheels in a sheet, the sheet's width, as Keycap's choices open
// on a phone and as Material's pickers open full width there; choosing
// closes the sheet. From 600 it opens over the keyboard, anchored to the
// field.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Size screen, Widget field) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          KeycapHost(brightness: Brightness.light, child: app!),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 200, 24, 0),
          child: field,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(keycapLoadFonts);

  testWidgets('at 390 a date field opens its month in a sheet, the sheet\'s '
      'width, and a day chosen closes it', (tester) async {
    DateTime? chosen;
    await _show(
      tester,
      const Size(390, 844),
      KeycapDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (d) => chosen = d,
      ),
    );
    await tester.tap(find.byType(KeycapDatePicker));
    await tester.pumpAndSettle();
    expect(find.byType(KeycapSheet), findsOneWidget);
    expect(find.byType(KeycapMenuPanel), findsNothing);
    final sheet = tester.getRect(find.byType(KeycapSheet));
    final month = tester.getRect(find.byType(KeycapCalendar));
    // The month spans the sheet, less its margins: no narrower than the
    // field it was opened from.
    expect(month.width, greaterThanOrEqualTo(390 - 2 * 24 - 1));
    expect(month.left, greaterThanOrEqualTo(sheet.left));
    expect(month.right, lessThanOrEqualTo(sheet.right));
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2026, 11, 12));
    expect(find.byType(KeycapSheet), findsNothing);
  });

  testWidgets('at 390 a range field opens in a sheet and the second day '
      'closes it', (tester) async {
    RawDateRange? chosen;
    await _show(
      tester,
      const Size(390, 844),
      KeycapDateRangePicker(
        labelText: 'Away',
        value: null,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 2),
        onChanged: (r) => chosen = r,
      ),
    );
    await tester.tap(find.byType(KeycapDateRangePicker));
    await tester.pumpAndSettle();
    expect(find.byType(KeycapSheet), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.byType(KeycapSheet), findsOneWidget);
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(chosen?.start, DateTime(2026, 11, 10));
    expect(chosen?.end, DateTime(2026, 11, 14));
    expect(find.byType(KeycapSheet), findsNothing);
  });

  testWidgets('at 390 a time field opens its wheels in a sheet, the '
      "sheet's width", (tester) async {
    await _show(
      tester,
      const Size(390, 844),
      KeycapTimePicker(
        labelText: 'At',
        value: const RawTimeOfDay(hour: 9, minute: 0),
        onChanged: (_) {},
      ),
    );
    await tester.tap(find.byType(KeycapTimePicker));
    await tester.pumpAndSettle();
    expect(find.byType(KeycapSheet), findsOneWidget);
    expect(find.byType(KeycapWheelPicker), findsOneWidget);
    // The wheels span the sheet, less its margins, as the month does.
    expect(
      tester.getSize(find.byType(KeycapWheelPicker)).width,
      greaterThanOrEqualTo(390 - 2 * 24 - 1),
    );
  });

  testWidgets('from 600 a date field opens over the keyboard, anchored', (
    tester,
  ) async {
    await _show(
      tester,
      const Size(744, 1133),
      KeycapDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
    );
    final field = tester.getRect(find.byType(KeycapDatePicker));
    await tester.tapAt(field.bottomLeft + const Offset(48, -16));
    await tester.pumpAndSettle();
    expect(find.byType(KeycapSheet), findsNothing);
    expect(
      find.ancestor(
        of: find.byType(KeycapCalendar),
        matching: find.byType(KeycapMenuPanel),
      ),
      findsWidgets,
    );
  });
}
