/// Studio's theme: its colours by day and by night, its type, its measures,
/// its motion, its density, and the [StudioTheme] every app installs once in
/// its `builder:`.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'transitions.dart' show studioPageTransitions;

// Below this chroma an indicator is a white or a grey: a light with no hue of
// its own, which keeps the set it lights hue-free.
const double _hueFreeChroma = 10;

// The tone a hue-free light shows at by day: a graphite ink.
const double _hueFreeInkTone = 22;

// The tone of that light itself, where it shows through the dark by day.
const double _hueFreeLightTone = 90;

/// How one part of Studio looks, as Material's `ButtonStyle` is: every slot a
/// `WidgetStateProperty`, read from a part's `style:` first, then from its
/// component theme on [StudioThemeData], then from the look's own default.
///
/// ```dart
/// const wide = StudioStyle(padding: WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)));
/// ```
typedef StudioStyle = RawStyle;

/// How tight Studio's controls stand: [RawDensity.standard] (a 44 px
/// key), [RawDensity.comfortable] (40) or [RawDensity.compact] (36). A
/// control's tap target stays at the floor for the input whatever the
/// density.
typedef StudioDensity = RawDensity;

/// Studio's measures. The corners, the light (always from the top) and the
/// three depths are the look's and are not settings: a key, a pane and a
/// panel are cut the same way on every app.
abstract final class StudioMetrics {
  /// A key's height at [RawDensity.standard], before density: every
  /// control that shares a row takes it.
  static const double controlHeight = 44;

  /// A list row's height on a display or a panel, before density.
  static const double rowHeight = 52;

  /// The width of a focused face's lit edge, hugging its outline.
  static const double focusWidth = 1.5;

  /// How far a pressed key sinks.
  static const double pressTravel = 1.5;

  /// The widest a form, a dialog or a reading column stands.
  static const double readingWidth = 600;

  /// An indicator lamp's diameter.
  static const double lampSize = 8;

  /// The lip of a recess round the keys it holds (a bank, a slot): the inset
  /// that makes their corners concentric with its own.
  static const double recessInset = 4;

  /// The lip a fitted part leaves round what rides in it, thinner than a
  /// recess (a lamp in its bezel, a photograph in its key's rim, a trace in
  /// its readout window): fitted, not set in.
  static const double lip = 3;

  /// How far a timeline's lamp drops from its row's top, to stand on the
  /// line of its title's capitals.
  static const double lampDrop = 5;

  /// Below this an avatar's rim narrows from [lip] to a hair.
  static const double smallAvatar = 32;

  /// The height from which a sunk face is a pane a page reads on (a
  /// display, a list's glass), not a slot: its lip casts a deeper shadow.
  static const double paneDepthFrom = 48;

  /// From this window width a tablet's: the places are a rail, a sheet
  /// stands 560 wide, a segmented bank stops spanning the width.
  static const double tablet = 600;

  /// From this window width a desk's: the places are a side panel, and a
  /// page lays its groups side by side.
  static const double desk = 1024;
}

/// Glyph sizes, from a field's small affordance to a dish's glyph.
abstract final class StudioIconSizes {
  /// A small affordance inside a field or a row (a chevron, a clear key).
  static const double small = 14;

  /// A glyph beside words in a control.
  static const double medium = 18;

  /// A key's or a bar's glyph.
  static const double regular = 20;

  /// A large key's glyph.
  static const double large = 24;

  /// A glyph standing for a whole pane (an empty state's dish, a picture's place).
  static const double huge = 28;
}

/// Studio's spacing, on a 4 px grid ([RawSpacingScope] declares it).
abstract final class StudioSpacing {
  /// The grid every gap, inset and offset stands on.
  static const double grid = 4;

  /// Half the grid, only inside one small part: a meter's segments from
  /// their window, a bank key's glyph from its legend, a subtitle from its
  /// title, the rows of the side panel, half the gap between a bank's keys.
  static const double hair = grid / 2;

  /// Inside a control: a lamp and its words, an icon and its words.
  static const double tight = 4;

  /// Between a label and its field, between the lines of one item.
  static const double small = 8;

  /// Between keys in a row; the page margin on a phone.
  static const double medium = 12;

  /// A panel's and a row's inset.
  static const double regular = 16;

  /// Between groups; the page margin on a tablet.
  static const double large = 24;

  /// Between sections; the page margin on a desktop.
  static const double extraLarge = 32;

  /// Above a page's first heading on a wide screen.
  static const double huge = 48;

  /// The page margin for a window [width] wide: 12 on a phone (panels sit in
  /// the chassis as modules in a rack), 24 on a tablet, 32 on a desktop.
  static double pageMargin(double width) => width >= StudioMetrics.desk
      ? extraLarge
      : width >= StudioMetrics.tablet
      ? large
      : medium;
}

/// Studio's motion, from the objects: springs only, critically damped unless
/// the object has a click in it. Run them through `RawMotionPolicy`, which
/// honours Reduce Motion.
abstract final class StudioMotion {
  /// The damping ratio of every spring that should stop dead.
  static const double dampingRatio = 1;

  /// A key sinking under a press and coming back.
  static const double pressStiffness = 2200;

  /// A toggle's cap snapping through its throw.
  static const double throwStiffness = 1500;

  /// A knob settling into its detent: a little under critical, the click.
  static const double detentDampingRatio = 0.72;

  /// A knob settling into its detent.
  static const double detentStiffness = 1800;

  /// A fader's cap or a lit bar moving to a new place by itself (a key, a
  /// tab).
  static const double moveStiffness = 900;

  /// A lamp warming up or going dark.
  static const double lampStiffness = 1100;

  /// A dialog, a drawer, a menu or a message arriving or leaving.
  static const double overlayStiffness = 650;
}

/// Studio's colours by role.
///
/// The metal is chrome: [chassis], [panel] and [bar] (each with its lower
/// tone), printed with [legend] and [legendMuted], cut with [groove]. The
/// glass is content: [display] with [onDisplay], and the [readout] windows:
/// by night dark glass whose figures glow in [indicator], by day pale glass
/// lit from behind in [indicator]'s hue, its figures [readoutLit]. [indicator]
/// is the one accent (amber in the anodised preset),
/// the light of a lamp, a backlit key or a lit legend ([litLegend] where a lit
/// word must still read on the metal by day). [danger] is the meaning of a
/// live recording or a failure, nothing else.
@immutable
class StudioColors with Diagnosticable {
  /// Colours given one by one; [StudioColors.light] and [StudioColors.dark]
  /// are the look's own.
  const StudioColors({
    required this.brightness,
    required this.chassis,
    required this.chassisLow,
    required this.panel,
    required this.panelLow,
    required this.bar,
    required this.barLow,
    required this.legend,
    required this.legendMuted,
    required this.groove,
    required this.edgeLight,
    required this.display,
    required this.displayLow,
    required this.onDisplay,
    required this.onDisplayMuted,
    required this.displayLine,
    required this.readout,
    required this.readoutLow,
    required this.key,
    required this.keyLow,
    required this.onKey,
    required this.disabled,
    required this.slot,
    required this.cap,
    required this.capLow,
    required this.indicator,
    required this.onIndicator,
    required this.litLegend,
    required this.lampOff,
    required this.danger,
    required this.onDanger,
    required this.dangerLegend,
    required this.focusRing,
    required this.shadow,
  });

  /// The gear in a bright room: light silver anodised panels, pale warm
  /// glass displays with graphite words, readout windows of pale glass lit
  /// amber from behind (as a backlit LCD is by day).
  const StudioColors.light()
    : brightness = Brightness.light,
      chassis = const Color(0xFFBEC2C7),
      chassisLow = const Color(0xFFB2B6BC),
      panel = const Color(0xFFE3E5E8),
      panelLow = const Color(0xFFD2D5D9),
      bar = const Color(0xFFE9EBED),
      barLow = const Color(0xFFD5D8DC),
      legend = const Color(0xFF202328),
      legendMuted = const Color(0xFF4B5058),
      groove = const Color(0x2E000000),
      edgeLight = const Color(0xCCFFFFFF),
      // Pale glass with a faint green-grey tint, a shade under the metal
      // round it: its own material, set in rather than laid on (cream read
      // as card stock, untinted grey as the metal itself).
      display = const Color(0xFFDFE4E2),
      displayLow = const Color(0xFFD3D9D7),
      onDisplay = const Color(0xFF1A1C1F),
      onDisplayMuted = const Color(0xFF4D5056),
      displayLine = const Color(0x17000000),
      readout = const Color(0xFFF7E0BC),
      readoutLow = const Color(0xFFF0D2A2),
      key = const Color(0xFFF6F7F8),
      keyLow = const Color(0xFFD9DCE0),
      onKey = const Color(0xFF202328),
      disabled = const Color(0xFF8E939A),
      slot = const Color(0xFF2B2E33),
      cap = const Color(0xFFF2F3F5),
      capLow = const Color(0xFFB4B9BF),
      indicator = const Color(0xFFFFAE3A),
      onIndicator = const Color(0xFF2A1700),
      litLegend = const Color(0xFF7D4000),
      lampOff = const Color(0xFF6E6A62),
      danger = const Color(0xFFC4281C),
      onDanger = const Color(0xFFFFFFFF),
      dangerLegend = const Color(0xFFA0140E),
      focusRing = const Color(0xFF9A5200),
      shadow = const Color(0xFF000000);

  /// The same gear in low light: graphite panels, dark glass displays with
  /// warm-white words, legends faintly backlit.
  const StudioColors.dark()
    : brightness = Brightness.dark,
      chassis = const Color(0xFF0E0F11),
      chassisLow = const Color(0xFF0A0A0C),
      panel = const Color(0xFF292B2F),
      panelLow = const Color(0xFF1F2124),
      bar = const Color(0xFF2C2E32),
      barLow = const Color(0xFF212326),
      legend = const Color(0xFFE8E2D6),
      legendMuted = const Color(0xFFA8A296),
      groove = const Color(0x8C000000),
      edgeLight = const Color(0x1FFFFFFF),
      display = const Color(0xFF131518),
      displayLow = const Color(0xFF0B0C0E),
      onDisplay = const Color(0xFFF1EBDF),
      onDisplayMuted = const Color(0xFFABA599),
      displayLine = const Color(0x14FFFFFF),
      readout = const Color(0xFF0E0F11),
      readoutLow = const Color(0xFF060607),
      key = const Color(0xFF3A3D42),
      keyLow = const Color(0xFF282A2E),
      onKey = const Color(0xFFE8E2D6),
      disabled = const Color(0xFF6C6A66),
      slot = const Color(0xFF08090A),
      cap = const Color(0xFF8A8E95),
      capLow = const Color(0xFF4A4E54),
      indicator = const Color(0xFFFFAE3A),
      onIndicator = const Color(0xFF2A1700),
      litLegend = const Color(0xFFFFB547),
      lampOff = const Color(0xFF5A4E3C),
      danger = const Color(0xFFFF5446),
      onDanger = const Color(0xFF1F0402),
      dangerLegend = const Color(0xFFFF7468),
      focusRing = const Color(0xFFFFAE3A),
      shadow = const Color(0xFF000000);

  /// Bright room or low light.
  final Brightness brightness;

  /// The frame round the panels: the page behind everything.
  final Color chassis;

  /// The chassis's lower tone (its gradient falls to it).
  final Color chassisLow;

  /// A panel module's metal, lit from the top.
  final Color panel;

  /// The panel's lower tone.
  final Color panelLow;

  /// The faceplate of the top bar and the bottom bar.
  final Color bar;

  /// The bar's lower tone.
  final Color barLow;

  /// Words printed on the metal.
  final Color legend;

  /// Secondary print on the metal, at 4.5:1 on every metal it is printed on:
  /// the chassis, a panel and a bar, at their tops and their lower tones.
  final Color legendMuted;

  /// A machined groove's dark line.
  final Color groove;

  /// The light catching a top edge (and a groove's lower lip).
  final Color edgeLight;

  /// A glass display's face at its top.
  final Color display;

  /// The display's lower tone.
  final Color displayLow;

  /// Words on a display.
  final Color onDisplay;

  /// Supporting words on a display, at 4.5:1 on its glass and on the metal
  /// round it (a row laid on a panel or on the chassis).
  final Color onDisplayMuted;

  /// A rule between rows on a display.
  final Color displayLine;

  /// A readout window's glass: by night dark, by day pale and lit from
  /// behind by the indicator.
  final Color readout;

  /// The readout's lower tone.
  final Color readoutLow;

  /// A key's cap at its top.
  final Color key;

  /// The key's lower tone.
  final Color keyLow;

  /// A key's legend.
  final Color onKey;

  /// A legend that cannot be pressed.
  final Color disabled;

  /// The dark slot a toggle's or a fader's cap rides in.
  final Color slot;

  /// A toggle's or a fader's metal cap at its top.
  final Color cap;

  /// The cap's lower tone.
  final Color capLow;

  /// The indicator light: a lit lamp, a backlit key, a glowing readout. The
  /// one accent.
  final Color indicator;

  /// Words on a lit key's cap.
  final Color onIndicator;

  /// A lit legend on the metal, a display or a key: [indicator] by night, a
  /// deeper amber by day, reading at 4.5:1 on each.
  final Color litLegend;

  /// A lamp that is off: a dark dimple.
  final Color lampOff;

  /// A live recording, a failure, a destructive key's light.
  final Color danger;

  /// Words on [danger].
  final Color onDanger;

  /// A destructive legend on the metal or a display, at 4.5:1 on each.
  final Color dangerLegend;

  /// The keyboard focus ring, at 3:1 on the metal and the keys.
  final Color focusRing;

  /// Every cast and inner shadow.
  final Color shadow;

  /// The glow round a lit lamp or a backlit legend.
  Color get glow => indicator.withValues(alpha: 0.55);

  /// An unlit lamp's edge by night: the bezel round its dark glass, an
  /// unlit star's outline. [lampOff] lifted toward [legend] until it stands
  /// a little over 3:1 on [key], the lightest metal a lamp is set in (more
  /// on a panel, the bar or a display), so an unlit lamp still reads as a
  /// lamp: the 3:1 WCAG asks of a part's outline, with room for the light
  /// across the metal. A lit lamp covers it. Its hue is the lamp's own.
  Color get lampEdge => RawPalette.readableTone(lampOff, on: [key], ratio: 3.3);

  /// The light where it shows through the dark: in a switch's or a fader's
  /// slot, in the graphite main key's lamp and legend. [indicator], save by
  /// day in a set under a white light: the silver is too bright for a white
  /// light to read on, so there [indicator] is ink, and this is the white.
  Color get lightInDark {
    final light = RawHct.fromColor(indicator);
    return brightness == Brightness.light &&
            light.chroma < _hueFreeChroma &&
            light.tone < 50
        ? light.withTone(_hueFreeLightTone).toColor()
        : indicator;
  }

  /// The main key's cap: graphite in both rooms, so its legend can be lit.
  /// (Amber means on: the main key is not filled with it; its legend and
  /// its lamp are lit.)
  Color get litKey => brightness == Brightness.dark
      // By night a pale graphite cap, the brightest key on the bar, so the
      // main key leads (a black cap sank into the dark bar).
      ? const Color(0xFF4A4D53)
      : const Color(0xFF3A3D42);

  /// The main key's lower tone.
  Color get litKeyLow => brightness == Brightness.dark
      ? const Color(0xFF34373C)
      : const Color(0xFF26282C);

  /// The main key's lit legend: the indicator, a little whiter, and
  /// lightened further until it reads on [litKey] at 4.5:1 (an app's own
  /// indicator included).
  Color get onLitKey => RawPalette.readableTone(
    Color.lerp(lightInDark, const Color(0xFFFFFFFF), 0.12)!,
    on: [litKey],
  );

  /// A destructive main key's lit legend: red light, at 4.5:1 on [litKey].
  Color get onLitKeyDanger => const Color(0xFFFF8A7E);

  /// The main key's legend with no power: unlit, still read at 4.5:1.
  Color get onLitKeyOff => const Color(0xFFA19C92);

  /// Whether the readout windows are pale glass lit from behind (by day)
  /// rather than dark glass (by night), read off [readout] itself.
  bool get litReadout => readout.computeLuminance() > 0.4;

  /// Words on a readout window's glass: warm white on the dark glass; on the
  /// lit glass a near-black in the glass's own hue (warm on the look's amber
  /// pane).
  Color get onReadout => litReadout
      ? _paneInk(const Color(0xFF2A2116))
      : _nightInk(const Color(0xFFF1EBDF));

  /// Supporting words on a readout window's glass (a drum's figures round
  /// the chosen one), at 4.5:1 on both its tones.
  Color get onReadoutMuted => RawPalette.readableTone(
    litReadout
        ? _paneInk(const Color(0xFF5E4C33))
        : _nightInk(const Color(0xFFBDB6A8)),
    on: [readout, readoutLow],
  );

  // [ink] as the look prints it on its own lit pane; on a pane lit in
  // another hue, the same depth in that pane's hue, at no more chroma than
  // the pane's own, so a blue pane's words are a blue-black, not the amber
  // pane's brown, and an ice pane's a plain black.
  Color _paneInk(Color ink) {
    if (readout == const StudioColors.light().readout) return ink;
    final own = RawHct.fromColor(ink);
    final pane = RawHct.fromColor(readout);
    return pane
        .withChroma(math.min(own.chroma, pane.chroma))
        .withTone(own.tone)
        .toColor();
  }

  // [ink] on the dark glass: the look's warm white, or under a light with
  // no hue of its own, that light's white.
  Color _nightInk(Color ink) {
    final light = RawHct.fromColor(indicator);
    if (light.chroma >= _hueFreeChroma) return ink;
    final own = RawHct.fromColor(ink);
    return light
        .withChroma(math.min(own.chroma, light.chroma))
        .withTone(own.tone)
        .toColor();
  }

  // Whether [indicator] is a white or a grey: a light with no hue of its
  // own.
  bool get _hueFreeLight => RawHct.fromColor(indicator).chroma < _hueFreeChroma;

  /// A readout's lit figures and segments: [indicator], glowing, on the dark
  /// glass (lifted until it reads there at 4.5:1, for a brand too dim); on
  /// the lit glass the indicator deepened until it reads there at 4.5:1, as
  /// a backlit LCD's figures do; under a white light, the pane's own
  /// near-black ([onReadout]).
  Color get readoutLit =>
      litReadout && _hueFreeLight ? onReadout : _onGlass(indicator, 4.5);

  // [light] deepened by day, or lifted by night, until it reads at [ratio]
  // on both ends of the glass.
  Color _onGlass(Color light, double ratio) =>
      RawPalette.readableTone(light, on: [readout, readoutLow], ratio: ratio);

  /// A dimmer light on a readout (a third trace): the indicator half-way to
  /// the glass, kept at 3:1 on it.
  Color get readoutDim {
    return _onGlass(Color.lerp(readoutLit, readout, 0.45)!, 3);
  }

  /// The glow round a readout's lit figures: on the dark glass only; the lit
  /// glass is lit from behind, and its figures stay sharp.
  List<Shadow> readoutGlow(
    Color light, {
    double alpha = 0.55,
    double blur = 6,
  }) => litReadout
      ? const []
      : [
          Shadow(
            color: light.withValues(alpha: alpha),
            blurRadius: blur,
          ),
        ];

  /// The dimming over a page under a dialog or a sheet: the room's lights
  /// lowered.
  Color get scrim =>
      shadow.withValues(alpha: brightness == Brightness.dark ? 0.62 : 0.38);

  /// Black or white words, whichever reads better on [fill].
  static Color wordsOn(Color fill) =>
      RawPalette.contrastRatio(const Color(0xFF000000), fill) >=
          RawPalette.contrastRatio(const Color(0xFFFFFFFF), fill)
      ? const Color(0xFF1A1206)
      : const Color(0xFFFFFFFF);

  /// A copy with the given colours replaced.
  StudioColors copyWith({
    Color? chassis,
    Color? chassisLow,
    Color? panel,
    Color? panelLow,
    Color? bar,
    Color? barLow,
    Color? legend,
    Color? legendMuted,
    Color? groove,
    Color? edgeLight,
    Color? display,
    Color? displayLow,
    Color? onDisplay,
    Color? onDisplayMuted,
    Color? displayLine,
    Color? readout,
    Color? readoutLow,
    Color? key,
    Color? keyLow,
    Color? onKey,
    Color? disabled,
    Color? slot,
    Color? cap,
    Color? capLow,
    Color? indicator,
    Color? onIndicator,
    Color? litLegend,
    Color? lampOff,
    Color? focusRing,
    Color? danger,
    Color? onDanger,
    Color? dangerLegend,
    Color? shadow,
  }) => StudioColors(
    brightness: brightness,
    chassis: chassis ?? this.chassis,
    chassisLow: chassisLow ?? this.chassisLow,
    panel: panel ?? this.panel,
    panelLow: panelLow ?? this.panelLow,
    bar: bar ?? this.bar,
    barLow: barLow ?? this.barLow,
    legend: legend ?? this.legend,
    legendMuted: legendMuted ?? this.legendMuted,
    groove: groove ?? this.groove,
    edgeLight: edgeLight ?? this.edgeLight,
    display: display ?? this.display,
    displayLow: displayLow ?? this.displayLow,
    onDisplay: onDisplay ?? this.onDisplay,
    onDisplayMuted: onDisplayMuted ?? this.onDisplayMuted,
    displayLine: displayLine ?? this.displayLine,
    readout: readout ?? this.readout,
    readoutLow: readoutLow ?? this.readoutLow,
    key: key ?? this.key,
    keyLow: keyLow ?? this.keyLow,
    onKey: onKey ?? this.onKey,
    disabled: disabled ?? this.disabled,
    slot: slot ?? this.slot,
    cap: cap ?? this.cap,
    capLow: capLow ?? this.capLow,
    indicator: indicator ?? this.indicator,
    onIndicator: onIndicator ?? this.onIndicator,
    litLegend: litLegend ?? this.litLegend,
    lampOff: lampOff ?? this.lampOff,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerLegend: dangerLegend ?? this.dangerLegend,
    focusRing: focusRing ?? this.focusRing,
    shadow: shadow ?? this.shadow,
  );

  /// Between [a] and [b] at [t].
  static StudioColors lerp(StudioColors a, StudioColors b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return StudioColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      chassis: c(a.chassis, b.chassis),
      chassisLow: c(a.chassisLow, b.chassisLow),
      panel: c(a.panel, b.panel),
      panelLow: c(a.panelLow, b.panelLow),
      bar: c(a.bar, b.bar),
      barLow: c(a.barLow, b.barLow),
      legend: c(a.legend, b.legend),
      legendMuted: c(a.legendMuted, b.legendMuted),
      groove: c(a.groove, b.groove),
      edgeLight: c(a.edgeLight, b.edgeLight),
      display: c(a.display, b.display),
      displayLow: c(a.displayLow, b.displayLow),
      onDisplay: c(a.onDisplay, b.onDisplay),
      onDisplayMuted: c(a.onDisplayMuted, b.onDisplayMuted),
      displayLine: c(a.displayLine, b.displayLine),
      readout: c(a.readout, b.readout),
      readoutLow: c(a.readoutLow, b.readoutLow),
      key: c(a.key, b.key),
      keyLow: c(a.keyLow, b.keyLow),
      onKey: c(a.onKey, b.onKey),
      disabled: c(a.disabled, b.disabled),
      slot: c(a.slot, b.slot),
      cap: c(a.cap, b.cap),
      capLow: c(a.capLow, b.capLow),
      indicator: c(a.indicator, b.indicator),
      onIndicator: c(a.onIndicator, b.onIndicator),
      litLegend: c(a.litLegend, b.litLegend),
      lampOff: c(a.lampOff, b.lampOff),
      danger: c(a.danger, b.danger),
      onDanger: c(a.onDanger, b.onDanger),
      dangerLegend: c(a.dangerLegend, b.dangerLegend),
      focusRing: c(a.focusRing, b.focusRing),
      shadow: c(a.shadow, b.shadow),
    );
  }

  List<Object> get _all => [
    brightness,
    chassis,
    chassisLow,
    panel,
    panelLow,
    bar,
    barLow,
    legend,
    legendMuted,
    groove,
    edgeLight,
    display,
    displayLow,
    onDisplay,
    onDisplayMuted,
    displayLine,
    readout,
    readoutLow,
    key,
    keyLow,
    onKey,
    disabled,
    slot,
    cap,
    capLow,
    indicator,
    onIndicator,
    litLegend,
    lampOff,
    danger,
    onDanger,
    dangerLegend,
    focusRing,
    shadow,
  ];

  @override
  bool operator ==(Object other) =>
      other is StudioColors && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(ColorProperty('panel', panel))
      ..add(ColorProperty('display', display))
      ..add(ColorProperty('indicator', indicator))
      ..add(ColorProperty('danger', danger));
  }
}

/// The face Studio sets its words in: Barlow unless an app gives its own.
@immutable
class StudioTypeface with Diagnosticable {
  /// A face of [family], bundled by [package] (null when the app bundles it),
  /// whose capitals stand [capHeightFactor] of its size.
  const StudioTypeface({
    required this.family,
    this.package,
    this.capHeightFactor = 0.7,
    this.fallback = const [],
  });

  /// Barlow, the look's own.
  static const StudioTypeface barlow = StudioTypeface(
    family: studioFontFamily,
    package: studioFontPackage,
    capHeightFactor: studioCapHeightFactor,
  );

  /// The family.
  final String family;

  /// The package that bundles it, or null.
  final String? package;

  /// The capitals' height as a fraction of the size.
  final double capHeightFactor;

  /// Families to fall back to for scripts the face lacks.
  final List<String> fallback;

  @override
  bool operator ==(Object other) =>
      other is StudioTypeface &&
      other.family == family &&
      other.package == package &&
      other.capHeightFactor == capHeightFactor &&
      listEquals(other.fallback, fallback);

  @override
  int get hashCode =>
      Object.hash(family, package, capHeightFactor, Object.hashAll(fallback));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('family', family))
      ..add(StringProperty('package', package, defaultValue: null))
      ..add(DoubleProperty('capHeightFactor', capHeightFactor));
  }
}

/// Studio's type, in its colours. At most four on a screen: a title, body,
/// secondary and one label.
@immutable
class StudioTextTheme with Diagnosticable {
  /// Styles given one by one; [StudioTextTheme.of] derives them.
  const StudioTextTheme({
    required this.display,
    required this.headline,
    required this.title,
    required this.body,
    required this.label,
    required this.secondary,
    required this.legend,
    required this.readout,
    required this.caption,
  });

  /// The scale in [colors], set in [typeface].
  factory StudioTextTheme.of(
    StudioColors colors, {
    StudioTypeface typeface = StudioTypeface.barlow,
  }) {
    TextStyle s(double size, double height, FontWeight weight, Color color) =>
        TextStyle(
          inherit: false,
          fontFamily: typeface.family,
          package: typeface.package,
          fontFamilyFallback: typeface.fallback.isEmpty
              ? null
              : typeface.fallback,
          fontSize: size,
          height: height / size,
          fontWeight: weight,
          color: color,
          leadingDistribution: TextLeadingDistribution.even,
          textBaseline: TextBaseline.alphabetic,
          decoration: TextDecoration.none,
        );
    return StudioTextTheme(
      display: s(34, 40, FontWeight.w600, colors.onDisplay),
      headline: s(24, 30, FontWeight.w600, colors.onDisplay),
      title: s(17, 22, FontWeight.w600, colors.legend),
      body: s(16, 24, FontWeight.w400, colors.onDisplay),
      label: s(15, 20, FontWeight.w500, colors.legend),
      secondary: s(14, 20, FontWeight.w400, colors.onDisplayMuted),
      legend: s(
        12,
        16,
        FontWeight.w600,
        colors.legendMuted,
      ).copyWith(letterSpacing: 1.6),
      readout: s(20, 24, FontWeight.w600, colors.readoutLit).copyWith(
        fontFeatures: const [FontFeature.tabularFigures()],
        letterSpacing: 0.4,
      ),
      caption: s(13, 18, FontWeight.w400, colors.onDisplayMuted),
    );
  }

  /// The one big thing on a screen: a large figure, an Overview's line.
  final TextStyle display;

  /// A page's object: an episode's title.
  final TextStyle headline;

  /// A bar's or a dialog's title, a row's title.
  final TextStyle title;

  /// What people read.
  final TextStyle body;

  /// A control's words, sentence case.
  final TextStyle label;

  /// Supporting lines.
  final TextStyle secondary;

  /// An engraved panel legend: small capitals with tracking in scripts that
  /// have capitals ([StudioLegend] sets it).
  final TextStyle legend;

  /// Figures in a readout window: tabular, glowing.
  final TextStyle readout;

  /// A short note under a field, a timestamp.
  final TextStyle caption;

  /// Between [a] and [b] at [t].
  static StudioTextTheme lerp(StudioTextTheme a, StudioTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle l(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return StudioTextTheme(
      display: l(a.display, b.display),
      headline: l(a.headline, b.headline),
      title: l(a.title, b.title),
      body: l(a.body, b.body),
      label: l(a.label, b.label),
      secondary: l(a.secondary, b.secondary),
      legend: l(a.legend, b.legend),
      readout: l(a.readout, b.readout),
      caption: l(a.caption, b.caption),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is StudioTextTheme &&
      other.display == display &&
      other.headline == headline &&
      other.title == title &&
      other.body == body &&
      other.label == label &&
      other.secondary == secondary &&
      other.legend == legend &&
      other.readout == readout &&
      other.caption == caption;

  @override
  int get hashCode => Object.hash(
    display,
    headline,
    title,
    body,
    label,
    secondary,
    legend,
    readout,
    caption,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle>('body', body))
      ..add(DiagnosticsProperty<TextStyle>('label', label));
  }
}

/// Studio's theme: its colours, its type, its density, how strongly its metal
/// shows its brush, and each part's style.
@immutable
class StudioThemeData with Diagnosticable {
  /// A theme from its parts; [StudioThemeData.light] and
  /// [StudioThemeData.dark] are the look's own.
  ///
  /// [textureStrength] stands from 0 (smooth anodised metal) to 1 (the
  /// look's brush); the brush always goes in high contrast.
  StudioThemeData({
    required this.colors,
    StudioTextTheme? textTheme,
    this.typeface = StudioTypeface.barlow,
    StudioDensity? density,
    double textureStrength = 1,
    this.buttonStyle,
    this.litButtonStyle,
    this.textButtonStyle,
    this.destructiveButtonStyle,
    this.iconButtonStyle,
    this.textFieldStyle,
    this.selectStyle,
    this.checkboxStyle,
    this.radioStyle,
    this.switchStyle,
    this.segmentedButtonStyle,
    this.faderStyle,
    this.knobStyle,
    this.meterStyle,
    this.listTileStyle,
    this.sectionHeaderStyle,
    this.panelStyle,
    this.displayStyle,
    this.appBarStyle,
    this.tabBarStyle,
    this.popoverStyle,
    this.tooltipStyle,
    this.sideSheetStyle,
    this.tagStyle,
    this.dataTableStyle,
    this.breadcrumbStyle,
    this.menuBarStyle,
    this.commandPaletteStyle,
    this.calendarStyle,
    this.chipStyle,
    this.ratingStyle,
    this.fileDropStyle,
    this.floatingKeyStyle,
    this.keyRowStyle,
    this.toggleBankStyle,
    this.linkStyle,
    this.kbdStyle,
    this.navigationBarStyle,
    this.navigationRailStyle,
    this.sideNavigationStyle,
    this.dialogStyle,
    this.bottomSheetStyle,
    this.toastStyle,
    RawShapeScheme? shapeScheme,
  }) : assert(
         textureStrength >= 0 && textureStrength <= 1,
         'Studio brushes its metal from 0 (smooth) to 1: textureStrength '
         'stands in that range, not $textureStrength.',
       ),
       textureStrength = textureStrength.clamp(0.0, 1.0),
       shapeScheme = shapeLimits.clamp(
         shapeScheme ?? defaultShapeScheme,
         look: 'Studio',
       ),
       textTheme = textTheme ?? StudioTextTheme.of(colors, typeface: typeface),
       density = density ?? StudioDensity.adaptivePlatformDensity;

  /// The gear in a bright room.
  factory StudioThemeData.light({
    StudioDensity? density,
    StudioTypeface typeface = StudioTypeface.barlow,
  }) => StudioThemeData(
    colors: const StudioColors.light(),
    density: density,
    typeface: typeface,
  );

  /// The gear in low light.
  factory StudioThemeData.dark({
    StudioDensity? density,
    StudioTypeface typeface = StudioTypeface.barlow,
  }) => StudioThemeData(
    colors: const StudioColors.dark(),
    density: density,
    typeface: typeface,
  );

  /// The look in [brightness]: [StudioThemeData.light] or
  /// [StudioThemeData.dark].
  factory StudioThemeData.anodised(
    Brightness brightness, {
    StudioDensity? density,
    StudioTypeface typeface = StudioTypeface.barlow,
  }) => brightness == Brightness.dark
      ? StudioThemeData.dark(density: density, typeface: typeface)
      : StudioThemeData.light(density: density, typeface: typeface);

  /// Studio in an app's own light: its [indicator] (the lamps, the backlit
  /// key, the readouts) and, if it names one, the [finish] its panels are
  /// anodised in. The corners, the light from the top and the three depths
  /// stay the look's.
  ///
  /// The indicator stays the lamps' colour; a lit key's words over it are
  /// dark or light, whichever reads there at 4.5:1 (the indicator moves, as
  /// little as it must, only for a colour neither reads on); an unlit lamp is
  /// the same lamp, dark. Every word and
  /// lit legend is then walked in its own hue until it reads at 4.5:1 on
  /// each metal, glass and key it is painted on, the focus ring at 3:1. By
  /// day the readout windows' pale glass is lit from behind by the
  /// indicator's hue and keeps the look's brightness, a dark indicator
  /// included. The finish tints the metal at the metal's own tones, so by
  /// night a cream or a sand gives a warm charcoal, never brown.
  ///
  /// ```dart
  /// final theme = StudioThemeData.from(indicator: const Color(0xFF4FD1C5));
  /// ```
  factory StudioThemeData.from({
    required Color indicator,
    Color? finish,
    Brightness brightness = Brightness.light,
    StudioDensity? density,
    StudioTypeface typeface = StudioTypeface.barlow,
  }) => StudioThemeData._lit(
    indicator: indicator,
    finish: finish,
    brightness: brightness,
    density: density,
    typeface: typeface,
  );

  // [StudioThemeData.from], the finish's metal [lift] tones over the look's
  // own; the words are then walked on the lifted metal.
  factory StudioThemeData._lit({
    required Color indicator,
    Color? finish,
    required Brightness brightness,
    StudioDensity? density,
    StudioTypeface typeface = StudioTypeface.barlow,
    double lift = 0,
  }) {
    final base = brightness == Brightness.dark
        ? const StudioColors.dark()
        : const StudioColors.light();
    final metal = finish == null ? base : _anodise(base, finish, lift);
    // A light with no hue of its own (a white, a grey) keeps the set
    // hue-free: a neutral black for the words on it, and the glass lit as
    // the light is, not in the look's cream.
    final hueFree = RawHct.fromColor(indicator).chroma < _hueFreeChroma;
    // By day a white light can't be seen on the silver, so a hue-free set
    // shows it as ink: a graphite lamp, bar and latched key, as a
    // monochrome display shows what is on in black.
    final shown = hueFree && brightness == Brightness.light
        ? RawHct.fromColor(indicator).withTone(_hueFreeInkTone).toColor()
        : indicator;
    final lit = RawPalette.accentFill(
      shown,
      brightness: brightness,
      rule: RawAccentRule.named,
      darkInk: hueFree ? const Color(0xFF141414) : const Color(0xFF1A1206),
    );
    // An unlit lamp is the indicator's lamp, dark: the look's unlit depth
    // in the indicator's hue, at no more chroma than the lamp's own.
    final off = RawHct.fromColor(base.lampOff);
    final lamp = RawHct.fromColor(lit.fill);
    var colors = metal.copyWith(
      indicator: lit.fill,
      onIndicator: lit.ink,
      lampOff: lamp
          .withChroma(math.min(off.chroma, lamp.chroma))
          .withTone(off.tone)
          .toColor(),
    );
    if (brightness == Brightness.light) {
      // The glass keeps the look's brightness, tinted by the indicator.
      Color glass(Color own, double t) => hueFree
          ? RawNeutralTones.of(indicator).tone(RawHct.fromColor(own).tone)
          : RawHct.fromColor(Color.lerp(const Color(0xFFF4F1E7), lit.fill, t)!)
                .withTone(RawHct.fromColor(own).tone)
                .toColor();
      colors = colors.copyWith(
        readout: glass(base.readout, 0.25),
        readoutLow: glass(base.readoutLow, 0.38),
      );
    }
    final metals = [
      colors.chassis,
      colors.panel,
      colors.panelLow,
      colors.bar,
      colors.barLow,
    ];
    final glass = [colors.display, colors.displayLow];
    final keys = [colors.key, colors.keyLow];
    return StudioThemeData(
      colors: colors.copyWith(
        legendMuted: RawPalette.readableTone(base.legendMuted, on: metals),
        onDisplayMuted: RawPalette.readableTone(
          base.onDisplayMuted,
          on: [...glass, ...metals],
        ),
        dangerLegend: RawPalette.readableTone(
          base.dangerLegend,
          on: [...metals, ...glass],
        ),
        litLegend: RawPalette.readableTone(
          lit.fill,
          on: [...metals, ...glass, ...keys],
        ),
        focusRing: RawPalette.readableTone(
          lit.fill,
          on: [...metals, ...keys],
          ratio: 3,
        ),
      ),
      density: density,
      typeface: typeface,
    );
  }

  // The panels, bars and keys anodised in [finish]: its hue, at most half
  // its chroma and no more than a tint, at each metal's own tone (raised by
  // [lift]), so every word keeps its contrast. By night the tint eases to a
  // charcoal's.
  static StudioColors _anodise(StudioColors c, Color finish, double lift) {
    final f = RawHct.fromColor(finish);
    final tones = RawNeutralTones.of(
      f.withChroma(math.min(_finishChroma, f.chroma / 2)).toColor(),
    );
    Color tint(Color metal) =>
        tones.tone(math.min(100, RawHct.fromColor(metal).tone + lift));
    // The glass leans to the finish too, far fainter: a mint pane on plum
    // or brass would read as dirt.
    final glass = RawNeutralTones.of(
      f.withChroma(math.min(_glassChroma, f.chroma / 4)).toColor(),
    );
    Color pane(Color own) => glass.tone(RawHct.fromColor(own).tone);
    return c.copyWith(
      display: pane(c.display),
      displayLow: pane(c.displayLow),
      chassis: tint(c.chassis),
      chassisLow: tint(c.chassisLow),
      panel: tint(c.panel),
      panelLow: tint(c.panelLow),
      bar: tint(c.bar),
      barLow: tint(c.barLow),
      key: tint(c.key),
      keyLow: tint(c.keyLow),
    );
  }

  // The most chroma a finish lends the metal: a tint, as anodising leaves
  // the aluminium's grain showing.
  static const double _finishChroma = 7;

  // The most chroma a finish lends the display glass.
  static const double _glassChroma = 4;

  // By day moss's olive at the silver's own tones reads as khaki, so its
  // metal stands this many tones lighter, a pale anodised olive. Two is as
  // far as it goes while a key's top stays under white, proud of the panel.
  static const double _mossDayLift = 2;

  /// The look's six palettes, the first its default, each by day and by
  /// night: what an app's palette picker lists (each [RawNamedPalette] its
  /// label, and its lamp and its metal as swatches) and the
  /// [RawNamedPalette.id] an app stores and hands back to [preset] or
  /// [StudioHost.palette]. anodised: amber lamps on silver and graphite;
  /// cobalt: blue light on blue-anodised metal; teal: cyan lamps on
  /// blue-green steel; moss: green lamps on olive, a pale olive by day;
  /// violet: violet light on plum; graphite: cool white lamps on neutral
  /// steel, the one set with no hue.
  static const List<RawNamedPalette> palettes = <RawNamedPalette>[
    RawNamedPalette(
      id: 'anodised',
      label: 'Anodised',
      swatches: [Color(0xFFFFAE3A), Color(0xFFE3E5E8)],
      darkSwatches: [Color(0xFFFFAE3A), Color(0xFF292B2F)],
    ),
    RawNamedPalette(
      id: 'cobalt',
      label: 'Cobalt',
      swatches: [Color(0xFF4DA3FF), Color(0xFFE3E5ED)],
      darkSwatches: [Color(0xFF4DA3FF), Color(0xFF292B30)],
    ),
    RawNamedPalette(
      id: 'teal',
      label: 'Teal',
      swatches: [Color(0xFF2CD4C0), Color(0xFFDFE6E7)],
      darkSwatches: [Color(0xFF2CD4C0), Color(0xFF262C2D)],
    ),
    RawNamedPalette(
      id: 'moss',
      label: 'Moss',
      swatches: [Color(0xFF7BD34F), Color(0xFFEAECDE)],
      darkSwatches: [Color(0xFF7BD34F), Color(0xFF2A2C24)],
    ),
    RawNamedPalette(
      id: 'violet',
      label: 'Violet',
      swatches: [Color(0xFFB38CFF), Color(0xFFECE2EC)],
      darkSwatches: [Color(0xFFB38CFF), Color(0xFF2E2A2F)],
    ),
    RawNamedPalette(
      id: 'graphite',
      label: 'Graphite',
      swatches: [Color(0xFF313539), Color(0xFFE7E4E3)],
      darkSwatches: [Color(0xFFDFE3E8), Color(0xFF2B2B2A)],
    ),
  ];

  /// The preset of the palette [id] (one of [palettes]) in [brightness]:
  /// [StudioThemeData.anodised], or [StudioThemeData.from] its indicator
  /// and finish.
  ///
  /// ```dart
  /// final theme = StudioThemeData.preset('cobalt', Brightness.dark);
  /// ```
  factory StudioThemeData.preset(
    String id,
    Brightness brightness, {
    StudioDensity? density,
  }) {
    assert(
      palettes.any((p) => p.id == id),
      'Studio has no palette "$id": ${[for (final p in palettes) p.id]}',
    );
    final (Color, Color)? light = switch (id) {
      'cobalt' => (const Color(0xFF4DA3FF), const Color(0xFF2C5A8C)),
      'teal' => (const Color(0xFF2CD4C0), const Color(0xFF7FA8AC)),
      'moss' => (const Color(0xFF7BD34F), const Color(0xFF5C6B45)),
      'violet' => (const Color(0xFFB38CFF), const Color(0xFF5B4570)),
      'graphite' => (const Color(0xFFDFE3E8), const Color(0xFF8E8E8E)),
      _ => null,
    };
    if (light == null) {
      return StudioThemeData.anodised(brightness, density: density);
    }
    return StudioThemeData._lit(
      indicator: light.$1,
      finish: light.$2,
      brightness: brightness,
      density: density,
      lift: id == 'moss' && brightness == Brightness.light ? _mossDayLift : 0,
    );
  }

  /// The colours.
  final StudioColors colors;

  /// The type, set in [typeface].
  final StudioTextTheme textTheme;

  /// The face every word is set in.
  final StudioTypeface typeface;

  /// How tight the controls stand. By default the platform's: compact under
  /// a pointer (macOS, Windows, Linux), standard on touch.
  final StudioDensity density;

  /// How strongly the metal shows its brush: 0 smooth, 1 the look's. Glass
  /// is always smooth.
  final double textureStrength;

  /// The corners an app can change, held to [shapeLimits]: Studio's milled
  /// radii. [RawCorner.extraSmall] is a switch's cap and a fader's handle
  /// (3), [RawCorner.small] a readout's window and a toggle's slot (5),
  /// [RawCorner.medium] a key, a field's glass, a select's window (6),
  /// [RawCorner.large] a glass display pane (10) and [RawCorner.extraLarge]
  /// a panel module, a dialog, a sheet (12). The parts read them through
  /// [radiusCap] to [radiusPanel]; a bank that holds keys stays concentric
  /// with them ([radiusBank]). Lamps and knobs stay round, the corners stay
  /// arcs, and the groove pair and the relief stay the light's: Studio opens
  /// no stroke and no depth. A change of corners eases across with the
  /// theme ([lerp]).
  ///
  /// ```dart
  /// final rounder = StudioThemeData.dark().copyWith(
  ///   shapeScheme: StudioThemeData.defaultShapeScheme.copyWith(
  ///     corners: StudioThemeData.defaultShapeScheme.corners.scaled(1.5),
  ///   ),
  /// );
  /// ```
  final RawShapeScheme shapeScheme;

  /// Studio's own corners: round, 3, 5, 6, 10 and 12.
  static const RawShapeScheme defaultShapeScheme = RawShapeScheme(
    corners: RawCornerScale(
      extraSmall: 3,
      small: 5,
      medium: 6,
      large: 10,
      extraLarge: 12,
    ),
  );

  /// The bands Studio holds a [shapeScheme] to, so every end still reads as
  /// milled hardware: round corners alone; a key from 4 to 10 (under 4 a key
  /// reads as a tile, over 10 as a pebble); each other step in proportion,
  /// a milled part keeping a visible radius; no stroke and no depth. An
  /// app's part may take its own step on each corner (a part's style's
  /// `corners`), held to the steps from extra small to extra large: a
  /// milled corner is never sharp, and a key is never a pill.
  static const RawShapeLimits shapeLimits = RawShapeLimits(
    extraSmall: RawBand(2, 5),
    small: RawBand(3, 8),
    medium: RawBand(4, 10),
    large: RawBand(6, 14),
    extraLarge: RawBand(8, 18),
    cornerFreedom: RawCornerFreedom.perCorner,
    cornerSteps: {
      RawCorner.extraSmall,
      RawCorner.small,
      RawCorner.medium,
      RawCorner.large,
      RawCorner.extraLarge,
    },
  );

  /// A switch's cap, a fader's handle: 3 by default ([RawCorner.extraSmall]).
  double get radiusCap => shapeScheme.corners.extraSmall;

  /// A readout's window, a toggle's slot: 5 by default ([RawCorner.small]).
  double get radiusSmall => shapeScheme.corners.small;

  /// A key, a field's glass, a select's window: 6 by default
  /// ([RawCorner.medium]).
  double get radiusKey => shapeScheme.corners.medium;

  /// A glass display pane: 10 by default ([RawCorner.large]).
  double get radiusDisplay => shapeScheme.corners.large;

  /// A recess that holds keys (a bank, a rail): [radiusKey] plus
  /// [StudioMetrics.recessInset], so the keys in it stay concentric with it.
  double get radiusBank => radiusKey + StudioMetrics.recessInset;

  /// A panel module, a dialog, a sheet: 12 by default
  /// ([RawCorner.extraLarge]).
  double get radiusPanel => shapeScheme.corners.extraLarge;

  /// Every ordinary key ([StudioButton]).
  final StudioStyle? buttonStyle;

  /// Every lit key ([StudioButton.lit]).
  final StudioStyle? litButtonStyle;

  /// Every key with no cap ([StudioButton.text]).
  final StudioStyle? textButtonStyle;

  /// Every destructive key, over its kind's style.
  final StudioStyle? destructiveButtonStyle;

  /// Every [StudioIconButton].
  final StudioStyle? iconButtonStyle;

  /// Every [StudioTextField].
  final StudioStyle? textFieldStyle;

  /// Every [StudioSelect].
  final StudioStyle? selectStyle;

  /// Every [StudioCheckbox].
  final StudioStyle? checkboxStyle;

  /// Every [StudioRadio].
  final StudioStyle? radioStyle;

  /// Every [StudioSwitch].
  final StudioStyle? switchStyle;

  /// Every [StudioSegmentedButton].
  final StudioStyle? segmentedButtonStyle;

  /// Every [StudioFader].
  final StudioStyle? faderStyle;

  /// Every [StudioKnob].
  final StudioStyle? knobStyle;

  /// Every [StudioMeter].
  final StudioStyle? meterStyle;

  /// Every [StudioListTile].
  final StudioStyle? listTileStyle;

  /// Every [StudioSectionHeader].
  final StudioStyle? sectionHeaderStyle;

  /// Every [StudioPanel].
  final StudioStyle? panelStyle;

  /// Every [StudioDisplay].
  final StudioStyle? displayStyle;

  /// Every [StudioAppBar].
  final StudioStyle? appBarStyle;

  /// Every [StudioTabBar].
  final StudioStyle? tabBarStyle;

  /// Every [StudioPopover] and [StudioHoverCard].
  final StudioStyle? popoverStyle;

  /// Every [StudioTooltip].
  final StudioStyle? tooltipStyle;

  /// Every the panel [showStudioSideSheet] shows.
  final StudioStyle? sideSheetStyle;

  /// Every [StudioTag].
  final StudioStyle? tagStyle;

  /// Every [StudioDataTable].
  final StudioStyle? dataTableStyle;

  /// Every [StudioBreadcrumb].
  final StudioStyle? breadcrumbStyle;

  /// Every [StudioMenuBar].
  final StudioStyle? menuBarStyle;

  /// Every [StudioCommandPalette].
  final StudioStyle? commandPaletteStyle;

  /// Every [StudioCalendar] and the date pickers' calendars.
  final StudioStyle? calendarStyle;

  /// Every [StudioChip].
  final StudioStyle? chipStyle;

  /// Every [StudioRating].
  final StudioStyle? ratingStyle;

  /// Every [StudioFileDrop].
  final StudioStyle? fileDropStyle;

  /// Every [StudioFloatingKey].
  final StudioStyle? floatingKeyStyle;

  /// Every [StudioKeyRow].
  final StudioStyle? keyRowStyle;

  /// Every [StudioToggleBank].
  final StudioStyle? toggleBankStyle;

  /// Every [StudioLink].
  final StudioStyle? linkStyle;

  /// Every [StudioKbd].
  final StudioStyle? kbdStyle;

  /// Every [StudioNavigationBar].
  final StudioStyle? navigationBarStyle;

  /// Every [StudioNavigationRail].
  final StudioStyle? navigationRailStyle;

  /// Every [StudioSideNavigation].
  final StudioStyle? sideNavigationStyle;

  /// Every [StudioDialog].
  final StudioStyle? dialogStyle;

  /// Every sheet [showStudioBottomSheet] raises.
  final StudioStyle? bottomSheetStyle;

  /// Every toast.
  final StudioStyle? toastStyle;

  /// A key's height at this density.
  double get controlHeight => density.height(StudioMetrics.controlHeight);

  /// A row's height at this density.
  double get rowHeight => density.height(StudioMetrics.rowHeight);

  /// The capitals' height as a fraction of the face's size.
  double get capHeightFactor => typeface.capHeightFactor;

  /// A copy with the given fields replaced.
  StudioThemeData copyWith({
    StudioColors? colors,
    StudioTextTheme? textTheme,
    StudioTypeface? typeface,
    StudioDensity? density,
    double? textureStrength,
    StudioStyle? buttonStyle,
    StudioStyle? litButtonStyle,
    StudioStyle? textButtonStyle,
    StudioStyle? destructiveButtonStyle,
    StudioStyle? iconButtonStyle,
    StudioStyle? textFieldStyle,
    StudioStyle? selectStyle,
    StudioStyle? checkboxStyle,
    StudioStyle? radioStyle,
    StudioStyle? switchStyle,
    StudioStyle? segmentedButtonStyle,
    StudioStyle? faderStyle,
    StudioStyle? knobStyle,
    StudioStyle? meterStyle,
    StudioStyle? listTileStyle,
    StudioStyle? sectionHeaderStyle,
    StudioStyle? panelStyle,
    StudioStyle? displayStyle,
    StudioStyle? appBarStyle,
    StudioStyle? tabBarStyle,
    StudioStyle? popoverStyle,
    StudioStyle? tooltipStyle,
    StudioStyle? sideSheetStyle,
    StudioStyle? tagStyle,
    StudioStyle? dataTableStyle,
    StudioStyle? breadcrumbStyle,
    StudioStyle? menuBarStyle,
    StudioStyle? commandPaletteStyle,
    StudioStyle? calendarStyle,
    StudioStyle? chipStyle,
    StudioStyle? ratingStyle,
    StudioStyle? fileDropStyle,
    StudioStyle? floatingKeyStyle,
    StudioStyle? keyRowStyle,
    StudioStyle? toggleBankStyle,
    StudioStyle? linkStyle,
    StudioStyle? kbdStyle,
    StudioStyle? navigationBarStyle,
    StudioStyle? navigationRailStyle,
    StudioStyle? sideNavigationStyle,
    StudioStyle? dialogStyle,
    StudioStyle? bottomSheetStyle,
    StudioStyle? toastStyle,
    RawShapeScheme? shapeScheme,
  }) {
    final nextColors = colors ?? this.colors;
    final nextFace = typeface ?? this.typeface;
    return StudioThemeData(
      colors: nextColors,
      typeface: nextFace,
      textTheme:
          textTheme ??
          (colors == null && typeface == null
              ? this.textTheme
              : StudioTextTheme.of(nextColors, typeface: nextFace)),
      density: density ?? this.density,
      textureStrength: textureStrength ?? this.textureStrength,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      litButtonStyle: litButtonStyle ?? this.litButtonStyle,
      textButtonStyle: textButtonStyle ?? this.textButtonStyle,
      destructiveButtonStyle:
          destructiveButtonStyle ?? this.destructiveButtonStyle,
      iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
      textFieldStyle: textFieldStyle ?? this.textFieldStyle,
      selectStyle: selectStyle ?? this.selectStyle,
      checkboxStyle: checkboxStyle ?? this.checkboxStyle,
      radioStyle: radioStyle ?? this.radioStyle,
      switchStyle: switchStyle ?? this.switchStyle,
      segmentedButtonStyle: segmentedButtonStyle ?? this.segmentedButtonStyle,
      faderStyle: faderStyle ?? this.faderStyle,
      knobStyle: knobStyle ?? this.knobStyle,
      meterStyle: meterStyle ?? this.meterStyle,
      listTileStyle: listTileStyle ?? this.listTileStyle,
      sectionHeaderStyle: sectionHeaderStyle ?? this.sectionHeaderStyle,
      panelStyle: panelStyle ?? this.panelStyle,
      displayStyle: displayStyle ?? this.displayStyle,
      appBarStyle: appBarStyle ?? this.appBarStyle,
      tabBarStyle: tabBarStyle ?? this.tabBarStyle,
      popoverStyle: popoverStyle ?? this.popoverStyle,
      tooltipStyle: tooltipStyle ?? this.tooltipStyle,
      sideSheetStyle: sideSheetStyle ?? this.sideSheetStyle,
      tagStyle: tagStyle ?? this.tagStyle,
      dataTableStyle: dataTableStyle ?? this.dataTableStyle,
      breadcrumbStyle: breadcrumbStyle ?? this.breadcrumbStyle,
      menuBarStyle: menuBarStyle ?? this.menuBarStyle,
      commandPaletteStyle: commandPaletteStyle ?? this.commandPaletteStyle,
      calendarStyle: calendarStyle ?? this.calendarStyle,
      chipStyle: chipStyle ?? this.chipStyle,
      ratingStyle: ratingStyle ?? this.ratingStyle,
      fileDropStyle: fileDropStyle ?? this.fileDropStyle,
      floatingKeyStyle: floatingKeyStyle ?? this.floatingKeyStyle,
      keyRowStyle: keyRowStyle ?? this.keyRowStyle,
      toggleBankStyle: toggleBankStyle ?? this.toggleBankStyle,
      linkStyle: linkStyle ?? this.linkStyle,
      kbdStyle: kbdStyle ?? this.kbdStyle,
      navigationBarStyle: navigationBarStyle ?? this.navigationBarStyle,
      navigationRailStyle: navigationRailStyle ?? this.navigationRailStyle,
      sideNavigationStyle: sideNavigationStyle ?? this.sideNavigationStyle,
      dialogStyle: dialogStyle ?? this.dialogStyle,
      bottomSheetStyle: bottomSheetStyle ?? this.bottomSheetStyle,
      toastStyle: toastStyle ?? this.toastStyle,
      shapeScheme: shapeScheme ?? this.shapeScheme,
    );
  }

  /// Between [a] and [b] at [t]: colours, type, density, brush and corners
  /// move; the part styles move where both name one.
  static StudioThemeData lerp(StudioThemeData a, StudioThemeData b, double t) {
    if (identical(a, b)) return a;
    StudioStyle? s(StudioStyle? x, StudioStyle? y) => StudioStyle.lerp(x, y, t);
    return StudioThemeData(
      colors: StudioColors.lerp(a.colors, b.colors, t),
      textTheme: StudioTextTheme.lerp(a.textTheme, b.textTheme, t),
      typeface: t < 0.5 ? a.typeface : b.typeface,
      density: StudioDensity.lerp(a.density, b.density, t),
      textureStrength:
          a.textureStrength + (b.textureStrength - a.textureStrength) * t,
      buttonStyle: s(a.buttonStyle, b.buttonStyle),
      litButtonStyle: s(a.litButtonStyle, b.litButtonStyle),
      textButtonStyle: s(a.textButtonStyle, b.textButtonStyle),
      destructiveButtonStyle: s(
        a.destructiveButtonStyle,
        b.destructiveButtonStyle,
      ),
      iconButtonStyle: s(a.iconButtonStyle, b.iconButtonStyle),
      textFieldStyle: s(a.textFieldStyle, b.textFieldStyle),
      selectStyle: s(a.selectStyle, b.selectStyle),
      checkboxStyle: s(a.checkboxStyle, b.checkboxStyle),
      radioStyle: s(a.radioStyle, b.radioStyle),
      switchStyle: s(a.switchStyle, b.switchStyle),
      segmentedButtonStyle: s(a.segmentedButtonStyle, b.segmentedButtonStyle),
      faderStyle: s(a.faderStyle, b.faderStyle),
      knobStyle: s(a.knobStyle, b.knobStyle),
      meterStyle: s(a.meterStyle, b.meterStyle),
      listTileStyle: s(a.listTileStyle, b.listTileStyle),
      sectionHeaderStyle: s(a.sectionHeaderStyle, b.sectionHeaderStyle),
      panelStyle: s(a.panelStyle, b.panelStyle),
      displayStyle: s(a.displayStyle, b.displayStyle),
      appBarStyle: s(a.appBarStyle, b.appBarStyle),
      tabBarStyle: s(a.tabBarStyle, b.tabBarStyle),
      popoverStyle: s(a.popoverStyle, b.popoverStyle),
      tooltipStyle: s(a.tooltipStyle, b.tooltipStyle),
      sideSheetStyle: s(a.sideSheetStyle, b.sideSheetStyle),
      tagStyle: s(a.tagStyle, b.tagStyle),
      dataTableStyle: s(a.dataTableStyle, b.dataTableStyle),
      breadcrumbStyle: s(a.breadcrumbStyle, b.breadcrumbStyle),
      menuBarStyle: s(a.menuBarStyle, b.menuBarStyle),
      commandPaletteStyle: s(a.commandPaletteStyle, b.commandPaletteStyle),
      calendarStyle: s(a.calendarStyle, b.calendarStyle),
      chipStyle: s(a.chipStyle, b.chipStyle),
      ratingStyle: s(a.ratingStyle, b.ratingStyle),
      fileDropStyle: s(a.fileDropStyle, b.fileDropStyle),
      floatingKeyStyle: s(a.floatingKeyStyle, b.floatingKeyStyle),
      keyRowStyle: s(a.keyRowStyle, b.keyRowStyle),
      toggleBankStyle: s(a.toggleBankStyle, b.toggleBankStyle),
      linkStyle: s(a.linkStyle, b.linkStyle),
      kbdStyle: s(a.kbdStyle, b.kbdStyle),
      navigationBarStyle: s(a.navigationBarStyle, b.navigationBarStyle),
      navigationRailStyle: s(a.navigationRailStyle, b.navigationRailStyle),
      sideNavigationStyle: s(a.sideNavigationStyle, b.sideNavigationStyle),
      dialogStyle: s(a.dialogStyle, b.dialogStyle),
      bottomSheetStyle: s(a.bottomSheetStyle, b.bottomSheetStyle),
      toastStyle: s(a.toastStyle, b.toastStyle),
      shapeScheme: RawShapeScheme.lerp(a.shapeScheme, b.shapeScheme, t),
    );
  }

  List<Object?> get _all => [
    colors,
    textTheme,
    typeface,
    density,
    textureStrength,
    buttonStyle,
    litButtonStyle,
    textButtonStyle,
    destructiveButtonStyle,
    iconButtonStyle,
    textFieldStyle,
    selectStyle,
    checkboxStyle,
    radioStyle,
    switchStyle,
    segmentedButtonStyle,
    faderStyle,
    knobStyle,
    meterStyle,
    listTileStyle,
    sectionHeaderStyle,
    panelStyle,
    displayStyle,
    appBarStyle,
    tabBarStyle,
    popoverStyle,
    tooltipStyle,
    sideSheetStyle,
    tagStyle,
    dataTableStyle,
    breadcrumbStyle,
    menuBarStyle,
    commandPaletteStyle,
    calendarStyle,
    chipStyle,
    ratingStyle,
    fileDropStyle,
    floatingKeyStyle,
    keyRowStyle,
    toggleBankStyle,
    linkStyle,
    kbdStyle,
    navigationBarStyle,
    navigationRailStyle,
    sideNavigationStyle,
    dialogStyle,
    bottomSheetStyle,
    toastStyle,
    shapeScheme,
  ];

  @override
  bool operator ==(Object other) =>
      other is StudioThemeData && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<StudioColors>('colors', colors))
      ..add(DiagnosticsProperty<StudioTypeface>('typeface', typeface))
      ..add(DiagnosticsProperty<StudioDensity>('density', density))
      ..add(DoubleProperty('textureStrength', textureStrength))
      ..add(
        DiagnosticsProperty<RawShapeScheme>(
          'shapeScheme',
          shapeScheme,
          defaultValue: defaultShapeScheme,
        ),
      );
  }
}

/// Studio for [child]: the theme, the grid its spacing stands on, the tap
/// floors its controls stand at, and the Material theme under its parts.
/// Install it once, in an app's `builder:`.
///
/// ```dart
/// MaterialApp(builder: (context, child) => StudioTheme(data: StudioThemeData.dark(), child: child!), home: const Home())
/// ```
class StudioTheme extends StatelessWidget {
  /// Studio in [data] for [child].
  const StudioTheme({super.key, required this.data, required this.child});

  /// The theme.
  final StudioThemeData data;

  /// What wears it.
  final Widget child;

  /// The tap floors every Studio control stands at: 40 by 40 for a finger,
  /// 24 by 24 for a pointer (ui_core's own floors).
  static const RawTapTargets tapTargets = RawTapTargets.fallback;

  static final StudioThemeData _fallback = StudioThemeData.light();

  /// The theme above [context], or the look by day when there is none, as
  /// `Theme.of` falls back to its default.
  static StudioThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static StudioThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedStudioTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    final bridge = _bridges[data] ??= _materialUnder(colors, data.typeface);
    // The Theme stands over the app's navigator when StudioTheme is in the
    // app's builder, so its routes change pages by this theme: Studio's,
    // unless the app's own theme chose another.
    final outer = Theme.of(context).pageTransitionsTheme;
    final material =
        outer == const PageTransitionsTheme() ||
            outer == bridge.pageTransitionsTheme
        ? bridge
        : bridge.copyWith(pageTransitionsTheme: outer);
    Widget under = _InheritedStudioTheme(
      theme: this,
      child: Theme(
        data: material,
        child: RawSpacingScope(
          spacing: RawSpacing.fallback,
          child: RawTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.indicator,
              selectionColor: colors.indicator.withValues(alpha: 0.35),
              child: IconTheme(
                data: IconThemeData(color: colors.legend, size: 20),
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
    // Studio's text field asks for the words of the Material library Studio
    // is built on, and its menu on iOS for Cupertino's. An app with none of
    // either gets Studio's own English, never a throw; an app that has them
    // keeps its own. The app's direction is kept.
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

  static final Expando<ThemeData> _bridges = Expando('StudioTheme bridges');

  static ThemeData _materialUnder(
    StudioColors colors,
    StudioTypeface typeface,
  ) => ThemeData(
    brightness: colors.brightness,
    fontFamily: typeface.family,
    package: typeface.package,
    fontFamilyFallback: typeface.fallback.isEmpty ? null : typeface.fallback,
    useMaterial3: true,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: studioPageTransitions,
    ),
    visualDensity: VisualDensity.standard,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    splashColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    focusColor: const Color(0x00000000),
    scaffoldBackgroundColor: colors.chassis,
    canvasColor: colors.chassis,
    colorScheme: ColorScheme.fromSeed(
      seedColor: colors.indicator,
      brightness: colors.brightness,
      primary: colors.indicator,
      onPrimary: colors.onIndicator,
      surface: colors.panel,
      onSurface: colors.legend,
      error: colors.danger,
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: colors.indicator,
      selectionColor: colors.indicator.withValues(alpha: 0.35),
      selectionHandleColor: colors.indicator,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StudioThemeData>('data', data));
  }
}

class _InheritedStudioTheme extends InheritedTheme {
  const _InheritedStudioTheme({required this.theme, required super.child});

  final StudioTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      StudioTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedStudioTheme old) =>
      theme.data != old.theme.data;
}

/// [StudioTheme] that moves to a new [data] smoothly (a bright room to low
/// light, one density to another), as `AnimatedTheme` does; quickly under
/// Reduce Motion.
///
/// ```dart
/// AnimatedStudioTheme(data: night ? StudioThemeData.dark() : StudioThemeData.light(), child: page)
/// ```
class AnimatedStudioTheme extends ImplicitlyAnimatedWidget {
  /// Animates to [data] whenever it changes.
  const AnimatedStudioTheme({
    super.key,
    required this.data,
    required this.child,
    super.curve = Curves.easeOut,
    super.duration = const Duration(milliseconds: 240),
    super.onEnd,
  });

  /// The theme to arrive at.
  final StudioThemeData data;

  /// What wears it.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedStudioTheme> createState() =>
      _AnimatedStudioThemeState();
}

class _AnimatedStudioThemeState
    extends AnimatedWidgetBaseState<AnimatedStudioTheme> {
  _StudioThemeTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => _StudioThemeTween(begin: value as StudioThemeData),
    ) as _StudioThemeTween?;
  }

  @override
  Widget build(BuildContext context) => StudioTheme(
    data: MediaQuery.maybeDisableAnimationsOf(context) ?? false
        ? widget.data
        : _data!.evaluate(animation),
    child: widget.child,
  );
}

class _StudioThemeTween extends Tween<StudioThemeData> {
  _StudioThemeTween({super.begin});

  @override
  StudioThemeData lerp(double t) => StudioThemeData.lerp(begin!, end!, t);
}

/// Reads Studio's theme from a [BuildContext].
extension StudioThemeContext on BuildContext {
  /// [StudioTheme.of] this context.
  StudioThemeData get studioTheme => StudioTheme.of(this);
}

// The words of the Material and Cupertino libraries Studio is built on, which
// StudioTheme gives its parts when the app gives none: English in any locale.
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
