import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Marks the band a screen or a sheet stands its footer in, so a bar that
/// also asks for a band of its own there is caught: the two would draw two
/// hairlines and inset the bar twice. Plumbing of the components; pages never
/// place one.
class Fluent2FooterBand extends InheritedWidget {
  /// Marks [child] as the footer's band.
  const Fluent2FooterBand({required super.child, super.key});

  /// Whether [context] stands in a screen's or a sheet's footer band.
  static bool around(BuildContext context) =>
      context.getInheritedWidgetOfExactType<Fluent2FooterBand>() != null;

  @override
  bool updateShouldNotify(Fluent2FooterBand oldWidget) => false;
}

/// Marks what a screen or a sheet stands over its bottom edge (the footer's
/// band, a floating bar), so a toast raised on that route rises above it
/// rather than over its buttons. Plumbing of the components; pages never
/// place one.
class Fluent2BottomStand extends StatelessWidget {
  /// Marks [child] as standing over the bottom edge.
  const Fluent2BottomStand({required this.child, super.key});

  /// The footer's band or the floating bar.
  final Widget child;

  /// How far above [overlay]'s bottom edge the stands on the route [context]
  /// is on reach; zero when it stands none. The whole route is searched: the
  /// caller may sit inside the screen or above it (the page's own state).
  static double reachOf(BuildContext context, RenderBox overlay) {
    var reach = 0.0;
    void visit(Element element) {
      if (element.widget is! Fluent2BottomStand) {
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
