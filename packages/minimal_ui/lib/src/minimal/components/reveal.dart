import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../theme.dart';

/// The arrival and departure of a row or a block inside a Column or a list:
/// its extent grows from nothing while it fades in, and on the way out it
/// fades while its neighbours close over it — [MinimalMotion.base] (120 ms)
/// on [MinimalMotion.out], no bounce, no scale.
///
/// A list that swaps its children in one frame makes the reader re-find
/// their place; the extent has to MOVE. The leaving child is kept for the
/// length of the collapse (silent and untappable), then replaced by a
/// zero-extent box — not laid out, not hit-tested, costing nothing while it
/// is away. That is the difference between this and an Opacity: an
/// invisible row that still eats taps is a bug the page cannot see. The
/// child keeps its element (and its state) through a reversal mid-move,
/// and it is clipped only while it moves, so a settled child's focus ring
/// still paints outside its edge. Under `MediaQuery.disableAnimations`, or
/// with [MinimalMotion.animate] off, it switches at once. Inside a
/// [MinimalListSection] it is a row like any other: the group draws no rule for
/// it while it is folded away.
///
/// ```dart
/// MinimalReveal(visible: showNote, child: MinimalListTile(title: 'Note'))
/// ```
class MinimalReveal extends StatefulWidget {
  /// Shows [child] while [visible], growing in and folding away.
  const MinimalReveal({
    super.key,
    required this.visible,
    required this.child,
    this.axis = Axis.vertical,
  });

  /// Whether the child is shown.
  final bool visible;

  /// What it shows.
  final Widget child;

  /// Which extent collapses: vertical anchors the child to the top (a row in
  /// a column), horizontal to the leading edge (a tag in a row).
  final Axis axis;

  @override
  State<MinimalReveal> createState() => _MinimalRevealState();
}

class _MinimalRevealState extends State<MinimalReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: MinimalMotion.base,
    value: widget.visible ? 1 : 0,
  )..addStatusListener(_onStatus);

  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: MinimalMotion.out,
    reverseCurve: MinimalMotion.out.flipped,
  );

  @override
  void didUpdateWidget(MinimalReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (context.minimalStill) {
      _controller.value = widget.visible ? 1 : 0;
    } else if (widget.visible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  void _onStatus(AnimationStatus status) {
    // The collapse finished (rebuild so the child is dropped for real), or
    // the arrival did (rebuild so the clip comes off).
    if (status.isDismissed || status.isCompleted) setState(() {});
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }
    // Leaving, the child is seen for the length of the collapse but is no
    // longer part of the page: it takes no taps, holds no keyboard focus
    // and says nothing. The
    // wrappers stay in the tree either way, so flipping back mid-move
    // keeps the child's element and state.
    final content = ExcludeFocus(
      excluding: !widget.visible,
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: ExcludeSemantics(
          excluding: !widget.visible,
          child: widget.child,
        ),
      ),
    );
    final moving = !widget.visible || !_controller.isCompleted;
    final vertical = widget.axis == Axis.vertical;
    return ClipRect(
      // Settled, nothing is clipped: a focus ring drawn outside the child's
      // edge must survive. (A SizeTransition would clip for good.)
      clipBehavior: moving ? Clip.hardEdge : Clip.none,
      child: AnimatedBuilder(
        animation: _curve,
        builder: (context, child) => vertical
            // The child keeps the width it is given, as it would standing
            // in the column itself: a note runs from the start edge and a
            // rule across the whole row, never centred in the reveal.
            ? _Unfold(factor: _curve.value.clamp(0.0, 1.0), child: child)
            : Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: _curve.value.clamp(0.0, 1.0),
                child: child,
              ),
        child: FadeTransition(opacity: _curve, child: content),
      ),
    );
  }
}

/// [child] at the width its parent gives (a stretching column's full
/// width), anchored to the top start, as tall as [factor] of its own
/// height.
class _Unfold extends SingleChildRenderObjectWidget {
  const _Unfold({required this.factor, super.child});

  final double factor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderUnfold(factor, Directionality.of(context));

  @override
  void updateRenderObject(BuildContext context, _RenderUnfold renderObject) {
    renderObject
      ..factor = factor
      ..textDirection = Directionality.of(context);
  }
}

class _RenderUnfold extends RenderShiftedBox {
  _RenderUnfold(this._factor, this._textDirection) : super(null);

  double _factor;
  set factor(double value) {
    if (value == _factor) return;
    _factor = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// The parent's width constraints as given; any height up to its own.
  BoxConstraints _inner(BoxConstraints c) => BoxConstraints(
    minWidth: c.minWidth,
    maxWidth: c.maxWidth,
    maxHeight: c.maxHeight,
  );

  Size _sizeFor(BoxConstraints c, Size child) =>
      c.constrain(Size(child.width, child.height * _factor));

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final kid = child;
    if (kid == null) return constraints.smallest;
    return _sizeFor(constraints, kid.getDryLayout(_inner(constraints)));
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      (child?.getMinIntrinsicHeight(width) ?? 0) * _factor;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      (child?.getMaxIntrinsicHeight(width) ?? 0) * _factor;

  @override
  void performLayout() {
    final kid = child;
    if (kid == null) {
      size = constraints.smallest;
      return;
    }
    kid.layout(_inner(constraints), parentUsesSize: true);
    size = _sizeFor(constraints, kid.size);
    (kid.parentData! as BoxParentData).offset = Offset(
      _textDirection == TextDirection.rtl ? size.width - kid.size.width : 0.0,
      0,
    );
  }

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) => child?.getDryBaseline(_inner(constraints), baseline);
}
