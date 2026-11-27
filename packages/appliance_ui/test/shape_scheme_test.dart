// Appliance's corners are the theme's: its moulded radii by default, held to
// bands that still read as moulded plastic, read by every part, eased
// across with the theme.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

const _rounder = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 5,
    small: 8,
    medium: 10,
    large: 14,
    extraLarge: 18,
  ),
);

List<double> _radii(ApplianceThemeData t) => [
  t.radiusSmallKey,
  t.radiusKey,
  t.radiusWell,
  t.radiusTrough,
  t.radiusPanel,
  t.radiusLid,
];

double _faceRadius(WidgetTester tester, Finder part) => tester
    .widgetList<ApplianceSurface>(
      find.descendant(of: part, matching: find.byType(ApplianceSurface)),
    )
    .first
    .face
    .radius
    .topLeft
    .x;

void main() {
  test("the default corners are Appliance's own, in every palette", () {
    for (final p in ApplianceThemeData.palettes) {
      for (final b in Brightness.values) {
        final t = ApplianceThemeData.preset(p.id, b);
        expect(t.shapeScheme, ApplianceThemeData.defaultShapeScheme);
        expect(_radii(t), [6, 10, 10, 12, 14, 16]);
      }
    }
    final own = ApplianceThemeData.from(
      brightness: Brightness.dark,
      signal: const Color(0xFF4FD1C5),
    );
    expect(own.shapeScheme, ApplianceThemeData.defaultShapeScheme);
    expect(
      [
        ApplianceMetrics.smallKeyRadius,
        ApplianceMetrics.keyRadius,
        ApplianceMetrics.wellRadius,
        ApplianceMetrics.troughRadius,
        ApplianceMetrics.panelRadius,
        ApplianceMetrics.lidRadius,
      ],
      [6, 10, 10, 12, 14, 16],
    );
  });

  test("an app's corners are held to Appliance's bands, round only", () {
    final t = ApplianceThemeData.light().copyWith(
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
      [8, 14, 8, 10, 24],
    );
    expect(t.shapeScheme.stroke, isNull);
    expect(t.shapeScheme.depth, isNull);
    // The constructor holds them too, not only copyWith.
    final made = ApplianceThemeData(
      colors: ApplianceColors.preset(
        ApplianceThemeData.palettes.first.id,
        Brightness.light,
      ),
      shapeScheme: const RawShapeScheme(
        corners: RawCornerScale(
          extraSmall: 0,
          small: 0,
          medium: 0,
          large: 0,
          extraLarge: 0,
        ),
      ),
    );
    expect(_radii(made), [4, 6, 6, 8, 10, 12]);
  });

  test("three times Appliance's corners end at the bands' most", () {
    final t = ApplianceThemeData.light().copyWith(
      shapeScheme: ApplianceThemeData.defaultShapeScheme.copyWith(
        corners: ApplianceThemeData.defaultShapeScheme.corners.scaled(3),
      ),
    );
    final limits = ApplianceThemeData.shapeLimits;
    expect(
      [
        t.radiusSmallKey,
        t.radiusKey,
        t.radiusTrough,
        t.radiusPanel,
        t.radiusLid,
      ],
      [
        limits.extraSmall.max,
        limits.small.max,
        limits.medium.max,
        limits.large.max,
        limits.extraLarge.max,
      ],
    );
  });

  test('copyWith, lerp, == and hashCode see the corners', () {
    final a = ApplianceThemeData.light();
    final b = a.copyWith(shapeScheme: _rounder);
    expect(b.radiusKey, 8);
    expect(ApplianceThemeData.lerp(a, b, 0.5).radiusKey, 9);
    expect(a == b, isFalse);
    expect(b, a.copyWith(shapeScheme: _rounder));
    expect(b.hashCode, a.copyWith(shapeScheme: _rounder).hashCode);
  });

  testWidgets("the parts draw the theme's corners", (tester) async {
    final t = ApplianceThemeData.light().copyWith(shapeScheme: _rounder);
    Future<void> show(Widget part) async {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => ApplianceHost(
            light: t,
            brightness: Brightness.light,
            child: app!,
          ),
          home: Center(child: SizedBox(width: 300, child: part)),
        ),
      );
      await tester.pumpAndSettle();
    }

    await show(ApplianceButton('Save', onPressed: () {}));
    expect(_faceRadius(tester, find.byType(ApplianceButton)), 8);
    await show(const AppliancePanel(child: SizedBox(height: 40)));
    expect(_faceRadius(tester, find.byType(AppliancePanel)), 14);
    await show(
      ApplianceCheckbox(value: true, semanticLabel: 'Gift', onChanged: (_) {}),
    );
    expect(_faceRadius(tester, find.byType(ApplianceCheckbox)), 5);
  });
}
