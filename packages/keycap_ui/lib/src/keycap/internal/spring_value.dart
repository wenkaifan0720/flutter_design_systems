/// A number that springs to each new value it is given.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Rebuilds [builder] with a value springing toward [value] on [spring],
/// through `RawMotionPolicy` (critically damped under Reduce Motion;
/// [spatial] false runs it as an effect: a colour, a fade).
class KeycapSpringValue extends StatefulWidget {
  /// Springs toward [value].
  const KeycapSpringValue({
    super.key,
    required this.value,
    required this.spring,
    required this.builder,
    this.spatial = true,
    this.child,
  });

  /// Where the value is going.
  final double value;

  /// How it goes there.
  final ({double dampingRatio, double stiffness}) spring;

  /// Whether the value moves something (true) or changes an effect (false).
  final bool spatial;

  /// Builds with the value as it moves.
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;

  /// Handed to [builder] unchanged.
  final Widget? child;

  @override
  State<KeycapSpringValue> createState() => _KeycapSpringValueState();
}

class _KeycapSpringValueState extends State<KeycapSpringValue>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(KeycapSpringValue old) {
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

/// Rebuilds [builder] with a colour springing toward [color]: on [darken]
/// when the new colour is more opaque (a floor going down under a finger),
/// else on [lighten]. An effect: Reduce Motion keeps it, quickened.
class KeycapSpringColor extends StatefulWidget {
  /// Springs toward [color].
  const KeycapSpringColor({
    super.key,
    required this.color,
    required this.darken,
    required this.lighten,
    required this.builder,
    this.child,
  });

  /// Where the colour is going.
  final Color color;

  /// The spring toward a more opaque colour.
  final ({double dampingRatio, double stiffness}) darken;

  /// The spring toward a clearer one.
  final ({double dampingRatio, double stiffness}) lighten;

  /// Builds with the colour as it moves.
  final Widget Function(BuildContext context, Color color, Widget? child)
  builder;

  /// Handed to [builder] unchanged.
  final Widget? child;

  @override
  State<KeycapSpringColor> createState() => _KeycapSpringColorState();
}

class _KeycapSpringColorState extends State<KeycapSpringColor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this)
    ..value = 1;
  late Color _from = widget.color;
  late Color _to = widget.color;

  Color get _now =>
      _t.value >= 1 ? _to : Color.lerp(_from, _to, _t.value.clamp(0.0, 1.0))!;

  @override
  void didUpdateWidget(KeycapSpringColor old) {
    super.didUpdateWidget(old);
    if (widget.color == _to) return;
    final now = _now;
    final s = widget.color.a > now.a ? widget.darken : widget.lighten;
    _from = now;
    _to = widget.color;
    _t
      ..value = 0
      ..springTo(
        1,
        RawMotionPolicy.of(context)
            .effects(dampingRatio: s.dampingRatio, stiffness: s.stiffness),
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
    builder: (context, child) => widget.builder(context, _now, child),
  );
}
