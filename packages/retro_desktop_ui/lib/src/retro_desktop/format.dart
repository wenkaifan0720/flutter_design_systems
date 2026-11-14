import 'package:intl/intl.dart';

/// Locale-aware display formatting shared by desktop controls and application data.
/// Non-English date symbols must be loaded by the app's localization delegate.
///
/// ```dart
/// Text(RetroDesktopFormat.number(1200))
/// ```
abstract final class RetroDesktopFormat {
  /// Formats a reading with the locale's decimal separators.
  static String number(num value, {String locale = 'en_US'}) =>
      NumberFormat.decimalPattern(locale).format(value);

  /// Formats ungrouped calendar or clock digits.
  static String integer(int value, {int digits = 1, String locale = 'en_US'}) {
    assert(digits > 0);
    return NumberFormat('0' * digits, locale).format(value);
  }

  /// Formats a calendar month heading.
  static String monthYear(DateTime value, {String locale = 'en_US'}) =>
      DateFormat.yMMMM(locale).format(value);

  /// Formats a complete date for a calendar cell's accessible name.
  static String date(DateTime value, {String locale = 'en_US'}) =>
      DateFormat.yMMMMd(locale).format(value);

  /// Formats a ratio as a localized percent.
  static String percent(double value, {String locale = 'en_US'}) =>
      NumberFormat.percentPattern(locale).format(value);
}
