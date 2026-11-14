import 'package:flutter/widgets.dart';

import '../theme.dart';

/// What a face is in one set of states, whole: its [ground] (the fill, the
/// rim and the drop as one decoration), the [ink] of its words and glyphs,
/// the [quiet] ink beside them (a count's) and the [rule] under its words
/// (an underline's ink; null for none).
/// Plumbing of the controls; pages never make one.
@immutable
class LedgerFaceStyle {
  /// A face of [ink] on [ground].
  const LedgerFaceStyle({
    required this.ink,
    this.ground = const BoxDecoration(),
    this.quiet,
    this.rule,
  });

  /// The fill, the rim and the drop.
  final BoxDecoration ground;

  /// The words' and the glyphs' ink.
  final Color ink;

  /// The quieter ink beside the words (a count's); null for none.
  final Color? quiet;

  /// The ink of the rule under the words; null draws none.
  final Color? rule;

  /// The style [t] of the way from [a] to [b]: every part of it at once.
  static LedgerFaceStyle lerp(LedgerFaceStyle a, LedgerFaceStyle b, double t) =>
      LedgerFaceStyle(
        ground: BoxDecoration.lerp(a.ground, b.ground, t)!,
        ink: Color.lerp(a.ink, b.ink, t)!,
        quiet: Color.lerp(a.quiet, b.quiet, t),
        rule: Color.lerp(a.rule, b.rule, t),
      );

  @override
  bool operator ==(Object other) =>
      other is LedgerFaceStyle &&
      other.ground == ground &&
      other.ink == ink &&
      other.quiet == quiet &&
      other.rule == rule;

  @override
  int get hashCode => Object.hash(ground, ink, quiet, rule);
}

/// Ledger's one motion for a change of state. A face resolves its
/// [LedgerFaceStyle] for its states and hands it here; when the states
/// change, the face goes from the style it shows to the new one whole (the
/// fill, the rim, the drop and the ink together), as ink fades in on paper,
/// in [duration] on [LedgerMotion.out]. A change that comes mid-way turns
/// from where the face is, never jumping back; with the platform's reduced
/// motion on, it switches at once. [builder] draws the
/// face in the style of the moment. Plumbing of the controls; pages never
/// place one.
class LedgerFace extends StatelessWidget {
  /// A face in [style], drawn by [builder].
  const LedgerFace({
    required this.style,
    required this.builder,
    this.duration = LedgerMotion.fast,
    this.child,
    super.key,
  });

  /// The style the face is going to.
  final LedgerFaceStyle style;

  /// Draws the face in the style of the moment, round [child].
  final Widget Function(
    BuildContext context,
    LedgerFaceStyle style,
    Widget? child,
  )
  builder;

  /// How long a change takes.
  final Duration duration;

  /// What stands inside the face and never changes with its style.
  final Widget? child;

  @override
  Widget build(BuildContext context) => _AnimatedFace(
    style: style,
    builder: builder,
    duration: LedgerMotion.of(context, duration),
    child: child,
  );
}

class _AnimatedFace extends ImplicitlyAnimatedWidget {
  const _AnimatedFace({
    required this.style,
    required this.builder,
    required super.duration,
    this.child,
  }) : super(curve: LedgerMotion.out);

  final LedgerFaceStyle style;
  final Widget Function(BuildContext, LedgerFaceStyle, Widget?) builder;
  final Widget? child;

  @override
  AnimatedWidgetBaseState<_AnimatedFace> createState() => _AnimatedFaceState();
}

class _AnimatedFaceState extends AnimatedWidgetBaseState<_AnimatedFace> {
  _FaceTween? _style;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _style = visitor(
      _style,
      widget.style,
      (value) => _FaceTween(begin: value as LedgerFaceStyle),
    ) as _FaceTween?;
  }

  @override
  Widget build(BuildContext context) =>
      widget.builder(context, _style!.evaluate(animation), widget.child);
}

class _FaceTween extends Tween<LedgerFaceStyle> {
  _FaceTween({super.begin});

  @override
  LedgerFaceStyle lerp(double t) => LedgerFaceStyle.lerp(begin!, end!, t);
}

/// A value on its way to [value], moving in Ledger's one motion (as
/// [LedgerFace] moves a whole face): a press's sink, a rule drawn in. A
/// change mid-way turns from where it is; with reduced motion on, it lands
/// at once. Plumbing of the controls.
class LedgerEase extends StatelessWidget {
  /// [builder] at the moment's value on its way to [value].
  const LedgerEase({
    required this.value,
    required this.builder,
    this.duration = LedgerMotion.fast,
    this.child,
    super.key,
  });

  /// Where it is going.
  final double value;

  /// Draws [child] at the moment's value.
  final ValueWidgetBuilder<double> builder;

  /// How long a change takes.
  final Duration duration;

  /// What stands inside and never changes with the value.
  final Widget? child;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween<double>(end: value),
    duration: LedgerMotion.of(context, duration),
    curve: LedgerMotion.out,
    builder: builder,
    child: child,
  );
}
