import 'dart:math' as math;

import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:intl/intl.dart' show NumberFormat;

import 'component_themes.dart';
import 'acts.dart';
import 'controls.dart';
import 'entries.dart';
import 'glyphs.dart';
import 'internal/caps.dart';
import 'internal/face.dart' show retroDesktopFaceRim;
import 'internal/parts.dart' show retroDesktopHeldGround, retroDesktopSunkenBox;
import 'layout.dart' show RetroDesktopReach;
import 'localizations.dart';
import 'press.dart';
import 'raised.dart';
import 'theme.dart';

DateTime _day(DateTime date) => DateTime(date.year, date.month, date.day);
DateTime _month(DateTime date) => DateTime(date.year, date.month);

/// A calendar value picker. Arrow keys move by day or week; Page Up/Down changes month.
///
/// ```dart
/// RetroDesktopDatePicker(value: DateTime(2026, 11, 6), onChanged: (_) {})
/// ```
class RetroDesktopDatePicker extends StatefulWidget {
  /// Creates a [RetroDesktopDatePicker].
  const RetroDesktopDatePicker({
    super.key,
    this.value,
    this.onChanged,
    this.first,
    this.last,
    this.style,
  });

  /// The selected calendar day, without its time-of-day fields.
  final DateTime? value;

  /// The earliest selectable day, inclusive; defaults to January 1, 1900.
  final DateTime? first;

  /// The latest selectable day, inclusive; defaults to December 31, 2100.
  final DateTime? last;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<DateTime>? onChanged;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  State<RetroDesktopDatePicker> createState() => _DatePickerState();
}

class _DatePickerState extends State<RetroDesktopDatePicker> {
  late DateTime _showing;
  final List<FocusNode> _nodes = List.generate(31, (_) => FocusNode());
  DateTime get _first => _day(widget.first ?? DateTime(1900));
  DateTime get _last => _day(widget.last ?? DateTime(2100, 12, 31));
  bool _available(DateTime date) =>
      !date.isBefore(_first) && !date.isAfter(_last);
  DateTime _clamp(DateTime date) => date.isBefore(_first)
      ? _first
      : date.isAfter(_last)
      ? _last
      : date;
  DateTime get _value => _clamp(_day(widget.value ?? DateTime.now()));
  @override
  void initState() {
    super.initState();
    assert(!_last.isBefore(_first));
    _showing = _month(_value);
  }

  @override
  void didUpdateWidget(RetroDesktopDatePicker old) {
    super.didUpdateWidget(old);
    assert(!_last.isBefore(_first));
    if (old.value != widget.value ||
        old.first != widget.first ||
        old.last != widget.last) {
      _showing = _month(_value);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _moveMonth(int by) => setState(
    () =>
        _showing = _month(_clamp(DateTime(_showing.year, _showing.month + by))),
  );
  KeyEventResult _keys(DateTime date, KeyEvent event) {
    if (widget.onChanged == null ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent)) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    DateTime? next;
    if (key == LogicalKeyboardKey.arrowLeft) {
      next = DateTime(date.year, date.month, date.day + (rtl ? 1 : -1));
    } else if (key == LogicalKeyboardKey.arrowRight) {
      next = DateTime(date.year, date.month, date.day + (rtl ? -1 : 1));
    } else if (key == LogicalKeyboardKey.arrowUp) {
      next = DateTime(date.year, date.month, date.day - 7);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      next = DateTime(date.year, date.month, date.day + 7);
    } else if (key == LogicalKeyboardKey.home) {
      next = DateTime(date.year, date.month, 1);
    } else if (key == LogicalKeyboardKey.end) {
      next = DateTime(date.year, date.month + 1, 0);
    } else if (key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown) {
      final month = date.month + (key == LogicalKeyboardKey.pageUp ? -1 : 1);
      next = DateTime(
        date.year,
        month,
        math.min(date.day, DateTime(date.year, month + 1, 0).day),
      );
    }
    if (next == null) return KeyEventResult.ignored;
    final picked = _clamp(next);
    setState(() => _showing = _month(picked));
    widget.onChanged!(picked);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final target = _nodes[picked.day - 1];
        target.requestFocus();
        if (target.context != null) Scrollable.ensureVisible(target.context!);
      }
    });
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final words = RetroDesktopLocalizations.of(context);
    final t = RetroDesktopTheme.of(context);
    final month = _showing;
    final count = DateTime(month.year, month.month + 1, 0).day;
    // The week starts where the locale's does, as the calendar's does.
    final first = DesignLocalizations.of(context).firstDayOfWeek;
    final before = (month.weekday - first + 7) % 7;
    final rows = ((before + count) / 7).ceil();
    final canBack = _month(_first).isBefore(month);
    final canNext = _month(_last).isAfter(month);
    final target = widget.value != null && _month(_value) == month
        ? _value.day
        : (month == _month(_first) ? _first.day : 1);
    final dayStyle =
        RetroDesktopStyle.first(
          [widget.style, t.datePickerTheme],
          (s) => s.textStyle,
          const {},
        ) ??
        t.type.body;
    final minimum =
        RetroDesktopStyle.first(
          [widget.style, t.datePickerTheme],
          (s) => s.minimumSize,
          const {},
        ) ??
        Size.zero;
    // A day is a whole target: 48 under a finger, 44 under a pointer.
    final slot = math.max(RetroDesktopReach.least(context), minimum.width);
    final week = 7 * slot;
    final height = math.max(
      math.max(slot, minimum.height),
      MediaQuery.textScalerOf(context).scale(dayStyle.fontSize ?? 16) +
          24 * t.density.vertical,
    );
    final title = words.formatMonthYear(month);
    // Seven 48-wide days need 336. The month stands in the calendar's sunken
    // box, as "A calendar" does: one face for both, its edge on the column's.
    // A slot a little short of the box takes the shortfall from the box's side
    // padding, so its face stays on the column's edges and every day keeps its
    // whole target; up to 24 more (a phone window's 328, its 324 at the
    // comfortable density) overhangs the padding by half the rest on each
    // side, the picker whole and centred; narrower slots share out the week. From 600 up a month keeps its own width at its
    // column's start, not the column's.
    final pad = RetroDesktopReach.least(context) >= 44 ? 4.0 : 8.0;
    final h = t.density.horizontal;
    // The density rounds a padding to whole pixels: the side is reckoned in
    // them, so what the box takes is what it is asked for.
    final side = (pad * h).roundToDouble();
    final frame = 2 * (side + retroDesktopFaceRim(t));
    Widget boxed(Widget picker, {double give = 0}) => retroDesktopSunkenBox(
      context,
      states: const {},
      padding: EdgeInsets.symmetric(
        horizontal: (side - give / 2) / h,
        vertical: pad,
      ),
      child: picker,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        var over = constraints.hasBoundedWidth
            ? week + frame - constraints.maxWidth
            : 0.0;
        var give = over > 0
            ? 2.0 * math.min((over / 2).ceilToDouble(), side - 1)
            : 0.0;
        var short = over - give;
        // A column too narrow for seven whole targets (a window inside a phone's page, 268) narrows the days to share
        // it, down to the calendar's 36 a day, rather than scroll the weekend out of sight: each day keeps its height.
        var days = week;
        if (short > 24) {
          days = math.max(
            7 * 36.0,
            7 * ((constraints.maxWidth - frame) / 7).floorToDouble(),
          );
          over = days + frame - constraints.maxWidth;
          give = 0;
          short = over;
        }
        if (MediaQuery.sizeOf(context).width >= 600 && over < 0) {
          return Align(
            alignment: AlignmentDirectional.topStart,
            widthFactor: 1,
            heightFactor: 1,
            child: SizedBox(
              width: week + frame,
              child: boxed(
                _picker(
                  context,
                  words,
                  t,
                  month,
                  count,
                  before,
                  first,
                  rows,
                  canBack,
                  canNext,
                  target,
                  dayStyle,
                  height,
                  week,
                  title,
                ),
              ),
            ),
          );
        }
        final picker = boxed(
          give: give,
          _picker(
            context,
            words,
            t,
            month,
            count,
            before,
            first,
            rows,
            canBack,
            canNext,
            target,
            dayStyle,
            height,
            days,
            title,
          ),
        );
        if (short <= 0 || short > 24) return picker;
        return OverflowBox(
          fit: OverflowBoxFit.deferToChild,
          minWidth: days + frame - give,
          maxWidth: days + frame - give,
          child: picker,
        );
      },
    );
  }

  Widget _picker(
    BuildContext context,
    RetroDesktopLocalizations words,
    RetroDesktopThemeData t,
    DateTime month,
    int count,
    int before,
    int first,
    int rows,
    bool canBack,
    bool canNext,
    int target,
    TextStyle dayStyle,
    double height,
    double week,
    String title,
  ) {
    final today = _day(DateTime.now());
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The month between its two steps, one group in the middle: not a
        // step at each edge of a wide calendar.
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              RetroDesktopIconButton(
                // The arrows point the way the months run: the other way right to left.
                Directionality.of(context) == TextDirection.rtl
                    ? RetroDesktopGlyphs.chevronRight
                    : RetroDesktopGlyphs.chevronLeft,
                label: DesignLocalizations.of(context).previousMonthTooltip,
                onPressed: widget.onChanged != null && canBack
                    ? () => _moveMonth(-1)
                    : null,
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Semantics(
                    liveRegion: true,
                    // The calendar's month head and weekday names, one style
                    // for both pickers.
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      style: t.type.chrome.copyWith(color: t.colors.text),
                    ),
                  ),
                ),
              ),
              RetroDesktopIconButton(
                Directionality.of(context) == TextDirection.rtl
                    ? RetroDesktopGlyphs.chevronLeft
                    : RetroDesktopGlyphs.chevronRight,
                label: DesignLocalizations.of(context).nextMonthTooltip,
                onPressed: widget.onChanged != null && canNext
                    ? () => _moveMonth(1)
                    : null,
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            // The weekday heads keep a gap between them: where the widest short name fills its column (twice the
            // text size on a phone ran "SuMoTuWe" together), each shows its first letter, as a narrow calendar does.
            final column =
                math.max(
                  week - 1,
                  constraints.hasBoundedWidth ? constraints.maxWidth : week,
                ) /
                7;
            final headStyle = t.type.small.copyWith(
              color: t.colors.textSecondary,
            );
            final widest = words.weekdaysShort.fold(0.0, (w, name) {
              final p = TextPainter(
                text: TextSpan(text: name, style: headStyle),
                textDirection: Directionality.of(context),
                textScaler: MediaQuery.textScalerOf(context),
                maxLines: 1,
              )..layout();
              final width = p.width;
              p.dispose();
              return math.max(w, width);
            });
            final heads = [
              for (final name in words.weekdaysShort)
                widest > column - 6 ? name.characters.first : name,
            ];
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              // Seven columns sharing the slot; only one narrower than seven
              // 36 px days scrolls the week.
              child: SizedBox(
                width: math.max(
                  week - 1,
                  constraints.hasBoundedWidth ? constraints.maxWidth : week,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                heads[(first - 1 + col) % 7],
                                textAlign: TextAlign.center,
                                style: headStyle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    for (var row = 0; row < rows; row++)
                      Row(
                        children: [
                          for (var col = 0; col < 7; col++)
                            Expanded(
                              child: Builder(
                                builder: (context) {
                                  final day = row * 7 + col - before + 1;
                                  if (day < 1 || day > count) {
                                    return SizedBox(height: height);
                                  }
                                  final date = DateTime(
                                    month.year,
                                    month.month,
                                    day,
                                  );
                                  final chosen =
                                      widget.value != null &&
                                      _day(widget.value!) == date;
                                  _nodes[day - 1].skipTraversal = day != target;
                                  return Focus(
                                    canRequestFocus: false,
                                    skipTraversal: true,
                                    includeSemantics: false,
                                    onKeyEvent: (_, event) =>
                                        _keys(date, event),
                                    child: RetroDesktopPressable(
                                      label: words.formatDate(date),
                                      selected: chosen,
                                      focusNode: _nodes[day - 1],
                                      onPressed:
                                          widget.onChanged != null &&
                                              _available(date)
                                          ? () {
                                              _nodes[day - 1].requestFocus();
                                              widget.onChanged!(date);
                                            }
                                          : null,
                                      builder: (context, states) {
                                        T? slot<T>(
                                          WidgetStateProperty<T?>? Function(
                                            RetroDesktopStyle,
                                          )
                                          read,
                                        ) => RetroDesktopStyle.first(
                                          [widget.style, t.datePickerTheme],
                                          read,
                                          states,
                                        );
                                        // The calendar's day: plain on the
                                        // paper, the chosen day lit in the
                                        // highlight, today outlined, a held day
                                        // greyed; the whole slot is the target.
                                        final isToday = date == today;
                                        final fill =
                                            slot((s) => s.fill) ??
                                            (chosen
                                                ? t.colors.highlight
                                                : null);
                                        final ink =
                                            slot((s) => s.foreground) ??
                                            (chosen
                                                ? t.colors.onHighlight
                                                : t.colors.text);
                                        final shape =
                                            (slot((s) => s.shape) ??
                                                    t.shapes.small)
                                                .copyWith(
                                                  side:
                                                      slot((s) => s.side) ??
                                                      (isToday && !chosen
                                                          ? BorderSide(
                                                              color:
                                                                  slot(
                                                                    (s) =>
                                                                        s.edge,
                                                                  ) ??
                                                                  t.colors.text,
                                                              width: t
                                                                  .strokes
                                                                  .regular,
                                                            )
                                                          : BorderSide.none),
                                                );
                                        // The face draws its own focus ring,
                                        // inside its slot, as a calendar day's.
                                        return SizedBox(
                                          height: height,
                                          child: Builder(
                                            builder: (context) {
                                              RetroDesktopHighlightClaim.maybeOf(
                                                context,
                                              )?.claim(context, states);
                                              return RetroDesktopHighlight(
                                                shape: shape,
                                                inside: true,
                                                focused: states.contains(
                                                  WidgetState.focused,
                                                ),
                                                child: retroDesktopHeldGround(
                                                  t,
                                                  held:
                                                      !chosen &&
                                                      states.contains(
                                                        WidgetState.pressed,
                                                      ),
                                                  child: DecoratedBox(
                                                    decoration: ShapeDecoration(
                                                      color: fill,
                                                      shape: shape,
                                                    ),
                                                    // A number shrinks to its slot rather than run into the next day's (a
                                                    // phone column at twice the text size).
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 2,
                                                          ),
                                                      child: Center(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: RetroDesktopCaps(
                                                            style: slot(
                                                              (s) =>
                                                                  s.textStyle,
                                                            ),
                                                            Text(
                                                              words
                                                                  .formatInteger(
                                                                    day,
                                                                  ),
                                                              style:
                                                                  (slot(
                                                                            (
                                                                              s,
                                                                            ) =>
                                                                                s.textStyle,
                                                                          ) ??
                                                                          t.type.body)
                                                                      .copyWith(
                                                                        color:
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
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
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
      ],
    );
  }
}

/// Opens a date dialog; Cancel, Escape and the barrier return null.
Future<DateTime?> showRetroDesktopDatePicker(
  BuildContext context, {
  DateTime? value,
  DateTime? first,
  DateTime? last,
  String? title,
}) {
  final words = RetroDesktopLocalizations.of(context);
  final begin = _day(first ?? DateTime(1900));
  final end = _day(last ?? DateTime(2100, 12, 31));
  assert(!end.isBefore(begin));
  final initial = _day(value ?? DateTime.now());
  var selected = initial.isBefore(begin)
      ? begin
      : initial.isAfter(end)
      ? end
      : initial;
  return showRetroDesktopDialog<DateTime>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, change) => RetroDesktopDialog(
        title: title ?? words.chooseDate,
        content: [
          RetroDesktopDatePicker(
            value: selected,
            first: first,
            last: last,
            onChanged: (date) => change(() => selected = date),
          ),
        ],
        actions: [
          RetroDesktopButton(
            DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          RetroDesktopButton(
            words.choose,
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, selected),
          ),
        ],
      ),
    ),
  );
}

/// A clock time without a date, timezone or dependency on Material's TimeOfDay.
@immutable
class RetroDesktopTime {
  /// Creates a [RetroDesktopTime].
  const RetroDesktopTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour of the day, from 0 through 23.
  final int hour;

  /// The minute of the hour, from 0 through 59.
  final int minute;

  /// Returns a copy with the supplied values replaced.
  RetroDesktopTime copyWith({int? hour, int? minute}) =>
      RetroDesktopTime(hour ?? this.hour, minute ?? this.minute);

  /// Formats a value for display and accessibility.
  String format({
    bool use24Hour = true,
    String am = 'AM',
    String pm = 'PM',
    String locale = 'en',
  }) {
    final digits = NumberFormat('00', locale);
    final shownHour = use24Hour ? hour : (hour % 12 == 0 ? 12 : hour % 12);
    return '${digits.format(shownHour)}:${digits.format(minute)}${use24Hour ? '' : ' ${hour < 12 ? am : pm}'}';
  }

  @override
  bool operator ==(Object other) =>
      other is RetroDesktopTime && hour == other.hour && minute == other.minute;
  @override
  int get hashCode => Object.hash(hour, minute);
  @override
  String toString() => format();
}

/// A value-controlled time picker with keyboard menus for the hour and minute.
///
/// ```dart
/// RetroDesktopTimePicker(value: const RetroDesktopTime(9, 30), onChanged: (_) {})
/// ```
class RetroDesktopTimePicker extends StatelessWidget {
  /// Creates a [RetroDesktopTimePicker].
  const RetroDesktopTimePicker({
    super.key,
    this.value,
    this.onChanged,
    this.use24Hour,
    this.style,
  });

  /// The current value to display or edit.
  final RetroDesktopTime? value;

  /// Reports the value selected by the user; null prevents changes.
  final ValueChanged<RetroDesktopTime>? onChanged;

  /// Whether to use a 24-hour clock; null follows the host preference.
  final bool? use24Hour;

  /// Overrides this part's component theme; unresolved slots keep their themed values.
  final RetroDesktopStyle? style;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    final appearance = (style ?? const RetroDesktopStyle()).merge(
      t.timePickerTheme,
    );
    final words = RetroDesktopLocalizations.of(context);
    final time = value ?? const RetroDesktopTime(12, 0);
    final twentyFour = use24Hour ?? MediaQuery.alwaysUse24HourFormatOf(context);
    final hours = twentyFour
        ? List.generate(24, (i) => i)
        : List.generate(12, (i) => i == 0 ? 12 : i);
    final hour = twentyFour
        ? time.hour
        : time.hour % 12 == 0
        ? 12
        : time.hour % 12;
    // The three fields stand on one line by their feet: a name that breaks
    // onto a second line ("Morning or evening" in Chisel's wider face) rises
    // above its field rather than pushing it below its neighbours'.
    return Wrap(
      spacing: 12 * t.density.horizontal,
      runSpacing: 12 * t.density.vertical,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        SizedBox(
          width: 128,
          child: RetroDesktopSelect<int>(
            label: words.hour,
            value: hour,
            style: appearance,
            options: [
              for (final hour in hours)
                RetroDesktopOption(hour, words.formatInteger(hour, digits: 2)),
            ],
            onChanged: onChanged == null
                ? null
                : (hour) => onChanged!(
                    time.copyWith(
                      hour: twentyFour
                          ? hour
                          : hour % 12 + (time.hour >= 12 ? 12 : 0),
                    ),
                  ),
          ),
        ),
        SizedBox(
          width: 128,
          child: RetroDesktopSelect<int>(
            label: words.minute,
            value: time.minute,
            style: appearance,
            options: [
              for (var minute = 0; minute < 60; minute++)
                RetroDesktopOption(
                  minute,
                  words.formatInteger(minute, digits: 2),
                ),
            ],
            onChanged: onChanged == null
                ? null
                : (minute) => onChanged!(time.copyWith(minute: minute)),
          ),
        ),
        if (!twentyFour)
          SizedBox(
            width: 128,
            child: RetroDesktopSelect<bool>(
              label: words.period,
              value: time.hour >= 12,
              style: appearance,
              options: [
                RetroDesktopOption(false, words.am),
                RetroDesktopOption(true, words.pm),
              ],
              onChanged: onChanged == null
                  ? null
                  : (pm) => onChanged!(
                      time.copyWith(hour: time.hour % 12 + (pm ? 12 : 0)),
                    ),
            ),
          ),
      ],
    );
  }
}

/// Opens a clock dialog and returns the confirmed time.
Future<RetroDesktopTime?> showRetroDesktopTimePicker(
  BuildContext context, {
  RetroDesktopTime? value,
  String? title,
  bool? use24Hour,
}) {
  final words = RetroDesktopLocalizations.of(context);
  var selected =
      value ?? RetroDesktopTime(DateTime.now().hour, DateTime.now().minute);
  return showRetroDesktopDialog<RetroDesktopTime>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, change) => RetroDesktopDialog(
        title: title ?? words.chooseTime,
        content: [
          RetroDesktopTimePicker(
            value: selected,
            use24Hour: use24Hour,
            onChanged: (time) => change(() => selected = time),
          ),
        ],
        actions: [
          RetroDesktopButton(
            DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          RetroDesktopButton(
            words.choose,
            isDefaultAction: true,
            onPressed: () => Navigator.pop(context, selected),
          ),
        ],
      ),
    ),
  );
}
