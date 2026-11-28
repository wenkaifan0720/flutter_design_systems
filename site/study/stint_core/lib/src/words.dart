import 'dart:ui' show Locale;

import 'models.dart';

/// The languages Stint speaks. Its own words, the seed content, dates,
/// durations and digits follow the language; Arabic reads right to left.
enum StintLanguage {
  en('English'),
  ar('العربية'),
  ja('日本語'),
  de('Deutsch');

  const StintLanguage(this.nativeName);

  /// The language's name in its own words, as a language picker lists it.
  final String nativeName;

  /// Whether the language reads right to left.
  bool get rtl => this == ar;

  /// The locale an app passes to its 'locale'.
  Locale get locale => Locale(name);

  /// Every language's locale, for an app's 'supportedLocales'.
  static const locales = [
    Locale('en'),
    Locale('ar'),
    Locale('ja'),
    Locale('de'),
  ];

  /// The language whose code is [code] (en, ar, ja, de), else English.
  static StintLanguage forCode(String? code) =>
      values.where((l) => l.name == code).firstOrNull ?? en;
}

/// Application copy, fixtures and display formats follow the same language.
class StintWords {
  const StintWords([this.language = StintLanguage.en]);
  final StintLanguage language;

  /// Whether the words are Arabic: right to left, with Arabic-Indic digits.
  bool get arabic => language == StintLanguage.ar;
  static const _arabicDigits = '٠١٢٣٤٥٦٧٨٩';

  /// The same word in English, Arabic, Japanese and German.
  String _w(String en, String ar, String ja, String de) => switch (language) {
    StintLanguage.en => en,
    StintLanguage.ar => ar,
    StintLanguage.ja => ja,
    StintLanguage.de => de,
  };

  String text(TeamText value) => value.inLanguage(language);
  String get today => _w('Today', 'اليوم', '今日', 'Heute');
  String get tasks => _w('Tasks', 'المهام', 'タスク', 'Aufgaben');

  /// The timesheet place. German names the tracking, as Japanese names the
  /// work time: 'Zeit' alone reads as time in general.
  String get time => _w('Time', 'الوقت', '作業時間', 'Zeiterfassung');

  /// [time] for a navigation slot too narrow for German's 'Zeiterfassung'.
  String get timeShort => _w('Time', 'الوقت', '作業時間', 'Stunden');
  String get settings => _w('Settings', 'الإعدادات', '設定', 'Einstellungen');
  String get teamName => _w(
    'Fieldwork Studio',
    'استوديو فيلدورك',
    'フィールドワーク・スタジオ',
    'Fieldwork Studio',
  );
  String get greeting => _w(
    'Good morning, Maya',
    'صباح الخير يا مايا',
    'おはようございます、マヤさん',
    'Guten Morgen, Maya',
  );
  String get openTasks =>
      _w('Open tasks', 'المهام المفتوحة', '未完了のタスク', 'Offene Aufgaben');
  String get hoursThisWeek => _w(
    'Hours this week',
    'ساعات هذا الأسبوع',
    '今週の作業時間',
    'Stunden diese Woche',
  );
  String get upNext => _w('Up next', 'المهام القادمة', '次のタスク', 'Als Nächstes');
  String get runningTimer =>
      _w('Running timer', 'المؤقّت يعمل', 'タイマー計測中', 'Timer läuft');
  String get stoppedTimer =>
      _w('Timer stopped', 'المؤقّت متوقّف', 'タイマー停止中', 'Timer gestoppt');
  String get startTimer =>
      _w('Start a timer', 'بدء مؤقّت', 'タイマーを開始', 'Timer starten');
  String get stopTimer => _w('Stop', 'إيقاف', '停止', 'Stoppen');
  String get switchTask =>
      _w('Switch task', 'تبديل المهمة', 'タスクを切り替え', 'Aufgabe wechseln');
  String get noTimerTasks => _w(
    'No open tasks to track.',
    'لا توجد مهام مفتوحة للتوقيت.',
    '計測できる未完了のタスクはありません。',
    'Keine offenen Aufgaben zum Erfassen.',
  );
  String get todaysPlan =>
      _w('Today’s plan', 'خطة اليوم', '今日の予定', 'Plan für heute');
  String get noTasksToday => _w(
    'No tasks due today.',
    'لا توجد مهام مستحقة اليوم.',
    '今日が期限のタスクはありません。',
    'Heute ist nichts fällig.',
  );
  String get timeBlocks =>
      _w('Time blocks', 'فترات العمل', '作業ブロック', 'Zeitblöcke');
  String get noBlocks => _w(
    'No time logged today yet.',
    'لم يُسجَّل وقت اليوم بعد.',
    '今日の記録はまだありません。',
    'Heute noch keine Zeit erfasst.',
  );
  String get laterThisWeek => _w(
    'Later this week',
    'لاحقًا هذا الأسبوع',
    '今週の残り',
    'Später diese Woche',
  );
  String get teamActivity =>
      _w('Team activity', 'نشاط الفريق', 'チームのアクティビティ', 'Teamaktivität');
  String get recentActivity => _w(
    'Recent activity',
    'آخر المستجدات',
    '最近のアクティビティ',
    'Letzte Aktivitäten',
  );
  String get noActivity => _w(
    'No activity yet.',
    'لا يوجد نشاط بعد.',
    'アクティビティはまだありません。',
    'Noch keine Aktivität.',
  );
  String get notTracking => _w(
    'Not tracking a task',
    'لا توجد مهمة قيد التوقيت',
    '計測中のタスクはありません',
    'Keine Aufgabe in Erfassung',
  );
  String since(DateTime start) {
    final at = clock(minuteOfDay(start));
    return _w('Since $at', 'منذ $at', '$atから', 'Seit $at');
  }

  String timeRange(TimeEntry entry) =>
      '\u2066${clock(entry.start)}–${clock(entry.end)}\u2069';

  /// The separator between the parts of a meta line. In Arabic a middle dot
  /// beside Arabic-Indic digits reads as a zero (٠), so the Arabic comma
  /// stands there instead.
  String get dot => arabic ? '\u060c ' : ' · ';

  // A day with nothing due says so, not "0 of 0 done".
  String progress(int done, int all) => all == 0
      ? _w(
          'Nothing due today',
          'لا شيء مستحق اليوم',
          '今日が期限のタスクはありません',
          'Heute nichts fällig',
        )
      : _w(
          '$done of $all done',
          '${number(done)} من ${number(all)} مكتملة',
          '$all件中$done件完了',
          '$done von $all erledigt',
        );
  String elapsed(Duration value) {
    final seconds = value.isNegative ? 0 : value.inSeconds;
    final zero = number(0);
    return [
      seconds ~/ 3600,
      seconds ~/ 60 % 60,
      seconds % 60,
    ].map((n) => number(n).padLeft(2, zero)).join(':');
  }

  String elapsedLabel(String reading) => _w(
    'Elapsed time, $reading',
    'الوقت المنقضي، $reading',
    '経過時間、$reading',
    'Verstrichene Zeit, $reading',
  );

  String timeAgo(DateTime at, DateTime now) {
    final minutes = now.difference(at).inMinutes;
    if (minutes < 1) return _w('Just now', 'الآن', 'たった今', 'Gerade eben');
    if (minutes >= 1440) return relativeDay(-(minutes ~/ 1440));
    final hours = minutes >= 60;
    final n = hours ? minutes ~/ 60 : minutes;
    switch (language) {
      case StintLanguage.en:
        return '${number(n)}${hours ? 'h' : 'm'} ago';
      case StintLanguage.ja:
        return '$n${hours ? '時間' : '分'}前';
      case StintLanguage.de:
        return 'vor $n ${hours ? 'Std.' : 'Min.'}';
      case StintLanguage.ar:
        if (n == 1) return hours ? 'قبل ساعة' : 'قبل دقيقة';
        if (n == 2) return hours ? 'قبل ساعتين' : 'قبل دقيقتين';
        final unit = hours
            ? (n <= 10 ? 'ساعات' : 'ساعة')
            : (n <= 10 ? 'دقائق' : 'دقيقة');
        return 'قبل ${number(n)} $unit';
    }
  }

  String eventAction(StudioEvent event, String name) {
    final female = const {'maya', 'noor', 'inez'}.contains(event.person);
    final spent = duration(event.minutes);
    final verb = switch (language) {
      StintLanguage.en => switch (event.kind) {
        ActivityKind.finished => 'finished',
        ActivityKind.started => 'started',
        ActivityKind.commented => 'commented',
        ActivityKind.logged => 'logged $spent',
      },
      StintLanguage.ar => switch (event.kind) {
        ActivityKind.finished => female ? 'أنهت' : 'أنهى',
        ActivityKind.started => female ? 'بدأت' : 'بدأ',
        ActivityKind.commented => female ? 'علّقت' : 'علّق',
        ActivityKind.logged => '${female ? 'سجّلت' : 'سجّل'} $spent',
      },
      StintLanguage.ja => switch (event.kind) {
        ActivityKind.finished => 'さんが完了しました',
        ActivityKind.started => 'さんが開始しました',
        ActivityKind.commented => 'さんがコメントしました',
        ActivityKind.logged => 'さんが$spentを記録しました',
      },
      StintLanguage.de => switch (event.kind) {
        ActivityKind.finished => 'hat eine Aufgabe erledigt',
        ActivityKind.started => 'hat eine Aufgabe begonnen',
        ActivityKind.commented => 'hat kommentiert',
        ActivityKind.logged => 'hat $spent erfasst',
      },
    };
    return language == StintLanguage.ja ? '$name$verb' : '$name $verb';
  }

  String get viewTasks => _w(
    'View all tasks',
    'عرض كل المهام',
    'すべてのタスクを表示',
    'Alle Aufgaben anzeigen',
  );
  String get byProject =>
      _w('By project', 'حسب المشروع', 'プロジェクト別', 'Nach Projekt');
  String get seeTime => _w(
    'View timesheet',
    'عرض سجل الوقت',
    'タイムシートを表示',
    'Stundenzettel anzeigen',
  );
  String get search =>
      _w('Search tasks', 'البحث في المهام', 'タスクを検索', 'Aufgaben durchsuchen');
  String get filters => _w('Filters', 'تصفية', '絞り込み', 'Filter');
  String get status => _w('Status', 'الحالة', 'ステータス', 'Status');
  String get all => _w('All', 'الكل', 'すべて', 'Alle');
  String get open => _w('Open', 'مفتوحة', '未完了', 'Offen');
  String get done => _w('Done', 'مكتملة', '完了', 'Erledigt');
  String get project => _w('Project', 'المشروع', 'プロジェクト', 'Projekt');
  String get assignee => _w('Assignee', 'المكلّف', '担当者', 'Zuständig');
  String get sort => _w('Sort by', 'ترتيب حسب', '並べ替え', 'Sortieren nach');
  String get dateError => _w(
    'Enter the day, month and year.',
    'أكمل اليوم والشهر والسنة.',
    '年・月・日を入力してください。',
    'Gib Tag, Monat und Jahr ein.',
  );
  String get calendar =>
      _w('Open calendar', 'فتح التقويم', 'カレンダーを開く', 'Kalender öffnen');
  String get due => _w('Due date', 'تاريخ الاستحقاق', '期限', 'Fälligkeitsdatum');
  String get priority => _w('Priority', 'الأولوية', '優先度', 'Priorität');
  String get title => _w('Title', 'العنوان', 'タイトル', 'Titel');
  String get low => _w('Low', 'منخفضة', '低', 'Niedrig');
  String get normal => _w('Normal', 'عادية', '中', 'Normal');
  String get high => _w('High', 'عالية', '高', 'Hoch');
  String get reset =>
      _w('Clear filters', 'مسح التصفية', '絞り込みを解除', 'Filter zurücksetzen');
  String get apply => _w('Apply', 'تطبيق', '適用', 'Anwenden');
  String get select =>
      _w('Select tasks', 'تحديد المهام', 'タスクを選択', 'Aufgaben auswählen');
  String get stopSelecting =>
      _w('Cancel selection', 'إلغاء التحديد', '選択をやめる', 'Auswahl abbrechen');
  String get selectAll => _w(
    'Select all results',
    'تحديد كل النتائج',
    '結果をすべて選択',
    'Alle Ergebnisse auswählen',
  );
  String get actions =>
      _w('Task actions', 'إجراءات المهمة', 'タスクの操作', 'Aufgabenaktionen');
  String get complete =>
      _w('Mark done', 'تحديد كمكتملة', '完了にする', 'Als erledigt markieren');
  String get reopen => _w('Reopen', 'إعادة فتح', '未完了に戻す', 'Wieder öffnen');
  String get move => _w(
    'Move to project',
    'نقل إلى مشروع',
    '別のプロジェクトへ移動',
    'In Projekt verschieben',
  );
  String get delete => _w('Delete', 'حذف', '削除', 'Löschen');
  String get undo => _w('Undo', 'تراجع', '元に戻す', 'Rückgängig');
  String get deleted =>
      _w('Tasks deleted', 'حُذفت المهام', 'タスクを削除しました', 'Aufgaben gelöscht');
  String get refresh => _w('Refresh', 'تحديث', '更新', 'Aktualisieren');
  String get loading => _w(
    'Loading workspace',
    'جارٍ تحميل مساحة العمل',
    'ワークスペースを読み込み中',
    'Arbeitsbereich wird geladen',
  );
  String get loadError => _w(
    'Couldn’t load the workspace',
    'تعذر تحميل مساحة العمل',
    'ワークスペースを読み込めませんでした',
    'Arbeitsbereich konnte nicht geladen werden',
  );
  String get retry => _w('Retry', 'إعادة المحاولة', '再試行', 'Erneut versuchen');
  String get retryHelp => _w(
    'Try again to load the team’s latest work.',
    'حاول مجددًا لعرض أحدث أعمال الفريق.',
    'もう一度読み込んで、チームの最新の作業を表示します。',
    'Versuche es erneut, um die neuesten Arbeiten des Teams zu laden.',
  );
  String get noTasks =>
      _w('No tasks here', 'لا توجد مهام هنا', 'タスクはありません', 'Keine Aufgaben');
  String get allClear => _w(
    'There are no open tasks coming up.',
    'لا توجد مهام مفتوحة قادمة.',
    '予定されている未完了のタスクはありません。',
    'Es stehen keine offenen Aufgaben an.',
  );
  String get noMatches => _w(
    'No matching tasks',
    'لا توجد مهام مطابقة',
    '一致するタスクはありません',
    'Keine passenden Aufgaben',
  );
  String get searchHelp => _w(
    'Try a different search or clear your filters.',
    'غيّر عبارة البحث أو امسح عوامل التصفية.',
    '検索語を変えるか、絞り込みを解除してください。',
    'Versuche einen anderen Suchbegriff oder setze die Filter zurück.',
  );
  String get chooseTask =>
      _w('Choose a task', 'اختر مهمة', 'タスクを選んでください', 'Wähle eine Aufgabe');
  String get chooseTaskHelp => _w(
    'Open a row to see the details and edit it here.',
    'افتح صفًا لعرض تفاصيل المهمة وتعديلها هنا.',
    '行を開くと、ここに詳細が表示され、編集できます。',
    'Öffne eine Zeile, um die Details hier zu sehen und zu bearbeiten.',
  );
  String get taskDetail =>
      _w('Task details', 'تفاصيل المهمة', 'タスクの詳細', 'Aufgabendetails');
  String get notes => _w('Notes', 'الملاحظات', 'メモ', 'Notizen');
  String get estimate => _w(
    'Estimate (minutes)',
    'التقدير بالدقائق',
    '見積もり（分）',
    'Schätzung (Minuten)',
  );
  String get labels => _w('Labels', 'الوسوم', 'ラベル', 'Labels');
  String get planning => _w('Planning', 'تخطيط', '企画', 'Planung');
  String get review => _w('Review', 'مراجعة', 'レビュー', 'Prüfung');
  String get fieldwork =>
      _w('Fieldwork', 'عمل ميداني', 'フィールドワーク', 'Feldarbeit');
  String get reminder => _w('Reminder', 'تذكير', 'リマインダー', 'Erinnerung');
  String get reminderTime =>
      _w('Reminder time', 'وقت التذكير', 'リマインダーの時刻', 'Erinnerungszeit');
  String get save =>
      _w('Save changes', 'حفظ التغييرات', '変更を保存', 'Änderungen speichern');
  String get saved => _w(
    'Changes saved',
    'حُفظت التغييرات',
    '変更を保存しました',
    'Änderungen gespeichert',
  );
  String get dirty => _w(
    'Unsaved changes',
    'تغييرات غير محفوظة',
    '未保存の変更',
    'Ungespeicherte Änderungen',
  );
  String get leaveMessage => _w(
    'Save your changes before leaving this task?',
    'هل تريد حفظ التغييرات قبل مغادرة المهمة؟',
    'このタスクを離れる前に変更を保存しますか？',
    'Änderungen speichern, bevor du diese Aufgabe verlässt?',
  );
  String get discard => _w('Discard', 'تجاهل', '破棄', 'Verwerfen');
  // A dialog of two actions asks only whether to throw the edits away:
  // Save stays on the form.
  String get keepEditing =>
      _w('Keep editing', 'متابعة التعديل', '編集を続ける', 'Weiter bearbeiten');
  String get discardMessage => _w(
    'Leave this task and discard your changes?',
    'هل تريد مغادرة المهمة وتجاهل تغييراتك؟',
    '変更を破棄して、このタスクを離れますか？',
    'Diese Aufgabe verlassen und die Änderungen verwerfen?',
  );
  String get cancel => _w('Cancel', 'إلغاء', 'キャンセル', 'Abbrechen');
  String get titleError => _w(
    'Enter a title for this task.',
    'أدخل عنوانًا لهذه المهمة.',
    'タスクのタイトルを入力してください。',
    'Gib einen Titel für diese Aufgabe ein.',
  );
  String get estimateError => _w(
    'Choose an estimate between 5 and 480 minutes.',
    'اختر تقديرًا بين ٥ و٤٨٠ دقيقة.',
    '見積もりは5〜480分の範囲で入力してください。',
    'Wähle eine Schätzung zwischen 5 und 480 Minuten.',
  );
  String get assigneeError => _w(
    'Choose a teammate from the list.',
    'اختر زميلًا من القائمة.',
    'リストからメンバーを選んでください。',
    'Wähle ein Teammitglied aus der Liste.',
  );
  String get projectError => _w(
    'Choose a project.',
    'اختر مشروعًا.',
    'プロジェクトを選んでください。',
    'Wähle ein Projekt.',
  );
  String get week => _w('Week', 'الأسبوع', '週', 'Woche');
  String get weekTotal =>
      _w('Week total', 'إجمالي الأسبوع', '週の合計', 'Wochensumme');
  String get logged =>
      _w('Hours logged', 'الساعات المسجّلة', '記録した時間', 'Erfasste Stunden');
  String get entries => _w('Time entries', 'سجل الوقت', '作業記録', 'Zeiteinträge');
  String get addEntry =>
      _w('Add entry', 'إضافة تسجيل', '記録を追加', 'Eintrag hinzufügen');
  String get date => _w('Date', 'التاريخ', '日付', 'Datum');
  String get start => _w('Start time', 'وقت البدء', '開始時刻', 'Startzeit');
  String get end => _w('End time', 'وقت الانتهاء', '終了時刻', 'Endzeit');
  String get note => _w('Work note', 'ملاحظة العمل', '作業メモ', 'Arbeitsnotiz');
  String get noteHint => _w(
    'What did you work on?',
    'على ماذا عملت؟',
    'どんな作業をしましたか？',
    'Woran hast du gearbeitet?',
  );
  String get entryError => _w(
    'End time must be later than start time.',
    'يجب أن يكون وقت الانتهاء بعد وقت البدء.',
    '終了時刻は開始時刻より後にしてください。',
    'Die Endzeit muss nach der Startzeit liegen.',
  );
  String get noteError => _w(
    'Describe the work you logged.',
    'اكتب وصفًا للعمل المسجّل.',
    '記録した作業の内容を入力してください。',
    'Beschreibe die erfasste Arbeit.',
  );
  String get entrySaved =>
      _w('Entry added', 'أُضيف التسجيل', '記録を追加しました', 'Eintrag hinzugefügt');
  String get noEntries => _w(
    'No time logged this week',
    'لا توجد ساعات مسجّلة هذا الأسبوع',
    '今週の記録はありません',
    'Diese Woche keine Zeit erfasst',
  );
  String get previousWeek =>
      _w('Previous week', 'الأسبوع السابق', '前の週', 'Vorherige Woche');
  String get nextWeek =>
      _w('Next week', 'الأسبوع التالي', '次の週', 'Nächste Woche');
  String get appearance => _w('Theme', 'المظهر', 'テーマ', 'Erscheinungsbild');
  String get system => _w('System', 'النظام', 'システム', 'System');
  String get day => _w('Day', 'نهاري', 'ライト', 'Hell');
  String get night => _w('Night', 'ليلي', 'ダーク', 'Dunkel');
  String get textSize => _w('Text size', 'حجم النص', '文字サイズ', 'Textgröße');

  /// A text size as a percentage, in the language's digits and sign.
  String percent(double scale) {
    final n = number((scale * 100).round());
    return _w('$n%', '$n٪', '$n%', '$n\u00a0%');
  }

  /// The language setting's label. [language] is the language itself.
  String get languageLabel => _w('Language', 'اللغة', '言語', 'Sprache');
  String get density => _w('Density', 'الكثافة', '表示密度', 'Anzeigedichte');
  String get standard => _w('Standard', 'قياسية', '標準', 'Standard');
  String get compact => _w('Compact', 'مدمجة', 'コンパクト', 'Kompakt');
  String get about => _w('About Stint', 'حول ستنت', 'Stintについて', 'Über Stint');
  String get aboutDetail => _w(
    'A shared task list and timesheet for Fieldwork Studio.',
    'قائمة مهام وسجل وقت مشترك لفريق استوديو فيلدورك.',
    'フィールドワーク・スタジオのチームで共有するタスクリストとタイムシート。',
    'Gemeinsame Aufgabenliste und Stundenzettel für das Fieldwork Studio.',
  );
  String get signOut => _w('Sign out', 'تسجيل الخروج', 'ログアウト', 'Abmelden');
  String get signOutMessage => _w(
    'Sign out of Fieldwork Studio?',
    'هل تريد تسجيل الخروج من استوديو فيلدورك؟',
    'フィールドワーク・スタジオからログアウトしますか？',
    'Von Fieldwork Studio abmelden?',
  );
  String get signedOut => _w(
    'You’re signed out',
    'تم تسجيل الخروج',
    'ログアウトしました',
    'Du bist abgemeldet',
  );
  String get returnToStudio => _w(
    'Return to the studio',
    'العودة إلى الاستوديو',
    'スタジオに戻る',
    'Zurück ins Studio',
  );
  String get commands => _w('Commands', 'الأوامر', 'コマンド', 'Befehle');
  String get findCommand =>
      _w('Find a command', 'ابحث عن أمر', 'コマンドを検索', 'Befehl suchen');
  String get noCommands => _w(
    'No matching commands',
    'لا توجد أوامر مطابقة',
    '一致するコマンドはありません',
    'Keine passenden Befehle',
  );
  String get back => _w('Back', 'رجوع', '戻る', 'Zurück');
  String get minutes => _w('minutes', 'دقيقة', '分', 'Minuten');
  String get clear => _w('Clear', 'مسح', 'クリア', 'Leeren');
  String get account => _w('Account', 'الحساب', 'アカウント', 'Konto');
  String get workWeek => _w('Work week', 'أسبوع العمل', '稼働日', 'Arbeitswoche');
  String get selectPerson =>
      _w('Find a teammate', 'ابحث عن زميل', 'メンバーを検索', 'Teammitglied suchen');
  String get noPeople => _w(
    'No matching teammates',
    'لا يوجد زملاء مطابقون',
    '一致するメンバーはいません',
    'Keine passenden Teammitglieder',
  );
  String get workspace =>
      _w('Workspace', 'مساحة العمل', 'ワークスペース', 'Arbeitsbereich');
  String get preferences =>
      _w('Preferences', 'التفضيلات', '個人設定', 'Persönliche Einstellungen');

  String place(Place value) => [today, tasks, time, settings][value.index];
  String priorityName(Priority p) => [low, normal, high][p.index];
  String labelName(Label l) => [planning, review, fieldwork][l.index];
  String statusName(TaskStatus s) => [all, open, done][s.index];
  String sortName(TaskSort s) => [due, priority, title][s.index];
  String appearanceName(Appearance a) => [system, day, night][a.index];

  /// [value] in the language's digits: Arabic-Indic in Arabic, and a decimal
  /// comma in Arabic and German.
  String number(num value) {
    final raw = value.toString();
    return switch (language) {
      StintLanguage.ar =>
        raw
            .replaceAllMapped(
              RegExp(r'[0-9]'),
              (m) => _arabicDigits[int.parse(m[0]!)],
            )
            .replaceAll('.', '٫'),
      StintLanguage.de => raw.replaceAll('.', ','),
      _ => raw,
    };
  }

  /// Minutes typed in the digits these languages' keyboards give: ASCII,
  /// Arabic-Indic, or full width from a Japanese input method.
  int? parseMinutes(String input) {
    final normalized = input.replaceAllMapped(RegExp('[٠-٩０-９]'), (match) {
      final c = match[0]!;
      final arabicDigit = _arabicDigits.indexOf(c);
      return arabicDigit >= 0 ? '$arabicDigit' : '${c.codeUnitAt(0) - 0xff10}';
    });
    return int.tryParse(normalized);
  }

  String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    final hours = h != 0 || m == 0, mins = m != 0;
    return switch (language) {
      StintLanguage.en => [if (hours) '${h}h', if (mins) '${m}m'].join(' '),
      StintLanguage.ar => [
        if (hours) '${number(h)}\u00a0س',
        if (mins) '${number(m)}\u00a0د',
      ].join(' '),
      // Japanese sets no spaces: a word joiner keeps "2時間" and "30分"
      // whole, and a zero-width space lets a narrow label break between
      // them, never inside.
      StintLanguage.ja => [
        if (hours) '$h\u2060時\u2060間',
        if (mins) '$m\u2060分',
      ].join('\u200b'),
      StintLanguage.de => [
        if (hours) '$h\u00a0h',
        if (mins) '$m\u00a0min',
      ].join(' '),
    };
  }

  /// [duration] with each part on a line of its own, for a narrow column:
  /// "2h", "30m".
  String durationLines(int minutes) =>
      duration(minutes).replaceAll(' ', '\n').replaceAll('\u200b', '\n');

  /// [minutes] as hours and minutes, h:mm, in the language's digits:
  /// "2:45", Arabic "٢:٤٥". A chart whose full readings ([duration]) don't
  /// fit shows these, its caption naming what they count ([logged]).
  String hours(int minutes) =>
      '${number(minutes ~/ 60)}:${number(minutes % 60).padLeft(2, number(0))}';

  String clock(int minutes) {
    final zero = number(0);
    final hour = number(minutes ~/ 60).padLeft(2, zero);
    final minute = number(minutes % 60).padLeft(2, zero);
    return '$hour:$minute';
  }

  List<String> get weekdayNames => switch (language) {
    StintLanguage.en => const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    StintLanguage.ar => const [
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ],
    StintLanguage.ja => const ['月', '火', '水', '木', '金', '土', '日'],
    StintLanguage.de => const ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'],
  };
  String weekday(DateTime day) => weekdayNames[day.weekday - 1];
  String weekdayShort(DateTime day) => arabic
      ? const ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح'][day.weekday - 1]
      : weekday(day);
  String weekdayNarrow(DateTime day) => weekdayShort(day)[0];

  /// The shortest weekday names that stay apart, Monday first, for a chart
  /// too narrow for [weekdayNames]: "Tu" and "Th", "Sa" and "Su".
  List<String> get weekdayLetters => switch (language) {
    StintLanguage.en => const ['M', 'Tu', 'W', 'Th', 'F', 'Sa', 'Su'],
    _ => weekdayNames,
  };
  List<String> get monthNames => switch (language) {
    StintLanguage.en => const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
    StintLanguage.ar => const [
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
    ],
    StintLanguage.ja => const [
      '1月',
      '2月',
      '3月',
      '4月',
      '5月',
      '6月',
      '7月',
      '8月',
      '9月',
      '10月',
      '11月',
      '12月',
    ],
    StintLanguage.de => const [
      'Jan.',
      'Feb.',
      'März',
      'Apr.',
      'Mai',
      'Juni',
      'Juli',
      'Aug.',
      'Sept.',
      'Okt.',
      'Nov.',
      'Dez.',
    ],
  };

  String shortDate(DateTime day) {
    final month = monthNames[day.month - 1];
    return switch (language) {
      StintLanguage.en => '$month ${day.day}',
      StintLanguage.ar => '${number(day.day)} $month',
      StintLanguage.ja => '$month${day.day}日',
      StintLanguage.de => '${day.day}. $month',
    };
  }

  /// A due day with its year: Nov 20, 2026.
  String dueDate(DateTime day) => switch (language) {
    StintLanguage.en => '${shortDate(day)}, ${day.year}',
    StintLanguage.ar => '${shortDate(day)} ${number(day.year)}',
    StintLanguage.ja => '${day.year}年${shortDate(day)}',
    StintLanguage.de => '${shortDate(day)} ${day.year}',
  };

  /// The seven-day interval beginning on [start], in the workspace language.
  /// A compact range shares the month only when both endpoints belong to it.
  String weekRange(DateTime start, {bool compact = false}) {
    final end = addDays(start, 6);
    final month = monthNames[end.month - 1];
    if (compact && start.month == end.month) {
      return switch (language) {
        StintLanguage.ja => '$month${start.day}日～${end.day}日',
        StintLanguage.de => '${start.day}.–${end.day}. $month',
        _ => '${number(start.day)}–${number(end.day)} $month',
      };
    }
    return language == StintLanguage.ja
        ? '${shortDate(start)}～${shortDate(end)}'
        : '${shortDate(start)} – ${shortDate(end)}';
  }

  String get dayPart => _w('Day', 'اليوم', '日', 'Tag');
  String get monthPart => _w('Month', 'الشهر', '月', 'Monat');
  String get yearPart => _w('Year', 'السنة', '年', 'Jahr');
  String get increase => _w('Increase', 'زيادة', '増やす', 'Erhöhen');
  String get decrease => _w('Decrease', 'تقليل', '減らす', 'Verringern');

  /// A stepper button's name for [field]: "Increase Estimate", "見積もりを増やす".
  String adjust(String field, {required bool increase}) => switch (language) {
    StintLanguage.ja => '$fieldを${increase ? '増やす' : '減らす'}',
    StintLanguage.de => '$field ${increase ? 'erhöhen' : 'verringern'}',
    _ => '${increase ? this.increase : decrease} $field',
  };
  String relativeDay(int offset) {
    final n = offset.abs();
    return switch (language) {
      StintLanguage.en => switch (offset) {
        -1 => 'Yesterday',
        0 => today,
        1 => 'Tomorrow',
        _ => offset < 0 ? '$n days ago' : 'In $n days',
      },
      StintLanguage.ar => switch (offset) {
        -1 => 'أمس',
        0 => today,
        1 => 'غدًا',
        -2 => 'قبل يومين',
        2 => 'بعد يومين',
        _ =>
          '${offset < 0 ? 'قبل' : 'بعد'} ${number(n)} ${n % 100 >= 3 && n % 100 <= 10 ? 'أيام' : 'يومًا'}',
      },
      StintLanguage.ja => switch (offset) {
        -1 => '昨日',
        0 => today,
        1 => '明日',
        _ => offset < 0 ? '$n日前' : '$n日後',
      },
      StintLanguage.de => switch (offset) {
        -1 => 'Gestern',
        0 => today,
        1 => 'Morgen',
        -2 => 'Vorgestern',
        2 => 'Übermorgen',
        _ => offset < 0 ? 'Vor $n Tagen' : 'In $n Tagen',
      },
    };
  }

  /// A third density some looks offer between standard and compact.
  String get comfortable => _w('Comfortable', 'مريحة', 'ゆったり', 'Komfortabel');

  /// The signed-in teammate's initials, as an avatar shows them.
  String get mayaInitials => _w('MR', 'مر', 'マ', 'MR');

  /// What joins the items of a short list: "Planning, Review".
  String get listSeparator => _w(', ', '، ', '、', ', ');

  /// A menu bar's first menu.
  String get file => _w('File', 'ملف', 'ファイル', 'Datei');

  /// A skip link's words, the first stop of the keyboard.
  String get skipToContent => _w(
    'Skip to main content',
    'انتقل إلى المحتوى',
    'メインコンテンツへ移動',
    'Zum Hauptinhalt springen',
  );

  /// The heading of a form's error summary.
  String get thereIsAProblem => _w(
    'There is a problem',
    'توجد مشكلة',
    '入力内容に問題があります',
    'Es gibt ein Problem',
  );

  /// A search field's hint that finds a task by its title or ID.
  String get titleOrId =>
      _w('Title or ID', 'العنوان أو الرقم', 'タイトルまたはID', 'Titel oder ID');

  /// Help under the switch-task search while a timer runs on [title].
  String timeSavedBeforeSwitch(String title) => _w(
    'Your time on $title is saved before you switch.',
    'يُحفظ وقتك على «$title» قبل التبديل.',
    '切り替える前に「$title」の時間を保存します。',
    'Deine Zeit für „$title“ wird vor dem Wechsel gespeichert.',
  );

  /// How many rows a table holds.
  String rowCount(int n) => _w(
    n == 1 ? '1 row' : '$n rows',
    'عدد الصفوف: ${number(n)}',
    '$n行',
    n == 1 ? '1 Zeile' : '$n Zeilen',
  );

  String selected(int n) =>
      _w('$n selected', 'عدد المحدد: ${number(n)}', '$n件選択中', '$n ausgewählt');
  String totalTasks(int n) => _w(
    n == 1 ? '1 task' : '$n tasks',
    'عدد المهام: ${number(n)}',
    '$n件のタスク',
    n == 1 ? '1 Aufgabe' : '$n Aufgaben',
  );
}
