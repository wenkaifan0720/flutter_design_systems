// The Material and Cupertino words the theme gives when the app gives none:
// the machinery under the look (a field's editable and its menu, a route's
// barrier) needs them, and an app on Flutter's own Material (with
// flutter_localizations or not) never gives material_ui's and cupertino_ui's.
// In the app's language where those libraries have it (115 languages), else
// English. The package's twin of the catalog's file, which gives English in
// any locale.
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoLocalizations,
        DefaultCupertinoLocalizations,
        GlobalCupertinoLocalizations;
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show
        DefaultMaterialLocalizations,
        GlobalMaterialLocalizations,
        MaterialLocalizations;

/// Material's words in the app's language, English where material_ui has
/// none for it.
const LocalizationsDelegate<MaterialLocalizations> frostedMaterialWords =
    _TranslatedOrEnglish<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    );

/// Cupertino's words in the app's language, English where cupertino_ui has
/// none for it.
const LocalizationsDelegate<CupertinoLocalizations> frostedCupertinoWords =
    _TranslatedOrEnglish<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
    );

/// [translated]'s words for the locales it knows, [english]'s for the rest.
class _TranslatedOrEnglish<T> extends LocalizationsDelegate<T> {
  const _TranslatedOrEnglish(this.translated, this.english);

  final LocalizationsDelegate<T> translated;
  final LocalizationsDelegate<T> english;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => translated.isSupported(locale)
      ? translated.load(locale)
      : english.load(const Locale('en'));

  @override
  bool shouldReload(_TranslatedOrEnglish<T> old) => false;
}
