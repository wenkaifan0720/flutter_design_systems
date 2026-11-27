// Frosted's six palettes through ui_core's RawNamedPalette: each one's swatches are its theme's act and canvas, by day and
// by night; the host and the theme take one; a change of palette eases from the old colours to the new.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';

void main() {
  test('six palettes, the first the default, each its theme in swatches', () {
    final palettes = FrostedThemeData.palettes;
    expect(palettes, hasLength(6));
    expect(palettes.map((p) => p.id).toSet(), hasLength(6));
    expect(palettes.first.id, 'opal');
    for (final p in palettes) {
      expect(p.label, isNotEmpty);
      for (final b in Brightness.values) {
        final t = FrostedThemeData.preset(p.id, b);
        expect(t.id, p.id);
        expect(p.swatchesFor(b), [
          t.colorScheme.accent,
          t.colorScheme.background,
        ], reason: '${p.id} ${b.name}');
      }
    }
  });

  test('the theme takes a palette', () {
    final quartz = FrostedThemeData.palettes[1];
    expect(FrostedThemeData(palette: quartz).id, 'quartz');
    expect(
      FrostedThemeData(palette: quartz, brightness: Brightness.dark).isDark,
      isTrue,
    );
    expect(FrostedThemeData().id, 'opal');
  });

  for (final b in Brightness.values) {
    testWidgets('${b.name}: the host takes a palette and eases a change', (
      t,
    ) async {
      late BuildContext seen;
      Widget app(RawNamedPalette palette) => Directionality(
        textDirection: TextDirection.ltr,
        child: FrostedHost(
          palette: palette,
          brightness: b,
          child: Builder(
            builder: (context) {
              seen = context;
              return const SizedBox();
            },
          ),
        ),
      );
      final opal = FrostedThemeData.palettes.first;
      final jade = FrostedThemeData.palettes[4];
      await t.pumpWidget(app(opal));
      expect(seen.frostedTheme.colorScheme.accent, opal.swatchesFor(b).first);
      await t.pumpWidget(app(jade));
      await t.pump(const Duration(milliseconds: 60));
      final mid = seen.frostedTheme.colorScheme.accent;
      expect(mid, isNot(opal.swatchesFor(b).first));
      expect(mid, isNot(jade.swatchesFor(b).first));
      await t.pumpAndSettle();
      expect(seen.frostedTheme.id, 'jade');
      expect(seen.frostedTheme.colorScheme.accent, jade.swatchesFor(b).first);
    });
  }
}
