// A pressable row with a control at its end (a row's ⋯ menu key) keeps the
// control a node of its own, as a ListTile's trailing IconButton does: a
// screen reader hears the row by its words, and reaches and presses the
// control alone.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

void main() {
  testWidgets('the row names itself, its menu key is its own node', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          brightness: Brightness.light,
          child: navigator!,
        ),
        home: MinimalScaffold(
          padding: EdgeInsets.zero,
          body: Column(
            children: [
              MinimalListTile(
                title: 'Proof the studio map',
                subtitle: 'Open studio · Nov 20',
                selected: true,
                onTap: () => opened++,
                trailing: MinimalMenu.button(
                  LucideIcons.ellipsis,
                  label: 'Task actions',
                  items: [MinimalMenuItem('Delete', onPressed: () {})],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final row = tester.getSemantics(
      find.bySemanticsLabel(RegExp('^Proof the studio map')),
    );
    final key = tester.getSemantics(find.bySemanticsLabel('Task actions'));
    expect(row.getSemanticsData().label, isNot(contains('Task actions')));
    expect(key.id, isNot(row.id));
    expect(key, isSemantics(label: 'Task actions', isButton: true));
    // A screen reader's press on the key opens its menu, not the row.
    tester.semantics.tap(find.semantics.byLabel('Task actions'));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);
    expect(opened, 0);
    semantics.dispose();
  });
}
