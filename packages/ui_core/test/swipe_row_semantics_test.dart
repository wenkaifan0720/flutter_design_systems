import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core/ui_core.dart';

import 'behaviour_harness.dart';

const _actions = [
  CustomSemanticsAction(label: 'Pin'),
  CustomSemanticsAction(label: 'Delete'),
];

// A swipe row round [row], 300 by 56.
Widget _swipe(Widget row) => harness(
  Align(
    alignment: Alignment.topLeft,
    child: SizedBox(
      width: 300,
      height: 56,
      child: RawSwipeActions(
        startActions: [RawSwipeAction(label: 'Pin', onPressed: () {})],
        endActions: [RawSwipeAction(label: 'Delete', onPressed: () {})],
        actionBuilder: (context, action, details) => Text(action.label),
        child: row,
      ),
    ),
  ),
);

// A trailing "more" button of a row.
Widget _more() => RawButton(
  key: const ValueKey('more'),
  onPressed: () {},
  semanticLabel: 'More for Stoner',
  builder: (context, states, _) => const SizedBox(width: 40, height: 40),
);

SemanticsData _node(WidgetTester tester, Finder finder) =>
    tester.getSemantics(finder).getSemanticsData();

// Every node in the tree that offers a custom action.
List<SemanticsData> _withActions(WidgetTester tester) {
  final found = <SemanticsData>[];
  bool visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (!node.isMergedIntoParent &&
        (data.customSemanticsActionIds?.isNotEmpty ?? false)) {
      found.add(data);
    }
    node.visitChildren(visit);
    return true;
  }

  var root = tester.getSemantics(find.byType(RawSwipeActions));
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return found;
}

List<int> _ids(List<CustomSemanticsAction> actions) => [
  for (final a in actions) CustomSemanticsAction.getIdentifier(a),
];

void main() {
  testWidgets('a row of words and a trailing button: the words and the '
      "actions are the row's node, the button keeps its own", (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _swipe(
        Row(
          children: [
            const Expanded(child: Text('Stoner')),
            _more(),
          ],
        ),
      ),
    );
    final row = _node(tester, find.text('Stoner'));
    expect(row.label, 'Stoner');
    expect(row.customSemanticsActionIds, unorderedEquals(_ids(_actions)));
    final more = _node(tester, find.byKey(const ValueKey('more')));
    expect(more.label, 'More for Stoner');
    expect(more.hasAction(SemanticsAction.tap), isTrue);
    expect(more.customSemanticsActionIds ?? const <int>[], isEmpty);
    expect(_withActions(tester), hasLength(1));
    semantics.dispose();
  });

  testWidgets("a row that is a button carries the actions on the button's "
      'own node, and no other node offers them', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _swipe(
        RawButton(
          onPressed: () {},
          builder: (context, states, _) => const Text('Stoner'),
        ),
      ),
    );
    final row = _node(tester, find.text('Stoner'));
    expect(row.label, 'Stoner');
    expect(row.hasAction(SemanticsAction.tap), isTrue);
    expect(row.customSemanticsActionIds, unorderedEquals(_ids(_actions)));
    expect(_withActions(tester), hasLength(1));
    semantics.dispose();
  });

  testWidgets("a look's own row node takes the actions through "
      'RawSwipeActionsSemantics, its trailing button kept', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _swipe(
        Semantics(
          container: true,
          button: true,
          onTap: () {},
          child: RawSwipeActionsSemantics(
            child: Row(
              children: [
                const Expanded(child: Text('Stoner')),
                _more(),
              ],
            ),
          ),
        ),
      ),
    );
    final row = _node(tester, find.text('Stoner'));
    expect(row.label, 'Stoner');
    expect(row.hasAction(SemanticsAction.tap), isTrue);
    expect(row.customSemanticsActionIds, unorderedEquals(_ids(_actions)));
    final more = _node(tester, find.byKey(const ValueKey('more')));
    expect(more.label, 'More for Stoner');
    expect(more.customSemanticsActionIds ?? const <int>[], isEmpty);
    expect(_withActions(tester), hasLength(1));
    semantics.dispose();
  });

  testWidgets('a button beside the words never takes the actions, whichever '
      'way the row reads', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _swipe(
        Row(
          children: [
            const Expanded(child: Text('Stoner')),
            RawSwipeActionsSemantics(child: _more()),
          ],
        ),
      ),
    );
    final more = _node(tester, find.byKey(const ValueKey('more')));
    expect(more.customSemanticsActionIds ?? const <int>[], isEmpty);
    expect(
      _node(tester, find.text('Stoner')).customSemanticsActionIds,
      unorderedEquals(_ids(_actions)),
    );
    semantics.dispose();
  });
}
