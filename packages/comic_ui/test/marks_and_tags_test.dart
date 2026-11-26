// Comic's page dots stand their marks one gap apart face to face, the current page's longer mark too; a multi-select's
// chosen tag stands its words as far in from its start as its cross from its end; and the multi-select's typing row
// says what it takes under the chosen tags too, until the most it takes are chosen.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart' show loadComicFonts;

Future<void> _pump(
  WidgetTester tester,
  Widget part, {
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = const Size(390, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    WidgetsApp(
      color: const Color(0xFFFF3E92),
      pageRouteBuilder: <T>(settings, builder) => PageRouteBuilder<T>(
        settings: settings,
        pageBuilder: (context, animation, secondary) => builder(context),
      ),
      builder: (context, navigator) => Directionality(
        textDirection: direction,
        child: ComicTheme(data: ComicThemeData.offset(), child: navigator!),
      ),
      home: Align(
        alignment: AlignmentDirectional.topStart,
        child: Padding(padding: const EdgeInsets.all(16), child: part),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// The marks of the page dots, by their 18-high faces, in the row's order on screen.
List<Rect> _marks(WidgetTester tester) {
  final rects =
      tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ComicPageDots),
              matching: find.byType(Container),
            ),
          )
          .map((c) => tester.getRect(find.byWidget(c)))
          .where((r) => r.height == 18)
          .toList()
        ..sort((a, b) => a.left.compareTo(b.left));
  return rects;
}

void main() {
  setUpAll(loadComicFonts);

  for (final direction in TextDirection.values) {
    for (final choosing in [true, false]) {
      testWidgets(
        'page dots stand one gap apart face to face, the current page too '
        '(${direction.name}, ${choosing ? 'taking presses' : 'display only'})',
        (tester) async {
          await _pump(
            tester,
            ComicPageDots(
              pageCount: 5,
              selectedIndex: 2,
              label: 'Pages',
              onPageChanged: choosing ? (_) {} : null,
            ),
            direction: direction,
          );
          final marks = _marks(tester);
          expect(marks, hasLength(5));
          expect(marks.where((r) => r.width > 18), hasLength(1));
          final gaps = [
            for (var i = 1; i < marks.length; i++)
              marks[i].left - marks[i - 1].right,
          ];
          for (final g in gaps) {
            expect(
              g,
              moreOrLessEquals(gaps.first, epsilon: .5),
              reason: '$gaps',
            );
          }
          // Under the 40 floor a round mark's slot is the floor wide: its neighbours stand 40 - 18 apart.
          expect(gaps.first, moreOrLessEquals(22, epsilon: .5));
        },
      );
    }

    testWidgets(
      "a chosen tag's words stand as far in from its start as its cross from its end (${direction.name})",
      (tester) async {
        await _pump(
          tester,
          SizedBox(
            width: 300,
            child: ComicMultiSelect<String>(
              labelText: 'Rooms',
              values: const ['Kitchen'],
              onChanged: (_) {},
            ),
          ),
          direction: direction,
        );
        final words = tester.getRect(find.text('Kitchen'));
        final face = tester.getRect(
          find
              .ancestor(
                of: find.text('Kitchen'),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        // The cross is a 14 glyph in the middle of its key.
        final key = tester.getRect(find.byIcon(ComicGlyphs.close));
        final cross = Rect.fromCenter(
          center: key.center,
          width: 14,
          height: 14,
        );
        final rtl = direction == TextDirection.rtl;
        final wordsIn = rtl ? face.right - words.right : words.left - face.left;
        final crossIn = rtl ? cross.left - face.left : face.right - cross.right;
        expect(wordsIn, moreOrLessEquals(crossIn, epsilon: 1));
      },
    );
  }

  testWidgets(
    "a multi-select's typing row says what it takes under the chosen tags too",
    (tester) async {
      await _pump(
        tester,
        SizedBox(
          width: 300,
          child: ComicMultiSelect<String>(
            labelText: 'Rooms',
            hintText: 'Add a room',
            values: const ['Kitchen', 'Hall'],
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Add a room'), findsOneWidget);
    },
  );

  testWidgets('a multi-select that holds the most it takes shows no hint', (
    tester,
  ) async {
    await _pump(
      tester,
      SizedBox(
        width: 300,
        child: ComicMultiSelect<String>(
          labelText: 'Rooms',
          hintText: 'Add a room',
          values: const ['Kitchen', 'Hall'],
          maxTags: 2,
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Add a room'), findsNothing);
  });
}
