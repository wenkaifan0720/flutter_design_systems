// The six print runs as RawNamedPalettes: their ids are the presets', their swatches the theme's own inks, and the host
// builds and blends to the palette it is given, by day and by night.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Color _ground(WidgetTester tester) => tester
    .widget<ColoredBox>(
      find
          .descendant(
            of: find.byType(ComicHost),
            matching: find.byType(ColoredBox),
          )
          .first,
    )
    .color;

Widget _app(RawNamedPalette? palette, Brightness brightness) => MaterialApp(
  builder: (context, child) =>
      ComicHost(palette: palette, brightness: brightness, child: child!),
  home: const SizedBox.expand(),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  test('the six palettes are the presets, in order, each named once', () {
    expect([
      for (final p in ComicThemeData.palettes) p.id,
    ], ComicThemeData.presets);
    final labels = {for (final p in ComicThemeData.palettes) p.label};
    expect(labels, hasLength(6));
  });

  for (final brightness in Brightness.values) {
    test(
      'a palette\'s swatches are its theme\'s act, captions, group and page (${brightness.name})',
      () {
        for (final palette in ComicThemeData.palettes) {
          final c = ComicThemeData.preset(palette.id, brightness).colors;
          expect(palette.swatchesFor(brightness), [
            c.primary,
            c.caption,
            c.shade,
            c.background,
          ], reason: palette.id);
          expect(
            identical(
              ComicThemeData(palette: palette, brightness: brightness),
              ComicThemeData.preset(palette.id, brightness),
            ),
            isTrue,
            reason: '${palette.id}: the preset itself, not a copy',
          );
        }
      },
    );
  }

  test('no palette is offset unless it says so; the default is offset', () {
    expect(
      identical(
        ComicThemeData(),
        ComicThemeData.preset('offset', Brightness.light),
      ),
      isTrue,
    );
    expect(
      ComicThemeData(density: ComicDensity.compact).density,
      ComicDensity.compact,
    );
  });

  testWidgets(
    'the host builds its palette and blends to a new one, by day and by night',
    (tester) async {
      final newsstand = ComicThemeData.palettes[2],
          cosmic = ComicThemeData.palettes[5];
      await tester.pumpWidget(_app(newsstand, Brightness.light));
      await tester.pumpAndSettle();
      final from = ComicThemeData.preset(
        'newsstand',
        Brightness.light,
      ).colors.background;
      expect(_ground(tester), from);
      await tester.pumpWidget(_app(cosmic, Brightness.light));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      final to = ComicThemeData.preset(
        'cosmic',
        Brightness.light,
      ).colors.background;
      final mid = _ground(tester);
      expect(mid, isNot(from), reason: 'moving');
      expect(mid, isNot(to), reason: 'not cut');
      await tester.pumpAndSettle();
      expect(_ground(tester), to);
      // Day to night moves too.
      await tester.pumpWidget(_app(cosmic, Brightness.dark));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));
      expect(
        _ground(tester),
        isNot(
          ComicThemeData.preset('cosmic', Brightness.dark).colors.background,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        _ground(tester),
        ComicThemeData.preset('cosmic', Brightness.dark).colors.background,
      );
    },
  );

  testWidgets('without a palette the host builds offset', (tester) async {
    await tester.pumpWidget(_app(null, Brightness.light));
    await tester.pumpAndSettle();
    expect(
      _ground(tester),
      ComicThemeData.preset('offset', Brightness.light).colors.background,
    );
  });
}
