/// A number that moves to each new value on one of Appliance's springs,
/// from wherever it stands (a switch's cap, a selector's block). Under
/// Reduce Motion the spring is critically damped.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Builds [builder] with a value springing toward [value].
class ApplianceSpringValue extends StatefulWidget {
  /// A value springing toward [value] on [spring].
  const ApplianceSpringValue({
    super.key,
    required this.value,
    required this.spring,
    required this.builder,
    this.spatial = true,
    this.child,
  });

  /// Where it goes.
  final double value;

  /// The spring it goes on.
  final ({double dampingRatio, double stiffness}) spring;

  /// Whether the spring moves something (critically damped under Reduce
  /// Motion) or only changes a colour (an effect).
  final bool spatial;

  /// Builds with the value now.
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;

  /// Passed through to [builder].
  final Widget? child;

  @override
  State<ApplianceSpringValue> createState() => _ApplianceSpringValueState();
}

class _ApplianceSpringValueState extends State<ApplianceSpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(ApplianceSpringValue old) {
    super.didUpdateWidget(old);
    if (old.value == widget.value) return;
    final policy = RawMotionPolicy.of(context);
    final s = widget.spring;
    _t.springTo(
      widget.value,
      widget.spatial
          ? policy.spatial(dampingRatio: s.dampingRatio, stiffness: s.stiffness)
          : policy.effects(
              dampingRatio: s.dampingRatio,
              stiffness: s.stiffness,
            ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _t,
    child: widget.child,
    builder: (context, child) => widget.builder(context, _t.value, child),
  );
}
