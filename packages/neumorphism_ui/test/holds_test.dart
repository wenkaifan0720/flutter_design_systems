import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadNeumorphicFonts);
  testWidgets('disclosure reports the next state and retains hidden input', (
    tester,
  ) async {
    final changes = <bool>[];
    await tester.pumpWidget(
      neumorphicApp(
        NeumorphicDisclosure(
          title: 'Details',
          onExpansionChanged: changes.add,
          child: const NeumorphicTextField(label: 'Note'),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(changes, [true]);
    await tester.enterText(find.byType(EditableText), 'Saved locally');
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(changes, [true, false]);
    await tester.tap(find.text('Details'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'Saved locally',
    );
  });
  testWidgets('controlled disclosure returns focus when content closes', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var expanded = true;
    late StateSetter update;
    await tester.pumpWidget(
      neumorphicApp(
        StatefulBuilder(
          builder: (context, setState) {
            update = setState;
            return NeumorphicDisclosure(
              title: 'Details',
              focusNode: node,
              expanded: expanded,
              onExpansionChanged: (v) => setState(() => expanded = v),
              child: const NeumorphicTextField(label: 'Note'),
            );
          },
        ),
      ),
    );
    tester
        .widget<EditableText>(find.byType(EditableText))
        .focusNode
        .requestFocus();
    await tester.pump();
    update(() => expanded = false);
    await tester.pumpAndSettle();
    expect(node.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'table adapts to width and text size, handles empty cells and row activation',
    (tester) async {
      var calls = 0;
      Widget table() => NeumorphicTable(
        columns: const [
          NeumorphicTableColumn('Item'),
          NeumorphicTableColumn('Price', numeric: true),
        ],
        rows: [
          NeumorphicTableRow(['Lamp', '24.00'], onPressed: () => calls++),
          const NeumorphicTableRow([]),
        ],
      );
      await tester.pumpWidget(
        neumorphicApp(SizedBox(width: 390, child: table())),
      );
      expect(
        find.text('Item'),
        findsNWidgets(2),
        reason: 'each narrow record has its own labels',
      );
      await tester.tap(find.text('Lamp'));
      expect(calls, 1);
      await tester.pumpWidget(
        neumorphicApp(SizedBox(width: 720, child: table())),
      );
      expect(
        find.text('Item'),
        findsOneWidget,
        reason: 'wide records share a heading',
      );
      await tester.pumpWidget(
        neumorphicApp(
          SingleChildScrollView(child: SizedBox(width: 720, child: table())),
          textScale: 2,
        ),
      );
      expect(
        find.text('Item'),
        findsNWidgets(2),
        reason: 'large type uses the narrow form',
      );
      expect(tester.takeException(), isNull);
    },
  );
  check(
    'table long records',
    () => NeumorphicTable(
      columns: const [
        NeumorphicTableColumn(long),
        NeumorphicTableColumn('Total', numeric: true),
      ],
      rows: [
        NeumorphicTableRow(
          [longLine, '1,234,567.89'],
          selected: true,
          onPressed: () {},
        ),
        const NeumorphicTableRow([]),
      ],
    ),
  );
  check(
    'disclosure long details',
    () => const NeumorphicDisclosure(
      title: longLine,
      note: longLine,
      initiallyExpanded: true,
      child: Text(longLine),
    ),
  );
  check(
    'grouped list long labels',
    () => const NeumorphicListSection(
      label: longLine,
      footer: longLine,
      children: [NeumorphicKvRow(long, longLine)],
    ),
  );
}
