/// A month grid in the page, and a row that opens one to choose a range of
/// days, painted on ui_core's calendar.
library;

import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../internal/cap_label.dart';
import '../internal/controls.dart';
import '../internal/field.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/today_mark.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'pressable.dart';

// A range of days is ui_core's, exported with the picker so a screen names
// it without a Material import.
export 'package:ui_core/ui_core.dart' show DesignDateRange;

/// A day's 44 px slot around its 32 px mark, and one month's width.
const double _slot = MinimalLayout.minHitTarget;
const double _mark = MinimalChromeMetrics.control;
const double _monthWidth = 7 * _slot;

/// The gutter between months side by side: wider than a column step, so
/// two months read as two grids, not one of fourteen columns.
const double _monthGap = MinimalSpacing.s32;

/// The look of every Minimal calendar grid: a month's name over its
/// weekdays in mono, days as 32 px marks in 44 px slots. The chosen day is
/// the accent; today a short bar under its figure; a range is a quiet band from its start
/// to its end, the ends on the accent; the band a resting pointer
/// previews while the end is still to choose is fainter.
class _Grid extends StatelessWidget {
  const _Grid({
    required this.controller,
    required this.months,
    required this.firstWeekday,
    required this.onChanged,
    this.autofocus = false,
  });

  final DesignCalendarController controller;
  final int months;

  /// Null: the locale's ([MinimalLocalizations.firstDayOfWeek]).
  final int? firstWeekday;

  /// The day a press or Enter chose; [controller] holds what it made of it.
  final ValueChanged<DateTime> onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    String month(DateTime m) => words.monthYear(m);

    Widget day(DesignCalendarDay d, Set<WidgetState> states) {
      final ends = d.isRangeStart || d.isRangeEnd;
      final banded = d.inRange || d.inPreview;
      final band = d.inRange ? t.primarySubtle : t.muted;
      final marked = d.selected || (d.inRange && ends);
      // The day a waiting range's preview runs to (the pointer's or the
      // keyboard's): the band ends on the shape a finished range's end has,
      // in the band's colour, its edge in the accent.
      final previewEnd = !marked && d.isPreviewEnd && d.enabled;
      final ink = marked
          ? t.primaryForeground
          : !d.enabled
          ? t.textTertiary
          : d.inMonth
          ? t.foreground
          : t.textTertiary;
      final shape = MinimalShapes.inset(t.shapes.small, 1);
      // The band's two halves, so a range's start and end hold it on one
      // side only, mirrored right to left.
      final towardStart = banded && !d.isRangeStart;
      final towardEnd = banded && !d.isRangeEnd && !d.isPreviewEnd;
      // The whole cell, so the band runs on between two days' marks (the
      // pressable around it hands its child loose constraints).
      return SizedBox(
        width: double.infinity,
        height: _slot,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (banded)
              Positioned.fill(
                top: (_slot - _mark) / 2,
                bottom: (_slot - _mark) / 2,
                // Stretched: a childless box is only as tall as it must be.
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: ColoredBox(
                        color: towardStart ? band : const Color(0x00000000),
                      ),
                    ),
                    Expanded(
                      child: ColoredBox(
                        color: towardEnd ? band : const Color(0x00000000),
                      ),
                    ),
                  ],
                ),
              ),
            Container(
              width: _mark,
              height: _mark,
              alignment: Alignment.center,
              decoration: minimalFrame(
                shape,
                fill: marked
                    ? t.primary
                    : previewEnd
                    ? band
                    : null,
                side: previewEnd
                    ? BorderSide(color: t.primary, width: t.hairline)
                    : BorderSide.none,
              ),
              foregroundDecoration: minimalStateLayer(
                t,
                shape,
                states,
                ground: minimalGround(context),
              ),
              // The figure by its capitals, on the day's middle and level
              // along the week; today a short bar under it.
              child: minimalTodayMark(
                today: d.isToday,
                ink: ink,
                figure: minimalCapLabel(
                  Text(
                    '${d.date.day}',
                    style: (marked ? t.monoValue.medium : t.monoValue).c(ink),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, box) => _calendar(
        context,
        day,
        month,
        words,
        t,
        stacked:
            months > 1 &&
            box.maxWidth < months * _monthWidth + (months - 1) * _monthGap,
      ),
    );
  }

  Widget _calendar(
    BuildContext context,
    Widget Function(DesignCalendarDay, Set<WidgetState>) day,
    String Function(DateTime) month,
    MinimalLocalizations words,
    MinimalThemeData t, {
    required bool stacked,
  }) {
    return DesignCalendar(
      controller: controller,
      months: months,
      firstWeekday: firstWeekday ?? words.firstDayOfWeek,
      autofocus: autofocus,
      showOutsideDays: false,
      onChanged: onChanged,
      dayLabel: words.fullDate,
      monthLabel: month,
      weekdayLabel: (w) => words.weekdaysShort[w - 1],
      dayBuilder: (context, d, states) => day(d, states),
      weekdayBuilder: (context, weekday, label) => Padding(
        padding: const EdgeInsets.only(bottom: MinimalSpacing.s4),
        child: Text(
          words.weekdaysShort[weekday - 1],
          textAlign: TextAlign.center,
          style: t.mono.copyWith(fontSize: 11).c(t.mutedForeground),
        ),
      ),
      headerBuilder: (context, h) {
        final index =
            (h.month.year - controller.month.year) * 12 +
            h.month.month -
            controller.month.month;
        // Every month's name stands on its grid's edge, as one month's
        // does. Both chevrons stand together after one name: the first
        // month's when the months are stacked in a narrow column (where
        // the reader starts), the last one's when they stand side by side
        // (at the row's end, as one month's chevrons do).
        final chevrons = months == 1 || stacked
            ? index == 0
            : index == months - 1;
        return SizedBox(
          height: _slot,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  h.label,
                  style: t.body.semibold,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (chevrons) ...[
                // The grid hands the month before to the first header and
                // the month after to the last; the header that carries both
                // turns the other way itself.
                MinimalIconButton(
                  LucideIcons.chevronLeftDir,
                  label: words.previousMonth,
                  size: MinimalButtonSize.small,
                  onPressed:
                      h.previous ??
                      (controller.canGoBack ? () => controller.turn(-1) : null),
                ),
                const MinimalGap(MinimalSpacing.s8),
                MinimalIconButton(
                  LucideIcons.chevronRightDir,
                  label: words.nextMonth,
                  size: MinimalButtonSize.small,
                  onPressed:
                      h.next ??
                      (controller.canGoForward(months)
                          ? () => controller.turn(1)
                          : null),
                ),
              ],
            ],
          ),
        );
      },
      // Side by side where they fit, a gutter between; a narrow column
      // stacks them.
      monthsBuilder: (context, grids) => Wrap(
        spacing: _monthGap,
        runSpacing: MinimalSpacing.s16,
        children: [
          for (final g in grids) SizedBox(width: _monthWidth, child: g),
        ],
      ),
    );
  }

  static bool _same(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

/// A month in the page to choose a day on: a booking's date, a journal's
/// day. Minimal's month grid (the chosen day on the accent, today a bar under its figure)
/// under the month's name and two small chevrons; [months] above 1 sets
/// that many side by side.
///
/// One tab stop for the grid; the arrows move a day or a week, Page Up and
/// Down a month, Home and End to the week's ends, Enter or Space chooses;
/// the keyboard's day wears the focus ring and a screen reader hears each
/// day by its full date. The behaviour is ui_core's ([DesignCalendar]);
/// Minimal paints it. A form row that opens a calendar is
/// [MinimalDatePicker]; a range, [MinimalDateRangePicker].
///
/// ```dart
/// MinimalCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), value: day, onChanged: setDay)
/// ```
class MinimalCalendar extends StatefulWidget {
  /// A calendar between [firstDate] and [lastDate].
  const MinimalCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.today,
    this.months = 1,
    this.firstWeekday,
    this.selectable,
  });

  /// The earliest day it offers.
  final DateTime firstDate;

  /// The latest day it offers.
  final DateTime lastDate;

  /// The chosen day.
  final DateTime? value;

  /// Called with the day chosen; null shows the month without choosing.
  final ValueChanged<DateTime>? onChanged;

  /// The day marked as today (a bar under its figure); the device's unstated.
  final DateTime? today;

  /// How many months it shows: side by side where they fit, a 32 px gutter
  /// between them, stacked in a narrow column.
  final int months;

  /// The weekday a week starts on ([DateTime.monday] … [DateTime.sunday]);
  /// null takes the locale's ([MinimalLocalizations.firstDayOfWeek]: Sunday
  /// in English). Pass it only to override the locale.
  final int? firstWeekday;

  /// Which days can be chosen, beside the bounds; null for all.
  final bool Function(DateTime day)? selectable;

  @override
  State<MinimalCalendar> createState() => _MinimalCalendarState();
}

class _MinimalCalendarState extends State<MinimalCalendar> {
  late DesignCalendarController _controller = _make();

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    selectedDate: widget.value,
    currentDate: widget.today,
    selectable: widget.onChanged == null ? (_) => false : widget.selectable,
  );

  @override
  void didUpdateWidget(MinimalCalendar old) {
    super.didUpdateWidget(old);
    if (old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old.today != widget.today ||
        old.selectable != widget.selectable ||
        (old.onChanged == null) != (widget.onChanged == null)) {
      _controller.dispose();
      _controller = _make();
      return;
    }
    final v = widget.value;
    if (v == null) {
      if (_controller.selectedDate != null) _controller.clear();
    } else if (_controller.selectedDate == null ||
        !_Grid._same(_controller.selectedDate!, v)) {
      _controller.select(v);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _Grid(
    controller: _controller,
    months: widget.months,
    firstWeekday: widget.firstWeekday,
    onChanged: (_) {
      final day = _controller.selectedDate;
      if (day != null) widget.onChanged?.call(day);
    },
  );
}

/// A range of days from a form row: a stay, a report's period, a leave. A
/// boxed row like a [MinimalDatePicker]'s, the range in mono (`12 Mar – 18
/// Mar 2026`) or the hint; a press opens Minimal's panel under it with two
/// months side by side (one where the window is narrow). The first press
/// chooses the start, the next the end, a band previewing the range
/// between; the panel closes on the end, and the row reports the range.
///
/// The grid takes the keyboard as a [MinimalCalendar]'s; Escape closes the
/// panel and focus goes back to the row. The behaviour is ui_core's
/// ([DesignCalendar] in range mode, in a [DesignAnchoredOverlay]); Minimal
/// paints it.
///
/// ```dart
/// MinimalDateRangePicker(label: 'Stay', firstDate: DateTime(2026), lastDate: DateTime(2027), value: stay, onChanged: setStay)
/// ```
class MinimalDateRangePicker extends StatefulWidget {
  /// A range picker between [firstDate] and [lastDate].
  const MinimalDateRangePicker({
    super.key,
    required this.firstDate,
    required this.lastDate,
    this.value,
    this.onChanged,
    this.label,
    this.hint,
    this.today,
    this.firstWeekday,
    this.selectable,
  });

  /// The earliest day it offers.
  final DateTime firstDate;

  /// The latest day it offers.
  final DateTime lastDate;

  /// The chosen range: ui_core's [DesignDateRange], its first and last day.
  final DesignDateRange? value;

  /// Called with the range once its end is chosen; null disables the row.
  final ValueChanged<DesignDateRange>? onChanged;

  /// The row's name, over the box; also its name for a screen reader.
  final String? label;

  /// What the row shows with no range.
  final String? hint;

  /// The day marked as today (a bar under its figure); the device's unstated.
  final DateTime? today;

  /// The weekday a week starts on; null takes the locale's
  /// ([MinimalLocalizations.firstDayOfWeek]: Sunday in English).
  final int? firstWeekday;

  /// Which days can be chosen, beside the bounds; null for all.
  final bool Function(DateTime day)? selectable;

  @override
  State<MinimalDateRangePicker> createState() => _MinimalDateRangePickerState();
}

class _MinimalDateRangePickerState extends State<MinimalDateRangePicker> {
  DesignCalendarController _make() {
    final v = widget.value;
    return DesignCalendarController(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      mode: DesignCalendarMode.range,
      selectedRange: v,
      currentDate: widget.today,
      selectable: widget.selectable,
    );
  }

  DesignCalendarController? _open;

  @override
  void dispose() {
    _open?.dispose();
    super.dispose();
  }

  String _range(MinimalLocalizations words, DesignDateRange r) {
    String day(DateTime d, {required bool year}) =>
        '${d.day} ${words.monthsShort[d.month - 1]}${year ? ' ${d.year}' : ''}';
    final end = r.end ?? r.start;
    final sameYear = r.start.year == end.year;
    return '${day(r.start, year: !sameYear)} – ${day(end, year: true)}';
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final words = MinimalLocalizations.of(context);
    final enabled = widget.onChanged != null;
    final value = widget.value;
    final label = widget.label;
    final text = value == null
        ? (widget.hint ?? words.choose)
        : _range(words, value);

    final overlay = DesignAnchoredOverlay(
      semanticLabel: label,
      // The calendar keeps its own width under a wide field.
      placement: const DesignOverlayPlacement(
        gap: MinimalSpacing.s4,
        matchAnchorWidth: false,
      ),
      onOpenChanged: (open) {
        if (!open) {
          final c = _open;
          WidgetsBinding.instance.addPostFrameCallback((_) => c?.dispose());
          _open = null;
        }
      },
      anchorBuilder: (context, anchor) {
        final shape = t.shapes.small;
        return MinimalPressable(
          onPressed: enabled ? anchor.toggle : null,
          enabled: enabled,
          shape: shape,
          semanticLabel: label == null ? text : '$label, $text',
          child: Container(
            // As tall as every field, grown with its words.
            height: minimalGrownHeight(
              context,
              t.density.height(MinimalChromeMetrics.control),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: MinimalFieldMetrics.inset,
            ),
            decoration: minimalFrame(
              shape,
              fill: enabled ? t.card : t.sunken,
              side: BorderSide(
                color: anchor.isOpen ? t.ring : t.border,
                width: t.rim,
              ),
            ),
            child: Row(
              children: [
                MinimalIcon(
                  LucideIcons.calendarRange,
                  size: MinimalIconSize.i16,
                  color: t.textTertiary,
                ),
                const MinimalGap(MinimalSpacing.s8),
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      text,
                      // The dates are figures, in mono; the prompt is words,
                      // in every field's placeholder face.
                      style: value == null
                          ? t.body.c(t.textTertiary)
                          : t.monoValue.c(t.foreground),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                MinimalIcon(
                  LucideIcons.chevronDown,
                  size: MinimalIconSize.i16,
                  color: t.textTertiary,
                ),
              ],
            ),
          ),
        );
      },
      overlayBuilder: (context, info) {
        final controller = _open ??= _make();
        final months =
            info.maxSize.width >=
                2 * _monthWidth + _monthGap + 2 * MinimalSpacing.s16
            ? 2
            : 1;
        return minimalKitPresence(
          context,
          info,
          MinimalKitPanel(
            padding: const EdgeInsets.all(MinimalSpacing.s8),
            child: _Grid(
              controller: controller,
              months: months,
              firstWeekday: widget.firstWeekday,
              autofocus: true,
              onChanged: (_) {
                final r = controller.selectedRange;
                if (r != null && r.isComplete) {
                  widget.onChanged?.call(r);
                  info.close();
                }
              },
            ),
          ),
        );
      },
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null) ...[
          ExcludeSemantics(
            child: Text(label, style: t.caption.medium.c(t.foreground)),
          ),
          const MinimalGap(MinimalChromeMetrics.iconGap),
        ],
        MinimalHitTarget(child: overlay),
      ],
    );
  }
}
