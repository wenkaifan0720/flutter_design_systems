import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ui_core/host.dart';

import 'colors.dart';
import 'component_themes.dart';
import 'fonts.dart';
import 'internal/presets.g.dart';
import 'knobs.dart';

export 'colors.dart';
export 'component_themes.dart';
export 'knobs.dart';

/// Design tokens and theme assembly: the only styling vocabulary a Fluent 2
/// page may use.
///
/// Fluent 2 is a look in the Fluent 2 family, and its values are Fluent 2's,
/// read from `@fluentui/tokens` 1.0.0-alpha.24: the global scales (spacing,
/// radii, stroke widths, durations, curves, the type ramp) are this file's
/// consts under Fluent's own names (`spacingHorizontalM` is
/// [Fluent2Spacing.m], `borderRadiusMedium` [Fluent2Radius.medium],
/// `durationFaster` [Fluent2Motion.faster]); the colours are the alias tokens
/// of one preset in one appearance, generated as [Fluent2Colors]
/// (`internal/presets.g.dart`), carried by [Fluent2ThemeData.colors] and read by the
/// name the Fluent React component's styles read (`t.colors.neutralBackground1`).
///
/// The theme instances come from [Fluent2ThemeData.preset]: seven brand ramps,
/// each with its designed light and dark (Fluent's `webLightTheme` and
/// `webDarkTheme` for `lapis`, Fluent's indigo light and dark for `iris`, the
/// theme designer's mapping for the five generated brands).
/// [Fluent2ThemeData.from] makes one from a brand colour;
/// [Fluent2ThemeData.copyWith] changes any part of one, and [Fluent2Theme]
/// puts one in scope.

/// The spacing scale, Fluent's `spacingHorizontal*` and `spacingVertical*`
/// (one scale, both axes): 2, 4, 6, 8, 10, 12, 16, 20, 24, 32; and the two
/// layout steps above it pages use (40, 48).
abstract final class Fluent2Spacing {
  /// Fluent's `spacingHorizontalNone` and `spacingVerticalNone`: 0.
  static const double none = 0;

  /// Fluent's `spacingHorizontalXXS` and `spacingVerticalXXS`: 2.
  static const double xxs = 2;

  /// Fluent's `spacingHorizontalXS` and `spacingVerticalXS`: 4.
  static const double xs = 4;

  /// Fluent's `spacingHorizontalSNudge` and `spacingVerticalSNudge`: 6.
  static const double sNudge = 6;

  /// Fluent's `spacingHorizontalS` and `spacingVerticalS`: 8.
  static const double s = 8;

  /// Fluent's `spacingHorizontalMNudge` and `spacingVerticalMNudge`: 10.
  static const double mNudge = 10;

  /// Fluent's `spacingHorizontalM` and `spacingVerticalM`: 12.
  static const double m = 12;

  /// Fluent's `spacingHorizontalL` and `spacingVerticalL`: 16.
  static const double l = 16;

  /// Fluent's `spacingHorizontalXL` and `spacingVerticalXL`: 20.
  static const double xl = 20;

  /// Fluent's `spacingHorizontalXXL` and `spacingVerticalXXL`: 24.
  static const double xxl = 24;

  /// Fluent's `spacingHorizontalXXXL` and `spacingVerticalXXXL`: 32.
  static const double xxxl = 32;

  /// A layout step: a section's gap on the desktop.
  static const double x40 = 40;

  /// A layout step: a page's foot room on the desktop.
  static const double x48 = 48;
}

/// Corner radii, Fluent's `borderRadius*`: controls and cards at
/// [medium] (4), the small parts at [small] (2), a dialog at [xLarge] (8),
/// a pill or a disc at [circular].
abstract final class Fluent2Radius {
  /// Fluent's `borderRadiusNone`: 0.
  static const double none = 0;

  /// Fluent's `borderRadiusSmall`: 2.
  static const double small = 2;

  /// Fluent's `borderRadiusMedium`: 4.
  static const double medium = 4;

  /// Fluent's `borderRadiusLarge`: 6.
  static const double large = 6;

  /// Fluent's `borderRadiusXLarge`: 8.
  static const double xLarge = 8;

  /// Fluent's `borderRadius2XLarge`: 12.
  static const double x2Large = 12;

  /// Fluent's `borderRadius3XLarge`: 16.
  static const double x3Large = 16;

  /// Fluent's `borderRadius4XLarge`: 24.
  static const double x4Large = 24;

  /// Fluent's `borderRadius5XLarge`: 32.
  static const double x5Large = 32;

  /// Fluent's `borderRadius6XLarge`: 40.
  static const double x6Large = 40;

  /// Fluent's `borderRadiusCircular`: a pill's ends or a disc.
  static const double circular = 10000;
}

/// Stroke widths, Fluent's `strokeWidth*`.
abstract final class Fluent2Stroke {
  /// Fluent's `strokeWidthThin`: 1.
  static const double thin = 1;

  /// Fluent's `strokeWidthThick`: 2.
  static const double thick = 2;

  /// Fluent's `strokeWidthThicker`: 3.
  static const double thicker = 3;

  /// Fluent's `strokeWidthThickest`: 4.
  static const double thickest = 4;
}

/// Glyph sizes: the designs Fluent UI System Icons draws (12, 16, 20, 24,
/// 28, 32, 48); a control's glyph is 20 at its medium size.
abstract final class Fluent2IconSize {
  /// The 12 glyph design.
  static const double i12 = 12;

  /// The 16 glyph design.
  static const double i16 = 16;

  /// The 20 glyph design.
  static const double i20 = 20;

  /// The 24 glyph design.
  static const double i24 = 24;

  /// The 28 glyph design.
  static const double i28 = 28;

  /// The 32 glyph design.
  static const double i32 = 32;

  /// The 48 glyph design.
  static const double i48 = 48;
}

/// Motion, Fluent's `duration*` and `curve*` tokens.
abstract final class Fluent2Motion {
  /// Fluent's `durationUltraFast`: 50 ms.
  static const Duration ultraFast = Duration(milliseconds: 50);

  /// Fluent's `durationFaster`: 100 ms.
  static const Duration faster = Duration(milliseconds: 100);

  /// Fluent's `durationFast`: 150 ms.
  static const Duration fast = Duration(milliseconds: 150);

  /// Fluent's `durationNormal`: 200 ms.
  static const Duration normal = Duration(milliseconds: 200);

  /// Fluent's `durationGentle`: 250 ms.
  static const Duration gentle = Duration(milliseconds: 250);

  /// Fluent's `durationSlow`: 300 ms.
  static const Duration slow = Duration(milliseconds: 300);

  /// Fluent's `durationSlower`: 400 ms.
  static const Duration slower = Duration(milliseconds: 400);

  /// Fluent's `durationUltraSlow`: 500 ms.
  static const Duration ultraSlow = Duration(milliseconds: 500);

  /// Fluent's `curveAccelerateMax`.
  static const Curve accelerateMax = Cubic(0.9, 0.1, 1, 0.2);

  /// Fluent's `curveAccelerateMid`.
  static const Curve accelerateMid = Cubic(1, 0, 1, 1);

  /// Fluent's `curveAccelerateMin`.
  static const Curve accelerateMin = Cubic(0.8, 0, 0.78, 1);

  /// Fluent's `curveDecelerateMax`.
  static const Curve decelerateMax = Cubic(0.1, 0.9, 0.2, 1);

  /// Fluent's `curveDecelerateMid`.
  static const Curve decelerateMid = Cubic(0, 0, 0, 1);

  /// Fluent's `curveDecelerateMin`.
  static const Curve decelerateMin = Cubic(0.33, 0, 0.1, 1);

  /// Fluent's `curveEasyEaseMax`.
  static const Curve easyEaseMax = Cubic(0.8, 0, 0.2, 1);

  /// Fluent's `curveEasyEase`.
  static const Curve easyEase = Cubic(0.33, 0, 0.67, 1);

  /// Fluent's `curveLinear`.
  static const Curve linear = Curves.linear;

  /// Whether a part at [context] moves: unless the reader has asked for
  /// reduced motion (`MediaQuery.disableAnimationsOf`, Flutter's own switch,
  /// which a test sets with `FakeAccessibilityFeatures`). Off, every state
  /// change is a cut.
  static bool on(BuildContext context) =>
      !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  /// [duration] at [context], or none when motion is off.
  static Duration of(BuildContext context, Duration duration) =>
      on(context) ? duration : Duration.zero;
}

/// The window's size class, Material's breakpoints: [compact] under 600,
/// [medium] under 840, [expanded] under 1200, [large] from there.
///
/// ```dart
/// final wide = Fluent2WindowClass.of(context) >= Fluent2WindowClass.expanded;
/// ```
enum Fluent2WindowClass implements Comparable<Fluent2WindowClass> {
  /// Under 600: a phone.
  compact,

  /// 600 to under 840: a small tablet, or a phone on its side.
  medium,

  /// 840 to under 1200: a tablet, or a small window.
  expanded,

  /// 1200 and over: a desktop window.
  large;

  /// The class of a window [width] wide.
  static Fluent2WindowClass forWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : width < 1200
      ? expanded
      : large;

  /// The class of the window at [context].
  static Fluent2WindowClass of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);

  /// Whether this class is [other] or wider.
  bool operator >=(Fluent2WindowClass other) => index >= other.index;

  /// Whether this class is narrower than [other].
  bool operator <(Fluent2WindowClass other) => index < other.index;

  @override
  int compareTo(Fluent2WindowClass other) => index - other.index;
}

/// A fixed spacer of one [Fluent2Spacing] step.
class Fluent2Gap extends StatelessWidget {
  /// A gap [size] wide and tall.
  const Fluent2Gap(this.size, {super.key});

  /// Its width and height: one [Fluent2Spacing] step.
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(width: size, height: size);
}

/// Responsive layout invariants shared by Fluent 2 apps.
abstract final class Fluent2Layout {
  /// The width from which the app is the desktop one (Fluent's `xl`
  /// breakpoint, 1024): the nav pane replaces the tab bar, the gutter grows
  /// to 24, a sheet becomes a centred dialog or a side drawer, and a
  /// pushed page's bar becomes a breadcrumb over its title.
  static const double wide = 1024;

  /// The width from which a phone layout gets the medium margins (Fluent's
  /// `medium` breakpoint, 640).
  static const double medium = 640;

  /// The touch-target floor (Fluent 2 mobile's 44).
  static const double minHitTarget = 44;

  /// The target floor where a touch reaches the controls (Android, iOS and
  /// Fuchsia, as Material's padded tap target): 48.
  static const double touchHitTarget = 48;

  /// The least target at [context]: [touchHitTarget] on a touch platform,
  /// [minHitTarget] elsewhere. A control's face keeps its own size; the
  /// room round it takes the touch.
  static double hitTargetOf(BuildContext context) =>
      padded(context) ? touchHitTarget : minHitTarget;

  /// Whether a touch reaches the controls at [context] (Android, iOS and
  /// Fuchsia, where Material pads its tap targets): there a press stands at
  /// least [touchHitTarget] square, its face at its own size and centred.
  static bool padded(BuildContext context) =>
      switch (Theme.of(context).platform) {
        TargetPlatform.android ||
        TargetPlatform.iOS ||
        TargetPlatform.fuchsia => true,
        _ => false,
      };

  /// The nav pane's width on the desktop (Fluent's `NavDrawer`, 260).
  static const double navPane = 260;

  /// Whether the window is the desktop one.
  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= wide;

  /// Whether a select, a date field or a menu opens as a list anchored to
  /// its face (a popover) at [context]: on the desktop, and wherever a
  /// pointer reaches it (Fluent's web dropdown, at any window width), the
  /// list starting on the field's leading edge at least as wide as it.
  /// Under a finger below the desktop it opens as a sheet (Fluent's mobile
  /// pickers).
  static bool popsOver(BuildContext context) =>
      isWide(context) || !padded(context);

  /// The page gutter at [context]: 16 on a phone, 24 on the desktop.
  static double gutter(BuildContext context) =>
      isWide(context) ? Fluent2Spacing.xxl : Fluent2Spacing.l;

  /// The gap between cards and sections: 12 on a phone, 16 on the desktop.
  static double gap(BuildContext context) =>
      isWide(context) ? Fluent2Spacing.l : Fluent2Spacing.m;
}

/// The recipe of Fluent's acrylic, the material of what floats over the page
/// (the tab bar, the nav pane, a menu, a popover, a tooltip's pane): a blur
/// of what lies behind, a luminosity layer that steadies it, a tint, and a
/// fine noise, as Fluent's in-app acrylic layers them. Drawn by
/// `Fluent2Acrylic`: one `BackdropFilter` under the fills, so a list of rows
/// never pays for it.
@immutable
final class Fluent2AcrylicRecipe with Diagnosticable {
  /// An acrylic from its layers.
  const Fluent2AcrylicRecipe({
    required this.tint,
    required this.tintOpacity,
    required this.luminosity,
    required this.luminosityOpacity,
    required this.blur,
    required this.noiseOpacity,
    required this.fallback,
  });

  /// The tint layer's colour.
  final Color tint;

  /// How much of [tint] lies over the luminosity layer, 0..1.
  final double tintOpacity;

  /// The luminosity layer's colour: the steady ground the blur reads on.
  final Color luminosity;

  /// How opaque the luminosity layer is, 0..1.
  final double luminosityOpacity;

  /// The blur's Gaussian sigma (a 30 px CSS blur radius halved).
  final double blur;

  /// The noise's opacity, 0..1.
  final double noiseOpacity;

  /// The opaque colour the material stands in as where nothing blurs (a
  /// media ground, the contrast tests).
  final Color fallback;

  /// The two fills laid over the blur, as one colour: the luminosity layer
  /// with the tint over it.
  Color get fill => Color.alphaBlend(
    tint.withValues(alpha: tintOpacity),
    luminosity.withValues(alpha: luminosityOpacity),
  );

  /// This with the named layers changed.
  Fluent2AcrylicRecipe copyWith({
    Color? tint,
    double? tintOpacity,
    Color? luminosity,
    double? luminosityOpacity,
    double? blur,
    double? noiseOpacity,
    Color? fallback,
  }) => Fluent2AcrylicRecipe(
    tint: tint ?? this.tint,
    tintOpacity: tintOpacity ?? this.tintOpacity,
    luminosity: luminosity ?? this.luminosity,
    luminosityOpacity: luminosityOpacity ?? this.luminosityOpacity,
    blur: blur ?? this.blur,
    noiseOpacity: noiseOpacity ?? this.noiseOpacity,
    fallback: fallback ?? this.fallback,
  );

  /// Between [a] and [b], layer by layer.
  static Fluent2AcrylicRecipe lerp(
    Fluent2AcrylicRecipe a,
    Fluent2AcrylicRecipe b,
    double t,
  ) => identical(a, b)
      ? a
      : Fluent2AcrylicRecipe(
          tint: Color.lerp(a.tint, b.tint, t)!,
          tintOpacity: lerpDouble(a.tintOpacity, b.tintOpacity, t)!,
          luminosity: Color.lerp(a.luminosity, b.luminosity, t)!,
          luminosityOpacity: lerpDouble(
            a.luminosityOpacity,
            b.luminosityOpacity,
            t,
          )!,
          blur: lerpDouble(a.blur, b.blur, t)!,
          noiseOpacity: lerpDouble(a.noiseOpacity, b.noiseOpacity, t)!,
          fallback: Color.lerp(a.fallback, b.fallback, t)!,
        );

  @override
  bool operator ==(Object other) =>
      other is Fluent2AcrylicRecipe &&
      other.tint == tint &&
      other.tintOpacity == tintOpacity &&
      other.luminosity == luminosity &&
      other.luminosityOpacity == luminosityOpacity &&
      other.blur == blur &&
      other.noiseOpacity == noiseOpacity &&
      other.fallback == fallback;

  @override
  int get hashCode => Object.hash(
    tint,
    tintOpacity,
    luminosity,
    luminosityOpacity,
    blur,
    noiseOpacity,
    fallback,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('tint', tint));
    properties.add(DoubleProperty('tintOpacity', tintOpacity));
    properties.add(ColorProperty('luminosity', luminosity));
    properties.add(DoubleProperty('luminosityOpacity', luminosityOpacity));
    properties.add(DoubleProperty('blur', blur));
    properties.add(DoubleProperty('noiseOpacity', noiseOpacity));
    properties.add(ColorProperty('fallback', fallback));
  }
}

/// Fluent's elevations, each an ambient shadow all round and a key shadow
/// cast down, as `shadow2` to `shadow64` lay them.
@immutable
final class Fluent2Shadows with Diagnosticable {
  /// The six elevations.
  const Fluent2Shadows({
    required this.shadow2,
    required this.shadow4,
    required this.shadow8,
    required this.shadow16,
    required this.shadow28,
    required this.shadow64,
  });

  /// A card at rest, a selected chip.
  final List<BoxShadow> shadow2;

  /// A card, a raised button.
  final List<BoxShadow> shadow4;

  /// A hovered card, a tab bar, a nav pane over content.
  final List<BoxShadow> shadow8;

  /// A menu, a popover, a tooltip, a toast.
  final List<BoxShadow> shadow16;

  /// A side drawer, a bottom sheet.
  final List<BoxShadow> shadow28;

  /// A dialog.
  final List<BoxShadow> shadow64;

  /// Fluent's `createShadowTokens(ambient, key)`: `0 0 2px ambient, 0 1px
  /// 2px key` up to `0 0 8px ambient, 0 32px 64px key`, as Flutter draws a
  /// CSS shadow.
  factory Fluent2Shadows.of(Color ambient, Color key) {
    List<BoxShadow> pair(double ambientBlur, double y, double keyBlur) => [
      fluent2CssShadow(color: ambient, blur: ambientBlur),
      fluent2CssShadow(color: key, y: y, blur: keyBlur),
    ];
    return Fluent2Shadows(
      shadow2: pair(2, 1, 2),
      shadow4: pair(2, 2, 4),
      shadow8: pair(2, 4, 8),
      shadow16: pair(2, 8, 16),
      shadow28: pair(8, 14, 28),
      shadow64: pair(8, 32, 64),
    );
  }

  List<List<BoxShadow>> get _all => [
    shadow2,
    shadow4,
    shadow8,
    shadow16,
    shadow28,
    shadow64,
  ];

  /// Between [a] and [b], elevation by elevation.
  static Fluent2Shadows lerp(Fluent2Shadows a, Fluent2Shadows b, double t) {
    if (identical(a, b)) return a;
    List<BoxShadow> l(List<BoxShadow> x, List<BoxShadow> y) =>
        BoxShadow.lerpList(x, y, t)!;
    return Fluent2Shadows(
      shadow2: l(a.shadow2, b.shadow2),
      shadow4: l(a.shadow4, b.shadow4),
      shadow8: l(a.shadow8, b.shadow8),
      shadow16: l(a.shadow16, b.shadow16),
      shadow28: l(a.shadow28, b.shadow28),
      shadow64: l(a.shadow64, b.shadow64),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Fluent2Shadows) return false;
    final x = _all, y = other._all;
    for (var i = 0; i < x.length; i++) {
      if (!listEquals(x[i], y[i])) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll([for (final l in _all) ...l]);
}

/// A CSS `box-shadow` as Flutter draws one: CSS blurs a shadow to a
/// standard deviation of half its blur radius, Flutter's radius maps to
/// `0.57735 r + 0.5`. Plumbing of the components.
BoxShadow fluent2CssShadow({
  required Color color,
  double x = 0,
  double y = 0,
  double blur = 0,
  double spread = 0,
}) => BoxShadow(
  offset: Offset(x, y),
  blurRadius: blur <= 0 ? 0 : math.max(0, (blur / 2 - 0.5) / 0.57735),
  spreadRadius: spread,
  color: color,
);

/// The tone a badge, a message bar, a field's validation or a toast wears:
/// Fluent's informative (the neutral grey), brand, success, warning, danger
/// (Fluent's error) and severe (its darker orange).
enum Fluent2Tone {
  /// Fluent's informative tone, a neutral grey.
  informative,

  /// The brand colour.
  brand,

  /// Fluent's success green.
  success,

  /// Fluent's warning amber.
  warning,

  /// Fluent's danger red (its `error`).
  danger,

  /// Fluent's severe warning, a darker orange.
  severe,
}

/// One tone's colours: a word or glyph ink ([ink], 4.5:1 on its [tint] and
/// on the page's surfaces), the solid fill ([solid]) with the ink set on it
/// ([onSolid]), the subtle tint ([tint]) and its border ([border]).
@immutable
final class Fluent2ToneColors {
  /// A tone's five colours.
  const Fluent2ToneColors({
    required this.ink,
    required this.solid,
    required this.onSolid,
    required this.tint,
    required this.border,
  });

  /// The tone's ink for words and glyphs, 4.5:1 on its [tint] and on the page's
  /// surfaces.
  final Color ink;

  /// The tone's solid fill.
  final Color solid;

  /// The ink set on [solid].
  final Color onSolid;

  /// The tone's subtle tint, a message bar's or a subtle badge's fill.
  final Color tint;

  /// The edge round [tint].
  final Color border;
}

/// Fluent 2's theme: one preset in one appearance, as Material's `ThemeData`
/// is Material's. Every colour is a Fluent alias in [colors] (ui_core's
/// roles below are named views of them), the page's ground ([background]),
/// the acrylic ([acrylic]), the elevations ([shadows],
/// [brandShadows]), the type ramp ([caption2] to [display], Fluent's own
/// names), the component themes ([components]), and the [density] and
/// [typeface] settings. Corners and strokes are Fluent's tokens
/// ([Fluent2Radius], [Fluent2Stroke]); a component theme sets one part's
/// shape.
///
/// Built from a preset ([preset], or a named factory such as
/// [Fluent2ThemeData.lapis]) and changed with [copyWith]; [lerp] blends two,
/// as [AnimatedFluent2Theme] does. [Fluent2Theme] puts one in scope.
///
/// ```dart
/// final theme = Fluent2ThemeData.lapis(Brightness.dark).copyWith(
///   density: Fluent2Density.compact,
/// );
/// ```
@immutable
final class Fluent2ThemeData with Diagnosticable {
  Fluent2ThemeData._({
    required this.id,
    required this.brightness,
    required this.colors,
    required this.sharedColors,
    required this.brandVariants,
    required this.background,
    required this.acrylic,
    required this.shadows,
    required this.brandShadows,
    this.components = const Fluent2ComponentThemes(),
    this.density = Fluent2Density.standard,
    this.typeface = Fluent2Typeface.look,
  });

  /// The `lapis` preset: Fluent's own web light and dark, the familiar web blue (#0F6CBD).
  factory Fluent2ThemeData.lapis([Brightness brightness = Brightness.light]) =>
      preset('lapis', brightness);

  /// The `iris` preset: Fluent's indigo light and dark (#5B5FC7).
  factory Fluent2ThemeData.iris([Brightness brightness = Brightness.light]) =>
      preset('iris', brightness);

  /// The `juniper` preset: a teal brand ramp (#038387) from Fluent's theme designer.
  factory Fluent2ThemeData.juniper([
    Brightness brightness = Brightness.light,
  ]) => preset('juniper', brightness);

  /// The `clover` preset: a green brand ramp (#107C10) from Fluent's theme designer.
  factory Fluent2ThemeData.clover([Brightness brightness = Brightness.light]) =>
      preset('clover', brightness);

  /// The `pumpkin` preset: a warm orange brand ramp (#CA5010) from Fluent's theme designer.
  factory Fluent2ThemeData.pumpkin([
    Brightness brightness = Brightness.light,
  ]) => preset('pumpkin', brightness);

  /// The `berry` preset: a vivid magenta brand ramp (#C239B3) from Fluent's theme designer.
  factory Fluent2ThemeData.berry([Brightness brightness = Brightness.light]) =>
      preset('berry', brightness);

  /// The `flint` preset: graphite (#394146), a neutral ramp with no accent.
  factory Fluent2ThemeData.flint([Brightness brightness = Brightness.light]) =>
      preset('flint', brightness);

  /// Which preset this theme is (see [presets]).
  final String id;

  /// Which appearance this theme is.
  final Brightness brightness;

  /// Every Fluent alias colour of this preset and appearance, by Fluent's
  /// name: `t.colors.neutralBackground1`, `t.colors.brandBackgroundHover`,
  /// `t.colors.statusDangerForeground1`.
  final Fluent2Colors colors;

  /// Fluent's shared palette in this appearance (the avatars', badges' and
  /// tags' named hues).
  final Fluent2SharedColors sharedColors;

  /// The brand ramp, shades 10 to 160 ([brand] reads one by its number).
  final List<Color> brandVariants;

  /// The ground the page stands on: Fluent's quiet base layer, faintly
  /// tinted by the brand. Light: the brand's palest shade at 30% over
  /// `neutralBackground3` (#F5F5F5); dark: its deepest shade but one at 30%
  /// over `neutralBackground2` (#1F1F1F).
  final Color background;

  /// The acrylic of what floats over the page.
  final Fluent2AcrylicRecipe acrylic;

  /// The neutral elevations (`shadow2` .. `shadow64`).
  final Fluent2Shadows shadows;

  /// The brand elevations (`shadow2Brand` .. `shadow64Brand`): a primary
  /// button raised, a selected card.
  final Fluent2Shadows brandShadows;

  /// The component themes, one per part, each empty unless set; every part
  /// also reads its own through the getters below ([primaryButtonTheme],
  /// [checkboxTheme], ...).
  final Fluent2ComponentThemes components;

  /// How compact the controls stand; [Fluent2Density.standard] unless set.
  final Fluent2Density density;

  /// The face and size scale of the type ramp; Selawik at Fluent's sizes
  /// unless set.
  final Fluent2Typeface typeface;

  /// Fluent's `caption2`, 10/14 regular.
  late final TextStyle caption2 = _ramp(10, 14, 400);

  /// `caption2Strong`, 10/14 semibold.
  late final TextStyle caption2Strong = _ramp(10, 14, 600);

  /// `caption1`, 12/16 regular: a timestamp, a hint, a tab bar's label.
  late final TextStyle caption1 = _ramp(12, 16, 400);

  /// `caption1Strong`, 12/16 semibold: a badge, a small button.
  late final TextStyle caption1Strong = _ramp(12, 16, 600);

  /// `caption1Stronger`, 12/16 bold.
  late final TextStyle caption1Stronger = _ramp(12, 16, 700);

  /// `body1`, 14/20 regular: the running text of every control and row.
  late final TextStyle body1 = _ramp(14, 20, 400);

  /// `body1Strong`, 14/20 semibold: a button, a row's title, a label.
  late final TextStyle body1Strong = _ramp(14, 20, 600);

  /// `body1Stronger`, 14/20 bold.
  late final TextStyle body1Stronger = _ramp(14, 20, 700);

  /// `body2`, 16/22 regular: a large control, a reading paragraph.
  late final TextStyle body2 = _ramp(16, 22, 400);

  /// `subtitle2`, 16/22 semibold: a card's title, a dialog's section.
  late final TextStyle subtitle2 = _ramp(16, 22, 600);

  /// `subtitle2Stronger`, 16/22 bold.
  late final TextStyle subtitle2Stronger = _ramp(16, 22, 700);

  /// `subtitle1`, 20/28 semibold: a dialog's title, a drawer's title, a
  /// phone page's title.
  late final TextStyle subtitle1 = _ramp(20, 28, 600);

  /// `title3`, 24/32 semibold: a section's title on the desktop.
  late final TextStyle title3 = _ramp(24, 32, 600);

  /// `title2`, 28/36 semibold: a page's title on the desktop.
  late final TextStyle title2 = _ramp(28, 36, 600);

  /// `title1`, 32/40 semibold: a hero's title.
  late final TextStyle title1 = _ramp(32, 40, 600);

  /// `largeTitle`, 40/52 semibold: a lead figure.
  late final TextStyle largeTitle = _ramp(40, 52, 600);

  /// `display`, 68/92 semibold: the one display figure of a page.
  late final TextStyle display = _ramp(68, 92, 600);

  TextStyle _ramp(double size, double line, int weight) =>
      typeface.style(size, line, weight, colors.neutralForeground1);

  /// A primary button's theme.
  Fluent2Style get primaryButtonTheme => components.primaryButton;

  /// A secondary button's theme (the default appearance).
  Fluent2Style get secondaryButtonTheme => components.secondaryButton;

  /// An outline button's theme.
  Fluent2Style get outlineButtonTheme => components.outlineButton;

  /// A subtle button's theme.
  Fluent2Style get subtleButtonTheme => components.subtleButton;

  /// A transparent button's theme.
  Fluent2Style get transparentButtonTheme => components.transparentButton;

  /// An icon button's theme.
  Fluent2Style get iconButtonTheme => components.iconButton;

  /// A check box's theme.
  Fluent2Style get checkboxTheme => components.checkbox;

  /// A radio's theme.
  Fluent2Style get radioTheme => components.radio;

  /// A switch's theme.
  Fluent2Style get switchTheme => components.switchTheme;

  /// A field frame's theme.
  Fluent2Style get textFieldTheme => components.textField;

  /// A tag's and an interaction tag's theme.
  Fluent2Style get tagTheme => components.tag;

  /// A slider's theme.
  Fluent2Style get sliderTheme => components.slider;

  /// The segmented strip's theme.
  Fluent2Style get segmentedButtonTheme => components.segmentedButton;

  /// A tab bar's theme.
  Fluent2Style get tabListTheme => components.tabList;

  /// A card's theme.
  Fluent2Style get cardTheme => components.card;

  /// A list row's theme.
  Fluent2Style get listItemTheme => components.listItem;

  /// A dialog's theme.
  Fluent2Style get dialogTheme => components.dialog;

  /// A bottom sheet's theme.
  Fluent2Style get bottomSheetTheme => components.bottomSheet;

  /// A menu's theme.
  Fluent2Style get menuTheme => components.menu;

  /// A toast's theme.
  Fluent2Style get toastTheme => components.toast;

  /// A tooltip's theme.
  Fluent2Style get tooltipTheme => components.tooltip;

  /// A badge's theme.
  Fluent2Style get badgeTheme => components.badge;

  /// An avatar's theme.
  Fluent2Style get avatarTheme => components.avatar;

  /// Whether this is the dark appearance.
  bool get isDark => brightness == Brightness.dark;

  /// The brand ramp's shade [shade] (10, 20, .. 160).
  Color brand(int shade) {
    assert(shade % 10 == 0 && shade >= 10 && shade <= 160, 'a ramp shade');
    return brandVariants[shade ~/ 10 - 1];
  }

  // --- ui_core's roles, as views of Fluent's aliases ---------------------------

  /// A card's, a list's, a field's face: `neutralBackground1`.
  Color get surface => colors.neutralBackground1;

  /// An inset ground (a filled field, a well, a code line):
  /// `neutralBackground3`.
  Color get surfaceAlt => colors.neutralBackground3;

  /// The inverted plane (a tooltip, an inverted toast):
  /// `neutralBackgroundInverted`.
  Color get surfaceInverse => colors.neutralBackgroundInverted;

  /// A divider, a card's edge: `neutralStroke2`.
  Color get border => colors.neutralStroke2;

  /// A control's outline: `neutralStroke1`.
  Color get borderStrong => colors.neutralStroke1;

  /// The 3:1 edge of an input and a toggle: `neutralStrokeAccessible`.
  Color get edge => colors.neutralStrokeAccessible;

  /// The first ink: `neutralForeground1`.
  Color get textPrimary => colors.neutralForeground1;

  /// The second ink: `neutralForeground2`.
  Color get textSecondary => colors.neutralForeground2;

  /// The third ink, a caption's: `neutralForeground3`.
  Color get textTertiary => colors.neutralForeground3;

  /// The fourth ink, the quietest word: `neutralForeground4`.
  Color get textQuiet => colors.neutralForeground4;

  /// The ink of a disabled control: `neutralForegroundDisabled`.
  Color get textDisabled => colors.neutralForegroundDisabled;

  /// Words on [surfaceInverse]: `neutralForegroundInverted`.
  Color get textInverse => colors.neutralForegroundInverted;

  /// The brand fill: a primary button, a checked box: `brandBackground`.
  Color get accent => colors.brandBackground;

  /// Words on [accent]: `neutralForegroundOnBrand`.
  Color get onAccent => colors.neutralForegroundOnBrand;

  /// The brand's tint: a selected row, an informative wash:
  /// `brandBackground2`.
  Color get accentSubtle => colors.brandBackground2;

  /// Brand words and glyphs on the surfaces: `brandForeground1`.
  Color get accentText => colors.brandForeground1;

  /// A link's ink: `brandForegroundLink`.
  Color get link => colors.brandForegroundLink;

  /// The focus ring's outer stroke: `strokeFocus2`.
  Color get focus => colors.strokeFocus2;

  /// The scrim under a dialog or a drawer: `backgroundOverlay`.
  Color get overlay => colors.backgroundOverlay;

  /// Success's ink.
  Color get success => tone(Fluent2Tone.success).ink;

  /// Words on success's solid.
  Color get onSuccess => tone(Fluent2Tone.success).onSolid;

  /// Success's tint.
  Color get successSubtle => tone(Fluent2Tone.success).tint;

  /// Warning's ink.
  Color get warning => tone(Fluent2Tone.warning).ink;

  /// Warning's tint.
  Color get warningSubtle => tone(Fluent2Tone.warning).tint;

  /// Danger's ink (Fluent's error).
  Color get danger => tone(Fluent2Tone.danger).ink;

  /// Words on danger's solid.
  Color get onDanger => tone(Fluent2Tone.danger).onSolid;

  /// Danger's tint.
  Color get dangerSubtle => tone(Fluent2Tone.danger).tint;

  /// One tone's colours, from Fluent's status tokens (danger, success,
  /// warning), its severe palette (dark orange), its brand and its neutral
  /// informative. The ink is the status `Foreground1`, the solid its
  /// `Background3`, the tint its `Background1` and the border its
  /// `Border1`; warning's solid carries the page ink, as Fluent's warning
  /// badge does (white on #F7630C reads 3.0:1).
  Fluent2ToneColors tone(Fluent2Tone tone) => switch (tone) {
    Fluent2Tone.informative => Fluent2ToneColors(
      ink: colors.neutralForeground3,
      solid: colors.neutralBackground5,
      onSolid: colors.neutralForeground1,
      // By day Fluent's `neutralBackground3` step from white laid over the
      // ground (4% ink), so a neutral message bar stays a filled bar on the
      // brand-tinted page rather than an empty frame.
      tint: brightness == Brightness.dark
          ? colors.neutralBackground3
          : const Color(0x0A000000),
      border: colors.neutralStroke1,
    ),
    Fluent2Tone.brand => Fluent2ToneColors(
      ink: colors.brandForeground1,
      solid: colors.brandBackground,
      onSolid: colors.neutralForegroundOnBrand,
      tint: colors.brandBackground2,
      border: colors.brandStroke2,
    ),
    Fluent2Tone.success => Fluent2ToneColors(
      ink: colors.statusSuccessForeground1,
      solid: colors.statusSuccessBackground3,
      onSolid: colors.neutralForegroundOnBrand,
      tint: colors.statusSuccessBackground1,
      border: colors.statusSuccessBorder1,
    ),
    Fluent2Tone.warning => Fluent2ToneColors(
      ink: colors.statusWarningForeground3,
      solid: colors.statusWarningBackground3,
      onSolid: const Color(0xFF242424),
      tint: colors.statusWarningBackground1,
      border: colors.statusWarningBorder1,
    ),
    Fluent2Tone.danger => Fluent2ToneColors(
      ink: colors.statusDangerForeground1,
      solid: colors.statusDangerBackground3,
      onSolid: colors.neutralForegroundOnBrand,
      tint: colors.statusDangerBackground1,
      border: colors.statusDangerBorder1,
    ),
    Fluent2Tone.severe => Fluent2ToneColors(
      ink: sharedColors.paletteDarkOrangeForeground1,
      solid: sharedColors.paletteDarkOrangeBackground3,
      onSolid: colors.neutralForegroundOnBrand,
      tint: sharedColors.paletteDarkOrangeBackground1,
      border: sharedColors.paletteDarkOrangeBorder1,
    ),
  };

  // --- presets ----------------------------------------------------------------

  /// The preset ids, the first the default.
  static const List<String> presets = <String>[
    'lapis',
    'iris',
    'juniper',
    'clover',
    'pumpkin',
    'berry',
    'flint',
  ];

  /// The theme for preset [id] in [brightness]; an unknown id throws.
  static Fluent2ThemeData preset(String id, Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final cached = (dark ? _dark : _light)[id];
    if (cached != null) return cached;
    final built = switch (id) {
      'lapis' => _build(
        id,
        brightness,
        dark ? fluent2Dark : fluent2Light,
        fluent2Ramp,
      ),
      'iris' => _build(id, brightness, dark ? irisDark : irisLight, irisRamp),
      'juniper' => _build(
        id,
        brightness,
        dark ? juniperDark : juniperLight,
        juniperRamp,
      ),
      'clover' => _build(
        id,
        brightness,
        dark ? cloverDark : cloverLight,
        cloverRamp,
      ),
      'pumpkin' => _build(
        id,
        brightness,
        dark ? pumpkinDark : pumpkinLight,
        pumpkinRamp,
      ),
      'berry' => _build(
        id,
        brightness,
        dark ? berryDark : berryLight,
        berryRamp,
      ),
      'flint' => _build(
        id,
        brightness,
        dark ? flintDark : flintLight,
        flintRamp,
      ),
      _ => throw ArgumentError.value(
        id,
        'id',
        'not a Fluent 2 preset (${presets.join(', ')})',
      ),
    };
    return (dark ? _dark : _light)[id] = built;
  }

  static final Map<String, Fluent2ThemeData> _light = {};
  static final Map<String, Fluent2ThemeData> _dark = {};

  /// The bundled face: Selawik, the open stand-in for Fluent's system face
  /// (metric compatible), in its regular, semibold and bold files.
  static const String face = fluent2FontPackage == null
      ? 'Selawik'
      : 'packages/$fluent2FontPackage/Selawik';

  /// A Fluent type style in the bundled face: [size] on a [line] px line at
  /// [weight], in [color], set with even leading so a line centres in its
  /// box as CSS centres it.
  static TextStyle type(double size, double line, int weight, Color color) =>
      Fluent2Typeface.look.style(size, line, weight, color);

  /// The page's ground: the neutral layer under the brand ramp's palest
  /// (light) or deepest (dark) shade at [tint].
  static Color _ground(
    Brightness brightness,
    Fluent2Colors c,
    List<Color> ramp, [
    double tint = 0.3,
  ]) => brightness == Brightness.dark
      ? Color.alphaBlend(ramp[1].withValues(alpha: tint), c.neutralBackground2)
      : Color.alphaBlend(
          ramp[15].withValues(alpha: tint),
          c.neutralBackground3,
        );

  static Fluent2ThemeData _build(
    String id,
    Brightness brightness,
    Fluent2Colors c,
    List<Color> ramp, {
    double tint = 0.3,
  }) {
    final dark = brightness == Brightness.dark;
    return Fluent2ThemeData._(
      id: id,
      brightness: brightness,
      colors: c,
      sharedColors: dark ? sharedDark : sharedLight,
      brandVariants: ramp,
      background: _ground(brightness, c, ramp, tint),
      acrylic: dark ? _acrylicDark : _acrylicLight,
      shadows: Fluent2Shadows.of(c.neutralShadowAmbient, c.neutralShadowKey),
      brandShadows: Fluent2Shadows.of(c.brandShadowAmbient, c.brandShadowKey),
    );
  }

  /// The acrylic, light: a #FCFCFC luminosity layer at 85% with no
  /// tint over it, blurred 30 px, 2% noise; #F9F9F9 where nothing blurs.
  static const Fluent2AcrylicRecipe _acrylicLight = Fluent2AcrylicRecipe(
    tint: Color(0xFFFCFCFC),
    tintOpacity: 0,
    luminosity: Color(0xFFFCFCFC),
    luminosityOpacity: 0.85,
    blur: 15,
    noiseOpacity: 0.02,
    fallback: Color(0xFFF9F9F9),
  );

  /// The acrylic, dark: #2C2C2C at 96% luminosity with the same
  /// tint at 15% over it, blurred 30 px, 2% noise; #2C2C2C where nothing
  /// blurs.
  static const Fluent2AcrylicRecipe _acrylicDark = Fluent2AcrylicRecipe(
    tint: Color(0xFF2C2C2C),
    tintOpacity: 0.15,
    luminosity: Color(0xFF2C2C2C),
    luminosityOpacity: 0.96,
    blur: 15,
    noiseOpacity: 0.02,
    fallback: Color(0xFF2C2C2C),
  );

  // --- a theme from a brand colour -------------------------------------------

  /// A Fluent 2 theme from one [brand] colour, as Fluent's theme designer
  /// makes one and as `ColorScheme.fromSeed` does for Material: a 16-shade
  /// ramp with [brand] at shade 80 (eased to black below it and to white
  /// above), every brand alias set from the shade Fluent's own `lapis`
  /// theme sets it from in [brightness], the neutrals and statuses
  /// Fluent's own. Then the contrast bars hold, whatever [brand] is: each
  /// brand family steps along the ramp, hover and pressed with it, until
  ///
  /// - the words on a brand fill (`neutralForegroundOnBrand` on
  ///   `brandBackground`) reach 4.5:1, and the inverted mark on
  ///   `compoundBrandBackground` (a check box's tick) 3:1;
  /// - the brand words and links on the surface (`brandForeground1`,
  ///   `compoundBrandForeground1`, `brandForegroundLink`) reach 4.5:1;
  /// - the brand strokes (`compoundBrandStroke`, `brandStroke1`) reach 3:1.
  ///
  /// The density, the typeface and the component themes ride along as
  /// `copyWith` takes them.
  ///
  /// ```dart
  /// final theme = Fluent2ThemeData.from(
  ///   brand: const Color(0xFF8A3FFC),
  ///   brightness: Brightness.dark,
  /// );
  /// ```
  factory Fluent2ThemeData.from({
    required Color brand,
    Brightness brightness = Brightness.light,
    String id = 'custom',
    Fluent2Density? density,
    Fluent2Typeface? typeface,
    Fluent2ComponentThemes? components,
  }) {
    final dark = brightness == Brightness.dark;
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    final seed = brand.withValues(alpha: 1);
    final ramp = [
      for (var i = 0; i < 16; i++)
        i < 7
            ? Color.lerp(black, seed, (i + 1) / 8)!
            : i == 7
            ? seed
            : Color.lerp(seed, white, (i - 7) / 9)!,
    ];
    final base = dark ? fluent2Dark : fluent2Light;
    final own = base.toMap();
    // Where Fluent's own theme takes each brand alias from: its shade.
    final shade = <String, int>{
      for (final MapEntry(:key, :value) in own.entries)
        if (key.contains('rand') && fluent2Ramp.contains(value))
          key: fluent2Ramp.indexOf(value),
    };
    final m = {
      ...own,
      for (final MapEntry(:key, :value) in shade.entries) key: ramp[value],
    };
    // Steps every alias of [family] together along the ramp, darker when
    // [darker], until each of them passes [holds].
    void hold(
      List<String> family,
      bool Function(Color colour) holds, {
      required bool darker,
    }) {
      final at = family.where(shade.containsKey).toList();
      for (var by = 0; by < 16 && at.isNotEmpty; by++) {
        final moved = {
          for (final key in at)
            key: ramp[(shade[key]! + (darker ? -by : by)).clamp(0, 15)],
        };
        if (!moved.values.every(holds) && by < 15) continue;
        m.addAll(moved);
        return;
      }
    }

    final onBrand = base.neutralForegroundOnBrand;
    final inverted = base.neutralForegroundInverted;
    final ink = base.neutralForeground1;
    // The tint under brand words (an accent-subtle chip) holds the page's
    // words first.
    hold(
      ['brandBackground2'],
      (tint) => contrast(ink, tint) >= 4.5,
      darker: dark,
    );
    // The brand-tinted page ground: Fluent's 30% of the ramp's end shade,
    // less where a deep seed would sink the neutral and status words on
    // it below 4.5 (a navy's palest shade is still blue-grey).
    final words = [
      base.neutralForeground1,
      base.neutralForeground2,
      base.neutralForeground3,
      base.statusDangerForeground1,
      base.statusSuccessForeground1,
      base.statusWarningForeground3,
    ];
    var tint = 0.3;
    while (tint > 0 &&
        words.any(
          (w) => contrast(w, _ground(brightness, base, ramp, tint)) < 4.5,
        )) {
      tint = math.max(0, tint - 0.05);
    }
    final page = _ground(brightness, base, ramp, tint);
    // Every ground brand words and strokes stand on: the three neutral
    // layers, the page, the acrylic's fallback and the brand tint.
    final grounds = [
      base.neutralBackground1,
      base.neutralBackground2,
      base.neutralBackground3,
      page,
      (dark ? _acrylicDark : _acrylicLight).fallback,
      m['brandBackground2']!,
    ];
    bool on(Color colour, double bar) =>
        grounds.every((g) => contrast(colour, g) >= bar);
    hold(
      [
        'brandBackground',
        'brandBackgroundHover',
        'brandBackgroundPressed',
        'brandBackgroundSelected',
      ],
      (fill) => contrast(onBrand, fill) >= 4.5,
      darker: onBrand.computeLuminance() > .5,
    );
    // The brand avatar's fill carries its initials in the static inverted
    // ink (white in both modes).
    final staticInk = base.neutralForegroundStaticInverted;
    hold(
      ['brandBackgroundStatic'],
      (fill) => contrast(staticInk, fill) >= 4.5,
      darker: staticInk.computeLuminance() > .5,
    );
    hold(
      [
        'compoundBrandBackground',
        'compoundBrandBackgroundHover',
        'compoundBrandBackgroundPressed',
      ],
      (fill) => contrast(inverted, fill) >= 3,
      darker: inverted.computeLuminance() > .5,
    );
    for (final family in [
      ['brandForeground1', 'brandForeground2'],
      [
        'compoundBrandForeground1',
        'compoundBrandForeground1Hover',
        'compoundBrandForeground1Pressed',
      ],
      [
        'brandForegroundLink',
        'brandForegroundLinkHover',
        'brandForegroundLinkPressed',
        'brandForegroundLinkSelected',
      ],
    ]) {
      hold(family, (colour) => on(colour, 4.5), darker: !dark);
    }
    for (final family in [
      [
        'compoundBrandStroke',
        'compoundBrandStrokeHover',
        'compoundBrandStrokePressed',
      ],
      ['brandStroke1'],
      [
        'neutralForeground2BrandSelected',
        'neutralForeground2BrandHover',
        'neutralForeground2BrandPressed',
      ],
    ]) {
      hold(family, (colour) => on(colour, 3), darker: !dark);
    }
    return _build(
      id,
      brightness,
      Fluent2Colors.fromMap(m),
      ramp,
      tint: tint,
    ).copyWith(density: density, typeface: typeface, components: components);
  }

  // --- ThemeData's shape -------------------------------------------------------

  /// This with the named parts changed: the colours ([colors],
  /// [sharedColors], [brandVariants], [background]), the acrylic and the
  /// elevations, the settings ([density], [typeface]), and the component
  /// themes whole ([components]) or one by one. The type ramp follows the
  /// first ink of [colors] and [typeface].
  Fluent2ThemeData copyWith({
    Fluent2Colors? colors,
    Fluent2SharedColors? sharedColors,
    List<Color>? brandVariants,
    Color? background,
    Fluent2AcrylicRecipe? acrylic,
    Fluent2Shadows? shadows,
    Fluent2Shadows? brandShadows,
    Fluent2Density? density,
    Fluent2Typeface? typeface,
    Fluent2ComponentThemes? components,
    Fluent2Style? primaryButtonTheme,
    Fluent2Style? secondaryButtonTheme,
    Fluent2Style? outlineButtonTheme,
    Fluent2Style? subtleButtonTheme,
    Fluent2Style? transparentButtonTheme,
    Fluent2Style? iconButtonTheme,
    Fluent2Style? checkboxTheme,
    Fluent2Style? radioTheme,
    Fluent2Style? switchTheme,
    Fluent2Style? textFieldTheme,
    Fluent2Style? tagTheme,
    Fluent2Style? sliderTheme,
    Fluent2Style? segmentedButtonTheme,
    Fluent2Style? tabListTheme,
    Fluent2Style? cardTheme,
    Fluent2Style? listItemTheme,
    Fluent2Style? dialogTheme,
    Fluent2Style? bottomSheetTheme,
    Fluent2Style? menuTheme,
    Fluent2Style? toastTheme,
    Fluent2Style? tooltipTheme,
    Fluent2Style? badgeTheme,
    Fluent2Style? avatarTheme,
  }) {
    assert(
      brandVariants == null || brandVariants.length == 16,
      'a brand ramp of sixteen shades',
    );
    return Fluent2ThemeData._(
      id: id,
      brightness: brightness,
      colors: colors ?? this.colors,
      sharedColors: sharedColors ?? this.sharedColors,
      brandVariants: brandVariants ?? this.brandVariants,
      background: background ?? this.background,
      acrylic: acrylic ?? this.acrylic,
      shadows: shadows ?? this.shadows,
      brandShadows: brandShadows ?? this.brandShadows,
      components: (components ?? this.components).copyWith(
        primaryButton: primaryButtonTheme,
        secondaryButton: secondaryButtonTheme,
        outlineButton: outlineButtonTheme,
        subtleButton: subtleButtonTheme,
        transparentButton: transparentButtonTheme,
        iconButton: iconButtonTheme,
        checkbox: checkboxTheme,
        radio: radioTheme,
        switchTheme: switchTheme,
        textField: textFieldTheme,
        tag: tagTheme,
        slider: sliderTheme,
        segmentedButton: segmentedButtonTheme,
        tabList: tabListTheme,
        card: cardTheme,
        listItem: listItemTheme,
        dialog: dialogTheme,
        bottomSheet: bottomSheetTheme,
        menu: menuTheme,
        toast: toastTheme,
        tooltip: tooltipTheme,
        badge: badgeTheme,
        avatar: avatarTheme,
      ),
      density: density ?? this.density,
      typeface: typeface ?? this.typeface,
    );
  }

  /// Between this and [other], as `ThemeData.lerp`: the colours, the ramp,
  /// the material, the elevations, the component themes and
  /// the density blend; the preset id, the appearance and the shared palette
  /// change at the middle. [AnimatedFluent2Theme] animates with it.
  Fluent2ThemeData lerp(Fluent2ThemeData? other, double t) {
    if (other == null || identical(this, other)) return this;
    final near = t < .5 ? this : other;
    return Fluent2ThemeData._(
      id: near.id,
      brightness: near.brightness,
      colors: _lerpColors(colors, other.colors, t),
      sharedColors: near.sharedColors,
      brandVariants: [
        for (var i = 0; i < brandVariants.length; i++)
          Color.lerp(brandVariants[i], other.brandVariants[i], t)!,
      ],
      background: Color.lerp(background, other.background, t)!,
      acrylic: Fluent2AcrylicRecipe.lerp(acrylic, other.acrylic, t),
      shadows: Fluent2Shadows.lerp(shadows, other.shadows, t),
      brandShadows: Fluent2Shadows.lerp(brandShadows, other.brandShadows, t),
      components: Fluent2ComponentThemes.lerp(components, other.components, t),
      density: Fluent2Density.lerp(density, other.density, t),
      typeface: Fluent2Typeface.lerp(typeface, other.typeface, t),
    );
  }

  static Fluent2Colors _lerpColors(Fluent2Colors a, Fluent2Colors b, double t) {
    if (identical(a, b)) return a;
    final x = a.toMap(), y = b.toMap();
    return Fluent2Colors.fromMap({
      for (final MapEntry(:key, :value) in x.entries)
        key: Color.lerp(value, y[key], t)!,
    });
  }

  static bool _sameColors(Fluent2Colors a, Fluent2Colors b) =>
      identical(a, b) || mapEquals(a.toMap(), b.toMap());

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Fluent2ThemeData &&
          other.id == id &&
          other.brightness == brightness &&
          _sameColors(other.colors, colors) &&
          identical(other.sharedColors, sharedColors) &&
          listEquals(other.brandVariants, brandVariants) &&
          other.background == background &&
          other.acrylic == acrylic &&
          other.shadows == shadows &&
          other.brandShadows == brandShadows &&
          other.components == components &&
          other.density == density &&
          other.typeface == typeface;

  @override
  int get hashCode => Object.hash(
    id,
    brightness,
    Object.hashAll(colors.toMap().values),
    identityHashCode(sharedColors),
    Object.hashAll(brandVariants),
    background,
    acrylic,
    shadows,
    brandShadows,
    components,
    density,
    typeface,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('id', id));
    properties.add(EnumProperty<Brightness>('brightness', brightness));
    properties.add(ColorProperty('brand', brand(80)));
    properties.add(ColorProperty('background', background));
    properties.add(
      DiagnosticsProperty<Fluent2AcrylicRecipe>('acrylic', acrylic),
    );
    properties.add(
      DiagnosticsProperty<Fluent2ComponentThemes>(
        'components',
        components,
        defaultValue: const Fluent2ComponentThemes(),
      ),
    );
    properties.add(
      DiagnosticsProperty<Fluent2Density>(
        'density',
        density,
        defaultValue: Fluent2Density.standard,
      ),
    );
    properties.add(
      DiagnosticsProperty<Fluent2Typeface>(
        'typeface',
        typeface,
        defaultValue: Fluent2Typeface.look,
      ),
    );
  }

  /// The WCAG contrast ratio of [ink] on [ground], 1..21, as it is seen:
  /// a translucent ink is laid over the ground first. [ground] is opaque.
  static double contrast(Color ink, Color ground) {
    final seen = Color.alphaBlend(ink, ground);
    final la = seen.computeLuminance();
    final lb = ground.computeLuminance();
    return la > lb ? (la + 0.05) / (lb + 0.05) : (lb + 0.05) / (la + 0.05);
  }
}

class _Fluent2Scope extends InheritedTheme {
  const _Fluent2Scope({
    required this.data,
    required this.dark,
    required super.child,
  });

  final Fluent2ThemeData data;
  final Fluent2ThemeData dark;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      _Fluent2Scope(data: data, dark: dark, child: child);

  @override
  bool updateShouldNotify(_Fluent2Scope oldWidget) =>
      data != oldWidget.data || dark != oldWidget.dark;
}

/// Puts Fluent 2 in scope for everything under it, as Material's `Theme`
/// does. It is the whole install: put one in any app's `builder:`, under a
/// `MaterialApp`, a `CupertinoApp` or a `WidgetsApp`, and every look
/// installs the same way (`<Look>Theme(data: <Look>ThemeData.preset(...))`).
/// Under it, Flutter's own text field reads Fluent's caret, selection and
/// handles, with no ink, splash or highlight; the default text style is
/// Fluent's `body1` and the default icon its first ink at 20.
///
/// An `InheritedTheme`, so what a route or an overlay captures keeps the
/// Fluent 2 it was raised in. A nested one restyles a part of the tree.
/// `Fluent2Host` puts one at the root and paints the page's ground.
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => Fluent2Theme(
///     data: Fluent2ThemeData.preset(
///       'lapis',
///       MediaQuery.platformBrightnessOf(context),
///     ),
///     child: child!,
///   ),
///   home: const InboxPage(),
/// )
/// ```
class Fluent2Theme extends StatelessWidget {
  /// Scopes [data] over [child]; [darkData] is the theme a media ground (chrome
  /// over a full-bleed photograph or video) draws in.
  const Fluent2Theme({
    super.key,
    required this.data,
    this.darkData,
    required this.child,
  });

  /// The theme for what is under it.
  final Fluent2ThemeData data;

  /// The dark theme of the same preset, for a media ground; null is [data]
  /// when it is dark, else the dark of [data]'s preset (the default
  /// preset's when [data] was not built from one).
  final Fluent2ThemeData? darkData;

  /// What it styles.
  final Widget child;

  /// The theme in scope at [context]: the nearest [Fluent2Theme]. Throws when
  /// there is none. `context.fluent2Theme` is the same.
  static Fluent2ThemeData of(BuildContext context) => _of(context).data;

  /// The theme in scope at [context], or null.
  static Fluent2ThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Fluent2Scope>()?.data;

  /// The dark theme of the preset in scope at [context]: what a media
  /// ground draws its chrome in.
  static Fluent2ThemeData darkOf(BuildContext context) => _of(context).dark;

  /// [Fluent2ThemeData.preset]: an app's theme file names its preset here.
  static Fluent2ThemeData preset(String id, Brightness brightness) =>
      Fluent2ThemeData.preset(id, brightness);

  static _Fluent2Scope _of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_Fluent2Scope>();
    if (scope == null) {
      throw FlutterError.fromParts([
        ErrorSummary('No Fluent2Theme above this widget.'),
        ErrorHint(
          "Put a Fluent2Theme (or a Fluent2Host) in the app's builder, above "
          'the navigator.',
        ),
      ]);
    }
    return scope;
  }

  static Fluent2ThemeData _darkFor(Fluent2ThemeData data) {
    if (data.isDark) return data;
    final id = Fluent2ThemeData.presets.contains(data.id)
        ? data.id
        : Fluent2ThemeData.presets.first;
    return Fluent2ThemeData.preset(id, Brightness.dark);
  }

  @override
  Widget build(BuildContext context) {
    Widget under = child;
    // Flutter's text field under a CupertinoApp or a WidgetsApp still asks
    // for Material's words. The override brings its locale's direction with
    // it; the app's own stands, so a right-to-left app stays right to left.
    final direction = Directionality.maybeOf(context);
    if (Localizations.maybeLocaleOf(context) != null &&
        Localizations.of<MaterialLocalizations>(
              context,
              MaterialLocalizations,
            ) ==
            null) {
      under = Localizations.override(
        context: context,
        delegates: const [DefaultMaterialLocalizations.delegate],
        child: direction == null
            ? under
            : Directionality(textDirection: direction, child: under),
      );
    }
    final platform = PreviewFrame.targetPlatformOf(context);
    return _Fluent2Scope(
      data: data,
      dark: darkData ?? _darkFor(data),
      child: Theme(
        data: _materialThemeFor(data, platform),
        child: DefaultTextStyle(
          style: data.body1,
          child: IconTheme(
            data: IconThemeData(color: data.textPrimary, size: 20),
            child: under,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Fluent2ThemeData>('data', data));
  }
}

/// Animates to a new [data] over [duration] (200 ms, as Material's
/// `AnimatedTheme`): the colours and the density blend through
/// [Fluent2ThemeData.lerp].
///
/// ```dart
/// AnimatedFluent2Theme(
///   data: Fluent2ThemeData.lapis(dark ? Brightness.dark : Brightness.light),
///   child: page,
/// )
/// ```
class AnimatedFluent2Theme extends ImplicitlyAnimatedWidget {
  /// Animates [child]'s theme to [data].
  const AnimatedFluent2Theme({
    super.key,
    required this.data,
    this.darkData,
    required this.child,
    super.curve,
    super.duration = const Duration(milliseconds: 200),
    super.onEnd,
  });

  /// The theme to arrive at.
  final Fluent2ThemeData data;

  /// The media ground's theme, as [Fluent2Theme.dark]; not animated.
  final Fluent2ThemeData? darkData;

  /// What it styles.
  final Widget child;

  @override
  AnimatedWidgetBaseState<AnimatedFluent2Theme> createState() =>
      _AnimatedFluent2ThemeState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Fluent2ThemeData>('data', data));
  }
}

class _AnimatedFluent2ThemeState
    extends AnimatedWidgetBaseState<AnimatedFluent2Theme> {
  Fluent2ThemeDataTween? _data;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _data = visitor(
      _data,
      widget.data,
      (value) => Fluent2ThemeDataTween(begin: value as Fluent2ThemeData),
    ) as Fluent2ThemeDataTween?;
  }

  @override
  Widget build(BuildContext context) => Fluent2Theme(
    data: _data!.evaluate(animation),
    darkData: widget.darkData,
    child: widget.child,
  );
}

/// A tween between two Fluent 2 themes, through [Fluent2ThemeData.lerp].
class Fluent2ThemeDataTween extends Tween<Fluent2ThemeData> {
  /// From [begin] to [end].
  Fluent2ThemeDataTween({super.begin, super.end});

  @override
  Fluent2ThemeData lerp(double t) => begin!.lerp(end, t);
}

/// The Material theme per Fluent 2 theme and platform, built once: a host
/// runs again on every navigation (the router's builder). The presets are
/// one instance per id and appearance, so this stays small.
final Map<TargetPlatform, Expando<ThemeData>> _materialThemes = {
  for (final p in TargetPlatform.values) p: Expando<ThemeData>('fluent2'),
};

ThemeData _materialThemeFor(Fluent2ThemeData t, TargetPlatform platform) =>
    _materialThemes[platform]![t] ??= _fluent2MaterialTheme(t, platform);

/// The thin Material `ThemeData` the platform primitives under a
/// [Fluent2Theme] still read: a `Scaffold`'s ground, a `TextField`'s
/// selection tint and cursor, a sheet's route. No token lives here; Fluent 2
/// components read [Fluent2ThemeData] through `context.fluent2Theme`.
/// Private: an app never sees a Material type in Fluent 2's API.
ThemeData _fluent2MaterialTheme(Fluent2ThemeData t, TargetPlatform platform) =>
    ThemeData(
      useMaterial3: true,
      brightness: t.brightness,
      platform: platform,
      // Material's own density (compact on a desktop) would move a
      // decorated field's words; Fluent 2's density is its own setting.
      visualDensity: VisualDensity.standard,
      fontFamily: t.typeface.family,
      package: t.typeface.package,
      scaffoldBackgroundColor: t.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: const Color(0x00000000),
      hoverColor: const Color(0x00000000),
      focusColor: const Color(0x00000000),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      colorScheme: ColorScheme(
        brightness: t.brightness,
        primary: t.accent,
        onPrimary: t.onAccent,
        secondary: t.surfaceInverse,
        onSecondary: t.textInverse,
        error: t.danger,
        onError: t.onDanger,
        surface: t.surface,
        onSurface: t.textPrimary,
        outline: t.borderStrong,
        outlineVariant: t.border,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: t.textPrimary,
        selectionColor: t.colors.brandBackground2Pressed.withValues(alpha: 0.6),
        selectionHandleColor: t.accent,
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1),
    );

/// `context.fluent2Theme`: the theme in scope.
extension Fluent2ThemeContext on BuildContext {
  /// The Fluent 2 theme in scope: `Fluent2Theme.of(this)`, as in
  /// `context.fluent2Theme.colors.neutralBackground1`.
  Fluent2ThemeData get fluent2Theme => Fluent2Theme.of(this);
}

/// Steps along Fluent's type ramp that stay on it.
extension Fluent2TextStyle on TextStyle {
  /// Recolour a ramp step: `t.body1.c(t.textSecondary)`.
  TextStyle c(Color color) => copyWith(color: color);

  /// The regular cut (400).
  TextStyle get regular => copyWith(fontWeight: FontWeight.w400);

  /// The strong cut (Fluent's semibold, 600).
  TextStyle get strong => copyWith(fontWeight: FontWeight.w600);

  /// The stronger cut (Fluent's bold, 700).
  TextStyle get stronger => copyWith(fontWeight: FontWeight.w700);

  /// Figures of one width (Selawik's digits are already tabular; the
  /// feature is set so a fallback face lines up too).
  TextStyle get tabular =>
      copyWith(fontFeatures: const [FontFeature.tabularFigures()]);

  /// Set on a line [px] tall: `t.caption1.line(20)`.
  TextStyle line(double px) => copyWith(height: px / fontSize!);
}
