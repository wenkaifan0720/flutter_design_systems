// Fluent2Host(customize:) changes both appearances' themes as built from
// the palette, so a palette picker keeps an app's density; a positive
// density step is roomier than Fluent's own, comfortable tighter.
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('customize changes the palette by ${brightness.name}', (
      tester,
    ) async {
      final palette = Fluent2ThemeData.palettes[2];
      late Fluent2ThemeData seen;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) => Fluent2Host(
            palette: palette,
            brightness: brightness,
            customize: (theme) =>
                theme.copyWith(density: Fluent2Density.compact),
            child: app!,
          ),
          home: Builder(
            builder: (context) {
              seen = context.fluent2Theme;
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(seen.id, palette.id);
      expect(seen.brightness, brightness);
      expect(seen.density, Fluent2Density.compact);
    });
  }

  testWidgets('customize keeps its change across a change of palette', (
    tester,
  ) async {
    late Fluent2ThemeData seen;
    Widget app(RawNamedPalette palette) => MaterialApp(
      builder: (context, app) => Fluent2Host(
        palette: palette,
        brightness: Brightness.light,
        customize: (theme) => theme.copyWith(density: Fluent2Density.compact),
        child: app!,
      ),
      home: Builder(
        builder: (context) {
          seen = context.fluent2Theme;
          return const SizedBox();
        },
      ),
    );
    await tester.pumpWidget(app(Fluent2ThemeData.palettes[0]));
    await tester.pumpAndSettle();
    await tester.pumpWidget(app(Fluent2ThemeData.palettes[3]));
    await tester.pumpAndSettle();
    expect(seen.id, Fluent2ThemeData.palettes[3].id);
    expect(seen.density, Fluent2Density.compact);
  });

  testWidgets('a positive step is roomier, comfortable tighter', (
    tester,
  ) async {
    // Under a pointer the floor is 24, so the button stands at its face.
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    try {
      Future<double> height(Fluent2Density density) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, app) => Fluent2Host(
              brightness: Brightness.light,
              customize: (theme) => theme.copyWith(density: density),
              child: app!,
            ),
            home: Center(child: Fluent2Button('Save', onPressed: () {})),
          ),
        );
        await tester.pumpAndSettle();
        return tester.getSize(find.byType(Fluent2Button)).height;
      }

      final standard = await height(Fluent2Density.standard);
      expect(await height(Fluent2Density.comfortable), standard - 4);
      expect(
        await height(const Fluent2Density(horizontal: 1, vertical: 1)),
        standard + 4,
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
