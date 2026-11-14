// Out of use, said in the material (msg_b070e9db183e): no fade. A part out of use goes flat and its colours move toward
// the ground, so it reads as part of the wall rather than a control behind glass.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../frames.dart';
import '../theme.dart';

/// How far a part out of use moves each colour it paints toward the ground: its words land near the quiet ink.
const double _towardGround = .5;

/// Out of use, in the material: the part goes flat (no light and no shadow, flush with the ground) and every colour it
/// paints moves halfway to the ground, so its words read in the quiet ink and its pigment pales. Not a fade: the
/// ground under it stays the ground and nothing shows through. In use it changes nothing and adds no layer, and the
/// wrapper stays in the tree either way, so turning a part off never remounts it.
///
/// Inside another part that is out of use it adds nothing: the colours move toward the ground once.
///
/// ```dart
/// NeumorphicOutOfUse(off: onPressed == null, child: face)
/// ```
class NeumorphicOutOfUse extends StatelessWidget {
  /// Creates a [NeumorphicOutOfUse].
  const NeumorphicOutOfUse({super.key, required this.off, required this.child});

  /// Whether the part is out of use.
  final bool off;

  /// The part.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final under =
        context.dependOnInheritedWidgetOfExactType<_Off>()?.active ?? false;
    final motion = NeumorphicMotion.of(context);
    final ground = NeumorphicTheme.of(context).colors.ground;
    final parentFlat = NeumorphicFlatScope.of(context);
    // Going out of use and back is one motion: the relief sinks to flush and the colours move toward the ground
    // together. The wrappers stay in the tree, so nothing remounts.
    return TweenAnimationBuilder<double>(
      tween: Tween(end: off ? 1 : 0),
      duration: motion.state,
      curve: motion.standard,
      child: child,
      builder: (context, amount, child) => NeumorphicFlatScope(
        flat: amount >= 1 || parentFlat,
        relief: 1 - amount,
        child: _TowardGround(
          amount > 0 && !under ? ground : null,
          amount,
          child: _Off(active: off && !under, child: child!),
        ),
      ),
    );
  }
}

/// Marks a subtree whose colours already move toward the ground.
class _Off extends InheritedWidget {
  const _Off({required this.active, required super.child});
  final bool active;

  @override
  bool updateShouldNotify(_Off oldWidget) => oldWidget.active != active;
}

class _TowardGround extends SingleChildRenderObjectWidget {
  const _TowardGround(this.ground, this.amount, {super.child});
  final Color? ground;
  final double amount;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderTowardGround(ground, amount);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) =>
      (renderObject as _RenderTowardGround)
        ..ground = ground
        ..amount = amount;
}

class _RenderTowardGround extends RenderProxyBox {
  _RenderTowardGround(this._ground, this._amount);

  double _amount;
  set amount(double value) {
    if (value == _amount) return;
    _amount = value;
    markNeedsPaint();
  }

  Color? _ground;
  set ground(Color? value) {
    if (value == _ground) return;
    final changed = (value == null) != (_ground == null);
    _ground = value;
    if (changed) markNeedsCompositingBitsUpdate();
    markNeedsPaint();
  }

  @override
  bool get alwaysNeedsCompositing => child != null && _ground != null;

  @override
  void paint(PaintingContext context, Offset offset) {
    final g = _ground;
    if (g == null || child == null) {
      layer = null;
      super.paint(context, offset);
      return;
    }
    final toward = _towardGround * _amount.clamp(0.0, 1.0);
    final k = 1 - toward;
    layer = context.pushColorFilter(
      offset,
      ColorFilter.matrix(<double>[
        k, 0, 0, 0, toward * g.r * 255, //
        0, k, 0, 0, toward * g.g * 255, //
        0, 0, k, 0, toward * g.b * 255, //
        0, 0, 0, 1, 0, //
      ]),
      super.paint,
      oldLayer: layer as ColorFilterLayer?,
    );
  }
}
