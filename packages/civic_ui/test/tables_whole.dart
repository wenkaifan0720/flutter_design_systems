// No table cell is cut, and no chart's words overlap. On a phone at twice
// the text a table too wide for the screen cuts its last columns at the
// screen's edge ("29" for 295), and a bar's value runs into its
// neighbour's; a cut number reads as a wrong number. Every paragraph in a
// table must stand wholly inside the screen and inside every clip round
// it, its words all shown; the words a chart paints must not touch.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

bool _isTable(Widget w) {
  final name = w.runtimeType.toString();
  return name == 'CivicChartTableView' || name.startsWith('CivicTable<');
}

Rect _global(RenderBox box, Rect local) =>
    MatrixUtils.transformRect(box.getTransformTo(null), local);

/// Each cell of a table on screen that is cut: its words, and how.
List<String> cutCells(WidgetTester tester) {
  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final cut = <String>[];
  final tables = find.byWidgetPredicate(_isTable).evaluate();
  for (final table in tables) {
    final paragraphs = <RenderParagraph>[];
    void visit(Element e) {
      final ro = e.renderObject;
      if (e is RenderObjectElement && ro is RenderParagraph) {
        paragraphs.add(ro);
      }
      e.visitChildElements(visit);
    }

    table.visitChildElements(visit);
    for (final p in paragraphs) {
      if (!p.attached || !p.hasSize || p.size.isEmpty) continue;
      final words = p.text.toPlainText(includeSemanticsLabels: false);
      if (words.trim().isEmpty) continue;
      final at = _global(p, Offset.zero & p.size);
      if (p.didExceedMaxLines) cut.add('$words: its lines run out');
      if (at.left < -0.5 || at.right > width + 0.5) {
        cut.add('$words: past the screen\'s edge');
        continue;
      }
      // Inside every clip round it, across (down the page it scrolls).
      for (RenderObject? up = p.parent; up != null; up = up.parent) {
        final clips =
            up is RenderClipRect ||
            up is RenderClipRRect ||
            up is RenderClipPath ||
            (up is RenderViewportBase && up.axis == Axis.horizontal);
        if (!clips || up is! RenderBox || !up.hasSize) continue;
        final room = _global(up, Offset.zero & up.size);
        if (at.left < room.left - 0.5 || at.right > room.right + 0.5) {
          cut.add('$words: cut by a ${up.runtimeType}');
          break;
        }
      }
    }
  }
  return cut;
}

/// Expects no table cell on screen to be cut.
void expectCellsWhole(WidgetTester tester, {String? where}) {
  expect(
    cutCells(tester),
    isEmpty,
    reason: 'a table cell is cut${where == null ? '' : ' in $where'}',
  );
}

/// Opens every "Show data table" fold on screen ([label] in the reader's
/// language), in turn from the top.
Future<void> openChartTables(WidgetTester tester, String label) async {
  final folds = find.text(label);
  for (var i = 0; i < folds.evaluate().length; i++) {
    final fold = folds.at(i);
    await tester.ensureVisible(fold);
    await tester.pump();
    await tester.tap(fold, warnIfMissed: false);
    for (var f = 0; f < 10; f++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }
}

/// The words each chart on screen paints, where they overlap another of
/// its words: the two, by where they stand.
List<String> overlappingChartWords(WidgetTester tester) {
  final overlaps = <String>[];
  for (final paint in tester.allRenderObjects.whereType<RenderCustomPaint>()) {
    final painter = paint.painter;
    if (painter == null || !paint.hasSize) continue;
    final name = painter.runtimeType.toString();
    if (name != '_CartesianPainter' && name != '_PiePainter') continue;
    final canvas = _WordsCanvas();
    painter.paint(canvas, paint.size);
    final words = canvas.words;
    for (var a = 0; a < words.length; a++) {
      for (var b = a + 1; b < words.length; b++) {
        // Words that touch read as one ("340355"): they stand 2 apart.
        final meet = words[a].$1.inflate(1).intersect(words[b].$1.inflate(1));
        if (meet.width > 0 && meet.height > 0) {
          overlaps.add('$name: "${words[a].$2}" and "${words[b].$2}"');
        }
      }
    }
  }
  return overlaps;
}

/// Expects no chart on screen to paint words over its other words.
void expectChartWordsApart(WidgetTester tester, {String? where}) {
  expect(
    overlappingChartWords(tester),
    isEmpty,
    reason: 'a chart\'s words overlap${where == null ? '' : ' in $where'}',
  );
}

// Keeps where each paragraph's words stand as it is drawn (a painter frees
// its words once painted): across, from its glyphs' ends; down, its lines
// as laid out (a glyph's box takes its face's whole height, which for the
// Arabic faces is twice the line's).
class _WordsCanvas extends TestRecordingCanvas {
  final words = <(Rect, String)>[];

  @override
  void drawParagraph(ui.Paragraph paragraph, Offset offset) {
    final boxes = paragraph.getBoxesForRange(0, 1 << 20);
    if (boxes.isNotEmpty) {
      var left = boxes.first.left;
      var right = boxes.first.right;
      for (final b in boxes.skip(1)) {
        left = math.min(left, b.left);
        right = math.max(right, b.right);
      }
      final at = Rect.fromLTRB(left, 0, right, paragraph.height).shift(offset);
      words.add((
        at,
        '${at.width.round()}×${at.height.round()} at '
            '(${at.left.round()}, ${at.top.round()})',
      ));
    }
    super.drawParagraph(paragraph, offset);
  }
}
