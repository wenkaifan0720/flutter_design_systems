// A row's swipe commands hold their words in from the plate's sides, as every face does (ui_core_test's
// DesignFaceInsetCheck): "Archive" and "Delete" at a phone's width, by day and by night, left to right and right to
// left, and at twice the text size.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_core_test/ui_core_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);
  for (final dark in [false, true]) {
    for (final direction in TextDirection.values) {
      for (final scale in [1.0, 2.0]) {
        testWidgets(
          'swipe commands keep their words in (${dark ? 'night' : 'day'}, ${direction.name}, x$scale)',
          (tester) async {
            tester.view.physicalSize = const Size(390, 600);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MediaQuery(
                data: MediaQueryData(
                  size: const Size(390, 600),
                  textScaler: TextScaler.linear(scale),
                ),
                child: comicApp(
                  dark: dark,
                  direction: direction,
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: ComicSwipeActions(
                      initiallyOpen: true,
                      endActions: [
                        RawSwipeAction(
                          label: 'Archive',
                          data: ComicGlyphs.check,
                          onPressed: () {},
                        ),
                        RawSwipeAction(
                          label: 'Delete',
                          data: ComicGlyphs.delete,
                          destructive: true,
                          onPressed: () {},
                        ),
                      ],
                      child: const ComicListTile(
                        title: 'Issue 12',
                        subtitle: 'Slide left',
                      ),
                    ),
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final report = await const DesignFaceInsetCheck(look: 'Comic')
                .check(
                  tester.element(find.byType(ComicSwipeActions)),
                  runAsync: tester.runAsync,
                );
            report.verify();
          },
        );
      }
    }
  }
}
