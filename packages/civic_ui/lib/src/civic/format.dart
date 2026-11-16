/// Civic's display formatting: the dates, times, sums and counts a public
/// service prints, in the plain shapes such services write them. A date is
/// day, month in full, year ("14 November 2026"), never a number for the
/// month and never an ordinal. A time is "9am", "5:30pm", "midday" or
/// "midnight" on a twelve-hour device and "17:30" on a 24-hour one. A
/// range is joined by "to", which a screen reader says as written ("9am to
/// 5pm"). A sum drops its zero cents ("€60", "€62.50").
///
/// PURE AND DETERMINISTIC, no intl, as the design kit's [DisplayFormat]: a
/// generated app renders inside walkthroughs and golden frames, and a
/// locale-aware formatter would make one record read differently on two
/// machines. Nothing here reads the clock: [relative] takes the moment to
/// measure against. The words are English; a service in another language
/// says its own.
///
/// ```dart
/// Text('Your permit ends on ${CivicFormat.date(permit.ends)}')
/// ```
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/host.dart';

/// Civic's formatters.
abstract final class CivicFormat {
  /// A sum from its minor units (cents), so data carries whole numbers and
  /// never a float that drifts: "€60" when the cents are zero, else
  /// "€62.50"; with `cents: true` always two places ("€60.00", for a
  /// column of sums that line up). A negative leads with the minus:
  /// "-€12".
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

  /// The day: "14 November 2026"; with [weekday], "Saturday 14 November
  /// 2026".
  static String date(DateTime d, {bool weekday = false}) =>
      '${weekday ? '${CivicFormat.weekday(d)} ' : ''}${dayMonth(d)} ${d.year}';

  /// The day without its year: "14 November", for a day in the year the
  /// reader is in.
  static String dayMonth(DateTime d) => '${d.day} ${month(d)}';

  /// The month in full: "November".
  static String month(DateTime d) => DisplayFormat.month(d, short: false);

  /// The day of the week in full: "Saturday".
  static String weekday(DateTime d) => DisplayFormat.weekday(d, short: false);

  /// Two days as a range: "3 to 14 November 2026" in one month,
  /// "28 October to 14 November 2026" in one year, else both in full.
  static String dateRange(DateTime start, DateTime end) {
    if (start.year != end.year) return '${date(start)} to ${date(end)}';
    if (start.month != end.month) {
      return '${dayMonth(start)} to ${date(end)}';
    }
    return '${start.day} to ${date(end)}';
  }

  /// The time of day as the reader's device prints it: "17:30" when it
  /// asks for the 24-hour clock ([MediaQuery.alwaysUse24HourFormatOf]),
  /// else "5:30pm".
  static String time(BuildContext context, DateTime d) =>
      clock(d, twentyFourHour: MediaQuery.alwaysUse24HourFormatOf(context));

  /// The time of day on the clock asked for: "17:30" and "09:05" on the
  /// 24-hour clock; else "5:30pm", "9am" (no ":00"), and "midday" and
  /// "midnight" for the two that "12am" and "12pm" leave in doubt. [time]
  /// is the one a page calls; this is its pure core.
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

  /// The answer to "when" against [now]: "today", "yesterday",
  /// "tomorrow", and any other day by its date ("14 November", with its
  /// year when it is not [now]'s). Lower case, as it stands in a sentence
  /// ("Sent today"); a sentence that starts with it raises its first
  /// letter. Counted in calendar days, so 11pm to 1am is a day.
  static String relative(DateTime d, {required DateTime now}) {
    final days = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'today';
    if (days == -1) return 'yesterday';
    if (days == 1) return 'tomorrow';
    return d.year == now.year ? dayMonth(d) : date(d);
  }
}
