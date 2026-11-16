// An activity's time is data: written left to right whatever the line's
// direction, so `28 Aug 09:06` keeps its order in an Arabic log (it read
// `Aug 09:06 28`), and it stands at its column's start either way round.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';

Widget _log(TextDirection direction) => Directionality(
  textDirection: direction,
  child: MinimalTheme(
    data: MinimalThemeData.standard(),
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: 354,
        child: MinimalTimeline(
          entries: [
            MinimalActivity(
              at: DateTime(2026, 8, 28, 9, 6),
              stamp: '28 Aug 09:06',
              text: 'هالة منصور علّقت',
            ),
          ],
        ),
      ),
    ),
  ),
);

void main() {
  for (final direction in TextDirection.values) {
    testWidgets('the stamp reads left to right (${direction.name})', (
      tester,
    ) async {
      await tester.pumpWidget(_log(direction));
      final stamp = find.text('28 Aug 09:06');
      final paragraph = tester.renderObject<RenderParagraph>(stamp);
      expect(paragraph.textDirection, TextDirection.ltr);
      final words = tester.getRect(find.textContaining('هالة'));
      final time = tester.getRect(stamp);
      // The time column at the line's start: before the words.
      if (direction == TextDirection.rtl) {
        expect(time.left, greaterThan(words.left));
      } else {
        expect(time.right, lessThan(words.right));
      }
      // Its figures in their written order: the day before the month.
      final day = paragraph.getOffsetForCaret(
        const TextPosition(offset: 0),
        Rect.zero,
      );
      final month = paragraph.getOffsetForCaret(
        const TextPosition(offset: 3),
        Rect.zero,
      );
      expect(day.dx, lessThan(month.dx));
    });
  }

  testWidgets('a section header\'s count reads left to right in Arabic', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: MinimalTheme(
          data: MinimalThemeData.standard(),
          child: const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 354,
              child: MinimalSectionHeader('آخر 12 أسبوعًا', count: '71 / 82'),
            ),
          ),
        ),
      ),
    );
    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('71 / 82'),
    );
    expect(paragraph.textDirection, TextDirection.ltr);
    final kept = paragraph.getOffsetForCaret(
      const TextPosition(offset: 0),
      Rect.zero,
    );
    final all = paragraph.getOffsetForCaret(
      const TextPosition(offset: 5),
      Rect.zero,
    );
    expect(kept.dx, lessThan(all.dx));
  });
}
