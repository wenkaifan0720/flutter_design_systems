// A default button out of use lays the highlight down: a plain face in its grey ring, as it stands in a window behind
// and as a plain button out of use does, so a button out of use has one look, by day and by night.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

/// How many pixels of [part]'s box carry colour: saturated past the platinum greys.
Future<int> _coloured(WidgetTester tester, GlobalKey key, Finder part) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;
  final width = image.width;
  image.dispose();
  final box = tester.getRect(part);
  var n = 0;
  for (var y = box.top.ceil(); y < box.bottom.floor(); y++) {
    for (var x = box.left.ceil(); x < box.right.floor(); x++) {
      final i = (y * width + x) * 4;
      final colour = HSLColor.fromColor(
        Color.fromARGB(
          255,
          bytes.getUint8(i),
          bytes.getUint8(i + 1),
          bytes.getUint8(i + 2),
        ),
      );
      if (colour.saturation > .3 && colour.lightness > .1) n++;
    }
  }
  return n;
}

void main() {
  for (final dark in [false, true]) {
    final mode = dark ? 'night' : 'day';
    testWidgets('a default button out of use carries no highlight, by $mode', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(1440, 300);
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      Future<int> paint(VoidCallback? onPressed) async {
        await tester.pumpWidget(
          retroDesktopApp(
            RepaintBoundary(
              key: key,
              child: Builder(
                builder: (context) => ColoredBox(
                  color: RetroDesktopTheme.of(context).colors.platinum,
                  child: Center(
                    child: KeyedSubtree(
                      key: const ValueKey('act'),
                      child: RetroDesktopButton(
                        'Start a timer',
                        isDefaultAction: true,
                        onPressed: onPressed,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            dark: dark,
            width: 1440,
          ),
        );
        await tester.pumpAndSettle();
        return _coloured(tester, key, find.byKey(const ValueKey('act')));
      }

      expect(
        await paint(() {}),
        greaterThan(100),
        reason: 'in use, the highlight',
      );
      expect(await paint(null), 0, reason: 'out of use, the plain face');
    });
  }
}
