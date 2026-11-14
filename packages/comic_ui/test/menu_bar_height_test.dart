// The menu bar keeps its own height under a parent that hands it a tall loose one (an Align, a Stack, a page's body):
// its items centred their words in all the height they were given, so the bar grew to the page and its menus opened
// under the page's bottom edge, out of reach.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  testWidgets(
    'a menu bar in a tall page is a bar, and its menu opens on the page',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 700);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        comicApp(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 340,
              child: ComicMenuBar(
                menus: [
                  DesignMenuEntry(
                    label: 'File',
                    children: [
                      DesignMenuEntry(label: 'New', onPressed: () {}),
                      DesignMenuEntry(label: 'Export', onPressed: () {}),
                    ],
                  ),
                  DesignMenuEntry(
                    label: 'Edit',
                    children: [
                      DesignMenuEntry(label: 'Undo', onPressed: () {}),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      final bar = tester.getRect(find.byType(ComicMenuBar));
      expect(
        bar.height,
        lessThan(ComicTapTarget.target * 2),
        reason: 'the bar is $bar',
      );
      await tester.tap(find.text('File'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      final export = tester.getRect(find.text('Export').last);
      expect(export.top, greaterThan(bar.bottom - 1));
      expect(export.bottom, lessThan(700));
      expect(tester.takeException(), isNull);
    },
  );
}
