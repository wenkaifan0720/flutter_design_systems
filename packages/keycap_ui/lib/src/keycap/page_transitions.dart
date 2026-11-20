/// How Keycap changes pages: the new page comes in a short way from the
/// reading end and settles, the page beneath goes down a step, as a key
/// does, and dims; back reverses it. A full-screen dialog rises from the
/// keyboard's front edge.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Keycap's page change, for a `PageTransitionsTheme`: the new page comes
/// [travel] pixels in from the reading end, opaque within the first tenth
/// of its run (about 30 ms), and settles without a bounce; the page beneath moves
/// [recede] pixels the other way and dims, as a key going down under a
/// finger. Under Reduce Motion it is a plain fade.
///
/// ```dart
/// ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: keycapPageTransitions))
/// ```
class KeycapPageTransitionsBuilder extends PageTransitionsBuilder {
  /// Keycap's page change.
  const KeycapPageTransitionsBuilder();

  /// How far the new page comes in.
  static const double travel = 28;

  /// How far the page beneath moves back.
  static const double recede = 10;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 260);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _PageSettle(
    animation: animation,
    secondaryAnimation: secondaryAnimation,
    rises: route.fullscreenDialog,
    child: child,
  );
}

/// Keycap's page change for every platform, for a `PageTransitionsTheme`;
/// on iOS wrapped in `DesignSwipeBackPageTransitionsBuilder`, so a swipe
/// from the screen's edge goes back.
///
/// ```dart
/// MaterialApp(theme: ThemeData(pageTransitionsTheme: const PageTransitionsTheme(builders: keycapPageTransitions)))
/// ```
const Map<TargetPlatform, PageTransitionsBuilder> keycapPageTransitions = {
  TargetPlatform.android: KeycapPageTransitionsBuilder(),
  TargetPlatform.fuchsia: KeycapPageTransitionsBuilder(),
  TargetPlatform.iOS: DesignSwipeBackPageTransitionsBuilder(
    KeycapPageTransitionsBuilder(),
  ),
  TargetPlatform.linux: KeycapPageTransitionsBuilder(),
  TargetPlatform.macOS: KeycapPageTransitionsBuilder(),
  TargetPlatform.windows: KeycapPageTransitionsBuilder(),
};

// A critically damped spring's way from 0 to 1, as a curve over the
// route's fixed duration: no overshoot, settled by the end.
class _SpringCurve extends Curve {
  const _SpringCurve(this.omega);

  final double omega;

  double _x(double t) => 1 - (1 + omega * t) * math.exp(-omega * t);

  @override
  double transformInternal(double t) => _x(t) / _x(1);
}

class _PageSettle extends StatefulWidget {
  const _PageSettle({
    required this.animation,
    required this.secondaryAnimation,
    required this.rises,
    required this.child,
  });

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final bool rises;
  final Widget child;

  @override
  State<_PageSettle> createState() => _PageSettleState();
}

class _PageSettleState extends State<_PageSettle> {
  // ω 8 over 0.3 s: settled by the end, never past it.
  static const _curve = _SpringCurve(8);

  late CurvedAnimation _in = _curved(widget.animation);
  late CurvedAnimation _under = _curved(widget.secondaryAnimation);

  CurvedAnimation _curved(Animation<double> parent) => CurvedAnimation(
    parent: parent,
    curve: _curve,
    reverseCurve: _curve.flipped,
  );

  @override
  void didUpdateWidget(_PageSettle old) {
    super.didUpdateWidget(old);
    if (old.animation != widget.animation) {
      _in.dispose();
      _in = _curved(widget.animation);
    }
    if (old.secondaryAnimation != widget.secondaryAnimation) {
      _under.dispose();
      _under = _curved(widget.secondaryAnimation);
    }
  }

  @override
  void dispose() {
    _in.dispose();
    _under.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final end = Directionality.of(context) == TextDirection.rtl ? -1.0 : 1.0;
    return AnimatedBuilder(
      animation: Listenable.merge([_in, _under]),
      child: widget.child,
      builder: (context, child) {
        final arrive = _in.value;
        final under = _under.value;
        if (still) {
          return Opacity(opacity: arrive.clamp(0.0, 1.0), child: child);
        }
        // Solid within the first tenth of its run, so the page beneath never
        // shows through the words.
        final opacity = (arrive / 0.12).clamp(0.0, 1.0);
        const travel = KeycapPageTransitionsBuilder.travel;
        final left = travel * (1 - arrive);
        final back = KeycapPageTransitionsBuilder.recede * under;
        final offset = widget.rises
            ? Offset(0, left * 1.5)
            : Offset(end * (left - back), 0);
        Widget page = Transform.translate(offset: offset, child: child);
        if (under > 0) {
          page = Stack(
            fit: StackFit.passthrough,
            children: [
              page,
              Positioned.fill(
                child: IgnorePointer(
                  child: ColoredBox(
                    color: Color.fromRGBO(20, 18, 16, 0.12 * under),
                  ),
                ),
              ),
            ],
          );
        }
        return Opacity(opacity: opacity, child: page);
      },
    );
  }
}

/// A page for a `Navigator.pages` list or a router that changes in
/// Keycap's way on every platform (iOS's edge swipe included).
///
/// ```dart
/// Navigator(pages: [KeycapPage(child: home)], onDidRemovePage: (page) {})
/// ```
class KeycapPage<T> extends Page<T> {
  /// A page holding [child].
  const KeycapPage({required this.child, super.key, super.name});

  /// The page's content.
  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _KeycapPageRoute<T>(this);
}

class _KeycapPageRoute<T> extends PageRoute<T> {
  _KeycapPageRoute(KeycapPage<T> page) : super(settings: page);

  PageTransitionsBuilder get _builder =>
      keycapPageTransitions[defaultTargetPlatform] ??
      const KeycapPageTransitionsBuilder();

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => _builder.transitionDuration;

  @override
  Duration get reverseTransitionDuration => _builder.reverseTransitionDuration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => (settings as KeycapPage<T>).child;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _builder.buildTransitions<T>(
    this,
    context,
    animation,
    secondaryAnimation,
    child,
  );
}
