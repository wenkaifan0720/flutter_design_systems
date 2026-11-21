// A tooltip's message joins the tipped key's own semantics node, as the
// published tooltip made it: a screen reader hears the key's name, its tip
// and that it is a button together, and no node round it takes the tip.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The nodes under [root] whose tooltip or label says [words].
List<SemanticsNode> _saying(SemanticsNode root, String words) {
  final found = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.tooltip.contains(words) || data.label.contains(words)) {
      found.add(node);
    }
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  visit(root);
  return found;
}

void main() {
  final keys = <String, (String, Widget)>{
    'MinimalIconButton': (
      'Copy link',
      MinimalIconButton(LucideIcons.link, label: 'Copy link', onPressed: () {}),
    ),
    'MinimalButton': ('Archive', MinimalButton('Archive', onPressed: () {})),
  };
  for (final MapEntry(key: name, value: (label, key)) in keys.entries) {
    testWidgets("a tipped $name's own node carries its label, its tip and "
        'that it is a button', (tester) async {
      final semantics = tester.ensureSemantics();
      const tip = 'Anyone with the link can view';
      await tester.pumpWidget(
        MaterialApp(
          home: MinimalTheme(
            data: MinimalThemeData.standard(),
            child: Material(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Share'),
                    MinimalTooltip(message: tip, child: key),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final node = tester.getSemantics(find.byWidget(key));
      expect(
        node,
        isSemantics(
          label: label,
          tooltip: tip,
          isButton: true,
          hasTapAction: true,
        ),
      );
      var root = node;
      while (root.parent != null) {
        root = root.parent!;
      }
      expect(_saying(root, tip), [node]);
      semantics.dispose();
    });
  }
}
