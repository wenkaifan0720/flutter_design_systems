// A date block and a week strip say their weekdays and months in the app's
// words, as Material's date header does: an Arabic app read the English
// names "Fri" and "Nov" over Arabic-Indic digits, and heard an English date.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<RawWidgetsLocalizations> _show(
  WidgetTester tester,
  Locale locale,
  Widget child,
) async {
  late RawWidgetsLocalizations names;
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: const [Locale('en'), Locale('ar')],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        Fluent2Localizations.delegate,
      ],
      builder: (context, _) => Fluent2Host(
        child: Builder(
          builder: (context) {
            names = RawWidgetsLocalizations.of(context);
            return Center(child: child);
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return names;
}

void main() {
  setUpAll(fluent2LoadFonts);
  final date = DateTime(2026, 11, 20);

  for (final locale in const [Locale('en'), Locale('ar')]) {
    testWidgets('in ${locale.languageCode} a date block says its weekday, day, '
        'month and whole date in the app\'s words', (tester) async {
      final semantics = tester.ensureSemantics();
      final names = await _show(tester, locale, Fluent2DateBlock(date: date));
      expect(
        find.text(names.formatShortWeekday(DateTime.friday)),
        findsOneWidget,
      );
      expect(find.text(names.formatDecimal(20)), findsOneWidget);
      expect(find.text(names.formatShortMonth(date)), findsOneWidget);
      expect(find.bySemanticsLabel(names.formatFullDate(date)), findsOneWidget);
      if (locale.languageCode == 'ar') {
        expect(find.text('Fri'), findsNothing);
        expect(find.text('Nov'), findsNothing);
      }
      semantics.dispose();
    });

    testWidgets('in ${locale.languageCode} a week strip says its days in the '
        'app\'s words', (tester) async {
      final semantics = tester.ensureSemantics();
      final names = await _show(
        tester,
        locale,
        SizedBox(
          width: 390,
          child: Fluent2WeekStrip(
            value: date,
            today: DateTime(2026, 11, 18),
            onChanged: (_) {},
          ),
        ),
      );
      // Its days in the app's digits: Arabic-Indic in Arabic.
      expect(find.text(names.formatDecimal(20)), findsOneWidget);
      for (
        var weekday = DateTime.monday;
        weekday <= DateTime.sunday;
        weekday++
      ) {
        expect(
          find.text(names.formatShortWeekday(weekday)),
          findsOneWidget,
          reason: '$weekday',
        );
      }
      expect(
        find.bySemanticsLabel(
          RegExp('^${RegExp.escape(names.formatFullDate(date))}'),
        ),
        findsOneWidget,
      );
      semantics.dispose();
    });
  }
}
