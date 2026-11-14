/// Expressive's motion: [ExpressiveMotion], the springs a theme's components
/// move with (CONTRACT §2 "Motion"; wave decision E6). Owner: w1-motion,
/// with `internal/motion/`, the generator's `emit/motion.ts`, the gallery's
/// motion demo and `test/motion_test.dart`.
///
/// A scheme is six springs, spatial (moves, resizes, reshapes) and effects
/// (opacity, colour), each fast, default and slow — Compose's
/// `ExpressiveMotionTokens` / `StandardMotionTokens`, generated from the
/// pinned jar into `internal/tokens/` and mapped through the design kit's
/// `designSpring` (mass 1, stiffness k, damping 2ζ√k):
///
/// | Scheme | spatial fast · default · slow (ζ/k) | effects fast · default · slow |
/// | --- | --- | --- |
/// | Expressive | 0.6/800 · 0.8/380 · 0.8/200 | 1.0/3800 · 1.0/1600 · 1.0/800 |
/// | Standard | 0.9/1400 · 0.9/700 · 0.9/300 | same |
///
/// How a component moves: it names a spring by [ExpressiveMotionKey] (the
/// key Compose's component code uses, generated into the behaviour
/// constants) and reads it where it runs, with [ExpressiveMotion.of] (or
/// `context.expressiveMotion`), which applies the three things the theme
/// alone does not know:
///
/// - the theme's scheme (`context.expressiveTheme.motion`);
/// - a subtree pinned to Standard ([ExpressiveStandardMotion]; an
///   Expressive app may calm dense data, a Standard app never bounces, so
///   nothing pins Expressive);
/// - Reduce Motion, the kit's [DesignMotionPolicy]: spatial springs critically
///   damped (ζ = 1 at the token's stiffness), effects unchanged.
///
/// Then it runs the spring: `controller.springTo(target, spring)` (the
/// kit's [DesignSpringDrive], exported here), or one of the implicit helpers —
/// [ExpressiveSpringValue] for a number, [ExpressiveSpringTween] for any
/// lerpable value, [ExpressiveSpringColor], [ExpressiveSpringSize] and
/// [ExpressiveSpringShape]. Nothing here takes a duration or a curve.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/motion/baked_motion.dart';
import 'internal/tokens/keys.g.dart';
import 'theme.dart';

export 'package:ui_core/ui_core.dart'
    show
        DesignMotionPolicy,
        DesignSpringDrive,
        designSpringSimulation,
        designSpringTolerance;

export 'internal/tokens/keys.g.dart' show ExpressiveMotionKey;

/// A spring's pace: Compose's fast, default and slow.
enum ExpressiveMotionSpeed {
  /// Small components and quick feedback: a press, a toggle, a check.
  fast,

  /// Compose's `default`: most transitions.
  normal,

  /// Large surfaces and long travel: a sheet, a full-screen change.
  slow,
}

/// A spring token as the scheme states it, before Reduce Motion: damping
/// ratio ζ and stiffness k (unit mass).
typedef ExpressiveSpringToken = ({double dampingRatio, double stiffness});

/// The motion of one theme, or of one place in the tree ([of]).
@immutable
class ExpressiveMotion with Diagnosticable {
  /// A motion of the given [scheme], reduced when [reduceMotion].
  const ExpressiveMotion({required this.scheme, this.reduceMotion = false});

  /// The motion in force at [context]: the theme's scheme, Standard inside
  /// an [ExpressiveStandardMotion], and Reduce Motion when the platform asks
  /// animations to be disabled. What every component reads.
  factory ExpressiveMotion.of(BuildContext context) => ExpressiveMotion(
    scheme: ExpressiveStandardMotion.pinnedAt(context)
        ? ExpressiveMotionScheme.standard
        : context.expressiveTheme.motion.scheme,
    reduceMotion: DesignMotionPolicy.of(context).reduceMotion,
  );

  /// The scheme the springs come from.
  final ExpressiveMotionScheme scheme;

  /// Whether spatial springs are critically damped (Reduce Motion).
  final bool reduceMotion;

  /// This motion with [scheme] or [reduceMotion] replaced.
  ///
  /// ```dart
  /// context.expressiveTheme.motion.copyWith(scheme: ExpressiveMotionScheme.standard)
  /// ```
  ExpressiveMotion copyWith({
    ExpressiveMotionScheme? scheme,
    bool? reduceMotion,
  }) => ExpressiveMotion(
    scheme: scheme ?? this.scheme,
    reduceMotion: reduceMotion ?? this.reduceMotion,
  );

  /// [a] until halfway, then [b]: a scheme is a set of springs, not a
  /// value between two others, so a theme's lerp switches it.
  static ExpressiveMotion lerp(
    ExpressiveMotion a,
    ExpressiveMotion b,
    double t,
  ) => t < .5 ? a : b;

  /// The kit's policy this motion runs under.
  DesignMotionPolicy get policy =>
      DesignMotionPolicy(reduceMotion: reduceMotion);

  /// The scheme's token for [key], as generated, before Reduce Motion.
  ExpressiveSpringToken tokenOf(ExpressiveMotionKey key) {
    final token = expressiveSpringTokenOf(scheme, key);
    return (dampingRatio: token.dampingRatio, stiffness: token.stiffness);
  }

  /// Whether [key] moves, resizes or reshapes (spatial) rather than fades or
  /// recolours (effects).
  static bool isSpatial(ExpressiveMotionKey key) => expressiveIsSpatialKey(key);

  /// The spring [key] runs here: the scheme's token through the kit's
  /// policy (a spatial spring critically damped under Reduce Motion).
  SpringDescription spring(ExpressiveMotionKey key) {
    final token = expressiveSpringTokenOf(scheme, key);
    return expressiveIsSpatialKey(key)
        ? policy.spatial(
            dampingRatio: token.dampingRatio,
            stiffness: token.stiffness,
          )
        : policy.effects(
            dampingRatio: token.dampingRatio,
            stiffness: token.stiffness,
          );
  }

  /// The spatial spring at [speed].
  SpringDescription spatial([
    ExpressiveMotionSpeed speed = ExpressiveMotionSpeed.normal,
  ]) => spring(switch (speed) {
    ExpressiveMotionSpeed.fast => ExpressiveMotionKey.fastSpatial,
    ExpressiveMotionSpeed.normal => ExpressiveMotionKey.defaultSpatial,
    ExpressiveMotionSpeed.slow => ExpressiveMotionKey.slowSpatial,
  });

  /// The effects spring at [speed].
  SpringDescription effects([
    ExpressiveMotionSpeed speed = ExpressiveMotionSpeed.normal,
  ]) => spring(switch (speed) {
    ExpressiveMotionSpeed.fast => ExpressiveMotionKey.fastEffects,
    ExpressiveMotionSpeed.normal => ExpressiveMotionKey.defaultEffects,
    ExpressiveMotionSpeed.slow => ExpressiveMotionKey.slowEffects,
  });

  /// Compose's `fastSpatialSpec`.
  SpringDescription get fastSpatial => spring(ExpressiveMotionKey.fastSpatial);

  /// Compose's `defaultSpatialSpec`.
  SpringDescription get defaultSpatial =>
      spring(ExpressiveMotionKey.defaultSpatial);

  /// Compose's `slowSpatialSpec`.
  SpringDescription get slowSpatial => spring(ExpressiveMotionKey.slowSpatial);

  /// Compose's `fastEffectsSpec`.
  SpringDescription get fastEffects => spring(ExpressiveMotionKey.fastEffects);

  /// Compose's `defaultEffectsSpec`.
  SpringDescription get defaultEffects =>
      spring(ExpressiveMotionKey.defaultEffects);

  /// Compose's `slowEffectsSpec`.
  SpringDescription get slowEffects => spring(ExpressiveMotionKey.slowEffects);

  @override
  bool operator ==(Object other) =>
      other is ExpressiveMotion &&
      other.scheme == scheme &&
      other.reduceMotion == reduceMotion;

  @override
  int get hashCode => Object.hash(scheme, reduceMotion);

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(EnumProperty<ExpressiveMotionScheme>('scheme', scheme))
      ..add(
        FlagProperty(
          'reduceMotion',
          value: reduceMotion,
          ifTrue: 'reduce motion',
        ),
      );
  }
}

/// `context.expressiveMotion`: [ExpressiveMotion.of].
extension ExpressiveMotionContext on BuildContext {
  /// The motion in force here ([ExpressiveMotion.of]).
  ExpressiveMotion get expressiveMotion => ExpressiveMotion.of(this);
}

/// Pins everything below it to the Standard scheme: an Expressive app's
/// dense data, a settings list, a table. The swap goes one way (CONTRACT §2):
/// nothing pins Expressive, so a Standard app never bounces. It follows its
/// subtree into overlays and routes that capture themes.
class ExpressiveStandardMotion extends InheritedTheme {
  /// A scope pinning [child] to the Standard scheme.
  const ExpressiveStandardMotion({required super.child, super.key});

  /// Whether [context] is inside an [ExpressiveStandardMotion].
  static bool pinnedAt(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ExpressiveStandardMotion>() !=
      null;

  @override
  Widget wrap(BuildContext context, Widget child) =>
      ExpressiveStandardMotion(child: child);

  @override
  bool updateShouldNotify(ExpressiveStandardMotion oldWidget) => false;
}

/// Linear interpolation of [T] at `t` (which a spatial spring carries past
/// 1 when it overshoots).
typedef ExpressiveLerp<T> = T Function(T a, T b, double t);

/// A number that springs to each new [value] on the spring [motion] names,
/// in the value's own units: a retarget mid-flight keeps its momentum, and
/// an underdamped spring overshoots [value] before it settles exactly on it.
class ExpressiveSpringValue extends StatefulWidget {
  /// A number that springs to [value] on [motion], built by [builder].
  const ExpressiveSpringValue({
    required this.value,
    required this.motion,
    required this.builder,
    this.child,
    super.key,
  });

  /// The value to spring to. The first build shows it without motion.
  final double value;

  /// The spring, read at [ExpressiveMotion.of] when [value] changes.
  final ExpressiveMotionKey motion;

  /// Builds the subtree at the current value.
  final ValueWidgetBuilder<double> builder;

  /// Passed through to [builder] unchanged.
  final Widget? child;

  @override
  State<ExpressiveSpringValue> createState() => _ExpressiveSpringValueState();
}

class _ExpressiveSpringValueState extends State<ExpressiveSpringValue>
    with SingleTickerProviderStateMixin {
  // An unchanged surface needs no ticker or animation element. Keep the
  // builder at one stable position when its first animation starts.
  AnimationController? _controller;

  void _tick() => setState(() {});

  @override
  void didUpdateWidget(ExpressiveSpringValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final controller = _controller ??= AnimationController.unbounded(
        vsync: this,
        value: oldWidget.value,
      )..addListener(_tick);
      controller.springTo(
        widget.value,
        ExpressiveMotion.of(context).spring(widget.motion),
      );
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _controller?.value ?? widget.value, widget.child);
}

/// A value of any lerpable type that springs to each new [value] on the
/// spring [motion] names: the spring runs the progress from the value shown
/// when [value] changed to the new one, through [lerp] (so an underdamped
/// spring carries the lerp past the target before it settles exactly on
/// it). A retarget starts the new leg from where the value is, at rest.
class ExpressiveSpringTween<T> extends StatefulWidget {
  /// A value that springs to [value] on [motion], interpolated by [lerp] and built by [builder].
  const ExpressiveSpringTween({
    required this.value,
    required this.motion,
    required this.lerp,
    required this.builder,
    this.child,
    super.key,
  });

  /// The value to spring to. The first build shows it without motion.
  final T value;

  /// The spring, read at [ExpressiveMotion.of] when [value] changes.
  final ExpressiveMotionKey motion;

  /// How [T] interpolates.
  final ExpressiveLerp<T> lerp;

  /// Builds the subtree at the current value.
  final ValueWidgetBuilder<T> builder;

  /// Passed through to [builder] unchanged.
  final Widget? child;

  @override
  State<ExpressiveSpringTween<T>> createState() =>
      _ExpressiveSpringTweenState<T>();
}

class _ExpressiveSpringTweenState<T> extends State<ExpressiveSpringTween<T>>
    with SingleTickerProviderStateMixin {
  AnimationController? _progress;
  late T _from = widget.value;
  late T _to = widget.value;

  T get _current =>
      _progress == null ? _to : widget.lerp(_from, _to, _progress!.value);

  void _tick() => setState(() {});

  @override
  void didUpdateWidget(ExpressiveSpringTween<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _to) {
      _from = _current;
      _to = widget.value;
      final progress = _progress ??= AnimationController.unbounded(
        vsync: this,
        value: 1,
      )..addListener(_tick);
      progress.value = 0;
      progress.springTo(
        1,
        ExpressiveMotion.of(context).spring(widget.motion),
        velocity: 0,
      );
    }
  }

  @override
  void dispose() {
    _progress?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _current, widget.child);
}

Color _lerpColor(Color a, Color b, double t) => Color.lerp(a, b, t)!;

Size _lerpSize(Size a, Size b, double t) => Size.lerp(a, b, t)!;

ShapeBorder _lerpShape(ShapeBorder a, ShapeBorder b, double t) =>
    ShapeBorder.lerp(a, b, t)!;

/// A colour that springs to each new [value] (an effects key, usually).
class ExpressiveSpringColor extends ExpressiveSpringTween<Color> {
  /// A colour that springs to [value] on [motion], built by [builder].
  const ExpressiveSpringColor({
    required super.value,
    required super.motion,
    required super.builder,
    super.child,
    super.key,
  }) : super(lerp: _lerpColor);
}

/// A size that springs to each new [value] (a spatial key, usually).
class ExpressiveSpringSize extends ExpressiveSpringTween<Size> {
  /// A size that springs to [value] on [motion], built by [builder].
  const ExpressiveSpringSize({
    required super.value,
    required super.motion,
    required super.builder,
    super.child,
    super.key,
  }) : super(lerp: _lerpSize);
}

/// A shape that springs to each new [value] through [ShapeBorder.lerp] (a
/// spatial key, usually: a press or selection morph). A shape morph between
/// library polygons is `shape.dart`'s; this one reshapes corners.
class ExpressiveSpringShape extends ExpressiveSpringTween<ShapeBorder> {
  /// A shape that springs to [value] on [motion], built by [builder].
  const ExpressiveSpringShape({
    required super.value,
    required super.motion,
    required super.builder,
    super.child,
    super.key,
  }) : super(lerp: _lerpShape);
}
