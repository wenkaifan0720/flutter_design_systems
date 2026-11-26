/// Data plotted as inked lines, areas and square bars, with no animated distortion, and an inline sparkline.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'layout.dart';
import 'localizations.dart';
import 'press.dart';
import 'print.dart' show ComicScreenGrid;
import 'theme.dart';
import 'knobs.dart' show ComicSpace;

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
    this.valueFormat,
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

  /// How values read in the accessible summary, on the value axis and on the plate, in the reader's digits, with
  /// their unit (`RawChartValueFormat(suffix: ' h')`); null: whole numbers.
  final RawChartValueFormat? valueFormat;

  /// The values are on their way: the plot holds its place, quietly.
  final bool loading;

  /// What a chart with no values says; null: the localized "Nothing to show yet".
  final String? empty;

  @override
  State<ComicChart> createState() => _ComicChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<ComicChartSeries>('series', series))
      ..add(IterableProperty<String>('labels', labels, defaultValue: const []))
      ..add(
        EnumProperty<ComicChartType>(
          'type',
          type,
          defaultValue: ComicChartType.line,
        ),
      )
      ..add(
        DiagnosticsProperty<ComicChartBand>('band', band, defaultValue: null),
      )
      ..add(StringProperty('summary', summary, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: 180))
      ..add(
        DiagnosticsProperty<RawChartValueFormat>(
          'valueFormat',
          valueFormat,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'loading',
          value: loading,
          ifTrue: 'loading',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('empty', empty, defaultValue: null));
  }
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
    this.valueFormat,
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

  /// See [ComicChart.valueFormat].
  final RawChartValueFormat? valueFormat;

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
    valueFormat: valueFormat,
    loading: loading,
    empty: empty,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<ComicChartSeries>('series', series))
      ..add(IterableProperty<String>('labels', labels, defaultValue: const []))
      ..add(
        DiagnosticsProperty<ComicChartBand>('band', band, defaultValue: null),
      )
      ..add(StringProperty('summary', summary, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: 180))
      ..add(
        DiagnosticsProperty<RawChartValueFormat>(
          'valueFormat',
          valueFormat,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'loading',
          value: loading,
          ifTrue: 'loading',
          defaultValue: false,
        ),
      )
      ..add(StringProperty('empty', empty, defaultValue: null));
  }
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
    super.valueFormat,
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
    valueFormat: valueFormat,
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
    super.valueFormat,
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
    valueFormat: valueFormat,
    loading: loading,
    empty: empty,
  );
}

class _ComicChartState extends State<ComicChart> {
  bool _focused = false;
  // ui_core's chart takes the keys on this node; the whole chart (its labels and key too) pops while it has them.
  late final FocusNode _focus = FocusNode(debugLabel: 'ComicChart')
    ..addListener(() {
      if (_focused != _focus.hasFocus) {
        setState(() => _focused = _focus.hasFocus);
      }
    });

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  int get _count =>
      widget.series.fold<int>(0, (n, s) => math.max(n, s.values.length));

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
      whole: widget.valueFormat == null,
    );
    final low = guides.last, upper = guides.first;
    // The reader's own figures: Arabic-Indic digits on an Arabic page, the locale's grouping.
    final digits = RawWidgetsLocalizations.of(context);
    final valueFormat =
        widget.valueFormat ?? const RawChartValueFormat(fractionDigits: 0);
    String fmt(double n) => valueFormat.format(n, digits);
    final nothing = values.isEmpty && !widget.loading;
    final read =
        widget.summary ??
        (widget.loading
            ? RawWidgetsLocalizations.of(context).loadingLabel
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
    final slots = math.max(_count, widget.labels.length);
    String slotName(int i) =>
        i >= 0 && i < widget.labels.length ? widget.labels[i] : '${i + 1}';
    _focus.canRequestFocus = !widget.loading && !nothing;
    // ui_core's chart picks the point under a pointer or a finger, steps it with the keys and lets Escape drop it, and
    // tells a screen reader the chart and each point. Its plot is Comic's: the axis gutter and the last label's room
    // beside it, 4 of air inside each, so its points stand where the ink draws them.
    final plot = SizedBox(
      height: widget.height,
      child: RawChart(
        focusNode: _focus,
        semanticLabel: widget.label,
        semanticSummary: read,
        xAxis: widget._bars ? RawChartXAxis.band : RawChartXAxis.linear,
        categories: widget._bars
            ? [for (var i = 0; i < slots; i++) slotName(i)]
            : null,
        padding: EdgeInsetsDirectional.only(start: start + 4, end: end + 4),
        formatX: (x) => slotName(x.round()),
        valueFormat: valueFormat,
        series: widget.loading || nothing
            ? const []
            : [
                for (final s in widget.series)
                  RawChartSeries(
                    label: s.label,
                    points: [
                      for (var i = 0; i < slots; i++)
                        RawChartPoint(
                          i.toDouble(),
                          i < s.values.length &&
                                  s.values[i] != null &&
                                  s.values[i]!.isFinite
                              ? s.values[i]
                              : null,
                        ),
                    ],
                  ),
              ],
        builder: (context, chart) {
          final at = chart.active?.index;
          final shown = at == null || at >= _count ? null : at;
          final plate = shown == null
              ? null
              : [
                  if (shown < widget.labels.length) widget.labels[shown],
                  for (final s in widget.series)
                    if (shown < s.values.length && s.values[shown] != null)
                      '${s.label}: ${fmt(s.values[shown]!)}',
                ];
          return Stack(
            clipBehavior: Clip.none,
            children: [
              SizedBox.expand(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _ChartInk(
                      dpr: MediaQuery.devicePixelRatioOf(context),
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
                      padding: const EdgeInsets.all(ComicSpace.gap),
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
          );
        },
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
        const SizedBox(width: ComicSpace.close),
        Text(words, style: axis),
      ],
    );
    // A chart is a stop in the tab order (the arrows read its points), so it pops as every stop does, the whole chart
    // at the control step. Its words are its one node's, ui_core's chart's (its label, its summary, a step
    // per point): the labels and the key under the plot are not read again.
    return ComicHighlight(
      states: _focused ? const {WidgetState.focused} : const <WidgetState>{},
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
              ExcludeSemantics(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(start: start, end: end),
                  child: _XLabels(
                    labels: widget.labels,
                    bars: widget._bars,
                    count: math.max(_count, widget.labels.length),
                    style: xStyle,
                  ),
                ),
              ),
            if (!widget.loading && !nothing) ...[
              const SizedBox(height: ComicSpace.close),
              ExcludeSemantics(
                child: Wrap(
                  spacing: ComicSpace.near,
                  runSpacing: ComicSpace.close,
                  children: [
                    for (final (i, s) in widget.series.indexed)
                      entry(c.series[i % c.series.length], s.label),
                    // The band keys its own fill, as a series keys its ink.
                    if (widget.band?.label != null)
                      entry(c.currentUserTint, widget.band!.label!),
                  ],
                ),
              ),
            ],
          ],
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
    this.dpr = 1,
  });

  /// The device's pixels per logical pixel: an area's dots land on whole ones.
  final double dpr;
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
            RawPalette.contrastRatio(color, colors.background),
            RawPalette.contrastRatio(color, colors.card),
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
            _screen(canvas, under, color, _areaRadius, dpr);
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
      old.dpr != dpr ||
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
    this.valueFormat,
  });

  /// Its accessible name.
  final String label;

  /// The values in order; null is a gap.
  final List<double?> values;

  /// Its size.
  final double width, height;

  /// Fills under the line, faintly.
  final bool area;

  /// How the values a screen reader hears read, in the reader's digits;
  /// null: whole numbers.
  final RawChartValueFormat? valueFormat;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    final digits = RawWidgetsLocalizations.of(context);
    final valueFormat =
        this.valueFormat ?? const RawChartValueFormat(fractionDigits: 0);
    String fmt(double n) => valueFormat.format(n, digits);
    final finite = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    final read = finite.isEmpty
        ? ComicLocalizations.of(context).noData
        : [
            digits.chartRangeLabel(fmt(finite.first), fmt(finite.last)),
            digits.chartExtremesLabel(
              fmt(finite.reduce(math.min)),
              fmt(finite.reduce(math.max)),
            ),
          ].join(digits.listSeparator);
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
            MediaQuery.devicePixelRatioOf(context),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<double?>('values', values))
      ..add(DoubleProperty('width', width, defaultValue: 96))
      ..add(DoubleProperty('height', height, defaultValue: 28))
      ..add(
        FlagProperty(
          'area',
          value: area,
          ifFalse: 'area: false',
          defaultValue: true,
        ),
      )
      ..add(
        DiagnosticsProperty<RawChartValueFormat>(
          'valueFormat',
          valueFormat,
          defaultValue: null,
        ),
      );
  }
}

class _SparkInk extends CustomPainter {
  _SparkInk(
    this.values,
    this.colors,
    this.direction,
    this.area, [
    this.dpr = 1,
  ]);

  /// The device's pixels per logical pixel: the area's dots land on whole ones.
  final double dpr;
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
        _screen(canvas, under, color, _sparkRadius, dpr);
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
      old.dpr != dpr ||
      !listEquals(old.values, values) ||
      old.colors != colors ||
      old.direction != direction ||
      old.area != area;
}

// A sparkline uses larger dots to keep its filled area visible at small sizes.
const double _areaPitch = 5, _areaRadius = 1.05, _sparkRadius = 1.4;

void _screen(Canvas canvas, Path area, Color ink, double radius, double dpr) {
  canvas.save();
  canvas.clipPath(area);
  ComicScreenGrid(
    _areaPitch,
    radius,
    dpr,
  ).paint(canvas, area.getBounds(), ink.withValues(alpha: 1));
  canvas.restore();
}
