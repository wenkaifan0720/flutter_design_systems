/// Where the shell's navigation a toaster keeps clear stands (its tab bar,
/// its top header), for the surfaces opened over the page: a popover prefers
/// the side where it stays clear of it, and a sheet stands on the bar. A
/// page's own foot or top bar, kept clear for the toasts, is the page's: the
/// surfaces open over it. Inside ui_core; not exported.
library;

import 'dart:math' as math;

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// A toaster's area and the bands along its top and bottom that the shell's
/// navigation takes (the parts kept clear under a [KeptNavigationBar]), as
/// last measured. It tells its listeners as they change, after the frame
/// when one is being built.
class KeptClear extends ChangeNotifier {
  /// The toaster's box.
  RenderBox? box;

  /// The band the shell's top header takes along the box's top, in its own
  /// coordinates.
  double get top => _top;

  /// The band the shell's navigation bar takes along the box's bottom, in
  /// its own coordinates: where a sheet stands. Not a page's foot, which the
  /// sheet covers as part of the page under its barrier, whether it stands
  /// on the bar or on the screen's foot; nor a key floating over the bar,
  /// nor a part on a popup (a sheet's own foot).
  double get bottom => _bottom;

  double _top = 0;
  double _bottom = 0;
  bool _telling = false;
  bool _disposed = false;

  /// Takes the bands as measured, and tells the listeners if they moved.
  void update({required double top, required double bottom}) {
    if (top == _top && bottom == _bottom) return;
    _top = top;
    _bottom = bottom;
    if (SchedulerBinding.instance.schedulerPhase !=
        SchedulerPhase.persistentCallbacks) {
      notifyListeners();
      return;
    }
    // Measured as a frame is built: its listeners rebuild after it.
    if (_telling) return;
    _telling = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _telling = false;
      if (!_disposed) notifyListeners();
    });
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  bool _laidOut(RenderBox? box) => box != null && box.attached && box.hasSize;

  /// The box less its bands, in [to]'s coordinates; null with no band, or
  /// while either box is not laid out.
  Rect? freeIn(RenderBox to) {
    final box = this.box;
    if (_top <= 0 && _bottom <= 0) return null;
    if (!_laidOut(box) || !_laidOut(to)) return null;
    final size = box!.size;
    final a = to.globalToLocal(box.localToGlobal(Offset(0, _top)));
    final b = to.globalToLocal(
      box.localToGlobal(Offset(size.width, size.height - _bottom)),
    );
    return Rect.fromPoints(a, b);
  }

  /// How much of [to]'s box, from its foot, the [bottom] band takes, in
  /// [to]'s coordinates: 0 with none, where [to] ends above it, or while
  /// either box is not laid out.
  double floorIn(RenderBox to) {
    final box = this.box;
    if (_bottom <= 0 || !_laidOut(box) || !_laidOut(to)) return 0;
    final top = to
        .globalToLocal(box!.localToGlobal(Offset(0, box.size.height - _bottom)))
        .dy;
    return math.max(0, to.size.height - math.max(0, top));
  }
}

/// Marks the parts kept clear below it as the shell's navigation, the one
/// part a sheet stands on and a popover keeps clear of (`RawAdaptiveShell`
/// puts its navigation in one). A page's foot kept clear for the toasts is
/// not in one.
class KeptNavigationBar extends InheritedWidget {
  /// Marks [child].
  const KeptNavigationBar({super.key, required super.child});

  /// Whether [context] stands in one; read once, as a part is created or
  /// updated, without a dependency.
  static bool of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<KeptNavigationBar>() != null;

  @override
  bool updateShouldNotify(KeptNavigationBar oldWidget) => false;
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

/// Builds a sheet [route]'s panel standing on the nearest toaster's
/// [KeptClear.bottom] (the shell's navigation bar, where the route's overlay
/// reaches over it): [builder] gets the floor's height across the overlay, and
/// builds again as it moves; 0 with no toaster above the route.
class KeptFloorBuilder extends StatelessWidget {
  /// Builds [builder] on [route]'s floor.
  const KeptFloorBuilder({
    super.key,
    required this.route,
    required this.builder,
  });

  /// The route the panel is the page of.
  final ModalRoute<Object?> route;

  /// Builds the panel on a floor of the given height.
  final Widget Function(BuildContext context, double floor) builder;

  /// [data] as a panel standing on a floor [floor] high sees it: the bars
  /// under it take the bottom inset as far as they reach.
  static MediaQueryData standingOn(MediaQueryData data, double floor) {
    if (floor <= 0) return data;
    double less(double inset) => math.max(0, inset - floor);
    return data.copyWith(
      padding: data.padding.copyWith(bottom: less(data.padding.bottom)),
      viewPadding: data.viewPadding.copyWith(
        bottom: less(data.viewPadding.bottom),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final area = KeptClearScope.maybeOf(context);
    if (area == null) return builder(context, 0);
    return ListenableBuilder(
      listenable: area,
      builder: (context, _) {
        final overlay = route.navigator?.overlay?.context.findRenderObject();
        return builder(
          context,
          overlay is RenderBox ? area.floorIn(overlay) : 0,
        );
      },
    );
  }
}
