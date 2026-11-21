/// What a Minimal press draws over its face: the wash under a press, the
/// focus ring, the dimming while it is disabled.
library;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import 'kit_paint.dart';
import 'menu_keys.dart';
import 'styled.dart';
import '../theme.dart';

/// [child] wearing a Minimal press's feedback for its state: dimmed while it
/// is not [enabled], washed in its ink while [pressed], ringed while
/// [focused] (unless the row it stands in paints the keyboard's place). Over
/// its own box, or with [outset] over that box grown by the outset.
///
/// `MinimalPressable` draws it; so does a radio standing on Flutter's
/// `RawRadio`, so both look and move alike.
class MinimalPressFeedback extends StatelessWidget {
  /// The feedback for a press in [states].
  const MinimalPressFeedback({
    super.key,
    required this.states,
    required this.enabled,
    required this.pressed,
    required this.focused,
    required this.child,
    this.radius,
    this.shape,
    this.style,
    this.focusInside,
    this.face,
    this.ink,
    this.outset,
  });

  /// The press's states, for the style's shape and overlay.
  final Set<WidgetState> states;

  /// False dims it.
  final bool enabled;

  /// True washes it.
  final bool pressed;

  /// True rings it.
  final bool focused;

  /// The face.
  final Widget child;

  /// See `MinimalPressable.radius`.
  final double? radius;

  /// See `MinimalPressable.shape`.
  final OutlinedBorder? shape;

  /// See `MinimalPressable.style`.
  final MinimalStyle? style;

  /// See `MinimalPressable.focusInside`.
  final bool? focusInside;

  /// See `MinimalPressable.face`.
  final Color? face;

  /// See `MinimalPressable.ink`.
  final Color? ink;

  /// See `MinimalPressable.outset`.
  final EdgeInsetsGeometry? outset;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shape =
        style?.shape?.resolve(states) ??
        this.shape ??
        (radius == null
            ? t.shapes.small
            : RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(radius!),
              ));
    final inside = focusInside ?? radius == 0;
    // The ring, unless the row it presses paints the keyboard's place (an
    // open menu's item, on the muted fill).
    final ringed = focused && enabled && !MinimalPaintsFocus.of(context);
    // The look's wash: the ink at 8% while pressed. Hover leaves the face
    // as it is; an app's overlay may say otherwise.
    final wash =
        style?.overlay?.resolve(states) ??
        minimalPressInk(
          t,
          face: face,
          faceInk: ink,
        ).withValues(alpha: enabled && pressed ? 0.08 : 0.0);
    return AnimatedOpacity(
      opacity: enabled
          ? 1
          : minimalDisabledOpacity(
              ink: ink,
              face: face,
              ground: minimalGround(context),
            ),
      duration: context.minimalStill ? Duration.zero : MinimalMotion.fast,
      child: _reach(
        context,
        // Outside the edge the ring stands past a gap of the ground, so it
        // reads on a face filled in its own ink.
        inside
            ? minimalFrame(
                shape,
                fill: wash,
                side: ringed
                    ? BorderSide(
                        color: t.ring,
                        width: t.focusWidth,
                        strokeAlign: BorderSide.strokeAlignInside,
                      )
                    : BorderSide.none,
              )
            : minimalRingFrame(
                shape,
                wash: wash,
                ring: ringed ? t.ring : null,
                ground: minimalGround(context),
                width: t.focusWidth,
              ),
      ),
    );
  }

  /// [child] wearing [feedback] (the wash and the ring): over its own box,
  /// or with [outset] over that box grown by the outset, the child laid out
  /// as it would be without it.
  Widget _reach(BuildContext context, Decoration feedback) {
    final outset = this.outset?.resolve(Directionality.of(context));
    if (outset == null || outset == EdgeInsets.zero) {
      return AnimatedContainer(
        duration: context.minimalStill ? Duration.zero : MinimalMotion.fast,
        curve: MinimalMotion.out,
        foregroundDecoration: feedback,
        child: child,
      );
    }
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.passthrough,
      children: [
        child,
        Positioned(
          left: -outset.left,
          top: -outset.top,
          right: -outset.right,
          bottom: -outset.bottom,
          child: IgnorePointer(
            child: AnimatedContainer(
              duration: context.minimalStill
                  ? Duration.zero
                  : MinimalMotion.fast,
              curve: MinimalMotion.out,
              foregroundDecoration: feedback,
            ),
          ),
        ),
      ],
    );
  }
}
