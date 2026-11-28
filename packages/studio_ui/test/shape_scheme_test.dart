// Studio's corners are the theme's: its milled radii by default, held to
// bands that still read as milled hardware, read by every part, eased across
// with the theme.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _rounder = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 5,
    small: 8,
    medium: 10,
    large: 14,
    extraLarge: 18,
  ),
);

List<double> _radii(StudioThemeData t) => [
  t.radiusCap,
  t.radiusSmall,
  t.radiusKey,
  t.radiusDisplay,
  t.radiusPanel,
  t.radiusBank,
];

double _faceRadius(WidgetTester tester, Finder part) => tester
    .widgetList<StudioSurface>(
      find.descendant(of: part, matching: find.byType(StudioSurface)),
    )
    .first
    .face
    .radius;

void main() {
  test("the default corners are Studio's own, in every palette", () {
    for (final p in StudioThemeData.palettes) {
      for (final b in Brightness.values) {
        final t = StudioThemeData.preset(p.id, b);
        expect(t.shapeScheme, StudioThemeData.defaultShapeScheme);
        expect(_radii(t), [3, 5, 6, 10, 12, 10]);
      }
    }
    final own = StudioThemeData.from(indicator: const Color(0xFF4FD1C5));
    expect(own.shapeScheme, StudioThemeData.defaultShapeScheme);
  });

  test("an app's corners are held to Studio's bands, round only", () {
    final t = StudioThemeData.light().copyWith(
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          style: RawCornerStyle.bevel,
          extraSmall: 20,
          small: 40,
          medium: 0,
          large: 1,
          extraLarge: 99,
        ),
        stroke: 3,
        depth: 2,
      ),
    );
    final c = t.shapeScheme.corners;
    expect(c.style, RawCornerStyle.round);
    expect(
      [c.extraSmall, c.small, c.medium, c.large, c.extraLarge],
      [5, 8, 4, 6, 18],
    );
    expect(t.shapeScheme.stroke, isNull);
    expect(t.shapeScheme.depth, isNull);
  });

  test("three times Studio's corners end at the bands' most", () {
    final t = StudioThemeData.light().copyWith(
      shapeScheme: StudioThemeData.defaultShapeScheme.copyWith(
        corners: StudioThemeData.defaultShapeScheme.corners.scaled(3),
      ),
    );
    final limits = StudioThemeData.shapeLimits;
    expect(
      [t.radiusCap, t.radiusSmall, t.radiusKey, t.radiusDisplay, t.radiusPanel],
      [
        limits.extraSmall.max,
        limits.small.max,
        limits.medium.max,
        limits.large.max,
        limits.extraLarge.max,
      ],
    );
    // A bank stays concentric with the keys it holds.
    expect(t.radiusBank, t.radiusKey + StudioMetrics.recessInset);
  });

  test('copyWith, lerp, == and hashCode see the corners', () {
    final a = StudioThemeData.light();
    final b = a.copyWith(shapeScheme: _rounder);
    expect(b.radiusKey, 10);
    expect(StudioThemeData.lerp(a, b, 0.5).radiusKey, 8);
    expect(a == b, isFalse);
    expect(b, a.copyWith(shapeScheme: _rounder));
    expect(b.hashCode, a.copyWith(shapeScheme: _rounder).hashCode);
  });

  testWidgets("the parts draw the theme's corners", (tester) async {
    final t = StudioThemeData.light().copyWith(shapeScheme: _rounder);
    Future<void> show(Widget part) => tester.pumpWidget(
      MaterialApp(
        builder: (context, app) => StudioHost(theme: t, child: app!),
        home: Center(child: SizedBox(width: 300, child: part)),
      ),
    );
    await show(StudioButton('Save', onPressed: () {}));
    await tester.pumpAndSettle();
    expect(_faceRadius(tester, find.byType(StudioButton)), 10);
    await show(const StudioPanel(child: SizedBox(height: 40)));
    await tester.pumpAndSettle();
    expect(_faceRadius(tester, find.byType(StudioPanel)), 18);
    await show(
      StudioKeyRow(
        items: [StudioKeyRowItem(label: 'Cut', onPressed: () {})],
      ),
    );
    await tester.pumpAndSettle();
    expect(_faceRadius(tester, find.byType(StudioKeyRow)), 14);
  });
}
