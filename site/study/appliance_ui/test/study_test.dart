import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:appliance_ui/appliance_ui.dart'
    show
        ApplianceButton,
        ApplianceIconButton,
        AppliancePanel,
        ApplianceTheme,
        ApplianceThemeData,
        RawPalette,
        applianceLoadFonts;
import 'package:stint_core/stint_core.dart';
import 'package:stint_appliance/stint_appliance.dart';

void main() {
  void window(WidgetTester tester, double width) {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 900);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> launch(
    WidgetTester tester,
    StintLaunch options, {
    StintRepository? repo,
  }) async {
    await tester.pumpWidget(
      StintAppliance(
        key: UniqueKey(),
        launch: options,
        repository: repo ?? StintRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Today aligns the week readings above a daily chart at each width and scale',
    (tester) async {
      await tester.runAsync(applianceLoadFonts);
      for (final width in [320.0, 390.0, 768.0, 1440.0]) {
        window(tester, width);
        for (final arabic in [false, true]) {
          final words = StintWords(
            arabic ? StintLanguage.ar : StintLanguage.en,
          );
          for (final scale in [1.0, 2.0]) {
            await launch(
              tester,
              StintLaunch(
                language: arabic ? StintLanguage.ar : StintLanguage.en,
                scale: scale,
              ),
            );
            final chart = find.byKey(const ValueKey('today-chart'));
            await tester.ensureVisible(chart);
            await tester.pumpAndSettle();
            final panel = tester.getRect(
              find.ancestor(of: chart, matching: find.byType(AppliancePanel)),
            );
            final plot = tester.getRect(chart);
            final tasks = tester.getRect(find.text(words.openTasks));
            final hours = tester.getRect(find.text(words.hoursThisWeek));
            final count = tester.getRect(find.text(words.number(30)));
            final label = '${words.hoursThisWeek}, ${words.duration(945)}';
            final reading = find.byWidgetPredicate(
              (v) => v is Text && v.semanticsLabel == label,
            );
            final amount = tester.getRect(reading);
            expect(find.bySemanticsLabel(label), findsOneWidget);
            expect(amount.height, greaterThanOrEqualTo(count.height - 1));
            expect(tasks.top, closeTo(hours.top, 1));
            expect(amount.top, closeTo(count.top, 1));
            expect(plot.top, greaterThan(amount.bottom));
            expect(plot.left, greaterThan(panel.left));
            expect(plot.right, lessThan(panel.right));
            double start(Rect r) => arabic ? r.right : r.left;
            expect(start(tasks), closeTo(start(count), 1));
            expect(start(hours), closeTo(start(amount), 1));
            expect(tester.widget<Text>(reading).data, words.duration(945));
            for (var i = 0; i < 7; i++) {
              expect(
                find.byKey(ValueKey('today-day-label-$i')),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
          }
        }
      }
    },
  );

  for (final width in [390.0, 1440.0]) {
    for (final ar in [false, true]) {
      testWidgets(
        'Five places at $width, ${ar ? "Arabic night 2x" : "English day"}',
        (tester) async {
          window(tester, width);
          for (final page in ['today', 'tasks', 'detail', 'time', 'settings']) {
            await launch(
              tester,
              StintLaunch.fromUri(
                Uri.parse(
                  'https://stint.example/?page=$page&theme=${ar ? "night" : "day"}&dir=${ar ? "rtl" : "ltr"}&scale=${ar ? 2 : 1}',
                ),
              ),
            );
            expect(tester.takeException(), isNull, reason: page);
            expect(find.byType(Directionality), findsWidgets);
            if (page == 'today' && width == 390) {
              final greeting = find.text(
                StintWords(ar ? StintLanguage.ar : StintLanguage.en).greeting,
              );
              expect(tester.getCenter(greeting).dy, lessThan(450));
              final nav = find
                  .bySemanticsLabel(
                    RegExp(ar ? 'اليوم.*١' : 'Today.*1', dotAll: true),
                  )
                  .first;
              expect(tester.getCenter(nav).dy, greaterThan(700));
            }
          }
        },
      );
    }
  }

  testWidgets(
    'phone week switcher keeps both keys at the touch floor beside the range at 2x',
    (tester) async {
      window(tester, 390);
      for (final arabic in [false, true]) {
        final words = StintWords(arabic ? StintLanguage.ar : StintLanguage.en);
        await launch(
          tester,
          StintLaunch(
            place: Place.time,
            scale: 2,
            language: arabic ? StintLanguage.ar : StintLanguage.en,
            compact: arabic,
          ),
        );
        Finder button(String label) => find.byWidgetPredicate(
          (widget) =>
              widget is ApplianceIconButton && widget.semanticLabel == label,
        );
        final previous = button(words.previousWeek),
            next = button(words.nextWeek);
        final week = mondayOf(studyToday);
        Finder range(DateTime start) =>
            find.text(words.weekRange(start, compact: true));
        final date = tester.getRect(range(week));
        expect(
          tester.renderObject<RenderParagraph>(range(week)).didExceedMaxLines,
          isFalse,
        );
        final before = tester.getRect(previous), after = tester.getRect(next);
        // Each key's target is the touch floor (40 x 40), as ui_core sets it.
        expect(before.size, const Size(40, 40));
        expect(after.size, const Size(40, 40));
        expect(before.center.dy, date.center.dy);
        expect(after.center.dy, date.center.dy);
        expect((arabic ? after : before).right, lessThanOrEqualTo(date.left));
        expect(
          (arabic ? before : after).left,
          greaterThanOrEqualTo(date.right),
        );
        await tester.tap(next);
        await tester.pumpAndSettle();
        expect(range(addDays(week, 7)), findsOneWidget);
        await tester.tap(next);
        await tester.pumpAndSettle();
        final spanningMonths = range(addDays(week, 14));
        expect(
          tester
              .renderObject<RenderParagraph>(spanningMonths)
              .didExceedMaxLines,
          isFalse,
        );
        await tester.tap(previous);
        await tester.pumpAndSettle();
        await tester.tap(previous);
        await tester.pumpAndSettle();
        expect(range(week), findsOneWidget);
      }
    },
  );

  testWidgets(
    'phone edit survives resize, keyboard save persists and a dirty departure asks first',
    (tester) async {
      window(tester, 390);
      final repo = StintRepository();
      await launch(
        tester,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      final title = find.byWidgetPredicate(
        (v) => v is EditableText && v.controller.text == 'Proof the studio map',
      );
      await tester.enterText(title, 'Hang the courtyard map');
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Discard'), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      expect(find.text('Discard'), findsNothing);
      tester.view.physicalSize = const Size(1440, 900);
      await tester.pumpAndSettle();
      final edited = find.byWidgetPredicate(
        (v) =>
            v is EditableText && v.controller.text == 'Hang the courtyard map',
      );
      expect(edited, findsOneWidget);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      expect(repo.snapshot.tasks.first.title.$1, 'Hang the courtyard map');
      await tester.enterText(edited, 'Unfinished');
      await tester.tap(find.text('Settings').first);
      await tester.pumpAndSettle();
      expect(find.text('Discard'), findsOneWidget);
      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(find.text(const StintWords().aboutDetail), findsWidgets);
      expect(repo.snapshot.tasks.first.title.$1, 'Hang the courtyard map');
    },
  );

  testWidgets(
    'a blank search result clears, the palette opens Time and an entry validates before it is saved',
    (tester) async {
      window(tester, 390);
      final repo = StintRepository();
      const words = StintWords();
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      final search = find.byType(EditableText).first;
      await tester.enterText(search, 'nonexistent task');
      await tester.pumpAndSettle();
      expect(find.text(words.noMatches), findsOneWidget);
      await tester.enterText(search, '');
      await tester.pumpAndSettle();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();
      final command = find.byType(EditableText).last;
      await tester.enterText(command, words.time);
      await tester.pumpAndSettle();
      final matchingTime = find.text(words.time).hitTestable();
      await tester.tap(matchingTime.last);
      await tester.pumpAndSettle();
      final add = find.text(words.addEntry);
      await tester.ensureVisible(add.first);
      await tester.tap(add.hitTestable().first);
      await tester.pumpAndSettle();
      final formButton = find
          .widgetWithText(ApplianceButton, words.addEntry)
          .last;
      await tester.ensureVisible(formButton);
      await tester.tap(formButton);
      await tester.pumpAndSettle();
      expect(find.text(words.noteError), findsWidgets);
      final note = find.byType(EditableText).last;
      await tester.ensureVisible(note);
      await tester.enterText(note, 'Prepare the worktable');
      await tester.pumpAndSettle();
      await tester.ensureVisible(formButton);
      await tester.tap(formButton);
      await tester.pumpAndSettle();
      expect(repo.snapshot.entries.length, 21);
      expect(repo.snapshot.entries.last.note.$1, 'Prepare the worktable');
    },
  );

  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'Unsaved changes keys stand in one row or one to a row at $width',
      (tester) async {
        window(tester, width);
        const w = StintWords();
        await launch(
          tester,
          const StintLaunch(place: Place.tasks, detail: true),
        );
        // The task's title (at 1440 the list's empty search comes first).
        final title = find.byWidgetPredicate(
          (e) => e is EditableText && e.controller.text.isNotEmpty,
        );
        await tester.enterText(title.first, 'A new title');
        await tester.pumpAndSettle();
        await tester.tap(
          width < 600
              ? find.bySemanticsLabel(w.back).hitTestable().first
              : find.text(w.today).hitTestable().first,
        );
        await tester.pumpAndSettle();
        expect(find.text(w.dirty), findsOneWidget);
        final keys = [
          for (final l in [w.cancel, w.discard, w.save])
            tester.getRect(find.widgetWithText(ApplianceButton, l).last),
        ];
        // The dialog's actions: all on one row, or one to a row, at one
        // height. A Wrap in the content put Cancel (a text key) and Discard
        // on one row at two heights and Save changes alone below them.
        final tops = keys.map((k) => k.top).toSet();
        expect(
          tops.length == 1 || tops.length == keys.length,
          isTrue,
          reason: '$keys',
        );
        expect(
          keys.map((k) => k.height).toSet(),
          hasLength(1),
          reason: '$keys',
        );
      },
    );
  }

  // Pick an Assignee and press Save: the list must not open again.
  // On the web the press focuses the key (the browser
  // focuses its semantics node, and its Focus takes the focus); the save
  // disables the key, and Flutter hands focus back to the combobox.
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'A pressed Save lets its focus go, not back to the list, at $width',
      (tester) async {
        window(tester, width);
        const w = StintWords();
        await launch(
          tester,
          const StintLaunch(place: Place.tasks, detail: true),
        );
        final field = find.text('Maya Reed').first;
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Noor Haddad').hitTestable().last);
        await tester.pumpAndSettle();
        expect(find.text('Sam Okafor').hitTestable(), findsNothing);
        // The web's press: the key takes the focus as it goes down.
        final save = find.text(w.save).last;
        await tester.ensureVisible(save);
        await tester.pumpAndSettle();
        // The key's own node is the nearest Focus over its label.
        Focus.of(tester.element(save)).requestFocus();
        await tester.pump();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.text('Sam Okafor').hitTestable(),
          findsNothing,
          reason: 'the Assignee list opened again',
        );
        final focus = FocusManager.instance.primaryFocus?.context;
        expect(
          focus?.widget is EditableText ||
              focus?.findAncestorWidgetOfExactType<EditableText>() != null,
          isFalse,
          reason: 'a field took the focus back',
        );
      },
    );
  }

  // Unsaved changes on a phone: the title edited, then the system back.
  Future<void> askToLeave(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await launch(tester, const StintLaunch(place: Place.tasks, detail: true));
    final title = find.byWidgetPredicate(
      (v) => v is EditableText && v.controller.text == 'Proof the studio map',
    );
    await tester.enterText(title, 'Walk the studio map');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('Unsaved changes sets Discard as the look sets a loss', (
    tester,
  ) async {
    const w = StintWords();
    await askToLeave(tester);
    expect(
      find.byWidgetPredicate(
        (v) =>
            v is ApplianceButton &&
            v.label == w.discard &&
            v.isDestructiveAction,
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Today\'s week bars are the Time chart\'s trace in every palette',
    (tester) async {
      window(tester, 390);
      for (final accent in ApplianceThemeData.presets) {
        for (final appearance in [Appearance.day, Appearance.night]) {
          await launch(
            tester,
            StintLaunch(accent: accent, appearance: appearance),
          );
          final bar = find.byKey(const ValueKey('today-day-slot-0'));
          await tester.ensureVisible(bar);
          await tester.pumpAndSettle();
          final colors = ApplianceTheme.of(tester.element(bar)).colors;
          // The package chart's trace: on the day's LCD the signal's tone
          // that stands 3:1 there, on the night's glass the signal.
          final trace = colors.display.computeLuminance() > 0.4
              ? RawPalette.readableTone(
                  colors.signal,
                  on: [colors.display],
                  ratio: 3,
                )
              : colors.signal;
          final face = tester.widget<DecoratedBox>(bar).decoration;
          expect(
            (face as BoxDecoration).color,
            trace,
            reason: '$accent, ${appearance.name}',
          );
        }
      }
    },
  );
}
