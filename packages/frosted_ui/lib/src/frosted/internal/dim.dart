import 'package:flutter/widgets.dart';

import '../chrome_metrics.dart';
import '../theme.dart';

/// [child] at [opacity], easing to a new one over [FrostedMotion.fast] from
/// wherever it stands when the change comes (a cut under Reduce Motion).
/// Always in the tree, whatever the opacity, so the part under it keeps its
/// state (a field keeps its focus). A press's fade, a disabled part's dim, a
/// focus light coming and going. Plumbing of the components; pages never
/// place one.
class FrostedFade extends StatelessWidget {
  /// Creates a [FrostedFade].
  const FrostedFade({required this.opacity, required this.child, super.key});

  /// The opacity to stand at.
  final double opacity;

  /// What is drawn.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final motion = FrostedMotion.of(context);
    return AnimatedOpacity(
      opacity: opacity,
      duration: motion.fast,
      curve: motion.curve,
      child: child,
    );
  }
}

/// The one way Frosted draws what cannot be used: [child] at
/// [FrostedChromeMetrics.disabledOpacity], once. A row that is off dims as
/// one thing, its words and its control together, and a control inside it
/// is then drawn at full strength, so nothing is dimmed twice (a switch in a
/// settings row that is off reads as the row does). With [off] false it is
/// [child] at full strength. Turning off or on eases (a [FrostedFade]), and
/// the part stays in the tree either way. Plumbing of the components; pages
/// never place one.
class FrostedDim extends StatelessWidget {
  /// Creates a [FrostedDim].
  const FrostedDim({required this.child, this.off = true, super.key});

  /// Whether [child] is drawn off.
  final bool off;

  /// What is drawn.
  final Widget child;

  /// Whether a part above [context] already draws it off.
  static bool inDimmed(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_Dimmed>()?.off ?? false;

  @override
  Widget build(BuildContext context) {
    final above = inDimmed(context);
    return FrostedFade(
      opacity: off && !above ? FrostedChromeMetrics.disabledOpacity : 1,
      child: _Dimmed(off: off || above, child: child),
    );
  }
}

class _Dimmed extends InheritedWidget {
  const _Dimmed({required this.off, required super.child});

  /// Whether what is under it is drawn off.
  final bool off;

  @override
  bool updateShouldNotify(_Dimmed oldWidget) => oldWidget.off != off;
}

/// Builds with [value], easing to a new one over [FrostedMotion.fast] from
/// the value shown when the change comes (a cut under Reduce Motion), each
/// frame through [lerp]: a word's style or a glyph's ink following its
/// part's state, as its face does. Plumbing of the components; pages never
/// place one.
class FrostedEase<T extends Object> extends StatelessWidget {
  /// Creates a [FrostedEase].
  const FrostedEase({
    required this.value,
    required this.lerp,
    required this.builder,
    super.key,
  });

  /// The value to arrive at.
  final T value;

  /// The value between two, at a fraction.
  final T Function(T a, T b, double t) lerp;

  /// Draws with the value shown.
  final Widget Function(BuildContext context, T value) builder;

  /// A word's style.
  static TextStyle words(TextStyle a, TextStyle b, double t) =>
      TextStyle.lerp(a, b, t)!;

  /// A glyph's ink and a word's style together.
  static (Color, TextStyle) inkAndWords(
    (Color, TextStyle) a,
    (Color, TextStyle) b,
    double t,
  ) => (Color.lerp(a.$1, b.$1, t)!, TextStyle.lerp(a.$2, b.$2, t)!);

  @override
  Widget build(BuildContext context) {
    final motion = FrostedMotion.of(context);
    return TweenAnimationBuilder<T>(
      tween: _LerpTween<T>(value, lerp),
      duration: motion.fast,
      curve: motion.curve,
      builder: (context, shown, _) => builder(context, shown),
    );
  }
}

class _LerpTween<T extends Object> extends Tween<T> {
  _LerpTween(T end, this.between) : super(end: end);

  final T Function(T a, T b, double t) between;

  @override
  T lerp(double t) => between(begin!, end!, t);
}
