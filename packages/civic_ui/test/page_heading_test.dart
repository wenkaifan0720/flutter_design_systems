// A page's title is a heading part: CivicPageHeading says its words as a
// screen reader's heading, in the extra-large step, with an optional caption
// over it that is no heading. An adopter's page title, written as the docs
// showed (a Text in headingXL), was plain text to a screen reader.
import 'package:civic_ui/civic_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a page heading is a heading, its caption is not', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => CivicHost(child: child!),
        home: const CivicScreen(
          topBar: CivicTopBar(title: 'Add'),
          body: CivicPageHeading('Add a book', caption: 'Your reading list'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final heading = tester.getSemantics(find.text('Add a book'));
    expect(heading.flagsCollection.isHeader, isTrue);
    final caption = tester.getSemantics(find.text('Your reading list'));
    expect(caption.flagsCollection.isHeader, isFalse);
    final style = tester.widget<RichText>(
      find
          .descendant(
            of: find.byType(CivicPageHeading),
            matching: find.byType(RichText),
          )
          .last,
    );
    final xl = CivicTheme.textOf(tester.element(find.byType(CivicPageHeading)))
        .headingXL;
    expect(style.text.style?.fontSize, xl.fontSize);
    handle.dispose();
  });
}
