// A glyph that points along the reading direction turns with it: sign out's arrow points out of the page, to the
// right left to right and to the left right to left.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

void main() {
  test('sign out turns with the text', () {
    expect(RetroDesktopGlyphs.signOut.matchTextDirection, isTrue);
  });

  testWidgets('right to left, sign out is drawn mirrored', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(child: Icon(RetroDesktopGlyphs.signOut, size: 24)),
      ),
    );
    final flips = find.descendant(
      of: find.byType(Icon),
      matching: find.byWidgetPredicate(
        (w) => w is Transform && w.transform.storage[0] == -1,
      ),
    );
    expect(flips, findsOneWidget);
  });
}
