import 'package:flutter/widgets.dart';

/// The window width from which a control stops taking its column's width.
const double frostedMeasureFrom = 600;

/// The widest a select or a segmented control stands from
/// [frostedMeasureFrom] up.
const double frostedControlMeasure = 320;

/// A control's measure (design6 P, width on a wide layout): on a phone it
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
