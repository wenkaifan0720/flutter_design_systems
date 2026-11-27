// A tooltip's words are the tipped control's: a screen reader reads them on
// the control's own node, with its label and as a button, as ClayTooltip did
// in 0.1 (MergeSemantics round the tip), never on an ancestor. An icon
// button's own tooltip names it, as Material's IconButton(tooltip:) is
// named.
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clay_ui/clay_ui.dart';

/// What a screen reader reads off [node]: a button or not, its label and its
/// tooltip.
String _read(SemanticsNode node) {
  final data = node.getSemanticsData();
  final kind = data.flagsCollection.isButton ? 'button' : 'not a button';
  return "$kind '${data.label}', tooltip '${data.tooltip}'";
}

void main() {
  testWidgets("a tipped button's node carries the tooltip", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ClayPreview(
        child: Center(
          child: ClayTooltip(
            message: 'Save to your recipes',
            child: ClayButton.filled('Save', onPressed: () {}),
          ),
        ),
      ),
    );
    expect(
      _read(tester.getSemantics(find.byType(ClayButton))),
      "button 'Save', tooltip 'Save to your recipes'",
    );
    // The tip is on no other node.
    expect(
      find.semantics.byPredicate(
        (node) =>
            !node.isMergedIntoParent &&
            node.getSemanticsData().tooltip == 'Save to your recipes',
      ),
      findsOne,
    );
    semantics.dispose();
  });

  testWidgets("an icon button's node carries its own tooltip", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      ClayPreview(
        child: Center(
          child: ClayIconButton(
            onPressed: () {},
            icon: const Icon(IconData(0x41)),
            tooltip: 'Edit this habit',
          ),
        ),
      ),
    );
    expect(
      _read(tester.getSemantics(find.byType(ClayIconButton))),
      "button '', tooltip 'Edit this habit'",
    );
    expect(
      find.semantics.byPredicate(
        (node) =>
            !node.isMergedIntoParent &&
            node.getSemanticsData().tooltip == 'Edit this habit',
      ),
      findsOne,
    );
    semantics.dispose();
  });
}
