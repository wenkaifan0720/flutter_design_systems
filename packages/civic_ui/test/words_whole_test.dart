// Every page of the gallery, so every part, on a phone at twice the text, left
// to right and right to left (in Arabic): no line breaks inside a word
// (words_whole.dart); with every chart's table folded out, no table cell is
// cut and no chart's words overlap (tables_whole.dart).
// Brindlemere's screens are held to the same at 390 and twice the text, in
// English and in Arabic (screens_matrix.dart).
// ignore_for_file: avoid_relative_lib_imports
import 'package:civic_ui/civic_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import 'screens_matrix.dart';
import 'tables_whole.dart';
import 'words_whole.dart';

void main() {
  setUpAll(loadScreenFonts);
  for (final page in galleryPages) {
    for (final direction in TextDirection.values) {
      testWidgets('${page.id} at 390, text ×2, ${direction.name}', (
        tester,
      ) async {
        await showScreen(
          tester,
          Directionality(
            textDirection: direction,
            child: page.build(Brightness.light),
          ),
          width: 390,
          height: 844,
          text: 2,
        );
        expect(tester.takeException(), isNull);
        expectWordsWhole(tester, where: page.id);
        expectChartWordsApart(tester, where: page.id);
        final l = DesignLocalizations.of(
          tester.element(find.byType(Navigator).first),
        );
        await openChartTables(tester, l.chartShowTableLabel);
        expect(tester.takeException(), isNull);
        expectWordsWhole(tester, where: '${page.id}, its tables out');
        expectCellsWhole(tester, where: page.id);
      });
    }
  }
}
