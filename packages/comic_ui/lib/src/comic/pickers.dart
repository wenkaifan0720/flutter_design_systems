/// Date and time choices in the comic's caption grid, without a platform skin.
library;

import 'package:flutter/foundation.dart';
import 'package:ui_core/ui_core.dart';

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
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
import 'internal/lamp_line.dart';
import 'internal/lettering.dart'
    show comicCalendarScaleMost, comicTimeScaleMost;
import 'knobs.dart' show ComicSpace;
import 'internal/style_guard.dart';

DateTime _day(DateTime day) => DateTime(day.year, day.month, day.day);
String _locale(BuildContext context) {
  final locale = Localizations.maybeLocaleOf(context)?.toString() ?? 'en_US';
  // intl knows only en_US until the app loads its date data (Comic's delegate does, as Flutter's global ones do);
  // before then asking after any other locale throws, so the dates read in English.
  try {
    return DateFormat.localeExists(locale) ? locale : 'en_US';
  } on Exception {
    return 'en_US';
  }
}

/// A seven-column month that grows to fit the scaled day numbers. Arrows move by day
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
    this.autofocus = false,
  }) : assert(firstWeekday >= 1 && firstWeekday <= 7),
       assert(monthNames == null || monthNames.length == 12),
       assert(dayNames == null || dayNames.length == 7);

  /// Chosen date, ignoring time.
  final DateTime? value;

  /// Whether the keys start on the chosen day (else today, or the nearest day allowed) when the calendar first shows,
  /// as they do in [showComicDatePicker]'s.
  final bool autofocus;

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
  /// takes it, so two calendars on one screen share their grid. Where a month has less than seven of them across
  /// (a phone's dialog), its columns narrow, as Material's calendar's, down to 40 or the width that keeps each number
  /// 4 clear of its outline, and keep this height; narrower still, the month scrolls sideways.
  static const double dayWidth = 48;

  /// Width of the seven-column month at its default cell size.
  static const double maxWidth = 7 * dayWidth;

  @override
  State<ComicDatePicker> createState() => _ComicDatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
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
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      )
      ..add(
        IntProperty(
          'firstWeekday',
          firstWeekday,
          defaultValue: DateTime.monday,
        ),
      )
      ..add(
        IterableProperty<String>('monthNames', monthNames, defaultValue: null),
      )
      ..add(IterableProperty<String>('dayNames', dayNames, defaultValue: null))
      ..add(StringProperty('previousLabel', previousLabel, defaultValue: null))
      ..add(StringProperty('nextLabel', nextLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
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
    final (minimumDayWidth, narrowestDay) = _dayWidths(context, widget.style);
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
    // The month's rules, laid once where two days meet (see [_DayRules]).
    final rest = comicStyleOf([widget.style, t.datePickerTheme], const {});
    final rule = comicRim(t, rest, t.colors.divider, 1);
    Widget cell(int day) {
      final date = DateTime(_month.year, _month.month, day),
          selected = widget.value != null && date == _day(widget.value!);
      final live = widget.onChanged != null && _can(date);
      _nodes[day - 1].skipTraversal = date != _cursor;
      return ComicPressable(
        label: DateFormat.yMMMMd(locale).format(date),
        selected: selected,
        focusNode: _nodes[day - 1],
        autofocus: widget.autofocus && date == _cursor,
        keys: (_, event) => _keys(event),
        onPressed: live
            ? () {
                setState(() => _cursor = date);
                widget.onChanged!(date);
              }
            : null,
        sink: false,
        overlay: comicStyleOf([
          widget.style,
          t.datePickerTheme,
        ], const {}).overlay,
        outline: comicStyleOf([
          widget.style,
          t.datePickerTheme,
        ], const {}).shapes(t.shapes.small),
        builder: (context, states) {
          final look = comicStyleOf([widget.style, t.datePickerTheme], states);
          // The chosen day's lamp keeps the ink contour every lit fill has: the night line's cream on the yellow
          // stood 1.2:1, the day's edge gone. At night the night line is laid over the ink's outer edge, which the
          // page swallowed (comicLampNightLine).
          final rim = comicRim(
            t,
            look,
            selected ? t.colors.onCaption : t.colors.divider,
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
                comicStyleOf([widget.style, t.datePickerTheme], s),
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
                  // A resting day leaves its edges to the month's rules; the chosen day and one under the keys, the
                  // pointer or a press draw their own, which lifts with the day.
                  side:
                      selected ||
                          rim != rule ||
                          states.any(
                            const {
                              WidgetState.focused,
                              WidgetState.hovered,
                              WidgetState.pressed,
                            }.contains,
                          )
                      ? rim
                      : BorderSide.none,
                ),
              ),
              child: ComicStateDecoration(
                position: DecorationPosition.foreground,
                decoration: ShapeDecoration(
                  shape: (shape ?? const RoundedRectangleBorder()).copyWith(
                    side: selected
                        ? comicLampNightLine(t.colors)
                        : BorderSide.none,
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
                            EdgeInsets.symmetric(
                              vertical: reserve,
                              horizontal: reserve / 2,
                            ),
                          ),
                  // The number alone sets the cell, its capitals on the middle; today's dot is laid over the cell
                  // under it, so today stands as tall as the days beside it (ui_core's DesignRowCheck: 4 px taller).
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.center,
                    children: [
                      CapLabel(
                        display: false,
                        child: Text(
                          RawWidgetsLocalizations.of(context)
                              .formatDecimal(day),
                          style:
                              _dayFigure(
                                t,
                                look.textStyle,
                                selected: selected,
                              ).copyWith(
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
          RawWidgetsLocalizations.of(context).previousMonthTooltip,
      // The arrows stand on the header's keylines, their targets growing inward.
      targetAlignment: AlignmentDirectional.centerStart,
      onPressed: canBack
          ? () => _walk(_bound(_shiftMonth(-1)), focus: false)
          : null,
    );
    final next = ComicIconButton(
      rtl ? ComicGlyphs.chevronLeft : ComicGlyphs.chevronRight,
      label:
          widget.nextLabel ??
          RawWidgetsLocalizations.of(context).nextMonthTooltip,
      targetAlignment: AlignmentDirectional.centerEnd,
      onPressed: canNext
          ? () => _walk(_bound(_shiftMonth(1)), focus: false)
          : null,
    );
    // The month's name grows at most twice too, as Material's calendar header: larger, "November" outgrew the space
    // between the arrows and broke mid-word.
    final month = Semantics(
      header: true,
      liveRegion: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: comicCalendarScaleMost,
        child: Text(heading, style: t.type.title, textAlign: TextAlign.center),
      ),
    );
    return Align(
      alignment: AlignmentDirectional.topStart,
      widthFactor: 1,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 7 * minimumDayWidth),
        child: _grid(
          previous,
          next,
          month,
          count,
          lead,
          cell,
          minimumDayWidth,
          math.max(narrowestDay, _narrowestDay),
          rule,
          rest.shape ?? t.shapes.small,
        ),
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
    double narrowestDay,
    BorderSide rule,
    OutlinedBorder ruleShape,
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
                  spacing: ComicSpace.close,
                  runSpacing: ComicSpace.close,
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
          const SizedBox(height: ComicSpace.close),
          // The weekdays and days grow at most twice, as Material's calendar on a phone: larger, seven initials touch
          // and seven days' numbers outgrew a phone, the grid scrolling sideways. Where seven fit at their narrowest
          // (a phone's dialog), they share the width, as Material's calendar's days do, rather than cut Sunday off;
          // where they don't, each keeps a touch's width and the month scrolls.
          MediaQuery.withClampedTextScaling(
            maxScaleFactor: comicCalendarScaleMost,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: box.hasBoundedWidth && box.maxWidth >= 7 * narrowestDay
                    ? box.maxWidth
                    : math.max(
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
                                padding: const EdgeInsets.symmetric(
                                  vertical: ComicSpace.close,
                                ),
                                child: Text(
                                  (widget.dayNames ??
                                      words.weekdaysShort)[(widget
                                              .firstWeekday -
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
                    // Two days side by side share one rule, as heavy as the month's outer rule: each day's own outline
                    // stood two rules deep against its neighbour's.
                    CustomPaint(
                      painter: _DayRules(
                        lead: lead,
                        count: count,
                        side: rule,
                        shape: ruleShape,
                        direction: Directionality.of(context),
                        devicePixelRatio:
                            MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (
                            var row = 0;
                            row < (count + lead + 6) ~/ 7;
                            row++
                          )
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
    // The hour, minute and half of the day in the app's language: ui_core's words.
    final shared = RawWidgetsLocalizations.of(context),
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
    final names = [
      hourLabel ?? shared.timePickerHourLabel,
      minuteLabel ?? shared.timePickerMinuteLabel,
      if (!h24) periodLabel ?? shared.timeFieldDayPeriodLabel,
    ];
    final selects = <Widget>[
      ComicSelect<int>(
        style: layers,
        labelText: names[0],
        value: h24 ? time.hour : time.hour % 12,
        options: [
          for (var hour = 0; hour < (h24 ? 24 : 12); hour++)
            // In the app's digits (Arabic's ٩), on this picker's own clock: formatHour would follow the language's
            // clock, and Persian's is 24 hours where this picker may show 12.
            ComicSelectOption(
              hour,
              shared.formatDecimal(
                h24
                    ? hour
                    : hour == 0
                    ? 12
                    : hour,
              ),
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
        labelText: names[1],
        value: time.minute,
        options: [
          for (final minute in minutes)
            ComicSelectOption(
              minute,
              shared.formatMinute(RawTimeOfDay(hour: 0, minute: minute)),
            ),
        ],
        onChanged: onChanged == null
            ? null
            : (minute) => onChanged!(ComicTime(time.hour, minute)),
      ),
      if (!h24)
        ComicSelect<int>(
          style: layers,
          labelText: names[2],
          value: time.hour ~/ 12,
          options: [
            ComicSelectOption(0, shared.anteMeridiemAbbreviation),
            ComicSelectOption(1, shared.postMeridiemAbbreviation),
          ],
          onChanged: onChanged == null
              ? null
              : (period) => onChanged!(
                  ComicTime(time.hour % 12 + period * 12, time.minute),
                ),
        ),
    ];
    // Hour, minute and AM or PM on one row of equal selects, each label on one line, up to 160 a select; under
    // 96 a select (a phone's narrow column), or under a label's own width, they stack. The least grows with the
    // text: at 200% on a phone the labels would break mid-word ("Minut e") and the selects stand at different
    // heights under them. The words grow at most twice, as Material's time picker's.
    const gap = 12.0, most = 160.0;
    final title = ComicTheme.of(context).type.title;
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: comicTimeScaleMost,
      child: LayoutBuilder(
        builder: (context, box) {
          final scaler = MediaQuery.textScalerOf(context);
          var least = math.min(most, scaler.scale(96));
          for (final name in names) {
            final words = TextPainter(
              text: TextSpan(text: name, style: title),
              textDirection: Directionality.of(context),
              textScaler: scaler,
              maxLines: 1,
            )..layout();
            least = math.max(least, words.width);
            words.dispose();
          }
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
          // Hour then minute, left to right in every language, as Material's time picker keeps them (a time reads
          // ٩:٠٥ in Arabic too); AM or PM keeps its place on the reading side.
          Widget select(int i) => SizedBox(width: each, child: selects[i]);
          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                textDirection: TextDirection.ltr,
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  select(0),
                  const SizedBox(width: gap),
                  select(1),
                ],
              ),
              if (n > 2) ...[const SizedBox(width: gap), select(2)],
            ],
          );
        },
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ComicTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<ComicTime>>.has('onChanged', onChanged),
      )
      ..add(IntProperty('minuteStep', minuteStep, defaultValue: 1))
      ..add(
        DiagnosticsProperty<bool>(
          'use24hFormat',
          use24hFormat,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('hourLabel', hourLabel, defaultValue: null))
      ..add(StringProperty('minuteLabel', minuteLabel, defaultValue: null))
      ..add(StringProperty('periodLabel', periodLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<ComicStyle>('style', style, defaultValue: null),
      );
  }
}

/// The narrowest a day's column gets before the month scrolls sideways: Material's calendar's day.
const double _narrowestDay = 40;

/// The least room between a day's number and its outline, as every Comic face keeps round its content.
const double _dayClearance = 4;

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
  String? confirmText,
  String? cancelText,
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
      builder: (context, setState) => Center(
        // As wide as its content, the calendar's seven days, as Material's date picker dialog is: at the panel's
        // widest the month left a strip of empty paper at its end.
        child: IntrinsicWidth(
          child: ComicDialog(
            title: title ?? ComicLocalizations.of(context).chooseDate,
            content: [
              _NaturalWidth(
                width: 7 * _dayWidths(context, null).$1,
                child: ComicDatePicker(
                  value: picked,
                  firstDate: firstDate,
                  lastDate: lastDate,
                  currentDate: currentDate,
                  onChanged: (day) => setState(() => picked = day),
                  // The keys start on the chosen day.
                  autofocus: true,
                ),
              ),
            ],
            actions: [
              ComicButton(
                cancelText ??
                    RawWidgetsLocalizations.of(context).cancelButtonLabel,
                onPressed: () => Navigator.pop(context),
              ),
              ComicButton.filled(
                confirmText ?? ComicLocalizations.of(context).choose,
                size: ComicButtonSize.small,
                onPressed: picked == null
                    ? null
                    : () => Navigator.pop(context, picked),
              ),
            ],
          ),
        ),
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
  String? confirmText,
  String? cancelText,
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
            cancelText ?? RawWidgetsLocalizations.of(context).cancelButtonLabel,
            onPressed: () => Navigator.pop(context),
          ),
          ComicButton.filled(
            confirmText ?? ComicLocalizations.of(context).choose,
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

/// A day's number: the body's words, the chosen day's heavy as a calendar's and a range's chosen ends are, under the
/// app's [own] style for the day.
TextStyle _dayFigure(
  ComicThemeData t,
  TextStyle? own, {
  required bool selected,
}) => t.type.body
    .copyWith(fontWeight: selected ? FontWeight.w800 : null)
    .merge(own);

/// A day's width in a calendar under [context] (each of seven at least, where they fit) and the narrowest a day may
/// grow, for the calendar and for the dialog that holds one.
(double, double) _dayWidths(BuildContext context, ComicStyle? style) {
  // Reserve the measured day label and its actual outline insets. An
  // arbitrary text allowance made even an ordinary phone scroll sideways.
  // The numbers grow at most twice (see [_grid]), so they are measured so.
  // A day keeps a touch's width (48) where seven fit; where they don't (a
  // phone's dialog) they narrow, but never so far that a number comes within
  // 4 of its day's outline, the corner's curve included.
  final t = ComicTheme.of(context);
  var minimumDayWidth = ComicDatePicker.dayWidth, narrowestDay = 0.0;
  final direction = Directionality.of(context);
  for (final states in const <Set<WidgetState>>[
    {},
    {WidgetState.selected},
    {WidgetState.disabled},
  ]) {
    final look = comicStyleOf([style, t.datePickerTheme], states);
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
    final padding = look.padding(direction)?.horizontal ?? 0;
    final corner = comicCornerInset(shape, direction);
    final painter = TextPainter(
      textDirection: direction,
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: comicCalendarScaleMost),
    );
    for (var day = 1; day <= 31; day++) {
      painter.text = TextSpan(
        text: '$day',
        style: _dayFigure(
          t,
          look.textStyle,
          selected: states.contains(WidgetState.selected),
        ),
      );
      painter.layout();
      minimumDayWidth = math.max(
        minimumDayWidth,
        (painter.width + inset / 2 + padding).ceilToDouble(),
      );
      narrowestDay = math.max(
        narrowestDay,
        (painter.width + inset + padding + 2 * (_dayClearance + corner))
            .ceilToDouble(),
      );
    }
    painter.dispose();
  }
  return (minimumDayWidth, narrowestDay);
}

/// The month's rules: every day's outline, laid in one stroke so that where two days meet the rule is laid once, on
/// whole device pixels and inside the weeks' box.
class _DayRules extends CustomPainter {
  _DayRules({
    required this.lead,
    required this.count,
    required this.side,
    required this.shape,
    required this.direction,
    required this.devicePixelRatio,
  });

  final int lead, count;
  final BorderSide side;
  final OutlinedBorder shape;
  final TextDirection direction;
  final double devicePixelRatio;

  @override
  void paint(Canvas canvas, Size size) {
    if (side.style == BorderStyle.none || side.width <= 0 || count == 0) return;
    final rows = (count + lead + 6) ~/ 7;
    final half = side.width / 2;
    // A boundary on whole device pixels, the stroke laid from it toward the day after (the last within the box).
    double at(double v, double most) =>
        ((v * devicePixelRatio).roundToDouble() / devicePixelRatio + half)
            .clamp(half, most - half);
    final width = size.width / 7, height = size.height / rows;
    final rtl = direction == TextDirection.rtl;
    final outline = shape.copyWith(side: BorderSide.none);
    final path = Path();
    for (var day = 1; day <= count; day++) {
      final i = day - 1 + lead, row = i ~/ 7, column = i % 7;
      final start = rtl ? 7 - column - 1 : column;
      path.addPath(
        outline.getOuterPath(
          Rect.fromLTRB(
            at(start * width, size.width),
            at(row * height, size.height),
            at((start + 1) * width, size.width),
            at((row + 1) * height, size.height),
          ),
          textDirection: direction,
        ),
        Offset.zero,
      );
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = side.width
        ..color = side.color,
    );
  }

  @override
  bool shouldRepaint(_DayRules oldDelegate) =>
      oldDelegate.lead != lead ||
      oldDelegate.count != count ||
      oldDelegate.side != side ||
      oldDelegate.shape != shape ||
      oldDelegate.direction != direction ||
      oldDelegate.devicePixelRatio != devicePixelRatio;
}

/// Reports [width] as its child's natural width, without asking the child (a calendar lays out its days by the room it
/// is given), so an [IntrinsicWidth] above sizes a dialog to its calendar. Layout and paint are the child's own.
class _NaturalWidth extends SingleChildRenderObjectWidget {
  const _NaturalWidth({required this.width, required super.child});

  final double width;

  @override
  _RenderNaturalWidth createRenderObject(BuildContext context) =>
      _RenderNaturalWidth(width);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderNaturalWidth renderObject,
  ) => renderObject.width = width;
}

class _RenderNaturalWidth extends RenderProxyBox {
  _RenderNaturalWidth(this._width);

  double _width;
  set width(double value) {
    if (value == _width) return;
    _width = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicWidth(double height) => _width;

  @override
  double computeMaxIntrinsicWidth(double height) => _width;
}
