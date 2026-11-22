// A dialog's destructive action (Discard) is set as the period's alerts set Don't Save: the stop sign before its words
// on the face it would have anyway (no red face, which the language never had), and apart at the row's start, at least
// 24 from Cancel, so it never reads as Cancel beside it. On a desk, where the alert's buttons stand in one row.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

/// How many pixels of [part]'s box are the stop sign's red.
Future<int> _stopRed(
  WidgetTester tester,
  GlobalKey key,
  Finder part,
  Color stop,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  final origin = tester.getTopLeft(find.byKey(key));
  final box = tester.getRect(part).shift(-origin);
  var n = 0;
  for (var y = box.top.ceil(); y < box.bottom.floor(); y++) {
    for (var x = box.left.ceil(); x < box.right.floor(); x++) {
      final i = (y * width + x) * 4;
      if ((bytes.getUint8(i) - (stop.r * 255).round()).abs() <= 2 &&
          (bytes.getUint8(i + 1) - (stop.g * 255).round()).abs() <= 2 &&
          (bytes.getUint8(i + 2) - (stop.b * 255).round()).abs() <= 2) {
        n++;
      }
    }
  }
  return n;
}

void main() {
  // The look's own faces, so the three buttons measure as on a desk and stand in one row.
  setUpAll(loadRetroDesktopFonts);
  for (final (dark, direction, buttons) in [
    (false, TextDirection.ltr, false),
    (true, TextDirection.ltr, false),
    (false, TextDirection.rtl, false),
    (false, TextDirection.ltr, true),
  ]) {
    final mode =
        '${dark ? 'night' : 'day'}, ${direction.name}'
        '${buttons ? ', as plain buttons' : ''}';
    testWidgets('Discard carries the stop sign and stands apart, by $mode', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        retroDesktopApp(
          Directionality(
            textDirection: direction,
            child: Center(
              child: RepaintBoundary(
                key: key,
                child: RetroDesktopDialog(
                  title: 'Unsaved changes',
                  message: 'Save your changes before leaving this task?',
                  actions: buttons
                      ? [
                          RetroDesktopButton('Cancel', onPressed: () {}),
                          RetroDesktopButton(
                            'Discard',
                            isDestructiveAction: true,
                            onPressed: () {},
                          ),
                          RetroDesktopButton(
                            'Save changes',
                            isDefaultAction: true,
                            onPressed: () {},
                          ),
                        ]
                      : const [
                          RetroDesktopDialogAction<String>('Cancel'),
                          RetroDesktopDialogAction<String>(
                            'Discard',
                            value: 'discard',
                            isDestructiveAction: true,
                          ),
                          RetroDesktopDialogAction<String>(
                            'Save changes',
                            value: 'save',
                            isDefaultAction: true,
                          ),
                        ],
                ),
              ),
            ),
          ),
          dark: dark,
          width: 1440,
        ),
      );
      await tester.pumpAndSettle();
      Finder button(String label) =>
          find.widgetWithText(RetroDesktopButton, label);
      final stop = RetroDesktopTheme.of(
        tester.element(find.byType(RetroDesktopDialog)),
      ).colors.illustration.stop;

      expect(
        await _stopRed(tester, key, button('Discard'), stop),
        greaterThan(40),
        reason: 'the stop sign before Discard',
      );
      expect(await _stopRed(tester, key, button('Cancel'), stop), 0);
      expect(await _stopRed(tester, key, button('Save changes'), stop), 0);
      expect(
        find.descendant(of: button('Discard'), matching: find.byType(Icon)),
        findsNothing,
        reason: 'the period picture, not a line glyph',
      );

      final discard = tester.getRect(button('Discard'));
      final cancel = tester.getRect(button('Cancel'));
      final save = tester.getRect(button('Save changes'));
      if (direction == TextDirection.ltr) {
        expect(cancel.left - discard.right, greaterThanOrEqualTo(24 - .01));
        expect(save.left, greaterThan(cancel.right));
      } else {
        expect(discard.left - cancel.right, greaterThanOrEqualTo(24 - .01));
        expect(save.right, lessThan(cancel.left));
      }
      expect(discard.top, cancel.top, reason: 'one row');
    }, variant: TargetPlatformVariant.only(TargetPlatform.macOS));
  }
}
