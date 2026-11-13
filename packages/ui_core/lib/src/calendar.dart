/// A calendar, headless: an inline month grid and its model, for a date
/// picker, a date range picker and an inline calendar.
///
/// [DesignCalendarController] holds the shown month, the keyboard's day,
/// and the selection: one day, a range (first tap the start, second the
/// end, a pointer resting on a day previews the range) or several days.
/// [DesignCalendar] lays out one or more months as grids of days the look
/// paints, with one tab stop: arrows move a day or a week, Home and End to
/// the week's ends, Page Up and Down a month (with Shift a year), Enter or
/// Space selects; moving off a month's edge turns the page, so a range can
/// span months. Dates are calendar days (local midnight); arithmetic goes
/// through the day of the month, so a daylight-saving change never skips or
/// repeats a day.
library;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'localizations.dart';
import 'pressable.dart';

/// [d] as a calendar day: local midnight.
DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _addDays(DateTime d, int days) =>
    DateTime(d.year, d.month, d.day + days);

DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);

DateTime? _earliest(Iterable<DateTime> days) =>
    days.isEmpty ? null : days.reduce((a, b) => a.isBefore(b) ? a : b);

DateTime _addMonths(DateTime d, int months) {
  final first = DateTime(d.year, d.month + months);
  final last = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, d.day > last ? last : d.day);
}

bool _sameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;

/// A range of days, [start] to [end] inclusive; [end] is null while only
/// the start is chosen.
@immutable
class DesignDateRange {
  /// A range from [start] to [end].
  DesignDateRange(DateTime start, [DateTime? end])
    : start = _dateOnly(start),
      end = end == null ? null : _dateOnly(end);

  /// The first day.
  final DateTime start;

  /// The last day, or null while the range is half chosen.
  final DateTime? end;

  /// Whether both ends are chosen.
  bool get isComplete => end != null;

  /// Whether [day] is in it (its start alone while half chosen).
  bool contains(DateTime day) {
    final d = _dateOnly(day);
    final e = end ?? start;
    return !d.isBefore(start) && !d.isAfter(e);
  }

  /// How many days it spans, a daylight-saving change aside.
  int get dayCount {
    final e = end ?? start;
    return DateTime.utc(
          e.year,
          e.month,
          e.day,
        ).difference(DateTime.utc(start.year, start.month, start.day)).inDays +
        1;
  }

  @override
  bool operator ==(Object other) =>
      other is DesignDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DesignDateRange($start, $end)';
}

/// How a calendar selects.
enum DesignCalendarMode {
  /// One day.
  single,

  /// A range: the first press the start, the next the end.
  range,

  /// Any set of days, each press toggling one.
  multiple,
}

/// A calendar's state: the shown month, the keyboard's day and the
/// selection.
///
/// The caller makes it (a State's field, say), keeps it across rebuilds
/// and disposes it; a widget it is given to only listens to it.
///
/// ```dart
/// DesignCalendarController(firstDate: DateTime(2026), lastDate: DateTime(2027))
/// ```
class DesignCalendarController extends ChangeNotifier {
  /// A calendar between [firstDate] and [lastDate]. It opens on the month of
  /// `initialMonth`, else of the selection (its earliest day), else of
  /// [currentDate].
  DesignCalendarController({
    required DateTime firstDate,
    required DateTime lastDate,
    this.mode = DesignCalendarMode.single,
    DateTime? initialMonth,
    DateTime? selectedDate,
    DesignDateRange? selectedRange,
    Iterable<DateTime> selectedDates = const [],
    this.selectable,
    DateTime? currentDate,
  }) : firstDate = _dateOnly(firstDate),
       lastDate = _dateOnly(lastDate),
       currentDate = _dateOnly(currentDate ?? DateTime.now()),
       _selected = selectedDate == null ? null : _dateOnly(selectedDate),
       _range = selectedRange,
       _days = {for (final d in selectedDates) _dateOnly(d)} {
    assert(!this.lastDate.isBefore(this.firstDate));
    final start =
        initialMonth ??
        _selected ??
        _range?.start ??
        _earliest(_days) ??
        this.currentDate;
    _focused = _clamp(_dateOnly(start));
    _month = _monthOf(_focused);
  }

  /// The earliest day it offers.
  final DateTime firstDate;

  /// The latest day it offers.
  final DateTime lastDate;

  /// How it selects.
  final DesignCalendarMode mode;

  /// Which days can be chosen, beside the bounds; null for all.
  final bool Function(DateTime day)? selectable;

  /// Today, marked in the grid.
  final DateTime currentDate;

  late DateTime _month;
  late DateTime _focused;
  DateTime? _selected;
  DesignDateRange? _range;
  final Set<DateTime> _days;
  DateTime? _hovered;

  DateTime _clamp(DateTime d) => d.isBefore(firstDate)
      ? firstDate
      : d.isAfter(lastDate)
      ? lastDate
      : d;

  /// The first shown month (its first day).
  DateTime get month => _month;

  /// The day the keyboard is on.
  DateTime get focusedDay => _focused;

  /// The chosen day ([DesignCalendarMode.single]).
  DateTime? get selectedDate => _selected;

  /// The chosen range ([DesignCalendarMode.range]).
  DesignDateRange? get selectedRange => _range;

  /// The chosen days ([DesignCalendarMode.multiple]), in order.
  List<DateTime> get selectedDates => _days.toList()..sort();

  /// The day a pointer rests on while a range waits for its end.
  DateTime? get hovered => _hovered;

  /// Whether [day] is inside the bounds and [selectable].
  bool isSelectable(DateTime day) {
    final d = _dateOnly(day);
    if (d.isBefore(firstDate) || d.isAfter(lastDate)) return false;
    return selectable?.call(d) ?? true;
  }

  /// Whether an earlier month can be shown.
  bool get canGoBack => _month.isAfter(_monthOf(firstDate));

  /// Whether a later month can be shown ([months] shown at once).
  bool canGoForward([int months = 1]) =>
      _addMonths(_month, months - 1).isBefore(_monthOf(lastDate));

  /// Shows the month [delta] months on, the keyboard's day moving with it.
  void turn(int delta) {
    final next = _monthOf(_addMonths(_month, delta));
    if (next.isBefore(_monthOf(firstDate)) ||
        next.isAfter(_monthOf(lastDate))) {
      return;
    }
    _month = next;
    _focused = _clamp(_addMonths(_focused, delta));
    notifyListeners();
  }

  /// Puts the keyboard on [day], turning to its month when it is not shown
  /// ([months] shown at once).
  void focus(DateTime day, {int months = 1}) {
    final d = _clamp(_dateOnly(day));
    _focused = d;
    final m = _monthOf(d);
    if (m.isBefore(_month)) {
      _month = m;
    } else if (!m.isBefore(_monthOf(_addMonths(_month, months)))) {
      _month = _monthOf(_addMonths(m, -(months - 1)));
    }
    notifyListeners();
  }

  /// Moves the keyboard's day by [days].
  void moveFocus(int days, {int months = 1}) =>
      focus(_addDays(_focused, days), months: months);

  /// Moves the keyboard's day by [delta] months.
  void moveFocusMonths(int delta, {int months = 1}) =>
      focus(_addMonths(_focused, delta), months: months);

  /// The day a pointer rests on, for a range's preview; null when it
  /// leaves.
  set hovered(DateTime? day) {
    final d = day == null ? null : _dateOnly(day);
    if (_sameDay(d, _hovered) || (d == null && _hovered == null)) return;
    _hovered = d;
    notifyListeners();
  }

  /// Selects [day] as the mode says: the day; the range's start, then its
  /// end (a day before the start starts again there); or a day toggled.
  void select(DateTime day) {
    final d = _dateOnly(day);
    if (!isSelectable(d)) return;
    _focused = d;
    switch (mode) {
      case DesignCalendarMode.single:
        _selected = d;
      case DesignCalendarMode.range:
        final r = _range;
        if (r == null || r.isComplete || d.isBefore(r.start)) {
          _range = DesignDateRange(d);
        } else {
          _range = DesignDateRange(r.start, d);
          _hovered = null;
        }
      case DesignCalendarMode.multiple:
        if (!_days.remove(d)) _days.add(d);
    }
    notifyListeners();
  }

  /// Clears the selection.
  void clear() {
    _selected = null;
    _range = null;
    _days.clear();
    notifyListeners();
  }

  /// The range a waiting start and a resting pointer preview, or null.
  DesignDateRange? get preview {
    final r = _range;
    final h = _hovered;
    if (mode != DesignCalendarMode.range || r == null || r.isComplete) {
      return null;
    }
    if (h == null || h.isBefore(r.start)) return null;
    return DesignDateRange(r.start, h);
  }

  /// [day] as the grid paints it.
  DesignCalendarDay dayOf(DateTime day, {required DateTime inMonth}) {
    final d = _dateOnly(day);
    final r = _range;
    final p = preview;
    final chosen = switch (mode) {
      DesignCalendarMode.single => _sameDay(d, _selected),
      DesignCalendarMode.range =>
        r != null && (_sameDay(d, r.start) || _sameDay(d, r.end)),
      DesignCalendarMode.multiple => _days.contains(d),
    };
    return DesignCalendarDay(
      date: d,
      inMonth: d.month == inMonth.month && d.year == inMonth.year,
      isToday: _sameDay(d, currentDate),
      selected: chosen,
      isRangeStart: r != null && _sameDay(d, r.start),
      isRangeEnd: r != null && _sameDay(d, r.end),
      inRange: r != null && r.isComplete && r.contains(d),
      inPreview: p != null && p.contains(d),
      isPreviewEnd: p != null && _sameDay(d, p.end),
      enabled: isSelectable(d),
      focused: _sameDay(d, _focused),
    );
  }

  /// The weeks of [month] as the grid shows them, each seven days, starting
  /// on [firstWeekday] ([DateTime.monday] … [DateTime.sunday]).
  List<List<DateTime>> weeksOf(DateTime month, int firstWeekday) {
    final first = _monthOf(month);
    final lead = (first.weekday - firstWeekday) % 7;
    var day = _addDays(first, -lead);
    final weeks = <List<DateTime>>[];
    final next = DateTime(first.year, first.month + 1);
    while (day.isBefore(next)) {
      weeks.add([for (var i = 0; i < 7; i++) _addDays(day, i)]);
      day = _addDays(day, 7);
    }
    return weeks;
  }
}

/// One day as the grid paints it.
@immutable
class DesignCalendarDay {
  /// A day; the controller makes these.
  const DesignCalendarDay({
    required this.date,
    required this.inMonth,
    required this.isToday,
    required this.selected,
    required this.isRangeStart,
    required this.isRangeEnd,
    required this.inRange,
    required this.inPreview,
    required this.isPreviewEnd,
    required this.enabled,
    required this.focused,
  });

  /// The day.
  final DateTime date;

  /// Whether it belongs to the month around it (else a neighbour's, shown
  /// to fill the week).
  final bool inMonth;

  /// Whether it is today.
  final bool isToday;

  /// Whether it is chosen (a range's ends count).
  final bool selected;

  /// Whether a range starts on it, a waiting one's too (a start chosen, no
  /// end yet).
  final bool isRangeStart;

  /// Whether a range ends on it.
  final bool isRangeEnd;

  /// Whether a whole range covers it.
  final bool inRange;

  /// Whether the preview of a range waiting for its end covers it: from the
  /// waiting start ([isRangeStart]) to the preview's end ([isPreviewEnd]).
  final bool inPreview;

  /// Whether the preview of a range waiting for its end ends on it: the day
  /// the pointer rests on, or the keyboard's day, when it is on or after
  /// the start. A look draws it as it draws a finished range's end
  /// ([isRangeEnd]), with no need to read the controller. On the start
  /// itself, both [isRangeStart] and this are true.
  final bool isPreviewEnd;

  /// Whether it can be chosen.
  final bool enabled;

  /// Whether the keyboard is on it (ring it while the grid has focus; the
  /// cell's states carry [WidgetState.focused] then).
  final bool focused;
}

/// Paints one day for its [states] ([WidgetState.selected] when chosen,
/// [WidgetState.focused] while the keyboard is on it, hovered, pressed,
/// disabled).
typedef DesignCalendarDayBuilder = Widget Function(
  BuildContext context,
  DesignCalendarDay day,
  Set<WidgetState> states,
);

/// A month's header, as [DesignCalendar.headerBuilder] gets it.
@immutable
class DesignCalendarHeader {
  /// A header for [month].
  const DesignCalendarHeader({
    required this.month,
    required this.label,
    required this.previous,
    required this.next,
  });

  /// The month (its first day).
  final DateTime month;

  /// Its name ("March 2026").
  final String label;

  /// Shows the month before; null at the first month (the first shown
  /// month's header only).
  final VoidCallback? previous;

  /// Shows the month after; null at the last (the last shown month's
  /// header only).
  final VoidCallback? next;
}

/// One or more month grids over a [DesignCalendarController].
///
/// ```dart
/// DesignCalendar(controller: controller, dayBuilder: (context, day, states) => Text('${day.date.day}'))
/// ```
class DesignCalendar extends StatefulWidget {
  /// A calendar over [controller].
  const DesignCalendar({
    super.key,
    required this.controller,
    required this.dayBuilder,
    this.headerBuilder,
    this.weekdayBuilder,
    this.monthsBuilder,
    this.months = 1,
    this.firstWeekday,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.dayLabel,
    this.monthLabel,
    this.weekdayLabel,
    this.showOutsideDays = true,
    this.minDayWidth = 0,
  });

  /// The model: the shown month, the keyboard's day and the selection.
  /// The caller makes it, keeps it across
  /// rebuilds and disposes it.
  final DesignCalendarController controller;

  /// Paints a day.
  final DesignCalendarDayBuilder dayBuilder;

  /// Paints a month's header; null shows its label.
  final Widget Function(BuildContext context, DesignCalendarHeader header)?
  headerBuilder;

  /// Paints a weekday's heading ([DateTime.monday] …).
  final Widget Function(BuildContext context, int weekday, String label)?
  weekdayBuilder;

  /// Lays out the months side by side or stacked; null puts them in a row.
  final Widget Function(BuildContext context, List<Widget> months)?
  monthsBuilder;

  /// How many months show at once (two for a range picker on a wide
  /// screen).
  final int months;

  /// The day a week starts on ([DateTime.monday] … [DateTime.sunday]). Null
  /// takes it from [DesignLocalizations.firstDayOfWeek], as
  /// `CalendarDatePicker` takes it from its localizations.
  final int? firstWeekday;

  /// Called with the day a press or Enter chose, after [controller] took
  /// it: the controller holds what it made of it (a date, a range's end, a
  /// day added or taken away).
  final ValueChanged<DateTime>? onChanged;

  /// The grid's one focus. The caller's, who disposes it; null: the
  /// calendar makes its own and disposes it.
  final FocusNode? focusNode;

  /// Whether the grid takes focus when it first appears.
  final bool autofocus;

  /// A day's name for a screen reader; null:
  /// [DesignLocalizations.formatFullDate].
  final String Function(DateTime day)? dayLabel;

  /// A month's name; null:
  /// [DesignLocalizations.formatMonthYear].
  final String Function(DateTime month)? monthLabel;

  /// A weekday's short heading; null:
  /// [DesignLocalizations.formatShortWeekday].
  final String Function(int weekday)? weekdayLabel;

  /// Whether days of the neighbouring months fill the first and last weeks
  /// (they cannot be focused by a screen reader's swipe and read as such).
  final bool showOutsideDays;

  /// A day's least width, its touch target: where seven do not fit the
  /// month's width, each day keeps it and overhangs its seventh, centred
  /// (Compose's `minimumInteractiveComponentSize`). 0, the default, keeps
  /// each day to its seventh.
  final double minDayWidth;

  @override
  State<DesignCalendar> createState() => _DesignCalendarState();
}

class _DesignCalendarState extends State<DesignCalendar> {
  String _dayLabel(DateTime day) =>
      (widget.dayLabel ?? DesignLocalizations.of(context).formatFullDate)(day);

  String _monthLabel(DateTime month) =>
      (widget.monthLabel ?? DesignLocalizations.of(context).formatMonthYear)(
        month,
      );

  int get _firstWeekday =>
      widget.firstWeekday ?? DesignLocalizations.of(context).firstDayOfWeek;

  String _weekdayLabel(int weekday) =>
      (widget.weekdayLabel ??
      DesignLocalizations.of(context).formatShortWeekday)(weekday);

  FocusNode? _own;
  bool _keyboard = false;

  FocusNode get _node =>
      widget.focusNode ?? (_own ??= FocusNode(debugLabel: 'DesignCalendar'));

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_changed);
  }

  @override
  void didUpdateWidget(DesignCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_changed);
      widget.controller.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_changed);
    _own?.dispose();
    super.dispose();
  }

  void _changed() => setState(() {});

  void _select(DateTime day) {
    widget.controller.select(day);
    widget.onChanged?.call(day);
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final c = widget.controller;
    final n = widget.months;
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final shift = HardwareKeyboard.instance.isShiftPressed;
    final day = c.focusedDay;
    final weekStart = (day.weekday - _firstWeekday) % 7;
    void move(int days) => c.moveFocus(days, months: n);
    if (key == LogicalKeyboardKey.arrowLeft) {
      move(rtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      move(rtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      move(-7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      move(7);
    } else if (key == LogicalKeyboardKey.home) {
      move(-weekStart);
    } else if (key == LogicalKeyboardKey.end) {
      move(6 - weekStart);
    } else if (key == LogicalKeyboardKey.pageUp) {
      c.moveFocusMonths(shift ? -12 : -1, months: n);
    } else if (key == LogicalKeyboardKey.pageDown) {
      c.moveFocusMonths(shift ? 12 : 1, months: n);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.space) {
      _select(day);
    } else {
      return KeyEventResult.ignored;
    }
    if (c.mode == DesignCalendarMode.range) c.hovered = c.focusedDay;
    // The keyboard's day is no node's focus: a screen reader is told it.
    if (c.focusedDay != day) designAnnounce(context, _dayLabel(c.focusedDay));
    return KeyEventResult.handled;
  }

  Widget _monthGrid(BuildContext context, int index) {
    final c = widget.controller;
    final month = DateTime(c.month.year, c.month.month + index);
    final header = DesignCalendarHeader(
      month: month,
      label: _monthLabel(month),
      previous: index == 0 && c.canGoBack ? () => c.turn(-1) : null,
      next: index == widget.months - 1 && c.canGoForward(widget.months)
          ? () => c.turn(1)
          : null,
    );
    final weekdays = [
      for (var i = 0; i < 7; i++) (_firstWeekday - 1 + i) % 7 + 1,
    ];
    final focusShows = _keyboard && _node.hasFocus;
    Widget cell(DateTime date) {
      final day = c.dayOf(date, inMonth: month);
      if (!day.inMonth && !widget.showOutsideDays) {
        return const SizedBox.shrink();
      }
      final lit = day.focused && day.inMonth && focusShows;
      Widget face = DesignPressable(
        onPressed: day.enabled ? () => _select(date) : null,
        selected: day.selected,
        semanticLabel: _dayLabel(date),
        semanticSelected: day.selected || day.inRange,
        enableFeedback: false,
        excludeSemantics: true,
        builder: (context, states, _) => widget.dayBuilder(context, day, {
          ...states,
          if (lit) WidgetState.focused,
        }),
      );
      if (!day.inMonth) face = ExcludeSemantics(child: face);
      if (c.mode == DesignCalendarMode.range && day.enabled) {
        face = MouseRegion(onEnter: (_) => c.hovered = date, child: face);
      }
      return ExcludeFocus(child: face);
    }

    final weeks = c.weeksOf(month, _firstWeekday);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          liveRegion: true,
          child:
              widget.headerBuilder?.call(context, header) ?? Text(header.label),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (final w in weekdays)
                Expanded(
                  child:
                      widget.weekdayBuilder?.call(
                        context,
                        w,
                        _weekdayLabel(w),
                      ) ??
                      Center(child: Text(_weekdayLabel(w))),
                ),
            ],
          ),
        ),
        for (final week in weeks)
          Row(
            children: [
              for (final d in week)
                Expanded(
                  child: widget.minDayWidth > 0
                      ? _AtLeastWide(width: widget.minDayWidth, child: cell(d))
                      : cell(d),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final months = [
      for (var i = 0; i < widget.months; i++) _monthGrid(context, i),
    ];
    final body =
        widget.monthsBuilder?.call(context, months) ??
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [for (final m in months) Expanded(child: m)],
        );
    return Focus(
      focusNode: _node,
      autofocus: widget.autofocus,
      onKeyEvent: _key,
      onFocusChange: (focused) {
        setState(() {
          _keyboard =
              focused &&
              FocusManager.instance.highlightMode ==
                  FocusHighlightMode.traditional;
        });
        if (focused) {
          designAnnounce(context, _dayLabel(widget.controller.focusedDay));
        }
      },
      child: MouseRegion(
        onExit: (_) => widget.controller.hovered = null,
        child: body,
      ),
    );
  }
}

/// [child] at least [width] wide, centred on the width it is given: a day
/// that overhangs its seventh where seven do not fit.
class _AtLeastWide extends SingleChildRenderObjectWidget {
  const _AtLeastWide({required this.width, required super.child});

  final double width;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAtLeastWide(width);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAtLeastWide renderObject,
  ) => renderObject.width = width;
}

class _RenderAtLeastWide extends RenderShiftedBox {
  _RenderAtLeastWide(this._width) : super(null);

  double _width;

  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  BoxConstraints _inner(BoxConstraints c) =>
      c.maxWidth >= _width ? c : c.copyWith(minWidth: _width, maxWidth: _width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final child = this.child;
    if (child == null) return constraints.smallest;
    return constraints.constrain(child.getDryLayout(_inner(constraints)));
  }

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(_inner(constraints), parentUsesSize: true);
    size = constraints.constrain(child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }
}
