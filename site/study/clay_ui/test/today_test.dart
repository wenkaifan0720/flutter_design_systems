import 'package:clay_ui/clay_ui.dart' show clayLoadFonts;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_clay/stint_clay.dart';
import 'package:stint_core/stint_core.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: clayLoadFonts,
    app: (launch, repository) =>
        StintClay(launch: launch, repository: repository),
  );
  const w = StintWords();
  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintClay(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    Future<void> press(String text) async {
      final label = find.text(text).first;
      await tester.ensureVisible(label);
      await tester.tap(label);
      await tester.pumpAndSettle();
    }

    Future<void> choose(String title) async {
      final field = find.byType(EditableText).last;
      await tester.tap(field);
      await tester.enterText(field, title);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await press(w.switchTask);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    await press(w.stopTimer);
    expect(repo.snapshot.timer, isNull);
    expect(repo.snapshot.entries.length, 22);
    final savedEntry = repo.snapshot.activity.first;
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-timer-card')),
        matching: find.text(w.eventAction(savedEntry, w.text(team.first.name))),
      ),
      findsOneWidget,
    );
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');

    final row = find.byKey(const ValueKey('plan-ST-102'));
    await tester.ensureVisible(row);
    await tester.tap(
      find.descendant(of: row, matching: find.text('Edit the walking route')),
    );
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isTrue,
    );
    expect(
      tester.getSemantics(row),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tab walks the plan in task order on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = StintRepository(clock: () => studyMorning);
    final model = StintController(repo)..data = repo.snapshot;
    addTearDown(model.dispose);
    await tester.pumpWidget(StintClay(repository: repo));
    await tester.pumpAndSettle();
    final rows = [
      for (final task in model.todayTasks)
        find.byKey(ValueKey('plan-${task.id}')),
    ];
    for (var step = 0; step < 24; step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();
      if (isSemantics(isFocused: true)
          .matches(tester.getSemantics(rows.first), {})) {
        break;
      }
    }
    for (final (index, row) in rows.indexed) {
      if (index > 0) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
      }
      expect(tester.getSemantics(row), isSemantics(isFocused: true));
      final centre = tester.getCenter(row);
      expect(centre.dy, inInclusiveRange(56, 760));
    }
  });

  testWidgets('paired plan and team slabs line up after Arabic text wraps', (
    tester,
  ) async {
    await tester.runAsync(clayLoadFonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(768, 3000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const words = StintWords(StintLanguage.ar);
    for (final switched in [false, true]) {
      final repository = StintRepository(clock: () => studyMorning);
      if (switched) repository.track('ST-102');
      await tester.pumpWidget(
        StintClay(
          key: UniqueKey(),
          launch: const StintLaunch(language: StintLanguage.ar),
          repository: repository,
        ),
      );
      await tester.pumpAndSettle();
      Rect slab(String key) =>
          tester.getRect(find.byKey(ValueKey('today-$key')));
      final plan = slab('plan'), team = slab('team');
      expect(plan.left, greaterThan(team.right));
      expect(plan.top, closeTo(team.top, 1));
      expect(plan.bottom, closeTo(team.bottom, 1));
      final blockHeading = tester.getTopLeft(find.text(words.timeBlocks)).dy;
      final feedHeading = tester.getTopLeft(find.text(words.recentActivity)).dy;
      expect(blockHeading, closeTo(feedHeading, 1));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('paired plan rows take a tap where they paint at 1440', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      StintClay(repository: StintRepository(clock: () => studyMorning)),
    );
    await tester.pumpAndSettle();
    final rows = find.byWidgetPredicate(
      (widget) =>
          widget.key is ValueKey<String> &&
          (widget.key! as ValueKey<String>).value.startsWith('plan-'),
    );
    expect(rows, findsAtLeastNWidgets(4));
    for (var i = 0; i < rows.evaluate().length; i++) {
      final painted = tester.getRect(rows.at(i));
      final node = tester.getSemantics(rows.at(i));
      var rect = node.rect;
      for (var n = node; ; n = n.parent!) {
        if (n.transform != null) {
          rect = MatrixUtils.transformRect(n.transform!, rect);
        }
        if (n.parent == null) break;
      }
      // A screen reader's tap lands on the row the eye sees.
      expect(
        (rect.center.dy - painted.center.dy).abs(),
        lessThan(2),
        reason: 'plan row $i paints at $painted, its semantics at $rect',
      );
    }
    handle.dispose();
  });
}
