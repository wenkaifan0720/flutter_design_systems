// Clay's six palettes as ui_core's RawNamedPalette, for an app's picker:
// each preset's id with its name and its key and ground by day and by
// night, a theme from each, and a host that takes one.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('six palettes, one per preset, in its order', () {
    expect(ClayThemeData.palettes, hasLength(6));
    expect([
      for (final p in ClayThemeData.palettes) p.id,
    ], ClayThemeData.presets);
    expect(
      [for (final p in ClayThemeData.palettes) p.label],
      ['Clay', 'Mint', 'Sky', 'Butter', 'Peach', 'Lavender'],
    );
  });

  test("a palette's swatches are its key and its ground", () {
    for (final palette in ClayThemeData.palettes) {
      for (final brightness in Brightness.values) {
        final colors = ClayColors.preset(palette.id, brightness);
        expect(palette.swatchesFor(brightness), [
          colors.accent,
          colors.ground,
        ], reason: '${palette.id} ${brightness.name}');
      }
    }
  });

  test('fromPalette gives the preset, or an own palette by its key', () {
    for (final palette in ClayThemeData.palettes) {
      for (final brightness in Brightness.values) {
        expect(
          ClayThemeData.fromPalette(palette, brightness),
          ClayThemeData.preset(palette.id, brightness),
        );
      }
    }
    const own = RawNamedPalette(
      id: 'harbour',
      label: 'Harbour',
      swatches: [Color(0xFF2F6A9A)],
      darkSwatches: [Color(0xFF8FC1EA)],
    );
    expect(
      ClayThemeData.fromPalette(own, Brightness.dark),
      ClayThemeData.from(
        accent: const Color(0xFF8FC1EA),
        brightness: Brightness.dark,
      ),
    );
  });

  testWidgets('ClayHost takes a palette', (tester) async {
    late ClayColors colors;
    final mint = ClayThemeData.palettes.firstWhere((p) => p.id == 'mint');
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ClayHost(
          palette: mint,
          brightness: Brightness.dark,
          child: Builder(
            builder: (context) {
              colors = ClayTheme.of(context).colors;
              return const SizedBox.expand();
            },
          ),
        ),
      ),
    );
    expect(colors, ClayColors.preset('mint', Brightness.dark));
  });
}
