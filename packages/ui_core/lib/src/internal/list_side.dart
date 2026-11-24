/// The side of its field a list from a `RawAutocomplete` opens on (a
/// combobox's, a tag input's), placed as a popover's list is: the side it
/// asks for while that side holds the list, or a sensible least of a longer
/// one; the other side only when it has more room and the asked side can't.
/// Inside ui_core; not exported.
library;

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../anchored_overlay.dart';

/// The least a side must hold of a list that is longer, before the list
/// takes the other side: a popover's [RawPopoverPlacement.preferredExtent].
const double rawListLeast = 200;

/// The direction a `RawAutocomplete` gets for a list that asks for [asked],
/// [flipped] to the other side or not. [OptionsViewOpenDirection.mostSpace]
/// is Flutter's own and never flips.
OptionsViewOpenDirection rawListDirection(
  OptionsViewOpenDirection asked, {
  required bool flipped,
}) => switch (asked) {
  OptionsViewOpenDirection.mostSpace => asked,
  OptionsViewOpenDirection.up when flipped => OptionsViewOpenDirection.down,
  OptionsViewOpenDirection.down when flipped => OptionsViewOpenDirection.up,
  _ => asked,
};

/// Measures a `RawAutocomplete`'s list (its options view) where it is laid
/// out and tells [onFlip] when the list should be on the other side of its
/// field: when its [asked] side can't hold the list's own height, or
/// [rawListLeast] of a longer list, and the other side has more room. A
/// list on the wrong side is not painted or hit until it is built there.
///
/// [field] is the autocomplete's own context: its box is the field's, in the
/// nearest overlay, as the autocomplete places the list. The rooms are its
/// own: from the field to the overlay's edge, less the safe area and the
/// on-screen keyboard.
class RawListSide extends SingleChildRenderObjectWidget {
  /// Watches the side of [child], laid out [opensUp] or not.
  const RawListSide({
    super.key,
    required this.field,
    required this.asked,
    required this.opensUp,
    required this.onFlip,
    super.child,
  });

  /// The autocomplete's context.
  final BuildContext field;

  /// The side the list asks for: [OptionsViewOpenDirection.up] or
  /// [OptionsViewOpenDirection.down].
  final OptionsViewOpenDirection asked;

  /// Whether the autocomplete laid the list out above the field.
  final bool opensUp;

  /// Told, after the frame, whether the list should be flipped from
  /// [asked].
  final ValueChanged<bool> onFlip;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderListSide(
    field,
    asked,
    opensUp,
    onFlip,
    MediaQuery.paddingOf(context),
    MediaQuery.viewInsetsOf(context),
  );

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    (renderObject as _RenderListSide)
      ..field = field
      ..asked = asked
      ..opensUp = opensUp
      ..onFlip = onFlip
      ..padding = MediaQuery.paddingOf(context)
      ..insets = MediaQuery.viewInsetsOf(context);
  }
}

class _RenderListSide extends RenderProxyBox {
  _RenderListSide(
    this.field,
    this._asked,
    this._opensUp,
    this.onFlip,
    this._padding,
    this._insets,
  );

  BuildContext field;
  ValueChanged<bool> onFlip;

  OptionsViewOpenDirection _asked;
  set asked(OptionsViewOpenDirection value) {
    if (value == _asked) return;
    _asked = value;
    markNeedsLayout();
  }

  bool _opensUp;
  set opensUp(bool value) {
    if (value == _opensUp) return;
    _opensUp = value;
    markNeedsLayout();
  }

  EdgeInsets _padding;
  set padding(EdgeInsets value) {
    if (value == _padding) return;
    _padding = value;
    markNeedsLayout();
  }

  EdgeInsets _insets;
  set insets(EdgeInsets value) {
    if (value == _insets) return;
    _insets = value;
    markNeedsLayout();
  }

  // Laid out on the wrong side: built on the other next frame.
  bool _wrongSide = false;

  // The room above and below the field in its overlay, as the autocomplete
  // measures it; null while the field is not laid out in one.
  ({double above, double below})? _rooms() {
    if (!field.mounted) return null;
    final box = field.findRenderObject();
    final overlay = Overlay.maybeOf(field)?.context.findRenderObject();
    if (box is! RenderBox || !box.hasSize || overlay is! RenderBox) {
      return null;
    }
    if (!overlay.hasSize || !box.attached) return null;
    final rect = MatrixUtils.transformRect(
      box.getTransformTo(overlay),
      Offset.zero & box.size,
    );
    final bounds = _padding.deflateRect(
      _insets.deflateRect(Offset.zero & overlay.size),
    );
    return (
      above: math.max(0, rect.top - bounds.top),
      below: math.max(0, bounds.bottom - rect.bottom),
    );
  }

  @override
  void performLayout() {
    super.performLayout();
    final child = this.child;
    // The field's box, laid out before its list: read as a layout callback
    // reads the boxes round it (the autocomplete reads it so too).
    ({double above, double below})? rooms;
    invokeLayoutCallback<BoxConstraints>((_) => rooms = _rooms());
    final found = rooms;
    if (child == null || found == null) {
      _wrongSide = false;
      return;
    }
    final up = _asked == OptionsViewOpenDirection.up;
    final room = up ? found.above : found.below;
    final other = up ? found.below : found.above;
    final here = _opensUp ? found.above : found.below;
    // Its height in the larger room: what it needs.
    var extent = child.size.height;
    if (here < math.max(room, other)) {
      child.layout(
        constraints.copyWith(minHeight: 0, maxHeight: math.max(room, other)),
        parentUsesSize: true,
      );
      extent = child.size.height;
      super.performLayout();
    }
    final flip = room < math.min(extent, rawListLeast) && other > room;
    _wrongSide = (flip ? !up : up) != _opensUp;
    if (_wrongSide) {
      WidgetsBinding.instance
        ..addPostFrameCallback((_) => onFlip(flip), debugLabel: 'list side')
        ..ensureVisualUpdate();
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!_wrongSide) super.paint(context, offset);
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) =>
      !_wrongSide && super.hitTest(result, position: position);
}
