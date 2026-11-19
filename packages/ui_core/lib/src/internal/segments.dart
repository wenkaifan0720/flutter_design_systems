// Date and time patterns (CLDR's, as DesignLocaleData holds them): read
// into the segments a field types in and the text between, and written out
// for a date or a time in a locale's names and digits.
import 'package:flutter/foundation.dart';

import '../date_field.dart' show DesignDateSegmentType;
import 'localizations_data.dart';

/// One part of a pattern: a field's segment, or the text between.
@immutable
class PatternPart {
  /// A field's segment: its [type], the pattern [letter] and how many times
  /// it repeats ([width]).
  const PatternPart.segment(this.type, this.letter, this.width)
    : literal = null;

  /// Text between segments.
  const PatternPart.literal(String this.literal)
    : type = null,
      letter = '',
      width = 0;

  /// The segment's kind; null for text.
  final DesignDateSegmentType? type;

  /// The pattern letter (`h`, `H`, `K`, `k` tell the clock apart).
  final String letter;

  /// How many times the letter repeats (`MM`: 2).
  final int width;

  /// The text; null for a segment.
  final String? literal;

  @override
  bool operator ==(Object other) =>
      other is PatternPart &&
      other.type == type &&
      other.letter == letter &&
      other.width == width &&
      other.literal == literal;

  @override
  int get hashCode => Object.hash(type, letter, width, literal);

  @override
  String toString() => literal != null
      ? 'PatternPart.literal(${literal!.runes.map((r) => r.toRadixString(16)).join(' ')})'
      : 'PatternPart.segment($type, $letter×$width)';
}

DesignDateSegmentType? _typeOf(String letter) => switch (letter) {
  'y' => DesignDateSegmentType.year,
  'M' || 'L' => DesignDateSegmentType.month,
  'd' => DesignDateSegmentType.day,
  'h' || 'H' || 'K' || 'k' => DesignDateSegmentType.hour,
  'm' => DesignDateSegmentType.minute,
  's' => DesignDateSegmentType.second,
  'a' => DesignDateSegmentType.dayPeriod,
  _ => null,
};

/// Walks [pattern]: [onField] for each run of one letter, [onText] for the
/// text between (quoted text unquoted, `''` a quote).
void _walk(
  String pattern,
  void Function(String letter, int width) onField,
  void Function(String text) onText,
) {
  var i = 0;
  while (i < pattern.length) {
    final c = pattern[i];
    if (c == "'") {
      if (i + 1 < pattern.length && pattern[i + 1] == "'") {
        onText("'");
        i += 2;
        continue;
      }
      // Quoted text runs to the next lone quote; `''` inside is a quote.
      final quoted = StringBuffer();
      i++;
      while (i < pattern.length) {
        if (pattern[i] == "'") {
          if (i + 1 < pattern.length && pattern[i + 1] == "'") {
            quoted.write("'");
            i += 2;
            continue;
          }
          i++;
          break;
        }
        quoted.write(pattern[i]);
        i++;
      }
      onText(quoted.toString());
      continue;
    }
    final isLetter = RegExp('[A-Za-z]').hasMatch(c);
    if (!isLetter) {
      onText(c);
      i++;
      continue;
    }
    var j = i;
    while (j < pattern.length && pattern[j] == c) {
      j++;
    }
    onField(c, j - i);
    i = j;
  }
}

/// [pattern]'s segments and the text between them, adjacent text merged.
List<PatternPart> parsePattern(String pattern) {
  final parts = <PatternPart>[];
  void text(String t) {
    if (t.isEmpty) return;
    final last = parts.isEmpty ? null : parts.last;
    if (last?.literal != null) {
      parts[parts.length - 1] = PatternPart.literal(last!.literal! + t);
    } else {
      parts.add(PatternPart.literal(t));
    }
  }

  _walk(pattern, (letter, width) {
    final type = _typeOf(letter);
    if (type == null) {
      text(letter * width);
    } else {
      parts.add(PatternPart.segment(type, letter, width));
    }
  }, text);
  return parts;
}

/// [n] in the locale's digits, [width] wide (zero-padded).
String localDigits(DesignLocaleData data, int n, {int width = 1}) {
  final ascii = n.toString().padLeft(width, '0');
  final zero = data.zeroDigit;
  if (zero == null) return ascii;
  final base = zero.codeUnitAt(0);
  return String.fromCharCodes(
    ascii.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? base + c - 0x30 : c),
  );
}

/// [when] written in [pattern], in [data]'s names and digits, with [am] and
/// [pm] for the day period.
String formatPattern(
  String pattern,
  DateTime when, {
  required DesignLocaleData data,
  required String am,
  required String pm,
}) {
  final out = StringBuffer();
  final month = when.month - 1;
  final day = when.weekday % 7;
  String n(int value, int width) =>
      localDigits(data, value, width: width >= 2 ? 2 : 1);
  _walk(pattern, (c, w) {
    out.write(switch (c) {
      'y' =>
        w == 2
            ? localDigits(data, when.year % 100, width: 2)
            : localDigits(data, when.year),
      'M' when w >= 4 => data.months[month],
      'M' when w == 3 => data.shortMonths[month],
      'L' when w >= 4 => data.standaloneMonths[month],
      'L' when w == 3 => data.standaloneShortMonths[month],
      'M' || 'L' => n(when.month, w),
      'd' => n(when.day, w),
      'E' => w >= 4 ? data.weekdays[day] : data.shortWeekdays[day],
      'c' =>
        w >= 4
            ? data.standaloneWeekdays[day]
            : data.standaloneShortWeekdays[day],
      'G' => data.eras[when.year > 0 ? 1 : 0],
      'h' => n(when.hour % 12 == 0 ? 12 : when.hour % 12, w),
      'H' => n(when.hour, w),
      'K' => n(when.hour % 12, w),
      'k' => n(when.hour == 0 ? 24 : when.hour, w),
      'm' => n(when.minute, w),
      's' => n(when.second, w),
      'a' => when.hour < 12 ? am : pm,
      _ => c * w,
    });
  }, out.write);
  return out.toString();
}

/// The days in [month] (1–12) of [year]; a leap year's February when the
/// year is not known yet.
int daysInMonth(int? year, int month) =>
    DateTime.utc(year ?? 2000, month + 1, 0).day;

/// A segment's least value: its pattern [letter]'s.
int segmentMin(String letter) => switch (letter) {
  'H' || 'K' || 'm' || 's' || 'a' => 0,
  _ => 1,
};

/// A segment's greatest value: a month's days when [year] and [month] are
/// known (31 when the month is not).
int segmentMax(String letter, {int? year, int? month}) => switch (letter) {
  'y' => 9999,
  'M' || 'L' => 12,
  'd' => month == null ? 31 : daysInMonth(year, month),
  'h' => 12,
  'H' => 23,
  'K' => 11,
  'k' => 24,
  'm' || 's' => 59,
  _ => 1,
};

/// How many digits a segment takes: a year 4, AM/PM none, the rest 2.
int segmentDigits(String letter) => switch (letter) {
  'y' => 4,
  'a' => 0,
  _ => 2,
};

/// The result of typing a digit into a segment.
typedef TypedDigit = ({String typed, int value, bool advance});

/// [digit] typed into a segment that holds the digits [typed] so far, the
/// segment taking [min] to [max] in at most [digits] digits: appended where
/// the number still fits, else starting again; moving on once no further
/// digit could fit ("1" in a month waits for 10–12, "3" moves on).
TypedDigit typeDigit(
  String typed,
  int digit, {
  required int min,
  required int max,
  required int digits,
}) {
  var next = '$typed$digit';
  if (next.length > digits || int.parse(next) > max) next = '$digit';
  final value = int.parse(next);
  final advance = next.length >= digits || value * 10 > max;
  return (typed: next, value: value, advance: advance);
}

/// [value] stepped by [delta] within [min]…[max], wrapping round when
/// [wrap] (12 on to 1), else held at the ends (a year).
int stepSegment(int value, int delta, int min, int max, {bool wrap = true}) {
  final next = value + delta;
  if (!wrap) return next.clamp(min, max);
  final span = max - min + 1;
  return min + ((next - min) % span + span) % span;
}

/// Whether [text] holds a character written right to left (Hebrew, Arabic
/// and their marks), which breaks a run of digits read left to right.
bool hasRightToLeft(String text) => text.runes.any(
  (r) =>
      r == 0x200F ||
      r == 0x061C ||
      (r >= 0x0590 && r <= 0x08FF) ||
      (r >= 0xFB1D && r <= 0xFDFF) ||
      (r >= 0xFE70 && r <= 0xFEFF),
);

/// [parts] in runs for a right-to-left line: digits joined by text with no
/// right-to-left character ("16.11.2026", "3:05") read left to right as
/// one run, as the bidi algorithm reads a number; each other part stands on
/// its own. Each run is a list of indices into [parts].
List<List<int>> numberRuns(List<PatternPart> parts) {
  bool numeric(PatternPart p) =>
      p.type != null && p.type != DesignDateSegmentType.dayPeriod;
  final runs = <List<int>>[];
  var i = 0;
  while (i < parts.length) {
    if (!numeric(parts[i])) {
      runs.add([i]);
      i++;
      continue;
    }
    final run = [i];
    var j = i + 1;
    // Take text and the next number while the text has no right-to-left.
    while (j + 1 < parts.length &&
        parts[j].literal != null &&
        !hasRightToLeft(parts[j].literal!) &&
        numeric(parts[j + 1])) {
      run
        ..add(j)
        ..add(j + 1);
      j += 2;
    }
    runs.add(run);
    i = j;
  }
  return runs;
}

/// [items] in groups a line of wrapped segments never breaks inside: each
/// item that is not [isText] with the text items after it, text before the
/// first such item joining it, so that no line starts with a separator.
List<List<T>> unbreakable<T>(List<T> items, bool Function(T item) isText) {
  final groups = <List<T>>[];
  final lead = <T>[];
  for (final item in items) {
    if (!isText(item)) {
      groups.add([...lead, item]);
      lead.clear();
    } else if (groups.isEmpty) {
      lead.add(item);
    } else {
      groups.last.add(item);
    }
  }
  if (lead.isNotEmpty) groups.add(lead);
  return groups;
}
