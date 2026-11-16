// Civic's words for dates, times, sums and counts: the plain shapes a
// public service prints, the same on every machine.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final sent = DateTime(2026, 11, 3, 9);

  test('a date is day, month in full, year', () {
    expect(CivicFormat.date(sent), '3 November 2026');
    expect(CivicFormat.date(sent, weekday: true), 'Tuesday 3 November 2026');
    expect(CivicFormat.dayMonth(sent), '3 November');
  });

  test('a range of days says "to" and its year once', () {
    expect(
      CivicFormat.dateRange(sent, DateTime(2026, 11, 14)),
      '3 to 14 November 2026',
    );
    expect(
      CivicFormat.dateRange(DateTime(2026, 10, 28), DateTime(2026, 11, 14)),
      '28 October to 14 November 2026',
    );
    expect(
      CivicFormat.dateRange(sent, DateTime(2027, 11, 2)),
      '3 November 2026 to 2 November 2027',
    );
  });

  test('a time drops its zero minutes and names midday and midnight', () {
    String twelve(int h, [int m = 0]) =>
        CivicFormat.clock(DateTime(2026, 1, 1, h, m), twentyFourHour: false);
    expect(twelve(9), '9am');
    expect(twelve(17, 30), '5:30pm');
    expect(twelve(12), 'midday');
    expect(twelve(0), 'midnight');
    expect(twelve(12, 15), '12:15pm');
    expect(twelve(0, 5), '12:05am');
    expect(
      CivicFormat.clock(DateTime(2026, 1, 1, 9, 5), twentyFourHour: true),
      '09:05',
    );
    expect(
      CivicFormat.clockRange(
        DateTime(2026, 1, 1, 9),
        DateTime(2026, 1, 1, 17),
        twentyFourHour: false,
      ),
      '9am to 5pm',
    );
  });

  testWidgets('a time follows the device\'s 24-hour setting', (tester) async {
    late String twelve;
    late String twentyFour;
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            twelve = CivicFormat.time(context, DateTime(2026, 1, 1, 17, 30));
            return MediaQuery(
              data: const MediaQueryData(alwaysUse24HourFormat: true),
              child: Builder(
                builder: (context) {
                  twentyFour = CivicFormat.time(
                    context,
                    DateTime(2026, 1, 1, 17, 30),
                  );
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(twelve, '5:30pm');
    expect(twentyFour, '17:30');
  });

  test('a sum drops zero cents unless asked to keep them', () {
    expect(CivicFormat.money(6000, symbol: '€'), '€60');
    expect(CivicFormat.money(6250, symbol: '€'), '€62.50');
    expect(CivicFormat.money(6000, symbol: '€', cents: true), '€60.00');
    expect(CivicFormat.money(-1200, symbol: '€'), '-€12');
    expect(CivicFormat.money(123456700, symbol: '€'), '€1,234,567');
  });

  test('counts and plurals', () {
    expect(CivicFormat.count(1240), '1,240');
    expect(CivicFormat.plural(1, 'permit'), '1 permit');
    expect(CivicFormat.plural(3, 'permit'), '3 permits');
    expect(CivicFormat.plural(2, 'person', 'people'), '2 people');
  });

  test('when, against now, in calendar days', () {
    final now = DateTime(2026, 11, 14, 23, 30);
    expect(CivicFormat.relative(DateTime(2026, 11, 14, 8), now: now), 'today');
    expect(
      CivicFormat.relative(DateTime(2026, 11, 15, 0, 30), now: now),
      'tomorrow',
    );
    expect(CivicFormat.relative(DateTime(2026, 11, 13), now: now), 'yesterday');
    expect(CivicFormat.relative(sent, now: now), '3 November');
    expect(
      CivicFormat.relative(DateTime(2025, 11, 3), now: now),
      '3 November 2025',
    );
  });

  test('the chrome reads its sizes from the measures', () {
    expect(CivicTopBar.height, CivicChromeMetrics.topBar);
    expect(CivicTopBar.ruleHeight, CivicChromeMetrics.topBarRule);
    expect(CivicNavigationBar.height, CivicChromeMetrics.navigationBar);
    expect(CivicChromeMetrics.sideNavigation, CivicLayout.sideNavigationWidth);
  });
}
