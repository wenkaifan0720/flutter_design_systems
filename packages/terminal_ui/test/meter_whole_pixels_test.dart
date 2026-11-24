// A bar of blocks stands on whole pixels, as a terminal's block glyphs do:
// an edge astride two pixels paints one of them at part strength, a soft
// line along the bar. Its cells are each a block or a dot.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_ui/terminal_ui.dart';

class _Recorder implements Canvas {
  final rects = <Rect>[];
  final dots = <Offset>[];

  @override
  void drawRect(Rect rect, Paint paint) => rects.add(rect);

  @override
  void drawCircle(Offset c, double radius, Paint paint) => dots.add(c);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

bool _whole(double v) => (v - v.roundToDouble()).abs() < 1e-9;

void main() {
  for (final direction in TextDirection.values) {
    for (final (font, cells, value) in const [
      (15.0, 17, 0.25),
      (15.0, 20, 0.33),
      (15.5, 17, 5 / 17),
      (19.5, 13, 0.6),
    ]) {
      test(
        'a bar ${(value * 100).round()}% full of $cells cells at ${font}px, '
        '${direction.name}, stands on whole pixels, each cell a block or a dot',
        () {
          final grid = TermGrid(fontSize: font, lineHeight: font * 1.6);
          final size = Size(grid.cols(cells), grid.lineHeight);
          final canvas = _Recorder();
          TermBlocksPainter(
            grid: grid,
            value: value,
            color: const Color(0xFF2F6E2F),
            track: const Color(0xFF999999),
            textDirection: direction,
          ).paint(canvas, size);
          expect(canvas.rects, hasLength(1));
          final bar = canvas.rects.single;
          final moving = direction == TextDirection.ltr ? bar.right : bar.left;
          expect(
            [moving, bar.top, bar.bottom].every(_whole),
            isTrue,
            reason: 'the bar $bar has an edge astride a pixel',
          );
          final eighths = (cells * 8 * value).round();
          expect(canvas.dots, hasLength(cells - (eighths / 8).ceil()));
        },
      );
    }
  }
}
