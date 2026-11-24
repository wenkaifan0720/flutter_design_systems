// A calendar's days are whole targets, at least the look's floor tall under a finger, and read in the app's digits.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester, {
  Locale locale = const Locale('en'),
  double width = 390,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 900);
  addTearDown(tester.view.reset);
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
          child: const ApplianceHost(
            brightness: Brightness.light,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(width: 358, child: ApplianceCalendar()),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The height of the day cell that holds [label].
double _dayHeight(WidgetTester tester, String label) => tester
    .widgetList<SizedBox>(
      find.ancestor(of: find.text(label), matching: find.byType(SizedBox)),
    )
    .map((box) => box.height ?? 0)
    .reduce((a, b) => a > b ? a : b);

void main() {
  setUpAll(applianceLoadFonts);

  testWidgets('under a finger a day is as tall as the look\'s floor', (
    tester,
  ) async {
    await _show(tester);
    expect(_dayHeight(tester, '20'), greaterThanOrEqualTo(48));
  });

  testWidgets('under a pointer a day keeps its 44', (tester) async {
    await _show(tester, width: 1440);
    expect(_dayHeight(tester, '20'), 44);
  }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));

  testWidgets('in Arabic the days read in Arabic-Indic digits', (tester) async {
    await _show(tester, locale: const Locale('ar'));
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });
}
