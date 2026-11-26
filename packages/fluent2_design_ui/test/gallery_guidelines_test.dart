// Flutter's four accessibility guidelines on every gallery page, in every preset, light and dark: Android's 48 px and
// iOS's 44 px tap targets, a label on every tappable node, and text contrast (4.5:1, 3:1 for large text). Each is
// evaluated on its own, so one failing never hides another.
//
// Text contrast is read twice. Flutter's guideline reads the ink from a capture at one pixel per logical pixel, where
// Selawik's strokes at 10 to 12 px are only ever anti-aliased; it flags small words whose ink passes. Where it flags a
// page, the words are read again with their own ink (`inkedContrastFailures`), and only that reading fails the test.
// Every page is read the second way too, so no word escapes either reading.
//
// Contrast reads drawn pixels, which hang on the rasterizer as a golden does: it is tagged `goldens` (run on macOS,
// left out of `flutter test --exclude-tags goldens` elsewhere); the targets read only semantics and run everywhere.
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'tiers.dart';

void main() {
  setUpAll(loadFluent2TestFonts);

  // Every run checks the targets on each page in the first preset (leak tracked, so each page's disposal is held),
  // light and dark in turn, and each other preset once, on pages spread over the gallery, the other way; the sweep,
  // the rest.
  final presets = Fluent2ThemeData.presets;
  final step = galleryPages.length ~/ (presets.length - 1);
  for (final (i, page) in galleryPages.indexed) {
    final mode = Brightness.values[i % 2];
    final k = i ~/ step;
    final other = i % step == 0 && k < presets.length - 1
        ? presets[1 + k]
        : null;
    for (final (preset, b) in presetsAndModes) {
      final everyday =
          (preset == presets.first && b == mode) ||
          (preset == other && b != mode);
      testWidgets(
        '${page.id} in $preset ${b.name} meets the target guidelines',
        experimentalLeakTesting: leakTestingIn(preset),
        tags: sweepUnless(everyday),
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, preset, b);
            final failed = <String>[];
            for (final (name, guideline) in [
              ('40 px targets (the floor)', touchFloorGuideline),
              ('labelled targets', labeledTapTargetGuideline),
            ]) {
              final result = await guideline.evaluate(tester);
              if (!result.passed) failed.add('$name: ${result.reason}');
            }
            expect(failed, isEmpty, reason: failed.join('\n'));
          } finally {
            semantics.dispose();
          }
        },
      );

      testWidgets(
        '${page.id} in $preset ${b.name} meets the text contrast guideline',
        experimentalLeakTesting: leakTestingIn(preset),
        (tester) async {
          final semantics = tester.ensureSemantics();
          try {
            await pumpGalleryPage(tester, page, preset, b);
            final pixels = await textContrastGuideline.evaluate(tester);
            final inked = await inkedContrastFailures(tester);
            expect(
              inked,
              isEmpty,
              reason:
                  'text contrast: ${inked.join('; ')}'
                  '${pixels.passed ? '' : '\nFlutter\'s reading: ${pixels.reason}'}',
            );
          } finally {
            semantics.dispose();
          }
        },
        tags: const ['goldens'],
      );
    }
  }
}
