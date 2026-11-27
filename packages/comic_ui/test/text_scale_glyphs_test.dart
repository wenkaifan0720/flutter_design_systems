// At twice the text size a tag's glyph, a chip's and a segment's grow with their words, and a monogram's head grows
// with the name beside it (to twice at most).
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _pump(WidgetTester tester, Widget child, double scale) async {
  tester.view.physicalSize = const Size(390, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            child: Padding(padding: const EdgeInsets.all(16), child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _glyph(WidgetTester tester, Key key) => tester
    .getSize(
      find
          .descendant(of: find.byKey(key), matching: find.byType(RichText))
          .first,
    )
    .height;

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final scale in [1.0, 2.0, 3.0]) {
    testWidgets(
      'glyphs beside words and a monogram grow with the text / $scale',
      (tester) async {
        await _pump(
          tester,
          const ComicColumn(
            children: [
              ComicTag('Done', key: ValueKey('tag'), icon: ComicGlyphs.check),
              ComicPerson(key: ValueKey('person'), initials: 'SC', size: 28),
            ],
          ),
          scale,
        );
        final icon = tester.getSize(
          find.descendant(
            of: find.byKey(const ValueKey('tag')),
            matching: find.byType(Icon),
          ),
        );
        expect(icon.width, moreOrLessEquals(14 * scale, epsilon: .01));
        final grown = scale.clamp(1.0, 2.0);
        final face = find.descendant(
          of: find.byKey(const ValueKey('person')),
          matching: find.byType(ClipOval),
        );
        expect(
          tester.getSize(face).width,
          moreOrLessEquals(28 * grown, epsilon: .01),
        );
        // The initials keep their share of the head: inside it, never past it.
        final letters = tester.getRect(
          find.descendant(
            of: find.byKey(const ValueKey('person')),
            matching: find.byType(RichText),
          ),
        );
        final head = tester.getRect(face);
        expect(head.inflate(.01).contains(letters.topLeft), isTrue);
        expect(head.inflate(.01).contains(letters.bottomRight), isTrue);
        expect(_glyph(tester, const ValueKey('person')), greaterThan(0));
      },
    );
  }
}
