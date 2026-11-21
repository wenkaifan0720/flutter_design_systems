import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/chart_look.dart';
import '../../internal/spring.dart';
import '../../theme.dart';

/// A named run of values, one for each of a chart's labels; a null is a
/// gap (no figure for that month).
@immutable
class CivicChartSeries {
  /// A series called [label].
  const CivicChartSeries(this.label, this.values);

  /// Its name, in the legend, the table and what a screen reader hears.
  final String label;

  /// Its values, in the order of the chart's labels.
  final List<double?> values;

  @override
  bool operator ==(Object other) =>
      other is CivicChartSeries &&
      other.label == label &&
      listEquals(other.values, values);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(values));
}

enum _Kind { line, area, bar }

/// A line for each series across the chart's [labels] (months, years):
/// numbers up the start, the labels along the foot, hairlines at the
/// numbers. Each series is told apart by more than its colour: its line's
/// dash and its points' mark (the first solid and round, the second dashed
/// and square, …), named in words in the legend over it.
///
/// A pointer over it, a finger along it or the arrow keys (it is one tab
/// stop, ringed in the focus yellow) pick a label and say its values in a
/// card. Under it "Show data table" folds out every figure as a table, for
/// anyone, and a screen reader's "Show data table" opens it too. A screen
/// reader hears [title], then the data in a sentence (lowest, highest),
/// then each point.
///
/// For one number a page leads with, [CivicKeyFigure]; a chart never holds
/// a figure the page does not say elsewhere.
///
/// Reads [CivicStyle]'s foreground (the axis words) and edge (the
/// hairlines): its `style:`, then [CivicThemeData.chartStyle]. The
/// series' colours, dashes and marks are the look's.
///
/// ```dart
/// CivicLineChart(
///   title: 'Permits issued each month',
///   labels: const ['Jan', 'Feb', 'Mar'],
///   series: const [
///     CivicChartSeries('Resident', [120, 135, 128]),
///     CivicChartSeries('Visitor', [80, 92, 110]),
///   ],
/// )
/// ```
class CivicLineChart extends StatelessWidget {
  /// A line chart.
  const CivicLineChart({
    super.key,
    required this.title,
    required this.labels,
    required this.series,
    this.summary,
    this.valueLabel,
    this.labelHeader,
    this.missingLabel,
    this.height = 240,
    this.focusNode,
    this.style,
  });

  /// Its name, over it and said first.
  final String title;

  /// What it shows, in a sentence under its name.
  final String? summary;

  /// The labels along its foot, in order: one for each value of a series.
  final List<String> labels;

  /// The series.
  final List<CivicChartSeries> series;

  /// A value in words ("€1,240"); null: the reader's numbers.
  final String Function(double value)? valueLabel;

  /// The table's first column's header ("Month"); null: none.
  final String? labelHeader;

  /// What a missing value (a null in a series) says, in its table cell
  /// and in the card, and on a bar chart in its bar's place: why it is
  /// missing ("No data yet"); null: "Empty" in the reader's language.
  final String? missingLabel;

  /// The chart's height at the reader's text size of 1.
  final double height;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this chart's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => _Cartesian(
    kind: _Kind.line,
    title: title,
    summary: summary,
    labels: labels,
    series: series,
    valueLabel: valueLabel,
    labelHeader: labelHeader,
    missingLabel: missingLabel,
    height: height,
    focusNode: focusNode,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _describe(
      properties,
      title,
      summary,
      labels,
      series,
      valueLabel,
      labelHeader,
      missingLabel,
      height,
      focusNode,
      style,
    );
  }
}

/// [CivicLineChart] with each line's area washed down to zero in its
/// colour: how much, more than where it went. Read, picked and tabled as
/// the line chart is.
///
/// Reads [CivicStyle]'s foreground (the axis words) and edge (the
/// hairlines): its `style:`, then [CivicThemeData.chartStyle].
///
/// ```dart
/// CivicAreaChart(
///   title: 'Applications waiting',
///   labels: const ['Mon', 'Tue', 'Wed'],
///   series: const [CivicChartSeries('Waiting', [42, 38, 51])],
/// )
/// ```
class CivicAreaChart extends StatelessWidget {
  /// An area chart.
  const CivicAreaChart({
    super.key,
    required this.title,
    required this.labels,
    required this.series,
    this.summary,
    this.valueLabel,
    this.labelHeader,
    this.missingLabel,
    this.height = 240,
    this.focusNode,
    this.style,
  });

  /// Its name, over it and said first.
  final String title;

  /// What it shows, in a sentence under its name.
  final String? summary;

  /// The labels along its foot, in order.
  final List<String> labels;

  /// The series.
  final List<CivicChartSeries> series;

  /// A value in words; null: the reader's numbers.
  final String Function(double value)? valueLabel;

  /// The table's first column's header; null: none.
  final String? labelHeader;

  /// What a missing value (a null in a series) says, in its table cell
  /// and in the card, and on a bar chart in its bar's place: why it is
  /// missing ("No data yet"); null: "Empty" in the reader's language.
  final String? missingLabel;

  /// The chart's height at the reader's text size of 1.
  final double height;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this chart's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => _Cartesian(
    kind: _Kind.area,
    title: title,
    summary: summary,
    labels: labels,
    series: series,
    valueLabel: valueLabel,
    labelHeader: labelHeader,
    missingLabel: missingLabel,
    height: height,
    focusNode: focusNode,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _describe(
      properties,
      title,
      summary,
      labels,
      series,
      valueLabel,
      labelHeader,
      missingLabel,
      height,
      focusNode,
      style,
    );
  }
}

/// Bars standing on zero for each of the chart's [labels], a bar for each
/// series side by side, each bar's value written over it. The series are
/// told apart by more than their colour: the first solid, the second
/// striped, …, named in the legend. Read, picked and tabled as
/// [CivicLineChart] is.
///
/// Reads [CivicStyle]'s foreground (the axis words) and edge (the
/// hairlines): its `style:`, then [CivicThemeData.chartStyle].
///
/// ```dart
/// CivicBarChart(
///   title: 'Fines paid by quarter',
///   labels: const ['Q1', 'Q2', 'Q3', 'Q4'],
///   series: const [CivicChartSeries('Fines paid', [310, 280, 355, 290])],
/// )
/// ```
class CivicBarChart extends StatelessWidget {
  /// A bar chart.
  const CivicBarChart({
    super.key,
    required this.title,
    required this.labels,
    required this.series,
    this.summary,
    this.valueLabel,
    this.labelHeader,
    this.missingLabel,
    this.height = 240,
    this.focusNode,
    this.style,
  });

  /// Its name, over it and said first.
  final String title;

  /// What it shows, in a sentence under its name.
  final String? summary;

  /// The labels along its foot, in order: one group of bars each.
  final List<String> labels;

  /// The series.
  final List<CivicChartSeries> series;

  /// A value in words; null: the reader's numbers.
  final String Function(double value)? valueLabel;

  /// The table's first column's header; null: none.
  final String? labelHeader;

  /// What a missing value (a null in a series) says, in its table cell
  /// and in the card, and on a bar chart in its bar's place: why it is
  /// missing ("No data yet"); null: "Empty" in the reader's language.
  final String? missingLabel;

  /// The chart's height at the reader's text size of 1.
  final double height;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// Overrides for this chart's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) => _Cartesian(
    kind: _Kind.bar,
    title: title,
    summary: summary,
    labels: labels,
    series: series,
    valueLabel: valueLabel,
    labelHeader: labelHeader,
    missingLabel: missingLabel,
    height: height,
    focusNode: focusNode,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    _describe(
      properties,
      title,
      summary,
      labels,
      series,
      valueLabel,
      labelHeader,
      missingLabel,
      height,
      focusNode,
      style,
    );
  }
}

void _describe(
  DiagnosticPropertiesBuilder properties,
  String title,
  String? summary,
  List<String> labels,
  List<CivicChartSeries> series,
  String Function(double value)? valueLabel,
  String? labelHeader,
  String? missingLabel,
  double height,
  FocusNode? focusNode,
  CivicStyle? style,
) {
  properties
    ..add(StringProperty('title', title))
    ..add(StringProperty('summary', summary, defaultValue: null))
    ..add(IterableProperty<String>('labels', labels))
    ..add(IntProperty('series', series.length))
    ..add(
      ObjectFlagProperty<String Function(double value)>.has(
        'valueLabel',
        valueLabel,
      ),
    )
    ..add(StringProperty('labelHeader', labelHeader, defaultValue: null))
    ..add(StringProperty('missingLabel', missingLabel, defaultValue: null))
    ..add(DoubleProperty('height', height, defaultValue: 240))
    ..add(
      DiagnosticsProperty<FocusNode>(
        'focusNode',
        focusNode,
        defaultValue: null,
      ),
    )
    ..add(DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null));
}

class _Cartesian extends StatelessWidget {
  const _Cartesian({
    required this.kind,
    required this.title,
    required this.summary,
    required this.labels,
    required this.series,
    required this.valueLabel,
    required this.labelHeader,
    required this.missingLabel,
    required this.height,
    required this.focusNode,
    required this.style,
  });

  final _Kind kind;
  final String title;
  final String? summary;
  final List<String> labels;
  final List<CivicChartSeries> series;
  final String Function(double value)? valueLabel;
  final String? labelHeader;
  final String? missingLabel;
  final double height;
  final FocusNode? focusNode;
  final CivicStyle? style;

  List<DesignChartSeries> get _data => [
    for (final s in series)
      DesignChartSeries(
        label: s.label,
        points: [
          for (final (i, v) in s.values.indexed)
            if (i < labels.length) DesignChartPoint(i.toDouble(), v),
        ],
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf([style, t.chartStyle], const {});
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final l = RawWidgetsLocalizations.of(context);
    String say(double v) => valueLabel?.call(v) ?? l.formatDecimal(v);
    final missing = missingLabel ?? l.emptyValueLabel;
    final small = text.bodySmall.copyWith(
      color: so.foreground ?? t.textSecondary,
      fontFeatures: const [ui.FontFeature.tabularFigures()],
    );
    final looks = [
      for (var i = 0; i < series.length; i++) CivicSeriesLook.of(t, i),
    ];
    // Room at the start for the widest number, at the foot for a line of
    // labels, over the bars for their values.
    final values = [
      for (final s in series)
        for (final v in s.values) ?v,
    ];
    final top = values.isEmpty ? 0.0 : values.reduce(math.max);
    final low = values.isEmpty ? 0.0 : values.reduce(math.min);
    var widest = 0.0;
    for (final v in {top * 1.25, low, 0.0}) {
      final p = civicChartWords(say(v), small, scaler, direction);
      widest = math.max(widest, p.width);
      p.dispose();
    }
    final line = scaler.scale(small.fontSize ?? 16) * (small.height ?? 1.3);
    final data = _data;
    Widget chart(VoidCallback showTable) => DesignChart(
      series: data,
      semanticLabel: title,
      xAxis: DesignChartXAxis.band,
      categories: labels,
      formatY: say,
      focusNode: focusNode,
      onShowTable: showTable,
      padding: EdgeInsetsDirectional.only(
        start: widest + CivicSpacing.s12,
        end: CivicSpacing.s8,
        top: kind == _Kind.bar ? line + CivicSpacing.s8 : CivicSpacing.s12,
        bottom: line + CivicSpacing.s12,
      ),
      builder: (context, chart) => CivicChartFocus(
        focused: chart.states.contains(WidgetState.focused),
        child: _Readout(
          chart: chart,
          painter: (shown, along, index) => _CartesianPainter(
            shown: shown,
            along: along,
            index: index,
            kind: kind,
            chart: chart,
            looks: looks,
            t: t,
            small: small,
            bold: text.label.copyWith(color: t.textPrimary),
            plain: text.bodySmall.copyWith(color: t.textPrimary),
            rule: so.edge ?? t.rule,
            scaler: scaler,
            direction: direction,
            say: say,
            missing: missing,
            labels: labels,
          ),
        ),
      ),
    );
    final tall = height * scaler.scale(1).clamp(1.0, 1.5);
    return CivicChartFrame(
      title: title,
      summary: summary,
      legend: series.length > 1
          ? CivicChartLegend(
              lines: kind != _Kind.bar,
              entries: [
                for (final (i, s) in series.indexed) (s.label, looks[i]),
              ],
            )
          : null,
      chart: (showTable) => SizedBox(height: tall, child: chart(showTable)),
      table: CivicChartTableView(
        label: title,
        headers: [labelHeader ?? '', for (final s in series) s.label],
        rows: [
          for (final (i, x) in labels.indexed)
            [
              x,
              for (final s in series)
                switch (i < s.values.length ? s.values[i] : null) {
                  final double v => say(v),
                  null => null,
                },
            ],
        ],
        missing: missing,
      ),
    );
  }
}

/// Paints a chart with its readout coming and going on the state spring
/// and moving from label to label on the focus spring.
class _Readout extends StatefulWidget {
  const _Readout({required this.chart, required this.painter});

  final DesignChartDetails chart;
  final CustomPainter Function(double shown, double along, int index) painter;

  @override
  State<_Readout> createState() => _ReadoutState();
}

class _ReadoutState extends State<_Readout> {
  // The label last picked, kept while the readout goes; and which showing
  // of it this is, so a new one starts at its label rather than gliding
  // from the last.
  var _last = 0;
  var _showing = 0;
  var _was = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.chart.active;
    if (active != null) {
      if (!_was) _showing++;
      _last = active.index;
    }
    _was = active != null;
    return CivicSpringValue(
      value: active == null ? 0 : 1,
      spring: CivicMotion.state,
      effects: true,
      builder: (context, shown, _) => CivicSpringValue(
        key: ValueKey(_showing),
        value: _last.toDouble(),
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, along, _) => CustomPaint(
          size: widget.chart.size,
          painter: widget.painter(shown.clamp(0.0, 1.0), along, _last),
        ),
      ),
    );
  }
}

class _CartesianPainter extends CustomPainter {
  _CartesianPainter({
    required this.shown,
    required this.along,
    required this.index,
    required this.kind,
    required this.chart,
    required this.looks,
    required this.t,
    required this.small,
    required this.bold,
    required this.plain,
    required this.rule,
    required this.scaler,
    required this.direction,
    required this.say,
    required this.missing,
    required this.labels,
  });

  /// How far the readout has come in, 0 to 1.
  final double shown;

  /// Where the readout stands, as a label's index (between two as it
  /// moves).
  final double along;

  /// The label it reads.
  final int index;
  final _Kind kind;
  final DesignChartDetails chart;
  final List<CivicSeriesLook> looks;
  final CivicThemeData t;
  final TextStyle small;
  final TextStyle bold;
  final TextStyle plain;
  final Color rule;
  final TextScaler scaler;
  final TextDirection direction;
  final String Function(double) say;
  final String missing;
  final List<String> labels;

  bool get _rtl => direction == TextDirection.rtl;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = chart.plotArea;
    final hair = Paint()
      ..color = rule
      ..strokeWidth = 1;
    // The numbers up the start, each on its hairline: every hairline, and
    // as many of the numbers, counted from the one nearest zero, as stand
    // clear of each other.
    final ticks = chart.yTicks.toList();
    final numbers = [
      for (final tick in ticks)
        civicChartWords(tick.label, small, scaler, direction),
    ];
    var apart = double.infinity;
    var nearest = 0;
    final zeroAt = chart.y.map(0);
    for (var i = 0; i < ticks.length; i++) {
      if (i > 0) {
        apart = math.min(
          apart,
          (ticks[i].position - ticks[i - 1].position).abs(),
        );
      }
      if ((ticks[i].position - zeroAt).abs() <
          (ticks[nearest].position - zeroAt).abs()) {
        nearest = i;
      }
    }
    final tallest = numbers.fold(0.0, (h, p) => math.max(h, p.height));
    final every = apart.isFinite && apart > 0
        ? math.max(1, ((tallest + CivicSpacing.s4) / apart).ceil())
        : 1;
    for (final (i, tick) in ticks.indexed) {
      final y = tick.position;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), hair);
      final p = numbers[i];
      if ((i - nearest) % every == 0) {
        final x = _rtl
            ? plot.right + CivicSpacing.s8
            : plot.left - CivicSpacing.s8 - p.width;
        p.paint(canvas, Offset(x, y - p.height / 2));
      }
      p.dispose();
    }
    // Zero, the line the bars and the areas stand on, in ink.
    final zero = chart.y.map(
      chart.y.min <= 0 && chart.y.max >= 0 ? 0 : chart.y.min,
    );
    canvas.drawLine(
      Offset(plot.left, zero),
      Offset(plot.right, zero),
      Paint()
        ..color = t.textPrimary
        ..strokeWidth = 1,
    );
    _labelsAlong(canvas, plot);
    if (kind == _Kind.bar) {
      _group(canvas, plot);
      _bars(canvas, zero);
    } else {
      _lines(canvas, zero);
    }
    _picked(canvas, size, plot);
  }

  // The labels along the foot, each under its place but kept within the
  // plot (clear of the numbers up the start), as many as stand clear of
  // each other.
  void _labelsAlong(Canvas canvas, Rect plot) {
    if (labels.isEmpty) return;
    final painters = [
      for (final words in labels)
        civicChartWords(words, small, scaler, direction),
    ];
    Rect place(int i) {
      final p = painters[i];
      final x = chart.x.map(i.toDouble());
      final left = (x - p.width / 2)
          .clamp(plot.left, math.max(plot.left, plot.right - p.width))
          .toDouble();
      return Rect.fromLTWH(
        left,
        plot.bottom + CivicSpacing.s8,
        p.width,
        p.height,
      );
    }

    bool clear(int every) {
      Rect? last;
      for (var i = 0; i < labels.length; i += every) {
        final at = place(i);
        if (last != null &&
            at.left < last.right + CivicSpacing.s8 &&
            at.right > last.left - CivicSpacing.s8) {
          return false;
        }
        last = at;
      }
      return true;
    }

    var every = 1;
    while (every < labels.length && !clear(every)) {
      every++;
    }
    for (var i = 0; i < labels.length; i += every) {
      painters[i].paint(canvas, place(i).topLeft);
    }
    for (final p in painters) {
      p.dispose();
    }
  }

  void _lines(Canvas canvas, double zero) {
    for (final (s, data) in chart.series.indexed) {
      final look = looks[s];
      final path = Path();
      final area = Path();
      var open = false;
      double? firstX;
      double? lastX;
      void closeArea() {
        if (firstX != null && lastX != null) {
          area
            ..lineTo(lastX!, zero)
            ..lineTo(firstX!, zero)
            ..close();
        }
        firstX = null;
        lastX = null;
      }

      for (final p in data.points) {
        final y = p.y;
        if (y == null) {
          open = false;
          closeArea();
          continue;
        }
        final at = Offset(chart.x.map(p.x), chart.y.map(y));
        if (!open) {
          path.moveTo(at.dx, at.dy);
          area.moveTo(at.dx, at.dy);
          firstX = at.dx;
          open = true;
        } else {
          path.lineTo(at.dx, at.dy);
          area.lineTo(at.dx, at.dy);
        }
        lastX = at.dx;
      }
      closeArea();
      if (kind == _Kind.area) {
        canvas.drawPath(
          area,
          Paint()..color = look.color.withValues(alpha: t.isDark ? 0.28 : 0.16),
        );
      }
      civicStrokeDashed(
        canvas,
        path,
        Paint()
          ..color = look.color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round,
        look.dash,
      );
      if (data.points.length <= 24) {
        for (final p in data.points) {
          final y = p.y;
          if (y == null) continue;
          civicMark(
            canvas,
            Offset(chart.x.map(p.x), chart.y.map(y)),
            4,
            look.mark,
            look.color,
            t.background,
          );
        }
      }
    }
  }

  double get _band {
    final step = labels.length > 1
        ? (chart.x.map(1) - chart.x.map(0)).abs()
        : chart.plotArea.width;
    return step * 0.7;
  }

  // The gap between a group's bars.
  double get _gap => chart.series.length > 1 ? 2.0 : 0.0;

  Rect _bar(int s, int i, double value, double zero) {
    final n = math.max(1, chart.series.length);
    final group = _band;
    final each = (group - _gap * (n - 1)) / n;
    final centre = chart.x.map(i.toDouble());
    final order = _rtl ? n - 1 - s : s;
    final left = centre - group / 2 + order * (each + _gap);
    final y = chart.y.map(value);
    return Rect.fromLTRB(
      left,
      math.min(y, zero),
      left + each,
      math.max(y, zero),
    );
  }

  // The room over a bar for its value: its own width and the gap to its
  // neighbours, less a space, so two values never meet; alone in its
  // group, most of the step to the next.
  double _room(Rect box) {
    if (chart.series.length > 1) return box.width + _gap - CivicSpacing.s4;
    final step = labels.length > 1
        ? (chart.x.map(1) - chart.x.map(0)).abs()
        : chart.plotArea.width;
    return step - CivicSpacing.s8;
  }

  void _bars(Canvas canvas, double zero) {
    final values = <(TextPainter, Rect, double)>[];
    var fit = true;
    for (final (s, data) in chart.series.indexed) {
      final look = looks[s];
      for (final (i, p) in data.points.indexed) {
        final y = p.y;
        if (y == null) {
          _missing(canvas, _bar(s, i, 0, zero), zero);
          continue;
        }
        final box = _bar(s, i, y, zero);
        civicFillHatched(
          canvas,
          Path()..addRect(box),
          look.color,
          look.hatch,
          t.background,
        );
        final w = civicChartWords(
          say(y),
          small.copyWith(color: t.textPrimary),
          scaler,
          direction,
        );
        if (w.width > _room(box)) fit = false;
        values.add((w, box, y));
      }
    }
    // The values over their bars, only where every one fits its place (a
    // chart with some values and not others reads as if those were
    // missing); the card and the table give them all.
    for (final (w, box, y) in values) {
      if (fit) {
        w.paint(
          canvas,
          Offset(
            box.center.dx - w.width / 2,
            (y >= 0 ? box.top : box.bottom) - w.height - CivicSpacing.s4,
          ),
        );
      }
      w.dispose();
    }
  }

  // A missing value leaves its bar's place empty but for [missing],
  // standing on the zero line in its place (a dash where a word of it is
  // wider than the place).
  void _missing(Canvas canvas, Rect place, double zero) {
    final style = small.copyWith(color: t.textSecondary);
    final room = _room(place);
    var words = TextPainter(
      text: TextSpan(text: missing, style: style),
      textDirection: direction,
      textScaler: scaler,
      textAlign: TextAlign.center,
    )..layout(maxWidth: math.max(0, room));
    if (words.minIntrinsicWidth > room ||
        words.height > zero - chart.plotArea.top - CivicSpacing.s4) {
      words.dispose();
      words = civicChartWords('–', style, scaler, direction);
    }
    words.paint(
      canvas,
      Offset(
        place.center.dx - words.width / 2,
        zero - words.height - CivicSpacing.s4,
      ),
    );
    words.dispose();
  }

  // The picked group of bars, in the action's tint behind them.
  void _group(Canvas canvas, Rect plot) {
    if (shown < 0.01) return;
    final x = chart.x.map(along);
    final half = _band / 2 + CivicSpacing.s8;
    canvas.drawRect(
      Rect.fromLTRB(x - half, plot.top, x + half, plot.bottom),
      Paint()..color = t.secondaryFill.withValues(alpha: shown),
    );
  }

  void _picked(Canvas canvas, Size size, Rect plot) {
    if (shown < 0.01) return;
    final x = chart.x.map(along);
    final fading = shown < 0.99;
    if (fading) {
      canvas.saveLayer(
        Offset.zero & size,
        Paint()..color = Color.fromRGBO(0, 0, 0, shown),
      );
    }
    // A line through the picked label; bars have their group's tint.
    if (kind != _Kind.bar) {
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = t.textPrimary
          ..strokeWidth = 1,
      );
    }
    // The card stands over the highest of the picked points.
    var anchorY = plot.bottom;
    final lines = <(String, CivicSeriesLook?)>[
      (index < labels.length ? labels[index] : '', null),
    ];
    for (final (s, data) in chart.series.indexed) {
      if (index >= data.points.length) continue;
      final y = data.points[index].y;
      lines.add(('${data.label}: ${y == null ? missing : say(y)}', looks[s]));
      if (y == null) continue;
      final at = kind == _Kind.bar
          ? _bar(s, index, y, chart.y.map(0)).topCenter
          : Offset(chart.x.map(index.toDouble()), chart.y.map(y));
      anchorY = math.min(anchorY, at.dy);
      if (kind != _Kind.bar) {
        civicMark(canvas, at, 6, looks[s].mark, looks[s].color, t.background);
      }
    }
    civicPaintReadout(
      canvas,
      t: t,
      lines: lines,
      anchor: Offset(x, anchorY),
      bounds: Offset.zero & size,
      bold: bold,
      plain: plain,
      scaler: scaler,
      direction: direction,
      touch: chart.activeBy == PointerDeviceKind.touch,
      reach: kind == _Kind.bar ? _band / 2 + CivicSpacing.s8 : 0,
    );
    if (fading) canvas.restore();
  }

  @override
  bool shouldRepaint(_CartesianPainter old) =>
      old.chart != chart ||
      old.shown != shown ||
      old.along != along ||
      old.index != index ||
      old.missing != missing ||
      old.t != t ||
      old.kind != kind ||
      old.scaler != scaler ||
      old.direction != direction ||
      !listEquals(old.labels, labels);
}

/// A trend in a line, without axes, beside a sentence: [values] in the
/// action colour across its width, the last marked, and after it the last
/// value in words ([valueLabel], or the reader's number). It stands beside
/// words that say what it is ([label], which a screen reader hears with
/// where the line starts and ends). For the figures themselves, a table or
/// a [CivicLineChart].
///
/// Reads [CivicStyle]'s foreground (the line) and textStyle (the value):
/// its `style:`, then [CivicThemeData.chartStyle].
///
/// ```dart
/// CivicSparkline(
///   label: 'Visitor permits this week',
///   values: const [12, 18, 15, 22, 19, 26, 31],
/// )
/// ```
class CivicSparkline extends StatelessWidget {
  /// A sparkline.
  const CivicSparkline({
    super.key,
    required this.label,
    required this.values,
    this.valueLabel,
    this.width = 96,
    this.height = 32,
    this.style,
  });

  /// What it shows, said with its first and last values.
  final String label;

  /// The values, in order.
  final List<double> values;

  /// The last value in words ("31 this week"); null: the reader's number.
  final String? valueLabel;

  /// The line's width.
  final double width;

  /// The line's height at the reader's text size of 1.
  final double height;

  /// Overrides for this sparkline's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final so = DesignStyleOf([style, t.chartStyle], const {});
    final l = RawWidgetsLocalizations.of(context);
    final last = values.isEmpty ? null : values.last;
    final words = valueLabel ?? (last == null ? '' : l.formatDecimal(last));
    final said = values.isEmpty
        ? label
        : '$label${l.listSeparator}'
              '${l.chartRangeLabel(l.formatDecimal(values.first), words)}';
    final tall =
        height * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    return Semantics(
      container: true,
      label: said,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CivicSpacing.s8,
        children: [
          CustomPaint(
            size: Size(width, tall),
            painter: _Spark(
              values: values,
              color: so.foreground ?? t.action,
              ground: t.background,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
          if (words.isNotEmpty)
            Flexible(
              child: Text(
                words,
                style: context.civicText.label
                    .copyWith(
                      color: t.textPrimary,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    )
                    .merge(so.textStyle),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(IterableProperty<double>('values', values))
      ..add(StringProperty('valueLabel', valueLabel, defaultValue: null))
      ..add(DoubleProperty('width', width, defaultValue: 96))
      ..add(DoubleProperty('height', height, defaultValue: 32))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _Spark extends CustomPainter {
  _Spark({
    required this.values,
    required this.color,
    required this.ground,
    required this.rtl,
  });

  final List<double> values;
  final Color color;
  final Color ground;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    const inset = 6.0;
    final low = values.reduce(math.min);
    final high = values.reduce(math.max);
    final span = high - low == 0 ? 1 : high - low;
    Offset at(int i) {
      final along = values.length == 1 ? 0.5 : i / (values.length - 1);
      final x = inset + along * (size.width - 2 * inset);
      final y =
          inset + (1 - (values[i] - low) / span) * (size.height - 2 * inset);
      return Offset(rtl ? size.width - x : x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
    civicMark(
      canvas,
      at(values.length - 1),
      3.5,
      CivicMarkShape.circle,
      color,
      ground,
    );
  }

  @override
  bool shouldRepaint(_Spark old) =>
      !listEquals(old.values, values) ||
      old.color != color ||
      old.ground != ground ||
      old.rtl != rtl;
}
