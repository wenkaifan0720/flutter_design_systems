// ClayHost takes a density next to its palette and brightness, and it stands
// over the theme by day and by night: an app sets how tight its controls
// stand in one place, without building both themes itself.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('density stands over the ${brightness.name} theme', (
      tester,
    ) async {
      late ClayThemeData seen;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ClayHost(
            brightness: brightness,
            palette: ClayThemeData.palettes[1],
            density: ClayDensity.compact,
            child: Builder(
              builder: (context) {
                seen = ClayTheme.of(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(seen.density, ClayDensity.compact);
      expect(seen.colors.brightness, brightness);
      expect(
        seen.colors.accent,
        ClayThemeData.fromPalette(
          ClayThemeData.palettes[1],
          brightness,
        ).colors.accent,
      );
    });
  }
}
