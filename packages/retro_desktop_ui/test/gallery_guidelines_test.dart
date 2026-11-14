// Flutter's four accessibility guidelines on every gallery page, in every preset, by day and by night: Android's 48 px
// and iOS's 44 px tap targets, a label on every tappable node, and text contrast (4.5:1, 3:1 for large text). Each is
// evaluated on its own, so one failing never hides another.
//
// Text contrast is read twice. Flutter's guideline reads the ink from a capture at one pixel per logical pixel, where
// Atkinson's thin strokes at 11 to 13 px are only ever anti-aliased; it flags small words whose ink passes. Where it flags
// a page, the words are read again with their own ink (`inkedContrastFailures`), and only that reading fails the test.
// Every page is read the second way too, so no word escapes either reading.
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final page in galleryPages) {
    for (final (preset, b) in presetsAndModes) {
      testWidgets('${page.id} in $preset ${b.name} meets the guidelines', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        try {
          await pumpGalleryPage(tester, page, preset, b);
          final failed = <String>[];
          for (final (name, guideline) in [
            ('Android 48 px targets', androidTapTargetGuideline),
            ('iOS 44 px targets', iOSTapTargetGuideline),
            ('labelled targets', labeledTapTargetGuideline),
          ]) {
            final result = await guideline.evaluate(tester);
            if (!result.passed) failed.add('$name: ${result.reason}');
          }
          final pixels = await textContrastGuideline.evaluate(tester);
          final inked = await inkedContrastFailures(tester);
          if (inked.isNotEmpty) {
            failed.add(
              'text contrast: ${inked.join('; ')}'
              '${pixels.passed ? '' : '\nFlutter\'s reading: ${pixels.reason}'}',
            );
          }
          expect(failed, isEmpty, reason: failed.join('\n'));
        } finally {
          semantics.dispose();
        }
      }, tags: const ['goldens']);
    }
  }
}
