/// A score out of a few stars.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
/// clears it to zero when [allowClear] holds); under a mouse, and while a
/// finger is down, the stars the tap would fill show in the quiet ink first
/// — the one place Minimal answers a hovering pointer, because it says what
/// a click will do. It is
/// one keyboard stop: the arrow keys step the score, Home and End go to the
/// ends, and a screen reader hears it as a slider ("3 of 5").
///
/// ```dart
/// MinimalRating(value: stars.toDouble(), onChanged: (v) => setState(() => stars = v), label: 'Your rating')
/// ```
class MinimalRating extends StatefulWidget {
  /// A rating out of [max] stars.
  const MinimalRating({
    super.key,
    required this.value,
    this.onChanged,
    this.max = 5,
    this.size = 20,
    this.label,
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
  final String? label;

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
      ..add(StringProperty('label', label, defaultValue: null))
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
  int? _preview;
  bool _focused = false;

  void _set(int v) {
    final change = widget.onChanged;
    if (change == null) return;
    final next = v.clamp(0, widget.max);
    if (next == widget.value.round()) return;
    HapticFeedback.selectionClick();
    change(next);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final now = widget.value.round();
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowLeft
                : LogicalKeyboardKey.arrowRight)) {
      _set(now + 1);
    } else if (key == LogicalKeyboardKey.arrowDown ||
        key ==
            (rtl
                ? LogicalKeyboardKey.arrowRight
                : LogicalKeyboardKey.arrowLeft)) {
      _set(now - 1);
    } else if (key == LogicalKeyboardKey.home) {
      _set(widget.allowClear ? 0 : 1);
    } else if (key == LogicalKeyboardKey.end) {
      _set(widget.max);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final live = widget.onChanged != null;
    final value = widget.value.clamp(0.0, widget.max.toDouble());
    final preview = _preview;
    final cell = widget.size + MinimalSpacing.s4;
    final stars = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < widget.max; i++)
          _Star(
            size: widget.size,
            extent: cell,
            fill: preview != null
                ? (i < preview ? 1 : 0)
                : (value - i).clamp(0.0, 1.0),
            ink: preview != null ? t.textTertiary : t.foreground,
            edge: t.input,
            stroke: t.rim,
          ),
      ],
    );
    final l = MinimalLocalizations.of(context);
    final words = l.ratingOf(_format(value), widget.max);
    if (!live) {
      // A mark reads as itself.
      return Semantics(
        container: true,
        label: widget.label,
        value: words,
        child: stars,
      );
    }
    final now = value.round();
    return Semantics(
      container: true,
      slider: true,
      label: widget.label,
      value: words,
      increasedValue: l.ratingOf(
        '${math.min(now + 1, widget.max)}',
        widget.max,
      ),
      decreasedValue: l.ratingOf('${math.max(now - 1, 0)}', widget.max),
      onIncrease: () => _set(now + 1),
      onDecrease: () => _set(now - 1),
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onKeyEvent: _onKey,
        onFocusChange: (v) => setState(() => _focused = v),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onExit: (_) => setState(() => _preview = null),
          // At a finger the stars stand in a band as tall as the floor, a
          // tap in it landing on the star under it.
          // The row is one target: a tap anywhere in it, or in the band
          // round it, picks the star under it, so a finger meets no gap
          // between two stars.
          child: MinimalTapBand(
            child: MouseRegion(
              onHover: (e) =>
                  setState(() => _preview = _starAt(e.localPosition, cell)),
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTapDown: (d) =>
                    setState(() => _preview = _starAt(d.localPosition, cell)),
                onTapUp: (d) {
                  final star = _starAt(d.localPosition, cell);
                  setState(() => _preview = null);
                  _set(widget.allowClear && star == now ? 0 : star);
                },
                onTapCancel: () => setState(() => _preview = null),
                child: DecoratedBox(
                  position: DecorationPosition.foreground,
                  decoration: minimalRingFrame(
                    t.shapes.small,
                    // Keyboard focus only: a tap focuses it without a ring.
                    ring:
                        _focused &&
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
            ),
          ),
        ),
      ),
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
