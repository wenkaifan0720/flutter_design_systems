import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/paint.dart';
import '../../internal/spring.dart';
import '../../theme.dart';
import '../icon-button/icon_button.dart';

// A calendar's caller builds its controller and reads the day it holds.
export 'package:ui_core/ui_core.dart'
    show DesignCalendarController, DesignDateRange;

/// A month of days to choose from: the month's name between the ways to
/// the month before and after, the weekdays, and the days on square faces.
/// A month stands at most [monthWidth] wide from the start of its column, as
/// Material's calendar does, wider only as far as larger text needs; its
/// words grow at most [textScaleMost] times with the reader's text.
/// The day chosen is solid in the action colour; a range's days between
/// its ends stand on the action's tint; today's number is bold over a short
/// rule; a pointer greys a day; the keyboard's day stands on the yellow
/// plate over the ink bar. Days that can't be chosen are faded.
///
/// The [controller] holds the month shown, the selection (one day, a range
/// or several, by its mode) and the days offered; the calendar draws it.
/// Tab reaches the grid once; the arrow keys move a day or a week, Page Up
/// and Page Down a month, Home and End the week's ends; Enter and Space
/// choose. A screen reader hears each day in full.
///
/// For a date someone knows (a date of birth), [CivicDateInput]'s typed
/// boxes are quicker; [CivicDatePicker] offers both.
///
/// Reads [CivicStyle]'s fill and foreground by a day's state (selected
/// among them): its `style:`, then [CivicThemeData.calendarStyle].
///
/// With `dates` a `DesignCalendarController(firstDate: DateTime(2026),
/// lastDate: DateTime(2027, 12, 31))` the page's state keeps:
///
/// ```dart
/// CivicCalendar(
///   controller: dates,
///   onChanged: (day) => setState(() => chosen = day),
/// )
/// ```
class CivicCalendar extends StatefulWidget {
  /// A calendar over [controller].
  const CivicCalendar({
    super.key,
    required this.controller,
    this.onChanged,
    this.months = 1,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(months > 0);

  /// The month shown, the selection and the days offered. The caller makes
  /// it, keeps it and disposes it.
  final DesignCalendarController controller;

  /// Called with the day a press or Enter chose, after the controller took
  /// it.
  final ValueChanged<DateTime>? onChanged;

  /// How many months show at once: two for a range on a wide window. They
  /// stack where they don't fit side by side.
  final int months;

  /// {@macro civic.focusNode}
  final FocusNode? focusNode;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the days' look.
  final CivicStyle? style;

  /// A day's least width: a finger's target.
  static const double dayWidth = 44;

  /// A month's widest at the reader's usual text: seven days of 56, near
  /// Material's 360-wide calendar. On a wide page a month stretched to
  /// the page's width spread its days apart; larger text widens it as far
  /// as the widest day's number needs.
  static const double monthWidth = 7 * 56;

  /// The gap between months side by side.
  static const double monthGap = CivicSpacing.s32;

  /// The most a calendar's words (the month's name, the weekdays, the days)
  /// grow with the reader's text: twice, as Material's calendar on a phone.
  /// Larger, seven days' numbers outgrow a phone's width and break, and the
  /// month's name breaks beside its arrows.
  static const double textScaleMost = 2;

  /// How wide a month stands in [context]: [monthWidth], or seven of the
  /// widest day's number (bold, as today's and a chosen day's, at most
  /// [textScaleMost] times) with [CivicSpacing.s8] either side, where the
  /// reader's text needs more.
  static double monthWidthOf(BuildContext context) {
    final words = DesignLocalizations.of(context);
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context)
          .clamp(maxScaleFactor: textScaleMost),
      maxLines: 1,
    );
    var day = 0.0;
    for (var d = 1; d <= 31; d++) {
      painter
        ..text = TextSpan(
          text: words.formatDecimal(d),
          style: context.civicText.label.copyWith(height: 1.2),
        )
        ..layout();
      day = math.max(day, painter.width);
    }
    painter.dispose();
    return math.max(monthWidth, 7 * (day + 2 * CivicSpacing.s8)).ceilToDouble();
  }

  @override
  State<CivicCalendar> createState() => _CivicCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<DesignCalendarController>('controller', controller),
      )
      ..add(IntProperty('months', months, defaultValue: 1))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicCalendarState extends State<CivicCalendar> {
  FocusNode? _own;
  FocusNode get _grid => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // The month buttons stand inside the grid's focus: the keyboard's day
    // shows only while the grid itself holds the focus, not a button.
    return ListenableBuilder(
      listenable: _grid,
      builder: (context, _) => _calendar(context, _grid.hasPrimaryFocus),
    );
  }

  Widget _calendar(BuildContext context, bool gridHasFocus) {
    final controller = widget.controller;
    final style = widget.style;
    final t = context.civicTheme;
    final text = context.civicText;
    final words = DesignLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final widest = CivicCalendar.monthWidthOf(context);
    final calendar = DesignCalendar(
      controller: controller,
      onChanged: widget.onChanged,
      months: widget.months,
      focusNode: _grid,
      autofocus: widget.autofocus,
      showOutsideDays: false,
      minDayWidth: CivicCalendar.dayWidth,
      monthsBuilder: (context, list) => Wrap(
        spacing: CivicCalendar.monthGap,
        runSpacing: CivicSpacing.s24,
        children: [
          for (final month in list)
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widest),
              child: month,
            ),
        ],
      ),
      headerBuilder: (context, header) => Padding(
        padding: const EdgeInsets.only(bottom: CivicSpacing.s8),
        child: Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  header.label,
                  style: text.headingS.copyWith(color: t.textPrimary),
                ),
              ),
            ),
            if (header.previous != null || header.next != null)
              IconTheme.merge(
                data: IconThemeData(color: t.textPrimary),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CivicIconButton(
                      icon: rtl
                          ? LucideIcons.chevronRight
                          : LucideIcons.chevronLeft,
                      semanticLabel: words.previousMonthTooltip,
                      tooltip: words.previousMonthTooltip,
                      onPressed: header.previous,
                    ),
                    CivicIconButton(
                      icon: rtl
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      semanticLabel: words.nextMonthTooltip,
                      tooltip: words.nextMonthTooltip,
                      onPressed: header.next,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      weekdayBuilder: (context, weekday, label) => Padding(
        padding: const EdgeInsets.only(bottom: CivicSpacing.s4),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: text.bodySmall.copyWith(
            color: t.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      dayBuilder: (context, day, states) => _Day(
        day: day,
        states: gridHasFocus
            ? states
            : states.difference(const {WidgetState.focused}),
        styles: [style, t.calendarStyle],
      ),
    );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: CivicCalendar.textScaleMost,
      child: calendar,
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day, required this.states, required this.styles});

  final DesignCalendarDay day;
  final Set<WidgetState> states;
  final List<DesignStyle?> styles;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final text = context.civicText;
    final so = DesignStyleOf(styles, states);
    final enabled = day.enabled;
    final end = day.selected || day.isRangeStart || day.isRangeEnd;
    final between = !end && (day.inRange || day.inPreview);
    final focused = states.contains(WidgetState.focused);
    final hovered = enabled && states.contains(WidgetState.hovered);
    final pressed = enabled && states.contains(WidgetState.pressed);
    final (fill, ink) = !enabled
        ? (t.background, t.textDisabled)
        : end
        ? (so.fill ?? t.action, so.foreground ?? t.onAction)
        : between
        ? (
            day.inPreview && !day.inRange
                ? Color.lerp(t.background, t.secondaryFill, 0.6)!
                : t.secondaryFill,
            t.onSecondary,
          )
        : (so.fill ?? t.background, so.foreground ?? t.textPrimary);
    final touched = end
        ? (t.isDark
              ? Color.lerp(fill, const Color(0xFFFFFFFF), 0.2)!
              : Color.lerp(fill, const Color(0xFF000000), 0.3)!)
        : Color.lerp(fill, t.rule, pressed ? 0.75 : 0.45)!;
    return CivicSpringValue(
      value: pressed ? 1 : (hovered ? 0.7 : 0),
      spring: CivicMotion.press,
      effects: true,
      builder: (context, touch, _) => CivicSpringValue(
        value: focused ? 1 : 0,
        spring: CivicMotion.focus,
        effects: true,
        builder: (context, focus, _) => CustomPaint(
          painter: CivicFacePainter(
            fill: Color.lerp(fill, touched, touch)!,
            edgeColor: t.onFocus,
            edgeHeight: 0,
            press: 0,
            focus: focus,
            focusColor: t.focus,
            barColor: t.focusBar,
          ),
          // At least a finger's 44, taller as the text grows; every day
          // keeps room for today's rule, so a week's days stand level.
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minHeight: CivicCalendar.dayWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: CivicSpacing.s4),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DesignLocalizations.of(context).formatDecimal(day.date.day),
                    style: (day.isToday || end ? text.label : text.body)
                        .copyWith(
                          height: 1.2,
                          color: Color.lerp(ink, t.onFocus, focus),
                          decoration: enabled
                              ? null
                              : TextDecoration.lineThrough,
                          decorationColor: t.textDisabled,
                        ),
                  ),
                  SizedBox(
                    width: 16,
                    height: 3,
                    child: day.isToday
                        ? ColoredBox(
                            color: Color.lerp(
                              end ? ink : t.action,
                              t.onFocus,
                              focus,
                            )!,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
