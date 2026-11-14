// A day and a month: the day as a pressed tray with raised tiles, the month in a well, a bank of latching round push buttons, a small note in a well.
import '../component_themes.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../controls.dart';
import '../localizations.dart';
import '../frames.dart';
import '../internal/geometry.dart';
import '../layout.dart';
import '../ornaments.dart';
import '../theme.dart';
import '../internal/cap_label.dart';
import '../internal/cell_bank.dart' show NeumorphicChosenBand;

double? _minutes(String hhmm) {
  final m = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(hhmm.trim());
  if (m == null) return null;
  return int.parse(m[1]!) * 60.0 + int.parse(m[2]!);
}

/// One event of a [NeumorphicDayTray].
class NeumorphicTrayEvent {
  /// Creates a [NeumorphicTrayEvent].
  const NeumorphicTrayEvent({
    required this.start,
    required this.end,
    required this.title,
    this.subtitle,
    this.detail,
    this.mark,
    this.isPast = false,
    this.isCurrent = false,
    this.onPressed,
  });

  /// '09:00'.
  final String start, end;

  /// The primary heading.
  final String title;

  /// A line under the title: for a short event, beside it.
  final String? subtitle, detail;

  /// The kind it belongs to, told by shape.
  final NeumorphicMarkShape? mark;

  /// It's over: quieter words.
  final bool isPast;

  /// It's on now: a wash of the pigment over the time gone, a bar of it at its edge.
  final bool isCurrent;

  /// Called when the item is activated.
  final VoidCallback? onPressed;
}

/// A gap to show as free, in words, between two times.
class NeumorphicTrayFree {
  /// Creates a [NeumorphicTrayFree].
  const NeumorphicTrayFree(
    this.start,
    this.end,
    this.words, {
    this.isLimited = false,
  });

  /// The start time in HH:mm form.
  final String start;

  /// The end time in HH:mm form.
  final String end;

  /// The text identifying the free interval.
  final String words;

  /// Stand at the foot of the gap: for one an hour's line would strike through.
  final bool isLimited;
}

class _RailPainter extends CustomPainter {
  _RailPainter(
    this.c,
    this.flat,
    this.rtl,
    this.ruleTop,
    this.rows,
    this.border,
  );
  final OutlinedBorder border;
  final NeumorphicColors c;
  final bool flat, rtl;
  final double ruleTop;
  final int rows;
  @override
  void paint(Canvas canvas, Size s) {
    final box = Offset.zero & s;
    neumorphicPaintRaised(
      canvas,
      border.getOuterPath(box),
      c,
      light: (const Offset(-2, -2), 5),
      dark: (const Offset(4, 3), 9),
      face: cssLinear(box, rtl ? 270 : 90, [c.faceStart, c.faceEnd]),
      flat: flat,
    );
    if (flat) {
      border.copyWith(side: BorderSide(color: c.quiet)).paint(canvas, box);
    }
    for (var i = 0; i <= rows; i++) {
      final y = ruleTop + i * 22.5;
      if (y > s.height) break;
      canvas.drawRect(
        Rect.fromLTWH(rtl ? 0 : s.width - 5, y, 5, 1),
        neumorphicFillPaint(c.quiet),
      );
    }
  }

  @override
  bool shouldRepaint(_RailPainter o) =>
      o.c != c ||
      o.flat != flat ||
      o.rtl != rtl ||
      o.rows != rows ||
      o.ruleTop != ruleTop ||
      o.border != border;
}

class _NowPainter extends CustomPainter {
  _NowPainter(this.c);
  final NeumorphicColors c;
  @override
  void paint(Canvas canvas, Size s) {
    final y = s.height / 2;
    canvas.drawCircle(Offset(0, y), 9, neumorphicFillPaint(c.ledGlow));
    canvas.drawCircle(Offset(0, y), 6, neumorphicFillPaint(c.pigment));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(6, y - 1, s.width - 6, 2),
        const Radius.circular(1),
      ),
      neumorphicFillPaint(c.pigment),
    );
  }

  @override
  bool shouldRepaint(_NowPainter o) => o.c != c;
}

class _NowWash extends CustomPainter {
  _NowWash(this.c, this.to, this.rtl, this.border);
  final OutlinedBorder border;
  final NeumorphicColors c;
  final double to;
  final bool rtl;
  @override
  void paint(Canvas canvas, Size s) {
    canvas.save();
    canvas.clipPath(border.getOuterPath(Offset.zero & s));
    canvas.drawRect(
      Rect.fromLTWH(0, 0, s.width, s.height * to),
      neumorphicFillPaint(c.wash),
    );
    // The elapsed-time wash and the separate now line already carry this data.
    canvas.restore();
  }

  @override
  bool shouldRepaint(_NowWash o) =>
      o.c != c || o.to != to || o.rtl != rtl || o.border != border;
}

class _Tile extends StatelessWidget {
  const _Tile({required this.e, required this.minutes, this.washTo});
  final NeumorphicTrayEvent e;
  final double minutes;
  final double? washTo;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final titleInk = e.isPast ? c.inkSecondary : c.ink;
    final tiny = minutes <= 15;
    final short = minutes <= 30;
    final titleStyle = (tiny && !desk)
        ? t.textTheme.micro.copyWith(
            fontWeight: FontWeight.w700,
            color: titleInk,
          )
        : t.textTheme.text(14, 18, weight: FontWeight.w700, color: titleInk);
    final detail = t.textTheme.micro
        .copyWith(
          color: e.isCurrent ? c.pigmentInkLit : c.inkSecondary,
          fontWeight: FontWeight.w600,
        )
        .tabular;
    final mark = e.mark == null ? null : NeumorphicShapeMark(e.mark!, size: 8);
    Widget body;
    if (short) {
      final detailText = e.subtitle == null
          ? null
          : Text(
              e.subtitle!,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: detail,
            );
      final titleText = Text(
        e.title,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: titleStyle,
      );
      body = Padding(
        padding: EdgeInsets.symmetric(horizontal: desk ? 14 : 10),
        child: tiny
            ? NeumorphicFitRow(
                fill: (mark == null ? 0 : 1) + (detailText == null ? 0 : 1),
                gap: 8,
                fillShare: .55,
                children: [?mark, ?detailText, titleText],
              )
            : NeumorphicFitRow(
                fill: (mark == null ? 0 : 1) + (detailText == null ? 0 : 1),
                gap: 8,
                fillShare: .45,
                children: [?mark, titleText, ?detailText],
              ),
      );
    } else {
      body = Padding(
        padding: desk
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mark != null) ...[
                  Padding(padding: const EdgeInsets.only(top: 5), child: mark),
                  const SizedBox(width: 7),
                ],
                Expanded(
                  child: Text(
                    e.title,
                    maxLines: minutes >= 60 ? 2 : 1,
                    overflow: TextOverflow.ellipsis,
                    style: titleStyle,
                  ),
                ),
              ],
            ),
            if (e.subtitle != null)
              Text(
                e.subtitle!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: detail,
              ),
            if (e.detail != null && minutes >= 60)
              Text(
                e.detail!,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: detail,
              ),
          ],
        ),
      );
    }
    final tile = NeumorphicSurface(
      cast: NeumorphicSurfaceLevel.part,
      radius: NeumorphicRadii.chip,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (washTo != null)
              CustomPaint(
                painter: _NowWash(
                  c,
                  washTo!,
                  Directionality.of(context) == TextDirection.rtl,
                  NeumorphicTheme.of(context).shapes
                      .corner(NeumorphicRadii.chip),
                ),
              ),
            short ? Center(child: body) : body,
          ],
        ),
      ),
    );
    return e.onPressed == null
        ? tile
        : NeumorphicTap(onPressed: e.onPressed, label: e.title, child: tile);
  }
}

/// How wide a short overlapping tile's words stand.
double _tinyWidth(NeumorphicTrayEvent e, NeumorphicThemeData t) {
  double words(String text, TextStyle style) {
    final p = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final w = p.width;
    p.dispose();
    return w;
  }

  final title = t.desk
      ? t.textTheme.text(14, 18, weight: FontWeight.w700)
      : t.textTheme.micro.copyWith(fontWeight: FontWeight.w700);
  final side = t.desk ? 14.0 : 10.0;
  return 2 * side +
      words(e.title, title) +
      (e.subtitle == null
          ? 0
          : 8 +
                words(
                  e.subtitle!,
                  t.textTheme.micro
                      .copyWith(fontWeight: FontWeight.w600)
                      .tabular,
                )) +
      (e.mark == null ? 0 : 16) +
      1;
}

/// A day as a pressed tray: an hour moulding down its side, events as raised tiles at their real height, an hour at 90. A short event is one line; an
/// overlapping one takes the right half. A line in the pigment is now. Mark events by shape, never by hue: the pigment means now.
///
/// ```dart
/// NeumorphicDayTray(from: 8, to: 18, now: '13:05', events: const [NeumorphicTrayEvent(start: '09:00', end: '10:00', title: 'A thing', detail: '09:00 to 10:00', mark: NeumorphicMarkShape.solid)])
/// ```
class NeumorphicDayTray extends StatelessWidget {
  /// Creates a [NeumorphicDayTray].
  const NeumorphicDayTray({
    super.key,
    this.style,
    this.from = 8,
    this.to = 18,
    this.now,
    this.events = const [],
    this.free = const [],
  });

  /// The first and last hour.
  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The first hour displayed on the time rail.
  final int from;

  /// The final hour displayed on the time rail.
  final int to;

  /// '13:05'; none, if today isn't this day.
  final String? now;

  /// The scheduled events placed on the time rail.
  final List<NeumorphicTrayEvent> events;

  /// The labelled free intervals between events.
  final List<NeumorphicTrayFree> free;
  static const double _hour = 90;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final flat = NeumorphicFlatScope.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final first = math.min(from, to - 1);
    final hours = to - first;
    final height = hours * _hour;
    final railW = desk ? 62.0 : 52.0;
    final gap = desk ? 10.0 : 8.0;
    final tmRight = desk ? 10.0 : 8.0;
    double y(double minutes) => (minutes - first * 60) * _hour / 60;
    final nowM = now == null ? null : _minutes(now!);
    final tm = t.textTheme.micro.copyWith(color: c.inkSecondary).tabular;

    // Lanes: the first of an overlap keeps the whole width; each one that starts within it takes the right half.
    final placed = <(NeumorphicTrayEvent, double, double, bool, bool)>[];
    var lastEnd = -1.0;
    for (final e in events) {
      final a = _minutes(e.start), b = _minutes(e.end);
      if (a == null) continue;
      final end = b == null || b <= a ? a + 15 : b;
      final over = a < lastEnd;
      final tiny = end - a <= 15;
      placed.add((e, a, end, over, tiny));
      lastEnd = math.max(lastEnd, end);
    }

    return NeumorphicSurface(
      style: style,
      themeStyle: NeumorphicTheme.of(context).cardTheme,
      cast: NeumorphicSurfaceLevel.well,
      padding: desk
          ? const EdgeInsetsDirectional.fromSTEB(
              8,
              18,
              18,
              18,
            ).resolve(Directionality.of(context))
          : const EdgeInsetsDirectional.fromSTEB(
              8,
              14,
              12,
              14,
            ).resolve(Directionality.of(context)),
      child: LayoutBuilder(
        builder: (context, box) {
          // At larger type, a fixed number of pixels per minute cannot also
          // contain the full event text. Keep the chronology and show every word.
          if (MediaQuery.textScalerOf(context).scale(14) > 14) {
            return _ReadableDayTray(events: events, free: free, now: now);
          }
          final w = box.maxWidth;
          final eventsX = railW + gap;
          final eventsW = math.max(w - eventsX, 0).toDouble();
          // Where the words of the tile it crosses end, at most.
          var lineOnTop = true;
          if (nowM != null) {
            for (final (e, a, end, _, _) in placed) {
              if (nowM < a || nowM > end) continue;
              final words =
                  10 +
                  (end - a >= 60 ? 36 : 18) +
                  (e.subtitle == null ? 0 : 16) +
                  (e.detail == null ? 0 : 16);
              if (y(nowM) - y(a) < words) lineOnTop = false;
            }
          }
          Widget nowLine() => PositionedDirectional(
            start: railW,
            end: 0,
            top: y(nowM!) - 9,
            height: 18,
            child: rtl
                ? Transform.flip(
                    flipX: true,
                    child: CustomPaint(painter: _NowPainter(c)),
                  )
                : CustomPaint(painter: _NowPainter(c)),
          );
          return SizedBox(
            height: height + 8,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // The hours' strip stands 8 in from the well on its three sides, its corners the well's 14 less those
                // 8, so the two curves share their centres: 6 in at the top and 10 at its corners, it read as a
                // second edge nested in the well's.
                PositionedDirectional(
                  start: 0,
                  width: railW,
                  top: desk ? -10 : -6,
                  bottom: desk ? -10 : -6,
                  child: CustomPaint(
                    painter: _RailPainter(
                      c,
                      flat,
                      rtl,
                      // The first hour's rule, as far down the strip as the strip stands above the hours.
                      desk ? 10 : 6,
                      hours * 4,
                      t.shapes.corner(NeumorphicRadii.well - 8),
                    ),
                  ),
                ),
                for (var h = first; h <= to; h++)
                  if (nowM == null || (nowM - h * 60).abs() > 15)
                    PositionedDirectional(
                      start: 0,
                      width: railW - tmRight,
                      top: y(h * 60.0) - 8,
                      child: Text(
                        NeumorphicLocalizations.of(context)
                            .formatTime(DateTime(2000, 1, 1, h)),
                        maxLines: 1,
                        textAlign: TextAlign.end,
                        style: tm,
                      ),
                    ),
                for (var h = first; h <= to; h++)
                  PositionedDirectional(
                    start: railW,
                    end: 0,
                    top: y(h * 60.0),
                    height: 2,
                    child: const NeumorphicEngraved(),
                  ),
                for (final f in free)
                  if (_minutes(f.start) != null && _minutes(f.end) != null)
                    PositionedDirectional(
                      start: eventsX,
                      end: 0,
                      top: y(_minutes(f.start)!),
                      height: y(_minutes(f.end)!) - y(_minutes(f.start)!),
                      child: Align(
                        alignment: f.isLimited
                            ? Alignment.bottomCenter
                            : Alignment.center,
                        child: Padding(
                          padding: EdgeInsets.only(bottom: f.isLimited ? 6 : 0),
                          child: Text(
                            f.words,
                            maxLines: 1,
                            style: t.textTheme.micro,
                          ),
                        ),
                      ),
                    ),
                // The line runs on the tray's floor, under a raised tile, unless it passes below that tile's words: it
                // never strikes through them.
                if (nowM != null &&
                    y(nowM) >= 0 &&
                    y(nowM) <= height &&
                    !lineOnTop)
                  nowLine(),
                for (final (e, a, end, over, tiny) in placed)
                  PositionedDirectional(
                    start: over && !tiny
                        ? eventsX + eventsW / 2 + gap / 2
                        : (over ? null : eventsX),
                    end: 0,
                    width: over && tiny
                        ? math.min(eventsW, _tinyWidth(e, t))
                        : null,
                    top: y(a) + 1,
                    height: math.max(y(end) - y(a) - 2, 18),
                    child: _Tile(
                      e: e,
                      minutes: end - a,
                      washTo: e.isCurrent && nowM != null
                          ? ((nowM - a) / (end - a)).clamp(0.0, 1.0)
                          : (e.isCurrent ? 1.0 : null),
                    ),
                  ),
                if (nowM != null && y(nowM) >= 0 && y(nowM) <= height) ...[
                  PositionedDirectional(
                    start: 0,
                    width: railW - tmRight,
                    top: y(nowM) - 8,
                    child: Text(
                      now!,
                      maxLines: 1,
                      textAlign: TextAlign.end,
                      style: tm.copyWith(
                        color: c.pigmentInk,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  if (lineOnTop) nowLine(),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReadableDayTray extends StatelessWidget {
  const _ReadableDayTray({required this.events, required this.free, this.now});
  final List<NeumorphicTrayEvent> events;
  final List<NeumorphicTrayFree> free;
  final String? now;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final entries = <(double, Widget)>[];
    for (final event in events) {
      final start = _minutes(event.start);
      if (start == null) continue;
      final words = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${event.start} – ${event.end}',
            style: t.textTheme.micro.tabular,
          ),
          const SizedBox(height: 4),
          if (event.isCurrent) const NeumorphicLed(),
          if (event.mark != null) NeumorphicShapeMark(event.mark!),
          Text(
            event.title,
            style: t.textTheme.body.copyWith(
              fontWeight: FontWeight.w700,
              color: event.isPast ? t.colors.inkSecondary : t.colors.ink,
            ),
          ),
          if (event.subtitle != null)
            Text(event.subtitle!, style: t.textTheme.caption),
          if (event.detail != null)
            Text(event.detail!, style: t.textTheme.caption),
        ],
      );
      final face = NeumorphicSurface(
        cast: NeumorphicSurfaceLevel.part,
        radius: NeumorphicRadii.chip,
        outlined: true,
        padding: const EdgeInsets.all(12),
        child: words,
      );
      entries.add((
        start,
        event.onPressed == null
            ? face
            : NeumorphicTap(
                onPressed: event.onPressed,
                label: [
                  event.start,
                  event.end,
                  event.title,
                  event.subtitle,
                  event.detail,
                ].whereType<String>().join(', '),
                child: face,
              ),
      ));
    }
    for (final gap in free) {
      final start = _minutes(gap.start);
      if (start == null || _minutes(gap.end) == null) continue;
      entries.add((
        start,
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            '${gap.start} – ${gap.end}\n${gap.words}',
            style: t.textTheme.caption,
          ),
        ),
      ));
    }
    entries.sort((a, b) => a.$1.compareTo(b.$1));
    return NeumorphicColumn(
      gap: 12,
      children: [
        if (now != null)
          Text(
            now!,
            style: t.textTheme.value.copyWith(color: t.colors.pigmentInk),
          ),
        for (final entry in entries) entry.$2,
      ],
    );
  }
}

/// A month in a well: today pressed in under the pigment's tint, small ticks under the days that hold something. [dense] for a pilaster.
/// Its weeks start on the locale's first day, as the pickers' do.
///
/// ```dart
/// NeumorphicMonth(year: 2026, month: 11, today: 11, marked: const {2, 3, 4, 9})
/// ```
class NeumorphicMonth extends StatelessWidget {
  /// Creates a [NeumorphicMonth].
  const NeumorphicMonth({
    super.key,
    this.style,
    required this.year,
    required this.month,
    this.today,
    this.marked = const {},
    this.dense = false,
    this.weekdays,
    this.onDay,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The calendar year.
  final int year;

  /// The month number, from 1 through 12.
  final int month;

  /// The day number emphasized as today.
  final int? today;

  /// Day numbers carrying a small activity marker.
  final Set<int> marked;

  /// Whether to use the compact calendar spacing.
  final bool dense;

  /// Optional weekday headings starting with Monday; they stand in the locale's order.
  final List<String>? weekdays;

  /// Reports the selected day number.
  final ValueChanged<int>? onDay;
  // A month's figures grow with the text only so far (1.3), as Material's date picker's do: at twice the text on a
  // phone its figures ran together and to the well's walls.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final height = math.max(
      dense ? 34.0 : 40.0,
      MediaQuery.textScalerOf(context).scale(18) + 6,
    );
    final first = DateTime(year, month);
    // The week starts where the locale's does: fixed on Monday, the month stood a day off the pickers beside it.
    final firstDay = NeumorphicLocalizations.of(context).firstDayOfWeek;
    final lead = (first.weekday - firstDay + 7) % 7;
    final length = DateTime(year, month + 1, 0).day;
    final cells = <(DateTime, bool)>[
      for (var i = lead - 1; i >= 0; i--) (DateTime(year, month, -i), false),
      for (var d = 1; d <= length; d++) (DateTime(year, month, d), true),
    ];
    var next = 1;
    while (cells.length % 7 != 0) {
      cells.add((DateTime(year, month + 1, next++), false));
    }
    final day = t.textTheme.text(14, 18, weight: FontWeight.w600).tabular;
    final muted = t.textTheme
        .text(14, 18, weight: FontWeight.w500, color: c.inkTertiary)
        .tabular;
    final words = NeumorphicLocalizations.of(context);
    Widget cell((DateTime, bool) e) {
      final (date, inMonth) = e;
      final d = date.day;
      final isToday = inMonth && d == today;
      final mark = inMonth && marked.contains(d);
      // The figure on the day's middle; its mark hangs under it, so no number rides high for a mark it lacks.
      final content = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          neumorphicLabel(
            Text(
              words.formatDay(date),
              maxLines: 1,
              style: isToday
                  ? day.copyWith(
                      color: c.pigmentInk,
                      fontWeight: FontWeight.w800,
                    )
                  : (inMonth ? day : muted),
            ),
          ),
          PositionedDirectional(
            bottom: -6,
            start: 0,
            end: 0,
            height: 4,
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: mark
                    ? BoxDecoration(
                        shape: BoxShape.circle,
                        color: isToday ? c.pigmentInk : c.inkTertiary,
                      )
                    : null,
              ),
            ),
          ),
        ],
      );
      final box = SizedBox(
        height: height,
        child: Center(
          // Today is pressed in under the pigment's tint, as a chosen cell is: a slab of the pigment laid on the
          // month was a body of its own (law 5), raised among figures that are not.
          child: isToday
              ? SizedBox.square(
                  dimension: height,
                  child: NeumorphicChosenBand(
                    chosen: true,
                    border: t.shapes.corner(NeumorphicRadii.cap),
                    child: Center(child: content),
                  ),
                )
              : content,
        ),
      );
      return onDay != null && inMonth
          ? NeumorphicTap(
              onPressed: () => onDay!(d),
              label: words.formatFullDate(date),
              shape: t.shapes.corner(NeumorphicRadii.cap),
              focusSize: isToday ? Size.square(height) : null,
              child: box,
            )
          : box;
    }

    // Monday-first names, read from the locale's first day.
    final names = (weekdays ?? words.weekdaysShort).take(7).toList();
    final calendar = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    names[(i + firstDay - 1) % names.length],
                    textAlign: TextAlign.center,
                    style: t.textTheme.micro.copyWith(
                      fontWeight: FontWeight.w700,
                      color: c.inkSecondary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        for (var i = 0; i < cells.length; i += 7) ...[
          if (i > 0) const SizedBox(height: 4),
          Row(
            children: [
              for (var j = i; j < i + 7; j++) Expanded(child: cell(cells[j])),
            ],
          ),
        ],
      ],
    );
    // Seven touch targets need 7 × 48 inside the well. Where the well's own sides would leave a pixel or two short (a
    // 390 phone gives 350), the sides narrow to 4 before the month gives up its grid for a dated list.
    return LayoutBuilder(
      builder: (context, outer) => NeumorphicWell(
        style: style,
        padding: dense
            ? const EdgeInsets.fromLTRB(4, 10, 4, 6)
            : outer.hasBoundedWidth && outer.maxWidth - 16 < 7 * 48
            ? const EdgeInsets.fromLTRB(4, 12, 4, 8)
            : const EdgeInsets.fromLTRB(8, 12, 8, 8),
        child: _monthBody(context, calendar, length, words, t),
      ),
    );
  }

  Widget _monthBody(
    BuildContext context,
    Widget calendar,
    int length,
    NeumorphicLocalizations words,
    NeumorphicThemeData t,
  ) {
    return onDay == null
        ? calendar
        : LayoutBuilder(
            builder: (context, box) {
              if (!box.hasBoundedWidth || box.maxWidth >= 7 * 48) {
                return calendar;
              }
              // Seven touch targets cannot fit here. A dated list keeps the
              // chronology and every day reachable inside the shaped well,
              // rather than hiding columns beyond its painted boundary.
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var d = 1; d <= length; d++)
                    NeumorphicTap(
                      label: words.formatFullDate(DateTime(year, month, d)),
                      onPressed: () => onDay!(d),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        child: Text(
                          words.formatFullDate(DateTime(year, month, d)),
                          style: d == today
                              ? t.textTheme.title
                              : t.textTheme.body,
                        ),
                      ),
                    ),
                ],
              );
            },
          );
  }
}

/// One button of a [NeumorphicPushGroup].
class NeumorphicPush {
  /// Creates a [NeumorphicPush].
  const NeumorphicPush({
    required this.icon,
    required this.label,
    this.note,
    this.selected = false,
    this.onPressed,
  });

  /// The glyph displayed with the content.
  final IconData icon;

  /// The text identifying this item or control.
  final String label;

  /// Supporting text displayed with the primary content.
  final String? note;

  /// Latched in: pressed AND the pigment in its glyph AND an LED AND its note in the pigment.
  final bool selected;

  /// Called when the item is activated.
  final VoidCallback? onPressed;
}

/// A bank of latching round push buttons in a well: modes, a few states you switch between. Pick up to about four a row.
///
/// ```dart
/// NeumorphicPushGroup(items: [NeumorphicPush(icon: NeumorphicGlyphs.sun, label: 'Day', note: 'Ran 06:45'), NeumorphicPush(icon: NeumorphicGlyphs.moon, label: 'Night', note: 'Since 22:30', selected: true)])
/// ```
class NeumorphicPushGroup extends StatelessWidget {
  /// Creates a [NeumorphicPushGroup].
  const NeumorphicPushGroup({super.key, this.style, required this.items});

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The push-button options, in display order.
  final List<NeumorphicPush> items;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final desk = t.desk;
    final size = desk ? 72.0 : 64.0;
    final iconSize = desk ? 26.0 : 24.0;
    if (items.isEmpty) return const SizedBox.shrink();
    Widget push(NeumorphicPush p) {
      return NeumorphicTap(
        onPressed: p.onPressed,
        label: p.label,
        selected: p.selected,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            neumorphicOwnSize(
              width: size,
              height: size,
              alignment: Alignment.center,
              child: Stack(
                clipBehavior: Clip.none,
                fit: StackFit.expand,
                children: [
                  NeumorphicSurface(
                    cast: p.selected
                        ? NeumorphicSurfaceLevel.groove
                        : NeumorphicSurfaceLevel.part,
                    round: true,
                    live: p.selected,
                    child: Center(
                      child: Icon(
                        p.icon,
                        size: iconSize,
                        color: p.selected ? c.pigment : c.ink,
                      ),
                    ),
                  ),
                  // The lamp is in the cap, over its glyph: at the box's corner it sat half off the round key's
                  // rim with its halo, a badge stuck on.
                  if (p.selected)
                    Positioned(
                      top: size * .125,
                      left: 0,
                      right: 0,
                      child: const Center(child: NeumorphicLed()),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              p.label,
              textAlign: TextAlign.center,
              style: t.textTheme.text(14, 18, weight: FontWeight.w700),
            ),
            if (p.note != null) ...[
              const SizedBox(height: 2),
              Text(
                p.note!,
                textAlign: TextAlign.center,
                style: t.textTheme.micro
                    .copyWith(color: p.selected ? c.pigmentInk : c.inkTertiary)
                    .tabular,
              ),
            ],
          ],
        ),
      );
    }

    return NeumorphicWell(
      style: style,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final slot = MediaQuery.textScalerOf(context).scale(80);
          final columns = math.max(
            1,
            math.min(
              math.min(items.length, 4),
              ((constraints.maxWidth + 4) / (slot + 4)).floor(),
            ),
          );
          final rows = <Widget>[];
          for (var i = 0; i < items.length; i += columns) {
            final line = items.sublist(i, math.min(i + columns, items.length));
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var j = 0; j < columns; j++) ...[
                    if (j > 0) const SizedBox(width: 4),
                    Expanded(
                      child: j < line.length
                          ? push(line[j])
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            );
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const SizedBox(height: 14),
                rows[i],
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A small note in a well: an aside, or what's next. The words stay short, and a well this small stays on the control radius.
///
/// ```dart
/// NeumorphicNote(icon: NeumorphicGlyphs.zap, title: 'A short note about the page.')
/// ```
class NeumorphicNote extends StatelessWidget {
  /// Creates a [NeumorphicNote].
  const NeumorphicNote({
    super.key,
    this.style,
    this.icon,
    this.overline,
    required this.title,
    this.subtitle,
    this.well = false,
  });

  /// Frame styling before the shared card component theme.
  final NeumorphicStyle? style;

  /// The glyph displayed with the content.
  final IconData? icon;

  /// A small line over the words.
  final String? overline;

  /// The primary heading.
  final String title;

  /// A small line under: makes [title] bold.
  final String? subtitle;

  /// The glyph stands in a round well, for a note that names a thing.
  final bool well;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final c = t.colors;
    final strong = overline != null || subtitle != null;
    final mark = icon == null
        ? null
        : well
        ? NeumorphicIconWell(icon!)
        : Icon(icon, size: 18, color: c.inkTertiary);
    return NeumorphicWell(
      style: style,
      small: true,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          if (mark != null) ...[mark, SizedBox(width: well ? 12 : 10)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (overline != null)
                  Text(overline!, style: t.textTheme.micro.tabular),
                Text(
                  title,
                  style: strong
                      ? t.textTheme.caption.copyWith(
                          fontWeight: FontWeight.w700,
                          color: c.ink,
                        )
                      : t.textTheme.caption
                            .copyWith(color: c.inkSecondary)
                            .tabular,
                ),
                if (subtitle != null)
                  Text(subtitle!, style: t.textTheme.micro.tabular),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
