part of '../stint_retro_desktop.dart';

class _DesktopWordsDelegate
    extends LocalizationsDelegate<RetroDesktopLocalizations> {
  const _DesktopWordsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<RetroDesktopLocalizations> load(Locale locale) async {
    await initializeDateFormatting(locale.languageCode);
    return switch (locale.languageCode) {
      'ar' => const _ArabicDesktopWords(),
      'ja' => const _JapaneseDesktopWords(),
      'de' => const _GermanDesktopWords(),
      _ => const RetroDesktopLocalizationsEn(),
    };
  }

  @override
  bool shouldReload(_DesktopWordsDelegate old) => false;
}

class _ArabicDesktopWords extends RetroDesktopLocalizationsEn {
  const _ArabicDesktopWords() : super(localeName: 'ar');
  static const words = StintWords(StintLanguage.ar);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
  @override
  String get noData => words.noEntries;
  @override
  String get tryAgain => 'إعادة المحاولة';
  @override
  String get choose => 'اختيار';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get chooseTime => 'اختر وقتًا';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  String get period => 'الفترة';
  @override
  String get am => 'ص';
  @override
  String get pm => 'م';
  @override
  String get mainNavigation => 'التنقل الرئيسي';
  @override
  String get tabs => 'علامات التبويب';
  @override
  String get average => 'المتوسط';
  @override
  String get cut => 'قص';
  @override
  String get copy => 'نسخ';
  @override
  String get paste => 'لصق';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get lookUp => 'بحث';
  @override
  String get searchWeb => 'البحث في الويب';
  @override
  String get share => 'مشاركة';
  @override
  String get scanText => 'مسح النص';
  @override
  String get less => 'أقل';
  @override
  String get more => 'أكثر';
  @override
  String get earlierTabs => 'علامات التبويب السابقة';
  @override
  String get laterTabs => 'علامات التبويب التالية';
}

class _JapaneseDesktopWords extends RetroDesktopLocalizationsEn {
  const _JapaneseDesktopWords() : super(localeName: 'ja');
  static const words = StintWords(StintLanguage.ja);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String get noData => words.noEntries;
  @override
  String get tryAgain => '再試行';
  @override
  String get choose => '選択';
  @override
  String get chooseDate => '日付を選択';
  @override
  String get chooseTime => '時刻を選択';
  @override
  String get hour => '時';
  @override
  String get minute => '分';
  @override
  String get period => '午前/午後';
  @override
  String get am => '午前';
  @override
  String get pm => '午後';
  @override
  String get mainNavigation => 'メインナビゲーション';
  @override
  String get tabs => 'タブ';
  @override
  String get average => '平均';
  @override
  String get cut => '切り取り';
  @override
  String get copy => 'コピー';
  @override
  String get paste => '貼り付け';
  @override
  String get selectAll => 'すべて選択';
  @override
  String get lookUp => '調べる';
  @override
  String get searchWeb => 'ウェブを検索';
  @override
  String get share => '共有';
  @override
  String get scanText => 'テキストをスキャン';
  @override
  String get less => '少なく';
  @override
  String get more => '多く';
  @override
  String get earlierTabs => '前のタブ';
  @override
  String get laterTabs => '次のタブ';
}

class _GermanDesktopWords extends RetroDesktopLocalizationsEn {
  const _GermanDesktopWords() : super(localeName: 'de');
  static const words = StintWords(StintLanguage.de);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String get noData => words.noEntries;
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get choose => 'Auswählen';
  @override
  String get chooseDate => 'Datum auswählen';
  @override
  String get chooseTime => 'Uhrzeit auswählen';
  @override
  String get hour => 'Stunde';
  @override
  String get minute => 'Minute';
  @override
  String get period => 'Tageszeit';
  @override
  String get am => 'AM';
  @override
  String get pm => 'PM';
  @override
  String get mainNavigation => 'Hauptnavigation';
  @override
  String get tabs => 'Tabs';
  @override
  String get average => 'Durchschnitt';
  @override
  String get cut => 'Ausschneiden';
  @override
  String get copy => 'Kopieren';
  @override
  String get paste => 'Einsetzen';
  @override
  String get selectAll => 'Alle auswählen';
  @override
  String get lookUp => 'Nachschlagen';
  @override
  String get searchWeb => 'Im Web suchen';
  @override
  String get share => 'Teilen';
  @override
  String get scanText => 'Text scannen';
  @override
  String get less => 'Weniger';
  @override
  String get more => 'Mehr';
  @override
  String get earlierTabs => 'Vorherige Tabs';
  @override
  String get laterTabs => 'Nächste Tabs';
}
