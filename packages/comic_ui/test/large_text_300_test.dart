// At 300% text, three parts broke where Material's and Cupertino's hold, each held here:
// - a wheel's rows overlapped and its band cut the chosen value: a row's words grow until their line fills the row;
// - a shares chart's scale set "540 done" one character a line: its words grow at most 1.3 times, as Material's
//   slider label, and wrap only between words;
// - a calendar's weekday initials touched into one word: they grow at most twice, as Material's calendar;
// - a date picker's grid outgrew a phone and scrolled sideways, and a calendar's numbers filled their cells to the
//   rules: a day's number grows at most twice too, as Material's calendar on a phone;
// - a calendar's month name outgrew the space between its arrows and broke mid-word ("Novembe", "r 2026"): it grows
//   at most twice, as Material's calendar header;
// - a time picker's labels outgrew a desk column's select and broke mid-word ("Minut / e"): its words grow at most
//   twice, as Material's time picker's, and its selects stack where a label would not fit its select on one line;
// - a select's value broke mid-word ("Thur / sday"): it stands on one line with an ellipsis, as Material's
//   DropdownMenu's;
// - a tag input's long tag overflowed its row in a desk column: it stands on one line with an ellipsis, as Material's
//   chips' labels.
// Measured in the bundled faces, as a device draws them.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:comic_ui/comic_ui.dart';

import 'support.dart';

/// [child] at [scale] times the text size, in a page [width] wide (a phone's by default), in [direction].
Future<void> _at(
  WidgetTester tester,
  double scale,
  Widget child, {
  double width = 390,
  TextDirection direction = TextDirection.ltr,
}) async {
  tester.view.physicalSize = Size(width, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    comicApp(
      direction: direction,
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

/// Fails when a word of [p]'s text is wider than [p], so its lines break inside it.
void _wordsWhole(RenderParagraph p) {
  final words = p.text.toPlainText();
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
  setUpAll(loadComicFonts);

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
          _wordsWhole(p);
        }
      },
    );
  }

  for (final which in ['date picker', 'calendar']) {
    testWidgets("a $which's weekday initials stand apart at 300% text", (
      tester,
    ) async {
      final calendar = RawCalendarController(
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

  for (final which in ['date picker', 'calendar']) {
    for (final width in [390.0, 1440.0]) {
      for (final direction in TextDirection.values) {
        testWidgets(
          "a $which's days fit at 300% text, at most twice their size, $width wide, ${direction.name}",
          (tester) async {
            final calendar = RawCalendarController(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              initialMonth: DateTime(2026, 11),
              selectedDate: DateTime(2026, 11, 6),
            );
            addTearDown(calendar.dispose);
            await _at(
              tester,
              3,
              width: width,
              direction: direction,
              which == 'date picker'
                  ? ComicDatePicker(
                      value: DateTime(2026, 11, 6),
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2027),
                      onChanged: (_) {},
                    )
                  : ComicCalendar(controller: calendar, onChanged: (_) {}),
            );
            expect(tester.takeException(), isNull);
            // Seven days stand across the page: nothing scrolls sideways.
            for (final s in tester.stateList<ScrollableState>(
              find.byType(Scrollable),
            )) {
              if (s.position.axis == Axis.horizontal) {
                expect(
                  s.position.maxScrollExtent,
                  0,
                  reason: 'the grid scrolls sideways',
                );
              }
            }
            for (var day = 1; day <= 30; day++) {
              final number = find.text('$day').first;
              final p = tester.renderObject<RenderParagraph>(number);
              final size = p.text.style!.fontSize!;
              expect(
                p.textScaler.scale(size),
                lessThanOrEqualTo(size * 2 + .01),
                reason: '"$day" grows past twice',
              );
              // Its figures stand inside its cell, clear of the rule round it.
              final cell = tester.getRect(
                find
                    .ancestor(of: number, matching: find.byType(DecoratedBox))
                    .first,
              );
              final (left, right) = _drawn(p);
              final rule = day == 6 ? 2.5 : 1.0;
              expect(
                left - cell.left >= rule && cell.right - right >= rule,
                isTrue,
                reason: '"$day" draws $left to $right in a cell $cell',
              );
            }
          },
        );
      }
    }
  }

  for (final which in ['date picker', 'calendar']) {
    for (final width in [320.0, 390.0, 1440.0]) {
      for (final month in [9, 11]) {
        testWidgets(
          "a $which's month name stays whole at 300% text, $width wide, month $month",
          (tester) async {
            final calendar = RawCalendarController(
              firstDate: DateTime(2026),
              lastDate: DateTime(2027),
              initialMonth: DateTime(2026, month),
            );
            addTearDown(calendar.dispose);
            await _at(
              tester,
              3,
              width: width,
              which == 'date picker'
                  ? ComicDatePicker(
                      value: DateTime(2026, month, 6),
                      firstDate: DateTime(2026),
                      lastDate: DateTime(2027),
                      onChanged: (_) {},
                    )
                  : ComicCalendar(controller: calendar, onChanged: (_) {}),
            );
            expect(tester.takeException(), isNull);
            final name = month == 9 ? 'September 2026' : 'November 2026';
            final p = _words(tester, name);
            _wordsWhole(p);
            final size = p.text.style!.fontSize!;
            expect(p.textScaler.scale(size), closeTo(size * 2, .01));
          },
        );
      }
    }
  }

  for (final (locale, names) in const [
    (Locale('en'), ['Hour', 'Minute', 'AM/PM']),
    (Locale('de'), ['Stunde', 'Minute', 'Tageshälfte']),
  ]) {
    // A phone's page, and desk columns as the gallery lays them.
    for (final (page, column) in const [
      (320.0, null),
      (390.0, null),
      (1440.0, 240.0),
      (1440.0, 360.0),
      (1440.0, 520.0),
    ]) {
      testWidgets(
        "a time picker's labels stay whole at 300% text, ${locale.languageCode}, "
        '$page wide${column == null ? '' : ' in a $column column'}',
        (tester) async {
          final picker = Builder(
            builder: (context) => Localizations.override(
              context: context,
              locale: locale,
              delegates: const [RawWidgetsLocalizations.delegate],
              child: ComicTimePicker(
                value: const ComicTime(9, 30),
                use24hFormat: false,
                onChanged: (_) {},
              ),
            ),
          );
          await _at(
            tester,
            3,
            width: page,
            column == null
                ? picker
                : Align(
                    alignment: AlignmentDirectional.topStart,
                    child: SizedBox(width: column, child: picker),
                  ),
          );
          expect(tester.takeException(), isNull);
          for (final name in names) {
            final p = _words(tester, name);
            _wordsWhole(p);
            final size = p.text.style!.fontSize!;
            expect(p.textScaler.scale(size), closeTo(size * 2, .01));
          }
        },
      );
    }
  }

  for (final column in [200.0, 320.0]) {
    testWidgets(
      "a select's value stays on one line at 300% text, in a $column column",
      (tester) async {
        final semantics = tester.ensureSemantics();
        await _at(
          tester,
          3,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: column,
              child: ComicSelect<String>(
                label: 'Delivery day',
                value: 'thu',
                options: const [ComicSelectOption('thu', 'Thursday')],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final p = _words(tester, 'Thursday');
        expect(p.maxLines, 1);
        expect(p.overflow, TextOverflow.ellipsis);
        final line = TextPainter(
          text: p.text,
          textDirection: TextDirection.ltr,
          textScaler: p.textScaler,
          maxLines: 1,
        )..layout();
        expect(p.size.height, closeTo(line.height, .5));
        line.dispose();
        // It is read whole.
        expect(
          tester.getSemantics(find.bySemanticsLabel('Delivery day')),
          isSemantics(label: 'Delivery day', value: 'Thursday'),
        );
        semantics.dispose();
      },
    );
  }

  for (final direction in TextDirection.values) {
    testWidgets(
      "a tag input's long tag stays in its field at 300% text, ${direction.name}",
      (tester) async {
        const tag = 'قصص بوليسية طويلة';
        await _at(
          tester,
          3,
          width: 1440,
          direction: direction,
          Align(
            alignment: AlignmentDirectional.topStart,
            child: SizedBox(
              width: 240,
              child: ComicMultiSelect<String>(
                label: 'Genres',
                values: const [tag, 'Western'],
                options: const [tag, 'Western'],
                onChanged: (_) {},
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final p = _words(tester, tag);
        expect(p.maxLines, 1);
        expect(p.overflow, TextOverflow.ellipsis);
        final field = tester.getRect(find.byType(ComicMultiSelect<String>));
        final drawn = tester.getRect(find.text(tag).first);
        expect(
          drawn.left >= field.left - .5 && drawn.right <= field.right + .5,
          isTrue,
          reason: 'the tag draws $drawn in a field $field',
        );
      },
    );
  }
}
