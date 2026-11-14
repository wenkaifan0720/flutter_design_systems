// Minimal's parts between states (design6 O, "In motion"): what is on screen
// mid-move, read from the pixels a frame paints, not from the widget tree.
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

final MinimalThemeData _light = MinimalThemeData.preset(
  'standard',
  Brightness.light,
);
const Key _frame = Key('frame');

Widget _host(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  builder: (context, navigator) => MinimalHost(
    light: _light,
    dark: MinimalThemeData.preset('standard', Brightness.dark),
    brightness: Brightness.light,
    child: RepaintBoundary(key: _frame, child: navigator!),
  ),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void _phone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(390, 844)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

/// The frame as painted, to read a pixel at a global position.
class _Shot {
  _Shot(this.width, this.bytes);

  final int width;
  final ByteData bytes;

  static Future<_Shot> take(WidgetTester tester) async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(_frame),
    );
    late _Shot shot;
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
      shot = _Shot(image.width, data!);
      image.dispose();
    });
    return shot;
  }

  Color at(Offset p) {
    final i = (p.dy.floor() * width + p.dx.floor()) * 4;
    return Color.fromARGB(
      bytes.getUint8(i + 3),
      bytes.getUint8(i),
      bytes.getUint8(i + 1),
      bytes.getUint8(i + 2),
    );
  }
}

bool _near(Color a, Color b, [int tolerance = 3]) {
  int c(double v) => (v * 255).round();
  return (c(a.r) - c(b.r)).abs() <= tolerance &&
      (c(a.g) - c(b.g)).abs() <= tolerance &&
      (c(a.b) - c(b.b)).abs() <= tolerance;
}

Matcher _isColor(Color want) => predicate<Color>(
  (got) => _near(got, want),
  'the colour ${want.toARGB32().toRadixString(16)}',
);

Matcher _isNotColor(Color avoid) => predicate<Color>(
  (got) => !_near(got, avoid),
  'not the colour ${avoid.toARGB32().toRadixString(16)}',
);

void main() {
  group('a carousel, mid-swipe', () {
    const slides = [Color(0xFF1D4ED8), Color(0xFF15803D), Color(0xFFB91C1C)];

    for (final through in const [0.3, 0.7]) {
      testWidgets('${(through * 100).round()}% through, the cut slide keeps '
          'its corners', (tester) async {
        _phone(tester);
        await tester.pumpWidget(
          _host(
            MinimalCarouselView(
              height: 200,
              showControls: false,
              children: [for (final c in slides) ColoredBox(color: c)],
            ),
          ),
        );
        await tester.pumpAndSettle();
        final view = tester.getRect(find.byType(PageView));
        final drag = await tester.startGesture(view.center);
        await drag.moveBy(const Offset(-20, 0));
        await drag.moveBy(Offset(-(view.width * through - 20), 0));
        await tester.pump();
        final shot = await _Shot.take(tester);
        // The incoming slide reaches the frame's end edge...
        expect(
          shot.at(Offset(view.right - 2, view.center.dy)),
          _isColor(slides[1]),
        );
        // ...and the frame's corners round it there, as at rest.
        for (final corner in [
          Offset(view.right - 1, view.top + 1),
          Offset(view.right - 1, view.bottom - 2),
          Offset(view.left + 1, view.top + 1),
        ]) {
          for (final slide in slides) {
            expect(shot.at(corner), _isNotColor(slide), reason: '$corner');
          }
        }
        await drag.up();
        await tester.pumpAndSettle();
      }, tags: 'goldens');
    }

    testWidgets('the long dot travels with the swipe, round the ring when it '
        'loops', (tester) async {
      _phone(tester);
      for (final loop in const [false, true]) {
        await tester.pumpWidget(
          _host(
            MinimalCarouselView(
              key: ValueKey(loop),
              height: 200,
              loop: loop,
              children: [for (final c in slides) ColoredBox(color: c)],
            ),
          ),
        );
        await tester.pumpAndSettle();
        // The dots themselves, 6 px tall (the pressables around them
        // animate boxes of their own).
        List<double> dots() => [
          for (final e
              in find
                  .descendant(
                    of: find.byType(MinimalPageDots),
                    matching: find.byType(AnimatedContainer),
                  )
                  .evaluate())
            if ((e.renderObject! as RenderBox).size.height == 6)
              (e.renderObject! as RenderBox).size.width,
        ];
        expect(dots(), [18, 6, 6], reason: 'at rest, loop: $loop');
        final view = tester.getRect(find.byType(PageView));
        // Half way to the next slide; looping, half way back past the first
        // to the last.
        final toward = loop ? 1.0 : -1.0;
        final drag = await tester.startGesture(view.center);
        await drag.moveBy(Offset(20 * toward, 0));
        await drag.moveBy(Offset((view.width / 2 - 20) * toward, 0));
        await tester.pump();
        final w = dots();
        final sharing = loop ? [w[0], w[2]] : [w[0], w[1]];
        for (final width in sharing) {
          expect(
            width,
            inInclusiveRange(9, 15),
            reason: 'mid-swipe, loop: $loop, dots $w',
          );
        }
        await drag.up();
        await tester.pumpAndSettle();
      }
    });
  });

  group('a date range, previewing its end', () {
    Future<void> openOnTenth(WidgetTester tester) async {
      _phone(tester);
      await tester.pumpWidget(
        _host(
          MinimalDateRangePicker(
            label: 'Stay',
            firstDate: DateTime(2026),
            lastDate: DateTime(2027),
            today: DateTime(2026, 8, 3),
            onChanged: (_) {},
          ),
        ),
      );
      await tester.tap(find.byType(MinimalDateRangePicker));
      await tester.pumpAndSettle();
      // August 2026 starts on a Saturday; the weeks run Sunday to Saturday.
      // The picker may show two months: August's days are the first.
      await tester.tap(find.text('10').first);
      await tester.pumpAndSettle();
    }

    /// The day [n]'s mark and its whole cell.
    (Rect, Rect) day(WidgetTester tester, String n) {
      final text = find.text(n).first;
      return (
        tester.getRect(
          find.ancestor(of: text, matching: find.byType(Container)).first,
        ),
        tester.getRect(
          find.ancestor(of: text, matching: find.byType(Stack)).first,
        ),
      );
    }

    Future<void> hover(WidgetTester tester, String n) async {
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text(n).first));
      await tester.pump();
    }

    /// The band runs in from the start's side and ends on [n]'s mark: the
    /// band on that side of the cell, the ground on the other, the mark's
    /// corner round (no band in it) and its edge in the accent.
    Future<void> endsOn(WidgetTester tester, String n) async {
      final (mark, cell) = day(tester, n);
      final shot = await _Shot.take(tester);
      final band = _light.muted;
      expect(shot.at(Offset(cell.left + 1, mark.center.dy)), _isColor(band));
      expect(
        shot.at(Offset(cell.right - 2, mark.center.dy)),
        _isNotColor(band),
      );
      expect(shot.at(Offset(mark.right - 1, mark.top + 1)), _isNotColor(band));
      // The hairline edge, antialiased: toward the accent, off the band.
      final edge = shot.at(Offset(mark.center.dx, mark.top + 0.5));
      expect(edge, _isNotColor(band));
      expect(_near(edge, _light.primary, 110), isTrue, reason: '$edge');
    }

    testWidgets('a later day in the same week', (tester) async {
      await openOnTenth(tester);
      await hover(tester, '13');
      await endsOn(tester, '13');
    }, tags: 'goldens');

    testWidgets('a day in a later week', (tester) async {
      await openOnTenth(tester);
      await hover(tester, '20');
      await endsOn(tester, '20');
    }, tags: 'goldens');

    testWidgets('before the start, no preview at all', (tester) async {
      await openOnTenth(tester);
      await hover(tester, '6');
      final (mark, cell) = day(tester, '6');
      final shot = await _Shot.take(tester);
      final band = _light.muted;
      for (final x in [cell.left + 1, cell.right - 2, mark.center.dx]) {
        expect(shot.at(Offset(x, mark.center.dy)), _isNotColor(band));
      }
    }, tags: 'goldens');
  });
}
