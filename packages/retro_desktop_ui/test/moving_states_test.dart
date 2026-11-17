// The ten everyday screens between their states (ui_core's moving_states.dart): a press held halfway, a hover, a
// keyboard focus and a sheet halfway open, each moment held still and read by ui_core's shadow and clip check near
// what moved, so no shadow, rim or ring is cut by a clip round it. On a phone (iOS, a finger) at 390 and on a desk
// (macOS, a pointer) at 1440. Retro Desktop's own motion is instant, as the period's was, so a moment is the frame its
// state lands on. None of the ten screens swipes (the look has no carousel), so there is no swipe to hold.
// ignore_for_file: avoid_relative_lib_imports
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:ui_core/alignment.dart';

import '../example/lib/everyday_screens.dart';
import 'moving_states.dart';

void main() {
  for (final (form, (width, platform)) in const [
    (390.0, TargetPlatform.iOS),
    (1440.0, TargetPlatform.macOS),
  ].indexed) {
    for (final (i, screen) in everydayScreens.indexed) {
      testWidgets(
        '${screen.id} at ${width.toInt()}: no shadow or ring is cut while it moves',
        variant: TargetPlatformVariant.only(platform),
        // Every day each screen once, on a phone and on a desk in turn; the other in the sweep (dart_test.yaml).
        tags: i % 2 == form ? null : const ['sweep'],
        (tester) async {
          tester.view
            ..physicalSize = Size(width, width < 600 ? 844 : 900)
            ..devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            screen.app(Brightness.light, TextDirection.ltr),
          );
          await tester.pumpAndSettle();
          final root = find.byType(WidgetsApp).first;
          final problems = <String>[];
          var moments = 0;

          Future<void> checkNear(String moment, Finder target) async {
            moments++;
            final report =
                await const DesignShadowClipCheck(look: 'Retro Desktop').check(
                  tester.element(root),
                  runAsync: tester.runAsync,
                  near: target.evaluate().isEmpty
                      ? null
                      : tester.getRect(target).inflate(16),
                );
            problems.addAll(report.problems.map((p) => '$moment: $p'));
          }

          // The first enabled button the page shows, else its first enabled field, else the first enabled control a
          // tap reaches (a list's row, a switch): pinned to its element, so every moment holds the same one.
          bool enabled(Widget w) => switch (w) {
            RetroDesktopButton(:final onPressed) => onPressed != null,
            RetroDesktopTextField(:final enabled) => enabled,
            RetroDesktopPressable(:final onPressed) => onPressed != null,
            _ => false,
          };
          final picked =
              [RetroDesktopButton, RetroDesktopTextField, RetroDesktopPressable]
                  .map(
                    (type) => find
                        .byType(type)
                        .hitTestable()
                        .evaluate()
                        .where((e) => enabled(e.widget)),
                  )
                  .firstWhere(
                    (found) => found.isNotEmpty,
                    orElse: () => const <Element>[],
                  );
          expect(picked, isNotEmpty, reason: '${screen.id} has a control');
          final element = picked.first;
          final target = find.byElementPredicate((e) => identical(e, element));

          await atPressHalfway(
            tester,
            target,
            (moment) => checkNear(moment, target),
          );
          if (platform == TargetPlatform.macOS) {
            await atHover(
              tester,
              target,
              (moment) => checkNear(moment, target),
            );
          }
          await atFocus(tester, target, (moment) => checkNear(moment, target));
          final context = tester.element(target);
          await atSheetHalfway(
            tester,
            () => showRetroDesktopBottomSheet<void>(
              context,
              builder: (_) => const RetroDesktopBottomSheet(
                title: 'Print',
                child: Text('Two copies, both sides.'),
              ),
            ),
            (moment) async {
              moments++;
              final report = await const DesignShadowClipCheck(
                look: 'Retro Desktop',
              ).check(tester.element(root), runAsync: tester.runAsync);
              problems.addAll(report.problems.map((p) => '$moment: $p'));
            },
          );
          expect(tester.takeException(), isNull);
          expect(moments, platform == TargetPlatform.macOS ? 6 : 4);
          expect(problems, isEmpty);
        },
      );
    }
  }
}
