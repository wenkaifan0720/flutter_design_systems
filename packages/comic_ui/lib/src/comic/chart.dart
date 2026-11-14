/// Data plotted as inked lines, areas and square bars, with no animated distortion, and an inline sparkline.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'layout.dart';
import 'localizations.dart';
import 'press.dart';
import 'theme.dart';

/// One named series; a missing value breaks the line.
@immutable
class ComicChartSeries {
  /// Creates a series in point order.
  const ComicChartSeries(this.label, this.values);

  /// Its legend and accessible name.
  final String label;

  /// Values in point order; null is a gap.
  final List<double?> values;

  @override
  bool operator ==(Object other) =>
      other is ComicChartSeries &&
      other.label == label &&
      listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(values));
}

/// An optional target range behind a chart.
@immutable
class ComicChartBand {
  /// Creates a band from low to high.
  const ComicChartBand(this.low, this.high, {this.label}) : assert(low <= high);

  /// Its inclusive limits.
  final double low, high;

  /// Legend text.
  final String? label;

  @override
  bool operator ==(Object other) =>
      other is ComicChartBand &&
      other.low == low &&
      other.high == high &&
      other.label == label;

  @override
  int get hashCode => Object.hash(low, high, label);
}

/// What a [ComicChart] draws its series as.
enum ComicChartType {
  /// Inked lines with square point marks.
  line,

  /// Lines with the ground under each filled in its ink.
  area,

  /// Grouped bars.
  bar,
}

/// A chart of one or more series, drawn as its [type]: inked lines with square point marks, an area filled under
/// them, or grouped bars, over a zero baseline with gaps, an optional target band, a value axis, the x labels and a legend. Hover, a
/// touch or the arrow keys show a point's values in a plate. With no values it says so; [loading] holds its place.
///
/// ```dart
/// ComicChart(label: 'Weekly pages', series: [ComicChartSeries('Pages', [12, 18, 16])])
/// ```
class ComicChart extends StatefulWidget {
  /// Creates an inked plot; labels and legend stand outside the plot height.
  const ComicChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.type = ComicChartType.line,
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
    this.empty,
  });

  /// The chart's accessible name.
  final String label;

  /// Series in legend order.
  final List<ComicChartSeries> series;

  /// X-axis labels.
  final List<String> labels;

  /// What the series are drawn as: lines, an area or grouped bars.
  final ComicChartType type;

  bool get _bars => type == ComicChartType.bar;

  /// Optional target range.
  final ComicChartBand? band;

  /// Overrides the accessible value summary.
  final String? summary;

  /// Plot height, excluding axis labels and legend.
  final double height;

  /// Formats values in the accessible summary, the value axis and the plate.
  final String Function(double)? format;

  /// The values are on their way: the plot holds its place, quietly.
  final bool loading;

  /// What a chart with no values says; null: the localized "Nothing to show yet".
  final String? empty;

  @override
  State<ComicChart> createState() => _ComicChartState();
}

/// The chart row's three names (the shared stems): a [ComicChart] of inked lines, of an area under them, or of grouped
/// bars. Each takes [ComicChart]'s own arguments, the form aside.
///
/// ```dart
/// ComicLineChart(label: 'Pages read', labels: const ['Mon', 'Tue', 'Wed'], series: [ComicChartSeries('You', [12, 18, 16])])
/// ```
class ComicLineChart extends StatelessWidget {
  /// Creates a [ComicLineChart].
  const ComicLineChart({
    super.key,
    required this.label,
    required this.series,
    this.labels = const [],
    this.band,
    this.summary,
    this.height = 180,
    this.format,
    this.loading = false,
    this.empty,
  });

  /// See [ComicChart.label].
  final String label;

  /// See [ComicChart.series].
  final List<ComicChartSeries> series;

  /// See [ComicChart.labels].
  final List<String> labels;

  /// See [ComicChart.band].
  final ComicChartBand? band;

  /// See [ComicChart.summary].
  final String? summary;

  /// See [ComicChart.height].
  final double height;

  /// See [ComicChart.format].
  final String Function(double)? format;

  /// See [ComicChart.loading].
  final bool loading;

  /// See [ComicChart.empty].
  final String? empty;

  @override
  Widget build(BuildContext context) => ComicChart(
    label: label,
    series: series,
    labels: labels,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
    empty: empty,
  );
}

/// A [ComicChart] with the area under each line filled: a running total, a level over time.
///
/// ```dart
/// ComicAreaChart(label: 'Visitors', labels: const ['Wk 1', 'Wk 2'], series: [ComicChartSeries('Visitors', [310, 402])])
/// ```
class ComicAreaChart extends ComicLineChart {
  /// Creates a [ComicAreaChart].
  const ComicAreaChart({
    super.key,
    required super.label,
    required super.series,
    super.labels,
    super.band,
    super.summary,
    super.height,
    super.format,
    super.loading,
    super.empty,
  });

  @override
  Widget build(BuildContext context) => ComicChart(
    label: label,
    series: series,
    labels: labels,
    type: ComicChartType.area,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
    empty: empty,
  );
}

/// A [ComicChart] of grouped bars: amounts side by side, one group a label.
///
/// ```dart
/// ComicBarChart(label: 'Orders', labels: const ['Wk 1', 'Wk 2'], series: [ComicChartSeries('Online', [42, 51])])
/// ```
class ComicBarChart extends ComicLineChart {
  /// Creates a [ComicBarChart].
  const ComicBarChart({
    super.key,
    required super.label,
    required super.series,
    super.labels,
    super.band,
    super.summary,
    super.height,
    super.format,
    super.loading,
    super.empty,
  });

  @override
  Widget build(BuildContext context) => ComicChart(
    label: label,
    series: series,
    labels: labels,
    type: ComicChartType.bar,
    band: band,
    summary: summary,
    height: height,
    format: format,
    loading: loading,
    empty: empty,
  );
}

class _ComicChartState extends State<ComicChart> {
  int? _at;
  bool _focused = false;
  final _focus = FocusNode(debugLabel: 'ComicChart');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  int get _count =>
      widget.series.fold<int>(0, (n, s) => math.max(n, s.values.length));

  int _nearest(double dx, double width, double start, double end) {
    if (_count <= 1) return 0;
    final count = math.max(_count, widget.labels.length);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The plot as the ink lays it: the axis gutter on the start side, the
    // last label's room on the end side, 4 of air inside each.
    final left = (rtl ? end : start) + 4;
    final plot = math.max(1.0, width - start - end - 8);
    var at = ((dx - left) / plot).clamp(0.0, 1.0);
    if (rtl) at = 1 - at;
    return widget._bars
        ? (at * count).floor().clamp(0, _count - 1)
        : (at * (count - 1)).round().clamp(0, _count - 1);
  }

  KeyEventResult _keys(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final count = _count;
    if (count == 0) return KeyEventResult.ignored;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    final step = key == LogicalKeyboardKey.arrowRight
        ? (rtl ? -1 : 1)
        : key == LogicalKeyboardKey.arrowLeft
        ? (rtl ? 1 : -1)
        : null;
    if (key == LogicalKeyboardKey.escape && _at != null) {
      setState(() => _at = null);
      return KeyEventResult.handled;
    }
    if (step == null) return KeyEventResult.ignored;
    setState(
      () => _at = ((_at ?? (step > 0 ? -1 : count)) + step).clamp(0, count - 1),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final c = t.colors;
    final words = ComicLocalizations.of(context);
    final values = [
      for (final s in widget.series)
        for (final v in s.values)
          if (v != null && v.isFinite) v,
    ];
    final bounds = [
      ...values,
      if (widget.band != null) widget.band!.low,
      if (widget.band != null) widget.band!.high,
    ];
    final least = bounds.fold<double>(0, math.min);
    final most = bounds.fold<double>(0, math.max);
    // Round guides (0, 10, 20, 30; 0, 250, 500, 750), top down: the plot runs
    // from the lowest guide to the highest, each label the guide's exact value.
    final guides = _roundGuides(
      least,
      least == most ? least + 1 : most,
      whole: widget.format == null,
    );
    final low = guides.last, upper = guides.first;
    final fmt = widget.format ?? (double n) => n.toStringAsFixed(0);
    final nothing = values.isEmpty && !widget.loading;
    final read =
        widget.summary ??
        (widget.loading
            ? DesignLocalizations.of(context).loadingLabel
            : nothing
            ? widget.empty ?? words.noData
            : [
                for (final s in widget.series)
                  '${s.label}: ${[for (final v in s.values)
                    if (v != null) fmt(v)].join(', ')}',
              ].join('; '));
    final axis = t.type.small;
    final ticks = guides;
    double measure(String text) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: axis),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
      )..layout();
      final w = painter.width;
      painter.dispose();
      return w;
    }

    final labelled = widget.labels.isNotEmpty && !widget.loading && !nothing;
    final xStyle = DefaultTextStyle.of(context).style.merge(axis);
    // A line's first and last labels stand centred on the plot's first and
    // last points, so each needs half its width beside the plot: the axis
    // gutter gives it at the start and the end keeps what the last one
    // needs. Bars stand half a group in, which is room enough.
    double half(int i) =>
        _XLabels.widthOf(widget.labels[i], xStyle, context) / 2 - 4;
    final lastPoint = math.max(_count, widget.labels.length) - 1;
    final start = widget.loading || nothing
        ? 0.0
        : math.max(
            ticks.map((v) => measure(fmt(v))).fold<double>(0, math.max) + 8,
            labelled && !widget._bars ? half(0) : 0.0,
          );
    final end = labelled && !widget._bars && lastPoint < widget.labels.length
        ? math.max(0.0, half(lastPoint))
        : 0.0;
    final shown = _at == null || _at! >= _count ? null : _at;
    final plate = shown == null
        ? null
        : [
            if (shown < widget.labels.length) widget.labels[shown],
            for (final s in widget.series)
              if (shown < s.values.length && s.values[shown] != null)
                '${s.label}: ${fmt(s.values[shown]!)}',
          ];
    final plot = LayoutBuilder(
      builder: (context, box) => MouseRegion(
        onHover: widget.loading || nothing
            ? null
            : (e) => setState(
                () => _at = _nearest(
                  e.localPosition.dx,
                  box.maxWidth,
                  start,
                  end,
                ),
              ),
        onExit: (_) => setState(() => _at = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: widget.loading || nothing
              ? null
              : (d) => setState(
                  () => _at = _nearest(
                    d.localPosition.dx,
                    box.maxWidth,
                    start,
                    end,
                  ),
                ),
          onHorizontalDragUpdate: widget.loading || nothing
              ? null
              : (d) => setState(
                  () => _at = _nearest(
                    d.localPosition.dx,
                    box.maxWidth,
                    start,
                    end,
                  ),
                ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox(
                height: widget.height,
                width: box.maxWidth,
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ChartInk(
                      widget.series,
                      widget._bars,
                      widget.band,
                      low,
                      upper,
                      t.colors,
                      Directionality.of(context),
                      area: widget.type == ComicChartType.area,
                      start: start,
                      end: end,
                      slots: widget.labels.length,
                      // A chart with nothing to plot keeps its guides but
                      // labels none: there is no scale to read.
                      ticks: widget.loading || nothing
                          ? const []
                          : [for (final v in ticks) fmt(v)],
                      axis: axis,
                      at: shown,
                      loading: widget.loading,
                      textScaler: MediaQuery.textScalerOf(context),
                    ),
                  ),
                ),
              ),
              if (nothing)
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        widget.empty ?? words.noData,
                        textAlign: TextAlign.center,
                        style: t.type.body.copyWith(color: c.textSecondary),
                      ),
                    ),
                  ),
                ),
              if (plate != null && plate.isNotEmpty)
                PositionedDirectional(
                  top: 4,
                  start: start + 8,
                  end: 8,
                  child: Align(
                    alignment: AlignmentDirectional.topStart,
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        color: c.card,
                        shape: t.shapes.medium.copyWith(
                          side: BorderSide(color: c.nightLine, width: t.rim(2)),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (final (i, line) in plate.indexed)
                              Text(
                                line,
                                style: i == 0 && shown! < widget.labels.length
                                    ? t.type.small.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: c.text,
                                      )
                                    : t.type.small.copyWith(color: c.text),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    Widget entry(Color swatch, String words) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: ShapeDecoration(
            color: swatch,
            shape: t.shapes.small.copyWith(side: BorderSide(color: c.text)),
          ),
        ),
        const SizedBox(width: 6),
        Text(words, style: axis),
      ],
    );
    return Semantics(
      container: true,
      label: widget.label,
      value: read,
      excludeSemantics: true,
      child: Focus(
        focusNode: _focus,
        onKeyEvent: _keys,
        canRequestFocus: !widget.loading && !nothing,
        onFocusChange: (on) => setState(() => _focused = on),
        // A chart is a stop in the tab order (the arrows read its points), so it wears the ring every stop wears,
        // round the whole chart at the control step.
        child: ComicHighlight(
          states: _focused
              ? const {WidgetState.focused}
              : const <WidgetState>{},
          shape: t.shapes.small,
          wash: false,
          // In a box of fixed height the plot gives up what its labels and key need; unbounded, it keeps its own height.
          child: LayoutBuilder(
            builder: (context, room) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (room.maxHeight.isFinite) Flexible(child: plot) else plot,
                if (labelled)
                  Padding(
                    padding: EdgeInsetsDirectional.only(start: start, end: end),
                    child: _XLabels(
                      labels: widget.labels,
                      bars: widget._bars,
                      count: math.max(_count, widget.labels.length),
                      style: xStyle,
                    ),
                  ),
                if (!widget.loading && !nothing) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      for (final (i, s) in widget.series.indexed)
                        entry(c.series[i % c.series.length], s.label),
                      // The band keys its own fill, as a series keys its ink.
                      if (widget.band?.label != null)
                        entry(c.currentUserTint, widget.band!.label!),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Round guides from [low] to [high], top down, as kit_chart's `_niceTicks` chooses them: a step of 1, 2, 2.5 or 5 times
/// a power of ten, the first at least a third of the span, from the step at or under [low] to the first at or over
/// [high] (0 to 27 reads 0, 10, 20, 30; 0 to 612 reads 0, 250, 500, 750). Whole-number labels take whole steps only, so
/// no two guides read the same.
List<double> _roundGuides(double low, double high, {required bool whole}) {
  final raw = (high - low) / 3;
  final magnitude = math
      .pow(10, (math.log(raw) / math.ln10).floor())
      .toDouble();
  var step = [1.0, 2.0, 2.5, 5.0, 10.0]
      .map((m) => m * magnitude)
      .where((s) => !whole || s == s.roundToDouble())
      .firstWhere((s) => s >= raw, orElse: () => 10 * magnitude);
  if (whole) step = math.max(1.0, step);
  final first = (low / step).floor() * step;
  final guides = <double>[];
  for (var v = first; v < high + step * .999; v += step) {
    guides.add(double.parse(v.toStringAsFixed(6)));
    if (guides.length > 6) break;
  }
  if (guides.length < 2) guides.add(first + step);
  return guides.reversed.toList();
}

/// The WCAG contrast ratio of two colours, 1 to 21.
double _contrast(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  return (math.max(la, lb) + .05) / (math.min(la, lb) + .05);
}

/// Where point or group [i] of [count] stands across the plot: 0 at its start, 1 at its end. Lines run end to end; bars
/// stand in the middle of equal slots.
double _across(int i, int count, bool bars) => bars
    ? (i + .5) / math.max(1, count)
    : count < 2
    ? .5
    : i / (count - 1);

/// The x labels under the plot, each at its own width and centred on its point (a line) or its group (bars), never
/// moved off it. When they don't all fit with air between them they thin evenly: every k-th, the same k throughout,
/// the first and the last always kept (k divides the run, so the last falls on the beat).
class _XLabels extends StatelessWidget {
  const _XLabels({
    required this.labels,
    required this.bars,
    required this.count,
    required this.style,
  });
  final List<String> labels;
  final bool bars;
  final int count;
  final TextStyle style;

  /// The air between two labels.
  static const double air = 8;

  /// A label's width as it lays out in [style].
  static double widthOf(String text, TextStyle style, BuildContext context) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final w = painter.width;
    painter.dispose();
    return w;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final rtl = Directionality.of(context) == TextDirection.rtl;
      final plot = math.max(0.0, box.maxWidth - 8);
      final n = math.min(labels.length, count);
      final centres = [
        for (var i = 0; i < n; i++)
          4 +
              (rtl ? 1 - _across(i, count, bars) : _across(i, count, bars)) *
                  plot,
      ];
      final widths = [
        for (var i = 0; i < n; i++) widthOf(labels[i], style, context),
      ];
      bool fits(List<int> picked) {
        for (var j = 1; j < picked.length; j++) {
          final a = picked[j - 1], b = picked[j];
          if ((centres[b] - centres[a]).abs() <
              (widths[a] + widths[b]) / 2 + air) {
            return false;
          }
        }
        return true;
      }

      var picked = n == 0 ? const <int>[] : const [0];
      for (var k = 1; k < n; k++) {
        if ((n - 1) % k != 0) continue;
        final every = [for (var i = 0; i < n; i += k) i];
        if (fits(every)) {
          picked = every;
          break;
        }
      }
      final line = (style.fontSize ?? 12) * (style.height ?? 1.3);
      return SizedBox(
        height: MediaQuery.textScalerOf(context).scale(line) + 4,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final i in picked)
              Positioned(
                left: centres[i] - widths[i] / 2,
                top: 0,
                child: Text(
                  labels[i],
                  maxLines: 1,
                  softWrap: false,
                  style: style,
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _ChartInk extends CustomPainter {
  _ChartInk(
    this.series,
    this.bars,
    this.band,
    this.low,
    this.high,
    this.colors,
    this.direction, {
    this.area = false,
    this.start = 0,
    this.end = 0,
    this.slots = 0,
    this.ticks = const [],
    this.axis,
    this.at,
    this.loading = false,
    this.textScaler = TextScaler.noScaling,
  });
  final List<ComicChartSeries> series;
  final bool bars, area, loading;
  final ComicChartBand? band;
  final double low, high, start, end;
  final ComicColors colors;
  final TextDirection direction;
  final List<String> ticks;
  final TextStyle? axis;
  final int? at;
  final int slots;
  final TextScaler textScaler;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final rtl = direction == TextDirection.rtl;
    final whole = Offset.zero & size;
    final plot = Rect.fromLTRB(
      (rtl ? end : start) + 4,
      4,
      size.width - (rtl ? start : end) - 4,
      size.height - 4,
    );
    if (plot.isEmpty) return;
    final guide = Paint()
      ..color = colors.divider
      ..strokeWidth = 1;
    if (loading) {
      // Bare guides run the chart's whole width, so a chart holding its place starts on its column's edge.
      for (var i = 0; i <= 4; i++) {
        final yy = plot.top + plot.height * i / 4;
        canvas.drawLine(Offset(0, yy), Offset(size.width, yy), guide);
      }
      final track = Paint()..color = colors.track;
      for (var i = 0; i < 7; i++) {
        final w = plot.width / 7;
        final h = plot.height * (.3 + .1 * ((i * 3) % 5));
        canvas.drawRect(
          Rect.fromLTWH(plot.left + i * w + w * .2, plot.bottom - h, w * .6, h),
          track,
        );
      }
      return;
    }
    double y(double v) => plot.bottom - (v - low) / (high - low) * plot.height;
    // Points stand on as many slots as there are values or labels, the same
    // slots the x labels stand on.
    final count = series.fold<int>(
      slots,
      (n, s) => math.max(n, s.values.length),
    );
    double x(int i) {
      final at = _across(i, count, bars);
      return plot.left + (rtl ? 1 - at : at) * plot.width;
    }

    // The value axis: a guide on each round step, each labelled at the plot's
    // start; a loading chart keeps five bare guides, an empty one four, so its
    // words stand in the middle gap rather than on a guide.
    final rules = ticks.length >= 2
        ? ticks.length
        : loading
        ? 5
        : 4;
    for (var i = 0; i < rules; i++) {
      final yy = plot.top + plot.height * i / (rules - 1);
      // Bare guides (an empty chart's) run the whole width, as a loading chart's do.
      canvas.drawLine(
        Offset(ticks.length < 2 ? 0 : plot.left, yy),
        Offset(ticks.length < 2 ? size.width : plot.right, yy),
        guide,
      );
      if (axis != null && i < ticks.length) {
        final label = TextPainter(
          text: TextSpan(text: ticks[i], style: axis),
          textDirection: direction,
          textScaler: textScaler,
        )..layout();
        label.paint(
          canvas,
          Offset(
            rtl ? plot.right + 6 : plot.left - 6 - label.width,
            (yy - label.height / 2).clamp(0, size.height - label.height),
          ),
        );
        label.dispose();
      }
    }
    canvas.save();
    canvas.clipRect(whole);
    if (band != null) {
      canvas.drawRect(
        Rect.fromLTRB(plot.left, y(band!.high), plot.right, y(band!.low)),
        Paint()..color = colors.currentUserTint,
      );
    }
    if (at != null && count > 0) {
      canvas.drawLine(
        Offset(x(at!), plot.top),
        Offset(x(at!), plot.bottom),
        Paint()
          ..color = colors.textSecondary
          ..strokeWidth = 1.5,
      );
    }
    canvas.drawLine(
      Offset(plot.left, y(0)),
      Offset(plot.right, y(0)),
      Paint()
        ..color = colors.text
        ..strokeWidth = 2,
    );
    for (final (si, s) in series.indexed) {
      final color = colors.series[si % colors.series.length];
      // A series too light to hold 3:1 against the page or a panel (the
      // yellow on cream) is inked: its line drawn over an ink outline, its
      // points rimmed, so it keeps its hue and the legend's swatch.
      final faint =
          math.min(
            _contrast(color, colors.background),
            _contrast(color, colors.card),
          ) <
          3;
      final paint = Paint()
        ..color = color
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      if (faint) {
        paint
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;
      }
      final path = Path();
      final runs = <List<Offset>>[];
      var connected = false;
      for (final (i, value) in s.values.indexed) {
        if (value == null || !value.isFinite) {
          connected = false;
          continue;
        }
        final point = Offset(x(i), y(value));
        if (bars) {
          final width = math.min(
            26.0,
            plot.width / math.max(1, count) * .8 / math.max(1, series.length),
          );
          final dx = (si - (series.length - 1) / 2) * width * (rtl ? -1 : 1);
          final rect = Rect.fromLTRB(
            point.dx + dx - width / 2,
            math.min(point.dy, y(0)),
            point.dx + dx + width / 2,
            math.max(point.dy, y(0)),
          );
          canvas.drawRect(rect, Paint()..color = color);
          canvas.drawRect(
            rect,
            Paint()
              ..color = i == at ? colors.outline : colors.text
              ..strokeWidth = i == at ? 2.5 : 1
              ..style = PaintingStyle.stroke,
          );
        } else {
          if (connected) {
            path.lineTo(point.dx, point.dy);
            runs.last.add(point);
          } else {
            path.moveTo(point.dx, point.dy);
            runs.add([point]);
          }
          connected = true;
        }
      }
      if (!bars) {
        if (area) {
          for (final run in runs) {
            if (run.length < 2) continue;
            final under = Path()..moveTo(run.first.dx, y(0));
            for (final p in run) {
              under.lineTo(p.dx, p.dy);
            }
            under
              ..lineTo(run.last.dx, y(0))
              ..close();
            canvas.drawPath(
              under,
              Paint()..color = color.withValues(alpha: .28),
            );
          }
        }
        if (faint) {
          canvas.drawPath(
            path,
            Paint()
              ..color = colors.text
              ..strokeWidth = 5
              ..style = PaintingStyle.stroke
              ..strokeJoin = StrokeJoin.round
              ..strokeCap = StrokeCap.round,
          );
        }
        canvas.drawPath(path, paint);
        for (final (i, value) in s.values.indexed) {
          if (value == null || !value.isFinite) continue;
          final point = Offset(x(i), y(value));
          final big = i == at;
          final mark = Rect.fromCenter(
            center: point,
            width: big ? 10 : 6,
            height: big ? 10 : 6,
          );
          if (faint && !big) {
            canvas.drawRect(mark.inflate(1.25), Paint()..color = colors.text);
          }
          canvas.drawRect(mark, Paint()..color = color);
          if (big) {
            canvas.drawRect(
              mark,
              Paint()
                ..color = colors.outline
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
            );
          }
        }
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartInk old) =>
      !listEquals(old.series, series) ||
      old.bars != bars ||
      old.area != area ||
      old.band != band ||
      old.low != low ||
      old.high != high ||
      old.colors != colors ||
      old.direction != direction ||
      old.start != start ||
      old.end != end ||
      old.slots != slots ||
      !listEquals(old.ticks, ticks) ||
      old.axis != axis ||
      old.at != at ||
      old.loading != loading ||
      old.textScaler != textScaler;
}

/// A trend in a line's height, inline beside a figure: no axes, an inked line over its first series colour, the last
/// value marked. [values] may hold gaps; a run of continuous values reads best (120 x 32 is a legible size).
///
/// ```dart
/// ComicSparkline(label: 'Sales this week', values: const [3, 5, 4, 8, 7])
/// ```
class ComicSparkline extends StatelessWidget {
  /// Creates a sparkline.
  const ComicSparkline({
    super.key,
    required this.label,
    required this.values,
    this.width = 96,
    this.height = 28,
    this.area = true,
    this.format,
  });

  /// Its accessible name.
  final String label;

  /// The values in order; null is a gap.
  final List<double?> values;

  /// Its size.
  final double width, height;

  /// Fills under the line, faintly.
  final bool area;

  /// Formats the values a screen reader hears.
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final fmt = format ?? (double n) => n.toStringAsFixed(0);
    final finite = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    final read = finite.isEmpty
        ? ComicLocalizations.of(context).noData
        : '${fmt(finite.first)} to ${fmt(finite.last)}, '
              'low ${fmt(finite.reduce(math.min))}, high ${fmt(finite.reduce(math.max))}';
    return Semantics(
      container: true,
      label: label,
      value: read,
      excludeSemantics: true,
      child: comicOwnSize(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkInk(
            values,
            t.colors,
            Directionality.of(context),
            area,
          ),
        ),
      ),
    );
  }
}

class _SparkInk extends CustomPainter {
  _SparkInk(this.values, this.colors, this.direction, this.area);
  final List<double?> values;
  final ComicColors colors;
  final TextDirection direction;
  final bool area;

  @override
  void paint(Canvas canvas, Size size) {
    final finite = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    // The end mark (7 square and its 1.5 rim) stays inside the sparkline.
    final box = (Offset.zero & size).deflate(4.5);
    if (finite.isEmpty || box.isEmpty) {
      canvas.drawLine(
        Offset(box.left, box.center.dy),
        Offset(box.right, box.center.dy),
        Paint()
          ..color = colors.divider
          ..strokeWidth = 1.5,
      );
      return;
    }
    final low = finite.reduce(math.min), high = finite.reduce(math.max);
    final span = high == low ? 1.0 : high - low;
    final rtl = direction == TextDirection.rtl;
    Offset point(int i, double v) {
      final at = values.length < 2 ? .5 : i / (values.length - 1);
      return Offset(
        box.left + (rtl ? 1 - at : at) * box.width,
        box.bottom - (v - low) / span * box.height,
      );
    }

    final color = colors.series.first;
    final line = Path();
    final runs = <List<Offset>>[];
    var connected = false;
    Offset? last;
    for (final (i, v) in values.indexed) {
      if (v == null || !v.isFinite) {
        connected = false;
        continue;
      }
      final p = point(i, v);
      if (connected) {
        line.lineTo(p.dx, p.dy);
        runs.last.add(p);
      } else {
        line.moveTo(p.dx, p.dy);
        runs.add([p]);
      }
      connected = true;
      last = p;
    }
    if (area) {
      for (final run in runs) {
        if (run.length < 2) continue;
        final under = Path()..moveTo(run.first.dx, box.bottom);
        for (final p in run) {
          under.lineTo(p.dx, p.dy);
        }
        under
          ..lineTo(run.last.dx, box.bottom)
          ..close();
        canvas.drawPath(under, Paint()..color = color.withValues(alpha: .5));
      }
    }
    // The line is inked, as every line on the page: a series colour alone
    // can sit too close to the paper to read at this size.
    canvas.drawPath(
      line,
      Paint()
        ..color = colors.text
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    if (last != null) {
      final mark = Rect.fromCenter(center: last, width: 7, height: 7);
      canvas.drawRect(mark, Paint()..color = color);
      canvas.drawRect(
        mark,
        Paint()
          ..color = colors.outline
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkInk old) =>
      !listEquals(old.values, values) ||
      old.colors != colors ||
      old.direction != direction ||
      old.area != area;
}
