/// Brutal's own words, the few that ui_core's RawWidgetsLocalizations has no
/// entry for. English by default; an app in another language gives its own
/// through Flutter's localizations.
library;

import 'package:flutter/widgets.dart';

/// The words Brutal's parts speak that ui_core's `RawWidgetsLocalizations` does
/// not carry. Each counted message is given its count, so a language picks
/// its own plural form (English has two, Polish three, Arabic six).
///
/// The class is English. An app in another language subclasses it and gives
/// it to [Localizations] with a `LocalizationsDelegate<BrutalLocalizations>`
/// in its `localizationsDelegates`; with none, Brutal speaks English.
///
/// ```dart
/// Text(BrutalLocalizations.of(context).rowCount(rows.length))
/// ```
@immutable
class BrutalLocalizations {
  /// English.
  const BrutalLocalizations();

  /// The app's [BrutalLocalizations] for [context]'s locale, else English.
  static BrutalLocalizations of(BuildContext context) =>
      Localizations.of<BrutalLocalizations>(context, BrutalLocalizations) ??
      const BrutalLocalizations();

  /// How many rows a data table holds after its filter, under its pages
  /// (English: 1 row, 2 rows).
  String rowCount(int count) => count == 1 ? '1 row' : '$count rows';
}
