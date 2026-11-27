// A Navigator in an ApplianceScaffold's body (a router's shell, a list and
// the detail pushed over it) keeps its routes' semantics nodes when a list
// opens over a pushed page: a tap on a combobox's field focuses it, and no
// node comes or goes above the field. On the web with semantics on, a node
// that gains a new parent moves its element in the page, and the browser
// blurs a focused input it moves, so the tap's focus would be lost.
import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:appliance_ui/appliance_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

void main() {
  setUpAll(applianceLoadFonts);
  for (final width in const [390.0, 1440.0]) {
    testWidgets('a tap on a combobox on a pushed page at $width keeps the '
        'nodes above its field', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, app) =>
              ApplianceHost(brightness: Brightness.light, child: app!),
          home: ApplianceScaffold(
            destinations: const [
              ApplianceDestination(icon: LucideIcons.house, label: 'Home'),
              ApplianceDestination(icon: LucideIcons.listTodo, label: 'Tasks'),
            ],
            selectedIndex: 1,
            onSelected: (_) {},
            body: Navigator(
              key: navigator,
              onGenerateRoute: (settings) => PageRouteBuilder<void>(
                settings: settings,
                pageBuilder: (context, animation, secondary) =>
                    const ApplianceScreen(body: Text('Tasks')),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      unawaited(
        navigator.currentState!.push(
          PageRouteBuilder<void>(
            pageBuilder: (context, animation, secondary) =>
                const ApplianceScreen(
                  body: ApplianceCombobox<String>(
                    labelText: 'Assignee',
                    options: ['Ada Brook', 'Sam Lee'],
                  ),
                ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final before = _fieldPath('Assignee')!;
      await tester.tapAt(_centre(before));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final after = _fieldPath('Assignee')!;
      expect(
        after.last.getSemanticsData().flagsCollection.isFocused,
        Tristate.isTrue,
      );
      expect([for (final n in after) n.id], [for (final n in before) n.id]);
      semantics.dispose();
    });
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

// The centre of the last node of [path], in the view's coordinates.
Offset _centre(List<SemanticsNode> path) {
  final m = Matrix4.identity();
  for (final node in path) {
    if (node.transform != null) m.multiply(node.transform!);
  }
  return MatrixUtils.transformRect(m, path.last.rect).center;
}
