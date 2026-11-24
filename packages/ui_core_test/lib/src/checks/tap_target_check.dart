part of '../alignment.dart';

/// Whether every tap target on a screen takes a tap where a finger, a
/// pointer and a screen reader are told it is: the area a tap reaches is at
/// least the floor for what reaches the controls ([input]: 44 by 44 for a
/// finger, 24 by 24 for a pointer, or the look's own from its
/// [RawTapTargetScope]), and it is the box a screen reader outlines,
/// whatever the input.
///
/// Flutter's tap-target guidelines (`androidTapTargetGuideline`,
/// `iOSTapTargetGuideline`) measure the semantics box alone. A control can
/// report a 44 pt box that a tap cannot reach: hit testing reaches a child
/// only through its parent's bounds, so a 32 pt face that widens its own
/// hit test to 44 pt inside a 32 pt row takes taps over 32 pt, while a
/// screen reader outlines, and the guidelines pass, 44 pt. Material's
/// `MaterialTapTargetSize.padded` lays the control out at the floor instead,
/// so layout, hit area and semantics agree.
///
/// Each live node that takes a tap (from the semantics tree: a widget test has
/// it unless it turns it off, an app while a screen reader runs) is read from
/// the middle of its box outwards along both axes, as the pointer is hit tested
/// there: how far a tap still reaches what takes it at the middle. A node whose
/// reach is short of [floor] on either axis, or that a screen reader outlines
/// more than [tolerance] past where a tap reaches, is named, with what stops
/// the tap (the parent whose edge it is, or the neighbour a tap there goes to).
/// A node partly off the screen, or past a clip round it, is not read. A part a
/// scroll view's edge cuts (a chip scrolled half out of its row) is read by
/// what shows: along the cut, the sliver at the edge is scrolling, not a short
/// target; across it, the floor holds. A part whose taps a larger control round
/// it takes (a clock dial's hours) is that control's. A link inside a sentence
/// (a [TextSpan] with a recognizer among other words, or a target in a
/// [WidgetSpan] of a paragraph that lays out other words) cannot grow its
/// line, and WCAG 2.2's 2.5.8 exempts it; a link that is the whole of its text
/// is held to the floor.
///
/// A text field is reached where a press ends in it, as a real press
/// resolves: on its line of words; on its ground, a handler behind the line
/// that reports to the field's node and has none of its own (a seat that
/// focuses the field on a press above or below the words); and on a key
/// whose node is the field's own child (a clear, reveal or send key at its
/// end), as Material's field with a suffix key is. The key's own target is
/// held to the floor on its own; a key beside the field, with a node that is
/// not the field's, is not the field's reach.
///
/// A test pumps a screen, then:
///
/// ```dart
/// const DesignTapTargetCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
///
/// A phone's screen is read for a finger, a desk's for a pointer:
///
/// ```dart
/// const DesignTapTargetCheck(look: 'Comic', input: RawInput.pointer)
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
///
/// See also:
///
///  * [RawTapTargets], the floors a look declares.
///  * [TapTargetPadding], which lays a control out at its floor, so the
///    check holds.
///
/// It reads the semantics tree and hit tests the layout, and no pixels.
@immutable
class DesignTapTargetCheck {
  /// A check for [look].
  const DesignTapTargetCheck({
    required this.look,
    this.input,
    this.floor,
    this.tolerance = 1,
  });

  /// The look's name, for messages.
  final String look;

  /// What reaches the controls; null: the [RawTapTargetScope]'s, else
  /// the platform's ([RawInput.forPlatform]).
  final RawInput? input;

  /// The least area a tap must reach; null: the floor for [input] that the
  /// [RawTapTargetScope] round the screen declares, else
  /// [RawTapTargets.fallback]'s (44 by 44 for a finger, 24 by 24 for a
  /// pointer).
  final Size? floor;

  /// How far, in logical pixels, a reach may fall short of the floor or of
  /// the semantics box.
  final double tolerance;

  /// Checks every live tap target under [context].
  DesignAlignmentReport check(BuildContext context) {
    final targets =
        context.getInheritedWidgetOfExactType<RawTapTargetScope>()?.targets ??
        RawTapTargets.fallback;
    final by = input ?? targets.inputOn();
    return _TapReader(
      look: look,
      input: by,
      floor: floor ?? targets.floorFor(by),
      tolerance: tolerance,
    )._check(context);
  }
}

// [DesignTapTargetCheck] with its input and floor read.
class _TapReader {
  const _TapReader({
    required this.look,
    required this.input,
    required this.floor,
    required this.tolerance,
  });

  final String look;
  final RawInput input;
  final Size floor;
  final double tolerance;

  String get _needs => switch (input) {
    RawInput.touch => 'a finger needs',
    RawInput.pointer => 'a pointer needs',
  };

  DesignAlignmentReport _check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignTapTargetCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final view = View.of(context);
    final viewId = view.viewId;
    final screen = Offset.zero & (view.physicalSize / view.devicePixelRatio);
    final area = _global(root).intersect(screen);
    final found = <String>[];
    for (final (node, rect) in _placedNodes(semantics, view.devicePixelRatio)) {
      // A node merged into its parent is read as the parent.
      if (node.isMergedIntoParent) continue;
      final data = node.getSemanticsData();
      final flags = data.flagsCollection;
      if (flags.isHidden || flags.isEnabled == Tristate.isFalse) continue;
      if (!data.hasAction(SemanticsAction.tap) &&
          !data.hasAction(SemanticsAction.longPress)) {
        continue;
      }
      if (rect.width < 1 || rect.height < 1) continue;
      // Wholly inside the screen read, and inside every clip round it.
      if (!_contains(area, rect)) continue;
      final problem = _read(node, data, rect, viewId);
      if (problem != null) found.add(problem);
    }
    return DesignAlignmentReport(look, found);
  }

  String? _read(SemanticsNode node, SemanticsData data, Rect rect, int viewId) {
    final name = _nodeName(data);
    // What takes a tap at the middle, else at the first spot of a few that
    // reaches anything.
    final probes = [
      rect.center,
      for (final f in const [.25, .75])
        for (final g in const [.25, .5, .75])
          Offset(rect.left + rect.width * f, rect.top + rect.height * g),
    ];
    // What a tap there reaches: a gesture's box, or a link's own words.
    Object? target;
    RenderBox? actor;
    Offset? from;
    for (final p in probes) {
      final path = _pathAt(p, viewId);
      if (_linkIn(path) case (final span, final text)?) {
        // A link in a sentence is set by its line.
        if (_isInline(span, text)) return null;
        (target, actor, from) = (span, text, p);
        break;
      }
      final widest = _widestActorIn(path, rect);
      if (widest != null) {
        // So is a link set as a widget in a sentence (a WidgetSpan, which
        // keeps focus and state layers).
        if (_inSentence(widest)) return null;
        (target, actor, from) = (widest, widest, p);
        break;
      }
    }
    if (actor == null || from == null) {
      // A part of a larger control that takes the tap for it (a clock
      // dial's hours, a list row's own selection): the larger one's.
      for (final p in probes) {
        final round = _actorIn(_pathAt(p, viewId));
        if (round != null && _contains(_global(round).inflate(.5), rect)) {
          return null;
        }
      }
      return '$name: nothing takes a tap anywhere in the box a screen reader '
          'outlines (${_size(rect.size)}): a finger\'s tap does nothing';
    }
    if (!_isClipFree(actor, rect)) return null;
    final own = actor;
    final field = data.flagsCollection.isTextField;
    bool reaches(Offset p) {
      final path = _pathAt(p, viewId);
      if (path.any((e) => identical(e.target, target))) return true;
      // A field's ground takes a press off its words for it (a seat behind
      // the line that focuses the field), and a key in its node is part of
      // it: the press reaches the field.
      return field && _isGroundOf(_actorIn(path), own, node, rect);
    }

    // How far a tap reaches from [from] towards each side, a pixel at a
    // time, up to the floor's or the box's reach past its edge.
    double reach(Offset step, double most) {
      var d = 0.0;
      while (d < most) {
        final next = d + 1;
        if (!reaches(from! + step * next)) break;
        d = next;
      }
      return d;
    }

    // As far past each edge as the whole shortfall: a face aligned in its
    // reach has all its room on one side.
    final padX = math.max(0.0, floor.width - rect.width) + 2;
    final padY = math.max(0.0, floor.height - rect.height) + 2;
    final left = reach(const Offset(-1, 0), from.dx - rect.left + padX);
    final right = reach(const Offset(1, 0), rect.right - from.dx + padX);
    final up = reach(const Offset(0, -1), from.dy - rect.top + padY);
    final down = reach(const Offset(0, 1), rect.bottom - from.dy + padY);
    final reached = Rect.fromLTRB(
      from.dx - left - .5,
      from.dy - up - .5,
      from.dx + right + .5,
      from.dy + down + .5,
    );
    final short = <String>[];
    // A part a scroll view's edge cuts is read by what shows: the sliver
    // left at the edge is scrolling, not a target, along the cut.
    final cut = _scrollCut(actor);
    final shortWide = reached.width < floor.width - tolerance && !cut.across;
    final shortHigh = reached.height < floor.height - tolerance && !cut.down;
    final outlinesMore = [
      if (rect.left < reached.left - tolerance) 'left',
      if (rect.top < reached.top - tolerance) 'top',
      if (rect.right > reached.right + tolerance) 'right',
      if (rect.bottom > reached.bottom + tolerance) 'bottom',
    ];
    if (!shortWide && !shortHigh && outlinesMore.isEmpty) return null;
    if (shortWide || shortHigh) {
      short.add(
        'a tap reaches it over ${_size(reached.size)}, under the '
        '${_size(floor)} $_needs',
      );
      if (outlinesMore.isNotEmpty) {
        short.add(
          'a screen reader outlines ${_size(rect.size)}, past where a tap '
          'reaches at its ${outlinesMore.join(' and ')}, so the tap-target '
          'guidelines pass a target a finger does not have',
        );
      }
    } else {
      short.add(
        'a screen reader outlines ${_size(rect.size)}, past where a tap '
        'reaches (${_size(reached.size)}) at its '
        '${outlinesMore.join(' and ')}: the box a screen reader outlines is '
        'the box a tap reaches',
      );
    }
    final why = _stopper(actor, reached, rect, viewId);
    return '$name: ${short.join('; ')}${why == null ? '' : ' ($why)'}';
  }

  // Whether nothing clips [actor] inside [rect]'s reach: a control a clip
  // round it cuts is the clip check's ([DesignClipCheck]).
  static bool _isClipFree(RenderBox actor, Rect rect) {
    final clip = _clipOf(actor, throughScrolls: true);
    return clip == null || _contains(clip.inflate(.5), rect);
  }

  // What stops a tap at [reached]'s edge: the box above [actor] whose own
  // edge it is, or the control a tap past it goes to.
  String? _stopper(RenderBox actor, Rect reached, Rect outlined, int viewId) {
    for (final (side, spot) in [
      ('left', Offset(reached.left - 1, reached.center.dy)),
      ('right', Offset(reached.right + 1, reached.center.dy)),
      ('top', Offset(reached.center.dx, reached.top - 1)),
      ('bottom', Offset(reached.center.dx, reached.bottom + 1)),
    ]) {
      if (!outlined.inflate(floor.longestSide).contains(spot)) continue;
      final other = _actorIn(_pathAt(spot, viewId));
      // A gesture round the control too (a page's tap that closes the
      // keyboard) is no neighbour.
      if (other != null &&
          !identical(other, actor) &&
          !_isWithin(actor, other) &&
          !_isWithin(other, actor)) {
        return 'a tap past its $side goes to ${_nameOf(_controlRound(other))}';
      }
    }
    for (RenderObject? up = actor.parent; up != null; up = up.parent) {
      if (up is! RenderBox || !up.hasSize) continue;
      final box = _global(up);
      if (box.width + tolerance < outlined.width ||
          box.height + tolerance < outlined.height) {
        return 'a box round it ${_size(box.size)} stops taps at its own '
            'edge: hit testing reaches a child only inside its parent';
      }
      if (_contains(box.inflate(tolerance), outlined)) break;
    }
    return null;
  }
}

// Whether [other], the first thing a press acts on, is part of the text
// field [node] whose own gesture is [own]: its ground, a handler that
// reports to the field's node and has none of its own (a seat behind the
// line that focuses the field on a press off its words), or a key whose
// node lies in the field's (a clear or reveal key at its end). Outside a
// debug build, where the semantics tree is not mapped to the render tree,
// by structure: [other] meets the field's own ancestors at a box that lies
// in the field's ([outlined]).
bool _isGroundOf(
  RenderBox? other,
  RenderBox own,
  SemanticsNode node,
  Rect outlined,
) {
  if (other == null) return false;
  if (identical(other, own)) return true;
  SemanticsNode? reportsTo;
  for (RenderObject? up = other; up != null; up = up.parent) {
    reportsTo = up.debugSemantics;
    if (reportsTo != null) break;
  }
  if (reportsTo != null) {
    for (SemanticsNode? up = reportsTo; up != null; up = up.parent) {
      if (identical(up, node)) return true;
    }
    return false;
  }
  final mine = <RenderObject>{};
  for (RenderObject? up = own; up != null; up = up.parent) {
    mine.add(up);
  }
  for (RenderObject? up = other; up != null; up = up.parent) {
    if (mine.contains(up)) {
      return up is RenderBox &&
          up.hasSize &&
          _contains(outlined.inflate(1), _global(up));
    }
  }
  return false;
}

// The link [path] reaches, if any: the span with a recognizer a tap there
// lands on, and the text it is set in.
(TextSpan, RenderParagraph)? _linkIn(List<HitTestEntry> path) {
  for (var i = 0; i < path.length; i++) {
    final span = path[i].target;
    if (span is! TextSpan || span.recognizer == null) continue;
    for (var j = i + 1; j < path.length; j++) {
      if (path[j].target case final RenderParagraph text) return (span, text);
    }
  }
  return null;
}

// Whether [span] is a link inside a sentence: [text] says more than it.
bool _isInline(TextSpan span, RenderParagraph text) {
  String words(InlineSpan s) => s
      .toPlainText(includeSemanticsLabels: false, includePlaceholders: false)
      .trim();
  return words(text.text).length > words(span).length;
}

// Whether [box] stands in a sentence: in a WidgetSpan of a paragraph that
// lays out words besides it. A paragraph's only children are its
// WidgetSpans', so a paragraph round [box] holds it in one.
bool _inSentence(RenderBox box) {
  for (RenderObject? up = box.parent; up != null; up = up.parent) {
    if (up is RenderParagraph) {
      return up.text
          .toPlainText(
            includeSemanticsLabels: false,
            includePlaceholders: false,
          )
          .trim()
          .isNotEmpty;
    }
  }
  return false;
}

// Of what takes a pointer down in [path], the widest that is still this
// control's (a text field's own gesture round its line of text, not a
// page's round everything): what a tap there reaches. Each is read by what
// shows of it ([_shown]), as the node's box is: a chip scrolled half out of
// its row is the slice that shows.
RenderBox? _widestActorIn(List<HitTestEntry> path, Rect node) {
  RenderBox? widest;
  var area = -1.0;
  final near = node.inflate(48);
  for (final entry in path) {
    final t = entry.target;
    final acts =
        t is RenderEditable || (t is RenderPointerListener && _isGestureOf(t));
    if (!acts || t is! RenderBox || !t.hasSize) continue;
    final r = _shown(t);
    if (r.width <= 0 || r.height <= 0 || !_contains(near, r)) continue;
    final a = r.width * r.height;
    if (a > area) {
      area = a;
      widest = t;
    }
  }
  return widest;
}

// What shows of [box] on the screen: its box inside every scroll view
// round it.
Rect _shown(RenderBox box) {
  var shown = _global(box);
  for (RenderObject? up = box.parent; up != null; up = up.parent) {
    if (up case final RenderBox port
        when port is RenderAbstractViewport && port.hasSize) {
      shown = shown.intersect(_global(port));
    }
  }
  return shown;
}

// Whether a scroll view's edge cuts [box] across (at its left or right) or
// down (at its top or bottom).
({bool across, bool down}) _scrollCut(RenderBox box) {
  final own = _global(box);
  final shown = _shown(box);
  return (
    across: shown.left > own.left + .5 || shown.right < own.right - .5,
    down: shown.top > own.top + .5 || shown.bottom < own.bottom - .5,
  );
}

// The control [node] is part of: the nearest box above it that is one.
RenderBox _controlRound(RenderBox node) {
  for (RenderObject? up = node; up != null; up = up.parent) {
    if (up is RenderBox && _isControl(up)) return up;
  }
  return node;
}

// A node's role and words, as a screen reader would name it.
String _nodeName(SemanticsData d) {
  final f = d.flagsCollection;
  final role = f.isTextField
      ? 'a text field'
      : d.hasAction(SemanticsAction.increase) ||
            d.hasAction(SemanticsAction.decrease)
      ? 'a slider'
      : f.isLink
      ? 'a link'
      : f.isToggled != Tristate.none
      ? 'a switch'
      : f.isChecked != CheckedState.none
      ? 'a checkbox'
      : f.isButton
      ? 'a button'
      : 'a tap target';
  final words = [
    d.label,
    d.value,
    d.tooltip,
  ].where((w) => w.isNotEmpty).join(', ').replaceAll('\n', ' ');
  if (words.isEmpty) return role;
  return '$role "${words.length > 32 ? '${words.substring(0, 31)}…' : words}"';
}

// Every semantics node under [root] with its box on the screen, in logical
// pixels: the root's transform scales by [ratio].
List<(SemanticsNode, Rect)> _placedNodes(SemanticsNode root, double ratio) {
  final placed = <(SemanticsNode, Rect)>[];
  void visit(SemanticsNode node, Matrix4 above) {
    final at = above.clone();
    if (node.transform != null) at.multiply(node.transform!);
    final rect = MatrixUtils.transformRect(at, node.rect);
    placed.add((
      node,
      Rect.fromLTRB(
        rect.left / ratio,
        rect.top / ratio,
        rect.right / ratio,
        rect.bottom / ratio,
      ),
    ));
    node.visitChildren((child) {
      visit(child, at);
      return true;
    });
  }

  visit(root, Matrix4.identity());
  return placed;
}
