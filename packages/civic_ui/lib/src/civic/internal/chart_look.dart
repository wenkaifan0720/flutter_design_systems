// What Civic's charts share: how a series is told apart without its colour
// (a dash, a mark's shape, a hatch), the legend that names them in words, the
// table a chart's data folds out as, and the frame that holds them.
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/semantics.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../components/details/details.dart';
import '../theme.dart';
import 'paint.dart';
import 'spring.dart';

/// A mark's shape.
enum CivicMarkShape {
  /// A round.
  circle,

  /// A square.
  square,

  /// A triangle, point up.
  triangle,

  /// A diamond.
  diamond,
}

/// A fill's hatch, over its colour in the ground's.
enum CivicHatch {
  /// Solid.
  none,

  /// Stripes rising to the end.
  diagonal,

  /// Stripes across.
  horizontal,

  /// Stripes both ways.
  cross,
}

/// How one series looks, so it is told apart by more than its colour.
@immutable
class CivicSeriesLook {
  /// A series' look.
  const CivicSeriesLook({
    required this.color,
    required this.dash,
    required this.mark,
    required this.hatch,
  });

  /// The [index]th series' look in [t]: the action colour, solid, round;
  /// the ink, dashed, square; the success colour, dotted, triangle; the
  /// error colour, long dashes, diamond; then round again.
  factory CivicSeriesLook.of(CivicThemeData t, int index) =>
      switch (index % 4) {
        0 => CivicSeriesLook(
          color: t.action,
          dash: null,
          mark: CivicMarkShape.circle,
          hatch: CivicHatch.none,
        ),
        1 => CivicSeriesLook(
          color: t.textPrimary,
          dash: const [8, 5],
          mark: CivicMarkShape.square,
          hatch: CivicHatch.diagonal,
        ),
        2 => CivicSeriesLook(
          color: t.success,
          dash: const [2, 4],
          mark: CivicMarkShape.triangle,
          hatch: CivicHatch.horizontal,
        ),
        _ => CivicSeriesLook(
          color: t.danger,
          dash: const [14, 4, 2, 4],
          mark: CivicMarkShape.diamond,
          hatch: CivicHatch.cross,
        ),
      };

  /// The line's and the fill's colour.
  final Color color;

  /// The line's dash, on and off; null, solid.
  final List<double>? dash;

  /// The shape its points are marked with.
  final CivicMarkShape mark;

  /// The hatch over its fills (a bar, a slice).
  final CivicHatch hatch;
}

/// Strokes [path] with [paint], in [dash] (on, off, …) or solid.
void civicStrokeDashed(
  Canvas canvas,
  Path path,
  Paint paint,
  List<double>? dash,
) {
  if (dash == null || dash.isEmpty) {
    canvas.drawPath(path, paint);
    return;
  }
  for (final metric in path.computeMetrics()) {
    var at = 0.0;
    var i = 0;
    while (at < metric.length) {
      final run = dash[i % dash.length];
      if (i.isEven) {
        canvas.drawPath(
          metric.extractPath(at, math.min(at + run, metric.length)),
          paint,
        );
      }
      at += run;
      i++;
    }
  }
}

/// Draws a [shape] mark [radius] about [centre], in [fill] on a ring of
/// [ring] (the ground, so a mark stands clear of the line under it).
void civicMark(
  Canvas canvas,
  Offset centre,
  double radius,
  CivicMarkShape shape,
  Color fill,
  Color ring,
) {
  Path outline(double r) => switch (shape) {
    CivicMarkShape.circle =>
      Path()..addOval(Rect.fromCircle(center: centre, radius: r)),
    CivicMarkShape.square =>
      Path()..addRect(Rect.fromCircle(center: centre, radius: r * 0.9)),
    CivicMarkShape.triangle =>
      Path()
        ..moveTo(centre.dx, centre.dy - r * 1.15)
        ..lineTo(centre.dx + r * 1.1, centre.dy + r * 0.8)
        ..lineTo(centre.dx - r * 1.1, centre.dy + r * 0.8)
        ..close(),
    CivicMarkShape.diamond =>
      Path()
        ..moveTo(centre.dx, centre.dy - r * 1.2)
        ..lineTo(centre.dx + r * 1.2, centre.dy)
        ..lineTo(centre.dx, centre.dy + r * 1.2)
        ..lineTo(centre.dx - r * 1.2, centre.dy)
        ..close(),
  };
  canvas
    ..drawPath(outline(radius + 2), Paint()..color = ring)
    ..drawPath(outline(radius), Paint()..color = fill);
}

/// Fills [area] in [color] with [hatch]'s stripes in [ground] over it.
void civicFillHatched(
  Canvas canvas,
  Path area,
  Color color,
  CivicHatch hatch,
  Color ground,
) {
  canvas.drawPath(area, Paint()..color = color);
  if (hatch == CivicHatch.none) return;
  final box = area.getBounds();
  final stripe = Paint()
    ..color = ground
    ..strokeWidth = 2;
  canvas
    ..save()
    ..clipPath(area);
  const gap = 7.0;
  if (hatch == CivicHatch.diagonal || hatch == CivicHatch.cross) {
    for (var x = box.left - box.height; x < box.right; x += gap) {
      canvas.drawLine(
        Offset(x, box.bottom),
        Offset(x + box.height, box.top),
        stripe,
      );
    }
  }
  if (hatch == CivicHatch.horizontal || hatch == CivicHatch.cross) {
    for (var y = box.top + gap / 2; y < box.bottom; y += gap) {
      canvas.drawLine(Offset(box.left, y), Offset(box.right, y), stripe);
    }
  }
  canvas.restore();
}

/// A sample of a series' look for its legend: a stretch of its line with
/// its mark ([line]), or a block of its fill.
class CivicSeriesSample extends StatelessWidget {
  /// A sample of [look].
  const CivicSeriesSample({super.key, required this.look, this.line = true});

  /// The look.
  final CivicSeriesLook look;

  /// Whether it is a line's sample rather than a fill's.
  final bool line;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    return CustomPaint(
      size: Size(32 * scale, 16 * scale),
      painter: _Sample(look, line, t.background),
    );
  }
}

class _Sample extends CustomPainter {
  _Sample(this.look, this.line, this.ground);

  final CivicSeriesLook look;
  final bool line;
  final Color ground;

  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.height / 2;
    if (line) {
      civicStrokeDashed(
        canvas,
        Path()
          ..moveTo(0, mid)
          ..lineTo(size.width, mid),
        Paint()
          ..color = look.color
          ..strokeWidth = 3
          ..style = PaintingStyle.stroke,
        look.dash,
      );
      civicMark(
        canvas,
        Offset(size.width / 2, mid),
        4,
        look.mark,
        look.color,
        ground,
      );
    } else {
      civicFillHatched(
        canvas,
        Path()..addRect(Offset.zero & size),
        look.color,
        look.hatch,
        ground,
      );
    }
  }

  @override
  bool shouldRepaint(_Sample old) =>
      old.look != look || old.line != line || old.ground != ground;
}

/// The series' names, each after its sample, wrapping as the room needs.
class CivicChartLegend extends StatelessWidget {
  /// A legend of [entries]: each a name and its look.
  const CivicChartLegend({super.key, required this.entries, this.lines = true});

  /// The names, in order, with their looks.
  final List<(String, CivicSeriesLook)> entries;

  /// Whether the samples are lines (a line chart) or fills (bars, slices).
  final bool lines;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    // The chart's own semantics say each series; the legend is for the eye.
    return ExcludeSemantics(
      child: Wrap(
        spacing: CivicSpacing.s24,
        runSpacing: CivicSpacing.s8,
        children: [
          for (final (name, look) in entries)
            Row(
              mainAxisSize: MainAxisSize.min,
              spacing: CivicSpacing.s8,
              children: [
                CivicSeriesSample(look: look, line: lines),
                Flexible(
                  child: Text(
                    name,
                    style: context.civicText.body.copyWith(
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// A chart's data as Civic's table: its names in bold over an ink rule,
/// each row on a hairline, numbers at the end. A missing value says
/// [missing]. Where the columns need more room than there is, each row
/// stands as a block instead (its name, then each column's name and its
/// value), so no cell is cut and nothing scrolls.
///
/// A screen reader hears [label], then the table's cells (or, in blocks,
/// each row's name and each name with its value).
class CivicChartTableView extends StatelessWidget {
  /// A table of [rows] under [headers].
  const CivicChartTableView({
    super.key,
    required this.label,
    required this.headers,
    required this.rows,
    required this.missing,
  });

  /// The table's name, said first.
  final String label;

  /// The columns' names: the first over the rows' names (empty for none).
  final List<String> headers;

  /// Each row's cells, in the order of [headers]; null where a value is
  /// missing.
  final List<List<String?>> rows;

  /// What a missing value says.
  final String missing;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final scaler = MediaQuery.textScalerOf(context);
    final direction = Directionality.of(context);
    final l = RawWidgetsLocalizations.of(context);
    const figures = [ui.FontFeature.tabularFigures()];
    final names = text.label.copyWith(color: t.textPrimary);
    final body = text.body.copyWith(
      color: t.textPrimary,
      fontFeatures: figures,
    );
    String say(String? cell) => cell ?? missing;
    double wide(String words, TextStyle style) {
      final p = TextPainter(
        text: TextSpan(text: words, style: style),
        textDirection: direction,
        textScaler: scaler,
      )..layout();
      final width = p.width;
      p.dispose();
      return width;
    }

    // How wide the table stands: each column as its widest cell, and the
    // room after it.
    var needed = 0.0;
    for (var c = 0; c < headers.length; c++) {
      var column = wide(headers[c], names);
      for (final row in rows) {
        if (c < row.length) column = math.max(column, wide(say(row[c]), body));
      }
      needed += column + CivicSpacing.s24;
    }
    // The last column needs no room after it.
    needed -= CivicSpacing.s24;

    Widget cell(String words, {required bool header, required int column}) =>
        Semantics(
          container: true,
          role: header ? SemanticsRole.columnHeader : SemanticsRole.cell,
          label: words,
          child: ExcludeSemantics(
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  bottom: header
                      ? BorderSide(color: t.border, width: CivicMetrics.edge)
                      : BorderSide(color: t.rule),
                ),
              ),
              child: Padding(
                padding: EdgeInsetsDirectional.only(
                  top: CivicSpacing.s12,
                  bottom: CivicSpacing.s12,
                  end: column == headers.length - 1 ? 0 : CivicSpacing.s24,
                ),
                child: Align(
                  alignment: column == 0
                      ? AlignmentDirectional.centerStart
                      : AlignmentDirectional.centerEnd,
                  widthFactor: 1,
                  child: Text(words, style: header ? names : body),
                ),
              ),
            ),
          ),
        );

    Widget grid() => Table(
      defaultColumnWidth: const IntrinsicColumnWidth(),
      children: [
        TableRow(
          children: [
            for (final (c, words) in headers.indexed)
              cell(words, header: true, column: c),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              for (var c = 0; c < headers.length; c++)
                cell(
                  say(c < row.length ? row[c] : null),
                  header: false,
                  column: c,
                ),
            ],
          ),
      ],
    );

    // A row as a block: its name, then each column's name and its value,
    // the value at the end where both fit on a line, under it where not.
    Widget block(List<String?> row) => Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: t.rule)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: CivicSpacing.s4,
            children: [
              Text(say(row.firstOrNull), style: names),
              for (var c = 1; c < headers.length; c++)
                Semantics(
                  container: true,
                  label: [
                    headers[c],
                    say(c < row.length ? row[c] : null),
                  ].join(l.listSeparator),
                  child: ExcludeSemantics(
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: CivicSpacing.s16,
                      children: [
                        Text(
                          headers[c],
                          style: body.copyWith(color: t.textSecondary),
                        ),
                        Text(say(c < row.length ? row[c] : null), style: body),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      container: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, constraints) => needed <= constraints.maxWidth
            ? Align(alignment: AlignmentDirectional.centerStart, child: grid())
            : DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(color: t.border, width: CivicMetrics.edge),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [for (final row in rows) block(row)],
                ),
              ),
      ),
    );
  }
}

/// A chart's frame: its [title] (a heading's weight) over its [summary],
/// its [legend], the [chart], then its data as a table folded under "Show
/// data table" in plain sight, which a screen reader's "Show data table"
/// opens too (the `showTable` that [chart] is handed).
class CivicChartFrame extends StatefulWidget {
  /// A frame round [chart].
  const CivicChartFrame({
    super.key,
    required this.title,
    required this.chart,
    required this.table,
    this.summary,
    this.legend,
    this.tableLabel,
  });

  /// The chart's name.
  final String title;

  /// What it shows, in a sentence.
  final String? summary;

  /// Its legend.
  final Widget? legend;

  /// The chart, given the call that opens its table.
  final Widget Function(VoidCallback showTable) chart;

  /// The table.
  final Widget table;

  /// The fold's words; null: "Show data table" in the reader's language.
  final String? tableLabel;

  @override
  State<CivicChartFrame> createState() => _CivicChartFrameState();
}

class _CivicChartFrameState extends State<CivicChartFrame> {
  var _open = false;
  var _opened = 0;

  void _showTable() => setState(() {
    _open = true;
    _opened++;
  });

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final summary = widget.summary;
    final legend = widget.legend;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // The chart says its name itself; this is its caption to the eye.
        ExcludeSemantics(
          child: Text(
            widget.title,
            style: text.headingS.copyWith(color: t.textPrimary),
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: CivicSpacing.s4),
          Text(summary, style: text.body.copyWith(color: t.textSecondary)),
        ],
        if (legend != null) ...[
          const SizedBox(height: CivicSpacing.s16),
          legend,
        ],
        const SizedBox(height: CivicSpacing.s16),
        widget.chart(_showTable),
        const SizedBox(height: CivicSpacing.s16),
        CivicDetails(
          key: ValueKey(_opened),
          title:
              widget.tableLabel ??
              RawWidgetsLocalizations.of(context).chartShowTableLabel,
          initiallyExpanded: _open,
          onExpansionChanged: (open) => _open = open,
          child: widget.table,
        ),
      ],
    );
  }
}

/// The well's focus round a chart: an ink edge and the yellow ring outside
/// it, coming up on the focus spring.
class CivicChartFocus extends StatelessWidget {
  /// [child] with its focus while [focused].
  const CivicChartFocus({
    super.key,
    required this.focused,
    required this.child,
  });

  /// Whether the keys are on the chart.
  final bool focused;

  /// The chart.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return CivicSpringValue(
      value: focused ? 1 : 0,
      spring: CivicMotion.focus,
      effects: true,
      child: child,
      builder: (context, focus, child) => DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          border: Border.all(
            color: t.focus.withValues(alpha: focus.clamp(0, 1)),
            width: CivicMetrics.focusRing,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: Border.all(
              color: t.focusBar.withValues(alpha: focus.clamp(0, 1)),
              width: CivicMetrics.edge,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Lays out [words] in [style] at [scaler] for painting.
TextPainter civicChartWords(
  String words,
  TextStyle style,
  TextScaler scaler,
  TextDirection direction,
) => TextPainter(
  text: TextSpan(text: words, style: style),
  textDirection: direction,
  textScaler: scaler,
  maxLines: 1,
)..layout();

/// Paints the readout for a picked point: a card on the page's white with
/// a soft shadow, [lines] in it (the first in bold), standing over
/// [anchor] (the highest of the picked points; clear of a finger for a
/// [touch]) where there is room, else beside it, [reach] out from its
/// middle (a group of bars' half width), on the side the words read toward
/// first, so it never covers what is picked; kept inside [bounds].
void civicPaintReadout(
  Canvas canvas, {
  required CivicThemeData t,
  required List<(String, CivicSeriesLook?)> lines,
  required Offset anchor,
  required Rect bounds,
  required TextStyle bold,
  required TextStyle plain,
  required TextScaler scaler,
  required TextDirection direction,
  required bool touch,
  double reach = 0,
}) {
  final painters = [
    for (final (i, (words, _)) in lines.indexed)
      civicChartWords(words, i == 0 ? bold : plain, scaler, direction),
  ];
  const pad = CivicSpacing.s12;
  final sample = scaler.scale(12);
  var width = 0.0;
  var height = pad * 2;
  for (final (i, p) in painters.indexed) {
    final withMark = lines[i].$2 != null ? sample + CivicSpacing.s8 : 0.0;
    width = math.max(width, p.width + withMark);
    height += p.height + (i == 0 ? 0 : CivicSpacing.s4);
  }
  width += pad * 2;
  final lift = touch ? 48.0 : 16.0;
  final rtl = direction == TextDirection.rtl;
  double across(double x) =>
      x.clamp(bounds.left, math.max(bounds.left, bounds.right - width));
  double left;
  double top;
  if (anchor.dy - lift - height >= bounds.top) {
    left = across(anchor.dx - width / 2);
    top = anchor.dy - lift - height;
  } else {
    final gap = touch ? 32.0 : 16.0;
    final out = gap + reach;
    final after = rtl ? anchor.dx - out - width : anchor.dx + out;
    final before = rtl ? anchor.dx + out : anchor.dx - out - width;
    final fits = after >= bounds.left && after + width <= bounds.right;
    left = across(fits ? after : before);
    top = bounds.top + CivicSpacing.s4;
  }
  final card = RRect.fromRectAndRadius(
    Rect.fromLTWH(left, top, width, height),
    Radius.circular(t.shapeScheme.corners.small),
  );
  canvas
    ..drawShadow(
      Path()..addRRect(card),
      const Color(0xFF000000),
      t.isDark ? 6 : 4,
      false,
    )
    ..drawRRect(card, Paint()..color = t.background);
  var y = top + pad;
  for (final (i, p) in painters.indexed) {
    final look = lines[i].$2;
    var x = rtl ? left + width - pad : left + pad;
    if (look != null) {
      final c = Offset(rtl ? x - sample / 2 : x + sample / 2, y + p.height / 2);
      civicMark(canvas, c, sample / 3, look.mark, look.color, t.background);
      x += rtl ? -(sample + CivicSpacing.s8) : sample + CivicSpacing.s8;
    }
    p.paint(canvas, Offset(rtl ? x - p.width : x, y));
    y += p.height + CivicSpacing.s4;
    p.dispose();
  }
}
