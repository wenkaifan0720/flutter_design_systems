/// Line, area and donut charts: series over a run of labels, and parts of
/// a whole.
library;

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/styled.dart';
import '../localizations.dart';
import '../theme.dart';
import 'feedback.dart';

/// One named run of values in a [MinimalLineChart] or [MinimalAreaChart]:
/// one value per label. [color] overrides the chart's palette.
@immutable
class MinimalChartSeries {
  /// A series called [name] through [values].
  const MinimalChartSeries(this.name, this.values, {this.color});

  /// What it measures, in the legend.
  final String name;

  /// Its values, one per label.
  final List<double> values;

  /// Its colour; null takes the next of the chart's.
  final Color? color;
}

/// One part of a [MinimalPieChart]'s whole.
@immutable
class MinimalChartSlice {
  /// A part called [label] worth [value].
  const MinimalChartSlice(this.label, this.value, {this.color});

  /// What it is, in the legend.
  final String label;

  /// How much it is.
  final double value;

  /// Its colour; null takes the next of the chart's.
  final Color? color;
}

/// The colours a chart gives its series in order: the accent first, then
/// the ink, then a grey and the tones — so one series is the accent and a
/// second reads against it in either mode.
///
/// By day the grey is the faint ink. By night the ink is softened a fifth
/// toward the ground and the grey is the quiet ink: a slice of the full
/// ink glares on the dark ground, and one of the faint ink all but sinks
/// into it.
List<Color> minimalChartPalette(MinimalThemeData t) => [
  t.primary,
  if (t.isLightAppearance) ...[
    t.foreground,
    t.textTertiary,
  ] else ...[
    Color.alphaBlend(t.foreground.withValues(alpha: 0.8), t.card),
    t.mutedForeground,
  ],
  t.success,
  t.warning,
  t.destructive,
];

String _figure(double v) {
  if (v.abs() >= 10000) return '${(v / 1000).toStringAsFixed(0)}k';
  if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}k';
  return v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

/// A step of 1, 2 or 5 times a power of ten near [rough].
double _nice(double rough) {
  if (rough <= 0) return 1;
  final power = math.pow(10, (math.log(rough) / math.ln10).floor()).toDouble();
  final f = rough / power;
  final step = f <= 1
      ? 1
      : f <= 2
      ? 2
      : f <= 5
      ? 5
      : 10;
  return step * power;
}

/// The scale a plot of [series] runs on: its lowest and highest rule and
/// the step between them. [series] holds at least one value.
({double bottom, double top, double step}) _scaleOf(List<List<double>> series) {
  final all = [for (final s in series) ...s];
  var lo = all.reduce(math.min);
  var hi = all.reduce(math.max);
  if (lo > 0) lo = 0;
  if (hi == lo) hi = lo + 1;
  final step = _nice((hi - lo) / 4);
  return (
    bottom: (lo / step).floor() * step,
    top: (hi / step).ceil() * step,
    step: step,
  );
}

/// A series over a run of labels — signups a day, revenue a month, two
/// plans against each other: 1.6 px lines with round joins on a plot of
/// hairline rules, the values' scale in mono down its start edge and
/// [labels] in mono under it, a legend over it when there is more than one
/// series. The first series takes the accent.
///
/// The readout follows the pointer, a finger dragged across it, or the
/// arrow keys once the chart has focus: a hairline down the nearest label,
/// a dot on each line and a small card with the label and every series'
/// value — a chart's readout is information, so it answers a hovering
/// pointer. [loading] shows a pulsing placeholder over the whole box the
/// chart takes (its plot and the labels under it); with no values the
/// plot's rules run across that box and say so ([emptyLabel], else
/// "No data").
///
/// ```dart
/// MinimalLineChart(series: [MinimalChartSeries('Signups', weekly)], labels: const ['M', 'T', 'W', 'T', 'F', 'S', 'S'])
/// ```
class MinimalLineChart extends StatelessWidget {
  /// Lines through [series].
  const MinimalLineChart({
    super.key,
    required this.series,
    this.labels,
    this.height = 180,
    this.loading = false,
    this.emptyLabel,
    this.semanticLabel,
    this.format,
  });

  /// The lines.
  final List<MinimalChartSeries> series;

  /// One short label per value (`M`, `Jan`, `09:00`), in mono under the
  /// plot; long runs print as many as fit, evenly spaced, the first and the
  /// last among them whenever two fit.
  final List<String>? labels;

  /// The plot's height.
  final double height;

  /// Whether the data is still coming: a skeleton.
  final bool loading;

  /// What a chart with no values says.
  final String? emptyLabel;

  /// What a screen reader hears for the chart as a whole.
  final String? semanticLabel;

  /// How a value prints in the scale and the readout; null prints it
  /// short (`1.2k`).
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context) => _SeriesChart(
    series: series,
    labels: labels,
    height: height,
    loading: loading,
    emptyLabel: emptyLabel,
    semanticLabel: semanticLabel,
    format: format ?? _figure,
    area: false,
  );
}

/// A [MinimalLineChart] with the ground under each line filled with one
/// flat, faint tint of its colour: for a
/// quantity that accumulates or a total over time, where the area itself
/// says "how much". Everything else — the scale, the labels, the legend,
/// the readout, the loading and empty states — is the line chart's.
///
/// ```dart
/// MinimalAreaChart(series: [MinimalChartSeries('Revenue', monthly)], labels: months, format: (v) => '\$${v.round()}')
/// ```
class MinimalAreaChart extends StatelessWidget {
  /// Filled areas under [series].
  const MinimalAreaChart({
    super.key,
    required this.series,
    this.labels,
    this.height = 180,
    this.loading = false,
    this.emptyLabel,
    this.semanticLabel,
    this.format,
  });

  /// The areas.
  final List<MinimalChartSeries> series;

  /// The run of labels under the chart.
  final List<String>? labels;

  /// Its plot's height.
  final double height;

  /// Whether the data is still coming: a skeleton.
  final bool loading;

  /// What a chart with no values says.
  final String? emptyLabel;

  /// What a screen reader calls the chart.
  final String? semanticLabel;

  /// Prints a value in the readout and to a screen reader.
  final String Function(double value)? format;

  @override
  Widget build(BuildContext context) => _SeriesChart(
    series: series,
    labels: labels,
    height: height,
    loading: loading,
    emptyLabel: emptyLabel,
    semanticLabel: semanticLabel,
    format: format ?? _figure,
    area: true,
  );
}

class _SeriesChart extends StatefulWidget {
  const _SeriesChart({
    required this.series,
    required this.labels,
    required this.height,
    required this.loading,
    required this.emptyLabel,
    required this.semanticLabel,
    required this.format,
    required this.area,
  });

  final List<MinimalChartSeries> series;
  final List<String>? labels;
  final double height;
  final bool loading;
  final String? emptyLabel;
  final String? semanticLabel;
  final String Function(double) format;
  final bool area;

  @override
  State<_SeriesChart> createState() => _SeriesChartState();
}

class _SeriesChartState extends State<_SeriesChart> {
  int? _at;
  bool _focused = false;

  int get _count =>
      widget.series.fold(0, (n, s) => math.max(n, s.values.length));

  /// The scale's least width at the start edge.
  static const double _axis = 36;

  /// The air between a scale figure and the plot.
  static const double _figureGap = 6;

  /// The air between the plot's lowest rule and the labels under it.
  static const double _labelGap = 6;

  /// The bands over and under the plot, from the line a scale figure or a
  /// label takes at the text scale: over it ([head]) half that line, so the
  /// top figure, centred on the top rule, stands inside the chart's box;
  /// under it ([strip]) the labels' line and the air above it.
  ({double head, double strip}) _bands(TextStyle figure, TextScaler scaler) {
    final tp = TextPainter(
      text: TextSpan(text: '0', style: figure),
      textDirection: TextDirection.ltr,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final line = tp.height;
    tp.dispose();
    return (
      head: (line / 2).ceilToDouble(),
      strip: (_labelGap + line).ceilToDouble(),
    );
  }

  /// The plot's gutters: at the start edge as wide as the widest scale
  /// figure needs (never less than [_axis]), at the end edge half the
  /// widest label, so the last label stands centred on its own point.
  ({double axis, double end}) _gutters(TextStyle figure, TextScaler scaler) {
    double measure(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: figure),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }

    final scale = _scaleOf([for (final s in widget.series) s.values]);
    var widest = 0.0;
    for (
      var v = scale.bottom;
      v <= scale.top + scale.step / 2;
      v += scale.step
    ) {
      widest = math.max(widest, measure(widget.format(v)));
    }
    final names = widget.labels;
    final label = names == null || names.isEmpty
        ? 0.0
        : names
              .take(_count)
              .map(measure)
              .fold<double>(0, (m, w) => math.max(m, w));
    return (
      axis: math.max(_axis, (widest + _figureGap).ceilToDouble()),
      end: (label / 2).ceilToDouble(),
    );
  }

  int _indexAt(double dx, double width, double axis, double end) {
    final n = _count;
    if (n <= 1) return 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final plot = width - axis - end;
    if (plot <= 0) return 0;
    final x = rtl ? width - axis - dx : dx - axis;
    return (x / plot * (n - 1)).round().clamp(0, n - 1);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = _count;
    if (n == 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final forward = rtl
        ? LogicalKeyboardKey.arrowLeft
        : LogicalKeyboardKey.arrowRight;
    final back = rtl
        ? LogicalKeyboardKey.arrowRight
        : LogicalKeyboardKey.arrowLeft;
    if (key == forward) {
      setState(() => _at = ((_at ?? -1) + 1).clamp(0, n - 1));
    } else if (key == back) {
      setState(() => _at = ((_at ?? n) - 1).clamp(0, n - 1));
    } else if (key == LogicalKeyboardKey.escape) {
      setState(() => _at = null);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _readout(int i) {
    final names = widget.labels;
    final head = names != null && i < names.length ? '${names[i]}: ' : '';
    return head +
        [
          for (final s in widget.series)
            if (i < s.values.length) '${s.name} ${widget.format(s.values[i])}',
        ].join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final palette = minimalChartPalette(t);
    final colours = [
      for (var i = 0; i < widget.series.length; i++)
        widget.series[i].color ?? palette[i % palette.length],
    ];
    final legend = widget.series.length > 1
        ? Padding(
            padding: const EdgeInsets.only(bottom: MinimalSpacing.s12),
            child: _Legend(
              names: [for (final s in widget.series) s.name],
              colours: colours,
            ),
          )
        : null;
    final n = _count;
    final figure = t.countFigure.c(t.mutedForeground);
    final scaler = MediaQuery.textScalerOf(context);
    final (:head, :strip) = _bands(figure, scaler);
    // The box a loaded chart takes under its legend: the plot, half a
    // figure's line over it and the labels under it. Loading and empty
    // charts fill the same box, so nothing blank hangs below them.
    final whole = head + widget.height + strip;
    final Widget plot;
    if (widget.loading) {
      // The chart's whole width, as the empty state: with no axis labels
      // drawn yet, a gutter kept for them reads as a misaligned block. A
      // plot-sized block takes the chart's own corners (its focus frame's),
      // not a text line's.
      plot = SizedBox(
        height: whole,
        child: Semantics(
          label: MinimalLocalizations.of(context).loading,
          child: MinimalSkeleton(
            height: double.infinity,
            shape: t.shapes.small,
          ),
        ),
      );
    } else if (n == 0) {
      // The plot's rules with no line on them, and why: one hairline alone
      // would read as a stray divider.
      plot = SizedBox(
        height: whole,
        child: CustomPaint(
          painter: _EmptyPlotPainter(rule: t.border, stroke: t.hairline),
          child: Center(
            child: Text(
              widget.emptyLabel ?? MinimalLocalizations.of(context).noData,
              // Why it is empty is content: the caption's quiet ink, as a
              // table's empty line (the faintest ink is a placeholder's).
              style: t.bodySmall.c(t.mutedForeground),
            ),
          ),
        ),
      );
    } else {
      final at = _at;
      final (:axis, :end) = _gutters(figure, scaler);
      plot = LayoutBuilder(
        builder: (context, box) {
          final width = box.maxWidth;
          final span = width - axis - end;
          int index(double dx) => _indexAt(dx, width, axis, end);
          final painted = CustomPaint(
            size: Size(width, whole),
            painter: _SeriesPainter(
              series: [for (final s in widget.series) s.values],
              colours: colours,
              labels: widget.labels,
              area: widget.area,
              at: at,
              format: widget.format,
              rule: t.border,
              guide: t.textTertiary,
              ground: t.card,
              figure: figure,
              stroke: t.hairline,
              axis: axis,
              end: end,
              figureGap: _figureGap,
              head: head,
              strip: strip,
              labelGap: _labelGap,
              rtl: Directionality.of(context) == TextDirection.rtl,
              scaler: scaler,
            ),
          );
          return MouseRegion(
            onHover: (e) => setState(() => _at = index(e.localPosition.dx)),
            onExit: (_) => setState(() => _at = null),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => setState(() => _at = index(d.localPosition.dx)),
              onHorizontalDragUpdate: (d) =>
                  setState(() => _at = index(d.localPosition.dx)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  painted,
                  if (at != null)
                    _ReadoutCard(
                      label: widget.labels != null && at < widget.labels!.length
                          ? widget.labels![at]
                          : null,
                      rows: [
                        for (var s = 0; s < widget.series.length; s++)
                          if (at < widget.series[s].values.length)
                            (
                              widget.series[s].name,
                              widget.format(widget.series[s].values[at]),
                              colours[s],
                            ),
                      ],
                      x: n <= 1 ? axis + span / 2 : axis + span * at / (n - 1),
                      width: width,
                    ),
                ],
              ),
            ),
          );
        },
      );
    }
    final at = _at;
    final ring =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: at == null || n == 0 ? null : _readout(at),
      child: Focus(
        canRequestFocus: n > 0 && !widget.loading,
        onKeyEvent: _onKey,
        onFocusChange: (v) => setState(() {
          _focused = v;
          if (!v) _at = null;
        }),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: minimalFrame(
            t.shapes.small,
            side: ring
                ? BorderSide(
                    color: t.ring,
                    width: t.focusWidth,
                    strokeAlign: BorderSide.strokeAlignOutside,
                  )
                : BorderSide.none,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [?legend, plot],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.names, required this.colours});

  final List<String> names;
  final List<Color> colours;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return ExcludeSemantics(
      child: Wrap(
        spacing: MinimalSpacing.s12,
        runSpacing: MinimalSpacing.s4,
        children: [
          for (var i = 0; i < names.length; i++)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: ShapeDecoration(
                    color: colours[i],
                    shape: const CircleBorder(),
                  ),
                ),
                const MinimalGap(MinimalSpacing.s4 + 2),
                minimalCapLabel(
                  Text(names[i], style: t.caption.c(t.mutedForeground)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// The readout's card, over the plot's top beside the guide line.
class _ReadoutCard extends StatelessWidget {
  const _ReadoutCard({
    required this.label,
    required this.rows,
    required this.x,
    required this.width,
  });

  final String? label;
  final List<(String, String, Color)> rows;

  /// The guide's x from the plot's left edge.
  final double x;
  final double width;

  static const double _width = 140;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final gx = rtl ? width - x : x;
    // Beside the guide, on the side with room.
    final left = gx + 8 + _width <= width
        ? gx + 8
        : math.max(0.0, gx - 8 - _width);
    final label = this.label;
    return Positioned(
      left: left,
      top: 0,
      width: _width,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalSpacing.s8,
              vertical: MinimalSpacing.s4 + 2,
            ),
            decoration: minimalFrame(
              t.shapes.small,
              fill: t.card,
              side: BorderSide(color: t.border, width: t.hairline),
              shadows: t.shadowSm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (label != null)
                  Text(label, style: t.caption.medium.c(t.foreground)),
                for (final (name, value, colour) in rows)
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: ShapeDecoration(
                          color: colour,
                          shape: const CircleBorder(),
                        ),
                      ),
                      const MinimalGap(MinimalSpacing.s4 + 2),
                      Expanded(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.c(t.mutedForeground),
                        ),
                      ),
                      Text(value, style: t.countFigure.c(t.foreground)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// An empty chart's rules: four hairlines a third of its box apart, top to
/// bottom, as a plot's scale stands, with the words that say why between
/// the middle two.
class _EmptyPlotPainter extends CustomPainter {
  const _EmptyPlotPainter({required this.rule, required this.stroke});

  final Color rule;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < stroke) return;
    final line = Paint()
      ..color = rule
      ..strokeWidth = stroke;
    for (var i = 0; i <= 3; i++) {
      // On the pixel grid, as the scale's rules are, and inside the box.
      final y = ((size.height * i / 3).roundToDouble() + stroke / 2).clamp(
        stroke / 2,
        size.height - stroke / 2,
      );
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
  }

  @override
  bool shouldRepaint(_EmptyPlotPainter old) =>
      old.rule != rule || old.stroke != stroke;
}

class _SeriesPainter extends CustomPainter {
  _SeriesPainter({
    required this.series,
    required this.colours,
    required this.labels,
    required this.area,
    required this.at,
    required this.format,
    required this.rule,
    required this.guide,
    required this.ground,
    required this.figure,
    required this.stroke,
    required this.axis,
    required this.end,
    required this.figureGap,
    required this.head,
    required this.strip,
    required this.labelGap,
    required this.rtl,
    required this.scaler,
  });

  final List<List<double>> series;
  final List<Color> colours;
  final List<String>? labels;
  final bool area;
  final int? at;
  final String Function(double) format;
  final Color rule;
  final Color guide;
  final Color ground;
  final TextStyle figure;
  final double stroke;
  final double axis;

  /// The gutter past the last point, at the end edge.
  final double end;
  final double figureGap;

  /// The band over the plot: room for the top figure's upper half.
  final double head;

  /// The band under the plot: the labels and the air over them.
  final double strip;

  /// The air between the lowest rule and the labels.
  final double labelGap;
  final bool rtl;
  final TextScaler scaler;

  TextPainter _text(String s) => TextPainter(
    text: TextSpan(text: s, style: figure),
    textDirection: TextDirection.ltr,
    textScaler: scaler,
    maxLines: 1,
  )..layout();

  @override
  void paint(Canvas canvas, Size size) {
    final (:bottom, :top, :step) = _scaleOf(series);
    final plotH = size.height - head - strip;
    final plotW = size.width - axis - end;
    final foot = head + plotH;
    final n = series.fold(0, (m, s) => math.max(m, s.length));
    double y(double v) => foot - (v - bottom) / (top - bottom) * plotH;
    double x(int i) {
      final along = n <= 1 ? plotW / 2 : plotW * i / (n - 1);
      return rtl ? size.width - axis - along : axis + along;
    }

    // The scale: a hairline at each step across the plot, from the first
    // point to the last, where an area's fill ends too; its figure in the
    // start gutter, which is as wide as the widest figure needs. Each
    // figure is centred on its rule but the lowest, which rises to stand
    // on its rule (as far as the figure over it leaves room), so the scale
    // stops above the labels and the corner where the two meet keeps its
    // air.
    final line = Paint()
      ..color = rule
      ..strokeWidth = stroke;
    final from = rtl ? end : axis;
    final to = rtl ? size.width - axis : size.width - end;
    final pitch = plotH * step / (top - bottom);
    var lowest = true;
    for (var v = bottom; v <= top + step / 2; v += step) {
      final yy = y(v).roundToDouble() + stroke / 2;
      canvas.drawLine(Offset(from, yy), Offset(to, yy), line);
      final tp = _text(format(v));
      final tx = rtl
          ? size.width - axis + figureGap
          : axis - figureGap - tp.width;
      final rise = lowest
          ? math.min((tp.height + stroke) / 2, math.max(0.0, pitch - tp.height))
          : 0.0;
      tp.paint(canvas, Offset(tx, yy - tp.height / 2 - rise));
      lowest = false;
    }

    // The labels: as many as fit, each centred on its own point, evenly
    // spaced and keeping both ends, so the line never runs past its last
    // label. One that cannot stand on its point inside the chart is left
    // out rather than pushed off it.
    final names = labels;
    if (names != null && names.isNotEmpty && n > 0) {
      final widest = names.map((s) => _text(s).width).reduce(math.max);
      final count = math.min(n, names.length);
      final shown = _evenLabels(
        count,
        pitch: n <= 1 ? 0 : plotW / (n - 1),
        room: widest + 12,
      );
      for (final i in shown) {
        final tp = _text(names[i]);
        final left = x(i) - tp.width / 2;
        if (left < -0.5 || left + tp.width > size.width + 0.5) continue;
        tp.paint(canvas, Offset(left, foot + labelGap));
      }
    }

    // The guide under the readout.
    final a = at;
    if (a != null) {
      canvas.drawLine(
        Offset(x(a), head),
        Offset(x(a), foot),
        Paint()
          ..color = guide
          ..strokeWidth = stroke,
      );
    }

    for (var s = 0; s < series.length; s++) {
      final values = series[s];
      if (values.isEmpty) continue;
      final colour = colours[s];
      final path = Path()..moveTo(x(0), y(values[0]));
      for (var i = 1; i < values.length; i++) {
        path.lineTo(x(i), y(values[i]));
      }
      if (area) {
        final fill = Path.from(path)
          ..lineTo(x(values.length - 1), foot)
          ..lineTo(x(0), foot)
          ..close();
        // One flat tint, as a sparkline's: Minimal draws no gradients.
        canvas.drawPath(fill, Paint()..color = colour.withValues(alpha: 0.1));
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = colour,
      );
      if (a != null && a < values.length) {
        final c = Offset(x(a), y(values[a]));
        canvas
          ..drawCircle(c, 4, Paint()..color = ground)
          ..drawCircle(
            c,
            4,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2
              ..color = colour,
          );
      }
    }
  }

  @override
  bool shouldRepaint(_SeriesPainter old) =>
      old.series != series ||
      old.colours.length != colours.length ||
      old.at != at ||
      old.area != area ||
      old.rule != rule ||
      old.figure != figure ||
      old.axis != axis ||
      old.end != end ||
      old.head != head ||
      old.strip != strip ||
      old.rtl != rtl ||
      old.labels != labels;
}

/// Which of a run of [count] labels, [pitch] apart, a chart prints when
/// each needs [room] from the next: every one when they fit, else the most
/// that fit at evenly spaced indices that keep the first and the last
/// (index `round(i * (count - 1) / (m - 1))` for m labels), else the first
/// alone.
List<int> _evenLabels(
  int count, {
  required double pitch,
  required double room,
}) {
  if (count <= 1) return [for (var i = 0; i < count; i++) i];
  final last = count - 1;
  // No more than the even gaps could hold; fewer when rounding brings two
  // picks a point closer than the rest.
  final most = pitch <= 0
      ? 1
      : math.min(count, (last * pitch / room).floor() + 1);
  for (var m = most; m >= 2; m--) {
    final picks = [for (var i = 0; i < m; i++) (i * last / (m - 1)).round()];
    var fits = true;
    for (var i = 1; i < m && fits; i++) {
      fits = (picks[i] - picks[i - 1]) * pitch >= room;
    }
    if (fits) return picks;
  }
  return const [0];
}

/// Parts of a whole — spend by category, plans by count, a disk by kind:
/// a donut of the [slices] in the chart palette with a 2 px gap of the
/// surface between them, and in its hole the total (or [centerValue] and
/// [centerLabel]); beside it (under it when narrow) a legend of each
/// slice's swatch, label, value and share. Keep it to five or six slices;
/// fold the rest into "Other".
///
/// The readout: pointing at or tapping a slice, or the arrow keys once the
/// chart has focus, picks it — the others fade back and the hole reads
/// that slice's label and share. [loading] shows a pulsing ring; with no
/// values it says so ([emptyLabel], else "No data").
///
/// ```dart
/// MinimalPieChart(slices: const [MinimalChartSlice('Design', 42), MinimalChartSlice('Build', 31), MinimalChartSlice('Ops', 12)], centerLabel: 'Hours')
/// ```
class MinimalPieChart extends StatefulWidget {
  /// A ring of [slices].
  const MinimalPieChart({
    super.key,
    required this.slices,
    this.centerLabel,
    this.centerValue,
    this.size = 168,
    this.thickness = 22,
    this.legend = true,
    this.loading = false,
    this.emptyLabel,
    this.semanticLabel,
    this.format,
  });

  /// The parts.
  final List<MinimalChartSlice> slices;

  /// The words under the figure in the hole ("Hours", "Total").
  final String? centerLabel;

  /// The figure in the hole; null prints the total.
  final String? centerValue;

  /// The donut's diameter.
  final double size;

  /// The ring's width.
  final double thickness;

  /// Whether it lists the parts beside the ring.
  final bool legend;

  /// Whether the data is still coming: a skeleton.
  final bool loading;

  /// What a chart with no values says.
  final String? emptyLabel;

  /// What a screen reader calls the chart.
  final String? semanticLabel;

  /// Prints a value in the legend and to a screen reader.
  final String Function(double value)? format;

  @override
  State<MinimalPieChart> createState() => _MinimalPieChartState();
}

class _MinimalPieChartState extends State<MinimalPieChart> {
  int? _at;
  bool _focused = false;

  /// The widest the legend runs.
  static const double _legendWidth = 280;

  double get _total =>
      widget.slices.fold(0.0, (s, x) => s + math.max(0.0, x.value));

  int? _sliceAt(Offset p) {
    final r = widget.size / 2;
    final d = p - Offset(r, r);
    final distance = d.distance;
    if (distance > r || distance < r - widget.thickness - 6) return null;
    var angle = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    final total = _total;
    if (total <= 0) return null;
    var start = 0.0;
    for (var i = 0; i < widget.slices.length; i++) {
      final sweep = math.max(0.0, widget.slices[i].value) / total * 2 * math.pi;
      if (angle >= start && angle < start + sweep) return i;
      start += sweep;
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final n = widget.slices.length;
    if (n == 0) return KeyEventResult.ignored;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowDown) {
      setState(() => _at = ((_at ?? -1) + 1) % n);
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowUp) {
      setState(() => _at = ((_at ?? 0) - 1 + n) % n);
    } else if (key == LogicalKeyboardKey.escape) {
      setState(() => _at = null);
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final l = MinimalLocalizations.of(context);
    final format = widget.format ?? _figure;
    final palette = minimalChartPalette(t);
    final colours = [
      for (var i = 0; i < widget.slices.length; i++)
        widget.slices[i].color ?? palette[i % palette.length],
    ];
    final total = _total;
    final at = _at;
    String share(double v) =>
        total <= 0 ? '0%' : '${(v / total * 100).round()}%';
    final Widget donut;
    if (widget.loading) {
      donut = Semantics(
        label: l.loading,
        child: MinimalSkeleton.circle(size: widget.size),
      );
    } else if (total <= 0) {
      donut = SizedBox.square(
        dimension: widget.size,
        child: CustomPaint(
          painter: _DonutPainter(
            values: const [],
            colours: const [],
            thickness: widget.thickness,
            // The empty ring is a placeholder's grey: by night the strong
            // hairline's, as the skeleton and a progress track take.
            track: t.isLightAppearance ? t.border : t.borderStrong,
            gap: t.card,
            at: null,
          ),
          child: Center(
            child: Text(
              widget.emptyLabel ?? l.noData,
              style: t.bodySmall.c(t.mutedForeground),
            ),
          ),
        ),
      );
    } else {
      final picked = at == null ? null : widget.slices[at];
      donut = MouseRegion(
        onHover: (e) => setState(() => _at = _sliceAt(e.localPosition)),
        onExit: (_) => setState(() => _at = null),
        child: GestureDetector(
          onTapDown: (d) => setState(() => _at = _sliceAt(d.localPosition)),
          child: SizedBox.square(
            dimension: widget.size,
            child: CustomPaint(
              painter: _DonutPainter(
                values: [for (final s in widget.slices) math.max(0.0, s.value)],
                colours: colours,
                thickness: widget.thickness,
                track: t.border,
                gap: t.card,
                at: at,
              ),
              child: Center(
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        picked == null
                            ? widget.centerValue ?? format(total)
                            : share(picked.value),
                        style: t.figure.c(t.foreground),
                      ),
                      if (picked != null || widget.centerLabel != null)
                        Text(
                          picked?.label ?? widget.centerLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.caption.c(t.mutedForeground),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final legend = widget.legend && total > 0 && !widget.loading
        ? ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < widget.slices.length; i++)
                  Container(
                    constraints: const BoxConstraints(minHeight: 28),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: ShapeDecoration(
                            color: colours[i],
                            shape: const CircleBorder(),
                          ),
                        ),
                        const MinimalGap(MinimalSpacing.s8),
                        // Words and figures by their capitals, so the dot
                        // stands on their middle at any text size.
                        Expanded(
                          child: minimalCapLabel(
                            Text(
                              widget.slices[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  (i == at ? t.bodySmall.medium : t.bodySmall)
                                      .c(t.foreground),
                            ),
                          ),
                        ),
                        const MinimalGap(MinimalSpacing.s16),
                        minimalCapLabel(
                          Text(
                            format(widget.slices[i].value),
                            style: t.countFigure.c(t.foreground),
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: minimalCapLabel(
                            Text(
                              share(widget.slices[i].value),
                              textAlign: TextAlign.end,
                              style: t.countFigure.c(t.mutedForeground),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        : null;
    final ring =
        _focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    final summary = [
      for (final s in widget.slices) '${s.label} ${format(s.value)}',
    ].join(', ');
    return Semantics(
      container: true,
      label: widget.semanticLabel,
      value: at == null
          ? summary
          : '${widget.slices[at].label} ${share(widget.slices[at].value)}',
      child: Focus(
        canRequestFocus: total > 0 && !widget.loading,
        onKeyEvent: _onKey,
        onFocusChange: (v) => setState(() {
          _focused = v;
          if (!v) _at = null;
        }),
        child: LayoutBuilder(
          builder: (context, box) {
            final ringed = DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: minimalFrame(
                const CircleBorder(),
                side: ring
                    ? BorderSide(
                        color: t.ring,
                        width: t.focusWidth,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      )
                    : BorderSide.none,
              ),
              child: donut,
            );
            if (legend == null) return Center(child: ringed);
            final wide = box.maxWidth >= widget.size + 200;
            // A legend no wider than it reads: as wide as its longest label
            // and its figures (at most [_legendWidth]), so each figure
            // stands just past the labels instead of out at the far edge.
            final held = ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _legendWidth),
              child: IntrinsicWidth(child: legend),
            );
            return wide
                ? Row(
                    children: [
                      ringed,
                      const MinimalGap(MinimalSpacing.s24),
                      Flexible(child: held),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(child: ringed),
                      const MinimalGap(MinimalSpacing.s16),
                      Center(child: held),
                    ],
                  );
          },
        ),
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.colours,
    required this.thickness,
    required this.track,
    required this.gap,
    required this.at,
  });

  final List<double> values;
  final List<Color> colours;
  final double thickness;
  final Color track;
  final Color gap;
  final int? at;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(thickness / 2);
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;
    final total = values.fold(0.0, (s, v) => s + v);
    if (total <= 0) {
      canvas.drawArc(rect, 0, 2 * math.pi, false, ring..color = track);
      return;
    }
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * 2 * math.pi;
      if (sweep <= 0) continue;
      final faded = at != null && at != i;
      canvas.drawArc(
        rect,
        start,
        sweep,
        false,
        ring..color = colours[i].withValues(alpha: faded ? 0.3 : 1),
      );
      start += sweep;
    }
    // A 2 px gap of the surface at each boundary.
    if (values.where((v) => v > 0).length > 1) {
      final r = size.width / 2;
      final c = size.center(Offset.zero);
      final cut = Paint()
        ..color = gap
        ..strokeWidth = 2;
      var a = -math.pi / 2;
      for (final v in values) {
        if (v <= 0) continue;
        final dir = Offset(math.cos(a), math.sin(a));
        canvas.drawLine(c + dir * (r - thickness - 1), c + dir * (r + 1), cut);
        a += v / total * 2 * math.pi;
      }
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.values != values ||
      old.at != at ||
      old.thickness != thickness ||
      old.track != track ||
      old.gap != gap ||
      old.colours.length != colours.length;
}
