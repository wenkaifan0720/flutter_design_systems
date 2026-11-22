// A multi-select set to enabled: false keeps its tags: a screen reader's
// Remove action on a tag calls no onChanged.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

void main() {
  testWidgets("a disabled multi-select removes no tag from a screen reader's "
      'action', (tester) async {
    final handle = tester.ensureSemantics();
    final changes = <List<String>>[];
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, navigator) => MinimalHost(
          light: MinimalThemeData.preset('standard', Brightness.light),
          dark: MinimalThemeData.preset('standard', Brightness.dark),
          brightness: Brightness.light,
          child: navigator!,
        ),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: MinimalMultiSelect<String>(
                label: 'Labels',
                values: const ['Bug'],
                options: const ['Bug', 'Design', 'Docs'],
                enabled: false,
                onChanged: changes.add,
              ),
            ),
          ),
        ),
      ),
    );
    final field = find.byType(MinimalMultiSelect<String>);
    final words = MinimalLocalizations.of(tester.element(field));
    tester.semantics.customAction(
      find.semantics.byLabel('Bug'),
      CustomSemanticsAction(label: words.remove),
    );
    await tester.pump();
    expect(changes, isEmpty);
    handle.dispose();
  });
}
