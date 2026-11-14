import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind, lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart'
    show GestureVelocityTrackerBuilder, MultitouchDragStrategy;
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:ui_core/host.dart';

import 'component_themes.dart';
import 'fonts.dart';

import 'internal/rest_ring.dart';
import 'internal/themes/atrium.g.dart';
import 'internal/themes/frost.g.dart';
import 'internal/themes/instrument.g.dart';
import 'internal/themes/native_neutral.g.dart';
import 'internal/themes/platinum.g.dart';
import 'internal/themes/wayfinding.g.dart';
import 'knobs.dart';
import 'materials.dart';

export 'component_themes.dart';
export 'fonts.dart' show frostedFontFamily, frostedLoadFonts;
export 'knobs.dart';

/// Design tokens and theme assembly: the only styling vocabulary a Frosted
/// page may use.
///
/// Fixed scales (spacing, corners, icon size, motion) are compile-time
/// consts. Theme-dependent tokens (colour, the glass, the spectrum, the
/// washes of light, shadow, type, the shape roles) live on [FrostedThemeData],
/// a
/// plain value the app mounts once through `FrostedHost` as a [FrostedTheme]
/// (an `InheritedTheme`) and every widget reads via `context.frostedTheme`.
/// Pages never write raw numbers, hex colours or TextStyles; everything
/// routes through this file's names.
///
/// The theme instances come from [FrostedThemeData.preset]: `prism`, the look
/// as
/// its source stylesheet sets it (its custom properties and
/// literal colours, written in `_Source` at the end of this file under their
/// own names, with the role mapping and the judgment calls in its header;
/// its dark appearance is DESIGNED, in `_Night`), and six of Cody's catalog
/// themes (`cody/themes/<id>/tokens.json`, ThemeTokens v2 records whose light
/// and dark are both designed, baked by `scripts/baked-themes.ts` into
/// `internal/themes/`) dressed in the same roles through
/// `FrostedThemeData._fromTokens`: `quartz` (platinum), `garnet` (atrium),
/// `glacier`
/// (frost), `cobalt` (native-neutral), `jade` (wayfinding) and `copper`
/// (instrument). Nothing else constructs a [FrostedThemeData].

/// The spacing scale: the 4 point grid and the half steps the source pads
/// its rows, chips and tiles in (6, 10, 14).
abstract final class FrostedSpacing {
  /// A step of 2.
  static const double s2 = 2;

  /// A step of 4.
  static const double s4 = 4;

  /// A step of 6.
  static const double s6 = 6;

  /// A step of 8.
  static const double s8 = 8;

  /// A step of 10.
  static const double s10 = 10;

  /// A step of 12.
  static const double s12 = 12;

  /// A step of 14.
  static const double s14 = 14;

  /// A step of 16.
  static const double s16 = 16;

  /// A step of 20.
  static const double s20 = 20;

  /// A step of 24.
  static const double s24 = 24;

  /// A step of 28.
  static const double s28 = 28;

  /// A step of 32.
  static const double s32 = 32;

  /// A step of 40.
  static const double s40 = 40;

  /// A step of 48.
  static const double s48 = 48;

  /// A step of 56.
  static const double s56 = 56;

  /// A step of 64.
  static const double s64 = 64;
}

/// Corner radii, and the look's outlines at four of them ([extraSmall],
/// [small], [medium], [large]) and round ([full]). The source's language is the tile (18 on a phone, 20 on the desktop), the
/// inner pane (10, 12 on the desktop), the field well (12), the squircle of a
/// monogram (11, 17 large), the sheet (22; 20 as a dialog), the menu and the
/// toast (16), the ticket (10) and round (chips, buttons, the tab bar's
/// tabs).
abstract final class FrostedCorners {
  /// A corner of 2.
  static const double r2 = 2;

  /// A corner of 6.
  static const double r6 = 6;

  /// A corner of 9.
  static const double r9 = 9;

  /// A corner of 10.
  static const double r10 = 10;

  /// A corner of 11.
  static const double r11 = 11;

  /// A corner of 12.
  static const double r12 = 12;

  /// A corner of 14.
  static const double r14 = 14;

  /// A corner of 16.
  static const double r16 = 16;

  /// A corner of 17.
  static const double r17 = 17;

  /// A corner of 18.
  static const double r18 = 18;

  /// A corner of 20.
  static const double r20 = 20;

  /// A corner of 22.
  static const double r22 = 22;

  /// A corner as round as the part is short: a pill.
  static const double rFull = 999;

  /// An inner pane's and a picture's outline: [r10].
  static const OutlinedBorder extraSmall = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(r10)),
  );

  /// A field's, a well's and an option's outline: [r12].
  static const OutlinedBorder small = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(r12)),
  );

  /// A tile's and a card's outline: [r18].
  static const OutlinedBorder medium = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(r18)),
  );

  /// A dialog's and a sheet's outline: [r22].
  static const OutlinedBorder large = RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(r22)),
  );

  /// What is round by its role (a chip, a button, a tab): a stadium.
  static const OutlinedBorder full = StadiumBorder();
}

/// Glyph sizes: a pending mark's (12), a chip's and a crumb's (14), a link's
/// and a row chevron's (16), a button's and a round button's (18), the body
/// glyph and a tab's (20), a large token's (24) and the done check's (32).
abstract final class FrostedIconSize {
  /// A glyph 12 across.
  static const double i12 = 12;

  /// A glyph 14 across.
  static const double i14 = 14;

  /// A glyph 16 across.
  static const double i16 = 16;

  /// A glyph 18 across.
  static const double i18 = 18;

  /// A glyph 20 across.
  static const double i20 = 20;

  /// A glyph 24 across.
  static const double i24 = 24;

  /// A glyph 32 across.
  static const double i32 = 32;
}

/// Frosted's timing: [fast] for a control turning to its new state (a tick,
/// a switch, a chosen segment), [base] for what moves within the page and
/// what rises over it (a toast, a menu, a sheet), [slow] for a figure
/// counting to its value; every one eased out on [curve]. The look's are
/// [look]; read them through [of], which answers [still]
/// under Reduce Motion (`MediaQuery.disableAnimations`).
///
/// ```dart
/// final motion = FrostedMotion.of(context);
/// AnimatedOpacity(opacity: shown ? 1 : 0, duration: motion.base, curve: motion.curve, child: child);
/// ```
@immutable
class FrostedMotion with Diagnosticable {
  /// The timings; the look's unless named.
  const FrostedMotion({
    this.fast = const Duration(milliseconds: 120),
    this.base = const Duration(milliseconds: 200),
    this.slow = const Duration(milliseconds: 320),
    this.curve = Curves.easeOutCubic,
  });

  /// The look's own: 120, 200 and 320 ms, eased out.
  static const FrostedMotion look = FrostedMotion();

  /// Every timing a cut: what [of] answers under Reduce Motion.
  static const FrostedMotion still = FrostedMotion(
    fast: Duration.zero,
    base: Duration.zero,
    slow: Duration.zero,
  );

  /// A control turning to its new state.
  final Duration fast;

  /// What moves within the page, or rises over it.
  final Duration base;

  /// A figure counting to its value.
  final Duration slow;

  /// The easing every timing runs on.
  final Curve curve;

  /// Whether anything moves: false for [still].
  bool get moves => fast > Duration.zero || base > Duration.zero;

  /// The timings in force at [context]: the look's, or [still] under
  /// Reduce Motion (`MediaQuery.disableAnimations`; a test holds a spinner
  /// still with `FakeAccessibilityFeatures(disableAnimations: true)`).
  static FrostedMotion of(BuildContext context) =>
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? still : look;

  /// This with the named timings changed.
  FrostedMotion copyWith({
    Duration? fast,
    Duration? base,
    Duration? slow,
    Curve? curve,
  }) => FrostedMotion(
    fast: fast ?? this.fast,
    base: base ?? this.base,
    slow: slow ?? this.slow,
    curve: curve ?? this.curve,
  );

  /// Between [a] and [b]: timings ease, the curve changes at the middle.
  static FrostedMotion lerp(FrostedMotion a, FrostedMotion b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    Duration d(Duration x, Duration y) => Duration(
      microseconds: lerpDouble(x.inMicroseconds, y.inMicroseconds, t)!.round(),
    );
    return FrostedMotion(
      fast: d(a.fast, b.fast),
      base: d(a.base, b.base),
      slow: d(a.slow, b.slow),
      curve: t < .5 ? a.curve : b.curve,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FrostedMotion &&
      other.fast == fast &&
      other.base == base &&
      other.slow == slow &&
      other.curve == curve;

  @override
  int get hashCode => Object.hash(fast, base, slow, curve);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Duration>('fast', fast))
      ..add(DiagnosticsProperty<Duration>('base', base))
      ..add(DiagnosticsProperty<Duration>('slow', slow))
      ..add(DiagnosticsProperty<Curve>('curve', curve));
  }
}

/// The paddings Frosted's parts use, on the spacing scale.
abstract final class FrostedInsets {
  /// 6 on every side.
  static const EdgeInsets all6 = EdgeInsets.all(FrostedSpacing.s6);

  /// 8 on every side.
  static const EdgeInsets all8 = EdgeInsets.all(FrostedSpacing.s8);

  /// 10 on every side.
  static const EdgeInsets all10 = EdgeInsets.all(FrostedSpacing.s10);

  /// 12 on every side.
  static const EdgeInsets all12 = EdgeInsets.all(FrostedSpacing.s12);

  /// 16 on every side.
  static const EdgeInsets all16 = EdgeInsets.all(FrostedSpacing.s16);

  /// 20 on every side.
  static const EdgeInsets all20 = EdgeInsets.all(FrostedSpacing.s20);

  /// 10 at the start and the end.
  static const EdgeInsets horizontal10 = EdgeInsets.symmetric(
    horizontal: FrostedSpacing.s10,
  );

  /// 14 at the start and the end.
  static const EdgeInsets horizontal14 = EdgeInsets.symmetric(
    horizontal: FrostedSpacing.s14,
  );

  /// 16 at the start and the end.
  static const EdgeInsets horizontal16 = EdgeInsets.symmetric(
    horizontal: FrostedSpacing.s16,
  );

  /// 20 at the start and the end.
  static const EdgeInsets horizontal20 = EdgeInsets.symmetric(
    horizontal: FrostedSpacing.s20,
  );

  /// 6 over and under.
  static const EdgeInsets vertical6 = EdgeInsets.symmetric(
    vertical: FrostedSpacing.s6,
  );

  /// 8 over and under.
  static const EdgeInsets vertical8 = EdgeInsets.symmetric(
    vertical: FrostedSpacing.s8,
  );

  /// A tile's padding on a phone (`--pad`): 16 all round.
  static const EdgeInsets tile = EdgeInsets.all(FrostedSpacing.s16);

  /// A tile's padding on the desktop: 20 all round.
  static const EdgeInsets tileWide = EdgeInsets.all(FrostedSpacing.s20);

  /// A page's room round its content on a phone: the 16 gutter at its
  /// sides, 20 under its last tile (the top bar brings its own 10 above).
  static const EdgeInsets screen = EdgeInsets.fromLTRB(
    FrostedSpacing.s16,
    0,
    FrostedSpacing.s16,
    FrostedSpacing.s20,
  );

  /// A page's room on the desktop: the 32 gutter at its sides, 40 under
  /// (the top band brings its 32 above).
  static const EdgeInsets screenWide = EdgeInsets.fromLTRB(
    FrostedSpacing.s32,
    0,
    FrostedSpacing.s32,
    FrostedSpacing.s40,
  );
}

/// A fixed spacer of one [FrostedSpacing] step, as wide as it is tall.
///
/// ```dart
/// Column(children: [title, const FrostedGap(FrostedSpacing.s12),
/// ```
/// body])
class FrostedGap extends StatelessWidget {
  /// A spacer [size] across and [size] tall.
  const FrostedGap(this.size, {super.key});

  /// Its width and its height.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Responsive layout invariants shared by Frosted apps.
abstract final class FrostedBreakpoints {
  /// The width from which the app is the desktop one, as the source switches
  /// at 1024: the sidebar replaces the tab bar, the gutter grows to 32, the
  /// tiles to 20 corners and 20 padding on a 16 gap, the main a 12-column
  /// grid, the hero money to 96, a sheet becomes a centred dialog and a
  /// detail's bar a crumb over a large title.
  static const double wide = 1024;

  /// The touch-target floor under a pointer: a mouse or a trackpad.
  static const double minHitTarget = 44;

  /// The touch-target floor under a finger, as Material pads its targets on
  /// a phone.
  static const double touchHitTarget = 48;

  /// The floor a target answers on [context]'s platform: [touchHitTarget]
  /// on Android, iOS and Fuchsia, [minHitTarget] on the desktop.
  static double hitTargetOf(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => touchHitTarget,
        _ => minHitTarget,
      };

  /// The sidebar's width on the desktop.
  static const double sidebar = 240;

  /// The desktop main grid's columns.
  static const int columns = 12;

  /// Whether the window is the desktop one.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  /// The page gutter at [context]: 16 on a phone, 32 on the desktop.
  static double gutter(BuildContext context) =>
      isWide(context) ? FrostedSpacing.s32 : FrostedSpacing.s16;

  /// The gap between tiles (`--gap`): 10 on a phone, 16 on the desktop.
  static double gap(BuildContext context) =>
      isWide(context) ? FrostedSpacing.s16 : FrostedSpacing.s10;

  /// A tile's padding (`--pad`): 16 on a phone, 20 on the desktop.
  static double pad(BuildContext context) =>
      isWide(context) ? FrostedSpacing.s20 : FrostedSpacing.s16;

  /// A tile's corner (`--r-tile`): 18 on a phone, 20 on the desktop.
  static double tileRadius(BuildContext context) =>
      isWide(context) ? FrostedCorners.r20 : FrostedCorners.r18;

  /// An inner pane's corner (`--r-in`): 10 on a phone, 12 on the desktop.
  static double innerRadius(BuildContext context) =>
      isWide(context) ? FrostedCorners.r12 : FrostedCorners.r10;
}

/// One text slot of a baked catalog theme: the face it names, its size,
/// weight (100..900), line height as a multiple and tracking in points.
@immutable
final class FrostedTokenType {
  /// A type role of its [font], [size], [weight], [height] and [letterSpacing].
  const FrostedTokenType({
    required this.font,
    required this.size,
    required this.weight,
    required this.height,
    required this.letterSpacing,
  });

  /// The family.
  final String font;

  /// The size, in points.
  final double size;

  /// The weight, 100 to 900.
  final int weight;

  /// The line height, a multiple of [size].
  final double height;

  /// The tracking, in points.
  final double letterSpacing;
}

/// One elevation layer of a baked catalog theme.
@immutable
final class FrostedTokenShadow {
  /// A shadow of its [color], [blur], [offsetY] and [spread].
  const FrostedTokenShadow({
    required this.color,
    required this.blur,
    required this.offsetY,
    required this.spread,
  });

  /// Its colour.
  final Color color;

  /// How soft it is.
  final double blur;

  /// How far below the face it falls.
  final double offsetY;

  /// How far past the face it reaches.
  final double spread;

  /// This layer as a Flutter shadow.
  BoxShadow get shadow => BoxShadow(
    color: color,
    blurRadius: blur,
    offset: Offset(0, offsetY),
    spreadRadius: spread,
  );
}

/// The colours of one appearance of a baked catalog theme: Cody's role names,
/// which is what ThemeTokens v2 records.
@immutable
final class FrostedTokenColors {
  /// One appearance's colours.
  const FrostedTokenColors({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.onDanger,
    required this.dangerSubtle,
    required this.overlay,
    required this.accentText,
    required this.emphasis,
    required this.onEmphasis,
    required this.shadowSm,
    required this.shadowMd,
    required this.shadowLg,
  });

  /// The canvas every page stands on.
  final Color background;

  /// A tile's ground.
  final Color surface;

  /// A quieter ground: a well, a wash.
  final Color surfaceAlt;

  /// The ink slab's ground (a toast, the act).
  final Color surfaceInverse;

  /// The hairline.
  final Color border;

  /// A heavier rule.
  final Color borderStrong;

  /// The words.
  final Color textPrimary;

  /// The second line's words.
  final Color textSecondary;

  /// Quiet words: placeholders, captions.
  final Color textTertiary;

  /// Words on [surfaceInverse].
  final Color textInverse;

  /// The accent.
  final Color accent;

  /// Words and glyphs on [accent].
  final Color onAccent;

  /// The accent's wash (a chosen row).
  final Color accentSubtle;

  /// Good news.
  final Color success;

  /// Words and glyphs on [success].
  final Color onSuccess;

  /// Good news's wash.
  final Color successSubtle;

  /// A warning.
  final Color warning;

  /// A warning's wash.
  final Color warningSubtle;

  /// A loss or an error.
  final Color danger;

  /// Words and glyphs on [danger].
  final Color onDanger;

  /// An error's wash.
  final Color dangerSubtle;

  /// The scrim under a sheet or a dialog.
  final Color overlay;

  /// The accent set as words on the canvas.
  final Color accentText;

  /// The ink act's fill.
  final Color emphasis;

  /// Words and glyphs on [emphasis].
  final Color onEmphasis;

  /// A small lift's shadows.
  final List<FrostedTokenShadow> shadowSm;

  /// A middle lift's shadows.
  final List<FrostedTokenShadow> shadowMd;

  /// A large lift's shadows.
  final List<FrostedTokenShadow> shadowLg;

  /// This with the named roles replaced.
  FrostedTokenColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accent,
    Color? onAccent,
    Color? accentSubtle,
    Color? success,
    Color? onSuccess,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? onDanger,
    Color? dangerSubtle,
    Color? overlay,
    Color? accentText,
    Color? emphasis,
    Color? onEmphasis,
    List<FrostedTokenShadow>? shadowSm,
    List<FrostedTokenShadow>? shadowMd,
    List<FrostedTokenShadow>? shadowLg,
  }) => FrostedTokenColors(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSubtle: accentSubtle ?? this.accentSubtle,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successSubtle: successSubtle ?? this.successSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerSubtle: dangerSubtle ?? this.dangerSubtle,
    overlay: overlay ?? this.overlay,
    accentText: accentText ?? this.accentText,
    emphasis: emphasis ?? this.emphasis,
    onEmphasis: onEmphasis ?? this.onEmphasis,
    shadowSm: shadowSm ?? this.shadowSm,
    shadowMd: shadowMd ?? this.shadowMd,
    shadowLg: shadowLg ?? this.shadowLg,
  );
}

/// The corner language of a baked catalog theme.
@immutable
final class FrostedTokenShape {
  /// The look's corners.
  const FrostedTokenShape({
    required this.cardRadius,
    required this.controlRadius,
    required this.smallRadius,
    required this.sheetRadius,
  });

  /// A tile's corner.
  final double cardRadius;

  /// A control's corner.
  final double controlRadius;

  /// A small part's corner.
  final double smallRadius;

  /// A sheet's corner.
  final double sheetRadius;
}

/// A ThemeTokens v2 record, baked into constants
/// (`internal/themes/<id>.g.dart`, drift-gated against the JSON by the
/// catalog's tests): both appearances, the twelve type slots and the shape.
/// `FrostedThemeData._fromTokens` dresses the system in one.
@immutable
final class FrostedTokens {
  /// A look's raw tokens: colours in both appearances, the type roles and the
  /// corners.
  const FrostedTokens({
    required this.light,
    required this.dark,
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
    required this.shape,
  });

  /// The light appearance's colours.
  final FrostedTokenColors light;

  /// The dark appearance's colours.
  final FrostedTokenColors dark;

  /// The largest figure's type.
  final FrostedTokenType giant;

  /// A hero figure's type.
  final FrostedTokenType hero;

  /// A display title's type.
  final FrostedTokenType display;

  /// The first heading's type.
  final FrostedTokenType h1;

  /// The second heading's type.
  final FrostedTokenType h2;

  /// The third heading's type.
  final FrostedTokenType h3;

  /// Large body text's type.
  final FrostedTokenType bodyLarge;

  /// Body text's type.
  final FrostedTokenType body;

  /// Small body text's type.
  final FrostedTokenType bodySmall;

  /// A caption's type.
  final FrostedTokenType caption;

  /// A control's label's type.
  final FrostedTokenType label;

  /// Fixed-width text's type.
  final FrostedTokenType mono;

  /// The corners.
  final FrostedTokenShape shape;
}

/// Which way money moved: how a figure is inked and an amount is signed.
enum FrostedMoneyFlow {
  /// A standing figure: a balance, a net worth, a goal's savings. Ink; an
  /// amount carries no plus.
  balance,

  /// Money spent: a purchase, a month's spending. Ink; an amount carries
  /// its true minus.
  outflow,

  /// Money in: pay, a refund. The green of money in, with its plus.
  inflow,

  /// A move between the owner's own accounts: the quiet ink, no sign.
  transfer,
}

/// The tone a chip, a nudge, a note or a snack bar wears, each an ink on
/// its own tint: the quiet wash, information's cool blue, success's green,
/// a warning's amber or danger's red.
enum FrostedTone {
  /// Nothing to say beyond the words: the wash and the secondary ink.
  quiet,

  /// Information: the cool blue.
  info,

  /// Something done or gained: the green.
  success,

  /// Something to watch: the amber.
  warning,

  /// Something wrong or lost: the red.
  danger,
}

/// One hue of the spectrum, as the source's `.c-*` classes name it: two
/// close stops ([a], [b]) for its marks, a dark ink of the same hue ([ink])
/// for words and figures on its tint, a deeper ink ([inkDeep]) for labels set
/// on the marks themselves, and three alphas of its hue: [tint] (fills),
/// [tintSolid] (small solids) and [edge] (hairlines).
@immutable
final class FrostedHue {
  /// A hue of its stops, inks and alphas.
  const FrostedHue({
    required this.a,
    required this.b,
    required this.ink,
    required this.inkDeep,
    required this.tint,
    required this.tintSolid,
    required this.edge,
  });

  /// A hue of the spectrum turned to [degrees] on the wheel, at the source's
  /// pastel lightness, for a record that names no spectrum: its marks at 74%
  /// and 72% lightness fifteen degrees apart, its ink eased from 36% toward
  /// [toward] until it reads 4.5:1 on its tint over [ground] (and over each
  /// of [also], the page's other grounds), its deep ink at 24%.
  factory FrostedHue.turned(
    double degrees,
    double saturation, {
    required Color ground,
    required Color toward,
    required bool dark,
    List<Color> also = const <Color>[],
  }) {
    Color hsl(double h, double s, double l) =>
        HSLColor.fromAHSL(1, h % 360, s, l).toColor();
    final a = hsl(degrees, saturation * 0.78, 0.74);
    final b = hsl(degrees + 15, saturation * 0.72, 0.72);
    final tint = a.withValues(alpha: 0.2);
    final ink = FrostedThemeData._reach(
      hsl(degrees, saturation, dark ? 0.8 : 0.36),
      toward,
      [
        for (final g in [ground, ...also]) Color.alphaBlend(tint, g),
      ],
      4.5,
    );
    return FrostedHue(
      a: a,
      b: b,
      ink: ink,
      // The deep ink stands on the marks themselves (a share's plate): a
      // pale hue's 24% is eased darker until it reads there, with room for
      // the pixel.
      inkDeep: FrostedThemeData._reach(
        hsl(degrees, saturation, 0.24),
        hsl(degrees, saturation, 0.08),
        [a, b],
        4.6,
      ),
      tint: tint,
      tintSolid: a.withValues(alpha: 0.26),
      edge: a.withValues(alpha: 0.34),
    );
  }

  /// This hue on a dark ground: the marks and the deep ink kept (the marks
  /// are pastel, the deep ink reads on them), the ink lifted toward [toward]
  /// until it reads 4.5:1 on its tint over [ground] and each of [also].
  FrostedHue onDark({
    required Color ground,
    required Color toward,
    List<Color> also = const <Color>[],
  }) => FrostedHue(
    a: a,
    b: b,
    ink: FrostedThemeData._reach(Color.lerp(a, toward, 0.45)!, toward, [
      for (final g in [ground, ...also]) Color.alphaBlend(tint, g),
    ], 4.5),
    inkDeep: inkDeep,
    tint: tint,
    tintSolid: tintSolid,
    edge: edge,
  );

  /// This hue lit from within on a dark ground, the designed night's rule:
  /// the marks and the deep ink kept (the marks are pastel and glow on the
  /// dark; the deep ink reads on them), the fill, the small solid and the
  /// hairline a step stronger ([glow], the hairline half that) so a tinted
  /// pane holds its light, a fill of the ink turned to white at its alpha,
  /// and the ink eased from the first mark toward [toward] until it reads
  /// 4.5:1 on its fill over [ground] and each of [also].
  FrostedHue lit({
    required Color ground,
    required Color toward,
    double glow = 1.35,
    List<Color> also = const <Color>[],
  }) {
    Color up(Color c, double by) {
      final base = c.computeLuminance() < 0.1
          ? const Color(0xFFFFFFFF).withValues(alpha: c.a)
          : c;
      return base.withValues(alpha: math.min(1, base.a * by));
    }

    final fill = up(tint, glow);
    return FrostedHue(
      a: a,
      b: b,
      ink: FrostedThemeData._reach(Color.lerp(a, toward, 0.35)!, toward, [
        for (final g in [ground, ...also]) Color.alphaBlend(fill, g),
      ], 4.5),
      inkDeep: inkDeep,
      tint: fill,
      tintSolid: up(tintSolid, glow),
      edge: up(edge, 1 + (glow - 1) / 2),
    );
  }

  /// The first stop of the hue's marks.
  final Color a;

  /// The second stop of the hue's marks.
  final Color b;

  /// The hue's ink for words and figures on its tint (`--k`).
  final Color ink;

  /// The deeper ink for labels set on the marks themselves (`--k2`).
  final Color inkDeep;

  /// The hue's fill (`--t`).
  final Color tint;

  /// The hue's small solid (`--t2`): a monogram, a token, a legend dot.
  final Color tintSolid;

  /// The hue's hairline (`--e`).
  final Color edge;

  /// A band's light, left to right (`linear-gradient(90deg, a, b)`).
  LinearGradient get band => LinearGradient(colors: [a, b]);

  /// A dot's light, top left to bottom right (`135deg`).
  LinearGradient get dot => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [a, b],
  );

  /// The hue with its ink swapped, for a tone that keeps the marks.
  FrostedHue inked(Color ink) => FrostedHue(
    a: a,
    b: b,
    ink: ink,
    inkDeep: inkDeep,
    tint: tint,
    tintSolid: tintSolid,
    edge: edge,
  );

  /// This with the named values replaced.
  FrostedHue copyWith({
    Color? a,
    Color? b,
    Color? ink,
    Color? inkDeep,
    Color? tint,
    Color? tintSolid,
    Color? edge,
  }) => FrostedHue(
    a: a ?? this.a,
    b: b ?? this.b,
    ink: ink ?? this.ink,
    inkDeep: inkDeep ?? this.inkDeep,
    tint: tint ?? this.tint,
    tintSolid: tintSolid ?? this.tintSolid,
    edge: edge ?? this.edge,
  );

  /// Between [a] and [b], value by value.
  static FrostedHue lerp(FrostedHue a, FrostedHue b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedHue(
      a: Color.lerp(a.a, b.a, t)!,
      b: Color.lerp(a.b, b.b, t)!,
      ink: Color.lerp(a.ink, b.ink, t)!,
      inkDeep: Color.lerp(a.inkDeep, b.inkDeep, t)!,
      tint: Color.lerp(a.tint, b.tint, t)!,
      tintSolid: Color.lerp(a.tintSolid, b.tintSolid, t)!,
      edge: Color.lerp(a.edge, b.edge, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedHue &&
          other.a == a &&
          other.b == b &&
          other.ink == ink &&
          other.inkDeep == inkDeep &&
          other.tint == tint &&
          other.tintSolid == tintSolid &&
          other.edge == edge;

  @override
  int get hashCode =>
      Object.hashAll([a, b, ink, inkDeep, tint, tintSolid, edge]);
}

/// The look's hues, each named for its colour: the eight of the spectrum
/// ([categories], violet round to blue), six iridescent pairs ([objects]),
/// and six more for marks of their own: [emerald], [slate], [turquoise],
/// [lavender], [iris] and [silver]. [FrostedThemeData.hue] reaches the
/// spectrum by index.
@immutable
final class FrostedHues {
  /// Every hue, each named for its colour.
  const FrostedHues({
    required this.periwinkle,
    required this.orchid,
    required this.coral,
    required this.apricot,
    required this.lemon,
    required this.mint,
    required this.teal,
    required this.sky,
    required this.cyan,
    required this.seafoam,
    required this.sunset,
    required this.lagoon,
    required this.azure,
    required this.lime,
    required this.emerald,
    required this.slate,
    required this.turquoise,
    required this.lavender,
    required this.iris,
    required this.silver,
  });

  /// Periwinkle, the spectrum's first hue.
  final FrostedHue periwinkle;

  /// Orchid, the spectrum's second hue.
  final FrostedHue orchid;

  /// Coral, the spectrum's third hue.
  final FrostedHue coral;

  /// Apricot, the spectrum's fourth hue.
  final FrostedHue apricot;

  /// Lemon, the spectrum's fifth hue.
  final FrostedHue lemon;

  /// Mint, the spectrum's sixth hue.
  final FrostedHue mint;

  /// Teal, the spectrum's seventh hue.
  final FrostedHue teal;

  /// Sky, the spectrum's eighth hue.
  final FrostedHue sky;

  /// Cyan into cornflower, the first iridescent hue.
  final FrostedHue cyan;

  /// Seafoam into aqua, the second iridescent hue.
  final FrostedHue seafoam;

  /// Amber into rose, the third iridescent hue.
  final FrostedHue sunset;

  /// Teal into lavender, the fourth iridescent hue.
  final FrostedHue lagoon;

  /// Azure, the fifth iridescent hue: cyan into cornflower as [cyan] is in
  /// the look's own presets; a theme made from an accent turns it further
  /// round the wheel.
  final FrostedHue azure;

  /// Lime into mint, the sixth iridescent hue.
  final FrostedHue lime;

  /// Emerald, green into jade: something coming in or gained.
  final FrostedHue emerald;

  /// Slate, a quiet grey-violet: something that is neither
  /// in nor out.
  final FrostedHue slate;

  /// Turquoise into sky.
  final FrostedHue turquoise;

  /// Lavender into lilac.
  final FrostedHue lavender;

  /// Iris, lavender into rose: the look's own hue, the
  /// credit card's face unless a brand is given.
  final FrostedHue iris;

  /// Silver, a pale grey.
  final FrostedHue silver;

  /// The spectrum's eight hues, violet round to blue, for categories:
  /// periwinkle, orchid, coral, apricot, lemon, mint, teal and sky.
  List<FrostedHue> get categories => [
    periwinkle,
    orchid,
    coral,
    apricot,
    lemon,
    mint,
    teal,
    sky,
  ];

  /// The six iridescent hues, for things kept apart (accounts, goals,
  /// projects): cyan, seafoam, sunset, lagoon, azure and lime.
  List<FrostedHue> get objects => [cyan, seafoam, sunset, lagoon, azure, lime];

  /// Every hue lit from within on a dark ground (see [FrostedHue.lit]).
  FrostedHues lit({required Color ground, required Color toward}) {
    FrostedHue d(FrostedHue h) => h.lit(ground: ground, toward: toward);
    return FrostedHues(
      periwinkle: d(periwinkle),
      orchid: d(orchid),
      coral: d(coral),
      apricot: d(apricot),
      lemon: d(lemon),
      mint: d(mint),
      teal: d(teal),
      sky: d(sky),
      cyan: d(cyan),
      seafoam: d(seafoam),
      sunset: d(sunset),
      lagoon: d(lagoon),
      azure: d(azure),
      lime: d(lime),
      emerald: d(emerald),
      slate: d(slate),
      turquoise: d(turquoise),
      lavender: d(lavender),
      iris: d(iris),
      silver: d(silver),
    );
  }

  /// Every hue on a dark ground (see [FrostedHue.onDark]).
  FrostedHues onDark({required Color ground, required Color toward}) {
    FrostedHue d(FrostedHue h) => h.onDark(ground: ground, toward: toward);
    return FrostedHues(
      periwinkle: d(periwinkle),
      orchid: d(orchid),
      coral: d(coral),
      apricot: d(apricot),
      lemon: d(lemon),
      mint: d(mint),
      teal: d(teal),
      sky: d(sky),
      cyan: d(cyan),
      seafoam: d(seafoam),
      sunset: d(sunset),
      lagoon: d(lagoon),
      azure: d(azure),
      lime: d(lime),
      emerald: d(emerald),
      slate: d(slate),
      turquoise: d(turquoise),
      lavender: d(lavender),
      iris: d(iris),
      silver: d(silver),
    );
  }

  /// This with the named values replaced.
  FrostedHues copyWith({
    FrostedHue? periwinkle,
    FrostedHue? orchid,
    FrostedHue? coral,
    FrostedHue? apricot,
    FrostedHue? lemon,
    FrostedHue? mint,
    FrostedHue? teal,
    FrostedHue? sky,
    FrostedHue? cyan,
    FrostedHue? seafoam,
    FrostedHue? sunset,
    FrostedHue? lagoon,
    FrostedHue? azure,
    FrostedHue? lime,
    FrostedHue? emerald,
    FrostedHue? slate,
    FrostedHue? turquoise,
    FrostedHue? lavender,
    FrostedHue? iris,
    FrostedHue? silver,
  }) => FrostedHues(
    periwinkle: periwinkle ?? this.periwinkle,
    orchid: orchid ?? this.orchid,
    coral: coral ?? this.coral,
    apricot: apricot ?? this.apricot,
    lemon: lemon ?? this.lemon,
    mint: mint ?? this.mint,
    teal: teal ?? this.teal,
    sky: sky ?? this.sky,
    cyan: cyan ?? this.cyan,
    seafoam: seafoam ?? this.seafoam,
    sunset: sunset ?? this.sunset,
    lagoon: lagoon ?? this.lagoon,
    azure: azure ?? this.azure,
    lime: lime ?? this.lime,
    emerald: emerald ?? this.emerald,
    slate: slate ?? this.slate,
    turquoise: turquoise ?? this.turquoise,
    lavender: lavender ?? this.lavender,
    iris: iris ?? this.iris,
    silver: silver ?? this.silver,
  );

  /// Between [a] and [b], value by value.
  static FrostedHues lerp(FrostedHues a, FrostedHues b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedHues(
      periwinkle: FrostedHue.lerp(a.periwinkle, b.periwinkle, t),
      orchid: FrostedHue.lerp(a.orchid, b.orchid, t),
      coral: FrostedHue.lerp(a.coral, b.coral, t),
      apricot: FrostedHue.lerp(a.apricot, b.apricot, t),
      lemon: FrostedHue.lerp(a.lemon, b.lemon, t),
      mint: FrostedHue.lerp(a.mint, b.mint, t),
      teal: FrostedHue.lerp(a.teal, b.teal, t),
      sky: FrostedHue.lerp(a.sky, b.sky, t),
      cyan: FrostedHue.lerp(a.cyan, b.cyan, t),
      seafoam: FrostedHue.lerp(a.seafoam, b.seafoam, t),
      sunset: FrostedHue.lerp(a.sunset, b.sunset, t),
      lagoon: FrostedHue.lerp(a.lagoon, b.lagoon, t),
      azure: FrostedHue.lerp(a.azure, b.azure, t),
      lime: FrostedHue.lerp(a.lime, b.lime, t),
      emerald: FrostedHue.lerp(a.emerald, b.emerald, t),
      slate: FrostedHue.lerp(a.slate, b.slate, t),
      turquoise: FrostedHue.lerp(a.turquoise, b.turquoise, t),
      lavender: FrostedHue.lerp(a.lavender, b.lavender, t),
      iris: FrostedHue.lerp(a.iris, b.iris, t),
      silver: FrostedHue.lerp(a.silver, b.silver, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedHues &&
          other.periwinkle == periwinkle &&
          other.orchid == orchid &&
          other.coral == coral &&
          other.apricot == apricot &&
          other.lemon == lemon &&
          other.mint == mint &&
          other.teal == teal &&
          other.sky == sky &&
          other.cyan == cyan &&
          other.seafoam == seafoam &&
          other.sunset == sunset &&
          other.lagoon == lagoon &&
          other.azure == azure &&
          other.lime == lime &&
          other.emerald == emerald &&
          other.slate == slate &&
          other.turquoise == turquoise &&
          other.lavender == lavender &&
          other.iris == iris &&
          other.silver == silver;

  @override
  int get hashCode => Object.hashAll([
    periwinkle,
    orchid,
    coral,
    apricot,
    lemon,
    mint,
    teal,
    sky,
    cyan,
    seafoam,
    sunset,
    lagoon,
    azure,
    lime,
    emerald,
    slate,
    turquoise,
    lavender,
    iris,
    silver,
  ]);
}

/// The light behind the glass: three faint washes at the top of every
/// screen (`.aurora .blob`), each a blurred disc of one colour, drawn at
/// [strength].
@immutable
final class FrostedLights {
  /// Three washes of light at [strength].
  const FrostedLights({
    required this.lilac,
    required this.rose,
    required this.peach,
    required this.strength,
  });

  /// The first wash, lilac, left of the page.
  final Color lilac;

  /// The second, rose, over the middle.
  final Color rose;

  /// The third, peach, at the right lower down.
  final Color peach;

  /// How strongly the washes are drawn, 0..1 (the source's opacities are
  /// multiplied by it).
  final double strength;

  /// Each wash's opacity at its peak before [strength]: lilac, rose, peach.
  static const List<double> peaks = [0.85, 0.78, 0.75];

  /// Each wash's share of its colour at its peak as the backdrop
  /// ([FrostedBackdrop.dawn]) paints it, before [strength] and
  /// [backdropBoost]: lilac, rose, peach.
  static const List<double> backdropShares = [0.95, 0.85, 0.85];

  /// How much more strongly the backdrop draws its washes than [strength]
  /// says: by day, and by [night].
  static double backdropBoost({required bool night}) => night ? 1.1 : 1.35;

  /// How much of a wash reaches into another's peak: its tail there.
  static const double _crossing = 0.25;

  /// [ground] under each wash at its peak, as the page's washes and the
  /// backdrop draw it (whichever is deeper), and under that peak with
  /// another wash's tail crossing it: the deepest colours a word on the page
  /// can stand on, and what the inks are held to. [night] is the backdrop's
  /// night drawing.
  List<Color> peaksOver(Color ground, {bool night = false}) {
    final washes = [lilac, rose, peach];
    Color at(int i, double share) {
      final w = washes[i];
      final most = math.max(
        peaks[i],
        backdropShares[i] * backdropBoost(night: night),
      );
      return w.withValues(alpha: math.min(1.0, w.a * most * strength) * share);
    }

    return [
      for (var i = 0; i < 3; i++) ...[
        Color.alphaBlend(at(i, 1), ground),
        for (var j = 0; j < 3; j++)
          if (j != i)
            Color.alphaBlend(
              at(j, _crossing),
              Color.alphaBlend(at(i, 1), ground),
            ),
      ],
    ];
  }

  /// This with the named values replaced.
  FrostedLights copyWith({
    Color? lilac,
    Color? rose,
    Color? peach,
    double? strength,
  }) => FrostedLights(
    lilac: lilac ?? this.lilac,
    rose: rose ?? this.rose,
    peach: peach ?? this.peach,
    strength: strength ?? this.strength,
  );

  /// Between [a] and [b], value by value.
  static FrostedLights lerp(FrostedLights a, FrostedLights b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedLights(
      lilac: Color.lerp(a.lilac, b.lilac, t)!,
      rose: Color.lerp(a.rose, b.rose, t)!,
      peach: Color.lerp(a.peach, b.peach, t)!,
      strength: lerpDouble(a.strength, b.strength, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedLights &&
          other.lilac == lilac &&
          other.rose == rose &&
          other.peach == peach &&
          other.strength == strength;

  @override
  int get hashCode => Object.hashAll([lilac, rose, peach, strength]);
}

/// The inks the charts are drawn in (`charts.py`): the line's three stops,
/// the gridlines, the area under a line, the annotation ink, the pace
/// dashes and the projection dashes.
@immutable
final class FrostedChartInks {
  /// The charts' inks.
  const FrostedChartInks({
    required this.line,
    required this.grid,
    required this.areaFrom,
    required this.areaTo,
    required this.label,
    required this.pace,
    required this.endDot,
    required this.endRing,
  });

  /// The line's light, left to right (stops at 0, 0.55, 1).
  final List<Color> line;

  /// The gridlines and a chart's floor.
  final Color grid;

  /// The light under a line, from the line down to nothing.
  final Color areaFrom;

  /// See [areaFrom].
  final Color areaTo;

  /// An annotation on a mark.
  final Color label;

  /// The pace line's dashes.
  final Color pace;

  /// The dot at a line's end and the ring round it.
  final Color endDot;

  /// See [endDot].
  final Color endRing;

  /// The line's light as a shader's gradient.
  LinearGradient get lineGradient =>
      LinearGradient(colors: line, stops: const [0, 0.55, 1]);

  /// The light under the line as a shader's gradient, top to foot.
  LinearGradient get area => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [areaFrom, areaTo],
  );

  /// This with the named values replaced.
  FrostedChartInks copyWith({
    List<Color>? line,
    Color? grid,
    Color? areaFrom,
    Color? areaTo,
    Color? label,
    Color? pace,
    Color? endDot,
    Color? endRing,
  }) => FrostedChartInks(
    line: line ?? this.line,
    grid: grid ?? this.grid,
    areaFrom: areaFrom ?? this.areaFrom,
    areaTo: areaTo ?? this.areaTo,
    label: label ?? this.label,
    pace: pace ?? this.pace,
    endDot: endDot ?? this.endDot,
    endRing: endRing ?? this.endRing,
  );

  /// Between [a] and [b], value by value.
  static FrostedChartInks lerp(
    FrostedChartInks a,
    FrostedChartInks b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedChartInks(
      line: _lerpColors(a.line, b.line, t),
      grid: Color.lerp(a.grid, b.grid, t)!,
      areaFrom: Color.lerp(a.areaFrom, b.areaFrom, t)!,
      areaTo: Color.lerp(a.areaTo, b.areaTo, t)!,
      label: Color.lerp(a.label, b.label, t)!,
      pace: Color.lerp(a.pace, b.pace, t)!,
      endDot: Color.lerp(a.endDot, b.endDot, t)!,
      endRing: Color.lerp(a.endRing, b.endRing, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedChartInks &&
          listEquals(other.line, line) &&
          other.grid == grid &&
          other.areaFrom == areaFrom &&
          other.areaTo == areaTo &&
          other.label == label &&
          other.pace == pace &&
          other.endDot == endDot &&
          other.endRing == endRing;

  @override
  int get hashCode => Object.hashAll([
    ...line,
    grid,
    areaFrom,
    areaTo,
    label,
    pace,
    endDot,
    endRing,
  ]);
}

/// The light the source lays on its marks and its objects, written in
/// place in its CSS rather than as custom properties: the sheens and inset
/// lights of a band and a tube, the rules and beads of a statement and a
/// visit strip, the specular bands, hazes and rims of the cards and the
/// mosaic's panes, the debit card's blue, the frost of a frozen card and
/// the glass pill on a card. [day] is the source's own values (white at
/// its alphas, the ink at its alphas); [night] is the dark appearance's,
/// designed for light through dark glass: the sheens dimmed so a pastel
/// mark glows instead of chalking, the ink's hairlines turned to white at
/// the same weight, the cards and the frost smoked.
@immutable
final class FrostedSheens {
  /// The sheens, rims and washes of the glass.
  const FrostedSheens({
    required this.bandSheen,
    required this.bandLight,
    required this.bandShade,
    required this.leaveFill,
    required this.arriveSheen,
    required this.arriveRing,
    required this.tubeSheen,
    required this.tubeLight,
    required this.tubeRing,
    required this.rule,
    required this.beadRing,
    required this.stripRule,
    required this.stripTick,
    required this.struck,
    required this.halo,
    required this.merchantCard,
    required this.bead,
    required this.cardSheen,
    required this.specular,
    required this.debitSpecular,
    required this.paneSpecular,
    required this.paneHaze,
    required this.newGoalFill,
    required this.newGoalRing,
    required this.ghostEdge,
    required this.debitFrom,
    required this.debitTo,
    required this.debitShade,
    required this.frozenShade,
    required this.frostStreak,
    required this.frostHaze,
    required this.frostWash,
    required this.frostGlow,
    required this.frostRing,
    required this.frostMarkFill,
    required this.frostMarkRing,
    required this.frostMarkShade,
    required this.pillFill,
    required this.pillRing,
    required this.pillEdge,
  });

  /// These sheens on another night: the halo round a bead in the canvas
  /// [ground], a merchant's card in the [glass], the statement's bead the
  /// solid [bead], a struck-out figure in the [ink], each at this set's
  /// alpha; the white lights and the smoked cards kept.
  FrostedSheens on({
    required Color ground,
    required Color glass,
    required Color bead,
    required Color ink,
  }) => FrostedSheens(
    bandSheen: bandSheen,
    bandLight: bandLight,
    bandShade: bandShade,
    leaveFill: leaveFill,
    arriveSheen: arriveSheen,
    arriveRing: arriveRing,
    tubeSheen: tubeSheen,
    tubeLight: tubeLight,
    tubeRing: tubeRing,
    rule: rule,
    beadRing: beadRing,
    stripRule: stripRule,
    stripTick: stripTick,
    struck: ink.withValues(alpha: struck.a),
    halo: ground.withValues(alpha: halo.a),
    merchantCard: glass.withValues(alpha: merchantCard.a),
    bead: bead,
    cardSheen: cardSheen,
    specular: specular,
    debitSpecular: debitSpecular,
    paneSpecular: paneSpecular,
    paneHaze: paneHaze,
    newGoalFill: newGoalFill,
    newGoalRing: newGoalRing,
    ghostEdge: ghostEdge,
    debitFrom: debitFrom,
    debitTo: debitTo,
    debitShade: debitShade,
    frozenShade: frozenShade,
    frostStreak: frostStreak,
    frostHaze: frostHaze,
    frostWash: frostWash,
    frostGlow: frostGlow,
    frostRing: frostRing,
    frostMarkFill: frostMarkFill,
    frostMarkRing: frostMarkRing,
    frostMarkShade: frostMarkShade,
    pillFill: pillFill,
    pillRing: pillRing,
    pillEdge: pillEdge,
  );

  /// A band's top sheen (`.seg`, fading out at 55%), its inset top light
  /// and its inset bottom shade.
  final Color bandSheen;

  /// See [bandSheen].
  final Color bandLight;

  /// See [bandSheen].
  final Color bandShade;

  /// A leaving band's fill (`.seg--leave`); an arriving band's sheen
  /// (fading out at 70%) and ring (`.seg--arrive`).
  final Color leaveFill;

  /// See [leaveFill].
  final Color arriveSheen;

  /// See [leaveFill].
  final Color arriveRing;

  /// A glass tube's fill sheen (fading out at 60%), its inset light and its
  /// track's ring (`.tube`).
  final Color tubeSheen;

  /// See [tubeSheen].
  final Color tubeLight;

  /// See [tubeSheen].
  final Color tubeRing;

  /// The statement's rule (`.stl-rule`) and the due bead's ring
  /// (`.stl-n--due`).
  final Color rule;

  /// See [rule].
  final Color beadRing;

  /// The visit strip's rule and its day ticks.
  final Color stripRule;

  /// See [stripRule].
  final Color stripTick;

  /// A struck balance's line (`.chg-v s`).
  final Color struck;

  /// The done check's halo (`.done-check`).
  final Color halo;

  /// A merchant card's fill on the desktop (`.a-tm .merch`).
  final Color merchantCard;

  /// A bead's face: a closed or due statement bead, the strip's own day.
  final Color bead;

  /// A card's inset top light (`.kcard`, `.dcard`).
  final Color cardSheen;

  /// The specular band across the pearl credit card, the debit card's and a
  /// wide
  /// pane's.
  final Color specular;

  /// See [specular].
  final Color debitSpecular;

  /// See [specular].
  final Color paneSpecular;

  /// A mosaic pane's haze at its top start corner (`.cell` radial).
  final Color paneHaze;

  /// The new-goal ghost card: its fill, its ring and its edge
  /// (`.new-goal`).
  final Color newGoalFill;

  /// See [newGoalFill].
  final Color newGoalRing;

  /// See [newGoalFill].
  final Color ghostEdge;

  /// The debit card's base, top start to bottom end, and its shadow
  /// (`.dcard`).
  final Color debitFrom;

  /// See [debitFrom].
  final Color debitTo;

  /// See [debitFrom].
  final Color debitShade;

  /// A frozen card's shadow, and the frost over it (`.frost`): its streaks,
  /// its haze, its wash (three stops at 160deg), its inner glow, its ring,
  /// and its mark's fill, ring and shadow (`.frost-i`).
  final Color frozenShade;

  /// See [frozenShade].
  final Color frostStreak;

  /// See [frozenShade].
  final Color frostHaze;

  /// See [frozenShade].
  final List<Color> frostWash;

  /// See [frozenShade].
  final Color frostGlow;

  /// See [frozenShade].
  final Color frostRing;

  /// See [frozenShade].
  final Color frostMarkFill;

  /// See [frozenShade].
  final Color frostMarkRing;

  /// See [frozenShade].
  final Color frostMarkShade;

  /// The glass pill on a card (`.glass`): its fill, the ring inside it and
  /// the hairline outside.
  final Color pillFill;

  /// See [pillFill].
  final Color pillRing;

  /// See [pillFill].
  final Color pillEdge;

  /// The source's own values: white at its alphas, the ink at its alphas.
  static const FrostedSheens day = FrostedSheens(
    bandSheen: Color(0x66FFFFFF),
    bandLight: Color(0x73FFFFFF),
    bandShade: Color(0x0D15152D),
    leaveFill: Color(0xB3FFFFFF),
    arriveSheen: Color(0x99FFFFFF),
    arriveRing: Color(0xE6FFFFFF),
    tubeSheen: Color(0x73FFFFFF),
    tubeLight: Color(0x80FFFFFF),
    tubeRing: Color(0x0B15152D),
    rule: Color(0x2415152D),
    beadRing: Color(0x4D15152D),
    stripRule: Color(0x1A15152D),
    stripTick: Color(0x1F15152D),
    struck: Color(0x6615152D),
    halo: Color(0xB8FFFFFF),
    merchantCard: Color(0x80FFFFFF),
    bead: Color(0xFFFFFFFF),
    cardSheen: Color(0xE6FFFFFF),
    specular: Color(0x8CFFFFFF),
    debitSpecular: Color(0x99FFFFFF),
    paneSpecular: Color(0x6BFFFFFF),
    paneHaze: Color(0x8CFFFFFF),
    newGoalFill: Color(0x5CFFFFFF),
    newGoalRing: Color(0xB3FFFFFF),
    ghostEdge: Color(0x1415152D),
    debitFrom: Color(0xF5DCECFA),
    debitTo: Color(0xE6ECF1FC),
    debitShade: Color(0x731E508C),
    frozenShade: Color(0x73285A96),
    frostStreak: Color(0x4DFFFFFF),
    frostHaze: Color(0x80FFFFFF),
    frostWash: [Color(0xBDF8FBFF), Color(0x99D6E5F8), Color(0xB8ECF2FC)],
    frostGlow: Color(0x668CB4EB),
    frostRing: Color(0xCCFFFFFF),
    frostMarkFill: Color(0xE0FFFFFF),
    frostMarkRing: Color(0x4D78AAE6),
    frostMarkShade: Color(0x80285A96),
    pillFill: Color(0x8CFFFFFF),
    pillRing: Color(0xCCFFFFFF),
    pillEdge: Color(0x0D15152D),
  );

  /// The dark appearance's, designed (see [FrostedSheens]): sheens at about
  /// half, hairlines in white at the source's weights, the debit card and
  /// the frost a smoked blue glass, the pill a dark glass.
  static const FrostedSheens night = FrostedSheens(
    bandSheen: Color(0x38FFFFFF),
    bandLight: Color(0x4DFFFFFF),
    bandShade: Color(0x4D000000),
    leaveFill: Color(0x1AFFFFFF),
    arriveSheen: Color(0x47FFFFFF),
    arriveRing: Color(0x73FFFFFF),
    tubeSheen: Color(0x38FFFFFF),
    tubeLight: Color(0x42FFFFFF),
    tubeRing: Color(0x12FFFFFF),
    rule: Color(0x29FFFFFF),
    beadRing: Color(0x5CFFFFFF),
    stripRule: Color(0x1FFFFFFF),
    stripTick: Color(0x24FFFFFF),
    struck: Color(0x73F3F2FA),
    halo: Color(0xB80E0D15),
    merchantCard: Color(0x80262532),
    bead: Color(0xFF363542),
    cardSheen: Color(0x38FFFFFF),
    specular: Color(0x17FFFFFF),
    debitSpecular: Color(0x1AFFFFFF),
    paneSpecular: Color(0x0FFFFFFF),
    paneHaze: Color(0x14FFFFFF),
    newGoalFill: Color(0x0AFFFFFF),
    newGoalRing: Color(0x24FFFFFF),
    ghostEdge: Color(0x14FFFFFF),
    debitFrom: Color(0xEB243A5C),
    debitTo: Color(0xE61A243A),
    debitShade: Color(0x80000000),
    frozenShade: Color(0x80000000),
    frostStreak: Color(0x1AFFFFFF),
    frostHaze: Color(0x0FFFFFFF),
    frostWash: [Color(0xB31C2A40), Color(0x8C22324D), Color(0xA61A2638)],
    frostGlow: Color(0x4778AAE6),
    frostRing: Color(0x38FFFFFF),
    frostMarkFill: Color(0xE62A3A55),
    frostMarkRing: Color(0x5978AAE6),
    frostMarkShade: Color(0x80000000),
    pillFill: Color(0x14FFFFFF),
    pillRing: Color(0x29FFFFFF),
    pillEdge: Color(0x33000000),
  );

  /// This with the named values replaced.
  FrostedSheens copyWith({
    Color? bandSheen,
    Color? bandLight,
    Color? bandShade,
    Color? leaveFill,
    Color? arriveSheen,
    Color? arriveRing,
    Color? tubeSheen,
    Color? tubeLight,
    Color? tubeRing,
    Color? rule,
    Color? beadRing,
    Color? stripRule,
    Color? stripTick,
    Color? struck,
    Color? halo,
    Color? merchantCard,
    Color? bead,
    Color? cardSheen,
    Color? specular,
    Color? debitSpecular,
    Color? paneSpecular,
    Color? paneHaze,
    Color? newGoalFill,
    Color? newGoalRing,
    Color? ghostEdge,
    Color? debitFrom,
    Color? debitTo,
    Color? debitShade,
    Color? frozenShade,
    Color? frostStreak,
    Color? frostHaze,
    List<Color>? frostWash,
    Color? frostGlow,
    Color? frostRing,
    Color? frostMarkFill,
    Color? frostMarkRing,
    Color? frostMarkShade,
    Color? pillFill,
    Color? pillRing,
    Color? pillEdge,
  }) => FrostedSheens(
    bandSheen: bandSheen ?? this.bandSheen,
    bandLight: bandLight ?? this.bandLight,
    bandShade: bandShade ?? this.bandShade,
    leaveFill: leaveFill ?? this.leaveFill,
    arriveSheen: arriveSheen ?? this.arriveSheen,
    arriveRing: arriveRing ?? this.arriveRing,
    tubeSheen: tubeSheen ?? this.tubeSheen,
    tubeLight: tubeLight ?? this.tubeLight,
    tubeRing: tubeRing ?? this.tubeRing,
    rule: rule ?? this.rule,
    beadRing: beadRing ?? this.beadRing,
    stripRule: stripRule ?? this.stripRule,
    stripTick: stripTick ?? this.stripTick,
    struck: struck ?? this.struck,
    halo: halo ?? this.halo,
    merchantCard: merchantCard ?? this.merchantCard,
    bead: bead ?? this.bead,
    cardSheen: cardSheen ?? this.cardSheen,
    specular: specular ?? this.specular,
    debitSpecular: debitSpecular ?? this.debitSpecular,
    paneSpecular: paneSpecular ?? this.paneSpecular,
    paneHaze: paneHaze ?? this.paneHaze,
    newGoalFill: newGoalFill ?? this.newGoalFill,
    newGoalRing: newGoalRing ?? this.newGoalRing,
    ghostEdge: ghostEdge ?? this.ghostEdge,
    debitFrom: debitFrom ?? this.debitFrom,
    debitTo: debitTo ?? this.debitTo,
    debitShade: debitShade ?? this.debitShade,
    frozenShade: frozenShade ?? this.frozenShade,
    frostStreak: frostStreak ?? this.frostStreak,
    frostHaze: frostHaze ?? this.frostHaze,
    frostWash: frostWash ?? this.frostWash,
    frostGlow: frostGlow ?? this.frostGlow,
    frostRing: frostRing ?? this.frostRing,
    frostMarkFill: frostMarkFill ?? this.frostMarkFill,
    frostMarkRing: frostMarkRing ?? this.frostMarkRing,
    frostMarkShade: frostMarkShade ?? this.frostMarkShade,
    pillFill: pillFill ?? this.pillFill,
    pillRing: pillRing ?? this.pillRing,
    pillEdge: pillEdge ?? this.pillEdge,
  );

  /// Between [a] and [b], value by value.
  static FrostedSheens lerp(FrostedSheens a, FrostedSheens b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedSheens(
      bandSheen: Color.lerp(a.bandSheen, b.bandSheen, t)!,
      bandLight: Color.lerp(a.bandLight, b.bandLight, t)!,
      bandShade: Color.lerp(a.bandShade, b.bandShade, t)!,
      leaveFill: Color.lerp(a.leaveFill, b.leaveFill, t)!,
      arriveSheen: Color.lerp(a.arriveSheen, b.arriveSheen, t)!,
      arriveRing: Color.lerp(a.arriveRing, b.arriveRing, t)!,
      tubeSheen: Color.lerp(a.tubeSheen, b.tubeSheen, t)!,
      tubeLight: Color.lerp(a.tubeLight, b.tubeLight, t)!,
      tubeRing: Color.lerp(a.tubeRing, b.tubeRing, t)!,
      rule: Color.lerp(a.rule, b.rule, t)!,
      beadRing: Color.lerp(a.beadRing, b.beadRing, t)!,
      stripRule: Color.lerp(a.stripRule, b.stripRule, t)!,
      stripTick: Color.lerp(a.stripTick, b.stripTick, t)!,
      struck: Color.lerp(a.struck, b.struck, t)!,
      halo: Color.lerp(a.halo, b.halo, t)!,
      merchantCard: Color.lerp(a.merchantCard, b.merchantCard, t)!,
      bead: Color.lerp(a.bead, b.bead, t)!,
      cardSheen: Color.lerp(a.cardSheen, b.cardSheen, t)!,
      specular: Color.lerp(a.specular, b.specular, t)!,
      debitSpecular: Color.lerp(a.debitSpecular, b.debitSpecular, t)!,
      paneSpecular: Color.lerp(a.paneSpecular, b.paneSpecular, t)!,
      paneHaze: Color.lerp(a.paneHaze, b.paneHaze, t)!,
      newGoalFill: Color.lerp(a.newGoalFill, b.newGoalFill, t)!,
      newGoalRing: Color.lerp(a.newGoalRing, b.newGoalRing, t)!,
      ghostEdge: Color.lerp(a.ghostEdge, b.ghostEdge, t)!,
      debitFrom: Color.lerp(a.debitFrom, b.debitFrom, t)!,
      debitTo: Color.lerp(a.debitTo, b.debitTo, t)!,
      debitShade: Color.lerp(a.debitShade, b.debitShade, t)!,
      frozenShade: Color.lerp(a.frozenShade, b.frozenShade, t)!,
      frostStreak: Color.lerp(a.frostStreak, b.frostStreak, t)!,
      frostHaze: Color.lerp(a.frostHaze, b.frostHaze, t)!,
      frostWash: _lerpColors(a.frostWash, b.frostWash, t),
      frostGlow: Color.lerp(a.frostGlow, b.frostGlow, t)!,
      frostRing: Color.lerp(a.frostRing, b.frostRing, t)!,
      frostMarkFill: Color.lerp(a.frostMarkFill, b.frostMarkFill, t)!,
      frostMarkRing: Color.lerp(a.frostMarkRing, b.frostMarkRing, t)!,
      frostMarkShade: Color.lerp(a.frostMarkShade, b.frostMarkShade, t)!,
      pillFill: Color.lerp(a.pillFill, b.pillFill, t)!,
      pillRing: Color.lerp(a.pillRing, b.pillRing, t)!,
      pillEdge: Color.lerp(a.pillEdge, b.pillEdge, t)!,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedSheens &&
          other.bandSheen == bandSheen &&
          other.bandLight == bandLight &&
          other.bandShade == bandShade &&
          other.leaveFill == leaveFill &&
          other.arriveSheen == arriveSheen &&
          other.arriveRing == arriveRing &&
          other.tubeSheen == tubeSheen &&
          other.tubeLight == tubeLight &&
          other.tubeRing == tubeRing &&
          other.rule == rule &&
          other.beadRing == beadRing &&
          other.stripRule == stripRule &&
          other.stripTick == stripTick &&
          other.struck == struck &&
          other.halo == halo &&
          other.merchantCard == merchantCard &&
          other.bead == bead &&
          other.cardSheen == cardSheen &&
          other.specular == specular &&
          other.debitSpecular == debitSpecular &&
          other.paneSpecular == paneSpecular &&
          other.paneHaze == paneHaze &&
          other.newGoalFill == newGoalFill &&
          other.newGoalRing == newGoalRing &&
          other.ghostEdge == ghostEdge &&
          other.debitFrom == debitFrom &&
          other.debitTo == debitTo &&
          other.debitShade == debitShade &&
          other.frozenShade == frozenShade &&
          other.frostStreak == frostStreak &&
          other.frostHaze == frostHaze &&
          listEquals(other.frostWash, frostWash) &&
          other.frostGlow == frostGlow &&
          other.frostRing == frostRing &&
          other.frostMarkFill == frostMarkFill &&
          other.frostMarkRing == frostMarkRing &&
          other.frostMarkShade == frostMarkShade &&
          other.pillFill == pillFill &&
          other.pillRing == pillRing &&
          other.pillEdge == pillEdge;

  @override
  int get hashCode => Object.hashAll([
    bandSheen,
    bandLight,
    bandShade,
    leaveFill,
    arriveSheen,
    arriveRing,
    tubeSheen,
    tubeLight,
    tubeRing,
    rule,
    beadRing,
    stripRule,
    stripTick,
    struck,
    halo,
    merchantCard,
    bead,
    cardSheen,
    specular,
    debitSpecular,
    paneSpecular,
    paneHaze,
    newGoalFill,
    newGoalRing,
    ghostEdge,
    debitFrom,
    debitTo,
    debitShade,
    frozenShade,
    frostStreak,
    frostHaze,
    ...frostWash,
    frostGlow,
    frostRing,
    frostMarkFill,
    frostMarkRing,
    frostMarkShade,
    pillFill,
    pillRing,
    pillEdge,
  ]);
}

/// A CSS `box-shadow` as Flutter draws one: CSS blurs a shadow to a
/// standard deviation of half its blur radius, Flutter's radius maps to
/// `0.57735 r + 0.5`.
BoxShadow _css(double y, double blur, double spread, Color color) => BoxShadow(
  offset: Offset(0, y),
  blurRadius: blur <= 0 ? 0 : math.max(0, (blur / 2 - 0.5) / 0.57735),
  spreadRadius: spread,
  color: color,
);

/// Theme-dependent tokens: colour roles, the glass, the inks, the spectrum,
/// the washes of light, the shadows, the resolved type scale and the corner
/// language. Built by [FrostedThemeData.preset] with every role materialised:
/// components read values, they never derive them. A plain value:
/// [FrostedTheme] carries it down the tree.
///
/// The role and slot NAMES are Cody's where a role exists, so a page written
/// against one system transfers to another; the roles after
/// [FrostedColorScheme.accentText] and
/// the slots [FrostedTextTheme.displaySmall], [FrostedTextTheme.headlineLarge],
/// [FrostedTextTheme.stat], [FrostedTextTheme.amount],
/// [FrostedTextTheme.amountSmall], [FrostedTextTheme.bodySmall],
/// [FrostedTextTheme.labelSmall], [FrostedTextTheme.link],
/// [FrostedTextTheme.tab], [FrostedTextTheme.overline],
/// [FrostedTextTheme.monoSmall], [FrostedTextTheme.monogram] and
/// [FrostedTextTheme.wordmark] are Frosted's own, named for what they are for.
@immutable
class FrostedThemeData with Diagnosticable {
  /// A theme from its groups; the presets, [FrostedThemeData.from] and
  /// [copyWith] build every theme.
  const FrostedThemeData._({
    required this.id,
    required this.brightness,
    required this.colorScheme,
    required this.textTheme,
    required this.shadows,
    required this.glass,
    required this.pearl,
    required this.toast,
    required this.hues,
    required this.lights,
    required this.charts,
    required this.sheens,
    this._density,
    required this.typeface,
    required this.components,
    required this.backdrop,
    required this.opaqueMaterials,
  });

  /// A theme from every value by name, as the presets and the token rules set
  /// them.
  factory FrostedThemeData._raw({
    required String id,
    required Brightness brightness,
    required Color background,
    required Color surface,
    required Color surfaceAlt,
    required Color surfaceInverse,
    required Color borderStrong,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color textInverse,
    required Color accent,
    required Color onAccent,
    required Color accentSubtle,
    required Color success,
    required Color onSuccess,
    required Color successSubtle,
    required Color warning,
    required Color warningSubtle,
    required Color danger,
    required Color onDanger,
    required Color dangerSubtle,
    required Color overlay,
    required Color accentText,
    required Color hairline,
    required Color wash,
    required Color glass,
    required Color glassHi,
    required Color glassEdge,
    required Color glassRim,
    required Color well,
    required Color wellEdge,
    required Color plane,
    required Color actTop,
    required Color actBottom,
    required Color actSheen,
    required Color onAct,
    required Color ringInner,
    required Color ringOuter,
    required Color moneyIn,
    required Color moneyInTint,
    required Color over,
    required Color overTint,
    required Color cold,
    required Color coldTint,
    required Color coldEdge,
    required FrostedHues hues,
    required FrostedLights lights,
    required List<Color> rimStops,
    required Color pearlFrom,
    required Color pearlTo,
    required Color pearlBlush,
    required List<Color> pearlRim,
    required List<Color> pearlGlow,
    required Color pearlInk,
    required Color pearlInkQuiet,
    required Color utilFrom,
    required Color utilTo,
    required Color utilTrack,
    required List<Color> avatarStops,
    required FrostedChartInks charts,
    required FrostedSheens sheens,
    required Color topFrost,
    required Color barFill,
    required Color barFade,
    required Color sideFill,
    required Color sideEdge,
    required Color navCurrent,
    required Color sheetTop,
    required Color sheetBottom,
    required Color sheetEdge,
    required Color grabber,
    required Color menuFill,
    required Color menuEdge,
    required Color toastTop,
    required Color toastBottom,
    required Color onToast,
    required Color toastSheen,
    required Color toastMarkFill,
    required Color toastMarkInk,
    required Color toastAction,
    required Color unreadDot,
    required Color trackFill,
    required Color trackEdge,
    required Color meterTrack,
    required Color paceTick,
    required Color paceRing,
    required Color toggleTrack,
    required Color knob,
    required List<BoxShadow> lift,
    required List<BoxShadow> barShadow,
    required List<BoxShadow> sheetShadow,
    required List<BoxShadow> dialogShadow,
    required List<BoxShadow> menuShadow,
    required List<BoxShadow> toastShadow,
    required List<BoxShadow> actShadow,
    required List<BoxShadow> raisedShadow,
    required List<BoxShadow> pearlShadow,
    required List<BoxShadow> ticketShadow,
    required List<BoxShadow> knobShadow,
    required TextStyle giant,
    required TextStyle display,
    required TextStyle figure,
    required TextStyle figureSmall,
    required TextStyle stat,
    required TextStyle hero,
    required TextStyle h1,
    required TextStyle h2,
    required TextStyle h3,
    required TextStyle bodyLarge,
    required TextStyle body,
    required TextStyle bodySmall,
    required TextStyle amount,
    required TextStyle amountSmall,
    required TextStyle caption,
    required TextStyle note,
    required TextStyle label,
    required TextStyle labelSmall,
    required TextStyle link,
    required TextStyle tab,
    required TextStyle eyebrow,
    required TextStyle mono,
    required TextStyle monoSmall,
    required TextStyle monogram,
    required TextStyle wordmark,
    FrostedDensity? density,
    FrostedTypeface typeface = FrostedTypeface.look,
    FrostedComponentThemes components = const FrostedComponentThemes(),
    FrostedBackdrop backdrop = const FrostedBackdrop.dawn(),
    bool opaqueMaterials = false,
  }) => FrostedThemeData._(
    id: id,
    brightness: brightness,
    colorScheme: FrostedColorScheme(
      background: background,
      surface: surface,
      surfaceAlt: surfaceAlt,
      surfaceInverse: surfaceInverse,
      border: hairline,
      borderStrong: borderStrong,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      textTertiary: textTertiary,
      textInverse: textInverse,
      accent: accent,
      onAccent: onAccent,
      accentSubtle: accentSubtle,
      accentText: accentText,
      success: success,
      onSuccess: onSuccess,
      successSubtle: successSubtle,
      warning: warning,
      warningSubtle: warningSubtle,
      danger: danger,
      onDanger: onDanger,
      dangerSubtle: dangerSubtle,
      overlay: overlay,
      buttonTop: actTop,
      buttonBottom: actBottom,
      buttonSheen: actSheen,
      onButton: onAct,
      ringInner: ringInner,
      ringOuter: ringOuter,
      moneyIn: moneyIn,
      moneyInTint: moneyInTint,
      over: over,
      overTint: overTint,
      cold: cold,
      coldTint: coldTint,
      coldEdge: coldEdge,
      unreadDot: unreadDot,
      meterTrack: meterTrack,
      paceTick: paceTick,
      paceTickRing: paceRing,
      toggleTrack: toggleTrack,
      toggleKnob: knob,
    ),
    textTheme: FrostedTextTheme(
      displayLarge: giant,
      displayMedium: display,
      displaySmall: figure,
      headlineLarge: figureSmall,
      headlineMedium: hero,
      headlineSmall: h1,
      titleLarge: h2,
      titleMedium: body,
      titleSmall: h3,
      bodyLarge: bodyLarge,
      bodyMedium: bodySmall,
      bodySmall: note,
      labelLarge: label,
      labelMedium: caption,
      labelSmall: labelSmall,
      overline: eyebrow,
      stat: stat,
      amount: amount,
      amountSmall: amountSmall,
      link: link,
      tab: tab,
      mono: mono,
      monoSmall: monoSmall,
      monogram: monogram,
      wordmark: wordmark,
    ),
    shadows: FrostedShadows(
      tile: lift,
      bar: barShadow,
      sheet: sheetShadow,
      dialog: dialogShadow,
      menu: menuShadow,
      toast: toastShadow,
      button: actShadow,
      raised: raisedShadow,
      pearl: pearlShadow,
      ticket: ticketShadow,
      toggleKnob: knobShadow,
    ),
    glass: FrostedGlassColors(
      fill: glass,
      fillHigh: glassHi,
      edge: glassEdge,
      rim: glassRim,
      spectrumStops: rimStops,
      wash: wash,
      well: well,
      wellEdge: wellEdge,
      plane: plane,
      topFrost: topFrost,
      bar: barFill,
      barFade: barFade,
      sidebar: sideFill,
      sidebarEdge: sideEdge,
      navCurrent: navCurrent,
      sheetTop: sheetTop,
      sheetBottom: sheetBottom,
      sheetEdge: sheetEdge,
      grabber: grabber,
      menu: menuFill,
      menuEdge: menuEdge,
      track: trackFill,
      trackEdge: trackEdge,
    ),
    pearl: FrostedPearlColors(
      from: pearlFrom,
      to: pearlTo,
      blush: pearlBlush,
      rim: pearlRim,
      glow: pearlGlow,
      text: pearlInk,
      textSecondary: pearlInkQuiet,
      usageFrom: utilFrom,
      usageTo: utilTo,
      usageTrack: utilTrack,
      avatar: avatarStops,
    ),
    toast: FrostedToastColors(
      top: toastTop,
      bottom: toastBottom,
      text: onToast,
      sheen: toastSheen,
      mark: toastMarkFill,
      onMark: toastMarkInk,
      action: toastAction,
    ),
    hues: hues,
    lights: lights,
    charts: charts,
    sheens: sheens,
    density: density,
    typeface: typeface,
    components: components,
    backdrop: backdrop,
    opaqueMaterials: opaqueMaterials,
  );

  /// Builds a theme from a baked ThemeTokens v2 record: every Cody role by
  /// name, and Frosted's own roles by the rules below (the same rules for
  /// every catalog theme, so any of them can dress the system). The record's
  /// light and dark are both designed, so both appearances are its own; the
  /// dark one is dressed by the night's rules (`_Night`), not inverted:
  ///
  /// - the glass is the set's `surface` at 62% (the high glass at 78%), at
  ///   night the surface a step toward `surfaceAlt`, rimmed in white (at
  ///   night 18%, a line of light) and edged in the set's `border`; the wash
  ///   is the page ink at 4.5%, the rule between rows
  /// ([FrostedColorScheme.border])
  ///   the record's `border` at 60%; a field's
  ///   well is the glass at 82%;
  /// - the act (every button, chip and toggle that is on) wears the set's
  ///   `accent`, from the accent eased 10% to white (less where its ink would
  ///   read under 4.5:1 there) down to the accent, its ink `onAccent` (where
  ///   `onAccent` cannot read 4.5:1 on the accent's eased words, the act wears
  ///   those words' colour with the page or its ink as its ink, so the act and
  ///   the words stay one ink); its focus ring the surface then the accent; the
  ///   accent's words (`accentText`) are eased toward the page ink until they
  ///   read 4.5:1 on the canvas and the tile, where Frosted sets them;
  /// - the quieter inks (`textSecondary`, `textTertiary`) are
  ///   the record's, eased toward the page ink until they read 4.5:1, with
  ///   room to spare, on the glass and on the canvas under the washes of
  ///   light at their peak; the first also on the glass tinted by the
  ///   brand's wash and the money tint (a banner's panes);
  /// - money in is `success`, over budget `danger`, the warning `warning`
  ///   (eased to read 4.5:1 on its own tint, the warning's `warningSubtle`),
  ///   the cold of a frozen card the accent turned to blue (212 degrees),
  ///   eased toward the page ink until it reads as a word (4.5:1) on its
  ///   tint (at night each tint 18%, so a chip is lit from within);
  /// - the spectrum is twenty hues turned round the wheel from the accent
  ///   ([FrostedHue.turned], on the light set): the eight categories in
  ///   eighths, the objects in sixths from a third round, money in
  ///   `success`, a move the quiet ink, the allocation bands and the prism's
  ///   own hue at the accent; at night the same pastels lit from within
  ///   ([FrostedHue.lit]) on the dark set's tile;
  /// - the washes of light are the accent, `danger` and `warning` each eased
  ///   60% toward white, at 60% strength; at night the same three hues at
  ///   the saturated middle of their lightness, at 50%, so they glow;
  /// - the rim of light is the five pastel stops of the categories at 0, 2,
  ///   3, 5 and 7; the pearl (a card) is the accent's palest tint by day and
  ///   at night a smoked pearl, the well deepened 18% toward the accent with
  ///   the night's blush and glow; its words the page's inks, eased until
  ///   they read 4.5:1 on it; its rim the same stops; an avatar's pearl the
  ///   subtle washes of the accent, `danger` and `warning` (at night the
  ///   well lit 30% toward their glow);
  /// - the charts' line runs from the accent through its mix with `danger`
  ///   to `danger`; the grid is the `border` at half; the area the accent at
  ///   16% to nothing;
  /// - the bars, the sheet, the menu and the sidebar are the `surface`
  ///   (the sheet eased 3% toward the background at its foot), edged in the
  ///   `border`; the toast is `surfaceInverse` with `textInverse` words by
  ///   day and a raised dark glass with the page ink at night, so the act
  ///   stays the one light face; their shadows are the set's `shadowLg` (a
  ///   tile's and the bar's `shadowMd`); the cards' own shadows are the
  ///   ink's shade by day and black at night;
  /// - the sheens ([FrostedSheens]) are the source's by day and the night's at
  ///   night, its halo, merchant card, bead and struck figure on the set's
  ///   own canvas, glass, well and ink ([FrostedSheens.on]);
  /// - the corners are the record's, but the small corner rounds no
  ///   further than the card's (a pill small corner would clip a
  ///   picture's rank and tag in its corners);
  /// - the figures ([FrostedTextTheme.displayLarge], [FrostedTextTheme.displayMedium], [FrostedTextTheme.displaySmall], [FrostedTextTheme.headlineLarge], [FrostedTextTheme.stat]) are
  ///   the record's `display` slot at 96, 64, 40, 28 and 20 on Frosted's
  ///   lines; [FrostedTextTheme.headlineMedium] its `hero` at 28,
  /// [FrostedTextTheme.headlineSmall] its `h1` at 20,
  /// [FrostedTextTheme.titleLarge] its `h2` at
  ///   16, [FrostedTextTheme.titleSmall] its `h3` at 14;
  /// [FrostedTextTheme.bodyLarge] and [FrostedTextTheme.titleMedium] its
  /// `bodyLarge` and
  ///   `body` at 16; [FrostedTextTheme.bodyMedium] its `bodySmall` at 14;
  /// [FrostedTextTheme.amount] its `body` in
  ///   the display face, tabular; [FrostedTextTheme.labelMedium] and
  /// [FrostedTextTheme.bodySmall] its `caption` at 12;
  ///   [FrostedTextTheme.labelLarge] and [FrostedTextTheme.labelSmall] its
  /// `label` at 14 and 12; [FrostedTextTheme.link] and [FrostedTextTheme.tab]
  /// its
  ///   `label` and `caption` at 14 and 12 in 500; [FrostedTextTheme.overline]
  /// its `caption`
  ///   tracked; [FrostedTextTheme.mono] and [FrostedTextTheme.monoSmall] its
  /// `mono` at 14 and 12, tabular and
  ///   tracked; [FrostedTextTheme.monogram] its `h3` at 14 in 600;
  /// [FrostedTextTheme.wordmark] its `h2` at 24 in
  ///   600.
  ///
  /// The faces a record names stand in as the bundled Bricolage Grotesque
  /// (the display slots) and DM Sans (the text slots); a record's mono is
  /// Bricolage with tabular figures.
  factory FrostedThemeData._fromTokens(
    String id,
    FrostedTokens tokens,
    Brightness brightness,
  ) {
    final dark = brightness == Brightness.dark;
    final c = dark ? tokens.dark : tokens.light;
    const white = Color(0xFFFFFFFF);
    final grounds = [c.background, c.surface];
    Color a(Color color, double alpha) => color.withValues(alpha: alpha);
    TextStyle type(
      FrostedTokenType t,
      Color color, {
      required double size,
      required double line,
      int? weight,
      double? trackingEm,
      bool display = false,
      bool tabular = false,
    }) => _type(
      face: display ? face : textFace,
      size: size,
      line: line,
      weight: weight ?? t.weight,
      trackingEm: trackingEm ?? t.letterSpacing / t.size,
      color: color,
      tabular: tabular,
    );

    final accent = HSLColor.fromColor(c.accent);
    Color turned(double degrees) => _reach(
      accent.withHue(degrees % 360).toColor(),
      c.textPrimary,
      grounds,
      4.5,
    );
    // The night's light: a hue at the saturated middle of its lightness, so
    // a wash glows on a dark canvas instead of hazing it (a grey stays grey).
    Color glow(Color color, double lightness) {
      final h = HSLColor.fromColor(color);
      final s = h.saturation < 0.1
          ? h.saturation
          : h.saturation.clamp(0.45, 0.7);
      return h.withSaturation(s).withLightness(lightness).toColor();
    }

    // The page's washes by day and by night (`lights` below), and the
    // grounds a word on a hue's tint can stand on: the canvas, the tile and
    // the canvas under each wash at its peak.
    FrostedLights lightsOf(FrostedTokenColors k, {required bool night}) => night
        ? FrostedLights(
            lilac: glow(k.accent, 0.6),
            rose: glow(k.danger, 0.53),
            peach: glow(k.warning, 0.55),
            strength: 0.5,
          )
        : FrostedLights(
            lilac: Color.lerp(k.accent, white, 0.6)!,
            rose: Color.lerp(k.danger, white, 0.6)!,
            peach: Color.lerp(k.warning, white, 0.6)!,
            strength: 0.6,
          );
    List<Color> pageOf(FrostedTokenColors k, {required bool night}) => [
      k.background,
      k.surface,
      ...lightsOf(k, night: night).peaksOver(k.background, night: night),
    ];

    // A hue of the spectrum: the day's pastel, turned on the light set; at
    // night the same pastel lit from within on the dark set's tile. Its ink
    // reads on its tint wherever the page lays it.
    FrostedHue hue(double degrees) {
      final day = FrostedHue.turned(
        degrees,
        accent.saturation.clamp(0.35, 0.8),
        ground: tokens.light.surface,
        toward: tokens.light.textPrimary,
        dark: false,
        also: pageOf(tokens.light, night: false),
      );
      return dark
          ? day.lit(
              ground: c.surface,
              toward: c.textPrimary,
              also: pageOf(c, night: true),
            )
          : day;
    }

    final cold = turned(212);
    final accentText = _reach(c.accentText, c.textPrimary, grounds, 4.5);
    // The act and the accent's words are one ink: the kit stamps the words'
    // colour as a brand ground under `onAccent`. Where the record's
    // `onAccent` cannot read 4.5:1 on the eased words (a deep act lifted to
    // read on a dark page), the act takes the words' colour and whichever of
    // the page and its ink reads better on it as its own words.
    final heldAct = contrast(c.onAccent, accentText) >= 4.5;
    final act = heldAct ? c.accent : accentText;
    final onAct = heldAct
        ? c.onAccent
        : contrast(c.background, accentText) >=
              contrast(c.textPrimary, accentText)
        ? c.background
        : c.textPrimary;
    final categories = [for (var i = 0; i < 8; i++) hue(accent.hue + i * 45)];
    final objects = [
      for (var i = 0; i < 6; i++) hue(accent.hue + 120 + i * 60),
    ];
    // A tone's ink reads 4.5:1 on its tint over either ground and over the
    // backdrop's washes (a chip on the page stands on them).
    final washPeaks = lightsOf(
      c,
      night: dark,
    ).peaksOver(c.background, night: dark);
    final moneyInTint = a(c.success, dark ? 0.18 : 0.13);
    final overTint = a(c.danger, dark ? 0.18 : 0.12);
    final warnTint = a(c.warning, dark ? 0.18 : 0.2);
    final coldTint = a(cold, 0.16);
    Color onTint(Color ink, Color tint) => _reach(ink, c.textPrimary, [
      for (final ground in [...grounds, ...washPeaks])
        Color.alphaBlend(tint, ground),
    ], 4.5);
    final moneyInInk = onTint(c.success, moneyInTint);
    FrostedHue night(FrostedHue h) => dark
        ? h.lit(
            ground: c.surface,
            toward: c.textPrimary,
            also: [c.background, ...washPeaks],
          )
        : h;
    final moneyIn = night(
      FrostedHue(
        a: Color.lerp(c.success, white, 0.35)!,
        b: Color.lerp(c.success, white, 0.45)!,
        ink: moneyInInk,
        inkDeep: Color.lerp(c.success, c.textPrimary, 0.4)!,
        tint: a(c.success, 0.13),
        tintSolid: a(c.success, 0.16),
        edge: a(c.success, 0.3),
      ),
    );
    final move = night(
      FrostedHue(
        a: Color.lerp(c.textTertiary, white, 0.3)!,
        b: c.textTertiary,
        ink: c.textSecondary,
        inkDeep: c.textPrimary,
        tint: a(c.textPrimary, 0.045),
        tintSolid: a(c.textPrimary, 0.05),
        edge: a(c.textPrimary, 0.08),
      ),
    );
    final signature = hue(accent.hue);
    final md = [for (final s in c.shadowMd) s.shadow];
    final lg = [for (final s in c.shadowLg) s.shadow];
    final pale = [
      for (final i in [0, 2, 3, 5, 7]) categories[i].a,
    ];
    // The act's top: the act eased 10% toward white, held where its words
    // still read 4.5:1 on it.
    final actTop = _reach(Color.lerp(act, white, 0.1)!, act, [onAct], 4.5);
    // A shadow is the ink's own shade by day and black at night.
    const black = Color(0xFF000000);
    final shade = dark ? black : Color.lerp(c.textPrimary, c.accent, 0.3)!;
    // Night glass: the tile a step toward the well, so it holds the washes
    // behind it as the day's does, rimmed along the top in white.
    final glassBase = dark
        ? Color.lerp(c.surface, c.surfaceAlt, 0.4)!
        : c.surface;
    final glass = a(glassBase, 0.62);
    final glassHi = a(glassBase, 0.78);
    final glassOn = Color.alphaBlend(glass, c.background);
    final lights = lightsOf(c, night: dark);
    // Words stand on the canvas under the washes as well as on the tiles.
    final read = [
      ...grounds,
      glassOn,
      ...lights.peaksOver(c.background, night: dark),
    ];
    final tertiary = _reach(c.textTertiary, c.textPrimary, read, 4.6);
    // The quieter ink: the record's, eased toward the page ink only as far
    // as it takes to read 4.5:1 (with room for the pixel) on every pane its
    // words sit on: those, and the glass tinted by the brand's wash (a
    // banner's spectrum, its first stop at 22%, its last at 16%), by the
    // money tint, and by the chosen tint (a picked day's figures), and the
    // wash over any of them (a missed day's bead).
    final secondary = _reach(c.textSecondary, c.textPrimary, [
      ...read,
      for (final g in read) Color.alphaBlend(a(c.textPrimary, 0.045), g),
      Color.alphaBlend(a(categories[0].a, 0.22), glassOn),
      Color.alphaBlend(a(categories[1].b, 0.16), glassOn),
      Color.alphaBlend(moneyInTint, glassOn),
      Color.alphaBlend(c.accentSubtle, glassOn),
    ], 4.6);
    final sheetBottom = Color.lerp(c.surface, c.background, 0.3)!;
    // The card's pearl: the accent's palest tint by day; at night a smoked
    // pearl, the well deepened toward the accent, so the page's own pale
    // words read on it as they do on the glass.
    final pearlFrom = dark
        ? a(Color.lerp(c.surfaceAlt, c.accent, 0.18)!, 0.92)
        : Color.lerp(c.accentSubtle, white, 0.5)!;
    final pearlTo = dark
        ? a(Color.lerp(c.surface, c.accent, 0.1)!, 0.88)
        : Color.lerp(c.accentSubtle, white, 0.7)!;
    final pearlBlush = dark
        ? a(glow(c.danger, 0.6), 0.28)
        : a(Color.lerp(c.danger, white, 0.6)!, 0.55);
    final sheens = dark
        ? FrostedSheens.night.on(
            ground: c.background,
            glass: glassBase,
            bead: c.surfaceAlt,
            ink: c.textPrimary,
          )
        : FrostedSheens.day;
    // The pearl's words stand on its base and on its blush, and its tags
    // (the kind, the note) on their pill over both, under the card's sheen
    // and its specular band where they cross it.
    Color lit(Color g) => Color.alphaBlend(
      sheens.specular,
      Color.alphaBlend(sheens.cardSheen, g),
    );
    final pearlGrounds = [
      for (final p in [pearlFrom, pearlTo])
        for (final g in [
          Color.alphaBlend(p, c.background),
          Color.alphaBlend(pearlBlush, Color.alphaBlend(p, c.background)),
        ]) ...[
          g,
          lit(g),
          Color.alphaBlend(sheens.pillFill, g),
          Color.alphaBlend(sheens.pillFill, lit(g)),
        ],
    ];
    // The night's toast: a raised dark glass, so the act stays the one light
    // face on the page.
    final toastTop = dark
        ? Color.lerp(c.surfaceAlt, white, 0.03)!
        : Color.lerp(c.surfaceInverse, white, 0.08)!;
    final toastBottom = dark
        ? Color.lerp(c.surface, c.surfaceAlt, 0.5)!
        : c.surfaceInverse;
    final onToast = dark
        ? _reach(c.textPrimary, white, [toastTop, toastBottom], 4.5)
        : c.textInverse;
    final display = tokens.display;
    return FrostedThemeData._raw(
      id: id,
      brightness: brightness,
      background: c.background,
      surface: c.surface,
      surfaceAlt: c.surfaceAlt,
      surfaceInverse: c.surfaceInverse,
      borderStrong: c.borderStrong,
      textPrimary: c.textPrimary,
      textSecondary: secondary,
      textTertiary: tertiary,
      textInverse: c.textInverse,
      accent: act,
      onAccent: onAct,
      accentSubtle: c.accentSubtle,
      success: c.success,
      onSuccess: c.onSuccess,
      successSubtle: c.successSubtle,
      // The warning's ink eased to read on its own tint, as over's is.
      warning: onTint(c.warning, warnTint),
      warningSubtle: warnTint,
      danger: c.danger,
      onDanger: c.onDanger,
      dangerSubtle: c.dangerSubtle,
      overlay: c.overlay,
      accentText: accentText,
      hairline: a(c.border, 0.6),
      wash: a(c.textPrimary, 0.045),
      glass: glass,
      glassHi: glassHi,
      // By day a pane's edge is the lit hairline, never a dark line.
      glassEdge: dark ? c.border : _Source.litEdge,
      glassRim: a(white, dark ? 0.18 : 0.9),
      well: a(glassBase, 0.82),
      wellEdge: dark ? c.border : _Source.litEdge,
      plane: c.surface,
      actTop: actTop,
      actBottom: act,
      actSheen: a(white, 0.14),
      onAct: onAct,
      ringInner: c.surface,
      ringOuter: a(act, 0.7),
      moneyIn: moneyInInk,
      moneyInTint: moneyInTint,
      // On its chip's tint, and bare on the page under its washes (a
      // field's error).
      over: _reach(onTint(c.danger, overTint), c.textPrimary, read, 4.5),
      overTint: overTint,
      cold: onTint(cold, coldTint),
      coldTint: coldTint,
      coldEdge: a(cold, 0.34),
      hues: FrostedHues(
        periwinkle: categories[0],
        orchid: categories[1],
        coral: categories[2],
        apricot: categories[3],
        lemon: categories[4],
        mint: categories[5],
        teal: categories[6],
        sky: categories[7],
        cyan: objects[0],
        seafoam: objects[1],
        sunset: objects[2],
        lagoon: objects[3],
        azure: objects[4],
        lime: objects[5],
        emerald: moneyIn,
        slate: move,
        turquoise: objects[3],
        lavender: objects[0],
        iris: signature,
        silver: move,
      ),
      lights: lights,
      rimStops: pale,
      pearlFrom: pearlFrom,
      pearlTo: pearlTo,
      pearlBlush: pearlBlush,
      pearlRim: pale,
      pearlGlow: dark
          ? [glow(c.accent, 0.45), glow(c.danger, 0.4), glow(c.warning, 0.4)]
          : [
              Color.lerp(c.accent, white, 0.6)!,
              Color.lerp(c.danger, white, 0.65)!,
              Color.lerp(c.warning, white, 0.65)!,
            ],
      pearlInk: _reach(c.textPrimary, dark ? white : black, pearlGrounds, 4.5),
      pearlInkQuiet: _reach(secondary, c.textPrimary, pearlGrounds, 4.5),
      utilFrom: categories[0].a,
      utilTo: categories[1].b,
      utilTrack: a(c.textPrimary, dark ? 0.12 : 0.08),
      avatarStops: dark
          ? [
              Color.lerp(c.surfaceAlt, glow(c.accent, 0.6), 0.3)!,
              Color.lerp(c.surfaceAlt, glow(c.danger, 0.53), 0.3)!,
              Color.lerp(c.surfaceAlt, glow(c.warning, 0.55), 0.3)!,
            ]
          : [
              Color.lerp(c.accent, white, 0.82)!,
              Color.lerp(c.danger, white, 0.82)!,
              Color.lerp(c.warning, white, 0.82)!,
            ],
      sheens: sheens,
      charts: FrostedChartInks(
        line: [c.accent, Color.lerp(c.accent, c.danger, 0.5)!, c.danger],
        grid: a(c.border, 0.5),
        areaFrom: a(c.accent, dark ? 0.2 : 0.16),
        areaTo: a(c.accent, 0),
        label: accentText,
        pace: a(c.textPrimary, 0.4),
        endDot: c.danger,
        endRing: c.surface,
      ),
      topFrost: a(c.background, 0.5),
      barFill: a(c.surface, dark ? 0.86 : 0.74),
      barFade: c.background,
      sideFill: a(c.surface, 0.5),
      sideEdge: dark ? c.border : _Source.litEdge,
      navCurrent: dark ? a(c.textPrimary, 0.12) : a(c.surface, 0.8),
      sheetTop: c.surface,
      sheetBottom: sheetBottom,
      sheetEdge: c.border,
      grabber: c.borderStrong,
      menuFill: c.surface,
      menuEdge: c.border,
      toastTop: toastTop,
      toastBottom: toastBottom,
      onToast: onToast,
      toastSheen: a(white, dark ? 0.14 : 0.1),
      toastMarkFill: a(c.success, 0.2),
      toastMarkInk: Color.lerp(c.success, onToast, 0.3)!,
      toastAction: a(onToast, dark ? 0.1 : 0.12),
      unreadDot: c.danger,
      trackFill: dark ? a(white, 0.08) : a(c.surface, 0.92),
      trackEdge: a(c.border, 0.5),
      meterTrack: dark ? a(white, 0.12) : a(c.surface, 0.7),
      paceTick: a(c.textPrimary, dark ? 0.8 : 0.78),
      paceRing: dark ? a(c.background, 0.9) : a(c.surface, 0.92),
      toggleTrack: a(c.textPrimary, dark ? 0.18 : 0.13),
      knob: dark ? Color.lerp(c.surfaceAlt, white, 0.06)! : c.surface,
      lift: md,
      barShadow: md,
      sheetShadow: lg,
      dialogShadow: lg,
      menuShadow: lg,
      toastShadow: lg,
      actShadow: [
        _css(8, 18, -12, a(dark ? black : c.accent, dark ? 0.5 : 0.7)),
      ],
      raisedShadow: [_css(2, 6, -2, a(shade, dark ? 0.4 : 0.18))],
      pearlShadow: [_css(18, 36, -22, a(shade, dark ? 0.6 : 0.4))],
      ticketShadow: [_css(6, 16, -12, a(shade, dark ? 0.5 : 0.45))],
      knobShadow: [
        _css(1, 3, 0, a(dark ? black : c.textPrimary, 0.22)),
        BoxShadow(
          color: a(dark ? black : c.textPrimary, 0.06),
          spreadRadius: 0.5,
        ),
      ],
      giant: type(
        display,
        c.textPrimary,
        size: 96,
        line: 83,
        trackingEm: -0.035,
        display: true,
      ),
      display: type(
        display,
        c.textPrimary,
        size: 64,
        line: 55,
        trackingEm: -0.035,
        display: true,
      ),
      figure: type(
        display,
        c.textPrimary,
        size: 40,
        line: 34,
        trackingEm: -0.03,
        display: true,
      ),
      figureSmall: type(
        display,
        c.textPrimary,
        size: 28,
        line: 24,
        trackingEm: -0.025,
        display: true,
      ),
      stat: type(
        display,
        c.textPrimary,
        size: 20,
        line: 22,
        trackingEm: -0.02,
        display: true,
        tabular: true,
      ),
      hero: type(tokens.hero, c.textPrimary, size: 28, line: 31, display: true),
      h1: type(tokens.h1, c.textPrimary, size: 20, line: 22, display: true),
      h2: type(tokens.h2, c.textPrimary, size: 16, line: 20, display: true),
      h3: type(tokens.h3, c.textPrimary, size: 14, line: 14, display: true),
      bodyLarge: type(tokens.bodyLarge, c.textPrimary, size: 16, line: 22),
      body: type(tokens.body, c.textPrimary, size: 16, line: 20, weight: 500),
      bodySmall: type(tokens.bodySmall, secondary, size: 14, line: 19),
      amount: type(
        tokens.body,
        c.textPrimary,
        size: 16,
        line: 20,
        weight: 500,
        trackingEm: -0.005,
        display: true,
        tabular: true,
      ),
      amountSmall: type(
        tokens.body,
        c.textPrimary,
        size: 14,
        line: 16,
        weight: 500,
        trackingEm: -0.005,
        display: true,
        tabular: true,
      ),
      caption: type(tokens.caption, tertiary, size: 12, line: 16, weight: 500),
      note: type(tokens.caption, tertiary, size: 12, line: 17, weight: 400),
      label: type(tokens.label, c.textPrimary, size: 14, line: 14, weight: 600),
      labelSmall: type(
        tokens.label,
        secondary,
        size: 12,
        line: 12,
        weight: 500,
      ),
      link: type(tokens.label, secondary, size: 14, line: 14, weight: 500),
      tab: type(tokens.caption, tertiary, size: 12, line: 12, weight: 500),
      eyebrow: type(
        tokens.caption,
        tertiary,
        size: 12,
        line: 16,
        weight: 500,
        trackingEm: 0.04,
      ),
      mono: type(
        tokens.mono,
        c.textPrimary,
        size: 14,
        line: 14,
        weight: 500,
        trackingEm: 0.04,
        display: true,
        tabular: true,
      ),
      monoSmall: type(
        tokens.mono,
        secondary,
        size: 12,
        line: 12,
        weight: 500,
        trackingEm: 0.04,
        display: true,
        tabular: true,
      ),
      monogram: type(
        tokens.h3,
        c.textPrimary,
        size: 14,
        line: 14,
        weight: 600,
        trackingEm: -0.01,
        display: true,
      ),
      wordmark: type(
        tokens.h2,
        c.textPrimary,
        size: 24,
        line: 24,
        weight: 600,
        trackingEm: -0.04,
        display: true,
      ),
    );
  }

  /// The default theme, opal, in [brightness], with any knob set: what
  /// `FrostedThemeData()` gives, as Material's `ThemeData()` does.
  ///
  /// ```dart
  /// FrostedTheme(data: FrostedThemeData(density: FrostedDensity.compact), child: app)
  /// ```
  factory FrostedThemeData({
    Brightness brightness = Brightness.light,
    FrostedDensity? density,
    FrostedTypeface? typeface,
    FrostedComponentThemes? components,
    FrostedBackdrop? backdrop,
    bool? opaqueMaterials,
  }) => FrostedThemeData.opal(brightness).copyWith(
    density: density,
    typeface: typeface,
    components: components,
    backdrop: backdrop,
    opaqueMaterials: opaqueMaterials,
  );

  /// Opal, the default: the look as it was drawn, a pale canvas under
  /// three washes of light, glass tiles and one ink act.
  factory FrostedThemeData.opal([Brightness brightness = Brightness.light]) =>
      preset('opal', brightness);

  /// Quartz: cool greys and a violet act.
  factory FrostedThemeData.quartz([Brightness brightness = Brightness.light]) =>
      preset('quartz', brightness);

  /// Garnet: warm whites and a crimson act.
  factory FrostedThemeData.garnet([Brightness brightness = Brightness.light]) =>
      preset('garnet', brightness);

  /// Glacier: cold glass and a teal act.
  factory FrostedThemeData.glacier([
    Brightness brightness = Brightness.light,
  ]) => preset('glacier', brightness);

  /// Cobalt: plain greys and a blue act, closest to a platform's own.
  factory FrostedThemeData.cobalt([Brightness brightness = Brightness.light]) =>
      preset('cobalt', brightness);

  /// Jade: soft whites and a green act.
  factory FrostedThemeData.jade([Brightness brightness = Brightness.light]) =>
      preset('jade', brightness);

  /// Copper: warm greys and an orange act.
  factory FrostedThemeData.copper([Brightness brightness = Brightness.light]) =>
      preset('copper', brightness);

  /// A theme dressed from a few colours, as Material's `ColorScheme.fromSeed`
  /// is: [accent] wears the act (every button, chip and toggle that is on),
  /// and [success], [danger] and [warning] money in, over and a warning,
  /// each the quartz palette's when null. Every role is then settled the
  /// way the presets are (`FrostedThemeData._fromTokens`): the inks eased
  /// until words read 4.5:1 on the glass and under the washes, the spectrum
  /// turned round the wheel from [accent], the washes of light its tints.
  /// At night each colour is eased toward white until it reads 4.5:1 on the
  /// dark canvas.
  ///
  /// ```dart
  /// final theme = FrostedThemeData.from(accent: const Color(0xFF0A7CFF));
  /// ```
  factory FrostedThemeData.from({
    required Color accent,
    Brightness brightness = Brightness.light,
    Color? success,
    Color? danger,
    Color? warning,
    String id = 'custom',
  }) {
    const base = platinumTokens;
    const white = Color(0xFFFFFFFF);
    FrostedTokenColors dress(FrostedTokenColors c, bool dark) {
      final grounds = [c.background, c.surface];
      Color settle(Color ink) => dark ? _reach(ink, white, grounds, 4.5) : ink;
      Color on(Color fill) => contrast(white, fill) >= 4.5
          ? white
          : _reach(c.textPrimary, const Color(0xFF000000), [fill], 4.5);
      Color subtle(Color ink) =>
          Color.alphaBlend(ink.withValues(alpha: dark ? .2 : .1), c.surface);
      final act = settle(accent);
      final good = success == null ? null : settle(success);
      final bad = danger == null ? null : settle(danger);
      final careful = warning == null ? null : settle(warning);
      return c.copyWith(
        accent: act,
        onAccent: on(act),
        accentSubtle: subtle(act),
        accentText: _reach(act, c.textPrimary, grounds, 4.5),
        success: good,
        onSuccess: good == null ? null : on(good),
        successSubtle: good == null ? null : subtle(good),
        danger: bad,
        onDanger: bad == null ? null : on(bad),
        dangerSubtle: bad == null ? null : subtle(bad),
        warning: careful,
        warningSubtle: careful == null ? null : subtle(careful),
      );
    }

    return FrostedThemeData._fromTokens(
      id,
      FrostedTokens(
        light: dress(base.light, false),
        dark: dress(base.dark, true),
        giant: base.giant,
        hero: base.hero,
        display: base.display,
        h1: base.h1,
        h2: base.h2,
        h3: base.h3,
        bodyLarge: base.bodyLarge,
        body: base.body,
        bodySmall: base.bodySmall,
        caption: base.caption,
        label: base.label,
        mono: base.mono,
        shape: base.shape,
      ),
      brightness,
    );
  }

  /// This theme's dark appearance, wearing this theme's knobs: itself when
  /// it is dark, else its preset's dark one (opal's for a theme that is no
  /// preset's). What a media ground (a full-bleed photograph or video)
  /// draws its chrome in when [FrostedTheme] names no dark theme.
  FrostedThemeData get darkTwin {
    if (isDark) return this;
    return _twins[this] ??=
        preset(
          presets.contains(id) ? id : presets.first,
          Brightness.dark,
        ).copyWith(
          density: _density,
          typeface: typeface,
          components: components,
          backdrop: backdrop,
          opaqueMaterials: opaqueMaterials,
        );
  }

  static final Expando<FrostedThemeData> _twins = Expando<FrostedThemeData>(
    'frosted dark',
  );

  /// The preset ids, the first the default.
  static const List<String> presets = <String>[
    'opal',
    'quartz',
    'garnet',
    'glacier',
    'cobalt',
    'jade',
    'copper',
  ];

  /// The theme for preset [id] in [brightness]; an unknown id throws.
  static FrostedThemeData preset(String id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return switch (id) {
      'opal' => dark ? _frostedDark : _frostedLight,
      'quartz' => dark ? _quartzDark : _quartzLight,
      'garnet' => dark ? _garnetDark : _garnetLight,
      'glacier' => dark ? _glacierDark : _glacierLight,
      'cobalt' => dark ? _cobaltDark : _cobaltLight,
      'jade' => dark ? _jadeDark : _jadeLight,
      'copper' => dark ? _copperDark : _copperLight,
      _ => throw ArgumentError.value(
        id,
        'id',
        'not a Frosted preset (${presets.join(', ')})',
      ),
    };
  }

  static final FrostedThemeData _frostedLight = _opal(Brightness.light);
  static final FrostedThemeData _frostedDark = _opal(Brightness.dark);
  static final FrostedThemeData _quartzLight = FrostedThemeData._fromTokens(
    'quartz',
    platinumTokens,
    Brightness.light,
  );
  static final FrostedThemeData _quartzDark = FrostedThemeData._fromTokens(
    'quartz',
    platinumTokens,
    Brightness.dark,
  );
  static final FrostedThemeData _garnetLight = FrostedThemeData._fromTokens(
    'garnet',
    atriumTokens,
    Brightness.light,
  );
  static final FrostedThemeData _garnetDark = FrostedThemeData._fromTokens(
    'garnet',
    atriumTokens,
    Brightness.dark,
  );
  static final FrostedThemeData _glacierLight = FrostedThemeData._fromTokens(
    'glacier',
    frostTokens,
    Brightness.light,
  );
  static final FrostedThemeData _glacierDark = FrostedThemeData._fromTokens(
    'glacier',
    frostTokens,
    Brightness.dark,
  );
  static final FrostedThemeData _cobaltLight = FrostedThemeData._fromTokens(
    'cobalt',
    nativeNeutralTokens,
    Brightness.light,
  );
  static final FrostedThemeData _cobaltDark = FrostedThemeData._fromTokens(
    'cobalt',
    nativeNeutralTokens,
    Brightness.dark,
  );
  static final FrostedThemeData _jadeLight = FrostedThemeData._fromTokens(
    'jade',
    wayfindingTokens,
    Brightness.light,
  );
  static final FrostedThemeData _jadeDark = FrostedThemeData._fromTokens(
    'jade',
    wayfindingTokens,
    Brightness.dark,
  );
  static final FrostedThemeData _copperLight = FrostedThemeData._fromTokens(
    'copper',
    instrumentTokens,
    Brightness.light,
  );
  static final FrostedThemeData _copperDark = FrostedThemeData._fromTokens(
    'copper',
    instrumentTokens,
    Brightness.dark,
  );

  /// The bundled display face every title and figure is set in: Bricolage
  /// Grotesque, one variable file whose weight and optical-size axes every
  /// style sets (the source's `--font-d`).
  static const String face = frostedFontPackage == null
      ? 'BricolageGrotesque'
      : 'packages/$frostedFontPackage/BricolageGrotesque';

  /// The bundled text face: DM Sans, the running copy, the labels and the
  /// chips (the source's `--font-t`).
  static const String textFace = frostedFontPackage == null
      ? 'DMSans'
      : 'packages/$frostedFontPackage/DMSans';

  static const List<FontFeature> _tabular = [FontFeature.tabularFigures()];

  /// A style on one of the two faces: its weight set as a [FontWeight] and
  /// as the face's `wght` axis, its optical size as the `opsz` axis (Chrome
  /// sets it automatically; Flutter does not), clamped to the face's axis
  /// (Bricolage 12..96, DM Sans 9..40).
  static TextStyle _type({
    required String face,
    required double size,
    required double line,
    required int weight,
    required Color color,
    double trackingEm = 0,
    bool tabular = false,
  }) {
    final display = face == FrostedThemeData.face;
    final opsz = display ? size.clamp(12.0, 96.0) : size.clamp(9.0, 40.0);
    return TextStyle(
      fontFamily: face,
      // A glyph the display face lacks comes from the text face, then the
      // platform's own fonts (Noto on the web): Arabic, Hebrew, Chinese,
      // Japanese, Devanagari and Thai never show as boxes.
      fontFamilyFallback: display ? const [textFace] : null,
      fontSize: size,
      fontWeight: FontWeight(weight),
      fontVariations: [
        FontVariation.weight(weight.toDouble()),
        FontVariation.opticalSize(opsz),
      ],
      height: line / size,
      letterSpacing: trackingEm * size,
      fontFeatures: tabular ? _tabular : null,
      leadingDistribution: TextLeadingDistribution.even,
      color: color,
    );
  }

  // --- prism -------------------------------------------------------------------

  /// `prism`: the look as the source stylesheet sets it. Light is the
  /// source's own palette, role for role (the mapping is in `_Source`'s
  /// header); dark is DESIGNED (the source is light only): its night,
  /// `_Night`, light through dark glass, held to the same contrast bar by the
  /// tests.
  static FrostedThemeData _opal(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final ink = dark ? _Night.ink : _Source.ink;
    final lights = dark
        ? const FrostedLights(
            lilac: _Night.lightLilac,
            rose: _Night.lightRose,
            peach: _Night.lightPeach,
            strength: _Night.lightStrength,
          )
        : const FrostedLights(
            lilac: _Source.lightLilac,
            rose: _Source.lightRose,
            peach: _Source.lightPeach,
            strength: 1,
          );
    final canvas = dark ? _Night.canvas : _Source.canvas;
    final read = [
      canvas,
      if (dark) _Night.surface else _Source.surface,
      ...lights.peaksOver(canvas, night: dark),
    ];
    // The source's quieter inks, eased toward the page ink as far as it takes
    // to read 4.5:1 on the washes: under the brightest of them the three meet.
    Color reading(Color quiet) => _reach(quiet, ink, read, 4.6);
    final ink2 = reading(dark ? _Night.ink2 : _Source.ink2);
    final ink3 = reading(dark ? _Night.ink3 : _Source.ink3);
    // Money in and over are words too (an amount, an over note): eased the
    // same way, on the washes and on their own tint.
    Color tone(Color ink0, Color tint) => _reach(ink0, ink, [
      ...read,
      for (final g in read) Color.alphaBlend(tint, g),
    ], 4.6);
    final moneyIn = tone(
      dark ? _Night.moneyIn : _Source.moneyIn,
      dark ? _Night.moneyInTint : _Source.moneyInTint,
    );
    final over = tone(
      dark ? _Night.over : _Source.over,
      dark ? _Night.overTint : _Source.overTint,
    );
    // The card's quiet words on the pearl and its blush.
    final pearlBase = [
      for (final p in [
        dark ? _Night.pearlFrom : _Source.pearlFrom,
        dark ? _Night.pearlTo : _Source.pearlTo,
      ])
        Color.alphaBlend(p, canvas),
    ];
    // Its tags (the kind, the note) stand on their pill over both, under the
    // card's sheen and its specular band where they cross it.
    final pearlSheens = dark ? FrostedSheens.night : FrostedSheens.day;
    Color pearlLit(Color g) => Color.alphaBlend(
      pearlSheens.specular,
      Color.alphaBlend(pearlSheens.cardSheen, g),
    );
    final pearlQuiet = _reach(ink2, ink, [
      for (final g in [
        ...pearlBase,
        for (final b in pearlBase)
          Color.alphaBlend(dark ? _Night.pearlBlush : _Source.pearlBlush, b),
      ]) ...[
        g,
        pearlLit(g),
        Color.alphaBlend(pearlSheens.pillFill, g),
        Color.alphaBlend(pearlSheens.pillFill, pearlLit(g)),
      ],
    ], 4.6);
    final warn = tone(
      dark ? _Night.warn : _Source.warn,
      dark ? _Night.warnTint : _Source.warnTint,
    );
    final cold = tone(
      dark ? _Night.cold : _Source.cold,
      dark ? _Night.coldTint : _Source.coldTint,
    );
    final white = dark ? _Night.plane : _Source.white;
    TextStyle type({
      required double size,
      required double line,
      required int weight,
      double trackingEm = 0,
      Color? color,
      bool display = false,
      bool tabular = false,
    }) => _type(
      face: display ? face : textFace,
      size: size,
      line: line,
      weight: weight,
      trackingEm: trackingEm,
      color: color ?? ink,
      tabular: tabular,
    );
    Color a(Color c, double alpha) => c.withValues(alpha: alpha);
    return FrostedThemeData._raw(
      id: 'opal',
      brightness: brightness,
      background: dark ? _Night.canvas : _Source.canvas,
      surface: dark ? _Night.surface : _Source.surface,
      surfaceAlt: dark ? _Night.surfaceAlt : _Source.surfaceAlt,
      surfaceInverse: dark ? _Night.actBottom : _Source.inkBottom,
      borderStrong: dark ? _Night.borderStrong : _Source.borderStrong,
      textPrimary: ink,
      textSecondary: ink2,
      textTertiary: ink3,
      textInverse: dark ? _Source.ink : _Source.white,
      accent: ink,
      onAccent: dark ? _Source.ink : _Source.white,
      accentSubtle: dark ? _Night.wash : _Source.wash,
      success: moneyIn,
      // White words where they read on the fill, else the day's ink: by
      // night the danger pink read 2.18:1 under white.
      onSuccess: contrast(_Source.white, moneyIn) >= 4.5
          ? _Source.white
          : _Source.ink,
      successSubtle: dark ? _Night.moneyInTint : _Source.moneyInTint,
      warning: warn,
      warningSubtle: dark ? _Night.warnTint : _Source.warnTint,
      danger: over,
      onDanger: contrast(_Source.white, over) >= 4.5
          ? _Source.white
          : _Source.ink,
      dangerSubtle: dark ? _Night.overTint : _Source.overTint,
      overlay: dark ? _Night.scrim : _Source.scrim,
      accentText: ink,
      hairline: dark ? _Night.line : _Source.line,
      wash: dark ? _Night.wash : _Source.wash,
      glass: dark ? _Night.glass : _Source.glass,
      glassHi: dark ? _Night.glassHi : _Source.glassHi,
      // By day a pane's edge is the lit hairline, never a dark line.
      glassEdge: dark ? _Night.edge : _Source.litEdge,
      glassRim: dark ? _Night.rim : _Source.rim,
      well: dark ? _Night.well : _Source.well,
      wellEdge: dark ? _Night.wellEdge : _Source.litEdge,
      plane: white,
      actTop: dark ? _Night.actTop : _Source.inkTop,
      actBottom: dark ? _Night.actBottom : _Source.inkBottom,
      actSheen: dark ? _Night.actSheen : _Source.inkSheen,
      onAct: dark ? _Source.ink : _Source.white,
      ringInner: white,
      ringOuter: dark ? _Night.ringOuter : _Source.ringOuter,
      moneyIn: moneyIn,
      moneyInTint: dark ? _Night.moneyInTint : _Source.moneyInTint,
      over: over,
      overTint: dark ? _Night.overTint : _Source.overTint,
      cold: cold,
      coldTint: dark ? _Night.coldTint : _Source.coldTint,
      coldEdge: dark ? _Night.coldEdge : _Source.coldEdge,
      hues: _heldHues(dark ? _Night.hues : _Source.hues, ink, read),
      lights: lights,
      rimStops: _Source.rimStops,
      pearlFrom: dark ? _Night.pearlFrom : _Source.pearlFrom,
      pearlTo: dark ? _Night.pearlTo : _Source.pearlTo,
      pearlBlush: dark ? _Night.pearlBlush : _Source.pearlBlush,
      pearlRim: _Source.pearlRim,
      pearlGlow: dark ? _Night.pearlGlow : _Source.pearlGlow,
      pearlInk: ink,
      pearlInkQuiet: pearlQuiet,
      utilFrom: _Source.utilFrom,
      utilTo: _Source.utilTo,
      utilTrack: dark ? _Night.utilTrack : _Source.utilTrack,
      avatarStops: dark ? _Night.avatarStops : _Source.avatarStops,
      charts: dark ? _Night.charts : _Source.charts,
      sheens: dark ? FrostedSheens.night : FrostedSheens.day,
      topFrost: dark ? _Night.topFrost : _Source.topFrost,
      barFill: dark ? _Night.barFill : _Source.barFill,
      barFade: dark ? _Night.canvas : _Source.canvas,
      sideFill: dark ? _Night.sideFill : _Source.sideFill,
      sideEdge: dark ? _Night.line : _Source.litEdge,
      navCurrent: dark ? _Night.navCurrent : _Source.navCurrent,
      sheetTop: dark ? _Night.sheetTop : _Source.sheetTop,
      sheetBottom: dark ? _Night.sheetBottom : _Source.sheetBottom,
      sheetEdge: dark ? _Night.sheetEdge : _Source.sheetEdge,
      grabber: dark ? _Night.grabber : _Source.grabber,
      menuFill: dark ? _Night.menuFill : _Source.menuFill,
      menuEdge: dark ? _Night.menuEdge : _Source.menuEdge,
      toastTop: dark ? _Night.toastTop : _Source.toastTop,
      toastBottom: dark ? _Night.toastBottom : _Source.toastBottom,
      onToast: dark ? _Night.ink : _Source.white,
      toastSheen: dark ? _Night.toastSheen : _Source.toastSheen,
      toastMarkFill: dark ? _Night.moneyInTint : _Source.toastMarkFill,
      toastMarkInk: dark ? _Night.moneyIn : _Source.toastMarkInk,
      toastAction: dark ? _Night.toastAction : _Source.toastAction,
      unreadDot: _Source.unreadDot,
      trackFill: dark ? _Night.trackFill : _Source.trackFill,
      trackEdge: dark ? _Night.trackEdge : _Source.trackEdge,
      meterTrack: dark ? _Night.meterTrack : _Source.meterTrack,
      paceTick: dark ? _Night.paceTick : _Source.paceTick,
      paceRing: dark ? _Night.paceRing : _Source.paceRing,
      toggleTrack: dark ? _Night.toggleTrack : _Source.toggleTrack,
      knob: white,
      lift: [_css(10, 28, -20, dark ? _Night.liftShade : _Source.liftShade)],
      barShadow: [_css(14, 32, -18, dark ? _Night.barShade : _Source.barShade)],
      sheetShadow: [
        _css(-18, 48, -24, dark ? _Night.sheetShade : _Source.sheetShade),
      ],
      dialogShadow: [
        _css(18, 48, -24, dark ? _Night.sheetShade : _Source.sheetShade),
      ],
      menuShadow: [
        _css(22, 44, -18, dark ? _Night.barShade : _Source.barShade),
      ],
      toastShadow: [
        _css(18, 40, -18, dark ? _Night.toastShade : _Source.toastShade),
      ],
      actShadow: [_css(8, 18, -12, dark ? _Night.actShade : _Source.actShade)],
      raisedShadow: [
        _css(2, 6, -2, dark ? _Night.raisedShade : _Source.raisedShade),
      ],
      pearlShadow: [
        _css(18, 36, -22, dark ? _Night.pearlShade : _Source.pearlShade),
      ],
      ticketShadow: [
        _css(6, 16, -12, dark ? _Night.ticketShade : _Source.ticketShade),
      ],
      knobShadow: [
        _css(1, 3, 0, a(dark ? _Night.knobShade : _Source.inkDeep, 0.22)),
        BoxShadow(
          color: a(dark ? _Night.knobShade : _Source.inkDeep, 0.06),
          spreadRadius: 0.5,
        ),
      ],
      giant: type(
        size: 96,
        line: 83,
        weight: 500,
        trackingEm: -0.035,
        display: true,
      ),
      display: type(
        size: 64,
        line: 55,
        weight: 500,
        trackingEm: -0.035,
        display: true,
      ),
      figure: type(
        size: 40,
        line: 34,
        weight: 500,
        trackingEm: -0.03,
        display: true,
      ),
      figureSmall: type(
        size: 28,
        line: 24,
        weight: 500,
        trackingEm: -0.025,
        display: true,
      ),
      stat: type(
        size: 20,
        line: 22,
        weight: 500,
        trackingEm: -0.02,
        display: true,
        tabular: true,
      ),
      hero: type(
        size: 28,
        line: 31,
        weight: 500,
        trackingEm: -0.03,
        display: true,
      ),
      h1: type(
        size: 20,
        line: 22,
        weight: 600,
        trackingEm: -0.02,
        display: true,
      ),
      h2: type(
        size: 16,
        line: 20,
        weight: 600,
        trackingEm: -0.01,
        display: true,
      ),
      h3: type(
        size: 14,
        line: 14,
        weight: 600,
        trackingEm: -0.01,
        display: true,
      ),
      bodyLarge: type(size: 16, line: 22, weight: 400),
      body: type(size: 16, line: 20, weight: 500),
      bodySmall: type(size: 14, line: 19, weight: 400, color: ink2),
      amount: type(
        size: 16,
        line: 20,
        weight: 500,
        trackingEm: -0.005,
        display: true,
        tabular: true,
      ),
      amountSmall: type(
        size: 14,
        line: 16,
        weight: 500,
        trackingEm: -0.005,
        display: true,
        tabular: true,
      ),
      caption: type(size: 12, line: 16, weight: 500, color: ink3),
      note: type(size: 12, line: 17, weight: 400, color: ink3),
      label: type(size: 14, line: 14, weight: 600),
      labelSmall: type(size: 12, line: 12, weight: 500, color: ink2),
      link: type(size: 14, line: 14, weight: 500, color: ink2),
      tab: type(size: 12, line: 12, weight: 500, color: ink3),
      eyebrow: type(
        size: 12,
        line: 16,
        weight: 500,
        trackingEm: 0.04,
        color: ink3,
      ),
      mono: type(
        size: 14,
        line: 14,
        weight: 500,
        trackingEm: 0.04,
        display: true,
        tabular: true,
      ),
      monoSmall: type(
        size: 12,
        line: 12,
        weight: 500,
        trackingEm: 0.04,
        color: ink2,
        display: true,
        tabular: true,
      ),
      monogram: type(
        size: 14,
        line: 14,
        weight: 600,
        trackingEm: -0.01,
        display: true,
      ),
      wordmark: type(
        size: 24,
        line: 24,
        weight: 600,
        trackingEm: -0.04,
        display: true,
      ),
    );
  }

  /// Which preset this theme is (see [presets]).
  final String id;

  /// Which appearance this theme is.
  final Brightness brightness;

  /// The theme's colours by role: the page, its words, the accent, the tones,
  /// money's inks and the controls' own.
  final FrostedColorScheme colorScheme;

  /// The theme's text styles: Material's `TextTheme` slots, by role and size,
  /// and the look's own (a stat, an amount, a link, a tab, figures of one
  /// width, a monogram, the wordmark).
  final FrostedTextTheme textTheme;

  /// The shadows the theme's faces cast.
  final FrostedShadows shadows;

  /// The glass's colours: a tile's frosted fill, its edge and rim, a field's
  /// well, the bars, the sidebar, a sheet, a menu and the prism bar's tube.
  final FrostedGlassColors glass;

  /// The pearl's colours: the pale credit card, its words and its usage bar,
  /// and an avatar's pearl.
  final FrostedPearlColors pearl;

  /// The toast's colours: its slab, the words and the light on it, its mark and
  /// its action.
  final FrostedToastColors toast;

  /// Every hue the source names: the spectrum's categories, the objects,
  /// money in, a move, the allocation bands.
  final FrostedHues hues;

  /// The washes of light behind the glass.
  final FrostedLights lights;

  /// The inks the charts are drawn in.
  final FrostedChartInks charts;

  /// The light laid on the marks and the objects (see [FrostedSheens]).
  final FrostedSheens sheens;

  // Type scale: complete styles with family, size, weight, height and colour
  // baked in. The display face is Bricolage Grotesque, the text face DM Sans.

  // The knobs: each the look's own unless the app sets it, as Material's
  // ThemeData carries its shape, density and component themes.

  /// How compact the controls stand; the touch target never shrinks. Unset,
  /// it follows the platform ([FrostedDensity.adaptivePlatformDensity]:
  /// compact on macOS, Windows and Linux, standard on touch).
  FrostedDensity get density =>
      _density ?? FrostedDensity.adaptivePlatformDensity;

  final FrostedDensity? _density;

  /// The faces and the size scale the type is set in. Set through
  /// [copyWith], which sets every type slot in the new faces.
  final FrostedTypeface typeface;

  /// One [FrostedStyle] per part, theme-wide; a widget's own `style:` wins.
  final FrostedComponentThemes components;

  /// What stands behind every page for the glass to show: the preset's
  /// light (the default), a night sky, an image or a plain colour.
  final FrostedBackdrop backdrop;

  /// Whether every glass draws its opaque form, for those who find
  /// transparency hard to read; the host turns it on when the platform
  /// reports high contrast.
  final bool opaqueMaterials;

  /// The theme's glass ([FrostedMaterials.derive]): each material's
  /// blur, tint, rim and shadow, its tint derived from the text.
  FrostedMaterials get materials => FrostedMaterials.derive(this);

  /// The colour a control's boundary and its state are drawn in where
  /// nothing else shows them: an off switch's track and knob, an empty check
  /// or radio, a field's edge, the chosen segment, chip, tab or link. It
  /// reads 3:1 (WCAG 1.4.11) on the page, the surface, the wash and every
  /// glass over any backdrop ([FrostedMaterials.grounds]).
  Color get controlEdge => frostedRestRing(this);

  /// Whether this theme is a dark appearance.
  bool get isDark => brightness == Brightness.dark;

  /// The hue of the [index]th category, round the spectrum.
  FrostedHue hue(int index) {
    final categories = hues.categories;
    return categories[index % categories.length];
  }

  /// The ink of a figure of [flow]: money in's green, else the page ink (a
  /// move the quiet ink).
  Color flowInk(FrostedMoneyFlow flow) => switch (flow) {
    FrostedMoneyFlow.inflow => colorScheme.moneyIn,
    FrostedMoneyFlow.transfer => colorScheme.textSecondary,
    _ => colorScheme.textPrimary,
  };

  /// The ink a tone's words wear.
  Color toneInk(FrostedTone tone) => switch (tone) {
    FrostedTone.quiet => colorScheme.textSecondary,
    FrostedTone.success => colorScheme.moneyIn,
    FrostedTone.danger => colorScheme.over,
    FrostedTone.warning => colorScheme.warning,
    FrostedTone.info => colorScheme.cold,
  };

  /// The tint a tone stands on.
  Color toneTint(FrostedTone tone) => switch (tone) {
    FrostedTone.quiet => glass.wash,
    FrostedTone.success => colorScheme.moneyInTint,
    FrostedTone.danger => colorScheme.overTint,
    FrostedTone.warning => colorScheme.warningSubtle,
    FrostedTone.info => colorScheme.coldTint,
  };

  /// [ink] eased toward [toward] in steps until it reaches [min]:1 on every
  /// one of [grounds]; [ink] itself when it already does.
  static Color _reach(
    Color ink,
    Color toward,
    List<Color> grounds,
    double min,
  ) {
    for (var i = 0; i <= 20; i++) {
      final c = Color.lerp(ink, toward, i / 20)!;
      if (grounds.every((g) => contrast(c, g) >= min)) return c;
    }
    return toward;
  }

  /// The WCAG contrast ratio of [ink] on [ground], 1..21, as it is seen:
  /// a translucent ink is laid over the ground first. [ground] is opaque.
  static double contrast(Color ink, Color ground) {
    final seen = Color.alphaBlend(ink, ground);
    final la = seen.computeLuminance();
    final lb = ground.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }

  /// This theme with the named values replaced, as Material's
  /// `ThemeData.copyWith`. A new [typeface] sets every style of [textTheme]
  /// in its faces and at its scale, unless a [textTheme] is given too.
  ///
  /// ```dart
  /// final theme = FrostedThemeData.opal().copyWith(
  ///   colorScheme: FrostedThemeData.opal().colorScheme.copyWith(accent: const Color(0xFF3A5BD9)),
  ///   density: FrostedDensity.compact,
  /// );
  /// ```
  FrostedThemeData copyWith({
    String? id,
    Brightness? brightness,
    FrostedColorScheme? colorScheme,
    FrostedTextTheme? textTheme,
    FrostedShadows? shadows,
    FrostedGlassColors? glass,
    FrostedPearlColors? pearl,
    FrostedToastColors? toast,
    FrostedHues? hues,
    FrostedLights? lights,
    FrostedChartInks? charts,
    FrostedSheens? sheens,
    FrostedDensity? density,
    FrostedTypeface? typeface,
    FrostedComponentThemes? components,
    FrostedBackdrop? backdrop,
    bool? opaqueMaterials,
  }) {
    final from = this.typeface;
    final to = typeface ?? from;
    return FrostedThemeData._(
      id: id ?? this.id,
      brightness: brightness ?? this.brightness,
      colorScheme: colorScheme ?? this.colorScheme,
      textTheme:
          textTheme ??
          (to == from
              ? this.textTheme
              : this.textTheme._map((style) => _retyped(style, from, to))),
      shadows: shadows ?? this.shadows,
      glass: glass ?? this.glass,
      pearl: pearl ?? this.pearl,
      toast: toast ?? this.toast,
      hues: hues ?? this.hues,
      lights: lights ?? this.lights,
      charts: charts ?? this.charts,
      sheens: sheens ?? this.sheens,
      density: density ?? _density,
      typeface: typeface ?? this.typeface,
      components: components ?? this.components,
      backdrop: backdrop ?? this.backdrop,
      opaqueMaterials: opaqueMaterials ?? this.opaqueMaterials,
    );
  }

  /// Between this theme and [other], as Material's `ThemeData.lerp`: every
  /// colour, shadow, type slot and knob eases; the id and the brightness
  /// change at the middle. `AnimatedFrostedTheme` animates with it.
  FrostedThemeData lerp(FrostedThemeData? other, double t) {
    if (other == null || identical(this, other) || t == 0) return this;
    if (t == 1) return other;
    final a = this, b = other;
    return FrostedThemeData._(
      id: t < .5 ? a.id : b.id,
      brightness: t < .5 ? a.brightness : b.brightness,
      colorScheme: FrostedColorScheme.lerp(a.colorScheme, b.colorScheme, t),
      textTheme: FrostedTextTheme.lerp(a.textTheme, b.textTheme, t),
      shadows: FrostedShadows.lerp(a.shadows, b.shadows, t),
      glass: FrostedGlassColors.lerp(a.glass, b.glass, t),
      pearl: FrostedPearlColors.lerp(a.pearl, b.pearl, t),
      toast: FrostedToastColors.lerp(a.toast, b.toast, t),
      hues: FrostedHues.lerp(a.hues, b.hues, t),
      lights: FrostedLights.lerp(a.lights, b.lights, t),
      charts: FrostedChartInks.lerp(a.charts, b.charts, t),
      sheens: FrostedSheens.lerp(a.sheens, b.sheens, t),
      density: a._density == null && b._density == null
          ? null
          : FrostedDensity.lerp(a.density, b.density, t),
      typeface: FrostedTypeface.lerp(a.typeface, b.typeface, t),
      components: FrostedComponentThemes.lerp(a.components, b.components, t),
      backdrop: t < .5 ? a.backdrop : b.backdrop,
      opaqueMaterials: t < .5 ? a.opaqueMaterials : b.opaqueMaterials,
    );
  }

  List<Object?> get _values => [
    id,
    brightness,
    colorScheme,
    textTheme,
    shadows,
    glass,
    pearl,
    toast,
    hues,
    lights,
    charts,
    sheens,
    _density,
    typeface,
    components,
    backdrop,
    opaqueMaterials,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedThemeData && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(DiagnosticsProperty<FrostedColorScheme>('colorScheme', colorScheme))
      ..add(DiagnosticsProperty<FrostedTextTheme>('textTheme', textTheme))
      ..add(DiagnosticsProperty<FrostedShadows>('shadows', shadows))
      ..add(DiagnosticsProperty<FrostedGlassColors>('glass', glass))
      ..add(DiagnosticsProperty<FrostedPearlColors>('pearl', pearl))
      ..add(DiagnosticsProperty<FrostedToastColors>('toast', toast))
      ..add(
        DiagnosticsProperty<FrostedHues>(
          'hues',
          hues,
          level: DiagnosticLevel.debug,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedLights>(
          'lights',
          lights,
          level: DiagnosticLevel.debug,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedChartInks>(
          'charts',
          charts,
          level: DiagnosticLevel.debug,
        ),
      )
      ..add(
        DiagnosticsProperty<FrostedSheens>(
          'sheens',
          sheens,
          level: DiagnosticLevel.debug,
        ),
      )
      ..add(DiagnosticsProperty<FrostedDensity>('density', density))
      ..add(DiagnosticsProperty<FrostedTypeface>('typeface', typeface))
      ..add(
        DiagnosticsProperty<FrostedComponentThemes>('components', components),
      )
      ..add(DiagnosticsProperty<FrostedBackdrop>('backdrop', backdrop))
      ..add(
        FlagProperty(
          'opaqueMaterials',
          value: opaqueMaterials,
          ifTrue: 'opaque materials',
        ),
      );
  }

  /// [style] set in [to]'s faces, from [from]'s.
  static TextStyle _retyped(
    TextStyle style,
    FrostedTypeface from,
    FrostedTypeface to,
  ) {
    final display = style.fontFamily == from.displayFamily;
    final family = display ? to.displayFamily : to.textFamily;
    final size = style.fontSize;
    return style.copyWith(
      fontFamily: family,
      fontFamilyFallback: display ? [to.textFamily] : null,
      fontVariations: style.fontVariations == null || size == null
          ? style.fontVariations
          : [
              for (final v in style.fontVariations!)
                v.axis == 'opsz'
                    ? FontVariation.opticalSize(
                        display
                            ? size.clamp(12.0, 96.0)
                            : size.clamp(9.0, 40.0),
                      )
                    : v,
            ],
    );
  }
}

/// The theme's colours by role: the page, its words, the accent, the tones,
/// money's inks and the controls' own.
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.colorScheme]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedColorScheme with Diagnosticable {
  /// Creates a [FrostedColorScheme]; every value is required.
  const FrostedColorScheme({
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.surfaceInverse,
    required this.border,
    required this.borderStrong,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textInverse,
    required this.accent,
    required this.onAccent,
    required this.accentSubtle,
    required this.accentText,
    required this.success,
    required this.onSuccess,
    required this.successSubtle,
    required this.warning,
    required this.warningSubtle,
    required this.danger,
    required this.onDanger,
    required this.dangerSubtle,
    required this.overlay,
    required this.buttonTop,
    required this.buttonBottom,
    required this.buttonSheen,
    required this.onButton,
    required this.ringInner,
    required this.ringOuter,
    required this.moneyIn,
    required this.moneyInTint,
    required this.over,
    required this.overTint,
    required this.cold,
    required this.coldTint,
    required this.coldEdge,
    required this.unreadDot,
    required this.meterTrack,
    required this.paceTick,
    required this.paceTickRing,
    required this.toggleTrack,
    required this.toggleKnob,
  });

  /// The canvas the page stands on, under the washes of light.
  final Color background;

  /// A glass tile's face as it reads over the canvas, made opaque: the
  /// stand-in for a card, a list or a field where glass cannot be drawn.
  final Color surface;

  /// The quieter face inside a tile: the wash over the surface.
  final Color surfaceAlt;

  /// The ink as a face: the act's pill, the toast's slab.
  final Color surfaceInverse;

  /// The rule between rows, settings and facts, and down the sidebar's edge
  /// (`--line`).
  final Color border;

  /// A firmer edge: the sheet's grabber, a statement's due mark.
  final Color borderStrong;

  /// The page's words: a row's title, a figure (`--ink`).
  final Color textPrimary;

  /// Quieter words: a row's second line, a label, a link (`--ink-2`).
  final Color textSecondary;

  /// The caption ink: a cap, a tab at rest, a note, an axis label
  /// (`--ink-3`).
  final Color textTertiary;

  /// Words on [surfaceInverse]: a button's, a toast's.
  final Color textInverse;

  /// The one accent: the ink. The source has none apart from it; every act
  /// is the ink pill.
  final Color accent;

  /// The ink on an [accent] face.
  final Color onAccent;

  /// The accent's wash: the wash itself.
  final Color accentSubtle;

  /// An accent-coloured WORD: the ink.
  final Color accentText;

  /// The good tone: money in, a goal on track, a kept budget (`--in`).
  final Color success;

  /// The ink on a [success] face.
  final Color onSuccess;

  /// The good wash (`--in-t`).
  final Color successSubtle;

  /// The warning tone: a budget nearly spent, a nudge (`--warn`).
  final Color warning;

  /// The warning wash (`--warn-t`).
  final Color warningSubtle;

  /// The bad tone: over budget, a destructive act (`--over`).
  final Color danger;

  /// The ink on a [danger] face.
  final Color onDanger;

  /// The bad wash (`--over-t`).
  final Color dangerSubtle;

  /// The scrim under a sheet, a dialog or a menu.
  final Color overlay;

  /// The act's pill at its top; it falls to [buttonBottom] (`--ink-fill`).
  final Color buttonTop;

  /// The act's pill at its foot.
  final Color buttonBottom;

  /// The light along the act's top inside edge.
  final Color buttonSheen;

  /// The ink on the act.
  final Color onButton;

  /// The focus ring round a lit act: its inner white and its outer ink.
  final Color ringInner;

  /// See [ringInner].
  final Color ringOuter;

  /// Money in: an amount that came in, a positive change (`--in`).
  final Color moneyIn;

  /// Money in's tint (`--in-t`).
  final Color moneyInTint;

  /// Over budget: the spill of a meter, an amount past its budget
  /// (`--over`).
  final Color over;

  /// Over budget's tint (`--over-t`).
  final Color overTint;

  /// The cold of a frozen card: its ink, tint and edge (`--cold`).
  final Color cold;

  /// See [cold].
  final Color coldTint;

  /// See [cold].
  final Color coldEdge;

  /// The unread dot on the bell and the ring round it.
  final Color unreadDot;

  /// The track of a meter on a pane's floor.
  final Color meterTrack;

  /// The pace tick across a bar and the ring round it.
  final Color paceTick;

  /// See [paceTick].
  final Color paceTickRing;

  /// A toggle's track when off, and its knob.
  final Color toggleTrack;

  /// See [toggleTrack].
  final Color toggleKnob;

  /// The act's fill: [buttonTop] falling to [buttonBottom] (`--ink-fill`).
  LinearGradient get buttonFill => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [buttonTop, buttonBottom],
  );

  /// This FrostedColorScheme with the named values replaced.
  FrostedColorScheme copyWith({
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? surfaceInverse,
    Color? border,
    Color? borderStrong,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textInverse,
    Color? accent,
    Color? onAccent,
    Color? accentSubtle,
    Color? accentText,
    Color? success,
    Color? onSuccess,
    Color? successSubtle,
    Color? warning,
    Color? warningSubtle,
    Color? danger,
    Color? onDanger,
    Color? dangerSubtle,
    Color? overlay,
    Color? buttonTop,
    Color? buttonBottom,
    Color? buttonSheen,
    Color? onButton,
    Color? ringInner,
    Color? ringOuter,
    Color? moneyIn,
    Color? moneyInTint,
    Color? over,
    Color? overTint,
    Color? cold,
    Color? coldTint,
    Color? coldEdge,
    Color? unreadDot,
    Color? meterTrack,
    Color? paceTick,
    Color? paceTickRing,
    Color? toggleTrack,
    Color? toggleKnob,
  }) => FrostedColorScheme(
    background: background ?? this.background,
    surface: surface ?? this.surface,
    surfaceAlt: surfaceAlt ?? this.surfaceAlt,
    surfaceInverse: surfaceInverse ?? this.surfaceInverse,
    border: border ?? this.border,
    borderStrong: borderStrong ?? this.borderStrong,
    textPrimary: textPrimary ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary: textTertiary ?? this.textTertiary,
    textInverse: textInverse ?? this.textInverse,
    accent: accent ?? this.accent,
    onAccent: onAccent ?? this.onAccent,
    accentSubtle: accentSubtle ?? this.accentSubtle,
    accentText: accentText ?? this.accentText,
    success: success ?? this.success,
    onSuccess: onSuccess ?? this.onSuccess,
    successSubtle: successSubtle ?? this.successSubtle,
    warning: warning ?? this.warning,
    warningSubtle: warningSubtle ?? this.warningSubtle,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    dangerSubtle: dangerSubtle ?? this.dangerSubtle,
    overlay: overlay ?? this.overlay,
    buttonTop: buttonTop ?? this.buttonTop,
    buttonBottom: buttonBottom ?? this.buttonBottom,
    buttonSheen: buttonSheen ?? this.buttonSheen,
    onButton: onButton ?? this.onButton,
    ringInner: ringInner ?? this.ringInner,
    ringOuter: ringOuter ?? this.ringOuter,
    moneyIn: moneyIn ?? this.moneyIn,
    moneyInTint: moneyInTint ?? this.moneyInTint,
    over: over ?? this.over,
    overTint: overTint ?? this.overTint,
    cold: cold ?? this.cold,
    coldTint: coldTint ?? this.coldTint,
    coldEdge: coldEdge ?? this.coldEdge,
    unreadDot: unreadDot ?? this.unreadDot,
    meterTrack: meterTrack ?? this.meterTrack,
    paceTick: paceTick ?? this.paceTick,
    paceTickRing: paceTickRing ?? this.paceTickRing,
    toggleTrack: toggleTrack ?? this.toggleTrack,
    toggleKnob: toggleKnob ?? this.toggleKnob,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedColorScheme lerp(
    FrostedColorScheme a,
    FrostedColorScheme b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedColorScheme(
      background: Color.lerp(a.background, b.background, t)!,
      surface: Color.lerp(a.surface, b.surface, t)!,
      surfaceAlt: Color.lerp(a.surfaceAlt, b.surfaceAlt, t)!,
      surfaceInverse: Color.lerp(a.surfaceInverse, b.surfaceInverse, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      borderStrong: Color.lerp(a.borderStrong, b.borderStrong, t)!,
      textPrimary: Color.lerp(a.textPrimary, b.textPrimary, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      textTertiary: Color.lerp(a.textTertiary, b.textTertiary, t)!,
      textInverse: Color.lerp(a.textInverse, b.textInverse, t)!,
      accent: Color.lerp(a.accent, b.accent, t)!,
      onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
      accentSubtle: Color.lerp(a.accentSubtle, b.accentSubtle, t)!,
      accentText: Color.lerp(a.accentText, b.accentText, t)!,
      success: Color.lerp(a.success, b.success, t)!,
      onSuccess: Color.lerp(a.onSuccess, b.onSuccess, t)!,
      successSubtle: Color.lerp(a.successSubtle, b.successSubtle, t)!,
      warning: Color.lerp(a.warning, b.warning, t)!,
      warningSubtle: Color.lerp(a.warningSubtle, b.warningSubtle, t)!,
      danger: Color.lerp(a.danger, b.danger, t)!,
      onDanger: Color.lerp(a.onDanger, b.onDanger, t)!,
      dangerSubtle: Color.lerp(a.dangerSubtle, b.dangerSubtle, t)!,
      overlay: Color.lerp(a.overlay, b.overlay, t)!,
      buttonTop: Color.lerp(a.buttonTop, b.buttonTop, t)!,
      buttonBottom: Color.lerp(a.buttonBottom, b.buttonBottom, t)!,
      buttonSheen: Color.lerp(a.buttonSheen, b.buttonSheen, t)!,
      onButton: Color.lerp(a.onButton, b.onButton, t)!,
      ringInner: Color.lerp(a.ringInner, b.ringInner, t)!,
      ringOuter: Color.lerp(a.ringOuter, b.ringOuter, t)!,
      moneyIn: Color.lerp(a.moneyIn, b.moneyIn, t)!,
      moneyInTint: Color.lerp(a.moneyInTint, b.moneyInTint, t)!,
      over: Color.lerp(a.over, b.over, t)!,
      overTint: Color.lerp(a.overTint, b.overTint, t)!,
      cold: Color.lerp(a.cold, b.cold, t)!,
      coldTint: Color.lerp(a.coldTint, b.coldTint, t)!,
      coldEdge: Color.lerp(a.coldEdge, b.coldEdge, t)!,
      unreadDot: Color.lerp(a.unreadDot, b.unreadDot, t)!,
      meterTrack: Color.lerp(a.meterTrack, b.meterTrack, t)!,
      paceTick: Color.lerp(a.paceTick, b.paceTick, t)!,
      paceTickRing: Color.lerp(a.paceTickRing, b.paceTickRing, t)!,
      toggleTrack: Color.lerp(a.toggleTrack, b.toggleTrack, t)!,
      toggleKnob: Color.lerp(a.toggleKnob, b.toggleKnob, t)!,
    );
  }

  List<Object?> get _values => [
    background,
    surface,
    surfaceAlt,
    surfaceInverse,
    border,
    borderStrong,
    textPrimary,
    textSecondary,
    textTertiary,
    textInverse,
    accent,
    onAccent,
    accentSubtle,
    accentText,
    success,
    onSuccess,
    successSubtle,
    warning,
    warningSubtle,
    danger,
    onDanger,
    dangerSubtle,
    overlay,
    buttonTop,
    buttonBottom,
    buttonSheen,
    onButton,
    ringInner,
    ringOuter,
    moneyIn,
    moneyInTint,
    over,
    overTint,
    cold,
    coldTint,
    coldEdge,
    unreadDot,
    meterTrack,
    paceTick,
    paceTickRing,
    toggleTrack,
    toggleKnob,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedColorScheme && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('background', background))
      ..add(ColorProperty('surface', surface))
      ..add(ColorProperty('surfaceAlt', surfaceAlt))
      ..add(ColorProperty('surfaceInverse', surfaceInverse))
      ..add(ColorProperty('border', border))
      ..add(ColorProperty('borderStrong', borderStrong))
      ..add(ColorProperty('textPrimary', textPrimary))
      ..add(ColorProperty('textSecondary', textSecondary))
      ..add(ColorProperty('textTertiary', textTertiary))
      ..add(ColorProperty('textInverse', textInverse))
      ..add(ColorProperty('accent', accent))
      ..add(ColorProperty('onAccent', onAccent))
      ..add(ColorProperty('accentSubtle', accentSubtle))
      ..add(ColorProperty('accentText', accentText))
      ..add(ColorProperty('success', success))
      ..add(ColorProperty('onSuccess', onSuccess))
      ..add(ColorProperty('successSubtle', successSubtle))
      ..add(ColorProperty('warning', warning))
      ..add(ColorProperty('warningSubtle', warningSubtle))
      ..add(ColorProperty('danger', danger))
      ..add(ColorProperty('onDanger', onDanger))
      ..add(ColorProperty('dangerSubtle', dangerSubtle))
      ..add(ColorProperty('overlay', overlay))
      ..add(ColorProperty('buttonTop', buttonTop))
      ..add(ColorProperty('buttonBottom', buttonBottom))
      ..add(ColorProperty('buttonSheen', buttonSheen))
      ..add(ColorProperty('onButton', onButton))
      ..add(ColorProperty('ringInner', ringInner))
      ..add(ColorProperty('ringOuter', ringOuter))
      ..add(ColorProperty('moneyIn', moneyIn))
      ..add(ColorProperty('moneyInTint', moneyInTint))
      ..add(ColorProperty('over', over))
      ..add(ColorProperty('overTint', overTint))
      ..add(ColorProperty('cold', cold))
      ..add(ColorProperty('coldTint', coldTint))
      ..add(ColorProperty('coldEdge', coldEdge))
      ..add(ColorProperty('unreadDot', unreadDot))
      ..add(ColorProperty('meterTrack', meterTrack))
      ..add(ColorProperty('paceTick', paceTick))
      ..add(ColorProperty('paceTickRing', paceTickRing))
      ..add(ColorProperty('toggleTrack', toggleTrack))
      ..add(ColorProperty('toggleKnob', toggleKnob));
  }
}

/// The theme's text styles: Material's `TextTheme` slots, by role and size, and
/// the look's own (a stat, an amount, a link, a tab, figures of one width, a
/// monogram, the wordmark).
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.textTheme]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedTextTheme with Diagnosticable {
  /// Creates a [FrostedTextTheme]; every value is required.
  const FrostedTextTheme({
    required this.displayLarge,
    required this.displayMedium,
    required this.displaySmall,
    required this.headlineLarge,
    required this.headlineMedium,
    required this.headlineSmall,
    required this.titleLarge,
    required this.titleMedium,
    required this.titleSmall,
    required this.bodyLarge,
    required this.bodyMedium,
    required this.bodySmall,
    required this.labelLarge,
    required this.labelMedium,
    required this.labelSmall,
    required this.overline,
    required this.stat,
    required this.amount,
    required this.amountSmall,
    required this.link,
    required this.tab,
    required this.mono,
    required this.monoSmall,
    required this.monogram,
    required this.wordmark,
  });

  /// The hero money at desktop width (500 96 on an 83 line): a page's one
  /// figure.
  final TextStyle displayLarge;

  /// The hero money on a phone (500 64/55): a net worth, a month's spend.
  final TextStyle displayMedium;

  /// A figure in a tile (500 40/34): a category's spend, the amount being
  /// typed.
  final TextStyle displaySmall;

  /// A smaller figure (500 28/24): a rent band's, a transaction's, a goal's
  /// saved.
  final TextStyle headlineLarge;

  /// The desktop page title and a lead's words (500 28/31).
  final TextStyle headlineMedium;

  /// A phone page's title and a sheet's (600 20/22).
  final TextStyle headlineSmall;

  /// A tile's title (600 16/20).
  final TextStyle titleLarge;

  /// The working line (500 16/20): a row's title, an option, a setting, a
  /// fact's value.
  final TextStyle titleMedium;

  /// A small title in the display face (600 14/14): a band's figure, the
  /// month switch, a frozen card's word.
  final TextStyle titleSmall;

  /// Running copy (400 16/22).
  final TextStyle bodyLarge;

  /// A quiet line in the secondary ink (400 14/19): a row's second line, a
  /// fact's label, "of $2,700".
  final TextStyle bodyMedium;

  /// A note in the caption ink (400 12/17): a field's help, a setting's
  /// second line.
  final TextStyle bodySmall;

  /// A button's word (600 14/14).
  final TextStyle labelLarge;

  /// A cap in the caption ink (500 12/16): a tile's eyebrow, a field's
  /// label.
  final TextStyle labelMedium;

  /// A chip's, a tab's and a legend's word (500 12/12).
  final TextStyle labelSmall;

  /// A tracked cap (500 12/16, tracked 0.04em) in the caption ink: a frozen
  /// card's word, a card's kind.
  final TextStyle overline;

  /// A stat (500 20/22, tabular): a pane's amount, a percent, a tile's
  /// summary figure.
  final TextStyle stat;

  /// An amount in a row (500 16/20, display face, tabular).
  final TextStyle amount;

  /// A smaller amount (500 14/16, display face, tabular): a part's, a
  /// menu's.
  final TextStyle amountSmall;

  /// A link and a nav item's word (500 14/14) in the secondary ink.
  final TextStyle link;

  /// A tab's word under its glyph (500 12/12) in the caption ink.
  final TextStyle tab;

  /// Figures of one width, tracked (500 14, tabular): a card number.
  final TextStyle mono;

  /// Small tracked figures (500 12, tabular): a card's last four.
  final TextStyle monoSmall;

  /// A monogram's or an avatar's letters (600 14/14, display face).
  final TextStyle monogram;

  /// The app's wordmark in the sidebar (600 24/24).
  final TextStyle wordmark;

  /// Every style passed through [f]: a new typeface set in every slot.
  FrostedTextTheme _map(TextStyle Function(TextStyle style) f) =>
      FrostedTextTheme(
        displayLarge: f(displayLarge),
        displayMedium: f(displayMedium),
        displaySmall: f(displaySmall),
        headlineLarge: f(headlineLarge),
        headlineMedium: f(headlineMedium),
        headlineSmall: f(headlineSmall),
        titleLarge: f(titleLarge),
        titleMedium: f(titleMedium),
        titleSmall: f(titleSmall),
        bodyLarge: f(bodyLarge),
        bodyMedium: f(bodyMedium),
        bodySmall: f(bodySmall),
        labelLarge: f(labelLarge),
        labelMedium: f(labelMedium),
        labelSmall: f(labelSmall),
        overline: f(overline),
        stat: f(stat),
        amount: f(amount),
        amountSmall: f(amountSmall),
        link: f(link),
        tab: f(tab),
        mono: f(mono),
        monoSmall: f(monoSmall),
        monogram: f(monogram),
        wordmark: f(wordmark),
      );

  /// This FrostedTextTheme with the named values replaced.
  FrostedTextTheme copyWith({
    TextStyle? displayLarge,
    TextStyle? displayMedium,
    TextStyle? displaySmall,
    TextStyle? headlineLarge,
    TextStyle? headlineMedium,
    TextStyle? headlineSmall,
    TextStyle? titleLarge,
    TextStyle? titleMedium,
    TextStyle? titleSmall,
    TextStyle? bodyLarge,
    TextStyle? bodyMedium,
    TextStyle? bodySmall,
    TextStyle? labelLarge,
    TextStyle? labelMedium,
    TextStyle? labelSmall,
    TextStyle? overline,
    TextStyle? stat,
    TextStyle? amount,
    TextStyle? amountSmall,
    TextStyle? link,
    TextStyle? tab,
    TextStyle? mono,
    TextStyle? monoSmall,
    TextStyle? monogram,
    TextStyle? wordmark,
  }) => FrostedTextTheme(
    displayLarge: displayLarge ?? this.displayLarge,
    displayMedium: displayMedium ?? this.displayMedium,
    displaySmall: displaySmall ?? this.displaySmall,
    headlineLarge: headlineLarge ?? this.headlineLarge,
    headlineMedium: headlineMedium ?? this.headlineMedium,
    headlineSmall: headlineSmall ?? this.headlineSmall,
    titleLarge: titleLarge ?? this.titleLarge,
    titleMedium: titleMedium ?? this.titleMedium,
    titleSmall: titleSmall ?? this.titleSmall,
    bodyLarge: bodyLarge ?? this.bodyLarge,
    bodyMedium: bodyMedium ?? this.bodyMedium,
    bodySmall: bodySmall ?? this.bodySmall,
    labelLarge: labelLarge ?? this.labelLarge,
    labelMedium: labelMedium ?? this.labelMedium,
    labelSmall: labelSmall ?? this.labelSmall,
    overline: overline ?? this.overline,
    stat: stat ?? this.stat,
    amount: amount ?? this.amount,
    amountSmall: amountSmall ?? this.amountSmall,
    link: link ?? this.link,
    tab: tab ?? this.tab,
    mono: mono ?? this.mono,
    monoSmall: monoSmall ?? this.monoSmall,
    monogram: monogram ?? this.monogram,
    wordmark: wordmark ?? this.wordmark,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedTextTheme lerp(
    FrostedTextTheme a,
    FrostedTextTheme b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedTextTheme(
      displayLarge: TextStyle.lerp(a.displayLarge, b.displayLarge, t)!,
      displayMedium: TextStyle.lerp(a.displayMedium, b.displayMedium, t)!,
      displaySmall: TextStyle.lerp(a.displaySmall, b.displaySmall, t)!,
      headlineLarge: TextStyle.lerp(a.headlineLarge, b.headlineLarge, t)!,
      headlineMedium: TextStyle.lerp(a.headlineMedium, b.headlineMedium, t)!,
      headlineSmall: TextStyle.lerp(a.headlineSmall, b.headlineSmall, t)!,
      titleLarge: TextStyle.lerp(a.titleLarge, b.titleLarge, t)!,
      titleMedium: TextStyle.lerp(a.titleMedium, b.titleMedium, t)!,
      titleSmall: TextStyle.lerp(a.titleSmall, b.titleSmall, t)!,
      bodyLarge: TextStyle.lerp(a.bodyLarge, b.bodyLarge, t)!,
      bodyMedium: TextStyle.lerp(a.bodyMedium, b.bodyMedium, t)!,
      bodySmall: TextStyle.lerp(a.bodySmall, b.bodySmall, t)!,
      labelLarge: TextStyle.lerp(a.labelLarge, b.labelLarge, t)!,
      labelMedium: TextStyle.lerp(a.labelMedium, b.labelMedium, t)!,
      labelSmall: TextStyle.lerp(a.labelSmall, b.labelSmall, t)!,
      overline: TextStyle.lerp(a.overline, b.overline, t)!,
      stat: TextStyle.lerp(a.stat, b.stat, t)!,
      amount: TextStyle.lerp(a.amount, b.amount, t)!,
      amountSmall: TextStyle.lerp(a.amountSmall, b.amountSmall, t)!,
      link: TextStyle.lerp(a.link, b.link, t)!,
      tab: TextStyle.lerp(a.tab, b.tab, t)!,
      mono: TextStyle.lerp(a.mono, b.mono, t)!,
      monoSmall: TextStyle.lerp(a.monoSmall, b.monoSmall, t)!,
      monogram: TextStyle.lerp(a.monogram, b.monogram, t)!,
      wordmark: TextStyle.lerp(a.wordmark, b.wordmark, t)!,
    );
  }

  List<Object?> get _values => [
    displayLarge,
    displayMedium,
    displaySmall,
    headlineLarge,
    headlineMedium,
    headlineSmall,
    titleLarge,
    titleMedium,
    titleSmall,
    bodyLarge,
    bodyMedium,
    bodySmall,
    labelLarge,
    labelMedium,
    labelSmall,
    overline,
    stat,
    amount,
    amountSmall,
    link,
    tab,
    mono,
    monoSmall,
    monogram,
    wordmark,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedTextTheme && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<TextStyle>('displayLarge', displayLarge))
      ..add(DiagnosticsProperty<TextStyle>('displayMedium', displayMedium))
      ..add(DiagnosticsProperty<TextStyle>('displaySmall', displaySmall))
      ..add(DiagnosticsProperty<TextStyle>('headlineLarge', headlineLarge))
      ..add(DiagnosticsProperty<TextStyle>('headlineMedium', headlineMedium))
      ..add(DiagnosticsProperty<TextStyle>('headlineSmall', headlineSmall))
      ..add(DiagnosticsProperty<TextStyle>('titleLarge', titleLarge))
      ..add(DiagnosticsProperty<TextStyle>('titleMedium', titleMedium))
      ..add(DiagnosticsProperty<TextStyle>('titleSmall', titleSmall))
      ..add(DiagnosticsProperty<TextStyle>('bodyLarge', bodyLarge))
      ..add(DiagnosticsProperty<TextStyle>('bodyMedium', bodyMedium))
      ..add(DiagnosticsProperty<TextStyle>('bodySmall', bodySmall))
      ..add(DiagnosticsProperty<TextStyle>('labelLarge', labelLarge))
      ..add(DiagnosticsProperty<TextStyle>('labelMedium', labelMedium))
      ..add(DiagnosticsProperty<TextStyle>('labelSmall', labelSmall))
      ..add(DiagnosticsProperty<TextStyle>('overline', overline))
      ..add(DiagnosticsProperty<TextStyle>('stat', stat))
      ..add(DiagnosticsProperty<TextStyle>('amount', amount))
      ..add(DiagnosticsProperty<TextStyle>('amountSmall', amountSmall))
      ..add(DiagnosticsProperty<TextStyle>('link', link))
      ..add(DiagnosticsProperty<TextStyle>('tab', tab))
      ..add(DiagnosticsProperty<TextStyle>('mono', mono))
      ..add(DiagnosticsProperty<TextStyle>('monoSmall', monoSmall))
      ..add(DiagnosticsProperty<TextStyle>('monogram', monogram))
      ..add(DiagnosticsProperty<TextStyle>('wordmark', wordmark));
  }
}

/// The shadows the theme's faces cast.
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.shadows]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedShadows with Diagnosticable {
  /// Creates a [FrostedShadows]; every value is required.
  const FrostedShadows({
    required this.tile,
    required this.bar,
    required this.sheet,
    required this.dialog,
    required this.menu,
    required this.toast,
    required this.button,
    required this.raised,
    required this.pearl,
    required this.ticket,
    required this.toggleKnob,
  });

  /// The shadow a tile casts (`--lift`).
  final List<BoxShadow> tile;

  /// The shadow the tab bar's slab casts.
  final List<BoxShadow> bar;

  /// The shadow a phone sheet casts up the page.
  final List<BoxShadow> sheet;

  /// The shadow a desktop dialog stands in.
  final List<BoxShadow> dialog;

  /// The shadow a menu stands in.
  final List<BoxShadow> menu;

  /// The shadow the toast's slab casts.
  final List<BoxShadow> toast;

  /// The shadow under the act's pill (`--ink-lift`).
  final List<BoxShadow> button;

  /// The shadow under a raised white face: a chosen segment, a swap button.
  final List<BoxShadow> raised;

  /// The shadow the pearl credit card casts.
  final List<BoxShadow> pearl;

  /// The shadow a ticket casts on the rent band.
  final List<BoxShadow> ticket;

  /// The shadow under a toggle's knob.
  final List<BoxShadow> toggleKnob;

  /// This FrostedShadows with the named values replaced.
  FrostedShadows copyWith({
    List<BoxShadow>? tile,
    List<BoxShadow>? bar,
    List<BoxShadow>? sheet,
    List<BoxShadow>? dialog,
    List<BoxShadow>? menu,
    List<BoxShadow>? toast,
    List<BoxShadow>? button,
    List<BoxShadow>? raised,
    List<BoxShadow>? pearl,
    List<BoxShadow>? ticket,
    List<BoxShadow>? toggleKnob,
  }) => FrostedShadows(
    tile: tile ?? this.tile,
    bar: bar ?? this.bar,
    sheet: sheet ?? this.sheet,
    dialog: dialog ?? this.dialog,
    menu: menu ?? this.menu,
    toast: toast ?? this.toast,
    button: button ?? this.button,
    raised: raised ?? this.raised,
    pearl: pearl ?? this.pearl,
    ticket: ticket ?? this.ticket,
    toggleKnob: toggleKnob ?? this.toggleKnob,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedShadows lerp(FrostedShadows a, FrostedShadows b, double t) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedShadows(
      tile: BoxShadow.lerpList(a.tile, b.tile, t)!,
      bar: BoxShadow.lerpList(a.bar, b.bar, t)!,
      sheet: BoxShadow.lerpList(a.sheet, b.sheet, t)!,
      dialog: BoxShadow.lerpList(a.dialog, b.dialog, t)!,
      menu: BoxShadow.lerpList(a.menu, b.menu, t)!,
      toast: BoxShadow.lerpList(a.toast, b.toast, t)!,
      button: BoxShadow.lerpList(a.button, b.button, t)!,
      raised: BoxShadow.lerpList(a.raised, b.raised, t)!,
      pearl: BoxShadow.lerpList(a.pearl, b.pearl, t)!,
      ticket: BoxShadow.lerpList(a.ticket, b.ticket, t)!,
      toggleKnob: BoxShadow.lerpList(a.toggleKnob, b.toggleKnob, t)!,
    );
  }

  List<Object?> get _values => [
    tile,
    bar,
    sheet,
    dialog,
    menu,
    toast,
    button,
    raised,
    pearl,
    ticket,
    toggleKnob,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedShadows && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<BoxShadow>('tile', tile))
      ..add(IterableProperty<BoxShadow>('bar', bar))
      ..add(IterableProperty<BoxShadow>('sheet', sheet))
      ..add(IterableProperty<BoxShadow>('dialog', dialog))
      ..add(IterableProperty<BoxShadow>('menu', menu))
      ..add(IterableProperty<BoxShadow>('toast', toast))
      ..add(IterableProperty<BoxShadow>('button', button))
      ..add(IterableProperty<BoxShadow>('raised', raised))
      ..add(IterableProperty<BoxShadow>('pearl', pearl))
      ..add(IterableProperty<BoxShadow>('ticket', ticket))
      ..add(IterableProperty<BoxShadow>('toggleKnob', toggleKnob));
  }
}

/// The glass's colours: a tile's frosted fill, its edge and rim, a field's
/// well, the bars, the sidebar, a sheet, a menu and the prism bar's tube.
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.glass]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedGlassColors with Diagnosticable {
  /// Creates a [FrostedGlassColors]; every value is required.
  const FrostedGlassColors({
    required this.fill,
    required this.fillHigh,
    required this.edge,
    required this.rim,
    required this.spectrumStops,
    required this.wash,
    required this.well,
    required this.wellEdge,
    required this.plane,
    required this.topFrost,
    required this.bar,
    required this.barFade,
    required this.sidebar,
    required this.sidebarEdge,
    required this.navCurrent,
    required this.sheetTop,
    required this.sheetBottom,
    required this.sheetEdge,
    required this.grabber,
    required this.menu,
    required this.menuEdge,
    required this.track,
    required this.trackEdge,
  });

  /// A tile's frosted glass (`--glass`): white at 62%, the canvas blurred
  /// behind it.
  final Color fill;

  /// The high glass (`--glass-hi`): a round button, the search well, a glass
  /// button.
  final Color fillHigh;

  /// A tile's hairline edge (`--edge`).
  final Color edge;

  /// The white rim along a tile's top inside edge (`--rim`).
  final Color rim;

  /// The spectrum's rim along a hero's top edge: five pastel stops, fading
  /// in from nothing at 4% and out to nothing at 96%.
  final List<Color> spectrumStops;

  /// The quiet wash a chip, a date block, a segmented control's track and a
  /// checked option stand on (`--wash`).
  final Color wash;

  /// A field's well: white at 82%.
  final Color well;

  /// A field well's inset edge.
  final Color wellEdge;

  /// A plain white face: a segmented control's chosen segment, the month
  /// switch's arrow, a swap button, a nudge's mark.
  final Color plane;

  /// The frost behind a phone's top bar, fading down to nothing.
  final Color topFrost;

  /// The tab bar's slab (white at 74%, the page blurred behind it).
  final Color bar;

  /// The canvas the page fades into under the tab bar.
  final Color barFade;

  /// The sidebar's glass and its right edge.
  final Color sidebar;

  /// See [sidebar].
  final Color sidebarEdge;

  /// The current nav link's face.
  final Color navCurrent;

  /// A sheet's face at its top and at its foot, and its edge.
  final Color sheetTop;

  /// See [sheetTop].
  final Color sheetBottom;

  /// See [sheetTop].
  final Color sheetEdge;

  /// The grab handle at a phone sheet's top.
  final Color grabber;

  /// A menu's face and edge.
  final Color menu;

  /// See [menu].
  final Color menuEdge;

  /// The prism bar's glass tube: its track and the hairline round it.
  final Color track;

  /// See [track].
  final Color trackEdge;

  /// The spectrum's rim, left to right: nothing at 4%, the five stops at 18,
  /// 38, 56 and 76%, nothing at 96%.
  LinearGradient get spectrumRim => LinearGradient(
    colors: [
      spectrumStops[0].withValues(alpha: 0),
      spectrumStops[0],
      spectrumStops[1],
      spectrumStops[2],
      spectrumStops[3],
      spectrumStops[4].withValues(alpha: 0),
    ],
    stops: const [0.04, 0.18, 0.38, 0.56, 0.76, 0.96],
  );

  /// A sheet's face, top to foot.
  LinearGradient get sheetFace => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [sheetTop, sheetBottom],
  );

  /// This FrostedGlassColors with the named values replaced.
  FrostedGlassColors copyWith({
    Color? fill,
    Color? fillHigh,
    Color? edge,
    Color? rim,
    List<Color>? spectrumStops,
    Color? wash,
    Color? well,
    Color? wellEdge,
    Color? plane,
    Color? topFrost,
    Color? bar,
    Color? barFade,
    Color? sidebar,
    Color? sidebarEdge,
    Color? navCurrent,
    Color? sheetTop,
    Color? sheetBottom,
    Color? sheetEdge,
    Color? grabber,
    Color? menu,
    Color? menuEdge,
    Color? track,
    Color? trackEdge,
  }) => FrostedGlassColors(
    fill: fill ?? this.fill,
    fillHigh: fillHigh ?? this.fillHigh,
    edge: edge ?? this.edge,
    rim: rim ?? this.rim,
    spectrumStops: spectrumStops ?? this.spectrumStops,
    wash: wash ?? this.wash,
    well: well ?? this.well,
    wellEdge: wellEdge ?? this.wellEdge,
    plane: plane ?? this.plane,
    topFrost: topFrost ?? this.topFrost,
    bar: bar ?? this.bar,
    barFade: barFade ?? this.barFade,
    sidebar: sidebar ?? this.sidebar,
    sidebarEdge: sidebarEdge ?? this.sidebarEdge,
    navCurrent: navCurrent ?? this.navCurrent,
    sheetTop: sheetTop ?? this.sheetTop,
    sheetBottom: sheetBottom ?? this.sheetBottom,
    sheetEdge: sheetEdge ?? this.sheetEdge,
    grabber: grabber ?? this.grabber,
    menu: menu ?? this.menu,
    menuEdge: menuEdge ?? this.menuEdge,
    track: track ?? this.track,
    trackEdge: trackEdge ?? this.trackEdge,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedGlassColors lerp(
    FrostedGlassColors a,
    FrostedGlassColors b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedGlassColors(
      fill: Color.lerp(a.fill, b.fill, t)!,
      fillHigh: Color.lerp(a.fillHigh, b.fillHigh, t)!,
      edge: Color.lerp(a.edge, b.edge, t)!,
      rim: Color.lerp(a.rim, b.rim, t)!,
      spectrumStops: _lerpColors(a.spectrumStops, b.spectrumStops, t),
      wash: Color.lerp(a.wash, b.wash, t)!,
      well: Color.lerp(a.well, b.well, t)!,
      wellEdge: Color.lerp(a.wellEdge, b.wellEdge, t)!,
      plane: Color.lerp(a.plane, b.plane, t)!,
      topFrost: Color.lerp(a.topFrost, b.topFrost, t)!,
      bar: Color.lerp(a.bar, b.bar, t)!,
      barFade: Color.lerp(a.barFade, b.barFade, t)!,
      sidebar: Color.lerp(a.sidebar, b.sidebar, t)!,
      sidebarEdge: Color.lerp(a.sidebarEdge, b.sidebarEdge, t)!,
      navCurrent: Color.lerp(a.navCurrent, b.navCurrent, t)!,
      sheetTop: Color.lerp(a.sheetTop, b.sheetTop, t)!,
      sheetBottom: Color.lerp(a.sheetBottom, b.sheetBottom, t)!,
      sheetEdge: Color.lerp(a.sheetEdge, b.sheetEdge, t)!,
      grabber: Color.lerp(a.grabber, b.grabber, t)!,
      menu: Color.lerp(a.menu, b.menu, t)!,
      menuEdge: Color.lerp(a.menuEdge, b.menuEdge, t)!,
      track: Color.lerp(a.track, b.track, t)!,
      trackEdge: Color.lerp(a.trackEdge, b.trackEdge, t)!,
    );
  }

  List<Object?> get _values => [
    fill,
    fillHigh,
    edge,
    rim,
    spectrumStops,
    wash,
    well,
    wellEdge,
    plane,
    topFrost,
    bar,
    barFade,
    sidebar,
    sidebarEdge,
    navCurrent,
    sheetTop,
    sheetBottom,
    sheetEdge,
    grabber,
    menu,
    menuEdge,
    track,
    trackEdge,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedGlassColors && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('fill', fill))
      ..add(ColorProperty('fillHigh', fillHigh))
      ..add(ColorProperty('edge', edge))
      ..add(ColorProperty('rim', rim))
      ..add(IterableProperty<Color>('spectrumStops', spectrumStops))
      ..add(ColorProperty('wash', wash))
      ..add(ColorProperty('well', well))
      ..add(ColorProperty('wellEdge', wellEdge))
      ..add(ColorProperty('plane', plane))
      ..add(ColorProperty('topFrost', topFrost))
      ..add(ColorProperty('bar', bar))
      ..add(ColorProperty('barFade', barFade))
      ..add(ColorProperty('sidebar', sidebar))
      ..add(ColorProperty('sidebarEdge', sidebarEdge))
      ..add(ColorProperty('navCurrent', navCurrent))
      ..add(ColorProperty('sheetTop', sheetTop))
      ..add(ColorProperty('sheetBottom', sheetBottom))
      ..add(ColorProperty('sheetEdge', sheetEdge))
      ..add(ColorProperty('grabber', grabber))
      ..add(ColorProperty('menu', menu))
      ..add(ColorProperty('menuEdge', menuEdge))
      ..add(ColorProperty('track', track))
      ..add(ColorProperty('trackEdge', trackEdge));
  }
}

/// The pearl's colours: the pale credit card, its words and its usage bar, and
/// an avatar's pearl.
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.pearl]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedPearlColors with Diagnosticable {
  /// Creates a [FrostedPearlColors]; every value is required.
  const FrostedPearlColors({
    required this.from,
    required this.to,
    required this.blush,
    required this.rim,
    required this.glow,
    required this.text,
    required this.textSecondary,
    required this.usageFrom,
    required this.usageTo,
    required this.usageTrack,
    required this.avatar,
  });

  /// The pearl credit card: its cool base from [from] to [to],
  /// the blush inside its rings, its spectrum rim and the glow it floats on;
  /// the ink and the quiet ink of the words on it (the card is a pale object
  /// in both appearances).
  final Color from;

  /// See [from].
  final Color to;

  /// See [from].
  final Color blush;

  /// See [from].
  final List<Color> rim;

  /// See [from].
  final List<Color> glow;

  /// See [from].
  final Color text;

  /// See [from].
  final Color textSecondary;

  /// The card's utilisation bar, left to right, and its track.
  final Color usageFrom;

  /// See [usageFrom].
  final Color usageTo;

  /// See [usageFrom].
  final Color usageTrack;

  /// An avatar's pearl: three stops, top left to bottom right (0, 55%,
  /// 100%).
  final List<Color> avatar;

  /// The pearl's base, top left to bottom right.
  LinearGradient get base => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [from, to],
  );

  /// The pearl's spectrum rim, top left to bottom right.
  LinearGradient get rimGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: rim,
    stops: const [0, 0.35, 0.6, 0.82, 1],
  );

  /// An avatar's pearl.
  LinearGradient get avatarGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: avatar,
    stops: const [0, 0.55, 1],
  );

  /// The card's utilisation bar.
  LinearGradient get usage => LinearGradient(colors: [usageFrom, usageTo]);

  /// This FrostedPearlColors with the named values replaced.
  FrostedPearlColors copyWith({
    Color? from,
    Color? to,
    Color? blush,
    List<Color>? rim,
    List<Color>? glow,
    Color? text,
    Color? textSecondary,
    Color? usageFrom,
    Color? usageTo,
    Color? usageTrack,
    List<Color>? avatar,
  }) => FrostedPearlColors(
    from: from ?? this.from,
    to: to ?? this.to,
    blush: blush ?? this.blush,
    rim: rim ?? this.rim,
    glow: glow ?? this.glow,
    text: text ?? this.text,
    textSecondary: textSecondary ?? this.textSecondary,
    usageFrom: usageFrom ?? this.usageFrom,
    usageTo: usageTo ?? this.usageTo,
    usageTrack: usageTrack ?? this.usageTrack,
    avatar: avatar ?? this.avatar,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedPearlColors lerp(
    FrostedPearlColors a,
    FrostedPearlColors b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedPearlColors(
      from: Color.lerp(a.from, b.from, t)!,
      to: Color.lerp(a.to, b.to, t)!,
      blush: Color.lerp(a.blush, b.blush, t)!,
      rim: _lerpColors(a.rim, b.rim, t),
      glow: _lerpColors(a.glow, b.glow, t),
      text: Color.lerp(a.text, b.text, t)!,
      textSecondary: Color.lerp(a.textSecondary, b.textSecondary, t)!,
      usageFrom: Color.lerp(a.usageFrom, b.usageFrom, t)!,
      usageTo: Color.lerp(a.usageTo, b.usageTo, t)!,
      usageTrack: Color.lerp(a.usageTrack, b.usageTrack, t)!,
      avatar: _lerpColors(a.avatar, b.avatar, t),
    );
  }

  List<Object?> get _values => [
    from,
    to,
    blush,
    rim,
    glow,
    text,
    textSecondary,
    usageFrom,
    usageTo,
    usageTrack,
    avatar,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedPearlColors && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('from', from))
      ..add(ColorProperty('to', to))
      ..add(ColorProperty('blush', blush))
      ..add(IterableProperty<Color>('rim', rim))
      ..add(IterableProperty<Color>('glow', glow))
      ..add(ColorProperty('text', text))
      ..add(ColorProperty('textSecondary', textSecondary))
      ..add(ColorProperty('usageFrom', usageFrom))
      ..add(ColorProperty('usageTo', usageTo))
      ..add(ColorProperty('usageTrack', usageTrack))
      ..add(IterableProperty<Color>('avatar', avatar));
  }
}

/// The toast's colours: its slab, the words and the light on it, its mark and
/// its action.
///
/// One of [FrostedThemeData]'s groups ([FrostedThemeData.toast]); every
/// preset fills it; [FrostedThemeData.copyWith] takes a new one, and
/// [copyWith] changes a few of its values.
@immutable
class FrostedToastColors with Diagnosticable {
  /// Creates a [FrostedToastColors]; every value is required.
  const FrostedToastColors({
    required this.top,
    required this.bottom,
    required this.text,
    required this.sheen,
    required this.mark,
    required this.onMark,
    required this.action,
  });

  /// The toast's slab at its top and foot, the ink on it, the light along
  /// its top inside edge, its mark's disc and ink, and its action's face.
  final Color top;

  /// See [top].
  final Color bottom;

  /// See [top].
  final Color text;

  /// See [top].
  final Color sheen;

  /// See [top].
  final Color mark;

  /// See [top].
  final Color onMark;

  /// See [top].
  final Color action;

  /// The toast's slab, top to foot.
  LinearGradient get slab => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [top, bottom],
  );

  /// This FrostedToastColors with the named values replaced.
  FrostedToastColors copyWith({
    Color? top,
    Color? bottom,
    Color? text,
    Color? sheen,
    Color? mark,
    Color? onMark,
    Color? action,
  }) => FrostedToastColors(
    top: top ?? this.top,
    bottom: bottom ?? this.bottom,
    text: text ?? this.text,
    sheen: sheen ?? this.sheen,
    mark: mark ?? this.mark,
    onMark: onMark ?? this.onMark,
    action: action ?? this.action,
  );

  /// Between [a] and [b]: every value eases.
  static FrostedToastColors lerp(
    FrostedToastColors a,
    FrostedToastColors b,
    double t,
  ) {
    if (identical(a, b) || t == 0) return a;
    if (t == 1) return b;
    return FrostedToastColors(
      top: Color.lerp(a.top, b.top, t)!,
      bottom: Color.lerp(a.bottom, b.bottom, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      sheen: Color.lerp(a.sheen, b.sheen, t)!,
      mark: Color.lerp(a.mark, b.mark, t)!,
      onMark: Color.lerp(a.onMark, b.onMark, t)!,
      action: Color.lerp(a.action, b.action, t)!,
    );
  }

  List<Object?> get _values => [top, bottom, text, sheen, mark, onMark, action];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrostedToastColors && _deepEquals(other._values, _values);

  @override
  int get hashCode => Object.hashAll(_values.map(_deepHash));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('top', top))
      ..add(ColorProperty('bottom', bottom))
      ..add(ColorProperty('text', text))
      ..add(ColorProperty('sheen', sheen))
      ..add(ColorProperty('mark', mark))
      ..add(ColorProperty('onMark', onMark))
      ..add(ColorProperty('action', action));
  }
}

/// Frosted's theme in the tree, as Material's `Theme` is: an
/// [InheritedTheme] that carries [data] to every Frosted widget under it
/// (`FrostedTheme.of(context)`, or `context.frostedTheme`), and installs what
/// the platform's own widgets under it read: the body type and the glyph
/// ink, Frosted's scroll bar, a quiet Material theme for a text field's
/// caret and selection (no ink, no splash, no hover wash), and Material's
/// words where the app has none (a `CupertinoApp`'s or a `WidgetsApp`'s
/// text field asks for them). Put it in the app's builder, above the
/// navigator, so every route reads it; a nested one re-themes its subtree.
///
/// [darkData] is the dark theme of the same family, which a media ground (a
/// full-bleed photograph or video) draws its chrome in; null is
/// [FrostedThemeData.darkTwin].
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => FrostedTheme(
///     data: FrostedThemeData.opal(),
///     child: child!,
///   ),
/// )
/// ```
class FrostedTheme extends StatelessWidget {
  /// Scopes [data] over [child].
  const FrostedTheme({
    super.key,
    required this.data,
    this.darkData,
    required this.child,
  });

  /// The theme in force under this widget.
  final FrostedThemeData data;

  /// The dark theme of the same family; null is [FrostedThemeData.darkTwin].
  final FrostedThemeData? darkData;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]. Throws when there is none:
  /// `context.frostedTheme` is the same.
  static FrostedThemeData of(BuildContext context) {
    final found = maybeOf(context);
    if (found == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No FrostedTheme in scope.'),
        ErrorHint(
          'Put a FrostedTheme (or a FrostedHost) in the app\'s builder, '
          'above the navigator, or above this widget.',
        ),
      ]);
    }
    return found;
  }

  /// The theme in scope at [context], or null.
  static FrostedThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_FrostedScope>()?.theme.data;

  /// The dark theme of the family in scope at [context].
  static FrostedThemeData darkOf(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<_FrostedScope>()
        ?.theme;
    if (scope == null) return of(context);
    return scope.darkData ?? scope.data.darkTwin;
  }

  @override
  Widget build(BuildContext context) => _FrostedScope(
    theme: this,
    child: _FrostedInstall(data: data, child: child),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<FrostedThemeData>('data', data))
      ..add(DiagnosticsProperty<FrostedThemeData>('dark', darkData));
  }
}

/// The [FrostedTheme] in the tree, found by its lookups and carried over to
/// a captured subtree (a route, an overlay) by [InheritedTheme.capture].
class _FrostedScope extends InheritedTheme {
  const _FrostedScope({required this.theme, required super.child});

  final FrostedTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      FrostedTheme(data: theme.data, darkData: theme.darkData, child: child);

  @override
  bool updateShouldNotify(_FrostedScope oldWidget) =>
      theme.data != oldWidget.theme.data ||
      theme.darkData != oldWidget.theme.darkData;
}

class _FrostedInstall extends StatelessWidget {
  const _FrostedInstall({required this.data, required this.child});

  final FrostedThemeData data;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    var under = child;
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      // A Localizations sets its locale's direction (left to right for
      // English) under it: the page keeps the direction it stands in.
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
      data: _materialUnder(data, PreviewFrame.targetPlatformOf(context)),
      child: ScrollConfiguration(
        behavior: FrostedScrollBehavior(
          thumb: data.colorScheme.textTertiary.withValues(alpha: .45),
          parent: ScrollConfiguration.of(context),
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: data.colorScheme.textPrimary, size: 24),
          child: DefaultTextStyle.merge(
            style: data.textTheme.titleMedium,
            child: under,
          ),
        ),
      ),
    );
  }
}

/// The Material theme per Frosted theme and platform, built once each: the
/// presets are one instance per id and appearance, so this stays small.
final Map<TargetPlatform, Expando<ThemeData>> _materialThemes = {
  for (final p in TargetPlatform.values) p: Expando<ThemeData>('frosted'),
};

/// What Flutter's own widgets under Frosted read (a text field's caret,
/// selection and handles, a route's ground), in Frosted's colours, with no
/// ink, splash, highlight or hover wash. Not in the package's barrel: an app
/// never meets a Material type in Frosted's API.
ThemeData _materialUnder(FrostedThemeData t, TargetPlatform platform) =>
    _materialThemes[platform]![t] ??= ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      platform: platform,
      // Frosted's density is its own knob (FrostedThemeData.density); left
      // to Material, a desktop platform (macOS, Windows, Linux, and a web
      // build opened on one) is compact, which takes 8 px off a decorated
      // field's height and 4 off its baseline, and shrink-wraps tap
      // targets (pinned padded below).
      visualDensity: VisualDensity.standard,
      fontFamily: t.textTheme.titleMedium.fontFamily,
      scaffoldBackgroundColor: t.colorScheme.background,
      canvasColor: t.colorScheme.background,
      splashFactory: NoSplash.splashFactory,
      splashColor: const Color(0x00000000),
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.colorScheme.accent,
        onPrimary: t.colorScheme.onAccent,
        secondary: t.colorScheme.surfaceInverse,
        onSecondary: t.colorScheme.textInverse,
        error: t.colorScheme.danger,
        onError: t.colorScheme.onDanger,
        surface: t.colorScheme.background,
        onSurface: t.colorScheme.textPrimary,
        outline: t.colorScheme.borderStrong,
        outlineVariant: t.colorScheme.border,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.colorScheme.accent,
        selectionColor: t.colorScheme.accent.withValues(alpha: 0.3),
        selectionHandleColor: t.colorScheme.accent,
      ),
      dividerTheme: DividerThemeData(
        color: t.colorScheme.border,
        thickness: FrostedStrokes.hairline,
      ),
    );

/// Animates to a new [data] over [duration] (200 ms, as Material's
/// `AnimatedTheme`): every colour, shadow, type slot and knob eases through
/// [FrostedThemeData.lerp].
///
/// ```dart
/// AnimatedFrostedTheme(
///   data: FrostedThemeData.opal(dark ? Brightness.dark : Brightness.light),
///   child: page,
/// )
/// ```
class AnimatedFrostedTheme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedFrostedTheme({
    super.key,
    required this.data,
    this.darkData,
    required this.child,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final FrostedThemeData data;

  /// The dark theme of the same family, as [FrostedTheme.dark].
  final FrostedThemeData? darkData;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedFrostedTheme> createState() =>
      _AnimatedFrostedThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<FrostedThemeData>('data', data));
  }
}

class _AnimatedFrostedThemeState
    extends AnimatedWidgetBaseState<AnimatedFrostedTheme> {
  FrostedThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => FrostedThemeDataTween(begin: value as FrostedThemeData),
    ) as FrostedThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) => FrostedTheme(
    data: _data!.evaluate(animation),
    darkData: widget.darkData,
    child: widget.child,
  );
}

/// A tween between two Frosted themes, through [FrostedThemeData.lerp].
class FrostedThemeDataTween extends Tween<FrostedThemeData> {
  /// From [begin] to [end].
  FrostedThemeDataTween({super.begin, super.end});

  @override
  FrostedThemeData lerp(double t) => begin!.lerp(end, t);
}

/// How a scroll looks under Frosted: a thin bar of quiet ink on a desktop,
/// the stretch on Android, nothing of Material's; everything else (the
/// physics, the drag devices, the platform) the [parent]'s, the behaviour
/// in force above the theme. [FrostedTheme] installs it.
class FrostedScrollBehavior extends ScrollBehavior {
  /// A behaviour whose bar is drawn in [thumb].
  const FrostedScrollBehavior({
    required this.thumb,
    this.parent = const ScrollBehavior(),
  });

  /// The bar's colour.
  final Color thumb;

  /// The behaviour every other choice is delegated to.
  final ScrollBehavior parent;

  @override
  Set<PointerDeviceKind> get dragDevices => parent.dragDevices;

  @override
  Set<LogicalKeyboardKey> get pointerAxisModifiers =>
      parent.pointerAxisModifiers;

  @override
  TargetPlatform getPlatform(BuildContext context) =>
      parent.getPlatform(context);

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      parent.getScrollPhysics(context);

  @override
  GestureVelocityTrackerBuilder velocityTrackerBuilder(BuildContext context) =>
      parent.velocityTrackerBuilder(context);

  @override
  MultitouchDragStrategy getMultitouchDragStrategy(BuildContext context) =>
      parent.getMultitouchDragStrategy(context);

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
  bool shouldNotify(FrostedScrollBehavior oldDelegate) =>
      oldDelegate.thumb != thumb ||
      oldDelegate.parent.runtimeType != parent.runtimeType ||
      parent.shouldNotify(oldDelegate.parent);
}

/// The accessor every Frosted widget reads its tokens through.
extension FrostedThemeContext on BuildContext {
  /// The app's design tokens: `context.frostedTheme.glass`, ...
  FrostedThemeData get frostedTheme => FrostedTheme.of(this);
}

/// Scale-step adjustments that stay on the scale.
extension FrostedTextStyle on TextStyle {
  /// Recolour a scale step: `t.body.c(t.textSecondary)`.
  TextStyle c(Color color) => copyWith(color: color);

  /// The regular cut (400): `t.body.regular`.
  TextStyle get regular => _weighed(400);

  /// The medium cut (500).
  TextStyle get medium => _weighed(500);

  /// The strongest emphasis Frosted uses: the semibold cut (600).
  TextStyle get semibold => _weighed(600);

  /// Figures of one width, so amounts line up: `t.body.tabular`.
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// The same style in the display face (Bricolage Grotesque): a strong
  /// figure inside running copy.
  TextStyle get display => _faced(FrostedThemeData.face);

  /// The same style in the text face (DM Sans).
  TextStyle get text => _faced(FrostedThemeData.textFace);

  /// Set on a line [px] tall: `t.caption.line(20)`.
  TextStyle line(double px) => copyWith(height: px / fontSize!);

  /// Tracked [em] of its size: `t.textTheme.overline.tracked(0.1)`.
  TextStyle tracked(double em) => copyWith(letterSpacing: em * fontSize!);

  /// At [px], its optical size following: `t.monogram.at(20)`.
  TextStyle at(double px) => copyWith(
    fontSize: px,
    height: height == null ? null : height! * fontSize! / px,
    letterSpacing: letterSpacing == null
        ? null
        : letterSpacing! * px / fontSize!,
    fontVariations: _variations(fontVariations, size: px),
  );

  TextStyle _weighed(int weight) => copyWith(
    fontWeight: FontWeight(weight),
    fontVariations: _variations(fontVariations, weight: weight.toDouble()),
  );

  TextStyle _faced(String face) => copyWith(
    fontFamily: face,
    fontFamilyFallback: const [FrostedThemeData.textFace],
    fontVariations: _variations(fontVariations, size: fontSize, face: face),
  );

  /// [variations] with its `wght` and `opsz` axes rewritten.
  List<FontVariation>? _variations(
    List<FontVariation>? variations, {
    double? weight,
    double? size,
    String? face,
  }) {
    if (variations == null) return null;
    final display = (face ?? fontFamily) == FrostedThemeData.face;
    return [
      for (final v in variations)
        switch (v.axis) {
          'wght' when weight != null => FontVariation.weight(weight),
          'opsz' when size != null => FontVariation.opticalSize(
            display ? size.clamp(12.0, 96.0) : size.clamp(9.0, 40.0),
          ),
          _ => v,
        },
    ];
  }
}

/// The values the `prism` preset is written in: the source stylesheet's
/// custom properties as literals, each under its own name (`--ink-2` is
/// `_Source.ink2`), and the literal colours its rules set.
///
/// ## Role mapping
///
/// The stylesheet names its properties by what they are (`--canvas`,
/// `--glass`, `--ink-2`, `--in`, `--over`, `--warn`, `--line`, `--wash`) and
/// most of its other colours are literals in its rules, so each role takes
/// the value of the rule that plays it most often (driftwood-authoring §3):
///
/// - `background` = `--canvas`. `surface` is the glass tile (white 62%) as
///   it reads over the canvas, made opaque (`#FAFAFC`): the tile itself is
///   drawn from the glass roles, and `surface` is the stand-in where glass
///   cannot be drawn. JUDGMENT: the opaque stand-in rather than the
///   translucent face, so a component that needs a face (and the contrast
///   tests) reads a real colour. `surfaceAlt` is the wash over that
///   (`#F0F0F3`).
/// - `border` = `--line` (7%), the rule between rows (the source's 8% well
///   edge is the lit hairline now); `borderStrong` the grabber's 14%. The
///   glass's `edge` = `--edge` (5.5%), `wash` = `--wash` (4.5%). All stay
///   translucent, as the source sets them.
/// - `textPrimary` = `--ink`, `textSecondary` = `--ink-2`, `textTertiary` =
///   `--ink-3` (and the source's `--ink-q` for a figure's cents), every one
///   opaque as the source sets
///   it. JUDGMENT: the source's `--ink-2`, `--ink-3` and `--ink-q` read 3.9,
///   3.0 and 2.2:1 where a wash is strongest; the theme eases them toward
///   the page ink until they read 4.5:1 there, so the values below are the
///   source's and the theme's are a step deeper.
/// - `accent` = `accentText` = `surfaceInverse` = the ink: the source has no
///   accent colour; every act is the ink pill (`.btn--ink`, `.fchip.on`,
///   `.tgl:checked`, `.opt[aria-pressed]`, `.move-btn`). Its fill is
///   `--ink-fill` (`buttonTop` to `buttonBottom`), its lift `--ink-lift`.
/// `onAccent`
///   and `textInverse` are white.
/// - `success` = `moneyIn` = `--in`, `danger` = `over` = `--over`, `warning`
///   = `warn` = `--warn`, each with its `-t` tint as the wash. `cold` = the
///   frozen card's `--cold` with its tint and edge.
/// - `overlay` = the scrim, rgba(30, 28, 50, .3).
/// - The hues are the `.c-*` classes, each at its seven values.
/// - The washes of light are the three blobs (`.b1`, `.b2`, `.b3`); the rim
///   is the `.glass-tile` hairline gradient; the pearl is `.kcard`'s layers
///   and `.kc-glow`; the avatar is `.avatar`'s gradient; the charts' inks
///   are `charts.py`'s literals.
/// - The chrome faces are the rules that draw them: `.top::before`,
///   `.tabbar-in`, `.tabbar::before`, `.side`, `.nav.on`, `.sheet`,
///   `.sheet-grab`, `.menu`, `.toast`, `.toast-i`, `.toast-a`, the unread
///   dot, the prism track, the meter, the pace tick, `.tgl`; their shadows
///   are the rules' box-shadows as Flutter draws them, inset rims apart
///   (the components draw those).
///
/// Type: the slots are the source's own sizes, weights, lines and tracking;
/// the display face is `--font-d` (Bricolage Grotesque), the text face
/// `--font-t` (DM Sans). JUDGMENT: amounts in rows, stats and card numbers
/// are tabular, as the source sets `tnum` on `.amt`, `.num`, `.stat-v` and
/// `.cell-amt`; the hero money keeps proportional numerals, as `.money`
/// does.
///
/// Dark is DESIGNED: the source has no dark appearance, so its night is
/// written in `_Night` from the concept's principles (light through dark
/// glass), held by the tests to the bar light is held to (words 4.5:1 on the
/// canvas, the surface and the washes).
abstract final class _Source {
  static const Color canvas = Color(0xFFF3F3F7);
  static const Color surface = Color(0xFFFAFAFC);
  static const Color surfaceAlt = Color(0xFFF0F0F3);
  static const Color white = Color(0xFFFFFFFF);
  static const Color glass = Color(0x9EFFFFFF);
  static const Color glassHi = Color(0xC7FFFFFF);
  static const Color ink = Color(0xFF15151D);
  static const Color ink2 = Color(0xFF4E4F5A);
  static const Color ink3 = Color(0xFF575864);
  static const Color inkDeep = Color(0xFF15152D);
  static const Color line = Color(0x1215152D);
  static const Color wash = Color(0x0B15152D);

  /// The lit hairline round a pane of light glass (white at 85%), where the
  /// source's `--edge` drew a dark one.
  static const Color litEdge = Color(0xD9FFFFFF);
  static const Color borderStrong = Color(0x2415152D);
  static const Color rim = Color(0xE6FFFFFF);
  static const Color well = Color(0xD1FFFFFF);
  static const Color moneyIn = Color(0xFF257B51);
  static const Color moneyInTint = Color(0x2140A874);
  static const Color over = Color(0xFFBC484B);
  static const Color overTint = Color(0x1FE26260);
  static const Color warn = Color(0xFF8E5D1E);
  static const Color warnTint = Color(0x33ECAA50);
  static const Color cold = Color(0xFF2F5C8F);
  static const Color coldTint = Color(0x2978AAE6);
  static const Color coldEdge = Color(0x5778AAE6);
  static const Color inkTop = Color(0xFF2A2935);
  static const Color inkBottom = Color(0xFF15151D);
  static const Color inkSheen = Color(0x24FFFFFF);
  static const Color ringOuter = Color(0xB315151D);
  static const Color scrim = Color(0x4D1E1C32);
  static const Color topFrost = Color(0x80F3F3F7);
  static const Color barFill = Color(0xBDFFFFFF);
  static const Color sideFill = Color(0x80FFFFFF);
  static const Color navCurrent = Color(0xCCFFFFFF);
  static const Color sheetTop = Color(0xFFFFFFFF);
  static const Color sheetBottom = Color(0xFFF8F8FB);
  static const Color sheetEdge = Color(0x0D15152D);
  static const Color grabber = Color(0x2415152D);
  static const Color menuFill = Color(0xFFFDFDFE);
  static const Color menuEdge = Color(0x0F15152D);
  static const Color toastTop = Color(0xFF2A2935);
  static const Color toastBottom = Color(0xFF1B1A25);
  static const Color toastSheen = Color(0x1AFFFFFF);
  static const Color toastMarkFill = Color(0x336FCB98);
  static const Color toastMarkInk = Color(0xFF8FDDB0);
  static const Color toastAction = Color(0x1FFFFFFF);
  static const Color unreadDot = Color(0xFFE2707A);
  static const Color trackFill = Color(0xEBFFFFFF);
  static const Color trackEdge = Color(0x0A15152D);
  static const Color meterTrack = Color(0xB3FFFFFF);
  static const Color paceTick = Color(0xC715151D);
  static const Color paceRing = Color(0xEBFFFFFF);
  static const Color toggleTrack = Color(0x2115152D);
  static const Color liftShade = Color(0x422A2464);
  static const Color barShade = Color(0x5C2A2464);
  static const Color sheetShade = Color(0x662A2464);
  static const Color toastShade = Color(0xB315151D);
  static const Color actShade = Color(0xB315151D);
  static const Color raisedShade = Color(0x2E2A2464);
  static const Color pearlShade = Color(0x663C3082);
  static const Color ticketShade = Color(0x73342972);
  static const Color lightLilac = Color(0xFFC2BBF4);
  static const Color lightRose = Color(0xFFF3BFD8);
  static const Color lightPeach = Color(0xFFF5D6B4);
  static const List<Color> rimStops = [
    Color(0xFFA9AEF0),
    Color(0xFFE2A6CF),
    Color(0xFFF2B79D),
    Color(0xFF9FD8B4),
    Color(0xFF7EBEF0),
  ];
  static const Color pearlFrom = Color(0xEBEAE7FC);
  static const Color pearlTo = Color(0xDBF6F3FC);
  static const Color pearlBlush = Color(0x8CF4C4DE);
  static const List<Color> pearlRim = [
    Color(0xFFA9AEF0),
    Color(0xFFE2A6CF),
    Color(0xFFF2B79D),
    Color(0xFF9FD8B4),
    Color(0xFF8FC4F0),
  ];
  static const List<Color> pearlGlow = [
    Color(0xFFC7C1F6),
    Color(0xFFF2C2DA),
    Color(0xFFF6DABA),
  ];
  static const Color utilFrom = Color(0xFF8D96EB);
  static const Color utilTo = Color(0xFFD486C5);
  static const Color utilTrack = Color(0x1415152D);
  static const List<Color> avatarStops = [
    Color(0xFFE6E2FB),
    Color(0xFFF8E1EC),
    Color(0xFFFBEBD9),
  ];
  static const FrostedChartInks charts = FrostedChartInks(
    line: [Color(0xFF747BD9), Color(0xFFA968BC), Color(0xFFD76A88)],
    grid: Color(0x1215152D),
    areaFrom: Color(0x298F86E0),
    areaTo: Color(0x008F86E0),
    label: Color(0xFF5E5BB8),
    pace: Color(0x6615152D),
    endDot: Color(0xFFD76A88),
    endRing: Color(0xFFFFFFFF),
  );
  static const FrostedHues hues = FrostedHues(
    periwinkle: FrostedHue(
      a: Color(0xFF8D96EB),
      b: Color(0xFFA08FE5),
      ink: Color(0xFF4D4496),
      inkDeep: Color(0xFF342972),
      tint: Color(0x339792E9),
      tintSolid: Color(0x429792E9),
      edge: Color(0x579792E9),
    ),
    orchid: FrostedHue(
      a: Color(0xFFC58BD7),
      b: Color(0xFFD486C5),
      ink: Color(0xFF79377B),
      inkDeep: Color(0xFF561A58),
      tint: Color(0x33CD88CE),
      tintSolid: Color(0x42CD88CE),
      edge: Color(0x57CD88CE),
    ),
    coral: FrostedHue(
      a: Color(0xFFEF8893),
      b: Color(0xFFEF8B7B),
      ink: Color(0xFF99393B),
      inkDeep: Color(0xFF681119),
      tint: Color(0x33EF8987),
      tintSolid: Color(0x42EF8987),
      edge: Color(0x57EF8987),
    ),
    apricot: FrostedHue(
      a: Color(0xFFF6AA73),
      b: Color(0xFFEDB067),
      ink: Color(0xFF8B551B),
      inkDeep: Color(0xFF5A2800),
      tint: Color(0x33F2AD6C),
      tintSolid: Color(0x42F2AD6C),
      edge: Color(0x57F2AD6C),
    ),
    lemon: FrostedHue(
      a: Color(0xFFF7D471),
      b: Color(0xFFDFDE78),
      ink: Color(0xFF7B5F06),
      inkDeep: Color(0xFF4D3300),
      tint: Color(0x33ECD973),
      tintSolid: Color(0x42ECD973),
      edge: Color(0x57ECD973),
    ),
    mint: FrostedHue(
      a: Color(0xFF82CF98),
      b: Color(0xFF6BD1AD),
      ink: Color(0xFF256D4C),
      inkDeep: Color(0xFF004527),
      tint: Color(0x3377D0A2),
      tintSolid: Color(0x4277D0A2),
      edge: Color(0x5777D0A2),
    ),
    teal: FrostedHue(
      a: Color(0xFF64CACD),
      b: Color(0xFF68C7DC),
      ink: Color(0xFF026771),
      inkDeep: Color(0xFF00434C),
      tint: Color(0x3365C9D5),
      tintSolid: Color(0x4265C9D5),
      edge: Color(0x5765C9D5),
    ),
    sky: FrostedHue(
      a: Color(0xFF6AB2EB),
      b: Color(0xFF7FACF0),
      ink: Color(0xFF165A98),
      inkDeep: Color(0xFF003773),
      tint: Color(0x3375AFEE),
      tintSolid: Color(0x4275AFEE),
      edge: Color(0x5775AFEE),
    ),
    cyan: FrostedHue(
      a: Color(0xFF60BFDF),
      b: Color(0xFF89B3F1),
      ink: Color(0xFF005B8B),
      inkDeep: Color(0xFF003A5C),
      tint: Color(0x3373BAEA),
      tintSolid: Color(0x4273BAEA),
      edge: Color(0x5773BAEA),
    ),
    seafoam: FrostedHue(
      a: Color(0xFF7FD2B0),
      b: Color(0xFF6BD1D2),
      ink: Color(0xFF0B665B),
      inkDeep: Color(0xFF00453C),
      tint: Color(0x3372D2C1),
      tintSolid: Color(0x4272D2C1),
      edge: Color(0x5772D2C1),
    ),
    sunset: FrostedHue(
      a: Color(0xFFEDB06D),
      b: Color(0xFFFDA0A3),
      ink: Color(0xFF9C4438),
      inkDeep: Color(0xFF6A2718),
      tint: Color(0x33FAA684),
      tintSolid: Color(0x42FAA684),
      edge: Color(0x57FAA684),
    ),
    lagoon: FrostedHue(
      a: Color(0xFF57C5C6),
      b: Color(0xFFA7A9EF),
      ink: Color(0xFF325392),
      inkDeep: Color(0xFF1C3564),
      tint: Color(0x3372BAEA),
      tintSolid: Color(0x4272BAEA),
      edge: Color(0x5772BAEA),
    ),
    azure: FrostedHue(
      a: Color(0xFF60BFDF),
      b: Color(0xFF89B3F1),
      ink: Color(0xFF005B8B),
      inkDeep: Color(0xFF003A5C),
      tint: Color(0x3373BAEA),
      tintSolid: Color(0x4273BAEA),
      edge: Color(0x5773BAEA),
    ),
    lime: FrostedHue(
      a: Color(0xFFBBD786),
      b: Color(0xFF81E1B7),
      ink: Color(0xFF3C6B3C),
      inkDeep: Color(0xFF214821),
      tint: Color(0x339EDE9D),
      tintSolid: Color(0x429EDE9D),
      edge: Color(0x579EDE9D),
    ),
    emerald: FrostedHue(
      a: Color(0xFF6FCB98),
      b: Color(0xFF57C2A0),
      ink: Color(0xFF257B51),
      inkDeep: Color(0xFF0F5634),
      tint: Color(0x2140A874),
      tintSolid: Color(0x2940A874),
      edge: Color(0x4D40A874),
    ),
    slate: FrostedHue(
      a: Color(0xFFA3A3B4),
      b: Color(0xFF8E8EA3),
      ink: Color(0xFF5C5D68),
      inkDeep: Color(0xFF15151D),
      tint: Color(0x0B15152D),
      tintSolid: Color(0x0D15152D),
      edge: Color(0x1415152D),
    ),
    turquoise: FrostedHue(
      a: Color(0xFF57C5C6),
      b: Color(0xFF7FB4EC),
      ink: Color(0xFF0E5F78),
      inkDeep: Color(0xFF003C4E),
      tint: Color(0x3366BEDC),
      tintSolid: Color(0x4266BEDC),
      edge: Color(0x5766BEDC),
    ),
    lavender: FrostedHue(
      a: Color(0xFFA7A9EF),
      b: Color(0xFFC7A3E8),
      ink: Color(0xFF4F4B97),
      inkDeep: Color(0xFF342972),
      tint: Color(0x33B4A8EE),
      tintSolid: Color(0x42B4A8EE),
      edge: Color(0x57B4A8EE),
    ),
    iris: FrostedHue(
      a: Color(0xFFA9AEF0),
      b: Color(0xFFE2A6CF),
      ink: Color(0xFF4F4B97),
      inkDeep: Color(0xFF342972),
      tint: Color(0x29B2AAEC),
      tintSolid: Color(0x38B2AAEC),
      edge: Color(0x4DB2AAEC),
    ),
    silver: FrostedHue(
      a: Color(0xFFC3C5D3),
      b: Color(0xFFAEB0C2),
      ink: Color(0xFF5C5D68),
      inkDeep: Color(0xFF15151D),
      tint: Color(0x0D15152D),
      tintSolid: Color(0x0F15152D),
      edge: Color(0x1A15152D),
    ),
  );
}

/// The DESIGNED dark appearance of `prism`: light through glass at night.
/// The source is light only; this is its night, written from the concept's
/// principles rather than inverted from the day:
///
/// - a deep canvas, a blue-black with violet in it (#0E0D15), under the same
///   three washes lit from within: lilac, rose and peach turned to the
///   saturated middle of their hues, so at night they glow rather than haze;
/// - tiles of frosted dark glass (a violet-grey at the day glass's 62%, 78%
///   for a control) edged in white at 7% and rimmed along the top with a
///   line of light (white at 18%), so a tile reads by its edge and the light
///   it holds, as the day's does;
/// - the inks pale and cool on the same ladder as the day's: the ink 15:1 on
///   a tile, the second 7:1, the caption 5:1, the quiet ink 3.6:1 (a glyph
///   and the hung cents only);
/// - the spectrum's marks the day's own pastels, which glow on the dark;
///   their tints a step stronger so a pane is lit from within, their inks
///   lifted until a word reads 4.5:1 on its tint;
/// - the one act a pale pearl pill with the ink's words, the only light
///   face on the page; the toast a raised dark glass, so nothing competes
///   with it;
/// - the pearl credit card and the avatars a smoked pearl (a deep lavender with its
///   blush and its spectrum rim), so the page's pale words read on them as
///   they do on the glass.
///
/// Held by the theme test to every pair the day is held to.
abstract final class _Night {
  static const Color canvas = Color(0xFF0E0D15);
  static const Color surface = Color(0xFF1D1C27);
  static const Color surfaceAlt = Color(0xFF2A2934);
  static const Color plane = Color(0xFF363542);
  static const Color glass = Color(0x9E262532);
  static const Color glassHi = Color(0xC72B2A38);
  static const Color ink = Color(0xFFF3F2FA);
  static const Color ink2 = Color(0xFFC4C2D3);
  static const Color ink3 = Color(0xFFB3B1C4);
  static const Color line = Color(0x14FFFFFF);
  static const Color wash = Color(0x0FFFFFFF);
  static const Color edge = Color(0x12FFFFFF);
  static const Color wellEdge = Color(0x1FFFFFFF);
  static const Color borderStrong = Color(0x38FFFFFF);
  static const Color rim = Color(0x2EFFFFFF);
  static const Color well = Color(0xD1262532);
  static const Color moneyIn = Color(0xFF6FCB98);
  static const Color moneyInTint = Color(0x2E6FCB98);
  static const Color over = Color(0xFFEE8285);
  static const Color overTint = Color(0x2EEE8285);
  static const Color warn = Color(0xFFEBAE5C);
  static const Color warnTint = Color(0x2EEBAE5C);
  static const Color cold = Color(0xFF93BEEE);
  static const Color coldTint = Color(0x2978AAE6);
  static const Color coldEdge = Color(0x5778AAE6);
  static const Color actTop = Color(0xFFFFFFFF);
  static const Color actBottom = Color(0xFFE8E5F4);
  static const Color actSheen = Color(0xFFFFFFFF);
  static const Color ringOuter = Color(0xB3F3F2FA);
  static const Color scrim = Color(0x99050409);
  static const Color topFrost = Color(0x800E0D15);
  static const Color barFill = Color(0xD624232F);
  static const Color sideFill = Color(0x801D1C27);
  static const Color navCurrent = Color(0x1FFFFFFF);
  static const Color sheetTop = Color(0xFF252430);
  static const Color sheetBottom = Color(0xFF1D1C26);
  static const Color sheetEdge = Color(0x1AFFFFFF);
  static const Color grabber = Color(0x38FFFFFF);
  static const Color menuFill = Color(0xFF282733);
  static const Color menuEdge = Color(0x1AFFFFFF);
  static const Color toastTop = Color(0xFF2E2D3A);
  static const Color toastBottom = Color(0xFF23222D);
  static const Color toastSheen = Color(0x24FFFFFF);
  static const Color toastAction = Color(0x1AFFFFFF);
  static const Color trackFill = Color(0x14FFFFFF);
  static const Color trackEdge = Color(0x0FFFFFFF);
  static const Color meterTrack = Color(0x1FFFFFFF);
  static const Color paceTick = Color(0xCCF3F2FA);
  static const Color paceRing = Color(0xE60E0D15);
  static const Color toggleTrack = Color(0x2EFFFFFF);
  static const Color liftShade = Color(0x8C000000);
  static const Color barShade = Color(0x99000000);
  static const Color sheetShade = Color(0xA6000000);
  static const Color toastShade = Color(0x99000000);
  static const Color actShade = Color(0x80000000);
  static const Color raisedShade = Color(0x66000000);
  static const Color knobShade = Color(0xFF000000);
  static const Color pearlShade = Color(0x99000000);
  static const Color ticketShade = Color(0x80000000);
  static const Color lightLilac = Color(0xFF6A5AE0);
  static const Color lightRose = Color(0xFFC04C8C);
  static const Color lightPeach = Color(0xFFCF8448);
  static const double lightStrength = 0.5;
  static const Color pearlFrom = Color(0xEB2E2A4A);
  static const Color pearlTo = Color(0xE01F1D33);
  static const Color pearlBlush = Color(0x47D66EAA);
  static const List<Color> pearlGlow = [
    Color(0xFF4D42A8),
    Color(0xFF8E3C6A),
    Color(0xFF9A6236),
  ];
  static const Color utilTrack = Color(0x1FFFFFFF);
  static const List<Color> avatarStops = [
    Color(0xFF3A3463),
    Color(0xFF4A3150),
    Color(0xFF4B3C33),
  ];
  static final FrostedHues hues = _Source.hues.lit(
    ground: surface,
    toward: ink,
  );
  static const FrostedChartInks charts = FrostedChartInks(
    line: [Color(0xFF8F95E8), Color(0xFFBB82CF), Color(0xFFE88AA3)],
    grid: Color(0x14FFFFFF),
    areaFrom: Color(0x338F86E0),
    areaTo: Color(0x008F86E0),
    label: Color(0xFFB0ADF0),
    pace: Color(0x66F3F2FA),
    endDot: Color(0xFFE88AA3),
    endRing: Color(0xFF0E0D15),
  );
}

/// Two colour lists, stop by stop; lists of different lengths change at the
/// middle.
List<Color> _lerpColors(List<Color> a, List<Color> b, double t) =>
    a.length == b.length
    ? [for (var i = 0; i < a.length; i++) Color.lerp(a[i], b[i], t)!]
    : (t < .5 ? a : b);

bool _deepEquals(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    final x = a[i], y = b[i];
    if (x is List && y is List) {
      if (!listEquals(x, y)) return false;
    } else if (x != y) {
      return false;
    }
  }
  return true;
}

int _deepHash(Object? value) =>
    value is List ? Object.hashAll(value) : value.hashCode;

/// [hue] with its ink eased toward [toward] until it reads 4.5:1 on its tint
/// over each of [grounds]; the rest of it kept.
FrostedHue _heldHue(FrostedHue hue, Color toward, List<Color> grounds) =>
    FrostedHue(
      a: hue.a,
      b: hue.b,
      ink: FrostedThemeData._reach(hue.ink, toward, [
        for (final g in grounds) Color.alphaBlend(hue.tint, g),
      ], 4.5),
      inkDeep: hue.inkDeep,
      tint: hue.tint,
      tintSolid: hue.tintSolid,
      edge: hue.edge,
    );

/// A designed spectrum's hues, each held on its tint over [grounds] (the
/// page's grounds and the backdrop's washes): a fixed source colour can
/// stand on a wash deeper than the page it was drawn for.
FrostedHues _heldHues(FrostedHues h, Color toward, List<Color> grounds) {
  FrostedHue d(FrostedHue hue) => _heldHue(hue, toward, grounds);
  return FrostedHues(
    periwinkle: d(h.periwinkle),
    orchid: d(h.orchid),
    coral: d(h.coral),
    apricot: d(h.apricot),
    lemon: d(h.lemon),
    mint: d(h.mint),
    teal: d(h.teal),
    sky: d(h.sky),
    cyan: d(h.cyan),
    seafoam: d(h.seafoam),
    sunset: d(h.sunset),
    lagoon: d(h.lagoon),
    azure: d(h.azure),
    lime: d(h.lime),
    emerald: d(h.emerald),
    slate: d(h.slate),
    turquoise: d(h.turquoise),
    lavender: d(h.lavender),
    iris: d(h.iris),
    silver: d(h.silver),
  );
}
