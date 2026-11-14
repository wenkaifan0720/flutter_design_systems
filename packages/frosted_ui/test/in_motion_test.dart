// In motion (design6 O): each gesture driven, and what is on screen read
// mid-move, where the state matrix (a part at rest) cannot see it.
// - A carousel's slide keeps the card's corners 30% and 70% through a swipe,
//   and a peeking slide meets the frame's round edge: the frame holds the
//   shape, not only the slide (the user, 11-11: "the card's border radius
//   goes back to zero during the swipe").
// - A date range's preview ends at the day the pointer or the keyboard rests
//   on, with the round end a finished range has, in the same week, in a
//   later week and right to left; none before the start (the user, 11-11:
//   "the range end region extends beyond the end date and has zero border
//   radius during hovering").
import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frosted_ui/frosted_ui.dart';
import 'package:frosted_ui/frosted_host.dart';

const _ground = Color(0xFFFFFFFF);
const _page = ValueKey('page');

Widget _stage(Widget child, {TextDirection direction = TextDirection.ltr}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      builder: (context, page) =>
          FrostedHost(brightness: Brightness.light, child: page!),
      home: Directionality(
        textDirection: direction,
        child: RepaintBoundary(
          key: _page,
          child: ColoredBox(
            color: _ground,
            child: Center(child: SizedBox(width: 360, child: child)),
          ),
        ),
      ),
    );

/// The page as drawn, one pixel a logical pixel, and a reader of a pixel.
Future<Color Function(Offset)> _shot(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_page),
  );
  final width = boundary.size.width.round();
  final Uint8List px = (await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      return (await image.toByteData())!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }))!;
  return (Offset at) {
    final i = (at.dy.floor() * width + at.dx.floor()) * 4;
    return Color.fromARGB(px[i + 3], px[i], px[i + 1], px[i + 2]);
  };
}

bool _isGround(Color c) =>
    (c.r * 255).round() > 245 &&
    (c.g * 255).round() > 245 &&
    (c.b * 255).round() > 245;

void main() {
  group('a carousel keeps its corners in motion', () {
    Widget carousel({double fraction = 1}) => FrostedCarouselView(
      height: 180,
      viewportFraction: fraction,
      label: 'Places',
      children: const [
        ColoredBox(color: Color(0xFFD03030)),
        ColoredBox(color: Color(0xFF3050D0)),
        ColoredBox(color: Color(0xFF30A050)),
      ],
    );

    Future<List<String>> corners(WidgetTester tester, String when) async {
      final frame = tester.getRect(find.byType(PageView));
      final read = await _shot(tester);
      final faults = <String>[];
      for (final (name, at) in [
        ('top start', frame.topLeft + const Offset(1, 1)),
        ('top end', frame.topRight + const Offset(-2, 1)),
        ('bottom start', frame.bottomLeft + const Offset(1, -2)),
        ('bottom end', frame.bottomRight + const Offset(-2, -2)),
      ]) {
        if (!_isGround(read(at))) {
          faults.add('$when: the $name corner is square');
        }
      }
      return faults;
    }

    testWidgets('30% and 70% through a swipe', (tester) async {
      await tester.pumpWidget(_stage(carousel()));
      await tester.pumpAndSettle();
      final frame = tester.getRect(find.byType(PageView));
      final finger = await tester.startGesture(frame.center);
      await finger.moveBy(const Offset(-20, 0));
      await finger.moveBy(Offset(-frame.width * .3 + 20, 0));
      await tester.pump();
      final faults = await corners(tester, '30%');
      await finger.moveBy(Offset(-frame.width * .4, 0));
      await tester.pump();
      faults.addAll(await corners(tester, '70%'));
      await finger.up();
      await tester.pumpAndSettle();
      faults.addAll(await corners(tester, 'settled'));
      expect(faults, isEmpty, reason: faults.join('\n'));
    }, tags: const ['goldens']);

    // With a peek each slide keeps its own corners and the frame cuts
    // straight: the frame's round corners squeezed the peek into a capsule
    // that grew and shrank as it moved (self-review round 1).
    testWidgets('a peeking slide keeps its own corners, the frame cuts it '
        'straight', (tester) async {
      await tester.pumpWidget(_stage(carousel(fraction: .8)));
      await tester.pumpAndSettle();
      final slide = tester.getRect(
        find.byWidgetPredicate(
          (w) => w is ColoredBox && w.color == const Color(0xFFD03030),
        ),
      );
      final frame = tester.getRect(find.byType(PageView));
      final read = await _shot(tester);
      final faults = <String>[
        for (final (name, at) in [
          ('top start', slide.topLeft + const Offset(1, 1)),
          ('top end', slide.topRight + const Offset(-2, 1)),
          ('bottom start', slide.bottomLeft + const Offset(1, -2)),
          ('bottom end', slide.bottomRight + const Offset(-2, -2)),
        ])
          if (!_isGround(read(at))) "the slide's $name corner is square",
        if (_isGround(read(frame.topRight + const Offset(-2, 1))))
          'the peek is rounded off where the frame ends',
      ];
      expect(faults, isEmpty, reason: faults.join('\n'));
    }, tags: const ['goldens']);

    testWidgets('its dots say the slide, the carousel its label', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await tester.pumpWidget(_stage(carousel()));
      await tester.pumpAndSettle();
      // Only the carousel says its label; the dots say where it stands.
      expect(find.bySemanticsLabel('Places'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('^Slide 1 of 3')), findsWidgets);
      semantics.dispose();
    });
  });

  group("a range's preview ends at its day, round", () {
    // November 2026: the 1st is a Sunday, so the 10th and the 13th share a
    // week and the 20th is in the next.
    Widget picker() => FrostedDateRangePicker(
      firstDate: DateTime(2026),
      lastDate: DateTime(2027, 12, 31),
      currentDate: DateTime(2026, 11, 1),
      months: 1,
      onChanged: (_) {},
    );

    const cell = 38.0;

    /// The preview's end, and every wash of a band in the end day's row.
    (Rect?, double) previewOf(WidgetTester tester, String day) {
      final end = find.byKey(const ValueKey('frosted-preview-end'));
      final at = tester.getRect(find.text(day));
      final t = tester
          .element(find.byType(FrostedDateRangePicker))
          .frostedTheme;
      var reach = double.negativeInfinity;
      for (final element
          in find
              .descendant(
                of: find.byType(FrostedDateRangePicker),
                matching: find.byType(ColoredBox),
              )
              .evaluate()) {
        if ((element.widget as ColoredBox).color != t.glass.wash) continue;
        final box = element.renderObject! as RenderBox;
        final r = box.localToGlobal(Offset.zero) & box.size;
        if (r.top < at.bottom && r.bottom > at.top) {
          reach = r.right > reach ? r.right : reach;
        }
      }
      return (end.evaluate().isEmpty ? null : tester.getRect(end), reach);
    }

    Future<TestGesture> rest(WidgetTester tester, String day) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(tester.getCenter(find.text(day)));
      await tester.pump();
      return mouse;
    }

    void endsAt(WidgetTester tester, String day, {bool rtl = false}) {
      final (end, reach) = previewOf(tester, day);
      expect(end, isNotNull, reason: 'the preview to the $day has an end');
      final centre = tester.getCenter(find.text(day)).dx;
      if (rtl) {
        expect(end!.left, closeTo(centre - cell / 2, .5));
      } else {
        expect(end!.right, closeTo(centre + cell / 2, .5));
        expect(
          reach <= end.right + .5,
          isTrue,
          reason: 'no band runs past the $day',
        );
      }
      expect(end.height, cell);
    }

    testWidgets('in the same week, in a later week, none before the start', (
      tester,
    ) async {
      await tester.pumpWidget(_stage(picker()));
      await tester.tap(find.text('10'));
      await tester.pump();
      final mouse = await rest(tester, '13');
      endsAt(tester, '13');
      await mouse.moveTo(tester.getCenter(find.text('20')));
      await tester.pump();
      endsAt(tester, '20');
      await mouse.moveTo(tester.getCenter(find.text('5')));
      await tester.pump();
      expect(previewOf(tester, '5').$1, isNull);
      await mouse.moveTo(tester.getCenter(find.text('10')));
      await tester.pump();
      expect(
        previewOf(tester, '10').$1,
        isNull,
        reason: 'a preview of the start alone draws no band',
      );
      await mouse.removePointer();
    });

    testWidgets('from the keyboard', (tester) async {
      await tester.pumpWidget(_stage(picker()));
      await tester.tap(find.text('10'));
      await tester.pump();
      // The grid is one tab stop; a tap chooses a day without taking the
      // keyboard, so the keyboard is put on the grid first.
      tester
          .widget<Focus>(
            find
                .descendant(
                  of: find.byType(FrostedDateRangePicker),
                  matching: find.byWidgetPredicate(
                    (w) => w is Focus && w.onKeyEvent != null,
                  ),
                )
                .first,
          )
          .focusNode!
          .requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      endsAt(tester, '12');
    });

    testWidgets('right to left', (tester) async {
      await tester.pumpWidget(_stage(picker(), direction: TextDirection.rtl));
      await tester.tap(find.text('10'));
      await tester.pump();
      final mouse = await rest(tester, '13');
      endsAt(tester, '13', rtl: true);
      await mouse.removePointer();
    });
  });
}
