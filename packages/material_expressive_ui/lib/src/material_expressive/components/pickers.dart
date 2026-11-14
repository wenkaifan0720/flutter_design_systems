/// Pickers: the date picker (calendar, input, docked, range, and its modal
/// dialog), the time picker (dial, input, vibrant, scroll, and its dialogs)
/// and the number scroll field (CONTRACT §4.1 `date-picker`, `time-picker`,
/// and the "number scroll field" extra). Owner: w3-pickers.
///
/// Ports of Compose material3 1.5.0-alpha29 (wave decision F1):
///
/// - [ExpressiveDatePicker] is `DatePicker` (`DatePicker.kt`):
///   `DateEntryContainer`'s header (title, headline, the mode toggle, the
///   divider), `DatePickerContent`'s month navigation (the year menu button
///   and the two arrows), the weekday letters, the horizontally paged months
///   (`HorizontalMonthsList`, six 48dp rows of 40dp days) and the year grid
///   (`YearPicker`, three 72 × 36dp years a row) revealed over them; in input
///   mode `DateInputContent` (`DateInput.kt`), an outlined field that
///   validates as it is typed. Geometry and colours are
///   `DatePickerModalTokens` and `DatePickerDefaults.colors()`; the constants
///   Compose writes in code are `DatePickerBehavior` / `DateInputBehavior`.
/// - [ExpressiveDateRangePicker] is `DateRangePicker` (`DateRangePicker.kt`):
///   a vertical list of months under month subheads, the selected span drawn
///   behind the days (`drawRangeBackground`, line for line), and
///   `DateRangeInputContent`'s two fields.
/// - [ExpressiveDockedDatePicker] is the Compose docked sample: an outlined,
///   read-only field whose calendar button raises a `DatePicker` without its
///   header in a popover below it.
/// - [ExpressiveDatePickerDialog] is `DatePickerDialog`
///   (`DatePickerDialog.android.kt`): 360dp wide at most 568dp tall, the
///   picker over the dismiss and confirm text buttons.
///   [showExpressiveDatePicker] and [showExpressiveDateRangePicker] raise it
///   and resolve to the confirmed selection (a draft until then).
/// - [ExpressiveTimePicker] is `TimePicker` (`TimePicker.kt`): the hour and
///   minute selectors, the AM/PM toggle (the updated `ToggleButton` toggle,
///   `ComposeMaterial3Flags.isUpdatedTimepickerToggleEnabled`), and the
///   256dp clock dial (`ClockFace`), its selector springing to the value,
///   its numbers crossfading between hours and minutes; `vibrant` is the
///   `TimePicker(shapes = …)` overload with `vibrantColors()`.
///   [ExpressiveTimeInput] is `TimeInput`, [ExpressiveTimeScroll] is
///   `TimeScroll` on [ExpressiveScrollField] (`ScrollField.kt`).
/// - [ExpressiveTimePickerDialog] is `TimePickerDialog` and
///   `VibrantTimePickerDialog` (`TimePickerDialog.kt`), portrait layout;
///   [showExpressiveTimePicker] raises it.
///
/// Every value a picker prints goes through the design kit's formatter
/// (`ExpressiveFormat`): English, day first ("12 Mar 2031"), deterministic.
///
/// Deviations from Compose, recorded for the oracle:
/// - Words are the kit's English and our own phrasing, not Compose's
///   localized strings; the weekday letters are the first letter of the
///   kit's weekday names; the headline is `ExpressiveFormat.date`, not the
///   locale's `yMMMd`; the week starts on
///   [ExpressiveDatePicker.firstDayOfWeek], else the locale's
///   ([ExpressiveLocalizations.firstDayOfWeek]: Sunday in English, as
///   Compose's en-US locale).
/// - The mode switch fades and slides the incoming content in on Compose's
///   springs, but the outgoing content leaves at once and the height snaps
///   (Compose's `AnimatedContent` also cross-fades out and animates size).
/// - Months page with a `PageView` snapping on the default effects spring
///   (Compose snaps its `LazyRow` on the same spring); the arrows spring the
///   page on the default spatial spring. Keyboard focus moves between days
///   by the platform's directional traversal, not `dayOnKeyEvent`'s month
///   hops.
/// - The time dialogs lay out in portrait only (Compose switches to a
///   landscape layout on short, wide windows); the picker itself takes
///   [ExpressiveTimePickerLayout.horizontal].
/// - Symbols: the bundled Material Symbols subset has no `date_range` or
///   `swipe_vertical`; the calendar toggle is `calendar_month` and the
///   scroll toggle `unfold_more`.
library;

import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart'
    show Material, MaterialType, TextField;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../component_themes.dart';
import '../internal/cap_label.dart';
import '../internal/focus_ring.dart';
import '../internal/styled_content.dart';
import '../internal/state_face.dart';
import '../elevation.dart';
import '../format.dart';
import '../icons.dart';
import '../internal/tokens/behavior.g.dart';
import '../internal/tokens/button_small_tokens.g.dart';
import '../internal/tokens/date_picker_modal_tokens.g.dart';
import '../internal/tokens/dialog_tokens.g.dart';
import '../internal/tokens/divider_tokens.g.dart';
import '../internal/tokens/keys.g.dart';
import '../internal/tokens/outlined_text_field_tokens.g.dart';
import '../internal/tokens/time_input_tokens.g.dart';
import '../internal/tokens/time_picker_tokens.g.dart';
import '../motion.dart';
import '../shape.dart';
import '../spacing.dart';
import '../states.dart';
import '../strings.dart';
import '../theme.dart';
import 'buttons.dart';
import 'icon_buttons.dart';
import 'menus.dart';
import 'overlays.dart';
import 'text_fields.dart';

// ---------------------------------------------------------------------------
// The calendar.

/// [d] as a day, midnight local.
DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

/// Days in [month] of [year].
int _daysIn(int year, int month) => DateTime(year, month + 1, 0).day;

/// Cells before the first of the month in a week starting on
/// [firstDayOfWeek] (`CalendarMonth.daysFromStartOfWeekToFirstOfMonth`).
int _leadingCells(int year, int month, int firstDayOfWeek) =>
    (DateTime(year, month).weekday - firstDayOfWeek + DateTime.daysPerWeek) %
    DateTime.daysPerWeek;

/// "March 2031": the year menu button's and the range list's month.
String _monthYear(DateTime month) =>
    '${ExpressiveFormat.month(month, short: false)} ${month.year}';

/// "Thursday, 12 March 2031": what a screen reader reads for a day.
String _spokenDay(DateTime d) =>
    '${ExpressiveFormat.weekday(d, short: false)}, ${d.day} '
    '${ExpressiveFormat.month(d, short: false)} ${d.year}';

/// "03/12/2031": a date as the input field holds it.
String _inputText(DateTime d) =>
    '${_two(d.month)}/${_two(d.day)}/${d.year.toString().padLeft(4, '0')}';

String _two(int v) => v.toString().padLeft(2, '0');

/// Which days a picker lets the user choose (Compose's `SelectableDates`
/// with the bounds the caller gives).
@immutable
class _Selectable {
  const _Selectable({
    required this.firstYear,
    required this.lastYear,
    this.firstDate,
    this.lastDate,
    this.predicate,
  });

  final int firstYear;
  final int lastYear;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final bool Function(DateTime day)? predicate;

  bool year(int y) =>
      y >= firstYear &&
      y <= lastYear &&
      (firstDate == null || y >= firstDate!.year) &&
      (lastDate == null || y <= lastDate!.year);

  bool day(DateTime d) {
    if (!year(d.year)) return false;
    if (firstDate != null && d.isBefore(_dayOf(firstDate!))) return false;
    if (lastDate != null && d.isAfter(_dayOf(lastDate!))) return false;
    return predicate?.call(d) ?? true;
  }

  int get monthCount => (lastYear - firstYear + 1) * DateTime.monthsPerYear;

  int indexOf(DateTime month) =>
      ((month.year - firstYear) * DateTime.monthsPerYear + month.month - 1)
          .clamp(0, monthCount - 1);

  DateTime monthAt(int index) => DateTime(
    firstYear + index ~/ DateTime.monthsPerYear,
    index % DateTime.monthsPerYear + 1,
  );
}

_Selectable _selectableOf({
  int? firstYear,
  int? lastYear,
  DateTime? firstDate,
  DateTime? lastDate,
  bool Function(DateTime day)? predicate,
}) => _Selectable(
  firstYear: firstYear ?? DatePickerBehavior.firstYear.toInt(),
  lastYear: lastYear ?? DatePickerBehavior.lastYear.toInt(),
  firstDate: firstDate,
  lastDate: lastDate,
  predicate: predicate,
);

// ---------------------------------------------------------------------------
// Colours.

/// Compose's `DatePickerDefaults.colors()`, resolved.
@immutable
class _DateColors {
  _DateColors.of(ExpressiveThemeData t)
    : container = t.colors.role(DatePickerModalTokens.containerColor),
      title = t.colors.role(DatePickerModalTokens.headerSupportingTextColor),
      headline = t.colors.role(DatePickerModalTokens.headerHeadlineColor),
      weekday = t.colors.role(DatePickerModalTokens.weekdaysLabelTextColor),
      subhead = t.colors.role(
        DatePickerModalTokens.rangeSelectionMonthSubheadColor,
      ),
      navigation = t.colors.onSurfaceVariant,
      year = t.colors.role(
        DatePickerModalTokens.selectionYearUnselectedLabelTextColor,
      ),
      currentYear = t.colors.role(
        DatePickerModalTokens.dateTodayLabelTextColor,
      ),
      selectedYear = t.colors.role(
        DatePickerModalTokens.selectionYearSelectedLabelTextColor,
      ),
      selectedYearContainer = t.colors.role(
        DatePickerModalTokens.selectionYearSelectedContainerColor,
      ),
      day = t.colors.role(DatePickerModalTokens.dateUnselectedLabelTextColor),
      selectedDay = t.colors.role(
        DatePickerModalTokens.dateSelectedLabelTextColor,
      ),
      selectedDayContainer = t.colors.role(
        DatePickerModalTokens.dateSelectedContainerColor,
      ),
      today = t.colors.role(DatePickerModalTokens.dateTodayLabelTextColor),
      todayBorder = t.colors.role(
        DatePickerModalTokens.dateTodayContainerOutlineColor,
      ),
      inRange = t.colors.role(
        DatePickerModalTokens.selectionDateInRangeLabelTextColor,
      ),
      rangeContainer = t.colors.role(
        DatePickerModalTokens.rangeSelectionActiveIndicatorContainerColor,
      ),
      divider = t.colors.role(DividerTokens.color);

  final Color container;
  final Color title;
  final Color headline;
  final Color weekday;
  final Color subhead;
  final Color navigation;
  final Color year;
  final Color currentYear;
  final Color selectedYear;
  final Color selectedYearContainer;
  final Color day;
  final Color selectedDay;
  final Color selectedDayContainer;
  final Color today;
  final Color todayBorder;
  final Color inRange;
  final Color rangeContainer;
  final Color divider;

  static Color faded(Color c) =>
      c.withValues(alpha: c.a * DatePickerBehavior.disabledAlpha);

  /// `DatePickerColors.dayContentColor`.
  Color dayContent({
    required bool today,
    required bool selected,
    required bool inRange,
    required bool enabled,
  }) => switch ((selected, inRange, today)) {
    (true, _, _) => enabled ? selectedDay : faded(selectedDay),
    (false, true, _) => enabled ? this.inRange : faded(day),
    (false, false, true) => enabled ? this.today : faded(day),
    _ => enabled ? day : faded(day),
  };

  /// `DatePickerColors.dayContainerColor`.
  Color dayContainer({required bool selected, required bool enabled}) =>
      selected
      ? (enabled ? selectedDayContainer : faded(selectedDayContainer))
      : selectedDayContainer.withValues(alpha: 0);

  /// `DatePickerColors.yearContentColor`.
  Color yearContent({
    required bool current,
    required bool selected,
    required bool enabled,
  }) => switch ((selected, current)) {
    (true, _) => enabled ? selectedYear : faded(selectedYear),
    (false, true) => enabled ? currentYear : faded(year),
    _ => enabled ? year : faded(year),
  };

  /// `DatePickerColors.yearContainerColor`.
  Color yearContainer({required bool selected, required bool enabled}) =>
      selected
      ? (enabled ? selectedYearContainer : faded(selectedYearContainer))
      : selectedYearContainer.withValues(alpha: 0);
}

// ---------------------------------------------------------------------------
// Spring scrolling.

/// Springs [position] to [target] on [spring]: a ballistic activity driven
/// by the spring's simulation, never a duration (wave decision F10).
void _springScroll(
  ScrollPosition position,
  double target,
  SpringDescription spring,
) {
  if (position is! ScrollPositionWithSingleContext) {
    position.jumpTo(target);
    return;
  }
  position.beginActivity(
    BallisticScrollActivity(
      position,
      designSpringSimulation(spring, from: position.pixels, to: target),
      position.context.vsync,
      true,
    ),
  );
}

/// A page view's snapping, on a motion key's spring rather than the
/// framework's default.
class _SpringPagePhysics extends PageScrollPhysics {
  const _SpringPagePhysics(this._spring, {super.parent});

  final SpringDescription _spring;

  @override
  SpringDescription get spring => _spring;

  @override
  _SpringPagePhysics applyTo(ScrollPhysics? ancestor) =>
      _SpringPagePhysics(_spring, parent: buildParent(ancestor));
}

/// Springs the pages of [controller] to [page] on [key]'s spring.
void _springToPage(
  BuildContext context,
  PageController controller,
  int page,
  ExpressiveMotionKey key,
) {
  if (!controller.hasClients) return;
  final position = controller.position;
  final extent = position.viewportDimension * controller.viewportFraction;
  final current = controller.page ?? page.toDouble();
  final target = position.pixels + (page - current) * extent;
  _springScroll(position, target, ExpressiveMotion.of(context).spring(key));
}

// ---------------------------------------------------------------------------
// The date picker.

/// Which face a date picker shows (Compose's `DisplayMode`).
enum ExpressiveDatePickerMode {
  /// The calendar.
  picker,

  /// The typed field.
  input,
}

/// Compose's `DatePicker`: a header (the [title], the headline showing the
/// selected date, the mode toggle), then the calendar — month navigation,
/// the weekday letters and the paged months, with the year grid behind the
/// month button — or, in [ExpressiveDatePickerMode.input], an outlined
/// field that takes MM/DD/YYYY.
///
/// [selected] is the chosen day; a tap on an enabled day (or a valid typed
/// date) calls [onChanged]. Days before [firstDate], after [lastDate], or
/// refused by [selectableDay] are disabled; the calendar spans [firstYear]
/// to [lastYear] (1900–2100 by default, `DatePickerDefaults.YearRange`).
/// [today] is outlined (the current day when null).
///
/// Laid out in place it is the picker alone on its container colour; raise
/// it in a dialog with [showExpressiveDatePicker], or dock it under a field
/// with [ExpressiveDockedDatePicker]. [showHeader] false drops the header
/// and the toggle (the docked form).
class ExpressiveDatePicker extends StatefulWidget {
  /// A date picker with [selected] chosen, reporting a choice through [onChanged].
  const ExpressiveDatePicker({
    this.style,
    this.selected,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.firstYear,
    this.lastYear,
    this.initialMonth,
    this.initialMode = ExpressiveDatePickerMode.picker,
    this.onModeChanged,
    this.title,
    this.headline,
    this.showHeader = true,
    this.showModeToggle = true,
    this.currentDate,
    this.firstDayOfWeek,
    super.key,
  });

  /// The chosen day, or none.
  final DateTime? selected;

  /// Called with the day the user chooses.
  final ValueChanged<DateTime>? onChanged;

  /// The first day that can be chosen, if any.
  final DateTime? firstDate;

  /// The last day that can be chosen, if any.
  final DateTime? lastDate;

  /// Refuses days beyond the bounds (a closed weekday, a booked night).
  final bool Function(DateTime day)? selectableDayPredicate;

  /// The calendar's first year; 1900 when null.
  final int? firstYear;

  /// The calendar's last year; 2100 when null.
  final int? lastYear;

  /// The month shown first; [selected]'s (or [currentDate]'s) when null.
  final DateTime? initialMonth;

  /// The face shown first.
  final ExpressiveDatePickerMode initialMode;

  /// Called when the user switches faces.
  final ValueChanged<ExpressiveDatePickerMode>? onModeChanged;

  /// The header's title; "Select date" ("Enter date" typing) when null.
  final String? title;

  /// The header's headline; the selected date (or "Selected date") when
  /// null.
  final String? headline;

  /// Whether the header (title, headline, toggle, divider) shows.
  final bool showHeader;

  /// Whether the header's mode toggle shows.
  final bool showModeToggle;

  /// The day outlined as today; the current day when null.
  final DateTime? currentDate;

  /// The weekday the calendar's weeks start on ([DateTime.monday] …
  /// [DateTime.sunday]); the locale's
  /// ([ExpressiveLocalizations.firstDayOfWeek]) when null.
  final int? firstDayOfWeek;

  /// Stateful visual overrides for the date picker.
  final ExpressiveComponentThemeData? style;

  @override
  State<ExpressiveDatePicker> createState() => _ExpressiveDatePickerState();
}

class _ExpressiveDatePickerState extends State<ExpressiveDatePicker> {
  late ExpressiveDatePickerMode _mode = widget.initialMode;
  late DateTime _month = _initialMonth();

  DateTime _initialMonth() {
    final d = widget.initialMonth ?? widget.selected ?? _today;
    return DateTime(d.year, d.month);
  }

  DateTime get _today => _dayOf(widget.currentDate ?? DateTime.now());

  void _setMode(ExpressiveDatePickerMode mode) {
    setState(() {
      // Compose's `displayMode` setter: back on the calendar, show the
      // selected day's month.
      final s = widget.selected;
      if (s != null) _month = DateTime(s.year, s.month);
      _mode = mode;
    });
    widget.onModeChanged?.call(mode);
  }

  @override
  Widget build(BuildContext context) => ExpressiveTheme(
    data: context.expressiveTheme.copyWith(
      datePickerTheme: context.expressiveTheme.datePickerTheme.merge(
        widget.style,
      ),
    ),
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = _DateColors.of(t);
    final selectable = _selectableOf(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      predicate: widget.selectableDayPredicate,
    );
    final typing = _mode == ExpressiveDatePickerMode.input;
    final selected = widget.selected;
    final headline =
        widget.headline ??
        (selected != null
            ? ExpressiveFormat.date(selected)
            : typing
            ? ExpressiveLocalizations.of(context).enteredDate
            : ExpressiveLocalizations.of(context).selectedDate);
    final spoken = selected != null
        ? '${typing ? ExpressiveLocalizations.of(context).enteredDate : ExpressiveLocalizations.of(context).selectedDate}: '
              '${_spokenDay(selected)}'
        : headline;
    return _DateEntryContainer(
      colors: colors,
      title: widget.showHeader
          ? _HeaderTitle(
              // Android's `m3c_date_input_title` reads as the picker's title.
              widget.title ?? ExpressiveLocalizations.of(context).selectDate,
              colors: colors,
              range: false,
            )
          : null,
      headline: widget.showHeader
          ? _HeaderHeadline(
              spoken: spoken,
              colors: colors,
              style: t.type.of(DatePickerModalTokens.headerHeadlineFont),
              range: false,
              child: Text(headline),
            )
          : null,
      modeToggle: widget.showHeader && widget.showModeToggle
          ? _ModeToggle(mode: _mode, onChanged: _setMode)
          : null,
      headerMinHeight: DatePickerModalTokens.headerContainerHeight,
      child: _ModeSwitch(
        mode: _mode,
        child: switch (_mode) {
          ExpressiveDatePickerMode.picker => _CalendarContent(
            month: _month,
            selected: selected,
            onChanged: widget.onChanged,
            onMonthChanged: (m) => _month = m,
            selectable: selectable,
            today: _today,
            firstDayOfWeek:
                widget.firstDayOfWeek ??
                ExpressiveLocalizations.of(context).firstDayOfWeek,
            colors: colors,
          ),
          ExpressiveDatePickerMode.input => _DateInputContent(
            selected: selected,
            onChanged: widget.onChanged,
            selectable: selectable,
          ),
        },
      ),
    );
  }
}

/// `DateEntryContainer`: the header over the content, on the container
/// colour, at least `DatePickerModalTokens.containerWidth` wide where the
/// parent leaves room (Compose's `sizeIn(minWidth)`).
class _DateEntryContainer extends StatelessWidget {
  const _DateEntryContainer({
    required this.colors,
    required this.title,
    required this.headline,
    required this.modeToggle,
    required this.headerMinHeight,
    required this.child,
  });

  final _DateColors colors;
  final Widget? title;
  final Widget? headline;
  final Widget? modeToggle;
  final double headerMinHeight;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasHeader = title != null || headline != null || modeToggle != null;
    final header = hasHeader
        ? ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: title != null ? headerMinHeight : 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (title != null)
                  Align(
                    alignment: AlignmentDirectional.bottomStart,
                    child: title,
                  ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    // DateEntryContainer provides the headline colour as
                    // LocalContentColor to the headline row, so the mode
                    // toggle's icon wears it.
                    IconTheme.merge(
                      data: IconThemeData(color: colors.headline),
                      child: Row(
                        children: <Widget>[
                          if (headline != null)
                            Expanded(child: headline!)
                          else
                            const Spacer(),
                          ?modeToggle,
                        ],
                      ),
                    ),
                    _Divider(color: colors.divider),
                  ],
                ),
              ],
            ),
          )
        : null;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: DatePickerModalTokens.containerWidth,
      ),
      child: ExpressiveSurface(
        componentStyle: context.expressiveTheme.datePickerTheme,
        shape: context.expressiveTheme.shapes.none,
        clipBehavior: _pickerPlateClip(
          context,
          context.expressiveTheme.datePickerTheme,
        ),
        color: colors.container,
        child: _PickerViewport(
          naturalWidth: DatePickerModalTokens.containerWidth,
          minimumWidth: DatePickerBehavior.cellSize * DateTime.daysPerWeek,
          naturalHeight: DatePickerModalTokens.containerHeight,
          child: Semantics(
            container: true,
            explicitChildNodes: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ?header,
                Flexible(child: child),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// `HorizontalDivider`: a hairline in [color].
class _Divider extends StatelessWidget {
  const _Divider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: DividerTokens.thickness,
    child: ColoredBox(color: color),
  );
}

/// `DatePickerDefaults.DatePickerTitle` in its padding.
class _HeaderTitle extends StatelessWidget {
  const _HeaderTitle(this.text, {required this.colors, required this.range});

  final String text;
  final _DateColors colors;
  final bool range;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: range
            ? DateRangePickerBehavior.titlePaddingStart
            : DatePickerBehavior.titlePaddingStart,
        end: DatePickerBehavior.titlePaddingEnd,
        top: range ? 0 : DatePickerBehavior.titlePaddingTop,
      ),
      child: Text(
        text,
        style: t.type
            .of(DatePickerModalTokens.headerSupportingTextFont)
            .merge(t.datePickerTheme.textStyle?.resolve(const <WidgetState>{}))
            .copyWith(
              color:
                  t.datePickerTheme.foregroundColor?.resolve(
                    const <WidgetState>{},
                  ) ??
                  colors.title,
            ),
      ),
    );
  }
}

/// `DatePickerDefaults.DatePickerHeadline` in its padding: one line,
/// announced politely as it changes.
class _HeaderHeadline extends StatelessWidget {
  const _HeaderHeadline({
    required this.spoken,
    required this.colors,
    required this.style,
    required this.range,
    required this.child,
  });

  final String spoken;
  final _DateColors colors;
  final TextStyle style;
  final bool range;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsetsDirectional.only(
      start: range
          ? DateRangePickerBehavior.titlePaddingStart
          : DatePickerBehavior.titlePaddingStart,
      end: DatePickerBehavior.titlePaddingEnd,
      bottom: DatePickerBehavior.headlinePaddingBottom,
    ),
    child: Semantics(
      liveRegion: true,
      label: spoken,
      excludeSemantics: true,
      // The single date's headline is one line (`maxLines = 1`); the
      // range's texts wrap, and the header grows with them — up to
      // [maxRangeTextScale]: past it the two dates would push the calendar
      // off a phone, so the range's headline stops growing there, as
      // Material's date range picker caps its header.
      child: DefaultTextStyle(
        style: style
            .merge(
              context.expressiveTheme.datePickerTheme.textStyle?.resolve(
                const <WidgetState>{},
              ),
            )
            .copyWith(
              color:
                  context.expressiveTheme.datePickerTheme.foregroundColor
                      ?.resolve(const <WidgetState>{}) ??
                  colors.headline,
            ),
        maxLines: range ? null : 1,
        overflow: range ? TextOverflow.clip : TextOverflow.ellipsis,
        child: range
            ? MediaQuery.withClampedTextScaling(
                maxScaleFactor: maxRangeTextScale,
                child: child,
              )
            : child,
      ),
    ),
  );

  /// The largest text scale the range headline takes (Material's
  /// `_kMaxRangeTextScaleFactor`, 1.3).
  static const double maxRangeTextScale = 1.3;
}

/// `DateRangePickerHeadline`'s row: start, a dash and end, spaced and
/// centred vertically. Where the two dates don't fit on one line, the end
/// date moves whole to the next line (the dash stays with the start), so a
/// date never breaks inside ("19 Sep / 2026"); a date wider than a whole
/// line still wraps rather than ellipsizing.
class _RangeHeadlineRow extends StatelessWidget {
  const _RangeHeadlineRow({required this.start, required this.end});

  final String start;
  final String end;

  static const String _dash = '-';

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: DateRangePickerBehavior.headlineSpacing,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Flexible(child: Text(start)),
          const SizedBox(width: DateRangePickerBehavior.headlineSpacing),
          const Text(_dash),
        ],
      ),
      Text(end),
    ],
  );
}

/// `DisplayModeToggleButton`: an icon button switching the face.
class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final ExpressiveDatePickerMode mode;
  final ValueChanged<ExpressiveDatePickerMode> onChanged;

  @override
  Widget build(BuildContext context) {
    final toInput = mode == ExpressiveDatePickerMode.picker;
    final label = toInput
        ? ExpressiveLocalizations.of(context).toDateInput
        : ExpressiveLocalizations.of(context).toCalendar;
    return Padding(
      padding: const EdgeInsetsDirectional.only(
        end: DatePickerBehavior.modeTogglePaddingEnd,
        bottom: DatePickerBehavior.modeTogglePaddingBottom,
      ),
      child: ExpressiveIconButton(
        toInput ? ExpressiveSymbols.edit : ExpressiveSymbols.calendarMonth,
        semanticLabel: label,
        tooltip: label,
        onPressed: () => onChanged(
          toInput
              ? ExpressiveDatePickerMode.input
              : ExpressiveDatePickerMode.picker,
        ),
      ),
    );
  }
}

/// `SwitchableDateEntryContent`'s transition, incoming half: the new face
/// fades in on the default effects spring as it slides in on the default
/// spatial spring — from below into input, from the parallax offset above
/// back into the calendar.
class _ModeSwitch extends StatefulWidget {
  const _ModeSwitch({required this.mode, required this.child});

  final ExpressiveDatePickerMode mode;
  final Widget child;

  @override
  State<_ModeSwitch> createState() => _ModeSwitchState();
}

class _ModeSwitchState extends State<_ModeSwitch>
    with TickerProviderStateMixin {
  late final AnimationController _fade = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late final AnimationController _slide = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  bool _fromBelow = true;

  @override
  void didUpdateWidget(_ModeSwitch old) {
    super.didUpdateWidget(old);
    if (old.mode == widget.mode) return;
    final motion = ExpressiveMotion.of(context);
    _fromBelow = widget.mode == ExpressiveDatePickerMode.input;
    _fade
      ..value = 0
      ..springTo(1, motion.defaultEffects);
    _slide
      ..value = 0
      ..springTo(1, motion.defaultSpatial);
  }

  @override
  void dispose() {
    _fade.dispose();
    _slide.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ClipRect(
    child: AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[_fade, _slide]),
      child: KeyedSubtree(
        key: ValueKey<ExpressiveDatePickerMode>(widget.mode),
        child: widget.child,
      ),
      builder: (context, child) {
        final remaining = 1 - _slide.value;
        final dy = _fromBelow
            ? remaining * DatePickerBehavior.modeParallax
            : -remaining * DatePickerBehavior.modeParallax;
        return Opacity(
          opacity: _fade.value.clamp(0.0, 1.0),
          child: Transform.translate(offset: Offset(0, dy), child: child),
        );
      },
    ),
  );
}

/// `DatePickerContent`: the month navigation, the weekdays and the paged
/// months, with the year grid revealed over them.
class _CalendarContent extends StatefulWidget {
  const _CalendarContent({
    required this.month,
    required this.selected,
    required this.onChanged,
    required this.onMonthChanged,
    required this.selectable,
    required this.today,
    required this.firstDayOfWeek,
    required this.colors,
  });

  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime>? onChanged;
  final ValueChanged<DateTime> onMonthChanged;
  final _Selectable selectable;
  final DateTime today;
  final int firstDayOfWeek;
  final _DateColors colors;

  @override
  State<_CalendarContent> createState() => _CalendarContentState();
}

class _CalendarContentState extends State<_CalendarContent> {
  late int _index = widget.selectable.indexOf(widget.month);
  late final PageController _pages = PageController(initialPage: _index);
  bool _years = false;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _onPage(int index) {
    setState(() => _index = index);
    widget.onMonthChanged(widget.selectable.monthAt(index));
  }

  void _step(int by) => _springToPage(
    context,
    _pages,
    (_index + by).clamp(0, widget.selectable.monthCount - 1),
    ExpressiveMotionKey.defaultSpatial,
  );

  void _pickYear(int year) {
    final month = widget.selectable.monthAt(_index).month;
    final index = widget.selectable.indexOf(DateTime(year, month));
    setState(() {
      _years = false;
      _index = index;
    });
    _pages.jumpToPage(index);
    widget.onMonthChanged(widget.selectable.monthAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    final selectable = widget.selectable;
    final month = selectable.monthAt(_index);
    final motion = ExpressiveMotion.of(context);
    const calendarHeight =
        DatePickerBehavior.cellSize * DatePickerBehavior.maxCalendarRows;
    final calendar = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DatePickerBehavior.horizontalPadding,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _WeekDays(firstDayOfWeek: widget.firstDayOfWeek, colors: colors),
          // A whole-pixel page: two thousand fractional pages add up past
          // the sliver's precision.
          LayoutBuilder(
            builder: (context, constraints) => Center(
              child: SizedBox(
                width: constraints.maxWidth.floorToDouble(),
                height: calendarHeight,
                child: PageView.builder(
                  controller: _pages,
                  physics: _SpringPagePhysics(motion.defaultEffects),
                  onPageChanged: _onPage,
                  itemCount: selectable.monthCount,
                  itemBuilder: (context, index) => _Month(
                    month: selectable.monthAt(index),
                    selected: widget.selected,
                    onChanged: widget.onChanged,
                    selectable: selectable,
                    today: widget.today,
                    firstDayOfWeek: widget.firstDayOfWeek,
                    colors: colors,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MonthsNavigation(
          label: _monthYear(month),
          yearsOpen: _years,
          previous: _index > 0 ? () => _step(-1) : null,
          next: _index < selectable.monthCount - 1 ? () => _step(1) : null,
          onYears: () => setState(() => _years = !_years),
          colors: colors,
        ),
        Stack(
          children: <Widget>[
            ExcludeSemantics(excluding: _years, child: calendar),
            Positioned.fill(
              child: _Reveal(
                open: _years,
                child: Column(
                  children: <Widget>[
                    Expanded(
                      child: _YearPicker(
                        displayedYear: month.year,
                        currentYear: widget.today.year,
                        selectable: selectable,
                        colors: colors,
                        onYear: _pickYear,
                      ),
                    ),
                    _Divider(color: colors.divider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// `AnimatedVisibility(expandVertically + fadeIn(0.6), shrinkVertically +
/// fadeOut)` for the year grid: it grows down from its top on the default
/// effects spring as it fades from 0.6 in (default effects) or out (fast
/// effects).
class _Reveal extends StatefulWidget {
  const _Reveal({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_Reveal> createState() => _RevealState();
}

class _RevealState extends State<_Reveal> with TickerProviderStateMixin {
  late final AnimationController _size = AnimationController.unbounded(
    vsync: this,
    value: widget.open ? 1 : 0,
  );
  late final AnimationController _fade = AnimationController.unbounded(
    vsync: this,
    value: widget.open ? 1 : 0,
  );

  @override
  void didUpdateWidget(_Reveal old) {
    super.didUpdateWidget(old);
    if (old.open == widget.open) return;
    final motion = ExpressiveMotion.of(context);
    _size.springTo(widget.open ? 1 : 0, motion.defaultEffects);
    if (widget.open) {
      _fade
        ..value = DatePickerBehavior.yearsFadeInAlpha
        ..springTo(1, motion.defaultEffects);
    } else {
      _fade.springTo(0, motion.fastEffects);
    }
  }

  @override
  void dispose() {
    _size.dispose();
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: Listenable.merge(<Listenable>[_size, _fade]),
    child: widget.child,
    builder: (context, child) {
      final size = _size.value.clamp(0.0, 1.0);
      if (size <= 0 && !widget.open) return const SizedBox.shrink();
      return ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: size,
          child: Opacity(opacity: _fade.value.clamp(0.0, 1.0), child: child),
        ),
      );
    },
  );
}

/// `MonthsNavigation`: the year menu button, then (unless the years are
/// open) the previous and next arrows.
class _MonthsNavigation extends StatelessWidget {
  const _MonthsNavigation({
    required this.label,
    required this.yearsOpen,
    required this.previous,
    required this.next,
    required this.onYears,
    required this.colors,
  });

  final String label;
  final bool yearsOpen;
  final VoidCallback? previous;
  final VoidCallback? next;
  final VoidCallback onYears;
  final _DateColors colors;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: DatePickerBehavior.horizontalPadding,
    ),
    child: SizedBox(
      height: DatePickerBehavior.monthYearHeight,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Flexible(
            child: _YearMenuButton(
              label: label,
              expanded: yearsOpen,
              color: colors.navigation,
              onTap: onYears,
            ),
          ),
          if (!yearsOpen)
            // CompositionLocalProvider(LocalContentColor provides
            // navigationContentColor) around the arrows.
            IconTheme.merge(
              data: IconThemeData(color: colors.navigation),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpressiveIconButton(
                    _monthBack(context),
                    onPressed: previous,
                    semanticLabel: ExpressiveLocalizations.of(context)
                        .previousMonth,
                    tooltip: ExpressiveLocalizations.of(context).previousMonth,
                  ),
                  ExpressiveIconButton(
                    _monthOn(context),
                    onPressed: next,
                    semanticLabel: ExpressiveLocalizations.of(context)
                        .nextMonth,
                    tooltip: ExpressiveLocalizations.of(context).nextMonth,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}

/// `YearPickerMenuButton`: a text button in the ambient content colour, on
/// the full corner, the month and year (in the navigation colour) then the
/// drop-down arrow (turned over while the years are open).
class _YearMenuButton extends StatelessWidget {
  const _YearMenuButton({
    required this.label,
    required this.expanded,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool expanded;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    // textButtonColors(contentColor = LocalContentColor.current): the
    // button (its ripple and the arrow) wears the ambient content colour;
    // only the label is set in the navigation colour.
    final ambient = IconTheme.of(context).color ?? t.colors.onSurface;
    return ExpressivePressable(
      componentStyle: _pickerControlStyle(t.datePickerTheme),
      shapes: ExpressivePressShapes.all(
        t.shapes.of(ExpressiveShapeKey.cornerFull),
      ),
      motion: ButtonBehavior.pressMotion,
      color: ambient.withValues(alpha: 0),
      contentColor: ambient,
      onPressed: onTap,
      semanticLabel:
          '$label, ${expanded ? ExpressiveLocalizations.of(context).toDays : ExpressiveLocalizations.of(context).toYears}',
      child: ExpressiveStyledContent(
        minimumSize: const Size(0, ButtonSmallTokens.containerHeight),
        padding: const EdgeInsets.symmetric(
          horizontal: AlertDialogBehavior.actionHorizontalPadding,
        ),
        textStyle: t.type.labelLarge.copyWith(color: color),
        iconSize: DialogTokens.iconSize,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Flexible(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: ButtonSmallTokens.iconLabelSpace),
            Transform.rotate(
              angle: expanded ? math.pi : 0,
              child: Icon(ExpressiveSymbols.arrowDropDown),
            ),
          ],
        ),
      ),
    );
  }
}

/// `WeekDays`: the weekday letters, one to each seventh of the width (a
/// 48dp cell and its share of the spare width, as `drawRangeBackground`
/// measures the days).
class _WeekDays extends StatelessWidget {
  const _WeekDays({required this.firstDayOfWeek, required this.colors});

  final int firstDayOfWeek;
  final _DateColors colors;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final style = t.type
        .of(DatePickerModalTokens.weekdaysLabelTextFont)
        .merge(t.datePickerTheme.textStyle?.resolve(const <WidgetState>{}))
        .copyWith(
          color:
              t.datePickerTheme.foregroundColor?.resolve(
                const <WidgetState>{},
              ) ??
              colors.weekday,
        );
    // A week from a known Monday (5 January 2026), turned to start on
    // firstDayOfWeek.
    final monday = DateTime(2026, 1, 5);
    return SizedBox(
      height: DatePickerBehavior.cellSize,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          for (var i = 0; i < DateTime.daysPerWeek; i++)
            Builder(
              builder: (context) {
                final day = DateTime(
                  monday.year,
                  monday.month,
                  monday.day +
                      (firstDayOfWeek - DateTime.monday + i) %
                          DateTime.daysPerWeek,
                );
                final name = ExpressiveFormat.weekday(day, short: false);
                return Expanded(
                  child: Semantics(
                    label: name,
                    excludeSemantics: true,
                    child: Center(
                      child: Text(name.substring(0, 1), style: style),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

/// The span a range picker draws behind one month (`SelectedRangeInfo`):
/// grid coordinates of its first and last cells, and whether the span
/// starts and ends inside the month.
@immutable
class _RangeInfo {
  const _RangeInfo(this.start, this.end, this.firstIsStart, this.lastIsEnd);

  final (int, int) start;
  final (int, int) end;
  final bool firstIsStart;
  final bool lastIsEnd;

  /// `SelectedRangeInfo.calculateRangeInfo`.
  static _RangeInfo? of(
    DateTime month,
    DateTime start,
    DateTime end,
    int firstDayOfWeek,
  ) {
    final first = DateTime(month.year, month.month);
    final days = _daysIn(month.year, month.month);
    final last = DateTime(month.year, month.month, days);
    if (start.isAfter(last) || end.isBefore(first)) return null;
    final lead = _leadingCells(month.year, month.month, firstDayOfWeek);
    final firstIsStart = !start.isBefore(first);
    final lastIsEnd = !end.isAfter(last);
    final startCell = firstIsStart ? lead + start.day - 1 : lead;
    final endCell = lastIsEnd ? lead + end.day - 1 : lead + days - 1;
    const week = DateTime.daysPerWeek;
    return _RangeInfo(
      (startCell % week, startCell ~/ week),
      (endCell % week, endCell ~/ week),
      firstIsStart,
      lastIsEnd,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is _RangeInfo &&
      other.start == start &&
      other.end == end &&
      other.firstIsStart == firstIsStart &&
      other.lastIsEnd == lastIsEnd;

  @override
  int get hashCode => Object.hash(start, end, firstIsStart, lastIsEnd);
}

/// `drawRangeBackground`, line for line.
class _RangePainter extends CustomPainter {
  _RangePainter(this.info, this.color, this.textDirection);

  final _RangeInfo info;
  final Color color;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    const week = DateTime.daysPerWeek;
    const cell = DatePickerBehavior.cellSize;
    const layer = DatePickerModalTokens.dateStateLayerHeight;
    const halfCell = cell / 2;
    const pad = (cell - layer) / 2;
    final space = (size.width - week * cell) / week;
    final halfSpace = space / 2;
    final (x1, y1) = info.start;
    final (x2, y2) = info.end;
    var startX =
        x1 * (cell + space) + (info.firstIsStart ? halfCell : 0) + halfSpace;
    final startY = y1 * cell + pad;
    var endX =
        x2 * (cell + space) + (info.lastIsEnd ? halfCell : cell) + halfSpace;
    final endY = y2 * cell + pad;
    final rtl = textDirection == TextDirection.rtl;
    if (rtl) {
      startX = size.width - startX;
      endX = size.width - endX;
    }
    final paint = Paint()..color = color;
    final firstWidth = y1 == y2
        ? endX - startX
        : rtl
        ? -startX
        : size.width - startX;
    canvas.drawRect(Rect.fromLTWH(startX, startY, firstWidth, layer), paint);
    if (y1 != y2) {
      for (var y = y2 - y1 - 1; y >= 1; y--) {
        canvas.drawRect(
          Rect.fromLTWH(0, startY + y * cell, size.width, layer),
          paint,
        );
      }
      final left = rtl ? size.width : 0.0;
      canvas.drawRect(
        Rect.fromLTWH(left, endY, rtl ? endX - size.width : endX, layer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RangePainter old) =>
      old.info != info ||
      old.color != color ||
      old.textDirection != textDirection;
}

/// `Month`: six rows of seven cells, each a seventh of the width (48dp and
/// its share of the spare width; narrower on a narrow window); a day in each
/// cell of the month, empty cells either side. [range] makes it a range month: [selected] and
/// [rangeEnd] both selected and the span drawn behind.
class _Month extends StatelessWidget {
  const _Month({
    required this.month,
    required this.selected,
    required this.onChanged,
    required this.selectable,
    required this.today,
    required this.firstDayOfWeek,
    required this.colors,
    this.range = false,
    this.rangeEnd,
  });

  final DateTime month;
  final DateTime? selected;
  final ValueChanged<DateTime>? onChanged;
  final _Selectable selectable;
  final DateTime today;
  final int firstDayOfWeek;
  final _DateColors colors;
  final bool range;
  final DateTime? rangeEnd;

  @override
  Widget build(BuildContext context) {
    final lead = _leadingCells(month.year, month.month, firstDayOfWeek);
    final days = _daysIn(month.year, month.month);
    final start = selected;
    final end = rangeEnd;
    final info = range && start != null && end != null
        ? _RangeInfo.of(month, start, end, firstDayOfWeek)
        : null;
    Widget cell(int index) {
      if (index < lead || index >= lead + days) {
        return const SizedBox.shrink();
      }
      final date = DateTime(month.year, month.month, index - lead + 1);
      final isStart = _sameDay(date, start);
      final isEnd = _sameDay(date, end);
      final inRange =
          range &&
          start != null &&
          end != null &&
          !date.isBefore(start) &&
          !date.isAfter(end);
      return _Day(
        date: date,
        selected: isStart || isEnd,
        animate: isStart,
        today: _sameDay(date, today),
        inRange: inRange,
        range: range,
        isStart: isStart,
        isEnd: isEnd,
        enabled: onChanged != null && selectable.day(date),
        onTap: () => onChanged?.call(date),
        colors: colors,
      );
    }

    final grid = LayoutBuilder(
      builder: (context, box) {
        // Where seven do not fit, the outer days stand flush with the
        // month's edges, so the pager's clip leaves their whole target.
        final narrow =
            box.maxWidth < DatePickerBehavior.cellSize * DateTime.daysPerWeek;
        AlignmentGeometry align(int d) => !narrow
            ? Alignment.center
            : d == 0
            ? AlignmentDirectional.centerStart
            : d == DateTime.daysPerWeek - 1
            ? AlignmentDirectional.centerEnd
            : Alignment.center;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            for (
              var week = 0;
              week < DatePickerBehavior.maxCalendarRows;
              week++
            )
              SizedBox(
                height: DatePickerBehavior.cellSize,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    // A day keeps its 48dp touch target where seven do not
                    // fit (Compose's overlap): it overhangs its cell.
                    for (var d = 0; d < DateTime.daysPerWeek; d++)
                      Expanded(
                        child: Center(
                          child: OverflowBox(
                            maxWidth: DatePickerBehavior.cellSize,
                            alignment: align(d),
                            child: cell(week * DateTime.daysPerWeek + d),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
    if (info == null) return grid;
    return CustomPaint(
      painter: _RangePainter(
        info,
        colors.rangeContainer,
        Directionality.of(context),
      ),
      child: grid,
    );
  }
}

/// `Day`: a 40dp circle in its 48dp cell — `primary` when selected, an
/// outline for today, its number in the day's colour.
class _Day extends StatelessWidget {
  const _Day({
    required this.date,
    required this.selected,
    required this.animate,
    required this.today,
    required this.inRange,
    required this.range,
    required this.isStart,
    required this.isEnd,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  final DateTime date;
  final bool selected;
  final bool animate;
  final bool today;
  final bool inRange;
  final bool range;
  final bool isStart;
  final bool isEnd;
  final bool enabled;
  final VoidCallback onTap;
  final _DateColors colors;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final container = colors.dayContainer(selected: selected, enabled: enabled);
    final content = colors.dayContent(
      today: today,
      selected: selected,
      inRange: inRange,
      enabled: enabled,
    );
    final spoken = <String>[
      if (range && isStart) ExpressiveLocalizations.of(context).startDate,
      if (range && isEnd) ExpressiveLocalizations.of(context).endDate,
      if (range && inRange && !isStart && !isEnd)
        ExpressiveLocalizations.of(context).inRange,
      if (today) ExpressiveLocalizations.of(context).today,
      _spokenDay(date),
    ].join(', ');
    final style = t.type.of(DatePickerModalTokens.dateLabelTextFont);
    return ExpressivePressable(
      componentStyle: _pickerControlStyle(t.datePickerTheme),
      shapes: ExpressivePressShapes.all(
        t.shapes.of(DatePickerModalTokens.dateContainerShape),
      ),
      motion: ExpressiveMotionKey.defaultSpatial,
      color: container,
      contentColor: content,
      colorMotion: animate ? ExpressiveMotionKey.defaultEffects : null,
      side: today && !selected
          ? BorderSide(
              color: colors.todayBorder,
              width: DatePickerModalTokens.dateTodayContainerOutlineWidth,
            )
          : BorderSide.none,
      role: ExpressivePressRole.tab,
      selected: selected,
      semanticLabel: spoken,
      onPressed: enabled ? onTap : null,
      child: Builder(
        builder: (context) {
          final inset = ExpressiveStyleScope.maybeOf(context)!.inset
              .resolve(Directionality.of(context));
          final custom = inset.horizontal > 0 || inset.vertical > 0;
          return SizedBox.square(
            dimension: custom
                ? DatePickerBehavior.cellSize
                : DatePickerModalTokens.dateContainerWidth,
            child: ExpressiveStyledContent(
              textStyle: style,
              child: ExcludeSemantics(
                child: _PickerLabel(
                  '${date.day}',
                  fitAs: '30',
                  singleLine: false,
                  textAlign: TextAlign.center,
                  shape: custom
                      ? null
                      : t.shapes.of(DatePickerModalTokens.dateContainerShape),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// `YearPicker`: three years a row, 16dp between rows, scrolled so the
/// displayed year sits on the second row.
class _YearPicker extends StatefulWidget {
  const _YearPicker({
    required this.displayedYear,
    required this.currentYear,
    required this.selectable,
    required this.colors,
    required this.onYear,
  });

  final int displayedYear;
  final int currentYear;
  final _Selectable selectable;
  final _DateColors colors;
  final ValueChanged<int> onYear;

  @override
  State<_YearPicker> createState() => _YearPickerState();
}

class _YearPickerState extends State<_YearPicker> {
  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _initialOffset,
  );

  double get _initialOffset {
    final perRow = DatePickerBehavior.yearsInRow.toInt();
    final index = math.max(
      0,
      widget.displayedYear - widget.selectable.firstYear - perRow,
    );
    return (index ~/ perRow) *
        (DatePickerModalTokens.selectionYearContainerHeight +
            DatePickerBehavior.yearsVerticalSpacing);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.selectable;
    return ColoredBox(
      color: widget.colors.container,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: DatePickerBehavior.horizontalPadding,
        ),
        child: GridView.builder(
          controller: _scroll,
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: DatePickerBehavior.yearsInRow.toInt(),
            mainAxisExtent: DatePickerModalTokens.selectionYearContainerHeight,
            mainAxisSpacing: DatePickerBehavior.yearsVerticalSpacing,
          ),
          itemCount: s.lastYear - s.firstYear + 1,
          itemBuilder: (context, i) {
            final year = s.firstYear + i;
            return Center(
              child: _Year(
                year: year,
                selected: year == widget.displayedYear,
                current: year == widget.currentYear,
                enabled: s.year(year),
                colors: widget.colors,
                onTap: () => widget.onYear(year),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// `Year`: a 72 × 36dp year on the full corner, `primary` when displayed,
/// outlined when current.
class _Year extends StatelessWidget {
  const _Year({
    required this.year,
    required this.selected,
    required this.current,
    required this.enabled,
    required this.colors,
    required this.onTap,
  });

  final int year;
  final bool selected;
  final bool current;
  final bool enabled;
  final _DateColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final content = colors.yearContent(
      current: current,
      selected: selected,
      enabled: enabled,
    );
    return ExpressivePressable(
      componentStyle: _pickerControlStyle(t.datePickerTheme),
      shapes: ExpressivePressShapes.all(
        t.shapes.of(DatePickerModalTokens.selectionYearStateLayerShape),
      ),
      motion: ExpressiveMotionKey.defaultSpatial,
      color: colors.yearContainer(selected: selected, enabled: enabled),
      contentColor: content,
      colorMotion: ExpressiveMotionKey.defaultEffects,
      side: current && !selected
          ? BorderSide(
              color: colors.todayBorder,
              width: DatePickerModalTokens.dateTodayContainerOutlineWidth,
            )
          : BorderSide.none,
      role: ExpressivePressRole.tab,
      selected: selected,
      minimumInteractiveSize: false,
      semanticLabel: ExpressiveLocalizations.of(context).goToYear(year),
      onPressed: enabled ? onTap : null,
      child: SizedBox(
        width: DatePickerModalTokens.selectionYearContainerWidth,
        height: DatePickerModalTokens.selectionYearContainerHeight,
        child: ExpressiveStyledContent(
          textStyle: t.type.of(
            DatePickerModalTokens.selectionYearLabelTextFont,
          ),
          child: Builder(
            builder: (context) {
              final inset = ExpressiveStyleScope.maybeOf(context)!.inset
                  .resolve(Directionality.of(context));
              return ExcludeSemantics(
                child: _PickerLabel(
                  '$year',
                  singleLine: false,
                  shape: inset == EdgeInsets.zero
                      ? t.shapes.of(
                          DatePickerModalTokens.selectionYearStateLayerShape,
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Date input.

/// Keeps digits only and lays them out as MM/DD/YYYY as they are typed
/// (Compose's `DateInputTransformation` + `DateOutputTransformation`).
class _DateFormatter extends TextInputFormatter {
  const _DateFormatter();

  /// Digits in MMDDYYYY.
  static const int digits = 8;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final all = newValue.text.replaceAll(RegExp(r'\D'), '');
    final kept = all.length > digits ? all.substring(0, digits) : all;
    final out = StringBuffer();
    for (var i = 0; i < kept.length; i++) {
      if (i == 2 || i == 4) out.write('/');
      out.write(kept[i]);
    }
    final text = out.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}

/// Parses MM/DD/YYYY and validates it (Compose's `DateInputValidator`): the
/// day, or the error to show (both null while it is incomplete).
(DateTime?, String?) _parseInput(
  String text,
  _Selectable selectable,
  ExpressiveLocalizations strings, {
  DateTime? rangeStart,
}) {
  final digits = text.replaceAll(RegExp(r'\D'), '');
  if (digits.length < _DateFormatter.digits) return (null, null);
  final m = int.parse(digits.substring(0, 2));
  final d = int.parse(digits.substring(2, 4));
  final y = int.parse(digits.substring(4));
  if (m < 1 || m > DateTime.monthsPerYear || d < 1 || d > _daysIn(y, m)) {
    return (null, strings.badDatePattern);
  }
  final date = DateTime(y, m, d);
  if (y < selectable.firstYear || y > selectable.lastYear) {
    return (
      null,
      strings.outOfYears(selectable.firstYear, selectable.lastYear),
    );
  }
  if (!selectable.day(date)) return (null, strings.dateNotAllowed);
  if (rangeStart != null && date.isBefore(rangeStart)) {
    return (null, strings.endBeforeStart);
  }
  return (date, null);
}

/// `DateInputTextField`: an outlined field that takes MM/DD/YYYY, reports a
/// valid date as it completes and shows the validation error under it.
class _DateField extends StatefulWidget {
  const _DateField({
    required this.label,
    required this.initial,
    required this.onChanged,
    required this.validate,
  });

  final String label;
  final DateTime? initial;
  final ValueChanged<DateTime>? onChanged;
  final (DateTime?, String?) Function(String text) validate;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late final TextEditingController _text = TextEditingController(
    text: widget.initial == null ? '' : _inputText(widget.initial!),
  );
  late String? _error = widget.validate(_text.text).$2;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _changed(String text) {
    final (date, error) = widget.validate(text);
    setState(() => _error = error);
    if (date != null) widget.onChanged?.call(date);
  }

  @override
  Widget build(BuildContext context) => Padding(
    // Compose always passes `supportingText`, so its slot keeps
    // `MinSupportingTextLineHeight` under the field even when blank; a shown
    // error's line brings its own top padding, which comes off the bottom
    // padding so the content keeps its height (`DateInputTextField`).
    padding: EdgeInsets.only(
      bottom: _error == null
          ? DateInputBehavior.fieldPaddingBottom +
                TextFieldBehavior.minSupportingTextLineHeight
          : DateInputBehavior.fieldPaddingBottom -
                TextFieldBehavior.supportingTopPadding,
    ),
    child: ExpressiveTextField(
      style: _pickerControlStyle(context.expressiveTheme.datePickerTheme),
      controller: _text,
      kind: ExpressiveTextFieldKind.outlined,
      label: widget.label,
      hintText: ExpressiveLocalizations.of(context).datePattern,
      semanticLabel:
          '${widget.label}, ${ExpressiveLocalizations.of(context).datePattern}',
      errorText: _error,
      enabled: widget.onChanged != null,
      keyboardType: TextInputType.datetime,
      inputFormatters: const <TextInputFormatter>[_DateFormatter()],
      onChanged: _changed,
    ),
  );
}

/// `DateInputContent`: one field, padded as Compose pads it.
class _DateInputContent extends StatelessWidget {
  const _DateInputContent({
    required this.selected,
    required this.onChanged,
    required this.selectable,
  });

  final DateTime? selected;
  final ValueChanged<DateTime>? onChanged;
  final _Selectable selectable;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(
      left: DateInputBehavior.fieldPaddingHorizontal,
      right: DateInputBehavior.fieldPaddingHorizontal,
      top: DateInputBehavior.fieldPaddingTop,
    ),
    child: _DateField(
      label: ExpressiveLocalizations.of(context).date,
      initial: selected,
      onChanged: onChanged,
      validate: (text) =>
          _parseInput(text, selectable, ExpressiveLocalizations.of(context)),
    ),
  );
}

// ---------------------------------------------------------------------------
// The date range picker.

/// Compose's `DateRangePicker`: the header (title, the "start - end"
/// headline, the mode toggle), the weekday letters, then every month in a
/// scrolling list under its subhead, the chosen span drawn behind its days;
/// in input mode, a start and an end field side by side.
///
/// A tap sets the start; the next tap on or after it sets the end; a tap
/// before the start, or after a complete range, starts again
/// (`updateDateSelection`). [onChanged] reports the start and the end (null
/// until chosen).
///
/// The list fills the height its parent gives; unbounded, it shows seven
/// rows' worth.
class ExpressiveDateRangePicker extends StatefulWidget {
  /// A date range picker from [start] to [end], reporting a change through [onChanged].
  const ExpressiveDateRangePicker({
    this.style,
    this.start,
    this.end,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.firstYear,
    this.lastYear,
    this.initialMonth,
    this.initialMode = ExpressiveDatePickerMode.picker,
    this.title,
    this.showModeToggle = true,
    this.currentDate,
    this.firstDayOfWeek,
    super.key,
  });

  /// The range's first day, or none.
  final DateTime? start;

  /// The range's last day, or none.
  final DateTime? end;

  /// Called with the new start and end.
  final void Function(DateTime? start, DateTime? end)? onChanged;

  /// As [ExpressiveDatePicker.firstDate].
  final DateTime? firstDate;

  /// As [ExpressiveDatePicker.lastDate].
  final DateTime? lastDate;

  /// As [ExpressiveDatePicker.selectableDayPredicate].
  final bool Function(DateTime day)? selectableDayPredicate;

  /// As [ExpressiveDatePicker.firstYear].
  final int? firstYear;

  /// As [ExpressiveDatePicker.lastYear].
  final int? lastYear;

  /// The month scrolled to first; [start]'s (or [currentDate]'s) when null.
  final DateTime? initialMonth;

  /// The face shown first.
  final ExpressiveDatePickerMode initialMode;

  /// The header's title; "Select dates" ("Enter dates" typing) when null.
  final String? title;

  /// Whether the header's mode toggle shows.
  final bool showModeToggle;

  /// As [ExpressiveDatePicker.currentDate].
  final DateTime? currentDate;

  /// As [ExpressiveDatePicker.firstDayOfWeek].
  final int? firstDayOfWeek;

  /// Stateful visual overrides for the date picker.
  final ExpressiveComponentThemeData? style;

  @override
  State<ExpressiveDateRangePicker> createState() =>
      _ExpressiveDateRangePickerState();
}

class _ExpressiveDateRangePickerState extends State<ExpressiveDateRangePicker> {
  late ExpressiveDatePickerMode _mode = widget.initialMode;

  DateTime get _today => _dayOf(widget.currentDate ?? DateTime.now());

  /// `updateDateSelection`.
  void _tap(DateTime day) {
    final start = widget.start;
    final end = widget.end;
    if ((start == null && end == null) || (start != null && end != null)) {
      widget.onChanged?.call(day, null);
    } else if (start != null && !day.isBefore(start)) {
      widget.onChanged?.call(start, day);
    } else {
      widget.onChanged?.call(day, null);
    }
  }

  @override
  Widget build(BuildContext context) => ExpressiveTheme(
    data: context.expressiveTheme.copyWith(
      datePickerTheme: context.expressiveTheme.datePickerTheme.merge(
        widget.style,
      ),
    ),
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = _DateColors.of(t);
    final selectable = _selectableOf(
      firstYear: widget.firstYear,
      lastYear: widget.lastYear,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      predicate: widget.selectableDayPredicate,
    );
    final start = widget.start;
    final end = widget.end;
    final typing = _mode == ExpressiveDatePickerMode.input;
    final spoken =
        '${ExpressiveLocalizations.of(context).startDate}: ${start == null ? '-' : _spokenDay(start)}, '
        '${ExpressiveLocalizations.of(context).endDate}: ${end == null ? '-' : _spokenDay(end)}';
    final onChanged = widget.onChanged;
    return _DateEntryContainer(
      colors: colors,
      title: _HeaderTitle(
        widget.title ??
            (typing
                ? ExpressiveLocalizations.of(context).enterDates
                : ExpressiveLocalizations.of(context).selectDates),
        colors: colors,
        range: true,
      ),
      headline: _HeaderHeadline(
        spoken: spoken,
        colors: colors,
        style: t.type.of(
          DatePickerModalTokens.rangeSelectionHeaderHeadlineFont,
        ),
        range: true,
        child: _RangeHeadlineRow(
          start: start == null
              ? ExpressiveLocalizations.of(context).startDate
              : ExpressiveFormat.date(start),
          end: end == null
              ? ExpressiveLocalizations.of(context).endDate
              : ExpressiveFormat.date(end),
        ),
      ),
      modeToggle: widget.showModeToggle
          ? _ModeToggle(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            )
          : null,
      headerMinHeight:
          DatePickerModalTokens.rangeSelectionHeaderContainerHeight -
          DateRangePickerBehavior.headerHeightOffset,
      child: _ModeSwitch(
        mode: _mode,
        child: switch (_mode) {
          ExpressiveDatePickerMode.picker => _RangeCalendar(
            start: start,
            end: end,
            onTap: onChanged == null ? null : _tap,
            selectable: selectable,
            today: _today,
            initialMonth: widget.initialMonth ?? start ?? _today,
            firstDayOfWeek:
                widget.firstDayOfWeek ??
                ExpressiveLocalizations.of(context).firstDayOfWeek,
            colors: colors,
          ),
          ExpressiveDatePickerMode.input => Padding(
            padding: const EdgeInsets.only(
              left: DateInputBehavior.fieldPaddingHorizontal,
              right: DateInputBehavior.fieldPaddingHorizontal,
              top: DateInputBehavior.fieldPaddingTop,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: DateInputBehavior.rangeFieldSpacing,
              children: <Widget>[
                Expanded(
                  child: _DateField(
                    label: ExpressiveLocalizations.of(context).startDate,
                    initial: start,
                    onChanged: onChanged == null
                        ? null
                        : (d) => onChanged(
                            d,
                            end != null && end.isBefore(d) ? null : end,
                          ),
                    validate: (text) => _parseInput(
                      text,
                      selectable,
                      ExpressiveLocalizations.of(context),
                    ),
                  ),
                ),
                Expanded(
                  child: _DateField(
                    label: ExpressiveLocalizations.of(context).endDate,
                    initial: end,
                    onChanged: onChanged == null
                        ? null
                        : (d) => onChanged(start, d),
                    validate: (text) => _parseInput(
                      text,
                      selectable,
                      ExpressiveLocalizations.of(context),
                      rangeStart: start,
                    ),
                  ),
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// `DateRangePickerContent` + `VerticalMonthsList`: the weekdays over the
/// scrolling months, each under its subhead.
class _RangeCalendar extends StatefulWidget {
  const _RangeCalendar({
    required this.start,
    required this.end,
    required this.onTap,
    required this.selectable,
    required this.today,
    required this.initialMonth,
    required this.firstDayOfWeek,
    required this.colors,
  });

  final DateTime? start;
  final DateTime? end;
  final ValueChanged<DateTime>? onTap;
  final _Selectable selectable;
  final DateTime today;
  final DateTime initialMonth;
  final int firstDayOfWeek;
  final _DateColors colors;

  @override
  State<_RangeCalendar> createState() => _RangeCalendarState();
}

class _RangeCalendarState extends State<_RangeCalendar> {
  static const double _gridExtent =
      DatePickerBehavior.cellSize * DatePickerBehavior.maxCalendarRows;

  ScrollController? _scroll;
  double _extent = _gridExtent;

  @override
  void dispose() {
    _scroll?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final subhead = t.type
        .of(DatePickerModalTokens.rangeSelectionMonthSubheadFont)
        .copyWith(color: widget.colors.subhead);
    // A month's extent: its subhead (padding and one title-small line) and
    // its six rows.
    final line = MediaQuery.textScalerOf(context)
        .scale((subhead.fontSize ?? 0) * (subhead.height ?? 1));
    // Whole pixels: two thousand fractional extents add up past the
    // sliver's precision.
    final extent =
        (DateRangePickerBehavior.monthSubheadPaddingTop +
                DateRangePickerBehavior.monthSubheadPaddingBottom +
                line +
                _gridExtent)
            .ceilToDouble();
    final s = widget.selectable;
    if (_scroll == null || extent != _extent) {
      final offset = _scroll == null
          ? s.indexOf(widget.initialMonth) * extent
          : _scroll!.hasClients
          ? _scroll!.offset / _extent * extent
          : 0.0;
      _scroll?.dispose();
      _scroll = ScrollController(initialScrollOffset: offset);
      _extent = extent;
    }
    final list = ListView.builder(
      controller: _scroll,
      padding: EdgeInsets.zero,
      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
      itemExtent: extent,
      itemCount: s.monthCount,
      itemBuilder: (context, index) {
        final month = s.monthAt(index);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsetsDirectional.only(
                start: DateRangePickerBehavior.monthSubheadPaddingStart,
                top: DateRangePickerBehavior.monthSubheadPaddingTop,
                bottom: DateRangePickerBehavior.monthSubheadPaddingBottom,
              ),
              child: Text(
                _monthYear(month),
                style: subhead,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _Month(
              month: month,
              selected: widget.start,
              rangeEnd: widget.end,
              range: true,
              onChanged: widget.onTap,
              selectable: s,
              today: widget.today,
              firstDayOfWeek: widget.firstDayOfWeek,
              colors: widget.colors,
            ),
          ],
        );
      },
    );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: DatePickerBehavior.horizontalPadding,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _WeekDays(
              firstDayOfWeek: widget.firstDayOfWeek,
              colors: widget.colors,
            ),
            if (constraints.hasBoundedHeight)
              Flexible(child: list)
            else
              SizedBox(
                height:
                    DatePickerBehavior.cellSize *
                    (DatePickerBehavior.maxCalendarRows + 1),
                child: list,
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The docked date picker.

/// The docked date picker (Compose's docked sample): a read-only text field
/// of [kind] (filled, as [ExpressiveTextField] is, so a date sits among a
/// form's fields; Compose's sample draws it outlined) showing [value] as
/// MM/DD/YYYY (or as [format] prints it), whose tap (or calendar button)
/// raises the calendar in a popover below it — no header, no toggle. A
/// chosen day is reported through [onChanged] at once; the popover stays
/// until a tap outside, Escape or the system back closes it.
class ExpressiveDockedDatePicker extends StatefulWidget {
  /// A docked date picker showing [value] and reporting a choice through [onChanged].
  const ExpressiveDockedDatePicker({
    this.style,
    this.value,
    this.onChanged,
    this.label,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.currentDate,
    this.firstDayOfWeek,
    this.supportingText,
    this.format,
    this.kind = ExpressiveTextFieldKind.filled,
    super.key,
  });

  /// The chosen day, or none.
  final DateTime? value;

  /// How the read-only field prints [value] — an app whose dates are day
  /// first passes its own (`(d) => ExpressiveFormat.date(d)`, "3 Oct
  /// 2026"), so the field never reads as another day. Compose's MM/DD/YYYY
  /// input pattern when null.
  final String Function(DateTime day)? format;

  /// Called with the day the user chooses; disabled when null.
  final ValueChanged<DateTime>? onChanged;

  /// The field's label (the strings' `date` when null).
  final String? label;

  /// As [ExpressiveDatePicker.firstDate].
  final DateTime? firstDate;

  /// As [ExpressiveDatePicker.lastDate].
  final DateTime? lastDate;

  /// As [ExpressiveDatePicker.selectableDayPredicate].
  final bool Function(DateTime day)? selectableDayPredicate;

  /// As [ExpressiveDatePicker.currentDate].
  final DateTime? currentDate;

  /// As [ExpressiveDatePicker.firstDayOfWeek].
  final int? firstDayOfWeek;

  /// The line under the field.
  final String? supportingText;

  /// The field's container: filled (the default, as [ExpressiveTextField]
  /// is) or outlined (Compose's docked sample).
  final ExpressiveTextFieldKind kind;

  /// Stateful visual overrides for the date picker.
  final ExpressiveComponentThemeData? style;

  @override
  State<ExpressiveDockedDatePicker> createState() =>
      _ExpressiveDockedDatePickerState();
}

class _ExpressiveDockedDatePickerState
    extends State<ExpressiveDockedDatePicker> {
  late final TextEditingController _text = TextEditingController(
    text: _shown(widget.value),
  );
  bool _open = false;

  String _shown(DateTime? day) =>
      day == null ? '' : (widget.format ?? _inputText)(day);

  @override
  void didUpdateWidget(ExpressiveDockedDatePicker old) {
    super.didUpdateWidget(old);
    if (!_sameDay(old.value, widget.value) &&
        !(old.value == null && widget.value == null)) {
      _text.text = _shown(widget.value);
    } else if (old.format != widget.format) {
      _text.text = _shown(widget.value);
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _show() async {
    if (_open || widget.onChanged == null) return;
    setState(() => _open = true);
    var chosen = widget.value;
    await showExpressivePopover(
      context,
      padding: EdgeInsets.zero,
      label: widget.label ?? ExpressiveLocalizations.of(context).date,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => ExpressiveDatePicker(
          style: widget.style,
          selected: chosen,
          showHeader: false,
          showModeToggle: false,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          selectableDayPredicate: widget.selectableDayPredicate,
          currentDate: widget.currentDate,
          firstDayOfWeek: widget.firstDayOfWeek,
          onChanged: (d) {
            update(() => chosen = d);
            widget.onChanged?.call(d);
          },
        ),
      ),
    );
    if (mounted) setState(() => _open = false);
  }

  @override
  Widget build(BuildContext context) => ExpressiveTextField(
    style: context.expressiveTheme.datePickerTheme.merge(widget.style),
    controller: _text,
    kind: widget.kind,
    label: widget.label ?? ExpressiveLocalizations.of(context).date,
    hintText: ExpressiveLocalizations.of(context).datePattern,
    helperText: widget.supportingText,
    readOnly: true,
    enabled: widget.onChanged != null,
    onTap: _show,
    trailing: ExpressiveIconButton(
      ExpressiveSymbols.calendarMonth,
      onPressed: widget.onChanged == null ? null : _show,
      semanticLabel: ExpressiveLocalizations.of(context).selectDate,
    ),
  );
}

// ---------------------------------------------------------------------------
// The date picker dialog.

/// Compose's `DatePickerDialog`: [child] (an [ExpressiveDatePicker] or an
/// [ExpressiveDateRangePicker]) on the picker's container — 360dp wide,
/// at most 568dp tall, the extra-large corner — over the [dismiss] and
/// [confirm] text buttons at its bottom end. On a window too short for it
/// the picker scrolls above the buttons.
class ExpressiveDatePickerDialog extends StatelessWidget {
  /// A dialog around [child] with [confirm] and an optional [dismiss] action.
  const ExpressiveDatePickerDialog({
    this.style,
    required this.child,
    required this.confirm,
    this.dismiss,
    super.key,
  });

  /// The picker.
  final Widget child;

  /// The confirm action (a text button, "OK").
  final Widget confirm;

  /// The dismiss action (a text button, "Cancel").
  final Widget? dismiss;

  /// Stateful visual overrides for the date picker.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: _buildDialog);

  Widget _buildDialog(BuildContext context, BoxConstraints constraints) {
    final t = context.expressiveTheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: DatePickerModalTokens.containerWidth,
        maxHeight: DatePickerModalTokens.containerHeight,
      ),
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.datePickerTheme,
        padding: constraints.maxWidth < DatePickerModalTokens.containerWidth
            ? const EdgeInsets.symmetric(horizontal: ExpressiveSpacing.s16)
            : EdgeInsets.zero,
        shape: t.shapes.of(DatePickerModalTokens.containerShape),
        color: t.colors.role(DatePickerModalTokens.containerColor),
        contentColor: t.colors.onSurface,
        tonalElevation: DatePickerModalTokens.containerElevation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // A window shorter than the dialog scrolls the picker (Compose
            // clips it); the range picker's own list scrolls already.
            Flexible(
              child: child is ExpressiveDateRangePicker
                  ? child
                  : SingleChildScrollView(child: child),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                // DatePickerDialog.android.kt's DialogButtonsPadding (bottom
                // 8, end 6) and DialogButtonsMainAxisSpacing (8): spacing
                // steps, as the behaviour generator reads common sources
                // only.
                padding: const EdgeInsetsDirectional.only(
                  bottom: ExpressiveSpacing.s8,
                  end: ExpressiveSpacing.s6,
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: ExpressiveSpacing.s8,
                  children: <Widget>[?dismiss, confirm],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Raises an [ExpressiveDatePicker] in an [ExpressiveDatePickerDialog] and
/// resolves to the day confirmed with OK, or null when cancelled. The
/// choice is a draft until OK, which waits for one.
Future<DateTime?> showExpressiveDatePicker({
  required BuildContext context,
  ExpressiveComponentThemeData? style,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  bool Function(DateTime day)? selectableDay,
  ExpressiveDatePickerMode initialMode = ExpressiveDatePickerMode.picker,
  String? title,
  DateTime? today,
  int? firstDayOfWeek,
  String? confirmLabel,
  String? dismissLabel,
}) {
  final strings = ExpressiveLocalizations.of(context);
  var draft = initialDate;
  return showExpressiveDialog<DateTime>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => ExpressiveDatePickerDialog(
        style: style,
        dismiss: ExpressiveTextButton(
          dismissLabel ?? strings.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        confirm: ExpressiveTextButton(
          confirmLabel ?? strings.ok,
          onPressed: draft == null
              ? null
              : () => Navigator.of(context).pop(draft),
        ),
        child: ExpressiveDatePicker(
          style: style,
          selected: draft,
          onChanged: (d) => update(() => draft = d),
          firstDate: firstDate,
          lastDate: lastDate,
          selectableDayPredicate: selectableDay,
          initialMode: initialMode,
          title: title,
          currentDate: today,
          firstDayOfWeek: firstDayOfWeek,
        ),
      ),
    ),
  );
}

/// Raises an [ExpressiveDateRangePicker] in an [ExpressiveDatePickerDialog]
/// and resolves to the range confirmed with OK (OK waits for both ends), or
/// null when cancelled.
Future<({DateTime start, DateTime end})?> showExpressiveDateRangePicker({
  required BuildContext context,
  ExpressiveComponentThemeData? style,
  DateTime? initialStart,
  DateTime? initialEnd,
  DateTime? firstDate,
  DateTime? lastDate,
  bool Function(DateTime day)? selectableDay,
  String? title,
  DateTime? today,
  int? firstDayOfWeek,
  String? confirmLabel,
  String? dismissLabel,
}) {
  final strings = ExpressiveLocalizations.of(context);
  var start = initialStart;
  var end = initialEnd;
  return showExpressiveDialog<({DateTime start, DateTime end})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) {
        final s = start;
        final e = end;
        return ExpressiveDatePickerDialog(
          style: style,
          dismiss: ExpressiveTextButton(
            dismissLabel ?? strings.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          confirm: ExpressiveTextButton(
            confirmLabel ?? strings.ok,
            onPressed: s == null || e == null
                ? null
                : () => Navigator.of(context).pop((start: s, end: e)),
          ),
          child: ExpressiveDateRangePicker(
            style: style,
            start: s,
            end: e,
            onChanged: (ns, ne) => update(() {
              start = ns;
              end = ne;
            }),
            firstDate: firstDate,
            lastDate: lastDate,
            selectableDayPredicate: selectableDay,
            title: title,
            currentDate: today,
            firstDayOfWeek: firstDayOfWeek,
          ),
        );
      },
    ),
  );
}

// ---------------------------------------------------------------------------
// Time: the state.

/// Which value a time picker's dial and fields edit (Compose's
/// `TimePickerSelectionMode`).
enum ExpressiveTimeSelection {
  /// The hour.
  hour,

  /// The minutes.
  minute,
}

const int _half = Duration.hoursPerDay ~/ 2;

/// Compose's `TimePickerState`: the time (hour 0–23, minute 0–59), the
/// clock it is shown on and which value is being edited. Every time picker,
/// time input and time scroll edits one; share it to switch between them
/// (a dialog's mode toggle does). Listen to it for changes.
class ExpressiveTimePickerController extends ChangeNotifier {
  /// A time picker controller at [hour] and [minute], on a 24-hour clock when `_is24Hour`.
  ExpressiveTimePickerController({
    int hour = 0,
    int minute = 0,
    this._is24Hour = false,
  }) : assert(hour >= 0 && hour < Duration.hoursPerDay),
       assert(minute >= 0 && minute < Duration.minutesPerHour),
       _hour = hour,
       _minute = minute;

  int _hour;
  int _minute;
  bool _is24Hour;
  ExpressiveTimeSelection _selection = ExpressiveTimeSelection.hour;

  /// The hour, 0–23.
  int get hour => _hour;
  set hour(int value) {
    final v = value % Duration.hoursPerDay;
    if (v == _hour) return;
    _hour = v;
    notifyListeners();
  }

  /// The minute, 0–59.
  int get minute => _minute;
  set minute(int value) {
    final v = value % Duration.minutesPerHour;
    if (v == _minute) return;
    _minute = v;
    notifyListeners();
  }

  /// Whether the time shows on the 24-hour clock.
  bool get is24Hour => _is24Hour;
  set is24Hour(bool value) {
    if (value == _is24Hour) return;
    _is24Hour = value;
    notifyListeners();
  }

  /// The value being edited.
  ExpressiveTimeSelection get selection => _selection;
  set selection(ExpressiveTimeSelection value) {
    if (value == _selection) return;
    _selection = value;
    notifyListeners();
  }

  /// Whether the hour is in the afternoon (12–23).
  bool get isPm => _hour >= _half;

  /// The hour as the clock face prints it: 0–23 on the 24-hour clock, else
  /// 1–12 (`hourForDisplay`).
  int get hourForDisplay {
    if (_is24Hour) return _hour;
    if (_hour % _half == 0) return _half;
    return isPm ? _hour - _half : _hour;
  }

  /// Sets the hour and minute at once.
  void setTime(int hour, int minute) {
    final h = hour % Duration.hoursPerDay;
    final m = minute % Duration.minutesPerHour;
    if (h == _hour && m == _minute) return;
    _hour = h;
    _minute = m;
    notifyListeners();
  }

  /// Switches to AM ([pm] false) or PM, keeping the clock-face hour.
  void setPeriod({required bool pm}) {
    if (pm == isPm) return;
    hour = pm ? _hour + _half : _hour - _half;
  }

  /// Sets the hour from a clock-face [value] (1–12, or 0–23 on the 24-hour
  /// clock), keeping the period.
  void setDisplayHour(int value) {
    hour = _is24Hour ? value : value % _half + (isPm ? _half : 0);
  }
}

/// How a time picker lays its fields and dial out (Compose's
/// `TimePickerLayoutType`).
enum ExpressiveTimePickerLayout {
  /// The fields above the dial (portrait).
  vertical,

  /// The fields beside the dial (landscape).
  horizontal,
}

/// Compose's `TimePickerColors`, resolved: `colors()` or `vibrantColors()`.
@immutable
class _TimeColors {
  _TimeColors.of(ExpressiveThemeData t, {required this.vibrant})
    : dial = vibrant
          ? t.colors.surfaceContainerLowest
          : t.colors.role(TimePickerTokens.clockDialColor),
      dialSelectedContent = t.colors.role(
        TimePickerTokens.clockDialSelectedLabelTextColor,
      ),
      dialContent = t.colors.role(
        TimePickerTokens.clockDialUnselectedLabelTextColor,
      ),
      selector = t.colors.role(
        TimePickerTokens.clockDialSelectorHandleContainerColor,
      ),
      periodSelectedContainer = t.colors.primaryContainer,
      // Compose's colors(): the unselected period is transparent inside
      // the 1dp outline; vibrantColors() fills it instead.
      periodContainer = vibrant
          ? t.colors.surfaceContainerLowest
          : expressiveTransparent,
      periodOutline = vibrant
          ? null
          : t.colors.role(TimePickerTokens.periodSelectorOutlineColor),
      periodSelectedContent = t.colors.onPrimaryContainer,
      periodContent = t.colors.role(
        TimePickerTokens.periodSelectorUnselectedLabelTextColor,
      ),
      fieldSelectedContainer = vibrant
          ? t.colors.surfaceContainerLowest
          : t.colors.role(TimePickerTokens.timeSelectorSelectedContainerColor),
      fieldContainer = vibrant
          ? t.colors.surfaceContainerLowest
          : t.colors.role(
              TimePickerTokens.timeSelectorUnselectedContainerColor,
            ),
      fieldSelectedContent = vibrant
          ? t.colors.primary
          : t.colors.role(TimePickerTokens.timeSelectorSelectedLabelTextColor),
      fieldContent = vibrant
          ? t.colors.onSurface
          : t.colors.role(
              TimePickerTokens.timeSelectorUnselectedLabelTextColor,
            ),
      // `timeTextFieldColors`: `focusedBorderColor` and
      // `unfocusedBorderColor` are both `Outline` (not the spec's
      // `TimeFieldFocusOutlineColor`).
      fieldBorder = t.colors.outline,
      separator =
          t.timePickerTheme.foregroundColor?.resolve({}) ??
          t.colors.role(TimeInputTokens.timeFieldSeparatorColor),
      error = t.colors.error,
      errorContainer = t.colors.errorContainer,
      onErrorContainer = t.colors.onErrorContainer,
      supporting = t.colors.role(TimeInputTokens.timeFieldSupportingTextColor),
      primary = t.colors.primary;

  final bool vibrant;
  final Color dial;
  final Color dialSelectedContent;
  final Color dialContent;
  final Color selector;
  final Color periodSelectedContainer;
  final Color periodContainer;

  /// The unselected period's outline (none when vibrant).
  final Color? periodOutline;
  final Color periodSelectedContent;
  final Color periodContent;
  final Color fieldSelectedContainer;
  final Color fieldContainer;
  final Color fieldSelectedContent;
  final Color fieldContent;
  final Color fieldBorder;
  final Color separator;
  final Color error;
  final Color errorContainer;
  final Color onErrorContainer;
  final Color supporting;
  final Color primary;
}

// ---------------------------------------------------------------------------
// The time picker (dial).

/// Compose's `TimePicker`: the hour and minute selectors and (on the
/// 12-hour clock) the AM/PM toggle, above the clock dial — or beside it in
/// [ExpressiveTimePickerLayout.horizontal]. A tap on a selector picks what
/// the dial edits; a tap or drag on the dial sets it, the selector
/// springing to the value, and a chosen hour moves on to the minutes.
///
/// [vibrant] is Material 3 Expressive's vibrant picker (Compose's
/// `TimePicker(shapes = …)` with `vibrantColors()`): taller fields on the
/// large corner, the dial on the lowest container.
class ExpressiveTimePicker extends StatelessWidget {
  /// A time picker editing [controller].
  const ExpressiveTimePicker({
    required this.controller,
    this.vibrant = false,
    this.layout,
    this.autoSwitchToMinute = true,
    this.style,
    super.key,
  });

  /// Stateful paint, geometry and type overrides.
  final ExpressiveComponentThemeData? style;

  /// The time it edits.
  final ExpressiveTimePickerController controller;

  /// Whether it is the vibrant picker.
  final bool vibrant;

  /// The layout; from the window's orientation when null (Compose's
  /// `TimePickerDefaults.layoutType()`).
  final ExpressiveTimePickerLayout? layout;

  /// Whether a chosen hour moves the dial on to the minutes (Compose turns
  /// it off for screen-reader use).
  final bool autoSwitchToMinute;

  @override
  Widget build(BuildContext context) => _TimePlate(
    style: style,
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final colors = _TimeColors.of(context.expressiveTheme, vibrant: vibrant);
    final type =
        layout ??
        (MediaQuery.orientationOf(context) == Orientation.landscape
            ? ExpressiveTimePickerLayout.horizontal
            : ExpressiveTimePickerLayout.vertical);
    final auto =
        autoSwitchToMinute && !MediaQuery.accessibleNavigationOf(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final dial = _ClockFace(
          controller: controller,
          colors: colors,
          autoSwitchToMinute: auto,
        );
        final horizontal = type == ExpressiveTimePickerLayout.horizontal;
        final display = _ClockDisplay(
          controller: controller,
          colors: colors,
          horizontal: horizontal,
        );
        final displayWidth = _timeDisplayWidth(
          vibrant: vibrant,
          horizontal: horizontal,
          is24Hour: controller.is24Hour,
        );
        final naturalWidth = horizontal
            ? displayWidth +
                  (vibrant
                      ? TimePickerBehavior.vibrantHorizontalGap
                      : TimePickerBehavior.clockDisplayBottomMargin) +
                  TimePickerTokens.clockDialContainerSize
            : math.max(displayWidth, TimePickerTokens.clockDialContainerSize);
        return _PickerViewport(
          naturalWidth: naturalWidth,
          naturalHeight: horizontal
              ? TimePickerTokens.clockDialContainerSize
              : (vibrant
                        ? TimePickerBehavior.vibrantFieldHeight +
                              TimePickerBehavior.vibrantVerticalGap
                        : TimePickerTokens.timeSelectorContainerHeight +
                              TimePickerBehavior.clockDisplayBottomMargin +
                              TimePickerBehavior.clockFaceBottomMargin) +
                    TimePickerTokens.clockDialContainerSize,
          child: Semantics(
            explicitChildNodes: true,
            child: horizontal
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      display,
                      SizedBox(
                        width: vibrant
                            ? TimePickerBehavior.vibrantHorizontalGap
                            : TimePickerBehavior.clockDisplayBottomMargin,
                      ),
                      dial,
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      display,
                      SizedBox(
                        height: vibrant
                            ? TimePickerBehavior.vibrantVerticalGap
                            : TimePickerBehavior.clockDisplayBottomMargin,
                      ),
                      dial,
                      if (!vibrant)
                        const SizedBox(
                          height: TimePickerBehavior.clockFaceBottomMargin,
                        ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

/// `VerticalClockDisplay` / `HorizontalClockDisplay`: the two selectors
/// with the colon between them, and the AM/PM toggle beside (or under)
/// them on the 12-hour clock.
class _ClockDisplay extends StatelessWidget {
  const _ClockDisplay({
    required this.controller,
    required this.colors,
    required this.horizontal,
  });

  final ExpressiveTimePickerController controller;
  final _TimeColors colors;
  final bool horizontal;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final vibrant = colors.vibrant;
    final fieldWidth = vibrant
        ? (!horizontal && controller.is24Hour
              ? TimePickerBehavior.vibrantFieldWidthPortrait
              : TimePickerBehavior.vibrantFieldWidth)
        // Compose's ClockDisplay reads `TimeSelectorContainerWidth` for every
        // non-vibrant layout; only the vibrant width widens in portrait 24h.
        : TimePickerTokens.timeSelectorContainerWidth;
    final fieldHeight = vibrant
        ? TimePickerBehavior.vibrantFieldHeight
        : TimePickerTokens.timeSelectorContainerHeight;
    final style = t.type.of(TimePickerTokens.timeSelectorLabelTextFont);
    final numbers = Directionality(
      textDirection: TextDirection.ltr,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _TimeSelector(
            value: controller.hourForDisplay,
            selection: ExpressiveTimeSelection.hour,
            controller: controller,
            colors: colors,
            width: fieldWidth,
            height: fieldHeight,
            style: style,
          ),
          _Separator(
            width: vibrant
                ? TimePickerBehavior.vibrantSeparatorWidth
                : TimePickerBehavior.separatorWidth,
            height: fieldHeight,
            style: t.type.of(TimePickerTokens.timeSelectorSeparatorFont),
            color: colors.separator,
          ),
          _TimeSelector(
            value: controller.minute,
            selection: ExpressiveTimeSelection.minute,
            controller: controller,
            colors: colors,
            width: fieldWidth,
            height: fieldHeight,
            style: style,
          ),
        ],
      ),
    );
    if (controller.is24Hour) return numbers;
    if (horizontal) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          numbers,
          Padding(
            padding: const EdgeInsets.only(
              top: TimePickerBehavior.vibrantPeriodToggleLargePadding,
            ),
            child: _PeriodToggle(
              controller: controller,
              colors: colors,
              horizontal: true,
              width: TimePickerTokens.periodSelectorHorizontalContainerWidth,
              height: vibrant
                  ? TimePickerBehavior.vibrantPeriodToggleHorizontalHeight
                  : TimePickerTokens.periodSelectorHorizontalContainerHeight,
              gap: vibrant
                  ? TimePickerBehavior.vibrantPeriodTogglePadding
                  : TimePickerBehavior.periodTogglePadding,
            ),
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        numbers,
        Padding(
          padding: EdgeInsetsDirectional.only(
            start: vibrant
                ? TimePickerBehavior.vibrantPeriodToggleLargePadding
                : TimePickerBehavior.periodTogglePadding,
          ),
          child: _PeriodToggle(
            controller: controller,
            colors: colors,
            horizontal: false,
            width: vibrant
                ? TimePickerBehavior.vibrantPeriodToggleWidth
                : TimePickerTokens.periodSelectorVerticalContainerWidth,
            height: vibrant
                ? TimePickerBehavior.vibrantPeriodToggleHeight
                : TimePickerTokens.periodSelectorVerticalContainerHeight,
            gap: vibrant
                ? TimePickerBehavior.vibrantPeriodTogglePadding
                : TimePickerBehavior.periodTogglePadding,
          ),
        ),
      ],
    );
  }
}

/// The spoken name of [number] on the dial or a field.
String _spokenNumber(
  ExpressiveTimeSelection selection, {
  required ExpressiveLocalizations strings,
  required bool is24Hour,
  required int number,
}) => switch (selection) {
  ExpressiveTimeSelection.minute => strings.minutes(number),
  ExpressiveTimeSelection.hour =>
    is24Hour ? strings.hours(number) : strings.oClock(number),
};

/// `TimeSelector`: an hour or minute field — a radio that picks what the
/// dial edits — its two digits in the selector type.
class _TimeSelector extends StatelessWidget {
  const _TimeSelector({
    required this.value,
    required this.selection,
    required this.controller,
    required this.colors,
    required this.width,
    required this.height,
    required this.style,
    this.valid = true,
  });

  final int value;
  final ExpressiveTimeSelection selection;
  final ExpressiveTimePickerController controller;
  final _TimeColors colors;
  final double width;
  final double height;
  final TextStyle style;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final selected = controller.selection == selection;
    final container = !valid
        ? colors.errorContainer
        : selected
        ? colors.fieldSelectedContainer
        : colors.fieldContainer;
    final content = !valid
        ? colors.onErrorContainer
        : selected
        ? colors.fieldSelectedContent
        : colors.fieldContent;
    final shape = colors.vibrant
        ? t.shapes.of(ExpressiveShapeKey.cornerLarge)
        : t.shapes.of(TimePickerTokens.timeSelectorContainerShape);
    final spoken = _spokenNumber(
      selection,
      strings: ExpressiveLocalizations.of(context),
      is24Hour: controller.is24Hour,
      number: value,
    );
    return ExpressivePressable(
      componentStyle: _pickerControlStyle(t.timePickerTheme),
      shapes: ExpressivePressShapes.all(shape),
      motion: ExpressiveMotionKey.defaultSpatial,
      color: container,
      contentColor: content,
      side: colors.vibrant && selected
          ? BorderSide(
              color: valid ? colors.primary : colors.error,
              width: TimePickerBehavior.selectedFieldBorder,
            )
          : BorderSide.none,
      role: ExpressivePressRole.radio,
      selected: selected,
      error: !valid,
      semanticLabel:
          '${selection == ExpressiveTimeSelection.hour ? ExpressiveLocalizations.of(context).selectHour : ExpressiveLocalizations.of(context).selectMinute}, $spoken',
      onPressed: () => controller.selection = selection,
      child: SizedBox(
        width: width,
        height: height,
        child: ExpressiveStyledContent(
          textStyle: style.copyWith(color: content),
          child: ExcludeSemantics(child: _PickerLabel(_two(value))),
        ),
      ),
    );
  }
}

/// `DisplaySeparator`: the colon, centred in [width] × [height], lifted
/// [TimePickerBehavior.separatorLift].
class _Separator extends StatelessWidget {
  const _Separator({
    required this.width,
    required this.height,
    required this.style,
    required this.color,
  });

  final double width;
  final double height;
  final TextStyle style;
  final Color color;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: width,
      height: height,
      child: OverflowBox(
        // Loose: the colon's line box is centred in the separator, not
        // stretched to it (a tight box would set the text at its top).
        minWidth: 0,
        minHeight: 0,
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        // LineHeightStyle(Center, Trim.Both), then offset(y = -4dp). The
        // display styles' line heights all but equal the font's own
        // height, so the trimmed box is the evenly distributed line box
        // (the style's leading distribution) centred in the separator.
        child: Transform.translate(
          offset: const Offset(0, -TimePickerBehavior.separatorLift),
          child: Text(
            ':',
            textAlign: TextAlign.center,
            style: _fitPickerFieldStyle(
              context,
              style
                  .merge(
                    context.expressiveTheme.timePickerTheme.textStyle?.resolve(
                      {},
                    ),
                  )
                  .copyWith(
                    color: color,
                    leadingDistribution: TextLeadingDistribution.even,
                  ),
              Size(
                double.infinity,
                height -
                    TimePickerBehavior.separatorLift -
                    TimePickerBehavior.separatorLift,
              ),
              text: ':',
            ),
          ),
        ),
      ),
    ),
  );
}

/// `VerticalPeriodToggle` / `HorizontalPeriodToggle`, the updated toggle:
/// AM and PM as two toggle buttons [gap] apart, the checked one on
/// `primaryContainer`, its label bold, its corners springing from full to
/// 12dp while checked or pressed.
class _PeriodToggle extends StatelessWidget {
  const _PeriodToggle({
    required this.controller,
    required this.colors,
    required this.horizontal,
    required this.width,
    required this.height,
    required this.gap,
  });

  final ExpressiveTimePickerController controller;
  final _TimeColors colors;
  final bool horizontal;
  final double width;
  final double height;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final touch = ExpressiveMinimumInteractiveSize.enforcedAt(context)
        ? HostBehavior.minimumInteractiveComponentSize
        : 0.0;
    final customized = theme.timePickerTheme.shape != null;
    // Custom outlines reserve content insets inside both buttons. Give their
    // actual targets room instead of extending semantics beyond a short pair.
    final pairWidth = customized
        ? math.max(width, horizontal ? touch * 2 + gap : touch)
        : width;
    final pairHeight = customized
        ? math.max(height, horizontal ? touch : touch * 2 + gap)
        : height;
    final itemWidth = horizontal ? (pairWidth - gap) / 2 : pairWidth;
    final itemHeight = horizontal ? pairHeight : (pairHeight - gap) / 2;
    Widget item(String label, {required bool pm}) => _PeriodTarget(
      touch: touch,
      child: _PeriodItem(
        label: label,
        checked: controller.isPm == pm,
        colors: colors,
        width: itemWidth,
        height: itemHeight,
        onTap: () => controller.setPeriod(pm: pm),
      ),
    );
    final children = <Widget>[
      item(ExpressiveLocalizations.of(context).am, pm: false),
      item(ExpressiveLocalizations.of(context).pm, pm: true),
    ];
    return Semantics(
      label: ExpressiveLocalizations.of(context).period,
      explicitChildNodes: true,
      child: SizedBox(
        width: pairWidth,
        height: pairHeight,
        child: horizontal
            ? Row(spacing: gap, children: children)
            : Column(spacing: gap, children: children),
      ),
    );
  }
}

/// One period button's node, at least [touch] square, centred on the
/// button: Compose's `ToggleButton` is a toggleable `Surface`, which takes
/// `minimumInteractiveComponentSize()`, so its node reaches 48dp though the
/// toggle draws each half shorter. The layout and the drawing keep the
/// halves' size; the node merges the button's own.
class _PeriodTarget extends SingleChildRenderObjectWidget {
  const _PeriodTarget({required this.touch, required super.child});

  /// The smallest node side; 0 where targets are shrunk.
  final double touch;

  @override
  _RenderPeriodTarget createRenderObject(BuildContext context) =>
      _RenderPeriodTarget(touch);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPeriodTarget renderObject,
  ) => renderObject.touch = touch;
}

class _RenderPeriodTarget extends RenderProxyBox {
  _RenderPeriodTarget(this._touch);

  double _touch;
  set touch(double value) {
    if (value == _touch) return;
    _touch = value;
    markNeedsSemanticsUpdate();
  }

  @override
  Rect get semanticBounds {
    final dx = math.max(0.0, (_touch - size.width) / 2);
    final dy = math.max(0.0, (_touch - size.height) / 2);
    return Rect.fromLTRB(-dx, -dy, size.width + dx, size.height + dy);
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    config
      ..isSemanticBoundary = true
      ..isMergingSemanticsOfDescendants = true;
  }
}

/// `ToggleItem` (the updated toggle): Compose's `ToggleButton` with the
/// period colours and `ToggleButtonShapes(CircleShape, 12dp, 12dp)`.
class _PeriodItem extends StatelessWidget {
  const _PeriodItem({
    required this.label,
    required this.checked,
    required this.colors,
    required this.width,
    required this.height,
    required this.onTap,
  });

  final String label;
  final bool checked;
  final _TimeColors colors;
  final double width;
  final double height;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final rounded = t.shapes.medium;
    final content = checked
        ? colors.periodSelectedContent
        : colors.periodContent;
    final base = t.type.of(TimePickerTokens.periodSelectorLabelTextFont);
    return ExpressivePressable(
      componentStyle: _pickerControlStyle(t.timePickerTheme),
      shapes: ExpressivePressShapes(
        shape: t.shapes.of(ExpressiveShapeKey.cornerFull),
        pressed: rounded,
        selected: rounded,
      ),
      motion: ButtonBehavior.pressMotion,
      color: checked ? colors.periodSelectedContainer : colors.periodContainer,
      contentColor: content,
      side: switch (colors.periodOutline) {
        final outline? when !checked => BorderSide(
          color: outline,
          width: TimePickerTokens.periodSelectorOutlineWidth,
        ),
        _ => BorderSide.none,
      },
      role: ExpressivePressRole.radio,
      selected: checked,
      minimumInteractiveSize: false,
      semanticLabel: label,
      onPressed: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: ExpressiveStyledContent(
          textStyle: (checked ? _bold(base) : base).copyWith(color: content),
          child: Builder(
            builder: (context) => ExcludeSemantics(
              child: _PickerLabel(
                label,
                shape:
                    ExpressiveStyleScope.maybeOf(context)!.inset ==
                        EdgeInsets.zero
                    ? (checked
                          ? rounded
                          : t.shapes.of(ExpressiveShapeKey.cornerFull))
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// [style] at bold weight, its variable axis too.
TextStyle _bold(TextStyle style) => style.copyWith(
  fontWeight: FontWeight.bold,
  fontVariations: <FontVariation>[
    for (final v in style.fontVariations ?? const <FontVariation>[])
      if (v.axis != 'wght') v,
    FontVariation.weight(FontWeight.bold.value.toDouble()),
  ],
);

/// The selector's handle radius.
const double _handleRadius =
    TimePickerTokens.clockDialSelectorHandleContainerSize / 2;

/// The dial's centre, from its top left.
const double _dialCentre = TimePickerTokens.clockDialContainerSize / 2;

/// `ClockFace`: the 256dp dial, its numbers on a circle (and a second,
/// inner circle for the 24-hour clock's afternoon hours), the selector — a
/// 48dp handle on a 2dp track from an 8dp centre — springing to the value
/// on the default spatial spring, the numbers under the handle in the
/// selected colour, and the hour and minute faces crossfading on the
/// default effects spring.
class _ClockFace extends StatefulWidget {
  const _ClockFace({
    required this.controller,
    required this.colors,
    required this.autoSwitchToMinute,
  });

  final ExpressiveTimePickerController controller;
  final _TimeColors colors;
  final bool autoSwitchToMinute;

  @override
  State<_ClockFace> createState() => _ClockFaceState();
}

class _ClockFaceState extends State<_ClockFace> with TickerProviderStateMixin {
  static const double _full = math.pi * 2;
  static const double _quarter = math.pi / 2;
  static const int _fiveMinutes = 5;

  /// The selector's screen angle (0 at three o'clock, clockwise).
  late final AnimationController _angle = AnimationController.unbounded(
    vsync: this,
    value: _targetAngle,
  );

  /// The crossfade between the hour and minute faces: 1 shows [_face].
  late final AnimationController _fade = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  late ExpressiveTimeSelection _face = widget.controller.selection;
  ExpressiveTimeSelection? _previousFace;
  late int _hour = widget.controller.hour;
  late int _minute = widget.controller.minute;
  bool _dragging = false;
  Offset _drag = Offset.zero;
  Timer? _switch;

  ExpressiveTimePickerController get _c => widget.controller;

  double get _targetAngle => _c.selection == ExpressiveTimeSelection.hour
      ? (_c.hour % _half) * (_full / _half) - _quarter
      : _c.minute * (_full / Duration.minutesPerHour) - _quarter;

  @override
  void didUpdateWidget(_ClockFace old) {
    super.didUpdateWidget(old);
    final c = _c;
    var moved = c.hour != _hour || c.minute != _minute;
    if (c.selection != _face) {
      _previousFace = _face;
      _face = c.selection;
      _fade
        ..value = 0
        ..springTo(1, ExpressiveMotion.of(context).defaultEffects);
      moved = true;
    }
    if (!_dragging && moved) _springAngle();
    _hour = c.hour;
    _minute = c.minute;
  }

  /// Springs the selector to the value along the shorter way round
  /// (`endValueForAnimation`).
  void _springAngle() {
    var diff = _angle.value - _targetAngle;
    while (diff > math.pi) {
      diff -= _full;
    }
    while (diff <= -math.pi) {
      diff += _full;
    }
    _angle.springTo(
      _angle.value - diff,
      ExpressiveMotion.of(context).defaultSpatial,
    );
  }

  @override
  void dispose() {
    _switch?.cancel();
    _angle.dispose();
    _fade.dispose();
    super.dispose();
  }

  /// Sets the value at [local] (relative to the dial's top left): the
  /// nearest hour, the nearest minute (on a tap, the nearest five), the
  /// 24-hour clock's ring by the distance from the centre (`moveSelector`).
  void _setAt(Offset local, {required bool tap}) {
    final v = local - const Offset(_dialCentre, _dialCentre);
    final screen = math.atan2(v.dy, v.dx);
    final fromTwelve = (screen + _quarter) % _full;
    final c = _c;
    if (c.selection == ExpressiveTimeSelection.hour) {
      final h = (fromTwelve / (_full / _half)).round() % _half;
      final pm = c.is24Hour
          ? v.distance < TimePickerBehavior.innerRingDistance
          : c.isPm;
      c.hour = h + (pm ? _half : 0);
    } else {
      var m = (fromTwelve / (_full / Duration.minutesPerHour)).round();
      if (tap) m = (m / _fiveMinutes).round() * _fiveMinutes;
      c.minute = m % Duration.minutesPerHour;
    }
    if (!tap) _angle.value = screen;
  }

  void _afterHour() {
    if (!widget.autoSwitchToMinute) return;
    _switch?.cancel();
    _switch = Timer(
      const Duration(milliseconds: TimePickerBehavior.autoSwitchDelay),
      () {
        if (mounted) _c.selection = ExpressiveTimeSelection.minute;
      },
    );
  }

  void _onTap(Offset local) {
    final wasHour = _c.selection == ExpressiveTimeSelection.hour;
    _setAt(local, tap: true);
    _springAngle();
    if (wasHour) _afterHour();
  }

  /// The values on [face]'s outer circle and, for the 24-hour hours, the
  /// inner one.
  (List<int>, List<int>) _values(ExpressiveTimeSelection face) {
    if (face == ExpressiveTimeSelection.minute) {
      return (
        <int>[for (var i = 0; i < _half; i++) i * _fiveMinutes],
        const <int>[],
      );
    }
    if (!_c.is24Hour) {
      return (<int>[_half, for (var i = 1; i < _half; i++) i], const <int>[]);
    }
    return (
      <int>[for (var i = 0; i < _half; i++) i],
      <int>[for (var i = 0; i < _half; i++) i + _half],
    );
  }

  bool _isValue(ExpressiveTimeSelection face, int value) {
    final c = _c;
    if (face == ExpressiveTimeSelection.hour) {
      return c.is24Hour ? value == c.hour : value == c.hourForDisplay;
    }
    return value == c.minute;
  }

  /// A number chosen by its semantics tap.
  void _choose(ExpressiveTimeSelection face, int value) {
    final c = _c;
    if (face == ExpressiveTimeSelection.hour) {
      c.setDisplayHour(value);
      _afterHour();
    } else {
      c.minute = value;
    }
  }

  Widget _numbers(
    ExpressiveTimeSelection face,
    TextStyle style,
    Color color, {
    required bool semantics,
  }) {
    const target = TimePickerBehavior.numberTarget;
    const halfTarget = target / 2;
    final (outer, inner) = _values(face);
    Iterable<Widget> ring(List<int> values, double radius) sync* {
      for (var i = 0; i < values.length; i++) {
        final value = values[i];
        final angle = _full / values.length * i - _quarter;
        final label = Center(
          child: Text(
            '$value',
            maxLines: 1,
            softWrap: false,
            style: style.copyWith(color: color),
          ),
        );
        yield Positioned(
          left: _dialCentre + radius * math.cos(angle) - halfTarget,
          top: _dialCentre + radius * math.sin(angle) - halfTarget,
          width: target,
          height: target,
          child: semantics
              ? Semantics(
                  button: true,
                  selected: _isValue(face, value),
                  label: _spokenNumber(
                    face,
                    strings: ExpressiveLocalizations.of(context),
                    is24Hour: _c.is24Hour,
                    number: value,
                  ),
                  onTap: () => _choose(face, value),
                  excludeSemantics: true,
                  child: label,
                )
              : label,
        );
      }
    }

    return Stack(
      children: <Widget>[
        ...ring(outer, TimePickerBehavior.outerCircleRadius),
        ...ring(inner, TimePickerBehavior.innerCircleRadius),
      ],
    );
  }

  /// The selector's handle centre for the current angle.
  Offset _handle() {
    final c = _c;
    final inner =
        c.is24Hour && c.isPm && c.selection == ExpressiveTimeSelection.hour;
    final length = inner
        ? TimePickerBehavior.innerCircleRadius
        : TimePickerBehavior.outerCircleRadius;
    final a = _angle.value;
    return Offset(
      _dialCentre + length * math.cos(a),
      _dialCentre + length * math.sin(a),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = widget.colors;
    final states = <WidgetState>{if (_dragging) WidgetState.dragged};
    final visual = t.timePickerTheme;
    final style = t.type
        .of(TimePickerTokens.clockDialLabelTextFont)
        .merge(visual.textStyle?.resolve(states));
    final fill = Color.alphaBlend(
      visual.overlayColor?.resolve(states) ?? expressiveTransparent,
      visual.backgroundColor?.resolve(states) ?? colors.dial,
    );
    final content =
        visual.foregroundColor?.resolve(states) ?? colors.dialContent;
    final selectedContent =
        visual.foregroundColor?.resolve({...states, WidgetState.selected}) ??
        colors.dialSelectedContent;
    final side =
        visual.side?.resolve(states) ??
        BorderSide.none.copyWith(color: visual.outline?.resolve(states));
    // Each number is its own button to assistive technology: the dial's
    // tap and drag are not actions of their own. The pointer shows the click
    // cursor over the whole dial, as over a slider: it is a value set by a
    // tap or a drag.
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTapUp: (d) => _onTap(d.localPosition),
        onPanStart: (d) {
          setState(() => _dragging = true);
          _drag = d.localPosition;
          _angle.stop();
        },
        onPanUpdate: (d) {
          _drag += d.delta;
          _setAt(_drag, tap: false);
        },
        onPanEnd: (_) {
          setState(() => _dragging = false);
          final wasHour = _c.selection == ExpressiveTimeSelection.hour;
          _springAngle();
          if (wasHour && widget.autoSwitchToMinute) {
            _c.selection = ExpressiveTimeSelection.minute;
          }
        },
        child: SizedBox.square(
          dimension: TimePickerTokens.clockDialContainerSize,
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[_angle, _fade]),
            builder: (context, _) {
              final handle = _handle();
              final fade = _fade.value.clamp(0.0, 1.0);
              final previous = _previousFace;
              Widget layer(Color color, {required bool semantics}) => Stack(
                children: <Widget>[
                  if (previous != null && fade < 1)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 1 - fade,
                        child: ExcludeSemantics(
                          child: _numbers(
                            previous,
                            style,
                            color,
                            semantics: false,
                          ),
                        ),
                      ),
                    ),
                  Positioned.fill(
                    child: Opacity(
                      opacity: fade,
                      child: _numbers(
                        _face,
                        style,
                        color,
                        semantics: semantics,
                      ),
                    ),
                  ),
                ],
              );
              return Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DialPainter(
                        dial: fill,
                        side: side,
                        trackWidth: TimePickerTokens
                            .clockDialSelectorTrackContainerWidth,
                        selector: colors.selector,
                        handle: handle,
                        angle: _angle.value,
                      ),
                    ),
                  ),
                  Positioned.fill(child: layer(content, semantics: true)),
                  Positioned.fill(
                    child: ExcludeSemantics(
                      child: ClipPath(
                        clipper: _HandleClip(handle),
                        child: layer(selectedContent, semantics: false),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// `ClockFace`'s background and `drawSelector`'s handle, track and centre
/// dot (the numbers under the handle are drawn again above it, clipped to
/// it, in the selected colour).
class _DialPainter extends CustomPainter {
  _DialPainter({
    required this.dial,
    required this.selector,
    required this.handle,
    required this.angle,
    required this.side,
    required this.trackWidth,
  });

  final Color dial;
  final Color selector;
  final Offset handle;
  final double angle;
  final BorderSide side;
  final double trackWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    canvas.drawCircle(center, size.shortestSide / 2, Paint()..color = dial);
    if (side.style != BorderStyle.none) {
      canvas.drawCircle(
        center,
        math.max(0, size.shortestSide / 2 - side.width / 2),
        side.toPaint(),
      );
    }
    final paint = Paint()..color = selector;
    canvas.drawCircle(handle, _handleRadius, paint);
    final end =
        handle -
        Offset(
          _handleRadius * math.cos(angle),
          _handleRadius * math.sin(angle),
        );
    canvas.drawLine(
      center,
      end,
      Paint()
        ..color = selector
        ..strokeWidth = trackWidth,
    );
    canvas.drawCircle(
      center,
      TimePickerTokens.clockDialSelectorCenterContainerSize / 2,
      paint,
    );
  }

  @override
  bool shouldRepaint(_DialPainter old) =>
      old.dial != dial ||
      old.selector != selector ||
      old.handle != handle ||
      old.angle != angle ||
      old.side != side ||
      old.trackWidth != trackWidth;
}

/// Clips to the selector's handle.
class _HandleClip extends CustomClipper<Path> {
  _HandleClip(this.handle);

  final Offset handle;

  @override
  Path getClip(Size size) =>
      Path()..addOval(Rect.fromCircle(center: handle, radius: _handleRadius));

  @override
  bool shouldReclip(_HandleClip old) => old.handle != handle;
}

// ---------------------------------------------------------------------------
// The time input.

/// Compose's `TimeInput`: the hour and minute as two fields — the one being
/// edited a text field taking two digits, the other a selector — with the
/// colon between them and the AM/PM toggle after them on the 12-hour clock.
/// An out-of-range value shows the field in the error colours with what
/// went wrong under it; two valid hour digits move on to the minutes.
class ExpressiveTimeInput extends StatelessWidget {
  /// A time input editing [controller].
  const ExpressiveTimeInput({
    required this.controller,
    this.vibrant = false,
    this.style,
    super.key,
  });

  /// Stateful paint, geometry and type overrides.
  final ExpressiveComponentThemeData? style;

  /// The time it edits.
  final ExpressiveTimePickerController controller;

  /// Whether it wears the vibrant fields (`TimeInput(shapes = …)`).
  final bool vibrant;

  @override
  Widget build(BuildContext context) => _TimePlate(
    style: style,
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final colors = _TimeColors.of(context.expressiveTheme, vibrant: vibrant);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final t = context.expressiveTheme;
        final style = vibrant
            ? t.type.displayLarge
            : t.type.of(TimeInputTokens.timeFieldLabelTextFont);
        final fieldHeight = vibrant
            ? TimePickerBehavior.vibrantFieldHeight
            : TimeInputTokens.timeFieldContainerHeight;
        return _PickerViewport(
          naturalHeight:
              fieldHeight + (vibrant ? 0 : _timeSupportingHeight(context)),
          naturalWidth: _timeInputWidth(
            vibrant: vibrant,
            is24Hour: controller.is24Hour,
          ),
          child: Semantics(
            explicitChildNodes: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _TimeField(
                        controller: controller,
                        selection: ExpressiveTimeSelection.hour,
                        colors: colors,
                        style: style,
                      ),
                      _Separator(
                        width: vibrant
                            ? TimePickerBehavior.vibrantSeparatorWidth
                            : TimePickerBehavior.separatorWidth,
                        // DisplaySeparator reads LocalTextStyle: the field's
                        // style, 72dp tall unless vibrant.
                        height: vibrant
                            ? fieldHeight
                            : TimeInputTokens.periodSelectorContainerHeight,
                        style: style,
                        color: colors.separator,
                      ),
                      _TimeField(
                        controller: controller,
                        selection: ExpressiveTimeSelection.minute,
                        colors: colors,
                        style: style,
                      ),
                    ],
                  ),
                ),
                if (!controller.is24Hour)
                  Padding(
                    padding: EdgeInsetsDirectional.only(
                      start: TimePickerBehavior.periodTogglePadding,
                    ),
                    child: _PeriodToggle(
                      controller: controller,
                      colors: colors,
                      horizontal: false,
                      width: vibrant
                          ? TimePickerBehavior.vibrantPeriodToggleWidth
                          : TimeInputTokens.periodSelectorContainerWidth,
                      height: vibrant
                          ? TimePickerBehavior.vibrantPeriodToggleHeight
                          : TimeInputTokens.periodSelectorContainerHeight,
                      gap: vibrant
                          ? TimePickerBehavior.vibrantPeriodTogglePadding
                          : TimePickerBehavior.periodTogglePadding,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// `TimePickerTextField`: while its value is being edited, a two-digit text
/// field on the focused container in an `outline` border (2dp while it has
/// the keyboard focus, 1dp otherwise); otherwise a
/// [_TimeSelector]. Under it (not on the vibrant fields, unless in error)
/// the supporting text, 7dp down, two lines tall.
/// Compose's `TimeInputTransformation` (`TimePicker.kt`) for one time
/// field: digits only (anything else reverts the edit), a digit typed into
/// a full field replaces its two digits (`isReplacingTwoDigits`), and an
/// edit that would leave more than two digits reverts and is rejected with
/// the platform's reject haptic (`TimeInputErrorHandler.onError`). A value
/// out of the hour's or minute's range is not rejected here: the field
/// shows it with its error text, as Compose does.
class _TimeDigitsFormatter extends TextInputFormatter {
  const _TimeDigitsFormatter();

  /// `MaxValueForTextField`'s two digits.
  static const int digits = 2;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (text.isEmpty) return newValue;
    if (!RegExp(r'^\d+$').hasMatch(text)) return oldValue;
    var selection = newValue.selection;
    if (oldValue.selection.isCollapsed &&
        oldValue.text.length == digits &&
        text.length == digits + 1) {
      // The typed digit is the one next to the caret; the old two go.
      final at = selection.start;
      if (at >= 1 && at <= digits + 1) {
        text = text.substring(at - 1, at);
        selection = TextSelection.collapsed(offset: text.length);
      }
    }
    if (text.length > digits) {
      _rejectTimeEntry();
      return oldValue;
    }
    return TextEditingValue(text: text, selection: selection);
  }
}

/// `TimeInputErrorHandler.onError` (material3 `TimePicker.android.kt`):
/// `HapticFeedbackType.Reject`. Flutter's error notification haptic is the
/// same constant on Android (`HapticFeedbackConstants.REJECT`, the engine's
/// `PlatformPlugin`, API 30 and up) and the iOS error notification
/// (`UINotificationFeedbackGenerator`, `.error`) on iOS — each platform's
/// own reject. Compose's accompanying `FX_KEYPRESS_INVALID` click has no
/// Flutter counterpart and is not played.
void _rejectTimeEntry() => unawaited(HapticFeedback.errorNotification());

class _TimeField extends StatefulWidget {
  const _TimeField({
    required this.controller,
    required this.selection,
    required this.colors,
    required this.style,
  });

  final ExpressiveTimePickerController controller;
  final ExpressiveTimeSelection selection;
  final _TimeColors colors;
  final TextStyle style;

  @override
  State<_TimeField> createState() => _TimeFieldState();
}

class _TimeFieldState extends State<_TimeField> {
  // `rememberTextFieldState(…, initialSelection = TextRange.Zero)`.
  late final TextEditingController _text = TextEditingController.fromValue(
    TextEditingValue(
      text: _two(_value),
      selection: const TextSelection.collapsed(offset: 0),
    ),
  );
  final FocusNode _focus = FocusNode();
  bool _valid = true;
  bool _hovered = false;
  late bool _wasSelected = _selected;

  bool get _isHour => widget.selection == ExpressiveTimeSelection.hour;

  int get _value =>
      _isHour ? widget.controller.hourForDisplay : widget.controller.minute;

  bool get _selected => widget.controller.selection == widget.selection;

  @override
  void initState() {
    super.initState();
    // The outline thickens with focus (2dp focused, 1dp otherwise).
    _focus.addListener(_focusChanged);
    // `LaunchedEffect(selection)`: the selected field takes the focus from
    // its first composition, not only when chosen later.
    if (_selected) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selected) _focus.requestFocus();
      });
    }
  }

  void _focusChanged() => setState(() {});

  @override
  void didUpdateWidget(_TimeField old) {
    super.didUpdateWidget(old);
    if (_valid && !_focus.hasFocus && _text.text != _two(_value)) {
      _text.text = _two(_value);
    }
    // Chosen for editing (a tap on its selector, or the hour's two digits
    // moving on): take the keyboard focus once the field is built.
    final selected = _selected;
    if (selected && !_wasSelected) {
      _text.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _text.text.length,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _selected) _focus.requestFocus();
      });
    }
    _wasSelected = selected;
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _inRange(int v) {
    if (!_isHour) return v >= 0 && v < Duration.minutesPerHour;
    return widget.controller.is24Hour
        ? v >= 0 && v < Duration.hoursPerDay
        : v >= 1 && v <= _half;
  }

  void _changed(String text) {
    final v = int.tryParse(text);
    final c = widget.controller;
    if (v == null) {
      setState(() => _valid = text.isEmpty);
      return;
    }
    final valid = _inRange(v);
    setState(() => _valid = valid);
    if (!valid) return;
    if (_isHour) {
      c.setDisplayHour(v);
      // `shouldSwitchFocusToMinute`: two valid digits move on.
      if (text.length == 2) c.selection = ExpressiveTimeSelection.minute;
    } else {
      c.minute = v;
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = widget.colors;
    final vibrant = colors.vibrant;
    final width = vibrant
        ? TimePickerBehavior.vibrantFieldWidth
        : TimeInputTokens.timeFieldContainerWidth;
    final height = vibrant
        ? TimePickerBehavior.vibrantFieldHeight
        : TimeInputTokens.timeFieldContainerHeight;
    final selected = _selected;
    final Widget box;
    if (!selected) {
      box = _TimeSelector(
        value: _value,
        selection: widget.selection,
        controller: widget.controller,
        colors: colors,
        width: width,
        height: height,
        style: widget.style,
        valid: _valid,
      );
    } else {
      final shape = vibrant
          ? t.shapes.of(ExpressiveShapeKey.cornerLarge)
          : t.shapes.of(TimeInputTokens.timeFieldContainerShape);
      final text = _valid ? colors.fieldSelectedContent : colors.error;
      final focused = _focus.hasFocus;
      // The whole box is the field: a tap above or below the digits
      // focuses it, as a tap anywhere on Compose's decorated
      // `BasicTextField` does; the digits' own tap wins where it lands.
      box = GestureDetector(
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        onTap: _focus.requestFocus,
        child: SizedBox(
          width: width,
          height: height,
          // The plate is the field's face (the editable inside is one line):
          // the checks read the field by it, beside the selector boxes.
          child: DesignKeylineFace(
            child: _TimeInputPlate(
              states: {
                WidgetState.selected,
                if (focused) WidgetState.focused,
                if (_hovered) WidgetState.hovered,
                if (!_valid) WidgetState.error,
              },
              shape: shape,
              color: _valid
                  ? colors.fieldSelectedContainer
                  : colors.errorContainer,
              side: _valid && vibrant && !focused
                  ? BorderSide.none
                  : BorderSide(
                      color: !_valid
                          ? colors.error
                          : vibrant
                          ? colors.primary
                          : colors.fieldBorder,
                      width: focused
                          ? TimeInputTokens.timeFieldFocusOutlineWidth
                          : OutlinedTextFieldTokens.outlineWidth,
                    ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _hovered = true),
                onExit: (_) => setState(() => _hovered = false),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final states = <WidgetState>{
                      WidgetState.selected,
                      if (focused) WidgetState.focused,
                      if (_hovered) WidgetState.hovered,
                      if (!_valid) WidgetState.error,
                    };
                    final visual = t.timePickerTheme;
                    final fieldStyle = widget.style
                        .merge(visual.textStyle?.resolve(states))
                        .copyWith(
                          color:
                              visual.foregroundColor?.resolve(states) ?? text,
                        );
                    // The digits by their capitals on the plate's middle, as
                    // the selector boxes' are.
                    return Center(
                      child: expressiveFaceLabel(
                        Material(
                          type: MaterialType.transparency,
                          child: TextField(
                            controller: _text,
                            focusNode: _focus,
                            decoration: null,
                            textAlign: TextAlign.center,
                            style: _fitPickerFieldStyle(
                              context,
                              fieldStyle,
                              constraints.biggest,
                            ),
                            cursorColor: _valid ? colors.primary : colors.error,
                            keyboardType: TextInputType.number,
                            textInputAction: _isHour
                                ? TextInputAction.next
                                : TextInputAction.done,
                            inputFormatters: const <TextInputFormatter>[
                              _TimeDigitsFormatter(),
                            ],
                            onChanged: _changed,
                            onSubmitted: (_) {
                              if (_isHour && _valid) {
                                widget.controller.selection =
                                    ExpressiveTimeSelection.minute;
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );
    }
    final showSupporting = !vibrant || !_valid;
    final supporting = !_valid
        ? (_isHour
              ? ExpressiveLocalizations.of(context).badHour
              : ExpressiveLocalizations.of(context).badMinute)
        : (_isHour
              ? ExpressiveLocalizations.of(context).hour
              : ExpressiveLocalizations.of(context).minute);
    return SizedBox(
      width: width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Semantics(
            label: _isHour
                ? ExpressiveLocalizations.of(context).hour
                : ExpressiveLocalizations.of(context).minute,
            child: box,
          ),
          if (showSupporting)
            Padding(
              padding: const EdgeInsets.only(
                top: TimePickerBehavior.supportingTextTop,
              ),
              // One style for the label and the two-line reserve.
              child: DefaultTextStyle(
                style: t.type
                    .of(TimeInputTokens.timeFieldSupportingTextFont)
                    .merge(
                      t.timePickerTheme.textStyle?.resolve({
                        if (!_valid) WidgetState.error,
                      }),
                    )
                    .copyWith(
                      color:
                          t.timePickerTheme.foregroundColor?.resolve({
                            if (!_valid) WidgetState.error,
                          }) ??
                          (_valid ? colors.supporting : colors.error),
                    ),
                overflow: TextOverflow.ellipsis,
                child: Semantics(
                  liveRegion: !_valid,
                  // `minLines = 2`: the label always keeps two lines' height.
                  child: Stack(
                    children: <Widget>[
                      const ExcludeSemantics(
                        child: Visibility.maintain(
                          visible: false,
                          child: Text('\n'),
                        ),
                      ),
                      Text(supporting, maxLines: 2),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The scroll field and the time scroll.

/// Compose's `ScrollField` (CONTRACT §4.1's number scroll field): a
/// vertically paged wheel of [itemCount] numbers that wraps around, a third
/// of [ScrollFieldBehavior.height] a number, the centred one selected —
/// drawn larger and in `onSurface` as it springs in, the others in
/// `outline` — on the lowest container with the large corner. A fling
/// snaps to a number, a tap on one springs it to the centre, the arrow keys
/// step it. A pointer, a drag or the keyboard's focus lays the `onSurface`
/// state layer on the container, and the keyboard's focus rings it.
/// [onChanged] reports the selected index.
class ExpressiveScrollField extends StatefulWidget {
  /// A wheel of [itemCount] numbers showing [value].
  const ExpressiveScrollField({
    required this.itemCount,
    required this.value,
    this.onChanged,
    this.label,
    this.itemLabel,
    this.spokenItem,
    this.width,
    this.height = ScrollFieldBehavior.height,
    this.style,
    super.key,
  }) : assert(itemCount > 0),
       _looping = true,
       _words = false;

  /// Whether the wheel wraps round from its last item to its first: always,
  /// as Compose's does.
  final bool _looping;

  /// Whether the items are words, drawn in the title and headline type
  /// rather than the display type of numbers: never, for numbers.
  final bool _words;

  /// Stateful paint, geometry and type overrides.
  final ExpressiveComponentThemeData? style;

  /// How many numbers the wheel holds (0 … itemCount − 1).
  final int itemCount;

  /// The selected index.
  final int value;

  /// Called with the index the wheel settles on; disabled when null.
  final ValueChanged<int>? onChanged;

  /// What the wheel is called to assistive technology.
  final String? label;

  /// The number printed for an index; two digits of the index when null.
  final String Function(int index)? itemLabel;

  /// What a screen reader reads for an index; [itemLabel]'s when null.
  final String Function(int index)? spokenItem;

  /// The wheel's width; its parent's when null.
  final double? width;

  /// The wheel's height.
  final double height;

  @override
  State<ExpressiveScrollField> createState() => _ExpressiveScrollFieldState();
}

class _ExpressiveScrollFieldState extends State<ExpressiveScrollField> {
  /// Pages enough to feel endless (Compose's pager counts `Int.MAX_VALUE`;
  /// far fewer here, as fractional pages add up past the sliver's
  /// precision), a multiple of 12, 24 and 60 so both ends wrap evenly.
  static const int _pages = 1200;
  bool _focused = false;
  bool _hovered = false;
  bool _dragged = false;

  /// Numbers a [ScrollFieldBehavior.height] shows.
  static const int _visible = 3;

  late int _page = _initialPage(widget.value);
  late PageController _controller = _make();

  /// Whether the keyboard drives: the ring shows for its focus alone. Read
  /// when built, as ExpressivePressable reads it.
  bool get _keyboard =>
      FocusManager.instance.highlightMode == FocusHighlightMode.traditional;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addHighlightModeListener(_modeChanged);
  }

  void _modeChanged(FocusHighlightMode mode) {
    if (mounted) setState(() {});
  }

  int get _pageCount => widget._looping ? _pages : widget.itemCount;

  int _initialPage(int index) => widget._looping
      ? _pages ~/ 2 - (_pages ~/ 2 % widget.itemCount) + index
      : index.clamp(0, widget.itemCount - 1);

  PageController _make() => PageController(
    initialPage: _page,
    viewportFraction: ScrollFieldBehavior.height / _visible / widget.height,
  );

  @override
  void didUpdateWidget(ExpressiveScrollField old) {
    super.didUpdateWidget(old);
    if (old.height != widget.height ||
        old.itemCount != widget.itemCount ||
        old._looping != widget._looping) {
      _page = _initialPage(widget.value % widget.itemCount);
      _controller.dispose();
      _controller = _make();
      return;
    }
    final current = _page % widget.itemCount;
    if (widget.value != current &&
        _controller.hasClients &&
        !_controller.position.isScrollingNotifier.value) {
      _page += widget.value - current;
      _controller.jumpToPage(_page);
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_modeChanged);
    _controller.dispose();
    super.dispose();
  }

  void _springTo(int page) {
    if (page < 0 || page >= _pageCount) return;
    _springToPage(
      context,
      _controller,
      page,
      ExpressiveMotionKey.defaultSpatial,
    );
  }

  String _label(int index) => widget.itemLabel?.call(index) ?? _two(index);

  String _spoken(int index) => widget.spokenItem?.call(index) ?? _label(index);

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final enabled = widget.onChanged != null;
    final motion = ExpressiveMotion.of(context);
    final index = _page % widget.itemCount;
    final canIncrease = widget._looping || _page < _pageCount - 1;
    final canDecrease = widget._looping || _page > 0;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_focused && _keyboard) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
      if (_dragged) WidgetState.dragged,
    };
    final visual = _pickerControlStyle(t.timePickerTheme).merge(widget.style);
    final shape =
        visual.shape?.resolve(states) ??
        t.shapes.of(ExpressiveShapeKey.cornerLarge);
    // A pointer, the keyboard's focus or a drag lays the `onSurface` state
    // layer on the container (a style's own overlay replaces it), and the
    // keyboard's focus rings it: a wheel the arrow keys turn shows it has
    // them.
    final container = !enabled
        ? _DateColors.faded(c.surfaceContainerLowest)
        : visual.overlayColor != null
        ? c.surfaceContainerLowest
        : t.states.composite(c.surfaceContainerLowest, c.onSurface, states);
    final ring =
        states.contains(WidgetState.focused) &&
        !states.contains(WidgetState.disabled);
    return Semantics(
      label: widget.label,
      value: _spoken(index),
      enabled: enabled,
      increasedValue: canIncrease
          ? _spoken((index + 1) % widget.itemCount)
          : null,
      decreasedValue: canDecrease
          ? _spoken((index - 1) % widget.itemCount)
          : null,
      onIncrease: enabled && canIncrease ? () => _springTo(_page + 1) : null,
      onDecrease: enabled && canDecrease ? () => _springTo(_page - 1) : null,
      child: ExcludeSemantics(
        child: Focus(
          canRequestFocus: enabled,
          onFocusChange: (value) => setState(() => _focused = value),
          onKeyEvent: (node, event) {
            if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
              return KeyEventResult.ignored;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
              _springTo(_page + 1);
              return KeyEventResult.handled;
            }
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              _springTo(_page - 1);
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: CustomPaint(
              foregroundPainter: ring
                  ? _WheelRing(
                      shape: shape,
                      color: c.secondary,
                      thickness: 3,
                      textDirection: Directionality.maybeOf(context),
                    )
                  : null,
              child: ExpressiveStyleScope(
                style: visual,
                states: states,
                inset: EdgeInsets.zero,
                child: ExpressiveSurface(
                  componentStyle: visual,
                  states: states,
                  shape: shape,
                  color: container,
                  padding: const EdgeInsets.symmetric(
                    horizontal: ExpressiveSpacing.s16,
                  ),
                  child: MouseRegion(
                    // A value set by a drag or a tap on a number: the click
                    // cursor over the whole field, as over a slider.
                    cursor: enabled
                        ? SystemMouseCursors.click
                        : MouseCursor.defer,
                    onEnter: (_) => setState(() => _hovered = true),
                    onExit: (_) => setState(() => _hovered = false),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notice) {
                        if (notice is ScrollStartNotification &&
                            notice.dragDetails != null) {
                          setState(() => _dragged = true);
                        } else if (notice is ScrollEndNotification &&
                            _dragged) {
                          setState(() => _dragged = false);
                        }
                        return false;
                      },
                      child: PageView.builder(
                        // A new controller (looping, height or count changed)
                        // starts at its own page: a kept scrollable would
                        // carry the old offset into it.
                        key: ObjectKey(_controller),
                        controller: _controller,
                        scrollDirection: Axis.vertical,
                        physics: enabled
                            ? _SpringPagePhysics(motion.defaultSpatial)
                            : const NeverScrollableScrollPhysics(),
                        onPageChanged: (page) {
                          setState(() => _page = page);
                          widget.onChanged?.call(page % widget.itemCount);
                        },
                        itemCount: _pageCount,
                        itemBuilder: (context, page) => GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: enabled ? () => _springTo(page) : null,
                          child: Center(
                            child: _ScrollItem(
                              text: _label(page % widget.itemCount),
                              selected: page == _page,
                              enabled: enabled,
                              words: widget._words,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The wheel's focus ring: the M3 focus indicator, [thickness] in `secondary`
/// 2dp out from [shape], as ExpressiveStateFace draws it.
class _WheelRing extends CustomPainter {
  const _WheelRing({
    required this.shape,
    required this.color,
    required this.thickness,
    required this.textDirection,
  });

  final OutlinedBorder shape;
  final Color color;
  final double thickness;
  final TextDirection? textDirection;

  @override
  void paint(Canvas canvas, Size size) => expressivePaintFocusRing(
    canvas,
    Offset.zero & size,
    shape,
    color: color,
    thickness: thickness,
    offset: 2,
    textDirection: textDirection,
  );

  @override
  bool shouldRepaint(_WheelRing old) =>
      old.shape != shape ||
      old.color != color ||
      old.thickness != thickness ||
      old.textDirection != textDirection;
}

/// `ScrollFieldDefaults.Item`: two digits, springing on the fast spatial
/// spring between `displayMedium` in `outline` and
/// `displayLargeEmphasized` in `onSurface` as it is selected.
class _ScrollItem extends StatelessWidget {
  const _ScrollItem({
    required this.text,
    required this.selected,
    required this.enabled,
    this.words = false,
  });

  final String text;
  final bool selected;
  final bool enabled;

  /// Words, not numbers: `titleLarge` springing to
  /// `headlineSmallEmphasized`.
  final bool words;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final c = t.colors;
    final target = switch ((enabled, selected)) {
      (true, true) => c.onSurface,
      (true, false) => c.outline,
      (false, _) => _DateColors.faded(c.onSurface),
    };
    final scope = ExpressiveStyleScope.maybeOf(context)!;
    final states = {...scope.states, if (selected) WidgetState.selected};
    final visual = scope.style;
    return ExpressiveSpringValue(
      value: selected ? 1 : 0,
      motion: ExpressiveMotionKey.fastSpatial,
      builder: (context, fraction, _) => ExpressiveSpringColor(
        value: visual.foregroundColor?.resolve(states) ?? target,
        motion: ExpressiveMotionKey.fastEffects,
        builder: (context, color, _) => DefaultTextStyle.merge(
          style: TextStyle.lerp(
            words ? t.type.titleLarge : t.type.displayMedium,
            words
                ? t.type.headlineSmallEmphasized
                : t.type.displayLargeEmphasized,
            fraction.clamp(0.0, 1.0),
          )!.merge(visual.textStyle?.resolve(states)).copyWith(color: color),
          child: _PickerLabel(text),
        ),
      ),
    );
  }
}

/// Compose's `TimeScroll`: the hour and minute as two
/// [ExpressiveScrollField]s (100 × 120dp) with the colon between them and
/// the vibrant AM/PM toggle after them on the 12-hour clock.
class ExpressiveTimeScroll extends StatelessWidget {
  /// A time scroll editing [controller].
  const ExpressiveTimeScroll({required this.controller, this.style, super.key});

  /// Stateful paint, geometry and type overrides.
  final ExpressiveComponentThemeData? style;

  /// The time it edits.
  final ExpressiveTimePickerController controller;

  @override
  Widget build(BuildContext context) => _TimePlate(
    style: style,
    child: Builder(builder: _buildPicker),
  );

  Widget _buildPicker(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = _TimeColors.of(t, vibrant: true);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final c = controller;
        final hourCount = c.is24Hour ? Duration.hoursPerDay : _half;
        // 12-hour: index 0 is 1 o'clock, 11 is 12.
        final hourIndex = c.is24Hour ? c.hour : c.hourForDisplay - 1;
        const height = TimePickerBehavior.vibrantFieldHeight;
        return _PickerViewport(
          naturalHeight: height,
          naturalWidth:
              TimePickerBehavior.scrollFieldWidth * 2 +
              TimePickerBehavior.vibrantSeparatorWidth +
              (c.is24Hour
                  ? 0
                  : TimePickerBehavior.vibrantPeriodTogglePadding +
                        TimePickerBehavior.vibrantPeriodToggleWidth),
          child: Semantics(
            explicitChildNodes: true,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      ExpressiveScrollField(
                        itemCount: hourCount,
                        value: hourIndex,
                        width: TimePickerBehavior.scrollFieldWidth,
                        height: height,
                        label: ExpressiveLocalizations.of(context).selectHour,
                        itemLabel: (i) => _two(c.is24Hour ? i : i + 1),
                        spokenItem: (i) => _spokenNumber(
                          ExpressiveTimeSelection.hour,
                          strings: ExpressiveLocalizations.of(context),
                          is24Hour: c.is24Hour,
                          number: c.is24Hour ? i : i + 1,
                        ),
                        onChanged: (i) =>
                            c.setDisplayHour(c.is24Hour ? i : i + 1),
                      ),
                      _Separator(
                        width: TimePickerBehavior.vibrantSeparatorWidth,
                        height: height,
                        style: t.type.displayLarge,
                        color: colors.separator,
                      ),
                      ExpressiveScrollField(
                        itemCount: Duration.minutesPerHour,
                        value: c.minute,
                        width: TimePickerBehavior.scrollFieldWidth,
                        height: height,
                        label: ExpressiveLocalizations.of(context).selectMinute,
                        spokenItem: (i) => _spokenNumber(
                          ExpressiveTimeSelection.minute,
                          strings: ExpressiveLocalizations.of(context),
                          is24Hour: c.is24Hour,
                          number: i,
                        ),
                        onChanged: (i) => c.minute = i,
                      ),
                    ],
                  ),
                ),
                if (!c.is24Hour)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: TimePickerBehavior.vibrantPeriodTogglePadding,
                    ),
                    child: _PeriodToggle(
                      controller: c,
                      colors: colors,
                      horizontal: false,
                      width: TimePickerBehavior.vibrantPeriodToggleWidth,
                      height: TimePickerBehavior.vibrantPeriodToggleHeight,
                      gap: TimePickerBehavior.vibrantPeriodTogglePadding,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// The time picker dialogs.

/// Which face a time picker dialog shows (Compose's
/// `TimePickerDisplayMode`).
enum ExpressiveTimePickerMode {
  /// The dial ([ExpressiveTimePicker]).
  dial,

  /// The typed fields ([ExpressiveTimeInput]).
  input,

  /// The scroll fields ([ExpressiveTimeScroll]).
  scroll,
}

/// `TimePickerDialogDefaults.DisplayModeToggle`: the icon button in a time
/// picker dialog's action row that switches between the dial (or, with
/// [scroll], the scroll fields) and typing.
class ExpressiveTimePickerModeToggle extends StatelessWidget {
  /// A toggle in [mode] that reports a switch through [onChanged].
  const ExpressiveTimePickerModeToggle({
    required this.mode,
    required this.onChanged,
    this.scroll = false,
    this.style,
    super.key,
  });

  /// The face shown.
  final ExpressiveTimePickerMode mode;

  /// Called with the face to switch to.
  final ValueChanged<ExpressiveTimePickerMode> onChanged;

  /// Whether the other face is the scroll fields rather than the dial.
  final bool scroll;

  /// Visual overrides for the icon button.
  final ExpressiveComponentThemeData? style;

  @override
  Widget build(BuildContext context) {
    final typing = mode == ExpressiveTimePickerMode.input;
    final other = scroll
        ? ExpressiveTimePickerMode.scroll
        : ExpressiveTimePickerMode.dial;
    final label = typing
        ? (scroll
              ? ExpressiveLocalizations.of(context).toScroll
              : ExpressiveLocalizations.of(context).toDial)
        : ExpressiveLocalizations.of(context).toKeyboard;
    return ExpressiveIconButton(
      typing
          ? (scroll ? ExpressiveSymbols.unfoldMore : ExpressiveSymbols.schedule)
          : ExpressiveSymbols.keyboard,
      style: style,
      semanticLabel: label,
      tooltip: label,
      onPressed: () =>
          onChanged(typing ? other : ExpressiveTimePickerMode.input),
    );
  }
}

/// Compose's `TimePickerDialog` (and, [vibrant], `VibrantTimePickerDialog`):
/// [child] (a time picker, time input or time scroll) on the dialog's
/// container, the [title] above it (not on the vibrant dialog), and the
/// action row under it — the [modeToggle] at its start, then [dismiss] and
/// [confirm] at its end, 8dp apart. The dialog is as wide as its content
/// plus 24dp either side (12dp, vibrant).
class ExpressiveTimePickerDialog extends StatelessWidget {
  /// A time picker dialog around [child] with [confirm] and an optional [dismiss] action.
  const ExpressiveTimePickerDialog({
    required this.child,
    required this.confirm,
    this.dismiss,
    this.title,
    this.modeToggle,
    this.vibrant = false,
    this.style,
    super.key,
  });

  /// Stateful paint, geometry and type overrides.
  final ExpressiveComponentThemeData? style;

  /// The time picker.
  final Widget child;

  /// The confirm action (a text button, "OK").
  final Widget confirm;

  /// The dismiss action (a text button, "Cancel").
  final Widget? dismiss;

  /// The title ("Select time"); none on the vibrant dialog.
  final String? title;

  /// The mode toggle at the action row's start.
  final Widget? modeToggle;

  /// Whether it is the vibrant dialog.
  final bool vibrant;

  @override
  Widget build(BuildContext context) => ExpressiveTheme(
    data: context.expressiveTheme.copyWith(
      timePickerTheme: context.expressiveTheme.timePickerTheme.merge(style),
    ),
    child: Builder(builder: _buildDialog),
  );

  Widget _buildDialog(BuildContext context) {
    final t = context.expressiveTheme;
    final pad = vibrant
        ? TimePickerDialogBehavior.vibrantPadding
        : TimePickerDialogBehavior.contentPadding;
    return IntrinsicWidth(
      child: ExpressiveSurface(
        style: style,
        componentStyle: t.timePickerTheme,
        shape: t.shapes.of(TimePickerTokens.containerShape),
        color: vibrant
            ? t.colors.surfaceContainer
            : t.colors.role(TimePickerTokens.containerColor),
        contentColor: t.colors.onSurface,
        tonalElevation: TimePickerTokens.containerElevation,
        child: Padding(
          padding: EdgeInsets.all(pad),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (!vibrant && title != null)
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: TimePickerDialogBehavior.titleBottomPadding,
                  ),
                  child: Text(
                    title!,
                    style: t.type
                        .of(TimePickerTokens.headlineFont)
                        .merge(t.timePickerTheme.textStyle?.resolve({}))
                        .copyWith(
                          color:
                              t.timePickerTheme.foregroundColor?.resolve({}) ??
                              t.colors.role(TimePickerTokens.headlineColor),
                        ),
                  ),
                ),
              Flexible(
                child: SingleChildScrollView(child: Center(child: child)),
              ),
              if (vibrant)
                const SizedBox(height: TimePickerDialogBehavior.vibrantPadding),
              _TimeDialogActions(
                hasModeToggle: modeToggle != null,
                spacing: TimePickerDialogBehavior.actionsSpacing,
                children: <Widget>[
                  ?modeToggle,
                  const Spacer(),
                  ?dismiss,
                  confirm,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Keep the native Row's measurement and offsets whenever it fits. On a narrow
// surface, stack the actions instead of letting the spacer's row overflow.
class _TimeDialogActions extends Flex {
  const _TimeDialogActions({
    required this.hasModeToggle,
    required super.spacing,
    required super.children,
  }) : super(direction: Axis.horizontal);

  final bool hasModeToggle;

  @override
  RenderFlex createRenderObject(BuildContext context) =>
      _RenderTimeDialogActions(
        hasModeToggle,
        spacing: spacing,
        textDirection: Directionality.of(context),
      );

  @override
  void updateRenderObject(BuildContext context, RenderFlex renderObject) {
    super.updateRenderObject(context, renderObject);
    (renderObject as _RenderTimeDialogActions).hasModeToggle = hasModeToggle;
  }
}

class _RenderTimeDialogActions extends RenderFlex {
  _RenderTimeDialogActions(
    this._hasModeToggle, {
    required super.spacing,
    required super.textDirection,
  }) : super(direction: Axis.horizontal);

  bool _hasModeToggle;
  set hasModeToggle(bool value) {
    if (_hasModeToggle == value) return;
    _hasModeToggle = value;
    markNeedsLayout();
  }

  bool _fits(BoxConstraints constraints) {
    var width = spacing * math.max(0, childCount - 1);
    RenderBox? child = firstChild;
    while (child != null) {
      final data = child.parentData! as FlexParentData;
      if ((data.flex ?? 0) == 0) {
        width += child.getMaxIntrinsicWidth(constraints.maxHeight);
      }
      child = data.nextSibling;
    }
    return width <= constraints.maxWidth;
  }

  Size _stack(BoxConstraints constraints, {required bool dry}) {
    final childConstraints = BoxConstraints(maxWidth: constraints.maxWidth);
    var height = 0.0;
    var count = 0;
    RenderBox? child = firstChild;
    while (child != null) {
      final data = child.parentData! as FlexParentData;
      if ((data.flex ?? 0) > 0) {
        if (!dry) child.layout(BoxConstraints.tight(Size.zero));
      } else {
        final Size childSize;
        if (dry) {
          childSize = child.getDryLayout(childConstraints);
        } else {
          child.layout(childConstraints, parentUsesSize: true);
          childSize = child.size;
        }
        if (count > 0) height += spacing;
        if (!dry) {
          final atStart = _hasModeToggle && count == 0;
          final left = atStart == (textDirection == TextDirection.ltr);
          data.offset = Offset(
            left ? 0 : constraints.maxWidth - childSize.width,
            height,
          );
        }
        height += childSize.height;
        count++;
      }
      child = data.nextSibling;
    }
    return constraints.constrain(Size(constraints.maxWidth, height));
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) => _fits(constraints)
      ? super.computeDryLayout(constraints)
      : _stack(constraints, dry: true);

  @override
  void performLayout() {
    if (_fits(constraints)) {
      super.performLayout();
    } else {
      size = _stack(constraints, dry: false);
    }
  }
}

/// Raises a time picker in an [ExpressiveTimePickerDialog] and resolves to
/// the time confirmed with OK, or null when cancelled. [initialMode] picks
/// the face (the dialog's toggle switches to typing and back); [vibrant]
/// the vibrant dialog (always so for the scroll face); [is24Hour] follows
/// the platform's setting when null.
Future<({int hour, int minute})?> showExpressiveTimePicker({
  required BuildContext context,
  int initialHour = 0,
  int initialMinute = 0,
  bool? is24Hour,
  bool vibrant = false,
  ExpressiveTimePickerMode initialMode = ExpressiveTimePickerMode.dial,
  ExpressiveComponentThemeData? style,
  String? confirmLabel,
  String? dismissLabel,
}) {
  final strings = ExpressiveLocalizations.of(context);
  final controller = ExpressiveTimePickerController(
    hour: initialHour,
    minute: initialMinute,
    is24Hour: is24Hour ?? MediaQuery.alwaysUse24HourFormatOf(context),
  );
  final scroll = initialMode == ExpressiveTimePickerMode.scroll;
  final isVibrant = vibrant || scroll;
  var mode = initialMode;
  return showExpressiveDialog<({int hour, int minute})>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, update) => ExpressiveTimePickerDialog(
        style: style,
        vibrant: isVibrant,
        title: mode == ExpressiveTimePickerMode.input
            ? ExpressiveLocalizations.of(context).enterTime
            : ExpressiveLocalizations.of(context).selectTime,
        modeToggle: ExpressiveTimePickerModeToggle(
          mode: mode,
          scroll: scroll,
          onChanged: (m) => update(() => mode = m),
        ),
        dismiss: ExpressiveTextButton(
          dismissLabel ?? strings.cancel,
          onPressed: () => Navigator.of(context).pop(),
        ),
        confirm: ExpressiveTextButton(
          confirmLabel ?? strings.ok,
          onPressed: () =>
              Navigator.of(context)
                  .pop((hour: controller.hour, minute: controller.minute)),
        ),
        child: switch (mode) {
          ExpressiveTimePickerMode.dial => ExpressiveTimePicker(
            style: style,
            controller: controller,
            vibrant: isVibrant,
            layout: ExpressiveTimePickerLayout.vertical,
          ),
          ExpressiveTimePickerMode.input => ExpressiveTimeInput(
            style: style,
            controller: controller,
            vibrant: isVibrant,
          ),
          ExpressiveTimePickerMode.scroll => ExpressiveTimeScroll(
            style: style,
            controller: controller,
          ),
        },
      ),
    ),
  ).whenComplete(controller.dispose);
}

// A picker plate owns its padding, minimum size and shape. Its private controls
// keep role-specific geometry while sharing stateful paint and type overrides.
ExpressiveComponentThemeData _pickerControlStyle(
  ExpressiveComponentThemeData style,
) => ExpressiveComponentThemeData(
  backgroundColor: style.backgroundColor,
  foregroundColor: style.foregroundColor,
  outline: style.outline,
  overlayColor: style.overlayColor,
  side: style.side,
  textStyle: style.textStyle,
  iconSize: style.iconSize,
);

// Native picker plates were unclipped. Adding an anti-aliased rectangle clips
// the scroll fields' edge pixels twice; only an explicit outline needs a mask.
Clip _pickerPlateClip(
  BuildContext context,
  ExpressiveComponentThemeData style,
) => style.shape?.resolve(const <WidgetState>{}) != null
    ? Clip.antiAlias
    : Clip.none;

// Calendar and clock layouts have a known minimum width. They pan inside a
// narrow surface instead of overlapping 48dp actions or clipping their labels.
class _PickerViewport extends StatelessWidget {
  const _PickerViewport({
    required this.naturalWidth,
    required this.naturalHeight,
    required this.child,
    this.minimumWidth,
  });
  final double naturalWidth;
  final double naturalHeight;
  // A calendar can give up its outer margin before it needs to pan. In
  // particular, the native 358dp gallery plate must not become a 360dp canvas.
  final double? minimumWidth;
  final Widget child;
  @override
  Widget build(BuildContext context) => _PickerWidth(
    width: naturalWidth,
    height: naturalHeight,
    child: LayoutBuilder(
      builder: (context, constraints) =>
          constraints.maxWidth < (minimumWidth ?? naturalWidth)
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: naturalWidth, child: child),
            )
          : child,
    ),
  );
}

class _PickerWidth extends SingleChildRenderObjectWidget {
  const _PickerWidth({
    required this.width,
    required this.height,
    required super.child,
  });
  final double width;
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderPickerWidth(width, height);
  @override
  void updateRenderObject(
    BuildContext context,
    _RenderPickerWidth renderObject,
  ) {
    renderObject
      ..width = width
      ..height = height;
  }
}

class _RenderPickerWidth extends RenderProxyBox {
  _RenderPickerWidth(this._width, this._height);
  double _width;
  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;
  @override
  double computeMaxIntrinsicWidth(double height) => _width;
  @override
  double computeMinIntrinsicHeight(double width) => _height;
  @override
  double computeMaxIntrinsicHeight(double width) => _height;
}

/// The previous month's arrow: Compose's auto-mirrored KeyboardArrowLeft,
/// pointing back against the reading direction.
IconData _monthBack(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? ExpressiveSymbols.keyboardArrowRight
    : ExpressiveSymbols.keyboardArrowLeft;

/// The next month's arrow, pointing on with the reading direction.
IconData _monthOn(BuildContext context) =>
    Directionality.of(context) == TextDirection.rtl
    ? ExpressiveSymbols.keyboardArrowLeft
    : ExpressiveSymbols.keyboardArrowRight;

// Keep fixed calendar cells stable, fitting only text that would cross their
// outline. Default-size labels that already fit retain their exact text scale.
class _PickerLabel extends StatelessWidget {
  const _PickerLabel(
    this.text, {
    this.shape,
    this.textAlign = TextAlign.start,
    this.singleLine = true,
    this.fitAs,
  });
  final String text;
  final ShapeBorder? shape;
  final TextAlign textAlign;
  final bool singleLine;

  /// A sibling's widest text this one fits as, so a grid's labels shrink
  /// together (a month's 1 and 30 print at one size at large text).
  final String? fitAs;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final shape = this.shape;
      // A number or a period on its cell's face, centred by its capitals.
      final child = expressiveFaceLabel(
        Text(
          text,
          textAlign: textAlign,
          maxLines: singleLine ? 1 : null,
          softWrap: singleLine ? false : null,
          overflow: singleLine ? TextOverflow.visible : null,
        ),
      );
      if (shape == null) return FittedBox(fit: BoxFit.scaleDown, child: child);
      Size measure(String text) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: DefaultTextStyle.of(context).style),
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        )..layout();
        final size = painter.size;
        painter.dispose();
        return size;
      }

      final own = measure(text);
      final widest = fitAs == null ? own : measure(fitAs!);
      final measured = Size(
        math.max(own.width, widest.width),
        math.max(own.height, widest.height),
      );
      final size = constraints.biggest;
      final bounds = Offset.zero & size;
      final direction = Directionality.of(context);
      // The native rounded outline has an exact Dart containment check.
      // Avoid repeated renderer path calls for every calendar number.
      final contains = switch (shape) {
        ExpressiveCornerBorder() =>
          shape
              .radiiOn(bounds, direction)
              .toRRect(bounds)
              .scaleRadii()
              .contains,
        RoundedRectangleBorder() =>
          shape.borderRadius
              .resolve(direction)
              .toRRect(bounds)
              .scaleRadii()
              .contains,
        _ => shape.getOuterPath(bounds, textDirection: direction).contains,
      };
      bool fits(double scale) {
        final rect = Rect.fromCenter(
          center: size.center(Offset.zero),
          width: measured.width * scale,
          height: measured.height * scale,
        ).deflate(.001);
        return [
          rect.topLeft,
          rect.topCenter,
          rect.topRight,
          rect.centerLeft,
          rect.centerRight,
          rect.bottomLeft,
          rect.bottomCenter,
          rect.bottomRight,
        ].every(contains);
      }

      var high = math.min(
        1.0,
        math.min(size.width / measured.width, size.height / measured.height),
      );
      if (!fits(high)) {
        var low = 0.0;
        for (var i = 0; i < 20; i++) {
          final middle = (low + high) / 2;
          if (fits(middle)) {
            low = middle;
          } else {
            high = middle;
          }
        }
        high = low;
      }
      if (high == 1) return Center(child: child);
      return Center(
        child: SizedBox(
          width: own.width * high,
          height: own.height * high,
          child: FittedBox(fit: BoxFit.contain, child: child),
        ),
      );
    },
  );
}

// A typed field uses ShapeDecoration's interior paint, as the native input did:
// it keeps an opaque border from blending twice with the fill at curved edges.
class _TimeInputPlate extends StatelessWidget {
  const _TimeInputPlate({
    required this.child,
    required this.shape,
    required this.color,
    required this.side,
    required this.states,
  });
  final Widget child;
  final OutlinedBorder shape;
  final Color color;
  final BorderSide side;
  final Set<WidgetState> states;

  @override
  Widget build(BuildContext context) {
    final theme = context.expressiveTheme;
    final style = _pickerControlStyle(theme.timePickerTheme);
    final outline = style.outline?.resolve(states);
    final side =
        style.side?.resolve(states) ??
        this.side.copyWith(
          color: outline,
          style: outline == null ? null : BorderStyle.solid,
        );
    final shape = this.shape.copyWith(side: side);
    final fill = Color.alphaBlend(
      style.overlayColor?.resolve(states) ?? expressiveTransparent,
      style.backgroundColor?.resolve(states) ?? color,
    );
    final customOutline =
        style.side?.resolve(states) != null || outline != null;
    return DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: customOutline
          ? ClipPath(
              clipper: ShapeBorderClipper(
                shape: shape,
                textDirection: Directionality.of(context),
              ),
              child: Padding(padding: shape.dimensions, child: child),
            )
          : child,
    );
  }
}

class _TimePlate extends StatelessWidget {
  const _TimePlate({required this.child, this.style});
  final Widget child;
  final ExpressiveComponentThemeData? style;
  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final merged = t.timePickerTheme.merge(style);
    return ExpressiveTheme(
      data: t.copyWith(timePickerTheme: merged),
      child: ExpressiveSurface(
        componentStyle: merged,
        shape: t.shapes.of(ExpressiveShapeKey.cornerNone),
        clipBehavior: _pickerPlateClip(context, merged),
        color: expressiveTransparent,
        child: child,
      ),
    );
  }
}

double _timeDisplayWidth({
  required bool vibrant,
  required bool horizontal,
  required bool is24Hour,
}) {
  final field = vibrant
      ? (!horizontal && is24Hour
            ? TimePickerBehavior.vibrantFieldWidthPortrait
            : TimePickerBehavior.vibrantFieldWidth)
      : TimePickerTokens.timeSelectorContainerWidth;
  return field * 2 +
      (vibrant
          ? TimePickerBehavior.vibrantSeparatorWidth
          : TimePickerBehavior.separatorWidth) +
      (is24Hour || horizontal
          ? 0
          : (vibrant
                ? TimePickerBehavior.vibrantPeriodToggleLargePadding +
                      TimePickerBehavior.vibrantPeriodToggleWidth
                : TimePickerBehavior.periodTogglePadding +
                      TimePickerTokens.periodSelectorVerticalContainerWidth));
}

double _timeInputWidth({required bool vibrant, required bool is24Hour}) =>
    (vibrant
            ? TimePickerBehavior.vibrantFieldWidth
            : TimeInputTokens.timeFieldContainerWidth) *
        2 +
    (vibrant
        ? TimePickerBehavior.vibrantSeparatorWidth
        : TimePickerBehavior.separatorWidth) +
    (is24Hour
        ? 0
        : TimePickerBehavior.periodTogglePadding +
              (vibrant
                  ? TimePickerBehavior.vibrantPeriodToggleWidth
                  : TimeInputTokens.periodSelectorContainerWidth));

TextStyle _fitPickerFieldStyle(
  BuildContext context,
  TextStyle style,
  Size available, {
  String text = '00',
}) {
  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final factor = math.min(
    1.0,
    math.min(
      available.width / painter.width,
      available.height / painter.height,
    ),
  );
  painter.dispose();
  return factor < 1
      ? style.copyWith(fontSize: (style.fontSize ?? 1) * factor)
      : style;
}

double _timeSupportingHeight(BuildContext context) {
  final painter = TextPainter(
    text: TextSpan(
      text: '\n',
      style: context.expressiveTheme.type.of(
        TimeInputTokens.timeFieldSupportingTextFont,
      ),
    ),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
  )..layout();
  final height = painter.height + TimePickerBehavior.supportingTextTop;
  painter.dispose();
  return height;
}

// ---------------------------------------------------------------------------
// The inline calendar
// ---------------------------------------------------------------------------

/// A month calendar standing in the page (shadcn's `Calendar`; the date
/// picker's grid without its dialog): the month's name over its arrows,
/// the weekdays in the picker's weekday type, each day a 40dp circle in a
/// 48dp cell (overhanging its seventh where seven do not fit) — the chosen
/// day in `primary`, today ringed in `primary`, a range's days on its
/// `secondaryContainer` band. The keyboard is ui_core's
/// `DesignCalendar`: the arrows move a day or a week, Page Up and Down a
/// month, Home and End to the week's ends, Enter chooses; the keyboard's day
/// shows the focus state layer and ring. A pointer resting on a day while a
/// range has its start shows where the range would end.
///
/// [ExpressiveCalendar] chooses a day ([value]); [ExpressiveCalendar.range]
/// a start and an end. [months] lays that many months side by side.
///
/// ```dart
/// ExpressiveCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), value: day, onChanged: setDay)
/// ```
class ExpressiveCalendar extends StatefulWidget {
  /// A calendar choosing one day, [value].
  const ExpressiveCalendar({
    required this.firstDate,
    required this.lastDate,
    this._value,
    this._onChanged,
    this.currentDate,
    this.selectableDayPredicate,
    this.months = 1,
    this.firstDayOfWeek,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : start = null,
       end = null,
       _onRange = null,
       _range = false;

  /// A calendar choosing a range, [start] to [end].
  const ExpressiveCalendar.range({
    required this.firstDate,
    required this.lastDate,
    this.start,
    this.end,
    void Function(DateTime? start, DateTime? end)? onChanged,
    this.currentDate,
    this.selectableDayPredicate,
    this.months = 1,
    this.firstDayOfWeek,
    this.focusNode,
    this.autofocus = false,
    super.key,
  }) : _onRange = onChanged,
       _value = null,
       _onChanged = null,
       _range = true;

  /// The earliest day offered.
  final DateTime firstDate;

  /// The latest day offered.
  final DateTime lastDate;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// Whether a day can be chosen; every day when null.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// How many months stand side by side.
  final int months;

  /// The week's first day (`DateTime.monday` … `DateTime.sunday`); the
  /// locale's ([ExpressiveLocalizations.firstDayOfWeek]) when null.
  final int? firstDayOfWeek;

  /// A range's first day (range).
  final DateTime? start;

  /// A range's last day (range).
  final DateTime? end;

  /// The focus node of the days' grid; null lets the calendar keep its own.
  final FocusNode? focusNode;

  /// Whether the days' grid takes focus when first built.
  final bool autofocus;

  final DateTime? _value;
  final ValueChanged<DateTime>? _onChanged;
  final void Function(DateTime? start, DateTime? end)? _onRange;
  final bool _range;

  @override
  State<ExpressiveCalendar> createState() => _ExpressiveCalendarState();
}

class _ExpressiveCalendarState extends State<ExpressiveCalendar> {
  late DesignCalendarController _controller = _make();

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: widget._range ? DesignCalendarMode.range : DesignCalendarMode.single,
    selectedDate: widget._value,
    selectedRange: widget._range && widget.start != null
        ? DesignDateRange(widget.start!, widget.end)
        : null,
    selectable: widget.selectableDayPredicate,
    currentDate: widget.currentDate,
  );

  @override
  void didUpdateWidget(ExpressiveCalendar old) {
    super.didUpdateWidget(old);
    final range = _controller.selectedRange;
    final changed = widget._range
        ? range?.start != widget.start || range?.end != widget.end
        : _controller.selectedDate != widget._value;
    if (changed ||
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old._range != widget._range) {
      _controller.dispose();
      _controller = _make();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _changed(DateTime day) {
    if (widget._range) {
      widget._onRange?.call(
        _controller.selectedRange?.start,
        _controller.selectedRange?.end,
      );
    } else {
      final day = _controller.selectedDate;
      if (day != null) widget._onChanged?.call(day);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = _DateColors.of(t);
    final strings = ExpressiveLocalizations.of(context);
    final enabled = widget._range
        ? widget._onRange != null
        : widget._onChanged != null;
    return DesignCalendar(
      controller: _controller,
      months: widget.months,
      firstWeekday: widget.firstDayOfWeek ?? strings.firstDayOfWeek,
      showOutsideDays: false,
      // Where seven 48dp cells do not fit, a day keeps its 48dp target and
      // overhangs its seventh, as the date picker's days do.
      minDayWidth: DatePickerBehavior.cellSize,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onChanged: enabled ? _changed : null,
      monthsBuilder: (context, months) => Wrap(
        spacing: ExpressiveSpacing.s24,
        runSpacing: ExpressiveSpacing.s16,
        children: months,
      ),
      headerBuilder: (context, header) => SizedBox(
        height: DatePickerBehavior.monthYearHeight,
        child: Row(
          children: <Widget>[
            const SizedBox(width: ExpressiveSpacing.s12),
            Expanded(
              child: Text(
                header.label,
                style: t.type.labelLarge.copyWith(color: colors.navigation),
              ),
            ),
            IconTheme.merge(
              data: IconThemeData(color: colors.navigation),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  ExpressiveIconButton(
                    _monthBack(context),
                    onPressed: header.previous,
                    semanticLabel: strings.previousMonth,
                    tooltip: strings.previousMonth,
                  ),
                  ExpressiveIconButton(
                    _monthOn(context),
                    onPressed: header.next,
                    semanticLabel: strings.nextMonth,
                    tooltip: strings.nextMonth,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      weekdayBuilder: (context, weekday, label) => SizedBox(
        width: DatePickerBehavior.cellSize,
        height: DatePickerBehavior.cellSize,
        child: Center(
          child: Text(
            label,
            style: t.type
                .of(DatePickerModalTokens.weekdaysLabelTextFont)
                .copyWith(color: colors.weekday),
          ),
        ),
      ),
      dayBuilder: (context, day, states) {
        final chosen = day.selected || day.isRangeStart || day.isRangeEnd;
        final band = day.inRange || day.inPreview;
        // The day a waiting start's preview ends on (the pointer's, or the
        // keyboard's): its band stops there with a finished end's round cap.
        final previewEnd = day.isPreviewEnd && !day.inRange;
        final ltr = Directionality.of(context) == TextDirection.ltr;
        final half = DatePickerBehavior.cellSize / 2;
        final inset =
            (DatePickerBehavior.cellSize -
                DatePickerModalTokens.dateContainerWidth) /
            2;
        final face = ExpressiveStateFace(
          states: states,
          shape: t.shapes.of(DatePickerModalTokens.dateContainerShape),
          color: colors.dayContainer(selected: chosen, enabled: day.enabled),
          contentColor: colors.dayContent(
            today: day.isToday,
            selected: chosen,
            inRange: day.inRange,
            enabled: day.enabled,
          ),
          side: day.isToday && !chosen
              ? BorderSide(
                  color: colors.todayBorder,
                  width: DatePickerModalTokens.dateTodayContainerOutlineWidth,
                )
              : BorderSide.none,
          child: SizedBox.square(
            dimension: DatePickerModalTokens.dateContainerWidth,
            // The day's number on its face's middle, by its capitals.
            child: Center(
              child: expressiveFaceLabel(
                Text(
                  '${day.date.day}',
                  style: t.type.of(DatePickerModalTokens.dateLabelTextFont),
                ),
              ),
            ),
          ),
        );
        return SizedBox.square(
          dimension: DatePickerBehavior.cellSize,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (previewEnd && !day.isRangeStart)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _PreviewEndPainter(
                      color: colors.rangeContainer.withValues(alpha: 0.5),
                      diameter: DatePickerModalTokens.dateContainerWidth,
                      ltr: ltr,
                    ),
                  ),
                )
              else if (band &&
                  !previewEnd &&
                  !(day.isRangeStart && day.isRangeEnd))
                Positioned(
                  top: inset,
                  bottom: inset,
                  left: (ltr ? day.isRangeStart : day.isRangeEnd) ? half : 0,
                  right: (ltr ? day.isRangeEnd : day.isRangeStart) ? half : 0,
                  child: ColoredBox(
                    color: day.inRange
                        ? colors.rangeContainer
                        : colors.rangeContainer.withValues(alpha: 0.5),
                  ),
                ),
              face,
            ],
          ),
        );
      },
    );
  }
}

/// A range preview's end, as one shape so its translucent wash is laid
/// once: the band from the cell's start edge to the day's centre, then the
/// day's own circle (a finished range's end), measured from the cell as laid
/// out (a day is wider than its circle where seven cells share the width).
class _PreviewEndPainter extends CustomPainter {
  const _PreviewEndPainter({
    required this.color,
    required this.diameter,
    required this.ltr,
  });

  final Color color;
  final double diameter;
  final bool ltr;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = size.center(Offset.zero);
    final r = diameter / 2;
    final band = ltr
        ? Rect.fromLTRB(0, centre.dy - r, centre.dx, centre.dy + r)
        : Rect.fromLTRB(centre.dx, centre.dy - r, size.width, centre.dy + r);
    final shape = Path.combine(
      PathOperation.union,
      Path()..addRect(band),
      Path()..addOval(Rect.fromCircle(center: centre, radius: r)),
    );
    canvas.drawPath(shape, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_PreviewEndPainter old) =>
      old.color != color || old.diameter != diameter || old.ltr != ltr;
}
