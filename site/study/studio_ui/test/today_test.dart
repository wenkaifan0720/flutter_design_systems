import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_studio/stint_studio.dart';
import 'package:studio_ui/studio_ui.dart' show studioLoadFonts;

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: studioLoadFonts,
    app: (launch, repository) =>
        StintStudio(launch: launch, repository: repository),
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
    await tester.pumpWidget(StintStudio(repository: repo));
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

    Future<void> activateWithKeyboard(
      Finder target,
      LogicalKeyboardKey key,
    ) async {
      for (var step = 0; step < 40; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        if (isSemantics(isFocused: true)
            .matches(tester.getSemantics(target), {})) {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          return;
        }
      }
      fail('Tab did not reach $target');
    }

    Future<void> choose(String title) async {
      final field = find.byType(EditableText).last;
      await tester.tap(field);
      await tester.enterText(field, title);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await activateWithKeyboard(
      find.text(w.switchTask),
      LogicalKeyboardKey.enter,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    await activateWithKeyboard(
      find.text(w.stopTimer),
      LogicalKeyboardKey.space,
    );
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
    final title = find.descendant(
      of: row,
      matching: find.text('Edit the walking route'),
    );
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isTrue,
    );
    expect(
      tester.getSemantics(row),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    await activateWithKeyboard(row, LogicalKeyboardKey.space);
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paired list headings and wells line up after Arabic text wraps',
    (tester) async {
      await tester.runAsync(studioLoadFonts);
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(768, 3000);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const words = StintWords(StintLanguage.ar);
      for (final switched in [false, true]) {
        final repository = StintRepository(clock: () => studyMorning);
        if (switched) repository.track('ST-102');
        await tester.pumpWidget(
          StintStudio(
            key: UniqueKey(),
            launch: const StintLaunch(language: StintLanguage.ar),
            repository: repository,
          ),
        );
        await tester.pumpAndSettle();
        Rect well(String key) =>
            tester.getRect(find.byKey(ValueKey('today-$key')));
        final plan = well('plan'), team = well('team');
        expect(plan.left, greaterThan(team.right));
        expect(plan.top, closeTo(team.top, 1));
        expect(plan.bottom, closeTo(team.bottom, 1));
        final blockHeading = tester.getTopLeft(find.text(words.timeBlocks)).dy;
        final feedHeading = tester
            .getTopLeft(find.text(words.recentActivity))
            .dy;
        expect(blockHeading, closeTo(feedHeading, 1));
        expect(well('blocks').top, closeTo(well('feed').top, 1));
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('Tab walks the plan in task order on a phone', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final repo = StintRepository(clock: () => studyMorning);
    final model = StintController(repo)..data = repo.snapshot;
    addTearDown(model.dispose);
    await tester.pumpWidget(StintStudio(repository: repo));
    await tester.pumpAndSettle();
    final rows = [
      for (final task in model.todayTasks)
        find.byKey(ValueKey('plan-${task.id}')),
    ];
    for (var step = 0; step < 20; step++) {
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
      expect(centre.dy, inInclusiveRange(56, 784));
    }
  });

  testWidgets(
    'Today changes from one column to two at tablet width in either direction',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final ar in [false, true]) {
        final words = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
        for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(
            StintStudio(
              key: UniqueKey(),
              launch: StintLaunch(
                language: ar ? StintLanguage.ar : StintLanguage.en,
              ),
              repository: StintRepository(),
            ),
          );
          await tester.pumpAndSettle();
          final row = tester.getRect(find.byKey(const ValueKey('plan-ST-101')));
          final name = tester.getRect(
            find.text(words.text(team.first.name)).first,
          );
          if (width == 390) {
            expect(row.bottom, lessThan(name.top));
            expect(row.left, lessThan(name.center.dx));
            expect(row.right, greaterThan(name.center.dx));
          } else if (ar) {
            expect(name.right, lessThan(row.left));
          } else {
            expect(name.left, greaterThan(row.right));
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );

  testWidgets('paired plan rows take a tap where they paint at 1440', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      StintStudio(repository: StintRepository(clock: () => studyMorning)),
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
      // A screen reader's tap lands on the row the eye sees, not the one
      // above it.
      expect(
        (rect.center.dy - painted.center.dy).abs(),
        lessThan(2),
        reason: 'plan row $i paints at $painted, its semantics at $rect',
      );
    }
    handle.dispose();
  });
}
