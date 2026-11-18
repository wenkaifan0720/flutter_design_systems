/// A side sheet, headless: a modal route whose panel slides in from the
/// start or end edge, under a barrier. Focus moves into it and back to the
/// opener when it closes; Escape (wherever the focus is in it, and when its
/// barrier does not dismiss), a barrier tap and a drag toward its edge close
/// it; under Reduce Motion it fades instead of sliding.
library;

import 'package:flutter/widgets.dart';

import 'barrier.dart';
import 'internal/gesture_focus.dart';
import 'internal/painted_barrier.dart';
import 'internal/route_spring.dart';
import 'localizations.dart';
import 'motion.dart';

/// Which edge a [DesignSideSheetRoute] comes from.
enum DesignSheetEdge {
  /// The reading start (left in English, right in Arabic).
  start,

  /// The reading end.
  end,
}

/// What a side sheet's panel gets to paint with.
@immutable
class DesignSheetInfo {
  /// The sheet's info; the route makes it.
  const DesignSheetInfo({
    required this.side,
    required this.animation,
    required this.dragging,
    required this.close,
  });

  /// The side it is on, resolved for the text direction
  /// ([AxisDirection.left] or [AxisDirection.right]).
  final AxisDirection side;

  /// Its presence, 0 (gone) to 1 (open), for a look's own fades.
  final Animation<double> animation;

  /// Whether a finger is dragging it.
  final bool dragging;

  /// Closes it (its close button).
  final VoidCallback close;
}

/// A modal side sheet. Push it with `Navigator.push`; its panel is
/// [builder]'s, sized to [width] (at most the screen less [minGap]) and the
/// full height.
///
/// It opens, settles and closes on a spring ([dampingRatio], [stiffness]),
/// or closes on its own ([closeDampingRatio], [closeStiffness]), from
/// wherever it is when it turns. A drag moves it with the finger from
/// where it is drawn, and let go, it settles from there with the drag's
/// speed (back open, or closed past a third of its width or on a fling), so
/// no frame jumps.
///
/// ```dart
/// DesignSideSheetRoute<void>(builder: (context, sheet) => const SizedBox(width: 320))
/// ```
class DesignSideSheetRoute<T> extends PopupRoute<T> {
  /// A sheet whose panel [builder] paints.
  DesignSideSheetRoute({
    required this.builder,
    this.edge = DesignSheetEdge.end,
    this.width = 360,
    this.minGap = 56,
    Color barrierColor = const Color(0x66000000),
    this.barrierBuilder,
    String? barrierLabel,
    bool barrierDismissible = true,
    this.dragToClose = true,
    this.semanticLabel,
    this.dampingRatio = 1,
    this.stiffness = 700,
    this.closeDampingRatio,
    this.closeStiffness,
    super.settings,
  }) : _scrim = barrierColor,
       _givenBarrierLabel = barrierLabel,
       _dismissOnBarrier = barrierDismissible;

  /// The spring's damping ratio (ζ): it opens and settles on it, and
  /// closes on it unless [closeDampingRatio] is given. Defaults to 1,
  /// critically damped.
  final double dampingRatio;

  /// The spring's stiffness (k), and the close spring's unless
  /// [closeStiffness] is given. Defaults to 700.
  final double stiffness;

  /// The close spring's damping ratio (ζ); null: [dampingRatio]. A look
  /// whose sheet falls away on a spring of its own sets it with
  /// [closeStiffness].
  final double? closeDampingRatio;

  /// The close spring's stiffness (k); null: [stiffness].
  final double? closeStiffness;

  /// Paints the panel.
  final Widget Function(BuildContext context, DesignSheetInfo sheet) builder;

  /// The edge it comes from.
  final DesignSheetEdge edge;

  /// The panel's width.
  final double width;

  /// The least room left beside it on a narrow screen.
  final double minGap;

  /// Whether a drag toward its edge closes it.
  final bool dragToClose;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Paints the barrier in place of the barrier colour (a look's own
  /// screen); null: the colour.
  final DesignBarrierBuilder? barrierBuilder;

  final Color _scrim;
  final bool _dismissOnBarrier;
  final ValueNotifier<double?> _drag = ValueNotifier(null);
  final GestureFocus _gestureFocus = GestureFocus();
  late final RouteSpring _spring = RouteSpring(
    dampingRatio: dampingRatio,
    stiffness: stiffness,
    closeDampingRatio: closeDampingRatio,
    closeStiffness: closeStiffness,
  );

  final String? _givenBarrierLabel;

  /// What a screen reader calls the barrier; null:
  /// [DesignLocalizations.sideSheetBarrierLabel].
  @override
  String? get barrierLabel {
    final context = navigator?.context;
    return _givenBarrierLabel ??
        (context == null
            ? null
            : DesignLocalizations.of(context).sideSheetBarrierLabel);
  }

  /// The barrier's colour; null while [barrierBuilder] paints it.
  @override
  Color? get barrierColor => barrierBuilder == null ? _scrim : null;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final paint = barrierBuilder;
    return paint == null ? barrier : paintedBarrier(paint, animation!, barrier);
  }

  @override
  bool get barrierDismissible => _dismissOnBarrier;

  /// Nominal: the spring decides how long it takes ([createSimulation]).
  @override
  Duration get transitionDuration => const Duration(milliseconds: 300);

  @override
  void install() {
    super.install();
    _spring.attach(controller!);
  }

  /// The spring from where the sheet is to open or gone, carrying a drag's
  /// speed.
  @override
  Simulation createSimulation({required bool forward}) =>
      _spring.simulation(navigator!.context, to: forward ? 1 : 0);

  @override
  void dispose() {
    _drag.dispose();
    super.dispose();
  }

  void _dragStart() {
    // The finger takes the panel from where it is drawn, even part way
    // through opening.
    controller!.stop();
    _drag.value = 0;
    // A user gesture takes the focus out of the route; let go open, the
    // route has it back.
    _gestureFocus.hold(this);
    navigator?.didStartUserGesture();
  }

  // [delta]: the drag toward the edge, in sheet widths.
  void _dragUpdate(double delta) {
    final c = controller!;
    c.value -= delta;
    _drag.value = 1 - c.value;
  }

  // [fling]: the speed toward the edge, in sheet widths a second.
  void _dragEnd(double fling, {bool settle = false}) {
    // A pointer that never became a drag (a tap on the sheet's content)
    // ends in a cancel: nothing moved and no user gesture was started.
    if (_drag.value == null) return;
    _drag.value = null;
    final close =
        !settle && (fling > 1 || (fling > -1 && controller!.value < 2 / 3));
    // It settles from where it was let go, on the spring, at the drag's
    // speed (sheet widths a second toward open).
    if (close) {
      _spring.carry = -fling;
      navigator?.pop();
      _spring.carry = null;
    } else {
      _spring.settle(navigator!.context, 1, velocity: -fling);
    }
    navigator?.didStopUserGesture();
  }

  double _panelWidth(BuildContext context) {
    final screen = MediaQuery.sizeOf(context).width;
    return width.clamp(0.0, (screen - minGap).clamp(0.0, screen));
  }

  AxisDirection _side(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final left = (edge == DesignSheetEdge.start) != rtl;
    return left ? AxisDirection.left : AxisDirection.right;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final side = _side(context);
    final w = _panelWidth(context);
    return Align(
      alignment: side == AxisDirection.left
          ? Alignment.centerLeft
          : Alignment.centerRight,
      child: SizedBox(
        width: w,
        height: double.infinity,
        child: Semantics(
          scopesRoute: true,
          namesRoute: true,
          explicitChildNodes: true,
          label: semanticLabel,
          child: _DragToClose(
            route: this,
            enabled: dragToClose,
            side: side,
            width: w,
            child: escapeCloses(
              context,
              ValueListenableBuilder<double?>(
                valueListenable: _drag,
                builder: (context, drag, _) => builder(
                  context,
                  DesignSheetInfo(
                    side: side,
                    animation: animation,
                    dragging: drag != null,
                    close: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (designReduceMotionOf(context)) {
      return FadeTransition(opacity: animation, child: child);
    }
    // The page is the screen's width; the panel moves its own, so a finger
    // and the panel move together.
    final screen = MediaQuery.sizeOf(context).width;
    final panel = screen == 0 ? 1.0 : _panelWidth(context) / screen;
    final from = (_side(context) == AxisDirection.left ? -1.0 : 1.0) * panel;
    // The spring is the curve: the panel is where the route's value says.
    return SlideTransition(
      position: Tween(
        begin: Offset(from, 0),
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }
}

// A drag toward the sheet's edge moves it with the finger; past a third of
// its width or a fling, it closes, else it goes back.
class _DragToClose extends StatelessWidget {
  const _DragToClose({
    required this.route,
    required this.enabled,
    required this.side,
    required this.width,
    required this.child,
  });

  final DesignSideSheetRoute<Object?> route;
  final bool enabled;
  final AxisDirection side;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final sign = side == AxisDirection.left ? -1.0 : 1.0;
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => route._dragStart(),
      onHorizontalDragUpdate: (d) =>
          route._dragUpdate(d.primaryDelta! * sign / width),
      onHorizontalDragEnd: (d) =>
          route._dragEnd(d.primaryVelocity! * sign / width),
      onHorizontalDragCancel: () => route._dragEnd(0, settle: true),
      child: child,
    );
  }
}
