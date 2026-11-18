/// Gloss's page change: the new page is set down on top, the one under it
/// sinks back a little and dims, as a moulded part pressed in; and its switch
/// between places.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/widgets.dart';

/// Gloss's push and pop, for a `PageTransitionsTheme` (an app's own, through
/// `glossPageTransitions`).
///
/// A pushed page rises 24 px into place and its glaze comes up from clear,
/// on a curve shaped like a settling spring; the page under it sinks back
/// (to 98.5% of its size) and dims, as a part pressed into its well. A pop
/// runs it backwards. Under Reduce Motion only the fade stays.
///
/// ```dart
/// final theme = ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: {TargetPlatform.android: GlossPageTransitionsBuilder()}));
/// ```
class GlossPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Gloss's page change.
  const GlossPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 380);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 300);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => GlossPageTransition(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    child: child,
  );
}

/// The motion [GlossPageTransitionsBuilder] plays, for a route of one's own.
class GlossPageTransition extends StatefulWidget {
  /// [child] arriving on [animation], sinking back on [secondaryAnimation].
  const GlossPageTransition({
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
  State<GlossPageTransition> createState() => _GlossPageTransitionState();

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

class _GlossPageTransitionState extends State<GlossPageTransition> {
  static const Curve _settle = _SpringCurve();

  late CurvedAnimation _arrive;
  late CurvedAnimation _fade;
  late CurvedAnimation _under;

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
    _fade = CurvedAnimation(
      parent: widget.animation,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.2, 1, curve: Curves.easeIn),
    );
    _under = CurvedAnimation(
      parent: widget.secondaryAnimation,
      curve: _settle,
      reverseCurve: Curves.easeInCubic,
    );
  }

  void _drop() {
    _arrive.dispose();
    _fade.dispose();
    _under.dispose();
  }

  @override
  void didUpdateWidget(GlossPageTransition old) {
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
    return AnimatedBuilder(
      animation: Listenable.merge([_arrive, _under]),
      child: widget.child,
      builder: (context, child) {
        final rise = still ? 0.0 : (1 - _arrive.value) * 24;
        final sink = still ? 1.0 : 1 - 0.015 * _under.value;
        final dim = still ? 0.0 : (_under.value * 0.18).clamp(0.0, 0.2);
        // One shape of tree at every moment, so the page keeps its state
        // as it dims.
        return FadeTransition(
          opacity: _fade,
          child: Transform.translate(
            offset: Offset(0, rise),
            child: Transform.scale(
              scale: sink,
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(10, 16, 22, dim),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A switch between places (a bottom bar's, a rail's or a sidebar's): the
/// place left fades as the new one rises 8 px out of the page and its glaze
/// comes up, on the settling spring's curve. Under Reduce Motion only the
/// fade stays.
///
/// [place] names the place shown; a new value plays the switch.
///
/// ```dart
/// GlossPlaceSwitch(place: selectedIndex, child: pages[selectedIndex])
/// ```
class GlossPlaceSwitch extends StatelessWidget {
  /// [child], the page of [place].
  const GlossPlaceSwitch({super.key, required this.place, required this.child});

  /// Which place [child] is; when it changes, the switch plays.
  final Object place;

  /// The place's page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 320),
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
          child: Transform.translate(
            offset: Offset(0, still ? 0 : (1 - animation.value) * 8),
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

/// A curve shaped like Gloss's settling spring (damping 0.82, stiffness 260 at
/// unit travel), normalised to end at 1.
class _SpringCurve extends Curve {
  const _SpringCurve();

  static final SpringSimulation _spring = SpringSimulation(
    SpringDescription.withDampingRatio(mass: 1, stiffness: 260, ratio: 0.82),
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
  double transformInternal(double t) => _spring.x(t * _span);
}
