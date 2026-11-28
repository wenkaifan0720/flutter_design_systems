import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart'
    show
        Fluent2Button,
        Fluent2DatePicker,
        Fluent2Dialog,
        Fluent2FormField,
        Fluent2IconButton,
        Fluent2ProgressBar,
        Fluent2Select;
import 'package:stint_core/stint_core.dart';
import 'package:stint_fluent2_design/stint_fluent2_design.dart';

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
      StintFluent2Design(
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
    'the complete week range and both native keys stay together at 2x',
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
        Finder button(String label) => find.descendant(
          of: find.byWidgetPredicate(
            (widget) =>
                widget is RawTooltip && widget.semanticsTooltip == label,
          ),
          matching: find.byType(Fluent2IconButton),
        );
        final previous = button(words.previousWeek),
            next = button(words.nextWeek);
        final week = mondayOf(studyToday);
        Finder range(DateTime start) => find.bySemanticsLabel(
          '${words.shortDate(start)} – ${words.shortDate(addDays(start, 6))}',
        );
        final date = tester.getRect(range(week));
        final rangeText = tester.widget<Text>(
          find.descendant(of: range(week), matching: find.byType(Text)).first,
        );
        expect([
          words.weekRange(week),
          words.weekRange(week, compact: true),
        ], contains(rangeText.data));
        expect(rangeText.overflow, isNot(TextOverflow.ellipsis));
        final before = tester.getRect(previous), after = tester.getRect(next);
        expect(before.width, greaterThanOrEqualTo(32));
        expect(after.size, before.size);
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
      if (add.hitTestable().evaluate().isEmpty) {
        await Scrollable.ensureVisible(
          tester.element(add.first),
          alignment: 0.45,
        );
        await tester.pumpAndSettle();
      }
      await tester.tap(add.hitTestable().first);
      await tester.pumpAndSettle();
      final formButton = find
          .widgetWithText(Fluent2Button, words.addEntry)
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

  testWidgets(
    'weekday data and its spoken values follow the localized seven-day chart',
    (tester) async {
      window(tester, 390);
      final week = mondayOf(studyToday);
      for (final rtl in [false, true]) {
        final repo = StintRepository();
        final daily = List.filled(7, 0);
        for (final entry in repo.snapshot.entries.where(
          (e) => !e.date.isBefore(week) && e.date.isBefore(addDays(week, 7)),
        )) {
          daily[entry.date.weekday - 1] += entry.end - entry.start;
        }
        await launch(
          tester,
          StintLaunch(
            place: Place.time,
            language: rtl ? StintLanguage.ar : StintLanguage.en,
            scale: 2,
          ),
          repo: repo,
        );
        final words = StintWords(rtl ? StintLanguage.ar : StintLanguage.en);
        final meters = find.byType(Fluent2ProgressBar);
        expect(
          tester.widgetList<Fluent2ProgressBar>(meters).map((bar) => bar.value),
          [for (final value in daily) value.toDouble()],
        );
        for (var i = 0; i < daily.length; i++) {
          expect(find.text(words.weekdayShort(addDays(week, i))), findsWidgets);
          expect(find.text(words.duration(daily[i])), findsWidgets);
        }
        expect(find.bySemanticsLabel(RegExp(words.logged)), findsOneWidget);
        final range =
            '${StintWords(rtl ? StintLanguage.ar : StintLanguage.en).shortDate(week)} – ${StintWords(rtl ? StintLanguage.ar : StintLanguage.en).shortDate(addDays(week, 6))}';
        expect(find.bySemanticsLabel(range), findsOneWidget);
      }
    },
  );
  testWidgets(
    'filter choices intersect and bulk Undo restores exactly the selected rows',
    (tester) async {
      window(tester, 1440);
      final repo = StintRepository();
      const w = StintWords();
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap(find.text('Filters (1)'));
      Future<void> choose(String field, String value) async {
        await tap(
          find.byWidgetPredicate(
            (v) => v is Fluent2FormField && v.labelText == field,
          ),
        );
        await tap(find.text(value).hitTestable().last);
      }

      await choose(w.project, 'Open studio');
      await choose(w.assignee, 'Maya Reed');
      await choose(w.sort, w.title);
      await tap(find.text(w.apply));
      expect(find.text('2 tasks'), findsOneWidget);
      await tap(find.text(w.select));
      await tap(find.text('Label the display shelves'));
      await tap(find.text('Proof the studio map'));
      expect(find.text('2 selected'), findsOneWidget);
      await tap(
        find.byWidgetPredicate(
          (v) => v is Fluent2IconButton && v.semanticLabel == w.actions,
        ),
      );
      await tap(find.text(w.delete));
      expect(repo.snapshot.tasks, hasLength(38));
      await tap(find.text(w.undo));
      expect(repo.snapshot.tasks, hasLength(40));
      expect(find.text('Proof the studio map'), findsOneWidget);
      expect(find.text('Label the display shelves'), findsOneWidget);
    },
  );

  testWidgets(
    'a failed first read retries, a delayed read shows skeletons, and an empty day explains the list',
    (tester) async {
      window(tester, 390);
      const w = StintWords();
      final repo = StintRepository(failNext: true);
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      expect(find.text(w.loadError), findsOneWidget);
      repo.latency = const Duration(seconds: 3);
      await tester.tap(find.text('Try again'));
      await tester.pump();
      expect(find.bySemanticsLabel(w.loading), findsOneWidget);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Proof the studio map'), findsOneWidget);
      await launch(
        tester,
        const StintLaunch(),
        repo: StintRepository(empty: true),
      );
      expect(find.text(w.allClear), findsWidgets);
    },
  );

  testWidgets(
    'appearance and language are live and signing out can be cancelled or confirmed',
    (tester) async {
      window(tester, 1440);
      const w = StintWords(), ar = StintWords(StintLanguage.ar);
      await launch(tester, const StintLaunch(place: Place.settings));
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      Future<void> choose(String field, String value) async {
        final select = find.byWidgetPredicate(
          (v) => v is Fluent2FormField && v.labelText == field,
        );
        await tap(
          find
              .descendant(
                of: select,
                matching: find.byWidgetPredicate((v) => v is Fluent2Select),
              )
              .first,
        );
        await tap(find.text(value).hitTestable().last);
      }

      await choose(w.appearance, w.night);
      await choose(w.languageLabel, 'العربية');
      expect(find.text(ar.preferences), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(ar.preferences))),
        TextDirection.rtl,
      );
      await tap(find.text(ar.signOut));
      await tap(find.text(ar.cancel));
      expect(find.text(ar.preferences), findsOneWidget);
      await tap(find.text(ar.signOut));
      await tap(find.text(ar.signOut).hitTestable().last);
      expect(find.text(ar.signedOut), findsOneWidget);
      await tap(find.text(ar.returnToStudio));
      expect(find.text(ar.greeting), findsOneWidget);
    },
  );

  testWidgets(
    'the searchable assignee, calendar, priority and reminder save to the same task',
    (tester) async {
      window(tester, 390);
      const w = StintWords();
      final repo = StintRepository();
      await launch(
        tester,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      final person = find.byWidgetPredicate(
        (v) => v is EditableText && v.controller.text == 'Maya Reed',
      );
      await tester.ensureVisible(person);
      await tester.enterText(person, 'Noor');
      await tester.pumpAndSettle();
      expect(find.text('Noor Haddad'), findsOneWidget);
      await tester.tap(find.text('Noor Haddad').hitTestable().last);
      await tester.pumpAndSettle();
      Future<void> tap(Finder f) async {
        await tester.ensureVisible(f);
        await tester.tap(f);
        await tester.pumpAndSettle();
      }

      await tap(find.byType(Fluent2DatePicker));
      await tap(find.text('21').hitTestable().last);
      await tap(find.text(w.normal));
      await tap(find.text(w.reminder));
      await tap(find.text(w.save).last);
      final saved = repo.snapshot.tasks.first;
      expect(saved.assignee, 'noor');
      expect(saved.due, DateTime(2026, 11, 21));
      expect(saved.priority, Priority.normal);
      expect(saved.reminder, isFalse);
    },
  );

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
    // As written: a narrow phone stacks them, the primary on top.
    final actions = tester
        .widget<Fluent2Dialog>(find.byType(Fluent2Dialog))
        .actions
        .cast<Fluent2Button>();
    expect(actions.map((a) => a.label), [w.cancel, w.discard, w.save]);
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
}
