// The host's density knob reaches both appearances, and a list's rows,
// a setting's and a menu's options move with it, never under the touch
// floor; a desktop that sets none stands its rows compact, as Material's
// list tile does; the everyday glyphs an app reaches for are in the set (a
// book, a gear, a heart, a star and a pencil).
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:material_ui/material_ui.dart'
    show MaterialApp, Material, MaterialType;

Future<FrostedThemeData> _themeUnder(
  WidgetTester tester, {
  FrostedDensity? density,
  Brightness brightness = Brightness.light,
  FrostedThemeData? theme,
  Widget? child,
}) async {
  late FrostedThemeData seen;
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => FrostedHost(
        density: density,
        brightness: brightness,
        theme: theme,
        child: app!,
      ),
      home: Material(
        type: MaterialType.transparency,
        child: Builder(
          builder: (context) {
            seen = context.frostedTheme;
            return Align(
              alignment: Alignment.topCenter,
              child: child ?? const SizedBox(),
            );
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
    testWidgets('the host density reaches the ${brightness.name} theme', (
      tester,
    ) async {
      final t = await _themeUnder(
        tester,
        density: FrostedDensity.compact,
        brightness: brightness,
      );
      expect(t.density, FrostedDensity.compact);
    });
  }

  testWidgets("the host density lies over an app's own theme", (tester) async {
    final t = await _themeUnder(
      tester,
      density: FrostedDensity.comfortable,
      theme: FrostedThemeData.opal(),
    );
    expect(t.density, FrostedDensity.comfortable);
    final unset = await _themeUnder(tester, theme: FrostedThemeData.opal());
    expect(unset.density, FrostedThemeData.opal().density);
  });

  testWidgets('a list row moves 4 a step, never under the floor', (
    tester,
  ) async {
    Future<double> rowAt(FrostedDensity density) async {
      await _themeUnder(
        tester,
        density: density,
        child: const SizedBox(
          width: 360,
          child: FrostedListTile(title: 'Middlemarch'),
        ),
      );
      return tester.getSize(find.byType(FrostedListTile)).height;
    }

    final standard = await rowAt(FrostedDensity.standard);
    expect(await rowAt(FrostedDensity.comfortable), standard - 4);
    expect(await rowAt(FrostedDensity.compact), standard - 8);
    final tightest = await rowAt(
      const FrostedDensity(horizontal: -4, vertical: -4),
    );
    expect(tightest, greaterThanOrEqualTo(40));
  });

  testWidgets('a desktop that sets no density stands its rows compact', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final t = await _themeUnder(
      tester,
      child: const SizedBox(
        width: 360,
        child: FrostedListTile(title: 'Middlemarch'),
      ),
    );
    final (density, height) = (
      t.density,
      tester.getSize(find.byType(FrostedListTile)).height,
    );
    debugDefaultTargetPlatformOverride = null;
    expect(density, FrostedDensity.compact);
    expect(height, 44);
  });

  test('the everyday glyphs are in the set, each its own', () {
    final everyday = {
      'book': FrostedGlyphs.book,
      'settings': FrostedGlyphs.settings,
      'heart': FrostedGlyphs.heart,
      'star': FrostedGlyphs.star,
      'edit': FrostedGlyphs.edit,
    };
    expect(everyday.values.map((g) => g.codePoint).toSet(), hasLength(5));
    for (final glyph in everyday.values) {
      expect(glyph.fontFamily, FrostedGlyphs.house.fontFamily);
    }
  });
}
