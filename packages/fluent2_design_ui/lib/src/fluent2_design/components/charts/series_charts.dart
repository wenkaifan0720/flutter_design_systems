// Line, area and donut charts in Fluent 2's data hues, to common chart mark specs: 2 lines, 8 markers ringed in the
// ground, 2 gaps between fills, recessive grid and axes, words in the text inks, a legend for two series or more and a
// crosshair with a value card under the pointer.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';

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

String _plain(double v) =>
    v == v.roundToDouble() ? '${v.round()}' : v.toStringAsFixed(1);

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

class _Plot extends StatefulWidget {
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

  @override
  State<_Plot> createState() => _PlotState();
}

class _PlotState extends State<_Plot> {
  int? _at;

  String _say(double v) => widget.valueLabel?.call(v) ?? _plain(v);

  void _point(Offset local, double width, double left, double right) {
    final n = widget.labels.length;
    if (n == 0) return;
    final room = math.max(1.0, width - left - right);
    // Right to left the run starts at the right edge.
    final dx = Directionality.of(context) == TextDirection.rtl
        ? width - local.dx
        : local.dx;
    final i = n == 1 ? 0 : (((dx - left) / room) * (n - 1)).round();
    final at = i.clamp(0, n - 1);
    if (at != _at) setState(() => _at = at);
  }

  void _leave() {
    if (_at != null) setState(() => _at = null);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final series = widget.series;
    final colors = [
      for (final (i, s) in series.indexed) _hueOf(t, s, i, series.length),
    ];
    var high = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        high = math.max(high, v);
      }
    }
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

    final ticks = [top, top / 2, 0.0].map(_say).toList();
    final left =
        ticks.map((w) => widthOf(w, tick)).reduce(math.max) + Fluent2Spacing.s;
    final direct = series.length >= 2 && series.length <= 4;
    final at = _at;
    final spoken = [
      ?widget.label,
      for (final s in series)
        if (s.values.isNotEmpty)
          '${s.name}, from ${_say(s.values.first)} to ${_say(s.values.last)}',
    ].join('. ');
    return Semantics(
      label: spoken,
      image: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (series.length >= 2)
            Padding(
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
          SizedBox(
            height: widget.height,
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
                return MouseRegion(
                  onHover: (e) => _point(e.localPosition, width, left, room),
                  onExit: (_) => _leave(),
                  child: Listener(
                    // A touch points at a value: a pointer down, not a
                    // press (the chart is an image to a screen reader).
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (d) =>
                        _point(d.localPosition, width, left, room),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onHorizontalDragUpdate: (d) =>
                          _point(d.localPosition, width, left, room),
                      onHorizontalDragEnd: (_) => _leave(),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _PlotPainter(
                                series: series,
                                labels: widget.labels,
                                colors: colors,
                                top: top,
                                ticks: ticks,
                                area: widget.area,
                                left: left,
                                right: room,
                                at: at,
                                grid: t.colors.neutralStroke2,
                                cross: t.colors.neutralStrokeAccessible,
                                ground: widget.ground ?? t.surface,
                                tick: tick,
                                name: t.caption1.c(t.textSecondary),
                                scaler: scaler,
                                direction: dir,
                                direct: room > Fluent2Spacing.xs,
                              ),
                            ),
                          ),
                          if (at != null && at < widget.labels.length)
                            _Card(
                              x: _xOf(at, width, left, room),
                              width: width,
                              title: widget.labels[at],
                              lines: [
                                for (final (i, s) in series.indexed)
                                  if (at < s.values.length)
                                    (colors[i], s.name, _say(s.values[at])),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  double _xOf(int i, double width, double left, double right) {
    final n = widget.labels.length;
    final room = width - left - right;
    final x = n == 1 ? left + room / 2 : left + room * i / (n - 1);
    return Directionality.of(context) == TextDirection.rtl ? width - x : x;
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

  static const double _w = 150;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    // Beside the crosshair, on whichever side has the room.
    final opensLeft = x + Fluent2Spacing.s + _w > width;
    final at = opensLeft ? x - Fluent2Spacing.s - _w : x + Fluent2Spacing.s;
    return Positioned(
      left: at.clamp(0.0, math.max(0.0, width - _w)),
      top: 0,
      width: math.min(_w, width),
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.all(Fluent2Spacing.s),
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
              for (final (color, name, value) in lines)
                Row(
                  spacing: Fluent2Spacing.xs,
                  children: [
                    _Swatch(color),
                    Expanded(
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: t.caption1.c(t.textSecondary),
                      ),
                    ),
                    Text(value, style: t.caption1.tabular),
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

  @override
  void paint(Canvas canvas, Size size) {
    final axis = _text('0', tick).height;
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
      final widest = labels.map((l) => _text(l, tick).width).reduce(math.max);
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
}

/// One part of a [Fluent2PieChart].
///
/// ```dart
/// Fluent2PieSlice('Documents', 40)
/// ```
@immutable
class Fluent2PieSlice {
  /// A part called [label], worth [value].
  const Fluent2PieSlice(this.label, this.value, {this.valueText, this.hue});

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
}

class _Fluent2PieChartState extends State<Fluent2PieChart> {
  int? _at;

  static String _text(Fluent2PieSlice s) => s.valueText ?? _plain(s.value);

  List<Fluent2PieSlice> _parts(String other) {
    final all = widget.slices;
    if (all.length <= 5) return all;
    final rest = all.skip(4).fold<double>(0, (a, s) => a + s.value);
    return [
      ...all.take(4),
      Fluent2PieSlice(other, rest, hue: Fluent2ChartHue.neutral),
    ];
  }

  int? _hit(Offset local, List<Fluent2PieSlice> parts) {
    final c = Offset(widget.size / 2, widget.size / 2);
    final d = local - c;
    final r = d.distance;
    if (r > widget.size / 2 || r < widget.size / 2 - widget.thickness) {
      return null;
    }
    final total = parts.fold<double>(0, (a, s) => a + math.max(0, s.value));
    if (total <= 0) return null;
    var angle = math.atan2(d.dy, d.dx) + math.pi / 2;
    if (angle < 0) angle += 2 * math.pi;
    var from = 0.0;
    for (final (i, s) in parts.indexed) {
      final sweep = 2 * math.pi * math.max(0, s.value) / total;
      if (angle < from + sweep) return i;
      from += sweep;
    }
    return parts.length - 1;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final parts = _parts(Fluent2Localizations.of(context).other);
    final colors = [
      for (final (i, s) in parts.indexed)
        (s.hue ?? Fluent2ChartHue.categorical[i]).of(t),
    ];
    final at = _at;
    final spoken = [
      ?widget.label,
      for (final s in parts) '${s.label} ${_text(s)}',
    ].join(', ');
    final donut = SizedBox.square(
      dimension: widget.size,
      child: MouseRegion(
        onHover: (e) {
          final i = _hit(e.localPosition, parts);
          if (i != _at) setState(() => _at = i);
        },
        onExit: (_) => setState(() => _at = null),
        child: Listener(
          // A touch points at a slice: a pointer down, not a press.
          behavior: HitTestBehavior.opaque,
          onPointerDown: (d) {
            final i = _hit(d.localPosition, parts);
            if (i != _at) setState(() => _at = i);
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DonutPainter(
                    values: [for (final s in parts) s.value],
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
                  child: at != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_text(parts[at]), style: t.subtitle2.tabular),
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
        ),
      ),
    );
    final legend = Column(
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
    );
    return Semantics(
      label: spoken,
      image: true,
      excludeSemantics: true,
      child: LayoutBuilder(
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
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.thickness,
    required this.at,
  });

  final List<double> values;
  final List<Color> colors;
  final double thickness;
  final int? at;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (a, v) => a + math.max(0, v));
    if (total <= 0) return;
    final r = (math.min(size.width, size.height) - thickness) / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final count = values.where((v) => v > 0).length;
    final gap = count > 1 ? 2 / r : 0.0;
    var from = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      final sweep = 2 * math.pi * math.max(0, v) / total;
      if (sweep > 0) {
        canvas.drawArc(
          rect,
          from + gap / 2,
          math.max(0.0, sweep - gap),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = thickness
            ..color = at == null || at == i
                ? colors[i]
                : colors[i].withValues(alpha: .4),
        );
      }
      from += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.at != at ||
      old.thickness != thickness ||
      !identical(old.values, values) ||
      !identical(old.colors, colors);
}
