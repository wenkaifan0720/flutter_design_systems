import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Marks the band a screen or a sheet stands its footer in, so a bar that
/// also asks for a band of its own there is caught: the two would draw two
/// hairlines and inset the bar twice. Plumbing of the components; pages never
/// place one.
class FrostedFooterBand extends InheritedWidget {
  /// Creates a [FrostedFooterBand].
  const FrostedFooterBand({required super.child, super.key});

  /// Whether [context] stands in a screen's or a sheet's footer band.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<FrostedFooterBand>() != null;

  @override
  bool updateShouldNotify(FrostedFooterBand oldWidget) => false;
}

/// Marks what a screen or a sheet stands over its bottom edge (the footer's
/// band, a floating bar), so a toast raised on that route rises above it
/// rather than over its buttons. Plumbing of the components; pages never
/// place one.
class FrostedBottomStand extends StatelessWidget {
  /// Creates a [FrostedBottomStand].
  const FrostedBottomStand({required this.child, super.key});

  /// What stands at the foot.
  final Widget child;

  /// How far above [overlay]'s bottom edge the stands on the route [context]
  /// is on reach; zero when it stands none. The whole route is searched: the
  /// caller may sit inside the screen or above it (the page's own state).
  static double reachOf(BuildContext context, RenderBox overlay) {
    var reach = 0.0;
    void visit(Element element) {
      if (element.widget is! FrostedBottomStand) {
        element.visitChildren(visit);
        return;
      }
      final box = element.findRenderObject();
      if (box is RenderBox && box.hasSize) {
        final top = box.localToGlobal(Offset.zero, ancestor: overlay).dy;
        reach = math.max(reach, overlay.size.height - top);
      }
    }

    ModalRoute.of(context)?.subtreeContext?.visitChildElements(visit);
    return reach;
  }

  @override
  Widget build(BuildContext context) => child;
}
