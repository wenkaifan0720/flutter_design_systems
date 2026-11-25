/// Palette maths for a look's own colour API: how well two colours read
/// together, a colour walked in its own hue until it reads, a filled
/// control's colour and its label's ink for a named accent, and the neutral
/// tones of a tinted ground. Each look keeps its own words for its colours
/// (its `from`); these give it the numbers.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import 'internal/hct.dart';

/// The palette maths a look's colour API stands on, on Material's HCT
/// colour space (hue, chroma and tone, as `ColorScheme.fromSeed` reckons
/// them): a tone is CIE L*, 0 black to 100 white, so two opaque colours'
/// tones alone give their contrast.
///
/// ```dart
/// final words = RawPalette.readableTone(brand, on: [page, panel]);
/// final button = RawPalette.accentFill(brand, brightness: Brightness.dark);
/// ```
abstract final class RawPalette {
  /// WCAG 2's contrast ratio of [foreground] on [background], from 1 (the
  /// same luminance) to 21 (black on white). A translucent foreground is
  /// read as it is seen, laid over [background]; [background] is read as
  /// opaque.
  static double contrastRatio(Color foreground, Color background) {
    final ground = background.withValues(alpha: 1);
    final seen = Color.alphaBlend(foreground, ground);
    final a = seen.computeLuminance();
    final b = ground.computeLuminance();
    return (math.max(a, b) + 0.05) / (math.min(a, b) + 0.05);
  }

  /// [color] when it reads at [ratio] on every colour in [on]; else the tone
  /// of its hue and chroma nearest its own that does, darker or lighter,
  /// whichever is nearer. Its chroma drops only where sRGB cannot hold it at
  /// that tone, and its alpha is kept (read laid over each ground).
  ///
  /// Every ground the colour is painted on goes in [on] (the page, a panel,
  /// a selected row), so it reads on each. When no tone reads on all of them
  /// (a light and a dark ground at a ratio neither side reaches), it gives
  /// the tone that reads best on the one it reads worst on. With [on] empty
  /// it gives [color].
  ///
  /// ```dart
  /// // A navy accent for words on a night page and its raised panel.
  /// final accent = RawPalette.readableTone(
  ///   const Color(0xFF1F3A68),
  ///   on: const [Color(0xFF121212), Color(0xFF1E1E1E)],
  /// );
  /// ```
  static Color readableTone(
    Color color, {
    required Iterable<Color> on,
    double ratio = 4.5,
  }) {
    assert(ratio >= 1, 'a contrast ratio is 1 or more');
    final grounds = on.toList(growable: false);
    if (grounds.isEmpty || _worst(color, grounds) >= ratio) return color;
    final source = Hct.fromInt(color.withValues(alpha: 1).toARGB32());
    Color at(double tone) =>
        Color(Hct.from(source.hue, source.chroma, tone).toInt())
            .withValues(alpha: color.a);
    bool reads(double tone) => _worst(at(tone), grounds) >= ratio;

    // The first tone that reads, walking from the colour's own toward
    // [end] a tone at a time, then narrowed to a hundredth of one.
    double? toward(double end) {
      final step = end < source.tone ? -1.0 : 1.0;
      var fails = source.tone;
      while ((end - fails) * step > 0) {
        final next = (end - fails).abs() < 1 ? end : fails + step;
        if (reads(next)) {
          var good = next;
          for (var i = 0; i < 7; i++) {
            final mid = (fails + good) / 2;
            if (reads(mid)) {
              good = mid;
            } else {
              fails = mid;
            }
          }
          return good;
        }
        fails = next;
      }
      return null;
    }

    final darker = toward(0);
    final lighter = toward(100);
    if (darker == null && lighter == null) {
      var best = source.tone;
      var bestWorst = _worst(at(best), grounds);
      for (var tone = 0.0; tone <= 100; tone += 0.5) {
        final worst = _worst(at(tone), grounds);
        if (worst > bestWorst) {
          best = tone;
          bestWorst = worst;
        }
      }
      return at(best);
    }
    if (darker == null) return at(lighter!);
    if (lighter == null) return at(darker);
    final down = source.tone - darker;
    final up = lighter - source.tone;
    if (down != up) return at(down < up ? darker : lighter);
    final a = at(darker);
    final b = at(lighter);
    return _worst(a, grounds) >= _worst(b, grounds) ? a : b;
  }

  /// A filled control's colour and its label's ink for a named [accent],
  /// each reading on the other at [ratio], by [rule]. [lightInk] and
  /// [darkInk] are opaque.
  ///
  /// [RawAccentRule.scheme] (the default) pairs them as Material pairs a
  /// primary and its on-primary: by day the label is [lightInk] and the
  /// fill takes the nearest tone of [accent] it reads on (a gold goes
  /// olive); by night the label is [darkInk] and the fill lightens as far as
  /// it must. Where `ColorScheme.fromSeed` puts every primary at one tone
  /// (40 by day, 80 by night), it moves [accent] only as far as the ink
  /// needs, so a navy stays navy by day. [RawAccentRule.named] keeps [accent] as the
  /// fill whenever either ink reads on it (a gold keeps its gold, with dark
  /// words), and moves it only as far as it must when neither does. [accent]
  /// is read as opaque.
  ///
  /// ```dart
  /// final stop = RawPalette.accentFill(
  ///   const Color(0xFFC9A227),
  ///   brightness: Brightness.light,
  ///   rule: RawAccentRule.named,
  /// );
  /// // stop.fill is the gold itself and stop.ink the dark ink.
  /// ```
  static RawAccentFill accentFill(
    Color accent, {
    required Brightness brightness,
    RawAccentRule rule = RawAccentRule.scheme,
    Color lightInk = const Color(0xFFFFFFFF),
    Color darkInk = const Color(0xFF111111),
    double ratio = 4.5,
  }) {
    assert(ratio >= 1, 'a contrast ratio is 1 or more');
    assert(lightInk.a == 1 && darkInk.a == 1, 'the inks are opaque');
    final named = accent.withValues(alpha: 1);
    final (preferred, other) = brightness == Brightness.light
        ? (lightInk, darkInk)
        : (darkInk, lightInk);
    switch (rule) {
      case RawAccentRule.scheme:
        return RawAccentFill(
          fill: readableTone(named, on: [preferred], ratio: ratio),
          ink: preferred,
        );
      case RawAccentRule.named:
        if (contrastRatio(preferred, named) >= ratio) {
          return RawAccentFill(fill: named, ink: preferred);
        }
        if (contrastRatio(other, named) >= ratio) {
          return RawAccentFill(fill: named, ink: other);
        }
        final tone = Hct.fromInt(named.toARGB32()).tone;
        double moved(Color c) => (Hct.fromInt(c.toARGB32()).tone - tone).abs();
        final forPreferred = readableTone(named, on: [preferred], ratio: ratio);
        final forOther = readableTone(named, on: [other], ratio: ratio);
        return moved(forOther) < moved(forPreferred)
            ? RawAccentFill(fill: forOther, ink: other)
            : RawAccentFill(fill: forPreferred, ink: preferred);
    }
  }

  // How [color] reads on the ground it reads worst on.
  static double _worst(Color color, List<Color> grounds) =>
      grounds.map((g) => contrastRatio(color, g)).reduce(math.min);
}

/// How [RawPalette.accentFill] fits a filled control's colour to a named
/// accent.
enum RawAccentRule {
  /// As Material pairs a primary and its on-primary: the label's ink follows
  /// the brightness (light by day, dark by night) and the fill takes the
  /// nearest tone of the accent that ink reads on.
  scheme,

  /// The named accent stays the fill whenever the light or the dark ink
  /// reads on it, that ink its label's; the fill moves only when neither
  /// does, as little as it must.
  named,
}

/// A filled control's colour and the ink of its label, from
/// [RawPalette.accentFill].
@immutable
class RawAccentFill with Diagnosticable {
  /// A [fill] and the [ink] that reads on it.
  const RawAccentFill({required this.fill, required this.ink});

  /// The control's colour.
  final Color fill;

  /// Its label's and icon's colour.
  final Color ink;

  @override
  bool operator ==(Object other) =>
      other is RawAccentFill && other.fill == fill && other.ink == ink;

  @override
  int get hashCode => Object.hash(fill, ink);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(ColorProperty('ink', ink));
  }
}

/// The neutral tones of a tinted ground: any tone in the hue of a named
/// [neutral] (a cream, a sand, a cool white), from 0 (black) to 100 (white).
///
/// At the light end (tone 60 up) a tone keeps the neutral's own chroma;
/// at the dark end (tone 40 down) its chroma is at most [darkChroma]
/// (6 by default, as the neutral palette of Material's tonal-spot scheme
/// holds), eased between. So a cream
/// page stays cream by day and its night grounds are a warm charcoal, never
/// brown. A look picks its own tones for its page, panels and lines, and
/// keeps a day page in the light band with [ownTone]. A grey neutral (white,
/// black, any sRGB grey) gives sRGB's greys.
///
/// ```dart
/// final cream = RawNeutralTones.of(const Color(0xFFFFF4EC));
/// final nightPage = cream.tone(6);
/// final nightPanel = cream.tone(12);
/// ```
@immutable
class RawNeutralTones with Diagnosticable {
  /// The tones of [neutral]'s hue, its chroma held to [darkChroma] at the
  /// dark end. [neutral] is read as opaque.
  factory RawNeutralTones.of(Color neutral, {double darkChroma = 6}) {
    assert(darkChroma >= 0, 'darkChroma is a chroma, 0 or more');
    final hct = Hct.fromInt(neutral.withValues(alpha: 1).toARGB32());
    // sRGB's greys carry a little colour of their own in HCT (white's
    // chroma is about 2.9, toward blue): a neutral within one chroma step of
    // the grey of its tone, hue and chroma together, is a grey and gives
    // greys. A cream of lower chroma than white's lies the far side of it.
    final grey = Hct.fromInt(ColorUtils.argbFromLstar(hct.tone));
    return RawNeutralTones._(
      hct.hue,
      hct.chroma,
      hct.tone,
      darkChroma,
      grey: _apart(hct, grey) <= 1,
    );
  }

  const RawNeutralTones._(
    this.hue,
    this.chroma,
    this.ownTone,
    this.darkChroma, {
    required bool grey,
    // A private field set from a named parameter, which an initializing
    // formal cannot be.
    // ignore: prefer_initializing_formals
  }) : _grey = grey;

  /// The neutral's hue, in degrees.
  final double hue;

  /// The neutral's own chroma, which the light end keeps.
  final double chroma;

  /// The neutral's own tone, 0 (black) to 100 (white).
  final double ownTone;

  /// The most chroma a tone of 40 or less takes.
  final double darkChroma;

  final bool _grey;

  /// The colour at [tone] (clamped to 0 to 100) in the neutral's hue.
  Color tone(double tone) {
    final t = tone.clamp(0.0, 100.0);
    if (_grey) return Color(ColorUtils.argbFromLstar(t));
    final dark = math.min(chroma, darkChroma);
    final c = t >= 60
        ? chroma
        : t <= 40
        ? dark
        : dark + (chroma - dark) * (t - 40) / 20;
    return Color(Hct.from(hue, c, t).toInt());
  }

  @override
  bool operator ==(Object other) =>
      other is RawNeutralTones &&
      other.hue == hue &&
      other.chroma == chroma &&
      other.ownTone == ownTone &&
      other.darkChroma == darkChroma;

  @override
  int get hashCode => Object.hash(hue, chroma, ownTone, darkChroma);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('hue', hue))
      ..add(DoubleProperty('chroma', chroma))
      ..add(DoubleProperty('ownTone', ownTone))
      ..add(DoubleProperty('darkChroma', darkChroma));
  }
}

/// A colour by Material's hue, chroma and tone (HCT), the space
/// `ColorScheme.fromSeed` builds its tones in: [hue] in degrees, [chroma]
/// its colourfulness, [tone] CIE L* from 0 (black) to 100 (white). A tone
/// keeps its hue as it darkens or lightens, where HSL's lightness drifts
/// it; two opaque colours' tones alone give their contrast. A hue, chroma
/// and tone sRGB can't hold comes back at the most chroma it can, so a
/// colour moved to a far tone and back may have lost some, as Material's
/// `Hct` does.
///
/// ```dart
/// final brand = RawHct.fromColor(const Color(0xFF2E7D32));
/// final edge = brand.withTone(brand.tone - 12).toColor();
/// ```
@immutable
class RawHct with Diagnosticable {
  const RawHct._(this.hue, this.chroma, this.tone, this._argb);

  /// [color]'s hue, chroma and tone; its alpha is left out.
  factory RawHct.fromColor(Color color) =>
      RawHct._of(Hct.fromInt(color.withValues(alpha: 1).toARGB32()));

  factory RawHct._of(Hct hct) =>
      RawHct._(hct.hue, hct.chroma, hct.tone, hct.toInt());

  /// The hue, in degrees from 0 to 360.
  final double hue;

  /// The chroma: 0 for a grey, upward for more colourful.
  final double chroma;

  /// The tone, CIE L*: 0 black to 100 white.
  final double tone;

  final int _argb;

  /// The opaque colour.
  Color toColor() => Color(_argb);

  /// This hue and chroma at [tone]; the chroma drops where sRGB cannot hold
  /// it there, as Material's `Hct` does.
  RawHct withTone(double tone) => RawHct._of(Hct.from(hue, chroma, tone));

  /// This hue and tone at [chroma], or the most sRGB holds there.
  RawHct withChroma(double chroma) => RawHct._of(Hct.from(hue, chroma, tone));

  @override
  bool operator ==(Object other) => other is RawHct && other._argb == _argb;

  @override
  int get hashCode => _argb.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('hue', hue))
      ..add(DoubleProperty('chroma', chroma))
      ..add(DoubleProperty('tone', tone));
  }
}

// The distance between two colours' hue and chroma, as a point on the
// colour wheel (chroma along the hue's direction).
double _apart(Hct a, Hct b) {
  final ah = a.hue * math.pi / 180, bh = b.hue * math.pi / 180;
  final dx = a.chroma * math.cos(ah) - b.chroma * math.cos(bh);
  final dy = a.chroma * math.sin(ah) - b.chroma * math.sin(bh);
  return math.sqrt(dx * dx + dy * dy);
}
