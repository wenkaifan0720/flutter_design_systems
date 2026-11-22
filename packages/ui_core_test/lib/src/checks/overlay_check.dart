part of '../alignment.dart';

/// Whether each open overlay (a popover, a menu, a list, a picker, a tip, a
/// sheet, a dialog) shows whole: on the screen, and nothing in it cut.
///
/// An overlay is what a person opened to reach what it holds. Any part of it
/// past the screen's edge, or cut by its own frame, can't be seen or picked:
/// a month that runs off the screen's foot through its third week, a week
/// whose Sunday is cut by a dialog narrower than the seven days.
///
/// - **On the screen**: all it paints (its surface and whatever stands past
///   it; a scroll view's rows aside, which scroll into view) stands inside
///   the screen: `an overlay from a button "Due" runs past the screen's foot
///   by 212 px: 300 of its 512 px high show`.
/// - **Nothing cut**: every control and line of words in it shows whole, as
///   [DesignClipCheck] reads them (a scrolled list's rows read against the
///   list alone, as they scroll into view): `in a dialog "Pick a date": a
///   button "29" is cut at its right by 22 px: 26 of its 48 px across
///   show`.
/// - **No needless scroll**: a grid in it (a scroll view whose controls
///   stand several to a line: a month, swatches) shows whole where it can,
///   rather than shrink and scroll. Up and down, it scrolls only where the
///   other side of its anchor can't hold it whole either: `an overlay from
///   a button "Due" shrinks a grid to 248 of its 300 px high and scrolls
///   it, where above its anchor holds it whole`. Sideways, it scrolls by a
///   control at least, as a strip shows more to scroll to: `in a dialog
///   "Pick a date": a grid scrolls sideways by 26 px, less than its
///   narrowest control (48 px)`. A list (a control to a line) is
///   [DesignListSideCheck]'s: it may shrink to the room below and scroll.
///
/// It finds every overlay open anywhere in the app, whatever [check] is
/// given: what an [OverlayPortal] shows (a [RawPopover]'s, an
/// autocomplete's, a `MenuAnchor`'s, a tip's) and each [PopupRoute]'s page
/// (a dialog's, a sheet's). It reads layout boxes and the clips over them,
/// and no pixels. A test pumps a screen, opens an overlay, lets it settle,
/// then:
///
/// ```dart
/// const DesignOverlayCheck(look: 'Comic')
///     .check(tester.element(find.byType(TaskForm)))
///     .verify();
/// ```
@immutable
class DesignOverlayCheck {
  /// A check for [look].
  const DesignOverlayCheck({required this.look, this.tolerance = 0.5});

  /// The look's name, for messages.
  final String look;

  /// How far, in logical pixels, a surface may stand past the screen, and
  /// what shows past a clip.
  final double tolerance;

  /// Checks every overlay open in the app [context] is in.
  DesignAlignmentReport check(BuildContext context) {
    final found = <String>[];
    final reader = _DrawnReader(null, null, _markedFaces(context));
    final clips = DesignClipCheck(look: look, tolerance: tolerance);
    final seen = <RenderBox>{};
    final routes = <Route<Object?>>{};
    final scrolls = <(ScrollPosition, RenderBox)>[];

    void surface(
      RenderBox root,
      String name,
      MediaQueryData? media, {
      Rect? anchor,
    }) {
      final box = _surfaceOf(root, media?.size);
      if (box == null || !seen.add(box)) return;
      if (media != null) {
        final reach = _reachOf(root, media.size);
        if (reach != null) {
          if (_offScreen(reach, Offset.zero & media.size) case final off?) {
            found.add('$name $off');
          }
        }
      }
      for (final cut in clips._cutsUnder(box, reader)) {
        found.add('in $name: $cut');
      }
      for (final (position, view) in scrolls) {
        if (!_holds(box, view)) continue;
        if (_needlessScroll(position, view, box, anchor, media)
            case final scroll?) {
          found.add(
            anchor != null && position.axis == Axis.vertical
                ? '$name $scroll'
                : 'in $name: $scroll',
          );
        }
      }
    }

    void visit(Element e) {
      final widget = e.widget;
      if (widget is OverlayPortal) {
        final own = e.renderObject;
        if (own is RenderBox && own.attached && own.hasSize && _isShown(own)) {
          if (_overlayChildOf(e, own) case final root? when root.hasSize) {
            surface(
              root,
              'an overlay from ${_nameOf(own)}',
              MediaQuery.maybeOf(e),
              anchor: _global(own),
            );
          }
        }
      } else if (widget is PageStorage) {
        // A route's page: ModalRoute's scope stores its page's state.
        final route = ModalRoute.of(e);
        if (route is PopupRoute && route.isActive && routes.add(route)) {
          final root = _firstBox(e);
          if (root != null && root.attached && root.hasSize) {
            final kind = route is RawDialogRoute ? 'a dialog' : 'a popup';
            surface(root, '$kind${_wordsOf(root)}', MediaQuery.maybeOf(e));
          }
        }
      }
      e.visitChildren(visit);
    }

    var top = context as Element;
    top.visitAncestorElements((up) {
      top = up;
      return true;
    });
    void scrollables(Element e) {
      if (e is StatefulElement && e.state is ScrollableState) {
        final position = (e.state as ScrollableState).position;
        final view = e.renderObject;
        if (view is RenderBox &&
            view.attached &&
            view.hasSize &&
            position.hasContentDimensions) {
          scrolls.add((position, view));
        }
      }
      e.visitChildren(scrollables);
    }

    scrollables(top);
    visit(top);
    return DesignAlignmentReport(look, found);
  }

  // What is needless about [view]'s scroll in the overlay [surface] (the
  // anchor at [anchor], if any): null where it holds no grid, or scrolls as
  // a grid may.
  String? _needlessScroll(
    ScrollPosition position,
    RenderBox view,
    RenderBox surface,
    Rect? anchor,
    MediaQueryData? media,
  ) {
    final hidden = position.maxScrollExtent - position.minScrollExtent;
    if (hidden <= tolerance) return null;
    final controls = <Rect>[];
    void visit(RenderObject n) {
      if (n is RenderBox && n.hasSize && !n.size.isEmpty && _isControl(n)) {
        controls.add(_global(n));
        return;
      }
      _visitShown(n, visit);
    }

    visit(view);
    if (!_isGrid(controls)) return null;
    if (position.axis == Axis.horizontal) {
      final narrowest = controls.map((r) => r.width).reduce(math.min);
      if (hidden >= narrowest - tolerance) return null;
      return 'a grid scrolls sideways by ${_px(hidden)} px, less than its '
          'narrowest control (${_px(narrowest)} px): it fits whole, or '
          'scrolls by a control at least';
    }
    if (anchor == null || media == null) return null;
    final shown = _global(surface);
    final screen = (media.padding + media.viewInsets).deflateRect(
      Offset.zero & media.size,
    );
    final whole = shown.height + hidden;
    final below = shown.top >= anchor.center.dy;
    // The gap to the anchor and the margin to the screen's edge, as the
    // overlay stands, kept on the other side.
    final gap = below ? shown.top - anchor.bottom : anchor.top - shown.bottom;
    final margin = below
        ? screen.bottom - shown.bottom
        : shown.top - screen.top;
    final other = below
        ? anchor.top - screen.top
        : screen.bottom - anchor.bottom;
    if (other < whole + gap + margin - tolerance) return null;
    return 'shrinks a grid to ${_px(shown.height)} of its ${_px(whole)} px '
        'high and scrolls it, where ${below ? 'above' : 'below'} its anchor '
        'holds it whole: a grid opens where it fits whole';
  }

  // Where [shown] stands past [screen], "runs past the screen's foot by 212
  // px: 300 of its 512 px high show"; null when it stands inside.
  String? _offScreen(Rect shown, Rect screen) {
    final sides = [
      for (final (side, by) in [
        ('left edge', screen.left - shown.left),
        ('top', screen.top - shown.top),
        ('right edge', shown.right - screen.right),
        ('foot', shown.bottom - screen.bottom),
      ])
        if (by > tolerance) "the screen's $side by ${_px(by)} px",
    ];
    if (sides.isEmpty) return null;
    final seen = shown.intersect(screen);
    final across =
        shown.left < screen.left - tolerance ||
        shown.right > screen.right + tolerance;
    final (part, whole, way) = across
        ? (math.max(0.0, seen.width), shown.width, 'across')
        : (math.max(0.0, seen.height), shown.height, 'high');
    return 'runs past ${sides.join(' and ')}: ${_px(part)} of its '
        '${_px(whole)} px $way show';
  }
}

// Whether [box] stands in [surface]'s render tree.
bool _holds(RenderObject surface, RenderObject box) {
  for (RenderObject? up = box; up != null; up = up.parent) {
    if (identical(up, surface)) return true;
  }
  return false;
}

// Whether [controls] stand as a grid: some two on one line side by side.
bool _isGrid(List<Rect> controls) {
  for (var i = 0; i < controls.length; i++) {
    for (var j = i + 1; j < controls.length; j++) {
      final (a, b) = (controls[i], controls[j]);
      final line = math.min(a.height, b.height) / 2;
      if ((a.center.dy - b.center.dy).abs() < line &&
          (a.right <= b.left + 0.5 || b.right <= a.left + 0.5)) {
        return true;
      }
    }
  }
  return false;
}

// What [root] shows, global: every box it paints that has an area, but a
// layer as large as [screen] and what a scroll view holds (which scrolls
// into view); null when it shows nothing.
Rect? _reachOf(RenderBox root, Size screen) {
  Rect? reach;
  void visit(RenderObject n) {
    if (n is RenderBox && n.hasSize && !n.size.isEmpty) {
      final rect = _global(n);
      final layer =
          rect.width >= screen.width - 0.5 &&
          rect.height >= screen.height - 0.5;
      if (!layer) reach = reach == null ? rect : reach!.expandToInclude(rect);
    }
    if (n is RenderAbstractViewport) return;
    _visitShown(n, visit);
  }

  visit(root);
  return reach;
}

// The overlay's surface under [root]: [root] itself when it is smaller than
// [screen] on either axis (or no screen is known), else the first box,
// breadth first, that is shown, has an area and is smaller than [screen].
RenderBox? _surfaceOf(RenderBox root, Size? screen) {
  bool smaller(RenderBox b) =>
      screen == null ||
      b.size.width < screen.width - 0.5 ||
      b.size.height < screen.height - 0.5;
  if (smaller(root) && !root.size.isEmpty) return root;
  final queue = <RenderObject>[root];
  while (queue.isNotEmpty) {
    final n = queue.removeAt(0);
    if (n is RenderBox &&
        n.hasSize &&
        !n.size.isEmpty &&
        smaller(n) &&
        _isShown(n)) {
      return n;
    }
    _visitShown(n, queue.add);
  }
  return null;
}

// The first box built under [e].
RenderBox? _firstBox(Element e) {
  RenderBox? found;
  void visit(Element c) {
    if (found != null) return;
    if (c.renderObject case final RenderBox box) {
      found = box;
      return;
    }
    c.visitChildren(visit);
  }

  e.visitChildren(visit);
  return found;
}

// " "Pick a date"": the first words under [root], for a message; empty
// when it has none.
String _wordsOf(RenderObject root) {
  String? words;
  void visit(RenderObject n) {
    if (words != null) return;
    if (n is RenderSemanticsAnnotations &&
        (n.properties.namesRoute ?? false) &&
        (n.properties.label ?? '').isNotEmpty) {
      words = n.properties.label;
      return;
    }
    if (n is RenderParagraph) {
      final t = n.text.toPlainText(includeSemanticsLabels: false).trim();
      if (t.isNotEmpty && !isIconGlyph(t)) {
        words = t;
        return;
      }
    }
    _visitShown(n, visit);
  }

  visit(root);
  final w = words;
  if (w == null) return '';
  return ' "${w.length > 30 ? '${w.substring(0, 29)}…' : w}"';
}
