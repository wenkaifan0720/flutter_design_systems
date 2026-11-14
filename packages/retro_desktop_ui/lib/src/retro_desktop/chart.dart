import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'theme.dart';
import 'component_themes.dart';
import 'internal/face.dart';
import 'localizations.dart';
import 'layout.dart';
import 'press.dart';
import 'raised.dart' show RetroDesktopTooltipFace;

/// A named series. Missing values leave a gap in a line and no bar.
@immutable
class RetroDesktopChartSeries {
  /// Creates a [RetroDesktopChartSeries].
  RetroDesktopChartSeries(this.label, List<double?> values)
    : values = List.unmodifiable(values);

  /// The visible or accessible name of this part.
  final String label;

  /// The values plotted in their supplied order.
  final List<double?> values;
  @override
  bool operator ==(Object other) =>
      other is RetroDesktopChartSeries &&
      label == other.label &&
      listEquals(values, other.values);
  @override
  int get hashCode => Object.hash(label, Object.hashAll(values));
}

/// Straight pixel lines, hatched bars and areas, or a ringed donut; data marks
/// keep square ends, as plotted data does.
enum RetroDesktopChartType {
  /// Draws connected line series with gaps for missing values.
  line,

  /// Draws grouped bars with distinct hatch patterns.
  bar,

  /// Draws each series as a line over a hatched fill down to the baseline.
  area,

  /// Draws the first series' values as a ring, one segment per label.
  donut,
}

/// A data chart in a desktop plot well: its axes' readings, a legend, and one
/// readable summary. Pointing at the plot (or tapping it, or the arrow keys
/// once it has focus) shows the reading at that place in a tooltip. With no
/// values it says so in the well; [loading] holds the well while data comes.
///
/// ```dart
/// RetroDesktopChart(label: 'Weekly activity', series: [RetroDesktopChartSeries('Visits', [12, 18, 9])], labels: const ['Mon', 'Tue', 'Wed'])
/// ```
class RetroDesktopChart extends StatefulWidget {
  /// Creates a [RetroDesktopChart].
  RetroDesktopChart({
    super.key,
    required this.label,
    required List<RetroDesktopChartSeries> series,
    List<String> labels = const [],
    this.kind = RetroDesktopChartType.line,
    this.height = 180,
    this.format,
    this.summary,
    this.bandLow,
    this.bandHigh,
    this.loading = false,
    this.style,
  }) : series = List.unmodifiable(series),
       labels = List.unmodifiable(labels),
       assert(height > 0),
       assert((bandLow == null) == (bandHigh == null));

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;

  /// The visible or accessible name of this part.
  final String label;

  /// The named data series shown on the plot.
  final List<RetroDesktopChartSeries> series;

  /// Labels corresponding to the supplied data positions (a donut's segments).
  final List<String> labels;

  /// The visual category used to draw this item.
  final RetroDesktopChartType kind;

  /// The height in logical pixels.
  final double height;

  /// Formats a value for display and accessibility.
  final String Function(double)? format;

  /// An optional accessible summary in place of the generated one.
  final String? summary;

  /// The lower edge of the optional reference band.
  final double? bandLow;

  /// The upper edge of the optional reference band.
  final double? bandHigh;

  /// Holds the well, quietly hatched, while the data is on its way.
  final bool loading;

  @override
  State<RetroDesktopChart> createState() => _ChartState();
}

class _ChartState extends State<RetroDesktopChart> {
  int? _at;
  bool _focused = false;

  int get _count => widget.kind == RetroDesktopChartType.donut
      ? (widget.series.isEmpty ? 0 : widget.series.first.values.length)
      : widget.series.fold<int>(0, (n, s) => math.max(n, s.values.length));

  int _index(double dx, double width) {
    final n = _count;
    if (n < 1 || width <= 0) return 0;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    var share = (dx / width).clamp(0.0, 1.0);
    if (rtl) share = 1 - share;
    // Each value has its band, whatever the kind (the painter stands it in the band's middle).
    return (share * n).floor().clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    final kind = widget.kind;
    final series = widget.series;
    final labels = widget.labels;
    final style = widget.style;
    final theme = RetroDesktopTheme.of(context);
    final words = RetroDesktopLocalizations.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, theme.chartTheme], get, const {});
    final note = theme.type.note
        .merge(slot((s) => s.textStyle))
        .copyWith(color: slot((s) => s.foreground));
    // The scale stands half a value's line inside the plate at its top and
    // foot: each value then sits level with its gridline (held inside the
    // gutter, the end ones stood 8 px off theirs), and a point on the top line
    // keeps its whole dot (the area's May was cut in half by the frame).
    final pad =
        (MediaQuery.textScalerOf(context).scale(note.fontSize ?? 12) *
                (note.height ?? 1.3) /
                2)
            .ceilToDouble();
    final plotColors = theme.colors.copyWith(
      paper: slot((s) => s.fill),
      control: slot((s) => s.side)?.color ?? slot((s) => s.edge),
      tones: slot((s) => s.foreground) == null
          ? null
          : [slot((s) => s.foreground)!],
    );
    final plotInks = slot((s) => s.foreground) == null
        ? plotColors.chartTones
        : [slot((s) => s.foreground)!];
    final donut = kind == RetroDesktopChartType.donut;
    final values = [
      for (final s in donut ? series.take(1) : series)
        for (final v in s.values)
          if (v != null && v.isFinite && (!donut || v > 0)) v,
    ];
    final empty = values.isEmpty;
    var low = values.isEmpty ? 0.0 : values.reduce(math.min);
    var high = values.isEmpty ? 1.0 : values.reduce(math.max);
    if (kind != RetroDesktopChartType.line) {
      low = math.min(low, 0);
      high = math.max(high, 0);
    }
    if (widget.bandLow?.isFinite ?? false) low = math.min(low, widget.bandLow!);
    if (widget.bandHigh?.isFinite ?? false) {
      high = math.max(high, widget.bandHigh!);
    }
    if (low == high) {
      low -= 1;
      high += 1;
    }
    // The scale widens to the round values that hold the data, and every
    // gridline stands on one and is named in the gutter.
    final ticks = _roundTicks(low, high);
    low = ticks.first;
    high = ticks.last;
    String fmt(double value) =>
        widget.format?.call(value) ?? words.formatNumber(value);
    String reading(int i) {
      if (donut) {
        final v = series.first.values[i];
        final name = i < labels.length ? labels[i] : '${i + 1}';
        return '$name: ${v == null ? '–' : fmt(v)}';
      }
      final head = i < labels.length ? labels[i] : null;
      final parts = [
        for (final s in series)
          if (i < s.values.length && s.values[i] != null)
            '${s.label} ${fmt(s.values[i]!)}',
      ];
      return [?head, parts.join(', ')].join(' · ');
    }

    final read = widget.loading
        ? DesignLocalizations.of(context).loadingLabel
        : empty
        ? words.noData
        : widget.summary ??
              (donut
                  ? [for (var i = 0; i < _count; i++) reading(i)].join('; ')
                  : [
                      for (final s in series)
                        '${s.label}: ${[for (final v in s.values)
                          if (v != null && v.isFinite) fmt(v)].join(', ')}',
                    ].join('; '));
    final at = _at != null && _at! < _count && !empty && !widget.loading
        ? _at
        : null;
    final rtl = Directionality.of(context) == TextDirection.rtl;

    Widget plot = LayoutBuilder(
      builder: (context, box) => MouseRegion(
        onHover: empty || widget.loading
            ? null
            : (e) => setState(
                () => _at = _index(e.localPosition.dx, box.maxWidth),
              ),
        onExit: (_) => setState(() => _at = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: empty || widget.loading
              ? null
              : (e) => setState(() {
                  final i = _index(e.localPosition.dx, box.maxWidth);
                  _at = _at == i ? null : i;
                }),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: retroDesktopFace(
                  states: const {},
                  component: theme.chartTheme.merge(
                    RetroDesktopStyle(
                      fill: WidgetStatePropertyAll(theme.colors.paper),
                    ),
                  ),
                  style: style,
                  scale: RetroDesktopFaceScale.surface,
                  padding: EdgeInsets.zero,
                  child: widget.loading || empty
                      ? CustomPaint(
                          painter: _QuietPainter(
                            colors: plotColors,
                            hatch: widget.loading,
                          ),
                          // The words on a plate of paper: the hatch never runs through them.
                          child: Center(
                            child: ColoredBox(
                              color: plotColors.paper,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                child: Text(
                                  read,
                                  textAlign: TextAlign.center,
                                  style: theme.type.meta,
                                ),
                              ),
                            ),
                          ),
                        )
                      : CustomPaint(
                          painter: donut
                              ? _DonutPainter(
                                  values: series.first.values,
                                  inks: plotInks,
                                  colors: plotColors,
                                  at: at,
                                )
                              : _ChartPainter(
                                  series: series,
                                  kind: kind,
                                  low: low,
                                  high: high,
                                  bandLow: widget.bandLow,
                                  bandHigh: widget.bandHigh,
                                  ticks: ticks,
                                  colors: plotColors,
                                  inks: plotInks,
                                  guideWidth: theme.strokes.hairline,
                                  seriesWidth: theme.strokes.heavy,
                                  rtl: rtl,
                                  at: at,
                                  pad: pad,
                                ),
                        ),
                ),
              ),
              if (at != null)
                PositionedDirectional(
                  top: 6,
                  start: 0,
                  end: 0,
                  child: Align(
                    alignment: AlignmentDirectional(
                      donut || _count < 2
                          ? 0
                          : (kind == RetroDesktopChartType.bar
                                        ? (at + .5) / _count
                                        : at / (_count - 1)) *
                                    2 -
                                1,
                      -1,
                    ),
                    child: IgnorePointer(
                      child: RetroDesktopTooltipFace(message: reading(at)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    plot = Focus(
      canRequestFocus: !empty && !widget.loading,
      onFocusChange: (on) => setState(() {
        _focused = on;
        if (!on) _at = null;
      }),
      onKeyEvent: (_, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
          return KeyEventResult.ignored;
        }
        final key = event.logicalKey;
        final forward = rtl
            ? LogicalKeyboardKey.arrowLeft
            : LogicalKeyboardKey.arrowRight;
        final back = rtl
            ? LogicalKeyboardKey.arrowRight
            : LogicalKeyboardKey.arrowLeft;
        if (key == forward) {
          setState(() => _at = math.min(_count - 1, (_at ?? -1) + 1));
        } else if (key == back) {
          setState(() => _at = math.max(0, (_at ?? _count) - 1));
        } else if (key == LogicalKeyboardKey.escape && _at != null) {
          setState(() => _at = null);
        } else {
          return KeyEventResult.ignored;
        }
        return KeyEventResult.handled;
      },
      child: RetroDesktopHighlight(
        shape: theme.shapes.medium,
        focused:
            _focused &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional,
        child: plot,
      ),
    );
    final legend = Wrap(
      spacing: 14,
      runSpacing: 6,
      children: [
        for (final (index, name)
            in (donut
                    ? [
                        for (var i = 0; i < _count; i++)
                          i < labels.length ? labels[i] : '${i + 1}',
                      ]
                    : [for (final s in series) s.label])
                .indexed)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              retroDesktopOwnSize(
                width: 24,
                height: 14,
                child: CustomPaint(
                  painter: _LegendPainter(
                    index: index,
                    kind: kind,
                    ink: plotInks[index % plotInks.length],
                    paper: plotColors.paper,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(child: Text(name, style: note)),
            ],
          ),
      ],
    );
    // The gutter grows with the reader's text, up to its widest value (kept to 60, twice the text cut "30 GB" to
    // "30…"); a value longer than that still ends in an ellipsis rather than push the plot out.
    final most = MediaQuery.textScalerOf(context).scale(60);
    var gutter = 60.0;
    for (final v in ticks) {
      final tp = TextPainter(
        text: TextSpan(text: fmt(v), style: note),
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      gutter = math.max(gutter, tp.width.ceilToDouble() + 1);
      tp.dispose();
    }
    gutter = math.min(gutter, math.max(60.0, most));
    return Semantics(
      container: true,
      label: widget.label,
      value: at == null ? read : reading(at),
      liveRegion: at != null,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: widget.height,
            child: donut
                ? Center(child: AspectRatio(aspectRatio: 1, child: plot))
                // With nothing to scale, no gutter: the plate takes the column.
                : empty || widget.loading
                ? plot
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: gutter,
                        child: LayoutBuilder(
                          builder: (context, box) {
                            // Each value level with its gridline (the
                            // plot's lines run 1 px inside its box), the
                            // end ones held inside the gutter; a value whose
                            // words would meet those of the one below it is
                            // left unnamed, counted from the foot, so large
                            // text never stacks two values on each other.
                            final line =
                                MediaQuery.textScalerOf(context)
                                    .scale(note.fontSize ?? 12) *
                                (note.height ?? 1.3);
                            final inset = math.min(
                              pad,
                              math.max(0.0, box.maxHeight - 2) / 4,
                            );
                            final span = math.max(
                              0.0,
                              box.maxHeight - 2 - 2 * inset,
                            );
                            // How far down the plot a value stands, as
                            // the painter reckons it (a range too wide
                            // to subtract is taken by its magnitude).
                            final range = high - low;
                            final magnitude = math.max(low.abs(), high.abs());
                            double down(double v) => range.isFinite
                                ? (high - v) / range
                                : (high / magnitude - v / magnitude) /
                                      (high / magnitude - low / magnitude);
                            final room = math.max(0.0, box.maxHeight - line);
                            double top(double v) =>
                                (1 + inset + span * down(v) - line / 2).clamp(
                                  0.0,
                                  room,
                                );
                            // One stride from the foot (every value, every
                            // second, every third…): the first whose names
                            // all stand clear of each other, so the named
                            // values keep an even step.
                            var named = <double, double>{};
                            for (
                              var every = 1;
                              every <= ticks.length;
                              every++
                            ) {
                              final pick = <double, double>{};
                              var clear = true;
                              var limit = double.infinity;
                              for (var i = 0; i < ticks.length; i += every) {
                                final at = top(ticks[i]);
                                if (at + line > limit) {
                                  clear = false;
                                  break;
                                }
                                pick[ticks[i]] = at;
                                limit = at - 2;
                              }
                              named = pick;
                              if (clear) break;
                            }
                            return Stack(
                              children: [
                                for (final MapEntry(key: v, value: top)
                                    in named.entries)
                                  Positioned(
                                    left: 0,
                                    right: 0,
                                    top: top,
                                    child: Text(
                                      fmt(v),
                                      style: note,
                                      textAlign: TextAlign.end,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: plot),
                    ],
                  ),
          ),
          if (labels.isNotEmpty && !donut && !empty && !widget.loading)
            Padding(
              padding: EdgeInsetsDirectional.only(start: gutter + 8, top: 4),
              // Each name whole, on one line under its column; where the widest is wider than a column, every
              // second (or third…) one is named, so no word breaks inside itself.
              child: LayoutBuilder(
                builder: (context, box) {
                  final painters = [
                    for (final text in labels)
                      TextPainter(
                        text: TextSpan(text: text, style: note),
                        textDirection: Directionality.of(context),
                        textScaler: MediaQuery.textScalerOf(context),
                        maxLines: 1,
                      )..layout(),
                  ];
                  final widest = painters.fold(
                    0.0,
                    (w, p) => math.max(w, p.width.ceilToDouble()),
                  );
                  final tall = painters.fold(
                    0.0,
                    (h, p) => math.max(h, p.height.ceilToDouble()),
                  );
                  for (final p in painters) {
                    p.dispose();
                  }
                  final column = box.maxWidth / labels.length;
                  final every = column <= 0
                      ? labels.length
                      : math.max(1, ((widest + 6) / column).ceil());
                  return SizedBox(
                    height: tall,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        for (var i = 0; i < labels.length; i += every)
                          PositionedDirectional(
                            top: 0,
                            width: widest,
                            // Centred on its column, held off the plot's far end (it may reach into the gutter).
                            start: math.max(
                              -60,
                              math.min(
                                (i + .5) * column - widest / 2,
                                box.maxWidth - widest,
                              ),
                            ),
                            child: Text(
                              labels[i],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              softWrap: false,
                              style: note,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          if (!empty && !widget.loading) ...[const SizedBox(height: 8), legend],
        ],
      ),
    );
  }
}

/// A small line of recent values with no axes, for a row or a figure: the
/// last value marked in the highlight, as the reading now.
///
/// ```dart
/// RetroDesktopSparkline(label: 'Visits this week', values: const [3, 5, 4, 8, 6, 9, 7])
/// ```
class RetroDesktopSparkline extends StatelessWidget {
  /// Creates a [RetroDesktopSparkline].
  const RetroDesktopSparkline({
    super.key,
    required this.label,
    required this.values,
    this.width = 96,
    this.height = 24,
    this.format,
  });

  /// The line's accessible name.
  final String label;

  /// The values, oldest first; null leaves a gap.
  final List<double?> values;

  /// The size in logical pixels.
  final double width, height;

  /// Formats a value for the accessible reading.
  final String Function(double)? format;

  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final words = RetroDesktopLocalizations.of(context);
    final shown = [
      for (final v in values)
        if (v != null && v.isFinite) format?.call(v) ?? words.formatNumber(v),
    ];
    return Semantics(
      label: label,
      value: shown.isEmpty ? words.noData : shown.join(', '),
      excludeSemantics: true,
      child: retroDesktopOwnSize(
        width: width,
        height: height,
        child: CustomPaint(
          painter: _SparkPainter(
            values: values,
            ink: t.colors.textSecondary,
            now: t.colors.highlight,
            width: t.strokes.regular,
            rtl: Directionality.of(context) == TextDirection.rtl,
          ),
        ),
      ),
    );
  }
}

class _SparkPainter extends CustomPainter {
  const _SparkPainter({
    required this.values,
    required this.ink,
    required this.now,
    required this.width,
    required this.rtl,
  });
  final List<double?> values;
  final Color ink, now;
  final double width;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size size) {
    final finite = [
      for (final v in values)
        if (v != null && v.isFinite) v,
    ];
    if (finite.isEmpty || size.isEmpty) return;
    var low = finite.reduce(math.min), high = finite.reduce(math.max);
    if (low == high) {
      low -= 1;
      high += 1;
    }
    final box = (Offset.zero & size).deflate(3);
    Offset at(int i, double v) {
      final share = values.length < 2 ? .5 : i / (values.length - 1);
      return Offset(
        box.left + (rtl ? 1 - share : share) * box.width,
        box.bottom - (v - low) / (high - low) * box.height,
      );
    }

    final path = Path();
    var linked = false;
    Offset? last;
    for (final (i, v) in values.indexed) {
      if (v == null || !v.isFinite) {
        linked = false;
        continue;
      }
      final p = at(i, v);
      linked ? path.lineTo(p.dx, p.dy) : path.moveTo(p.dx, p.dy);
      linked = true;
      last = p;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = width,
    );
    if (last != null) {
      canvas.drawRect(
        Rect.fromCenter(center: last, width: 5, height: 5),
        Paint()..color = now,
      );
    }
  }

  @override
  bool shouldRepaint(_SparkPainter old) =>
      !listEquals(values, old.values) ||
      ink != old.ink ||
      now != old.now ||
      width != old.width ||
      rtl != old.rtl;
}

// An empty or loading well: the guides alone, hatched while loading.
class _QuietPainter extends CustomPainter {
  const _QuietPainter({required this.colors, required this.hatch});
  final RetroDesktopColors colors;
  final bool hatch;
  @override
  void paint(Canvas canvas, Size size) {
    // Empty, the plate stays blank: gridlines with no scale named nothing and ran through the words. Loading, it is
    // hatched.
    final bounds = (Offset.zero & size).deflate(1);
    if (bounds.isEmpty || !hatch) return;
    canvas.save();
    canvas.clipRect(bounds);
    final line = Paint()
      ..color = colors.divider
      ..strokeWidth = 1;
    for (double x = -bounds.height; x < bounds.width; x += 8) {
      canvas.drawLine(
        Offset(bounds.left + x, bounds.bottom),
        Offset(bounds.left + x + bounds.height, bounds.top),
        line,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_QuietPainter old) =>
      colors != old.colors || hatch != old.hatch;
}

// A ring in segments, one per value, each in its tone and hatch; the one read
// stands out a little from the ring.
class _DonutPainter extends CustomPainter {
  const _DonutPainter({
    required this.values,
    required this.inks,
    required this.colors,
    this.at,
  });
  final List<double?> values;
  final List<Color> inks;
  final RetroDesktopColors colors;
  final int? at;
  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(
      0,
      (sum, v) => sum + (v != null && v.isFinite && v > 0 ? v : 0),
    );
    if (total <= 0 || size.isEmpty) return;
    final centre = size.center(Offset.zero);
    final outer = size.shortestSide / 2 - 8;
    final inner = outer * .58;
    var start = -math.pi / 2;
    for (final (i, v) in values.indexed) {
      if (v == null || !v.isFinite || v <= 0) continue;
      final sweep = v / total * math.pi * 2;
      final grow = i == at ? 4.0 : 0.0;
      final path = Path()
        ..arcTo(
          Rect.fromCircle(center: centre, radius: outer + grow),
          start,
          sweep,
          true,
        )
        ..arcTo(
          Rect.fromCircle(center: centre, radius: inner),
          start + sweep,
          -sweep,
          false,
        )
        ..close();
      canvas.save();
      canvas.clipPath(path);
      _paintBar(
        canvas,
        Rect.fromCircle(center: centre, radius: outer + grow),
        inks[i % inks.length],
        colors.paper,
        i,
      );
      canvas.restore();
      // A paper seam between segments keeps neighbours apart without colour.
      canvas.drawLine(
        centre + Offset(math.cos(start), math.sin(start)) * inner,
        centre + Offset(math.cos(start), math.sin(start)) * (outer + grow),
        Paint()
          ..color = colors.paper
          ..strokeWidth = 2,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      !listEquals(values, old.values) ||
      !listEquals(inks, old.inks) ||
      colors != old.colors ||
      at != old.at;
}

class _ChartPainter extends CustomPainter {
  const _ChartPainter({
    required this.series,
    required this.kind,
    required this.low,
    required this.high,
    required this.colors,
    required this.inks,
    required this.rtl,
    required this.guideWidth,
    required this.seriesWidth,
    required this.ticks,
    this.bandLow,
    this.bandHigh,
    this.at,
    this.pad = 0,
  });
  // The position read in the tooltip, marked by a rule down the plot.
  final int? at;
  // How far inside the plate the scale's ends stand (a quarter of it at most).
  final double pad;
  // The round values the gridlines stand on, the first and last the scale's ends.
  final List<double> ticks;
  final List<RetroDesktopChartSeries> series;
  final RetroDesktopChartType kind;
  final double low, high;
  final double? bandLow, bandHigh;
  final RetroDesktopColors colors;
  final List<Color> inks;
  final bool rtl;
  final double guideWidth, seriesWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final bounds = (Offset.zero & size).deflate(1);
    if (bounds.isEmpty) return;
    canvas.drawRect(bounds, Paint()..color = colors.paper);
    // Finite observations can still overflow when their range is subtracted.
    // A constant huge value may also be unchanged by the one-unit range padding.
    final range = high - low;
    final magnitude = math.max(low.abs(), high.abs());
    final inset = math.min(pad, bounds.height / 4);
    final scale = Rect.fromLTRB(
      bounds.left,
      bounds.top + inset,
      bounds.right,
      bounds.bottom - inset,
    );
    double y(double value) {
      final share = high == low
          ? .5
          : range.isFinite
          ? (value - low) / range
          : (value / magnitude - low / magnitude) /
                (high / magnitude - low / magnitude);
      return scale.bottom - share.clamp(0, 1) * scale.height;
    }

    final count = series.fold<int>(0, (n, s) => math.max(n, s.values.length));
    // Every kind stands each value in the middle of its band, under its label: a line's ends then sit inside the
    // frame, not half cut by it.
    double x(int index) {
      final share = (index + .5) / math.max(1, count);
      return bounds.left + (rtl ? 1 - share : share) * bounds.width;
    }

    if (bandLow != null &&
        bandHigh != null &&
        bandLow!.isFinite &&
        bandHigh!.isFinite) {
      canvas.drawRect(
        Rect.fromLTRB(bounds.left, y(bandHigh!), bounds.right, y(bandLow!)),
        Paint()..color = colors.highlightContainer,
      );
    }
    final guide = Paint()
      ..color = colors.divider
      ..strokeWidth = guideWidth;
    for (final tick in ticks) {
      final at = y(tick);
      canvas.drawLine(Offset(bounds.left, at), Offset(bounds.right, at), guide);
    }
    if (at case final int read when read < count) {
      canvas.drawLine(
        Offset(x(read), bounds.top),
        Offset(x(read), bounds.bottom),
        Paint()
          ..color = colors.textTertiary
          ..strokeWidth = guideWidth,
      );
    }
    canvas.save();
    canvas.clipRect(bounds);
    final base = y(math.max(low, math.min(0, high)));
    // Areas first, then every line, then every point: an area is a plate of
    // its own (opaque, the guides stop under it, no glass) and stands under
    // the other series' lines and points.
    final lines = <(Path, Paint, int)>[];
    final points = <(Rect, Color)>[];
    for (final (index, s) in series.indexed) {
      final ink = inks[index % inks.length];
      final stroke = Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = seriesWidth;
      final path = Path();
      final fill = Path();
      var linked = false;
      Offset? last;
      void closeFill() {
        if (last != null) {
          fill
            ..lineTo(last.dx, base)
            ..close();
        }
      }

      for (final (i, value) in s.values.indexed) {
        if (value == null || !value.isFinite) {
          if (linked) closeFill();
          linked = false;
          continue;
        }
        if (kind != RetroDesktopChartType.bar) {
          final point = Offset(x(i), y(value));
          if (linked) {
            path.lineTo(point.dx, point.dy);
            fill.lineTo(point.dx, point.dy);
          } else {
            path.moveTo(point.dx, point.dy);
            fill
              ..moveTo(point.dx, base)
              ..lineTo(point.dx, point.dy);
          }
          linked = true;
          last = point;
          points.add((
            Rect.fromCenter(center: point, width: 4, height: 4),
            ink,
          ));
        } else {
          final slot = bounds.width / math.max(1, count);
          final barWidth = slot * .75 / math.max(1, series.length);
          // A day's bars in the legend's order, which reads from the right
          // in right to left (the days turned and their bars did not).
          final place = rtl ? series.length - 1 - index : index;
          final left = x(i) - slot * .375 + place * barWidth;
          final bar = Rect.fromLTRB(
            left,
            math.min(y(0), y(value)),
            left + barWidth * .85,
            math.max(y(0), y(value)),
          );
          _paintBar(canvas, bar, ink, colors.paper, index);
        }
      }
      if (kind == RetroDesktopChartType.area) {
        if (linked) closeFill();
        canvas.drawPath(fill, Paint()..color = _areaInk(ink, colors.paper));
      }
      if (kind != RetroDesktopChartType.bar) lines.add((path, stroke, index));
    }
    for (final (path, stroke, index) in lines) {
      _paintLine(canvas, path, stroke, index);
    }
    for (final (rect, ink) in points) {
      canvas.drawRect(rect, Paint()..color = ink);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      pad != old.pad ||
      guideWidth != old.guideWidth ||
      seriesWidth != old.seriesWidth ||
      !listEquals(series, old.series) ||
      !listEquals(inks, old.inks) ||
      !listEquals(ticks, old.ticks) ||
      kind != old.kind ||
      low != old.low ||
      high != old.high ||
      bandLow != old.bandLow ||
      bandHigh != old.bandHigh ||
      colors != old.colors ||
      at != old.at ||
      rtl != old.rtl;
}

/// Round gridline values holding [low] to [high]: a step of 1, 2, 2.5 or 5
/// times a power of ten, about four steps to a chart, from the last round value
/// at or under [low] to the first at or over [high]. A range too wide to
/// subtract keeps its two ends.
List<double> _roundTicks(double low, double high) {
  final range = high - low;
  if (!range.isFinite || range <= 0) return [low, high];
  final raw = range / 4;
  final power = math.pow(10, (math.log(raw) / math.ln10).floor()).toDouble();
  final step = [
    1.0,
    2.0,
    2.5,
    5.0,
    10.0,
  ].map((m) => m * power).firstWhere((s) => s >= raw * (1 - 1e-9));
  final from = (low / step + 1e-9).floor() * step;
  final to = (high / step - 1e-9).ceil() * step;
  final count = ((to - from) / step).round();
  if (!from.isFinite || !to.isFinite || count < 1 || count > 12) {
    return [low, high];
  }
  // Enough decimals to name the step exactly (2.5 needs one more than 2).
  final decimals =
      (-(math.log(step) / math.ln10).floor() +
              ((step / power - 2.5).abs() < 1e-9 ? 1 : 0))
          .clamp(0, 15);
  return [
    for (var i = 0; i <= count; i++)
      double.parse((from + i * step).toStringAsFixed(decimals)),
  ];
}

void _paintLine(Canvas canvas, Path path, Paint stroke, int index) {
  final pattern = const <List<double>>[
    [],
    [7, 4],
    [2, 3],
    [8, 3, 2, 3],
    [12, 5],
  ][index % 5];
  if (pattern.isEmpty) {
    canvas.drawPath(path, stroke);
    return;
  }
  for (final metric in path.computeMetrics()) {
    var at = 0.0, part = 0;
    while (at < metric.length) {
      final end = math.min(at + pattern[part % pattern.length], metric.length);
      if (part.isEven) canvas.drawPath(metric.extractPath(at, end), stroke);
      at = end;
      part++;
    }
  }
}

void _paintBar(Canvas canvas, Rect bar, Color ink, Color paper, int index) {
  canvas.drawRect(bar, Paint()..color = ink);
  canvas.save();
  canvas.clipRect(bar);
  final stroke = Paint()
    ..color = paper
    ..strokeWidth = 1;
  switch (index % 5) {
    case 0:
      // Solid is the first series; its legend carries the same solid swatch.
      break;
    case 1:
      for (double x = -bar.height; x < bar.width; x += 6) {
        canvas.drawLine(
          Offset(bar.left + x, bar.bottom),
          Offset(bar.left + x + bar.height, bar.top),
          stroke,
        );
      }
    case 2:
      for (double x = 0; x < bar.width + bar.height; x += 6) {
        canvas.drawLine(
          Offset(bar.left + x, bar.bottom),
          Offset(bar.left + x - bar.height, bar.top),
          stroke,
        );
      }
    case 3:
      for (double x = bar.left + 3; x < bar.right; x += 6) {
        canvas.drawLine(Offset(x, bar.top), Offset(x, bar.bottom), stroke);
      }
    case 4:
      for (double y = bar.top + 3; y < bar.bottom; y += 6) {
        canvas.drawLine(Offset(bar.left, y), Offset(bar.right, y), stroke);
      }
  }
  canvas.restore();
}

// An area's ink: its line's, mixed into the paper and opaque. A fifth of the
// way by day; a third at night, where a fifth of a light ink on dark paper
// all but vanishes.
Color _areaInk(Color ink, Color paper) => Color.alphaBlend(
  ink.withValues(alpha: paper.computeLuminance() < .5 ? .34 : .2),
  paper,
);

class _LegendPainter extends CustomPainter {
  const _LegendPainter({
    required this.index,
    required this.kind,
    required this.ink,
    required this.paper,
  });
  final int index;
  final RetroDesktopChartType kind;
  final Color ink, paper;
  @override
  void paint(Canvas canvas, Size size) {
    if (kind == RetroDesktopChartType.bar ||
        kind == RetroDesktopChartType.donut) {
      _paintBar(canvas, Offset.zero & size, ink, paper, index);
    } else {
      if (kind == RetroDesktopChartType.area) {
        canvas.drawRect(
          Rect.fromLTRB(0, size.height / 2, size.width, size.height),
          Paint()..color = _areaInk(ink, paper),
        );
      }
      _paintLine(
        canvas,
        Path()
          ..moveTo(0, size.height / 2)
          ..lineTo(size.width, size.height / 2),
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
        index,
      );
    }
  }

  @override
  bool shouldRepaint(_LegendPainter old) =>
      index != old.index ||
      kind != old.kind ||
      ink != old.ink ||
      paper != old.paper;
}
