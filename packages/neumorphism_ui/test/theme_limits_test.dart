// What an app may change and where the look holds: a theme's relief stays in the look's band, and a style's outline is
// one of the look's own borders, no corner sharper than its least.
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
  test('a theme clamps its relief to the look\'s band', () {
    NeumorphicElevation cast(NeumorphicElevation e) =>
        NeumorphicThemeData.porcelain().copyWith(elevation: e).elevation;
    expect(
      cast(const NeumorphicElevation(depth: 0, strength: 0)),
      const NeumorphicElevation(
        depth: NeumorphicElevation.leastDepth,
        strength: NeumorphicElevation.leastStrength,
      ),
    );
    expect(
      cast(const NeumorphicElevation(depth: 3)).depth,
      NeumorphicElevation.mostDepth,
    );
    const inBand = NeumorphicElevation(depth: .75, strength: .8);
    expect(cast(inBand), inBand);
    final a = NeumorphicThemeData.porcelain().copyWith(
      elevation: const NeumorphicElevation(depth: 0),
    );
    final b = NeumorphicThemeData.porcelain().copyWith(
      elevation: const NeumorphicElevation(depth: 9),
    );
    for (final t in [0.0, .3, .5, .7, 1.0]) {
      final depth = NeumorphicThemeData.lerp(a, b, t).elevation.depth;
      expect(
        depth,
        inInclusiveRange(
          NeumorphicElevation.leastDepth,
          NeumorphicElevation.mostDepth,
        ),
      );
    }
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
