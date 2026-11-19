// The lettering's marks never cut into the line above. Bangers sets its lines 0.95 of the size apart, and its plain
// capitals stand within that, but its marks reach higher: an acute 1.12 times the size, a stacked Vietnamese tone 1.38,
// a comma below 0.11 under the line. A heading in French, Spanish, a Nordic language, German or Vietnamese gets the
// least leading its own marks need, the same between every line; English keeps its tight leading. The reaches below
// are each sentence's own, measured from the bundled Bangers' outlines.
import 'dart:ui' show BoxHeightStyle;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// Each sentence with how far its tallest glyph reaches above the line and its deepest below, as a multiple of the size.
const _sentences = <(String, String, double, double)>[
  ('French', "Été à la plage, l'école", 1.118, .111),
  ('Spanish', 'Año del árbol, éxito', 1.118, .111),
  ('Nordic', 'Åland og Ærø, Øresund', .984, .111),
  ('German', 'Über Größe und Ärger', 1.018, .024),
  ('Vietnamese', 'Tiếng Việt, đất nước', 1.384, .205),
];

const _english = 'Move the page on, please';

/// [child] in a column [width] wide, its text at [scale] times.
Future<void> _show(
  WidgetTester tester,
  double scale,
  double width,
  Widget child,
) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: width, child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The distances between [p]'s lines, as multiples of its drawn size.
List<double> _pitches(RenderParagraph p) {
  final size = p.textScaler.scale(p.text.style!.fontSize!);
  final tops = {
    for (final box in p.getBoxesForSelection(
      TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
      boxHeightStyle: BoxHeightStyle.max,
    ))
      (box.top * 100).round() / 100,
  }.toList()..sort();
  return [for (var i = 1; i < tops.length; i++) (tops[i] - tops[i - 1]) / size];
}

void main() {
  setUpAll(loadComicFonts);

  for (final scale in [1.0, 3.0]) {
    for (final (language, words, top, bottom) in _sentences) {
      testWidgets(
        "a $language heading's marks clear the line above at ${scale.toInt()}00% text",
        (tester) async {
          await _show(tester, scale, 150 * scale, ComicLetters(words));
          final pitches = _pitches(
            tester.renderObject<RenderParagraph>(find.byType(RichText)),
          );
          expect(pitches, isNotEmpty, reason: 'it wraps');
          for (final pitch in pitches) {
            // The tallest mark of a line stays above the deepest glyph of the line before it.
            expect(pitch, greaterThan(top + bottom));
            // The least leading that clears them: a hair, not a jump.
            expect(pitch, lessThan(top + bottom + .1));
            // The same between every line.
            expect(pitch, closeTo(pitches.first, .001));
          }
        },
      );
    }

    testWidgets(
      'an English heading keeps its tight leading at ${scale.toInt()}00% text',
      (tester) async {
        await _show(tester, scale, 150 * scale, const ComicLetters(_english));
        final p = tester.renderObject<RenderParagraph>(find.byType(RichText));
        final pitches = _pitches(p);
        expect(pitches, isNotEmpty, reason: 'it wraps');
        for (final pitch in pitches) {
          expect(pitch, closeTo(p.text.style!.height!, .001));
        }
      },
    );

    testWidgets(
      "a cover's Vietnamese title clears its lines at ${scale.toInt()}00% text, and English keeps its leading",
      (tester) async {
        // A word a line: the box stands three pitches tall.
        Future<double> pitchOf(String words) async {
          await _show(
            tester,
            scale,
            390,
            ComicLettering(words, size: 30 * scale),
          );
          return tester.getSize(find.byType(ComicLettering)).height /
              (3 * 30 * scale);
        }

        // Đất's stacked tone reaches 1.384 above the line, Việt's dot 0.205 below it.
        expect(await pitchOf('Tiếng\nĐất\nViệt'), greaterThan(1.384 + .205));
        expect(await pitchOf('Move\nthe\npage'), closeTo(.95, .02));
      },
    );
  }
}
