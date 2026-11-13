/// Layout for controls that share a line, headless: a box of a minimum
/// height with its content centred, and the same for a text entry, with its
/// hint on the typed text's baseline. Neither paints anything.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// [child] with even leading, whatever else the text height behaviour above
// it says: a line's extra height shared equally above and below its glyphs.
Widget _evenLeading(BuildContext context, Widget child) {
  final above = DefaultTextHeightBehavior.maybeOf(context);
  return DefaultTextHeightBehavior(
    textHeightBehavior: TextHeightBehavior(
      applyHeightToFirstAscent: above?.applyHeightToFirstAscent ?? true,
      applyHeightToLastDescent: above?.applyHeightToLastDescent ?? true,
      leadingDistribution: TextLeadingDistribution.even,
    ),
    child: child,
  );
}

/// A control's box: at least [minHeight] tall, as wide as its [child] (or as
/// the width it is told to be), with [child] placed by [alignment] and its
/// text given even leading ([TextLeadingDistribution.even]).
///
/// Give every control that can share a line this box and one height, and
/// they line up: the height no longer comes from padding added to a line
/// height. It is a minimum, so larger text grows it. The border, fill, side
/// padding and press are the design system's own.
///
/// ```dart
/// const DesignControlBox(minHeight: 40, child: Text('Save'))
/// ```
class DesignControlBox extends StatelessWidget {
  /// A box at least [minHeight] tall around [child].
  const DesignControlBox({
    super.key,
    required this.minHeight,
    this.alignment = Alignment.center,
    required this.child,
  }) : assert(minHeight >= 0);

  /// The least height of the box, in logical pixels.
  final double minHeight;

  /// Where [child] sits in the box. A field or a list row usually wants
  /// [AlignmentDirectional.centerStart].
  final AlignmentGeometry alignment;

  /// What the box holds.
  final Widget child;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(minHeight: minHeight),
    // Both factors, or the box takes all the room its parent offers.
    child: Align(
      alignment: alignment,
      widthFactor: 1,
      heightFactor: 1,
      child: _evenLeading(context, child),
    ),
  );
}

/// A text entry's box: at least [minHeight] tall, holding [child], an
/// editable as wide as the box, with one line centred in it and [hint] on
/// the typed text's baseline while [controller] is empty.
///
/// [child] is a `TextField` whose decoration is null, or collapsed with
/// every field that sizes it set, in which case it draws its own hint and
/// [hint] stays null. Either way a line stands where the box puts it,
/// whatever the platform's density, the text size or the app's
/// `InputDecorationTheme`. Several lines ([maxLines] other than 1) start
/// where one line would stand, and the box grows with them. A press anywhere
/// in the box reaches the editable.
///
/// The box centres the line by its line box. What the eye compares in a row
/// is the capitals: to put them on the box's middle, beside a button's
/// cap-centred label, wrap this box in a `DesignCapCenter` with the field's
/// typeface's factor. The typed text, [hint], the caret and taps then move
/// together.
///
/// The design system still owns the border, the fill, the focus ring, the
/// side padding, any icons, the counter, help and error, all around or
/// beside this box, and, when the decoration is null, what a screen reader
/// hears as the hint: [hint] is drawn only, so wrap the entry in
/// `Semantics(hint: ...)`.
///
/// ```dart
/// DesignTextEntryBox(minHeight: 40, controller: controller, hint: const Text('Search'), child: TextField(controller: controller, decoration: null))
/// ```
class DesignTextEntryBox extends StatelessWidget {
  /// A box at least [minHeight] tall around the editable [child].
  const DesignTextEntryBox({
    super.key,
    required this.minHeight,
    this.controller,
    this.hint,
    this.maxLines = 1,
    required this.child,
  }) : assert(minHeight >= 0),
       assert(
         hint == null || controller != null,
         'A hint shows while the controller is empty: pass the controller.',
       ),
       assert(maxLines == null || maxLines > 0);

  /// The least height of the box, in logical pixels.
  final double minHeight;

  /// The editable's controller, which says when [hint] shows. Required with
  /// a [hint]. Yours to dispose.
  final TextEditingController? controller;

  /// Shown while the text is empty, on the typed text's baseline, at most
  /// as wide as the editable. It adds nothing to the box's height, so the
  /// box does not move as typing starts. Give it one line.
  final Widget? hint;

  /// The editable's own `maxLines`: 1 centres the line, anything else (null
  /// for no limit) starts the first line where a single line would stand.
  final int? maxLines;

  /// The editable.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    Widget layout({required bool showHint}) => _evenLeading(
      context,
      _TextEntryLayout(
        minHeight: minHeight,
        oneLine: maxLines == 1,
        editable: child,
        hint: showHint ? ExcludeSemantics(child: hint!) : null,
      ),
    );
    if (hint == null) return layout(showHint: false);
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller!,
      builder: (context, value, _) => layout(showHint: value.text.isEmpty),
    );
  }
}

enum _Slot { editable, hint }

class _TextEntryLayout
    extends SlottedMultiChildRenderObjectWidget<_Slot, RenderBox> {
  const _TextEntryLayout({
    required this.minHeight,
    required this.oneLine,
    required this.editable,
    required this.hint,
  });

  final double minHeight;
  final bool oneLine;
  final Widget editable;
  final Widget? hint;

  @override
  Iterable<_Slot> get slots => _Slot.values;

  @override
  Widget? childForSlot(_Slot slot) => switch (slot) {
    _Slot.editable => editable,
    _Slot.hint => hint,
  };

  @override
  SlottedContainerRenderObjectMixin<_Slot, RenderBox> createRenderObject(
    BuildContext context,
  ) => _RenderTextEntry(minHeight, oneLine, Directionality.of(context));

  @override
  void updateRenderObject(
    BuildContext context,
    covariant _RenderTextEntry renderObject,
  ) {
    renderObject
      ..minHeight = minHeight
      ..oneLine = oneLine
      ..textDirection = Directionality.of(context);
  }
}

// What a layout comes to, for real or dry.
typedef _Measured = ({
  Size box,
  Size editable,
  BoxConstraints editableConstraints,
  double top,
});

class _RenderTextEntry extends RenderBox
    with SlottedContainerRenderObjectMixin<_Slot, RenderBox> {
  _RenderTextEntry(this._minHeight, this._oneLine, this._textDirection);

  double _minHeight;
  set minHeight(double value) {
    if (value == _minHeight) return;
    _minHeight = value;
    markNeedsLayout();
  }

  bool _oneLine;
  set oneLine(bool value) {
    if (value == _oneLine) return;
    _oneLine = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  RenderBox get _editable => childForSlot(_Slot.editable)!;
  RenderBox? get _hint => childForSlot(_Slot.hint);

  // The height of one line of the editable inside the child.
  double? get _lineHeight {
    RenderEditable? found;
    void visit(RenderObject node) {
      if (found != null) return;
      if (node is RenderEditable) {
        found = node;
      } else {
        node.visitChildren(visit);
      }
    }

    visit(_editable);
    return found?.preferredLineHeight;
  }

  // What is left above a first line when several lines start where one
  // would stand; a single line is centred instead, and needs none.
  double get _air {
    final line = _lineHeight;
    if (_oneLine || line == null) return 0;
    return math.max(0.0, (_minHeight - line) / 2);
  }

  _Measured _measure(BoxConstraints constraints, ChildLayouter layoutChild) {
    final air = _air;
    final editableConstraints = BoxConstraints(
      minWidth: constraints.minWidth,
      maxWidth: constraints.maxWidth,
      maxHeight: math.max(0.0, constraints.maxHeight - 2 * air),
    );
    final editable = layoutChild(_editable, editableConstraints);
    final box = constraints.constrain(
      Size(editable.width, math.max(_minHeight, editable.height + 2 * air)),
    );
    return (
      box: box,
      editable: editable,
      editableConstraints: editableConstraints,
      top: _oneLine ? (box.height - editable.height) / 2 : air,
    );
  }

  // Where a child [width] wide starts in a box [boxWidth] wide.
  double _start(double boxWidth, double width) =>
      _textDirection == TextDirection.rtl ? boxWidth - width : 0;

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _measure(constraints, ChildLayoutHelper.dryLayoutChild).box;

  @override
  double? computeDryBaseline(
    covariant BoxConstraints constraints,
    TextBaseline baseline,
  ) {
    final measured = _measure(constraints, ChildLayoutHelper.dryLayoutChild);
    final distance = _editable.getDryBaseline(
      measured.editableConstraints,
      baseline,
    );
    return distance == null ? null : distance + measured.top;
  }

  @override
  double? computeDistanceToActualBaseline(TextBaseline baseline) {
    final editable = _editable;
    final distance = editable.getDistanceToActualBaseline(baseline);
    if (distance == null) return null;
    return distance + (editable.parentData! as BoxParentData).offset.dy;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _editable.getMinIntrinsicWidth(height);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _editable.getMaxIntrinsicWidth(height);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(_minHeight, _editable.getMinIntrinsicHeight(width) + 2 * _air);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(_minHeight, _editable.getMaxIntrinsicHeight(width) + 2 * _air);

  @override
  void performLayout() {
    final measured = _measure(constraints, ChildLayoutHelper.layoutChild);
    size = measured.box;
    final editable = _editable;
    final top = measured.top;
    (editable.parentData! as BoxParentData).offset = Offset(
      _start(size.width, editable.size.width),
      top,
    );
    final hint = _hint;
    if (hint == null) return;
    hint.layout(
      BoxConstraints(maxWidth: editable.size.width),
      parentUsesSize: true,
    );
    const alphabetic = TextBaseline.alphabetic;
    final typed = editable.getDistanceToBaseline(alphabetic, onlyReal: true);
    final own = hint.getDistanceToBaseline(alphabetic, onlyReal: true);
    final line = _lineHeight ?? editable.size.height;
    (hint.parentData! as BoxParentData).offset = Offset(
      _start(size.width, hint.size.width),
      typed != null && own != null
          ? top + typed - own
          : top + (line - hint.size.height) / 2,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    void draw(RenderBox? child) {
      if (child == null) return;
      final at = (child.parentData! as BoxParentData).offset;
      context.paintChild(child, offset + at);
    }

    draw(_hint);
    draw(_editable);
  }

  // A press anywhere in the box is a press on the editable: its nearest
  // point, as the box is taller than a line.
  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final editable = _editable;
    final at = (editable.parentData! as BoxParentData).offset;
    final inside = Offset(
      math.min(math.max(position.dx, at.dx), at.dx + editable.size.width - 1),
      math.min(math.max(position.dy, at.dy), at.dy + editable.size.height - 1),
    );
    return result.addWithPaintOffset(
      offset: at,
      position: inside,
      hitTest: (result, transformed) =>
          editable.hitTest(result, position: transformed),
    );
  }
}
