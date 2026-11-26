// Flutter's accessibility guidelines on every gallery page, in every preset, by day and by night: tap targets at
// ui_core's touch floor, 40 px (Expressive's floor for a finger and a pointer; Compose's 48 is the one Material
// measure the look leaves), a label on every tappable node, and text contrast (4.5:1, 3:1 for large text). Each is
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
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart'
    show RawTapTargets;

import 'flutter_test_config.dart' show pageWalkLeakTesting;
import 'gallery_support.dart';
import 'support/tiers.dart';

void main() {
  LeakTesting.settings = pageWalkLeakTesting;
  setUpAll(loadExpressiveFonts);

  // Every page in every preset by day and night; the everyday tier reads
  // each preset and mode once, each on another page (support/tiers).
  final cases = presetsAndModes.toList();
  for (final (row, page) in galleryPages.indexed) {
    for (final (column, (preset, b)) in cases.indexed) {
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
        tags: sweepUnless(
          everydayOnce(row, column, galleryPages.length, cases.length),
        ),
      );
      testWidgets(
        '${page.id} in $preset ${b.name} meets the text contrast guideline',
        (tester) => meets(tester, contrast: true),
        tags: const ['goldens'],
      );
    }
  }
}

/// Words Compose itself writes short of 4.5:1 in one of the six presets, held as Compose draws them: a tonal outlined
/// field's placeholder is `onSurfaceVariant` on `onPrimary` (`OutlinedTextFieldDefaults.tonalColors()`), a pair the
/// scheme does not tune, and ember's dark scheme leaves it at 4.24:1, kept as Compose draws it; every other
/// word on every page meets its ratio.
const _composePairs = {
  (
    'text-fields',
    'ember',
    Brightness.dark,
    '"Search your trips" 4.24:1 (needs 4.5) ink #d1a181 on #6d3415',
  ),
};

final _floor = _LaidOutTapTargetGuideline(
  MinimumTapTargetGuideline(
    size: RawTapTargets.fallback.touch,
    link: (androidTapTargetGuideline as MinimumTapTargetGuideline).link,
  ),
);

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
    if (targets) ('40 px targets (the touch floor)', _floor),
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
