import 'localizations.dart';

/// Formats currency, dates and times for display.
///
/// Date and number formats are fixed. For translated words, pass
/// [MinimalLocalizations.of] to the formatter's `words` argument; a date or
/// a time then takes the reader's digits too (Arabic's ٢٠ نوفمبر ٢٠٢٦ and
/// ٧:٣٠ م).
/// [relative] accepts both timestamps so the caller controls the reference time.
///
/// ```dart
/// Text(MinimalFormat.money(128400, symbol: '€', cents: false), style: t.giant)
/// ```
abstract final class MinimalFormat {
  /// Currency from MINOR units — cents, pence — so app data carries integers
  /// and never a float that drifts. `cents: false` rounds to whole units for
  /// the register where the decimals are noise (a headline total, a price
  /// chip). The sign leads the symbol: `-$12.00`.
  static String money(
    int minorUnits, {
    String symbol = r'$',
    bool cents = true,
  }) {
    final negative = minorUnits < 0;
    final absolute = minorUnits.abs();
    final whole = absolute ~/ 100;
    final remainder = absolute % 100;
    final body = cents
        ? '${_grouped(whole)}.${remainder.toString().padLeft(2, '0')}'
        : _grouped(remainder >= 50 ? whole + 1 : whole);
    return '${negative ? '-' : ''}$symbol$body';
  }

  /// The full day: "28 Aug 2026". Day first, month as a word — a numeric
  /// month is the one date shape that means two different days on two sides
  /// of the Atlantic.
  static String date(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) =>
      '${words.digits(d.day)} ${words.monthsShort[d.month - 1]} '
      '${words.digits(d.year)}';

  /// The day without the year: "28 Aug", for anything inside the current
  /// season of use, where the year is noise.
  static String dayMonth(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) => '${words.digits(d.day)} ${words.monthsShort[d.month - 1]}';

  /// "Fri", or "Friday" with `short: false`. Short is the name's first
  /// three letters in a Latin script, which abbreviates that way; a name in
  /// another script prints whole (Arabic's الجمعة, never الج).
  static String weekday(
    DateTime d, {
    bool short = true,
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) {
    final name = words.weekdays[d.weekday - 1];
    final latin = name.runes.every((r) => r < 0x0250);
    return short && latin && name.length > 3 ? name.substring(0, 3) : name;
  }

  /// Formats a time on the 24-hour [clock], for example `07:12`.
  /// Use [time12] for a 12-hour clock.
  static String time(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) => clock(d, words: words);

  /// The 12-hour clock: "9:41 AM". No leading zero on the hour — a clock
  /// face, not a timestamp. The marks and digits are [words]' (Arabic's
  /// "٩:٤١ ص").
  static String time12(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) {
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final mark = d.hour < 12 ? words.anteMeridiem : words.postMeridiem;
    return '${words.digits(hour)}:${words.digits(d.minute, width: 2)} $mark';
  }

  /// The 24-hour clock Minimal prints in mono: "07:00", "21:30", in
  /// [words]' digits (Arabic's "٢١:٣٠").
  static String clock(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) => '${words.digits(d.hour, width: 2)}:${words.digits(d.minute, width: 2)}';

  /// The sortable day an audit trail or a property prints: "2026-06-02".
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// An activity row's timestamp: "28 Aug 07:12" — [dayMonth] with the day
  /// zero-padded so a mono column aligns, then the 24-hour [clock].
  static String stamp(
    DateTime d, {
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) =>
      '${words.digits(d.day, width: 2)} ${words.monthsShort[d.month - 1]} '
      '${clock(d, words: words)}';

  /// The human answer to "when": "Today", "Yesterday", "Tomorrow", "3 days
  /// ago", "In 2 days", and past a week the plain [dayMonth].
  ///
  /// Measured in CALENDAR days, not elapsed hours: 11pm to 1am is one sleep
  /// and the reader calls it yesterday, however few hours it was. It gives up
  /// at a week because "In 23 days" is a worse answer than the date.
  static String relative(
    DateTime d, {
    required DateTime now,
    MinimalLocalizations words = const MinimalLocalizationsEn(),
  }) {
    // Calendar days compared in UTC: two local midnights across a
    // daylight-saving change are 23 or 25 hours apart, and `inDays` would
    // call tomorrow today.
    final days = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    final said = words.relativeDay(days);
    return said.isEmpty ? dayMonth(d, words: words) : said;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Thousands separators, built by hand because intl is not on the system's
  /// dependency list.
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
