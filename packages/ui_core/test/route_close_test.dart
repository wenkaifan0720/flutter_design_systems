// The modal routes' close token: given, a dialog or a sheet closes on it;
// not given, on its open token; under Reduce Motion it fades either way; and
// a sheet dragged away carries the drag's speed into it.
import 'dart:async' show unawaited;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _page = ValueKey('page');

typedef _Make = PopupRoute<void> Function({
  double? closeDampingRatio,
  double? closeStiffness,
  ValueSetter<double>? seen,
});

// Each route on its own default open token, its page a plain box.
final _routes = <String, _Make>{
  'dialog': ({closeDampingRatio, closeStiffness, seen}) =>
      RawModalDialogRoute<void>(
        closeDampingRatio: closeDampingRatio,
        closeStiffness: closeStiffness,
        builder: (context, details) => AnimatedBuilder(
          animation: details.animation,
          builder: (context, _) {
            seen?.call(details.animation.value);
            return const Center(
              child: SizedBox(key: _page, width: 200, height: 100),
            );
          },
        ),
      ),
  'bottom sheet': ({closeDampingRatio, closeStiffness, seen}) =>
      RawBottomSheetRoute<void>(
        closeDampingRatio: closeDampingRatio,
        closeStiffness: closeStiffness,
        builder: (context, details) => const SizedBox(key: _page, height: 300),
      ),
  'side sheet': ({closeDampingRatio, closeStiffness, seen}) =>
      RawSideSheetRoute<void>(
        closeDampingRatio: closeDampingRatio,
        closeStiffness: closeStiffness,
        builder: (context, sheet) => const SizedBox.expand(key: _page),
      ),
};

const _step = Duration(milliseconds: 4);

// Pumps until [route]'s animation reaches [status]; how long it took.
Future<Duration> _until(
  WidgetTester tester,
  PopupRoute<void> route,
  AnimationStatus status,
) async {
  final animation = route.animation!;
  var elapsed = Duration.zero;
  while (animation.status != status) {
    await tester.pump(_step);
    elapsed += _step;
    if (elapsed > const Duration(seconds: 5)) fail('never $status');
  }
  return elapsed;
}

Future<NavigatorState> _app(
  WidgetTester tester, {
  bool reduceMotion = false,
}) async {
  await tester.pumpWidget(
    harness(const SizedBox.expand(), reduceMotion: reduceMotion),
  );
  return tester.state<NavigatorState>(find.byType(Navigator));
}

// How long [route] takes to open, then to close.
Future<(Duration, Duration)> _times(
  WidgetTester tester,
  PopupRoute<void> route, {
  bool reduceMotion = false,
}) async {
  final navigator = await _app(tester, reduceMotion: reduceMotion);
  unawaited(navigator.push(route));
  await tester.pump();
  final open = await _until(tester, route, AnimationStatus.completed);
  navigator.pop();
  await tester.pump();
  final close = await _until(tester, route, AnimationStatus.dismissed);
  await tester.pumpAndSettle();
  return (open, close);
}

void main() {
  for (final MapEntry(key: name, value: make) in _routes.entries) {
    group(name, () {
      testWidgets('with no close token it closes on its open token', (
        tester,
      ) async {
        final (open, close) = await _times(tester, make());
        expect(
          (close - open).inMicroseconds.abs(),
          lessThanOrEqualTo(2 * _step.inMicroseconds),
          reason: 'open $open, close $close',
        );
      });

      testWidgets('a stiffer close token closes it sooner than it opened, '
          'a softer one later', (tester) async {
        final (open, quick) = await _times(tester, make(closeStiffness: 6000));
        expect(
          quick.inMicroseconds,
          lessThan(open.inMicroseconds * 0.7),
          reason: 'open $open, close $quick',
        );
        final (_, slow) = await _times(tester, make(closeStiffness: 150));
        expect(
          slow.inMicroseconds,
          greaterThan(open.inMicroseconds * 1.5),
          reason: 'open $open, close $slow',
        );
      });

      testWidgets('under Reduce Motion it fades out on the effects spring, '
          'whatever its close token', (tester) async {
        final route = make(closeStiffness: 150);
        final navigator = await _app(tester, reduceMotion: true);
        unawaited(navigator.push(route));
        await tester.pumpAndSettle();
        final rest = tester.getRect(find.byKey(_page));
        navigator.pop();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        expect(route.animation!.value, inExclusiveRange(0, 1));
        expect(tester.getRect(find.byKey(_page)), rest, reason: 'it fades');
        final close = await _until(tester, route, AnimationStatus.dismissed);
        expect(
          close,
          lessThanOrEqualTo(const Duration(milliseconds: 150)),
          reason: 'a soft close token would take far longer',
        );
        await tester.pumpAndSettle();
      });
    });
  }

  testWidgets("a dialog's close token sets its damping: an underdamped one "
      'overshoots in the details as it closes', (tester) async {
    final seen = <double>[];
    final route = _routes['dialog']!(closeDampingRatio: 0.3, seen: seen.add);
    final navigator = await _app(tester);
    unawaited(navigator.push(route));
    await tester.pumpAndSettle();
    expect(seen.reduce((a, b) => a < b ? a : b), greaterThanOrEqualTo(0));
    expect(seen.reduce((a, b) => a > b ? a : b), lessThanOrEqualTo(1));
    seen.clear();
    navigator.pop();
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(seen.reduce((a, b) => a < b ? a : b), lessThan(-0.02));
    await tester.pumpAndSettle();
  });

  // A sheet dragged [by], held still or flung, and let go where it closes;
  // how long it takes from there to be gone (the route at 0: a fling past it
  // swings the spring on, unseen, before the route is dismissed).
  for (final (name, by) in [
    ('bottom sheet', const Offset(0, 240)),
    ('side sheet', const Offset(240, 0)),
  ]) {
    testWidgets('a $name let go to close closes on its close token, '
        "carrying the drag's speed", (tester) async {
      Future<Duration> close({double? stiffness, required bool fling}) async {
        final route = _routes[name]!(closeStiffness: stiffness);
        final navigator = await _app(tester);
        unawaited(navigator.push(route));
        await tester.pumpAndSettle();
        final from = tester.getCenter(find.byKey(_page));
        if (fling) {
          await tester.flingFrom(from, by, 2400);
        } else {
          final drag = await tester.startGesture(from);
          for (var i = 0; i < 12; i++) {
            await drag.moveBy(by / 12);
            await tester.pump(const Duration(milliseconds: 16));
          }
          // Held still, so it is let go with no fling.
          await tester.pump(const Duration(milliseconds: 300));
          await drag.up();
        }
        await tester.pump();
        final animation = route.animation!;
        var took = Duration.zero;
        while (animation.value > 1e-3) {
          await tester.pump(_step);
          took += _step;
          if (took > const Duration(seconds: 5)) fail('never gone');
        }
        await tester.pumpAndSettle();
        expect(find.byKey(_page), findsNothing);
        return took;
      }

      final onOpen = await close(fling: false);
      final soft = await close(stiffness: 150, fling: false);
      final flung = await close(stiffness: 150, fling: true);
      expect(soft, greaterThan(onOpen), reason: 'on the close token');
      expect(flung, lessThan(soft), reason: 'carrying the fling');
    });
  }
}
