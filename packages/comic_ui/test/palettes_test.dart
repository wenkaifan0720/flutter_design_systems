// Comic's six print runs and its own colours from an app's: every run reads in both appearances, and by day each reads
// as its own run on a plain screen (its gutter, its panel and its lamp) and in its act; from() needs only
// the act, derives the rest in the look's own inks, keeps its night in the group's hue (the look's own run prints an
// ink-blue night, not a black one), keeps a dark background's day page on light stock, and reads its coloured words
// on every ground they are painted on, the paper faces too.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

double _ratio(Color a, Color b) => RawPalette.contrastRatio(a, b);

/// CIE L*a*b* (D65) of [c].
List<double> _lab(Color c) {
  double lin(double v) =>
      v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
  final r = lin(c.r), g = lin(c.g), b = lin(c.b);
  final x = (.4124 * r + .3576 * g + .1805 * b) / .95047;
  final y = .2126 * r + .7152 * g + .0722 * b;
  final z = (.0193 * r + .1192 * g + .9505 * b) / 1.08883;
  double f(double t) =>
      t > .008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
  return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
}

/// How far apart two colours read (CIE76).
double _apart(Color a, Color b) {
  final p = _lab(a), q = _lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

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

  test('by day each run reads as its own on a plain screen: its gutter, its panel and its lamp', () {
    // A settings or checkout screen shows little but the gutter, the panels, the lamp (captions, what is chosen, a
    // switch that is on) and the ink: those three together tell one run from another.
    final runs = ComicThemeData.presets;
    for (var i = 0; i < runs.length; i++) {
      for (var j = i + 1; j < runs.length; j++) {
        final a = ComicThemeData.preset(runs[i], Brightness.light).colors;
        final b = ComicThemeData.preset(runs[j], Brightness.light).colors;
        final apart =
            _apart(a.background, b.background) +
            _apart(a.card, b.card) +
            _apart(a.caption, b.caption);
        expect(
          apart,
          greaterThanOrEqualTo(35),
          reason: '${runs[i]} and ${runs[j]} by day',
        );
      }
    }
  });

  test('by day no two runs share a gutter', () {
    // The gutter is most of a plain screen; the panels are near white in every run, so the gutters alone tell runs apart.
    final runs = ComicThemeData.presets;
    for (var i = 0; i < runs.length; i++) {
      for (var j = i + 1; j < runs.length; j++) {
        expect(
          _apart(
            ComicThemeData.preset(runs[i], Brightness.light).colors.background,
            ComicThemeData.preset(runs[j], Brightness.light).colors.background,
          ),
          greaterThanOrEqualTo(8),
          reason: '${runs[i]} and ${runs[j]} by day',
        );
      }
    }
  });

  test('by day no two runs share a caption', () {
    // The caption fills the narrator's boxes and also the switches that are on, the chosen options and the notices:
    // on a settings or checkout screen it is the run's loudest colour.
    final runs = ComicThemeData.presets;
    for (var i = 0; i < runs.length; i++) {
      for (var j = i + 1; j < runs.length; j++) {
        expect(
          _apart(
            ComicThemeData.preset(runs[i], Brightness.light).colors.caption,
            ComicThemeData.preset(runs[j], Brightness.light).colors.caption,
          ),
          greaterThanOrEqualTo(15),
          reason: '${runs[i]} and ${runs[j]} by day',
        );
      }
    }
  });

  test('by day the six acts stand apart, by hue or by tone', () {
    final runs = ComicThemeData.presets;
    for (var i = 0; i < runs.length; i++) {
      for (var j = i + 1; j < runs.length; j++) {
        final p = RawHct.fromColor(
          ComicThemeData.preset(runs[i], Brightness.light).colors.primary,
        );
        final q = RawHct.fromColor(
          ComicThemeData.preset(runs[j], Brightness.light).colors.primary,
        );
        final hue = (p.hue - q.hue).abs() % 360;
        expect(
          math.min(hue, 360 - hue) >= 20 || (p.tone - q.tone).abs() >= 12,
          isTrue,
          reason:
              '${runs[i]} and ${runs[j]}: hues ${p.hue.round()} and ${q.hue.round()}, tones ${p.tone.round()} and ${q.tone.round()}',
        );
      }
    }
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
