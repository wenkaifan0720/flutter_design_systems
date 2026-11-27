// One form column, one width: a select, a picker's field and a date field take the column a text field takes, and a
// slider's rail meets the column's edges, at a phone's width and a desk's, either way round.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

Future<void> _pump(
  WidgetTester tester,
  List<Widget> fields, {
  required double width,
  required TextDirection direction,
}) async {
  tester.view.physicalSize = Size(width, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      ComicScaffold(
        topBar: const ComicAppBar(title: 'Add a book'),
        body: ComicSections(
          children: [
            ComicTextField(
              key: const ValueKey('text'),
              labelText: 'Title',
              onChanged: (_) {},
            ),
            ...fields,
          ],
        ),
      ),
      width: width,
      direction: direction,
    ),
  );
  await tester.pump();
}

// The drawn box of a field: its pressable face, not the room round it.
Rect _face(WidgetTester tester, String key) => tester.getRect(
  find
      .descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(ComicPressable),
      )
      .first,
);

Finder _ink(String key, String painter) => find.descendant(
  of: find.byKey(ValueKey(key)),
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        widget.painter.runtimeType.toString() == painter,
  ),
);

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadComicFonts();
  });

  for (final width in [390.0, 1440.0]) {
    for (final direction in TextDirection.values) {
      final at = '$width ${direction.name}';
      testWidgets('a select and a picker field take the column / $at', (
        tester,
      ) async {
        await _pump(
          tester,
          [
            ComicSelect<String>(
              key: const ValueKey('select'),
              labelText: 'Shelf',
              value: 'read',
              options: const [
                ComicSelectOption('read', 'To read'),
                ComicSelectOption('done', 'Done'),
              ],
              onChanged: (_) {},
            ),
            ComicSelectField(
              key: const ValueKey('field'),
              labelText: 'Started',
              value: '14 Mar 2026',
              onPressed: () {},
            ),
          ],
          width: width,
          direction: direction,
        );
        final column = tester.getRect(find.byKey(const ValueKey('text')));
        for (final key in ['select', 'field']) {
          final face = _face(tester, key);
          expect(
            face.left,
            moreOrLessEquals(column.left, epsilon: .5),
            reason: key,
          );
          expect(
            face.right,
            moreOrLessEquals(column.right, epsilon: .5),
            reason: key,
          );
        }
      });

      testWidgets(
        'a slider\'s rail and a range\'s meet the column\'s edges / $at',
        (tester) async {
          await _pump(
            tester,
            [
              ComicSlider(
                key: const ValueKey('slider'),
                label: 'Pages a day',
                value: .4,
                onChanged: (_) {},
              ),
              ComicRangeSlider(
                key: const ValueKey('range'),
                label: 'Pages',
                values: const RawRangeValues(.3, .6),
                onChanged: (_) {},
              ),
            ],
            width: width,
            direction: direction,
          );
          final column = tester.getRect(find.byKey(const ValueKey('text')));
          for (final (key, painter) in [
            ('slider', '_SliderInk'),
            ('range', '_RailInk'),
          ]) {
            final ink = _ink(key, painter);
            expect(ink, findsOneWidget, reason: key);
            final box = tester.getRect(ink);
            final y = box.height / 2;
            // Just inside each of the column's edges, the rail is drawn.
            expect(
              tester.renderObject(ink),
              paints..path(
                includes: [
                  Offset(column.left - box.left + 2, y),
                  Offset(column.right - box.left - 2, y),
                ],
              ),
              reason: key,
            );
          }
        },
      );
    }
  }
}
