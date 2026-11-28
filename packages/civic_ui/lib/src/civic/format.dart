/// Date, time, amount and count formats for public services.
///
/// Dates use a written month, so a day never reads as another (3/4 is the
/// 3rd of April in one place and March the 4th in another), in the order
/// the app's locale writes a day, as a date field does (see
/// `CivicDatePicker`): [CivicFormat.dateOf] writes `November 14, 2026` in
/// American English and `14 November 2026` in British English. Time ranges
/// use the word “to”. [CivicFormat.time] follows the device’s clock setting.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';
import 'package:ui_core/ui_core.dart';

/// Formats dates, times and numbers for Civic services.
///
/// The dates ([dateOf], [dayMonthOf], [dateRangeOf], [relativeOf]) follow
/// the app's locale, as its date fields do, so one screen never writes a day
/// two ways: the locale's order, month words and digits, from
/// `RawWidgetsLocalizations`. Under a default `MaterialApp` that is
/// American English ("November 14, 2026" beside a field showing
/// 11/14/2026); for day-first English give the app
/// `locale: Locale('en', 'GB')` ("14 November 2026" beside 14/11/2026). The
/// times, sums and counts are English in every language; an app's own time
/// in its language and digits is `RawWidgetsLocalizations.formatTimeOfDay`
/// (or `formatHour` and `formatMinute`).
abstract final class CivicFormat {
  /// Formats [minorUnits] with [symbol], for example `€60` or `€62.50`.
  ///
  /// Set [cents] to show two decimal places even for a whole amount.
  static String money(
    int minorUnits, {
    required String symbol,
    bool cents = false,
  }) {
    final whole = minorUnits.abs() % 100 == 0;
    return DisplayFormat.money(
      minorUnits,
      symbol: symbol,
      cents: cents || !whole,
    );
  }

  /// A count with thousands separators: "1,240".
  static String count(int value) => DisplayFormat.count(value);

  /// A count with its noun: "1 permit", "3 permits"; [many] for a plural
  /// that is not the noun and an s ("2 people").
  static String plural(int n, String one, [String? many]) =>
      '${count(n)} ${n == 1 ? one : (many ?? '${one}s')}';

  /// The day as the app's locale writes it, its month in words: "November
  /// 14, 2026" in American English, "14 November 2026" in British English,
  /// "١٤ نوفمبر ٢٠٢٦" in Arabic. With [weekday], the locale's full date
  /// ("Saturday, November 14, 2026"). The order is the one the app's date
  /// fields use, so a page never writes a day two ways.
  static String dateOf(
    BuildContext context,
    DateTime d, {
    bool weekday = false,
  }) {
    final words = RawWidgetsLocalizations.of(context);
    return weekday
        ? words.formatFullDate(d)
        : _spelled(words, words.formatMediumDate(d), d);
  }

  /// The day without its year as the app's locale writes it, its month in
  /// words: "November 14" in American English, "14 November" in British
  /// English. For a day in the year the reader is in.
  static String dayMonthOf(BuildContext context, DateTime d) {
    final words = RawWidgetsLocalizations.of(context);
    return _spelled(words, words.formatShortMonthDay(d), d);
  }

  /// Two days as a range in the app's locale: "November 3 to November 14,
  /// 2026" in American English, "3 November to 14 November 2026" in British,
  /// the year once where both days share it, else both in full. English
  /// joins them with "to"; another language with a dash.
  static String dateRangeOf(
    BuildContext context,
    DateTime start,
    DateTime end,
  ) {
    final to = _english(context) ? ' to ' : ' – ';
    return start.year == end.year
        ? '${dayMonthOf(context, start)}$to${dateOf(context, end)}'
        : '${dateOf(context, start)}$to${dateOf(context, end)}';
  }

  /// The answer to "when" against [now], in the app's locale: in English
  /// "today", "yesterday", "tomorrow", lower case as it stands in a sentence
  /// ("Sent today"; a sentence that starts with it raises its first letter);
  /// in another language the locale's word for today. Any other day by
  /// [dayMonthOf], with its year ([dateOf]) when it is not [now]'s. Counted
  /// in calendar days, so 11pm to 1am is a day.
  static String relativeOf(
    BuildContext context,
    DateTime d, {
    required DateTime now,
  }) {
    final days = _daysApart(d, now);
    final english = _english(context);
    if (days == 0) {
      return english
          ? 'today'
          : RawWidgetsLocalizations.of(context).currentDateLabel;
    }
    if (english && days == -1) return 'yesterday';
    if (english && days == 1) return 'tomorrow';
    return d.year == now.year ? dayMonthOf(context, d) : dateOf(context, d);
  }

  static bool _english(BuildContext context) =>
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'en';

  static int _daysApart(DateTime d, DateTime now) => DateTime.utc(
    d.year,
    d.month,
    d.day,
  ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;

  // [text], a locale pattern's day with its month short, with the month in
  // full: the locale's month and year with the year taken away. A locale
  // whose pattern writes the month as a number keeps it.
  static String _spelled(
    RawWidgetsLocalizations words,
    String text,
    DateTime d,
  ) {
    final short = words.formatShortMonth(d);
    final full = words
        .formatMonthYear(d)
        .replaceFirst(words.formatYear(d), '')
        .trim();
    if (short.isEmpty || full.isEmpty || !text.contains(short)) return text;
    return text.replaceFirst(short, full);
  }

  /// The day in English, day first: "14 November 2026"; with [weekday],
  /// "Saturday 14 November 2026". The same in every locale, so beside a date
  /// field under another locale a page writes a day two ways.
  @Deprecated(
    "Use CivicFormat.dateOf, which writes the day in the app's locale, as "
    'its date fields do. Removed in 1.0.0.',
  )
  static String date(DateTime d, {bool weekday = false}) => _date(d, weekday);

  static String _date(DateTime d, bool weekday) =>
      '${weekday ? '${CivicFormat.weekday(d)} ' : ''}${_dayMonth(d)} ${d.year}';

  /// The day without its year in English, day first: "14 November".
  @Deprecated(
    "Use CivicFormat.dayMonthOf, which writes the day in the app's locale. "
    'Removed in 1.0.0.',
  )
  static String dayMonth(DateTime d) => _dayMonth(d);

  static String _dayMonth(DateTime d) => '${d.day} ${month(d)}';

  /// The month in full: "November".
  static String month(DateTime d) => DisplayFormat.month(d, short: false);

  /// The day of the week in full: "Saturday".
  static String weekday(DateTime d) => DisplayFormat.weekday(d, short: false);

  /// Two days as a range in English: "3 to 14 November 2026" in one month,
  /// "28 October to 14 November 2026" in one year, else both in full.
  @Deprecated(
    "Use CivicFormat.dateRangeOf, which writes the days in the app's "
    'locale. Removed in 1.0.0.',
  )
  static String dateRange(DateTime start, DateTime end) {
    if (start.year != end.year) {
      return '${_date(start, false)} to ${_date(end, false)}';
    }
    if (start.month != end.month) {
      return '${_dayMonth(start)} to ${_date(end, false)}';
    }
    return '${start.day} to ${_date(end, false)}';
  }

  /// The time of day as the reader's device prints it: "17:30" when it
  /// asks for the 24-hour clock ([MediaQuery.alwaysUse24HourFormatOf]),
  /// else "5:30pm".
  static String time(BuildContext context, DateTime d) =>
      clock(d, twentyFourHour: MediaQuery.alwaysUse24HourFormatOf(context));

  /// Formats [d] as a 24-hour time or an English 12-hour time.
  ///
  /// The 12-hour format uses `midday`, `midnight`, `9am` and `5:30pm`.
  /// Use [time] to follow the device’s clock setting.
  static String clock(DateTime d, {required bool twentyFourHour}) {
    if (twentyFourHour) {
      return DisplayFormat.clock(d, twentyFourHour: true);
    }
    if (d.minute == 0 && d.hour == 0) return 'midnight';
    if (d.minute == 0 && d.hour == 12) return 'midday';
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute == 0
        ? ''
        : ':${d.minute.toString().padLeft(2, '0')}';
    return '$hour$minute${d.hour < 12 ? 'am' : 'pm'}';
  }

  /// Two times as a range on the clock asked for: "9am to 5pm".
  static String clockRange(
    DateTime start,
    DateTime end, {
    required bool twentyFourHour,
  }) =>
      '${clock(start, twentyFourHour: twentyFourHour)} to '
      '${clock(end, twentyFourHour: twentyFourHour)}';

  /// The answer to "when" against [now] in English: "today", "yesterday",
  /// "tomorrow", and any other day by its date ("14 November", with its
  /// year when it is not [now]'s). Lower case, as it stands in a sentence
  /// ("Sent today"); a sentence that starts with it raises its first
  /// letter. Counted in calendar days, so 11pm to 1am is a day.
  @Deprecated(
    "Use CivicFormat.relativeOf, which writes the day in the app's locale. "
    'Removed in 1.0.0.',
  )
  static String relative(DateTime d, {required DateTime now}) {
    final days = _daysApart(d, now);
    if (days == 0) return 'today';
    if (days == -1) return 'yesterday';
    if (days == 1) return 'tomorrow';
    return d.year == now.year ? _dayMonth(d) : _date(d, false);
  }
}
