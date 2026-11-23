/// Appliance's charts, read as an energy monitor's display: traces on its
/// glass in a window sunk in the panel (dark inks on a pale LCD by day, lit
/// traces on smoked glass by night), the scale printed faint on the glass, the legend's lamps on the panel under it. [ApplianceLineChart],
/// [ApplianceAreaChart], [ApplianceBarChart], [ApplianceDonutChart] and the
/// small [ApplianceSparkline].
///
/// A chart takes the focus; the arrows move its readout from point to
/// point (the pointer does too), and a screen reader hears each reading.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'feedback.dart';
import 'internal/glyphs.dart';
import 'material.dart';
import 'theme.dart';

/// One series of a chart.
@immutable
class ApplianceChartSeries {
  /// A series named [label] of [values], one for each of the chart's
  /// labels.
  const ApplianceChartSeries(this.label, this.values, {this.color});

  /// Its name, in the legend and the readout.
  final String label;

  /// Its values, in the labels' order.
  final List<double> values;

  /// Its trace's light; null takes the next of the display's.
  final Color? color;
}

// Whether the display is a pale LCD (by day) rather than smoked glass.
bool _lcd(ApplianceColors c) => c.display.computeLuminance() > 0.4;

/// The display's traces, in order: the signal, then colours that stay apart
/// from it and from each other on the glass: inks at 3:1 and more on the
/// day's LCD, lights on the night's glass.
List<Color> _traces(ApplianceColors c) => _lcd(c)
    ? [
        c.signalInk,
        const Color(0xFF1D6A7A),
        c.onDisplay,
        c.ready,
        const Color(0xFF7B3F8F),
      ]
    : [
        c.signal,
        const Color(0xFF7FC8D8),
        c.onDisplay,
        c.ready,
        const Color(0xFFD9A6E8),
      ];

// The display's faint words (the scale, a caption): [night]'s strength on
// the glass, stronger on the LCD, where dark ink fades faster; 4.5:1 on both.
Color _faint(ApplianceColors c, double night) =>
    c.onDisplay.withValues(alpha: _lcd(c) ? math.max(night, 0.76) : night);

/// How the charts write a value with no words of the caller's: in the
/// reader's digits, at its scale's decimals on the axis and its own (up to
/// three) in the readout.
const DesignChartValueFormat _values = DesignChartValueFormat();

/// The window a chart stands in, and what it shows while loading or empty.
class _Window extends StatelessWidget {
  const _Window({
    required this.height,
    required this.child,
    required this.focused,
    required this.style,
  });

  final double height;
  final Widget child;
  final bool focused;
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final layered = DesignStyleOf([style, theme.chartStyle], const {});
    return SizedBox(
      height: height,
      child: ApplianceSurface(
        face: layered.on(
          ApplianceFace.well(
            c,
            fill: c.display,
          ).copyWith(focus: focused ? c.focus : c.focus.withValues(alpha: 0)),
        ),
        child: Padding(
          padding:
              layered.padding(Directionality.of(context)) ??
              const EdgeInsets.fromLTRB(
                ApplianceSpacing.medium,
                ApplianceSpacing.medium,
                ApplianceSpacing.medium,
                ApplianceSpacing.small,
              ),
          child: child,
        ),
      ),
    );
  }
}

/// What a window says while its chart loads or has nothing.
class _Idle extends StatelessWidget {
  const _Idle({required this.loading, required this.emptyLabel});

  final bool loading;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    return Center(
      child: loading
          ? const ApplianceProgressRing(semanticLabel: 'Loading')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The dashes are a reading, not words: they keep their
                // size as the text grows, so the words under them fit.
                ExcludeSemantics(
                  child: Text(
                    '- - -',
                    textScaler: TextScaler.noScaling,
                    style: theme.textTheme.display.copyWith(
                      color: c.onDisplay.withValues(alpha: 0.45),
                    ),
                  ),
                ),
                const SizedBox(height: ApplianceSpacing.tight),
                Text(
                  emptyLabel,
                  style: theme.textTheme.secondary.copyWith(
                    color: _faint(c, 0.7),
                  ),
                ),
              ],
            ),
    );
  }
}

/// The legend: a lamp lit in each series' light, and its name.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    return ExcludeSemantics(
      child: Wrap(
        spacing: ApplianceSpacing.regular,
        runSpacing: ApplianceSpacing.tight,
        children: [
          for (final (label, color) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ApplianceLamp(lit: true, color: color, size: 8),
                const SizedBox(width: ApplianceSpacing.small),
                Text(
                  label,
                  style: theme.textTheme.secondary.copyWith(
                    color: theme.colors.printMuted,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// How a [_SeriesChart] draws its series.
enum _Mark { line, area, bar }

/// A chart of series over labels, with its readout.
class _SeriesChart extends StatefulWidget {
  const _SeriesChart({
    required this.mark,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    required this.height,
    required this.valueText,
    required this.loading,
    required this.emptyLabel,
    required this.style,
  });

  final _Mark mark;
  final List<String> labels;
  final List<ApplianceChartSeries> series;
  final String semanticLabel;
  final double height;
  final String Function(double value)? valueText;
  final bool loading;
  final String emptyLabel;
  final ApplianceStyle? style;

  @override
  State<_SeriesChart> createState() => _SeriesChartState();
}

class _SeriesChartState extends State<_SeriesChart> {
  final FocusNode _focus = FocusNode(debugLabel: 'ApplianceChart');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _text(double v) =>
      widget.valueText?.call(v) ??
      _values.format(v, RawWidgetsLocalizations.of(context));

  int get _count => widget.labels.length;

  bool get _empty =>
      _count == 0 ||
      widget.series.isEmpty ||
      widget.series.every((s) => s.values.isEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final traces = _traces(c);
    final colours = [
      for (final (i, s) in widget.series.indexed)
        s.color ?? traces[i % traces.length],
    ];
    if (widget.loading || _empty) {
      // Nothing to pick: the window says why.
      return Semantics(
        container: true,
        label: widget.loading
            ? widget.semanticLabel
            : '${widget.semanticLabel}, ${widget.emptyLabel}',
        child: _Window(
          height: widget.height,
          focused: false,
          style: widget.style,
          child: ExcludeSemantics(
            excluding: !widget.loading,
            child: _Idle(
              loading: widget.loading,
              emptyLabel: widget.emptyLabel,
            ),
          ),
        ),
      );
    }
    final scale = MediaQuery.textScalerOf(context);
    final axisStyle = theme.textTheme.legend.copyWith(color: _faint(c, 0.6));
    final line = applianceLabelSize(context, '0', axisStyle).height;
    final factor = scale.scale(axisStyle.fontSize!) / axisStyle.fontSize!;
    final foot = math.max(18.0, line + 2);
    final labelSpacing = widget.labels.fold<double>(
      44 * factor,
      (width, label) => math.max(
        width,
        applianceLabelSize(context, label, axisStyle).width + 8,
      ),
    );
    final chart = DesignChart(
      semanticLabel: widget.semanticLabel,
      series: [
        for (final s in widget.series)
          DesignChartSeries(
            label: s.label,
            points: [
              for (final (i, v) in s.values.take(_count).indexed)
                DesignChartPoint(i.toDouble(), v),
            ],
          ),
      ],
      xAxis: widget.mark == _Mark.bar
          ? DesignChartXAxis.band
          : DesignChartXAxis.linear,
      categories: widget.labels,
      formatX: (x) {
        final i = x.round();
        return i >= 0 && i < _count ? widget.labels[i] : '';
      },
      formatY: widget.valueText,
      valueFormat: _values,
      tickCount: 4,
      // The scale's figures at the start, as wide as the widest of them
      // needs; the labels at the foot.
      yLabelGutter: (ticks) => math.max(
        34 * factor,
        DesignScaleTick.widestLabel(
              ticks,
              style: axisStyle,
              textScaler: scale,
              textDirection: Directionality.of(context),
            ) +
            8,
      ),
      padding: EdgeInsetsDirectional.only(
        top: 4 + (line - 16).clamp(0.0, double.infinity) / 2,
        bottom: foot,
      ),
      focusNode: _focus,
      builder: (context, chart) {
        final at = chart.active?.index;
        return Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: _SeriesPainter(
                  mark: widget.mark,
                  chart: chart,
                  colours: colours,
                  grid: c.onDisplay.withValues(alpha: 0.14),
                  scale: axisStyle,
                  textScaler: scale,
                  direction: Directionality.of(context),
                  labelSpacing: labelSpacing,
                  labels: widget.labels,
                  foot: foot,
                  glass: c.display,
                ),
              ),
            ),
            if (at != null && at < _count)
              // The readout stands on the far side from its point, so the
              // point and its neighbours show.
              _farFrom(
                chart,
                at,
                _Readout(
                  title: widget.labels[at],
                  lines: [
                    for (final (i, s) in widget.series.indexed)
                      if (at < s.values.length)
                        (s.label, _text(s.values[at]), colours[i]),
                  ],
                ),
              ),
          ],
        );
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListenableBuilder(
          listenable: _focus,
          builder: (context, child) => _Window(
            height: widget.height,
            focused: _focus.hasFocus,
            style: widget.style,
            child: child!,
          ),
          child: chart,
        ),
        if (widget.series.length > 1) ...[
          const SizedBox(height: ApplianceSpacing.small),
          ExcludeSemantics(
            child: _Legend(
              entries: [
                for (final (i, s) in widget.series.indexed)
                  (s.label, colours[i]),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// [child] (the readout) at the top of [chart]'s plot, on the far side from
/// point [at]: past the plot's middle it stands at the plot's left, else at
/// its right.
Widget _farFrom(DesignChartDetails chart, int at, Widget child) {
  final plot = chart.plotArea;
  final left = chart.x.map(at.toDouble()) > plot.center.dx;
  return Positioned(
    top: 0,
    left: left ? plot.left : null,
    right: left ? null : chart.size.width - plot.right,
    child: child,
  );
}

/// The readout: the point's label and each series' value, lit on a small
/// pane of the glass.
class _Readout extends StatelessWidget {
  const _Readout({required this.title, required this.lines});

  final String title;
  final List<(String, String, Color)> lines;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: ApplianceSpacing.small,
        vertical: ApplianceSpacing.tight,
      ),
      decoration: BoxDecoration(
        color: Color.lerp(c.display, c.onDisplay, 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: c.onDisplay.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: t.legend.copyWith(color: _faint(c, 0.7))),
          for (final (label, value, color) in lines)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: ApplianceSpacing.tight),
                Text(
                  lines.length > 1 ? '$label  $value' : value,
                  style: t.secondary.copyWith(
                    color: c.onDisplay,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SeriesPainter extends CustomPainter {
  _SeriesPainter({
    required this.mark,
    required this.chart,
    required this.colours,
    required this.grid,
    required this.scale,
    required this.textScaler,
    required this.direction,
    required this.labelSpacing,
    required this.labels,
    required this.foot,
    required this.glass,
  });

  final _Mark mark;

  // ui_core's plot, scales, ticks, the values as drawn and the pick.
  final DesignChartDetails chart;
  final List<Color> colours;
  final Color grid;
  final TextStyle scale;
  final TextScaler textScaler;
  final TextDirection direction;
  final double labelSpacing;
  final List<String> labels;
  final double foot;
  final Color glass;

  // [within]: the width the words keep inside (a label at the plot's end
  // stays on the glass rather than running off its edge).
  void _text(
    Canvas canvas,
    String s,
    Offset at, {
    double align = 0,
    double? within,
  }) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: scale),
      textDirection: direction,
      textScaler: textScaler,
    )..layout();
    var left = at.dx - tp.width * align;
    if (within != null) {
      left = left.clamp(0.0, math.max(0.0, within - tp.width));
    }
    tp
      ..paint(canvas, Offset(left, at.dy - tp.height / 2))
      ..dispose();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = chart.plotArea;
    final rtl = chart.x.end < chart.x.start;
    final count = labels.length;
    final series = [
      for (final s in chart.series) [for (final p in s.points) p.y ?? 0.0],
    ];
    double y(double v) => chart.y.map(v);
    double x(int i) => chart.x.map(i.toDouble());

    // The scale: faint rules across the glass, their figures at the side.
    final rule = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final tick in chart.yTicks) {
      final yy = tick.position;
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), rule);
      _text(
        canvas,
        tick.label,
        Offset(rtl ? plot.right + 6 : plot.left - 6, yy),
        align: rtl ? 0 : 1,
      );
    }
    // The labels under it: every one that fits.
    final every = math.max(
      1,
      (count * labelSpacing / math.max(plot.width, 1)).ceil(),
    );
    for (var i = 0; i < count; i += every) {
      _text(
        canvas,
        labels[i],
        Offset(x(i), size.height - foot / 2 + 2),
        align: 0.5,
        within: size.width,
      );
    }
    // The cursor at the readout's point.
    final cursor = chart.active?.index;
    if (cursor != null && cursor < count) {
      canvas.drawLine(
        Offset(x(cursor), plot.top),
        Offset(x(cursor), plot.bottom),
        Paint()
          ..color = grid.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }
    if (mark == _Mark.bar) {
      final n = series.length;
      final band = (chart.x as DesignBandScale).step.abs();
      final gap = band * 0.24;
      final w = (band - gap) / n;
      for (final (si, values) in series.indexed) {
        for (var i = 0; i < math.min(count, values.length); i++) {
          final left = rtl
              ? x(i) + band / 2 - gap / 2 - w * (si + 1)
              : x(i) - band / 2 + gap / 2 + w * si;
          final rect = Rect.fromLTRB(
            left + 0.5,
            y(values[i]),
            left + w - 0.5,
            plot.bottom,
          );
          final lit = cursor == null || cursor == i;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: const Radius.circular(2),
              topRight: const Radius.circular(2),
            ),
            Paint()..color = colours[si].withValues(alpha: lit ? 0.95 : 0.45),
          );
        }
      }
      return;
    }
    for (final (si, values) in series.indexed) {
      final n = math.min(count, values.length);
      if (n == 0) continue;
      final path = Path()..moveTo(x(0), y(values[0]));
      for (var i = 1; i < n; i++) {
        path.lineTo(x(i), y(values[i]));
      }
      if (mark == _Mark.area) {
        final fill = Path.from(path)
          ..lineTo(x(n - 1), plot.bottom)
          ..lineTo(x(0), plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                colours[si].withValues(alpha: 0.38),
                colours[si].withValues(alpha: 0.04),
              ],
            ).createShader(plot),
        );
      }
      // A soft glow under the trace, then the trace.
      canvas
        ..drawPath(
          path,
          Paint()
            ..color = colours[si].withValues(alpha: 0.25)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        )
        ..drawPath(
          path,
          Paint()
            ..color = colours[si]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round,
        );
      if (cursor != null && cursor < n) {
        final p = Offset(x(cursor), y(values[cursor]));
        canvas
          ..drawCircle(p, 4.5, Paint()..color = glass)
          ..drawCircle(p, 3.5, Paint()..color = colours[si]);
      }
    }
  }

  @override
  bool shouldRepaint(_SeriesPainter old) => true;
}

/// A line chart: each series a lit trace across the display's glass, the
/// scale printed faint behind it, the legend's lamps under the window.
///
/// ```dart
/// ApplianceLineChart(semanticLabel: 'Spending by month', labels: const ['Jun', 'Jul', 'Aug'], series: const [ApplianceChartSeries('Spent', [42, 58, 51])])
/// ```
class ApplianceLineChart extends StatelessWidget {
  /// A line chart of [series] over [labels].
  const ApplianceLineChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel = 'No readings yet',
    this.style,
  });

  /// The points' labels, in order.
  final List<String> labels;

  /// The series.
  final List<ApplianceChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The window's height.
  final double height;

  /// A value in words ("£42"); the figure otherwise.
  final String Function(double value)? valueText;

  /// Whether its readings are still coming: the ring turns in the window.
  final bool loading;

  /// What the window says when there are no readings.
  final String emptyLabel;

  /// The window's style, over [ApplianceThemeData.chartStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => _SeriesChart(
    mark: _Mark.line,
    labels: labels,
    series: series,
    semanticLabel: semanticLabel,
    height: height,
    valueText: valueText,
    loading: loading,
    emptyLabel: emptyLabel,
    style: style,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('series', series.length));
  }
}

/// An area chart: the line chart's traces with the glass under each lit
/// faintly in its light.
///
/// ```dart
/// ApplianceAreaChart(semanticLabel: 'Orders by week', labels: const ['W1', 'W2', 'W3'], series: const [ApplianceChartSeries('Orders', [12, 18, 15])])
/// ```
class ApplianceAreaChart extends StatelessWidget {
  /// An area chart of [series] over [labels].
  const ApplianceAreaChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel = 'No readings yet',
    this.style,
  });

  /// The points' labels, in order.
  final List<String> labels;

  /// The series.
  final List<ApplianceChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The window's height.
  final double height;

  /// A value in words; the figure otherwise.
  final String Function(double value)? valueText;

  /// Whether its readings are still coming.
  final bool loading;

  /// What the window says when there are no readings.
  final String emptyLabel;

  /// The window's style, over [ApplianceThemeData.chartStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => _SeriesChart(
    mark: _Mark.area,
    labels: labels,
    series: series,
    semanticLabel: semanticLabel,
    height: height,
    valueText: valueText,
    loading: loading,
    emptyLabel: emptyLabel,
    style: style,
  );
}

/// A bar chart: a lit bar for each series at each label, grouped; the
/// readout's group stays bright while the rest dim.
///
/// ```dart
/// ApplianceBarChart(semanticLabel: 'Items by room', labels: const ['Kitchen', 'Hall'], series: const [ApplianceChartSeries('Items', [14, 6])])
/// ```
class ApplianceBarChart extends StatelessWidget {
  /// A bar chart of [series] over [labels].
  const ApplianceBarChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel = 'No readings yet',
    this.style,
  });

  /// The groups' labels, in order.
  final List<String> labels;

  /// The series.
  final List<ApplianceChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The window's height.
  final double height;

  /// A value in words; the figure otherwise.
  final String Function(double value)? valueText;

  /// Whether its readings are still coming.
  final bool loading;

  /// What the window says when there are no readings.
  final String emptyLabel;

  /// The window's style, over [ApplianceThemeData.chartStyle].
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) => _SeriesChart(
    mark: _Mark.bar,
    labels: labels,
    series: series,
    semanticLabel: semanticLabel,
    height: height,
    valueText: valueText,
    loading: loading,
    emptyLabel: emptyLabel,
    style: style,
  );
}

/// A donut chart: a ring of lit arcs on the glass, a share for each slice;
/// the readout's slice stands out and its share is lit in the ring's
/// middle. The legend beside it gives each share.
///
/// ```dart
/// ApplianceDonutChart(semanticLabel: 'Spending by room', slices: const [('Kitchen', 120), ('Hall', 40)])
/// ```
class ApplianceDonutChart extends StatefulWidget {
  /// A donut of [slices].
  const ApplianceDonutChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.size = 168,
    this.valueText,
    this.loading = false,
    this.emptyLabel = 'No readings yet',
    this.style,
  });

  /// Each slice's name and value.
  final List<(String label, double value)> slices;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The window's side.
  final double size;

  /// A value in words; the figure otherwise.
  final String Function(double value)? valueText;

  /// Whether its readings are still coming.
  final bool loading;

  /// What the window says when there are none.
  final String emptyLabel;

  /// The window's style, over [ApplianceThemeData.chartStyle].
  final ApplianceStyle? style;

  @override
  State<ApplianceDonutChart> createState() => _ApplianceDonutChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('slices', slices.length));
  }
}

class _ApplianceDonutChartState extends State<ApplianceDonutChart> {
  final FocusNode _focus = FocusNode(debugLabel: 'ApplianceDonutChart');
  // The slice picked, for the legend.
  int? _at;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _total =>
      widget.slices.fold<double>(0, (sum, s) => sum + math.max(0.0, s.$2));

  String _share(double v) =>
      RawWidgetsLocalizations.of(context)
          .formatPercent(_total <= 0 ? 0 : v / _total);

  String _text(double v) =>
      widget.valueText?.call(v) ??
      _values.format(v, RawWidgetsLocalizations.of(context));

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final traces = _traces(c);
    final empty = widget.slices.isEmpty || _total <= 0;
    final at = empty ? null : _at;
    final colours = [
      for (var i = 0; i < widget.slices.length; i++) traces[i % traces.length],
    ];
    final Widget ring;
    if (widget.loading || empty) {
      // Nothing to pick: the window says why.
      ring = Semantics(
        container: true,
        label: widget.loading
            ? widget.semanticLabel
            : '${widget.semanticLabel}, ${widget.emptyLabel}',
        child: ExcludeSemantics(
          excluding: !widget.loading,
          child: _Idle(loading: widget.loading, emptyLabel: widget.emptyLabel),
        ),
      );
    } else {
      ring = DesignPieChart(
        semanticLabel: widget.semanticLabel,
        slices: [
          for (final (label, value) in widget.slices)
            DesignPieSlice(label: label, value: math.max(0.0, value)),
        ],
        holeRadius: 0.5,
        formatValue: _text,
        focusNode: _focus,
        onActiveSliceChanged: (i) => setState(() => _at = i),
        builder: (context, pie) {
          final a = pie.active;
          return CustomPaint(
            painter: _DonutPainter(
              pie: pie,
              colours: colours,
              slot: c.onDisplay.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    a == null ? _text(_total) : _share(widget.slices[a].$2),
                    style: t.figure.copyWith(color: c.onDisplay),
                  ),
                  Text(
                    a == null ? 'Total' : widget.slices[a].$1,
                    style: t.legend.copyWith(color: _faint(c, 0.65)),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
    return Wrap(
      spacing: ApplianceSpacing.large,
      runSpacing: ApplianceSpacing.regular,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          child: ListenableBuilder(
            listenable: _focus,
            builder: (context, child) => _Window(
              height: widget.size,
              focused: _focus.hasFocus,
              style: widget.style,
              child: child!,
            ),
            child: ring,
          ),
        ),
        if (!empty)
          ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (label, value)) in widget.slices.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: ApplianceSpacing.tight,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ApplianceLamp(lit: true, color: colours[i], size: 8),
                        const SizedBox(width: ApplianceSpacing.small),
                        Text(
                          label,
                          style: t.secondary.copyWith(
                            color: c.print,
                            fontWeight: at == i ? FontWeight.w600 : null,
                          ),
                        ),
                        const SizedBox(width: ApplianceSpacing.small),
                        Text(
                          '${_text(value)} · ${_share(value)}',
                          style: t.secondary.copyWith(
                            color: c.printMuted,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.pie, required this.colours, required this.slot});

  // ui_core's centre, radius, angles (counter-clockwise right to left) and
  // the pick.
  final DesignPieChartDetails pie;
  final List<Color> colours;
  final Color slot;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 18.0;
    final rect = Rect.fromCircle(
      center: pie.centre,
      radius: pie.radius - width / 2 - 2,
    );
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..color = slot
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    final at = pie.active;
    for (final (i, s) in pie.slices.indexed) {
      // A hair's gap at each end of a slice.
      final sign = s.sweepAngle.isNegative ? -1.0 : 1.0;
      final sweep = math.max(0.0, s.sweepAngle.abs() - 0.04);
      if (sweep == 0) continue;
      final lit = at == null || at == i;
      canvas.drawArc(
        at == i ? rect.inflate(2) : rect,
        s.startAngle + 0.02 * sign,
        sweep * sign,
        false,
        Paint()
          ..color = colours[i].withValues(alpha: lit ? 0.95 : 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = at == i ? width + 4 : width,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// A sparkline: a small trace printed on the panel, its last reading a lit
/// lamp; for a figure's trend in a row.
///
/// ```dart
/// const ApplianceSparkline(values: [3, 5, 4, 7, 6, 9], semanticLabel: 'Orders this week, rising')
/// ```
class ApplianceSparkline extends StatelessWidget {
  /// A trace of [values].
  const ApplianceSparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.width = 72,
    this.height = 24,
    this.style,
  });

  /// The readings, oldest first.
  final List<double> values;

  /// What it shows (and which way it goes), for a screen reader.
  final String semanticLabel;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// Its style, over [ApplianceThemeData.chartStyle]: foreground (the trace).
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).chartStyle,
    ], const {});
    final c = ApplianceTheme.of(context).colors;
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SparkPainter(
              values: values,
              line: look.foreground ?? c.printMuted,
              lamp: c.signal,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IterableProperty<double>('values', values));
  }
}

class _SparkPainter extends CustomPainter {
  _SparkPainter({
    required this.values,
    required this.line,
    required this.lamp,
    required this.rtl,
  });

  final List<double> values;
  final Color line;
  final Color lamp;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    final n = values.length;
    Offset p(int i) {
      final f = n == 1 ? 1.0 : i / (n - 1);
      final x = 3 + (size.width - 6) * (rtl ? 1 - f : f);
      final y = 3 + (size.height - 6) * (1 - (values[i] - lo) / span);
      return Offset(x, y);
    }

    final path = Path()..moveTo(p(0).dx, p(0).dy);
    for (var i = 1; i < n; i++) {
      path.lineTo(p(i).dx, p(i).dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      )
      ..drawCircle(p(n - 1), 3, Paint()..color = lamp);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) || old.line != line || old.rtl != rtl;
}
