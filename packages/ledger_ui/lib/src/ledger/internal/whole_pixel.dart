import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// Every box Ledger sizes stands a whole pixel tall. A box of fractional
// height (a gauge 15.68 tall at 294 wide, a head whose two faces share a
// baseline 16.12 apart) sets every row under it on a fraction, and a 1 px
// rule there straddles two device rows and blurs. Plumbing of the
// components; a page's own pictures keep `AspectRatio`.

/// An [AspectRatio] whose height is a whole pixel: the width it is given
/// over [aspectRatio], rounded.
class LedgerWholeAspect extends SingleChildRenderObjectWidget {
  /// A box of [aspectRatio] whose height is whole.
  const LedgerWholeAspect({required this.aspectRatio, super.child, super.key});

  /// Width over height.
  final double aspectRatio;

  @override
  RenderAspectRatio createRenderObject(BuildContext context) =>
      _RenderWholeAspect(aspectRatio: aspectRatio);

  @override
  void updateRenderObject(
    BuildContext context,
    RenderAspectRatio renderObject,
  ) => renderObject.aspectRatio = aspectRatio;
}

class _RenderWholeAspect extends RenderAspectRatio {
  _RenderWholeAspect({required super.aspectRatio});

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final s = super.computeDryLayout(constraints);
    return constraints.constrain(Size(s.width, s.height.roundToDouble()));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width).roundToDouble();

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width).roundToDouble();
}

/// Its [child] at its own size, standing in a box of the nearest whole
/// height (the child at its top; a fraction over hangs, unclipped). For a
/// row whose parts of other faces share a baseline.
class LedgerWholeHeight extends SingleChildRenderObjectWidget {
  /// Stands its child in a box of whole height.
  const LedgerWholeHeight({super.child, super.key});

  @override
  RenderProxyBox createRenderObject(BuildContext context) =>
      _RenderWholeHeight();
}

class _RenderWholeHeight extends RenderProxyBox {
  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final s = child?.getDryLayout(constraints) ?? constraints.smallest;
    return constraints.constrain(Size(s.width, s.height.roundToDouble()));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.smallest;
      return;
    }
    c.layout(constraints, parentUsesSize: true);
    size = constraints.constrain(
      Size(c.size.width, c.size.height.roundToDouble()),
    );
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      super.computeMinIntrinsicHeight(width).roundToDouble();

  @override
  double computeMaxIntrinsicHeight(double width) =>
      super.computeMaxIntrinsicHeight(width).roundToDouble();
}
