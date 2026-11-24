// Line, area and donut charts in Fluent 2's data hues, to common chart mark specs: 2 lines, 8 markers ringed in the
// ground, 2 gaps between fills, recessive grid and axes, words in the text inks, a legend for two series or more and a
// crosshair with a value card under the pointer.
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import 'package:ui_core/ui_core.dart';

import '../../internal/figure.dart';
import '../../internal/key_focus.dart';
import '../../internal/measure.dart';
import '../../localizations.dart';
import '../../theme.dart';
import 'charts.dart';

/// One line or area of a [Fluent2LineChart] or [Fluent2AreaChart].
///
/// ```dart
/// Fluent2ChartSeries('Sent', const [3, 5, 4, 7])
/// ```
@immutable
class Fluent2ChartSeries {
  /// A series called [name].
  const Fluent2ChartSeries(this.name, this.values, {this.hue});

  /// What it is; its legend entry and its card's line.
  final String name;

  /// Its value at each label, the same count as the chart's labels.
  final List<double> values;

  /// Its colour; null takes the next of the fixed order, or the brand when it
  /// stands alone.
  final Fluent2ChartHue? hue;
}

/// The round number at or over [v].
double _niceTop(double v) {
  if (v <= 0) return 1;
  final power = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  final f = v / power;
  // The first round top over the peak whose half is round too (25 tops at
  // 30, not 50), so the plot fills its height.
  const steps = [1, 2, 3, 4, 5, 6, 8, 10];
  return steps.firstWhere((s) => f <= s) * power;
}

Color _hueOf(Fluent2ThemeData t, Fluent2ChartSeries s, int i, int count) =>
    (s.hue ??
            (count == 1
                ? Fluent2ChartHue.brand
                : Fluent2ChartHue.categorical[i %
                      Fluent2ChartHue.categorical.length]))
        .of(t);

class _Swatch extends StatelessWidget {
  const _Swatch(this.color);

  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
  );
}

class _Plot extends StatelessWidget {
  const _Plot({
    required this.series,
    required this.labels,
    required this.area,
    required this.height,
    required this.label,
    required this.valueLabel,
    required this.ground,
  });

  final List<Fluent2ChartSeries> series;
  final List<String> labels;
  final bool area;
  final double height;
  final String? label;
  final String Function(double value)? valueLabel;
  final Color? ground;

  String _say(BuildContext context, double v) =>
      valueLabel?.call(v) ?? fluent2Figure(context, v);

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final colors = [
      for (final (i, s) in series.indexed) _hueOf(t, s, i, series.length),
    ];
    var high = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        high = math.max(high, v);
      }
    }
    // Fluent's value axis: three lines, the top a round number over the peak
    // whose half is round too, so the plot fills its height.
    final top = _niceTop(high);
    final scaler = MediaQuery.textScalerOf(context);
    final dir = Directionality.of(context);
    final tick = t.caption1.tabular.c(t.textTertiary);
    double widthOf(String words, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: dir,
        textScaler: scaler,
      )..layout();
      final w = p.width;
      p.dispose();
      return w;
    }

    // Fluent's three lines label the value axis; ui_core measures their
    // words and keeps that room at the reading start.
    final yTicks = [
      for (final v in [top, top / 2, 0.0])
        RawScaleTick(value: v, position: v, label: _say(context, v)),
    ];
    final ticks = [for (final y in yTicks) y.label];
    final left =
        RawScaleTick.widestLabel(
          yTicks,
          style: tick,
          textScaler: scaler,
          textDirection: dir,
        ) +
        Fluent2Spacing.s;
    final direct = series.length >= 2 && series.length <= 4;
    final summary = [
      for (final s in series)
        if (s.values.isNotEmpty)
          '${s.name}, from ${_say(context, s.values.first)} to '
              '${_say(context, s.values.last)}',
    ].join('. ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (series.length >= 2)
          // The chart says its series' names itself.
          ExcludeSemantics(
            child: Padding(
              padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
              child: Wrap(
                spacing: Fluent2Spacing.m,
                runSpacing: Fluent2Spacing.xxs,
                children: [
                  for (final (i, s) in series.indexed)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: Fluent2Spacing.xs,
                      children: [
                        _Swatch(colors[i]),
                        Text(s.name, style: t.caption1.c(t.textSecondary)),
                      ],
                    ),
                ],
              ),
            ),
          ),
        SizedBox(
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final width = box.maxWidth;
              final room = direct && width >= 360
                  ? math.min(
                      96.0,
                      series
                              .map((s) => widthOf(s.name, t.caption1))
                              .reduce(math.max) +
                          Fluent2Spacing.s,
                    )
                  : Fluent2Spacing.xs;
              // ui_core's chart picks the point (a pointer along the run, a
              // finger's scrub, a tap held, the keys) and says it; Fluent's
              // painter draws the run, its value axis, the crosshair and
              // the card.
              return RawChart(
                semanticLabel:
                    label ?? [for (final s in series) s.name].join(', '),
                semanticSummary: summary,
                series: [
                  for (final s in series)
                    RawChartSeries(
                      label: s.name,
                      points: [
                        for (final (i, v) in s.values.indexed)
                          RawChartPoint(i.toDouble(), v),
                      ],
                    ),
                ],
                formatX: (x) {
                  final i = x.round();
                  return i >= 0 && i < labels.length
                      ? labels[i]
                      : fluent2Figure(context, x);
                },
                formatY: (v) => _say(context, v),
                padding: EdgeInsetsDirectional.only(end: room),
                yLabelGutter: (_) => left,
                builder: (context, chart) {
                  final at = chart.active?.index;
                  final drawn = [
                    for (final (i, s) in series.indexed)
                      Fluent2ChartSeries(s.name, [
                        for (final p in chart.series[i].points) p.y ?? 0,
                      ], hue: s.hue),
                  ];
                  return Fluent2KeyRing(
                    focused: chart.states.contains(WidgetState.focused),
                    radius: Fluent2Radius.medium,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PlotPainter(
                              series: drawn,
                              labels: labels,
                              colors: colors,
                              top: top,
                              ticks: ticks,
                              area: area,
                              left: left,
                              right: room,
                              at: at,
                              grid: t.colors.neutralStroke2,
                              cross: t.colors.neutralStrokeAccessible,
                              ground: ground ?? t.surface,
                              tick: tick,
                              name: t.caption1.c(t.textSecondary),
                              scaler: scaler,
                              direction: dir,
                              direct: room > Fluent2Spacing.xs,
                            ),
                          ),
                        ),
                        if (at != null && at < labels.length)
                          _Card(
                            x: _xOf(at, width, left, room, dir),
                            width: width,
                            title: labels[at],
                            lines: [
                              for (final (i, s) in series.indexed)
                                if (at < s.values.length)
                                  (
                                    colors[i],
                                    s.name,
                                    _say(context, s.values[at]),
                                  ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  double _xOf(
    int i,
    double width,
    double left,
    double right,
    TextDirection direction,
  ) {
    final n = labels.length;
    final room = width - left - right;
    final x = n == 1 ? left + room / 2 : left + room * i / (n - 1);
    return direction == TextDirection.rtl ? width - x : x;
  }
}

class _Card extends StatelessWidget {
  const _Card({
    required this.x,
    required this.width,
    required this.title,
    required this.lines,
  });

  final double x;
  final double width;
  final String title;
  final List<(Color, String, String)> lines;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    const padding = Fluent2Spacing.s;
    const swatchAndGaps = 8 + 2 * Fluent2Spacing.xs;
    final nameStyle = t.caption1.c(t.textSecondary);
    final valueStyle = t.caption1.tabular;
    final rowWidths = [
      for (final (_, name, value) in lines)
        swatchAndGaps +
            fluent2WordsWidth(context, [name], nameStyle) +
            fluent2WordsWidth(context, [value], valueStyle),
    ];
    final contentWidth = [
      fluent2WordsWidth(context, [title], t.caption1Strong),
      ...rowWidths,
    ].reduce(math.max);
    const insets = 2 * (padding + 1); // Padding and the card's border.
    final cardWidth = math.min(width, math.max(150.0, contentWidth + insets));
    // Beside the crosshair, past it in the reading direction where there is
    // the room (right to left, to its left), else before it.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final right = x + Fluent2Spacing.s;
    final left = x - Fluent2Spacing.s - cardWidth;
    final at = rtl
        ? (left >= 0 ? left : right)
        : (right + cardWidth <= width ? right : left);
    return Positioned(
      left: at.clamp(0.0, width - cardWidth),
      top: 0,
      width: cardWidth,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: t.colors.neutralBackground1,
            borderRadius: BorderRadius.circular(Fluent2Radius.medium),
            border: Border.all(
              color: t.isDark
                  ? t.colors.neutralStroke2
                  : t.colors.transparentStroke,
            ),
            boxShadow: t.shadows.shadow8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Fluent2Spacing.xxs,
            children: [
              Text(title, style: t.caption1Strong),
              for (final (i, (color, name, value)) in lines.indexed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      spacing: Fluent2Spacing.xs,
                      children: [
                        _Swatch(color),
                        Expanded(child: Text(name, style: nameStyle)),
                        if (rowWidths[i] <= cardWidth - insets)
                          Text(value, style: valueStyle),
                      ],
                    ),
                    if (rowWidths[i] > cardWidth - insets)
                      Text(value, style: valueStyle),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlotPainter extends CustomPainter {
  _PlotPainter({
    required this.series,
    required this.labels,
    required this.colors,
    required this.top,
    required this.ticks,
    required this.area,
    required this.left,
    required this.right,
    required this.at,
    required this.grid,
    required this.cross,
    required this.ground,
    required this.tick,
    required this.name,
    required this.scaler,
    required this.direction,
    required this.direct,
  });

  final List<Fluent2ChartSeries> series;
  final List<String> labels;
  final List<Color> colors;
  final double top;
  final List<String> ticks;
  final bool area;
  final double left;
  final double right;
  final int? at;
  final Color grid;
  final Color cross;
  final Color ground;
  final TextStyle tick;
  final TextStyle name;
  final TextScaler scaler;
  final TextDirection direction;
  final bool direct;

  TextPainter _text(String words, TextStyle style) => TextPainter(
    text: TextSpan(text: words, style: style),
    textDirection: direction,
    textScaler: scaler,
    maxLines: 1,
  )..layout();

  /// What [read] takes from [words]' painter, the painter disposed.
  double _measure(
    String words,
    TextStyle style,
    double Function(TextPainter painter) read,
  ) {
    final p = _text(words, style);
    final value = read(p);
    p.dispose();
    return value;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final axis = _measure('0', tick, (p) => p.height);
    // The run's names stand below the base line by at least half a label, so
    // the lowest value label, centred on that line, never meets the first.
    final drop = math.max(Fluent2Spacing.s, axis / 2);
    final bottom = size.height - axis - drop;
    final topY = axis / 2;
    final h = math.max(1.0, bottom - topY);
    final w = math.max(1.0, size.width - left - right);
    final n = labels.length;
    // Right to left the chart mirrors, as Fluent's charts do: the run starts
    // at the right, the value axis stands at the right and the line names
    // at the left. [at] is laid out left to right; [mx] mirrors an x, [tx] a
    // label's left edge.
    final rtl = direction == TextDirection.rtl;
    double mx(double v) => rtl ? size.width - v : v;
    double tx(double v, double width) => rtl ? size.width - v - width : v;
    double x(int i) => mx(n <= 1 ? left + w / 2 : left + w * i / (n - 1));
    double y(double v) => bottom - h * (v / top).clamp(0.0, 1.0);
    final line = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var i = 0; i < 3; i++) {
      final gy = topY + h * i / 2;
      canvas.drawLine(Offset(mx(left), gy), Offset(mx(left + w), gy), line);
      final p = _text(ticks[i], tick);
      p.paint(
        canvas,
        Offset(
          tx(left - Fluent2Spacing.s - p.width, p.width),
          gy - p.height / 2,
        ),
      );
      p.dispose();
    }
    // As many axis labels as fit, always the first and last.
    if (n > 0) {
      final widest = labels
          .map((l) => _measure(l, tick, (p) => p.width))
          .reduce(math.max);
      final fits = n <= 1 ? 1 : (w / (widest + Fluent2Spacing.m)).floor();
      final every = math.max(1, ((n - 1) / math.max(1, fits - 1)).ceil());
      final last = n - 1;
      // The last label always stands; when it falls off the stride, the
      // stride's label before it (nearer than a stride) gives way to it.
      final yields = last % every == 0 ? -1 : last - last % every;
      for (var i = 0; i < n; i++) {
        if (i % every != 0 && i != last) continue;
        if (i == yields && i != 0) continue;
        final p = _text(labels[i], tick);
        final dx = (x(i) - p.width / 2).clamp(0.0, size.width - p.width);
        p.paint(canvas, Offset(dx, bottom + drop));
        p.dispose();
      }
    }
    final held = at;
    if (held != null && n > 0) {
      canvas.drawLine(
        Offset(x(held), topY),
        Offset(x(held), bottom),
        Paint()
          ..color = cross
          ..strokeWidth = 1,
      );
    }
    final ends = <(double, String)>[];
    for (final (i, s) in series.indexed) {
      if (s.values.isEmpty) continue;
      final path = Path()..moveTo(x(0), y(s.values.first));
      for (var j = 1; j < s.values.length; j++) {
        path.lineTo(x(j), y(s.values[j]));
      }
      if (area && s.values.length > 1) {
        final wash = Path.from(path)
          ..lineTo(x(s.values.length - 1), bottom)
          ..lineTo(x(0), bottom)
          ..close();
        canvas.drawPath(
          wash,
          Paint()..color = colors[i].withValues(alpha: .16),
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = colors[i],
      );
      final last = s.values.length - 1;
      final mark = held != null && held <= last ? held : last;
      final point = Offset(x(mark), y(s.values[mark]));
      canvas.drawCircle(point, 6, Paint()..color = ground);
      canvas.drawCircle(point, 4, Paint()..color = colors[i]);
      ends.add((y(s.values[last]), s.name));
    }
    if (direct) {
      ends.sort((a, b) => a.$1.compareTo(b.$1));
      var floor = double.negativeInfinity;
      for (final (ey, words) in ends) {
        final p = _text(words, name);
        final py = math.max(ey - p.height / 2, floor);
        p.paint(canvas, Offset(tx(left + w + Fluent2Spacing.s, p.width), py));
        floor = py + p.height;
        p.dispose();
      }
    }
  }

  @override
  bool shouldRepaint(_PlotPainter old) =>
      old.at != at ||
      old.area != area ||
      old.top != top ||
      old.left != left ||
      old.right != right ||
      old.ground != ground ||
      old.grid != grid ||
      old.cross != cross ||
      old.tick != tick ||
      old.name != name ||
      old.scaler != scaler ||
      old.direction != direction ||
      old.direct != direct ||
      !identical(old.series, series) ||
      !identical(old.labels, labels) ||
      !_sameColors(old.colors, colors);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Lines across a shared run of [labels]: one axis from zero, a recessive
/// grid, 2 lines in the data hues, the last or the hovered point marked with an
/// 8 dot ringed in the ground. Two or more series get a legend, and up to four
/// their names at the line ends. Hover or a drag shows a crosshair and a card
/// of the values. Read as [label], then where each series starts and ends.
///
/// ```dart
/// Fluent2LineChart(label: 'Files shared', labels: const ['Mon', 'Tue', 'Wed'], series: const [Fluent2ChartSeries('You', [3, 5, 4])])
/// ```
class Fluent2LineChart extends StatelessWidget {
  /// A chart of [series] over [labels].
  const Fluent2LineChart({
    super.key,
    required this.series,
    required this.labels,
    this.label,
    this.height = 200,
    this.valueLabel,
    this.ground,
  });

  /// The lines.
  final List<Fluent2ChartSeries> series;

  /// The run along the bottom.
  final List<String> labels;

  /// What it shows.
  final String? label;

  /// The plot's height, axis labels included.
  final double height;

  /// A value's words; null says the number.
  final String Function(double value)? valueLabel;

  /// The colour it stands on (the marks' ring); null is the surface.
  final Color? ground;

  @override
  Widget build(BuildContext context) => _Plot(
    series: series,
    labels: labels,
    area: false,
    height: height,
    label: label,
    valueLabel: valueLabel,
    ground: ground,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2ChartSeries>('series', series))
      ..add(IterableProperty<String>('labels', labels))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: 200))
      ..add(
        ObjectFlagProperty<String Function(double value)?>.has(
          'valueLabel',
          valueLabel,
        ),
      )
      ..add(ColorProperty('ground', ground, defaultValue: null));
  }
}

/// [Fluent2LineChart] with each line washed down to the baseline at 16% of its
/// hue: how much, more than where it went.
///
/// ```dart
/// Fluent2AreaChart(label: 'Storage used', labels: const ['Jan', 'Feb', 'Mar'], series: const [Fluent2ChartSeries('Used', [12, 18, 21])])
/// ```
class Fluent2AreaChart extends StatelessWidget {
  /// A chart of [series] over [labels].
  const Fluent2AreaChart({
    super.key,
    required this.series,
    required this.labels,
    this.label,
    this.height = 200,
    this.valueLabel,
    this.ground,
  });

  /// The areas.
  final List<Fluent2ChartSeries> series;

  /// The run along the bottom.
  final List<String> labels;

  /// What it shows.
  final String? label;

  /// The plot's height, axis labels included.
  final double height;

  /// A value's words; null says the number.
  final String Function(double value)? valueLabel;

  /// The colour it stands on (the marks' ring); null is the surface.
  final Color? ground;

  @override
  Widget build(BuildContext context) => _Plot(
    series: series,
    labels: labels,
    area: true,
    height: height,
    label: label,
    valueLabel: valueLabel,
    ground: ground,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2ChartSeries>('series', series))
      ..add(IterableProperty<String>('labels', labels))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DoubleProperty('height', height, defaultValue: 200))
      ..add(
        ObjectFlagProperty<String Function(double value)?>.has(
          'valueLabel',
          valueLabel,
        ),
      )
      ..add(ColorProperty('ground', ground, defaultValue: null));
  }
}

/// One part of a [Fluent2PieChart].
///
/// ```dart
/// Fluent2PieSlice('Documents', 40)
/// ```
@immutable
class Fluent2PieSlice {
  /// A part called [label], worth [value].
  const Fluent2PieSlice(this.label, this.value, {this.valueText, this.hue})
    : assert(value >= 0, 'a slice is never negative');

  /// What it is.
  final String label;

  /// Its share, against the others'.
  final double value;

  /// Its value's words; null says the number.
  final String? valueText;

  /// Its colour; null takes the next of the fixed order.
  final Fluent2ChartHue? hue;
}

/// Parts of a whole as a donut: the data hues in fixed order with 2 gaps
/// between them, past five parts the rest folded into a neutral "Other", a
/// legend of every part with its value beside it. The pointer on a part sets
/// the others back and says it in the hole. Read as [label], then each part.
///
/// ```dart
/// Fluent2PieChart(label: 'Storage', slices: const [Fluent2PieSlice('Documents', 40), Fluent2PieSlice('Photos', 25)])
/// ```
class Fluent2PieChart extends StatefulWidget {
  /// A donut of [slices].
  const Fluent2PieChart({
    super.key,
    required this.slices,
    this.label,
    this.size = 160,
    this.thickness = 24,
    this.center,
    this.ground,
  });

  /// The parts, largest first reads best.
  final List<Fluent2PieSlice> slices;

  /// What it shows.
  final String? label;

  /// The donut's side.
  final double size;

  /// The ring's thickness.
  final double thickness;

  /// What stands in the hole when nothing is hovered.
  final Widget? center;

  /// The colour it stands on; null is the surface.
  final Color? ground;

  @override
  State<Fluent2PieChart> createState() => _Fluent2PieChartState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<Fluent2PieSlice>('slices', slices))
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DoubleProperty('size', size, defaultValue: 160))
      ..add(DoubleProperty('thickness', thickness, defaultValue: 24))
      ..add(ColorProperty('ground', ground, defaultValue: null));
  }
}

class _Fluent2PieChartState extends State<Fluent2PieChart> {
  String _text(Fluent2PieSlice s) =>
      s.valueText ?? fluent2Figure(context, s.value);

  List<Fluent2PieSlice> _parts(String other) {
    final all = widget.slices;
    if (all.length <= 5) return all;
    final rest = all.skip(4).fold<double>(0, (a, s) => a + s.value);
    return [
      ...all.take(4),
      Fluent2PieSlice(other, rest, hue: Fluent2ChartHue.neutral),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final parts = _parts(Fluent2Localizations.of(context).other);
    final colors = [
      for (final (i, s) in parts.indexed)
        (s.hue ?? Fluent2ChartHue.categorical[i]).of(t),
    ];
    final summary = [for (final s in parts) '${s.label} ${_text(s)}']
        .join(', ');
    // ui_core's pie picks the part (under a pointer or a finger, the keys)
    // and says it; Fluent's painter draws the ring and the words in its hole.
    final donut = SizedBox.square(
      dimension: widget.size,
      child: RawPieChart(
        semanticLabel:
            widget.label ?? [for (final s in parts) s.label].join(', '),
        semanticSummary: summary,
        slices: [
          for (final s in parts)
            RawPieSlice(label: s.label, value: math.max(0, s.value)),
        ],
        holeRadius:
            math.max(0, widget.size / 2 - widget.thickness) / (widget.size / 2),
        formatValue: (v) {
          for (final s in parts) {
            if (s.value == v) return _text(s);
          }
          return fluent2Figure(context, v);
        },
        builder: (context, pie) {
          final at = pie.active;
          return Fluent2KeyRing(
            focused: pie.states.contains(WidgetState.focused),
            radius: widget.size / 2,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DonutPainter(
                      slices: pie.slices,
                      colors: colors,
                      thickness: widget.thickness,
                      at: at,
                    ),
                  ),
                ),
                // The words in the hole stay inside it: drawn smaller, whole,
                // where a large text size would carry them onto the ring.
                SizedBox.square(
                  dimension: math.max(
                    0,
                    (widget.size - 2 * (widget.thickness + Fluent2Spacing.xs)) /
                        math.sqrt2,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: at != null && at < parts.length
                        ? Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _text(parts[at]),
                                style: t.subtitle2.tabular,
                              ),
                              Text(
                                parts[at].label,
                                maxLines: 1,
                                style: t.caption1.c(t.textSecondary),
                              ),
                            ],
                          )
                        : widget.center ?? const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    final legend = ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: Fluent2Spacing.xs,
        children: [
          for (final (i, s) in parts.indexed)
            Row(
              spacing: Fluent2Spacing.s,
              children: [
                _Swatch(colors[i]),
                Expanded(
                  child: Text(
                    s.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: t.caption1.c(t.textSecondary),
                  ),
                ),
                Text(_text(s), style: t.caption1.tabular),
              ],
            ),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, box) {
        // The legend stands beside the donut while its words have their
        // room at the reader's text size, else under it, never cut.
        final beside =
            !box.hasBoundedWidth ||
            box.maxWidth >=
                widget.size + MediaQuery.textScalerOf(context).scale(160);
        if (!beside) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Fluent2Spacing.m,
            children: [
              Center(child: donut),
              legend,
            ],
          );
        }
        return Row(
          spacing: Fluent2Spacing.xl,
          children: [
            donut,
            Expanded(child: legend),
          ],
        );
      },
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.slices,
    required this.colors,
    required this.thickness,
    required this.at,
  });

  /// ui_core's slices: each part's angles from the top, clockwise (the other
  /// way right to left).
  final List<RawPieSliceDetails> slices;
  final List<Color> colors;
  final double thickness;
  final int? at;

  @override
  void paint(Canvas canvas, Size size) {
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final count = slices.where((s) => s.sweepAngle != 0).length;
    final gap = count > 1 ? 2 / r : 0.0;
    for (final (i, s) in slices.indexed) {
      final sweep = s.sweepAngle;
      if (sweep.abs() <= gap) continue;
      final g = sweep.sign * gap;
      canvas.drawArc(
        rect,
        s.startAngle + g / 2,
        sweep - g,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = thickness
          ..color = at == null || at == i
              ? colors[i]
              : colors[i].withValues(alpha: .4),
      );
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.at != at ||
      old.thickness != thickness ||
      !listEquals(old.slices, slices) ||
      !identical(old.colors, colors);
}
