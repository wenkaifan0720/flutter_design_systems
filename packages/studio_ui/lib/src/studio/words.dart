/// The words Studio's own parts say beyond ui_core's ([RawWidgetsLocalizations]):
/// [StudioLocalizations], every count a real plural in the app's language.
library;

import 'package:flutter/foundation.dart' show SynchronousFuture;
import 'package:flutter/widgets.dart';

/// What Studio's parts say on their own that ui_core's words do not hold:
/// counts, each a real plural (one row, two rows), never a number glued to
/// a noun.
///
/// English ships ([DefaultStudioLocalizations]). An app in another language
/// extends it, words each count in its language's plural forms (one, few,
/// many, other as the language has them), and adds a delegate that loads
/// its subclass, as it does for `WidgetsLocalizations`. With none installed
/// the parts speak English.
///
/// ```dart
/// Text(StudioLocalizations.of(context).rowCount(rows.length))
/// ```
abstract class StudioLocalizations {
  /// Const constructor, for subclasses.
  const StudioLocalizations();

  /// The words in force at [context]: the installed delegate's, else
  /// English.
  static StudioLocalizations of(BuildContext context) =>
      Localizations.of<StudioLocalizations>(context, StudioLocalizations) ??
      const DefaultStudioLocalizations();

  /// Loads Studio's English words for any locale, so the parts never go
  /// without words; an app in another language adds its own delegate
  /// before it.
  static const LocalizationsDelegate<StudioLocalizations> delegate =
      _StudioLocalizationsDelegate();

  /// How many rows a table holds after its filter: "1 row", "12 rows".
  String rowCount(int count);
}

/// Studio's words in English.
class DefaultStudioLocalizations extends StudioLocalizations {
  /// English.
  const DefaultStudioLocalizations();

  @override
  String rowCount(int count) => count == 1 ? '1 row' : '$count rows';
}

class _StudioLocalizationsDelegate
    extends LocalizationsDelegate<StudioLocalizations> {
  const _StudioLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<StudioLocalizations> load(Locale locale) =>
      SynchronousFuture<StudioLocalizations>(
        const DefaultStudioLocalizations(),
      );

  @override
  bool shouldReload(_StudioLocalizationsDelegate old) => false;
}
