import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Window classes independent of the desktop tiling threshold.
enum RetroDesktopWindowSizeClass {
  /// Under 600 logical pixels.
  compact,

  /// From 600 up to 840 logical pixels.
  medium,

  /// From 840 up to 1200 logical pixels.
  expanded,

  /// At least 1200 logical pixels.
  large;

  /// Classifies the available [width].
  static RetroDesktopWindowSizeClass ofWidth(double width) => width < 600
      ? compact
      : width < 840
      ? medium
      : width < 1200
      ? expanded
      : large;

  /// Classifies the window at [context].
  static RetroDesktopWindowSizeClass of(BuildContext context) =>
      ofWidth(MediaQuery.sizeOf(context).width);
}

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

  /// Reads the theme policy, respecting the platform's Reduce Motion setting.
  static RetroDesktopMotion of(BuildContext context) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) return still;
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
      (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
      ? Duration.zero
      : duration;

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
