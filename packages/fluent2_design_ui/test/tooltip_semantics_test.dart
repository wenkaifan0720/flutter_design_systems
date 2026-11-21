// A tooltip's message joins the tipped key's own semantics node, as the
// published tooltip made it: a screen reader hears the key's name, its tip
// and that it is a button together, and no node round it takes the tip.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';
import 'package:fluent2_design_ui/fluent2_design_host.dart';

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
    'Fluent2IconButton': (
      'Share',
      Fluent2IconButton(Fluent2Icons.share, label: 'Share', onPressed: () {}),
    ),
    'Fluent2Button': ('Archive', Fluent2Button('Archive', onPressed: () {})),
  };
  for (final MapEntry(key: name, value: (label, key)) in keys.entries) {
    testWidgets("a tipped $name's own node carries its label, its tip and "
        'that it is a button', (tester) async {
      final semantics = tester.ensureSemantics();
      const tip = 'Share with your team';
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (BuildContext context, Widget? page) =>
              Fluent2Host(brightness: Brightness.light, child: page!),
          home: Material(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Files'),
                  Fluent2Tooltip(message: tip, child: key),
                ],
              ),
            ),
          ),
        ),
      );
      // A Fluent 2 button's node is found by its name: the widget's
      // outermost box is its tap target, which owns no node.
      final node = tester.getSemantics(find.bySemanticsLabel(label));
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
