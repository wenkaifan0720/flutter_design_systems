// A glyph beside a title or a label (design6 P, added 11-11 noon, from the user's review of another look's window
// title): the glyph's middle on the label's capitals' middle, both on the row's centre line, within half a device
// pixel. Read from the drawn pixels at a desk's device pixel ratio, on the Overview, every Hearth screen and every
// gallery page, at a phone's and a desk's width, at each density the gallery offers.
//
// A pair is an icon and the one line of words beside it in the same row (a button's, a chip's, a rail's destination, a
// one-line list row's). A glyph beside a block of two lines (a list row's title over its meta) stands on the block's
// middle, not the title's, and is left out.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

// ignore: avoid_relative_lib_imports
import '../example/lib/main.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/hearth.dart';
// ignore: avoid_relative_lib_imports
import '../example/lib/kit_gallery/live.dart';
import 'gallery_support.dart' show loadBundledFonts, settle;
import 'support.dart' show loadNeumorphicFonts;

/// A desk's screen: half a device pixel is a quarter of a logical one.
const _dpr = 2.0;
const _halfPixel = .5 / _dpr;

/// What is held: ui_core's tolerance for a label's or an icon's ink off its line (DesignLabelCheck), the engine's
/// whole-pixel baseline aside. The text engine draws every line of text, a glyph's included, with its baseline snapped
/// to a whole device pixel, so where within a pixel the capitals and the glyph land is the engine's; a pair more than
/// half a device pixel apart as drawn is listed with its numbers, and held to half a pixel once ui_core's label widget
/// puts the capitals, as drawn, on the middle.
const _tolerance = .75;

/// Capitals whose ink runs from the cap line to the baseline, flat at both (U's bowl overshoots below); then those that
/// overshoot both alike.
const _flat = 'BDEFHIKLMNPRTXZ';
const _round = 'CGOS';

bool _glyph(RenderParagraph p) =>
    (p.text.style?.fontFamily ?? '').toLowerCase().contains('lucide');

int _lines(RenderParagraph p) {
  final text = p.text.toPlainText();
  if (text.isEmpty) return 0;
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: text.length),
  );
  return {for (final b in boxes) b.top.round()}.length;
}

List<RenderParagraph> _paragraphs(RenderObject root) {
  final found = <RenderParagraph>[];
  void walk(RenderObject o) {
    if (o is RenderParagraph) found.add(o);
    o.visitChildren(walk);
  }

  walk(root);
  return found;
}

/// The row a glyph stands in: the nearest horizontal flex or fitted row above it.
RenderBox? _row(RenderObject o) {
  var p = o.parent;
  for (var n = 0; p != null && n < 8; n++, p = p.parent) {
    if (p is RenderFlex && p.direction == Axis.horizontal) return p;
    if (p is RenderNeumorphicFitRow) return p;
  }
  return null;
}

List<RenderBox> _children(RenderBox row) => [
  if (row is RenderFlex) ...row.getChildrenAsList(),
  if (row is RenderNeumorphicFitRow) ...row.getChildrenAsList(),
];

/// The part a render object belongs to, by the nearest look widget that built it.
String _owner(RenderObject o) {
  var name = '?';
  final creator = o.debugCreator;
  if (creator is DebugCreator) {
    creator.element.visitAncestorElements((e) {
      final type = '${e.widget.runtimeType}'.split('<').first;
      if (type.startsWith('Neumorphic') && type != 'NeumorphicTap') {
        name = type;
        return false;
      }
      return true;
    });
  }
  return name;
}

/// The ink's top and bottom in [r] (device pixels), with the edge rows' coverage read as fractions of a pixel.
({double top, double bottom})? _ink(ByteData px, int w, int h, Rect r) {
  final x0 = r.left.ceil().clamp(0, w - 1), x1 = r.right.floor().clamp(0, w);
  final y0 = r.top.floor().clamp(1, h - 2),
      y1 = r.bottom.ceil().clamp(1, h - 1);
  if (x1 - x0 < 1 || y1 - y0 < 2) return null;
  List<int> at(int x, int y) {
    final i = (y * w + x) * 4;
    return [px.getUint8(i), px.getUint8(i + 1), px.getUint8(i + 2)];
  }

  // The ground: the commonest colour on the rows just outside the region.
  final counts = <int, int>{};
  final colours = <int, List<int>>{};
  for (final y in [y0 - 1, y1]) {
    for (var x = x0; x < x1; x++) {
      final c = at(x, y);
      final key = (c[0] >> 2) << 12 | (c[1] >> 2) << 6 | c[2] >> 2;
      counts[key] = (counts[key] ?? 0) + 1;
      colours[key] = c;
    }
  }
  final ground =
      colours[(counts.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value)))
          .first
          .key]!;
  final d = <double>[];
  var most = 0.0;
  for (var y = y0; y < y1; y++) {
    var row = 0.0;
    for (var x = x0; x < x1; x++) {
      final c = at(x, y);
      final dist = [for (var k = 0; k < 3; k++) (c[k] - ground[k]).abs()]
          .reduce((a, b) => a > b ? a : b)
          .toDouble();
      if (dist > row) row = dist;
    }
    d.add(row);
    if (row > most) most = row;
  }
  if (most < 40) return null;
  final cover = [for (final v in d) (v / most).clamp(0.0, 1.0)];
  final first = cover.indexWhere((c) => c > .08);
  final last = cover.lastIndexWhere((c) => c > .08);
  if (first < 0) return null;
  return (
    top: y0 + first + (1 - cover[first]),
    bottom: y0 + last + cover[last],
  );
}

typedef _Pair = ({
  String owner,
  String label,
  double glyphToCaps,
  double capsToRow,
  double boxToCaps,
  double own,
  String glyph,
});

Future<List<_Pair>> _measure(WidgetTester tester, Key key) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final image = await tester.runAsync(() => boundary.toImage(pixelRatio: _dpr));
  final bytes = await tester.runAsync(
    () => image!.toByteData(format: ui.ImageByteFormat.rawRgba),
  );
  final w = image!.width, h = image.height;
  image.dispose();
  final pairs = <_Pair>[];
  final paragraphs = _paragraphs(boundary);
  for (final icon in paragraphs.where(_glyph)) {
    final row = _row(icon);
    if (row == null || !row.hasSize) continue;
    final kids = _children(row);
    RenderObject mine = icon;
    while (mine.parent != row) {
      mine = mine.parent!;
    }
    final at = kids.indexOf(mine as RenderBox);
    // The nearest neighbour that holds words, on either side.
    RenderParagraph? label;
    var blocked = false;
    for (final step in [1, -1]) {
      for (var i = at + step; i >= 0 && i < kids.length; i += step) {
        final words = _paragraphs(kids[i]);
        if (words.isEmpty) continue;
        final texts = words.where((p) => !_glyph(p)).toList();
        if (texts.length == 1 && _lines(texts.single) == 1) {
          label ??= texts.single;
        } else if (texts.isNotEmpty) {
          blocked = true;
        }
        break;
      }
      if (label != null) break;
    }
    if (label == null || blocked) continue;
    final text = label.text.toPlainText();
    var c = text.split('').indexWhere(_flat.contains);
    if (c < 0) c = text.split('').indexWhere(_round.contains);
    if (c < 0) continue;
    final box = label
        .getBoxesForSelection(TextSelection(baseOffset: c, extentOffset: c + 1))
        .first
        .toRect();
    final origin = label.localToGlobal(Offset.zero);
    final capsRect = (box.shift(origin)).deflate(.5);
    final iconRect = icon.localToGlobal(Offset.zero) & icon.size;
    final caps = _ink(
      bytes!,
      w,
      h,
      Rect.fromLTRB(
        capsRect.left * _dpr,
        capsRect.top * _dpr,
        capsRect.right * _dpr,
        capsRect.bottom * _dpr,
      ),
    );
    final glyph = _ink(
      bytes,
      w,
      h,
      Rect.fromLTRB(
        iconRect.left * _dpr,
        iconRect.top * _dpr,
        iconRect.right * _dpr,
        iconRect.bottom * _dpr,
      ),
    );
    if (caps == null || glyph == null) continue;
    final capsMid = (caps.top + caps.bottom) / 2 / _dpr;
    final glyphMid = (glyph.top + glyph.bottom) / 2 / _dpr;
    final rowRect = row.localToGlobal(Offset.zero) & row.size;
    pairs.add((
      owner: _owner(label),
      label: text,
      glyphToCaps: glyphMid - capsMid,
      capsToRow: capsMid - rowRect.center.dy,
      boxToCaps: iconRect.center.dy - capsMid,
      own: glyphMid - iconRect.center.dy,
      glyph: icon.text.toPlainText().codeUnitAt(0).toRadixString(16),
    ));
  }
  return pairs;
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadBundledFonts();
  });
  final gate = ['overview', for (final s in hearthScreens) s.id];
  final pages = [for (final p in liveGalleryPages) p.id];
  final runs = <(String, double, GalleryDensity)>[
    for (final s in gate)
      for (final width in [390.0, 1440.0])
        for (final d in [GalleryDensity.standard, GalleryDensity.compact])
          (s, width, d),
    for (final p in pages)
      if (!gate.contains(p))
        for (final d in [GalleryDensity.standard, GalleryDensity.compact])
          (p, 1440.0, d),
  ];
  for (final (screen, width, density) in runs) {
    testWidgets('glyphs beside labels $screen $width ${density.name}', (
      tester,
    ) async {
      tester.view.devicePixelRatio = _dpr;
      tester.view.physicalSize = Size(width, width < 600 ? 1400 : 1600) * _dpr;
      addTearDown(tester.view.reset);
      const key = Key('screen');
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: GalleryApp(
            initialPage: screen,
            initialCustom: GalleryCustom(density: density),
          ),
        ),
      );
      await settle(tester);
      final pairs = await _measure(tester, key);
      String say(_Pair p) =>
          '${p.owner} "${p.label}" (glyph ${p.glyph}): its ink ${p.glyphToCaps.toStringAsFixed(2)} and its box '
          '${p.boxToCaps.toStringAsFixed(2)} from the capitals, its ink ${p.own.toStringAsFixed(2)} from its own '
          'box\'s middle; the capitals ${p.capsToRow.toStringAsFixed(2)} from the row';
      // Placed off: the glyph's box or the capitals off the line, or its ink off them by more than Lucide's own
      // drawing puts it off its box (that drawing is listed below, as drawn: e1bf's ink stands 0.6 above its box).
      final off = [
        for (final p in pairs)
          if ((p.glyphToCaps - p.own).abs() > _tolerance ||
              p.boxToCaps.abs() > _tolerance ||
              p.capsToRow.abs() > _tolerance)
            say(p),
      ];
      // On the line as laid out, but more than half a device pixel off the capitals as drawn: the engine's snapped
      // baselines, and Lucide's drawing where its ink is off its own box's middle.
      final drawn = [
        for (final p in pairs)
          if (!off.contains(say(p)) && p.glyphToCaps.abs() > _halfPixel) say(p),
      ];
      // ignore: avoid_print
      print(
        'GLYPHS $screen ${width.toInt()} ${density.name}: ${pairs.length} pairs, '
        '${off.length} off${off.isEmpty ? '' : '\n  ${off.join('\n  ')}'}'
        '${drawn.isEmpty ? '' : '\n  over half a device pixel as drawn: ${drawn.join('\n  over half a device pixel as drawn: ')}'}',
      );
      expect(off, isEmpty, reason: off.join('\n'));
    }, tags: ['goldens']);
  }
}
