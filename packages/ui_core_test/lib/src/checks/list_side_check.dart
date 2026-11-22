part of '../alignment.dart';

/// Whether each list open under a field or a button (a [RawPopover]'s, an
/// autocomplete's) opens below it when below has room for it.
///
/// A list opens on the side it asks for, below unless it says otherwise, as
/// Material's menus and autocomplete do: the side the eye goes to from the
/// field, and the side the next list on the page opens on. It takes the
/// other side only when the room below can't hold it, or a sensible least
/// of a longer list (200 px, which it then fills and scrolls). A list that
/// opens above with that room below, because above has more, jumps from
/// side to side as the page scrolls. A popover is held to its own
/// placement's rule: its [RawPopoverPlacement.preferredExtent] is the
/// least, and a surface placed with [RawPopoverFit.whole] (a month, a grid)
/// needs its whole extent below, so one that fits whole only above opens
/// there.
///
/// - **Below while below holds it**: a list that asks for below (a
///   popover placed below, an autocomplete that opens down or on the side
///   with most space) and stands above its anchor has less than its height,
///   and less than its least (200 px, or its placement's), below the anchor:
///   `a list over "Assignee" at 16,
///   246 opens above it with 330 px free below, room for 200 px of its 220
///   px`.
///
/// The room below runs from the anchor to the screen's foot, less the safe
/// area and the keyboard. It reads layout boxes. A test pumps a screen,
/// opens a list, then:
///
/// ```dart
/// const DesignListSideCheck(look: 'Comic')
///     .check(tester.element(find.byType(TaskForm)))
///     .verify();
/// ```
@immutable
class DesignListSideCheck {
  /// A check for [look].
  const DesignListSideCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// The least of a longer list that the room below must hold before the
  /// list may open above: a [RawPopoverPlacement]'s default preferred
  /// extent, and an autocomplete's. A popover's own placement says its
  /// least.
  static const double least = 200;

  /// Checks every list open under [context].
  DesignAlignmentReport check(BuildContext context) {
    final problems = <String>[];
    void find(Element e) {
      // The least of it the room below must hold, when it asks for below.
      final least = switch (e.widget) {
        RawPopover(:final placement)
            when placement.side == RawPopoverSide.below =>
          placement.fit == RawPopoverFit.whole
              ? double.infinity
              : placement.preferredExtent,
        RawAutocomplete<Object>(:final optionsViewOpenDirection)
            when optionsViewOpenDirection != OptionsViewOpenDirection.up =>
          DesignListSideCheck.least,
        _ => null,
      };
      if (least != null) {
        if (_listAbove(e, least) case final problem?) problems.add(problem);
      }
      e.visitChildren(find);
    }

    find(context as Element);
    return DesignAlignmentReport(look, problems);
  }
}

// What is wrong with the list [anchor] opens, if it is open: null when it
// is closed, below its anchor, or above with too little room below for it
// or [least] of it.
String? _listAbove(Element anchor, double least) {
  final box = anchor.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize || !_isShown(box)) {
    return null;
  }
  final root = _overlayChildOf(anchor, box);
  if (root == null || !root.hasSize) return null;
  final list = _listIn(root);
  if (list == null) return null;
  final field = _global(box);
  final drawn = _global(list);
  if (drawn.bottom > field.top + 0.5) return null;
  final media = MediaQuery.maybeOf(anchor);
  if (media == null) return null;
  final screen = (media.padding + media.viewInsets).deflateRect(
    Offset.zero & media.size,
  );
  final below = screen.bottom - field.bottom;
  final needs = math.min(drawn.height, least);
  if (below < needs + 1) return null;
  final name = _nameOf(box);
  return 'a list over $name at ${_px(drawn.left)}, ${_px(drawn.top)} '
      'opens above it with ${_px(below)} px free below, room for '
      '${drawn.height <= least ? 'its' : '${_px(needs)} px of its'} '
      '${_px(drawn.height)} px: it opens below while below holds it';
}

// The box of what [anchor] shows in an overlay: the first box built under
// it that is laid out outside its own box [own].
RenderBox? _overlayChildOf(Element anchor, RenderBox own) {
  RenderBox? found;
  bool inside(RenderObject r) {
    for (RenderObject? up = r; up != null; up = up.parent) {
      if (identical(up, own)) return true;
    }
    return false;
  }

  void visit(Element e) {
    if (found != null) return;
    final r = e.renderObject;
    if (r is RenderBox && r.attached && !inside(r)) {
      found = r;
      return;
    }
    e.visitChildren(visit);
  }

  anchor.visitChildren(visit);
  return found;
}

// The list's own box under an overlay's [root]: the first box, breadth
// first, that is shorter than the room the overlay gives it and is shown,
// then down the boxes it holds one at a time to the one that holds the
// rows (a room the list may not fill holds the list's own box).
RenderBox? _listIn(RenderBox root) {
  final queue = <RenderObject>[root];
  final room = root.size.height;
  RenderBox? found;
  while (queue.isNotEmpty && found == null) {
    final n = queue.removeAt(0);
    if (n is RenderBox &&
        n.hasSize &&
        n.size.height > 0 &&
        n.size.height < room - 0.5 &&
        _isShown(n)) {
      found = n;
    } else {
      n.visitChildren(queue.add);
    }
  }
  var list = found;
  while (list != null && list is! RenderAbstractViewport) {
    final children = <RenderObject>[];
    list.visitChildren(children.add);
    final only = children.length == 1 ? children.single : null;
    if (only is! RenderBox || !only.hasSize || only.size.height <= 0) break;
    list = only;
  }
  return list;
}
