part of '../alignment.dart';

/// Whether each control a screen shows keeps a node of its own that a
/// screen reader reaches: a row's trailing control (a "more" button, a
/// menu) merged into the row's node is reached by no tap through the
/// semantics tree, and the row's own tap runs in its place.
///
/// - **A node for each control**: two controls that come to one node are
///   named: `a button "More for Stoner" and a button "Stoner" are one node,
///   so a tap through the semantics tree reaches one of them`. A checkbox,
///   a radio or a switch merged into its row (a check row) is one control
///   with the row, as Flutter's `CheckboxListTile` is, and passes; so does
///   a field's own group, which [DesignFieldSemanticsCheck] reads, and a
///   control another covers where it stands (a list's row scrolled under a
///   floating button), whose tap there is the cover's.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on). A test pumps a screen
/// (a list of rows, a settings page), then:
///
/// ```dart
/// const DesignControlNodesCheck(look: 'Comic')
///     .check(tester.element(find.byType(SettingsScreen)))
///     .verify();
/// ```
@immutable
class DesignControlNodesCheck {
  /// A check for [look].
  const DesignControlNodesCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks every control shown under [context].
  DesignAlignmentReport check(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null || root is! RenderBox || !root.hasSize) {
      return DesignAlignmentReport(look, const []);
    }
    final semantics = root.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignControlNodesCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final ratio = View.of(context).devicePixelRatio;
    // The fields' boxes: their controls are their check's.
    final fields = <RenderObject>{};
    void find(Element e) {
      if (e.widget is RawInputDecorator && e.renderObject != null) {
        fields.add(e.renderObject!);
      }
      e.visitChildren(find);
    }

    find(context as Element);
    final controls = <RenderBox>[];
    // Walks [n], noting the controls that hold no other; whether [n] holds
    // one.
    bool walk(RenderObject n, {required bool excluded}) {
      final out = excluded || (n is RenderExcludeSemantics && n.excluding);
      final below =
          out || (n is RenderSemanticsAnnotations && n.excludeSemantics);
      if (fields.contains(n)) return false;
      var holds = false;
      _visitShown(n, (c) => holds = walk(c, excluded: below) || holds);
      final takes = !out && _FieldSemanticsReader._takesTap(n);
      if (takes && !holds && n is RenderBox && n.hasSize && _isShown(n)) {
        controls.add(n);
      }
      return takes || holds;
    }

    walk(root, excluded: false);
    final view = View.of(context).viewId;
    final byNode = <SemanticsNode, List<RenderBox>>{};
    for (final control in controls) {
      final center = _global(control).center;
      // Covered where it stands (a list's row scrolled under a floating
      // button): a tap there is the cover's, whatever the nodes.
      if (_covered(control, center, controls, view)) continue;
      final node = _FieldSemanticsReader._takerAt(semantics, center * ratio);
      if (node != null) (byNode[node] ??= []).add(control);
    }
    final found = <String>[];
    for (final group in byNode.values) {
      if (group.length < 2) continue;
      // A check row: a checkbox, a radio or a switch and its row, one
      // control.
      final checks = group.where(_checkable).length;
      if (group.length - checks < 2 && checks <= 1) continue;
      final names = [for (final c in group) _named(c)];
      final listed = names.length == 2
          ? '${names[0]} and ${names[1]}'
          : '${names.sublist(0, names.length - 1).join(', ')} and '
                '${names.last}';
      found.add(
        '$listed are one node, so a tap through the semantics tree reaches '
        'one of them',
      );
    }
    return DesignAlignmentReport(look, found);
  }

  // Whether a pointer at [center] reaches another of [controls], one
  // neither round [control] nor in it, and not [control].
  static bool _covered(
    RenderBox control,
    Offset center,
    List<RenderBox> controls,
    int view,
  ) {
    final result = HitTestResult();
    RendererBinding.instance.hitTestInView(result, center, view);
    final hit = {for (final entry in result.path) entry.target};
    if (hit.contains(control)) return false;
    bool holds(RenderObject outer, RenderObject inner) {
      for (RenderObject? up = inner; up != null; up = up.parent) {
        if (up == outer) return true;
      }
      return false;
    }

    return controls.any(
      (other) =>
          other != control &&
          hit.contains(other) &&
          !holds(other, control) &&
          !holds(control, other),
    );
  }

  // Whether [control] says a checked or toggled state, on the node round it.
  static bool _checkable(RenderBox control) {
    for (RenderObject? up = control; up != null; up = up.parent) {
      if (up is RenderSemanticsAnnotations) {
        final p = up.properties;
        if (p.checked != null || p.toggled != null || p.mixed != null) {
          return true;
        }
        if (p.label?.trim().isNotEmpty ?? false) return false;
      }
    }
    return false;
  }

  // The control's name: the nearest labelled node round it.
  static String _named(RenderBox control) {
    for (RenderObject? up = control; up != null; up = up.parent) {
      if (up is RenderSemanticsAnnotations &&
          (up.properties.label?.trim().isNotEmpty ?? false)) {
        return _nameOf(up);
      }
    }
    return _nameOf(control);
  }
}

/// Whether a screen's navigation (a bar's, a rail's or a sidebar's
/// destinations) stays in the semantics tree, each a node that takes a
/// tap, with a page pushed over the body beside it.
///
/// A page pushed in a navigator blocks what was painted before it in the
/// same semantics container (its route's barrier says so), so a rail or a
/// sidebar painted before a body's navigator drops out of what a screen
/// reader reaches while a page is open, though it shows: `the destination
/// "Mail" is not in the semantics tree with a page pushed`. A shell built on
/// `RawAdaptiveShell` keeps it.
///
/// A test pumps the app, pushes a page in the body, then:
///
/// ```dart
/// const DesignNavigationCheck(look: 'Comic')
///     .check(tester.element(find.byType(App)), destinations: ['Home', 'Mail'])
///     .verify();
/// ```
@immutable
class DesignNavigationCheck {
  /// A check for [look].
  const DesignNavigationCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// Checks that each of [destinations] (their labels, as the navigation
  /// says them) is a node under [context] that takes a tap.
  DesignAlignmentReport check(
    BuildContext context, {
    required List<String> destinations,
  }) {
    final root = context.findRenderObject();
    final semantics = root?.owner?.semanticsOwner?.rootSemanticsNode;
    if (semantics == null || !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignNavigationCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final heard = <String, bool>{};
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      final taps = data.hasAction(SemanticsAction.tap);
      for (final line in data.label.split('\n')) {
        final l = line.trim();
        if (destinations.contains(l)) heard[l] = (heard[l] ?? false) || taps;
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(semantics);
    return DesignAlignmentReport(look, [
      for (final d in destinations)
        if (!heard.containsKey(d))
          'the destination "$d" is not in the semantics tree with a page '
              'pushed'
        else if (!heard[d]!)
          'the destination "$d" takes no tap through the semantics tree',
    ]);
  }
}
