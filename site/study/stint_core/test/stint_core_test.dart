import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

void main() {
  late StintRepository repo;
  late StintController c;
  setUp(() {
    repo = StintRepository();
    c = StintController(repo);
  });
  tearDown(() => c.dispose());

  test(
    'week ranges retain both dates across months and years in both languages',
    () {
      const en = StintWords(), ar = StintWords(StintLanguage.ar);
      final november = DateTime(2026, 11, 16), newYear = DateTime(2026, 12, 28);
      expect(en.weekRange(november), 'Nov 16 – Nov 22');
      expect(en.weekRange(november, compact: true), '16–22 Nov');
      expect(ar.weekRange(november, compact: true), '١٦–٢٢ نوفمبر');
      expect(
        en.weekRange(DateTime(2026, 11, 30), compact: true),
        'Nov 30 – Dec 6',
      );
      expect(en.weekRange(newYear, compact: true), 'Dec 28 – Jan 3');
      expect(ar.weekRange(newYear, compact: true), '٢٨ ديسمبر – ٣ يناير');
    },
  );
  test('a fresh studio has the same forty tasks, related team, projects and two weeks of entries', () async {
    await c.refresh();
    expect(team.length, 5);
    expect(projects.length, 3);
    expect(c.data.tasks.map((t) => t.id).toSet().length, 40);
    expect(c.data.tasks.map((t) => t.title), seedTasks().map((t) => t.title));
    for (final t in c.data.tasks) {
      expect(team.any((p) => p.id == t.assignee), isTrue);
      expect(projects.any((p) => p.id == t.project), isTrue);
    }
    expect(c.openTasks.length, 30);
    expect(c.entriesFor(c.week).length, 10);
    expect(c.entriesFor(addDays(c.week, -7)).length, 10);
    expect(
      c.totalMinutes(c.week),
      c.entriesFor(c.week).fold<int>(0, (n, e) => n + e.end - e.start),
    );
  });
  test('loads, fails once, retries and ignores stale completions after a faster retry or disposal', () async {
    repo.latency = const Duration(milliseconds: 8);
    repo.failNext = true;
    final older = c.refresh();
    expect(c.state, DataState.loading);
    repo.latency = Duration.zero;
    await c.refresh();
    await older;
    expect(c.state, DataState.ready);
    repo.failNext = true;
    await c.refresh();
    expect(c.state, DataState.error);
    await c.refresh();
    expect(c.state, DataState.ready);
    final empty = StintController(StintRepository(empty: true));
    await empty.refresh();
    expect(empty.openTasks, isEmpty);
    expect(empty.data.entries, isEmpty);
    final last = empty.refresh();
    empty.dispose();
    await last;
  });
  test('filters intersect, search uses the chosen language, sort is stable, selections mutate only named tasks', () async {
    await c.refresh();
    c.filter((f) {
      f.status = TaskStatus.open;
      f.project = 'studio';
      f.assignee = 'maya';
      f.search = 'ST-101';
    });
    expect(c.visible.map((t) => t.id), ['ST-101']);
    c.filter((f) => f.reset());
    c.settings.update(() => c.settings.language = StintLanguage.ar);
    c.filter((f) => f.search = 'خريطة الاستوديو');
    expect(c.visible.single.id, 'ST-101');
    c.filter((f) {
      f.reset();
      f.status = TaskStatus.open;
      f.sort = TaskSort.priority;
    });
    expect(c.visible.first.priority, Priority.high);
    expect(c.visible.last.priority, Priority.low);
    c.filter((f) => f.sort = TaskSort.title);
    expect(
      c.visible.first.title,
      c.visible
          .map((t) => t.title)
          .reduce((a, b) => a.$2.compareTo(b.$2) < 0 ? a : b),
    );
    c.toggleSelection('ST-101');
    c.toggleSelection('ST-102');
    c.changeTasks(c.selected, project: 'workshops', done: true);
    expect(c.openTasks.length, 28);
    expect(c.selected, isEmpty);
    expect(c.data.tasks.first.project, 'workshops');
    c.selectResults();
    expect(c.selected.length, 28);
    final deleted = c.deleteTasks(c.selected);
    expect(c.data.tasks.length, 12);
    c.undoDelete(deleted);
    c.undoDelete(deleted);
    expect(c.data.tasks.length, 40);
  });
  test('drafts validate in both languages, reverting clears dirty, material edits survive a refresh', () async {
    await c.refresh();
    final task = c.data.tasks.first;
    c.openTask(task);
    final d = c.draft!;
    d.setDue(null);
    expect(c.saveTask(), isFalse);
    expect(
      d.errors(const StintWords(StintLanguage.ar))['due'],
      const StintWords(StintLanguage.ar).dateError,
    );
    d.setDue(task.due);
    expect(d.dirty, isFalse);
    d.title('', StintLanguage.en);
    expect(c.saveTask(), isFalse);
    expect(
      d.errors(const StintWords(StintLanguage.ar))['title'],
      const StintWords(StintLanguage.ar).titleError,
    );
    d.title(task.title.$1, StintLanguage.en);
    expect(d.dirty, isFalse);
    d.edit(
      d.task.copyWith(estimate: 2, assignee: 'missing', project: 'missing'),
    );
    expect(
      d.errors(c.words).keys,
      containsAll(['estimate', 'assignee', 'project']),
    );
    d.edit(task);
    d.toggle(Label.review);
    d.notes('A new note', StintLanguage.en);
    d.title('Trace the step-free path', StintLanguage.en);
    d.edit(d.task.copyWith(reminderMinute: 12 * 60, done: true));
    expect(c.saveTask(), isTrue);
    expect(c.draft!.dirty, isFalse);
    await c.refresh();
    expect(c.data.tasks.first.notes.$2, 'A new note');
    expect(c.data.tasks.first.reminderMinute, 720);
    expect(c.data.tasks.first.labels, contains(Label.review));
    c.openTask(null);
    expect(c.draft, isNull);
  });
  test('time validates order and notes, logs to its date, shifts calendar weeks, totals by day', () async {
    await c.refresh();
    c.shiftWeek(-1);
    final before = c.totalMinutes(c.week);
    final entry = EntryDraft(addDays(c.week, 6))..end = 500;
    expect(c.addEntry(entry), isFalse);
    expect(
      entry.errors(const StintWords(StintLanguage.ar)).keys,
      containsAll(['end', 'note']),
    );
    entry.update(() {
      entry.end = 630;
      entry.note = '  Bind samples  ';
    });
    expect(c.addEntry(entry), isTrue);
    expect(c.dailyMinutes(c.week).last, 90);
    expect(c.totalMinutes(c.week), before + 90);
    expect(c.entriesFor(c.week).first.note.$1, 'Bind samples');
    entry.dispose();
    expect(mondayOf(DateTime(2027, 1, 1)), DateTime(2026, 12, 28));
  });
  test('launch links, scenarios, preferences and Arabic formatting apply to the same data', () async {
    final l = StintLaunch.fromUri(
      Uri.parse(
        'https://example.test/?dir=rtl#/detail?theme=night&scale=2&density=compact&state=error',
      ),
    );
    final model = StintController(
      l.createRepository()..latency = Duration.zero,
      launch: l,
    );
    await model.refresh();
    expect(model.state, DataState.error);
    await model.refresh();
    expect(model.place, Place.tasks);
    expect(model.draft!.task.id, 'ST-101');
    expect(model.settings.compact, isTrue);
    expect(model.settings.scale, 2);
    expect(model.settings.appearance, Appearance.night);
    expect(model.words.duration(90), '١\u00a0س ٣٠\u00a0د');
    expect(model.words.clock(545), '٠٩:٠٥');
    expect(model.words.shortDate(studyToday), '٢٠ نوفمبر');
    model.signIn(false);
    expect(model.signedIn, isFalse);
    model.signIn(true);
    expect(model.place, Place.today);
    model.dispose();
  });
  test('Japanese and German read as a native speaker writes them', () {
    const ja = StintWords(StintLanguage.ja), de = StintWords(StintLanguage.de);
    final day = DateTime(2026, 11, 20);
    expect(ja.duration(90), '1\u2060時\u2060間\u200b30\u2060分');
    expect(ja.durationLines(90), '1\u2060時\u2060間\n30\u2060分');
    expect(ja.weekdayLetters.first, '月');
    expect(ja.shortDate(day), '11月20日');
    expect(ja.dueDate(day), '2026年11月20日');
    expect(ja.weekRange(DateTime(2026, 11, 16), compact: true), '11月16日～22日');
    expect(ja.totalTasks(5), '5件のタスク');
    expect(ja.parseMinutes('９０'), 90);
    expect(de.duration(90), '1\u00a0h 30\u00a0min');
    expect(de.shortDate(day), '20. Nov.');
    expect(
      de.weekRange(DateTime(2026, 12, 28), compact: true),
      '28. Dez. – 3. Jan.',
    );
    expect(de.percent(1.5), '150\u00a0%');
    expect(de.rowCount(1), '1 Zeile');
    expect(
      de.timeSavedBeforeSwitch('X'),
      'Deine Zeit für „X“ wird vor dem Wechsel gespeichert.',
    );
    const en = StintWords();
    for (final task in seedTasks()) {
      expect(ja.text(task.title), isNot(en.text(task.title)));
      expect(de.text(task.title).trim(), isNotEmpty);
    }
    for (final language in StintLanguage.values) {
      expect(StintLanguage.forCode(language.name), language);
      expect(language.rtl, language == StintLanguage.ar);
    }
    expect(StintLanguage.forCode('fr'), StintLanguage.en);
    expect(
      StintLaunch.fromUri(Uri.parse('https://example.test/?lang=ja')).language,
      StintLanguage.ja,
    );
    expect(
      StintLaunch.fromUri(Uri.parse('https://example.test/?dir=rtl&lang=de'))
          .language,
      StintLanguage.ar,
    );
  });
  test('an accent opens from the address and is shared with the settings', () {
    String? accent(String query) =>
        StintLaunch.fromUri(Uri.parse('https://example.test/?$query')).accent;
    expect(accent('accent=mint'), 'mint');
    expect(accent('theme=night'), isNull);
    final launch = StintLaunch.fromUri(
      Uri.parse('https://example.test/?accent=sky'),
    );
    final settings = StintSettings(launch);
    expect(settings.accent, 'sky');
    expect(launch.sharing(settings).accent, 'sky');
    settings.update(() => settings.accent = null);
    expect(settings.accent, isNull);
  });

  test("an edition's palettes reach the settings it shares; the accent picks "
      "one of them, else the look's own", () {
    const own = StintPalette('clay', Color(0xFFD9825B));
    const mint = StintPalette('mint', Color(0xFF3E9C7C));
    const launch = StintLaunch(accent: 'mint');
    final settings = StintSettings(launch);
    var heard = 0;
    settings.addListener(() => heard++);
    expect(settings.palette, isNull);
    final controller = StintController(
      StintRepository(),
      launch: launch.sharing(settings),
      palettes: const [own, mint],
    );
    expect(heard, 1, reason: 'a host hears the palettes arrive');
    expect(settings.palettes.map((p) => p.name), ['Clay', 'Mint']);
    expect(settings.palette, mint);
    expect(settings.presetOf(const ['clay', 'mint']), 'mint');
    // Another look's palette (an old address) keeps this look's own.
    settings.update(() => settings.accent = 'navy');
    expect(settings.palette, own);
    expect(settings.presetOf(const ['clay', 'mint']), 'clay');
    controller.dispose();
    settings.dispose();
  });

  test("the Material and Cupertino references offer their own and Stint's "
      'five seeds', () {
    const own = StintPalette('look', Color(0xFF415F91), label: 'Look’s own');
    expect(StintAccent.palettesAfter(own).map((p) => (p.id, p.name)), [
      ('look', 'Look’s own'),
      ('navy', 'Navy'),
      ('green', 'Green'),
      ('gold', 'Black + gold'),
      ('purple', 'Purple'),
      ('pastel', 'Pastel'),
    ]);
  });

  test('week readings too wide for their slot read h:mm, never decimal '
      'hours', () {
    const en = StintWords(), de = StintWords(StintLanguage.de);
    const ar = StintWords(StintLanguage.ar);
    expect(en.hours(165), '2:45');
    expect(en.hours(168), '2:48');
    expect(en.hours(60), '1:00');
    expect(de.hours(5), '0:05');
    expect(ar.hours(165), '٢:٤٥');
  });

  test('a shared settings object outlives the controller that borrows it', () {
    final settings = StintSettings(const StintLaunch());
    final borrowed = StintController(
      StintRepository(),
      launch: const StintLaunch().sharing(settings),
    );
    expect(borrowed.settings, same(settings));
    borrowed.dispose();
    settings.update(() => settings.language = StintLanguage.de);
    expect(settings.words.language, StintLanguage.de);
    settings.dispose();
  });
}
