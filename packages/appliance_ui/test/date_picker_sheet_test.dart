// Below 600 wide a date or date range field opens its month in a sheet, the
// sheet's width, as Appliance's menus open on a phone and as Material's
// pickers open full width there; choosing closes the sheet. From 600 it
// opens on a plate, anchored to the field.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Size screen, Widget field) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
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

/// The field's key: its foot, under its label.
Future<void> _open(WidgetTester tester, Finder field) async {
  await tester.tapAt(tester.getRect(field).bottomCenter - const Offset(0, 16));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets("at 390 a date field opens its month in a sheet, the sheet's "
      'width, and a day chosen closes it', (tester) async {
    DateTime? chosen;
    await _show(
      tester,
      const Size(390, 844),
      ApplianceDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (d) => chosen = d,
      ),
    );
    final field = find.byType(ApplianceDatePicker);
    final width = tester.getSize(field).width;
    await _open(tester, field);
    expect(find.byType(ApplianceSheet), findsOneWidget);
    expect(find.byType(ApplianceMenuPlate), findsNothing);
    // Titled as Material titles its date picker, in the app's language.
    expect(find.text('Select date'), findsOneWidget);
    final sheet = tester.getRect(find.byType(ApplianceSheet));
    final month = tester.getRect(find.byType(ApplianceCalendar));
    // The month spans the sheet, less its margins: no narrower than the
    // field it was opened from.
    expect(month.width, greaterThanOrEqualTo(width - 1));
    expect(month.left, greaterThanOrEqualTo(sheet.left));
    expect(month.right, lessThanOrEqualTo(sheet.right));
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(chosen, DateTime(2026, 11, 12));
    expect(find.byType(ApplianceSheet), findsNothing);
  });

  testWidgets('at 390 a range field opens in a sheet and the second day '
      'closes it', (tester) async {
    RawDateRange? chosen;
    await _show(
      tester,
      const Size(390, 844),
      ApplianceDateRangePicker(
        labelText: 'Away',
        value: null,
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        currentDate: DateTime(2026, 11, 2),
        onChanged: (r) => chosen = r,
      ),
    );
    await _open(tester, find.byType(ApplianceDateRangePicker));
    expect(find.byType(ApplianceSheet), findsOneWidget);
    await tester.tap(find.text('10'));
    await tester.pumpAndSettle();
    expect(find.byType(ApplianceSheet), findsOneWidget);
    await tester.tap(find.text('14'));
    await tester.pumpAndSettle();
    expect(chosen?.start, DateTime(2026, 11, 10));
    expect(chosen?.end, DateTime(2026, 11, 14));
    expect(find.byType(ApplianceSheet), findsNothing);
  });

  testWidgets('a sheet holds its month at most 400 wide, centred', (
    tester,
  ) async {
    await _show(
      tester,
      const Size(560, 844),
      ApplianceDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
    );
    await _open(tester, find.byType(ApplianceDatePicker));
    final sheet = tester.getRect(find.byType(ApplianceSheet));
    final month = tester.getRect(find.byType(ApplianceCalendar));
    expect(month.width, lessThanOrEqualTo(400));
    expect(month.center.dx, moreOrLessEquals(sheet.center.dx, epsilon: 1));
  });

  testWidgets('from 600 a date field opens on a plate, anchored', (
    tester,
  ) async {
    await _show(
      tester,
      const Size(744, 1133),
      ApplianceDatePicker(
        labelText: 'Due',
        value: DateTime(2026, 11, 20),
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        onChanged: (_) {},
      ),
    );
    await _open(tester, find.byType(ApplianceDatePicker));
    expect(find.byType(ApplianceSheet), findsNothing);
    expect(
      find.ancestor(
        of: find.byType(ApplianceCalendar),
        matching: find.byType(ApplianceMenuPlate),
      ),
      findsWidgets,
    );
  });
}
