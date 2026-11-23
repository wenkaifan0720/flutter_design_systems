// A select under a shown label is named once: the field's label names its
// press, which says the chosen option as its value. With no label the press
// names itself.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

Widget _select({String? labelText}) => MaterialApp(
  home: FrostedHost(
    child: Center(
      child: FrostedSelect<String>(
        labelText: labelText,
        options: const [
          FrostedSelectOption('k', 'Kitchen'),
          FrostedSelectOption('s', 'Study'),
        ],
        value: 'k',
        onChanged: (_) {},
      ),
    ),
  ),
);

void main() {
  testWidgets('a labelled select says its label once', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_select(labelText: 'Room'));
    // What a screen reader hears: the field's node with the press merged in.
    final heard = tester
        .getSemantics(find.byType(FrostedPressable))
        .getSemanticsData();
    expect(heard.label, 'Room');
    expect(heard.value, 'Kitchen');
    expect(heard.flagsCollection.isButton, isTrue);
    semantics.dispose();
  });

  testWidgets('a select with no label names itself', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(_select());
    final heard = tester
        .getSemantics(find.byType(FrostedPressable))
        .getSemanticsData();
    expect(heard.label, 'Select');
    expect(heard.value, 'Kitchen');
    semantics.dispose();
  });
}
