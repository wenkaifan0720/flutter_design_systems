// The Material and Cupertino words Comic's theme gives where the app gives none: the machinery under a field (the
// editable text, its selection on iOS, a raised route) asks for them, and an app on flutter_localizations gives
// Flutter's types, never material_ui's or cupertino_ui's. These load material_ui's and cupertino_ui's own translations
// for the app's locale, and English for a locale they don't know. (The package's twin of drip's English-only file.)
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

/// The Material localizations for the current locale, with English as the fallback.
const LocalizationsDelegate<MaterialLocalizations> comicMaterialWordsDelegate =
    _MaterialWords();

/// The Cupertino localizations for the current locale, with English as the fallback.
const LocalizationsDelegate<CupertinoLocalizations>
comicCupertinoWordsDelegate = _CupertinoWords();

class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? GlobalMaterialLocalizations.delegate.load(locale)
      : DefaultMaterialLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_MaterialWords old) => false;
}

class _CupertinoWords extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      GlobalCupertinoLocalizations.delegate.isSupported(locale)
      ? GlobalCupertinoLocalizations.delegate.load(locale)
      : DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_CupertinoWords old) => false;
}
