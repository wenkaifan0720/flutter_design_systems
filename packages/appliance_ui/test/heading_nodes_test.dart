// A section's heading and the words after it read as two nodes, the heading
// flagged as a header, on a page under ApplianceHost and with the host
// standing straight around them.
import 'package:appliance_ui/appliance_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const content = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      ApplianceSectionHeader('Delivery'),
      Text('Tuesday, between 8 and 10'),
    ],
  );

  void expectApart(WidgetTester tester) {
    // The heading's node, round the words it prints in capitals.
    final heading = tester.getSemantics(find.text('DELIVERY'));
    final text = tester.getSemantics(find.text('Tuesday, between 8 and 10'));
    expect(heading.label, 'Delivery');
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(text.label, 'Tuesday, between 8 and 10');
    expect(text.flagsCollection.isHeader, isFalse);
  }

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, on a page under ApplianceHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            ApplianceHost(brightness: Brightness.light, child: child!),
        home: const Scaffold(body: content),
      ),
    );
    expectApart(tester);
    semantics.dispose();
  });

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, held straight by ApplianceHost', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: ApplianceHost(brightness: Brightness.light, child: content),
      ),
    );
    expectApart(tester);
    semantics.dispose();
  });
}
