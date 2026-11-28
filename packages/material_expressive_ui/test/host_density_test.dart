// The host takes the reader's density next to the palette and the
// brightness: ExpressiveHost(density:) is the density of whichever theme it
// wears, a palette's or the app's own, by day and by night; null leaves each
// theme's own. An adopter had to copyWith every theme to set it.
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ExpressiveThemeData> _worn(
  WidgetTester tester,
  ExpressiveHost host,
) async {
  late ExpressiveThemeData worn;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => ExpressiveHost(
        theme: host.theme,
        darkTheme: host.darkTheme,
        brightness: host.brightness,
        palette: host.palette,
        density: host.density,
        child: child!,
      ),
      home: Builder(
        builder: (context) {
          worn = context.expressiveTheme;
          return const SizedBox.shrink();
        },
      ),
    ),
  );
  await tester.pumpAndSettle();
  return worn;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('a palette by ${brightness.name} wears the host density', (
      tester,
    ) async {
      final worn = await _worn(
        tester,
        ExpressiveHost(
          brightness: brightness,
          palette: ExpressiveThemeData.palettes.last,
          density: ExpressiveDensity.compact,
          child: const SizedBox(),
        ),
      );
      expect(worn.density, ExpressiveDensity.compact);
      expect(worn.brightness, brightness);
    });

    testWidgets("the app's own theme by ${brightness.name} wears it too", (
      tester,
    ) async {
      final worn = await _worn(
        tester,
        ExpressiveHost(
          brightness: brightness,
          theme: ExpressiveThemeData.baseline(),
          darkTheme: ExpressiveThemeData.baseline(Brightness.dark),
          density: ExpressiveDensity.comfortable,
          child: const SizedBox(),
        ),
      );
      expect(worn.density, ExpressiveDensity.comfortable);
    });
  }

  testWidgets("no host density leaves the theme's own", (tester) async {
    final worn = await _worn(
      tester,
      ExpressiveHost(
        theme: ExpressiveThemeData.baseline().copyWith(
          density: ExpressiveDensity.comfortable,
        ),
        brightness: Brightness.light,
        child: const SizedBox(),
      ),
    );
    expect(worn.density, ExpressiveDensity.comfortable);
  });
}
