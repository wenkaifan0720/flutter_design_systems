/// The Material and Cupertino words the theme supplies when an app gives
/// none of its primitives' own: a field's context menu reads Material's,
/// or Cupertino's on iOS and macOS, and without them it threw.
///
/// The published package's: material_ui's and cupertino_ui's translations
/// for the locales they speak, English for the rest. (The look's source
/// keeps an English-only twin of this file.)
library;

import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoLocalizations,
        DefaultCupertinoLocalizations,
        GlobalCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart'
    show
        DefaultMaterialLocalizations,
        GlobalMaterialLocalizations,
        MaterialLocalizations;

/// Material's words for any locale: the app's language where material_ui
/// speaks it, English elsewhere.
const LocalizationsDelegate<MaterialLocalizations> expressiveMaterialWords =
    _MaterialWords();

/// Cupertino's words for any locale: the app's language where cupertino_ui
/// speaks it, English elsewhere.
const LocalizationsDelegate<CupertinoLocalizations> expressiveCupertinoWords =
    _CupertinoWords();

class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? GlobalMaterialLocalizations.delegate.load(locale)
      : SynchronousFuture(const DefaultMaterialLocalizations());

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
      : SynchronousFuture(const DefaultCupertinoLocalizations());

  @override
  bool shouldReload(_CupertinoWords old) => false;
}
