// CivicFormat's dates follow the app's locale, as its date fields do, so one
// screen never writes a day two ways. An adopter's default app showed
// 11/2/2026 in the date field and "2 November 2026" on the book's page: the
// field followed the locale (American English), CivicFormat wrote English
// day first in every locale. Each Of form in American English, British
// English and Arabic (the locale's order, month words and digits), and a
// page with the field and a CivicFormat date in each.
import 'package:civic_ui/civic_parts.dart' show CivicDateSegment;
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart'
    show GlobalMaterialLocalizations, MaterialApp;

final _day = DateTime(2026, 11, 14);
final _start = DateTime(2026, 11, 3);

Future<BuildContext> _app(
  WidgetTester tester,
  Locale locale, {
  Widget Function(BuildContext context)? page,
}) async {
  late BuildContext at;
  await tester.pumpWidget(
    MaterialApp(
      locale: locale,
      supportedLocales: [locale],
      localizationsDelegates: const [
        RawWidgetsLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, app) => CivicHost(child: app!),
      home: Builder(
        builder: (context) {
          at = context;
          return page?.call(context) ?? const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return at;
}

void main() {
  const us = Locale('en', 'US');
  const gb = Locale('en', 'GB');
  const ar = Locale('ar');

  testWidgets('American English: month first, in words', (tester) async {
    final c = await _app(tester, us);
    expect(CivicFormat.dateOf(c, _day), 'November 14, 2026');
    expect(
      CivicFormat.dateOf(c, _day, weekday: true),
      'Saturday, November 14, 2026',
    );
    expect(CivicFormat.dayMonthOf(c, _day), 'November 14');
    expect(
      CivicFormat.dateRangeOf(c, _start, _day),
      'November 3 to November 14, 2026',
    );
    expect(
      CivicFormat.dateRangeOf(c, _start, DateTime(2027, 1, 2)),
      'November 3, 2026 to January 2, 2027',
    );
    expect(CivicFormat.relativeOf(c, _day, now: _day), 'today');
    expect(
      CivicFormat.relativeOf(c, DateTime(2026, 11, 13, 23), now: _day),
      'yesterday',
    );
    expect(CivicFormat.relativeOf(c, _start, now: _day), 'November 3');
    expect(
      CivicFormat.relativeOf(c, DateTime(2025, 11, 3), now: _day),
      'November 3, 2025',
    );
  });

  testWidgets('British English: day first, in words', (tester) async {
    final c = await _app(tester, gb);
    expect(CivicFormat.dateOf(c, _day), '14 November 2026');
    expect(
      CivicFormat.dateOf(c, _day, weekday: true),
      'Saturday, 14 November 2026',
    );
    expect(CivicFormat.dayMonthOf(c, _day), '14 November');
    expect(
      CivicFormat.dateRangeOf(c, _start, _day),
      '3 November to 14 November 2026',
    );
    expect(
      CivicFormat.relativeOf(c, DateTime(2026, 11, 15), now: _day),
      'tomorrow',
    );
    expect(CivicFormat.relativeOf(c, _start, now: _day), '3 November');
  });

  testWidgets("Arabic: the locale's digits and month words", (tester) async {
    final c = await _app(tester, ar);
    expect(CivicFormat.dateOf(c, _day), '١٤ نوفمبر ٢٠٢٦');
    expect(CivicFormat.dateOf(c, _day, weekday: true), 'السبت، ١٤ نوفمبر ٢٠٢٦');
    expect(CivicFormat.dayMonthOf(c, _day), '١٤ نوفمبر');
    expect(
      CivicFormat.dateRangeOf(c, _start, _day),
      '٣ نوفمبر – ١٤ نوفمبر ٢٠٢٦',
    );
    expect(
      CivicFormat.relativeOf(c, _day, now: _day),
      RawWidgetsLocalizations.of(c).currentDateLabel,
    );
    expect(CivicFormat.relativeOf(c, _start, now: _day), '٣ نوفمبر');
  });

  // The field's parts and a CivicFormat date on one page put the day and the
  // month in the same order.
  for (final (locale, order) in [
    (us, ['month', 'day', 'year']),
    (gb, ['day', 'month', 'year']),
    (ar, ['day', 'month', 'year']),
  ]) {
    testWidgets('a page with a date field and a CivicFormat date agrees '
        '(${locale.toLanguageTag()})', (tester) async {
      late String written;
      await _app(
        tester,
        locale,
        page: (context) {
          written = CivicFormat.dateOf(context, _day);
          return Column(
            children: [
              CivicDatePicker(
                labelText: 'Date started',
                value: _day,
                firstDate: DateTime(2026),
                lastDate: DateTime(2026, 12, 31),
                onChanged: (_) {},
              ),
              Text(written),
            ],
          );
        },
      );
      final parts = [
        for (final s in tester.widgetList<CivicDateSegment>(
          find.byType(CivicDateSegment),
        ))
          s.details.type.name,
      ];
      expect(parts, order);
      final words = RawWidgetsLocalizations.of(
        tester.element(find.byType(CivicDatePicker)),
      );
      final month = words
          .formatMonthYear(_day)
          .replaceFirst(words.formatYear(_day), '')
          .trim();
      final day = words
          .formatShortMonthDay(_day)
          .replaceAll(RegExp(r'[^\d٠-٩]'), '');
      final monthFirst = written.indexOf(month) < written.indexOf(day);
      expect(
        monthFirst,
        parts.indexOf('month') < parts.indexOf('day'),
        reason: '"$written" beside a field typed $parts',
      );
    });
  }
}
