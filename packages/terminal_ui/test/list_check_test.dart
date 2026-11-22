// Every list a field opens on slipway's screens and the gallery pages that
// have one, at a phone's and a desk's width and right to left on a phone, by
// night: ui_core's checkList (the list as wide as its field, on its edges,
// its words in line with the field's) finds nothing.
//
// A list is laid out the same on paper. There checkList would read the clear
// band a raised pane leaves round its doubled frame, in the pane's own
// picture, as dark ink on the light page, and find every list 2 px out past
// its field on each side; menu_ground_test.dart reads each of these lists on
// paper from the screen's pixels instead.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_review/ui_core_review.dart' show DesignWidthCheck;

// The example's pages set the gallery's direction.
// ignore_for_file: avoid_relative_lib_imports
import '../example/lib/kit_gallery/kit.dart';
import 'faces.dart';
import 'field_lists.dart';
import 'ui_core_checks.dart';

void main() {
  setUpAll(loadFaces);

  const configs = [
    (390.0, TextDirection.ltr),
    (390.0, TextDirection.rtl),
    (1440.0, TextDirection.ltr),
  ];

  for (final t in fieldListPages) {
    for (final (width, dir) in configs) {
      final where = '${width.toInt()}${dir == TextDirection.rtl ? ' rtl' : ''}';
      testWidgets(
        '${t.id} at $where by night: every list a field opens fits it',
        (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = Size(width, width < 600 ? 844 : 900);
          addTearDown(tester.view.reset);
          addTearDown(() => kitShownDirection = TextDirection.ltr);

          final problems = <String>[];
          await openEachFieldList(tester, () => t.app(Brightness.dark, dir), (
            key,
            field,
            pane,
          ) async {
            final found = (await DesignWidthCheck(
              look: 'terminal',
              listWordsIndent: uiCoreChecks.listWordsIndent.$1,
            ).checkList(field, runAsync: tester.runAsync)).problems;
            for (final p in found) {
              problems.add('${t.id} $where $key: $p');
            }
          });

          expect(problems, isEmpty, reason: problems.join('\n'));
        },
        // The check reads drawn pixels, which depend on the rasterizer as a
        // golden does.
        tags: const ['goldens'],
      );
    }
  }
}
