/// Clay's charts on ui_core's headless charts: lines rolled like coils of
/// clay, areas washed under them, bars standing as raised pills, a donut of
/// clay segments and a sparkline. ui_core picks points (pointer, finger,
/// keys, screen reader) and says them; Clay draws every mark.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/sprites.dart' show clayDrawShape;
import 'surface.dart';
import 'theme.dart';

/// A named run of points, in order along x.
typedef ClayChartSeries = DesignChartSeries;

/// A point of a [ClayChartSeries]: x and y, or a gap where y is null.
typedef ClayChartPoint = DesignChartPoint;

/// What a chart's x values are: numbers, times or categories.
typedef ClayChartXAxis = DesignChartXAxis;

/// A slice of a [ClayPieChart].
typedef ClayPieSlice = DesignPieSlice;

/// The colour of the [i]th series: the accent first, then the pastels
/// deepened until a line of them stands 3:1 from the clay.
Color claySeriesColor(ClayColors c, int i) {
  if (i == 0) return c.accent;
  const order = [
    ClayTint.sky,
    ClayTint.mint,
    ClayTint.lilac,
    ClayTint.butter,
    ClayTint.rose,
    ClayTint.peach,
  ];
  final night = c.brightness == Brightness.dark;
  final hsl = HSLColor.fromColor(c.tint(order[(i - 1) % order.length]));
  return hsl
      .withSaturation(math.max(hsl.saturation, 0.55))
      .withLightness(night ? 0.68 : 0.46)
      .toColor();
}

/// The first colours of a chart: [style]'s fill, then the series colours.
List<Color> _palette(ClayColors c, DesignStyleOf layered, int count) => [
  for (var i = 0; i < count; i++)
    i == 0 ? (layered.fill ?? claySeriesColor(c, 0)) : claySeriesColor(c, i),
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
List<List<Offset>> _runs(DesignChartDetails d, DesignChartSeries s) {
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

/// A coil of clay along [path]: its shadow, its body and a lit ridge.
void _coil(Canvas canvas, Path path, Color color, Color shade, double width) {
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

  final DesignChartDetails details;
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
    for (final (i, s) in d.series.indexed) {
      final color = palette[i];
      for (final run in _runs(d, s)) {
        final line = _smooth(run);
        if (filled && run.length > 1) {
          final area = Path.from(line)
            ..lineTo(run.last.dx, base)
            ..lineTo(run.first.dx, base)
            ..close();
          canvas.drawPath(
            area,
            Paint()
              ..shader = LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  color.withValues(alpha: 0.34),
                  color.withValues(alpha: 0.04),
                ],
              ).createShader(plot),
          );
        }
        if (run.length == 1) {
          _ball(canvas, c, run.first, color, 4);
        } else {
          _coil(canvas, line, color, c.shadeOf(color), 4);
        }
      }
    }
    if (a != null) {
      for (final (i, s) in d.series.indexed) {
        if (a.index >= s.points.length || s.points[a.index].y == null) {
          continue;
        }
        final at = d.positionOf(DesignChartPointRef(i, a.index));
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
  DesignChartDetails d,
  TextDirection direction,
) {
  final band = d.x as DesignBandScale;
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
    final band = d.x as DesignBandScale;
    final plot = d.plotArea;
    final a = d.active;
    if (a != null) {
      // The picked band: a soft dent the bars stand in.
      final x = band.map(a.index.toDouble());
      final r = math.min(12.0, band.step.abs() / 2);
      final dent = Rect.fromLTRB(
        x - band.step.abs() / 2 + 2,
        plot.top,
        x + band.step.abs() / 2 - 2,
        plot.bottom,
      );
      clayDrawShape(
        canvas,
        dent,
        r,
        Paint()..color = c.shadeOf(c.clay).withValues(alpha: 0.10),
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
  DesignLocalizations l,
  ClayChartXAxis axis,
  double x,
  List<String>? categories,
  String Function(double)? format,
) {
  if (format != null) return format(x);
  switch (axis) {
    case DesignChartXAxis.band:
      final i = x.round();
      return categories != null && i >= 0 && i < categories.length
          ? categories[i]
          : l.formatDecimal(i + 1.0);
    case DesignChartXAxis.time:
      return l.formatFullDate(DateTime.fromMillisecondsSinceEpoch(x.round()));
    case DesignChartXAxis.linear:
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
    DesignChartDetails details,
    TextStyle labels,
    TextDirection direction,
  )
  paint;
  final List<Widget> Function(DesignChartDetails details)? marks;
  final bool yIncludesZero;
  final String? semanticSummary;
  final ValueChanged<DesignChartPointRef?>? onActivePointChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final l = DesignLocalizations.of(context);
    final direction = Directionality.of(context);
    final labels = theme.textTheme.caption.copyWith(
      color: labelColor ?? c.inkSecondary,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final chart = SizedBox(
      height: height,
      child: DesignChart(
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
    this.xAxis = DesignChartXAxis.linear,
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
  final ValueChanged<DesignChartPointRef?>? onActivePointChanged;

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
    final layered = DesignStyleOf([style, themeStyle], const {});
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
  final ValueChanged<DesignChartPointRef?>? onActivePointChanged;

  /// This chart's own style, over [ClayThemeData.barChartStyle]: `fill` the
  /// first series, `foreground` the axes' words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.barChartStyle], const {});
    final palette = _palette(c, layered, series.length);
    return _Cartesian(
      series: series,
      semanticLabel: semanticLabel,
      semanticSummary: semanticSummary,
      xAxis: DesignChartXAxis.band,
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

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.details,
    required this.colors,
    required this.palette,
  });

  final DesignPieChartDetails details;
  final ClayColors colors;
  final List<Color> palette;

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    final r = d.radius - 6;
    final hole = d.holeRadius;
    // The well the donut sits in.
    canvas.drawCircle(
      d.centre,
      r + 4,
      Paint()..color = c.shadeOf(c.clay).withValues(alpha: 0.10),
    );
    for (final (i, s) in d.slices.indexed) {
      if (s.sweepAngle.abs() < 0.001) continue;
      final picked = d.active == i;
      final push = picked ? 5.0 : 0.0;
      final mid = s.midAngle;
      final at = d.centre + Offset(math.cos(mid), math.sin(mid)) * push;
      final outer = Rect.fromCircle(center: at, radius: r);
      final inner = Rect.fromCircle(center: at, radius: math.max(hole, 0.0));
      final path = Path()..arcTo(outer, s.startAngle, s.sweepAngle, true);
      if (hole > 0) {
        path.arcTo(inner, s.startAngle + s.sweepAngle, -s.sweepAngle, false);
      } else {
        path.lineTo(at.dx, at.dy);
      }
      path.close();
      final color = palette[i % palette.length];
      final shade = c.shadeOf(color);
      canvas
        ..drawPath(
          path.shift(const Offset(0, 3)),
          Paint()
            ..color = shade.withValues(alpha: picked ? 0.42 : 0.3)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
        )
        ..drawPath(path, Paint()..color = color)
        ..drawPath(
          path,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.35, -0.45),
              radius: 1.1,
              colors: [
                const Color(0xFFFFFFFF).withValues(alpha: 0.3),
                const Color(0x00FFFFFF),
                shade.withValues(alpha: 0.22),
              ],
              stops: const [0, 0.55, 1],
            ).createShader(outer),
        )
        // A seam of the card between slices.
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.5
            ..strokeJoin = StrokeJoin.round
            ..color = c.clay,
        );
    }
    if (d.states.contains(WidgetState.focused)) _focusRim(canvas, c, size);
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.details != details ||
      old.colors != colors ||
      !listEquals(old.palette, palette);
}

/// A donut of clay segments, a seam of the card between each; the picked
/// one (hover, a finger, the arrow keys) eases out of the ring and its
/// share is read in the hole. A legend under it names each slice, its value
/// and share.
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
    final l = DesignLocalizations.of(context);
    final layered = DesignStyleOf([style, theme.pieChartStyle], const {});
    final palette = _palette(c, layered, slices.length);
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    String value(double v) => formatValue?.call(v) ?? l.formatDecimal(v);
    String share(double v) => total <= 0 ? '' : '${(v / total * 100).round()}%';
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: SizedBox.square(
            dimension: size,
            child: DesignPieChart(
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
                return Stack(
                  children: [
                    CustomPaint(
                      size: d.size,
                      painter: _DonutPainter(
                        details: d,
                        colors: c,
                        palette: palette,
                      ),
                    ),
                    if (holeRadius > 0.3 && (big != null || small != null))
                      Positioned.fromRect(
                        rect: Rect.fromCircle(
                          center: d.centre,
                          radius: d.holeRadius * 0.86,
                        ),
                        child: ExcludeSemantics(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (big != null)
                                  Text(
                                    big,
                                    style: theme.textTheme.headline.copyWith(
                                      color: c.ink,
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                if (small != null)
                                  Text(small, style: theme.textTheme.caption),
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

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.details,
    required this.colors,
    required this.color,
  });

  final DesignChartDetails details;
  final ClayColors colors;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final d = details;
    final c = colors;
    if (d.series.isEmpty) return;
    for (final run in _runs(d, d.series.first)) {
      if (run.length > 1) {
        _coil(canvas, _smooth(run), color, c.shadeOf(color), 2.5);
      }
    }
    final points = d.series.first.points;
    final a = d.active;
    final i = a?.index ?? points.lastIndexWhere((p) => p.y != null);
    if (i >= 0 && points[i].y != null) {
      _ball(
        canvas,
        c,
        d.positionOf(DesignChartPointRef(0, i)),
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
    final layered = DesignStyleOf([style, theme.sparklineStyle], const {});
    final color = layered.fill ?? c.accent;
    return SizedBox(
      width: width,
      height: height,
      child: DesignChart(
        semanticLabel: semanticLabel,
        series: [
          DesignChartSeries(
            label: semanticLabel,
            points: [
              for (final (i, v) in values.indexed)
                DesignChartPoint(i.toDouble(), v),
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
