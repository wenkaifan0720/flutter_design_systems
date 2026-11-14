import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../chrome_metrics.dart';
import '../components/toast.dart';
import '../localizations.dart';
import '../theme.dart';

/// What a Frosted toast carries past its words: its [tone], its [icon], and
/// how far over the screen's bottom edge it stands ([bottom]: over the tab
/// bar, over a route's footer), measured where it was raised.
@immutable
class FrostedToastLook {
  /// A toast's look.
  const FrostedToastLook({required this.tone, required this.bottom, this.icon});

  /// The mark's ink and glyph.
  final FrostedTone tone;

  /// The mark's glyph; null is the tone's.
  final IconData? icon;

  /// The card's bottom edge, up from the screen's.
  final double bottom;
}

/// The toasts' layer over the app, which [FrostedHost] mounts above the
/// navigator: ui_core's [DesignToaster] (the queue, the timer that pauses
/// under a pointer or focus, the swipe and Escape that dismiss, F6 to reach
/// it, the live region), one toast at a time, each painted as a
/// [FrostedSnackBar] rising from below. On a phone it spans the row 16 in;
/// at desktop width it stands 380 wide at the bottom end, 32 in.
class FrostedToaster extends StatelessWidget {
  /// A layer of toasts over [child].
  const FrostedToaster({required this.child, super.key});

  /// The app the toasts float over.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final wide = FrostedBreakpoints.isWide(context);
    return DesignToaster(
      maxVisible: 1,
      alignment: wide
          ? AlignmentDirectional.bottomEnd
          : AlignmentDirectional.bottomCenter,
      padding: wide
          ? const EdgeInsetsDirectional.only(
              end: FrostedChromeMetrics.toastWideEdge,
            )
          : const EdgeInsets.symmetric(
              horizontal: FrostedChromeMetrics.toastSide,
            ),
      constraints: wide
          ? const BoxConstraints.tightFor(
              width: FrostedChromeMetrics.toastWideWidth,
            )
          : const BoxConstraints(),
      regionLabel: FrostedLocalizations.of(context).notifications,
      toastBuilder: _paint,
      child: child,
    );
  }

  static Widget _paint(BuildContext context, DesignToastDetails view) {
    final toast = view.toast;
    final data = toast.data;
    final look = data is FrostedToastLook
        ? data
        : FrostedToastLook(
            tone: FrostedTone.success,
            bottom: FrostedBreakpoints.isWide(context)
                ? FrostedChromeMetrics.toastWideEdge
                : FrostedChromeMetrics.toastBottom,
          );
    final card = FrostedSnackBar(
      toast.message,
      title: toast.title,
      tone: look.tone,
      icon: look.icon,
      actionLabel: toast.actionLabel,
      onAction: view.runAction,
    );
    final face = !FrostedMotion.of(context).moves
        ? card
        : AnimatedBuilder(
            animation: view.animation,
            child: card,
            builder: (context, child) {
              final v = view.animation.value.clamp(0.0, 1.0);
              return Opacity(
                opacity: v,
                child: Transform.translate(
                  offset: Offset(0, (1 - v) * FrostedChromeMetrics.toastRise),
                  child: child,
                ),
              );
            },
          );
    // The layer stands inside the safe area; the toast's own height over
    // the edge already counts it.
    final safe = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: math.max(0, look.bottom - safe)),
      child: face,
    );
  }
}
