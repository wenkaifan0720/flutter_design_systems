// At a large text size, on a row too narrow for its words and its end side by
// side (a phone's), a row's value or control stands under its words, at the
// row's end, as Material's list rows wrap theirs: the words take the row's
// whole width with every word whole, and every row of a slab does the same,
// whatever it ends with. On a wide row (a desk's pane) and at the reader's own
// size it stays on their line where the two fit; on a desk, a part too wide
// for that goes under its words whole.
import 'package:clay_ui/clay_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp;

Future<void> _show(
  WidgetTester tester,
  Widget child, {
  required TextDirection direction,
  double scale = 2,
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, app) => ClayTheme(
        data: ClayThemeData.clay(Brightness.light),
        child: MediaQuery.withClampedTextScaling(
          minScaleFactor: scale,
          maxScaleFactor: scale,
          child: app!,
        ),
      ),
      home: Directionality(
        textDirection: direction,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: child,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

// Each word of [text] lies on one line: a word broken in two spans two.
void _expectWordsWhole(WidgetTester tester, String text) {
  final paragraph = tester.renderObject<RenderParagraph>(find.text(text));
  var start = 0;
  for (final word in text.split(' ')) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + word.length),
    );
    expect(
      {for (final box in boxes) box.top.round()},
      hasLength(1),
      reason: '"$word" of "$text" runs over more than one line',
    );
    start += word.length + 1;
  }
}

Widget _slab() => ClayGroup(
  children: [
    ClayListTile(
      title: 'Morning walk round the park',
      trailingText: '12 days',
      onTap: () {},
    ),
    ClayListTile(
      title: 'Remind me in the evening',
      trailing: ClaySwitch(value: true, onChanged: (_) {}),
    ),
    ClayListTile(
      title: 'Drink water',
      subtitle: 'Eight glasses',
      trailing: ClayCheckbox(value: true, onChanged: (_) {}),
    ),
  ],
);

// What ends each row of the slab, beside the row's words.
List<(String, Finder)> _ends() => [
  ('Morning walk round the park', find.text('12 days')),
  ('Remind me in the evening', find.byType(ClaySwitch)),
  ('Drink water', find.byType(ClayCheckbox)),
];

void main() {
  setUpAll(clayLoadFonts);
  for (final direction in TextDirection.values) {
    final side = direction.name;

    testWidgets('at twice the size every row\'s end stands under its '
        'words, at the row\'s end ($side)', (tester) async {
      await _show(tester, _slab(), direction: direction);
      final slab = tester.getRect(find.byType(ClayGroup));
      for (final (title, end) in _ends()) {
        _expectWordsWhole(tester, title);
        final words = tester.getRect(find.text(title));
        final at = tester.getRect(end);
        expect(
          at.top,
          greaterThanOrEqualTo(words.bottom),
          reason: 'the end of "$title" stays beside its words',
        );
        if (direction == TextDirection.ltr) {
          expect(at.left, greaterThan(slab.center.dx), reason: title);
        } else {
          expect(at.right, lessThan(slab.center.dx), reason: title);
        }
      }
      expect(
        tester.renderObject<RenderParagraph>(find.text('12 days')).size.width,
        greaterThanOrEqualTo(
          tester
                  .renderObject<RenderParagraph>(find.text('12 days'))
                  .getMaxIntrinsicWidth(double.infinity) -
              0.5,
        ),
        reason: '"12 days" is cut',
      );
    });

    testWidgets('at twice the size on a desk\'s wide pane every row\'s end '
        'stays on its words\' line ($side)', (tester) async {
      await _show(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(width: 640, child: _slab()),
        ),
        direction: direction,
        size: const Size(1440, 900),
      );
      for (final (title, end) in _ends()) {
        _expectWordsWhole(tester, title);
        final words = tester.getRect(find.text(title));
        final at = tester.getRect(end);
        expect(
          at.top < words.bottom && at.bottom > words.top,
          isTrue,
          reason: 'the end of "$title" ($at) leaves its words\' line ($words)',
        );
      }
    });

    testWidgets('at twice the size on a desk\'s pane a part too wide to '
        'stand beside its words goes under them, whole ($side)', (
      tester,
    ) async {
      await _show(
        tester,
        Align(
          alignment: AlignmentDirectional.topStart,
          child: SizedBox(
            width: 480,
            child: ClayGroup(
              children: [
                ClayListTile(
                  title: 'Week starts on',
                  trailing: ClaySegmentedButton<String>(
                    segments: const [
                      ClaySegment(value: 'mon', label: 'Mon'),
                      ClaySegment(value: 'sat', label: 'Sat'),
                      ClaySegment(value: 'sun', label: 'Sun'),
                    ],
                    selected: 'mon',
                    expanded: false,
                    onChanged: (_) {},
                  ),
                ),
              ],
            ),
          ),
        ),
        direction: direction,
        size: const Size(1440, 900),
      );
      final words = tester.getRect(find.text('Week starts on'));
      final part = tester.getRect(find.byType(ClaySegmentedButton<String>));
      expect(
        part.top,
        greaterThanOrEqualTo(words.bottom),
        reason: 'the days ($part) are squeezed beside their words ($words)',
      );
      final days = [
        for (final day in ['Mon', 'Sat', 'Sun']) tester.getRect(find.text(day)),
      ];
      for (final day in days) {
        expect(
          day.top,
          moreOrLessEquals(days.first.top, epsilon: 0.5),
          reason: 'the days stand one under another',
        );
      }
    });

    testWidgets('at the reader\'s own size every row\'s end stays on its '
        'words\' line ($side)', (tester) async {
      await _show(tester, _slab(), direction: direction, scale: 1);
      for (final (title, end) in _ends()) {
        final words = tester.getRect(find.text(title));
        final at = tester.getRect(end);
        expect(
          at.top < words.bottom && at.bottom > words.top,
          isTrue,
          reason: 'the end of "$title" ($at) leaves its words\' line ($words)',
        );
      }
    });
  }
}
