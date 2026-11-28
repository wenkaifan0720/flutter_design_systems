// Minimal's corners are the theme's (F15): its own scale by default, held to
// bands that still read as Minimal, read by every part, eased with the
// theme. MinimalShapes(radius:) is the one-knob way to a scheme.
// ignore_for_file: deprecated_member_use, deprecated_member_use_from_same_package
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

List<double> _steps(RawShapeScheme s) => [
  s.corners.extraSmall,
  s.corners.small,
  s.corners.medium,
  s.corners.large,
  s.corners.extraLarge,
];

List<double> _radii(MinimalThemeData t) => [
  t.smallRadius,
  t.controlRadius,
  t.cardRadius,
  t.sheetRadius,
];

void main() {
  test("the default corners are Minimal's own, in every palette", () {
    for (final p in MinimalThemeData.palettes) {
      for (final b in Brightness.values) {
        final t = MinimalThemeData.preset(p.id, b);
        expect(t.shapeScheme, MinimalThemeData.defaultShapeScheme);
        expect(_steps(t.shapeScheme), [4, 8, 10, 14, 18]);
        expect(_radii(t), [4, 8, 10, 14]);
        expect(t.shapes, MinimalShapes.look);
      }
    }
    final own = MinimalThemeData.from(primary: const Color(0xFF7A1F5C));
    expect(own.shapeScheme, MinimalThemeData.defaultShapeScheme);
  });

  test("an app's corners are held to Minimal's bands, round only", () {
    const wild = RawShapeScheme(
      corners: RawCornerScale(
        style: RawCornerStyle.bevel,
        extraSmall: 20,
        small: 40,
        medium: 99,
        large: 99,
        extraLarge: 99,
      ),
      stroke: 3,
      depth: 2,
    );
    final t = MinimalThemeData.standard().copyWith(shapeScheme: wild);
    expect(_steps(t.shapeScheme), [8, 12, 14, 20, 24]);
    expect(t.shapeScheme.corners.style, RawCornerStyle.round);
    expect(t.shapeScheme.stroke, isNull);
    expect(t.shapeScheme.depth, isNull);
    final made = MinimalThemeData(
      colors: MinimalThemeData.standard().colors,
      shapeScheme: wild,
    );
    expect(made.shapeScheme, t.shapeScheme);
  });

  test('square is a step Minimal takes, the capsules square with it', () {
    final t = MinimalThemeData.standard().copyWith(
      shapeScheme: const MinimalShapes(radius: 0).scheme,
    );
    expect(_steps(t.shapeScheme), [0, 0, 0, 0, 0]);
    expect(t.shapes.pill, isNot(isA<StadiumBorder>()));
    expect(MinimalShapes.radiusOf(t.shapes.pill), 0);
  });

  test("three times Minimal's corners end at each band's most", () {
    final t = MinimalThemeData.standard().copyWith(
      shapeScheme: RawShapeScheme(
        corners: MinimalThemeData.defaultShapeScheme.corners.scaled(3),
      ),
    );
    expect(_steps(t.shapeScheme), [8, 12, 14, 20, 24]);
  });

  test('one radius sets every step, as Minimal draws them', () {
    expect(_steps(const MinimalShapes(radius: 12).scheme), [8, 12, 14, 18, 22]);
    expect(_steps(const MinimalShapes(radius: 2).scheme), [0, 2, 4, 8, 12]);
    expect(MinimalShapes.look.scheme, MinimalThemeData.defaultShapeScheme);
    final t = MinimalThemeData.standard().copyWith(
      shapeScheme: const MinimalShapes(radius: 16).scheme,
    );
    expect(_steps(t.shapeScheme), [8, 12, 14, 20, 24]);
    expect(t.shapes.radius, 12);
  });

  test('the deprecated shapes still set the scheme, until 0.10.0', () {
    final t = MinimalThemeData.standard().copyWith(
      shapes: const MinimalShapes(radius: 12),
    );
    expect(
      t.shapeScheme,
      MinimalThemeData.standard()
          .copyWith(shapeScheme: const MinimalShapes(radius: 12).scheme)
          .shapeScheme,
    );
    expect(
      () => MinimalThemeData(
        colors: MinimalThemeData.standard().colors,
        shapeScheme: MinimalThemeData.defaultShapeScheme,
        shapes: MinimalShapes.look,
      ),
      throwsAssertionError,
    );
  });

  test('copyWith, lerp, == and hashCode see the corners', () {
    final a = MinimalThemeData.standard();
    final b = a.copyWith(shapeScheme: const MinimalShapes(radius: 12).scheme);
    expect(b, isNot(a));
    expect(b.copyWith(), b);
    expect(b.copyWith().hashCode, b.hashCode);
    expect(MinimalThemeData.lerp(a, b, .5).controlRadius, 10);
    expect(MinimalThemeData.lerp(a, b, .5).cardRadius, 12);
    expect(
      a.toDiagnosticsNode().toStringDeep(),
      isNot(contains('shapeScheme')),
    );
    expect(b.toDiagnosticsNode().toStringDeep(), contains('shapeScheme'));
  });

  testWidgets("parts read the theme's corners", (tester) async {
    final t = MinimalThemeData.standard().copyWith(
      shapeScheme: const MinimalShapes(radius: 12).scheme,
    );
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            MinimalHost(light: t, brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: Column(
            children: [
              MinimalButton('Save', onPressed: () {}),
              const MinimalCard(child: Text('Plan')),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final radii = [
      for (final box in tester.widgetList<DecoratedBox>(
        find.byType(DecoratedBox),
      ))
        if (box.decoration case BoxDecoration(:final BorderRadius borderRadius))
          borderRadius.topLeft.x,
    ];
    expect(radii, containsAll(<double>[12, 14]));
  });
}
