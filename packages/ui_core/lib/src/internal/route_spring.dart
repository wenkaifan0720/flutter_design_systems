/// What ui_core's modal routes share: one spring for every open and close,
/// focus given back as they close, and Escape that closes them even where a
/// barrier tap does not. Inside ui_core; not exported.
library;

import 'dart:async' show unawaited;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../motion.dart';
import 'quiet_focus.dart';

/// Whether Reduce Motion is on at [context], read without depending on it:
/// a route reads it as it is pushed or popped, outside a build.
bool reduceMotionNow(BuildContext context) {
  final media = context.getInheritedWidgetOfExactType<MediaQuery>()?.data;
  return (media?.disableAnimations ?? false) ||
      WidgetsBinding
          .instance
          .platformDispatcher
          .accessibilityFeatures
          .reduceMotion;
}

/// A route's motion: one spring token (ζ, k) drives the route's controller,
/// which Flutter keeps inside 0 to 1 (its barrier and its lifecycle read it),
/// and [presence], the same spring unclamped, so a panel shows an
/// underdamped token's overshoot. Closing (to 0) runs on the close token,
/// the open token unless the route gives its own. Under Reduce Motion the
/// route fades on the effects spring instead ([DesignMotionPolicy.effects]).
class RouteSpring {
  /// The motion of a route whose token is ([dampingRatio], [stiffness]),
  /// closing on ([closeDampingRatio], [closeStiffness]) when given.
  RouteSpring({
    required this.dampingRatio,
    required this.stiffness,
    double? closeDampingRatio,
    double? closeStiffness,
  }) : closeDampingRatio = closeDampingRatio ?? dampingRatio,
       closeStiffness = closeStiffness ?? stiffness;

  /// The token's damping ratio (ζ).
  final double dampingRatio;

  /// The token's stiffness (k).
  final double stiffness;

  /// The close token's damping ratio: [dampingRatio] unless given.
  final double closeDampingRatio;

  /// The close token's stiffness: [stiffness] unless given.
  final double closeStiffness;

  AnimationController? _controller;
  Simulation? _simulation;

  /// The route's presence on its spring, unclamped: 0 gone, 1 open, past 1
  /// while an underdamped token overshoots.
  late final Animation<double> presence = _Presence(this);

  /// Whether the route last chose the Reduce Motion fade.
  bool reduced = false;

  /// A speed (route units a second) the next [simulation] starts at, once:
  /// a drag's, let go to close.
  double? carry;

  /// Drives [controller], the route's own.
  void attach(AnimationController controller) => _controller = controller;

  /// The spring the route runs at [context] now: [closing], the close
  /// token's. Under Reduce Motion either is a short fade on the effects
  /// spring.
  SpringDescription springAt(BuildContext context, {bool closing = false}) {
    reduced = reduceMotionNow(context);
    final policy = DesignMotionPolicy(reduceMotion: reduced);
    final zeta = closing ? closeDampingRatio : dampingRatio;
    final k = closing ? closeStiffness : stiffness;
    return reduced
        ? policy.effects(dampingRatio: zeta, stiffness: k)
        : policy.spatial(dampingRatio: zeta, stiffness: k);
  }

  /// The simulation from where the route is to [to], at [velocity] (route
  /// units a second; the controller's own when null, or a drag's [carry]),
  /// on the close token when [to] is 0. Kept, so [presence] reads it
  /// unclamped.
  Simulation simulation(
    BuildContext context, {
    required double to,
    double? velocity,
  }) {
    final c = _controller!;
    return _simulation = designSpringSimulation(
      springAt(context, closing: to <= 0),
      from: c.value,
      to: to,
      velocity: velocity ?? _takeCarry() ?? c.velocity,
    );
  }

  double? _takeCarry() {
    final v = carry;
    carry = null;
    return v;
  }

  /// Runs the controller to [to] on the spring (a settle after a drag),
  /// forward or back by where [to] lies.
  TickerFuture settle(BuildContext context, double to, {double? velocity}) {
    final c = _controller!;
    final simulation = this.simulation(context, to: to, velocity: velocity);
    return to >= c.value
        ? c.animateWith(simulation)
        : c.animateBackWith(simulation);
  }
}

// The route's controller, read through the spring driving it so it is not
// clamped: an underdamped token passes 1 and comes back.
class _Presence extends Animation<double>
    with AnimationWithParentMixin<double> {
  _Presence(this.spring);

  final RouteSpring spring;

  @override
  Animation<double> get parent => spring._controller!;

  @override
  double get value {
    final c = spring._controller;
    if (c == null) return 0;
    final simulation = spring._simulation;
    final elapsed = c.lastElapsedDuration;
    if (!c.isAnimating || simulation == null || elapsed == null) {
      return c.value;
    }
    return simulation.x(
      elapsed.inMicroseconds / Duration.microsecondsPerSecond,
    );
  }
}

/// The node that held focus as a route opened, given focus back as it
/// closes, quietly (a field given focus back does not reopen its list).
class RouteFocusReturn {
  FocusNode? _opener;

  /// Notes the node that holds focus now.
  void capture() => _opener = FocusManager.instance.primaryFocus;

  /// Gives focus back to the noted node, while it can take it.
  void giveBack() {
    final node = _opener;
    _opener = null;
    if (node == null || node.context == null || !node.canRequestFocus) return;
    DesignQuietFocus.restore(node);
  }
}

/// [child] with Escape closing its route through `maybePop`, even where the
/// route's barrier does not dismiss (an alert): Flutter's own Escape on a
/// modal route goes only as far as its barrier. It closes the route however
/// the focus sits: inside the route, or on the route's own scope, where it
/// rests from the push until something in the route takes it (a dialog with
/// no field and no button that takes the focus on opening), above these
/// actions. Escape that something in the route handles (a list's, a field's)
/// stays theirs. Place it at the top of the route's page, under the route's
/// focus scope and no other.
Widget escapeCloses(BuildContext context, Widget child) =>
    _EscapeCloses(child: child);

class _EscapeCloses extends StatefulWidget {
  const _EscapeCloses({required this.child});

  final Widget child;

  @override
  State<_EscapeCloses> createState() => _EscapeClosesState();
}

class _EscapeClosesState extends State<_EscapeCloses> {
  // The route's focus scope, whose key handler this one stands in front of
  // while it is mounted.
  FocusScopeNode? _scope;
  FocusOnKeyEventCallback? _given;
  ModalRoute<Object?>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
    final scope = FocusScope.of(context);
    if (identical(scope, _scope)) return;
    _unhook();
    _scope = scope;
    _given = scope.onKeyEvent;
    scope.onKeyEvent = _atScope;
  }

  void _unhook() {
    final scope = _scope;
    if (scope != null && scope.onKeyEvent == _atScope) {
      scope.onKeyEvent = _given;
    }
    _scope = null;
    _given = null;
  }

  @override
  void dispose() {
    _unhook();
    super.dispose();
  }

  // Escape reaching the route's scope with the focus on the scope itself.
  KeyEventResult _atScope(FocusNode node, KeyEvent event) {
    final handled = _given?.call(node, event) ?? KeyEventResult.ignored;
    if (handled != KeyEventResult.ignored) return handled;
    final keyboard = HardwareKeyboard.instance;
    final route = _route;
    if (event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.escape ||
        keyboard.isShiftPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isMetaPressed ||
        FocusManager.instance.primaryFocus != _scope ||
        route == null ||
        !route.isCurrent) {
      return KeyEventResult.ignored;
    }
    unawaited(Navigator.of(context).maybePop());
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) => Actions(
    actions: {
      DismissIntent: CallbackAction<DismissIntent>(
        onInvoke: (_) => Navigator.of(context).maybePop(),
      ),
    },
    child: widget.child,
  );
}
