// The masthead's places stand still when another is chosen: the lit link's rim takes no room the others don't take.
// Lettering's hard print falls toward the end, as every print in Comic does: right in LTR, left in RTL, so a logo's
// start keeps to its box's start in both.
import 'dart:typed_data';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Widget _shell(int selected) => MaterialApp(
  debugShowCheckedModeBanner: false,
  home: ComicHost(
    child: ComicAppShell(
      brand: 'Shelf',
      destinations: const [
        ComicNavItem(label: 'Books', short: 'Books', icon: ComicGlyphs.book),
        ComicNavItem(label: 'Add a book', short: 'Add', icon: ComicGlyphs.add),
        ComicNavItem(
          label: 'Settings',
          short: 'Settings',
          icon: ComicGlyphs.settings,
        ),
      ],
      selectedIndex: selected,
      onDestinationSelected: (_) {},
      body: const SizedBox.expand(),
    ),
  ),
);

void main() {
  setUpAll(loadComicFonts);

  testWidgets("the masthead's places keep their places whichever is chosen", (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 900);
    addTearDown(tester.view.reset);
    final at = <int, List<Rect>>{};
    for (final selected in const [0, 1, 2]) {
      await tester.pumpWidget(_shell(selected));
      await tester.pumpAndSettle();
      at[selected] = [
        for (final words in const ['BOOKS', 'ADD A BOOK', 'SETTINGS'])
          tester.getRect(find.text(words)),
      ];
    }
    for (final selected in const [1, 2]) {
      for (var i = 0; i < 3; i++) {
        expect(
          at[selected]![i].left,
          moreOrLessEquals(at[0]![i].left, epsilon: .01),
          reason: 'place $i with $selected chosen',
        );
      }
    }
  });

  /// Ink beside a logo's box, in bands 4 to 10 px out: (left, right).
  Future<(int, int)> beside(
    WidgetTester tester,
    TextDirection direction,
  ) async {
    const key = ValueKey('logo');
    await tester.pumpWidget(
      Directionality(
        textDirection: direction,
        child: ComicTheme(
          data: ComicThemeData.offset(),
          child: const Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: Color(0xFFFFFFFF),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: ComicLetteringProbe(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final box = tester.getRect(find.byType(ComicLettering));
    final frame = tester.getRect(find.byKey(key));
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(key),
    );
    final (ByteData bytes, int w) = (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final bytes = await image.toByteData();
      final w = image.width;
      image.dispose();
      return (bytes!, w);
    }))!;
    int inked(double from, double to) {
      var n = 0;
      for (var x = from.round(); x < to.round(); x++) {
        for (
          var y = (box.top - frame.top).round();
          y < (box.bottom - frame.top).round();
          y++
        ) {
          if (bytes.getUint32((y * w + x) * 4) != 0xFFFFFFFF) n++;
        }
      }
      return n;
    }

    final left = box.left - frame.left, right = box.right - frame.left;
    return (inked(left - 10, left - 4), inked(right + 4, right + 10));
  }

  testWidgets(
    "a logo's print falls toward the end, right in LTR and left in RTL",
    (tester) async {
      final ltr = await beside(tester, TextDirection.ltr);
      final rtl = await beside(tester, TextDirection.rtl);
      // Past the start only the contour, inside 4 px; past the end the plates, 5 across.
      expect(ltr.$1, 0, reason: 'LTR: nothing printed left of the words');
      expect(
        rtl.$1,
        greaterThan(0),
        reason: 'RTL: the print falls left of the words',
      );
      expect(
        rtl.$2,
        lessThan(ltr.$2 ~/ 2),
        reason:
            'RTL: the print leaves the right (the glyphs\' own slant stays)',
      );
    },
  );
}

/// The app's name as the masthead letters it, alone.
class ComicLetteringProbe extends StatelessWidget {
  const ComicLetteringProbe({super.key});
  @override
  Widget build(BuildContext context) => const ComicLogo('Shelf');
}
