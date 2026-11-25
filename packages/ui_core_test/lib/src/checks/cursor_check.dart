part of '../alignment.dart';

/// Whether every control on a screen shows a pointer that says it acts:
/// over its whole hit area while it is live, and nothing of its own while
/// it is off.
///
/// A mouse over a live control shows the click cursor, as Flutter's own
/// buttons, sliders and switches do on the web and on a desktop, or a
/// cursor of its own that says more (a text field's text cursor, a drag
/// handle's grab, a divider's resize, a colour area's crosshair). A slider
/// that shows the click cursor over its thumb but the arrow over its track
/// reads as a picture of a slider. An off control defers to what is under
/// it: the click cursor over a disabled button promises a press that never
/// comes.
///
/// Each control (a box whose semantics say it is a button, a link, a
/// field, a slider, a switch or a checkbox, or that takes a tap) is read at
/// a grid of spots across its box, as the mouse tracker picks the cursor
/// there: the first mouse region under the pointer that does not defer. A
/// spot where nothing acts (no gesture and no text entry is hit there) is
/// not where the control is (the tap-target check, [DesignTapTargetCheck],
/// reads those), and a spot inside a smaller control within it is that
/// control's. A cursor given as Flutter's adaptive clickable cursor (what
/// Material's ink asks for) shows the click cursor on the web, where the
/// galleries run, and counts as the click cursor here unless [web] is
/// false.
///
/// A test pumps a screen (a gallery page at 1440 wide, an app screen),
/// then:
///
/// ```dart
/// const DesignCursorCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
///
/// It reads the mouse regions and hit tests the layout, and no pixels.
@immutable
class DesignCursorCheck {
  /// A check for [look].
  const DesignCursorCheck({required this.look, this.web = true});

  /// The look's name, for messages.
  final String look;

  /// Whether Flutter's adaptive clickable cursor counts as the click
  /// cursor, as it shows on the web.
  final bool web;

  /// Checks every control under [context] that is laid out and painted.
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null) return DesignAlignmentReport(look, const []);
    final viewId = View.of(context).viewId;
    final found = <String>[];
    for (final (control, inner) in _controlsWithin(root)) {
      final rect = _global(control);
      if (rect.width < 4 || rect.height < 4) continue;
      final kind = _cursorKind(control);
      if (kind == null) continue;
      // A modal barrier (a tap outside a sheet or a dialog closes it) keeps
      // the arrow, as Flutter's own does.
      if (_isBarrier(control)) continue;
      // A surface that takes taps but says nothing of itself (a chart to
      // inspect, a map, a canvas) keeps the arrow, as the web's do.
      if (_partName(control) == 'a control' && rect.shortestSide > 64) {
        continue;
      }
      final spots = _spots(rect);
      if (kind == _CursorKind.off) {
        final at = rect.center;
        if (inner.any((b) => _global(b).contains(at))) continue;
        final (cursor, region) = _cursorAt(at, viewId);
        if (region != null &&
            _isWithin(region, control) &&
            _saysItActs(cursor, region, live: false)) {
          found.add(
            '${_partName(control)} is off but shows the ${_cursorName(cursor)} '
            'cursor, which promises a press that never comes: an off control '
            'defers to what is under it',
          );
        }
        continue;
      }
      final wrong = <(Offset, MouseCursor)>[];
      var read = 0;
      for (final at in spots) {
        if (inner.any((b) => _global(b).contains(at))) continue;
        final path = _pathAt(at, viewId);
        final actor = _actorIn(path);
        if (actor == null || !_belongsTo(actor, control)) continue;
        read++;
        final (cursor, region) = _cursorIn(path);
        if (!kind.allows(cursor, region, web: web)) wrong.add((at, cursor));
      }
      if (wrong.isEmpty) continue;
      final shown = {for (final (_, c) in wrong) _cursorName(c)}.join(' or ');
      final where = _whereIn(rect, [for (final (at, _) in wrong) at]);
      found.add(
        '${_partName(control)} shows the $shown cursor $where '
        '(${wrong.length} of the $read spots where it acts): a live '
        '${kind == _CursorKind.field ? 'field shows the text cursor' : 'control shows the click cursor (or its own: grab, resize)'} '
        'over all of it',
      );
    }
    return DesignAlignmentReport(look, found);
  }

  // The spots a control is read at: across its box, two pixels in from its
  // edges, more of them along a long side (a slider's track), less its four
  // corners, which a round face leaves.
  static List<Offset> _spots(Rect r) {
    int count(double side) => (side / 24).round().clamp(3, 9);
    List<double> along(double start, double side, int n) {
      final inset = math.min(2.0, side / 4);
      return [
        for (var i = 0; i < n; i++)
          start + inset + (side - 2 * inset) * i / (n - 1),
      ];
    }

    final ys = along(r.top, r.height, count(r.height));
    final xs = along(r.left, r.width, count(r.width));
    return [
      for (final y in ys)
        for (final x in xs)
          if (!((y == ys.first || y == ys.last) &&
              (x == xs.first || x == xs.last)))
            Offset(x, y),
    ];
  }
}

// What a control's cursor must be.
enum _CursorKind {
  // A text field: the text cursor, or the click cursor over one that opens
  // something (a select's, a date's).
  field,

  // Anything else live: not the arrow.
  live,

  // Off: its own region defers.
  off;

  bool allows(
    MouseCursor cursor,
    RenderMouseRegion? region, {
    required bool web,
  }) {
    final acts =
        region != null && _saysItActs(cursor, region, live: true, web: web);
    return switch (this) {
      field => acts,
      live => acts,
      off => !acts,
    };
  }
}

// The kind of [control], from its semantics; null for a box that is not a
// control after all (a gesture handler with nothing to do).
_CursorKind? _cursorKind(RenderBox control) {
  final s = _semanticsOf(control);
  if (s.disabled) return _CursorKind.off;
  if (s.entry) return _CursorKind.field;
  return _CursorKind.live;
}

// The controls under [root] that are painted, each with the controls
// inside it (whose spots are theirs). A control nested in one of the same
// box (a Semantics over a MergeSemantics over the same gesture) is one.
List<(RenderBox, List<RenderBox>)> _controlsWithin(RenderObject root) {
  final controls = <RenderBox>[];
  void visit(RenderObject node) {
    if (node is RenderBox && node.hasSize && _isControl(node)) {
      final rect = _global(node);
      // The same control said twice over the same box.
      final outer = controls.lastOrNull;
      if (outer == null || !_isWithin(node, outer) || _global(outer) != rect) {
        controls.add(node);
      }
    }
    _visitShown(node, visit);
  }

  visit(root);
  return [
    for (final c in controls)
      (
        c,
        [
          for (final d in controls)
            if (!identical(d, c) && _isWithin(d, c) && _global(d) != _global(c))
              d,
        ],
      ),
  ];
}

// The cursor the mouse tracker shows at [at], and the region it comes from
// (null: none decides, the arrow).
(MouseCursor, RenderMouseRegion?) _cursorAt(Offset at, int viewId) =>
    _cursorIn(_pathAt(at, viewId));

(MouseCursor, RenderMouseRegion?) _cursorIn(List<HitTestEntry> path) {
  for (final entry in path) {
    final target = entry.target;
    if (target is! MouseTrackerAnnotation) continue;
    final annotation = target as MouseTrackerAnnotation;
    if (!annotation.validForMouseTracker) continue;
    final cursor = annotation.cursor;
    if (cursor == MouseCursor.defer) continue;
    return (cursor, target is RenderMouseRegion ? target : null);
  }
  return (SystemMouseCursors.basic, null);
}

// Whether [cursor] (from [region]) tells a person the spot acts: the click
// cursor, or one of a control's own (text, grab, resize, crosshair). The
// adaptive clickable cursor shows the click cursor on the web, and so does
// the arrow a live Material ink response resolves it to elsewhere.
bool _saysItActs(
  MouseCursor cursor,
  RenderMouseRegion region, {
  required bool live,
  bool web = true,
}) {
  var shown = cursor;
  if (shown == WidgetStateMouseCursor.adaptiveClickable) {
    return web;
  }
  if (shown is WidgetStateMouseCursor) {
    shown = shown.resolve(<WidgetState>{});
  }
  if (shown == SystemMouseCursors.basic) {
    return live && web && _fromInk(region);
  }
  return shown != MouseCursor.defer &&
      shown != MouseCursor.uncontrolled &&
      shown != SystemMouseCursors.none &&
      shown != SystemMouseCursors.forbidden;
}

// Whether [region] is a Material ink response's, whose adaptive cursor
// resolves to the arrow off the web.
bool _fromInk(RenderMouseRegion region) {
  var ink = false;
  final creator = region.debugCreator;
  if (creator is DebugCreator) {
    var depth = 0;
    creator.element.visitAncestorElements((e) {
      final name = e.widget.runtimeType.toString();
      if (name == 'InkResponse' ||
          name == 'InkWell' ||
          name == '_InkResponseStateWidget') {
        ink = true;
      }
      return !ink && ++depth < 8;
    });
  }
  return ink;
}

String _cursorName(MouseCursor cursor) {
  if (cursor == SystemMouseCursors.basic) return 'arrow';
  if (cursor == SystemMouseCursors.click) return 'click';
  if (cursor == SystemMouseCursors.text) return 'text';
  if (cursor == SystemMouseCursors.forbidden) return 'forbidden';
  if (cursor is SystemMouseCursor) return cursor.kind;
  return cursor.debugDescription;
}

// Whether [actor] (what takes a press at a spot) is [control]'s own: under
// it, or the gesture detector round it whose box is the control's (a
// GestureDetector's listener stands above the semantics it adds). A
// gesture round the whole page (a tap that closes the keyboard) is not.
bool _belongsTo(RenderBox actor, RenderBox control) {
  if (_isWithin(actor, control)) return true;
  if (!_isWithin(control, actor)) return false;
  final a = _global(actor);
  final c = _global(control);
  return (a.left - c.left).abs() <= 2 &&
      (a.top - c.top).abs() <= 2 &&
      (a.right - c.right).abs() <= 2 &&
      (a.bottom - c.bottom).abs() <= 2;
}

// [control]'s name, or, for a part with no name of its own (a slider's
// track under the slider's semantics), the part of the control round it.
String _partName(RenderBox control) {
  final own = _nameOf(control);
  if (own != 'a control') return own;
  for (RenderObject? up = control.parent; up != null; up = up.parent) {
    if (up is RenderBox && _isControl(up)) {
      final outer = _nameOf(up);
      if (outer != 'a control') return 'a part of $outer';
    }
  }
  return own;
}

// The first thing in [path] that acts on a press: a gesture detector's
// listener with a gesture (a scroll view's own aside), or a text entry.
RenderBox? _actorIn(List<HitTestEntry> path) {
  for (final entry in path) {
    final target = entry.target;
    if (target is RenderEditable) return target;
    if (target is RenderPointerListener && _isGestureOf(target)) {
      return target;
    }
  }
  return null;
}

// Whether [listener] is a gesture detector's with a gesture, and not a
// scroll view's own (whose drag is the page's, not a control's). Outside a
// debug build, where widgets are not known, any listener that hears a
// pointer down.
bool _isGestureOf(RenderPointerListener listener) {
  final creator = listener.debugCreator;
  if (creator is! DebugCreator) return listener.onPointerDown != null;
  var gestures = false;
  var scroll = false;
  var depth = 0;
  var seenDetector = false;
  creator.element.visitAncestorElements((e) {
    final w = e.widget;
    if (!seenDetector && w is RawGestureDetector) {
      seenDetector = true;
      gestures = w.gestures.isNotEmpty;
    }
    final name = w.runtimeType.toString();
    if (name == 'Scrollable' || name == '_ScrollableScope') scroll = true;
    return ++depth < 6;
  });
  // A Listener of a control's own (a press read from the pointer).
  if (!seenDetector) return listener.onPointerDown != null && !scroll;
  return gestures && !scroll;
}

// Where [spots] stand in [rect], in words: "near its start and in the
// middle", "over all of it".
String _whereIn(Rect rect, List<Offset> spots) {
  String across(double x) {
    final f = rect.width <= 0 ? .5 : (x - rect.left) / rect.width;
    return f < .2
        ? 'near its left end'
        : f < .4
        ? 'a quarter across'
        : f <= .6
        ? 'in its middle'
        : f <= .8
        ? 'three quarters across'
        : 'near its right end';
  }

  final places = {for (final s in spots) across(s.dx)}.toList();
  if (places.length >= 5) return 'over all of it';
  if (places.length == 1) return places.single;
  return '${places.sublist(0, places.length - 1).join(', ')} and '
      '${places.last}';
}
