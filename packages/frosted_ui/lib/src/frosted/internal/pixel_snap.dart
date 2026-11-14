import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// Paints [child] with its left edge on the device-pixel grid: at most half
/// a device pixel off where layout put it, and only while nothing above it
/// scales or turns it (its baseline is already whole: DesignCapCenter). A
/// small label (12 px in DM Sans at 500) laid at a fractional x draws stems
/// of under two device pixels that cover no pixel whole on a screen without
/// stem darkening (FreeType on Linux), so its words read as their edge's
/// shade, not their ink; laid on the grid, more of its stems keep pixels of
/// full ink. Plumbing of the filter chips' and the segments' words; hit
/// testing follows the shift.
class FrostedPixelSnap extends SingleChildRenderObjectWidget {
  /// Snaps [child]'s left edge to the grid.
  const FrostedPixelSnap({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPixelSnap(View.of(context).devicePixelRatio);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderPixelSnap).devicePixelRatio = View.of(context)
        .devicePixelRatio;
  }
}

class _RenderPixelSnap extends RenderProxyBox {
  _RenderPixelSnap(this._devicePixelRatio);

  double _devicePixelRatio;
  set devicePixelRatio(double value) {
    if (value == _devicePixelRatio) return;
    _devicePixelRatio = value;
    markNeedsPaint();
  }

  // The shift of the last paint, which hit testing and transforms follow.
  Offset _shift = Offset.zero;

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child == null) return;
    final m = getTransformTo(null).storage;
    // A plain translation: no scale, turn or perspective above.
    final plain =
        m[0] == 1 &&
        m[5] == 1 &&
        m[10] == 1 &&
        m[15] == 1 &&
        m[1] == 0 &&
        m[2] == 0 &&
        m[3] == 0 &&
        m[4] == 0 &&
        m[6] == 0 &&
        m[7] == 0 &&
        m[8] == 0 &&
        m[9] == 0 &&
        m[11] == 0;
    if (!plain) {
      _shift = Offset.zero;
    } else {
      final x = m[12] * _devicePixelRatio;
      _shift = Offset((x.roundToDouble() - x) / _devicePixelRatio, 0);
    }
    context.paintChild(child, offset + _shift);
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(_shift.dx, _shift.dy, 0, 1);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: _shift,
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }
}
