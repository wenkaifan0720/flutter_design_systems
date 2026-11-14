/// Chart: a simple chart on tokens, no chart library (CONTRACT §4.1
/// `chart`). Counts plot from zero as bars or a line, a label under each
/// point, as they always have; a measure (a pulse, a weight) plots on an
/// axis scaled to it ([ExpressiveChartDomain]) with its labels thinned to
/// fit ([ExpressiveChartLabels]); and a paired measure (a blood pressure's
/// two numbers) plots as two series on one axis ([ExpressiveChart.paired]).
///
/// Material has no chart component; this one is built for the host app
/// only from the scheme's roles, the type scale, the spacing scale, component tokens
/// and springs.
library;

import 'dart:async' show Timer;
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/widgets.dart';

import '../color.dart' show ExpressiveColorScheme;
import '../internal/tokens/linear_progress_indicator_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../component_themes.dart';
import '../elevation.dart';
import '../spacing.dart';
import '../strings.dart';
import '../theme.dart';
import 'feedback.dart' show ExpressiveSkeleton;

/// One point of a chart: its [label] on the axis and its [value].
@immutable
class ExpressiveChartPoint {
  /// A point labelled [label] with [value], standing at [at] when given, in [color] when given.
  const ExpressiveChartPoint(this.label, this.value, {this.at, this.color});

  /// The axis label.
  final String label;

  /// The value (≥ 0 on a zero domain).
  final double value;

  /// Where the point stands on the x axis, in the unit of the chart's
  /// `span` (days from the range's start, say: a reading at 8 PM stands at
  /// 8 PM of its day); by its index when null.
  final double? at;

  /// The point's own colour on a line (the status its value is in: a
  /// score under its goal in an amber, a pulse in its zone's colour),
  /// drawing its dot and the segment that ends at it; the series' colour
  /// when null. Never the only sign of the status: the card around the
  /// chart names it.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartPoint &&
      other.label == label &&
      other.value == value &&
      other.at == at &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, value, at, color);
}

/// A candidate x-axis label: where it stands, in the unit of the chart's
/// `span`, and what it says (`Sep 21`).
@immutable
class ExpressiveChartTick {
  /// A tick standing at [at] and reading [label].
  const ExpressiveChartTick(this.at, this.label);

  /// Where the label stands.
  final double at;

  /// What it says.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartTick && other.at == at && other.label == label;

  @override
  int get hashCode => Object.hash(at, label);
}

/// One named series of a paired chart: its [label] (the legend's word and
/// what a screen reader says) and its [points].
@immutable
class ExpressiveChartSeries {
  /// A series named [label] of [points].
  const ExpressiveChartSeries(this.label, this.points);

  /// The series' name: `Systolic`.
  final String label;

  /// The points, in axis order.
  final List<ExpressiveChartPoint> points;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartSeries &&
      other.label == label &&
      listEquals(other.points, points);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(points));
}

/// A band across the plot between two values (a target range, a
/// person's usual range), drawn in `surfaceContainerHigh` (or its own
/// [color]) under the series and named in the legend and to a screen
/// reader.
@immutable
class ExpressiveChartBand {
  /// A band from [low] to [high], named [label].
  const ExpressiveChartBand(
    this.low,
    this.high, {
    required this.label,
    this.color,
  });

  /// The band's lower value.
  final double low;

  /// The band's upper value.
  final double high;

  /// Its name, in a paired chart's legend and to a screen reader:
  /// `Your target`.
  final String label;

  /// Its fill (a range in its status's container colour, say);
  /// `surfaceContainerHigh` when null.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartBand &&
      other.low == low &&
      other.high == high &&
      other.label == label &&
      other.color == color;

  @override
  int get hashCode => Object.hash(low, high, label, color);
}

/// A goal across the plot at one value, drawn as a dotted line in
/// `outline` under the series (a sleep goal, a goal weight) and named to a
/// screen reader.
@immutable
class ExpressiveChartTarget {
  /// A target at [value], named [label].
  const ExpressiveChartTarget(this.value, {required this.label});

  /// Where the goal stands.
  final double value;

  /// What it is called: `Goal`.
  final String label;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartTarget &&
      other.value == value &&
      other.label == label;

  @override
  int get hashCode => Object.hash(value, label);
}

enum _DomainKind { zero, data, fixed }

/// What a chart's y axis spans.
///
/// - [ExpressiveChartDomain.zero] (the default): 0 to the largest value,
///   for counts.
/// - [ExpressiveChartDomain.data]: the values' own range, padded, for a
///   measure (pulse 64–78 reads 60–80 by 5).
/// - [ExpressiveChartDomain.fixed]: a pinned range, widened to any value
///   that falls outside it (a blood pressure's 60–180 by 20).
///
/// A scaled axis (anything but a plain zero chart) snaps outward to a round
/// step, 1, 2 or 5 × 10ⁿ, about four steps high unless a [step] is given,
/// and draws its gridlines there.
@immutable
final class ExpressiveChartDomain {
  /// From zero to the largest value.
  const ExpressiveChartDomain.zero()
    : _kind = _DomainKind.zero,
      padding = 0,
      min = null,
      max = null,
      step = null;

  /// The values' range, padded each side by [padding] of it (a flat series
  /// gets ±1), snapped outward to round steps.
  const ExpressiveChartDomain.data({this.padding = 0.1, this.step})
    : _kind = _DomainKind.data,
      min = null,
      max = null;

  /// [min] to [max], widened to the values at [step] (a round step about
  /// four high when null).
  const ExpressiveChartDomain.fixed(
    double this.min,
    double this.max, {
    this.step,
  }) : _kind = _DomainKind.fixed,
       padding = 0;

  final _DomainKind _kind;

  /// The share of the data's range added each side ([ExpressiveChartDomain.data]).
  final double padding;

  /// The pinned bounds ([ExpressiveChartDomain.fixed]).
  final double? min;

  /// The pinned upper bound ([ExpressiveChartDomain.fixed]).
  final double? max;

  /// The gridlines' step; a round step about four high when null.
  final double? step;

  /// Whether the axis starts at zero (a count), so a line may carry its
  /// tonal area down to it.
  bool get fromZero => _kind == _DomainKind.zero;

  /// The axis this domain gives [values]: its bounds and gridline step.
  ExpressiveChartAxis resolve(Iterable<double> values) {
    final list = values.toList();
    switch (_kind) {
      case _DomainKind.zero:
        final peak = list.fold<double>(0, math.max);
        final hi = peak <= 0 ? 1.0 : peak;
        final s = step ?? _niceStep(hi / 4);
        return ExpressiveChartAxis(0, _up(hi, s), s);
      case _DomainKind.data:
        if (list.isEmpty) return const ExpressiveChartAxis(0, 1, 0.25);
        var lo = list.reduce(math.min);
        var hi = list.reduce(math.max);
        if (hi - lo < 1e-9) {
          lo -= 1;
          hi += 1;
        }
        final pad = (hi - lo) * padding;
        lo -= pad;
        hi += pad;
        final s = step ?? _niceStep((hi - lo) / 4);
        return ExpressiveChartAxis(_down(lo, s), _up(hi, s), s);
      case _DomainKind.fixed:
        var lo = min!;
        var hi = max!;
        final s = step ?? _niceStep((hi - lo) / 4);
        if (list.isNotEmpty) {
          lo = math.min(lo, _down(list.reduce(math.min), s));
          hi = math.max(hi, _up(list.reduce(math.max), s));
        }
        return ExpressiveChartAxis(lo, hi, s);
    }
  }

  /// The round step (1, 2 or 5 × 10ⁿ) at or above [raw].
  static double _niceStep(double raw) {
    if (raw <= 0 || !raw.isFinite) return 1;
    final magnitude = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final fraction = raw / magnitude;
    final nice = fraction <= 1
        ? 1
        : fraction <= 2
        ? 2
        : fraction <= 5
        ? 5
        : 10;
    return magnitude * nice;
  }

  // Snapping tolerates float noise: 172.0 / 0.5 must floor to 344, not 343.
  static double _down(double v, double step) =>
      (v / step + 1e-9).floor() * step;

  static double _up(double v, double step) => (v / step - 1e-9).ceil() * step;

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartDomain &&
      other._kind == _kind &&
      other.padding == padding &&
      other.min == min &&
      other.max == max &&
      other.step == step;

  @override
  int get hashCode => Object.hash(_kind, padding, min, max, step);
}

/// A resolved y axis: its bounds and the step its gridlines stand at.
@immutable
class ExpressiveChartAxis {
  /// An axis from [min] to [max] with gridlines every [step].
  const ExpressiveChartAxis(this.min, this.max, this.step);

  /// The lowest value: the baseline.
  final double min;

  /// The highest value: the top gridline.
  final double max;

  /// The gridlines' step.
  final double step;

  /// The values the gridlines stand at, [min] to [max].
  List<double> get lines {
    final count = ((max - min) / step).round();
    return <double>[for (var i = 0; i <= count; i++) min + step * i];
  }

  /// How [value] reads on this axis: as many decimals as the step needs.
  String format(double value) {
    var decimals = 0;
    var scaled = step;
    while (decimals < 3 && (scaled - scaled.roundToDouble()).abs() > 1e-6) {
      decimals++;
      scaled *= 10;
    }
    return value.toStringAsFixed(decimals);
  }

  @override
  bool operator ==(Object other) =>
      other is ExpressiveChartAxis &&
      other.min == min &&
      other.max == max &&
      other.step == step;

  @override
  int get hashCode => Object.hash(min, max, step);

  @override
  String toString() => 'ExpressiveChartAxis($min, $max, $step)';
}

/// Which x-axis labels a chart shows.
enum ExpressiveChartLabels {
  /// Every point's label (the default): a chart of a few counts.
  all,

  /// Every label when they fit; otherwise every k-th, counted back from the
  /// last, k the smallest step at which no two come closer than 8dp and at
  /// most seven remain, so the gaps are even (a week shows all seven days,
  /// a month every fifth).
  sparse,

  /// No labels, no gridlines and no baseline: a list row's sparkline,
  /// announced by its row, not by the chart.
  none,

  /// Every point's label under it, and no y axis or gridlines: a card's
  /// trend (a week of scores under the week's score), its scale said by
  /// the card. The [ExpressiveChart.highlight] point's label (today)
  /// stands on a `surfaceContainerHighest` pill.
  plain,
}

/// A chart's kinds.
enum ExpressiveChartType {
  /// Rounded bars, one per point.
  bar,

  /// A line through the points over a tonal area.
  line,

  /// Two series on one axis: the first solid with filled points, the
  /// second dashed with diamond points.
  paired,

  /// A ring of parts of a whole, a legend of each part's value under it.
  donut,
}

/// A simple chart on tokens, no chart library: [points] as rounded bars
/// ([ExpressiveChart.bar]: `outline`, at least 3:1 on the surface in
/// every scheme as a mark that carries a value must be, the [highlight]
/// bar in `primary`) or as a line ([ExpressiveChart.line]: a `primary`
/// stroke of the linear progress indicator's track thickness over a
/// `primaryContainer` area, the [highlight] point marked), on a hairline
/// `outlineVariant` baseline, with each point's label under it in
/// `labelSmall`. The plot is [aspectRatio] wide to high; a change of values
/// springs the bars and the line to their new heights (the default spatial
/// spring).
///
/// A line of a measure takes a [domain] (a data domain fills the plot:
/// pulse 64–78 reads 60–80 by 5) and [labels] (`sparse` for a month of
/// points, `none` for a sparkline). On a scaled axis the gridlines stand at
/// round steps in `outlineVariant`, each labelled in `labelSmall` and
/// centred on its line; a domain off zero draws no tonal area (it would
/// read as a quantity from zero). Points with an `at` stand at their time
/// across [span], with [ticks] as the x labels; where the points start
/// after the span does, [emptyLabel] says so in the empty stretch
/// ("No readings before Sep 8").
///
/// [ExpressiveChart.paired] draws two series on one axis (a blood
/// pressure), each a 4dp round-capped line: the first in `primary`,
/// solid, with round points; the second in `tertiary`, in pill dashes,
/// with diamond points (Material's library shapes), so the two never rest
/// on colour alone; an optional [band] (a target) on the small corner
/// in the primary container; a legend under the plot drawing each
/// series' own line and point. Points are drawn while they stand 20dp
/// apart or more on average (a week of two readings a day); denser, the
/// line and its dash carry the series.
///
/// [ExpressiveChart.donut] draws parts of a whole as a ring: each part an
/// arc in its own colour (`primary`, `tertiary`, `secondary`, `outline` in
/// turn, or the point's own), 4dp apart, its ends round, an optional
/// [centerValue] over [centerLabel] in the hole, and a legend under it
/// naming each part with its value.
///
/// While [loading] the plot is a skeleton of its own size; with no points
/// it says so ([ExpressiveLocalizations.chartEmpty]) over a baseline. A
/// count chart with [tooltip] shows the point under a pointer (a hover, or
/// a finger down) in a plain tooltip's pill above it, without taking the
/// tap from a card it stands in.
///
/// Announced as one image: [semanticLabel], or every label and value when
/// null (a paired chart: each series' count and range). A sparkline
/// ([ExpressiveChartLabels.none]) is left to its row.
///
/// ```dart
/// ExpressiveChart.bar(points: week, highlight: 6, semanticLabel: 'Minutes read, last 7 days')
/// ```
class ExpressiveChart extends StatelessWidget {
  /// Rounded bars, their corners never rounder than a short bar is tall;
  /// an optional [target] (a daily goal) dotted across them, the axis
  /// reaching it.
  const ExpressiveChart.bar({
    required this.points,
    this.highlight,
    this.aspectRatio = 2,
    this.semanticLabel,
    this.target,
    this.style,
    this.loading = false,
    this.tooltip = false,
    super.key,
  }) : kind = ExpressiveChartType.bar,
       centerLabel = null,
       centerValue = null,
       domain = const ExpressiveChartDomain.zero(),
       labels = ExpressiveChartLabels.all,
       span = null,
       ticks = null,
       emptyLabel = null,
       first = null,
       second = null,
       band = null,
       color = null;

  /// A line over a tonal area; on a [domain] off zero, a line alone. A
  /// [band] (a usual range) and a [target] (a goal's dotted line) stand
  /// under it; [color] is the series' colour.
  const ExpressiveChart.line({
    required this.points,
    this.highlight,
    this.aspectRatio = 2,
    this.semanticLabel,
    this.domain = const ExpressiveChartDomain.zero(),
    this.labels = ExpressiveChartLabels.all,
    this.span,
    this.ticks,
    this.emptyLabel,
    this.band,
    this.target,
    this.color,
    this.style,
    this.loading = false,
    this.tooltip = false,
    super.key,
  }) : kind = ExpressiveChartType.line,
       first = null,
       second = null,
       centerLabel = null,
       centerValue = null;

  /// Two series on one axis.
  const ExpressiveChart.paired({
    required ExpressiveChartSeries this.first,
    required ExpressiveChartSeries this.second,
    this.band,
    this.aspectRatio = 1.6,
    this.semanticLabel,
    this.domain = const ExpressiveChartDomain.fixed(60, 180, step: 20),
    this.labels = ExpressiveChartLabels.sparse,
    this.span,
    this.ticks,
    this.emptyLabel,
    this.style,
    this.loading = false,
    super.key,
  }) : kind = ExpressiveChartType.paired,
       points = const <ExpressiveChartPoint>[],
       highlight = null,
       target = null,
       color = null,
       tooltip = false,
       centerLabel = null,
       centerValue = null;

  /// Parts of a whole as a ring, [centerValue] over [centerLabel] in its
  /// hole, a legend of each part's value under it.
  const ExpressiveChart.donut({
    required this.points,
    this.centerValue,
    this.centerLabel,
    this.aspectRatio = 1,
    this.semanticLabel,
    this.style,
    this.loading = false,
    super.key,
  }) : kind = ExpressiveChartType.donut,
       highlight = null,
       domain = const ExpressiveChartDomain.zero(),
       labels = ExpressiveChartLabels.all,
       span = null,
       ticks = null,
       emptyLabel = null,
       first = null,
       second = null,
       band = null,
       target = null,
       color = null,
       tooltip = false;

  /// Whether the data is still coming: the plot is a skeleton of its size.
  final bool loading;

  /// Whether a count chart (bars, or a line from zero) shows the point under
  /// a pointer in a tooltip.
  final bool tooltip;

  /// A donut's figure in its hole (`1,240`); none when null.
  final String? centerValue;

  /// A donut's words under [centerValue] (`Spent`); none when null.
  final String? centerLabel;

  /// Stateful frame, label and primary-ink overrides; data coordinates are unchanged.
  final ExpressiveComponentThemeData? style;

  /// The points, in axis order (bar and line).
  final List<ExpressiveChartPoint> points;

  /// The index of the point drawn in the accent; none when null.
  final int? highlight;

  /// The plot's width-to-height ratio (the labels and legend included on a
  /// scaled axis).
  final double aspectRatio;

  /// Bars, a line or a pair.
  final ExpressiveChartType kind;

  /// What a screen reader says; every label and value when null.
  final String? semanticLabel;

  /// What the y axis spans.
  final ExpressiveChartDomain domain;

  /// Which x labels show.
  final ExpressiveChartLabels labels;

  /// The x axis's extent, 0 to [span], in the unit of the points' `at`;
  /// the last point's `at` (or index) when null.
  final double? span;

  /// The candidate x labels; each point's label at the point when null.
  final List<ExpressiveChartTick>? ticks;

  /// The words for the stretch before the first point, where the points
  /// start after the span does; nothing is said when null.
  final String? emptyLabel;

  /// The paired chart's first series (solid, filled points, `primary`).
  final ExpressiveChartSeries? first;

  /// The paired chart's second series (dashed, diamond points, `tertiary`).
  final ExpressiveChartSeries? second;

  /// The band under a line or a pair (a target range, a usual range), or
  /// none.
  final ExpressiveChartBand? band;

  /// A line's or the bars' goal, dotted across the plot, or none.
  final ExpressiveChartTarget? target;

  /// A line's colour; `primary` when null. A point's own
  /// [ExpressiveChartPoint.color] draws its dot and the segment ending at
  /// it.
  final Color? color;

  /// Whether this chart is the original count chart: a bar, or a line from
  /// zero with a label under every point at its index.
  bool get _plain =>
      kind == ExpressiveChartType.bar ||
      (kind == ExpressiveChartType.line &&
          domain == const ExpressiveChartDomain.zero() &&
          labels == ExpressiveChartLabels.all &&
          span == null &&
          ticks == null &&
          emptyLabel == null &&
          band == null &&
          target == null &&
          color == null &&
          points.every((point) => point.at == null && point.color == null));

  static List<double> _lerp(List<double> a, List<double> b, double t) =>
      a.length != b.length
      ? b
      : <double>[for (var i = 0; i < b.length; i++) a[i] + (b[i] - a[i]) * t];

  static String _number(double value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toStringAsFixed(1);

  bool get _empty => kind == ExpressiveChartType.paired
      ? first!.points.isEmpty && second!.points.isEmpty
      : points.isEmpty;

  @override
  Widget build(BuildContext context) {
    if (loading) return _buildLoading(context);
    if (_empty) return _buildEmpty(context);
    if (kind == ExpressiveChartType.donut) return _buildDonut(context);
    return _plain ? _buildPlain(context) : _buildScaled(context);
  }

  /// The plot's size as a skeleton, announced as loading.
  Widget _buildLoading(BuildContext context) => Semantics(
    label: ExpressiveLocalizations.of(context).loading,
    child: ExcludeSemantics(
      child: _frame(
        context,
        AspectRatio(
          aspectRatio: aspectRatio,
          child: LayoutBuilder(
            builder: (context, box) =>
                ExpressiveSkeleton(width: box.maxWidth, height: box.maxHeight),
          ),
        ),
      ),
    ),
  );

  /// No points: the plot's room, a hairline baseline and the words.
  Widget _buildEmpty(BuildContext context) {
    final theme = context.expressiveTheme;
    final words = ExpressiveLocalizations.of(context).chartEmpty;
    return Semantics(
      label: semanticLabel == null ? words : '$semanticLabel: $words',
      child: ExcludeSemantics(
        child: _frame(
          context,
          AspectRatio(
            aspectRatio: aspectRatio,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colors.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  words,
                  textAlign: TextAlign.center,
                  style: theme.type.bodyMedium.copyWith(
                    color: theme.colors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// The donut's parts in turn: `primary`, `tertiary`, `secondary`,
  /// `outline`, or each point's own colour.
  static List<Color> _partColors(
    ExpressiveThemeData theme,
    List<ExpressiveChartPoint> points,
  ) {
    final colors = theme.colors;
    final cycle = <Color>[
      colors.primary,
      colors.tertiary,
      colors.secondary,
      colors.outline,
    ];
    return <Color>[
      for (var i = 0; i < points.length; i++)
        points[i].color ?? cycle[i % cycle.length],
    ];
  }

  Widget _buildDonut(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final visual = theme.chartTheme.merge(style);
    const states = <WidgetState>{};
    final typography = visual.textStyle?.resolve(states);
    final parts = _partColors(theme, points);
    final total = points.fold<double>(0, (a, p) => a + math.max(0, p.value));
    String share(ExpressiveChartPoint p) => total <= 0
        ? _number(p.value)
        : '${_number(p.value)} (${(p.value / total * 100).round()}%)';
    final label =
        semanticLabel ??
        <String>[
          if (centerLabel case final words?)
            centerValue == null ? words : '$words $centerValue',
          points.map((p) => '${p.label} ${share(p)}').join(', '),
        ].join('; ');
    final legendStyle = theme.type.bodySmall
        .merge(typography)
        .copyWith(color: colors.onSurfaceVariant);
    final ring = AspectRatio(
      aspectRatio: aspectRatio,
      child: _ChartValues(
        values: <double>[for (final p in points) math.max(0, p.value)],
        builder: (shown) => CustomPaint(
          size: Size.infinite,
          painter: _DonutPainter(values: shown, colors: parts),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (centerValue case final value?)
                  Text(
                    value,
                    maxLines: 1,
                    style: theme.type.headlineSmall
                        .merge(typography)
                        .copyWith(color: colors.onSurface),
                  ),
                if (centerLabel case final words?)
                  Text(
                    words,
                    maxLines: 1,
                    style: theme.type.labelMedium
                        .merge(typography)
                        .copyWith(color: colors.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: _frame(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ExpressiveSpacing.s16,
            children: <Widget>[
              // In a bounded height (a card of fixed size) the ring gives way
              // to the legend, centred and still round, rather than
              // overflowing; unbounded, a loose flex lays out as before.
              Flexible(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1,
                  child: ring,
                ),
              ),
              Wrap(
                spacing: ExpressiveSpacing.s16,
                runSpacing: ExpressiveSpacing.s4,
                children: <Widget>[
                  for (var i = 0; i < points.length; i++)
                    _LegendEntry(
                      label: '${points[i].label} · ${share(points[i])}',
                      style: legendStyle,
                      mark: _Legend(
                        color: parts[i],
                        dashed: false,
                        swatch: true,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _frame(BuildContext context, Widget child) => ExpressiveSurface(
    componentStyle: context.expressiveTheme.chartTheme,
    style: style,
    clipBehavior:
        context.expressiveTheme.chartTheme.merge(style).shape?.resolve({}) !=
            null
        ? Clip.antiAlias
        : Clip.none,
    shape: context.expressiveTheme.shapes.none,
    color: expressiveTransparent,
    padding: EdgeInsets.zero,
    child: child,
  );

  Widget _buildPlain(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final visual = theme.chartTheme.merge(style);
    const states = <WidgetState>{};
    final ink = visual.foregroundColor?.resolve(states);
    final typography = visual.textStyle?.resolve(states);
    final values = <double>[for (final point in points) point.value];
    final label =
        semanticLabel ??
        <String>[
          points.map((p) => '${p.label} ${_number(p.value)}').join(', '),
          if (target case final target?)
            '${target.label}: ${_number(target.value)}',
        ].join('; ');
    final gap = points.length > 12
        ? ExpressiveSpacing.s2
        : ExpressiveSpacing.s8;
    final plot = AspectRatio(
      aspectRatio: aspectRatio,
      child: _ChartValues(
        values: values,
        builder: (shown) => CustomPaint(
          size: Size.infinite,
          painter: _ChartPainter(
            kind: kind,
            values: shown,
            highlight: highlight,
            gap: gap,
            stroke: LinearProgressIndicatorTokens.trackThickness,
            bar: colors.outline,
            accent: ink ?? colors.primary,
            area: colors.primaryContainer,
            ground: colors.surface,
            baseline: colors.outlineVariant,
            ruleWidth: 1,
            target: kind == ExpressiveChartType.bar ? target?.value : null,
            targetColor: colors.outline,
          ),
        ),
      ),
    );
    final shownPlot = tooltip
        ? _PointTooltip(
            kind: kind,
            points: points,
            gap: gap,
            peak: values.fold<double>(
              kind == ExpressiveChartType.bar ? target?.value ?? 0 : 0,
              math.max,
            ),
            child: plot,
          )
        : plot;
    final labelStyle = theme.type.labelSmall
        .merge(typography)
        .copyWith(color: ink ?? colors.onSurfaceVariant);
    final accentLabel = theme.type.labelSmallEmphasized
        .merge(typography)
        .copyWith(color: ink ?? colors.onSurface);
    return Semantics(
      image: true,
      label: label,
      child: ExcludeSemantics(
        child: _frame(
          context,
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ExpressiveSpacing.s8,
            children: <Widget>[
              shownPlot,
              Row(
                spacing: gap,
                children: <Widget>[
                  for (var i = 0; i < points.length; i++)
                    Expanded(
                      child: Text(
                        points[i].label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        softWrap: false,
                        style: i == highlight ? accentLabel : labelStyle,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// The series a scaled chart draws, in paint order.
  List<List<ExpressiveChartPoint>> get _series =>
      kind == ExpressiveChartType.paired
      ? <List<ExpressiveChartPoint>>[first!.points, second!.points]
      : <List<ExpressiveChartPoint>>[points];

  String _semantics(ExpressiveChartAxis axis) {
    if (semanticLabel case final label?) return label;
    if (kind != ExpressiveChartType.paired) {
      return <String>[
        points.map((p) => '${p.label} ${axis.format(p.value)}').join(', '),
        if (band case final band?)
          '${band.label}: ${axis.format(band.low)} to ${axis.format(band.high)}',
        if (target case final target?)
          '${target.label}: ${axis.format(target.value)}',
      ].join('; ');
    }
    String describe(ExpressiveChartSeries series) {
      final values = series.points.map((p) => p.value);
      if (values.isEmpty) return '${series.label}: no points';
      return '${series.label}: ${values.length} points, '
          '${axis.format(values.reduce(math.min))} to '
          '${axis.format(values.reduce(math.max))}';
    }

    return <String>[
      describe(first!),
      describe(second!),
      if (band case final band?)
        '${band.label}: ${axis.format(band.low)} to ${axis.format(band.high)}',
      ?emptyLabel,
    ].join('; ');
  }

  Widget _buildScaled(BuildContext context) {
    final theme = context.expressiveTheme;
    final colors = theme.colors;
    final visual = theme.chartTheme.merge(style);
    const states = <WidgetState>{};
    final ink = visual.foregroundColor?.resolve(states);
    final typography = visual.textStyle?.resolve(states);
    final series = _series;
    final values = <double>[
      for (final s in series)
        for (final p in s) p.value,
    ];
    final axis = domain.resolve(<double>[
      ...values,
      if (band case final band?) ...<double>[band.low, band.high],
      if (target case final target?) target.value,
    ]);
    // x positions: a point's `at`, else its index.
    final xs = <List<double>>[
      for (final s in series)
        <double>[for (var i = 0; i < s.length; i++) s[i].at ?? i.toDouble()],
    ];
    final allX = <double>[for (final x in xs) ...x];
    final extent = span ?? (allX.isEmpty ? 0.0 : allX.reduce(math.max));
    final candidates =
        ticks ??
        <ExpressiveChartTick>[
          for (var i = 0; i < series.first.length; i++)
            ExpressiveChartTick(xs.first[i], series.first[i].label),
        ];
    // The tick under the highlighted point (a plain chart pills its label).
    final marked = highlight;
    final markedAt = marked == null || marked < 0 || marked >= xs.first.length
        ? null
        : xs.first[marked];
    final markedTick = markedAt == null
        ? -1
        : candidates.indexWhere((tick) => tick.at == markedAt);
    final paired = kind == ExpressiveChartType.paired;
    final plot = AspectRatio(
      aspectRatio: aspectRatio,
      child: _ChartValues(
        values: values,
        builder: (shown) {
          var at = 0;
          final lines = <_Line>[
            for (var s = 0; s < series.length; s++)
              _Line(
                xs: xs[s],
                ys: <double>[for (final _ in series[s]) shown[at++]],
                color: s == 0
                    ? ink ?? color ?? colors.primary
                    : colors.tertiary,
                dashed: s == 1,
                colors: <Color?>[for (final p in series[s]) p.color],
              ),
          ];
          return CustomPaint(
            size: Size.infinite,
            painter: _ScaledChartPainter(
              lines: lines,
              axis: axis,
              span: extent,
              ticks: candidates,
              labels: labels,
              emptyLabel: emptyLabel,
              firstX: allX.isEmpty ? null : allX.reduce(math.min),
              band: band == null ? null : (band!.low, band!.high),
              bandColor: band?.color ?? _bandTint(colors),
              target: target?.value,
              targetColor: colors.outline,
              highlightFill: colors.surfaceContainerHighest,
              highlightStyle: theme.type.labelSmallEmphasized
                  .merge(typography)
                  .copyWith(color: ink ?? colors.onSurface),
              area: kind == ExpressiveChartType.line && domain.fromZero
                  ? colors.primaryContainer
                  : null,
              highlight: highlight,
              highlightTick: markedTick < 0 ? null : markedTick,
              grid: colors.surfaceContainerHighest,
              ruleWidth: 1,
              pointStroke: ExpressiveSpacing.s2,
              labelStyle: theme.type.labelSmall
                  .merge(typography)
                  .copyWith(color: ink ?? colors.onSurfaceVariant),
              stroke: kind == ExpressiveChartType.paired
                  ? _seriesStroke
                  : LinearProgressIndicatorTokens.trackThickness,
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: Directionality.of(context),
            ),
          );
        },
      ),
    );
    if (labels == ExpressiveChartLabels.none) {
      return ExcludeSemantics(child: _frame(context, plot));
    }
    final Widget body;
    if (paired) {
      final legendStyle = theme.type.labelMedium
          .merge(typography)
          .copyWith(color: ink ?? colors.onSurfaceVariant);
      body = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ExpressiveSpacing.s8,
        children: <Widget>[
          plot,
          Wrap(
            spacing: ExpressiveSpacing.s16,
            runSpacing: ExpressiveSpacing.s4,
            children: <Widget>[
              _LegendEntry(
                label: first!.label,
                style: legendStyle,
                mark: _Legend(
                  color: ink ?? colors.primary,
                  dashed: false,
                  pointStroke: ExpressiveSpacing.s2,
                ),
              ),
              _LegendEntry(
                label: second!.label,
                style: legendStyle,
                mark: _Legend(
                  color: colors.tertiary,
                  dashed: true,
                  pointStroke: ExpressiveSpacing.s2,
                ),
              ),
              if (band case final band?)
                _LegendEntry(
                  label: band.label,
                  style: legendStyle,
                  mark: _Legend(
                    color: band.color ?? _bandTint(colors),
                    dashed: false,
                    swatch: true,
                    edge: colors.outlineVariant,
                    edgeStroke: 0,
                  ),
                ),
            ],
          ),
        ],
      );
    } else {
      body = plot;
    }
    return Semantics(
      image: true,
      label: _semantics(axis),
      child: ExcludeSemantics(child: _frame(context, body)),
    );
  }
}

/// The chart's values, springing to each new list (the default spatial
/// spring): a list is compared by its contents, so a rebuild with equal
/// values does not restart the run.
/// A donut's ring: one arc per part, clockwise from 12 o'clock, 4dp apart.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({required this.values, required this.colors});

  final List<double> values;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, b) => a + b);
    if (total <= 0) return;
    final side = math.min(size.width, size.height);
    final stroke = side * .14;
    final rect = Rect.fromCenter(
      center: size.center(Offset.zero),
      width: side - stroke,
      height: side - stroke,
    );
    final radius = rect.width / 2;
    // The gap between parts, as an angle; round ends reach into it by half
    // the stroke on each side.
    final gap = (ExpressiveSpacing.s4 + stroke) / radius;
    final parts = values.where((v) => v > 0).length;
    var start = -math.pi / 2;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * math.pi * 2;
      if (values[i] <= 0) continue;
      final drawn = parts > 1 ? math.max(0.0, sweep - gap) : sweep;
      final paint = Paint()
        ..color = colors[i]
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = parts == 1 ? StrokeCap.butt : StrokeCap.round;
      if (drawn > 0) {
        canvas.drawArc(
          rect,
          start + (parts > 1 ? gap / 2 : 0),
          drawn,
          false,
          paint,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      !listEquals(old.values, values) || !listEquals(old.colors, colors);
}

/// A count chart's tooltip: the point under a hovering pointer, or under a
/// finger while it is down and a moment after, in a plain tooltip's
/// `inverseSurface` pill above the point. A [Listener], so a card's tap
/// still reaches the card.
class _PointTooltip extends StatefulWidget {
  const _PointTooltip({
    required this.kind,
    required this.points,
    required this.gap,
    required this.peak,
    required this.child,
  });

  final ExpressiveChartType kind;
  final List<ExpressiveChartPoint> points;
  final double gap;
  final double peak;
  final Widget child;

  @override
  State<_PointTooltip> createState() => _PointTooltipState();
}

class _PointTooltipState extends State<_PointTooltip> {
  int? _shown;
  Timer? _hide;

  @override
  void dispose() {
    _hide?.cancel();
    super.dispose();
  }

  int? _indexAt(double x, double width) {
    final n = widget.points.length;
    if (n == 0) return null;
    if (widget.kind == ExpressiveChartType.bar) {
      final column = (width - widget.gap * (n - 1)) / n;
      return (x / (column + widget.gap)).floor().clamp(0, n - 1);
    }
    // A line's points stand at the bars' centres.
    final column = (width - widget.gap * (n - 1)) / n;
    return ((x - column / 2) / (column + widget.gap)).round().clamp(0, n - 1);
  }

  void _show(Offset at, double width) {
    _hide?.cancel();
    final i = _indexAt(at.dx, width);
    if (i != _shown) setState(() => _shown = i);
  }

  void _leave({Duration after = Duration.zero}) {
    _hide?.cancel();
    _hide = Timer(after, () {
      if (mounted) setState(() => _shown = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    return LayoutBuilder(
      builder: (context, box) {
        final width = box.maxWidth;
        final height = width.isFinite && box.maxHeight.isFinite
            ? box.maxHeight
            : null;
        final i = _shown;
        Widget? pill;
        if (i != null && i < widget.points.length) {
          final n = widget.points.length;
          final column = (width - widget.gap * (n - 1)) / n;
          final centre = i * (column + widget.gap) + column / 2;
          final point = widget.points[i];
          final top = widget.peak <= 0 ? 1.0 : widget.peak;
          final plotHeight = height ?? 0;
          final y = plotHeight - point.value / top * plotHeight;
          pill = Positioned(
            left: 0,
            right: 0,
            top: math.max(0, y - ExpressiveSpacing.s32 - ExpressiveSpacing.s4),
            child: Align(
              alignment: Alignment(
                width <= 0 ? 0 : (centre / width) * 2 - 1,
                0,
              ),
              child: IgnorePointer(
                child: ExpressiveSurface(
                  shape: theme.shapes.extraSmall,
                  color: theme.colors.inverseSurface,
                  contentColor: theme.colors.inverseOnSurface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ExpressiveSpacing.s8,
                    vertical: ExpressiveSpacing.s4,
                  ),
                  child: Text(
                    '${point.label} · ${ExpressiveChart._number(point.value)}',
                    maxLines: 1,
                    style: theme.type.bodySmall.copyWith(
                      color: theme.colors.inverseOnSurface,
                    ),
                  ),
                ),
              ),
            ),
          );
        }
        return MouseRegion(
          onEnter: (e) => _show(e.localPosition, width),
          onHover: (e) => _show(e.localPosition, width),
          onExit: (_) => _leave(),
          child: Listener(
            onPointerDown: (e) => _show(e.localPosition, width),
            onPointerMove: (e) => _show(e.localPosition, width),
            onPointerUp: (e) => e.kind == PointerDeviceKind.mouse
                ? null
                : _leave(after: const Duration(milliseconds: 1500)),
            onPointerCancel: (_) => _leave(),
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[widget.child, ?pill],
            ),
          ),
        );
      },
    );
  }
}

class _ChartValues extends StatelessWidget {
  const _ChartValues({required this.values, required this.builder});

  final List<double> values;
  final Widget Function(List<double> shown) builder;

  @override
  Widget build(BuildContext context) => ExpressiveSpringTween<_Values>(
    value: _Values(values),
    motion: ExpressiveMotionKey.defaultSpatial,
    lerp: (a, b, t) => _Values(ExpressiveChart._lerp(a.list, b.list, t)),
    builder: (context, shown, _) => builder(shown.list),
  );
}

/// A list of values with value equality.
@immutable
class _Values {
  const _Values(this.list);

  final List<double> list;

  @override
  bool operator ==(Object other) {
    if (other is! _Values || other.list.length != list.length) return false;
    for (var i = 0; i < list.length; i++) {
      if (other.list[i] != list[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(list);
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.kind,
    required this.values,
    required this.highlight,
    required this.gap,
    required this.stroke,
    required this.bar,
    required this.accent,
    required this.area,
    required this.ground,
    required this.baseline,
    required this.ruleWidth,
    this.target,
    this.targetColor = expressiveTransparent,
  });

  final ExpressiveChartType kind;
  final List<double> values;
  final int? highlight;
  final double gap;
  final double stroke;
  final Color bar;
  final Color accent;
  final Color area;
  final Color ground;
  final Color baseline;
  final double ruleWidth;

  /// The bars' goal, dotted across them; none when null.
  final double? target;
  final Color targetColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final peak = values.fold<double>(target ?? 0, (a, b) => a > b ? a : b);
    final top = peak <= 0 ? 1.0 : peak;
    final count = values.length;
    final column = (size.width - gap * (count - 1)) / count;
    double centre(int i) => i * (column + gap) + column / 2;
    double height(double v) => (v.clamp(0, top) / top) * size.height;

    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()
        ..color = baseline
        ..strokeWidth = ruleWidth,
    );

    switch (kind) {
      case ExpressiveChartType.bar:
        if (target case final goal? when goal > 0) {
          final at = size.height - height(goal);
          final dot = Paint()..color = targetColor;
          for (var dx = 0.0; dx <= size.width + 0.5; dx += _targetPitch) {
            canvas.drawCircle(Offset(dx, at), _targetDot, dot);
          }
        }
        for (var i = 0; i < count; i++) {
          final h = height(values[i]);
          if (h <= 0) continue;
          // A bar shorter than half its width rounds only as far as it is
          // tall, so it stays a bar and never reads as a dome.
          final radius = Radius.circular(math.min(column / 2, h));
          final rect = Rect.fromLTWH(
            i * (column + gap),
            size.height - h,
            column,
            h,
          );
          canvas.drawRRect(
            RRect.fromRectAndCorners(rect, topLeft: radius, topRight: radius),
            Paint()..color = i == highlight ? accent : bar,
          );
        }
      case ExpressiveChartType.line:
      case ExpressiveChartType.paired:
      // A donut has a painter of its own.
      case ExpressiveChartType.donut:
        final line = Path();
        for (var i = 0; i < count; i++) {
          final y = size.height - height(values[i]);
          if (i == 0) {
            line.moveTo(centre(i), y);
          } else {
            line.lineTo(centre(i), y);
          }
        }
        final fill = Path.from(line)
          ..lineTo(centre(count - 1), size.height)
          ..lineTo(centre(0), size.height)
          ..close();
        canvas
          ..drawPath(fill, Paint()..color = area)
          ..drawPath(
            line,
            Paint()
              ..color = accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = stroke
              ..strokeCap = StrokeCap.round
              ..strokeJoin = StrokeJoin.round,
          );
        final marked = highlight;
        if (marked != null && marked >= 0 && marked < count) {
          final point = Offset(
            centre(marked),
            size.height - height(values[marked]),
          );
          // The marker: a dot of twice the stroke's width, ringed in the
          // ground so it reads over the line.
          canvas
            ..drawCircle(point, stroke * 2, Paint()..color = ground)
            ..drawCircle(point, stroke * 1.5, Paint()..color = accent);
        }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.kind != kind ||
      old.highlight != highlight ||
      old.gap != gap ||
      old.stroke != stroke ||
      old.bar != bar ||
      old.accent != accent ||
      old.area != area ||
      old.ground != ground ||
      old.baseline != baseline ||
      old.ruleWidth != ruleWidth ||
      old.target != target ||
      old.targetColor != targetColor ||
      _Values(old.values) != _Values(values);
}

// ---------------------------------------------------------------------------
// The scaled axis
// ---------------------------------------------------------------------------

/// The x labels a chart keeps of [ticks] ([ExpressiveChartLabels.sparse]):
/// all of them when they fit; otherwise every k-th, counted back from the
/// last, k the smallest step at which no two labels come closer than [gap]
/// and at most [most] remain. [ticks] are evenly spaced, [widths] their
/// label widths and [scale] logical pixels a unit of the span.
@visibleForTesting
List<int> expressiveSparseTicks(
  List<ExpressiveChartTick> ticks,
  List<double> widths, {
  required double scale,
  double gap = ExpressiveSpacing.s8,
  int most = 7,
}) {
  if (ticks.length < 2) {
    return <int>[for (var i = 0; i < ticks.length; i++) i];
  }
  final spacing = (ticks[1].at - ticks[0].at).abs() * scale;
  final widest = widths.reduce(math.max);
  var k = spacing <= 0
      ? ticks.length
      : math.max(1, ((widest + gap) / spacing).ceil());
  while ((ticks.length + k - 1) ~/ k > most) {
    k++;
  }
  return <int>[for (var i = ticks.length - 1; i >= 0; i -= k) i].reversed
      .toList();
}

/// One series as the scaled painter draws it.
@immutable
class _Line {
  const _Line({
    required this.xs,
    required this.ys,
    required this.color,
    required this.dashed,
    this.colors = const <Color?>[],
  });

  final List<double> xs;
  final List<double> ys;
  final Color color;
  final bool dashed;

  /// Each point's own colour, or null for the line's.
  final List<Color?> colors;

  /// Point [i]'s colour.
  Color at(int i) => (i < colors.length ? colors[i] : null) ?? color;

  /// Whether any point wears its own colour.
  bool get tinted => colors.any((c) => c != null);

  @override
  bool operator ==(Object other) =>
      other is _Line &&
      listEquals(other.xs, xs) &&
      listEquals(other.ys, ys) &&
      other.color == color &&
      other.dashed == dashed &&
      listEquals(other.colors, colors);

  @override
  int get hashCode => Object.hash(
    Object.hashAll(xs),
    Object.hashAll(ys),
    color,
    dashed,
    Object.hashAll(colors),
  );
}

/// A target's dots: their radius and the distance between their centres.
const double _targetDot = ExpressiveSpacing.s2 / 2 + ExpressiveSpacing.s2 / 4;
const double _targetPitch = ExpressiveSpacing.s4 + ExpressiveSpacing.s2;

/// A scaled series' stroke: the count line's track thickness, round
/// capped, Expressive's weight for a line that carries the page.
const double _seriesStroke = ExpressiveSpacing.s4;

/// A band's corner: Material's small step, enough to soften the band
/// without rounding off the range it marks at the plot's ends.
const double _bandCorner = 8;

/// A band's fill when it names none: the primary container, half
/// strength, so the series' own colours stay legible on it.
Color _bandTint(ExpressiveColorScheme colors) =>
    colors.primaryContainer.withValues(alpha: colors.primaryContainer.a * .6);

/// Each series' point shape, from Material's shape library: the first a
/// circle, the second a diamond, so two series part by shape as well as
/// colour and dash.
const List<ExpressiveMaterialShape> _pointShapes = <ExpressiveMaterialShape>[
  ExpressiveMaterialShape.circle,
  ExpressiveMaterialShape.diamond,
];

/// A point's radius, and the clear ring around it that parts it from the
/// line.
const double _pointRadius = ExpressiveSpacing.s6;
const double _pointGap = ExpressiveSpacing.s2;

/// A dash's length and the gap after it, between the round caps' centres:
/// pill dashes, each cap reaching half the stroke past its end.
const double _dashOn = ExpressiveSpacing.s4;
const double _dashOff = ExpressiveSpacing.s10;

/// Points are drawn while a series' points stand this far apart on
/// average, or farther; denser, the line and its dash carry the series.
const double _pointsFrom = ExpressiveSpacing.s20;

/// Strokes [path] solid or in dashes.
void _strokeSeries(
  Canvas canvas,
  Path path,
  Color color,
  double width, {
  required bool dashed,
}) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;
  if (!dashed) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final metric in path.computeMetrics()) {
    for (var d = 0.0; d < metric.length; d += _dashOn + _dashOff) {
      canvas.drawPath(
        metric.extractPath(d, math.min(d + _dashOn, metric.length)),
        paint,
      );
    }
  }
}

/// A series point at [at]: the line cleared around it, then the series'
/// library shape ([_pointShapes]; the second series' when [second]),
/// filled. Paint inside a layer, so the clearing takes only the series'
/// own line.
void _drawPoint(
  Canvas canvas,
  Offset at,
  Color color, {
  required bool second,
  double stroke = ExpressiveSpacing.s2,
}) {
  final shape = ExpressiveMaterialShapeBorder(_pointShapes[second ? 1 : 0]);
  canvas.drawPath(
    shape.getOuterPath(
      Rect.fromCircle(center: at, radius: _pointRadius + _pointGap),
    ),
    Paint()..blendMode = BlendMode.clear,
  );
  canvas.drawPath(
    shape.getOuterPath(Rect.fromCircle(center: at, radius: _pointRadius)),
    Paint()..color = color,
  );
}

class _ScaledChartPainter extends CustomPainter {
  _ScaledChartPainter({
    required this.lines,
    required this.axis,
    required this.span,
    required this.ticks,
    required this.labels,
    required this.emptyLabel,
    required this.firstX,
    required this.band,
    required this.bandColor,
    required this.target,
    required this.targetColor,
    required this.highlightFill,
    required this.highlightStyle,
    required this.area,
    required this.highlight,
    this.highlightTick,
    required this.grid,
    required this.ruleWidth,
    required this.pointStroke,
    required this.labelStyle,
    required this.stroke,
    required this.textScaler,
    required this.textDirection,
  });

  final List<_Line> lines;
  final ExpressiveChartAxis axis;
  final double span;
  final List<ExpressiveChartTick> ticks;
  final ExpressiveChartLabels labels;
  final String? emptyLabel;
  final double? firstX;
  final (double, double)? band;
  final Color bandColor;
  final double? target;
  final Color targetColor;
  final Color highlightFill;
  final TextStyle highlightStyle;
  final Color? area;
  final int? highlight;

  /// The tick under [highlight]'s point, whose label a plain chart pills.
  final int? highlightTick;
  final Color grid;
  final double ruleWidth;
  final double pointStroke;
  final TextStyle labelStyle;
  final double stroke;
  final TextScaler textScaler;
  final TextDirection textDirection;

  TextPainter _label(String text, {double? maxWidth, TextStyle? style}) =>
      TextPainter(
        text: TextSpan(text: text, style: style ?? labelStyle),
        textAlign: TextAlign.center,
        textDirection: textDirection,
        textScaler: textScaler,
      )..layout(maxWidth: maxWidth ?? double.infinity);

  @override
  void paint(Canvas canvas, Size size) {
    final sparkline = labels == ExpressiveChartLabels.none;
    final plain = labels == ExpressiveChartLabels.plain;
    final inset = _pointRadius + _pointGap;
    final Rect plot;
    final yLabels = <TextPainter>[];
    final xLabels = <TextPainter>[];
    var xLabelTop = 0.0;
    final gridValues = axis.lines;
    if (sparkline) {
      plot = Rect.fromLTRB(
        inset,
        inset,
        size.width - inset,
        size.height - inset,
      );
    } else if (plain) {
      // A card's trend: the points' labels under them, each (today's on
      // its pill) centred on its point, and no y axis.
      xLabels.addAll(<TextPainter>[
        for (var i = 0; i < ticks.length; i++)
          _label(
            ticks[i].label,
            style: i == highlightTick ? highlightStyle : null,
          ),
      ]);
      final lineHeight = xLabels.isEmpty
          ? 0.0
          : xLabels.map((p) => p.height).reduce(math.max);
      xLabelTop = ExpressiveSpacing.s8;
      final pill = xLabels.isEmpty
          ? inset
          : xLabels.map((p) => p.width).reduce(math.max) / 2 +
                ExpressiveSpacing.s6;
      final side = math.max(inset, pill);
      plot = Rect.fromLTRB(
        side,
        inset,
        size.width - side,
        size.height - xLabelTop - lineHeight - ExpressiveSpacing.s2,
      );
    } else {
      yLabels.addAll(<TextPainter>[
        for (final v in gridValues) _label(axis.format(v)),
      ]);
      final gutter =
          yLabels.map((p) => p.width).reduce(math.max) + ExpressiveSpacing.s8;
      // Every y label centres on its line, the lowest too, so the axis
      // reads as evenly spaced as its values; the x labels sit below the
      // lowest one's lower half, clear of it.
      final lineHeight = yLabels.first.height;
      xLabelTop = lineHeight / 2 + ExpressiveSpacing.s4;
      final xBand = xLabelTop + lineHeight;
      xLabels.addAll(<TextPainter>[for (final t in ticks) _label(t.label)]);
      // Room at the end for the last label to centre under its point.
      final endRoom = xLabels.isEmpty
          ? inset
          : math.max(inset, xLabels.last.width / 2);
      plot = Rect.fromLTRB(
        gutter,
        math.max(inset, lineHeight / 2),
        size.width - endRoom,
        size.height - xBand,
      );
    }
    if (plot.width <= 0 || plot.height <= 0) return;
    final range = axis.max - axis.min;
    double y(double v) =>
        plot.bottom - (range <= 0 ? 0.5 : (v - axis.min) / range) * plot.height;
    double x(double at) =>
        span <= 0 ? plot.center.dx : plot.left + plot.width * at / span;

    if (band case (final low, final high)) {
      // On the small corner (8dp, or half the band when thinner):
      // the band is a shape on the plot, as Expressive draws a container.
      final rect = Rect.fromLTRB(plot.left, y(high), plot.right, y(low));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(math.min(_bandCorner, rect.shortestSide.abs() / 2)),
        ),
        Paint()..color = bandColor,
      );
    }

    if (target case final goal?) {
      final at = y(goal);
      final dot = Paint()..color = targetColor;
      for (var dx = plot.left; dx <= plot.right + 0.5; dx += _targetPitch) {
        canvas.drawCircle(Offset(dx, at), _targetDot, dot);
      }
    }

    if (plain) {
      for (var i = 0; i < xLabels.length; i++) {
        final label = xLabels[i];
        final centre = x(ticks[i].at);
        final top = plot.bottom + xLabelTop;
        if (i == highlightTick) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(centre, top + label.height / 2),
                width: label.width + ExpressiveSpacing.s8,
                height: label.height + ExpressiveSpacing.s2,
              ),
              const Radius.circular(ExpressiveSpacing.s4),
            ),
            Paint()..color = highlightFill,
          );
        }
        label.paint(canvas, Offset(centre - label.width / 2, top));
      }
    }

    // The stretch before the first point, said in words; the gridlines
    // part around them rather than a ground being painted under them, so
    // the chart sits on any container.
    Rect? note;
    TextPainter? notePainter;
    if (!sparkline && emptyLabel != null && firstX != null && firstX! > 0) {
      final right = x(firstX!);
      final room = right - plot.left - ExpressiveSpacing.s8;
      final label = room > ExpressiveSpacing.s40
          ? _label(emptyLabel!, maxWidth: room)
          : null;
      // At most two lines: a note broken word by word down a narrow
      // stretch reads as debris on the plot, so it gives way.
      if (label != null && label.computeLineMetrics().length <= 2) {
        notePainter = label;
        final at = Offset(
          plot.left + (right - plot.left - notePainter.width) / 2,
          plot.center.dy - notePainter.height / 2,
        );
        note = (at & notePainter.size).inflate(ExpressiveSpacing.s4);
      }
    }

    if (!sparkline && !plain) {
      final gridPaint = Paint()
        ..color = grid
        ..strokeWidth = ruleWidth;
      final centres = <double>[];
      canvas.save();
      if (note != null) {
        canvas.clipPath(
          Path()
            ..fillType = PathFillType.evenOdd
            ..addRect(Offset.zero & size)
            ..addRect(note),
        );
      }
      for (var i = 0; i < gridValues.length; i++) {
        final at = y(gridValues[i]);
        canvas.drawLine(
          Offset(plot.left, at),
          Offset(plot.right, at),
          gridPaint,
        );
      }
      canvas.restore();
      for (var i = 0; i < gridValues.length; i++) {
        final at = y(gridValues[i]);
        final label = yLabels[i];
        final top = at - label.height / 2;
        label.paint(
          canvas,
          Offset(plot.left - ExpressiveSpacing.s8 - label.width, top),
        );
        centres.add(top + label.height / 2);
      }
      // A measure's axis: its labels stand as evenly apart as its values,
      // or the axis reads as non-linear.
      assert(() {
        for (var i = 2; i < centres.length; i++) {
          final a = centres[i - 1] - centres[i - 2];
          final b = centres[i] - centres[i - 1];
          if ((a - b).abs() > 0.5) return false;
        }
        return true;
      }(), 'ExpressiveChart: the y labels are not evenly spaced ($centres).');
      notePainter?.paint(canvas, note!.deflate(ExpressiveSpacing.s4).topLeft);

      // The x labels: the kept ones, placed from the last back, so a label
      // pulled in from an edge never crowds its neighbour (the neighbour
      // gives way; the last never does).
      final kept = labels == ExpressiveChartLabels.sparse
          ? expressiveSparseTicks(ticks, <double>[
              for (final p in xLabels) p.width,
            ], scale: span <= 0 ? plot.width : plot.width / span)
          : <int>[for (var i = 0; i < ticks.length; i++) i];
      var limit = size.width + ExpressiveSpacing.s8;
      for (final i in kept.reversed) {
        final label = xLabels[i];
        final left = (x(ticks[i].at) - label.width / 2)
            .clamp(0.0, math.max(0.0, size.width - label.width))
            .toDouble();
        if (left + label.width > limit - ExpressiveSpacing.s8) continue;
        label.paint(canvas, Offset(left, plot.bottom + xLabelTop));
        limit = left;
      }
    }

    final most = lines.fold<int>(0, (n, line) => math.max(n, line.xs.length));
    final dots = most < 2 || plot.width / (most - 1) >= _pointsFrom;
    for (final line in lines) {
      if (line.xs.isEmpty) continue;
      final path = Path();
      for (var i = 0; i < line.xs.length; i++) {
        final p = Offset(x(line.xs[i]), y(line.ys[i]));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (area case final fill? when line.xs.length > 1) {
        canvas.drawPath(
          Path.from(path)
            ..lineTo(x(line.xs.last), y(axis.min))
            ..lineTo(x(line.xs.first), y(axis.min))
            ..close(),
          Paint()..color = fill,
        );
      }
      canvas.saveLayer(Offset.zero & size, Paint());
      if (line.tinted && !line.dashed) {
        // Each segment in the colour of the point it ends at.
        for (var i = 1; i < line.xs.length; i++) {
          _strokeSeries(
            canvas,
            Path()
              ..moveTo(x(line.xs[i - 1]), y(line.ys[i - 1]))
              ..lineTo(x(line.xs[i]), y(line.ys[i])),
            line.at(i),
            stroke,
            dashed: false,
          );
        }
      } else {
        _strokeSeries(canvas, path, line.color, stroke, dashed: line.dashed);
      }
      if (dots && !sparkline) {
        for (var i = 0; i < line.xs.length; i++) {
          _drawPoint(
            canvas,
            Offset(x(line.xs[i]), y(line.ys[i])),
            line.at(i),
            second: line.dashed,
            stroke: pointStroke,
          );
        }
      } else if (sparkline || highlight != null) {
        // A sparkline marks where it ends; a line its highlighted point.
        final i = sparkline ? line.xs.length - 1 : highlight!;
        if (i >= 0 && i < line.xs.length) {
          _drawPoint(
            canvas,
            Offset(x(line.xs[i]), y(line.ys[i])),
            line.at(i),
            second: line.dashed,
            stroke: pointStroke,
          );
        }
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ScaledChartPainter old) =>
      !listEquals(old.lines, lines) ||
      old.axis != axis ||
      old.span != span ||
      !listEquals(old.ticks, ticks) ||
      old.labels != labels ||
      old.emptyLabel != emptyLabel ||
      old.firstX != firstX ||
      old.band != band ||
      old.bandColor != bandColor ||
      old.target != target ||
      old.targetColor != targetColor ||
      old.highlightFill != highlightFill ||
      old.highlightStyle != highlightStyle ||
      old.area != area ||
      old.highlight != highlight ||
      old.highlightTick != highlightTick ||
      old.grid != grid ||
      old.ruleWidth != ruleWidth ||
      old.pointStroke != pointStroke ||
      old.labelStyle != labelStyle ||
      old.stroke != stroke ||
      old.textScaler != textScaler ||
      old.textDirection != textDirection;
}

/// A legend entry: the series' own mark beside its name.
class _LegendEntry extends StatelessWidget {
  const _LegendEntry({
    required this.label,
    required this.style,
    required this.mark,
  });

  final String label;
  final TextStyle style;
  final _Legend mark;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: ExpressiveSpacing.s6,
    children: <Widget>[
      CustomPaint(
        // Long enough for a dash either side of a point, so a solid line
        // reads solid and a dashed one dashed.
        size: const Size(ExpressiveSpacing.s36, ExpressiveSpacing.s12),
        painter: mark,
      ),
      Flexible(child: Text(label, style: style)),
    ],
  );
}

/// A legend's mark: the series' line and point (solid and filled, or
/// dashed with a diamond), or a band's swatch.
class _Legend extends CustomPainter {
  const _Legend({
    required this.color,
    required this.dashed,
    this.swatch = false,
    this.edge,
    this.edgeStroke = 0,
    this.pointStroke = ExpressiveSpacing.s2,
  });

  final Color color;
  final bool dashed;
  final bool swatch;

  /// A swatch's hairline edge, so a band's tint reads on the ground.
  final Color? edge;
  final double edgeStroke;
  final double pointStroke;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    if (swatch) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: mid, width: size.height, height: size.height),
          const Radius.circular(ExpressiveSpacing.s2),
        ),
        Paint()..color = color,
      );
      if (edge case final edge?) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: mid,
              width: size.height,
              height: size.height,
            ).deflate(edgeStroke == 0 ? 0.5 : edgeStroke / 2),
            const Radius.circular(ExpressiveSpacing.s2),
          ),
          Paint()
            ..color = edge
            ..strokeWidth = edgeStroke
            ..style = PaintingStyle.stroke,
        );
      }
      return;
    }
    canvas.saveLayer(Offset.zero & size, Paint());
    // A dashed legend line starts on a dash centred under its point.
    final start = dashed ? mid.dx - _dashOn / 2 - (_dashOn + _dashOff) : 0.0;
    _strokeSeries(
      canvas,
      Path()
        ..moveTo(start, mid.dy)
        ..lineTo(size.width, mid.dy),
      color,
      _seriesStroke,
      dashed: dashed,
    );
    _drawPoint(canvas, mid, color, second: dashed, stroke: pointStroke);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Legend old) =>
      old.color != color ||
      old.dashed != dashed ||
      old.swatch != swatch ||
      old.edge != edge ||
      old.edgeStroke != edgeStroke ||
      old.pointStroke != pointStroke;
}

// ---------------------------------------------------------------------------
// The chart stems: one class per chart a developer reaches for by name, each
// an [ExpressiveChart] of one kind (the one API across looks names them
// `<Prefix>LineChart`, `<Prefix>BarChart`, ...). They draw exactly what that
// kind draws.
// ---------------------------------------------------------------------------

/// A line of a measure over time on an axis scaled to its data (pulse
/// 64–78 reads 60–80 by 5): a `primary` stroke, the [highlight] point
/// marked, gridlines at round steps, no area (an axis off zero would make
/// an area read as a quantity from zero). The x labels thin out to fit
/// (`sparse`). An [ExpressiveChart.line] on [ExpressiveChartDomain.data].
///
/// ```dart
/// ExpressiveLineChart(points: pulse, semanticLabel: 'Pulse this week, 64 to 78 beats a minute')
/// ```
class ExpressiveLineChart extends StatelessWidget {
  /// A line through [points].
  const ExpressiveLineChart({
    required this.points,
    this.highlight,
    this.aspectRatio = 2,
    this.semanticLabel,
    this.domain = const ExpressiveChartDomain.data(),
    this.labels = ExpressiveChartLabels.sparse,
    this.span,
    this.ticks,
    this.emptyLabel,
    this.band,
    this.target,
    this.color,
    this.style,
    this.loading = false,
    super.key,
  });

  /// The values, in order.
  final List<ExpressiveChartPoint> points;

  /// The point marked (today), if any.
  final int? highlight;

  /// The plot's width over its height.
  final double aspectRatio;

  /// What a screen reader says; every label and value when null.
  final String? semanticLabel;

  /// The y axis: scaled to the data by default.
  final ExpressiveChartDomain domain;

  /// Which x labels show.
  final ExpressiveChartLabels labels;

  /// The time the x axis spans, for points with an `at`.
  final double? span;

  /// The x labels of a timed axis.
  final List<ExpressiveChartTick>? ticks;

  /// What the empty stretch before the first point says.
  final String? emptyLabel;

  /// A usual range under the line.
  final ExpressiveChartBand? band;

  /// A goal's dotted line.
  final ExpressiveChartTarget? target;

  /// The series' colour; `primary` when null.
  final Color? color;

  /// Overrides of the chart's theme.
  final ExpressiveComponentThemeData? style;

  /// Whether the plot is a skeleton while the data loads.
  final bool loading;

  @override
  Widget build(BuildContext context) => ExpressiveChart.line(
    points: points,
    highlight: highlight,
    aspectRatio: aspectRatio,
    semanticLabel: semanticLabel,
    domain: domain,
    labels: labels,
    span: span,
    ticks: ticks,
    emptyLabel: emptyLabel,
    band: band,
    target: target,
    color: color,
    style: style,
    loading: loading,
  );
}

/// A count over time as a line over a tonal area from zero: a `primary`
/// stroke over `primaryContainer`, the [highlight] point marked, every
/// label under its point; values spring to new heights. With [tooltip] a
/// pointer shows the point under it. An [ExpressiveChart.line] on
/// [ExpressiveChartDomain.zero].
///
/// ```dart
/// ExpressiveAreaChart(points: mood, highlight: 11, semanticLabel: 'Mood over two weeks')
/// ```
class ExpressiveAreaChart extends StatelessWidget {
  /// An area under [points].
  const ExpressiveAreaChart({
    required this.points,
    this.highlight,
    this.aspectRatio = 2,
    this.semanticLabel,
    this.target,
    this.style,
    this.loading = false,
    this.tooltip = false,
    super.key,
  });

  /// The values, in order.
  final List<ExpressiveChartPoint> points;

  /// The point marked (today), if any.
  final int? highlight;

  /// The plot's width over its height.
  final double aspectRatio;

  /// What a screen reader says; every label and value when null.
  final String? semanticLabel;

  /// A goal's dotted line.
  final ExpressiveChartTarget? target;

  /// Overrides of the chart's theme.
  final ExpressiveComponentThemeData? style;

  /// Whether the plot is a skeleton while the data loads.
  final bool loading;

  /// Whether a pointer shows the point under it.
  final bool tooltip;

  @override
  Widget build(BuildContext context) => ExpressiveChart.line(
    points: points,
    highlight: highlight,
    aspectRatio: aspectRatio,
    semanticLabel: semanticLabel,
    target: target,
    style: style,
    loading: loading,
    tooltip: tooltip,
  );
}

/// Counts as rounded bars, one per point: `outline` bars, the [highlight]
/// bar in `primary`, each label under its bar; an optional [target]
/// dotted across them; values spring to new heights. With [tooltip] a
/// pointer shows the bar under it. An [ExpressiveChart.bar].
///
/// ```dart
/// ExpressiveBarChart(points: week, highlight: 5, semanticLabel: 'Minutes read this week')
/// ```
class ExpressiveBarChart extends StatelessWidget {
  /// A bar for each of [points].
  const ExpressiveBarChart({
    required this.points,
    this.highlight,
    this.aspectRatio = 2,
    this.semanticLabel,
    this.target,
    this.style,
    this.loading = false,
    this.tooltip = false,
    super.key,
  });

  /// The values, in order.
  final List<ExpressiveChartPoint> points;

  /// The bar drawn in `primary` (today), if any.
  final int? highlight;

  /// The plot's width over its height.
  final double aspectRatio;

  /// What a screen reader says; every label and value when null.
  final String? semanticLabel;

  /// A goal's dotted line.
  final ExpressiveChartTarget? target;

  /// Overrides of the chart's theme.
  final ExpressiveComponentThemeData? style;

  /// Whether the plot is a skeleton while the data loads.
  final bool loading;

  /// Whether a pointer shows the bar under it.
  final bool tooltip;

  @override
  Widget build(BuildContext context) => ExpressiveChart.bar(
    points: points,
    highlight: highlight,
    aspectRatio: aspectRatio,
    semanticLabel: semanticLabel,
    target: target,
    style: style,
    loading: loading,
    tooltip: tooltip,
  );
}

/// Parts of a whole as a donut: each part an arc in its own colour
/// (`primary`, `tertiary`, `secondary`, `outline` in turn), 4dp apart, its
/// ends round, [centerValue] over [centerLabel] in the hole and a legend
/// of each part's value under it.
/// An [ExpressiveChart.donut].
///
/// ```dart
/// ExpressivePieChart(points: spend, centerValue: '2,420', centerLabel: 'Spent in March')
/// ```
class ExpressivePieChart extends StatelessWidget {
  /// A ring of [points].
  const ExpressivePieChart({
    required this.points,
    this.centerValue,
    this.centerLabel,
    this.aspectRatio = 1,
    this.semanticLabel,
    this.style,
    this.loading = false,
    super.key,
  });

  /// The parts, in order round the ring.
  final List<ExpressiveChartPoint> points;

  /// The total, in the hole.
  final String? centerValue;

  /// What the total is, under it.
  final String? centerLabel;

  /// The plot's width over its height.
  final double aspectRatio;

  /// What a screen reader says; every part and value when null.
  final String? semanticLabel;

  /// Overrides of the chart's theme.
  final ExpressiveComponentThemeData? style;

  /// Whether the plot is a skeleton while the data loads.
  final bool loading;

  @override
  Widget build(BuildContext context) => ExpressiveChart.donut(
    points: points,
    centerValue: centerValue,
    centerLabel: centerLabel,
    aspectRatio: aspectRatio,
    semanticLabel: semanticLabel,
    style: style,
    loading: loading,
  );
}

/// A trend at a glance, inline: a `primary` line on an axis scaled to its
/// data, with no labels, gridlines or baseline. Its row says what it is (a
/// screen reader hears the row, not the line). An [ExpressiveChart.line]
/// with [ExpressiveChartLabels.none].
///
/// ```dart
/// SizedBox(width: 88, height: 36, child: ExpressiveSparkline(points: pulse))
/// ```
class ExpressiveSparkline extends StatelessWidget {
  /// A trend through [points].
  const ExpressiveSparkline({
    required this.points,
    this.aspectRatio = 88 / 36,
    this.color,
    this.style,
    super.key,
  });

  /// The values, in order.
  final List<ExpressiveChartPoint> points;

  /// The line's width over its height.
  final double aspectRatio;

  /// The line's colour; `primary` when null.
  final Color? color;

  /// Overrides of the chart's theme.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) => ExpressiveChart.line(
    points: points,
    domain: const ExpressiveChartDomain.data(),
    labels: ExpressiveChartLabels.none,
    aspectRatio: aspectRatio,
    color: color,
    style: style,
  );
}
