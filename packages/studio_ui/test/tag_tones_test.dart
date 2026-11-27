// A tag's tones stand apart in every palette, by day and by night: a plain
// tag is unlit, its words neutral on the display's glass; a lit one glows,
// its words in the palette's lit legend on the readout's backlit glass, its
// lamp on; a failure's words are red. Each reads at 4.5:1 on its glass.
// Graphite has no hue: its lit tag is told by its lamp.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

Future<({Color ink, Color glass, bool lamp})> _tag(
  WidgetTester tester,
  StudioThemeData theme,
  StudioTagTone tone,
) async {
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: StudioTheme(
        data: theme,
        child: Center(child: StudioTag('Editing', tone: tone)),
      ),
    ),
  );
  final text = tester.widget<Text>(find.text('Editing'));
  final surface = tester.widget<StudioSurface>(
    find
        .descendant(
          of: find.byType(StudioTag),
          matching: find.byType(StudioSurface),
        )
        .first,
  );
  return (
    ink: text.style!.color!,
    glass: surface.face.fill,
    lamp: find
        .descendant(
          of: find.byType(StudioTag),
          matching: find.byType(StudioLamp),
        )
        .evaluate()
        .isNotEmpty,
  );
}

void main() {
  for (final palette in StudioThemeData.palettes) {
    for (final brightness in Brightness.values) {
      final at =
          '${palette.label} by ${brightness == Brightness.dark ? 'night' : 'day'}';
      testWidgets('plain, lit and failing tags stand apart: $at', (
        tester,
      ) async {
        final theme = StudioThemeData.preset(palette.id, brightness);
        final c = theme.colors;
        final plain = await _tag(tester, theme, StudioTagTone.plain);
        final lit = await _tag(tester, theme, StudioTagTone.lit);
        final danger = await _tag(tester, theme, StudioTagTone.danger);
        expect(plain.lamp, isFalse);
        expect(lit.lamp, isTrue);
        expect(plain.glass, c.display, reason: 'a plain tag is unlit glass');
        expect(lit.glass, c.readout, reason: 'a lit tag is backlit glass');
        for (final (name, t) in [
          ('plain', plain),
          ('lit', lit),
          ('danger', danger),
        ]) {
          expect(
            RawPalette.contrastRatio(t.ink, t.glass),
            greaterThanOrEqualTo(4.5),
            reason: '$name words on their glass',
          );
        }
        final hueFree = RawHct.fromColor(c.indicator).chroma < 16;
        if (!hueFree) {
          expect(
            DesignToneCheck.distance(plain.ink, lit.ink),
            greaterThanOrEqualTo(24),
            reason: 'plain ${plain.ink} and lit ${lit.ink} words',
          );
        }
        const DesignToneCheck(look: 'Studio').check([
          DesignToneSet(
            palette: palette.label,
            brightness: brightness,
            tones: {'lit': lit.ink, 'danger': danger.ink},
          ),
        ]).verify();
      });
    }
  }
}
