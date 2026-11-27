// Clay's shapes an app can change: its corner steps and the depth of its
// relief, each held to a band where it still reads as soft clay.
import 'package:clay_ui/clay_parts.dart' show clayCornerBetween;
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

RawShapeScheme _scheme({
  RawCornerStyle style = RawCornerStyle.continuous,
  double extraSmall = 6,
  double small = 9,
  double medium = 16,
  double large = 24,
  double extraLarge = 32,
  double? stroke,
  double? depth = 1,
}) => RawShapeScheme(
  corners: RawCornerScale(
    style: style,
    extraSmall: extraSmall,
    small: small,
    medium: medium,
    large: large,
    extraLarge: extraLarge,
  ),
  stroke: stroke,
  depth: depth,
);

Future<Rect> _rectOf(WidgetTester tester, Finder f) async => tester.getRect(f);

void main() {
  setUpAll(clayLoadFonts);

  test(
    "Clay's own scheme: continuous 6, 9, 16, 24, 32, no stroke, depth 1",
    () {
      final s = ClayThemeData.clay(Brightness.light).shapeScheme;
      expect(s, ClayThemeData.defaultShapeScheme);
      expect(s.corners.style, RawCornerStyle.continuous);
      expect(
        [
          s.corners.extraSmall,
          s.corners.small,
          s.corners.medium,
          s.corners.large,
          s.corners.extraLarge,
        ],
        [6, 9, 16, 24, 32],
      );
      expect(s.stroke, isNull);
      expect(s.depth, 1);
    },
  );

  test('a scheme past the bands is held to them', () {
    final low = ClayThemeData.clay(Brightness.light)
        .copyWith(
          shapeScheme: _scheme(
            extraSmall: 0,
            small: 0,
            medium: 0,
            large: 0,
            extraLarge: 0,
            depth: 0,
          ),
        )
        .shapeScheme;
    expect(
      [
        low.corners.extraSmall,
        low.corners.small,
        low.corners.medium,
        low.corners.large,
        low.corners.extraLarge,
        low.depth,
      ],
      [4, 6, 12, 18, 24, 0.75],
    );
    final high = ClayThemeData(
      shapeScheme: _scheme(
        extraSmall: 99,
        small: 99,
        medium: 99,
        large: 99,
        extraLarge: 99,
        depth: 9,
      ),
    ).shapeScheme;
    expect(
      [
        high.corners.extraSmall,
        high.corners.small,
        high.corners.medium,
        high.corners.large,
        high.corners.extraLarge,
        high.depth,
      ],
      [8, 12, 20, 30, 40, 1.5],
    );
  });

  test('corners stay continuous and Clay draws no line', () {
    final s = ClayThemeData(
      shapeScheme: _scheme(style: RawCornerStyle.bevel, stroke: 2),
    ).shapeScheme;
    expect(s.corners.style, RawCornerStyle.continuous);
    expect(s.stroke, isNull);
  });

  test('a scheme inside the bands is kept as given', () {
    final s = ClayThemeData(
      shapeScheme: _scheme(medium: 20, large: 18, depth: 1.25),
    ).shapeScheme;
    expect(s.corners.medium, 20);
    expect(s.corners.large, 18);
    expect(s.depth, 1.25);
  });

  test('the theme lerps its scheme and compares by it', () {
    final a = ClayThemeData.clay(Brightness.light);
    final b = a.copyWith(shapeScheme: _scheme(medium: 20, depth: 1.5));
    expect(a == b, isFalse);
    final mid = ClayThemeData.lerp(a, b, 0.5).shapeScheme;
    expect(mid.corners.medium, closeTo(18, 1e-9));
    expect(mid.depth, closeTo(1.25, 1e-9));
    expect(a.copyWith(), a);
  });

  testWidgets("a part takes its step from the theme's scheme", (tester) async {
    Future<double> wellRadius(RawShapeScheme? scheme) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ClayTheme(
            data: ClayThemeData(shapeScheme: scheme),
            child: const Center(
              child: ClayWell(child: SizedBox(width: 120, height: 48)),
            ),
          ),
        ),
      );
      final surface = tester.widget<ClaySurface>(find.byType(ClaySurface));
      return surface.face.radius;
    }

    expect(await wellRadius(null), 16);
    expect(await wellRadius(_scheme(medium: 12)), 12);
    expect(await wellRadius(_scheme(medium: 99)), 20);
  });

  testWidgets('depth deepens a press: the face sinks further', (tester) async {
    Future<double> sink(double depth) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ClayTheme(
            data: ClayThemeData(shapeScheme: _scheme(depth: depth)),
            child: Center(
              child: ClaySurface(
                face: ClayFace.raised(const ClayColors.light())
                    .copyWith(press: 1),
                child: const SizedBox(key: Key('face'), width: 120, height: 48),
              ),
            ),
          ),
        ),
      );
      final rest = (await _rectOf(tester, find.byType(ClaySurface))).top;
      return (await _rectOf(tester, find.byKey(const Key('face')))).top - rest;
    }

    final flat = await sink(0.75);
    final own = await sink(1);
    final deep = await sink(1.5);
    expect(own, closeTo(1.5, 1e-9));
    expect(flat, closeTo(1.125, 1e-9));
    expect(deep, closeTo(2.25, 1e-9));
  });

  test(
    'a corner between the steps keeps its proportion to the control step',
    () {
      final theme = ClayThemeData.clay(Brightness.light);
      final squarer = theme.copyWith(
        shapeScheme: theme.shapeScheme.copyWith(
          corners: theme.shapeScheme.corners.copyWith(medium: 12),
        ),
      );
      // A key cap (7) and a table's row (10) at Clay's own control step, 16.
      expect(clayCornerBetween(theme, 7), 7);
      expect(clayCornerBetween(squarer, 7), 5.25);
      expect(clayCornerBetween(squarer, 10), 7.5);
    },
  );
}
