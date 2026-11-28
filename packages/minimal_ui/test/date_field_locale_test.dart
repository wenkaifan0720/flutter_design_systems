// A date field writes its day as the app's language writes a date in a
// field, so it reads like the calendar it opens: "Nov 9, 2026" in English,
// "9 Nov 2026" in British English, Arabic in its own months and digits.
// MinimalFormat.date stays the app's own day-first helper.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

final DateTime _day = DateTime(2026, 11, 9);

Future<void> _pump(
  WidgetTester tester,
  Locale locale,
  MinimalDatePickerPresentation presentation,
) async {
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFF000000),
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        DefaultWidgetsLocalizations.delegate,
      ],
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, _, _) => builder(context),
      ),
      home: MinimalHost(
        brightness: Brightness.light,
        child: Center(
          child: SizedBox(
            width: 360,
            child: MinimalDatePicker(
              labelText: 'Started',
              mode: MinimalDatePickerMode.date,
              presentation: presentation,
              value: _day,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  for (final presentation in [
    MinimalDatePickerPresentation.field,
    MinimalDatePickerPresentation.compact,
  ]) {
    for (final (locale, shown) in [
      (const Locale('en', 'US'), 'Nov 9, 2026'),
      (const Locale('en', 'GB'), '9 Nov 2026'),
      (const Locale('ar'), null),
    ]) {
      testWidgets(
        '${presentation.name}, $locale: the field reads like its calendar',
        (tester) async {
          await _pump(tester, locale, presentation);
          final context = tester.element(find.byType(MinimalDatePicker));
          final words = RawWidgetsLocalizations.of(context);
          final day = words.formatMediumDate(_day);
          if (shown != null) expect(day, shown);
          expect(find.text(day), findsOneWidget);
          // The day's figure as the calendar writes it, in the app's digits.
          expect(day, contains(MinimalLocalizations.of(context).digits(9)));
          if (MinimalFormat.date(_day) != day) {
            expect(find.text(MinimalFormat.date(_day)), findsNothing);
          }
          await tester.tap(find.text(day));
          await tester.pumpAndSettle();
          expect(find.text(words.formatMonthYear(_day)), findsWidgets);
        },
      );
    }
  }
}
