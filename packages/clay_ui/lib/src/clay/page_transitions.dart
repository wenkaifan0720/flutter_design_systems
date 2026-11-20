/// Clay's page change: the page under settles back and sinks into the
/// ground, then the new page inflates into place; and its switch between
/// places.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// Clay's push and pop, for a `PageTransitionsTheme` (an app's own, through
/// `clayPageTransitions`).
///
/// The page under settles back to 97% and sinks into the ground (its words
/// gone before the new page's come, so the two never read over each other);
/// the pushed page then fades in, inflating from 95% of its size to its own
/// on a calm spring with no overshoot. A pop runs it backwards. Under Reduce
/// Motion only the fades stay.
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: ClayPageTransitionsBuilder()}))
/// ```
class ClayPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Clay's page change.
  const ClayPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 340);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => ClayPageTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}

/// The motion [ClayPageTransitionsBuilder] plays, for a route of one's own.
class ClayPageTransition extends StatefulWidget {
  /// [child] arriving on [animation], settling back on [secondaryAnimation].
  const ClayPageTransition({
    super.key,
    required this.animation,
    required this.secondaryAnimation,
    required this.child,
  });

  /// The page's own arrival (0 away, 1 in place).
  final Animation<double> animation;

  /// A page pushed over this one (0 none, 1 covering it).
  final Animation<double> secondaryAnimation;

  /// The page.
  final Widget child;

  @override
  State<ClayPageTransition> createState() => _ClayPageTransitionState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<Animation<double>>('animation', animation))
      ..add(
        DiagnosticsProperty<Animation<double>>(
          'secondaryAnimation',
          secondaryAnimation,
        ),
      );
  }
}

class _ClayPageTransitionState extends State<ClayPageTransition> {
  static const Curve _settle = _SpringCurve();

  late CurvedAnimation _arrive;
  late CurvedAnimation _fade;
  late CurvedAnimation _under;
  late CurvedAnimation _sink;

  @override
  void initState() {
    super.initState();
    _curve();
  }

  void _curve() {
    _arrive = CurvedAnimation(
      parent: widget.animation,
      curve: _settle,
      reverseCurve: Curves.easeInCubic,
    );
    // The new page comes once the one under has mostly sunk; on a pop it
    // goes first, and the one under rises after it.
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0.35, 0.95, curve: Curves.easeOut),
      reverseCurve: const Interval(0.45, 1, curve: Curves.easeIn),
    );
    _under = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _settle,
      reverseCurve: Curves.easeInCubic,
    );
    _sink = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: const Interval(0.05, 0.45, curve: Curves.easeIn),
    );
  }

  void _drop() {
    _arrive.dispose();
    _fade.dispose();
    _under.dispose();
    _sink.dispose();
  }

  @override
  void didUpdateWidget(ClayPageTransition old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation ||
        old.secondaryAnimation != widget.secondaryAnimation) {
      _drop();
      _curve();
    }
  }

  @override
  void dispose() {
    _drop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final ground =
        ClayTheme.maybeOf(context)?.colors.ground ?? const Color(0xFFECEAF6);
    return AnimatedBuilder(
      animation: Listenable.merge([_arrive, _under, _sink]),
      child: widget.child,
      builder: (context, child) {
        final grow = still ? 1.0 : 0.95 + 0.05 * _arrive.value;
        final settle = still ? 1.0 : 1 - 0.03 * _under.value;
        // One shape of tree at every moment, so the page keeps its state
        // as it moves. The ground is painted over the page under, not faded
        // through it, so nothing behind the navigator shows.
        return FadeTransition(
          opacity: _fade,
          child: Transform.scale(
            scale: grow * settle,
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                color: ground.withValues(alpha: _sink.value.clamp(0.0, 1.0)),
              ),
              child: child,
            ),
          ),
        );
      },
    );
  }
}

/// A switch between places (a bottom bar's, a rail's or a sidebar's): the
/// place left fades as the new one inflates from 98% of its size, on Clay's
/// calm spring. Under Reduce Motion only the fade stays.
///
/// [place] names the place shown; a new value plays the switch.
///
/// ```dart
/// ClayPlaceSwitch(place: 1, child: const Text('Habits'))
/// ```
class ClayPlaceSwitch extends StatelessWidget {
  /// [child], the page of [place].
  const ClayPlaceSwitch({super.key, required this.place, required this.child});

  /// Which place [child] is; when it changes, the switch plays.
  final Object place;

  /// The place's page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      reverseDuration: const Duration(milliseconds: 140),
      switchInCurve: const _SpringCurve(),
      switchOutCurve: Curves.easeOut,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.passthrough, children: [...previous, ?current]),
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        child: child,
        builder: (context, child) => Opacity(
          opacity: Curves.easeOut.transform(
            (animation.value / 0.6).clamp(0.0, 1.0),
          ),
          child: Transform.scale(
            scale: still ? 1 : 0.98 + 0.02 * animation.value,
            child: child,
          ),
        ),
      ),
      child: KeyedSubtree(key: ValueKey<Object>(place), child: child),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('place', place));
  }
}

/// A curve shaped like Clay's calm spring (critically damped, stiffness 300
/// at unit travel), normalised to end at 1: it arrives and stops, with no
/// overshoot.
class _SpringCurve extends Curve {
  const _SpringCurve();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 300, ratio: 1),
    0,
    1,
    0,
  );

  // The simulation's time to settle within a thousandth, measured once.
  static final double _span = () {
    var t = 0.0;
    while (t < 3) {
      if ((_spring.x(t) - 1).abs() < 0.001 && _spring.dx(t).abs() < 0.01) {
        return t;
      }
      t += 0.005;
    }
    return 3.0;
  }();

  @override
  double transformInternal(double t) =>
      t >= 1 ? 1 : _spring.x(t * _span).clamp(0.0, 1.0);
}
