// General series charts for apps and kit parts, on the same pressed material.
import 'component_themes.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'frames.dart';
import 'format.dart';
import 'layout.dart';
import 'localizations.dart';
import 'raised.dart';
import 'rows.dart';
import 'tell.dart';
import 'styled.dart';
import 'theme.dart';

/// A continuous line with gaps, the same line over a filled area, or grouped columns.
/// The geometry used to display chart samples.
enum NeumorphicChartKind {
  /// Connected observations, with gaps for absent values.
  line,

  /// Separate bars for each observation.
  bar,

  /// The line over a faint fill down to zero: an amount that accumulates or a volume over time.
  area,
}

/// A named series. Null and non-finite values leave a gap.
@immutable
class NeumorphicChartSeries {
  /// Creates a [NeumorphicChartSeries].
  const NeumorphicChartSeries(this.label, this.values);

  /// The series name used in the legend and semantics.
  final String label;

  /// Ordered samples; null or non-finite values leave a gap.
  final List<double?> values;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicChartSeries &&
      other.label == label &&
      listEquals(other.values, values);
  @override
  int get hashCode => Object.hash(label, Object.hashAll(values));
}

/// A shaded target interval behind all series.
@immutable
class NeumorphicChartBand {
  /// Creates a [NeumorphicChartBand].
  const NeumorphicChartBand(this.low, this.high, {this.label})
    : assert(low <= high);

  /// The lower bound of the shaded interval.
  final double low;

  /// The upper bound of the shaded interval.
  final double high;

  /// An optional name for the shaded interval.
  final String? label;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicChartBand &&
      other.low == low &&
      other.high == high &&
      other.label == label;
  @override
  int get hashCode => Object.hash(low, high, label);
}

/// Multiple series share a scale, with real gaps and an optional target band.
/// Series use solid, dashed and dotted strokes, filled areas, or individually outlined bars. Hover or touch the plot
/// to read one position's values in a raised readout; [loading] shows the well's skeleton; no values show the empty
/// state.
///
/// ```dart
/// NeumorphicChart(label: 'Hours slept', series: const [NeumorphicChartSeries('Sleep', [7, null, 8])])
/// ```
class NeumorphicChart extends StatelessWidget {
  /// Creates a [NeumorphicChart].
  const NeumorphicChart({
    super.key,
    this.style,
    required this.label,
    required this.series,
    this.kind = NeumorphicChartKind.line,
    this.labels = const [],
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
  }) : assert(height >= 60);

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The accessible name of the chart.
  final String label;

  /// The series drawn together on a shared scale.
  final List<NeumorphicChartSeries> series;

  /// Whether samples are drawn as connected lines or bars.
  final NeumorphicChartKind kind;

  /// Category labels corresponding to sample positions.
  final List<String> labels;

  /// An optional shaded reference interval.
  final NeumorphicChartBand? band;

  /// An optional spoken summary of the chart.
  final String? summary;

  /// Height of the plotted area; labels grow outside it.
  final double height;

  /// Formats numeric values for labels and semantics.
  final String Function(double value)? format;

  /// Whether the series are still on their way: the well holds a skeleton of the plot.
  final bool loading;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    if (loading) {
      return _ChartLoading(label: label, style: style, height: height + 32);
    }
    final fmt =
        format ?? (double value) => NeumorphicFormat.number(context, value);
    final values = [
      for (final s in series)
        for (final value in s.values)
          if (value != null && value.isFinite) value,
    ];
    if (values.isEmpty) {
      return NeumorphicEmptyState(
        title: NeumorphicLocalizations.of(context).nothingToShow,
      );
    }
    final least = math.min(
      0.0,
      math.min(values.reduce(math.min), band?.low ?? double.infinity),
    );
    final most = math.max(
      least + 1,
      math.max(values.reduce(math.max), band?.high ?? double.negativeInfinity),
    );
    // The gridlines stand on a round step, four of them at most across the data, and the plot runs from whole step to
    // whole step, so every gridline is labelled with a round value in the gutter.
    final step = _niceStep((most - least) / 4);
    final low = (least / step).floor() * step;
    final steps = math.max(1, ((most - low) / step - 1e-9).ceil());
    final high = low + steps * step;
    final ticks = [for (var i = 0; i <= steps; i++) low + i * step];
    final scaler = MediaQuery.textScalerOf(context);
    final tickStyle = DefaultTextStyle.of(context).style
        .merge(t.textTheme.micro.tabular);
    var gutter = 0.0, tickHeight = 0.0;
    for (final value in ticks) {
      final painter = TextPainter(
        text: TextSpan(text: fmt(value), style: tickStyle),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      )..layout();
      gutter = math.max(gutter, painter.width);
      tickHeight = math.max(tickHeight, painter.height);
      painter.dispose();
    }
    gutter = gutter.ceilToDouble();
    const gutterGap = 8.0;
    final read =
        summary ??
        [
          for (final s in series)
            '${s.label}: ${[for (final value in s.values)
              if (value != null && value.isFinite) fmt(value)].join(', ')}',
          if (band != null)
            '${band!.label ?? ''} ${fmt(band!.low)}–${fmt(band!.high)}',
        ].join('; ');
    final direction = Directionality.of(context);
    final wellLook = NeumorphicStyleOf([
      style,
      t.cardTheme,
    ], NeumorphicStatesScope.of(context));
    // The plot's inset inside the well, as the well resolves it: its padding and its shape's own width.
    final inset =
        (wellLook.padding(direction) ?? const EdgeInsets.all(14)) +
        (wellLook.shape?.dimensions.resolve(direction) ?? EdgeInsets.zero);
    final count = series.fold<int>(0, (n, s) => math.max(n, s.values.length));
    const barRadius = 2.0;
    return Semantics(
      container: true,
      label: label,
      value: read,
      child: ExcludeSemantics(
        child: NeumorphicFill(
          maxWidth: 680,
          alignment: AlignmentDirectional.topStart,
          child: NeumorphicColumn(
            gap: 8,
            children: [
              NeumorphicWell(
                style: style,
                padding: const EdgeInsets.all(14),
                // The top and bottom labels stand centred on their gridlines, half a line past the plot's 4 px margin.
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: math.max(0.0, tickHeight / 2 - 4),
                  ),
                  child: Row(
                    textDirection: TextDirection.ltr,
                    children: [
                      neumorphicOwnSize(
                        width: gutter,
                        height: height,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            for (final value in ticks)
                              Positioned(
                                right: 0,
                                top:
                                    4 +
                                    (high - value) /
                                        (high - low) *
                                        math.max(0.0, height - 8) -
                                    tickHeight / 2,
                                child: Text(
                                  fmt(value),
                                  style: t.textTheme.micro.tabular,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: gutterGap),
                      Expanded(
                        child: SizedBox(
                          height: height,
                          child: _Readout(
                            count: series.fold<int>(
                              0,
                              (n, s) => math.max(n, s.values.length),
                            ),
                            kind: kind,
                            groups: series.length,
                            read: (i) => [
                              if (i < labels.length) labels[i],
                              for (final s in series)
                                if (i < s.values.length &&
                                    s.values[i] != null &&
                                    s.values[i]!.isFinite)
                                  '${s.label} ${fmt(s.values[i]!)}',
                            ].join('\n'),
                            builder: (selected) => CustomPaint(
                              painter: _ChartPainter(
                                series,
                                kind,
                                band,
                                low,
                                high,
                                step,
                                t.colors,
                                barRadius,
                                selected,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (labels.isNotEmpty)
                _AxisLabels(
                  labels: labels,
                  kind: kind,
                  count: count,
                  // The well's inset, the gutter and the plot's own 4 px margin: the labels sit under the bars and
                  // points.
                  left: inset.left + gutter + gutterGap,
                  right: inset.right,
                  style: t.textTheme.micro,
                ),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final (i, s) in series.indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        neumorphicOwnSize(
                          width: 24,
                          height: 12,
                          child: CustomPaint(
                            painter: _SeriesKeyPainter(
                              i,
                              t.colors,
                              bar: kind == NeumorphicChartKind.bar,
                              radius: barRadius,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(s.label, style: t.textTheme.caption),
                        ),
                      ],
                    ),
                  if (band != null)
                    Text(
                      '${band!.label ?? ''} ${fmt(band!.low)}–${fmt(band!.high)}',
                      style: t.textTheme.caption,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

typedef _ChartColors = ({List<Color> inks, Color band});

final _chartColors = Expando<_ChartColors>();

double _lightness(double luminance) => luminance > 216 / 24389
    ? 116 * math.pow(luminance, 1 / 3).toDouble() - 16
    : luminance * 24389 / 27;

Color _atLightness(Color ink, double lightness) {
  final target = lightness > 8
      ? math.pow((lightness + 16) / 116, 3).toDouble()
      : lightness * 27 / 24389;
  final lighter = target > ink.computeLuminance();
  final end = lighter ? const Color(0xFFFFFFFF) : const Color(0xFF000000);
  var low = 0.0, high = 1.0;
  for (var i = 0; i < 28; i++) {
    final middle = (low + high) / 2;
    final color = Color.lerp(ink, end, middle)!;
    if ((color.computeLuminance() < target) == lighter) {
      low = middle;
    } else {
      high = middle;
    }
  }
  return Color.lerp(ink, end, (low + high) / 2)!;
}

_ChartColors _chartPalette(NeumorphicColors c) => _chartColors[c] ??= (() {
  final grounds = [c.ground, c.faceStart, c.faceEnd, c.wellStart, c.wellEnd];
  double limit(double opacity) {
    final wash = c.quiet.withValues(alpha: opacity);
    final luminances = [
      ...grounds,
      for (final ground in grounds) Color.alphaBlend(wash, ground),
    ].map((color) => color.computeLuminance());
    final boundary = c.dark
        ? (luminances.reduce(math.max) + .05) * 3.1 - .05
        : (luminances.reduce(math.min) + .05) / 3.1 - .05;
    return _lightness(boundary.clamp(0.0, 1.0));
  }

  // A target interval keeps its printed outline. On a custom palette with
  // little luminance room, reduce only its wash until all three inks fit.
  var opacity = .12;
  double room(double alpha) => c.dark ? 100 - limit(alpha) : limit(alpha);
  if (room(opacity) < 41.5) {
    var low = 0.0, high = opacity;
    for (var i = 0; i < 24; i++) {
      final middle = (low + high) / 2;
      if (room(middle) >= 41.5) {
        low = middle;
      } else {
        high = middle;
      }
    }
    opacity = low;
  }
  // Three ink tones, still in the material's hue. L* separation alone gives
  // at least 20 CIELAB units; the extra half unit survives 8-bit rasterization.
  // The faintest line keeps 3.1:1 on every surface, with room above 3:1.
  final gap = math.min(20.5, room(opacity) / 2);
  final edge = limit(opacity);
  final own = _lightness(c.ink.computeLuminance());
  final first = c.dark
      ? math.max(own, edge + gap * 2).clamp(0.0, 100.0)
      : math.min(own, edge - gap * 2).clamp(0.0, 100.0);
  return (
    inks: [
      for (var i = 0; i < 3; i++)
        _atLightness(c.ink, first + (c.dark ? -1 : 1) * gap * i),
    ],
    band: c.quiet.withValues(alpha: opacity),
  );
})();

Color _seriesInk(NeumorphicColors c, int index) {
  final inks = _chartPalette(c).inks;
  return inks[index % inks.length];
}

void _seriesLine(Canvas canvas, Offset a, Offset b, int index, Paint paint) {
  if (index % 3 == 0) {
    canvas.drawLine(a, b, paint);
    return;
  }
  final delta = b - a, length = delta.distance;
  if (length == 0) return;
  final dash = index % 3 == 1 ? 7.0 : 2.0;
  for (var start = 0.0; start < length; start += dash + 4) {
    canvas.drawLine(
      a + delta * (start / length),
      a + delta * (math.min(start + dash, length) / length),
      paint,
    );
  }
}

/// A series' key: a stroke sample for a line or an area, a square in the bar's ink and corner for bars.
class _SeriesKeyPainter extends CustomPainter {
  const _SeriesKeyPainter(
    this.index,
    this.colors, {
    this.bar = false,
    this.radius = 2,
  });
  final int index;
  final NeumorphicColors colors;
  final bool bar;
  final double radius;
  @override
  void paint(Canvas canvas, Size size) {
    final ink = _seriesInk(colors, index);
    if (bar) {
      final side = math.min(size.height, size.width);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, (size.height - side) / 2, side, side),
          Radius.circular(radius),
        ),
        Paint()..color = ink,
      );
      return;
    }
    _seriesLine(
      canvas,
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      index,
      Paint()
        ..color = ink
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_SeriesKeyPainter old) =>
      old.index != index ||
      old.colors != colors ||
      old.bar != bar ||
      old.radius != radius;
}

/// The category labels under a chart's well, each centred on its own bar or point: the same x the painter uses
/// ([_plotX]), offset by the well's inset, so a label never drifts from its data at any width.
class _AxisLabels extends StatelessWidget {
  const _AxisLabels({
    required this.labels,
    required this.kind,
    required this.count,
    required this.left,
    required this.right,
    required this.style,
  });
  final List<String> labels;
  final NeumorphicChartKind kind;
  final int count;
  final double left, right;
  final TextStyle style;
  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    final words = DefaultTextStyle.of(context).style.merge(style);
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final plot = Rect.fromLTWH(
          left + 4,
          0,
          math.max(0, width - left - right - 8),
          1,
        );
        final n = math.max(count, 1);
        final slot = kind == NeumorphicChartKind.bar
            ? plot.width / n
            : n <= 1
            ? plot.width
            : plot.width / (n - 1);
        final placed = <(String, double, double)>[];
        var height = 0.0;
        for (var i = 0; i < math.min(labels.length, n); i++) {
          final x = _plotX(plot, i, n, kind);
          final w = math.max(
            1.0,
            math.min(slot, math.min(2 * x, 2 * (width - x))),
          );
          final painter = TextPainter(
            text: TextSpan(text: labels[i], style: words),
            textAlign: TextAlign.center,
            textDirection: TextDirection.ltr,
            textScaler: scaler,
          )..layout(maxWidth: w);
          height = math.max(height, painter.height);
          painter.dispose();
          placed.add((labels[i], x, w));
        }
        // The width is the row's own; only the height is the labels'.
        return SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (value, x, w) in placed)
                Positioned(
                  left: x - w / 2,
                  top: 0,
                  width: w,
                  child: Text(
                    value,
                    style: style,
                    textAlign: TextAlign.center,
                    textDirection: TextDirection.ltr,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter(
    List<NeumorphicChartSeries> series,
    this.kind,
    this.band,
    this.low,
    this.high,
    this.step,
    this.colors,
    this.barRadius,
    this.selected,
  ) : series = [
        for (final s in series)
          NeumorphicChartSeries(s.label, List.unmodifiable(s.values)),
      ];
  final List<NeumorphicChartSeries> series;
  final NeumorphicChartKind kind;
  final NeumorphicChartBand? band;
  final double low, high, step;
  final NeumorphicColors colors;
  final double barRadius;
  final int? selected;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final area = _plotArea(size);
    if (area.isEmpty) return;
    final count = series.fold<int>(0, (n, s) => math.max(n, s.values.length));
    double y(double v) => area.bottom - (v - low) / (high - low) * area.height;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    if (band != null) {
      canvas.drawRect(
        Rect.fromLTRB(area.left, y(band!.high), area.right, y(band!.low)),
        Paint()..color = _chartPalette(colors).band,
      );
      final edge = Paint()
        ..color = colors.edge
        ..strokeWidth = 1;
      canvas.drawLine(
        Offset(area.left, y(band!.high)),
        Offset(area.right, y(band!.high)),
        edge,
      );
      canvas.drawLine(
        Offset(area.left, y(band!.low)),
        Offset(area.right, y(band!.low)),
        edge,
      );
    }
    final guide = Paint()
      ..color = colors.crease
      ..strokeWidth = 1;
    // One gridline a step, each labelled in the gutter beside the plot.
    final steps = ((high - low) / step).round();
    for (var i = 0; i <= steps; i++) {
      final at = y(low + i * step);
      canvas.drawLine(Offset(area.left, at), Offset(area.right, at), guide);
    }
    if (selected != null && selected! < count) {
      final x = _plotX(area, selected!, count, kind);
      canvas.drawLine(
        Offset(x, area.top),
        Offset(x, area.bottom),
        Paint()
          ..color = colors.inkTertiary
          ..strokeWidth = 1,
      );
    }
    if (kind == NeumorphicChartKind.area) {
      final zero = y(0).clamp(area.top, area.bottom);
      for (final (index, s) in series.indexed) {
        final fill = Paint()
          ..color = _seriesInk(colors, index).withValues(alpha: .14);
        Path? run;
        double? first, last;
        void close() {
          if (run != null && first != null && last != null) {
            run!
              ..lineTo(last!, zero)
              ..lineTo(first!, zero)
              ..close();
            canvas.drawPath(run!, fill);
          }
          run = null;
          first = last = null;
        }

        for (final (i, value) in s.values.indexed) {
          if (value == null || !value.isFinite) {
            close();
            continue;
          }
          final x = _plotX(area, i, count, kind);
          if (run == null) {
            run = Path()
              ..moveTo(x, zero)
              ..lineTo(x, y(value));
            first = x;
          } else {
            run!.lineTo(x, y(value));
          }
          last = x;
        }
        close();
      }
    }
    for (final (index, s) in series.indexed) {
      final ink = _seriesInk(colors, index);
      final paint = Paint()
        ..color = ink
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round;
      Offset? previous, last;
      for (final (i, value) in s.values.indexed) {
        if (value == null || !value.isFinite) {
          previous = null;
          continue;
        }
        if (kind == NeumorphicChartKind.bar) {
          final group = area.width / math.max(count, 1);
          final width = group * .75 / math.max(series.length, 1);
          final left = area.left + i * group + group * .125 + index * width;
          final rect = Rect.fromLTRB(
            left + 1,
            math.min(y(0), y(value)),
            left + math.max(1, width - 1),
            math.max(y(0), y(value)),
          );
          // Bars follow the corner family: square in the square family, a 2 px round otherwise.
          final bar = RRect.fromRectAndRadius(rect, Radius.circular(barRadius));
          canvas.drawRRect(
            bar,
            i == selected ? (Paint()..color = colors.ink) : paint,
          );
          canvas.drawRRect(
            bar,
            Paint()
              ..color = colors.ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1,
          );
        } else {
          final point = Offset(_plotX(area, i, count, kind), y(value));
          if (previous != null) {
            _seriesLine(canvas, previous, point, index, paint);
          }
          canvas.drawCircle(point, i == selected ? 4.5 : 2.5, paint);
          previous = point;
          last = point;
        }
      }
      if (last != null) canvas.drawCircle(last, 4, Paint()..color = ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      !listEquals(series, old.series) ||
      kind != old.kind ||
      band != old.band ||
      low != old.low ||
      high != old.high ||
      step != old.step ||
      colors != old.colors ||
      barRadius != old.barRadius ||
      selected != old.selected;
}

Rect _plotArea(Size size) => (Offset.zero & size).deflate(4);

/// A round step at least [raw]: 1, 2, 2.5 or 5 times a power of ten.
double _niceStep(double raw) {
  if (!raw.isFinite || raw <= 0) return 1;
  final power = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final f = raw / power;
  final nice = f <= 1
      ? 1.0
      : f <= 2
      ? 2.0
      : f <= 2.5
      ? 2.5
      : f <= 5
      ? 5.0
      : 10.0;
  return nice * power;
}

/// Where sample [i] of [count] sits across the plot: on the line's points, or at the middle of its bar group.
double _plotX(Rect area, int i, int count, NeumorphicChartKind kind) {
  if (kind == NeumorphicChartKind.bar) {
    final group = area.width / math.max(count, 1);
    return area.left + group * (i + .5);
  }
  return count <= 1 ? area.center.dx : area.left + area.width * i / (count - 1);
}

/// The sample nearest [x] across the plot.
int _plotIndex(Rect area, double x, int count, NeumorphicChartKind kind) {
  if (kind == NeumorphicChartKind.bar) {
    final group = area.width / math.max(count, 1);
    return ((x - area.left) / group).floor().clamp(0, count - 1);
  }
  if (count <= 1) return 0;
  return ((x - area.left) / area.width * (count - 1)).round().clamp(
    0,
    count - 1,
  );
}

/// The plot with a readout: a mouse over it or a touch on it marks the nearest sample and raises its values above
/// the plot. The values are in the chart's semantics already, so the readout itself is not announced.
class _Readout extends StatefulWidget {
  const _Readout({
    required this.count,
    required this.kind,
    required this.groups,
    required this.read,
    required this.builder,
  });
  final int count, groups;
  final NeumorphicChartKind kind;
  final String Function(int index) read;
  final Widget Function(int? selected) builder;
  @override
  State<_Readout> createState() => _ReadoutState();
}

class _ReadoutState extends State<_Readout> {
  int? _selected;

  void _at(Offset local) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize || widget.count == 0) return;
    final index = _plotIndex(
      _plotArea(box.size),
      local.dx,
      widget.count,
      widget.kind,
    );
    if (index != _selected) setState(() => _selected = index);
  }

  void _clear() {
    if (_selected != null) setState(() => _selected = null);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected != null && _selected! < widget.count
        ? _selected
        : null;
    return MouseRegion(
      onHover: (event) => _at(event.localPosition),
      onExit: (_) => _clear(),
      child: Listener(
        onPointerDown: (event) => _at(event.localPosition),
        onPointerMove: (event) => _at(event.localPosition),
        behavior: HitTestBehavior.opaque,
        child: LayoutBuilder(
          builder: (context, box) {
            final text = selected == null ? '' : widget.read(selected);
            return Stack(
              clipBehavior: Clip.none,
              fit: StackFit.expand,
              children: [
                widget.builder(selected),
                if (text.isNotEmpty)
                  Align(
                    // The readout follows the sample and stays inside the plot.
                    alignment: Alignment(
                      (_plotX(
                                    _plotArea(box.biggest),
                                    selected!,
                                    widget.count,
                                    widget.kind,
                                  ) /
                                  math.max(box.maxWidth, 1) *
                                  2 -
                              1)
                          .clamp(-1.0, 1.0),
                      -1,
                    ),
                    child: IgnorePointer(
                      child: NeumorphicTooltipFace(message: text),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A chart's well while its values load: the frame the plot will fill, with the look's skeleton in it.
class _ChartLoading extends StatelessWidget {
  const _ChartLoading({required this.label, this.style, required this.height});
  final String label;
  final NeumorphicStyle? style;
  final double height;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label: label,
    value: NeumorphicLocalizations.of(context).loading,
    child: ExcludeSemantics(
      child: NeumorphicFill(
        maxWidth: 680,
        alignment: AlignmentDirectional.topStart,
        child: NeumorphicWell(
          style: style,
          padding: const EdgeInsets.all(14),
          child: LayoutBuilder(
            builder: (context, box) => NeumorphicSkeleton.box(
              aspect:
                  (box.hasBoundedWidth ? math.min(box.maxWidth, 640.0) : 240) /
                  height,
            ),
          ),
        ),
      ),
    ),
  );
}

/// One part of a whole, for [NeumorphicPieChart].
@immutable
class NeumorphicPieSlice {
  /// Creates a [NeumorphicPieSlice].
  const NeumorphicPieSlice(this.label, this.value) : assert(value >= 0);

  /// The part's name, in the key and the readout.
  final String label;

  /// The part's amount; the ring shows its share of the sum.
  final double value;
  @override
  bool operator ==(Object other) =>
      other is NeumorphicPieSlice &&
      other.label == label &&
      other.value == value;
  @override
  int get hashCode => Object.hash(label, value);
}

/// Shares of a whole as a ring in a pressed well, its key beside it (below it when narrow). The three chart inks
/// tell the first three slices apart; slices four to six are the same inks drawn hollow. The middle holds the total,
/// or the slice under the mouse or the last touch. [loading] shows a skeleton; a sum of zero shows the empty state.
///
/// ```dart
/// NeumorphicPieChart(label: 'Where the time went', slices: const [NeumorphicPieSlice('Work', 6), NeumorphicPieSlice('Rest', 2)])
/// ```
class NeumorphicPieChart extends StatefulWidget {
  /// Creates a [NeumorphicPieChart].
  const NeumorphicPieChart({
    super.key,
    required this.label,
    required this.slices,
    this.total,
    this.caption,
    this.summary,
    this.size = 168,
    this.format,
    this.loading = false,
    this.style,
  }) : assert(size >= 96);

  /// The accessible name of the chart.
  final String label;

  /// The parts, in key order, at most six: fold the rest into one 'Other'.
  final List<NeumorphicPieSlice> slices;

  /// The figure in the middle; null prints the formatted sum.
  final String? total;

  /// The words under the middle figure.
  final String? caption;

  /// An optional spoken summary; null reads every slice and its share.
  final String? summary;

  /// The ring's diameter.
  final double size;

  /// Formats amounts for the middle and the key.
  final String Function(double value)? format;

  /// Whether the parts are still on their way.
  final bool loading;

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;
  @override
  State<NeumorphicPieChart> createState() => _NeumorphicDonutState();
}

class _NeumorphicDonutState extends State<NeumorphicPieChart> {
  int? _selected;

  int? _sliceAt(Offset local, double sum) {
    final size = widget.size, ring = size * .15;
    final centre = Offset(size / 2, size / 2), delta = local - centre;
    final radius = (size - ring) / 2 - 4;
    if ((delta.distance - radius).abs() > ring / 2 + 6) return null;
    var turn = math.atan2(delta.dy, delta.dx) + math.pi / 2;
    if (turn < 0) turn += 2 * math.pi;
    var at = 0.0;
    for (final (i, slice) in widget.slices.indexed) {
      at += slice.value / sum * 2 * math.pi;
      if (turn <= at) return i;
    }
    return widget.slices.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.slices.length <= 6,
      'Six slices at most: the three inks, solid and hollow.',
    );
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    if (widget.loading) {
      return _ChartLoading(
        label: widget.label,
        style: widget.style,
        height: widget.size,
      );
    }
    final fmt =
        widget.format ??
        (double value) => NeumorphicFormat.number(context, value);
    final sum = widget.slices.fold<double>(0, (n, s) => n + s.value);
    if (sum <= 0) {
      return NeumorphicEmptyState(title: words.nothingToShow);
    }
    final selected = _selected != null && _selected! < widget.slices.length
        ? _selected
        : null;
    String share(NeumorphicPieSlice s) => words.formatPercent(s.value / sum);
    final read =
        widget.summary ??
        [
          for (final s in widget.slices)
            '${s.label}: ${fmt(s.value)}, ${share(s)}',
        ].join('; ');
    final middle = selected == null
        ? (widget.total ?? fmt(sum), widget.caption)
        : (
            fmt(widget.slices[selected].value),
            '${widget.slices[selected].label}, ${share(widget.slices[selected])}',
          );
    void at(Offset local) {
      final index = _sliceAt(local, sum);
      if (index != _selected) setState(() => _selected = index);
    }

    final ring = MouseRegion(
      onHover: (event) => at(event.localPosition),
      onExit: (_) => setState(() => _selected = null),
      child: Listener(
        onPointerDown: (event) => at(event.localPosition),
        child: SizedBox.square(
          dimension: widget.size,
          child: CustomPaint(
            painter: _DonutPainter(widget.slices, sum, selected, t.colors),
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(widget.size * .2),
                // The hole's width for the words to wrap in; under large text the readout scales down to the hole
                // rather than spill out of it. Its words grow only so far (1.3), as an instrument face's do: at twice
                // the text the caption broke over three lines and its corners grazed the ring.
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: widget.size * .6,
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            middle.$1,
                            style: t.textTheme.value,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (middle.$2 != null)
                            Text(
                              middle.$2!,
                              style: t.textTheme.micro,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final key = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, s) in widget.slices.indexed)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox.square(
                  dimension: 14,
                  child: CustomPaint(painter: _SliceKeyPainter(i, t.colors)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    s.label,
                    style: t.textTheme.caption.copyWith(
                      color: i == selected ? t.colors.ink : null,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(fmt(s.value), style: t.textTheme.caption.tabular),
                // The share's column grows with the text, a gap before it: a fixed 52 ran '9.2' into '57%' at
                // twice the text ('9.257%').
                const SizedBox(width: 10),
                SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(44),
                  child: Text(
                    share(s),
                    style: t.textTheme.micro.tabular,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
    return Semantics(
      container: true,
      label: widget.label,
      value: read,
      child: ExcludeSemantics(
        child: NeumorphicFill(
          maxWidth: 680,
          alignment: AlignmentDirectional.topStart,
          child: NeumorphicWell(
            style: widget.style,
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, box) =>
                  !box.hasBoundedWidth || box.maxWidth >= widget.size + 220
                  ? Row(
                      children: [
                        ring,
                        const SizedBox(width: 24),
                        // A key as wide as a key reads, beside the ring: run across a wide well, each slice's
                        // figures stood 300 px from its name, and the eye lost the row between them.
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.textScalerOf(context)
                                    .scale(320),
                              ),
                              child: key,
                            ),
                          ),
                        ),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Center(child: ring),
                        const SizedBox(height: 16),
                        key,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints slice [index]'s band, solid for the first three and hollow for the next three.
void _paintSlice(
  Canvas canvas,
  Rect oval,
  double start,
  double sweep,
  double width,
  int index,
  NeumorphicColors colors,
) {
  final ink = _seriesInk(colors, index);
  if (index < 3) {
    canvas.drawArc(
      oval,
      start,
      sweep,
      false,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    return;
  }
  final outer = oval.inflate(width / 2), inner = oval.deflate(width / 2);
  final band = Path()
    ..arcTo(outer, start, sweep, true)
    ..arcTo(inner, start + sweep, -sweep, false)
    ..close();
  canvas.drawPath(
    band,
    Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5,
  );
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(
    List<NeumorphicPieSlice> slices,
    this.sum,
    this.selected,
    this.colors,
  ) : slices = List.unmodifiable(slices);
  final List<NeumorphicPieSlice> slices;
  final double sum;
  final int? selected;
  final NeumorphicColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final width = size.shortestSide * .15;
    final oval = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - width) / 2 - 4,
    );
    // The ring's groove, where no slice reaches.
    canvas.drawCircle(
      oval.center,
      oval.width / 2,
      Paint()
        ..color = colors.quiet.withValues(alpha: .35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    final gap = slices.where((s) => s.value > 0).length > 1
        ? 3 / (oval.width / 2)
        : 0.0;
    var start = -math.pi / 2;
    for (final (i, s) in slices.indexed) {
      final sweep = s.value / sum * 2 * math.pi;
      if (sweep > gap) {
        _paintSlice(
          canvas,
          oval,
          start + gap / 2,
          sweep - gap,
          i == selected ? width + 6 : width,
          i,
          colors,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      !listEquals(slices, old.slices) ||
      sum != old.sum ||
      selected != old.selected ||
      colors != old.colors;
}

class _SliceKeyPainter extends CustomPainter {
  const _SliceKeyPainter(this.index, this.colors);
  final int index;
  final NeumorphicColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final box = (Offset.zero & size).deflate(1);
    final ink = _seriesInk(colors, index);
    canvas.drawOval(
      box,
      index < 3
          ? (Paint()..color = ink)
          : (Paint()
              ..color = ink
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5),
    );
  }

  @override
  bool shouldRepaint(_SliceKeyPainter old) =>
      old.index != index || old.colors != colors;
}

/// A word-sized trend line with no axes, for a stat or a row: the first chart ink, its last value marked. Fewer than
/// two values draw a level dash.
///
/// ```dart
/// NeumorphicSparkline(label: 'Steps this week', values: const [4.2, 6.1, 5.0, 7.3])
/// ```
class NeumorphicSparkline extends StatelessWidget {
  /// Creates a [NeumorphicSparkline].
  const NeumorphicSparkline({
    super.key,
    required this.label,
    required this.values,
    this.summary,
    this.width = 96,
    this.height = 32,
    this.format,
  }) : assert(width >= 32 && height >= 16);

  /// The accessible name of the trend.
  final String label;

  /// Ordered samples; null or non-finite values are left out.
  final List<double?> values;

  /// An optional spoken summary; null reads the values.
  final String? summary;

  /// The line's width.
  final double width;

  /// The line's height.
  final double height;

  /// Formats values for semantics.
  final String Function(double value)? format;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final fmt =
        format ?? (double value) => NeumorphicFormat.number(context, value);
    final points = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    return Semantics(
      container: true,
      label: label,
      value: summary ?? points.map(fmt).join(', '),
      child: ExcludeSemantics(
        child: neumorphicOwnSize(
          width: width,
          height: height,
          child: CustomPaint(painter: _SparkPainter(points, t.colors)),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(List<double> points, this.colors)
    : points = List.unmodifiable(points);
  final List<double> points;
  final NeumorphicColors colors;
  @override
  void paint(Canvas canvas, Size size) {
    final area = (Offset.zero & size).deflate(4);
    final ink = _seriesInk(colors, 0);
    if (points.length < 2) {
      canvas.drawLine(
        area.centerLeft,
        area.centerRight,
        Paint()
          ..color = colors.inkTertiary
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    final low = points.reduce(math.min), high = points.reduce(math.max);
    final span = high - low == 0 ? 1.0 : high - low;
    Offset at(int i) => Offset(
      area.left + area.width * i / (points.length - 1),
      high == low
          ? area.center.dy
          : area.bottom - (points[i] - low) / span * area.height,
    );
    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < points.length; i++) {
      line.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.75
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(at(points.length - 1), 3, Paint()..color = ink);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(points, old.points) || colors != old.colors;
}
