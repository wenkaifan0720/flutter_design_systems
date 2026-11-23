import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/centred_host.dart';

void main() {
  Future<void> expectExpanded(WidgetTester tester, bool open) async {
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(isTextField: true, hasExpandedState: true, isExpanded: open),
    );
  }

  testWidgets('a combobox says on its text input whether its list is open', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      centredHost(
        SizedBox(
          width: 280,
          child: MinimalCombobox<String>(
            labelText: 'Assignee',
            options: const ['Ana Souza', 'Ben Okafor'],
            onSelected: (_) {},
          ),
        ),
      ),
    );
    await expectExpanded(tester, false);
    await tester.tap(find.byType(EditableText));
    await tester.enterText(find.byType(EditableText), 'B');
    await tester.pumpAndSettle();
    expect(find.text('Ben Okafor'), findsOneWidget);
    await expectExpanded(tester, true);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.text('Ben Okafor'), findsNothing);
    await expectExpanded(tester, false);
    semantics.dispose();
  });

  for (final values in const [
    <String>[],
    ['Bug'],
  ]) {
    testWidgets(
      'a multi-select ${values.isEmpty ? 'with no tags' : 'with a tag'} says on its text input whether its list is open',
      (tester) async {
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          centredHost(
            SizedBox(
              width: 320,
              child: MinimalMultiSelect<String>(
                labelText: 'Labels',
                options: const ['Bug', 'Design'],
                values: values,
                onChanged: (_) {},
              ),
            ),
          ),
        );
        await expectExpanded(tester, false);
        await tester.tap(find.byType(EditableText));
        await tester.enterText(find.byType(EditableText), 'D');
        await tester.pumpAndSettle();
        expect(find.text('Design'), findsOneWidget);
        await expectExpanded(tester, true);
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(find.text('Design'), findsNothing);
        await expectExpanded(tester, false);
        semantics.dispose();
      },
    );
  }
}
