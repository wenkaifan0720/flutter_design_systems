import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// How one part of the look looks, slot by slot, for its states: ui_core's
/// [RawStyle] under the look's own name.
typedef LookStyle = RawStyle;

/// The look's colours for one preset, by day or by night.
@immutable
class LookColors with Diagnosticable {
  /// Colours given one by one.
  const LookColors({
    required this.ground,
    required this.surface,
    required this.ink,
    required this.mutedInk,
    required this.rule,
    required this.accent,
    required this.onAccent,
    required this.danger,
    required this.onDanger,
  });

  /// The day colours.
  static const LookColors day = LookColors(
    ground: Color(0xFFF7F5F0),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF1C1B19),
    mutedInk: Color(0xFF6B675F),
    rule: Color(0xFFC9C4B8),
    accent: Color(0xFF2B4FD6),
    onAccent: Color(0xFFFFFFFF),
    danger: Color(0xFFB3261E),
    onDanger: Color(0xFFFFFFFF),
  );

  /// The night colours: the same roles, chosen for a dark ground, not
  /// inverted from the day's.
  static const LookColors night = LookColors(
    ground: Color(0xFF151413),
    surface: Color(0xFF201F1D),
    ink: Color(0xFFEDEAE3),
    mutedInk: Color(0xFFA39E94),
    rule: Color(0xFF4A4741),
    accent: Color(0xFF8EA6FF),
    onAccent: Color(0xFF101A44),
    danger: Color(0xFFFFB4AB),
    onDanger: Color(0xFF5F1410),
  );

  /// The page behind everything.
  final Color ground;

  /// A raised face: a card, a field, a dialog.
  final Color surface;

  /// Words and glyphs.
  final Color ink;

  /// Help, hints and anything turned off.
  final Color mutedInk;

  /// The look's one rule, round faces and between rows.
  final Color rule;

  /// The one colour that marks what acts.
  final Color accent;

  /// Words on [accent].
  final Color onAccent;

  /// What deletes or cannot be undone.
  final Color danger;

  /// Words on [danger].
  final Color onDanger;

  /// Between [a] and [b], role by role.
  static LookColors lerp(LookColors a, LookColors b, double t) => LookColors(
    ground: Color.lerp(a.ground, b.ground, t)!,
    surface: Color.lerp(a.surface, b.surface, t)!,
    ink: Color.lerp(a.ink, b.ink, t)!,
    mutedInk: Color.lerp(a.mutedInk, b.mutedInk, t)!,
    rule: Color.lerp(a.rule, b.rule, t)!,
    accent: Color.lerp(a.accent, b.accent, t)!,
    onAccent: Color.lerp(a.onAccent, b.onAccent, t)!,
    danger: Color.lerp(a.danger, b.danger, t)!,
    onDanger: Color.lerp(a.onDanger, b.onDanger, t)!,
  );

  List<Color> get _all => [
    ground,
    surface,
    ink,
    mutedInk,
    rule,
    accent,
    onAccent,
    danger,
    onDanger,
  ];

  @override
  bool operator ==(Object other) =>
      other is LookColors && listEquals(other._all, _all);

  @override
  int get hashCode => Object.hashAll(_all);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('ground', ground))
      ..add(ColorProperty('ink', ink))
      ..add(ColorProperty('accent', accent));
  }
}

/// The look's motion tokens: springs, each a damping ratio and a stiffness,
/// as ui_core runs them ([rawSpring], [RawMotionPolicy]).
@immutable
class LookMotion {
  /// Tokens given one by one.
  const LookMotion({
    this.stateDampingRatio = 1,
    this.stateStiffness = 1600,
    this.routeDampingRatio = 1,
    this.routeStiffness = 900,
  });

  /// A change of state (hover, focus, press, selection): a colour or a
  /// rule's weight, critically damped so it never overshoots.
  final double stateDampingRatio;

  /// How quickly a state change settles; 1600 settles in about 200 ms.
  final double stateStiffness;

  /// A route (a dialog, a sheet, a page) arriving or leaving.
  final double routeDampingRatio;

  /// How quickly a route settles.
  final double routeStiffness;

  @override
  bool operator ==(Object other) =>
      other is LookMotion &&
      other.stateDampingRatio == stateDampingRatio &&
      other.stateStiffness == stateStiffness &&
      other.routeDampingRatio == routeDampingRatio &&
      other.routeStiffness == routeStiffness;

  @override
  int get hashCode => Object.hash(
    stateDampingRatio,
    stateStiffness,
    routeDampingRatio,
    routeStiffness,
  );
}

/// Everything the look's parts read: colours, type, sizes, motion and each
/// part's theme slot.
@immutable
class LookThemeData with Diagnosticable {
  /// A theme given field by field.
  const LookThemeData({
    required this.colors,
    this.fontFamily = 'Roboto',
    this.capHeightFactor = 0.711,
    this.controlHeight = 44,
    this.radius = 8,
    this.density = RawDensity.standard,
    this.motion = const LookMotion(),
    this.buttonStyle,
  });

  /// The look by day.
  factory LookThemeData.day() => const LookThemeData(colors: LookColors.day);

  /// The look by night.
  factory LookThemeData.night() =>
      const LookThemeData(colors: LookColors.night);

  /// The look for [brightness]: what an app passes from
  /// `MediaQuery.platformBrightnessOf(context)`.
  factory LookThemeData.of(Brightness brightness) =>
      brightness == Brightness.dark
      ? LookThemeData.night()
      : LookThemeData.day();

  /// The colours.
  final LookColors colors;

  /// The typeface every part writes in. Any family the app loads works; the
  /// look never depends on one.
  final String fontFamily;

  /// [fontFamily]'s cap height over its font size, for [RawCapCenter].
  final double capHeightFactor;

  /// The one height every control that can share a row stands at.
  final double controlHeight;

  /// The corner every face takes.
  final double radius;

  /// How compact the controls' faces stand; never their tap targets.
  final RawDensity density;

  /// The springs.
  final LookMotion motion;

  /// Every button's style, under each button's own `style:`.
  final LookStyle? buttonStyle;

  /// A control label's words. Their colour comes from the face they stand
  /// on (a `LookSurface`).
  TextStyle get label => TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Body text.
  TextStyle get body => TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.45,
    color: colors.ink,
  );

  /// A heading.
  TextStyle get title => TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: colors.ink,
  );

  /// This theme with the given fields changed.
  LookThemeData copyWith({
    LookColors? colors,
    String? fontFamily,
    double? capHeightFactor,
    double? controlHeight,
    double? radius,
    RawDensity? density,
    LookMotion? motion,
    LookStyle? buttonStyle,
  }) => LookThemeData(
    colors: colors ?? this.colors,
    fontFamily: fontFamily ?? this.fontFamily,
    capHeightFactor: capHeightFactor ?? this.capHeightFactor,
    controlHeight: controlHeight ?? this.controlHeight,
    radius: radius ?? this.radius,
    density: density ?? this.density,
    motion: motion ?? this.motion,
    buttonStyle: buttonStyle ?? this.buttonStyle,
  );

  /// Between [a] and [b], as `ThemeData.lerp`: what an animated theme
  /// change (day to night) draws on the way.
  static LookThemeData lerp(LookThemeData a, LookThemeData b, double t) =>
      LookThemeData(
        colors: LookColors.lerp(a.colors, b.colors, t),
        fontFamily: t < .5 ? a.fontFamily : b.fontFamily,
        capHeightFactor: t < .5 ? a.capHeightFactor : b.capHeightFactor,
        controlHeight: lerpDouble(a.controlHeight, b.controlHeight, t)!,
        radius: lerpDouble(a.radius, b.radius, t)!,
        density: RawDensity.lerp(a.density, b.density, t),
        motion: t < .5 ? a.motion : b.motion,
        buttonStyle: RawStyle.lerp(a.buttonStyle, b.buttonStyle, t),
      );

  @override
  bool operator ==(Object other) =>
      other is LookThemeData &&
      other.colors == colors &&
      other.fontFamily == fontFamily &&
      other.capHeightFactor == capHeightFactor &&
      other.controlHeight == controlHeight &&
      other.radius == radius &&
      other.density == density &&
      other.motion == motion &&
      other.buttonStyle == buttonStyle;

  @override
  int get hashCode => Object.hash(
    colors,
    fontFamily,
    capHeightFactor,
    controlHeight,
    radius,
    density,
    motion,
    buttonStyle,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<LookColors>('colors', colors))
      ..add(StringProperty('fontFamily', fontFamily))
      ..add(DoubleProperty('controlHeight', controlHeight))
      ..add(DoubleProperty('radius', radius));
  }
}

/// Puts [data] round [child]: the look's theme, its tap-target floors, its
/// spacing grid and its default words and glyphs.
///
/// An app puts it in its `MaterialApp`, `CupertinoApp` or `WidgetsApp`
/// `builder`, so every route, dialog and overlay stands under it:
///
/// ```dart
/// MaterialApp(
///   builder: (context, child) => LookTheme(
///     data: LookThemeData.of(MediaQuery.platformBrightnessOf(context)),
///     child: child!,
///   ),
///   home: const Placeholder(),
/// )
/// ```
class LookTheme extends StatelessWidget {
  /// Applies [data] to [child].
  const LookTheme({super.key, required this.data, required this.child});

  /// The theme.
  final LookThemeData data;

  /// What stands under it.
  final Widget child;

  /// The nearest theme, or the day theme when there is none.
  static LookThemeData of(BuildContext context) =>
      maybeOf(context) ?? LookThemeData.day();

  /// The nearest theme, or null.
  static LookThemeData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_LookScope>()?.theme.data;

  @override
  Widget build(BuildContext context) => _LookScope(
    theme: this,
    child: RawTapTargetScope(
      targets: RawTapTargets.fallback,
      child: RawSpacingScope(
        spacing: RawSpacing.fallback,
        child: DefaultTextStyle(
          style: data.body,
          child: IconTheme(
            data: IconThemeData(color: data.colors.ink, size: 20),
            child: child,
          ),
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<LookThemeData>('data', data));
  }
}

class _LookScope extends InheritedTheme {
  const _LookScope({required this.theme, required super.child});

  final LookTheme theme;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      LookTheme(data: theme.data, child: child);

  @override
  bool updateShouldNotify(_LookScope old) => old.theme.data != theme.data;
}
