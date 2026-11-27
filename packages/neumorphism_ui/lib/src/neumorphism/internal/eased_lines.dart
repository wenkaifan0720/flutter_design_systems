// What a field changes as it turns wrong, right again, or takes the focus, eased: the line under it, the mark at its
// end and its label's ink. Nothing a field shows arrives in one frame.
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The line under a field (its help, or what is wrong) as it comes, changes and goes: the room it takes eases open or
/// shut as its words fade, so what stands below the field slides rather than jumps. [gap] stands over the words and
/// comes and goes with them. A line of another key or type (help to error) crosses; the same line with new words
/// changes in place. Under Reduce Motion it cuts.
class NeumorphicHintSlot extends StatelessWidget {
  /// The line [child] (null for none) under a gap of [gap].
  const NeumorphicHintSlot({super.key, required this.child, this.gap = 8});

  /// The line, or null for none.
  final Widget? child;

  /// The room over the line, which goes with it.
  final double gap;

  @override
  Widget build(BuildContext context) {
    final motion = NeumorphicMotion.of(context);
    final line = child;
    final Widget current = line == null
        ? const SizedBox.shrink(key: ValueKey<Type>(NeumorphicHintSlot))
        : Padding(
            key: line.key ?? ValueKey<Type>(line.runtimeType),
            padding: EdgeInsets.only(top: gap),
            child: line,
          );
    return AnimatedSwitcher(
      duration: motion.move,
      switchInCurve: motion.enter,
      switchOutCurve: motion.enter,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: AlignmentDirectional.topStart,
        child: FadeTransition(opacity: animation, child: child),
      ),
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: current,
    );
  }
}

/// The place of a field's error mark at its end: while [shown] the mark ([child], with the room before it) fades in
/// there, the entry giving it its width as it comes, and out as the field is put right; nothing stands there while it
/// is right. Under Reduce Motion it cuts.
class NeumorphicMarkSlot extends StatelessWidget {
  /// [child] at a field's end while [shown].
  const NeumorphicMarkSlot({
    super.key,
    required this.shown,
    required this.child,
  });

  /// Whether the field is wrong.
  final bool shown;

  /// The mark, with the room before it.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = NeumorphicMotion.of(context);
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: shown ? 1 : 0),
      duration: motion.state,
      curve: motion.enter,
      builder: (context, v, child) => switch (v) {
        <= 0 => const SizedBox.shrink(),
        >= 1 => child!,
        _ => ClipRect(
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: v,
            heightFactor: 1,
            child: Opacity(opacity: v, child: child),
          ),
        ),
      },
      child: child,
    );
  }
}

/// A field's label in [style], naming itself in the pigment's ink while [lit] (its field has the focus), easing across
/// as the focus comes and goes. Under Reduce Motion it cuts.
class NeumorphicLabelInk extends StatelessWidget {
  /// [child] in [style], in the pigment's ink while [lit].
  const NeumorphicLabelInk({
    super.key,
    required this.lit,
    required this.style,
    required this.child,
  });

  /// Whether the field has the focus.
  final bool lit;

  /// The label's style; its colour is the ink at rest (else the one in scope).
  final TextStyle style;

  /// The label.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final motion = NeumorphicMotion.of(context);
    final rest =
        style.color ?? DefaultTextStyle.of(context).style.color ?? t.colors.ink;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: lit ? 1 : 0),
      duration: motion.state,
      curve: motion.standard,
      builder: (context, v, child) => DefaultTextStyle.merge(
        style: style.copyWith(color: Color.lerp(rest, t.colors.pigmentInk, v)),
        child: child!,
      ),
      child: child,
    );
  }
}
