// A select's open menu stands on its field's full width, on paper: on the
// painted pixels of the screen, the menu's ground runs from the field's one
// edge to the other and stops there, and its doubled frame sits inside that
// ground, the same distance in from either edge. The menus are the settings
// screen's environment select, the settings page's and the fields page's,
// at a phone's width either way round and at a desk's.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

// The example's screens and pages are the ones under test.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/everyday_screens.dart';
import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';

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

  final pages = {for (final p in galleryPages) p.id: p};
  final screens = {for (final s in everydayScreens) s.id: s};
  final menus =
      <
        ({
          String id,
          Widget Function(Brightness, TextDirection) app,
          int opener,
        })
      >[
        (id: 'everyday-settings', app: screens['settings']!.app, opener: 0),
        for (final (id, opener) in const [('settings', 0), ('fields', 1)])
          (
            id: id,
            app: (Brightness b, TextDirection d) {
              kitShownDirection = d;
              return pages[id]!.build(b);
            },
            opener: opener,
          ),
      ];

  const configs = [
    (390.0, TextDirection.ltr),
    (390.0, TextDirection.rtl),
    (1440.0, TextDirection.ltr),
  ];

  for (final menu in menus) {
    for (final (width, dir) in configs) {
      final where = '${width.toInt()}${dir == TextDirection.rtl ? ' rtl' : ''}';
      testWidgets("${menu.id} at $where: the open menu's ground spans its field", (
        tester,
      ) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
        addTearDown(tester.view.reset);
        addTearDown(() => kitShownDirection = TextDirection.ltr);
        await tester.pumpWidget(menu.app(Brightness.light, dir));
        Future<void> settle() async {
          for (var i = 0; i < 16; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        await settle();
        final field = find
            .byWidgetPredicate(
              (w) =>
                  w is Semantics &&
                  w.properties.expanded == false &&
                  w.properties.enabled != false,
            )
            .at(menu.opener);
        if (field.hitTestable().evaluate().isEmpty) {
          await tester.ensureVisible(field);
          await settle();
        }
        final face = tester.getRect(field);
        final before = find.byType(TermPane).evaluate().toSet();
        await tester.tapAt(face.center);
        await settle();
        final opened = find
            .byType(TermPane)
            .evaluate()
            .where((e) => !before.contains(e))
            .toList();
        expect(opened, hasLength(1), reason: 'one menu opens');
        final pane = find.byElementPredicate(
          (e) => identical(e, opened.single),
        );
        final list = tester.getRect(pane);
        final theme = TermTheme.of(opened.single);

        // As laid out: the menu's sides are the field's.
        expect(list.left, face.left, reason: 'menu $list, field $face');
        expect(list.right, face.right, reason: 'menu $list, field $face');

        // As drawn: the screen round the field and its menu, a point of
        // page past either side.
        final crop = face.expandToInclude(list).inflate(1);
        final layer = tester.binding.renderViews.first.debugLayer!;
        final image = (await tester.runAsync(
          () => (layer as OffsetLayer).toImage(crop, pixelRatio: _scale),
        ))!;
        final rgba = (await tester.runAsync(
          () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
        ))!;
        final w = image.width;
        image.dispose();
        final ground = _rgba(theme.surface);
        final start = ((face.left - crop.left) * _scale).round();
        final end = ((face.right - crop.left) * _scale).round() - 1;
        int at(int x, int y) => rgba.getUint32((y * w + x) * 4);

        // Every row of the menu is its ground at the field's two edges.
        final top = ((list.top - crop.top) * _scale).round();
        final bottom = ((list.bottom - crop.top) * _scale).round();
        for (var y = top; y < bottom; y++) {
          for (final x in [start, end]) {
            expect(
              _hex(at(x, y)),
              _hex(ground),
              reason:
                  'row ${y / _scale + crop.top}, x ${x / _scale + crop.left}',
            );
          }
        }

        // Across its middle, the ground stops at the field's edges, and
        // from either edge in: the ground, the frame's outer line, the
        // ground between the two lines, the inner line, the same widths
        // each side.
        final y = ((list.center.dy - crop.top) * _scale).floor();
        expect(_hex(at(start - 1, y)), isNot(_hex(ground)));
        expect(_hex(at(end + 1, y)), isNot(_hex(ground)));
        final fromStart = _runs(rgba, w, y, start, 1, 4);
        final fromEnd = _runs(rgba, w, y, end, -1, 4);
        final reason =
            'from the left ${[for (final r in fromStart) '${_hex(r.rgba)} x ${r.length}']}, '
            'from the right ${[for (final r in fromEnd) '${_hex(r.rgba)} x ${r.length}']}';
        expect(fromStart, fromEnd, reason: reason);
        expect(fromStart, hasLength(4), reason: reason);
        final [outerGap, outer, innerGap, inner] = fromStart;
        expect(outerGap.rgba, ground, reason: reason);
        expect(innerGap.rgba, ground, reason: reason);
        expect(outer.rgba, isNot(ground), reason: reason);
        expect(inner.rgba, outer.rgba, reason: reason);
      });
    }
  }
}
