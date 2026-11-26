import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_keycap/stint_keycap.dart';

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
      StintKeycap(
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
              // The place keys stand in a row at the phone's foot.
              final places = find.bySemanticsLabel(
                RegExp(
                  '^${RegExp.escape(StintWords(ar ? StintLanguage.ar : StintLanguage.en).today)}',
                ),
              );
              expect([
                for (var i = 0; i < places.evaluate().length; i++)
                  tester.getCenter(places.at(i)).dy,
              ], contains(greaterThan(700)));
            }
          }
        },
      );
    }
  }

  testWidgets('phone week switcher keeps its keys beside the range at 2x', (
    tester,
  ) async {
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
        (widget) => widget is KeycapIconButton && widget.semanticLabel == label,
      );
      final previous = button(words.previousWeek),
          next = button(words.nextWeek);
      final week = mondayOf(studyToday);
      Finder range(DateTime start) =>
          find.text(words.weekRange(start, compact: true));
      final label = tester.widget<Text>(range(week));
      expect(label.maxLines, isNull);
      expect(label.overflow, isNot(TextOverflow.ellipsis));
      final date = tester.getRect(range(week));
      final before = tester.getRect(previous), after = tester.getRect(next);
      expect(before.width, greaterThanOrEqualTo(40));
      expect(after.size, before.size);
      expect(before.center.dy, date.center.dy);
      expect(after.center.dy, date.center.dy);
      expect((arabic ? after : before).right, lessThanOrEqualTo(date.left));
      expect((arabic ? before : after).left, greaterThanOrEqualTo(date.right));
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(range(addDays(week, 7)), findsOneWidget);
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
      final formButton = find.widgetWithText(KeycapButton, words.addEntry).last;
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

  Finder selectField(String label) =>
      find.byWidgetPredicate((w) => w is KeycapSelect && w.labelText == label);
  Finder ball(String label) => find.byWidgetPredicate(
    (w) => w is KeycapIconButton && w.semanticLabel == label,
  );

  testWidgets(
    'search, filter keys, the list well and row keys share their edges',
    (tester) async {
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
        final field = tester.getRect(find.byType(KeycapSearchField));
        // The well's rows span the well: its first row measures it.
        expect(find.text(words.totalTasks(30).toUpperCase()), findsOneWidget);
        final group = tester.getRect(
          find
              .byWidgetPredicate(
                (w) =>
                    w.key is ValueKey<String> &&
                    (w.key! as ValueKey<String>).value.startsWith(
                      'task-well-row-',
                    ),
              )
              .first,
        );
        final filters = tester.getRect(
          find.widgetWithText(
            KeycapButton,
            '${words.filters} (${words.number(1)})',
          ),
        );
        final select = tester.getRect(
          find.widgetWithText(KeycapButton, words.select),
        );
        expect(group.left, closeTo(field.left, 0.01));
        expect(group.right, closeTo(field.right, 0.01));
        expect((arabic ? select : filters).left, closeTo(field.left, 0.01));
        expect((arabic ? filters : select).right, closeTo(field.right, 0.01));
        expect(filters.height, select.height);
        final menu1 = tester.getRect(
          ball('${words.actions}${words.dot}ST-101'),
        );
        final menu2 = tester.getRect(
          ball('${words.actions}${words.dot}ST-102'),
        );
        expect(menu1.left, menu2.left);
        expect(menu1.right, menu2.right);
      }
    },
  );

  testWidgets(
    'project, assignee and status intersect, sort, bulk delete and undo',
    (tester) async {
      window(tester, 1440);
      final repo = StintRepository();
      await launch(tester, const StintLaunch(place: Place.tasks), repo: repo);
      await press(tester, find.widgetWithText(KeycapButton, 'Filters (1)'));
      for (final choice in [
        ('Status', 'Open'),
        ('Project', 'Open studio'),
        ('Assignee', 'Maya Reed'),
        ('Sort by', 'Title'),
      ]) {
        await press(tester, selectField(choice.$1));
        await press(tester, find.text(choice.$2).hitTestable().last);
      }
      await press(tester, find.widgetWithText(KeycapButton, 'Apply'));
      final rows = find.byType(KeycapSwipeActions);
      expect(rows, findsNWidgets(2));
      final titles = tester
          .widgetList<KeycapListTile>(
            find.descendant(of: rows, matching: find.byType(KeycapListTile)),
          )
          .map((row) => row.title)
          .toList();
      expect(titles, ['Label the display shelves', 'Proof the studio map']);
      await press(tester, find.widgetWithText(KeycapButton, 'Select tasks'));
      for (final title in titles) {
        await press(tester, find.text(title));
      }
      await press(tester, ball('Task actions · 2 selected'));
      await press(tester, find.text('Delete').hitTestable().last);
      expect(repo.snapshot.tasks.length, 38);
      await press(tester, find.text('Undo').hitTestable().last);
      expect(repo.snapshot.tasks.length, 40);
      await press(tester, ball('Task actions · ST-101'));
      await press(tester, find.text('Move to project').hitTestable().last);
      await press(tester, find.text('Workshop series').hitTestable().last);
      expect(
        repo.snapshot.tasks.firstWhere((t) => t.id == 'ST-101').project,
        'workshops',
      );
      await press(tester, ball('Task actions · ST-116'));
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
        StintKeycap(
          key: UniqueKey(),
          launch: const StintLaunch(scenario: 'loading', place: Place.tasks),
        ),
      );
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.byType(KeycapSkeleton), findsWidgets);
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
          (v) => v is KeycapTextField && v.labelText == 'Title',
        ),
        matching: find.byType(EditableText),
      );
      await tester.enterText(title(), '');
      await tester.pumpAndSettle();
      await press(tester, find.widgetWithText(KeycapButton, 'Save changes'));
      expect(find.text(const StintWords().titleError), findsOneWidget);
      await tester.enterText(title(), 'Check the studio map');
      final assignee = find.descendant(
        // Assignee: Project's combobox comes first.
        of: find.byType(KeycapCombobox<String>).last,
        matching: find.byType(EditableText),
      );
      await tester.ensureVisible(assignee);
      await tester.enterText(assignee, 'Noor');
      await tester.pumpAndSettle();
      await press(tester, find.text('Noor Haddad').hitTestable().last);
      await press(tester, find.byType(KeycapDatePicker));
      expect(find.byType(KeycapCalendar), findsOneWidget);
      await press(tester, find.text('24').hitTestable().last);
      await press(tester, find.text('Reminder time'));
      expect(find.byType(KeycapTimePicker), findsOneWidget);
      await press(tester, find.widgetWithText(KeycapButton, 'Apply'));
      await press(tester, find.widgetWithText(KeycapButton, 'Save changes'));
      final task = repo.snapshot.tasks.first;
      expect(task.assignee, 'noor');
      expect(task.title.$1, 'Check the studio map');
      expect(task.due, DateTime(2026, 11, 24));
    },
  );

  testWidgets(
    'settings retain night, density and Arabic through sign-out and return',
    (tester) async {
      window(tester, 800);
      await launch(tester, const StintLaunch(place: Place.settings));
      const en = StintWords();
      Future<void> pick(String row, String choice, String apply) async {
        await press(tester, find.text(row).first);
        await press(tester, find.text(choice).hitTestable().last);
        await press(tester, find.widgetWithText(KeycapButton, apply).last);
      }

      await pick(en.appearance, en.appearanceName(Appearance.night), en.apply);
      await pick(en.density, en.compact, en.apply);
      await pick(en.languageLabel, 'العربية', en.apply);
      const ar = StintWords(StintLanguage.ar);
      final ctx = tester.element(find.text(ar.aboutDetail));
      expect(Directionality.of(ctx), TextDirection.rtl);
      expect(KeycapTheme.of(ctx).colors.brightness, Brightness.dark);
      expect(KeycapTheme.of(ctx).density, RawDensity.compact);
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
        // The Assignee field's own words: from 1024 the side column's
        // account row names Maya too.
        final field = find.descendant(
          of: find.byType(KeycapCombobox<String>).last,
          matching: find.text('Maya Reed'),
        );
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
    final dialog = tester.widget<KeycapDialog>(find.byType(KeycapDialog));
    final keys = dialog.actions.whereType<KeycapButton>().toList();
    expect(keys.map((k) => (k.child as Text).data), [
      w.cancel,
      w.discard,
      w.save,
    ]);
    expect(
      keys
          .where((k) => k.isDestructiveAction)
          .map((k) => (k.child as Text).data),
      [w.discard],
    );
  });

  testWidgets('Today\'s past days read as data in every palette', (
    tester,
  ) async {
    window(tester, 390);
    for (final accent in KeycapThemeData.presets) {
      for (final appearance in [Appearance.day, Appearance.night]) {
        await launch(
          tester,
          StintLaunch(accent: accent, appearance: appearance),
        );
        // Monday has hours: its risen plastic against the slot it rises in.
        final slot = find.byKey(const ValueKey('today-day-slot-0'));
        final groove = tester.widget<DecoratedBox>(
          find.descendant(of: slot, matching: find.byType(DecoratedBox)).first,
        );
        final floor = (groove.decoration as BoxDecoration).color!;
        final risen = tester
            .widgetList<ColoredBox>(
              find.descendant(of: slot, matching: find.byType(ColoredBox)),
            )
            .first
            .color;
        expect(
          RawPalette.contrastRatio(risen, floor),
          greaterThanOrEqualTo(3),
          reason: '$accent, ${appearance.name}',
        );
      }
    }
  });
}
