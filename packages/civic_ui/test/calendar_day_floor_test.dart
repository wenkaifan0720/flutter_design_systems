// A calendar's day stands as tall as the look's tap floor where it is used
// (48 under a finger, 44 under a pointer), so each day's face fills the
// target its calendar gives it: at 44 under a 48 floor a chosen day's plate
// stood 4 short of its target, and the weeks' plates 4 apart.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _pump(WidgetTester tester, Brightness brightness) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final days = RawCalendarController(
    firstDate: DateTime(2026),
    lastDate: DateTime(2027, 12, 31),
    initialMonth: DateTime(2026, 11),
  );
  addTearDown(days.dispose);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, navigator) => CivicTheme(
        data: brightness == Brightness.light
            ? CivicThemeData.light()
            : CivicThemeData.dark(),
        child: navigator!,
      ),
      home: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: CivicCalendar(controller: days),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

// A day's face: the plate painted round its figure.
Rect _face(WidgetTester tester, String day) => tester.getRect(
  find.ancestor(of: find.text(day), matching: find.byType(CustomPaint)).first,
);

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('under a finger (${brightness.name}) each day stands 48', (
      tester,
    ) async {
      await _pump(tester, brightness);
      for (final (above, below) in const [('10', '17'), ('20', '27')]) {
        final a = _face(tester, above);
        final b = _face(tester, below);
        expect(a.height, 48, reason: above);
        expect(b.top - a.bottom, lessThanOrEqualTo(.01), reason: below);
      }
    }, variant: TargetPlatformVariant.only(TargetPlatform.android));

    testWidgets('under a pointer (${brightness.name}) each day stays 44', (
      tester,
    ) async {
      await _pump(tester, brightness);
      expect(_face(tester, '10').height, 44);
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }

  testWidgets('in Arabic the days are written in Arabic-Indic digits', (
    tester,
  ) async {
    final days = RawCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      initialMonth: DateTime(2026, 11),
    );
    addTearDown(days.dispose);
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        locale: const Locale('ar'),
        supportedLocales: const [Locale('en'), Locale('ar')],
        localizationsDelegates: const [RawWidgetsLocalizations.delegate],
        pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
          settings: settings,
          pageBuilder: (context, animation, secondary) => builder(context),
        ),
        builder: (context, navigator) =>
            CivicTheme(data: CivicThemeData.light(), child: navigator!),
        home: Align(
          alignment: Alignment.topCenter,
          child: CivicCalendar(controller: days),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('٢٠'), findsOneWidget);
    expect(find.text('20'), findsNothing);
  });
}
