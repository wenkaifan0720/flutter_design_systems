/// A value that springs to its target: how Terminal's presses, frames and
/// indicators move between states, on ui_core's spring and its Reduce Motion
/// policy.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// Builds [builder] with a value that springs from where it is to [target]
/// whenever [target] changes. [spatial] runs the token as a spatial spring
/// (something moves or resizes), else as an effects spring (a fill or a
/// colour); under Reduce Motion both settle without overshoot.
class TermSpring extends StatefulWidget {
  /// A value springing to [target] on [token].
  const TermSpring({
    super.key,
    required this.target,
    required this.token,
    required this.builder,
    this.spatial = false,
    this.child,
  });

  /// Where the value is going.
  final double target;

  /// The spring: a damping ratio and a stiffness.
  final ({double dampingRatio, double stiffness}) token;

  /// Whether the value moves something (spatial) or changes a fill or a
  /// colour (effects).
  final bool spatial;

  /// Builds with the value now.
  final Widget Function(BuildContext context, double value, Widget? child)
  builder;

  /// Passed through to [builder], built once.
  final Widget? child;

  @override
  State<TermSpring> createState() => _TermSpringState();
}

class _TermSpringState extends State<TermSpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _value = AnimationController.unbounded(
    vsync: this,
    value: widget.target,
  );

  @override
  void didUpdateWidget(TermSpring oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.target != widget.target) {
      final policy = DesignMotionPolicy.of(context);
      final spring = widget.spatial
          ? policy.spatial(
              dampingRatio: widget.token.dampingRatio,
              stiffness: widget.token.stiffness,
            )
          : policy.effects(
              dampingRatio: widget.token.dampingRatio,
              stiffness: widget.token.stiffness,
            );
      _value.springTo(widget.target, spring);
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
    builder: (context, child) => widget.builder(context, _value.value, child),
    child: widget.child,
  );
}

/// Ticks [builder] through whole steps: frame `0, 1, 2, …` every [period],
/// as a terminal's caret blinks and its spinner turns. Under Reduce Motion,
/// or when [running] is false, it holds at frame 0.
class TermStepper extends StatefulWidget {
  /// Steps every [period] while [running].
  const TermStepper({
    super.key,
    required this.period,
    required this.builder,
    this.running = true,
  });

  /// How long each frame shows.
  final Duration period;

  /// Whether it steps.
  final bool running;

  /// Builds frame [step].
  final Widget Function(BuildContext context, int step) builder;

  @override
  State<TermStepper> createState() => _TermStepperState();
}

class _TermStepperState extends State<TermStepper>
    with SingleTickerProviderStateMixin {
  late final _ticker = createTicker(_tick);
  int _step = 0;

  void _tick(Duration elapsed) {
    final step = elapsed.inMicroseconds ~/ widget.period.inMicroseconds;
    if (step != _step) setState(() => _step = step);
  }

  @override
  void didUpdateWidget(TermStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period) {
      _ticker.stop();
      _step = 0;
    }
  }

  // Followed in build: iOS's Reduce Motion changing comes as a build alone,
  // with no didChangeDependencies.
  void _sync() {
    final still = designReduceMotionOf(context);
    final run =
        widget.running && !still && TickerMode.valuesOf(context).enabled;
    if (run && !_ticker.isActive) {
      _ticker.start();
    } else if (!run && _ticker.isActive) {
      _ticker.stop();
      _step = 0;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _sync();
    return widget.builder(context, _step);
  }
}
