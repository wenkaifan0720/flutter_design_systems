import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The spring Frosted's dialog and sheets open and close on (ζ 1, k 700):
/// ui_core's sheet spring, which settles in about a quarter second each way,
/// near Frosted's former 320 ms rise and 220 ms fall.
const double frostedRouteStiffness = 700;

/// A modal barrier, as ui_core's parts paint one (`barrierBuilder`), that
/// softens the page below as it dims it: the page blurred by [soften] under
/// [color], both growing with the route's animation (the blur drawn whole
/// from the first frame it is, never faded under an Opacity), clipped to the
/// route's own box.
DesignBarrierBuilder frostedSoftBarrier({
  required Color color,
  required double soften,
}) =>
    (context, animation) => IgnorePointer(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final v = animation.value.clamp(0.0, 1.0);
          if (v <= .01) return const SizedBox.shrink();
          return ClipRect(
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(
                sigmaX: v * soften,
                sigmaY: v * soften,
              ),
              child: ColoredBox(
                color: color.withValues(alpha: color.a * v),
                child: const SizedBox.expand(),
              ),
            ),
          );
        },
      ),
    );

/// The barrier a Frosted route paints over [color]: the page below softened
/// by [soften] as it dims, or the colour alone when [soften] is 0 (no
/// transparency).
DesignBarrierBuilder? _softBelow(Color color, double soften) =>
    soften > 0 ? frostedSoftBarrier(color: color, soften: soften) : null;

/// Under Reduce Motion ui_core's routes fade their page in. Frosted's glass is
/// a backdrop blur, which reads an empty layer under the fade's Opacity (the
/// panel clear while it fades), so a Frosted panel cuts in instead, while its
/// barrier fades on the route's animation.
Widget _stillCuts(
  BuildContext context,
  Widget child,
  Widget Function() moving,
) => designReduceMotionOf(context) ? child : moving();

/// The dialog route of Frosted's dialogs, and of its sheets on a tablet or
/// the desktop (ui_core's [DesignDialogRoute]: a spring, focus kept inside
/// and given back, Escape, the dialog's role and name): the card grows in
/// over the page, softened below by [soften], rather than fading (glass under
/// an Opacity reads an empty layer).
class FrostedSoftDialogRoute<T> extends DesignDialogRoute<T> {
  /// A dialog route of [builder]'s page, softening the page below by
  /// [soften] under [barrierColor].
  FrostedSoftDialogRoute({
    required double soften,
    required WidgetBuilder builder,
    super.barrierColor = const Color(0x66000000),
    super.barrierLabel,
    super.barrierDismissible,
    super.semanticLabel,
    super.isAlert,
    super.settings,
  }) : super(
         stiffness: frostedRouteStiffness,
         barrierBuilder: _softBelow(barrierColor, soften),
         builder: (context, details) =>
             _Grow(presence: details.animation, child: builder(context)),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _stillCuts(
    context,
    child,
    () => super.buildTransitions(context, animation, secondaryAnimation, child),
  );
}

/// The phone's sheet route (ui_core's [RawBottomSheetRoute]: a spring that
/// carries a drag's speed, a drag down or the scrim closing it, focus given
/// back), softening the page below by [soften].
class FrostedSoftBottomSheetRoute<T> extends RawBottomSheetRoute<T> {
  /// A sheet route of [builder]'s panel, softening the page below by
  /// [soften] under [barrierColor].
  FrostedSoftBottomSheetRoute({
    required double soften,
    required super.builder,
    super.snapSizes,
    super.barrierColor = const Color(0x66000000),
    super.barrierLabel,
    super.semanticLabel,
    super.settings,
  }) : super(
         stiffness: frostedRouteStiffness,
         barrierBuilder: _softBelow(barrierColor, soften),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _stillCuts(
    context,
    child,
    () => super.buildTransitions(context, animation, secondaryAnimation, child),
  );
}

/// The side sheet's route (ui_core's [RawSideSheetRoute] on its spring),
/// softening the page below as the dialog and the bottom sheet do: the whole
/// page behind it blurred under the scrim, not dimmed alone.
class FrostedSoftSideSheetRoute<T> extends RawSideSheetRoute<T> {
  /// A side sheet route softening the page below by [soften].
  FrostedSoftSideSheetRoute({
    required double soften,
    required super.builder,
    super.edge,
    super.width,
    super.barrierColor = const Color(0x66000000),
    super.barrierLabel,
    super.semanticLabel,
  }) : super(
         stiffness: frostedRouteStiffness,
         barrierBuilder: _softBelow(barrierColor, soften),
       );

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => _stillCuts(
    context,
    child,
    () => super.buildTransitions(context, animation, secondaryAnimation, child),
  );
}

/// [child] growing from 96% to its size with [presence], drawn from the
/// first frame it is present (a scale, never an Opacity: glass under one
/// reads an empty layer).
class _Grow extends StatelessWidget {
  const _Grow({required this.presence, required this.child});

  final Animation<double> presence;
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: presence,
    child: child,
    builder: (context, child) {
      final v = presence.value;
      if (v <= 0) return const SizedBox.shrink();
      return Transform.scale(
        scale: .96 + .04 * v.clamp(0.0, 1.0),
        child: child,
      );
    },
  );
}
