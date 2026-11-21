/// A modal route's barrier, its screen reader's node cut to the part of the
/// screen the route's panel leaves uncovered, as Material's modal bottom
/// sheet cuts its own: a tap on the barrier reaches only that part.
library;

import 'package:flutter/widgets.dart';

/// [route]'s barrier as [ModalRoute.buildModalBarrier] builds it, its
/// semantics node inset by [clip] (what the panel covers, from each side of
/// the screen), through [ModalBarrier.clipDetailsNotifier].
Widget clippedModalBarrier(
  ModalRoute<Object?> route,
  ValueNotifier<EdgeInsets> clip,
) {
  final color = route.barrierColor;
  if (color != null && color.a != 0 && !route.offstage) {
    return AnimatedModalBarrier(
      color: route.animation!.drive(
        ColorTween(
          begin: color.withValues(alpha: 0),
          end: color,
        ).chain(CurveTween(curve: route.barrierCurve)),
      ),
      dismissible: route.barrierDismissible,
      semanticsLabel: route.barrierLabel,
      barrierSemanticsDismissible: route.semanticsDismissible,
      clipDetailsNotifier: clip,
    );
  }
  return ModalBarrier(
    dismissible: route.barrierDismissible,
    semanticsLabel: route.barrierLabel,
    barrierSemanticsDismissible: route.semanticsDismissible,
    clipDetailsNotifier: clip,
  );
}
