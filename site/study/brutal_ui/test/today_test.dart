import 'package:brutal_ui/brutal_ui.dart'
    show
        AnimatedBrutalSurface,
        BrutalFace,
        BrutalListTile,
        BrutalTheme,
        RawPalette,
        brutalLoadFonts;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_brutal/stint_brutal.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  setUpAll(() {
    final icons = FontLoader('packages/lucide_icons_flutter/Lucide')
      ..addFont(
        rootBundle.load('packages/lucide_icons_flutter/assets/lucide.ttf'),
      );
    return icons.load();
  });
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: brutalLoadFonts,
    app: (launch, repository) =>
        StintBrutal(launch: launch, repository: repository),
  );
  const w = StintWords();
  for (final appearance in [Appearance.day, Appearance.night]) {
    testWidgets(
      'timer focus contrasts with ink and paper by ${appearance.name}',
      (tester) async {
        await tester.pumpWidget(
          StintBrutal(
            launch: StintLaunch(appearance: appearance),
            repository: StintRepository(clock: () => studyMorning),
          ),
        );
        await tester.pumpAndSettle();
        BrutalFace stopFace() => tester
            .widget<AnimatedBrutalSurface>(
              find.descendant(
                of: find.byKey(const ValueKey('today-action-first')),
                matching: find.byType(AnimatedBrutalSurface),
              ),
            )
            .face;
        final resting = stopFace();
        for (
          var step = 0;
          step < 20 && stopFace().shadow == resting.shadow;
          step++
        ) {
          await tester.sendKeyEvent(LogicalKeyboardKey.tab);
          await tester.pumpAndSettle();
        }
        final focused = stopFace();
        // The face is the signal; focus moves it to the hard shadow, eased
        // for the paper behind it, in the same hue.
        expect(
          HSVColor.fromColor(focused.shadow).hue,
          closeTo(HSVColor.fromColor(resting.fill).hue, 6),
        );
        expect(
          RawPalette.contrastRatio(focused.shadow, resting.shadow),
          greaterThanOrEqualTo(3),
        );
        // Focus reads by two cues: the face flips from the signal to paper,
        // and the hard shadow turns from ink to the signal at 3:1 or more.
        final paper = BrutalTheme.of(
          tester.element(find.byKey(const ValueKey('today-action-first'))),
        ).colors.surface;
        expect(resting.fill, isNot(paper));
        expect(focused.fill, paper);
        expect(
          RawPalette.contrastRatio(resting.fill, resting.foreground),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          RawPalette.contrastRatio(focused.fill, focused.foreground),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }

  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintBrutal(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    // The plan marks the task the timer runs on, and says so: the mark
    // follows a switch and goes on stop.
    void marked(String? id) {
      final rows = [
        for (final v in tester.widgetList(
          find.byWidgetPredicate(
            (v) =>
                v.key is ValueKey<String> &&
                (v.key! as ValueKey<String>).value.startsWith('plan-'),
          ),
        ))
          (v.key! as ValueKey<String>).value,
      ];
      if (id != null) expect(rows, contains('plan-$id'));
      for (final key in rows) {
        final row = find.byKey(ValueKey(key)), mine = key == 'plan-$id';
        expect(
          find.descendant(
            of: row,
            matching: find.byKey(const ValueKey('today-plan-running')),
          ),
          mine ? findsOneWidget : findsNothing,
          reason: '$key marked',
        );
        expect(
          tester.getSemantics(row).getSemanticsData().label,
          mine ? contains(w.runningTimer) : isNot(contains(w.runningTimer)),
          reason: '$key spoken',
        );
      }
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
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('today-timer-well')),
        matching: find.text('Edit the walking route'),
      ),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('today-timer-digits')))
          .data,
      '1m',
    );
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    marked('ST-101');

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

  testWidgets('a later task opens its own editable record', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repo = StintRepository(clock: () => studyMorning);
    await tester.pumpWidget(StintBrutal(repository: repo));
    await tester.pumpAndSettle();
    // This title is also in the roster, attached to Inez. Open the actual
    // later-this-week row, then check the record brought up by that row.
    final later = find
        .ancestor(
          of: find.byKey(const ValueKey('today-later-lead-ST-104')),
          matching: find.byType(BrutalListTile),
        )
        .first;
    await tester.ensureVisible(later);
    await tester.tap(later);
    await tester.pumpAndSettle();
    final title = repo.snapshot.tasks
        .singleWhere((task) => task.id == 'ST-104')
        .title
        .$1;
    expect(
      find.byWidgetPredicate(
        (v) => v is EditableText && v.controller.text == title,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
