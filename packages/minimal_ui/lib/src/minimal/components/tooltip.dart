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
/// The behaviour is ui_core's ([DesignTooltip]), as WCAG 1.4.13 asks: the
/// pointer may move onto the tip, Escape hides it without moving the focus,
/// and it stays until the pointer or the focus leaves; one shows at a
/// time, and running the pointer along a toolbar reads each control's tip
/// without the wait. Minimal paints the tip.
///
/// A screen reader hears [message] as the child's tooltip. Never put the
/// only way to do something in a tooltip.
///
/// [style] dresses one tooltip, `components.tooltip` every one: fill,
/// foreground, edge or side, shape, padding and textStyle.
///
/// ```dart
/// MinimalTooltip(message: 'Archive', child: MinimalIconButton(LucideIcons.archive, label: 'Archive', onPressed: archive))
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
  static const DesignOverlayPlacement placement = DesignOverlayPlacement(
    side: DesignOverlaySide.below,
    align: DesignOverlayAlign.center,
    gap: gap,
    preferredExtent: 48,
    matchAnchorWidth: false,
  );

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final so = MinimalStyleOf([style, t.components.tooltip], const {});
    return DesignTooltip(
      message: message,
      hoverDelay: waitDuration,
      placement: placement,
      tooltipBuilder: (context, info) => AnimatedBuilder(
        animation: info.animation,
        builder: (context, child) => Opacity(
          opacity: info.animation.value.clamp(0.0, 1.0),
          child: child,
        ),
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
      child: child,
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
