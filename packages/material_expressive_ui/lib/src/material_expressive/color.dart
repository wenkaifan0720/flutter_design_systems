/// Expressive's colour: [ExpressiveColorScheme], every colour role of one
/// theme in one brightness, which `context.expressiveTheme.colors` carries
/// (CONTRACT §2 "Color"). Components paint with these roles and nothing
/// else — by name (`colors.primary`) or, from a token, by its symbolic
/// [ExpressiveColorRole] (`colors.role(ButtonSmallTokens.containerColor)`).
///
/// The roles are exactly Compose's `ColorScheme` at material3 1.5.0-alpha29
/// (its 48 `ColorSchemeKeyTokens`, the generated [ExpressiveColorRole]),
/// plus [ExpressiveColorScheme.shadow] (md.sys.color.shadow), which
/// Compose paints as a constant.
///
/// A theme's colours are baked from its `themes/<id>/theme.json` by
/// `tools/expressive_tokens` (`emit/color.ts`, the seed baker in
/// `src/bake/`: material-color-utilities 0.4.0, spec 2025, phone), light
/// and dark; dark is generated, never an inversion of light. `baseline` is
/// exactly what Compose's `MaterialExpressiveTheme` paints by default
/// (CONTRACT §6), from the jar's tokens rather than the baker.
///
/// Owner: w1-color (with `internal/color/`, `emit/color.ts`, `src/bake/`
/// and `test/color_test.dart`).
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'internal/tokens/keys.g.dart';

export 'internal/tokens/keys.g.dart' show ExpressiveColorRole;

/// Every colour role of one theme in one brightness.
@immutable
class ExpressiveColorScheme with Diagnosticable {
  /// Every role given, as the baker writes them.
  const ExpressiveColorScheme({
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.background,
    required this.onBackground,
    required this.surface,
    required this.onSurface,
    required this.surfaceVariant,
    required this.onSurfaceVariant,
    required this.surfaceTint,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
    required this.outline,
    required this.outlineVariant,
    required this.scrim,
    required this.surfaceBright,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceContainerLow,
    required this.surfaceContainerLowest,
    required this.surfaceDim,
    required this.primaryFixed,
    required this.primaryFixedDim,
    required this.onPrimaryFixed,
    required this.onPrimaryFixedVariant,
    required this.secondaryFixed,
    required this.secondaryFixedDim,
    required this.onSecondaryFixed,
    required this.onSecondaryFixedVariant,
    required this.tertiaryFixed,
    required this.tertiaryFixedDim,
    required this.onTertiaryFixed,
    required this.onTertiaryFixedVariant,
    required this.shadow,
  });

  /// A scheme whose every role is [of] that role, and whose [shadow] is
  /// [shadow].
  factory ExpressiveColorScheme.fromRoles(
    Color Function(ExpressiveColorRole role) of, {
    required Color shadow,
  }) => ExpressiveColorScheme(
    primary: of(ExpressiveColorRole.primary),
    onPrimary: of(ExpressiveColorRole.onPrimary),
    primaryContainer: of(ExpressiveColorRole.primaryContainer),
    onPrimaryContainer: of(ExpressiveColorRole.onPrimaryContainer),
    inversePrimary: of(ExpressiveColorRole.inversePrimary),
    secondary: of(ExpressiveColorRole.secondary),
    onSecondary: of(ExpressiveColorRole.onSecondary),
    secondaryContainer: of(ExpressiveColorRole.secondaryContainer),
    onSecondaryContainer: of(ExpressiveColorRole.onSecondaryContainer),
    tertiary: of(ExpressiveColorRole.tertiary),
    onTertiary: of(ExpressiveColorRole.onTertiary),
    tertiaryContainer: of(ExpressiveColorRole.tertiaryContainer),
    onTertiaryContainer: of(ExpressiveColorRole.onTertiaryContainer),
    background: of(ExpressiveColorRole.background),
    onBackground: of(ExpressiveColorRole.onBackground),
    surface: of(ExpressiveColorRole.surface),
    onSurface: of(ExpressiveColorRole.onSurface),
    surfaceVariant: of(ExpressiveColorRole.surfaceVariant),
    onSurfaceVariant: of(ExpressiveColorRole.onSurfaceVariant),
    surfaceTint: of(ExpressiveColorRole.surfaceTint),
    inverseSurface: of(ExpressiveColorRole.inverseSurface),
    inverseOnSurface: of(ExpressiveColorRole.inverseOnSurface),
    error: of(ExpressiveColorRole.error),
    onError: of(ExpressiveColorRole.onError),
    errorContainer: of(ExpressiveColorRole.errorContainer),
    onErrorContainer: of(ExpressiveColorRole.onErrorContainer),
    outline: of(ExpressiveColorRole.outline),
    outlineVariant: of(ExpressiveColorRole.outlineVariant),
    scrim: of(ExpressiveColorRole.scrim),
    surfaceBright: of(ExpressiveColorRole.surfaceBright),
    surfaceContainer: of(ExpressiveColorRole.surfaceContainer),
    surfaceContainerHigh: of(ExpressiveColorRole.surfaceContainerHigh),
    surfaceContainerHighest: of(ExpressiveColorRole.surfaceContainerHighest),
    surfaceContainerLow: of(ExpressiveColorRole.surfaceContainerLow),
    surfaceContainerLowest: of(ExpressiveColorRole.surfaceContainerLowest),
    surfaceDim: of(ExpressiveColorRole.surfaceDim),
    primaryFixed: of(ExpressiveColorRole.primaryFixed),
    primaryFixedDim: of(ExpressiveColorRole.primaryFixedDim),
    onPrimaryFixed: of(ExpressiveColorRole.onPrimaryFixed),
    onPrimaryFixedVariant: of(ExpressiveColorRole.onPrimaryFixedVariant),
    secondaryFixed: of(ExpressiveColorRole.secondaryFixed),
    secondaryFixedDim: of(ExpressiveColorRole.secondaryFixedDim),
    onSecondaryFixed: of(ExpressiveColorRole.onSecondaryFixed),
    onSecondaryFixedVariant: of(ExpressiveColorRole.onSecondaryFixedVariant),
    tertiaryFixed: of(ExpressiveColorRole.tertiaryFixed),
    tertiaryFixedDim: of(ExpressiveColorRole.tertiaryFixedDim),
    onTertiaryFixed: of(ExpressiveColorRole.onTertiaryFixed),
    onTertiaryFixedVariant: of(ExpressiveColorRole.onTertiaryFixedVariant),
    shadow: shadow,
  );

  /// This scheme with the given roles replaced (Compose's
  /// `ColorScheme.copy`): a brand's own primary over a preset, a dark
  /// surface of its own.
  ///
  /// ```dart
  /// context.expressiveTheme.colors.copyWith(primary: const Color(0xFF006A60))
  /// ```
  ExpressiveColorScheme copyWith({
    Color? primary,
    Color? onPrimary,
    Color? primaryContainer,
    Color? onPrimaryContainer,
    Color? inversePrimary,
    Color? secondary,
    Color? onSecondary,
    Color? secondaryContainer,
    Color? onSecondaryContainer,
    Color? tertiary,
    Color? onTertiary,
    Color? tertiaryContainer,
    Color? onTertiaryContainer,
    Color? background,
    Color? onBackground,
    Color? surface,
    Color? onSurface,
    Color? surfaceVariant,
    Color? onSurfaceVariant,
    Color? surfaceTint,
    Color? inverseSurface,
    Color? inverseOnSurface,
    Color? error,
    Color? onError,
    Color? errorContainer,
    Color? onErrorContainer,
    Color? outline,
    Color? outlineVariant,
    Color? scrim,
    Color? surfaceBright,
    Color? surfaceContainer,
    Color? surfaceContainerHigh,
    Color? surfaceContainerHighest,
    Color? surfaceContainerLow,
    Color? surfaceContainerLowest,
    Color? surfaceDim,
    Color? primaryFixed,
    Color? primaryFixedDim,
    Color? onPrimaryFixed,
    Color? onPrimaryFixedVariant,
    Color? secondaryFixed,
    Color? secondaryFixedDim,
    Color? onSecondaryFixed,
    Color? onSecondaryFixedVariant,
    Color? tertiaryFixed,
    Color? tertiaryFixedDim,
    Color? onTertiaryFixed,
    Color? onTertiaryFixedVariant,
    Color? shadow,
  }) {
    final given = <ExpressiveColorRole, Color?>{
      ExpressiveColorRole.primary: primary,
      ExpressiveColorRole.onPrimary: onPrimary,
      ExpressiveColorRole.primaryContainer: primaryContainer,
      ExpressiveColorRole.onPrimaryContainer: onPrimaryContainer,
      ExpressiveColorRole.inversePrimary: inversePrimary,
      ExpressiveColorRole.secondary: secondary,
      ExpressiveColorRole.onSecondary: onSecondary,
      ExpressiveColorRole.secondaryContainer: secondaryContainer,
      ExpressiveColorRole.onSecondaryContainer: onSecondaryContainer,
      ExpressiveColorRole.tertiary: tertiary,
      ExpressiveColorRole.onTertiary: onTertiary,
      ExpressiveColorRole.tertiaryContainer: tertiaryContainer,
      ExpressiveColorRole.onTertiaryContainer: onTertiaryContainer,
      ExpressiveColorRole.background: background,
      ExpressiveColorRole.onBackground: onBackground,
      ExpressiveColorRole.surface: surface,
      ExpressiveColorRole.onSurface: onSurface,
      ExpressiveColorRole.surfaceVariant: surfaceVariant,
      ExpressiveColorRole.onSurfaceVariant: onSurfaceVariant,
      ExpressiveColorRole.surfaceTint: surfaceTint,
      ExpressiveColorRole.inverseSurface: inverseSurface,
      ExpressiveColorRole.inverseOnSurface: inverseOnSurface,
      ExpressiveColorRole.error: error,
      ExpressiveColorRole.onError: onError,
      ExpressiveColorRole.errorContainer: errorContainer,
      ExpressiveColorRole.onErrorContainer: onErrorContainer,
      ExpressiveColorRole.outline: outline,
      ExpressiveColorRole.outlineVariant: outlineVariant,
      ExpressiveColorRole.scrim: scrim,
      ExpressiveColorRole.surfaceBright: surfaceBright,
      ExpressiveColorRole.surfaceContainer: surfaceContainer,
      ExpressiveColorRole.surfaceContainerHigh: surfaceContainerHigh,
      ExpressiveColorRole.surfaceContainerHighest: surfaceContainerHighest,
      ExpressiveColorRole.surfaceContainerLow: surfaceContainerLow,
      ExpressiveColorRole.surfaceContainerLowest: surfaceContainerLowest,
      ExpressiveColorRole.surfaceDim: surfaceDim,
      ExpressiveColorRole.primaryFixed: primaryFixed,
      ExpressiveColorRole.primaryFixedDim: primaryFixedDim,
      ExpressiveColorRole.onPrimaryFixed: onPrimaryFixed,
      ExpressiveColorRole.onPrimaryFixedVariant: onPrimaryFixedVariant,
      ExpressiveColorRole.secondaryFixed: secondaryFixed,
      ExpressiveColorRole.secondaryFixedDim: secondaryFixedDim,
      ExpressiveColorRole.onSecondaryFixed: onSecondaryFixed,
      ExpressiveColorRole.onSecondaryFixedVariant: onSecondaryFixedVariant,
      ExpressiveColorRole.tertiaryFixed: tertiaryFixed,
      ExpressiveColorRole.tertiaryFixedDim: tertiaryFixedDim,
      ExpressiveColorRole.onTertiaryFixed: onTertiaryFixed,
      ExpressiveColorRole.onTertiaryFixedVariant: onTertiaryFixedVariant,
    };
    return ExpressiveColorScheme.fromRoles(
      (role) => given[role] ?? this.role(role),
      shadow: shadow ?? this.shadow,
    );
  }

  /// Every role of [a] and [b] interpolated at [t] (0 is [a], 1 is [b]):
  /// how a page cross-fades from one scheme to another on its spring, as
  /// an artwork scheme replaces the theme's (`ExpressiveArtwork`). [t] may
  /// overshoot, as a spring does; each channel is clamped.
  static ExpressiveColorScheme lerp(
    ExpressiveColorScheme a,
    ExpressiveColorScheme b,
    double t,
  ) {
    if (identical(a, b)) return a;
    return ExpressiveColorScheme.fromRoles(
      (role) => Color.lerp(a.role(role), b.role(role), t)!,
      shadow: Color.lerp(a.shadow, b.shadow, t)!,
    );
  }

  /// The accent: the most prominent actions and active states.
  final Color primary;

  /// Text and icons on [primary].
  final Color onPrimary;

  /// A prominent container in the accent family: the floating action button.
  final Color primaryContainer;

  /// Text and icons on [primaryContainer].
  final Color onPrimaryContainer;

  /// The accent on [inverseSurface]: a snackbar's action.
  final Color inversePrimary;

  /// A less prominent accent.
  final Color secondary;

  /// Text and icons on [secondary].
  final Color onSecondary;

  /// A tonal container: the selected navigation item's indicator, tonal buttons.
  final Color secondaryContainer;

  /// Text and icons on [secondaryContainer].
  final Color onSecondaryContainer;

  /// A contrasting accent that balances [primary] and [secondary].
  final Color tertiary;

  /// Text and icons on [tertiary].
  final Color onTertiary;

  /// A container in the contrasting accent family.
  final Color tertiaryContainer;

  /// Text and icons on [tertiaryContainer].
  final Color onTertiaryContainer;

  /// The page's ground; the same as [surface] in Material 3.
  final Color background;

  /// Text and icons on [background].
  final Color onBackground;

  /// The ground every page stands on.
  final Color surface;

  /// Text and icons on [surface] and its containers.
  final Color onSurface;

  /// A variant ground; the same tone as [surfaceContainerHighest].
  final Color surfaceVariant;

  /// Secondary text and icons on [surface]: idle navigation items, the drag handle.
  final Color onSurfaceVariant;

  /// The tint Material 3's tonal elevation mixes into [surface]; the same as [primary].
  final Color surfaceTint;

  /// A surface that contrasts with [surface]: snackbars.
  final Color inverseSurface;

  /// Text and icons on [inverseSurface].
  final Color inverseOnSurface;

  /// Errors: the most prominent error state.
  final Color error;

  /// Text and icons on [error].
  final Color onError;

  /// A container for errors.
  final Color errorContainer;

  /// Text and icons on [errorContainer].
  final Color onErrorContainer;

  /// Important boundaries: a text field's outline.
  final Color outline;

  /// Decorative outlines and dividers.
  final Color outlineVariant;

  /// What a modal surface dims the page with, at the scrim's opacity.
  final Color scrim;

  /// The brightest surface, in light and dark alike.
  final Color surfaceBright;

  /// The default container: the navigation bar.
  final Color surfaceContainer;

  /// A container a step above [surfaceContainer].
  final Color surfaceContainerHigh;

  /// The most prominent surface container.
  final Color surfaceContainerHighest;

  /// A quiet container a step above [surface]: sheets.
  final Color surfaceContainerLow;

  /// The quietest container, below [surfaceContainerLow].
  final Color surfaceContainerLowest;

  /// The dimmest surface, in light and dark alike.
  final Color surfaceDim;

  /// The accent container that keeps its tone in light and dark.
  final Color primaryFixed;

  /// A stronger [primaryFixed].
  final Color primaryFixedDim;

  /// Text and icons on [primaryFixed] and [primaryFixedDim].
  final Color onPrimaryFixed;

  /// Lower-emphasis text and icons on [primaryFixed] and [primaryFixedDim].
  final Color onPrimaryFixedVariant;

  /// The secondary container that keeps its tone in light and dark.
  final Color secondaryFixed;

  /// A stronger [secondaryFixed].
  final Color secondaryFixedDim;

  /// Text and icons on [secondaryFixed] and [secondaryFixedDim].
  final Color onSecondaryFixed;

  /// Lower-emphasis text and icons on [secondaryFixed] and [secondaryFixedDim].
  final Color onSecondaryFixedVariant;

  /// The tertiary container that keeps its tone in light and dark.
  final Color tertiaryFixed;

  /// A stronger [tertiaryFixed].
  final Color tertiaryFixedDim;

  /// Text and icons on [tertiaryFixed] and [tertiaryFixedDim].
  final Color onTertiaryFixed;

  /// Lower-emphasis text and icons on [tertiaryFixed] and [tertiaryFixedDim].
  final Color onTertiaryFixedVariant;

  /// Elevation's shadow (md.sys.color.shadow): the neutral palette's tone 0
  /// in every theme, which is what Compose's shadows paint with.
  final Color shadow;

  /// The colour [role] names: how a token's symbolic colour resolves.
  Color role(ExpressiveColorRole role) => switch (role) {
    ExpressiveColorRole.background => background,
    ExpressiveColorRole.error => error,
    ExpressiveColorRole.errorContainer => errorContainer,
    ExpressiveColorRole.inverseOnSurface => inverseOnSurface,
    ExpressiveColorRole.inversePrimary => inversePrimary,
    ExpressiveColorRole.inverseSurface => inverseSurface,
    ExpressiveColorRole.onBackground => onBackground,
    ExpressiveColorRole.onError => onError,
    ExpressiveColorRole.onErrorContainer => onErrorContainer,
    ExpressiveColorRole.onPrimary => onPrimary,
    ExpressiveColorRole.onPrimaryContainer => onPrimaryContainer,
    ExpressiveColorRole.onPrimaryFixed => onPrimaryFixed,
    ExpressiveColorRole.onPrimaryFixedVariant => onPrimaryFixedVariant,
    ExpressiveColorRole.onSecondary => onSecondary,
    ExpressiveColorRole.onSecondaryContainer => onSecondaryContainer,
    ExpressiveColorRole.onSecondaryFixed => onSecondaryFixed,
    ExpressiveColorRole.onSecondaryFixedVariant => onSecondaryFixedVariant,
    ExpressiveColorRole.onSurface => onSurface,
    ExpressiveColorRole.onSurfaceVariant => onSurfaceVariant,
    ExpressiveColorRole.onTertiary => onTertiary,
    ExpressiveColorRole.onTertiaryContainer => onTertiaryContainer,
    ExpressiveColorRole.onTertiaryFixed => onTertiaryFixed,
    ExpressiveColorRole.onTertiaryFixedVariant => onTertiaryFixedVariant,
    ExpressiveColorRole.outline => outline,
    ExpressiveColorRole.outlineVariant => outlineVariant,
    ExpressiveColorRole.primary => primary,
    ExpressiveColorRole.primaryContainer => primaryContainer,
    ExpressiveColorRole.primaryFixed => primaryFixed,
    ExpressiveColorRole.primaryFixedDim => primaryFixedDim,
    ExpressiveColorRole.scrim => scrim,
    ExpressiveColorRole.secondary => secondary,
    ExpressiveColorRole.secondaryContainer => secondaryContainer,
    ExpressiveColorRole.secondaryFixed => secondaryFixed,
    ExpressiveColorRole.secondaryFixedDim => secondaryFixedDim,
    ExpressiveColorRole.surface => surface,
    ExpressiveColorRole.surfaceBright => surfaceBright,
    ExpressiveColorRole.surfaceContainer => surfaceContainer,
    ExpressiveColorRole.surfaceContainerHigh => surfaceContainerHigh,
    ExpressiveColorRole.surfaceContainerHighest => surfaceContainerHighest,
    ExpressiveColorRole.surfaceContainerLow => surfaceContainerLow,
    ExpressiveColorRole.surfaceContainerLowest => surfaceContainerLowest,
    ExpressiveColorRole.surfaceDim => surfaceDim,
    ExpressiveColorRole.surfaceTint => surfaceTint,
    ExpressiveColorRole.surfaceVariant => surfaceVariant,
    ExpressiveColorRole.tertiary => tertiary,
    ExpressiveColorRole.tertiaryContainer => tertiaryContainer,
    ExpressiveColorRole.tertiaryFixed => tertiaryFixed,
    ExpressiveColorRole.tertiaryFixedDim => tertiaryFixedDim,
  };

  /// The content colour Material pairs with [color] when it is one of this
  /// scheme's container roles (Compose's `ColorScheme.contentColorFor`),
  /// else null.
  Color? contentColorFor(Color color) {
    for (final (container, content) in <(Color, Color)>[
      (primary, onPrimary),
      (secondary, onSecondary),
      (tertiary, onTertiary),
      (background, onBackground),
      (error, onError),
      (primaryContainer, onPrimaryContainer),
      (secondaryContainer, onSecondaryContainer),
      (tertiaryContainer, onTertiaryContainer),
      (errorContainer, onErrorContainer),
      (inverseSurface, inverseOnSurface),
      (surface, onSurface),
      (surfaceVariant, onSurfaceVariant),
      (surfaceBright, onSurface),
      (surfaceContainer, onSurface),
      (surfaceContainerHigh, onSurface),
      (surfaceContainerHighest, onSurface),
      (surfaceContainerLow, onSurface),
      (surfaceContainerLowest, onSurface),
      (surfaceDim, onSurface),
      (primaryFixed, onPrimaryFixed),
      (primaryFixedDim, onPrimaryFixed),
      (secondaryFixed, onSecondaryFixed),
      (secondaryFixedDim, onSecondaryFixed),
      (tertiaryFixed, onTertiaryFixed),
      (tertiaryFixedDim, onTertiaryFixed),
    ]) {
      if (container == color) return content;
    }
    return null;
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveColorScheme &&
      other.shadow == shadow &&
      ExpressiveColorRole.values.every((key) => other.role(key) == role(key));

  @override
  int get hashCode =>
      Object.hash(shadow, Object.hashAll(ExpressiveColorRole.values.map(role)));

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    for (final key in ExpressiveColorRole.values) {
      properties.add(ColorProperty(key.name, role(key)));
    }
    properties.add(ColorProperty('shadow', shadow));
  }
}
