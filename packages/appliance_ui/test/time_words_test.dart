// A time picker speaks the reader's language: a screen reader names its
// figures in ui_core's words for the hour and the minute ("Stunde" and
// "Minute" in German, "ساعة" and "دقيقة" in Arabic), its keys for the halves
// of the day read as the reader writes them ("ص" and "م" in Arabic), and its
// figures are set in the reader's digits (Arabic-Indic in Arabic), as
// Material's time picker sets its hours. With no name of its own it leaves
// its naming to the field round it.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _show(WidgetTester tester, Locale locale, Widget child) async {
  tester.view.devicePixelRatio = 2;
  tester.view.physicalSize = const Size(390 * 2, 1200);
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) =>
          ApplianceHost(brightness: Brightness.light, child: app!),
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
          child: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final (locale, hour, minute, morning, evening) in [
    (const Locale('ar'), 'ساعة', 'دقيقة', 'ص', 'م'),
    (const Locale('de'), 'Stunde', 'Minute', 'AM', 'PM'),
    (const Locale('en'), 'Hour', 'Minute', 'AM', 'PM'),
  ]) {
    testWidgets('in ${locale.languageCode} a screen reader names the figures '
        '$hour and $minute, and the keys read $morning and $evening', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await _show(
        tester,
        locale,
        ApplianceTimePicker(
          value: const ApplianceTime(18, 30),
          twentyFourHour: false,
          onChanged: (_) {},
        ),
      );
      // A figure's name, then the figure it shows.
      Finder named(String word) =>
          find.bySemanticsLabel(RegExp('^${RegExp.escape(word)}(\n|\$)'));
      expect(named(hour), findsOneWidget);
      expect(named(minute), findsOneWidget);
      expect(find.text(morning), findsOneWidget);
      expect(find.text(evening), findsOneWidget);
      expect(find.bySemanticsLabel(morning), findsOneWidget);
      expect(find.bySemanticsLabel(evening), findsOneWidget);
      expect(
        find.bySemanticsLabel(RegExp(r'^(Hours|Minutes)\b')),
        findsNothing,
      );
      semantics.dispose();
    });
  }

  for (final (locale, h12, h24, minutes) in [
    (const Locale('ar'), '٦', '١٨', '٠٥'),
    (const Locale('de'), '6', '18', '05'),
  ]) {
    testWidgets('in ${locale.languageCode} the figures read $h12 or $h24 '
        'and $minutes', (tester) async {
      final semantics = tester.ensureSemantics();
      for (final twentyFour in [false, true]) {
        await _show(
          tester,
          locale,
          ApplianceTimePicker(
            value: const ApplianceTime(18, 5),
            twentyFourHour: twentyFour,
            onChanged: (_) {},
          ),
        );
        expect(find.text(twentyFour ? h24 : h12), findsOneWidget);
        expect(find.text(minutes), findsOneWidget);
        // A screen reader hears the figure the window shows.
        expect(
          find.bySemanticsLabel(RegExp(twentyFour ? h24 : h12)),
          findsWidgets,
        );
      }
      semantics.dispose();
    });
  }

  testWidgets('with no name of its own the picker leaves its naming to '
      'its field', (tester) async {
    final semantics = tester.ensureSemantics();
    await _show(
      tester,
      const Locale('de'),
      ApplianceField(
        labelText: 'Erinnern um',
        child: ApplianceTimePicker(
          value: const ApplianceTime(18, 5),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.bySemanticsLabel(RegExp('^Erinnern um')), findsWidgets);
    expect(find.bySemanticsLabel(RegExp(r'\bTime\b')), findsNothing);
    semantics.dispose();
  });
}
