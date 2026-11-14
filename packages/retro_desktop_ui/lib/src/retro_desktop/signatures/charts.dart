// Facts as drawings, all from plain data: a gauge with a real thumb, a month, the next hours under a time-lapse of pixel sky,
// ten days as one pixel shape, hatched bars, a scale with a knob, a span. Everything lands on the device's grid, and nothing
// is a picture: each is worked out from the numbers it's given.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../press.dart';

import '../glyphs.dart';

import '../acts.dart';
import '../controls.dart';
import '../frames.dart';
import '../layout.dart';
import '../pixels.dart';
import '../theme.dart';
import '../localizations.dart';
import '../component_themes.dart';
import '../internal/face.dart';
import '../shapes.dart';

class _GaugePainter extends RetroDesktopPixelPainter {
  const _GaugePainter(this.c, this.share, this.shape, {this.rtl = false});
  final RetroDesktopColors c;
  final double share;
  final OutlinedBorder shape;
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final r = px.snap(Offset.zero & s);
    final outline = shape.copyWith(
      side: BorderSide(color: c.control, width: px.hairX),
    );
    canvas.save();
    canvas.clipPath(outline.getOuterPath(r));
    final w = px.hairX, h = px.hair;
    canvas.drawRect(r, Paint()..color = c.platinumDark);
    final inner = Rect.fromLTRB(
      r.left + w,
      r.top + h,
      r.right - w,
      r.bottom - h,
    );
    px.bevel(inner, c.bevelDark, c.bevelLight);
    // The thumb fills from the reading start: from the right in right-to-left (it stood at the left, away from its
    // "Used" under the right end). Its bevel keeps the light at the top left.
    final run = inner.width * share.clamp(0, 1);
    final from = rtl ? px.x(inner.right - run) : inner.left;
    final to = rtl ? inner.right : px.x(inner.left + run);
    if (to > from) {
      final thumb = Rect.fromLTRB(from, inner.top, to, inner.bottom);
      final thumbShape = RetroDesktopShapes.inset(outline, w);
      canvas.save();
      canvas.clipPath(thumbShape.getOuterPath(thumb));
      canvas.drawPath(
        thumbShape.getOuterPath(thumb),
        Paint()..color = Color.lerp(c.thumbTop, c.thumbBottom, .5)!,
      );
      // Its end inside the track a line of the outline.
      final body = rtl
          ? Rect.fromLTRB(from + w, thumb.top, to, thumb.bottom)
          : Rect.fromLTRB(from, thumb.top, to - w, thumb.bottom);
      px.bevel(body, const Color(0x8CFFFFFF), c.bevelDark);
      if (rtl) {
        px.fillExact(from, thumb.top, from + w, thumb.bottom, c.outline);
      } else {
        px.fillExact(to - w, thumb.top, to, thumb.bottom, c.outline);
      }
      if (body.width >= 18) {
        final mid = (body.left + body.right) / 2;
        final top = px.y((body.top + body.bottom) / 2 - 4);
        for (final dx in [-5.0, -1.0, 3.0]) {
          final x = px.x(mid + dx);
          px.fillExact(x, top, x + w, top + 8 * h, c.textSecondary);
          px.fillExact(
            x + w,
            top,
            x + 2 * w,
            top + 8 * h,
            const Color(0xB3FFFFFF),
          );
        }
      }
      canvas.restore();
      thumbShape
          .copyWith(
            side: BorderSide(color: c.outline, width: w),
          )
          .paint(canvas, thumb);
    }
    canvas.restore();
    outline.paint(canvas, r);
  }

  @override
  bool shouldRepaint(_GaugePainter o) =>
      o.c != c || o.share != share || o.shape != shape || o.rtl != rtl;
}

/// How much of a whole: a scroll thumb sized to it in a sunk track, with its three grip lines.
///
/// ```dart
/// RetroDesktopThumbGauge(share: .28)
/// ```
class RetroDesktopThumbGauge extends StatelessWidget {
  /// Creates a [RetroDesktopThumbGauge].
  const RetroDesktopThumbGauge({super.key, required this.share});

  /// The proportion represented by this part.
  final double share;
  @override
  Widget build(BuildContext context) => Semantics(
    value: RetroDesktopLocalizations.of(context)
        .formatPercent(share.clamp(0, 1)),
    child: SizedBox(
      height: 18,
      child: RetroDesktopPixelPaint(
        painter: _GaugePainter(
          RetroDesktopTheme.of(context).colors,
          share,
          RetroDesktopTheme.of(context).shapes.full,
          rtl: Directionality.of(context) == TextDirection.rtl,
        ),
      ),
    ),
  );
}

/// A gauge and its words: the amount big, of what, a share at the end; the bar; a small line each end under it.
///
/// ```dart
/// RetroDesktopGaugeBlock(value: '1.38 GB', of: 'of 5 GB', share: .28, endLabel: '28%', footStart: 'Used', footEnd: '3.62 GB free')
/// ```
class RetroDesktopGaugeBlock extends StatelessWidget {
  /// Creates a [RetroDesktopGaugeBlock].
  const RetroDesktopGaugeBlock({
    super.key,
    required this.value,
    required this.share,
    this.of,
    this.endLabel,
    this.footStart,
    this.footEnd,
  });

  /// The current value to display or edit.
  final String value;

  /// The capacity or total beside [value], such as "of 5 GB".
  final String? of;

  /// The ending label or boundary.
  final String? endLabel;

  /// The footnote at the start edge.
  final String? footStart;

  /// The footnote at the end edge.
  final String? footEnd;

  /// The proportion represented by this part.
  final double share;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final smallPx = t.type.chrome.copyWith(color: c.textSecondary);
    return RetroDesktopColumn(
      gap: 6,
      children: [
        RetroDesktopFitRow(
          fill: 0,
          gap: 8,
          align: RetroDesktopFitAlign.baseline,
          fillShare: .5,
          children: [
            Text.rich(
              TextSpan(
                text: value,
                style: t.type.big,
                children: [
                  if (of != null) TextSpan(text: ' $of', style: smallPx),
                ],
              ),
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
            ),
            if (endLabel != null) Text(endLabel!, style: smallPx, maxLines: 1),
          ],
        ),
        RetroDesktopThumbGauge(share: share),
        if (footStart != null || footEnd != null)
          RetroDesktopFitRow(
            fill: 0,
            gap: 8,
            fillShare: .3,
            children: [
              Text(
                footStart ?? '',
                style: t.type.caption,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
              ),
              if (footEnd != null)
                Text(
                  footEnd!,
                  style: t.type.caption,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
      ],
    );
  }
}

/// One day's small marks in a `RetroDesktopMonthGrid`: [remaining] solid pips, [completed] outlined, and an [icon].
class RetroDesktopDayMarks {
  /// Creates a [RetroDesktopDayMarks].
  const RetroDesktopDayMarks({
    this.remaining = 0,
    this.completed = 0,
    this.icon,
    this.overdue = false,
  });

  /// The number of unfinished items represented by the open pips.
  final int remaining;

  /// The number of completed items represented by the completed pips.
  final int completed;

  /// The glyph shown with the content.
  final IconData? icon;

  /// The date goes inverted.
  final bool overdue;
}

class _PipsPainter extends RetroDesktopPixelPainter {
  const _PipsPainter(this.ink, this.outline, this.open, this.done);
  final Color ink, outline;
  final int open, done;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final fit = math.max(1, ((s.width + 2) / 9).floor());
    for (var i = 0; i < open + done; i++) {
      final at = Rect.fromLTWH((i % fit) * 9.0, (i ~/ fit) * 9.0, 7, 7);
      if (i < open) {
        px.fill(at, ink);
      } else {
        px.frame(at, outline);
      }
    }
  }

  @override
  bool shouldRepaint(_PipsPainter o) =>
      o.ink != ink || o.outline != outline || o.open != open || o.done != done;
}

// A month's cells join edge to edge, so they stay square and share their
// rules; the day that is today is a tile inset in its cell, in the family's
// control shape, so it reads at a glance without a second frame around it.
class _CellPainter extends RetroDesktopPixelPainter {
  const _CellPainter(this.fill, this.rule, this.right, this.tile, this.shape);
  final Color fill;
  final Color? rule;
  final bool right;
  final Color? tile;
  final OutlinedBorder shape;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    px.canvas.drawRect(r, Paint()..color = fill);
    final w = px.hairX, h = px.hair;
    if (rule != null) {
      px.fillExact(r.left, r.bottom - h, r.right, r.bottom, rule!);
      if (right) px.fillExact(r.right - w, r.top, r.right, r.bottom, rule!);
    }
    if (tile != null) {
      // Today's ring, two pixels in: not a lit tile (lit is chosen).
      px.canvas.drawPath(
        shape.getOuterPath(r.deflate(3)),
        Paint()
          ..color = tile!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_CellPainter o) =>
      o.fill != fill ||
      o.rule != rule ||
      o.right != right ||
      o.tile != tile ||
      o.shape != shape;
}

/// The head over a month: its name big, and the small buttons that move it.
///
/// ```dart
/// RetroDesktopMonthHead('November 2026', onPrevious: () {}, onToday: () {}, onNext: () {})
/// ```
class RetroDesktopMonthHead extends StatelessWidget {
  /// Creates a [RetroDesktopMonthHead].
  const RetroDesktopMonthHead(
    this.title, {
    super.key,
    this.onPrevious,
    this.onToday,
    this.onNext,
  });

  /// The heading displayed above the content.
  final String title;

  /// Called to move to the previous period.
  final VoidCallback? onPrevious;

  /// Called to return to the current calendar day.
  final VoidCallback? onToday;

  /// Called to move to the next period.
  final VoidCallback? onNext;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    // The arrows show the small Today button's height, square: one top and
    // one bottom across the three (Chisel's small icon button stood shorter).
    final arrow = RetroDesktopStyle(
      minimumSize: WidgetStatePropertyAll(
        Size.square(retroDesktopSmallButtonFaceHeight(context)),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      // The month's name and its three buttons on one line where they fit, the name at the start and the buttons at
      // the end; where they don't (a phone, twice the text size), the buttons go under the name, each keeping its
      // whole reach and the name its whole word.
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: [
          Text(
            title,
            style: t.type.big,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
          ),
          // Never wider than the head: in a very narrow one Today gives way between its arrows.
          RetroDesktopFitRow(
            fill: 1,
            gap: 6,
            shrink: true,
            children: [
              RetroDesktopIconButton.triangle(
                rtl ? AxisDirection.right : AxisDirection.left,
                label: DesignLocalizations.of(context).previousMonthTooltip,
                onPressed: onPrevious,
                style: arrow,
              ),
              RetroDesktopButton(
                DesignLocalizations.of(context).currentDateLabel,
                size: RetroDesktopButtonSize.small,
                onPressed: onToday,
              ),
              RetroDesktopIconButton.triangle(
                rtl ? AxisDirection.left : AxisDirection.right,
                label: DesignLocalizations.of(context).nextMonthTooltip,
                onPressed: onNext,
                style: arrow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A month from its numbers: weeks from Monday, the days of other months quieter, this week tinted, today lit, a pip for each
/// thing on a day. Nothing is hand-laid: give it a year, a month and what's on. It brings its well.
///
/// ```dart
/// RetroDesktopMonthGrid(year: 2026, month: 11, today: 11, days: const {11: RetroDesktopDayMarks(remaining: 4, completed: 1), 9: RetroDesktopDayMarks(remaining: 1, overdue: true)})
/// ```
class RetroDesktopMonthGrid extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopMonthGrid].
  const RetroDesktopMonthGrid({
    super.key,
    this.style,
    required this.year,
    required this.month,
    this.today,
    this.days = const {},
    this.weekdays,
    this.onDay,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The calendar year displayed by this part.
  final int year;

  /// The month value or label displayed by this part.
  final int month;

  /// The day of this month to light; none, if it isn't this month.
  final int? today;

  /// The data for the days displayed in the calendar.
  final Map<int, RetroDesktopDayMarks> days;

  /// Seven names, Monday first.
  final List<String>? weekdays;

  /// Reports the calendar day selected by the user.
  final ValueChanged<int>? onDay;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final words = RetroDesktopLocalizations.of(context);
    final dayNames = weekdays ?? words.weekdays;
    final first = DateTime.utc(year, month, 1);
    final lead = (first.weekday - DateTime.monday) % 7;
    final length = DateTime.utc(year, month + 1, 0).day;
    final previous = DateTime.utc(year, month, 0).day;
    final weeks = ((lead + length + 6) ~/ 7);
    final height = math.max(
      RetroDesktopReach.least(context),
      MediaQuery.textScalerOf(context).scale(16) + 22,
    );
    return RetroDesktopWell(
      style: style,
      child: LayoutBuilder(
        builder: (context, box) {
          final available = math.max(
            box.maxWidth,
            7 * RetroDesktopReach.least(context),
          );
          double edge(int index) =>
              (index * available / 7).roundToDouble().clamp(0.0, available);
          final widths = [for (var i = 0; i < 7; i++) edge(i + 1) - edge(i)];
          final todayWeek = today == null ? -1 : (lead + today! - 1) ~/ 7;
          Widget cell(int week, int col) {
            final n = week * 7 + col - lead + 1;
            final inMonth = n >= 1 && n <= length;
            final label = inMonth ? n : (n < 1 ? previous + n : n - length);
            final now = inMonth && n == today;
            final marks = inMonth ? days[n] : null;
            // Only another month's days are dim; today is ringed, not lit (lit is chosen, the state law); this week
            // is outlined round its row below.
            final fill = inMonth ? c.paper : c.paperDim;
            final ink = inMonth ? c.text : c.textTertiary;
            final dayNumber = Text(
              words.formatInteger(label),
              style: t.type.pixel(16, 14, color: ink),
              maxLines: 1,
            );
            // An overdue day's number stands in an outlined pill: marked, not chosen (inverted words are chosen).
            final Widget day = marks?.overdue == true && !now
                ? DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: t.shapes.full.copyWith(
                        side: BorderSide(color: c.text),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(3, 1, 3, 0),
                      child: dayNumber,
                    ),
                  )
                : dayNumber;
            final box = RetroDesktopPixelPaint(
              painter: _CellPainter(
                fill,
                c.divider,
                col < 6,
                // Today's ring in ink: in the highlight's colour, inside this
                // week's highlight frame, it read as a chosen day.
                now ? c.text : null,
                t.shapes.small.copyWith(side: BorderSide.none),
              ),
              child: SizedBox(
                height: height,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(6, 4, 5, 5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Transform.translate(
                        offset: Offset(
                          marks?.overdue == true && !now ? -3 : 0,
                          0,
                        ),
                        child: day,
                      ),
                      if (marks != null)
                        Row(
                          children: [
                            Flexible(
                              child: SizedBox(
                                height: 7,
                                width:
                                    (marks.remaining + marks.completed) * 9.0,
                                child: RetroDesktopPixelPaint(
                                  painter: _PipsPainter(
                                    ink,
                                    c.textSecondary,
                                    marks.remaining,
                                    marks.completed,
                                  ),
                                ),
                              ),
                            ),
                            if (marks.icon != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 2),
                                child: Icon(marks.icon, size: 11, color: ink),
                              ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
            if (onDay == null || !inMonth) return box;
            return RetroDesktopPressable(
              button: true,
              label: words.formatDate(DateTime(year, month, n)),
              onPressed: () => onDay!(n),
              // Cells join, so the ring stands inside, on today's tile.
              focusShape: t.shapes.small,
              ringInside: true,
              child: box,
            );
          }

          // The day names whole in their heads: where a name is wider than its column (large text, a narrow
          // desk), the two-letter names, then the first letters; a name is never sliced.
          final headStyle = t.type.pixel(16, 21, color: c.textSecondary);
          bool fits(List<String> names) {
            for (var i = 0; i < 7 && i < names.length; i++) {
              final p = TextPainter(
                text: TextSpan(text: names[i], style: headStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final width = p.width;
              p.dispose();
              if (width > widths[i] - 12) return false;
            }
            return true;
          }

          final initials = [
            for (final name in dayNames) name.characters.take(1).toString(),
          ];
          final heads = fits(dayNames)
              ? dayNames
              : weekdays == null && fits(words.weekdaysShort)
              ? words.weekdaysShort
              : initials;
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: available,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        SizedBox(
                          width: widths[i],
                          child: RetroDesktopPixelPaint(
                            painter: _CellPainter(
                              c.platinumLight,
                              c.dark ? c.shade : c.bevelDarker,
                              false,
                              null,
                              t.shapes.small,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                              ),
                              child: SizedBox(
                                height: MediaQuery.textScalerOf(context)
                                    .scale(21),
                                child: Text(
                                  i < heads.length ? heads[i] : '',
                                  style: headStyle,
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  for (var w = 0; w < weeks; w++)
                    // This week: a one-pixel line in the highlight round its row, as the legend's swatch shows,
                    // drawn on whole pixels like every other rule.
                    RetroDesktopPixelPaint(
                      foreground: true,
                      painter: _WeekFrame(w == todayWeek ? c.highlight : null),
                      child: Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            SizedBox(width: widths[i], child: cell(w, i)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// What a page's small marks mean, under a month or a chart. `(mark, words)`, any small widget as the mark.
///
/// ```dart
/// RetroDesktopLegend(const [(RetroDesktopLegendMark.solid, 'open'), (RetroDesktopLegendMark.outline, 'done')])
/// ```
class RetroDesktopLegend extends StatelessWidget {
  /// Creates a [RetroDesktopLegend].
  const RetroDesktopLegend(this.items, {super.key});

  /// The items displayed in their supplied order.
  final List<(RetroDesktopLegendMark, String)> items;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // On its column's edge, as the chart it keys stands.
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          for (final (mark, words) in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                switch (mark) {
                  RetroDesktopLegendMark.solid => retroDesktopOwnSize(
                    width: 7,
                    height: 7,
                    child: RetroDesktopPixelPaint(
                      painter: _PipsPainter(c.text, c.textSecondary, 1, 0),
                    ),
                  ),
                  RetroDesktopLegendMark.outline => retroDesktopOwnSize(
                    width: 7,
                    height: 7,
                    child: RetroDesktopPixelPaint(
                      painter: _PipsPainter(c.text, c.textSecondary, 0, 1),
                    ),
                  ),
                  RetroDesktopLegendMark.tint => retroDesktopOwnSize(
                    width: 12,
                    height: 9,
                    // This week's mark in the month: an outline in the highlight, no tint.
                    child: DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: t.shapes.small.copyWith(
                          side: BorderSide(
                            color: c.highlight,
                            width: t.strokes.hairline,
                          ),
                        ),
                      ),
                    ),
                  ),
                  RetroDesktopLegendMark.send => Icon(
                    RetroDesktopGlyphs.send,
                    size: 13,
                    color: c.textSecondary,
                  ),
                },
                const SizedBox(width: 6),
                Flexible(child: Text(words, style: t.type.caption)),
              ],
            ),
        ],
      ),
    );
  }
}

/// The small keys of a `RetroDesktopLegend`.
enum RetroDesktopLegendMark {
  /// A solid-filled chart mark.
  solid,

  /// An outlined chart mark.
  outline,

  /// The mark of a span the month picks out (this week): a box outlined in the highlight, as the month outlines it.
  tint,

  /// The outgoing value represented by this mark.
  send,
}

/// The sky of an hour, in the words a forecast gives. Each draws its own tone and sprites in a `RetroDesktopPixelSky`.
enum RetroDesktopSkyCondition {
  /// Rain weather or its drawing color.
  rain,

  /// Light drizzle weather or its drawing color.
  drizzle,

  /// Cloudy daylight weather or its drawing color.
  cloud,

  /// Partly cloudy daylight weather or its drawing color.
  partSun,

  /// Clear daylight weather or its drawing color.
  sun,

  /// Sunset weather or its drawing color.
  sunset,

  /// Clear night weather or its drawing color.
  clearNight,

  /// Cloudy night weather or its drawing color.
  cloudNight,
}

/// One column of a `RetroDesktopHourStrip`.
class RetroDesktopHour {
  /// Creates a [RetroDesktopHour].
  const RetroDesktopHour({
    required this.label,
    required this.icon,
    required this.value,
    required this.reading,
    this.kind = RetroDesktopSkyCondition.cloud,
    this.share = 0,
    this.shareLabel,
  });

  /// The visible or accessible name of this part.
  final String label;

  /// The glyph shown with the content.
  final IconData icon;

  /// The number the stepped line rides.
  final double value;

  /// That number in words: '8°'.
  final String reading;

  /// The visual category used to draw this item.
  final RetroDesktopSkyCondition kind;

  /// The bar under it, 0 to 1.
  final double share;

  /// The label describing the displayed proportion.
  final String? shareLabel;
}

const _heavy = [
  '..........#########...........',
  '.......###############........',
  '...#######################....',
  '..###########################.',
  '.#############################',
  '##############################',
  '##############################',
  '++++#####++++++####+++++####++',
  '.++++++++++++++++++++++++++++.',
  '...++++++.....+++++++...+++...',
];
const _light = [
  '......######......',
  '...############...',
  '.################.',
  '##################',
  '+++++######+++++++',
  '..++++++++++++....',
];
const _small = [
  '...#####...',
  '.#########.',
  '###########',
  '+++++++++++',
  '.+++++++++.',
];
const _sunShape = [
  '...#####...',
  '..#######..',
  '.#########.',
  '###########',
  '###########',
  '###########',
  '###########',
  '###########',
  '.#########.',
  '..#######..',
  '...#####...',
];
const _setShape = [
  '...#####...',
  '..#######..',
  '.#########.',
  '###########',
  '###########',
];
const _moonShape = [
  '..####..',
  '.####...',
  '####....',
  '###.....',
  '###.....',
  '####....',
  '.####...',
  '..####..',
];

/// Which of the sky's 13 tones a kind wears, the first hour of a run and those after.
const _tones = <RetroDesktopSkyCondition, List<int>>{
  RetroDesktopSkyCondition.rain: [0, 1],
  RetroDesktopSkyCondition.drizzle: [2],
  RetroDesktopSkyCondition.cloud: [3, 4],
  RetroDesktopSkyCondition.partSun: [5],
  RetroDesktopSkyCondition.sun: [6],
  RetroDesktopSkyCondition.sunset: [7],
  RetroDesktopSkyCondition.clearNight: [8, 9, 10],
  RetroDesktopSkyCondition.cloudNight: [11, 12],
};

class _SkyPainter extends RetroDesktopPixelPainter {
  _SkyPainter(
    this.c,
    List<RetroDesktopSkyCondition> kinds,
    List<double> shares,
    this.p,
  ) : kinds = List.unmodifiable(kinds),
      shares = List.unmodifiable(shares);
  final RetroDesktopColors c;
  final List<RetroDesktopSkyCondition> kinds;
  final List<double> shares;
  final double p;

  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final n = kinds.length;
    if (n == 0 || s.width <= 0 || s.height <= 0) return;
    final cols = s.width / n / p;
    final rows = (s.height / p).floor();
    final limit = (n * cols).round();
    final cells = RetroDesktopCells(px, p, s.width, s.height);
    int cell(double hour) => ((hour + .5) * cols).round();
    final sea = rows - 4;
    final xb = [for (var i = 0; i <= n; i++) (i * cols).round()];

    // Tones: one per column, each stepping along its run.
    final tone = <int>[];
    var run = 0;
    for (var i = 0; i < n; i++) {
      run = i > 0 && kinds[i] == kinds[i - 1] ? run + 1 : 0;
      final list = _tones[kinds[i]]!;
      tone.add(list[math.min(run, list.length - 1)]);
    }
    final sky = c.illustration.sky;
    for (var i = 0; i < n; i++) {
      px.fill(
        Rect.fromLTRB(xb[i] * p, 0, xb[i + 1] * p, s.height),
        sky[tone[i]],
      );
    }
    // The dither at each join: two cells deep, each tone stepping into the other.
    for (var i = 1; i < n; i++) {
      final a = <(int, int)>{}, b = <(int, int)>{};
      for (var r = 0; r <= rows; r++) {
        if (r.isEven) {
          b.add((xb[i] - 1, r));
        } else {
          a.add((xb[i], r));
        }
      }
      cells.fill(b, sky[tone[i]]);
      cells.fill(a, sky[tone[i - 1]]);
    }

    void draw(Iterable<(int, int)> set, Color color) {
      cells.fill(set.where((e) => e.$1 >= 0 && e.$1 < limit), color);
    }

    // Places a shape with its middle column at cell `cx`, its top at `cy`; `pal` maps its letters to colours.
    void sprite(
      List<String> bm,
      int cx,
      int cy,
      Map<String, Color> pal, {
      bool outline = true,
    }) {
      final w = bm.fold<int>(0, (a, r) => math.max(a, r.length));
      final x0 = cx - w ~/ 2;
      final by = <String, Set<(int, int)>>{};
      final filled = <(int, int)>{};
      for (var j = 0; j < bm.length; j++) {
        for (var i = 0; i < bm[j].length; i++) {
          final ch = bm[j][i];
          if (ch == '.') continue;
          (by[ch] ??= {}).add((x0 + i, cy + j));
          filled.add((x0 + i, cy + j));
        }
      }
      if (outline) {
        final ring = <(int, int)>{};
        for (final (x, y) in filled) {
          for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
            if (!filled.contains((x + dx, y + dy))) ring.add((x + dx, y + dy));
          }
        }
        draw(ring, c.illustration.skyLine);
      }
      for (final e in by.entries) {
        draw(e.value, pal[e.key]!);
      }
    }

    /// Each run of a kind, as (first, last).
    List<(int, int)> runs(bool Function(RetroDesktopSkyCondition) test) {
      final out = <(int, int)>[];
      for (var i = 0; i < n; i++) {
        if (!test(kinds[i])) continue;
        var j = i;
        while (j + 1 < n && test(kinds[j + 1])) {
          j++;
        }
        out.add((i, j));
        i = j;
      }
      return out;
    }

    // Stars over a clear night.
    for (final (a, b) in runs(
      (k) => k == RetroDesktopSkyCondition.clearNight,
    )) {
      const seeds = [
        (.0, 3),
        (.3, 9),
        (.75, 5),
        (1.1, 2),
        (1.7, 7),
        (2.15, 3),
        (2.5, 8),
        (2.75, 1),
        (.55, 12),
        (1.3, 11),
        (-.15, 7),
        (3.0, 6),
      ];
      final span = (b - a + 1) / 3;
      draw({
        for (final (h, y) in seeds)
          if (y < sea && h * span <= b - a + .5)
            (((a + h * span + .5) * cols).floor(), y),
      }, c.illustration.star);
      // The moon, a third in.
      sprite(_moonShape, cell(a + (b - a) / 2), 2, {
        '#': c.illustration.moon,
      }, outline: false);
    }
    // The sun breaks out where the part-sun run meets the sun, or over the sun itself.
    final sunnyRuns = runs(
      (k) =>
          k == RetroDesktopSkyCondition.sun ||
          k == RetroDesktopSkyCondition.partSun,
    );
    for (final (a, b) in sunnyRuns) {
      final at = b > a ? a + .85 : a.toDouble();
      final sx = cell(at);
      sprite(_sunShape, sx, 4, {'#': c.illustration.sun});
      draw({
        for (final (dx, dy) in const [
          (-8, 0),
          (-9, 0),
          (8, 0),
          (9, 0),
          (0, -7),
          (0, -8),
          (-6, -5),
          (-7, -6),
          (6, -5),
          (7, -6),
          (-6, 5),
          (6, 5),
        ])
          (sx + dx, 9 + dy),
      }, c.illustration.skyLine);
    }
    // The low sun on the sea, and its road.
    final sunsets = runs((k) => k == RetroDesktopSkyCondition.sunset);
    final setX = [for (final (a, _) in sunsets) cell(a + .3)];
    for (final sx in setX) {
      sprite(_setShape, sx, sea - 5, {'#': c.illustration.sunset});
      draw({
        for (final (dx, dy) in const [
          (0, -3),
          (0, -4),
          (-5, -2),
          (-6, -3),
          (5, -2),
          (6, -3),
          (-8, 1),
          (-9, 1),
          (8, 1),
          (9, 1),
        ])
          (sx + dx, sea - 5 + dy),
      }, c.illustration.skyLine);
    }
    // The sea.
    px.fill(
      Rect.fromLTRB(0, sea * p, limit * p, s.height),
      c.illustration.sea.withValues(alpha: .62),
    );
    final waves = <(int, int)>{};
    for (final (r, step, off) in [
      (sea + 1, 7, 0),
      (sea + 2, 9, 3),
      (sea + 3, 6, 2),
    ]) {
      for (var x = off; x < limit; x += step) {
        waves
          ..add((x, r))
          ..add((x + 1, r));
      }
    }
    draw(waves, const Color(0x47FFFFFF));
    for (final sx in setX) {
      final road = <(int, int)>{};
      const lines = [(5, 0), (4, 1), (2, -1), (1, 1)];
      for (var r = 0; r < lines.length; r++) {
        final (half, off) = lines[r];
        for (var i = -half; i <= half; i++) {
          road.add((sx + off + i, sea + r));
        }
      }
      draw(road, c.illustration.sunset);
    }
    // Rain: a staggered lattice thinning towards the end of the shower.
    for (final (a, b) in runs(
      (k) =>
          k == RetroDesktopSkyCondition.rain ||
          k == RetroDesktopSkyCondition.drizzle,
    )) {
      final hFull = kinds[a] == RetroDesktopSkyCondition.rain
          ? a +
                math.max(
                  0,
                  _lastOf(kinds, a, RetroDesktopSkyCondition.rain) - a,
                ) +
                .1
          : a.toDouble();
      final hEnd = b + .7;
      final rain = <(int, int)>{};
      final x0 = (a * cols).floor();
      final x1 = ((hEnd + .5) * cols).toInt();
      var j = 0;
      for (var y0 = 12; y0 < sea - 3; y0 += 4) {
        var i = 0;
        for (var x = x0; x < x1 + 4; x += 5) {
          final m = (i * 73 + j * 151 + 2 * 17) % 97;
          final dx = x + (j.isOdd ? 2 : 0) + m % 2;
          final dy = y0 + (m ~/ 2) % 2;
          final h = dx / cols - .5;
          final keep = h < hFull
              ? 1.0
              : math.max(0.0, (hEnd - h) / (hEnd - hFull));
          if (m / 97 < keep) {
            rain
              ..add((dx, dy))
              ..add((dx, dy + 1))
              ..add((dx - 1, dy + 2));
          }
          i++;
        }
        j++;
      }
      draw(rain, c.illustration.rain);
    }
    // A shower coming back after dark, drawn for any night hour with a good chance of it.
    for (var i = 0; i < n; i++) {
      if (kinds[i] != RetroDesktopSkyCondition.cloudNight ||
          i >= shares.length) {
        continue;
      }
      if (shares[i] < .25) continue;
      final drops = <(int, int)>{};
      for (final (dh, y) in const [
        (-.25, 13),
        (.0, 17),
        (.2, 12),
        (.42, 16),
        (-.08, 21),
        (.32, 21),
      ]) {
        if (y + 2 >= sea) continue;
        final x = ((i + dh + .5) * cols).toInt();
        drops
          ..add((x, y))
          ..add((x, y + 1))
          ..add((x - 1, y + 2));
      }
      draw(drops, c.illustration.rain);
    }
    // The clouds last: they stand in front.
    final dull = {'#': c.illustration.cloud, '+': c.illustration.cloudLow};
    final lit = {'#': c.illustration.cloudLit, '+': c.illustration.cloudLitLow};
    final night = {
      '#': c.illustration.cloudNight,
      '+': c.illustration.cloudNightLow,
    };
    for (final (a, b) in runs(
      (k) =>
          k == RetroDesktopSkyCondition.rain ||
          k == RetroDesktopSkyCondition.drizzle,
    )) {
      var at = a + .1, top = 2;
      while (at <= b + .1) {
        sprite(_heavy, cell(at), top, dull);
        at += 1.8;
        top = top == 2 ? 1 : 2;
      }
    }
    for (final (a, b) in runs((k) => k == RetroDesktopSkyCondition.cloud)) {
      var at = a + .2, top = 5;
      while (at <= b + .4) {
        sprite(_light, cell(at), top, lit);
        at += 1.1;
        top = top == 5 ? 2 : 5;
      }
    }
    for (final (a, _) in runs((k) => k == RetroDesktopSkyCondition.partSun)) {
      sprite(_small, cell(a.toDouble()), 10, lit);
    }
    for (final (a, b) in runs(
      (k) => k == RetroDesktopSkyCondition.cloudNight,
    )) {
      sprite(_light, cell(a + .15), 2, night);
      if (b > a) sprite(_heavy, cell(a + 1.25), 3, night);
    }
  }

  static int _lastOf(
    List<RetroDesktopSkyCondition> kinds,
    int from,
    RetroDesktopSkyCondition k,
  ) {
    var j = from;
    while (j + 1 < kinds.length && kinds[j + 1] == k) {
      j++;
    }
    return j;
  }

  @override
  bool shouldRepaint(_SkyPainter o) =>
      o.c != c ||
      o.p != p ||
      !_same(o.kinds, kinds) ||
      !_same(o.shares, shares);
}

bool _same(List<Object?> a, List<Object?> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

/// A time-lapse in big square pixels: a column of flat tone per hour, dithered at the joins, with rain, cloud, the sun, the
/// moon and stars placed by rule from what each hour is. It paints to the size it's given. [art] accepts an optional app drawing over the plot.
/// Use a `RetroDesktopHourStrip`, which brings the numbers.
///
/// ```dart
/// RetroDesktopPixelSky(kinds: const [RetroDesktopSkyCondition.rain, RetroDesktopSkyCondition.cloud, RetroDesktopSkyCondition.sun], height: 72)
/// ```
class RetroDesktopPixelSky extends StatelessWidget {
  /// Creates a [RetroDesktopPixelSky].
  const RetroDesktopPixelSky({
    super.key,
    required this.kinds,
    this.shares = const [],
    this.height,
    this.art,
  });

  /// The weather categories in chronological order.
  final List<RetroDesktopSkyCondition> kinds;

  /// The proportions plotted in their supplied order.
  final List<double> shares;

  /// The height in logical pixels.
  final double? height;

  /// Optional caller-supplied illustration or decoration.
  final Widget? art;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    // Time runs the reading way: in right to left the first hour stands at the
    // right, as the hour strip's numbers under it do.
    return SizedBox(
      height: height ?? (t.desk ? 168 : 72),
      child: ClipRect(
        child: Transform.flip(
          flipX: Directionality.of(context) == TextDirection.rtl,
          child: Stack(
            fit: StackFit.expand,
            children: [
              RetroDesktopPixelPaint(
                painter: _SkyPainter(t.colors, kinds, shares, t.desk ? 6 : 2),
              ),
              if (art != null) ExcludeSemantics(child: art!),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepLinePainter extends RetroDesktopPixelPainter {
  _StepLinePainter(this.ink, List<double> values, List<double> widths)
    : values = List.unmodifiable(values),
      widths = List.unmodifiable(widths);
  final Color ink;
  final List<double> values;
  final List<double> widths;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    if (values.isEmpty) return;
    final top = values.reduce(math.max), low = values.reduce(math.min);
    final range = top == low ? 1.0 : top - low;
    double y(double v) => 5 + (top - v) * (s.height - 10) / range;
    final canvas = px.canvas;
    final area = Path()..moveTo(0, s.height);
    var x = 0.0;
    for (var i = 0; i < values.length; i++) {
      area
        ..lineTo(x, y(values[i]))
        ..lineTo(x + widths[i], y(values[i]));
      x += widths[i];
    }
    area
      ..lineTo(x, s.height)
      ..close();
    canvas.drawPath(
      area,
      // One flat wash under the steps: nothing fades (the material law).
      Paint()..color = ink.withValues(alpha: .1),
    );
    x = 0;
    for (var i = 0; i < values.length; i++) {
      final at = y(values[i]);
      px.fill(Rect.fromLTRB(x, at - 1, x + widths[i], at + 1), ink);
      if (i + 1 < values.length && values[i + 1] != values[i]) {
        final next = y(values[i + 1]);
        final edge = x + widths[i];
        px.fill(
          Rect.fromLTRB(
            edge - 1,
            math.min(at, next) - 1,
            edge + 1,
            math.max(at, next) + 1,
          ),
          ink,
        );
      }
      x += widths[i];
    }
  }

  @override
  bool shouldRepaint(_StepLinePainter o) =>
      o.ink != ink || !_same(o.values, values) || !_same(o.widths, widths);
}

class _HatchFill extends RetroDesktopPixelPainter {
  const _HatchFill(this.c, {this.now = false});
  final RetroDesktopColors c;
  final bool now;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    if (r.width <= 0 || r.height <= 0) return;
    if (now) {
      px.diagonal(r, 6, 3, c.highlight, between: c.highlightDark);
    } else {
      px.diagonal(r, 3, 1, c.hatch);
    }
    final line = now ? c.outline : c.text;
    final w = px.hairX, h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.top + h, line);
    px.fillExact(r.left, r.top, r.left + w, r.bottom, line);
    px.fillExact(r.right - w, r.top, r.right, r.bottom, line);
  }

  @override
  bool shouldRepaint(_HatchFill o) => o.c != c || o.now != now;
}

// The now column is the first in reading order: at the right in right-to-left, under its header (it stood at the left,
// under the last column's).
class _NowCell extends RetroDesktopPixelPainter {
  const _NowCell(this.c, this.fromTop, {required this.width, this.rtl = false});
  final RetroDesktopColors c;
  final double fromTop, width;
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final tint = px.snap(
      rtl
          ? Rect.fromLTRB(s.width - width, fromTop, s.width, s.height)
          : Rect.fromLTRB(0, fromTop, width, s.height),
    );
    px.fillExact(
      tint.left,
      tint.top,
      tint.right,
      tint.bottom,
      c.highlightContainer,
    );
  }

  @override
  bool shouldRepaint(_NowCell o) =>
      o.c != c || o.fromTop != fromTop || o.width != width || o.rtl != rtl;
}

class _NowFrame extends RetroDesktopPixelPainter {
  const _NowFrame(
    this.c, {
    required this.width,
    this.top = 0,
    this.rtl = false,
  });
  final RetroDesktopColors c;
  final double width;
  final bool rtl;

  /// Where the frame starts: under the sky, so its side never cuts the art.
  final double top;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(
      rtl
          ? Rect.fromLTRB(s.width - width, top, s.width, s.height)
          : Rect.fromLTRB(0, top, width, s.height),
    );
    final w = px.hairX, h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.top + h, c.divider);
    px.fillExact(r.left, r.bottom - h, r.right, r.bottom, c.divider);
    px.fillExact(r.left, r.top, r.left + w, r.bottom, c.divider);
    px.fillExact(r.right - w, r.top, r.right, r.bottom, c.divider);
  }

  @override
  bool shouldRepaint(_NowFrame o) =>
      o.c != c || o.width != width || o.top != top || o.rtl != rtl;
}

/// A one-pixel line round a month grid's week row; none without a colour (every other week).
class _WeekFrame extends RetroDesktopPixelPainter {
  const _WeekFrame(this.color);
  final Color? color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final color = this.color;
    if (color == null) return;
    final r = px.snap(Offset.zero & s);
    final w = px.hairX, h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.top + h, color);
    px.fillExact(r.left, r.bottom - h, r.right, r.bottom, color);
    px.fillExact(r.left, r.top, r.left + w, r.bottom, color);
    px.fillExact(r.right - w, r.top, r.right, r.bottom, color);
  }

  @override
  bool shouldRepaint(_WeekFrame o) => o.color != color;
}

/// The next hours, one column each: a time-lapse of the sky over them, the time, an icon, a stepped line with the reading, a
/// hatched bar with its figure. The first column is now, framed and tinted. It brings its well, and needs about 22 wide a
/// column: past that, columns are hidden from the end.
///
/// ```dart
/// RetroDesktopHourStrip(hours: const [RetroDesktopHour(label: 'Now', icon: RetroDesktopGlyphs.cloudRain, value: 8, reading: '8°', kind: RetroDesktopSkyCondition.rain, share: .6, shareLabel: '60')])
/// ```
class RetroDesktopHourStrip extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopHourStrip].
  const RetroDesktopHourStrip({
    super.key,
    this.style,
    required this.hours,
    this.art,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The hourly readings in chronological order.
  final List<RetroDesktopHour> hours;

  /// Optional caller-supplied illustration or decoration.
  final Widget? art;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    if (hours.isEmpty) {
      return RetroDesktopWell(style: style, child: const SizedBox(height: 40));
    }
    final skyH = t.desk ? 168.0 : 72.0;
    final lineH = t.desk ? 44.0 : 36.0;
    return RetroDesktopWell(
      style: style,
      child: LayoutBuilder(
        builder: (context, box) {
          final fit = math.max(1, (box.maxWidth / 22).floor());
          final shown = hours.take(fit).toList();
          final n = shown.length;
          double edge(int index) => (index * box.maxWidth / n)
              .roundToDouble()
              .clamp(0.0, box.maxWidth);
          final widths = [for (var i = 0; i < n; i++) edge(i + 1) - edge(i)];
          final nowW = widths.first;
          Widget column(int i, Widget Function(RetroDesktopHour) cell) =>
              SizedBox(width: widths[i], child: cell(shown[i]));
          // The drawn rows (the sky, the stepped line) run in reading order with the rows of words: mirrored in
          // right-to-left, where they ran left to right under right-to-left headers.
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return RetroDesktopPixelPaint(
            painter: _NowCell(c, skyH + 1, width: nowW, rtl: rtl),
            child: RetroDesktopPixelPaint(
              painter: _NowFrame(c, width: nowW, top: skyH, rtl: rtl),
              foreground: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The sky turns itself in right to left.
                  RetroDesktopPixelSky(
                    kinds: [for (final h in shown) h.kind],
                    shares: [for (final h in shown) h.share],
                    height: skyH,
                    art: art,
                  ),
                  SizedBox(height: 1, child: ColoredBox(color: c.outline)),
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        column(
                          i,
                          (h) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  h.label,
                                  style: t.type.pixel(
                                    t.desk ? 18 : (i == 0 ? 14 : 16),
                                    16,
                                    color: c.textSecondary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                ),
                                const SizedBox(height: 6),
                                Icon(
                                  h.icon,
                                  size: t.desk ? 22 : 18,
                                  color: c.text,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(
                    height: lineH,
                    child: Transform.flip(
                      flipX: rtl,
                      child: RetroDesktopPixelPaint(
                        painter: _StepLinePainter(c.text, [
                          for (final h in shown) h.value,
                        ], widths),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        column(
                          i,
                          (h) => Padding(
                            padding: const EdgeInsets.fromLTRB(0, 4, 0, 6),
                            child: Text(
                              h.reading,
                              textAlign: TextAlign.center,
                              style: t.desk
                                  ? t.type.pixel(24, 22)
                                  : t.type.pixel(18, 16),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                    ],
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < n; i++)
                        column(
                          i,
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _ShareBar(share: h.share, now: i == 0),
                                const SizedBox(height: 3),
                                Text(
                                  h.shareLabel ??
                                      '${(h.share * 100).round()}${t.desk ? '%' : ''}',
                                  style: t.type.mono(
                                    t.desk ? 12 : 11,
                                    16,
                                    color: c.textSecondary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.clip,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ShareBar extends StatelessWidget {
  const _ShareBar({required this.share, this.now = false});
  final double share;
  final bool now;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final height = t.desk ? 32.0 : 24.0;
    final filled = (height - 1) * share.clamp(0, 1);
    return retroDesktopOwnSize(
      width: t.desk ? 22 : 10,
      height: height,
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (filled >= 1)
            SizedBox(
              height: filled,
              width: double.infinity,
              child: RetroDesktopPixelPaint(painter: _HatchFill(c)),
            ),
          SizedBox(
            height: 1,
            width: double.infinity,
            child: ColoredBox(color: c.text),
          ),
        ],
      ),
    );
  }
}

/// A day of a `RetroDesktopRangeShape`.
class RetroDesktopDayRange {
  /// Creates a [RetroDesktopDayRange].
  const RetroDesktopDayRange({
    required this.weekday,
    required this.date,
    required this.icon,
    required this.low,
    required this.high,
    this.share = 0,
    this.shareLabel,
    this.amount,
    this.warn = false,
    this.lowLabel,
    this.highLabel,
  });

  /// The weekday label displayed by this part.
  final String weekday;

  /// The calendar date represented by this item.
  final String date;

  /// The glyph shown with the content.
  final IconData icon;

  /// The low value in the displayed range.
  final double low;

  /// The high value in the displayed range.
  final double high;

  /// How wet it is, 0 to 1: the day's tone.
  final double share;

  /// The label describing the displayed proportion.
  final String? shareLabel;

  /// The amount represented by the bar or reading.
  final String? amount;

  /// The label for the low value.
  final String? lowLabel;

  /// The label for the high value.
  final String? highLabel;

  /// The date goes inverted.
  final bool warn;
}

class _RangePainter extends RetroDesktopPixelPainter {
  _RangePainter(
    this.c,
    List<RetroDesktopDayRange> days,
    this.n,
    this.p,
    this.m,
    this.top,
    this.bottom,
  ) : days = List.unmodifiable(days);
  final RetroDesktopColors c;
  final List<RetroDesktopDayRange> days;
  final int n, m;
  final double p, top, bottom;
  static const headRoom = 8, footRoom = 8;
  int y(double t) => headRoom + ((top - t) * m).round();
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final w = n * days.length;
    int tone(double share) {
      final v = share * 100;
      return v <= 10 ? 0 : (v <= 30 ? 1 : (v <= 70 ? 2 : (v <= 90 ? 3 : 4)));
    }

    // Each day its own block, its own outline, one cell of ground between two days: bars side by side, not one
    // shape that swells and narrows.
    final fills = <(int, int), int>{};
    for (var i = 0; i < days.length; i++) {
      final d = days[i];
      for (var x = i * n + 2; x < math.min(w - 1, (i + 1) * n - 1); x++) {
        for (var yy = y(d.high); yy < y(d.low); yy++) {
          fills[(x, yy)] = tone(d.share);
        }
      }
    }
    final ring = <(int, int)>{};
    for (final (x, yy) in fills.keys) {
      for (final (dx, dy) in const [(1, 0), (-1, 0), (0, 1), (0, -1)]) {
        if (!fills.containsKey((x + dx, yy + dy))) ring.add((x + dx, yy + dy));
      }
    }
    final last = fills;
    final cells = RetroDesktopCells(px, p, s.width, s.height);
    if (bottom < 0 && top > 0) {
      cells.fill({
        for (var x = 1; x < w - 1; x++)
          if (x % 5 < 3) (x, y(0)),
      }, c.tones[2]);
    }
    cells.fill(ring, c.pixelOutline);
    for (var k = 0; k < 5; k++) {
      cells.fill({
        for (final e in last.entries)
          if (e.value == k) e.key,
      }, c.tones[k]);
    }
  }

  @override
  bool shouldRepaint(_RangePainter o) =>
      o.c != c ||
      o.n != n ||
      o.p != p ||
      o.m != m ||
      o.top != top ||
      o.bottom != bottom ||
      !_same(o.days, days);
}

/// A run of days in pixels: each day a block of flat tone from its low to its high, its own ink line round it, one pixel of
/// ground between two days, with the readings over and under each day, the first day framed as today. The tone is how wet it is, so a key says
/// dry to wet. Its cells are whole pixels. It brings its well, and its days share the well's width.
///
/// ```dart
/// RetroDesktopRangeShape(days: const [RetroDesktopDayRange(weekday: 'Mon', date: '16', icon: RetroDesktopGlyphs.cloudRain, low: 7, high: 12, share: .95, warn: true)], keyLabel: 'Rain chance, rain mm', dry: 'dry', wet: 'wet')
/// ```
class RetroDesktopRangeShape extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopRangeShape].
  const RetroDesktopRangeShape({
    super.key,
    this.style,
    required this.days,
    this.unit = '°',
    this.keyLabel,
    this.dry,
    this.wet,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The data for the days displayed in the calendar.
  final List<RetroDesktopDayRange> days;

  /// The unit shown beside the value.
  final String unit;

  /// The label describing the visual key.
  final String? keyLabel;

  /// Dry weather.
  final String? dry;

  /// Wet weather.
  final String? wet;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    if (days.isEmpty) {
      return RetroDesktopWell(style: style, child: const SizedBox(height: 40));
    }
    final p = t.desk ? 3.0 : 2.0;
    var top = days.first.high, bottom = days.first.low;
    for (final d in days) {
      top = math.max(top, d.high);
      bottom = math.min(bottom, d.low);
    }
    final range = math.max(1.0, top - bottom);
    final m = math.max(1, (52 / range).round());
    String label(double v) {
      final round = v == v.roundToDouble() ? v.round().toString() : '$v';
      return '${round.replaceFirst('-', '−')}$unit';
    }

    return RetroDesktopWell(
      style: style,
      child: LayoutBuilder(
        builder: (context, box) {
          // The days share the whole width, as the hours above them do
          // (capped, four days floated in the middle of a wide well).
          final fit = math.max(1, (box.maxWidth / (days.length * p)).floor());
          final shown = days;
          final columnW = fit * p;
          final width = columnW * shown.length;
          final rows =
              _RangePainter.headRoom +
              ((top - bottom) * m).round() +
              _RangePainter.footRoom;
          final shape = _RangePainter(c, shown, fit, p, m, top, bottom);
          double yAt(double v) => shape.y(v) * p;
          final hiStyle = t.desk ? t.type.pixel(22, 18) : t.type.pixel(16, 14);
          final loStyle = t.desk
              ? t.type.pixel(18, 16, color: c.textSecondary)
              : t.type.pixel(16, 14, color: c.textSecondary);
          final figure = t.type.mono(
            t.desk ? 12 : 11,
            t.desk ? 16 : 14,
            weight: FontWeight.w600,
            color: c.textSecondary,
          );
          // The readings over the highest day and under the lowest keep
          // their own height clear of the heads and the figures at the
          // reader's text size (twice it, the high ran over today's picture
          // and the low under the key), in whole pixels.
          double tall(String text, TextStyle style) {
            final tp = TextPainter(
              text: TextSpan(text: text, style: style),
              textDirection: TextDirection.ltr,
              textScaler: MediaQuery.textScalerOf(context),
              maxLines: 1,
            )..layout();
            final h = tp.height;
            tp.dispose();
            return h;
          }

          double clear(double need, int room) =>
              (math.max(0.0, need - room * p) / p).ceil() * p;
          final overTop = clear(
            tall(label(top), hiStyle) + p + 2,
            _RangePainter.headRoom,
          );
          final underBottom = clear(
            tall(label(bottom), loStyle) + p + 2,
            _RangePainter.footRoom,
          );
          Widget perDay(Widget Function(int i, RetroDesktopDayRange d) cell) =>
              Row(
                children: [
                  for (var i = 0; i < shown.length; i++)
                    SizedBox(width: columnW, child: cell(i, shown[i])),
                ],
              );
          // The drawn bars run in reading order with the day heads above them (mirrored in right-to-left).
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return Center(
            heightFactor: 1,
            child: SizedBox(
              width: width,
              child: RetroDesktopPixelPaint(
                painter: _NowCell(c, 0, width: columnW, rtl: rtl),
                child: RetroDesktopPixelPaint(
                  painter: _NowFrame(c, width: columnW, rtl: rtl),
                  foreground: true,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      perDay((i, d) {
                        final words = t.desk
                            ? t.type.pixel(
                                18,
                                17,
                                color: d.warn
                                    ? c.paper
                                    : (i == 0 ? c.text : c.textSecondary),
                              )
                            : t.type.pixel(
                                i == 0 ? 13 : 15,
                                14,
                                color: d.warn
                                    ? c.paper
                                    : (i == 0 ? c.text : c.textSecondary),
                              );
                        final date = Padding(
                          padding: EdgeInsets.fromLTRB(
                            i == 0 ? 0 : 3,
                            1,
                            i == 0 ? 0 : 3,
                            0,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                d.weekday,
                                style: words,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                d.date,
                                style: words,
                                maxLines: 1,
                                softWrap: false,
                                overflow: TextOverflow.clip,
                              ),
                            ],
                          ),
                        );
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 4),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              d.warn
                                  ? DecoratedBox(
                                      decoration: ShapeDecoration(
                                        color: c.text,
                                        shape: t.shapes.full,
                                      ),
                                      child: date,
                                    )
                                  : date,
                              SizedBox(height: t.desk ? 6 : 5),
                              Icon(
                                d.icon,
                                size: t.desk ? 22 : 18,
                                color: c.text,
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: overTop),
                      SizedBox(
                        height: rows * p,
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned.fill(
                              child: Transform.flip(
                                flipX: rtl,
                                child: RetroDesktopPixelPaint(painter: shape),
                              ),
                            ),
                            for (var i = 0; i < shown.length; i++) ...[
                              PositionedDirectional(
                                start: i * columnW,
                                width: columnW,
                                bottom: rows * p - yAt(shown[i].high) + p + 2,
                                child: Text(
                                  shown[i].highLabel ?? label(shown[i].high),
                                  textAlign: TextAlign.center,
                                  style: hiStyle,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                              PositionedDirectional(
                                start: i * columnW,
                                width: columnW,
                                top: yAt(shown[i].low) + p + 2,
                                child: Text(
                                  shown[i].lowLabel ?? label(shown[i].low),
                                  textAlign: TextAlign.center,
                                  style: loStyle,
                                  maxLines: 1,
                                  softWrap: false,
                                ),
                              ),
                            ],
                            if (bottom < 0 && top > 0)
                              PositionedDirectional(
                                end: 4,
                                bottom: rows * p - yAt(0) + 3,
                                child: Text(
                                  '0$unit',
                                  style: t.type.text(
                                    12,
                                    12,
                                    weight: FontWeight.w600,
                                    color: c.textTertiary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      SizedBox(height: underBottom),
                      if (shown.any((d) => d.share > 0 || d.shareLabel != null))
                        perDay(
                          (i, d) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              d.shareLabel ??
                                  '${(d.share * 100).round()}${t.desk ? '%' : ''}',
                              textAlign: TextAlign.center,
                              style: figure,
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                      if (shown.any((d) => d.amount != null))
                        perDay(
                          (i, d) => Padding(
                            padding: const EdgeInsets.fromLTRB(0, 3, 0, 7),
                            child: Text(
                              d.amount ?? '',
                              textAlign: TextAlign.center,
                              style: figure.copyWith(color: c.text),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.clip,
                            ),
                          ),
                        ),
                      // The key under the figure rows names them from the chart's start, the tones' legend at its
                      // end (begun one column in, its words stood inside a day's column as if that day's). Under
                      // them on the well's own paper, today's column ends above it (between the chart and the
                      // figures, its paper broke today's tint in two).
                      if (keyLabel != null || dry != null)
                        ColoredBox(
                          color: c.paper,
                          child: Padding(
                            padding: const EdgeInsetsDirectional.fromSTEB(
                              6,
                              2,
                              6,
                              6,
                            ),
                            child: RetroDesktopFitRow(
                              fill: 0,
                              gap: 8,
                              fillShare: .3,
                              children: [
                                Text(
                                  keyLabel ?? '',
                                  style: t.type.caption.copyWith(
                                    color: c.textTertiary,
                                  ),
                                  maxLines: 1,
                                  softWrap: false,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (dry != null)
                                  Wrap(
                                    spacing: 5,
                                    runSpacing: 3,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        dry!,
                                        style: t.type.caption.copyWith(
                                          color: c.textTertiary,
                                        ),
                                      ),
                                      retroDesktopOwnSize(
                                        width: 47,
                                        height: 11,
                                        child: RetroDesktopPixelPaint(
                                          painter: _TonesKey(
                                            c,
                                            rtl:
                                                Directionality.of(context) ==
                                                TextDirection.rtl,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        wet ?? '',
                                        style: t.type.caption.copyWith(
                                          color: c.textTertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// The tones from dry to wet, in reading order: in right to left the dry end
// stands at the right, beside its word (the words swapped sides and the tones
// did not, so the pale end read "wet").
class _TonesKey extends RetroDesktopPixelPainter {
  const _TonesKey(this.c, {this.rtl = false});
  final RetroDesktopColors c;
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    px.fill(Offset.zero & s, c.pixelOutline);
    for (var i = 0; i < 5; i++) {
      px.fill(Rect.fromLTWH(1 + (rtl ? 4 - i : i) * 9.0, 1, 9, 9), c.tones[i]);
    }
  }

  @override
  bool shouldRepaint(_TonesKey o) => o.c != c || o.rtl != rtl;
}

class _RulePainter extends RetroDesktopPixelPainter {
  _RulePainter(this.c, List<double> fractions, {this.rtl = false})
    : fractions = List.unmodifiable(fractions);
  final RetroDesktopColors c;
  final List<double> fractions;

  /// The axis line stands at the reading start, beside the figures (at the right in right-to-left).
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    for (final f in fractions) {
      px.ruleAcross(0, s.width, s.height * (1 - f), c.divider);
    }
    final w = px.hairX, h = px.hair;
    final r = px.snap(Offset.zero & s);
    if (rtl) {
      px.fillExact(r.right - w, r.top, r.right, r.bottom, c.text);
    } else {
      px.fillExact(r.left, r.top, r.left + w, r.bottom, c.text);
    }
    px.fillExact(r.left, r.bottom - h, r.right, r.bottom, c.text);
  }

  @override
  bool shouldRepaint(_RulePainter o) =>
      o.c != c || o.rtl != rtl || !_same(o.fractions, fractions);
}

// The words of a note over a bar.
TextStyle _noteStyle(RetroDesktopThemeData t) =>
    t.type.mono(11, 12, weight: FontWeight.w600);

/// A note on a `RetroDesktopHatchBars`: words over one bar.
class RetroDesktopBarNote {
  /// Creates a [RetroDesktopBarNote].
  const RetroDesktopBarNote(this.index, this.words);

  /// The index of the active data position.
  final int index;

  /// The labels describing the plotted values.
  final String words;
}

/// Hatched bars over an axis, one for each number. The first is now, in the highlight; a value of 0 is a thin line; a [span] of
/// bars can carry words (dry from here to here), a [divider] marks a turn in the run. It brings its well.
///
/// ```dart
/// RetroDesktopHatchBars(values: const [.8, 1.4, 0, 0], max: 1.5, axis: const ['1.5', '1.0', '0.5', '0'], labels: const ['09', '', '', '12'], notes: const [RetroDesktopBarNote(1, '1.4 at 10:00')])
/// ```
class RetroDesktopHatchBars extends StatelessWidget
    implements RetroDesktopFlush {
  /// Creates a [RetroDesktopHatchBars].
  const RetroDesktopHatchBars({
    super.key,
    this.style,
    required this.values,
    this.max,
    this.axis = const [],
    this.labels = const [],
    this.notes = const [],
    this.spanFrom,
    this.spanTo,
    this.spanWords,
    this.divider,
    this.nowAt = 0,
  });

  /// The enclosing well's shape, rim, fill and spacing over its component theme.
  final RetroDesktopStyle? style;

  /// The values plotted in their supplied order.
  final List<double> values;

  /// The value at the top; the largest, if left out.
  final double? max;

  /// Top to bottom. Each draws a rule across the bars.
  final List<String> axis;

  /// One a bar, most of them empty.
  final List<String> labels;

  /// The notes displayed with the chart.
  final List<RetroDesktopBarNote> notes;

  /// The beginning of the highlighted interval.
  final int? spanFrom;

  /// The end of the highlighted interval.
  final int? spanTo;

  /// The index of the bar a rule stands before, marking a turn in the run; null for none.
  final int? divider;

  /// The label describing the highlighted interval.
  final String? spanWords;

  /// The position of the current-time marker.
  final int nowAt;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final height = t.desk ? 200.0 : 120.0;
    final scaler = MediaQuery.textScalerOf(context);
    // With no top named, a note on the tallest bar still needs room over it: a line of the reader's size (at twice
    // the text, kept to the plain size's room, it ran across the well's top).
    final noteRoom = scaler.scale(12) + 4;
    final top =
        max ??
        (values.isEmpty ? 1.0 : values.reduce(math.max)) *
            (notes.isEmpty
                ? 1
                : math.max(1.15, (height - 1) / (height - 1 - noteRoom)));
    final scale = top <= 0 ? 1.0 : top;
    final axisStyle = t.type.mono(12, 16, color: c.textTertiary);
    // The axis column and the labels' row are as wide and as tall as their words at the reader's size (kept to 22
    // and 12, twice the text cut "1.5" to "1." and the hours' feet off at the well's edge).
    var axisW = 22.0;
    for (final a in axis) {
      final tp = TextPainter(
        text: TextSpan(text: a, style: axisStyle),
        textDirection: Directionality.of(context),
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      axisW = math.max(axisW, tp.width.ceilToDouble());
      tp.dispose();
    }
    // Grown with the reader's text only: a long value at the plain size keeps the plain column.
    axisW = math.min(axisW, math.max(22.0, scaler.scale(22)));
    final labelsH = math.max(12.0, scaler.scale(16) - 4);
    // A note stands over its bar: with a named top close over the bar, the
    // well grows at its top by what the note's line reaches over the plot (at
    // twice the text, "1.4 at 10:00" was cut by the well's frame).
    var over = 0.0;
    for (final note in notes) {
      if (note.index >= values.length) continue;
      final tp = TextPainter(
        text: TextSpan(text: note.words, style: _noteStyle(t)),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      final reach =
          (values[note.index] / scale).clamp(0, 1) * (height - 1) +
          4 +
          tp.height -
          height;
      tp.dispose();
      over = math.max(over, (reach - 8).ceilToDouble());
    }
    return RetroDesktopWell(
      style: style,
      child: Padding(
        padding: EdgeInsets.fromLTRB(8, 12 + over, 10, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (axis.isNotEmpty) ...[
              SizedBox(
                width: axisW,
                height: height + scaler.scale(12),
                child: Transform.translate(
                  offset: Offset(0, -scaler.scale(6)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (final a in axis)
                        Text(a, style: axisStyle, maxLines: 1, softWrap: false),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: LayoutBuilder(
                builder: (context, box) {
                  final n = values.isEmpty ? 1 : values.length;
                  const gap = 2.0;
                  final barRoom = box.maxWidth - 1;
                  final pitch = (barRoom + gap) / n;
                  double barX(int i) => 1 + (i * pitch).roundToDouble();
                  double barW(int i) =>
                      ((i + 1) * pitch - gap).roundToDouble() -
                      (i * pitch).roundToDouble();
                  final marks = [
                    if (axis.length > 1)
                      for (var i = 0; i < axis.length - 1; i++)
                        1 - i / (axis.length - 1),
                  ];
                  final noteStyle = _noteStyle(t);
                  final rtl = Directionality.of(context) == TextDirection.rtl;
                  double place(double x, double w) =>
                      rtl ? box.maxWidth - x - w : x;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: height,
                        child: RetroDesktopPixelPaint(
                          painter: _RulePainter(c, marks, rtl: rtl),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              for (var i = 0; i < values.length; i++)
                                Positioned(
                                  left: place(barX(i), barW(i)),
                                  width: barW(i),
                                  bottom: 1,
                                  height: math.max(
                                    1,
                                    (values[i] / scale).clamp(0, 1) *
                                        (height - 1),
                                  ),
                                  child: values[i] <= 0
                                      ? ColoredBox(color: c.textTertiary)
                                      : RetroDesktopPixelPaint(
                                          painter: _HatchFill(
                                            c,
                                            now: i == nowAt,
                                          ),
                                        ),
                                ),
                              if (divider != null && divider! < n)
                                Positioned(
                                  left: place(barX(divider!), 1),
                                  width: 1,
                                  top: -4,
                                  bottom: 0,
                                  child: RetroDesktopPixelPaint(
                                    painter: _DashDown(c.textTertiary),
                                  ),
                                ),
                              if (spanFrom != null &&
                                  spanTo != null &&
                                  spanTo! < n &&
                                  spanFrom! <= spanTo!)
                                Positioned(
                                  left: place(
                                    barX(spanFrom!),
                                    barX(spanTo!) +
                                        barW(spanTo!) -
                                        barX(spanFrom!),
                                  ),
                                  width:
                                      barX(spanTo!) +
                                      barW(spanTo!) -
                                      barX(spanFrom!),
                                  bottom: 10,
                                  height: 22,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: c.paper,
                                      border: Border(
                                        left: BorderSide(color: c.bevelDark),
                                        right: BorderSide(color: c.bevelDark),
                                        bottom: BorderSide(color: c.bevelDark),
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        spanWords ?? '',
                                        style: t.type.text(
                                          12,
                                          14,
                                          weight: FontWeight.w600,
                                          color: c.textSecondary,
                                        ),
                                        maxLines: 1,
                                        softWrap: false,
                                        overflow: TextOverflow.clip,
                                      ),
                                    ),
                                  ),
                                ),
                              // A note starts at its bar's reading start and runs on in reading order (in
                              // right-to-left it ran rightward off the plot into the figures: "1.4.5").
                              for (final note in notes)
                                if (note.index < n)
                                  PositionedDirectional(
                                    start: barX(note.index),
                                    bottom:
                                        (values[note.index] / scale).clamp(
                                              0,
                                              1,
                                            ) *
                                            (height - 1) +
                                        4,
                                    child: Text(
                                      note.words,
                                      style: noteStyle,
                                      maxLines: 1,
                                      softWrap: false,
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                      if (labels.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: labelsH,
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                for (var i = 0; i < labels.length && i < n; i++)
                                  if (labels[i].isNotEmpty)
                                    Positioned(
                                      left: place(barX(i), 0),
                                      child: Text(
                                        labels[i],
                                        style: i == divider
                                            ? axisStyle.copyWith(
                                                color: c.text,
                                                fontWeight: FontWeight.w700,
                                              )
                                            : axisStyle,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashDown extends RetroDesktopPixelPainter {
  const _DashDown(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    for (var y = 0.0; y < s.height; y += 4) {
      px.fill(Rect.fromLTWH(0, y, 1, 2), color);
    }
  }

  @override
  bool shouldRepaint(_DashDown o) => o.color != color;
}

class _DashAcross extends RetroDesktopPixelPainter {
  const _DashAcross(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    for (var x = 0.0; x < s.width; x += 4) {
      px.fill(Rect.fromLTWH(x, 0, 2, 1), color);
    }
  }

  @override
  bool shouldRepaint(_DashAcross o) => o.color != color;
}

/// A few days' numbers on the machine: each bar hatched, its figure on top, the last one now, and a dashed line at a limit.
///
/// ```dart
/// RetroDesktopDayBars(values: const [41, 52, 47], labels: const ['Thu\n5', 'Fri\n6', 'Sat\n7'], limit: 50, max: 62)
/// ```
class RetroDesktopDayBars extends StatelessWidget {
  /// Creates a [RetroDesktopDayBars].
  const RetroDesktopDayBars({
    super.key,
    required this.values,
    required this.labels,
    this.limit,
    this.max,
  });

  /// The values plotted in their supplied order.
  final List<double> values;

  /// Labels corresponding to the supplied data positions.
  final List<String> labels;

  /// The boundary used to scale the plotted values.
  final double? limit;

  /// The maximum value used to scale the plot.
  final double? max;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    // A bar's figure stands on its top in a line of the reader's size, and the chart grows by what that line gains
    // (at twice the text the figures, kept to 16, stood half behind the bars' tops).
    final figureH = MediaQuery.textScalerOf(context).scale(16).ceilToDouble();
    final head = 18.0 + figureH - 16;
    final height = (t.desk ? 158.0 : 104.0) + head - 18;
    const gap = 6.0;
    final top = max ?? (values.isEmpty ? 1.0 : values.reduce(math.max));
    final scale = top <= 0 ? 1.0 : top;
    final room = height - head - 1;
    String show(double v) =>
        v == v.roundToDouble() ? v.round().toString() : '$v';
    final figure = t.type.mono(
      12,
      16,
      weight: FontWeight.w600,
      color: c.textSecondary,
    );
    return RetroDesktopColumn(
      children: [
        SizedBox(
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                height: 1,
                child: ColoredBox(color: c.text),
              ),
              if (limit != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 1 + (limit! / scale).clamp(0, 1) * room,
                  height: 1,
                  child: RetroDesktopPixelPaint(
                    painter: _DashAcross(c.textTertiary),
                  ),
                ),
              if (limit != null)
                PositionedDirectional(
                  end: 0,
                  bottom: 2 + (limit! / scale).clamp(0, 1) * room,
                  child: ColoredBox(
                    color: c.platinum,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(2, 0, 3, 0),
                      child: Text(
                        show(limit!),
                        style: t.type.text(
                          11,
                          12,
                          weight: FontWeight.w600,
                          color: c.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ),
              Positioned.fill(
                bottom: 1,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < values.length; i++) ...[
                      if (i > 0) const SizedBox(width: gap),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            ColoredBox(
                              color: c.platinum,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2,
                                ),
                                child: SizedBox(
                                  height: figureH,
                                  child: Text(
                                    show(values[i]),
                                    style: i == values.length - 1
                                        ? figure.copyWith(color: c.text)
                                        : figure,
                                    maxLines: 1,
                                    softWrap: false,
                                    overflow: TextOverflow.clip,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 2),
                            SizedBox(
                              height: math.max(
                                1,
                                (values[i] / scale).clamp(0, 1) * room,
                              ),
                              width: double.infinity,
                              child: RetroDesktopPixelPaint(
                                painter: _HatchFill(
                                  c,
                                  now: i == values.length - 1,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: t.type.mono(
                      11,
                      13,
                      weight: i == labels.length - 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: i == labels.length - 1 ? c.text : c.textTertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ScalePainter extends RetroDesktopPixelPainter {
  const _ScalePainter(
    this.c,
    this.bands,
    this.knob,
    this.shape,
    this.track, {
    this.rtl = false,
  });
  final RetroDesktopColors c;
  // The knob's outline, and the track's (the family's capsule).
  final OutlinedBorder shape, track;
  final int bands;
  final double knob;
  // Right to left the first band stands at the right, under its name, and the
  // knob counts from there; the sunk edge stays top and left.
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final r = px.snap(Offset.zero & s);
    final w = px.hairX, h = px.hair;
    final outline = track.copyWith(
      side: BorderSide(color: c.control, width: w),
    );
    canvas.save();
    canvas.clipPath(outline.getOuterPath(r));
    canvas.drawRect(r, Paint()..color = c.paper);
    final inner = Rect.fromLTRB(
      r.left + w,
      r.top + h,
      r.right - w,
      r.bottom - h,
    );
    // Each band's hatch closes up on the one before: empty, wide, close, nearly solid.
    final kinds = c.dark
        ? [
            null,
            (6.0, 1.0, c.bevelLight),
            (3.0, 1.0, c.textTertiary),
            (2.0, 1.0, c.text),
          ]
        : [
            null,
            (6.0, 1.0, c.bevelDark),
            (3.0, 1.0, c.bevelDarker),
            (2.0, 1.0, c.text),
          ];
    final n = bands <= 0 ? 1 : bands;
    for (var i = 0; i < n; i++) {
      final k = rtl ? n - 1 - i : i;
      final kind =
          kinds[n == 1 ? 0 : (k * (kinds.length - 1) / (n - 1)).round()];
      final left = px.x(inner.left + i * inner.width / n);
      final right = px.x(inner.left + (i + 1) * inner.width / n);
      final band = Rect.fromLTRB(left, inner.top, right, inner.bottom);
      if (kind != null) px.diagonal(band, kind.$1, kind.$2, kind.$3);
      if (i < n - 1) {
        px.fillExact(right - w, inner.top, right, inner.bottom, c.bevelDark);
      }
    }
    px.fillExact(
      inner.left,
      inner.top,
      inner.right,
      inner.top + h,
      c.bevelDark,
    );
    px.fillExact(
      inner.left,
      inner.top,
      inner.left + w,
      inner.bottom,
      c.bevelDark,
    );
    canvas.restore();
    outline.paint(canvas, r);
    final along = knob.clamp(0.0, 1.0);
    final at = px.x(r.left + (r.width - 2) * (rtl ? 1 - along : along) + 1 - 6);
    final thumb = Size(px.x(at + 12) - at, px.y(s.height + 4) - px.y(-4));
    canvas.save();
    canvas.translate(at, px.y(-4));
    final rr = Offset.zero & thumb;
    canvas.drawPath(
      shape.getOuterPath(rr),
      // Flat: no part fades (the material law).
      Paint()..color = c.highlightFaceMiddle,
    );
    shape.paint(canvas, rr);
    canvas.drawRect(
      Rect.fromLTRB(w, h, thumb.width - w, 2 * h),
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.drawRect(
      Rect.fromLTRB(w, h, 2 * w, thumb.height - h),
      Paint()..color = const Color(0x66FFFFFF),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScalePainter o) =>
      o.c != c ||
      o.bands != bands ||
      o.knob != knob ||
      o.shape != shape ||
      o.track != track ||
      o.rtl != rtl;
}

/// Where a reading stands on a scale of named bands: a track that hatches closer band by band and a lit knob at the value. A
/// band's name and range go under it; [fine] is a footnote.
///
/// ```dart
/// RetroDesktopScaleBar(at: .14, bands: const ['Good\n0–50', 'Fair\n51–100', 'Poor\n101+'], fine: '* for sensitive groups')
/// ```
class RetroDesktopScaleBar extends StatelessWidget {
  /// Creates a [RetroDesktopScaleBar].
  const RetroDesktopScaleBar({
    super.key,
    this.style,
    required this.at,
    required this.bands,
    this.fine,
  });

  /// 0 to 1 along the whole scale.
  final RetroDesktopStyle? style;

  /// The position of the current marker.
  final double at;

  /// The reference ranges displayed behind the values.
  final List<String> bands;

  /// Fine, clear weather.
  final String? fine;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    T? slot<T>(WidgetStateProperty<T?>? Function(RetroDesktopStyle) get) =>
        RetroDesktopStyle.first([style, t.chartTheme], get, const {});
    final c = t.colors.copyWith(
      text: slot((s) => s.foreground),
      control: slot((s) => s.edge),
    );
    final shape = (slot((s) => s.shape) ?? t.shapes.small).copyWith(
      side:
          slot((s) => s.side) ??
          BorderSide(color: c.outline, width: t.strokes.regular),
    );
    final label = t.type.text(
      12,
      15,
      weight: FontWeight.w600,
      color: c.textTertiary,
    );
    return RetroDesktopColumn(
      gap: 4,
      children: [
        SizedBox(
          height: 18,
          child: RetroDesktopPixelPaint(
            painter: _ScalePainter(
              c,
              bands.length,
              at,
              shape,
              t.shapes.full,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        // A band's name and range stand whole under it, a gap before the
        // next: where the reader's text is wider than a band (twice the size
        // on a phone ran "101–150" into "151+"), all the bands' words step
        // down together to fit, so they keep one size and one top.
        LayoutBuilder(
          builder: (context, box) {
            const gap = 6.0;
            final row = Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final b in bands)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.only(end: gap),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.topStart,
                        child: Text(
                          b,
                          style: label,
                          maxLines: 2,
                          softWrap: false,
                        ),
                      ),
                    ),
                  ),
              ],
            );
            if (!box.hasBoundedWidth || bands.isEmpty) return row;
            double widest(TextScaler scaler) {
              var most = 0.0;
              for (final b in bands) {
                final tp = TextPainter(
                  text: TextSpan(text: b, style: label),
                  textDirection: TextDirection.ltr,
                  textScaler: scaler,
                )..layout();
                most = math.max(most, tp.width);
                tp.dispose();
              }
              return most;
            }

            final room = box.maxWidth / bands.length - gap;
            if (widest(MediaQuery.textScalerOf(context)) <= room) return row;
            final plain = widest(TextScaler.noScaling);
            if (plain <= 0) return row;
            return MediaQuery.withClampedTextScaling(
              maxScaleFactor: math.max(.5, room / plain - .01),
              child: row,
            );
          },
        ),
        if (fine != null) Text(fine!, style: t.type.meta),
      ],
    );
  }
}

class _SpanPainter extends RetroDesktopPixelPainter {
  const _SpanPainter(
    this.c,
    this.from,
    this.to,
    this.at,
    this.track, {
    this.rtl = false,
  });
  final RetroDesktopColors c;
  final OutlinedBorder track;
  final double from, to;
  final double? at;
  // Right to left the whole counts from the right, under its labels; the sunk
  // edge stays top and left.
  final bool rtl;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final canvas = px.canvas;
    final r = px.snap(Offset.zero & s);
    final w = px.hairX, h = px.hair;
    final outline = track.copyWith(
      side: BorderSide(color: c.control, width: w),
    );
    canvas.save();
    canvas.clipPath(outline.getOuterPath(r));
    canvas.drawRect(r, Paint()..color = c.platinumDark);
    final inner = Rect.fromLTRB(
      r.left + w,
      r.top + h,
      r.right - w,
      r.bottom - h,
    );
    px.fillExact(
      inner.left,
      inner.top,
      inner.right,
      inner.top + h,
      c.bevelDark,
    );
    px.fillExact(
      inner.left,
      inner.top,
      inner.left + w,
      inner.bottom,
      c.bevelDark,
    );
    double along(double v) {
      final f = v.clamp(0.0, 1.0);
      return rtl ? 1 - f : f;
    }

    final a = px.x(inner.left + inner.width * math.min(along(from), along(to)));
    final b = px.x(inner.left + inner.width * math.max(along(from), along(to)));
    if (b > a) {
      // The stretch is the lit part: paper by day; at night the paper is as
      // dark as the track, so it takes the light plate.
      px.fillExact(
        a,
        inner.top,
        b,
        inner.bottom,
        c.dark ? c.platinumLight : c.paper,
      );
      px.fillExact(a, inner.top, a + w, inner.bottom, c.bevelDark);
      px.fillExact(b - w, inner.top, b, inner.bottom, c.bevelDark);
    }
    canvas.restore();
    outline.paint(canvas, r);
    if (at != null) {
      final x = px.x(inner.left + inner.width * along(at!) - 1);
      final top = px.y(-4), bottom = px.y(s.height + 4);
      final right = x + 3 * w;
      px.fillExact(x, top, right, bottom, c.outline);
      px.fillExact(x + w, top + h, right - w, bottom - h, c.highlight);
    }
  }

  @override
  bool shouldRepaint(_SpanPainter o) =>
      o.c != c ||
      o.from != from ||
      o.to != to ||
      o.at != at ||
      o.track != track ||
      o.rtl != rtl;
}

/// A span in a whole: a lit stretch in a sunk track, and a lit pin at now. Hours of daylight, a booking in a month. The
/// labels go under their places, and one that would hit another stays out.
///
/// ```dart
/// RetroDesktopSpanBar(from: .31, to: .68, at: .39, fromLabel: '07:22', toLabel: '16:21', startLabel: '00', endLabel: '24')
/// ```
class RetroDesktopSpanBar extends StatelessWidget {
  /// Creates a [RetroDesktopSpanBar].
  const RetroDesktopSpanBar({
    super.key,
    required this.from,
    required this.to,
    this.at,
    this.fromLabel,
    this.toLabel,
    this.startLabel,
    this.endLabel,
  });

  /// The start of the displayed interval.
  final double from;

  /// The end of the displayed interval.
  final double to;

  /// The position of the current marker.
  final double? at;

  /// The label for the start of the interval.
  final String? fromLabel;

  /// The label for the end of the interval.
  final String? toLabel;

  /// The label at the start of the range.
  final String? startLabel;

  /// The label shown at the end of the range.
  final String? endLabel;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final c = t.colors;
    final label = t.type.mono(12, 16, color: c.textTertiary);
    double width(String s) {
      final tp = TextPainter(
        text: TextSpan(text: s, style: label),
        textDirection: TextDirection.ltr,
        textScaler: MediaQuery.textScalerOf(context),
        maxLines: 1,
      )..layout();
      final w = tp.width;
      tp.dispose();
      return w;
    }

    return RetroDesktopColumn(
      gap: 4,
      children: [
        SizedBox(
          height: 16,
          child: RetroDesktopPixelPaint(
            painter: _SpanPainter(
              c,
              from,
              to,
              at,
              t.shapes.full,
              rtl: Directionality.of(context) == TextDirection.rtl,
            ),
          ),
        ),
        LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth;
            final kept = <(double, double, String)>[];
            void offer(String? s, double centreAt, {int side = 0}) {
              if (s == null || s.isEmpty) return;
              final lw = width(s);
              final double x = side < 0
                  ? 0.0
                  : side > 0
                  ? w - lw
                  : (centreAt * w - lw / 2).clamp(0.0, math.max(0.0, w - lw));
              for (final (a, b, _) in kept) {
                if (x < b + 4 && x + lw + 4 > a) return;
              }
              kept.add((x, x + lw, s));
            }

            offer(fromLabel, from);
            offer(toLabel, to);
            offer(startLabel, 0, side: -1);
            offer(endLabel, 1, side: 1);
            return SizedBox(
              height: 14,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (final (a, _, s) in kept)
                    PositionedDirectional(
                      start: a,
                      child: Text(
                        s,
                        style: label,
                        maxLines: 1,
                        softWrap: false,
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
