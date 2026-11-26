import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart'
    show
        ExpressiveBarChart,
        ExpressiveDialog,
        ExpressiveDockedDatePicker,
        ExpressiveFilledButton,
        ExpressiveIconButton,
        ExpressiveSelect,
        ExpressiveThemeData,
        ExpressiveTooltip,
        RawPalette;
import 'package:stint_core/stint_core.dart';
import 'package:stint_material_expressive/stint_material_expressive.dart';

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
      StintMaterialExpressive(
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
        Finder button(String label) => find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is ExpressiveTooltip && widget.message == label,
          ),
          matching: find.byType(ExpressiveIconButton),
        );
        final previous = button(words.previousWeek),
            next = button(words.nextWeek);
        final week = mondayOf(studyToday);
        Finder range(DateTime start) => find.bySemanticsLabel(
          '${words.shortDate(start)} – ${words.shortDate(addDays(start, 6))}',
        );
        final date = tester.getRect(range(week));
        expect(
          find.text(
            '${words.number(16)}–${words.number(22)} ${words.monthNames[10]}',
          ),
          findsOneWidget,
        );
        final rangeText = tester.widget<Text>(
          find.descendant(of: range(week), matching: find.byType(Text)).first,
        );
        expect(rangeText.overflow, isNot(TextOverflow.ellipsis));
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
          .widgetWithText(ExpressiveFilledButton, words.addEntry)
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
    'day labels, data bars and the Friday highlight share physical positions in both directions',
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
        final chart = tester.widget<ExpressiveBarChart>(
          find.byType(ExpressiveBarChart),
        );
        expect(chart.points.map((p) => p.value), [
          for (final value in rtl ? daily.reversed : daily) value / 60,
        ]);
        expect(chart.highlight, rtl ? 2 : 4);
        expect(chart.points.first.label, rtl ? 'ح' : 'M');
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
          find.descendant(
            of: find.byWidgetPredicate(
              (v) => v is ExpressiveSelect && v.labelText == field,
            ),
            matching: find.byType(EditableText),
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
          (v) => v is ExpressiveIconButton && v.semanticLabel == w.actions,
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
      expect(find.text(w.allClear), findsOneWidget);
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
          (v) => v is ExpressiveSelect && v.labelText == field,
        );
        await tap(
          find.descendant(of: select, matching: find.byType(EditableText)),
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

      await tap(
        find.descendant(
          of: find.byType(ExpressiveDockedDatePicker),
          matching: find.byType(EditableText),
        ),
      );
      await tap(find.text('21').hitTestable().last);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
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
    final actions = tester
        .widget<ExpressiveDialog>(find.byType(ExpressiveDialog))
        .actions;
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

  testWidgets(
    'the running timer\'s well is a deep tint of the palette at night',
    (tester) async {
      window(tester, 390);
      for (final accent in ExpressiveThemeData.presets) {
        await launch(
          tester,
          StintLaunch(accent: accent, appearance: Appearance.night),
        );
        final well = find.byKey(const ValueKey('today-timer-well'));
        final fill =
            (tester.widget<DecoratedBox>(well).decoration as BoxDecoration)
                .color!;
        // As dark as Material's large surfaces stand at night: no lighter than
        // a tone 30 container, its words still reading 4.5:1 on it.
        expect(fill.computeLuminance(), lessThan(0.1), reason: accent);
        // The palette's own hue, not another role's: the well's hue stands
        // within 30° of the primary's wherever the primary has a hue.
        final primary = HSVColor.fromColor(
          ExpressiveThemeData.of(tester.element(well)).colors.primary,
        );
        if (primary.saturation > .2) {
          final hue = HSVColor.fromColor(fill).hue;
          final apart = (hue - primary.hue).abs() % 360;
          expect(
            apart > 180 ? 360 - apart : apart,
            lessThanOrEqualTo(30),
            reason: '$accent: well $fill, primary ${primary.toColor()}',
          );
        }
        for (final key in ['today-timer-digits', 'today-timer-title']) {
          final words = tester.widget<Text>(find.byKey(ValueKey(key)));
          expect(
            RawPalette.contrastRatio(words.style!.color!, fill),
            greaterThanOrEqualTo(4.5),
            reason: '$accent: $key',
          );
        }
      }
    },
  );

  testWidgets(
    'the words of Time\'s week chart read 4.5:1 on its card in every palette',
    (tester) async {
      window(tester, 390);
      for (final accent in ExpressiveThemeData.presets) {
        for (final appearance in [Appearance.day, Appearance.night]) {
          await launch(
            tester,
            StintLaunch(
              place: Place.time,
              accent: accent,
              appearance: appearance,
            ),
          );
          final chart = find.byType(ExpressiveBarChart);
          final card = tester
              .widgetList<Container>(
                find.ancestor(of: chart, matching: find.byType(Container)),
              )
              .map((c) => c.decoration)
              .whereType<BoxDecoration>()
              .firstWhere((d) => d.color != null);
          // The caption, each day's reading and each day's name.
          final words = find.descendant(
            of: find.ancestor(of: chart, matching: find.byType(Column)).first,
            matching: find.byType(RichText),
          );
          expect(words, findsWidgets);
          for (final element in words.evaluate()) {
            final paragraph = element.renderObject! as RenderParagraph;
            final ink = paragraph.text.style!.color!;
            expect(
              RawPalette.contrastRatio(ink, card.color!),
              greaterThanOrEqualTo(4.5),
              reason:
                  '$accent, ${appearance.name}: '
                  '"${paragraph.text.toPlainText()}"',
            );
          }
        }
      }
    },
  );
}
