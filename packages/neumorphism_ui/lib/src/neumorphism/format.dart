import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart' show RawWidgetsLocalizations;

import 'localizations.dart';

/// Display formatting from the Neumorphism localization at the call site.
/// Explicit data goes in; no formatter reads the clock or ambient global locale.
abstract final class NeumorphicFormat {
  /// A number in the active locale, with at most [maximumFractionDigits].
  static String number(
    BuildContext context,
    num value, {
    int maximumFractionDigits = 1,
  }) =>
      NeumorphicLocalizations.of(context)
          .formatNumber(value, maximumFractionDigits: maximumFractionDigits);

  /// A fraction expressed as a percentage in the active locale.
  static String percent(BuildContext context, num value) =>
      NeumorphicLocalizations.of(context).formatPercent(value);

  /// A full date, including weekday, month and year.
  static String date(BuildContext context, DateTime value) =>
      NeumorphicLocalizations.of(context).formatFullDate(value);

  /// A day as a field or a list shows one: the day, its month short and the year, in the locale's order ("Nov 26,
  /// 2026" in American English, "26 nov. 2026" in French).
  static String mediumDate(BuildContext context, DateTime value) =>
      RawWidgetsLocalizations.of(context).formatMediumDate(value);

  /// An hour and minute on the look's 24-hour scale.
  static String time(BuildContext context, DateTime value) =>
      NeumorphicLocalizations.of(context).formatTime(value);
}
