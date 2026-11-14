// ignore_for_file: avoid_relative_lib_imports
// A focus ring is its part's outline moved by one distance, measured on what
// is painted. Every focusable part in every specimen (fields, buttons, chips,
// checks, radios, switches, the slider, segments, tabs, steppers, pages, menu
// items, rows, calendar and clock cells, dialog and sheet actions), in both
// appearances, is focused; its ring's painted path is
// recorded beside its face's outline, and the gap between them is read at the
// middle of each edge and along each corner's diagonal. A rounded or round
// corner keeps the gap; a square one keeps square, so its diagonal is the gap
// times the square root of two. Within half a pixel.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

import 'highlight_shape_test.dart' show nodeOf;
import 'shape_fit_test.dart' show shapeSpecimens;
import 'support.dart';

const appearances = <String, RetroDesktopAppearance>{
  'chisel': RetroDesktopAppearance.chisel,
  'platinum': RetroDesktopAppearance.platinum,
};

List<Offset> samples(Path path, [double step = .25]) => [
  for (final metric in path.computeMetrics())
    for (var s = 0.0; s <= metric.length; s += step)
      metric.getTangentForOffset(s)!.position,
];

Paint? paintOf(Invocation call) {
  for (final argument in call.positionalArguments.reversed) {
    if (argument is Paint) return argument;
  }
  return null;
}

/// The ring's edge that faces the part, as points: the contour of a filled
/// rim nearer the part, or a dotted ring's centre line. Null when nothing in
/// [color] was painted.
({List<Offset> points, bool dotted})? ringEdge(
  List<RecordedInvocation> calls,
  Color color,
  Rect face,
) {
  final drawn = <Invocation>[];
  // The ring is the last thing its painter draws. A Paint keeps its colour
  // in single precision, so colours are compared as 32-bit values.
  for (final call in calls.reversed) {
    final paint = paintOf(call.invocation);
    if (paint == null) continue;
    if (paint.color.toARGB32() != color.toARGB32()) break;
    drawn.add(call.invocation);
  }
  if (drawn.isEmpty) return null;
  if (drawn.length > 1) {
    return (
      points: [
        for (final call in drawn)
          if (call.memberName == #drawPath)
            ...samples(call.positionalArguments[0] as Path, .5),
      ],
      dotted: true,
    );
  }
  final call = drawn.single;
  final List<Path> contours;
  switch (call.memberName) {
    case #drawDRRect:
      contours = [
        Path()..addRRect(call.positionalArguments[0] as RRect),
        Path()..addRRect(call.positionalArguments[1] as RRect),
      ];
    case #drawCircle:
      // A round part's ring: a stroked circle spans half its width each side.
      final centre = call.positionalArguments[0] as Offset;
      final radius = call.positionalArguments[1] as double;
      final paint = call.positionalArguments[2] as Paint;
      final half = paint.style == PaintingStyle.stroke
          ? paint.strokeWidth / 2
          : 0;
      contours = [
        for (final r in {radius - half, radius + half})
          if (r > 0)
            Path()..addOval(Rect.fromCircle(center: centre, radius: r)),
      ];
    case #drawPath:
      final path = call.positionalArguments[0] as Path;
      contours = [
        for (final metric in path.computeMetrics())
          metric.extractPath(0, metric.length),
      ];
    default:
      return null;
  }
  if (contours.isEmpty) return null;
  contours.sort((a, b) => a.getBounds().width.compareTo(b.getBounds().width));
  final inside = contours.last.getBounds().width <= face.width + .5;
  return (
    points: samples(inside ? contours.last : contours.first),
    dotted: false,
  );
}

/// The point of [points] on the 45° line through [corner], nearest it.
Offset? onDiagonal(
  List<Offset> points,
  Offset corner,
  Offset towards,
  double band,
) {
  Offset? best;
  var bestReach = double.infinity;
  for (final p in points) {
    final dx = (p.dx - corner.dx) * towards.dx;
    final dy = (p.dy - corner.dy) * towards.dy;
    if ((dx - dy).abs() > band) continue;
    final reach = dx + dy;
    if (reach < bestReach) {
      bestReach = reach;
      best = p;
    }
  }
  return best;
}

/// The failures of one ring around [face] (the part's outline as its face
/// paints it), read at each edge's middle and each corner's diagonal.
List<String> measure(Path face, ({List<Offset> points, bool dotted}) ring) {
  final failures = <String>[];
  final box = face.getBounds();
  final outline = samples(face);
  final band = ring.dotted ? 1.3 : .3;
  double? extreme(List<Offset> points, bool vertical, double at, bool least) {
    double? out;
    for (final p in points) {
      if (((vertical ? p.dx : p.dy) - at).abs() > band) continue;
      final v = vertical ? p.dy : p.dx;
      if (out == null || (least ? v < out : v > out)) out = v;
    }
    return out;
  }

  final edges = <double>[];
  for (final (vertical, at, least) in [
    (true, box.center.dx, true),
    (true, box.center.dx, false),
    (false, box.center.dy, true),
    (false, box.center.dy, false),
  ]) {
    final a = extreme(outline, vertical, at, least);
    final b = extreme(ring.points, vertical, at, least);
    if (a == null || b == null) continue;
    edges.add((a - b).abs());
  }
  if (edges.isEmpty) return ['no edge to measure'];
  final gap = edges.reduce(math.max);
  if (edges.any((e) => (e - gap).abs() > .5)) {
    failures.add('edges ${edges.map((e) => e.toStringAsFixed(2)).join('/')}');
  }
  // A dotted ring may be off at a corner: its corner is where its dots'
  // lines meet.
  final dots = ring.dotted
      ? ring.points
            .skip(1)
            .fold(
              Rect.fromPoints(ring.points.first, ring.points.first),
              (r, p) => r.expandToInclude(Rect.fromPoints(p, p)),
            )
      : null;
  for (final (name, corner, towards, dotCorner) in [
    ('top start', box.topLeft, const Offset(1, 1), dots?.topLeft),
    ('top end', box.topRight, const Offset(-1, 1), dots?.topRight),
    ('bottom start', box.bottomLeft, const Offset(1, -1), dots?.bottomLeft),
    ('bottom end', box.bottomRight, const Offset(-1, -1), dots?.bottomRight),
  ]) {
    final a = onDiagonal(outline, corner, towards, .3);
    if (a == null) continue;
    final square = (a - corner).distance < .5;
    final b = square && dotCorner != null
        ? dotCorner
        : onDiagonal(ring.points, corner, towards, band);
    if (b == null) continue;
    final want = square ? gap * math.sqrt2 : gap;
    final got = (a - b).distance;
    if ((got - want).abs() > (square ? .5 * math.sqrt2 : .5)) {
      failures.add(
        '$name corner ${square ? 'square' : 'round'}: '
        '${got.toStringAsFixed(2)} along the diagonal, want ${want.toStringAsFixed(2)}',
      );
    }
  }
  return failures;
}

/// Every ring painted now, each with the outline of the part it surrounds.
List<(String, Path, List<RecordedInvocation>, Color, Color?)> rings(
  WidgetTester tester,
) {
  final out = <(String, Path, List<RecordedInvocation>, Color, Color?)>[];
  // The highlight is a custom paint of its own kind (it hands its painter the
  // device's grid): found as any CustomPaint, not by its exact type.
  for (final element
      in find.byWidgetPredicate((w) => w is CustomPaint).evaluate()) {
    final widget = element.widget as CustomPaint;
    final size = (element.renderObject! as RenderBox).size;
    for (final CustomPainter? painter in [
      widget.foregroundPainter,
      widget.painter,
    ]) {
      if (painter == null) continue;
      final dynamic p = painter;
      final kind = painter.runtimeType.toString();
      if (kind != '_HighlightPainter' && kind != '_SliderPainter') continue;
      final ring = p.ring as RetroDesktopFocusRing?;
      if (ring == null || ring.width <= 0) continue;
      if (kind == '_HighlightPainter' &&
          ((p.skip as RetroDesktopHighlightClaim?)?.claimed ?? false)) {
        continue;
      }
      final canvas = TestRecordingCanvas();
      painter.paint(canvas, size);
      Path face;
      if (kind == '_HighlightPainter') {
        // The ring stands round the face as drawn: the part's box on the
        // device's grid (the view is at one device pixel per logical one), as
        // the face's own painter and the ring's both snap it.
        final at = (element.renderObject! as RenderBox).localToGlobal(
          Offset.zero,
        );
        double edge(double v) => v.roundToDouble();
        face = (p.shape as OutlinedBorder).getOuterPath(
          Rect.fromLTRB(
            edge(at.dx) - at.dx,
            edge(at.dy) - at.dy,
            edge(at.dx + size.width) - at.dx,
            edge(at.dy + size.height) - at.dy,
          ),
        );
      } else if (p.chisel as bool) {
        face = Path()..addRect(Offset.zero & size);
      } else {
        // The thumb: the one shape painted 18 by 26.
        final thumb = canvas.invocations
            .map((c) => c.invocation)
            .where((c) => c.memberName == #drawPath)
            .map((c) => c.positionalArguments[0] as Path)
            .where((path) {
              final b = path.getBounds();
              return (b.width - 18).abs() < .5 && (b.height - 26).abs() < .5;
            });
        if (thumb.isEmpty) continue;
        face = thumb.first;
      }
      // A ring inside its face may take the label's colour where the theme's
      // would vanish (Chisel's dots, a ring inside an accent-filled cell).
      final Color? inside = kind == '_HighlightPainter'
          ? p.insideColor as Color?
          : null;
      out.add((kind, face, canvas.invocations, ring.color, inside));
    }
  }
  return out;
}

void main() {
  setUpAll(loadRetroDesktopFonts);

  for (final appearance in appearances.entries) {
    testWidgets('${appearance.key}: every ring is its part moved by one gap', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );
      final theme = RetroDesktopThemeData.classic().copyWith(
        appearance: appearance.value,
      );
      final failures = <String>[];
      var measured = 0;
      for (final specimen in shapeSpecimens.entries) {
        if (specimen.key == 'kitSpecimenScreen') continue;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) =>
                RetroDesktopTheme(data: theme, child: child!),
            home: SingleChildScrollView(
              child: KeyedSubtree(
                key: ValueKey(specimen.key),
                child: specimen.value(),
              ),
            ),
          ),
        );
        await tester.pump();
        final nodes = <FocusNode>[];
        for (final press in find.byType(RetroDesktopPressable).evaluate()) {
          final node = nodeOf(press);
          if (node != null && node.canRequestFocus) nodes.add(node);
        }
        for (final field in find.byType(EditableText).evaluate()) {
          final node = (field.widget as EditableText).focusNode;
          if (node.canRequestFocus) nodes.add(node);
        }
        for (var i = 0; i < nodes.length; i++) {
          final node = nodes[i];
          if (node.context == null || !node.context!.mounted) continue;
          node.requestFocus();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 400));
          for (final (kind, face, calls, color, inside) in rings(tester)) {
            final bounds = face.getBounds();
            if (bounds.bottom < 0 || bounds.top > 1600) continue;
            final edge =
                ringEdge(calls, color, bounds) ??
                (inside == null ? null : ringEdge(calls, inside, bounds));
            if (edge == null) {
              failures.add(
                '${specimen.key} focus $i ($kind): no ring read from '
                '${calls.map((c) => c.invocation.memberName).join(' ')}',
              );
              continue;
            }
            measured++;
            for (final failure in measure(face, edge)) {
              failures.add('${specimen.key} focus $i ($kind): $failure');
            }
          }
          node.unfocus();
          await tester.pump();
        }
        expect(tester.takeException(), isNull, reason: specimen.key);
      }
      debugPrint('CONCENTRIC ${appearance.key}: $measured rings measured');
      expect(measured, greaterThan(60));
      expect(failures, isEmpty, reason: failures.join('\n'));
    });
  }

  test('the measure itself: a square ring around a square part', () {
    final face = Path()..addRect(const Rect.fromLTWH(10, 10, 40, 20));
    final ring = Path()..addRect(const Rect.fromLTWH(7, 7, 46, 26));
    expect(measure(face, (points: samples(ring), dotted: false)), isEmpty);
    final rounded = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 7, 46, 26),
          const Radius.circular(3),
        ),
      );
    expect(
      measure(face, (points: samples(rounded), dotted: false)),
      isNotEmpty,
    );
  });

  test('the measure itself: a rounded ring around a rounded part', () {
    final face = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 10, 40, 20),
          const Radius.circular(4),
        ),
      );
    final ring = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 7, 46, 26),
          const Radius.circular(7),
        ),
      );
    expect(measure(face, (points: samples(ring), dotted: false)), isEmpty);
    final tight = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(7, 7, 46, 26),
          const Radius.circular(4),
        ),
      );
    expect(measure(face, (points: samples(tight), dotted: false)), isNotEmpty);
  });
}
