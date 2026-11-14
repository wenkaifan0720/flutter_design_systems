/// A page's foot that a toast stands clear of.
library;

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Marks a page's footer (its act: Create, Save) so a toast never covers
/// it: [MinimalScaffold] wraps its footer in one, and
/// [showMinimalSnackBar] lifts the toast over every marked foot on the
/// current route that stands at the window's foot. A page calls the
/// toast with its own context, which is above its scaffold, so the feet
/// are found by registration rather than by an inherited lookup.
class MinimalPageFoot extends StatefulWidget {
  /// Marks [child] as a page's foot.
  const MinimalPageFoot({super.key, required this.child});

  /// The footer.
  final Widget child;

  static final Set<_MinimalPageFootState> _live = {};

  /// How far above the window's bottom edge a foot may end and still be
  /// the page's foot.
  static const double _footReach = 64;

  /// How far the current route's foot stands above the bottom edge of the
  /// window [context] is in; 0 with none.
  static double liftOf(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;
    var lift = 0.0;
    for (final foot in _live) {
      if (!foot.mounted) continue;
      if (!(ModalRoute.isCurrentOf(foot.context) ?? true)) continue;
      final box = foot.context.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final top = box.localToGlobal(Offset.zero).dy;
      // Only a foot at the window's own foot (a floating sheet's stands a
      // gap and the safe area above it): a page drawn small, in a
      // preview's frame, lifts nothing.
      if (top + box.size.height < height - _footReach) continue;
      lift = math.max(lift, height - top);
    }
    return lift;
  }

  @override
  State<MinimalPageFoot> createState() => _MinimalPageFootState();
}

class _MinimalPageFootState extends State<MinimalPageFoot> {
  @override
  void initState() {
    super.initState();
    MinimalPageFoot._live.add(this);
  }

  @override
  void dispose() {
    MinimalPageFoot._live.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
