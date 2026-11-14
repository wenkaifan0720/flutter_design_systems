// Comic's tokens: the comic page in five print runs. `ComicTheme.of(context)` is the only way in.
// Every colour with a hue lives here. Each means one thing: `caption` is the narrator's lamp, `act` is you and the thing to
// press, `shade` is the group and the halftone, `drama` is sound effects and the burst's back plate, `line` is the contour.
import 'dart:ui' show lerpDouble;
import 'dart:math' as math;

import 'tones.dart';
import 'component_themes.dart';
import 'shapes.dart';
import 'knobs.dart';
import 'fonts.dart';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

/// The width where the phone layout becomes the 12-column desktop layout.
const double comicDeskWidth = 1024;

/// Material's window classes, by the width the page is given: compact under 600, medium under 840, expanded under 1200,
/// large from 1200. Comic's 12-column desktop starts at [comicDeskWidth], inside expanded.
enum ComicWindowSizeClass {
  /// Under 600 wide: a phone.
  compact,

  /// 600 to 840: a large phone held across, a small tablet.
  medium,

  /// 840 to 1200: a tablet, a small window.
  expanded,

  /// 1200 and up: a desktop.
  large;

  /// The class of a page [width] wide.
  static ComicWindowSizeClass ofWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : width < 1200
      ? expanded
      : large;

  /// The class of the page at [context].
  static ComicWindowSizeClass of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);
}

/// Comic's motion: a page being turned, quick and snappy, with a small overshoot where a panel pops. A press lands in
/// [press]; a control's state (a switch's thumb, a check inked in, a selected segment) moves in [state]; what moves across
/// the page in [move]; what pops over it in [raise] (a dialog, a menu), or [travel] from the page's foot (a sheet), and
/// leaves in [leave]. Under Reduce Motion, and in every shot, each is a cut: read them through [of] or [durationOf].
@immutable
class ComicMotion {
  /// Creates a [ComicMotion].
  const ComicMotion({
    this.press = const Duration(milliseconds: 80),
    this.state = const Duration(milliseconds: 120),
    this.move = const Duration(milliseconds: 160),
    this.raise = const Duration(milliseconds: 200),
    this.travel = const Duration(milliseconds: 260),
    this.leave = const Duration(milliseconds: 110),
    this.spinner = const Duration(milliseconds: 1000),
    this.progress = const Duration(milliseconds: 1100),
    this.pulse = const Duration(milliseconds: 900),
    this.enter = Curves.easeOutBack,
    this.exit = Curves.easeInCubic,
    this.standard = Curves.easeInOutCubic,
  });

  /// A press landing.
  final Duration press;

  /// A control turning to its new state: a tick inked in, a switch thrown.
  final Duration state;

  /// Something moving within the page: a plate to the selected tab.
  final Duration move;

  /// A raised surface arriving: a menu, a dialog.
  final Duration raise;

  /// A sheet arriving from the page's foot.
  final Duration travel;

  /// Something leaving: quicker than it came.
  final Duration leave;

  /// One turn of an indeterminate circular indicator.
  final Duration spinner;

  /// One sweep of an indeterminate progress strip.
  final Duration progress;

  /// One fade of a skeleton placeholder.
  final Duration pulse;

  /// How something arrives, how it goes, and how it moves between two places.
  final Curve enter, exit, standard;

  /// The same tokens with every duration a cut.
  static const ComicMotion still = ComicMotion(
    press: Duration.zero,
    state: Duration.zero,
    move: Duration.zero,
    raise: Duration.zero,
    travel: Duration.zero,
    leave: Duration.zero,
    spinner: Duration.zero,
    progress: Duration.zero,
    pulse: Duration.zero,
  );

  /// The tokens in force at [context]: [still] under Reduce Motion (`MediaQuery.disableAnimationsOf`).
  static ComicMotion of(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? still
      : ComicTheme.maybeOf(context)?.motion ?? const ComicMotion();

  /// This with the supplied timing or curves replaced.
  ComicMotion copyWith({
    Duration? press,
    Duration? state,
    Duration? move,
    Duration? raise,
    Duration? travel,
    Duration? leave,
    Duration? spinner,
    Duration? progress,
    Duration? pulse,
    Curve? enter,
    Curve? exit,
    Curve? standard,
  }) => ComicMotion(
    press: press ?? this.press,
    state: state ?? this.state,
    move: move ?? this.move,
    raise: raise ?? this.raise,
    travel: travel ?? this.travel,
    leave: leave ?? this.leave,
    spinner: spinner ?? this.spinner,
    progress: progress ?? this.progress,
    pulse: pulse ?? this.pulse,
    enter: enter ?? this.enter,
    exit: exit ?? this.exit,
    standard: standard ?? this.standard,
  );

  /// Timings interpolate; curves switch at the midpoint.
  static ComicMotion lerp(ComicMotion a, ComicMotion b, double t) {
    Duration d(Duration x, Duration y) => Duration(
      microseconds: lerpDouble(x.inMicroseconds, y.inMicroseconds, t)!.round(),
    );
    return ComicMotion(
      press: d(a.press, b.press),
      state: d(a.state, b.state),
      move: d(a.move, b.move),
      raise: d(a.raise, b.raise),
      travel: d(a.travel, b.travel),
      leave: d(a.leave, b.leave),
      spinner: d(a.spinner, b.spinner),
      progress: d(a.progress, b.progress),
      pulse: d(a.pulse, b.pulse),
      enter: t < .5 ? a.enter : b.enter,
      exit: t < .5 ? a.exit : b.exit,
      standard: t < .5 ? a.standard : b.standard,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ComicMotion &&
      other.press == press &&
      other.state == state &&
      other.move == move &&
      other.raise == raise &&
      other.travel == travel &&
      other.leave == leave &&
      other.spinner == spinner &&
      other.progress == progress &&
      other.pulse == pulse &&
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
    spinner,
    progress,
    pulse,
    enter,
    exit,
    standard,
  );

  /// [d], or a cut where motion is off at [context].
  static Duration durationOf(BuildContext context, Duration d) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? Duration.zero
      : d;
}

/// The keyboard's focus ring: a [width] line [gap] outside the control's own outline, in [color], which reads 3:1 on
/// the page, card and control grounds.
@immutable
class ComicFocusRing {
  /// Creates a [ComicFocusRing].
  const ComicFocusRing({required this.color, this.width = 3, this.gap = 3});

  /// The ring's colour.
  final Color color;

  /// The ring's line, in logical pixels.
  final double width;

  /// The space between the control's outline and the ring.
  final double gap;

  /// This ring with the named values changed.
  ComicFocusRing copyWith({Color? color, double? width, double? gap}) =>
      ComicFocusRing(
        color: color ?? this.color,
        width: width ?? this.width,
        gap: gap ?? this.gap,
      );

  /// The ring [t] of the way from [a] to [b].
  static ComicFocusRing lerp(ComicFocusRing a, ComicFocusRing b, double t) =>
      ComicFocusRing(
        color: Color.lerp(a.color, b.color, t)!,
        width: lerpDouble(a.width, b.width, t)!,
        gap: lerpDouble(a.gap, b.gap, t)!,
      );

  @override
  bool operator ==(Object other) =>
      other is ComicFocusRing &&
      other.color == color &&
      other.width == width &&
      other.gap == gap;

  @override
  int get hashCode => Object.hash(color, width, gap);
}

/// Colours. Grounds first, then what stands on them.
@immutable
class ComicColors with Diagnosticable {
  /// Creates a [ComicColors].
  const ComicColors({
    this.status,
    required this.brightness,
    required this.background,
    required this.grain,
    required this.card,
    required this.inset,
    required this.outline,
    required this.text,
    required this.textSecondary,
    required this.divider,
    required this.caption,
    required this.onCaption,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.primaryLargeText,
    required this.currentUserTint,
    required this.shade,
    required this.onShade,
    required this.shadeText,
    required this.shadeTint,
    required this.drama,
    required this.paper,
    required this.onPaper,
    required this.onPaperSecondary,
    required this.control,
    required this.hint,
    required this.track,
    required this.unlit,
    required this.series,
    required this.dotTint,
    required this.currentUserDot,
    required this.lampDot,
    required this.cover,
    required this.coverRay,
    required this.coverDot,
    required this.coverDotSecondary,
    required this.head,
    required this.headRing,
    required this.currentUserHead,
    required this.currentUserHeadRing,
    required this.monogramSecondary,
    required this.monogramTertiary,
    required this.art1,
    required this.art2,
    required this.art3,
    required this.art4,
    required this.artDot,
    required this.art4Dot,
    required this.nightLine,
    required this.sky,
    required this.skyDot,
    required this.sun,
    required this.sunDot,
    required this.hill,
    required this.lake,
    required this.lakeDot,
    required this.pine,
    required this.snow,
    required this.flake,
    required this.window,
    required this.smoke,
    required this.wood,
    required this.chili,
    required this.check,
    required this.shadow,
    required this.potDot,
    required this.amber,
    required this.ray,
    required this.highlight,
  });

  /// The dimmed ground behind modal surfaces.
  Color get scrim => const Color(0x99000000);

  /// Semantic status inks on the current panel ground.
  ComicTones get tones => status ?? (dark ? ComicTones.dark : ComicTones.light);

  /// Custom semantic inks; null uses the appearance defaults.
  final ComicTones? status;

  /// Whether these colours are for a light page or a dark one, as `ThemeData.brightness`.
  final Brightness brightness;

  /// Newsprint or the black gutter; its grain; a panel's fill; a quiet well inside a panel.
  final Color background, grain, card, inset;

  /// The contour. By day it reads everywhere. At night it's black, the edge of a lit fill: a control at night reads by
  /// its fill ([control]), not by this line.
  final Color outline;

  /// Words on a panel; quieter words; the hairline between rows.
  final Color text, textSecondary, divider;

  /// The narrator's lamp: captions, the hero burst, today, the leader. [onCaption] is the letters on it.
  final Color caption, onCaption;

  /// You, and the thing to press. [primary] is the fill and [onPrimary] its letters; [primaryText] is the same meaning as words on a
  /// panel; [currentUserTint] is the pale ground of what's yours.
  final Color primary, onPrimary, primaryText, currentUserTint;

  /// You, as big lettering: stays lit on dots, where [primaryText] gives way to the ink. Large type only, its bar is 3.
  final Color primaryLargeText;

  /// The group and the halftone: bars, links, cover. [onShade] is letters on it; [shadeText] the same meaning as words.
  final Color shade, onShade, shadeText, shadeTint;

  /// Drama: the burst's back plate and sound effects. Large or outlined only, and never a status colour.
  final Color drama;

  /// Balloons, corner boxes, stamps: paper at any hour. [onPaper] and [onPaperSecondary] are the words on it.
  final Color paper, onPaper, onPaperSecondary;

  /// A control's fill (paper at night, the lit thing); [hint] the words waiting in a field.
  final Color control, hint;

  /// An empty bar's ground.
  final Color track;

  /// A mark not lit: a step not reached, a cell not begun. By day the well inside its contour; at night the contour is lost
  /// in the dark, so it's a lit grey that reads by itself, with [onPaper] letters.
  final Color unlit;

  /// A chart's own inks, in order: a pie's slices and its key. Each reads on the page and stands apart from the others. At
  /// night the quiet ones are lit (a grey, the act's pale, paper) where the day's would sink into the dark.
  final List<Color> series;

  /// The dots of a shaded panel, and of a panel that's yours.
  final Color dotTint, currentUserDot;

  /// The drama's dots where they stand on the lamp: a lead bar's fill, the month that's now.
  final Color lampDot;

  /// The cover: its ground, the action lines and its two halftones.
  final Color cover, coverRay, coverDot, coverDotSecondary;

  /// A small head's fill and ring, plain and yours; a monogram's other two fills.
  final Color head,
      headRing,
      currentUserHead,
      currentUserHeadRing,
      monogramSecondary,
      monogramTertiary;

  /// The four art grounds behind a drawing, and the dots laid over them.
  final Color art1, art2, art3, art4, artDot, art4Dot;

  /// A loose line that must read on a night ground: the contour by day, the lit colour at night.
  final Color nightLine;

  /// Scene inks.
  final Color sky, skyDot, sun, sunDot, hill, lake, lakeDot, pine, snow, flake;

  /// [window]: the adaptive window classification. [smoke]: the smoke ink used by the drawing. [wood]: the wood ink used by the drawing. [chili]: the chili ink used by the drawing. [check]: whether to show the completion check. [shadow]: the ink color of the lettering's hard offset impression. [potDot]: the pot dot ink used by the drawing. [amber]: the amber ink used by the drawing. [ray]: the ray ink used by the drawing.
  final Color window, smoke, wood, chili, check, shadow, potDot, amber, ray;

  /// Whether this entry is emphasized.
  final Color highlight;

  /// Copies the palette, replacing only supplied roles.
  ComicColors copyWith({
    ComicTones? status,
    Brightness? brightness,
    Color? background,
    Color? grain,
    Color? card,
    Color? inset,
    Color? outline,
    Color? text,
    Color? textSecondary,
    Color? divider,
    Color? caption,
    Color? onCaption,
    Color? primary,
    Color? onPrimary,
    Color? primaryText,
    Color? primaryLargeText,
    Color? currentUserTint,
    Color? shade,
    Color? onShade,
    Color? shadeText,
    Color? shadeTint,
    Color? drama,
    Color? paper,
    Color? onPaper,
    Color? onPaperSecondary,
    Color? control,
    Color? hint,
    Color? track,
    Color? unlit,
    List<Color>? series,
    Color? dotTint,
    Color? currentUserDot,
    Color? lampDot,
    Color? cover,
    Color? coverRay,
    Color? coverDot,
    Color? coverDotSecondary,
    Color? head,
    Color? headRing,
    Color? currentUserHead,
    Color? currentUserHeadRing,
    Color? monogramSecondary,
    Color? monogramTertiary,
    Color? art1,
    Color? art2,
    Color? art3,
    Color? art4,
    Color? artDot,
    Color? art4Dot,
    Color? nightLine,
    Color? sky,
    Color? skyDot,
    Color? sun,
    Color? sunDot,
    Color? hill,
    Color? lake,
    Color? lakeDot,
    Color? pine,
    Color? snow,
    Color? flake,
    Color? window,
    Color? smoke,
    Color? wood,
    Color? chili,
    Color? check,
    Color? shadow,
    Color? potDot,
    Color? amber,
    Color? ray,
    Color? highlight,
  }) => ComicColors(
    status: status ?? this.status,
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    grain: grain ?? this.grain,
    card: card ?? this.card,
    inset: inset ?? this.inset,
    outline: outline ?? this.outline,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    divider: divider ?? this.divider,
    caption: caption ?? this.caption,
    onCaption: onCaption ?? this.onCaption,
    primary: primary ?? this.primary,
    onPrimary: onPrimary ?? this.onPrimary,
    primaryText: primaryText ?? this.primaryText,
    primaryLargeText: primaryLargeText ?? this.primaryLargeText,
    currentUserTint: currentUserTint ?? this.currentUserTint,
    shade: shade ?? this.shade,
    onShade: onShade ?? this.onShade,
    shadeText: shadeText ?? this.shadeText,
    shadeTint: shadeTint ?? this.shadeTint,
    drama: drama ?? this.drama,
    paper: paper ?? this.paper,
    onPaper: onPaper ?? this.onPaper,
    onPaperSecondary: onPaperSecondary ?? this.onPaperSecondary,
    control: control ?? this.control,
    hint: hint ?? this.hint,
    track: track ?? this.track,
    unlit: unlit ?? this.unlit,
    series: series ?? this.series,
    dotTint: dotTint ?? this.dotTint,
    currentUserDot: currentUserDot ?? this.currentUserDot,
    lampDot: lampDot ?? this.lampDot,
    cover: cover ?? this.cover,
    coverRay: coverRay ?? this.coverRay,
    coverDot: coverDot ?? this.coverDot,
    coverDotSecondary: coverDotSecondary ?? this.coverDotSecondary,
    head: head ?? this.head,
    headRing: headRing ?? this.headRing,
    currentUserHead: currentUserHead ?? this.currentUserHead,
    currentUserHeadRing: currentUserHeadRing ?? this.currentUserHeadRing,
    monogramSecondary: monogramSecondary ?? this.monogramSecondary,
    monogramTertiary: monogramTertiary ?? this.monogramTertiary,
    art1: art1 ?? this.art1,
    art2: art2 ?? this.art2,
    art3: art3 ?? this.art3,
    art4: art4 ?? this.art4,
    artDot: artDot ?? this.artDot,
    art4Dot: art4Dot ?? this.art4Dot,
    nightLine: nightLine ?? this.nightLine,
    sky: sky ?? this.sky,
    skyDot: skyDot ?? this.skyDot,
    sun: sun ?? this.sun,
    sunDot: sunDot ?? this.sunDot,
    hill: hill ?? this.hill,
    lake: lake ?? this.lake,
    lakeDot: lakeDot ?? this.lakeDot,
    pine: pine ?? this.pine,
    snow: snow ?? this.snow,
    flake: flake ?? this.flake,
    window: window ?? this.window,
    smoke: smoke ?? this.smoke,
    wood: wood ?? this.wood,
    chili: chili ?? this.chili,
    check: check ?? this.check,
    shadow: shadow ?? this.shadow,
    potDot: potDot ?? this.potDot,
    amber: amber ?? this.amber,
    ray: ray ?? this.ray,
    highlight: highlight ?? this.highlight,
  );

  /// Between [a] and [b]: every colour blends; the appearance flips at the middle.
  static ComicColors lerp(ComicColors a, ComicColors b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return ComicColors(
      status: ComicTones.lerp(a.tones, b.tones, t),
      brightness: t < .5 ? a.brightness : b.brightness,
      background: Color.lerp(a.background, b.background, t)!,
      grain: Color.lerp(a.grain, b.grain, t)!,
      card: Color.lerp(a.card, b.card, t)!,
      inset: Color.lerp(a.inset, b.inset, t)!,
      outline: Color.lerp(a.outline, b.outline, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      divider: Color.lerp(a.divider, b.divider, t)!,
      caption: Color.lerp(a.caption, b.caption, t)!,
      onCaption: Color.lerp(a.onCaption, b.onCaption, t)!,
      primary: Color.lerp(a.primary, b.primary, t)!,
      onPrimary: Color.lerp(a.onPrimary, b.onPrimary, t)!,
      primaryText: Color.lerp(a.primaryText, b.primaryText, t)!,
      primaryLargeText: Color.lerp(a.primaryLargeText, b.primaryLargeText, t)!,
      currentUserTint: Color.lerp(a.currentUserTint, b.currentUserTint, t)!,
      shade: Color.lerp(a.shade, b.shade, t)!,
      onShade: Color.lerp(a.onShade, b.onShade, t)!,
      shadeText: Color.lerp(a.shadeText, b.shadeText, t)!,
      shadeTint: Color.lerp(a.shadeTint, b.shadeTint, t)!,
      drama: Color.lerp(a.drama, b.drama, t)!,
      paper: Color.lerp(a.paper, b.paper, t)!,
      onPaper: Color.lerp(a.onPaper, b.onPaper, t)!,
      onPaperSecondary: Color.lerp(a.onPaperSecondary, b.onPaperSecondary, t)!,
      control: Color.lerp(a.control, b.control, t)!,
      hint: Color.lerp(a.hint, b.hint, t)!,
      track: Color.lerp(a.track, b.track, t)!,
      unlit: Color.lerp(a.unlit, b.unlit, t)!,
      series: <Color>[
        for (var i = 0; i < a.series.length; i++)
          Color.lerp(
            a.series[i],
            i < b.series.length ? b.series[i] : a.series[i],
            t,
          )!,
      ],
      dotTint: Color.lerp(a.dotTint, b.dotTint, t)!,
      currentUserDot: Color.lerp(a.currentUserDot, b.currentUserDot, t)!,
      lampDot: Color.lerp(a.lampDot, b.lampDot, t)!,
      cover: Color.lerp(a.cover, b.cover, t)!,
      coverRay: Color.lerp(a.coverRay, b.coverRay, t)!,
      coverDot: Color.lerp(a.coverDot, b.coverDot, t)!,
      coverDotSecondary: Color.lerp(
        a.coverDotSecondary,
        b.coverDotSecondary,
        t,
      )!,
      head: Color.lerp(a.head, b.head, t)!,
      headRing: Color.lerp(a.headRing, b.headRing, t)!,
      currentUserHead: Color.lerp(a.currentUserHead, b.currentUserHead, t)!,
      currentUserHeadRing: Color.lerp(
        a.currentUserHeadRing,
        b.currentUserHeadRing,
        t,
      )!,
      monogramSecondary: Color.lerp(
        a.monogramSecondary,
        b.monogramSecondary,
        t,
      )!,
      monogramTertiary: Color.lerp(a.monogramTertiary, b.monogramTertiary, t)!,
      art1: Color.lerp(a.art1, b.art1, t)!,
      art2: Color.lerp(a.art2, b.art2, t)!,
      art3: Color.lerp(a.art3, b.art3, t)!,
      art4: Color.lerp(a.art4, b.art4, t)!,
      artDot: Color.lerp(a.artDot, b.artDot, t)!,
      art4Dot: Color.lerp(a.art4Dot, b.art4Dot, t)!,
      nightLine: Color.lerp(a.nightLine, b.nightLine, t)!,
      sky: Color.lerp(a.sky, b.sky, t)!,
      skyDot: Color.lerp(a.skyDot, b.skyDot, t)!,
      sun: Color.lerp(a.sun, b.sun, t)!,
      sunDot: Color.lerp(a.sunDot, b.sunDot, t)!,
      hill: Color.lerp(a.hill, b.hill, t)!,
      lake: Color.lerp(a.lake, b.lake, t)!,
      lakeDot: Color.lerp(a.lakeDot, b.lakeDot, t)!,
      pine: Color.lerp(a.pine, b.pine, t)!,
      snow: Color.lerp(a.snow, b.snow, t)!,
      flake: Color.lerp(a.flake, b.flake, t)!,
      window: Color.lerp(a.window, b.window, t)!,
      smoke: Color.lerp(a.smoke, b.smoke, t)!,
      wood: Color.lerp(a.wood, b.wood, t)!,
      chili: Color.lerp(a.chili, b.chili, t)!,
      check: Color.lerp(a.check, b.check, t)!,
      shadow: Color.lerp(a.shadow, b.shadow, t)!,
      potDot: Color.lerp(a.potDot, b.potDot, t)!,
      amber: Color.lerp(a.amber, b.amber, t)!,
      ray: Color.lerp(a.ray, b.ray, t)!,
      highlight: Color.lerp(a.highlight, b.highlight, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicColors &&
          other.tones == tones &&
          other.brightness == brightness &&
          other.background == background &&
          other.grain == grain &&
          other.card == card &&
          other.inset == inset &&
          other.outline == outline &&
          other.text == text &&
          other.textSecondary == textSecondary &&
          other.divider == divider &&
          other.caption == caption &&
          other.onCaption == onCaption &&
          other.primary == primary &&
          other.onPrimary == onPrimary &&
          other.primaryText == primaryText &&
          other.primaryLargeText == primaryLargeText &&
          other.currentUserTint == currentUserTint &&
          other.shade == shade &&
          other.onShade == onShade &&
          other.shadeText == shadeText &&
          other.shadeTint == shadeTint &&
          other.drama == drama &&
          other.paper == paper &&
          other.onPaper == onPaper &&
          other.onPaperSecondary == onPaperSecondary &&
          other.control == control &&
          other.hint == hint &&
          other.track == track &&
          other.unlit == unlit &&
          listEquals(other.series, series) &&
          other.dotTint == dotTint &&
          other.currentUserDot == currentUserDot &&
          other.lampDot == lampDot &&
          other.cover == cover &&
          other.coverRay == coverRay &&
          other.coverDot == coverDot &&
          other.coverDotSecondary == coverDotSecondary &&
          other.head == head &&
          other.headRing == headRing &&
          other.currentUserHead == currentUserHead &&
          other.currentUserHeadRing == currentUserHeadRing &&
          other.monogramSecondary == monogramSecondary &&
          other.monogramTertiary == monogramTertiary &&
          other.art1 == art1 &&
          other.art2 == art2 &&
          other.art3 == art3 &&
          other.art4 == art4 &&
          other.artDot == artDot &&
          other.art4Dot == art4Dot &&
          other.nightLine == nightLine &&
          other.sky == sky &&
          other.skyDot == skyDot &&
          other.sun == sun &&
          other.sunDot == sunDot &&
          other.hill == hill &&
          other.lake == lake &&
          other.lakeDot == lakeDot &&
          other.pine == pine &&
          other.snow == snow &&
          other.flake == flake &&
          other.window == window &&
          other.smoke == smoke &&
          other.wood == wood &&
          other.chili == chili &&
          other.check == check &&
          other.shadow == shadow &&
          other.potDot == potDot &&
          other.amber == amber &&
          other.ray == ray &&
          other.highlight == highlight;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    tones,
    brightness,
    background,
    grain,
    card,
    inset,
    outline,
    text,
    textSecondary,
    divider,
    caption,
    onCaption,
    primary,
    onPrimary,
    primaryText,
    primaryLargeText,
    currentUserTint,
    shade,
    onShade,
    shadeText,
    shadeTint,
    drama,
    paper,
    onPaper,
    onPaperSecondary,
    control,
    hint,
    track,
    unlit,
    ...series,
    dotTint,
    currentUserDot,
    lampDot,
    cover,
    coverRay,
    coverDot,
    coverDotSecondary,
    head,
    headRing,
    currentUserHead,
    currentUserHeadRing,
    monogramSecondary,
    monogramTertiary,
    art1,
    art2,
    art3,
    art4,
    artDot,
    art4Dot,
    nightLine,
    sky,
    skyDot,
    sun,
    sunDot,
    hill,
    lake,
    lakeDot,
    pine,
    snow,
    flake,
    window,
    smoke,
    wood,
    chili,
    check,
    shadow,
    potDot,
    amber,
    ray,
    highlight,
  ]);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    properties.add(ColorProperty('background', background));
    properties.add(ColorProperty('card', card));
    properties.add(ColorProperty('text', text));
    properties.add(ColorProperty('outline', outline));
    properties.add(ColorProperty('primary', primary));
    properties.add(ColorProperty('caption', caption));
    properties.add(ColorProperty('shade', shade));
    properties.add(ColorProperty('drama', drama));
  }

  /// A sound effect's fill on an art ground, 1 to 4: drama where it shows, the lamp or paper where it wouldn't.
  Color sfxOn(int background) => switch (background) {
    1 => dark ? caption : drama,
    2 => caption,
    3 => dark ? caption : paper,
    4 => caption,
    _ => drama,
  };

  /// The art ground, 1 to 4.
  Color artGround(int background) => switch (background) {
    1 => art1,
    2 => art2,
    3 => art3,
    _ => art4,
  };
}

/// Skin tones and their halftone shade, for the drawn cast. They belong to the people drawn, so no preset moves them.
class ComicSkin {
  const ComicSkin._();

  /// Base inks for fictional skin tones.
  static const List<Color> tones = [
    Color(0xFF8B5A3C),
    Color(0xFFF1C7A1),
    Color(0xFFF5D0B3),
    Color(0xFFC98A5C),
    Color(0xFFA8704A),
    Color(0xFFEFC39C),
  ];

  /// Shaded inks corresponding to the fictional skin tones.
  static const List<Color> shades = [
    Color(0xFF6A4128),
    Color(0xFFD9A27A),
    Color(0xFFE2AD8A),
    Color(0xFFA56A40),
    Color(0xFF875334),
    Color(0xFFD49E74),
  ];

  /// The freckle ink used by fictional portraits.
  static const Color freckle = Color(0xFFC47A55);
}

/// What a designer picks for one appearance of a print run. The rest follows in [_dress].
class _Seed {
  const _Seed({
    required this.background,
    required this.card,
    required this.inset,
    required this.text,
    required this.textSecondary,
    required this.caption,
    required this.primary,
    required this.onPrimary,
    required this.primaryText,
    required this.currentUserTint,
    required this.shade,
    required this.onShade,
    required this.shadeText,
    required this.shadeTint,
    required this.drama,
    this.outline = const Color(0xFF15121C),
    this.onCaption = const Color(0xFF15121C),
    this.paper = const Color(0xFFFFFCF4),
    this.onPaper = const Color(0xFF15121C),
    this.onPaperSecondary = const Color(0xFF5A5262),
    this.hint = const Color(0xFF6B6273),
    this.coverRay,
    this.lampDot,
    this.art1,
    this.art3,
    this.art4,
    this.currentUserDot,
    this.track,
    this.scene,
  });
  final Color background,
      card,
      inset,
      text,
      textSecondary,
      caption,
      primary,
      onPrimary,
      primaryText;
  final Color currentUserTint,
      shade,
      onShade,
      shadeText,
      shadeTint,
      drama,
      outline;
  final Color onCaption, paper, onPaper, onPaperSecondary, hint;
  final Color? coverRay, lampDot, art1, art3, art4, currentUserDot;
  final Color? track;
  final _Scene? scene;
}

/// A scene's inks, when a print run wants them exact.
class _Scene {
  const _Scene(
    this.sky,
    this.skyDot,
    this.sun,
    this.sunDot,
    this.hill,
    this.lake,
    this.lakeDot,
    this.pine,
    this.snow,
    this.flake,
    this.smoke,
    this.wood,
    this.chili,
    this.check,
    this.potDot,
    this.ray,
  );
  final Color sky, skyDot, sun, sunDot, hill, lake, lakeDot, pine, snow, flake;
  final Color smoke, wood, chili, check, potDot, ray;
}

Color _mix(Color a, Color b, double k) => Color.lerp(a, b, k)!;
const Color _black = Color(0xFF000000), _white = Color(0xFFFFFFFF);

ComicColors _dress(_Seed s, {required bool dark}) {
  final lit = s.text;
  final sc = s.scene;
  final monogramTertiary = dark
      ? _mix(s.primary, _white, .5)
      : s.currentUserTint;
  final unlit = dark ? _mix(s.background, s.paper, .55) : s.inset;
  return ComicColors(
    brightness: dark ? Brightness.dark : Brightness.light,
    background: s.background,
    grain: dark
        ? s.shade.withValues(alpha: .10)
        : s.outline.withValues(alpha: .07),
    card: s.card,
    inset: s.inset,
    outline: s.outline,
    text: s.text,
    textSecondary: s.textSecondary,
    divider: dark
        ? s.textSecondary.withValues(alpha: .22)
        : s.outline.withValues(alpha: .16),
    caption: s.caption,
    onCaption: s.onCaption,
    primary: s.primary,
    onPrimary: s.onPrimary,
    primaryText: s.primaryText,
    primaryLargeText: s.primaryText,
    currentUserTint: s.currentUserTint,
    shade: s.shade,
    onShade: s.onShade,
    shadeText: s.shadeText,
    shadeTint: s.shadeTint,
    drama: s.drama,
    paper: s.paper,
    onPaper: s.onPaper,
    onPaperSecondary: s.onPaperSecondary,
    control: dark ? lit : s.paper,
    hint: s.hint,
    track: s.track ?? (dark ? _mix(s.background, s.card, .4) : s.inset),
    unlit: unlit,
    // By day the contour carries the pale ones; the last is the quieter words' grey, so it's told from the tint.
    series: dark
        ? [s.caption, s.drama, s.shade, unlit, monogramTertiary, s.paper]
        : [
            s.caption,
            s.drama,
            s.shade,
            s.shadeTint,
            s.primary,
            s.textSecondary,
          ],
    dotTint: s.shadeTint,
    currentUserDot:
        s.currentUserDot ??
        (dark ? _mix(s.card, s.primary, .22) : s.currentUserTint),
    lampDot: s.lampDot ?? s.drama,
    cover: dark ? s.card : s.shade,
    coverRay:
        s.coverRay ??
        (dark ? _mix(s.card, s.shade, .1) : _mix(s.shade, _white, .08)),
    coverDot: s.primary,
    coverDotSecondary: dark ? s.shade : s.caption,
    head: dark ? _mix(s.shade, _white, .55) : s.shadeTint,
    headRing: dark ? lit : s.outline,
    currentUserHead: dark ? _mix(s.primary, _white, .55) : s.currentUserTint,
    currentUserHeadRing: dark ? s.primary : s.outline,
    monogramSecondary: dark ? _mix(s.shade, _white, .3) : s.shadeTint,
    monogramTertiary: monogramTertiary,
    art1:
        s.art1 ??
        (dark ? _mix(_black, s.caption, .22) : _mix(s.caption, _white, .4)),
    art2: dark ? _mix(s.card, s.shade, .22) : s.shadeTint,
    art3: s.art3 ?? (dark ? _mix(_black, s.primary, .26) : s.currentUserTint),
    art4: s.art4 ?? _mix(s.shade, _black, dark ? .6 : .55),
    artDot: dark
        ? _white.withValues(alpha: .09)
        : _white.withValues(alpha: .55),
    art4Dot: _mix(s.shade, _white, .25).withValues(alpha: .35),
    nightLine: dark ? lit : s.outline,
    sky: sc?.sky ?? (dark ? _mix(s.background, s.card, .4) : s.shadeTint),
    skyDot: sc?.skyDot ?? (dark ? _mix(s.card, s.shade, .3) : s.shadeTint),
    sun: sc?.sun ?? (dark ? _mix(s.caption, _white, .55) : s.caption),
    sunDot: sc?.sunDot ?? _mix(s.caption, s.drama, .35),
    hill: sc?.hill ?? (dark ? _mix(s.card, s.shade, .18) : s.shade),
    lake: sc?.lake ?? (dark ? _mix(s.background, s.card, .7) : s.shade),
    lakeDot: sc?.lakeDot ?? (dark ? _mix(s.card, s.shade, .3) : s.shade),
    pine: sc?.pine ?? s.outline,
    snow: sc?.snow ?? (dark ? _mix(s.shade, _white, .75) : s.paper),
    flake: sc?.flake ?? (dark ? _white : const Color(0x00FFFFFF)),
    window: s.caption,
    smoke: sc?.smoke ?? (dark ? _mix(s.shade, _white, .6) : s.paper),
    wood: sc?.wood ?? (dark ? _mix(s.caption, _black, .35) : s.caption),
    chili: sc?.chili ?? _mix(s.drama, _black, .45),
    check: sc?.check ?? (dark ? _mix(s.card, s.shade, .3) : s.shadeTint),
    shadow: dark
        ? _black.withValues(alpha: .45)
        : s.outline.withValues(alpha: .18),
    potDot: sc?.potDot ?? _mix(s.drama, _black, .5),
    amber: _mix(s.caption, s.drama, .3),
    ray:
        sc?.ray ??
        (dark ? _mix(s.card, s.shade, .1) : _mix(s.caption, _white, .6)),
    highlight: _mix(s.shade, _white, dark ? .1 : .2),
  );
}

/// One print run, designed in both appearances.
class _Palette {
  const _Palette.colors(this.day, this.night);
  _Palette(_Seed day, _Seed night)
    : day = _dress(day, dark: false),
      night = _dress(night, dark: true);
  final ComicColors day, night;
}

/// Comic: the concept's own. The Sunday edition by day: newsprint gutters, white panels, process blue. The night issue:
/// black gutters, ink-blue panels, and paper things (balloons, captions, controls) lit like windows.
final _Palette _offset = _Palette(
  const _Seed(
    background: Color(0xFFF3E8CF),
    card: Color(0xFFFFFCF4),
    inset: Color(0xFFFBF1DC),
    text: Color(0xFF15121C),
    textSecondary: Color(0xFF5A5262),
    caption: Color(0xFFFFD83A),
    primary: Color(0xFFFF3E92),
    onPrimary: Color(0xFF15121C),
    primaryText: Color(0xFFC8136A),
    currentUserTint: Color(0xFFFFC6DE),
    shade: Color(0xFF1D63D1),
    onShade: Color(0xFFFFFFFF),
    shadeText: Color(0xFF1D63D1),
    shadeTint: Color(0xFFCFE0FA),
    drama: Color(0xFFDE2D26),
    coverRay: Color(0xFF2F74E0),
    art1: Color(0xFFFFE68A),
    art4: Color(0xFF1B2A6B),
    scene: _Scene(
      Color(0xFFCFE0FA),
      Color(0xFF8DB4F0),
      Color(0xFFFFD83A),
      Color(0xFFF2A62B),
      Color(0xFF6E9BE6),
      Color(0xFF2F6FD6),
      Color(0xFF1A4FA8),
      Color(0xFF15121C),
      Color(0xFFFFFCF4),
      Color(0x00FFFFFF),
      Color(0xFFFFFCF4),
      Color(0xFFF2C14E),
      Color(0xFF8E2318),
      Color(0xFFCFE0FA),
      Color(0xFF8E2318),
      Color(0xFFFFF1B0),
    ),
  ),
  const _Seed(
    background: Color(0xFF06081A),
    card: Color(0xFF131C47),
    inset: Color(0xFF1B2860),
    outline: Color(0xFF000000),
    text: Color(0xFFF4EDD8),
    textSecondary: Color(0xFFA9B6DC),
    caption: Color(0xFFFFD83A),
    primary: Color(0xFFFF4FA0),
    onPrimary: Color(0xFF15121C),
    primaryText: Color(0xFFFF6FB1),
    currentUserTint: Color(0xFF7A2453),
    shade: Color(0xFF5B8CFF),
    onShade: Color(0xFF06081A),
    shadeText: Color(0xFF8FB0FF),
    shadeTint: Color(0xFF2A3C85),
    drama: Color(0xFFFF5A4E),
    coverRay: Color(0xFF1C2A66),
    art1: Color(0xFF3B3410),
    art3: Color(0xFF4A1838),
    art4: Color(0xFF1B2A6B),
    currentUserDot: Color(0xFF3A2260),
    track: Color(0xFF0C1336),
    scene: _Scene(
      Color(0xFF0B1238),
      Color(0xFF22357C),
      Color(0xFFFFF0B5),
      Color(0xFFE9CF72),
      Color(0xFF1A2763),
      Color(0xFF0E1A4D),
      Color(0xFF22357C),
      Color(0xFF000000),
      Color(0xFFD9E2FF),
      Color(0xFFEAF0FF),
      Color(0xFFB9C6EC),
      Color(0xFFB98A2E),
      Color(0xFF7A1C12),
      Color(0xFF22357C),
      Color(0xFF6E140C),
      Color(0xFF1C2A66),
    ),
  ),
);

/// Reprint: a run off older plates. Cool stock, teal for the group, an orange act, magenta drama. At night a deep-sea
/// green-black under the same lit paper.
final _Palette _reprint = _Palette(
  const _Seed(
    background: Color(0xFFE2ECEA),
    card: Color(0xFFFBFDFA),
    inset: Color(0xFFEDF4F1),
    outline: Color(0xFF0E1E26),
    text: Color(0xFF0E1E26),
    textSecondary: Color(0xFF475A63),
    caption: Color(0xFFF5E34C),
    onCaption: Color(0xFF0E1E26),
    primary: Color(0xFFFF7A1F),
    onPrimary: Color(0xFF0E1E26),
    primaryText: Color(0xFFA84200),
    currentUserTint: Color(0xFFFFD6B8),
    shade: Color(0xFF007C8A),
    onShade: Color(0xFFFFFFFF),
    shadeText: Color(0xFF00707D),
    shadeTint: Color(0xFFBDE5E4),
    drama: Color(0xFFD3147C),
    paper: Color(0xFFFBFDFA),
    onPaper: Color(0xFF0E1E26),
    onPaperSecondary: Color(0xFF475A63),
    hint: Color(0xFF55676F),
  ),
  const _Seed(
    background: Color(0xFF03141A),
    card: Color(0xFF0B2B35),
    inset: Color(0xFF123C48),
    outline: Color(0xFF000000),
    text: Color(0xFFE9F5EF),
    textSecondary: Color(0xFFA2C8CA),
    caption: Color(0xFFF5E34C),
    onCaption: Color(0xFF0E1E26),
    primary: Color(0xFFFF8A33),
    onPrimary: Color(0xFF0E1E26),
    primaryText: Color(0xFFFFA866),
    currentUserTint: Color(0xFF6E3A12),
    shade: Color(0xFF38C2CE),
    onShade: Color(0xFF03141A),
    shadeText: Color(0xFF6FDCE4),
    shadeTint: Color(0xFF17525E),
    drama: Color(0xFFFF4FA8),
    paper: Color(0xFFFBFDFA),
    onPaper: Color(0xFF0E1E26),
    onPaperSecondary: Color(0xFF475A63),
    hint: Color(0xFF55676F),
  ),
);

/// Newsstand: the glossy cover. White stock, a red act, chrome yellow, a green group. At night charcoal and a hot red.
final _Palette _newsstand = _Palette(
  const _Seed(
    background: Color(0xFFECECE6),
    card: Color(0xFFFFFFFF),
    inset: Color(0xFFF4F4EE),
    outline: Color(0xFF111114),
    text: Color(0xFF111114),
    textSecondary: Color(0xFF55555C),
    caption: Color(0xFFFFC400),
    onCaption: Color(0xFF111114),
    primary: Color(0xFFFF5233),
    onPrimary: Color(0xFF111114),
    primaryText: Color(0xFFC2260B),
    currentUserTint: Color(0xFFFFD2C8),
    shade: Color(0xFF0B7F43),
    onShade: Color(0xFFFFFFFF),
    shadeText: Color(0xFF0A7A40),
    shadeTint: Color(0xFFCBEAD7),
    drama: Color(0xFF6B2BC4),
    paper: Color(0xFFFFFFFF),
    onPaper: Color(0xFF111114),
    onPaperSecondary: Color(0xFF55555C),
    hint: Color(0xFF66666E),
  ),
  const _Seed(
    background: Color(0xFF09090C),
    card: Color(0xFF1B1B23),
    inset: Color(0xFF26262F),
    outline: Color(0xFF000000),
    text: Color(0xFFF6F6F0),
    textSecondary: Color(0xFFB6B6C2),
    caption: Color(0xFFFFC400),
    onCaption: Color(0xFF111114),
    primary: Color(0xFFFF6242),
    onPrimary: Color(0xFF111114),
    primaryText: Color(0xFFFF8E75),
    currentUserTint: Color(0xFF6E2415),
    shade: Color(0xFF38CC7E),
    onShade: Color(0xFF09090C),
    shadeText: Color(0xFF68E0A2),
    shadeTint: Color(0xFF1E4A33),
    drama: Color(0xFFB07CFF),
    paper: Color(0xFFFFFFFF),
    onPaper: Color(0xFF111114),
    onPaperSecondary: Color(0xFF55555C),
    hint: Color(0xFF66666E),
  ),
);

/// Pulp: cheap paper. Manila stock, a blood-red act with paper letters, mustard captions, a bottle-green group. At night
/// a tobacco brown under a lamp.
final _Palette _pulp = _Palette(
  const _Seed(
    background: Color(0xFFE6D3A8),
    card: Color(0xFFF7EBCD),
    inset: Color(0xFFEFDFB9),
    outline: Color(0xFF24140A),
    text: Color(0xFF24140A),
    textSecondary: Color(0xFF5B4131),
    caption: Color(0xFFF0AE2E),
    onCaption: Color(0xFF24140A),
    primary: Color(0xFFBE2F1A),
    onPrimary: Color(0xFFFFF6E0),
    primaryText: Color(0xFF9E2412),
    currentUserTint: Color(0xFFF2C4A8),
    shade: Color(0xFF2B5A4C),
    onShade: Color(0xFFFFF6E0),
    shadeText: Color(0xFF265244),
    shadeTint: Color(0xFFC0D5C3),
    drama: Color(0xFF7D1F11),
    paper: Color(0xFFFFF6E0),
    onPaper: Color(0xFF24140A),
    onPaperSecondary: Color(0xFF5B4131),
    hint: Color(0xFF6A5040),
  ),
  const _Seed(
    background: Color(0xFF120B06),
    card: Color(0xFF26180E),
    inset: Color(0xFF342113),
    outline: Color(0xFF000000),
    text: Color(0xFFF4E6C8),
    textSecondary: Color(0xFFCBB28E),
    caption: Color(0xFFF0AE2E),
    onCaption: Color(0xFF24140A),
    primary: Color(0xFFE8573B),
    onPrimary: Color(0xFF1A0E06),
    primaryText: Color(0xFFFF9378),
    currentUserTint: Color(0xFF6A2A18),
    shade: Color(0xFF6DB298),
    onShade: Color(0xFF120B06),
    shadeText: Color(0xFF95CFB8),
    shadeTint: Color(0xFF2D4A3D),
    drama: Color(0xFFFF7A52),
    lampDot: Color(0xFFA9311A),
    paper: Color(0xFFFFF6E0),
    onPaper: Color(0xFF24140A),
    onPaperSecondary: Color(0xFF5B4131),
    hint: Color(0xFF6A5040),
  ),
);

/// Sunday: the funnies, soft. Pale sky stock, a coral act, sunny captions, a violet group. At night aubergine.
final _Palette _sunday = _Palette(
  const _Seed(
    background: Color(0xFFDCE7F2),
    card: Color(0xFFFFFEFA),
    inset: Color(0xFFF1F5F8),
    outline: Color(0xFF1A1C2C),
    text: Color(0xFF1A1C2C),
    textSecondary: Color(0xFF50556F),
    caption: Color(0xFFFFE26A),
    onCaption: Color(0xFF1A1C2C),
    primary: Color(0xFFFF8069),
    onPrimary: Color(0xFF1A1C2C),
    primaryText: Color(0xFFB8381F),
    currentUserTint: Color(0xFFFFD6CC),
    shade: Color(0xFF5F47C4),
    onShade: Color(0xFFFFFFFF),
    shadeText: Color(0xFF5F47C4),
    shadeTint: Color(0xFFDDD6F8),
    drama: Color(0xFFDB3F32),
    paper: Color(0xFFFFFEFA),
    onPaper: Color(0xFF1A1C2C),
    onPaperSecondary: Color(0xFF50556F),
    hint: Color(0xFF5E6380),
  ),
  const _Seed(
    background: Color(0xFF110F1F),
    card: Color(0xFF241F3F),
    inset: Color(0xFF302A52),
    outline: Color(0xFF000000),
    text: Color(0xFFF6F1E6),
    textSecondary: Color(0xFFBBB4DC),
    caption: Color(0xFFFFE26A),
    onCaption: Color(0xFF1A1C2C),
    primary: Color(0xFFFF8F7A),
    onPrimary: Color(0xFF1A1C2C),
    primaryText: Color(0xFFFFA694),
    currentUserTint: Color(0xFF6A3048),
    shade: Color(0xFFA892F4),
    onShade: Color(0xFF110F1F),
    shadeText: Color(0xFFC0AFFA),
    shadeTint: Color(0xFF3F3580),
    drama: Color(0xFFFF7264),
    paper: Color(0xFFFFFEFA),
    onPaper: Color(0xFF1A1C2C),
    onPaperSecondary: Color(0xFF50556F),
    hint: Color(0xFF5E6380),
  ),
);

/// Line height in whole pixels. Flutter rounds a paragraph's height up, Blink keeps the fraction; asking for a hair
/// under the nearest whole pixel keeps a stack of text from drifting and keeps rules on whole pixels.
double _lh(double size, double ratio) =>
    ((size * ratio).roundToDouble() - .01) / size;

/// The type scale. Bangers is the lettering: titles, numbers from 24 up, buttons. Shantell Sans is the text. Every style is
/// already right for the current width. Bangers styles are set in caps by the parts; write them in plain case.
class ComicTextTheme {
  ComicTextTheme._(this.colors, this.desk, this.typeface);

  /// Font families and scale used by every generated style.
  final ComicTypeface typeface;

  /// The hero text role.
  late final TextStyle hero = _letter(desk ? 104 : 60, .95, colors.text);

  /// The section text role.
  late final TextStyle section = _letter(desk ? 40 : 28, .95, colors.text);

  /// The panel text role.
  late final TextStyle panel = _letter(desk ? 34 : 28, .95, colors.text);

  /// The question text role.
  late final TextStyle question = _letter(26, 1.02, colors.text, .04);

  /// The item text role.
  late final TextStyle item = _letter(24, 1, colors.text);

  /// The button text role.
  late final TextStyle button = _letter(20, 1, colors.text, .05);

  /// The buttonSmall text role.
  late final TextStyle buttonSmall = _letter(18, 1, colors.text, .05);

  /// The body text role.
  late final TextStyle body = _text(16, 1.45, FontWeight.w500, colors.text);

  /// The title text role.
  late final TextStyle title = _text(16, 1.25, FontWeight.w700, colors.text);

  /// The meta text role.
  late final TextStyle meta = _text(
    14,
    1.3,
    FontWeight.w600,
    colors.textSecondary,
  );

  /// The small text role.
  late final TextStyle small = _text(
    14,
    1.35,
    FontWeight.w600,
    colors.textSecondary,
  );

  /// The label text role.
  late final TextStyle label = _text(
    12,
    1.2,
    FontWeight.w800,
    colors.text,
    .06,
  );

  /// The balloon text role.
  late final TextStyle balloon = _text(
    14,
    1.35,
    FontWeight.w600,
    colors.onPaper,
    .015,
  );

  /// The data text role.
  late final TextStyle data = _text(15, 1.25, FontWeight.w800, colors.text);

  /// The palette used by the component.
  final ComicColors colors;

  /// Whether the layout uses its expanded form.
  final bool desk;

  /// Bangers. hero: a splash's title, one per screen. section: a head on the gutter. panel: a panel's title. question:
  /// a question said out loud. item: a row of panels' titles. button: controls.

  /// Shantell Sans. body 16 plain text; title row titles; meta and small quieter lines; label caps 12 (write them in caps
  /// or use `ComicCaption`); balloon the words in a balloon; data a number under 24, which stays out of Bangers: its 7
  /// reads as a 1 when small.

  /// The lettering face at any size.
  TextStyle letter(
    double size, {
    double lineHeight = .95,
    Color? color,
    double tracking = .035,
  }) => _letter(size, lineHeight, color ?? colors.text, tracking);

  /// The text face at any size.
  TextStyle text(
    double size,
    double lineHeight, {
    FontWeight weight = FontWeight.w500,
    Color? color,
    double tracking = 0,
  }) => _text(size, lineHeight, weight, color ?? colors.text, tracking);

  /// A number: Bangers from 24 up, Shantell 800 below, whichever a size needs.
  TextStyle number(double size, {Color? color}) => size >= 24
      ? _letter(size, 1, color ?? colors.text, .03)
      : _text(
          size,
          1.25,
          FontWeight.w800,
          color ?? colors.text,
        ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  TextStyle _letter(
    double size,
    double ratio,
    Color color, [
    double tracking = .035,
  ]) => TextStyle(
    inherit: false,
    fontFamily: typeface.display,
    package: typeface.displayPackage,
    // A glyph the lettering face lacks (an accent, Cyrillic) comes from the text face, then from the platform's own
    // fonts (on the web, the engine's Noto fallbacks): never a box.
    fontFamilyFallback: typeface.displayPackage == typeface.textPackage
        ? [typeface.text]
        : null,
    fontSize: size * typeface.scale,
    height: _lh(size * typeface.scale, ratio),
    letterSpacing: size * tracking * typeface.scale,
    fontWeight: FontWeight.w400,
    color: color,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );

  TextStyle _text(
    double size,
    double ratio,
    FontWeight weight,
    Color color, [
    double tracking = 0,
  ]) => TextStyle(
    inherit: false,
    fontFamily: typeface.text,
    package: typeface.textPackage,
    fontSize: size * typeface.scale,
    height: _lh(size * typeface.scale, ratio),
    letterSpacing: size * tracking * typeface.scale,
    fontWeight: weight,
    color: color,
    textBaseline: TextBaseline.alphabetic,
    leadingDistribution: TextLeadingDistribution.even,
    decoration: TextDecoration.none,
  );
}

/// Convenient text-style variants used by Comic typography.
extension ComicTextStyle on TextStyle {
  /// Tabular figures: every number that aligns.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Tracking in em, like CSS letter-spacing.
  TextStyle tracked(double em) =>
      copyWith(letterSpacing: (fontSize ?? 14) * em);

  /// Exact line height ratio on the whole-pixel grid.
  TextStyle leading(double ratio) =>
      copyWith(height: _lh(fontSize ?? 14, ratio));
}

/// What `ComicTheme.of(context)` returns: a print run in one appearance, as Material's `ThemeData` is a theme. Immutable,
/// with [copyWith], [lerp], `==`, `hashCode` and `debugFillProperties`.
///
/// ```dart
/// final night = ComicThemeData.offset(Brightness.dark);
/// final other = night.copyWith(colors: ComicThemeData.sunday(Brightness.dark).colors);
/// ```
@immutable
class ComicThemeData with Diagnosticable {
  ComicThemeData._(
    this.id,
    this._palette,
    this.colors,
    this.width,
    this.onDots, {
    this.shapes = const ComicShapes(),
    this.strokes = const ComicStrokes(),
    this.density = ComicDensity.standard,
    this.typeface = ComicTypeface.look,
    this.components = const ComicComponentThemes(),
    this.motion = const ComicMotion(),
  }) : type = ComicTextTheme._(colors, width >= comicDeskWidth, typeface);

  /// The offset preset: process yellow, pink and blue on warm newsprint, a Sunday comic.
  factory ComicThemeData.offset([Brightness brightness = Brightness.light]) =>
      preset('offset', brightness);

  /// The reprint preset: teal and orange.
  factory ComicThemeData.reprint([Brightness brightness = Brightness.light]) =>
      preset('reprint', brightness);

  /// The newsstand preset: green.
  factory ComicThemeData.newsstand([
    Brightness brightness = Brightness.light,
  ]) => preset('newsstand', brightness);

  /// The pulp preset: an aged and earthy page.
  factory ComicThemeData.pulp([Brightness brightness = Brightness.light]) =>
      preset('pulp', brightness);

  /// The sunday preset: a softer page.
  factory ComicThemeData.sunday([Brightness brightness = Brightness.light]) =>
      preset('sunday', brightness);

  /// Builds a complete print palette from app colours, adjusting derived ink until it reads.
  ///
  /// ```dart
  /// ComicThemeData.from(primary: Color(0xffa32d67), caption: Color(0xffffdf57), shade: Color(0xff325e98))
  /// ```
  factory ComicThemeData.from({
    required Color primary,
    required Color caption,
    required Color shade,
    Color background = const Color(0xfff3e8cf),
    Brightness brightness = Brightness.light,
  }) {
    final palette = _Palette.colors(
      _comicFrom(primary, caption, shade, background, false),
      _comicFrom(primary, caption, shade, background, true),
    );
    return ComicThemeData._(
      'custom',
      palette,
      brightness == Brightness.dark ? palette.night : palette.day,
      0,
      false,
    );
  }

  /// Shape scale; null slots keep each original drawing.
  final ComicShapes shapes;

  /// Rim, rule and focus widths.
  final ComicStrokes strokes;

  /// Density changes the face while preserving accessible targets.
  final ComicDensity density;

  /// Families and scale for all printed type.
  final ComicTypeface typeface;

  /// Component styles, below a widget's explicit style.
  final ComicComponentThemes components;

  /// Timing and curves, cut under Reduce Motion by ComicMotion.of.
  final ComicMotion motion;

  /// A contour's width, defaulting to the component's drawing.
  double rim([double own = 2.5]) => strokes.regular ?? own;

  /// A rule's width, defaulting to its original drawing.
  double rule([double own = 2]) => strokes.hairline ?? own;

  /// The actButton component style.
  ComicStyle get filledButtonTheme => components.actButton;

  /// The lineButton component style.
  ComicStyle get buttonTheme => components.lineButton;

  /// The quietButton component style.
  ComicStyle get textButtonTheme => components.quietButton;

  /// The iconButton component style.
  ComicStyle get iconButtonTheme => components.iconButton;

  /// The checkbox component style.
  ComicStyle get checkboxTheme => components.checkbox;

  /// The radio component style.
  ComicStyle get radioTheme => components.radio;

  /// The switchTheme component style.
  ComicStyle get switchTheme => components.switchTheme;

  /// The textField component style.
  ComicStyle get textFieldTheme => components.textField;

  /// The chip component style.
  ComicStyle get chipTheme => components.chip;

  /// The slider component style.
  ComicStyle get sliderTheme => components.slider;

  /// The segmentedButton component style.
  ComicStyle get segmentedButtonTheme => components.segmentedButton;

  /// The card component style.
  ComicStyle get cardTheme => components.card;

  /// The dialog component style.
  ComicStyle get dialogTheme => components.dialog;

  /// The sheet component style.
  ComicStyle get sheetTheme => components.sheet;

  /// The menu component style.
  ComicStyle get menuTheme => components.menu;

  /// The snackBar component style.
  ComicStyle get snackBarTheme => components.snackBar;

  /// The tooltip component style.
  ComicStyle get tooltipTheme => components.tooltip;

  /// The badge component style.
  ComicStyle get badgeTheme => components.badge;

  /// The avatar component style.
  ComicStyle get avatarTheme => components.avatar;

  /// The option component style.
  ComicStyle get optionTheme => components.option;

  /// The stepper component style.
  ComicStyle get stepperTheme => components.stepper;

  /// The datePicker component style.
  ComicStyle get datePickerTheme => components.datePicker;

  /// The timePicker component style.
  ComicStyle get timePickerTheme => components.timePicker;

  /// Which print run this is (`offset`, `reprint`, ...).
  final String id;
  final _Palette _palette;

  /// Current colours.
  final ComicColors colors;

  /// The type, set for [width].
  final ComicTextTheme type;

  /// The width of the page this was set for: the type and the window class follow it.
  final double width;

  /// True on a dotted ground: the quiet words go to full ink there, because small quiet words don't read over dots.
  final bool onDots;

  /// What's in scope at [context]; the same as [ComicTheme.of].
  static ComicThemeData of(BuildContext context) => ComicTheme.of(context);

  /// The print runs, the default first. Each is designed in light and dark.
  static const List<String> presets = <String>[
    'offset',
    'reprint',
    'newsstand',
    'pulp',
    'sunday',
  ];

  static final Map<String, _Palette> _palettes = {
    'offset': _offset,
    'reprint': _reprint,
    'newsstand': _newsstand,
    'pulp': _pulp,
    'sunday': _sunday,
  };
  static final Map<(String, Brightness), ComicThemeData> _cache = {};

  /// The theme for preset [id] in [brightness]; an unknown id throws. The theme file's call.
  static ComicThemeData preset(String id, Brightness brightness) {
    final palette = _palettes[id];
    if (palette == null) {
      throw ArgumentError.value(
        id,
        'id',
        'not a Comic preset (${presets.join(', ')})',
      );
    }
    return _cache[(id, brightness)] ??= ComicThemeData._(
      id,
      palette,
      brightness == Brightness.dark ? palette.night : palette.day,
      0,
      false,
    );
  }

  /// The same preset and appearance, its type set for [width].
  ComicThemeData atWidth(double width) =>
      width == this.width ? this : copyWith(width: width);

  /// The stubs' page title and body text.
  TextStyle get h1 => type.panel;

  /// Body text: `type.body`.
  TextStyle get body => type.body;

  /// True from 1024 wide up: the 12-column layout.
  bool get desk => width >= comicDeskWidth;

  /// The window class of the page this theme was built for.
  ComicWindowSizeClass get window => ComicWindowSizeClass.ofWidth(width);

  late final ComicFocusRing _focus = ComicFocusRing(
    color: _comicFocusColor(colors),
    width: strokes.heavy ?? 3,
  );

  /// The keyboard's focus ring, legible on page, card and control grounds.
  ComicFocusRing get focus => _focus;

  /// Whether this is a light page or a dark one: `colors.brightness`, as `ThemeData.brightness`.
  Brightness get brightness => colors.brightness;

  /// The palette for words on dots: quiet words go to full ink.
  ComicThemeData get dotted {
    if (onDots) return this;
    final c = colors;
    return copyWith(colors: _withInks(c, c.text, c.text), onDots: true);
  }

  /// Rescopes every text ink for a filled ground without discarding style knobs.
  ComicThemeData lettersOn(Color letters) =>
      copyWith(colors: _withInks(colors, letters, letters));

  /// Copies supplied palette, typography, motion and component settings.
  ComicThemeData copyWith({
    ComicColors? colors,
    double? width,
    bool? onDots,
    ComicShapes? shapes,
    ComicStrokes? strokes,
    ComicDensity? density,
    ComicTypeface? typeface,
    ComicComponentThemes? components,
    ComicMotion? motion,
    ComicTones? tones,
    ComicStyle? filledButtonTheme,
    ComicStyle? buttonTheme,
    ComicStyle? textButtonTheme,
    ComicStyle? iconButtonTheme,
    ComicStyle? checkboxTheme,
    ComicStyle? radioTheme,
    ComicStyle? switchTheme,
    ComicStyle? textFieldTheme,
    ComicStyle? chipTheme,
    ComicStyle? sliderTheme,
    ComicStyle? segmentedButtonTheme,
    ComicStyle? cardTheme,
    ComicStyle? dialogTheme,
    ComicStyle? sheetTheme,
    ComicStyle? menuTheme,
    ComicStyle? snackBarTheme,
    ComicStyle? tooltipTheme,
    ComicStyle? badgeTheme,
    ComicStyle? avatarTheme,
    ComicStyle? optionTheme,
    ComicStyle? stepperTheme,
    ComicStyle? datePickerTheme,
    ComicStyle? timePickerTheme,
  }) => ComicThemeData._(
    id,
    _palette,
    (colors ?? this.colors).copyWith(status: tones),
    width ?? this.width,
    onDots ?? this.onDots,
    shapes: shapes ?? this.shapes,
    strokes: strokes ?? this.strokes,
    density: density ?? this.density,
    typeface: typeface ?? this.typeface,
    motion: motion ?? this.motion,
    components: (components ?? this.components).copyWith(
      actButton: filledButtonTheme,
      lineButton: buttonTheme,
      quietButton: textButtonTheme,
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
    ),
  );

  /// Between this and [other]: colours blend, the width eases, the preset and the dots flip at the middle.
  /// `AnimatedComicTheme` animates with it.
  ComicThemeData lerp(ComicThemeData? other, double t) {
    if (other == null || identical(this, other) || t == 0) return this;
    if (t == 1) return other;
    return ComicThemeData._(
      t < .5 ? id : other.id,
      t < .5 ? _palette : other._palette,
      ComicColors.lerp(colors, other.colors, t),
      lerpDouble(width, other.width, t)!,
      t < .5 ? onDots : other.onDots,
      shapes: ComicShapes.lerp(shapes, other.shapes, t),
      strokes: ComicStrokes.lerp(strokes, other.strokes, t),
      density: ComicDensity.lerp(density, other.density, t),
      typeface: ComicTypeface.lerp(typeface, other.typeface, t),
      components: ComicComponentThemes.lerp(components, other.components, t),
      motion: ComicMotion.lerp(motion, other.motion, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ComicThemeData &&
          other.id == id &&
          other.colors == colors &&
          other.width == width &&
          other.onDots == onDots &&
          other.shapes == shapes &&
          other.strokes == strokes &&
          other.density == density &&
          other.typeface == typeface &&
          other.components == components &&
          other.motion == motion;

  @override
  int get hashCode => Object.hash(
    id,
    colors,
    width,
    onDots,
    shapes,
    strokes,
    density,
    typeface,
    components,
    motion,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    properties.add(FlagProperty('onDots', value: onDots, ifTrue: 'on dots'));
    properties.add(DoubleProperty('width', width));
    properties.add(DiagnosticsProperty('shapes', shapes));
    properties.add(DiagnosticsProperty('strokes', strokes));
    properties.add(DiagnosticsProperty('density', density));
    properties.add(DiagnosticsProperty('typeface', typeface));
    properties.add(DiagnosticsProperty('components', components));
    properties.add(DiagnosticsProperty('motion', motion));

    properties.add(DiagnosticsProperty<ComicColors>('colors', colors));
  }
}

ComicColors _withInks(ComicColors c, Color ink, Color textSecondary) =>
    ComicColors(
      status: c.status,
      brightness: c.brightness,
      background: c.background,
      grain: c.grain,
      card: c.card,
      inset: c.inset,
      outline: c.outline,
      text: ink,
      textSecondary: textSecondary,
      divider: c.divider,
      caption: c.caption,
      onCaption: c.onCaption,
      primary: c.primary,
      onPrimary: c.onPrimary,
      primaryText: c.textSecondary == textSecondary ? c.primaryText : ink,
      primaryLargeText: c.primaryLargeText,
      currentUserTint: c.currentUserTint,
      shade: c.shade,
      onShade: c.onShade,
      shadeText: c.textSecondary == textSecondary ? c.shadeText : ink,
      shadeTint: c.shadeTint,
      drama: c.drama,
      paper: c.paper,
      onPaper: c.onPaper,
      onPaperSecondary: c.onPaperSecondary,
      control: c.control,
      hint: c.hint,
      track: c.track,
      unlit: c.unlit,
      series: c.series,
      dotTint: c.dotTint,
      currentUserDot: c.currentUserDot,
      lampDot: c.lampDot,
      cover: c.cover,
      coverRay: c.coverRay,
      coverDot: c.coverDot,
      coverDotSecondary: c.coverDotSecondary,
      head: c.head,
      headRing: c.headRing,
      currentUserHead: c.currentUserHead,
      currentUserHeadRing: c.currentUserHeadRing,
      monogramSecondary: c.monogramSecondary,
      monogramTertiary: c.monogramTertiary,
      art1: c.art1,
      art2: c.art2,
      art3: c.art3,
      art4: c.art4,
      artDot: c.artDot,
      art4Dot: c.art4Dot,
      nightLine: c.nightLine,
      sky: c.sky,
      skyDot: c.skyDot,
      sun: c.sun,
      sunDot: c.sunDot,
      hill: c.hill,
      lake: c.lake,
      lakeDot: c.lakeDot,
      pine: c.pine,
      snow: c.snow,
      flake: c.flake,
      window: c.window,
      smoke: c.smoke,
      wood: c.wood,
      chili: c.chili,
      check: c.check,
      shadow: c.shadow,
      potDot: c.potDot,
      amber: c.amber,
      ray: c.ray,
      highlight: c.highlight,
    );

/// Puts Comic in scope for everything under it, its type set for the window's width, as Material's `Theme` does. It is the
/// whole install: put one in any app's `builder:`, under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`, and every
/// look installs the same way (`<Look>Theme(data: <Look>ThemeData.preset(...))`). Under it, Flutter's own text field and
/// scroll bar wear Comic's caret, selection and bar, with no ink. `ComicHost` puts one at the root; another restyles a
/// part of the tree. An `InheritedTheme`, so what a route or an overlay captures keeps the Comic it was raised in.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => ComicTheme(
///     data: ComicThemeData.preset('offset', MediaQuery.platformBrightnessOf(context)),
///     child: child!,
///   ),
///   home: const IssuePage(),
/// )
/// ```
///
/// A nested one restyles a part of the tree:
///
/// ```dart
/// ComicTheme(
///   data: ComicThemeData.preset('pulp', Brightness.dark),
///   child: const ComicPanel(child: Text('Meanwhile...')),
/// )
/// ```
class ComicTheme extends InheritedTheme {
  /// Scopes [data] over [child].
  ComicTheme({super.key, required this.data, required Widget child})
    : super(
        child: _ComicInstall(data: data, child: child),
      );
  const ComicTheme._scope({required this.data, required super.child});

  /// The theme for what is under it.
  final ComicThemeData data;

  /// The theme in scope at [context]: the nearest [ComicTheme], `ComicDotsScope` or `ComicLetteringScope`. Throws when there is
  /// none. `context.comicTheme` is the same.
  static ComicThemeData of(BuildContext context) {
    final found = maybeOf(context);
    if (found == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No Comic theme in scope.'),
        ErrorHint(
          'Put a ComicTheme in the app\'s builder, or above this widget.',
        ),
      ]);
    }
    return found;
  }

  /// The theme in scope at [context], or null.
  static ComicThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<ComicTheme>()
      ?.data
      .atWidth(MediaQuery.sizeOf(context).width);

  /// [ComicThemeData.preset]: an app's theme file names its preset here.
  static ComicThemeData preset(String id, Brightness brightness) =>
      ComicThemeData.preset(id, brightness);

  /// What an overlay entry or a route carries over: the whole install but Material's words. Those come in a
  /// `Localizations`, whose box would stand between the overlay and an entry placed by a `Positioned` (a reorderable
  /// row's lifted copy) and break it; Comic's own routes add the words where they raise ([comicMaterialWords]).
  @override
  Widget wrap(BuildContext context, Widget child) => ComicTheme._scope(
    data: data,
    child: _ComicInstall(data: data, words: false, child: child),
  );
  @override
  bool updateShouldNotify(ComicTheme oldWidget) => data != oldWidget.data;
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ComicThemeData>('data', data));
  }
}

/// Marks the control a form field holds as wrong while [error], as a shadcn form item marks its control invalid: the
/// field-like parts under it draw their rim in the danger tone ([comicFieldInError]). Kept out of the barrel.
Widget comicFieldTrouble({required bool error, required Widget child}) =>
    _FieldTrouble(error: error, child: child);

/// Whether the form field around [context] shows an error (see [comicFieldTrouble]). Kept out of the barrel.
bool comicFieldInError(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<_FieldTrouble>()?.error ?? false;

class _FieldTrouble extends InheritedWidget {
  const _FieldTrouble({required this.error, required super.child});

  final bool error;

  @override
  bool updateShouldNotify(_FieldTrouble oldWidget) => error != oldWidget.error;
}

/// Material's words where [context] has none, for a `Localizations` that raises a surface: Flutter's text field under a
/// CupertinoApp or a WidgetsApp still asks for them. Kept out of the barrel.
List<LocalizationsDelegate<dynamic>> comicMaterialWords(BuildContext context) =>
    Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null
    ? const [DefaultMaterialLocalizations.delegate]
    : const [];

class _ComicInstall extends StatelessWidget {
  const _ComicInstall({
    required this.data,
    required this.child,
    this.words = true,
  });
  final ComicThemeData data;
  final Widget child;
  final bool words;
  @override
  Widget build(BuildContext context) {
    Widget under = child;
    final List<LocalizationsDelegate<dynamic>> material = words
        ? comicMaterialWords(context)
        : const [];
    if (material.isNotEmpty) {
      // Localizations sets a direction from its words; the app's own direction, in force here, stands under it.
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: material,
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    final scoped = data.atWidth(MediaQuery.sizeOf(context).width);
    return Theme(
      data: _comicMaterialUnder(data.colors),
      child: ScrollConfiguration(
        behavior: ComicScrollBehavior(data.colors.outline),
        child: IconTheme.merge(
          data: IconThemeData(color: scoped.colors.text),
          child: DefaultTextStyle.merge(style: scoped.type.body, child: under),
        ),
      ),
    );
  }
}

final Expando<ThemeData> _bridges = Expando<ThemeData>();

/// What Flutter's own widgets under Comic read (the text field's caret, selection and density), in Comic's colours, with
/// no ink, splash or highlight. Not part of the package's barrel: an app never sees a Material type in Comic's API.
ThemeData _comicMaterialUnder(ComicColors c) => _bridges[c] ??= ThemeData(
  useMaterial3: true,
  brightness: c.brightness,
  visualDensity: VisualDensity.standard,
  fontFamily: 'ShantellSans',
  package: comicFontPackage,
  scaffoldBackgroundColor: c.background,
  canvasColor: c.background,
  colorScheme: ColorScheme(
    brightness: c.brightness,
    primary: c.primary,
    onPrimary: c.onPrimary,
    secondary: c.shade,
    onSecondary: c.onShade,
    error: c.drama,
    onError: c.onPrimary,
    surface: c.card,
    onSurface: c.text,
  ),
  splashFactory: NoSplash.splashFactory,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  focusColor: Colors.transparent,
  splashColor: Colors.transparent,
  textSelectionTheme: TextSelectionThemeData(
    cursorColor: c.onPaper,
    selectionColor: c.shade.withValues(alpha: .35),
  ),
);

/// Animates to a new [data] over [duration] (200 ms, Material's `AnimatedTheme` default), as `AnimatedTheme` does:
/// colours blend through [ComicThemeData.lerp].
///
/// ```dart
/// AnimatedComicTheme(
///   data: ComicThemeData.preset('offset', dark ? Brightness.dark : Brightness.light),
///   child: page,
/// )
/// ```
class AnimatedComicTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedComicTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final ComicThemeData data;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedComicTheme> createState() =>
      _AnimatedComicThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ComicThemeData>('data', data));
  }
}

class _AnimatedComicThemeState
    extends AnimatedWidgetBaseState<AnimatedComicTheme> {
  ComicThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => ComicThemeDataTween(begin: value as ComicThemeData),
    ) as ComicThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) =>
      ComicTheme(data: _data!.evaluate(animation), child: widget.child);
}

/// How a scroll looks under Comic: a thin bar in the contour's ink on a desktop, the stretch on Android, and nothing of
/// Material's. `ComicTheme` installs it.
class ComicScrollBehavior extends ScrollBehavior {
  /// A behaviour whose bar is drawn in [thumb].
  const ComicScrollBehavior(this.thumb);

  /// The bar's colour.
  final Color thumb;

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => switch (getPlatform(context)) {
    TargetPlatform.macOS ||
    TargetPlatform.windows ||
    TargetPlatform.linux => RawScrollbar(
      controller: details.controller,
      thumbColor: thumb,
      thickness: 6,
      child: child,
    ),
    _ => child,
  };

  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => switch (getPlatform(context)) {
    TargetPlatform.android => StretchingOverscrollIndicator(
      axisDirection: details.direction,
      clipBehavior: details.decorationClipBehavior ?? Clip.hardEdge,
      child: child,
    ),
    _ => child,
  };

  @override
  bool shouldNotify(ComicScrollBehavior oldDelegate) =>
      oldDelegate.thumb != thumb;
}

/// A tween between two Comic themes, through [ComicThemeData.lerp].
class ComicThemeDataTween extends Tween<ComicThemeData> {
  /// From [begin] to [end].
  ComicThemeDataTween({super.begin, super.end});

  @override
  ComicThemeData lerp(double t) => begin!.lerp(end, t);
}

/// Re-scopes everything under it for words on dots: `t.colors.textSecondary` answers with full ink.
///
/// ```dart
/// ComicDotsScope(child: Text('Over the halftone'))
/// ```
class ComicDotsScope extends StatelessWidget {
  /// Creates a [ComicDotsScope].
  const ComicDotsScope({super.key, required this.child});

  /// What stands on the dots.
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ComicTheme._scope(data: ComicTheme.of(context).dotted, child: child);
}

/// Re-scopes everything under it for words on a filled ground: every ink answers with [letters].
///
/// ```dart
/// ComicLetteringScope(Colors.white, child: Text('On the lamp'))
/// ```
class ComicLetteringScope extends StatelessWidget {
  /// Creates a [ComicLetteringScope].
  const ComicLetteringScope(this.letters, {super.key, required this.child});

  /// The colour every ink answers with.
  final Color letters;

  /// What stands on the filled ground.
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context).lettersOn(letters);
    return ComicTheme._scope(
      data: t,
      child: DefaultTextStyle.merge(
        style: TextStyle(color: letters),
        child: IconTheme.merge(
          data: IconThemeData(color: letters),
          child: child,
        ),
      ),
    );
  }
}

/// `context.comicTheme`: the theme in scope.
extension ComicThemeContext on BuildContext {
  /// The Comic theme in scope: `ComicTheme.of(this)`.
  ComicThemeData get comicTheme => ComicTheme.of(this);
}

/// Default semantic inks for light paper.
const comicLightTones = ComicTones(
  info: Color(0xff164e8a),
  success: Color(0xff24602f),
  warning: Color(0xff754400),
  danger: Color(0xffa02028),
);

/// Default semantic inks for dark paper.
const comicDarkTones = ComicTones(
  info: Color(0xff9ccaff),
  success: Color(0xff9fdfa6),
  warning: Color(0xffffd181),
  danger: Color(0xffffa7ab),
);

double _comicContrast(Color a, Color b) {
  final x = a.computeLuminance(), y = b.computeLuminance();
  return (math.max(x, y) + .05) / (math.min(x, y) + .05);
}

Color _comicFocusColor(ComicColors colors) {
  final grounds = [colors.background, colors.card, colors.control];
  double contrast(Color color) =>
      grounds.map((ground) => _comicContrast(color, ground)).reduce(math.min);
  if (contrast(colors.text) >= 3) return colors.text;
  // Dark pages keep light paper controls. Their text ink cannot also be the
  // ring on both surfaces, so choose the neutral ink with the strongest
  // minimum contrast across them. Resolve once for each immutable theme.
  var best = colors.text;
  var strongest = contrast(best);
  for (var value = 0; value <= 255; value++) {
    final candidate = Color.fromARGB(255, value, value, value);
    final score = contrast(candidate);
    if (score > strongest) {
      best = candidate;
      strongest = score;
    }
  }
  return best;
}

Color _comicRead(Color wanted, List<Color> grounds, [double ratio = 4.5]) {
  bool reads(Color c) => grounds.every((g) => _comicContrast(c, g) >= ratio);
  if (reads(wanted)) return wanted;
  const ends = [Color(0xff000000), Color(0xffffffff)];
  final end = ends.reduce(
    (a, b) =>
        grounds.map((g) => _comicContrast(a, g)).reduce(math.min) >=
            grounds.map((g) => _comicContrast(b, g)).reduce(math.min)
        ? a
        : b,
  );
  var lo = 0.0, hi = 1.0;
  for (var i = 0; i < 24; i++) {
    final mid = (lo + hi) / 2;
    if (reads(Color.lerp(wanted, end, mid)!)) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  return Color.lerp(wanted, end, hi)!;
}

double _comicDistance(Color a, Color b) {
  List<double> lab(Color c) {
    double linear(double v) =>
        v <= .04045 ? v / 12.92 : math.pow((v + .055) / 1.055, 2.4).toDouble();
    final r = linear(c.r), g = linear(c.g), b = linear(c.b);
    double f(double t) =>
        t > .008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;
    final x = f((r * .4124 + g * .3576 + b * .1805) / .95047);
    final y = f(r * .2126 + g * .7152 + b * .0722);
    final z = f((r * .0193 + g * .1192 + b * .9505) / 1.08883);
    return [116 * y - 16, 500 * (x - y), 200 * (y - z)];
  }

  final x = lab(a), y = lab(b);
  return math.sqrt(
    List.generate(
      3,
      (i) => math.pow(x[i] - y[i], 2).toDouble(),
    ).reduce((a, b) => a + b),
  );
}

/// The look's own shorthand for a dark page, inside the library: `brightness == Brightness.dark`. Hidden from the
/// barrel; a caller reads `brightness`.
extension ComicDarkPage on ComicColors {
  /// Whether these are the night colours.
  bool get dark => brightness == Brightness.dark;
}

/// The same shorthand on the theme, inside the library.
extension ComicDarkTheme on ComicThemeData {
  /// Whether this is the night palette.
  bool get dark => colors.brightness == Brightness.dark;
}

ComicColors _comicFrom(
  Color act,
  Color caption,
  Color shade,
  Color ground,
  bool dark,
) {
  final base = dark ? _offset.night : _offset.day;
  const black = Color(0xff111111), white = Color(0xffffffff);
  Color blend(Color a, Color b, double amount) => Color.lerp(a, b, amount)!;
  final anchor = dark ? black : white, ink = dark ? white : black;
  // Keep the grounds in one luminance family, even when given hostile input.
  final paperGround = blend(ground, anchor, dark ? .93 : .8);
  final card = blend(paperGround, anchor, .55),
      well = blend(paperGround, anchor, .2);
  final grounds = [paperGround, card, well];
  final paper = blend(ground, white, .94), onPaper = _comicRead(black, [paper]);
  final quiet = _comicRead(blend(ink, card, .3), grounds);
  final choices = <Color>[];
  Color choose(Color wanted, {bool light = false, double contrast = 0}) {
    bool valid(Color color) =>
        choices.every((other) => _comicDistance(color, other) >= 20) &&
        (!light || _comicContrast(onPaper, color) >= 4.5) &&
        _comicContrast(color, card) >= contrast &&
        grounds.every(
          (g) =>
              math.max(
                _comicContrast(color, g),
                math.min(_comicContrast(ink, g), _comicContrast(ink, color)),
              ) >=
              3,
        );
    Color chosen = wanted;
    if (!valid(chosen)) {
      final candidates =
          [
            for (final l in [.35, .5, .65, .8])
              for (var h = 0; h < 360; h += 15)
                HSLColor.fromAHSL(1, h.toDouble(), .65, l).toColor(),
            base.primary,
            base.shade,
            base.caption,
            base.drama,
            base.unlit,
          ].where(valid).toList()..sort(
            (a, b) =>
                _comicDistance(a, wanted).compareTo(_comicDistance(b, wanted)),
          );
      if (candidates.isNotEmpty) chosen = candidates.first;
    }
    choices.add(chosen);
    return chosen;
  }

  final actFill = choose(act.withValues(alpha: 1));
  final shadeFill = choose(
    _comicRead(shade.withValues(alpha: 1), [card], 2.4),
    contrast: 2.4,
  );
  final captionFill = choose(caption.withValues(alpha: 1));
  final drama = choose(_comicRead(base.drama, [card], 3), contrast: 3);
  final unlit = choose(base.unlit, light: true);
  final onPrimary = _comicRead(black, [actFill]);
  final onShade = _comicRead(white, [shadeFill]);
  final onCaption = _comicRead(black, [captionFill]);
  final you = blend(actFill, card, .88), tint = blend(shadeFill, card, .9);
  Color dots(Color color, Color ground) {
    var result = blend(color, ground, .75);
    for (var i = 0; i < 32 && _comicContrast(ink, result) < 4.5; i++) {
      result = blend(result, ground, .15);
    }
    return result;
  }

  final currentUserDot = dots(actFill, you), dotTint = dots(shadeFill, tint);
  final tones = base.tones;
  final settledTones = ComicTones(
    info: _comicRead(tones.info, grounds),
    success: _comicRead(tones.success, grounds),
    warning: _comicRead(tones.warning, grounds),
    danger: _comicRead(tones.danger, grounds),
  );
  final onPaperSecondary = _comicRead(blend(onPaper, paper, .3), [paper]);
  return base.copyWith(
    status: settledTones,
    background: paperGround,
    grain: blend(ink, paperGround, .94),
    card: card,
    inset: well,
    text: ink,
    textSecondary: quiet,
    outline: ink,
    divider: blend(ink, card, .65),
    primary: actFill,
    onPrimary: onPrimary,
    primaryText: _comicRead(actFill, grounds),
    primaryLargeText: _comicRead(actFill, [you, currentUserDot], 3),
    caption: captionFill,
    onCaption: onCaption,
    shade: shadeFill,
    onShade: onShade,
    shadeText: _comicRead(shadeFill, grounds),
    shadeTint: tint,
    currentUserTint: you,
    drama: drama,
    paper: paper,
    onPaper: onPaper,
    onPaperSecondary: onPaperSecondary,
    control: paper,
    hint: _comicRead(quiet, [paper]),
    track: well,
    unlit: unlit,
    dotTint: dotTint,
    currentUserDot: currentUserDot,
    lampDot: _comicRead(drama, [captionFill], 1.8),
    cover: shadeFill,
    coverRay: blend(shadeFill, onShade, .2),
    coverDot: blend(shadeFill, onShade, .15),
    coverDotSecondary: blend(shadeFill, onShade, .3),
    head: captionFill,
    headRing: ink,
    currentUserHead: actFill,
    currentUserHeadRing: ink,
    monogramSecondary: captionFill,
    monogramTertiary: captionFill,
    art1: captionFill,
    art2: tint,
    art3: you,
    art4: shadeFill,
    artDot: dotTint,
    art4Dot: blend(shadeFill, onShade, .2),
    nightLine: ink,
    series: base.series,
  );
}
