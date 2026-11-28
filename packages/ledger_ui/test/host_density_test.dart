// LedgerHost takes a density next to its palette and brightness, and it
// stands over the theme by day and by night, a palette's or the app's own: an
// app sets how tightly its controls are set in one place, without building
// both themes itself. Left null, each theme keeps its own.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

Future<LedgerThemeData> _seen(WidgetTester tester, LedgerHost host) async {
  late LedgerThemeData seen;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: LedgerHost(
        theme: host.theme,
        darkTheme: host.darkTheme,
        palette: host.palette,
        brightness: host.brightness,
        density: host.density,
        child: Builder(
          builder: (context) {
            seen = LedgerTheme.of(context);
            return const SizedBox();
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return seen;
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets("density stands over the palette's ${brightness.name} theme", (
      tester,
    ) async {
      final palette = LedgerThemeData.palettes[1];
      final seen = await _seen(
        tester,
        LedgerHost(
          brightness: brightness,
          palette: palette,
          density: LedgerDensity.compact,
          child: const SizedBox(),
        ),
      );
      expect(seen.density, LedgerDensity.compact);
      expect(seen.brightness, brightness);
      expect(
        seen.accent,
        LedgerThemeData.fromPalette(palette, brightness).accent,
      );
    });

    testWidgets("density stands over the app's own ${brightness.name} theme", (
      tester,
    ) async {
      final own = brightness == Brightness.dark
          ? LedgerThemeData.dark(density: LedgerDensity.standard)
          : LedgerThemeData.light(density: LedgerDensity.standard);
      final seen = await _seen(
        tester,
        LedgerHost(
          brightness: brightness,
          theme: brightness == Brightness.light ? own : null,
          darkTheme: brightness == Brightness.dark ? own : null,
          density: LedgerDensity.comfortable,
          child: const SizedBox(),
        ),
      );
      expect(seen.density, LedgerDensity.comfortable);
      expect(seen.brightness, brightness);
    });
  }

  testWidgets("no density keeps the theme's own", (tester) async {
    final seen = await _seen(
      tester,
      LedgerHost(
        brightness: Brightness.light,
        theme: LedgerThemeData.light(density: LedgerDensity.comfortable),
        child: const SizedBox(),
      ),
    );
    expect(seen.density, LedgerDensity.comfortable);
  });
}
