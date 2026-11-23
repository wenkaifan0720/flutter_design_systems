// The inline calendar and the date range picker on ui_core's RawCalendarDatePicker: each day is the date picker's cap, raised
// out of the wall; a chosen day is pressed in with the pigment's dash under its figure; a range is a groove running
// between its two pressed ends.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
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
import 'internal/reach.dart' show neumorphicAtEnd;
import 'internal/day_face.dart';
import 'internal/out_of_use.dart';
import 'internal/moulded.dart';

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// A month's head: the back arrow, the name centred over the days, the forward arrow, as the date picker's month
/// heads (one head for one job: alone, the name at the start and both arrows at the end read as a second design beside
/// the picker). Months side by side turn together and read as one strip: the first has the back arrow, the last the
/// forward arrow, each name centred over its days.
Widget _header(
  BuildContext context,
  RawCalendarHeaderDetails h, {
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
  final forward = neumorphicAtEnd(
    NeumorphicIconButton(
      rtl ? NeumorphicGlyphs.chevronLeft : NeumorphicGlyphs.chevronRight,
      label: words.nextMonth,
      onPressed: h.next,
    ),
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
  RawCalendarDayDetails day,
  Set<WidgetState> states,
  NeumorphicStyle? style,
  RawCalendarController controller,
  int firstWeekday,
) {
  final t = NeumorphicTheme.of(context);
  final c = t.colors;
  // The day a waiting range's preview ends on (the pointer's, or the keyboard's) is drawn as its end until a press
  // makes it one.
  final previewEnd = day.isPreviewEnd && (day.inRange || day.inPreview);
  final end = day.selected || day.isRangeStart || day.isRangeEnd || previewEnd;
  final look = neumorphicStyleOf(
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
  RawCalendarDayDetails day,
  RawCalendarController controller,
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
  RawCalendarDayDetails day, {
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
  RawCalendarDayDetails day, {
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
/// A [controller] is the caller's, made once (in a State's initState, as `RawCalendarController(firstDate: start,
/// lastDate: end)`) and disposed with it. Without one the calendar picks one day between [firstDate] and [lastDate] on
/// a controller of its own, starting on [initialDate], and tells [onChanged].
///
/// ```dart
/// NeumorphicCalendar(controller: dates)
/// ```
///
/// ```dart
/// NeumorphicCalendar(firstDate: DateTime(2026), lastDate: DateTime(2026, 12, 31), onChanged: (day) {})
/// ```
class NeumorphicCalendar extends StatefulWidget {
  /// A calendar on [controller], or on one of its own between [firstDate] and [lastDate].
  const NeumorphicCalendar({
    super.key,
    this.controller,
    this.firstDate,
    this.lastDate,
    this.initialDate,
    this.months = 1,
    this.onChanged,
    this.firstWeekday,
    this.style,
  }) : assert(months >= 1),
       assert((firstWeekday ?? 1) >= 1 && (firstWeekday ?? 7) <= 7),
       assert(
         controller != null || (firstDate != null && lastDate != null),
         'A NeumorphicCalendar without a controller needs a firstDate and a lastDate.',
       );

  /// The days, the mode and the choice. The caller keeps it and disposes it; when null, the calendar makes its own
  /// from [firstDate], [lastDate] and [initialDate] and disposes it with itself.
  final RawCalendarController? controller;

  /// The earliest day it offers, without a [controller].
  final DateTime? firstDate;

  /// The latest day it offers, without a [controller].
  final DateTime? lastDate;

  /// The day chosen when it first shows, without a [controller]; later changes are not read.
  final DateTime? initialDate;

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
  State<NeumorphicCalendar> createState() => _NeumorphicCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawCalendarController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'firstDate',
          firstDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>('lastDate', lastDate, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'initialDate',
          initialDate,
          defaultValue: null,
        ),
      )
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('firstWeekday', firstWeekday, defaultValue: null))
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

/// A calendar's own controller, kept while the caller hands in none: made from the widget's bounds and its first
/// choice, made again when the bounds change (keeping the choice and the month while they are still in them), and
/// disposed when a controller is handed in or the widget goes.
mixin _OwnCalendar<W extends StatefulWidget> on State<W> {
  RawCalendarController? _own;

  RawCalendarController? get _handed;
  DateTime? get _first;
  DateTime? get _last;
  RawCalendarController _make(RawCalendarController? before);

  RawCalendarController get _controller => _handed ?? (_own ??= _make(null));

  void _update(DateTime? oldFirst, DateTime? oldLast) {
    final own = _own;
    if (own == null) return;
    if (_handed != null) {
      own.dispose();
      _own = null;
    } else if (!_sameDay(_first, oldFirst) || !_sameDay(_last, oldLast)) {
      _own = _make(own);
      own.dispose();
    }
  }

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }
}

bool _sameDay(DateTime? a, DateTime? b) => a == null || b == null
    ? a == b
    : a.year == b.year && a.month == b.month && a.day == b.day;

/// [day] when it is still between [first] and [last], else null.
DateTime? _within(DateTime? day, DateTime first, DateTime last) {
  if (day == null) return null;
  final d = DateTime(day.year, day.month, day.day);
  return d.isBefore(DateTime(first.year, first.month, first.day)) ||
          d.isAfter(DateTime(last.year, last.month, last.day))
      ? null
      : day;
}

class _NeumorphicCalendarState extends State<NeumorphicCalendar>
    with _OwnCalendar<NeumorphicCalendar> {
  @override
  RawCalendarController? get _handed => widget.controller;
  @override
  DateTime? get _first => widget.firstDate;
  @override
  DateTime? get _last => widget.lastDate;

  @override
  RawCalendarController _make(RawCalendarController? before) {
    final first = widget.firstDate!, last = widget.lastDate!;
    return RawCalendarController(
      firstDate: first,
      lastDate: last,
      selectedDate: before == null
          ? widget.initialDate
          : _within(before.selectedDate, first, last),
      initialMonth: before?.month,
    );
  }

  @override
  void didUpdateWidget(NeumorphicCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update(oldWidget.firstDate, oldWidget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final months = widget.months;
    final firstWeekday = widget.firstWeekday;
    final style = widget.style;
    final words = NeumorphicLocalizations.of(context);
    final calendar = RawCalendarDatePicker(
      controller: controller,
      months: months,
      onChanged: widget.onChanged,
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
    final least = NeumorphicCalendar.minMonthWidth * months + 28 * (months - 1);
    final most = NeumorphicCalendar.maxMonthWidth * months + 28 * (months - 1);
    // A month's figures grow with the text only so far (1.3), as Material's date picker's do: at twice the text on a
    // phone its figures would run together and into the well's walls.
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
        // column would read as a band. On a phone it spans its column.
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

/// A range of days picked on the calendar, first end then second, with the span written above it ("14 June – 18 June, 4
/// nights"). Two months side by side when there is room, one when there is not. [showNeumorphicDateRangePicker] raises
/// one in a dialog. A [controller] is the caller's, made once (in a State's initState, as
/// `RawCalendarController(firstDate: start, lastDate: end, mode: RawCalendarMode.range)`) and disposed with it.
/// Without one the picker keeps a range between [firstDate] and [lastDate] on a controller of its own, starting on
/// [initialDateRange], and tells [onChanged].
///
/// ```dart
/// NeumorphicDateRangePicker(controller: stay)
/// ```
///
/// ```dart
/// NeumorphicDateRangePicker(firstDate: DateTime(2026), lastDate: DateTime(2026, 12, 31), onChanged: (range) {})
/// ```
class NeumorphicDateRangePicker extends StatefulWidget {
  /// A range picker on [controller], which should be in range mode, or on one of its own between [firstDate] and
  /// [lastDate].
  const NeumorphicDateRangePicker({
    super.key,
    this.controller,
    this.firstDate,
    this.lastDate,
    this.initialDateRange,
    this.onChanged,
    this.nightsLabel,
    this.style,
  }) : assert(
         controller != null || (firstDate != null && lastDate != null),
         'A NeumorphicDateRangePicker without a controller needs a firstDate and a lastDate.',
       );

  /// The days and the range. The caller keeps it and disposes it; when null, the picker makes its own in range mode
  /// from [firstDate], [lastDate] and [initialDateRange] and disposes it with itself.
  final RawCalendarController? controller;

  /// The earliest day it offers, without a [controller].
  final DateTime? firstDate;

  /// The latest day it offers, without a [controller].
  final DateTime? lastDate;

  /// The range chosen when it first shows, without a [controller]; later changes are not read.
  final RawDateRange? initialDateRange;

  /// Called when the range changes.
  final ValueChanged<RawDateRange?>? onChanged;

  /// The span's words after its dates; null: the look's words, [NeumorphicLocalizations.nights].
  final String Function(int nights)? nightsLabel;

  /// The day cells' own style, before the date picker's theme.
  final NeumorphicStyle? style;

  @override
  State<NeumorphicDateRangePicker> createState() =>
      _NeumorphicDateRangePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawCalendarController>(
          'controller',
          controller,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>(
          'firstDate',
          firstDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<DateTime>('lastDate', lastDate, defaultValue: null),
      )
      ..add(
        DiagnosticsProperty<RawDateRange>(
          'initialDateRange',
          initialDateRange,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawDateRange?>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(
        ObjectFlagProperty<String Function(int nights)>.has(
          'nightsLabel',
          nightsLabel,
        ),
      )
      ..add(
        DiagnosticsProperty<NeumorphicStyle>(
          'style',
          style,
          defaultValue: null,
        ),
      );
  }
}

class _NeumorphicDateRangePickerState extends State<NeumorphicDateRangePicker>
    with _OwnCalendar<NeumorphicDateRangePicker> {
  @override
  RawCalendarController? get _handed => widget.controller;
  @override
  DateTime? get _first => widget.firstDate;
  @override
  DateTime? get _last => widget.lastDate;

  @override
  RawCalendarController _make(RawCalendarController? before) {
    final first = widget.firstDate!, last = widget.lastDate!;
    final range = before == null
        ? widget.initialDateRange
        : before.selectedRange;
    final kept =
        range != null &&
        _within(range.start, first, last) != null &&
        (range.end == null || _within(range.end, first, last) != null);
    return RawCalendarController(
      firstDate: first,
      lastDate: last,
      mode: RawCalendarMode.range,
      selectedRange: kept ? range : null,
      initialMonth: before?.month,
    );
  }

  @override
  void didUpdateWidget(NeumorphicDateRangePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    _update(oldWidget.firstDate, oldWidget.lastDate);
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final onChanged = widget.onChanged;
    final nightsLabel = widget.nightsLabel;
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
                    '${nights == null ? '' : ', ${nightsLabel?.call(nights) ?? words.nights(nights)}'}';
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
                style: widget.style,
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
Future<RawDateRange?> showNeumorphicDateRangePicker(
  BuildContext context, {
  required DateTime firstDate,
  required DateTime lastDate,
  RawDateRange? initialDateRange,
  String? title,
  String? doneLabel,
}) {
  final controller = RawCalendarController(
    firstDate: firstDate,
    lastDate: lastDate,
    mode: RawCalendarMode.range,
    selectedRange: initialDateRange,
  );
  final words = NeumorphicLocalizations.of(context);
  return showNeumorphicDialog<RawDateRange>(
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
