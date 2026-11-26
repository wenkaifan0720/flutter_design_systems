import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart' show frostedLoadFonts;
import 'package:stint_core/stint_core.dart';
import 'package:stint_frosted/stint_frosted.dart';

import '../../stint_core/test/support/today_alignment.dart';

Widget edition(
  StintRepository repo, {
  StintLaunch launch = const StintLaunch(),
}) => StintFrosted(key: UniqueKey(), launch: launch, repository: repo);

void main() {
  const w = StintWords();

  // The shared painted check: the timer column beside the week's.
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: frostedLoadFonts,
    app: (launch, repository) =>
        StintFrosted(launch: launch, repository: repository),
  );

  void window(WidgetTester tester, double width, [double height = 960]) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, height);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    window(tester, 1440);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(edition(repo));
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
      for (var step = 0; step < 60; step++) {
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
    expect(find.byType(EditableText), findsWidgets);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    expect(find.text('Edit the walking route'), findsWidgets);
    await activateWithKeyboard(
      find.text(w.stopTimer),
      LogicalKeyboardKey.space,
    );
    expect(repo.snapshot.timer, isNull);
    expect(repo.snapshot.entries.length, 22);
    expect(find.text(w.chooseTask), findsOneWidget);
    // Stopped, the picker holds the plan's first open task; another is
    // chosen by typing, and the act starts the one chosen.
    final field = find.descendant(
      of: find.byKey(const ValueKey('today-timer-choice')),
      matching: find.byType(EditableText),
    );
    expect(
      tester.widget<EditableText>(field).controller.text,
      'Proof the studio map',
    );
    await tester.tap(field);
    await tester.enterText(field, 'Edit the walking');
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await press(w.startTimer);
    expect(repo.snapshot.timer?.taskId, 'ST-102');

    final row = find.byKey(const ValueKey('plan-ST-102'));
    await tester.ensureVisible(row);
    // The row's one spoken node: its title and project.
    final node = find
        .bySemanticsLabel(RegExp('^Edit the walking route, Field guide'))
        .first;
    await tester.tap(
      find.descendant(of: row, matching: find.text('Edit the walking route')),
    );
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isTrue,
    );
    expect(
      tester.getSemantics(node),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    await activateWithKeyboard(node, LogicalKeyboardKey.space);
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today keeps one grid at every width, in either direction', (
    tester,
  ) async {
    await tester.runAsync(frostedLoadFonts);
    for (final ar in [false, true]) {
      for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
        window(tester, width, 4000);
        await tester.pumpWidget(
          edition(StintRepository(), launch: StintLaunch(language: ar ? StintLanguage.ar : StintLanguage.en)),
        );
        await tester.pumpAndSettle();
        checkGrid(tester, width: width, rtl: ar);
        expect(tester.takeException(), isNull);
      }
    }
  });

  testWidgets('a block added by stopping shows whole, the hero row even', (
    tester,
  ) async {
    window(tester, 1440, 2400);
    final repo = StintRepository(clock: () => studyMorning);
    await tester.pumpWidget(edition(repo));
    await tester.pumpAndSettle();
    final before = tester.getRect(find.byKey(const ValueKey('today-blocks')));
    await tester.tap(find.text(w.stopTimer));
    await tester.pumpAndSettle();
    final blocks = tester.getRect(find.byKey(const ValueKey('today-blocks')));
    final last = tester.getRect(
      find.byKey(const ValueKey('today-blocks-lead-2')),
    );
    expect(blocks.height, greaterThan(before.height));
    expect(last.bottom, lessThan(blocks.bottom));
    final timer = tester.getRect(
      find.byKey(const ValueKey('today-timer-card')),
    );
    final week = tester.getRect(find.byKey(const ValueKey('today-week')));
    expect(timer.top, closeTo(week.top, 1));
    expect(timer.bottom, closeTo(week.bottom, 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today reads at twice the text size on a phone', (tester) async {
    window(tester, 390, 8000);
    for (final ar in [false, true]) {
      await tester.pumpWidget(
        edition(StintRepository(), launch: StintLaunch(language: ar ? StintLanguage.ar : StintLanguage.en, scale: 2)),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      checkLists(tester, rtl: ar);
    }
  });
}

Iterable<String> keysWith(WidgetTester tester, String prefix) => tester
    .allWidgets
    .map((v) => v.key)
    .whereType<ValueKey<String>>()
    .map((k) => k.value)
    .where((k) => k.startsWith(prefix))
    .toSet();

Rect rectOf(WidgetTester tester, String key) =>
    tester.getRect(find.byKey(ValueKey(key)));

/// Every list's leading column shares one centre, and every list stands that
/// centre the same distance in from its card's start edge.
void checkLists(WidgetTester tester, {required bool rtl}) {
  final insets = <String, double>{};
  for (final list in ['plan', 'later', 'team', 'blocks', 'feed']) {
    final card = rectOf(
      tester,
      list == 'feed' ? 'today-activity' : 'today-$list',
    );
    // A plan check's key stands on the kit's whole target (the painted
    // check measures its face); the layout check keeps the 'all' row.
    final leads = list == 'plan'
        ? ['today-plan-lead-all']
        : keysWith(tester, 'today-$list-lead-').toList();
    expect(leads, isNotEmpty, reason: list);
    final centres = [for (final k in leads) rectOf(tester, k).center.dx];
    for (final c in centres) {
      expect(c, closeTo(centres.first, 1), reason: '$list leading column');
    }
    insets[list] = rtl ? card.right - centres.first : centres.first - card.left;
  }
  for (final inset in insets.values) {
    expect(inset, closeTo(insets.values.first, 1), reason: '$insets');
  }
}

void checkGrid(
  WidgetTester tester, {
  required double width,
  required bool rtl,
}) {
  final why = '$width ${rtl ? "rtl" : "ltr"}';
  checkLists(tester, rtl: rtl);

  // The hero: the timer beside the week from a tablet up, the reading's
  // well on the figures' top line and the acts on the chart's foot.
  final timer = rectOf(tester, 'today-timer-card');
  final week = rectOf(tester, 'today-week');
  final well = rectOf(tester, 'today-timer-well');
  final first = rectOf(tester, 'today-action-first');
  final last = rectOf(tester, 'today-action-last');
  final acts = first.expandToInclude(last);
  final tasks = rectOf(tester, 'today-stat-tasks');
  final hours = rectOf(tester, 'today-stat-hours');
  final chart = rectOf(tester, 'today-chart');
  if (width >= 600) {
    expect(timer.top, closeTo(week.top, 1), reason: why);
    expect(timer.bottom, closeTo(week.bottom, 1), reason: why);
    expect(well.top, closeTo(tasks.top, 1), reason: why);
    expect(acts.bottom, closeTo(chart.bottom, 1), reason: why);
    expect(rtl ? week.right < timer.left : week.left > timer.right, isTrue);
  } else {
    expect(week.top, greaterThan(timer.bottom), reason: why);
  }
  expect(acts.left, closeTo(well.left, 1), reason: why);
  expect(acts.right, closeTo(well.right, 1), reason: why);
  expect(first.width, closeTo(last.width, 1), reason: why);

  // The stat tiles: equal, and together as wide as the chart.
  if ((tasks.top - hours.top).abs() < 1) {
    expect(tasks.width, closeTo(hours.width, 1), reason: why);
    final both = tasks.expandToInclude(hours);
    expect(both.left, closeTo(chart.left, 1), reason: why);
    expect(both.right, closeTo(chart.right, 1), reason: why);
    expect(rtl ? tasks.right : tasks.left, rtl ? both.right : both.left);
  }

  // Seven days, each name centred under its own slot, Monday on the start
  // side.
  double? previous;
  for (var i = 0; i < 7; i++) {
    final slot = rectOf(tester, 'today-day-slot-$i');
    final label = rectOf(tester, 'today-day-label-$i');
    expect(label.center.dx, closeTo(slot.center.dx, 1), reason: '$why day $i');
    expect(label.top, greaterThanOrEqualTo(slot.bottom), reason: why);
    if (previous != null) {
      expect(
        rtl ? slot.center.dx < previous : slot.center.dx > previous,
        isTrue,
      );
    }
    previous = slot.center.dx;
  }
  final mon = rectOf(tester, 'today-day-slot-0');
  final sun = rectOf(tester, 'today-day-slot-6');
  final inStart = rtl ? chart.right - mon.right : mon.left - chart.left;
  final inEnd = rtl ? sun.left - chart.left : chart.right - sun.right;
  expect(inStart, closeTo(inEnd, 1), reason: why);
}
