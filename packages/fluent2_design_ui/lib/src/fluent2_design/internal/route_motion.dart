// How Fluent 2's surfaces move on ui_core's route springs: the presence a route hands its builder (0 gone, 1 open),
// turned into Fluent's entrances.
import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';

/// [child] as Fluent's dialog enters on [presence]: a fade from nothing and a
/// scale from .95 to its size. Under Reduce Motion ui_core's dialog route
/// holds [presence] at 1 and fades the page itself.
Widget fluent2DialogRise(Animation<double> presence, Widget child) =>
    AnimatedBuilder(
      animation: presence,
      builder: (context, child) {
        final p = presence.value.clamp(0.0, 1.0);
        return Opacity(
          opacity: p,
          child: Transform.scale(scale: 0.95 + 0.05 * p, child: child),
        );
      },
      child: child,
    );

/// [child] faded by [presence]: a centred sheet's entrance.
Widget fluent2Fade(Animation<double> presence, Widget child) => AnimatedBuilder(
  animation: presence,
  builder: (context, child) =>
      Opacity(opacity: presence.value.clamp(0.0, 1.0), child: child),
  child: child,
);

/// [child], a bottom sheet's card, where it stands on ui_core's bottom sheet
/// route: across a phone, centred over the window's foot from 600 at most
/// Fluent's dialog width ([Fluent2ChromeMetrics.dialogWidth]), at most
/// [maxHeight] tall; as tall as its content, or with [fill] as tall as the
/// route lays it out (a page sheet's resting size).
Widget fluent2BottomSheetPlace({
  required double maxHeight,
  required Widget child,
  bool fill = false,
}) => Align(
  alignment: Alignment.bottomCenter,
  heightFactor: 1,
  child: ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: Fluent2ChromeMetrics.dialogWidth,
      maxHeight: maxHeight,
    ),
    child: SizedBox(
      width: double.infinity,
      height: fill ? double.infinity : null,
      child: child,
    ),
  ),
);
