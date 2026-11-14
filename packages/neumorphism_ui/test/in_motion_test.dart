// In motion: the parts that move, drag, open or preview, held mid-move. The state matrix shows a part at rest; these
// look between its states, where a shape can slip: a slide cut square at the frame's edge, a swiped row's action
// squared off by the strip it shows in, a disclosure's body cut at its sides, a preview band running past the day it
// ends on.
import 'dart:ui' show PointerDeviceKind;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart' show ShaderMaskLayer;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

import 'support.dart';

/// The carousel's slides that cross its frame's side edges, each checked against the frame's clip: the corners at the
/// crossing edge are cut away (round, as the slide's own are) and the middle of that edge shows.
void _slidesHeldRound(WidgetTester tester, String when, {bool rest = false}) {
  final frame = find
      .ancestor(of: find.byType(PageView), matching: find.byType(ClipPath))
      .first;
  final clip = tester.widget<ClipPath>(frame);
  final box = tester.renderObject<RenderBox>(frame);
  final path = clip.clipper!.getClip(box.size);
  final origin = box.localToGlobal(Offset.zero);
  final edges = [origin.dx, origin.dx + box.size.width];
  var crossing = 0;
  for (final card in find.byType(NeumorphicPictureCard).evaluate()) {
    final r = tester.getRect(find.byWidget(card.widget));
    for (final (i, x) in edges.indexed) {
      if (r.left >= x - .5 || r.right <= x + .5) continue;
      crossing++;
      final at = x + (i == 0 ? 1.0 : -1.0);
      for (final y in [r.top + 1, r.bottom - 1]) {
        expect(
          path.contains(Offset(at, y) - origin),
          isFalse,
          reason:
              '$when: a slide crossing the frame edge at $x keeps a corner there (y $y)',
        );
      }
      expect(
        path.contains(Offset(at, r.center.dy) - origin),
        isTrue,
        reason: '$when: the slide shows along the frame edge at $x',
      );
    }
  }
  // At rest one slide fills the frame, its whole cast inside it: nothing is cut. Mid-swipe two slides share it.
  if (rest) {
    expect(crossing, 0, reason: '$when: one whole slide, none cut by an edge');
  } else {
    expect(
      crossing,
      greaterThan(0),
      reason: '$when: some slide crosses an edge',
    );
  }
}

/// The channel's cells in a picker, as global rects: each day the pressed channel runs through paints its own share
/// (a day chosen alone is its own well, not a channel).
List<(Rect, dynamic)> _band(WidgetTester tester) => [
  for (final e
      in find
          .descendant(
            of: find.byType(NeumorphicDateRangePicker),
            matching: find.byWidgetPredicate(
              (w) =>
                  w is CustomPaint &&
                  w.painter.runtimeType.toString() == '_Channel',
            ),
          )
          .evaluate())
    if (((e.widget as CustomPaint).painter as dynamic).run case final run
        when !(run.count == 1 && run.deepFirst == true && run.deepLast == true))
      (tester.getRect(find.byWidget(e.widget)), run),
];

/// The preview ends on [day]: its week's channel stops at that day, which is the range's own end, and nothing
/// of the channel lies after it; on [start]'s week the channel starts at [start].
void _previewEndsOn(WidgetTester tester, String day, {required String start}) {
  final end = tester.getCenter(find.text(day).first);
  final from = tester.getCenter(find.text(start).first);
  final band = _band(tester);
  expect(band, isNotEmpty, reason: 'a preview to $day shows its channel');
  for (final (r, _) in band) {
    expect(r.top > end.dy, isFalse, reason: 'no channel after $day\'s week');
  }
  final onRow = band.where((c) => c.$1.top <= end.dy && c.$1.bottom >= end.dy);
  final last = onRow.reduce((a, b) => a.$1.right > b.$1.right ? a : b);
  expect(
    last.$1.contains(end),
    isTrue,
    reason: 'the channel stops at $day, not past it',
  );
  expect(
    (last.$2.index == last.$2.count - 1, last.$2.deepLast),
    (true, true),
    reason: '$day is the range\'s own end, not a day it runs through',
  );
  final startRow = band.where(
    (c) => c.$1.top <= from.dy && c.$1.bottom >= from.dy,
  );
  final first = startRow.reduce((a, b) => a.$1.left < b.$1.left ? a : b);
  expect(
    first.$1.contains(from),
    isTrue,
    reason: 'the channel starts at $start',
  );
}

void main() {
  setUpAll(() async {
    await loadNeumorphicFonts();
    await loadNeumorphicGlyphs();
  });

  for (final width in [390.0, 1440.0]) {
    for (final dark in [false, true]) {
      final at = '${width.toInt()} ${dark ? 'dark' : 'light'}';
      testWidgets('a carousel\'s frame holds its shape mid-swipe ($at)', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          neumorphicApp(
            Padding(
              padding: const EdgeInsets.all(16),
              child: NeumorphicCarouselView(
                label: 'Rooms',
                children: [
                  for (final room in ['Hall', 'Kitchen', 'Study'])
                    NeumorphicPictureCard(title: room),
                ],
              ),
            ),
            dark: dark,
            width: width,
          ),
        );
        await tester.pumpAndSettle();
        _slidesHeldRound(tester, 'at rest', rest: true);
        final view = tester.getRect(find.byType(PageView));
        final page = view.width * .88;
        final g = await tester.startGesture(view.center);
        await g.moveBy(Offset(-page * .3, 0));
        await tester.pump();
        _slidesHeldRound(tester, '30% through');
        await g.moveBy(Offset(-page * .4, 0));
        await tester.pump();
        _slidesHeldRound(tester, '70% through');
        await g.up();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('a swiped row\'s actions keep their corners mid-slide', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        Padding(
          padding: const EdgeInsets.all(16),
          child: NeumorphicSwipeActions(
            endActions: [
              DesignSwipeAction(
                label: 'Delete',
                destructive: true,
                onPressed: () {},
              ),
              DesignSwipeAction(label: 'Archive', onPressed: () {}),
            ],
            child: const SizedBox(height: 56, child: Text('Lit')),
          ),
        ),
      ),
    );
    final row = tester.getRect(find.byType(NeumorphicSwipeActions));
    final g = await tester.startGesture(row.center);
    for (final (step, moment) in [(-40.0, 'opening'), (-80.0, 'half open')]) {
      await g.moveBy(Offset(step, 0));
      await tester.pump();
      final faces = find.descendant(
        of: find.byType(NeumorphicSwipeActions),
        // Each action's face is moulded, painted by its own painter (since round 1), which holds the face's shape.
        matching: find.byWidgetPredicate(
          (w) =>
              w is CustomPaint &&
              w.painter.runtimeType.toString() == '_ActionFace',
        ),
      );
      expect(faces, findsNWidgets(2), reason: '$moment: both actions show');
      for (final e in faces.evaluate()) {
        final shape =
            ((e.widget as CustomPaint).painter as dynamic).shape as ShapeBorder;
        final r = tester.getRect(find.byWidget(e.widget));
        final path = shape.getOuterPath(r);
        for (final corner in [
          r.topLeft,
          r.topRight,
          r.bottomLeft,
          r.bottomRight,
        ]) {
          final inward = r.center - corner;
          expect(
            path.contains(corner + inward / inward.distance * .75),
            isFalse,
            reason:
                '$moment: an action\'s face is cut round at its corner $corner',
          );
        }
        expect(
          r.right,
          lessThan(row.right),
          reason: '$moment: a face stands in from the row\'s end',
        );
      }
    }
    await g.up();
    await tester.pumpAndSettle();
  });

  testWidgets('a slid row\'s words sink under the edge it passes', (
    tester,
  ) async {
    Future<int> masks({required bool open, required TextDirection dir}) async {
      await tester.pumpWidget(
        neumorphicApp(
          Directionality(
            textDirection: dir,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: NeumorphicSwipeActions(
                key: ValueKey((open, dir)),
                initiallyOpen: open,
                endActions: [
                  DesignSwipeAction(label: 'Archive', onPressed: () {}),
                ],
                child: const SizedBox(
                  height: 56,
                  child: Text('One lamp over the worktop'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.layers.whereType<ShaderMaskLayer>().length;
    }

    // Cut sheer at its frame's edge, an open row read as a broken scrap of text (fresh-eyes rounds 1-11).
    for (final dir in TextDirection.values) {
      expect(
        await masks(open: true, dir: dir),
        1,
        reason: '$dir: open, the row fades where it passes under its frame',
      );
      expect(
        await masks(open: false, dir: dir),
        0,
        reason: '$dir: closed, nothing of the row is faded',
      );
    }
  });

  testWidgets('an opening disclosure cuts its body only along the foot', (
    tester,
  ) async {
    await tester.pumpWidget(
      neumorphicApp(
        const Padding(
          padding: EdgeInsets.all(16),
          child: NeumorphicDisclosure(
            title: 'Rooms',
            child: NeumorphicCard(children: [Text('Hall')]),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Rooms'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    Finder cutsOfBody() => find.ancestor(
      of: find.byType(NeumorphicCard),
      matching: find.descendant(
        of: find.byType(NeumorphicDisclosure),
        matching: find.byType(ClipRect),
      ),
    );
    final cuts = cutsOfBody();
    expect(cuts, findsOneWidget, reason: 'mid-open, the body is cut');
    final cut = tester.widget<ClipRect>(cuts);
    final box = tester.renderObject<RenderBox>(cuts).size;
    final clip = cut.clipper!.getClip(box);
    expect(clip.left, lessThan(-16), reason: 'nothing cut at the start side');
    expect(clip.right, greaterThan(box.width + 16), reason: 'nor the end');
    expect(clip.top, lessThan(-16), reason: 'nor above');
    expect(clip.bottom, box.height, reason: 'the foot is the edge that moves');
    await tester.pumpAndSettle();
    // Open, the cut stays in the tree (so the body's state, a field's typed words, survives) but cuts nothing.
    expect(
      tester
          .widgetList<ClipRect>(cutsOfBody())
          .where((c) => c.clipBehavior != Clip.none),
      isEmpty,
      reason: 'open, nothing cuts the body or its cast',
    );
  });

  // The picker shows two months; each day here is June's (the first of its number).
  testWidgets('a range\'s preview ends on the day it points at', (
    tester,
  ) async {
    final c = DesignCalendarController(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      mode: DesignCalendarMode.range,
      initialMonth: DateTime(2026, 6),
      currentDate: DateTime(2026, 6, 1),
    );
    addTearDown(c.dispose);
    await tester.pumpWidget(
      neumorphicApp(
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: NeumorphicDateRangePicker(controller: c),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('10').first);
    await tester.pumpAndSettle();
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    addTearDown(mouse.removePointer);
    await mouse.addPointer(location: Offset.zero);
    for (final day in ['12', '18']) {
      await mouse.moveTo(tester.getCenter(find.text(day).first));
      await tester.pumpAndSettle();
      _previewEndsOn(tester, day, start: '10');
    }
    await mouse.moveTo(tester.getCenter(find.text('10').first));
    await tester.pumpAndSettle();
    expect(_band(tester), isEmpty, reason: 'pointing at the start: no band');
    await mouse.moveTo(tester.getCenter(find.text('5').first));
    await tester.pumpAndSettle();
    expect(_band(tester), isEmpty, reason: 'before the start: no preview');

    // The keyboard's day previews the same way.
    await mouse.moveTo(Offset.zero);
    await tester.pumpAndSettle();
    for (
      var i = 0;
      i < 8 &&
          !'${FocusManager.instance.primaryFocus?.debugLabel}'.contains(
            'DesignCalendar',
          );
      i++
    ) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(
      '${FocusManager.instance.primaryFocus?.debugLabel}',
      contains('DesignCalendar'),
      reason: 'Tab reaches the calendar',
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    _previewEndsOn(tester, '12', start: '10');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    _previewEndsOn(tester, '19', start: '10');
  });
}
