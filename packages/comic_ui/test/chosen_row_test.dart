// A chosen row's words stay on the list's line: its yellow plate reaches past them at either side, rather than
// stepping them in from every other row's.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';
import 'package:comic_ui/src/comic/press.dart' show ComicStateDecoration;

import 'support.dart';

void main() {
  setUpAll(loadComicFonts);

  for (final direction in TextDirection.values) {
    for (final width in const [390.0, 1440.0]) {
      testWidgets(
        "a chosen row's words keep the list's line (${width.round()}, ${direction.name})",
        (tester) async {
          tester.view.physicalSize = Size(width, 900);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          await tester.pumpWidget(
            comicApp(
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ComicListTile(
                      title: 'Proof the studio map',
                      subtitle: 'Open studio',
                      selected: true,
                      onPressed: () {},
                      action: ComicIconButton(
                        ComicGlyphs.more,
                        label: 'More',
                        onPressed: () {},
                      ),
                    ),
                    ComicListTile(
                      title: 'Edit the walking route',
                      subtitle: 'Field guide',
                      onPressed: () {},
                      action: ComicIconButton(
                        ComicGlyphs.more,
                        label: 'More',
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
              ),
              direction: direction,
              width: width,
            ),
          );
          await tester.pumpAndSettle();
          final chosen = tester.getRect(find.text('Proof the studio map'));
          final other = tester.getRect(find.text('Edit the walking route'));
          final start = direction == TextDirection.ltr
              ? (Rect r) => r.left
              : (Rect r) => r.right;
          expect(start(chosen), closeTo(start(other), 0.5));
          // The plate reaches past the words' start.
          final caption = ComicTheme.of(
            tester.element(find.text('Proof the studio map')),
          ).colors.caption;
          final plate = tester.getRect(
            find.byWidgetPredicate(
              (w) =>
                  w is ComicStateDecoration &&
                  w.decoration is ShapeDecoration &&
                  (w.decoration as ShapeDecoration).color == caption,
            ),
          );
          expect(
            direction == TextDirection.ltr
                ? chosen.left - plate.left
                : plate.right - chosen.right,
            greaterThanOrEqualTo(8),
          );
          // And stays clear of the row's action.
          final more = tester.getRect(find.byType(ComicIconButton).first);
          expect(
            direction == TextDirection.ltr
                ? more.left - plate.right
                : plate.left - more.right,
            greaterThan(0),
          );
        },
      );
    }
  }
}
