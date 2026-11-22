import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [child] centred in the room it is given, as [Center] does, on whole
/// device pixels: a card centred on an odd remainder of room would stand
/// on a half pixel, and every hairline in it would print as two rows of
/// half ink.
class LedgerPixelCenter extends SingleChildRenderObjectWidget {
  /// Centres [child] on a whole device pixel.
  const LedgerPixelCenter({super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPixelCenter(MediaQuery.devicePixelRatioOf(context));

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderPixelCenter).ratio = MediaQuery.devicePixelRatioOf(
      context,
    );
  }
}

class _RenderPixelCenter extends RenderPositionedBox {
  _RenderPixelCenter(this._ratio);

  double _ratio;
  set ratio(double value) {
    if (value == _ratio) return;
    _ratio = value;
    markNeedsLayout();
  }

  @override
  void alignChild() {
    super.alignChild();
    final data = child!.parentData! as BoxParentData;
    double snap(double v) => (v * _ratio).roundToDouble() / _ratio;
    data.offset = Offset(snap(data.offset.dx), snap(data.offset.dy));
  }
}
