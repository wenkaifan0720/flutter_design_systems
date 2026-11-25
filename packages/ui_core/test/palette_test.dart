import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

const white = Color(0xFFFFFFFF);
const black = Color(0xFF000000);
const navy = Color(0xFF1F3A68);
const gold = Color(0xFFC9A227);
const cream = Color(0xFFFFF4EC);
const nightPage = Color(0xFF121212);
const nightPanel = Color(0xFF1E1E1E);
const darkInk = Color(0xFF111111);

double worst(Color c, List<Color> on) => on
    .map((g) => RawPalette.contrastRatio(c, g))
    .reduce((a, b) => a < b ? a : b);

// The hue distance, in degrees, between two colours' HCT hues.
double hueApart(Color a, Color b) {
  final d = (RawHct.fromColor(a).hue - RawHct.fromColor(b).hue).abs() % 360;
  return d > 180 ? 360 - d : d;
}

double toneOf(Color c) => RawHct.fromColor(c).tone;

// [c]'s hue and chroma at [tone], as readableTone walks them.
Color atTone(Color c, double tone) {
  final h = RawHct.fromColor(c);
  return RawHct.fromColor(c).withTone(tone).withChroma(h.chroma).toColor();
}

void main() {
  group('RawPalette.contrastRatio', () {
    test('runs from 1 to 21, either way round', () {
      expect(RawPalette.contrastRatio(black, white), closeTo(21, 1e-9));
      expect(RawPalette.contrastRatio(white, black), closeTo(21, 1e-9));
      expect(RawPalette.contrastRatio(navy, navy), closeTo(1, 1e-9));
      expect(
        RawPalette.contrastRatio(navy, cream),
        RawPalette.contrastRatio(cream, navy),
      );
    });

    test('reads a translucent foreground laid over the ground', () {
      const half = Color(0x80000000);
      final seen = Color.alphaBlend(half, white);
      expect(
        RawPalette.contrastRatio(half, white),
        RawPalette.contrastRatio(seen, white),
      );
      expect(RawPalette.contrastRatio(half, white), lessThan(5));
    });

    test('reads the ground as opaque', () {
      expect(
        RawPalette.contrastRatio(black, const Color(0x00FFFFFF)),
        closeTo(21, 1e-9),
      );
    });
  });

  group('RawPalette.readableTone', () {
    test('gives the colour itself when it reads on every ground', () {
      expect(RawPalette.readableTone(navy, on: const [white, cream]), navy);
      expect(RawPalette.readableTone(navy, on: const []), navy);
    });

    test('lightens a navy for a night page and panel, its hue kept', () {
      const on = [nightPage, nightPanel];
      final c = RawPalette.readableTone(navy, on: on);
      expect(worst(c, on), greaterThanOrEqualTo(4.5));
      expect(toneOf(c), greaterThan(toneOf(navy)));
      expect(hueApart(c, navy), lessThan(2));
      // The nearest tone that reads: half a tone back toward the navy does not.
      expect(worst(atTone(navy, toneOf(c) - 0.5), on), lessThan(4.5));
    });

    test('darkens a gold for words on a white page, its hue kept', () {
      const on = [white];
      final c = RawPalette.readableTone(gold, on: on);
      expect(worst(c, on), greaterThanOrEqualTo(4.5));
      expect(toneOf(c), lessThan(toneOf(gold)));
      expect(hueApart(c, gold), lessThan(2));
      expect(worst(atTone(gold, toneOf(c) + 0.5), on), lessThan(4.5));
    });

    test('reads on every ground given, the worst one included', () {
      const on = [white, Color(0xFFE8E8E8), Color(0xFFD0D0D0)];
      final c = RawPalette.readableTone(gold, on: on);
      expect(worst(c, on), greaterThanOrEqualTo(4.5));
      expect(
        RawPalette.contrastRatio(c, const Color(0xFFD0D0D0)),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('walks whichever way is nearer', () {
      const ground = Color(0xFF777777);
      final g = toneOf(ground);
      final above = atTone(navy, g + 8);
      final below = atTone(navy, g - 8);
      final up = RawPalette.readableTone(above, on: const [ground], ratio: 3);
      final down = RawPalette.readableTone(below, on: const [ground], ratio: 3);
      expect(toneOf(up), greaterThan(toneOf(above)));
      expect(toneOf(down), lessThan(toneOf(below)));
    });

    test('takes the ratio it is given', () {
      const on = [white];
      final aa = RawPalette.readableTone(gold, on: on);
      final aaa = RawPalette.readableTone(gold, on: on, ratio: 7);
      expect(worst(aaa, on), greaterThanOrEqualTo(7));
      expect(toneOf(aaa), lessThan(toneOf(aa)));
    });

    test('when no tone reads on all, the one that reads best on the worst', () {
      const on = [white, black];
      final c = RawPalette.readableTone(navy, on: on, ratio: 7);
      // A mid tone reads about 4.58:1 on both; none reaches 7:1 on both.
      expect(worst(c, on), greaterThan(4.5));
      expect(worst(c, on), lessThan(7));
    });

    test('keeps the alpha, reading the colour laid over each ground', () {
      const glass = Color(0x99C9A227);
      const on = [white];
      final c = RawPalette.readableTone(glass, on: on);
      expect(c.a, closeTo(glass.a, 1e-9));
      expect(worst(c, on), greaterThanOrEqualTo(4.5));
    });
  });

  group('RawPalette.accentFill', () {
    test('scheme, by day: light words, the fill darkened to carry them', () {
      final f = RawPalette.accentFill(gold, brightness: Brightness.light);
      expect(f.ink, white);
      expect(toneOf(f.fill), lessThan(toneOf(gold)));
      expect(hueApart(f.fill, gold), lessThan(2));
      expect(
        RawPalette.contrastRatio(f.ink, f.fill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('scheme, by night: dark words, the fill lightened to carry them', () {
      final f = RawPalette.accentFill(navy, brightness: Brightness.dark);
      expect(f.ink, darkInk);
      expect(toneOf(f.fill), greaterThan(toneOf(navy)));
      expect(
        RawPalette.contrastRatio(f.ink, f.fill),
        greaterThanOrEqualTo(4.5),
      );
    });

    test('scheme keeps a fill its ink already reads on', () {
      final f = RawPalette.accentFill(navy, brightness: Brightness.light);
      expect(f, const RawAccentFill(fill: navy, ink: white));
    });

    test('named keeps the gold by day, with the dark ink', () {
      final f = RawPalette.accentFill(
        gold,
        brightness: Brightness.light,
        rule: RawAccentRule.named,
      );
      expect(f, const RawAccentFill(fill: gold, ink: darkInk));
    });

    test('named keeps the navy by night, with the light ink', () {
      final f = RawPalette.accentFill(
        navy,
        brightness: Brightness.dark,
        rule: RawAccentRule.named,
      );
      expect(f, const RawAccentFill(fill: navy, ink: white));
    });

    test("named prefers the brightness's own ink when both read", () {
      const pale = Color(0xFFF4A7B9);
      final night = RawPalette.accentFill(
        pale,
        brightness: Brightness.dark,
        rule: RawAccentRule.named,
        lightInk: const Color(0xFFFFFFFF),
        darkInk: black,
        ratio: 1.5,
      );
      expect(night.ink, black);
      final day = RawPalette.accentFill(
        pale,
        brightness: Brightness.light,
        rule: RawAccentRule.named,
        darkInk: black,
        ratio: 1.5,
      );
      expect(day.ink, white);
      expect(day.fill, pale);
    });

    test('named moves a fill neither ink reads on, as little as it must', () {
      const mid = Color(0xFF787878);
      expect(RawPalette.contrastRatio(white, mid), lessThan(4.5));
      expect(RawPalette.contrastRatio(darkInk, mid), lessThan(4.5));
      final f = RawPalette.accentFill(
        mid,
        brightness: Brightness.light,
        rule: RawAccentRule.named,
      );
      expect(
        RawPalette.contrastRatio(f.ink, f.fill),
        greaterThanOrEqualTo(4.5),
      );
      final forWhite = RawPalette.readableTone(mid, on: const [white]);
      final forDark = RawPalette.readableTone(mid, on: const [darkInk]);
      final moved = (toneOf(f.fill) - toneOf(mid)).abs();
      expect(
        moved,
        closeTo(
          [
            (toneOf(forWhite) - toneOf(mid)).abs(),
            (toneOf(forDark) - toneOf(mid)).abs(),
          ].reduce((a, b) => a < b ? a : b),
          1e-9,
        ),
      );
    });

    test('reads the accent as opaque', () {
      final f = RawPalette.accentFill(
        const Color(0x40C9A227),
        brightness: Brightness.light,
        rule: RawAccentRule.named,
      );
      expect(f.fill.a, 1);
    });
  });

  group('RawNeutralTones', () {
    test("keeps the neutral's hue and chroma at the light end", () {
      final tones = RawNeutralTones.of(cream);
      final own = RawHct.fromColor(cream);
      expect(tones.ownTone, closeTo(own.tone, 1e-9));
      expect(tones.chroma, closeTo(own.chroma, 1e-9));
      final day = RawHct.fromColor(tones.tone(own.tone));
      expect(day.chroma, closeTo(own.chroma, 0.6));
      expect(hueApart(tones.tone(80), cream), lessThan(3));
    });

    test('holds the dark end to darkChroma, so a cream is never brown', () {
      const sand = Color(0xFFE9D3A6);
      final tones = RawNeutralTones.of(sand);
      expect(RawHct.fromColor(sand).chroma, greaterThan(12));
      for (final t in [4.0, 10.0, 20.0, 40.0]) {
        expect(RawHct.fromColor(tones.tone(t)).chroma, lessThanOrEqualTo(6.6));
      }
      expect(
        RawHct.fromColor(RawNeutralTones.of(sand, darkChroma: 2).tone(10))
            .chroma,
        lessThanOrEqualTo(2.6),
      );
      final mid = RawHct.fromColor(tones.tone(50)).chroma;
      expect(mid, greaterThan(6.6));
      expect(mid, lessThan(RawHct.fromColor(sand).chroma));
    });

    test('a grey neutral gives greys, and the ends are black and white', () {
      final tones = RawNeutralTones.of(white);
      final grey = tones.tone(30);
      expect(grey.r, grey.g);
      expect(grey.g, grey.b);
      expect(RawHct.fromColor(grey).tone, closeTo(30, 0.5));
      final fromBlack = RawNeutralTones.of(black).tone(60);
      expect([fromBlack.r, fromBlack.g], [fromBlack.b, fromBlack.b]);
      expect(tones.tone(120), white);
      expect(tones.tone(-5), black);
    });

    test('a near-white cream is a tint, not a grey: its night stays warm', () {
      // Its chroma (2.65) is under white's own in HCT (2.9, leaning blue),
      // but its hue is the far side of grey.
      const cream = Color(0xFFFFFBF5);
      final night = RawNeutralTones.of(cream).tone(10);
      expect({night.r, night.g, night.b}, hasLength(greaterThan(1)));
      final hue = RawHct.fromColor(night).hue;
      final own = RawHct.fromColor(cream).hue;
      expect((hue - own).abs(), lessThan(20));
      // A grey off by a level stays a grey.
      final off = RawNeutralTones.of(const Color(0xFFFAFAFA)).tone(10);
      expect({off.r, off.g, off.b}, hasLength(1));
    });
  });

  group('RawHct', () {
    test('round-trips an sRGB colour, its alpha left out', () {
      expect(RawHct.fromColor(navy).toColor(), navy);
      expect(RawHct.fromColor(const Color(0x801F3A68)).toColor(), navy);
    });

    test('withTone keeps the hue; withChroma the hue and tone', () {
      final h = RawHct.fromColor(const Color(0xFF2E7D32));
      final lighter = h.withTone(80);
      expect(lighter.tone, closeTo(80, 0.5));
      expect((lighter.hue - h.hue).abs(), lessThan(2));
      final duller = h.withChroma(10);
      expect(duller.chroma, closeTo(10, 0.5));
      expect(duller.tone, closeTo(h.tone, 0.5));
    });

    test('two of the same colour are equal', () {
      expect(RawHct.fromColor(navy), RawHct.fromColor(navy));
      expect(RawHct.fromColor(navy).hashCode, RawHct.fromColor(navy).hashCode);
      expect(RawHct.fromColor(navy) == RawHct.fromColor(gold), isFalse);
    });
  });

  test('a ratio under 1 or a chroma under 0 is a mistake', () {
    expect(
      () => RawPalette.readableTone(navy, on: const [white], ratio: 0.5),
      throwsAssertionError,
    );
    expect(
      () => RawPalette.accentFill(
        navy,
        brightness: Brightness.light,
        rule: RawAccentRule.named,
        ratio: 0.5,
      ),
      throwsAssertionError,
    );
    expect(
      () => RawNeutralTones.of(cream, darkChroma: -1),
      throwsAssertionError,
    );
    expect(
      () => RawPalette.accentFill(
        navy,
        brightness: Brightness.light,
        lightInk: const Color(0xB3FFFFFF),
      ),
      throwsAssertionError,
    );
  });
}
