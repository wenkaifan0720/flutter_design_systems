/// A choice's field (a select, a combobox, a multi-select) and an expanded
/// control (a button, a toggle, a button group or segmented button), as wide
/// as a control is from 600 (design6 P (a); ui_core's DesignWidthCheck).
/// Internal: each applies it once, in its own build.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../components/menus.dart' show ExpressiveMenu;
import '../components/select.dart' show ExpressiveSelect;

/// [face], a choice's field: in a window [ExpressiveSelect.wideFrom] or
/// wider, at most [ExpressiveSelect.wideMaxWidth] wide at its column's start
/// (a form grid's narrower cell bounds it as before); on a phone, its
/// column's width.
///
/// [fitContent], never narrower than [face] needs for its content on one
/// line (a segmented control's labels, read from its intrinsic width; its
/// segments must answer intrinsics).
Widget expressiveChoiceWidth(
  BuildContext context,
  Widget face, {
  bool fitContent = false,
}) {
  if (MediaQuery.sizeOf(context).width < ExpressiveSelect.wideFrom) {
    return face;
  }
  // Its own height too: offered more (a Center's, a dialog's), it stays
  // the control's height.
  return Align(
    alignment: AlignmentDirectional.centerStart,
    widthFactor: 1,
    heightFactor: 1,
    child: fitContent
        ? _ControlWidth(child: face)
        : ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: ExpressiveSelect.wideMaxWidth,
            ),
            child: face,
          ),
  );
}

class _ControlWidth extends SingleChildRenderObjectWidget {
  const _ControlWidth({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderControlWidth();
}

// At most a control's width, unless its content needs more on one line
// (within what it is given): a segmented control whose labels would wrap at
// 320 is as wide as they are.
class _RenderControlWidth extends RenderProxyBox {
  @override
  void performLayout() {
    final face = child;
    if (face == null) {
      size = constraints.smallest;
      return;
    }
    final content = face.getMaxIntrinsicWidth(double.infinity);
    final cap = math.max(ExpressiveSelect.wideMaxWidth, content.ceilToDouble());
    final maxWidth = math.min(constraints.maxWidth, cap);
    face.layout(
      constraints.copyWith(
        minWidth: math.min(constraints.minWidth, maxWidth),
        maxWidth: maxWidth,
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(face.size);
  }
}

/// [face], a select's read-only field: in a window
/// [ExpressiveSelect.wideFrom] or wider, at least as wide as its widest
/// option of [labels] needs, up to the width it is given (Flutter's
/// `DropdownButton` is as wide as its widest item), so a person reads any
/// choice whole and the face does not change width as they choose; on a
/// phone, as it is (its column's width; a choice too long for it ends in an
/// ellipsis).
Widget expressiveWidestOption(
  BuildContext context,
  List<String> labels,
  Widget face,
) {
  if (MediaQuery.sizeOf(context).width < ExpressiveSelect.wideFrom ||
      labels.isEmpty) {
    return face;
  }
  return _WidestOption(labels: labels, child: face);
}

class _WidestOption extends SingleChildRenderObjectWidget {
  const _WidestOption({required this.labels, required super.child});

  final List<String> labels;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWidestOption(labels);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderWidestOption renderObject,
  ) => renderObject.labels = labels;
}

// Lays the face out as it is given, then, when its entry is narrower than
// the widest option drawn in the entry's own style, again that much wider
// (within what it is given).
class _RenderWidestOption extends RenderProxyBox {
  _RenderWidestOption(this._labels);

  List<String> _labels;
  set labels(List<String> value) {
    if (listEquals(value, _labels)) return;
    _labels = value;
    markNeedsLayout();
  }

  @override
  void performLayout() {
    final face = child;
    if (face == null) {
      size = constraints.smallest;
      return;
    }
    face.layout(constraints, parentUsesSize: true);
    final entry = _entryIn(face);
    if (entry != null) {
      // The entry fills the width it is given (its size is its parent's to
      // read); the caret's gap and width end its line.
      final room = entry.constraints.maxWidth - entry.cursorWidth - 1;
      final short = _widest(entry) - room;
      if (short > 0.5 && face.size.width < constraints.maxWidth) {
        final width = math.min(constraints.maxWidth, face.size.width + short);
        face.layout(
          constraints.copyWith(minWidth: math.max(constraints.minWidth, width)),
          parentUsesSize: true,
        );
      }
    }
    size = face.size;
  }

  double _widest(RenderEditable entry) {
    var widest = 0.0;
    for (final label in _labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: entry.text?.style),
        textDirection: entry.textDirection,
        textScaler: entry.textScaler,
        maxLines: 1,
      )..layout();
      widest = math.max(widest, painter.width);
      painter.dispose();
    }
    return widest;
  }
}

RenderEditable? _entryIn(RenderObject node) {
  if (node is RenderEditable) return node;
  RenderEditable? found;
  node.visitChildren((child) => found ??= _entryIn(child));
  return found;
}

/// A choice's field's state (a select's, a combobox's): where its value
/// starts from its start edge, read after each frame from the field keyed
/// [valueFace], for its list's words ([ExpressiveMenu.wordsStart]).
mixin ExpressiveValueStart<W extends StatefulWidget> on State<W> {
  /// The field's key.
  final GlobalKey valueFace = GlobalKey();

  /// Where the field's value starts; null before the field is laid out.
  double? valueStart;

  /// Reads [valueStart] once this frame is laid out (called from build).
  void measureValueStart() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final face = valueFace.currentContext?.findRenderObject();
      if (face is! RenderBox || !face.hasSize || !face.attached) return;
      final entry = _entryIn(face);
      if (entry == null || !entry.hasSize) return;
      final left = entry.localToGlobal(Offset.zero, ancestor: face).dx;
      final start = Directionality.of(context) == TextDirection.rtl
          ? face.size.width - left - entry.size.width
          : left;
      if ((start - (valueStart ?? -1)).abs() > 0.01) {
        setState(() => valueStart = start);
      }
    });
  }
}
