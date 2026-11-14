// What a walk of the web build found (11-12: every gallery page in a browser at 1440 and 600) and what holds it. The
// other tests pumped a gallery page alone; the web build opens it from Quill's index, inside Quill's frame (beside the
// rail from 600, the side bar from 1024), and so does every test here.
// - every example of a section starts on its column's edge (design6 P: an example centred in its column, or set at
//   its end, while every other starts on the edge, is off);
// - a word is never broken across two lines (a phone preview that took the side bar's reach for its own broke
//   "Spending"; tiles squeezed into a measure broke "Groceries");
// - from 600 a category tile, a glyph round and a way keep to their content from the column's start, never filling
//   the column; a phone's share it;
// - a sheet's acts span their card on a phone (its one act too); from 600 each keeps to 320 (ui_core's
//   DesignWidthCheck), the row on the card's trailing end, the confirm last: a dialog's two share it, its one stands
//   at its end, as a tablet's bottom sheet's do.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:convert';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';
import 'package:ledger_ui/ledger_host.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/quill/quill.dart';

Future<void> _loadFonts() async {
  final manifest = json.decode(
    await rootBundle.loadString('FontManifest.json'),
  ) as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = entry['family'] as String;
    final loader = FontLoader(
      family.startsWith('packages/') ? family : ledgerFontFamily(family),
    );
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      loader.addFont(rootBundle.load(font['asset'] as String));
    }
    await loader.load();
  }
}

Future<void> _rest(WidgetTester t) async {
  for (var i = 0; i < 4; i++) {
    await t.pump(const Duration(milliseconds: 400));
  }
}

Rect _global(RenderBox b, Rect r) =>
    MatrixUtils.transformRect(b.getTransformTo(null), r);

/// [r] of [b] on screen as its upright box: where it lands and how large, a turn left out. A seal pressed 4° off
/// square draws a round whose edge is its box's edge; the turned box's corners, which draw nothing, reach past it.
Rect _upright(RenderBox b, Rect r) {
  final m = b.getTransformTo(null);
  final scale = math.sqrt(
    m.storage[0] * m.storage[0] + m.storage[1] * m.storage[1],
  );
  return Rect.fromCenter(
    center: MatrixUtils.transformPoint(m, r.center),
    width: r.width * scale,
    height: r.height * scale,
  );
}

GalleryPage _page(String id) => galleryPages.firstWhere((p) => p.id == id);

/// Opens [page] from Quill's index at [size], as the web build's `?part=` does, the window then grown to hold its
/// whole scroll.
Future<void> _open(WidgetTester t, GalleryPage page, Size size) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  await t.pumpWidget(
    QuillApp(
      key: UniqueKey(),
      parts: [for (final p in galleryPages) (title: p.title, build: p.build)],
      initialPart: galleryPages.indexOf(page),
    ),
  );
  await _rest(t);
  var extent = 0.0;
  for (final s in t.stateList<ScrollableState>(find.byType(Scrollable))) {
    final p = s.position;
    if (p.axis == Axis.vertical && p.hasContentDimensions) {
      extent = math.max(extent, p.maxScrollExtent);
    }
  }
  if (extent > 0) {
    t.view.physicalSize = Size(
      size.width,
      math.min(16000, size.height + extent),
    );
    await _rest(t);
  }
}

bool _shown(RenderObject o) {
  for (RenderObject? r = o; r != null; r = r.parent) {
    if (r is RenderOpacity && r.opacity == 0) return false;
    if (r is RenderAnimatedOpacity && r.opacity.value == 0) return false;
    if (r is RenderOffstage && r.offstage) return false;
  }
  return true;
}

/// Whether [d] draws a face a person sees as an edge: a fill other than the page's [paper], a picture, or a rule on
/// its start side, above or under it (a strip ruled above and under starts where its rules start).
bool _drawsAnEdge(Decoration d, Color paper) {
  if (d is ShapeDecoration) return true;
  if (d is! BoxDecoration) return false;
  final fill = d.color;
  if (fill != null && fill.a > .02 && fill != paper) return true;
  if (d.gradient != null || d.image != null) return true;
  final sides = switch (d.border) {
    final Border b => [b.left, b.top, b.bottom],
    final BorderDirectional b => [b.start, b.top, b.bottom],
    _ => const <BorderSide>[],
  };
  return sides.any(
    (side) =>
        side.style != BorderStyle.none && side.width > 0 && side.color.a > .02,
  );
}

/// The left of what [root] paints: a word's first glyph box, a face that draws an edge, a drawing, a picture; each cut
/// to the clips between it and [root]. Null when it paints none of these.
double? _inkLeft(RenderBox root, Color paper) {
  double? least;
  void take(Rect r, RenderObject o) {
    var rect = r;
    for (
      RenderObject? a = o.parent;
      a != null && a != root.parent;
      a = a.parent
    ) {
      if (a is RenderClipRect || a is RenderClipRRect || a is RenderClipPath) {
        final b = a as RenderBox;
        rect = rect.intersect(_global(b, Offset.zero & b.size));
      }
    }
    if (rect.width <= 0 || rect.height <= 0) return;
    least = least == null ? rect.left : math.min(least!, rect.left);
  }

  void visit(RenderObject o) {
    if (!_shown(o)) return;
    if (o is RenderBox && o.hasSize) {
      final box = Offset.zero & o.size;
      if (o is RenderParagraph) {
        final text = o.text.toPlainText();
        if (text.trim().isNotEmpty) {
          for (final b in o.getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )) {
            take(_upright(o, b.toRect()), o);
          }
        }
      } else if (o is RenderDecoratedBox && _drawsAnEdge(o.decoration, paper)) {
        take(_upright(o, box), o);
      } else if (o is RenderPhysicalModel ||
          o is RenderPhysicalShape ||
          o is RenderImage) {
        take(_upright(o, box), o);
      } else if (o is RenderCustomPaint &&
          (o.painter != null || o.foregroundPainter != null)) {
        take(_upright(o, box), o);
      }
    }
    o.visitChildren(visit);
  }

  visit(root);
  return least;
}

/// Sections whose example stands off the column's edge by design, with the reason.
const Map<String, String> _offTheEdge = {
  "Home's watermark, behind its column":
      'a backdrop stands centred behind the column it is drawn behind',
  'Swipe, trailing':
      'the example is a row swiped open: its words slid out under its start, its figure and its acts at its end, as '
      'a swipe leaves it',
  "A tab's bar":
      "page chrome, as a page stands it: on a phone the strip's words stand its own 24 in (its fill and rule on the "
      "edge); at desktop width a tab's masthead holds its search and bell at its end, its title the page's own",
  'As a pushed page draws it':
      "page chrome: at desktop width the crumb's chevron hangs 4 into the gutter, so its stroke (4 inside its glyph's "
      'box) stands on the edge; this test reads the box',
  'Action bar, docked':
      'a docked band runs its rule edge to edge, as on a screen: past the column by its own 24 gutter, so its total '
      'and its act stand on the column\'s edges',
  'Action bar, alone': 'the same band, alone: its rule past the column by its gutter, its words on the column\'s edges',
  'A counter':
      'a rolling figure gives each digit the widest digit\'s place, so the figure never shivers as it rolls; a narrow '
      'leading 1 stands in the middle of its place, 4 in, as a tabular figure\'s does',
};

/// Where an example of a section does not start on its column's edge.
List<String> _offEdge(WidgetTester t, String where) {
  final found = <String>[];
  final paper = t.element(find.byType(QuillFrame)).ledgerTheme.background;
  final sections = find.byWidgetPredicate(
    (w) =>
        w is KeyedSubtree &&
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('kit-section:'),
  );
  for (final e in sections.evaluate()) {
    final label = ((e.widget as KeyedSubtree).key! as ValueKey<String>).value
        .substring('kit-section:'.length);
    if (_offTheEdge.containsKey(label)) continue;
    final column = e.renderObject;
    if (column is! RenderFlex || !column.hasSize) continue;
    final edge = _global(column, Offset.zero & column.size).left;
    var i = 0;
    for (
      var c = column.firstChild;
      c != null;
      c = (c.parentData! as FlexParentData).nextSibling, i++
    ) {
      final left = _inkLeft(c, paper);
      if (left == null) continue;
      if ((left - edge).abs() > 1) {
        found.add(
          '$where · "$label" #$i starts ${(left - edge).toStringAsFixed(1)} from its column\'s edge',
        );
      }
    }
  }
  return found;
}

/// Every wrapping paragraph on screen whose longest word is wider than its box: a word broken across two lines. A
/// paragraph held to one line never breaks one (a bar's title is cut with its ellipsis instead).
List<String> _brokenWords(WidgetTester t, String where) => [
  for (final e in find.byType(RichText).evaluate())
    if (e.renderObject case final RenderParagraph p
        when p.hasSize &&
            p.softWrap &&
            p.maxLines != 1 &&
            _shown(p) &&
            p.getMinIntrinsicWidth(double.infinity) > p.size.width + .5)
      '$where · "${p.text.toPlainText().replaceAll('\n', ' ')}" breaks a word: its longest needs '
          '${p.getMinIntrinsicWidth(double.infinity).toStringAsFixed(1)}, its box is ${p.size.width.toStringAsFixed(1)}',
];

void main() {
  setUpAll(_loadFonts);

  for (final width in const [600.0, 1024.0, 1440.0]) {
    testWidgets(
      'every gallery page at ${width.round()}, opened from Quill\'s index: each example starts on its '
      'column\'s edge, and no word is broken',
      (t) async {
        addTearDown(t.view.reset);
        final found = <String>[];
        for (final page in galleryPages) {
          await _open(t, page, Size(width, 900));
          final where = '${page.id} ${width.round()}';
          found
            ..addAll(_offEdge(t, where))
            ..addAll(_brokenWords(t, where));
        }
        expect(found, isEmpty, reason: found.join('\n'));
      },
      timeout: const Timeout(Duration(minutes: 10)),
    );
  }

  testWidgets(
    'no word is broken at 390 either, on any gallery page opened from Quill\'s index',
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final page in galleryPages) {
        await _open(t, page, const Size(390, 844));
        found.addAll(_brokenWords(t, '${page.id} 390'));
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
    timeout: const Timeout(Duration(minutes: 10)),
  );

  testWidgets(
    'from 600 a category tile, a glyph round and a way keep to their content, from the column\'s start',
    (t) async {
      addTearDown(t.view.reset);
      final found = <String>[];
      for (final width in const [600.0, 1024.0, 1440.0, 1920.0]) {
        await _open(t, _page('choices'), Size(width, 900));
        final at = '${width.round()}';
        Rect rect(Element e) =>
            t.getRect(find.byElementPredicate((x) => identical(x, e)));

        final tiles = find
            .byType(LedgerCategoryTile)
            .evaluate()
            .map(rect)
            .toList();
        final holder = t.getRect(find.byType(LedgerCategoryTiles).first);
        if (tiles.isEmpty) found.add('$at: no category tiles');
        for (final r in tiles) {
          if (r.width > LedgerCategoryTiles.tile + .5) {
            found.add('$at: a category tile ${r.width} wide');
          }
        }
        if (tiles.isNotEmpty &&
            (tiles.map((r) => r.left).reduce(math.min) - holder.left).abs() >
                .5) {
          found.add(
            '$at: the tiles start ${tiles.map((r) => r.left).reduce(math.min) - holder.left} in',
          );
        }

        final picker = t.getRect(find.byType(LedgerIconPicker).first);
        final rounds =
            find
                .descendant(
                  of: find.byType(LedgerIconPicker).first,
                  matching: find.byType(LedgerPressable),
                )
                .evaluate()
                .map(rect)
                .toList()
              ..sort(
                (a, b) => (a.top - b.top).abs() > 1
                    ? a.top.compareTo(b.top)
                    : a.left.compareTo(b.left),
              );
        for (var i = 0; i + 1 < rounds.length; i++) {
          final (a, b) = (rounds[i], rounds[i + 1]);
          if ((a.top - b.top).abs() > 1) continue;
          if ((b.left - a.right - 16).abs() > .5) {
            found.add(
              '$at: two glyph rounds ${b.left - a.right} apart, not 16',
            );
          }
        }
        if (rounds.isNotEmpty && (rounds.first.left - picker.left).abs() > .5) {
          found.add(
            '$at: the glyph rounds start ${rounds.first.left - picker.left} in',
          );
        }

        final holderWays = t.getRect(find.byType(LedgerWays).first);
        final ways = find
            .descendant(
              of: find.byType(LedgerWays).first,
              matching: find.byType(LedgerPressable),
            )
            .evaluate()
            .map(rect)
            .reduce((a, b) => a.expandToInclude(b));
        final perLine = width >= LedgerLayout.wide ? 4 : 2;
        if (ways.width > perLine * LedgerWays.cell + .5) {
          found.add(
            '$at: the ways ${ways.width} across, past $perLine of ${LedgerWays.cell}',
          );
        }
        if ((ways.left - holderWays.left).abs() > .5) {
          found.add('$at: the ways start ${ways.left - holderWays.left} in');
        }
      }
      expect(found, isEmpty, reason: found.join('\n'));
    },
  );

  testWidgets("a sheet's acts span their card on a phone; from 600 each keeps to 320, the row on the card's trailing "
      'end, sharing a dialog where they fill it', (t) async {
    addTearDown(t.view.reset);
    final found = <String>[];
    for (final (window, card) in const [
      (390.0, 390.0),
      (768.0, 768.0),
      (1440.0, 440.0),
    ]) {
      for (final acts in const [1, 2]) {
        t.view.physicalSize = Size(window, 900);
        t.view.devicePixelRatio = 1;
        await t.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            builder: (context, page) =>
                LedgerHost(brightness: Brightness.light, child: page!),
            home: Align(
              alignment: Alignment.bottomLeft,
              child: SizedBox(
                width: card,
                child: LedgerSheetShell(
                  title: 'Freeze your card?',
                  foot: [
                    if (acts == 2) LedgerButton('Cancel', onPressed: () {}),
                    LedgerButton.ink('Freeze card', onPressed: () {}),
                  ],
                  children: const [
                    Text('Freezing stops the card, not the account.'),
                  ],
                ),
              ),
            ),
          ),
        );
        await t.pumpAndSettle();
        final at =
            '${window.round()} window, a $card card, $acts act${acts == 1 ? '' : 's'}';
        final shell = find.byType(LedgerSheetShell);
        final pad = LedgerSheetShell.padding(t.element(shell));
        final content = t.getRect(shell);
        final start = content.left + pad.left, end = content.right - pad.right;
        final rects = [
          for (final label in [if (acts == 2) 'Cancel', 'Freeze card'])
            t.getRect(
              find
                  .ancestor(
                    of: find.text(label),
                    matching: find.byType(LedgerButton),
                  )
                  .first,
            ),
        ];
        final row = rects.reduce((a, b) => a.expandToInclude(b));
        if (window >= LedgerLayout.measuredFrom) {
          // Each act at most 320 (ui_core's DesignWidthCheck), the row on the card's trailing end; where the acts'
          // measure fills the card (a dialog's two), they share it.
          if ((row.right - end).abs() > .5) {
            found.add(
              '$at: the acts end ${end - row.right} short of the card\'s end',
            );
          }
          for (final r in rects) {
            if (r.width > LedgerLayout.fieldMeasure + .5) {
              found.add('$at: an act ${r.width} wide');
            }
          }
          final measure =
              acts * LedgerLayout.fieldMeasure +
              (acts - 1) * LedgerChromeMetrics.buttonRowGap;
          if (measure >= end - start && (row.left - start).abs() > .5) {
            found.add(
              '$at: the acts start ${row.left - start} in, short of sharing the card',
            );
          }
        } else if ((row.left - start).abs() > .5 ||
            (row.right - end).abs() > .5) {
          found.add(
            '$at: the acts span ${row.left - start}..${end - row.right} in of the card\'s ${end - start}',
          );
        }
        if (acts == 2 && rects.first.left > rects.last.left) {
          found.add('$at: the confirm stands first');
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });
}
