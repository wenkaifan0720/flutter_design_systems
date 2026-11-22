// A focused text field always shows where the next key lands: its block
// caret blinks between solid and hollow, never to nothing, so a glance in
// either half of the blink finds it.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

final _shot = GlobalKey();

void main() {
  setUpAll(loadFaces);

  const themes = {'paper': TermThemeData.light, 'night': TermThemeData.dark};
  for (final MapEntry(key: name, value: theme) in themes.entries) {
    testWidgets('on $name a focused field shows its caret through the blink', (
      tester,
    ) async {
      final t = theme();
      final words = TextEditingController(text: 'walk');
      addTearDown(words.dispose);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: TermTheme(
            data: t,
            child: ColoredBox(
              color: t.background,
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: RepaintBoundary(
                    key: _shot,
                    child: ColoredBox(
                      color: t.background,
                      child: SizedBox(
                        width: 360,
                        child: TermTextField(
                          controller: words,
                          labelText: 'search tasks',
                          prompt: '/',
                          autofocus: true,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final grid = tester.element(find.byType(TermTextField)).termGrid;

      // The caret's ink on the words' line, inside the frame's sides.
      Future<int> caretInk() async {
        final boundary =
            _shot.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final (ByteData rgba, int w) = (await tester.runAsync(() async {
          final image = await boundary.toImage();
          final data = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final width = image.width;
          image.dispose();
          return (data!, width);
        }))!;
        final lh = grid.lineHeight;
        var ink = 0;
        for (var y = (lh + 3).round(); y < (lh * 2 - 3).round(); y++) {
          for (var x = grid.cellWidth.round(); x < w - grid.cellWidth; x++) {
            final i = (y * w + x) * 4;
            final d =
                (rgba.getUint8(i) - (t.accent.r * 255).round()).abs() +
                (rgba.getUint8(i + 1) - (t.accent.g * 255).round()).abs() +
                (rgba.getUint8(i + 2) - (t.accent.b * 255).round()).abs();
            if (d < 60) ink++;
          }
        }
        return ink;
      }

      await tester.pump(const Duration(milliseconds: 200));
      final shown = await caretInk();
      await tester.pump(const Duration(milliseconds: 500));
      final blinked = await caretInk();
      expect(shown, greaterThan(0), reason: 'the solid half');
      expect(blinked, greaterThan(0), reason: 'the other half');
      expect(blinked, lessThan(shown), reason: 'hollow, not solid');
    });
  }
}
