// What every bevel stands on: the device's pixel grid. A browser snaps a box's edges when it paints and Flutter doesn't, so
// a 1 px bevel at a fractional position blurs into two faint lines. `RetroDesktopPixelPaint` is `CustomPaint` for this look: it reads
// where its box really stands on the device (through scroll offsets, layers and transforms, which the canvas's own transform
// doesn't show), and `RetroDesktopPixelGrid` draws its rectangles on whole device pixels, at any position, at any scale, on any engine.
// Don't rely on `isAntiAlias: false`: Impeller ignores it.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'theme.dart';

/// A CSS `blur` as Flutter's `blurRadius`: CSS blur B is sigma B/2, Flutter's radius r is sigma .57735 r + .5.
double retroDesktopBlur(double css) => (css / 2 - .5) / .57735;

/// What a `RetroDesktopPixelPaint` draws: through [RetroDesktopPixelGrid], so it lands on the grid.
abstract class RetroDesktopPixelPainter {
  /// Creates a [RetroDesktopPixelPainter].
  const RetroDesktopPixelPainter();

  /// Draws this part using its current data and pixel grid.
  void paint(RetroDesktopPixelGrid px, Size size);

  /// Whether the new painter changes any visible drawing input.
  bool shouldRepaint(covariant RetroDesktopPixelPainter old);
}

/// `CustomPaint` on the device's grid. It paints behind [child], or over it if [foreground].
///
/// ```dart
/// RetroDesktopPixelPaint(painter: painter, child: const SizedBox(width: 80, height: 40))
/// ```
class RetroDesktopPixelPaint extends SingleChildRenderObjectWidget {
  /// Creates a [RetroDesktopPixelPaint].
  const RetroDesktopPixelPaint({
    super.key,
    required this.painter,
    this.foreground = false,
    super.child,
  });

  /// The painter drawn behind the child.
  final RetroDesktopPixelPainter painter;

  /// Whether the painter is drawn over the child instead of behind it.
  final bool foreground;
  @override
  RenderRetroDesktopPixelPaint createRenderObject(BuildContext context) =>
      RenderRetroDesktopPixelPaint(painter, foreground);
  @override
  void updateRenderObject(
    BuildContext context,
    RenderRetroDesktopPixelPaint renderObject,
  ) {
    renderObject
      ..painter = painter
      ..foreground = foreground;
  }
}

/// Render object used by the corresponding desktop layout widget.
class RenderRetroDesktopPixelPaint extends RenderProxyBox {
  /// Creates a [RenderRetroDesktopPixelPaint].
  RenderRetroDesktopPixelPaint(this._painter, this._foreground);
  RetroDesktopPixelPainter _painter;

  /// Whether this painter draws over its child.
  bool get foreground => _foreground;
  bool _foreground;
  set foreground(bool value) {
    if (value == _foreground) return;
    _foreground = value;
    markNeedsPaint();
  }

  /// For a subclass that works its painter out as it paints: no repaint is asked for.
  void paintWith(RetroDesktopPixelPainter p) => _painter = p;

  set painter(RetroDesktopPixelPainter next) {
    if (identical(next, _painter)) return;
    final repaint =
        next.runtimeType != _painter.runtimeType ||
        next.shouldRepaint(_painter);
    _painter = next;
    if (repaint) markNeedsPaint();
  }

  void _draw(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    canvas.save();
    canvas.translate(offset.dx, offset.dy);
    _painter.paint(
      RetroDesktopPixelGrid._(canvas, _deviceTransform(), _ratio()),
      size,
    );
    canvas.restore();
  }

  Matrix4 _deviceTransform() => getTransformTo(null);

  double _ratio() {
    RenderObject top = this;
    while (top.parent != null) {
      top = top.parent!;
    }
    final ratio = top is RenderView ? top.flutterView.devicePixelRatio : 1.0;
    return ratio <= 0 ? 1 : ratio;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (!foreground) _draw(context, offset);
    if (child != null) context.paintChild(child!, offset);
    if (foreground) _draw(context, offset);
  }

  @override
  bool hitTestSelf(Offset position) => child == null;
}

/// Internal, not exported (apps draw on the grid through RetroDesktopPixelPaint): the device's grid under [box].
/// The focus ring's custom paint hands it to its painter, and stays a custom paint so a checker reading faces still
/// finds the face under it.
RetroDesktopPixelGrid retroDesktopGridUnder(RenderBox box, Canvas canvas) {
  RenderObject top = box;
  while (top.parent != null) {
    top = top.parent!;
  }
  final ratio = top is RenderView ? top.flutterView.devicePixelRatio : 1.0;
  return RetroDesktopPixelGrid._(
    canvas,
    box.getTransformTo(null),
    ratio <= 0 ? 1 : ratio,
  );
}

/// The grid under a box. A `RetroDesktopPixelPainter` is handed one, and draws through it, in the box's own coordinates.
class RetroDesktopPixelGrid {
  RetroDesktopPixelGrid._(this.canvas, Matrix4 m, this._dpr) {
    final s = m.storage;
    _sx = s[0].abs() < 1e-9 ? 1 : s[0];
    _sy = s[5].abs() < 1e-9 ? 1 : s[5];
    _tx = s[12];
    _ty = s[13];
    final along = _sy * _dpr;
    hair = math.max(1, along.abs().round()) / along.abs();
    final across = _sx * _dpr;
    hairX = math.max(1, across.abs().round()) / across.abs();
  }

  /// Draws off the grid's own transform: for a painter given a plain canvas and nothing else, like a picture's slow path.
  factory RetroDesktopPixelGrid.plain(Canvas canvas) =>
      RetroDesktopPixelGrid._(canvas, Matrix4.identity(), 1);

  /// The canvas receiving the snapped drawing operations.
  final Canvas canvas;
  final double _dpr;
  late final double _sx, _sy, _tx, _ty;

  /// One logical pixel, down and across, as a whole number of device pixels.
  late final double hair, hairX;

  /// The local x nearest [v] that falls on a device pixel's edge.
  double x(double v) =>
      (((_tx + v * _sx) * _dpr).roundToDouble() / _dpr - _tx) / _sx;

  /// The local y nearest [v] that falls on a device pixel's edge.
  double y(double v) =>
      (((_ty + v * _sy) * _dpr).roundToDouble() / _dpr - _ty) / _sy;

  /// Rounds a vertical extent to a whole number of device pixels.
  double extent(double logical) =>
      (logical * (_sy * _dpr).abs()).roundToDouble() / (_sy * _dpr).abs();

  /// Aligns a logical rectangle or coordinate to the device-pixel grid.
  Rect snap(Rect r) =>
      Rect.fromLTRB(x(r.left), y(r.top), x(r.right), y(r.bottom));

  /// A filled rectangle with its edges on the grid.
  void fill(Rect r, Color color) {
    if (color.a == 0) return;
    canvas.drawRect(snap(r), Paint()..color = color);
  }

  /// A rectangle given by edges already snapped.
  void fillExact(double l, double t, double r, double b, Color color) {
    if (color.a == 0) return;
    canvas.drawRect(Rect.fromLTRB(l, t, r, b), Paint()..color = color);
  }

  /// A rectangle filled from [top] to [bottom].
  void fillDown(Rect r, Color top, Color bottom, {double mid = .5, Color? at}) {
    final s = snap(r);
    canvas.drawRect(
      s,
      Paint()
        ..shader = ui.Gradient.linear(
          s.topCenter,
          s.bottomCenter,
          at == null ? [top, bottom] : [top, at, bottom],
          at == null ? null : [0, mid, 1],
        ),
    );
  }

  /// A 1 lp frame just inside [r].
  void frame(Rect r, Color color) {
    final s = snap(r);
    fillExact(s.left, s.top, s.right, s.top + hair, color);
    fillExact(s.left, s.bottom - hair, s.right, s.bottom, color);
    fillExact(s.left, s.top + hair, s.left + hairX, s.bottom - hair, color);
    fillExact(s.right - hairX, s.top + hair, s.right, s.bottom - hair, color);
  }

  /// Light top and left, shade bottom and right: CSS `inset 1px 1px 0 light, inset -1px -1px 0 shade`, light on top.
  void bevel(Rect r, Color light, Color shade) {
    final s = snap(r);
    fillExact(s.left, s.bottom - hair, s.right, s.bottom, shade);
    fillExact(s.right - hairX, s.top, s.right, s.bottom, shade);
    fillExact(s.left, s.top, s.right, s.top + hair, light);
    fillExact(s.left, s.top, s.left + hairX, s.bottom, light);
  }

  /// A horizontal rule [at] the given y, one hair tall.
  void ruleAcross(double l, double r, double at, Color color) {
    final top = y(at);
    fillExact(x(l), top, x(r), top + hair, color);
  }

  /// A vertical rule [at] the given x, one hair wide.
  void ruleDown(double t, double b, double at, Color color) {
    final left = x(at);
    fillExact(left, y(t), left + hairX, y(b), color);
  }

  /// Bands up to the right inside [r], CSS `repeating-linear-gradient(-45deg, color 0 width, between width period)`, read a
  /// device pixel at a time as a browser reads a hard stop: full colour, no blur, at any scale. For a mark's small area.
  void diagonal(
    Rect r,
    double period,
    double width,
    Color color, {
    Color? between,
  }) {
    final s = snap(r);
    if (s.isEmpty) return;
    final stepX = 1 / (_sx.abs() * _dpr), stepY = 1 / (_sy.abs() * _dpr);
    final cols = (s.width / stepX).round(), rows = (s.height / stepY).round();
    if (cols * rows > 400000) {
      retroDesktopDiagonal(canvas, s, period, width, color, between: between);
      return;
    }
    if (between != null) canvas.drawRect(s, Paint()..color = between);
    const root = .7071067811865476;
    final path = Path();
    for (var row = 0; row < rows; row++) {
      final down = s.height - (row + .5) * stepY;
      int? from;
      for (var col = 0; col <= cols; col++) {
        final on =
            col < cols &&
            (root * (s.width - (col + .5) * stepX + down)) % period < width;
        if (on) {
          from ??= col;
        } else if (from != null) {
          path.addRect(
            Rect.fromLTRB(
              s.left + from * stepX,
              s.top + row * stepY,
              s.left + col * stepX,
              s.top + (row + 1) * stepY,
            ),
          );
          from = null;
        }
      }
    }
    canvas.drawPath(path, Paint()..color = color);
  }
}

/// The inset of a well: 1 lp of light and shade outside, 1 lp of dark and body inside, as the concept's `.well` draws it.
void retroDesktopInset(
  RetroDesktopPixelGrid px,
  Size size, {
  required Color fill,
  required Color outerShade,
  required Color outerLight,
  required Color innerDark,
  required Color innerBody,
}) {
  final r = Offset.zero & size;
  px.fill(r, fill);
  px.bevel(r, outerShade, outerLight);
  final s = px.snap(r);
  final inner = Rect.fromLTRB(
    s.left + px.hairX,
    s.top + px.hair,
    s.right - px.hairX,
    s.bottom - px.hair,
  );
  px.bevel(inner, innerDark, innerBody);
}

/// Pinstripes down a rectangle: shade over light, one hair each. A title bar's.
void retroDesktopPinstripes(
  RetroDesktopPixelGrid px,
  Rect r,
  Color shade,
  Color light,
) {
  final s = px.snap(r);
  var at = s.top;
  var odd = false;
  // Whole lines only: at a fractional scale a box's foot can cut one short.
  while (at + px.hair <= s.bottom + 1e-6) {
    final next = at + px.hair;
    px.fillExact(s.left, at, s.right, next, odd ? light : shade);
    at = next;
    odd = !odd;
  }
}

/// Diagonal bands up to the right, CSS `repeating-linear-gradient(-45deg, a 0 w, b w period)`, inside [r].
void retroDesktopDiagonal(
  Canvas canvas,
  Rect r,
  double period,
  double width,
  Color color, {
  Color? between,
  bool down = false,
}) {
  canvas.save();
  canvas.clipRect(r);
  if (between != null) canvas.drawRect(r, Paint()..color = between);
  final step = period * math.sqrt2;
  final across = width * math.sqrt2;
  final span = r.height + r.width;
  final p = Path();
  // Phase runs from the box's corner, as the gradient line does.
  var x = r.left - r.height - step;
  while (x < r.left + span) {
    if (down) {
      p
        ..moveTo(x, r.top)
        ..lineTo(x + across, r.top)
        ..lineTo(x + across + r.height, r.bottom)
        ..lineTo(x + r.height, r.bottom)
        ..close();
    } else {
      p
        ..moveTo(x, r.bottom)
        ..lineTo(x + across, r.bottom)
        ..lineTo(x + across + r.height, r.top)
        ..lineTo(x + r.height, r.top)
        ..close();
    }
    x += step;
  }
  canvas.drawPath(p, Paint()..color = color);
  canvas.restore();
}

/// The desktop: the ground, the weave and the light from the top left.
class RetroDesktopDeskPainter extends CustomPainter {
  /// Creates a [RetroDesktopDeskPainter].
  RetroDesktopDeskPainter(this.c);

  /// The colors used by this painter.
  final RetroDesktopColors c;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.drawRect(r, Paint()..color = c.desktop);
    retroDesktopDiagonal(
      canvas,
      r,
      12,
      1,
      c.desktopThreadDark.withValues(alpha: c.desktopThreadDark.a * .12),
      down: true,
    );
    retroDesktopDiagonal(
      canvas,
      r,
      12,
      1,
      c.desktopThreadLight.withValues(alpha: c.desktopThreadLight.a * .16),
    );
    // No glow: the desk is one flat ground and its weave (the material law).
  }

  @override
  bool shouldRepaint(RetroDesktopDeskPainter o) => o.c != c;
}

/// Draws a pixel-aligned directional triangle.
void retroDesktopPaintTriangle(
  Canvas canvas,
  Size s,
  AxisDirection dir,
  Color fill,
  Color line,
) {
  // The concept's own 12-unit polygons.
  const shapes = {
    AxisDirection.down: [Offset(1.5, 3.5), Offset(10.5, 3.5), Offset(6, 9.5)],
    AxisDirection.right: [Offset(3.5, 1.5), Offset(9.5, 6), Offset(3.5, 10.5)],
    AxisDirection.up: [Offset(1.5, 8.5), Offset(10.5, 8.5), Offset(6, 2.5)],
    AxisDirection.left: [Offset(8.5, 1.5), Offset(2.5, 6), Offset(8.5, 10.5)],
  };
  final k = math.min(s.width, s.height) / 12;
  final dx = (s.width - 12 * k) / 2, dy = (s.height - 12 * k) / 2;
  final p = Path()
    ..addPolygon([
      for (final o in shapes[dir]!) Offset(dx + o.dx * k, dy + o.dy * k),
    ], true);
  canvas.drawPath(p, Paint()..color = fill);
  canvas.drawPath(
    p,
    Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = k
      ..strokeJoin = StrokeJoin.round,
  );
}

/// Whole cells of art, drawn as horizontal runs on the grid so no seam shows between them.
class RetroDesktopCells {
  /// Creates a [RetroDesktopCells].
  RetroDesktopCells(this.px, this.cell, this.width, this.height);

  /// The device-pixel grid used for this drawing.
  final RetroDesktopPixelGrid px;

  /// The side of one cell, whole lp.
  final double cell;

  /// How much of the canvas may be drawn on.
  final double width, height;

  /// Fills [cells], a set of (x, y) in cells.
  void fill(Iterable<(int, int)> cells, Color color) {
    final rows = <int, List<int>>{};
    for (final (x, y) in cells) {
      if (x < 0 || y < 0) continue;
      (rows[y] ??= []).add(x);
    }
    for (final MapEntry(key: y, value: xs) in rows.entries) {
      xs.sort();
      var start = xs.first, prev = start;
      void flush() {
        final top = y * cell, left = start * cell;
        final right = math.min((prev + 1) * cell, width);
        final bottom = math.min(top + cell, height);
        if (right > left && bottom > top) {
          px.fill(Rect.fromLTRB(left, top, right, bottom), color);
        }
      }

      for (final x in xs.skip(1)) {
        if (x == prev || x == prev + 1) {
          prev = x;
          continue;
        }
        flush();
        start = prev = x;
      }
      flush();
    }
  }
}
