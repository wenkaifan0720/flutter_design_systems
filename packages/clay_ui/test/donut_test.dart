// Clay's donut stays honest and moves without jumps. Each piece's area is
// its share of all the clay, whatever the gaps and round ends, so a 9% slice
// is 9%; a piece too small to round keeps square ends, and its corners grow
// only as it does; and as the values spring from one set to the next, every
// piece's ends, corners and gaps move a little each frame and never jump:
// through a piece growing from nothing, one shrinking to nothing, and one
// coming to hold the whole ring.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:clay_ui/src/clay/internal/slices.dart';

// The gallery's donut, 200 across: its ring's edges.
const _outer = 92.0;
const _inner = 58.0;

List<ClaySliceShape?> _shapes(List<double> values) =>
    claySliceShapes(values, outer: _outer, inner: _inner);

/// The area inside [path]'s one outline, its curves flattened finely.
double _area(Path path) {
  var twice = 0.0;
  for (final metric in path.computeMetrics()) {
    final n = math.max(256, (metric.length / 0.2).ceil());
    Offset? first;
    Offset? last;
    for (var i = 0; i <= n; i++) {
      final p = metric.getTangentForOffset(metric.length * i / n)!.position;
      if (last != null) twice += last.dx * p.dy - p.dx * last.dy;
      first ??= p;
      last = p;
    }
    twice += last!.dx * first!.dy - first.dx * last.dy;
  }
  return twice.abs() / 2;
}

void main() {
  const sets = <String, List<double>>{
    "the gallery's week": [140, 95, 65, 30],
    'one small, one large': [91, 9],
    'small ones beside a large one': [1, 2, 3, 94],
    'four equal': [25, 25, 25, 25],
    'twelve equal': [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1],
    'falling shares': [60, 30, 6, 3, 1],
    'a nothing between two halves': [50, 0, 50],
  };

  for (final MapEntry(key: name, value: values) in sets.entries) {
    test('$name: each piece is its share of the clay', () {
      final shapes = _shapes(values);
      final total = values.fold(0.0, (a, b) => a + b);
      final areas = [
        for (final s in shapes)
          s == null ? 0.0 : _area(s.path(Offset.zero, _outer, _inner)),
      ];
      final clay = areas.fold(0.0, (a, b) => a + b);
      final round = shapes.fold(0.0, (a, s) => a + (s?.sweep ?? 0));
      for (final (i, v) in values.indexed) {
        expect(shapes[i] == null, v == 0, reason: 'piece $i');
        if (v == 0) continue;
        // The drawn outline holds what the layout says it does.
        expect(
          areas[i],
          closeTo(shapes[i]!.area(_outer, _inner), areas[i] * 0.003),
          reason: 'piece $i outline',
        );
        // Its share of the clay is its share of the values, to a tenth of a
        // percentage point.
        expect(areas[i] / clay, closeTo(v / total, 0.001), reason: 'piece $i');
        // And it runs as far round the ring's clay as its share, to a
        // percentage point.
        expect(
          shapes[i]!.sweep / round,
          closeTo(v / total, 0.01),
          reason: 'piece $i sweep',
        );
      }
    });
  }

  test('a 9% slice is 9% of the clay', () {
    final shapes = _shapes(const [91, 9]);
    final small = _area(shapes[1]!.path(Offset.zero, _outer, _inner));
    final large = _area(shapes[0]!.path(Offset.zero, _outer, _inner));
    expect(small / (small + large), closeTo(0.09, 0.001));
    // Big enough to round: its ends are Clay's continuous corners.
    expect(shapes[1]!.outerCorner, greaterThan(0));
    expect(shapes[1]!.innerCorner, greaterThan(0));
  });

  test('a piece too small to round keeps square ends', () {
    // The corner a piece's edge can hold: none while the edge runs no
    // further than one corner's radius, whole from three radii.
    const corner = 10.0;
    expect(claySliceCorner(corner / _inner, _inner, corner), 0);
    expect(claySliceCorner(0.5 * corner / _inner, _inner, corner), 0);
    expect(claySliceCorner(2 * corner / _inner, _inner, corner), corner / 2);
    expect(claySliceCorner(3 * corner / _inner, _inner, corner), corner);
    expect(claySliceCorner(9 * corner / _inner, _inner, corner), corner);
    // In the gallery's donut a 1% piece is square at both edges.
    final tiny = _shapes(const [1, 99])[0]!;
    expect(tiny.outerCorner, 0);
    expect(tiny.innerCorner, 0);
    // As a piece grows its corners only grow, from square to whole.
    var outer = 0.0;
    var inner = 0.0;
    for (var share = 0.005; share <= 0.5; share += 0.005) {
      final piece = _shapes([share, 1 - share])[0]!;
      expect(piece.outerCorner, greaterThanOrEqualTo(outer - 1e-9));
      expect(piece.innerCorner, greaterThanOrEqualTo(inner - 1e-9));
      outer = piece.outerCorner;
      inner = piece.innerCorner;
    }
    expect(outer, closeTo((_outer - _inner) * 0.3, 1e-9));
    expect(inner, closeTo((_outer - _inner) * 0.3, 1e-9));
  });

  test('one piece holding everything is a whole ring', () {
    final shapes = _shapes(const [100, 0, 0]);
    expect(shapes[0]!.whole, isTrue);
    expect(shapes[0]!.outerCorner, 0);
    expect(shapes[1], isNull);
    expect(shapes[2], isNull);
    expect(_shapes(const [0, 0]), [null, null]);
  });

  // Each change is followed in fine steps, as the spring moves the values.
  const moves = <String, (List<double>, List<double>)>{
    'shares trading places': ([140, 95, 65, 30], [30, 95, 65, 140]),
    'a piece growing from nothing': ([140, 95, 65, 0], [140, 95, 65, 30]),
    'a piece shrinking to nothing': ([140, 95, 3, 30], [140, 95, 0, 30]),
    'one piece coming to hold the ring': ([100, 50, 20], [100, 0, 0]),
    'a half going': ([50, 50], [100, 0]),
  };
  for (final MapEntry(key: name, value: (from, to)) in moves.entries) {
    test('$name: every piece moves a little each step, never jumping', () {
      // The largest change between neighbouring steps, in angle and in
      // corner, for [steps] steps from [from] to [to].
      (double, double) largest(int steps) {
        var angle = 0.0;
        var corner = 0.0;
        List<ClaySliceShape?>? last;
        for (var k = 0; k <= steps; k++) {
          final t = k / steps;
          final now = _shapes([
            for (final (i, a) in from.indexed) a + (to[i] - a) * t,
          ]);
          if (last != null) {
            for (final (i, s) in now.indexed) {
              final l = last[i];
              if (s == null && l == null) continue;
              if (s == null || l == null) {
                // A piece comes or goes only as nothing.
                expect((s ?? l)!.sweep, lessThan(0.002));
                continue;
              }
              angle = math.max(angle, (s.start - l.start).abs());
              angle = math.max(angle, (s.sweep - l.sweep).abs());
              corner = math.max(corner, (s.outerCorner - l.outerCorner).abs());
              corner = math.max(corner, (s.innerCorner - l.innerCorner).abs());
            }
          }
          last = now;
        }
        return (angle, corner);
      }

      final (angle, corner) = largest(2000);
      expect(angle, lessThan(0.01));
      expect(corner, lessThan(0.5));
      // Twice the steps, half the change: nothing jumps however fine the
      // frames.
      final (angle2, corner2) = largest(4000);
      expect(angle2, lessThan(angle * 0.6 + 1e-9));
      expect(corner2, lessThan(corner * 0.6 + 1e-9));
    });
  }

  testWidgets('a donut springs to new values through every frame', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    Widget donut(List<double> values) => ClayPreview(
      child: Center(
        child: ClayPieChart(
          semanticLabel: 'Minutes by habit',
          centerLabel: '5 h',
          slices: [
            for (final (i, v) in values.indexed)
              ClayPieSlice(label: 'Habit $i', value: v),
          ],
        ),
      ),
    );
    await tester.pumpWidget(donut(const [140, 95, 65, 30]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(donut(const [30, 95, 0, 140]));
    for (var frame = 0; frame < 60; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
