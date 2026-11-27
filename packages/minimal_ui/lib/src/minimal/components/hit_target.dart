import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Drip's host layer: hands the tap floor's margin on through a parent that
/// hugs small controls and stops a tap at its own edge (a 28 px strip of
/// pills, an excluded face, a 20 px content line inside a padded row). A
/// render box rejects every point outside its own size before any child
/// sees it; wrapping that box here passes the margin on. An app does not
/// need it: each Minimal control lays its own tap target out.
///
/// It pads the HIT-TEST region only, never layout or paint. [line] is the
/// height of one line of controls (a pill row's 28 px); null takes the
/// wrapped box's own height. A point within the margin that brings a line up
/// to the floor is forwarded [inset] inside the box's nearest edge, past its
/// border and padding, where one of its controls takes it. Only the margin a
/// line needs is added: a box already at the floor gains nothing.
///
/// ```dart
/// MinimalHitTarget(line: 28, child: Row(children: pills))
/// ```
class MinimalHitTarget extends SingleChildRenderObjectWidget {
  /// Pads [child]'s hit area to the tap floor in force.
  const MinimalHitTarget({super.key, this.line, this.inset = 4, super.child});

  /// The height of one line of controls; null takes the box's own height.
  final double? line;

  /// How far inside the box's nearest edge a margin point is forwarded.
  final double inset;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitTarget(line, inset, RawTapTargets.of(context).floorOn().height);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHitTarget)
      ..line = line
      ..inset = inset
      ..floor = RawTapTargets.of(context).floorOn().height;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('line', line, defaultValue: null))
      ..add(DoubleProperty('inset', inset, defaultValue: 4));
  }
}

class _RenderHitTarget extends RenderProxyBox {
  _RenderHitTarget(this.line, this.inset, this.floor);

  double? line;
  double inset;
  double floor;

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (size.contains(position)) {
      return super.hitTest(result, position: position);
    }
    final dx = ((floor - size.width) / 2).clamp(0.0, double.infinity);
    final dy = ((floor - (line ?? size.height)) / 2).clamp(
      0.0,
      double.infinity,
    );
    if (position.dx < -dx ||
        position.dy < -dy ||
        position.dx > size.width + dx ||
        position.dy > size.height + dy) {
      return false;
    }
    double into(double v, double extent) {
      final edge = inset < extent / 2 ? inset : extent / 2;
      return v.clamp(edge, extent - edge);
    }

    return super.hitTest(
      result,
      position: Offset(
        into(position.dx, size.width),
        into(position.dy, size.height),
      ),
    );
  }
}
