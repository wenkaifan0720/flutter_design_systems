// The inline calendar and the date range picker on ui_core's DesignCalendar: each day is the date picker's cap, raised
// out of the wall; a chosen day is pressed in with the pigment's dash under its figure; a range is a groove running
// between its two pressed ends.
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'component_themes.dart';
import 'controls.dart';
import 'frames.dart';
import 'glyphs.dart';
import 'knobs.dart';
import 'internal/cell_bank.dart' show neumorphicControlWidth;
import 'internal/panel.dart';
import 'localizations.dart';
import 'raised.dart';
import 'styled.dart';
import 'theme.dart';
import 'internal/day_face.dart';
import 'internal/out_of_use.dart';

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// A month's head: the back arrow, the name centred over the days, the forward arrow, as the date picker's month
/// heads (one head for one job: alone, the name at the start and both arrows at the end read as a second design beside
/// the picker). Months side by side turn together and read as one strip: the first has the back arrow, the last the
/// forward arrow, each name centred over its days.
Widget _header(
  BuildContext context,
  DesignCalendarHeader h, {
  required bool first,
  required bool last,
}) {
  final t = NeumorphicTheme.of(context);
  final words = NeumorphicLocalizations.of(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  final title = Semantics(
    header: true,
    liveRegion: true,
    child: Text(
      words.formatMonthYear(h.month),
      style: t.textTheme.title,
      textAlign: TextAlign.center,
    ),
  );
  final back = NeumorphicIconButton(
    rtl ? NeumorphicGlyphs.chevronRight : NeumorphicGlyphs.chevronLeft,
    label: words.previousMonth,
    onPressed: h.previous,
  );
  final forward = NeumorphicIconButton(
    rtl ? NeumorphicGlyphs.chevronLeft : NeumorphicGlyphs.chevronRight,
    label: words.nextMonth,
    onPressed: h.next,
  );
  // An arrow a month leaves out keeps its room, unseen and out of reach, so the name centres over the month's days.
  Widget room(Widget arrow) => ExcludeFocus(
    child: ExcludeSemantics(
      child: IgnorePointer(child: Opacity(opacity: 0, child: arrow)),
    ),
  );
  return Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        first ? back : room(back),
        Expanded(child: title),
        last ? forward : room(forward),
      ],
    ),
  );
}

Widget _weekday(BuildContext context, int weekday, String label) {
  final t = NeumorphicTheme.of(context);
  return SizedBox(
    height: 32,
    child: Center(child: Text(label, style: t.textTheme.micro)),
  );
}

Widget _day(
  BuildContext context,
  DesignCalendarDay day,
  Set<WidgetState> states,
  NeumorphicStyle? style,
  DesignCalendarController controller,
  int firstWeekday,
) {
  final t = NeumorphicTheme.of(context);
  final c = t.colors;
  // The day a waiting range's preview ends on (the pointer's, or the keyboard's) is drawn as its end until a press
  // makes it one.
  final previewEnd = day.isPreviewEnd && (day.inRange || day.inPreview);
  final end = day.selected || day.isRangeStart || day.isRangeEnd || previewEnd;
  final look = NeumorphicStyleOf(
    [style, t.datePickerTheme],
    {...states, if (end) WidgetState.selected},
  );
  final cell = t.shapes.corner(NeumorphicRadii.cap);
  final enabled = day.enabled;
  final run = _runOf(day, controller, firstWeekday);
  // A day keeps the 48 px target and grows with the reader's text: its figure's measured line, its mark, its insets
  // and the face's rim.
  final painter = TextPainter(
    text: TextSpan(
      text: '${day.date.day}',
      style: _figureStyle(t, day, end: end, look: look),
    ),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final line = painter.height;
  painter.dispose();
  return SizedBox(
    height: math.max(48, line + 6 + 6 + 6),
    // A day is a figure on the calendar's own surface. The chosen days are pressed in: one well for a day, and for a
    // range one smooth pressed channel along each week, its own ends marked by their figures.
    child: CustomPaint(
      painter: run == null
          ? null
          : _Channel(
              c,
              t.elevation,
              run,
              flat: NeumorphicFlatScope.of(context),
              rtl: Directionality.of(context) == TextDirection.rtl,
              preview: !day.inRange && day.inPreview,
            ),
      child: Padding(
        padding: const EdgeInsets.all(_wellInset),
        child: CustomPaint(
          foregroundPainter: states.contains(WidgetState.focused)
              ? neumorphicFocusLift(t, cell)
              : null,
          child: NeumorphicOutOfUse(
            off: !enabled,
            child: NeumorphicDayFace(
              shape: cell,
              hovered: run == null && states.contains(WidgetState.hovered),
              pressed: states.contains(WidgetState.pressed),
              style: style,
              themeStyle: t.datePickerTheme,
              states: {...states, if (!enabled) WidgetState.disabled},
              child: _figure(t, day, end: end, look: look),
            ),
          ),
        ),
      ),
    ),
  );
}

/// How far a day's well sits in from its cell.
const double _wellInset = 3;

/// Where [day] stands in the chosen run of its week: its place, the run's length, and whether the run's first and last
/// days are the range's own ends (their figures in the pigment) or the week's edge. Null when [day] is not chosen.
({int index, int count, bool deepFirst, bool deepLast})? _runOf(
  DesignCalendarDay day,
  DesignCalendarController controller,
  int firstWeekday,
) {
  final range = day.inRange
      ? controller.selectedRange
      : day.inPreview
      ? controller.preview
      : null;
  if (range == null) {
    return day.selected
        ? (index: 0, count: 1, deepFirst: true, deepLast: true)
        : null;
  }
  final d = day.date;
  final column = (d.weekday - firstWeekday) % 7;
  final weekStart = DateTime(d.year, d.month, d.day - column);
  final weekEnd = DateTime(d.year, d.month, d.day - column + 6);
  final from = range.start.isAfter(weekStart) ? range.start : weekStart;
  final last = range.end ?? range.start;
  final to = last.isBefore(weekEnd) ? last : weekEnd;
  int days(DateTime a, DateTime b) => (b.difference(a).inHours / 24).round();
  return (
    index: days(from, d),
    count: days(from, to) + 1,
    deepFirst: days(range.start, from) == 0,
    deepLast: days(to, last) == 0,
  );
}

/// A week's chosen run pressed in as one smooth channel: straight along the top and bottom, fully round at both ends,
/// each day painting the part of it inside its own cell. A day chosen alone is one well with round corners.
class _Channel extends CustomPainter {
  _Channel(
    this.c,
    this.elevation,
    this.run, {
    required this.flat,
    required this.rtl,
    required this.preview,
  });

  final NeumorphicColors c;
  final NeumorphicElevation elevation;
  final ({int index, int count, bool deepFirst, bool deepLast}) run;
  final bool flat, rtl, preview;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    // This day's share of its week row's run: the run starts [index] days before it, on the reading side.
    final start = (rtl ? run.index - run.count + 1 : -run.index) * w;
    final own = Rect.fromLTWH(
      _wellInset,
      _wellInset,
      w - 2 * _wellInset,
      size.height - 2 * _wellInset,
    );
    // One smooth channel per week row: straight along the top and bottom, fully round at both ends. A day chosen
    // alone is one well with the look's round corners.
    // A range's one day on a week's edge (its start on a Saturday) is a piece of the channel, round at both ends: as a
    // lone well's square corners it read as a day chosen apart from the run.
    final channel = run.count == 1 && run.deepFirst && run.deepLast
        ? (Path()..addRRect(
            RRect.fromRectAndRadius(
              own,
              Radius.circular(
                math.min(NeumorphicRadii.cap, own.shortestSide / 2),
              ),
            ),
          ))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTRB(
                start + _wellInset,
                own.top,
                start + run.count * w - _wellInset,
                own.bottom,
              ),
              Radius.circular(own.height / 2),
            ),
          ));
    final face = Color.alphaBlend(
      c.pigment.withValues(alpha: preview ? .05 : .10),
      c.ground,
    );
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    neumorphicPaintPressed(
      canvas,
      channel,
      c,
      light: (const Offset(-2, -2), 5),
      dark: (const Offset(2, 2), 5),
      face: LinearGradient(colors: [face, face])
          .createShader(channel.getBounds()),
      flat: flat,
      elevation: elevation.copyWith(
        depth: elevation.depth * (preview ? .5 : 1) * (run.count > 1 ? .75 : 1),
      ),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Channel old) =>
      old.c != c ||
      old.elevation != elevation ||
      old.run != run ||
      old.flat != flat ||
      old.rtl != rtl ||
      old.preview != preview;
}

TextStyle _figureStyle(
  NeumorphicThemeData t,
  DesignCalendarDay day, {
  required bool end,
  required NeumorphicStyleOf look,
}) => t.textTheme.body.tabular
    .copyWith(
      // The chosen days' and today's figures are in the pigment: the well says chosen, the underline says today.
      color: end || day.isToday
          ? t.colors.pigmentInk
          : day.inMonth
          ? t.colors.ink
          : t.colors.inkTertiary,
      fontWeight: end || day.isToday ? FontWeight.w800 : FontWeight.w500,
    )
    .merge(look.textStyle)
    .copyWith(color: look.foreground);

Widget _figure(
  NeumorphicThemeData t,
  DesignCalendarDay day, {
  required bool end,
  required NeumorphicStyleOf look,
}) {
  final c = t.colors;
  // The figure stands on the face's middle; its mark hangs under it, in the room the day keeps below (no day's number
  // rides high for a mark most days don't have).
  return Center(
    child: Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // One line always: a seventh of a phone is narrower than two large digits, so they shrink there, never wrap.
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${day.date.day}',
            maxLines: 1,
            softWrap: false,
            style: _figureStyle(t, day, end: end, look: look),
          ),
        ),
        // As wide as the mark at least, whatever the digit's width.
        PositionedDirectional(
          start: -8,
          end: -8,
          bottom: -6,
          height: 6,
          child: Center(
            child: SizedBox(
              width: 8,
              height: 2,
              child: ColoredBox(
                color: day.isToday ? c.pigment : const Color(0x00000000),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// A month (or [months] side by side) laid open on the page, for picking a day, a range or several days as the
/// [controller]'s mode says. Arrows move the keyboard's day, Page Up and Down the month, Enter picks; a range shows its
/// preview under the pointer or the keyboard before its second end is picked.
///
/// ```dart
/// NeumorphicCalendar(controller: DesignCalendarController(firstDate: start, lastDate: end))
/// ```
class NeumorphicCalendar extends StatelessWidget {
  /// A calendar on [controller].
  const NeumorphicCalendar({
    super.key,
    required this.controller,
    this.months = 1,
    this.onChanged,
    this.firstWeekday,
    this.style,
  });

  /// The days, the mode and the choice.
  final DesignCalendarController controller;

  /// How many months show side by side.
  final int months;

  /// Called with the day just chosen; the [controller] holds the whole choice.
  final ValueChanged<DateTime>? onChanged;

  /// The week's first day, a [DateTime] weekday; the locale's when null.
  final int? firstWeekday;

  /// The day cells' own style, before the date picker's theme.
  final NeumorphicStyle? style;

  /// The narrowest a month is laid out: seven cells of 44, room for a day's cap with its figure and dash at a 1.3 text
  /// scale. A column narrower than the months scrolls them sideways instead of crushing them.
  static const double minMonthWidth = 7 * 44;

  /// The widest a month is laid out from a medium window up: seven days of 48, the platform's target.
  static const double maxMonthWidth = 7 * 48;

  @override
  Widget build(BuildContext context) {
    final words = NeumorphicLocalizations.of(context);
    final calendar = DesignCalendar(
      controller: controller,
      months: months,
      onChanged: onChanged,
      firstWeekday: firstWeekday ?? words.firstDayOfWeek,
      monthLabel: words.formatMonthYear,
      dayLabel: words.formatFullDate,
      headerBuilder: (context, h) => _header(
        context,
        h,
        first: _sameMonth(h.month, controller.month),
        last: _sameMonth(
          h.month,
          DateTime(controller.month.year, controller.month.month + months - 1),
        ),
      ),
      weekdayBuilder: _weekday,
      monthsBuilder: (context, list) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, month) in list.indexed) ...[
            if (i > 0) const SizedBox(width: 28),
            Expanded(child: month),
          ],
        ],
      ),
      dayBuilder: (context, day, states) => _day(
        context,
        day,
        states,
        style,
        controller,
        firstWeekday ?? words.firstDayOfWeek,
      ),
    );
    final least = minMonthWidth * months + 28 * (months - 1);
    final most = maxMonthWidth * months + 28 * (months - 1);
    // A month's figures grow with the text only so far (1.3), as Material's date picker's do: at twice the text on a
    // phone its figures ran together and to the well's walls.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: _sized(calendar, least, most),
    );
  }

  Widget _sized(Widget calendar, double least, double most) {
    return LayoutBuilder(
      builder: (context, box) {
        if (!box.hasBoundedWidth) return calendar;
        if (box.maxWidth < least) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(width: least, child: calendar),
          );
        }
        // From a medium window up a month keeps to its seven days, from its column's start: a week spread over a 1440
        // column reads as a band (design6 P, 11-12). On a phone it spans its column.
        final width = neumorphicControlWidth(context, box.maxWidth, most);
        if (width >= box.maxWidth) return calendar;
        return Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: 1,
          child: SizedBox(width: width, child: calendar),
        );
      },
    );
  }
}

/// A range of days picked on the calendar, first end then second, with the span written above it ("14 June – 18 June,
/// 4 nights"). Two months side by side when there is room, one when there is not.
/// [showNeumorphicDateRangePicker] raises one in a dialog.
///
/// ```dart
/// NeumorphicDateRangePicker(controller: DesignCalendarController(firstDate: start, lastDate: end, mode: DesignCalendarMode.range))
/// ```
class NeumorphicDateRangePicker extends StatelessWidget {
  /// A range picker on [controller], which should be in range mode.
  const NeumorphicDateRangePicker({
    super.key,
    required this.controller,
    this.onChanged,
    this.nightsLabel,
    this.style,
  });

  /// The days and the range.
  final DesignCalendarController controller;

  /// Called when the range changes.
  final ValueChanged<DesignDateRange?>? onChanged;

  /// The span's words after its dates; null: "N nights".
  final String Function(int nights)? nightsLabel;

  /// The day cells' own style, before the date picker's theme.
  final NeumorphicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) => ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final r = controller.selectedRange;
          final nights = r == null || r.end == null
              ? null
              : r.end!.difference(r.start).inDays;
          final span = r == null
              ? words.chooseDate
              : '${words.formatFullDate(r.start)} – ${r.end == null ? '…' : words.formatFullDate(r.end!)}'
                    '${nights == null ? '' : ', ${nightsLabel?.call(nights) ?? '$nights ${nights == 1 ? 'night' : 'nights'}'}'}';
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                liveRegion: true,
                child: Text(span, style: t.textTheme.body.tabular),
              ),
              const SizedBox(height: 12),
              NeumorphicCalendar(
                controller: controller,
                months: box.maxWidth >= 640 ? 2 : 1,
                style: style,
                onChanged: (_) => onChanged?.call(controller.selectedRange),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Raises a [NeumorphicDateRangePicker] in a dialog; completes with the range on Done, or null.
///
/// ```dart
/// final stay = await showNeumorphicDateRangePicker(context, firstDate: today, lastDate: nextYear);
/// ```
Future<DesignDateRange?> showNeumorphicDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  DesignDateRange? initialDateRange,
  String? title,
  String? doneLabel,
}) {
  final controller = DesignCalendarController(
    firstDate: firstDate,
    lastDate: lastDate,
    mode: DesignCalendarMode.range,
    selectedRange: initialDateRange,
  );
  final words = NeumorphicLocalizations.of(context);
  return showNeumorphicDialog<DesignDateRange>(
    context,
    builder: (context) => NeumorphicDialog(
      title: title ?? words.chooseDate,
      content: [NeumorphicDateRangePicker(controller: controller)],
      actions: [
        NeumorphicButton(
          words.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        ListenableBuilder(
          listenable: controller,
          builder: (context, _) => NeumorphicButton.filled(
            doneLabel ?? words.done,
            onPressed: controller.selectedRange?.isComplete ?? false
                ? () => Navigator.of(context).pop(controller.selectedRange)
                : null,
          ),
        ),
      ],
    ),
  ).whenComplete(controller.dispose);
}
