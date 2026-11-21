// Three parts grow with the reader's text only so far, as Material's own
// do, so a phone's width keeps them whole at 300%: a calendar's days to
// twice the size (every day whole, the first week shown), a one-time code
// to twice and to its width (all six cells on screen), a bar chart's names
// and values to 1.3 times (the values on screen). Each at 100%, 200% and
// 300%.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

const _width = 390.0;

Widget _host(double scale, Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, page) => MediaQuery(
    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
    child: page!,
  ),
  home: TermTheme(
    data: TermThemeData.light(),
    child: Builder(
      builder: (context) => ColoredBox(
        color: TermTheme.of(context).background,
        child: Align(
          alignment: Alignment.topLeft,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: _width - 32, child: child),
          ),
        ),
      ),
    ),
  ),
);

Future<void> _pump(WidgetTester t, double scale, Widget child) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(_width, 844);
  addTearDown(t.view.reset);
  await t.pumpWidget(_host(scale, child));
  await t.pumpAndSettle();
  expect(t.takeException(), isNull);
}

// How many lines [paragraph]'s words are laid out on.
int _lines(RenderParagraph paragraph) {
  final words = paragraph.text.toPlainText();
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: words.length),
  );
  return {for (final b in boxes) b.top.round()}.length;
}

// The text scale the words at [finder] are drawn at, as a factor.
double _scaleAt(WidgetTester t, Finder finder) =>
    MediaQuery.textScalerOf(t.element(finder)).scale(10) / 10;

void main() {
  setUpAll(loadFaces);

  for (final scale in const [1.0, 2.0, 3.0]) {
    final name = '${(scale * 100).round()}%';

    testWidgets('at $name a calendar shows every day whole, the first week '
        'too, its days at most twice the size', (t) async {
      final calendar = RawCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027, 12, 31),
        selectedDate: DateTime(2026, 11, 14),
        currentDate: DateTime(2026, 11, 18),
      );
      addTearDown(calendar.dispose);
      await _pump(t, scale, TermCalendar(controller: calendar));
      final screen = Offset.zero & t.view.physicalSize;
      for (var day = 1; day <= 30; day++) {
        // November's, and a day the weeks either side show.
        final words = find.text('$day'.padLeft(2));
        expect(words, findsWidgets, reason: 'day $day');
        for (final shown in words.evaluate()) {
          final one = find.byElementPredicate((e) => identical(e, shown));
          final paragraph = t.renderObject<RenderParagraph>(one);
          // One line: the second figure never wraps out of sight.
          expect(_lines(paragraph), 1, reason: 'day $day');
          final at = t.getRect(one);
          expect(screen.contains(at.topLeft), isTrue, reason: 'day $day');
          expect(screen.contains(at.bottomRight), isTrue, reason: 'day $day');
          expect(_scaleAt(t, one), moreOrLessEquals(scale.clamp(1, 2)));
        }
      }
    });

    testWidgets('at $name a one-time code shows all six cells, at most '
        'twice the size', (t) async {
      await _pump(t, scale, const TermOtpField(semanticLabel: 'code'));
      final code = t.getRect(find.byType(TermOtpField));
      expect(code.right, lessThanOrEqualTo(_width));
      final slots = find.descendant(
        of: find.byType(TermOtpField),
        matching: find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is TermBracketPainter,
        ),
      );
      expect(slots, findsNWidgets(6));
      for (final slot in slots.evaluate()) {
        final at = t.getRect(find.byWidget(slot.widget));
        expect(at.right, lessThanOrEqualTo(_width), reason: '$at');
      }
      // At most twice the size, and as large as the width lets it be.
      expect(_scaleAt(t, slots.first), lessThanOrEqualTo(scale.clamp(1, 2)));
      if (scale == 1) expect(_scaleAt(t, slots.first), 1);
    });

    testWidgets('at $name a bar chart keeps its values on screen, its words '
        'at most 1.3 times the size', (t) async {
      await _pump(
        t,
        scale,
        const TermBarChart(
          bars: [('api', 42), ('web', 18), ('worker', 7)],
          unit: 'min',
        ),
      );
      for (final value in ['42 min', '18 min', '7 min']) {
        final words = find.text(value);
        expect(words, findsOneWidget);
        final at = t.getRect(words);
        expect(at.right, lessThanOrEqualTo(_width), reason: value);
        final paragraph = t.renderObject<RenderParagraph>(words);
        expect(_lines(paragraph), 1, reason: value);
        expect(paragraph.didExceedMaxLines, isFalse, reason: value);
        expect(_scaleAt(t, words), moreOrLessEquals(scale.clamp(1, 1.3)));
      }
    });
  }
}
