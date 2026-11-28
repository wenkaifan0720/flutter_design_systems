// StudioHost(density:) sets both brightnesses' density at every window
// width, with any palette; null keeps the palette's standard.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<StudioThemeData> _theme(
  WidgetTester tester, {
  required double width,
  Brightness brightness = Brightness.light,
  RawNamedPalette? palette,
  StudioDensity? density,
}) async {
  tester.view
    ..physicalSize = Size(width, 900)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  late StudioThemeData theme;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => StudioHost(
        palette: palette,
        brightness: brightness,
        density: density,
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          theme = context.studioTheme;
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return theme;
}

void main() {
  testWidgets('density: sets both brightnesses at every width', (tester) async {
    for (final width in [390.0, 1440.0]) {
      for (final brightness in Brightness.values) {
        final theme = await _theme(
          tester,
          width: width,
          brightness: brightness,
          density: StudioDensity.compact,
        );
        expect(theme.density, StudioDensity.compact, reason: '$width');
      }
    }
  });

  testWidgets("a palette keeps it; null keeps the palette's standard", (
    tester,
  ) async {
    final other = await _theme(
      tester,
      width: 1440,
      palette: StudioThemeData.palettes[2],
      density: StudioDensity.comfortable,
    );
    expect(other.density, StudioDensity.comfortable);
    final none = await _theme(tester, width: 1440);
    expect(none.density, StudioDensity.standard);
  });
}
