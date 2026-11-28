// A date field writes its day as the app's language writes a date in a field
// (ui_core's medium date): "Oct 2, 2026" in English, "2 Oct 2026" in British
// English. It wrote the whole day out, "Friday, 2 October 2026", where the
// docs said a medium date.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(WidgetTester tester, Locale locale) async {
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
      home: BrutalTheme(
        data: BrutalThemeData.light(),
        child: Center(
          child: SizedBox(
            width: 320,
            child: BrutalDatePicker(
              labelText: 'Started',
              value: DateTime(2026, 10, 2),
              firstDate: DateTime(2020),
              lastDate: DateTime(2040),
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
  testWidgets('in English the month comes first', (tester) async {
    await _pump(tester, const Locale('en', 'US'));
    expect(find.text('Oct 2, 2026'), findsOneWidget);
    expect(find.textContaining('Friday'), findsNothing);
  });

  testWidgets('in British English the day comes first', (tester) async {
    await _pump(tester, const Locale('en', 'GB'));
    expect(find.text('2 Oct 2026'), findsOneWidget);
    expect(find.textContaining('Friday'), findsNothing);
  });

  testWidgets('it writes the day as the language writes a date in a field', (
    tester,
  ) async {
    await _pump(tester, const Locale('fr'));
    final words = RawWidgetsLocalizations.of(
      tester.element(find.byType(BrutalDatePicker)),
    );
    expect(
      find.text(words.formatMediumDate(DateTime(2026, 10, 2))),
      findsOneWidget,
    );
  });
}
