/// Display formatting: money, counts, dates, clock times and the relative
/// day — the strings a generated screen actually prints.
///
/// PURE AND DETERMINISTIC, no intl. A generated app renders inside
/// walkthroughs and golden frames, and a locale-aware formatter makes the
/// same record read differently on two machines, which turns a diff into a
/// false failure. The vocabulary here is English and the shapes are fixed,
/// so a screen's text is a function of its data and one user setting (the
/// 24-hour clock) and nothing else. An app that genuinely ships to several
/// locales replaces these at that point; it does not need them to be
/// half-localised now.
///
/// Nothing here touches [DateTime.now]: [DisplayFormat.relative] takes the
/// moment to measure against as an argument, because a formatter that reads
/// the clock cannot be tested.
library;

import 'package:flutter/widgets.dart';

/// The formatters. A design system re-exports this file from its own
/// `format.dart` and may name the class after itself
/// (`typedef ExpressiveFormat = DisplayFormat;`), so page code reads
/// `ExpressiveFormat.money(…)`.
///
/// ```dart
/// Text(DisplayFormat.money(129900))
/// ```
abstract final class DisplayFormat {
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

  /// Currency from MINOR units — cents, pence — so app data carries integers
  /// and never a float that drifts. `cents: false` rounds half up to whole
  /// units where the decimals are noise (a headline total,
  /// a price chip). The sign leads the symbol: `-$12.00`.
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

  /// A count with thousands separators — steps, followers, a place in a
  /// league: `1240` → "1,240". The sign leads: "-1,240".
  static String count(int value) =>
      '${value < 0 ? '-' : ''}${_grouped(value.abs())}';

  /// The full day: "28 Aug 2026". Day first, month as a word — a numeric
  /// month is the one date shape that means two different days on two sides
  /// of the Atlantic.
  static String date(DateTime d) => '${d.day} ${month(d)} ${d.year}';

  /// The day without the year: "28 Aug", for anything inside the current
  /// season of use, where the year is noise.
  static String dayMonth(DateTime d) => '${d.day} ${month(d)}';

  /// "Aug", or "August" with `short: false` — a month header, a wheel.
  static String month(DateTime d, {bool short = true}) {
    final name = _months[d.month - 1];
    return short ? name.substring(0, 3) : name;
  }

  /// "Fri", or "Friday" with `short: false`.
  static String weekday(DateTime d, {bool short = true}) {
    final name = _weekdays[d.weekday - 1];
    return short ? name.substring(0, 3) : name;
  }

  /// The time of day as the reader's device prints it: the 24-hour clock
  /// ("07:05", "21:30") when the platform asks for it
  /// ([MediaQuery.alwaysUse24HourFormatOf]), else the 12-hour face
  /// ("7:05 AM", "9:30 PM"). It never hard-codes either.
  static String time(BuildContext context, DateTime d) =>
      clock(d, twentyFourHour: MediaQuery.alwaysUse24HourFormatOf(context));

  /// The time of day on the clock asked for: [twentyFourHour] prints
  /// "07:05" (the hour zero-padded, as a 24-hour device prints it),
  /// otherwise "7:05 AM" — no leading zero on a twelve-hour clock face.
  /// [time] is the one a screen calls; this is its pure core.
  static String clock(DateTime d, {required bool twentyFourHour}) {
    final minute = _two(d.minute);
    if (twentyFourHour) return '${_two(d.hour)}:$minute';
    final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '$hour:$minute ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  /// The sortable day an audit trail or a property prints: "2026-06-02".
  static String isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  /// The human answer to "when": "Today", "Yesterday", "Tomorrow", "3 days
  /// ago", "In 2 days", and past a week the plain [dayMonth].
  ///
  /// Measured in CALENDAR days, not elapsed hours: 11pm to 1am is one sleep
  /// and the reader calls it yesterday, however few hours it was. It gives
  /// up at a week because "In 23 days" is a worse answer than the date.
  static String relative(DateTime d, {required DateTime now}) {
    // Calendar days compared as UTC dates: two LOCAL midnights across a
    // daylight-saving change are 23 or 25 hours apart, and `inDays` would
    // floor the short one to zero — tomorrow would read "Today", and the
    // answer would hang on the machine's time zone.
    final days = DateTime.utc(
      d.year,
      d.month,
      d.day,
    ).difference(DateTime.utc(now.year, now.month, now.day)).inDays;
    if (days == 0) return 'Today';
    if (days == -1) return 'Yesterday';
    if (days == 1) return 'Tomorrow';
    if (days < -1 && days > -7) return '${-days} days ago';
    if (days > 1 && days < 7) return 'In $days days';
    return dayMonth(d);
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Thousands separators, built by hand because intl is not a
  /// dependency.
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
