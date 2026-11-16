import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../theme.dart';

/// Builds [builder] with a value that follows [value] on a Civic spring, so a
/// state change (a press, a focus, a check) moves continuously and never
/// snaps. [effects] runs it as an effects spring (a colour, an opacity),
/// which Reduce Motion shortens to a quick fade; otherwise it is spatial,
/// which Reduce Motion critically damps.
class CivicSpringValue extends StatefulWidget {
  /// Follows [value] on [spring].
  const CivicSpringValue({
    super.key,
    required this.value,
    required this.builder,
    this.spring = CivicMotion.state,
    this.effects = false,
    this.child,
  });

  /// Where the value is going.
  final double value;

  /// The spring it goes on.
  final CivicSpring spring;

  /// Whether this is a colour or opacity change rather than a move.
  final bool effects;

  /// Builds with the value as it moves.
  final ValueWidgetBuilder<double> builder;

  /// Passed through to [builder].
  final Widget? child;

  @override
  State<CivicSpringValue> createState() => _CivicSpringValueState();
}

class _CivicSpringValueState extends State<CivicSpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(CivicSpringValue oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      final policy = DesignMotionPolicy.of(context);
      final spring = widget.effects
          ? policy.effects(
              dampingRatio: widget.spring.dampingRatio,
              stiffness: widget.spring.stiffness,
            )
          : policy.spatial(
              dampingRatio: widget.spring.dampingRatio,
              stiffness: widget.spring.stiffness,
            );
      _controller.springTo(widget.value, spring);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _controller,
    builder: (context, child) =>
        widget.builder(context, _controller.value, child),
    child: widget.child,
  );
}
