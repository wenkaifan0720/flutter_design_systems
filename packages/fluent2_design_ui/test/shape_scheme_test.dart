// Fluent 2's corners are the theme's: Fluent's radius tokens by default,
// held to Fluent's bands, read by every part, eased across with the theme.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

const _rounder = RawShapeScheme(
  corners: RawCornerScale(
    extraSmall: 4,
    small: 8,
    medium: 10,
    large: 12,
    extraLarge: 16,
  ),
);

Widget _app(Fluent2ThemeData theme, Widget child) => MaterialApp(
  builder: (context, app) =>
      Fluent2Host(light: theme, brightness: Brightness.light, child: app!),
  home: Center(child: child),
);

BorderRadius _ringRadius(WidgetTester tester) =>
    (tester
                .widget<DecoratedBox>(
                  find
                      .descendant(
                        of: find.byType(Fluent2FocusRing),
                        matching: find.byType(DecoratedBox),
                      )
                      .first,
                )
                .decoration
            as BoxDecoration)
        .borderRadius!
        .resolve(TextDirection.ltr);

void main() {
  test("the default corners are Fluent's radius tokens, in every palette", () {
    for (final p in Fluent2ThemeData.palettes) {
      for (final b in Brightness.values) {
        final t = Fluent2ThemeData.preset(p.id, b);
        expect(t.shapeScheme, Fluent2ThemeData.defaultShapeScheme);
        expect(
          [
            t.radiusSmall,
            t.radiusMedium,
            t.radiusLarge,
            t.radiusXLarge,
            t.radius2XLarge,
          ],
          [2, 4, 6, 8, 12],
        );
      }
    }
    final own = Fluent2ThemeData.from(brand: const Color(0xFF8A3FFC));
    expect(own.shapeScheme, Fluent2ThemeData.defaultShapeScheme);
    expect(
      [
        Fluent2Radius.small,
        Fluent2Radius.medium,
        Fluent2Radius.large,
        Fluent2Radius.xLarge,
        Fluent2Radius.x2Large,
        Fluent2ChromeMetrics.layerRadius,
        Fluent2ChromeMetrics.sheetRadius,
      ],
      [2, 4, 6, 8, 12, 8, 8],
    );
  });

  test("an app's corners are held to Fluent's bands, round only", () {
    final t = Fluent2ThemeData.lapis().copyWith(
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
      [4, 8, 4, 4, 16],
    );
    expect(t.shapeScheme.stroke, isNull);
    expect(t.shapeScheme.depth, isNull);
  });

  test('every way in holds the corners; a blend is not held again', () {
    const wild = RawShapeScheme(
      corners: RawCornerScale(
        style: RawCornerStyle.bevel,
        extraSmall: 20,
        small: 40,
        medium: 0,
        large: 1,
        extraLarge: 99,
      ),
      stroke: 3,
    );
    final made = Fluent2ThemeData.from(
      brand: const Color(0xFF8A3FFC),
      shapeScheme: wild,
    );
    final copied = Fluent2ThemeData.lapis().copyWith(shapeScheme: wild);
    expect(made.shapeScheme, copied.shapeScheme);
    expect(made.shapeScheme.corners.style, RawCornerStyle.round);
    expect(made.radiusMedium, 8);
    expect(made.shapeScheme.stroke, isNull);
    // A spring may pass a band's end for a moment; the blend keeps it.
    final a = Fluent2ThemeData.lapis();
    final b = a.copyWith(shapeScheme: _rounder);
    expect(a.lerp(b, 1.5).radiusMedium, 10);
    expect(a.lerp(b, 1.5).copyWith().radiusMedium, 8);
  });

  test("three times Fluent's corners end at Fluent's most", () {
    final t = Fluent2ThemeData.lapis().copyWith(
      shapeScheme: Fluent2ThemeData.defaultShapeScheme.copyWith(
        corners: Fluent2ThemeData.defaultShapeScheme.corners.scaled(3),
      ),
    );
    final limits = Fluent2ThemeData.shapeLimits;
    expect(
      [
        t.radiusSmall,
        t.radiusMedium,
        t.radiusLarge,
        t.radiusXLarge,
        t.radius2XLarge,
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

  test('from() takes the corners, and lerp, == and hashCode see them', () {
    final own = Fluent2ThemeData.from(
      brand: const Color(0xFF8A3FFC),
      shapeScheme: _rounder,
    );
    expect(own.radiusMedium, 8);
    final a = Fluent2ThemeData.lapis();
    final b = a.copyWith(shapeScheme: _rounder);
    expect(a.lerp(b, 0.5).radiusMedium, 6);
    expect(a == b, isFalse);
    expect(b, a.copyWith(shapeScheme: _rounder));
    expect(b.hashCode, a.copyWith(shapeScheme: _rounder).hashCode);
  });

  testWidgets("the parts draw the theme's corners", (tester) async {
    final t = Fluent2ThemeData.lapis().copyWith(shapeScheme: _rounder);
    await tester.pumpWidget(
      _app(t, const SizedBox(width: 80, height: 40, child: Fluent2FocusRing())),
    );
    expect(_ringRadius(tester).topLeft.x, 8);
    await tester.pumpWidget(_app(t, Fluent2Button('Save', onPressed: () {})));
    await tester.pumpAndSettle();
    final face = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byType(Fluent2Button),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .firstWhere((d) => d.borderRadius != null);
    expect(face.borderRadius!.resolve(TextDirection.ltr).topLeft.x, 8);
    expect(Fluent2ButtonMetrics.radiusOf(Fluent2ButtonShape.rounded, 32, t), 8);
    expect(Fluent2Card.radiusOf(Fluent2CardSize.medium, t), 8);
    expect(Fluent2Card.radiusOf(Fluent2CardSize.large, t), 10);
    expect(Fluent2Avatar.squareRadius(32, t), 8);
    expect(Fluent2Avatar.squareRadius(32), 4);
  });
}
