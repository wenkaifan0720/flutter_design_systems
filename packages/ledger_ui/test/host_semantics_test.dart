// What stands under LedgerHost reaches a screen reader as it would without
// the host: a section's heading is a heading node of its own, and the text
// after it is not part of it, with the host above the app's navigator and
// with it inside a page.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ledger_ui/ledger_ui.dart';

const _page = Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    LedgerDivider(label: 'Accounts'),
    Text('Five accounts, two shared'),
  ],
);

void main() {
  for (final inPage in [false, true]) {
    testWidgets('a heading and the text after it stay two nodes under the host '
        '${inPage ? 'inside a page' : 'above the navigator'}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        inPage
            ? const MaterialApp(home: LedgerHost(child: _page))
            : MaterialApp(
                builder: (context, child) => LedgerHost(child: child!),
                home: _page,
              ),
      );
      final heading = tester.getSemantics(find.byType(LedgerDivider));
      expect(heading.flagsCollection.isHeader, isTrue);
      expect(heading.label, 'Accounts');
      final text = tester.getSemantics(find.text('Five accounts, two shared'));
      expect(text.flagsCollection.isHeader, isFalse);
      expect(text.label, 'Five accounts, two shared');
      semantics.dispose();
    });
  }
}
