import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_terminal/stint_terminal.dart';
import 'package:terminal_ui/terminal_ui.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.centredStrip,
    loadFonts: termLoadFonts,
    app: (launch, repository) =>
        StintTerminal(launch: launch, repository: repository),
  );
  const w = StintWords();
  void window(WidgetTester tester, double width) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Finder button(String label) =>
      find.byWidgetPredicate((v) => v is TermButton && v.label == label);

  testWidgets('the live timer, picker and checklist update one workspace', (
    tester,
  ) async {
    window(tester, 1440);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintTerminal(repository: repo));
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
        // The box is named by its task, and while the timer runs on it,
        // says so.
        expect(
          find.bySemanticsLabel(
            RegExp(
              '^${RegExp.escape(w.text(task.title))}, '
              '.*${RegExp.escape(w.runningTimer)}\$',
            ),
          ),
          mine ? findsOneWidget : findsNothing,
          reason: '${task.id} spoken',
        );
      }
      expect(
        find.byKey(const ValueKey('today-plan-running')),
        id == null ? findsNothing : findsOneWidget,
      );
    }

    marked('ST-101');

    Future<void> press(Finder target) async {
      await tester.ensureVisible(target.first);
      await tester.tap(target.first);
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

    await activateWithKeyboard(button(w.switchTask), LogicalKeyboardKey.enter);
    expect(find.byType(EditableText), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(button(w.switchTask));
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    marked('ST-102');
    expect(repo.snapshot.entries.length, 21);
    await activateWithKeyboard(button(w.stopTimer), LogicalKeyboardKey.space);
    expect(repo.snapshot.timer, isNull);
    marked(null);
    expect(repo.snapshot.entries.length, 22);
    expect(button(w.stopTimer), findsNothing);
    expect(button(w.startTimer), findsOneWidget);
    await press(button(w.startTimer));
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    marked('ST-101');

    final row = find.descendant(
      of: find.byKey(const ValueKey('plan-ST-102')),
      matching: find.byType(TermCheckbox),
    );
    await press(row);
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

    // The keys written beside the timer's buttons work them: Alt+T stops,
    // then opens the choice of what to start.
    Future<void> alt(LogicalKeyboardKey key) async {
      await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
      await tester.sendKeyEvent(key);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
      await tester.pumpAndSettle();
    }

    await alt(LogicalKeyboardKey.keyT);
    expect(repo.snapshot.timer, isNull);
    await alt(LogicalKeyboardKey.keyT);
    expect(find.byType(EditableText), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Today keeps its grid at every width in either direction', (
    tester,
  ) async {
    for (final ar in [false, true]) {
      for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
        window(tester, width);
        await tester.pumpWidget(
          StintTerminal(
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
        final plan = rect('plan'), week = rect('week');
        if (width == 390) {
          expect(week.bottom, lessThanOrEqualTo(plan.top + .5), reason: why);
        } else {
          expect(plan.top, closeTo(week.top, 1), reason: why);
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

        // Every list's leading column: one start for each row's mark.
        void column(Finder marks, String list) {
          final xs = {
            for (var i = 0; i < marks.evaluate().length; i++)
              (start(tester.getRect(marks.at(i))) * 2).round(),
          };
          expect(xs, hasLength(1), reason: '$why, $list: $xs');
        }

        column(find.byType(TermCheckbox), 'plan');
        column(find.byType(TermAvatar), 'team');
        // On a desk every day carries its hours, in either language
        // (stacked where one line won't fit; the test's Arabic glyphs are
        // whole squares, wider than the web's, so Arabic is checked at 1440).
        if (width >= (ar ? 1440 : 1024)) {
          expect(
            find.byKey(const ValueKey('today-day-hours')),
            findsNWidgets(7),
            reason: why,
          );
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
