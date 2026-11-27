/// Appliance's theme: its colours (the plastic, the print, the signal), its
/// type, its measures, its motion, its density, and the [ApplianceTheme]
/// every app installs once in its `builder:`.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'page_transitions.dart';

/// How one part of Appliance looks, as Material's `ButtonStyle` is: every
/// slot a `WidgetStateProperty`, read from a part's `style:` first, then from
/// its component theme on [ApplianceThemeData], then from the look's own
/// default.
///
/// ```dart
/// final wide = ApplianceStyle(padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)));
/// ```
typedef ApplianceStyle = RawStyle;

/// How tight Appliance's controls stand: [RawDensity.standard] (a 48 px
/// key), [RawDensity.comfortable] (44) or [RawDensity.compact] (40).
/// A control's tap target stays at the floor for the input whatever the
/// density. [ApplianceThemeData.density] defaults to
/// [RawDensity.adaptivePlatformDensity]: compact on a desktop, standard
/// on a phone.
typedef ApplianceDensity = RawDensity;

/// The depth a part stands at, lit from the top: every part uses one, and a
/// change of state moves it between them (a press sinks a raised key).
enum ApplianceDepth {
  /// Below the panel: a field's well, a display, a selector's trough, a
  /// switch's slot. Shaded along its top inside edge.
  sunken,

  /// Flush with the housing: a faceplate seated at a parting line, the
  /// housing itself.
  level,

  /// Above the panel: a key, a cap, a knob, a selector's block. A highlight
  /// on its top edge and a soft shade under it.
  raised,
}

/// The look's measures. Corners, the light's direction and the three depths
/// are not settings: they are what Appliance is.
abstract final class ApplianceMetrics {
  /// A faceplate's corner: a moulded panel's generous radius.
  static const double panelRadius = 14;

  /// A key's corner.
  static const double keyRadius = 10;

  /// A well's corner (a field, a select's face).
  static const double wellRadius = 10;

  /// A small key's corner (a checkbox).
  static const double smallKeyRadius = 6;

  /// A selector's trough corner; its block stands [troughInset] inside with
  /// the concentric corner (`troughRadius - troughInset`).
  static const double troughRadius = 12;

  /// The room between a trough's wall and its block, on every side.
  static const double troughInset = 4;

  /// A lid's corner (a dialog, a sheet's top, a menu).
  static const double lidRadius = 16;

  /// A key's height at [RawDensity.standard], before density.
  static const double controlHeight = 48;

  /// How far a pressed key travels into the panel.
  static const double pressTravel = 1.5;

  /// The width of a focused part's lit rim, inside its edge.
  static const double focusWidth = 1.5;

  /// A lamp's diameter.
  static const double lampSize = 8;

  /// How far a key's lamp stands in from its top and start corner.
  static const double lampInset = 8;

  /// A parting line's width: a shaded line and a lit one.
  static const double seamWidth = 2;

  /// The room between a slide switch's slot and its cap, each side.
  static const double capInset = 3;

  /// The room round a display window's words, each side.
  static const double windowInset = 4;

  /// The widest a form, a dialog or a reading column stands.
  static const double readingWidth = 560;
}

/// Appliance's spacing, on a 4 px grid ([RawSpacingScope] declares it).
abstract final class ApplianceSpacing {
  /// The grid every gap, inset and offset stands on.
  static const double grid = 4;

  /// Inside a control: a lamp and its words.
  static const double tight = 4;

  /// A hairline, under the grid: a tree's rows apart, a scroll thumb in its
  /// track, a small picture in its ring, a tag's key off its neighbours.
  static const double hair = 1;

  /// Two hairlines, under the grid: the caps of one shortcut, a picture in
  /// its ring, a term over its value on a phone.
  static const double nudge = 2;

  /// Between a label and its field, between lines of one item.
  static const double small = 8;

  /// Between keys in a row, a short gap.
  static const double medium = 12;

  /// A faceplate's inset, and the page margin on a phone.
  static const double regular = 16;

  /// Between groups, and the page margin on a tablet.
  static const double large = 24;

  /// Between sections, and the page margin on a desktop.
  static const double extraLarge = 32;

  /// Above a page's first heading on a wide screen.
  static const double huge = 48;

  /// The page margin for a window [width] wide: 16 on a phone, 24 on a
  /// tablet, 32 on a desktop.
  static double pageMargin(double width) => width >= 1024
      ? extraLarge
      : width >= 600
      ? large
      : regular;
}

/// Appliance's motion: springs from the physics of its objects. A key goes
/// down firmly and comes back with a little spring; a switch or a selector's
/// block snaps through to its detent; a lamp warms up and cools down; a lid
/// rises and settles. Run them through `RawMotionPolicy`, which critically
/// damps every spring under Reduce Motion.
abstract final class ApplianceMotion {
  /// A key going down: firm, no bounce.
  static const ({double dampingRatio, double stiffness}) press = (
    dampingRatio: 1,
    stiffness: 2600,
  );

  /// A key coming back up on its spring: a touch of give.
  static const ({double dampingRatio, double stiffness}) release = (
    dampingRatio: 0.72,
    stiffness: 1500,
  );

  /// A switch's cap or a selector's block snapping through to its detent.
  static const ({double dampingRatio, double stiffness}) snap = (
    dampingRatio: 0.8,
    stiffness: 900,
  );

  /// A lamp lighting or going out, a print changing colour.
  static const ({double dampingRatio, double stiffness}) lamp = (
    dampingRatio: 1,
    stiffness: 1200,
  );

  /// A lid (a dialog, a menu, a select's list) rising and settling.
  static const ({double dampingRatio, double stiffness}) lid = (
    dampingRatio: 1,
    stiffness: 700,
  );

  /// A sheet sliding up its track.
  static const ({double dampingRatio, double stiffness}) slide = (
    dampingRatio: 1,
    stiffness: 520,
  );
}

/// Appliance's colours, by role: the plastic (the grained housing, the
/// smooth faceplates, the keys and wells), the print (the legends), the
/// signal (the main key, the lamps, the focus backlight) and the display (by
/// day a pale LCD with dark figures, as on a clock radio; by night smoked
/// glass with lit ones).
///
/// [ApplianceColors.light] is warm-white plastic in a lit room;
/// [ApplianceColors.dark] the same plastic in a dim one, its legends
/// backlit, its lamps blooming. [ApplianceColors.from] recolours the finish
/// and the signal and keeps the contrast.
@immutable
class ApplianceColors with Diagnosticable {
  /// Every role given.
  const ApplianceColors({
    required this.brightness,
    required this.housingTop,
    required this.housingBottom,
    required this.face,
    required this.well,
    required this.trough,
    required this.slot,
    required this.keyTop,
    required this.keyBottom,
    required this.keyDownTop,
    required this.keyDownBottom,
    required this.print,
    required this.printMuted,
    required this.printDisabled,
    required this.hairline,
    required this.seamShade,
    required this.seamLight,
    required this.shade,
    required this.highlight,
    required this.signal,
    required this.signalTop,
    required this.signalBottom,
    required this.onSignal,
    required this.signalInk,
    required this.focus,
    required this.lampOff,
    required this.danger,
    required this.onDanger,
    required this.display,
    required this.onDisplay,
    required this.metalLight,
    required this.metalDark,
    required this.scrim,
    required this.ready,
  });

  /// Warm-white moulded plastic in a lit room, signal orange.
  static const ApplianceColors light = ApplianceColors(
    brightness: Brightness.light,
    housingTop: Color(0xFFC7BFB2),
    housingBottom: Color(0xFFBCB3A5),
    face: Color(0xFFF7F6F2),
    well: Color(0xFFFDFCFA),
    trough: Color(0xFFE1DDD5),
    slot: Color(0xFF3D3B37),
    keyTop: Color(0xFFFBFAF7),
    keyBottom: Color(0xFFEBE8E2),
    keyDownTop: Color(0xFFD8D3CA),
    keyDownBottom: Color(0xFFDEDAD2),
    print: Color(0xFF262523),
    printMuted: Color(0xFF423E39),
    printDisabled: Color(0xFF8F8A82),
    hairline: Color(0x17281E18),
    seamShade: Color(0x4D463A2E),
    seamLight: Color(0xE6FFFFFF),
    shade: Color(0xFF3C3024),
    highlight: Color(0xF2FFFFFF),
    signal: Color(0xFFEE6A26),
    signalTop: Color(0xFFF78A4C),
    signalBottom: Color(0xFFE05E1E),
    onSignal: Color(0xFF1D1A17),
    signalInk: Color(0xFF802A00),
    focus: Color(0xFFAC3A02),
    lampOff: Color(0xFFC9C4BB),
    danger: Color(0xFFB3261E),
    onDanger: Color(0xFFFFFFFF),
    display: Color(0xFFD9DCCB),
    onDisplay: Color(0xFF1F221C),
    metalLight: Color(0xFFE9EAEB),
    metalDark: Color(0xFFB9BBBE),
    scrim: Color(0x6626201A),
    ready: Color(0xFF2E8540),
  );

  /// The same plastic in a dim room: the housing warm grey, the legends
  /// backlit, the lamps blooming.
  static const ApplianceColors dark = ApplianceColors(
    brightness: Brightness.dark,
    housingTop: Color(0xFF1E1D1B),
    housingBottom: Color(0xFF191817),
    face: Color(0xFF383733),
    well: Color(0xFF1F1E1C),
    trough: Color(0xFF252421),
    slot: Color(0xFF161513),
    keyTop: Color(0xFF4A4944),
    keyBottom: Color(0xFF3E3D39),
    keyDownTop: Color(0xFF2A2926),
    keyDownBottom: Color(0xFF302F2C),
    print: Color(0xFFF1EBE1),
    printMuted: Color(0xFFBEB7AB),
    printDisabled: Color(0xFF8A857C),
    hairline: Color(0x12FFF0DC),
    seamShade: Color(0x73000000),
    seamLight: Color(0x0FFFFFFF),
    shade: Color(0xFF000000),
    highlight: Color(0x1AFFFFFF),
    signal: Color(0xFFEE6A26),
    signalTop: Color(0xFFF78A4C),
    signalBottom: Color(0xFFE05E1E),
    onSignal: Color(0xFF1D1A17),
    signalInk: Color(0xFFFEA168),
    focus: Color(0xFFF2803F),
    lampOff: Color(0xFF4E4C47),
    // Rose, a step from salmon, so the orange signal's words stay apart.
    danger: Color(0xFFFF8A8A),
    onDanger: Color(0xFF2A0A06),
    display: Color(0xFF171614),
    onDisplay: Color(0xFFF1EBE1),
    metalLight: Color(0xFF8D8F92),
    metalDark: Color(0xFF5D5F62),
    scrim: Color(0x99000000),
    ready: Color(0xFF63C77A),
  );

  /// Appliance by [brightness] with the plastic moulded toward [finish] (its
  /// hue at each part's own tone, a little of its chroma: the tones stay the
  /// look's, so the print keeps its contrast; by night the plastic holds
  /// little chroma, so a cream finish is a warm graphite, never brown) and
  /// [signal] for the main key, the lamps and the focus backlight: the named
  /// colour with the print or white on it, whichever reads at 4.5:1 (moved as
  /// little as it must when neither does); its words the nearest tone of its
  /// hue that reads at 4.5:1 on a faceplate, a well and a key, and its focus
  /// the nearest that reads at 3:1 on the housing and a faceplate.
  ///
  /// ```dart
  /// final mint = ApplianceColors.from(brightness: Brightness.light, finish: const Color(0xFFD9EDE4), signal: const Color(0xFF1F8A70));
  /// ```
  factory ApplianceColors.from({
    required Brightness brightness,
    Color? finish,
    Color? signal,
  }) {
    var colors = brightness == Brightness.light ? light : dark;
    if (finish != null) colors = _moulded(colors, finish);
    if (signal != null) colors = _signalled(colors, signal);
    return colors;
  }

  /// Appliance's palette [name] (one of [ApplianceThemeData.palettes]) for
  /// [brightness]: `warm` ([light] and [dark]: warm-white plastic, an
  /// orange signal), `mint` (mint plastic, a petrol signal), `butter`
  /// (cream plastic, a grape signal), `powder` (powder-blue plastic, a blue
  /// signal), `blush` (pink plastic, a berry signal) or `slate` (cool grey
  /// plastic, an amber signal). Each is the warm plastic at its own
  /// tones in another hue ([ApplianceColors.from]), so every legend reads as
  /// it does in warm. An unknown name gives warm.
  ///
  /// ```dart
  /// final mint = ApplianceColors.preset('mint', Brightness.dark);
  /// ```
  factory ApplianceColors.preset(String name, Brightness brightness) {
    final finish = _finishes[name];
    if (finish == null) return brightness == Brightness.dark ? dark : light;
    return _presets[(name, brightness)] ??= ApplianceColors.from(
      brightness: brightness,
      finish: finish.plastic,
      signal: finish.signal,
    );
  }

  static final Map<(String, Brightness), ApplianceColors> _presets = {};

  /// Day or night.
  final Brightness brightness;

  /// The housing's grained plastic at the top of a bar or a page.
  final Color housingTop;

  /// The housing's grained plastic at the bottom.
  final Color housingBottom;

  /// A faceplate: the smooth plastic every reading surface is.
  final Color face;

  /// A field's sunken well.
  final Color well;

  /// A selector's or a switch's sunken trough.
  final Color trough;

  /// A slider's dark slot.
  final Color slot;

  /// A key's plastic at its top.
  final Color keyTop;

  /// A key's plastic at its bottom.
  final Color keyBottom;

  /// A latched key's plastic at its top (it sits low, in shade).
  final Color keyDownTop;

  /// A latched key's plastic at its bottom.
  final Color keyDownBottom;

  /// The printed legends: titles, words, glyphs.
  final Color print;

  /// Secondary legends: a row's supporting line, a caption, a field's hint:
  /// 4.5:1 on the housing, a faceplate, a well and a key.
  final Color printMuted;

  /// A disabled part's legend.
  final Color printDisabled;

  /// A hairline seam between rows of one faceplate.
  final Color hairline;

  /// The parting line's shaded side.
  final Color seamShade;

  /// The parting line's lit side, just below it.
  final Color seamLight;

  /// The colour every shade is cast in, at its own strength.
  final Color shade;

  /// The highlight the light leaves on a raised part's top edge.
  final Color highlight;

  /// The signal: the main key's plastic, a lamp's light.
  final Color signal;

  /// The signal key's plastic at its top.
  final Color signalTop;

  /// The signal key's plastic at its bottom.
  final Color signalBottom;

  /// Legends on the signal key.
  final Color onSignal;

  /// The signal as words (a link, a price you can act on): 4.5:1 on the
  /// housing, a faceplate, a well and a key.
  final Color signalInk;

  /// The focus backlight: the signal, deep enough for 3:1 on the housing and
  /// on a faceplate.
  final Color focus;

  /// A lamp that is out.
  final Color lampOff;

  /// A destructive action's legend, and an error's.
  final Color danger;

  /// Legends on a danger key.
  final Color onDanger;

  /// A display window's glass (a chart's, a readout's, a toast's): by day a
  /// pale LCD, by night smoked glass.
  final Color display;

  /// A display's figures: dark segments on the day's LCD, a lit legend on
  /// the night's glass.
  final Color onDisplay;

  /// Brushed aluminium in the light.
  final Color metalLight;

  /// Brushed aluminium in shade.
  final Color metalDark;

  /// What dims the housing under a lid.
  final Color scrim;

  /// The ready lamp: a job done, a success.
  final Color ready;

  /// Black or white words, whichever reads better on [background].
  Color onColor(Color background) =>
      applianceContrast(print, background) >=
          applianceContrast(face, background)
      ? print
      : face;

  /// A copy with the given roles replaced.
  ApplianceColors copyWith({
    Brightness? brightness,
    Color? housingTop,
    Color? housingBottom,
    Color? face,
    Color? well,
    Color? trough,
    Color? slot,
    Color? keyTop,
    Color? keyBottom,
    Color? keyDownTop,
    Color? keyDownBottom,
    Color? print,
    Color? printMuted,
    Color? printDisabled,
    Color? hairline,
    Color? seamShade,
    Color? seamLight,
    Color? shade,
    Color? highlight,
    Color? signal,
    Color? signalTop,
    Color? signalBottom,
    Color? onSignal,
    Color? signalInk,
    Color? focus,
    Color? lampOff,
    Color? danger,
    Color? onDanger,
    Color? display,
    Color? onDisplay,
    Color? metalLight,
    Color? metalDark,
    Color? scrim,
    Color? ready,
  }) => ApplianceColors(
    brightness: brightness ?? this.brightness,
    housingTop: housingTop ?? this.housingTop,
    housingBottom: housingBottom ?? this.housingBottom,
    face: face ?? this.face,
    well: well ?? this.well,
    trough: trough ?? this.trough,
    slot: slot ?? this.slot,
    keyTop: keyTop ?? this.keyTop,
    keyBottom: keyBottom ?? this.keyBottom,
    keyDownTop: keyDownTop ?? this.keyDownTop,
    keyDownBottom: keyDownBottom ?? this.keyDownBottom,
    print: print ?? this.print,
    printMuted: printMuted ?? this.printMuted,
    printDisabled: printDisabled ?? this.printDisabled,
    hairline: hairline ?? this.hairline,
    seamShade: seamShade ?? this.seamShade,
    seamLight: seamLight ?? this.seamLight,
    shade: shade ?? this.shade,
    highlight: highlight ?? this.highlight,
    signal: signal ?? this.signal,
    signalTop: signalTop ?? this.signalTop,
    signalBottom: signalBottom ?? this.signalBottom,
    onSignal: onSignal ?? this.onSignal,
    signalInk: signalInk ?? this.signalInk,
    focus: focus ?? this.focus,
    lampOff: lampOff ?? this.lampOff,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    display: display ?? this.display,
    onDisplay: onDisplay ?? this.onDisplay,
    metalLight: metalLight ?? this.metalLight,
    metalDark: metalDark ?? this.metalDark,
    scrim: scrim ?? this.scrim,
    ready: ready ?? this.ready,
  );

  List<Color> get _all => [
    housingTop,
    housingBottom,
    face,
    well,
    trough,
    slot,
    keyTop,
    keyBottom,
    keyDownTop,
    keyDownBottom,
    print,
    printMuted,
    printDisabled,
    hairline,
    seamShade,
    seamLight,
    shade,
    highlight,
    signal,
    signalTop,
    signalBottom,
    onSignal,
    signalInk,
    focus,
    lampOff,
    danger,
    onDanger,
    display,
    onDisplay,
    metalLight,
    metalDark,
    scrim,
    ready,
  ];

  /// Between [a] and [b] by [t]: day turning to night.
  static ApplianceColors lerp(ApplianceColors a, ApplianceColors b, double t) {
    if (identical(a, b)) return a;
    final x = a._all;
    final y = b._all;
    Color at(int i) => Color.lerp(x[i], y[i], t)!;
    return ApplianceColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      housingTop: at(0),
      housingBottom: at(1),
      face: at(2),
      well: at(3),
      trough: at(4),
      slot: at(5),
      keyTop: at(6),
      keyBottom: at(7),
      keyDownTop: at(8),
      keyDownBottom: at(9),
      print: at(10),
      printMuted: at(11),
      printDisabled: at(12),
      hairline: at(13),
      seamShade: at(14),
      seamLight: at(15),
      shade: at(16),
      highlight: at(17),
      signal: at(18),
      signalTop: at(19),
      signalBottom: at(20),
      onSignal: at(21),
      signalInk: at(22),
      focus: at(23),
      lampOff: at(24),
      danger: at(25),
      onDanger: at(26),
      display: at(27),
      onDisplay: at(28),
      metalLight: at(29),
      metalDark: at(30),
      scrim: at(31),
      ready: at(32),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApplianceColors &&
      other.brightness == brightness &&
      listEquals(other._all, _all);

  @override
  int get hashCode => Object.hash(brightness, Object.hashAll(_all));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(ColorProperty('face', face))
      ..add(ColorProperty('print', print))
      ..add(ColorProperty('signal', signal));
  }
}

/// The contrast ratio of [a] on [b], as WCAG measures it (1 to 21;
/// [RawPalette.contrastRatio]: a translucent [a] is read laid over [b]).
double applianceContrast(Color a, Color b) => RawPalette.contrastRatio(a, b);

// The most chroma a finish ([ApplianceColors.from]'s `finish`) gives the
// plastic: a pale tint, so a strong colour tints it and never paints it.
const double _finishTint = 14;

// [base]'s plastic moulded in [finish]'s hue, each part at its own tone.
ApplianceColors _moulded(ApplianceColors base, Color finish) {
  final hct = RawHct.fromColor(finish);
  final tones = RawNeutralTones.of(
    hct.withChroma(math.min(hct.chroma, _finishTint)).toColor(),
  );
  Color at(Color c) => c.a == 0
      ? c
      : tones.tone(RawHct.fromColor(c).tone).withValues(alpha: c.a);
  return base.copyWith(
    housingTop: at(base.housingTop),
    housingBottom: at(base.housingBottom),
    face: at(base.face),
    well: at(base.well),
    trough: at(base.trough),
    keyTop: at(base.keyTop),
    keyBottom: at(base.keyBottom),
    keyDownTop: at(base.keyDownTop),
    keyDownBottom: at(base.keyDownBottom),
    lampOff: at(base.lampOff),
  );
}

// [base] with its signal key moulded in [signal] (RawPalette.accentFill,
// the named colour kept whenever the print or white reads on it), its words
// and its focus the nearest tones of its hue that read on [base]'s plastic.
ApplianceColors _signalled(ApplianceColors base, Color signal) {
  final key = RawPalette.accentFill(
    signal,
    brightness: base.brightness,
    rule: RawAccentRule.named,
    darkInk: ApplianceColors.light.onSignal,
  );
  final hsl = HSLColor.fromColor(key.fill);
  Color shift(double by) =>
      hsl.withLightness((hsl.lightness + by).clamp(0.0, 1.0)).toColor();
  return base.copyWith(
    signal: key.fill,
    // The moulding's light and shade, each at the nearest tone where the
    // legend still reads 4.5:1.
    signalTop: RawPalette.readableTone(shift(0.08), on: [key.ink]),
    signalBottom: RawPalette.readableTone(shift(-0.05), on: [key.ink]),
    onSignal: key.ink,
    // Words: a link, a text key, a lit row, at 4.5:1 on the housing, a
    // faceplate, a well and a key, as warm's do.
    signalInk: RawPalette.readableTone(
      signal,
      on: [
        base.housingTop,
        base.housingBottom,
        base.face,
        base.well,
        base.keyTop,
        base.keyBottom,
      ],
    ),
    // The backlight round a focused key's foot, on the housing or a
    // faceplate.
    focus: RawPalette.readableTone(
      signal,
      on: [base.housingTop, base.housingBottom, base.face],
      ratio: 3,
    ),
  );
}

// A finish of Appliance beside warm (ApplianceColors.light and dark): the
// plastic's tint and the signal.
class _Finish {
  const _Finish(this.plastic, this.signal);

  final Color plastic;
  final Color signal;
}

// Appliance's finishes beside warm.
const Map<String, _Finish> _finishes = {
  // Petrol, not green: the ready lamp is green.
  'mint': _Finish(Color(0xFFD9EDE4), Color(0xFF0F7C8C)),
  // Grape and berry, not red: the danger lamp is red.
  'butter': _Finish(Color(0xFFF3E7C2), Color(0xFF7A4FB0)),
  'powder': _Finish(Color(0xFFD5E2EF), Color(0xFF2F6BC2)),
  'blush': _Finish(Color(0xFFF2DADD), Color(0xFFA63A8F)),
  'slate': _Finish(Color(0xFFCDD2D8), Color(0xFFF0A81C)),
};

/// Appliance's text styles: four a screen reads in (a title, the body, a
/// secondary line and a key's label), the caps legend printed over a group,
/// a display for the one figure a screen leads with, and a heading for a top
/// bar or a panel.
@immutable
class ApplianceTextTheme with Diagnosticable {
  /// Every style given.
  const ApplianceTextTheme({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.secondary,
    required this.label,
    required this.legend,
    required this.figure,
  });

  /// Appliance's styles in [colors], set in [family] (Barlow by default)
  /// from [package].
  factory ApplianceTextTheme.from(
    ApplianceColors colors, {
    String family = applianceFontFamily,
    String? package = applianceFontPackage,
    List<String> fallback = const [],
  }) {
    TextStyle style(
      double size,
      double height,
      FontWeight weight,
      Color color, {
      double tracking = 0,
    }) => TextStyle(
      inherit: false,
      fontFamily: family,
      package: package,
      fontFamilyFallback: fallback.isEmpty ? null : fallback,
      fontSize: size,
      height: height / size,
      leadingDistribution: TextLeadingDistribution.even,
      fontWeight: weight,
      letterSpacing: tracking,
      color: color,
      textBaseline: TextBaseline.alphabetic,
      decoration: TextDecoration.none,
    );
    return ApplianceTextTheme(
      display: style(30, 36, FontWeight.w600, colors.print, tracking: -0.3),
      title: style(22, 28, FontWeight.w600, colors.print, tracking: -0.1),
      heading: style(17, 22, FontWeight.w500, colors.print),
      body: style(16, 22, FontWeight.w400, colors.print),
      secondary: style(14, 20, FontWeight.w400, colors.printMuted),
      label: style(16, 20, FontWeight.w500, colors.print),
      legend: style(12, 16, FontWeight.w500, colors.printMuted, tracking: 1.4),
      figure: style(
        16,
        22,
        FontWeight.w500,
        colors.print,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  /// The one figure or name a screen leads with: 30 px.
  final TextStyle display;

  /// A page's title: 22 px.
  final TextStyle title;

  /// A top bar's title, a faceplate's heading: 17 px.
  final TextStyle heading;

  /// What people read: 16 px.
  final TextStyle body;

  /// A supporting line: 14 px, muted.
  final TextStyle secondary;

  /// A key's legend: 16 px medium.
  final TextStyle label;

  /// The caps legend printed over a group: 12 px, tracked; set it in
  /// capitals.
  final TextStyle legend;

  /// Figures that line up (a price, a count): tabular, 16 px medium.
  final TextStyle figure;

  List<TextStyle> get _all => [
    display,
    title,
    heading,
    body,
    secondary,
    label,
    legend,
    figure,
  ];

  /// A copy with the given styles replaced.
  ApplianceTextTheme copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? secondary,
    TextStyle? label,
    TextStyle? legend,
    TextStyle? figure,
  }) => ApplianceTextTheme(
    display: display ?? this.display,
    title: title ?? this.title,
    heading: heading ?? this.heading,
    body: body ?? this.body,
    secondary: secondary ?? this.secondary,
    label: label ?? this.label,
    legend: legend ?? this.legend,
    figure: figure ?? this.figure,
  );

  /// These styles moved from [from] to [to]: a style in [from]'s print or
  /// muted print takes [to]'s; its face, sizes and any other colour stay.
  ApplianceTextTheme _recoloured(ApplianceColors from, ApplianceColors to) {
    TextStyle on(TextStyle style) => style.color == from.print
        ? style.copyWith(color: to.print)
        : style.color == from.printMuted
        ? style.copyWith(color: to.printMuted)
        : style;
    return ApplianceTextTheme(
      display: on(display),
      title: on(title),
      heading: on(heading),
      body: on(body),
      secondary: on(secondary),
      label: on(label),
      legend: on(legend),
      figure: on(figure),
    );
  }

  /// Between [a] and [b] by [t].
  static ApplianceTextTheme lerp(
    ApplianceTextTheme a,
    ApplianceTextTheme b,
    double t,
  ) {
    if (identical(a, b)) return a;
    TextStyle at(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return ApplianceTextTheme(
      display: at(a.display, b.display),
      title: at(a.title, b.title),
      heading: at(a.heading, b.heading),
      body: at(a.body, b.body),
      secondary: at(a.secondary, b.secondary),
      label: at(a.label, b.label),
      legend: at(a.legend, b.legend),
      figure: at(a.figure, b.figure),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApplianceTextTheme && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle>('body', body))
      ..add(DiagnosticsProperty<TextStyle>('title', title));
  }
}

/// Appliance's theme: its [colors], its [textTheme], its [density], whether
/// its housing carries its moulded grain ([texture]), and a component style
/// per part, as Flutter's `ThemeData` holds a `ButtonStyle` per button.
///
/// [ApplianceThemeData.light] and [ApplianceThemeData.dark] are warm, the
/// look's default finish; [ApplianceThemeData.preset] gives each of its six
/// palettes ([palettes]) and [ApplianceThemeData.from] recolours the finish
/// and the signal for a brand.
///
/// ```dart
/// ApplianceTheme(data: ApplianceThemeData.light(), child: child)
/// ```
@immutable
class ApplianceThemeData with Diagnosticable {
  /// Every setting given.
  ApplianceThemeData({
    required this.colors,
    ApplianceTextTheme? textTheme,
    RawDensity? density,
    this.texture = true,
    this.buttonStyle,
    this.filledButtonStyle,
    this.textButtonStyle,
    this.iconButtonStyle,
    this.textFieldStyle,
    this.selectStyle,
    this.menuStyle,
    this.toggleStyle,
    this.selectorStyle,
    this.sliderStyle,
    this.stepperStyle,
    this.panelStyle,
    this.listTileStyle,
    this.navigationStyle,
    this.dialogStyle,
    this.toastStyle,
    this.linkStyle,
    this.chipStyle,
    this.tagStyle,
    this.displayStyle,
    this.tooltipStyle,
    this.popoverStyle,
    this.tableStyle,
    this.bannerStyle,
    this.progressStyle,
    this.chartStyle,
    this.avatarStyle,
    this.calendarStyle,
  }) : textTheme = textTheme ?? ApplianceTextTheme.from(colors),
       density = density ?? RawDensity.adaptivePlatformDensity;

  /// Warm-white plastic by day.
  factory ApplianceThemeData.light({RawDensity? density}) =>
      ApplianceThemeData(colors: ApplianceColors.light, density: density);

  /// The same plastic in a dim room.
  factory ApplianceThemeData.dark({RawDensity? density}) =>
      ApplianceThemeData(colors: ApplianceColors.dark, density: density);

  /// The look's six palettes, the first its default, each by day and by
  /// night: what an app's palette picker lists (each [RawNamedPalette] its
  /// label, and its signal key and its plastic as swatches) and the
  /// [RawNamedPalette.id] an app stores and hands back to [preset] or
  /// [ApplianceHost.palette]. warm: warm-white plastic, an orange signal;
  /// mint: mint plastic, a petrol signal; butter: cream plastic, a grape
  /// signal; powder: powder-blue plastic, a blue signal; blush: pink
  /// plastic, a berry signal; slate: cool grey plastic, an amber signal. No
  /// signal is green or red, so the ready lamp and the danger lamp stay
  /// apart from it.
  static const List<RawNamedPalette> palettes = <RawNamedPalette>[
    RawNamedPalette(
      id: 'warm',
      label: 'Warm',
      swatches: [Color(0xFFEE6A26), Color(0xFFF7F6F2)],
      darkSwatches: [Color(0xFFEE6A26), Color(0xFF383733)],
    ),
    RawNamedPalette(
      id: 'mint',
      label: 'Mint',
      swatches: [Color(0xFF0F7C8C), Color(0xFFE7FBF2)],
      darkSwatches: [Color(0xFF0F7C8C), Color(0xFF323836)],
    ),
    RawNamedPalette(
      id: 'butter',
      label: 'Butter',
      swatches: [Color(0xFF7A4FB0), Color(0xFFFFF6DC)],
      darkSwatches: [Color(0xFF7A4FB0), Color(0xFF3A372D)],
    ),
    RawNamedPalette(
      id: 'powder',
      label: 'Powder',
      swatches: [Color(0xFF2F6BC2), Color(0xFFF0F7FF)],
      darkSwatches: [Color(0xFF2F6BC2), Color(0xFF33373B)],
    ),
    RawNamedPalette(
      id: 'blush',
      label: 'Blush',
      swatches: [Color(0xFFA63A8F), Color(0xFFFFF3F4)],
      darkSwatches: [Color(0xFFA63A8F), Color(0xFF3F3436)],
    ),
    RawNamedPalette(
      id: 'slate',
      label: 'Slate',
      swatches: [Color(0xFFF0A81C), Color(0xFFF2F6FD)],
      darkSwatches: [Color(0xFFF0A81C), Color(0xFF33383B)],
    ),
  ];

  /// The palette [id], one of [palettes], for [brightness]
  /// ([ApplianceColors.preset]).
  ///
  /// ```dart
  /// ApplianceThemeData.preset('mint', Brightness.dark)
  /// ```
  factory ApplianceThemeData.preset(
    String id,
    Brightness brightness, {
    RawDensity? density,
  }) {
    assert(
      palettes.any((p) => p.id == id),
      'Appliance has no palette "$id": ${[for (final p in palettes) p.id]}',
    );
    return ApplianceThemeData(
      colors: ApplianceColors.preset(id, brightness),
      density: density,
    );
  }

  /// [brightness]'s Appliance, or a brand's: the plastic tinted toward
  /// [finish] and the signal in [signal] ([ApplianceColors.from]), set in
  /// [fontFamily] when given. Given none of the three, it is
  /// [ApplianceThemeData.light] or [ApplianceThemeData.dark]. Corners, light
  /// and depth stay the look's.
  ///
  /// ```dart
  /// ApplianceThemeData.from(brightness: Brightness.light, signal: const Color(0xFF2F7D5B))
  /// ```
  factory ApplianceThemeData.from({
    required Brightness brightness,
    Color? finish,
    Color? signal,
    String? fontFamily,
    String? fontPackage,
    RawDensity? density,
  }) {
    final colors = ApplianceColors.from(
      brightness: brightness,
      finish: finish,
      signal: signal,
    );
    return ApplianceThemeData(
      colors: colors,
      textTheme: fontFamily == null
          ? null
          : ApplianceTextTheme.from(
              colors,
              family: fontFamily,
              package: fontPackage,
            ),
      density: density,
    );
  }

  /// The colours.
  final ApplianceColors colors;

  /// The text styles.
  final ApplianceTextTheme textTheme;

  /// How tight the controls stand.
  final RawDensity density;

  /// Whether the housing carries its fine moulded grain. Off under the
  /// platform's high contrast whatever this says.
  final bool texture;

  /// [ApplianceButton]'s ordinary key.
  final ApplianceStyle? buttonStyle;

  /// [ApplianceButton.filled]: the signal key.
  final ApplianceStyle? filledButtonStyle;

  /// [ApplianceButton.text]: a printed legend with no key round it.
  final ApplianceStyle? textButtonStyle;

  /// [ApplianceIconButton].
  final ApplianceStyle? iconButtonStyle;

  /// [ApplianceTextField]'s well.
  final ApplianceStyle? textFieldStyle;

  /// [ApplianceSelect]'s key.
  final ApplianceStyle? selectStyle;

  /// Every open list: a select's, a menu's.
  final ApplianceStyle? menuStyle;

  /// [ApplianceCheckbox], [ApplianceRadio] and [ApplianceSwitch].
  final ApplianceStyle? toggleStyle;

  /// [ApplianceSegmentedButton] and [ApplianceTabBar]: the slide selector.
  final ApplianceStyle? selectorStyle;

  /// [ApplianceSlider]: the fader.
  final ApplianceStyle? sliderStyle;

  /// [ApplianceStepper].
  final ApplianceStyle? stepperStyle;

  /// [AppliancePanel]: a faceplate.
  final ApplianceStyle? panelStyle;

  /// [ApplianceListTile].
  final ApplianceStyle? listTileStyle;

  /// The navigation keys: [ApplianceNavigationBar],
  /// [ApplianceNavigationRail], [ApplianceSideNavigation].
  final ApplianceStyle? navigationStyle;

  /// [ApplianceDialog] and the sheet's lid.
  final ApplianceStyle? dialogStyle;

  /// A toast's display window.
  final ApplianceStyle? toastStyle;

  /// [ApplianceLink]: words printed in the signal's ink.
  final ApplianceStyle? linkStyle;

  /// [ApplianceChip]: the small keys of a filter or a choice.
  final ApplianceStyle? chipStyle;

  /// [ApplianceTag]: a label printed on a small plate.
  final ApplianceStyle? tagStyle;

  /// The display windows: [ApplianceOtpField]'s cells, [ApplianceTimePicker]'s figures.
  final ApplianceStyle? displayStyle;

  /// [ApplianceTooltip]: a small display window by its anchor.
  final ApplianceStyle? tooltipStyle;

  /// [AppliancePopover] and [ApplianceHoverCard]: a lid over the page.
  final ApplianceStyle? popoverStyle;

  /// [ApplianceTable] and [ApplianceDataTable].
  final ApplianceStyle? tableStyle;

  /// [ApplianceBanner] and [ApplianceStatusView]'s notice.
  final ApplianceStyle? bannerStyle;

  /// [ApplianceProgressBar], [ApplianceProgressRing] and [ApplianceMeter].
  final ApplianceStyle? progressStyle;

  /// The charts: [ApplianceLineChart], [ApplianceBarChart], [ApplianceAreaChart], [ApplianceDonutChart], [ApplianceSparkline].
  final ApplianceStyle? chartStyle;

  /// [ApplianceAvatar]: a picture or initials in a round window.
  final ApplianceStyle? avatarStyle;

  /// [ApplianceCalendar] and the date pickers' month.
  final ApplianceStyle? calendarStyle;

  /// Day or night.
  Brightness get brightness => colors.brightness;

  /// A key's height at this density.
  double get controlHeight =>
      ApplianceMetrics.controlHeight + density.heightDelta;

  /// The typeface's cap height as a fraction of its size.
  double get capHeightFactor => applianceCapHeightFactor;

  /// A copy with the given settings replaced. New [colors] with no
  /// [textTheme] recolour the text theme, keeping its face and sizes.
  ApplianceThemeData copyWith({
    ApplianceColors? colors,
    ApplianceTextTheme? textTheme,
    RawDensity? density,
    bool? texture,
    ApplianceStyle? buttonStyle,
    ApplianceStyle? filledButtonStyle,
    ApplianceStyle? textButtonStyle,
    ApplianceStyle? iconButtonStyle,
    ApplianceStyle? textFieldStyle,
    ApplianceStyle? selectStyle,
    ApplianceStyle? menuStyle,
    ApplianceStyle? toggleStyle,
    ApplianceStyle? selectorStyle,
    ApplianceStyle? sliderStyle,
    ApplianceStyle? stepperStyle,
    ApplianceStyle? panelStyle,
    ApplianceStyle? listTileStyle,
    ApplianceStyle? navigationStyle,
    ApplianceStyle? dialogStyle,
    ApplianceStyle? toastStyle,
    ApplianceStyle? linkStyle,
    ApplianceStyle? chipStyle,
    ApplianceStyle? tagStyle,
    ApplianceStyle? displayStyle,
    ApplianceStyle? tooltipStyle,
    ApplianceStyle? popoverStyle,
    ApplianceStyle? tableStyle,
    ApplianceStyle? bannerStyle,
    ApplianceStyle? progressStyle,
    ApplianceStyle? chartStyle,
    ApplianceStyle? avatarStyle,
    ApplianceStyle? calendarStyle,
  }) => ApplianceThemeData(
    colors: colors ?? this.colors,
    textTheme:
        textTheme ??
        (colors == null
            ? this.textTheme
            : this.textTheme._recoloured(this.colors, colors)),
    density: density ?? this.density,
    texture: texture ?? this.texture,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    filledButtonStyle: filledButtonStyle ?? this.filledButtonStyle,
    textButtonStyle: textButtonStyle ?? this.textButtonStyle,
    iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    textFieldStyle: textFieldStyle ?? this.textFieldStyle,
    selectStyle: selectStyle ?? this.selectStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    toggleStyle: toggleStyle ?? this.toggleStyle,
    selectorStyle: selectorStyle ?? this.selectorStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    stepperStyle: stepperStyle ?? this.stepperStyle,
    panelStyle: panelStyle ?? this.panelStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    navigationStyle: navigationStyle ?? this.navigationStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    chipStyle: chipStyle ?? this.chipStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    displayStyle: displayStyle ?? this.displayStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    popoverStyle: popoverStyle ?? this.popoverStyle,
    tableStyle: tableStyle ?? this.tableStyle,
    bannerStyle: bannerStyle ?? this.bannerStyle,
    progressStyle: progressStyle ?? this.progressStyle,
    chartStyle: chartStyle ?? this.chartStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
  );

  List<ApplianceStyle?> get _styles => [
    buttonStyle,
    filledButtonStyle,
    textButtonStyle,
    iconButtonStyle,
    textFieldStyle,
    selectStyle,
    menuStyle,
    toggleStyle,
    selectorStyle,
    sliderStyle,
    stepperStyle,
    panelStyle,
    listTileStyle,
    navigationStyle,
    dialogStyle,
    toastStyle,
    linkStyle,
    chipStyle,
    tagStyle,
    displayStyle,
    tooltipStyle,
    popoverStyle,
    tableStyle,
    bannerStyle,
    progressStyle,
    chartStyle,
    avatarStyle,
    calendarStyle,
  ];

  /// Between [a] and [b] by [t], as `ThemeData.lerp`.
  static ApplianceThemeData lerp(
    ApplianceThemeData a,
    ApplianceThemeData b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final x = a._styles;
    final y = b._styles;
    ApplianceStyle? at(int i) => RawStyle.lerp(x[i], y[i], t);
    return ApplianceThemeData(
      colors: ApplianceColors.lerp(a.colors, b.colors, t),
      textTheme: ApplianceTextTheme.lerp(a.textTheme, b.textTheme, t),
      density: RawDensity.lerp(a.density, b.density, t),
      texture: t < 0.5 ? a.texture : b.texture,
      buttonStyle: at(0),
      filledButtonStyle: at(1),
      textButtonStyle: at(2),
      iconButtonStyle: at(3),
      textFieldStyle: at(4),
      selectStyle: at(5),
      menuStyle: at(6),
      toggleStyle: at(7),
      selectorStyle: at(8),
      sliderStyle: at(9),
      stepperStyle: at(10),
      panelStyle: at(11),
      listTileStyle: at(12),
      navigationStyle: at(13),
      dialogStyle: at(14),
      toastStyle: at(15),
      linkStyle: at(16),
      chipStyle: at(17),
      tagStyle: at(18),
      displayStyle: at(19),
      tooltipStyle: at(20),
      popoverStyle: at(21),
      tableStyle: at(22),
      bannerStyle: at(23),
      progressStyle: at(24),
      chartStyle: at(25),
      avatarStyle: at(26),
      calendarStyle: at(27),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ApplianceThemeData &&
      other.colors == colors &&
      other.textTheme == textTheme &&
      other.density == density &&
      other.texture == texture &&
      listEquals(other._styles, _styles);

  @override
  int get hashCode =>
      Object.hash(colors, textTheme, density, texture, Object.hashAll(_styles));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ApplianceColors>('colors', colors))
      ..add(DiagnosticsProperty<ApplianceTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<RawDensity>('density', density))
      ..add(FlagProperty('texture', value: texture, ifFalse: 'no texture'));
  }
}

/// Appliance for [child]: the one widget an app installs, in its `builder:`
/// (`MaterialApp(builder: (context, child) => ApplianceTheme(data: ..., child: child!))`).
///
/// It sets the words, the glyphs and the text selection in the look's
/// print, declares the look's 4 px grid ([RawSpacingScope]) and its tap
/// floors ([tapTargets]), and lays a Material theme under the look (its
/// density pinned, its ink off, its page change Appliance's) so the
/// Material parts it draws with never show.
///
/// ```dart
/// ApplianceTheme(data: ApplianceThemeData.dark(), child: const LarderHome())
/// ```
class ApplianceTheme extends StatelessWidget {
  /// Appliance in [data] for [child].
  const ApplianceTheme({super.key, required this.data, required this.child});

  /// The theme.
  final ApplianceThemeData data;

  /// What wears it.
  final Widget child;

  /// The tap floors every Appliance control stands at: ui_core's, 40 by 40
  /// for a finger and 24 by 24 for a pointer.
  static const RawTapTargets tapTargets = RawTapTargets.fallback;

  static final ApplianceThemeData _fallback = ApplianceThemeData.light();

  /// The theme above [context], or the look by day when there is none, as
  /// `Theme.of` falls back to its default.
  static ApplianceThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static ApplianceThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedApplianceTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    final bridge = _bridges[data] ??= _materialUnder(data);
    // Over the app's navigator, the routes change pages by this theme:
    // Appliance's, unless the app's own theme chose another.
    final outer = Theme.of(context).pageTransitionsTheme;
    final material =
        outer == const PageTransitionsTheme() ||
            outer == bridge.pageTransitionsTheme
        ? bridge
        : bridge.copyWith(pageTransitionsTheme: outer);
    Widget under = _InheritedApplianceTheme(
      theme: this,
      child: Theme(
        data: material,
        child: RawSpacingScope(
          spacing: RawSpacing.fallback,
          child: RawTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.signal,
              selectionColor: colors.signal.withValues(alpha: 0.3),
              child: IconTheme(
                data: IconThemeData(color: colors.print, size: 20),
                child: DefaultTextStyle(
                  style: data.textTheme.body,
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    // The text field's menu asks for the words of the Material library the
    // look is built on, and on iOS for Cupertino's: an app with none gets
    // English, never a throw; an app that has them keeps its own.
    final missing = Localizations.maybeLocaleOf(context) == null
        ? const <LocalizationsDelegate<Object?>>[]
        : <LocalizationsDelegate<Object?>>[
            if (Localizations.of<MaterialLocalizations>(
                  context,
                  MaterialLocalizations,
                ) ==
                null)
              const _MaterialWords(),
            if (Localizations.of<CupertinoLocalizations>(
                  context,
                  CupertinoLocalizations,
                ) ==
                null)
              const _CupertinoWords(),
          ];
    if (missing.isNotEmpty) {
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: missing,
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    return under;
  }

  static final Expando<ThemeData> _bridges = Expando('ApplianceTheme bridges');

  static ThemeData _materialUnder(ApplianceThemeData data) {
    final colors = data.colors;
    return ThemeData(
      brightness: colors.brightness,
      fontFamily: data.textTheme.body.fontFamily,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: appliancePageTransitions,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      splashColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      scaffoldBackgroundColor: colors.housingBottom,
      canvasColor: colors.face,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.signal,
        brightness: colors.brightness,
        primary: colors.signal,
        onPrimary: colors.onSignal,
        surface: colors.face,
        onSurface: colors.print,
        error: colors.danger,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.signal,
        selectionColor: colors.signal.withValues(alpha: 0.3),
        selectionHandleColor: colors.signal,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ApplianceThemeData>('data', data));
  }
}

class _InheritedApplianceTheme extends InheritedTheme {
  const _InheritedApplianceTheme({required this.theme, required super.child});

  final ApplianceTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ApplianceTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedApplianceTheme old) =>
      theme.data != old.theme.data;
}

/// [ApplianceTheme] that moves to a new [data] as a room's light changes
/// (day to night), on the lamp's spring; at once under Reduce Motion.
///
/// ```dart
/// AnimatedApplianceTheme(data: night ? ApplianceThemeData.dark() : ApplianceThemeData.light(), child: page)
/// ```
class AnimatedApplianceTheme extends StatefulWidget {
  /// Moves to [data] whenever it changes.
  const AnimatedApplianceTheme({
    super.key,
    required this.data,
    required this.child,
  });

  /// The theme to arrive at.
  final ApplianceThemeData data;

  /// What wears it.
  final Widget child;

  @override
  State<AnimatedApplianceTheme> createState() => _AnimatedApplianceThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ApplianceThemeData>('data', data));
  }
}

class _AnimatedApplianceThemeState extends State<AnimatedApplianceTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = 1;
  late ApplianceThemeData _from = widget.data;
  late ApplianceThemeData _to = widget.data;

  @override
  void didUpdateWidget(AnimatedApplianceTheme old) {
    super.didUpdateWidget(old);
    if (widget.data == _to) return;
    _from = ApplianceThemeData.lerp(_from, _to, _t.value);
    _to = widget.data;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _t.value = 1;
      return;
    }
    _t
      ..value = 0
      ..springTo(
        1,
        rawSpring(
          dampingRatio: 1,
          stiffness: ApplianceMotion.lamp.stiffness / 4,
        ),
      );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    builder: (context, child) => ApplianceTheme(
      data: _t.value >= 1 ? _to : ApplianceThemeData.lerp(_from, _to, _t.value),
      child: child!,
    ),
    child: widget.child,
  );
}

/// Reads Appliance's theme from a [BuildContext].
extension ApplianceThemeContext on BuildContext {
  /// [ApplianceTheme.of] this context.
  ApplianceThemeData get applianceTheme => ApplianceTheme.of(this);
}

// The words of the Material and Cupertino libraries Appliance is built on,
// which ApplianceTheme gives its parts when the app gives none: English.
class _MaterialWords extends LocalizationsDelegate<MaterialLocalizations> {
  const _MaterialWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_MaterialWords old) => false;
}

class _CupertinoWords extends LocalizationsDelegate<CupertinoLocalizations> {
  const _CupertinoWords();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(const Locale('en'));

  @override
  bool shouldReload(_CupertinoWords old) => false;
}
