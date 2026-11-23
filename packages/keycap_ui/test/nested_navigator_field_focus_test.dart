// A list opening over a page in a Navigator that an app puts in the
// scaffold's body keeps every semantics node above the field that opened it.
// On the web with semantics on, the engine moves a node's element when the
// node gets a new parent, and a browser blurs a focused input it moves: if
// the route gained a node when the list opened, the tap that focused the
// field would lose its focus a frame later and the list would close.
import 'dart:ui' show Tristate;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart'
    show DefaultMaterialLocalizations, MaterialApp;

const _label = 'Assignee';

Widget _app() => MaterialApp(
  localizationsDelegates: const [
    RawWidgetsLocalizations.delegate,
    DefaultMaterialLocalizations.delegate,
    DefaultWidgetsLocalizations.delegate,
  ],
  builder: (context, app) =>
      KeycapHost(brightness: Brightness.light, child: app!),
  home: KeycapScaffold(
    destinations: const [
      KeycapDestination(icon: LucideIcons.house, label: 'Home'),
      KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
    ],
    selectedIndex: 0,
    onDestinationSelected: (_) {},
    body: Navigator(
      onGenerateRoute: (settings) => PageRouteBuilder<void>(
        settings: settings,
        pageBuilder: (context, _, _) => Padding(
          padding: const EdgeInsets.all(24),
          child: Align(
            alignment: Alignment.topCenter,
            child: KeycapCombobox<String>(
              labelText: _label,
              options: const ['Ana', 'Ben', 'Chloe'],
              onSelected: (_) {},
            ),
          ),
        ),
      ),
    ),
  ),
);

void main() {
  for (final width in const [390.0, 1440.0]) {
    testWidgets('a combobox in a nested Navigator keeps the nodes above its '
        'field when its list opens, at ${width.toInt()}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 900);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_app());
      await tester.pumpAndSettle();
      final before = _fieldPath()!;
      await tester.tapAt(_centre(before));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Ben'), findsOneWidget, reason: 'the list is open');
      final after = _fieldPath()!;
      expect(
        after.last.getSemanticsData().flagsCollection.isFocused,
        Tristate.isTrue,
      );
      expect([for (final n in after) n.id], [for (final n in before) n.id]);
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      semantics.dispose();
    });
  }
}

/// The nodes from the root to the text field named [_label].
List<SemanticsNode>? _fieldPath() {
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
    if (data.flagsCollection.isTextField && data.label.contains(_label)) {
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
