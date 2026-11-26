import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';

void main() {
  late DateTime now;
  late StintRepository repo;
  late StintController c;
  setUp(() async {
    now = studyMorning;
    repo = StintRepository(clock: () => now);
    c = StintController(repo);
    await c.refresh();
  });
  tearDown(() => c.dispose());

  test(
    'stop, start and switch write once against the frozen studio clock',
    () async {
      final before = c.totalMinutes(c.week);
      final count = c.data.entries.length;
      expect(c.data.timer, (
        taskId: 'ST-101',
        start: DateTime(2026, 11, 20, 8, 18),
      ));
      expect(c.currentTask('maya')?.title.$1, 'Proof the studio map');
      c.track('ST-101');
      c.track('missing');
      c.track('ST-139');
      expect(c.data.entries.length, count);
      c.stopTimer();
      c.stopTimer();
      expect(c.data.timer, isNull);
      expect(c.currentTask('maya'), isNull);
      expect(c.totalMinutes(c.week), before + 102);
      final entry = c.todayBlocks.singleWhere(
        (e) => e.note == seedTasks().first.title,
      );
      expect((entry.start, entry.end, entry.project), (498, 600, 'studio'));
      c.track('ST-102');
      now = now.add(const Duration(minutes: 12, seconds: 9));
      c.track('ST-103');
      expect(c.data.timer, (taskId: 'ST-103', start: now));
      expect(c.totalMinutes(c.week), before + 114);
      expect(c.data.entries.length, count + 2);
      expect(c.data.activity.first.kind, ActivityKind.started);
      await c.refresh();
      expect(c.currentTask('maya')?.id, 'ST-103');
      c.stopTimer();
      expect(c.todayBlocks.last.end - c.todayBlocks.last.start, 1);
      expect(c.data.activity.length, 8);
    },
  );

  test(
    'a timer crossing the end of the week splits into the two dated blocks',
    () {
      c.stopTimer();
      now = DateTime(2026, 11, 22, 23, 50);
      c.track('ST-103');
      now = DateTime(2026, 11, 23, 0, 5);
      c.stopTimer();
      final oldWeek = c.entriesFor(c.week).first;
      final newWeek = c.entriesFor(addDays(c.week, 7)).single;
      expect(
        (oldWeek.date, oldWeek.start, oldWeek.end),
        (DateTime(2026, 11, 22), 1430, 1440),
      );
      expect(
        (newWeek.date, newWeek.start, newWeek.end),
        (DateTime(2026, 11, 23), 0, 5),
      );
    },
  );

  test('plan, task filters, draft, roster and timesheet follow the same completion', () async {
    expect(c.todayTasks.any((t) => t.done), isTrue);
    expect(c.todayTasks.every((t) => t.due == studyToday), isTrue);
    expect(
      c.laterThisWeek.every(
        (t) => t.due.isAfter(studyToday) && t.due.weekday >= 6 && !t.done,
      ),
      isTrue,
    );
    expect(c.todayBlocks.map((e) => e.start), orderedEquals([420, 540]));
    final task = c.currentTask('maya')!;
    c.openTask(task);
    c.changeTasks([task.id], done: true);
    expect(c.todayTasks.first.done, isTrue);
    expect(c.draft!.task.done, isTrue);
    expect(c.visible.map((t) => t.id), isNot(contains(task.id)));
    expect(c.openTasks.length, 29);
    expect(c.data.timer, isNull);
    expect(c.todayBlocks.length, 3);
    expect(c.data.activity.first.kind, ActivityKind.finished);
    await c.refresh();
    c.changeTasks([task.id], done: false);
    expect(c.todayTasks.first.done, isFalse);
    expect(c.visible.map((t) => t.id), contains(task.id));
    c.track(task.id);
    c.deleteTasks([task.id]);
    expect(c.data.timer, isNull);
    expect(c.todayBlocks.length, 4);
  });

  test('both languages name the five current tasks, all event kinds and relative times', () {
    expect(
      team.map((p) => c.currentTask(p.id)?.assignee),
      team.map((p) => p.id),
    );
    final feed = c.data.activity;
    expect(feed.length, inInclusiveRange(6, 8));
    expect(feed.map((e) => e.kind).toSet(), ActivityKind.values.toSet());
    expect(
      feed.map((e) => e.at),
      orderedEquals(
        feed.map((e) => e.at).toList()..sort((a, b) => b.compareTo(a)),
      ),
    );
    for (final ar in [false, true]) {
      final w = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
      for (final e in feed) {
        final name = w.text(team.firstWhere((p) => p.id == e.person).name);
        expect(w.text(e.subject), isNotEmpty);
        final sentence = w.eventAction(e, name);
        expect(sentence, contains(name));
        expect(RegExp('[A-Za-z]').hasMatch(sentence), !ar);
        expect(RegExp('[A-Za-z]').hasMatch(w.text(e.subject)), !ar);
      }
      expect(w.timeAgo(feed.first.at, now), ar ? 'الآن' : 'Just now');
      expect(
        w.elapsed(const Duration(hours: 1, minutes: 42)),
        ar ? '٠١:٤٢:٠٠' : '01:42:00',
      );
    }
    expect(c.words.eventAction(feed.first, 'Inez Park'), 'Inez Park logged 2h');
    expect(
      const StintWords(StintLanguage.ar)
          .timeAgo(now.subtract(const Duration(minutes: 12)), now),
      'قبل ١٢ دقيقة',
    );
    expect(
      const StintWords(StintLanguage.ar)
          .timeAgo(now.subtract(const Duration(hours: 2)), now),
      'قبل ساعتين',
    );
  });

  test('a task due this afternoon appears only in the plan and manual logs join the feed', () async {
    final sameDay = c.openTasks.first.copyWith(
      due: atMinute(studyToday, 15 * 60),
    );
    repo.put(sameDay);
    await c.refresh();
    expect(c.todayTasks.map((t) => t.id), contains(sameDay.id));
    expect(c.laterThisWeek.map((t) => t.id), isNot(contains(sameDay.id)));
    final entry = EntryDraft(studyToday)..note = 'Checked the route';
    expect(c.addEntry(entry), isTrue);
    expect(c.data.activity.first.kind, ActivityKind.logged);
    expect(
      c.data.activity.first.subject,
      TranslatedText.asEntered('Checked the route'),
    );
    entry.dispose();
  });

  test('an empty workspace has no seeded timer, blocks or activity', () async {
    final empty = StintController(StintRepository(empty: true));
    await empty.refresh();
    expect(empty.data.timer, isNull);
    expect(empty.todayTasks, isEmpty);
    expect(empty.todayBlocks, isEmpty);
    expect(empty.data.activity, isEmpty);
    expect(team.every((p) => empty.currentTask(p.id) == null), isTrue);
    empty.dispose();
  });
}
