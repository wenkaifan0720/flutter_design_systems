/// Keycap's charts: figures to read, so each sits sunk in a well (the
/// sunk-is-read rule), its marks printed in the case's inks, the scale
/// printed faint behind them. A point picked by pointer or arrow keys gets a
/// small readout laid over the well as a flat panel.
///
/// [KeycapLineChart], [KeycapAreaChart], [KeycapBarChart] over
/// [KeycapChartSeries]; [KeycapDonutChart] over labelled shares;
/// [KeycapSparkline] for a figure's trend in a row.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'cap.dart';
import 'feedback.dart';
import 'theme.dart';

/// One series of a chart: its [label] and a value per label of the chart.
@immutable
class KeycapChartSeries {
  /// A series reading [label].
  const KeycapChartSeries(this.label, this.values, {this.color});

  /// Its name, for the legend and a screen reader.
  final String label;

  /// Its values, one per label of the chart.
  final List<double> values;

  /// Its ink; the case's next series ink when null.
  final Color? color;

  @override
  bool operator ==(Object other) =>
      other is KeycapChartSeries &&
      other.label == label &&
      listEquals(other.values, values) &&
      other.color == color;

  @override
  int get hashCode => Object.hash(label, Object.hashAll(values), color);
}

/// The series inks in order: the accent ink, then inks that stay apart from
/// it and each other, each 3:1 and more on the well.
List<Color> _inks(KeycapColors c) => c.brightness == Brightness.light
    ? [
        c.accentInk,
        const Color(0xFF0F5C66),
        const Color(0xFF6A2C7C),
        const Color(0xFF7A4A0C),
        c.inkMuted,
      ]
    : [
        c.accentInk,
        const Color(0xFF6CC8C6),
        const Color(0xFFD6A4E6),
        const Color(0xFFE2B465),
        c.inkMuted,
      ];

/// A figure with no needless decimals.
String _plain(double v) {
  if (v == v.roundToDouble()) return v.toInt().toString();
  return v.toStringAsFixed(v.abs() < 10 ? 1 : 0);
}

/// The size [s] takes in [style] at the reader's text size.
Size _measure(BuildContext context, String s, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: s, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final size = tp.size;
  tp.dispose();
  return size;
}

/// The scale's small figures.
TextStyle _scaleStyle(KeycapThemeData theme) => theme.textTheme.figure.copyWith(
  fontSize: 12,
  height: 16 / 12,
  color: theme.colors.inkMuted,
);

/// The well a chart sits in; its rim lights when the chart has focus.
class _Well extends StatelessWidget {
  const _Well({
    required this.height,
    required this.child,
    required this.focused,
    required this.style,
  });

  final double height;
  final Widget child;
  final bool focused;
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final layered = DesignStyleOf([style, theme.chartStyle], const {});
    return SizedBox(
      height: height,
      child: KeycapWell(
        floor: layered.fill,
        rim: focused ? theme.colors.focus : null,
        padding:
            layered.padding(Directionality.of(context)) ??
            const EdgeInsets.fromLTRB(
              KeycapSpacing.medium,
              KeycapSpacing.medium,
              KeycapSpacing.medium,
              KeycapSpacing.small,
            ),
        child: child,
      ),
    );
  }
}

/// What a well says while its chart loads or has nothing to show.
class _Idle extends StatelessWidget {
  const _Idle({required this.loading, required this.emptyLabel});

  final bool loading;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return Center(
      child: loading
          ? KeycapSpinner(
              semanticLabel: DesignLocalizations.of(context).loadingLabel,
            )
          : Text(
              emptyLabel,
              textAlign: TextAlign.center,
              style: theme.textTheme.secondary,
            ),
    );
  }
}

/// A square of each series' ink and its name.
class _Legend extends StatelessWidget {
  const _Legend({required this.entries});

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    return ExcludeSemantics(
      child: Wrap(
        spacing: KeycapSpacing.regular,
        runSpacing: KeycapSpacing.tight,
        children: [
          for (final (label, color) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                  child: const SizedBox.square(dimension: 10),
                ),
                const SizedBox(width: KeycapSpacing.small),
                Text(label, style: theme.textTheme.secondary),
              ],
            ),
        ],
      ),
    );
  }
}

enum _Mark { line, area, bar }

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
  final List<KeycapChartSeries> series;
  final String semanticLabel;
  final double height;
  final String Function(double value)? valueText;
  final bool loading;
  final String? emptyLabel;
  final KeycapStyle? style;

  @override
  State<_SeriesChart> createState() => _SeriesChartState();
}

class _SeriesChartState extends State<_SeriesChart> {
  final FocusNode _focus = FocusNode(debugLabel: 'KeycapChart');

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  String _text(double v) => widget.valueText?.call(v) ?? _plain(v);

  int get _count => widget.labels.length;

  bool get _empty =>
      _count == 0 ||
      widget.series.isEmpty ||
      widget.series.every((s) => s.values.isEmpty);

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final inks = _inks(c);
    final colours = [
      for (final (i, s) in widget.series.indexed)
        s.color ?? inks[i % inks.length],
    ];
    final emptyLabel = widget.emptyLabel ?? words.noResultsLabel;
    if (widget.loading || _empty) {
      return Semantics(
        container: true,
        label: widget.loading
            ? widget.semanticLabel
            : '${widget.semanticLabel}, $emptyLabel',
        child: _Well(
          height: widget.height,
          focused: false,
          style: widget.style,
          child: ExcludeSemantics(
            excluding: !widget.loading,
            child: _Idle(loading: widget.loading, emptyLabel: emptyLabel),
          ),
        ),
      );
    }
    final scaler = MediaQuery.textScalerOf(context);
    final axis = _scaleStyle(theme);
    final line = _measure(context, '0', axis).height;
    final factor = scaler.scale(axis.fontSize!) / axis.fontSize!;
    final foot = math.max(20.0, line + 4);
    final values = widget.series.expand((s) => s.values.take(_count));
    final gutter = math.max(
      32 * factor,
      [
        for (final v in [values.reduce(math.min), values.reduce(math.max), 0.0])
          _measure(context, _text(v), axis).width + KeycapSpacing.small,
      ].reduce(math.max),
    );
    final labelSpacing = widget.labels.fold<double>(
      44 * factor,
      (width, label) => math.max(
        width,
        _measure(context, label, axis).width + KeycapSpacing.small,
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
      formatY: _text,
      tickCount: 4,
      padding: EdgeInsetsDirectional.only(
        start: gutter,
        top: line / 2,
        bottom: foot,
      ),
      focusNode: _focus,
      dampingRatio: KeycapMotion.panel.dampingRatio,
      stiffness: KeycapMotion.panel.stiffness,
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
                  rule: c.ink.withValues(alpha: 0.12),
                  floor: c.well,
                  scale: axis,
                  textScaler: scaler,
                  direction: Directionality.of(context),
                  labelSpacing: labelSpacing,
                  labels: widget.labels,
                  foot: foot,
                ),
              ),
            ),
            if (at != null && at < _count)
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
          builder: (context, child) => _Well(
            height: widget.height,
            focused: _focus.hasFocus,
            style: widget.style,
            child: child!,
          ),
          child: chart,
        ),
        if (widget.series.length > 1) ...[
          const SizedBox(height: KeycapSpacing.small),
          _Legend(
            entries: [
              for (final (i, s) in widget.series.indexed) (s.label, colours[i]),
            ],
          ),
        ],
      ],
    );
  }
}

/// [child] at the plot's top, on the far side from point [at], so the
/// point and its neighbours stay in view.
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

/// The picked point's label and each series' value, on a flat panel laid
/// over the well.
class _Readout extends StatelessWidget {
  const _Readout({required this.title, required this.lines});

  final String title;
  final List<(String, String, Color)> lines;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    return ExcludeSemantics(
      child: KeycapPanel(
        radius: BorderRadius.circular(KeycapMetrics.smallKeyRadius),
        elevated: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: KeycapSpacing.small,
            vertical: KeycapSpacing.tight,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: _scaleStyle(theme)),
              for (final (label, value, color) in lines)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox.square(dimension: 8),
                    ),
                    const SizedBox(width: KeycapSpacing.tight),
                    Text(
                      lines.length > 1 ? '$label  $value' : value,
                      style: t.figure.copyWith(color: c.ink),
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

class _SeriesPainter extends CustomPainter {
  _SeriesPainter({
    required this.mark,
    required this.chart,
    required this.colours,
    required this.rule,
    required this.floor,
    required this.scale,
    required this.textScaler,
    required this.direction,
    required this.labelSpacing,
    required this.labels,
    required this.foot,
  });

  final _Mark mark;
  final DesignChartDetails chart;
  final List<Color> colours;
  final Color rule;
  final Color floor;
  final TextStyle scale;
  final TextScaler textScaler;
  final TextDirection direction;
  final double labelSpacing;
  final List<String> labels;
  final double foot;

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
      maxLines: 1,
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

    // The scale: hairline rules across the well, their figures at the side.
    final rules = Paint()
      ..color = rule
      ..strokeWidth = 1;
    for (final tick in chart.yTicks) {
      final yy = tick.position;
      canvas.drawLine(Offset(plot.left, yy), Offset(plot.right, yy), rules);
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
    final cursor = chart.active?.index;
    if (cursor != null && cursor < count && mark != _Mark.bar) {
      canvas.drawLine(
        Offset(x(cursor), plot.top),
        Offset(x(cursor), plot.bottom),
        Paint()
          ..color = rule.withValues(alpha: rule.a * 2)
          ..strokeWidth = 1,
      );
    }
    if (mark == _Mark.bar) {
      final n = series.length;
      final band = (chart.x as DesignBandScale).step.abs();
      final gap = band * 0.28;
      final w = (band - gap) / n;
      for (final (si, values) in series.indexed) {
        for (var i = 0; i < math.min(count, values.length); i++) {
          final left = rtl
              ? x(i) + band / 2 - gap / 2 - w * (si + 1)
              : x(i) - band / 2 + gap / 2 + w * si;
          final rect = Rect.fromLTRB(
            left + 1,
            y(values[i]),
            left + w - 1,
            plot.bottom,
          );
          final lit = cursor == null || cursor == i;
          canvas.drawRRect(
            RRect.fromRectAndCorners(
              rect,
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3),
            ),
            Paint()..color = colours[si].withValues(alpha: lit ? 1 : 0.45),
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
                colours[si].withValues(alpha: 0.32),
                colours[si].withValues(alpha: 0.04),
              ],
            ).createShader(plot),
        );
      }
      canvas.drawPath(
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
          ..drawCircle(p, 5, Paint()..color = floor)
          ..drawCircle(p, 3.5, Paint()..color = colours[si]);
      }
    }
  }

  @override
  bool shouldRepaint(_SeriesPainter old) => true;
}

/// A line chart: each series a line printed across the well, the scale
/// faint behind it, a legend under the well when there is more than one.
/// Arrow keys walk the points; the picked point's values show on a small
/// panel.
///
/// ```dart
/// KeycapLineChart(semanticLabel: 'Words written by week', labels: const ['W1', 'W2', 'W3'], series: const [KeycapChartSeries('Words', [1200, 1800, 1500])])
/// ```
class KeycapLineChart extends StatelessWidget {
  /// A line chart of [series] over [labels].
  const KeycapLineChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel,
    this.style,
  });

  /// The labels along the foot, one per value.
  final List<String> labels;

  /// The series.
  final List<KeycapChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its height, the labels included.
  final double height;

  /// How a value reads; plain figures when null.
  final String Function(double value)? valueText;

  /// Whether its values are on their way (a spinner in the well).
  final bool loading;

  /// What the well says with nothing to show; the kit's "No results" when
  /// null.
  final String? emptyLabel;

  /// Overrides, over [KeycapThemeData.chartStyle]: fill (the well's floor)
  /// and padding.
  final KeycapStyle? style;

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
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length))
      ..add(FlagProperty('loading', value: loading, ifTrue: 'loading'));
  }
}

/// An area chart: a [KeycapLineChart] with each series' ground shaded
/// under its line, for a total over time.
///
/// ```dart
/// KeycapAreaChart(semanticLabel: 'Notes by month', labels: const ['Jan', 'Feb', 'Mar'], series: const [KeycapChartSeries('Notes', [12, 19, 24])])
/// ```
class KeycapAreaChart extends StatelessWidget {
  /// An area chart of [series] over [labels].
  const KeycapAreaChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel,
    this.style,
  });

  /// The labels along the foot, one per value.
  final List<String> labels;

  /// The series.
  final List<KeycapChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its height, the labels included.
  final double height;

  /// How a value reads; plain figures when null.
  final String Function(double value)? valueText;

  /// Whether its values are on their way.
  final bool loading;

  /// What the well says with nothing to show.
  final String? emptyLabel;

  /// Overrides, over [KeycapThemeData.chartStyle].
  final KeycapStyle? style;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length));
  }
}

/// A bar chart: a bar per label for each series, printed flat in the
/// well (they are read, not pressed); the picked label's bars stay full
/// ink, the rest fade.
///
/// ```dart
/// KeycapBarChart(semanticLabel: 'Notes by folder', labels: const ['Work', 'Home', 'Ideas'], series: const [KeycapChartSeries('Notes', [14, 9, 21])])
/// ```
class KeycapBarChart extends StatelessWidget {
  /// A bar chart of [series] over [labels].
  const KeycapBarChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueText,
    this.loading = false,
    this.emptyLabel,
    this.style,
  });

  /// The labels along the foot, one per bar group.
  final List<String> labels;

  /// The series.
  final List<KeycapChartSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its height, the labels included.
  final double height;

  /// How a value reads; plain figures when null.
  final String Function(double value)? valueText;

  /// Whether its values are on their way.
  final bool loading;

  /// What the well says with nothing to show.
  final String? emptyLabel;

  /// Overrides, over [KeycapThemeData.chartStyle].
  final KeycapStyle? style;

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

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length));
  }
}

/// A donut chart: each share an arc printed on a ring sunk in the well,
/// the total (or the picked share) in its middle, the shares listed beside
/// it.
///
/// ```dart
/// KeycapDonutChart(semanticLabel: 'Notes by folder', slices: const [('Work', 14), ('Home', 9), ('Ideas', 21)])
/// ```
class KeycapDonutChart extends StatefulWidget {
  /// A donut of [slices].
  const KeycapDonutChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.size = 200,
    this.centerLabel,
    this.valueText,
    this.loading = false,
    this.emptyLabel,
    this.style,
  });

  /// The shares: a label and a value each.
  final List<(String label, double value)> slices;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// The well's side.
  final double size;

  /// The words under the total in its middle ("Notes", "Total").
  final String? centerLabel;

  /// How a value reads; plain figures when null.
  final String Function(double value)? valueText;

  /// Whether its values are on their way.
  final bool loading;

  /// What the well says with nothing to show.
  final String? emptyLabel;

  /// Overrides, over [KeycapThemeData.chartStyle].
  final KeycapStyle? style;

  @override
  State<KeycapDonutChart> createState() => _KeycapDonutChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('slices', slices.length));
  }
}

class _KeycapDonutChartState extends State<KeycapDonutChart> {
  final FocusNode _focus = FocusNode(debugLabel: 'KeycapDonutChart');
  int? _at;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  double get _total =>
      widget.slices.fold<double>(0, (sum, s) => sum + math.max(0.0, s.$2));

  String _share(double v) =>
      _total <= 0 ? '0%' : '${(v / _total * 100).round()}%';

  String _text(double v) => widget.valueText?.call(v) ?? _plain(v);

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final inks = _inks(c);
    final empty = widget.slices.isEmpty || _total <= 0;
    final at = empty ? null : _at;
    final emptyLabel =
        widget.emptyLabel ?? DesignLocalizations.of(context).noResultsLabel;
    final colours = [
      for (var i = 0; i < widget.slices.length; i++) inks[i % inks.length],
    ];
    final Widget ring;
    if (widget.loading || empty) {
      ring = Semantics(
        container: true,
        label: widget.loading
            ? widget.semanticLabel
            : '${widget.semanticLabel}, $emptyLabel',
        child: ExcludeSemantics(
          excluding: !widget.loading,
          child: _Idle(loading: widget.loading, emptyLabel: emptyLabel),
        ),
      );
    } else {
      ring = DesignPieChart(
        semanticLabel: widget.semanticLabel,
        slices: [
          for (final (label, value) in widget.slices)
            DesignPieSlice(label: label, value: math.max(0.0, value)),
        ],
        holeRadius: 0.62,
        formatValue: _text,
        focusNode: _focus,
        dampingRatio: KeycapMotion.panel.dampingRatio,
        stiffness: KeycapMotion.panel.stiffness,
        onActiveSliceChanged: (i) => setState(() => _at = i),
        builder: (context, pie) {
          final a = pie.active;
          final under = a == null ? widget.centerLabel : widget.slices[a].$1;
          return CustomPaint(
            painter: _DonutPainter(
              pie: pie,
              colours: colours,
              track: c.wellPressed,
            ),
            child: Center(
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      a == null ? _text(_total) : _share(widget.slices[a].$2),
                      style: t.heading.copyWith(
                        color: c.ink,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (under != null)
                      Text(
                        under,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: _scaleStyle(theme),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }
    return Wrap(
      spacing: KeycapSpacing.large,
      runSpacing: KeycapSpacing.regular,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: widget.size,
          child: ListenableBuilder(
            listenable: _focus,
            builder: (context, child) => _Well(
              height: widget.size,
              focused: _focus.hasFocus,
              style: widget.style,
              child: child!,
            ),
            child: ring,
          ),
        ),
        if (!empty && !widget.loading)
          ExcludeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, (label, value)) in widget.slices.indexed)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: KeycapSpacing.tight,
                    ),
                    // One run of words, so large text wraps it rather than
                    // pushing it past the chart's edge.
                    child: Text.rich(
                      TextSpan(
                        children: [
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsetsDirectional.only(
                                end: KeycapSpacing.small,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: colours[i],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: const SizedBox.square(dimension: 10),
                              ),
                            ),
                          ),
                          TextSpan(
                            text: label,
                            style: t.body.copyWith(
                              color: c.ink,
                              fontWeight: at == i ? FontWeight.w600 : null,
                            ),
                          ),
                          const WidgetSpan(
                            child: SizedBox(width: KeycapSpacing.small),
                          ),
                          TextSpan(
                            text: '${_text(value)} · ${_share(value)}',
                            style: t.figure.copyWith(color: c.inkMuted),
                          ),
                        ],
                      ),
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
  _DonutPainter({
    required this.pie,
    required this.colours,
    required this.track,
  });

  final DesignPieChartDetails pie;
  final List<Color> colours;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    const width = 16.0;
    final rect = Rect.fromCircle(
      center: pie.centre,
      radius: pie.radius - width / 2 - 2,
    );
    canvas.drawCircle(
      rect.center,
      rect.width / 2,
      Paint()
        ..color = track
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    final at = pie.active;
    for (final (i, s) in pie.slices.indexed) {
      // A hair's gap at each end, so neighbouring shares stay apart.
      final sign = s.sweepAngle.isNegative ? -1.0 : 1.0;
      final sweep = math.max(0.0, s.sweepAngle.abs() - 0.04);
      if (sweep == 0) continue;
      final lit = at == null || at == i;
      canvas.drawArc(
        rect,
        s.startAngle + 0.02 * sign,
        sweep * sign,
        false,
        Paint()
          ..color = colours[i].withValues(alpha: lit ? 1 : 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = width,
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) => true;
}

/// A sparkline: a small line printed in muted ink, its last value an
/// accent dot; for a figure's trend in a row. Not a well of its own: it
/// sits beside the figure it explains.
///
/// ```dart
/// const KeycapSparkline(values: [3, 5, 4, 7, 6, 9], semanticLabel: 'Notes this week, rising')
/// ```
class KeycapSparkline extends StatelessWidget {
  /// A line of [values].
  const KeycapSparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.width = 72,
    this.height = 24,
    this.style,
  });

  /// The values, oldest first.
  final List<double> values;

  /// What it shows and which way it goes, for a screen reader.
  final String semanticLabel;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// Overrides, over [KeycapThemeData.chartStyle]: foreground (the line).
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final look = DesignStyleOf([style, theme.chartStyle], const {});
    return Semantics(
      label: semanticLabel,
      child: ExcludeSemantics(
        child: SizedBox(
          width: width,
          height: height,
          child: CustomPaint(
            painter: _SparkPainter(
              values: values,
              line: look.foreground ?? theme.colors.inkMuted,
              dot: theme.colors.accentInk,
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
    required this.dot,
    required this.rtl,
  });

  final List<double> values;
  final Color line;
  final Color dot;
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
      ..drawCircle(p(n - 1), 3, Paint()..color = dot);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) ||
      old.line != line ||
      old.dot != dot ||
      old.rtl != rtl;
}
