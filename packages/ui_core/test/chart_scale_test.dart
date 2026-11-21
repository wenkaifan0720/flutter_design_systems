import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const RawWidgetsLocalizations en = DefaultRawWidgetsLocalizations();

// CLDR spaces a time's AM with a narrow no-break space.
List<String> labels(DesignScale s, {int count = 5}) => [
  for (final t in s.ticks(en, count: count)) t.label.replaceAll('\u202f', ' '),
];

void main() {
  group('DesignLinearScale', () {
    test('maps and inverts, either way round', () {
      const s = DesignLinearScale(min: 0, max: 100, start: 0, end: 300);
      expect(s.map(50), 150);
      expect(s.invert(150), 50);
      // A y scale: its least value at the bottom.
      const y = DesignLinearScale(min: 0, max: 100, start: 300, end: 0);
      expect(y.map(0), 300);
      expect(y.map(100), 0);
      expect(y.invert(y.map(37.5)), closeTo(37.5, 1e-9));
    });

    test('nice: out to whole 1, 2 or 5 steps', () {
      final s = DesignLinearScale.nice(min: 3, max: 97, start: 0, end: 1);
      expect([s.min, s.max], [0, 100]);
      expect(labels(s), ['0', '20', '40', '60', '80', '100']);
      final money = DesignLinearScale.nice(
        min: 820,
        max: 1640,
        start: 0,
        end: 1,
        includeZero: true,
      );
      expect(money.max, 2000);
      expect(labels(money), ['0', '500', '1,000', '1,500', '2,000']);
      final below = DesignLinearScale.nice(min: -37, max: 12, start: 0, end: 1);
      expect([below.min, below.max], [-40, 20]);
      expect(labels(below).first, '-40');
    });

    test(
      'fixed divisions span the nice endpoints in both directions',
      () async {
        final ar = await RawWidgetsLocalizations.delegate.load(
          const Locale('ar'),
        );
        for (final (lo, hi) in [
          (0.0, 23.0),
          (-23.0, 0.0),
          (-12.0, 13.0),
          (0.0, 0.0),
        ]) {
          final s = DesignLinearScale.nice(
            min: hi,
            max: lo,
            start: 100,
            end: 0,
            divisions: 4,
            includeZero: true,
          );
          final ticks = s.ticks(ar);
          expect(ticks.map((t) => t.position), [100, 75, 50, 25, 0]);
          expect(ticks.first.value, lessThanOrEqualTo(lo));
          expect(ticks.last.value, greaterThanOrEqualTo(hi));
          if (lo == 0 && hi == 23) {
            expect(ticks.map((t) => t.value), [0, 6.25, 12.5, 18.75, 25]);
            expect(ticks[1].label, ar.formatDecimal(6.25, fractionDigits: 2));
          }
        }
      },
    );

    test('fractions keep the step\'s decimals, no more', () {
      final s = DesignLinearScale.nice(min: 0, max: 1, start: 0, end: 1);
      expect(labels(s), ['0.0', '0.2', '0.4', '0.6', '0.8', '1.0']);
      final fine = DesignLinearScale.nice(
        min: 0.013,
        max: 0.047,
        start: 0,
        end: 1,
      );
      expect(labels(fine), ['0.01', '0.02', '0.03', '0.04', '0.05']);
    });

    test('one value widens by one each way; none spans nothing', () {
      final s = DesignLinearScale.nice(min: 5, max: 5, start: 0, end: 1);
      expect([s.min, s.max], [4, 6]);
      expect(
        DesignLinearScale.nice(min: 9, max: 2, start: 0, end: 1).min,
        2,
        reason: 'min and max either way round',
      );
      const flat = DesignLinearScale(min: 5, max: 5, start: 0, end: 100);
      expect(flat.map(5), 50);
      expect(flat.ticks(en).single.label, '5');
      const point = DesignLinearScale(min: 5, max: 9, start: 7, end: 7);
      expect(point.invert(7), 5);
    });

    test('zeros alone from zero count up in ones, as a week with data '
        'does, and never below zero', () {
      final empty = DesignLinearScale.nice(
        min: 0,
        max: 0,
        start: 0,
        end: 1,
        includeZero: true,
      );
      expect([empty.min, empty.max], [0, 4]);
      expect(labels(empty), ['0', '1', '2', '3', '4']);
      final week = DesignLinearScale.nice(
        min: 0,
        max: 3.6,
        start: 0,
        end: 1,
        includeZero: true,
      );
      expect(labels(week), ['0', '1', '2', '3', '4']);
      for (final count in [1, 2, 3, 4, 6, 10]) {
        final s = DesignLinearScale.nice(
          min: 0,
          max: 0,
          start: 0,
          end: 1,
          tickCount: count,
          includeZero: true,
        );
        expect(s.min, 0, reason: '$count ticks');
        final ticks = s.ticks(en, count: count);
        expect(ticks.map((t) => t.value), [
          for (var i = 0; i <= s.max; i++) i.toDouble(),
        ], reason: '$count ticks');
      }
      final split = DesignLinearScale.nice(
        min: 0,
        max: 0,
        start: 0,
        end: 1,
        includeZero: true,
        divisions: 4,
      );
      expect(labels(split), ['0', '1', '2', '3', '4']);
      // Without zero asked for, one value is still the middle of its scale.
      final centred = DesignLinearScale.nice(min: 0, max: 0, start: 0, end: 1);
      expect([centred.min, centred.max], [-1, 1]);
    });

    test('ticks in the reader\'s numbers', () async {
      final ar = await RawWidgetsLocalizations.delegate.load(
        const Locale('ar'),
      );
      final s = DesignLinearScale.nice(min: 0, max: 2000, start: 0, end: 1);
      expect(s.ticks(ar).last.label, ar.formatDecimal(2000));
      expect(s.ticks(ar).last.label, contains('٢'));
    });
  });

  group('DesignTimeScale', () {
    test('a day: every six hours, as times of day', () {
      final s = DesignTimeScale(
        min: DateTime(2026, 11, 16),
        max: DateTime(2026, 11, 17),
        start: 0,
        end: 240,
      );
      final ticks = s.ticks(en);
      expect(labels(s), [
        '12:00 AM',
        '6:00 AM',
        '12:00 PM',
        '6:00 PM',
        '12:00 AM',
      ]);
      expect(ticks.map((t) => t.position), [0, 60, 120, 180, 240]);
      expect(s.mapDate(DateTime(2026, 11, 16, 12)), 120);
      expect(
        DateTime.fromMillisecondsSinceEpoch(s.invert(60).round()),
        DateTime(2026, 11, 16, 6),
      );
    });

    test('a minute: seconds', () {
      final s = DesignTimeScale(
        min: DateTime(2026, 11, 16, 15, 5),
        max: DateTime(2026, 11, 16, 15, 6),
        start: 0,
        end: 1,
      );
      expect(labels(s), [
        '3:05:00 PM',
        '3:05:15 PM',
        '3:05:30 PM',
        '3:05:45 PM',
        '3:06:00 PM',
      ]);
    });

    test('a week: every other day; a month: Mondays', () {
      final week = DesignTimeScale(
        min: DateTime(2026, 11, 16),
        max: DateTime(2026, 11, 23),
        start: 0,
        end: 1,
      );
      expect(labels(week), ['Nov 17', 'Nov 19', 'Nov 21', 'Nov 23']);
      final weeks = DesignTimeScale(
        min: DateTime(2026, 11, 4),
        max: DateTime(2026, 12, 6),
        start: 0,
        end: 1,
      );
      final mondays = weeks.ticks(en);
      expect(mondays.first.label, 'Nov 9');
      expect(
        mondays.map(
          (t) => DateTime.fromMillisecondsSinceEpoch(t.value.round()).weekday,
        ),
        everyElement(DateTime.monday),
      );
    });

    test('a year: quarters, January as its year', () {
      final s = DesignTimeScale(
        min: DateTime(2026),
        max: DateTime(2026, 12, 31),
        start: 0,
        end: 1,
      );
      expect(labels(s), ['2026', 'Apr', 'Jul', 'Oct']);
      expect(s.label(en, DateTime(2026, 7)), 'Jul');
    });

    test('decades: whole years', () {
      final s = DesignTimeScale(
        min: DateTime(2000),
        max: DateTime(2050),
        start: 0,
        end: 1,
      );
      expect(labels(s), ['2000', '2010', '2020', '2030', '2040', '2050']);
    });

    test('nice: out to whole steps; one moment widens a day each way', () {
      final s = DesignTimeScale.nice(
        min: DateTime(2026, 11, 20),
        max: DateTime(2026, 1, 15),
        start: 0,
        end: 1,
      );
      expect([s.min, s.max], [DateTime(2026), DateTime(2027)]);
      final hour = DesignTimeScale.nice(
        min: DateTime(2026, 11, 16, 9, 10),
        max: DateTime(2026, 11, 16, 13, 50),
        start: 0,
        end: 1,
      );
      expect(
        [hour.min, hour.max],
        [DateTime(2026, 11, 16, 9), DateTime(2026, 11, 16, 14)],
      );
      final one = DesignTimeScale.nice(
        min: DateTime(2026, 11, 16),
        max: DateTime(2026, 11, 16),
        start: 0,
        end: 1,
      );
      expect(one.min, DateTime(2026, 11, 15));
      expect(one.max, DateTime(2026, 11, 17));
    });
  });

  group('DesignBandScale', () {
    test('bands, their padding, their centres', () {
      const s = DesignBandScale(count: 4, start: 0, end: 400);
      expect(s.step, 100);
      expect(s.bandwidth, 90);
      expect(s.map(0), 50);
      expect(s.map(3), 350);
      expect(s.invert(250), 2);
      expect(s.indexAt(50), 0);
      expect(s.indexAt(99), 0);
      expect(s.indexAt(101), 1);
      expect(s.indexAt(399), 3);
      expect(s.indexAt(-10), isNull);
      expect(s.indexAt(460), isNull);
      expect(labels(s), ['1', '2', '3', '4']);
    });

    test('right to left: the first band at the right', () {
      const s = DesignBandScale(
        count: 4,
        start: 400,
        end: 0,
        labels: ['Q1', 'Q2', 'Q3', 'Q4'],
      );
      expect(s.map(0), 350);
      expect(s.map(3), 50);
      expect(s.indexAt(320), 0);
      expect(s.invert(350), 0);
      expect(labels(s), ['Q1', 'Q2', 'Q3', 'Q4']);
      expect(s.bandwidth, 90);
    });

    test('no bands: nothing under any position', () {
      const s = DesignBandScale(count: 0, start: 0, end: 100);
      expect(s.indexAt(50), isNull);
      expect(s.ticks(en), isEmpty);
      const none = DesignBandScale(count: 3, start: 5, end: 5);
      expect(none.invert(5), 0);
      expect(none.indexAt(5), isNull);
    });
  });

  test('ticks and scales say what they are', () {
    const a = DesignScaleTick(value: 1, position: 2, label: '1');
    expect(a, const DesignScaleTick(value: 1, position: 2, label: '1'));
    expect(
      a.hashCode,
      const DesignScaleTick(value: 1, position: 2, label: '1').hashCode,
    );
    expect(a, isNot(const DesignScaleTick(value: 1, position: 3, label: '1')));
    expect('$a', contains('1 at 2'));
    expect(
      '${const DesignLinearScale(min: 0, max: 1, start: 0, end: 9)}',
      contains('0.0–1.0'),
    );
    expect(
      '${DesignTimeScale(min: DateTime(2026), max: DateTime(2027), start: 0, end: 1)}',
      contains('2026'),
    );
    expect(
      '${const DesignBandScale(count: 3, start: 0, end: 9)}',
      contains('3 bands'),
    );
  });
}
