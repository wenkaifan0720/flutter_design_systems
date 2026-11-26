// Fluent 2's own words for a picker's title, and when a part shows them rather than ui_core's.
import 'package:flutter/widgets.dart';

import '../localizations.dart';

/// [word] of the Fluent 2 words at [context], unless it is Fluent 2's stock
/// English and the app reads another language: then null, and the part
/// takes ui_core's word for it in the app's language (`RawPickerWords`'
/// "Select time"), or, where ui_core has none, shows none and a screen
/// reader hears the part's kind (a dialog) in the app's language.
String? fluent2OwnWord(
  BuildContext context,
  String Function(Fluent2Localizations words) word,
) {
  final own = word(Fluent2Localizations.of(context));
  final english =
      (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'en';
  return english || own != word(const Fluent2LocalizationsEn()) ? own : null;
}
