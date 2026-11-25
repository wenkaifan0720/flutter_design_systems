// The words Frosted's parts say that every design system says too (Done, Try again, a day's and a month's names, a
// time), in the reader's language. Frosted's own, when the app gives Frosted words of its own or the reader reads
// English (its English is the design's: "Monday, November 9, 2026"); else ui_core's RawWidgetsLocalizations, which speak
// 30 languages. An app installs FrostedLocalizations.delegate in any language and its parts speak that language's
// shared words.
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../localizations.dart';

/// The words at a context that Frosted shares with every design system,
/// each Frosted's own unless it is Frosted's stock English and the reader
/// reads another language: then `RawWidgetsLocalizations`' word for it.
class FrostedSharedWords {
  const FrostedSharedWords._(this._own, this._shared, this._english);

  /// The words in force at [context].
  factory FrostedSharedWords.of(BuildContext context) => FrostedSharedWords._(
    FrostedLocalizations.of(context),
    RawWidgetsLocalizations.of(context),
    (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'en',
  );

  final FrostedLocalizations _own;
  final RawWidgetsLocalizations _shared;
  final bool _english;

  static const _stock = FrostedLocalizationsEn();

  String _say(String own, String stock, String Function() shared) =>
      _english || own != stock ? own : shared();

  /// What a finished step says.
  String get done =>
      _say(_own.done, _stock.done, () => _shared.doneButtonLabel);

  /// The error state's way to try again.
  String get tryAgain =>
      _say(_own.tryAgain, _stock.tryAgain, () => _shared.retryButtonLabel);

  /// A day as the calendar says it.
  String fullDate(DateTime day) => _say(
    _own.fullDate(day),
    _stock.fullDate(day),
    () => _shared.formatFullDate(day),
  );

  /// A month and its year, as a calendar's head says them.
  String monthYear(DateTime month) => _say(
    '${_own.monthName(month.month)} ${_shared.formatYear(month)}',
    '${_stock.monthName(month.month)} ${_shared.formatYear(month)}',
    () => _shared.formatMonthYear(month),
  );

  /// [hour]:[minute] as a field shows it, on a 24-hour clock when [use24]
  /// ("9:05 AM", "09:05"; German's "09:05" either way). The figures are
  /// always the reader's digits (`RawTimeFormatting.formatHour` and
  /// `formatMinute`), with Frosted's own words for the halves of the day.
  String time(int hour, int minute, {required bool use24}) {
    final at = RawTimeOfDay(hour: hour, minute: minute);
    final mm = _shared.formatMinute(at);
    String told(FrostedLocalizations words) {
      if (use24) {
        return '${_shared.formatHour(at, alwaysUse24HourFormat: true)}:$mm';
      }
      final h = _shared.formatDecimal(at.hourOfPeriod);
      return '$h:$mm ${hour < 12 ? words.am : words.pm}';
    }

    return _say(
      told(_own),
      told(_stock),
      () => _shared.formatTimeOfDay(
        RawTimeOfDay(hour: hour, minute: minute),
        alwaysUse24HourFormat: use24,
      ),
    );
  }
}
