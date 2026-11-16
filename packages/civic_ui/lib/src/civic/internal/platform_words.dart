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

// The words of the Material and Cupertino libraries Civic is built on, which
// CivicTheme gives its parts (a text field's menu, a sheet's spoken name)
// when the app gives none of those libraries' own: an app on Flutter's
// MaterialApp with flutter_localizations gives Flutter's types, never these.
// material_ui's and cupertino_ui's own translations for the locales they
// know, English for the rest.

/// Material's words for any locale: material_ui's translation where it has
/// one, else English.
///
/// Typed as any delegate, so Civic's API names no Material type.
const LocalizationsDelegate<Object?> civicMaterialWords = _MaterialWords();

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

/// Cupertino's words for any locale: cupertino_ui's translation where it has
/// one, else English. A text field's menu on iOS reads them.
///
/// Typed as any delegate, so Civic's API names no Cupertino type.
const LocalizationsDelegate<Object?> civicCupertinoWords = _CupertinoWords();

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
