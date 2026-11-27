// A row that opens and holds a control of its own (a row's menu key) keeps the control inside its band, as a key of
// its own: a screen reader hears the row and the control as two buttons, a tap on the words opens the row and a tap
// on the control presses only the control.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

int _opened = 0, _menus = 0;

Future<void> _show(WidgetTester tester, {bool selected = true}) async {
  _opened = 0;
  _menus = 0;
  await tester.pumpWidget(
    neumorphicApp(
      Padding(
        padding: const EdgeInsets.all(16),
        child: NeumorphicListTile(
          title: 'Proof the studio map',
          subtitle: 'Open studio',
          selected: selected,
          isFirst: true,
          onPressed: () => _opened++,
          action: NeumorphicIconButton(
            NeumorphicGlyphs.ellipsis,
            semanticLabel: 'Task actions',
            size: 38,
            onPressed: () => _menus++,
          ),
        ),
      ),
      width: 800,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the control is its own node beside the selected row', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await _show(tester);
    final control = find.semantics.byLabel('Task actions');
    expect(control, findsOne);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Task actions')),
      isSemantics(label: 'Task actions', isButton: true),
    );
    expect(
      tester.getSemantics(
        find.bySemanticsLabel('Proof the studio map, Open studio'),
      ),
      isSemantics(
        label: 'Proof the studio map, Open studio',
        isButton: true,
        isSelected: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('a tap on the words opens the row, on the control its menu', (
    tester,
  ) async {
    await _show(tester, selected: false);
    await tester.tap(find.text('Proof the studio map'));
    await tester.pumpAndSettle();
    expect((_opened, _menus), (1, 0));
    await tester.tap(find.byType(NeumorphicIconButton));
    await tester.pumpAndSettle();
    expect((_opened, _menus), (1, 1));
  });
}
