// A tooltip's message joins the tipped key's own semantics node, as the
// published tooltip made it: a screen reader hears the key's name, its tip
// and that it is a button together, and no node round it takes the tip.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

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
  setUpAll(loadFaces);

  final keys = <String, (String, Widget)>{
    'TermIconButton': (
      'rerun',
      TermIconButton(glyph: 'r', semanticLabel: 'rerun', onPressed: () {}),
    ),
    'TermButton': ('deploy', TermButton(label: 'deploy', onPressed: () {})),
  };
  for (final MapEntry(key: name, value: (label, key)) in keys.entries) {
    testWidgets("a tipped $name's own node carries its label, its tip and "
        'that it is a button', (t) async {
      final semantics = t.ensureSemantics();
      const tip = 'run it again (r)';
      await t.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          home: TermTheme(
            data: TermThemeData.dark(),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('jobs'),
                  TermTooltip(message: tip, child: key),
                ],
              ),
            ),
          ),
        ),
      );
      final node = t.getSemantics(find.byWidget(key));
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
