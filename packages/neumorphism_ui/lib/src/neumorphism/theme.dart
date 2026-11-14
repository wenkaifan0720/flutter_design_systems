// Neumorphism's tokens: one cast material, cool porcelain by default, lit from the top left, and one mineral pigment set into
// it. `NeumorphicTheme.of(context)` is the only way in. The concept's values are the first preset; every preset changes the
// plaster and the pigment together, and each mode is a seed of its own, decided rather than inverted.
//
// The pigment is not on `NeumorphicColors`. It means one thing, live, and a page reaches it only through a part that says
// so (`NeumorphicLiveText`, `NeumorphicLed`, `NeumorphicButton.filled`, a latched control): `NeumorphicPigment` is hidden from the barrel.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'component_themes.dart';
import 'knobs.dart';
import 'shapes.dart';

import 'package:material_ui/material_ui.dart';

/// The meaning of a notice, distinguished by a glyph and its words.
enum NeumorphicTone {
  /// Neutral information or guidance.
  info,

  /// An operation completed successfully.
  success,

  /// Something needs attention before proceeding.
  warning,

  /// An error or destructive consequence.
  danger,
}

/// The width where the phone layout becomes the 12-column desktop layout.
const double neumorphicDesktopBreakpoint = 1024;

/// An engraved rule's width, between rows and inside a part.
const double neumorphicRuleWidth = 1;

/// The fine outline high contrast prints, and the width of an edge a part's style asks for.
const double neumorphicEdgeWidth = 1.5;

/// Window size classes, independent of the look's desktop navigation breakpoint.
enum NeumorphicWindow {
  /// Less than 600 logical pixels.
  compact,

  /// From 600 to 839 logical pixels.
  medium,

  /// From 840 to 1199 logical pixels.
  expanded,

  /// At least 1200 logical pixels.
  large;

  /// Classifies a window's width.
  static NeumorphicWindow forWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : width < 1200
      ? expanded
      : large;
}

/// The look's radii, all of them. A box holding words or controls stays on this scale, however soft the look wants to be:
/// softness here is the shadow's job. Only objects keep their own shape: a dial, a knob, a switch's slot, a round push
/// button, a monogram, a check, an LED, an arched window with nothing written in it.
abstract final class NeumorphicRadii {
  /// A slab: a card on the wall, a tab bar's shoulders. The concept's 24 sits at the ceiling; this sits under it.
  static const double slab = 20;

  /// A well holding words or a chart, a bank of buttons, the day's tray. The concept's 18 to 28.
  static const double well = 14;

  /// A control you press or type in, a stat's well, a small well, a picture. The concept's pills.
  static const double control = 12;

  /// A chip, an event's tile.
  static const double chip = 10;

  /// A latch's cap inside its bank, a small mark holding a figure.
  static const double cap = 8;

  /// The smallest corner the look cuts. Moulded plaster has no sharp corner: a face moved in from its holder keeps at
  /// least this much round, and a pressed row or cell rounds by it where it meets its neighbour.
  static const double least = 6;
}

/// The illustration's colours: what the look's relief (a lit building by night) and its sky draw with. They change with
/// the preset and the night like the rest of the plaster, and no part of a page reads them.
@immutable
class NeumorphicArtColors {
  /// The relief's colours, each set by the preset.
  const NeumorphicArtColors({
    required this.lamp,
    required this.moon,
    required this.moonShade,
    required this.star,
  });

  /// Lamplight in a lit window: the one warm thing, secondary to the pigment.
  final Color lamp;

  /// The moon's lit side.
  final Color moon;

  /// The moon's shaded side, the far stop of its gradient.
  final Color moonShade;

  /// The pinprick stars.
  final Color star;

  /// The colours [t] of the way from [a] to [b].
  static NeumorphicArtColors lerp(
    NeumorphicArtColors a,
    NeumorphicArtColors b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return NeumorphicArtColors(
      lamp: Color.lerp(a.lamp, b.lamp, t)!,
      moon: Color.lerp(a.moon, b.moon, t)!,
      moonShade: Color.lerp(a.moonShade, b.moonShade, t)!,
      star: Color.lerp(a.star, b.star, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is NeumorphicArtColors &&
      other.lamp == lamp &&
      other.moon == moon &&
      other.moonShade == moonShade &&
      other.star == star;

  @override
  int get hashCode => Object.hash(lamp, moon, moonShade, star);
}

/// The plaster: what a page may read. Field names follow the concept's CSS variables.
class NeumorphicColors {
  const NeumorphicColors._({
    required this.dark,
    required this.ground,
    required this.faceStart,
    required this.faceEnd,
    required this.wellStart,
    required this.wellEnd,
    required this.highlight,
    required this.highlightSoft,
    required this.shadow,
    required this.shadowDeep,
    required this.shadowInset,
    required this.rim,
    required this.crease,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.quiet,
    required this.edge,
    required this.barStart,
    required this.barEnd,
    required this.domeLight,
    required this.domeMid,
    required this.domeDark,
    required this.fluteHighlight,
    required this.fluteShadow,
    required this.art,
    required this.toneLight,
    required this.toneMid,
    required this.toneDark,
    required this.toneDetail,
    required this._pigment,
    required this._pigmentHi,
    required this._pigmentDk,
    required this._pigmentInk,
    required this._pigmentInkLit,
    required this._onPigment,
  });

  /// Whether these colours were designed for a dark appearance.
  final bool dark;

  /// The wall: the page's ground, every surface's base.
  final Color ground;

  /// A raised face's two ends, on a 145 degree gradient: light top left, convex.
  final Color faceStart, faceEnd;

  /// A pressed face's two ends, the same gradient reversed: concave.
  final Color wellStart, wellEnd;

  /// The light shadow up-left, its softer form, and the dark shadow: cards, cast objects, insets.
  final Color highlight, highlightSoft, shadow, shadowDeep, shadowInset;

  /// The 1 px inner catch-light and inner crease: at night these do most of the edge's work.
  final Color rim, crease;

  /// Words: titles, secondary, captions. All three read at 4.5 on every face and well.
  final Color ink, inkSecondary, inkTertiary;

  /// A mark with no words: a scale's small ticks, an empty slot. 3:1 on every face and well, and never words.
  final Color quiet;

  /// An optional high-contrast outline: 4:1 on every face and well.
  /// Ordinary controls use relief; this ink is reserved for explicit boundaries.
  final Color edge;

  /// A chart's data bars, top to foot.
  final Color barStart, barEnd;

  /// A glossy dome's three stops: dial, knobs, beads.
  final Color domeLight, domeMid, domeDark;

  /// A flute's two strokes, on the collar.
  final Color fluteHighlight, fluteShadow;

  /// The illustration's own colours: the relief's lamplight, moon and stars. A page never reads them.
  final NeumorphicArtColors art;

  /// The plaster's own greys, for a drawing with no picture: light to dark, then the darkest detail.
  final Color toneLight, toneMid, toneDark, toneDetail;

  final Color _pigment,
      _pigmentHi,
      _pigmentDk,
      _pigmentInk,
      _pigmentInkLit,
      _onPigment;

  /// The colours [t] of the way from [a] to [b]. Whether it is a night palette snaps at the middle.
  static NeumorphicColors lerp(
    NeumorphicColors a,
    NeumorphicColors b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return NeumorphicColors._(
      dark: t < .5 ? a.dark : b.dark,
      ground: Color.lerp(a.ground, b.ground, t)!,
      faceStart: Color.lerp(a.faceStart, b.faceStart, t)!,
      faceEnd: Color.lerp(a.faceEnd, b.faceEnd, t)!,
      wellStart: Color.lerp(a.wellStart, b.wellStart, t)!,
      wellEnd: Color.lerp(a.wellEnd, b.wellEnd, t)!,
      highlight: Color.lerp(a.highlight, b.highlight, t)!,
      highlightSoft: Color.lerp(a.highlightSoft, b.highlightSoft, t)!,
      shadow: Color.lerp(a.shadow, b.shadow, t)!,
      shadowDeep: Color.lerp(a.shadowDeep, b.shadowDeep, t)!,
      shadowInset: Color.lerp(a.shadowInset, b.shadowInset, t)!,
      rim: Color.lerp(a.rim, b.rim, t)!,
      crease: Color.lerp(a.crease, b.crease, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      inkSecondary: Color.lerp(a.inkSecondary, b.inkSecondary, t)!,
      inkTertiary: Color.lerp(a.inkTertiary, b.inkTertiary, t)!,
      quiet: Color.lerp(a.quiet, b.quiet, t)!,
      edge: Color.lerp(a.edge, b.edge, t)!,
      barStart: Color.lerp(a.barStart, b.barStart, t)!,
      barEnd: Color.lerp(a.barEnd, b.barEnd, t)!,
      domeLight: Color.lerp(a.domeLight, b.domeLight, t)!,
      domeMid: Color.lerp(a.domeMid, b.domeMid, t)!,
      domeDark: Color.lerp(a.domeDark, b.domeDark, t)!,
      fluteHighlight: Color.lerp(a.fluteHighlight, b.fluteHighlight, t)!,
      fluteShadow: Color.lerp(a.fluteShadow, b.fluteShadow, t)!,
      art: NeumorphicArtColors.lerp(a.art, b.art, t),
      toneLight: Color.lerp(a.toneLight, b.toneLight, t)!,
      toneMid: Color.lerp(a.toneMid, b.toneMid, t)!,
      toneDark: Color.lerp(a.toneDark, b.toneDark, t)!,
      toneDetail: Color.lerp(a.toneDetail, b.toneDetail, t)!,
      pigment: Color.lerp(a._pigment, b._pigment, t)!,
      pigmentHi: Color.lerp(a._pigmentHi, b._pigmentHi, t)!,
      pigmentDk: Color.lerp(a._pigmentDk, b._pigmentDk, t)!,
      pigmentInk: Color.lerp(a._pigmentInk, b._pigmentInk, t)!,
      pigmentInkLit: Color.lerp(a._pigmentInkLit, b._pigmentInkLit, t)!,
      onPigment: Color.lerp(a._onPigment, b._onPigment, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeumorphicColors &&
          other.dark == dark &&
          other.ground == ground &&
          other.faceStart == faceStart &&
          other.faceEnd == faceEnd &&
          other.wellStart == wellStart &&
          other.wellEnd == wellEnd &&
          other.highlight == highlight &&
          other.highlightSoft == highlightSoft &&
          other.shadow == shadow &&
          other.shadowDeep == shadowDeep &&
          other.shadowInset == shadowInset &&
          other.rim == rim &&
          other.crease == crease &&
          other.ink == ink &&
          other.inkSecondary == inkSecondary &&
          other.inkTertiary == inkTertiary &&
          other.quiet == quiet &&
          other.edge == edge &&
          other.barStart == barStart &&
          other.barEnd == barEnd &&
          other.domeLight == domeLight &&
          other.domeMid == domeMid &&
          other.domeDark == domeDark &&
          other.fluteHighlight == fluteHighlight &&
          other.fluteShadow == fluteShadow &&
          other.art == art &&
          other.toneLight == toneLight &&
          other.toneMid == toneMid &&
          other.toneDark == toneDark &&
          other.toneDetail == toneDetail &&
          other._pigment == _pigment &&
          other._pigmentHi == _pigmentHi &&
          other._pigmentDk == _pigmentDk &&
          other._pigmentInk == _pigmentInk &&
          other._pigmentInkLit == _pigmentInkLit &&
          other._onPigment == _onPigment;

  @override
  int get hashCode => Object.hashAll([
    dark,
    ground,
    faceStart,
    faceEnd,
    wellStart,
    wellEnd,
    highlight,
    highlightSoft,
    shadow,
    shadowDeep,
    shadowInset,
    rim,
    crease,
    ink,
    inkSecondary,
    inkTertiary,
    quiet,
    edge,
    barStart,
    barEnd,
    domeLight,
    domeMid,
    domeDark,
    fluteHighlight,
    fluteShadow,
    art,
    toneLight,
    toneMid,
    toneDark,
    toneDetail,
    _pigment,
    _pigmentHi,
    _pigmentDk,
    _pigmentInk,
    _pigmentInkLit,
    _onPigment,
  ]);

  /// The accent fill for primary actions and app-defined controls.
  Color get accent => _pigment;

  /// Words and glyphs on [accent].
  Color get onAccent => _onPigment;

  /// Accent words on the material's unfilled surfaces.
  Color get accentInk => _pigmentInk;

  /// A light wash on a line chart's area.
  Color get area => inkSecondary.withValues(alpha: dark ? .14 : .18);
}

/// The pigment. Hidden from the barrel on purpose: a page that wants it asks a part, so it can't spread by accident.
extension NeumorphicPigment on NeumorphicColors {
  /// The fill: a switch's slot, a dial's arc, the act, a live series.
  Color get pigment => _pigment;

  /// The lit and deep ends of its gradients.
  Color get pigmentHi => _pigmentHi;

  /// The deep end of a pigment gradient.
  Color get pigmentDk => _pigmentDk;

  /// Words in the pigment.
  Color get pigmentInk => _pigmentInk;

  /// Words in the pigment over a wash.
  Color get pigmentInkLit => _pigmentInkLit;

  /// Letters on a filled pigment.
  Color get onPigment => _onPigment;

  /// The pigment washed into a pressed face: one even tint over the whole shape. At night .10, so the pigment's own
  /// words and glyphs keep 4.5:1 on it everywhere (a radial wash at .16 faded before the glyph; an even one does not).
  Color get wash => _pigment.withValues(alpha: dark ? .10 : .13);

  /// The ring around an LED.
  Color get ledGlow => _pigment.withValues(alpha: dark ? .25 : .18);
}

/// One appearance of a preset, by what a designer picks. Everything else is worked out in [_Seed.colors].
class _Seed {
  const _Seed({
    required this.dark,
    required this.ground,
    required this.faceStart,
    required this.faceEnd,
    required this.wellStart,
    required this.wellEnd,
    required this.highlight,
    required this.shadow,
    required this.shadowDeep,
    required this.shadowInset,
    required this.rim,
    required this.crease,
    required this.ink,
    required this.inkSecondary,
    required this.inkTertiary,
    required this.quiet,
    required this.barStart,
    required this.barEnd,
    required this.domeLight,
    required this.domeMid,
    required this.domeDark,
    required this.lamp,
    required this.moon1,
    required this.moon2,
    required this.pigment,
    required this.pigmentHi,
    required this.pigmentDk,
    required this.pigmentInk,
    required this.pigmentInkLit,
    required this.onPigment,
  });
  final bool dark;
  final Color ground,
      faceStart,
      faceEnd,
      wellStart,
      wellEnd,
      highlight,
      shadow,
      shadowDeep,
      shadowInset,
      rim,
      crease,
      ink,
      inkSecondary,
      inkTertiary,
      quiet,
      barStart,
      barEnd,
      domeLight,
      domeMid,
      domeDark,
      lamp,
      moon1,
      moon2,
      pigment,
      pigmentHi,
      pigmentDk,
      pigmentInk,
      pigmentInkLit,
      onPigment;

  NeumorphicColors get colors => NeumorphicColors._(
    dark: dark,
    ground: ground,
    faceStart: faceStart,
    faceEnd: faceEnd,
    wellStart: wellStart,
    wellEnd: wellEnd,
    // By night the light side is a faint rim: the ground lifted a little toward the seed's light, never a glow. The
    // dark side carries the depth.
    highlight: dark
        ? Color.lerp(ground, highlight.withValues(alpha: 1), .15)!
        : highlight,
    highlightSoft: dark
        ? Color.lerp(ground, highlight.withValues(alpha: 1), .1)!
        : highlight.withValues(alpha: highlight.a * .74),
    shadow: shadow,
    shadowDeep: shadowDeep,
    shadowInset: shadowInset,
    rim: rim,
    crease: crease,
    ink: ink,
    inkSecondary: inkSecondary,
    inkTertiary: inkTertiary,
    quiet: quiet,
    edge: Color.lerp(quiet, inkTertiary, .45)!,
    barStart: barStart,
    barEnd: barEnd,
    domeLight: domeLight,
    domeMid: domeMid,
    domeDark: domeDark,
    fluteHighlight: highlight.withValues(alpha: dark ? .13 : .95),
    fluteShadow: shadow.withValues(alpha: dark ? .55 : .75),
    art: NeumorphicArtColors(
      lamp: lamp,
      moon: moon1,
      moonShade: moon2,
      star: dark
          ? moon1.withValues(alpha: .55)
          : shadowDeep.withValues(alpha: shadowDeep.a * .96),
    ),
    toneLight: dark
        ? Color.lerp(faceStart, inkTertiary, .22)!
        : Color.lerp(faceStart, inkTertiary, .02)!,
    toneMid: dark
        ? Color.lerp(wellStart, inkTertiary, .04)!
        : Color.lerp(wellStart, inkTertiary, .18)!,
    toneDark: dark
        ? Color.lerp(faceStart, inkTertiary, .36)!
        : Color.lerp(wellStart, inkTertiary, .32)!,
    toneDetail: inkSecondary,
    pigment: pigment,
    pigmentHi: pigmentHi,
    pigmentDk: pigmentDk,
    pigmentInk: pigmentInk,
    pigmentInkLit: pigmentInkLit,
    onPigment: onPigment,
  );
}

/// One preset, designed in both modes.
class _Palette {
  const _Palette(this.day, this.night);
  final _Seed day, night;
}

double _contrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

// Move toward the appropriate luminance extreme, preserving as much of the
// requested hue as the contrast constraint allows. Bisection avoids rounding
// a color back under the requested bar.
Color _settle(Color color, List<Color> grounds, Color end, double ratio) {
  bool reads(Color c) => grounds.every((g) => _contrast(c, g) >= ratio);
  final opaque = color.withValues(alpha: 1);
  if (reads(opaque)) return opaque;
  var low = 0.0, high = 1.0;
  for (var i = 0; i < 32; i++) {
    final middle = (low + high) / 2;
    if (reads(Color.lerp(opaque, end, middle)!)) {
      high = middle;
    } else {
      low = middle;
    }
  }
  return Color.lerp(opaque, end, high)!;
}

_Seed _brandSeed(Color ground, Color pigment, Brightness brightness) {
  const white = Color(0xFFFFFFFF), black = Color(0xFF000000);
  final dark = brightness == Brightness.dark;
  final paper = dark ? black : white, ink = dark ? white : black;
  // A soft material needs closely related surfaces. Reserve enough luminance
  // room before deriving them, including hostile mid-grey and transparent input.
  final base = _settle(Color.alphaBlend(ground, paper), [ink], paper, 12);
  Color mix(Color a, Color b, double amount) => Color.lerp(a, b, amount)!;
  final faceStart = mix(base, white, dark ? .035 : .07);
  final faceEnd = mix(base, black, dark ? .16 : .035);
  final wellStart = mix(base, black, dark ? .23 : .05);
  final wellEnd = mix(base, white, dark ? .012 : .025);
  final grounds = [base, faceStart, faceEnd, wellStart, wellEnd];
  final act = _settle(Color.alphaBlend(pigment, base), grounds, ink, 4.6);
  final wash = act.withValues(alpha: dark ? .16 : .13);
  final all = [...grounds, for (final g in grounds) Color.alphaBlend(wash, g)];
  Color word(double amount, double ratio) =>
      _settle(mix(base, ink, amount), all, ink, ratio);
  final onAct = _contrast(white, act) >= _contrast(black, act) ? white : black;
  final actDeep = _settle(mix(act, ink, .12), [onAct], ink, 4.6);
  return _Seed(
    dark: dark,
    ground: base,
    faceStart: faceStart,
    faceEnd: faceEnd,
    wellStart: wellStart,
    wellEnd: wellEnd,
    highlight: white.withValues(alpha: dark ? .08 : .95),
    shadow: black.withValues(alpha: dark ? .75 : .25),
    shadowDeep: black.withValues(alpha: dark ? .62 : .32),
    shadowInset: black.withValues(alpha: dark ? .6 : .27),
    rim: white.withValues(alpha: dark ? .1 : .85),
    crease: black.withValues(alpha: dark ? .35 : .12),
    ink: word(.95, 7),
    inkSecondary: word(.8, 5),
    inkTertiary: word(.65, 4.6),
    quiet: word(.55, 4.1),
    barStart: word(.65, 4.1),
    barEnd: word(.8, 4.1),
    domeLight: mix(base, white, dark ? .1 : .55),
    domeMid: base,
    domeDark: mix(base, black, dark ? .15 : .08),
    lamp: mix(act, white, .35),
    moon1: mix(base, white, .6),
    moon2: mix(base, white, .15),
    pigment: act,
    pigmentHi: mix(act, white, .2),
    pigmentDk: actDeep,
    pigmentInk: _settle(act, all, ink, 4.6),
    pigmentInkLit: _settle(act, all, ink, 4.6),
    onPigment: onAct,
  );
}

/// Porcelain plaster and ultramarine, the concept's own: the fresco blue on a cool grey-blue lime, lit to a clear cobalt
/// on a moonlit blue-slate at night.
const _plaster = _Palette(
  _Seed(
    dark: false,
    ground: Color(0xFFE4E8EE),
    faceStart: Color(0xFFEDF0F5),
    faceEnd: Color(0xFFD8DDE5),
    wellStart: Color(0xFFD5DAE2),
    wellEnd: Color(0xFFE7EBF0),
    highlight: Color(0xF2FFFFFF),
    shadow: Color(0x66606E8C),
    shadowDeep: Color(0x7A52607E),
    shadowInset: Color(0x70606E8C),
    rim: Color(0xD9FFFFFF),
    crease: Color(0x1F3C4A68),
    ink: Color(0xFF121826),
    inkSecondary: Color(0xFF3A4356),
    inkTertiary: Color(0xFF485264),
    quiet: Color(0xFF6E7889),
    barStart: Color(0xFF4C566B),
    barEnd: Color(0xFF2F3849),
    domeLight: Color(0xFFFBFCFE),
    domeMid: Color(0xFFE4E8EE),
    domeDark: Color(0xFFCDD3DD),
    lamp: Color(0xFFFFAA60),
    moon1: Color(0xFFFBFCFE),
    moon2: Color(0xFFE4E8EE),
    pigment: Color(0xFF2E46D0),
    pigmentHi: Color(0xFF5E78F2),
    pigmentDk: Color(0xFF2337B0),
    pigmentInk: Color(0xFF2E46D0),
    pigmentInkLit: Color(0xFF2337B0),
    onPigment: Color(0xFFFFFFFF),
  ),
  _Seed(
    dark: true,
    ground: Color(0xFF1E2431),
    faceStart: Color(0xFF272E3C),
    faceEnd: Color(0xFF181D28),
    wellStart: Color(0xFF151A24),
    wellEnd: Color(0xFF232A37),
    highlight: Color(0x12B4C8FF),
    shadow: Color(0x8C03060E),
    shadowDeep: Color(0x9E03060E),
    shadowInset: Color(0x9903060E),
    rim: Color(0x1AC8D7FF),
    crease: Color(0x59000000),
    ink: Color(0xFFEEF1F7),
    inkSecondary: Color(0xFFC3CAD8),
    inkTertiary: Color(0xFF98A1B3),
    quiet: Color(0xFF7C869A),
    barStart: Color(0xFFD3D9E5),
    barEnd: Color(0xFFAEB7C8),
    domeLight: Color(0xFF343C4C),
    domeMid: Color(0xFF262D3A),
    domeDark: Color(0xFF191E29),
    lamp: Color(0xFFFF9A4E),
    moon1: Color(0xFFE2E9FA),
    moon2: Color(0xFF94A2C4),
    pigment: Color(0xFF7896FF),
    pigmentHi: Color(0xFFA3B8FF),
    pigmentDk: Color(0xFF6584F5),
    pigmentInk: Color(0xFF93ABFF),
    pigmentInkLit: Color(0xFF93ABFF),
    onPigment: Color(0xFF121826),
  ),
);

/// Warm lime and Pompeian red: a villa's wall. At night an umber wall by lamplight, the red lifted to vermilion.
const _pompeii = _Palette(
  _Seed(
    dark: false,
    ground: Color(0xFFEDE7DF),
    faceStart: Color(0xFFF5F0E9),
    faceEnd: Color(0xFFE1DACF),
    wellStart: Color(0xFFDDD5CA),
    wellEnd: Color(0xFFEFEAE2),
    highlight: Color(0xF2FFFFFF),
    shadow: Color(0x61826854),
    shadowDeep: Color(0x75705846),
    shadowInset: Color(0x6B826854),
    rim: Color(0xD9FFFFFF),
    crease: Color(0x1F5A4230),
    ink: Color(0xFF1E1510),
    inkSecondary: Color(0xFF473A30),
    inkTertiary: Color(0xFF55483D),
    quiet: Color(0xFF7C6E62),
    barStart: Color(0xFF5E4F44),
    barEnd: Color(0xFF3F332A),
    domeLight: Color(0xFFFEFCF9),
    domeMid: Color(0xFFEDE7DF),
    domeDark: Color(0xFFD7CFC4),
    lamp: Color(0xFFFFC27A),
    moon1: Color(0xFFFEFCF9),
    moon2: Color(0xFFEDE7DF),
    pigment: Color(0xFFA82A1C),
    pigmentHi: Color(0xFFD9553F),
    pigmentDk: Color(0xFF8A1F13),
    pigmentInk: Color(0xFFA02718),
    pigmentInkLit: Color(0xFF8A1F13),
    onPigment: Color(0xFFFFFFFF),
  ),
  _Seed(
    dark: true,
    ground: Color(0xFF2A2220),
    faceStart: Color(0xFF362C29),
    faceEnd: Color(0xFF1F1917),
    wellStart: Color(0xFF1B1513),
    wellEnd: Color(0xFF302725),
    highlight: Color(0x12FFDCBE),
    shadow: Color(0x8C0A0503),
    shadowDeep: Color(0x9E0A0503),
    shadowInset: Color(0x990A0503),
    rim: Color(0x1AFFE1CD),
    crease: Color(0x59000000),
    ink: Color(0xFFF5EEE8),
    inkSecondary: Color(0xFFD6CBC2),
    inkTertiary: Color(0xFFAFA399),
    quiet: Color(0xFF908479),
    barStart: Color(0xFFE2D8CF),
    barEnd: Color(0xFFBEB2A8),
    domeLight: Color(0xFF443936),
    domeMid: Color(0xFF332A27),
    domeDark: Color(0xFF211A18),
    lamp: Color(0xFFFFB46A),
    moon1: Color(0xFFF6E9DC),
    moon2: Color(0xFFB7A493),
    pigment: Color(0xFFF07F62),
    pigmentHi: Color(0xFFFFA98F),
    pigmentDk: Color(0xFFD9664A),
    pigmentInk: Color(0xFFF6957C),
    pigmentInkLit: Color(0xFFF6957C),
    onPigment: Color(0xFF1E1510),
  ),
);

/// Grey-green lime and Verona's green earth: a cloister wall. At night deep fir, the green lit to verdigris.
const _verona = _Palette(
  _Seed(
    dark: false,
    ground: Color(0xFFE3E9E3),
    faceStart: Color(0xFFEDF2ED),
    faceEnd: Color(0xFFD6DED7),
    wellStart: Color(0xFFD2DAD3),
    wellEnd: Color(0xFFE6ECE6),
    highlight: Color(0xF2FFFFFF),
    shadow: Color(0x61587464),
    shadowDeep: Color(0x75486656),
    shadowInset: Color(0x6B587464),
    rim: Color(0xD9FFFFFF),
    crease: Color(0x1F2F4A3C),
    ink: Color(0xFF101B16),
    inkSecondary: Color(0xFF34443C),
    inkTertiary: Color(0xFF43534A),
    quiet: Color(0xFF68786F),
    barStart: Color(0xFF4A5B52),
    barEnd: Color(0xFF2C3B33),
    domeLight: Color(0xFFFBFDFB),
    domeMid: Color(0xFFE3E9E3),
    domeDark: Color(0xFFCBD4CC),
    lamp: Color(0xFFFFC27A),
    moon1: Color(0xFFFBFDFB),
    moon2: Color(0xFFE3E9E3),
    pigment: Color(0xFF14694F),
    pigmentHi: Color(0xFF3FA685),
    pigmentDk: Color(0xFF0E5540),
    pigmentInk: Color(0xFF12644B),
    pigmentInkLit: Color(0xFF0E5540),
    onPigment: Color(0xFFFFFFFF),
  ),
  _Seed(
    dark: true,
    ground: Color(0xFF1C2723),
    faceStart: Color(0xFF26332E),
    faceEnd: Color(0xFF161F1C),
    wellStart: Color(0xFF131B18),
    wellEnd: Color(0xFF222D29),
    highlight: Color(0x12BEFFE1),
    shadow: Color(0x8C030A07),
    shadowDeep: Color(0x9E030A07),
    shadowInset: Color(0x99030A07),
    rim: Color(0x1AC8FFE6),
    crease: Color(0x59000000),
    ink: Color(0xFFEBF3EE),
    inkSecondary: Color(0xFFC1D0C8),
    inkTertiary: Color(0xFF95A79E),
    quiet: Color(0xFF7A8C83),
    barStart: Color(0xFFD1DED7),
    barEnd: Color(0xFFABBBB2),
    domeLight: Color(0xFF33413B),
    domeMid: Color(0xFF26322D),
    domeDark: Color(0xFF17201C),
    lamp: Color(0xFFFFB46A),
    moon1: Color(0xFFE4F3EC),
    moon2: Color(0xFF95B0A4),
    pigment: Color(0xFF62D2A9),
    pigmentHi: Color(0xFF93E5C6),
    pigmentDk: Color(0xFF49BD94),
    pigmentInk: Color(0xFF7DDCB9),
    pigmentInkLit: Color(0xFF7DDCB9),
    onPigment: Color(0xFF0F1B16),
  ),
);

/// Sand plaster and raw sienna: a hill town's wall in the sun. At night olive umber, the sienna lit to gold.
const _siena = _Palette(
  _Seed(
    dark: false,
    ground: Color(0xFFEBE4D3),
    faceStart: Color(0xFFF4EEE1),
    faceEnd: Color(0xFFDFD7C4),
    wellStart: Color(0xFFDAD1BD),
    wellEnd: Color(0xFFEEE8DA),
    highlight: Color(0xF2FFFFFF),
    shadow: Color(0x6180704C),
    shadowDeep: Color(0x756E5F3E),
    shadowInset: Color(0x6B80704C),
    rim: Color(0xD9FFFFFF),
    crease: Color(0x1F564A2C),
    ink: Color(0xFF1C170B),
    inkSecondary: Color(0xFF443C29),
    inkTertiary: Color(0xFF524934),
    quiet: Color(0xFF766C55),
    barStart: Color(0xFF585038),
    barEnd: Color(0xFF3B3421),
    domeLight: Color(0xFFFDFBF5),
    domeMid: Color(0xFFEBE4D3),
    domeDark: Color(0xFFD4CCB8),
    lamp: Color(0xFFFFD08A),
    moon1: Color(0xFFFDFBF5),
    moon2: Color(0xFFEBE4D3),
    pigment: Color(0xFF8F4F06),
    pigmentHi: Color(0xFFC98526),
    pigmentDk: Color(0xFF743E02),
    pigmentInk: Color(0xFF824703),
    pigmentInkLit: Color(0xFF743E02),
    onPigment: Color(0xFFFFFFFF),
  ),
  _Seed(
    dark: true,
    ground: Color(0xFF27231A),
    faceStart: Color(0xFF332E23),
    faceEnd: Color(0xFF1D1A12),
    wellStart: Color(0xFF181510),
    wellEnd: Color(0xFF2D291E),
    highlight: Color(0x12FFEDC0),
    shadow: Color(0x8C070501),
    shadowDeep: Color(0x9E070501),
    shadowInset: Color(0x99070501),
    rim: Color(0x1AFFF0CC),
    crease: Color(0x59000000),
    ink: Color(0xFFF3EEDF),
    inkSecondary: Color(0xFFD1CAB6),
    inkTertiary: Color(0xFFA9A28E),
    quiet: Color(0xFF8C8571),
    barStart: Color(0xFFDFD9C6),
    barEnd: Color(0xFFBAB39E),
    domeLight: Color(0xFF413B2E),
    domeMid: Color(0xFF312C21),
    domeDark: Color(0xFF1F1B13),
    lamp: Color(0xFFFFBE70),
    moon1: Color(0xFFF5EDD6),
    moon2: Color(0xFFB6AC8C),
    pigment: Color(0xFFE6B04A),
    pigmentHi: Color(0xFFF5CF85),
    pigmentDk: Color(0xFFD49A33),
    pigmentInk: Color(0xFFEDBE62),
    pigmentInkLit: Color(0xFFEDBE62),
    onPigment: Color(0xFF1C170B),
  ),
);

/// Rose-grey lime and Tyrian purple: a palace's wall. At night aubergine, the purple lit to orchid.
const _tyrian = _Palette(
  _Seed(
    dark: false,
    ground: Color(0xFFE9E3E8),
    faceStart: Color(0xFFF2EDF1),
    faceEnd: Color(0xFFDDD5DC),
    wellStart: Color(0xFFD9D1D8),
    wellEnd: Color(0xFFEDE7EC),
    highlight: Color(0xF2FFFFFF),
    shadow: Color(0x61745C76),
    shadowDeep: Color(0x75634C65),
    shadowInset: Color(0x6B745C76),
    rim: Color(0xD9FFFFFF),
    crease: Color(0x1F4F3A52),
    ink: Color(0xFF1A1019),
    inkSecondary: Color(0xFF443640),
    inkTertiary: Color(0xFF53454F),
    quiet: Color(0xFF786A75),
    barStart: Color(0xFF5A4B57),
    barEnd: Color(0xFF3B2E39),
    domeLight: Color(0xFFFDFBFD),
    domeMid: Color(0xFFE9E3E8),
    domeDark: Color(0xFFD3CBD2),
    lamp: Color(0xFFFFB98A),
    moon1: Color(0xFFFDFBFD),
    moon2: Color(0xFFE9E3E8),
    pigment: Color(0xFF7B1C72),
    pigmentHi: Color(0xFFB14FA8),
    pigmentDk: Color(0xFF62145B),
    pigmentInk: Color(0xFF7B1C72),
    pigmentInkLit: Color(0xFF62145B),
    onPigment: Color(0xFFFFFFFF),
  ),
  _Seed(
    dark: true,
    ground: Color(0xFF271F2B),
    faceStart: Color(0xFF332939),
    faceEnd: Color(0xFF1C161F),
    wellStart: Color(0xFF17121A),
    wellEnd: Color(0xFF2D2432),
    highlight: Color(0x12F0D2FF),
    shadow: Color(0x8C07030A),
    shadowDeep: Color(0x9E07030A),
    shadowInset: Color(0x9907030A),
    rim: Color(0x1AF0DCFF),
    crease: Color(0x59000000),
    ink: Color(0xFFF3ECF4),
    inkSecondary: Color(0xFFD3C7D6),
    inkTertiary: Color(0xFFABA0AF),
    quiet: Color(0xFF8E8393),
    barStart: Color(0xFFE0D6E3),
    barEnd: Color(0xFFBBAFBF),
    domeLight: Color(0xFF41364A),
    domeMid: Color(0xFF312838),
    domeDark: Color(0xFF1F1924),
    lamp: Color(0xFFFFAE7A),
    moon1: Color(0xFFF2E6F6),
    moon2: Color(0xFFAE9CB6),
    pigment: Color(0xFFDA8FD8),
    pigmentHi: Color(0xFFEDB9EB),
    pigmentDk: Color(0xFFC677C4),
    pigmentInk: Color(0xFFE3A4E1),
    pigmentInkLit: Color(0xFFE3A4E1),
    onPigment: Color(0xFF1A1019),
  ),
);

/// Line height in whole pixels. Flutter rounds a paragraph's height up, Blink keeps the fraction; asking for a hair
/// under the nearest whole pixel keeps a stack of text from drifting and keeps rules on whole pixels.
double _lh(double size, double px) => (px - .01) / size;

/// The type scale, Manrope alone. Every style is already right for the current width: `page` is 30 on a phone, 48 at 300
/// on a desktop. Sentence case everywhere; no tracked caps.
class NeumorphicTextTheme {
  NeumorphicTextTheme._(this.colors, this.desk, this.typeface);

  /// The inks used by the scale.
  final NeumorphicColors colors;

  /// Whether the display scale uses its desktop sizes.
  final bool desk;

  /// Families and scale shared by every text style.
  final NeumorphicTypeface typeface;

  /// Labels and axes, 12/16 at the default scale.
  TextStyle get micro => _t(12, 16, FontWeight.w600, colors.inkTertiary);

  /// Supporting words, 14/20.
  TextStyle get caption => _t(14, 20, FontWeight.w500, colors.inkTertiary);

  /// Component headings, 16/22 bold.
  TextStyle get title => _t(16, 22, FontWeight.w700, colors.ink);

  /// Reading text, 16/22.
  TextStyle get body => _t(16, 22, FontWeight.w500, colors.ink);

  /// A number in a card, 20/26.
  TextStyle get value => _t(20, 26, FontWeight.w600, colors.ink, -.01, true);

  /// The responsive page heading.
  TextStyle get page => desk
      ? _t(48, 52, FontWeight.w300, colors.ink, -.03, true)
      : _t(30, 36, FontWeight.w600, colors.ink, -.02, true);

  /// A prominent number, 48/52.
  TextStyle get figure => _t(48, 52, FontWeight.w300, colors.ink, -.03, true);

  /// Text at a component's own size, using the same family and scale.
  TextStyle text(
    double size,
    double lineHeight, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double tracking = 0,
  }) => _t(size, lineHeight, weight, color ?? colors.ink, tracking);

  TextStyle _t(
    double size,
    double px,
    FontWeight weight,
    Color color, [
    double tracking = 0,
    bool display = false,
  ]) => TextStyle(
    inherit: false,
    fontFamily: display ? typeface.display : typeface.text,
    package: display ? typeface.displayPackage : typeface.textPackage,
    fontSize: size,
    height: _lh(size, px),
    letterSpacing: size * tracking,
    fontWeight: weight,
    color: color,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );
}

/// Number-setting helpers shared by the design system's text styles.
extension NeumorphicTextStyle on TextStyle {
  /// Tabular figures: every number that aligns in a column. A figure standing alone stays proportional: Manrope's tabular
  /// 1 opens a gap.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
}

/// The look's timing: how long each kind of change takes, and the curves it eases on. Read it through
/// [NeumorphicMotion.of], which gives every duration as zero when the platform asks for reduced motion.
@immutable
class NeumorphicMotion {
  /// Creates a [NeumorphicMotion].
  const NeumorphicMotion({
    this.press = const Duration(milliseconds: 150),
    this.state = const Duration(milliseconds: 140),
    this.move = const Duration(milliseconds: 180),
    this.raise = const Duration(milliseconds: 220),
    this.travel = const Duration(milliseconds: 280),
    this.leave = const Duration(milliseconds: 120),
    this.enter = Curves.easeOutCubic,
    this.exit = Curves.easeInCubic,
    this.standard = Curves.easeInOutCubic,
  });

  /// A press going in or out.
  final Duration press;

  /// A state change: a switch's thumb, a check, a selected latch.
  final Duration state;

  /// Something moving within its part: a selection, a tab's crown.
  final Duration move;

  /// A surface rising: a sheet, a menu, a dialog.
  final Duration raise;

  /// A route's travel.
  final Duration travel;

  /// A surface leaving.
  final Duration leave;

  /// The curve of something arriving, leaving and moving.
  final Curve enter, exit, standard;

  /// Every duration zero: what Reduce Motion gets.
  NeumorphicMotion get still => const NeumorphicMotion(
    press: Duration.zero,
    state: Duration.zero,
    move: Duration.zero,
    raise: Duration.zero,
    travel: Duration.zero,
    leave: Duration.zero,
  );

  /// The motion in scope at [context]: all cuts under `MediaQuery.disableAnimationsOf`.
  static NeumorphicMotion of(BuildContext context) {
    final motion = NeumorphicTheme.of(context).motion;
    return (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
        ? motion.still
        : motion;
  }

  @override
  bool operator ==(Object other) =>
      other is NeumorphicMotion &&
      other.press == press &&
      other.state == state &&
      other.move == move &&
      other.raise == raise &&
      other.travel == travel &&
      other.leave == leave &&
      other.enter == enter &&
      other.exit == exit &&
      other.standard == standard;

  @override
  int get hashCode => Object.hash(
    press,
    state,
    move,
    raise,
    travel,
    leave,
    enter,
    exit,
    standard,
  );
}

/// What `NeumorphicTheme.of(context)` returns: a preset in one appearance, its type set for a width, and its motion.
/// Immutable, with [copyWith], [lerp], `==` and `debugFillProperties`, as Flutter's own theme data.
@immutable
class NeumorphicThemeData with Diagnosticable {
  NeumorphicThemeData._(
    this.id,
    this.colors,
    this.width, {
    this._highContrast,
    this._platformHighContrast = false,
    this._density,
    this.typeface = const NeumorphicTypeface(),
    this.elevation = const NeumorphicElevation(),
    this.buttonTheme = const NeumorphicStyle(),
    this.filledButtonTheme = const NeumorphicStyle(),
    this.textButtonTheme = const NeumorphicStyle(),
    this.iconButtonTheme = const NeumorphicStyle(),
    this.textFieldTheme = const NeumorphicStyle(),
    this.chipTheme = const NeumorphicStyle(),
    this.segmentedButtonTheme = const NeumorphicStyle(),
    this.checkboxTheme = const NeumorphicStyle(),
    this.radioTheme = const NeumorphicStyle(),
    this.switchTheme = const NeumorphicStyle(),
    this.sliderTheme = const NeumorphicStyle(),
    this.cardTheme = const NeumorphicStyle(),
    this.dialogTheme = const NeumorphicStyle(),
    this.sheetTheme = const NeumorphicStyle(),
    this.menuTheme = const NeumorphicStyle(),
    this.snackBarTheme = const NeumorphicStyle(),
    this.tooltipTheme = const NeumorphicStyle(),
    this.badgeTheme = const NeumorphicStyle(),
    this.avatarTheme = const NeumorphicStyle(),
    this.optionTheme = const NeumorphicStyle(),
    this.stepperTheme = const NeumorphicStyle(),
    this.datePickerTheme = const NeumorphicStyle(),
    this.timePickerTheme = const NeumorphicStyle(),
  }) : textTheme = NeumorphicTextTheme._(
         colors,
         width >= neumorphicDesktopBreakpoint,
         typeface,
       );

  /// Which preset this is (`porcelain`, `pompeii`, ...).
  final String id;

  /// The colours a page may read.
  final NeumorphicColors colors;

  /// The text styles, set for [width].
  final NeumorphicTextTheme textTheme;

  /// The window width the type is set for: 0 before a window says.
  final double width;

  /// Whether parts print a fine outline for people who need explicit boundaries: the app's setting when it gives one,
  /// otherwise the platform's (`MediaQuery.highContrastOf`). Without it the relief alone draws every edge.
  bool get highContrast => _highContrast ?? _platformHighContrast;
  final bool? _highContrast;
  final bool _platformHighContrast;

  /// The look's timing. Not a setting; [NeumorphicMotion.of] gives it with the platform's reduced motion applied.
  NeumorphicMotion get motion => const NeumorphicMotion();

  /// The look's corners.
  NeumorphicShapes get shapes => const NeumorphicShapes();

  /// How compact the controls stand: the app's density when it gives one, otherwise [NeumorphicDensity.adaptivePlatformDensity]:
  /// compact where a pointer drives the app, standard on touch. The touch target never shrinks.
  NeumorphicDensity get density =>
      _density ?? NeumorphicDensity.adaptivePlatformDensity;
  final NeumorphicDensity? _density;

  /// The theme-wide typeface settings.
  final NeumorphicTypeface typeface;

  /// The theme-wide elevation settings.
  final NeumorphicElevation elevation;

  /// State-resolved styling for every button, and the ordinary [NeumorphicButton]'s own.
  final NeumorphicStyle buttonTheme;

  /// State-resolved styling for [NeumorphicButton.filled] and the round act, over [buttonTheme].
  final NeumorphicStyle filledButtonTheme;

  /// State-resolved styling for [NeumorphicButton.text] and [NeumorphicLink], over [buttonTheme].
  final NeumorphicStyle textButtonTheme;

  /// State-resolved styling for iconButton parts.
  final NeumorphicStyle iconButtonTheme;

  /// State-resolved styling for textField parts.
  final NeumorphicStyle textFieldTheme;

  /// State-resolved styling for chip parts.
  final NeumorphicStyle chipTheme;

  /// State-resolved styling for segmentedButton parts.
  final NeumorphicStyle segmentedButtonTheme;

  /// State-resolved styling for checkbox parts.
  final NeumorphicStyle checkboxTheme;

  /// State-resolved styling for radio parts.
  final NeumorphicStyle radioTheme;

  /// State-resolved styling for switch parts.
  final NeumorphicStyle switchTheme;

  /// State-resolved styling for slider parts.
  final NeumorphicStyle sliderTheme;

  /// State-resolved styling for card parts.
  final NeumorphicStyle cardTheme;

  /// State-resolved styling for dialog parts.
  final NeumorphicStyle dialogTheme;

  /// State-resolved styling for sheet parts.
  final NeumorphicStyle sheetTheme;

  /// State-resolved styling for menu parts.
  final NeumorphicStyle menuTheme;

  /// State-resolved styling for snackBar parts.
  final NeumorphicStyle snackBarTheme;

  /// State-resolved styling for tooltip parts.
  final NeumorphicStyle tooltipTheme;

  /// State-resolved styling for badge parts.
  final NeumorphicStyle badgeTheme;

  /// State-resolved styling for avatar parts.
  final NeumorphicStyle avatarTheme;

  /// State-resolved styling for option parts.
  final NeumorphicStyle optionTheme;

  /// State-resolved styling for stepper parts.
  final NeumorphicStyle stepperTheme;

  /// State-resolved styling for datePicker parts.
  final NeumorphicStyle datePickerTheme;

  /// State-resolved styling for timePicker parts.
  final NeumorphicStyle timePickerTheme;

  /// What's in scope at [context]; `context.neumorphicTheme` is the same.
  static NeumorphicThemeData of(BuildContext context) =>
      NeumorphicTheme.of(context);

  /// The preset ids, the default first. Each is designed in light and dark.
  static const List<String> presets = <String>[
    'porcelain',
    'pompeii',
    'verona',
    'siena',
    'tyrian',
  ];

  static const Map<String, _Palette> _palettes = {
    'porcelain': _plaster,
    'pompeii': _pompeii,
    'verona': _verona,
    'siena': _siena,
    'tyrian': _tyrian,
  };
  static final Map<(String, Brightness), NeumorphicThemeData> _cache = {};

  /// The theme for preset [id] in [brightness]; an unknown id throws. The theme file's call.
  static NeumorphicThemeData preset(String id, Brightness brightness) {
    final palette = _palettes[id];
    if (palette == null) {
      throw ArgumentError.value(
        id,
        'id',
        'not a Neumorphism preset (${presets.join(', ')})',
      );
    }
    return _cache[(id, brightness)] ??= NeumorphicThemeData._(
      id,
      (brightness == Brightness.dark ? palette.night : palette.day).colors,
      0,
    );
  }

  /// Cool porcelain and ultramarine, the concept's own: the default.
  factory NeumorphicThemeData.porcelain([
    Brightness brightness = Brightness.light,
  ]) => preset('porcelain', brightness);

  /// Warm limestone and cinnabar.
  factory NeumorphicThemeData.pompeii([
    Brightness brightness = Brightness.light,
  ]) => preset('pompeii', brightness);

  /// Green-grey and malachite.
  factory NeumorphicThemeData.verona([
    Brightness brightness = Brightness.light,
  ]) => preset('verona', brightness);

  /// Ochre and burnt umber.
  factory NeumorphicThemeData.siena([
    Brightness brightness = Brightness.light,
  ]) => preset('siena', brightness);

  /// Mauve-grey and purple.
  factory NeumorphicThemeData.tyrian([
    Brightness brightness = Brightness.light,
  ]) => preset('tyrian', brightness);

  /// Derives the material from an app's ground and pigment. Colors are adjusted
  /// when needed: words hold 4.5:1, and printed resting edges hold 4:1 on every
  /// face and well, including the selected wash. Transparent input is composited
  /// before contrast is measured. The five named presets remain unchanged.
  ///
  /// ```dart
  /// final theme = NeumorphicThemeData.from(
  ///   ground: const Color(0xFFE8E3ED),
  ///   pigment: const Color(0xFF7542A3),
  /// );
  /// ```
  factory NeumorphicThemeData.from({
    required Color ground,
    required Color pigment,
    Brightness brightness = Brightness.light,
  }) => NeumorphicThemeData._(
    'custom',
    _brandSeed(ground, pigment, brightness).colors,
    0,
  );

  /// A copy with the given fields replaced. [highContrast] and [density] set here win over the platform's.
  NeumorphicThemeData copyWith({
    String? id,
    NeumorphicColors? colors,
    bool? highContrast,
    NeumorphicDensity? density,
    NeumorphicTypeface? typeface,
    NeumorphicElevation? elevation,
    NeumorphicStyle? buttonTheme,
    NeumorphicStyle? filledButtonTheme,
    NeumorphicStyle? textButtonTheme,
    NeumorphicStyle? iconButtonTheme,
    NeumorphicStyle? textFieldTheme,
    NeumorphicStyle? chipTheme,
    NeumorphicStyle? segmentedButtonTheme,
    NeumorphicStyle? checkboxTheme,
    NeumorphicStyle? radioTheme,
    NeumorphicStyle? switchTheme,
    NeumorphicStyle? sliderTheme,
    NeumorphicStyle? cardTheme,
    NeumorphicStyle? dialogTheme,
    NeumorphicStyle? sheetTheme,
    NeumorphicStyle? menuTheme,
    NeumorphicStyle? snackBarTheme,
    NeumorphicStyle? tooltipTheme,
    NeumorphicStyle? badgeTheme,
    NeumorphicStyle? avatarTheme,
    NeumorphicStyle? optionTheme,
    NeumorphicStyle? stepperTheme,
    NeumorphicStyle? datePickerTheme,
    NeumorphicStyle? timePickerTheme,
  }) => _copy(
    id: id,
    colors: colors,
    highContrast: highContrast,
    density: density,
    typeface: typeface,
    elevation: elevation,
    buttonTheme: buttonTheme,
    filledButtonTheme: filledButtonTheme,
    textButtonTheme: textButtonTheme,
    iconButtonTheme: iconButtonTheme,
    textFieldTheme: textFieldTheme,
    chipTheme: chipTheme,
    segmentedButtonTheme: segmentedButtonTheme,
    checkboxTheme: checkboxTheme,
    radioTheme: radioTheme,
    switchTheme: switchTheme,
    sliderTheme: sliderTheme,
    cardTheme: cardTheme,
    dialogTheme: dialogTheme,
    sheetTheme: sheetTheme,
    menuTheme: menuTheme,
    snackBarTheme: snackBarTheme,
    tooltipTheme: tooltipTheme,
    badgeTheme: badgeTheme,
    avatarTheme: avatarTheme,
    optionTheme: optionTheme,
    stepperTheme: stepperTheme,
    datePickerTheme: datePickerTheme,
    timePickerTheme: timePickerTheme,
  );

  NeumorphicThemeData _copy({
    String? id,
    NeumorphicColors? colors,
    bool? highContrast,
    NeumorphicDensity? density,
    NeumorphicTypeface? typeface,
    NeumorphicElevation? elevation,
    NeumorphicStyle? buttonTheme,
    NeumorphicStyle? filledButtonTheme,
    NeumorphicStyle? textButtonTheme,
    NeumorphicStyle? iconButtonTheme,
    NeumorphicStyle? textFieldTheme,
    NeumorphicStyle? chipTheme,
    NeumorphicStyle? segmentedButtonTheme,
    NeumorphicStyle? checkboxTheme,
    NeumorphicStyle? radioTheme,
    NeumorphicStyle? switchTheme,
    NeumorphicStyle? sliderTheme,
    NeumorphicStyle? cardTheme,
    NeumorphicStyle? dialogTheme,
    NeumorphicStyle? sheetTheme,
    NeumorphicStyle? menuTheme,
    NeumorphicStyle? snackBarTheme,
    NeumorphicStyle? tooltipTheme,
    NeumorphicStyle? badgeTheme,
    NeumorphicStyle? avatarTheme,
    NeumorphicStyle? optionTheme,
    NeumorphicStyle? stepperTheme,
    NeumorphicStyle? datePickerTheme,
    NeumorphicStyle? timePickerTheme,
    double? width,
    bool? platformHighContrast,
  }) => NeumorphicThemeData._(
    id ?? this.id,
    colors ?? this.colors,
    width ?? this.width,
    highContrast: highContrast ?? _highContrast,
    platformHighContrast: platformHighContrast ?? _platformHighContrast,
    density: density ?? _density,
    typeface: typeface ?? this.typeface,
    elevation: elevation ?? this.elevation,
    buttonTheme: buttonTheme ?? this.buttonTheme,
    filledButtonTheme: filledButtonTheme ?? this.filledButtonTheme,
    textButtonTheme: textButtonTheme ?? this.textButtonTheme,
    iconButtonTheme: iconButtonTheme ?? this.iconButtonTheme,
    textFieldTheme: textFieldTheme ?? this.textFieldTheme,
    chipTheme: chipTheme ?? this.chipTheme,
    segmentedButtonTheme: segmentedButtonTheme ?? this.segmentedButtonTheme,
    checkboxTheme: checkboxTheme ?? this.checkboxTheme,
    radioTheme: radioTheme ?? this.radioTheme,
    switchTheme: switchTheme ?? this.switchTheme,
    sliderTheme: sliderTheme ?? this.sliderTheme,
    cardTheme: cardTheme ?? this.cardTheme,
    dialogTheme: dialogTheme ?? this.dialogTheme,
    sheetTheme: sheetTheme ?? this.sheetTheme,
    menuTheme: menuTheme ?? this.menuTheme,
    snackBarTheme: snackBarTheme ?? this.snackBarTheme,
    tooltipTheme: tooltipTheme ?? this.tooltipTheme,
    badgeTheme: badgeTheme ?? this.badgeTheme,
    avatarTheme: avatarTheme ?? this.avatarTheme,
    optionTheme: optionTheme ?? this.optionTheme,
    stepperTheme: stepperTheme ?? this.stepperTheme,
    datePickerTheme: datePickerTheme ?? this.datePickerTheme,
    timePickerTheme: timePickerTheme ?? this.timePickerTheme,
  );

  /// Blends colors, geometry, type, and every state-resolved component slot.
  static NeumorphicThemeData lerp(
    NeumorphicThemeData a,
    NeumorphicThemeData b,
    double t,
  ) {
    if (a == b || t == 0) return a;
    if (t == 1) return b;
    return NeumorphicThemeData._(
      t < .5 ? a.id : b.id,
      NeumorphicColors.lerp(a.colors, b.colors, t),
      a.width + (b.width - a.width) * t,
      highContrast: t < .5 ? a._highContrast : b._highContrast,
      platformHighContrast: t < .5
          ? a._platformHighContrast
          : b._platformHighContrast,
      density: a._density == null && b._density == null
          ? null
          : NeumorphicDensity.lerp(a.density, b.density, t),
      typeface: NeumorphicTypeface.lerp(a.typeface, b.typeface, t),
      elevation: NeumorphicElevation.lerp(a.elevation, b.elevation, t),
      buttonTheme: NeumorphicStyle.lerp(a.buttonTheme, b.buttonTheme, t)!,
      filledButtonTheme: NeumorphicStyle.lerp(
        a.filledButtonTheme,
        b.filledButtonTheme,
        t,
      )!,
      textButtonTheme: NeumorphicStyle.lerp(
        a.textButtonTheme,
        b.textButtonTheme,
        t,
      )!,
      iconButtonTheme: NeumorphicStyle.lerp(
        a.iconButtonTheme,
        b.iconButtonTheme,
        t,
      )!,
      textFieldTheme: NeumorphicStyle.lerp(
        a.textFieldTheme,
        b.textFieldTheme,
        t,
      )!,
      chipTheme: NeumorphicStyle.lerp(a.chipTheme, b.chipTheme, t)!,
      segmentedButtonTheme: NeumorphicStyle.lerp(
        a.segmentedButtonTheme,
        b.segmentedButtonTheme,
        t,
      )!,
      checkboxTheme: NeumorphicStyle.lerp(a.checkboxTheme, b.checkboxTheme, t)!,
      radioTheme: NeumorphicStyle.lerp(a.radioTheme, b.radioTheme, t)!,
      switchTheme: NeumorphicStyle.lerp(a.switchTheme, b.switchTheme, t)!,
      sliderTheme: NeumorphicStyle.lerp(a.sliderTheme, b.sliderTheme, t)!,
      cardTheme: NeumorphicStyle.lerp(a.cardTheme, b.cardTheme, t)!,
      dialogTheme: NeumorphicStyle.lerp(a.dialogTheme, b.dialogTheme, t)!,
      sheetTheme: NeumorphicStyle.lerp(a.sheetTheme, b.sheetTheme, t)!,
      menuTheme: NeumorphicStyle.lerp(a.menuTheme, b.menuTheme, t)!,
      snackBarTheme: NeumorphicStyle.lerp(a.snackBarTheme, b.snackBarTheme, t)!,
      tooltipTheme: NeumorphicStyle.lerp(a.tooltipTheme, b.tooltipTheme, t)!,
      badgeTheme: NeumorphicStyle.lerp(a.badgeTheme, b.badgeTheme, t)!,
      avatarTheme: NeumorphicStyle.lerp(a.avatarTheme, b.avatarTheme, t)!,
      optionTheme: NeumorphicStyle.lerp(a.optionTheme, b.optionTheme, t)!,
      stepperTheme: NeumorphicStyle.lerp(a.stepperTheme, b.stepperTheme, t)!,
      datePickerTheme: NeumorphicStyle.lerp(
        a.datePickerTheme,
        b.datePickerTheme,
        t,
      )!,
      timePickerTheme: NeumorphicStyle.lerp(
        a.timePickerTheme,
        b.timePickerTheme,
        t,
      )!,
    );
  }

  final Map<(double, bool), NeumorphicThemeData> _windows = {};

  /// The same theme, including component overrides, set for [width].
  NeumorphicThemeData atWidth(double width) =>
      _atWindow(width, _platformHighContrast);

  NeumorphicThemeData _atWindow(double width, bool platformHighContrast) {
    if (width == this.width && platformHighContrast == _platformHighContrast) {
      return this;
    }
    if (_windows.length > 8) _windows.clear();
    return _windows[(width, platformHighContrast)] ??= _copy(
      width: width,
      platformHighContrast: platformHighContrast,
    );
  }

  /// The stubs' page title and body text.
  TextStyle get h1 => textTheme.page;

  /// The default body text for content under this theme.
  TextStyle get body => textTheme.body;

  /// True from 1024 wide up: the 12-column layout.
  bool get desk => width >= neumorphicDesktopBreakpoint;

  /// The responsive size class at this width.
  NeumorphicWindow get window => NeumorphicWindow.forWidth(width);

  /// Whether the current palette uses the dark appearance.
  bool get dark => colors.dark;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NeumorphicThemeData &&
          other.id == id &&
          other.colors == colors &&
          other.width == width &&
          other._highContrast == _highContrast &&
          other._platformHighContrast == _platformHighContrast &&
          other._density == _density &&
          other.typeface == typeface &&
          other.elevation == elevation &&
          other.buttonTheme == buttonTheme &&
          other.filledButtonTheme == filledButtonTheme &&
          other.textButtonTheme == textButtonTheme &&
          other.iconButtonTheme == iconButtonTheme &&
          other.textFieldTheme == textFieldTheme &&
          other.chipTheme == chipTheme &&
          other.segmentedButtonTheme == segmentedButtonTheme &&
          other.checkboxTheme == checkboxTheme &&
          other.radioTheme == radioTheme &&
          other.switchTheme == switchTheme &&
          other.sliderTheme == sliderTheme &&
          other.cardTheme == cardTheme &&
          other.dialogTheme == dialogTheme &&
          other.sheetTheme == sheetTheme &&
          other.menuTheme == menuTheme &&
          other.snackBarTheme == snackBarTheme &&
          other.tooltipTheme == tooltipTheme &&
          other.badgeTheme == badgeTheme &&
          other.avatarTheme == avatarTheme &&
          other.optionTheme == optionTheme &&
          other.stepperTheme == stepperTheme &&
          other.datePickerTheme == datePickerTheme &&
          other.timePickerTheme == timePickerTheme;

  @override
  int get hashCode => Object.hashAll([
    id,
    colors,
    width,
    _highContrast,
    _platformHighContrast,
    _density,
    typeface,
    elevation,
    buttonTheme,
    filledButtonTheme,
    textButtonTheme,
    iconButtonTheme,
    textFieldTheme,
    chipTheme,
    segmentedButtonTheme,
    checkboxTheme,
    radioTheme,
    switchTheme,
    sliderTheme,
    cardTheme,
    dialogTheme,
    sheetTheme,
    menuTheme,
    snackBarTheme,
    tooltipTheme,
    badgeTheme,
    avatarTheme,
    optionTheme,
    stepperTheme,
    datePickerTheme,
    timePickerTheme,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(DiagnosticsProperty<bool>('dark', dark))
      ..add(DoubleProperty('width', width))
      ..add(
        DiagnosticsProperty<bool>(
          'highContrast',
          _highContrast,
          defaultValue: null,
        ),
      )
      ..add(ColorProperty('ground', colors.ground))
      ..add(ColorProperty('ink', colors.ink))
      ..add(
        DiagnosticsProperty<NeumorphicDensity>(
          'density',
          _density,
          defaultValue: null,
        ),
      )
      ..add(DiagnosticsProperty<NeumorphicTypeface>('typeface', typeface))
      ..add(DiagnosticsProperty<NeumorphicElevation>('elevation', elevation))
      ..add(DiagnosticsProperty<NeumorphicStyle>('buttonTheme', buttonTheme))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'filledButtonTheme',
          filledButtonTheme,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'textButtonTheme',
          textButtonTheme,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'iconButtonTheme',
          iconButtonTheme,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>('textFieldTheme', textFieldTheme),
      )
      ..add(DiagnosticsProperty<NeumorphicStyle>('chipTheme', chipTheme))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'segmentedButtonTheme',
          segmentedButtonTheme,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>('checkboxTheme', checkboxTheme),
      )
      ..add(DiagnosticsProperty<NeumorphicStyle>('radioTheme', radioTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('switchTheme', switchTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('sliderTheme', sliderTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('cardTheme', cardTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('dialogTheme', dialogTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('sheetTheme', sheetTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('menuTheme', menuTheme))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>('snackBarTheme', snackBarTheme),
      )
      ..add(DiagnosticsProperty<NeumorphicStyle>('tooltipTheme', tooltipTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('badgeTheme', badgeTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('avatarTheme', avatarTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('optionTheme', optionTheme))
      ..add(DiagnosticsProperty<NeumorphicStyle>('stepperTheme', stepperTheme))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'datePickerTheme',
          datePickerTheme,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'timePickerTheme',
          timePickerTheme,
        ),
      );
  }
}

/// Puts Neumorphism in scope: the one root widget, set in any app's `builder:`, under `MaterialApp`, `CupertinoApp` or
/// `WidgetsApp`. A nested one restyles a subtree. Everything below reads [of]; what the look builds on from Flutter's
/// widgets (a text field, a scroll bar) is dressed here and none of it shows.
///
/// ```dart
/// NeumorphicTheme(data: NeumorphicThemeData.porcelain(), child: home)
/// ```
class NeumorphicTheme extends InheritedTheme {
  /// Creates a [NeumorphicTheme].
  NeumorphicTheme({super.key, required this.data, required Widget child})
    : super(
        child: _Dressing(data: data, child: child),
      );

  /// The theme in scope below.
  final NeumorphicThemeData data;

  /// The theme in scope at [context], its type set for the window's width. Asserts when there is none.
  static NeumorphicThemeData of(BuildContext context) {
    final theme = maybeOf(context);
    assert(
      theme != null,
      'No Neumorphism theme in scope: put NeumorphicTheme(data:, child:) in the app\'s builder:.',
    );
    return theme!;
  }

  /// The theme in scope at [context], or null.
  static NeumorphicThemeData? maybeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NeumorphicTheme>();
    if (scope == null) return null;
    final data = scope.data;
    return data._atWindow(
      MediaQuery.maybeSizeOf(context)?.width ?? data.width,
      MediaQuery.maybeHighContrastOf(context) ?? false,
    );
  }

  @override
  Widget wrap(BuildContext context, Widget child) =>
      NeumorphicTheme(data: data, child: child);

  @override
  bool updateShouldNotify(NeumorphicTheme oldWidget) => data != oldWidget.data;
}

/// A theme that eases to a new [data] over [duration], as `AnimatedTheme` does.
class AnimatedNeumorphicTheme extends ImplicitlyAnimatedWidget {
  /// Creates an [AnimatedNeumorphicTheme].
  const AnimatedNeumorphicTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to ease to.
  final NeumorphicThemeData data;

  /// What stands under it.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedNeumorphicTheme> createState() =>
      _AnimatedNeumorphicThemeState();
}

class _AnimatedNeumorphicThemeState
    extends AnimatedWidgetBaseState<AnimatedNeumorphicTheme> {
  _ThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (dynamic value) => _ThemeTween(begin: value as NeumorphicThemeData),
    ) as _ThemeTween?;
  }

  @override
  Widget build(BuildContext context) =>
      NeumorphicTheme(data: _data!.evaluate(animation), child: widget.child);
}

class _ThemeTween extends Tween<NeumorphicThemeData> {
  _ThemeTween({super.begin});

  @override
  NeumorphicThemeData lerp(double t) =>
      NeumorphicThemeData.lerp(begin!, end!, t);
}

/// What Neumorphism builds on from Flutter's widgets, dressed in its tokens: the text cursor and selection, no ink, no
/// splash. It is private; nothing of it is in the look's API.
class _Dressing extends StatelessWidget {
  const _Dressing({required this.data, required this.child});
  final NeumorphicThemeData data;
  final Widget child;

  static (NeumorphicColors, TargetPlatform, NeumorphicTypeface, ThemeData)?
  _last;

  static ThemeData _bridge(NeumorphicThemeData data) {
    final c = data.colors;
    final last = _last;
    final platform = defaultTargetPlatform;
    if (last != null &&
        last.$1 == c &&
        last.$2 == platform &&
        last.$3 == data.typeface) {
      return last.$4;
    }
    final theme = ThemeData(
      platform: platform,
      useMaterial3: true,
      brightness: c.dark ? Brightness.dark : Brightness.light,
      // Pinned, as the look's own parts are: Flutter's defaults are compact and shrink-wrapped on desktops and the web
      // opened there, which would move the Material pieces the look builds on (the editable, a scrollbar).
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      fontFamily: data.typeface.textPackage == null
          ? data.typeface.text
          : 'packages/${data.typeface.textPackage}/${data.typeface.text}',
      scaffoldBackgroundColor: c.ground,
      canvasColor: c.ground,
      colorScheme: ColorScheme(
        brightness: c.dark ? Brightness.dark : Brightness.light,
        primary: c.pigment,
        onPrimary: c.onPigment,
        secondary: c.inkSecondary,
        onSecondary: c.ground,
        error: c.pigment,
        onError: c.onPigment,
        surface: c.faceStart,
        onSurface: c.ink,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.ink,
        selectionColor: c.quiet.withValues(alpha: .45),
      ),
    );
    _last = (c, platform, data.typeface, theme);
    return theme;
  }

  @override
  Widget build(BuildContext context) {
    Widget under = child;
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      // A Localizations sets the reading direction from its locale's words: the app's own direction (an RTL app, a
      // gallery set right to left) is put back under it, or every page below reads left to right.
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    return Theme(
      data: _bridge(data),
      child: DefaultTextStyle(
        style: data.textTheme.body,
        child: IconTheme(
          data: IconThemeData(color: data.colors.ink),
          child: under,
        ),
      ),
    );
  }
}

/// `context.neumorphicTheme`: the theme in scope.
extension NeumorphicThemeContext on BuildContext {
  /// The nearest inherited Neumorphic theme.
  NeumorphicThemeData get neumorphicTheme => NeumorphicTheme.of(this);
}
