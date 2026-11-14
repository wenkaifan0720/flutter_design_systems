// Calendar and clock choices, with the same soft cells and raised sheets.
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'controls.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'entries.dart';
import 'glyphs.dart';
import 'internal/cell_bank.dart' show neumorphicWideRoom;
import 'localizations.dart';
import 'raised.dart';
import 'theme.dart';
import 'internal/day_face.dart';
import 'internal/out_of_use.dart';

DateTime _day(DateTime value) => DateTime(value.year, value.month, value.day);
bool _sameDay(DateTime? a, DateTime? b) =>
    a != null &&
    b != null &&
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day;
DateTime _clampDay(DateTime date, DateTime first, DateTime last) =>
    date.isBefore(first)
    ? first
    : date.isAfter(last)
    ? last
    : date;

/// A month of soft day cells. Arrow keys move focus; Enter or Space selects.
/// Page Up and Page Down change months, Home and End move within the week.
///
/// ```dart
/// NeumorphicDatePicker(value: date, onChanged: chooseDate)
/// ```
class NeumorphicDatePicker extends StatefulWidget {
  /// Creates a [NeumorphicDatePicker].
  const NeumorphicDatePicker({
    super.key,
    this.value,
    this.onChanged,
    this.first,
    this.last,
    this.today,
    this.style,
  });

  /// Day cells before the date-picker component theme.
  final NeumorphicStyle? style;

  /// The selected date, or null for no selection.
  final DateTime? value;

  /// The first selectable date; null uses 1 January 1900.
  final DateTime? first;

  /// The last selectable date; null uses 31 December 2100.
  final DateTime? last;

  /// The date used for the today marker, or the current date when null.
  final DateTime? today;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<DateTime>? onChanged;
  @override
  State<NeumorphicDatePicker> createState() => _NeumorphicDatePickerState();
}

class _NeumorphicDatePickerState extends State<NeumorphicDatePicker> {
  final _nodes = List.generate(31, (_) => FocusNode());
  late DateTime _month, _focused;
  DateTime get _first => _day(widget.first ?? DateTime(1900));
  DateTime get _last => _day(widget.last ?? DateTime(2100, 12, 31));
  DateTime get _today => _day(widget.today ?? DateTime.now());
  void _validate() {
    if (_first.isAfter(_last)) {
      throw ArgumentError('first must not be after last');
    }
    if (widget.value != null &&
        (_day(widget.value!).isBefore(_first) ||
            _day(widget.value!).isAfter(_last))) {
      throw ArgumentError.value(
        widget.value,
        'value',
        'must be between first and last',
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _validate();
    _focused = _clampDay(_day(widget.value ?? _today), _first, _last);
    _month = DateTime(_focused.year, _focused.month);
  }

  @override
  void didUpdateWidget(NeumorphicDatePicker old) {
    super.didUpdateWidget(old);
    _validate();
    if (widget.value != old.value && widget.value != null) {
      _focused = _day(widget.value!);
      _month = DateTime(_focused.year, _focused.month);
    } else if (widget.first != old.first || widget.last != old.last) {
      _focused = _clampDay(_focused, _first, _last);
      _month = DateTime(_focused.year, _focused.month);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _move(DateTime target, {bool requestFocus = true}) {
    target = _clampDay(target, _first, _last);
    setState(() {
      _focused = target;
      _month = DateTime(target.year, target.month);
    });
    if (requestFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _nodes[_focused.day - 1];
        node.requestFocus();
        if (node.context != null) {
          Scrollable.ensureVisible(
            node.context!,
            duration: NeumorphicMotion.of(context).move,
          );
        }
      });
    }
  }

  DateTime _inMonth(DateTime date, int delta) {
    final target = DateTime(date.year, date.month + delta);
    return DateTime(
      target.year,
      target.month,
      math.min(date.day, DateTime(target.year, target.month + 1, 0).day),
    );
  }

  KeyEventResult _key(DateTime date, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final first = NeumorphicLocalizations.of(context).firstDayOfWeek;
    final offset = (date.weekday - first + 7) % 7;
    final key = event.logicalKey;
    final target = switch (key) {
      LogicalKeyboardKey.arrowLeft => DateTime(
        date.year,
        date.month,
        date.day + (rtl ? 1 : -1),
      ),
      LogicalKeyboardKey.arrowRight => DateTime(
        date.year,
        date.month,
        date.day + (rtl ? -1 : 1),
      ),
      LogicalKeyboardKey.arrowUp => DateTime(
        date.year,
        date.month,
        date.day - 7,
      ),
      LogicalKeyboardKey.arrowDown => DateTime(
        date.year,
        date.month,
        date.day + 7,
      ),
      LogicalKeyboardKey.home => DateTime(
        date.year,
        date.month,
        date.day - offset,
      ),
      LogicalKeyboardKey.end => DateTime(
        date.year,
        date.month,
        date.day + 6 - offset,
      ),
      LogicalKeyboardKey.pageUp => _inMonth(date, -1),
      LogicalKeyboardKey.pageDown => _inMonth(date, 1),
      _ => null,
    };
    if (target == null) return KeyEventResult.ignored;
    _move(target);
    return KeyEventResult.handled;
  }

  // From a medium window up the month keeps its seven days' width (7 × 48), at the start of its column, never cut;
  // on a phone it spans the column.
  @override
  // Its figures grow with the text only so far (1.3), as the calendar's do: at twice the text its days ran together
  // (2324252627) and its chosen day outgrew its cell.
  Widget build(BuildContext context) => neumorphicWideRoom(
    AlignmentDirectional.topStart,
    MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Builder(builder: _picker),
    ),
    most: 7 * 48,
  );

  Widget _picker(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final words = NeumorphicLocalizations.of(context);
    final firstWeekday = words.firstDayOfWeek;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final lead = (_month.weekday - firstWeekday + 7) % 7;
    final length = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + length) / 7).ceil();
    final previous = DateTime(_month.year, _month.month - 1);
    final next = DateTime(_month.year, _month.month + 1);
    final canPrevious = !DateTime(
      previous.year,
      previous.month + 1,
      0,
    ).isBefore(_first);
    final canNext = !next.isAfter(_last);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            NeumorphicIconButton(
              rtl
                  ? NeumorphicGlyphs.chevronRight
                  : NeumorphicGlyphs.chevronLeft,
              label: words.previousMonth,
              onPressed: widget.onChanged == null || !canPrevious
                  ? null
                  : () => _move(_inMonth(_focused, -1), requestFocus: false),
            ),
            Expanded(
              child: Semantics(
                liveRegion: true,
                header: true,
                child: Text(
                  words.formatMonthYear(_month),
                  style: t.textTheme.title,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            NeumorphicIconButton(
              rtl
                  ? NeumorphicGlyphs.chevronLeft
                  : NeumorphicGlyphs.chevronRight,
              label: words.nextMonth,
              onPressed: widget.onChanged == null || !canNext
                  ? null
                  : () => _move(_inMonth(_focused, 1), requestFocus: false),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, box) {
            final available = box.hasBoundedWidth ? box.maxWidth : 350.0;
            final look = NeumorphicStyleOf([
              widget.style,
              t.datePickerTheme,
            ], const {});
            final inset = (look.shape ?? t.shapes.corner(NeumorphicRadii.cap))
                .dimensions
                .resolve(Directionality.of(context));
            final pad =
                look.padding(Directionality.of(context)) ?? EdgeInsets.zero;
            final width = math.max(
              7.0 *
                  math.max(
                    48.0,
                    math.max(
                      look.minimumSize?.width ?? 0.0,
                      28.0 + inset.horizontal + pad.horizontal,
                    ),
                  ),
              available,
            );
            final cellWidth = width / 7;
            final cellHeight = math.max(
              math.max(48.0, look.minimumSize?.height ?? 0.0),
              MediaQuery.textScalerOf(context)
                      .scale(look.textStyle?.fontSize ?? 22) +
                  14 +
                  inset.vertical +
                  pad.vertical,
            );
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: width,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Row(
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Text(
                                  words.weekdaysShort[(firstWeekday - 1 + i) %
                                      7],
                                  style: t.textTheme.micro,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    for (var row = 0; row < rows; row++)
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Builder(
                              builder: (context) {
                                final day = row * 7 + col - lead + 1;
                                if (day < 1 || day > length) {
                                  return SizedBox(
                                    width: cellWidth,
                                    height: cellHeight,
                                  );
                                }
                                final date = DateTime(
                                  _month.year,
                                  _month.month,
                                  day,
                                );
                                final selected = _sameDay(date, widget.value),
                                    today = _sameDay(date, _today);
                                final enabled =
                                    widget.onChanged != null &&
                                    !date.isBefore(_first) &&
                                    !date.isAfter(_last);
                                final node = _nodes[day - 1];
                                node.skipTraversal = !_sameDay(date, _focused);
                                return SizedBox(
                                  width: cellWidth,
                                  height: cellHeight,
                                  child: NeumorphicTap(
                                    style: widget.style,
                                    themeStyle: t.datePickerTheme,
                                    shape: t.shapes.corner(NeumorphicRadii.cap),
                                    focusNode: node,
                                    focusInset: 2,
                                    radius: NeumorphicRadii.cap,
                                    onKeyEvent: (_, event) => _key(date, event),
                                    selected: selected,
                                    label:
                                        '${words.formatFullDate(date)}${today ? ', ${words.today}' : ''}',
                                    onPressed: !enabled
                                        ? null
                                        : () {
                                            _focused = date;
                                            widget.onChanged!(date);
                                          },
                                    child: Builder(
                                      builder: (context) {
                                        final states = {
                                          ...NeumorphicStatesScope.of(context),
                                          if (selected) WidgetState.selected,
                                          if (!enabled) WidgetState.disabled,
                                        };
                                        final look = NeumorphicStyleOf([
                                          widget.style,
                                          t.datePickerTheme,
                                        ], states);
                                        return Padding(
                                          padding: const EdgeInsets.all(2),
                                          child: NeumorphicOutOfUse(
                                            off: !enabled,
                                            // A figure on the picker's surface; the chosen day alone is a
                                            // well, today only its figure and underline in the pigment.
                                            child: NeumorphicDayFace(
                                              style: widget.style,
                                              themeStyle: t.datePickerTheme,
                                              shape: t.shapes.corner(
                                                NeumorphicRadii.cap,
                                              ),
                                              states: states,
                                              hovered: states.contains(
                                                WidgetState.hovered,
                                              ),
                                              pressed: states.contains(
                                                WidgetState.pressed,
                                              ),
                                              chosen: selected,
                                              child: Center(
                                                // The figure on the face's middle, its mark hung under it (as the calendar's day).
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  alignment: Alignment.center,
                                                  children: [
                                                    Text(
                                                      words.formatDay(date),
                                                      style: t.textTheme.body
                                                          .copyWith(
                                                            color:
                                                                selected ||
                                                                    today
                                                                ? t
                                                                      .colors
                                                                      .pigmentInk
                                                                : null,
                                                            fontWeight:
                                                                selected ||
                                                                    today
                                                                ? FontWeight
                                                                      .w800
                                                                : FontWeight
                                                                      .w500,
                                                          )
                                                          .merge(look.textStyle)
                                                          .copyWith(
                                                            color:
                                                                look.foreground,
                                                          ),
                                                    ),
                                                    PositionedDirectional(
                                                      start: -8,
                                                      end: -8,
                                                      bottom: -6,
                                                      height: 6,
                                                      child: SizedBox(
                                                        height: 6,
                                                        child: Center(
                                                          child: SizedBox(
                                                            width: 8,
                                                            height: 2,
                                                            child: ColoredBox(
                                                              color: today
                                                                  ? t
                                                                        .colors
                                                                        .pigment
                                                                  : const Color(
                                                                      0x00000000,
                                                                    ),
                                                            ),
                                                          ),
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
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// A time of day independent of Material's TimeOfDay.
@immutable
class NeumorphicTime {
  /// Creates a [NeumorphicTime].
  const NeumorphicTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour in the 24-hour range 0 through 23.
  final int hour;

  /// The minute in the range 0 through 59.
  final int minute;

  /// Returns a time with the supplied clock fields replaced.
  NeumorphicTime copyWith({int? hour, int? minute}) =>
      NeumorphicTime(hour ?? this.hour, minute ?? this.minute);

  /// Formats this time using the supplied localizations and clock convention.
  String format({
    bool twentyFour = false,
    NeumorphicLocalizations? localizations,
  }) {
    final words = localizations ?? const NeumorphicLocalizationsEn();
    if (twentyFour) {
      // The standalone value works before an app loads intl date symbols.
      // An installed delegate still owns its locale's time pattern.
      if (localizations != null) {
        return words.formatTime(DateTime(2000, 1, 1, hour, minute));
      }
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    final h = words.formatNumber(hour % 12 == 0 ? 12 : hour % 12);
    final m = words.formatNumber(minute).padLeft(2, words.formatNumber(0));
    return '$h:$m ${hour < 12 ? words.am : words.pm}';
  }

  @override
  bool operator ==(Object other) =>
      other is NeumorphicTime && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => Object.hash(hour, minute);
}

/// A clock value chosen from moulded hour and minute banks, with a 12/24-hour mode.
///
/// ```dart
/// NeumorphicTimePicker(value: time, minuteStep: 15, onChanged: choose)
/// ```
class NeumorphicTimePicker extends StatelessWidget {
  /// Creates a [NeumorphicTimePicker].
  const NeumorphicTimePicker({
    super.key,
    this.value,
    this.onChanged,
    this.minuteStep = 5,
    this.twentyFour,
    this.hourLabel,
    this.minuteLabel,
    this.periodLabel,
    this.style,
  }) : assert(minuteStep > 0 && minuteStep <= 30 && 60 % minuteStep == 0);

  /// Hour, minute and period cells before the time-picker theme.
  final NeumorphicStyle? style;

  /// The selected time, or null for no selection.
  final NeumorphicTime? value;

  /// Reports a user-requested value change; update the supplied value to reflect it.
  final ValueChanged<NeumorphicTime>? onChanged;

  /// The interval between selectable minutes.
  final int minuteStep;

  /// Whether to use 24-hour time; null follows the media query.
  final bool? twentyFour;

  /// An optional localized label for the hour group.
  final String? hourLabel;

  /// An optional localized label for the minute group.
  final String? minuteLabel;

  /// An optional localized label for the AM/PM group.
  final String? periodLabel;
  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context);
    final partStyle = NeumorphicStyle.cascade([style, t.timePickerTheme]);
    final words = NeumorphicLocalizations.of(context);
    final time = value ?? const NeumorphicTime(12, 0);
    final fullDay = twentyFour ?? MediaQuery.alwaysUse24HourFormatOf(context);
    final minutes = {
      for (var i = 0; i < 60; i += minuteStep) i,
      if (value != null) value!.minute,
    }.toList()..sort();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(
            value?.format(twentyFour: fullDay, localizations: words) ??
                words.chooseTime,
            style: t.textTheme.page,
            // On the column's edge, as the hour and minute rows under it start.
            textAlign: TextAlign.start,
          ),
        ),
        const SizedBox(height: 20),
        Text(hourLabel ?? words.hour, style: t.textTheme.caption),
        const SizedBox(height: 8),
        NeumorphicSegmentedButton<int>(
          style: partStyle,
          label: hourLabel ?? words.hour,
          value: value == null
              ? null
              : fullDay
              ? time.hour
              : time.hour % 12,
          segments: [
            for (var hour = 0; hour < (fullDay ? 24 : 12); hour++)
              NeumorphicButtonSegment(
                hour,
                words.formatNumber(!fullDay && hour == 0 ? 12 : hour),
              ),
          ],
          onChanged: onChanged == null
              ? null
              : (hour) => onChanged!(
                  time.copyWith(
                    hour: fullDay ? hour : hour + (time.hour >= 12 ? 12 : 0),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        Text(minuteLabel ?? words.minute, style: t.textTheme.caption),
        const SizedBox(height: 8),
        NeumorphicSegmentedButton<int>(
          style: partStyle,
          label: minuteLabel ?? words.minute,
          value: value?.minute,
          segments: [
            for (final minute in minutes)
              NeumorphicButtonSegment(
                minute,
                words.formatNumber(minute).padLeft(2, words.formatNumber(0)),
              ),
          ],
          onChanged: onChanged == null
              ? null
              : (minute) => onChanged!(time.copyWith(minute: minute)),
        ),
        if (!fullDay) ...[
          const SizedBox(height: 20),
          Text(periodLabel ?? words.period, style: t.textTheme.caption),
          const SizedBox(height: 8),
          NeumorphicSegmentedButton<int>(
            style: partStyle,
            label: periodLabel ?? words.period,
            value: value == null ? null : time.hour ~/ 12,
            segments: [
              NeumorphicButtonSegment(0, words.am),
              NeumorphicButtonSegment(1, words.pm),
            ],
            onChanged: onChanged == null
                ? null
                : (period) => onChanged!(
                    time.copyWith(hour: time.hour % 12 + period * 12),
                  ),
          ),
        ],
      ],
    );
  }
}

/// Raises a calendar in a sheet and returns its value only when confirmed.
///
/// ```dart
/// final date = await showNeumorphicDatePicker(context, value: selected);
/// ```
Future<DateTime?> showNeumorphicDatePicker(
  BuildContext context, {
  DateTime? value,
  DateTime? first,
  DateTime? last,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
  bool useRootNavigator = true,
  NeumorphicStyle? style,
}) {
  final start = _day(first ?? DateTime(1900)),
      end = _day(last ?? DateTime(2100, 12, 31));
  if (start.isAfter(end)) throw ArgumentError('first must not be after last');
  var selected = _clampDay(_day(value ?? DateTime.now()), start, end);
  final words = NeumorphicLocalizations.of(context);
  return showNeumorphicBottomSheet<DateTime>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => NeumorphicBottomSheet(
        title: title ?? words.chooseDate,
        actions: [
          NeumorphicButton(
            cancelLabel ?? words.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          NeumorphicButton.filled(
            confirmLabel ?? words.choose,
            onPressed: () => Navigator.of(context).pop(selected),
          ),
        ],
        child: NeumorphicDatePicker(
          style: style,
          value: selected,
          first: start,
          last: end,
          onChanged: (v) => setState(() => selected = v),
        ),
      ),
    ),
  );
}

/// Raises a clock in a sheet and returns its value only when confirmed.
///
/// ```dart
/// final time = await showNeumorphicTimePicker(context, value: selected);
/// ```
Future<NeumorphicTime?> showNeumorphicTimePicker(
  BuildContext context, {
  NeumorphicTime? value,
  int minuteStep = 5,
  bool? twentyFour,
  String? title,
  String? confirmLabel,
  String? cancelLabel,
  bool useRootNavigator = true,
  NeumorphicStyle? style,
}) {
  final now = DateTime.now();
  var selected = value ?? NeumorphicTime(now.hour, now.minute);
  final words = NeumorphicLocalizations.of(context);
  return showNeumorphicBottomSheet<NeumorphicTime>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => NeumorphicBottomSheet(
        title: title ?? words.chooseTime,
        actions: [
          NeumorphicButton(
            cancelLabel ?? words.cancel,
            onPressed: () => Navigator.of(context).pop(),
          ),
          NeumorphicButton.filled(
            confirmLabel ?? words.choose,
            onPressed: () => Navigator.of(context).pop(selected),
          ),
        ],
        child: NeumorphicTimePicker(
          style: style,
          value: selected,
          minuteStep: minuteStep,
          twentyFour: twentyFour,
          onChanged: (v) => setState(() => selected = v),
        ),
      ),
    ),
  );
}
