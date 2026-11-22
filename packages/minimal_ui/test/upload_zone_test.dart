// The upload zone marks the words that open the picker.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

import 'support/text_scale_host.dart';

void main() {
  testWidgets('the upload zone prints its link words in a link\'s ink and '
      'underline, and stays one control', (tester) async {
    var browsed = 0;
    const title = 'Drop a CSV here, or browse';
    await tester.pumpWidget(
      textScaleHost(
        MinimalFileUpload(
          title: title,
          link: 'browse',
          onBrowse: () => browsed += 1,
        ),
      ),
    );
    await tester.pumpAndSettle();
    final t = MinimalThemeData.preset('standard', Brightness.light);
    final words = find.text(title, findRichText: true);
    final spans = <TextSpan>[];
    tester.widget<RichText>(words).text.visitChildren((span) {
      if (span is TextSpan && span.text == 'browse') spans.add(span);
      return true;
    });
    expect(spans, hasLength(1));
    expect(spans.single.style?.color, t.primaryInk);
    expect(spans.single.style?.decoration, TextDecoration.underline);
    expect(
      find.descendant(
        of: find.byType(MinimalFileUpload),
        matching: find.byType(MinimalPressable),
      ),
      findsOneWidget,
    );
    await tester.tap(words);
    expect(browsed, 1);
  });
}
