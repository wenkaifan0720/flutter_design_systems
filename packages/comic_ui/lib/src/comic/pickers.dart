/// Date and time choices in the comic's caption grid, without a platform skin.
library;

import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' show DateFormat;

import 'glyphs.dart';

import 'controls.dart';
import 'entries.dart';
import 'localizations.dart';
import 'press.dart';
import 'raised.dart';
import 'theme.dart';
import 'component_themes.dart';
import 'styled.dart';
import 'internal/cap_label.dart';

DateTime _day(DateTime day) => DateTime(day.year, day.month, day.day);
String _locale(BuildContext context) {
  final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en_US';
  return DateFormat.localeExists(locale) ? locale : 'en_US';
}

/// A month of caption cells, at most [maxWidth] wide and standing at the start of a wider column. Arrows move by day
/// or week; Page Up and Down change month.
///
/// ```dart
/// ComicDatePicker(value: day, firstDate: opens, lastDate: closes, onChanged: select)
/// ```
class ComicDatePicker extends StatefulWidget {
  /// Creates a date picker.
  const ComicDatePicker({
    super.key,
    this.style,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.currentDate,
    this.firstWeekday = DateTime.monday,
    this.monthNames,
    this.dayNames,
    this.previousLabel,
    this.nextLabel,
  }) : assert(firstWeekday >= 1 && firstWeekday <= 7),
       assert(monthNames == null || monthNames.length == 12),
       assert(dayNames == null || dayNames.length == 7);

  /// Chosen date, ignoring time.
  final DateTime? value;

  /// Selects a date; absent disables selection.
  final ValueChanged<DateTime>? onChanged;

  /// Earliest allowed date, inclusive.
  final DateTime? firstDate;

  /// Latest allowed date, inclusive.
  final DateTime? lastDate;

  /// Overrides the device's current date.
  final DateTime? currentDate;

  /// First column, with Monday as 1 and Sunday as 7.
  final int firstWeekday;

  /// Optional month names, January first.
  final List<String>? monthNames;

  /// Optional weekday names, Monday first.
  final List<String>? dayNames;

  /// Overrides the localized previous-month label.
  final String? previousLabel;

  /// Overrides the localized next-month label.
  final String? nextLabel;

  /// Appearance above the picker component theme.
  final ComicStyle? style;

  /// A day's cell, wide and tall: a touch's least target. Every month Comic draws ([ComicCalendar], the range picker)
  /// takes it, so two calendars on one screen share their grid.
  static const double dayWidth = 48;

  /// The widest a month stands: seven days of [dayWidth]. Spread over a desktop column its days read as a table, not a
  /// picker (the design kit's checks reads a week as a group of choices, held to what its days take).
  static const double maxWidth = 7 * dayWidth;

  @override
  State<ComicDatePicker> createState() => _ComicDatePickerState();
}

class _ComicDatePickerState extends State<ComicDatePicker> {
  late DateTime _cursor, _month;
  final _nodes = List.generate(31, (_) => FocusNode());
  DateTime get _today => _day(widget.currentDate ?? DateTime.now());
  DateTime _bound(DateTime value) {
    if (widget.firstDate != null && value.isBefore(_day(widget.firstDate!))) {
      return _day(widget.firstDate!);
    }
    if (widget.lastDate != null && value.isAfter(_day(widget.lastDate!))) {
      return _day(widget.lastDate!);
    }
    return value;
  }

  bool _can(DateTime date) =>
      (widget.firstDate == null || !date.isBefore(_day(widget.firstDate!))) &&
      (widget.lastDate == null || !date.isAfter(_day(widget.lastDate!)));
  @override
  void initState() {
    super.initState();
    _cursor = _bound(_day(widget.value ?? _today));
    _month = DateTime(_cursor.year, _cursor.month);
  }

  @override
  void didUpdateWidget(ComicDatePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && widget.value != null) {
      _cursor = _bound(_day(widget.value!));
      _month = DateTime(_cursor.year, _cursor.month);
    } else if (old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate) {
      _cursor = _bound(_cursor);
      _month = DateTime(_cursor.year, _cursor.month);
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _walk(DateTime date, {bool focus = true}) {
    if (!_can(date)) return;
    setState(() {
      _cursor = date;
      _month = DateTime(date.year, date.month);
    });
    if (focus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final node = _nodes[date.day - 1];
        node.requestFocus();
        final target = node.context;
        if (target != null) Scrollable.ensureVisible(target);
      });
    }
  }

  DateTime _shiftMonth(int by) {
    final month = DateTime(_cursor.year, _cursor.month + by);
    return DateTime(
      month.year,
      month.month,
      math.min(_cursor.day, DateTime(month.year, month.month + 1, 0).day),
    );
  }

  KeyEventResult _keys(KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey,
        rtl = Directionality.of(context) == TextDirection.rtl;
    DateTime at(int days) =>
        DateTime(_cursor.year, _cursor.month, _cursor.day + days);
    final next = key == LogicalKeyboardKey.arrowRight
        ? at(rtl ? -1 : 1)
        : key == LogicalKeyboardKey.arrowLeft
        ? at(rtl ? 1 : -1)
        : key == LogicalKeyboardKey.arrowDown
        ? at(7)
        : key == LogicalKeyboardKey.arrowUp
        ? at(-7)
        : key == LogicalKeyboardKey.pageDown
        ? _shiftMonth(1)
        : key == LogicalKeyboardKey.pageUp
        ? _shiftMonth(-1)
        : key == LogicalKeyboardKey.home
        ? DateTime(_cursor.year, _cursor.month)
        : key == LogicalKeyboardKey.end
        ? DateTime(_cursor.year, _cursor.month + 1, 0)
        : null;
    if (next == null) return KeyEventResult.ignored;
    _walk(_bound(next));
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.firstDate == null ||
          widget.lastDate == null ||
          !_day(widget.firstDate!).isAfter(_day(widget.lastDate!)),
    );
    final t = ComicTheme.of(context), locale = _locale(context);
    // Reserve the measured day label and its actual outline insets. An
    // arbitrary text allowance made even an ordinary phone scroll sideways.
    var minimumDayWidth = 48.0;
    final direction = Directionality.of(context);
    for (final states in const <Set<WidgetState>>[
      {},
      {WidgetState.selected},
      {WidgetState.disabled},
    ]) {
      final look = ComicStyleOf([widget.style, t.datePickerTheme], states);
      final shape = look.shape ?? t.shapes.small;
      final rim = comicRim(
        t,
        look,
        t.colors.divider,
        states.contains(WidgetState.selected) ? 2.5 : 1,
      );
      final inset = shape
          .copyWith(side: rim)
          .dimensions
          .resolve(direction)
          .horizontal;
      final padding = (look.padding(direction)?.horizontal ?? 0) + 8;
      final painter = TextPainter(
        textDirection: direction,
        textScaler: MediaQuery.textScalerOf(context),
      );
      for (var day = 1; day <= 31; day++) {
        painter.text = TextSpan(
          text: '$day',
          style: t.type.body.merge(look.textStyle),
        );
        painter.layout();
        minimumDayWidth = math.max(
          minimumDayWidth,
          (painter.width + inset + padding).ceilToDouble(),
        );
      }
      painter.dispose();
    }
    final count = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = (_month.weekday - widget.firstWeekday + 7) % 7;
    final heading = widget.monthNames == null
        ? DateFormat.yMMMM(locale).format(_month)
        : '${widget.monthNames![_month.month - 1]} ${_month.year}';
    final canBack =
        widget.firstDate == null ||
        _month.isAfter(
          DateTime(widget.firstDate!.year, widget.firstDate!.month),
        );
    final canNext =
        widget.lastDate == null ||
        _month.isBefore(
          DateTime(widget.lastDate!.year, widget.lastDate!.month),
        );
    Widget cell(int day) {
      final date = DateTime(_month.year, _month.month, day),
          selected = widget.value != null && date == _day(widget.value!);
      final live = widget.onChanged != null && _can(date);
      _nodes[day - 1].skipTraversal = date != _cursor;
      return ComicPressable(
        label: DateFormat.yMMMMd(locale).format(date),
        selected: selected,
        focusNode: _nodes[day - 1],
        keys: (_, event) => _keys(event),
        onPressed: live
            ? () {
                setState(() => _cursor = date);
                widget.onChanged!(date);
              }
            : null,
        sink: false,
        overlay: ComicStyleOf([
          widget.style,
          t.datePickerTheme,
        ], const {}).overlay,
        outline: ComicStyleOf([
          widget.style,
          t.datePickerTheme,
        ], const {}).shapes(t.shapes.small),
        builder: (context, states) {
          final look = ComicStyleOf([widget.style, t.datePickerTheme], states);
          final rim = comicRim(
            t,
            look,
            selected ? t.colors.nightLine : t.colors.divider,
            selected ? 2.5 : 1,
          );
          // Every day reserves the thickest rim a day can have, so choosing
          // one never moves the rows under it (a decorated Container adds its
          // rim to its padding: a chosen day's 2.5 rim stood 3 px taller than
          // the 1 px days beside it, and its row grew).
          final reserve = [
            for (final (s, w) in const [
              (<WidgetState>{}, 1.0),
              ({WidgetState.selected}, 2.5),
            ])
              comicRim(
                t,
                ComicStyleOf([widget.style, t.datePickerTheme], s),
                t.colors.divider,
                w,
              ).width,
          ].reduce(math.max);
          return AnimatedComicShape(
            shape: look.shape ?? t.shapes.small,
            builder: (context, shape) => ComicStateDecoration(
              decoration: ShapeDecoration(
                color: look.fill ?? (selected ? t.colors.caption : null),
                shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                  side: rim,
                ),
              ),
              // A day is as tall as it is wide, as a month's days in the calendar: its number stands in the middle.
              child: Container(
                height: ComicDatePicker.dayWidth,
                alignment: Alignment.center,
                padding:
                    (look.padding(Directionality.of(context)) ??
                            EdgeInsets.zero)
                        .add(
                          shape == null
                              ? EdgeInsets.zero
                              : const EdgeInsets.symmetric(horizontal: 4),
                        )
                        .add(EdgeInsets.all(reserve)),
                // The number alone sets the cell, its capitals on the middle; today's dot is laid over the cell
                // under it, so today stands as tall as the days beside it (ui_core's DesignRowCheck: 4 px taller).
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    CapLabel(
                      display: false,
                      child: Text(
                        '$day',
                        style: t.type.body
                            .merge(look.textStyle)
                            .copyWith(
                              color:
                                  look.foreground ??
                                  (selected
                                      ? t.colors.onCaption
                                      : t.colors.text),
                            ),
                      ),
                    ),
                    if (date == _today)
                      Positioned(
                        bottom: -5,
                        child: ComicStateDecoration(
                          decoration: ShapeDecoration(
                            color: selected
                                ? t.colors.onCaption
                                : t.colors.text,
                            shape: t.shapes.full,
                          ),
                          child: const SizedBox(width: 4, height: 4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final rtl = Directionality.of(context) == TextDirection.rtl;
    final previous = ComicIconButton(
      rtl ? ComicGlyphs.chevronRight : ComicGlyphs.chevronLeft,
      label:
          widget.previousLabel ??
          DesignLocalizations.of(context).previousMonthTooltip,
      onPressed: canBack
          ? () => _walk(_bound(_shiftMonth(-1)), focus: false)
          : null,
    );
    final next = ComicIconButton(
      rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight,
      label:
          widget.nextLabel ?? DesignLocalizations.of(context).nextMonthTooltip,
      onPressed: canNext
          ? () => _walk(_bound(_shiftMonth(1)), focus: false)
          : null,
    );
    final month = Semantics(
      header: true,
      liveRegion: true,
      child: Text(heading, style: t.type.title, textAlign: TextAlign.center),
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: ComicDatePicker.maxWidth),
        child: _grid(previous, next, month, count, lead, cell, minimumDayWidth),
      ),
    );
  }

  /// The month's head and its weeks, in the width [build] gives them.
  Widget _grid(
    Widget previous,
    Widget next,
    Widget month,
    int count,
    int lead,
    Widget Function(int) cell,
    double minimumDayWidth,
  ) {
    final t = ComicTheme.of(context);
    final words = ComicLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, box) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (box.maxWidth < 200)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                month,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: [previous, next],
                ),
              ],
            )
          else
            Row(
              children: [
                previous,
                Expanded(child: month),
                next,
              ],
            ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: math.max(
                7 * minimumDayWidth,
                box.hasBoundedWidth ? box.maxWidth : 336,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ExcludeSemantics(
                    child: Row(
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Text(
                                (widget.dayNames ??
                                    words.weekdaysShort)[(widget.firstWeekday -
                                        1 +
                                        i) %
                                    7],
                                textAlign: TextAlign.center,
                                style: t.type.small,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (var row = 0; row < (count + lead + 6) ~/ 7; row++)
                    Row(
                      children: [
                        for (var col = 0; col < 7; col++)
                          Expanded(
                            child:
                                row * 7 + col - lead + 1 < 1 ||
                                    row * 7 + col - lead + 1 > count
                                ? const SizedBox(
                                    height: ComicDatePicker.dayWidth,
                                  )
                                : cell(row * 7 + col - lead + 1),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A value representing a time of day without a Material type.
@immutable
class ComicTime {
  /// Creates a time with a 24-hour hour and a minute.
  const ComicTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// Hour, 0 through 23.
  final int hour;

  /// Minute, 0 through 59.
  final int minute;

  /// Formats the time with intl in an initialized locale.
  String format({bool use24hFormat = false, String locale = 'en_US'}) =>
      (use24hFormat ? DateFormat.Hm(locale) : DateFormat.jm(locale)).format(
        DateTime(2000, 1, 1, hour, minute),
      );
  @override
  bool operator ==(Object other) =>
      other is ComicTime && other.hour == hour && other.minute == minute;
  @override
  int get hashCode => Object.hash(hour, minute);
}

/// Time selected from labelled caption menus, wrapping at narrow widths.
///
/// ```dart
/// ComicTimePicker(value: ComicTime(19,30), minuteStep: 15, onChanged: select)
/// ```
class ComicTimePicker extends StatelessWidget {
  /// Creates a time picker. A missing callback disables every choice.
  const ComicTimePicker({
    super.key,
    this.style,
    this.value,
    this.onChanged,
    this.minuteStep = 1,
    this.use24hFormat,
    this.hourLabel,
    this.minuteLabel,
    this.periodLabel,
  }) : assert(minuteStep > 0 && minuteStep <= 60 && 60 % minuteStep == 0);

  /// Current time, or midnight as the initial editing position.
  final ComicTime? value;

  /// Reports a new time.
  final ValueChanged<ComicTime>? onChanged;

  /// Minute increments; must divide 60.
  final int minuteStep;

  /// Uses 24 hours without a period menu; null follows the platform's setting
  /// ([MediaQuery.alwaysUse24HourFormatOf]).
  final bool? use24hFormat;

  /// Overrides the localized hour label.
  final String? hourLabel;

  /// Overrides the localized minute label.
  final String? minuteLabel;

  /// Overrides the localized period label.
  final String? periodLabel;

  /// Appearance above the picker component theme.
  final ComicStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = ComicLocalizations.of(context),
        time = value ?? const ComicTime(0, 0),
        h24 = use24hFormat ?? MediaQuery.alwaysUse24HourFormatOf(context);
    final minutes = {
      for (var i = 0; i < 60; i += minuteStep) i,
      time.minute,
    }.toList()..sort();
    final layers = ComicStyle.layered([
      style,
      ComicTheme.of(context).timePickerTheme,
    ]);
    final selects = <Widget>[
      ComicSelect<int>(
        style: layers,
        label: hourLabel ?? words.hour,
        value: h24 ? time.hour : time.hour % 12,
        options: [
          for (var hour = 0; hour < (h24 ? 24 : 12); hour++)
            ComicSelectOption(
              hour,
              '${h24
                  ? hour
                  : hour == 0
                  ? 12
                  : hour}',
            ),
        ],
        onChanged: onChanged == null
            ? null
            : (hour) => onChanged!(
                ComicTime(
                  h24 ? hour : hour + (time.hour >= 12 ? 12 : 0),
                  time.minute,
                ),
              ),
      ),
      ComicSelect<int>(
        style: layers,
        label: minuteLabel ?? words.minute,
        value: time.minute,
        options: [
          for (final minute in minutes)
            ComicSelectOption(minute, minute.toString().padLeft(2, '0')),
        ],
        onChanged: onChanged == null
            ? null
            : (minute) => onChanged!(ComicTime(time.hour, minute)),
      ),
      if (!h24)
        ComicSelect<int>(
          style: layers,
          label: periodLabel ?? words.period,
          value: time.hour ~/ 12,
          options: [
            ComicSelectOption(0, words.am),
            ComicSelectOption(1, words.pm),
          ],
          onChanged: onChanged == null
              ? null
              : (period) => onChanged!(
                  ComicTime(time.hour % 12 + period * 12, time.minute),
                ),
        ),
    ];
    // Hour, minute and AM or PM on one row of equal selects, each label on one line, up to 160 a select; under
    // 96 a select (a phone's narrow column) they stack. The least grows with the text: at 200% on a phone the labels
    // would break mid-word ("Minut e") and the selects stand at different heights under them.
    const gap = 12.0, most = 160.0;
    final least = math.min(most, MediaQuery.textScalerOf(context).scale(96));
    return LayoutBuilder(
      builder: (context, box) {
        final n = selects.length;
        final room = box.hasBoundedWidth
            ? box.maxWidth
            : n * most + (n - 1) * gap;
        final each = math.min(most, (room - (n - 1) * gap) / n);
        if (each < least) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < n; i++) ...[
                if (i > 0) const SizedBox(height: gap),
                selects[i],
              ],
            ],
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < n; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              SizedBox(width: each, child: selects[i]),
            ],
          ],
        );
      },
    );
  }
}

/// Raises a calendar and returns the confirmed day, or null on dismissal.
///
/// ```dart
/// final day = await showComicDatePicker(context, value: selected);
/// ```
Future<DateTime?> showComicDatePicker(
  BuildContext context, {
  DateTime? value,
  DateTime? firstDate,
  DateTime? lastDate,
  DateTime? currentDate,
  String? title,
  String? confirm,
  String? cancel,
}) {
  assert(
    firstDate == null ||
        lastDate == null ||
        !_day(firstDate).isAfter(_day(lastDate)),
  );
  DateTime? picked = value == null ? null : _day(value);
  if (picked != null && firstDate != null && picked.isBefore(_day(firstDate))) {
    picked = _day(firstDate);
  }
  if (picked != null && lastDate != null && picked.isAfter(_day(lastDate))) {
    picked = _day(lastDate);
  }
  return showComicDialog<DateTime>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => ComicDialog(
        title: title ?? ComicLocalizations.of(context).chooseDate,
        content: [
          ComicDatePicker(
            value: picked,
            firstDate: firstDate,
            lastDate: lastDate,
            currentDate: currentDate,
            onChanged: (day) => setState(() => picked = day),
          ),
        ],
        actions: [
          ComicButton(
            cancel ?? DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          ComicButton.filled(
            confirm ?? ComicLocalizations.of(context).choose,
            size: ComicButtonSize.small,
            onPressed: picked == null
                ? null
                : () => Navigator.pop(context, picked),
          ),
        ],
      ),
    ),
  );
}

/// Raises a clock and returns the confirmed time, or null on dismissal.
///
/// ```dart
/// final time = await showComicTimePicker(context, value: ComicTime(19,30));
/// ```
Future<ComicTime?> showComicTimePicker(
  BuildContext context, {
  ComicTime? value,
  int minuteStep = 1,
  bool? use24hFormat,
  String? title,
  String? confirm,
  String? cancel,
}) {
  var picked = value;
  return showComicDialog<ComicTime>(
    context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => ComicDialog(
        title: title ?? ComicLocalizations.of(context).chooseTime,
        content: [
          ComicTimePicker(
            value: picked,
            minuteStep: minuteStep,
            use24hFormat: use24hFormat,
            onChanged: (time) => setState(() => picked = time),
          ),
        ],
        actions: [
          ComicButton(
            cancel ?? DesignLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          ComicButton.filled(
            confirm ?? ComicLocalizations.of(context).choose,
            size: ComicButtonSize.small,
            onPressed: picked == null
                ? null
                : () => Navigator.pop(context, picked),
          ),
        ],
      ),
    ),
  );
}
