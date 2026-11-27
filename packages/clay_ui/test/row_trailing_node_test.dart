// A row that opens something keeps a control at its end as a node of its
// own, so a screen reader reaches the row and its key apart ("Middlemarch",
// then "Delete Middlemarch"). The row merged its key into its own node, and
// the key could not be reached. A row that is itself a checkbox or a switch
// still reads as one node with its control.
import 'dart:ui' show CheckedState;

import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart' show SemanticsNode;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(WidgetTester tester, Widget row) => tester.pumpWidget(
  MaterialApp(
    builder: (context, app) =>
        ClayTheme(data: ClayThemeData.clay(Brightness.light), child: app!),
    home: ClayScreen(body: ClayGroup(children: [row])),
  ),
);

Iterable<SemanticsNode> _nodes(bool Function(SemanticsNode node) test) => find
    .semantics
    .byPredicate((node) => !node.isMergedIntoParent && test(node))
    .evaluate();

void main() {
  testWidgets('a row keeps its trailing key as a node of its own', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _show(
      tester,
      ClayListTile(
        title: 'Middlemarch',
        subtitle: 'George Eliot',
        onTap: () {},
        trailing: ClayIconButton.plain(
          onPressed: () {},
          icon: const Icon(IconData(0xe001)),
          tooltip: 'Delete Middlemarch',
        ),
      ),
    );
    final key = _nodes(
      (node) => node.getSemanticsData().tooltip == 'Delete Middlemarch',
    );
    expect(key, hasLength(1));
    expect(key.single.getSemanticsData().flagsCollection.isButton, isTrue);
    final row = _nodes(
      (node) => node.getSemanticsData().label.contains('Middlemarch'),
    );
    expect(row, hasLength(1));
    expect(row.single, isNot(key.single));
    expect(row.single.getSemanticsData().flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('a checkbox row stays one node with its box', (tester) async {
    final handle = tester.ensureSemantics();
    await _show(
      tester,
      ClayListTile(
        title: 'Drink water',
        checked: true,
        onTap: () {},
        trailing: ClayCheckbox(value: true, onChanged: (_) {}),
      ),
    );
    final row = _nodes(
      (node) => node.getSemanticsData().label.contains('Drink water'),
    );
    expect(row, hasLength(1));
    expect(
      _nodes(
        (node) =>
            node.getSemanticsData().flagsCollection.isChecked !=
            CheckedState.none,
      ),
      hasLength(1),
    );
    handle.dispose();
  });
}
