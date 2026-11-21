// The behaviour checks as Flutter's accessibility guidelines: a screen meets
// one when its check finds nothing, and fails with the check's own lines.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'behaviour_harness.dart';

import 'package:ui_core_test/guidelines.dart';

// A switch drawn on a pressable that keeps its button flag beside its state.
Widget _switch({required bool asButton}) => Semantics(
  label: 'Sounds',
  toggled: true,
  button: asButton,
  onTap: () {},
  child: GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {},
    child: const SizedBox(width: 48, height: 48),
  ),
);

void main() {
  testWidgets('checkableRoleGuideline: a switch that says it is a button '
      'fails with the check\'s line; one that does not passes', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(harness(Center(child: _switch(asButton: true))));
    final failed = await checkableRoleGuideline.evaluate(tester);
    expect(failed.passed, isFalse);
    expect(
      failed.reason,
      'a switch "Sounds": says it is a button beside its toggled state, as '
      "Flutter's Switch does not",
    );
    await tester.pumpWidget(harness(Center(child: _switch(asButton: false))));
    await expectLater(tester, meetsGuideline(checkableRoleGuideline));
    semantics.dispose();
  });

  testWidgets('textFieldNameGuideline and tapTargetReachGuideline read the '
      'whole screen, as the checks do', (tester) async {
    final semantics = tester.ensureSemantics();
    final controller = TextEditingController();
    final node = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(node.dispose);
    await tester.pumpWidget(
      harness(
        Center(
          child: SizedBox(
            width: 200,
            height: 48,
            child: plainField(controller: controller, focusNode: node),
          ),
        ),
      ),
    );
    final unnamed = await textFieldNameGuideline.evaluate(tester);
    expect(unnamed.passed, isFalse);
    expect(
      unnamed.reason,
      (const DesignTextFieldNameCheck(look: 'Screen')
              .check(tester.element(find.byType(Center))))
          .problems
          .join('\n'),
    );
    await expectLater(tester, meetsGuideline(tapTargetReachGuideline));
    await expectLater(tester, meetsGuideline(cursorGuideline));
    await expectLater(tester, meetsGuideline(fieldSemanticsGuideline));
    await expectLater(tester, meetsGuideline(labelPlacementGuideline));
    await expectLater(tester, meetsGuideline(tooltipNodeGuideline));
    await expectLater(tester, meetsGuideline(listSideGuideline));
    semantics.dispose();
  });

  testWidgets('tooltipNodeGuideline: a tip over a button fails with the '
      'check\'s line', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      harness(
        Center(
          // The switch keeps a node of its own under the tip's.
          child: Semantics(
            tooltip: 'Sounds',
            child: Semantics(container: true, child: _switch(asButton: false)),
          ),
        ),
      ),
    );
    final apart = await tooltipNodeGuideline.evaluate(tester);
    expect(apart.passed, isFalse);
    expect(apart.reason, startsWith('the tip "Sounds" at '));
    semantics.dispose();
  });

  test('each says what it holds', () {
    for (final guideline in [
      checkableRoleGuideline,
      fieldSemanticsGuideline,
      textFieldNameGuideline,
      tapTargetReachGuideline,
      cursorGuideline,
      labelPlacementGuideline,
      tooltipNodeGuideline,
      listSideGuideline,
    ]) {
      expect(guideline.description, endsWith('.'));
    }
  });
}
