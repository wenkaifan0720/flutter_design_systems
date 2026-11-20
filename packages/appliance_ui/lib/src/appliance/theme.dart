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
typedef ApplianceStyle = DesignStyle;

/// How tight Appliance's controls stand: [DesignDensity.standard] (a 48 px
/// key), [DesignDensity.comfortable] (44) or [DesignDensity.compact] (40).
/// A control's tap target stays at the floor for the input whatever the
/// density. [ApplianceThemeData.density] defaults to
/// [DesignDensity.adaptivePlatformDensity]: compact on a desktop, standard
/// on a phone.
typedef ApplianceDensity = DesignDensity;

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

  /// A key's height at [DesignDensity.standard], before density.
  static const double controlHeight = 48;

  /// How far a pressed key travels into the panel.
  static const double pressTravel = 1.5;

  /// The room a focus ring once kept round a face.
  @Deprecated(
    'Focus lights the part\'s own rim from inside since 0.1.2; nothing is '
    'drawn round it.',
  )
  static const double focusGap = 2;

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

  /// The corner a focus ring once had round a face of corner [radius].
  @Deprecated(
    'Focus lights the part\'s own rim from inside since 0.1.2; nothing is '
    'drawn round it.',
  )
  static double focusRadius(double radius) => radius + 3;
}

/// Appliance's spacing, on a 4 px grid ([DesignSpacingScope] declares it).
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
/// rises and settles. Run them through `DesignMotionPolicy`, which critically
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
    signalInk: Color(0xFFAD3F0B),
    focus: Color(0xFFB8420C),
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
    printMuted: Color(0xFFB6AFA4),
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
    signalInk: Color(0xFFF59A62),
    focus: Color(0xFFF2803F),
    lampOff: Color(0xFF4E4C47),
    danger: Color(0xFFFF8F80),
    onDanger: Color(0xFF2A0A06),
    display: Color(0xFF171614),
    onDisplay: Color(0xFFF1EBE1),
    metalLight: Color(0xFF8D8F92),
    metalDark: Color(0xFF5D5F62),
    scrim: Color(0x99000000),
    ready: Color(0xFF63C77A),
  );

  /// Appliance by [brightness] with the plastic tinted toward [finish] (its
  /// hue and a little of its saturation; the tones stay the look's, so the
  /// print keeps its contrast) and [signal] for the main key, the lamps and
  /// the focus backlight (its ink tones darkened or lightened until they read).
  ///
  /// ```dart
  /// final mint = ApplianceColors.from(brightness: Brightness.light, finish: const Color(0xFFD9EDE4), signal: const Color(0xFF1F8A70));
  /// ```
  factory ApplianceColors.from({
    required Brightness brightness,
    Color? finish,
    Color? signal,
  }) {
    final base = brightness == Brightness.light ? light : dark;
    var colors = base;
    if (finish != null) {
      final tint = HSLColor.fromColor(finish);
      Color tinted(Color c) {
        if (c.a == 0) return c;
        final hsl = HSLColor.fromColor(c);
        return hsl
            .withHue(tint.hue)
            .withSaturation(
              math.min(0.45, hsl.saturation * 0.4 + tint.saturation * 0.35),
            )
            .toColor()
            .withValues(alpha: c.a);
      }

      colors = colors.copyWith(
        housingTop: tinted(base.housingTop),
        housingBottom: tinted(base.housingBottom),
        face: tinted(base.face),
        well: tinted(base.well),
        trough: tinted(base.trough),
        keyTop: tinted(base.keyTop),
        keyBottom: tinted(base.keyBottom),
        keyDownTop: tinted(base.keyDownTop),
        keyDownBottom: tinted(base.keyDownBottom),
        lampOff: tinted(base.lampOff),
      );
    }
    if (signal != null) {
      final hsl = HSLColor.fromColor(signal);
      Color shift(double by) =>
          hsl.withLightness((hsl.lightness + by).clamp(0.0, 1.0)).toColor();
      // The ink tones walk from the signal until they read on a faceplate
      // (4.5:1, for words) and on the housing (3:1, for the bezel).
      Color reading(Color on, double ratio) {
        final step = brightness == Brightness.light ? -0.02 : 0.02;
        var c = signal;
        for (var i = 0; i < 40 && applianceContrast(c, on) < ratio; i++) {
          c = HSLColor.fromColor(c)
              .withLightness(
                (HSLColor.fromColor(c).lightness + step).clamp(0.0, 1.0),
              )
              .toColor();
        }
        return c;
      }

      final onSignal =
          applianceContrast(const Color(0xFF1D1A17), signal) >=
              applianceContrast(const Color(0xFFFFFFFF), signal)
          ? const Color(0xFF1D1A17)
          : const Color(0xFFFFFFFF);
      colors = colors.copyWith(
        signal: signal,
        signalTop: shift(0.08),
        signalBottom: shift(-0.05),
        onSignal: onSignal,
        signalInk: reading(colors.face, 4.5),
        focus: reading(colors.housingBottom, 3),
      );
    }
    return colors;
  }

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

  /// Secondary legends: a row's supporting line, a caption.
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

  /// The signal as words on a faceplate (a link, a price you can act on):
  /// 4.5:1.
  final Color signalInk;

  /// The focus backlight: the signal, deep enough for 3:1 on the housing and
  /// on a key.
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

/// The contrast ratio of [a] on [b], as WCAG measures it (1 to 21).
double applianceContrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

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
  factory ApplianceTextTheme.of(
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
/// [ApplianceThemeData.light] and [ApplianceThemeData.dark] are the look's
/// one preset, warm; [ApplianceThemeData.from] recolours its finish and its
/// signal for a brand.
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
    DesignDensity? density,
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
  }) : textTheme = textTheme ?? ApplianceTextTheme.of(colors),
       density = density ?? DesignDensity.adaptivePlatformDensity;

  /// Warm-white plastic by day.
  factory ApplianceThemeData.light({DesignDensity? density}) =>
      ApplianceThemeData(colors: ApplianceColors.light, density: density);

  /// The same plastic in a dim room.
  factory ApplianceThemeData.dark({DesignDensity? density}) =>
      ApplianceThemeData(colors: ApplianceColors.dark, density: density);

  /// [brightness]'s theme: [ApplianceThemeData.light] or
  /// [ApplianceThemeData.dark].
  factory ApplianceThemeData.of(
    Brightness brightness, {
    DesignDensity? density,
  }) => brightness == Brightness.light
      ? ApplianceThemeData.light(density: density)
      : ApplianceThemeData.dark(density: density);

  /// The look's presets by name: one, `warm` (light and dark).
  static const List<String> presets = ['warm'];

  /// The preset [name] for [brightness]: `warm`, the only one.
  ///
  /// ```dart
  /// ApplianceThemeData.preset('warm', Brightness.dark)
  /// ```
  factory ApplianceThemeData.preset(String name, Brightness brightness) {
    assert(
      presets.contains(name),
      'Appliance has no preset $name; it offers ${presets.join(', ')}.',
    );
    return ApplianceThemeData.of(brightness);
  }

  /// A brand's Appliance: the plastic tinted toward [finish] and the signal
  /// in [signal] ([ApplianceColors.from]), set in [fontFamily] when given.
  /// Corners, light and depth stay the look's.
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
    DesignDensity? density,
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
          : ApplianceTextTheme.of(
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
  final DesignDensity density;

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

  /// A page's first heading, as generated pages name it: the
  /// [ApplianceTextTheme.title] style.
  TextStyle get h1 => textTheme.title;

  /// Running copy, as generated pages name it: the [ApplianceTextTheme.body]
  /// style.
  TextStyle get body => textTheme.body;

  /// A copy with the given settings replaced.
  ApplianceThemeData copyWith({
    ApplianceColors? colors,
    ApplianceTextTheme? textTheme,
    DesignDensity? density,
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
        (colors == null ? this.textTheme : ApplianceTextTheme.of(colors)),
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
    ApplianceStyle? at(int i) => DesignStyle.lerp(x[i], y[i], t);
    return ApplianceThemeData(
      colors: ApplianceColors.lerp(a.colors, b.colors, t),
      textTheme: ApplianceTextTheme.lerp(a.textTheme, b.textTheme, t),
      density: DesignDensity.lerp(a.density, b.density, t),
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
      ..add(DiagnosticsProperty<DesignDensity>('density', density))
      ..add(FlagProperty('texture', value: texture, ifFalse: 'no texture'));
  }
}

/// Appliance for [child]: the one widget an app installs, in its `builder:`
/// (`MaterialApp(builder: (context, child) => ApplianceTheme(data: ..., child: child!))`).
///
/// It sets the words, the glyphs and the text selection in the look's
/// print, declares the look's 4 px grid ([DesignSpacingScope]) and its tap
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

  /// The tap floors every Appliance control stands at: 48 by 48 for a
  /// finger, 24 by 24 for a pointer.
  static const DesignTapTargets tapTargets = DesignTapTargets(
    touch: Size(48, 48),
    pointer: Size(24, 24),
  );

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
        child: DesignSpacingScope(
          spacing: DesignSpacing.fallback,
          child: DesignTapTargetScope(
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
        designSpring(
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
