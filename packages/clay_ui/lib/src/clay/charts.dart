/// Clay's charts on ui_core's headless charts: lines rolled like coils of
/// clay, areas laid under them as slabs of pastel clay, bars standing as
/// raised pills, a donut of pastel clay pieces round a pressed well, and a
/// sparkline. Every mark keeps Clay's three moves: inflated volume (light
/// inside its top-leading edge, shade inside its bottom-trailing edge),
/// one soft shadow straight down in its own hue, continuous corners and no
/// stroke. ui_core picks points (pointer, finger, keys, screen reader) and
/// says them; Clay draws every mark.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/slices.dart';
import 'internal/sprites.dart' show clayAddShape, clayDrawShape;
import 'internal/volume.dart';
import 'surface.dart';
import 'theme.dart';

/// A named run of points, in order along x.
typedef ClayChartSeries = RawChartSeries;

/// A point of a [ClayChartSeries]: x and y, or a gap where y is null.
typedef ClayChartPoint = RawChartPoint;

/// What a chart's x values are: numbers, times or categories.
typedef ClayChartXAxis = RawChartXAxis;

/// A slice of a [ClayPieChart].
typedef ClayPieSlice = RawPieSlice;

/// The pastels after the accent, in the order a chart takes them: each one
/// a hue away from the one before it.
const _pastels = [
  ClayTint.sky,
  ClayTint.mint,
  ClayTint.lilac,
  ClayTint.butter,
  ClayTint.rose,
  ClayTint.peach,
];

/// The colour of the [i]th piece of a donut or the [i]th series of bars:
/// the accent first, then Clay's pastels' hues, all at one weight, so no
/// series says it matters more than another and each is told from its
/// neighbours by its hue. By day the accent as it is, then each pastel's hue
/// at the accent's lightness and chroma (as much of it as sRGB holds at that
/// hue); legends, labels and values carry the data, not contrast. By night
/// the accent, then the pastels chalky.
Color claySliceColor(ClayColors c, int i) {
  if (c.brightness != Brightness.dark) return _dayColor(c, i);
  if (i == 0) return c.accent;
  final hsl = HSLColor.fromColor(c.tint(_pastels[(i - 1) % _pastels.length]));
  return hsl.withSaturation(0.5).withLightness(0.70).toColor();
}

/// The colour of the [i]th line. By day it is [claySliceColor]'s, so a line,
/// its area and its legend's ball share one colour and every line weighs as
/// the accent does. By night the accent first, then the pastel kept matte
/// (never saturated) and lifted only as far as a line of it needs to stand
/// 3:1 from the clay.
Color claySeriesColor(ClayColors c, int i) {
  if (c.brightness != Brightness.dark) return _dayColor(c, i);
  if (i == 0) return c.accent;
  final pastel = HSLColor.fromColor(claySliceColor(c, i));
  var hsl = pastel.withSaturation(math.min(pastel.saturation, 0.42));
  for (var step = 0; step < 160; step++) {
    if (clayContrast(hsl.toColor(), c.clay) >= 3) break;
    final l = hsl.lightness + 0.005;
    if (l >= 1) break;
    hsl = hsl.withLightness(l);
  }
  return hsl.toColor();
}

/// By day, the [i]th series: the accent itself first, then each pastel's hue
/// at the accent's OKLCH lightness and chroma, so every series weighs as the
/// accent does.
Color _dayColor(ClayColors c, int i) {
  if (i == 0) return c.accent;
  final accent = _okLch(c.accent);
  final hue = _okLch(c.tint(_pastels[(i - 1) % _pastels.length])).hue;
  return _oklch(accent.lightness, accent.chroma, hue);
}

double _toLinear(double v) =>
    v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();

double _fromLinear(double v) => v <= 0.0031308
    ? 12.92 * v
    : 1.055 * math.pow(v, 1 / 2.4).toDouble() - 0.055;

double _cbrt(double v) =>
    v < 0 ? -math.pow(-v, 1 / 3).toDouble() : math.pow(v, 1 / 3).toDouble();

/// [color] in OKLCH: its lightness, its chroma and its hue (in radians).
({double lightness, double chroma, double hue}) _okLch(Color color) {
  final r = _toLinear(color.r);
  final g = _toLinear(color.g);
  final b = _toLinear(color.b);
  final l = _cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b);
  final m = _cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b);
  final s = _cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b);
  final ok = (
    l: 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s,
    a: 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s,
    b: 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s,
  );
  return (
    lightness: ok.l,
    chroma: math.sqrt(ok.a * ok.a + ok.b * ok.b),
    hue: math.atan2(ok.b, ok.a),
  );
}

/// The colour at OKLCH [lightness], [chroma] and [hue], its chroma lowered
/// until it lies in sRGB, to the 8 bits it is painted in.
Color _oklch(double lightness, double chroma, double hue) {
  for (var k = chroma; ; k = math.max(0, k - 0.002)) {
    final a = k * math.cos(hue);
    final b = k * math.sin(hue);
    final l = math.pow(lightness + 0.3963377774 * a + 0.2158037573 * b, 3);
    final m = math.pow(lightness - 0.1055613458 * a - 0.0638541728 * b, 3);
    final s = math.pow(lightness - 0.0894841775 * a - 1.2914855480 * b, 3);
    final rgb = [
      4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
      -1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
      -0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s,
    ];
    if (k == 0 || rgb.every((v) => v >= -1e-4 && v <= 1 + 1e-4)) {
      int byte(double v) => (_fromLinear(v.clamp(0.0, 1.0)) * 255).round();
      return Color.fromARGB(255, byte(rgb[0]), byte(rgb[1]), byte(rgb[2]));
    }
  }
}

/// The first colours of a chart: [layered]'s fill, then the lines' colours
/// ([claySeriesColor]), or the pieces' and bars' pastels ([claySliceColor])
/// when [pastel].
List<Color> _palette(
  ClayColors c,
  RawStyleOf layered,
  int count, {
  bool pastel = false,
}) => [
  for (var i = 0; i < count; i++)
    i == 0 && layered.fill != null
        ? layered.fill!
        : (pastel ? claySliceColor(c, i) : claySeriesColor(c, i)),
];

/// A monotone curve through [p]: soft, but never overshooting a value.
Path _smooth(List<Offset> p) {
  final path = Path()..moveTo(p.first.dx, p.first.dy);
  final n = p.length;
  if (n == 1) return path;
  if (n == 2) return path..lineTo(p[1].dx, p[1].dy);
  final d = [
    for (var i = 0; i < n - 1; i++)
      p[i + 1].dx == p[i].dx
          ? 0.0
          : (p[i + 1].dy - p[i].dy) / (p[i + 1].dx - p[i].dx),
  ];
  final m = List<double>.filled(n, 0);
  m[0] = d[0];
  m[n - 1] = d[n - 2];
  for (var i = 1; i < n - 1; i++) {
    m[i] = d[i - 1] * d[i] <= 0 ? 0 : (d[i - 1] + d[i]) / 2;
  }
  for (var i = 0; i < n - 1; i++) {
    if (d[i] == 0) {
      m[i] = 0;
      m[i + 1] = 0;
      continue;
    }
    final a = m[i] / d[i];
    final b = m[i + 1] / d[i];
    final s = a * a + b * b;
    if (s > 9) {
      final t = 3 / math.sqrt(s);
      m[i] = t * a * d[i];
      m[i + 1] = t * b * d[i];
    }
  }
  for (var i = 0; i < n - 1; i++) {
    final dx = (p[i + 1].dx - p[i].dx) / 3;
    path.cubicTo(
      p[i].dx + dx,
      p[i].dy + m[i] * dx,
      p[i + 1].dx - dx,
      p[i + 1].dy - m[i + 1] * dx,
      p[i + 1].dx,
      p[i + 1].dy,
    );
  }
  return path;
}

/// The runs of [s] between its gaps, as drawn.
List<List<Offset>> _runs(RawChartDetails d, RawChartSeries s) {
  final runs = <List<Offset>>[];
  var run = <Offset>[];
  for (final p in s.points) {
    if (p.y == null) {
      if (run.isNotEmpty) runs.add(run);
      run = <Offset>[];
    } else {
      run.add(Offset(d.x.map(p.x), d.y.map(p.y!)));
    }
  }
  if (run.isNotEmpty) runs.add(run);
  return runs;
}

/// A coil of clay along [path]: its shadow straight down in its own hue,
/// its body, a lit ridge along its top and a shaded one along its foot.
void _coil(Canvas canvas, ClayColors c, Path path, Color color, double width) {
  final shade = c.shadeOf(color);
  final night = c.brightness == Brightness.dark;
  canvas
    ..drawPath(
      path.shift(Offset(0, width * 0.7)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width + 1
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = shade.withValues(alpha: 0.32)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, width * 0.7),
    )
    ..drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    )
    ..drawPath(
      path.shift(Offset(0, -width * 0.22)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.34
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Color.lerp(
          color,
          const Color(0xFFFFFFFF),
          0.55,
        )!.withValues(alpha: 0.6),
    )
    ..drawPath(
      path.shift(Offset(0, width * 0.24)),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width * 0.3
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = shade.withValues(alpha: night ? 0.5 : 0.32),
    );
}

/// A small raised ball of [ring] round a pale centre, at [at].
void _ball(Canvas canvas, ClayColors c, Offset at, Color ring, double r) {
  canvas
    ..drawCircle(
      at + Offset(0, r * 0.35),
      r + 1,
      Paint()
        ..color = c.shadeOf(ring).withValues(alpha: 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.5),
    )
    ..drawCircle(at, r, Paint()..color = ring)
    ..drawCircle(at, r * 0.55, Paint()..color = c.risen);
}

/// A focused chart's rim: the 2 px band of the focus colour every focused
/// Clay part takes, just inside its edge.
void _focusRim(Canvas canvas, ClayColors c, Size size) {
  clayDrawShape(
    canvas,
    (Offset.zero & size).deflate(1),
    ClayRadius.control - 1,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = c.focus,
  );
}

TextPainter _label(String text, TextStyle style, TextDirection direction) =>
    TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      maxLines: 1,
    )..layout();

/// The grid as soft grooves pressed across the plot, and the axes' words.
abstract class _AxesPainter extends CustomPainter {
  _AxesPainter({
    required this.details,
    required this.colors,
    required this.labelStyle,
    required this.direction,
  });

  final RawChartDetails details;
  final ClayColors colors;
  final TextStyle labelStyle;
  final TextDirection direction;

  void paintAxes(Canvas canvas) {
    final d = details;
    final c = colors;
    final plot = d.plotArea;
    final rtl = direction == TextDirection.rtl;
    final dark = c.shadeOf(c.clay).withValues(alpha: 0.16);
    // By night the lit edge is a whisper: a bright line would read as a rule.
    final lit = c.light.withValues(
      alpha: c.brightness == Brightness.dark ? 0.08 : 0.7,
    );
    for (final tick in d.yTicks) {
      final y = tick.position.roundToDouble() + 0.5;
      canvas
        ..drawLine(
          Offset(plot.left, y),
          Offset(plot.right, y),
          Paint()
            ..color = dark
            ..strokeWidth = 1,
        )
        ..drawLine(
          Offset(plot.left, y + 1),
          Offset(plot.right, y + 1),
          Paint()
            ..color = lit
            ..strokeWidth = 1,
        );
      final words = _label(tick.label, labelStyle, direction);
      final x = rtl ? plot.right + 8 : plot.left - 8 - words.width;
      words
        ..paint(canvas, Offset(x, y - words.height / 2))
        ..dispose();
    }
    final xs = d.xTicks;
    // The x words, thinned to those that fit side by side.
    var lastEdge = double.negativeInfinity;
    for (final tick in rtl ? xs.reversed : xs) {
      final words = _label(tick.label, labelStyle, direction);
      final left = (tick.position - words.width / 2).clamp(
        0.0,
        d.size.width - words.width,
      );
      if (left >= lastEdge + 8) {
        words.paint(canvas, Offset(left, plot.bottom + 8));
        lastEdge = left + words.width;
      }
      words.dispose();
    }
  }

  @override
  bool shouldRepaint(_AxesPainter old) =>
      old.details != details ||
      old.colors != colors ||
      old.labelStyle != labelStyle ||
      old.direction != direction;
}

class _LinePainter extends _AxesPainter {
  _LinePainter({
    required super.details,
    required super.colors,
    required super.labelStyle,
    required super.direction,
    required this.palette,
    required this.filled,
  });

  final List<Color> palette;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    paintAxes(canvas);
    final plot = d.plotArea;
    final base = d.y.map(d.y.min <= 0 && d.y.max >= 0 ? 0 : d.y.min);
    final a = d.active;
    if (a != null && d.activePosition != null) {
      final x = d.activePosition!.dx;
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = c.ink.withValues(alpha: 0.14)
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round,
      );
    }
    if (filled) {
      // Under each line a slab of its pastel clay laid on the floor, its
      // feet rounded: lit inside its top-leading edge, shaded inside its
      // bottom-trailing one. By night the clay lifted toward the light and
      // barely warmed (the line's colour mixed into night clay turns to
      // brick). Every series' slab first, so every line lies over them.
      final night = c.brightness == Brightness.dark;
      for (final (i, s) in d.series.indexed) {
        final slab = night
            ? Color.lerp(c.risen, palette[i], 0.16)!
            : Color.lerp(palette[i], c.clay, 0.6)!;
        for (final run in _runs(d, s)) {
          if (run.length < 2) continue;
          final first = run.first;
          final last = run.last;
          final foot = math.max(
            0.0,
            [
              12.0,
              (base - first.dy).abs() / 2,
              (base - last.dy).abs() / 2,
              (last.dx - first.dx).abs() / 4,
            ].reduce(math.min),
          );
          final way = last.dx >= first.dx ? 1.0 : -1.0;
          final up = base >= first.dy ? 1.0 : -1.0;
          final area = _smooth(run)
            ..lineTo(last.dx, base - up * foot)
            ..quadraticBezierTo(last.dx, base, last.dx - way * foot, base)
            ..lineTo(first.dx + way * foot, base)
            ..quadraticBezierTo(first.dx, base, first.dx, base - up * foot)
            ..close();
          clayPaintVolume(
            canvas,
            area,
            colors: c,
            color: slab,
            side: 48,
            mirrored: direction == TextDirection.rtl,
          );
        }
      }
    }
    for (final (i, s) in d.series.indexed) {
      final color = palette[i];
      for (final run in _runs(d, s)) {
        if (run.length == 1) {
          _ball(canvas, c, run.first, color, 4);
        } else {
          _coil(canvas, c, _smooth(run), color, 4);
        }
      }
    }
    if (a != null) {
      for (final (i, s) in d.series.indexed) {
        if (a.index >= s.points.length || s.points[a.index].y == null) {
          continue;
        }
        final at = d.positionOf(RawChartPointRef(i, a.index));
        _ball(canvas, c, at, palette[i], i == a.series ? 7 : 5);
      }
    }
    if (d.states.contains(WidgetState.focused)) _focusRim(canvas, c, size);
  }

  @override
  bool shouldRepaint(_LinePainter old) =>
      super.shouldRepaint(old) ||
      !listEquals(old.palette, palette) ||
      old.filled != filled;
}

/// Where each bar of [d] stands: series side by side in their band, each
/// at most 56 wide, from zero to its value.
List<({int series, int index, Rect rect})> _bars(
  RawChartDetails d,
  TextDirection direction,
) {
  final band = d.x as RawBandScale;
  final base = d.y.map(d.y.min <= 0 && d.y.max >= 0 ? 0 : d.y.min);
  final n = math.max(1, d.series.length);
  final inner = n > 1 ? 4.0 : 0.0;
  final w = math.min(
    56.0,
    math.max(2.0, (band.bandwidth - inner * (n - 1)) / n),
  );
  final group = w * n + inner * (n - 1);
  final rtl = direction == TextDirection.rtl;
  final bars = <({int series, int index, Rect rect})>[];
  for (final (i, s) in d.series.indexed) {
    for (final (j, p) in s.points.indexed) {
      if (p.y == null) continue;
      final slot = rtl ? n - 1 - i : i;
      final left = band.map(p.x) - group / 2 + slot * (w + inner);
      final top = d.y.map(p.y!);
      bars.add((
        series: i,
        index: j,
        rect: Rect.fromLTRB(
          left,
          math.min(top, base),
          left + w,
          math.max(top, base),
        ),
      ));
    }
  }
  return bars;
}

/// The bar chart's ground: the picked band's dent, the grid and the words.
class _BarPainter extends _AxesPainter {
  _BarPainter({
    required super.details,
    required super.colors,
    required super.labelStyle,
    required super.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    final band = d.x as RawBandScale;
    final plot = d.plotArea;
    final a = d.active;
    if (a != null) {
      // The picked band: a soft dent pressed into the ground, the bars
      // standing in it.
      final x = band.map(a.index.toDouble());
      final r = math.min(12.0, band.step.abs() / 2);
      final dent = Rect.fromLTRB(
        x - band.step.abs() / 2 + 2,
        plot.top,
        x + band.step.abs() / 2 - 2,
        plot.bottom,
      );
      final shape = Path();
      clayAddShape(shape, dent, r);
      clayPaintWell(
        canvas,
        shape,
        colors: c,
        side: dent.shortestSide,
        mirrored: direction == TextDirection.rtl,
      );
    }
    paintAxes(canvas);
    if (d.states.contains(WidgetState.focused)) _focusRim(canvas, c, size);
  }
}

/// Places the readout above the point it reads (below when there is no
/// room), clear of a finger, inside the chart.
class _ReadoutLayout extends SingleChildLayoutDelegate {
  _ReadoutLayout(this.anchor, this.gap);

  final Offset anchor;
  final double gap;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints.loosen();

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchor.dx - child.width / 2)
        .clamp(0.0, math.max(0.0, size.width - child.width))
        .toDouble();
    var y = anchor.dy - gap - child.height;
    if (y < 0) y = anchor.dy + gap;
    return Offset(
      x,
      y.clamp(0.0, math.max(0.0, size.height - child.height)).toDouble(),
    );
  }

  @override
  bool shouldRelayout(_ReadoutLayout old) =>
      old.anchor != anchor || old.gap != gap;
}

/// The picked point in words, on a small raised slab of the inverse clay.
class _Readout extends StatelessWidget {
  const _Readout({required this.title, required this.rows});

  final String title;
  final List<(Color, String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final ink = c.onColor(c.inverse);
    final text = theme.textTheme.caption.copyWith(color: ink);
    return ExcludeSemantics(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 220),
        child: ClaySurface(
          face: ClayFace.raised(
            c,
            color: c.inverse,
            radius: ClayRadius.small + 3,
          ).copyWith(elevation: 0.8),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.medium,
              vertical: ClaySpacing.small,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: text.copyWith(
                    fontWeight: FontWeight.w600,
                    fontVariations: clayWeight(FontWeight.w600),
                  ),
                ),
                for (final (color, name, value) in rows)
                  Padding(
                    padding: const EdgeInsets.only(top: ClaySpacing.hairline),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: ShapeDecoration(
                            shape: const CircleBorder(),
                            color: color,
                          ),
                        ),
                        const SizedBox(width: ClaySpacing.small),
                        Flexible(
                          child: Text(
                            '$name  $value',
                            style: text.copyWith(
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small balls of each series' colour beside its name.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<(Color, String)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    return ExcludeSemantics(
      child: Wrap(
        spacing: ClaySpacing.regular,
        runSpacing: ClaySpacing.small,
        children: [
          for (final (color, name) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 12,
                  child: ClaySurface(
                    face: ClayFace.raised(
                      c,
                      color: color,
                      radius: 6,
                    ).copyWith(elevation: 0.5),
                  ),
                ),
                const SizedBox(width: ClaySpacing.small),
                Flexible(child: Text(name, style: theme.textTheme.secondary)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The x of [index] in words, as the chart's axis would say it.
String _xWords(
  RawWidgetsLocalizations l,
  ClayChartXAxis axis,
  double x,
  List<String>? categories,
  String Function(double)? format,
) {
  if (format != null) return format(x);
  switch (axis) {
    case RawChartXAxis.band:
      final i = x.round();
      return categories != null && i >= 0 && i < categories.length
          ? categories[i]
          : l.formatDecimal(i + 1.0);
    case RawChartXAxis.time:
      return l.formatFullDate(DateTime.fromMillisecondsSinceEpoch(x.round()));
    case RawChartXAxis.linear:
      return l.formatDecimal(x);
  }
}

/// A cartesian chart in Clay: the plot, the readout over it, the legend
/// under it.
class _Cartesian extends StatelessWidget {
  const _Cartesian({
    required this.series,
    required this.semanticLabel,
    required this.xAxis,
    required this.categories,
    required this.formatX,
    required this.formatY,
    required this.height,
    required this.palette,
    required this.labelColor,
    required this.paint,
    this.marks,
    this.yIncludesZero = true,
    this.semanticSummary,
    this.onActivePointChanged,
  });

  final List<ClayChartSeries> series;
  final String semanticLabel;
  final ClayChartXAxis xAxis;
  final List<String>? categories;
  final String Function(double)? formatX;
  final String Function(double)? formatY;
  final double height;
  final List<Color> palette;
  final Color? labelColor;
  final CustomPainter Function(
    RawChartDetails details,
    TextStyle labels,
    TextDirection direction,
  )
  paint;
  final List<Widget> Function(RawChartDetails details)? marks;
  final bool yIncludesZero;
  final String? semanticSummary;
  final ValueChanged<RawChartPointRef?>? onActivePointChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final l = RawWidgetsLocalizations.of(context);
    final direction = Directionality.of(context);
    final labels = theme.textTheme.caption.copyWith(
      color: labelColor ?? c.inkSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final chart = SizedBox(
      height: height,
      child: RawChart(
        series: series,
        semanticLabel: semanticLabel,
        semanticSummary: semanticSummary,
        xAxis: xAxis,
        categories: categories,
        formatX: formatX,
        formatY: formatY,
        yIncludesZero: yIncludesZero,
        onActivePointChanged: onActivePointChanged,
        padding: const EdgeInsetsDirectional.fromSTEB(
          ClaySpacing.huge,
          ClaySpacing.medium,
          ClaySpacing.medium,
          ClaySpacing.extraLarge,
        ),
        stiffness: ClayMotion.panelStiffness,
        builder: (context, d) {
          final a = d.active;
          final at = d.activePosition;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(size: d.size, painter: paint(d, labels, direction)),
              ...?marks?.call(d),
              if (a != null && at != null)
                Positioned.fill(
                  child: CustomSingleChildLayout(
                    delegate: _ReadoutLayout(
                      at,
                      d.activeBy == PointerDeviceKind.touch ? 40 : 14,
                    ),
                    child: _Readout(
                      title: _xWords(
                        l,
                        xAxis,
                        d.series[a.series].points[a.index].x,
                        categories,
                        formatX,
                      ),
                      rows: [
                        for (final (i, s) in d.series.indexed)
                          if (a.index < s.points.length &&
                              s.points[a.index].y != null)
                            (
                              palette[i],
                              s.label,
                              formatY?.call(s.points[a.index].y!) ??
                                  l.formatDecimal(s.points[a.index].y!),
                            ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
    if (series.length < 2) return chart;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        chart,
        const SizedBox(height: ClaySpacing.medium),
        _Legend(
          entries: [for (final (i, s) in series.indexed) (palette[i], s.label)],
        ),
      ],
    );
  }
}

/// A line chart: each series a coil of clay along a soft, never
/// overshooting curve over pressed grid grooves. Hover, a finger's scrub or
/// the arrow keys pick a point: a ball rises on each line there and a slab
/// reads them; a legend names the series when there are two or more.
///
/// ```dart
/// ClayLineChart(semanticLabel: 'Glasses a day', series: const [ClayChartSeries(label: 'Glasses', points: [ClayChartPoint(0, 5), ClayChartPoint(1, 7), ClayChartPoint(2, 6)])])
/// ```
class ClayLineChart extends StatelessWidget {
  /// A line chart of [series].
  const ClayLineChart({
    super.key,
    required this.series,
    required this.semanticLabel,
    this.xAxis = RawChartXAxis.linear,
    this.categories,
    this.formatX,
    this.formatY,
    this.yIncludesZero = false,
    this.height = 220,
    this.semanticSummary,
    this.onActivePointChanged,
    this.style,
  });

  /// The data.
  final List<ClayChartSeries> series;

  /// The chart's name, said first.
  final String semanticLabel;

  /// What the x values are.
  final ClayChartXAxis xAxis;

  /// A band axis's category names.
  final List<String>? categories;

  /// The x values in words; null: the reader's numbers or dates.
  final String Function(double value)? formatX;

  /// The y values in words; null: the reader's numbers.
  final String Function(double value)? formatY;

  /// Whether the y scale reaches 0.
  final bool yIncludesZero;

  /// The plot's height.
  final double height;

  /// What a screen reader hears of the data; null: a sentence built from it.
  final String? semanticSummary;

  /// The picked point changed.
  final ValueChanged<RawChartPointRef?>? onActivePointChanged;

  /// This chart's own style, over [ClayThemeData.lineChartStyle]: `fill`
  /// the first series, `foreground` the axes' words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) => _line(
    context,
    filled: false,
    themeStyle: ClayTheme.of(context).lineChartStyle,
  );

  Widget _line(
    BuildContext context, {
    required bool filled,
    required ClayStyle? themeStyle,
  }) {
    final c = ClayTheme.of(context).colors;
    final layered = RawStyleOf([style, themeStyle], const {});
    final palette = _palette(c, layered, series.length);
    return _Cartesian(
      series: series,
      semanticLabel: semanticLabel,
      semanticSummary: semanticSummary,
      xAxis: xAxis,
      categories: categories,
      formatX: formatX,
      formatY: formatY,
      height: height,
      palette: palette,
      labelColor: layered.foreground,
      yIncludesZero: yIncludesZero,
      onActivePointChanged: onActivePointChanged,
      paint: (d, labels, direction) => _LinePainter(
        details: d,
        colors: c,
        labelStyle: labels,
        direction: direction,
        palette: palette,
        filled: filled,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length))
      ..add(EnumProperty<ClayChartXAxis>('xAxis', xAxis));
  }
}

/// An area chart: a [ClayLineChart] with a wash of each series' colour
/// under its line, down to zero. Its theme slot is
/// [ClayThemeData.areaChartStyle].
///
/// ```dart
/// ClayAreaChart(semanticLabel: 'Minutes read', series: const [ClayChartSeries(label: 'Minutes', points: [ClayChartPoint(0, 12), ClayChartPoint(1, 20), ClayChartPoint(2, 15)])])
/// ```
class ClayAreaChart extends ClayLineChart {
  /// An area chart of [series].
  const ClayAreaChart({
    super.key,
    required super.series,
    required super.semanticLabel,
    super.xAxis,
    super.categories,
    super.formatX,
    super.formatY,
    super.height,
    super.semanticSummary,
    super.onActivePointChanged,
    super.style,
  }) : super(yIncludesZero: true);

  @override
  Widget build(BuildContext context) => _line(
    context,
    filled: true,
    themeStyle: ClayTheme.of(context).areaChartStyle,
  );
}

/// A bar chart: a raised pill of clay per value, lit from above, standing
/// on zero; series side by side in each category. Hover, a finger or the
/// arrow keys pick a category: a soft dent forms behind its bars and a slab
/// reads them.
///
/// ```dart
/// ClayBarChart(semanticLabel: 'Habits kept this week', categories: const ['Mon', 'Tue', 'Wed'], series: const [ClayChartSeries(label: 'Kept', points: [ClayChartPoint(0, 4), ClayChartPoint(1, 5), ClayChartPoint(2, 3)])])
/// ```
class ClayBarChart extends StatelessWidget {
  /// A bar chart of [series] over [categories].
  const ClayBarChart({
    super.key,
    required this.series,
    required this.categories,
    required this.semanticLabel,
    this.formatY,
    this.height = 220,
    this.semanticSummary,
    this.onActivePointChanged,
    this.style,
  });

  /// The data: each point's x its category's index.
  final List<ClayChartSeries> series;

  /// The categories' names, in order.
  final List<String> categories;

  /// The chart's name, said first.
  final String semanticLabel;

  /// The values in words; null: the reader's numbers.
  final String Function(double value)? formatY;

  /// The plot's height.
  final double height;

  /// What a screen reader hears of the data; null: a sentence built from it.
  final String? semanticSummary;

  /// The picked bar changed.
  final ValueChanged<RawChartPointRef?>? onActivePointChanged;

  /// This chart's own style, over [ClayThemeData.barChartStyle]: `fill` the
  /// first series, `foreground` the axes' words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.barChartStyle], const {});
    final palette = _palette(c, layered, series.length, pastel: true);
    return _Cartesian(
      series: series,
      semanticLabel: semanticLabel,
      semanticSummary: semanticSummary,
      xAxis: RawChartXAxis.band,
      categories: categories,
      formatX: null,
      formatY: formatY,
      height: height,
      palette: palette,
      labelColor: layered.foreground,
      onActivePointChanged: onActivePointChanged,
      paint: (d, labels, direction) => _BarPainter(
        details: d,
        colors: c,
        labelStyle: labels,
        direction: direction,
      ),
      // Each bar a raised pill of clay, lit and shaded as every Clay part
      // is; the picked category's bars rise a little.
      marks: (d) => [
        for (final bar in _bars(d, Directionality.of(context)))
          if (bar.rect.height >= 0.5)
            Positioned.fromRect(
              rect: bar.rect,
              child: IgnorePointer(
                child: AnimatedClaySurface(
                  face:
                      ClayFace.raised(
                        c,
                        color: palette[bar.series],
                        radius: math.min(
                          12,
                          math.min(bar.rect.width, bar.rect.height) / 2,
                        ),
                      ).copyWith(
                        elevation: 0.7,
                        lift: d.active?.index == bar.index ? 1 : 0,
                      ),
                ),
              ),
            ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length))
      ..add(IntProperty('categories', categories.length));
  }
}

/// How far the picked piece eases out of the ring.
const double _donutPush = 5;

/// A donut's pieces: each a piece of pastel clay ([claySliceShapes]: a gap
/// of the ground between each, round ends, each piece's area its share),
/// casting one soft shadow straight down in its own hue, round a hole
/// pressed into the ground. The picked piece eases out and rises by [lift].
class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.details,
    required this.colors,
    required this.palette,
    required this.lift,
    required this.mirrored,
  });

  final RawPieChartDetails details;
  final ClayColors colors;
  final List<Color> palette;

  /// How far each piece has risen, 0 to 1.
  final List<double> lift;
  final bool mirrored;

  /// The ring's outer edge, inside the chart's radius: room for a piece to
  /// ease out and for its shadow.
  static double outerOf(RawPieChartDetails d) => math.max(0, d.radius - 8);

  /// The ring's inner edge: the hole's, or for a pie a small hub of the
  /// ground the pieces part round.
  static double innerOf(RawPieChartDetails d) => d.holeRadius > 0
      ? math.min(d.holeRadius, outerOf(d) - 1)
      : math.min(6, outerOf(d) / 8);

  /// The well pressed into the hole, a ring of the ground inside the
  /// pieces; null when the hole is too small for one.
  static double? wellOf(RawPieChartDetails d) {
    if (d.holeRadius <= 0) return null;
    final r = innerOf(d) - 7;
    return r >= 8 ? r : null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    final outer = outerOf(d);
    final inner = innerOf(d);
    final band = outer - inner;
    if (band <= 0) return;
    final well = wellOf(d);
    if (well != null) {
      clayPaintWell(
        canvas,
        Path()..addOval(Rect.fromCircle(center: d.centre, radius: well)),
        colors: c,
        side: well * 2,
        mirrored: mirrored,
      );
    }
    final shapes = claySliceShapes(
      [for (final s in d.slices) s.value],
      outer: outer,
      inner: inner,
      mirrored: mirrored,
    );
    final pieces = <(Path, Color, double)>[];
    for (final (i, shape) in shapes.indexed) {
      if (shape == null) continue;
      final up = i < lift.length ? lift[i] : 0.0;
      final at =
          d.centre +
          Offset(math.cos(shape.mid), math.sin(shape.mid)) * _donutPush * up;
      pieces.add((
        shape.path(at, outer, inner),
        palette[i % palette.length],
        up,
      ));
    }
    // Every shadow first, so none lies over a neighbouring piece.
    for (final (path, color, up) in pieces) {
      clayPaintDrop(
        canvas,
        path,
        colors: c,
        color: color,
        side: band,
        lift: up,
      );
    }
    for (final (path, color, _) in pieces) {
      clayPaintVolume(
        canvas,
        path,
        colors: c,
        color: color,
        side: band,
        mirrored: mirrored,
      );
    }
    if (d.states.contains(WidgetState.focused)) _focusRim(canvas, c, size);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.details != details ||
      old.colors != colors ||
      old.mirrored != mirrored ||
      !listEquals(old.palette, palette) ||
      !listEquals(old.lift, lift);
}

/// A donut drawn from its details, the picked piece rising on Clay's lift
/// spring as it is picked and settling back as it is let go.
class _Donut extends StatefulWidget {
  const _Donut({
    required this.details,
    required this.colors,
    required this.palette,
  });

  final RawPieChartDetails details;
  final ClayColors colors;
  final List<Color> palette;

  @override
  State<_Donut> createState() => _DonutState();
}

class _DonutState extends State<_Donut> with SingleTickerProviderStateMixin {
  late final AnimationController _t = AnimationController(vsync: this, value: 1)
    ..addListener(() => setState(() {}));
  late int? _active = widget.details.active;
  List<double> _from = const [];

  double _lift(int i) {
    final to = i == _active ? 1.0 : 0.0;
    if (_t.value >= 1) return to;
    final from = i < _from.length ? _from[i] : 0.0;
    return from + (to - from) * _t.value;
  }

  @override
  void didUpdateWidget(_Donut old) {
    super.didUpdateWidget(old);
    final a = widget.details.active;
    if (a == _active) return;
    _from = [for (var i = 0; i < widget.details.slices.length; i++) _lift(i)];
    _active = a;
    _t.value = 0;
    final policy = RawMotionPolicy.of(context);
    unawaited(
      _t.springTo(
        1,
        policy.reduceMotion
            ? policy.effects(
                dampingRatio: 1,
                stiffness: ClayMotion.liftStiffness,
              )
            : policy.spatial(
                dampingRatio: ClayMotion.liftDamping,
                stiffness: ClayMotion.liftStiffness,
              ),
      ),
    );
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomPaint(
    size: widget.details.size,
    painter: _DonutPainter(
      details: widget.details,
      colors: widget.colors,
      palette: widget.palette,
      lift: [for (var i = 0; i < widget.details.slices.length; i++) _lift(i)],
      mirrored: Directionality.of(context) == TextDirection.rtl,
    ),
  );
}

/// A donut of pastel clay: each slice its own piece, a small gap of the
/// ground between each, its ends rounded, lit inside its top-leading edge
/// and shaded inside its bottom-trailing one, casting one soft shadow
/// straight down in its own hue, round a hole pressed into the ground that
/// holds the total. The picked slice (hover, a finger, the arrow keys) eases
/// out of the ring and rises, and its share is read in the hole. A legend
/// of clay balls under it names each slice, its value and share.
///
/// The pieces stay honest: each piece's area is its share of all the clay,
/// so the gaps and round ends never change how big a share looks. A piece
/// too small to round keeps square ends. When a value changes the pieces
/// spring to their new shares, never jumping.
///
/// ```dart
/// ClayPieChart(semanticLabel: 'Time by habit', slices: const [ClayPieSlice(label: 'Walk', value: 40), ClayPieSlice(label: 'Read', value: 25)])
/// ```
class ClayPieChart extends StatelessWidget {
  /// A donut of [slices].
  const ClayPieChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.formatValue,
    this.centerLabel,
    this.centerCaption,
    this.size = 200,
    this.holeRadius = 0.58,
    this.semanticSummary,
    this.onActiveSliceChanged,
    this.style,
  });

  /// The slices, clockwise from twelve o'clock.
  final List<ClayPieSlice> slices;

  /// The chart's name, said first.
  final String semanticLabel;

  /// The values in words; null: the reader's numbers.
  final String Function(double value)? formatValue;

  /// What the hole says while nothing is picked (a total).
  final String? centerLabel;

  /// A word under [centerLabel].
  final String? centerCaption;

  /// The donut's side.
  final double size;

  /// The hole, a share of the radius; 0 for a pie.
  final double holeRadius;

  /// What a screen reader hears of the data; null: a sentence built from it.
  final String? semanticSummary;

  /// The picked slice changed.
  final ValueChanged<int?>? onActiveSliceChanged;

  /// This chart's own style, over [ClayThemeData.pieChartStyle]: `fill`
  /// the first slice.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final l = RawWidgetsLocalizations.of(context);
    final layered = RawStyleOf([style, theme.pieChartStyle], const {});
    final palette = _palette(c, layered, slices.length, pastel: true);
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    String value(double v) => formatValue?.call(v) ?? l.formatDecimal(v);
    String share(double v) => total <= 0 ? '' : l.formatPercent(v / total);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox.square(
            dimension: size,
            child: RawPieChart(
              slices: slices,
              semanticLabel: semanticLabel,
              semanticSummary: semanticSummary,
              formatValue: formatValue,
              holeRadius: holeRadius,
              onActiveSliceChanged: onActiveSliceChanged,
              stiffness: ClayMotion.panelStiffness,
              builder: (context, d) {
                final a = d.active;
                final big = a == null ? centerLabel : share(slices[a].value);
                final small = a == null ? centerCaption : slices[a].label;
                final well = _DonutPainter.wellOf(d);
                final bigStyle = theme.textTheme.headline.copyWith(
                  color: c.ink,
                  fontFeatures: const [FontFeature.tabularFigures()],
                );
                final smallStyle = theme.textTheme.caption;
                return Stack(
                  children: [
                    _Donut(details: d, colors: c, palette: palette),
                    if (holeRadius > 0.3 &&
                        well != null &&
                        (big != null || small != null))
                      Positioned.fromRect(
                        rect: _inCircle(
                          context,
                          [(big, bigStyle), (small, smallStyle)],
                          center: d.centre,
                          radius: well * 0.9,
                        ),
                        child: ExcludeSemantics(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (big != null) Text(big, style: bigStyle),
                                if (small != null)
                                  Text(small, style: smallStyle),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
        const SizedBox(height: ClaySpacing.medium),
        _Legend(
          entries: [
            for (final (i, s) in slices.indexed)
              (palette[i], '${s.label}  ${value(s.value)} · ${share(s.value)}'),
          ],
        ),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('slices', slices.length));
  }
}

// The box, of the shape [lines] make set one under another, that stands in
// the circle of [radius] at [center] corner to corner: the hole's words
// shrink into it rather than reach the ring at a large text size.
Rect _inCircle(
  BuildContext context,
  List<(String?, TextStyle)> lines, {
  required Offset center,
  required double radius,
}) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  );
  final base = DefaultTextStyle.of(context).style;
  var width = 0.0, height = 0.0;
  for (final (text, style) in lines) {
    if (text == null) continue;
    painter
      ..text = TextSpan(text: text, style: base.merge(style))
      ..layout();
    width = math.max(width, painter.width);
    height += painter.height;
  }
  painter.dispose();
  final diagonal = math.sqrt(width * width + height * height);
  if (diagonal <= 0) return Rect.fromCircle(center: center, radius: radius);
  return Rect.fromCenter(
    center: center,
    width: 2 * radius * width / diagonal,
    height: 2 * radius * height / diagonal,
  );
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.details,
    required this.colors,
    required this.color,
  });

  final RawChartDetails details;
  final ClayColors colors;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    if (d.series.isEmpty) return;
    for (final run in _runs(d, d.series.first)) {
      if (run.length > 1) {
        _coil(canvas, c, _smooth(run), color, 2.5);
      }
    }
    final points = d.series.first.points;
    final a = d.active;
    final i = a?.index ?? points.lastIndexWhere((p) => p.y != null);
    if (i >= 0 && points[i].y != null) {
      _ball(
        canvas,
        c,
        d.positionOf(RawChartPointRef(0, i)),
        color,
        a == null ? 3.5 : 5,
      );
    }
    if (d.states.contains(WidgetState.focused)) _focusRim(canvas, c, size);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.details != details || old.colors != colors || old.color != color;
}

/// A sparkline: a thin coil of clay through [values], no axes, a ball on
/// its last value (on the picked one while one is). Its name and values
/// are said; it is one tab stop, as a chart is.
///
/// ```dart
/// const ClaySparkline(semanticLabel: 'Water this week', values: [5, 7, 6, 8, 7, 8, 6])
/// ```
class ClaySparkline extends StatelessWidget {
  /// A sparkline of [values].
  const ClaySparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.width,
    this.height = 40,
    this.formatValue,
    this.style,
  });

  /// The values, in order.
  final List<double> values;

  /// Its name, said first.
  final String semanticLabel;

  /// Its width; null spans its parent.
  final double? width;

  /// Its height.
  final double height;

  /// The values in words; null: the reader's numbers.
  final String Function(double value)? formatValue;

  /// This sparkline's own style, over [ClayThemeData.sparklineStyle]:
  /// `fill` the line.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.sparklineStyle], const {});
    final color = layered.fill ?? c.accent;
    return SizedBox(
      width: width,
      height: height,
      child: RawChart(
        semanticLabel: semanticLabel,
        series: [
          RawChartSeries(
            label: semanticLabel,
            points: [
              for (final (i, v) in values.indexed)
                RawChartPoint(i.toDouble(), v),
            ],
          ),
        ],
        yIncludesZero: false,
        formatY: formatValue,
        padding: const EdgeInsets.all(ClaySpacing.tight),
        stiffness: ClayMotion.panelStiffness,
        builder: (context, d) => CustomPaint(
          size: d.size,
          painter: _SparkPainter(details: d, colors: c, color: color),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('values', values.length));
  }
}
