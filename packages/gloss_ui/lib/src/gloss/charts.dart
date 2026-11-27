/// Line, area, bar, pie, and sparkline charts in the Gloss theme.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'internal/label_stride.dart';
import 'surface.dart';
import 'theme.dart';
import 'internal/corners.dart';

/// One series of figures in a chart.
@immutable
class GlossSeries {
  /// A series named [label] of [values], one per x label.
  const GlossSeries(this.label, this.values, {this.color});

  /// Its name, in the legend and for a screen reader.
  final String label;

  /// Its figures.
  final List<double> values;

  /// Its gel; null: the next in Gloss's set (jade, lagoon, amber, plum).
  final Color? color;
}

/// One slice of a [GlossPieChart].
@immutable
class GlossSlice {
  /// A slice named [label] worth [value].
  const GlossSlice(this.label, this.value, {this.color});

  /// Its name.
  final String label;

  /// Its share, against the others' sum.
  final double value;

  /// Its gel; null: the next in Gloss's set.
  final Color? color;
}

/// Gloss's set of gels for series, by day and by night.
List<Color> _gels(GlossColors c) => c.brightness == Brightness.light
    ? const [
        Color(0xFF1FA77A),
        Color(0xFF2F86C8),
        Color(0xFFE09A22),
        Color(0xFF9A5AB8),
      ]
    : const [
        Color(0xFF3CC596),
        Color(0xFF55A6E2),
        Color(0xFFEDB04A),
        Color(0xFFB57DD0),
      ];

Color _gelAt(GlossColors c, Color? given, int i) =>
    given ?? _gels(c)[i % _gels(c).length];

/// A gel face for [color]: lighter at the top, deeper at the foot, the
/// lens's sheen on it.
GlossFace _gelOf(Color color, {double? radius}) {
  final hsl = HSLColor.fromColor(color);
  Color by(double d) =>
      hsl.withLightness((hsl.lightness + d).clamp(0.0, 1.0)).toColor();
  return GlossFace(
    top: by(0.16),
    middle: color,
    bottom: by(-0.06),
    edge: by(-0.22),
    glow: by(0.3).withValues(alpha: 0.45),
    foreground: const Color(0xFFFFFFFF),
    lens: 0.7,
    lift: 0.4,
    radius: radius,
  );
}

/// Gloss's figure for [value] in the reader's digits: as the scale writes
/// it, compact past a thousand (1.2k).
String _compact(double value, String figure, RawWidgetsLocalizations words) {
  if (value.abs() < 1000) return figure;
  final k = words.formatDecimal(
    value / 1000,
    fractionDigits: value % 1000 == 0 ? 0 : 1,
  );
  return '${k}k';
}

/// A chart's own format, or Gloss's compact figure.
RawChartValueFormat _formatOf(RawChartValueFormat? format) =>
    format ?? const RawChartValueFormat.custom(_compact);

class _Legend extends StatelessWidget {
  const _Legend(this.entries);

  final List<(String, Color)> entries;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    return ExcludeSemantics(
      child: Wrap(
        spacing: GlossSpacing.regular,
        runSpacing: GlossSpacing.tight,
        children: [
          for (final (label, color) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox.square(
                  dimension: 12,
                  child: GlossSurface(face: _gelOf(color)),
                ),
                const SizedBox(width: GlossSpacing.small),
                Flexible(child: Text(label, style: theme.textTheme.caption)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The frame every axes chart shares: the tray, the legend under it when
/// there is more than one series, and one sentence for a screen reader.
class _Framed extends StatelessWidget {
  const _Framed({
    required this.semanticLabel,
    required this.readOut,
    required this.legend,
    required this.height,
    required this.painter,
    required this.fill,
    required this.corners,
  });

  final String semanticLabel;
  final String readOut;
  final List<(String, Color)> legend;
  final double height;
  final CustomPainter painter;
  final Color? fill;
  // The tray's corners an app gave (start on the left), or null.
  final BorderRadius? corners;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    var tray = GlossFace.well(
      c,
      radius: glossCorner(theme, RawCorner.medium),
    ).copyWith(lift: -0.55, corners: corners);
    if (fill != null) tray = tray.glazed(fill!);
    return Semantics(
      label: semanticLabel,
      value: readOut,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: GlossSurface(
              face: tray,
              child: Padding(
                // The figures' side (the start) and the far side, mirrored
                // on a right-to-left page.
                padding: const EdgeInsetsDirectional.fromSTEB(
                  GlossSpacing.small,
                  GlossSpacing.regular - GlossMetrics.rimRoom,
                  GlossSpacing.regular - GlossMetrics.rimRoom,
                  GlossSpacing.small,
                ),
                child: CustomPaint(painter: painter, size: Size.infinite),
              ),
            ),
          ),
          if (legend.length > 1) ...[
            const SizedBox(height: GlossSpacing.small),
            _Legend(legend),
          ],
        ],
      ),
    );
  }
}

String _readOut(
  List<String> labels,
  List<GlossSeries> series,
  RawWidgetsLocalizations words,
  RawChartValueFormat format,
) => [
  for (final s in series)
    '${s.label}: ${[for (final (i, v) in s.values.indexed) '${i < labels.length ? labels[i] : i + 1} ${format.format(v, words)}'].join(', ')}',
].join('. ');

/// What the axes charts share: the engraved grid, the figures up the start
/// and the labels along the foot.
abstract class _AxesPainter extends CustomPainter {
  _AxesPainter({
    required this.c,
    required this.text,
    required this.labels,
    required this.series,
    required this.direction,
    required this.textScaler,
    required this.t,
    required this.words,
    required this.valueFormat,
  });

  final GlossColors c;
  final TextStyle text;
  final List<String> labels;
  final List<GlossSeries> series;
  final TextDirection direction;
  final TextScaler textScaler;
  final double t;

  /// The reader's words, for ui_core's ticks.
  final RawWidgetsLocalizations words;

  /// How the value axis writes its ticks: each at its scale's decimals.
  final RawChartValueFormat valueFormat;

  // Whether no value is above 0.
  bool get _empty => series.expand((s) => s.values).fold(0.0, math.max) <= 0;

  /// ui_core's scale up the start, from 0 to a whole tick over the most:
  /// each step a round figure (1, 2 or 5 times a power of ten), never 1.3
  /// or 3.8.
  late final RawLinearScale _scale = () {
    final most = series
        .expand((s) => s.values)
        .fold(0.0, (a, b) => math.max(a, b));
    return RawLinearScale.nice(
      // An empty or all-zero chart still climbs to 1.
      min: 0,
      max: most > 0 ? most : 1,
      start: 0,
      end: 1,
      includeZero: true,
    );
  }();

  /// The axis's top.
  double get top => _scale.max;

  TextPainter _words(String s, {TextAlign align = TextAlign.start}) =>
      TextPainter(
        text: TextSpan(text: s, style: text),
        textDirection: direction,
        textScaler: textScaler,
        textAlign: align,
        maxLines: 1,
      )..layout();

  /// Paints the grid and the labels, and gives the plot's rectangle.
  Rect paintAxes(Canvas canvas, Size size) {
    // Nothing above 0: the axis counts 0 and 1, not tenths of a scale no
    // value reaches.
    final ticks = valueFormat.labelTicks(
      _scale.ticks(words, count: _empty ? 1 : 5),
      words,
    );
    final figures = [for (final tick in ticks) _words(tick.label)];
    // The figures' room at the start of the plot.
    final gutter = math.min(
      size.width,
      RawScaleTick.widestLabel(
            ticks,
            style: text,
            textScaler: textScaler,
            textDirection: direction,
          ) +
          GlossSpacing.small,
    );
    final lineHeight = figures.map((f) => f.height).fold(0.0, math.max);
    // The tray already has room for a 16 px caption and its two half-lines
    // at the ends of the value axis.
    final foot = 20 + math.max(0.0, lineHeight - 16);
    final upper = math.min(
      size.height,
      math.max(
        0.0,
        lineHeight / 2 - (GlossSpacing.regular - GlossMetrics.rimRoom),
      ),
    );
    final rtl = direction == TextDirection.rtl;
    final plot = Rect.fromLTRB(
      rtl ? 0 : gutter,
      upper,
      rtl ? size.width - gutter : size.width,
      math.max(upper, size.height - foot),
    );
    double yAt(int i) => plot.bottom - plot.height * ticks[i].position;
    for (var i = 0; i < ticks.length; i++) {
      final y = yAt(i);
      // An engraved line: a dark cut, light on its lower lip.
      canvas
        ..drawLine(
          Offset(plot.left, y),
          Offset(plot.right, y),
          Paint()
            ..color = c.hairline
            ..strokeWidth = 1,
        )
        ..drawLine(
          Offset(plot.left, y + 1),
          Offset(plot.right, y + 1),
          Paint()
            ..color = c.lip.withValues(alpha: c.lip.a * 0.6)
            ..strokeWidth = 1,
        );
    }
    // The figures: every one that keeps clear of the next, or every other,
    // every third...: evenly, from 0 up.
    final rows = glossLabelStride(figures.length, (every) {
      var floor = double.infinity;
      for (var i = 0; i < figures.length; i += every) {
        final above = yAt(i) - figures[i].height / 2;
        if (above + figures[i].height > floor) return false;
        floor = above - GlossSpacing.tight;
      }
      return true;
    });
    if (rows != null) {
      for (var i = 0; i < figures.length; i += rows) {
        final f = figures[i];
        f.paint(
          canvas,
          Offset(
            rtl ? plot.right + 8 : plot.left - 8 - f.width,
            yAt(i) - f.height / 2,
          ),
        );
      }
    }
    for (final f in figures) {
      f.dispose();
    }
    // The labels under it: every one, or every other, every third...,
    // evenly, so no two kept stand closer than a word's space.
    final n = labels.length;
    if (n > 0 && plot.width > 0) {
      final names = [for (final l in labels) _words(l)];
      double leftOf(int i) => (xAt(plot, i, n) - names[i].width / 2)
          .clamp(plot.left, math.max(plot.left, plot.right - names[i].width))
          .toDouble();
      final steps = glossLabelStride(n, (every) {
        final kept = [for (var i = 0; i < n; i += every) i]
          ..sort((a, b) => leftOf(a).compareTo(leftOf(b)));
        var end = double.negativeInfinity;
        for (final i in kept) {
          if (leftOf(i) < end) return false;
          end = leftOf(i) + names[i].width + GlossSpacing.small;
        }
        return true;
      });
      if (steps != null) {
        for (var i = 0; i < n; i += steps) {
          names[i].paint(canvas, Offset(leftOf(i), plot.bottom + 5));
        }
      }
      for (final w in names) {
        w.dispose();
      }
    }
    return plot;
  }

  /// Where the [i]th of [n] points sits along [plot].
  double xAt(Rect plot, int i, int n);

  @override
  bool shouldRepaint(_AxesPainter old) =>
      old.t != t ||
      old.c != c ||
      old.text != text ||
      old.direction != direction ||
      old.textScaler != textScaler ||
      old.words != words ||
      old.valueFormat != valueFormat ||
      !listEquals(old.labels, labels) ||
      !listEquals(
        [for (final s in old.series) ...s.values],
        [for (final s in series) ...s.values],
      );
}

class _LinePainter extends _AxesPainter {
  _LinePainter({
    required super.c,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
    required super.textScaler,
    required super.t,
    required super.words,
    required super.valueFormat,
    required this.area,
  });

  final bool area;

  // The first and last points stand in from the plot's ends, so a day's
  // name centred under them stays inside the well.
  static const double _edge = 20;

  @override
  double xAt(Rect plot, int i, int n) {
    final f = n <= 1 ? 0.5 : i / (n - 1);
    final edge = math.min(_edge, plot.width / 2);
    final run = plot.width - 2 * edge;
    return direction == TextDirection.rtl
        ? plot.right - edge - run * f
        : plot.left + edge + run * f;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = paintAxes(canvas, size);
    if (plot.isEmpty) return;
    final top = this.top;
    for (final (si, s) in series.indexed) {
      if (s.values.isEmpty) continue;
      final color = _gelAt(c, s.color, si);
      final n = s.values.length;
      final points = [
        for (final (i, v) in s.values.indexed)
          Offset(xAt(plot, i, n), plot.bottom - plot.height * (v / top) * t),
      ];
      final line = Path()..moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        final a = points[i - 1];
        final b = points[i];
        final mid = (b.dx - a.dx) / 2;
        line.cubicTo(a.dx + mid, a.dy, b.dx - mid, b.dy, b.dx, b.dy);
      }
      if (area) {
        final fill = Path.from(line)
          ..lineTo(points.last.dx, plot.bottom)
          ..lineTo(points.first.dx, plot.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                color.withValues(alpha: 0.42),
                color.withValues(alpha: 0.04),
              ],
            ).createShader(plot),
        );
      }
      // The glow under the line, then the gel line, then its sheen.
      canvas
        ..drawPath(
          line.shift(const Offset(0, 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..color = color.withValues(alpha: 0.18)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawPath(
          line,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        )
        ..drawPath(
          line.shift(const Offset(0, -0.8)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.9
            ..color = const Color(0x8CFFFFFF),
        );
      if (n <= 14) {
        for (final p in points) {
          paintGlossFace(
            canvas,
            Rect.fromCircle(center: p, radius: 4.5),
            _gelOf(color),
          );
        }
      }
    }
  }
}

class _BarPainter extends _AxesPainter {
  _BarPainter({
    required super.c,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
    required super.textScaler,
    required super.t,
    required super.words,
    required super.valueFormat,
    required this.corner,
  });

  // The theme's extraSmall step: a bar's crown is rounded in proportion.
  final double corner;

  @override
  bool shouldRepaint(_AxesPainter old) =>
      super.shouldRepaint(old) || (old is _BarPainter && old.corner != corner);

  @override
  double xAt(Rect plot, int i, int n) {
    final slot = plot.width / math.max(1, n);
    final f = (i + 0.5) * slot;
    return direction == TextDirection.rtl ? plot.right - f : plot.left + f;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = paintAxes(canvas, size);
    if (plot.isEmpty) return;
    final top = this.top;
    final n = labels.isEmpty
        ? series.fold(0, (a, s) => math.max(a, s.values.length))
        : labels.length;
    if (n == 0 || series.isEmpty) return;
    final slot = plot.width / n;
    final group = math.min(slot * 0.68, 22.0 * series.length + 4);
    final bar = (group - 3 * (series.length - 1)) / series.length;
    for (var i = 0; i < n; i++) {
      final centre = xAt(plot, i, n);
      for (final (si, s) in series.indexed) {
        if (i >= s.values.length) continue;
        final h = plot.height * (s.values[i] / top) * t;
        if (h <= 0.5) continue;
        final offset = -group / 2 + si * (bar + 3);
        final x = direction == TextDirection.rtl
            ? centre - offset - bar
            : centre + offset;
        final rect = Rect.fromLTWH(x, plot.bottom - h, bar, h + 3);
        paintGlossFace(
          canvas,
          rect,
          _gelOf(_gelAt(c, s.color, si)).copyWith(
            corners: BorderRadius.vertical(
              top: Radius.circular(math.min(bar / 2, corner * 8 / 7)),
              bottom: Radius.circular(corner * 2 / 7),
            ),
          ),
        );
      }
    }
  }
}

/// Grows a chart's figures in from nothing once, as it first shows (at once
/// under Reduce Motion).
class _Grow extends StatelessWidget {
  const _Grow({required this.builder});

  final Widget Function(BuildContext context, double t) builder;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) return builder(context, 1);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => builder(context, t),
    );
  }
}

/// A line chart with an engraved grid and a legend for multiple series.
/// Axis labels use the ambient text scale and reading direction.
///
/// ```dart
/// GlossLineChart(labels: const ['Mon', 'Tue', 'Wed'], series: const [GlossSeries('Minutes', [35, 20, 45])], semanticLabel: 'Cooking time this week')
/// ```
class GlossLineChart extends StatelessWidget {
  /// A line chart of [series] over [labels].
  const GlossLineChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueFormat,
    this.style,
  });

  /// The x labels.
  final List<String> labels;

  /// The lines.
  final List<GlossSeries> series;

  /// What it shows, for a screen reader (which also hears the figures).
  final String semanticLabel;

  /// Its height.
  final double height;

  /// How a value is written on the value axis and in what a screen reader
  /// hears: in the reader's digits, each tick at its scale's decimals, with
  /// a unit (`RawChartValueFormat(suffix: ' h')`); null: the figure,
  /// compact past a thousand (1.2k).
  final RawChartValueFormat? valueFormat;

  /// Its own style, over [GlossThemeData.chartStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) => _axes(context, area: false);

  Widget _axes(BuildContext context, {required bool area}) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.chartStyle], const {});
    return _Grow(
      builder: (context, t) => _Framed(
        semanticLabel: semanticLabel,
        readOut: _readOut(
          labels,
          series,
          RawWidgetsLocalizations.of(context),
          _formatOf(valueFormat),
        ),
        legend: [
          for (final (i, s) in series.indexed) (s.label, _gelAt(c, s.color, i)),
        ],
        height: height,
        fill: layered.fill,
        corners: glossCornersOf(
          theme,
          layered,
          RawCorner.medium,
          Directionality.of(context),
        ),
        painter: _LinePainter(
          c: c,
          text: theme.textTheme.caption.copyWith(color: c.inkSecondary),
          labels: labels,
          series: series,
          direction: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          words: RawWidgetsLocalizations.of(context),
          valueFormat: _formatOf(valueFormat),
          t: t,
          area: area,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('labels', labels))
      ..add(IntProperty('series', series.length));
  }
}

/// A line chart with a translucent fill between each series and the baseline.
///
/// ```dart
/// GlossAreaChart(labels: const ['Mon', 'Tue', 'Wed'], series: const [GlossSeries('Meals', [2, 3, 2])], semanticLabel: 'Meals cooked')
/// ```
class GlossAreaChart extends GlossLineChart {
  /// An area chart of [series] over [labels].
  const GlossAreaChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height,
    super.valueFormat,
    super.style,
  });

  @override
  Widget build(BuildContext context) => _axes(context, area: true);
}

/// A bar chart that groups the series at each label. Axis labels use the
/// ambient text scale and reading direction.
///
/// ```dart
/// GlossBarChart(labels: const ['Mon', 'Tue', 'Wed'], series: const [GlossSeries('Recipes', [3, 1, 4])], semanticLabel: 'Recipes cooked each day')
/// ```
class GlossBarChart extends StatelessWidget {
  /// A bar chart of [series] over [labels].
  const GlossBarChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 200,
    this.valueFormat,
    this.style,
  });

  /// The x labels.
  final List<String> labels;

  /// The series.
  final List<GlossSeries> series;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its height.
  final double height;

  /// How a value is written on the value axis and in what a screen reader
  /// hears: in the reader's digits, each tick at its scale's decimals, with
  /// a unit (`RawChartValueFormat(suffix: ' h')`); null: the figure,
  /// compact past a thousand (1.2k).
  final RawChartValueFormat? valueFormat;

  /// Its own style, over [GlossThemeData.chartStyle].
  final GlossStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.chartStyle], const {});
    return _Grow(
      builder: (context, t) => _Framed(
        semanticLabel: semanticLabel,
        readOut: _readOut(
          labels,
          series,
          RawWidgetsLocalizations.of(context),
          _formatOf(valueFormat),
        ),
        legend: [
          for (final (i, s) in series.indexed) (s.label, _gelAt(c, s.color, i)),
        ],
        height: height,
        fill: layered.fill,
        corners: glossCornersOf(
          theme,
          layered,
          RawCorner.medium,
          Directionality.of(context),
        ),
        painter: _BarPainter(
          c: c,
          corner: glossCorner(theme, RawCorner.extraSmall),
          text: theme.textTheme.caption.copyWith(color: c.inkSecondary),
          labels: labels,
          series: series,
          direction: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          words: RawWidgetsLocalizations.of(context),
          valueFormat: _formatOf(valueFormat),
          t: t,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<String>('labels', labels))
      ..add(IntProperty('series', series.length));
  }
}

/// A donut chart showing each slice and its value in a legend. The total
/// appears in the center. The legend moves below the ring when its labels
/// need the full width.
///
/// ```dart
/// GlossPieChart(slices: const [GlossSlice('Dinners', 7), GlossSlice('Lunches', 4)], semanticLabel: 'Meals this week')
/// ```
class GlossPieChart extends StatelessWidget {
  /// A donut of [slices].
  const GlossPieChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.size = 168,
    this.centerLabel,
  });

  /// The slices.
  final List<GlossSlice> slices;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its width and height.
  final double size;

  /// What its middle says under the total; null: nothing.
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final total = slices.fold(0.0, (a, s) => a + math.max(0, s.value));
    final colors = [for (final (i, s) in slices.indexed) _gelAt(c, s.color, i)];
    final ring = SizedBox.square(
      dimension: size,
      child: _Grow(
        builder: (context, t) => CustomPaint(
          painter: _DonutPainter(
            c: c,
            values: [for (final s in slices) math.max(0.0, s.value)],
            colors: colors,
            t: t,
          ),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatOf(null).format(total, words),
                  style: theme.textTheme.title.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                if (centerLabel != null)
                  Text(centerLabel!, style: theme.textTheme.caption),
              ],
            ),
          ),
        ),
      ),
    );
    final entries = [
      for (final (i, s) in slices.indexed)
        ('${s.label} ${_formatOf(null).format(s.value, words)}', colors[i]),
    ];
    final legend = _Legend(entries);
    final direction = Directionality.of(context);
    final scaler = MediaQuery.textScalerOf(context);
    final widest = entries.fold(
      0.0,
      (width, entry) => math.max(
        width,
        TextPainter.computeWidth(
          text: TextSpan(text: entry.$1, style: theme.textTheme.caption),
          textDirection: direction,
          textScaler: scaler,
        ),
      ),
    );
    final legendRoom = math.max(
      180.0,
      GlossSpacing.large + 12 + GlossSpacing.small + widest,
    );
    return Semantics(
      label: semanticLabel,
      value: [
        for (final s in slices)
          '${s.label} ${_formatOf(null).format(s.value, words)}',
      ].join(', '),
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) => box.maxWidth >= size + legendRoom
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ring,
                  const SizedBox(width: GlossSpacing.large),
                  Flexible(child: legend),
                ],
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ring,
                  const SizedBox(height: GlossSpacing.regular),
                  legend,
                ],
              ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('slices', slices.length));
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.c,
    required this.values,
    required this.colors,
    required this.t,
  });

  final GlossColors c;
  final List<double> values;
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final band = s * 0.17;
    final centre = size.center(Offset.zero);
    final r = (s - band) / 2;
    final ring = Rect.fromCircle(center: centre, radius: r);
    // The groove.
    canvas
      ..drawCircle(
        centre,
        r,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = band + 4
          ..color = c.well,
      )
      ..drawArc(
        Rect.fromCircle(center: centre, radius: r + band / 2 + 1.5),
        math.pi * 0.1,
        math.pi * 0.8,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = c.lip.withValues(alpha: c.lip.a * 0.8),
      );
    final total = values.fold(0.0, (a, b) => a + b);
    if (total <= 0) return;
    const gap = 0.035;
    var start = -math.pi / 2;
    final whole = math.pi * 2 * t;
    for (final (i, v) in values.indexed) {
      final sweep = whole * v / total;
      if (sweep > gap) {
        final color = colors[i];
        final hsl = HSLColor.fromColor(color);
        final deep = hsl
            .withLightness((hsl.lightness - 0.08).clamp(0.0, 1.0))
            .toColor();
        canvas
          ..drawArc(
            ring,
            start + gap / 2,
            sweep - gap,
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = band
              ..shader =
                  RadialGradient(
                    colors: [deep, color, deep],
                    stops: const [0.72, 0.86, 1],
                  ).createShader(
                    Rect.fromCircle(center: centre, radius: r + band / 2),
                  ),
          )
          // The sheen: a thin bright arc along the gel's outer top.
          ..drawArc(
            Rect.fromCircle(center: centre, radius: r + band * 0.22),
            start + gap,
            math.max(0, sweep - gap * 2),
            false,
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = band * 0.18
              ..strokeCap = StrokeCap.round
              ..color = const Color(0x52FFFFFF),
          );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.t != t ||
      old.c != c ||
      !listEquals(old.values, values) ||
      !listEquals(old.colors, colors);
}

/// A sparkline: a small thread of jade gel tracing [values], a bead at its
/// last figure. For a trend beside a number.
///
/// ```dart
/// const GlossSparkline(values: [3, 5, 4, 6, 8], semanticLabel: 'Recipes saved, rising')
/// ```
class GlossSparkline extends StatelessWidget {
  /// A sparkline of [values].
  const GlossSparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.width = 96,
    this.height = 28,
    this.color,
  });

  /// The figures.
  final List<double> values;

  /// What it shows, for a screen reader.
  final String semanticLabel;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// Its gel; null: jade.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values,
            color ?? _gels(c).first,
            Directionality.of(context),
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
  _SparkPainter(this.values, this.color, this.direction);

  final List<double> values;
  final Color color;
  final TextDirection direction;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    const pad = GlossSpacing.tight;
    final rtl = direction == TextDirection.rtl;
    Offset at(int i) {
      final f = i / (values.length - 1);
      final x = pad + (size.width - 2 * pad) * (rtl ? 1 - f : f);
      final y = pad + (size.height - 2 * pad) * (1 - (values[i] - lo) / span);
      return Offset(x, y);
    }

    final line = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      final a = at(i - 1);
      final b = at(i);
      final mid = (b.dx - a.dx) / 2;
      line.cubicTo(a.dx + mid, a.dy, b.dx - mid, b.dy, b.dx, b.dy);
    }
    canvas
      ..drawPath(
        line.shift(const Offset(0, 1.5)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = color.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawPath(
        line,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color,
      );
    paintGlossFace(
      canvas,
      Rect.fromCircle(center: at(values.length - 1), radius: 4),
      _gelOf(color),
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      old.color != color || !listEquals(old.values, values);
}
