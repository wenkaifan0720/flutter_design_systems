// A curve over an animation that holds nothing to dispose: built in a build
// method or a route's transition builder, every frame if need be, it only
// reads its parent. (A CurvedAnimation made there is never disposed.)
import 'package:flutter/animation.dart';

/// [parent] through [curve], and through [reverseCurve] while it runs back.
Animation<double> studioCurved(
  Animation<double> parent,
  Curve curve, {
  Curve? reverseCurve,
}) => _StudioCurved(parent, curve, reverseCurve);

class _StudioCurved extends Animation<double>
    with AnimationWithParentMixin<double> {
  _StudioCurved(this.parent, this.curve, this.reverseCurve);

  @override
  final Animation<double> parent;

  final Curve curve;
  final Curve? reverseCurve;

  @override
  double get value {
    final back = reverseCurve;
    final c = back != null && parent.status == AnimationStatus.reverse
        ? back
        : curve;
    return c.transform(parent.value.clamp(0.0, 1.0));
  }
}
