// What stands under ExpressiveHost reaches a screen reader as it would
// without the host: a title is a heading node of its own, and the text after
// it is not part of it, with the host above the app's navigator and with it
// inside a page.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

const _page = Column(
  mainAxisSize: MainAxisSize.min,
  children: <Widget>[
    ExpressiveText.title('Tide tables'),
    ExpressiveText.body('Low water at 7:10'),
  ],
);

void main() {
  for (final inPage in [false, true]) {
    testWidgets('a title and the text after it stay two nodes under the host '
        '${inPage ? 'inside a page' : 'above the navigator'}', (tester) async {
      final semantics = tester.ensureSemantics();
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        inPage
            ? const MaterialApp(home: ExpressiveHost(child: _page))
            : MaterialApp(
                builder: (context, child) => ExpressiveHost(child: child!),
                home: _page,
              ),
      );
      final title = tester.getSemantics(find.text('Tide tables'));
      expect(title.flagsCollection.isHeader, isTrue);
      expect(title.label, 'Tide tables');
      final text = tester.getSemantics(find.text('Low water at 7:10'));
      expect(text.flagsCollection.isHeader, isFalse);
      expect(text.label, 'Low water at 7:10');
      semantics.dispose();
    });
  }
}
