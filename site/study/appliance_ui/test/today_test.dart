import 'dart:ui' show BoxHeightStyle;

import 'package:appliance_ui/appliance_ui.dart'
    show ApplianceListGroup, applianceLoadFonts;
import 'package:flutter/rendering.dart' show RenderParagraph;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_core/stint_core.dart';
import 'package:stint_appliance/stint_appliance.dart';

import '../../stint_core/test/support/today_alignment.dart';

void main() {
  checkTodayAlignment(
    hero: TodayHero.columns,
    hasTimerLamp: true,
    loadFonts: applianceLoadFonts,
    app: (launch, repository) =>
        StintAppliance(launch: launch, repository: repository),
  );
  const w = StintWords();
  testWidgets('the live timer, picker and plan update one workspace', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 960);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var now = studyMorning;
    final repo = StintRepository(clock: () => now);
    await tester.pumpWidget(StintAppliance(repository: repo));
    await tester.pumpAndSettle();
    expect(find.text('01:42:00'), findsOneWidget);
    now = now.add(const Duration(seconds: 2));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('01:42:02'), findsOneWidget);

    Future<void> press(String text) async {
      final label = find.text(text).first;
      await tester.ensureVisible(label);
      await tester.tap(label);
      await tester.pumpAndSettle();
    }

    Future<void> activateWithKeyboard(
      Finder target,
      LogicalKeyboardKey key,
    ) async {
      for (var step = 0; step < 40; step++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pumpAndSettle();
        if (isSemantics(isFocused: true)
            .matches(tester.getSemantics(target), {})) {
          await tester.sendKeyEvent(key);
          await tester.pumpAndSettle();
          return;
        }
      }
      fail('Tab did not reach $target');
    }

    Future<void> choose(String title) async {
      final field = find.byType(EditableText).last;
      await tester.tap(field);
      await tester.enterText(field, title);
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
    }

    await activateWithKeyboard(
      find.text(w.switchTask),
      LogicalKeyboardKey.enter,
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(repo.snapshot.timer?.taskId, 'ST-101');
    await press(w.switchTask);
    await choose('Edit the walking route');
    expect(repo.snapshot.timer?.taskId, 'ST-102');
    expect(repo.snapshot.entries.length, 21);
    await activateWithKeyboard(
      find.text(w.stopTimer),
      LogicalKeyboardKey.space,
    );
    expect(repo.snapshot.timer, isNull);
    expect(repo.snapshot.entries.length, 22);
    await press(w.startTimer);
    await choose('Proof the studio map');
    expect(repo.snapshot.timer?.taskId, 'ST-101');

    final row = find.byKey(const ValueKey('plan-ST-102'));
    await tester.ensureVisible(row);
    final title = find.descendant(
      of: row,
      matching: find.text('Edit the walking route'),
    );
    await tester.tap(title);
    await tester.pumpAndSettle();
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isTrue,
    );
    expect(
      tester.getSemantics(row),
      isSemantics(hasCheckedState: true, isChecked: true, hasTapAction: true),
    );
    await activateWithKeyboard(row, LogicalKeyboardKey.space);
    expect(
      repo.snapshot.tasks.singleWhere((t) => t.id == 'ST-102').done,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'Today changes from one column to two at tablet width in either direction',
    (tester) async {
      await tester.runAsync(applianceLoadFonts);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final ar in [false, true]) {
        final words = StintWords(ar ? StintLanguage.ar : StintLanguage.en);
        for (final width in [390.0, 768.0, 1024.0, 1280.0, 1440.0]) {
          tester.view.physicalSize = Size(width, 2400);
          final repo = StintRepository(clock: () => studyMorning);
          await tester.pumpWidget(
            StintAppliance(
              key: UniqueKey(),
              launch: StintLaunch(language: ar ? StintLanguage.ar : StintLanguage.en),
              repository: repo,
            ),
          );
          await tester.pumpAndSettle();
          final row = tester.getRect(find.byKey(const ValueKey('plan-ST-101')));
          final name = tester.getRect(
            find.text(words.text(team.first.name)).first,
          );
          if (width == 390) {
            expect(row.bottom, lessThan(name.top));
            expect(row.left, lessThan(name.center.dx));
            expect(row.right, greaterThan(name.center.dx));
          } else if (ar) {
            expect(name.right, lessThan(row.left));
          } else {
            expect(name.left, greaterThan(row.right));
          }
          if (width >= 1024) {
            for (final stamp in {
              for (final block in repo.snapshot.entries.where(
                (e) => e.date == studyToday,
              ))
                words.timeRange(block),
              for (final event in repo.snapshot.activity)
                words.timeAgo(event.at, studyMorning),
            }) {
              final paragraphs = tester.renderObjectList<RenderParagraph>(
                find.text(stamp),
              );
              expect(paragraphs, isNotEmpty, reason: stamp);
              for (final paragraph in paragraphs) {
                final runs = paragraph.getBoxesForSelection(
                  TextSelection(baseOffset: 0, extentOffset: stamp.length),
                  boxHeightStyle: BoxHeightStyle.max,
                );
                expect(
                  runs.map((run) => run.top).toSet(),
                  hasLength(1),
                  reason: '$stamp at $width',
                );
              }
            }
          }
          if (!ar && width >= 768) {
            Rect group(String title) => tester.getRect(
              find.byWidgetPredicate(
                (v) => v is ApplianceListGroup && v.header == title,
              ),
            );
            final plan = group(words.todaysPlan),
                roster = group(words.teamActivity);
            expect(plan.top, closeTo(roster.top, 1));
            expect(
              plan.bottom,
              closeTo(roster.bottom, 1),
              reason: 'seeded plan and roster at $width',
            );
          }
          expect(tester.takeException(), isNull);
        }
      }
    },
  );
}
