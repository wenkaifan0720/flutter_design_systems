import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';

/// How a face looks at one moment: what [TendSurface] paints and what
/// [AnimatedTendSurface] moves between as the part's states change.
@immutable
class TendFace {
  /// A face of [fill] in a rule of [rule], [ruleWidth] wide.
  const TendFace({
    required this.fill,
    required this.rule,
    required this.foreground,
    this.ruleWidth = 1,
  });

  /// The plate.
  final Color fill;

  /// The rule round the plate.
  final Color rule;

  /// The rule's width: 1 at rest, 2 under keyboard focus.
  final double ruleWidth;

  /// The words and glyphs on the plate.
  final Color foreground;

  /// Between [a] and [b] at [t].
  static TendFace lerp(TendFace a, TendFace b, double t) => TendFace(
    fill: Color.lerp(a.fill, b.fill, t)!,
    rule: Color.lerp(a.rule, b.rule, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
    ruleWidth: lerpDouble(a.ruleWidth, b.ruleWidth, t)!,
  );

  @override
  bool operator ==(Object other) =>
      other is TendFace &&
      other.fill == fill &&
      other.rule == rule &&
      other.foreground == foreground &&
      other.ruleWidth == ruleWidth;

  @override
  int get hashCode => Object.hash(fill, rule, foreground, ruleWidth);
}

/// Paints [face] in [shape] behind [child], and gives [child] the face's
/// foreground for its words and glyphs.
class TendSurface extends StatelessWidget {
  /// [child] on [face].
  const TendSurface({
    super.key,
    required this.face,
    required this.shape,
    this.child,
  });

  /// What to paint.
  final TendFace face;

  /// The outline; the face's rule is drawn on it.
  final OutlinedBorder shape;

  /// What stands on the face.
  final Widget? child;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: ShapeDecoration(
      color: face.fill,
      shape: shape.copyWith(
        side: BorderSide(color: face.rule, width: face.ruleWidth),
      ),
    ),
    child: DefaultTextStyle.merge(
      style: TextStyle(color: face.foreground),
      child: IconTheme.merge(
        data: IconThemeData(color: face.foreground),
        child: child ?? const SizedBox.shrink(),
      ),
    ),
  );
}

/// A [TendSurface] that moves to each new [face] on the theme's state
/// spring, from wherever it stands: a press, a release, a focus or a change
/// of colour turns mid-way with no jump. Under Reduce Motion the change is a
/// short fade, as [RawMotionPolicy] says.
class AnimatedTendSurface extends StatefulWidget {
  /// [child] on a face that moves to [face].
  const AnimatedTendSurface({
    super.key,
    required this.face,
    required this.shape,
    this.child,
  });

  /// The face to arrive at.
  final TendFace face;

  /// The outline.
  final OutlinedBorder shape;

  /// What stands on the face.
  final Widget? child;

  @override
  State<AnimatedTendSurface> createState() => _AnimatedTendSurfaceState();
}

class _AnimatedTendSurfaceState extends State<AnimatedTendSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    value: 1,
  );
  late TendFace _from = widget.face;
  late TendFace _to = widget.face;

  TendFace get _now => TendFace.lerp(_from, _to, _controller.value);

  @override
  void didUpdateWidget(AnimatedTendSurface old) {
    super.didUpdateWidget(old);
    if (widget.face == _to) return;
    _from = _now;
    _to = widget.face;
    final motion = TendTheme.of(context).motion;
    _controller
      ..value = 0
      ..springTo(
        1,
        RawMotionPolicy.of(context).effects(
          dampingRatio: motion.stateDampingRatio,
          stiffness: motion.stateStiffness,
        ),
      );
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
        TendSurface(face: _now, shape: widget.shape, child: child),
    child: widget.child,
  );
}

/// Builds with a number that moves to each new [value] on the theme's state
/// spring: a thumb's travel, a mark's scale. A spatial motion, so under
/// Reduce Motion it arrives without overshoot ([RawMotionPolicy.spatial]).
class TendSpringBuilder extends StatefulWidget {
  /// Builds [builder] with a number springing to [value].
  const TendSpringBuilder({
    super.key,
    required this.value,
    required this.builder,
    this.child,
  });

  /// Where the number is going.
  final double value;

  /// Builds with the number where it stands now.
  final ValueWidgetBuilder<double> builder;

  /// Passed to [builder] untouched.
  final Widget? child;

  @override
  State<TendSpringBuilder> createState() => _TendSpringBuilderState();
}

class _TendSpringBuilderState extends State<TendSpringBuilder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController.unbounded(
    vsync: this,
    value: widget.value,
  );

  @override
  void didUpdateWidget(TendSpringBuilder old) {
    super.didUpdateWidget(old);
    if (widget.value == old.value) return;
    final motion = TendTheme.of(context).motion;
    _controller.springTo(
      widget.value,
      RawMotionPolicy.of(context).spatial(
        dampingRatio: motion.stateDampingRatio,
        stiffness: motion.stateStiffness,
      ),
    );
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
