part of '../stint_comic.dart';

class _StintControls extends LocalizationsDelegate<ComicLocalizations> {
  const _StintControls();
  @override
  bool isSupported(Locale locale) =>
      ['ar', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<ComicLocalizations> load(Locale locale) =>
      SynchronousFuture(switch (locale.languageCode) {
        'ja' => const _ComicJapanese(),
        'de' => const _ComicGerman(),
        _ => const _ComicArabic(),
      });
  @override
  bool shouldReload(_StintControls old) => false;
}

class _ComicArabic extends ComicLocalizationsEn {
  /// The words, in Arabic.
  const _ComicArabic();

  @override
  String get dismiss => 'إغلاق';
  @override
  String get tryAgain => 'حاول مجددًا';
  @override
  String get send => 'إرسال';
  @override
  String get less => 'أقل';
  @override
  String get more => 'أكثر';
  @override
  String get choose => 'اختر';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get chooseTime => 'اختر وقتًا';
  @override
  String get mainNavigation => 'الرئيسية';
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
  String get scanText => 'مسح النص ضوئيًا';
  @override
  String rating(int count, int total) => '$count من $total';
  @override
  String rate(int count, int total) => 'قيّم $count من $total';
  @override
  String page(int page, int total) => 'الصفحة $page من $total';
  @override
  String get breadcrumbs => 'أنت هنا';
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';
  @override
  String get dropFiles => 'أفلت الملفات هنا';
  @override
  String get chooseFiles => 'اختر ملفات';
  @override
  String removeFile(String name) => 'أزل $name';
  @override
  String get noData => 'لا شيء لعرضه بعد';
  @override
  String get stepDone => 'تم';
  @override
  String get stepNow => 'الآن';
  @override
  String get stepUpcoming => 'لاحقًا';
  @override
  String rangeFrom(String label) => '$label، من';
  @override
  String rangeTo(String label) => '$label، إلى';
  @override
  String get searchCommands => 'اكتب أمرًا';
  @override
  String get selectRow => 'حدد الصف';
  @override
  String get selectPage => 'حدد هذه الصفحة';
  @override
  String get resize => 'تغيير الحجم';
  @override
  String get notifications => 'الإشعارات';
  @override
  List<String> get months => const StintWords(StintLanguage.ar).monthNames;
  @override
  List<String> get weekdaysShort => const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];
}

class _ComicJapanese extends ComicLocalizationsEn {
  const _ComicJapanese();
  static const words = StintWords(StintLanguage.ja);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String rating(int count, int total) => '$total中$count';
  @override
  String rate(int count, int total) => '$total中$countで評価';
  @override
  String page(int page, int total) => '$page / $totalページ';
  @override
  String removeFile(String name) => '$nameを削除';
  @override
  String rangeFrom(String label) => '$label（開始）';
  @override
  String rangeTo(String label) => '$label（終了）';
  @override
  String get dismiss => '閉じる';
  @override
  String get tryAgain => '再試行';
  @override
  String get send => '送信';
  @override
  String get less => '少なく';
  @override
  String get more => '多く';
  @override
  String get choose => '選択';
  @override
  String get chooseDate => '日付を選択';
  @override
  String get chooseTime => '時刻を選択';
  @override
  String get mainNavigation => 'メイン';
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
  String get breadcrumbs => '現在地';
  @override
  String get previous => '前へ';
  @override
  String get next => '次へ';
  @override
  String get dropFiles => 'ここにファイルをドロップ';
  @override
  String get chooseFiles => 'ファイルを選択';
  @override
  String get noData => '表示するものはまだありません';
  @override
  String get stepDone => '完了';
  @override
  String get stepNow => '進行中';
  @override
  String get stepUpcoming => '予定';
  @override
  String get searchCommands => 'コマンドを入力';
  @override
  String get selectRow => '行を選択';
  @override
  String get selectPage => 'このページを選択';
  @override
  String get resize => 'サイズを変更';
  @override
  String get notifications => 'お知らせ';
}

class _ComicGerman extends ComicLocalizationsEn {
  const _ComicGerman();
  static const words = StintWords(StintLanguage.de);
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String rating(int count, int total) => '$count von $total';
  @override
  String rate(int count, int total) => 'Mit $count von $total bewerten';
  @override
  String page(int page, int total) => 'Seite $page von $total';
  @override
  String removeFile(String name) => '$name entfernen';
  @override
  String rangeFrom(String label) => '$label, von';
  @override
  String rangeTo(String label) => '$label, bis';
  @override
  String get dismiss => 'Schließen';
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get send => 'Senden';
  @override
  String get less => 'Weniger';
  @override
  String get more => 'Mehr';
  @override
  String get choose => 'Auswählen';
  @override
  String get chooseDate => 'Datum auswählen';
  @override
  String get chooseTime => 'Uhrzeit auswählen';
  @override
  String get mainNavigation => 'Hauptmenü';
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
  String get breadcrumbs => 'Du bist hier';
  @override
  String get previous => 'Zurück';
  @override
  String get next => 'Weiter';
  @override
  String get dropFiles => 'Dateien hier ablegen';
  @override
  String get chooseFiles => 'Dateien auswählen';
  @override
  String get noData => 'Noch nichts anzuzeigen';
  @override
  String get stepDone => 'Erledigt';
  @override
  String get stepNow => 'Jetzt';
  @override
  String get stepUpcoming => 'Demnächst';
  @override
  String get searchCommands => 'Befehl eingeben';
  @override
  String get selectRow => 'Zeile auswählen';
  @override
  String get selectPage => 'Diese Seite auswählen';
  @override
  String get resize => 'Größe ändern';
  @override
  String get notifications => 'Benachrichtigungen';
}
