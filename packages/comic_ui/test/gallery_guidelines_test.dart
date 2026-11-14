// Flutter's four accessibility guidelines on every gallery page, in every preset, by day and by night: Android's 48 px
// and iOS's 44 px tap targets, a label on every tappable node, and text contrast (4.5:1, 3:1 for large text). Each is
// evaluated on its own, so one failing never hides another.
//
// Text contrast is read twice. Flutter's guideline reads the ink from a capture at one pixel per logical pixel, where
// Shantell Sans's thin strokes at 11 to 13 px are only ever anti-aliased; it flags small words whose ink passes. Where it flags
// a page, the words are read again with their own ink (`inkedContrastFailures`), and only that reading fails the test.
// Every page is read the second way too, so no word escapes either reading.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'gallery_support.dart';
import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  // Contrast is read from the drawn pixels, which hang on the rasterizer as a golden does: each test is tagged
  // goldens, so Linux CI leaves it to the macOS goldens job (11-13).
  testWidgets('contrast reads enabled text and skips disabled semantics', (
    tester,
  ) async {
    for (final enabled in [false, true]) {
      await tester.pumpWidget(
        comicApp(
          ComicButton(
            'Low contrast',
            onPressed: enabled ? () {} : null,
            style: const ComicStyle(
              fill: WidgetStatePropertyAll(Color(0xff787878)),
              foreground: WidgetStatePropertyAll(Color(0xff777777)),
            ),
          ),
        ),
      );
      await settle(tester);
      final failed = await inkedContrastFailures(tester);
      expect(failed, enabled ? isNotEmpty : isEmpty);
    }
  }, tags: 'goldens');

  testWidgets(
    'contrast follows inherited span size, fitted scale and pixel ratio',
    (tester) async {
      addTearDown(tester.view.reset);
      for (final (size, width, ratio, passes) in [
        (28.0, 400.0, 1.0, true),
        (12.0, 400.0, 1.0, false),
        (28.0, 24.0, 1.0, false),
        (28.0, 400.0, 3.0, true),
        (12.0, 400.0, 3.0, false),
        (28.0, 24.0, 3.0, false),
      ]) {
        tester.view.devicePixelRatio = ratio;
        tester.view.physicalSize = const Size(500, 500) * ratio;
        await tester.pumpWidget(
          comicApp(
            Center(
              child: ColoredBox(
                color: const Color(0xff333333),
                child: SizedBox(
                  width: width,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text.rich(
                      TextSpan(
                        style: TextStyle(fontSize: size),
                        children: const [
                          TextSpan(
                            text: 'Inherited',
                            style: TextStyle(color: Color(0xff888888)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await settle(tester);
        expect(
          await inkedContrastFailures(tester),
          passes ? isEmpty : isNotEmpty,
          reason: 'font $size, fitted width $width, DPR $ratio',
        );
      }
    },
    tags: 'goldens',
  );

  for (final page in galleryPages) {
    for (final (preset, b) in presetsAndModes) {
      testWidgets('${page.id} in $preset ${b.name} meets the guidelines', (
        tester,
      ) async {
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
        final inked = await inkedContrastFailures(
          tester,
          diagnosticPath: 'test/failures/${page.id}_${preset}_${b.name}.png',
        );
        if (inked.isNotEmpty) {
          failed.add(
            'text contrast: ${inked.join('; ')}'
            '${pixels.passed ? '' : '\nFlutter\'s reading: ${pixels.reason}'}',
          );
        }
        expect(failed, isEmpty, reason: failed.join('\n'));
      }, tags: 'goldens');
    }
  }
}
