// A field's add-ons stay whole at twice the text on a phone while they fit
// the line, the words having the rest, as Material's InputDecorator lays
// out its prefixText and suffixText.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

String _plain(RenderParagraph p) =>
    p.text.toPlainText(includeSemanticsLabels: false);

void main() {
  setUpAll(loadFaces);

  for (final (name, prefix, suffix) in [
    ('a prefix', 'https://', null),
    ('a suffix', null, '.dev'),
  ]) {
    for (final direction in TextDirection.values) {
      testWidgets('$name at 390, 2x, ${direction.name}: laid out whole', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final words = TextEditingController(text: 'pr-1482');
        addTearDown(words.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Directionality(
              textDirection: direction,
              child: MediaQuery.withClampedTextScaling(
                minScaleFactor: 2,
                maxScaleFactor: 2,
                child: TermTheme(
                  data: TermThemeData.dark(),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: TermTextField(
                        labelText: 'preview url',
                        prefixText: prefix,
                        suffixText: suffix,
                        controller: words,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final addOn = (prefix ?? suffix)!;
        final paragraph = tester
            .renderObjectList<RenderParagraph>(find.byType(RichText))
            .firstWhere((p) => _plain(p) == addOn);
        expect(paragraph.didExceedMaxLines, isFalse);
        expect(
          paragraph.getMaxIntrinsicWidth(double.infinity),
          lessThanOrEqualTo(paragraph.size.width + 0.5),
        );
      });
    }
  }
}
