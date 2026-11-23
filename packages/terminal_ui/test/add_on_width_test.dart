// A text field's add-ons give way to its words at large text on a phone,
// but each keeps its rule, two letters and the ellipsis: cut, never gone.
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

void main() {
  setUpAll(loadFaces);

  for (final width in const [320.0, 390.0]) {
    testWidgets('add-ons at twice the text in ${width.toInt()} keep three '
        'cells of words', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 600);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          builder: (context, app) => MediaQuery.withClampedTextScaling(
            minScaleFactor: 2,
            maxScaleFactor: 2,
            child: TermTheme(data: TermThemeData.dark(), child: app!),
          ),
          home: const Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                TermTextField(
                  labelText: 'preview url',
                  prefixText: 'https://',
                  suffixText: '.slipway.dev',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      final grid = tester.element(find.byType(TermTextField)).termGrid;
      for (final words in const ['https://', '.slipway.dev']) {
        expect(
          tester.getSize(find.text(words)).width,
          greaterThanOrEqualTo(grid.cols(3) - 0.01),
          reason: words,
        );
      }
    });
  }
}
