/// Brutal's display formatting: the times, days, sums and counts its pages
/// print, in one shape everywhere: 24-hour times with a colon ("19:30"),
/// ranges with an en dash ("19:30–23:00"), days written out ("Friday 14
/// November", "Fri 14 Nov"), a date with its year ("14 Nov 2026"), sums with two places and thousands commas
/// ("1,420.00", the currency drawn beside it), counts with commas ("1,512"),
/// a badge's count capped ("99+") and lengths as "45 min" or "1 h 45 min".
///
/// Pure and deterministic, with no locale: the same record reads the same
/// on every machine, in a test's frame as on a phone. Nothing here reads the
/// clock: the day words take the moment to measure against.
///
/// ```dart
/// Text(BrutalFormat.range(doors, close))
/// ```
abstract final class BrutalFormat {
  /// The en dash a range is joined with.
  static const String dash = '–';

  /// The true minus (U+2212) a negative sum carries.
  static const String minus = '−';

  /// The middle dot the parts of a line of facts are joined with.
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

  /// "19:30–23:00"; a range past midnight reads the same way.
  static String range(DateTime start, DateTime end) =>
      '${time(start)}$dash${time(end)}';

  /// "Friday 14 November".
  static String day(DateTime at) =>
      '${_days[at.weekday - 1]} ${at.day} ${_months[at.month - 1]}';

  /// "Fri 14 Nov".
  static String dayShort(DateTime at) =>
      '${_days[at.weekday - 1].substring(0, 3)} ${at.day} '
      '${_months[at.month - 1].substring(0, 3)}';

  /// "14 Nov 2026": a day with its year, as a record or a form states it.
  static String date(DateTime at) =>
      '${at.day} ${_months[at.month - 1].substring(0, 3)} ${at.year}';

  /// "November 2026", a month's head.
  static String month(DateTime at) => '${_months[at.month - 1]} ${at.year}';

  /// "Today", "Tomorrow" or "Yesterday", else [day]: measured against
  /// [now], never the clock.
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

  /// "1,512": a whole count with thousands commas.
  static String count(int n) {
    final digits = n.abs().toString();
    final grouped = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) grouped.write(',');
      grouped.write(digits[i]);
    }
    return '${n < 0 ? minus : ''}$grouped';
  }

  /// "1,420.00": a sum with two places and thousands commas, a negative one
  /// with the true minus. The currency is drawn beside it, by the page.
  static String sum(num amount) {
    final cents = (amount.abs() * 100).round();
    final whole = count(cents ~/ 100);
    return '${amount < 0 ? minus : ''}$whole.${_two(cents % 100)}';
  }

  /// A badge's count: "3", or "99+" past [max].
  static String badge(int n, {int max = 99}) => n > max ? '$max+' : '$n';

  /// "45 min", "1 h", "1 h 45 min".
  static String length(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '$minutes min';
    return minutes == 0 ? '$hours h' : '$hours h $minutes min';
  }
}
