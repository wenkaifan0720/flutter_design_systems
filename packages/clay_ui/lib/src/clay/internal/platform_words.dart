import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';

// The words of the Material and Cupertino libraries Clay is built on, which
// ClayTheme gives its parts (a text field's menu, its spoken hints) when the
// app gives none of those libraries' own. Here they are English in any
// locale.

/// Material's words for any locale: English.
///
/// Typed as any delegate, so Clay's API names no Material type.
const LocalizationsDelegate<Object?> clayMaterialWords = _MaterialWords();

class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_MaterialWords old) => false;
}

/// Cupertino's words for any locale: English. A text field's menu on iOS
/// reads them.
///
/// Typed as any delegate, so Clay's API names no Cupertino type.
const LocalizationsDelegate<Object?> clayCupertinoWords = _CupertinoWords();

class _CupertinoWords extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_CupertinoWords old) => false;
}
