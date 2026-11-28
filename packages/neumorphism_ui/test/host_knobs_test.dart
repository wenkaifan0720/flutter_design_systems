// NeumorphicHost takes a density and a shape scheme next to its palette and brightness, and they stand over the theme
// by day and by night: a stored palette and a depth from the app's settings go together without building both themes.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('density and depth stand over the ${brightness.name} theme', (
      tester,
    ) async {
      late NeumorphicThemeData seen;
      final palette = NeumorphicThemeData.palettes[2];
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: NeumorphicHost(
            palette: palette,
            brightness: brightness,
            density: NeumorphicDensity.compact,
            shapeScheme: NeumorphicThemeData.defaultShapeScheme.copyWith(
              depth: 1.25,
            ),
            child: Builder(
              builder: (context) {
                seen = NeumorphicTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(seen.density, NeumorphicDensity.compact);
      expect(seen.shapeScheme.depth, 1.25);
      expect(
        seen.colors.ground,
        NeumorphicThemeData.preset(palette.id, brightness).colors.ground,
      );
    });
  }
}
