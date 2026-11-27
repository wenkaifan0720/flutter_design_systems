// On a page of GlossScaffold, on ui_core's RawAdaptiveShell, under the look's host, a heading and the
// words after it read as two nodes, the heading flagged as a header: the keys
// set round the app and its panes (F6 between panes) add no node of their own
// for the two to merge into.
// GlossScaffold is deprecated (GlossAppShell replaces it); tested until 0.7.0 removes it.
// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:gloss_ui/gloss_ui.dart';
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
    ('the look\'s section header', const GlossSectionHeader('Tide tables')),
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
                GlossHost(theme: GlossThemeData.light(), child: child!),
            home: GlossScaffold(
              destinations: const [
                GlossDestination(icon: LucideIcons.house, label: 'Today'),
                GlossDestination(icon: LucideIcons.bookOpen, label: 'Recipes'),
              ],
              onDestinationSelected: (_) {},
              body: Column(
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
