// The typed-confirmation field in Slipway's delete question has its frame
// closed on all four sides: on the painted pixels of the screen, each side
// of the field's line is drawn from corner to corner, whether the field has
// the focus or not, on paper and at night, as a phone's sheet and a desk's
// dialog, either way round, and at twice the text size, where the question
// is taller than the sheet's body.
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's flows are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import '../example/lib/kit_gallery/slipway.dart';
import 'faces.dart';

/// Device pixels a point in the pictures read here.
const _scale = 4.0;

String _hex(int rgba) => rgba.toRadixString(16).padLeft(8, '0');

Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 16; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUpAll(loadFaces);

  for (final width in [390.0, 1440.0]) {
    for (final brightness in Brightness.values) {
      for (final direction in TextDirection.values) {
        for (final scale in [1.0, 2.0]) {
          for (final focused in [false, true]) {
            final where =
                '${width.toInt()}, ${brightness.name}, ${direction.name}, '
                'text x${scale.toInt()}, ${focused ? 'focused' : 'unfocused'}';
            testWidgets(
              'the typed confirmation is framed on four sides at $where',
              (tester) async {
                tester.view.devicePixelRatio = 1;
                tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
                addTearDown(tester.view.reset);
                kitTextScale = scale;
                addTearDown(() => kitTextScale = 1);
                await tester.pumpWidget(
                  slipwayApp(
                    brightness,
                    direction: direction,
                    place: SlipwayPlace.confirm,
                  ),
                );
                await _settle(tester);
                final dialog = find.byType(TermConfirmDialog);
                final input = find.descendant(
                  of: dialog,
                  matching: find.byType(EditableText),
                );
                // A desk's dialog opens with the field focused, a phone's sheet
                // without.
                final node = tester.widget<EditableText>(input).focusNode;
                if (focused && !node.hasFocus) {
                  await tester.showKeyboard(input);
                  await _settle(tester);
                } else if (!focused && node.hasFocus) {
                  node.unfocus();
                  await _settle(tester);
                }
                expect(node.hasFocus, focused);
                final frame = find.descendant(
                  of: find.descendant(
                    of: dialog,
                    matching: find.byType(TermTextField),
                  ),
                  matching: find.byWidgetPredicate(
                    (w) => w is CustomPaint && w.painter is TermFramePainter,
                  ),
                );
                final field = tester.getRect(frame.first);
                final painter =
                    tester.widget<CustomPaint>(frame.first).painter!
                        as TermFramePainter;
                final grid = painter.grid;

                // As laid out: the field stands whole in the pane, out of the
                // message's scroll, which ends above it.
                final pane = tester.getRect(
                  find
                      .descendant(of: dialog, matching: find.byType(TermPane))
                      .first,
                );
                final body = tester.getRect(
                  find.descendant(
                    of: dialog,
                    matching: find.byType(SingleChildScrollView),
                  ),
                );
                expect(
                  pane.intersect(field),
                  field,
                  reason: 'field $field, pane $pane',
                );
                expect(
                  body.bottom,
                  lessThanOrEqualTo(field.top),
                  reason: 'field $field, message $body',
                );

                // As drawn: each side, sampled along its length, has its line
                // within a cell's or a line's middle, where the painter puts it.
                final crop = field.inflate(1);
                final layer = tester.binding.renderViews.first.debugLayer!;
                final image = (await tester.runAsync(
                  () =>
                      (layer as OffsetLayer).toImage(crop, pixelRatio: _scale),
                ))!;
                final rgba = (await tester.runAsync(
                  () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
                ))!;
                final w = image.width, h = image.height;
                image.dispose();
                int at(double x, double y) {
                  final px = ((x - crop.left) * _scale).round().clamp(0, w - 1);
                  final py = ((y - crop.top) * _scale).round().clamp(0, h - 1);
                  return rgba.getUint32((py * w + px) * 4);
                }

                final cw = grid.cellWidth, lh = grid.lineHeight;
                // The ground inside the frame, between its line and the words.
                final ground = at(
                  direction == TextDirection.ltr
                      ? field.left + cw * 1.25
                      : field.right - cw * 1.25,
                  field.top + lh * 1.5,
                );
                // Whether a line crosses the span from [a] to [b].
                bool drawn(Offset a, Offset b) {
                  const steps = 48;
                  for (var i = 0; i <= steps; i++) {
                    final p = Offset.lerp(a, b, i / steps)!;
                    if (at(p.dx, p.dy) != ground) return true;
                  }
                  return false;
                }

                final reach = cw / 2;
                final mid = Rect.fromLTRB(
                  field.left + cw / 2,
                  field.top + lh / 2,
                  field.right - cw / 2,
                  field.bottom - lh / 2,
                );
                // The top line is cut for the label; the rest of it, and the
                // other three sides, run unbroken.
                final gaps = [
                  for (final g in painter.topGaps)
                    direction == TextDirection.ltr
                        ? (field.left + g.start, field.left + g.end)
                        : (field.right - g.end, field.right - g.start),
                ];
                bool inGap(double x) => gaps.any((g) => x >= g.$1 && x <= g.$2);
                final failures = <String>[];
                for (var i = 1; i < 12; i++) {
                  final x = mid.left + (mid.right - mid.left) * i / 12;
                  final y = mid.top + (mid.bottom - mid.top) * i / 12;
                  if (!inGap(x) &&
                      !drawn(
                        Offset(x, mid.top - reach),
                        Offset(x, mid.top + reach),
                      )) {
                    failures.add('top at x $x');
                  }
                  if (!drawn(
                    Offset(x, mid.bottom - reach),
                    Offset(x, mid.bottom + reach),
                  )) {
                    failures.add('bottom at x $x');
                  }
                  if (!drawn(
                    Offset(mid.left - reach, y),
                    Offset(mid.left + reach, y),
                  )) {
                    failures.add('left at y $y');
                  }
                  if (!drawn(
                    Offset(mid.right - reach, y),
                    Offset(mid.right + reach, y),
                  )) {
                    failures.add('right at y $y');
                  }
                }
                expect(
                  failures,
                  isEmpty,
                  reason: 'field $field, ground ${_hex(ground)}',
                );
              },
            );
          }
        }
      }
    }
  }
}
