import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../internal/arrow.dart';
import '../../styled.dart';
import '../../theme.dart';
import 'arrow_placement.dart';

/// A tooltip's face, Fluent's `appearance`: [normal] the surface (the
/// default), [inverted] the dark static plane.
enum Fluent2TooltipAppearance {
  /// Fluent's normal tooltip: the neutral surface.
  normal,

  /// Fluent's inverted tooltip: dark on light, light on dark.
  inverted,
}

/// Where a tooltip sits from its control, Fluent's `positioning`: [above]
/// (the default), [below], or [after] at its end side for a rail; each flips
/// when the window has no room.
enum Fluent2TooltipPosition {
  /// Above its control.
  above,

  /// Below its control.
  below,

  /// After its control, on the reading side's end.
  after,
}

/// The bubble a [Fluent2Tooltip] shows, drawn in place: Fluent's tooltip
/// surface (at most 240 wide, 4 corners, 5 over and 7 under the words and
/// 12 at the sides, caption1, `shadow8`) in its [appearance], with its 6
/// arrow when [placement] says where. Plumbing of the tooltip; a specimen
/// draws one alone.
///
/// ```dart
/// Fluent2TooltipBubble(message: 'Share', appearance: Fluent2TooltipAppearance.inverted)
/// ```
class Fluent2TooltipBubble extends StatelessWidget {
  /// A tooltip's bubble showing [message].
  const Fluent2TooltipBubble({
    required this.message,
    this.appearance = Fluent2TooltipAppearance.normal,
    this.placement,
    super.key,
  });

  /// The tip's words.
  final String message;

  /// Fluent's `appearance`: normal or inverted.
  final Fluent2TooltipAppearance appearance;

  /// Where the arrow points; null draws none.
  final Fluent2ArrowPlacement? placement;

  /// The arrow's height (Fluent's `arrowHeight`).
  static const double arrow = 6;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final inverted = appearance == Fluent2TooltipAppearance.inverted;
    final look = Fluent2StyleOf(
      [t.tooltipTheme],
      {if (inverted) WidgetState.selected},
    );
    final fill =
        look.fill ??
        (inverted
            ? t.colors.neutralBackgroundStatic
            : t.colors.neutralBackground1);
    final ink =
        look.foreground ??
        (inverted
            ? t.colors.neutralForegroundStaticInverted
            : t.colors.neutralForeground1);
    final p = placement;
    final bubble = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 240),
      child: Fluent2Plate(
        fill: fill,
        side: fluent2Rim(t, look, t.colors.transparentStroke),
        radius: BorderRadius.circular(Fluent2Radius.medium),
        shape: look.shape,
        shadows: t.shadows.shadow8,
        padding:
            look.padding(Directionality.of(context)) ??
            const EdgeInsets.fromLTRB(12, 5, 12, 7),
        child: Text(message, style: t.caption1.merge(look.textStyle).c(ink)),
      ),
    );
    if (p == null) return bubble;
    return CustomPaint(
      foregroundPainter: _ArrowPainter(placement: p, fill: fill, height: arrow),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: arrow),
        child: bubble,
      ),
    );
  }
}

/// Paints the arrow of a bubble laid with room for one at its top and
/// foot: a triangle of [height] in the bubble's [fill] on the side its
/// [placement] says, at its offset. Plumbing of the tooltip and the popover.
class _ArrowPainter extends CustomPainter {
  _ArrowPainter({
    required this.placement,
    required this.fill,
    required this.height,
  });

  final Fluent2ArrowPlacement placement;
  final Color fill;
  final double height;

  @override
  void paint(Canvas canvas, Size size) => fluent2PaintArrow(
    canvas,
    size,
    placement: placement,
    fill: fill,
    height: height,
  );

  // The placement is written during layout, after this painter was made.
  @override
  bool shouldRepaint(_ArrowPainter old) => true;
}

/// Fluent 2's Tooltip: a short [message] naming or explaining its [child]
/// (an icon-only command, a truncated name), shown in a bubble above it
/// (or [below]) after the pointer rests on it for 250 ms, on a long press
/// on a touch screen, and while the keyboard's focus is inside it; hidden
/// 250 ms after the pointer leaves. [withArrow] adds the 6 arrow pointing
/// at the control (Fluent draws none by default). The message is the
/// control's tooltip to a screen reader. Never put an act or the only
/// copy of something needed inside one.
///
/// ```dart
/// Fluent2Tooltip(message: 'Share', child: Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: share))
/// ```
class Fluent2Tooltip extends StatefulWidget {
  /// A tooltip that names [child] with [message] on hover, long press or focus.
  const Fluent2Tooltip({
    required this.message,
    required this.child,
    this.appearance = Fluent2TooltipAppearance.normal,
    this.position = Fluent2TooltipPosition.above,
    this.withArrow = false,
    super.key,
  });

  /// The tip's words.
  final String message;

  /// The control the tip names.
  final Widget child;

  /// Fluent's `appearance`: normal or inverted.
  final Fluent2TooltipAppearance appearance;

  /// Where the tip stands against [child].
  final Fluent2TooltipPosition position;

  /// Whether the bubble points at [child].
  final bool withArrow;

  @override
  State<Fluent2Tooltip> createState() => _Fluent2TooltipState();
}

class _Fluent2TooltipState extends State<Fluent2Tooltip> {
  final GlobalKey<RawTooltipState> _tip = GlobalKey<RawTooltipState>();
  final Fluent2ArrowPlacement _placement = Fluent2ArrowPlacement();

  Offset _place(TooltipPositionContext c) {
    const edge = 8.0;
    // Fluent's 4 between the control and the bubble; with the arrow the
    // bubble stands 6 further off, and the room the arrow is drawn in is
    // already in its box.
    const gap = 4.0;
    final size = c.tooltipSize;
    if (widget.position == Fluent2TooltipPosition.after) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final right = c.target.dx + c.targetSize.width / 2 + gap;
      final left = c.target.dx - c.targetSize.width / 2 - gap - size.width;
      final fitsRight = right + size.width <= c.overlaySize.width - edge;
      final fitsLeft = left >= edge;
      final y = (c.target.dy - size.height / 2)
          .clamp(
            edge,
            math.max(edge, c.overlaySize.height - edge - size.height),
          )
          .toDouble();
      final toRight = rtl ? !fitsLeft && fitsRight : fitsRight || !fitsLeft;
      return Offset(toRight ? right : left, y);
    }
    final top = c.target.dy - c.targetSize.height / 2;
    final bottom = c.target.dy + c.targetSize.height / 2;
    final aboveY = top - gap - size.height;
    final belowY = bottom + gap;
    final wantAbove = widget.position == Fluent2TooltipPosition.above;
    final fitsAbove = aboveY >= edge;
    final fitsBelow = belowY + size.height <= c.overlaySize.height - edge;
    final above = wantAbove
        ? (fitsAbove || !fitsBelow)
        : (fitsAbove && !fitsBelow);
    final x = (c.target.dx - size.width / 2)
        .clamp(edge, math.max(edge, c.overlaySize.width - edge - size.width))
        .toDouble();
    _placement
      ..isAbove = above
      ..offset = c.target.dx - x;
    return Offset(x, above ? aboveY : belowY);
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: (focused) {
        if (focused) {
          if (FocusManager.instance.highlightMode ==
              FocusHighlightMode.traditional) {
            _tip.currentState?.ensureTooltipVisible();
          }
        } else {
          RawTooltip.dismissAllToolTips();
        }
      },
      child: RawTooltip(
        key: _tip,
        semanticsTooltip: widget.message,
        hoverDelay: const Duration(milliseconds: 250),
        dismissDelay: const Duration(milliseconds: 250),
        animationStyle: AnimationStyle(
          curve: Fluent2Motion.decelerateMid,
          duration: Fluent2Motion.on(context)
              ? Fluent2Motion.normal
              : Duration.zero,
          reverseDuration: Fluent2Motion.on(context)
              ? Fluent2Motion.faster
              : Duration.zero,
        ),
        positionDelegate: _place,
        tooltipBuilder: (context, animation) => FadeTransition(
          opacity: animation,
          child: Fluent2TooltipBubble(
            message: widget.message,
            appearance: widget.appearance,
            placement:
                widget.withArrow &&
                    widget.position != Fluent2TooltipPosition.after
                ? _placement
                : null,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}
