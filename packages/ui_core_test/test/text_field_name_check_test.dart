// DesignTextFieldNameCheck: each text field says a name, on its own node.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

final _controllers = <TextEditingController>[];
final _nodes = <FocusNode>[];

// A bare text input, [text] in it.
Widget _input([String text = '']) {
  final controller = TextEditingController(text: text);
  final node = FocusNode();
  _controllers.add(controller);
  _nodes.add(node);
  return SizedBox(
    width: 200,
    height: 44,
    child: plainField(controller: controller, focusNode: node),
  );
}

Future<List<String>> _problems(WidgetTester tester, Widget field) async {
  await tester.pumpWidget(
    harness(
      Center(
        child: Column(
          key: const ValueKey('screen'),
          mainAxisSize: MainAxisSize.min,
          children: [field],
        ),
      ),
    ),
  );
  return const DesignTextFieldNameCheck(look: 'Test')
      .check(tester.element(find.byKey(const ValueKey('screen'))))
      .problems;
}

void main() {
  tearDown(() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    _controllers.clear();
    _nodes.clear();
  });

  testWidgets('a field with no name is named by where it is and what it '
      'shows', (tester) async {
    final semantics = tester.ensureSemantics();
    final problems = await _problems(tester, _input('12.50'));
    expect(problems, hasLength(1));
    expect(problems.single, startsWith('a text field showing "12.50" at '));
    expect(problems.single, contains('(200 × 44): says no name'));
    semantics.dispose();
  });

  testWidgets('a label, a hint or a tooltip on its node is a name', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    for (final named in [
      Semantics(label: 'Amount', child: _input()),
      Semantics(hint: 'Search', child: _input()),
      Semantics(tooltip: 'Amount in dollars', child: _input()),
      RawInputDecorator(
        labelText: 'Amount',
        builder: (context, parts) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [?parts.label, parts.control],
        ),
        child: _input(),
      ),
    ]) {
      expect(await _problems(tester, named), isEmpty);
    }
    semantics.dispose();
  });

  testWidgets("a label a tap target keeps beside the field is not the field's "
      'name (the 11-19 Ledger fault)', (tester) async {
    final semantics = tester.ensureSemantics();
    final problems = await _problems(
      tester,
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Focuses the field on a tap, but keeps its own node.
          GestureDetector(onTap: () {}, child: const Text('Amount')),
          _input(),
        ],
      ),
    );
    expect(problems, hasLength(1));
    expect(problems.single, contains('says no name'));
    semantics.dispose();
  });

  testWidgets('without semantics it says how to turn them on', (tester) async {
    await tester.pumpWidget(harness(Center(child: _input())));
    expect(
      () =>
          const DesignTextFieldNameCheck(look: 'Test')
              .check(tester.element(find.byType(Center))),
      throwsA(
        isA<StateError>().having(
          (e) => e.message,
          'message',
          contains('ensureSemantics'),
        ),
      ),
    );
  }, semanticsEnabled: false);
}
