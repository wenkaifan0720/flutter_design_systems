// Every list a field opens on slipway's screens and the gallery pages that
// have one hangs from its field on paper, at a phone's width either way
// round and at a desk's: on the painted pixels of the screen, its doubled
// frame sits the same distance in from its either edge, and its ground stops
// at the frame's outer line, so the list never stands on a slab wider than
// itself over the lines and words beside it. The field it hangs from stands
// on the same ground, out to the same edges. (By night ui_core's checkList
// reads these lists in list_check_test.dart; see there for paper.)
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's pages set the gallery's direction.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';
import 'field_lists.dart';

/// Device pixels a point in the pictures read here.
const _scale = 4.0;

/// One run of equal pixels along a row: its colour and its length.
typedef _Run = ({int rgba, int length});

/// The first [count] runs along row [y] of [rgba] ([width] pixels a row),
/// from [x] towards [step] (1 rightwards, -1 leftwards).
List<_Run> _runs(ByteData rgba, int width, int y, int x, int step, int count) {
  int at(int x) => rgba.getUint32((y * width + x) * 4);
  final runs = <_Run>[];
  while (runs.length < count && x >= 0 && x < width) {
    final colour = at(x);
    var length = 0;
    while (x >= 0 && x < width && at(x) == colour) {
      length++;
      x += step;
    }
    runs.add((rgba: colour, length: length));
  }
  return runs;
}

/// [colour] as the RGBA bytes a raw picture holds, read big-endian.
int _rgba(Color colour) =>
    (colour.r * 255).round() << 24 |
    (colour.g * 255).round() << 16 |
    (colour.b * 255).round() << 8 |
    (colour.a * 255).round();

String _hex(int rgba) => rgba.toRadixString(16).padLeft(8, '0');

void main() {
  setUpAll(loadFaces);

  const configs = [
    (390.0, TextDirection.ltr),
    (390.0, TextDirection.rtl),
    (1440.0, TextDirection.ltr),
  ];

  for (final t in fieldListPages) {
    for (final (width, dir) in configs) {
      final where = '${width.toInt()}${dir == TextDirection.rtl ? ' rtl' : ''}';
      testWidgets(
        "${t.id} at $where on paper: each open list's ground stops at its frame",
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          addTearDown(tester.view.reset);
          addTearDown(() => kitShownDirection = TextDirection.ltr);

          final problems = <String>[];
          await openEachFieldList(tester, () => t.app(Brightness.light, dir), (
            key,
            field,
            pane,
          ) async {
            final face = field.renderObject! as RenderBox;
            final faceRect = face.localToGlobal(Offset.zero) & face.size;
            final listBox = pane.renderObject! as RenderBox;
            final list = listBox.localToGlobal(Offset.zero) & listBox.size;
            final ground = _rgba(TermTheme.of(pane).surface);
            void fault(String what) =>
                problems.add('${t.id} $where $key: $what');

            // The screen round the field and its list, a point of page past
            // either side.
            final crop = faceRect.expandToInclude(list).inflate(1);
            final layer = tester.binding.renderViews.first.debugLayer!;
            final image = (await tester.runAsync(
              () => (layer as OffsetLayer).toImage(crop, pixelRatio: _scale),
            ))!;
            final rgba = (await tester.runAsync(
              () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
            ))!;
            final w = image.width;
            image.dispose();
            int px(double x) => ((x - crop.left) * _scale).round();
            int py(double y) => ((y - crop.top) * _scale).round();
            int at(int x, int y) => rgba.getUint32((y * w + x) * 4);
            String runs(List<_Run> r) =>
                [for (final x in r) '${_hex(x.rgba)} x ${x.length}'].join(', ');

            // No row of the list has its ground at the list's two edges: the
            // page shows there, past the frame.
            final start = px(list.left);
            final end = px(list.right) - 1;
            for (var y = py(list.top); y < py(list.bottom); y++) {
              if (at(start, y) == ground || at(end, y) == ground) {
                fault(
                  'ground at an edge of the list, row ${y / _scale + crop.top}',
                );
                return;
              }
            }

            // Across its middle, from either edge in: the page, the frame's
            // outer line, the ground between the two lines, the inner line,
            // the same widths each side.
            final y = ((list.center.dy - crop.top) * _scale).floor();
            final fromStart = _runs(rgba, w, y, start, 1, 4);
            final fromEnd = _runs(rgba, w, y, end, -1, 4);
            final across =
                'from the left ${runs(fromStart)}; from the right ${runs(fromEnd)}';
            if (fromStart.length != 4 ||
                fromStart.toString() != fromEnd.toString()) {
              fault('its frame is not the same each side: $across');
              return;
            }
            final [page, outer, between, inner] = fromStart;
            if (page.rgba == ground ||
                outer.rgba == ground ||
                outer.rgba == page.rgba ||
                between.rgba != ground ||
                inner.rgba != outer.rgba) {
              fault('not page, line, ground, line: $across');
              return;
            }

            // A field as wide as its list stands on the same ground, out to
            // the same edges: across its middle, the same page from either
            // edge, then its ground.
            if ((faceRect.left - list.left).abs() < 0.5 &&
                (faceRect.right - list.right).abs() < 0.5) {
              final fy = ((faceRect.center.dy - crop.top) * _scale).floor();
              final fieldStart = _runs(rgba, w, fy, start, 1, 2);
              final fieldEnd = _runs(rgba, w, fy, end, -1, 2);
              for (final side in [fieldStart, fieldEnd]) {
                if (side.length < 2 ||
                    side[0].rgba != page.rgba ||
                    side[0].length != page.length ||
                    side[1].rgba != ground) {
                  fault(
                    'the field does not stand on the list\'s ground: from '
                    'the left ${runs(fieldStart)}; from the right '
                    '${runs(fieldEnd)}; the list $across',
                  );
                  return;
                }
              }
            }
          });

          expect(problems, isEmpty, reason: problems.join('\n'));
        },
        // The check reads drawn pixels, which depend on the rasterizer as a
        // golden does.
        tags: const ['goldens'],
      );
    }
  }
}
