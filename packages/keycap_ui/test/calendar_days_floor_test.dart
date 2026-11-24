// A calendar's days stand at the look's floor under a finger, 48, so a bordered grid closes up, and read in the app's
// digits.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
  final controller = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027),
    selectedDate: DateTime(2026, 11, 20),
  );
  addTearDown(controller.dispose);
  await tester.pumpWidget(
    MaterialApp(
      home: Localizations(
        locale: locale,
        delegates: const [
          RawWidgetsLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        child: Directionality(
          textDirection: locale.languageCode == 'ar'
              ? TextDirection.rtl
              : TextDirection.ltr,
          child: KeycapHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 358,
                child: KeycapCalendar(controller: controller),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The height of the tallest box round the day that reads [label].
double _dayHeight(WidgetTester tester, String label) => tester
    .widgetList<SizedBox>(
      find.ancestor(of: find.text(label), matching: find.byType(SizedBox)),
    )
    .map((box) => box.height ?? 0)
    .reduce((a, b) => a > b ? a : b);

void main() {
  testWidgets('under a finger a day is as tall as the look\'s floor', (
    tester,
  ) async {
    await _show(tester);
    expect(_dayHeight(tester, '12'), 48);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('under a pointer a day keeps its 44', (tester) async {
    await _show(tester, width: 1440);
    expect(_dayHeight(tester, '12'), 44);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('in Arabic the days read in Arabic-Indic digits', (tester) async {
    await _show(tester, locale: const Locale('ar'));
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });
}
