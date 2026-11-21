part of '../alignment.dart';

/// Whether each text field keeps its semantics nodes as its text changes:
/// its text entry is the same node, and every node it had is still there,
/// in its role, after the first letter (a clear key that shows then is a
/// node added beside them).
///
/// On the web a text field's node is the browser's input. A field whose
/// entry moves to another node as its text changes (one node merging the
/// entry, then a group with the entry apart once a clear key joins) gets a
/// new input on the first key, and the keys typed while it is made are lost
/// while the field still looks focused. A screen reader on any platform
/// loses its place.
///
/// - **The same entry**: `a field "Search tasks": its text entry moved from
///   node #4 to node #5 as its text changed`.
/// - **The same nodes**: `a field "Search tasks": node #4, a text entry,
///   is now a group`.
///
/// It reads the semantics tree, which a widget test has unless it turns it
/// off ([WidgetTester.ensureSemantics] turns it on), and maps it to the
/// fields' boxes as a debug build does. A test reads the fields, types,
/// then checks them:
///
/// ```dart
/// const check = DesignFieldNodesCheck(look: 'Comic');
/// final empty = check.read(tester.element(find.byType(TaskList)));
/// await tester.enterText(find.byType(EditableText), 'p');
/// await tester.pump();
/// check.check(empty, tester.element(find.byType(TaskList))).verify();
/// ```
@immutable
class DesignFieldNodesCheck {
  /// A check for [look].
  const DesignFieldNodesCheck({required this.look});

  /// The look's name, for messages.
  final String look;

  /// The nodes of every text field's [RawInputDecorator] shown under
  /// [context], for [check] to compare.
  DesignFieldNodes read(BuildContext context) {
    final root = context.findRenderObject();
    if (root == null ||
        root.owner?.semanticsOwner == null ||
        !SemanticsBinding.instance.semanticsEnabled) {
      throw StateError(
        'DesignFieldNodesCheck reads the semantics tree: turn semantics on '
        '(a widget test has them unless semanticsEnabled is false; '
        'tester.ensureSemantics() turns them on).',
      );
    }
    final fields = <Element, _FieldNodes>{};
    void find(Element e) {
      if (e.widget is RawInputDecorator) {
        if (_fieldNodesOf(e) case final nodes?) fields[e] = nodes;
      }
      e.visitChildren(find);
    }

    find(context as Element);
    return DesignFieldNodes._(fields);
  }

  /// Checks the fields read in [before] against them as they are now
  /// under [context].
  DesignAlignmentReport check(DesignFieldNodes before, BuildContext context) {
    final now = read(context)._fields;
    final problems = <String>[];
    for (final MapEntry(key: field, value: was) in before._fields.entries) {
      final after = now[field];
      if (after == null) continue;
      final name = was.name;
      if (after.entry != was.entry) {
        problems.add(
          '$name: its text entry moved from node #${was.entry} to node '
          '#${after.entry} as its text changed: on the web that is a new '
          'input, and the keys typed meanwhile are lost',
        );
      }
      for (final MapEntry(key: id, value: role) in was.nodes.entries) {
        final nowRole = after.nodes[id];
        if (nowRole == role) continue;
        problems.add(
          nowRole == null
              ? '$name: node #$id, $role, is gone'
              : '$name: node #$id, $role, is now $nowRole',
        );
      }
    }
    return DesignAlignmentReport(look, problems);
  }
}

/// The semantics nodes of the text fields under a screen, as
/// [DesignFieldNodesCheck.read] found them.
@immutable
class DesignFieldNodes {
  const DesignFieldNodes._(this._fields);

  final Map<Element, _FieldNodes> _fields;

  /// How many text fields were read.
  int get length => _fields.length;
}

// One field's nodes: its entry's node and every node from the field's own
// down, each with its role, and the field's name for messages.
typedef _FieldNodes = ({int entry, Map<int, String> nodes, String name});

// The nodes of the field [e] builds, if it holds a text entry and is shown.
_FieldNodes? _fieldNodesOf(Element e) {
  final box = e.renderObject;
  if (box is! RenderBox || !box.attached || !box.hasSize || !_isShown(box)) {
    return null;
  }
  RenderEditable? editable;
  void findEntry(RenderObject r) {
    if (editable != null) return;
    if (r is RenderEditable) {
      editable = r;
      return;
    }
    r.visitChildren(findEntry);
  }

  findEntry(box);
  final entry = editable;
  if (entry == null) return null;
  SemanticsNode? nodeOf(RenderObject r) {
    for (RenderObject? up = r; up != null; up = up.parent) {
      final own = up.debugSemantics;
      if (own == null) continue;
      // A node merged into another is read as the one it merges into.
      var node = own;
      while (node.isMergedIntoParent) {
        final parent = node.parent;
        if (parent == null) break;
        node = parent;
      }
      return node;
    }
    return null;
  }

  final entryNode = nodeOf(entry);
  final fieldNode = nodeOf(box);
  if (entryNode == null || fieldNode == null) return null;
  final nodes = <int, String>{};
  void visit(SemanticsNode n) {
    if (n.isMergedIntoParent) return;
    nodes[n.id] = _nodeRole(n.getSemanticsData());
    n.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(fieldNode);
  final label = (e.widget as RawInputDecorator).labelText?.trim() ?? '';
  return (
    entry: entryNode.id,
    nodes: nodes,
    name: label.isEmpty ? 'a field (${_nameOf(box)})' : 'a field "$label"',
  );
}

// A node's role, for a message.
String _nodeRole(SemanticsData d) {
  final f = d.flagsCollection;
  if (f.isTextField) return 'a text entry';
  if (_actsNode(d)) return 'a control';
  return 'a group';
}
