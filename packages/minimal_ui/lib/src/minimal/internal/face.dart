/// Minimal's one motion for a change of state: a part's face lerps.
library;

import 'package:flutter/widgets.dart';

import '../theme.dart';

/// A part's face, which moves to each new state the way Minimal moves: a
/// short plain fade. The face's whole style (its decoration, so its fill,
/// rim, ring and any shadow, and the [ink] its words and glyph are drawn
/// in) lerps from where it is to where the new state puts it, in
/// [MinimalMotion.base] on [MinimalMotion.out]. It is an implicit
/// animation over the style, not a tween per widget, so a change that comes
/// mid-way turns from where the face is, with no jump back; with reduced
/// motion ([MinimalMotionContext.minimalStill]) it switches at once.
///
/// It lays out as a [Container] with the same box fields. [builder] draws
/// what stands on the face, in the [ink] of the moment.
class MinimalFace extends StatelessWidget {
  /// A face wearing [decoration], its words in [ink].
  const MinimalFace({
    super.key,
    this.decoration,
    this.foregroundDecoration,
    this.ink,
    this.width,
    this.height,
    this.constraints,
    this.padding,
    this.alignment,
    this.duration,
    this.clipBehavior = Clip.none,
    required this.builder,
  });

  /// The face: fill, rim, ring, shadow.
  final Decoration? decoration;

  /// What lies over the face.
  final Decoration? foregroundDecoration;

  /// The ink the face's words and glyph are drawn in.
  final Color? ink;

  /// The face's width.
  final double? width;

  /// The face's height.
  final double? height;

  /// The face's constraints.
  final BoxConstraints? constraints;

  /// The air inside the face.
  final EdgeInsetsGeometry? padding;

  /// Where the content stands in the face.
  final AlignmentGeometry? alignment;

  /// How long a change takes; null is [MinimalMotion.base].
  final Duration? duration;

  /// Whether the face clips what stands on it to its outline.
  final Clip clipBehavior;

  /// What stands on the face, drawn in the ink of the moment.
  final Widget Function(BuildContext context, Color? ink) builder;

  @override
  Widget build(BuildContext context) => _FaceMotion(
    face: this,
    duration: context.minimalStill
        ? Duration.zero
        : (duration ?? MinimalMotion.base),
    curve: MinimalMotion.out,
  );
}

class _FaceMotion extends ImplicitlyAnimatedWidget {
  const _FaceMotion({required this.face, required super.duration, super.curve});

  final MinimalFace face;

  @override
  AnimatedWidgetBaseState<_FaceMotion> createState() => _FaceMotionState();
}

class _FaceMotionState extends AnimatedWidgetBaseState<_FaceMotion> {
  DecorationTween? _decoration;
  DecorationTween? _foreground;
  ColorTween? _ink;

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    final face = widget.face;
    _decoration = visitor(
      _decoration,
      face.decoration,
      (value) => DecorationTween(begin: value as Decoration),
    ) as DecorationTween?;
    _foreground = visitor(
      _foreground,
      face.foregroundDecoration,
      (value) => DecorationTween(begin: value as Decoration),
    ) as DecorationTween?;
    _ink = visitor(
      _ink,
      face.ink,
      (value) => ColorTween(begin: value as Color),
    ) as ColorTween?;
  }

  /// A box that is only a clear fill (a row's selection faded out) paints
  /// nothing at all, rather than an invisible rect over the page's rules.
  static Decoration? _visible(Decoration? d) =>
      d is BoxDecoration &&
          (d.color == null || d.color!.a == 0) &&
          d.border == null &&
          d.boxShadow == null &&
          d.gradient == null &&
          d.image == null
      ? null
      : d;

  @override
  Widget build(BuildContext context) {
    final face = widget.face;
    return Container(
      width: face.width,
      height: face.height,
      constraints: face.constraints,
      padding: face.padding,
      alignment: face.alignment,
      // A clipping face keeps its decoration: the clip is its outline.
      decoration: face.clipBehavior == Clip.none
          ? _visible(_decoration?.evaluate(animation))
          : _decoration?.evaluate(animation),
      foregroundDecoration: _visible(_foreground?.evaluate(animation)),
      clipBehavior: face.clipBehavior,
      child: face.builder(context, _ink?.evaluate(animation) ?? face.ink),
    );
  }
}
