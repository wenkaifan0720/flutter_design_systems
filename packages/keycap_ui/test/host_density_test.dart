// KeycapHost takes the density beside the colourway, as an app's settings
// offer both: the themes it builds from the palette stand at that density,
// and a theme the app gives keeps its own.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  Future<KeycapThemeData> themeUnder(
    WidgetTester tester,
    KeycapHost host,
  ) async {
    late KeycapThemeData seen;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => KeycapHost(
          palette: host.palette,
          theme: host.theme,
          darkTheme: host.darkTheme,
          brightness: host.brightness,
          density: host.density,
          child: child!,
        ),
        home: Builder(
          builder: (context) {
            seen = KeycapTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    return seen;
  }

  for (final brightness in Brightness.values) {
    for (final density in [
      RawDensity.compact,
      RawDensity.comfortable,
      RawDensity.standard,
    ]) {
      testWidgets('a palette at $density by ${brightness.name}', (
        tester,
      ) async {
        final palette = KeycapThemeData.palettes[2];
        final theme = await themeUnder(
          tester,
          KeycapHost(
            palette: palette,
            brightness: brightness,
            density: density,
            child: const SizedBox(),
          ),
        );
        final expected = KeycapThemeData.preset(
          palette.id,
          brightness,
          density: density,
        );
        expect(theme.density, density);
        expect(theme.colors.accent.top, expected.colors.accent.top);
        expect(theme.controlHeight, expected.controlHeight);
      });
    }
  }

  testWidgets('a given theme keeps its own density', (tester) async {
    final given = KeycapThemeData.preset(
      'sage',
      Brightness.light,
      density: RawDensity.standard,
    );
    final theme = await themeUnder(
      tester,
      KeycapHost(
        theme: given,
        brightness: Brightness.light,
        density: RawDensity.compact,
        child: const SizedBox(),
      ),
    );
    expect(theme.density, RawDensity.standard);
  });
}
