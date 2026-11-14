/// Date and time selection: a compact row opening a popover or sheet, and
/// an inline calendar.
library;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../chrome_metrics.dart';
import '../format.dart';
import '../internal/cap_label.dart';
import '../internal/field.dart';
import '../internal/kit_paint.dart';
import '../internal/styled.dart';
import '../internal/today_mark.dart';
import '../localizations.dart';
import '../shapes.dart';
import '../theme.dart';
import 'button.dart';
import 'icon_button.dart';
import 'menu.dart';
import 'pressable.dart';
import 'sheet.dart';

/// What a [MinimalDatePicker] sets: the day, the clock time, or both.
enum MinimalDatePickerMode {
  /// The day.
  date,

  /// The clock time.
  time,

  /// The day and the clock time.
  dateAndTime,
}

/// How a [MinimalDatePicker] stands on the page: `compact` a form row whose
/// mono value pills open the picker in place; `inline` the calendar itself
/// (with the time columns under it for `dateAndTime`); `wheel` the hour and
/// minute columns alone.
enum MinimalDatePickerPresentation {
  /// A form row whose value pills open the picker.
  compact,

  /// The calendar itself, in the page.
  inline,

  /// The hour and minute columns alone.
  wheel,
}

/// Date and time selection in Minimal's grammar. The compact row prints
/// the label in the quiet ink and the value as bordered mono pills — the
/// date (`28 Aug 2026`), the clock (`21:30`) — each opening its own picker
/// in an anchored popover: a month calendar with mono day numbers, the
/// chosen day on the accent, [today] a bar under its figure; or two scrolling columns of
/// hours and minutes. Choosing a day closes the calendar. With
/// `confirmSelection` the picker rises in a sheet instead and commits only
/// on Done. With no [onChanged] the whole row dims to the kit's 0.45, its
/// pills' values in the quiet ink at the regular weight.
///
/// Every pill and every day stands in a 44 px slot, so each keeps its whole
/// touch target. The calendar is one keyboard stop: the arrow keys walk the
/// days (stepping the month at its edges), Page Up and Page Down step the
/// month, Enter or Space picks the day. The time columns' 32 px items abut
/// like a dense list's rows: each takes its whole row of the column.
///
/// Minimal prints the 24-hour clock unless [use24HourFormat] is false. The
/// calendar starts its weeks on Monday. Nothing here reads the clock: pass
/// [today] to have it marked. [first] and [last] (the earliest and latest
/// moments that can be chosen) grey the days outside them and clamp every
/// change into range.
///
/// ```dart
/// MinimalDatePicker(label: 'Reminder', value: remindAt, mode: MinimalDatePickerMode.time, onChanged: setRemindAt)
/// ```
class MinimalDatePicker extends StatefulWidget {
  /// A picker of a date, a time or both, showing [value].
  const MinimalDatePicker({
    super.key,
    required this.label,
    required this.value,
    this.onChanged,
    this.mode = MinimalDatePickerMode.dateAndTime,
    this.presentation = MinimalDatePickerPresentation.compact,
    this.first,
    this.last,
    this.use24HourFormat = true,
    this.confirmSelection = false,
    this.today,
    this.icon,
  });

  /// What it picks.
  final String label;

  /// The moment it shows.
  final DateTime value;

  /// Null disables the picker.
  final ValueChanged<DateTime>? onChanged;

  /// What it picks: a date, a time or both.
  final MinimalDatePickerMode mode;

  /// Compact pills that open pickers, the calendar inline, or scrolling wheels.
  final MinimalDatePickerPresentation presentation;

  /// The earliest moment it can pick.
  final DateTime? first;

  /// The latest moment it can pick.
  final DateTime? last;

  /// Whether it prints the 24-hour clock.
  final bool use24HourFormat;

  /// Raise the picker in a sheet that commits only on Done.
  final bool confirmSelection;

  /// The day the calendar outlines as today; none when null.
  final DateTime? today;

  /// A glyph before the compact row's label.
  final IconData? icon;

  @override
  State<MinimalDatePicker> createState() => _MinimalDatePickerState();
}

/// The date picker's geometry: a day's 44 px slot around its 32 px mark,
/// the popovers' widths (a calendar of 44 px columns inside the card's
/// padding; the two time columns), a time column's 32 px items.
abstract final class _DateMetrics {
  static const double day = MinimalLayout.minHitTarget;
  static const double dayMark = MinimalChromeMetrics.control;
  static const double popoverPad = MinimalSpacing.s8;
  static const double calendarWidth = 7 * day + 2 * popoverPad;
  static const double timeWidth = 208;
  static const double timeItem = 32;
  static const int timeVisible = 5;
  static const int minuteStep = 5;
  static const double weekdayType = 11;
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

class _MinimalDatePickerState extends State<MinimalDatePicker> {
  late DateTime _month = DateTime(widget.value.year, widget.value.month);

  /// The day the keyboard stands on in the shown month; null starts at
  /// the choice (or today, or the 1st).
  int? _cursor;
  final FocusNode _grid = FocusNode(debugLabel: 'Calendar days');

  @override
  void didUpdateWidget(MinimalDatePicker old) {
    super.didUpdateWidget(old);
    if (old.value.year != widget.value.year ||
        old.value.month != widget.value.month) {
      _month = DateTime(widget.value.year, widget.value.month);
      _cursor = null;
    }
  }

  @override
  void dispose() {
    _grid.dispose();
    super.dispose();
  }

  DateTime _clamp(DateTime v) {
    final min = widget.first;
    final max = widget.last;
    if (min != null && v.isBefore(min)) return min;
    if (max != null && v.isAfter(max)) return max;
    return v;
  }

  void _change(DateTime v) => widget.onChanged?.call(_clamp(v));

  String _dateText() => MinimalFormat.date(widget.value);

  String _timeText() => widget.use24HourFormat
      ? MinimalFormat.clock(widget.value)
      : MinimalFormat.time12(widget.value);

  /// A picker for [mode] alone, standing in a popover or a sheet.
  MinimalDatePicker _panel(
    MinimalDatePickerMode mode,
    DateTime value,
    ValueChanged<DateTime> onChanged,
  ) => MinimalDatePicker(
    label: widget.label,
    value: value,
    mode: mode,
    presentation: mode == MinimalDatePickerMode.time
        ? MinimalDatePickerPresentation.wheel
        : MinimalDatePickerPresentation.inline,
    first: widget.first,
    last: widget.last,
    use24HourFormat: widget.use24HourFormat,
    today: widget.today,
    onChanged: onChanged,
  );

  Future<void> _open(MinimalDatePickerMode mode, BuildContext anchor) async {
    if (widget.onChanged == null) return;
    var draft = _clamp(widget.value);
    if (!widget.confirmSelection) {
      final box = anchor.findRenderObject()! as RenderBox;
      await MinimalMenu.popover<void>(
        context,
        anchor: box.localToGlobal(Offset.zero) & box.size,
        label: widget.label,
        width: mode == MinimalDatePickerMode.time
            ? _DateMetrics.timeWidth
            : _DateMetrics.calendarWidth,
        builder: (popoverContext) => StatefulBuilder(
          builder: (context, update) => Padding(
            padding: const EdgeInsets.all(_DateMetrics.popoverPad),
            child: _panel(mode, draft, (v) {
              update(() => draft = v);
              widget.onChanged?.call(v);
              // A day is one choice: the calendar has done its job.
              if (mode == MinimalDatePickerMode.date) {
                Navigator.of(popoverContext).pop();
              }
            }),
          ),
        ),
      );
      return;
    }
    final result = await showMinimalBottomSheet<DateTime>(
      context,
      title: widget.label,
      leading: MinimalSheetAction(MinimalLocalizations.of(context).cancel),
      trailing: MinimalSheetAction(
        MinimalLocalizations.of(context).done,
        isDefaultAction: true,
        onPressed: () => Navigator.of(context, rootNavigator: true).pop(draft),
      ),
      builder: (_) => StatefulBuilder(
        builder: (context, update) =>
            _panel(mode, draft, (v) => update(() => draft = v)),
      ),
    );
    if (result != null && mounted) widget.onChanged?.call(result);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return switch (widget.presentation) {
      MinimalDatePickerPresentation.compact => _compact(context),
      MinimalDatePickerPresentation.wheel => _disabledAware(_timeColumns()),
      MinimalDatePickerPresentation.inline =>
        widget.mode == MinimalDatePickerMode.time
            ? _disabledAware(_timeColumns())
            : _disabledAware(
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _calendar(context),
                    if (widget.mode == MinimalDatePickerMode.dateAndTime) ...[
                      const MinimalGap(MinimalSpacing.s8),
                      Container(height: t.hairline, color: t.border),
                      const MinimalGap(MinimalSpacing.s8),
                      // The columns take the calendar's measure, so the two
                      // blocks share their edges.
                      _timeColumns(fill: true),
                    ],
                  ],
                ),
              ),
    };
  }

  // An inline calendar or wheel spans a phone's column; from the compact
  // width up it keeps a control's measure, a month's seven columns at the
  // size of a day rather than stretched across a page.
  Widget _disabledAware(Widget child) => MinimalLayout.capControl(
    context,
    widget.onChanged != null
        ? child
        : Opacity(opacity: 0.45, child: IgnorePointer(child: child)),
  );

  Widget _compact(BuildContext context) {
    final t = context.minimalTheme;
    final icon = widget.icon;
    final enabled = widget.onChanged != null;
    Widget pill(String text, MinimalDatePickerMode mode) {
      final label =
          '${widget.label}, '
          '${mode == MinimalDatePickerMode.time ? 'time' : 'date'}';
      final face = Container(
        constraints: const BoxConstraints(
          minHeight: MinimalChromeMetrics.controlSm,
        ),
        padding: MinimalInsets.horizontal8,
        // A value in a hairline on the ground, as a field's; no grey well.
        decoration: minimalFrame(
          MinimalShapes.inset(t.shapes.small, 1),
          side: BorderSide(color: t.border, width: t.hairline),
        ),
        // Shrink-wrapped: the pill is as wide as its value.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          // Disabled, the value drops to the quiet ink at the regular
          // weight: dimmed, the full ink at medium would still read
          // stronger than an enabled row's label.
          child: minimalCapLabel(
            Text(
              text,
              maxLines: 1,
              style: enabled
                  ? t.monoValue.medium
                  : t.monoValue.c(t.mutedForeground),
            ),
          ),
        ),
      );
      // A 44 px slot (the row's height) around the 28 px pill, so the row
      // leaves room for the pill's whole touch target.
      return SizedBox(
        height: t.rowHeight,
        child: Center(
          widthFactor: 1,
          child: enabled
              ? Builder(
                  builder: (pillContext) => MinimalPressable(
                    onPressed: () => _open(mode, pillContext),
                    shape: MinimalShapes.inset(t.shapes.small, 1),
                    semanticLabel: label,
                    child: face,
                  ),
                )
              // The row dims as a whole; the pill still says what it is.
              : Semantics(
                  container: true,
                  button: true,
                  enabled: false,
                  label: label,
                  child: face,
                ),
        ),
      );
    }

    final row = Container(
      constraints: BoxConstraints(minHeight: t.rowHeight),
      // Painted over the row's foot: the label and value are centred on
      // the whole row, the rule's pixel with it. Disabled, the words dim and
      // the rule keeps its neighbours' strength.
      foregroundDecoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              if (icon != null) ...[
                MinimalIcon(icon),
                const MinimalGap(MinimalFieldMetrics.rowIconGap),
              ],
              Expanded(
                child: minimalCapLabel(
                  Text(
                    widget.label,
                    style: t.body.c(t.mutedForeground),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const MinimalGap(MinimalSpacing.s12),
              // The value takes what its pills need (up to 240, and never past
              // two thirds of a narrow row; then they wrap) and the label every
              // pixel left, so a short value never leaves the label wrapping
              // beside empty room.
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: box.maxWidth.isFinite
                      ? (box.maxWidth * 2 / 3).clamp(0.0, 240.0)
                      : 240,
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: MinimalChromeMetrics.iconGap,
                  children: [
                    if (widget.mode != MinimalDatePickerMode.time)
                      pill(_dateText(), MinimalDatePickerMode.date),
                    if (widget.mode != MinimalDatePickerMode.date)
                      pill(_timeText(), MinimalDatePickerMode.time),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    // Spanning a phone's column; from the compact width up it stops at a
    // control's measure, as a select does.
    return MinimalLayout.capControl(
      context,
      enabled
          ? row
          // Dimmed, the row says so to a screen reader too: its label is
          // an inactive control's, not text the page asks anyone to read.
          : Semantics(container: true, enabled: false, child: row),
    );
  }

  int _daysIn(DateTime month) => DateTime(month.year, month.month + 1, 0).day;

  /// Where the keyboard starts in the shown month: the choice, today, or
  /// the 1st.
  int _cursorDay() {
    final days = _daysIn(_month);
    final cursor = _cursor;
    if (cursor != null) return cursor.clamp(1, days);
    bool shown(DateTime? d) =>
        d != null && d.year == _month.year && d.month == _month.month;
    if (shown(widget.value)) return widget.value.day;
    final today = widget.today;
    if (today != null && shown(today)) return today.day;
    return 1;
  }

  DateTime _dayAt(int n) => widget.value.isUtc
      ? DateTime.utc(
          _month.year,
          _month.month,
          n,
          widget.value.hour,
          widget.value.minute,
        )
      : DateTime(
          _month.year,
          _month.month,
          n,
          widget.value.hour,
          widget.value.minute,
        );

  /// Whether [day] can be chosen: the picker is live and the day touches
  /// the allowed range.
  bool _isOpen(DateTime day) {
    final min = widget.first;
    final max = widget.last;
    final start = DateTime(day.year, day.month, day.day);
    final end = DateTime(day.year, day.month, day.day, 23, 59, 59);
    return widget.onChanged != null &&
        !(min != null && min.isAfter(end)) &&
        !(max != null && max.isBefore(start));
  }

  void _stepMonth(int delta, {int? cursor}) => setState(() {
    _month = DateTime(_month.year, _month.month + delta);
    _cursor = cursor;
  });

  /// Moves the keyboard's day to [target], a day number of the shown month
  /// that may run past either end: the month steps to follow it.
  void _moveCursor(int target) {
    final days = _daysIn(_month);
    if (target < 1) {
      final previous = DateTime(_month.year, _month.month - 1);
      _stepMonth(-1, cursor: _daysIn(previous) + target);
    } else if (target > days) {
      _stepMonth(1, cursor: target - days);
    } else {
      setState(() => _cursor = target);
    }
  }

  KeyEventResult _onGridKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final cursor = _cursorDay();
    final ahead = Directionality.of(context) == TextDirection.rtl ? -1 : 1;
    final step = switch (key) {
      LogicalKeyboardKey.arrowLeft => -ahead,
      LogicalKeyboardKey.arrowRight => ahead,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => null,
    };
    if (step != null) {
      _moveCursor(cursor + step);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final delta = key == LogicalKeyboardKey.pageUp ? -1 : 1;
      final month = DateTime(_month.year, _month.month + delta);
      _stepMonth(delta, cursor: cursor.clamp(1, _daysIn(month)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      final day = _dayAt(cursor);
      if (_isOpen(day)) _change(day);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _calendar(BuildContext context) {
    final t = context.minimalTheme;
    final enabled = widget.onChanged != null;
    final days = _daysIn(_month);
    final words = MinimalLocalizations.of(context);
    // The week starts on the locale's day, as every Minimal calendar's does.
    final firstDay = words.firstDayOfWeek;
    final lead = (DateTime(_month.year, _month.month).weekday - firstDay) % 7;
    final rows = ((days + lead) / 7).ceil();
    final today = widget.today;
    // The keyboard's day wears the focus ring while the grid holds
    // keyboard focus.
    final cursor =
        _grid.hasFocus &&
            FocusManager.instance.highlightMode ==
                FocusHighlightMode.traditional
        ? _cursorDay()
        : null;

    Widget cell(int n) {
      final day = _dayAt(n);
      final open = _isOpen(day);
      final selected = _sameDay(day, widget.value);
      final isToday = today != null && _sameDay(day, today);
      final ink = selected
          ? t.primaryForeground
          : open
          ? t.foreground
          : t.textTertiary;
      final cell = MinimalShapes.inset(t.shapes.small, 1);
      return SizedBox(
        height: _DateMetrics.day,
        child: Center(
          // One keyboard stop for the whole grid: the days are reached by
          // the arrow keys, not by Tab.
          child: ExcludeFocus(
            child: MinimalPressable(
              onPressed: open
                  ? () {
                      setState(() => _cursor = n);
                      _change(day);
                    }
                  : null,
              enabled: open,
              selected: selected,
              shape: cell,
              semanticLabel: isToday
                  ? '${words.fullDate(day)}, ${words.relativeDay(0)}'
                  : words.fullDate(day),
              child: Container(
                width: _DateMetrics.dayMark,
                height: _DateMetrics.dayMark,
                alignment: Alignment.center,
                decoration: minimalFrame(
                  cell,
                  fill: selected ? t.primary : null,
                ),
                foregroundDecoration: n == cursor
                    ? minimalRingFrame(
                        cell,
                        ring: t.ring,
                        ground: minimalGround(context),
                        width: t.focusWidth,
                      )
                    : null,
                child: ExcludeSemantics(
                  child: minimalTodayMark(
                    today: isToday,
                    ink: ink,
                    figure: Text(
                      '$n',
                      style: (selected ? t.monoValue.medium : t.monoValue).c(
                        ink,
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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // A 44 px band, so the small month buttons keep their whole target.
        SizedBox(
          height: MinimalLayout.minHitTarget,
          child: Row(
            children: [
              Expanded(
                child: Semantics(
                  liveRegion: true,
                  child: Text(
                    MinimalLocalizations.of(context).monthYear(_month),
                    style: t.body.semibold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              MinimalIconButton(
                LucideIcons.chevronLeftDir,
                label: MinimalLocalizations.of(context).previousMonth,
                size: MinimalButtonSize.small,
                onPressed: enabled ? () => _stepMonth(-1) : null,
              ),
              // Wide enough that neither button's padded target reaches
              // into the other's face.
              const MinimalGap(MinimalSpacing.s8),
              MinimalIconButton(
                LucideIcons.chevronRightDir,
                label: MinimalLocalizations.of(context).nextMonth,
                size: MinimalButtonSize.small,
                onPressed: enabled ? () => _stepMonth(1) : null,
              ),
            ],
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Text(
                    words.weekdaysShort[(firstDay - 1 + i) % 7],
                    textAlign: TextAlign.center,
                    style: t.mono
                        .copyWith(fontSize: _DateMetrics.weekdayType)
                        .c(t.mutedForeground),
                  ),
                ),
            ],
          ),
        ),
        const MinimalGap(MinimalSpacing.s4),
        Focus(
          focusNode: _grid,
          canRequestFocus: enabled,
          includeSemantics: false,
          onKeyEvent: _onGridKey,
          onFocusChange: (_) => setState(() {}),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var row = 0; row < rows; row++)
                Row(
                  children: [
                    for (var col = 0; col < 7; col++)
                      Expanded(
                        child: Builder(
                          builder: (context) {
                            final n = row * 7 + col - lead + 1;
                            if (n < 1 || n > days) {
                              return const SizedBox(height: _DateMetrics.day);
                            }
                            return cell(n);
                          },
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeColumns({bool fill = false}) {
    final value = widget.value;
    final minutes = <int>{
      for (var m = 0; m < 60; m += _DateMetrics.minuteStep) m,
      value.minute,
    }.toList()..sort();
    String hourText(int h) => widget.use24HourFormat
        ? h.toString().padLeft(2, '0')
        : '${h % 12 == 0 ? 12 : h % 12} ${h < 12 ? 'AM' : 'PM'}';
    DateTime at(int hour, int minute) => value.isUtc
        ? DateTime.utc(value.year, value.month, value.day, hour, minute)
        : DateTime(value.year, value.month, value.day, hour, minute);
    // Hour then minute in every language, as the time itself prints.
    final columns = Row(
      textDirection: TextDirection.ltr,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _TimeColumn(
            label: MinimalLocalizations.of(context).hour,
            values: List<int>.generate(24, (h) => h),
            selected: value.hour,
            text: hourText,
            onChanged: widget.onChanged == null
                ? null
                : (h) => _change(at(h, value.minute)),
          ),
        ),
        const MinimalGap(MinimalSpacing.s8),
        Expanded(
          child: _TimeColumn(
            label: MinimalLocalizations.of(context).minute,
            values: minutes,
            selected: value.minute,
            text: (m) => m.toString().padLeft(2, '0'),
            onChanged: widget.onChanged == null
                ? null
                : (m) => _change(at(value.hour, m)),
          ),
        ),
      ],
    );
    if (fill) return columns;
    // At most a wheel's measure, on the start edge where every part of the
    // page stands, not centred in what is left of the slot.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _DateMetrics.timeWidth),
        child: columns,
      ),
    );
  }
}

/// One scrolling column of the time picker: a small uppercase head centred
/// over five 32 px mono items in view, the chosen one in an ink hairline at
/// medium weight and scrolled to the middle when the column opens. The
/// column loops, as a clock face does (minute 55 stands over 00, hour 23
/// over 00), so both columns are full whatever the time.
class _TimeColumn extends StatefulWidget {
  const _TimeColumn({
    required this.label,
    required this.values,
    required this.selected,
    required this.text,
    required this.onChanged,
  });

  final String label;
  final List<int> values;
  final int selected;
  final String Function(int) text;
  final ValueChanged<int>? onChanged;

  @override
  State<_TimeColumn> createState() => _TimeColumnState();
}

class _TimeColumnState extends State<_TimeColumn> {
  /// How many times the values repeat down the column: enough that no
  /// scroll reaches either end, so it reads as a loop.
  static const int _laps = 200;

  /// The rows above the middle one in view.
  static const int _above = _DateMetrics.timeVisible ~/ 2;

  /// The index in [_TimeColumn.values] of the selected value, or of the
  /// nearest one the column lists.
  int get _selectedIndex {
    final values = widget.values;
    final index = values.indexOf(widget.selected);
    if (index >= 0) return index;
    var best = 0;
    for (var i = 1; i < values.length; i++) {
      if ((values[i] - widget.selected).abs() <
          (values[best] - widget.selected).abs()) {
        best = i;
      }
    }
    return best;
  }

  /// The offset that stands the selected value on the middle row: its copy
  /// in the middle lap, or with [near] the copy nearest that offset, so a
  /// pick glides the short way round.
  double _centred({double? near}) {
    final n = widget.values.length;
    const item = _DateMetrics.timeItem;
    final middle = near == null
        ? _laps ~/ 2 * n
        : (near / item).round() + _above;
    final row = middle - (middle - _selectedIndex + n ~/ 2) % n + n ~/ 2;
    return (row - _above) * item;
  }

  late final ScrollController _scroll = ScrollController(
    initialScrollOffset: _centred(),
  );

  @override
  void didUpdateWidget(_TimeColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selected == widget.selected || !_scroll.hasClients) return;
    // A picked value glides to the middle row, so the pair stays one band.
    final target = _centred(near: _scroll.offset);
    if (context.minimalStill) {
      _scroll.jumpTo(target);
    } else {
      _scroll.animateTo(
        target,
        duration: MinimalMotion.fast,
        curve: MinimalMotion.out,
      );
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final onChanged = widget.onChanged;
    final cell = MinimalShapes.inset(t.shapes.small, 1);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: MinimalSpacing.s4),
          child: ExcludeSemantics(
            child: Text(
              widget.label.toUpperCase(),
              style: t.label,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        Semantics(
          label: widget.label,
          container: true,
          child: SizedBox(
            height: _DateMetrics.timeItem * _DateMetrics.timeVisible,
            child: ListView.builder(
              controller: _scroll,
              itemExtent: _DateMetrics.timeItem,
              itemCount: widget.values.length * _laps,
              // The laps repeat the same values: no index to announce.
              addSemanticIndexes: false,
              itemBuilder: (context, i) {
                final v = widget.values[i % widget.values.length];
                final selected = v == widget.selected;
                return SizedBox(
                  height: _DateMetrics.timeItem,
                  child: MinimalPressable(
                    onPressed: onChanged == null ? null : () => onChanged(v),
                    enabled: onChanged != null,
                    selected: selected,
                    shape: cell,
                    child: Container(
                      alignment: Alignment.center,
                      // The picked value says so in ink, as a chosen chip
                      // does: its hairline and figure in the ink, the
                      // figure at medium weight, the rest muted. No wash,
                      // and no second accent slab beside the calendar's.
                      decoration: minimalFrame(
                        cell,
                        side: selected
                            ? BorderSide(color: t.foreground, width: t.rim)
                            : BorderSide.none,
                      ),
                      child: Text(
                        widget.text(v),
                        style: selected
                            ? t.monoValue.medium.c(t.foreground)
                            : t.monoValue.c(t.mutedForeground),
                        // A time reads left to right in every language,
                        // its period after the hour (5 AM, never AM 5).
                        textDirection: TextDirection.ltr,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
