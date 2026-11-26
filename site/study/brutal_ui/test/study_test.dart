import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_brutal/stint_brutal.dart';

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
      StintBrutal(
        key: UniqueKey(),
        launch: options,
        repository: repo ?? StintRepository(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in [390.0, 1440.0]) {
    for (final ar in [false, true]) {
      testWidgets('All five places at $width, Arabic=$ar, text 2x', (
        tester,
      ) async {
        window(tester, width);
        for (final page in ['today', 'tasks', 'detail', 'time', 'settings']) {
          final w = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
          final launchOptions = StintLaunch.fromUri(
            Uri.parse(
              'https://study.invalid/?page=$page&theme=${ar ? "night" : "day"}&dir=${ar ? "rtl" : "ltr"}&scale=2',
            ),
          );
          await launch(tester, launchOptions);
          expect(tester.takeException(), isNull, reason: page);
          expect(find.byType(RawAdaptiveShell), findsOneWidget);
          if (page == 'time') {
            Finder arrow(String label) => find.byWidgetPredicate(
              (v) => v is BrutalIconButton && v.tooltip == label,
            );
            final prev = tester.getRect(arrow(w.previousWeek)),
                next = tester.getRect(arrow(w.nextWeek));
            final monday = mondayOf(studyToday);
            Finder visibleRange(DateTime start) => find.text(
              w
                  .weekRange(start, compact: width == 390)
                  .split(' – ')
                  .map((date) => date.replaceAll(' ', '\u00a0'))
                  .join(' – '),
            );
            final range = visibleRange(monday);
            void checkRange(Finder range, DateTime start) {
              final text = tester.widget<Text>(range);
              expect(text.semanticsLabel, w.weekRange(start));
              final paragraph = tester.renderObject<RenderParagraph>(
                find.descendant(of: range, matching: find.byType(RichText)),
              );
              expect(paragraph.didExceedMaxLines, isFalse);
              expect(text.overflow, isNot(TextOverflow.ellipsis));
            }

            checkRange(range, monday);
            expect(tester.getCenter(range).dy, prev.center.dy);
            expect(prev.center.dy, next.center.dy);
            expect(prev.size, next.size);
            expect(prev.width, greaterThanOrEqualTo(40));
            expect(prev.center.dx < next.center.dx, !ar);
            await tester.tap(arrow(w.nextWeek));
            await tester.pumpAndSettle();
            expect(range, findsNothing);
            await tester.tap(arrow(w.nextWeek));
            await tester.pumpAndSettle();
            final nextMonth = addDays(monday, 14);
            checkRange(visibleRange(nextMonth), nextMonth);
          }
          if (page == 'tasks') {
            final search = tester.getRect(find.byType(BrutalSearchField)),
                rows = tester.getRect(find.byKey(const ValueKey('task-rows')));
            expect(rows.left, search.left);
            expect(rows.right, search.right);
          }
        }
      });
    }
  }

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
      final formButton = find.widgetWithText(BrutalButton, words.addEntry).last;
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
  testWidgets(
    'filters intersect, sort, row actions, selection and undo preserve the original tasks',
    (tester) async {
      window(tester, 1440);
      final repo = StintRepository();
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      Future<void> tap(Finder finder) async {
        await tester.ensureVisible(finder.first);
        await tester.tap(finder.first);
        await tester.pumpAndSettle();
      }

      Finder menu(String label) => find.byWidgetPredicate(
        (v) => v is BrutalIconButton && v.tooltip == label,
      );
      await tap(find.widgetWithText(BrutalButton, 'Filters (1)'));
      Future<void> choose(String field, String option) async {
        await tap(
          find.byWidgetPredicate(
            (v) => v is BrutalSelect && v.labelText == field,
          ),
        );
        await tap(find.text(option).hitTestable().last);
      }

      await choose('Project', 'Open studio');
      await choose('Assignee', 'Maya Reed');
      await choose('Sort by', 'Title');
      await tap(find.widgetWithText(BrutalButton, 'Apply'));
      expect(find.text('Proof the studio map'), findsOneWidget);
      expect(find.text('Edit the walking route'), findsNothing);
      await tap(find.widgetWithText(BrutalButton, 'Filters (3)'));
      await tap(find.widgetWithText(BrutalButton, 'Clear filters'));
      await tap(menu('Task actions · ST-101'));
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
      await tap(menu('Task actions · ST-101'));
      await tap(find.text('Move to project'));
      await tap(find.text('Workshop series').hitTestable().last);
      expect(repo.snapshot.tasks.first.project, 'workshops');
      await tap(menu('Task actions · ST-101'));
      await tap(find.text('Mark done'));
      expect(repo.snapshot.tasks.first.done, isTrue);
      await tap(find.widgetWithText(BrutalButton, 'Select tasks'));
      for (final title in ['Proof the studio map', 'Edit the walking route']) {
        await tap(
          find.byWidgetPredicate(
            (v) => v is BrutalCheckbox && v.semanticLabel == title,
          ),
        );
      }
      expect(find.text('2 selected'), findsOneWidget);
      await tap(menu('Task actions'));
      await tap(find.text('Delete'));
      expect(repo.snapshot.tasks.length, 38);
      await tap(find.text('Undo'));
      expect(repo.snapshot.tasks.length, 40);
      expect(
        repo.snapshot.tasks.where((t) => t.id == 'ST-101').single.project,
        'workshops',
      );
    },
  );

  testWidgets(
    'task controls validate and save edits to the selected teammate, date and reminder',
    (tester) async {
      window(tester, 390);
      final repo = StintRepository();
      await launch(
        tester,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f.first);
        await tester.tap(f.first);
        await tester.pumpAndSettle();
      }

      Finder field(String label) => find.descendant(
        of: find.byWidgetPredicate(
          (v) => v is BrutalTextField && v.labelText == label,
        ),
        matching: find.byType(EditableText),
      );
      final title = field('Title');
      await tester.enterText(title, '');
      await tester.pumpAndSettle();
      await tap(find.widgetWithText(BrutalButton, 'Save changes'));
      expect(find.text(const StintWords().titleError), findsWidgets);
      await tester.ensureVisible(title);
      await tester.enterText(title, 'Studio field map');
      await tester.pumpAndSettle();
      final assignee = find.descendant(
        // Assignee: Project's combobox comes first.
        of: find.byType(BrutalCombobox<String>).last,
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(assignee);
      await tester.enterText(assignee, 'Noor');
      await tester.pumpAndSettle();
      await tap(find.text('Noor Haddad').hitTestable().last);
      await tap(find.byType(BrutalDatePicker));
      expect(find.byType(BrutalCalendar), findsOneWidget);
      await tap(find.text('24').hitTestable().last);
      await tap(find.text('Reminder time').last);
      expect(find.byType(BrutalWheelPicker<int>), findsNWidgets(2));
      await tap(find.widgetWithText(BrutalButton, 'Done'));
      await tap(find.widgetWithText(BrutalButton, 'Save changes'));
      final saved = repo.snapshot.tasks.first;
      expect(saved.title.$1, 'Studio field map');
      expect(saved.assignee, 'noor');
      expect(saved.due, DateTime(2026, 11, 24));
    },
  );

  testWidgets(
    'load failure, empty studio and settings use their native actions',
    (tester) async {
      window(tester, 800);
      await launch(
        tester,
        const StintLaunch(place: Place.tasks),
        repo: StintRepository(failNext: true),
      );
      expect(find.text(const StintWords().loadError), findsOneWidget);
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Proof the studio map'), findsOneWidget);
      await launch(
        tester,
        const StintLaunch(),
        repo: StintRepository(empty: true),
      );
      expect(find.text(const StintWords().noTasks), findsOneWidget);
      await launch(tester, const StintLaunch(place: Place.settings));
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f.first);
        await tester.tap(f.first);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Night'));
      expect(
        tester.element(find.byType(BrutalAppBar)).brutalTheme.brightness,
        Brightness.dark,
      );
      // Four languages: a select, opened from its English value.
      await tap(find.text('English'));
      await tap(find.text('العربية'));
      expect(
        find.text(const StintWords(StintLanguage.ar).appearance),
        findsWidgets,
      );
      final signout = find.widgetWithText(
        BrutalButton,
        const StintWords(StintLanguage.ar).signOut,
      );
      await tap(signout);
      await tap(find.text(const StintWords(StintLanguage.ar).cancel));
      expect(find.byType(BrutalDialog), findsNothing);
      await tap(signout);
      await tap(
        find.widgetWithText(
          BrutalDialogAction,
          const StintWords(StintLanguage.ar).signOut,
        ),
      );
      expect(
        find.text(const StintWords(StintLanguage.ar).signedOut),
        findsOneWidget,
      );
      await tap(find.text(const StintWords(StintLanguage.ar).returnToStudio));
      expect(find.byType(RawAdaptiveShell), findsOneWidget);
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

  // Three actions, as the other editions ask: Cancel stays on the task,
  // Discard throws the edits away, Save changes keeps them.
  testWidgets('Unsaved changes offers Cancel, Discard and Save changes', (
    tester,
  ) async {
    const w = StintWords();
    await askToLeave(tester);
    final actions = tester
        .widget<BrutalDialog>(find.byType(BrutalDialog))
        .actions
        .cast<BrutalDialogAction>();
    expect(actions.map((a) => a.label), [w.cancel, w.discard, w.save]);
    expect(actions.elementAt(1).isDestructiveAction, isTrue);
    await tester.tap(find.text(w.cancel).last);
    await tester.pumpAndSettle();
    expect(find.text(w.dirty), findsNothing);
    expect(
      find.byWidgetPredicate(
        (v) => v is EditableText && v.controller.text == 'Walk the studio map',
      ),
      findsOneWidget,
    );
  });

  testWidgets('Time\'s week chart reads in hours and minutes, never decimals', (
    tester,
  ) async {
    window(tester, 390);
    await launch(tester, const StintLaunch(place: Place.time));
    final chart = find.byType(BrutalBarChart);
    expect(chart, findsOneWidget);
    String reading(double hours) => tester
        .widget<BrutalBarChart>(chart)
        .valueFormat
        .format(hours, RawWidgetsLocalizations.of(tester.element(chart)));
    expect(reading(2.75), '2h 45m');
    expect(reading(4), '4h');
    expect(reading(0.5), '30m');
  });
}
