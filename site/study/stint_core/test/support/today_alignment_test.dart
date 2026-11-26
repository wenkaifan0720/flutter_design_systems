import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'today_alignment.dart';

/// The centred strip's rules on painted rects: a strip whose keys share the
/// digits' line, and one whose keys stand on a row of their own under them.
void main() {
  // A 1024 strip, left to right: the card's ink from 300 to 960, its inset
  // 36; the clock on the Open tasks track at 652.
  const card = Rect.fromLTRB(300, 140, 960, 290);
  const tasks = Rect.fromLTRB(652, 360, 800, 450);
  const title = Rect.fromLTRB(336, 210, 500, 250);
  const digits = Rect.fromLTRB(652, 214, 771, 246);
  List<String> check({
    required Rect first,
    required Rect last,
    Rect digitsAt = digits,
    bool rtl = false,
  }) => centredStripProblems(
    width: 1024,
    rtl: rtl,
    title: title,
    digits: digitsAt,
    first: first,
    last: last,
    card: card,
    tasks: tasks,
  );
  Rect mirror(Rect r) =>
      Rect.fromLTRB(1260 - r.right, r.top, 1260 - r.left, r.bottom);

  group('keys on the line', () {
    const first = Rect.fromLTRB(800, 210, 860, 250);
    const last = Rect.fromLTRB(870, 210, 924, 250);
    test('hold on the digits\' centre line at the card inset', () {
      expect(check(first: first, last: last), isEmpty);
    });
    test('read from the right in Arabic', () {
      final problems = centredStripProblems(
        width: 1024,
        rtl: true,
        title: mirror(title),
        digits: mirror(digits),
        first: mirror(first),
        last: mirror(last),
        card: mirror(card),
        tasks: mirror(tasks),
      );
      expect(problems, isEmpty);
    });
    test('off the digits\' centre line fail', () {
      expect(
        check(first: first.translate(0, 4), last: last.translate(0, 4)),
        contains(startsWith('timer digits and controls centre')),
      );
    });
    test('short of the card inset fail', () {
      expect(
        check(first: first.translate(-6, 0), last: last.translate(-6, 0)),
        contains(startsWith('trailing control has the card inset')),
      );
    });
  });

  group('keys on their own row', () {
    // Under the digits by 14, at the card's inset.
    const first = Rect.fromLTRB(690, 260, 780, 300);
    const last = Rect.fromLTRB(790, 260, 924, 300);
    test('hold under the digits at the strip\'s gap and the card inset', () {
      expect(check(first: first, last: last), isEmpty);
    });
    test('too far under the digits fail', () {
      expect(
        check(first: first.translate(0, 30), last: last.translate(0, 30)),
        contains(startsWith('timer keys row under the digits')),
      );
    });
    test('on two lines of their own fail', () {
      expect(
        check(first: first, last: last.translate(0, 6)),
        contains(startsWith('timer button centres')),
      );
    });
    test('short of the card inset fail', () {
      expect(
        check(first: first.translate(-6, 0), last: last.translate(-6, 0)),
        contains(startsWith('trailing control has the card inset')),
      );
    });
  });

  test('a phone stacks title, digits and keys', () {
    expect(
      centredStripProblems(
        width: 390,
        rtl: false,
        title: const Rect.fromLTRB(44, 220, 300, 270),
        digits: const Rect.fromLTRB(44, 300, 200, 340),
        first: const Rect.fromLTRB(44, 380, 180, 420),
        last: const Rect.fromLTRB(190, 380, 346, 420),
        card: const Rect.fromLTRB(24, 160, 366, 440),
        tasks: const Rect.fromLTRB(24, 500, 190, 590),
      ),
      isEmpty,
    );
  });
}
