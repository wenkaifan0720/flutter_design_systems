// A face's one-line label, drawn with its capitals on the middle of its box (ui_core's DesignCapCenter): what centres
// the box then centres the capitals, not the line, whose ascent and descent differ by face. The look's two label faces:
// Jersey 15's capitals are 750 of its 1350 units, Atkinson Hyperlegible Next's 0.668 of its size.
import 'package:flutter/rendering.dart' show BoxParentData, RenderShiftedBox;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

/// The capitals' height over the size, for [family] (a package-qualified name included).
double retroDesktopCapHeight(String? family) {
  final f = family ?? '';
  if (f.endsWith('Jersey15')) return 750 / 1350;
  return .668;
}

/// [child], one line of words on a face, drawn with its capitals on its box's middle. [style] is the label's own style
/// when it sets a family; otherwise the face's text style gives it.
class RetroDesktopCaps extends StatelessWidget {
  /// Wraps [child].
  const RetroDesktopCaps(this.child, {super.key, this.style});

  /// The label.
  final Widget child;

  /// The label's own style, if it names a family.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => DesignCapCenter(
    capHeightFactor: retroDesktopCapHeight(
      style?.fontFamily ?? DefaultTextStyle.of(context).style.fontFamily,
    ),
    child: child,
  );
}

/// The first line of words in [style] (merged over the place's default) at the reader's text size: its height, and
/// how far down it the middle of its capitals stands as the engine draws them, on the baseline it rounds to a whole
/// pixel.
({double line, double middle}) retroDesktopCapsLine(
  BuildContext context, [
  TextStyle? style,
]) {
  final scaler = MediaQuery.textScalerOf(context);
  final plain = DefaultTextStyle.of(context);
  final words = plain.style.merge(style);
  final probe = TextPainter(
    text: TextSpan(text: 'H', style: words),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    textHeightBehavior: plain.textHeightBehavior,
  )..layout();
  final baseline = probe.computeDistanceToActualBaseline(
    TextBaseline.alphabetic,
  );
  final line = probe.height;
  probe.dispose();
  final caps =
      retroDesktopCapHeight(words.fontFamily) *
      scaler.scale(words.fontSize ?? 14);
  return (line: line, middle: (baseline + .5).floorToDouble() - caps / 2);
}

/// A mark before a block of words, its middle on the capitals of their first line at the reader's text size, however
/// tall the words are drawn: a fixed top offset put it above the line once the text grew. [style] is the words' style
/// (the place's default when null). It stands one line tall; the mark may reach over the lines above and below.
class RetroDesktopOnCaps extends StatelessWidget {
  /// Puts [child] on the first line of words in [style].
  const RetroDesktopOnCaps({super.key, this.style, required this.child});

  /// The words' style; null takes the place's default.
  final TextStyle? style;

  /// The mark.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final at = retroDesktopCapsLine(context, style);
    return _OnCaps(line: at.line, middle: at.middle, child: child);
  }
}

// [child] beside a line of words [line] tall, its middle [middle] down that line: the line's height and the child's
// width are its own size; the child may stand over the line above and below.
class _OnCaps extends SingleChildRenderObjectWidget {
  const _OnCaps({required this.line, required this.middle, super.child});
  final double line;
  final double middle;

  @override
  _RenderOnCaps createRenderObject(BuildContext context) =>
      _RenderOnCaps(line, middle);

  @override
  void updateRenderObject(BuildContext context, _RenderOnCaps renderObject) {
    renderObject
      ..line = line
      ..middle = middle;
  }
}

class _RenderOnCaps extends RenderShiftedBox {
  _RenderOnCaps(this._line, this._middle) : super(null);

  double _line;
  set line(double value) {
    if (value == _line) return;
    _line = value;
    markNeedsLayout();
  }

  double _middle;
  set middle(double value) {
    if (value == _middle) return;
    _middle = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) =>
      BoxConstraints(maxWidth: c.maxWidth);

  @override
  double computeMinIntrinsicWidth(double height) =>
      child?.getMinIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMaxIntrinsicWidth(double height) =>
      child?.getMaxIntrinsicWidth(double.infinity) ?? 0;

  @override
  double computeMinIntrinsicHeight(double width) => _line;

  @override
  double computeMaxIntrinsicHeight(double width) => _line;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) {
    final c = child;
    final width = c == null ? 0.0 : c.getDryLayout(_inner(constraints)).width;
    return constraints.constrain(Size(width, _line));
  }

  @override
  void performLayout() {
    final c = child;
    if (c == null) {
      size = constraints.constrain(Size(0, _line));
      return;
    }
    c.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(Size(c.size.width, _line));
    (c.parentData! as BoxParentData).offset = Offset(
      0,
      _middle - c.size.height / 2,
    );
  }
}
