/// Comic's display formatting: the times, ranges, days, sums and counts a printed caption prints, in the shapes Comic's
/// pages write them: 24-hour times with a colon ("19:30"), ranges with an en dash ("19:30–23:00"), days written out
/// ("Thursday 14 March", "Thu 14 Mar"), sums with two places and thousands commas ("1,420.00", the unit drawn beside
/// it), counts with commas ("1,512"), a badge's count capped ("99+") and lengths as "45 min" or "1 h 45 min".
///
/// PURE AND DETERMINISTIC, no intl: a generated app renders inside walkthroughs and golden frames, and a locale-aware
/// formatter would make one record read differently on two machines. Nothing here reads the clock: the day words take
/// the moment to measure against as an argument.
///
/// ```dart
/// Text(ComicFormat.range(start, end), style: t.type.body)
/// ```
abstract final class ComicFormat {
  /// The en dash a range is joined with.
  static const String dash = '–';

  /// The true minus (U+2212) a negative sum carries.
  static const String minus = '−';

  /// The middle dot a meta line's parts are joined with.
  static const String dot = ' · ';

  static const List<String> _months = [
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

  static const List<String> _days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static String _two(int n) => n.toString().padLeft(2, '0');

  /// "19:30".
  static String time(DateTime at) => '${_two(at.hour)}:${_two(at.minute)}';

  /// "19:30–23:00"; a range that crosses midnight reads the same way.
  static String range(DateTime start, DateTime end) =>
      '${time(start)}$dash${time(end)}';

  /// "Thursday 14 March".
  static String day(DateTime at) =>
      '${_days[at.weekday - 1]} ${at.day} ${_months[at.month - 1]}';

  /// "Thu 14 Mar".
  static String dayShort(DateTime at) =>
      '${_days[at.weekday - 1].substring(0, 3)} ${at.day} '
      '${_months[at.month - 1].substring(0, 3)}';

  /// "March 2027", a month's head.
  static String month(DateTime at) => '${_months[at.month - 1]} ${at.year}';

  /// "Today", "Tomorrow", "Yesterday", else [day]: measured against [now], never the clock.
  static String dayWord(DateTime at, {required DateTime now}) {
    final a = DateTime(at.year, at.month, at.day);
    final b = DateTime(now.year, now.month, now.day);
    return switch (a.difference(b).inDays) {
      0 => 'Today',
      1 => 'Tomorrow',
      -1 => 'Yesterday',
      _ => day(at),
    };
  }

  static String _grouped(int whole) {
    final digits = whole.abs().toString();
    final out = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) out.write(',');
      out.write(digits[i]);
    }
    return out.toString();
  }

  /// "1,512".
  static String count(int n) => '${n < 0 ? minus : ''}${_grouped(n)}';

  /// A badge's count: "3", "12", "99+" past 99.
  static String badge(int n) => n > 99 ? '99+' : '$n';

  /// "1,420.00": a sum with two places, its unit drawn beside it, as `ComicFigures` does.
  static String sum(num value) {
    final cents = (value.abs() * 100).round();
    final sign = value < 0 && cents > 0 ? minus : '';
    return '$sign${_grouped(cents ~/ 100)}.${_two(cents % 100)}';
  }

  /// "45 min", "1 h", "1 h 45 min".
  static String length(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m min';
    return m == 0 ? '$h h' : '$h h $m min';
  }
}
