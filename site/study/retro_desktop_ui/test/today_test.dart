import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart'
    show RetroDesktopCheckbox, retroDesktopLoadFonts;
import 'package:stint_core/stint_core.dart';
import 'package:stint_retro_desktop/stint_retro_desktop.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    loadFonts: retroDesktopLoadFonts,
    app: (launch, repository) =>
        StintRetroDesktop(launch: launch, repository: repository),
  );
  const w = StintWords();
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
    await tester.pumpWidget(StintRetroDesktop(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    // The plan marks the task the timer runs on, and says so.
    void marked(String? id) {
      for (final task in ['ST-101', 'ST-102', 'ST-103', 'ST-104']) {
        expect(
          find.descendant(
            of: find.byKey(ValueKey('plan-$task')),
            matching: find.byKey(const ValueKey('today-plan-running')),
          ),
          task == id ? findsOneWidget : findsNothing,
          reason: '$task marked running',
        );
      }
    }

    marked('ST-101');
    expect(
      find.bySemanticsLabel(RegExp('Proof the studio map.*${w.runningTimer}')),
      findsOneWidget,
    );

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
      await tester.enterText(field, title);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await activateWithKeyboard(
      find.text(w.switchTask).first,
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
      find.text(w.stopTimer).first,
      LogicalKeyboardKey.space,
    );
    expect(repo.snapshot.timer, isNull);
    marked(null);
    expect(repo.snapshot.entries.length, 22);
    expect(find.text(w.stoppedTimer), findsWidgets);
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');

    final box = find.descendant(
      of: find.byKey(const ValueKey('plan-ST-102')),
      matching: find.byType(RetroDesktopCheckbox),
    );
    await tester.ensureVisible(box);
    await tester.tap(
      find.descendant(
        of: find.byKey(const ValueKey('plan-ST-102')),
        matching: find.text('Edit the walking route'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isTrue,
    );
    expect(
      tester.getSemantics(box),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    await activateWithKeyboard(box, LogicalKeyboardKey.space);
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isFalse,
    );
    await press(w.viewTasks);
    expect(find.text(w.search), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
