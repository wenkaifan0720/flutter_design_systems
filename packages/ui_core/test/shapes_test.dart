// The shape API a look opens: each corner style's outline, the round
// corner's fast path, a morph between any two styles with no jump, the ink
// and hit clip every style gives, concentric insets, and the bands a look
// holds its scheme to.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const Rect _rect = Rect.fromLTWH(0, 0, 100, 60);
final Paint _paint = Paint()..color = const Color(0xFF000000);

RawCornerBorder _border(RawCornerStyle style, {double r = 20}) =>
    RawCornerBorder(style: style, borderRadius: BorderRadius.circular(r));

// For each style, a point its top left corner (radius 20) holds and one it
// cuts away, where the styles part.
const Map<RawCornerStyle, (Offset, Offset)> _probes = {
  RawCornerStyle.round: (Offset(6, 6), Offset(5, 5)),
  RawCornerStyle.continuous: (Offset(5, 5), Offset(4, 4)),
  RawCornerStyle.bevel: (Offset(11, 11), Offset(9, 9)),
  RawCornerStyle.notch: (Offset(25, 5), Offset(15, 15)),
  RawCornerStyle.step: (Offset(7, 17), Offset(3, 17)),
  RawCornerStyle.concave: (Offset(15, 15), Offset(10, 10)),
};

// [p] mirrored into each corner of [_rect].
List<Offset> _corners(Offset p) => [
  p,
  Offset(_rect.width - p.dx, p.dy),
  Offset(_rect.width - p.dx, _rect.height - p.dy),
  Offset(p.dx, _rect.height - p.dy),
];

// How far from (30, 30), along [angle], the outline [border] draws on
// [_rect] lies: the first point out of it.
double _reach(ShapeBorder border, double angle) {
  final path = border.getOuterPath(_rect);
  const from = Offset(30, 30);
  final along = Offset(math.cos(angle), math.sin(angle));
  var inside = 0.0;
  var outside = 0.25;
  while (path.contains(from + along * outside)) {
    inside = outside;
    outside += 0.25;
  }
  for (var i = 0; i < 20; i++) {
    final mid = (inside + outside) / 2;
    if (path.contains(from + along * mid)) {
      inside = mid;
    } else {
      outside = mid;
    }
  }
  return inside;
}

// Rays from inside the top left corner toward it.
final List<double> _rays = [
  for (var i = 0; i < 8; i++) math.pi * (185 + i * 11) / 180,
];

// The most the outline moves along any ray between neighbouring samples of
// [at] (0 to 1 in [steps]), and the most it moves in all.
({double step, double span}) _motion(
  ShapeBorder Function(double t) at, {
  int steps = 30,
}) {
  var step = 0.0, span = 0.0;
  for (final angle in _rays) {
    final reach = [
      for (var k = 0; k <= steps; k++) _reach(at(k / steps), angle),
    ];
    final low = reach.reduce(math.min), high = reach.reduce(math.max);
    span = math.max(span, high - low);
    for (var k = 1; k < reach.length; k++) {
      step = math.max(step, (reach[k] - reach[k - 1]).abs());
    }
  }
  return (step: step, span: span);
}

// No sample moves past three times its share of the whole, and half a pixel.
bool _smooth(({double step, double span}) m, int steps) =>
    m.step <= 3 * m.span / steps + 0.5;

void main() {
  group('each corner style', () {
    for (final MapEntry(key: style, value: (held, cut)) in _probes.entries) {
      test('${style.name} holds and cuts its corner, in every corner', () {
        final path = _border(style).getOuterPath(_rect);
        for (final p in _corners(held)) {
          expect(path.contains(p), isTrue, reason: '${style.name} holds $p');
        }
        for (final p in _corners(cut)) {
          expect(path.contains(p), isFalse, reason: '${style.name} cuts $p');
        }
        expect(path.contains(const Offset(50, 30)), isTrue);
        expect(path.contains(const Offset(1, 1)), isFalse);
      });
    }

    test(
      'a stair takes 2 steps under 8, 3 to 16, 4 above, on whole pixels',
      () {
        // Under 8: 2 steps of 3.5 at 7, the corner between them on whole
        // pixels (4, 4), not at (3.5, 3.5).
        final small = _border(RawCornerStyle.step, r: 7).getOuterPath(_rect);
        expect(small.contains(const Offset(4.2, 4.2)), isTrue);
        expect(small.contains(const Offset(3.8, 4.2)), isFalse);
        expect(small.contains(const Offset(4.2, 3.8)), isFalse);
        // 12: 3 steps of 4.
        final mid = _border(RawCornerStyle.step, r: 12).getOuterPath(_rect);
        expect(mid.contains(const Offset(4.2, 8.2)), isTrue);
        expect(mid.contains(const Offset(3.8, 8.2)), isFalse);
        expect(mid.contains(const Offset(8.2, 4.2)), isTrue);
        expect(mid.contains(const Offset(8.2, 3.8)), isFalse);
      },
    );

    test('a path is made once per size and moved to where it is drawn', () {
      final border = _border(RawCornerStyle.bevel);
      final moved = border.getOuterPath(_rect.shift(const Offset(10, 10)));
      expect(moved.contains(const Offset(21, 21)), isTrue);
      expect(moved.contains(const Offset(19, 19)), isFalse);
      // Another size: its own outline, not the first one's moved.
      final wide = border.getOuterPath(const Rect.fromLTWH(0, 0, 200, 100));
      expect(wide.contains(const Offset(150, 50)), isTrue);
      expect(wide.contains(const Offset(191, 91)), isFalse);
      final again = border.getOuterPath(_rect);
      expect(again.contains(const Offset(11, 11)), isTrue);
      expect(again.contains(const Offset(9, 9)), isFalse);
    });
  });

  group("the round corner's fast path", () {
    test('a round corner at rest fills, strokes and clips as an RRect', () {
      final round = _border(RawCornerStyle.round);
      expect(
        (Canvas canvas) => round.paintInterior(canvas, _rect, _paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(_rect, const Radius.circular(20)),
        ),
      );
      expect(
        (Canvas canvas) => round.paintInterior(canvas, _rect, _paint),
        paintsExactlyCountTimes(#drawPath, 0),
      );
      final stroked = round.copyWith(side: const BorderSide(width: 2));
      expect(
        (Canvas canvas) => stroked.paint(canvas, _rect),
        paintsExactlyCountTimes(#drawDRRect, 1),
      );
      final between = ShapeBorder.lerp(
        _border(RawCornerStyle.round, r: 10),
        _border(RawCornerStyle.round, r: 30),
        0.5,
      )!;
      expect(
        (Canvas canvas) => between.paintInterior(canvas, _rect, _paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(_rect, const Radius.circular(20)),
        ),
      );
    });

    test('the other styles, and a corner between styles, draw a path', () {
      for (final style in RawCornerStyle.values) {
        if (style == RawCornerStyle.round) continue;
        expect(
          (Canvas canvas) =>
              _border(style).paintInterior(canvas, _rect, _paint),
          paintsExactlyCountTimes(#drawPath, 1),
          reason: style.name,
        );
      }
      final halfway = ShapeBorder.lerp(
        _border(RawCornerStyle.bevel),
        _border(RawCornerStyle.round),
        0.5,
      )!;
      expect(
        (Canvas canvas) => halfway.paintInterior(canvas, _rect, _paint),
        paintsExactlyCountTimes(#drawPath, 1),
      );
      final arrived = ShapeBorder.lerp(
        _border(RawCornerStyle.bevel),
        _border(RawCornerStyle.round),
        1,
      )!;
      expect(arrived, _border(RawCornerStyle.round));
      expect(
        (Canvas canvas) => arrived.paintInterior(canvas, _rect, _paint),
        paintsExactlyCountTimes(#drawRRect, 1),
      );
    });
  });

  group('a morph', () {
    test('between any two styles moves the outline with no jump', () {
      const steps = 30;
      for (final a in RawCornerStyle.values) {
        for (final b in RawCornerStyle.values) {
          if (b.index <= a.index) continue;
          final m = _motion(
            (t) => ShapeBorder.lerp(_border(a), _border(b), t)!,
          );
          expect(m.span, greaterThan(0.5), reason: '${a.name} → ${b.name}');
          expect(
            _smooth(m, steps),
            isTrue,
            reason: '${a.name} → ${b.name}: ${m.step} of ${m.span}',
          );
        }
      }
    });

    test(
      "from and to Flutter's borders, where two of Flutter's kinds snap",
      () {
        const steps = 30;
        final r = BorderRadius.circular(20);
        final froms = <ShapeBorder, RawCornerBorder>{
          RoundedRectangleBorder(borderRadius: r): _border(
            RawCornerStyle.bevel,
          ),
          BeveledRectangleBorder(borderRadius: r): _border(
            RawCornerStyle.round,
          ),
          RoundedSuperellipseBorder(borderRadius: r): _border(
            RawCornerStyle.notch,
          ),
          const StadiumBorder(): _border(RawCornerStyle.concave),
        };
        for (final MapEntry(key: flutter, value: ours) in froms.entries) {
          final there = _motion((t) => ShapeBorder.lerp(flutter, ours, t)!);
          final back = _motion((t) => ShapeBorder.lerp(ours, flutter, t)!);
          expect(_smooth(there, steps), isTrue, reason: '$flutter → ours');
          expect(_smooth(back, steps), isTrue, reason: 'ours → $flutter');
        }
        final snap = _motion(
          (t) => ShapeBorder.lerp(
            RoundedRectangleBorder(borderRadius: r),
            BeveledRectangleBorder(borderRadius: r),
            t,
          )!,
        );
        expect(_smooth(snap, steps), isFalse, reason: 'the probe sees a snap');
      },
    );

    test('past its ends (a spring overshooting) still draws', () {
      for (final t in [-0.3, 1.3]) {
        final border = ShapeBorder.lerp(
          _border(RawCornerStyle.bevel),
          _border(RawCornerStyle.round, r: 10),
          t,
        )!;
        expect(
          border.getOuterPath(_rect).contains(const Offset(50, 30)),
          isTrue,
        );
      }
    });
  });

  group('a ShapeBorderTween from a bevel to a round corner', () {
    Future<List<double>> frames(
      WidgetTester tester, {
      required ShapeBorder from,
      required ShapeBorder to,
      int? reverseAt,
    }) async {
      var pressed = false;
      late StateSetter setPressed;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: StatefulBuilder(
              builder: (context, setState) {
                setPressed = setState;
                return TweenAnimationBuilder<ShapeBorder?>(
                  tween: ShapeBorderTween(
                    begin: from,
                    end: pressed ? to : from,
                  ),
                  duration: const Duration(milliseconds: 200),
                  builder: (context, shape, _) => SizedBox(
                    width: 100,
                    height: 60,
                    child: DecoratedBox(
                      key: const ValueKey('face'),
                      decoration: ShapeDecoration(
                        color: const Color(0xFF808080),
                        shape: shape!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );
      ShapeBorder shown() =>
          (tester
                      .renderObject<RenderDecoratedBox>(
                        find.byKey(const ValueKey('face')),
                      )
                      .decoration
                  as ShapeDecoration)
              .shape;
      final reach = <double>[_reach(shown(), _rays[4])];
      setPressed(() => pressed = true);
      for (var f = 0; f < 20; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        reach.add(_reach(shown(), _rays[4]));
        if (f == reverseAt) setPressed(() => pressed = false);
      }
      return reach;
    }

    double largest(List<double> reach) =>
        [for (var i = 1; i < reach.length; i++) (reach[i] - reach[i - 1]).abs()]
            .reduce(math.max);

    // A frame's share of the whole move at the tween's linear rate (16 of
    // 200 ms), three times over, and half a pixel.
    double rate(List<double> reach) {
      final span = reach.reduce(math.max) - reach.reduce(math.min);
      return 3 * span * 16 / 200 + 0.5;
    }

    testWidgets('moves every frame within its rate, and back from halfway', (
      tester,
    ) async {
      final there = await frames(
        tester,
        from: _border(RawCornerStyle.bevel),
        to: _border(RawCornerStyle.round),
      );
      expect(
        there.last,
        closeTo(_reach(_border(RawCornerStyle.round), _rays[4]), 0.01),
      );
      expect(largest(there), lessThanOrEqualTo(rate(there)));
      final back = await frames(
        tester,
        from: _border(RawCornerStyle.bevel),
        to: _border(RawCornerStyle.round),
        reverseAt: 5,
      );
      expect(largest(back), lessThanOrEqualTo(rate(there)));
    });

    testWidgets(
      "Flutter's own two kinds jump in one frame (the probe's control)",
      (tester) async {
        final r = BorderRadius.circular(20);
        final snap = await frames(
          tester,
          from: BeveledRectangleBorder(borderRadius: r),
          to: RoundedRectangleBorder(borderRadius: r),
        );
        expect(largest(snap), greaterThan(rate(snap)));
      },
    );
  });

  group('ink and hits follow the outline', () {
    for (final MapEntry(key: style, value: (held, cut)) in _probes.entries) {
      testWidgets('an ink splash stays inside a ${style.name} corner', (
        tester,
      ) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                height: 60,
                child: Material(
                  child: InkWell(
                    customBorder: _border(style),
                    splashFactory: InkSplash.splashFactory,
                    onTap: () {},
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
          ),
        );
        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(InkWell)),
        );
        await tester.pump(const Duration(milliseconds: 200));
        final ink = tester.allRenderObjects.firstWhere(
          (r) => r.runtimeType.toString() == '_RenderInkFeatures',
        );
        expect(
          ink,
          paints..clipPath(
            pathMatcher: isPathThat(
              includes: [const Offset(50, 30), held],
              excludes: [cut, const Offset(1, 1)],
            ),
          ),
        );
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a ShapeBorderClipper takes no tap in a cut ${style.name} '
          'corner', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              key: const ValueKey('box'),
              width: 100,
              height: 60,
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: _border(style),
                  textDirection: TextDirection.ltr,
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => taps++,
                ),
              ),
            ),
          ),
        );
        final origin = tester.getTopLeft(find.byKey(const ValueKey('box')));
        await tester.tapAt(origin + cut);
        expect(taps, 0);
        await tester.tapAt(origin + held);
        expect(taps, 1);
      });
    }
  });

  group('concentric', () {
    final inner = _rect.deflate(3);

    test(
      'a round corner less the inset, elliptical where the insets differ',
      () {
        final b = _border(RawCornerStyle.round, r: 12);
        expect(
          (Canvas c) =>
              b.inset(const EdgeInsets.all(3)).paintInterior(c, inner, _paint),
          paints..rrect(
            rrect: RRect.fromRectAndRadius(inner, const Radius.circular(9)),
          ),
        );
        final uneven = const Rect.fromLTRB(4, 2, 96, 58);
        expect(
          (Canvas c) => b
              .inset(const EdgeInsets.symmetric(horizontal: 4, vertical: 2))
              .paintInterior(c, uneven, _paint),
          paints..rrect(
            rrect: RRect.fromRectAndRadius(
              uneven,
              const Radius.elliptical(8, 10),
            ),
          ),
        );
        expect(
          (Canvas c) => b
              .outset(const EdgeInsets.all(2))
              .paintInterior(c, _rect.inflate(2), _paint),
          paints..rrect(
            rrect: RRect.fromRectAndRadius(
              _rect.inflate(2),
              const Radius.circular(14),
            ),
          ),
        );
      },
    );

    test("a chamfer keeps its distance: 2 − √2 of the inset off", () {
      // The outer line x + y = 12 moved 3 in is x + y = 12 + 3√2: its middle
      // at 8.12.
      final path = _border(
        RawCornerStyle.bevel,
        r: 12,
      ).inset(const EdgeInsets.all(3)).getOuterPath(inner);
      expect(path.contains(const Offset(8.4, 8.4)), isTrue);
      expect(path.contains(const Offset(7.8, 7.8)), isFalse);
    });

    test("a notch's and a stair's keep their size", () {
      final notch = _border(
        RawCornerStyle.notch,
        r: 12,
      ).inset(const EdgeInsets.all(3)).getOuterPath(inner);
      expect(notch.contains(const Offset(14, 14)), isFalse);
      expect(notch.contains(const Offset(16, 5)), isTrue);
      final stair = _border(
        RawCornerStyle.step,
        r: 12,
      ).inset(const EdgeInsets.all(3)).getOuterPath(inner);
      // 3 steps of 4 from (3, 3).
      expect(stair.contains(const Offset(7.2, 11.2)), isTrue);
      expect(stair.contains(const Offset(6.8, 11.2)), isFalse);
    });

    test(
      'a scoop meets the sides where its parallel does: √(r² + 2rd) − d',
      () {
        // r 12, d 3: 11.70 round the inner corner (3, 3).
        final path = _border(
          RawCornerStyle.concave,
          r: 12,
        ).inset(const EdgeInsets.all(3)).getOuterPath(inner);
        expect(path.contains(const Offset(11.38, 11.38)), isTrue);
        expect(path.contains(const Offset(11.1, 11.1)), isFalse);
      },
    );

    test('a corner of 0 stays 0; any other no less than the floor', () {
      const b = RawCornerBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
      );
      expect(
        (Canvas c) => b
            .inset(const EdgeInsets.all(5), floor: 4)
            .paintInterior(c, _rect.deflate(5), _paint),
        paints..rrect(
          rrect: RRect.fromRectAndCorners(
            _rect.deflate(5),
            topLeft: const Radius.circular(4),
          ),
        ),
      );
      // Outside too: a ring round a sharp corner stays sharp.
      expect(
        (Canvas c) => const RawCornerBorder()
            .outset(const EdgeInsets.all(2))
            .paintInterior(c, _rect.inflate(2), _paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(_rect.inflate(2), Radius.zero),
        ),
      );
    });

    test('a full border stays full inside, under its most', () {
      const box = Rect.fromLTWH(0, 0, 100, 40);
      expect(
        (Canvas c) =>
            const RawCornerBorder(full: true)
                .inset(const EdgeInsets.all(3))
                .paintInterior(c, box.deflate(3), _paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            box.deflate(3),
            const Radius.circular(17),
          ),
        ),
      );
      expect(
        (Canvas c) => const RawCornerBorder(full: true, maxRadius: 12)
            .inset(const EdgeInsets.all(3))
            .paintInterior(c, box.deflate(3), _paint),
        paints..rrect(
          rrect: RRect.fromRectAndRadius(
            box.deflate(3),
            const Radius.circular(9),
          ),
        ),
      );
    });

    test('a directional radius follows the text direction', () {
      const b = RawCornerBorder(
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(12),
        ),
      );
      expect(
        (Canvas c) =>
            b.paintInterior(c, _rect, _paint, textDirection: TextDirection.rtl),
        paints..rrect(
          rrect: RRect.fromRectAndCorners(
            _rect,
            topRight: const Radius.circular(12),
          ),
        ),
      );
    });

    test('a cut corner follows the text direction too, each made apart', () {
      const b = RawCornerBorder(
        style: RawCornerStyle.bevel,
        borderRadius: BorderRadiusDirectional.only(
          topStart: Radius.circular(20),
        ),
      );
      final ltr = b.getOuterPath(_rect, textDirection: TextDirection.ltr);
      final rtl = b.getOuterPath(_rect, textDirection: TextDirection.rtl);
      expect(ltr.contains(const Offset(5, 5)), isFalse);
      expect(ltr.contains(const Offset(95, 5)), isTrue);
      expect(rtl.contains(const Offset(5, 5)), isTrue);
      expect(rtl.contains(const Offset(95, 5)), isFalse);
    });

    test("a stroke draws on its centre line, by the side's alignment", () {
      for (final (align, edge) in [
        (BorderSide.strokeAlignInside, 2.0),
        (BorderSide.strokeAlignCenter, 0.0),
        (BorderSide.strokeAlignOutside, -2.0),
      ]) {
        final b = _border(RawCornerStyle.bevel)
            .copyWith(side: BorderSide(width: 4, strokeAlign: align));
        expect(
          (Canvas c) => b.paint(c, _rect),
          paints..path(
            includes: [Offset(50, edge + 0.5)],
            excludes: [Offset(50, edge - 0.5)],
          ),
          reason: 'aligned $align',
        );
      }
    });
  });

  group('a scale, a scheme and their lerps', () {
    test("a scale's steps, Material 3's numbers by default", () {
      const scale = RawCornerScale();
      expect(
        [for (final s in RawCorner.values) scale.radius(s)],
        [0, 4, 8, 12, 16, 28, double.infinity],
      );
      expect(scale.border(RawCorner.full).full, isTrue);
      expect(
        scale.border(RawCorner.medium).borderRadius,
        BorderRadius.circular(12),
      );
      expect(scale.scaled(2).large, 32);
      expect(
        const RawCornerScale(style: RawCornerStyle.bevel)
            .border(RawCorner.small)
            .style,
        RawCornerStyle.bevel,
      );
    });

    test('a scale between styles gives borders between them', () {
      const a = RawCornerScale(medium: 20);
      const b = RawCornerScale(style: RawCornerStyle.bevel, medium: 20);
      final half = RawCornerScale.lerp(a, b, 0.5).border(RawCorner.medium);
      final path = half.getOuterPath(_rect);
      // Between the round corner's 5.86 and the bevel's 10 on the diagonal.
      expect(path.contains(const Offset(9, 9)), isTrue);
      expect(path.contains(const Offset(7, 7)), isFalse);
      expect(RawCornerScale.lerp(a, b, 1), b);
    });

    test('a scheme lerps what both sides open, and switches what one does', () {
      const a = RawShapeScheme(stroke: 2, depth: 1);
      const b = RawShapeScheme(stroke: 4);
      expect(RawShapeScheme.lerp(a, b, 0.5).stroke, 3);
      expect(RawShapeScheme.lerp(a, b, 0.4).depth, 1);
      expect(RawShapeScheme.lerp(a, b, 0.6).depth, isNull);
    });

    test('values with no meaning assert', () {
      expect(() => RawBand(3, 1), throwsAssertionError);
      expect(() => RawCornerScale(medium: -1), throwsAssertionError);
      expect(
        () => RawShapeScheme(stroke: double.infinity),
        throwsAssertionError,
      );
      expect(() => const RawCornerScale().scaled(-1), throwsAssertionError);
    });
  });

  group("a look's bands", () {
    // A look's bands, as one that opens its corners and stroke only.
    const limits = RawShapeLimits(
      styles: {RawCornerStyle.round, RawCornerStyle.continuous},
      extraSmall: RawBand(2, 6),
      small: RawBand(6, 12),
      medium: RawBand(10, 18),
      large: RawBand(14, 24),
      extraLarge: RawBand(20, 32),
      stroke: RawBand(1, 3),
    );
    const base = RawCornerScale(medium: 14, large: 18, extraLarge: 26);

    test('scaled(3) ends at every band\'s most, scaled(0) at its least', () {
      final up = limits.clamp(RawShapeScheme(corners: base.scaled(3))).corners;
      expect(
        [up.extraSmall, up.small, up.medium, up.large, up.extraLarge],
        [6, 12, 18, 24, 32],
      );
      final down = limits
          .clamp(RawShapeScheme(corners: base.scaled(0)))
          .corners;
      expect(
        [down.extraSmall, down.small, down.medium, down.large, down.extraLarge],
        [2, 6, 10, 14, 20],
      );
    });

    test('a value inside its band stays; one the look does not open goes', () {
      final held = limits.clamp(
        const RawShapeScheme(corners: base, stroke: 5, depth: 1.2),
      );
      expect(held.corners, base);
      expect(held.stroke, 3);
      expect(held.depth, isNull);
      const scoop = RawShapeScheme(
        corners: RawCornerScale(style: RawCornerStyle.concave),
      );
      expect(limits.clamp(scoop).corners.style, RawCornerStyle.round);
      expect(limits.debugDescribeClamps(scoop), ['style concave to round']);
      expect(
        limits.debugDescribeClamps(
          const RawShapeScheme(
            corners: RawCornerScale(medium: 40),
            stroke: 2,
            depth: 1,
          ),
        ),
        contains("medium 40 to 18, the band's most"),
      );
      expect(limits.debugDescribeClamps(const RawShapeScheme(depth: 1)), [
        'depth 1: not opened, dropped',
      ]);
    });

    test(
      'the nearest allowed style stands in: its kin first, else the default',
      () {
        expect(
          limits.nearestStyle(RawCornerStyle.continuous),
          RawCornerStyle.continuous,
        );
        expect(
          const RawShapeLimits().nearestStyle(RawCornerStyle.continuous),
          RawCornerStyle.round,
        );
        expect(
          const RawShapeLimits(
            styles: {RawCornerStyle.round, RawCornerStyle.step},
          ).nearestStyle(RawCornerStyle.bevel),
          RawCornerStyle.step,
        );
        expect(
          limits.nearestStyle(RawCornerStyle.concave),
          RawCornerStyle.round,
        );
      },
    );

    test('in debug, each value held is told once per band end', () {
      final lines = <String>[];
      final print = debugPrint;
      debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
      try {
        for (final medium in <double>[30, 40, 50, 0]) {
          limits.clamp(
            RawShapeScheme(corners: RawCornerScale(medium: medium)),
            look: 'Shapes test',
          );
        }
      } finally {
        debugPrint = print;
      }
      expect(lines, [
        "Shapes test holds medium 30 to 18, the band's most.",
        "Shapes test holds medium 0 to 10, the band's least.",
      ]);
    });
  });
}
