// On a page of CivicAppShell, on ui_core's RawAdaptiveShell, under the look's host, a heading and the
// words after it read as two nodes, the heading flagged as a header: the keys
// set round the app and its panes (F6 between panes) add no node of their own
// for the two to merge into.
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

// The deepest node whose label holds [words].
SemanticsNode _node(String words) {
  final root = RendererBinding
      .instance
      .renderViews
      .first
      .owner!
      .semanticsOwner!
      .rootSemanticsNode!;
  SemanticsNode? found;
  void visit(SemanticsNode node) {
    if (node.label.toLowerCase().contains(words.toLowerCase())) found = node;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found!;
}

void main() {
  for (final (name, heading) in [
    (
      'the look\'s section header',
      const CivicSectionHeader(title: 'Tide tables'),
    ),
    (
      'a header the app marks',
      Semantics(header: true, child: const Text('Tide tables')),
    ),
  ]) {
    testWidgets('$name and the words after it read as two nodes', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                CivicHost(theme: CivicThemeData.light(), child: child!),
            home: CivicAppShell(
              destinations: const [
                CivicNavigationDestination(
                  icon: LucideIcons.house,
                  label: 'Home',
                ),
                CivicNavigationDestination(
                  icon: LucideIcons.settings,
                  label: 'Settings',
                ),
              ],
              selectedIndex: 0,
              onDestinationSelected: (_) {},
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, const Text('Low water at 7:10')],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final header = _node('Tide tables');
        expect(header.label, isNot(contains('Low water')));
        expect(header, isSemantics(isHeader: true));
        final words = _node('Low water at 7:10');
        expect(words.label, 'Low water at 7:10');
        expect(words, isSemantics(isHeader: false));
      } finally {
        semantics.dispose();
      }
    });
  }
}
