// Reduce Motion as iOS sets it. Flutter gives iOS's setting only as the
// platform's accessibility features (`reduceMotion`), never as MediaQuery's
// `disableAnimations`, which Android and the web set. Terminal reads both,
// through ui_core's `rawReduceMotionOf`: with the iOS flag alone a spring
// settles without overshoot, the keyboard's focus is cut (no fade), the
// spinner and the caret stand still, and each follows the flag as it
// changes, with no app rebuild.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

const _bouncy = (dampingRatio: 0.4, stiffness: 400.0);

void _iosReduceMotion(WidgetTester tester, bool on) =>
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        FakeAccessibilityFeatures(reduceMotion: on);

/// The values a [TermSpring] on [_bouncy] passes through from 0 to 1.
Future<List<double>> _springTo1(WidgetTester tester, bool spatial) async {
  final seen = <double>[];
  Widget at(double target) => TermSpring(
    target: target,
    token: _bouncy,
    spatial: spatial,
    builder: (context, value, child) {
      seen.add(value);
      return const SizedBox();
    },
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(at(0));
  seen.clear();
  await tester.pumpWidget(at(1));
  for (var i = 0; i < 90; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
  return seen;
}

void main() {
  for (final spatial in [true, false]) {
    final kind = spatial ? 'spatial' : 'effects';
    testWidgets('a bouncy $kind spring overshoots, and under iOS Reduce '
        'Motion alone settles without', (tester) async {
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final free = await _springTo1(tester, spatial);
      expect(free.reduce(math.max), greaterThan(1.01));

      _iosReduceMotion(tester, true);
      final calm = await _springTo1(tester, spatial);
      expect(calm.reduce(math.max), lessThanOrEqualTo(1.0));
      expect(calm.last, closeTo(1, 0.001));
    });
  }

  testWidgets("the keyboard's focus glides in, and under iOS Reduce Motion "
      'stands at once', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var shown = 0.0;
    Widget at(double target) => TermSpring(
      target: target,
      token: TermMotion.move,
      spatial: true,
      focus: true,
      builder: (context, value, child) {
        shown = value;
        return const SizedBox();
      },
    );
    await tester.pumpWidget(at(0));
    await tester.pumpWidget(at(1));
    await tester.pump(const Duration(milliseconds: 16));
    expect(shown, inExclusiveRange(0, 0.99));
    await tester.pumpAndSettle();
    expect(shown, closeTo(1, 0.001));

    _iosReduceMotion(tester, true);
    await tester.pumpWidget(at(0));
    expect(shown, 0);
    await tester.pumpWidget(at(1));
    expect(shown, 1);
  });

  testWidgets('the spinner stands still as iOS Reduce Motion comes on, and '
      'turns again as it goes', (tester) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    var shown = -1;
    await tester.pumpWidget(
      TermStepper(
        period: const Duration(milliseconds: 100),
        builder: (context, step) {
          shown = step;
          return const SizedBox();
        },
      ),
    );
    Future<void> wait() async {
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    }

    await wait();
    expect(shown, greaterThan(0), reason: 'it turns');

    _iosReduceMotion(tester, true);
    await tester.pump();
    expect(shown, 0, reason: 'back to its first frame');
    await wait();
    expect(shown, 0, reason: 'and holds there');

    _iosReduceMotion(tester, false);
    await tester.pump();
    await wait();
    expect(shown, greaterThan(0), reason: 'it turns again');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets("a field's caret is steady under iOS Reduce Motion alone", (
    tester,
  ) async {
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await tester.pumpWidget(
      MaterialApp(
        home: TermTheme(
          data: TermThemeData.dark(),
          child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: TermTextField(labelText: 'branch'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(TermTextField));
    await tester.pump();
    // The field's own block (its painter, `_Caret`): whether it has gone
    // hollow half a second on, as a blinking caret does.
    final caret = find.byWidgetPredicate(
      (w) => w is CustomPaint && w.painter.runtimeType.toString() == '_Caret',
    );
    final block = paints
      ..rect(color: TermThemeData.dark().accent, style: PaintingStyle.fill);
    Future<bool> blinks() async {
      await tester.pump();
      expect(tester.renderObject(caret), block);
      await tester.pump(const Duration(milliseconds: 500));
      final gone = !(block as Matcher).matches(
        tester.renderObject(caret),
        <dynamic, dynamic>{},
      );
      await tester.pump(const Duration(milliseconds: 500));
      return gone;
    }

    expect(await blinks(), isTrue, reason: 'the caret, blinking');

    _iosReduceMotion(tester, true);
    await tester.pump();
    expect(await blinks(), isFalse, reason: 'a steady block in its place');

    _iosReduceMotion(tester, false);
    await tester.pump();
    expect(await blinks(), isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
