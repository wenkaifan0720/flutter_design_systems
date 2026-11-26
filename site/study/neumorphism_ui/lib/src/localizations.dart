part of '../stint_neumorphism.dart';

class _PlasterWordsDelegate
    extends LocalizationsDelegate<NeumorphicLocalizations> {
  const _PlasterWordsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['ar', 'en', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<NeumorphicLocalizations> load(Locale locale) async {
    await initializeDateFormatting(locale.languageCode);
    return switch (locale.languageCode) {
      'ar' => const _ArabicPlasterWords(),
      'ja' => const _JapanesePlasterWords(),
      'de' => const _GermanPlasterWords(),
      _ => const NeumorphicLocalizationsEn(),
    };
  }

  @override
  bool shouldReload(_PlasterWordsDelegate old) => false;
}

class _ArabicPlasterWords extends NeumorphicLocalizationsEn {
  const _ArabicPlasterWords() : super(localeName: 'ar');
  static const words = StintWords(StintLanguage.ar);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
  @override
  String get close => 'إغلاق';
  @override
  String get back => 'رجوع';
  @override
  String get dismiss => 'إغلاق';
  @override
  String get loading => 'جارٍ التحميل';
  @override
  String get tryAgain => 'إعادة المحاولة';
  @override
  String get clearSearch => 'مسح البحث';
  @override
  String get choose => 'اختيار';
  @override
  String get cancel => 'إلغاء';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get previousMonth => 'الشهر السابق';
  @override
  String get nextMonth => 'الشهر التالي';
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
  String get delete => 'حذف';
  @override
  String get lookUp => 'بحث';
  @override
  String get searchWeb => 'البحث في الويب';
  @override
  String get share => 'مشاركة';
  @override
  String get scanText => 'مسح النص';
  @override
  String get search => 'بحث';
  @override
  String get today => 'اليوم';
  @override
  String get noResults => 'لا توجد نتائج';
  @override
  String get moreOptions => 'المزيد من الخيارات';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get menu => 'القائمة';
  @override
  String get nothingToShow => 'لا توجد بيانات';
  @override
  String get success => 'نجاح';
  @override
  String get information => 'معلومة';
  @override
  String get warning => 'تنبيه';
  @override
  String get error => 'خطأ';
  @override
  String get pullToRefresh => 'اسحب للتحديث';
  @override
  String get releaseToRefresh => 'أفلت للتحديث';
  @override
  String get refreshing => 'جارٍ التحديث';
  @override
  String get refreshed => 'تم التحديث';
}

class _JapanesePlasterWords extends NeumorphicLocalizationsEn {
  const _JapanesePlasterWords() : super(localeName: 'ja');
  static const words = StintWords(StintLanguage.ja);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String get close => '閉じる';
  @override
  String get back => '戻る';
  @override
  String get dismiss => '閉じる';
  @override
  String get loading => '読み込み中';
  @override
  String get tryAgain => '再試行';
  @override
  String get clearSearch => '検索をクリア';
  @override
  String get choose => '選択';
  @override
  String get cancel => 'キャンセル';
  @override
  String get chooseDate => '日付を選択';
  @override
  String get previousMonth => '前の月';
  @override
  String get nextMonth => '次の月';
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
  String get delete => '削除';
  @override
  String get lookUp => '調べる';
  @override
  String get searchWeb => 'ウェブを検索';
  @override
  String get share => '共有';
  @override
  String get scanText => 'テキストをスキャン';
  @override
  String get search => '検索';
  @override
  String get today => '今日';
  @override
  String get noResults => '結果はありません';
  @override
  String get moreOptions => 'その他のオプション';
  @override
  String get notifications => 'お知らせ';
  @override
  String get menu => 'メニュー';
  @override
  String get nothingToShow => '表示するデータはありません';
  @override
  String get success => '完了';
  @override
  String get information => 'お知らせ';
  @override
  String get warning => '注意';
  @override
  String get error => 'エラー';
  @override
  String get pullToRefresh => '引っ張って更新';
  @override
  String get releaseToRefresh => '指を離して更新';
  @override
  String get refreshing => '更新中';
  @override
  String get refreshed => '更新しました';
}

class _GermanPlasterWords extends NeumorphicLocalizationsEn {
  const _GermanPlasterWords() : super(localeName: 'de');
  static const words = StintWords(StintLanguage.de);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String get close => 'Schließen';
  @override
  String get back => 'Zurück';
  @override
  String get dismiss => 'Schließen';
  @override
  String get loading => 'Wird geladen';
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get clearSearch => 'Suche leeren';
  @override
  String get choose => 'Auswählen';
  @override
  String get cancel => 'Abbrechen';
  @override
  String get chooseDate => 'Datum auswählen';
  @override
  String get previousMonth => 'Vorheriger Monat';
  @override
  String get nextMonth => 'Nächster Monat';
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
  String get delete => 'Löschen';
  @override
  String get lookUp => 'Nachschlagen';
  @override
  String get searchWeb => 'Im Web suchen';
  @override
  String get share => 'Teilen';
  @override
  String get scanText => 'Text scannen';
  @override
  String get search => 'Suchen';
  @override
  String get today => 'Heute';
  @override
  String get noResults => 'Keine Ergebnisse';
  @override
  String get moreOptions => 'Weitere Optionen';
  @override
  String get notifications => 'Benachrichtigungen';
  @override
  String get menu => 'Menü';
  @override
  String get nothingToShow => 'Keine Daten';
  @override
  String get success => 'Erfolg';
  @override
  String get information => 'Hinweis';
  @override
  String get warning => 'Warnung';
  @override
  String get error => 'Fehler';
  @override
  String get pullToRefresh => 'Zum Aktualisieren ziehen';
  @override
  String get releaseToRefresh => 'Zum Aktualisieren loslassen';
  @override
  String get refreshing => 'Wird aktualisiert';
  @override
  String get refreshed => 'Aktualisiert';
}
