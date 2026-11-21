/// Studio's charts, read off a scope: traces of light on a dark readout
/// window ruled with a fine graticule. [StudioLineChart], [StudioAreaChart]
/// and [StudioBarChart] over labelled steps, [StudioPieChart] as lit arcs
/// round a ring, [StudioSparkline] as a trace with no frame. The first
/// series glows in the indicator; the next in the readout's white, then
/// dimmer. A screen reader hears each chart's figures.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'fonts.dart';
import 'internal/label_stride.dart';
import 'surface.dart';
import 'theme.dart';

/// A named run of values for a chart.
///
/// ```dart
/// StudioSeries('Plays', [120, 180, 150])
/// ```
@immutable
class StudioSeries {
  /// [values] under [label].
  const StudioSeries(this.label, this.values, {this.color});

  /// Its name, in the legend.
  final String label;

  /// One value per step.
  final List<double> values;

  /// Its light; by default by its place.
  final Color? color;
}

List<Color> _lights(StudioColors c) => [
  c.readoutLit,
  c.onReadout,
  c.readoutDim,
  c.onReadoutMuted,
];

Color _lightOf(StudioColors c, int i, Color? own) =>
    own ?? _lights(c)[i % _lights(c).length];

// The room kept between two labels side by side: a word's space.
const double _labelGap = StudioSpacing.small;

// A figure in the reader's digits: whole, or to one place.
String _figure(RawWidgetsLocalizations words, double v) =>
    v == v.roundToDouble()
    ? words.formatDecimal(v.toInt())
    : words.formatDecimal(v, fractionDigits: 1);

// A chart's frame: the scope window, and the legend under it.
class _Scope extends StatelessWidget {
  const _Scope({
    required this.semanticLabel,
    required this.readOut,
    required this.legend,
    required this.height,
    required this.chart,
  });

  final String semanticLabel;
  final String readOut;
  final List<(String, Color)> legend;
  final double height;
  final Widget chart;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    return Semantics(
      container: true,
      label: semanticLabel,
      value: readOut,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: StudioSurface(
              face: c.readoutFace.copyWith(radius: StudioRadii.display),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  StudioSpacing.small,
                  StudioSpacing.medium,
                  StudioSpacing.medium,
                  StudioSpacing.small,
                ),
                child: RepaintBoundary(child: chart),
              ),
            ),
          ),
          if (legend.length > 1) ...[
            const SizedBox(height: StudioSpacing.small),
            Wrap(
              spacing: StudioSpacing.regular,
              runSpacing: StudioSpacing.tight,
              children: [
                for (final (label, light) in legend)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      StudioLamp(on: true, color: light, size: 8),
                      const SizedBox(width: StudioSpacing.small),
                      Text(
                        label,
                        style: theme.textTheme.caption.copyWith(
                          color: c.legend,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

abstract class _AxesPainter extends CustomPainter {
  _AxesPainter({
    required this.colors,
    required this.text,
    required this.labels,
    required this.series,
    required this.direction,
  }) : super(repaint: PaintingBinding.instance.systemFonts);

  final StudioColors colors;
  final TextStyle text;
  final List<String> labels;
  final List<StudioSeries> series;
  final TextDirection direction;

  /// The reader's words, whose digits the scale's figures are set in; the
  /// chart gives them before the painter paints.
  late final RawWidgetsLocalizations words;

  /// ui_core's scale up the start, from 0 to a whole step over the most:
  /// each step a round figure (1, 2 or 5 times a power of ten), so a
  /// five-hour week reads 0, 1, 2, 3, 4, 5, never 1.3 or 3.8.
  late final DesignLinearScale _scale = () {
    final most = series.fold<double>(
      0,
      (m, s) => s.values.fold<double>(m, (a, v) => math.max(a, v)),
    );
    return DesignLinearScale.nice(
      // An empty or all-zero chart still climbs to 1.
      min: 0,
      max: most > 0 ? most : 1,
      start: 0,
      end: 1,
      includeZero: true,
    );
  }();

  /// The scale's top.
  late final double top = _scale.max;

  /// The scale's steps, their figures in the reader's digits.
  late final List<DesignScaleTick> _ticks = _scale.ticks(words);

  // These resolved family names may come from different packages. Inherit
  // the rest of the caption style from the enclosing span.
  late final _families = TextStyle(
    fontFamily: text.fontFamily,
    fontFamilyFallback: [
      ...?text.fontFamilyFallback,
      studioRegisteredFamily('NotoSansArabic'),
    ],
  );

  TextPainter _words(String s, {Color? color}) => TextPainter(
    text: TextSpan(
      style: text.copyWith(color: color),
      children: [TextSpan(text: s, style: _families)],
    ),
    textDirection: direction,
    locale: text.locale,
    maxLines: 1,
  )..layout();

  /// The plot's rectangle, after the scale's figures and the steps' labels.
  /// When the steps stand on the plot's ends ([between] false, a line),
  /// the plot is inset by half the widest step's label, so the first label
  /// clears the scale's figures and the last stays inside the glass.
  Rect plot(Size size, {bool between = true}) {
    var gutter = 0.0;
    var labelHeight = 0.0;
    for (final tick in _ticks) {
      final p = _words(tick.label);
      gutter = math.max(gutter, p.width);
      labelHeight = math.max(labelHeight, p.height);
      p.dispose();
    }
    var half = 0.0;
    var dayHeight = labels.isEmpty ? labelHeight : 0.0;
    for (final label in labels) {
      final day = _words(label);
      dayHeight = math.max(dayHeight, day.height);
      if (!between) half = math.max(half, day.width / 2);
      day.dispose();
    }
    // The steps' labels stand clear under the base figure ("0"), which is
    // centred on the base line.
    final under = labelHeight / 2 + StudioSpacing.tight + dayHeight;
    final start = math.min(size.width, gutter + StudioSpacing.small);
    half = math.min(half, math.max(0.0, (size.width - start) / 2 - 1));
    final plotTop = math.min(size.height, labelHeight / 2);
    return Rect.fromLTRB(
      start + half,
      plotTop,
      size.width - half,
      math.max(plotTop, size.height - under),
    );
  }

  void paintGrid(Canvas canvas, Size size, Rect r, {required bool between}) {
    final c = colors;
    final line = Paint()
      ..color = c.onReadout.withValues(alpha: 0.10)
      ..strokeWidth = 1;
    final dash = Paint()
      ..color = c.onReadout.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    // The scale's figures, every one that keeps clear of the next, or
    // every other, every third...: evenly, from 0 up.
    final figures = [
      for (final tick in _ticks) _words(tick.label, color: c.onReadoutMuted),
    ];
    double yAt(int i) => r.bottom - r.height * _ticks[i].position;
    for (var i = 0; i < _ticks.length; i++) {
      canvas.drawLine(Offset(r.left, yAt(i)), Offset(r.right, yAt(i)), line);
    }
    final rows = studioLabelStride(figures.length, (every) {
      var floor = size.height;
      for (var i = 0; i < figures.length; i += every) {
        final p = figures[i];
        final above = yAt(i) - p.height / 2;
        if (r.left - StudioSpacing.small - p.width < 0 ||
            above < 0 ||
            above + p.height > floor) {
          return false;
        }
        floor = above - StudioSpacing.tight;
      }
      return true;
    });
    if (rows != null) {
      for (var i = 0; i < figures.length; i += rows) {
        final p = figures[i];
        p.paint(
          canvas,
          Offset(r.left - StudioSpacing.small - p.width, yAt(i) - p.height / 2),
        );
      }
    }
    for (final p in figures) {
      p.dispose();
    }
    // The steps' labels: every one, or every other, every third...,
    // evenly, so no two kept stand closer than a word's space.
    final n = labels.length;
    final names = [for (final l in labels) _words(l, color: c.onReadoutMuted)];
    double leftOf(int i) => (xOf(r, i, between: between) - names[i].width / 2)
        .clamp(0.0, math.max(0.0, size.width - names[i].width))
        .toDouble();
    for (var i = 0; i < n; i++) {
      final x = xOf(r, i, between: between);
      canvas.drawLine(Offset(x, r.top), Offset(x, r.bottom), dash);
    }
    final steps = studioLabelStride(n, (every) {
      final kept = [for (var i = 0; i < n; i += every) i]
        ..sort((a, b) => leftOf(a).compareTo(leftOf(b)));
      var end = double.negativeInfinity;
      for (final i in kept) {
        if (names[i].height > size.height - r.bottom ||
            names[i].width > size.width ||
            leftOf(i) < end) {
          return false;
        }
        end = leftOf(i) + names[i].width + _labelGap;
      }
      return true;
    });
    if (steps != null) {
      for (var i = 0; i < n; i += steps) {
        names[i].paint(
          canvas,
          Offset(leftOf(i), size.height - names[i].height),
        );
      }
    }
    for (final p in names) {
      p.dispose();
    }
  }

  double xOf(Rect r, int i, {required bool between}) {
    final n = labels.length;
    final rtl = direction == TextDirection.rtl;
    final f = between
        ? (i + 0.5) / n
        : n == 1
        ? 0.5
        : i / (n - 1);
    return rtl ? r.right - r.width * f : r.left + r.width * f;
  }

  double yOf(Rect r, double v) => r.bottom - r.height * (v / top).clamp(0, 1);

  @override
  bool shouldRepaint(_AxesPainter old) =>
      old.colors != colors ||
      old.text != text ||
      !listEquals(old.labels, labels) ||
      old.series != series ||
      old.direction != direction ||
      old.words != words;
}

class _LinePainter extends _AxesPainter {
  _LinePainter({
    required super.colors,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
    required this.area,
  });

  final bool area;

  @override
  void paint(Canvas canvas, Size size) {
    final r = plot(size, between: false);
    paintGrid(canvas, size, r, between: false);
    for (final (si, s) in series.indexed) {
      final light = _lightOf(colors, si, s.color);
      final path = Path();
      for (final (i, v) in s.values.indexed) {
        final p = Offset(xOf(r, i, between: false), yOf(r, v));
        if (i == 0) {
          path.moveTo(p.dx, p.dy);
        } else {
          path.lineTo(p.dx, p.dy);
        }
      }
      if (area && s.values.isNotEmpty) {
        final fill = Path.from(path)
          ..lineTo(xOf(r, s.values.length - 1, between: false), r.bottom)
          ..lineTo(xOf(r, 0, between: false), r.bottom)
          ..close();
        canvas.drawPath(
          fill,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                light.withValues(alpha: 0.32),
                light.withValues(alpha: 0.02),
              ],
            ).createShader(r),
        );
      }
      // The trace's glow, then the trace.
      canvas
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeJoin = StrokeJoin.round
            ..color = light.withValues(alpha: 0.28)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        )
        ..drawPath(
          path,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..strokeJoin = StrokeJoin.round
            ..strokeCap = StrokeCap.round
            ..color = light,
        );
      for (final (i, v) in s.values.indexed) {
        canvas.drawCircle(
          Offset(xOf(r, i, between: false), yOf(r, v)),
          2.5,
          Paint()..color = light,
        );
      }
    }
  }
}

class _BarPainter extends _AxesPainter {
  _BarPainter({
    required super.colors,
    required super.text,
    required super.labels,
    required super.series,
    required super.direction,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final r = plot(size);
    paintGrid(canvas, size, r, between: true);
    final n = labels.length;
    if (n == 0) return;
    final slot = r.width / n;
    final group = slot * 0.62;
    final each = group / series.length;
    for (final (si, s) in series.indexed) {
      final light = _lightOf(colors, si, s.color);
      for (final (i, v) in s.values.indexed) {
        final centre = xOf(r, i, between: true);
        final rtl = direction == TextDirection.rtl;
        final left =
            centre - group / 2 + each * (rtl ? series.length - 1 - si : si);
        final bar = Rect.fromLTRB(
          left + 1,
          yOf(r, v),
          left + each - 1,
          r.bottom,
        );
        // A bar is a stack of lit segments, as a level meter.
        const seg = 4.0;
        for (var y = bar.bottom - seg; y >= bar.top - 0.5; y -= seg + 1.5) {
          final cell = Rect.fromLTRB(bar.left, y, bar.right, y + seg);
          canvas
            ..drawRect(
              cell.inflate(1),
              Paint()
                ..color = light.withValues(alpha: 0.25)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
            )
            ..drawRect(cell, Paint()..color = light);
        }
      }
    }
  }
}

abstract class _AxesChart extends StatelessWidget {
  const _AxesChart({
    super.key,
    required this.labels,
    required this.series,
    required this.semanticLabel,
    this.height = 220,
  });

  final List<String> labels;
  final List<StudioSeries> series;
  final String semanticLabel;
  final double height;

  CustomPainter painter(
    StudioColors c,
    TextStyle text,
    TextDirection direction,
  );

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final text = theme.textTheme.caption.copyWith(
      locale: Localizations.maybeLocaleOf(context),
      fontSize: MediaQuery.textScalerOf(context).scale(11),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final readOut = [
      for (final s in series)
        '${s.label}: ${[for (final (i, v) in s.values.indexed) '${i < labels.length ? labels[i] : i} ${_figure(words, v)}'].join(', ')}',
    ].join('. ');
    final scope = painter(c, text, Directionality.of(context));
    if (scope is _AxesPainter) scope.words = words;
    return _Scope(
      semanticLabel: semanticLabel,
      readOut: readOut,
      height: height,
      legend: [
        for (final (i, s) in series.indexed) (s.label, _lightOf(c, i, s.color)),
      ],
      chart: CustomPaint(size: Size.infinite, painter: scope),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('semanticLabel', semanticLabel))
      ..add(IntProperty('series', series.length));
  }
}

/// Values over steps as traces of light: each series a glowing line with
/// a dot at each step, on the scope's graticule.
///
/// ```dart
/// StudioLineChart(semanticLabel: 'Plays by day', labels: const ['Mon', 'Tue', 'Wed'], series: const [StudioSeries('Plays', [120, 180, 150])])
/// ```
class StudioLineChart extends _AxesChart {
  /// A line chart.
  const StudioLineChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height,
  });

  @override
  CustomPainter painter(StudioColors c, TextStyle text, TextDirection d) =>
      _LinePainter(
        colors: c,
        text: text,
        labels: labels,
        series: series,
        direction: d,
        area: false,
      );
}

/// Values over steps as traces with the glass under them glowing faintly
/// down to the base line.
///
/// ```dart
/// StudioAreaChart(semanticLabel: 'Listeners', labels: days, series: [StudioSeries('Listeners', listeners)])
/// ```
class StudioAreaChart extends _AxesChart {
  /// An area chart.
  const StudioAreaChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height,
  });

  @override
  CustomPainter painter(StudioColors c, TextStyle text, TextDirection d) =>
      _LinePainter(
        colors: c,
        text: text,
        labels: labels,
        series: series,
        direction: d,
        area: true,
      );
}

/// Values per step as columns of lit segments, as level meters stand.
///
/// ```dart
/// StudioBarChart(semanticLabel: 'Downloads by episode', labels: const ['1', '2', '3'], series: const [StudioSeries('Downloads', [340, 410, 290])])
/// ```
class StudioBarChart extends _AxesChart {
  /// A bar chart.
  const StudioBarChart({
    super.key,
    required super.labels,
    required super.series,
    required super.semanticLabel,
    super.height,
  });

  @override
  CustomPainter painter(StudioColors c, TextStyle text, TextDirection d) =>
      _BarPainter(
        colors: c,
        text: text,
        labels: labels,
        series: series,
        direction: d,
      );
}

/// A share of a [StudioPieChart].
@immutable
class StudioSlice {
  /// [value] under [label].
  const StudioSlice(this.label, this.value, {this.color});

  /// Its name.
  final String label;

  /// Its amount.
  final double value;

  /// Its light; by default by its place.
  final Color? color;
}

/// Shares of a whole as lit arcs round a ring on the scope's glass, a fine
/// gap between them, the total in a readout in the middle.
///
/// ```dart
/// StudioPieChart(semanticLabel: 'Listening by device', slices: const [StudioSlice('Phone', 62), StudioSlice('Desktop', 28), StudioSlice('Speaker', 10)])
/// ```
class StudioPieChart extends StatelessWidget {
  /// A ring of [slices].
  const StudioPieChart({
    super.key,
    required this.slices,
    required this.semanticLabel,
    this.size = 200,
    this.centerLabel,
  });

  /// The shares.
  final List<StudioSlice> slices;

  /// What a screen reader calls it.
  final String semanticLabel;

  /// The ring's diameter.
  final double size;

  /// What the middle reads; the total when null.
  final String? centerLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final total = slices.fold<double>(0, (a, s) => a + s.value);
    final readOut = [
      for (final s in slices)
        '${s.label} ${total == 0 ? 0 : (s.value / total * 100).round()}%',
    ].join(', ');
    return _Scope(
      semanticLabel: semanticLabel,
      readOut: readOut,
      height: size + StudioSpacing.medium * 2,
      legend: [
        for (final (i, s) in slices.indexed) (s.label, _lightOf(c, i, s.color)),
      ],
      chart: Center(
        child: SizedBox.square(
          dimension: size - StudioSpacing.small,
          child: CustomPaint(
            painter: _RingPainter(
              values: [for (final s in slices) s.value],
              lights: [
                for (final (i, s) in slices.indexed) _lightOf(c, i, s.color),
              ],
              track: c.onReadout.withValues(alpha: 0.08),
            ),
            child: Center(
              child: Text(
                centerLabel ?? _figure(words, total),
                style: theme.textTheme.readout.copyWith(
                  color: c.readoutLit,
                  fontSize: 22,
                  shadows: c.readoutGlow(c.readoutLit, alpha: 0.5),
                ),
              ),
            ),
          ),
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

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.values,
    required this.lights,
    required this.track,
  });

  final List<double> values;
  final List<Color> lights;
  final Color track;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final width = r * 0.22;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: r - width / 2 - 3,
    );
    canvas.drawArc(
      rect,
      0,
      math.pi * 2,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..color = track,
    );
    final total = values.fold<double>(0, (a, v) => a + v);
    if (total <= 0) return;
    const gap = 0.035;
    var start = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      final sweep = math.pi * 2 * v / total;
      if (sweep > gap * 2) {
        final from = start + gap / 2;
        void arc(Rect rr, Paint p) =>
            canvas.drawArc(rr, from, sweep - gap, false, p);
        arc(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width + 4
            ..color = lights[i].withValues(alpha: 0.25)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
        );
        arc(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = width
            ..color = lights[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      !listEquals(old.values, values) ||
      !listEquals(old.lights, lights) ||
      old.track != track;
}

/// A small trace with no frame, for a figure's trend beside it (in a row,
/// a readout). The last point is a lit dot.
///
/// ```dart
/// StudioSparkline(values: const [3, 5, 4, 8, 7, 11], semanticLabel: 'Plays this week, rising')
/// ```
class StudioSparkline extends StatelessWidget {
  /// A sparkline of [values].
  const StudioSparkline({
    super.key,
    required this.values,
    required this.semanticLabel,
    this.width = 96,
    this.height = 28,
    this.color,
  });

  /// The values, in order.
  final List<double> values;

  /// What a screen reader hears.
  final String semanticLabel;

  /// Its width.
  final double width;

  /// Its height.
  final double height;

  /// Its light; the indicator when null.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values,
            color ?? c.indicator,
            Directionality.of(context) == TextDirection.rtl,
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
  _SparkPainter(this.values, this.light, this.rtl);

  final List<double> values;
  final Color light;
  final bool rtl;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final lo = values.reduce(math.min);
    final hi = values.reduce(math.max);
    final span = hi - lo == 0 ? 1 : hi - lo;
    Offset at(int i) {
      final f = i / (values.length - 1);
      final x = (rtl ? 1 - f : f) * (size.width - 6) + 3;
      final y = size.height - 3 - (values[i] - lo) / span * (size.height - 6);
      return Offset(x, y);
    }

    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = light.withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      )
      ..drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.75
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round
          ..color = light,
      )
      ..drawCircle(at(values.length - 1), 2.75, Paint()..color = light);
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(old.values, values) || old.light != light || old.rtl != rtl;
}
