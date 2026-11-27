// Gloss's six gels (GlossThemeData.palettes, ui_core's RawNamedPalette):
// jade first, the look's own, then five more on the same porcelain; each
// palette's swatches are its theme's gel and page by day and by night, and
// the host takes one and eases a change. On each, by day and by night, words
// read 4.5:1 on the page, a bar, a well (its floor and the rim's shadow at
// its top, as painted) and a porcelain tile; the ink reads 4.5:1 and the
// supporting words and the jade's 3:1 at least on a pearl part's crown and
// foot; white words read 5.3:1 on the gel's middle, as on jade's own by
// night (5.6:1 by day), so they hold where the glaze lightens toward the
// gel's crown and foot; the focus stands 3:1 everywhere.
// GlossThemeData.from holds the same for any gel and finish, and keeps the
// porcelain at the look's own tones (a black finish by day was a grey page).
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

String _hex(Color c) => '#${c.toARGB32().toRadixString(16)}';

void _reads(GlossColors c, String name) {
  final well = GlossFace.well(c), tile = GlossFace.porcelain(c);
  final level = [
    c.page,
    c.barTop,
    c.barMiddle,
    c.barBottom,
    c.well,
    well.top,
    tile.top,
    tile.middle,
  ];
  final pearl = [c.pearlTop, c.pearlBottom];
  void at(String what, Color ink, List<Color> grounds, double ratio) {
    for (final ground in grounds) {
      expect(
        RawPalette.contrastRatio(ink, ground),
        greaterThanOrEqualTo(ratio),
        reason: '$name: $what ${_hex(ink)} on ${_hex(ground)}',
      );
    }
  }

  at('ink', c.ink, [...level, ...pearl], 4.5);
  at('supporting words', c.inkSecondary, level, 4.5);
  at('supporting words on pearl', c.inkSecondary, pearl, 3);
  at('jade words', c.jadeInk, level, 4.5);
  at('jade on pearl', c.jadeInk, pearl, 3);
  at('danger words', c.danger, level, 4.5);
  at('focus', c.focus, [...level, ...pearl], 3);
  at('words on the gel', c.onJade, [c.jade], 5.3);
}

void main() {
  final ids = [for (final p in GlossThemeData.palettes) p.id];

  test('six gels, jade first, each its theme in swatches', () {
    expect(ids, ['jade', 'sapphire', 'amethyst', 'amber', 'rose', 'teal']);
    for (final p in GlossThemeData.palettes) {
      expect(p.label, p.id[0].toUpperCase() + p.id.substring(1));
      for (final b in Brightness.values) {
        final c = GlossThemeData.preset(p.id, b).colors;
        expect(p.swatchesFor(b), [c.jade, c.page], reason: '${p.id} ${b.name}');
      }
    }
    // A choice stored by another version is jade's.
    expect(
      GlossThemeData.preset('cobalt', Brightness.light).colors,
      const GlossColors.light(),
    );
  });

  for (final b in Brightness.values) {
    testWidgets('${b.name}: the host takes a palette and eases a change', (
      t,
    ) async {
      late BuildContext seen;
      Widget app(RawNamedPalette palette) => Directionality(
        textDirection: TextDirection.ltr,
        child: GlossHost(
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
      final jade = GlossThemeData.palettes.first;
      final teal = GlossThemeData.palettes.last;
      await t.pumpWidget(app(jade));
      expect(GlossTheme.of(seen).colors.jade, jade.swatchesFor(b).first);
      await t.pumpWidget(app(teal));
      await t.pump(const Duration(milliseconds: 60));
      final mid = GlossTheme.of(seen).colors.jade;
      expect(mid, isNot(jade.swatchesFor(b).first));
      expect(mid, isNot(teal.swatchesFor(b).first));
      await t.pumpAndSettle();
      expect(GlossTheme.of(seen).colors.jade, teal.swatchesFor(b).first);
    });
  }

  for (final b in Brightness.values) {
    final jade = b == Brightness.dark
        ? const GlossColors.dark()
        : const GlossColors.light();

    test('${b.name}: jade is the look by day and by night', () {
      expect(GlossThemeData.preset('jade', b).colors, jade);
    });

    test('${b.name}: each gel its own', () {
      final gels = {
        for (final name in ids) GlossThemeData.preset(name, b).colors.jade,
      };
      expect(gels, hasLength(ids.length));
    });

    for (final name in ids) {
      test('${b.name}, $name: every word reads where it stands', () {
        final c = GlossThemeData.preset(name, b).colors;
        expect(c.brightness, b);
        _reads(c, '$name ${b.name}');
      });
    }

    for (final gel in const [
      Color(0xFF1F3A68),
      Color(0xFF2E7D32),
      Color(0xFFC9A227),
      Color(0xFF6A1B9A),
      Color(0xFFF4B6C2),
    ]) {
      for (final finish in const [
        null,
        Color(0xFFFFFFFF),
        Color(0xFF000000),
        Color(0xFFFFF3D6),
      ]) {
        test('${b.name}: from(gel: ${_hex(gel)}, finish: '
            '${finish == null ? 'none' : _hex(finish)})', () {
          final c = GlossThemeData.from(
            gel: gel,
            finish: finish,
            brightness: b,
          ).colors;
          _reads(c, 'from ${_hex(gel)}');
          // The porcelain keeps the look's own tones, in the finish's hue.
          for (final (part, own, made) in [
            ('page', jade.page, c.page),
            ('bar', jade.barMiddle, c.barMiddle),
            ('pearl', jade.pearlBottom, c.pearlBottom),
          ]) {
            expect(
              RawHct.fromColor(made).tone,
              closeTo(RawHct.fromColor(own).tone, 1),
              reason: part,
            );
          }
        });
      }
    }
  }
}
