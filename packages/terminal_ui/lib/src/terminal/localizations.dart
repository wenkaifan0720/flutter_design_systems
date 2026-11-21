/// The words Terminal's own parts say, beyond ui_core's
/// [RawWidgetsLocalizations]: what a screen reader hears for a pager, a path, a
/// step or a group of people, and the few words its parts write themselves.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The words Terminal's parts say and write. Each counted one takes its
/// count whole, so a language words its own plural forms (one, few,
/// many, …) rather than having a word added to a number.
///
/// Terminal speaks English, Arabic and German ([supportedLocales]). [of]
/// reads the nearest [Localizations]' instance; when there is none, it
/// takes the words for the app's locale ([forLocale]), English for a
/// language Terminal does not speak, so nothing needs setting up. An app in
/// another language extends [DefaultTermLocalizations], overriding the
/// words it says, and adds a delegate for its subclass to its
/// `localizationsDelegates`, as it does for [RawWidgetsLocalizations].
///
/// ```dart
/// Text(TermLocalizations.of(context).avatarGroupLabel(const ['Ada Lovelace', 'Alan Turing']))
/// ```
abstract class TermLocalizations {
  /// Abstract const constructor, for subclasses.
  const TermLocalizations();

  /// The words for [context]: the nearest [Localizations]'
  /// [TermLocalizations], else Terminal's own for the app's locale.
  static TermLocalizations of(BuildContext context) =>
      Localizations.of<TermLocalizations>(context, TermLocalizations) ??
      forLocale(Localizations.maybeLocaleOf(context));

  /// Terminal's own words for [locale]: Arabic, German, else English.
  static TermLocalizations forLocale(Locale? locale) =>
      switch (locale?.languageCode) {
        'ar' => const _ArabicTermLocalizations(),
        'de' => const _GermanTermLocalizations(),
        _ => const DefaultTermLocalizations(),
      };

  /// The languages Terminal speaks.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ar'),
    Locale('de'),
  ];

  /// A delegate that loads Terminal's words for the app's locale
  /// ([forLocale]), for an app's `localizationsDelegates`.
  static const LocalizationsDelegate<TermLocalizations> delegate =
      _TermLocalizationsDelegate();

  /// What a screen reader hears for a `TermAvatarGroup` of [names]: how many
  /// people, then who ("2 people: Ada Lovelace, Alan Turing").
  String avatarGroupLabel(List<String> names);

  /// What a screen reader calls a `TermPagination` ("pages").
  String get paginationLabel;

  /// A pager's button to the page before ("previous page").
  String get previousPageLabel;

  /// A pager's button to the page after ("next page").
  String get nextPageLabel;

  /// One page of a pager or of `TermPageDots`, from 1 ("page 3").
  String pageLabel(int page);

  /// Where a pager or `TermPageDots` stands: [page] from 1 of [count]
  /// ("page 2 of 5").
  String pagePositionLabel(int page, int count);

  /// What a screen reader calls a `TermBreadcrumb` ("path").
  String get breadcrumbLabel;

  /// One of `TermSteps`: [step] from 1 of [count], its [label] and its
  /// [state], one of the four words below ("step 2 of 4, test, current").
  String stepLabel(int step, int count, String label, String state);

  /// A step still to come ("to come").
  String get stepUpcomingLabel;

  /// The step under way ("current").
  String get stepCurrentLabel;

  /// A step done ("done").
  String get stepDoneLabel;

  /// A step that failed ("failed").
  String get stepFailedLabel;

  /// A tag's remove button, for the tag [label] ("remove production").
  String removeLabel(String label);

  /// A `TermDataTable`'s box that chooses every row on the page
  /// ("select page").
  String get selectPageLabel;

  /// A `TermFileField`'s button that opens the files ("browse").
  String get browseLabel;

  /// The question a `TermConfirmDialog` asks before its `[y/N]`
  /// ("proceed?").
  String get confirmPrompt;

  /// What a screen reader hears for that question and its `[y/N]`
  /// ("proceed? yes or no, no by default").
  String get confirmPromptLabel;

  /// What a `TermConfirmDialog` asks to have typed, [word]
  /// ("type production to confirm"). [word] stands in it as given, so the
  /// dialog can set it in bold.
  String typedConfirmationLabel(String word);

  /// The field's label for that word when the words above say what to
  /// type ("confirm").
  String get typedConfirmationFieldLabel;

  /// The keys a `TermConfirmDialog` takes, shown under it
  /// ("y yes · n no · esc").
  String get confirmKeysHint;

  /// The key that cancels a dialog or a sheet, shown under it
  /// ("esc cancel").
  String get cancelKeyHint;

  /// A `TermPullToRefresh` pulled, not yet far enough ("pull to refresh").
  String get pullToRefreshLabel;

  /// A `TermPullToRefresh` pulled far enough ("let go to refresh").
  String get releaseToRefreshLabel;

  /// A `TermPullToRefresh` at work ("refreshing").
  String get refreshingLabel;

  /// A `TermPullToRefresh` done ("up to date").
  String get refreshedLabel;

  /// What a screen reader hears for a `TermSparkline`'s values: where they
  /// start and end, their least and their most, each written already
  /// ("from 3 to 9, least 3, most 9").
  String sparklineLabel(String first, String last, String least, String most);

  /// A `TermSparkline` with no values ("no values").
  String get noValuesLabel;

  /// The name of a terminal palette's colour [index], 0 to 15 ("black",
  /// "red", … "bright white"), as a `TermColorPicker` swatch says it.
  String paletteColorName(int index);

  /// A sheet's way out, a `TermActionSheet`'s last row ("cancel").
  String get cancelLabel;

  /// A `TermConfirmDialog`'s answer no ("no").
  String get noLabel;

  /// The key that closes a sheet, shown under it ("esc close").
  String get closeKeyHint;

  /// What a screen reader hears for a `TermSkeleton` ("loading").
  String get loadingLabel;

  /// A `TermFileField` with no file yet ("no file chosen").
  String get noFileLabel;

  /// A search's options on their way ("searching").
  String get searchingLabel;

  /// A search that failed ("search failed").
  String get searchFailedLabel;

  /// The button that searches again ("try again").
  String get retryLabel;

  /// A `TermCombobox` whose words match nothing ("no match").
  String get noMatchLabel;

  /// A `TermCommandPalette`'s title ("commands").
  String get commandsLabel;

  /// A `TermCommandPalette`'s empty field ("type a command").
  String get commandHint;

  /// A `TermCommandPalette` whose words match no command, before them
  /// ("no command matches").
  String get noCommandLabel;

  /// A password field's button that shows what is typed ("show").
  String get showLabel;

  /// A password field's button that hides it again ("hide").
  String get hideLabel;

  /// What a screen reader calls a `TermOtpField` ("one-time code").
  String get oneTimeCodeLabel;

  /// The keys a `TermCommandPalette` takes, shown under it
  /// ("↑↓ move · ⏎ run · esc close").
  String get paletteKeysHint;
}

/// The words in English, with no localizations package.
///
/// ```dart
/// const DefaultTermLocalizations().avatarGroupLabel(const ['Ada Lovelace'])
/// ```
class DefaultTermLocalizations implements TermLocalizations {
  /// English, the words [TermLocalizations.of] falls back to.
  const DefaultTermLocalizations();

  /// Makes the English words: what [delegate] loads for any locale.
  static Future<TermLocalizations> load(Locale locale) =>
      SynchronousFuture<TermLocalizations>(const DefaultTermLocalizations());

  /// A delegate that loads English for every locale, for an app's
  /// `localizationsDelegates`.
  static const LocalizationsDelegate<TermLocalizations> delegate =
      _DefaultTermLocalizationsDelegate();

  @override
  String avatarGroupLabel(List<String> names) {
    final count = names.length;
    return '${count == 1 ? '1 person' : '$count people'}: ${names.join(', ')}';
  }

  @override
  String get paginationLabel => 'pages';

  @override
  String get previousPageLabel => 'previous page';

  @override
  String get nextPageLabel => 'next page';

  @override
  String pageLabel(int page) => 'page $page';

  @override
  String pagePositionLabel(int page, int count) => 'page $page of $count';

  @override
  String get breadcrumbLabel => 'path';

  @override
  String stepLabel(int step, int count, String label, String state) =>
      'step $step of $count, $label, $state';

  @override
  String get stepUpcomingLabel => 'to come';

  @override
  String get stepCurrentLabel => 'current';

  @override
  String get stepDoneLabel => 'done';

  @override
  String get stepFailedLabel => 'failed';

  @override
  String removeLabel(String label) => 'remove $label';

  @override
  String get selectPageLabel => 'select page';

  @override
  String get browseLabel => 'browse';

  @override
  String get confirmPrompt => 'proceed?';

  @override
  String get confirmPromptLabel => 'proceed? yes or no, no by default';

  @override
  String typedConfirmationLabel(String word) => 'type $word to confirm';

  @override
  String get typedConfirmationFieldLabel => 'confirm';

  @override
  String get confirmKeysHint => 'y yes · n no · esc';

  @override
  String get cancelKeyHint => 'esc cancel';

  @override
  String get pullToRefreshLabel => 'pull to refresh';

  @override
  String get releaseToRefreshLabel => 'let go to refresh';

  @override
  String get refreshingLabel => 'refreshing';

  @override
  String get refreshedLabel => 'up to date';

  @override
  String sparklineLabel(String first, String last, String least, String most) =>
      'from $first to $last, least $least, most $most';

  @override
  String get noValuesLabel => 'no values';

  @override
  String paletteColorName(int index) => _palette(index, const [
    'black',
    'red',
    'green',
    'yellow',
    'blue',
    'magenta',
    'cyan',
    'white',
  ], (name) => 'bright $name');

  @override
  String get cancelLabel => 'cancel';

  @override
  String get noLabel => 'no';

  @override
  String get closeKeyHint => 'esc close';

  @override
  String get loadingLabel => 'loading';

  @override
  String get noFileLabel => 'no file chosen';

  @override
  String get searchingLabel => 'searching';

  @override
  String get searchFailedLabel => 'search failed';

  @override
  String get retryLabel => 'try again';

  @override
  String get noMatchLabel => 'no match';

  @override
  String get commandsLabel => 'commands';

  @override
  String get commandHint => 'type a command';

  @override
  String get noCommandLabel => 'no command matches';

  @override
  String get showLabel => 'show';

  @override
  String get hideLabel => 'hide';

  @override
  String get oneTimeCodeLabel => 'one-time code';

  @override
  String get paletteKeysHint => '↑↓ move · ⏎ run · esc close';
}

/// Colour [index] of the 16: one of [names] (0 to 7), or its bright form
/// (8 to 15).
String _palette(
  int index,
  List<String> names,
  String Function(String name) bright,
) {
  RangeError.checkValueInInterval(index, 0, 15, 'index');
  return index < 8 ? names[index] : bright(names[index - 8]);
}

/// The right-to-left mark.
const String _rtl = '\u200F';

/// [value] in Arabic-Indic digits ("١٢").
String _arabicDigits(int value) => String.fromCharCodes(
  '$value'.codeUnits.map((c) => c >= 0x30 && c <= 0x39 ? c - 0x30 + 0x660 : c),
);

/// The words in Arabic, its figures in Arabic-Indic digits as ui_core's
/// Arabic dates are. A line of keys opens with a right-to-left mark
/// ([_rtl]): it starts with a key's Latin letters, and a frame isolates its
/// words by their first strong letter, which would set it left to right.
class _ArabicTermLocalizations extends DefaultTermLocalizations {
  const _ArabicTermLocalizations();

  @override
  String avatarGroupLabel(List<String> names) {
    final n = names.length;
    final d = _arabicDigits(n);
    final hundred = n % 100;
    final count = switch (n) {
      0 => 'لا أحد',
      1 => 'شخص واحد',
      2 => 'شخصان',
      _ when hundred >= 3 && hundred <= 10 => '$d أشخاص',
      _ when hundred >= 11 && hundred <= 99 => '$d شخصًا',
      _ => '$d شخص',
    };
    return '$count: ${names.join('، ')}';
  }

  @override
  String get paginationLabel => 'الصفحات';

  @override
  String get previousPageLabel => 'الصفحة السابقة';

  @override
  String get nextPageLabel => 'الصفحة التالية';

  @override
  String pageLabel(int page) => 'الصفحة ${_arabicDigits(page)}';

  @override
  String pagePositionLabel(int page, int count) =>
      'الصفحة ${_arabicDigits(page)} من ${_arabicDigits(count)}';

  @override
  String get breadcrumbLabel => 'المسار';

  @override
  String stepLabel(int step, int count, String label, String state) =>
      'الخطوة ${_arabicDigits(step)} من ${_arabicDigits(count)}، $label، $state';

  @override
  String get stepUpcomingLabel => 'قادمة';

  @override
  String get stepCurrentLabel => 'الحالية';

  @override
  String get stepDoneLabel => 'مكتملة';

  @override
  String get stepFailedLabel => 'فشلت';

  @override
  String removeLabel(String label) => 'إزالة $label';

  @override
  String get selectPageLabel => 'تحديد الصفحة';

  @override
  String get browseLabel => 'استعراض';

  @override
  String get confirmPrompt => 'متابعة؟';

  @override
  String get confirmPromptLabel => 'متابعة؟ نعم أو لا، لا افتراضيًا';

  @override
  String typedConfirmationLabel(String word) => 'اكتب $word للتأكيد';

  @override
  String get typedConfirmationFieldLabel => 'تأكيد';

  @override
  String get confirmKeysHint => '${_rtl}y نعم · n لا · esc';

  @override
  String get cancelKeyHint => '${_rtl}esc إلغاء';

  @override
  String get pullToRefreshLabel => 'اسحب للتحديث';

  @override
  String get releaseToRefreshLabel => 'أفلِت للتحديث';

  @override
  String get refreshingLabel => 'جارٍ التحديث';

  @override
  String get refreshedLabel => 'محدَّث';

  @override
  String sparklineLabel(String first, String last, String least, String most) =>
      'من $first إلى $last، الأدنى $least، الأعلى $most';

  @override
  String get noValuesLabel => 'لا قيم';

  @override
  String paletteColorName(int index) => _palette(index, const [
    'أسود',
    'أحمر',
    'أخضر',
    'أصفر',
    'أزرق',
    'أرجواني',
    'سماوي',
    'أبيض',
  ], (name) => '$name فاتح');

  @override
  String get cancelLabel => 'إلغاء';

  @override
  String get noLabel => 'لا';

  @override
  String get closeKeyHint => '${_rtl}esc إغلاق';

  @override
  String get loadingLabel => 'جارٍ التحميل';

  @override
  String get noFileLabel => 'لم يُختر أي ملف';

  @override
  String get searchingLabel => 'جارٍ البحث';

  @override
  String get searchFailedLabel => 'تعذّر البحث';

  @override
  String get retryLabel => 'أعد المحاولة';

  @override
  String get noMatchLabel => 'لا تطابق';

  @override
  String get commandsLabel => 'الأوامر';

  @override
  String get commandHint => 'اكتب أمرًا';

  @override
  String get noCommandLabel => 'لا يطابقها أي أمر';

  @override
  String get showLabel => 'إظهار';

  @override
  String get hideLabel => 'إخفاء';

  @override
  String get oneTimeCodeLabel => 'رمز لمرة واحدة';

  @override
  String get paletteKeysHint => '$_rtl↑↓ تنقّل · ⏎ تشغيل · esc إغلاق';
}

/// The words in German.
class _GermanTermLocalizations extends DefaultTermLocalizations {
  const _GermanTermLocalizations();

  @override
  String avatarGroupLabel(List<String> names) {
    final n = names.length;
    return '${n == 1 ? '1 Person' : '$n Personen'}: ${names.join(', ')}';
  }

  @override
  String get paginationLabel => 'Seiten';

  @override
  String get previousPageLabel => 'vorherige Seite';

  @override
  String get nextPageLabel => 'nächste Seite';

  @override
  String pageLabel(int page) => 'Seite $page';

  @override
  String pagePositionLabel(int page, int count) => 'Seite $page von $count';

  @override
  String get breadcrumbLabel => 'Pfad';

  @override
  String stepLabel(int step, int count, String label, String state) =>
      'Schritt $step von $count, $label, $state';

  @override
  String get stepUpcomingLabel => 'ausstehend';

  @override
  String get stepCurrentLabel => 'aktuell';

  @override
  String get stepDoneLabel => 'erledigt';

  @override
  String get stepFailedLabel => 'fehlgeschlagen';

  @override
  String removeLabel(String label) => '$label entfernen';

  @override
  String get selectPageLabel => 'Seite auswählen';

  @override
  String get browseLabel => 'durchsuchen';

  @override
  String get confirmPrompt => 'fortfahren?';

  @override
  String get confirmPromptLabel =>
      'fortfahren? ja oder nein, standardmäßig nein';

  @override
  String typedConfirmationLabel(String word) =>
      '$word eingeben, um zu bestätigen';

  @override
  String get typedConfirmationFieldLabel => 'bestätigen';

  @override
  String get confirmKeysHint => 'y ja · n nein · esc';

  @override
  String get cancelKeyHint => 'esc abbrechen';

  @override
  String get pullToRefreshLabel => 'zum Aktualisieren ziehen';

  @override
  String get releaseToRefreshLabel => 'zum Aktualisieren loslassen';

  @override
  String get refreshingLabel => 'wird aktualisiert';

  @override
  String get refreshedLabel => 'aktuell';

  @override
  String sparklineLabel(String first, String last, String least, String most) =>
      'von $first bis $last, Minimum $least, Maximum $most';

  @override
  String get noValuesLabel => 'keine Werte';

  @override
  String paletteColorName(int index) => _palette(index, const [
    'Schwarz',
    'Rot',
    'Grün',
    'Gelb',
    'Blau',
    'Magenta',
    'Cyan',
    'Weiß',
  ], (name) => 'helles $name');

  @override
  String get cancelLabel => 'abbrechen';

  @override
  String get noLabel => 'nein';

  @override
  String get closeKeyHint => 'esc schließen';

  @override
  String get loadingLabel => 'wird geladen';

  @override
  String get noFileLabel => 'keine Datei ausgewählt';

  @override
  String get searchingLabel => 'wird gesucht';

  @override
  String get searchFailedLabel => 'Suche fehlgeschlagen';

  @override
  String get retryLabel => 'erneut versuchen';

  @override
  String get noMatchLabel => 'kein Treffer';

  @override
  String get commandsLabel => 'Befehle';

  @override
  String get commandHint => 'Befehl eingeben';

  @override
  String get noCommandLabel => 'kein passender Befehl';

  @override
  String get showLabel => 'anzeigen';

  @override
  String get hideLabel => 'verbergen';

  @override
  String get oneTimeCodeLabel => 'Einmalcode';

  @override
  String get paletteKeysHint => '↑↓ bewegen · ⏎ ausführen · esc schließen';
}

class _TermLocalizationsDelegate
    extends LocalizationsDelegate<TermLocalizations> {
  const _TermLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TermLocalizations> load(Locale locale) =>
      SynchronousFuture<TermLocalizations>(TermLocalizations.forLocale(locale));

  @override
  bool shouldReload(_TermLocalizationsDelegate old) => false;

  @override
  String toString() => 'TermLocalizations.delegate(en, ar, de)';
}

class _DefaultTermLocalizationsDelegate
    extends LocalizationsDelegate<TermLocalizations> {
  const _DefaultTermLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<TermLocalizations> load(Locale locale) =>
      DefaultTermLocalizations.load(locale);

  @override
  bool shouldReload(_DefaultTermLocalizationsDelegate old) => false;

  @override
  String toString() => 'DefaultTermLocalizations.delegate(en)';
}
