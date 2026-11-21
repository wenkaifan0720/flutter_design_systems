import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// Retro Desktop changes state instantly by default, as its desktop grammar did.
/// Apps can choose timing without replacing any component.
///
/// ```dart
/// RetroDesktopMotion(state: Duration(milliseconds: 100))
/// ```
@immutable
class RetroDesktopMotion {
  /// Sets independent state and route timings.
  const RetroDesktopMotion({
    this.press = Duration.zero,
    this.state = Duration.zero,
    this.move = Duration.zero,
    this.raise = Duration.zero,
    this.travel = Duration.zero,
    this.leave = Duration.zero,
    this.enter = Curves.linear,
    this.exit = Curves.linear,
    this.standard = Curves.linear,
  });

  /// Pointer and keyboard press feedback.
  final Duration press;

  /// Selection, check and toggle changes.
  final Duration state;

  /// Movement within a page.
  final Duration move;

  /// A raised surface entering.
  final Duration raise;

  /// A page or sheet entering.
  final Duration travel;

  /// A surface leaving.
  final Duration leave;

  /// Arrival, departure and state curves.
  final Curve enter, exit, standard;

  /// A policy with no animation.
  static const still = RetroDesktopMotion();

  /// Reads the theme policy, respecting the platform's Reduce Motion setting
  /// (Android's Remove animations, the web's prefers-reduced-motion, iOS's
  /// Reduce Motion: ui_core's `designReduceMotionOf`).
  static RetroDesktopMotion of(BuildContext context) {
    if (designReduceMotionOf(context)) return still;
    final motion = RetroDesktopTheme.of(context).motion;
    // Read neutral timing values so a copied policy file does not depend on the
    // package's concrete policy class retaining the same name.
    return RetroDesktopMotion(
      press: motion.press,
      state: motion.state,
      move: motion.move,
      raise: motion.raise,
      travel: motion.travel,
      leave: motion.leave,
      enter: motion.enter,
      exit: motion.exit,
      standard: motion.standard,
    );
  }

  /// Cuts an explicitly supplied duration when motion is disabled.
  static Duration durationOf(BuildContext context, Duration duration) =>
      designReduceMotionOf(context) ? Duration.zero : duration;

  /// Replaces selected policy values.
  RetroDesktopMotion copyWith({
    Duration? press,
    Duration? state,
    Duration? move,
    Duration? raise,
    Duration? travel,
    Duration? leave,
    Curve? enter,
    Curve? exit,
    Curve? standard,
  }) => RetroDesktopMotion(
    press: press ?? this.press,
    state: state ?? this.state,
    move: move ?? this.move,
    raise: raise ?? this.raise,
    travel: travel ?? this.travel,
    leave: leave ?? this.leave,
    enter: enter ?? this.enter,
    exit: exit ?? this.exit,
    standard: standard ?? this.standard,
  );

  /// Interpolates durations; curves change at the midpoint.
  static RetroDesktopMotion lerp(
    RetroDesktopMotion a,
    RetroDesktopMotion b,
    double t,
  ) {
    Duration mix(Duration x, Duration y) => Duration(
      microseconds: math.max(
        0,
        lerpDouble(x.inMicroseconds, y.inMicroseconds, t)!.round(),
      ),
    );
    return RetroDesktopMotion(
      press: mix(a.press, b.press),
      state: mix(a.state, b.state),
      move: mix(a.move, b.move),
      raise: mix(a.raise, b.raise),
      travel: mix(a.travel, b.travel),
      leave: mix(a.leave, b.leave),
      enter: t < .5 ? a.enter : b.enter,
      exit: t < .5 ? a.exit : b.exit,
      standard: t < .5 ? a.standard : b.standard,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RetroDesktopMotion &&
      press == other.press &&
      state == other.state &&
      move == other.move &&
      raise == other.raise &&
      travel == other.travel &&
      leave == other.leave &&
      enter == other.enter &&
      exit == other.exit &&
      standard == other.standard;
  @override
  int get hashCode => Object.hash(
    press,
    state,
    move,
    raise,
    travel,
    leave,
    enter,
    exit,
    standard,
  );
}

/// A page pushed the look's way: it stands in its place at once, as the period's screens changed, and goes the same
/// way when popped; nothing travels across the screen. With a [RetroDesktopMotion.travel] set, it fades in over that
/// time and out over [RetroDesktopMotion.leave], still in its place; Reduce Motion makes it instant again. Push your
/// app's own pages with it: a `MaterialPageRoute` takes your `MaterialApp`'s page transitions, the platform's slide or
/// zoom, unless you set them (the README's "Pages").
///
/// ```dart
/// RetroDesktopPageRoute<void>(builder: (context) => const Text('Project notes'))
/// ```
class RetroDesktopPageRoute<T> extends PageRoute<T> {
  /// Creates a [RetroDesktopPageRoute] that builds its page with [builder].
  RetroDesktopPageRoute({
    required this.builder,
    super.settings,
    super.fullscreenDialog,
    this.maintainState = true,
  });

  /// Builds the page.
  final WidgetBuilder builder;

  @override
  final bool maintainState;

  // The look's motion where the navigator stands (its theme above the app's pages), read as the route needs it.
  RetroDesktopMotion get _motion {
    final context = navigator?.context;
    return context == null
        ? RetroDesktopMotion.still
        : RetroDesktopMotion.of(context);
  }

  @override
  Duration get transitionDuration => _motion.travel;

  @override
  Duration get reverseTransitionDuration => _motion.leave;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => Semantics(
    scopesRoute: true,
    explicitChildNodes: true,
    child: builder(context),
  );

  CurvedAnimation? _fade;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final motion = RetroDesktopMotion.of(context);
    final page = motion.travel == Duration.zero && motion.leave == Duration.zero
        ? child
        : FadeTransition(
            opacity: _fade ??= CurvedAnimation(
              parent: animation,
              curve: motion.enter,
              reverseCurve: motion.exit,
            ),
            child: child,
          );
    // On iOS the swipe back from the screen's edge pops it, as it does every page there (ui_core's swipe back).
    return defaultTargetPlatform == TargetPlatform.iOS
        ? const SwipeBackPageTransitionsBuilder(
            _AsBuilt(),
          ).buildTransitions(this, context, animation, secondaryAnimation, page)
        : page;
  }

  @override
  void dispose() {
    _fade?.dispose();
    super.dispose();
  }
}

// The page as [RetroDesktopPageRoute] built it, for ui_core's swipe back to stand round.
class _AsBuilt extends PageTransitionsBuilder {
  const _AsBuilt();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => child;
}

/// The keyboard focus outline: [width] of [color], [gap] outside the focused part's own outline and concentric with it.
@immutable
class RetroDesktopFocusRing {
  /// Draws [width] logical pixels of [color], [gap] outside the part, or
  /// [gap] inside it when [inside]; [dotted] draws it one pixel on, one off.
  const RetroDesktopFocusRing({
    required this.color,
    this.width = 2,
    this.gap = 2,
    this.inside = false,
    this.dotted = false,
  });

  /// Outline ink.
  final Color color;

  /// Outline thickness.
  final double width;

  /// Space between the part's outline and the ring; the ring's radius is the
  /// part's plus this (outside) or minus it (inside).
  final double gap;

  /// Whether the ring stands inside the part's face, as the Chisel appearance's
  /// dotted focus rectangle does, rather than outside it.
  final bool inside;

  /// Whether the ring is drawn dotted, one pixel on and one off.
  final bool dotted;

  /// Replaces one of the outline tokens.
  RetroDesktopFocusRing copyWith({
    Color? color,
    double? width,
    double? gap,
    bool? inside,
    bool? dotted,
  }) => RetroDesktopFocusRing(
    color: color ?? this.color,
    width: width ?? this.width,
    gap: gap ?? this.gap,
    inside: inside ?? this.inside,
    dotted: dotted ?? this.dotted,
  );

  /// Blends outlines when a theme changes.
  static RetroDesktopFocusRing lerp(
    RetroDesktopFocusRing a,
    RetroDesktopFocusRing b,
    double t,
  ) => RetroDesktopFocusRing(
    color: Color.lerp(a.color, b.color, t)!,
    width: math.max(0, lerpDouble(a.width, b.width, t)!),
    gap: math.max(0, lerpDouble(a.gap, b.gap, t)!),
    inside: t < .5 ? a.inside : b.inside,
    dotted: t < .5 ? a.dotted : b.dotted,
  );
  @override
  bool operator ==(Object other) =>
      other is RetroDesktopFocusRing &&
      color == other.color &&
      width == other.width &&
      gap == other.gap &&
      inside == other.inside &&
      dotted == other.dotted;
  @override
  int get hashCode => Object.hash(color, width, gap, inside, dotted);
}
