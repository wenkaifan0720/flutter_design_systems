/// Keycap's theme: its colourway (the case, the wells, the alpha, modifier
/// and accent keys), its type, its measures, its motion, its density, and the
/// [KeycapTheme] every app installs once in its `builder:`.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoLocalizations, DefaultCupertinoLocalizations;
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'page_transitions.dart';

/// How one part of Keycap looks, as Material's `ButtonStyle` is: every slot a
/// `WidgetStateProperty`, read from a part's `style:` first, then from its
/// component theme on [KeycapThemeData], then from the look's own default.
///
/// ```dart
/// final wide = KeycapStyle(padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 32)));
/// ```
typedef KeycapStyle = RawStyle;

/// How tight Keycap's controls stand: ui_core's [RawDensity] under Keycap's
/// name, the same type, so either name works. [RawDensity.standard] (a 48 px
/// key), [RawDensity.comfortable] (44) or [RawDensity.compact] (40). A
/// control's tap target stays at the floor for the input whatever the
/// density. [KeycapThemeData.density] defaults to
/// [RawDensity.adaptivePlatformDensity]: compact on a desktop, standard on
/// a phone.
typedef KeycapDensity = RawDensity;

/// The relative luminance contrast of [a] on [b], 1 to 21, as WCAG measures
/// it ([RawPalette.contrastRatio]; a translucent [a] is read laid over [b]).
///
/// ```dart
/// keycapContrast(colors.ink, colors.ground) >= 4.5
/// ```
double keycapContrast(Color a, Color b) => RawPalette.contrastRatio(a, b);

/// One kind of keycap in a colourway: the plastic of its dished [top] face,
/// its side walls ([wall]), its deepest wall, the front one ([front]), and
/// the [legend] printed on it.
@immutable
class KeycapCapColors with Diagnosticable {
  /// A cap's colours.
  const KeycapCapColors({
    required this.top,
    required this.wall,
    required this.front,
    required this.legend,
  });

  /// A cap moulded in [top], its walls shaded down from it toward [shade]
  /// (the sides by [wallShade], the front by [frontShade]), printed in
  /// [legend].
  ///
  /// ```dart
  /// final teal = KeycapCapColors.moulded(const Color(0xFF1F8A8A), legend: const Color(0xFFFFFFFF), shade: const Color(0xFF000000));
  /// ```
  factory KeycapCapColors.moulded(
    Color top, {
    required Color legend,
    required Color shade,
    double wallShade = 0.12,
    double frontShade = 0.26,
  }) => KeycapCapColors(
    top: top,
    wall: Color.lerp(top, shade, wallShade)!,
    front: Color.lerp(top, shade, frontShade)!,
    legend: legend,
  );

  /// The dished top face.
  final Color top;

  /// The side walls.
  final Color wall;

  /// The front wall, the one that shows most.
  final Color front;

  /// The legend printed on the top face.
  final Color legend;

  /// The back wall: the top's plastic catching the light.
  Color get back => Color.lerp(top, wall, 0.35)!;

  /// A copy with the given colours replaced.
  KeycapCapColors copyWith({
    Color? top,
    Color? wall,
    Color? front,
    Color? legend,
  }) => KeycapCapColors(
    top: top ?? this.top,
    wall: wall ?? this.wall,
    front: front ?? this.front,
    legend: legend ?? this.legend,
  );

  /// Between [a] and [b] by [t].
  static KeycapCapColors lerp(KeycapCapColors a, KeycapCapColors b, double t) {
    if (identical(a, b)) return a;
    return KeycapCapColors(
      top: Color.lerp(a.top, b.top, t)!,
      wall: Color.lerp(a.wall, b.wall, t)!,
      front: Color.lerp(a.front, b.front, t)!,
      legend: Color.lerp(a.legend, b.legend, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeycapCapColors &&
      other.top == top &&
      other.wall == wall &&
      other.front == front &&
      other.legend == legend;

  @override
  int get hashCode => Object.hash(top, wall, front, legend);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('top', top))
      ..add(ColorProperty('wall', wall))
      ..add(ColorProperty('front', front))
      ..add(ColorProperty('legend', legend));
  }
}

/// Keycap's colourway, by role. The keys: [alpha] (the light keys, a
/// screen's neutral controls), [modifier] (the darker keys: secondary
/// controls, and what is latched or current), [accent] (the one coloured
/// key: a screen's main action) and [danger] (a key that destroys). The
/// keyboard round them: the [ground] (the case), the [well] (an opening cut
/// into it, where groups, lists and fields sit) and the [panel] (keycap
/// plastic laid over the keyboard: a dialog, a sheet, a menu). The roles
/// never swap: a key's colour says what kind of key it is.
///
/// [KeycapColors.light] is the classic colourway in daylight: light cool-grey
/// alphas, slate modifiers, a cobalt accent on a cool slate case.
/// [KeycapColors.dark] is the same keyboard in a dark colourway, the accent
/// faintly backlit. [KeycapColors.from] recolours the accent (and the alphas)
/// for a brand and keeps the contrast.
@immutable
class KeycapColors with Diagnosticable {
  /// Every role given.
  const KeycapColors({
    required this.brightness,
    required this.ground,
    required this.well,
    required this.wellPressed,
    required this.wellShade,
    required this.wellLip,
    required this.page,
    required this.pagePressed,
    required this.pageSelected,
    required this.panel,
    required this.alpha,
    required this.modifier,
    required this.accent,
    required this.danger,
    required this.latchedLegend,
    required this.ink,
    required this.inkMuted,
    required this.inkDisabled,
    required this.accentInk,
    required this.dangerInk,
    required this.success,
    required this.hairline,
    required this.edge,
    required this.focus,
    required this.shadow,
    required this.backlight,
    required this.scrim,
    required this.toast,
    required this.onToast,
    this._info,
  });

  /// The classic colourway in daylight: light cool-grey alphas, slate
  /// modifiers, a cobalt accent, on a cool slate case whose wells are cut a
  /// shade darker.
  static const KeycapColors light = KeycapColors(
    brightness: Brightness.light,
    ground: Color(0xFFCDD2DA),
    well: Color(0xFFB5BCC6),
    wellPressed: Color(0xFFABB2BD),
    wellShade: Color(0x4D0E1420),
    wellLip: Color(0x99FFFFFF),
    page: Color(0xFFF7F8FA),
    pagePressed: Color(0xFFE4E7EC),
    pageSelected: Color(0xFFD3D7DE),
    panel: Color(0xFFF3F5F8),
    alpha: KeycapCapColors(
      top: Color(0xFFEEF1F5),
      wall: Color(0xFFC9CFD8),
      front: Color(0xFFA6AEBA),
      legend: Color(0xFF1B1F26),
    ),
    modifier: KeycapCapColors(
      top: Color(0xFFA3ABB7),
      wall: Color(0xFF8C95A2),
      front: Color(0xFF76808E),
      legend: Color(0xFF12151A),
    ),
    accent: KeycapCapColors(
      top: Color(0xFF2F59CF),
      wall: Color(0xFF2649B0),
      front: Color(0xFF1C3A90),
      legend: Color(0xFFFFFFFF),
    ),
    danger: KeycapCapColors(
      top: Color(0xFFC0392B),
      wall: Color(0xFFA43024),
      front: Color(0xFF85261C),
      legend: Color(0xFFFFFFFF),
    ),
    latchedLegend: Color(0xFF12151A),
    ink: Color(0xFF1B1F26),
    inkMuted: Color(0xFF3C434C),
    inkDisabled: Color(0xFF7F8794),
    accentInk: Color(0xFF1F3F96),
    dangerInk: Color(0xFF84231A),
    success: Color(0xFF1A4D2D),
    // A note's ink: the ocean's teal, apart from the cobalt key's words.
    info: Color(0xFF00545C),
    hairline: Color(0x24141A24),
    edge: Color(0x47121822),
    focus: Color(0xFF1F3F96),
    shadow: Color(0xFF0E1420),
    backlight: Color(0x002F59CF),
    scrim: Color(0x660E1218),
    toast: Color(0xFF2A2E35),
    onToast: Color(0xFFF1F3F6),
  );

  /// The same keyboard in a dark colourway: graphite alphas, deeper
  /// modifiers, the cobalt accent with its backlight showing faintly round
  /// its foot.
  static const KeycapColors dark = KeycapColors(
    brightness: Brightness.dark,
    ground: Color(0xFF1C1F24),
    well: Color(0xFF14161A),
    wellPressed: Color(0xFF22252B),
    wellShade: Color(0x80000000),
    wellLip: Color(0x0FFFFFFF),
    // By night a page stays sunk, a shade under the case (a lighter page
    // reads as a raised card in the dark), and lighter than a small well.
    page: Color(0xFF181A1F),
    pagePressed: Color(0xFF23262C),
    pageSelected: Color(0xFF2E3138),
    panel: Color(0xFF272A31),
    alpha: KeycapCapColors(
      top: Color(0xFF454A53),
      wall: Color(0xFF33373E),
      front: Color(0xFF24272C),
      legend: Color(0xFFEEF0F4),
    ),
    modifier: KeycapCapColors(
      top: Color(0xFF2E3137),
      wall: Color(0xFF23262B),
      front: Color(0xFF17191D),
      legend: Color(0xFFDADDE3),
    ),
    accent: KeycapCapColors(
      top: Color(0xFF3D63D6),
      wall: Color(0xFF3155BC),
      front: Color(0xFF25449A),
      legend: Color(0xFFFFFFFF),
    ),
    danger: KeycapCapColors(
      top: Color(0xFFC9473A),
      wall: Color(0xFFB03E32),
      front: Color(0xFF8E3128),
      legend: Color(0xFFFFFFFF),
    ),
    latchedLegend: Color(0xFF9DB4F5),
    ink: Color(0xFFECEEF2),
    inkMuted: Color(0xFFA3A9B3),
    inkDisabled: Color(0xFF6B717B),
    accentInk: Color(0xFF8DA7F2),
    dangerInk: Color(0xFFF08A7E),
    success: Color(0xFF6CC48A),
    // A note's ink: the ocean's teal, apart from the cobalt key's words.
    info: Color(0xFF4AA5AF),
    hairline: Color(0x14FFFFFF),
    edge: Color(0x24FFFFFF),
    focus: Color(0xFF8DA7F2),
    shadow: Color(0xFF000000),
    backlight: Color(0x592F59CF),
    scrim: Color(0x99000000),
    toast: Color(0xFF3A3E46),
    onToast: Color(0xFFF1F3F6),
  );

  /// Keycap by [brightness], its accent key moulded in [accent] (its walls
  /// shaded from it, its legend white or ink, whichever reads at 4.5:1; the
  /// key moves only as far as it must when neither does; its ink and focus
  /// the nearest tones of its hue that read on the case, the wells, the
  /// pages, a chosen row and the panels) and its alphas tinted toward [alpha]
  /// when given (their tones kept, so the legends keep their contrast; by
  /// night the tint holds little chroma, so a cream's alphas are a warm
  /// graphite, never brown). The modifiers and the case stay the colourway's.
  ///
  /// ```dart
  /// final teal = KeycapColors.from(brightness: Brightness.light, accent: const Color(0xFF16807A));
  /// ```
  factory KeycapColors.from({
    required Brightness brightness,
    Color? accent,
    Color? alpha,
  }) {
    final night = brightness == Brightness.dark;
    final base = night ? dark : light;
    var colors = base;
    if (alpha != null) {
      final tint = RawHct.fromColor(alpha);
      final tones = RawNeutralTones.of(
        tint.withChroma(math.min(tint.chroma, _alphaTint)).toColor(),
      );
      colors = colors.copyWith(alpha: _tinted(base.alpha, tones));
    }
    return accent == null ? colors : _keyed(colors, accent);
  }

  /// Keycap's colourway [name] (one of [KeycapThemeData.presets]) for
  /// [brightness]: `classic` ([light] and [dark]), `retro` (beige alphas,
  /// warm grey modifiers, an amber key), `sage` (a sage keyboard, a green
  /// key), `rose` (blush alphas, mauve modifiers, a rose key), `lilac`
  /// (lilac alphas, a violet key) or `ocean` (sea-grey alphas, a teal key).
  /// Each is the classic keyboard's plastics at their own tones in another
  /// hue, so every legend and word reads as it does in classic. An unknown
  /// name gives classic.
  ///
  /// ```dart
  /// final sage = KeycapColors.preset('sage', Brightness.dark);
  /// ```
  factory KeycapColors.preset(String name, Brightness brightness) {
    final way = _colourways[name];
    if (way == null) return brightness == Brightness.dark ? dark : light;
    return _presets[(name, brightness)] ??= way.colors(brightness);
  }

  static final Map<(String, Brightness), KeycapColors> _presets = {};

  /// Day or night.
  final Brightness brightness;

  /// The case: the app's ground, under everything.
  final Color ground;

  /// A well's floor: an opening cut into the case, where a group of rows, a
  /// card or a field's words sit.
  final Color well;

  /// A row's floor while it is pressed.
  final Color wellPressed;

  /// The plate's thickness along a well's top inside edge, a hard band.
  final Color wellShade;

  /// The light along a well's bottom inside edge.
  final Color wellLip;

  /// A page's floor: a large well that is read or written in (a group of
  /// rows, a card, a table, a note's words). By day the lightest surface on
  /// the case, its cut shown by its crisp edge and the plate's band, not by
  /// a darker floor; by night a shade under the case. Small wells (a field,
  /// a search, a track) keep [well].
  final Color page;

  /// A row's floor on a page while it is pressed.
  final Color pagePressed;

  /// A row's floor on a page while it is the chosen one: a plate of
  /// modifier plastic.
  final Color pageSelected;

  /// Keycap plastic laid over the keyboard: a dialog, a sheet, a menu.
  final Color panel;

  /// The light keys: a screen's neutral controls.
  final KeycapCapColors alpha;

  /// The darker keys: secondary controls, and what is latched or current.
  final KeycapCapColors modifier;

  /// The one coloured key: a screen's main action.
  final KeycapCapColors accent;

  /// A key that destroys something.
  final KeycapCapColors danger;

  /// The legend of a latched key: the modifier's by day; by night lit by
  /// the backlight, so what is chosen shows in a dark room.
  final Color latchedLegend;

  /// Words on the case, in a well or on a panel.
  final Color ink;

  /// Supporting words.
  final Color inkMuted;

  /// The words of a part that is off.
  final Color inkDisabled;

  /// The accent as words (a link, a text action): 4.5:1 on a well.
  final Color accentInk;

  /// What is wrong, as words.
  final Color dangerInk;

  /// What went right, as words or a mark.
  final Color success;

  /// A note's ink (`KeycapTone.info`), apart from the accent's words, so a
  /// note never reads as a link or a choice: the classic's cobalt, or the
  /// ocean's teal where the key itself is cobalt or near it (classic's,
  /// lilac's), whichever stands farther from [accentInk], [success], [ink]
  /// and [dangerInk]; 4.5:1 on the same grounds. Unset, [accentInk].
  Color get info => _info ?? accentInk;
  final Color? _info;

  /// A rule between rows.
  final Color hairline;

  /// The fine edge round a well or a panel, so it reads on any ground.
  final Color edge;

  /// Keyboard focus: the backlight showing round a focused key's foot.
  final Color focus;

  /// The colour shadows are cast in.
  final Color shadow;

  /// The accent key's backlight round its foot (clear by day).
  final Color backlight;

  /// The dim over the page behind a dialog or a sheet.
  final Color scrim;

  /// A toast's panel.
  final Color toast;

  /// A toast's words.
  final Color onToast;

  /// A copy with the given roles replaced.
  KeycapColors copyWith({
    Brightness? brightness,
    Color? ground,
    Color? well,
    Color? wellPressed,
    Color? wellShade,
    Color? wellLip,
    Color? page,
    Color? pagePressed,
    Color? pageSelected,
    Color? panel,
    KeycapCapColors? alpha,
    KeycapCapColors? modifier,
    KeycapCapColors? accent,
    KeycapCapColors? danger,
    Color? latchedLegend,
    Color? ink,
    Color? inkMuted,
    Color? inkDisabled,
    Color? accentInk,
    Color? dangerInk,
    Color? success,
    Color? info,
    Color? hairline,
    Color? edge,
    Color? focus,
    Color? shadow,
    Color? backlight,
    Color? scrim,
    Color? toast,
    Color? onToast,
  }) => KeycapColors(
    brightness: brightness ?? this.brightness,
    ground: ground ?? this.ground,
    well: well ?? this.well,
    wellPressed: wellPressed ?? this.wellPressed,
    wellShade: wellShade ?? this.wellShade,
    wellLip: wellLip ?? this.wellLip,
    page: page ?? this.page,
    pagePressed: pagePressed ?? this.pagePressed,
    pageSelected: pageSelected ?? this.pageSelected,
    panel: panel ?? this.panel,
    alpha: alpha ?? this.alpha,
    modifier: modifier ?? this.modifier,
    accent: accent ?? this.accent,
    danger: danger ?? this.danger,
    latchedLegend: latchedLegend ?? this.latchedLegend,
    ink: ink ?? this.ink,
    inkMuted: inkMuted ?? this.inkMuted,
    inkDisabled: inkDisabled ?? this.inkDisabled,
    accentInk: accentInk ?? this.accentInk,
    dangerInk: dangerInk ?? this.dangerInk,
    success: success ?? this.success,
    info: info ?? _info,
    hairline: hairline ?? this.hairline,
    edge: edge ?? this.edge,
    focus: focus ?? this.focus,
    shadow: shadow ?? this.shadow,
    backlight: backlight ?? this.backlight,
    scrim: scrim ?? this.scrim,
    toast: toast ?? this.toast,
    onToast: onToast ?? this.onToast,
  );

  /// Between [a] and [b] by [t].
  static KeycapColors lerp(KeycapColors a, KeycapColors b, double t) {
    if (identical(a, b)) return a;
    Color c(Color x, Color y) => Color.lerp(x, y, t)!;
    return KeycapColors(
      brightness: t < 0.5 ? a.brightness : b.brightness,
      ground: c(a.ground, b.ground),
      well: c(a.well, b.well),
      wellPressed: c(a.wellPressed, b.wellPressed),
      wellShade: c(a.wellShade, b.wellShade),
      wellLip: c(a.wellLip, b.wellLip),
      page: c(a.page, b.page),
      pagePressed: c(a.pagePressed, b.pagePressed),
      pageSelected: c(a.pageSelected, b.pageSelected),
      panel: c(a.panel, b.panel),
      alpha: KeycapCapColors.lerp(a.alpha, b.alpha, t),
      modifier: KeycapCapColors.lerp(a.modifier, b.modifier, t),
      accent: KeycapCapColors.lerp(a.accent, b.accent, t),
      danger: KeycapCapColors.lerp(a.danger, b.danger, t),
      latchedLegend: c(a.latchedLegend, b.latchedLegend),
      ink: c(a.ink, b.ink),
      inkMuted: c(a.inkMuted, b.inkMuted),
      inkDisabled: c(a.inkDisabled, b.inkDisabled),
      accentInk: c(a.accentInk, b.accentInk),
      dangerInk: c(a.dangerInk, b.dangerInk),
      success: c(a.success, b.success),
      info: c(a.info, b.info),
      hairline: c(a.hairline, b.hairline),
      edge: c(a.edge, b.edge),
      focus: c(a.focus, b.focus),
      shadow: c(a.shadow, b.shadow),
      backlight: c(a.backlight, b.backlight),
      scrim: c(a.scrim, b.scrim),
      toast: c(a.toast, b.toast),
      onToast: c(a.onToast, b.onToast),
    );
  }

  List<Object> get _values => [
    brightness,
    ground,
    well,
    wellPressed,
    wellShade,
    wellLip,
    page,
    pagePressed,
    pageSelected,
    panel,
    alpha,
    modifier,
    accent,
    danger,
    latchedLegend,
    ink,
    inkMuted,
    inkDisabled,
    accentInk,
    dangerInk,
    success,
    info,
    hairline,
    edge,
    focus,
    shadow,
    backlight,
    scrim,
    toast,
    onToast,
  ];

  @override
  bool operator ==(Object other) =>
      other is KeycapColors && listEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(ColorProperty('ground', ground))
      ..add(ColorProperty('well', well))
      ..add(DiagnosticsProperty<KeycapCapColors>('alpha', alpha))
      ..add(DiagnosticsProperty<KeycapCapColors>('modifier', modifier))
      ..add(DiagnosticsProperty<KeycapCapColors>('accent', accent))
      ..add(ColorProperty('ink', ink))
      ..add(ColorProperty('focus', focus));
  }
}

// The most chroma an alpha tint ([KeycapColors.from]'s `alpha`) gives the
// alphas: a pale tint, so a strong colour tints them and never paints them.
const double _alphaTint = 12;

// [caps]' plastics in [tones]' hue at their own tones, so the legend on them
// keeps its contrast.
KeycapCapColors _tinted(KeycapCapColors caps, RawNeutralTones tones) {
  Color at(Color c) =>
      tones.tone(RawHct.fromColor(c).tone).withValues(alpha: c.a);
  return caps.copyWith(
    top: at(caps.top),
    wall: at(caps.wall),
    front: at(caps.front),
  );
}

// [base] with its accent key moulded in [accent]: the named colour with
// white or the classic ink on it, whichever reads at 4.5:1 (moved as little
// as it must when neither does); its words, its latched legend by night and
// its focus the nearest tones of its hue that read on [base]'s grounds.
KeycapColors _keyed(KeycapColors base, Color accent) {
  final night = base.brightness == Brightness.dark;
  final grounds = [
    base.ground,
    base.well,
    base.page,
    base.pageSelected,
    base.panel,
  ];
  final accentInk = RawPalette.readableTone(accent, on: grounds);
  final key = RawPalette.accentFill(
    accent,
    brightness: base.brightness,
    rule: RawAccentRule.named,
    darkInk: KeycapColors.light.ink,
  );
  return base.copyWith(
    accent: KeycapCapColors.moulded(
      key.fill,
      legend: key.ink,
      shade: const Color(0xFF000000),
      wallShade: 0.12,
      frontShade: 0.32,
    ),
    // Its words read on every ground they are painted on: the case, a well,
    // a page, a chosen row and a panel.
    accentInk: accentInk,
    // A note's ink stays apart from the key's own words and from the other
    // tones (sage's green key, classic's cobalt, lilac's violet).
    info: _noteInk(accentInk, base, grounds),
    latchedLegend: night
        ? RawPalette.readableTone(accent, on: [base.modifier.top])
        : null,
    focus: RawPalette.readableTone(
      accent,
      on: [base.ground, base.well, base.panel],
      ratio: 3,
    ),
    backlight: accent.withValues(alpha: night ? 0.35 : 0),
  );
}

// Two inks' distance in HCT: their tones and their chromas along their hues,
// as one straight line (ui_core_test's DesignToneCheck reads the same).
double _apart(Color a, Color b) {
  final x = RawHct.fromColor(a);
  final y = RawHct.fromColor(b);
  double along(RawHct h, double Function(double) f) =>
      h.chroma * f(h.hue * math.pi / 180);
  final dt = x.tone - y.tone;
  final da = along(x, math.cos) - along(y, math.cos);
  final db = along(x, math.sin) - along(y, math.sin);
  return math.sqrt(dt * dt + da * da + db * db);
}

// A note's ink (`KeycapTone.info`): the classic's cobalt or the ocean's teal,
// each at the nearest tone that reads on [grounds], whichever stands farther
// from [accentInk] and from [base]'s success, warning (the words' ink) and
// danger.
Color _noteInk(Color accentInk, KeycapColors base, List<Color> grounds) {
  final night = base.brightness == Brightness.dark;
  Color? best;
  var room = -1.0;
  for (final key in [
    (night ? KeycapColors.dark : KeycapColors.light).accentInk,
    const Color(0xFF0E7C86),
  ]) {
    final ink = RawPalette.readableTone(key, on: grounds);
    final least = [
      accentInk,
      base.success,
      base.ink,
      base.dangerInk,
    ].map((other) => _apart(ink, other)).reduce(math.min);
    if (least > room) {
      room = least;
      best = ink;
    }
  }
  return best!;
}

// A colourway of the classic keyboard: its plastics at their own tones in
// the hues of three neutrals (the case's, which its words and lines take
// too; the alphas'; the modifiers', which a chosen row's plate takes), and
// its accent key. A tone of 40 or less holds little chroma, so its night is
// a tinted graphite.
class _Colourway {
  const _Colourway({
    required this.ground,
    required this.alpha,
    required this.modifier,
    required this.key,
  });

  final Color ground;
  final Color alpha;
  final Color modifier;
  final Color key;

  KeycapColors colors(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? KeycapColors.dark
        : KeycapColors.light;
    final ground = RawNeutralTones.of(this.ground);
    final modifier = RawNeutralTones.of(this.modifier);
    Color g(Color c) =>
        ground.tone(RawHct.fromColor(c).tone).withValues(alpha: c.a);
    return _keyed(
      base.copyWith(
        ground: g(base.ground),
        well: g(base.well),
        wellPressed: g(base.wellPressed),
        wellShade: g(base.wellShade),
        wellLip: g(base.wellLip),
        page: g(base.page),
        pagePressed: g(base.pagePressed),
        pageSelected: modifier
            .tone(RawHct.fromColor(base.pageSelected).tone)
            .withValues(alpha: base.pageSelected.a),
        panel: g(base.panel),
        alpha: _tinted(
          base.alpha,
          RawNeutralTones.of(alpha),
        ).copyWith(legend: g(base.alpha.legend)),
        modifier: _tinted(
          base.modifier,
          modifier,
        ).copyWith(legend: g(base.modifier.legend)),
        latchedLegend: g(base.latchedLegend),
        ink: g(base.ink),
        inkMuted: g(base.inkMuted),
        inkDisabled: g(base.inkDisabled),
        hairline: g(base.hairline),
        edge: g(base.edge),
        shadow: g(base.shadow),
        scrim: g(base.scrim),
        toast: g(base.toast),
        onToast: g(base.onToast),
      ),
      key,
    );
  }
}

// Keycap's colourways beside classic (KeycapColors.light and dark).
const Map<String, _Colourway> _colourways = {
  'retro': _Colourway(
    ground: Color(0xFFD8D2C4),
    alpha: Color(0xFFF2EBDA),
    modifier: Color(0xFFA8A296),
    key: Color(0xFFE8892B),
  ),
  'sage': _Colourway(
    ground: Color(0xFFC9D3CB),
    alpha: Color(0xFFE8F0E8),
    modifier: Color(0xFF9AAE9F),
    key: Color(0xFF2F7D57),
  ),
  'rose': _Colourway(
    ground: Color(0xFFD6CBCF),
    alpha: Color(0xFFF5E6EA),
    modifier: Color(0xFFB39AA4),
    key: Color(0xFFC2477A),
  ),
  'lilac': _Colourway(
    ground: Color(0xFFCFCDD9),
    alpha: Color(0xFFECE8F6),
    modifier: Color(0xFFA49DBB),
    key: Color(0xFF6A4FC8),
  ),
  'ocean': _Colourway(
    ground: Color(0xFFC7D3D6),
    alpha: Color(0xFFE6F1F3),
    modifier: Color(0xFF93AAB0),
    key: Color(0xFF0E7C86),
  ),
};

/// Keycap's text styles: four a screen reads in (a [title], the [body], a
/// [secondary] line and a key's [label]), the [legend] printed in capitals
/// over a group, a [display] for the one name or figure a screen leads with,
/// a [heading] for a top bar or a panel, and [figure] for counts that line
/// up.
@immutable
class KeycapTextTheme with Diagnosticable {
  /// Every style given.
  const KeycapTextTheme({
    required this.display,
    required this.title,
    required this.heading,
    required this.body,
    required this.secondary,
    required this.label,
    required this.legend,
    required this.figure,
  });

  /// Keycap's styles in [colors], set in [family] (Rubik by default) from
  /// [package].
  ///
  /// ```dart
  /// final text = KeycapTextTheme.from(KeycapColors.light);
  /// ```
  factory KeycapTextTheme.from(
    KeycapColors colors, {
    String family = keycapFontFamily,
    String? package = keycapFontPackage,
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
    return KeycapTextTheme(
      display: style(28, 34, FontWeight.w600, colors.ink, tracking: -0.3),
      title: style(22, 28, FontWeight.w600, colors.ink, tracking: -0.1),
      heading: style(17, 22, FontWeight.w500, colors.ink),
      body: style(16, 24, FontWeight.w400, colors.ink),
      secondary: style(14, 20, FontWeight.w400, colors.inkMuted),
      label: style(15, 20, FontWeight.w500, colors.ink),
      legend: style(12, 16, FontWeight.w500, colors.inkMuted, tracking: 1),
      figure: style(
        14,
        20,
        FontWeight.w400,
        colors.inkMuted,
      ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
    );
  }

  /// The one name or figure a screen leads with: 28 px.
  final TextStyle display;

  /// A page's title: 22 px.
  final TextStyle title;

  /// A top bar's title, a panel's heading, a row's strongest words: 17 px.
  final TextStyle heading;

  /// What people read: 16 px on 24.
  final TextStyle body;

  /// A supporting line: 14 px, muted.
  final TextStyle secondary;

  /// A key's legend: 15 px medium.
  final TextStyle label;

  /// The capitals printed over a group, tracked: 12 px.
  final TextStyle legend;

  /// Counts, times and dates that line up: 14 px tabular figures.
  final TextStyle figure;

  /// A copy with the given styles replaced.
  KeycapTextTheme copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? heading,
    TextStyle? body,
    TextStyle? secondary,
    TextStyle? label,
    TextStyle? legend,
    TextStyle? figure,
  }) => KeycapTextTheme(
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
  static KeycapTextTheme lerp(KeycapTextTheme a, KeycapTextTheme b, double t) {
    if (identical(a, b)) return a;
    TextStyle s(TextStyle x, TextStyle y) => TextStyle.lerp(x, y, t)!;
    return KeycapTextTheme(
      display: s(a.display, b.display),
      title: s(a.title, b.title),
      heading: s(a.heading, b.heading),
      body: s(a.body, b.body),
      secondary: s(a.secondary, b.secondary),
      label: s(a.label, b.label),
      legend: s(a.legend, b.legend),
      figure: s(a.figure, b.figure),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeycapTextTheme &&
      other.display == display &&
      other.title == title &&
      other.heading == heading &&
      other.body == body &&
      other.secondary == secondary &&
      other.label == label &&
      other.legend == legend &&
      other.figure == figure;

  @override
  int get hashCode => Object.hash(
    display,
    title,
    heading,
    body,
    secondary,
    label,
    legend,
    figure,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle>('title', title))
      ..add(DiagnosticsProperty<TextStyle>('body', body))
      ..add(DiagnosticsProperty<TextStyle>('label', label));
  }
}

/// The look's measures. A cap's walls, its corners and the keyboard's
/// gaps are not settings: they are what Keycap is.
abstract final class KeycapMetrics {
  /// A key's corner.
  static const double keyRadius = 8;

  /// A small key's corner (a checkbox).
  static const double smallKeyRadius = 6;

  /// A field's well: a key's corner, so a field and a key beside it match.
  static const double fieldRadius = 8;

  /// A group's well: an opening cut into the case.
  static const double wellRadius = 12;

  /// A panel of keycap plastic over the keyboard (a dialog, a sheet, a menu).
  static const double panelRadius = 16;

  /// A key's height at [RawDensity.standard], before density.
  static const double controlHeight = 48;

  /// The gap between keys in a row: a keyboard's pitch.
  static const double keyGap = 4;

  /// How thick the plate shows along the top inside edge of a well cut
  /// into it.
  static const double plateDepth = 2;

  /// The width of the backlight round a focused key's foot.
  static const double focusWidth = 2;

  /// The room between a key's foot and its focus backlight.
  static const double focusGap = 1;

  /// The widest a form, a dialog or a reading column stands.
  static const double readingWidth = 640;

  /// A cap [height] tall: how much of each wall shows round its top face at
  /// rest. The sides show a sliver, the back a little less (it leans away),
  /// the front most (the eye looks down at it).
  ///
  /// Each is on a half pixel, so the walls' edges stay crisp.
  ///
  /// ```dart
  /// final walls = KeycapMetrics.walls(48); // (side: 5, back: 3, front: 9)
  /// ```
  static ({double side, double back, double front}) walls(double height) {
    double half(double v) => (v * 2).roundToDouble() / 2;
    return (
      side: half((height * 0.1).clamp(2.5, 5.0)),
      back: half((height * 0.06).clamp(1.5, 3.0)),
      front: half((height * 0.19).clamp(4.0, 9.0)),
    );
  }

  /// A part [height] tall at 1x holding a line of words in [style]: taller
  /// by as much as that line grows once text grows, never shorter than
  /// [height], in whole pixels. A part keeps the room round its words it has at 1x, so large
  /// text never clips.
  ///
  /// ```dart
  /// SizedBox(height: KeycapMetrics.grown(context, 32, theme.textTheme.secondary))
  /// ```
  ///
  /// [scaler], when given, is the one the words are printed with (words
  /// capped at a size of their own), in place of the window's.
  static double grown(
    BuildContext context,
    double height,
    TextStyle style, {
    TextScaler? scaler,
  }) {
    final size = style.fontSize ?? 14;
    final line = style.height ?? 1.2;
    final scaled = (scaler ?? MediaQuery.textScalerOf(context)).scale(size);
    return math.max(height, (height + (scaled - size) * line).ceilToDouble());
  }
}

/// Keycap's spacing, on a 4 px grid ([RawSpacingScope] declares it).
abstract final class KeycapSpacing {
  /// The grid every gap, inset and offset stands on.
  static const double grid = 4;

  /// Half a step: a track's inset round its fill, a ring's off its part.
  static const double hairline = 2;

  /// Inside a control: a glyph and its words; keys in a row.
  static const double tight = 4;

  /// Between a label and its field, between lines of one item.
  static const double small = 8;

  /// Between keys in an action row.
  static const double medium = 12;

  /// A well's inset, and the page margin on a phone.
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

/// Keycap's motion: springs, short and calm. A key goes down onto its switch
/// crisply and comes back up without a bounce; a latch settles a little lower
/// and stays; a panel is laid over the keyboard and lifted off. Run them
/// through `RawMotionPolicy`, which critically damps every spring under
/// Reduce Motion.
abstract final class KeycapMotion {
  /// A key going down onto its switch.
  static const ({double dampingRatio, double stiffness}) press = (
    dampingRatio: 1,
    stiffness: 3000,
  );

  /// A key coming back up.
  static const ({double dampingRatio, double stiffness}) release = (
    dampingRatio: 1,
    stiffness: 1700,
  );

  /// A key latching down, or letting go of a latch; a switch's cap sliding.
  static const ({double dampingRatio, double stiffness}) latch = (
    dampingRatio: 1,
    stiffness: 1300,
  );

  /// A colour changing: a legend, a well's floor, the backlight.
  static const ({double dampingRatio, double stiffness}) colour = (
    dampingRatio: 1,
    stiffness: 1400,
  );

  /// A panel laid over the keyboard (a dialog, a menu, a select's list).
  static const ({double dampingRatio, double stiffness}) panel = (
    dampingRatio: 1,
    stiffness: 800,
  );

  /// A sheet sliding up from the keyboard's front edge.
  static const ({double dampingRatio, double stiffness}) sheet = (
    dampingRatio: 1,
    stiffness: 560,
  );
}

/// Keycap's whole theme: the colourway, the type, the density, the accent's
/// backlight by night, and a style for each part.
///
/// [KeycapThemeData.light] and [KeycapThemeData.dark] are the look's one
/// preset, classic; [KeycapThemeData.from] recolours its accent (and its
/// alphas) for a brand.
///
/// ```dart
/// KeycapTheme(data: KeycapThemeData.light(), child: child)
/// ```
@immutable
class KeycapThemeData with Diagnosticable {
  /// Every setting given.
  KeycapThemeData({
    required this.colors,
    KeycapTextTheme? textTheme,
    RawDensity? density,
    this.backlight = true,
    this.buttonStyle,
    this.modifierButtonStyle,
    this.accentButtonStyle,
    this.textButtonStyle,
    this.iconButtonStyle,
    this.textFieldStyle,
    this.selectStyle,
    this.menuStyle,
    this.toggleStyle,
    this.keyRowStyle,
    this.wellStyle,
    this.listTileStyle,
    this.appBarStyle,
    this.navigationStyle,
    this.dialogStyle,
    this.toastStyle,
    this.linkStyle,
    this.tagStyle,
    this.sliderStyle,
    this.progressStyle,
    this.tooltipStyle,
    this.bannerStyle,
    this.tableStyle,
    this.calendarStyle,
    this.chartStyle,
    this.avatarStyle,
  }) : textTheme = textTheme ?? KeycapTextTheme.from(colors),
       density = density ?? RawDensity.adaptivePlatformDensity;

  /// The classic colourway in daylight.
  factory KeycapThemeData.light({RawDensity? density}) =>
      KeycapThemeData(colors: KeycapColors.light, density: density);

  /// The classic colourway by night.
  factory KeycapThemeData.dark({RawDensity? density}) =>
      KeycapThemeData(colors: KeycapColors.dark, density: density);

  /// [brightness]'s theme: [KeycapThemeData.light] or [KeycapThemeData.dark].
  factory KeycapThemeData.of(Brightness brightness, {RawDensity? density}) =>
      brightness == Brightness.light
      ? KeycapThemeData.light(density: density)
      : KeycapThemeData.dark(density: density);

  /// The look's colourways by name, each by day and by night: `classic`
  /// (the default), `retro`, `sage`, `rose`, `lilac` and `ocean`
  /// ([KeycapColors.preset]).
  static const List<String> presets = [
    'classic',
    'retro',
    'sage',
    'rose',
    'lilac',
    'ocean',
  ];

  /// The six colourways as ui_core's [RawNamedPalette]s, for an app's
  /// palette picker: each one's id is its preset's (one of [presets]), its
  /// swatches its accent key, a modifier and an alpha, by day and by night.
  /// [KeycapThemeData.preset] with the id gives its theme, and `KeycapHost`
  /// takes one as its `palette`.
  ///
  /// ```dart
  /// KeycapThemeData.preset(KeycapThemeData.palettes[2].id, Brightness.dark)
  /// ```
  static final List<RawNamedPalette> palettes = [
    for (final id in presets)
      RawNamedPalette(
        id: id,
        label: '${id[0].toUpperCase()}${id.substring(1)}',
        swatches: _swatches(KeycapColors.preset(id, Brightness.light)),
        darkSwatches: _swatches(KeycapColors.preset(id, Brightness.dark)),
      ),
  ];

  static List<Color> _swatches(KeycapColors c) => [
    c.accent.top,
    c.modifier.top,
    c.alpha.top,
  ];

  /// The colourway [name], one of [presets], for [brightness]
  /// ([KeycapColors.preset]).
  ///
  /// ```dart
  /// KeycapThemeData.preset('sage', Brightness.dark)
  /// ```
  factory KeycapThemeData.preset(
    String name,
    Brightness brightness, {
    RawDensity? density,
  }) {
    assert(
      presets.contains(name),
      'Keycap has no preset $name; it offers ${presets.join(', ')}.',
    );
    return KeycapThemeData(
      colors: KeycapColors.preset(name, brightness),
      density: density,
    );
  }

  /// A brand's Keycap: its accent key in [accent] and its alphas tinted
  /// toward [alpha] ([KeycapColors.from]), set in [fontFamily] when given.
  /// The caps' shape, their walls and the colourway's roles stay the look's.
  ///
  /// ```dart
  /// KeycapThemeData.from(brightness: Brightness.light, accent: const Color(0xFF16807A))
  /// ```
  factory KeycapThemeData.from({
    required Brightness brightness,
    Color? accent,
    Color? alpha,
    String? fontFamily,
    String? fontPackage,
    RawDensity? density,
  }) {
    final colors = KeycapColors.from(
      brightness: brightness,
      accent: accent,
      alpha: alpha,
    );
    return KeycapThemeData(
      colors: colors,
      textTheme: fontFamily == null
          ? null
          : KeycapTextTheme.from(
              colors,
              family: fontFamily,
              package: fontPackage,
            ),
      density: density,
    );
  }

  /// The colourway.
  final KeycapColors colors;

  /// The text styles.
  final KeycapTextTheme textTheme;

  /// How tight the controls stand.
  final RawDensity density;

  /// Whether the accent key's backlight shows round its foot by night. Off
  /// under the platform's high contrast whatever this says.
  final bool backlight;

  /// [KeycapButton]: an alpha key.
  final KeycapStyle? buttonStyle;

  /// [KeycapButton.modifier]: a modifier key.
  final KeycapStyle? modifierButtonStyle;

  /// [KeycapButton.accent]: the accent key.
  final KeycapStyle? accentButtonStyle;

  /// [KeycapButton.text]: a legend printed on the case, with no cap.
  final KeycapStyle? textButtonStyle;

  /// [KeycapIconButton].
  final KeycapStyle? iconButtonStyle;

  /// [KeycapTextField]'s well.
  final KeycapStyle? textFieldStyle;

  /// [KeycapSelect]'s key.
  final KeycapStyle? selectStyle;

  /// Every open list: a select's, a menu's.
  final KeycapStyle? menuStyle;

  /// [KeycapCheckbox], [KeycapRadio] and [KeycapSwitch].
  final KeycapStyle? toggleStyle;

  /// [KeycapSegmentedButton] and [KeycapTabBar]: a row of keys.
  final KeycapStyle? keyRowStyle;

  /// [KeycapWell], [KeycapListGroup] and [KeycapCard].
  final KeycapStyle? wellStyle;

  /// [KeycapListTile].
  final KeycapStyle? listTileStyle;

  /// [KeycapAppBar].
  final KeycapStyle? appBarStyle;

  /// The navigation: [KeycapNavigationBar], [KeycapNavigationRail],
  /// [KeycapSideNavigation].
  final KeycapStyle? navigationStyle;

  /// [KeycapDialog] and [KeycapSheet]: a panel over the keyboard.
  final KeycapStyle? dialogStyle;

  /// A toast's panel.
  final KeycapStyle? toastStyle;

  /// `KeycapLink`: words that go somewhere.
  final KeycapStyle? linkStyle;

  /// `KeycapChip`, `KeycapTag`, `KeycapBadge` and `KeycapKbd`: small caps
  /// and printed labels.
  final KeycapStyle? tagStyle;

  /// `KeycapSlider`, `KeycapRangeSlider` and `KeycapRating`.
  final KeycapStyle? sliderStyle;

  /// `KeycapProgressBar`, `KeycapSpinner`, `KeycapMeter` and
  /// `KeycapSkeleton`.
  final KeycapStyle? progressStyle;

  /// `KeycapTooltip`, `KeycapPopover` and `KeycapHoverCard`: small panels
  /// over the keyboard.
  final KeycapStyle? tooltipStyle;

  /// `KeycapBanner` and `KeycapStatusView`.
  final KeycapStyle? bannerStyle;

  /// `KeycapTable`, `KeycapDataTable` and `KeycapDescriptionList`.
  final KeycapStyle? tableStyle;

  /// `KeycapCalendar` and the date and time pickers.
  final KeycapStyle? calendarStyle;

  /// The charts: `KeycapLineChart` and the rest.
  final KeycapStyle? chartStyle;

  /// `KeycapAvatar` and `KeycapAvatarGroup`.
  final KeycapStyle? avatarStyle;

  /// Day or night.
  Brightness get brightness => colors.brightness;

  /// A key's height at this density.
  double get controlHeight => KeycapMetrics.controlHeight + density.heightDelta;

  /// The typeface's cap height as a fraction of its size.
  double get capHeightFactor => keycapCapHeightFactor;

  /// A page's first heading, as generated pages name it: the
  /// [KeycapTextTheme.title] style.
  TextStyle get h1 => textTheme.title;

  /// Running copy, as generated pages name it: the [KeycapTextTheme.body]
  /// style.
  TextStyle get body => textTheme.body;

  /// A copy with the given settings replaced.
  KeycapThemeData copyWith({
    KeycapColors? colors,
    KeycapTextTheme? textTheme,
    RawDensity? density,
    bool? backlight,
    KeycapStyle? buttonStyle,
    KeycapStyle? modifierButtonStyle,
    KeycapStyle? accentButtonStyle,
    KeycapStyle? textButtonStyle,
    KeycapStyle? iconButtonStyle,
    KeycapStyle? textFieldStyle,
    KeycapStyle? selectStyle,
    KeycapStyle? menuStyle,
    KeycapStyle? toggleStyle,
    KeycapStyle? keyRowStyle,
    KeycapStyle? wellStyle,
    KeycapStyle? listTileStyle,
    KeycapStyle? appBarStyle,
    KeycapStyle? navigationStyle,
    KeycapStyle? dialogStyle,
    KeycapStyle? toastStyle,
    KeycapStyle? linkStyle,
    KeycapStyle? tagStyle,
    KeycapStyle? sliderStyle,
    KeycapStyle? progressStyle,
    KeycapStyle? tooltipStyle,
    KeycapStyle? bannerStyle,
    KeycapStyle? tableStyle,
    KeycapStyle? calendarStyle,
    KeycapStyle? chartStyle,
    KeycapStyle? avatarStyle,
  }) => KeycapThemeData(
    colors: colors ?? this.colors,
    textTheme:
        textTheme ??
        (colors == null ? this.textTheme : KeycapTextTheme.from(colors)),
    density: density ?? this.density,
    backlight: backlight ?? this.backlight,
    buttonStyle: buttonStyle ?? this.buttonStyle,
    modifierButtonStyle: modifierButtonStyle ?? this.modifierButtonStyle,
    accentButtonStyle: accentButtonStyle ?? this.accentButtonStyle,
    textButtonStyle: textButtonStyle ?? this.textButtonStyle,
    iconButtonStyle: iconButtonStyle ?? this.iconButtonStyle,
    textFieldStyle: textFieldStyle ?? this.textFieldStyle,
    selectStyle: selectStyle ?? this.selectStyle,
    menuStyle: menuStyle ?? this.menuStyle,
    toggleStyle: toggleStyle ?? this.toggleStyle,
    keyRowStyle: keyRowStyle ?? this.keyRowStyle,
    wellStyle: wellStyle ?? this.wellStyle,
    listTileStyle: listTileStyle ?? this.listTileStyle,
    appBarStyle: appBarStyle ?? this.appBarStyle,
    navigationStyle: navigationStyle ?? this.navigationStyle,
    dialogStyle: dialogStyle ?? this.dialogStyle,
    toastStyle: toastStyle ?? this.toastStyle,
    linkStyle: linkStyle ?? this.linkStyle,
    tagStyle: tagStyle ?? this.tagStyle,
    sliderStyle: sliderStyle ?? this.sliderStyle,
    progressStyle: progressStyle ?? this.progressStyle,
    tooltipStyle: tooltipStyle ?? this.tooltipStyle,
    bannerStyle: bannerStyle ?? this.bannerStyle,
    tableStyle: tableStyle ?? this.tableStyle,
    calendarStyle: calendarStyle ?? this.calendarStyle,
    chartStyle: chartStyle ?? this.chartStyle,
    avatarStyle: avatarStyle ?? this.avatarStyle,
  );

  List<KeycapStyle?> get _styles => [
    buttonStyle,
    modifierButtonStyle,
    accentButtonStyle,
    textButtonStyle,
    iconButtonStyle,
    textFieldStyle,
    selectStyle,
    menuStyle,
    toggleStyle,
    keyRowStyle,
    wellStyle,
    listTileStyle,
    appBarStyle,
    navigationStyle,
    dialogStyle,
    toastStyle,
    linkStyle,
    tagStyle,
    sliderStyle,
    progressStyle,
    tooltipStyle,
    bannerStyle,
    tableStyle,
    calendarStyle,
    chartStyle,
    avatarStyle,
  ];

  /// Between [a] and [b] by [t], as `ThemeData.lerp`.
  static KeycapThemeData lerp(KeycapThemeData a, KeycapThemeData b, double t) {
    if (identical(a, b)) return a;
    final x = a._styles;
    final y = b._styles;
    KeycapStyle? at(int i) => RawStyle.lerp(x[i], y[i], t);
    return KeycapThemeData(
      colors: KeycapColors.lerp(a.colors, b.colors, t),
      textTheme: KeycapTextTheme.lerp(a.textTheme, b.textTheme, t),
      density: RawDensity.lerp(a.density, b.density, t),
      backlight: t < 0.5 ? a.backlight : b.backlight,
      buttonStyle: at(0),
      modifierButtonStyle: at(1),
      accentButtonStyle: at(2),
      textButtonStyle: at(3),
      iconButtonStyle: at(4),
      textFieldStyle: at(5),
      selectStyle: at(6),
      menuStyle: at(7),
      toggleStyle: at(8),
      keyRowStyle: at(9),
      wellStyle: at(10),
      listTileStyle: at(11),
      appBarStyle: at(12),
      navigationStyle: at(13),
      dialogStyle: at(14),
      toastStyle: at(15),
      linkStyle: at(16),
      tagStyle: at(17),
      sliderStyle: at(18),
      progressStyle: at(19),
      tooltipStyle: at(20),
      bannerStyle: at(21),
      tableStyle: at(22),
      calendarStyle: at(23),
      chartStyle: at(24),
      avatarStyle: at(25),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is KeycapThemeData &&
      other.colors == colors &&
      other.textTheme == textTheme &&
      other.density == density &&
      other.backlight == backlight &&
      listEquals(other._styles, _styles);

  @override
  int get hashCode => Object.hash(
    colors,
    textTheme,
    density,
    backlight,
    Object.hashAll(_styles),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<KeycapColors>('colors', colors))
      ..add(DiagnosticsProperty<KeycapTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<RawDensity>('density', density))
      ..add(
        FlagProperty('backlight', value: backlight, ifFalse: 'no backlight'),
      );
  }
}

/// Keycap for [child]: the one widget an app installs, in its `builder:`
/// (`MaterialApp(builder: (context, child) => KeycapTheme(data: ..., child: child!))`).
///
/// It sets the words, the glyphs and the text selection in the look's ink,
/// declares the look's 4 px grid ([RawSpacingScope]) and its tap floors
/// ([tapTargets]), and lays a Material theme under the look (its density
/// pinned, its ink off, its page change Keycap's) so the Material parts it
/// draws with never show.
///
/// ```dart
/// KeycapTheme(data: KeycapThemeData.dark(), child: const NotesHome())
/// ```
class KeycapTheme extends StatelessWidget {
  /// Keycap in [data] for [child].
  const KeycapTheme({super.key, required this.data, required this.child});

  /// The theme.
  final KeycapThemeData data;

  /// What wears it.
  final Widget child;

  /// Keycap's tap floors: 40 by 40 for a finger, 24 by 24 for a pointer, as
  /// ui_core's defaults.
  static const RawTapTargets tapTargets = RawTapTargets.fallback;

  static final KeycapThemeData _fallback = KeycapThemeData.light();

  /// The theme above [context], or the look by day when there is none, as
  /// `Theme.of` falls back to its default.
  static KeycapThemeData of(BuildContext context) =>
      maybeOf(context) ?? _fallback;

  /// The theme above [context], or null.
  static KeycapThemeData? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_InheritedKeycapTheme>()
      ?.theme
      .data;

  @override
  Widget build(BuildContext context) {
    final colors = data.colors;
    final bridge = _bridges[data] ??= _materialUnder(data);
    // Over the app's navigator, the routes change pages by this theme:
    // Keycap's, unless the app's own theme chose another.
    final outer = Theme.of(context).pageTransitionsTheme;
    final material =
        outer == const PageTransitionsTheme() ||
            outer == bridge.pageTransitionsTheme
        ? bridge
        : bridge.copyWith(pageTransitionsTheme: outer);
    Widget under = _InheritedKeycapTheme(
      theme: this,
      child: Theme(
        data: material,
        child: RawSpacingScope(
          spacing: RawSpacing.fallback,
          child: RawTapTargetScope(
            targets: tapTargets,
            child: DefaultSelectionStyle(
              cursorColor: colors.accent.top,
              selectionColor: colors.accent.top.withValues(alpha: 0.28),
              child: IconTheme(
                data: IconThemeData(color: colors.ink, size: 20),
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

  static final Expando<ThemeData> _bridges = Expando('KeycapTheme bridges');

  static ThemeData _materialUnder(KeycapThemeData data) {
    final colors = data.colors;
    return ThemeData(
      brightness: colors.brightness,
      fontFamily: data.textTheme.body.fontFamily,
      useMaterial3: true,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: keycapPageTransitions,
      ),
      visualDensity: VisualDensity.standard,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      splashColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      scaffoldBackgroundColor: colors.ground,
      canvasColor: colors.panel,
      colorScheme: ColorScheme.fromSeed(
        seedColor: colors.accent.top,
        brightness: colors.brightness,
        primary: colors.accent.top,
        onPrimary: colors.accent.legend,
        surface: colors.panel,
        onSurface: colors.ink,
        error: colors.dangerInk,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: colors.accent.top,
        selectionColor: colors.accent.top.withValues(alpha: 0.28),
        selectionHandleColor: colors.accent.top,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<KeycapThemeData>('data', data));
  }
}

class _InheritedKeycapTheme extends InheritedTheme {
  const _InheritedKeycapTheme({required this.theme, required super.child});

  final KeycapTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      KeycapTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_InheritedKeycapTheme old) =>
      theme.data != old.theme.data;
}

/// [KeycapTheme] that moves to a new [data] as the room's light changes (day
/// to night) on a calm spring; at once under Reduce Motion.
///
/// ```dart
/// AnimatedKeycapTheme(data: night ? KeycapThemeData.dark() : KeycapThemeData.light(), child: page)
/// ```
class AnimatedKeycapTheme extends StatefulWidget {
  /// Moves to [data] whenever it changes.
  const AnimatedKeycapTheme({
    super.key,
    required this.data,
    required this.child,
  });

  /// The theme to arrive at.
  final KeycapThemeData data;

  /// What wears it.
  final Widget child;

  @override
  State<AnimatedKeycapTheme> createState() => _AnimatedKeycapThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<KeycapThemeData>('data', data));
  }
}

class _AnimatedKeycapThemeState extends State<AnimatedKeycapTheme>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = 1;
  late KeycapThemeData _from = widget.data;
  late KeycapThemeData _to = widget.data;

  @override
  void didUpdateWidget(AnimatedKeycapTheme old) {
    super.didUpdateWidget(old);
    if (widget.data == _to) return;
    _from = KeycapThemeData.lerp(_from, _to, _t.value);
    _to = widget.data;
    if (rawReduceMotionOf(context)) {
      _t.value = 1;
      return;
    }
    _t
      ..value = 0
      ..springTo(
        1,
        rawSpring(
          dampingRatio: 1,
          stiffness: KeycapMotion.colour.stiffness / 4,
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
    builder: (context, child) => KeycapTheme(
      data: _t.value >= 1 ? _to : KeycapThemeData.lerp(_from, _to, _t.value),
      child: child!,
    ),
    child: widget.child,
  );
}

/// Reads Keycap's theme from a [BuildContext].
extension KeycapThemeContext on BuildContext {
  /// [KeycapTheme.of] this context.
  KeycapThemeData get keycapTheme => KeycapTheme.of(this);
}

// The words of the Material and Cupertino libraries Keycap is built on,
// which KeycapTheme gives its parts when the app gives none: English.
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
