import 'package:flutter/widgets.dart' show StringCharacters;

/// Fluent 2's display formatting: the dates, clock times, relative times,
/// counts, sizes and durations a Fluent 2 row prints, in the shapes Fluent's
/// own products write them ("Mon, Nov 3", "9:41 AM", "2h ago", "2.4 MB",
/// "1 h 30 min").
///
/// PURE AND DETERMINISTIC, no intl. A generated app renders inside
/// walkthroughs and golden frames, and a locale-aware formatter makes the
/// same record read differently on two machines, which turns a diff into a
/// false failure. The vocabulary is US English and the shapes are fixed, so
/// a screen's text is a function of its data and nothing else.
///
/// Nothing here touches [DateTime.now]: the relative words take the moment
/// to measure against as an argument, because a formatter that reads the
/// clock cannot be tested.
///
/// ```dart
/// Text(Fluent2Format.ago(file.modified, now: now), style: t.caption1)
/// ```
abstract final class Fluent2Format {
  /// The minus a negative figure takes: the hyphen-minus, since Selawik
  /// has no U+2212 and a fallback face would set it in other metrics.
  static const String minus = '-';

  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<String> _weekdays = <String>[
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// "Nov 3", or "Mon, Nov 3" with [weekday], "Nov 3, 2026" with [year].
  static String date(DateTime d, {bool weekday = false, bool year = false}) {
    final day = '${month(d, short: true)} ${d.day}';
    return '${weekday ? '${Fluent2Format.weekday(d)}, ' : ''}$day'
        '${year ? ', ${d.year}' : ''}';
  }

  /// "Monday, November 3": a page's or a day's head.
  static String longDate(DateTime d) =>
      '${weekday(d, short: false)}, ${month(d)} ${d.day}';

  /// "November", "Nov" with [short], "November 2026" with [year].
  static String month(DateTime d, {bool short = false, bool year = false}) {
    final name = _months[d.month - 1];
    return '${short ? name.substring(0, 3) : name}${year ? ' ${d.year}' : ''}';
  }

  /// "Mon", or "Monday" with `short: false`.
  static String weekday(DateTime d, {bool short = true}) {
    final name = _weekdays[d.weekday - 1];
    return short ? name.substring(0, 3) : name;
  }

  /// The 12-hour clock: "9:41 AM", no leading zero on the hour.
  static String time(DateTime d) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:${_two(d.minute)} ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// A meeting's span: "9:00 – 9:30 AM", or both halves of the day named
  /// when it crosses noon ("11:30 AM – 12:15 PM").
  static String timeRange(DateTime start, DateTime end) {
    final a = time(start), b = time(end);
    final sameHalf = (start.hour < 12) == (end.hour < 12);
    return sameHalf ? '${a.substring(0, a.length - 3)} – $b' : '$a – $b';
  }

  /// The day word a list prints: "Today", "Yesterday", "Tomorrow", the
  /// weekday within the week either side, else [date].
  static String day(DateTime d, {required DateTime now}) {
    final days = _days(d, now);
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    if (days == 1) return 'Tomorrow';
    if (days > -7 && days < 7) return weekday(d, short: false);
    return date(d, year: d.year != now.year);
  }

  /// How long ago, as a row's meta prints it: "Just now", "5m ago",
  /// "2h ago", "Yesterday", then [date]. Calendar days decide past the
  /// first day, so 11 PM seen at 1 AM is yesterday.
  static String ago(DateTime d, {required DateTime now}) {
    final elapsed = now.difference(d);
    if (elapsed.inMinutes < 1) return 'Just now';
    if (elapsed.inMinutes < 60) return '${elapsed.inMinutes}m ago';
    final days = _days(d, now);
    if (days == 0) return '${elapsed.inHours}h ago';
    if (days == -1) return 'Yesterday';
    if (days > -7) return weekday(d, short: false);
    return date(d, year: d.year != now.year);
  }

  /// A duration as Fluent's calendars print one: "45 min", "1 h",
  /// "1 h 30 min".
  static String duration(Duration span) {
    final h = span.inHours, m = span.inMinutes % 60;
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }

  /// A file's size: "512 B", "18 KB", "2.4 MB", "1.2 GB" (1,024 a step, one
  /// decimal from megabytes up, none under ten).
  static String bytes(int size) {
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = size.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < units.length - 1) {
      value /= 1024;
      unit += 1;
    }
    final digits = unit < 2 || value >= 10 ? 0 : 1;
    return '${value.toStringAsFixed(digits)} ${units[unit]}';
  }

  /// A count with its thousands separated: "1,284"; [compact] shortens
  /// past ten thousand ("12K", "3.4M"), as a badge or a stat prints it.
  static String count(int value, {bool compact = false}) {
    final sign = value < 0 ? minus : '';
    final n = value.abs();
    if (compact && n >= 10000) {
      final (v, s) = n >= 1000000 ? (n / 1000000, 'M') : (n / 1000, 'K');
      final text = v >= 100 ? v.round().toString() : v.toStringAsFixed(1);
      return '$sign${text.endsWith('.0') ? text.substring(0, text.length - 2) : text}$s';
    }
    return '$sign${_grouped(n)}';
  }

  /// "1 file", "3 files"; [many] for an irregular plural.
  static String plural(int n, String one, [String? many]) =>
      '${count(n)} ${n == 1 ? one : many ?? '${one}s'}';

  /// A whole share of [whole], 0 to 100.
  static int percent(num part, num whole) =>
      whole == 0 ? 0 : (part / whole * 100).round().clamp(0, 100);

  /// Money from MINOR units (cents), so data carries integers: "$1,326.44",
  /// "-$12.00"; [cents] false rounds to whole units.
  static String money(
    int minorUnits, {
    String symbol = r'$',
    bool cents = true,
  }) {
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    final whole = absolute ~/ 100, rest = absolute % 100;
    final body = cents
        ? '${_grouped(whole)}.${_two(rest)}'
        : _grouped(rest >= 50 ? whole + 1 : whole);
    return '${negative ? minus : ''}$symbol$body';
  }

  /// A person's initials as an avatar sets them: the first letters of the
  /// first and last words ("Ines Duarte" is "ID"), one for one word.
  static String initials(String name) {
    final words = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return '';
    final first = words.first.characters.first;
    if (words.length == 1) return first.toUpperCase();
    return (first + words.last.characters.first).toUpperCase();
  }

  static int _days(DateTime d, DateTime now) => DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _grouped(int value) {
    final digits = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index += 1) {
      final fromEnd = digits.length - index;
      if (index > 0 && fromEnd % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return buffer.toString();
  }
}
