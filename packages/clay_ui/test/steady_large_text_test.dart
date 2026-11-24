// Steady at twice the text size on a phone, left to right and right to left:
// Today's ring stands clear of its words and each of their lines is whole, the settings' address keeps on one
// line, a sparkline's figure keeps on its line, a split pane's rows keep
// their names whole, and (on a desk) a habit's month keeps each day's number
// inside its ball.
// ignore_for_file: avoid_relative_lib_imports
import 'dart:math' as math;

import 'package:clay_ui/clay_ui.dart'
    show ClayProgressRing, ClaySurface, clayLoadFonts;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../example/lib/gallery_pages.dart';
import '../example/lib/kit_gallery/steady/steady.dart';

Future<void> _open(
  WidgetTester tester,
  TextDirection direction, {
  SteadyPlace place = SteadyPlace.overview,
  String? part,
  Size size = const Size(390, 844),
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    SteadyApp(
      initialPlace: place,
      initialDirection: direction,
      textScale: 2,
      parts: [for (final p in galleryPages) (title: p.title, build: p.build)],
      initialPart: part == null
          ? null
          : galleryPages.indexWhere((p) => p.id == part),
    ),
  );
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(tester.takeException(), isNull);
}

// Scrolls the page down until [target] is built, then brings it into view.
Future<void> _seek(WidgetTester tester, Finder target) async {
  for (var pass = 0; pass < 60 && target.evaluate().isEmpty; pass++) {
    final open =
        tester
            .stateList<ScrollableState>(find.byType(Scrollable))
            .where(
              (s) =>
                  s.position.axis == Axis.vertical &&
                  s.position.pixels < s.position.maxScrollExtent - 1,
            )
            .toList()
          ..sort(
            (a, b) => b.position.viewportDimension.compareTo(
              a.position.viewportDimension,
            ),
          );
    if (open.isEmpty) break;
    final p = open.first.position;
    p.jumpTo(math.min(p.pixels + p.viewportDimension * 0.8, p.maxScrollExtent));
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(target, findsWidgets);
  await tester.ensureVisible(target.first);
  await tester.pump(const Duration(milliseconds: 300));
  expect(tester.takeException(), isNull);
}

// The lines [text] lies on.
int _lines(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(
      baseOffset: 0,
      extentOffset: paragraph.text.toPlainText().length,
    ),
  );
  return {for (final box in boxes) box.top.round()}.length;
}

// Each word of [text] lies on one line: a word broken in two spans two.
void _expectWordsWhole(WidgetTester tester, Finder text) {
  final paragraph = tester.renderObject<RenderParagraph>(text);
  final words = paragraph.text.toPlainText();
  var start = 0;
  for (final word in words.split(' ')) {
    final boxes = paragraph.getBoxesForSelection(
      TextSelection(baseOffset: start, extentOffset: start + word.length),
    );
    expect(
      {for (final box in boxes) box.top.round()},
      hasLength(1),
      reason: '"$word" of "$words" runs over more than one line',
    );
    start += word.length + 1;
  }
}

void main() {
  setUpAll(clayLoadFonts);
  for (final direction in TextDirection.values) {
    final side = direction.name;

    testWidgets('Today\'s ring stands clear of its words, each line of '
        'them whole ($side)', (tester) async {
      await _open(tester, direction, place: SteadyPlace.today);
      final ring = find.byWidgetPredicate(
        (w) => w is ClayProgressRing && w.size == 96,
      );
      final title = find.text('Keep it steady').evaluate().isEmpty
          ? find.text('All done. Rest well.')
          : find.text('Keep it steady');
      for (final words in [
        title,
        find.textContaining('left today'),
        find.text('21-day best run'),
      ]) {
        expect(_lines(tester, words), 1, reason: '$words breaks its line');
        expect(
          tester.getRect(ring).overlaps(tester.getRect(words)),
          isFalse,
          reason: 'the ring runs into its words',
        );
      }
    });

    testWidgets('the settings\' address keeps on one line ($side)', (
      tester,
    ) async {
      await _open(tester, direction, place: SteadyPlace.settings);
      expect(_lines(tester, find.text('mara@example.com')), 1);
      _expectWordsWhole(tester, find.text('Mara Ilunga'));
    });

    testWidgets('a sparkline\'s figure keeps on its line ($side)', (
      tester,
    ) async {
      await _open(tester, direction, part: 'charts');
      for (final figure in ['6.7 a day', '7 h 10']) {
        await _seek(tester, find.text(figure));
        expect(_lines(tester, find.text(figure).first), 1, reason: figure);
        // Every row alike: the week under its figure.
        final week = find.bySemanticsLabel(
          figure == '6.7 a day' ? 'Water this week' : 'Sleep this week',
        );
        expect(
          tester.getRect(week).top,
          greaterThanOrEqualTo(tester.getRect(find.text(figure).first).bottom),
          reason: '$figure keeps its week beside it',
        );
      }
    });

    testWidgets('a split pane\'s rows keep their names whole ($side)', (
      tester,
    ) async {
      await _open(tester, direction, part: 'lists');
      await _seek(tester, find.text('Day 1'));
      for (final name in ['Day 1', 'Day 2']) {
        expect(_lines(tester, find.text(name).first), 1, reason: name);
      }
    });

    testWidgets('on a desk a habit\'s month keeps each day\'s number '
        'inside its ball ($side)', (tester) async {
      await _open(
        tester,
        direction,
        place: SteadyPlace.habits,
        size: const Size(1440, 900),
      );
      Finder day(int n) => find.byWidgetPredicate(
        (w) =>
            w is Semantics &&
            (w.properties.label ?? '').startsWith('$n November,'),
      );
      await _seek(tester, day(15));
      for (final n in [1, 8, 12, 15, 19]) {
        final number = find.descendant(of: day(n), matching: find.byType(Text));
        final ball = tester.getRect(
          find.descendant(of: day(n), matching: find.byType(ClaySurface)),
        );
        final at = tester.getRect(number);
        for (final corner in [
          at.topLeft,
          at.topRight,
          at.bottomLeft,
          at.bottomRight,
        ]) {
          expect(
            (corner - ball.center).distance,
            lessThanOrEqualTo(ball.width / 2 + 0.5),
            reason: '$n ($at) reaches past its ball ($ball)',
          );
        }
        expect(
          at.height,
          greaterThanOrEqualTo(
            0.9 * tester.renderObject<RenderParagraph>(number).size.height,
          ),
          reason: '$n is drawn smaller to fit its ball',
        );
      }
    });
  }
}
