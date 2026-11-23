// A section's heading and the words after it read as two nodes, the heading
// flagged as a header, on a page under RetroDesktopHost and with the host
// standing straight around them.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';
import 'package:retro_desktop_ui/retro_desktop_host.dart';

import 'support.dart';

void main() {
  setUpAll(loadRetroDesktopFonts);

  const content = Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      RetroDesktopSectionHeader('Startup items'),
      Text('Open these when the computer starts'),
    ],
  );

  void expectApart(WidgetTester tester) {
    final heading = tester.getSemantics(
      find.descendant(
        of: find.byType(RetroDesktopSectionHeader),
        matching: find.text('Startup items'),
      ),
    );
    final text = tester.getSemantics(
      find.text('Open these when the computer starts'),
    );
    expect(heading.label, 'Startup items');
    expect(heading.flagsCollection.isHeader, isTrue);
    expect(text.label, 'Open these when the computer starts');
    expect(text.flagsCollection.isHeader, isFalse);
  }

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, on a page under RetroDesktopHost', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (_, child) =>
            RetroDesktopHost(brightness: Brightness.light, child: child!),
        home: const RetroDesktopScaffold(body: content),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expectApart(tester);
    semantics.dispose();
  });

  testWidgets('a section header and the text after it read as two nodes, the '
      'header flagged as one, held straight by RetroDesktopHost', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      const MaterialApp(
        home: RetroDesktopHost(brightness: Brightness.light, child: content),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expectApart(tester);
    semantics.dispose();
  });
}
