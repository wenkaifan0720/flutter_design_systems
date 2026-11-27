/// A score out of a few stars.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind, kTouchSlop;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../internal/kit_paint.dart';
import '../internal/tap_band.dart';
import '../localizations.dart';
import '../theme.dart';

/// A score out of [max] stars — a review, a difficulty, how a session went:
/// stars drawn in the ink when filled and on the control edge when not. A
/// read-only rating (no [onChanged]) is a mark that can show halves: a
/// score shown, not a control switched off, so it does not dim.
///
/// As a control, a tap on a star sets the score (a tap on the current one
/// clears it to zero when [allowClear] holds), and a drag sweeps across
/// the stars; under a mouse, and while a finger is down, the stars the tap
/// would fill show in the quiet ink first — the one place Minimal answers a
/// hovering pointer, because it says what a click will do — and a click
/// answers at once: the score it set shows in the ink until the pointer
/// moves again. It is one
/// keyboard stop: the arrow keys step the score, a digit sets that many,
/// Home (or 0) and End go to the ends, and a screen reader hears it as a
/// slider ("3 of 5"). With [allowClear] off it never goes below one star.
/// The behaviour is ui_core's ([RawRating]); Minimal paints it, and adds
/// the clearing tap and the preview under a finger.
///
/// ```dart
/// MinimalRating(value: stars.toDouble(), onChanged: (v) => setState(() => stars = v), semanticLabel: 'Your rating')
/// ```
class MinimalRating extends StatefulWidget {
  /// A rating out of [max] stars.
  const MinimalRating({
    super.key,
    required this.value,
    this.onChanged,
    this.max = 5,
    this.size = 20,
    this.semanticLabel,
    this.allowClear = true,
    this.focusNode,
    this.autofocus = false,
  }) : assert(max > 0, 'a rating has at least one star'),
       assert(value >= 0 && value <= max, 'value lies within 0..max'),
       assert(size > 0, 'a star has a size');

  /// The score, 0..[max]; a read-only rating may show a half.
  final double value;

  /// Null makes this a mark.
  final ValueChanged<int>? onChanged;

  /// How many stars.
  final int max;

  /// A star's size.
  final double size;

  /// What is being rated, for a screen reader.
  final String? semanticLabel;

  /// A tap on the current score clears it.
  final bool allowClear;

  /// {@macro minimal.focusNode}
  final FocusNode? focusNode;

  /// {@macro minimal.autofocus}
  final bool autofocus;

  @override
  State<MinimalRating> createState() => _MinimalRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('value', value))
      ..add(ObjectFlagProperty<ValueChanged<int>>.has('onChanged', onChanged))
      ..add(IntProperty('max', max, defaultValue: 5))
      ..add(DoubleProperty('size', size, defaultValue: 20))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'allowClear',
          value: allowClear,
          ifFalse: 'allowClear: false',
        ),
      )
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _MinimalRatingState extends State<MinimalRating> {
  FocusNode? _ownNode;

  FocusNode get _node =>
      widget.focusNode ?? (_ownNode ??= FocusNode(debugLabel: 'MinimalRating'));

  // The star a finger is down on (ui_core previews a hovering pointer only),
  // where it went down, and whether it has since moved into a drag.
  int? _touch;
  Offset? _down;
  bool _moved = false;

  // A click has just set the score under a pointer that has not moved
  // since: the stars show the score in the ink, not ui_core's hover
  // preview, so the click reads as done (as Minimal's own preview did,
  // which a tap ended).
  bool _clicked = false;

  @override
  void dispose() {
    _ownNode?.dispose();
    super.dispose();
  }

  // A score set by a tap, a key, a drag or a screen reader: whole stars,
  // and none below one without [MinimalRating.allowClear].
  void _changed(double value) {
    final change = widget.onChanged;
    if (change == null) return;
    final next = value.round().clamp(widget.allowClear ? 0 : 1, widget.max);
    if (next == widget.value.round()) return;
    // ui_core plays a drag's steps itself; a tap and a key play here.
    if (!_moved) RawHaptics.of(context).selectionChanged?.call();
    change(next);
  }

  void _pointerDown(PointerDownEvent e, double cell) {
    _down = e.localPosition;
    _moved = false;
    if (e.kind != PointerDeviceKind.mouse) {
      setState(() => _touch = _starAt(e.localPosition, cell));
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final down = _down;
    if (down == null || (e.localPosition - down).distance <= kTouchSlop) {
      return;
    }
    _moved = true;
    if (_touch != null) setState(() => _touch = null);
  }

  void _pointerUp(PointerUpEvent e, double cell) {
    final tapped = _down != null && !_moved;
    final star = _starAt(e.localPosition, cell);
    setState(() {
      _touch = null;
      if (tapped && e.kind == PointerDeviceKind.mouse) _clicked = true;
    });
    _down = null;
    // ui_core's tap leaves the score already set alone (it runs after this,
    // on the score before the page's rebuild); here a tap on it clears it.
    if (tapped && widget.allowClear && star == widget.value.round()) {
      _changed(0);
    }
    _moved = false;
  }

  void _pointerCancel() {
    setState(() => _touch = null);
    _down = null;
    _moved = false;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final live = widget.onChanged != null;
    final value = widget.value.clamp(0.0, widget.max.toDouble());
    final cell = widget.size + MinimalSpacing.s4;
    final l = MinimalLocalizations.of(context);
    final node = _node;
    return RawRating(
      value: value,
      onChanged: live ? _changed : null,
      // No onChanged: a mark, read as a value rather than as disabled.
      readOnly: !live,
      itemCount: widget.max,
      semanticLabel: widget.semanticLabel,
      semanticFormatterCallback: (v) => l.ratingOf(_format(v), widget.max),
      focusNode: node,
      autofocus: widget.autofocus,
      itemBuilder: (context, item) {
        final touch = _touch;
        final settled = _clicked && item.isPreview;
        return _Star(
          size: widget.size,
          extent: cell,
          fill: touch != null
              ? (item.index < touch ? 1 : 0)
              : settled
              ? (item.index < value.round() ? 1 : 0)
              : item.fill,
          ink: touch != null || (item.isPreview && !settled)
              ? t.textTertiary
              : t.foreground,
          edge: t.input,
          stroke: t.rim,
        );
      },
      layoutBuilder: (context, items) {
        final stars = Row(mainAxisSize: MainAxisSize.min, children: items);
        if (!live) return stars;
        // At a finger the stars stand in a band as tall as the floor, a tap
        // in it landing on the star under it: the row is one target, so a
        // finger meets no gap between two stars.
        return MinimalTapBand(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _pointerDown(e, cell),
            onPointerMove: _pointerMove,
            onPointerUp: (e) => _pointerUp(e, cell),
            onPointerCancel: (_) => _pointerCancel(),
            onPointerHover: (_) {
              if (_clicked) setState(() => _clicked = false);
            },
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: minimalRingFrame(
                t.shapes.small,
                // Keyboard focus only: a tap focuses it without a ring.
                ring:
                    node.hasFocus &&
                        FocusManager.instance.highlightMode ==
                            FocusHighlightMode.traditional
                    ? t.ring
                    : null,
                ground: minimalGround(context),
                width: t.focusWidth,
              ),
              child: stars,
            ),
          ),
        );
      },
    );
  }

  /// The star (1..max) under [at] in the row of cells [cell] wide, counted
  /// from the start edge.
  int _starAt(Offset at, double cell) {
    final i = (at.dx / cell).floor().clamp(0, widget.max - 1);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return (rtl ? widget.max - 1 - i : i) + 1;
  }

  static String _format(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _Star extends StatelessWidget {
  const _Star({
    required this.size,
    required this.extent,
    required this.fill,
    required this.ink,
    required this.edge,
    required this.stroke,
  });

  final double size;
  final double extent;

  /// How much of the star is filled, 0..1 from its start edge.
  final double fill;
  final Color ink;
  final Color edge;
  final double stroke;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: extent,
      height: extent,
      child: Center(
        child: CustomPaint(
          size: Size.square(size),
          painter: _StarPainter(
            fill: fill,
            ink: ink,
            edge: edge,
            stroke: stroke,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({
    required this.fill,
    required this.ink,
    required this.edge,
    required this.stroke,
    required this.rtl,
  });

  final double fill;
  final Color ink;
  final Color edge;
  final double stroke;
  final bool rtl;

  static Path _star(Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * 0.48;
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? outer : inner;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = c + Offset(math.cos(a) * r, math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    return path..close();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = _star(size);
    Paint line(Color colour) => Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeJoin = StrokeJoin.round
      ..color = colour;
    if (fill >= 1) {
      canvas
        ..drawPath(path, Paint()..color = ink)
        ..drawPath(path, line(ink));
      return;
    }
    if (fill <= 0) {
      canvas.drawPath(path, line(edge));
      return;
    }
    // A part star: the filled share is a whole star's, its fill and its
    // ink outline, and the rest wears the edge; the cut is the only place
    // they meet. The clips reach past the box by the stroke, so the
    // outline's points (the top one, the outer ones) are not shaved.
    final w = size.width * fill;
    final s = stroke;
    final cut = rtl ? size.width - w : w;
    final inked = rtl
        ? Rect.fromLTRB(cut, -s, size.width + s, size.height + s)
        : Rect.fromLTRB(-s, -s, cut, size.height + s);
    final rest = rtl
        ? Rect.fromLTRB(-s, -s, cut, size.height + s)
        : Rect.fromLTRB(cut, -s, size.width + s, size.height + s);
    canvas
      ..save()
      ..clipRect(inked)
      ..drawPath(path, Paint()..color = ink)
      ..drawPath(path, line(ink))
      ..restore()
      ..save()
      ..clipRect(rest)
      ..drawPath(path, line(edge))
      ..restore();
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.fill != fill ||
      old.ink != ink ||
      old.edge != edge ||
      old.stroke != stroke ||
      old.rtl != rtl;
}
