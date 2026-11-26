// Comic's six print runs and its own colours from an app's: every run reads in both appearances; from() needs only
// the act, derives the rest in the look's own inks, keeps its night in the group's hue (the look's own run prints an
// ink-blue night, not a black one), keeps a dark background's day page on light stock, and reads its coloured words
// on every ground they are painted on, the paper faces too.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

double _ratio(Color a, Color b) => RawPalette.contrastRatio(a, b);

void main() {
  test('six print runs, the look\'s own first, each its own act', () {
    expect(ComicThemeData.presets, hasLength(6));
    expect(ComicThemeData.presets.first, 'offset');
    final acts = {
      for (final id in ComicThemeData.presets)
        ComicThemeData.preset(id, Brightness.light).colors.primary,
    };
    expect(acts, hasLength(6), reason: 'each run has an act of its own');
  });

  for (final id in ComicThemeData.presets) {
    for (final b in Brightness.values) {
      test(
        '$id (${b.name}): words read on every ground, inks on their fills',
        () {
          final c = ComicThemeData.preset(id, b).colors;
          final grounds = [c.background, c.card, c.inset];
          for (final (name, ink, least) in [
            ('text', c.text, 7.0),
            ('textSecondary', c.textSecondary, 4.5),
            ('primaryText', c.primaryText, 4.5),
            ('shadeText', c.shadeText, 4.5),
          ]) {
            for (final g in grounds) {
              expect(
                _ratio(ink, g),
                greaterThanOrEqualTo(least),
                reason: '$name on $g',
              );
            }
          }
          expect(_ratio(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
          expect(_ratio(c.onShade, c.shade), greaterThanOrEqualTo(4.5));
          expect(_ratio(c.onCaption, c.caption), greaterThanOrEqualTo(4.5));
          expect(_ratio(c.onPaper, c.paper), greaterThanOrEqualTo(7));
          expect(_ratio(c.hint, c.paper), greaterThanOrEqualTo(4.5));
        },
      );
    }
  }

  test(
    'from() takes the act alone: process yellow captions, process blue group',
    () {
      const magenta = Color(0xFFC2185B);
      final t = ComicThemeData.from(primary: magenta);
      final own = ComicThemeData.preset('offset', Brightness.light).colors;
      expect(t.colors.caption, own.caption);
      expect(t.colors.shade, own.shade);
      expect(t.colors.primary, magenta);
    },
  );

  test(
    'from() with a blue act takes another run\'s group ink, not a second blue',
    () {
      const navy = Color(0xFF1F3A68);
      final c = ComicThemeData.from(primary: navy).colors;
      final blue = ComicThemeData.preset(
        'offset',
        Brightness.light,
      ).colors.shade;
      expect(c.shade, isNot(blue));
      expect(
        (RawHct.fromColor(c.shade).hue - RawHct.fromColor(navy).hue).abs(),
        greaterThan(40),
      );
    },
  );

  test(
    "from()'s night is the night issue in the group's hue, not plain black",
    () {
      for (final group in const [
        Color(0xFF1D63D1),
        Color(0xFF007C8A),
        Color(0xFF5F47C4),
      ]) {
        final c = ComicThemeData.from(
          primary: const Color(0xFFFF3E92),
          shade: group,
          brightness: Brightness.dark,
        ).colors;
        final card = RawHct.fromColor(c.card),
            page = RawHct.fromColor(c.background);
        final hue = RawHct.fromColor(group).hue;
        expect(
          card.chroma,
          greaterThan(15),
          reason: 'a panel in colour for $group',
        );
        final apart = (card.hue - hue).abs() % 360;
        expect(
          apart < 20 || apart > 340,
          isTrue,
          reason: 'the panel in the group\'s hue for $group',
        );
        expect(page.tone, lessThan(8));
        expect(
          card.tone,
          greaterThan(page.tone + 5),
          reason: 'a panel stands off its gutter',
        );
      }
    },
  );

  test('from() keeps a dark background on light stock by day', () {
    final c = ComicThemeData.from(
      primary: const Color(0xFFFF3E92),
      background: const Color(0xFF101010),
    ).colors;
    expect(RawHct.fromColor(c.background).tone, greaterThan(90));
    expect(_ratio(c.text, c.background), greaterThanOrEqualTo(7));
  });

  for (final b in Brightness.values) {
    test("from()'s coloured words read on the paper faces too (${b.name})", () {
      for (final (act, group) in const [
        (Color(0xFF1F3A68), Color(0xFF2B79C7)),
        (Color(0xFF2E7D32), Color(0xFF6A1B9A)),
        (Color(0xFFF2C94C), Color(0xFF1F3A68)),
        (Color(0xFFF4B6C2), Color(0xFFB3E5FC)),
      ]) {
        final c = ComicThemeData.from(
          primary: act,
          shade: group,
          brightness: b,
        ).colors;
        final grounds = [
          c.background,
          c.card,
          c.inset,
          if (b == Brightness.light) c.paper,
        ];
        for (final g in grounds) {
          expect(
            _ratio(c.primaryText, g),
            greaterThanOrEqualTo(4.5),
            reason: 'act words for $act on $g',
          );
          expect(
            _ratio(c.shadeText, g),
            greaterThanOrEqualTo(4.5),
            reason: 'group words for $group on $g',
          );
        }
      }
    });
  }

  test(
    "from()'s coloured words read on a dark ground's paper faces by day",
    () {
      // A dark neutral by day keeps its hue on light stock, so its paper faces
      // are the darkest grounds the coloured words stand on.
      for (final ground in const [
        Color(0xFF2A2A2A),
        Color(0xFF1B2A3A),
        Color(0xFF8A7A5A),
      ]) {
        for (final act in const [
          Color(0xFFF2C94C),
          Color(0xFF7FB3FF),
          Color(0xFFD32F2F),
        ]) {
          final c = ComicThemeData.from(
            primary: act,
            background: ground,
          ).colors;
          for (final g in [c.background, c.card, c.inset, c.paper]) {
            expect(
              _ratio(c.primaryText, g),
              greaterThanOrEqualTo(4.5),
              reason: 'act words for $act over $ground on $g',
            );
            expect(
              _ratio(c.shadeText, g),
              greaterThanOrEqualTo(4.5),
              reason: 'group words over $ground on $g',
            );
          }
        }
      }
    },
  );
}
