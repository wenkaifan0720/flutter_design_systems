import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/host.dart';

/// The time [DisplayFormat.time] prints at [at] under a media query that does
/// or does not ask for the 24-hour clock.
Future<String> _timeUnder(
  WidgetTester tester,
  DateTime at, {
  required bool twentyFourHour,
}) async {
  late String printed;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(alwaysUse24HourFormat: twentyFourHour),
      child: Builder(
        builder: (context) {
          printed = DisplayFormat.time(context, at);
          return const SizedBox();
        },
      ),
    ),
  );
  return printed;
}

void main() {
  group('money', () {
    test('prints minor units with separators and the sign first', () {
      expect(DisplayFormat.money(129900), r'$1,299.00');
      expect(DisplayFormat.money(5), r'$0.05');
      expect(DisplayFormat.money(-1200), r'-$12.00');
      expect(DisplayFormat.money(123456789), r'$1,234,567.89');
      expect(DisplayFormat.money(129900, symbol: '€'), '€1,299.00');
    });

    test('rounds half up to whole units without cents', () {
      expect(DisplayFormat.money(1250, cents: false), r'$13');
      expect(DisplayFormat.money(1249, cents: false), r'$12');
      expect(DisplayFormat.money(-1250, cents: false), r'-$13');
    });
  });

  test('count groups thousands with the sign first', () {
    expect(DisplayFormat.count(0), '0');
    expect(DisplayFormat.count(999), '999');
    expect(DisplayFormat.count(1240), '1,240');
    expect(DisplayFormat.count(1000000), '1,000,000');
    expect(DisplayFormat.count(-1240), '-1,240');
  });

  test('dates print day first with the month as a word', () {
    final day = DateTime(2026, 8, 28);
    expect(DisplayFormat.date(day), '28 Aug 2026');
    expect(DisplayFormat.dayMonth(day), '28 Aug');
    expect(DisplayFormat.month(day), 'Aug');
    expect(DisplayFormat.month(day, short: false), 'August');
    expect(DisplayFormat.weekday(day), 'Fri');
    expect(DisplayFormat.weekday(day, short: false), 'Friday');
    expect(DisplayFormat.isoDate(DateTime(2026, 6, 2)), '2026-06-02');
  });

  group('clock', () {
    test('on the 12-hour face: no leading zero, noon and midnight are 12', () {
      String twelve(int h, int m) => DisplayFormat.clock(
        DateTime(2026, 1, 1, h, m),
        twentyFourHour: false,
      );
      expect(twelve(0, 5), '12:05 AM');
      expect(twelve(7, 5), '7:05 AM');
      expect(twelve(11, 59), '11:59 AM');
      expect(twelve(12, 0), '12:00 PM');
      expect(twelve(21, 30), '9:30 PM');
    });

    test('on the 24-hour clock: the hour zero-padded', () {
      String full(int h, int m) =>
          DisplayFormat.clock(DateTime(2026, 1, 1, h, m), twentyFourHour: true);
      expect(full(0, 5), '00:05');
      expect(full(7, 5), '07:05');
      expect(full(12, 0), '12:00');
      expect(full(21, 30), '21:30');
    });
  });

  testWidgets('time follows the platform\'s 24-hour setting', (tester) async {
    final at = DateTime(2026, 8, 28, 21, 30);
    expect(await _timeUnder(tester, at, twentyFourHour: false), '9:30 PM');
    expect(await _timeUnder(tester, at, twentyFourHour: true), '21:30');
    final morning = DateTime(2026, 8, 28, 7, 5);
    expect(await _timeUnder(tester, morning, twentyFourHour: false), '7:05 AM');
    expect(await _timeUnder(tester, morning, twentyFourHour: true), '07:05');
  });

  group('relative', () {
    final now = DateTime(2026, 8, 28, 9, 41);

    test('names the calendar day within a week, else the date', () {
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 28, 23, 59), now: now),
        'Today',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 27, 23, 0), now: now),
        'Yesterday',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 29, 0, 1), now: now),
        'Tomorrow',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 25), now: now),
        '3 days ago',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 30), now: now),
        'In 2 days',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 8, 22), now: now),
        '6 days ago',
      );
      expect(
        DisplayFormat.relative(DateTime(2026, 9, 3), now: now),
        'In 6 days',
      );
      expect(DisplayFormat.relative(DateTime(2026, 8, 21), now: now), '21 Aug');
      expect(DisplayFormat.relative(DateTime(2026, 9, 4), now: now), '4 Sep');
    });

    test('counts calendar days, not elapsed hours', () {
      // 11pm to 1am is one sleep: yesterday, however few hours it was.
      expect(
        DisplayFormat.relative(
          DateTime(2026, 8, 27, 23),
          now: DateTime(2026, 8, 28, 1),
        ),
        'Yesterday',
      );
    });

    // Local midnights across a daylight-saving change are 23 or 25 hours
    // apart. Measured in local time, the short day floors to zero and
    // tomorrow reads "Today" — in any zone that observes the change (the
    // machine's own zone decides which boundaries bite). Counted on UTC
    // dates, every boundary reads the same everywhere.
    const boundaries = <String, List<int>>{
      'US spring forward': [2026, 3, 8],
      'EU spring forward': [2026, 3, 29],
      'EU fall back': [2026, 10, 25],
      'US fall back': [2026, 11, 1],
    };
    for (final MapEntry(key: name, value: ymd) in boundaries.entries) {
      test('holds across the $name daylight-saving boundary', () {
        final before = DateTime(ymd[0], ymd[1], ymd[2] - 1, 12);
        final boundary = DateTime(ymd[0], ymd[1], ymd[2], 12);
        final after = DateTime(ymd[0], ymd[1], ymd[2] + 1, 12);
        expect(DisplayFormat.relative(boundary, now: before), 'Tomorrow');
        expect(DisplayFormat.relative(after, now: boundary), 'Tomorrow');
        expect(DisplayFormat.relative(before, now: boundary), 'Yesterday');
        expect(DisplayFormat.relative(boundary, now: after), 'Yesterday');
        expect(DisplayFormat.relative(after, now: before), 'In 2 days');
        expect(DisplayFormat.relative(before, now: after), '2 days ago');
      });
    }

    test('reads Tomorrow and Yesterday on every day of the year', () {
      for (
        var day = DateTime(2026, 1, 1);
        day.year == 2026;
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        final next = DateTime(day.year, day.month, day.day + 1);
        expect(
          DisplayFormat.relative(next, now: day),
          'Tomorrow',
          reason: '$day',
        );
        expect(
          DisplayFormat.relative(day, now: next),
          'Yesterday',
          reason: '$day',
        );
      }
    });
  });
}
