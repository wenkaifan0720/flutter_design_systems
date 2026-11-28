// Fluent2Host(density:) sets both appearances' density at every window
// width, a palette's change keeps it, and customize sees the theme at it.
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:material_ui/material_ui.dart';

Future<Fluent2ThemeData> _theme(
  WidgetTester tester, {
  required double width,
  Brightness brightness = Brightness.light,
  RawNamedPalette? palette,
  Fluent2Density? density,
  Fluent2ThemeData Function(Fluent2ThemeData)? customize,
}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late Fluent2ThemeData theme;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => Fluent2Host(
        palette: palette,
        brightness: brightness,
        density: density,
        customize: customize,
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          theme = context.fluent2Theme;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  testWidgets('density: sets both appearances at every width', (tester) async {
    for (final width in [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        final theme = await _theme(
          tester,
          width: width,
          brightness: brightness,
          density: Fluent2Density.compact,
        );
        expect(theme.density, Fluent2Density.compact, reason: '$width');
        expect(theme.isDark, brightness == Brightness.dark);
      }
    }
  });

  testWidgets('a palette keeps it; null keeps the palette\'s standard', (
    tester,
  ) async {
    final other = await _theme(
      tester,
      width: 1440,
      palette: Fluent2ThemeData.palettes[2],
      density: Fluent2Density.comfortable,
    );
    expect(other.density, Fluent2Density.comfortable);
    final none = await _theme(tester, width: 1440);
    expect(none.density, Fluent2Density.standard);
  });

  testWidgets('customize sees the theme at the density', (tester) async {
    Fluent2Density? seen;
    await _theme(
      tester,
      width: 1440,
      density: Fluent2Density.compact,
      customize: (theme) {
        seen = theme.density;
        return theme;
      },
    );
    expect(seen, Fluent2Density.compact);
  });
}
