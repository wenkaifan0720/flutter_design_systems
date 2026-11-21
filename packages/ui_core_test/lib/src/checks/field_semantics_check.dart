part of '../alignment.dart';

/// Whether each control inside a [RawInputDecorator] takes a tap through the
/// semantics tree, and whether the field's label is read once.
///
/// A screen reader's double tap, and a click on the web while semantics
/// run, go to the node under the point that takes a tap (as
/// [SemanticsOwner.performActionAt] finds it), not to what a pointer would
/// hit there. A field that makes one node of several controls leaves all
/// but one of them out of reach, and says its label beside a control that
/// already says it.
///
/// - **A node for each control**: two controls of one field (segmented
///   buttons, chips, radios, a stepper's buttons with nodes of their own)
///   never come to one node: `a field "Priority": a button "Low" and a
///   button "High" are one node, so a tap through the semantics tree
///   reaches one of them`.
/// - **A stepper's buttons**: a button of a stepper (a node that steps a
///   value and takes no tap itself; a date's segment that does is one
///   control) that takes a pointer's press and no tap through the semantics
///   tree of its own (the stepper's node steps instead) lies under no node
///   that takes a tap, which would take it in the button's place: `a field
///   "Estimate": a tap through the semantics tree on its stepper's button on
///   the right lands on "Estimate", not on the button`.
/// - **The label read once**: the field's label is a line of no more than
///   one of the nodes over the field, a button's own name aside (a search
///   field's Search button): `a field "Estimate": its label is read 2
///   times`.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on). A test pumps a screen,
/// then:
///
/// ```dart
/// const DesignFieldSemanticsCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignFieldSemanticsCheck {
  /// A check for [look].
  const DesignFieldSemanticsCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every [RawInputDecorator] shown under [context].
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || !root.attached) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignFieldSemanticsCheck reads the semantics tree: turn semantics '
        'on (a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final view = View.of(context);
    final fields = <(RawInputDecorator, RenderBox)>[];
    void find(Element e) {
      if (e.widget case final RawInputDecorator field) {
        final box = e.renderObject;
        if (box is RenderBox && box.attached && box.hasSize && _isShown(box)) {
          fields.add((field, box));
        }
      }
      e.visitChildren(find);
    }

    find(context as Element);
    final placed = _placedNodes(semantics, view.devicePixelRatio);
    return DesignAlignmentReport(look, [
      for (final (field, box) in fields)
        ..._FieldSemanticsReader(
          field,
          box,
          semantics,
          placed,
          view.devicePixelRatio,
          view.viewId,
        ).read(),
    ]);
  }
}

// Reads one field.
class _FieldSemanticsReader {
  _FieldSemanticsReader(
    this.field,
    this.box,
    this.root,
    this.placed,
    this.ratio,
    this.viewId,
  );

  final RawInputDecorator field;
  final RenderBox box;
  final SemanticsNode root;
  final List<(SemanticsNode, Rect)> placed;
  final double ratio;
  final int viewId;

  // The controls that take a tap through the semantics tree, each holding
  // no other.
  final List<RenderBox> _taps = [];

  // Each stepper's buttons that take a pointer's press and no tap through
  // the semantics tree of their own.
  final List<(RenderBox, RenderBox)> _presses = [];

  late final String _name = switch (field.labelText) {
    final label? when label.trim().isNotEmpty => 'a field "${label.trim()}"',
    _ => 'a field (${_nameOf(box)})',
  };

  List<String> read() {
    _walk(box, excluded: false);
    final found = <String>[];
    final byNode = <SemanticsNode, List<RenderBox>>{};
    for (final control in _taps) {
      final node = _takerAt(root, _global(control).center * ratio);
      if (node != null) (byNode[node] ??= []).add(control);
    }
    for (final controls in byNode.values) {
      if (controls.length < 2) continue;
      final names = [for (final c in controls) _say(c)];
      final listed = names.length == 2
          ? '${names[0]} and ${names[1]}'
          : '${names.sublist(0, names.length - 1).join(', ')} and '
                '${names.last}';
      found.add(
        '$_name: $listed are one node, so a tap through the semantics tree '
        'reaches one of them',
      );
    }
    for (final (stepper, button) in _presses) {
      final at = _global(button).center;
      final hit = HitTestResult();
      RendererBinding.instance.hitTestInView(hit, at, viewId);
      if (!hit.path.any((e) => e.target == button)) continue;
      final node = _takerAt(root, at * ratio);
      if (node == null) continue;
      final side = at.dx < _global(stepper).center.dx ? 'left' : 'right';
      final label = node.getSemanticsData().label.split('\n').first.trim();
      found.add(
        '$_name: a tap through the semantics tree on its stepper\'s button '
        'on the $side lands on ${label.isEmpty ? 'another node' : '"$label"'}, '
        'not on the button',
      );
    }
    final words = field.labelText?.trim().toLowerCase() ?? '';
    if (words.isNotEmpty) {
      final area = _global(box).inflate(1);
      var heard = 0;
      for (final (node, rect) in placed) {
        if (node.isMergedIntoParent || !area.contains(rect.center)) continue;
        final data = node.getSemanticsData();
        // A button's own name is the button's (a search field's Search),
        // not a reading of the field's label; a node that merges several
        // says each one's words on a line of its own, and is read by them.
        if (data.flagsCollection.isButton && !data.label.contains('\n')) {
          continue;
        }
        for (final line in data.label.split('\n')) {
          final l = line.trim().toLowerCase();
          if (l == words || l.startsWith('$words,')) heard++;
        }
      }
      if (heard > 1) found.add('$_name: its label is read $heard times');
    }
    return found;
  }

  // Walks [n], noting the controls; whether [n] holds one.
  bool _walk(RenderObject n, {required bool excluded}) {
    final out = excluded || (n is RenderExcludeSemantics && n.excluding);
    final below =
        out || (n is RenderSemanticsAnnotations && n.excludeSemantics);
    var holds = false;
    _visitShown(n, (c) => holds = _walk(c, excluded: below) || holds);
    final takes = !out && (n is RenderEditable || _takesTap(n));
    if (takes && !holds && n is RenderBox && n.hasSize) _taps.add(n);
    // A stepper's buttons that take a press alone; a stepper node that takes
    // a tap itself (a date's segment) is one control with what presses it.
    if (!out &&
        n is RenderSemanticsAnnotations &&
        (n.properties.onIncrease != null || n.properties.onDecrease != null) &&
        !_takesTap(n)) {
      _visitShown(n, (c) => _press(n, c, excluded: below));
    }
    return takes || holds;
  }

  // Notes the stepper's buttons under [n] that take a press alone.
  void _press(RenderBox stepper, RenderObject n, {required bool excluded}) {
    final out = excluded || (n is RenderExcludeSemantics && n.excluding);
    if (!out && (n is RenderEditable || _takesTap(n))) return;
    if (n is RenderPointerListener &&
        n.onPointerDown != null &&
        n.hasSize &&
        !_holdsEntry(n)) {
      _presses.add((stepper, n));
      return;
    }
    final below =
        out || (n is RenderSemanticsAnnotations && n.excludeSemantics);
    _visitShown(n, (c) => _press(stepper, c, excluded: below));
  }

  static bool _holdsEntry(RenderObject n) {
    if (n is RenderEditable) return true;
    var found = false;
    n.visitChildren((c) => found = found || _holdsEntry(c));
    return found;
  }

  static bool _takesTap(RenderObject n) => switch (n) {
    RenderSemanticsGestureHandler(:final onTap, :final onLongPress) =>
      onTap != null || onLongPress != null,
    RenderSemanticsAnnotations(:final properties) =>
      properties.onTap != null || properties.onLongPress != null,
    _ => false,
  };

  // The control's name: the label of the nearest node round it that has
  // one, inside the field.
  String _say(RenderBox control) {
    for (RenderObject? up = control; up != null && up != box; up = up.parent) {
      if (up is RenderSemanticsAnnotations &&
          (up.properties.label?.trim().isNotEmpty ?? false)) {
        return _nameOf(up);
      }
    }
    return _nameOf(control);
  }

  // The node a tap through the semantics tree at [position] (in the root
  // node's space) goes to, as [SemanticsOwner.performActionAt] finds it: the
  // deepest node there that takes a tap, a merged node standing for all it
  // merges.
  static SemanticsNode? _takerAt(SemanticsNode node, Offset position) {
    if (node.transform case final transform?) {
      final inverse = Matrix4.identity();
      if (inverse.copyInverse(transform) == 0) return null;
      position = MatrixUtils.transformPoint(inverse, position);
    }
    if (!node.rect.contains(position)) return null;
    final taps = node.getSemanticsData().hasAction(SemanticsAction.tap);
    if (node.mergeAllDescendantsIntoThisNode) return taps ? node : null;
    final children = <SemanticsNode>[];
    node.visitChildren((child) {
      children.add(child);
      return true;
    });
    for (final child in children.reversed) {
      final found = _takerAt(child, position);
      if (found != null) return found;
    }
    return taps ? node : null;
  }
}
