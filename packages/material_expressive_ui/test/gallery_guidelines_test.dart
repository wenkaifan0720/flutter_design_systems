// Flutter's four accessibility guidelines on every gallery page, in every preset, by day and by night: Android's 48 px
// and iOS's 44 px tap targets, a label on every tappable node, and text contrast (4.5:1, 3:1 for large text). Each is
// evaluated on its own, so one failing never hides another.
//
// Text contrast is read twice. Flutter's guideline reads the ink from a capture at one pixel per logical pixel, where
// thin strokes at 11 to 13 px are only ever anti-aliased; it flags small words whose ink passes. Where it flags
// a page, the words are read again with their own ink (`inkedContrastFailures`), and only that reading fails the test.
// Every page is read the second way too, so no word escapes either reading.
//
// Tap targets are Flutter's two guidelines, measured at the scale a node is laid out at: a page drawn inside a scaled
// device preview (the preview page shows a phone at a fraction of its size) is a picture of that phone, and its
// targets are held to the size in the phone's own pixels.
//
// Each page is two tests: the tap-target and label guidelines, read from the semantics tree, run everywhere; text
// contrast reads the drawn pixels, the rasterizer's as a golden's are, so it is tagged `goldens` (macOS runs it,
// Linux CI leaves it out).
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show precisionErrorTolerance;
import 'package:flutter/services.dart' show Brightness;
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'gallery_support.dart';

void main() {
  setUpAll(loadExpressiveFonts);

  for (final page in galleryPages) {
    for (final (preset, b) in presetsAndModes) {
      Future<void> meets(WidgetTester tester, {required bool contrast}) async {
        final semantics = tester.ensureSemantics();
        await pumpGalleryPage(tester, page, preset, b);
        final failed = await galleryGuidelineFailures(
          tester,
          page.id,
          preset,
          b,
          targets: !contrast,
          contrast: contrast,
        );
        expect(failed, isEmpty, reason: failed.join('\n'));
        semantics.dispose();
      }

      testWidgets(
        '${page.id} in $preset ${b.name} meets the guidelines',
        (tester) => meets(tester, contrast: false),
      );
      testWidgets(
        '${page.id} in $preset ${b.name} meets the text contrast guideline',
        (tester) => meets(tester, contrast: true),
        tags: const ['goldens'],
      );
    }
  }
}

/// Words Compose itself writes short of 4.5:1 in one of the five presets, held as Compose draws them: a tonal outlined
/// field's placeholder is `onSurfaceVariant` on `onPrimary` (`OutlinedTextFieldDefaults.tonalColors()`), a pair the
/// scheme does not tune, and ember's dark scheme leaves it at 4.24:1. The lead's call (DECISIONS.md); every other
/// word on every page meets its ratio.
const _composePairs = {
  (
    'text-fields',
    'ember',
    Brightness.dark,
    '"Search your trips" 4.24:1 (needs 4.5) ink #d1a181 on #6d3415',
  ),
};

final _android = _LaidOutTapTargetGuideline(androidTapTargetGuideline);
final _iOS = _LaidOutTapTargetGuideline(iOSTapTargetGuideline);

/// [of]'s guideline, except that a node drawn smaller than it is laid out (under a transform that scales it down)
/// is held to the size in its own coordinates.
class _LaidOutTapTargetGuideline extends MinimumTapTargetGuideline {
  _LaidOutTapTargetGuideline(AccessibilityGuideline of)
    : super(size: (of as MinimumTapTargetGuideline).size, link: of.link);

  @override
  bool shouldSkipNode(SemanticsNode node) {
    if (super.shouldSkipNode(node)) return true;
    for (SemanticsNode? n = node; n != null; n = n.parent) {
      if (_planeScale(n.transform) < 1 - precisionErrorTolerance) {
        final own = node.rect.size;
        return own.width >= size.width - precisionErrorTolerance &&
            own.height >= size.height - precisionErrorTolerance;
      }
    }
    return false;
  }
}

/// The smaller of [t]'s scales along x and y (a node's transform scales the plane; its z scale is always 1).
double _planeScale(Matrix4? t) {
  if (t == null) return 1;
  final m = t.storage;
  return math.min(
    math.sqrt(m[0] * m[0] + m[1] * m[1]),
    math.sqrt(m[4] * m[4] + m[5] * m[5]),
  );
}

/// Evaluates all four guidelines using the same pixel/ink and preview policy: the tap-target and label ones from the
/// semantics tree ([targets]), text contrast from the drawn pixels ([contrast]; only in a `goldens` test).
Future<List<String>> galleryGuidelineFailures(
  WidgetTester tester,
  String pageId,
  String preset,
  Brightness b, {
  bool targets = true,
  bool contrast = true,
}) async {
  final failed = <String>[];
  for (final (name, guideline) in [
    if (targets) ('Android 48 px targets', _android),
    if (targets) ('iOS 44 px targets', _iOS),
    if (targets) ('labelled targets', labeledTapTargetGuideline),
  ]) {
    final result = await guideline.evaluate(tester);
    if (!result.passed) failed.add('$name: ${result.reason}');
  }
  if (!contrast) return failed;
  final pixels = await textContrastGuideline.evaluate(tester);
  final inked = (await inkedContrastFailures(tester))
      .where((f) => !_composePairs.contains((pageId, preset, b, f)))
      .toList();
  if (inked.isNotEmpty) {
    failed.add(
      'text contrast: ${inked.join('; ')}'
      '${pixels.passed ? '' : '\nFlutter\'s reading: ${pixels.reason}'}',
    );
  }
  return failed;
}
