// What an app may change and where the look holds: a theme's corners and relief stay in the look's bands and every
// radius moves with its step, and a style's outline is one of the look's own borders, no corner sharper than its least.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

Future<void> _mount(WidgetTester tester, OutlinedBorder shape) =>
    tester.pumpWidget(
      MaterialApp(
        home: NeumorphicTheme(
          data: NeumorphicThemeData.porcelain(),
          child: Center(
            child: NeumorphicButton(
              'Keep',
              onPressed: () {},
              style: NeumorphicStyle(shape: WidgetStatePropertyAll(shape)),
            ),
          ),
        ),
      ),
    );

void main() {
  test('a theme holds its corners and its relief to the look\'s bands', () {
    final limits = NeumorphicThemeData.shapeLimits;
    RawShapeScheme cast(RawShapeScheme s) =>
        NeumorphicThemeData.porcelain().copyWith(shapeScheme: s).shapeScheme;
    const own = NeumorphicThemeData.defaultShapeScheme;
    expect(NeumorphicThemeData.porcelain().shapeScheme, own);
    // Depth from 0.5 to 1.5: shallower reads as flat print, deeper as an object.
    expect(cast(own.copyWith(depth: 0)).depth, limits.depth!.min);
    expect(cast(own.copyWith(depth: 3)).depth, limits.depth!.max);
    expect(cast(own.copyWith(depth: .75)).depth, .75);
    // Each step held to its band; the least corner and the capsule's cap fixed.
    final low = cast(
      own.copyWith(
        corners: const RawCornerScale(
          extraSmall: 0,
          small: 0,
          medium: 0,
          large: 0,
          extraLarge: 0,
          fullMaxRadius: 0,
        ),
      ),
    ).corners;
    expect(
      (low.extraSmall, low.small, low.medium, low.large, low.fullMaxRadius),
      (6.0, 6.0, 8.0, 14.0, 24.0),
    );
    final high = cast(
      own.copyWith(
        corners: const RawCornerScale(
          extraSmall: 99,
          small: 99,
          medium: 99,
          large: 99,
          extraLarge: 99,
          fullMaxRadius: 99,
        ),
      ),
    ).corners;
    expect(
      (
        high.extraSmall,
        high.small,
        high.medium,
        high.large,
        high.fullMaxRadius,
      ),
      (6.0, 10.0, 16.0, 28.0, 24.0),
    );
    // No stroke: the relief draws every edge.
    expect(cast(own.copyWith(stroke: 2)).stroke, isNull);
    final a = NeumorphicThemeData.porcelain().copyWith(
      shapeScheme: own.copyWith(depth: 0),
    );
    final b = NeumorphicThemeData.porcelain().copyWith(
      shapeScheme: own.copyWith(depth: 9),
    );
    for (final t in [0.0, .3, .5, .7, 1.0]) {
      final depth = NeumorphicThemeData.lerp(a, b, t).shapeScheme.depth!;
      expect(depth, inInclusiveRange(limits.depth!.min, limits.depth!.max));
    }
  });

  test('a theme moves every radius with its step', () {
    final s = NeumorphicThemeData.porcelain()
        .copyWith(
          shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
            corners: NeumorphicThemeData.defaultShapeScheme.corners.copyWith(
              small: 10,
              medium: 16,
              large: 28,
            ),
          ),
        )
        .shapes;
    expect(
      (s.least, s.cap, s.chip, s.control, s.well, s.slab),
      (6.0, 10.0, 14.0, 16.0, 18.0, 28.0),
    );
    // The look's own, as drawn before a theme moved them.
    final own = NeumorphicThemeData.porcelain().shapes;
    expect(
      (own.least, own.cap, own.chip, own.control, own.well, own.slab),
      (
        NeumorphicRadii.least,
        NeumorphicRadii.cap,
        NeumorphicRadii.chip,
        NeumorphicRadii.control,
        NeumorphicRadii.well,
        NeumorphicRadii.slab,
      ),
    );
    // A chip never goes under the least corner.
    final tight = NeumorphicThemeData.porcelain()
        .copyWith(
          shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
            corners: NeumorphicThemeData.defaultShapeScheme.corners.copyWith(
              medium: 8,
            ),
          ),
        )
        .shapes;
    expect(tight.chip, NeumorphicRadii.least);
  });

  testWidgets('the look\'s own borders pass the shape rule', (tester) async {
    for (final shape in const <OutlinedBorder>[
      NeumorphicRoundedBorder(radius: NeumorphicRadii.least),
      NeumorphicRoundedBorder(radius: 20),
      NeumorphicStadiumBorder(),
      NeumorphicCircleBorder(),
    ]) {
      await _mount(tester, shape);
      expect(tester.takeException(), isNull, reason: '$shape');
    }
  });

  testWidgets('a sharp corner or a foreign border fails the shape rule', (
    tester,
  ) async {
    for (final shape in const <OutlinedBorder>[
      NeumorphicRoundedBorder(radius: 0),
      NeumorphicRoundedBorder(radius: NeumorphicRadii.least - 1),
      RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      BeveledRectangleBorder(),
    ]) {
      await _mount(tester, shape);
      final error = tester.takeException();
      expect(error, isA<AssertionError>(), reason: '$shape');
      expect('$error', contains('no sharp corner'));
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
