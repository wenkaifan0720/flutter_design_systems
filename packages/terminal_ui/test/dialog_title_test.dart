// A dialog's title stays whole in its top line at twice the text on a
// phone, left to right and right to left: the cells it is measured in are
// the face's, grown with the reader's text scale.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';
import 'package:ui_core_test/ui_core_test.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final direction in TextDirection.values) {
    testWidgets('a dialog at 390, 2x, ${direction.name}: its title is whole', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: direction,
            child: MediaQuery.withClampedTextScaling(
              minScaleFactor: 2,
              maxScaleFactor: 2,
              child: TermTheme(
                data: TermThemeData.light(),
                child: Center(
                  child: TermDialog(
                    title: 'unsaved changes',
                    content: const Text(
                      'the form has edits that are not saved.',
                    ),
                    actions: [
                      TermButton(label: 'cancel', onPressed: () {}),
                      TermButton.filled(
                        label: 'save changes',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final title = tester
          .renderObjectList<RenderParagraph>(find.byType(RichText))
          .firstWhere((p) => p.text.toPlainText().contains('unsaved changes'));
      expect(
        title.getMaxIntrinsicWidth(double.infinity),
        lessThanOrEqualTo(title.size.width + 0.5),
      );
      final report = const DesignClipCheck(look: 'terminal')
          .check(tester.element(find.byType(TermDialog)));
      expect(report.problems, isEmpty);
    });
  }
}
