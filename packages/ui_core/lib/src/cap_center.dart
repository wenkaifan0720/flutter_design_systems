/// A one-line label or text entry drawn with its capitals on the middle of
/// its own box.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'internal/label_line.dart';

/// Draws a one-line label or text entry so that the middle of its capitals
/// is the middle of its own box, as [Baseline] puts a baseline where it is
/// told.
///
/// A text's box is its line: the font's ascent above the baseline and its
/// descent below, and the engine puts the baseline on a whole pixel. So a
/// label centred by its box sits a pixel or two off the middle, by a
/// different amount in each typeface and size, and a face that centres its
/// label looks as if it did not. This widget keeps its [child]'s size and
/// moves only what it paints: up or down, so that the capitals' middle, where
/// the engine will draw it (its whole-pixel baseline paid in advance), is the
/// box's middle. Whatever centres this box then centres the capitals: a
/// [Row]'s cross axis, [Center], [Align], a button's face, a tab, a title
/// bar, a list row. Within half a device pixel, at any pixel ratio, text
/// scale, fractional offset or scale, where the engine draws the font's
/// outlines as they are (Core Text: iOS and macOS). An engine that hints
/// them (FreeType: Linux, and the web's CanvasKit) also snaps the capitals'
/// top to the pixel grid, up to a device pixel from the font's cap height,
/// which moves their middle up to half of that further.
///
/// Wrap the label alone, never an icon: in a centred [Row], an icon's box and
/// this box share a middle, and the icon is drawn on it. A look wraps the
/// label of each face once, in its own widgets; page code never writes it.
///
/// It reads the text entry under [child] when it holds one (a `TextField`'s
/// editable line), else the first paragraph that is not an icon's glyph, with
/// its font size through its own text scaler. A label that wraps to more
/// than one line, or a child without a paragraph, is drawn where it is laid
/// out: the middle of two lines' capitals is no one line's.
///
/// Around a text entry, wrap its one-line `TextField` (its decoration
/// collapsed, as `DesignTextEntryCheck` asks), inside the look's own box: the
/// line is placed by the field's style, whether text is typed or its hint
/// shows, and the caret, the selection, the hint and taps move with it. A
/// row that holds a field and a button then holds their capitals on one
/// line, whatever their sizes.
///
/// The move is at most a few pixels, and what it paints may reach that far
/// past the box; hit testing and semantics follow what is painted. So a
/// clip drawn exactly round a text entry's 48 px reach trims its node by the
/// move (a tap target test reads 47.7): a look leaves the clip room for
/// the move (or clips nothing round the entry).
///
/// ```dart
/// DesignCapCenter(capHeightFactor: 0.711, child: Text('Save'))
/// ```
class DesignCapCenter extends SingleChildRenderObjectWidget {
  /// Draws [child], a one-line label or text entry, with its capitals on its
  /// box's middle.
  const DesignCapCenter({
    super.key,
    required this.capHeightFactor,
    required Widget super.child,
  });

  /// The height of the label's capitals as a fraction of its font size: the
  /// typeface's cap height (its OS/2 table's `sCapHeight`) over its units per
  /// em (its head table's `unitsPerEm`), read once from the font file.
  ///
  /// The looks' typefaces: Atkinson Hyperlegible Next and Mono 0.668,
  /// Bangers 0.721, Bricolage Grotesque 0.660, DM Sans 0.700, Federo 0.726,
  /// Geist and Geist Mono 0.710, Inter 0.728, Jersey 15 0.556, Jost 0.700,
  /// Manrope 0.720, Marcellus 0.700, Roboto and Roboto Flex 0.711, Shantell
  /// Sans 0.700.
  final double capHeightFactor;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderCapCenter(capHeightFactor);

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderCapCenter).capHeightFactor = capHeightFactor;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DoubleProperty('capHeightFactor', capHeightFactor));
  }
}

// Paints its child moved by [_shift], worked out where it is used (paint,
// hit testing, transforms), after any layout of the label below it: a label
// whose text changes inside a box of fixed size lays out again without this
// one.
class _RenderCapCenter extends RenderProxyBox implements CapCentred {
  _RenderCapCenter(this._capHeightFactor);

  double _capHeightFactor;
  @override
  double get capHeightFactor => _capHeightFactor;
  set capHeightFactor(double value) {
    if (value == _capHeightFactor) return;
    _capHeightFactor = value;
    markNeedsPaint();
    markNeedsSemanticsUpdate();
  }

  // How far down to draw the child: the box's middle less the middle of the
  // label's capitals as the engine will draw them, in this box's units.
  double get _shift {
    final child = this.child;
    if (child == null || !child.hasSize || !hasSize) return 0;
    final p = labelLine(child);
    if (p == null || !isOneLine(p)) return 0;
    final caps = drawnCaps(p, capHeightFactor);
    if (caps == null) return 0;
    // The child is at this box's top left.
    final toChild = p.getTransformTo(child);
    final top = MatrixUtils.transformPoint(toChild, Offset(0, caps.top)).dy;
    final base = MatrixUtils.transformPoint(
      toChild,
      Offset(0, caps.baseline),
    ).dy;
    final shift = size.height / 2 - (top + base) / 2;
    return shift.isFinite ? shift : 0;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final child = this.child;
    if (child != null) context.paintChild(child, offset.translate(0, _shift));
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final child = this.child;
    if (child == null) return false;
    return result.addWithPaintOffset(
      offset: Offset(0, _shift),
      position: position,
      hitTest: (result, transformed) =>
          child.hitTest(result, position: transformed),
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    transform.translateByDouble(0, _shift, 0, 1);
  }
}
