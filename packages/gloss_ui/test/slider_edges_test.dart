// A slider's groove meets its column's edges, the edges the fields above it
// share (the shapes its painter draws reach them), and its bead stands flush with them at either end: a slider and a
// range slider, left to right and right to left. Each bead keeps a finger's
// square to press.
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gloss_ui/gloss_ui.dart';

const _width = 360.0;

Future<void> _show(WidgetTester t, Widget slider, TextDirection dir) async {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = const Size(_width + 80, 300);
  addTearDown(t.view.reset);
  final data = GlossThemeData.preset('jade', Brightness.light);
  await t.pumpWidget(
    Directionality(
      textDirection: dir,
      child: GlossTheme(
        data: data,
        child: ColoredBox(
          color: data.colors.page,
          child: Center(
            child: SizedBox(width: _width, child: slider),
          ),
        ),
      ),
    ),
  );
  await t.pumpAndSettle();
}

/// What a painter draws, its bounds in its own box: each shape a draw call
/// is given, through the canvas's translations and mirrorings, no taller
/// than [height] (the groove's face, not the soft light round it).
class _Bounds implements Canvas {
  _Bounds(this.height);

  final double height;
  Rect? drawn;
  final List<(double, double, double)> _stack = [];
  double _dx = 0, _sx = 1, _dy = 0;

  void _add(Rect r) {
    if (r.height > height + .5) return;
    final a = _sx * r.left + _dx, b = _sx * r.right + _dx;
    final m = Rect.fromLTRB(
      a < b ? a : b,
      r.top + _dy,
      a < b ? b : a,
      r.bottom + _dy,
    );
    drawn = drawn == null ? m : drawn!.expandToInclude(m);
  }

  @override
  void save() => _stack.add((_dx, _sx, _dy));

  @override
  void saveLayer(Rect? bounds, Paint paint) => save();

  @override
  void restore() {
    final (dx, sx, dy) = _stack.removeLast();
    _dx = dx;
    _sx = sx;
    _dy = dy;
  }

  @override
  void translate(double dx, double dy) {
    _dx += _sx * dx;
    _dy += dy;
  }

  @override
  void scale(double sx, [double? sy]) => _sx *= sx;

  @override
  void drawRect(Rect rect, Paint paint) => _add(rect);

  @override
  void drawRRect(RRect rrect, Paint paint) => _add(rrect.outerRect);

  @override
  void drawDRRect(RRect outer, RRect inner, Paint paint) =>
      _add(outer.outerRect);

  @override
  void drawPath(Path path, Paint paint) => _add(path.getBounds());

  @override
  void drawShadow(Path path, Color color, double elevation, bool occluder) {}

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// The groove a slider paints runs from its column's start to its end.
void _grooveMeetsEdges(WidgetTester t, Finder slider) {
  final column = t.getRect(slider);
  final groove = find
      .descendant(of: slider, matching: find.byType(CustomPaint))
      .evaluate()
      .map((e) => e.renderObject! as RenderCustomPaint)
      .firstWhere((r) => '${r.painter.runtimeType}'.contains('Groove'));
  final record = _Bounds(groove.size.height);
  groove.painter!.paint(record, groove.size);
  final drawn = record.drawn!.shift(groove.localToGlobal(Offset.zero));
  expect(drawn.left, moreOrLessEquals(column.left, epsilon: .5));
  expect(drawn.right, moreOrLessEquals(column.right, epsilon: .5));
}

/// The 28 square beads, start to end.
List<Rect> _beads(WidgetTester t, Finder slider) {
  final rects = [
    for (final e
        in find
            .descendant(of: slider, matching: find.byType(GlossSurface))
            .evaluate())
      t.getRect(find.byElementPredicate((x) => identical(x, e))),
  ].where((r) => (r.width - 28).abs() < .5 && (r.height - 28).abs() < .5);
  return rects.toList()..sort((a, b) => a.left.compareTo(b.left));
}

void main() {
  for (final dir in TextDirection.values) {
    testWidgets(
      "a slider's groove meets the column, its bead flush (${dir.name})",
      (t) async {
        await _show(t, GlossSlider(value: .4, onChanged: (_) {}), dir);
        _grooveMeetsEdges(t, find.byType(GlossSlider));
        for (final v in [0.0, 1.0]) {
          await _show(t, GlossSlider(value: v, onChanged: (_) {}), dir);
          final column = t.getRect(find.byType(GlossSlider));
          final bead = _beads(t, find.byType(GlossSlider)).single;
          final atStart = (v == 0) == (dir == TextDirection.ltr);
          if (atStart) {
            expect(bead.left, moreOrLessEquals(column.left, epsilon: .5));
          } else {
            expect(bead.right, moreOrLessEquals(column.right, epsilon: .5));
          }
        }
      },
    );

    testWidgets(
      "a range slider's groove meets the column, its beads flush (${dir.name})",
      (t) async {
        await _show(
          t,
          GlossRangeSlider(
            values: const GlossRangeValues(0, 1),
            onChanged: (_) {},
          ),
          dir,
        );
        _grooveMeetsEdges(t, find.byType(GlossRangeSlider));
        final column = t.getRect(find.byType(GlossRangeSlider));
        final beads = _beads(t, find.byType(GlossRangeSlider));
        expect(beads, hasLength(2));
        expect(beads.first.left, moreOrLessEquals(column.left, epsilon: .5));
        expect(beads.last.right, moreOrLessEquals(column.right, epsilon: .5));
      },
    );
  }

  testWidgets('a press at the very start of the slider sets its least', (
    t,
  ) async {
    double? got;
    await _show(
      t,
      GlossSlider(value: .5, onChanged: (v) => got = v),
      TextDirection.ltr,
    );
    final column = t.getRect(find.byType(GlossSlider));
    await t.tapAt(column.centerLeft + const Offset(2, 0));
    expect(got, 0);
    await t.tapAt(column.centerRight - const Offset(2, 0));
    expect(got, 1);
  });
}
