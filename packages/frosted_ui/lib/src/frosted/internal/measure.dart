import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// The window width from which a control stops taking its column's width.
const double frostedMeasureFrom = 600;

/// The widest a select or a segmented control stands from
/// [frostedMeasureFrom] up.
const double frostedControlMeasure = 320;

/// A control's measure (its width on a wide layout): on a phone it
/// takes its column's width; from [frostedMeasureFrom] up it stands at the
/// column's start, at most [frostedControlMeasure] wide, so a select never
/// runs the width of a page for one word.
class FrostedControlMeasure extends StatelessWidget {
  /// Measures [child].
  const FrostedControlMeasure({required this.child, super.key});

  /// The control.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.sizeOf(context).width < frostedMeasureFrom) return child;
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: frostedControlMeasure),
        child: child,
      ),
    );
  }
}

/// A field's width: its column's, or, standing alone where nothing bounds
/// its width (a filter in a toolbar's row), its content's. Plumbing of the
/// components.
class FrostedFieldWidth extends SingleChildRenderObjectWidget {
  /// Sizes [child] as a field.
  const FrostedFieldWidth({required Widget super.child, super.key});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderFieldWidth();
}

class _RenderFieldWidth extends RenderProxyBox {
  @override
  void performLayout() {
    final child = this.child!;
    if (constraints.hasBoundedWidth) {
      child.layout(constraints, parentUsesSize: true);
    } else {
      final width = child.getMaxIntrinsicWidth(constraints.maxHeight);
      child.layout(constraints.tighten(width: width), parentUsesSize: true);
    }
    size = constraints.constrain(child.size);
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final child = this.child!;
    if (constraints.hasBoundedWidth) return child.getDryLayout(constraints);
    final width = child.getMaxIntrinsicWidth(constraints.maxHeight);
    return constraints.constrain(
      child.getDryLayout(constraints.tighten(width: width)),
    );
  }
}
