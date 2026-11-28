import 'dart:ui' as ui;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoListSection;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_cupertino/stint_cupertino.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: () =>
        (FontLoader('packages/cupertino_icons/CupertinoIcons')..addFont(
              rootBundle.load(
                'packages/cupertino_icons/assets/CupertinoIcons.ttf',
              ),
            ))
            .load(),
    app: (launch, repository) =>
        StintCupertino(launch: launch, repository: repository),
  );
  const w = StintWords();
  void viewport(WidgetTester t, double width, {double height = 960}) {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = Size(width, height);
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
  }

  for (final width in [390, 1440]) {
    for (final rtl in [false, true]) {
      testWidgets('Section headings meet the painted card edge at $width '
          '${rtl ? "RTL" : "LTR"}', (t) async {
        viewport(t, width.toDouble(), height: 4100);
        const page = ValueKey('cupertino-page-paint');
        await t.pumpWidget(
          RepaintBoundary(
            key: page,
            child: StintCupertino(
              launch: StintLaunch(
                language: rtl ? StintLanguage.ar : StintLanguage.en,
                appearance: Appearance.day,
              ),
              repository: StintRepository(clock: () => studyMorning),
            ),
          ),
        );
        await t.pumpAndSettle();
        final pixels = (await t.runAsync(() async {
          final image = await captureImage(t.element(find.byKey(page)));
          try {
            return await image.toByteData(format: ui.ImageByteFormat.rawRgba);
          } finally {
            image.dispose();
          }
        }))!;

        int leadingPixel(Rect area, bool Function(int) matches) {
          for (var i = 0; i < area.width.ceil(); i++) {
            final x = rtl ? area.right.ceil() - 1 - i : area.left.floor() + i;
            for (var y = area.top.floor(); y < area.bottom.ceil(); y++) {
              if (matches(pixels.getUint32((y * width + x) * 4))) {
                return rtl ? x + 1 : x;
              }
            }
          }
          throw StateError('No matching pixels in $area');
        }

        final words = StintWords(rtl ? StintLanguage.ar : StintLanguage.en);
        int? pairedBottom;
        for (final (group, title) in [
          ('plan', words.todaysPlan),
          ('team', words.teamActivity),
          ('blocks', words.timeBlocks),
          ('later', words.laterThisWeek),
          ('feed', words.recentActivity),
        ]) {
          final rowMark = find.byWidgetPredicate((widget) {
            final key = widget.key;
            return key is ValueKey<String> &&
                key.value.startsWith('today-$group-lead-');
          }).first;
          final card = t.getRect(
            find.ancestor(
              of: rowMark,
              matching: find.byType(CupertinoListSection),
            ),
          );
          // Sample the straight side below the rounded top corners.
          final acrossCard = Rect.fromLTRB(
            card.left - 4,
            card.top + 20,
            card.right + 4,
            card.top + 21,
          );
          final face = leadingPixel(acrossCard, (rgba) => rgba == 0xffffffff);
          final heading = t.getRect(find.text(title));
          final origin = rtl ? heading.right : heading.left;
          expect(origin, closeTo(face, 1), reason: '$title text origin');
          // The first glyph can have a side bearing, especially in Arabic.
          final ink = leadingPixel(heading, (rgba) => rgba >> 24 < 96);
          expect(ink, closeTo(face, 3), reason: '$title leading glyph');
          if (width == 1440 && (group == 'plan' || group == 'team')) {
            final x = face + (rtl ? -12 : 12);
            var y = card.bottom.ceil();
            while (y >= card.top &&
                pixels.getUint32((y * width + x) * 4) != 0xffffffff) {
              y--;
            }
            expect(y, greaterThan(card.top), reason: '$title painted face');
            pairedBottom ??= y;
            expect(y, closeTo(pairedBottom, 1), reason: 'Paired card bottoms');
          }
        }
      });
    }
  }

  testWidgets('Tracking, stopping and ticking update the visible workspace', (
    t,
  ) async {
    viewport(t, 1440);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await t.pumpWidget(StintCupertino(repository: repo));
    await t.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    final mondaySlot = find.byKey(const ValueKey('today-day-slot-0'));
    final mondayX = t.getCenter(mondaySlot).dx;
    now = now.add(const Duration(seconds: 2));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    Future<void> press(String label) async {
      final target = find.text(label).first;
      await t.ensureVisible(target);
      await t.tap(target);
      await t.pumpAndSettle();
    }

    Future<void> choose(String title) async {
      final field = find.byType(EditableText).last;
      await t.enterText(field, title);
      await t.pumpAndSettle();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
    }

    final switchButton = find.text(w.switchTask);
    for (var i = 0; i < 30; i++) {
      if (isSemantics(isFocused: true)
          .matches(t.getSemantics(switchButton), {})) {
        break;
      }
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pumpAndSettle();
    }
    expect(t.getSemantics(switchButton), isSemantics(isFocused: true));
    await t.sendKeyEvent(LogicalKeyboardKey.enter);
    await t.pumpAndSettle();
    expect(find.byType(EditableText), findsOneWidget);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await t.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    expect(find.byType(EditableText), findsNothing);

    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    expect(t.getCenter(mondaySlot).dx, closeTo(mondayX, 1));
    await press(w.stopTimer);
    expect(repo.snapshot.timer, isNull);
    expect(repo.snapshot.entries.length, 22);
    expect(find.text(w.stoppedTimer), findsOneWidget);
    final logged = repo.snapshot.activity.first;
    expect(logged.kind, ActivityKind.logged);
    expect(
      t.widget<Text>(find.byKey(const ValueKey('today-timer-digits'))).data,
      w.duration(logged.minutes),
    );
    final well = find.byKey(const ValueKey('today-timer-well'));
    expect(
      find.descendant(
        of: well,
        matching: find.text(w.eventAction(logged, w.text(team.first.name))),
      ),
      findsOneWidget,
    );
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    expect(find.text(w.runningTimer), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'Plan completion, later tasks and the feed reflect the same data',
    (t) async {
      viewport(t, 768);
      final repo = StintRepository();
      await t.pumpWidget(StintCupertino(repository: repo));
      await t.pumpAndSettle();
      t.view.physicalSize = const Size(768, 4100);
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.text(w.greeting)).dy, lessThan(140));
      expect(
        t.getSemantics(find.text(w.todaysPlan)),
        isSemantics(label: w.todaysPlan, isHeader: true, hasTapAction: false),
      );
      expect(
        t.getSemantics(find.text(w.viewTasks)),
        isSemantics(label: w.viewTasks, hasTapAction: true),
      );
      final row = find.byKey(const ValueKey('plan-ST-101'));
      await t.ensureVisible(row);
      await t.tap(
        find.descendant(of: row, matching: find.text('Proof the studio map')),
      );
      await t.pumpAndSettle();
      expect(repo.snapshot.tasks.first.done, isTrue);
      expect(
        t.getSemantics(row),
        isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
      );
      expect(find.text(w.stoppedTimer), findsOneWidget);
      expect(find.text(w.progress(2, 4)), findsOneWidget);
      expect(find.text(w.number(29)), findsOneWidget);
      for (final person in team) {
        expect(find.text(w.text(person.name)), findsOneWidget);
      }
      expect(
        find.text(
          w.eventAction(repo.snapshot.activity.first, w.text(team.first.name)),
        ),
        findsWidgets,
      );
      final later = find.text('Send the materials list').first;
      await t.ensureVisible(later);
      await t.tap(later);
      await t.pumpAndSettle();
      expect(find.text(w.title), findsWidgets);
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('Weekly readings open the task list and timesheet', (t) async {
    viewport(t, 390);
    await t.pumpWidget(StintCupertino(repository: StintRepository()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('today-stat-tasks')));
    await t.pumpAndSettle();
    expect(find.text(w.filters), findsWidgets);
    await t.tap(find.text(w.today).last);
    await t.pumpAndSettle();
    await t.tap(find.byKey(const ValueKey('today-stat-hours')));
    await t.pumpAndSettle();
    expect(find.text(w.addEntry), findsWidgets);
  });

  testWidgets('Large chart labels share a baseline and stay separated', (
    t,
  ) async {
    viewport(t, 390);
    await t.pumpWidget(const StintCupertino(launch: StintLaunch(scale: 2)));
    await t.pumpAndSettle();
    Rect? previous;
    for (var i = 0; i < 7; i++) {
      final label = find.byKey(ValueKey('today-day-label-$i'));
      final rect = t.getRect(label);
      expect(
        t.widget<Text>(label).data,
        w.weekdayShort(addDays(mondayOf(studyToday), i)),
      );
      if (previous != null) {
        expect(rect.left - previous.right, greaterThanOrEqualTo(3));
        expect(rect.bottom, closeTo(previous.bottom, 1));
      }
      previous = rect;
    }
  });

  testWidgets(
    'An empty workspace explains the timer, schedule and feed in Arabic',
    (t) async {
      viewport(t, 390);
      const ar = StintWords(StintLanguage.ar);
      await t.pumpWidget(
        StintCupertino(
          launch: const StintLaunch(language: StintLanguage.ar, scale: 2),
          repository: StintRepository(empty: true),
        ),
      );
      await t.pumpAndSettle();
      for (final label in [
        ar.stoppedTimer,
        ar.noTimerTasks,
        ar.noTasksToday,
        ar.noBlocks,
        ar.allClear,
        ar.noActivity,
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final start = find.text(ar.startTimer);
      expect(
        t.getSemantics(start),
        isSemantics(hasEnabledState: true, isEnabled: false),
      );
      expect(t.takeException(), isNull);
    },
  );
}
