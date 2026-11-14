import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// A modal route whose barrier softens the page below it as it dims it: the
/// page blurred by [soften] (growing with the route's animation; the blur is
/// drawn whole from the first frame it is, never faded under an Opacity)
/// under the barrier's colour.
mixin FrostedSoftensBelow<T> on ModalRoute<T> {
  /// The blur the page below softens by; 0 for none.
  double get soften;

  @override
  Widget buildModalBarrier() {
    final barrier = super.buildModalBarrier();
    final blur = soften;
    final rise = animation;
    if (blur <= 0 || rise == null) return barrier;
    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: AnimatedBuilder(
            animation: rise,
            builder: (context, _) {
              final v = rise.value.clamp(0.0, 1.0) * blur;
              if (v <= .01) return const SizedBox.shrink();
              // Clipped to the route's own box: an app shown inside
              // another (a gallery's page) softens only itself.
              return ClipRect(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: v, sigmaY: v),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
        barrier,
      ],
    );
  }
}

/// The desktop's sheet, a dialog: it grows in over the softened page rather
/// than fading (glass under an Opacity reads an empty layer).
class FrostedSoftDialogRoute<T> extends RawDialogRoute<T>
    with FrostedSoftensBelow<T> {
  /// A dialog route softening the page below by [soften].
  FrostedSoftDialogRoute({
    required this.soften,
    required super.pageBuilder,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.transitionDuration,
    super.settings,
  }) : super(transitionBuilder: _grow);

  @override
  final double soften;

  static Widget _grow(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) => AnimatedBuilder(
    animation: animation,
    child: child,
    builder: (context, child) => animation.value <= 0
        ? const SizedBox.shrink()
        : Transform.scale(
            scale: .96 + .04 * Curves.easeOutCubic.transform(animation.value),
            child: child,
          ),
  );
}

/// The side sheet's route, softening the page below as the dialog and the
/// bottom sheet do: the whole page behind it blurred under the scrim, not
/// dimmed alone.
class FrostedSoftSideSheetRoute<T> extends DesignSideSheetRoute<T>
    with FrostedSoftensBelow<T> {
  /// A side sheet route softening the page below by [soften].
  FrostedSoftSideSheetRoute({
    required this.soften,
    required super.builder,
    super.edge,
    super.width,
    super.barrierColor,
    super.barrierLabel,
    super.semanticLabel,
    super.transitionDuration,
  });

  @override
  final double soften;
}
