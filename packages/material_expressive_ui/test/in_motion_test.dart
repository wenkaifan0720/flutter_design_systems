// design6 O: parts looked at mid-move, not only at rest. Each test drives the
// gesture (a drag held part-way, a pointer resting on a day, an animation
// pumped to half its duration) and reads what is on screen then.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:material_ui/material_ui.dart' show MaterialApp;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';
import 'package:material_expressive_ui/material_expressive_host.dart';

const _capture = ValueKey('capture');
const _paper = Color(0xFFFFFFFF);
const _slide = Color(0xFFD00000);

Widget _host(Widget child, {double width = 360, double height = 420}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: ExpressiveHost(
        light: ExpressiveThemeData.preset('baseline', Brightness.light),
        brightness: Brightness.light,
        child: Align(
          alignment: Alignment.topLeft,
          child: RepaintBoundary(
            key: _capture,
            child: ColoredBox(
              color: _paper,
              child: SizedBox(width: width, height: height, child: child),
            ),
          ),
        ),
      ),
    );

/// The captured frame, as RGBA bytes with its width.
Future<(ByteData, int)> _frame(WidgetTester tester) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_capture),
  );
  late ByteData bytes;
  late int width;
  await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      width = image.width;
      bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
    } finally {
      image.dispose();
    }
  });
  return (bytes, width);
}

Color _at((ByteData, int) frame, Offset p) {
  final (bytes, width) = frame;
  final i = (p.dy.floor() * width + p.dx.floor()) * 4;
  return Color.fromARGB(
    bytes.getUint8(i + 3),
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

bool _near(Color a, Color b) =>
    ((a.r - b.r).abs() + (a.g - b.g).abs() + (a.b - b.b).abs()) < 0.03;

void main() {
  // Drawn pixels are the rasterizer's, as a golden's: macOS runs each test.
  group('carousel', () {
    for (final (name, carousel) in <(String, Widget)>[
      (
        'uncontained',
        ExpressiveCarouselView.uncontained(
          itemCount: 6,
          itemWidth: 200,
          itemSpacing: 8,
          itemBuilder: (context, i) => const ColoredBox(color: _slide),
        ),
      ),
      (
        'multi-browse',
        ExpressiveCarouselView.multiBrowse(
          itemCount: 6,
          preferredItemWidth: 220,
          itemSpacing: 8,
          itemBuilder: (context, i) => const ColoredBox(color: _slide),
        ),
      ),
      (
        'hero',
        ExpressiveCarouselView.hero(
          itemCount: 6,
          itemSpacing: 8,
          itemBuilder: (context, i) => const ColoredBox(color: _slide),
        ),
      ),
    ]) {
      testWidgets('$name: a slide crossing the frame mid-swipe keeps its '
          'corners there', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = const Size(360, 420);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(_host(carousel, height: 200));
        await tester.pumpAndSettle();
        final drag = await tester.startGesture(const Offset(180, 100));
        await drag.moveBy(const Offset(-20, 0));
        await tester.pump();
        // 30% and 70% through a 200dp slide, the pointer still down.
        for (final step in const [60.0, 80.0]) {
          await drag.moveBy(Offset(-step, 0));
          await tester.pump();
          final frame = await _frame(tester);
          // The slide leaving on the left is cut by the frame...
          expect(
            _near(_at(frame, const Offset(1, 100)), _slide),
            isTrue,
            reason: '$name: a slide crosses the left edge mid-swipe',
          );
          // ...in its own corner: the frame's corner is not painted.
          for (final corner in const [Offset(1, 1), Offset(1, 198)]) {
            expect(
              _at(frame, corner),
              isSameColorAs(_paper),
              reason: '$name: the frame cut the moving slide square at $corner',
            );
          }
        }
        await drag.up();
        await tester.pumpAndSettle();
      }, tags: const ['goldens']);
    }
  });

  testWidgets("swipe to dismiss: mid-drag, the band fills the row's slot in "
      "the row's own corners", (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 420);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _host(
        Padding(
          padding: const EdgeInsets.all(16),
          child: ExpressiveListSection(
            children: <Widget>[
              for (final name in const ['Studio rent', 'Book club'])
                ExpressiveSwipeToDismiss(
                  key: ValueKey<String>(name),
                  onDismissed: (_) {},
                  child: ExpressiveListTile(title: Text(name), onTap: () {}),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final slot = tester.getRect(find.byType(ExpressiveSwipeToDismiss).first);
    final drag = await tester.startGesture(slot.center);
    await drag.moveBy(const Offset(-20, 0));
    await tester.pump();
    await drag.moveBy(const Offset(-100, 0));
    await tester.pump();
    final frame = await _frame(tester);
    expect(
      _near(_at(frame, Offset(slot.right - 40, slot.center.dy)), _paper),
      isFalse,
      reason: 'the band shows where the row left',
    );
    // The first row of a section rounds its top by 16dp: the slot's top
    // end corner is the band's too.
    expect(
      _at(frame, Offset(slot.right - 2, slot.top + 2)),
      isSameColorAs(_paper),
      reason: "the band's corner is square under a round row",
    );
    await drag.moveBy(const Offset(100, 0));
    await drag.up();
    await tester.pumpAndSettle();
  }, tags: const ['goldens']);

  group('mid-move: nothing overflows or throws, neighbours hold', () {
    late BuildContext page;
    Widget host(Widget child) => _host(
      Builder(
        builder: (context) {
          page = context;
          return Padding(padding: const EdgeInsets.all(16), child: child);
        },
      ),
      width: 390,
      height: 844,
    );

    // Frames 16, 76, 196 and 396ms in: the springs' early, middle and late.
    Future<void> through(WidgetTester tester, String what) async {
      var at = 0;
      for (final ms in const [16, 60, 120, 200]) {
        await tester.pump(Duration(milliseconds: ms));
        at += ms;
        expect(tester.takeException(), isNull, reason: '$what at ${at}ms');
      }
    }

    testWidgets('a bottom sheet opening, dragged and closing', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const SizedBox.expand()));
      showExpressiveBottomSheet<void>(
        page,
        builder: (context) => Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (var i = 1; i <= 4; i++)
              ExpressiveListTile(title: Text('Sheet row $i')),
          ],
        ),
      );
      await through(tester, 'opening');
      await tester.pumpAndSettle();
      final drag = await tester.startGesture(
        tester.getCenter(find.text('Sheet row 1')),
      );
      await drag.moveBy(const Offset(0, 20));
      await tester.pump();
      await drag.moveBy(const Offset(0, 80));
      await tester.pump();
      expect(tester.takeException(), isNull, reason: 'dragged');
      await drag.up();
      await tester.pumpAndSettle();
      Navigator.of(page).pop();
      await through(tester, 'closing');
      await tester.pumpAndSettle();
    });

    testWidgets('a dialog and a menu opening and closing', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const SizedBox.expand()));
      showExpressiveDialog<void>(
        context: page,
        builder: (context) => const Center(
          child: SizedBox(
            width: 280,
            height: 160,
            child: ColoredBox(color: _slide),
          ),
        ),
      );
      await through(tester, 'dialog opening');
      await tester.pumpAndSettle();
      Navigator.of(page).pop();
      await through(tester, 'dialog closing');
      await tester.pumpAndSettle();
      showExpressiveMenu(
        page,
        anchor: const Rect.fromLTWH(24, 24, 120, 40),
        entries: <ExpressiveMenuEntry>[
          for (final label in const ['Edit', 'Share', 'Delete'])
            ExpressiveMenuItem(label, onPressed: () {}),
        ],
      );
      await through(tester, 'menu opening');
      await tester.pumpAndSettle();
      Navigator.of(page).pop();
      await through(tester, 'menu closing');
      await tester.pumpAndSettle();
    });

    testWidgets('a snackbar entering and leaving', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const SizedBox.expand()));
      showExpressiveSnackBar(
        page,
        'Trip saved',
        actionLabel: 'Undo',
        onAction: () {},
      );
      await through(tester, 'entering');
      await tester.pump(const Duration(seconds: 12));
      await through(tester, 'leaving');
      await tester.pumpAndSettle();
    });

    testWidgets('a switch, a segmented button and a disclosure half-way '
        'through their change', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var on = false;
      var span = 'day';
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ExpressiveSwitch(
                  value: on,
                  semanticLabel: 'Wi-Fi',
                  onChanged: (v) => setState(() => on = v),
                ),
                ExpressiveSegmentedButton<String>(
                  segments: const [
                    ExpressiveButtonSegment('day', 'Day'),
                    ExpressiveButtonSegment('week', 'Week'),
                  ],
                  value: span,
                  onChanged: (v) => setState(() => span = v),
                ),
                ExpressiveDisclosure(
                  title: const Text('Details'),
                  child: Column(
                    children: <Widget>[
                      for (var i = 1; i <= 4; i++)
                        ExpressiveListTile(title: Text('Detail $i')),
                    ],
                  ),
                ),
                const Text('Below', key: ValueKey('below')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(ExpressiveSwitch));
      await through(tester, 'switch');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Week'));
      await through(tester, 'segmented');
      await tester.pumpAndSettle();
      final closed = tester.getRect(find.byType(ExpressiveDisclosure));
      await tester.tap(find.text('Details'));
      await through(tester, 'disclosure opening');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Details'));
      // Half-closed: the panel's rows are clipped by the part, not drawn
      // past it over what follows.
      await tester.pump(const Duration(milliseconds: 120));
      final part = tester.getRect(find.byType(ExpressiveDisclosure));
      expect(part.height, greaterThan(closed.height));
      expect(tester.takeException(), isNull);
      await tester.pumpAndSettle();
      expect(
        tester.getRect(find.byType(ExpressiveDisclosure)).height,
        moreOrLessEquals(closed.height, epsilon: 0.5),
      );
    });

    testWidgets('a slider dragged to both ends', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      var value = 0.5;
      await tester.pumpWidget(
        host(
          StatefulBuilder(
            builder: (context, setState) => ExpressiveSlider(
              value: value,
              semanticLabel: 'Volume',
              onChanged: (v) => setState(() => value = v),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final track = tester.getRect(find.byType(ExpressiveSlider));
      final drag = await tester.startGesture(track.center);
      for (final dx in [track.width, -2 * track.width, track.width / 2]) {
        await drag.moveBy(Offset(dx, 0));
        await tester.pump(const Duration(milliseconds: 60));
        expect(tester.takeException(), isNull, reason: 'dragged by $dx');
      }
      await drag.up();
      await tester.pumpAndSettle();
    });

    testWidgets("a text field's label moving up: the next line stays put", (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        host(
          const Column(
            children: <Widget>[
              ExpressiveTextField(label: 'Trip name'),
              Text('Below', key: ValueKey('below')),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      final rest = tester.getTopLeft(find.byKey(const ValueKey('below')));
      await tester.tap(find.byType(ExpressiveTextField));
      var at = 0;
      for (final ms in const [16, 60, 120, 200]) {
        await tester.pump(Duration(milliseconds: ms));
        at += ms;
        expect(tester.takeException(), isNull);
        expect(
          tester.getTopLeft(find.byKey(const ValueKey('below'))),
          rest,
          reason: 'the line under the field moved at ${at}ms',
        );
      }
      await tester.pumpAndSettle();
    });
  });

  // Drawn pixels are the rasterizer's, as a golden's: macOS runs each test.
  group('date range preview', () {
    // March 2026 starts on a Sunday; the range waits at Tuesday the 10th.
    Widget calendar() => ExpressiveCalendar.range(
      firstDate: DateTime(2026),
      lastDate: DateTime(2026, 12, 31),
      currentDate: DateTime(2026, 3, 10),
      start: DateTime(2026, 3, 10),
      onChanged: (start, end) {},
    );

    Future<TestGesture> pointer(WidgetTester tester) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      return mouse;
    }

    Offset day(WidgetTester tester, int d) =>
        tester.getCenter(find.text('$d', findRichText: true).last);

    // Whether the band's wash is at [dx], [dy] from day [c]'s centre: against
    // the same column in the cell's own top margin, where nothing is drawn
    // (the band is the 40dp day's height in a 48dp cell). The points stay
    // off the digits (the test font draws a two-digit day 32px wide, so
    // nothing samples within 16px of a centre on its line) and outside a
    // focus ring's 22 to 25dp: a band at 26 before the centre (a 400dp
    // month's cells are 57 wide), the day's circle at (12, -14).
    bool washed((ByteData, int) frame, Offset c, double dx, double dy) =>
        !_near(
          _at(frame, c.translate(dx, dy)),
          _at(frame, c.translate(dx, -22.5)),
        );

    Future<void> expectEndsAt(
      WidgetTester tester,
      int end, {
      required List<int> beyond,
      String how = 'pointer',
    }) async {
      final frame = await _frame(tester);
      final c = day(tester, end);
      expect(
        washed(frame, c, -26, 0),
        isTrue,
        reason: '$how on $end: the band reaches it',
      );
      expect(
        washed(frame, c, 12, -14),
        isTrue,
        reason: "$how on $end: the band's end holds the day's circle",
      );
      // Inside the cell's band, outside the day's circle: a square end
      // (a whole cell of wash) paints it; a finished end's round cap does not.
      for (final (dx, dy) in const [(23.0, -19.0), (23.0, 19.0)]) {
        expect(
          washed(frame, c, dx, dy),
          isFalse,
          reason: "$how on $end: the band's end is round, not square",
        );
      }
      for (final d in beyond) {
        expect(
          washed(frame, day(tester, d), -26, 0),
          isFalse,
          reason: '$how on $end: nothing past it ($d)',
        );
      }
    }

    testWidgets('the band ends at the hovered day in the shape a finished '
        "range's end has: the same week, a later week", (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 520);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(calendar(), width: 400, height: 520));
      await tester.pumpAndSettle();
      final mouse = await pointer(tester);
      await mouse.moveTo(day(tester, 13));
      await tester.pumpAndSettle();
      await expectEndsAt(tester, 13, beyond: [14]);
      await mouse.moveTo(day(tester, 18));
      await tester.pumpAndSettle();
      await expectEndsAt(tester, 18, beyond: [19, 20]);
    }, tags: const ['goldens']);

    testWidgets('no band on the start itself, nor before it', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 520);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(calendar(), width: 400, height: 520));
      await tester.pumpAndSettle();
      final mouse = await pointer(tester);
      for (final at in const [10, 7]) {
        await mouse.moveTo(day(tester, at));
        await tester.pumpAndSettle();
        final frame = await _frame(tester);
        for (final d in const [11, 12]) {
          expect(
            washed(frame, day(tester, d), -26, 0),
            isFalse,
            reason: 'pointer on $at: no band at $d',
          );
        }
        expect(
          washed(frame, day(tester, 10), 23, -19),
          isFalse,
          reason: 'pointer on $at: no band leaves the start',
        );
      }
    }, tags: const ['goldens']);

    testWidgets('from the keyboard too', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(400, 520);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(_host(calendar(), width: 400, height: 520));
      await tester.pumpAndSettle();
      tester
          .widgetList<Focus>(find.byType(Focus))
          .map((f) => f.focusNode)
          .firstWhere((n) => n?.debugLabel == 'DesignCalendar')!
          .requestFocus();
      await tester.pump();
      for (var i = 0; i < 3; i++) {
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      }
      await tester.pumpAndSettle();
      await expectEndsAt(tester, 13, beyond: [14], how: 'keyboard');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      await expectEndsAt(tester, 20, beyond: [21], how: 'keyboard');
    }, tags: const ['goldens']);
  });
}
