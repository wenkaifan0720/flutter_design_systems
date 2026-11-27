// A row's words and its figure, side by side or the figure under the words: shared by the list rows and the toast.
import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A row's words and its figure: the figure beside them, at most [share] of the row, while the words keep [need] (the
/// title's longest word), the figure stands on one line in its share and, unless it is a mark, standing beside costs
/// the words no line; else under them at the start. A figure is never broken: at 390 and twice the text a price beside
/// its words would break as £32.0 over 0, and a status as On · over 70%.
class BesideOrUnder extends MultiChildRenderObjectWidget {
  /// Lays out [children]: the words, then the figure.
  const BesideOrUnder({
    super.key,
    required this.need,
    required this.centre,
    this.mark = 48,
    this.topFrom = double.infinity,
    this.firstLine = 0,
    required super.children,
  });

  /// The widest word the words must keep beside the figure.
  final double need;

  /// Whether, beside the words, the figure stands on their middle (else on their top).
  final bool centre;

  /// The widest a mark stands (an onward glyph, a dot): a mark never moves under the words. 0 for a figure in words
  /// however short (a toast's act).
  final double mark;

  /// Words at least this tall stand a [centre]d figure on the middle of their first line ([firstLine] tall), not on
  /// their middle: beside three lines it stands where a list tile's key and mark stand.
  final double topFrom;

  /// The height of the words' first line, for [topFrom].
  final double firstLine;

  /// The most of the width the figure takes beside the words.
  static const share = .4;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderBesideOrUnder(
    need,
    centre,
    Directionality.of(context),
    mark,
    topFrom,
    firstLine,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    RenderBesideOrUnder renderObject,
  ) => renderObject
    ..need = need
    ..centre = centre
    ..direction = Directionality.of(context)
    ..mark = mark
    ..topFrom = topFrom
    ..firstLine = firstLine;
}

class _BesideData extends ContainerBoxParentData<RenderBox> {}

typedef _Plan = ({bool beside, Size words, Size side});

/// The render box of [BesideOrUnder].
class RenderBesideOrUnder extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BesideData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BesideData> {
  /// Lays out [BesideOrUnder]'s two children.
  RenderBesideOrUnder(
    this._need,
    this._centre,
    this._direction,
    this._mark, [
    this._topFrom = double.infinity,
    this._firstLine = 0,
  ]);

  static const _gap = 12.0, _under = 6.0;

  double _need;
  set need(double value) {
    if (value == _need) return;
    _need = value;
    markNeedsLayout();
  }

  bool _centre;
  set centre(bool value) {
    if (value == _centre) return;
    _centre = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  double _topFrom;
  set topFrom(double value) {
    if (value == _topFrom) return;
    _topFrom = value;
    markNeedsLayout();
  }

  double _firstLine;
  set firstLine(double value) {
    if (value == _firstLine) return;
    _firstLine = value;
    markNeedsLayout();
  }

  // Beside words this tall, a centred figure stands on their first line; the words stand lower by what it needs above.
  bool _atTop(_Plan p) => p.beside && _centre && p.words.height >= _topFrom;
  double _lift(_Plan p) => math.max(0, (p.side.height - _firstLine) / 2);

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BesideData) child.parentData = _BesideData();
  }

  _Plan _plan(
    BoxConstraints c,
    Size Function(RenderBox child, BoxConstraints constraints) measure,
  ) {
    final words = firstChild!, side = childAfter(words)!;
    if (!c.hasBoundedWidth) {
      return (
        beside: true,
        words: measure(words, const BoxConstraints()),
        side: measure(side, const BoxConstraints()),
      );
    }
    // Measured by laying out, not by intrinsics: a figure may hold a LayoutBuilder (a toast's link), which has none.
    // Each child's last measure is the one it keeps. A figure wider than its share stands under the words without
    // being laid out in the share: one that draws from its width (a tag's shape) would flip between two shapes on
    // every layout, and an animated one would never come to rest.
    final w = c.maxWidth, most = w * BesideOrUnder.share;
    final alone = measure(side, BoxConstraints(maxWidth: w));
    if (alone.width > most) {
      return (
        beside: false,
        words: measure(words, BoxConstraints.tightFor(width: w)),
        side: alone,
      );
    }
    final s = measure(side, BoxConstraints(maxWidth: most));
    final room = w - s.width - _gap;
    // On one line in its share, the words keeping [need] beside it.
    var beside =
        alone.width <= most && s.height <= alone.height + .5 && room >= _need;
    if (beside && alone.width > _mark) {
      // A price or a status beside the words must not cost them a line.
      final lines = measure(words, BoxConstraints.tightFor(width: w)).height;
      final next = measure(words, BoxConstraints.tightFor(width: room));
      if (next.height <= lines + .5) {
        return (beside: true, words: next, side: s);
      }
      beside = false;
    }
    if (beside) {
      return (
        beside: true,
        words: measure(words, BoxConstraints.tightFor(width: room)),
        side: s,
      );
    }
    return (
      beside: false,
      words: measure(words, BoxConstraints.tightFor(width: w)),
      side: measure(side, BoxConstraints(maxWidth: w)),
    );
  }

  Size _size(_Plan p, BoxConstraints c) => c.constrain(
    Size(
      c.hasBoundedWidth ? c.maxWidth : p.words.width + _gap + p.side.width,
      _atTop(p)
          ? _lift(p) +
                math.max(p.words.height, (_firstLine + p.side.height) / 2)
          : p.beside
          ? math.max(p.words.height, p.side.height)
          : p.words.height + _under + p.side.height,
    ),
  );

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _size(_plan(constraints, (b, k) => b.getDryLayout(k)), constraints);

  @override
  void performLayout() {
    final p = _plan(constraints, (b, k) {
      b.layout(k, parentUsesSize: true);
      return b.size;
    });
    size = _size(p, constraints);
    final words = firstChild!, side = childAfter(words)!;
    final rtl = _direction == TextDirection.rtl;
    final wordsAt = words.parentData! as _BesideData;
    final sideAt = side.parentData! as _BesideData;
    double startOf(double width) => rtl ? size.width - width : 0;
    if (_atTop(p)) {
      final lift = _lift(p);
      wordsAt.offset = Offset(startOf(p.words.width), lift);
      sideAt.offset = Offset(
        rtl ? 0 : size.width - p.side.width,
        lift + (_firstLine - p.side.height) / 2,
      );
    } else if (p.beside) {
      double y(double height) => _centre ? (size.height - height) / 2 : 0;
      wordsAt.offset = Offset(startOf(p.words.width), y(p.words.height));
      sideAt.offset = Offset(
        rtl ? 0 : size.width - p.side.width,
        y(p.side.height),
      );
    } else {
      wordsAt.offset = Offset(startOf(p.words.width), 0);
      sideAt.offset = Offset(startOf(p.side.width), p.words.height + _under);
    }
  }

  double _mark;
  set mark(double value) {
    if (value == _mark) return;
    _mark = value;
    markNeedsLayout();
  }

  /// Whether the figure stands beside the words in [width]: on one line in its share, the words keeping [need] beside
  /// it and, for a price or a status, keeping their lines. Otherwise, at twice the text a bulb row would keep £8.00
  /// beside its words and break 'Warm white, £4.00 each' over three lines, while the lamp's £32.00 above it stands
  /// under its own.
  /// (The intrinsic sizes' reading; layout measures the same by laying out.)
  bool _beside(double width) {
    final words = firstChild!, side = childAfter(words)!;
    final natural = side.getMaxIntrinsicWidth(double.infinity);
    if (natural > width * BesideOrUnder.share) return false;
    final room = width - natural - _gap;
    if (room < _need) return false;
    if (natural <= _mark) return true;
    return words.getMinIntrinsicHeight(room) <=
        words.getMinIntrinsicHeight(width) + .5;
  }

  double _heightAt(double width) {
    final words = firstChild!, side = childAfter(words)!;
    final sideWidth = math.min(
      side.getMaxIntrinsicWidth(double.infinity),
      width * BesideOrUnder.share,
    );
    final room = width - sideWidth - _gap;
    if (_beside(width)) {
      final w = words.getMinIntrinsicHeight(room);
      final s = side.getMinIntrinsicHeight(sideWidth);
      if (_centre && w >= _topFrom) {
        return math.max(0, (s - _firstLine) / 2) +
            math.max(w, (_firstLine + s) / 2);
      }
      return math.max(w, s);
    }
    return words.getMinIntrinsicHeight(width) +
        _under +
        side.getMinIntrinsicHeight(width);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      firstChild!.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      firstChild!.getMaxIntrinsicWidth(height) +
      _gap +
      childAfter(firstChild!)!.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) => _heightAt(width);

  @override
  double computeMaxIntrinsicHeight(double width) => _heightAt(width);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
