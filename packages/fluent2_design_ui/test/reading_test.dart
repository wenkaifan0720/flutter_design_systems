// Rows, cards and a table's checks as a screen reader hears them: a list row that presses is heard once, its title and
// subtitle as its label and its value as its value, its words kept out of the reading (merged in too, each was heard
// twice); a row that does not press reads its words. A check row, a selectable card and a table's select cell carry
// their state on the node the reader lands on, as a check box does (on a container round it, a reader heard an empty
// "checked" and then the part with no state).
import 'dart:ui' show CheckedState, SemanticsAction;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

Widget _app(Widget row) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) =>
      Fluent2Theme(data: Fluent2ThemeData.lapis(), child: page!),
  home: Scaffold(body: row),
);

/// What a screen reader visits, in its order: the nodes it lands on.
List<SemanticsData> _visited(WidgetTester t) => [
  for (final node in t.semantics.simulatedAccessibilityTraversal())
    node.getSemanticsData(),
];

void main() {
  testWidgets('a row that presses is heard once', (t) async {
    final reading = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        Fluent2ListItem(
          title: 'Q3 plan.docx',
          subtitle: 'Kai Tanaka edited',
          value: '2.4 MB',
          onTap: () {},
        ),
      ),
    );
    final heard = _visited(t)
        .singleWhere((d) => d.hasAction(SemanticsAction.tap));
    expect(heard.label, 'Q3 plan.docx, Kai Tanaka edited');
    expect(heard.value, '2.4 MB');
    expect(
      _visited(t).where((d) => d.label.contains('Q3 plan.docx')),
      hasLength(1),
      reason: 'the words are heard once, on the row',
    );
    reading.dispose();
  });

  testWidgets('a check row is heard once, with its state', (t) async {
    final reading = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        Fluent2ListItem(
          title: 'Updates',
          subtitle: 'Weekly',
          checked: true,
          onChanged: (_) {},
        ),
      ),
    );
    final heard = _visited(t)
        .singleWhere((d) => d.hasAction(SemanticsAction.tap));
    expect(heard.label, 'Updates, Weekly');
    expect(heard.flagsCollection.isChecked, CheckedState.isTrue);
    reading.dispose();
  });

  testWidgets('a row that does not press reads its words', (t) async {
    final reading = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        const Fluent2ListItem(
          title: 'Storage',
          subtitle: 'Northwind',
          value: '62%',
        ),
      ),
    );
    final words = _visited(t).map((d) => d.label).join('\n');
    for (final word in ['Storage', 'Northwind', '62%']) {
      expect(RegExp(word).allMatches(words), hasLength(1), reason: word);
    }
    reading.dispose();
  });

  testWidgets('a selectable card is heard with its state', (t) async {
    final reading = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        Fluent2Card(
          selected: true,
          onSelected: (_) {},
          label: 'Brand kit',
          children: const [Text('Brand kit')],
        ),
      ),
    );
    final heard = _visited(t)
        .singleWhere((d) => d.hasAction(SemanticsAction.tap));
    expect(heard.label, 'Brand kit');
    expect(heard.flagsCollection.isChecked, CheckedState.isTrue);
    expect(
      _visited(t)
          .where((d) => d.flagsCollection.isChecked != CheckedState.none),
      hasLength(1),
    );
    reading.dispose();
  });

  testWidgets("a table's select cells are heard with their state", (t) async {
    final reading = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        Fluent2Table(
          columns: const [Fluent2TableColumn('Name')],
          rows: const [
            Fluent2TableRow(cells: [Fluent2TableCell('Q3 plan.docx')]),
            Fluent2TableRow(cells: [Fluent2TableCell('Budget.xlsx')]),
          ],
          selected: const {0},
          onSelectionChanged: (_) {},
        ),
      ),
    );
    final checks = _visited(t)
        .where((d) => d.flagsCollection.isChecked != CheckedState.none)
        .toList();
    expect(checks, isNotEmpty);
    for (final check in checks) {
      expect(check.label, isNotEmpty, reason: 'a state with no name');
      expect(check.hasAction(SemanticsAction.tap), isTrue);
    }
    reading.dispose();
  });
}
