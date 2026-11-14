import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import 'chrome_metrics.dart';
import 'component_themes.dart';
import 'components/pressable.dart' show MinimalHitTarget;
import 'internal/lucide_cut.g.dart';
import 'knobs.dart';
import 'shapes.dart';

/// Design tokens and theme assembly — the only styling vocabulary a
/// Minimal screen uses.
///
/// Fixed scales (spacing, radius, icon size, motion) are compile-time consts.
/// Theme-dependent tokens (colour, type, the corner scale, the row and
/// hairline geometry) live on [MinimalThemeData], a value an app installs
/// once with a [MinimalTheme] in its `builder:` and every widget reads via
/// `context.minimalTheme`. Screens never write raw numbers, hex colours or
/// TextStyles — everything routes through this file's names. A theme comes
/// from a preset ([MinimalThemeData.preset]) or an app's own colours
/// ([MinimalThemeData.from]), and [MinimalThemeData.copyWith] moves it
/// toward a brand.
///
/// Material's `ThemeData` is not the token carrier: [MinimalTheme] installs
/// a thin one for the platform primitives beneath it (a text field's caret
/// and selection, a divider, a scaffold's ground), and no Minimal component
/// reads it for a token.

/// 4pt spacing scale.
abstract final class MinimalSpacing {
  /// 2 px: a hairline's air, a badge's offset.
  static const double s2 = 2;

  /// 4 px: between a label and its help line.
  static const double s4 = 4;

  /// 8 px: between related parts of a row.
  static const double s8 = 8;

  /// 12 px: a card's tight padding, between stacked controls.
  static const double s12 = 12;

  /// 16 px: a card's padding, between rows of a form.
  static const double s16 = 16;

  /// 20 px.
  static const double s20 = 20;

  /// 24 px: between sections of a page.
  static const double s24 = 24;

  /// 32 px.
  static const double s32 = 32;

  /// 40 px: room below a page's last row.
  static const double s40 = 40;

  /// 48 px.
  static const double s48 = 48;

  /// 64 px: an empty state's air.
  static const double s64 = 64;
}

/// Corner radii for component identity (true circles and pills). The
/// theme's corner language (card/control/small/sheet) lives on
/// [MinimalThemeData].
abstract final class MinimalCorners {
  /// 4 px.
  static const double r4 = 4;

  /// 8 px.
  static const double r8 = 8;

  /// 12 px.
  static const double r12 = 12;

  /// 16 px.
  static const double r16 = 16;

  /// 24 px.
  static const double r24 = 24;

  /// Fully round: a pill's or a circle's ends.
  static const double rFull = 999;
}

/// Icon sizes. [i18] is Minimal's own default glyph; [i14] is the glyph a
/// 28 px pill or a small button carries.
abstract final class MinimalIconSize {
  /// 14 px: a 28 px pill's or a small button's glyph.
  static const double i14 = 14;

  /// 16 px: a button's or a field's glyph.
  static const double i16 = 16;

  /// 18 px: Minimal's default glyph, a row's.
  static const double i18 = 18;

  /// 20 px: a tab's glyph.
  static const double i20 = 20;

  /// 24 px: a feature glyph.
  static const double i24 = 24;

  /// 32 px: an empty state's glyph.
  static const double i32 = 32;
}

/// Motion durations and curves. Minimal motion is instant: fades finish
/// inside [base], nothing bounces and nothing scales.
abstract final class MinimalMotion {
  /// A press, a check: 90 ms.
  static const Duration fast = Duration(milliseconds: 90);

  /// A fade or a change of state: 120 ms.
  static const Duration base = Duration(milliseconds: 120);

  /// An entrance, a slide between pages: 160 ms.
  static const Duration slow = Duration(milliseconds: 160);

  /// Minimal's one curve: a decelerate, no overshoot.
  static const Curve out = Curves.easeOutCubic;

  /// Cody's spring register, kept by name so code transfers: Minimal has
  /// no overshoot, so it is the same decelerate as [out].
  static const Curve spring = Curves.easeOutCubic;

  /// Kill-switch for continuous or repeating animation. Golden and
  /// walkthrough tests set this false so frames are deterministic and
  /// pumpAndSettle terminates; any widget that starts a repeating
  /// AnimationController must check it. One-shot feedback ignores it, and
  /// the route transitions collapse to nothing. Never set in app code.
  static bool animate = true;
}

/// EdgeInsets shortcuts on the spacing scale.
abstract final class MinimalInsets {
  /// 4 px on every side.
  static const EdgeInsets all4 = EdgeInsets.all(MinimalSpacing.s4);

  /// 8 px on every side.
  static const EdgeInsets all8 = EdgeInsets.all(MinimalSpacing.s8);

  /// 12 px on every side.
  static const EdgeInsets all12 = EdgeInsets.all(MinimalSpacing.s12);

  /// 16 px on every side.
  static const EdgeInsets all16 = EdgeInsets.all(MinimalSpacing.s16);

  /// 20 px on every side.
  static const EdgeInsets all20 = EdgeInsets.all(MinimalSpacing.s20);

  /// 24 px on every side.
  static const EdgeInsets all24 = EdgeInsets.all(MinimalSpacing.s24);

  /// 8 px at the sides.
  static const EdgeInsets horizontal8 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s8,
  );

  /// 12 px at the sides.
  static const EdgeInsets horizontal12 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s12,
  );

  /// 16 px at the sides.
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s16,
  );

  /// 20 px at the sides.
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s20,
  );

  /// 24 px at the sides.
  static const EdgeInsets horizontal24 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s24,
  );

  /// 8 px above and below.
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(
    vertical: MinimalSpacing.s8,
  );

  /// 12 px above and below.
  static const EdgeInsets vertical12 = EdgeInsets.symmetric(
    vertical: MinimalSpacing.s12,
  );

  /// 16 px above and below.
  static const EdgeInsets vertical16 = EdgeInsets.symmetric(
    vertical: MinimalSpacing.s16,
  );

  /// 12 px at the sides, 8 above and below.
  static const EdgeInsets horizontal12Vertical8 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s12,
    vertical: MinimalSpacing.s8,
  );

  /// 16 px at the sides, 8 above and below.
  static const EdgeInsets horizontal16Vertical8 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s16,
    vertical: MinimalSpacing.s8,
  );

  /// 16 px at the sides, 12 above and below.
  static const EdgeInsets horizontal16Vertical12 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s16,
    vertical: MinimalSpacing.s12,
  );

  /// 20 px at the sides, 16 above and below.
  static const EdgeInsets horizontal20Vertical16 = EdgeInsets.symmetric(
    horizontal: MinimalSpacing.s20,
    vertical: MinimalSpacing.s16,
  );

  /// The screen gutter alone, for a full-bleed list whose rows run edge to
  /// edge but whose type keeps the page's measure.
  static const EdgeInsets gutter = EdgeInsets.symmetric(
    horizontal: MinimalChromeMetrics.gutter,
  );

  /// Default screen body padding: the gutter at the sides, a row's breath at
  /// the top, room for overshoot at the bottom.
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    MinimalChromeMetrics.gutter,
    MinimalSpacing.s16,
    MinimalChromeMetrics.gutter,
    MinimalSpacing.s40,
  );
}

/// Square gap for Rows and Columns: `MinimalGap(MinimalSpacing.s16)`.
class MinimalGap extends StatelessWidget {
  /// A [size] square of space.
  const MinimalGap(this.size, {super.key});

  /// Its width and height: one of [MinimalSpacing]'s steps.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Minimal's glyph: an icon drawn at the theme's stroke, in the quiet ink
/// unless told otherwise. Every Minimal component draws its icons through
/// it, and a page should too.
///
/// Lucide ships its stroke as one font family per weight (`Lucide100` …
/// `Lucide600`, the same codepoints in each), so a Lucide glyph is re-cut
/// onto the 300 family while [MinimalThemeData.iconStroke] is nearer its stroke
/// than the face's own (every preset's is). Any other [IconData] draws
/// exactly as given.
///
/// ```dart
/// MinimalIcon(LucideIcons.bell, color: t.foreground)
/// ```
class MinimalIcon extends StatelessWidget {
  /// Draws [icon] at [size].
  const MinimalIcon(
    this.icon, {
    super.key,
    this.size = MinimalIconSize.i18,
    this.color,
    this.semanticLabel,
  });

  /// The glyph.
  final IconData icon;

  /// Its size; [MinimalIconSize.i18] unless given.
  final double size;

  /// Null takes [MinimalThemeData.mutedForeground], the glyph ink of a Minimal
  /// row.
  final Color? color;

  /// What a screen reader says for it; null for a glyph beside words that say
  /// it.
  final String? semanticLabel;

  static const String _lucidePackage = 'lucide_icons_flutter';

  /// The stroke Lucide's 300 cut draws, and the one its own face draws, in
  /// the 24-unit grid.
  static const double _cutStroke = 1.55;
  static const double _faceStroke = 2.0;

  /// [icon] on Lucide's 300 cut when [stroke] is nearer that cut's stroke
  /// than the face's own (every preset's 1.75 is), else [icon] itself; a
  /// glyph that is not Lucide's comes back untouched.
  ///
  /// The cut is a lookup in `internal/lucide_cut.g.dart` (generated from
  /// lucide_icons_flutter), never an [IconData] made here: a release
  /// build tree-shakes icon fonts only when every [IconData] in the app is
  /// const, and refuses one made at run time.
  static IconData stroked(IconData icon, double stroke) {
    if (icon.fontPackage != _lucidePackage ||
        (stroke - _cutStroke).abs() >= (stroke - _faceStroke).abs()) {
      return icon;
    }
    final cuts = icon.matchTextDirection
        ? minimalLucideCutMirrored
        : minimalLucideCut;
    return cuts[icon.codePoint] ?? icon;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Icon(
      stroked(icon, t.iconStroke),
      size: size,
      color: color ?? t.mutedForeground,
      semanticLabel: semanticLabel,
    );
  }
}

/// Responsive layout invariants shared by Minimal apps.
abstract final class MinimalLayout {
  /// Below this width the layout is a phone's: one column, a tab bar.
  static const double compact = 600;

  /// From this width the layout is a desktop's: a rail, the widest measure.
  static const double expanded = 960;

  /// The touch-target floor. [MinimalPressable] pads every 28–32 px control's
  /// hit area out to it without changing what it paints.
  static const double minHitTarget = 44;

  /// Whether the screen is narrower than [compact].
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  /// The measure a page's content keeps at this screen's width: 840 px from
  /// [expanded], 680 from [compact], the whole width below.
  static double contentWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= expanded) return 840;
    if (width >= compact) return 680;
    return width;
  }

  /// The widest a control that fills its column grows from [compact] up (an
  /// expanded button, a segmented control, a select): on a phone it spans the screen,
  /// on a tablet or a laptop it stops here, on its start.
  static const double controlMax = 320;

  /// [child] (a control that fills its column) held to [controlMax] on its
  /// start from [compact] up; itself below.
  static Widget capControl(BuildContext context, Widget child) =>
      isCompact(context)
      ? child
      : Align(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: controlMax),
            child: child,
          ),
        );

  /// [child] (a control that keeps the width of what it shows: a button
  /// that does not expand) at that width on its start from [compact] up,
  /// whatever stretches it (a column's stretch); itself below, where a
  /// phone's column may stretch it.
  /// The hold passes the control's 44 px target on (a box rejects a tap
  /// outside its own size before its child sees it).
  static Widget holdWidth(BuildContext context, Widget child) =>
      isCompact(context)
      ? child
      : MinimalHitTarget(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: 1,
            heightFactor: 1,
            child: child,
          ),
        );

  /// The measure a form or a settings page keeps: 640 px from [compact], the
  /// whole width below. Narrower than [contentWidth]: each row pairs a label
  /// with its control at the far end, and past this the eye loses the pair
  /// (a switch 780 px from its label on a laptop).
  static double formWidth(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= compact ? 640 : width;
  }
}

/// Minimal's colour roles in one appearance, as Material's `ColorScheme`:
/// the grounds, the hairlines, the inks, the one accent and the three
/// status tones. Every role is materialised — components read values, they
/// never derive them. `MinimalThemeData.preset` and `MinimalThemeData.from`
/// build them with every contrast bar held; [copyWith] changes roles as
/// given and checks nothing.
///
/// ```dart
/// final t = MinimalThemeData.standard();
/// final quieter = t.copyWith(
///   colors: t.colors.copyWith(border: const Color(0xFFF0F0F2)),
/// );
/// ```
@immutable
class MinimalColors with Diagnosticable {
  /// Every role, as given.
  const MinimalColors({
    required this.brightness,
    required this.background,
    required this.card,
    required this.muted,
    required this.sunken,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.input,
    required this.foreground,
    required this.mutedForeground,
    required this.textTertiary,
    required this.textInverse,
    required this.primary,
    required this.primaryForeground,
    required this.primarySubtle,
    required this.primaryInk,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.successInk,
    required this.warning,
    required this.warningSubtle,
    required this.warningInk,
    required this.destructive,
    required this.destructiveForeground,
    required this.destructiveSubtle,
    required this.destructiveInk,
    required this.info,
    required this.overlay,
    required this.ring,
    required this.selection,
  });

  /// Which appearance these colours are for.
  final Brightness brightness;

  /// The page ground.
  final Color background;

  /// Cards, sheets, menus and docked bars.
  final Color card;

  /// The quiet fill: table headers, the selected filter, a set pill.
  final Color muted;

  /// A well BELOW the ground: code blocks, an inset input, an empty track.
  final Color sunken;

  /// The ink as a ground: a snack bar, a tooltip, an inverted badge.
  final Color surfaceInverse;

  /// The hairline every row, bar and container draws.
  final Color border;

  /// A firmer hairline: a hovered field's rim, a divider that must hold.
  final Color borderStrong;

  /// The edge that makes an idle control findable: an unchecked box, a
  /// switch's off track. Unlike the hairlines it clears 3:1 against the
  /// ground, the surface and the quiet fill in every preset, so an empty
  /// checkbox never reads as a missing one.
  final Color input;

  /// The ink every title and value prints in.
  final Color foreground;

  /// The quiet ink: a row's meta, a caption, an idle glyph. Clears AA on
  /// the ground.
  final Color mutedForeground;

  /// The faintest ink: a placeholder, a disabled label.
  final Color textTertiary;

  /// Ink on [surfaceInverse].
  final Color textInverse;

  /// The one colour spent on the thing to act on.
  final Color primary;

  /// Text and glyphs on a [primary] fill, at AA contrast for a 13 px label.
  final Color primaryForeground;

  /// The accent's quiet fill: a selected row, an accent tag.
  final Color primarySubtle;

  /// The accent as TEXT or a thin glyph (a link, an accent tag, a
  /// selection check): [primary] itself wherever it clears AA on the ground
  /// and on [primarySubtle], a deeper cut where it does not (ember's orange).
  /// [primary] stays the fill — the primary button, a toggle's track, a bar.
  final Color primaryInk;

  /// A status colour splits in two: the fill ([success], [warning],
  /// [destructive]) for dots, bars, heatmap cells and filled glyphs, and the ink
  /// ([successInk], ...) for words and thin strokes, which clears AA on the
  /// ground and on the tone's subtle fill in every preset.
  final Color success;

  /// Text on a [success] fill: the ink in light, where white on the green
  /// fails AA, and the dark ground in dark.
  final Color onSuccess;

  /// The success tone's quiet fill.
  final Color successSubtle;

  /// [success] as text: `Paid`, `+12%`, a kept count.
  final Color successInk;

  /// The warning tone's fill: a late dot, an in-progress ring.
  final Color warning;

  /// The warning tone's quiet fill.
  final Color warningSubtle;

  /// [warning] as text or a thin glyph: `Late`, a due time, the
  /// in-progress ring.
  final Color warningInk;

  /// The danger tone's fill: the destructive button, an error dot.
  final Color destructive;

  /// Text on a [destructive] fill (the destructive button's label).
  final Color destructiveForeground;

  /// The danger tone's quiet fill.
  final Color destructiveSubtle;

  /// [destructive] as text: an error line, a `Bug` label, a negative delta.
  final Color destructiveInk;

  /// An informational note or highlight an app wants to name for the job
  /// (a hint, a "new" marker): the accent's INK, so a word in it clears AA
  /// on the ground in every preset (ember's orange fill would not). It is
  /// an app-level role — no Minimal component reads it; a status speaks in
  /// its own tone (work in progress is [warning]).
  final Color info;

  /// The scrim under a sheet or a dialog.
  final Color overlay;

  /// The keyboard focus ring every focusable control draws.
  final Color ring;

  /// A highlighted row: selected, or the current match.
  final Color selection;

  List<Color> get _roles => [
    background,
    card,
    muted,
    sunken,
    surfaceInverse,
    border,
    borderStrong,
    input,
    foreground,
    mutedForeground,
    textTertiary,
    textInverse,
    primary,
    primaryForeground,
    primarySubtle,
    primaryInk,
    success,
    onSuccess,
    successSubtle,
    successInk,
    warning,
    warningSubtle,
    warningInk,
    destructive,
    destructiveForeground,
    destructiveSubtle,
    destructiveInk,
    info,
    overlay,
    ring,
    selection,
  ];

  static const List<String> _names = [
    'background',
    'surface',
    'surfaceAlt',
    'sunken',
    'surfaceInverse',
    'border',
    'borderStrong',
    'controlBorder',
    'textPrimary',
    'textSecondary',
    'textTertiary',
    'textInverse',
    'accent',
    'onAccent',
    'accentSubtle',
    'accentInk',
    'success',
    'onSuccess',
    'successSubtle',
    'successInk',
    'warning',
    'warningSubtle',
    'warningInk',
    'danger',
    'onDanger',
    'dangerSubtle',
    'dangerInk',
    'info',
    'overlay',
    'focusRing',
    'selection',
  ];

  static MinimalColors _fromRoles(Brightness brightness, List<Color> r) =>
      MinimalColors(
        brightness: brightness,
        background: r[0],
        card: r[1],
        muted: r[2],
        sunken: r[3],
        surfaceInverse: r[4],
        border: r[5],
        borderStrong: r[6],
        input: r[7],
        foreground: r[8],
        mutedForeground: r[9],
        textTertiary: r[10],
        textInverse: r[11],
        primary: r[12],
        primaryForeground: r[13],
        primarySubtle: r[14],
        primaryInk: r[15],
        success: r[16],
        onSuccess: r[17],
        successSubtle: r[18],
        successInk: r[19],
        warning: r[20],
        warningSubtle: r[21],
        warningInk: r[22],
        destructive: r[23],
        destructiveForeground: r[24],
        destructiveSubtle: r[25],
        destructiveInk: r[26],
        info: r[27],
        overlay: r[28],
        ring: r[29],
        selection: r[30],
      );

  /// These colours with the named roles changed.
  MinimalColors copyWith({
    Brightness? brightness,
    Color? background,
    Color? card,
    Color? muted,
    Color? sunken,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? input,
    Color? foreground,
    Color? mutedForeground,
    Color? textTertiary,
    Color? textInverse,
    Color? primary,
    Color? primaryForeground,
    Color? primarySubtle,
    Color? primaryInk,
    Color? success,
    Color? onSuccess,
    Color? successSubtle,
    Color? successInk,
    Color? warning,
    Color? warningSubtle,
    Color? warningInk,
    Color? destructive,
    Color? destructiveForeground,
    Color? destructiveSubtle,
    Color? destructiveInk,
    Color? info,
    Color? overlay,
    Color? ring,
    Color? selection,
  }) => MinimalColors(
    brightness: brightness ?? this.brightness,
    background: background ?? this.background,
    card: card ?? this.card,
    muted: muted ?? this.muted,
    sunken: sunken ?? this.sunken,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    input: input ?? this.input,
    foreground: foreground ?? this.foreground,
    mutedForeground: mutedForeground ?? this.mutedForeground,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    primary: primary ?? this.primary,
    primaryForeground: primaryForeground ?? this.primaryForeground,
    primarySubtle: primarySubtle ?? this.primarySubtle,
    primaryInk: primaryInk ?? this.primaryInk,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successSubtle: successSubtle ?? this.successSubtle,
    successInk: successInk ?? this.successInk,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    warningInk: warningInk ?? this.warningInk,
    destructive: destructive ?? this.destructive,
    destructiveForeground: destructiveForeground ?? this.destructiveForeground,
    destructiveSubtle: destructiveSubtle ?? this.destructiveSubtle,
    destructiveInk: destructiveInk ?? this.destructiveInk,
    info: info ?? this.info,
    overlay: overlay ?? this.overlay,
    ring: ring ?? this.ring,
    selection: selection ?? this.selection,
  );

  /// Between [a] and [b], role by role; the appearance flips at the middle.
  static MinimalColors lerp(MinimalColors a, MinimalColors b, double t) {
    if (identical(a, b)) return a;
    final x = a._roles, y = b._roles;
    return _fromRoles(t < .5 ? a.brightness : b.brightness, [
      for (var i = 0; i < x.length; i++) Color.lerp(x[i], y[i], t)!,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalColors &&
          other.brightness == brightness &&
          listEquals(other._roles, _roles);

  @override
  int get hashCode => Object.hash(brightness, Object.hashAll(_roles));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    final roles = _roles;
    for (var i = 0; i < roles.length; i++) {
      properties.add(ColorProperty(_names[i], roles[i]));
    }
  }
}

/// Minimal's type scale, as Material's `TextTheme`: complete styles with
/// family, size, weight, height and colour baked in. Geist for words, Geist
/// Mono (tabular figures) for [giant], [figure] and [mono], whose word gap is
/// Geist's space rather than a full mono cell, so `25 Sep` reads as one
/// space and a column of stamps still aligns (a code block restores the
/// cell, `MinimalCodeBlock`). [label] is the uppercase group-header register:
/// components print it upper-cased.
///
/// ```dart
/// final t = MinimalThemeData.standard();
/// final own = t.copyWith(
///   typeface: const MinimalTypeface.app(sans: 'Inter', mono: 'JetBrainsMono'),
/// );
/// ```
@immutable
class MinimalTextTheme with Diagnosticable {
  /// Every step, as given.
  const MinimalTextTheme({
    required this.giant,
    required this.hero,
    required this.display,
    required this.h1,
    required this.h2,
    required this.h3,
    required this.bodyLarge,
    required this.body,
    required this.bodySmall,
    required this.caption,
    required this.label,
    required this.mono,
    required this.figure,
    required this.control,
  });

  /// The look's scale in [typeface], inked in [colors]: the primary ink for
  /// every step but [caption] and [label], which take the quiet one.
  factory MinimalTextTheme.of(
    MinimalColors colors, [
    MinimalTypeface typeface = MinimalTypeface.look,
  ]) {
    const w4 = FontWeight.w400;
    const w5 = FontWeight.w500;
    const w6 = FontWeight.w600;
    final ink = colors.foreground;
    final quiet = colors.mutedForeground;
    TextStyle type(
      double size,
      double lineHeight,
      FontWeight weight,
      Color color, {
      double tracking = 0,
      bool mono = false,
    }) => _type(
      typeface,
      size,
      lineHeight,
      weight,
      color,
      tracking: tracking,
      mono: mono,
    );
    return MinimalTextTheme(
      giant: type(34, 38, w6, ink, tracking: -0.5, mono: true),
      hero: type(28, 34, w6, ink, tracking: -0.4),
      display: type(24, 30, w6, ink, tracking: -0.3),
      h1: type(21, 28, w6, ink, tracking: -0.2),
      h2: type(17, 24, w6, ink),
      h3: type(15, 20, w6, ink),
      bodyLarge: type(15, 22, w4, ink),
      body: type(14, 20, w4, ink),
      bodySmall: type(13, 18, w4, ink),
      caption: type(12, 16, w4, quiet),
      label: type(11, 14, w6, quiet, tracking: 0.7),
      mono: type(12, 16, w4, ink, mono: true),
      figure: type(15, 20, w6, ink, mono: true),
      control: type(13, 16, w5, ink),
    );
  }

  /// The largest figure: a KPI's value, a balance. Geist Mono.
  final TextStyle giant;

  /// A landing's headline.
  final TextStyle hero;

  /// A page's display title.
  final TextStyle display;

  /// A page title.
  final TextStyle h1;

  /// A section title.
  final TextStyle h2;

  /// A card's or a row group's title.
  final TextStyle h3;

  /// A lead paragraph.
  final TextStyle bodyLarge;

  /// The default text: a row's title, a paragraph.
  final TextStyle body;

  /// Dense text: a table cell, a field's value.
  final TextStyle bodySmall;

  /// A caption or a row's meta, in the quiet ink.
  final TextStyle caption;

  /// The uppercase group-header register, in the quiet ink: components
  /// print it upper-cased.
  final TextStyle label;

  /// Stamps, ids and code: Geist Mono with tabular figures.
  final TextStyle mono;

  /// A figure that leads its line — a total, a count, a time: [h3]'s size
  /// and weight in Geist Mono with tabular figures. The action bar's
  /// summary prints in it.
  final TextStyle figure;

  /// A control's label: 13/16 medium. Buttons at sm and md print in it; lg
  /// steps up to [body] medium.
  final TextStyle control;

  List<TextStyle> get _steps => [
    giant,
    hero,
    display,
    h1,
    h2,
    h3,
    bodyLarge,
    body,
    bodySmall,
    caption,
    label,
    mono,
    figure,
    control,
  ];

  static const List<String> _names = [
    'giant',
    'hero',
    'display',
    'h1',
    'h2',
    'h3',
    'bodyLarge',
    'body',
    'bodySmall',
    'caption',
    'label',
    'mono',
    'figure',
    'control',
  ];

  static MinimalTextTheme _fromSteps(List<TextStyle> s) => MinimalTextTheme(
    giant: s[0],
    hero: s[1],
    display: s[2],
    h1: s[3],
    h2: s[4],
    h3: s[5],
    bodyLarge: s[6],
    body: s[7],
    bodySmall: s[8],
    caption: s[9],
    label: s[10],
    mono: s[11],
    figure: s[12],
    control: s[13],
  );

  /// Every step through [f]: `text.map((s) => s.copyWith(height: 1.3))`.
  MinimalTextTheme map(TextStyle Function(TextStyle style) f) =>
      _fromSteps([for (final s in _steps) f(s)]);

  /// The scale re-inked from [from] to [to]: a step printed in one of
  /// [from]'s inks takes [to]'s for the same role; any other colour stays.
  MinimalTextTheme reinked(MinimalColors from, MinimalColors to) {
    if (identical(from, to)) return this;
    final inks = <Color, Color>{
      from.textTertiary: to.textTertiary,
      from.mutedForeground: to.mutedForeground,
      from.foreground: to.foreground,
    };
    return map((s) {
      final ink = inks[s.color];
      return ink == null || ink == s.color ? s : s.copyWith(color: ink);
    });
  }

  /// This with the named steps changed.
  MinimalTextTheme copyWith({
    TextStyle? giant,
    TextStyle? hero,
    TextStyle? display,
    TextStyle? h1,
    TextStyle? h2,
    TextStyle? h3,
    TextStyle? bodyLarge,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? caption,
    TextStyle? label,
    TextStyle? mono,
    TextStyle? figure,
    TextStyle? control,
  }) => MinimalTextTheme(
    giant: giant ?? this.giant,
    hero: hero ?? this.hero,
    display: display ?? this.display,
    h1: h1 ?? this.h1,
    h2: h2 ?? this.h2,
    h3: h3 ?? this.h3,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    body: body ?? this.body,
    bodySmall: bodySmall ?? this.bodySmall,
    caption: caption ?? this.caption,
    label: label ?? this.label,
    mono: mono ?? this.mono,
    figure: figure ?? this.figure,
    control: control ?? this.control,
  );

  /// Between [a] and [b], step by step.
  static MinimalTextTheme lerp(
    MinimalTextTheme a,
    MinimalTextTheme b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final x = a._steps, y = b._steps;
    return _fromSteps([
      for (var i = 0; i < x.length; i++) TextStyle.lerp(x[i], y[i], t)!,
    ]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalTextTheme && listEquals(other._steps, _steps);

  @override
  int get hashCode => Object.hashAll(_steps);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    final steps = _steps;
    for (var i = 0; i < steps.length; i++) {
      properties.add(DiagnosticsProperty<TextStyle>(_names[i], steps[i]));
    }
  }
}

/// Minimal's theme, as `ThemeData` is Material's: the colour roles, the type
/// scale, the elevation, the corner scale and the other knobs, Minimal's own
/// row geometry, and the component themes. What `MinimalTheme.of(context)`
/// (and `context.minimalTheme`) returns. Immutable: [copyWith] and [lerp]
/// make new ones. Install it with a [MinimalTheme] in the app's `builder:`,
/// under a `MaterialApp`, a `CupertinoApp` or a `WidgetsApp` alike.
///
/// Every colour role and type step reads straight off the theme as well
/// (`t.primary` is `t.colors.primary`, `t.body` is `t.text.body`), the way a
/// Minimal screen writes them.
///
/// ```dart
/// final night = MinimalThemeData.preset('ember', Brightness.dark);
/// final mine = night.copyWith(
///   shapes: const MinimalShapes(radius: 12),
///   density: MinimalDensity.compact,
///   components: const MinimalComponentThemes(
///     chip: MinimalStyle(shape: WidgetStatePropertyAll(StadiumBorder())),
///   ),
/// );
/// ```
@immutable
class MinimalThemeData with Diagnosticable {
  /// A theme from [colors]; every other part the look's own unless named.
  /// [text] defaults to the look's scale in [typeface], inked in [colors];
  /// the shadows to the look's, cast for [colors]' appearance.
  MinimalThemeData({
    this.id = 'custom',
    required this.colors,
    MinimalTextTheme? text,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    this.shapes = MinimalShapes.look,
    MinimalDensity? density,
    this.typeface = MinimalTypeface.look,
    this.components = const MinimalComponentThemes(),
    this.iconStroke = 1.75,
  }) : _chosenDensity = density,
       text = text ?? MinimalTextTheme.of(colors, typeface),
       shadowSm = shadowSm ?? _shadow(colors, 0),
       shadowMd = shadowMd ?? _shadow(colors, 1),
       shadowLg = shadowLg ?? _shadow(colors, 2);

  /// The standard preset: neutral greys under a blue accent.
  factory MinimalThemeData.standard([
    Brightness brightness = Brightness.light,
  ]) => MinimalThemeData.preset('standard', brightness);

  /// The graphite preset: the ink itself is the accent.
  factory MinimalThemeData.graphite([
    Brightness brightness = Brightness.light,
  ]) => MinimalThemeData.preset('graphite', brightness);

  /// The ember preset: warm neutrals under an orange accent, with a cooler
  /// crimson for danger.
  factory MinimalThemeData.ember([Brightness brightness = Brightness.light]) =>
      MinimalThemeData.preset('ember', brightness);

  /// The preset ids [preset] builds, the default first. Each is designed in
  /// light and dark.
  static const List<String> presets = <String>['standard', 'graphite', 'ember'];

  /// The theme for one preset in one appearance. `standard` spends a blue
  /// accent, `graphite` spends the ink itself, `ember` runs warm neutrals
  /// under an orange accent (with its own cooler crimson for danger, so the
  /// two never read as one colour). Throws [ArgumentError] for an id that
  /// is not in [presets]. The same id and brightness always return the same
  /// instance, so a rebuild that asks again notifies nothing.
  factory MinimalThemeData.preset(String id, Brightness brightness) {
    final palette = switch ((id, brightness)) {
      ('standard', Brightness.light) => _standardLight,
      ('standard', Brightness.dark) => _standardDark,
      ('graphite', Brightness.light) => _graphiteLight,
      ('graphite', Brightness.dark) => _graphiteDark,
      ('ember', Brightness.light) => _emberLight,
      ('ember', Brightness.dark) => _emberDark,
      _ => throw ArgumentError.value(
        id,
        'id',
        'not a Minimal preset (${presets.join(', ')})',
      ),
    };
    return _presets[(id, brightness)] ??= MinimalThemeData(
      id: id,
      colors: _colors(palette),
    );
  }

  static final Map<(String, Brightness), MinimalThemeData> _presets = {};

  /// A theme in an app's own colours, in either appearance as the presets
  /// are: [primary] for the one thing to act on (the primary button, a
  /// switch that is on, a selected segment), and [neutral] to tint the
  /// greys toward (a warm or a cool grey; null keeps the standard preset's
  /// neutral greys).
  ///
  /// It adjusts rather than asserts, so any colours give a theme that holds
  /// the presets' bars: the label on the accent, the accent's ink (links,
  /// checks) on every ground and on its own quiet fill, the inks on the
  /// grounds, the control edge and every mark at 3:1. A colour that already
  /// holds is kept as given; read `colors.primary` and `colors.primaryInk` to
  /// see where they landed. When the accent sits too close to the danger or
  /// the warning tone to tell apart, that tone moves (a cooler crimson, a
  /// yellower ochre), as the ember preset's do.
  ///
  /// ```dart
  /// final brand = MinimalThemeData.from(
  ///   primary: const Color(0xFF7A1F5C),
  ///   neutral: const Color(0xFF8B7355),
  ///   brightness: Brightness.dark,
  /// );
  /// ```
  factory MinimalThemeData.from({
    required Color primary,
    Color? neutral,
    Brightness brightness = Brightness.light,
  }) => _fromThemes[(primary, neutral, brightness)] ??= MinimalThemeData(
    colors: _derive(primary, neutral, brightness),
  );

  static final Map<(Color, Color?, Brightness), MinimalThemeData> _fromThemes =
      {};

  /// What's in scope at [context]; the same as [MinimalTheme.of].
  static MinimalThemeData of(BuildContext context) => MinimalTheme.of(context);

  /// Which preset this is (`standard`, `graphite`, `ember`), or `custom`.
  final String id;

  /// The colour roles.
  final MinimalColors colors;

  /// The type scale.
  final MinimalTextTheme text;

  /// The faintest lift: a pressed segment's plate, a raised chip.
  final List<BoxShadow> shadowSm;

  /// What floats over the page: a menu or a snack bar. Minimal separates
  /// with hairlines, so only what floats casts a shadow.
  final List<BoxShadow> shadowMd;

  /// A sheet or a dialog.
  final List<BoxShadow> shadowLg;

  /// The corner scale every framed part reads.
  final MinimalShapes shapes;

  /// How compact the controls stand. Unset, the platform's own
  /// ([MinimalDensity.adaptivePlatformDensity]): standard on a phone,
  /// compact on a desktop.
  MinimalDensity get density =>
      _chosenDensity ?? MinimalDensity.adaptivePlatformDensity;
  final MinimalDensity? _chosenDensity;

  /// Whether [density] is the platform's own, no density having been set.
  bool get followsPlatformDensity => _chosenDensity == null;

  /// This theme under the platform's Increase Contrast setting, which
  /// `MinimalTheme` applies by itself: the quiet inks step up one, and the
  /// hairlines take the inks' strength.
  MinimalThemeData get highContrast => _contrasted[this] ??= copyWith(
    colors: colors.copyWith(
      mutedForeground: colors.foreground,
      textTertiary: colors.mutedForeground,
      border: colors.textTertiary,
      borderStrong: colors.mutedForeground,
      input: colors.mutedForeground,
    ),
  );

  static final Expando<MinimalThemeData> _contrasted =
      Expando<MinimalThemeData>('minimal contrast');

  /// The faces [text] was set in.
  final MinimalTypeface typeface;

  /// The component themes.
  final MinimalComponentThemes components;

  /// A list row's height, at [density]: 44 at standard and at every denser
  /// step, since the row is its own tap target and a target stays 44 × 44 at
  /// every density; a looser density grows it.
  double get rowHeight => density.height(
    MinimalChromeMetrics.row,
    least: MinimalLayout.minHitTarget,
  );

  /// A dense list row's height, at [density]: 36 at standard.
  double get rowHeightCompact =>
      density.height(MinimalChromeMetrics.rowCompact);

  /// The stroke weight of a Lucide glyph (the icon font draws it; a painted
  /// status glyph matches it).
  final double iconStroke;

  /// Which appearance this theme is for.
  Brightness get brightness => colors.brightness;

  /// Which appearance this theme IS: true in light.
  bool get isLightAppearance => colors.brightness == Brightness.light;

  /// The width of every rule between rows and around a section.
  double get hairline => 1;

  /// The width of a control's rim.
  double get rim => 1;

  /// The width of the keyboard's focus ring.
  double get focusWidth => 2;

  /// A rule in the theme's hairline colour and width, for a Border.
  BorderSide get rule => BorderSide(color: colors.border, width: hairline);

  /// The corner radius of a card, a list section, a menu and a snack bar:
  /// [shapes]' medium step.
  double get cardRadius => MinimalShapes.radiusOf(shapes.medium);

  /// The corner radius of a button, a field and a select: [shapes]' small
  /// step.
  double get controlRadius => MinimalShapes.radiusOf(shapes.small);

  /// The corner radius of a tag, a key cap and a checkbox's box: [shapes]'
  /// mark step.
  double get smallRadius => MinimalShapes.radiusOf(shapes.mark);

  /// The corner radius of a dialog and a bottom sheet: [shapes]' large step.
  double get sheetRadius => MinimalShapes.radiusOf(shapes.large);

  // The colour roles, read straight off the theme.

  /// [MinimalColors.background].
  Color get background => colors.background;

  /// [MinimalColors.card].
  Color get card => colors.card;

  /// [MinimalColors.muted].
  Color get muted => colors.muted;

  /// [MinimalColors.sunken].
  Color get sunken => colors.sunken;

  /// [MinimalColors.surfaceInverse].
  Color get surfaceInverse => colors.surfaceInverse;

  /// [MinimalColors.border].
  Color get border => colors.border;

  /// [MinimalColors.borderStrong].
  Color get borderStrong => colors.borderStrong;

  /// [MinimalColors.input].
  Color get input => colors.input;

  /// [MinimalColors.foreground].
  Color get foreground => colors.foreground;

  /// [MinimalColors.mutedForeground].
  Color get mutedForeground => colors.mutedForeground;

  /// [MinimalColors.textTertiary].
  Color get textTertiary => colors.textTertiary;

  /// [MinimalColors.textInverse].
  Color get textInverse => colors.textInverse;

  /// [MinimalColors.primary].
  Color get primary => colors.primary;

  /// [MinimalColors.primaryForeground].
  Color get primaryForeground => colors.primaryForeground;

  /// [MinimalColors.primarySubtle].
  Color get primarySubtle => colors.primarySubtle;

  /// [MinimalColors.primaryInk].
  Color get primaryInk => colors.primaryInk;

  /// [MinimalColors.success].
  Color get success => colors.success;

  /// [MinimalColors.onSuccess].
  Color get onSuccess => colors.onSuccess;

  /// [MinimalColors.successSubtle].
  Color get successSubtle => colors.successSubtle;

  /// [MinimalColors.successInk].
  Color get successInk => colors.successInk;

  /// [MinimalColors.warning].
  Color get warning => colors.warning;

  /// [MinimalColors.warningSubtle].
  Color get warningSubtle => colors.warningSubtle;

  /// [MinimalColors.warningInk].
  Color get warningInk => colors.warningInk;

  /// [MinimalColors.destructive].
  Color get destructive => colors.destructive;

  /// [MinimalColors.destructiveForeground].
  Color get destructiveForeground => colors.destructiveForeground;

  /// [MinimalColors.destructiveSubtle].
  Color get destructiveSubtle => colors.destructiveSubtle;

  /// [MinimalColors.destructiveInk].
  Color get destructiveInk => colors.destructiveInk;

  /// [MinimalColors.info].
  Color get info => colors.info;

  /// [MinimalColors.overlay].
  Color get overlay => colors.overlay;

  /// [MinimalColors.ring].
  Color get ring => colors.ring;

  /// [MinimalColors.selection].
  Color get selection => colors.selection;

  // The type scale, read straight off the theme.

  /// [MinimalTextTheme.giant].
  TextStyle get giant => text.giant;

  /// [MinimalTextTheme.hero].
  TextStyle get hero => text.hero;

  /// [MinimalTextTheme.display].
  TextStyle get display => text.display;

  /// [MinimalTextTheme.h1].
  TextStyle get h1 => text.h1;

  /// [MinimalTextTheme.h2].
  TextStyle get h2 => text.h2;

  /// [MinimalTextTheme.h3].
  TextStyle get h3 => text.h3;

  /// [MinimalTextTheme.bodyLarge].
  TextStyle get bodyLarge => text.bodyLarge;

  /// [MinimalTextTheme.body].
  TextStyle get body => text.body;

  /// [MinimalTextTheme.bodySmall].
  TextStyle get bodySmall => text.bodySmall;

  /// [MinimalTextTheme.caption].
  TextStyle get caption => text.caption;

  /// [MinimalTextTheme.label].
  TextStyle get label => text.label;

  /// [MinimalTextTheme.mono].
  TextStyle get mono => text.mono;

  /// [MinimalTextTheme.figure].
  TextStyle get figure => text.figure;

  /// [MinimalTextTheme.control].
  TextStyle get control => text.control;

  /// This with the named parts changed. A new [colors] re-inks the type
  /// scale (a step in one of the old inks takes the new one for its role)
  /// and recasts the look's shadows; a new [typeface] sets the type anew in
  /// it. Pass [text] or the shadows to set them as given.
  MinimalThemeData copyWith({
    String? id,
    MinimalColors? colors,
    MinimalTextTheme? text,
    List<BoxShadow>? shadowSm,
    List<BoxShadow>? shadowMd,
    List<BoxShadow>? shadowLg,
    MinimalShapes? shapes,
    MinimalDensity? density,
    MinimalTypeface? typeface,
    MinimalComponentThemes? components,
    double? iconStroke,
  }) {
    final nextColors = colors ?? this.colors;
    final nextFace = typeface ?? this.typeface;
    final MinimalTextTheme nextText;
    if (text != null) {
      nextText = text;
    } else if (typeface != null && typeface != this.typeface) {
      nextText = MinimalTextTheme.of(nextColors, nextFace);
    } else {
      nextText = this.text.reinked(this.colors, nextColors);
    }
    final recast = colors != null && colors != this.colors;
    List<BoxShadow> shadow(
      List<BoxShadow>? given,
      List<BoxShadow> own,
      int i,
    ) =>
        given ??
        (recast && listEquals(own, _shadow(this.colors, i))
            ? _shadow(nextColors, i)
            : own);
    return MinimalThemeData(
      id: id ?? this.id,
      colors: nextColors,
      text: nextText,
      shadowSm: shadow(shadowSm, this.shadowSm, 0),
      shadowMd: shadow(shadowMd, this.shadowMd, 1),
      shadowLg: shadow(shadowLg, this.shadowLg, 2),
      shapes: shapes ?? this.shapes,
      density: density ?? _chosenDensity,
      typeface: nextFace,
      components: components ?? this.components,
      iconStroke: iconStroke ?? this.iconStroke,
    );
  }

  /// Between this and [other]: colours, type, shadows, corners and sizes
  /// blend; the preset id, the appearance and the faces flip at the middle.
  /// `AnimatedMinimalTheme` animates with it.
  MinimalThemeData lerp(MinimalThemeData? other, double t) {
    if (other == null || identical(this, other)) return this;
    return MinimalThemeData(
      id: t < .5 ? id : other.id,
      colors: MinimalColors.lerp(colors, other.colors, t),
      text: MinimalTextTheme.lerp(text, other.text, t),
      shadowSm: BoxShadow.lerpList(shadowSm, other.shadowSm, t)!,
      shadowMd: BoxShadow.lerpList(shadowMd, other.shadowMd, t)!,
      shadowLg: BoxShadow.lerpList(shadowLg, other.shadowLg, t)!,
      shapes: MinimalShapes.lerp(shapes, other.shapes, t),
      density: _chosenDensity == null && other._chosenDensity == null
          ? null
          : MinimalDensity.lerp(density, other.density, t),
      typeface: MinimalTypeface.lerp(typeface, other.typeface, t),
      components: MinimalComponentThemes.lerp(components, other.components, t),
      iconStroke: lerpDouble(iconStroke, other.iconStroke, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MinimalThemeData &&
          other.id == id &&
          other.colors == colors &&
          other.text == text &&
          listEquals(other.shadowSm, shadowSm) &&
          listEquals(other.shadowMd, shadowMd) &&
          listEquals(other.shadowLg, shadowLg) &&
          other.shapes == shapes &&
          other._chosenDensity == _chosenDensity &&
          other.typeface == typeface &&
          other.components == components &&
          other.iconStroke == iconStroke;

  @override
  int get hashCode => Object.hash(
    id,
    colors,
    text,
    Object.hashAll(shadowSm),
    Object.hashAll(shadowMd),
    Object.hashAll(shadowLg),
    shapes,
    _chosenDensity,
    typeface,
    components,
    iconStroke,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<MinimalColors>('colors', colors))
      ..add(DiagnosticsProperty<MinimalTextTheme>('text', text))
      ..add(
        DiagnosticsProperty<MinimalShapes>(
          'shapes',
          shapes,
          defaultValue: MinimalShapes.look,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalDensity>(
          'density',
          _chosenDensity,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalTypeface>(
          'typeface',
          typeface,
          defaultValue: MinimalTypeface.look,
        ),
      )
      ..add(
        DiagnosticsProperty<MinimalComponentThemes>(
          'components',
          components,
          defaultValue: const MinimalComponentThemes(),
        ),
      )
      ..add(DoubleProperty('iconStroke', iconStroke, defaultValue: 1.75));
  }
}

class _MinimalScope extends InheritedTheme {
  const _MinimalScope({
    required this.data,
    required this.dark,
    required super.child,
  });

  final MinimalThemeData data;
  final MinimalThemeData? dark;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _MinimalScope(data: data, dark: dark, child: child);

  @override
  bool updateShouldNotify(_MinimalScope oldWidget) =>
      data != oldWidget.data || dark != oldWidget.dark;
}

/// Puts Minimal in scope for everything under it, as Material's `Theme`
/// does. It is the whole install: put one in any app's `builder:`, under a
/// `MaterialApp`, a `CupertinoApp` or a `WidgetsApp` alike, and every look
/// installs the same way (`<Look>Theme(data: <Look>ThemeData.preset(...))`).
/// Under it, Flutter's own text field and scroll bar wear Minimal's caret,
/// selection, handles and bar, with no ink, and every text has Minimal's
/// body style to fall back on. Another one restyles a part of the tree. An
/// `InheritedTheme`, so what a route or an overlay captures keeps the
/// Minimal it was raised in.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => MinimalTheme(
///     data: MinimalThemeData.preset(
///       'standard',
///       MediaQuery.platformBrightnessOf(context),
///     ),
///     child: child!,
///   ),
///   home: const InboxPage(),
/// )
/// ```
class MinimalTheme extends StatelessWidget {
  /// Scopes [data] over [child].
  const MinimalTheme({
    super.key,
    required this.data,
    required this.child,
    this.darkData,
  });

  /// The theme for what is under it.
  final MinimalThemeData data;

  /// The tokens a media ground ([MinimalGround.media]) is drawn in whatever
  /// the appearance: the app's dark theme. Null takes [data].
  final MinimalThemeData? darkData;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]. Throws when there is none.
  /// `context.minimalTheme` is the same.
  static MinimalThemeData of(BuildContext context) {
    final found = maybeOf(context);
    if (found == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No MinimalTheme in scope.'),
        ErrorHint(
          "Put a MinimalTheme in the app's builder, or above this widget.",
        ),
      ]);
    }
    return found;
  }

  /// The theme in scope at [context], or null.
  static MinimalThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_MinimalScope>()?.data;

  /// The tokens a media ground wears at [context]: the [darkData] theme in
  /// scope, or the theme itself when none was given.
  static MinimalThemeData darkOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_MinimalScope>();
    if (scope == null) return of(context);
    return scope.dark ?? scope.data;
  }

  @override
  Widget build(BuildContext context) {
    Widget under = child;
    // Flutter's text field under a CupertinoApp or a WidgetsApp still asks
    // for Material's words.
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      // An override sets the direction from its locale's words again; the
      // app's own direction (a Directionality it placed) stands.
      final direction = Directionality.maybeOf(context);
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    // The platform's Increase Contrast setting: every part reads the theme
    // in scope, so stepping the theme reaches them all.
    final contrast = MediaQuery.maybeHighContrastOf(context) ?? false;
    final shown = contrast ? data.highContrast : data;
    return _MinimalScope(
      data: shown,
      dark: contrast ? darkData?.highContrast : darkData,
      child: Theme(
        data: _bridges[shown] ??= _materialUnder(shown),
        child: ScrollConfiguration(
          behavior: MinimalScrollBehavior(shown.borderStrong),
          child: IconTheme.merge(
            data: IconThemeData(color: shown.mutedForeground),
            // Minimal's own text default: it replaces WidgetsApp's error
            // style for any text outside a part that sets its own.
            child: DefaultTextStyle(style: shown.body, child: under),
          ),
        ),
      ),
    );
  }

  static final Expando<ThemeData> _bridges = Expando<ThemeData>('minimal');

  /// What Flutter's own widgets under Minimal read (a text field's caret,
  /// selection and handles, a divider, a scaffold's ground), in Minimal's
  /// colours, with no ink, splash or highlight. Private: an app never sees
  /// a Material type in Minimal's API, and no Minimal part reads a token
  /// from it.
  static ThemeData _materialUnder(MinimalThemeData t) => ThemeData(
    useMaterial3: true,
    brightness: t.brightness,
    fontFamily: t.body.fontFamily,
    scaffoldBackgroundColor: t.background,
    canvasColor: t.background,
    splashFactory: NoSplash.splashFactory,
    highlightColor: const Color(0x00000000),
    hoverColor: const Color(0x00000000),
    splashColor: const Color(0x00000000),
    focusColor: t.ring,
    materialTapTargetSize: MaterialTapTargetSize.padded,
    // The theme's density is read by Minimal's own parts, at its own step.
    // Material's default is compact on a desktop (and a web build opened on
    // one), which would move a text field's line 4 px under its box there.
    visualDensity: VisualDensity.standard,
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: t.primary,
      selectionColor: t.primary.withValues(alpha: 0.24),
      selectionHandleColor: t.primary,
    ),
    colorScheme:
        ColorScheme.fromSeed(
          seedColor: t.primary,
          brightness: t.brightness,
          surface: t.background,
        ).copyWith(
          primary: t.primary,
          onPrimary: t.primaryForeground,
          onSurface: t.foreground,
          error: t.destructive,
          onError: t.destructiveForeground,
          outline: t.borderStrong,
          outlineVariant: t.border,
        ),
    dividerTheme: DividerThemeData(
      color: t.border,
      thickness: t.hairline,
      space: t.hairline,
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<MinimalThemeData>('data', data))
      ..add(
        DiagnosticsProperty<MinimalThemeData>(
          'darkData',
          darkData,
          defaultValue: null,
        ),
      );
  }
}

/// Animates to a new [data] over [duration] (200 ms, Material's
/// `AnimatedTheme` default), as `AnimatedTheme` does: colours, type, corners
/// and sizes blend through [MinimalThemeData.lerp].
///
/// ```dart
/// AnimatedMinimalTheme(
///   data: MinimalThemeData.preset(
///     'standard',
///     dark ? Brightness.dark : Brightness.light,
///   ),
///   child: page,
/// )
/// ```
class AnimatedMinimalTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedMinimalTheme({
    super.key,
    required this.data,
    required this.child,
    this.darkData,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final MinimalThemeData data;

  /// [MinimalTheme.darkData], passed through as it is.
  final MinimalThemeData? darkData;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedMinimalTheme> createState() =>
      _AnimatedMinimalThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<MinimalThemeData>('data', data));
  }
}

class _AnimatedMinimalThemeState
    extends AnimatedWidgetBaseState<AnimatedMinimalTheme> {
  MinimalThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => MinimalThemeDataTween(begin: value as MinimalThemeData),
    ) as MinimalThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) => MinimalTheme(
    data: _data!.evaluate(animation),
    darkData: widget.darkData,
    child: widget.child,
  );
}

/// A tween between two Minimal themes, through [MinimalThemeData.lerp].
class MinimalThemeDataTween extends Tween<MinimalThemeData> {
  /// From [begin] to [end].
  MinimalThemeDataTween({super.begin, super.end});

  @override
  MinimalThemeData lerp(double t) => begin!.lerp(end, t);
}

/// How a scroll looks under Minimal: a thin bar in [thumb] on a desktop,
/// the stretch on Android, and nothing of Material's. [MinimalTheme]
/// installs it.
class MinimalScrollBehavior extends ScrollBehavior {
  /// A behaviour whose bar is drawn in [thumb].
  const MinimalScrollBehavior(this.thumb);

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
      radius: const Radius.circular(3),
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
  bool shouldNotify(MinimalScrollBehavior oldDelegate) =>
      oldDelegate.thumb != thumb;
}

/// The accessor every Minimal widget reads its tokens through.
extension MinimalThemeContext on BuildContext {
  /// The app's design tokens: `context.minimalTheme.primary`, ...
  MinimalThemeData get minimalTheme => MinimalTheme.of(this);
}

/// The one motion switch every Minimal component reads.
extension MinimalMotionContext on BuildContext {
  /// True when motion should collapse to its end state: the test and
  /// walkthrough kill-switch ([MinimalMotion.animate] false) or the platform's
  /// reduce-motion setting (`MediaQuery.disableAnimations`).
  bool get minimalStill =>
      !MinimalMotion.animate ||
      (MediaQuery.maybeDisableAnimationsOf(this) ?? false);
}

/// Scale-step adjustments that keep a style on the scale.
extension MinimalTextStyle on TextStyle {
  /// Recolour a scale step: `t.body.c(t.mutedForeground)`.
  TextStyle c(Color color) => copyWith(color: color);

  /// Emphasise a scale step without leaving the scale.
  TextStyle get semibold => copyWith(fontWeight: FontWeight.w600);

  /// The quieter emphasis register: one weight up from regular.
  TextStyle get medium => copyWith(fontWeight: FontWeight.w500);
}

// ── Presets ──────────────────────────────────────────────────────────────

/// One preset's colour roles in one appearance; [_colors] turns it into
/// the theme's roles.
typedef _Palette = ({
  Color background,
  Color card,
  Color muted,
  Color sunken,
  Color border,
  Color borderStrong,
  Color input,
  Color text1,
  Color text2,
  Color text3,
  Color textInverse,
  Color primary,
  Color primaryForeground,
  Color primarySubtle,
  Color primaryInk,
  Color success,
  Color successSubtle,
  Color successInk,
  Color warning,
  Color warningSubtle,
  Color warningInk,
  Color destructive,
  Color destructiveSubtle,
  Color destructiveInk,
  Color overlay,
  bool dark,
});

// Shared status colours, per appearance. The light danger is a shade
// deeper than the spec's #D93F3F so its white label clears AA (4.75:1).
// The light amber is a shade deeper than the spec's #D98A00 (2.8:1 on
// white) so, as a mark — a badge dot, a progress bar, a snooze tile — it
// stands 3.4:1 off the ground like every other status fill. The light
// fills are still too bright to print words in (the amber 3.4:1, the green
// 3.4:1), so each carries a deeper ink that clears 4.5:1 on the ground and
// on its own subtle fill.
const Color _successLight = Color(0xFF2F9E66);
const Color _successSubtleLight = Color(0xFFE8F6EF);
const Color _successInkLight = Color(0xFF1E7A4C);
const Color _warningLight = Color(0xFFC27B00);
const Color _warningSubtleLight = Color(0xFFFDF4E3);
const Color _warningInkLight = Color(0xFFA15F00);
const Color _dangerLight = Color(0xFFD63535);
const Color _dangerSubtleLight = Color(0xFFFCEBEB);
const Color _dangerInkLight = Color(0xFFC22F2F);
const Color _successDark = Color(0xFF4CC38A);
const Color _successSubtleDark = Color(0xFF13261D);
const Color _warningDark = Color(0xFFF5B642);
const Color _warningSubtleDark = Color(0xFF2A2112);
const Color _dangerDark = Color(0xFFF06B6B);
const Color _dangerSubtleDark = Color(0xFF2C1515);

// The scrim: the page stays legible behind a sheet in light, and dims
// harder in dark so the raised card still stands off it.
const Color _overlayLight = Color(0x610A0A0E);
const Color _overlayDark = Color(0x99000000);

const _Palette _standardLight = (
  background: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  muted: Color(0xFFF7F7F8),
  sunken: Color(0xFFF2F2F4),
  border: Color(0xFFE8E8EB),
  borderStrong: Color(0xFFD4D4D9),
  // 3.2:1 on the paper, 3.0:1 on the quiet fill.
  input: Color(0xFF8E8E98),
  text1: Color(0xFF17171A),
  text2: Color(0xFF6E6E78),
  text3: Color(0xFFA1A1AA),
  textInverse: Color(0xFFFFFFFF),
  primary: Color(0xFF3E63DD),
  primaryForeground: Color(0xFFFFFFFF),
  primarySubtle: Color(0xFFEDF1FD),
  primaryInk: Color(0xFF3E63DD),
  success: _successLight,
  successSubtle: _successSubtleLight,
  successInk: _successInkLight,
  warning: _warningLight,
  warningSubtle: _warningSubtleLight,
  warningInk: _warningInkLight,
  destructive: _dangerLight,
  destructiveSubtle: _dangerSubtleLight,
  destructiveInk: _dangerInkLight,
  overlay: _overlayLight,
  dark: false,
);

const _Palette _standardDark = (
  background: Color(0xFF0E0E11),
  // By night as by day a card is the ground in a hairline, and every quiet
  // fill steps away from the ground the same way: lighter, the well more.
  card: Color(0xFF0E0E11),
  muted: Color(0xFF1A1A1F),
  sunken: Color(0xFF1D1D22),
  border: Color(0xFF27272C),
  borderStrong: Color(0xFF3A3A42),
  // 3.4:1 on the ground, 3.1:1 on the quiet fill.
  input: Color(0xFF66666F),
  text1: Color(0xFFEDEDF0),
  text2: Color(0xFF8B8B96),
  text3: Color(0xFF5C5C66),
  textInverse: Color(0xFF0E0E11),
  primary: Color(0xFF7C9BFF),
  primaryForeground: Color(0xFF0E0E11),
  primarySubtle: Color(0xFF1C2340),
  primaryInk: Color(0xFF7C9BFF),
  success: _successDark,
  successSubtle: _successSubtleDark,
  successInk: _successDark,
  warning: _warningDark,
  warningSubtle: _warningSubtleDark,
  warningInk: _warningDark,
  destructive: _dangerDark,
  destructiveSubtle: _dangerSubtleDark,
  destructiveInk: _dangerDark,
  overlay: _overlayDark,
  dark: true,
);

final _Palette _graphiteLight = (
  background: _standardLight.background,
  card: _standardLight.card,
  muted: _standardLight.muted,
  sunken: _standardLight.sunken,
  border: _standardLight.border,
  borderStrong: _standardLight.borderStrong,
  input: _standardLight.input,
  text1: _standardLight.text1,
  text2: _standardLight.text2,
  text3: _standardLight.text3,
  textInverse: _standardLight.textInverse,
  primary: const Color(0xFF17171A),
  primaryForeground: const Color(0xFFFFFFFF),
  primarySubtle: const Color(0xFFF0F0F2),
  primaryInk: const Color(0xFF17171A),
  success: _successLight,
  successSubtle: _successSubtleLight,
  successInk: _successInkLight,
  warning: _warningLight,
  warningSubtle: _warningSubtleLight,
  warningInk: _warningInkLight,
  destructive: _dangerLight,
  destructiveSubtle: _dangerSubtleLight,
  destructiveInk: _dangerInkLight,
  overlay: _overlayLight,
  dark: false,
);

final _Palette _graphiteDark = (
  background: _standardDark.background,
  card: _standardDark.card,
  muted: _standardDark.muted,
  sunken: _standardDark.sunken,
  border: _standardDark.border,
  borderStrong: _standardDark.borderStrong,
  input: _standardDark.input,
  text1: _standardDark.text1,
  text2: _standardDark.text2,
  text3: _standardDark.text3,
  textInverse: _standardDark.textInverse,
  primary: const Color(0xFFEDEDF0),
  primaryForeground: const Color(0xFF0E0E11),
  primarySubtle: const Color(0xFF1F1F24),
  primaryInk: const Color(0xFFEDEDF0),
  success: _successDark,
  successSubtle: _successSubtleDark,
  successInk: _successDark,
  warning: _warningDark,
  warningSubtle: _warningSubtleDark,
  warningInk: _warningDark,
  destructive: _dangerDark,
  destructiveSubtle: _dangerSubtleDark,
  destructiveInk: _dangerDark,
  overlay: _overlayDark,
  dark: true,
);

const _Palette _emberLight = (
  background: Color(0xFFFFFFFF),
  card: Color(0xFFFFFFFF),
  muted: Color(0xFFF8F7F5),
  sunken: Color(0xFFF3F1EE),
  border: Color(0xFFEAE7E3),
  borderStrong: Color(0xFFD7D2CC),
  input: Color(0xFF8F8A84),
  text1: Color(0xFF1B1917),
  text2: Color(0xFF75706A),
  text3: Color(0xFFA8A29B),
  textInverse: Color(0xFFFFFFFF),
  primary: Color(0xFFE5602F),
  // White on the orange is 3.47:1; the ink is 5.05:1.
  primaryForeground: Color(0xFF1B1917),
  primarySubtle: Color(0xFFFCEEE8),
  // The orange is 3.5:1 on the paper: words and thin glyphs in the accent
  // take this burnt cut (5.4:1, 4.8:1 on the subtle fill).
  primaryInk: Color(0xFFB5461C),
  success: _successLight,
  successSubtle: _successSubtleLight,
  successInk: _successInkLight,
  // The shared amber is a second orange beside this accent (ΔE 33); a
  // yellower, deeper ochre keeps `Late` and `Baking` apart (ΔE 47) and
  // reads better on the paper (3.5:1 against 2.8:1).
  warning: Color(0xFFA88400),
  warningSubtle: Color(0xFFFAF4DC),
  warningInk: Color(0xFF846800),
  // The shared red sits 16° of hue from the orange accent; a cooler crimson
  // keeps Create and Delete apart, colour-blind eyes included.
  destructive: Color(0xFFC2305A),
  destructiveSubtle: Color(0xFFFBE9EE),
  destructiveInk: Color(0xFFC2305A),
  overlay: Color(0x61110F0E),
  dark: false,
);

const _Palette _emberDark = (
  background: Color(0xFF110F0E),
  // By night as by day a card is the ground in a hairline, and every quiet
  // fill steps away from the ground the same way: lighter, the well more.
  card: Color(0xFF110F0E),
  muted: Color(0xFF1E1B19),
  sunken: Color(0xFF221F1C),
  border: Color(0xFF2B2724),
  borderStrong: Color(0xFF3F3934),
  input: Color(0xFF716A64),
  text1: Color(0xFFF2EFEC),
  text2: Color(0xFF968F88),
  text3: Color(0xFF5F5953),
  textInverse: Color(0xFF110F0E),
  primary: Color(0xFFFF8A5C),
  primaryForeground: Color(0xFF110F0E),
  primarySubtle: Color(0xFF2E1B13),
  primaryInk: Color(0xFFFF8A5C),
  success: _successDark,
  successSubtle: _successSubtleDark,
  successInk: _successDark,
  // As in light: a yellower amber than the shared one, clear of the
  // orange accent (ΔE 47 against 36).
  warning: Color(0xFFEACB5A),
  warningSubtle: Color(0xFF26210F),
  warningInk: Color(0xFFEACB5A),
  // The light crimson, lifted for the dark ground: a deep rose-red rather
  // than a hot magenta, so it reads as the light crimson's sibling. It sits
  // at hue 344 because a redder crimson falls within ΔE 40 of the orange.
  destructive: Color(0xFFEA4E78),
  destructiveSubtle: Color(0xFF2E1520),
  destructiveInk: Color(0xFFEA4E78),
  overlay: _overlayDark,
  dark: true,
);

const List<FontFeature> _tabular = <FontFeature>[FontFeature.tabularFigures()];

/// The faces' space advances, in em: Geist Mono's is a full cell (600 of
/// 1000 units, as wide as a digit), Geist's a quarter em (250).
const double _monoSpaceEm = 0.6;
const double _sansSpaceEm = 0.25;

/// What a mono style adds to each space so its word gap is Geist's: set
/// whole in Geist Mono, a date or a stamp (`25 Sep`, `24 Sep 17:05`) reads
/// as a double space, because the space is as wide as a digit and a
/// digit's glyph sits narrower than its cell. Every word stays mono, so a
/// column of same-shaped stamps still aligns. Logical pixels at [size]: a
/// copy at another size keeps it, a close enough gap for the few that
/// resize, and a code block, whose indentation needs the full cell, sets it
/// back to zero ([MinimalCodeBlock]). Another mono face keeps its own gap.
double _monoWordSpacing(double size) => (_sansSpaceEm - _monoSpaceEm) * size;

TextStyle _type(
  MinimalTypeface face,
  double size,
  double lineHeight,
  FontWeight weight,
  Color color, {
  double tracking = 0,
  bool mono = false,
}) {
  return TextStyle(
    fontFamily: mono ? face.mono : face.sans,
    package: mono ? face.monoPackage : face.sansPackage,
    fontSize: size,
    height: lineHeight / size,
    fontWeight: weight,
    letterSpacing: tracking,
    color: color,
    fontFeatures: mono ? _tabular : null,
    wordSpacing: mono && face.mono == MinimalTypeface.look.mono
        ? _monoWordSpacing(size)
        : null,
    // Dense rows centre their type: the leading splits evenly above and below
    // the glyphs rather than all landing under them.
    leadingDistribution: TextLeadingDistribution.even,
  );
}

/// One preset's palette as the theme's colour roles.
MinimalColors _colors(_Palette p) => MinimalColors(
  brightness: p.dark ? Brightness.dark : Brightness.light,
  background: p.background,
  card: p.card,
  muted: p.muted,
  sunken: p.sunken,
  surfaceInverse: p.text1,
  border: p.border,
  borderStrong: p.borderStrong,
  input: p.input,
  foreground: p.text1,
  mutedForeground: p.text2,
  textTertiary: p.text3,
  textInverse: p.textInverse,
  primary: p.primary,
  primaryForeground: p.primaryForeground,
  primarySubtle: p.primarySubtle,
  primaryInk: p.primaryInk,
  success: p.success,
  // Every success fill is mid-tone: the dark ink reads on it in both
  // appearances, where white fails AA in light.
  onSuccess: p.dark ? p.textInverse : p.text1,
  successSubtle: p.successSubtle,
  successInk: p.successInk,
  warning: p.warning,
  warningSubtle: p.warningSubtle,
  warningInk: p.warningInk,
  destructive: p.destructive,
  destructiveForeground: p.textInverse,
  destructiveSubtle: p.destructiveSubtle,
  destructiveInk: p.destructiveInk,
  info: p.primaryInk,
  overlay: p.overlay,
  ring: p.primary,
  selection: p.primarySubtle,
);

/// The look's shadows for [colors]' appearance, by [level]: 0 the faint
/// lift, 1 what floats, 2 a sheet or a dialog. Floating shadows draw in
/// from their edges (a negative spread, as shadcn's shadow-xl and
/// shadow-2xl), so one soft shadow falls under the surface rather than a
/// halo round it.
List<BoxShadow> _shadow(MinimalColors colors, int level) =>
    (colors.brightness == Brightness.dark
    ? _shadowsDark
    : _shadowsLight)[level];

final List<List<BoxShadow>> _shadowsLight = _shadows(
  const Color(0xFF0A0A0E),
  0.06,
  0.12,
  0.25,
);
final List<List<BoxShadow>> _shadowsDark = _shadows(
  const Color(0xFF000000),
  0.4,
  0.5,
  0.6,
);

List<List<BoxShadow>> _shadows(Color shadow, double sm, double md, double lg) =>
    [
      <BoxShadow>[
        BoxShadow(
          color: shadow.withValues(alpha: sm),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ],
      <BoxShadow>[
        BoxShadow(
          color: shadow.withValues(alpha: md),
          blurRadius: 24,
          offset: const Offset(0, 8),
          spreadRadius: -6,
        ),
      ],
      <BoxShadow>[
        BoxShadow(
          color: shadow.withValues(alpha: lg),
          blurRadius: 50,
          offset: const Offset(0, 25),
          spreadRadius: -12,
        ),
      ],
    ];

// ── From an app's own colours ────────────────────────────────────────────

const Color _white = Color(0xFFFFFFFF);
const Color _black = Color(0xFF000000);

/// WCAG's contrast of [a] on [b], from 1 to 21.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

/// The least contrast [c] has on any of [grounds].
double _worst(Color c, List<Color> grounds) =>
    grounds.map((g) => _contrast(c, g)).reduce(math.min);

/// [c] moved toward [toward] in small steps until it holds [ratio] on every
/// one of [grounds]: [c] itself when it already does.
Color _settle(Color c, List<Color> grounds, double ratio, Color toward) {
  for (var i = 0; i <= 40; i++) {
    final step = Color.lerp(c, toward, i / 40)!;
    if (_worst(step, grounds) >= ratio) return step;
  }
  return toward;
}

/// CIE76 colour difference: the distance between two colours in CIELAB.
double _deltaE(Color a, Color b) {
  List<double> lab(Color c) {
    double lin(double v) =>
        v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4) * 1.0;
    final r = lin(c.r), g = lin(c.g), bl = lin(c.b);
    final x = (r * 0.4124 + g * 0.3576 + bl * 0.1805) / 0.95047;
    final y = r * 0.2126 + g * 0.7152 + bl * 0.0722;
    final z = (r * 0.0193 + g * 0.1192 + bl * 0.9505) / 1.08883;
    double f(double v) =>
        v > 0.008856 ? math.pow(v, 1 / 3) * 1.0 : 7.787 * v + 16 / 116;
    return [116 * f(y) - 16, 500 * (f(x) - f(y)), 200 * (f(y) - f(z))];
  }

  final p = lab(a), q = lab(b);
  return math.sqrt(
    math.pow(p[0] - q[0], 2) +
        math.pow(p[1] - q[1], 2) +
        math.pow(p[2] - q[2], 2),
  );
}

/// A grey of the standard palette tinted toward [neutral]'s hue, its
/// lightness kept: a warm or a cool grey, never a colour.
Color _tinted(Color grey, Color neutral) {
  final n = HSLColor.fromColor(neutral);
  final g = HSLColor.fromColor(grey);
  return g
      .withHue(n.hue)
      .withSaturation(math.min(n.saturation, 0.16))
      .toColor();
}

/// One status tone: its fill, quiet fill and ink.
typedef _Tone = ({Color fill, Color subtle, Color ink});

/// The danger tones a theme from an app's colours may take, the shared one
/// first: then ember's cooler crimson, then a rose, so a red or an orange
/// accent never reads as the danger.
const List<_Tone> _dangersLight = [
  (fill: _dangerLight, subtle: _dangerSubtleLight, ink: _dangerInkLight),
  (fill: Color(0xFFC2305A), subtle: Color(0xFFFBE9EE), ink: Color(0xFFC2305A)),
  (fill: Color(0xFFB4307F), subtle: Color(0xFFF9E9F3), ink: Color(0xFFA42A73)),
];
const List<_Tone> _dangersDark = [
  (fill: _dangerDark, subtle: _dangerSubtleDark, ink: _dangerDark),
  (fill: Color(0xFFEA4E78), subtle: Color(0xFF2E1520), ink: Color(0xFFEA4E78)),
  (fill: Color(0xFFE062AE), subtle: Color(0xFF2C1426), ink: Color(0xFFE062AE)),
];

/// The warning tones, the shared amber first, then ember's yellower ochre,
/// then a brown (an orange accent's), then in light a burnt orange (a
/// yellow accent's, which settles to an olive the others sit near), so no
/// accent reads as the warning.
const List<_Tone> _warningsLight = [
  (fill: _warningLight, subtle: _warningSubtleLight, ink: _warningInkLight),
  (fill: Color(0xFFA88400), subtle: Color(0xFFFAF4DC), ink: Color(0xFF846800)),
  (fill: Color(0xFF9A6A3A), subtle: Color(0xFFF7EEE5), ink: Color(0xFF7D5228)),
  (fill: Color(0xFFB45309), subtle: Color(0xFFFBF0E6), ink: Color(0xFF9A4508)),
];
const List<_Tone> _warningsDark = [
  (fill: _warningDark, subtle: _warningSubtleDark, ink: _warningDark),
  (fill: Color(0xFFEACB5A), subtle: Color(0xFF26210F), ink: Color(0xFFEACB5A)),
  (fill: Color(0xFFD8A27A), subtle: Color(0xFF2A2017), ink: Color(0xFFD8A27A)),
];

/// The first of [tones] that stands 40 ΔE from [primary], or the farthest.
_Tone _apart(Color primary, List<_Tone> tones) {
  for (final tone in tones) {
    if (_deltaE(tone.fill, primary) >= 40) return tone;
  }
  return tones.reduce(
    (a, b) => _deltaE(a.fill, primary) >= _deltaE(b.fill, primary) ? a : b,
  );
}

/// The colours `MinimalThemeData.from` builds: the standard palette's
/// greys (tinted toward [neutral]), [primary] spent as given where it holds
/// and moved where it does not, and every derived role settled until the
/// presets' bars hold.
MinimalColors _derive(Color primary, Color? neutral, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final p = dark ? _standardDark : _standardLight;
  Color tint(Color c) => neutral == null ? c : _tinted(c, neutral);
  final background = tint(p.background);
  final surface = tint(p.card);
  final surfaceAlt = tint(p.muted);
  final grounds = [background, surface, surfaceAlt];
  // Words move toward the far end of the ground: black in light, white in
  // dark.
  final far = dark ? _white : _black;
  final text1 = _settle(tint(p.text1), grounds, 7, far);
  final text2 = _settle(tint(p.text2), grounds, 4.5, far);
  final controlBorder = _settle(tint(p.input), grounds, 3, far);
  final textInverse = dark ? background : _white;

  // The primary: opaque, a mark at 3:1 on the ground, and a fill its label
  // reads on at 4.5:1 in white or in the ink, whichever reads better; where
  // neither does, the fill moves away from the label until it reads.
  var fill = _settle(primary.withValues(alpha: 1), [background], 3, far);
  final inks = [_white, dark ? background : text1];
  Color label(Color on) =>
      _contrast(inks[0], on) >= _contrast(inks[1], on) ? inks[0] : inks[1];
  var onAccent = label(fill);
  if (_contrast(onAccent, fill) < 4.5) {
    final away = onAccent.computeLuminance() > 0.5 ? _black : _white;
    fill = _settle(fill, [onAccent], 4.5, away);
    onAccent = label(fill);
  }
  final accentSubtle = Color.lerp(background, fill, dark ? 0.16 : 0.1)!;
  final accentInk = _settle(fill, [...grounds, accentSubtle], 4.5, far);

  _Tone settled(_Tone tone) {
    final mark = _settle(tone.fill, [background], 3, far);
    return (
      fill: mark,
      subtle: tone.subtle,
      ink: _settle(tone.ink, [background, surface, tone.subtle], 4.5, far),
    );
  }

  final danger = settled(_apart(fill, dark ? _dangersDark : _dangersLight));
  final warning = settled(_apart(fill, dark ? _warningsDark : _warningsLight));
  final success = settled((
    fill: p.success,
    subtle: p.successSubtle,
    ink: p.successInk,
  ));
  // The danger fill carries the destructive button's label.
  final dangerFill = _settle(
    danger.fill,
    [textInverse],
    4.5,
    dark ? _white : _black,
  );

  return MinimalColors(
    brightness: brightness,
    background: background,
    card: surface,
    muted: surfaceAlt,
    sunken: tint(p.sunken),
    surfaceInverse: text1,
    border: tint(p.border),
    borderStrong: tint(p.borderStrong),
    input: controlBorder,
    foreground: text1,
    mutedForeground: text2,
    textTertiary: tint(p.text3),
    textInverse: textInverse,
    primary: fill,
    primaryForeground: onAccent,
    primarySubtle: accentSubtle,
    primaryInk: accentInk,
    success: success.fill,
    onSuccess: dark ? textInverse : text1,
    successSubtle: success.subtle,
    successInk: success.ink,
    warning: warning.fill,
    warningSubtle: warning.subtle,
    warningInk: warning.ink,
    destructive: dangerFill,
    destructiveForeground: textInverse,
    destructiveSubtle: danger.subtle,
    destructiveInk: danger.ink,
    info: accentInk,
    overlay: p.overlay,
    ring: fill,
    selection: accentSubtle,
  );
}
