import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart'
    show expressiveLoadFonts;
import 'package:stint_core/stint_core.dart';
import 'package:stint_material_expressive/stint_material_expressive.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    pairedSections: true,
    loadFonts: expressiveLoadFonts,
    app: (launch, repo) =>
        StintMaterialExpressive(launch: launch, repository: repo),
  );

  const w = StintWords();
  testWidgets('section counts share the title line and done rows keep their '
      'project ink at night', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 2400);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      const StintMaterialExpressive(
        launch: StintLaunch(appearance: Appearance.night),
      ),
    );
    await tester.pumpAndSettle();
    final plan = find.byKey(const ValueKey('today-plan'));
    // One paragraph carries the title and its count, so they share a baseline.
    final count = w.progress(1, 4).replaceAll(' ', '\u00a0');
    expect(
      find.descendant(
        of: plan,
        matching: find.text('${w.todaysPlan}\u2003$count'),
      ),
      findsOneWidget,
    );
    // Print attendance sheets is done, so its row is selected; Confirm the
    // print workshop is open in the same project.
    final projects = find.descendant(
      of: plan,
      matching: find.text('Workshop series'),
    );
    expect(projects, findsNWidgets(2));
    final inks = [
      for (final element in projects.evaluate())
        (element.renderObject! as RenderParagraph).text.style?.color,
    ];
    expect(inks.first, isNotNull);
    expect(inks.last, inks.first);
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
    await tester.pumpWidget(StintMaterialExpressive(repository: repo));
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
    'the peak duration and bar fill the plot at phone and desktop widths',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final width in [390.0, 1440.0]) {
        tester.view.physicalSize = Size(width, 1800);
        await tester.pumpWidget(const StintMaterialExpressive());
        await tester.pumpAndSettle();
        final chart = find.byKey(const ValueKey('today-chart'));
        final peakReading = find.descendant(
          of: chart,
          matching: find.text('4h'),
        );
        final topInset =
            tester.getTopLeft(peakReading).dy - tester.getTopLeft(chart).dy;
        expect(topInset, closeTo(8, 1), reason: 'Thursday at ${width}px');
      }
    },
  );

  testWidgets(
    'logging a session rescales the week and breaks overlapping timeline joins',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = StintRepository(clock: () => studyMorning);
      await tester.pumpWidget(StintMaterialExpressive(repository: repo));
      await tester.pumpAndSettle();
      Finder keyed(String name) => find.byKey(ValueKey('today-$name'));
      final thursday = tester.getSize(keyed('day-slot-3')).height;
      final friday = tester.getSize(keyed('day-slot-4')).height;
      final fixture = StintController(repo)..data = repo.snapshot;
      addTearDown(fixture.dispose);
      final before = fixture.dailyMinutes(mondayOf(studyToday));
      expect(friday / thursday, closeTo(before[4] / before[3], .01));
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
      fixture.data = repo.snapshot;
      final after = fixture.dailyMinutes(mondayOf(studyToday));
      expect(after[3], before[3]);
      expect(
        find.descendant(of: keyed('chart'), matching: find.text('4h')),
        findsOneWidget,
      );
      final newPeak = tester.getSize(keyed('day-slot-4')).height;
      expect(newPeak, greaterThan(friday));
      expect(
        tester.getSize(keyed('day-slot-3')).height / newPeak,
        closeTo(after[3] / after[4], .01),
      );
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

  testWidgets(
    'the tracking mark and checkbox share a line at double text size',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 1800);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const StintMaterialExpressive(launch: StintLaunch(scale: 2)),
      );
      await tester.pumpAndSettle();
      final check = find.byKey(const ValueKey('today-plan-lead-ST-101'));
      final tracking = find.byKey(const ValueKey('today-plan-running'));
      expect(
        tester.getCenter(tracking).dy,
        closeTo(tester.getCenter(check).dy, 1),
      );
    },
  );

  testWidgets('empty Today explains the idle timer, plan and activity', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      StintMaterialExpressive(repository: StintRepository(empty: true)),
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
            StintMaterialExpressive(
              key: UniqueKey(),
              launch: StintLaunch(language: ar ? StintLanguage.ar : StintLanguage.en),
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
