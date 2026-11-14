/// A short line that names a control: a tooltip.
library;

import 'package:flutter/widgets.dart';

import '../component_themes.dart';
import '../internal/styled.dart';
import '../theme.dart';

/// A short line that names what is under the pointer — an icon button's
/// action, a truncated value, a shortcut: the inverse surface on the
/// `shapes.small` step with the words in the caption, a few pixels under
/// [child] (over it near the screen's foot). It shows after a moment's
/// hover with a mouse, on a long press by touch, and while the keyboard
/// focuses the child; it fades in and out in [MinimalMotion.fast]. A
/// tooltip is information, so it is the one surface a hovering pointer
/// raises.
///
/// A screen reader hears [message] as the child's hint. Never put the
/// only way to do something in a tooltip.
///
/// [style] dresses one tooltip, `components.tooltip` every one: fill,
/// foreground, edge or side, shape, padding and textStyle.
///
/// ```dart
/// MinimalTooltip(message: 'Archive', child: MinimalIconButton(LucideIcons.archive, label: 'Archive', onPressed: archive))
/// ```
class MinimalTooltip extends StatefulWidget {
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

  @override
  State<MinimalTooltip> createState() => _MinimalTooltipState();
}

class _MinimalTooltipState extends State<MinimalTooltip> {
  final GlobalKey<RawTooltipState> _tip = GlobalKey<RawTooltipState>();

  /// Keyboard focus inside the child shows the tooltip; leaving hides it.
  void _onFocus(bool focused) {
    if (focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional) {
      _tip.currentState?.ensureTooltipVisible();
    } else if (!focused) {
      RawTooltip.dismissAllToolTips();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([widget.style, t.components.tooltip], const {});
    final still = context.minimalStill;
    final message = widget.message;
    return RawTooltip(
      key: _tip,
      semanticsTooltip: message,
      hoverDelay: widget.waitDuration,
      triggerMode: TooltipTriggerMode.longPress,
      animationStyle: AnimationStyle(
        duration: still ? Duration.zero : MinimalMotion.fast,
        reverseDuration: still ? Duration.zero : MinimalMotion.fast,
        curve: MinimalMotion.out,
      ),
      positionDelegate: (c) => positionDependentBox(
        size: c.overlaySize,
        childSize: c.tooltipSize,
        target: c.target,
        verticalOffset: c.targetSize.height / 2 + MinimalTooltip.gap,
        preferBelow: true,
      ),
      tooltipBuilder: (context, animation) => FadeTransition(
        opacity: animation,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: Container(
            padding:
                so.padding ??
                const EdgeInsets.symmetric(
                  horizontal: MinimalSpacing.s8,
                  vertical: MinimalSpacing.s4,
                ),
            decoration: minimalFrame(
              so.shape ?? t.shapes.small,
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
      ),
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        includeSemantics: false,
        onFocusChange: _onFocus,
        child: widget.child,
      ),
    );
  }
}
