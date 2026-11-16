// Material's and Cupertino's words for the machinery under the look (a
// field's editable and its selection, a calendar's dates, a sheet's route)
// when the app gives none of the library the look is built on: an app under
// a CupertinoApp or a WidgetsApp, or one whose flutter_localizations give
// another library's. The published package's copy: material_ui's and
// cupertino_ui's own translations where they have the app's language (115
// languages), English for the rest.
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

/// Material's words in the app's language where Material has it, else
/// English.
const LocalizationsDelegate<MaterialLocalizations> fluent2MaterialWords =
    _Translated<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    );

/// Cupertino's words in the app's language where Cupertino has it, else
/// English.
const LocalizationsDelegate<CupertinoLocalizations> fluent2CupertinoWords =
    _Translated<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
    );

/// [translated]'s words where it has the locale's language, else
/// [english]'s, in any locale.
class _Translated<T> extends LocalizationsDelegate<T> {
  const _Translated(this.translated, this.english);

  final LocalizationsDelegate<T> translated;
  final LocalizationsDelegate<T> english;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => translated.isSupported(locale)
      ? translated.load(locale)
      : english.load(const Locale('en'));

  @override
  bool shouldReload(_Translated<T> old) => false;

  @override
  Type get type => T;
}
