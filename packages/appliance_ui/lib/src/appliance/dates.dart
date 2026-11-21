/// Appliance's dates and times: [ApplianceCalendar] (a month of days on the
/// panel, the chosen ones lit keys), [ApplianceDatePicker] and
/// [ApplianceDateRangePicker] (a key that opens one on a plate) and
/// [ApplianceTimePicker] (hours and minutes in a display window, each with
/// its up and down keys).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import 'actions.dart';
import 'lists.dart';
import 'material.dart';
import 'select.dart';
import 'text_field.dart';
import 'theme.dart';

// The ui_core types this part's API takes, through the look's barrel.
export 'package:ui_core/ui_core.dart'
    show RawCalendarController, RawCalendarMode, RawDateRange;

// Keep ui_core’s compact month and day, and the year in the same position
// and with the same punctuation as the reader’s named date.
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
  // A host can supply its own date wording with a different month form.
  return full;
}

/// A day cell's height at 1x text.
const double _dayHeight = 44;

/// A day cell's height: 44, or taller as the text grows so its key holds a
/// two-figure day whole.
double _dayHeightOf(BuildContext context) {
  final theme = ApplianceTheme.of(context);
  final painter = TextPainter(
    text: TextSpan(text: '28', style: theme.textTheme.body),
    textDirection: TextDirection.ltr,
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final height = math.max(
    _dayHeight,
    painter.height + 2 * ApplianceSpacing.tight + 2 * ApplianceSpacing.hair,
  );
  painter.dispose();
  return height;
}

/// A chevron, pointing to the start side when [back].
class _Chevron extends StatelessWidget {
  const _Chevron({required this.color, this.back = false});

  final Color color;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final rtl = Directionality.of(context) == TextDirection.rtl;
    return Transform.flip(
      flipX: back != rtl,
      child: CustomPaint(
        size: const Size.square(16),
        painter: ApplianceChevronPainter(color),
      ),
    );
  }
}

/// A small key with a glyph: a calendar's month keys, a time's up and down.
class _SmallKey extends StatelessWidget {
  const _SmallKey({
    required this.semanticLabel,
    required this.onPressed,
    required this.glyph,
    this.size = 32,
  });

  final String semanticLabel;
  final VoidCallback? onPressed;
  final Widget Function(Color ink) glyph;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = ApplianceTheme.of(context).colors;
    return RawButton(
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      excludeSemantics: true,
      builder: (context, states, _) {
        final face = applianceKeyFace(
          c,
          down: states.contains(WidgetState.pressed),
          disabled: onPressed == null,
          focused: states.contains(WidgetState.focused),
          radius: ApplianceMetrics.smallKeyRadius,
        );
        return TapTargetPadding(
          child: SizedBox.square(
            dimension: size,
            child: AnimatedApplianceSurface(
              face: face,
              child: Center(child: glyph(face.foreground)),
            ),
          ),
        );
      },
    );
  }
}

/// A month's header: its name, and keys to the month before and after.
Widget _header(BuildContext context, RawCalendarHeaderDetails header) {
  final theme = ApplianceTheme.of(context);
  return Padding(
    padding: const EdgeInsets.only(bottom: ApplianceSpacing.small),
    child: Row(
      children: [
        _SmallKey(
          semanticLabel: 'Previous month',
          onPressed: header.previous,
          glyph: (ink) => _Chevron(color: ink, back: true),
        ),
        Expanded(
          child: Text(
            header.label,
            textAlign: TextAlign.center,
            style: theme.textTheme.label.copyWith(color: theme.colors.print),
          ),
        ),
        _SmallKey(
          semanticLabel: 'Next month',
          onPressed: header.next,
          glyph: (ink) => _Chevron(color: ink),
        ),
      ],
    ),
  );
}

/// A weekday's heading, in the legend's small capitals.
Widget _weekday(BuildContext context, int weekday, String label) {
  final theme = ApplianceTheme.of(context);
  final style = theme.textTheme.legend.copyWith(color: theme.colors.printMuted);
  final painter = TextPainter(
    text: TextSpan(text: label, style: style),
    textDirection: Directionality.of(context),
    textScaler: MediaQuery.textScalerOf(context),
    maxLines: 1,
  )..layout();
  final height = math.max(28.0, painter.height + 2 * ApplianceSpacing.hair);
  painter.dispose();
  // Grown with the text, an initial wider than its column is scaled down to
  // fit it rather than run into its neighbour.
  return SizedBox(
    height: height,
    child: Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(label, maxLines: 1, softWrap: false, style: style),
      ),
    ),
  );
}

/// A day, painted for its [states]: chosen days (a range's ends) are lit
/// signal keys, the days between them a trough the keys stand in, today
/// marked by a small lit lamp. Hovering changes nothing; a press sinks a
/// key into the panel.
Widget _day(
  BuildContext context,
  RawCalendarDayDetails day,
  Set<WidgetState> states, [
  ApplianceStyle? style,
]) {
  final theme = ApplianceTheme.of(context);
  final c = theme.colors;
  final layered = DesignStyleOf([style, theme.calendarStyle], states);
  final pressed = states.contains(WidgetState.pressed);
  final focused = states.contains(WidgetState.focused);
  final previewEnd = day.inPreview && day.isPreviewEnd;
  final end = day.selected || day.isRangeStart || day.isRangeEnd || previewEnd;
  final band = day.inMonth && (day.inRange || day.inPreview);
  const radius = ApplianceMetrics.smallKeyRadius;
  final ApplianceFace face;
  if (!day.enabled) {
    face = ApplianceFace(
      top: c.keyTop.withValues(alpha: 0),
      bottom: c.keyBottom.withValues(alpha: 0),
      lift: 0,
      radius: BorderRadius.circular(radius),
      foreground: c.printDisabled,
      focus: c.focus.withValues(alpha: 0),
    );
  } else if (end) {
    face = applianceKeyFace(
      c,
      filled: true,
      down: pressed,
      focused: focused,
      radius: radius,
    );
  } else if (pressed) {
    face = applianceKeyFace(c, down: true, focused: focused, radius: radius);
  } else {
    face = ApplianceFace(
      top: c.keyTop.withValues(alpha: 0),
      bottom: c.keyBottom.withValues(alpha: 0),
      lift: 0,
      radius: BorderRadius.circular(radius),
      foreground: day.inMonth ? c.print : c.printDisabled,
      focus: focused ? c.focus : c.focus.withValues(alpha: 0),
    );
  }
  final startCap = day.isRangeStart;
  final endCap = day.isRangeEnd || previewEnd;
  final height = _dayHeightOf(context);
  return MouseRegion(
    cursor: day.enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
    child: SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (band)
            Positioned.fill(
              top: ApplianceSpacing.tight,
              bottom: ApplianceSpacing.tight,
              child: Container(
                decoration: BoxDecoration(
                  color: day.inRange
                      ? c.trough
                      : c.trough.withValues(alpha: 0.6),
                  borderRadius: BorderRadiusDirectional.horizontal(
                    start: startCap
                        ? const Radius.circular(radius)
                        : Radius.zero,
                    end: endCap ? const Radius.circular(radius) : Radius.zero,
                  ).resolve(Directionality.of(context)),
                ),
              ),
            ),
          // The key is square while its column allows, and keeps its height
          // in a narrower column, its figures scaled down to fit its width.
          _DayKey(
            side: height - 2 * ApplianceSpacing.tight,
            child: AnimatedApplianceSurface(
              face: layered.on(face),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ApplianceSpacing.hair,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          '${day.date.day}',
                          maxLines: 1,
                          softWrap: false,
                          style: layered.text(
                            theme.textTheme.body.copyWith(
                              color: face.foreground,
                              fontWeight: day.isToday || end
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (day.isToday && day.inMonth)
                    Positioned(
                      bottom: 3,
                      child: ApplianceLamp(
                        lit: true,
                        size: 4,
                        color: end ? c.onSignal : c.signal,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// A day's key: square while its column allows; in a narrower column it
// keeps its height and takes the column's width.
class _DayKey extends StatelessWidget {
  const _DayKey({required this.side, required this.child});

  final double side;
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => SizedBox(
      width: math.min(side, box.maxWidth),
      height: side,
      child: child,
    ),
  );
}

/// A calendar: a month of days on the panel, with keys to turn it. The day
/// chosen (a range's ends) is a lit signal key, the days between them a
/// trough; today carries a small lit lamp. The arrows walk the days, Page
/// Up and Down the months; Enter or Space chooses. Its days grow with the
/// text up to twice their size, as Material's calendar's do, their keys
/// with them.
///
/// [controller] holds the month, the selection and its mode (one day, a
/// range, several days).
///
/// ```dart
/// ApplianceCalendar(controller: RawCalendarController(firstDate: DateTime(2026), lastDate: DateTime(2027)))
/// ```
class ApplianceCalendar extends StatelessWidget {
  /// A calendar over [controller].
  const ApplianceCalendar({
    super.key,
    required this.controller,
    this.onChanged,
    this.months = 1,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The month shown and the selection; yours to dispose.
  final RawCalendarController controller;

  /// Called with the day chosen, after [controller] took it.
  final ValueChanged<DateTime>? onChanged;

  /// How many months show side by side.
  final int months;

  /// {@macro design.focusNode}
  final FocusNode? focusNode;

  /// Whether the days take the focus when shown.
  final bool autofocus;

  /// Its style, over [ApplianceThemeData.calendarStyle]: fill, foreground, textStyle (each day).
  final ApplianceStyle? style;

  // The days grow with the text up to 2x, as Material's calendar's do, and
  // their keys with them.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 2,
    child: Builder(builder: _month),
  );

  Widget _month(BuildContext context) {
    return RawCalendarDatePicker(
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
            if (i > 0) const SizedBox(width: ApplianceSpacing.large),
            Expanded(child: grid),
          ],
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('months', months, defaultValue: 1));
  }
}

/// A key that opens a plate under it, as a select's does: the date
/// pickers' anchor.
class _PickerKey extends StatelessWidget {
  const _PickerKey({
    required this.text,
    required this.empty,
    required this.enabled,
    required this.error,
    required this.semanticLabel,
    required this.semanticValue,
    required this.plate,
    required this.style,
  });

  final String text;
  final bool empty;
  final bool enabled;
  final bool error;
  final String? semanticLabel;
  final String? semanticValue;
  final Widget Function(BuildContext context, VoidCallback close) plate;
  final ApplianceStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    Widget face(DesignOverlayAnchor? anchor) {
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
          final down = states.contains(WidgetState.pressed) || open;
          final base = !enabled
              ? ApplianceFace.key(c).copyWith(lift: 0.35)
              : down
              ? ApplianceFace.keyDown(c)
              : ApplianceFace.key(c);
          final f = layered.on(
            base.copyWith(
              foreground: enabled ? c.print : c.printDisabled,
              edge: error ? c.danger : null,
              focus: states.contains(WidgetState.focused) && !open
                  ? (error ? c.danger : c.focus)
                  : c.focus.withValues(alpha: 0),
            ),
          );
          // The key's height, or taller as the text grows: the date wraps
          // before it is cut.
          return TapTargetPadding(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: theme.controlHeight),
              child: AnimatedApplianceSurface(
                face: f,
                child: Padding(
                  padding:
                      layered.padding(Directionality.of(context)) ??
                      const EdgeInsetsDirectional.only(
                        start: ApplianceSpacing.regular,
                        end: ApplianceSpacing.medium,
                        top: ApplianceSpacing.tight,
                        bottom: ApplianceSpacing.tight,
                      ),
                  child: Row(
                    children: [
                      Expanded(
                        child: DesignCapCenter(
                          capHeightFactor: theme.capHeightFactor,
                          child: Text(
                            text,
                            style: layered.text(
                              theme.textTheme.body.copyWith(
                                color: !enabled
                                    ? c.printDisabled
                                    : empty
                                    ? c.printMuted
                                    : f.foreground,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: ApplianceSpacing.small),
                      CustomPaint(
                        size: const Size(16, 16),
                        painter: _CalendarGlyph(
                          enabled ? c.printMuted : c.printDisabled,
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

    if (!enabled) return face(null);
    return RawPopover(
      semanticLabel: semanticLabel,
      placement: const RawPopoverPlacement(
        gap: ApplianceSpacing.tight + 2,
        margin: ApplianceSpacing.small,
        preferredExtent: 380,
        matchAnchorWidth: false,
        maxWidth: 340,
      ),
      dampingRatio: ApplianceMotion.lid.dampingRatio,
      stiffness: ApplianceMotion.lid.stiffness,
      anchorBuilder: (context, anchor) => face(anchor),
      overlayBuilder: (context, info) => ApplianceMenuReveal(
        animation: info.animation,
        below: info.side != RawPopoverSide.above,
        child: ApplianceMenuPlate(
          maxHeight: info.maxSize.height,
          child: Padding(
            padding: const EdgeInsets.all(ApplianceSpacing.medium),
            child: plate(context, info.close),
          ),
        ),
      ),
    );
  }
}

/// A small calendar sheet, the date pickers' glyph.
class _CalendarGlyph extends CustomPainter {
  _CalendarGlyph(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final line = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    canvas
      ..drawRRect(
        RRect.fromLTRBR(
          s * 0.12,
          s * 0.2,
          s * 0.88,
          s * 0.88,
          Radius.circular(s * 0.12),
        ),
        line,
      )
      ..drawLine(Offset(s * 0.12, s * 0.4), Offset(s * 0.88, s * 0.4), line)
      ..drawLine(Offset(s * 0.34, s * 0.1), Offset(s * 0.34, s * 0.28), line)
      ..drawLine(Offset(s * 0.66, s * 0.1), Offset(s * 0.66, s * 0.28), line);
  }

  @override
  bool shouldRepaint(_CalendarGlyph old) => old.color != color;
}

/// The plate's calendar, with a controller of its own while it is open.
class _CalendarPlate extends StatefulWidget {
  const _CalendarPlate({required this.make, required this.onChanged});

  final RawCalendarController Function() make;
  final void Function(RawCalendarController controller) onChanged;

  @override
  State<_CalendarPlate> createState() => _CalendarPlateState();
}

class _CalendarPlateState extends State<_CalendarPlate> {
  late final RawCalendarController _controller = widget.make();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 7 * 40,
    child: ApplianceCalendar(
      controller: _controller,
      autofocus: true,
      onChanged: (_) => widget.onChanged(_controller),
    ),
  );
}

/// A date picker: a key reading the date, which opens a calendar on a
/// plate under it. Choosing a day closes it.
///
/// ```dart
/// ApplianceDatePicker(label: 'Delivery day', value: DateTime(2026, 11, 20), firstDate: DateTime(2026, 11, 16), lastDate: DateTime(2027), onChanged: (day) {})
/// ```
class ApplianceDatePicker extends StatelessWidget {
  /// A picker of a day between [firstDate] and [lastDate].
  const ApplianceDatePicker({
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

  /// Called with the day chosen; null disables the picker.
  final ValueChanged<DateTime>? onChanged;

  /// The earliest day it offers.
  final DateTime firstDate;

  /// The latest day it offers.
  final DateTime lastDate;

  /// The words over the key.
  final String? label;

  /// What the key says before a day is chosen.
  final String hint;

  /// Help under the key.
  final String? helper;

  /// What is wrong, under the key.
  final String? error;

  /// The picker's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// Whether a day can be chosen; null: every day between the two.
  final bool Function(DateTime day)? selectable;

  /// Today, for the calendar's mark; the clock's otherwise.
  final DateTime? currentDate;

  /// The key's style, over [ApplianceThemeData.selectStyle].
  final ApplianceStyle? style;

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
          ExcludeSemantics(
            child: ApplianceFieldLabel(label!, enabled: enabled),
          ),
        _PickerKey(
          text: chosen == null ? hint : _dateLabel(words, chosen),
          empty: chosen == null,
          enabled: enabled,
          error: error != null,
          semanticLabel: semanticLabel ?? label,
          semanticValue: chosen == null ? null : words.formatFullDate(chosen),
          style: style,
          plate: (context, close) => _CalendarPlate(
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
        ApplianceFieldMessage(helper: helper, error: error),
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

/// A date range picker: a key reading the two days, which opens a calendar
/// on a plate. The first press chooses the start, the next the end (the
/// days between shown in the trough as the pointer moves); the plate closes
/// when both are chosen.
///
/// ```dart
/// ApplianceDateRangePicker(label: 'Away', value: RawDateRange(DateTime(2026, 12, 20), DateTime(2026, 12, 28)), firstDate: DateTime(2026, 11, 16), lastDate: DateTime(2027), onChanged: (range) {})
/// ```
class ApplianceDateRangePicker extends StatelessWidget {
  /// A picker of two days between [firstDate] and [lastDate].
  const ApplianceDateRangePicker({
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

  /// Called with both days once the end is chosen; null disables it.
  final ValueChanged<RawDateRange>? onChanged;

  /// The earliest day it offers.
  final DateTime firstDate;

  /// The latest day it offers.
  final DateTime lastDate;

  /// The words over the key.
  final String? label;

  /// What the key says before the days are chosen.
  final String hint;

  /// Help under the key.
  final String? helper;

  /// What is wrong, under the key.
  final String? error;

  /// The picker's name for a screen reader, when [label] is not shown.
  final String? semanticLabel;

  /// Today, for the calendar's mark; the clock's otherwise.
  final DateTime? currentDate;

  /// The key's style, over [ApplianceThemeData.selectStyle].
  final ApplianceStyle? style;

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
          ExcludeSemantics(
            child: ApplianceFieldLabel(label!, enabled: enabled),
          ),
        _PickerKey(
          text: range == null ? hint : rangeText(range),
          empty: range == null,
          enabled: enabled,
          error: error != null,
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
          plate: (context, close) => _CalendarPlate(
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
        ApplianceFieldMessage(helper: helper, error: error),
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(
        DiagnosticsProperty<RawDateRange>('value', value, defaultValue: null),
      );
  }
}

/// A time of day, to the minute.
@immutable
class ApplianceTime {
  /// [hour] (0 to 23) and [minute] (0 to 59).
  const ApplianceTime(this.hour, this.minute)
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour, 0 to 23.
  final int hour;

  /// The minute, 0 to 59.
  final int minute;

  /// This time with [hour] or [minute] changed.
  ApplianceTime copyWith({int? hour, int? minute}) =>
      ApplianceTime(hour ?? this.hour, minute ?? this.minute);

  @override
  bool operator ==(Object other) =>
      other is ApplianceTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// One of a time's figures in the window, with its up and down keys:
/// arrows change it (wrapping round), and so do the keys.
class _TimeDigits extends StatelessWidget {
  const _TimeDigits({
    required this.value,
    required this.max,
    required this.step,
    required this.shown,
    required this.semanticLabel,
    required this.onChanged,
    required this.fill,
  });

  final int value;
  final int max;
  final int step;
  final String shown;
  final String semanticLabel;
  final ValueChanged<int>? onChanged;

  // The window's glass, which a focused figure's cell is backlit on.
  final Color fill;

  int _wrap(int v) {
    final n = max + 1;
    return ((v % n) + n) % n;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final change = onChanged;
    final figure = theme.textTheme.display.copyWith(
      color: enabled ? c.onDisplay : c.onDisplay.withValues(alpha: 0.4),
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // The cell holds two figures whole as the text grows, so the keys over
    // and under it stay clear of them.
    final painter = TextPainter(
      text: TextSpan(text: '00', style: figure),
      textDirection: TextDirection.ltr,
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final cell = Size(
      math.max(48, painter.width + 2 * ApplianceSpacing.tight),
      math.max(44, painter.height + 2 * ApplianceSpacing.hair),
    );
    painter.dispose();
    Widget arrow({required bool up}) => _SmallKey(
      semanticLabel: '${up ? 'More' : 'Fewer'} $semanticLabel',
      onPressed: change == null
          ? null
          : () => change(_wrap(value + (up ? step : -step))),
      size: 28,
      glyph: (ink) => RotatedBox(
        quarterTurns: up ? 3 : 1,
        child: CustomPaint(
          size: const Size.square(14),
          painter: ApplianceChevronPainter(ink),
        ),
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(child: arrow(up: true)),
        const SizedBox(height: ApplianceSpacing.tight),
        DesignValueHandle(
          value: value.toDouble(),
          min: 0,
          max: max.toDouble(),
          step: step.toDouble(),
          pageStep: (step * 2).toDouble(),
          axis: Axis.vertical,
          semanticLabel: semanticLabel,
          semanticFormatterCallback: (_) => shown,
          mouseCursor: SystemMouseCursors.basic,
          onChanged: change == null
              ? null
              : (v) => change(_wrap((v / step).round() * step)),
          onKeyEvent: change == null
              ? null
              : (node, event) {
                  if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                    return KeyEventResult.ignored;
                  }
                  final key = event.logicalKey;
                  if (key == LogicalKeyboardKey.arrowUp && value + step > max) {
                    change(_wrap(value + step));
                    return KeyEventResult.handled;
                  }
                  if (key == LogicalKeyboardKey.arrowDown && value - step < 0) {
                    change(_wrap(value - step));
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
          // A focused figure's cell is backlit, as a key's rim is.
          builder: (context, states) => SizedBox.fromSize(
            size: cell,
            child: AnimatedApplianceSurface(
              control: false,
              face: ApplianceFace(
                top: fill,
                bottom: fill,
                radius: BorderRadius.circular(ApplianceSpacing.tight),
                focus: states.contains(WidgetState.focused)
                    ? c.focus
                    : c.focus.withValues(alpha: 0),
              ),
              child: Center(
                child: Text(shown, maxLines: 1, softWrap: false, style: figure),
              ),
            ),
          ),
        ),
        const SizedBox(height: ApplianceSpacing.tight),
        ExcludeSemantics(child: arrow(up: false)),
      ],
    );
  }
}

/// A time picker: hours and minutes lit in a display window, each with an
/// up key over it and a down key under it. The arrows change the figure
/// focused, wrapping round; Page Up and Down change it faster. With
/// [twentyFourHour] false a latching key beside the window chooses the
/// afternoon. Its figures grow with the text up to twice their size, as
/// Material's time picker's do, the window with them.
///
/// ```dart
/// ApplianceTimePicker(value: const ApplianceTime(18, 30), onChanged: (time) {})
/// ```
class ApplianceTimePicker extends StatelessWidget {
  /// A picker of [value].
  const ApplianceTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteStep = 5,
    this.twentyFourHour = true,
    this.semanticLabel,
    this.style,
  }) : assert(minuteStep > 0 && minuteStep <= 30);

  /// The time shown.
  final ApplianceTime value;

  /// Called with the new time; null shows it only.
  final ValueChanged<ApplianceTime>? onChanged;

  /// How far a minute's key or arrow moves it.
  final int minuteStep;

  /// Whether the hours run 0 to 23; otherwise 1 to 12 with a key for the
  /// afternoon.
  final bool twentyFourHour;

  /// The picker's name for a screen reader; null leaves it to the field
  /// round it ([ApplianceField]'s label). Its figures are named "Hour" and
  /// "Minute" in the reader's language either way.
  final String? semanticLabel;

  /// Its style, over [ApplianceThemeData.displayStyle]: fill (the window), foreground, textStyle (the figures).
  final ApplianceStyle? style;

  // The figures grow with the text up to 2x, as Material's time picker's
  // do, their cells with them, so they show whole and the keys stay clear.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 2,
    child: Builder(builder: _picker),
  );

  Widget _picker(BuildContext context) {
    final look = DesignStyleOf([
      style,
      ApplianceTheme.of(context).displayStyle,
    ], const {});
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    final hour12 = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final pm = value.hour >= 12;
    // Each figure named in the reader's words ("Hour", "Minute") and set in
    // the reader's digits (Arabic-Indic in Arabic): the figures are text in
    // the window, as Material's time picker sets its hours.
    final words = RawWidgetsLocalizations.of(context);
    String two(int n) => n < 10
        ? '${words.formatDecimal(0)}${words.formatDecimal(n)}'
        : words.formatDecimal(n);
    final window = ApplianceSurface(
      face: ApplianceFace.well(c, fill: look.fill ?? c.display),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ApplianceSpacing.small,
          vertical: ApplianceMetrics.windowInset,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _TimeDigits(
              value: value.hour,
              max: 23,
              step: 1,
              shown: twentyFourHour
                  ? two(value.hour)
                  : words.formatDecimal(hour12),
              semanticLabel: words.timePickerHourLabel,
              fill: look.fill ?? c.display,
              onChanged: change == null
                  ? null
                  : (h) => change(value.copyWith(hour: h)),
            ),
            ExcludeSemantics(
              child: Text(
                ':',
                style: look
                    .text(theme.textTheme.display)
                    .copyWith(color: look.foreground ?? c.onDisplay),
              ),
            ),
            _TimeDigits(
              value: value.minute,
              max: 59,
              step: minuteStep,
              shown: two(value.minute),
              semanticLabel: words.timePickerMinuteLabel,
              fill: look.fill ?? c.display,
              onChanged: change == null
                  ? null
                  : (m) => change(value.copyWith(minute: m)),
            ),
          ],
        ),
      ),
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      explicitChildNodes: true,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            window,
            if (!twentyFourHour) ...[
              const SizedBox(width: ApplianceSpacing.medium),
              _Meridiem(
                pm: pm,
                onChanged: change == null
                    ? null
                    : (afternoon) => change(
                        value.copyWith(
                          hour: value.hour % 12 + (afternoon ? 12 : 0),
                        ),
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<ApplianceTime>('value', value))
      ..add(IntProperty('minuteStep', minuteStep, defaultValue: 5));
  }
}

/// Two latching keys, morning and afternoon.
class _Meridiem extends StatelessWidget {
  const _Meridiem({required this.pm, required this.onChanged});

  final bool pm;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ApplianceTheme.of(context);
    final c = theme.colors;
    Widget key(String label, bool afternoon) {
      final on = pm == afternoon;
      final change = onChanged;
      return RawButton(
        onPressed: change == null ? null : () => change(afternoon),
        selected: on,
        semanticLabel: label,
        excludeSemantics: true,
        builder: (context, states, _) {
          final face = applianceKeyFace(
            c,
            down: on || states.contains(WidgetState.pressed),
            disabled: change == null,
            focused: states.contains(WidgetState.focused),
            radius: ApplianceMetrics.smallKeyRadius,
          );
          return TapTargetPadding(
            child: SizedBox(
              width: 56,
              height: 36,
              child: AnimatedApplianceSurface(
                face: face,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ApplianceLamp(
                      lit: on && change != null,
                      size: ApplianceMetrics.lampSize - 2,
                    ),
                    const SizedBox(width: ApplianceSpacing.tight + 2),
                    Text(
                      label,
                      style: theme.textTheme.legend.copyWith(
                        color: face.foreground,
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

    // The halves of the day as the reader writes them.
    final words = RawWidgetsLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        key(words.anteMeridiemAbbreviation, false),
        const SizedBox(height: ApplianceSpacing.small),
        key(words.postMeridiemAbbreviation, true),
      ],
    );
  }
}
