// Retro Desktop's tokens, every one from the concept's style.css. `RetroDesktopTheme.of(context)` is the only way in. Greys are the
// machine, white wells are your content, the highlight means the act and now, and nothing else is coloured.
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';
import 'fonts.dart';
import 'shapes.dart';
import 'component_themes.dart';
import 'behavior.dart';

/// The width where the phone's stack of windows becomes the 12-column tiled desktop.
const double retroDesktopDeskWidth = 1024;

/// The look's colours by role: the machine's greys and bevels, the paper, the text, the highlight, and the inks the
/// period's pictures draw with.
@immutable
class RetroDesktopColors {
  /// Derives the machine, paper and highlight roles from an opaque [primary], over [surface] when given; the
  /// pictures' inks keep the classic preset's.
  factory RetroDesktopColors.from({
    required Color primary,
    required Brightness brightness,
    Color? surface,
  }) => _retroDesktopColorsFrom(
    primary: primary,
    brightness: brightness,
    surface: surface,
  );

  /// Creates a [RetroDesktopColors].
  RetroDesktopColors({
    required this.dark,
    required this.desktop,
    required this.desktopThreadLight,
    required this.desktopThreadDark,
    required this.desktopGlow,
    required this.platinum,
    required this.platinumLight,
    required this.platinumDark,
    required this.bevelLight,
    required this.bevelDark,
    required this.bevelDarker,
    required this.outline,
    required this.control,
    required this.controlFace,
    required this.paper,
    required this.paperDim,
    required this.divider,
    required this.text,
    required this.textSecondary,
    required this.textTertiary,
    required this.highlight,
    required this.highlightDark,
    required this.highlightMid,
    required this.highlightContainer,
    required this.onHighlight,
    required this.highlightFaceTop,
    required this.highlightFaceMiddle,
    required this.highlightFaceBottom,
    required this.thumbTop,
    required this.thumbBottom,
    required this.hatch,
    required this.shade,
    required this.glow,
    required this.markLabel,
    required this.iconPage,
    required this.iconFold,
    required this.iconLine,
    required this.titleBoxDark,
    required this.titleBoxLight,
    required this.binderRingLight,
    required this.binderRingDark,
    required this.pixelOutline,
    required List<Color> tones,
    required this.illustration,
  }) : tones = List.unmodifiable(tones);

  /// Whether these are the night colours.
  final bool dark;

  /// The desktop: its ground and the weave's two threads; [desktopGlow] is a lighter ground for a host that marks a
  /// place on the desk (the look's own desk is flat: nothing glows).
  final Color desktop, desktopThreadLight, desktopThreadDark, desktopGlow;

  /// The machine: [platinum] for window bodies, [platinumLight] for raised faces, [platinumDark] for pressed ones.
  final Color platinum, platinumLight, platinumDark;

  /// Bevels: [bevelLight] on the top and left, [bevelDark] on the bottom and right, [bevelDarker] the deeper shade of
  /// ridges and grips.
  final Color bevelLight, bevelDark, bevelDarker;

  /// [outline] frames a window. [control] outlines a control: a token of its own, so night can lift it off the
  /// graphite. [controlFace] fills Chisel's checkbox and radio wells: the paper, as a field's, so a well reads as one
  /// by night too.
  final Color outline, control, controlFace;

  /// Your content: [paper] for wells, fields and the page of a document, [paperDim] for a dimmer paper beside it,
  /// [divider] for the rules between rows.
  final Color paper, paperDim, divider;

  /// Words and data: [text], then [textSecondary] and [textTertiary] for what reads after it.
  final Color text, textSecondary, textTertiary;

  /// The highlight means one thing: the act and now.
  final Color highlight,
      highlightDark,
      highlightMid,
      highlightContainer,
      onHighlight;

  /// The default button's face, the scroll thumb's face.
  final Color highlightFaceTop,
      highlightFaceMiddle,
      highlightFaceBottom,
      thumbTop,
      thumbBottom;

  /// The ink hatch of a data bar; the colour of window shadows; the lamp's glow at night (nothing by day).
  final Color hatch, shade, glow;

  /// The ground under a desktop mark's name.
  final Color markLabel;

  /// A document icon's page and fold, and the lines on it.
  final Color iconPage, iconFold, iconLine;

  /// A title bar box's face, from dark corner to light; a binder ring's face.
  final Color titleBoxDark, titleBoxLight, binderRingLight, binderRingDark;

  /// The ink line round a pixel silhouette.
  final Color pixelOutline;

  /// Flat illustration tones, from dry to wet; [chartTones] supplies data inks.
  final List<Color> tones;

  /// Five data inks derived from the highlight, readable on plot and panel grounds.
  ///
  /// Presets and derived palettes keep series at least 20 CIELAB units apart.
  /// Matching dash and hatch patterns also distinguish series without colour.
  /// Arbitrary replacement grounds retain the best available
  /// contrast when no candidate can meet both backgrounds.
  List<Color> get chartTones {
    final grounds = [
      paper,
      paperDim,
      platinum,
      platinumLight,
      platinumDark,
      highlightContainer,
    ];
    double contrast(Color value, Color ground) {
      final a = value.computeLuminance(), b = ground.computeLuminance();
      return (a > b ? a + .05 : b + .05) / (a > b ? b + .05 : a + .05);
    }

    double score(Color value) => grounds
        .map((ground) => contrast(value, ground))
        .reduce((a, b) => a < b ? a : b);
    Color readable(Color seed) {
      var best = seed;
      var bestScore = score(seed);
      if (bestScore >= 3) return seed;
      for (final target in [
        text,
        const Color(0xff000000),
        const Color(0xffffffff),
      ]) {
        for (var step = 1; step <= 100; step++) {
          final value = Color.lerp(seed, target, step / 100)!;
          final candidate = score(value);
          if (candidate >= 3) return value;
          if (candidate > bestScore) {
            best = value;
            bestScore = candidate;
          }
        }
      }
      return best;
    }

    final hue = HSLColor.fromColor(highlight).hue;
    return List.unmodifiable([
      for (var index = 0; index < 5; index++)
        readable(
          HSLColor.fromAHSL(
            1,
            (hue + index * 72) % 360,
            dark ? .65 : .75,
            dark ? .7 : .32,
          ).toColor(),
        ),
    ]);
  }

  /// The inks the pixel sky, its weather and what stands under it draw with.
  final RetroDesktopIllustrationColors illustration;

  /// The same palette with named colours replaced.
  RetroDesktopColors copyWith({
    bool? dark,
    Color? desktop,
    Color? desktopThreadLight,
    Color? desktopThreadDark,
    Color? desktopGlow,
    Color? platinum,
    Color? platinumLight,
    Color? platinumDark,
    Color? bevelLight,
    Color? bevelDark,
    Color? bevelDarker,
    Color? outline,
    Color? control,
    Color? controlFace,
    Color? paper,
    Color? paperDim,
    Color? divider,
    Color? text,
    Color? textSecondary,
    Color? textTertiary,
    Color? highlight,
    Color? highlightDark,
    Color? highlightMid,
    Color? highlightContainer,
    Color? onHighlight,
    Color? highlightFaceTop,
    Color? highlightFaceMiddle,
    Color? highlightFaceBottom,
    Color? thumbTop,
    Color? thumbBottom,
    Color? hatch,
    Color? shade,
    Color? glow,
    Color? markLabel,
    Color? iconPage,
    Color? iconFold,
    Color? iconLine,
    Color? titleBoxDark,
    Color? titleBoxLight,
    Color? binderRingLight,
    Color? binderRingDark,
    Color? pixelOutline,
    List<Color>? tones,
    RetroDesktopIllustrationColors? illustration,
  }) => RetroDesktopColors(
    dark: dark ?? this.dark,
    desktop: desktop ?? this.desktop,
    desktopThreadLight: desktopThreadLight ?? this.desktopThreadLight,
    desktopThreadDark: desktopThreadDark ?? this.desktopThreadDark,
    desktopGlow: desktopGlow ?? this.desktopGlow,
    platinum: platinum ?? this.platinum,
    platinumLight: platinumLight ?? this.platinumLight,
    platinumDark: platinumDark ?? this.platinumDark,
    bevelLight: bevelLight ?? this.bevelLight,
    bevelDark: bevelDark ?? this.bevelDark,
    bevelDarker: bevelDarker ?? this.bevelDarker,
    outline: outline ?? this.outline,
    control: control ?? this.control,
    controlFace: controlFace ?? this.controlFace,
    paper: paper ?? this.paper,
    paperDim: paperDim ?? this.paperDim,
    divider: divider ?? this.divider,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    highlight: highlight ?? this.highlight,
    highlightDark: highlightDark ?? this.highlightDark,
    highlightMid: highlightMid ?? this.highlightMid,
    highlightContainer: highlightContainer ?? this.highlightContainer,
    onHighlight: onHighlight ?? this.onHighlight,
    highlightFaceTop: highlightFaceTop ?? this.highlightFaceTop,
    highlightFaceMiddle: highlightFaceMiddle ?? this.highlightFaceMiddle,
    highlightFaceBottom: highlightFaceBottom ?? this.highlightFaceBottom,
    thumbTop: thumbTop ?? this.thumbTop,
    thumbBottom: thumbBottom ?? this.thumbBottom,
    hatch: hatch ?? this.hatch,
    shade: shade ?? this.shade,
    glow: glow ?? this.glow,
    markLabel: markLabel ?? this.markLabel,
    iconPage: iconPage ?? this.iconPage,
    iconFold: iconFold ?? this.iconFold,
    iconLine: iconLine ?? this.iconLine,
    titleBoxDark: titleBoxDark ?? this.titleBoxDark,
    titleBoxLight: titleBoxLight ?? this.titleBoxLight,
    binderRingLight: binderRingLight ?? this.binderRingLight,
    binderRingDark: binderRingDark ?? this.binderRingDark,
    pixelOutline: pixelOutline ?? this.pixelOutline,
    tones: tones ?? this.tones,
    illustration: illustration ?? this.illustration,
  );

  /// Interpolates all palette channels and artwork colours.
  static RetroDesktopColors lerp(
    RetroDesktopColors a,
    RetroDesktopColors b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    List<Color> mix(List<Color> x, List<Color> y) => [
      for (var i = 0; i < (x.length > y.length ? x.length : y.length); i++)
        Color.lerp(i < x.length ? x[i] : null, i < y.length ? y[i] : null, t)!,
    ];
    return RetroDesktopColors(
      dark: t < .5 ? a.dark : b.dark,
      desktop: Color.lerp(a.desktop, b.desktop, t)!,
      desktopThreadLight: Color.lerp(
        a.desktopThreadLight,
        b.desktopThreadLight,
        t,
      )!,
      desktopThreadDark: Color.lerp(
        a.desktopThreadDark,
        b.desktopThreadDark,
        t,
      )!,
      desktopGlow: Color.lerp(a.desktopGlow, b.desktopGlow, t)!,
      platinum: Color.lerp(a.platinum, b.platinum, t)!,
      platinumLight: Color.lerp(a.platinumLight, b.platinumLight, t)!,
      platinumDark: Color.lerp(a.platinumDark, b.platinumDark, t)!,
      bevelLight: Color.lerp(a.bevelLight, b.bevelLight, t)!,
      bevelDark: Color.lerp(a.bevelDark, b.bevelDark, t)!,
      bevelDarker: Color.lerp(a.bevelDarker, b.bevelDarker, t)!,
      outline: Color.lerp(a.outline, b.outline, t)!,
      control: Color.lerp(a.control, b.control, t)!,
      controlFace: Color.lerp(a.controlFace, b.controlFace, t)!,
      paper: Color.lerp(a.paper, b.paper, t)!,
      paperDim: Color.lerp(a.paperDim, b.paperDim, t)!,
      divider: Color.lerp(a.divider, b.divider, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
      highlight: Color.lerp(a.highlight, b.highlight, t)!,
      highlightDark: Color.lerp(a.highlightDark, b.highlightDark, t)!,
      highlightMid: Color.lerp(a.highlightMid, b.highlightMid, t)!,
      highlightContainer: Color.lerp(
        a.highlightContainer,
        b.highlightContainer,
        t,
      )!,
      onHighlight: Color.lerp(a.onHighlight, b.onHighlight, t)!,
      highlightFaceTop: Color.lerp(a.highlightFaceTop, b.highlightFaceTop, t)!,
      highlightFaceMiddle: Color.lerp(
        a.highlightFaceMiddle,
        b.highlightFaceMiddle,
        t,
      )!,
      highlightFaceBottom: Color.lerp(
        a.highlightFaceBottom,
        b.highlightFaceBottom,
        t,
      )!,
      thumbTop: Color.lerp(a.thumbTop, b.thumbTop, t)!,
      thumbBottom: Color.lerp(a.thumbBottom, b.thumbBottom, t)!,
      hatch: Color.lerp(a.hatch, b.hatch, t)!,
      shade: Color.lerp(a.shade, b.shade, t)!,
      glow: Color.lerp(a.glow, b.glow, t)!,
      markLabel: Color.lerp(a.markLabel, b.markLabel, t)!,
      iconPage: Color.lerp(a.iconPage, b.iconPage, t)!,
      iconFold: Color.lerp(a.iconFold, b.iconFold, t)!,
      iconLine: Color.lerp(a.iconLine, b.iconLine, t)!,
      titleBoxDark: Color.lerp(a.titleBoxDark, b.titleBoxDark, t)!,
      titleBoxLight: Color.lerp(a.titleBoxLight, b.titleBoxLight, t)!,
      binderRingLight: Color.lerp(a.binderRingLight, b.binderRingLight, t)!,
      binderRingDark: Color.lerp(a.binderRingDark, b.binderRingDark, t)!,
      pixelOutline: Color.lerp(a.pixelOutline, b.pixelOutline, t)!,
      tones: mix(a.tones, b.tones),
      illustration: RetroDesktopIllustrationColors.lerp(
        a.illustration,
        b.illustration,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetroDesktopColors &&
          dark == other.dark &&
          desktop == other.desktop &&
          desktopThreadLight == other.desktopThreadLight &&
          desktopThreadDark == other.desktopThreadDark &&
          desktopGlow == other.desktopGlow &&
          platinum == other.platinum &&
          platinumLight == other.platinumLight &&
          platinumDark == other.platinumDark &&
          bevelLight == other.bevelLight &&
          bevelDark == other.bevelDark &&
          bevelDarker == other.bevelDarker &&
          outline == other.outline &&
          control == other.control &&
          controlFace == other.controlFace &&
          paper == other.paper &&
          paperDim == other.paperDim &&
          divider == other.divider &&
          text == other.text &&
          textSecondary == other.textSecondary &&
          textTertiary == other.textTertiary &&
          highlight == other.highlight &&
          highlightDark == other.highlightDark &&
          highlightMid == other.highlightMid &&
          highlightContainer == other.highlightContainer &&
          onHighlight == other.onHighlight &&
          highlightFaceTop == other.highlightFaceTop &&
          highlightFaceMiddle == other.highlightFaceMiddle &&
          highlightFaceBottom == other.highlightFaceBottom &&
          thumbTop == other.thumbTop &&
          thumbBottom == other.thumbBottom &&
          hatch == other.hatch &&
          shade == other.shade &&
          glow == other.glow &&
          markLabel == other.markLabel &&
          iconPage == other.iconPage &&
          iconFold == other.iconFold &&
          iconLine == other.iconLine &&
          titleBoxDark == other.titleBoxDark &&
          titleBoxLight == other.titleBoxLight &&
          binderRingLight == other.binderRingLight &&
          binderRingDark == other.binderRingDark &&
          pixelOutline == other.pixelOutline &&
          listEquals(tones, other.tones) &&
          illustration == other.illustration;

  @override
  int get hashCode => Object.hashAll([
    dark,
    desktop,
    desktopThreadLight,
    desktopThreadDark,
    desktopGlow,
    platinum,
    platinumLight,
    platinumDark,
    bevelLight,
    bevelDark,
    bevelDarker,
    outline,
    control,
    controlFace,
    paper,
    paperDim,
    divider,
    text,
    textSecondary,
    textTertiary,
    highlight,
    highlightDark,
    highlightMid,
    highlightContainer,
    onHighlight,
    highlightFaceTop,
    highlightFaceMiddle,
    highlightFaceBottom,
    thumbTop,
    thumbBottom,
    hatch,
    shade,
    glow,
    markLabel,
    iconPage,
    iconFold,
    iconLine,
    titleBoxDark,
    titleBoxLight,
    binderRingLight,
    binderRingDark,
    pixelOutline,
    Object.hashAll(tones),
    illustration,
  ]);
}

/// The inks the period's pictures draw with: the thirteen tones of a pixel sky, its weather, what stands under it,
/// and the alert pictures. A preset sets them; [RetroDesktopColors.from] keeps the classic preset's.
@immutable
class RetroDesktopIllustrationColors {
  /// Creates a [RetroDesktopIllustrationColors].
  RetroDesktopIllustrationColors({
    required List<Color> sky,
    required this.cloud,
    required this.cloudLow,
    required this.cloudLit,
    required this.cloudLitLow,
    required this.cloudNight,
    required this.cloudNightLow,
    required this.sun,
    required this.sunset,
    required this.moon,
    required this.star,
    required this.rain,
    required this.tower,
    required this.skyLine,
    required this.sea,
    this.caution = const Color(0xffffcc33),
    this.stop = const Color(0xffdd2222),
    this.note = const Color(0xff3333aa),
  }) : sky = List.unmodifiable(sky);

  /// The thirteen tones of a pixel sky, from its top down.
  final List<Color> sky;

  /// A day cloud and its shaded foot.
  final Color cloud, cloudLow;

  /// A sunlit cloud and its foot.
  final Color cloudLit, cloudLitLow;

  /// A night cloud and its foot.
  final Color cloudNight, cloudNightLow;

  /// The sun, the setting sun, the moon and a star.
  final Color sun, sunset, moon, star;

  /// Rain, the tower on the skyline, the skyline itself and the sea.
  final Color rain, tower, skyLine, sea;

  /// The alert pictures' inks: the caution triangle's yellow, the stop sign's red, and the blue of the note
  /// balloon's mark and the tick.
  final Color caution, stop, note;

  /// The same inks with the named ones replaced.
  RetroDesktopIllustrationColors copyWith({
    List<Color>? sky,
    Color? cloud,
    Color? cloudLow,
    Color? cloudLit,
    Color? cloudLitLow,
    Color? cloudNight,
    Color? cloudNightLow,
    Color? sun,
    Color? sunset,
    Color? moon,
    Color? star,
    Color? rain,
    Color? tower,
    Color? skyLine,
    Color? sea,
    Color? caution,
    Color? stop,
    Color? note,
  }) => RetroDesktopIllustrationColors(
    sky: sky ?? this.sky,
    cloud: cloud ?? this.cloud,
    cloudLow: cloudLow ?? this.cloudLow,
    cloudLit: cloudLit ?? this.cloudLit,
    cloudLitLow: cloudLitLow ?? this.cloudLitLow,
    cloudNight: cloudNight ?? this.cloudNight,
    cloudNightLow: cloudNightLow ?? this.cloudNightLow,
    sun: sun ?? this.sun,
    sunset: sunset ?? this.sunset,
    moon: moon ?? this.moon,
    star: star ?? this.star,
    rain: rain ?? this.rain,
    tower: tower ?? this.tower,
    skyLine: skyLine ?? this.skyLine,
    sea: sea ?? this.sea,
    caution: caution ?? this.caution,
    stop: stop ?? this.stop,
    note: note ?? this.note,
  );

  /// Interpolates every ink, and the sky tone by tone.
  static RetroDesktopIllustrationColors lerp(
    RetroDesktopIllustrationColors a,
    RetroDesktopIllustrationColors b,
    double t,
  ) {
    if (t == 0) return a;
    if (t == 1) return b;
    Color mix(Color x, Color y) => Color.lerp(x, y, t)!;
    final n = a.sky.length > b.sky.length ? a.sky.length : b.sky.length;
    return RetroDesktopIllustrationColors(
      sky: [
        for (var i = 0; i < n; i++)
          Color.lerp(
            i < a.sky.length ? a.sky[i] : null,
            i < b.sky.length ? b.sky[i] : null,
            t,
          )!,
      ],
      cloud: mix(a.cloud, b.cloud),
      cloudLow: mix(a.cloudLow, b.cloudLow),
      cloudLit: mix(a.cloudLit, b.cloudLit),
      cloudLitLow: mix(a.cloudLitLow, b.cloudLitLow),
      cloudNight: mix(a.cloudNight, b.cloudNight),
      cloudNightLow: mix(a.cloudNightLow, b.cloudNightLow),
      sun: mix(a.sun, b.sun),
      sunset: mix(a.sunset, b.sunset),
      moon: mix(a.moon, b.moon),
      star: mix(a.star, b.star),
      rain: mix(a.rain, b.rain),
      tower: mix(a.tower, b.tower),
      skyLine: mix(a.skyLine, b.skyLine),
      sea: mix(a.sea, b.sea),
      caution: mix(a.caution, b.caution),
      stop: mix(a.stop, b.stop),
      note: mix(a.note, b.note),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetroDesktopIllustrationColors &&
          listEquals(sky, other.sky) &&
          cloud == other.cloud &&
          cloudLow == other.cloudLow &&
          cloudLit == other.cloudLit &&
          cloudLitLow == other.cloudLitLow &&
          cloudNight == other.cloudNight &&
          cloudNightLow == other.cloudNightLow &&
          sun == other.sun &&
          sunset == other.sunset &&
          moon == other.moon &&
          star == other.star &&
          rain == other.rain &&
          tower == other.tower &&
          skyLine == other.skyLine &&
          sea == other.sea &&
          caution == other.caution &&
          stop == other.stop &&
          note == other.note;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(sky),
    cloud,
    cloudLow,
    cloudLit,
    cloudLitLow,
    cloudNight,
    cloudNightLow,
    sun,
    sunset,
    moon,
    star,
    rain,
    tower,
    skyLine,
    sea,
    caution,
    stop,
    note,
  );
}

/// One preset by day or by night: what a designer picks. Everything else in [RetroDesktopColors] is worked out from these, in
/// [_Palette._colors], so no colour lives outside a seed.
class _Seed {
  const _Seed({
    required this.desk,
    required this.deskA,
    required this.deskB,
    required this.deskGlow,
    required this.plat,
    required this.plat2,
    required this.plat3,
    required this.hi,
    required this.lo,
    required this.lo2,
    required this.edge,
    required this.ctl,
    required this.ctlFace,
    required this.paper,
    required this.paper2,
    required this.rule,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.hl,
    required this.hlDeep,
    required this.hlMid,
    required this.hlTint,
    required this.hlInk,
    required this.hlFaceTop,
    required this.hlFaceBot,
    required this.thumbTop,
    required this.thumbBot,
    required this.shade,
    required this.markLabel,
    required this.outline,
    this.tones = _dayTones,
    this.sky = _daySky,
    this.art = _dayArt,
    this.hue,
    this.saturation = 1,
  });
  final Color desk, deskA, deskB, deskGlow;
  final Color plat, plat2, plat3, hi, lo, lo2, edge, ctl, ctlFace;
  final Color paper, paper2, rule, ink, ink2, ink3;
  final Color hl, hlDeep, hlMid, hlTint, hlInk, hlFaceTop, hlFaceBot;
  final Color thumbTop, thumbBot, shade, markLabel, outline;
  final List<Color> tones, sky, art;

  /// The art's tones, turned to this hue and scaled by [saturation]. The concept's own preset leaves it alone.
  final double? hue;
  final double saturation;
}

// The concept's two pixel pictures, by day and by night. A preset turns them to its hue.
const List<Color> _dayTones = [
  Color(0xFFE9E8FB),
  Color(0xFFBDBCE0),
  Color(0xFF8E8DB9),
  Color(0xFF6D69BF),
  Color(0xFF3F3C96),
];
const List<Color> _nightTones = [
  Color(0xFFA5A4D6),
  Color(0xFF7675AE),
  Color(0xFF565587),
  Color(0xFF443F94),
  Color(0xFF2C2A6E),
];
const List<Color> _daySky = [
  Color(0xFF8887B0),
  Color(0xFF807FA9),
  Color(0xFF9594BC),
  Color(0xFFAAA9CF),
  Color(0xFFBDBCE0),
  Color(0xFFD2D1F0),
  Color(0xFFE2E1F8),
  Color(0xFFB4AFE6),
  Color(0xFF6D69BF),
  Color(0xFF44419A),
  Color(0xFF2F2D78),
  Color(0xFF2C2B6C),
  Color(0xFF2E2D66),
];
const List<Color> _nightSky = [
  Color(0xFF3B3A5F),
  Color(0xFF363559),
  Color(0xFF403F67),
  Color(0xFF4C4B78),
  Color(0xFF5A5989),
  Color(0xFF6A699E),
  Color(0xFF7776AE),
  Color(0xFF5F5AA8),
  Color(0xFF3B3786),
  Color(0xFF27255F),
  Color(0xFF1C1B4A),
  Color(0xFF1B1A44),
  Color(0xFF1D1C44),
];
// cloud, its foot; lit cloud, its foot; night cloud, its foot; sun, set, moon, star, rain, tower, sky line, sea.
const List<Color> _dayArt = [
  Color(0xFF6C6B95),
  Color(0xFF55547E),
  Color(0xFFFFFFFF),
  Color(0xFFCFCEE9),
  Color(0xFF4A4982),
  Color(0xFF3A3970),
  Color(0xFFFFFFFF),
  Color(0xFFFFFFFF),
  Color(0xFFF4F3FF),
  Color(0xFFFFFFFF),
  Color(0xFFE6E4FF),
  Color(0xFFF4F3FF),
  Color(0xFF14142A),
  Color(0x9E0D0C2C),
];
const List<Color> _nightArt = [
  Color(0xFF55547E),
  Color(0xFF424167),
  Color(0xFFC9C8E6),
  Color(0xFF9C9BC4),
  Color(0xFF38375F),
  Color(0xFF2B2A4E),
  Color(0xFFF1F0FF),
  Color(0xFFB9B4FF),
  Color(0xFFE9E8FF),
  Color(0xFFD9D8FF),
  Color(0xFFC9C6FF),
  Color(0xFFD6D5EE),
  Color(0xFF14142A),
  Color(0x9E0D0C2C),
];

Color _mix(Color a, Color b, double k) => Color.lerp(a, b, k)!;

Color _turn(Color c, double? hue, double saturation) {
  if (hue == null) return c;
  final h = HSLColor.fromColor(c);
  return h
      .withHue(hue)
      .withSaturation((h.saturation * saturation).clamp(0.0, 1.0))
      .toColor();
}

/// One preset, designed for day and for night.
class _Palette {
  _Palette(_Seed d, _Seed n)
    : day = _colors(d, false),
      night = _colors(n, true);
  final RetroDesktopColors day, night;

  /// The one place the colour rules live.
  static RetroDesktopColors _colors(_Seed s, bool dark) {
    List<Color> art(List<Color> xs) => [
      for (final x in xs) _turn(x, s.hue, s.saturation),
    ];
    final a = art(s.art);
    return RetroDesktopColors(
      dark: dark,
      desktop: s.desk,
      desktopThreadLight: s.deskA,
      desktopThreadDark: s.deskB,
      desktopGlow: s.deskGlow,
      platinum: s.plat,
      platinumLight: s.plat2,
      platinumDark: s.plat3,
      bevelLight: s.hi,
      bevelDark: s.lo,
      bevelDarker: s.lo2,
      outline: s.edge,
      control: s.ctl,
      controlFace: s.ctlFace,
      paper: s.paper,
      paperDim: s.paper2,
      divider: s.rule,
      text: s.ink,
      textSecondary: s.ink2,
      textTertiary: s.ink3,
      highlight: s.hl,
      highlightDark: s.hlDeep,
      highlightMid: s.hlMid,
      highlightContainer: s.hlTint,
      onHighlight: s.hlInk,
      highlightFaceTop: s.hlFaceTop,
      highlightFaceMiddle: s.hl,
      highlightFaceBottom: s.hlFaceBot,
      thumbTop: s.thumbTop,
      thumbBottom: s.thumbBot,
      hatch: s.ink.withValues(alpha: dark ? .78 : .8),
      shade: s.shade,
      glow: dark ? s.hl.withValues(alpha: .6) : s.hl.withValues(alpha: 0),
      markLabel: s.markLabel,
      iconPage: dark ? _mix(s.plat2, s.hi, .1) : s.paper,
      iconFold: dark ? _mix(s.hi, s.ink3, .1) : s.plat3,
      iconLine: dark ? _mix(s.ink3, s.hi, .3) : s.lo,
      titleBoxDark: dark ? s.plat3 : s.plat3,
      titleBoxLight: dark ? _mix(s.plat2, s.hi, .5) : s.hi,
      binderRingLight: dark ? _mix(s.ink3, s.hi, .3) : s.hi,
      binderRingDark: dark ? _mix(s.hi, s.plat2, .5) : s.lo,
      pixelOutline: s.outline,
      tones: art(s.tones),
      illustration: RetroDesktopIllustrationColors(
        sky: art(s.sky),
        cloud: a[0],
        cloudLow: a[1],
        cloudLit: a[2],
        cloudLitLow: a[3],
        cloudNight: a[4],
        cloudNightLow: a[5],
        sun: a[6],
        sunset: a[7],
        moon: a[8],
        star: a[9],
        rain: a[10],
        tower: a[11],
        skyLine: a[12],
        sea: a[13],
      ),
    );
  }
}

const _plumShade = Color(0xFF0C0A32);
const _black = Color(0xFF000000);

// The concept's own: desktop greys and a confident indigo by day, graphite with the indigo lit as a lamp by night.
final _Palette _classic = _Palette(
  const _Seed(
    desk: Color(0xFF5E62A3),
    deskA: Color(0x16FFFFFF),
    deskB: Color(0x240A082E),
    deskGlow: Color(0x1FFFFFFF),
    plat: Color(0xFFDDDDDD),
    plat2: Color(0xFFE9E9E9),
    plat3: Color(0xFFCBCBCB),
    hi: Color(0xFFFFFFFF),
    lo: Color(0xFF9A9A9A),
    lo2: Color(0xFF6E6E74),
    edge: Color(0xFF262626),
    ctl: Color(0xFF262626),
    ctlFace: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFF2F2F5),
    rule: Color(0xFFE3E3E8),
    ink: Color(0xFF141418),
    ink2: Color(0xFF4A4A52),
    ink3: Color(0xFF55555E),
    hl: Color(0xFF4B3FD6),
    hlDeep: Color(0xFF3427A8),
    hlMid: Color(0xFFB7B1FF),
    hlTint: Color(0xFFDCDAFF),
    hlInk: Color(0xFFFFFFFF),
    hlFaceTop: Color(0xFF6458EC),
    hlFaceBot: Color(0xFF4236C8),
    thumbTop: Color(0xFFCFCAFF),
    thumbBot: Color(0xFFA59DFF),
    shade: _plumShade,
    markLabel: Color(0xFFFFFFFF),
    outline: Color(0xFF141418),
  ),
  const _Seed(
    desk: Color(0xFF2C2C5A),
    deskA: Color(0x12A39DFF),
    deskB: Color(0x4D000000),
    deskGlow: Color(0x337C74FF),
    plat: Color(0xFF2E2F36),
    plat2: Color(0xFF393A42),
    plat3: Color(0xFF24252B),
    hi: Color(0xFF50515B),
    lo: Color(0xFF141418),
    lo2: Color(0xFF0D0D10),
    edge: Color(0xFF050507),
    ctl: Color(0xFF84848F),
    ctlFace: Color(0xFF1C1C22),
    paper: Color(0xFF1C1C22),
    paper2: Color(0xFF23232B),
    rule: Color(0xFF2E2E36),
    ink: Color(0xFFEDEDF2),
    ink2: Color(0xFFB9B9C4),
    ink3: Color(0xFFA3A3AF),
    hl: Color(0xFFA39DFF),
    hlDeep: Color(0xFF7067F2),
    hlMid: Color(0xFF4C468F),
    hlTint: Color(0xFF35316B),
    hlInk: Color(0xFF100C33),
    hlFaceTop: Color(0xFFB9B4FF),
    hlFaceBot: Color(0xFF9189FB),
    thumbTop: Color(0xFFA7A1FF),
    thumbBot: Color(0xFF7E75F6),
    shade: _black,
    markLabel: _black,
    outline: Color(0xFFB9B8DE),
    tones: _nightTones,
    sky: _nightSky,
    art: _nightArt,
  ),
);

// Lagoon: a cool grey on a deep teal desktop; at night the lamp is a cyan over black water.
final _Palette _lagoon = _Palette(
  const _Seed(
    desk: Color(0xFF2F7F86),
    deskA: Color(0x16FFFFFF),
    deskB: Color(0x24002A30),
    deskGlow: Color(0x1FFFFFFF),
    plat: Color(0xFFDBDEDF),
    plat2: Color(0xFFE7EAEB),
    plat3: Color(0xFFC8CCCE),
    hi: Color(0xFFFFFFFF),
    lo: Color(0xFF93999B),
    lo2: Color(0xFF666D70),
    edge: Color(0xFF222627),
    ctl: Color(0xFF222627),
    ctlFace: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFEFF4F5),
    rule: Color(0xFFDFE6E8),
    ink: Color(0xFF101517),
    ink2: Color(0xFF42494C),
    ink3: Color(0xFF4F575A),
    hl: Color(0xFF00626F),
    hlDeep: Color(0xFF004854),
    hlMid: Color(0xFF8FD3DA),
    hlTint: Color(0xFFCDEBEE),
    hlInk: Color(0xFFFFFFFF),
    hlFaceTop: Color(0xFF0B7C8A),
    hlFaceBot: Color(0xFF005864),
    thumbTop: Color(0xFFBDEAEE),
    thumbBot: Color(0xFF7CCFD8),
    shade: Color(0xFF00232A),
    markLabel: Color(0xFFFFFFFF),
    outline: Color(0xFF101517),
    hue: 186,
    saturation: .9,
  ),
  const _Seed(
    desk: Color(0xFF13353D),
    deskA: Color(0x125FD3E0),
    deskB: Color(0x4D000000),
    deskGlow: Color(0x332AA5B4),
    plat: Color(0xFF2B3235),
    plat2: Color(0xFF363E41),
    plat3: Color(0xFF22282A),
    hi: Color(0xFF4C5558),
    lo: Color(0xFF121618),
    lo2: Color(0xFF0B0E0F),
    edge: Color(0xFF040607),
    ctl: Color(0xFF7F8C90),
    ctlFace: Color(0xFF192023),
    paper: Color(0xFF192023),
    paper2: Color(0xFF202A2D),
    rule: Color(0xFF2A3437),
    ink: Color(0xFFEAF0F1),
    ink2: Color(0xFFB5C2C5),
    ink3: Color(0xFFA0AEB2),
    hl: Color(0xFF5FD3E0),
    hlDeep: Color(0xFF2AA5B4),
    hlMid: Color(0xFF2C6E78),
    hlTint: Color(0xFF1E4A52),
    hlInk: Color(0xFF06262B),
    hlFaceTop: Color(0xFF82E0EA),
    hlFaceBot: Color(0xFF45C2D0),
    thumbTop: Color(0xFF7FDDE8),
    thumbBot: Color(0xFF3BB7C6),
    shade: _black,
    markLabel: _black,
    outline: Color(0xFFA9DCE2),
    tones: _nightTones,
    sky: _nightSky,
    art: _nightArt,
    hue: 186,
    saturation: .9,
  ),
);

// Berry: a warm pink grey on a mulberry desktop; at night a rose lamp over a wine-black desk.
final _Palette _berry = _Palette(
  const _Seed(
    desk: Color(0xFF8C4A6E),
    deskA: Color(0x16FFFFFF),
    deskB: Color(0x242E0018),
    deskGlow: Color(0x1FFFFFFF),
    plat: Color(0xFFDFDADC),
    plat2: Color(0xFFEAE6E8),
    plat3: Color(0xFFCDC7CA),
    hi: Color(0xFFFFFFFF),
    lo: Color(0xFF9B9497),
    lo2: Color(0xFF6F686B),
    edge: Color(0xFF282325),
    ctl: Color(0xFF282325),
    ctlFace: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFF6F1F3),
    rule: Color(0xFFE9E2E5),
    ink: Color(0xFF181215),
    ink2: Color(0xFF4E454A),
    ink3: Color(0xFF5A5157),
    hl: Color(0xFFA81C57),
    hlDeep: Color(0xFF7F1241),
    hlMid: Color(0xFFF0A8C6),
    hlTint: Color(0xFFF8D9E6),
    hlInk: Color(0xFFFFFFFF),
    hlFaceTop: Color(0xFFC62F70),
    hlFaceBot: Color(0xFF96164B),
    thumbTop: Color(0xFFF7C3D8),
    thumbBot: Color(0xFFEE93B8),
    shade: Color(0xFF2E0018),
    markLabel: Color(0xFFFFFFFF),
    outline: Color(0xFF181215),
    hue: 332,
    saturation: .85,
  ),
  const _Seed(
    desk: Color(0xFF4D223C),
    deskA: Color(0x12FF8FBC),
    deskB: Color(0x4D000000),
    deskGlow: Color(0x33C62F70),
    plat: Color(0xFF33292F),
    plat2: Color(0xFF3F343A),
    plat3: Color(0xFF281F25),
    hi: Color(0xFF5A4C54),
    lo: Color(0xFF171014),
    lo2: Color(0xFF0E0A0C),
    edge: Color(0xFF060405),
    ctl: Color(0xFF93838C),
    ctlFace: Color(0xFF211A1E),
    paper: Color(0xFF211A1E),
    paper2: Color(0xFF2A2126),
    rule: Color(0xFF362B31),
    ink: Color(0xFFF2ECEF),
    ink2: Color(0xFFC7BAC1),
    ink3: Color(0xFFB7A9B0),
    hl: Color(0xFFFF8FBC),
    hlDeep: Color(0xFFD9528D),
    hlMid: Color(0xFF7A3355),
    hlTint: Color(0xFF4F2238),
    hlInk: Color(0xFF2E0618),
    hlFaceTop: Color(0xFFFFADCF),
    hlFaceBot: Color(0xFFF778A9),
    thumbTop: Color(0xFFFFA8CB),
    thumbBot: Color(0xFFEC6FA2),
    shade: _black,
    markLabel: _black,
    outline: Color(0xFFE2B8CB),
    tones: _nightTones,
    sky: _nightSky,
    art: _nightArt,
    hue: 332,
    saturation: .85,
  ),
);

// Marmalade: a warm stone grey on a burnt amber desktop; at night an amber lamp over a brown-black desk.
final _Palette _marmalade = _Palette(
  const _Seed(
    desk: Color(0xFFA9683A),
    deskA: Color(0x16FFFFFF),
    deskB: Color(0x24301200),
    deskGlow: Color(0x1FFFFFFF),
    plat: Color(0xFFDFDBD3),
    plat2: Color(0xFFEAE7E0),
    plat3: Color(0xFFCCC7BD),
    hi: Color(0xFFFFFFFF),
    lo: Color(0xFF9B968C),
    lo2: Color(0xFF6F6A60),
    edge: Color(0xFF282520),
    ctl: Color(0xFF282520),
    ctlFace: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFF6F3EE),
    rule: Color(0xFFE8E3DA),
    ink: Color(0xFF181510),
    ink2: Color(0xFF4D483E),
    ink3: Color(0xFF59534A),
    hl: Color(0xFF9E3B06),
    hlDeep: Color(0xFF7A2C04),
    hlMid: Color(0xFFF5BE8E),
    hlTint: Color(0xFFF8E0CB),
    hlInk: Color(0xFFFFFFFF),
    hlFaceTop: Color(0xFFBC500F),
    hlFaceBot: Color(0xFF8C3404),
    thumbTop: Color(0xFFF9CFA9),
    thumbBot: Color(0xFFF2AC6E),
    shade: Color(0xFF301200),
    markLabel: Color(0xFFFFFFFF),
    outline: Color(0xFF181510),
    hue: 28,
    saturation: .9,
  ),
  const _Seed(
    desk: Color(0xFF462A15),
    deskA: Color(0x12FFB066),
    deskB: Color(0x4D000000),
    deskGlow: Color(0x33BC500F),
    plat: Color(0xFF33302B),
    plat2: Color(0xFF3F3B35),
    plat3: Color(0xFF282520),
    hi: Color(0xFF5A554D),
    lo: Color(0xFF171510),
    lo2: Color(0xFF0E0C0A),
    edge: Color(0xFF060504),
    ctl: Color(0xFF938E84),
    ctlFace: Color(0xFF211E1A),
    paper: Color(0xFF211E1A),
    paper2: Color(0xFF2A2620),
    rule: Color(0xFF36322B),
    ink: Color(0xFFF3EFE8),
    ink2: Color(0xFFC8C2B7),
    ink3: Color(0xFFB7B1A5),
    hl: Color(0xFFFFB066),
    hlDeep: Color(0xFFE08A3A),
    hlMid: Color(0xFF7A4F22),
    hlTint: Color(0xFF4F3319),
    hlInk: Color(0xFF2B1400),
    hlFaceTop: Color(0xFFFFC689),
    hlFaceBot: Color(0xFFF79D4C),
    thumbTop: Color(0xFFFFC28A),
    thumbBot: Color(0xFFEC9548),
    shade: _black,
    markLabel: _black,
    outline: Color(0xFFE6CDB2),
    tones: _nightTones,
    sky: _nightSky,
    art: _nightArt,
    hue: 28,
    saturation: .9,
  ),
);

// Slate: the plainest, a neutral grey with a blue-black highlight on a storm ground; at night a pale steel lamp on charcoal.
final _Palette _slate = _Palette(
  const _Seed(
    desk: Color(0xFF5F6B76),
    deskA: Color(0x16FFFFFF),
    deskB: Color(0x24101820),
    deskGlow: Color(0x1FFFFFFF),
    plat: Color(0xFFDCDDDE),
    plat2: Color(0xFFE8E9EA),
    plat3: Color(0xFFCACBCD),
    hi: Color(0xFFFFFFFF),
    lo: Color(0xFF979A9D),
    lo2: Color(0xFF6A6D70),
    edge: Color(0xFF242628),
    ctl: Color(0xFF242628),
    ctlFace: Color(0xFFFFFFFF),
    paper: Color(0xFFFFFFFF),
    paper2: Color(0xFFF1F2F4),
    rule: Color(0xFFE1E3E6),
    ink: Color(0xFF121416),
    ink2: Color(0xFF45494E),
    ink3: Color(0xFF52565B),
    hl: Color(0xFF37475A),
    hlDeep: Color(0xFF232F3D),
    hlMid: Color(0xFFA9B6C4),
    hlTint: Color(0xFFD6DEE6),
    hlInk: Color(0xFFFFFFFF),
    hlFaceTop: Color(0xFF4A5C72),
    hlFaceBot: Color(0xFF2E3C4D),
    thumbTop: Color(0xFFD0D9E3),
    thumbBot: Color(0xFFA7B5C5),
    shade: Color(0xFF101820),
    markLabel: Color(0xFFFFFFFF),
    outline: Color(0xFF121416),
    hue: 212,
    saturation: .35,
  ),
  const _Seed(
    desk: Color(0xFF2A323C),
    deskA: Color(0x12B4C6DC),
    deskB: Color(0x4D000000),
    deskGlow: Color(0x33546A84),
    plat: Color(0xFF2D2F33),
    plat2: Color(0xFF383A3F),
    plat3: Color(0xFF232528),
    hi: Color(0xFF4F5157),
    lo: Color(0xFF131416),
    lo2: Color(0xFF0C0D0E),
    edge: Color(0xFF040506),
    ctl: Color(0xFF85878E),
    ctlFace: Color(0xFF1B1C1F),
    paper: Color(0xFF1B1C1F),
    paper2: Color(0xFF232529),
    rule: Color(0xFF2D2F33),
    ink: Color(0xFFECEDEF),
    ink2: Color(0xFFB8BAC0),
    ink3: Color(0xFFA4A6AD),
    hl: Color(0xFFB4C6DC),
    hlDeep: Color(0xFF7F97B4),
    hlMid: Color(0xFF46576B),
    hlTint: Color(0xFF33414F),
    hlInk: Color(0xFF10202F),
    hlFaceTop: Color(0xFFCAD8E8),
    hlFaceBot: Color(0xFF9DB2CB),
    thumbTop: Color(0xFFC3D2E3),
    thumbBot: Color(0xFF90A6C0),
    shade: _black,
    markLabel: _black,
    outline: Color(0xFFBCC6D2),
    tones: _nightTones,
    sky: _nightSky,
    art: _nightArt,
    hue: 212,
    saturation: .35,
  ),
);

/// A line height on the whole-pixel grid: Flutter ceils a paragraph's height where Blink keeps fractions.
double _exact(double size, double px) => px / size;

/// Type. Two families and a mono: Jersey 15 is the system face (chrome, heads, numerals), Atkinson the reading face, Atkinson
/// Mono only where numbers must align. Jersey has one weight: write no `fontWeight` on it, it does nothing.
class RetroDesktopTextTheme {
  RetroDesktopTextTheme._(
    this.colors,
    this.desk, [
    this.typeface = const RetroDesktopTypeface(),
  ]) : chrome = _font(_px(20, 22, colors.text), typeface.chromeFamily),
       small = _font(_px(20, 24, colors.text), typeface.chromeFamily),
       sub = _font(_px(24, 28, colors.text), typeface.chromeFamily),
       head = _font(
         desk ? _px(34, 30, colors.text) : _px(30, 28, colors.text),
         typeface.chromeFamily,
       ),
       big = _font(_px(30, 28, colors.text), typeface.chromeFamily),
       title = _font(
         desk ? _px(56, 48, colors.text) : _px(40, 36, colors.text),
         typeface.chromeFamily,
       ),
       body = _font(
         _tx(16, 22, FontWeight.w400, colors.text),
         typeface.bodyFamily,
       ),
       row = _font(
         _tx(16, 22, FontWeight.w600, colors.text),
         typeface.bodyFamily,
       ),
       read = _font(
         _tx(17, 28, FontWeight.w400, colors.text),
         typeface.bodyFamily,
       ),
       note = _font(
         _tx(14, 20, FontWeight.w400, colors.textSecondary),
         typeface.bodyFamily,
       ),
       caption = _font(
         _tx(14, 20, FontWeight.w600, colors.textSecondary),
         typeface.bodyFamily,
       ),
       meta = _font(
         _tx(14, 20, FontWeight.w400, colors.textTertiary),
         typeface.bodyFamily,
       ),
       figure = _font(
         _mo(14, 20, FontWeight.w600, colors.text),
         typeface.monoFamily,
       );

  /// The color palette used by this scope.
  final RetroDesktopColors colors;

  /// The faces the styles are set in.
  final RetroDesktopTypeface typeface;
  static TextStyle _font(TextStyle style, String family) =>
      style.copyWith(fontFamily: retroDesktopFontFamily(family));

  /// Whether the styles are a desk's (from 1024 wide up), not a phone's.
  final bool desk;

  /// Jersey 15. `chrome` 20 for title bars, buttons, tabs and menus; `small` 20 and `sub` 24 for section heads; `big` 30 for a
  /// stat; `head` 30 to 34 for a page's sentence; `title` 40 to 56 for a document's title.
  final TextStyle chrome, small, sub, big, head, title;

  /// Atkinson. `body` 16 and `row` 16 semi-bold for rows; `read` 17 on 28 to read; `note` 14; `caption` 14 semi-bold for labels;
  /// `meta` 14 for what is quietest.
  final TextStyle body, row, read, note, caption, meta;

  /// Atkinson Mono, 14: values that must align.
  final TextStyle figure;

  /// Jersey 15 at any size, for a part's one numeral.
  TextStyle pixel(double size, double lineHeight, {Color? color}) =>
      _font(_px(size, lineHeight, color ?? colors.text), typeface.chromeFamily);

  /// Atkinson at any size.
  TextStyle text(
    double size,
    double lineHeight, {
    FontWeight weight = FontWeight.w400,
    Color? color,
    FontStyle? style,
  }) => _font(
    _tx(
      size,
      lineHeight,
      weight,
      color ?? colors.text,
    ).copyWith(fontStyle: style),
    typeface.bodyFamily,
  );

  /// Atkinson Mono at any size.
  TextStyle mono(
    double size,
    double lineHeight, {
    FontWeight weight = FontWeight.w400,
    Color? color,
  }) => _font(
    _mo(size, lineHeight, weight, color ?? colors.text),
    typeface.monoFamily,
  );

  // `fontWeight` is pinned: the face has one weight and the engine must never be asked to fake another.
  static TextStyle _px(double size, double lineHeight, Color color) =>
      TextStyle(
        inherit: false,
        fontFamily: 'Jersey15',
        fontSize: size,
        height: _exact(size, lineHeight),
        fontWeight: FontWeight.w400,
        color: color,
        textBaseline: TextBaseline.alphabetic,
        leadingDistribution: TextLeadingDistribution.even,
        decoration: TextDecoration.none,
      );

  static TextStyle _tx(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color,
  ) => TextStyle(
    inherit: false,
    fontFamily: 'AtkinsonNext',
    fontSize: size,
    height: _exact(size, lineHeight),
    fontWeight: weight,
    color: color,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );

  static TextStyle _mo(
    double size,
    double lineHeight,
    FontWeight weight,
    Color color,
  ) => TextStyle(
    inherit: false,
    fontFamily: 'AtkinsonMono',
    fontSize: size,
    height: _exact(size, lineHeight),
    fontWeight: weight,
    color: color,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );
}

/// What `RetroDesktopTheme.of(context)` returns.
@immutable
class RetroDesktopThemeData with Diagnosticable {
  RetroDesktopThemeData._(
    this.id,
    this._palette,
    this.colors,
    this.page,
    this.width, {
    this._components = const RetroDesktopComponentThemes(),
    this.motion = const RetroDesktopMotion(),
    this.appearance = RetroDesktopAppearance.platinum,
    this._density,
    this.typeface = const RetroDesktopTypeface(),
    this._focus,
  }) : type = RetroDesktopTextTheme._(
         colors,
         width >= retroDesktopDeskWidth,
         typeface,
       );

  /// Derives a readable desktop palette from the app's primary colour.
  factory RetroDesktopThemeData.from({
    required Color primary,
    required Brightness brightness,
    Color? surface,
  }) {
    final colors = RetroDesktopColors.from(
      primary: primary,
      brightness: brightness,
      surface: surface,
    );
    return RetroDesktopThemeData._('custom', _classic, colors, colors, 0);
  }

  /// Periwinkle desktop with an indigo highlight, by day and by night.
  factory RetroDesktopThemeData.classic([
    Brightness brightness = Brightness.light,
  ]) => preset('classic', brightness);

  /// Teal desktop and highlight, by day and by night.
  factory RetroDesktopThemeData.lagoon([
    Brightness brightness = Brightness.light,
  ]) => preset('lagoon', brightness);

  /// Plum desktop with a raspberry highlight, by day and by night.
  factory RetroDesktopThemeData.berry([
    Brightness brightness = Brightness.light,
  ]) => preset('berry', brightness);

  /// Amber desktop with a burnt-orange highlight, by day and by night.
  factory RetroDesktopThemeData.marmalade([
    Brightness brightness = Brightness.light,
  ]) => preset('marmalade', brightness);

  /// A quieter blue-grey desktop, by day and by night.
  factory RetroDesktopThemeData.slate([
    Brightness brightness = Brightness.light,
  ]) => preset('slate', brightness);

  /// Which preset this is (`classic`, `lagoon`, ...).
  final String id;
  final _Palette _palette;

  /// Current colours: on a highlighted surface, its own.
  final RetroDesktopColors colors;

  /// The page's colours, even on a highlighted surface.
  final RetroDesktopColors page;

  /// The resolved text styles for this theme.
  final RetroDesktopTextTheme type;

  /// The width in logical pixels.
  final double width;

  /// The preset ids, the default first. Each is designed in light and dark.
  static const List<String> presets = <String>[
    'classic',
    'lagoon',
    'berry',
    'marmalade',
    'slate',
  ];

  static final Map<String, _Palette> _palettes = {
    'classic': _classic,
    'lagoon': _lagoon,
    'berry': _berry,
    'marmalade': _marmalade,
    'slate': _slate,
  };
  static final Map<(String, Brightness), RetroDesktopThemeData> _cache = {};

  /// The theme for preset [id] in [brightness]; an unknown id throws. The theme file's call.
  static RetroDesktopThemeData preset(String id, Brightness brightness) {
    final palette = _palettes[id];
    if (palette == null) {
      throw ArgumentError.value(
        id,
        'id',
        'not a Retro Desktop preset (${presets.join(', ')})',
      );
    }
    return _cache[(id, brightness)] ??= () {
      final c = brightness == Brightness.dark ? palette.night : palette.day;
      return RetroDesktopThemeData._(id, palette, c, c, 0);
    }();
  }

  /// The same theme, its type set for [width].
  RetroDesktopThemeData atWidth(double width) => width == this.width
      ? this
      : RetroDesktopThemeData._(
          id,
          _palette,
          colors,
          page,
          width,
          components: _components,
          motion: motion,
          focus: _focus,
          appearance: appearance,
          density: _density,
          typeface: typeface,
        );

  /// The stubs' page title and body text.
  TextStyle get h1 => type.head;

  /// The main content shown beneath the heading.
  TextStyle get body => type.body;

  /// True from 1024 wide up: the tiled desktop.
  bool get desk => width >= retroDesktopDeskWidth;

  /// Whether the theme is in its night colours.
  bool get dark => colors.dark;

  /// The palette for what stands on the highlight: a selected row, the default button, today.
  RetroDesktopThemeData get onHighlight {
    final c = page;
    final on = c.onHighlight;
    return RetroDesktopThemeData._(
      id,
      _palette,
      RetroDesktopColors(
        dark: c.dark,
        desktop: c.desktop,
        desktopThreadLight: c.desktopThreadLight,
        desktopThreadDark: c.desktopThreadDark,
        desktopGlow: c.desktopGlow,
        platinum: c.highlight,
        platinumLight: c.highlight,
        platinumDark: c.highlightDark,
        bevelLight: c.bevelLight,
        bevelDark: c.highlightDark,
        bevelDarker: on,
        outline: c.outline,
        control: on,
        controlFace: c.controlFace,
        paper: c.highlight,
        paperDim: c.highlight,
        divider: on.withValues(alpha: .35),
        text: on,
        textSecondary: on,
        textTertiary: on,
        highlight: on,
        highlightDark: on,
        highlightMid: c.highlightMid,
        highlightContainer: c.highlightContainer,
        onHighlight: c.highlight,
        highlightFaceTop: c.highlightFaceTop,
        highlightFaceMiddle: c.highlightFaceMiddle,
        highlightFaceBottom: c.highlightFaceBottom,
        thumbTop: c.thumbTop,
        thumbBottom: c.thumbBottom,
        hatch: on,
        shade: c.shade,
        glow: c.glow,
        markLabel: c.markLabel,
        iconPage: c.iconPage,
        iconFold: c.iconFold,
        iconLine: c.iconLine,
        titleBoxDark: c.titleBoxDark,
        titleBoxLight: c.titleBoxLight,
        binderRingLight: c.binderRingLight,
        binderRingDark: c.binderRingDark,
        pixelOutline: on,
        tones: c.tones,
        illustration: c.illustration,
      ),
      c,
      width,
      components: _components,
      motion: motion,
      focus: _focus,
      appearance: appearance,
      density: _density,
      typeface: typeface,
    );
  }

  /// Which desktop the parts draw: Chisel (the 95-era PC) or Platinum (the
  /// late-90s Mac, the default). It sets the corners ([shapes]), the edges,
  /// the pressed face and the focus ring.
  final RetroDesktopAppearance appearance;

  /// Whether the parts draw the Chisel appearance.
  bool get chisel => appearance == RetroDesktopAppearance.chisel;

  /// The [appearance]'s outlines by role, for a part drawn in the look's hand. A
  /// component theme still sets one part's own shape.
  RetroDesktopShapes get shapes => RetroDesktopShapes.of(appearance);

  /// The look's line widths, for a part drawn in its hand.
  RetroDesktopStrokes get strokes => RetroDesktopStrokes.standard;

  final RetroDesktopDensity? _density;

  /// How much room the parts give their contents; unless the app chose one,
  /// the platform's ([RetroDesktopDensity.adaptivePlatformDensity]). Touch
  /// targets keep their floor.
  RetroDesktopDensity get density =>
      _density ?? RetroDesktopDensity.adaptivePlatformDensity;

  /// The faces the type is set in. The sizes are the look's; the reader's
  /// text scale applies on top.
  final RetroDesktopTypeface typeface;

  // Every part's component theme, set through the flat `…Theme:` arguments of [copyWith].
  final RetroDesktopComponentThemes _components;

  /// Instant by default, independently overridable by applications.
  final RetroDesktopMotion motion;

  /// The keyboard focus outline in the current surface's ink.
  final RetroDesktopFocusRing? _focus;

  /// The keyboard focus ring tokens: Platinum's accent ring outside the part,
  /// as wide as the heavy stroke, or Chisel's dotted rectangle inside its face.
  RetroDesktopFocusRing get focus =>
      _focus ??
      switch (appearance) {
        RetroDesktopAppearance.platinum => RetroDesktopFocusRing(
          color: colors.highlight,
          width: strokes.heavy,
          gap: 1,
        ),
        RetroDesktopAppearance.chisel => RetroDesktopFocusRing(
          color: colors.text,
          width: 1,
          gap: 3,
          inside: true,
          dotted: true,
        ),
      };

  /// Responsive class of the available window width.
  RetroDesktopWindowSizeClass get window =>
      RetroDesktopWindowSizeClass.ofWidth(width);

  /// Returns a theme with the requested values replaced.
  RetroDesktopThemeData copyWith({
    RetroDesktopColors? colors,
    RetroDesktopColors? page,
    RetroDesktopMotion? motion,
    RetroDesktopFocusRing? focus,
    RetroDesktopAppearance? appearance,
    RetroDesktopDensity? density,
    RetroDesktopTypeface? typeface,
    RetroDesktopStyle? defaultButtonTheme,
    RetroDesktopStyle? buttonTheme,
    RetroDesktopStyle? textButtonTheme,
    RetroDesktopStyle? iconButtonTheme,
    RetroDesktopStyle? checkboxTheme,
    RetroDesktopStyle? radioTheme,
    RetroDesktopStyle? switchTheme,
    RetroDesktopStyle? textFieldTheme,
    RetroDesktopStyle? chipTheme,
    RetroDesktopStyle? sliderTheme,
    RetroDesktopStyle? segmentedButtonTheme,
    RetroDesktopStyle? cardTheme,
    RetroDesktopStyle? dialogTheme,
    RetroDesktopStyle? sheetTheme,
    RetroDesktopStyle? menuTheme,
    RetroDesktopStyle? snackBarTheme,
    RetroDesktopStyle? tooltipTheme,
    RetroDesktopStyle? badgeTheme,
    RetroDesktopStyle? avatarTheme,
    RetroDesktopStyle? optionTheme,
    RetroDesktopStyle? stepperTheme,
    RetroDesktopStyle? datePickerTheme,
    RetroDesktopStyle? timePickerTheme,
    RetroDesktopStyle? appBarTheme,
    RetroDesktopStyle? navigationBarTheme,
    RetroDesktopStyle? tabBarTheme,
    RetroDesktopStyle? listTileTheme,
    RetroDesktopStyle? disclosureTheme,
    RetroDesktopStyle? progressTheme,
    RetroDesktopStyle? noticeTheme,
    RetroDesktopStyle? dividerTheme,
    RetroDesktopStyle? chartTheme,
    RetroDesktopStyle? toolbarTheme,
    RetroDesktopStyle? wellTheme,
    RetroDesktopStyle? windowTheme,
  }) => RetroDesktopThemeData._(
    id,
    _palette,
    colors ?? this.colors,
    page ?? colors ?? this.page,
    width,
    components: _components.copyWith(
      defaultButton: defaultButtonTheme,
      button: buttonTheme,
      textButton: textButtonTheme,
      iconButton: iconButtonTheme,
      checkbox: checkboxTheme,
      radio: radioTheme,
      switchTheme: switchTheme,
      textField: textFieldTheme,
      chip: chipTheme,
      slider: sliderTheme,
      segmentedButton: segmentedButtonTheme,
      card: cardTheme,
      dialog: dialogTheme,
      sheet: sheetTheme,
      menu: menuTheme,
      snackBar: snackBarTheme,
      tooltip: tooltipTheme,
      badge: badgeTheme,
      avatar: avatarTheme,
      option: optionTheme,
      stepper: stepperTheme,
      datePicker: datePickerTheme,
      timePicker: timePickerTheme,
      appBar: appBarTheme,
      navigationBar: navigationBarTheme,
      tabBar: tabBarTheme,
      listTile: listTileTheme,
      disclosure: disclosureTheme,
      progress: progressTheme,
      notice: noticeTheme,
      divider: dividerTheme,
      chart: chartTheme,
      window: windowTheme,
      well: wellTheme,
      toolbar: toolbarTheme,
    ),
    motion: motion ?? this.motion,
    focus: focus ?? _focus,
    appearance: appearance ?? this.appearance,
    density: density ?? _density,
    typeface: typeface ?? this.typeface,
  );

  /// Blends palettes, size and every component style.
  RetroDesktopThemeData lerp(RetroDesktopThemeData? other, double t) {
    if (other == null || t == 0) return this;
    if (t == 1) return other;
    return RetroDesktopThemeData._(
      t < .5 ? id : other.id,
      t < .5 ? _palette : other._palette,
      RetroDesktopColors.lerp(colors, other.colors, t),
      RetroDesktopColors.lerp(page, other.page, t),
      lerpDouble(width, other.width, t)!,
      components: RetroDesktopComponentThemes.lerp(
        _components,
        other._components,
        t,
      ),
      motion: RetroDesktopMotion.lerp(motion, other.motion, t),
      focus: _focus == null && other._focus == null
          ? null
          : RetroDesktopFocusRing.lerp(focus, other.focus, t),
      appearance: t < .5 ? appearance : other.appearance,
      density: t < .5 ? _density : other._density,
      typeface: t < .5 ? typeface : other.typeface,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RetroDesktopThemeData &&
          id == other.id &&
          colors == other.colors &&
          page == other.page &&
          width == other.width &&
          _components == other._components &&
          motion == other.motion &&
          focus == other.focus &&
          appearance == other.appearance &&
          _density == other._density &&
          typeface == other.typeface;
  @override
  int get hashCode => Object.hash(
    id,
    colors,
    page,
    width,
    _components,
    motion,
    focus,
    appearance,
    _density,
    typeface,
  );
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
    properties.add(
      EnumProperty<RetroDesktopAppearance>('appearance', appearance),
    );
    properties.add(DoubleProperty('width', width));
    properties.add(DiagnosticsProperty<RetroDesktopColors>('colors', colors));
    properties.add(DiagnosticsProperty<RetroDesktopMotion>('motion', motion));
  }

  /// Appearance of the appBar component.
  RetroDesktopStyle get appBarTheme => _components.appBar;

  /// Appearance of the navigationBar component.
  RetroDesktopStyle get navigationBarTheme => _components.navigationBar;

  /// Appearance of the tabBar component.
  RetroDesktopStyle get tabBarTheme => _components.tabBar;

  /// Appearance of the listTile component.
  RetroDesktopStyle get listTileTheme => _components.listTile;

  /// Appearance of the disclosure component.
  RetroDesktopStyle get disclosureTheme => _components.disclosure;

  /// Appearance of the progress component.
  RetroDesktopStyle get progressTheme => _components.progress;

  /// Appearance of the notice component.
  RetroDesktopStyle get noticeTheme => _components.notice;

  /// Appearance of the divider component.
  RetroDesktopStyle get dividerTheme => _components.divider;

  /// Appearance of the chart component.
  RetroDesktopStyle get chartTheme => _components.chart;

  /// The toolbar appearance.
  RetroDesktopStyle get toolbarTheme => _components.toolbar;

  /// The well appearance.
  RetroDesktopStyle get wellTheme => _components.well;

  /// The window appearance.
  RetroDesktopStyle get windowTheme => _components.window;

  /// Appearance of the actButton component.
  RetroDesktopStyle get defaultButtonTheme => _components.defaultButton;

  /// Appearance of the lineButton component.
  RetroDesktopStyle get buttonTheme => _components.button;

  /// Appearance of the quietButton component.
  RetroDesktopStyle get textButtonTheme => _components.textButton;

  /// Appearance of the iconButton component.
  RetroDesktopStyle get iconButtonTheme => _components.iconButton;

  /// Appearance of the checkbox component.
  RetroDesktopStyle get checkboxTheme => _components.checkbox;

  /// Appearance of the radio component.
  RetroDesktopStyle get radioTheme => _components.radio;

  /// Appearance of the switchTheme component.
  RetroDesktopStyle get switchTheme => _components.switchTheme;

  /// Appearance of the textField component.
  RetroDesktopStyle get textFieldTheme => _components.textField;

  /// Appearance of the chip component.
  RetroDesktopStyle get chipTheme => _components.chip;

  /// Appearance of the slider component.
  RetroDesktopStyle get sliderTheme => _components.slider;

  /// Appearance of the segmentedButton component.
  RetroDesktopStyle get segmentedButtonTheme => _components.segmentedButton;

  /// Appearance of the card component.
  RetroDesktopStyle get cardTheme => _components.card;

  /// Appearance of the dialog component.
  RetroDesktopStyle get dialogTheme => _components.dialog;

  /// Appearance of the sheet component.
  RetroDesktopStyle get sheetTheme => _components.sheet;

  /// Appearance of the menu component.
  RetroDesktopStyle get menuTheme => _components.menu;

  /// Appearance of the snackBar component.
  RetroDesktopStyle get snackBarTheme => _components.snackBar;

  /// Appearance of the tooltip component.
  RetroDesktopStyle get tooltipTheme => _components.tooltip;

  /// Appearance of the badge component.
  RetroDesktopStyle get badgeTheme => _components.badge;

  /// Appearance of the avatar component.
  RetroDesktopStyle get avatarTheme => _components.avatar;

  /// Appearance of the option component.
  RetroDesktopStyle get optionTheme => _components.option;

  /// Appearance of the stepper component.
  RetroDesktopStyle get stepperTheme => _components.stepper;

  /// Appearance of the datePicker component.
  RetroDesktopStyle get datePickerTheme => _components.datePicker;

  /// Appearance of the timePicker component.
  RetroDesktopStyle get timePickerTheme => _components.timePicker;
}

class _RetroDesktopScope extends InheritedTheme {
  const _RetroDesktopScope({required this.data, required super.child});
  final RetroDesktopThemeData data;
  @override
  Widget wrap(BuildContext context, Widget child) =>
      _RetroDesktopScope(data: data, child: child);
  @override
  bool updateShouldNotify(_RetroDesktopScope old) => old.data != data;
}

/// Installs Retro Desktop under MaterialApp, CupertinoApp or WidgetsApp.
/// Captured inherited themes preserve nested palettes across overlays and routes.
///
/// ```dart
/// RetroDesktopTheme(data: RetroDesktopThemeData.classic(), child: page)
/// ```
class RetroDesktopTheme extends StatelessWidget {
  /// Styles [child] with [data].
  const RetroDesktopTheme({super.key, required this.data, required this.child});

  /// The palette and component themes.
  final RetroDesktopThemeData data;

  /// The subtree to style.
  final Widget child;

  /// The nearest installed theme, or null.
  static RetroDesktopThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RetroDesktopScope>()?.data;

  /// The nearest installed theme; throws if no theme was installed.
  static RetroDesktopThemeData of(BuildContext context) =>
      maybeOf(context) ??
      (throw FlutterError(
        'No Retro Desktop theme in scope. Install RetroDesktopTheme in the app builder.',
      ));

  /// Preset constructor used by the catalog's emitted app theme file.
  static RetroDesktopThemeData preset(String id, Brightness brightness) =>
      RetroDesktopThemeData.preset(id, brightness);
  @override
  Widget build(BuildContext context) {
    Widget under = child;
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      // A Localizations sets the locale's reading direction below it; the
      // app's own Directionality (right to left under an English locale, say)
      // is kept.
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    final scoped = data.atWidth(MediaQuery.sizeOf(context).width);
    return _RetroDesktopScope(
      data: scoped,
      child: Theme(
        // The host can use SDK Material, Cupertino, or WidgetsApp while an
        // emitted package uses a separate Material implementation internally.
        // ScrollBehavior crosses that boundary and retains host overrides.
        data: _material(
          scoped,
          ScrollConfiguration.of(context).getPlatform(context),
        ),
        child: ScrollConfiguration(
          behavior: _RetroDesktopScrollBehavior(
            ScrollConfiguration.of(context),
            scoped.page,
            scoped.shapes,
            scoped.chisel,
          ),
          child: IconTheme.merge(
            data: IconThemeData(color: scoped.colors.text),
            child: DefaultTextStyle.merge(
              style: scoped.type.body,
              child: under,
            ),
          ),
        ),
      ),
    );
  }

  static ThemeData _material(
    RetroDesktopThemeData theme,
    TargetPlatform platform,
  ) {
    final c = theme.page;
    return ThemeData(
      useMaterial3: true,
      platform: platform,
      brightness: c.dark ? Brightness.dark : Brightness.light,
      visualDensity: VisualDensity.standard,
      fontFamily: retroDesktopFontFamily(theme.typeface.bodyFamily),
      scaffoldBackgroundColor: c.desktop,
      canvasColor: c.platinum,
      colorScheme: ColorScheme(
        brightness: c.dark ? Brightness.dark : Brightness.light,
        primary: c.highlight,
        onPrimary: c.onHighlight,
        secondary: c.highlightDark,
        onSecondary: c.onHighlight,
        error: c.text,
        onError: c.paper,
        surface: c.platinum,
        onSurface: c.text,
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      focusColor: Colors.transparent,
      splashColor: Colors.transparent,
      scrollbarTheme: ScrollbarThemeData(
        radius: theme.shapes.scrollbarTrackRadius,
        thickness: const WidgetStatePropertyAll(6),
        thumbColor: WidgetStatePropertyAll(c.highlight),
        trackColor: WidgetStatePropertyAll(c.platinum),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.text,
        selectionColor: c.highlightContainer,
        selectionHandleColor: c.highlight,
      ),
    );
  }
}

// Keep the app's input policy, but give every host the same desktop decoration.
class _RetroDesktopScrollBehavior extends ScrollBehavior {
  const _RetroDesktopScrollBehavior(
    this.delegate,
    this.colors,
    this.shapes,
    this.chisel,
  );
  final ScrollBehavior delegate;
  final RetroDesktopColors colors;
  final RetroDesktopShapes shapes;
  final bool chisel;

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      delegate.getPlatform(context);
  @override
  Set<PointerDeviceKind> get dragDevices => delegate.dragDevices;
  @override
  Set<LogicalKeyboardKey> get pointerAxisModifiers =>
      delegate.pointerAxisModifiers;
  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) =>
      delegate.getMultitouchDragStrategy(context);
  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      delegate.velocityTrackerBuilder(context);
  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      delegate.getScrollPhysics(context);
  @override
  ScrollViewKeyboardDismissBehavior getKeyboardDismissBehavior(
    BuildContext context,
  ) => delegate.getKeyboardDismissBehavior(context);
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    // Calling the delegate preserves explicit scrollbars:false and platform visibility.
    final decorated = delegate.buildScrollbar(context, child, details);
    if (identical(decorated, child)) return child;
    final motion = RetroDesktopMotion.of(context);
    // A slim overlay in both appearances: a classic bar with arrow buttons would
    // take its width out of every scrollable. Platinum's thumb is the accent;
    // Chisel's is a grey square outlined in ink.
    return RawScrollbar(
      controller: details.controller,
      shape: chisel
          ? shapes.full.copyWith(side: BorderSide(color: colors.outline))
          : shapes.full,
      trackRadius: shapes.scrollbarTrackRadius,
      thickness: chisel ? 8 : 6,
      thumbColor: chisel ? colors.platinumDark : colors.highlight,
      trackColor: colors.platinum,
      trackBorderColor: colors.control,
      fadeDuration: motion.state,
      pressDuration: motion.press,
      child: child,
    );
  }

  @override
  bool shouldNotify(_RetroDesktopScrollBehavior oldDelegate) =>
      colors != oldDelegate.colors ||
      shapes != oldDelegate.shapes ||
      chisel != oldDelegate.chisel ||
      delegate != oldDelegate.delegate ||
      delegate.shouldNotify(oldDelegate.delegate);
}

/// Transitions between themes, with instant changes by default.
///
/// ```dart
/// AnimatedRetroDesktopTheme(data: RetroDesktopThemeData.berry(), child: page)
/// ```
class AnimatedRetroDesktopTheme extends StatelessWidget {
  /// Interpolates the theme for [child].
  const AnimatedRetroDesktopTheme({
    super.key,
    required this.data,
    required this.child,
    this.duration = Duration.zero,
    this.curve = Curves.linear,
    this.onEnd,
  });

  /// Target theme.
  final RetroDesktopThemeData data;

  /// Styled subtree.
  final Widget child;

  /// Transition duration; ignored under Reduce Motion.
  final Duration duration;

  /// Transition curve.
  final Curve curve;

  /// Called when the transition finishes.
  final VoidCallback? onEnd;
  @override
  Widget build(BuildContext context) =>
      TweenAnimationBuilder<RetroDesktopThemeData>(
        tween: RetroDesktopThemeDataTween(end: data),
        duration: RetroDesktopMotion.durationOf(context, duration),
        curve: curve,
        onEnd: onEnd,
        builder: (context, value, child) =>
            RetroDesktopTheme(data: value, child: child!),
        child: child,
      );
}

/// A value tween for a complete Retro Desktop theme.
class RetroDesktopThemeDataTween extends Tween<RetroDesktopThemeData> {
  /// Interpolates from [begin] to [end].
  RetroDesktopThemeDataTween({super.begin, super.end});
  @override
  RetroDesktopThemeData lerp(double t) => (begin ?? end!).lerp(end, t);
}

/// Re-scopes everything under it to the highlight's palette: a selected row does this, so what stands in it reads.
///
/// ```dart
/// RetroDesktopOnHighlight(child: const Text('Selected item'))
/// ```
class RetroDesktopOnHighlight extends StatelessWidget {
  /// Creates a [RetroDesktopOnHighlight].
  const RetroDesktopOnHighlight({super.key, required this.child});

  /// The widget displayed inside this part.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context).onHighlight;
    return _RetroDesktopScope(
      data: t,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: t.colors.text),
        child: IconTheme.merge(
          data: IconThemeData(color: t.colors.text),
          child: child,
        ),
      ),
    );
  }
}

/// Internal, not exported: [child] back in [data], the theme from outside a lit row, so a control in a chosen row keeps
/// its own face (on the highlight's theme a task's checkbox lost its paper and read as a hollow outline).
class RetroDesktopOffHighlight extends StatelessWidget {
  /// Puts [child] back in [data].
  const RetroDesktopOffHighlight({
    super.key,
    required this.data,
    required this.child,
  });

  /// The theme from outside the lit row.
  final RetroDesktopThemeData data;

  /// The control.
  final Widget child;
  @override
  Widget build(BuildContext context) => _RetroDesktopScope(
    data: data,
    child: DefaultTextStyle.merge(
      style: TextStyle(color: data.colors.text),
      child: IconTheme.merge(
        data: IconThemeData(color: data.colors.text),
        child: child,
      ),
    ),
  );
}

/// `context.retroDesktopTheme`: the theme in scope.
extension RetroDesktopThemeContext on BuildContext {
  /// Reads the current Retro Desktop theme.
  RetroDesktopThemeData get retroDesktopTheme => RetroDesktopTheme.of(this);
}

RetroDesktopColors _retroDesktopColorsFrom({
  required Color primary,
  required Brightness brightness,
  Color? surface,
}) {
  final base = RetroDesktopThemeData.classic(brightness).colors;
  final dark = brightness == Brightness.dark;
  final supplied = Color.alphaBlend(
    surface ?? base.platinum,
    dark ? const Color(0xff202020) : const Color(0xffdddddd),
  );
  final pole = dark ? const Color(0xff000000) : const Color(0xffffffff);
  var machine = supplied;
  for (var step = 0; step <= 100; step++) {
    machine = Color.lerp(supplied, pole, step / 100)!;
    final luminance = machine.computeLuminance();
    if (dark ? luminance <= .08 : luminance >= .65) break;
  }
  final paper = Color.lerp(
    machine,
    dark ? const Color(0xff000000) : const Color(0xffffffff),
    dark ? .5 : .9,
  )!;
  final ink = dark ? const Color(0xfffafafa) : const Color(0xff111111);
  final plat2 = Color.lerp(machine, paper, .3)!;
  final plat3 = Color.lerp(machine, ink, .12)!;
  final paper2 = Color.lerp(paper, machine, .35)!;
  final grounds = [machine, plat2, plat3, paper, paper2];
  double contrast(Color a, Color b) {
    double ratio(Color a, Color b) {
      final x = a.computeLuminance(), y = b.computeLuminance();
      return (x > y ? x + .05 : y + .05) / (x > y ? y + .05 : x + .05);
    }

    // Both interpolation precision and rendered eight-bit pixels must pass.
    final raw = ratio(a, b);
    final quantized = ratio(Color(a.toARGB32()), Color(b.toARGB32()));
    return raw < quantized ? raw : quantized;
  }

  Color readable(Color value, {double minimum = 4.5}) {
    for (var step = 0; step <= 100; step++) {
      final color = Color.lerp(value, ink, step / 100)!;
      if (grounds.every((ground) => contrast(color, ground) >= minimum)) {
        return color;
      }
    }
    return ink;
  }

  final accent = readable(Color.alphaBlend(primary, machine));
  Color mix(Color a, Color b, double t) => Color.lerp(a, b, t)!;
  Color on(Color color) {
    final luminance = color.computeLuminance();
    return (luminance + .05) / .05 >= 1.05 / (luminance + .05)
        ? const Color(0xff000000)
        : const Color(0xffffffff);
  }

  final edge = readable(mix(ink, machine, .2), minimum: 3);
  return base.copyWith(
    desktop: mix(machine, accent, .16),
    desktopThreadLight: mix(machine, accent, .18),
    desktopThreadDark: mix(machine, accent, .10),
    desktopGlow: mix(machine, accent, .28),
    platinum: machine,
    platinumLight: plat2,
    platinumDark: plat3,
    bevelLight: mix(machine, const Color(0xffffffff), .75),
    bevelDark: mix(machine, const Color(0xff000000), .35),
    bevelDarker: mix(machine, const Color(0xff000000), .55),
    outline: edge,
    control: edge,
    controlFace: paper,
    paper: paper,
    paperDim: paper2,
    divider: mix(ink, paper, .7),
    text: ink,
    textSecondary: readable(mix(ink, paper, .15)),
    textTertiary: readable(mix(ink, paper, .3)),
    highlight: accent,
    highlightDark: accent,
    highlightMid: mix(accent, paper, .4),
    highlightContainer: mix(accent, paper, .85),
    onHighlight: on(accent),
    highlightFaceTop: accent,
    highlightFaceMiddle: accent,
    highlightFaceBottom: accent,
    thumbTop: mix(machine, paper, .5),
    thumbBottom: machine,
    hatch: accent,
    glow: accent.withValues(alpha: .18),
    markLabel: machine,
    iconPage: paper,
    iconFold: machine,
    iconLine: mix(ink, paper, .35),
    titleBoxDark: mix(machine, paper, .5),
    titleBoxLight: mix(machine, ink, .2),
    binderRingLight: mix(machine, paper, .7),
    binderRingDark: mix(machine, ink, .45),
    pixelOutline: edge,
    tones: [for (final tone in base.tones) readable(tone, minimum: 3)],
  );
}
