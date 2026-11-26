import 'package:terminal_ui/terminal_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_terminal/stint_terminal.dart';
import 'package:stint_core/stint_core.dart';

void main() {
  void window(WidgetTester t, double width) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, 900);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> show(
    WidgetTester t,
    StintLaunch launch, {
    StintRepository? repo,
  }) async {
    await t.pumpWidget(
      StintTerminal(
        key: UniqueKey(),
        launch: launch,
        repository: repo ?? StintRepository(),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> tap(WidgetTester t, Finder match) async {
    final f = match.first;
    await Scrollable.ensureVisible(f.evaluate().first, alignment: .5);
    await t.tap(f);
    await t.pumpAndSettle();
  }

  Finder text(String value) => find.text(value, findRichText: true);
  Finder field(String name) => find.descendant(
    of: find.byWidgetPredicate(
      (v) => v is TermTextField && v.labelText == name,
    ),
    matching: find.byType(EditableText),
  );
  Finder icon(String name) => find.byWidgetPredicate(
    (v) => v is TermIconButton && v.semanticLabel == name,
  );
  Future<void> key(WidgetTester t, LogicalKeyboardKey letter) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(letter);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  for (final width in [390.0, 1440.0]) {
    for (final rtl in [false, true]) {
      testWidgets('Five console windows at $width and 200%, Arabic=$rtl', (
        t,
      ) async {
        window(t, width);
        final w = StintWords(rtl ? StintLanguage.ar : StintLanguage.en);
        for (final page in ['today', 'tasks', 'detail', 'time', 'settings']) {
          await show(
            t,
            StintLaunch.fromUri(
              Uri.parse(
                'https://study.invalid/?page=$page&dir=${rtl ? 'rtl' : 'ltr'}&theme=${rtl ? 'night' : 'day'}&scale=2',
              ),
            ),
          );
          expect(t.takeException(), isNull, reason: page);
          expect(find.byType(RawAdaptiveShell), findsOneWidget);
          if (page == 'tasks') {
            final q = t.getRect(find.byKey(const ValueKey('search-tasks'))),
                rows = t.getRect(find.byKey(const ValueKey('task-rows')));
            expect(q.left, rows.left);
            expect(q.right, rows.right);
            expect(
              find.bySemanticsLabel(RegExp('^${RegExp.escape(w.settings)}')),
              findsWidgets,
            );
          }
          if (page == 'tasks') {
            final refresh = find.byWidgetPredicate(
              (widget) => widget is TermButton && widget.label == w.refresh,
            );
            expect(refresh.hitTestable(), findsOneWidget);
          }
          if (page == 'time') {
            final back = t.getRect(icon(w.previousWeek)),
                forward = t.getRect(icon(w.nextWeek));
            expect(
              t.widget<TermIconButton>(icon(w.previousWeek)).glyph,
              rtl ? '→' : '←',
            );
            expect(back.size, forward.size);
            expect(back.center.dy, forward.center.dy);
            expect(back.center.dx < forward.center.dx, !rtl);
            expect(back.width, greaterThanOrEqualTo(24));
            for (final offset in [0, 1, 2]) {
              final first = addDays(mondayOf(studyToday), offset * 7);
              final range = find.byWidgetPredicate(
                (v) => v is Text && v.semanticsLabel == w.weekRange(first),
              );
              expect(range, findsOneWidget);
              expect(
                t.getCenter(range).dy,
                t.getCenter(icon(w.previousWeek)).dy,
              );
              expect(t.getCenter(range).dy, t.getCenter(icon(w.nextWeek)).dy);
              // The keys stand beside the week they step, not at the page's
              // two edges.
              expect(
                (t.getCenter(icon(w.nextWeek)).dx -
                        t.getCenter(icon(w.previousWeek)).dx)
                    .abs(),
                lessThan(t.getSize(range).width + back.width + 48),
              );
              expect(t.widget<Text>(range).data!.contains('…'), false);
              final para = t.renderObject<RenderParagraph>(
                find.descendant(of: range, matching: find.byType(RichText)),
              );
              expect(para.didExceedMaxLines, isFalse);
              if (offset < 2) {
                await t.tap(icon(w.nextWeek));
                await t.pumpAndSettle();
              }
            }
          }
          if (page == 'detail') {
            expect(field(w.title), findsOneWidget);
            expect(
              find.byType(RawListDetail<String>, skipOffstage: false),
              findsOneWidget,
            );
          }
        }
      });
    }
  }
  testWidgets(
    'A draft survives native Back, dismissal and resize and saves with Control-S',
    (t) async {
      window(t, 390);
      final repo = StintRepository();
      await show(
        t,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      await t.enterText(field('Title'), '');
      await t.pumpAndSettle();
      await key(t, LogicalKeyboardKey.keyS);
      expect(find.byType(TermBanner), findsOneWidget);
      expect(text(const StintWords().titleError), findsWidgets);
      final titleInput = t.state(field('Title'));
      await t.enterText(field('Title'), 'R');
      await t.pumpAndSettle();
      expect(t.state(field('Title')), same(titleInput));
      await t.enterText(field('Title'), 'Rehang the studio map');
      await t.pumpAndSettle();
      await t.binding.handlePopRoute();
      await t.pumpAndSettle();
      expect(text('Discard'), findsOneWidget);
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      t.view.physicalSize = const Size(1440, 900);
      await t.pumpAndSettle();
      expect(
        t.widget<EditableText>(field('Title')).controller.text,
        'Rehang the studio map',
      );
      await tap(t, find.byType(TermDatePicker));
      expect(find.byType(TermCalendar), findsOneWidget);
      await tap(t, find.text('24').hitTestable().last);
      final reminder = find.descendant(
        of: find.byWidgetPredicate(
          (v) => v is TermTimeField && v.labelText == 'Reminder time',
        ),
        matching: find.byType(EditableText),
      );
      await t.enterText(reminder, '10:15');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      await key(t, LogicalKeyboardKey.keyS);
      expect(repo.snapshot.tasks.first.reminderMinute, 10 * 60 + 15);
      expect(repo.snapshot.tasks.first.title.$1, 'Rehang the studio map');
      expect(repo.snapshot.tasks.first.due, DateTime(2026, 11, 24));
      await t.enterText(field('Title'), 'Discard this');
      await t.pumpAndSettle();
      await tap(t, find.bySemanticsLabel(RegExp('^Settings')).first);
      await tap(t, text('Discard'));
      expect(repo.snapshot.tasks.first.title.$1, 'Rehang the studio map');
    },
  );
  testWidgets('Search, keyboard commands, time-entry errors and saved totals', (
    t,
  ) async {
    window(t, 390);
    final repo = StintRepository();
    await show(t, const StintLaunch(place: Place.tasks), repo: repo);
    await t.enterText(field('Search tasks'), 'no matching records');
    await t.pumpAndSettle();
    expect(text('No matching tasks'), findsOneWidget);
    await tap(t, text('Clear filters'));
    await tap(t, field('Search tasks'));
    await key(t, LogicalKeyboardKey.keyK);
    expect(find.byType(TermCommandPalette), findsOneWidget);
    await t.enterText(find.byType(EditableText).last, 'Time');
    await t.pumpAndSettle();
    await tap(t, find.text('Time').hitTestable().last);
    await tap(t, find.widgetWithText(TermButton, 'Add entry'));
    expect(field('Work note'), findsOneWidget);
    await tap(t, find.widgetWithText(TermButton, 'Add entry').last);
    expect(find.byType(TermBanner), findsOneWidget);
    final noteInput = t.state(field('Work note'));
    await t.enterText(field('Work note'), 'L');
    await t.pumpAndSettle();
    expect(t.state(field('Work note')), same(noteInput));
    await t.enterText(field('Work note'), 'Light the entry');
    await t.pumpAndSettle();
    final submit = find.widgetWithText(TermButton, 'Add entry').last;
    final beforeBlur = t.getRect(submit);
    await t.sendKeyEvent(LogicalKeyboardKey.tab);
    await t.pumpAndSettle();
    expect(t.getRect(submit), beforeBlur);
    await tap(t, submit);
    expect(repo.snapshot.entries.last.note.$1, 'Light the entry');
    expect(text('16h 45m'), findsOneWidget);
  });
  testWidgets('Intersection, sort and bulk delete preserve the undo batch', (
    t,
  ) async {
    window(t, 1440);
    final repo = StintRepository();
    await show(t, const StintLaunch(place: Place.tasks), repo: repo);
    await tap(t, text('Filters (1)'));
    for (final (name, choice) in [
      ('Project', 'Open studio'),
      ('Assignee', 'Maya Reed'),
      ('Sort by', 'Title'),
    ]) {
      await tap(
        t,
        find.byWidgetPredicate((v) => v is TermSelect && v.labelText == name),
      );
      await tap(t, find.text(choice).hitTestable().last);
    }
    await tap(t, text('Apply'));
    expect(
      find.byWidgetPredicate((v) => v is TermPane && v.title == '2 tasks'),
      findsOneWidget,
    );
    expect(text('Edit the walking route'), findsNothing);
    await tap(t, text('Filters (3)'));
    await tap(t, text('Clear filters'));
    await tap(t, text('Select tasks'));
    await tap(t, find.bySemanticsLabel('Proof the studio map').first);
    await tap(t, find.bySemanticsLabel('Edit the walking route').first);
    expect(text('2 selected'), findsOneWidget);
    await tap(t, icon('Task actions'));
    await tap(t, text('Delete'));
    expect(repo.snapshot.tasks.length, 38);
    await tap(t, text('Undo'));
    expect(repo.snapshot.tasks.length, 40);
  });
  testWidgets('Tablet rail, retry, empty overview and localized sign-out', (
    t,
  ) async {
    window(t, 800);
    await show(
      t,
      const StintLaunch(place: Place.tasks),
      repo: StintRepository(failNext: true),
    );
    expect(
      t.widget<RawAdaptiveShell>(find.byType(RawAdaptiveShell)).mode,
      RawNavigationMode.rail,
    );
    await tap(t, text('Try again'));
    expect(text('Proof the studio map'), findsWidgets);
    await show(t, const StintLaunch(), repo: StintRepository(empty: true));
    expect(text(const StintWords().noTasksToday), findsOneWidget);
    await show(t, const StintLaunch(place: Place.settings));
    await tap(
      t,
      find.byWidgetPredicate((v) => v is TermSelect && v.labelText == 'Theme'),
    );
    await tap(t, find.text('Night').hitTestable().last);
    await tap(
      t,
      find.byWidgetPredicate(
        (v) => v is TermSelect && v.labelText == 'Language',
      ),
    );
    await tap(t, find.text('العربية').hitTestable().last);
    const ar = StintWords(StintLanguage.ar);
    await tap(
      t,
      find.byWidgetPredicate((v) => v is TermButton && v.label == ar.signOut),
    );
    await tap(
      t,
      find.byWidgetPredicate((v) => v is TermButton && v.label == ar.cancel),
    );
    await tap(
      t,
      find.byWidgetPredicate((v) => v is TermButton && v.label == ar.signOut),
    );
    expect(find.textContaining('proceed?'), findsNothing);
    await tap(
      t,
      find.descendant(
        of: find.byType(TermDialog),
        matching: find.byWidgetPredicate(
          (v) => v is TermButton && v.label == ar.signOut,
        ),
      ),
    );
    expect(text(ar.signedOut), findsOneWidget);
    await tap(t, text(ar.returnToStudio));
    expect(text(ar.greeting), findsOneWidget);
  });

  // Unsaved changes on a phone: the title edited, then the system back.
  Future<void> askToLeave(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);
    await show(tester, const StintLaunch(place: Place.tasks, detail: true));
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
    final actions = tester.widgetList<TermButton>(
      find.descendant(
        of: find.byType(TermDialog),
        matching: find.byType(TermButton),
      ),
    );
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
}
