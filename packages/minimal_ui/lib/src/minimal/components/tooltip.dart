/// A short line that names a control: a tooltip.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// A short line that names what is under the pointer — an icon button's
/// action, a truncated value, a shortcut: the inverse surface on the
/// `shapes.small` step with the words in the caption, a few pixels under
/// [child] (over it near the screen's foot). It shows after a moment's
/// hover with a mouse, on a long press by touch, and at once while the
/// keyboard focuses the child; it fades in and out (a short fade under
/// Reduce Motion). A tooltip is information, so it is the one surface a
/// hovering pointer raises.
///
/// The behaviour is Flutter's [RawTooltip], as WCAG 1.4.13 asks: the pointer
/// may move onto the tip, Escape hides it without moving the focus, and it
/// stays until the pointer or the focus leaves; one shows at a time.
/// ui_core's [RawTooltipFocusFix] shows it on the keyboard's focus, and
/// [RawTooltipPlacement] places it. Minimal paints the tip.
///
/// A screen reader hears [message] as the child's tooltip. Never put the
/// only way to do something in a tooltip.
///
/// [style] dresses one tooltip, `components.tooltip` every one: fill,
/// foreground, edge or side, shape, padding and textStyle.
///
/// ```dart
/// MinimalTooltip(message: 'Archive', child: MinimalIconButton(LucideIcons.archive, semanticLabel: 'Archive', onPressed: archive))
/// ```
class MinimalTooltip extends StatelessWidget {
  /// [message], shown by [child] after a moment under the pointer or a long
  /// press.
  const MinimalTooltip({
    super.key,
    required this.message,
    required this.child,
    this.style,
    this.waitDuration = const Duration(milliseconds: 500),
  });

  /// What it says.
  final String message;

  /// What it explains.
  final Widget child;

  /// This tooltip's style, over `components.tooltip`.
  final MinimalStyle? style;

  /// How long a pointer rests before it shows.
  final Duration waitDuration;

  /// The gap between the child's edge and the tooltip's.
  static const double gap = 6;

  /// Under [child], centred on it, [gap] from it; over it where there are
  /// fewer than 48 px below (two lines of a tip) and more above.
  static const RawPopoverPlacement placement = RawPopoverPlacement(
    side: RawPopoverSide.below,
    align: RawPopoverAlign.center,
    gap: gap,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.tooltip], const {});
    if (message.isEmpty) return child;
    final spring = RawMotionPolicy.of(context)
        .effects(dampingRatio: 1, stiffness: 1600);
    // The tip comes and goes on its own spring. RawTooltip's animation says
    // only whether it shows: at once when it shows, and while it hides, as
    // long as the spring takes to close from open, so the tip stays until
    // it has faded.
    final closing = _settleTime(spring);
    // The message joins the child's node: one control, one node.
    return MergeSemantics(
      child: RawTooltipPlacement(
        placement: placement,
        builder: (context, positionDelegate) => RawTooltip(
          semanticsTooltip: message,
          hoverDelay: waitDuration,
          animationStyle: AnimationStyle(
            duration: Duration.zero,
            reverseDuration: closing,
          ),
          positionDelegate: positionDelegate,
          tooltipBuilder: (context, shown) => ExcludeSemantics(
            child: _TipPresence(
              shown: shown,
              spring: spring,
              builder: (context, presence) => _tip(context, so, presence),
            ),
          ),
          child: RawTooltipFocusFix(child: child),
        ),
      ),
    );
  }

  Widget _tip(
    BuildContext context,
    MinimalStyleOf so,
    Animation<double> presence,
  ) {
    final t = context.minimalTheme;
    return AnimatedBuilder(
      animation: presence,
      builder: (context, child) =>
          Opacity(opacity: presence.value.clamp(0.0, 1.0), child: child),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 280),
        child: Container(
          padding:
              so.paddingIn(context) ??
              const EdgeInsets.symmetric(
                horizontal: MinimalSpacing.s8,
                vertical: MinimalSpacing.s4,
              ),
          decoration: minimalFrame(
            so.outline(t, RawCorner.small),
            fill: so.fill ?? t.surfaceInverse,
            side: so.rim(null, t.rim),
          ),
          // The overlay may sit above any text style of the app's: the
          // words carry their whole style with them.
          child: DefaultTextStyle(
            style: so.text(t.caption, so.foreground ?? t.textInverse),
            child: Text(message),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('message', message))
      ..add(
        DiagnosticsProperty<MinimalStyle>('style', style, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<Duration>(
          'waitDuration',
          waitDuration,
          defaultValue: const Duration(milliseconds: 500),
        ),
      );
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
  final closing = rawSpringSimulation(spring, from: 1, to: 0);
  var ms = 1;
  while (ms < 5000 && !closing.isDone(ms / 1000)) {
    ms++;
  }
  return Duration(milliseconds: ms);
}
