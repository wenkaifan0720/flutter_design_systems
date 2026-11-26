part of '../stint_fluent2_design.dart';

class _StintControls extends LocalizationsDelegate<Fluent2Localizations> {
  const _StintControls();
  @override
  bool isSupported(Locale locale) =>
      ['ar', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<Fluent2Localizations> load(Locale locale) =>
      SynchronousFuture(switch (locale.languageCode) {
        'ja' => const _Fluent2Japanese(),
        'de' => const _Fluent2German(),
        _ => const _Fluent2Arabic(),
      });
  @override
  bool shouldReload(_StintControls old) => false;
}

class _Fluent2Arabic extends Fluent2LocalizationsEn {
  const _Fluent2Arabic();

  @override
  String backTo(String where) => 'العودة إلى $where';
  @override
  String get dismiss => 'تجاهل';
  @override
  String get tryAgain => 'حاول مجددًا';
  @override
  String get send => 'إرسال';
  @override
  String get attachFile => 'إرفاق ملف';
  @override
  String get emoji => 'رموز تعبيرية';
  @override
  String moreOptionsFor(String label) => 'خيارات إضافية لـ $label';
  @override
  String get filters => 'عوامل التصفية';
  @override
  String remove(String label) => 'إزالة $label';
  @override
  String get removeAction => 'إزالة';
  @override
  String get newItem => 'جديد';
  @override
  String get morePlaces => 'أماكن أخرى';
  @override
  String stepOf(int step, int steps) => 'الخطوة $step من $steps';
  @override
  String get notifications => 'الإشعارات';
  @override
  String accountSettings(String name) => '$name، الملف الشخصي والإعدادات';
  @override
  String get profileAndSettings => 'الملف الشخصي والإعدادات';
  @override
  String pageOf(int page, int count) => 'الصفحة $page من $count';
  @override
  String get chooseTime => 'اختر وقتًا';
  @override
  String get chooseDate => 'اختر تاريخًا';
  @override
  String get chooseDates => 'اختر تواريخ';
  @override
  String get dropFiles => 'اسحب الملفات إلى هنا';
  @override
  String get browseFiles => 'تصفّح الملفات';
  @override
  String get cut => 'قص';
  @override
  String get copy => 'نسخ';
  @override
  String get paste => 'لصق';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get share => 'مشاركة';
  @override
  String get other => 'أخرى';
  @override
  String get menu => 'القائمة';
  @override
  String get selectAnOption => 'اختر خيارًا';
  @override
  String get selectADate => 'اختر تاريخًا...';
  @override
  String get addPeople => 'أضف أشخاصًا';
  @override
  String get typeAMessage => 'اكتب رسالة';
  @override
  String get message => 'رسالة';
  @override
  String get create => 'إنشاء';
  @override
  String get expandNavigation => 'توسيع التنقل';
  @override
  String get collapseNavigation => 'طي التنقل';
  @override
  String get gotIt => 'فهمت';
  @override
  String notificationsUnread(int count) => 'الإشعارات، $count غير مقروءة';
  @override
  String get information => 'معلومات';
  @override
  String get success => 'نجاح';
  @override
  String get warning => 'تحذير';
  @override
  String get error => 'خطأ';
  @override
  List<String> get months => const [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  @override
  List<String> get monthsShort => months;
  @override
  List<String> get weekdaysShort => const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'];

  @override
  String get opensList => 'يفتح القائمة';
  @override
  String get opensMenu => 'يفتح قائمة إجراءات';
  @override
  String get opensCalendar => 'يفتح التقويم';
  @override
  String get opensSearch => 'يفتح البحث';
  @override
  String get increase => 'زيادة';
  @override
  String get decrease => 'تقليل';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  String get am => 'ص';
  @override
  String get pm => 'م';
  @override
  String get toolbar => 'شريط الأدوات';
  @override
  String get selectAllRows => 'تحديد كل الصفوف';
  @override
  String get lookUp => 'بحث';
  @override
  String get searchWeb => 'بحث في الويب';
  @override
  String get scanText => 'مسح النص';
  @override
  String fullDate(DateTime date) =>
      "${const StintWords(StintLanguage.ar).weekday(date)}، ${shortDate(date)}";
  @override
  String shortDate(DateTime date) => const StintWords(StintLanguage.ar).shortDate(date);
  @override
  String monthYear(DateTime date) =>
      "${months[date.month - 1]} ${const StintWords(StintLanguage.ar).number(date.year)}";
}

class _Fluent2Japanese extends Fluent2LocalizationsEn {
  const _Fluent2Japanese();
  static const words = StintWords(StintLanguage.ja);
  @override
  String backTo(String where) => '$whereに戻る';
  @override
  String moreOptionsFor(String label) => '$labelのその他のオプション';
  @override
  String remove(String label) => '$labelを削除';
  @override
  String stepOf(int step, int steps) => 'ステップ $step/$steps';
  @override
  String accountSettings(String name) => '$name、プロフィールと設定';
  @override
  String pageOf(int page, int count) => '$page / $countページ';
  @override
  String notificationsUnread(int count) => '通知、未読 $count 件';
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get monthsShort => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String fullDate(DateTime date) => '${words.dueDate(date)}（${words.weekday(date)}）';
  @override
  String shortDate(DateTime date) => words.shortDate(date);
  @override
  String monthYear(DateTime date) => '${date.year}年${months[date.month - 1]}';
  @override
  String get dismiss => '閉じる';
  @override
  String get tryAgain => '再試行';
  @override
  String get send => '送信';
  @override
  String get attachFile => 'ファイルを添付';
  @override
  String get emoji => '絵文字';
  @override
  String get filters => 'フィルター';
  @override
  String get removeAction => '削除';
  @override
  String get newItem => '新規';
  @override
  String get morePlaces => 'その他の場所';
  @override
  String get notifications => '通知';
  @override
  String get profileAndSettings => 'プロフィールと設定';
  @override
  String get chooseTime => '時刻を選択';
  @override
  String get chooseDate => '日付を選択';
  @override
  String get chooseDates => '日付を選択';
  @override
  String get dropFiles => 'ここにファイルをドラッグ';
  @override
  String get browseFiles => 'ファイルを参照';
  @override
  String get cut => '切り取り';
  @override
  String get copy => 'コピー';
  @override
  String get paste => '貼り付け';
  @override
  String get selectAll => 'すべて選択';
  @override
  String get share => '共有';
  @override
  String get other => 'その他';
  @override
  String get menu => 'メニュー';
  @override
  String get selectAnOption => 'オプションを選択';
  @override
  String get selectADate => '日付を選択...';
  @override
  String get addPeople => 'ユーザーを追加';
  @override
  String get typeAMessage => 'メッセージを入力';
  @override
  String get message => 'メッセージ';
  @override
  String get create => '作成';
  @override
  String get expandNavigation => 'ナビゲーションを展開';
  @override
  String get collapseNavigation => 'ナビゲーションを折りたたむ';
  @override
  String get gotIt => 'OK';
  @override
  String get information => '情報';
  @override
  String get success => '成功';
  @override
  String get warning => '警告';
  @override
  String get error => 'エラー';
  @override
  String get opensList => 'リストを開きます';
  @override
  String get opensMenu => '操作メニューを開きます';
  @override
  String get opensCalendar => 'カレンダーを開きます';
  @override
  String get opensSearch => '検索を開きます';
  @override
  String get increase => '増やす';
  @override
  String get decrease => '減らす';
  @override
  String get hour => '時';
  @override
  String get minute => '分';
  @override
  String get am => '午前';
  @override
  String get pm => '午後';
  @override
  String get toolbar => 'ツールバー';
  @override
  String get selectAllRows => 'すべての行を選択';
  @override
  String get lookUp => '調べる';
  @override
  String get searchWeb => 'ウェブを検索';
  @override
  String get scanText => 'テキストをスキャン';
}

class _Fluent2German extends Fluent2LocalizationsEn {
  const _Fluent2German();
  static const words = StintWords(StintLanguage.de);
  @override
  String backTo(String where) => 'Zurück zu $where';
  @override
  String moreOptionsFor(String label) => 'Weitere Optionen für $label';
  @override
  String remove(String label) => '$label entfernen';
  @override
  String stepOf(int step, int steps) => 'Schritt $step von $steps';
  @override
  String accountSettings(String name) => '$name, Profil und Einstellungen';
  @override
  String pageOf(int page, int count) => 'Seite $page von $count';
  @override
  String notificationsUnread(int count) => 'Benachrichtigungen, $count ungelesen';
  @override
  List<String> get months => words.monthNames;
  @override
  List<String> get monthsShort => words.monthNames;
  @override
  List<String> get weekdaysShort => words.weekdayNames;
  @override
  String fullDate(DateTime date) => '${words.weekday(date)}., ${words.dueDate(date)}';
  @override
  String shortDate(DateTime date) => words.shortDate(date);
  @override
  String monthYear(DateTime date) => '${months[date.month - 1]} ${date.year}';
  @override
  String get dismiss => 'Schließen';
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get send => 'Senden';
  @override
  String get attachFile => 'Datei anhängen';
  @override
  String get emoji => 'Emoji';
  @override
  String get filters => 'Filter';
  @override
  String get removeAction => 'Entfernen';
  @override
  String get newItem => 'Neu';
  @override
  String get morePlaces => 'Weitere Orte';
  @override
  String get notifications => 'Benachrichtigungen';
  @override
  String get profileAndSettings => 'Profil und Einstellungen';
  @override
  String get chooseTime => 'Uhrzeit auswählen';
  @override
  String get chooseDate => 'Datum auswählen';
  @override
  String get chooseDates => 'Daten auswählen';
  @override
  String get dropFiles => 'Dateien hierher ziehen';
  @override
  String get browseFiles => 'Dateien durchsuchen';
  @override
  String get cut => 'Ausschneiden';
  @override
  String get copy => 'Kopieren';
  @override
  String get paste => 'Einsetzen';
  @override
  String get selectAll => 'Alle auswählen';
  @override
  String get share => 'Teilen';
  @override
  String get other => 'Sonstiges';
  @override
  String get menu => 'Menü';
  @override
  String get selectAnOption => 'Option auswählen';
  @override
  String get selectADate => 'Datum auswählen …';
  @override
  String get addPeople => 'Personen hinzufügen';
  @override
  String get typeAMessage => 'Nachricht eingeben';
  @override
  String get message => 'Nachricht';
  @override
  String get create => 'Erstellen';
  @override
  String get expandNavigation => 'Navigation erweitern';
  @override
  String get collapseNavigation => 'Navigation reduzieren';
  @override
  String get gotIt => 'Verstanden';
  @override
  String get information => 'Information';
  @override
  String get success => 'Erfolg';
  @override
  String get warning => 'Warnung';
  @override
  String get error => 'Fehler';
  @override
  String get opensList => 'Öffnet die Liste';
  @override
  String get opensMenu => 'Öffnet ein Aktionsmenü';
  @override
  String get opensCalendar => 'Öffnet den Kalender';
  @override
  String get opensSearch => 'Öffnet die Suche';
  @override
  String get increase => 'Erhöhen';
  @override
  String get decrease => 'Verringern';
  @override
  String get hour => 'Stunde';
  @override
  String get minute => 'Minute';
  @override
  String get am => 'AM';
  @override
  String get pm => 'PM';
  @override
  String get toolbar => 'Symbolleiste';
  @override
  String get selectAllRows => 'Alle Zeilen auswählen';
  @override
  String get lookUp => 'Nachschlagen';
  @override
  String get searchWeb => 'Im Web suchen';
  @override
  String get scanText => 'Text scannen';
}
