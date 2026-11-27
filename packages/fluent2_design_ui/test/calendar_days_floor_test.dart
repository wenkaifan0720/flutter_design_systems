// Under a finger a calendar's day is as tall as the floor (ui_core's 40); its number is in the app's digits.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        Fluent2Localizations.delegate,
      ],
      builder: (context, _) => Fluent2Host(
        child: Align(
          alignment: Alignment.topCenter,
          // A month 322 wide: a seventh of it is 46.
          child: SizedBox(width: 322, child: child),
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
  testWidgets('a calendar\'s day under a finger is as tall as the floor', (
    tester,
  ) async {
    await _show(tester, Fluent2Calendar(value: DateTime(2026, 11, 20)));
    expect(_dayHeight(tester, '12'), RawTapTargets.fallback.touch.height);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('a range picker\'s day under a finger is as tall as the floor', (
    tester,
  ) async {
    final range = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027),
      mode: RawCalendarMode.range,
    );
    addTearDown(range.dispose);
    await _show(tester, Fluent2DateRangePicker(controller: range, months: 1));
    expect(_dayHeight(tester, '12'), RawTapTargets.fallback.touch.height);
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgets('in Arabic a calendar\'s days read in Arabic-Indic digits', (
    tester,
  ) async {
    await _show(
      tester,
      Fluent2Calendar(value: DateTime(2026, 11, 20)),
      locale: const Locale('ar'),
    );
    expect(find.text('١٢'), findsOneWidget);
    expect(find.text('12'), findsNothing);
  });
}
