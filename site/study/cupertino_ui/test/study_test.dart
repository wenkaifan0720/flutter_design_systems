import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoButton,
        CupertinoDialogAction,
        CupertinoListTile,
        CupertinoSearchTextField,
        CupertinoTheme;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_cupertino/stint_cupertino.dart';

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
      StintCupertino(
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
  testWidgets('Settings starts on the line the other pages start on', (
    t,
  ) async {
    window(t, 1440);
    const w = StintWords();
    await show(t, const StintLaunch(place: Place.time));
    final time = t.getTopLeft(find.text(w.weekTotal)).dx;
    await show(t, const StintLaunch(place: Place.settings));
    final settings = t.getTopLeft(find.text(w.preferences)).dx;
    expect((settings - time).abs(), lessThan(24));
  });

  testWidgets('A split-view task opens at Title and keeps its menu separate', (
    t,
  ) async {
    window(t, 1194);
    const words = StintWords();
    final repo = StintRepository();
    final task = repo.snapshot.tasks.firstWhere((task) => task.id == 'ST-105');
    await show(t, const StintLaunch(place: Place.tasks), repo: repo);
    await t.tap(find.text(words.text(task.title)));
    await t.pumpAndSettle();
    final title = t.getRect(find.text(words.title).first);
    expect(title.top, greaterThan(44));
    expect(title.bottom, lessThan(240));
    final action = find.semantics.byLabel(
      '${words.actions}${words.dot}${task.id}',
    );
    expect(action, findsOne);
    t.semantics.tap(action);
    await t.pumpAndSettle();
    expect(find.text(words.delete), findsOneWidget);
  });

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

  testWidgets('The chooser\'s search field meets its list\'s edges', (t) async {
    window(t, 390);
    const w = StintWords();
    await show(t, const StintLaunch());
    await t.ensureVisible(find.text(w.switchTask).first);
    await t.tap(find.text(w.switchTask).first);
    await t.pumpAndSettle();
    final field = t.getRect(find.byType(CupertinoSearchTextField));
    final row = t.getRect(find.byType(CupertinoListTile).last);
    expect(field.left, closeTo(row.left, 1));
    expect(field.right, closeTo(row.right, 1));
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
          matching: find.byWidgetPredicate((v) => v is CupertinoButton),
        )
        .last;
    // The key stands on the inset group's margins, edge to edge with its rows.
    final row = t.getRect(
      find
          .ancestor(
            of: find.text(w.date),
            matching: find.byType(CupertinoListTile),
          )
          .first,
    );
    expect(t.getRect(submit).left, closeTo(row.left, 1));
    expect(t.getRect(submit).right, closeTo(row.right, 1));
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

  // Three actions stand in a stack, and iOS stacks the default first and
  // Cancel at the foot.
  testWidgets('Unsaved changes stacks Save first and Cancel last', (t) async {
    window(t, 390);
    const w = StintWords();
    await show(t, const StintLaunch(place: Place.tasks, detail: true));
    await t.enterText(find.byType(EditableText).first, 'Walk the studio map');
    await t.pump();
    final NavigatorState nav = t.state(find.byType(Navigator).first);
    await nav.maybePop();
    await t.pumpAndSettle();
    final keys = t
        .widgetList<CupertinoDialogAction>(find.byType(CupertinoDialogAction))
        .map((a) => (a.child as Text).data)
        .toList();
    expect(keys, [w.save, w.discard, w.cancel]);
  });

  testWidgets('the accent reads on the night\'s grounds in every palette', (
    t,
  ) async {
    window(t, 390);
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    // The night's page and its grouped rows, where the week's bars, the
    // tab's mark, the done checks and the links stand.
    const grounds = [Color(0xFF000000), Color(0xFF1C1C1E)];
    for (final accent in ['look', ...StintAccent.values.map((a) => a.name)]) {
      await show(t, StintLaunch(accent: accent, appearance: Appearance.night));
      final primary = CupertinoTheme.of(
        t.element(find.text(StintWords().greeting).first),
      ).primaryColor;
      for (final ground in grounds) {
        expect(
          ratio(primary, ground),
          greaterThanOrEqualTo(4.5),
          reason: '$accent on $ground',
        );
      }
    }
  });
}
