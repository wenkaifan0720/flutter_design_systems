part of '../stint_frosted.dart';

class _WordsDelegate extends LocalizationsDelegate<FrostedLocalizations> {
  const _WordsDelegate();
  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'ja', 'de'].contains(locale.languageCode);
  @override
  Future<FrostedLocalizations> load(Locale locale) async =>
      switch (locale.languageCode) {
        'ar' => const _ArabicGlass(),
        'ja' => const _JapaneseGlass(),
        'de' => const _GermanGlass(),
        _ => const _EnglishGlass(),
      };
  @override
  bool shouldReload(_WordsDelegate old) => false;
}

class _EnglishGlass extends FrostedLocalizationsEn {
  const _EnglishGlass();
  @override
  String get searchCommands => const StintWords().commands;
}

class _ArabicGlass extends FrostedLocalizationsEn {
  const _ArabicGlass();
  static const w = StintWords(StintLanguage.ar);
  @override
  String get done => w.done;
  @override
  String get tryAgain => 'إعادة المحاولة';
  @override
  String get sections => 'الأقسام';
  @override
  String get profileAndSettings => 'الملف الشخصي والإعدادات';
  @override
  String get notifications => 'الإشعارات';
  @override
  String get filters => w.filters;
  @override
  String get month => 'الشهر';
  @override
  String get chooseMonth => 'اختيار الشهر';
  @override
  String get selectAll => 'تحديد الكل';
  @override
  String get select => 'اختيار';
  @override
  String get selectDate => 'اختيار التاريخ';
  @override
  String get selectTime => 'اختيار الوقت';
  @override
  String get previous => 'السابق';
  @override
  String get next => 'التالي';
  @override
  String get hour => 'الساعة';
  @override
  String get minute => 'الدقيقة';
  @override
  String get am => 'ص';
  @override
  String get pm => 'م';
  @override
  bool get alwaysUse24HourFormat => true;
  @override
  String monthName(int month) => w.monthNames[month - 1];
  @override
  String fullDate(DateTime date) =>
      '${w.weekday(date)}، ${w.shortDate(date)} ${w.number(date.year)}';
  @override
  String shortDate(DateTime date) => w.shortDate(date);
  @override
  String time(int hour, int minute) => w.clock(hour * 60 + minute);
  @override
  String lower(String what) => w.adjust(what, increase: false);
  @override
  String raise(String what) => w.adjust(what, increase: true);
  @override
  String get searchCommands => w.commands;
  @override
  String get noData => w.noEntries;
  @override
  String get move => w.move;
}

class _JapaneseGlass extends FrostedLocalizationsEn {
  const _JapaneseGlass();
  static const words = StintWords(StintLanguage.ja);
  @override
  String get done => words.done;
  @override
  String get filters => words.filters;
  @override
  bool get alwaysUse24HourFormat => true;
  @override
  String monthName(int month) => words.monthNames[month - 1];
  @override
  String fullDate(DateTime date) => words.dueDate(date);
  @override
  String shortDate(DateTime date) => words.shortDate(date);
  @override
  String time(int hour, int minute) => words.clock(hour * 60 + minute);
  @override
  String lower(String what) => words.adjust(what, increase: false);
  @override
  String raise(String what) => words.adjust(what, increase: true);
  @override
  String get searchCommands => words.commands;
  @override
  String get noData => words.noEntries;
  @override
  String get move => words.move;
  @override
  String get tryAgain => '再試行';
  @override
  String get sections => 'セクション';
  @override
  String get profileAndSettings => 'プロフィールと設定';
  @override
  String get notifications => 'お知らせ';
  @override
  String get month => '月';
  @override
  String get chooseMonth => '月を選択';
  @override
  String get selectAll => 'すべて選択';
  @override
  String get select => '選択';
  @override
  String get selectDate => '日付を選択';
  @override
  String get selectTime => '時刻を選択';
  @override
  String get previous => '前へ';
  @override
  String get next => '次へ';
  @override
  String get hour => '時';
  @override
  String get minute => '分';
  @override
  String get am => '午前';
  @override
  String get pm => '午後';
}

class _GermanGlass extends FrostedLocalizationsEn {
  const _GermanGlass();
  static const words = StintWords(StintLanguage.de);
  @override
  String get done => words.done;
  @override
  String get filters => words.filters;
  @override
  bool get alwaysUse24HourFormat => true;
  @override
  String monthName(int month) => words.monthNames[month - 1];
  @override
  String fullDate(DateTime date) => words.dueDate(date);
  @override
  String shortDate(DateTime date) => words.shortDate(date);
  @override
  String time(int hour, int minute) => words.clock(hour * 60 + minute);
  @override
  String lower(String what) => words.adjust(what, increase: false);
  @override
  String raise(String what) => words.adjust(what, increase: true);
  @override
  String get searchCommands => words.commands;
  @override
  String get noData => words.noEntries;
  @override
  String get move => words.move;
  @override
  String get tryAgain => 'Erneut versuchen';
  @override
  String get sections => 'Bereiche';
  @override
  String get profileAndSettings => 'Profil und Einstellungen';
  @override
  String get notifications => 'Benachrichtigungen';
  @override
  String get month => 'Monat';
  @override
  String get chooseMonth => 'Monat auswählen';
  @override
  String get selectAll => 'Alle auswählen';
  @override
  String get select => 'Auswählen';
  @override
  String get selectDate => 'Datum auswählen';
  @override
  String get selectTime => 'Uhrzeit auswählen';
  @override
  String get previous => 'Zurück';
  @override
  String get next => 'Weiter';
  @override
  String get hour => 'Stunde';
  @override
  String get minute => 'Minute';
  @override
  String get am => 'AM';
  @override
  String get pm => 'PM';
}
