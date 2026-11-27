// A pressable card's footer buttons keep their own nodes: a screen reader
// reaches the card, named by its words, and each button apart from it.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

/// The labels of the nodes a screen reader visits, their flags beside.
List<(String, bool)> _visited(WidgetTester tester) {
  final out = <(String, bool)>[];
  void visit(SemanticsNode node) {
    if (!node.isMergedIntoParent) {
      final data = node.getSemanticsData();
      if (data.label.isNotEmpty) {
        out.add((data.label, data.flagsCollection.isButton));
      }
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(
    tester.binding.renderViews.first.owner!.semanticsOwner!.rootSemanticsNode!,
  );
  return out;
}

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.macOS]) {
    testWidgets('a pressed card keeps its buttons apart (${platform.name})', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final log = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: platform),
          builder: (context, app) =>
              Fluent2Host(brightness: Brightness.light, child: app!),
          home: Center(
            child: SizedBox(
              width: 360,
              child: Fluent2Card(
                onPressed: () => log.add('card'),
                children: [
                  const Fluent2CardHeader(
                    header: 'Q3 plan.docx',
                    description: 'Kai Tanaka edited 2h ago',
                  ),
                  Fluent2CardFooter(
                    children: [
                      Fluent2Button('Share', onPressed: () => log.add('share')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final nodes = _visited(tester);
      final card = nodes.where((n) => n.$1.contains('Q3 plan.docx')).toList();
      expect(card, hasLength(1), reason: '$nodes');
      expect(card.single.$2, isTrue, reason: 'the card is a button');
      expect(card.single.$1, isNot(contains('Share')), reason: '$nodes');
      expect(nodes, contains(('Share', true)));
      const DesignControlNodesCheck(look: 'Fluent 2')
          .check(tester.element(find.byType(Fluent2Card)))
          .verify();
      await tester.tap(find.text('Share'));
      expect(log, ['share']);
      semantics.dispose();
    });
  }
}
