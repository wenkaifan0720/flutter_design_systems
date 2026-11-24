// Patterns read into segments and written out; the typing rules; the runs
// a right-to-left line reads left to right.
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';
import 'package:ui_core/src/internal/localizations_data.dart';
import 'package:ui_core/src/internal/segments.dart';

const _y = RawDateSegmentType.year;
const _m = RawDateSegmentType.month;
const _d = RawDateSegmentType.day;

void main() {
  test('a pattern reads into segments and the text between', () {
    expect(parsePattern('M/d/y'), const [
      PatternPart.segment(_m, 'M', 1),
      PatternPart.literal('/'),
      PatternPart.segment(_d, 'd', 1),
      PatternPart.literal('/'),
      PatternPart.segment(_y, 'y', 1),
    ]);
    // Korean's trailing dot; Portuguese's quoted word; a quote escaped;
    // letters no field types are text.
    expect(parsePattern('y. M. d.').last, const PatternPart.literal('.'));
    expect(parsePattern("d 'de' MMM").map((p) => p.literal ?? p.letter), [
      'd',
      ' de ',
      'M',
    ]);
    expect(
      parsePattern("h 'o''clock'")[1],
      const PatternPart.literal(" o'clock"),
    );
    expect(parsePattern("HH''mm")[1], const PatternPart.literal("'"));
    expect(parsePattern('EEEE d')[0], const PatternPart.literal('EEEE '));
    expect(parsePattern("'open")[0], const PatternPart.literal('open'));
    expect(
      parsePattern('a h:mm').first,
      const PatternPart.segment(RawDateSegmentType.dayPeriod, 'a', 1),
    );
  });

  test('parts compare by what they hold, and say it', () {
    const a = PatternPart.segment(_y, 'y', 4);
    expect(a, const PatternPart.segment(_y, 'y', 4));
    expect(a.hashCode, const PatternPart.segment(_y, 'y', 4).hashCode);
    expect(a == const PatternPart.segment(_y, 'y', 2), isFalse);
    expect(a.toString(), contains('year'));
    expect(const PatternPart.literal('/').toString(), contains('2f'));
  });

  test('a pattern writes a date and a time in the locale\'s names', () {
    final en = rawLocaleData['en']!;
    final ar = rawLocaleData['ar']!;
    final at = DateTime(2026, 11, 16, 0, 5, 9);
    String f(String pattern, [RawLocaleData? data]) =>
        formatPattern(pattern, at, data: data ?? en, am: 'AM', pm: 'PM');
    expect(f('EEEE, MMMM d, y'), 'Monday, November 16, 2026');
    expect(f('EEE MMM dd yy'), 'Mon Nov 16 26');
    expect(f('cccc LLLL / ccc LLL'), 'Monday November / Mon Nov');
    expect(f('G'), 'AD');
    expect(f('h:mm a'), '12:05 AM');
    expect(f('K:mm a'), '0:05 AM');
    expect(f('k:mm:ss'), '24:05:09');
    expect(f('HH:mm'), '00:05');
    expect(f("y 'Q' Q"), '2026 Q Q', reason: 'a letter no field writes');
    expect(f('d/M/y', ar), '١٦/١١/٢٠٢٦');
    expect(localDigits(ar, 7, width: 2), '٠٧');
  });

  test('typing rules: wait while a digit could follow, else move on', () {
    var t = typeDigit('', 1, min: 1, max: 12, digits: 2);
    expect(t, (typed: '1', value: 1, advance: false));
    t = typeDigit('1', 2, min: 1, max: 12, digits: 2);
    expect(t, (typed: '12', value: 12, advance: true));
    // "13" is no month: the 3 starts again, and moves on.
    t = typeDigit('1', 3, min: 1, max: 12, digits: 2);
    expect(t, (typed: '3', value: 3, advance: true));
    t = typeDigit('', 0, min: 1, max: 12, digits: 2);
    expect(t.advance, isFalse, reason: '"0" waits for 01–09');
    t = typeDigit('202', 6, min: 1, max: 9999, digits: 4);
    expect(t, (typed: '2026', value: 2026, advance: true));
    t = typeDigit('2026', 1, min: 1, max: 9999, digits: 4);
    expect(t.typed, '1', reason: 'a fifth digit starts again');
  });

  test('a segment\'s range, digits and steps', () {
    expect(segmentMax('d', year: 2024, month: 2), 29);
    expect(segmentMax('d', month: 2), 29, reason: 'a leap year until known');
    expect(segmentMax('d'), 31);
    expect(
      [for (final l in 'yMLdhHKkmsa'.split('')) segmentMin(l)],
      [
        1, 1, 1, 1, 1, 0, 0, 1, 0, 0, 0, //
      ],
    );
    expect(
      [for (final l in 'yMLhHKkmsa'.split('')) segmentMax(l)],
      [
        9999, 12, 12, 12, 23, 11, 24, 59, 59, 1, //
      ],
    );
    expect([for (final l in 'yMa'.split('')) segmentDigits(l)], [4, 2, 0]);
    expect(stepSegment(12, 1, 1, 12), 1);
    expect(stepSegment(0, -1, 0, 59), 59);
    expect(stepSegment(9999, 1, 1, 9999, wrap: false), 9999);
    expect(daysInMonth(2026, 2), 28);
  });

  test('right to left, a run of digits stays together unless marked', () {
    expect(hasRightToLeft('/'), isFalse);
    expect(hasRightToLeft('‏/'), isTrue);
    expect(hasRightToLeft(' م'), isTrue);
    expect(numberRuns(parsePattern('d.M.y')), [
      [0, 1, 2, 3, 4],
    ]);
    expect(numberRuns(parsePattern('d‏/M‏/y')), [
      [0],
      [1],
      [2],
      [3],
      [4],
    ]);
    expect(numberRuns(parsePattern('h:mm a')), [
      [0, 1, 2],
      [3],
      [4],
    ]);
  });
}
