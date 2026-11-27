import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

void main() {
  const content = Column(
    mainAxisSize: MainAxisSize.min,
    children: [MinimalSectionHeader('Morning'), Text('Walk before breakfast')],
  );

  Widget host(Widget child) => MinimalHost(
    light: MinimalThemeData.preset('standard', Brightness.light),
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: child,
  );

  void expectApart(WidgetTester tester) {
    final heading = tester.getSemantics(find.byType(MinimalSectionHeader));
    final text = tester.getSemantics(find.text('Walk before breakfast'));
    expect(heading.label.toLowerCase(), 'morning');
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(text.label, 'Walk before breakfast');
    expect(text.flagsCollection.isHeader, isFalse);
  }

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, on a page under MinimalHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) => host(child!),
        home: const MinimalScaffold(body: content),
      ),
    );
    expectApart(tester);
    semantics.dispose();
  });

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, held straight by MinimalHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(MaterialApp(home: host(content)));
    expectApart(tester);
    semantics.dispose();
  });
}
