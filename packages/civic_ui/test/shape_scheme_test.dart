// Civic's shapes an app can change: its corner steps, each held to a band
// where it still reads as a public service's plain forms; no stroke and no
// depth open.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

RawShapeScheme _scheme({
  RawCornerStyle style = RawCornerStyle.round,
  double extraSmall = 2,
  double small = 4,
  double medium = 8,
  double large = 12,
  double extraLarge = 16,
  double? stroke,
  double? depth,
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

List<double> _steps(RawShapeScheme s) => [
  s.corners.extraSmall,
  s.corners.small,
  s.corners.medium,
  s.corners.large,
  s.corners.extraLarge,
];

// A tag's drawn corner, at its top start.
double _tagCorner(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(CivicTag),
      matching: find.byType(DecoratedBox),
    ),
  );
  final shape = (box.decoration as ShapeDecoration).shape as RawCornerBorder;
  return shape.borderRadius.resolve(TextDirection.ltr).topLeft.x;
}

void main() {
  test("Civic's own scheme: round corners of 2, 4, 8, 12 and 16, no stroke, no depth", () {
    for (final t in [CivicThemeData.light(), CivicThemeData.dark()]) {
      final s = t.shapeScheme;
      expect(s, CivicThemeData.defaultShapeScheme);
      expect(s.corners.style, RawCornerStyle.round);
      expect(_steps(s), [2, 4, 8, 12, 16]);
      expect(s.stroke, isNull);
      expect(s.depth, isNull);
    }
  });

  test('a scheme past the bands is held to them', () {
    final base = CivicThemeData.light();
    final low = base
        .copyWith(
          shapeScheme: _scheme(
            extraSmall: 0,
            small: 0,
            medium: 0,
            large: 0,
            extraLarge: 0,
          ),
        )
        .shapeScheme;
    expect(_steps(low), [1, 2, 4, 8, 12]);
    final high = base
        .copyWith(
          shapeScheme: _scheme(
            extraSmall: 99,
            small: 99,
            medium: 99,
            large: 99,
            extraLarge: 99,
          ),
        )
        .shapeScheme;
    expect(_steps(high), [3, 6, 12, 16, 20]);
  });

  test('corners stay round, and Civic opens no stroke and no depth', () {
    final s = CivicThemeData.light()
        .copyWith(
          shapeScheme: _scheme(
            style: RawCornerStyle.bevel,
            stroke: 2,
            depth: 1.5,
          ),
        )
        .shapeScheme;
    expect(s.corners.style, RawCornerStyle.round);
    expect(s.stroke, isNull);
    expect(s.depth, isNull);
  });

  test('a scheme inside the bands is kept as given', () {
    final s = CivicThemeData.light()
        .copyWith(shapeScheme: _scheme(small: 6, medium: 4, large: 9))
        .shapeScheme;
    expect(_steps(s), [2, 6, 4, 9, 16]);
  });

  test('the brand factory takes a scheme and holds it', () {
    final s = CivicThemeData.from(
      brightness: Brightness.light,
      shapeScheme: _scheme(medium: 40),
    ).shapeScheme;
    expect(s.corners.medium, 12);
  });

  test('the theme lerps its scheme and compares by it', () {
    final a = CivicThemeData.light();
    final b = a.copyWith(shapeScheme: _scheme(medium: 12));
    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
    expect(CivicThemeData.lerp(a, b, 0.5).shapeScheme.corners.medium, 10);
    expect(a.copyWith(), a);
  });

  testWidgets("a part takes its step from the theme's scheme", (tester) async {
    Future<double> corner(RawShapeScheme? scheme) async {
      final t = CivicThemeData.light();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: CivicTheme(
            data: scheme == null ? t : t.copyWith(shapeScheme: scheme),
            child: const Center(child: CivicTag(label: 'Due')),
          ),
        ),
      );
      return _tagCorner(tester);
    }

    expect(await corner(null), 4);
    expect(await corner(_scheme(small: 6)), 6);
    expect(await corner(_scheme(small: 99)), 6);
  });

  testWidgets(
    "a change of shapes moves across with the host's theme, never past its "
    'ends',
    (tester) async {
      Widget host(RawShapeScheme scheme) => MaterialApp(
        builder: (context, child) => CivicHost(
          theme: CivicThemeData.light().copyWith(shapeScheme: scheme),
          brightness: Brightness.light,
          child: child!,
        ),
        home: const Center(child: CivicTag(label: 'Due')),
      );
      await tester.pumpWidget(host(CivicThemeData.defaultShapeScheme));
      expect(_tagCorner(tester), 4);
      await tester.pumpWidget(host(_scheme(small: 6)));
      final seen = <double>[];
      for (var i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 20));
        seen.add(_tagCorner(tester));
      }
      for (final r in seen) {
        expect(r, inInclusiveRange(4, 6));
      }
      expect(seen.where((r) => r > 4 && r < 6).length, greaterThan(3));
      for (var i = 1; i < seen.length; i++) {
        expect(seen[i], greaterThanOrEqualTo(seen[i - 1]));
      }
      await tester.pumpAndSettle();
      expect(_tagCorner(tester), 6);
    },
  );
}
