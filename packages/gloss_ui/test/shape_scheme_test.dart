// Gloss's corners an app can change: its five steps, each held to a band
// where it still reads as moulded porcelain; keys stay pills.
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_parts.dart' show glossPanelCorner;
import 'package:gloss_ui/gloss_ui.dart';
import 'package:material_ui/material_ui.dart';

RawShapeScheme _scheme({
  RawCornerStyle style = RawCornerStyle.round,
  double extraSmall = 7,
  double small = 12,
  double medium = 16,
  double large = 18,
  double extraLarge = 24,
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

// The corner of the first glazed surface under [of].
double? _radius(WidgetTester tester, Finder of) {
  final surface = find
      .descendant(
        of: of,
        matching: find.byWidgetPredicate(
          (w) => w is GlossSurface || w is AnimatedGlossSurface,
        ),
      )
      .first;
  final w = tester.widget(surface);
  return w is GlossSurface
      ? w.face.radius
      : (w as AnimatedGlossSurface).face.radius;
}

void main() {
  setUpAll(glossLoadFonts);

  test("0.5.1's corner constants stay as the default scheme's steps", () {
    final c = GlossThemeData.defaultShapeScheme.corners;
    // ignore: deprecated_member_use
    expect(GlossMetrics.socketRadius, c.extraSmall);
    // ignore: deprecated_member_use
    expect(GlossMetrics.fieldRadius, c.small);
    // ignore: deprecated_member_use
    expect(GlossMetrics.wellRadius, c.medium);
    // ignore: deprecated_member_use
    expect(GlossMetrics.cardRadius, c.large);
    // ignore: deprecated_member_use
    expect(GlossMetrics.panelRadius, c.extraLarge);
    // ignore: deprecated_member_use
    expect(glossPanelCorner, c.medium);
  });

  test("Gloss's own scheme: round corners of 7, 12, 16, 18 and 24, no stroke, no depth", () {
    final s = GlossThemeData.jade(Brightness.light).shapeScheme;
    expect(s, GlossThemeData.defaultShapeScheme);
    expect(s.corners.style, RawCornerStyle.round);
    expect(_steps(s), [7, 12, 16, 18, 24]);
    expect(s.stroke, isNull);
    expect(s.depth, isNull);
    for (final p in GlossThemeData.palettes) {
      for (final b in Brightness.values) {
        expect(GlossThemeData.preset(p.id, b).shapeScheme, s, reason: p.id);
      }
    }
  });

  test('a scheme past the bands is held to them', () {
    final low = GlossThemeData.jade(Brightness.light)
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
    expect(_steps(low), [5, 8, 12, 14, 18]);
    final high = GlossThemeData(
      colors: const GlossColors.light(),
      shapeScheme: _scheme(
        extraSmall: 99,
        small: 99,
        medium: 99,
        large: 99,
        extraLarge: 99,
      ),
    ).shapeScheme;
    expect(_steps(high), [9, 16, 22, 24, 32]);
  });

  test('scaled(3) ends at the most of each band', () {
    final s = GlossThemeData.jade(Brightness.light)
        .copyWith(
          shapeScheme: GlossThemeData.defaultShapeScheme.copyWith(
            corners: GlossThemeData.defaultShapeScheme.corners.scaled(3),
          ),
        )
        .shapeScheme;
    expect(_steps(s), [9, 16, 22, 24, 32]);
  });

  test('corners stay round, and Gloss opens no stroke and no depth', () {
    for (final style in RawCornerStyle.values) {
      final s = GlossThemeData(
        colors: const GlossColors.light(),
        shapeScheme: _scheme(style: style, stroke: 2, depth: 1.25),
      ).shapeScheme;
      expect(s.corners.style, RawCornerStyle.round, reason: style.name);
      expect(s.stroke, isNull);
      expect(s.depth, isNull);
    }
  });

  test('a scheme inside the bands is kept as given', () {
    final s = GlossThemeData(
      colors: const GlossColors.light(),
      shapeScheme: _scheme(small: 9, medium: 20, large: 14),
    ).shapeScheme;
    expect(_steps(s), [7, 9, 20, 14, 24]);
  });

  test('the theme lerps its scheme and compares by it', () {
    final a = GlossThemeData.jade(Brightness.light);
    final b = a.copyWith(shapeScheme: _scheme(medium: 22));
    expect(a == b, isFalse);
    expect(a.hashCode == b.hashCode, isFalse);
    expect(GlossThemeData.lerp(a, b, 0.5).shapeScheme.corners.medium, 19);
    expect(a.copyWith(), a);
  });

  testWidgets("each part takes its step from the theme's scheme", (
    tester,
  ) async {
    Future<Map<String, double?>> radii(RawShapeScheme? scheme) async {
      await tester.pumpWidget(
        MaterialApp(
          home: GlossTheme(
            data: GlossThemeData(
              colors: const GlossColors.light(),
              shapeScheme: scheme,
            ),
            child: Center(
              child: SizedBox(
                width: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const GlossWell(
                      key: Key('well'),
                      children: [GlossListTile(title: 'Basil')],
                    ),
                    const GlossCard(
                      key: Key('card'),
                      child: SizedBox(height: 40),
                    ),
                    const GlossTextField(key: Key('field'), hintText: 'Name'),
                    GlossButton.filled(
                      'Save',
                      key: const Key('key'),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      return {
        for (final k in ['well', 'card', 'field', 'key'])
          k: _radius(tester, find.byKey(Key(k))),
      };
    }

    expect(await radii(null), {
      'well': 16,
      'card': 18,
      'field': 12,
      'key': null,
    });
    expect(await radii(_scheme(small: 8, medium: 12, large: 14)), {
      'well': 12,
      'card': 14,
      'field': 8,
      'key': null,
    });
    expect(await radii(_scheme(small: 99, medium: 99, large: 99)), {
      'well': 22,
      'card': 24,
      'field': 16,
      'key': null,
    });
  });
}
