import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_fluent2_design/stint_fluent2_design.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    pairedSections: true,
    loadFonts: loadStintFluent2Fonts,
    app: (launch, repo) => StintFluent2Design(launch: launch, repository: repo),
  );

  const w = StintWords();
  testWidgets('a paired list keeps its last row icon and text on one centre', (
    tester,
  ) async {
    await tester.runAsync(loadStintFluent2Fonts);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final width in [768.0, 1440.0]) {
      tester.view.physicalSize = Size(width, 2400);
      await tester.pumpWidget(const StintFluent2Design());
      await tester.pumpAndSettle();
      Rect face(String id) =>
          tester.getRect(find.byKey(ValueKey('today-$id-face')));
      // The plan is the shorter list, so its last row takes the extra height.
      expect(face('plan').bottom, closeTo(face('team').bottom, 1));
      final text = tester.getRect(find.text(w.viewTasks));
      final icon = tester.getRect(
        find.descendant(
          of: find.byKey(const ValueKey('today-plan-lead-all')),
          matching: find.byType(Icon),
        ),
      );
      expect(icon.center.dy, closeTo(text.center.dy, 1), reason: '$width px');
    }
  });

  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintFluent2Design(repository: repo));
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
      for (var step = 0; step < 90; step++) {
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
    await tester.tap(find.bySemanticsLabel(w.cancel).first);
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
    'logging a session preserves other days and breaks overlapping timeline joins',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StintRepository(clock: () => studyMorning);
      await tester.pumpWidget(StintFluent2Design(repository: repo));
      await tester.pumpAndSettle();
      Finder keyed(String name) => find.byKey(ValueKey('today-$name'));
      final thursday = tester.getSize(keyed('day-slot-3')).height;
      final friday = tester.getSize(keyed('day-slot-4')).height;
      expect(keyed('link-blocks-lead-0'), findsOneWidget);
      await tester.tap(find.text(w.stopTimer));
      await tester.pumpAndSettle();
      expect(
        tester.widget<Text>(keyed('timer-title')).data,
        'Proof the studio map',
      );
      expect(tester.widget<Text>(keyed('timer-digits')).data, '01:42:00');
      expect(
        find.descendant(
          of: keyed('timer-well'),
          matching: find.text('Maya Reed logged 1h 42m'),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(keyed('day-slot-3')).height, thursday);
      expect(tester.getSize(keyed('day-slot-4')).height, greaterThan(friday));
      expect(keyed('link-blocks-lead-0'), findsNothing);
      expect(keyed('link-blocks-lead-1'), findsNothing);
      final first = tester.getRect(keyed('block-band-0'));
      final overlapping = tester.getRect(keyed('block-band-1'));
      final third = tester.getRect(keyed('block-band-2'));
      expect(overlapping.left, inExclusiveRange(first.left, first.right));
      expect(overlapping.right, greaterThan(third.right));
      expect(third.left, closeTo(first.right, 1));
    },
  );

  testWidgets('at 200 percent chart days and minutes fit their slots', (
    tester,
  ) async {
    await tester.runAsync(loadStintFluent2Fonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 2000);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      StintFluent2Design(
        launch: const StintLaunch(scale: 2),
        repository: StintRepository(clock: () => studyMorning),
      ),
    );
    await tester.pumpAndSettle();
    Finder day(String part, int index) =>
        find.byKey(ValueKey('today-day-$part-$index'));
    final slotWidth =
        tester.getCenter(day('slot', 1)).dx -
        tester.getCenter(day('slot', 0)).dx;
    void fits(Finder finder) {
      final label = tester.widget<Text>(finder);
      for (final line in label.data!.split('\n')) {
        final width = TextPainter.computeWidth(
          text: TextSpan(text: line, style: label.style),
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(tester.element(finder)),
        );
        expect(width, lessThanOrEqualTo(slotWidth), reason: line);
      }
    }

    for (var i = 0; i < 7; i++) {
      final label = day('label', i);
      expect(
        tester.widget<Text>(label).data,
        w.weekdayShort(addDays(mondayOf(studyToday), i)),
      );
      fits(label);
    }
    // Too wide in full at 200 percent: the week reads in h:mm.
    expect(find.text(w.logged), findsOneWidget);
    fits(find.text(w.hours(150)).first);
  });

  testWidgets('Arabic hour and minute readings fit inside the phone chart', (
    tester,
  ) async {
    await tester.runAsync(loadStintFluent2Fonts);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 1000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      const StintFluent2Design(launch: StintLaunch(language: StintLanguage.ar)),
    );
    await tester.pumpAndSettle();
    const ar = StintWords(StintLanguage.ar);
    final monday = find.byKey(const ValueKey('today-day-slot-0'));
    final tuesday = find.byKey(const ValueKey('today-day-slot-1'));
    final slotWidth =
        tester.getCenter(monday).dx - tester.getCenter(tuesday).dx;
    // One form for the week, each reading on one line inside its slot.
    for (final minutes in [150, 210, 165]) {
      final full = find.text(ar.duration(minutes));
      final reading = full.evaluate().isNotEmpty
          ? full.first
          : find.text(ar.hours(minutes)).first;
      final label = tester.widget<Text>(reading);
      expect(label.maxLines, 1);
      expect(
        TextPainter.computeWidth(
          text: TextSpan(text: label.data, style: label.style),
          textDirection: TextDirection.rtl,
        ),
        lessThanOrEqualTo(slotWidth - 2),
      );
    }
  });

  testWidgets('empty Today explains the idle timer, plan and activity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      StintFluent2Design(repository: StintRepository(empty: true)),
    );
    await tester.pumpAndSettle();
    for (final message in [
      w.stoppedTimer,
      w.noTimerTasks,
      w.noTasksToday,
      w.noBlocks,
      w.noActivity,
      w.allClear,
    ]) {
      expect(find.text(message), findsOneWidget);
    }
    expect(
      tester.getSemantics(find.text(w.startTimer)),
      isSemantics(hasTapAction: false),
    );
    expect(find.text(w.notTracking), findsNWidgets(team.length));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Today changes from one column to two at tablet width in either direction',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final ar in [false, true]) {
        for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
          tester.view.physicalSize = Size(width, 900);
          await tester.pumpWidget(
            StintFluent2Design(
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
            find.byKey(const ValueKey('today-team-lead-maya')),
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
          if (width >= 1024) {
            final digits = find.byKey(const ValueKey('today-timer-digits'));
            double leading() {
              final rect = tester.getRect(digits);
              return ar ? rect.right : rect.left;
            }

            final beforeSwitch = leading();
            final target = StintWords(
              ar ? StintLanguage.ar : StintLanguage.en,
            ).text(seedTasks().firstWhere((task) => task.id == 'ST-102').title);
            await tester.tap(find.byKey(const ValueKey('today-action-last')));
            await tester.pumpAndSettle();
            await tester.enterText(find.byType(EditableText), target);
            await tester.pumpAndSettle();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pumpAndSettle();
            final title = find.byKey(const ValueKey('today-timer-title'));
            expect(tester.widget<Text>(title).data, target);
            expect(leading(), closeTo(beforeSwitch, 1));
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
