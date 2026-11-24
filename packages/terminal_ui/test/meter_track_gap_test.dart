// After a meter's fill, its first dot stands one dot gap away, the gap
// between two of its dots, whatever eighth of a cell the fill ends on: the
// docs' meter page showed about 9 px after a part block against 5 between
// dots. The dots follow the fill at the cells' pitch, one for each whole
// cell the fill leaves, inside the bar.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'faces.dart';

class _Recorder implements Canvas {
  final rects = <Rect>[];
  final dots = <(Offset, double)>[];

  @override
  void drawRect(Rect rect, Paint paint) => rects.add(rect);

  @override
  void drawCircle(Offset c, double radius, Paint paint) =>
      dots.add((c, radius));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(loadFaces);

  for (final width in const [390.0, 1440.0]) {
    for (final (time, theme) in const [
      ('day', TermThemeData.light),
      ('night', TermThemeData.dark),
    ]) {
      for (final direction in TextDirection.values) {
        for (final value in const [0.0, 0.25, 0.5, 0.72, 0.99, 1.0]) {
          testWidgets('a meter ${(value * 100).round()}% full at '
              '${width.round()}, $time, ${direction.name}: one dot gap '
              'after its fill', (tester) async {
            tester.view.physicalSize = Size(width, 800);
            tester.view.devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(
              MaterialApp(
                home: Directionality(
                  textDirection: direction,
                  child: TermTheme(
                    data: theme(),
                    child: Center(
                      child: TermMeter(value: value, label: 'disk'),
                    ),
                  ),
                ),
              ),
            );
            final bar = find.descendant(
              of: find.byType(TermMeter),
              matching: find.byWidgetPredicate(
                (w) => w is CustomPaint && w.painter is TermBlocksPainter,
              ),
            );
            final painter =
                tester.widget<CustomPaint>(bar).painter! as TermBlocksPainter;
            final size = tester.getSize(bar);
            final canvas = _Recorder();
            painter.paint(canvas, size);
            final rtl = direction == TextDirection.rtl;
            // From the bar's start, the way it fills.
            double along(double x) => rtl ? size.width - x : x;
            final dots = [for (final (c, r) in canvas.dots) (along(c.dx), r)]
              ..sort((a, b) => a.$1.compareTo(b.$1));
            // Where the fill ends; the bar's start when it is empty.
            final end = canvas.rects.isEmpty
                ? 0.0
                : along(
                    rtl ? canvas.rects.single.left : canvas.rects.single.right,
                  );
            final cw = painter.grid.cellWidth;
            final cells = (size.width / cw + 1e-6).floor();
            final eighths = (cells * 8 * value).round();
            expect(dots, hasLength(cells - (eighths / 8).ceil()));
            for (final (x, r) in dots) {
              expect(x - r, greaterThanOrEqualTo(end), reason: 'past the fill');
              expect(x + r, lessThanOrEqualTo(size.width + .5), reason: 'in');
            }
            if (dots.length < 2) return;
            final r = dots.first.$2;
            final between = dots[1].$1 - dots[0].$1 - 2 * r;
            final after = dots.first.$1 - r - end;
            expect(
              after,
              moreOrLessEquals(between, epsilon: .5),
              reason: 'after the fill $after, between dots $between',
            );
          });
        }
      }
    }
  }
}
