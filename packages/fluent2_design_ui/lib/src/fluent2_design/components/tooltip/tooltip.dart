import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/arrow.dart';
import '../../styled.dart';
import '../../theme.dart';
import 'arrow_placement.dart';

/// A tooltip's room round its words: Fluent's padding (4 11 6 11) inside
/// its 1 px stroke, deeper under the words so the caption's capitals stand
/// on the bubble's middle; off the 4-pt grid on purpose.
const EdgeInsets _bubbleInsets = EdgeInsets.fromLTRB(12, 5, 12, 7);

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
    this.style,
    super.key,
  });

  /// This tooltip's own look, slot by slot, over its component theme
  /// ([Fluent2ThemeData.tooltipTheme]): the slots its doc names.
  final Fluent2Style? style;

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
      [style, t.tooltipTheme],
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
        padding: look.padding(Directionality.of(context)) ?? _bubbleInsets,
        child: Text(message, style: t.caption1.merge(look.textStyle).c(ink)),
      ),
    );
    if (p == null) return bubble;
    return CustomPaint(
      foregroundPainter: _ArrowPainter(
        placement: p,
        fill: fill,
        height: arrow,
        // A tooltip's aim moves as the tip lands (ui_core's surfaceRect).
        repaint: p is Listenable ? p as Listenable : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: arrow),
        child: bubble,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      )
      ..add(StringProperty('message', message))
      ..add(
        EnumProperty<Fluent2TooltipAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2TooltipAppearance.normal,
        ),
      )
      ..add(
        DiagnosticsProperty<Fluent2ArrowPlacement>(
          'placement',
          placement,
          defaultValue: null,
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
    super.repaint,
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

/// Fluent 2's Tooltip: a short [message] naming or explaining its [child] (an
/// icon-only command, a truncated name), shown in a bubble above it (or
/// [Fluent2TooltipPosition.below]) after the pointer rests on it for 250 ms, on
/// a long press on a touch screen, and while the keyboard's focus is inside it;
/// hidden 250 ms after the pointer leaves it and the bubble. The pointer may
/// move onto the bubble, Escape hides it, and one shows at a time: along a
/// toolbar the next shows at once. [withArrow] adds the 6 arrow pointing at the
/// control (Fluent draws none by default), aimed where the bubble landed. The
/// message is the control's tooltip to a screen reader. It is ui_core's
/// `DesignTooltip` in Fluent's bubble. Never put an act or the only copy of
/// something needed inside one.
///
/// ```dart
/// Fluent2Tooltip(message: 'Share', child: Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: share))
/// ```
class Fluent2Tooltip extends StatelessWidget {
  /// A tooltip that names [child] with [message] on hover, long press or focus.
  const Fluent2Tooltip({
    required this.message,
    required this.child,
    this.appearance = Fluent2TooltipAppearance.normal,
    this.position = Fluent2TooltipPosition.above,
    this.withArrow = false,
    this.style,
    super.key,
  });

  /// This tooltip's own look, slot by slot, over its component theme
  /// ([Fluent2ThemeData.tooltipTheme]): the slots its doc names.
  final Fluent2Style? style;

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

  /// Fluent's 4 between the control and the bubble (with the arrow, its
  /// room is inside the bubble's box) and 8 from the window's edges.
  DesignOverlayPlacement get _placement => DesignOverlayPlacement(
    side: switch (position) {
      Fluent2TooltipPosition.above => DesignOverlaySide.above,
      Fluent2TooltipPosition.below => DesignOverlaySide.below,
      Fluent2TooltipPosition.after => DesignOverlaySide.end,
    },
    align: DesignOverlayAlign.center,
    gap: 4,
    margin: 8,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  Widget build(BuildContext context) => DesignTooltip(
    message: message,
    hoverDelay: const Duration(milliseconds: 250),
    dismissDelay: const Duration(milliseconds: 250),
    placement: _placement,
    tooltipBuilder: (context, info) => FadeTransition(
      opacity: info.animation,
      child: Fluent2TooltipBubble(
        message: message,
        appearance: appearance,
        style: style,
        placement: withArrow && position != Fluent2TooltipPosition.after
            ? _Aim(info)
            : null,
      ),
    ),
    child: child,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
      )
      ..add(StringProperty('message', message))
      ..add(
        EnumProperty<Fluent2TooltipAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2TooltipAppearance.normal,
        ),
      )
      ..add(
        EnumProperty<Fluent2TooltipPosition>(
          'position',
          position,
          defaultValue: Fluent2TooltipPosition.above,
        ),
      )
      ..add(FlagProperty('withArrow', value: withArrow, ifTrue: 'withArrow'));
  }
}

/// The arrow's place read from where ui_core landed the bubble: on the side
/// it took, at the control's centre. It notifies as the bubble lands.
class _Aim extends Fluent2ArrowPlacement implements Listenable {
  _Aim(this.info);

  final DesignOverlayInfo info;

  @override
  bool get isAbove => info.side == DesignOverlaySide.above;

  @override
  double get offset {
    final landed = info.surfaceRect.value;
    return landed == null ? 0 : info.anchorRect.center.dx - landed.left;
  }

  @override
  void addListener(VoidCallback listener) =>
      info.surfaceRect.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      info.surfaceRect.removeListener(listener);
}
