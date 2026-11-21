// DesignTooltipNodeCheck: a tooltip is on the node of the control it tips.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

Widget _key(String label) => RawButton(
  onPressed: () {},
  semanticLabel: label,
  excludeSemantics: true,
  builder: (context, states, _) =>
      SizedBox.square(dimension: 40, child: Center(child: Text(label[0]))),
);

Future<DesignAlignmentReport> _check(WidgetTester tester, Widget tipped) async {
  await tester.pumpWidget(
    harness(Align(alignment: Alignment.topLeft, child: tipped)),
  );
  return const DesignTooltipNodeCheck(look: 'Test')
      .check(tester.element(find.byWidget(tipped)));
}

void main() {
  testWidgets('a tip on a node over its button is apart from it', (
    tester,
  ) async {
    // As a look's plain tooltip set its tip: a Semantics round a button
    // that keeps its own node.
    final report = await _check(
      tester,
      Semantics(tooltip: 'Delete', child: _key('Delete')),
    );
    expect(report.problems, [
      'the tip "Delete" at 0, 0 (40 × 40) is on a node over a button '
          '"Delete", not on its own: a screen reader reads the tip apart from '
          "the control; merge it into the control's node, as Flutter's "
          'Tooltip and RawTooltip do',
    ]);
  });

  testWidgets('a tip merged into its button\'s node passes', (tester) async {
    final report = await _check(
      tester,
      MergeSemantics(
        child: Semantics(tooltip: 'Delete', child: _key('Delete')),
      ),
    );
    expect(report.problems, isEmpty);
  });

  testWidgets('a tip on what is no control, over none, passes', (tester) async {
    final report = await _check(
      tester,
      Semantics(
        tooltip: 'Due in two days',
        child: const SizedBox.square(dimension: 20),
      ),
    );
    expect(report.problems, isEmpty);
  });
}
