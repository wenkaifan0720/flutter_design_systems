// A plate inside a rounded container is concentric with it: the same inset on every side, and its corners the
// container's less that inset. Platinum's joined strips (a toggle group, a button group, a split button) are one
// rounded frame; a held or chosen segment at either end sinks into a well that reaches the frame's outline. That well
// was a rectangle: it met the outline above and below but stopped at the frame's bevel at the end (a pixel further
// in), and its square corner sat inside the frame's round one. Measured in painted pixels, as the eye reads it, by day
// and by night, at a phone's 3x and a desktop's 2x, in either reading direction: every pixel of the well's ground keeps
// the inset (outline and bevel) from the outside, and along its edge it is no further off than that, round the corner
// too.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'support.dart';

Future<(int, int, Uint8List)> _pixels(
  WidgetTester tester,
  GlobalKey key,
) async {
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(
      pixelRatio: tester.view.devicePixelRatio,
    );
    final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final size = (image.width, image.height);
    image.dispose();
    return (size.$1, size.$2, data!.buffer.asUint8List());
  }))!;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  const values = ['Underline', 'Bold', 'Italic'];
  for (final brightness in Brightness.values) {
    for (final dpr in const [2.0, 3.0]) {
      for (final direction in TextDirection.values) {
        for (final held in const ['Underline', 'Italic']) {
          testWidgets('platinum ${brightness.name} at ${dpr.toInt()}x '
              '${direction.name}: the well of "$held" held at its end of the '
              'strip is concentric with the frame', (tester) async {
            tester.view.devicePixelRatio = dpr;
            tester.view.physicalSize = Size(600 * dpr, 200 * dpr);
            addTearDown(tester.view.reset);
            final key = GlobalKey();
            final theme = RetroDesktopThemeData.classic(brightness)
                .copyWith(appearance: RetroDesktopAppearance.platinum);
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                builder: (context, app) =>
                    RetroDesktopTheme(data: theme, child: app!),
                home: Directionality(
                  textDirection: direction,
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: RepaintBoundary(
                        key: key,
                        child: RetroDesktopToggleGroup<String>(
                          values: values,
                          selected: {held},
                          multiple: true,
                          allowEmpty: true,
                          onChanged: (_) {},
                          labelOf: (v) => v,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final (w, h, rgba) = await _pixels(tester, key);
            int at(int x, int y) => (y * w + x) * 4;
            bool outside(int x, int y) =>
                x < 0 || y < 0 || x >= w || y >= h || rgba[at(x, y) + 3] < 128;
            final c = theme.colors;
            final ground = c.dark ? c.bevelDark : c.platinumDark;
            final g8 = [
              (ground.r * 255).round(),
              (ground.g * 255).round(),
              (ground.b * 255).round(),
            ];
            bool groundColour(int x, int y) {
              if (outside(x, y)) return false;
              final i = at(x, y);
              return rgba[i] == g8[0] &&
                  rgba[i + 1] == g8[1] &&
                  rgba[i + 2] == g8[2] &&
                  rgba[i + 3] == 255;
            }

            // The frame: everything painted.
            var x0 = w, x1 = -1, y0 = h, y1 = -1;
            for (var y = 0; y < h; y++) {
              for (var x = 0; x < w; x++) {
                if (outside(x, y)) continue;
                x0 = math.min(x0, x);
                x1 = math.max(x1, x);
                y0 = math.min(y0, y);
                y1 = math.max(y1, y);
              }
            }
            expect(x1, greaterThan(x0));
            // The held end, as painted: reading order puts the first value at
            // the start.
            final left =
                (held == values.first) == (direction == TextDirection.ltr);
            // The corner and a little of the straight runs beside it, short of
            // the words.
            final span = (9 * dpr).round();
            final xs = left
                ? [for (var x = x0; x < x0 + span; x++) x]
                : [for (var x = x1 - span + 1; x <= x1; x++) x];
            // The well's ground: the run of its colour joined to a pixel inside
            // the well, short of the words (by night the frame's own bevel is
            // the same grey, a pixel of it showing between the outline and the
            // well's bevel on the curve).
            final seedX = left
                ? x0 + (5 * dpr).round()
                : x1 - (5 * dpr).round();
            final seedY = (y0 + y1) ~/ 2;
            expect(
              groundColour(seedX, seedY),
              isTrue,
              reason: 'no well painted',
            );
            final well = <int>{};
            final todo = [(seedX, seedY)];
            while (todo.isNotEmpty) {
              final (x, y) = todo.removeLast();
              if (!groundColour(x, y) || !well.add(y * w + x)) continue;
              todo.addAll([(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]);
            }
            bool isGround(int x, int y) =>
                x >= 0 && x < w && well.contains(y * w + x);

            // The inset: the outline and the well's own bevel.
            final t = (theme.strokes.regular + theme.strokes.hairline) * dpr;
            final reach = (4 * dpr).round() + 2;
            double distance(int x, int y) {
              var best = double.infinity;
              for (var yy = y - reach; yy <= y + reach; yy++) {
                for (var xx = x - reach; xx <= x + reach; xx++) {
                  if (outside(xx, yy)) {
                    final dx = xx - x, dy = yy - y;
                    best = math.min(
                      best,
                      math.sqrt((dx * dx + dy * dy).toDouble()),
                    );
                  }
                }
              }
              return best;
            }

            var nearest = double.infinity, furthest = 0.0;
            var count = 0;
            for (final x in xs) {
              for (var y = y0; y <= y1; y++) {
                if (!isGround(x, y)) continue;
                count++;
                final d = distance(x, y);
                nearest = math.min(nearest, d);
                // Its edge toward the frame: a neighbour that is not ground, on
                // the frame's side of the region's inner end.
                final inner = left ? x < xs.last : x > xs.first;
                var edge = false;
                for (final (dx, dy) in const [
                  (-1, -1),
                  (0, -1),
                  (1, -1),
                  (-1, 0),
                  (1, 0),
                  (-1, 1),
                  (0, 1),
                  (1, 1),
                ]) {
                  if (!isGround(x + dx, y + dy) &&
                      !outside(x + dx, y + dy) &&
                      x + dx >= x0 &&
                      x + dx <= x1) {
                    edge = true;
                  }
                }
                if (edge && inner) furthest = math.max(furthest, d);
              }
            }
            expect(count, greaterThan(0));
            // Never nearer the outside than the inset (a square corner in a
            // round one comes nearer)...
            expect(nearest, greaterThanOrEqualTo(t - .25));
            // ...and along its edge never further off (a well that stops short
            // of the outline at the end, or rounds more than the frame).
            expect(furthest, lessThanOrEqualTo(t + 2.25));
          }, tags: const ['goldens']);
        }
      }
    }
  }
}
