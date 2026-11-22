/// Keycap's dates and times: [KeycapCalendar] (a month printed on the
/// case, the chosen day a small accent key), [KeycapDatePicker] and
/// [KeycapDateRangePicker] (a key that lays a month over the keyboard) and
/// [KeycapTimePicker] (a key that lays hours and minutes over it, turning
/// in a well).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'cap.dart';
import 'choices.dart';
import 'internal/field_width.dart';
import 'internal/small_key.dart';
import 'select.dart';
import 'sliders.dart';
import 'text_field.dart';
import 'theme.dart';

// The ui_core types these parts' APIs take, through the look's barrel.
export 'package:ui_core/ui_core.dart'
    show RawCalendarController, RawCalendarMode, RawDateRange;
export 'package:ui_core/ui_core.dart' show RawTimeOfDay;

/// A date as a picker key shows it: the short month and day with the year,
/// in the locale's order.
String _dateLabel(RawWidgetsLocalizations words, DateTime date) {
  final monthDay = words.formatShortMonthDay(date);
  final full = words.formatFullDate(date);
  final separatedYear = '${words.listSeparator}${words.formatYear(date)}';
  if (words.dateFieldPattern.startsWith('M') || full.endsWith(separatedYear)) {
    return '$monthDay$separatedYear';
  }
  final monthYear = words.formatMonthYear(date);
  for (final month in [words.formatMonth(date), words.formatShortMonth(date)]) {
    if (month.isNotEmpty && monthYear.contains(month)) {
      return monthYear.replaceFirst(month, monthDay);
    }
  }
  return full;
}

/// A day's cell height at 1x text, and its least width: a finger's 44.
const double _dayHeight = KeycapCalendar.dayExtent;

double _dayHeightOf(BuildContext context) {
  final theme = KeycapTheme.of(context);
  final painter = TextPainter(
    text: TextSpan(text: '28', style: theme.textTheme.body),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final height = math.max(_dayHeight, painter.height + 2 * KeycapSpacing.tight);
  painter.dispose();
  return height;
}

/// A month's header: its name, and small keys to the month before and
/// after.
Widget _header(BuildContext context, RawCalendarHeaderDetails header) {
  final theme = KeycapTheme.of(context);
  final rtl = Directionality.of(context) == TextDirection.rtl;
  return Padding(
    padding: const EdgeInsets.only(bottom: KeycapSpacing.small),
    child: Row(
      children: [
        KeycapSmallKey(
          icon: rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
          semanticLabel: RawWidgetsLocalizations.of(context)
              .previousMonthTooltip,
          onPressed: header.previous,
          side: 36,
        ),
        Expanded(
          child: Text(
            header.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.label.copyWith(color: theme.colors.ink),
          ),
        ),
        KeycapSmallKey(
          icon: rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
          semanticLabel: RawWidgetsLocalizations.of(context).nextMonthTooltip,
          onPressed: header.next,
          side: 36,
        ),
      ],
    ),
  );
}

/// A weekday's heading, in the legend's small capitals.
Widget _weekday(BuildContext context, int weekday, String label) {
  final theme = KeycapTheme.of(context);
  final style = theme.textTheme.legend.copyWith(color: theme.colors.inkMuted);
  return SizedBox(
    height: 28,
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, softWrap: false, style: style),
      ),
    ),
  );
}

/// A day: printed on the case; the chosen day (a range's ends) a small
/// accent key, the days between them a well the keys stand in; today
/// underlined in the accent's ink. A pointer over a day changes nothing; a
/// press dims its figure.
Widget _day(
  BuildContext context,
  RawCalendarDayDetails day,
  Set<WidgetState> states, [
  KeycapStyle? style,
]) {
  final theme = KeycapTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.calendarStyle], states);
  final pressed = states.contains(WidgetState.pressed);
  final focused = states.contains(WidgetState.focused);
  final previewEnd = day.inPreview && day.isPreviewEnd;
  final end = day.selected || day.isRangeStart || day.isRangeEnd || previewEnd;
  final band = day.inMonth && (day.inRange || day.inPreview);
  final height = _dayHeightOf(context);
  final side = height - 2;
  const radius = KeycapMetrics.smallKeyRadius;
  final ink = !day.enabled
      ? c.inkDisabled
      : !day.inMonth
      ? c.inkDisabled
      : pressed
      ? c.inkMuted
      : layered.foreground ?? c.ink;
  // At a large text size the figures shrink to keep 6 px inside their cell:
  // where a month is narrow a day's touch target overhangs its seventh, and
  // the figures still keep apart, so a row's days never run together.
  Widget figure(Color color) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      child: DesignCapCenter(
        capHeightFactor: theme.capHeightFactor,
        child: Text(
          // The reader's digits: Arabic-Indic in Arabic, as the month is named.
          RawWidgetsLocalizations.of(context).formatDecimal(day.date.day),
          maxLines: 1,
          softWrap: false,
          style: theme.textTheme.body.copyWith(
            color: color,
            fontWeight: day.isToday || end ? FontWeight.w600 : FontWeight.w400,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    ),
  );
  final Widget mark;
  if (end && day.enabled) {
    final face = keycapKeyFace(
      theme,
      previewEnd && !day.selected ? KeycapKind.alpha : KeycapKind.accent,
      states,
      radius: radius,
    );
    mark = SizedBox(
      width: side,
      height: side,
      child: AnimatedKeycapCap(
        face: face,
        walls: KeycapMetrics.walls(side),
        child: Center(child: figure(face.legend)),
      ),
    );
  } else {
    mark = SizedBox(
      width: side,
      height: side,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(
            color: focused ? c.focus : c.focus.withValues(alpha: 0),
            width: KeycapMetrics.focusWidth,
          ),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            figure(ink),
            if (day.isToday && day.inMonth)
              Positioned(
                bottom: 5,
                child: SizedBox(
                  width: 14,
                  height: 2,
                  child: ColoredBox(color: c.accentInk),
                ),
              ),
          ],
        ),
      ),
    );
  }
  return MouseRegion(
    cursor: day.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (band)
            Positioned.fill(
              top: 1,
              bottom: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: day.inRange ? c.well : c.well.withValues(alpha: 0.6),
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: day.isRangeStart
                        ? const Radius.circular(radius)
                        : Radius.zero,
                    end: day.isRangeEnd || previewEnd
                        ? const Radius.circular(radius)
                        : Radius.zero,
                  ).resolve(Directionality.of(context)),
                ),
              ),
            ),
          mark,
        ],
      ),
    ),
  );
}

/// A month of days printed on the case, with keys to the months either
/// side: the chosen day a small accent key, a range's days a well its two
/// ends stand in, today underlined. The arrows move by day and week, Page
/// Up and Page Down by month. Built on ui_core's `RawCalendarDatePicker`.
///
/// ```dart
/// KeycapCalendar(controller: RawCalendarController(firstDate: DateTime(2026), lastDate: DateTime(2027)))
/// ```
class KeycapCalendar extends StatelessWidget {
  /// A calendar over [controller].
  const KeycapCalendar({
    super.key,
    required this.controller,
    this.onChanged,
    this.months = 1,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// What is chosen, and which month shows.
  final RawCalendarController controller;

  /// Called with each day chosen.
  final ValueChanged<DateTime>? onChanged;

  /// How many months show side by side.
  final int months;

  /// The grid's focus node.
  final FocusNode? focusNode;

  /// Whether it takes focus when it first appears.
  final bool autofocus;

  /// Overrides, over [KeycapThemeData.calendarStyle].
  final KeycapStyle? style;

  /// A day's least width and height: a finger's reach. A month is seven
  /// of them wide.
  static const double dayExtent = 44;

  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 2,
    child: Builder(
      builder: (context) => RawCalendarDatePicker(
        controller: controller,
        onChanged: onChanged,
        months: months,
        focusNode: focusNode,
        autofocus: autofocus,
        minDayWidth: _dayHeight,
        headerBuilder: _header,
        weekdayBuilder: _weekday,
        dayBuilder: (context, day, states) => _day(context, day, states, style),
        monthsBuilder: (context, grids) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, grid) in grids.indexed) ...[
              if (i > 0) const SizedBox(width: KeycapSpacing.large),
              Expanded(child: grid),
            ],
          ],
        ),
      ),
    ),
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('months', months, defaultValue: 1));
  }
}

/// The key every date and time picker shows its value on: an alpha key, as
/// a select's is, that lays its [panel] over the keyboard and stays part
/// way down while it is open.
class _PickerKey extends StatelessWidget {
  const _PickerKey({
    required this.text,
    required this.empty,
    required this.enabled,
    required this.error,
    required this.icon,
    required this.semanticLabel,
    required this.semanticValue,
    required this.panel,
    required this.style,
  });

  final String text;
  final bool empty;
  final bool enabled;
  final bool error;
  final IconData icon;
  final String? semanticLabel;
  final String? semanticValue;
  final Widget Function(BuildContext context, VoidCallback close) panel;
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final c = theme.colors;
    final h = theme.controlHeight;
    Widget key(DesignOverlayAnchor? anchor) {
      final open = anchor?.isOpen ?? false;
      return RawButton(
        onPressed: anchor?.toggle,
        expanded: anchor?.isOpen,
        semanticLabel: semanticLabel,
        semanticValue: semanticValue,
        excludeSemantics: true,
        builder: (context, states, _) {
          final layered = DesignStyleOf(
            [style, theme.selectStyle],
            {...states, if (error) WidgetState.error},
          );
          var face = keycapKeyFace(theme, KeycapKind.alpha, states);
          if (open && !states.contains(WidgetState.pressed)) {
            face = face.copyWith(travel: keycapLatchTravel);
          }
          if (open) face = face.copyWith(focus: c.focus.withValues(alpha: 0));
          if (error && enabled) {
            face = face.copyWith(
              edge: c.dangerInk,
              focus: states.contains(WidgetState.focused) && !open
                  ? c.dangerInk
                  : null,
            );
          }
          face = layered.on(face);
          final words = !enabled
              ? c.inkDisabled
              : empty
              ? c.inkMuted
              : face.legend;
          return TapTargetPadding(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: h),
              child: AnimatedKeycapCap(
                face: face,
                walls: KeycapMetrics.walls(h),
                child: Padding(
                  padding:
                      layered.padding(Directionality.of(context)) ??
                      EdgeInsetsDirectional.only(
                        start:
                            KeycapSpacing.medium +
                            theme.density.paddingDelta / 2,
                        end: KeycapSpacing.medium,
                        top: KeycapSpacing.tight,
                        bottom: KeycapSpacing.tight,
                      ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: Text(
                            text,
                            style: theme.textTheme.body
                                .merge(layered.textStyle)
                                .copyWith(color: words),
                          ),
                        ),
                      ),
                      const SizedBox(width: KeycapSpacing.small),
                      Icon(
                        icon,
                        size: 18,
                        color: enabled ? c.inkMuted : c.inkDisabled,
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

    final Widget box = !enabled
        ? key(null)
        : RawPopover(
            semanticLabel: semanticLabel,
            // The calendar wants its whole month (two, side by side, for a
            // range on a desk) before it picks a side: low on a phone it
            // opens above the field rather than below in a sliver.
            placement: const RawPopoverPlacement(
              gap: KeycapSpacing.tight + 2,
              margin: KeycapSpacing.small,
              preferredExtent: double.infinity,
              matchAnchorWidth: false,
              maxWidth: 340,
            ),
            dampingRatio: KeycapMotion.panel.dampingRatio,
            stiffness: KeycapMotion.panel.stiffness,
            anchorBuilder: (context, anchor) => key(anchor),
            overlayBuilder: (context, info) => KeycapMenuReveal(
              animation: info.animation,
              below: info.side != RawPopoverSide.above,
              child: KeycapMenuPanel(
                maxHeight: info.maxSize.height,
                child: Padding(
                  padding: const EdgeInsets.all(KeycapSpacing.small),
                  child: panel(context, info.close),
                ),
              ),
            ),
          );
    return keycapFieldWidth(context, box, KeycapSelect.maxWideWidth);
  }
}

class _CalendarPanel extends StatefulWidget {
  const _CalendarPanel({required this.make, required this.onChanged});

  final RawCalendarController Function() make;
  final void Function(RawCalendarController controller) onChanged;

  @override
  State<_CalendarPanel> createState() => _CalendarPanelState();
}

class _CalendarPanelState extends State<_CalendarPanel> {
  late final RawCalendarController _controller = widget.make();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 7 * KeycapCalendar.dayExtent,
    child: KeycapCalendar(
      controller: _controller,
      autofocus: true,
      onChanged: (_) => widget.onChanged(_controller),
    ),
  );
}

/// A day picked from a month: a key that shows the day and, pressed, lays
/// a [KeycapCalendar] over the keyboard; choosing a day closes it.
///
/// ```dart
/// KeycapDatePicker(label: 'Remind me on', value: day, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (d) => setState(() => day = d))
/// ```
class KeycapDatePicker extends StatelessWidget {
  /// A date picker.
  const KeycapDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint = 'Choose a day',
    this.helper,
    this.error,
    this.semanticLabel,
    this.selectable,
    this.currentDate,
    this.style,
  });

  /// The day chosen.
  final DateTime? value;

  /// Called with the day chosen; null turns it off.
  final ValueChanged<DateTime>? onChanged;

  /// The first day that can be chosen.
  final DateTime firstDate;

  /// The last.
  final DateTime lastDate;

  /// The words over the key.
  final String? label;

  /// What the key says before a day is chosen.
  final String hint;

  /// Help under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Its name, for a screen reader, when there is no [label].
  final String? semanticLabel;

  /// Which days can be chosen; every day when null.
  final bool Function(DateTime day)? selectable;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// Overrides for the key, over [KeycapThemeData.selectStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final chosen = value;
    final words = RawWidgetsLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: KeycapFieldLabel(label!, enabled: enabled)),
        _PickerKey(
          text: chosen == null ? hint : _dateLabel(words, chosen),
          empty: chosen == null,
          enabled: enabled,
          error: error != null,
          icon: LucideIcons.calendar,
          semanticLabel: semanticLabel ?? label,
          semanticValue: chosen == null ? null : words.formatFullDate(chosen),
          style: style,
          panel: (context, close) => _CalendarPanel(
            make: () => RawCalendarController(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedDate: chosen,
              selectable: selectable,
              currentDate: currentDate,
            ),
            onChanged: (controller) {
              final day = controller.selectedDate;
              if (day == null) return;
              close();
              onChanged?.call(day);
            },
          ),
        ),
        KeycapFieldMessage(helper: helper, error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null));
  }
}

/// A stretch of days: a key that shows them and, pressed, lays a month over
/// the keyboard; the first day chosen starts the range, the second ends it
/// and closes the month.
///
/// ```dart
/// KeycapDateRangePicker(label: 'Show notes from', value: range, firstDate: DateTime(2025), lastDate: DateTime(2027), onChanged: (r) => setState(() => range = r))
/// ```
class KeycapDateRangePicker extends StatelessWidget {
  /// A date range picker.
  const KeycapDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint = 'Choose the days',
    this.helper,
    this.error,
    this.semanticLabel,
    this.currentDate,
    this.style,
  });

  /// The days chosen.
  final RawDateRange? value;

  /// Called with a whole range; null turns it off.
  final ValueChanged<RawDateRange>? onChanged;

  /// The first day that can be chosen.
  final DateTime firstDate;

  /// The last.
  final DateTime lastDate;

  /// The words over the key.
  final String? label;

  /// What the key says before days are chosen.
  final String hint;

  /// Help under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Its name, for a screen reader, when there is no [label].
  final String? semanticLabel;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// Overrides for the key, over [KeycapThemeData.selectStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final range = value;
    final end = range?.end;
    final words = RawWidgetsLocalizations.of(context);
    String rangeText(RawDateRange dates) {
      final last = dates.end;
      final start = last == null || dates.start.year == last.year
          ? words.formatShortMonthDay(dates.start)
          : _dateLabel(words, dates.start);
      return last == null ? start : '$start – ${_dateLabel(words, last)}';
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: KeycapFieldLabel(label!, enabled: enabled)),
        _PickerKey(
          text: range == null ? hint : rangeText(range),
          empty: range == null,
          enabled: enabled,
          error: error != null,
          icon: LucideIcons.calendarRange,
          semanticLabel: semanticLabel ?? label,
          semanticValue: range == null
              ? null
              : end == null
              ? words.formatFullDate(range.start)
              : words.chartRangeLabel(
                  words.formatFullDate(range.start),
                  words.formatFullDate(end),
                ),
          style: style,
          panel: (context, close) => _CalendarPanel(
            make: () => RawCalendarController(
              firstDate: firstDate,
              lastDate: lastDate,
              mode: RawCalendarMode.range,
              selectedRange: range,
              currentDate: currentDate,
            ),
            onChanged: (controller) {
              final chosen = controller.selectedRange;
              if (chosen == null || !chosen.isComplete) return;
              close();
              onChanged?.call(chosen);
            },
          ),
        ),
        KeycapFieldMessage(helper: helper, error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

/// A time of day: a key that shows it and, pressed, lays its hours and
/// minutes over the keyboard, turning in a well ([KeycapWheelPicker]), with
/// a key that sets it. In the locale's 12 or 24 hour clock.
///
/// ```dart
/// KeycapTimePicker(label: 'Remind me at', value: const RawTimeOfDay(hour: 9, minute: 0), onChanged: (t) => setState(() => at = t))
/// ```
class KeycapTimePicker extends StatelessWidget {
  /// A time picker.
  const KeycapTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.hint = 'Choose a time',
    this.helper,
    this.error,
    this.semanticLabel,
    this.minuteStep = 5,
    this.style,
  }) : assert(60 % minuteStep == 0);

  /// The time chosen.
  final RawTimeOfDay? value;

  /// Called with the time set; null turns it off.
  final ValueChanged<RawTimeOfDay>? onChanged;

  /// The words over the key.
  final String? label;

  /// What the key says before a time is chosen.
  final String hint;

  /// Help under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Its name, for a screen reader, when there is no [label].
  final String? semanticLabel;

  /// The minutes' step.
  final int minuteStep;

  /// Overrides for the key, over [KeycapThemeData.selectStyle].
  final KeycapStyle? style;

  @override
  Widget build(BuildContext context) {
    final enabled = onChanged != null;
    final t = value;
    final h24 = MediaQuery.alwaysUse24HourFormatOf(context);
    String two(int n) => n.toString().padLeft(2, '0');
    final local = RawWidgetsLocalizations.of(context);
    String label12(RawTimeOfDay v) {
      final h = v.hour % 12 == 0 ? 12 : v.hour % 12;
      final half = v.hour < 12
          ? local.anteMeridiemAbbreviation
          : local.postMeridiemAbbreviation;
      return '$h:${two(v.minute)} $half';
    }

    String words(RawTimeOfDay v) =>
        h24 ? '${two(v.hour)}:${two(v.minute)}' : label12(v);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: KeycapFieldLabel(label!, enabled: enabled)),
        _PickerKey(
          text: t == null ? hint : words(t),
          empty: t == null,
          enabled: enabled,
          error: error != null,
          icon: LucideIcons.clock,
          semanticLabel: semanticLabel ?? label,
          semanticValue: t == null ? null : words(t),
          style: style,
          panel: (context, close) => _TimePanel(
            initial: t ?? const RawTimeOfDay(hour: 9, minute: 0),
            minuteStep: minuteStep,
            h24: h24,
            onSet: (v) {
              close();
              onChanged?.call(v);
            },
          ),
        ),
        KeycapFieldMessage(helper: helper, error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('label', label, defaultValue: null));
  }
}

class _TimePanel extends StatefulWidget {
  const _TimePanel({
    required this.initial,
    required this.minuteStep,
    required this.h24,
    required this.onSet,
  });

  final RawTimeOfDay initial;
  final int minuteStep;
  final bool h24;
  final ValueChanged<RawTimeOfDay> onSet;

  @override
  State<_TimePanel> createState() => _TimePanelState();
}

class _TimePanelState extends State<_TimePanel> {
  late int _hour = widget.initial.hour;
  late int _minute =
      (widget.initial.minute ~/ widget.minuteStep) % (60 ~/ widget.minuteStep);

  @override
  Widget build(BuildContext context) {
    String two(int n) => n.toString().padLeft(2, '0');
    final words = RawWidgetsLocalizations.of(context);
    final step = widget.minuteStep;
    final h24 = widget.h24;
    final columns = <RawPickerColumn>[
      RawPickerColumn(
        itemCount: h24 ? 24 : 12,
        itemLabel: (i) => h24 ? two(i) : '${i == 0 ? 12 : i}',
        semanticLabel: words.timePickerHourLabel,
        looping: true,
      ),
      RawPickerColumn(
        itemCount: 60 ~/ step,
        itemLabel: (i) => two(i * step),
        semanticLabel: words.timePickerMinuteLabel,
        looping: true,
      ),
    ];
    final selection = [if (h24) _hour else _hour % 12, _minute];
    final done = KeycapButton.accent(
      onPressed: () =>
          widget.onSet(RawTimeOfDay(hour: _hour, minute: _minute * step)),
      child: Text(words.doneButtonLabel),
    );
    // Hours and minutes turn on wheels; the half of the day is a pair of
    // keys, one held down, as a keyboard's lock keys are.
    return SizedBox(
      width: h24 ? 200 : 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KeycapWheelPicker(
            columns: (_) => columns,
            selection: selection,
            separator: ':',
            onChanged: (s) => setState(() {
              _minute = s[1];
              _hour = h24 ? s[0] : s[0] + (_hour < 12 ? 0 : 12);
            }),
          ),
          const SizedBox(height: KeycapSpacing.small),
          if (h24)
            done
          else
            Row(
              children: [
                KeycapSegmentedButton<bool>(
                  semanticLabel: words.timeFieldDayPeriodLabel,
                  expand: false,
                  segments: [
                    KeycapSegment(
                      value: false,
                      label: words.anteMeridiemAbbreviation,
                    ),
                    KeycapSegment(
                      value: true,
                      label: words.postMeridiemAbbreviation,
                    ),
                  ],
                  selected: {_hour >= 12},
                  onSelectionChanged: (s) =>
                      setState(() => _hour = _hour % 12 + (s.first ? 12 : 0)),
                ),
                const SizedBox(width: KeycapSpacing.small),
                Expanded(child: done),
              ],
            ),
        ],
      ),
    );
  }
}
