// A section's heading and the words after it read as two nodes, the heading
// flagged as a header, on a page under NeumorphicHost and with the host
// standing straight around them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';
import 'package:neumorphism_ui/neumorphism_host.dart';

void main() {
  const content = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      NeumorphicSectionHeader(title: 'Morning'),
      Text('Walk before breakfast'),
    ],
  );

  void expectApart(WidgetTester tester) {
    final heading = tester.getSemantics(find.byType(NeumorphicSectionHeader));
    final text = tester.getSemantics(find.text('Walk before breakfast'));
    expect(heading.label, 'Morning');
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(text.label, 'Walk before breakfast');
    expect(text.flagsCollection.isHeader, isFalse);
  }

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, on a page under NeumorphicHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            NeumorphicHost(brightness: Brightness.light, child: child!),
        home: const NeumorphicScaffold(body: content),
      ),
    );
    expectApart(tester);
    semantics.dispose();
  });

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, held straight by NeumorphicHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: NeumorphicHost(brightness: Brightness.light, child: content),
      ),
    );
    expectApart(tester);
    semantics.dispose();
  });
}
