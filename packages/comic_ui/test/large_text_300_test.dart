// At 300% text, three parts broke where Material's and Cupertino's hold, each held here:
// - a wheel's rows overlapped and its band cut the chosen value: a row's words grow until their line fills the row;
// - a shares chart's scale set "540 done" one character a line: its words grow at most 1.3 times, as Material's
//   slider label, and wrap only between words;
// - a calendar's weekday initials touched into one word: they grow at most twice, as Material's calendar.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// [child] at [scale] times the text size, in a phone-wide page.
Future<void> _at(WidgetTester tester, double scale, Widget child) async {
  tester.view.physicalSize = const Size(390, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      Builder(
        builder: (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

RenderParagraph _words(WidgetTester tester, String text) =>
    tester.renderObject<RenderParagraph>(find.text(text).first);

/// The left and right of [p]'s drawn words on the screen.
(double, double) _drawn(RenderParagraph p) {
  final boxes = p.getBoxesForSelection(
    TextSelection(baseOffset: 0, extentOffset: p.text.toPlainText().length),
  );
  final left = boxes.map((b) => b.left).reduce(math.min);
  final right = boxes.map((b) => b.right).reduce(math.max);
  return (
    p.localToGlobal(Offset(left, 0)).dx,
    p.localToGlobal(Offset(right, 0)).dx,
  );
}

void main() {
  for (final scale in [2.0, 3.0]) {
    testWidgets('a wheel row holds its words at ${scale.toInt()}00% text', (
      tester,
    ) async {
      await _at(
        tester,
        scale,
        ComicWheelPicker<int>(
          label: 'Copies',
          values: const [1, 2, 3, 4, 5],
          value: 3,
          labelOf: (n) => '$n',
          onChanged: (_) {},
        ),
      );
      for (final n in ['2', '3', '4']) {
        final p = _words(tester, n);
        expect(
          p.size.height,
          lessThanOrEqualTo(44.5),
          reason: '"$n" stands ${p.size.height} tall in a 44 row',
        );
      }
      // It still grows with the reader's text, to twice its size and a little past it at 300%.
      expect(
        _words(tester, '3').textScaler.scale(18),
        closeTo(18 * math.min(scale, 44 / 21.6), .01),
      );
    });
  }

  for (final note in [null, 'Week 3']) {
    testWidgets(
      "a shares chart's scale keeps its words whole at 300% text${note == null ? '' : ', with a note'}",
      (tester) async {
        await _at(
          tester,
          3,
          ComicShares(
            stamp: 'Done',
            scaleStart: '540 done',
            scaleEnd: '330 to go',
            scaleNote: note,
            parts: const [
              ComicShare('The first', 540, ink: ComicShareFill.lamp),
              ComicShare('The second', 200),
              ComicShare('The third', 130),
            ],
          ),
        );
        for (final words in ['540 done', '330 to go', ?note]) {
          final p = _words(tester, words);
          expect(p.textScaler.scale(12), closeTo(12 * 1.3, .01));
          for (final word in words.split(' ')) {
            final tp = TextPainter(
              text: TextSpan(text: word, style: p.text.style),
              textDirection: TextDirection.ltr,
              textScaler: p.textScaler,
              maxLines: 1,
            )..layout();
            expect(
              p.size.width + .5,
              greaterThanOrEqualTo(tp.width),
              reason: '"$word" in "$words" breaks mid-word',
            );
            tp.dispose();
          }
        }
      },
    );
  }

  for (final which in ['date picker', 'calendar']) {
    testWidgets("a $which's weekday initials stand apart at 300% text", (
      tester,
    ) async {
      final calendar = DesignCalendarController(
        firstDate: DateTime(2026),
        lastDate: DateTime(2027),
        initialMonth: DateTime(2026, 11),
      );
      addTearDown(calendar.dispose);
      await _at(
        tester,
        3,
        which == 'date picker'
            ? ComicDatePicker(
                value: DateTime(2026, 11, 6),
                firstDate: DateTime(2026),
                lastDate: DateTime(2027),
                onChanged: (_) {},
              )
            : ComicCalendar(controller: calendar, onChanged: (_) {}),
      );
      const days = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
      final drawn = [for (final d in days) _drawn(_words(tester, d))];
      for (var i = 1; i < days.length; i++) {
        expect(
          drawn[i].$1 - drawn[i - 1].$2,
          greaterThanOrEqualTo(4),
          reason:
              '"${days[i - 1]}" ends at ${drawn[i - 1].$2}, "${days[i]}" starts at ${drawn[i].$1}',
        );
      }
      for (final d in days) {
        final p = _words(tester, d);
        final size = p.text.style!.fontSize!;
        expect(p.textScaler.scale(size), lessThanOrEqualTo(size * 2 + .01));
      }
    });
  }
}
