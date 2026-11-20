// A link's line keeps one depth along each line of its words, spaces
// included: in Arabic, where the spaces come from a shallower face than
// the words, and in English; on one line and wrapped over several; at the
// body's size and at twice it.
import 'dart:typed_data';

import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'screens_matrix.dart' show loadScreenFonts;

const _shot = ValueKey('shot');

const _arabic = 'اقرأ الإرشادات قبل أن تتقدم بطلب للحصول على تصريح';
const _english = 'Read the guidance before you apply for a permit';

/// The lines [paragraph] lays its words in, measured apart from it: by a
/// text painter given its words, style and width.
List<LineMetrics> _lines(RenderParagraph paragraph) {
  final painter = TextPainter(
    text: paragraph.text,
    textAlign: paragraph.textAlign,
    textDirection: paragraph.textDirection,
    textScaler: paragraph.textScaler,
    maxLines: paragraph.maxLines,
    locale: paragraph.locale,
    strutStyle: paragraph.strutStyle,
    textWidthBasis: paragraph.textWidthBasis,
    textHeightBehavior: paragraph.textHeightBehavior,
  )..layout(minWidth: paragraph.size.width, maxWidth: paragraph.size.width);
  final lines = painter.computeLineMetrics();
  painter.dispose();
  return lines;
}

Future<void> _show(
  WidgetTester tester,
  String words,
  TextDirection direction, {
  required double width,
  required double scale,
}) => tester.pumpWidget(
  MaterialApp(
    builder: (context, child) => CivicHost(child: child!),
    home: MediaQuery.withClampedTextScaling(
      minScaleFactor: scale,
      maxScaleFactor: scale,
      child: Directionality(
        textDirection: direction,
        child: Center(
          child: RepaintBoundary(
            key: _shot,
            // Room under the link for a line below its last line's foot.
            child: Padding(
              padding: EdgeInsets.only(bottom: 24 * scale),
              child: SizedBox(
                width: width,
                child: CivicLink(onPressed: () {}, child: Text(words)),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  setUpAll(loadScreenFonts);
  for (final (direction, words) in [
    (TextDirection.rtl, _arabic),
    (TextDirection.ltr, _english),
  ]) {
    for (final scale in [1.0, 2.0]) {
      for (final wrapped in [false, true]) {
        final name =
            '${direction.name}, ${(scale * 100).round()}% text, '
            '${wrapped ? 'wrapped' : 'one line'}';
        testWidgets('$name: one line at one depth under each line of words', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(2400, 1200);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await _show(
            tester,
            words,
            direction,
            width: wrapped ? 260 * scale : 2000,
            scale: scale,
          );
          await tester.pumpAndSettle();
          final boundary = tester.renderObject<RenderRepaintBoundary>(
            find.byKey(_shot),
          );
          final paragraph = tester.renderObject<RenderParagraph>(
            find.text(words),
          );
          final lines = _lines(paragraph);
          expect(lines, hasLength(wrapped ? greaterThan(1) : 1));
          if (direction == TextDirection.rtl) {
            // The case at hand: a space's box is shallower than its words'.
            final space = words.indexOf(' ');
            Rect box(int at) => paragraph
                .getBoxesForSelection(
                  TextSelection(baseOffset: at, extentOffset: at + 1),
                )
                .first
                .toRect();
            expect(box(space).bottom, lessThan(box(space - 1).bottom - 1));
          }
          final origin = paragraph.localToGlobal(
            Offset.zero,
            ancestor: boundary,
          );
          final (Uint8List rgba, int width, int height) = (await tester
              .runAsync(() async {
                final image = await boundary.toImage();
                final bytes = await image.toByteData();
                final out = (
                  bytes!.buffer.asUint8List(),
                  image.width,
                  image.height,
                );
                image.dispose();
                return out;
              }))!;
          // How far a pixel stands from white (its bytes are premultiplied
          // by their alpha, over nothing).
          int ink(int x, int y) {
            final i = (y * width + x) * 4;
            return 3 * 255 -
                (rgba[i] + rgba[i + 1] + rgba[i + 2] + 3 * (255 - rgba[i + 3]));
          }

          // How deep each line's words reach: their own boxes, each as deep
          // as its face (Noto Sans Arabic's past the line's foot).
          final deepest = <int, double>{};
          for (final word in RegExp(r'\S+').allMatches(words)) {
            for (final box in paragraph.getBoxesForSelection(
              TextSelection(baseOffset: word.start, extentOffset: word.end),
            )) {
              final middle = (box.top + box.bottom) / 2;
              final line = lines.indexWhere(
                (l) => middle <= l.baseline + l.descent,
              );
              deepest[line] = [
                deepest[line] ?? box.bottom,
                box.bottom,
              ].reduce((a, b) => a > b ? a : b);
            }
          }
          for (final line in lines) {
            final from = (origin.dx + line.left).ceil() + 1;
            final to = (origin.dx + line.left + line.width).floor() - 1;
            final top = (origin.dy + line.baseline).round() + 1;
            // Down to the next line's baseline, or well under the last.
            final next = line.lineNumber + 1 < lines.length
                ? lines[line.lineNumber + 1].baseline
                : line.baseline + line.descent + 12 * scale;
            final bottom = (origin.dy + next).round().clamp(0, height);
            // A row under the words that is ink from the first word's edge
            // to the last's: one line, at one depth, through every space.
            final rows = [
              for (var y = top; y < bottom; y++)
                if ([for (var x = from; x <= to; x++) ink(x, y)]
                    .every((v) => v > 60))
                  y,
            ];
            expect(
              rows,
              isNotEmpty,
              reason:
                  'line ${line.lineNumber}: an unbroken line under '
                  '${(to - from)} px of words',
            );
            expect(
              rows.last - rows.first,
              rows.length - 1,
              reason: 'line ${line.lineNumber}: one line, not two',
            );
            // Right to left Civic draws the line itself, clear of the
            // words' descenders; left to right the text engine draws it, at
            // the face's own underline position.
            if (direction == TextDirection.rtl) {
              expect(
                rows.first,
                greaterThanOrEqualTo(
                  (origin.dy + deepest[line.lineNumber]!).floor(),
                ),
                reason: 'line ${line.lineNumber}: under its deepest word',
              );
            }
          }
        });
      }
    }
  }
}
