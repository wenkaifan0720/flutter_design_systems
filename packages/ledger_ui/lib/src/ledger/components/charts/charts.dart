import 'dart:math' as math;

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../internal/engraving.dart';
import '../../internal/plot.dart';
import '../../theme.dart';

/// A line across a plot at [value], its [label] at the plot's end above it
/// (`.ylab`: $2k, 60k).
///
/// ```dart
/// LedgerGridLine(2000, '\$2k')
/// ```
class LedgerGridLine {
  /// A line at [value], labelled [label].
  const LedgerGridLine(this.value, this.label);

  /// Where the line stands, on the plot's scale.
  final double value;

  /// The scale's words for it, at the plot's end.
  final String label;
}

/// A day ringed on a month's plot and labelled (`.mark`): a payday above
/// its point, a card's payment [below] it.
///
/// ```dart
/// LedgerChartMark(23, 'Pay +\$3,412.50')
/// ```
class LedgerChartMark {
  /// A ringed [day] labelled [text], above its point unless [below].
  const LedgerChartMark(this.day, this.text, {this.below = false});

  /// The day of the month (its index on a month's bars).
  final int day;

  /// The mark's words.
  final String text;

  /// Whether the words stand under the point (a card's payment) rather than
  /// over it.
  final bool below;
}

/// A note hung on a plot's point on a leader [lift] above it (`.anno`):
/// the rent's jump on day 1, a large bill's step; its `**strong**` run in
/// the ink. [deskLift] stands it on the desktop's plot, and [deskText]
/// words it there (a phone's note may break where the desktop's runs on).
///
/// ```dart
/// LedgerChartNote(0, '**Rent**\n\$1,150.00 · Nov 1', lift: 40, deskLift: 46, deskText: '**Rent** \$1,150.00 · Nov 1')
/// ```
class LedgerChartNote {
  /// A note on point [index]; [deskLift] and [deskText] default to [lift] and
  /// [text].
  const LedgerChartNote(
    this.index,
    this.text, {
    required this.lift,
    double? deskLift,
    String? deskText,
  }) : deskLift = deskLift ?? lift,
       deskText = deskText ?? text;

  /// Which point it hangs on (a step's index; 0 for the first day).
  final int index;

  /// The note's words, its `**strong**` run in the ink.
  final String text;

  /// How far above its point the note stands, on a leader.
  final double lift;

  /// The lift on the desktop's plot.
  final double deskLift;

  /// The note's words on the desktop.
  final String deskText;
}

class _Engraving extends CustomPainter {
  _Engraving(this.ops);

  final List<void Function(Canvas canvas)> ops;

  @override
  void paint(Canvas canvas, Size size) {
    for (final op in ops) {
      op(canvas);
    }
  }

  @override
  bool shouldRepaint(_Engraving old) => true;
}

// Each chart's source parameters, per width class: the plot's aspect
// (height over width), its scale's gutter, the hatch's spacing and stroke.
typedef _Spec = ({double w, double h, double gut, double spacing, double sw});

LedgerPlotLabel _scaleLabel(
  LedgerThemeData t,
  bool wide,
  double y,
  String text,
) => LedgerPlotLabel(
  right: 0,
  top: y,
  shift: const Offset(0, -1),
  // On the paper, so a line that runs under a figure grown with a large
  // text (a projection's drop at the plot's end) breaks round it.
  child: Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: ColoredBox(
      color: t.background,
      child: Padding(
        padding: const EdgeInsets.only(left: _scaleKnock),
        child: Text(text, softWrap: false, style: t.plotScale(wide)),
      ),
    ),
  ),
);

// The paper a scale's figure keeps clear before it.
const double _scaleKnock = 3;

LedgerPlotLabel _budgetLabel(
  LedgerThemeData t,
  bool wide,
  double y,
  String text,
) => LedgerPlotLabel(
  left: 0,
  top: y,
  shift: const Offset(0, -1),
  child: Padding(
    padding: const EdgeInsets.only(bottom: 2),
    child: Text(
      text,
      softWrap: false,
      style: t.plotScale(wide).medium.tracked(.02).colored(t.textPrimary),
    ),
  ),
);

LedgerPlotLabel _pointLabel(
  LedgerThemeData t,
  Offset at,
  String text, {
  bool end = false,
}) => LedgerPlotLabel(
  left: at.dx,
  top: at.dy,
  shift: end ? const Offset(-1, -1) : const Offset(-1, -.5),
  // On the paper, as a note is: the line it names may run close by it
  // ("Today" beside a falling line), and breaks round the words.
  child: Padding(
    padding: EdgeInsets.only(right: end ? 8 : 14 - _scaleKnock),
    child: ColoredBox(
      color: t.background,
      child: Padding(
        padding: EdgeInsets.only(
          left: _scaleKnock,
          right: end ? 0 : _scaleKnock,
        ),
        child: Text(
          text,
          softWrap: false,
          textAlign: end ? TextAlign.right : null,
          style: t.plotPoint,
        ),
      ),
    ),
  ),
);

LedgerPlotLabel _noteLabel(
  LedgerThemeData t,
  Offset at,
  double lift,
  String text,
) => LedgerPlotLabel(
  left: at.dx,
  top: at.dy - lift,
  child: Container(
    height: lift,
    padding: const EdgeInsets.only(left: 7),
    alignment: Alignment.topLeft,
    decoration: BoxDecoration(
      border: Border(left: BorderSide(color: t.textPrimary)),
    ),
    child: ColoredBox(
      color: t.background,
      child: Padding(
        padding: const EdgeInsets.only(right: 4, bottom: 1),
        child: ledgerPlotText(text, t.plotNote, t.textPrimary),
      ),
    ),
  ),
);

LedgerPlotLabel _markLabel(
  LedgerThemeData t,
  double x,
  double y,
  String text, {
  bool below = false,
  bool end = false,
}) => below
    ? LedgerPlotLabel(
        left: x,
        top: y + 6,
        shift: const Offset(-.5, 0),
        child: ColoredBox(
          color: t.background,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            child: Text(
              text,
              softWrap: false,
              style: t.plotMark.colored(t.textSecondary),
            ),
          ),
        ),
      )
    : LedgerPlotLabel(
        left: x,
        top: y,
        shift: end ? const Offset(-1, -1) : const Offset(-.5, -1),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(text, softWrap: false, style: t.plotMark),
        ),
      );

/// The day ruler's labels as `art.day_ruler` picks them: the 1st, the 8th,
/// the 15th, the 22nd (unless today is within 4 of it), today and the
/// last day; today read "Today" on the desktop (the shared words'
/// [DesignLocalizations.currentDateLabel]).
List<LedgerRulerMark> _dayRuler(
  BuildContext context,
  double Function(int day) x,
  int days,
  int today,
  bool wide,
  String month,
) => [
  for (final day in [1, 8, 15, 22, today, days])
    if (!(day == 22 && today - day < 4))
      (
        text: day == today
            ? (wide ? DesignLocalizations.of(context).currentDateLabel : '$day')
            : day == 1
            ? '$month 1'
            : '$day',
        x: day == 1 ? 0 : x(day),
        first: day == 1 && day != today,
        today: day == today,
      ),
];

/// A month's chart and the day ruler under it, as `.chart` stands them.
class _WithRuler extends StatelessWidget {
  const _WithRuler({required this.plot, required this.ruler});

  final LedgerPlot plot;
  final List<LedgerRulerMark> Function(double width, bool wide) ruler;

  @override
  Widget build(BuildContext context) {
    final wide = LedgerLayout.isWide(context);
    return LayoutBuilder(
      builder: (context, box) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          plot,
          LedgerDayRulerLabels(
            marks: ruler(box.maxWidth, wide),
            width: box.maxWidth,
          ),
        ],
      ),
    );
  }
}

/// The net worth over a year of month ends (`art.net_worth`): an engraved
/// area under the inked line, each month ringed, today's point green with
/// its halo and a dotted drop, the [grid] dotted across with its scale,
/// and today's [endLabel] beside its point; [months] keys each month under
/// it (the last green), each key centred under its point and whole however
/// narrow its slot (an empty key draws nothing, so a day's or a year's
/// range can key only some points). Sized by its width: the source's 342
/// by 168 on a phone, 712 by 330 from 1024, or [height]. Read as its label
/// and end.
///
/// ```dart
/// LedgerNetWorthChart(values: const [61.4, 62.9, 78.18], low: 56, high: 82, grid: const [LedgerGridLine(80, '80k')], endLabel: 'Oct 78.18k')
/// ```
class LedgerNetWorthChart extends StatelessWidget {
  /// A year of month-end [values] between [low] and [high].
  const LedgerNetWorthChart({
    required this.values,
    required this.low,
    required this.high,
    required this.grid,
    required this.endLabel,
    this.months,
    this.height,
    this.semanticLabel = 'Net worth by month',
    super.key,
  });

  /// Each month end's net worth, the last today's.
  final List<double> values;

  /// The plot's floor.
  final double low;

  /// The plot's ceiling.
  final double high;

  /// The dotted lines across, with their scale.
  final List<LedgerGridLine> grid;

  /// Today's words beside its point.
  final String endLabel;

  /// A key under each point, the last green; an empty key draws nothing.
  final List<String>? months;

  /// The plot's height; null takes the phone's or the desktop's.
  final double? height;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 168, gut: 30, spacing: 3.1, sw: .6);
  static const _Spec _desk = (w: 712, h: 330, gut: 36, spacing: 3.5, sw: .65);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final s = wide ? _desk : _phone;
    final plot = LedgerPlot(
      phoneAspect: _phone.h / _phone.w,
      deskAspect: _desk.h / _desk.w,
      height: height,
      draw: (size, wide) => _draw(t, size, wide ? _desk : _phone),
    );
    return Semantics(
      label: semanticLabel,
      value: endLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          plot,
          if (months case final keys?)
            _PointKeys(keys: keys, gutter: s.gut, now: keys.length - 1),
        ],
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, _Spec s) {
    final w = size.width, h = size.height;
    const top = 6.0;
    final wp = w - s.gut, yb = h - 5.5;
    double x(int i) => (i + .5) * wp / values.length;
    double y(double v) => top + (high - v) / (high - low) * (yb - top);
    final pts = [
      for (var i = 0; i < values.length; i++) Offset(x(i), y(values[i])),
    ];
    final area = ledgerEngravedArea(pts, top, yb, s.spacing);
    final ink = t.textPrimary, green = t.pace, paper = t.background;
    final last = pts.last;
    final ops = <void Function(Canvas)>[
      for (final g in grid) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      (c) => ledgerPaintArea(c, area, ledgerFade(ink, top, yb), ink, s.sw),
      (c) => ledgerDrop(c, last, Offset(last.dx, yb), green),
      (c) => ledgerInkedLine(c, pts, ink, paper),
      for (final p in pts.take(pts.length - 1))
        (c) => ledgerRing(c, p, ink, paper),
      (c) => ledgerNowMark(c, last, green, paper),
      (c) => c
        ..drawLine(Offset(0, yb), Offset(w, yb), ledgerStroke(ink, 1))
        ..drawLine(
          Offset(0, h - 1.5),
          Offset(w, h - 1.5),
          ledgerStroke(ink, .6),
        ),
    ];
    final wide = s.w == _desk.w;
    return (
      painter: _Engraving(ops),
      labels: [
        for (final g in [...grid]..sort((a, b) => b.value.compareTo(a.value)))
          _scaleLabel(t, wide, y(g.value), g.label),
        _pointLabel(t, last, endLabel),
      ],
    );
  }
}

/// The keys under the net worth's points (`.xlabs`): one slot per point and the
/// plot's gutter after them (`repeat(12, 1fr) 30px`, 36 from 1024), 8 under the
/// plot, each key centred on its slot (its point) in the 10 mono on 12 (11 from
/// 1024), the [now] key medium in the green. CSS's `1fr` slot never clips its
/// key (its least is the key's own width), so a key wider than its slot stands
/// whole, centred, over its neighbours' empty slots.
class _PointKeys extends StatelessWidget {
  const _PointKeys({required this.keys, required this.gutter, this.now});

  final List<String> keys;
  final double gutter;
  final int? now;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final base = t.plotScale(LedgerLayout.isWide(context));
    return Padding(
      padding: const EdgeInsets.only(top: _top),
      // Under its plot, which reads left to right in any page; each key
      // centred on its point grows as the plot's labels do.
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: LedgerPlot.labelTextScale,
        child: Row(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < keys.length; i++)
              Expanded(
                child: keys[i].isEmpty
                    ? const SizedBox.shrink()
                    : OverflowBox(
                        maxWidth: double.infinity,
                        fit: OverflowBoxFit.deferToChild,
                        child: Text(
                          keys[i],
                          textAlign: TextAlign.center,
                          softWrap: false,
                          style: i == now ? base.medium.colored(t.pace) : base,
                        ),
                      ),
              ),
            if (gutter > 0) SizedBox(width: gutter),
          ],
        ),
      ),
    );
  }

  // `.xlabs { margin-top: 8px }`.
  static const double _top = 8;
}

/// A month's spending summed day by day against its budget
/// (`art.cumulative`): the engraved area under the inked line, the budget
/// as a double rule with its label, the budget's pace as a dashed green
/// line from nothing to the budget at the month's end, the days ahead
/// shaded, today's point and its dotted drop, the rent day's [note], and
/// the day ruler under it. 342 by 248 on a phone, 712 by 392 from 1024.
///
/// ```dart
/// LedgerCumulativeChart(cumulative: spent, budget: 2700, days: 31, high: 3000, grid: grid, budgetLabel: 'Budget \$2,700')
/// ```
class LedgerCumulativeChart extends StatelessWidget {
  /// A month's [cumulative] spending against its [budget].
  const LedgerCumulativeChart({
    required this.cumulative,
    required this.budget,
    required this.days,
    required this.high,
    required this.grid,
    required this.budgetLabel,
    this.note,
    this.month = 'Oct',
    this.height,
    this.semanticLabel = 'Spent through the month against the budget',
    super.key,
  });

  /// The month's spending summed by the end of each day so far.
  final List<double> cumulative;

  /// The month's budget, drawn as a double rule.
  final double budget;

  /// How many days the month has.
  final int days;

  /// The plot's ceiling.
  final double high;

  /// The dotted lines across, with their scale.
  final List<LedgerGridLine> grid;

  /// The budget rule's words.
  final String budgetLabel;

  /// A note hung on a day (the rent's jump).
  final LedgerChartNote? note;

  /// The month's short name, for the ruler's first label (Oct 1).
  final String month;

  /// The plot's height; null takes the phone's or the desktop's.
  final double? height;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 248, gut: 30, spacing: 3.1, sw: .6);
  static const _Spec _desk = (w: 712, h: 392, gut: 40, spacing: 3.6, sw: .7);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final today = cumulative.length;
    return Semantics(
      label: semanticLabel,
      value: budgetLabel,
      excludeSemantics: true,
      child: _WithRuler(
        plot: LedgerPlot(
          phoneAspect: _phone.h / _phone.w,
          deskAspect: _desk.h / _desk.w,
          height: height,
          draw: (size, wide) => _draw(t, size, wide),
        ),
        ruler: (width, wide) {
          final wp = width - (wide ? _desk : _phone).gut;
          return _dayRuler(
            context,
            (d) => d / days * wp,
            days,
            today,
            wide,
            month,
          );
        },
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    const top = 4.0;
    final wp = w - s.gut, yb = h - 14;
    final today = cumulative.length;
    double x(int d) => d / days * wp;
    double y(double v) => top + (high - v) / high * (yb - top);
    final pts = [
      Offset(x(0), y(0)),
      for (var d = 0; d < cumulative.length; d++)
        Offset(x(d + 1), y(cumulative[d])),
    ];
    final ink = t.textPrimary, green = t.pace, paper = t.background;
    final area = ledgerEngravedArea(pts, top, yb, s.spacing);
    final last = pts.last, first = pts[1];
    final ops = <void Function(Canvas)>[
      for (final g in grid) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      (c) => ledgerAhead(c, Rect.fromLTRB(x(today), top, x(days), yb), ink),
      (c) => ledgerDoubleRule(c, y(budget), 0, w, ink),
      (c) => ledgerPaintArea(
        c,
        area,
        ledgerFade(ink, y(budget), yb, a1: .12),
        ink,
        s.sw,
      ),
      (c) {
        final from = Offset(x(0), y(0)), to = Offset(x(days), y(budget));
        c.drawLine(from, to, ledgerStroke(paper, 4.5));
        c.drawPath(
          ledgerDashed(
            Path()
              ..moveTo(from.dx, from.dy)
              ..lineTo(to.dx, to.dy),
            const [5, 3],
          ),
          ledgerStroke(green, 1.4),
        );
      },
      (c) => ledgerInkedLine(c, pts, ink, paper),
      (c) => ledgerDrop(
        c,
        Offset(last.dx, top),
        Offset(last.dx, yb),
        ink,
        width: .8,
      ),
      (c) => c
        ..drawCircle(last, 4.2, Paint()..color = ink)
        ..drawCircle(last, 4.2, ledgerStroke(paper, 1.5)),
      (c) => ledgerRing(c, first, ink, paper, radius: 2.6),
      (c) => c.drawLine(Offset(0, yb), Offset(wp, yb), ledgerStroke(ink, 1)),
      (c) => ledgerRulerTicks(c, x, yb, days, today, ink),
    ];
    final labels = [
      for (final g in [...grid]..sort((a, b) => b.value.compareTo(a.value)))
        _scaleLabel(t, wide, y(g.value), g.label),
      _budgetLabel(t, wide, y(budget) - 3, budgetLabel),
      if (note case final n?)
        _noteLabel(
          t,
          first,
          wide ? n.deskLift : n.lift,
          wide ? n.deskText : n.text,
        ),
    ];
    return (painter: _Engraving(ops), labels: labels);
  }
}

/// How a [LedgerDayBars] is inked: the [ink] (spending) or the [green].
enum LedgerBarTone {
  /// The ink: spending.
  ink,

  /// The green.
  green,
}

/// A month's spending by day as hatched bars (`art.day_bars`): one bar per
/// day so far, as tall as the money spent that day, on the month's ruler; a
/// bar past [cap] broken the way an engraver breaks an axis and labelled
/// with its amount from [capLabels]; [marks] ring the paydays along the top
/// on a dotted drop; the rest of the month shaded, nothing spent there yet;
/// the [grid] dotted with its amounts ([phoneGrid] on a phone, its top line
/// alone by default). 342 by 132 on a phone, 712 by 236 from 1024 ([height]
/// for another).
///
/// ```dart
/// LedgerDayBars(values: daily, days: 31, cap: 190, grid: grid)
/// ```
class LedgerDayBars extends StatelessWidget {
  /// A bar for each of the month's [values] so far, of [days].
  const LedgerDayBars({
    required this.values,
    required this.days,
    this.cap,
    this.capLabels = const {},
    this.marks = const [],
    this.grid = const [],
    this.phoneGrid,
    this.high,
    this.tone = LedgerBarTone.ink,
    this.month = 'Oct',
    this.height,
    this.deskHeight,
    this.semanticLabel = 'Spent per day',
    super.key,
  });

  /// Each day's spending so far.
  final List<double> values;

  /// How many days the month has.
  final int days;

  /// The height past which a bar is broken; null breaks none.
  final double? cap;

  /// A broken bar's words by its day (`**$1,172.40** Oct 1, rent day`).
  final Map<int, String> capLabels;

  /// The days ringed along the top (the paydays).
  final List<LedgerChartMark> marks;

  /// The dotted lines across, with their amounts.
  final List<LedgerGridLine> grid;

  /// The lines on a phone; null keeps [grid]'s top line alone.
  final List<LedgerGridLine>? phoneGrid;

  /// The plot's ceiling; null takes the tallest bar's (or the [cap]).
  final double? high;

  /// How the bars are inked.
  final LedgerBarTone tone;

  /// The month's short name, for the ruler's first label.
  final String month;

  /// The plot's height on a phone and from 1024 (a category's bars stand
  /// 120 and 268).
  final double? height;

  /// The plot's height from 1024.
  final double? deskHeight;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 132, gut: 30, spacing: 2.6, sw: .6);
  static const _Spec _desk = (w: 712, h: 236, gut: 40, spacing: 3.0, sw: .6);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final today = values.length;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: _WithRuler(
        plot: LedgerPlot(
          phoneAspect: _phone.h / _phone.w,
          deskAspect: _desk.h / _desk.w,
          height: wide ? deskHeight : height,
          draw: (size, wide) => _draw(t, size, wide),
        ),
        ruler: (width, wide) {
          final slot = (width - (wide ? _desk : _phone).gut) / days;
          return _dayRuler(
            context,
            (d) => d * slot - slot / 2,
            days,
            today,
            wide,
            month,
          );
        },
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    const top = 6.0;
    final wp = w - s.gut, yb = h - 14;
    final today = values.length;
    final hi = high ?? cap ?? values.reduce(math.max) * 1.12;
    final slot = wp / days;
    final bw = math.max(2.0, slot * .46);
    final lines = wide
        ? grid
        : phoneGrid ??
              (grid.isEmpty
                  ? const <LedgerGridLine>[]
                  : [grid.reduce((a, b) => a.value >= b.value ? a : b)]);
    double x(int d) => d * slot;
    double y(double v) => top + (hi - math.min(v, hi)) / hi * (yb - top);
    final ink = t.textPrimary, green = t.pace, paper = t.background;
    final color = tone == LedgerBarTone.green ? green : ink;
    final ops = <void Function(Canvas)>[
      for (final g in lines) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      (c) => ledgerAhead(c, Rect.fromLTRB(x(today), top, x(days), yb), ink),
    ];
    final labels = <LedgerPlotLabel>[];
    for (final m in marks) {
      final cx = x(m.day - 1) + slot / 2;
      ops
        ..add(
          (c) => ledgerDrop(
            c,
            Offset(cx, top + 8),
            Offset(cx, yb),
            green,
            width: .9,
          ),
        )
        ..add(
          (c) => ledgerRing(
            c,
            Offset(cx, top + 4),
            green,
            paper,
            radius: 3.4,
            width: 1.3,
          ),
        );
      labels.add(_markLabel(t, cx, top + 4, m.text));
    }
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      if (v <= 0) continue;
      final cx = x(i) + slot / 2;
      final x0 = cx - bw / 2, x1 = cx + bw / 2;
      var top0 = y(v);
      if (yb - top0 < 1.2) top0 = yb - 1.2;
      final bar = Rect.fromLTRB(x0, top0, x1, yb);
      final hatch = ledgerHatchRect(x0, top0, x1, yb, s.spacing);
      ops
        ..add((c) => c.drawPath(hatch, ledgerStroke(ledgerInk(color, .6), .6)))
        ..add((c) => c.drawRect(bar, ledgerStroke(color, .75)));
      if (cap != null && v > cap!) {
        final yk = top + 14;
        for (final dy in const [0.0, 4.5]) {
          final a = Offset(x0 - 3, yk + dy + 2),
              b = Offset(x1 + 3, yk + dy - 2);
          ops.add(
            (c) => c
              ..drawLine(a, b, ledgerStroke(paper, 2.8))
              ..drawLine(a, b, ledgerStroke(color, .8)),
          );
        }
        if (capLabels[i + 1] case final words?) {
          labels.add(
            LedgerPlotLabel(
              left: x1 + 6,
              top: top + 14,
              // On the paper, a line it crosses (a payday's drop) breaking
              // round it clear of its descenders, not out of them.
              child: ColoredBox(
                color: paper,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 1, 4, 4),
                  child: ledgerPlotText(words, t.plotCaption, t.textPrimary),
                ),
              ),
            ),
          );
        }
      }
    }
    ops
      ..add(
        (c) => c.drawLine(Offset(0, yb), Offset(wp, yb), ledgerStroke(ink, 1)),
      )
      // A tick under each bar's centre, where its day's label stands.
      ..add(
        (c) => ledgerRulerTicks(
          c,
          (d) => x(d - 1) + slot / 2,
          yb,
          days,
          today,
          ink,
          from: 1,
        ),
      );
    for (final g in lines) {
      labels.add(_scaleLabel(t, wide, y(g.value), g.label));
    }
    return (painter: _Engraving(ops), labels: labels);
  }
}

/// One merchant's month as a ruler (`art.visit_ruler`), 34 tall: a hatched
/// bar on each day it was paid, as tall as that day's total there, the
/// record's own [current] day solid; the days ahead shaded; a tick for
/// every day, long on the weeks. [moneyIn] inks it green (a payer).
/// [startLabel] and [endLabel] stand 4 under it at its two ends
/// (`.ruler-labs`: Oct 1, Oct 31).
///
/// ```dart
/// LedgerVisitRuler(visits: const [(28, 6.75), (23, 6.5)], days: 31, today: 28, current: 28, startLabel: 'Oct 1', endLabel: 'Oct 31')
/// ```
class LedgerVisitRuler extends StatelessWidget {
  /// A merchant's [visits] over a month of [days], up to [today].
  const LedgerVisitRuler({
    required this.visits,
    required this.days,
    required this.today,
    this.current,
    this.moneyIn = false,
    this.semanticLabel,
    this.startLabel,
    this.endLabel,
    super.key,
  });

  /// Each payment's day and amount.
  final List<(int, double)> visits;

  /// How many days the month has.
  final int days;

  /// Today's day; the days after it are shaded.
  final int today;

  /// The record's own day, drawn solid.
  final int? current;

  /// Whether the payments came in (a payer), inked green.
  final bool moneyIn;

  /// What a screen reader says the ruler is; null says the visits.
  final String? semanticLabel;

  /// The month's first and last day under the ruler's two ends.
  final String? startLabel;

  /// The month's last day, under the ruler's end.
  final String? endLabel;

  static const double _height = 34;

  // `.ruler-labs`: 4 under the ruler, 400 10 on 12 in the mono, the third
  // ink, at both widths.
  static const double _labelsTop = 4;
  static const double _labelSize = 10;
  static const double _labelLine = 12;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final ruler = LedgerPlot(
      phoneAspect: 0,
      deskAspect: 0,
      height: _height,
      draw: (size, _) =>
          (painter: _Engraving(_ops(t, size.width)), labels: const []),
    );
    final style = t.meta
        .sized(_labelSize)
        .line(_labelLine)
        .tracked(0)
        .colored(t.textTertiary);
    return Semantics(
      label: semanticLabel ?? '${visits.length} payments this month',
      excludeSemantics: true,
      child: startLabel == null && endLabel == null
          ? ruler
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ruler,
                const SizedBox(height: _labelsTop),
                // Under its ruler, which reads left to right in any page.
                Row(
                  textDirection: TextDirection.ltr,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(startLabel ?? '', style: style, softWrap: false),
                    Text(endLabel ?? '', style: style, softWrap: false),
                  ],
                ),
              ],
            ),
    );
  }

  List<void Function(Canvas)> _ops(LedgerThemeData t, double w) {
    const yb = 24.0, top = 2.0;
    final slot = w / days;
    final bw = math.max(2.4, slot * .5);
    final ink = t.textPrimary;
    final color = moneyIn ? t.moneyIn : ink;
    final per = <int, double>{};
    for (final (d, a) in visits) {
      per[d] = (per[d] ?? 0) + a;
    }
    final hi = per.isEmpty ? 1.0 : per.values.reduce(math.max);
    final ops = <void Function(Canvas)>[
      (c) => ledgerAhead(c, Rect.fromLTRB(today * slot, top, w, yb), ink),
    ];
    for (final d in per.keys.toList()..sort()) {
      final bh = math.max(3.0, per[d]! / hi * (yb - top - 2));
      final x0 = (d - .5) * slot - bw / 2;
      final bar = Rect.fromLTWH(x0, yb - bh, bw, bh);
      if (d == current) {
        ops.add((c) => c.drawRect(bar, Paint()..color = color));
      } else {
        final hatch = ledgerHatchRect(x0, yb - bh, x0 + bw, yb, 2.2);
        ops
          ..add(
            (c) => c.drawPath(hatch, ledgerStroke(ledgerInk(color, .7), .6)),
          )
          ..add((c) => c.drawRect(bar, ledgerStroke(color, .75)));
      }
    }
    ops
      ..add(
        (c) => c.drawLine(
          const Offset(0, yb),
          Offset(w, yb),
          ledgerStroke(ink, 1),
        ),
      )
      ..add(
        (c) => ledgerRulerTicks(
          c,
          (d) => d * slot,
          yb,
          days,
          today,
          ink,
          long: {0, 7, 14, 21, 28, days},
          longTick: 6,
          shortTick: 3,
          longWidth: .8,
          shortWidth: .5,
        ),
      );
    return ops;
  }
}

/// A month as a line (`art.month_line`): an account's balance or a
/// portfolio by the end of each day from its [start], engraved under the
/// inked line on the month's ruler, its [marks] ringed (a payday above, a
/// card's payment below), today ringed green with its [endLabel] (above
/// its ring with [endAbove]), the days ahead shaded, the [grid] dotted.
/// 342 by 196 on a phone, 712 by 300 from 1024, or [height] / [deskHeight].
///
/// ```dart
/// LedgerMonthLine(values: balance, start: 2479.82, days: 31, low: 0, high: 7400, grid: grid, endLabel: '\$6,248.30')
/// ```
class LedgerMonthLine extends StatelessWidget {
  /// A month's daily [values] from [start], between [low] and [high].
  const LedgerMonthLine({
    required this.values,
    required this.start,
    required this.days,
    required this.low,
    required this.high,
    required this.grid,
    this.endLabel,
    this.marks = const [],
    this.endAbove = false,
    this.month = 'Oct',
    this.height,
    this.deskHeight,
    this.semanticLabel = 'Balance through the month',
    super.key,
  });

  /// The balance by the end of each day so far.
  final List<double> values;

  /// The balance the month opened with.
  final double start;

  /// How many days the month has.
  final int days;

  /// The plot's floor.
  final double low;

  /// The plot's ceiling.
  final double high;

  /// The dotted lines across, with their scale.
  final List<LedgerGridLine> grid;

  /// Today's words beside its ring.
  final String? endLabel;

  /// The days ringed and labelled (a payday, a card's payment).
  final List<LedgerChartMark> marks;

  /// Whether today's words stand above its ring.
  final bool endAbove;

  /// The month's short name, for the ruler's first label.
  final String month;

  /// The plot's height on a phone.
  final double? height;

  /// The plot's height from 1024.
  final double? deskHeight;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 196, gut: 30, spacing: 3.1, sw: .6);
  static const _Spec _desk = (w: 712, h: 300, gut: 40, spacing: 3.5, sw: .65);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final today = values.length;
    return Semantics(
      label: semanticLabel,
      value: endLabel,
      excludeSemantics: true,
      child: _WithRuler(
        plot: LedgerPlot(
          phoneAspect: _phone.h / _phone.w,
          deskAspect: _desk.h / _desk.w,
          height: wide ? deskHeight : height,
          draw: (size, wide) => _draw(t, size, wide),
        ),
        ruler: (width, wide) {
          final wp = width - (wide ? _desk : _phone).gut;
          return _dayRuler(
            context,
            (d) => d / days * wp,
            days,
            today,
            wide,
            month,
          );
        },
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    const top = 10.0;
    final wp = w - s.gut, yb = h - 14;
    final today = values.length;
    double x(int d) => d / days * wp;
    double y(double v) => top + (high - v) / (high - low) * (yb - top);
    final pts = [
      Offset(x(0), y(start)),
      for (var d = 0; d < values.length; d++) Offset(x(d + 1), y(values[d])),
    ];
    final ink = t.textPrimary, green = t.pace, paper = t.background;
    final area = ledgerEngravedArea(pts, top, yb, s.spacing);
    final last = pts.last;
    final ops = <void Function(Canvas)>[
      for (final g in grid) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      (c) => ledgerAhead(c, Rect.fromLTRB(x(today), top, x(days), yb), ink),
      (c) => ledgerPaintArea(
        c,
        area,
        ledgerFade(ink, top, yb, a1: .12),
        ink,
        s.sw,
      ),
      (c) => ledgerInkedLine(c, pts, ink, paper),
    ];
    final labels = <LedgerPlotLabel>[];
    for (final m in marks) {
      final p = pts[m.day];
      ops.add(
        m.below
            ? (c) => ledgerRing(c, p, ink, paper, radius: 2.6)
            : (c) => ledgerRing(c, p, green, paper, radius: 3, width: 1.3),
      );
      labels.add(
        _markLabel(t, p.dx, p.dy + (m.below ? 4 : -4), m.text, below: m.below),
      );
    }
    ops
      ..add((c) => ledgerDrop(c, last, Offset(last.dx, yb), green))
      ..add((c) => ledgerNowMark(c, last, green, paper))
      ..add(
        (c) => c.drawLine(Offset(0, yb), Offset(wp, yb), ledgerStroke(ink, 1)),
      )
      ..add((c) => ledgerRulerTicks(c, x, yb, days, today, ink));
    for (final g in [...grid]..sort((a, b) => b.value.compareTo(a.value))) {
      labels.add(_scaleLabel(t, wide, y(g.value), g.label));
    }
    if (endLabel case final words?) {
      labels.add(
        endAbove
            ? _pointLabel(t, Offset(last.dx, last.dy - 9), words, end: true)
            : _pointLabel(t, last, words),
      );
    }
    return (painter: _Engraving(ops), labels: labels);
  }
}

/// The bracket over a run of [LedgerMonthBars] and its words.
///
/// ```dart
/// LedgerChartBracket(2, 11, '2026 to date **\$667.75**')
/// ```
class LedgerChartBracket {
  /// A bracket from bar [first] to bar [last], worded [text].
  const LedgerChartBracket(this.first, this.last, this.text);

  /// The first bar's index.
  final int first;

  /// The last bar's index.
  final int last;

  /// The bracket's words, its `**strong**` run in the ink.
  final String text;
}

/// Months as bars (`art.month_bars`): one hatched bar per month, the
/// latest solid, on a double rule; a [bracket] over a run of them with its
/// words, [marks] labelling a bar's top (the latest's ending on its right
/// side). Green by default. 342 by 164 on a phone (its bars 58 under the
/// top), 712 by 240 from 1024 (64).
///
/// ```dart
/// LedgerMonthBars(values: interest, bracket: const LedgerChartBracket(2, 11, '2026 to date **\$667.75**'), marks: const [LedgerChartMark(11, '+\$73.42')])
/// ```
class LedgerMonthBars extends StatelessWidget {
  /// A bar for each of [values], the latest solid.
  const LedgerMonthBars({
    required this.values,
    this.bracket,
    this.marks = const [],
    this.tone = LedgerBarTone.green,
    this.high,
    this.months,
    this.height,
    this.semanticLabel = 'By month',
    super.key,
  });

  /// Each month's amount, the latest last.
  final List<double> values;

  /// A bracket over a run of the bars.
  final LedgerChartBracket? bracket;

  /// Each mark's [LedgerChartMark.day] is a bar's index.
  final List<LedgerChartMark> marks;

  /// How the bars are inked; green by default.
  final LedgerBarTone tone;

  /// The plot's ceiling; null takes the tallest bar's.
  final double? high;

  /// A key under each bar.
  final List<String>? months;

  /// The plot's height; null takes the phone's or the desktop's.
  final double? height;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _phone = (w: 342.0, h: 164.0, top: 58.0, spacing: 2.6);
  static const _desk = (w: 712.0, h: 240.0, top: 64.0, spacing: 3.0);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LedgerPlot(
            phoneAspect: _phone.h / _phone.w,
            deskAspect: _desk.h / _desk.w,
            height: height,
            draw: (size, wide) => _draw(t, size, wide),
          ),
          if (months case final keys?)
            LedgerMonthKeys(keys: keys, now: keys.length - 1),
        ],
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    final n = values.length;
    final yb = h - 5.5, slot = w / n, bw = slot * .5;
    final hi = high ?? values.reduce(math.max) * 1.08;
    final top = s.top;
    double y(double v) => top + (hi - v) / hi * (yb - top);
    double cx(int i) => (i + .5) * slot;
    final ink = t.textPrimary;
    final color = tone == LedgerBarTone.green ? t.pace : ink;
    final ops = <void Function(Canvas)>[];
    for (var i = 0; i < n; i++) {
      final x0 = cx(i) - bw / 2, y0 = y(values[i]);
      final bar = Rect.fromLTRB(x0, y0, x0 + bw, yb);
      if (i == n - 1) {
        ops.add((c) => c.drawRect(bar, Paint()..color = color));
      } else {
        final hatch = ledgerHatchRect(x0, y0, x0 + bw, yb, s.spacing);
        ops
          ..add(
            (c) => c.drawPath(hatch, ledgerStroke(ledgerInk(color, .75), .6)),
          )
          ..add((c) => c.drawRect(bar, ledgerStroke(color, .8)));
      }
    }
    final labels = <LedgerPlotLabel>[];
    if (bracket case final b?) {
      final x0 = cx(b.first) - bw / 2, x1 = cx(b.last) + bw / 2;
      final yk = top - 24;
      ops.add(
        (c) => c.drawPath(
          Path()
            ..moveTo(x0, yk + 5)
            ..lineTo(x0, yk)
            ..lineTo(x1, yk)
            ..lineTo(x1, yk + 5),
          ledgerStroke(ink, .8),
        ),
      );
      labels.add(
        LedgerPlotLabel(
          left: (x0 + x1) / 2,
          top: yk,
          shift: const Offset(-.5, -1),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: ledgerPlotText(b.text, t.plotCaption, t.textPrimary),
          ),
        ),
      );
    }
    for (final m in marks) {
      final i = m.day;
      labels.add(
        i == n - 1
            ? _markLabel(t, cx(i) + bw / 2, y(values[i]) - 2, m.text, end: true)
            : _markLabel(t, cx(i), y(values[i]) - 2, m.text),
      );
    }
    ops.add((c) => ledgerDoubleRule(c, yb + 3, 0, w, ink));
    return (painter: _Engraving(ops), labels: labels);
  }
}

/// A month of bills summed as they fall due (`art.step_total`): the
/// running total steps up on each due date, engraved under the inked
/// steps, each step ringed, the large bills' [notes] hung on leaders, the
/// [grid] dotted, the month's ruler under it (1, 8, 15, 22, the last day).
/// 342 by 220 on a phone, 712 by 320 from 1024.
///
/// ```dart
/// LedgerStepTotal(steps: const [(1, 1150), (3, 35)], days: 30, high: 3000, grid: grid, month: 'Nov')
/// ```
class LedgerStepTotal extends StatelessWidget {
  /// A month of [days] whose bills' [steps] sum up to [high].
  const LedgerStepTotal({
    required this.steps,
    required this.days,
    required this.high,
    required this.grid,
    this.notes = const [],
    this.month = 'Nov',
    this.height,
    this.semanticLabel = 'Bills summed as they fall due',
    super.key,
  });

  /// Each bill's day and amount, in date order.
  final List<(int, double)> steps;

  /// How many days the month has.
  final int days;

  /// The plot's ceiling.
  final double high;

  /// The dotted lines across, with their scale.
  final List<LedgerGridLine> grid;

  /// Notes hung on the large bills' steps.
  final List<LedgerChartNote> notes;

  /// The month's short name, for the ruler's labels.
  final String month;

  /// The plot's height; null takes the phone's or the desktop's.
  final double? height;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 220, gut: 30, spacing: 3.1, sw: .6);
  static const _Spec _desk = (w: 712, h: 320, gut: 40, spacing: 3.5, sw: .65);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: _WithRuler(
        plot: LedgerPlot(
          phoneAspect: _phone.h / _phone.w,
          deskAspect: _desk.h / _desk.w,
          height: height,
          draw: (size, wide) => _draw(t, size, wide),
        ),
        ruler: (width, wide) {
          final slot = (width - (wide ? _desk : _phone).gut) / days;
          return [
            for (final day in [1, 8, 15, 22, days])
              (
                text: day == 1 ? '$month 1' : '$day',
                x: day == 1 ? 0.0 : (day - 1) * slot + slot / 2,
                first: day == 1,
                today: false,
              ),
          ];
        },
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    const top = 8.0;
    final wp = w - s.gut, yb = h - 14, slot = wp / days;
    double x(int d) => d * slot;
    double y(double v) => top + (high - v) / high * (yb - top);
    final pts = <Offset>[Offset(0, y(0))];
    final risers = <Offset>[];
    var run = 0.0;
    for (final (day, a) in steps) {
      final sx = x(day - 1) + slot / 2;
      pts.add(Offset(sx, y(run)));
      run += a;
      pts.add(Offset(sx, y(run)));
      risers.add(Offset(sx, y(run)));
    }
    pts.add(Offset(x(days), y(run)));
    // The risers nudged apart so the hatch has a function to follow.
    final fnPts = [
      for (var i = 0; i < pts.length; i++)
        Offset(pts[i].dx + (i.isEven && i > 0 ? .01 : 0), pts[i].dy),
    ];
    final ink = t.textPrimary, paper = t.background;
    final area = ledgerEngravedArea(fnPts, top, yb, s.spacing, band: false);
    final ops = <void Function(Canvas)>[
      for (final g in grid) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      (c) => ledgerPaintArea(
        c,
        area,
        ledgerFade(ink, top, yb, a1: .12),
        ink,
        s.sw,
      ),
      (c) => ledgerInkedLine(c, pts, ink, paper),
      for (final r in risers) (c) => ledgerRing(c, r, ink, paper),
      (c) => c.drawLine(Offset(0, yb), Offset(wp, yb), ledgerStroke(ink, 1)),
      // A tick under each day's centre, where its steps and labels stand.
      (c) => ledgerRulerTicks(
        c,
        (d) => x(d - 1) + slot / 2,
        yb,
        days,
        -1,
        ink,
        from: 1,
        long: {1, 8, 15, 22, 29, days},
      ),
    ];
    final labels = [
      for (final g in [...grid]..sort((a, b) => b.value.compareTo(a.value)))
        _scaleLabel(t, wide, y(g.value), g.label),
      for (final n in notes)
        if (n.index < risers.length)
          _noteLabel(
            t,
            risers[n.index],
            math.min(wide ? n.deskLift : n.lift, risers[n.index].dy - 2),
            wide ? n.deskText : n.text,
          ),
    ];
    return (painter: _Engraving(ops), labels: labels);
  }
}

/// A goal's saving over time (`art.goal_chart`): the months saved engraved
/// in the green under the inked line, each ringed, today green with its
/// halo; the [target] as a double rule with its label; the [projection]
/// on as a dashed green line to a ring at the goal's date over the shaded
/// months ahead, its [endLabel] at the foot; or, with no projection, the
/// [gapLabel]'s dimension line from today up to the target. [months] keys
/// the months under it. 342 by 196 on a phone, 712 by 300 from 1024, or
/// [height] / [deskHeight].
///
/// ```dart
/// LedgerGoalChart(history: saved, months: 19, target: 4000, low: 0, high: 4400, grid: grid, targetLabel: 'Target \$4,000')
/// ```
class LedgerGoalChart extends StatelessWidget {
  /// A goal's [history] over [months] against its [target].
  const LedgerGoalChart({
    required this.history,
    required this.months,
    required this.target,
    required this.low,
    required this.high,
    required this.grid,
    required this.targetLabel,
    this.projection = const [],
    this.endLabel,
    this.gapLabel,
    this.keys,
    this.now,
    this.height,
    this.deskHeight,
    this.semanticLabel = 'Saved over time against the target',
    super.key,
  });

  /// Each month's index and the sum saved by its end, up to now.
  final List<(int, double)> history;

  /// Each later month's index and the sum projected by its end.
  final List<(int, double)> projection;

  /// How many months the plot spans.
  final int months;

  /// The goal's target, drawn as a double rule.
  final double target;

  /// The plot's floor.
  final double low;

  /// The plot's ceiling.
  final double high;

  /// The dotted lines across, with their scale.
  final List<LedgerGridLine> grid;

  /// The target rule's words.
  final String targetLabel;

  /// The projection's words at its foot.
  final String? endLabel;

  /// With no projection, the words of the gap from today to the target.
  final String? gapLabel;

  /// Each month's key under the plot, and which is now (green).
  final List<String>? keys;

  /// The index of the key that is now.
  final int? now;

  /// The plot's height on a phone.
  final double? height;

  /// The plot's height from 1024.
  final double? deskHeight;

  /// What a screen reader says the chart is.
  final String semanticLabel;

  static const _Spec _phone = (w: 342, h: 196, gut: 30, spacing: 3.1, sw: .6);
  static const _Spec _desk = (w: 712, h: 300, gut: 40, spacing: 3.5, sw: .65);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final wide = LedgerLayout.isWide(context);
    final s = wide ? _desk : _phone;
    return Semantics(
      label: semanticLabel,
      value: targetLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          LedgerPlot(
            phoneAspect: _phone.h / _phone.w,
            deskAspect: _desk.h / _desk.w,
            height: wide ? deskHeight : height,
            draw: (size, wide) => _draw(t, size, wide),
          ),
          if (keys case final k?)
            LedgerMonthKeys(
              keys: k,
              gutter: s.gut,
              now: now,
              end: projection.isEmpty ? null : k.length - 1,
            ),
        ],
      ),
    );
  }

  LedgerPlotParts _draw(LedgerThemeData t, Size size, bool wide) {
    final s = wide ? _desk : _phone;
    final w = size.width, h = size.height;
    const top = 8.0;
    final wp = w - s.gut, yb = h - 5.5;
    double x(int i) => (i + .5) * wp / months;
    double y(double v) => top + (high - v) / (high - low) * (yb - top);
    final hp = [for (final (i, v) in history) Offset(x(i), y(v))];
    final pp = [hp.last, for (final (i, v) in projection) Offset(x(i), y(v))];
    final ink = t.textPrimary, green = t.pace, paper = t.background;
    final area = ledgerEngravedArea(hp, top, yb, s.spacing);
    final now = hp.last, end = pp.last;
    final ahead = projection.isNotEmpty;
    final ops = <void Function(Canvas)>[
      for (final g in grid) (c) => ledgerDotted(c, y(g.value), 0, w, ink),
      if (ahead)
        (c) =>
            ledgerAhead(c, Rect.fromLTRB(now.dx, top, x(months - 1), yb), ink),
      (c) => ledgerDoubleRule(c, y(target), 0, w, ink),
      (c) => ledgerPaintArea(
        c,
        area,
        ledgerFade(green, top, yb, a0: .7, a1: .12),
        green,
        s.sw,
      ),
      if (ahead)
        (c) => ledgerInkedLine(
          c,
          pp,
          green,
          paper,
          width: 1.4,
          knock: 4.5,
          dash: const [4, 3],
        ),
      (c) => ledgerInkedLine(c, hp, ink, paper),
      for (final p in hp.take(hp.length - 1))
        (c) => ledgerRing(c, p, ink, paper, radius: 2.2),
      if (ahead) ...[
        (c) => ledgerDrop(
          c,
          Offset(end.dx, top),
          Offset(end.dx, yb),
          green,
          width: .9,
        ),
        (c) => ledgerRing(c, end, green, paper, radius: 3.4, width: 1.4),
      ],
      (c) => ledgerNowMark(c, now, green, paper),
      (c) => c
        ..drawLine(Offset(0, yb), Offset(w, yb), ledgerStroke(ink, 1))
        ..drawLine(
          Offset(0, h - 1.5),
          Offset(w, h - 1.5),
          ledgerStroke(ink, .6),
        ),
    ];
    final labels = [
      for (final g in [...grid]..sort((a, b) => b.value.compareTo(a.value)))
        _scaleLabel(t, wide, y(g.value), g.label),
      _budgetLabel(t, wide, y(target) - 3, targetLabel),
      if (endLabel case final words?)
        _pointLabel(t, Offset(end.dx, yb - 5), words, end: true),
    ];
    if (gapLabel case final words?) {
      final g0 = y(target) + 2.5, g1 = now.dy - 12;
      ops
        ..add(
          (c) => c.drawPath(
            ledgerDashed(
              Path()
                ..moveTo(now.dx, g0)
                ..lineTo(now.dx, g1),
              const [2, 2.4],
            ),
            ledgerStroke(ink, .9),
          ),
        )
        ..add(
          (c) => c.drawLine(
            Offset(now.dx - 4.5, g0),
            Offset(now.dx + 4.5, g0),
            ledgerStroke(ink, 1.1),
          ),
        );
      labels.add(
        LedgerPlotLabel(
          left: now.dx,
          top: (g0 + g1) / 2,
          shift: const Offset(-1, -.5),
          child: Padding(
            padding: const EdgeInsets.only(right: 14),
            child: ledgerPlotText(
              words,
              t.plotPoint
                  .copyWith(fontWeight: FontWeight.w400)
                  .colored(t.textSecondary),
              t.textPrimary,
            ),
          ),
        ),
      );
    }
    return (painter: _Engraving(ops), labels: labels);
  }
}
