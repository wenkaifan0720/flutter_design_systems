// Every gallery page, by day and by night, against Flutter's four accessibility guidelines as every look reads them
// (ui_core's shared check, world_checks.dart): Android's 48 px and iOS's 44 px tap targets, a label on every tap
// target, and text contrast. gallery_guidelines_test.dart reads every preset too, with a second contrast reading.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/theme.dart';
import 'gallery_support.dart';
import 'support.dart';
import 'world_checks.dart';

/// Labels Flutter's contrast capture misreads, by page, each with why (the coordinator's note on world_checks,
/// 11-12). The capture reads the screen at one pixel per logical pixel and takes the two commonest colours in a
/// label's box, so a label whose strokes are thin in a box of its face's colour and another, or one turned so its box
/// takes in what is round it, reads as two grounds and not its ink. Each one's own ink is checked against the face it
/// stands on instead; the guideline still reads everything else on the page.
const _misread = <String, Map<String, String>>{
  'charts': {
    '5': "a run of steps' count: one display figure 8 px wide, read as its cell's fill and the card round the run",
  },
  'cover': {
    'ONLY 23 TO GO!': "the cover's sticker, turned: its box takes in the blue cover round the sticker",
  },
  'inventory': {
    'ISSUES': "a tree's 12 px heading, its box the row's whole width: the ground and a chosen row's fill beside it",
  },
};

void main() {
  setUpAll(loadComicFonts);

  for (final page in galleryPages) {
    for (final brightness in Brightness.values) {
      testWidgets('${page.id} by ${brightness.name} meets the guidelines', (
        tester,
      ) async {
        await pumpGalleryPage(tester, page, kitPreset, brightness);
        final misread = _misread[page.id];
        if (misread == null) {
          await expectMeetsGuidelines(tester);
          return;
        }
        // world_checks.dart's four, its contrast reading the page but for the named labels.
        final semantics = tester.ensureSemantics();
        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(
          tester,
          meetsGuideline(_ContrastBut(misread.keys.toSet())),
        );
        misread.forEach((label, why) {
          final (ink, face) = _inkAndFace(tester, label);
          expect(
            _contrast(ink, face),
            greaterThanOrEqualTo(4.5),
            reason: '"$label" ($why): its ink $ink on its face $face',
          );
        });
        semantics.dispose();
        // Contrast is read from the drawn pixels: the rasterizer's, as a golden's (Linux CI leaves it to macOS).
      }, tags: 'goldens');
    }
  }
}

/// Flutter's [textContrastGuideline], but for the nodes labelled [misread].
class _ContrastBut extends AccessibilityGuideline {
  const _ContrastBut(this.misread);

  final Set<String> misread;

  @override
  String get description => textContrastGuideline.description;

  @override
  FutureOr<Evaluation> evaluate(WidgetTester tester) async {
    final read = await textContrastGuideline.evaluate(tester);
    if (read.passed) return read;
    // One failure a node, each starting with the node it read.
    final kept = read.reason!
        .split(RegExp(r'\n(?=SemanticsNode#)'))
        .where((r) => !misread.any((label) => r.contains('label: "$label"')))
        .toList();
    return kept.isEmpty
        ? const Evaluation.pass()
        : Evaluation.fail(kept.join('\n'));
  }
}

/// The ink of the one paragraph reading [label] and the fill of the nearest face round it.
(Color, Color) _inkAndFace(WidgetTester tester, String label) {
  final paragraphs = tester.allRenderObjects
      .whereType<RenderParagraph>()
      .where((p) => p.text.toPlainText() == label)
      // allRenderObjects lists the one paragraph twice here.
      .toSet()
      .toList();
  expect(paragraphs, hasLength(1), reason: 'one paragraph reads "$label"');
  final paragraph = paragraphs.single;
  final ink = paragraph.text.style?.color;
  expect(ink, isNotNull, reason: '"$label" names its ink');
  for (RenderObject? up = paragraph.parent; up != null; up = up.parent) {
    if (up is! RenderDecoratedBox) continue;
    final fill = switch (up.decoration) {
      BoxDecoration(:final color) => color,
      ShapeDecoration(:final color) => color,
      _ => null,
    };
    if (fill != null && fill.a == 1) return (ink!, fill);
  }
  fail('"$label" stands on no filled face');
}

double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}
