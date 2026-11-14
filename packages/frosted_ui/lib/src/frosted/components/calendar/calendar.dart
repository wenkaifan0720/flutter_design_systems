import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/hit_slop.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../pressable/pressable.dart';
import '../../internal/dim.dart';

export 'package:ui_core/ui_core.dart' show DesignDateRange;

/// A month (or [months] side by side) laid open on the page (shadcn's
/// Calendar, Material's CalendarDatePicker): the month's name with its
/// steps back and on, the weekdays, then the days, the chosen one on the
/// ink act and today ringed. One Tab stop for the grid; the arrows walk
/// the days (Page Up and Down the months, Home and End the week), Return
/// or Space chooses. Days outside [firstDate] to [lastDate], or that
/// [selectableDayPredicate] refuses, fade and take no press. ui_core's
/// [DesignCalendar] is the behaviour.
///
/// ```dart
/// FrostedCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027, 12, 31), value: due, onChanged: (d) => setState(() => due = d))
/// ```
class FrostedCalendar extends StatefulWidget {
  /// A calendar between [firstDate] and [lastDate], [value] chosen.
  const FrostedCalendar({
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.currentDate,
    this.months = 1,
    this.selectableDayPredicate,
    super.key,
  });

  /// The first day that can be chosen.
  final DateTime firstDate;

  /// The last day that can be chosen.
  final DateTime lastDate;

  /// The chosen day.
  final DateTime? value;

  /// Called with the day chosen.
  final ValueChanged<DateTime>? onChanged;

  /// Today (the clock's, when null).
  final DateTime? currentDate;

  /// How many months stand side by side.
  final int months;

  /// Whether a day can be chosen, beyond the range.
  final bool Function(DateTime day)? selectableDayPredicate;

  @override
  State<FrostedCalendar> createState() => _FrostedCalendarState();
}

class _FrostedCalendarState extends State<FrostedCalendar> {
  late DesignCalendarController _controller = _make();

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    selectedDate: widget.value,
    initialMonth: widget.value ?? widget.currentDate,
    currentDate: widget.currentDate,
    selectable: widget.selectableDayPredicate,
  );

  @override
  void didUpdateWidget(FrostedCalendar old) {
    super.didUpdateWidget(old);
    if (old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old.currentDate != widget.currentDate ||
        old.selectableDayPredicate != widget.selectableDayPredicate) {
      final previous = _controller;
      _controller = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
      return;
    }
    final value = widget.value;
    if (value != null && !_same(value, _controller.selectedDate)) {
      _controller.select(value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _FrostedMonths(
    controller: _controller,
    months: widget.months,
    onChanged: widget.onChanged == null
        ? null
        : (c) {
            final day = c.selectedDate;
            if (day != null) widget.onChanged!(day);
          },
  );
}

/// A range of days chosen on an open calendar (shadcn's Calendar in range
/// mode, Material's date range picker): the first press sets the start,
/// the second the end (an earlier day starts over); between the two a band
/// of the accent's wash joins the ends, each on the ink act, and before
/// the second press the band follows the pointer or the keyboard as a
/// paler preview. Two months stand side by side by default. ui_core's
/// [DesignCalendar] (range mode) is the behaviour.
///
/// ```dart
/// FrostedDateRangePicker(firstDate: DateTime(2026), lastDate: DateTime(2027, 12, 31), value: trip, onChanged: (r) => setState(() => trip = r))
/// ```
class FrostedDateRangePicker extends StatefulWidget {
  /// A range picker between [firstDate] and [lastDate], [value] chosen.
  const FrostedDateRangePicker({
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.currentDate,
    this.months = 2,
    super.key,
  });

  /// The first day that can be chosen.
  final DateTime firstDate;

  /// The last day that can be chosen.
  final DateTime lastDate;

  /// The chosen range.
  final DesignDateRange? value;

  /// Called with the range as it is chosen: first with its start alone,
  /// then whole.
  final ValueChanged<DesignDateRange>? onChanged;

  /// Today (the clock's, when null).
  final DateTime? currentDate;

  /// How many months stand side by side (one on a narrow page).
  final int months;

  @override
  State<FrostedDateRangePicker> createState() => _FrostedDateRangePickerState();
}

class _FrostedDateRangePickerState extends State<FrostedDateRangePicker> {
  late DesignCalendarController _controller = _make();

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: DesignCalendarMode.range,
    selectedRange: widget.value,
    initialMonth: widget.value?.start ?? widget.currentDate,
    currentDate: widget.currentDate,
  );

  @override
  void didUpdateWidget(FrostedDateRangePicker old) {
    super.didUpdateWidget(old);
    if (old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old.currentDate != widget.currentDate ||
        (widget.value != old.value &&
            widget.value != _controller.selectedRange)) {
      final previous = _controller;
      _controller = _make();
      WidgetsBinding.instance.addPostFrameCallback((_) => previous.dispose());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => _FrostedMonths(
      controller: _controller,
      months: box.maxWidth < 560 ? 1 : widget.months,
      onChanged: widget.onChanged == null
          ? null
          : (c) {
              final range = c.selectedRange;
              if (range != null) widget.onChanged!(range);
            },
    ),
  );
}

bool _same(DateTime a, DateTime? b) =>
    b != null && a.year == b.year && a.month == b.month && a.day == b.day;

/// The months a calendar shows, painted: the head with its steps, the
/// weekdays, the day cells for their states.
class _FrostedMonths extends StatelessWidget {
  const _FrostedMonths({
    required this.controller,
    required this.months,
    required this.onChanged,
  });

  /// The days, the chosen ones and the month shown.
  final DesignCalendarController controller;

  /// How many months stand side by side.
  final int months;

  /// Called as the choice changes.
  final ValueChanged<DesignCalendarController>? onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    const cell = 38.0;
    // A day's row and its least width are the touch target (48 under a
    // finger, 44 under a pointer, never under the source's 44): where seven
    // do not fit, a day overhangs its seventh, centred.
    final target = FrostedBreakpoints.hitTargetOf(context);
    final row = math.max(44.0, target);
    Widget step(IconData glyph, String label, VoidCallback? go) =>
        FrostedHitSlop(
          child: FrostedPressable(
            onPressed: go,
            label: label,
            radius: 18,
            child: SizedBox.square(
              dimension: 36,
              child: FrostedDim(
                off: go == null,
                child: Icon(
                  glyph,
                  size: FrostedChromeMetrics.pickerGlyph + 2,
                  color: t.colorScheme.textPrimary,
                ),
              ),
            ),
          ),
        );
    // A month stands at most 400 wide, at the start of a wider field: on a
    // desktop column its days keep together rather than spread 100 apart.
    const monthMax = 400.0;
    final calendar = DesignCalendar(
      controller: controller,
      months: months,
      firstWeekday: DesignLocalizations.of(context).firstDayOfWeek,
      showOutsideDays: false,
      minDayWidth: target,
      // The behaviour gives the day chosen; the choice (a day, or a range
      // in range mode) is the controller's.
      onChanged: onChanged == null ? null : (_) => onChanged!(controller),
      dayLabel: words.fullDate,
      monthLabel: (m) => '${words.monthName(m.month)} ${m.year}',
      weekdayLabel: DesignLocalizations.of(context).formatShortWeekday,
      monthsBuilder: (context, grids) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: FrostedSpacing.s24,
        children: [for (final g in grids) Expanded(child: g)],
      ),
      headerBuilder: (context, head) => Padding(
        padding: const EdgeInsets.only(bottom: FrostedSpacing.s8),
        child: SizedBox(
          height: 36,
          child: Row(
            children: [
              if (head.previous != null || months == 1)
                step(
                  FrostedGlyphs.chevronLeft,
                  DesignLocalizations.of(context).previousMonthTooltip,
                  head.previous,
                ),
              Expanded(
                child: Text(
                  head.label,
                  textAlign: TextAlign.center,
                  style: t.textTheme.labelLarge.c(t.colorScheme.textPrimary),
                ),
              ),
              if (head.next != null || months == 1)
                step(
                  FrostedGlyphs.forward,
                  DesignLocalizations.of(context).nextMonthTooltip,
                  head.next,
                ),
            ],
          ),
        ),
      ),
      weekdayBuilder: (context, weekday, label) => SizedBox(
        height: 28,
        child: Center(child: Text(label, style: t.textTheme.labelMedium)),
      ),
      dayBuilder: (context, day, states) {
        final ends = day.selected || day.isRangeStart || day.isRangeEnd;
        final between = day.inRange && !ends;
        // A preview runs from the waiting start to the day the pointer (or
        // the keyboard) rests on, and ends there with a finished end's
        // shape; a preview of the start alone draws no band.
        final preview = controller.preview;
        final previewing =
            preview != null && !_same(preview.start, preview.end);
        final previewEnd = previewing && !ends && _same(day.date, preview.end);
        final lit =
            !previewEnd &&
            (states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed));
        final ink = ends
            ? t.colorScheme.onButton
            : day.isToday
            ? t.colorScheme.textPrimary
            : t.colorScheme.textSecondary;
        Widget face = SizedBox.square(
          dimension: cell,
          child: FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(cell / 2),
            color: ends ? null : (lit ? t.glass.wash : null),
            gradients: ends ? [t.colorScheme.buttonFill] : const <Gradient>[],
            sheen: ends ? t.colorScheme.buttonSheen : null,
            shadows: ends ? t.shadows.button : const <BoxShadow>[],
            ring: day.isToday && !ends ? t.colorScheme.borderStrong : null,
            child: Center(
              child: Text(
                '${day.date.day}',
                style:
                    (ends || day.isToday
                            ? t.textTheme.labelLarge.semibold
                            : t.textTheme.labelLarge)
                        .c(ink)
                        .tabular,
              ),
            ),
          ),
        );
        face = FrostedFocusRing(
          shown: states.contains(WidgetState.focused),
          radius: cell / 2,
          child: face,
        );
        face = FrostedDim(off: !day.enabled, child: face);
        // The band joining a range's ends, under the days: whole between
        // them, half under each end, paler while it is only a preview. A
        // preview's end has no face of its own to cover the band's end, so
        // the band itself ends round there, at the day's edge.
        final inPreview = previewing && day.inPreview;
        final band = between || (inPreview && !ends)
            ? (between ? t.colorScheme.accentSubtle : t.glass.wash)
            : (day.inRange && (day.isRangeStart != day.isRangeEnd))
            ? t.colorScheme.accentSubtle
            : inPreview
            ? t.glass.wash
            : null;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final half = day.isRangeStart && !day.isRangeEnd
            ? (rtl ? Alignment.centerLeft : Alignment.centerRight)
            : (day.isRangeEnd && !day.isRangeStart) || previewEnd
            ? (rtl ? Alignment.centerRight : Alignment.centerLeft)
            : null;
        // Where a week's row (or the month) begins or ends the band ends
        // there too, round at the day's edge: run to the cell's edge it
        // stood square past the grid's last day (self-review round 1).
        final column =
            (day.date.weekday -
                DesignLocalizations.of(context).firstDayOfWeek) %
            7;
        final rowStart = column == 0 || day.date.day == 1;
        final rowEnd =
            column == 6 ||
            DateTime(day.date.year, day.date.month, day.date.day + 1).day == 1;
        // An end whose half would run off its row has nothing to join.
        final offRow =
            (day.isRangeStart && !day.isRangeEnd && rowEnd) ||
            (day.isRangeEnd && !day.isRangeStart && rowStart);
        // A preview's end that opens a row stands alone there, round.
        final loneEnd = previewEnd && rowStart;
        final capped = (half == null && (rowStart || rowEnd)) || loneEnd;
        return SizedBox(
          height: row,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (band != null && !offRow)
                Positioned.fill(
                  top: (row - cell) / 2,
                  bottom: (row - cell) / 2,
                  child: capped
                      ? _CappedBand(
                          color: band,
                          cell: cell,
                          start: rowStart,
                          end: rowEnd || loneEnd,
                        )
                      : half == null
                      ? ColoredBox(color: band)
                      : previewEnd
                      ? Align(
                          alignment: half,
                          child: LayoutBuilder(
                            builder: (context, box) => SizedBox(
                              key: const ValueKey('frosted-preview-end'),
                              width: box.maxWidth / 2 + cell / 2,
                              height: cell,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: band,
                                  borderRadius:
                                      BorderRadiusDirectional.horizontal(
                                        end: Radius.circular(cell / 2),
                                      ).resolve(Directionality.of(context)),
                                ),
                              ),
                            ),
                          ),
                        )
                      : Align(
                          alignment: half,
                          child: FractionallySizedBox(
                            widthFactor: .5,
                            heightFactor: 1,
                            child: ColoredBox(color: band),
                          ),
                        ),
                ),
              face,
            ],
          ),
        );
      },
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: months * monthMax + (months - 1) * FrostedSpacing.s24,
        ),
        child: calendar,
      ),
    );
  }
}

/// A piece of a range's band where a week's row (or the month) begins
/// ([start]) or ends ([end]): round at the day's own edge on that side, to
/// the cell's edge on the other; a day that both begins and ends its row
/// is a round of the day's size.
class _CappedBand extends StatelessWidget {
  const _CappedBand({
    required this.color,
    required this.cell,
    required this.start,
    required this.end,
  });

  final Color color;
  final double cell;
  final bool start;
  final bool end;

  @override
  Widget build(BuildContext context) {
    const round = Radius.circular(9999);
    return LayoutBuilder(
      builder: (context, box) => Align(
        alignment: start && end
            ? Alignment.center
            : start
            ? AlignmentDirectional.centerEnd
            : AlignmentDirectional.centerStart,
        child: SizedBox(
          width: start && end ? cell : box.maxWidth / 2 + cell / 2,
          height: cell,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadiusDirectional.horizontal(
                start: start ? round : Radius.zero,
                end: end ? round : Radius.zero,
              ).resolve(Directionality.of(context)),
            ),
          ),
        ),
      ),
    );
  }
}
