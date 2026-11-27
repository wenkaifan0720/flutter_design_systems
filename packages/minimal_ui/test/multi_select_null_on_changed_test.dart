// A multi-select with no onChanged is disabled, as a select with none is:
// it dims, its tags lose their remove keys, the field takes no typing and a
// screen reader's Remove action removes no tag.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _host(Widget child) => MaterialApp(
  builder: (context, navigator) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: navigator!,
  ),
  home: Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SizedBox(width: 320, child: child),
      ),
    ),
  ),
);

const _options = ['Bug', 'Design', 'Docs'];

void main() {
  testWidgets('a multi-select with no onChanged dims, offers no remove key '
      'and takes no typing', (tester) async {
    await tester.pumpWidget(
      _host(
        const MinimalMultiSelect<String>(
          labelText: 'Labels',
          values: ['Bug'],
          options: _options,
        ),
      ),
    );
    final field = find.byType(MinimalMultiSelect<String>);
    final words = MinimalLocalizations.of(tester.element(field));
    expect(find.bySemanticsLabel(words.removeItem('Bug')), findsNothing);
    final dims = tester
        .widgetList<Opacity>(
          find.descendant(of: field, matching: find.byType(Opacity)),
        )
        .first;
    expect(dims.opacity, 0.45);
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    final text = tester.widget<EditableText>(find.byType(EditableText));
    expect(text.focusNode.hasFocus, isFalse);
  });

  testWidgets('a multi-select with onChanged keeps its remove keys', (
    tester,
  ) async {
    final changes = <List<String>>[];
    await tester.pumpWidget(
      _host(
        MinimalMultiSelect<String>(
          labelText: 'Labels',
          values: const ['Bug'],
          options: _options,
          onChanged: changes.add,
        ),
      ),
    );
    final field = find.byType(MinimalMultiSelect<String>);
    final words = MinimalLocalizations.of(tester.element(field));
    await tester.tap(find.bySemanticsLabel(words.removeItem('Bug')));
    await tester.pump();
    expect(changes, [<String>[]]);
  });

  testWidgets('a multi-select with no onChanged removes no tag from a screen '
      "reader's action", (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const MinimalMultiSelect<String>(
          labelText: 'Labels',
          values: ['Bug'],
          options: _options,
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
    expect(find.text('Bug'), findsOneWidget);
    handle.dispose();
  });
}
