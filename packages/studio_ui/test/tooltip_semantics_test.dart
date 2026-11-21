// A tooltip's message joins the tipped control's own semantics node, as
// the published tooltip made it: a screen reader hears the tip with the
// control, and no node around it takes the tip instead.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:studio_ui/studio_ui.dart';

const _tip = 'Save to your recipes';

void main() {
  testWidgets('the tipped key\'s own node carries the tip', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, app) =>
            StudioHost(brightness: Brightness.light, child: app!),
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Overlays'),
                StudioTooltip(
                  message: _tip,
                  child: StudioButton('Save', onPressed: () {}),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    // What a screen reader is given for the key: its node with all that
    // merges into it.
    final key = tester.getSemantics(find.byType(StudioButton));
    expect(key.getSemanticsData().tooltip, _tip);
    expect(key.getSemanticsData().label, 'Save');
    // The only node that says the tip is the key's.
    var root = key;
    while (root.parent != null) {
      root = root.parent!;
    }
    final saying = <SemanticsNode>[];
    void visit(SemanticsNode node) {
      final data = node.getSemanticsData();
      if (data.tooltip.contains(_tip) || data.label.contains(_tip)) {
        saying.add(node);
      }
      node.visitChildren((child) {
        visit(child);
        return true;
      });
    }

    visit(root);
    expect(saying, [key]);
    semantics.dispose();
  });
}
