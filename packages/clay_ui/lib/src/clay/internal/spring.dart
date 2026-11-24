/// A value that follows its target on a spring, for Clay's parts that move
/// something of their own (a switch's ball, a segment's thumb, a check).
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Builds [builder] at a value springing toward [target]: critically damped
/// by default (it arrives and stops), Reduce Motion honoured.
class ClaySpring extends StatefulWidget {
  /// A value following [target].
  const ClaySpring({
    super.key,
    required this.target,
    required this.builder,
    this.damping = ClayMotion.slideDamping,
    this.stiffness = ClayMotion.slideStiffness,
  });

  /// Where the value is going.
  final double target;

  /// Builds the part at the moment's value.
  final Widget Function(BuildContext context, double value) builder;

  /// The spring's damping ratio.
  final double damping;

  /// The spring's stiffness.
  final double stiffness;

  @override
  State<ClaySpring> createState() => _ClaySpringState();
}

class _ClaySpringState extends State<ClaySpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _value = AnimationController.unbounded(
    vsync: this,
    value: widget.target,
  );

  @override
  void didUpdateWidget(ClaySpring old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) {
      _value.springTo(
        widget.target,
        RawMotionPolicy.of(context)
            .spatial(dampingRatio: widget.damping, stiffness: widget.stiffness),
      );
    }
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _value,
    builder: (context, _) => widget.builder(context, _value.value),
  );
}
