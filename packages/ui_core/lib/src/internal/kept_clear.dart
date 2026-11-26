/// Where the parts a toaster keeps clear stand (a tab bar, a page's foot),
/// for the surfaces opened over them: a popover prefers the side where it
/// stays clear of them. Inside ui_core; not exported.
library;

import 'package:flutter/widgets.dart';

/// A toaster's area and the bands along its top and bottom that its kept
/// parts take, as last measured.
class KeptClear {
  /// The toaster's box.
  RenderBox? box;

  /// The bands along the box's top and bottom, in its own coordinates.
  double top = 0;

  /// See [top].
  double bottom = 0;

  /// The box less its bands, in [to]'s coordinates; null with no band, or
  /// while either box is not laid out.
  Rect? freeIn(RenderBox to) {
    final box = this.box;
    if (top <= 0 && bottom <= 0) return null;
    if (box == null || !box.attached || !box.hasSize) return null;
    if (!to.attached || !to.hasSize) return null;
    final size = box.size;
    final a = to.globalToLocal(box.localToGlobal(Offset(0, top)));
    final b = to.globalToLocal(
      box.localToGlobal(Offset(size.width, size.height - bottom)),
    );
    return Rect.fromPoints(a, b);
  }
}

/// Carries a toaster's [KeptClear] to what opens below it.
class KeptClearScope extends InheritedWidget {
  /// Carries [area].
  const KeptClearScope({super.key, required this.area, required super.child});

  /// The toaster's area.
  final KeptClear area;

  /// The nearest toaster's area, without a dependency: it is read as a
  /// surface is placed.
  static KeptClear? maybeOf(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KeptClearScope>()?.area;

  @override
  bool updateShouldNotify(KeptClearScope oldWidget) =>
      !identical(area, oldWidget.area);
}
