// The published package's twin of lib/src/retro_desktop/internal/platform_words.dart (in the module,
// lib/design_system/platinum/internal/platform_words.dart): the Material and Cupertino
// words the theme gives the parts' machinery (a text field's editable, its selection handles, a route) when the app
// supplies none of material_ui's or cupertino_ui's own. An app's flutter_localizations gives package:flutter's types,
// never these, so the look loads material_ui's and cupertino_ui's translations itself, in the app's language where
// they have it, and English elsewhere: a missing set never throws.
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoLocalizations,
        DefaultCupertinoLocalizations,
        GlobalCupertinoLocalizations;
import 'package:material_ui/material_ui.dart';

/// Material's words for the parts' machinery: material_ui's translation in the app's language, else English.
const LocalizationsDelegate<MaterialLocalizations> retroDesktopMaterialWords =
    _MaterialWords();

/// Cupertino's words for the parts' machinery: cupertino_ui's translation in the app's language, else English.
const LocalizationsDelegate<CupertinoLocalizations> retroDesktopCupertinoWords =
    _CupertinoWords();

class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      GlobalMaterialLocalizations.delegate.isSupported(locale)
      ? GlobalMaterialLocalizations.delegate.load(locale)
      : DefaultMaterialLocalizations.load(locale);
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
      : DefaultCupertinoLocalizations.load(locale);
  @override
  bool shouldReload(_CupertinoWords old) => false;
}
