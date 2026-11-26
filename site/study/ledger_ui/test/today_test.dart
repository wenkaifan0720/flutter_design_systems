import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_ledger/stint_ledger.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.centredStrip,
    loadFonts: ledgerLoadFonts,
    app: (launch, repository) =>
        StintLedger(launch: launch, repository: repository),
  );
  const w = StintWords();
  void window(WidgetTester tester, double width) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    window(tester, 1440);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintLedger(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    // The plan marks the task the timer runs on, and says so: the mark
    // follows a switch and goes on stop.
    void marked(String? id) {
      for (final task in repo.snapshot.tasks.where(
        (t) => find.byKey(ValueKey('plan-${t.id}')).evaluate().isNotEmpty,
      )) {
        final mine = task.id == id;
        expect(
          find.descendant(
            of: find.byKey(ValueKey('plan-${task.id}')),
            matching: find.byKey(const ValueKey('today-plan-running')),
          ),
          mine ? findsOneWidget : findsNothing,
          reason: '${task.id} marked',
        );
        expect(
          tester.getSemantics(find.byKey(ValueKey('plan-${task.id}'))).label,
          mine ? contains(w.runningTimer) : isNot(contains(w.runningTimer)),
          reason: '${task.id} spoken',
        );
      }
      expect(
        find.byKey(const ValueKey('today-plan-running')),
        id == null ? findsNothing : findsOneWidget,
      );
    }

    marked('ST-101');

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
    expect(find.byType(EditableText), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    marked('ST-102');
    expect(repo.snapshot.entries.length, 21);
    await activateWithKeyboard(
      find.text(w.stopTimer),
      LogicalKeyboardKey.space,
    );
    expect(repo.snapshot.timer, isNull);
    marked(null);
    expect(repo.snapshot.entries.length, 22);
    expect(find.text(w.stoppedTimer.toUpperCase()), findsOneWidget);
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    marked('ST-101');

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
    await activateWithKeyboard(row, LogicalKeyboardKey.space);
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today keeps its grid at every width in either direction', (
    tester,
  ) async {
    for (final ar in [false, true]) {
      for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
        window(tester, width);
        await tester.pumpWidget(
          StintLedger(
            key: UniqueKey(),
            launch: StintLaunch(language: ar ? StintLanguage.ar : StintLanguage.en),
            repository: StintRepository(),
          ),
        );
        await tester.pumpAndSettle();
        final why = 'width $width, Arabic $ar';
        double start(Rect r) => ar ? r.right : r.left;
        Rect rect(String key) =>
            tester.getRect(find.byKey(ValueKey('today-$key')));
        // One column on a phone; from a tablet's page two, sharing a top
        // line: the plan heads the first (the team under it), the week the
        // second.
        final plan = rect('plan'), roster = rect('team'), week = rect('week');
        if (width == 390) {
          expect(week.bottom, lessThan(plan.top), reason: why);
          expect(plan.bottom, lessThan(roster.top), reason: why);
        } else {
          expect(
            ar ? week.right < plan.left : week.left > plan.right,
            isTrue,
            reason: why,
          );
          expect(plan.top, closeTo(week.top, 1), reason: why);
          expect(start(roster), closeTo(start(plan), 1), reason: why);
          expect(roster.top, greaterThan(plan.bottom), reason: why);
          expectHeadRows([
            for (final k in [
              'plan',
              'later',
              'team',
              'week',
              'blocks',
              'activity',
            ])
              rect(k),
          ], why);
        }
        expect(tester.takeException(), isNull, reason: why);
      }
    }
  });
}

/// Side by side from a tablet's width, two sections' heads share a line
/// or stand a line apart at the least, never a few pixels off.
void expectHeadRows(List<Rect> sections, String why) {
  for (final a in sections) {
    for (final b in sections) {
      if (!(a.right <= b.left || b.right <= a.left)) continue;
      final apart = (a.top - b.top).abs();
      expect(
        apart <= 1 || apart >= 24,
        isTrue,
        reason: '$why: heads $apart apart',
      );
    }
  }
}
