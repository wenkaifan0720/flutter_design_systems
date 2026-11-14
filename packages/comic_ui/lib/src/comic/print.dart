// The print devices: Ben-Day dots, action lines and outlined lettering. All vector, all whole-pixel, none of it animated.
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'internal/geometry.dart';
import 'theme.dart';
import 'knobs.dart';

/// What a print device with no child stands on: the box it's given, or a band if it's given no height.
const Widget _empty = LimitedBox(
  maxWidth: 320,
  maxHeight: 120,
  child: SizedBox.expand(),
);

/// A screen of dots laid on whole device pixels, so a tile repeats exactly and there's no moiré at any scale.
///
/// [pitch] is the distance between dots in a row and [radius] a dot's size, in logical pixels. Staggered rows sit half a pitch
/// apart in x. The pitch is rounded to whole device pixels (even ones when staggered, so the half-step is whole too), and
/// the radius moves with it so a tone stays the tone. [dpr] is `MediaQuery.devicePixelRatioOf(context)`.
class ComicScreenGrid {
  /// Creates a [ComicScreenGrid].
  ComicScreenGrid(
    double pitch,
    double radius,
    this.dpr, {
    this.staggered = true,
    double rowFactor = .5,
  }) : devicePitch = _snap(pitch * dpr, staggered),
       deviceRow = math.max(
         1,
         (_snap(pitch * dpr, staggered) * rowFactor).round(),
       ),
       radius = radius * _snap(pitch * dpr, staggered) / (pitch * dpr);

  /// [dpr]: the physical pixels per logical pixel. [radius]: the radius in logical pixels.
  final double dpr, radius;

  /// [devicePitch]: the horizontal dot period in physical pixels. [deviceRow]: the vertical dot period in physical pixels.
  final int devicePitch, deviceRow;

  /// Offsets alternating rows of dots by half a period.
  final bool staggered;
  static int _snap(double device, bool even) {
    final d = math.max(2.0, device);
    return even ? math.max(2, (d / 2).round() * 2) : d.round();
  }

  /// The dot period in logical pixels after physical-pixel snapping.
  double get pitch => devicePitch / dpr;

  /// The row period in logical pixels after physical-pixel snapping.
  double get row => deviceRow / dpr;

  /// Dot centres inside [size], x and y pairs, in device pixels: whole numbers, each worked out on its own, so no error can
  /// build along a row.
  Float32List _deviceCentres(Size size) {
    final out = <double>[];
    final reach = radius * dpr;
    final half = devicePitch ~/ 2;
    final lastX = size.width * dpr + reach, lastY = size.height * dpr + reach;
    for (var j = 0; j * deviceRow < lastY; j++) {
      final shift = staggered && j.isOdd ? half : 0;
      for (var i = 0; i * devicePitch + shift < lastX; i++) {
        out
          ..add((i * devicePitch + shift).toDouble())
          ..add((j * deviceRow).toDouble());
      }
    }
    return Float32List.fromList(out);
  }

  /// Dot centres inside [size], x and y pairs, in logical pixels.
  Float32List points(Size size) {
    final device = _deviceCentres(size);
    return Float32List.fromList([for (final v in device) v / dpr]);
  }

  /// Paints this screen's dots in [rect], clipped to it. The dots go down in device pixels so that every one of them lands on the
  /// same part of a pixel: no drift, no moire.
  void paint(Canvas canvas, Rect rect, Color color) {
    if (rect.isEmpty || color.a == 0) return;
    canvas.save();
    canvas.clipRect(rect);
    canvas.translate(rect.left, rect.top);
    canvas.scale(1 / dpr);
    canvas.drawRawPoints(
      ui.PointMode.points,
      _deviceCentres(rect.size),
      Paint()
        ..color = color
        ..strokeCap = StrokeCap.round
        ..strokeWidth = radius * dpr * 2,
    );
    canvas.restore();
  }
}

class _ScreenPainter extends CustomPainter {
  _ScreenPainter(
    this.color,
    this.pitch,
    this.radius,
    this.dpr,
    this.staggered,
    this.rowFactor,
  );
  final Color color;
  final double pitch, radius, dpr, rowFactor;
  final bool staggered;
  @override
  void paint(Canvas canvas, Size size) => ComicScreenGrid(
    pitch,
    radius,
    dpr,
    staggered: staggered,
    rowFactor: rowFactor,
  ).paint(canvas, Offset.zero & size, color);
  @override
  bool shouldRepaint(_ScreenPainter o) =>
      o.color != color ||
      o.pitch != pitch ||
      o.radius != radius ||
      o.dpr != dpr ||
      o.staggered != staggered ||
      o.rowFactor != rowFactor;
}

/// Ben-Day dots over a large area, behind a [child]. One colour, one screen, on whole device pixels: read at scale 1, 2 and 3
/// with no moiré. It stands in a `RepaintBoundary` and draws once. Words on dots must meet the contrast bar against the dots:
/// a `ComicPanel(ground: ...)` keeps its words to the inks that do.
///
/// ```dart
/// ComicBenDay(color: t.colors.dotTint, pitch: 9, radius: 2.4, child: words)
/// ```
class ComicBenDay extends StatelessWidget {
  /// Creates a [ComicBenDay].
  const ComicBenDay({
    super.key,
    required this.color,
    this.pitch = 9,
    this.radius = 2.2,
    this.staggered = true,
    this.rowFactor = .5,
    this.child,
  });

  /// The ink color used by this drawing.
  final Color color;

  /// [pitch]: the horizontal dot period in logical pixels. [radius]: the radius in logical pixels. [rowFactor]: the vertical dot period relative to its horizontal pitch.
  final double pitch, radius, rowFactor;

  /// Offsets alternating rows of dots by half a period.
  final bool staggered;

  /// Content placed inside this widget.
  final Widget? child;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      painter: _ScreenPainter(
        color,
        pitch,
        radius,
        MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        staggered,
        rowFactor,
      ),
      isComplex: true,
      child: child == null ? _empty : RepaintBoundary(child: child),
    ),
  );
}

/// A halftone that fades, as on a cover: dots largest at [from] and gone by [reach], in the design's own box (see
/// [ComicCoverPrint]).
class ComicDotFade {
  /// Creates a [ComicDotFade].
  const ComicDotFade(this.from, this.reach, this.most, this.color);

  /// The center of the radial dot fade in design coordinates.
  final Offset from;

  /// [reach]: the distance to zero dots. [most]: the maximum dot radius.
  final double reach, most;

  /// The ink color used by this drawing.
  final Color color;

  @override
  bool operator ==(Object other) =>
      other is ComicDotFade &&
      other.from == from &&
      other.reach == reach &&
      other.most == most &&
      other.color == color;

  @override
  int get hashCode => Object.hash(from, reach, most, color);
}

class _CoverPainter extends CustomPainter {
  _CoverPainter(
    this.ground,
    this.ray,
    this.origin,
    this.fades,
    this.dpr,
    this.design,
    this.wedges,
  );
  final Color? ground;
  final Color ray;
  final Offset origin;
  final List<ComicDotFade> fades;
  final double dpr;
  final Size design;
  final int wedges;
  @override
  void paint(Canvas canvas, Size s) {
    final r = Offset.zero & s;
    canvas.save();
    canvas.clipRect(r);
    if (ground != null) canvas.drawRect(r, fillPaint(ground!));
    // As an SVG's `slice`: the design's box covers this one, centred.
    final k = math.max(s.width / design.width, s.height / design.height);
    final x0 = (s.width - design.width * k) / 2;
    final y0 = (s.height - design.height * k) / 2;
    final c = Offset(x0 + origin.dx * k, y0 + origin.dy * k);
    final far = math.sqrt(s.width * s.width + s.height * s.height) + c.distance;
    final wedge = Path();
    for (var i = 0; i < wedges; i++) {
      final a0 = 2 * math.pi * (2 * i) / (2 * wedges);
      final a1 = 2 * math.pi * (2 * i + 1) / (2 * wedges);
      wedge
        ..moveTo(c.dx, c.dy)
        ..lineTo(c.dx + far * math.cos(a0), c.dy + far * math.sin(a0))
        ..lineTo(c.dx + far * math.cos(a1), c.dy + far * math.sin(a1))
        ..close();
    }
    canvas.drawPath(wedge, fillPaint(ray));
    if (fades.isNotEmpty) {
      // A 60-degree screen on whole device pixels. Radii in five steps, so each step is one draw.
      final pitch = 13 * k;
      final grid = ComicScreenGrid(pitch, 1, dpr, rowFactor: .866);
      for (final f in fades) {
        final at = Offset(x0 + f.from.dx * k, y0 + f.from.dy * k);
        final reach = f.reach * k, most = f.most * k;
        final buckets = <int, List<double>>{};
        final half = grid.pitch / 2;
        var j = 0;
        for (var y = 0.0; y < s.height + most; y += grid.row, j++) {
          for (
            var x = j.isOdd ? half : 0.0;
            x < s.width + most;
            x += grid.pitch
          ) {
            final d = (Offset(x, y) - at).distance;
            if (d >= reach) continue;
            final v = math.pow(1 - d / reach, 1.2) * most;
            if (v < .35 * k) continue;
            final key = (v / most * 6).ceil().clamp(1, 6);
            (buckets[key] ??= [])
              ..add(x)
              ..add(y);
          }
        }
        for (final b in buckets.entries) {
          canvas.drawRawPoints(
            ui.PointMode.points,
            Float32List.fromList(b.value),
            Paint()
              ..color = f.color
              ..strokeCap = StrokeCap.round
              ..strokeWidth = 2 * most * b.key / 6,
          );
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CoverPainter o) =>
      o.ground != ground ||
      o.ray != ray ||
      o.origin != origin ||
      o.dpr != dpr ||
      o.design != design ||
      o.wedges != wedges ||
      !listEquals(o.fades, fades);
}

/// Action lines radiating from one point, with halftones fading in from two corners, over a [child]. It fills the box it's
/// given and crops to it like an SVG's `slice`, so it composes at any shape. No per-frame work: it stands in a
/// `RepaintBoundary` and redraws only if it's resized. Put words on it only inside a paper or caption box, or in
/// `ComicLettering`: nothing small reads on rays and dots.
///
/// ```dart
/// ComicCoverPrint(child: ComicLettering('Volume one', style: ComicLetteringStyle.title))
/// ```
class ComicCoverPrint extends StatelessWidget {
  /// Creates a [ComicCoverPrint].
  const ComicCoverPrint({
    super.key,
    this.origin = const Offset(640, 210),
    this.dots = true,
    this.wedges = 30,
    this.child,
  });

  /// Where the lines meet, in a design box of 900 by 520.
  final Offset origin;

  /// The two corner halftones.
  final bool dots;

  /// The number of radial wedges in the print pattern.
  final int wedges;

  /// Content placed inside this widget.
  final Widget? child;
  @override
  Widget build(BuildContext context) {
    final c = ComicTheme.of(context).colors;
    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        painter: _CoverPainter(
          c.cover,
          c.coverRay,
          origin,
          dots
              ? [
                  ComicDotFade(const Offset(0, 520), 520, 4.6, c.coverDot),
                  ComicDotFade(
                    const Offset(900, 0),
                    360,
                    4.0,
                    c.coverDotSecondary,
                  ),
                ]
              : const [],
          MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
          const Size(900, 520),
          wedges,
        ),
        child: child ?? _empty,
      ),
    );
  }
}

/// Action lines alone, in any colour: every other wedge of a sunburst, behind a [child].
///
/// ```dart
/// ComicActionLines(color: t.colors.ray, child: drawing)
/// ```
class ComicActionLines extends StatelessWidget {
  /// Creates a [ComicActionLines].
  const ComicActionLines({
    super.key,
    this.color,
    this.ground,
    this.origin = const Offset(520, 330),
    this.wedges = 30,
    this.child,
  });

  /// The lines; `ray` if left out.
  final Color? color;

  /// The ground under them, if any.
  final Color? ground;

  /// The origin of the radiating print pattern.
  final Offset origin;

  /// The number of radial wedges in the print pattern.
  final int wedges;

  /// Content placed inside this widget.
  final Widget? child;
  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: CustomPaint(
      isComplex: true,
      painter: _CoverPainter(
        ground,
        color ?? ComicTheme.of(context).colors.ray,
        origin,
        const [],
        MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
        const Size(900, 520),
        wedges,
      ),
      child: child ?? _empty,
    ),
  );
}

/// How lettering is outlined: contour width, then the layers behind it from nearest to farthest.
class ComicLetteringStyle {
  /// Creates a [ComicLetteringStyle].
  const ComicLetteringStyle({this.outline = 0, this.layers = const []});

  /// The contour's width outside the glyph.
  final double outline;

  /// Each (x, y, width of the layer's own stroke, ink name) behind the glyph: `line`, `drama` or `act`.
  final List<(double, double, double, String)> layers;

  /// A masthead's extrude: contour, a drama plate, a line.
  static const masthead = ComicLetteringStyle(
    outline: 3.8,
    layers: [(6, 6, 2, 'drama'), (9.2, 9.2, 2, 'line')],
  );

  /// A splash's title: contour and a hard drop.
  static const title = ComicLetteringStyle(
    outline: 2.9,
    layers: [(5.5, 5.5, 1, 'line')],
  );

  /// A cover's second line.
  static const subtitle = ComicLetteringStyle(
    outline: 2.4,
    layers: [(3, 4, 0, 'line')],
  );

  /// A big sound effect: contour, a drama plate, a line.
  static const sfx = ComicLetteringStyle(
    outline: 2.4,
    layers: [(4, 4, 0, 'drama'), (5, 5, 0, 'line')],
  );

  /// A small sound effect: contour and a drop.
  static const pow = ComicLetteringStyle(
    outline: 1.9,
    layers: [(2, 3, 0, 'line')],
  );

  /// The app's name in the top bar: contour, an act plate, a line.
  static const logo = ComicLetteringStyle(
    outline: 2.4,
    layers: [(3.5, 3.5, 1, 'act'), (5, 4.5, 1, 'line')],
  );
}

/// Outlined lettering: the concept's stacked `text-shadow`, as one part. It lays out once and paints that one layout in every
/// layer, so the layers can't come apart in RTL or on a wrap, and it stays vector at any scale: no blur, no filter. Lettering
/// is set in caps. [fit] shrinks one line to the width, for a masthead. Its box is the words' box; the outline paints outside.
///
/// ```dart
/// ComicLettering('Volume one', size: 60, fill: t.colors.paper, style: ComicLetteringStyle.title)
/// ```
class ComicLettering extends LeafRenderObjectWidget {
  /// Creates a [ComicLettering].
  const ComicLettering(
    this.text, {
    super.key,
    this.size = 60,
    this.fill,
    this.style = ComicLetteringStyle.title,
    this.lineHeight = .95,
    this.tracking = .035,
    this.fit = false,
    this.align = TextAlign.start,
    this.spans,
  });

  /// The text rendered by this object.
  final String text;

  /// [size]: the visual size in logical pixels. [lineHeight]: line height as a multiple of the text size. [tracking]: letter spacing relative to the text size.
  final double size, lineHeight, tracking;

  /// Whether or how the component fills its available space.
  final Color? fill;

  /// The visual treatment supplied by the caller.
  final ComicLetteringStyle style;

  /// Scale down to one line in the width given, whole.
  final bool fit;

  /// How the row aligns its children vertically.
  final TextAlign align;

  /// Per-word colours: (text, colour) in order, in place of one [fill].
  final List<(String, Color)>? spans;

  @override
  RenderObject createRenderObject(BuildContext context) => RenderComicLettering(
    this,
    ComicTheme.of(context).colors,
    Directionality.of(context),
    ComicTheme.of(context).typeface,
  );
  @override
  void updateRenderObject(
    BuildContext context,
    RenderComicLettering renderObject,
  ) {
    renderObject.update(
      this,
      ComicTheme.of(context).colors,
      Directionality.of(context),
      ComicTheme.of(context).typeface,
    );
  }
}

/// Lays out and paints the [ComicLettering] widget.
class RenderComicLettering extends RenderBox {
  /// Creates a [RenderComicLettering].
  RenderComicLettering(
    ComicLettering widget,
    ComicColors colors,
    TextDirection direction, [
    ComicTypeface typeface = const ComicTypeface(),
  ]) : _w = widget,
       _c = colors,
       _dir = direction,
       _typeface = typeface;
  ComicLettering _w;
  ComicColors _c;
  TextDirection _dir;
  ComicTypeface _typeface;
  final List<(TextPainter, Offset)> _layers = [];

  /// The number of painters laid out: each with the same words and the same width.
  int get layerCount => _layers.length;

  /// Updates the rendered lettering, palette and reading direction.
  void update(
    ComicLettering w,
    ComicColors c,
    TextDirection dir, [
    ComicTypeface? typeface,
  ]) {
    _w = w;
    _c = c;
    _dir = dir;
    _typeface = typeface ?? _typeface;
    markNeedsLayout();
  }

  Color _layerInk(String name) => switch (name) {
    'drama' => _c.drama,
    'act' => _c.primary,
    'caption' => _c.caption,
    _ => _c.outline,
  };

  TextStyle _style(double size, Color? color, Paint? foreground) => TextStyle(
    inherit: false,
    fontFamily: _typeface.display,
    package: _typeface.displayPackage,
    fontSize: size,
    height: ((size * _w.lineHeight).roundToDouble() - .01) / size,
    letterSpacing: size * _w.tracking,
    fontWeight: FontWeight.w400,
    color: foreground == null ? color : null,
    foreground: foreground,
    leadingDistribution: TextLeadingDistribution.even,
  );

  InlineSpan _span(double size, Color? color, Paint? foreground) {
    final s = _w.spans;
    if (s == null) {
      return TextSpan(
        text: _w.text.toUpperCase(),
        style: _style(size, color ?? _w.fill ?? _c.paper, foreground),
      );
    }
    return TextSpan(
      style: _style(size, _w.fill ?? _c.paper, foreground),
      children: [
        for (final (words, ink) in s)
          TextSpan(
            text: words.toUpperCase(),
            style: foreground == null ? TextStyle(color: color ?? ink) : null,
          ),
      ],
    );
  }

  TextPainter _painter(
    double size,
    double max,
    Color? color,
    Paint? foreground,
  ) => TextPainter(
    text: _span(size, color, foreground),
    textDirection: _dir,
    textAlign: _w.align,
  )..layout(maxWidth: max);

  void _clear() {
    for (final (p, _) in _layers) {
      p.dispose();
    }
    _layers.clear();
  }

  (double, Size) _measure(BoxConstraints c) {
    var size = _w.size * _typeface.scale;
    final max = c.maxWidth.isFinite ? c.maxWidth : 100000.0;
    final tp = _painter(size, _w.fit ? 100000.0 : max, _c.paper, null);
    final natural = tp.width;
    tp.dispose();
    if (_w.fit && natural > max && max > 0) size = size * max / natural;
    final p2 = _painter(size, max, _c.paper, null);
    final own = Size(_w.fit || !c.hasTightWidth ? p2.width : max, p2.height);
    p2.dispose();
    return (size, c.constrain(own));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _measure(constraints).$2;

  @override
  void performLayout() {
    final (fontSize, own) = _measure(constraints);
    size = own;
    _clear();
    final max = constraints.maxWidth.isFinite ? constraints.maxWidth : 100000.0;
    final k = fontSize / _w.size;
    final s = _w.style;
    for (final (x, y, sw, ink) in s.layers.reversed) {
      final color = _layerInk(ink);
      final at = Offset(x * k, y * k);
      // Each layer is a solid print of the glyphs, as a stacked text-shadow is; its own stroke fattens that print.
      // Drawn as the stroke alone it read as a hollow echo, a misregistration, with the ground showing through.
      _layers.add((_painter(fontSize, max, color, Paint()..color = color), at));
      if (sw > 0) {
        _layers.add((
          _painter(
            fontSize,
            max,
            color,
            Paint()
              ..color = color
              ..style = PaintingStyle.stroke
              ..strokeWidth = sw * k
              ..strokeJoin = StrokeJoin.round,
          ),
          at,
        ));
      }
    }
    if (s.outline > 0) {
      _layers.add((
        _painter(
          fontSize,
          max,
          _c.outline,
          Paint()
            ..color = _c.outline
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2 * s.outline * k
            ..strokeJoin = StrokeJoin.round,
        ),
        Offset.zero,
      ));
    }
    _layers.add((_painter(fontSize, max, null, null), Offset.zero));
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      computeMaxIntrinsicWidth(height);
  @override
  double computeMaxIntrinsicWidth(double height) {
    final tp = _painter(_w.size * _typeface.scale, 100000, _c.paper, null);
    final w = tp.width;
    tp.dispose();
    return w;
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      computeMaxIntrinsicHeight(width);
  @override
  double computeMaxIntrinsicHeight(double width) {
    final tp = _painter(
      _w.size * _typeface.scale,
      width.isFinite ? width : 100000,
      _c.paper,
      null,
    );
    final h = tp.height;
    tp.dispose();
    return h;
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..label = _w.text
      ..textDirection = _dir;
  }

  /// Where the words stand across a box wider than they are, as a fraction of the room left: a painter is only as
  /// wide as its longest line, so its own alignment can't place it in the box. Start is the right in RTL.
  double get _across => switch (_w.align) {
    TextAlign.left => 0,
    TextAlign.right => 1,
    TextAlign.center => .5,
    TextAlign.end => _dir == TextDirection.rtl ? 0 : 1,
    TextAlign.start || TextAlign.justify => _dir == TextDirection.rtl ? 1 : 0,
  };

  @override
  void paint(PaintingContext context, Offset offset) {
    // The run is placed whole, its hard print layers included: shifting each layer by the room its words alone leave
    // pushed the print past the box's end in RTL (r5, print_test).
    var lead = 0.0, reach = 0.0;
    for (final (p, at) in _layers) {
      if (at.dx < lead) lead = at.dx;
      if (at.dx + p.width > reach) reach = at.dx + p.width;
    }
    final room = size.width - (reach - lead);
    // At the start (0) nothing moves, as before; at the end the run's far edge meets the box's.
    final shift = room > 0 ? room * _across : 0.0;
    for (final (p, at) in _layers) {
      p.paint(context.canvas, offset + at + Offset(shift, 0));
    }
  }

  @override
  void dispose() {
    _clear();
    super.dispose();
  }
}

/// A sound effect: lettered, tilted, sitting on art. It paints outside its box as lettering does. Colour it by the art ground
/// under it: `t.colors.sfxOn(ground)`.
///
/// ```dart
/// ComicSfx('Krash!', size: 32, fill: t.colors.sfxOn(2))
/// ```
class ComicSfx extends StatelessWidget {
  /// Creates a [ComicSfx].
  const ComicSfx(
    this.text, {
    super.key,
    this.size = 24,
    this.fill,
    this.tilt = 0,
    this.big = false,
  });

  /// The text rendered by this object.
  final String text;

  /// The visual size in logical pixels.
  final double size;

  /// Its colour; the lamp if left out.
  final Color? fill;

  /// Degrees, negative leaning back.
  final double tilt;

  /// The big form, with a drama plate behind it.
  final bool big;
  @override
  Widget build(BuildContext context) {
    final c = ComicTheme.of(context).colors;
    final words = ComicLettering(
      text,
      size: size,
      fill: fill ?? c.caption,
      lineHeight: 1,
      tracking: .05,
      style: big ? ComicLetteringStyle.sfx : ComicLetteringStyle.pow,
    );
    return tilt == 0
        ? words
        : Transform.rotate(angle: tilt * math.pi / 180, child: words);
  }
}
