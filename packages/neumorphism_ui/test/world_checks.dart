// Checks a design system's tests run on its screens and parts, so every look
// tests the same way: right to left, at twice the text size, and against
// Flutter's accessibility guidelines. Copy this file into your package's
// test/ folder; it needs only flutter_test.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pumps [build] left to right, then right to left, and expects each of
/// [parts] mirrored: its right edge's distance from the screen's right in
/// right to left is its left edge's distance from the screen's left in left
/// to right, its top unmoved, its size the same, within [tolerance] logical
/// pixels. [build] is given the direction to lay out in (put it in the
/// app's `Directionality`, or give it as the locale's).
///
/// ```dart
/// await expectMirrorsInRtl(
///   tester,
///   (direction) => app(direction, const MyToolbar()),
///   parts: [find.text('Back'), find.byIcon(MyIcons.share)],
/// );
/// ```
Future<void> expectMirrorsInRtl(
  WidgetTester tester,
  Widget Function(TextDirection direction) build, {
  required List<Finder> parts,
  double tolerance = 0.5,
}) async {
  Future<List<Rect>> lay(TextDirection direction) async {
    await tester.pumpWidget(build(direction));
    await _settle(tester);
    expect(
      tester.takeException(),
      isNull,
      reason: 'nothing throws or overflows ($direction)',
    );
    return [for (final part in parts) tester.getRect(part)];
  }

  final width = tester.view.physicalSize.width / tester.view.devicePixelRatio;
  final ltr = await lay(TextDirection.ltr);
  final rtl = await lay(TextDirection.rtl);
  for (var i = 0; i < parts.length; i++) {
    final l = ltr[i];
    final r = rtl[i];
    final what = 'parts[$i]';
    expect(
      width - r.right,
      moreOrLessEquals(l.left, epsilon: tolerance),
      reason:
          '$what: ${l.left} from the left in left to right, '
          '${width - r.right} from the right in right to left',
    );
    expect(
      r.top,
      moreOrLessEquals(l.top, epsilon: tolerance),
      reason: '$what: its top',
    );
    expect(
      r.size.width,
      moreOrLessEquals(l.size.width, epsilon: tolerance),
      reason: '$what: its width',
    );
    expect(
      r.size.height,
      moreOrLessEquals(l.size.height, epsilon: tolerance),
      reason: '$what: its height',
    );
  }
}

/// Pumps [app] with the platform's text scale at [textScale] (200% by
/// default) and expects nothing to overflow or throw. [app] builds its
/// `MediaQuery` from the view, as `MaterialApp`, `CupertinoApp` and
/// `WidgetsApp` do. The text scale is reset when the test ends.
Future<void> expectNoOverflowAtTextScale(
  WidgetTester tester,
  Widget app, {
  double textScale = 2.0,
}) async {
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  await tester.pumpWidget(app);
  await _settle(tester);
  expect(
    tester.takeException(),
    isNull,
    reason: 'nothing overflows or throws at text scale $textScale',
  );
}

/// Expects what is on screen to meet Flutter's four accessibility
/// guidelines: Android's 48 px and iOS's 44 px tap targets, a label on
/// every tap target, and text contrast. Pump the screen first. A look whose
/// targets are iOS's 44 px on every platform passes [android] false.
Future<void> expectMeetsGuidelines(
  WidgetTester tester, {
  bool android = true,
}) async {
  final semantics = tester.ensureSemantics();
  if (android) {
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  }
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
  semantics.dispose();
}

/// Pumps until nothing more is scheduled, or for three seconds: a part that keeps moving on purpose (a busy key's
/// spinner, a progress loop) never settles, and the checks read the screen as it stands then.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 60; i++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (!tester.binding.hasScheduledFrame) return;
  }
}
