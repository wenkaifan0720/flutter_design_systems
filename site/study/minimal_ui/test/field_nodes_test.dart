import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stint_minimal/stint_minimal.dart';
import 'package:stint_core/stint_core.dart';

// On the web with semantics on, the engine moves a node's element when the
// node gets a new parent, and a browser blurs a focused input it moves: the
// tap that focused Project or Assignee loses the focus a frame later and the
// list never stays open. So a tap that opens a field's list keeps every node
// above the field's own: none comes, none goes.
void main() {
  for (final width in const [390.0, 1440.0]) {
    for (final label in const ['Project', 'Assignee']) {
      testWidgets('a tap on $label at $width keeps the nodes above its field', (
        tester,
      ) async {
        final semantics = tester.ensureSemantics();
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        tester.view.physicalSize = Size(width, 900);
        await tester.pumpWidget(
          StintMinimal(
            launch: const StintLaunch(place: Place.tasks, detail: true),
            repository: StintRepository(),
          ),
        );
        await tester.pumpAndSettle();
        final before = _fieldPath(label);
        if (before == null) {
          markTestSkipped('no text field named $label');
          semantics.dispose();
          return;
        }
        await tester.tapAt(_centre(before));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        final after = _fieldPath(label)!;
        expect(
          after.last.getSemanticsData().flagsCollection.isFocused,
          Tristate.isTrue,
        );
        expect([for (final n in after) n.id], [for (final n in before) n.id]);
        semantics.dispose();
      });
    }
  }
}

// The nodes from the root to the text field named [label].
List<SemanticsNode>? _fieldPath(String label) {
  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  List<SemanticsNode>? found;
  bool walk(SemanticsNode node, List<SemanticsNode> above) {
    final here = [...above, node];
    final data = node.getSemanticsData();
    if (data.label == label && data.flagsCollection.isTextField) {
      found = here;
      return false;
    }
    var go = true;
    node.visitChildren((child) => go = go && walk(child, here));
    return go;
  }

  walk(root, const []);
  return found;
}

Offset _centre(List<SemanticsNode> path) {
  final m = Matrix4.identity();
  for (final node in path) {
    if (node.transform != null) m.multiply(node.transform!);
  }
  return MatrixUtils.transformRect(m, path.last.rect).center;
}
