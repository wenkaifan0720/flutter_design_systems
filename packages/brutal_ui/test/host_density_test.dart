// BrutalHost takes a density that holds by day and by night, over the
// palette's presets and over themes an app gives, so an app sets it once
// rather than rebuilding both themes for it. Left out, each theme keeps its
// own.
import 'package:brutal_ui/brutal_ui.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<BrutalThemeData> _hosted(
  WidgetTester tester,
  BrutalHost Function(Widget child) host,
) async {
  late BrutalThemeData seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => host(child!),
      home: Builder(
        builder: (context) {
          seen = BrutalTheme.of(context);
          return const SizedBox();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return seen;
}

void main() {
  for (final b in Brightness.values) {
    testWidgets('a palette at a density (${b.name})', (tester) async {
      final theme = await _hosted(
        tester,
        (child) => BrutalHost(
          palette: BrutalThemeData.palettes[2],
          brightness: b,
          density: BrutalDensity.compact,
          child: child,
        ),
      );
      expect(theme.density, BrutalDensity.compact);
      expect(theme.controlHeight, 40);
      expect(
        theme.colors,
        BrutalThemeData.preset(BrutalThemeData.presets[2], b).colors,
      );
    });

    testWidgets("an app's own themes at a density (${b.name})", (tester) async {
      final theme = await _hosted(
        tester,
        (child) => BrutalHost(
          theme: BrutalThemeData.from(signal: const Color(0xFF2F5BFF)),
          darkTheme: BrutalThemeData.from(
            signal: const Color(0xFF2F5BFF),
            brightness: Brightness.dark,
          ),
          brightness: b,
          density: BrutalDensity.comfortable,
          child: child,
        ),
      );
      expect(theme.density, BrutalDensity.comfortable);
      expect(theme.controlHeight, 44);
    });
  }

  testWidgets("left out, each theme keeps its own", (tester) async {
    final theme = await _hosted(
      tester,
      (child) => BrutalHost(
        theme: BrutalThemeData.light(density: BrutalDensity.compact),
        brightness: Brightness.light,
        child: child,
      ),
    );
    expect(theme.density, BrutalDensity.compact);
    final preset = await _hosted(
      tester,
      (child) => BrutalHost(brightness: Brightness.light, child: child),
    );
    expect(preset.density, BrutalDensity.adaptivePlatformDensity);
  });
}
