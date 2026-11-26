import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart'
    show
        MinimalBarChart,
        MinimalButton,
        MinimalDialog,
        MinimalDatePicker,
        MinimalListTile,
        MinimalLocalizations,
        MinimalMenu,
        MinimalPressable,
        MinimalSearchField;
import 'package:stint_core/stint_core.dart';
import 'package:stint_minimal/stint_minimal.dart';

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
      StintMinimal(
        key: UniqueKey(),
        launch: options,
        repository: repo ?? StintRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

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
            if (ar && page == 'detail') {
              final calendar = find
                  .descendant(
                    of: find.byType(MinimalDatePicker),
                    matching: find.byType(MinimalPressable),
                  )
                  .first;
              final controls = MinimalLocalizations.of(
                tester.element(calendar),
              );
              expect(controls.months[10], 'نوفمبر');
              expect(controls.increase('التقدير'), 'زيادة التقدير');
              expect(controls.hour, isNot('Hour'));
              await tester.ensureVisible(calendar);
              await tester.tap(calendar);
              await tester.pumpAndSettle();
              expect(find.text(controls.monthYear(studyToday)), findsWidgets);
            }
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

  testWidgets('desktop task rows align with search and filters', (
    tester,
  ) async {
    window(tester, 1440);
    for (final arabic in [false, true]) {
      final words = StintWords(arabic ? StintLanguage.ar : StintLanguage.en);
      await launch(
        tester,
        StintLaunch(
          place: Place.tasks,
          language: arabic ? StintLanguage.ar : StintLanguage.en,
        ),
      );
      final field = tester.getRect(find.byType(MinimalSearchField));
      final filters = tester.getRect(
        find.widgetWithText(
          MinimalButton,
          '${words.filters} (${words.number(1)})',
        ),
      );
      final firstTask = seedTasks().first;
      final tile = find.widgetWithText(
        MinimalListTile,
        words.text(firstTask.title),
      );
      final leading = tester.getRect(
        find.byWidget(tester.widget<MinimalListTile>(tile).leading!),
      );
      final menu = tester.getRect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MinimalMenu &&
              widget.label == '${words.actions}${words.dot}${firstTask.id}',
        ),
      );
      expect(
        arabic ? filters.right : filters.left,
        arabic ? field.right : field.left,
      );
      expect(
        arabic ? leading.right : leading.left,
        closeTo(arabic ? field.right : field.left, 1),
      );
      expect(
        arabic ? menu.left : menu.right,
        arabic ? field.left : field.right,
      );
    }
  });

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
          .widgetWithText(MinimalButton, words.addEntry)
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
  Future<void> askToLeave(WidgetTester tester, {StintRepository? repo}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await launch(
      tester,
      const StintLaunch(place: Place.tasks, detail: true),
      repo: repo,
    );
    final title = find.byWidgetPredicate(
      (v) => v is EditableText && v.controller.text == 'Proof the studio map',
    );
    await tester.enterText(title, 'Walk the studio map');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
  }

  testWidgets('Unsaved changes asks Cancel, Discard or Save changes', (
    tester,
  ) async {
    const w = StintWords();
    final repo = StintRepository();
    await askToLeave(tester, repo: repo);
    expect(
      find.byWidgetPredicate(
        (v) =>
            v is MinimalDialog &&
            v.actions?.map((a) => a.label).join(',') ==
                '${w.cancel},${w.discard},${w.save}' &&
            v.actions![1].isDestructiveAction &&
            v.actions![2].isDefaultAction,
      ),
      findsOneWidget,
    );
    await tester.tap(find.text(w.cancel).last);
    await tester.pumpAndSettle();
    expect(find.text(w.leaveMessage), findsNothing);
    expect(
      find.byWidgetPredicate(
        (v) => v is EditableText && v.controller.text == 'Walk the studio map',
      ),
      findsOneWidget,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text(w.save).last);
    await tester.pumpAndSettle();
    expect(find.text(w.leaveMessage), findsNothing);
    expect(repo.snapshot.tasks.first.title.$1, 'Walk the studio map');
  });

  testWidgets('Time\'s week chart reads in hours and minutes, never decimals', (
    tester,
  ) async {
    window(tester, 390);
    await launch(tester, const StintLaunch(place: Place.time));
    final chart = find.byType(MinimalBarChart);
    expect(chart, findsOneWidget);
    String reading(double hours) =>
        tester.widget<MinimalBarChart>(chart).format!(hours);
    expect(reading(2.75), '2h 45m');
    expect(reading(4), '4h');
    expect(reading(0.5), '30m');
  });
}
