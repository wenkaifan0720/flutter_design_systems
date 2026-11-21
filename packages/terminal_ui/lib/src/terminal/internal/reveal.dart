/// How a menu and a tip come: revealed line by line from the edge beside
/// what opened them, as a terminal draws a pane.
library;

import 'package:flutter/widgets.dart';

/// Reveals [child] by [presence], from its bottom when it stands [above]
/// what opened it, else from its top, no taller than [maxHeight].
class TermReveal extends StatelessWidget {
  /// Reveals [child] by [presence].
  const TermReveal({
    super.key,
    required this.presence,
    required this.above,
    this.maxHeight = double.infinity,
    required this.child,
  });

  /// How far it has come, 0 to 1, on a spring.
  final Animation<double> presence;

  /// Whether it stands above what opened it.
  final bool above;

  /// The most it may take of the screen's height.
  final double maxHeight;

  /// What it reveals.
  final Widget child;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: presence,
    builder: (context, child) {
      // A spring only nears 1: within a hair of it, it is open.
      final v = presence.value;
      final t = v >= 0.995 ? 1.0 : v.clamp(0.0, 1.0);
      return ClipRect(
        clipBehavior: t >= 1 ? Clip.none : Clip.hardEdge,
        child: Align(
          alignment: above
              ? AlignmentDirectional.bottomStart
              : AlignmentDirectional.topStart,
          widthFactor: 1,
          heightFactor: t,
          child: child,
        ),
      );
    },
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: child,
    ),
  );
}
