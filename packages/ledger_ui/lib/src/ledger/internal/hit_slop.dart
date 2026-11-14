import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// Takes taps over at least a [target] square centred on its child while
/// laying out at the child's own size: a 32 point disc keeps the place the
/// source gives it in a band and still answers the 44 point touch target
/// round it. Hit testing reaches a child only through its parent's bounds,
/// so the slop reaches as far as the room round the child does. The control
/// is one node to assistive technology, its child's semantics merged into
/// it, whose box is that reach: a screen reader outlines, and Flutter's
/// tap-target guidelines measure, the target a finger has, while the face
/// keeps its own size in layout. Plumbing of the components; pages never
/// place one.
class LedgerHitSlop extends SingleChildRenderObjectWidget {
  /// Takes taps over a [target] square round its child.
  const LedgerHitSlop({
    required super.child,
    this.target = LedgerLayout.minHitTarget,
    super.key,
  });

  /// The touch target's least side.
  final double target;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderHitSlop(target);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderHitSlop).target = target;
  }
}

class _RenderHitSlop extends RenderProxyBox {
  _RenderHitSlop(this._target);

  double _target;
  set target(double value) {
    if (value == _target) return;
    _target = value;
    markNeedsSemanticsUpdate();
  }

  /// The target round the face: at least [_target] on each side.
  Rect get _reach {
    final dx = math.max(0.0, (_target - size.width) / 2);
    final dy = math.max(0.0, (_target - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  Rect get semanticBounds => _reach;

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!_reach.contains(position)) return false;
    // Brought inside the child, whose own test checks its size.
    final inside = Offset(
      position.dx.clamp(0.0, math.max(0.0, size.width - 0.5)),
      position.dy.clamp(0.0, math.max(0.0, size.height - 0.5)),
    );
    if (hitTestChildren(result, position: inside)) {
      result.add(BoxHitTestEntry(this, position));
      return true;
    }
    return false;
  }
}
