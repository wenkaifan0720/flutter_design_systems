// The Material and Cupertino words MinimalTheme gives the machinery under the
// look (an editable, its text menu, a route) when the app gives none of the
// look's own: material_ui's and cupertino_ui's translations for the app's
// locale, English for a locale they lack. An app on Flutter's MaterialApp with
// flutter_localizations gives Flutter's types, never these, so the look loads
// them itself.
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

/// Material's words for the app's locale, for an app that gives none.
const LocalizationsDelegate<MaterialLocalizations> minimalMaterialWords =
    _Words<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
      DefaultMaterialLocalizations.load,
    );

/// Cupertino's words for the app's locale, for an app that gives none.
const LocalizationsDelegate<CupertinoLocalizations> minimalCupertinoWords =
    _Words<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
      DefaultCupertinoLocalizations.load,
    );

/// Words of type [T]: [_translated]'s for a locale it supports, English for
/// any other.
class _Words<T> extends LocalizationsDelegate<T> {
  const _Words(this._translated, this._english);

  final LocalizationsDelegate<T> _translated;
  final Future<T> Function(Locale locale) _english;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => _translated.isSupported(locale)
      ? _translated.load(locale)
      : _english(const Locale('en'));

  @override
  bool shouldReload(_Words<T> old) => false;
}
