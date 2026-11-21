import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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

/// The bubble displayed by [Fluent2Tooltip]. Set [placement] to draw an
/// arrow toward the control that owns the tooltip.
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
        // A placement that notifies repaints the arrow as it moves.
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
/// move onto the bubble, Escape hides it, and one shows at a time. [withArrow] adds the 6 arrow pointing at the
/// control (Fluent draws none by default), aimed where the bubble landed. The
/// message is the control's tooltip to a screen reader. It is Flutter's
/// [RawTooltip] in Fluent's bubble, with ui_core's [RawTooltipFocusFix]
/// (the keyboard's focus shows it) and [RawTooltipPlacement] (where it
/// goes). Never put an act or the only copy of something needed inside one.
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
  RawPopoverPlacement get _placement => RawPopoverPlacement(
    side: switch (position) {
      Fluent2TooltipPosition.above => RawPopoverSide.above,
      Fluent2TooltipPosition.below => RawPopoverSide.below,
      Fluent2TooltipPosition.after => RawPopoverSide.end,
    },
    align: RawPopoverAlign.center,
    gap: 4,
    margin: 8,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return child;
    final spring = DesignMotionPolicy.of(context)
        .effects(dampingRatio: 1, stiffness: 1600);
    // The bubble comes and goes on its own spring. RawTooltip's animation
    // says only whether it shows: at once when it shows, and while it hides,
    // as long as the spring takes to close from open, so the bubble stays
    // until it has faded.
    final closing = _settleTime(spring);
    final aim = withArrow && position != Fluent2TooltipPosition.after
        ? _Aim()
        : null;
    // The message joins the child's node: one control, one node.
    return MergeSemantics(
      child: RawTooltipPlacement(
        placement: _placement,
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          hoverDelay: const Duration(milliseconds: 250),
          dismissDelay: const Duration(milliseconds: 250),
          animationStyle: AnimationStyle(
            duration: Duration.zero,
            reverseDuration: closing,
          ),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, shown) => ExcludeSemantics(
            child: _TipPresence(
              shown: shown,
              spring: spring,
              builder: (context, presence) => FadeTransition(
                opacity: presence,
                child: Builder(
                  builder: (context) {
                    aim?.bubble = context;
                    return Fluent2TooltipBubble(
                      message: message,
                      appearance: appearance,
                      style: style,
                      placement: aim,
                    );
                  },
                ),
              ),
            ),
          ),
          child: RawTooltipFocusFix(
            child: Builder(
              builder: (context) {
                aim?.anchor = context;
                return child;
              },
            ),
          ),
        ),
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
        EnumProperty<Fluent2TooltipPosition>(
          'position',
          position,
          defaultValue: Fluent2TooltipPosition.above,
        ),
      )
      ..add(FlagProperty('withArrow', value: withArrow, ifTrue: 'withArrow'));
  }
}

/// The arrow's place read from where the bubble landed, when it paints: on
/// the side of the control it took, at the control's centre.
class _Aim extends Fluent2ArrowPlacement {
  /// Where the control and the bubble build.
  BuildContext? anchor;
  BuildContext? bubble;

  RenderBox? _box(BuildContext? context) {
    final box = context != null && context.mounted
        ? context.findRenderObject()
        : null;
    return box is RenderBox && box.attached && box.hasSize ? box : null;
  }

  @override
  bool get isAbove {
    final control = _box(anchor);
    final tip = _box(bubble);
    if (control == null || tip == null) return true;
    return tip.localToGlobal(tip.size.center(Offset.zero)).dy <
        control.localToGlobal(control.size.center(Offset.zero)).dy;
  }

  @override
  double get offset {
    final control = _box(anchor);
    final tip = _box(bubble);
    if (control == null || tip == null) return 0;
    return control.localToGlobal(control.size.center(Offset.zero)).dx -
        tip.localToGlobal(Offset.zero).dx;
  }
}

// A tip's presence, 0 to 1, on [spring]: toward 1 while [shown] runs forward or has completed, toward 0 while it runs
// back.
class _TipPresence extends StatefulWidget {
  const _TipPresence({
    required this.shown,
    required this.spring,
    required this.builder,
  });

  final Animation<double> shown;
  final SpringDescription spring;
  final Widget Function(BuildContext context, Animation<double> presence)
  builder;

  @override
  State<_TipPresence> createState() => _TipPresenceState();
}

class _TipPresenceState extends State<_TipPresence>
    with SingleTickerProviderStateMixin {
  // Bounded: a tip's presence is an opacity, 0 to 1.
  late final AnimationController _presence = AnimationController(vsync: this);

  @override
  void initState() {
    super.initState();
    _presence.addStatusListener(_settled);
    widget.shown.addStatusListener(_follow);
    _follow(widget.shown.status);
  }

  @override
  void didUpdateWidget(_TipPresence oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shown != widget.shown) {
      oldWidget.shown.removeStatusListener(_follow);
      widget.shown.addStatusListener(_follow);
      _follow(widget.shown.status);
    }
  }

  @override
  void dispose() {
    widget.shown.removeStatusListener(_follow);
    _presence.dispose();
    super.dispose();
  }

  void _follow(AnimationStatus status) {
    final target = status.isForwardOrCompleted ? 1.0 : 0.0;
    if (_presence.value == target && !_presence.isAnimating) return;
    _presence.springTo(target, widget.spring);
  }

  // The spring started or came to rest: whether the tip is gone may change.
  void _settled(AnimationStatus status) {
    if (mounted) setState(() {});
  }

  // A hiding tip is gone once its spring has closed it, as ui_core's tooltip
  // took it away then. RawTooltip's own animation can run on (it lasts as
  // long as a close from fully open), and the tip would stay in place,
  // unseen, where a pointer could bring it back.
  bool get _gone =>
      !widget.shown.isForwardOrCompleted &&
      !_presence.isAnimating &&
      _presence.value == 0;

  @override
  Widget build(BuildContext context) =>
      _gone ? const SizedBox.shrink() : widget.builder(context, _presence);
}

// How long [spring] takes to close a tip from open: until its simulation is done, to the millisecond above.
Duration _settleTime(SpringDescription spring) {
  final closing = designSpringSimulation(spring, from: 1, to: 0);
  var ms = 1;
  while (ms < 5000 && !closing.isDone(ms / 1000)) {
    ms++;
  }
  return Duration(milliseconds: ms);
}
