// Per-part corners: the steps an app gives a part's corners (RawCorners),
// the border a look's scale draws from them (RawCornerScale.borderOf), what
// a look's limits let through (RawShapeLimits.clampCorners), and the motion
// between them: a lerp, a ShapeBorderTween, and a theme switch under a
// card that reads its style's corners.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const Rect _rect = Rect.fromLTWH(0, 0, 100, 60);
final Paint _paint = Paint()..color = const Color(0xFF000000);
const _ltr = TextDirection.ltr;
const _rtl = TextDirection.rtl;

// A scale whose medium is 20 and large 28, in [style].
RawCornerScale _scale(RawCornerStyle style) =>
    RawCornerScale(style: style, medium: 20, large: 28);

const RawCorners _medium = RawCorners.all(RawCorner.medium);

// The user's case: two diagonal corners square, the other two the part's.
const RawCorners _diagonal = RawCorners(
  topEnd: RawCorner.none,
  bottomStart: RawCorner.none,
);

// For each style, a point its top left corner (radius 20) holds and one it
// cuts away, as in shapes_test.
const Map<RawCornerStyle, (Offset, Offset)> _probes = {
  RawCornerStyle.round: (Offset(6, 6), Offset(5, 5)),
  RawCornerStyle.continuous: (Offset(5, 5), Offset(4, 4)),
  RawCornerStyle.bevel: (Offset(11, 11), Offset(9, 9)),
  RawCornerStyle.notch: (Offset(25, 5), Offset(15, 15)),
  RawCornerStyle.step: (Offset(7, 17), Offset(3, 17)),
  RawCornerStyle.concave: (Offset(15, 15), Offset(10, 10)),
};

// [p] mirrored into each corner of [_rect]: top left, top right, bottom
// right, bottom left.
List<Offset> _corners(Offset p) => [
  p,
  Offset(_rect.width - p.dx, p.dy),
  Offset(_rect.width - p.dx, _rect.height - p.dy),
  Offset(p.dx, _rect.height - p.dy),
];

// Rays from inside the top left corner toward it.
final List<double> _rays = [
  for (var i = 0; i < 8; i++) math.pi * (185 + i * 11) / 180,
];

// How far the outline [border] draws on [_rect] lies from inside a top
// corner, along [angle] (a ray toward the top left; mirrored with [right]).
double _reach(
  ShapeBorder border,
  double angle, {
  TextDirection direction = _ltr,
  bool right = false,
}) {
  final path = border.getOuterPath(_rect, textDirection: direction);
  final from = right ? const Offset(70, 30) : const Offset(30, 30);
  final along = Offset(
    right ? -math.cos(angle) : math.cos(angle),
    math.sin(angle),
  );
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

// The most the top left outline moves along any ray between neighbouring
// samples of [at] (0 to 1 in [steps]), and the most it moves in all.
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

double _largest(List<double> reach) =>
    [for (var i = 1; i < reach.length; i++) (reach[i] - reach[i - 1]).abs()]
        .reduce(math.max);

// A frame's share of the whole move at a linear 200 ms (16 of 200), three
// times over, and half a pixel.
double _rate(List<double> reach) {
  final span = reach.reduce(math.max) - reach.reduce(math.min);
  return 3 * span * 16 / 200 + 0.5;
}

List<String> _printed(void Function() body) {
  final lines = <String>[];
  final print = debugPrint;
  debugPrint = (message, {wrapWidth}) => lines.add(message ?? '');
  try {
    body();
  } finally {
    debugPrint = print;
  }
  return lines;
}

// --- A look in miniature: its theme holds a scheme, its limits and a card
// style; its card reads its style's corners over its theme's, held to the
// limits, drawn in the scheme's scale, and morphs the border it resolves to
// (its design moves its shapes).

class _DeckTheme extends InheritedWidget {
  const _DeckTheme({
    required this.scheme,
    required this.limits,
    required this.card,
    required super.child,
  });

  final RawShapeScheme scheme;
  final RawShapeLimits limits;
  final RawStyle card;

  static _DeckTheme of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_DeckTheme>()!;

  @override
  bool updateShouldNotify(_DeckTheme old) =>
      scheme != old.scheme || limits != old.limits || card != old.card;
}

class _SchemeTween extends Tween<RawShapeScheme> {
  _SchemeTween({super.begin});

  @override
  RawShapeScheme lerp(double t) => RawShapeScheme.lerp(begin!, end!, t);
}

class _StyleTween extends Tween<RawStyle> {
  _StyleTween({super.begin});

  @override
  RawStyle lerp(double t) => RawStyle.lerp(begin, end, t)!;
}

// The theme lerped as AnimatedTheme lerps Material's: linear, 200 ms.
class _AnimatedDeckTheme extends ImplicitlyAnimatedWidget {
  const _AnimatedDeckTheme({
    required this.scheme,
    required this.limits,
    this.card = const RawStyle(),
    required this.child,
  }) : super(duration: const Duration(milliseconds: 200));

  final RawShapeScheme scheme;
  final RawShapeLimits limits;
  final RawStyle card;
  final Widget child;

  @override
  AnimatedWidgetBaseState<_AnimatedDeckTheme> createState() =>
      _AnimatedDeckThemeState();
}

class _AnimatedDeckThemeState
    extends AnimatedWidgetBaseState<_AnimatedDeckTheme> {
  _SchemeTween? _scheme;
  _StyleTween? _card;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _scheme = visitor(
      _scheme,
      widget.scheme,
      (v) => _SchemeTween(begin: v as RawShapeScheme),
    ) as _SchemeTween?;
    _card = visitor(
      _card,
      widget.card,
      (v) => _StyleTween(begin: v as RawStyle),
    ) as _StyleTween?;
  }

  @override
  Widget build(BuildContext context) => _DeckTheme(
    scheme: _scheme!.evaluate(animation),
    limits: widget.limits,
    card: _card!.evaluate(animation),
    child: widget.child,
  );
}

class _DeckCard extends StatelessWidget {
  const _DeckCard({this.style, this.states = const {}, this.morph = true});

  final RawStyle? style;
  final Set<WidgetState> states;

  // Whether the card morphs the border it resolves to; false, the probe's
  // control.
  final bool morph;

  @override
  Widget build(BuildContext context) {
    final theme = _DeckTheme.of(context);
    final look = RawStyleOf([style, theme.card], states);
    final corners = theme.limits.clampCorners(
      look.corners,
      base: _medium,
      look: 'Deck',
    );
    final border = look.shape ?? theme.scheme.corners.borderOf(corners);
    Widget face(ShapeBorder shape) => SizedBox(
      width: 100,
      height: 60,
      child: DecoratedBox(
        key: const ValueKey('face'),
        decoration: ShapeDecoration(
          color: const Color(0xFF808080),
          shape: shape,
        ),
      ),
    );
    if (!morph) return face(border);
    return TweenAnimationBuilder<ShapeBorder?>(
      tween: ShapeBorderTween(end: border),
      duration: const Duration(milliseconds: 200),
      builder: (context, shape, _) => face(shape!),
    );
  }
}

const _deckLimits = RawShapeLimits(
  styles: {RawCornerStyle.bevel, RawCornerStyle.round},
  medium: RawBand(8, 24),
  large: RawBand(12, 32),
  cornerFreedom: RawCornerFreedom.perCorner,
);

ShapeBorder _shown(WidgetTester tester) =>
    (tester
                .renderObject<RenderDecoratedBox>(
                  find.byKey(const ValueKey('face')),
                )
                .decoration
            as ShapeDecoration)
        .shape;

Widget _app(Widget child, {TextDirection direction = _ltr}) => Directionality(
  textDirection: direction,
  child: Center(child: child),
);

void main() {
  group('RawCorners', () {
    test('over keeps each corner given, else the base\'s; only squares the '
        'rest; all gives every corner one step', () {
      expect(
        _diagonal.over(_medium),
        const RawCorners(
          topStart: RawCorner.medium,
          topEnd: RawCorner.none,
          bottomStart: RawCorner.none,
          bottomEnd: RawCorner.medium,
        ),
      );
      expect(const RawCorners().over(_medium), _medium);
      expect(
        const RawCorners.only(topStart: RawCorner.large),
        const RawCorners(
          topStart: RawCorner.large,
          topEnd: RawCorner.none,
          bottomStart: RawCorner.none,
          bottomEnd: RawCorner.none,
        ),
      );
      expect(
        const RawCorners.only(topStart: RawCorner.large).over(_medium),
        const RawCorners.only(topStart: RawCorner.large),
      );
      expect(
        _medium,
        const RawCorners(
          topStart: RawCorner.medium,
          topEnd: RawCorner.medium,
          bottomStart: RawCorner.medium,
          bottomEnd: RawCorner.medium,
        ),
      );
    });

    test('isEmpty and isUniform read the corners given', () {
      expect(const RawCorners().isEmpty, isTrue);
      expect(_diagonal.isEmpty, isFalse);
      expect(const RawCorners().isUniform, isTrue);
      expect(_diagonal.isUniform, isTrue, reason: 'both given are none');
      expect(const RawCorners(topStart: RawCorner.large).isUniform, isTrue);
      expect(_medium.isUniform, isTrue);
      expect(const RawCorners.only(topStart: RawCorner.large).isUniform, false);
      expect(_diagonal.over(_medium).isUniform, isFalse);
    });

    test(
      '== and hashCode; toString and diagnostics name the corners given',
      () {
        expect(
          _diagonal,
          const RawCorners(bottomStart: RawCorner.none, topEnd: RawCorner.none),
        );
        expect(
          _diagonal.hashCode,
          const RawCorners(
            bottomStart: RawCorner.none,
            topEnd: RawCorner.none,
          ).hashCode,
        );
        expect(_diagonal, isNot(const RawCorners(topEnd: RawCorner.none)));
        expect('$_diagonal', 'RawCorners(topEnd: none, bottomStart: none)');
        final builder = DiagnosticPropertiesBuilder();
        _diagonal.debugFillProperties(builder);
        expect(
          builder.properties
              .where((p) => !p.isFiltered(DiagnosticLevel.info))
              .map((p) => p.name),
          ['topEnd', 'bottomStart'],
        );
      },
    );
  });

  group('borderOf', () {
    test('every corner one step: the same border as border()', () {
      final bevel = _scale(RawCornerStyle.bevel);
      expect(bevel.borderOf(_medium), bevel.border(RawCorner.medium));
      expect(bevel.borderOf(const RawCorners()), bevel.border(RawCorner.none));
      const side = BorderSide(width: 2);
      expect(
        bevel.borderOf(const RawCorners.all(RawCorner.full), side: side),
        bevel.border(RawCorner.full, side: side),
      );
      expect(
        bevel.borderOf(_diagonal.over(_medium)).borderRadius,
        const BorderRadiusDirectional.only(
          topStart: Radius.circular(20),
          bottomEnd: Radius.circular(20),
        ),
      );
    });

    for (final MapEntry(key: style, value: (held, cut)) in _probes.entries) {
      test('a ${style.name} border cuts the corners given and keeps the others '
          'square, mirrored right to left', () {
        final border = _scale(style).borderOf(_diagonal.over(_medium));
        final h = _corners(held), c = _corners(cut);
        final ltr = border.getOuterPath(_rect, textDirection: _ltr);
        expect(ltr.contains(h[0]), isTrue);
        expect(ltr.contains(c[0]), isFalse, reason: 'top start cut');
        expect(ltr.contains(c[1]), isTrue, reason: 'top end square');
        expect(ltr.contains(const Offset(99.5, 0.5)), isTrue);
        expect(ltr.contains(c[2]), isFalse, reason: 'bottom end cut');
        expect(ltr.contains(c[3]), isTrue, reason: 'bottom start square');
        final rtl = border.getOuterPath(_rect, textDirection: _rtl);
        expect(rtl.contains(c[0]), isTrue, reason: 'top end square');
        expect(rtl.contains(const Offset(0.5, 0.5)), isTrue);
        expect(rtl.contains(h[1]), isTrue);
        expect(rtl.contains(c[1]), isFalse, reason: 'top start cut');
        expect(rtl.contains(c[2]), isTrue, reason: 'bottom start square');
        expect(rtl.contains(c[3]), isFalse, reason: 'bottom end cut');
      });
    }

    test('a round border with corners of their own stays on the RRect fast '
        'path; the other styles draw a path', () {
      final round = _scale(RawCornerStyle.round)
          .borderOf(_diagonal.over(_medium));
      expect(
        (Canvas canvas) =>
            round.paintInterior(canvas, _rect, _paint, textDirection: _ltr),
        paints..rrect(
          rrect: RRect.fromRectAndCorners(
            _rect,
            topLeft: const Radius.circular(20),
            bottomRight: const Radius.circular(20),
          ),
        ),
      );
      expect(
        (Canvas canvas) =>
            round.paintInterior(canvas, _rect, _paint, textDirection: _rtl),
        paints..rrect(
          rrect: RRect.fromRectAndCorners(
            _rect,
            topRight: const Radius.circular(20),
            bottomLeft: const Radius.circular(20),
          ),
        ),
      );
      final bevel = _scale(RawCornerStyle.bevel)
          .borderOf(_diagonal.over(_medium));
      expect(
        (Canvas canvas) =>
            bevel.paintInterior(canvas, _rect, _paint, textDirection: _ltr),
        paintsExactlyCountTimes(#drawPath, 1),
      );
    });

    test('a full corner reaches half the shorter side, at most '
        'fullMaxRadius; corners that would overlap shrink together', () {
      const end = RawCorners.only(
        topEnd: RawCorner.full,
        bottomEnd: RawCorner.full,
      );
      void rrect(RawCornerBorder border, TextDirection direction, RRect to) =>
          expect(
            (Canvas canvas) => border.paintInterior(
              canvas,
              _rect,
              _paint,
              textDirection: direction,
            ),
            paints..rrect(rrect: to),
          );
      final d = const RawCornerScale().borderOf(end);
      rrect(
        d,
        _ltr,
        RRect.fromRectAndCorners(
          _rect,
          topRight: const Radius.circular(30),
          bottomRight: const Radius.circular(30),
        ),
      );
      rrect(
        d,
        _rtl,
        RRect.fromRectAndCorners(
          _rect,
          topLeft: const Radius.circular(30),
          bottomLeft: const Radius.circular(30),
        ),
      );
      expect(d.full, isFalse);
      expect('$d', contains('full at topEnd, bottomEnd'));
      rrect(
        const RawCornerScale(fullMaxRadius: 12).borderOf(end),
        _ltr,
        RRect.fromRectAndCorners(
          _rect,
          topRight: const Radius.circular(12),
          bottomRight: const Radius.circular(12),
        ),
      );
      rrect(
        const RawCornerScale(large: 40).borderOf(
          const RawCorners.only(
            topEnd: RawCorner.full,
            bottomEnd: RawCorner.large,
          ),
        ),
        _ltr,
        RRect.fromRectAndCorners(
          _rect,
          topRight: const Radius.circular(30),
          bottomRight: const Radius.circular(40),
        ).scaleRadii(),
      );
    });
  });

  group('clampCorners', () {
    test('a fixed look keeps the part\'s own and says so once', () {
      const fixed = RawShapeLimits();
      expect(fixed.cornerFreedom, RawCornerFreedom.fixed);
      final lines = _printed(() {
        for (var i = 0; i < 3; i++) {
          expect(
            fixed.clampCorners(_diagonal, base: _medium, look: 'Fixed test'),
            _medium,
          );
        }
        expect(fixed.clampCorners(null, base: _medium), _medium);
        expect(
          fixed.clampCorners(
            const RawCorners(topStart: RawCorner.medium),
            base: _medium,
            look: 'Quiet test',
          ),
          _medium,
          reason: 'an override that changes nothing is no news',
        );
      });
      expect(lines, [
        'Fixed test ignores a corners override: its corners are fixed.',
      ]);
    });

    test('a uniform look takes an override that leaves all four corners one '
        'step over the part\'s own, and ignores one that leaves them '
        'differing', () {
      const uniform = RawShapeLimits(cornerFreedom: RawCornerFreedom.uniform);
      final lines = _printed(() {
        expect(
          uniform.clampCorners(
            const RawCorners.all(RawCorner.small),
            base: _medium,
            look: 'Uniform test',
          ),
          const RawCorners.all(RawCorner.small),
        );
        expect(
          uniform.clampCorners(
            const RawCorners(topStart: RawCorner.large),
            base: const RawCorners(
              topStart: RawCorner.small,
              topEnd: RawCorner.large,
              bottomStart: RawCorner.large,
              bottomEnd: RawCorner.large,
            ),
            look: 'Uniform test',
          ),
          const RawCorners.all(RawCorner.large),
          reason: 'a partial override that leaves the four equal',
        );
        expect(
          uniform.clampCorners(_diagonal, base: _medium, look: 'Uniform test'),
          _medium,
          reason: 'two diagonal cuts are not squared all round',
        );
        expect(
          uniform.clampCorners(
            const RawCorners(topStart: RawCorner.large),
            base: _medium,
            look: 'Uniform test',
          ),
          _medium,
        );
        for (var i = 0; i < 2; i++) {
          expect(
            uniform.clampCorners(
              const RawCorners.only(topStart: RawCorner.large),
              base: _medium,
              look: 'Uniform test',
            ),
            _medium,
          );
        }
      });
      expect(lines, [
        'Uniform test ignores a corners override whose corners differ: it '
            'takes one step on every corner.',
      ]);
    });

    test('a per-corner look takes each corner given', () {
      const free = RawShapeLimits(cornerFreedom: RawCornerFreedom.perCorner);
      expect(
        free.clampCorners(_diagonal, base: _medium),
        _diagonal.over(_medium),
      );
      expect(
        free.clampCorners(
          const RawCorners.only(topStart: RawCorner.large),
          base: _medium,
        ),
        const RawCorners.only(topStart: RawCorner.large),
      );
      expect(free.clampCorners(const RawCorners(), base: _medium), _medium);
    });

    test('a step the look does not allow goes to the nearest, the larger on '
        'a tie, told once', () {
      const steps = RawShapeLimits(
        cornerFreedom: RawCornerFreedom.perCorner,
        cornerSteps: {
          RawCorner.extraSmall,
          RawCorner.medium,
          RawCorner.large,
          RawCorner.full,
        },
      );
      expect(steps.nearestStep(RawCorner.none), RawCorner.extraSmall);
      expect(steps.nearestStep(RawCorner.small), RawCorner.medium);
      expect(steps.nearestStep(RawCorner.extraLarge), RawCorner.full);
      expect(steps.nearestStep(RawCorner.medium), RawCorner.medium);
      expect(
        const RawShapeLimits().nearestStep(RawCorner.small),
        RawCorner.small,
      );
      final lines = _printed(() {
        expect(
          steps.clampCorners(_diagonal, base: _medium, look: 'Steps test'),
          const RawCorners(
            topStart: RawCorner.medium,
            topEnd: RawCorner.extraSmall,
            bottomStart: RawCorner.extraSmall,
            bottomEnd: RawCorner.medium,
          ),
        );
        expect(
          const RawShapeLimits(
            cornerFreedom: RawCornerFreedom.uniform,
            cornerSteps: {RawCorner.small, RawCorner.large},
          ).clampCorners(
            const RawCorners.all(RawCorner.none),
            base: _medium,
            look: 'Steps test',
          ),
          const RawCorners.all(RawCorner.small),
          reason: 'a uniform look holds its one step too',
        );
      });
      expect(lines, [
        'Steps test holds corner none to extraSmall, the nearest step it '
            'allows.',
      ]);
    });

    test('every corner lies in its step\'s band, scaled(3) and scaled(0) '
        'alike', () {
      const limits = RawShapeLimits(
        small: RawBand(6, 12),
        medium: RawBand(10, 18),
        large: RawBand(14, 24),
        cornerFreedom: RawCornerFreedom.perCorner,
      );
      const scale = RawCornerScale(medium: 14, large: 18);
      const asked = RawCorners(
        topStart: RawCorner.small,
        topEnd: RawCorner.none,
        bottomEnd: RawCorner.large,
      );
      BorderRadius radii(double factor) => limits
          .clamp(RawShapeScheme(corners: scale.scaled(factor)))
          .corners
          .borderOf(limits.clampCorners(asked, base: _medium))
          .borderRadius
          .resolve(_ltr);
      expect(
        radii(3),
        const BorderRadius.only(
          topLeft: Radius.circular(12),
          bottomRight: Radius.circular(24),
          bottomLeft: Radius.circular(18),
        ),
      );
      expect(
        radii(0),
        const BorderRadius.only(
          topLeft: Radius.circular(6),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(10),
        ),
      );
    });

    test('limits compare and describe their corner freedom and steps', () {
      const a = RawShapeLimits(
        cornerFreedom: RawCornerFreedom.uniform,
        cornerSteps: {RawCorner.small, RawCorner.large},
      );
      const b = RawShapeLimits(
        cornerFreedom: RawCornerFreedom.uniform,
        cornerSteps: {RawCorner.large, RawCorner.small},
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(const RawShapeLimits()));
      expect(
        a,
        isNot(const RawShapeLimits(cornerFreedom: RawCornerFreedom.uniform)),
      );
      final builder = DiagnosticPropertiesBuilder();
      a.debugFillProperties(builder);
      final shown = builder.properties
          .where((p) => !p.isFiltered(DiagnosticLevel.info))
          .map((p) => p.name);
      expect(shown, containsAll(['cornerFreedom', 'cornerSteps']));
      final plain = DiagnosticPropertiesBuilder();
      const RawShapeLimits().debugFillProperties(plain);
      expect(
        plain.properties
            .where((p) => !p.isFiltered(DiagnosticLevel.info))
            .map((p) => p.name),
        isNot(contains('cornerFreedom')),
      );
    });
  });

  group('morphs between corners', () {
    for (final style in RawCornerStyle.values) {
      test('a ${style.name} corner from none to its step grows from the '
          'point, with no jump', () {
        final scale = _scale(style);
        final square = scale.borderOf(
          const RawCorners(topStart: RawCorner.none).over(_medium),
        );
        final step = scale.borderOf(_medium);
        final m = _motion((t) => ShapeBorder.lerp(square, step, t)!);
        expect(m.span, greaterThan(2));
        if (style == RawCornerStyle.step) {
          // A stair takes its count in whole steps as it grows (two under
          // 8, three to 16, four above): it moves at most a riser, 16 / 3.
          expect(m.step, lessThanOrEqualTo(16 / 3 + 0.5), reason: '$m');
        } else {
          expect(_smooth(m, 30), isTrue, reason: '$m');
        }
        expect(
          _reach(ShapeBorder.lerp(square, step, 0)!, _rays[4]),
          closeTo(_reach(square, _rays[4]), 0.01),
        );
        expect(
          _reach(ShapeBorder.lerp(square, step, 1)!, _rays[4]),
          closeTo(_reach(step, _rays[4]), 0.01),
        );
      });
    }

    test('a full corner and a step morph into each other', () {
      final scale = _scale(RawCornerStyle.bevel);
      final full = scale.borderOf(
        const RawCorners(topStart: RawCorner.full).over(_medium),
      );
      final step = scale.borderOf(_medium);
      final m = _motion((t) => ShapeBorder.lerp(full, step, t)!);
      expect(m.span, greaterThan(2));
      expect(_smooth(m, 30), isTrue, reason: '$m');
    });

    Future<List<double>> frames(
      WidgetTester tester, {
      required ShapeBorder from,
      required ShapeBorder to,
      required TextDirection direction,
      int? reverseAt,
    }) async {
      var pressed = false;
      late StateSetter setPressed;
      await tester.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, setState) {
              setPressed = setState;
              return TweenAnimationBuilder<ShapeBorder?>(
                tween: ShapeBorderTween(begin: from, end: pressed ? to : from),
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
          direction: direction,
        ),
      );
      double read() => _reach(_shown(tester), _rays[4], direction: direction);
      final reach = <double>[read()];
      setPressed(() => pressed = true);
      for (var f = 0; f < 20; f++) {
        await tester.pump(const Duration(milliseconds: 16));
        reach.add(read());
        if (f == reverseAt) setPressed(() => pressed = false);
      }
      return reach;
    }

    for (final direction in [_ltr, _rtl]) {
      testWidgets('a ShapeBorderTween from no override to one moves every '
          'frame within its rate, and back from halfway (${direction.name})', (
        tester,
      ) async {
        final scale = _scale(RawCornerStyle.bevel);
        final from = scale.border(RawCorner.medium);
        // Top start large: the top left grows in LTR and goes square in RTL.
        final to = scale.borderOf(
          const RawCorners.only(topStart: RawCorner.large),
        );
        final there = await frames(
          tester,
          from: from,
          to: to,
          direction: direction,
        );
        expect(
          there.last,
          closeTo(_reach(to, _rays[4], direction: direction), 0.01),
        );
        expect(there.first - there.last, isNot(closeTo(0, 2)));
        expect(_largest(there), lessThanOrEqualTo(_rate(there)));
        final back = await frames(
          tester,
          from: from,
          to: to,
          direction: direction,
          reverseAt: 5,
        );
        expect(_largest(back), lessThanOrEqualTo(_rate(there)));
      });
    }
  });

  group('ink and hits follow the corners given', () {
    for (final MapEntry(key: style, value: (held, cut)) in _probes.entries) {
      testWidgets('an ink splash stays out of a cut ${style.name} corner and '
          'fills a square one', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Center(
              child: SizedBox(
                width: 100,
                height: 60,
                child: Material(
                  child: InkWell(
                    customBorder: _scale(style)
                        .borderOf(_diagonal.over(_medium)),
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
              includes: [
                const Offset(50, 30),
                held,
                const Offset(99, 1),
                const Offset(1, 59),
              ],
              excludes: [cut, const Offset(1, 1), const Offset(99, 59)],
            ),
          ),
        );
        await gesture.up();
        await tester.pumpAndSettle();
      });

      testWidgets('a ShapeBorderClipper takes no tap in a cut ${style.name} '
          'corner, right to left', (tester) async {
        var taps = 0;
        await tester.pumpWidget(
          Center(
            child: SizedBox(
              key: const ValueKey('box'),
              width: 100,
              height: 60,
              child: ClipPath(
                clipper: ShapeBorderClipper(
                  shape: _scale(style).borderOf(_diagonal.over(_medium)),
                  textDirection: _rtl,
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
        await tester.tapAt(origin + _corners(cut)[1]);
        expect(taps, 0);
        await tester.tapAt(origin + const Offset(1, 1));
        expect(taps, 1, reason: 'top end square');
        await tester.tapAt(origin + _corners(held)[1]);
        expect(taps, 2);
      });
    }
  });

  test('inset and outset keep a square corner square and a full corner '
      'full', () {
    final border = const RawCornerScale(medium: 20).borderOf(
      const RawCorners(
        topStart: RawCorner.medium,
        topEnd: RawCorner.none,
        bottomStart: RawCorner.none,
        bottomEnd: RawCorner.full,
      ),
    );
    void rrect(ShapeBorder b, Rect rect, TextDirection direction, RRect to) =>
        expect(
          (Canvas canvas) =>
              b.paintInterior(canvas, rect, _paint, textDirection: direction),
          paints..rrect(rrect: to),
        );
    final inner = _rect.deflate(3);
    rrect(
      border.inset(const EdgeInsets.all(3)),
      inner,
      _ltr,
      RRect.fromRectAndCorners(
        inner,
        topLeft: const Radius.circular(17),
        bottomRight: const Radius.circular(27),
      ),
    );
    rrect(
      border.inset(const EdgeInsets.all(3)),
      inner,
      _rtl,
      RRect.fromRectAndCorners(
        inner,
        topRight: const Radius.circular(17),
        bottomLeft: const Radius.circular(27),
      ),
    );
    final outer = _rect.inflate(2);
    rrect(
      border.outset(const EdgeInsets.all(2)),
      outer,
      _ltr,
      RRect.fromRectAndCorners(
        outer,
        topLeft: const Radius.circular(22),
        bottomRight: const Radius.circular(32),
      ),
    );
  });

  group("a look's card reads its style's corners", () {
    Widget deck(
      Widget card, {
      RawShapeScheme scheme = const RawShapeScheme(
        corners: RawCornerScale(style: RawCornerStyle.bevel),
      ),
      RawShapeLimits limits = _deckLimits,
      RawStyle cardTheme = const RawStyle(),
      TextDirection direction = _ltr,
    }) => _app(
      _AnimatedDeckTheme(
        scheme: limits.clamp(scheme, look: 'Deck'),
        limits: limits,
        card: cardTheme,
        child: card,
      ),
      direction: direction,
    );

    const scale = RawCornerScale(style: RawCornerStyle.bevel);

    testWidgets('the corners given, in the theme\'s scale; shape wins; a fixed '
        'look keeps its own', (tester) async {
      await tester.pumpWidget(
        deck(
          const _DeckCard(
            style: RawStyle(corners: WidgetStatePropertyAll(_diagonal)),
          ),
        ),
      );
      expect(_shown(tester), scale.borderOf(_diagonal.over(_medium)));
      await tester.pumpWidget(
        deck(
          const _DeckCard(),
          cardTheme: const RawStyle(corners: WidgetStatePropertyAll(_diagonal)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _shown(tester),
        scale.borderOf(_diagonal.over(_medium)),
        reason: "from the card's component theme",
      );
      await tester.pumpWidget(
        deck(
          const _DeckCard(
            style: RawStyle(
              shape: WidgetStatePropertyAll(StadiumBorder()),
              corners: WidgetStatePropertyAll(_diagonal),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_shown(tester), const StadiumBorder());
      final print = debugPrint;
      final told = <String>[];
      debugPrint = (message, {wrapWidth}) => told.add(message ?? '');
      try {
        await tester.pumpWidget(
          deck(
            const _DeckCard(
              style: RawStyle(corners: WidgetStatePropertyAll(_diagonal)),
            ),
            limits: const RawShapeLimits(styles: {RawCornerStyle.bevel}),
          ),
        );
      } finally {
        debugPrint = print;
      }
      await tester.pumpAndSettle();
      expect(_shown(tester), scale.border(RawCorner.medium));
      expect(told, ['Deck ignores a corners override: its corners are fixed.']);
    });

    testWidgets('pressed takes other corners: the card morphs every frame '
        'within its rate, and back when let go halfway', (tester) async {
      final style = RawStyle(
        corners: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.pressed)
              ? const RawCorners(topStart: RawCorner.none)
              : null,
        ),
      );
      Future<List<double>> run({int? releaseAt}) async {
        var pressed = false;
        late StateSetter set;
        await tester.pumpWidget(
          deck(
            StatefulBuilder(
              builder: (context, setState) {
                set = setState;
                return _DeckCard(
                  style: style,
                  states: {if (pressed) WidgetState.pressed},
                );
              },
            ),
          ),
        );
        await tester.pumpAndSettle();
        double read() => _reach(_shown(tester), _rays[4]);
        final reach = <double>[read()];
        set(() => pressed = true);
        for (var f = 0; f < 20; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          reach.add(read());
          if (f == releaseAt) set(() => pressed = false);
        }
        return reach;
      }

      final there = await run();
      expect(
        there.last,
        closeTo(
          _reach(
            scale.borderOf(
              const RawCorners(topStart: RawCorner.none).over(_medium),
            ),
            _rays[4],
          ),
          0.01,
        ),
      );
      expect(there.first - there.last, isNot(closeTo(0, 2)));
      expect(_largest(there), lessThanOrEqualTo(_rate(there)));
      final back = await run(releaseAt: 5);
      expect(_largest(back), lessThanOrEqualTo(_rate(there)));
    });

    for (final direction in [_ltr, _rtl]) {
      testWidgets('a theme switch whose scale changes moves a card with a '
          'corners override every frame within the lerp rate; the square '
          'corners stay square (${direction.name})', (tester) async {
        const card = _DeckCard(
          style: RawStyle(corners: WidgetStatePropertyAll(_diagonal)),
        );
        const from = RawShapeScheme(
          corners: RawCornerScale(style: RawCornerStyle.bevel, medium: 10),
        );
        const to = RawShapeScheme(corners: RawCornerScale(medium: 24));
        await tester.pumpWidget(deck(card, scheme: from, direction: direction));
        // The corner the override keeps (top start) and one it squares
        // (top end), wherever the direction puts them.
        final rtl = direction == _rtl;
        double kept() =>
            _reach(_shown(tester), _rays[4], direction: direction, right: rtl);
        double squared() =>
            _reach(_shown(tester), _rays[4], direction: direction, right: !rtl);
        final square = squared();
        final reach = <double>[kept()];
        await tester.pumpWidget(deck(card, scheme: to, direction: direction));
        for (var f = 0; f < 30; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          reach.add(kept());
          expect(squared(), closeTo(square, 0.01), reason: 'frame $f');
        }
        expect(
          reach.last,
          closeTo(
            _reach(
              to.corners.borderOf(_diagonal.over(_medium)),
              _rays[4],
              direction: direction,
              right: rtl,
            ),
            0.01,
          ),
        );
        expect(reach.first - reach.last, isNot(closeTo(0, 2)));
        expect(_largest(reach), lessThanOrEqualTo(_rate(reach)));
      });
    }

    testWidgets("a theme switch that changes the card theme's corners switches "
        'them halfway, and the card morphs the border; without the morph it '
        'jumps (the probe\'s control)', (tester) async {
      const before = RawStyle(corners: WidgetStatePropertyAll(_diagonal));
      const after = RawStyle(
        corners: WidgetStatePropertyAll(RawCorners.all(RawCorner.large)),
      );
      Future<List<double>> run({required bool morph}) async {
        await tester.pumpWidget(
          deck(_DeckCard(morph: morph), cardTheme: before),
        );
        await tester.pumpAndSettle();
        // The top end: square before, large after.
        double read() => _reach(_shown(tester), _rays[4], right: true);
        final reach = <double>[read()];
        await tester.pumpWidget(
          deck(_DeckCard(morph: morph), cardTheme: after),
        );
        for (var f = 0; f < 30; f++) {
          await tester.pump(const Duration(milliseconds: 16));
          reach.add(read());
        }
        return reach;
      }

      final morphed = await run(morph: true);
      expect(
        morphed.last,
        closeTo(
          _reach(scale.border(RawCorner.large), _rays[4], right: true),
          0.01,
        ),
      );
      expect(_largest(morphed), lessThanOrEqualTo(_rate(morphed)));
      final snapped = await run(morph: false);
      expect(_largest(snapped), greaterThan(_rate(snapped)));
    });
  });
}
