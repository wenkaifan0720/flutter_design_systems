import 'dart:convert';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:stint_civic/stint_civic.dart';
import 'package:stint_core/stint_core.dart';

void main() {
  // Civic's own faces, so a page at 200% is measured in the letters a reader
  // sees rather than the test font's square glyphs.
  setUpAll(() async {
    final manifest = json.decode(
      await rootBundle.loadString('FontManifest.json'),
    ) as List<dynamic>;
    for (final entry in manifest.cast<Map<String, dynamic>>()) {
      final loader = FontLoader(entry['family'] as String);
      for (final font
          in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
        loader.addFont(rootBundle.load(font['asset'] as String));
      }
      await loader.load();
    }
  });

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
      StintCivic(
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
      (v) => v is CivicTextField && v.labelText == name,
    ),
    matching: find.byType(EditableText),
  );
  Finder icon(String name) => find.byWidgetPredicate(
    (v) => v is CivicIconButton && v.semanticLabel == name,
  );
  Future<void> key(WidgetTester t, LogicalKeyboardKey letter) async {
    await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await t.sendKeyEvent(letter);
    await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await t.pumpAndSettle();
  }

  for (final width in [390.0, 1440.0]) {
    for (final rtl in [false, true]) {
      testWidgets('Five public-service pages at $width and 200%, Arabic=$rtl', (
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
          if (page == 'time') {
            final back = t.getRect(icon(w.previousWeek)),
                forward = t.getRect(icon(w.nextWeek));
            expect(
              t.widget<CivicIconButton>(icon(w.previousWeek)).icon,
              rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
            );
            final arrow = t.widget<Icon>(
              find.descendant(
                of: icon(w.previousWeek),
                matching: find.byType(Icon),
              ),
            );
            expect(
              arrow.color,
              t.element(icon(w.previousWeek)).civicTheme.textPrimary,
            );
            expect(back.size, forward.size);
            expect(back.center.dy, forward.center.dy);
            expect(back.center.dx < forward.center.dx, !rtl);
            expect(back.width, greaterThanOrEqualTo(44));
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
      expect(find.byType(CivicErrorSummary), findsOneWidget);
      expect(text(const StintWords().titleError), findsWidgets);
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
      await tap(t, icon('Open calendar'));
      expect(find.byType(CivicCalendar), findsOneWidget);
      await tap(t, find.text('24').hitTestable().last);
      expect(find.byType(CivicTimeInput), findsOneWidget);
      await key(t, LogicalKeyboardKey.keyS);
      expect(repo.snapshot.tasks.first.title.$1, 'Rehang the studio map');
      expect(repo.snapshot.tasks.first.due, DateTime(2026, 11, 24));
      await t.enterText(field('Title'), 'Discard this');
      await t.pumpAndSettle();
      await tap(t, text('Settings').first);
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
    // As GOV.UK's search: the list holds while you type, and filters when
    // Search is pressed or Enter typed.
    await t.enterText(field('Search tasks'), 'no matching records');
    await t.pumpAndSettle();
    expect(text('No matching tasks'), findsNothing);
    await tap(t, find.bySemanticsLabel('Search tasks').last);
    expect(text('No matching tasks'), findsOneWidget);
    await tap(t, text('Clear filters'));
    await t.enterText(field('Search tasks'), 'no matching records');
    await t.testTextInput.receiveAction(TextInputAction.search);
    await t.pumpAndSettle();
    expect(text('No matching tasks'), findsOneWidget);
    await tap(t, text('Clear filters'));
    await tap(t, field('Search tasks'));
    await key(t, LogicalKeyboardKey.keyK);
    expect(find.byType(RawCommandPalette), findsOneWidget);
    await t.enterText(field('Find a command'), 'Time');
    await t.pumpAndSettle();
    await tap(t, find.text('Time').hitTestable().last);
    await tap(t, find.widgetWithText(CivicButton, 'Add entry'));
    expect(field('Work note'), findsOneWidget);
    await tap(t, find.widgetWithText(CivicButton, 'Add entry').last);
    expect(find.byType(CivicErrorSummary), findsOneWidget);
    await t.enterText(field('Work note'), 'Light the entry');
    await t.pumpAndSettle();
    await tap(t, find.widgetWithText(CivicButton, 'Add entry').last);
    expect(repo.snapshot.entries.last.note.$1, 'Light the entry');
    expect(text('16h 45m'), findsOneWidget);
  });
  testWidgets('Cancel discards pending filter choices on phone and desktop', (
    t,
  ) async {
    final project = find.byWidgetPredicate(
      (widget) =>
          widget is CivicSelect<String> && widget.labelText == 'Project',
    );
    for (final width in [390.0, 1440.0]) {
      window(t, width);
      await show(t, const StintLaunch(place: Place.tasks));
      await tap(t, text('Filters (1)'));
      await tap(t, project);
      await tap(t, text('Open studio').hitTestable().last);
      expect(t.widget<CivicSelect<String>>(project).value, isNotEmpty);
      await tap(t, find.widgetWithText(CivicButton, 'Cancel'));
      await tap(t, text('Filters (1)'));
      expect(t.widget<CivicSelect<String>>(project).value, isEmpty);
    }
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
        find.byWidgetPredicate((v) => v is CivicSelect && v.labelText == name),
      );
      await tap(t, find.text(choice).hitTestable().last);
    }
    await tap(t, text('Apply'));
    expect(text('2 tasks'), findsOneWidget);
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
    expect(text('No tasks here'), findsOneWidget);
    await show(t, const StintLaunch(place: Place.settings));
    await tap(t, text('Night'));
    await tap(t, text('العربية'));
    const ar = StintWords(StintLanguage.ar);
    await tap(t, find.widgetWithText(CivicLink, ar.signOut));
    await tap(t, find.widgetWithText(CivicLink, ar.cancel));
    await tap(t, find.widgetWithText(CivicLink, ar.signOut));
    await tap(t, find.widgetWithText(CivicButton, ar.signOut));
    expect(text(ar.signedOut), findsOneWidget);
    await tap(t, text(ar.returnToStudio));
    expect(text(ar.greeting), findsOneWidget);
  });

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
        await show(tester, const StintLaunch(place: Place.tasks, detail: true));
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
    final actions = tester
        .widget<CivicDialog>(find.byType(CivicDialog))
        .actions;
    expect(actions, hasLength(3));
    final discard = actions[1] as CivicButton;
    expect((discard.child as Text).data, w.discard);
    expect(discard.isDestructiveAction, isTrue);
    expect(find.text(w.cancel), findsOneWidget);
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
