/// A bottom sheet's scroll hand-over: the scroll view inside a sheet gives
/// the sheet a drag first. Inside ui_core; not exported.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// What a sheet does with the drags its content's scroll view hands it.
abstract interface class SheetDragTarget {
  /// Whether the sheet takes a drag up: it is below its largest size, or
  /// partly slid away.
  bool get canGrow;

  /// Whether the sheet stands open at its largest size.
  bool get atLargest;

  /// A drag starts moving the sheet.
  void dragStart();

  /// Moves the sheet by [dy] logical pixels, down positive; returns what it
  /// did not take, for the content to scroll. Past its largest size it
  /// gives a little and resists when [stretch], else it stops there.
  double dragUpdate(double dy, {bool stretch = true});

  /// The drag let go at [velocity] logical pixels a second, down positive.
  void dragEnd(double velocity);

  /// The scroll view went mid-drag: the drag ends where it is.
  void dragAbandon();
}

/// The controller a sheet hands its content's scroll view
/// ([SheetScrollPosition]).
class SheetScrollController extends ScrollController {
  /// A controller whose positions hand drags to [target].
  SheetScrollController(this.target, {super.debugLabel});

  /// The sheet.
  final SheetDragTarget target;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) => SheetScrollPosition(
    target: target,
    physics: physics,
    context: context,
    oldPosition: oldPosition,
  );
}

/// A scroll position that lets a sheet take a drag first: up, the sheet
/// grows to its largest size before the content scrolls; down with the
/// content at its top, the sheet shrinks or slides away. Let go, the sheet
/// settles with the drag's speed, or the content flings on its own.
class SheetScrollPosition extends ScrollPositionWithSingleContext {
  /// A position that hands drags to [target].
  SheetScrollPosition({
    required this.target,
    required super.physics,
    required super.context,
    super.oldPosition,
  });

  /// The sheet.
  final SheetDragTarget target;

  bool _moving = false;

  bool get _atTop => pixels <= minScrollExtent;

  // As DraggableScrollableSheet's position: with the content at its top the
  // sheet takes the drag, but a drag up at its largest size, which scrolls
  // the content; scrolled, the content takes it, down to its top, and the
  // sheet the rest.
  @override
  void applyUserOffset(double delta) {
    // delta > 0: the finger moves down.
    if (delta > 0 && !_atTop) {
      final scroll = math.min(delta, pixels - minScrollExtent);
      super.applyUserOffset(scroll);
      delta -= scroll;
      if (delta <= 0 || !_atTop) return;
    }
    if (!_atTop || (delta < 0 && !target.canGrow)) {
      super.applyUserOffset(delta);
      return;
    }
    if (!_moving) {
      _moving = true;
      target.dragStart();
    }
    final left = target.dragUpdate(delta, stretch: false);
    if (left < 0) super.applyUserOffset(left);
  }

  @override
  void goBallistic(double velocity) {
    if (!_moving) {
      super.goBallistic(velocity);
      return;
    }
    _moving = false;
    // velocity > 0: the content would scroll on, the finger flung up.
    final contentFlings =
        (velocity > 0 && target.atLargest) || (velocity < 0 && !_atTop);
    if (contentFlings) {
      target.dragEnd(0);
      super.goBallistic(velocity);
    } else {
      target.dragEnd(-velocity);
      super.goBallistic(0);
    }
  }

  @override
  void dispose() {
    if (_moving) {
      _moving = false;
      target.dragAbandon();
    }
    super.dispose();
  }
}
