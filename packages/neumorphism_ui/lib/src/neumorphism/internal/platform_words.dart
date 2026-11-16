// The words of the platform machinery under the look, for an app that gives none: Material's (the editable, a route)
// and, on iOS, Cupertino's (a field's menu, its magnifier). The look shows neither, but a part under it throws without
// them. They follow the app's language where material_ui and cupertino_ui translate it, and are English elsewhere.
//
// The package's twin of the catalog's file of the same name, which is English in any locale: the catalog's apps have no
// material_ui or cupertino_ui to translate from.
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoLocalizations,
        DefaultCupertinoLocalizations,
        GlobalCupertinoLocalizations;
import 'package:material_ui/material_ui.dart'
    show
        DefaultMaterialLocalizations,
        GlobalMaterialLocalizations,
        Locale,
        LocalizationsDelegate,
        MaterialLocalizations;

/// Material's words in the app's language where material_ui has it, English elsewhere.
const LocalizationsDelegate<MaterialLocalizations> neumorphicMaterialWords =
    _InLanguage<MaterialLocalizations>(
      GlobalMaterialLocalizations.delegate,
      DefaultMaterialLocalizations.delegate,
    );

/// Cupertino's words in the app's language where cupertino_ui has it, English elsewhere.
const LocalizationsDelegate<CupertinoLocalizations> neumorphicCupertinoWords =
    _InLanguage<CupertinoLocalizations>(
      GlobalCupertinoLocalizations.delegate,
      DefaultCupertinoLocalizations.delegate,
    );

/// [translated]'s words for a locale it supports, else [english]'s in English.
class _InLanguage<T> extends LocalizationsDelegate<T> {
  const _InLanguage(this.translated, this.english);

  final LocalizationsDelegate<T> translated;
  final LocalizationsDelegate<T> english;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<T> load(Locale locale) => translated.isSupported(locale)
      ? translated.load(locale)
      : english.load(const Locale('en'));

  @override
  bool shouldReload(_InLanguage<T> old) => false;
}
