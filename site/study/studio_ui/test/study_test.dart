import 'package:flutter/rendering.dart' show MatrixUtils, SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_studio/stint_studio.dart';

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
      StintStudio(
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
              final nav = find.byKey(const ValueKey(Place.today));
              expect(tester.getCenter(nav).dy, greaterThan(700));
            }
          }
        },
      );
    }
  }

  testWidgets('The plan action exposes its painted position', (tester) async {
    window(tester, 1440);
    await launch(tester, const StintLaunch());
    const words = StintWords();
    final label = '${words.viewTasks}, ${words.progress(1, 4)}';
    final action = find.byKey(const ValueKey('today-view-tasks'));
    await tester.ensureVisible(action);
    await tester.pumpAndSettle();
    final target = find.semantics.byLabel(label).evaluate().single;
    var center = target.rect.center;
    for (SemanticsNode? node = target; node != null; node = node.parent) {
      final transform = node.transform;
      if (transform != null) {
        center = MatrixUtils.transformPoint(transform, center);
      }
    }
    expect(tester.getRect(action).contains(center), isTrue);
  });

  testWidgets(
    'phone week switcher preserves transport keys beside the range at 2x',
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
          (widget) => widget is StudioTransportKey && widget.tooltip == label,
        );
        final previous = button(words.previousWeek),
            next = button(words.nextWeek);
        final week = mondayOf(studyToday);
        Finder range(DateTime start) =>
            find.text(words.weekRange(start, compact: true));
        final label = tester.widget<Text>(range(week));
        expect(label.maxLines, isNull);
        expect(label.overflow, isNot(TextOverflow.ellipsis));
        // The rack's meters in every language (the chart cannot paint
        // Arabic yet), each within the phone at 2x.
        final meters = find.byType(StudioMeter);
        expect(find.byType(StudioBarChart), findsNothing);
        expect(meters, findsNWidgets(7));
        for (final meter in tester.widgetList<StudioMeter>(meters)) {
          final box = tester.getRect(find.byWidget(meter));
          expect(box.left, greaterThanOrEqualTo(0));
          expect(box.right, lessThanOrEqualTo(390));
        }
        final date = tester.getRect(range(week));
        final before = tester.getRect(previous), after = tester.getRect(next);
        expect(before.width, greaterThanOrEqualTo(48));
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
        expect(
          tester
              .widgetList<StudioMeter>(meters)
              .every((meter) => meter.level == 0),
          isTrue,
        );
        await tester.tap(next);
        await tester.pumpAndSettle();
        final crossing = find.text(
          words.weekRange(addDays(week, 14)).replaceFirst(' – ', ' –\n'),
        );
        expect(crossing, findsOneWidget);
        expect(tester.widget<Text>(crossing).maxLines, isNull);
        expect(
          tester.getRect(previous).center.dy,
          tester.getRect(crossing).center.dy,
        );
        expect(
          tester.getRect(next).center.dy,
          tester.getRect(crossing).center.dy,
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
      final formButton = find.widgetWithText(StudioButton, words.addEntry).last;
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

  Future<void> press(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  testWidgets('large-text phone sheets keep their actions above the keyboard', (
    tester,
  ) async {
    window(tester, 390);
    tester.view.physicalSize = const Size(390, 844);
    const w = StintWords(StintLanguage.ar);
    final repo = StintRepository();
    await launch(
      tester,
      const StintLaunch(
        place: Place.time,
        language: StintLanguage.ar,
        scale: 2,
      ),
      repo: repo,
    );
    final previous = repo.snapshot.entries.length;
    await press(tester, find.widgetWithText(StudioButton, w.addEntry));
    final sheet = find.byType(StudioSheet);
    final submit = find.descendant(
      of: sheet,
      matching: find.widgetWithText(StudioButton, w.addEntry),
    );
    await press(tester, submit);
    expect(find.text(w.noteError), findsOneWidget);
    final note = find
        .descendant(of: sheet, matching: find.byType(EditableText))
        .last;
    await tester.ensureVisible(note);
    await tester.enterText(note, 'إعداد خريطة الحائط');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpAndSettle();
    await tester.ensureVisible(submit);
    await tester.pumpAndSettle();
    expect(tester.getRect(submit).bottom, lessThanOrEqualTo(844 - 280));
    await press(tester, submit);
    expect(repo.snapshot.entries.length, previous + 1);
    tester.view.resetViewInsets();
    await launch(
      tester,
      const StintLaunch(
        place: Place.tasks,
        language: StintLanguage.ar,
        scale: 2,
      ),
    );
    await press(
      tester,
      find.widgetWithText(StudioButton, '${w.filters} (${w.number(1)})'),
    );
    final apply = find.descendant(
      of: sheet,
      matching: find.widgetWithText(StudioButton, w.apply),
    );
    await press(tester, apply);
    expect(sheet, findsNothing);
    expect(tester.takeException(), isNull);
  });

  Finder selectField(String label) =>
      find.byWidgetPredicate((w) => w is StudioSelect && w.labelText == label);
  Finder menuKey(String label) => find.byWidgetPredicate(
    (w) => w is StudioIconButton && w.tooltip == label,
  );

  testWidgets('search, filter keys, dividers and row menus share their edges', (
    tester,
  ) async {
    window(tester, 1440);
    for (final arabic in [false, true]) {
      await launch(
        tester,
        StintLaunch(
          place: Place.tasks,
          language: arabic ? StintLanguage.ar : StintLanguage.en,
        ),
      );
      final words = StintWords(arabic ? StintLanguage.ar : StintLanguage.en);
      final field = tester.getRect(find.byType(StudioSearchField));
      final group = tester.getRect(find.byType(StudioGroove).first);
      final filters = tester.getRect(
        find.widgetWithText(
          StudioButton,
          '${words.filters} (${words.number(1)})',
        ),
      );
      final select = tester.getRect(
        find.widgetWithText(StudioButton, words.select),
      );
      expect(group.left, closeTo(field.left, 0.01));
      expect(group.right, closeTo(field.right, 0.01));
      expect((arabic ? select : filters).left, closeTo(field.left, 0.01));
      expect((arabic ? filters : select).right, closeTo(field.right, 0.01));
      expect(filters.height, select.height);
      final menu1 = tester.getRect(
        menuKey('${words.actions}${words.dot}ST-101'),
      );
      final menu2 = tester.getRect(
        menuKey('${words.actions}${words.dot}ST-102'),
      );
      expect(menu1.left, menu2.left);
      expect(menu1.right, menu2.right);
    }
  });

  testWidgets(
    'project, assignee and status intersect, sort, bulk delete and undo',
    (tester) async {
      window(tester, 1440);
      final repo = StintRepository();
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      await press(tester, find.widgetWithText(StudioButton, 'Filters (1)'));
      for (final choice in [
        ('Status', 'Open'),
        ('Project', 'Open studio'),
        ('Assignee', 'Maya Reed'),
        ('Sort by', 'Title'),
      ]) {
        final previous = switch (choice.$1) {
          'Status' => 'Open',
          'Sort by' => 'Due date',
          _ => 'All',
        };
        await press(
          tester,
          find
              .descendant(
                of: selectField(choice.$1),
                matching: find.text(previous),
              )
              .last,
        );
        await press(tester, find.text(choice.$2).hitTestable().last);
      }
      await press(tester, find.widgetWithText(StudioButton, 'Apply'));
      final rows = find.byType(StudioListTile);
      final titles = tester
          .widgetList<StudioListTile>(rows)
          .map((row) => row.title)
          .toList();
      expect(titles, ['Label the display shelves', 'Proof the studio map']);
      await press(tester, find.widgetWithText(StudioButton, 'Select tasks'));
      for (final title in titles) {
        await press(tester, find.text(title));
      }
      await press(tester, menuKey('Task actions'));
      await press(tester, find.text('Delete').hitTestable().last);
      expect(repo.snapshot.tasks.length, 38);
      await press(tester, find.text('Undo').hitTestable().last);
      expect(repo.snapshot.tasks.length, 40);
      await press(tester, menuKey('Task actions · ST-101'));
      await press(tester, find.text('Move to project').hitTestable().last);
      await press(tester, find.text('Workshop series').hitTestable().last);
      expect(
        repo.snapshot.tasks.firstWhere((t) => t.id == 'ST-101').project,
        'workshops',
      );
      await press(tester, menuKey('Task actions · ST-116'));
      await press(tester, find.text('Mark done').hitTestable().last);
      expect(
        repo.snapshot.tasks.firstWhere((t) => t.id == 'ST-116').done,
        isTrue,
      );
    },
  );

  testWidgets(
    'failed reads retry, a delayed read shows the skeleton and empty Today explains itself',
    (tester) async {
      window(tester, 800);
      await launch(
        tester,
        const StintLaunch(place: Place.tasks),
        repo: StintRepository(failNext: true),
      );
      expect(find.text(const StintWords().loadError), findsOneWidget);
      await press(tester, find.text('Try again'));
      expect(find.text('Proof the studio map'), findsOneWidget);
      await tester.pumpWidget(
        StintStudio(
          key: UniqueKey(),
          launch: const StintLaunch(scenario: 'loading', place: Place.tasks),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(StudioSkeleton), findsWidgets);
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Proof the studio map'), findsOneWidget);
      await launch(
        tester,
        const StintLaunch(),
        repo: StintRepository(empty: true),
      );
      expect(find.text(const StintWords().allClear), findsOneWidget);
    },
  );

  testWidgets(
    'calendar, assignee search, reminder time and title validation save together',
    (tester) async {
      window(tester, 390);
      final repo = StintRepository();
      await launch(
        tester,
        const StintLaunch(place: Place.tasks, detail: true),
        repo: repo,
      );
      Finder title() => find.descendant(
        of: find.byWidgetPredicate(
          (v) => v is StudioTextField && v.labelText == 'Title',
        ),
        matching: find.byType(EditableText),
      );
      await tester.enterText(title(), '');
      await tester.pumpAndSettle();
      await press(tester, find.widgetWithText(StudioButton, 'Save changes'));
      expect(find.text(const StintWords().titleError), findsOneWidget);
      await tester.enterText(title(), 'Check the studio map');
      final assignee = find.descendant(
        // Assignee: Project's combobox comes first.
        of: find.byType(StudioCombobox<String>).last,
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(assignee);
      await tester.enterText(assignee, 'Noor');
      await tester.pumpAndSettle();
      await press(tester, find.text('Noor Haddad').hitTestable().last);
      expect(find.bySemanticsLabel('Planning'), findsOneWidget);
      await press(tester, find.byType(StudioDatePicker));
      expect(find.byType(StudioCalendar), findsOneWidget);
      await press(tester, find.text('24').hitTestable().last);
      await press(tester, find.text('Reminder time'));
      expect(find.byType(StudioTimePicker), findsOneWidget);
      await press(tester, find.widgetWithText(StudioButton, 'Apply'));
      await press(tester, find.widgetWithText(StudioButton, 'Save changes'));
      final task = repo.snapshot.tasks.first;
      expect(task.assignee, 'noor');
      expect(task.title.$1, 'Check the studio map');
      expect(task.due, DateTime(2026, 11, 24));
    },
  );

  testWidgets(
    'large Arabic dates use localized figures and dialog actions stay readable',
    (tester) async {
      window(tester, 390);
      const words = StintWords(StintLanguage.ar);
      await launch(
        tester,
        const StintLaunch(
          place: Place.tasks,
          detail: true,
          language: StintLanguage.ar,
          scale: 2,
        ),
      );
      // At 2x the label takes the picker's middle; press the window under it.
      final due = find.byType(StudioDatePicker);
      await tester.ensureVisible(due);
      await tester.pumpAndSettle();
      await tester.tapAt(
        tester.getRect(due).bottomCenter - const Offset(0, 24),
      );
      await tester.pumpAndSettle();
      final date = find
          .bySemanticsLabel(RegExp(words.number(24)))
          .hitTestable()
          .last;
      expect(date, findsOneWidget);
      await press(tester, date);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      final keys = [words.cancel, words.discard, words.save]
          .map(
            (label) => find.widgetWithText(StudioButton, label).hitTestable(),
          )
          .toList();
      for (final key in keys) {
        final rect = tester.getRect(key);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(390));
      }
      await press(tester, keys[0]);
      expect(find.text(words.dirty), findsNothing);
    },
  );

  testWidgets(
    'settings retain night, density and Arabic through sign-out and return',
    (tester) async {
      window(tester, 800);
      await launch(tester, const StintLaunch(place: Place.settings));
      await press(
        tester,
        find.descendant(
          of: selectField('Theme'),
          matching: find.text('System'),
        ),
      );
      await press(tester, find.text('Night').hitTestable().last);
      await press(
        tester,
        find.descendant(
          of: selectField('Density'),
          matching: find.text('Standard'),
        ),
      );
      await press(tester, find.text('Comfortable').hitTestable().last);
      expect(
        StudioTheme.of(tester.element(selectField('Language'))).density,
        StudioDensity.comfortable,
      );
      await press(
        tester,
        find.descendant(
          of: selectField('Density'),
          matching: find.text('Comfortable'),
        ),
      );
      await press(tester, find.text('Compact').hitTestable().last);
      await press(
        tester,
        find.descendant(
          of: selectField('Language'),
          matching: find.text('English'),
        ),
      );
      await press(tester, find.text('العربية').hitTestable().last);
      const ar = StintWords(StintLanguage.ar);
      final ctx = tester.element(find.text(ar.aboutDetail));
      expect(Directionality.of(ctx), TextDirection.rtl);
      expect(StudioTheme.of(ctx).colors.brightness, Brightness.dark);
      expect(StudioTheme.of(ctx).density, StudioDensity.compact);
      await press(tester, find.text(ar.signOut).first);
      await press(tester, find.text(ar.cancel));
      expect(find.text(ar.signOutMessage), findsNothing);
      await press(tester, find.text(ar.signOut).first);
      await press(tester, find.text(ar.signOut).hitTestable().last);
      expect(find.text(ar.signedOut), findsOneWidget);
      await press(tester, find.text(ar.returnToStudio));
      expect(find.text(ar.greeting), findsOneWidget);
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

  testWidgets('Unsaved changes sets Discard as the look sets a loss', (
    tester,
  ) async {
    const w = StintWords();
    await askToLeave(tester);
    expect(
      find.byWidgetPredicate(
        (v) =>
            v is StudioButton && v.label == w.discard && v.isDestructiveAction,
      ),
      findsOneWidget,
    );
  });
}
