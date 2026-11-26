import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_material/stint_material.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: () => (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load(),
    app: (launch, repository) =>
        StintMaterial(launch: launch, repository: repository),
  );
  const w = StintWords();
  void viewport(WidgetTester t, double width) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, 960);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  testWidgets('Tracking, stopping and ticking update the visible workspace', (
    t,
  ) async {
    viewport(t, 1440);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await t.pumpWidget(StintMaterial(repository: repo));
    await t.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    final mondaySlot = find.byKey(const ValueKey('today-day-slot-0'));
    final mondayX = t.getCenter(mondaySlot).dx;
    now = now.add(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    Future<void> press(String label) async {
      final target = find.text(label).first;
      await t.ensureVisible(target);
      await t.tap(target);
      await t.pumpAndSettle();
    }

    Future<void> choose(String title) async {
      final field = find.byType(EditableText).last;
      await t.enterText(field, title);
      await t.pumpAndSettle();
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
    }

    final switchButton = find.text(w.switchTask);
    for (var i = 0; i < 30; i++) {
      if (isSemantics(isFocused: true)
          .matches(t.getSemantics(switchButton), {})) {
        break;
      }
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
    }
    expect(t.getSemantics(switchButton), isSemantics(isFocused: true));
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    expect(find.byType(EditableText), findsNothing);

    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    expect(t.getCenter(mondaySlot).dx, closeTo(mondayX, 1));
    await press(w.stopTimer);
    expect(repo.snapshot.timer, isNull);
    expect(repo.snapshot.entries.length, 22);
    expect(find.text(w.stoppedTimer), findsOneWidget);
    final logged = repo.snapshot.activity.first;
    expect(logged.kind, ActivityKind.logged);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('today-timer-digits'))).data,
      w.duration(logged.minutes),
    );
    final well = find.byKey(const ValueKey('today-timer-well'));
    expect(
      find.descendant(
        of: well,
        matching: find.text(w.eventAction(logged, w.text(team.first.name))),
      ),
      findsOneWidget,
    );
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    expect(find.text(w.runningTimer), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Plan completion, later tasks and the feed reflect the same data',
    (t) async {
      viewport(t, 768);
      final repo = StintRepository();
      await t.pumpWidget(StintMaterial(repository: repo));
      await t.pumpAndSettle();
      t.view.physicalSize = const Size(768, 4100);
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.text(w.greeting)).dy, lessThan(140));
      expect(
        t.getSemantics(find.text(w.todaysPlan)),
        isSemantics(label: w.todaysPlan, isHeader: true, hasTapAction: false),
      );
      expect(
        t.getSemantics(find.text(w.viewTasks)),
        isSemantics(label: w.viewTasks, hasTapAction: true),
      );
      final row = find.byKey(const ValueKey('plan-ST-101'));
      await t.ensureVisible(row);
      await t.tap(
        find.descendant(of: row, matching: find.text('Proof the studio map')),
      );
      await t.pumpAndSettle();
      expect(repo.snapshot.tasks.first.done, isTrue);
      expect(
        t.getSemantics(row),
        isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
      );
      expect(find.text(w.stoppedTimer), findsOneWidget);
      expect(find.text(w.progress(2, 4)), findsOneWidget);
      expect(find.text(w.number(29)), findsOneWidget);
      for (final person in team) {
        expect(find.text(w.text(person.name)), findsOneWidget);
      }
      expect(
        find.text(
          w.eventAction(repo.snapshot.activity.first, w.text(team.first.name)),
        ),
        findsWidgets,
      );
      final later = find.text('Send the materials list').first;
      await t.ensureVisible(later);
      await t.tap(later);
      await t.pumpAndSettle();
      expect(find.text(w.title), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Large chart labels share a baseline and stay separated', (
    t,
  ) async {
    viewport(t, 390);
    await t.pumpWidget(const StintMaterial(launch: StintLaunch(scale: 2)));
    await t.pumpAndSettle();
    Rect? previous;
    for (var i = 0; i < 7; i++) {
      final label = find.byKey(ValueKey('today-day-label-$i'));
      final rect = t.getRect(label);
      expect(
        t.widget<Text>(label).data,
        w.weekdayShort(addDays(mondayOf(studyToday), i)),
      );
      if (previous != null) {
        expect(rect.left - previous.right, greaterThanOrEqualTo(3));
        expect(rect.bottom, closeTo(previous.bottom, 1));
      }
      previous = rect;
    }
  });

  testWidgets(
    'An empty workspace explains the timer, schedule and feed in Arabic',
    (t) async {
      viewport(t, 390);
      const ar = StintWords(StintLanguage.ar);
      await t.pumpWidget(
        StintMaterial(
          launch: const StintLaunch(language: StintLanguage.ar, scale: 2),
          repository: StintRepository(empty: true),
        ),
      );
      await t.pumpAndSettle();
      for (final label in [
        ar.stoppedTimer,
        ar.noTimerTasks,
        ar.noTasksToday,
        ar.noBlocks,
        ar.allClear,
        ar.noActivity,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final start = find.text(ar.startTimer);
      expect(
        t.getSemantics(start),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      expect(t.takeException(), isNull);
    },
  );
}
