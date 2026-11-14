/// Expressive's theme: [ExpressiveThemeData] for one theme in one
/// brightness — its record and every foundation — built from the generated
/// baked themes; the [ExpressiveTheme] a host mounts it on (and
/// [AnimatedExpressiveTheme], which springs between two); and
/// `context.expressiveTheme` ([ExpressiveThemeContext]). Owner: w1-host
/// (the final composition), with `test/theme_test.dart`.
///
/// Themes are data (wave decision D6): `themes/<id>/theme.json` in the
/// module, baked by `tools/expressive_tokens` into
/// `internal/themes/<id>.g.dart` and listed by `internal/themes/registry.g.dart`
/// in module.yaml's preset order. `baseline` is exactly what Compose's
/// `MaterialExpressiveTheme` paints by default — light
/// `expressiveLightColorScheme()`, dark `ColorDarkTokens` (CONTRACT §6) —
/// the gallery default and the oracle's reference.
///
/// An app may bake themes of its own: the same `theme.json`, baked by the
/// same tool into the app's generated code as [ExpressiveThemeSpec] consts,
/// the public form of a baked theme. [ExpressiveThemeData.fromBaked] builds
/// one, and [ExpressiveThemeData.forApp] finds a theme by id among the
/// app's themes first, then the system's presets. An app that owns themes
/// may also bake its pictures' colours (`ExpressiveArtwork`): a page a
/// picture heads wears the theme retinted by it.
///
/// Every foundation is reachable from the theme, so a component reads
/// everything it paints with from `context.expressiveTheme`:
///
/// | Member | Foundation | File |
/// | --- | --- | --- |
/// | `colors` | the colour roles | `color.dart` |
/// | `type` | the 30-style type scale | `type.dart` |
/// | `shapes` | the corner scale (library shapes: `shape.dart`) | `shape.dart` |
/// | `motion` | the motion scheme and its springs | `motion.dart` |
/// | `states` | the state-layer opacities | `states.dart` |
/// | `elevation` | tonal and shadow elevation | `elevation.dart` |
///
/// The fixed scales need no theme: `ExpressiveSpacing` (`spacing.dart`),
/// `ExpressiveSymbolsFont` / `ExpressiveSymbols` (`icons.dart`) and the
/// generated component tokens a component reads through its foundation
/// (a colour role through `colors.role`, a shape key through `shapes.of`,
/// a type key through `type.of`, a motion key through `ExpressiveMotion.of`,
/// an elevation level through `elevation`).
library;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart'
    show
        ColorScheme,
        DefaultMaterialLocalizations,
        MaterialLocalizations,
        TextSelectionTheme,
        TextSelectionThemeData;
import 'package:flutter/widgets.dart';

import 'color.dart';
import 'component_themes.dart';
import 'elevation.dart';
import 'internal/density.dart';
import 'internal/themes/baked_theme.dart';
import 'internal/themes/registry.g.dart';
import 'internal/tokens/behavior.g.dart';
import 'internal/tokens/state_tokens.g.dart';
import 'motion.dart';
import 'shape.dart';
import 'type.dart';

export 'internal/density.dart' show ExpressiveDensity;

/// No colour at all: Compose's `Color.Transparent`, the ground of a
/// container that draws nothing of its own (a state layer's resting
/// colour, a row with no fill).
const Color expressiveTransparent = Color(0x00000000);

/// The motion scheme a theme runs (CONTRACT §2, "Motion").
enum ExpressiveMotionScheme {
  /// Springs that overshoot: Material's default, and every hero moment's.
  expressive,

  /// Nearly critically damped spatial springs (ζ = 0.9), for utilitarian
  /// products (Utilities, Finance, Business). A standard app never bounces.
  standard,
}

/// Compose's `StateTokens` as a theme applies them:
/// `context.expressiveTheme.states`.
@immutable
class ExpressiveStateLayers {
  /// State layers of the given opacities.
  const ExpressiveStateLayers({
    required this.hoverOpacity,
    required this.focusOpacity,
    required this.pressedOpacity,
    required this.draggedOpacity,
  });

  /// The generated `StateTokens`.
  static const ExpressiveStateLayers tokens = ExpressiveStateLayers(
    hoverOpacity: StateTokens.hoverStateLayerOpacity,
    focusOpacity: StateTokens.focusStateLayerOpacity,
    pressedOpacity: StateTokens.pressedStateLayerOpacity,
    draggedOpacity: StateTokens.draggedStateLayerOpacity,
  );

  /// md.sys.state.hover.state-layer-opacity.
  final double hoverOpacity;

  /// md.sys.state.focus.state-layer-opacity.
  final double focusOpacity;

  /// md.sys.state.pressed.state-layer-opacity: the ripple's.
  final double pressedOpacity;

  /// md.sys.state.dragged.state-layer-opacity.
  final double draggedOpacity;

  /// The overlay opacity [states] show: none when disabled, else the
  /// strongest interaction (pressed, dragged, focused, hovered). Compose
  /// shows the most recent interaction; the strongest is the one a user
  /// just started in every case but a hover arriving over a focused
  /// control, where the two differ by 0.02.
  double opacityOf(Set<WidgetState> states) {
    if (states.contains(WidgetState.disabled)) return 0;
    if (states.contains(WidgetState.pressed)) return pressedOpacity;
    if (states.contains(WidgetState.dragged)) return draggedOpacity;
    if (states.contains(WidgetState.focused)) return focusOpacity;
    if (states.contains(WidgetState.hovered)) return hoverOpacity;
    return 0;
  }

  /// [content] at the overlay opacity [states] show; null when none.
  Color? layerOf(Color content, Set<WidgetState> states) {
    final opacity = opacityOf(states);
    return opacity == 0 ? null : content.withValues(alpha: opacity);
  }

  /// [container] with [states]' overlay of [content] composited over it:
  /// what a state-layered container looks like as one colour.
  Color composite(Color container, Color content, Set<WidgetState> states) {
    final layer = layerOf(content, states);
    return layer == null ? container : Color.alphaBlend(layer, container);
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveStateLayers &&
      other.hoverOpacity == hoverOpacity &&
      other.focusOpacity == focusOpacity &&
      other.pressedOpacity == pressedOpacity &&
      other.draggedOpacity == draggedOpacity;

  @override
  int get hashCode =>
      Object.hash(hoverOpacity, focusOpacity, pressedOpacity, draggedOpacity);
}

/// Material's window size classes by the width a layout is given: compact
/// under 600dp, medium under 840, expanded under 1200, large under 1600,
/// extra-large from there (the `WindowSizeClass` breakpoints of Compose's
/// adaptive library, `androidx.window` 1.4). Every Expressive layout that
/// changes with width reads them here — the shell's rail, the table's
/// stacking — so a page and its parts agree on where a phone ends.
enum ExpressiveWindowSizeClass {
  /// Under 600dp: a phone held upright.
  compact(0),

  /// 600 to 840dp: a phone held across, a small tablet, a foldable open.
  medium(600),

  /// 840 to 1200dp: a tablet, a small desktop window.
  expanded(840),

  /// 1200 to 1600dp: a desktop window.
  large(1200),

  /// 1600dp and over: a wide desktop window.
  extraLarge(1600);

  const ExpressiveWindowSizeClass(this.minWidth);

  /// The least width of the class, in dp.
  final double minWidth;

  /// The class of a layout [width] wide.
  static ExpressiveWindowSizeClass ofWidth(double width) =>
      values.lastWhere((c) => width >= c.minWidth);

  /// The class of the window at [context].
  static ExpressiveWindowSizeClass of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);
}

/// The expression budget: how many hero moments an app may spend
/// (CONTRACT §3), at most one per page.
enum ExpressiveExpression {
  /// No hero moments.
  calm,

  /// One hero moment per app: the default.
  balanced,

  /// Two hero moments per app.
  bold,
}

/// One theme as baked, in public form: what an app's generated themes hold.
///
/// `tools/expressive_tokens` bakes each of an app's `theme.json` files into
/// one const, as it bakes the system's presets: the record ([seed],
/// [variant], [contrast], [motion], [expression]) and every colour role,
/// light and dark, by [ExpressiveColorRole] name as ARGB. A spec varies
/// what `theme.json` varies and nothing else: it wears the system's one
/// type scale and Compose's default corner scale, as every preset does.
///
/// [ExpressiveThemeData.fromBaked] builds a theme from one, and
/// [ExpressiveThemeData.forApp] looks one up by [id].
@immutable
class ExpressiveThemeSpec {
  /// A theme spec of the given record.
  const ExpressiveThemeSpec({
    required this.id,
    required this.seed,
    required this.variant,
    required this.contrast,
    required this.motion,
    required this.expression,
    required this.light,
    required this.dark,
    this.statusLight = const <String, int>{},
    this.statusDark = const <String, int>{},
  });

  /// The theme's id: its `themes/<id>/` directory, a lower-case slug.
  final String id;

  /// The seed colour, ARGB.
  final int seed;

  /// The dynamic-scheme variant: `tonalSpot`, `neutral`, `vibrant` or
  /// `expressive`.
  final String variant;

  /// The contrast level the colours were baked at: 0, 0.5 or 1.
  final double contrast;

  /// The motion scheme.
  final ExpressiveMotionScheme motion;

  /// The expression budget.
  final ExpressiveExpression expression;

  /// Every colour role in light, by [ExpressiveColorRole] name, as ARGB.
  final Map<String, int> light;

  /// Every colour role in dark. Baked, never an inversion of [light].
  final Map<String, int> dark;

  /// The status tones in light, by name (`success`, `onSuccess`,
  /// `successContainer`, `onSuccessContainer`, and the same for
  /// `warning`), as ARGB: [ExpressiveThemeData.status]. Empty for a spec
  /// baked without them, which then wears the default preset's.
  final Map<String, int> statusLight;

  /// The status tones in dark. Baked, never an inversion of [statusLight].
  final Map<String, int> statusDark;
}

/// One custom colour of an app, baked in one theme and brightness: a
/// colour group as Material's custom colours have it, [color] with the
/// content on it, and a [container] with the content on that.
///
/// `tools/expressive_tokens` bakes one per colour an app declares in its
/// module.yaml (`theming.customColors`) for each of its themes, light and
/// dark: the colour harmonised toward the theme's seed, then read through
/// the theme's own 2025 scheme at its contrast, and held to the contrast
/// floors (content 4.5:1, the colour against its container and the surface
/// 3:1; all 7:1 at contrast 1). An app reads them through its generated
/// [ExpressiveCustomColors].
@immutable
class ExpressiveCustomColor {
  /// A custom colour with its on-colour, container and on-container.
  const ExpressiveCustomColor({
    required this._color,
    required this._onColor,
    required this._container,
    required this._onContainer,
    this.label,
  });

  final int _color;
  final int _onColor;
  final int _container;
  final int _onContainer;

  /// The colour itself: a mark, such as a status dot.
  Color get color => Color(_color);

  /// Content on [color].
  Color get onColor => Color(_onColor);

  /// The colour's container: a status's fill.
  Color get container => Color(_container);

  /// Content on [container]: a status's label.
  Color get onContainer => Color(_onContainer);

  /// The name the colour goes by in this theme (module.yaml's `label`, or
  /// the theme's own), which a screen reader, a swatch or a filter chip
  /// says beside it: a colour is never the only signal. Null when the app
  /// names it by meaning elsewhere.
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveCustomColor &&
      other._color == _color &&
      other._onColor == _onColor &&
      other._container == _container &&
      other._onContainer == _onContainer &&
      other.label == label;

  @override
  int get hashCode =>
      Object.hash(_color, _onColor, _container, _onContainer, label);
}

/// One theme's custom colours, light and dark, by name.
@immutable
class ExpressiveCustomColorSet {
  /// A set of custom colours for [light] and [dark].
  const ExpressiveCustomColorSet({required this.light, required this.dark});

  /// Every custom colour in light.
  final Map<String, ExpressiveCustomColor> light;

  /// Every custom colour in dark. Baked, never an inversion of [light].
  final Map<String, ExpressiveCustomColor> dark;

  /// The colours in [brightness].
  Map<String, ExpressiveCustomColor> of(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}

/// An app's custom colours: the table `tools/expressive_tokens` generates
/// beside its themes (`lib/app/themes.g.dart`, `appCustomColors`), each of
/// its own themes' colours, the default theme first.
@immutable
class ExpressiveCustomColors {
  /// Custom colours with the given [names] and [themes].
  const ExpressiveCustomColors({required this.names, required this.themes});

  /// Every colour's name, in the order the app declares them.
  final List<String> names;

  /// Each of the app's own themes' colours, by theme id, the default first.
  final Map<String, ExpressiveCustomColorSet> themes;

  /// [name] in [theme]: baked for that app theme in its brightness. A
  /// system preset (the gate's robustness look) wears the default theme's.
  /// Throws an [ArgumentError] for a name the app does not declare.
  ExpressiveCustomColor of(String name, ExpressiveThemeData theme) {
    if (!names.contains(name)) {
      throw ArgumentError.value(
        name,
        'name',
        'No custom colour; the app has '
            '${names.isEmpty ? 'none' : names.join(', ')}',
      );
    }
    final set = themes[theme.id] ?? themes.values.first;
    return set.of(theme.brightness)[name]!;
  }
}

/// [baked]'s status tones in [brightness], or null when it has none.
ExpressiveStatusColors? _resolveStatus(
  ExpressiveBakedTheme baked,
  Brightness brightness,
) => ExpressiveStatusColors.fromMap(
  brightness == Brightness.dark
      ? baked.colors.statusDark
      : baked.colors.statusLight,
);

/// A theme's status tones: success and warning as Material's custom
/// colours, each a colour group ([ExpressiveCustomColor]). Never colour
/// roles (contract §7): `tools/expressive_tokens` bakes them for every
/// preset and every app theme, light and dark, from Material's green 800
/// (#2E7D32) and amber 600 (#FFB300) harmonised toward the theme's seed,
/// held to the custom-colour floors (content 4.5:1; the colour against its
/// container and the surface 3:1; all 7:1 at contrast 1). A banner, a tag
/// and the kit parts' notices read them.
@immutable
class ExpressiveStatusColors {
  /// Status tones of the given groups.
  const ExpressiveStatusColors({required this.success, required this.warning});

  /// [light] or [dark] (`BakedColors.statusLight`), by name; null when the
  /// map holds none.
  static ExpressiveStatusColors? fromMap(Map<String, int> tones) {
    if (tones.isEmpty) return null;
    ExpressiveCustomColor group(String name) {
      final cap = '${name[0].toUpperCase()}${name.substring(1)}';
      int of(String key) =>
          tones[key] ?? (throw StateError('The status tones carry no "$key".'));
      return ExpressiveCustomColor(
        color: of(name),
        onColor: of('on$cap'),
        container: of('${name}Container'),
        onContainer: of('on${cap}Container'),
      );
    }

    return ExpressiveStatusColors(
      success: group('success'),
      warning: group('warning'),
    );
  }

  /// What went well: a saved change, a passed check.
  final ExpressiveCustomColor success;

  /// What needs a look before it fails: a low balance, an expiring card.
  final ExpressiveCustomColor warning;

  /// [a] and [b] interpolated at [t], colour by colour.
  static ExpressiveStatusColors lerp(
    ExpressiveStatusColors a,
    ExpressiveStatusColors b,
    double t,
  ) {
    if (identical(a, b)) return a;
    ExpressiveCustomColor group(
      ExpressiveCustomColor x,
      ExpressiveCustomColor y,
    ) {
      int mix(Color p, Color q) => Color.lerp(p, q, t)!.toARGB32();
      return ExpressiveCustomColor(
        color: mix(x.color, y.color),
        onColor: mix(x.onColor, y.onColor),
        container: mix(x.container, y.container),
        onContainer: mix(x.onContainer, y.onContainer),
      );
    }

    return ExpressiveStatusColors(
      success: group(a.success, b.success),
      warning: group(a.warning, b.warning),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveStatusColors &&
      other.success == success &&
      other.warning == warning;

  @override
  int get hashCode => Object.hash(success, warning);
}

/// One Expressive theme in one brightness: what every component reads
/// through `context.expressiveTheme`, as Material's components read
/// `ThemeData`.
///
/// Build one with [preset] or a preset's own factory
/// ([ExpressiveThemeData.baseline], [ExpressiveThemeData.slate], ...), or
/// an app's with [forApp]; mount it with [ExpressiveTheme], the one root
/// widget, in any app's `builder:`:
///
/// ```dart
/// WidgetsApp(
///   color: const Color(0xFF6750A4),
///   builder: (context, child) => ExpressiveTheme(
///     data: ExpressiveThemeData.preset(
///       'baseline',
///       MediaQuery.platformBrightnessOf(context),
///     ),
///     child: child!,
///   ),
/// )
/// ```
@immutable
class ExpressiveThemeData with Diagnosticable {
  /// A theme from its parts. Prefer [preset] or [forApp]: a theme's colours
  /// are baked from its record, never typed.
  const ExpressiveThemeData({
    required this.id,
    required this.brightness,
    required this.expression,
    required this.colors,
    required this.type,
    required this.shapes,
    required this.motion,
    this.buttonTheme = const ExpressiveComponentThemeData(),
    this.iconButtonTheme = const ExpressiveComponentThemeData(),
    this.segmentedButtonTheme = const ExpressiveComponentThemeData(),
    this.chipTheme = const ExpressiveComponentThemeData(),
    this.listTileTheme = const ExpressiveComponentThemeData(),
    this.appBarTheme = const ExpressiveComponentThemeData(),
    this.menuTheme = const ExpressiveComponentThemeData(),
    this.snackBarTheme = const ExpressiveComponentThemeData(),
    this.dialogTheme = const ExpressiveComponentThemeData(),
    this.textFieldTheme = const ExpressiveComponentThemeData(),
    this.cardTheme = const ExpressiveComponentThemeData(),
    this.floatingActionButtonTheme = const ExpressiveComponentThemeData(),
    this.splitButtonTheme = const ExpressiveComponentThemeData(),
    this.checkboxTheme = const ExpressiveComponentThemeData(),
    this.radioTheme = const ExpressiveComponentThemeData(),
    this.switchTheme = const ExpressiveComponentThemeData(),
    this.sliderTheme = const ExpressiveComponentThemeData(),
    this.numberFieldTheme = const ExpressiveComponentThemeData(),
    this.inputOtpTheme = const ExpressiveComponentThemeData(),
    this.selectTheme = const ExpressiveComponentThemeData(),
    this.searchTheme = const ExpressiveComponentThemeData(),
    this.tooltipTheme = const ExpressiveComponentThemeData(),
    this.popoverTheme = const ExpressiveComponentThemeData(),
    this.bottomSheetTheme = const ExpressiveComponentThemeData(),
    this.datePickerTheme = const ExpressiveComponentThemeData(),
    this.timePickerTheme = const ExpressiveComponentThemeData(),
    this.badgeTheme = const ExpressiveComponentThemeData(),
    this.avatarTheme = const ExpressiveComponentThemeData(),
    this.optionTheme = const ExpressiveComponentThemeData(),
    this.messageBubbleTheme = const ExpressiveComponentThemeData(),
    this.bannerTheme = const ExpressiveComponentThemeData(),
    this.toolbarTheme = const ExpressiveComponentThemeData(),
    this.tabTheme = const ExpressiveComponentThemeData(),
    this.tabBarTheme = const ExpressiveComponentThemeData(),
    this.navigationItemTheme = const ExpressiveComponentThemeData(),
    this.navigationRailTheme = const ExpressiveComponentThemeData(),
    this.navigationBarTheme = const ExpressiveComponentThemeData(),
    this.ratingTheme = const ExpressiveComponentThemeData(),
    this.tableTheme = const ExpressiveComponentThemeData(),
    this.chartTheme = const ExpressiveComponentThemeData(),
    this.pageDotsTheme = const ExpressiveComponentThemeData(),
    this.carouselTheme = const ExpressiveComponentThemeData(),
    this.stepProgressTheme = const ExpressiveComponentThemeData(),
    this.meterTheme = const ExpressiveComponentThemeData(),
    this.progressIndicatorTheme = const ExpressiveComponentThemeData(),
    this.imageTheme = const ExpressiveComponentThemeData(),
    this.skeletonTheme = const ExpressiveComponentThemeData(),
    this.statusViewTheme = const ExpressiveComponentThemeData(),
    this.loadingIndicatorTheme = const ExpressiveComponentThemeData(),
    this._density,
    this._status,
  });

  /// Derives a palette from an app's seed using Material's tonal colour algorithm.
  ///
  /// High contrast leaves room for Material's interaction state layers as well as
  /// text and boundary contrast floors.
  /// Presets retain their pinned Compose palettes; this factory makes a new app palette.
  ///
  /// ```dart
  /// final theme = ExpressiveThemeData.from(seed: Color(0xff00695c));
  /// ```
  factory ExpressiveThemeData.from({
    required Color seed,
    Brightness brightness = Brightness.light,
  }) {
    final palette = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
      contrastLevel: 1,
    );
    final colors = ExpressiveColorScheme.fromRoles(
      (role) => switch (role) {
        ExpressiveColorRole.background => palette.surface,
        ExpressiveColorRole.error => palette.error,
        ExpressiveColorRole.errorContainer => palette.errorContainer,
        ExpressiveColorRole.inverseOnSurface => palette.onInverseSurface,
        ExpressiveColorRole.inversePrimary => palette.inversePrimary,
        ExpressiveColorRole.inverseSurface => palette.inverseSurface,
        ExpressiveColorRole.onBackground => palette.onSurface,
        ExpressiveColorRole.onError => palette.onError,
        ExpressiveColorRole.onErrorContainer => palette.onErrorContainer,
        ExpressiveColorRole.onPrimary => palette.onPrimary,
        ExpressiveColorRole.onPrimaryContainer => palette.onPrimaryContainer,
        ExpressiveColorRole.onPrimaryFixed => palette.onPrimaryFixed,
        ExpressiveColorRole.onPrimaryFixedVariant =>
          palette.onPrimaryFixedVariant,
        ExpressiveColorRole.onSecondary => palette.onSecondary,
        ExpressiveColorRole.onSecondaryContainer =>
          palette.onSecondaryContainer,
        ExpressiveColorRole.onSecondaryFixed => palette.onSecondaryFixed,
        ExpressiveColorRole.onSecondaryFixedVariant =>
          palette.onSecondaryFixedVariant,
        ExpressiveColorRole.onSurface => palette.onSurface,
        ExpressiveColorRole.onSurfaceVariant => palette.onSurfaceVariant,
        ExpressiveColorRole.onTertiary => palette.onTertiary,
        ExpressiveColorRole.onTertiaryContainer => palette.onTertiaryContainer,
        ExpressiveColorRole.onTertiaryFixed => palette.onTertiaryFixed,
        ExpressiveColorRole.onTertiaryFixedVariant =>
          palette.onTertiaryFixedVariant,
        ExpressiveColorRole.outline => palette.outline,
        ExpressiveColorRole.outlineVariant => palette.outlineVariant,
        ExpressiveColorRole.primary => palette.primary,
        ExpressiveColorRole.primaryContainer => palette.primaryContainer,
        ExpressiveColorRole.primaryFixed => palette.primaryFixed,
        ExpressiveColorRole.primaryFixedDim => palette.primaryFixedDim,
        ExpressiveColorRole.scrim => palette.scrim,
        ExpressiveColorRole.secondary => palette.secondary,
        ExpressiveColorRole.secondaryContainer => palette.secondaryContainer,
        ExpressiveColorRole.secondaryFixed => palette.secondaryFixed,
        ExpressiveColorRole.secondaryFixedDim => palette.secondaryFixedDim,
        ExpressiveColorRole.surface => palette.surface,
        ExpressiveColorRole.surfaceBright => palette.surfaceBright,
        ExpressiveColorRole.surfaceContainer => palette.surfaceContainer,
        ExpressiveColorRole.surfaceContainerHigh =>
          palette.surfaceContainerHigh,
        ExpressiveColorRole.surfaceContainerHighest =>
          palette.surfaceContainerHighest,
        ExpressiveColorRole.surfaceContainerLow => palette.surfaceContainerLow,
        ExpressiveColorRole.surfaceContainerLowest =>
          palette.surfaceContainerLowest,
        ExpressiveColorRole.surfaceDim => palette.surfaceDim,
        ExpressiveColorRole.surfaceTint => palette.surfaceTint,
        ExpressiveColorRole.surfaceVariant => palette.surfaceContainerHighest,
        ExpressiveColorRole.tertiary => palette.tertiary,
        ExpressiveColorRole.tertiaryContainer => palette.tertiaryContainer,
        ExpressiveColorRole.tertiaryFixed => palette.tertiaryFixed,
        ExpressiveColorRole.tertiaryFixedDim => palette.tertiaryFixedDim,
      },
      shadow: palette.shadow,
    );
    return ExpressiveThemeData.preset(
      expressiveDefaultThemeId,
      brightness,
    ).copyWith(colors: colors);
  }

  /// [spec], an app's baked theme, in [brightness]. Throws an
  /// [ArgumentError] for a record `theme.json` would refuse, and a
  /// [StateError] unless its colours carry exactly the
  /// [ExpressiveColorRole]s.
  factory ExpressiveThemeData.fromBaked(
    ExpressiveThemeSpec spec,
    Brightness brightness,
  ) => _fromBaked(_bake(spec), brightness);

  /// The theme [id] in [brightness] for an app whose own baked themes are
  /// [appThemes]: the app theme of that id, else the system preset. Throws
  /// an [ArgumentError] for an id neither has, and when two app themes
  /// share an id.
  static ExpressiveThemeData forApp(
    String id,
    List<ExpressiveThemeSpec> appThemes,
    Brightness brightness,
  ) {
    final ids = <String>{};
    for (final spec in appThemes) {
      if (!ids.add(spec.id)) {
        throw ArgumentError.value(
          spec.id,
          'appThemes',
          'Two app themes are named "${spec.id}"',
        );
      }
    }
    for (final spec in appThemes) {
      if (spec.id == id) return ExpressiveThemeData.fromBaked(spec, brightness);
    }
    final baked = expressiveBakedThemes[id];
    if (baked == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Neither the app nor Expressive has a theme "$id"; the app has '
            '${ids.isEmpty ? 'none' : ids.join(', ')} and Expressive has '
            '${presets.join(', ')}',
      );
    }
    return _fromBaked(baked, brightness);
  }

  /// `baseline`: Compose's own default scheme, what `MaterialExpressiveTheme`
  /// paints unthemed (seed #6750A4, tonal spot, Expressive motion,
  /// balanced). The default preset.
  factory ExpressiveThemeData.baseline([
    Brightness brightness = Brightness.light,
  ]) => preset('baseline', brightness);

  /// `slate`: a blue-grey seed (#52667A), neutral, Standard motion, calm.
  factory ExpressiveThemeData.slate([
    Brightness brightness = Brightness.light,
  ]) => preset('slate', brightness);

  /// `bloom`: an orchid rose seed (#B5487A), vibrant, Expressive motion,
  /// bold.
  factory ExpressiveThemeData.bloom([
    Brightness brightness = Brightness.light,
  ]) => preset('bloom', brightness);

  /// `grove`: a forest green seed (#2E7D5B), tonal spot, Expressive motion,
  /// balanced.
  factory ExpressiveThemeData.grove([
    Brightness brightness = Brightness.light,
  ]) => preset('grove', brightness);

  /// `ember`: a burnt orange seed (#C25A1F), the hue-rotating expressive
  /// variant, Expressive motion, bold.
  factory ExpressiveThemeData.ember([
    Brightness brightness = Brightness.light,
  ]) => preset('ember', brightness);

  /// The theme in force at [context]: the nearest [ExpressiveTheme]'s, else
  /// the default preset in the platform's brightness. The same as
  /// `context.expressiveTheme` and [ExpressiveTheme.of].
  static ExpressiveThemeData of(BuildContext context) =>
      ExpressiveTheme.of(context);

  /// The theme [id] in [brightness], from the generated baked themes.
  /// Throws an [ArgumentError] for an id no theme has.
  static ExpressiveThemeData preset(String id, Brightness brightness) {
    final baked = expressiveBakedThemes[id];
    if (baked == null) {
      throw ArgumentError.value(
        id,
        'id',
        'Expressive has no theme "$id"; it has ${presets.join(', ')}',
      );
    }
    return _fromBaked(baked, brightness);
  }

  /// Every theme id, in module.yaml's preset order: the default first.
  static List<String> get presets =>
      expressiveBakedThemes.keys.toList(growable: false);

  /// The theme a host wears when it is handed none: the gallery default,
  /// module.yaml's first preset. A generated app names its own theme.
  static String get defaultPreset => expressiveDefaultThemeId;

  static final RegExp _themeId = RegExp(r'^[a-z][a-z0-9]*(?:-[a-z0-9]+)*$');

  static const Set<String> _variants = <String>{
    'tonalSpot',
    'neutral',
    'vibrant',
    'expressive',
  };

  static const List<double> _contrasts = <double>[0, 0.5, 1];

  /// [spec] as the internal baked theme the foundations resolve: its
  /// record and colours, the one type scale and Compose's corner scale.
  static ExpressiveBakedTheme _bake(ExpressiveThemeSpec spec) {
    if (!_themeId.hasMatch(spec.id)) {
      throw ArgumentError.value(spec.id, 'spec.id', 'Not a lower-case slug');
    }
    if (!_variants.contains(spec.variant)) {
      throw ArgumentError.value(
        spec.variant,
        'spec.variant',
        'Not one of ${_variants.join(', ')}',
      );
    }
    if (!_contrasts.contains(spec.contrast)) {
      throw ArgumentError.value(
        spec.contrast,
        'spec.contrast',
        'Not one of ${_contrasts.join(', ')}',
      );
    }
    return ExpressiveBakedTheme(
      id: spec.id,
      seed: spec.seed,
      variant: spec.variant,
      contrast: spec.contrast,
      expression: spec.expression.name,
      source: null,
      colors: ExpressiveBakedColors(
        light: spec.light,
        dark: spec.dark,
        statusLight: spec.statusLight,
        statusDark: spec.statusDark,
      ),
      type: const ExpressiveBakedTextTheme(),
      shapes: expressiveComposeDefaultShapes,
      motion: ExpressiveBakedMotion(scheme: spec.motion.name),
    );
  }

  static ExpressiveThemeData _fromBaked(
    ExpressiveBakedTheme baked,
    Brightness brightness,
  ) => ExpressiveThemeData(
    id: baked.id,
    brightness: brightness,
    expression: ExpressiveExpression.values.byName(baked.expression),
    colors: expressiveResolveColors(baked, brightness),
    type: expressiveResolveTextTheme(baked, brightness),
    shapes: expressiveResolveShapes(baked, brightness),
    motion: expressiveResolveMotion(baked, brightness),
    status: _resolveStatus(baked, brightness),
  );

  /// The theme's id: its `themes/<id>/` directory and preset name.
  final String id;

  /// Light or dark. Dark is generated, never an inversion of light.
  final Brightness brightness;

  /// The theme's expression budget.
  final ExpressiveExpression expression;

  /// The colour roles (`color.dart`).
  final ExpressiveColorScheme colors;

  /// The type scale (`type.dart`).
  final ExpressiveTextTheme type;

  /// The shape scale (M3's `extraSmall` to `extraExtraLarge` and `full`),
  /// shared by every part's surface and every token-painted corner: the
  /// one way to an app's corners. A component theme sets one part's shape.
  final ExpressiveShapes shapes;

  final ExpressiveDensity? _density;

  /// Density, in Flutter's steps ([ExpressiveDensity.standard],
  /// `comfortable`, `compact`): unset, it adapts to the platform
  /// ([ExpressiveDensity.adaptivePlatformDensity]), compact where a pointer
  /// is the norm (macOS, Windows, Linux) and standard on touch. Touch
  /// targets keep their accessible minimum at every density.
  ExpressiveDensity get density =>
      _density ?? ExpressiveDensity.adaptivePlatformDensity;

  /// The motion scheme and its springs (`motion.dart`). A component reads
  /// its springs where it runs, with `ExpressiveMotion.of(context)`, which
  /// adds a Standard-pinned subtree and Reduce Motion to this scheme.
  final ExpressiveMotion motion;

  final ExpressiveStatusColors? _status;

  /// The status tones ([ExpressiveStatusColors]): the baked theme's, or the
  /// default preset's in this brightness for a theme built without them.
  ExpressiveStatusColors get status =>
      _status ?? (_defaultStatus[brightness] ??= _bakedStatus(brightness));

  static final Map<Brightness, ExpressiveStatusColors> _defaultStatus =
      <Brightness, ExpressiveStatusColors>{};

  static ExpressiveStatusColors _bakedStatus(Brightness brightness) =>
      _resolveStatus(
        expressiveBakedThemes[expressiveDefaultThemeId]!,
        brightness,
      )!;

  /// The button's.
  final ExpressiveComponentThemeData buttonTheme;

  /// The icon button's.
  final ExpressiveComponentThemeData iconButtonTheme;

  /// A segment's.
  final ExpressiveComponentThemeData segmentedButtonTheme;

  /// A chip's.
  final ExpressiveComponentThemeData chipTheme;

  /// A list row's.
  final ExpressiveComponentThemeData listTileTheme;

  /// The app bar's.
  final ExpressiveComponentThemeData appBarTheme;

  /// A menu's.
  final ExpressiveComponentThemeData menuTheme;

  /// The snackbar's.
  final ExpressiveComponentThemeData snackBarTheme;

  /// The alert dialog's.
  final ExpressiveComponentThemeData dialogTheme;

  /// A text field's.
  final ExpressiveComponentThemeData textFieldTheme;

  /// Visual slots for the card component.
  final ExpressiveComponentThemeData cardTheme;

  /// Visual slots for the fab component.
  final ExpressiveComponentThemeData floatingActionButtonTheme;

  /// Visual slots for the splitButton component.
  final ExpressiveComponentThemeData splitButtonTheme;

  /// Visual slots for the checkbox component.
  final ExpressiveComponentThemeData checkboxTheme;

  /// Visual slots for the radio component.
  final ExpressiveComponentThemeData radioTheme;

  /// Visual slots for the switchControl component.
  final ExpressiveComponentThemeData switchTheme;

  /// Visual slots for the slider component.
  final ExpressiveComponentThemeData sliderTheme;

  /// Visual slots for the quantityStepper component.
  final ExpressiveComponentThemeData numberFieldTheme;

  /// Visual slots for the codeField component.
  final ExpressiveComponentThemeData inputOtpTheme;

  /// Visual slots for the select component.
  final ExpressiveComponentThemeData selectTheme;

  /// Visual slots for the search component.
  final ExpressiveComponentThemeData searchTheme;

  /// Visual slots for the tooltip component.
  final ExpressiveComponentThemeData tooltipTheme;

  /// Visual slots for the popover component.
  final ExpressiveComponentThemeData popoverTheme;

  /// Visual slots for the bottomSheet component.
  final ExpressiveComponentThemeData bottomSheetTheme;

  /// Visual slots for the datePicker component.
  final ExpressiveComponentThemeData datePickerTheme;

  /// Visual slots for the timePicker component.
  final ExpressiveComponentThemeData timePickerTheme;

  /// Visual slots for the badge component.
  final ExpressiveComponentThemeData badgeTheme;

  /// Visual slots for the avatar component.
  final ExpressiveComponentThemeData avatarTheme;

  /// Visual slots for the option component.
  final ExpressiveComponentThemeData optionTheme;

  /// Visual slots for the messageBubble component.
  final ExpressiveComponentThemeData messageBubbleTheme;

  /// Visual slots for the banner component.
  final ExpressiveComponentThemeData bannerTheme;

  /// Visual slots for the toolbar component.
  final ExpressiveComponentThemeData toolbarTheme;

  /// Visual slots for the tab component.
  final ExpressiveComponentThemeData tabTheme;

  /// Visual slots for the tabBar component.
  final ExpressiveComponentThemeData tabBarTheme;

  /// Visual slots for the navigationItem component.
  final ExpressiveComponentThemeData navigationItemTheme;

  /// Visual slots for the navigationRail component.
  final ExpressiveComponentThemeData navigationRailTheme;

  /// Visual slots for the navigationBar component.
  final ExpressiveComponentThemeData navigationBarTheme;

  /// Visual slots for the rating component.
  final ExpressiveComponentThemeData ratingTheme;

  /// Visual slots for the table component.
  final ExpressiveComponentThemeData tableTheme;

  /// Visual slots for chart frames and content.
  final ExpressiveComponentThemeData chartTheme;

  /// Visual slots for the pageDots family.
  final ExpressiveComponentThemeData pageDotsTheme;

  /// Visual slots for the carousel family.
  final ExpressiveComponentThemeData carouselTheme;

  /// Visual slots for the stepProgress family.
  final ExpressiveComponentThemeData stepProgressTheme;

  /// Visual slots for the meter family.
  final ExpressiveComponentThemeData meterTheme;

  /// Visual slots for the progressIndicator family.
  final ExpressiveComponentThemeData progressIndicatorTheme;

  /// Visual slots for the image family.
  final ExpressiveComponentThemeData imageTheme;

  /// Visual slots for the skeleton family.
  final ExpressiveComponentThemeData skeletonTheme;

  /// Visual slots for the screenState family.
  final ExpressiveComponentThemeData statusViewTheme;

  /// Visual slots for the loadingIndicator family.
  final ExpressiveComponentThemeData loadingIndicatorTheme;

  /// Every component theme, in the constructor's order.
  List<ExpressiveComponentThemeData> get _componentThemes =>
      <ExpressiveComponentThemeData>[
        buttonTheme,
        iconButtonTheme,
        segmentedButtonTheme,
        chipTheme,
        listTileTheme,
        appBarTheme,
        menuTheme,
        snackBarTheme,
        dialogTheme,
        textFieldTheme,
        cardTheme,
        floatingActionButtonTheme,
        splitButtonTheme,
        checkboxTheme,
        radioTheme,
        switchTheme,
        sliderTheme,
        numberFieldTheme,
        inputOtpTheme,
        selectTheme,
        searchTheme,
        tooltipTheme,
        popoverTheme,
        bottomSheetTheme,
        datePickerTheme,
        timePickerTheme,
        badgeTheme,
        avatarTheme,
        optionTheme,
        messageBubbleTheme,
        bannerTheme,
        toolbarTheme,
        tabTheme,
        tabBarTheme,
        navigationItemTheme,
        navigationRailTheme,
        navigationBarTheme,
        ratingTheme,
        tableTheme,
        chartTheme,
        pageDotsTheme,
        carouselTheme,
        stepProgressTheme,
        meterTheme,
        progressIndicatorTheme,
        imageTheme,
        skeletonTheme,
        statusViewTheme,
        loadingIndicatorTheme,
      ];

  List<(String, ExpressiveComponentThemeData)> get _componentThemeEntries =>
      <(String, ExpressiveComponentThemeData)>[
        ('buttonTheme', buttonTheme),
        ('iconButtonTheme', iconButtonTheme),
        ('segmentedButtonTheme', segmentedButtonTheme),
        ('chipTheme', chipTheme),
        ('listTileTheme', listTileTheme),
        ('appBarTheme', appBarTheme),
        ('menuTheme', menuTheme),
        ('snackBarTheme', snackBarTheme),
        ('dialogTheme', dialogTheme),
        ('textFieldTheme', textFieldTheme),
        ('cardTheme', cardTheme),
        ('floatingActionButtonTheme', floatingActionButtonTheme),
        ('splitButtonTheme', splitButtonTheme),
        ('checkboxTheme', checkboxTheme),
        ('radioTheme', radioTheme),
        ('switchTheme', switchTheme),
        ('sliderTheme', sliderTheme),
        ('numberFieldTheme', numberFieldTheme),
        ('inputOtpTheme', inputOtpTheme),
        ('selectTheme', selectTheme),
        ('searchTheme', searchTheme),
        ('tooltipTheme', tooltipTheme),
        ('popoverTheme', popoverTheme),
        ('bottomSheetTheme', bottomSheetTheme),
        ('datePickerTheme', datePickerTheme),
        ('timePickerTheme', timePickerTheme),
        ('badgeTheme', badgeTheme),
        ('avatarTheme', avatarTheme),
        ('optionTheme', optionTheme),
        ('messageBubbleTheme', messageBubbleTheme),
        ('bannerTheme', bannerTheme),
        ('toolbarTheme', toolbarTheme),
        ('tabTheme', tabTheme),
        ('tabBarTheme', tabBarTheme),
        ('navigationItemTheme', navigationItemTheme),
        ('navigationRailTheme', navigationRailTheme),
        ('navigationBarTheme', navigationBarTheme),
        ('ratingTheme', ratingTheme),
        ('tableTheme', tableTheme),
        ('chartTheme', chartTheme),
        ('pageDotsTheme', pageDotsTheme),
        ('carouselTheme', carouselTheme),
        ('stepProgressTheme', stepProgressTheme),
        ('meterTheme', meterTheme),
        ('progressIndicatorTheme', progressIndicatorTheme),
        ('imageTheme', imageTheme),
        ('skeletonTheme', skeletonTheme),
        ('statusViewTheme', statusViewTheme),
        ('loadingIndicatorTheme', loadingIndicatorTheme),
      ];

  /// The state-layer opacities (`states.dart`): Compose's `StateTokens`,
  /// the same in every theme.
  ExpressiveStateLayers get states => ExpressiveStateLayers.tokens;

  /// Tonal and shadow elevation in this theme's colours (`elevation.dart`).
  ExpressiveElevation get elevation => ExpressiveElevation(colors);

  /// This theme with the parts given replaced: an app's own override of
  /// one foundation, or a subtree's (mount it on an [ExpressiveTheme]). A
  /// named component theme (`chipTheme:`) replaces that one.
  ExpressiveThemeData copyWith({
    ExpressiveExpression? expression,
    ExpressiveColorScheme? colors,
    ExpressiveTextTheme? type,
    ExpressiveShapes? shapes,
    ExpressiveDensity? density,
    ExpressiveMotion? motion,
    ExpressiveStatusColors? status,
    ExpressiveComponentThemeData? buttonTheme,
    ExpressiveComponentThemeData? iconButtonTheme,
    ExpressiveComponentThemeData? segmentedButtonTheme,
    ExpressiveComponentThemeData? chipTheme,
    ExpressiveComponentThemeData? listTileTheme,
    ExpressiveComponentThemeData? appBarTheme,
    ExpressiveComponentThemeData? menuTheme,
    ExpressiveComponentThemeData? snackBarTheme,
    ExpressiveComponentThemeData? dialogTheme,
    ExpressiveComponentThemeData? textFieldTheme,
    ExpressiveComponentThemeData? cardTheme,
    ExpressiveComponentThemeData? floatingActionButtonTheme,
    ExpressiveComponentThemeData? splitButtonTheme,
    ExpressiveComponentThemeData? checkboxTheme,
    ExpressiveComponentThemeData? radioTheme,
    ExpressiveComponentThemeData? switchTheme,
    ExpressiveComponentThemeData? sliderTheme,
    ExpressiveComponentThemeData? numberFieldTheme,
    ExpressiveComponentThemeData? inputOtpTheme,
    ExpressiveComponentThemeData? selectTheme,
    ExpressiveComponentThemeData? searchTheme,
    ExpressiveComponentThemeData? tooltipTheme,
    ExpressiveComponentThemeData? popoverTheme,
    ExpressiveComponentThemeData? bottomSheetTheme,
    ExpressiveComponentThemeData? datePickerTheme,
    ExpressiveComponentThemeData? timePickerTheme,
    ExpressiveComponentThemeData? badgeTheme,
    ExpressiveComponentThemeData? avatarTheme,
    ExpressiveComponentThemeData? optionTheme,
    ExpressiveComponentThemeData? messageBubbleTheme,
    ExpressiveComponentThemeData? bannerTheme,
    ExpressiveComponentThemeData? toolbarTheme,
    ExpressiveComponentThemeData? tabTheme,
    ExpressiveComponentThemeData? tabBarTheme,
    ExpressiveComponentThemeData? navigationItemTheme,
    ExpressiveComponentThemeData? navigationRailTheme,
    ExpressiveComponentThemeData? navigationBarTheme,
    ExpressiveComponentThemeData? ratingTheme,
    ExpressiveComponentThemeData? loadingIndicatorTheme,
    ExpressiveComponentThemeData? statusViewTheme,
    ExpressiveComponentThemeData? skeletonTheme,
    ExpressiveComponentThemeData? imageTheme,
    ExpressiveComponentThemeData? progressIndicatorTheme,
    ExpressiveComponentThemeData? meterTheme,
    ExpressiveComponentThemeData? stepProgressTheme,
    ExpressiveComponentThemeData? chartTheme,
    ExpressiveComponentThemeData? pageDotsTheme,
    ExpressiveComponentThemeData? carouselTheme,
    ExpressiveComponentThemeData? tableTheme,
  }) => ExpressiveThemeData(
    id: id,
    brightness: brightness,
    expression: expression ?? this.expression,
    colors: colors ?? this.colors,
    type: type ?? this.type,
    shapes: shapes ?? this.shapes,
    density: density ?? _density,
    motion: motion ?? this.motion,
    status: status ?? _status,
    buttonTheme: buttonTheme ?? this.buttonTheme,
    iconButtonTheme: iconButtonTheme ?? this.iconButtonTheme,
    segmentedButtonTheme: segmentedButtonTheme ?? this.segmentedButtonTheme,
    chipTheme: chipTheme ?? this.chipTheme,
    listTileTheme: listTileTheme ?? this.listTileTheme,
    appBarTheme: appBarTheme ?? this.appBarTheme,
    menuTheme: menuTheme ?? this.menuTheme,
    snackBarTheme: snackBarTheme ?? this.snackBarTheme,
    dialogTheme: dialogTheme ?? this.dialogTheme,
    textFieldTheme: textFieldTheme ?? this.textFieldTheme,
    cardTheme: cardTheme ?? this.cardTheme,
    floatingActionButtonTheme:
        floatingActionButtonTheme ?? this.floatingActionButtonTheme,
    splitButtonTheme: splitButtonTheme ?? this.splitButtonTheme,
    checkboxTheme: checkboxTheme ?? this.checkboxTheme,
    radioTheme: radioTheme ?? this.radioTheme,
    switchTheme: switchTheme ?? this.switchTheme,
    sliderTheme: sliderTheme ?? this.sliderTheme,
    numberFieldTheme: numberFieldTheme ?? this.numberFieldTheme,
    inputOtpTheme: inputOtpTheme ?? this.inputOtpTheme,
    selectTheme: selectTheme ?? this.selectTheme,
    searchTheme: searchTheme ?? this.searchTheme,
    tooltipTheme: tooltipTheme ?? this.tooltipTheme,
    popoverTheme: popoverTheme ?? this.popoverTheme,
    bottomSheetTheme: bottomSheetTheme ?? this.bottomSheetTheme,
    datePickerTheme: datePickerTheme ?? this.datePickerTheme,
    timePickerTheme: timePickerTheme ?? this.timePickerTheme,
    badgeTheme: badgeTheme ?? this.badgeTheme,
    avatarTheme: avatarTheme ?? this.avatarTheme,
    optionTheme: optionTheme ?? this.optionTheme,
    messageBubbleTheme: messageBubbleTheme ?? this.messageBubbleTheme,
    bannerTheme: bannerTheme ?? this.bannerTheme,
    toolbarTheme: toolbarTheme ?? this.toolbarTheme,
    tabTheme: tabTheme ?? this.tabTheme,
    tabBarTheme: tabBarTheme ?? this.tabBarTheme,
    navigationItemTheme: navigationItemTheme ?? this.navigationItemTheme,
    navigationRailTheme: navigationRailTheme ?? this.navigationRailTheme,
    navigationBarTheme: navigationBarTheme ?? this.navigationBarTheme,
    ratingTheme: ratingTheme ?? this.ratingTheme,
    tableTheme: tableTheme ?? this.tableTheme,
    chartTheme: chartTheme ?? this.chartTheme,
    pageDotsTheme: pageDotsTheme ?? this.pageDotsTheme,
    carouselTheme: carouselTheme ?? this.carouselTheme,
    stepProgressTheme: stepProgressTheme ?? this.stepProgressTheme,
    meterTheme: meterTheme ?? this.meterTheme,
    progressIndicatorTheme:
        progressIndicatorTheme ?? this.progressIndicatorTheme,
    imageTheme: imageTheme ?? this.imageTheme,
    skeletonTheme: skeletonTheme ?? this.skeletonTheme,
    statusViewTheme: statusViewTheme ?? this.statusViewTheme,
    loadingIndicatorTheme: loadingIndicatorTheme ?? this.loadingIndicatorTheme,
  );

  @override
  bool operator ==(Object other) =>
      other is ExpressiveThemeData &&
      other.id == id &&
      other.brightness == brightness &&
      other.expression == expression &&
      other.colors == colors &&
      other.type == type &&
      other.shapes == shapes &&
      other._density == _density &&
      other.motion == motion &&
      other.status == status &&
      listEquals(other._componentThemes, _componentThemes);

  @override
  int get hashCode => Object.hash(
    id,
    brightness,
    expression,
    colors,
    type,
    shapes,
    _density,
    motion,
    status,
    Object.hashAll(_componentThemes),
  );

  /// [a] and [b] interpolated at [t] (0 is [a], 1 is [b]), as
  /// `ThemeData.lerp` is: every colour role through
  /// [ExpressiveColorScheme.lerp], the status tones colour by colour, the
  /// component themes slot by slot
  /// ([ExpressiveComponentThemeData.lerp]), and the parts that do not interpolate
  /// (the id, the brightness, the expression budget, the type scale, the
  /// shape scale and the motion scheme) taken from [a] below one half and
  /// from [b] from it. [t] may overshoot, as a spring does.
  static ExpressiveThemeData lerp(
    ExpressiveThemeData a,
    ExpressiveThemeData b,
    double t,
  ) {
    if (identical(a, b)) return a;
    final near = t < 0.5 ? a : b;
    return ExpressiveThemeData(
      id: near.id,
      brightness: near.brightness,
      expression: near.expression,
      colors: ExpressiveColorScheme.lerp(a.colors, b.colors, t),
      type: ExpressiveTextTheme.lerp(a.type, b.type, t),
      shapes: ExpressiveShapes.lerp(a.shapes, b.shapes, t),
      density: a._density == null && b._density == null
          ? null
          : ExpressiveDensity.lerp(a.density, b.density, t),
      motion: near.motion,
      status: ExpressiveStatusColors.lerp(a.status, b.status, t),
      buttonTheme: ExpressiveComponentThemeData.lerp(
        a.buttonTheme,
        b.buttonTheme,
        t,
      ),
      iconButtonTheme: ExpressiveComponentThemeData.lerp(
        a.iconButtonTheme,
        b.iconButtonTheme,
        t,
      ),
      segmentedButtonTheme: ExpressiveComponentThemeData.lerp(
        a.segmentedButtonTheme,
        b.segmentedButtonTheme,
        t,
      ),
      chipTheme: ExpressiveComponentThemeData.lerp(a.chipTheme, b.chipTheme, t),
      listTileTheme: ExpressiveComponentThemeData.lerp(
        a.listTileTheme,
        b.listTileTheme,
        t,
      ),
      appBarTheme: ExpressiveComponentThemeData.lerp(
        a.appBarTheme,
        b.appBarTheme,
        t,
      ),
      menuTheme: ExpressiveComponentThemeData.lerp(a.menuTheme, b.menuTheme, t),
      snackBarTheme: ExpressiveComponentThemeData.lerp(
        a.snackBarTheme,
        b.snackBarTheme,
        t,
      ),
      dialogTheme: ExpressiveComponentThemeData.lerp(
        a.dialogTheme,
        b.dialogTheme,
        t,
      ),
      textFieldTheme: ExpressiveComponentThemeData.lerp(
        a.textFieldTheme,
        b.textFieldTheme,
        t,
      ),
      cardTheme: ExpressiveComponentThemeData.lerp(a.cardTheme, b.cardTheme, t),
      floatingActionButtonTheme: ExpressiveComponentThemeData.lerp(
        a.floatingActionButtonTheme,
        b.floatingActionButtonTheme,
        t,
      ),
      splitButtonTheme: ExpressiveComponentThemeData.lerp(
        a.splitButtonTheme,
        b.splitButtonTheme,
        t,
      ),
      checkboxTheme: ExpressiveComponentThemeData.lerp(
        a.checkboxTheme,
        b.checkboxTheme,
        t,
      ),
      radioTheme: ExpressiveComponentThemeData.lerp(
        a.radioTheme,
        b.radioTheme,
        t,
      ),
      switchTheme: ExpressiveComponentThemeData.lerp(
        a.switchTheme,
        b.switchTheme,
        t,
      ),
      sliderTheme: ExpressiveComponentThemeData.lerp(
        a.sliderTheme,
        b.sliderTheme,
        t,
      ),
      numberFieldTheme: ExpressiveComponentThemeData.lerp(
        a.numberFieldTheme,
        b.numberFieldTheme,
        t,
      ),
      inputOtpTheme: ExpressiveComponentThemeData.lerp(
        a.inputOtpTheme,
        b.inputOtpTheme,
        t,
      ),
      selectTheme: ExpressiveComponentThemeData.lerp(
        a.selectTheme,
        b.selectTheme,
        t,
      ),
      searchTheme: ExpressiveComponentThemeData.lerp(
        a.searchTheme,
        b.searchTheme,
        t,
      ),
      tooltipTheme: ExpressiveComponentThemeData.lerp(
        a.tooltipTheme,
        b.tooltipTheme,
        t,
      ),
      popoverTheme: ExpressiveComponentThemeData.lerp(
        a.popoverTheme,
        b.popoverTheme,
        t,
      ),
      bottomSheetTheme: ExpressiveComponentThemeData.lerp(
        a.bottomSheetTheme,
        b.bottomSheetTheme,
        t,
      ),
      datePickerTheme: ExpressiveComponentThemeData.lerp(
        a.datePickerTheme,
        b.datePickerTheme,
        t,
      ),
      timePickerTheme: ExpressiveComponentThemeData.lerp(
        a.timePickerTheme,
        b.timePickerTheme,
        t,
      ),
      badgeTheme: ExpressiveComponentThemeData.lerp(
        a.badgeTheme,
        b.badgeTheme,
        t,
      ),
      avatarTheme: ExpressiveComponentThemeData.lerp(
        a.avatarTheme,
        b.avatarTheme,
        t,
      ),
      optionTheme: ExpressiveComponentThemeData.lerp(
        a.optionTheme,
        b.optionTheme,
        t,
      ),
      messageBubbleTheme: ExpressiveComponentThemeData.lerp(
        a.messageBubbleTheme,
        b.messageBubbleTheme,
        t,
      ),
      bannerTheme: ExpressiveComponentThemeData.lerp(
        a.bannerTheme,
        b.bannerTheme,
        t,
      ),
      toolbarTheme: ExpressiveComponentThemeData.lerp(
        a.toolbarTheme,
        b.toolbarTheme,
        t,
      ),
      tabTheme: ExpressiveComponentThemeData.lerp(a.tabTheme, b.tabTheme, t),
      tabBarTheme: ExpressiveComponentThemeData.lerp(
        a.tabBarTheme,
        b.tabBarTheme,
        t,
      ),
      navigationItemTheme: ExpressiveComponentThemeData.lerp(
        a.navigationItemTheme,
        b.navigationItemTheme,
        t,
      ),
      navigationRailTheme: ExpressiveComponentThemeData.lerp(
        a.navigationRailTheme,
        b.navigationRailTheme,
        t,
      ),
      navigationBarTheme: ExpressiveComponentThemeData.lerp(
        a.navigationBarTheme,
        b.navigationBarTheme,
        t,
      ),
      ratingTheme: ExpressiveComponentThemeData.lerp(
        a.ratingTheme,
        b.ratingTheme,
        t,
      ),
      tableTheme: ExpressiveComponentThemeData.lerp(
        a.tableTheme,
        b.tableTheme,
        t,
      ),
      chartTheme: ExpressiveComponentThemeData.lerp(
        a.chartTheme,
        b.chartTheme,
        t,
      ),
      pageDotsTheme: ExpressiveComponentThemeData.lerp(
        a.pageDotsTheme,
        b.pageDotsTheme,
        t,
      ),
      carouselTheme: ExpressiveComponentThemeData.lerp(
        a.carouselTheme,
        b.carouselTheme,
        t,
      ),
      stepProgressTheme: ExpressiveComponentThemeData.lerp(
        a.stepProgressTheme,
        b.stepProgressTheme,
        t,
      ),
      meterTheme: ExpressiveComponentThemeData.lerp(
        a.meterTheme,
        b.meterTheme,
        t,
      ),
      progressIndicatorTheme: ExpressiveComponentThemeData.lerp(
        a.progressIndicatorTheme,
        b.progressIndicatorTheme,
        t,
      ),
      imageTheme: ExpressiveComponentThemeData.lerp(
        a.imageTheme,
        b.imageTheme,
        t,
      ),
      skeletonTheme: ExpressiveComponentThemeData.lerp(
        a.skeletonTheme,
        b.skeletonTheme,
        t,
      ),
      statusViewTheme: ExpressiveComponentThemeData.lerp(
        a.statusViewTheme,
        b.statusViewTheme,
        t,
      ),
      loadingIndicatorTheme: ExpressiveComponentThemeData.lerp(
        a.loadingIndicatorTheme,
        b.loadingIndicatorTheme,
        t,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('id', id))
      ..add(EnumProperty<Brightness>('brightness', brightness))
      ..add(EnumProperty<ExpressiveExpression>('expression', expression))
      ..add(DiagnosticsProperty<ExpressiveColorScheme>('colors', colors))
      ..add(DiagnosticsProperty<ExpressiveTextTheme>('type', type))
      ..add(DiagnosticsProperty<ExpressiveShapes>('shapes', shapes))
      ..add(DiagnosticsProperty<ExpressiveDensity>('density', density))
      ..add(DiagnosticsProperty<ExpressiveMotion>('motion', motion))
      ..add(DiagnosticsProperty<ExpressiveStatusColors>('status', status));
    for (final (name, theme) in _componentThemeEntries) {
      properties.add(
        DiagnosticsProperty<ExpressiveComponentThemeData>(
          name,
          theme,
          defaultValue: const ExpressiveComponentThemeData(),
        ),
      );
    }
  }
}

/// Mounts an [ExpressiveThemeData] for everything below it, as Material's
/// `Theme` does: the one root widget an app needs, in its `builder:`, under
/// `MaterialApp`, `CupertinoApp` or `WidgetsApp` alike (the last two with
/// Material's localizations: a field is Flutter's Material `TextField`
/// underneath). A nested one
/// restyles a subtree. It follows the app into overlays and routes that
/// capture themes (its mount is an [InheritedTheme]).
///
/// A scope also sets the ink below it: the ambient [DefaultTextStyle] and
/// [IconTheme] colour become its scheme's `onSurface`, as a surface's
/// `contentColor` does. Uncoloured text and glyphs under a retinted page
/// (an artwork scheme, a re-scoped footer) therefore take the page's own
/// ink rather than the ink of the theme around it. A surface or component
/// inside the scope that sets its own content colour still wins.
///
/// It also sets the text-selection colours below it, as Compose's
/// `MaterialTheme` provides `LocalTextSelectionColors`: handles and caret in
/// `primary`, the selection's background `primary` at
/// `HostBehavior.textSelectionBackgroundOpacity`. A field's selection is
/// Expressive's whatever Material theme the app wears.
///
/// ```dart
/// ExpressiveTheme(
///   data: ExpressiveThemeData.bloom(Brightness.dark),
///   child: const ExpressiveFilledButton('Save'),
/// )
/// ```
class ExpressiveTheme extends StatelessWidget {
  /// Mounts [data] for [child].
  const ExpressiveTheme({required this.data, required this.child, super.key});

  /// The theme mounted here.
  final ExpressiveThemeData data;

  /// What the theme is mounted for.
  final Widget child;

  /// The nearest mounted theme, or null outside any.
  static ExpressiveThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ExpressiveThemeMount>()?.data;

  /// The nearest mounted theme, else the default preset in the platform's
  /// brightness: a component outside any [ExpressiveTheme] still draws.
  static ExpressiveThemeData of(BuildContext context) =>
      maybeOf(context) ??
      ExpressiveThemeData.preset(
        ExpressiveThemeData.defaultPreset,
        MediaQuery.maybePlatformBrightnessOf(context) ?? Brightness.light,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ExpressiveThemeData>('data', data));
  }

  @override
  Widget build(BuildContext context) {
    final ink = data.colors.onSurface;
    // Under a bare WidgetsApp nothing above sets a text style, and a
    // MaterialApp sets Flutter's error style; either way the red, double
    // yellow underlined fallback would reach every route and overlay. A scope
    // over either supplies the body style, as ExpressiveHost does; a scope
    // under a real style only retints its ink.
    final inherited = DefaultTextStyle.of(context).style;
    final unstyled =
        inherited.fontSize == null ||
        (inherited.decorationStyle == TextDecorationStyle.double &&
            inherited.decorationColor == const Color(0xFFFFFF00));
    final textStyle = unstyled
        ? data.type.bodyLarge.copyWith(color: ink)
        : null;
    Widget withText(Widget child) => textStyle == null
        ? DefaultTextStyle.merge(
            style: TextStyle(color: ink),
            child: child,
          )
        : DefaultTextStyle(style: textStyle, child: child);
    final themed = _ExpressiveThemeMount(
      data: data,
      child: AnnotatedRegion<ExpressiveSystemBarColor>(
        value: ExpressiveSystemBarColor(ink),
        child: withText(
          IconTheme.merge(
            data: IconThemeData(color: ink),
            child: TextSelectionTheme(
              data: TextSelectionThemeData(
                cursorColor: data.colors.primary,
                selectionColor: data.colors.primary.withValues(
                  alpha: HostBehavior.textSelectionBackgroundOpacity,
                ),
                selectionHandleColor: data.colors.primary,
              ),
              child: child,
            ),
          ),
        ),
      ),
    );
    // The package's primitives use material_ui, whose localization type is
    // distinct from a Flutter MaterialApp's. A WidgetsApp has none either.
    // Keep the app's locale, delegates and direction, supplying only the
    // missing primitive resource; an existing translation always wins.
    if (Localizations.of<MaterialLocalizations>(
          context,
          MaterialLocalizations,
        ) !=
        null) {
      return themed;
    }
    final direction = Directionality.maybeOf(context);
    final localizedChild = direction == null
        ? themed
        : Directionality(textDirection: direction, child: themed);
    final locale = Localizations.maybeLocaleOf(context);
    if (locale == null) {
      return Localizations(
        locale: const Locale('en'),
        delegates: const [
          _PrimitiveMaterialLocalizations(),
          DefaultWidgetsLocalizations.delegate,
        ],
        child: localizedChild,
      );
    }
    return Localizations.override(
      context: context,
      delegates: const [_PrimitiveMaterialLocalizations()],
      child: localizedChild,
    );
  }
}

class _PrimitiveMaterialLocalizations
    extends LocalizationsDelegate<MaterialLocalizations> {
  const _PrimitiveMaterialLocalizations();

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      SynchronousFuture(const DefaultMaterialLocalizations());

  @override
  bool shouldReload(_PrimitiveMaterialLocalizations old) => false;
}

/// [ExpressiveTheme], springing to each new [data] on the theme's default
/// effects spring (Compose animates a colour change on its effects
/// springs; Material's `AnimatedTheme` on a fixed duration): every colour
/// role cross-fades, and the rest changes at the halfway point
/// ([ExpressiveThemeData.lerp]). The first build shows [data] at once.
///
/// ```dart
/// AnimatedExpressiveTheme(
///   data: ExpressiveThemeData.preset(id, Brightness.light),
///   child: const ExpressiveFilledButton('Save'),
/// )
/// ```
class AnimatedExpressiveTheme extends StatelessWidget {
  /// Springs to [data] for [child].
  const AnimatedExpressiveTheme({
    required this.data,
    required this.child,
    super.key,
  });

  /// The theme to spring to.
  final ExpressiveThemeData data;

  /// What the theme is mounted for.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ExpressiveSpringTween<ExpressiveThemeData>(
        value: data,
        motion: ExpressiveMotionKey.defaultEffects,
        lerp: ExpressiveThemeData.lerp,
        builder: (context, theme, child) =>
            ExpressiveTheme(data: theme, child: child!),
        child: child,
      );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ExpressiveThemeData>('data', data));
  }
}

/// The ink an [ExpressiveTheme] sets, annotated over the scope's
/// bounds: what an [ExpressivePreview]'s system bars wear over a scope
/// whose page asks for no overlay style, as the real bars adapt to what is
/// under them — a page in a show's scheme gets the scheme's ink, not the
/// app theme's.
@immutable
class ExpressiveSystemBarColor {
  /// An ink of [color].
  const ExpressiveSystemBarColor(this.color);

  /// The scope's `onSurface`.
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveSystemBarColor && other.color == color;

  @override
  int get hashCode => color.hashCode;
}

/// [ExpressiveTheme]'s inherited half: what `maybeOf` finds, and what
/// a route that captures themes carries over ([wrap] mounts the scope, ink
/// and all, again).
class _ExpressiveThemeMount extends InheritedTheme {
  const _ExpressiveThemeMount({required this.data, required super.child});

  final ExpressiveThemeData data;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ExpressiveTheme(data: data, child: child);

  @override
  bool updateShouldNotify(_ExpressiveThemeMount oldWidget) =>
      data != oldWidget.data;
}

/// `context.expressiveTheme`: the theme every Expressive component reads.
extension ExpressiveThemeContext on BuildContext {
  /// The theme in force here: the nearest [ExpressiveTheme]'s, else the
  /// default preset in the platform's brightness ([ExpressiveTheme.of]).
  ExpressiveThemeData get expressiveTheme => ExpressiveTheme.of(this);
}
