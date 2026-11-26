import 'package:material_ui/material_ui.dart'
    show CircleAvatar, DatePickerDialog, FilledButton, Icons, TextField;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_material/stint_material.dart';

void main() {
  void window(WidgetTester t, double width) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, width < 500 ? 844 : 960);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  Future<void> show(
    WidgetTester t,
    StintLaunch launch, {
    StintRepository? repo,
  }) async {
    await t.pumpWidget(
      StintMaterial(
        key: UniqueKey(),
        launch: launch,
        repository: repo ?? StintRepository(),
      ),
    );
    await t.pumpAndSettle();
  }

  for (final width in [390.0, 800.0, 1440.0]) {
    for (final ar in [false, true]) {
      testWidgets('Workspace at $width, Arabic $ar', (t) async {
        window(t, width);
        final w = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
        for (final (page, label) in [
          ('today', w.greeting),
          ('tasks', w.filters),
          ('detail', w.title),
          ('time', w.addEntry),
          ('settings', w.appearance),
        ]) {
          final uri = Uri(
            queryParameters: {
              'page': page,
              'theme': ar ? 'night' : 'day',
              'dir': ar ? 'rtl' : 'ltr',
              'scale': ar ? '2' : '1',
            },
          );
          await show(t, StintLaunch.fromUri(uri));
          expect(find.text(label), findsAtLeast(1), reason: page);
          expect(t.takeException(), isNull, reason: page);
        }
      });
    }
  }
  testWidgets(
    'An unsaved edit survives Cancel and a resize, and saves by keyboard',
    (t) async {
      window(t, 390);
      final repo = StintRepository(), original = repo.snapshot.tasks.first;
      const w = StintWords();
      await show(
        t,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      await t.enterText(find.byType(EditableText).first, 'Walk the studio map');
      await t.pump();
      final NavigatorState nav = t.state(find.byType(Navigator).first);
      await nav.maybePop();
      await t.pumpAndSettle();
      expect(find.text(w.dirty), findsOneWidget);
      await t.tap(find.text(w.cancel));
      await t.pumpAndSettle();
      expect(repo.snapshot.tasks.first.title, original.title);
      t.view.physicalSize = const Size(1440, 960);
      await t.pumpAndSettle();
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyS);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(w.text(repo.snapshot.tasks.first.title), 'Walk the studio map');
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('At twice the text no field label sits on the row above', (
    t,
  ) async {
    window(t, 390);
    const w = StintWords();
    await show(
      t,
      StintLaunch.fromUri(
        Uri(queryParameters: {'page': 'detail', 'scale': '2'}),
      ),
    );
    final task = StintRepository().snapshot.tasks.first;
    final estimate = find.text(w.estimate);
    // The form builds lazily, and a drag would scroll Notes: move the form.
    t
        .state<ScrollableState>(
          find
              .ancestor(
                of: find.text(w.title),
                matching: find.byType(Scrollable),
              )
              .first,
        )
        .position
        .jumpTo(400);
    await t.pumpAndSettle();
    expect(
      t.getRect(estimate).top,
      greaterThanOrEqualTo(t.getRect(find.text(w.shortDate(task.due))).bottom),
    );
  });

  testWidgets('Time entries\' head stands on its rows\' words; Settings '
      'shows Maya by her initial', (t) async {
    window(t, 1440);
    const w = StintWords();
    await show(t, const StintLaunch(place: Place.time));
    expect(
      t.getTopLeft(find.text(w.entries)).dx,
      closeTo(t.getTopLeft(find.text('Write the introduction').first).dx, 1),
    );
    await show(t, const StintLaunch(place: Place.settings));
    expect(
      find.descendant(of: find.byType(CircleAvatar), matching: find.text('M')),
      findsOneWidget,
    );
    // Project and Assignee both carry the dropdown's arrow.
    await show(t, const StintLaunch(place: Place.tasks, detail: true));
    for (final label in [w.project, w.assignee]) {
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(label),
            matching: find.byWidgetPredicate(
              (v) =>
                  v is TextField ||
                  v.runtimeType.toString().startsWith(
                    'DropdownButtonFormField',
                  ),
            ),
          ),
          matching: find.byIcon(Icons.arrow_drop_down),
        ),
        findsOneWidget,
        reason: label,
      );
    }
  });

  testWidgets('A task estimate accepts Arabic-Indic digits', (t) async {
    window(t, 390);
    final repo = StintRepository();
    await show(
      t,
      const StintLaunch(
        place: Place.tasks,
        detail: true,
        language: StintLanguage.ar,
      ),
      repo: repo,
    );
    final estimate = find.byWidgetPredicate(
      (v) => v is EditableText && v.keyboardType == TextInputType.number,
    );
    await t.ensureVisible(estimate);
    await t.enterText(estimate, '٩٠');
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(LogicalKeyboardKey.keyS);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
    expect(repo.snapshot.tasks.first.estimate, 90);
  });

  testWidgets('Timesheet requires a note and saves it to the displayed week', (
    t,
  ) async {
    window(t, 390);
    final repo = StintRepository(), initial = repo.snapshot.entries.length;
    const w = StintWords();
    await show(t, const StintLaunch(place: Place.time), repo: repo);
    await t.ensureVisible(find.text(w.addEntry).first);
    await t.tap(find.text(w.addEntry).first);
    await t.pumpAndSettle();
    final submit = find
        .ancestor(
          of: find.text(w.addEntry),
          matching: find.byWidgetPredicate((v) => v is FilledButton),
        )
        .last;
    await t.ensureVisible(submit);
    await t.tap(submit);
    await t.pumpAndSettle();
    expect(find.text(w.noteError), findsOneWidget);
    expect(repo.snapshot.entries.length, initial);
    await t.enterText(find.byType(EditableText).last, 'Proof the wall map');
    await t.pump();
    await t.ensureVisible(submit);
    await t.tap(submit);
    await t.pumpAndSettle();
    expect(repo.snapshot.entries.length, initial + 1);
    expect(w.text(repo.snapshot.entries.last.note), 'Proof the wall map');
    expect(t.takeException(), isNull);
  });

  // Pick an Assignee and press Save: the list must not open again.
  // On the web the press focuses the key (the browser
  // focuses its semantics node, and its Focus takes the focus); the save
  // disables the key, and Flutter hands focus back to the Autocomplete,
  // which opens its options (here the one that matches its words).
  for (final width in [390.0, 1440.0]) {
    testWidgets(
      'A pressed Save lets its focus go, not back to the list, at $width',
      (tester) async {
        window(tester, width);
        const w = StintWords();
        await show(tester, const StintLaunch(place: Place.tasks, detail: true));
        final field = find.byWidgetPredicate(
          (e) => e is EditableText && e.controller.text == 'Maya Reed',
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.tap(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, 'Noor');
        await tester.pumpAndSettle();
        await tester.tap(find.text('Noor Haddad').hitTestable().last);
        await tester.pumpAndSettle();
        // The field's words, and no list.
        expect(find.text('Noor Haddad').hitTestable(), findsOneWidget);
        final save = find.text(w.save).last;
        Focus.of(tester.element(save)).requestFocus();
        await tester.pump();
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(
          find.text('Noor Haddad').hitTestable(),
          findsOneWidget,
          reason: 'the Assignee options opened again',
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

  // The app runs on a fixed morning (studyToday); a picker left to the
  // machine's clock rang another day as today.
  testWidgets('The due date picker rings the study day as today', (t) async {
    window(t, 1440);
    const w = StintWords();
    await show(t, const StintLaunch(place: Place.tasks, detail: true));
    final due = find.text(w.due).last;
    await t.ensureVisible(due);
    await t.pumpAndSettle();
    await t.tap(due);
    await t.pumpAndSettle();
    final today = t
        .widget<DatePickerDialog>(find.byType(DatePickerDialog))
        .currentDate;
    expect(
      [today.year, today.month, today.day],
      [studyToday.year, studyToday.month, studyToday.day],
    );
  });

  testWidgets('An opened Assignee lists the whole team', (t) async {
    window(t, 1440);
    await show(t, const StintLaunch(place: Place.tasks, detail: true));
    final field = find.byWidgetPredicate(
      (w) => w is EditableText && w.controller.text == 'Maya Reed',
    );
    await t.ensureVisible(field);
    await t.pumpAndSettle();
    await t.tap(field);
    await t.pumpAndSettle();
    // The list builds the rows in view: the next two names stand there.
    expect(find.text('Sam Okafor').hitTestable(), findsOneWidget);
    expect(find.text('Noor Haddad').hitTestable(), findsOneWidget);
  });
}
