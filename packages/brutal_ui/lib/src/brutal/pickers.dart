/// Brutal's pickers. [BrutalCalendar] is a month as a table: the bar, the
/// weekdays and the days all cells on shared rules, the chosen day ink and a
/// span's middle lime. [BrutalDatePicker] and [BrutalDateRangePicker] are a
/// field that drops one; [BrutalWheelPicker] and [BrutalTimePicker] are flat
/// wheels between two heavy rules; [BrutalColorPicker] is a ruled field of
/// colour with a hue track and the colour's code.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/field_frame.dart';
import 'surface.dart';
import 'theme.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A span of days, from [start] to [end]: what [BrutalCalendar] and
/// [BrutalDateRangePicker] take and report.
///
/// ```dart
/// BrutalDateRange(start: DateTime(2026, 11, 14), end: DateTime(2026, 11, 16))
/// ```
@immutable
class BrutalDateRange {
  /// A span from [start] to [end]; [end] is not before [start].
  BrutalDateRange({required this.start, required this.end})
    : assert(!end.isBefore(start));

  /// The first day.
  final DateTime start;

  /// The last day.
  final DateTime end;

  /// How long the span is.
  Duration get duration => end.difference(start);

  @override
  bool operator ==(Object other) =>
      other is BrutalDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'BrutalDateRange($start, $end)';
}

/// A time of day, an hour from 0 to 23 and a minute: what [BrutalTimePicker]
/// takes and reports.
///
/// ```dart
/// const BrutalTime(hour: 19, minute: 30)
/// ```
@immutable
class BrutalTime {
  /// The time [hour]:[minute] on a 24-hour clock.
  const BrutalTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour, 0 to 23.
  final int hour;

  /// The minute, 0 to 59.
  final int minute;

  @override
  bool operator ==(Object other) =>
      other is BrutalTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      'BrutalTime(${hour.toString().padLeft(2, '0')}:'
      "${minute.toString().padLeft(2, '0')})";
}

/// Draws a rule [width] wide along a cell's top and start sides; the table
/// round the cells draws the end and bottom ones.
class _TopStart extends CustomPainter {
  _TopStart(this.color, this.direction, this.width);

  final Color color;
  final TextDirection direction;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final w = width;
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, w), paint);
    final x = direction == TextDirection.rtl ? size.width - w : 0.0;
    canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
  }

  @override
  bool shouldRepaint(_TopStart old) =>
      old.color != color || old.direction != direction || old.width != width;
}

/// A cell of the calendar's table: its top and start rules, [fill] inside
/// them, [child] centred in what is left.
class _Cell extends StatelessWidget {
  const _Cell({
    required this.height,
    required this.child,
    required this.rule,
    this.fill,
    this.focus,
  });

  final double height;
  final Widget child;
  final Color rule;
  final Color? fill;
  final Color? focus;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final w = theme.borderWidth;
    final direction = Directionality.of(context);
    return SizedBox(
      height: height,
      child: CustomPaint(
        foregroundPainter: _TopStart(rule, direction, w),
        child: Padding(
          padding: EdgeInsetsDirectional.only(start: w, top: w),
          child: CustomPaint(
            foregroundPainter: focus == null
                ? null
                : BrutalInsetFocusPainter(focus!),
            child: ColoredBox(
              color: fill ?? c.ink.withValues(alpha: 0),
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// The table's end and bottom rules round [child].
class _Table extends StatelessWidget {
  const _Table({required this.rule, required this.child});

  final Color rule;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final w = BrutalTheme.of(context).borderWidth;
    final direction = Directionality.of(context);
    return CustomPaint(
      foregroundPainter: _EndBottom(rule, direction, w),
      child: Padding(
        padding: EdgeInsetsDirectional.only(end: w, bottom: w),
        child: child,
      ),
    );
  }
}

class _EndBottom extends CustomPainter {
  _EndBottom(this.color, this.direction, this.width);

  final Color color;
  final TextDirection direction;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final w = width;
    final paint = Paint()..color = color;
    canvas.drawRect(Rect.fromLTWH(0, size.height - w, size.width, w), paint);
    final x = direction == TextDirection.rtl ? 0.0 : size.width - w;
    canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
  }

  @override
  bool shouldRepaint(_EndBottom old) =>
      old.color != color || old.direction != direction || old.width != width;
}

/// A month (or, with [months], several side by side) as a table of cells
/// on shared rules: a bar with the month and its two turns, the weekdays,
/// the days. The chosen day is ink with paper figures; today's figures are
/// heavy over a bar; the keyboard's day carries the inset focus rule.
///
/// The unnamed constructor chooses one day; [BrutalCalendar.range] a span,
/// its ends ink and its middle lime (a span waiting for its end shows the
/// same, to the day under the pointer). A null callback greys every day.
///
/// The arrows move by a day and a week, Page Up and Down by a month, Enter
/// chooses. Its words and figures grow with the reader's text to twice
/// their size, as Material's calendar's do, and keep that size beyond, so a
/// two-digit day stays inside its cell.
///
/// Reads [style]'s `edge` (every rule), `fill` (a chosen day or a span's
/// end, selected among its states; its figures take black or white by
/// contrast), `foreground` (the month's other days), `textStyle` (the
/// figures) and `iconSize` (the turns), then
/// [BrutalThemeData.calendarStyle]'s. A pressed day stays ink and a span's
/// middle lime.
///
/// ```dart
/// BrutalCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), selectedDate: day, onDateChanged: (d) => setState(() => day = d))
/// ```
class BrutalCalendar extends StatefulWidget {
  /// A calendar that chooses one day.
  const BrutalCalendar({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.onDateChanged,
    this.selectedDate,
    this.currentDate,
    this.selectableDayPredicate,
    this.autofocus = false,
    this.style,
  }) : selectedRange = null,
       onRangeChanged = null,
       months = 1,
       _range = false;

  /// A calendar that chooses a span, over [months] months side by side.
  const BrutalCalendar.range({
    super.key,
    required this.firstDate,
    required this.lastDate,
    required this.onRangeChanged,
    this.selectedRange,
    this.currentDate,
    this.selectableDayPredicate,
    this.months = 1,
    this.autofocus = false,
    this.style,
  }) : selectedDate = null,
       onDateChanged = null,
       _range = true;

  /// The first day that may be chosen.
  final DateTime firstDate;

  /// The last.
  final DateTime lastDate;

  /// The day chosen.
  final DateTime? selectedDate;

  /// Called with the day chosen; null greys the days.
  final ValueChanged<DateTime>? onDateChanged;

  /// The span chosen.
  final BrutalDateRange? selectedRange;

  /// Called once a span has both ends; null greys the days.
  final ValueChanged<BrutalDateRange>? onRangeChanged;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// Whether a day inside the bounds may be chosen.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// How many months stand side by side.
  final int months;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [BrutalThemeData.calendarStyle].
  final BrutalStyle? style;

  final bool _range;

  @override
  State<BrutalCalendar> createState() => _BrutalCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('selectedDate', selectedDate))
      ..add(
        DiagnosticsProperty<BrutalDateRange>('selectedRange', selectedRange),
      )
      ..add(FlagProperty('range', value: _range, ifTrue: 'range'));
  }
}

class _BrutalCalendarState extends State<BrutalCalendar> {
  late RawCalendarController _controller = _make();

  bool get _enabled => widget._range
      ? widget.onRangeChanged != null
      : widget.onDateChanged != null;

  RawCalendarController _make() => RawCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: widget._range ? RawCalendarMode.range : RawCalendarMode.single,
    selectedDate: widget.selectedDate,
    selectedRange: widget.selectedRange == null
        ? null
        : RawDateRange(widget.selectedRange!.start, widget.selectedRange!.end),
    currentDate: widget.currentDate,
    selectable: (d) =>
        _enabled && (widget.selectableDayPredicate?.call(d) ?? true),
  );

  @override
  void didUpdateWidget(BrutalCalendar old) {
    super.didUpdateWidget(old);
    final rebuilt =
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old._range != widget._range;
    final selection = widget._range
        ? widget.selectedRange != old.selectedRange &&
              widget.selectedRange?.start != _controller.selectedRange?.start
        : widget.selectedDate != null &&
              _day(widget.selectedDate!) != _controller.selectedDate;
    if (rebuilt || selection) {
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
    if (!widget._range) {
      widget.onDateChanged?.call(day);
      return;
    }
    final r = _controller.selectedRange;
    if (r != null && r.end != null) {
      widget.onRangeChanged?.call(BrutalDateRange(start: r.start, end: r.end!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layers = [widget.style, theme.calendarStyle];
    final frame = DesignStyleOf(layers, const {});
    final rule = frame.side?.color ?? frame.edge ?? c.ink;
    final w = theme.borderWidth;
    // A day's row grows with its figure (at large text, to twice its
    // size), never under 44.
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(maxScaleFactor: _maxTextScale);
    final dayHeight = math.max(44.0, scaler.scale(15) * 20 / 15 + 3 * w + 4);
    Widget turn(IconData icon, String label, VoidCallback? onPressed) =>
        TapTargetPadding(
          child: RawButton(
            onPressed: onPressed,
            semanticLabel: label,
            builder: (context, states, _) {
              final pressed = states.contains(WidgetState.pressed);
              final ink = states.contains(WidgetState.disabled)
                  ? c.disabled
                  : pressed
                  ? c.paper
                  : c.ink;
              return SizedBox(
                width: dayHeight + w,
                child: _Cell(
                  height: dayHeight + w,
                  rule: rule,
                  fill: pressed ? c.ink : null,
                  focus: states.contains(WidgetState.focused)
                      ? (pressed ? c.paper : c.ink)
                      : null,
                  child: Transform.flip(
                    flipX: rtl,
                    child: Icon(icon, size: frame.iconSize ?? 20, color: ink),
                  ),
                ),
              );
            },
          ),
        );
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: _maxTextScale,
      child: _Table(
        rule: rule,
        child: RawCalendarDatePicker(
          controller: _controller,
          months: widget.months,
          autofocus: widget.autofocus,
          onChanged: _changed,
          headerBuilder: (context, header) => Row(
            children: [
              turn(
                LucideIcons.chevronLeft,
                words.previousMonthTooltip,
                header.previous,
              ),
              Expanded(
                child: _Cell(
                  height: dayHeight + w,
                  rule: rule,
                  child: DesignCapCenter(
                    capHeightFactor: BrutalTheme.of(context).capHeightFactor,
                    child: Text(header.label, maxLines: 1, style: t.label),
                  ),
                ),
              ),
              turn(
                LucideIcons.chevronRight,
                words.nextMonthTooltip,
                header.next,
              ),
            ],
          ),
          weekdayBuilder: (context, weekday, label) => _Cell(
            height: 32,
            rule: rule,
            child: Text(
              label.toUpperCase(),
              maxLines: 1,
              style: t.caption.copyWith(color: c.inkMuted),
            ),
          ),
          dayBuilder: (context, day, states) {
            final pressed = states.contains(WidgetState.pressed);
            final end =
                day.selected ||
                day.isRangeStart ||
                day.isRangeEnd ||
                day.isPreviewEnd;
            final middle = !end && (day.inRange || day.inPreview);
            final layered = DesignStyleOf(layers, {
              ...states,
              if (end) WidgetState.selected,
            });
            final Color? fill;
            final Color figures;
            if (!day.enabled) {
              fill = end ? c.disabled : null;
              figures = end ? c.surface : c.disabled;
            } else if (pressed) {
              fill = c.ink;
              figures = c.paper;
            } else if (end) {
              fill = layered.fill ?? c.ink;
              figures = c.onColor(fill);
            } else if (middle) {
              fill = c.lime;
              figures = c.onBlock;
            } else {
              fill = null;
              figures = day.inMonth ? layered.foreground ?? c.ink : c.inkMuted;
            }
            return _Cell(
              height: dayHeight,
              rule: rule,
              fill: fill,
              focus: states.contains(WidgetState.focused)
                  ? (fill == c.ink ? c.paper : c.ink)
                  : null,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // One line; at large text on a phone it shrinks to its cell
                  // rather than breaking the figure in two.
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${day.date.day}',
                        maxLines: 1,
                        softWrap: false,
                        style: layered
                            .text(
                              t.label.copyWith(fontSize: 15, height: 20 / 15),
                            )
                            .copyWith(
                              color: figures,
                              fontWeight: day.isToday
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 12,
                    height: w,
                    child: day.isToday ? ColoredBox(color: figures) : null,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // How far its words and figures grow with the reader's text.
  static const double _maxTextScale = 2;
}

/// A field-shaped trigger: its words (or the hint) and a glyph in a cell of
/// its own, the focus rule while its panel is open. It reads
/// [BrutalThemeData.textFieldStyle] as every field's box does.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.anchor,
    required this.text,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.error,
  });

  final DesignOverlayAnchor anchor;
  final String? text;
  final String? hint;
  final IconData icon;
  final bool enabled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final height =
        DesignStyleOf([theme.textFieldStyle], const {}).minimumSize?.height ??
        theme.controlHeight;
    return RawButton(
      onPressed: enabled ? anchor.toggle : null,
      expanded: anchor.isOpen,
      semanticValue: text,
      builder: (context, states, _) {
        final layered = DesignStyleOf(
          [theme.textFieldStyle],
          {...states, if (error) WidgetState.error},
        );
        final rule =
            layered.side?.color ??
            layered.edge ??
            (!enabled
                ? c.disabled
                : error
                ? c.danger
                : c.ink);
        final ink = layered.foreground ?? (enabled ? c.ink : c.disabled);
        // A value longer than the field at a large text size (a full date
        // at 200%) takes a second line and the field grows with it, rather
        // than cutting the date short.
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: AnimatedBrutalSurface(
            stiffness: BrutalMotion.colorStiffness,
            face: BrutalFace(
              fill: layered.fill ?? c.surface,
              border: rule,
              foreground: ink,
              focus: states.contains(WidgetState.focused) || anchor.isOpen
                  ? rule
                  : rule.withValues(alpha: 0),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding:
                        layered.padding(Directionality.of(context)) ??
                        const EdgeInsets.symmetric(
                          horizontal: BrutalSpacing.medium,
                          vertical: BrutalSpacing.small,
                        ),
                    child: DesignCapCenter(
                      capHeightFactor: theme.capHeightFactor,
                      child: Text(
                        text ?? hint ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: layered
                            .text(theme.textTheme.body)
                            .copyWith(
                              color: !enabled
                                  ? c.disabled
                                  : text == null
                                  ? c.inkMuted
                                  : ink,
                            ),
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  width: theme.borderWidth,
                  child: ColoredBox(color: rule),
                ),
                SizedBox(
                  width: height - 2 * theme.borderWidth,
                  child: Center(
                    child: Icon(icon, size: layered.iconSize ?? 20, color: ink),
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

/// The raised panel a picker drops, its ground and rule from [layers].
Widget _panel(
  BuildContext context,
  RawPopoverInfo info,
  List<BrutalStyle?> layers,
  Widget child,
) {
  final c = BrutalTheme.of(context).colors;
  final layered = DesignStyleOf(layers, const {});
  return FadeTransition(
    opacity: info.animation,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxHeight: info.maxSize.height),
      child: BrutalSurface(
        face: BrutalFace(
          fill: layered.fill ?? c.surface,
          border: layered.side?.color ?? layered.edge ?? c.ink,
          foreground: c.ink,
          shadow: c.ink,
        ),
        child: SingleChildScrollView(
          primary: false,
          padding: const EdgeInsets.all(BrutalSpacing.medium),
          child: child,
        ),
      ),
    ),
  );
}

/// A label, a field and its message round [field], as the look's fields
/// stand.
Widget _labelled(
  Widget field, {
  required String? label,
  required String? helper,
  required String? error,
  required bool enabled,
}) => BrutalFieldFrame(
  labelText: label,
  helperText: helper,
  errorText: error,
  enabled: enabled,
  child: field,
);

/// A date in a field: a press drops a [BrutalCalendar] under it, and a
/// chosen day closes it. A null [onChanged] disables it.
///
/// The field reads [BrutalThemeData.textFieldStyle] as every field does;
/// the panel and its calendar read [style], then
/// [BrutalThemeData.calendarStyle], as [BrutalCalendar] does.
///
/// ```dart
/// BrutalDatePicker(labelText: 'Date', value: day, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (d) => setState(() => day = d))
/// ```
class BrutalDatePicker extends StatelessWidget {
  /// A date field.
  const BrutalDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText = 'Choose a date',
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
  });

  /// The date chosen.
  final DateTime? value;

  /// Called with the date chosen; null disables it.
  final ValueChanged<DateTime>? onChanged;

  /// The first day that may be chosen.
  final DateTime firstDate;

  /// The last.
  final DateTime lastDate;

  /// The words over the field.
  final String? labelText;

  /// What the empty field says.
  final String hintText;

  /// Help under the field.
  final String? helperText;

  /// What is wrong, under the field in red.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// The calendar's style, over [BrutalThemeData.calendarStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final layers = [style, BrutalTheme.of(context).calendarStyle];
    return _labelled(
      RawPopover(
        semanticLabel: labelText,
        // The calendar opens where its whole month fits: below while below
        // holds it, else above; it shrinks and scrolls only where neither
        // side does.
        placement: const RawPopoverPlacement(
          gap: BrutalSpacing.small,
          margin: BrutalSpacing.small,
          matchAnchorWidth: false,
          fit: RawPopoverFit.whole,
        ),
        dampingRatio: BrutalMotion.dampingRatio,
        stiffness: BrutalMotion.overlayStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          text: value == null ? null : words.formatFullDate(value!),
          hint: hintText,
          icon: LucideIcons.calendar,
          enabled: enabled,
          error: errorText != null,
        ),
        overlayBuilder: (context, info) => _panel(
          context,
          info,
          layers,
          SizedBox(
            width: 320,
            child: BrutalCalendar(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedDate: value,
              currentDate: currentDate,
              autofocus: true,
              style: style,
              onDateChanged: (d) {
                info.close();
                onChanged?.call(d);
              },
            ),
          ),
        ),
      ),
      label: labelText,
      helper: helperText,
      error: errorText,
      enabled: enabled,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<DateTime>(
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A span of dates in a field: a press drops a [BrutalCalendar.range] (two
/// months side by side from 600 px wide), and a span with both ends closes
/// it.
///
/// The field reads [BrutalThemeData.textFieldStyle] as every field does;
/// the panel and its calendar read [style], then
/// [BrutalThemeData.calendarStyle], as [BrutalCalendar] does.
///
/// ```dart
/// BrutalDateRangePicker(labelText: 'Dates', value: span, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (r) => setState(() => span = r))
/// ```
class BrutalDateRangePicker extends StatelessWidget {
  /// A date span field.
  const BrutalDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText = 'Choose dates',
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
  });

  /// The span chosen.
  final BrutalDateRange? value;

  /// Called with the span chosen; null disables it.
  final ValueChanged<BrutalDateRange>? onChanged;

  /// The first day that may be chosen.
  final DateTime firstDate;

  /// The last.
  final DateTime lastDate;

  /// The words over the field.
  final String? labelText;

  /// What the empty field says.
  final String hintText;

  /// Help under the field.
  final String? helperText;

  /// What is wrong, under the field in red.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// The calendar's style, over [BrutalThemeData.calendarStyle].
  final BrutalStyle? style;

  static String _span(RawWidgetsLocalizations words, BrutalDateRange r) {
    final a = r.start;
    final b = r.end;
    if (a.year == b.year && a.month == b.month) {
      return '${a.day} – ${b.day} ${words.formatMonthYear(b)}';
    }
    return '${a.day} ${words.formatMonthYear(a)} – '
        '${b.day} ${words.formatMonthYear(b)}';
  }

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final two = MediaQuery.sizeOf(context).width >= 600;
    final layers = [style, BrutalTheme.of(context).calendarStyle];
    return _labelled(
      RawPopover(
        semanticLabel: labelText,
        // The calendar opens where its whole month fits: below while below
        // holds it, else above; it shrinks and scrolls only where neither
        // side does.
        placement: const RawPopoverPlacement(
          gap: BrutalSpacing.small,
          margin: BrutalSpacing.small,
          matchAnchorWidth: false,
          fit: RawPopoverFit.whole,
        ),
        dampingRatio: BrutalMotion.dampingRatio,
        stiffness: BrutalMotion.overlayStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          text: value == null ? null : _span(words, value!),
          hint: hintText,
          icon: LucideIcons.calendarRange,
          enabled: enabled,
          error: errorText != null,
        ),
        overlayBuilder: (context, info) => _panel(
          context,
          info,
          layers,
          SizedBox(
            width: two ? 600 : 320,
            child: BrutalCalendar.range(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedRange: value,
              currentDate: currentDate,
              months: two ? 2 : 1,
              autofocus: true,
              style: style,
              onRangeChanged: (r) {
                info.close();
                onChanged?.call(r);
              },
            ),
          ),
        ),
      ),
      label: labelText,
      helper: helperText,
      error: errorText,
      enabled: enabled,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<BrutalDateRange>(
          'value',
          value,
          defaultValue: null,
        ),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<BrutalDateRange>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('hintText', hintText))
      ..add(StringProperty('helperText', helperText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<DateTime>(
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      )
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

// A wheel's row.
const double _wheelRow = 40;

/// Flat wheels, a column of each of [labels]' rows, on shared rules: rows
/// that scroll and snap, the middle one heavy between two rules. ui_core's
/// [RawPicker] turns them and gives each column its keys (Up and
/// Down, Page Up and Down, Home and End, a typed name, Left and Right to the
/// next column) and a screen reader's adjustable value, named [names]. A
/// column [widths] gives none of shares the room left.
///
/// Their rows keep their size at any text size, as Cupertino's wheels do
/// (a row's pitch is the wheel's, and a larger figure would cut its
/// neighbours).
///
/// The wheels win a drag that starts on them, the page under them keeps
/// still: the rule between two columns is shared, half of it in each
/// column's reach (the later column draws it whole), and a mouse turns them
/// as a finger does.
Widget _wheels(
  BuildContext context, {
  required List<List<String>> labels,
  required List<String?> names,
  required List<double?> widths,
  required List<int> selection,
  required ValueChanged<List<int>>? onChanged,
  required List<BrutalStyle?> layers,
  required int rows,
  String? semanticLabel,
}) {
  final theme = BrutalTheme.of(context);
  final c = theme.colors;
  final enabled = onChanged != null;
  final box = DesignStyleOf(layers, const {});
  final rule = enabled ? box.side?.color ?? box.edge ?? c.ink : c.disabled;
  final half = theme.borderWidth / 2;
  final last = labels.length - 1;
  // What of a column the rules stand over: half a rule at a side with a
  // neighbour.
  EdgeInsetsDirectional ruled(int i) => EdgeInsetsDirectional.only(
    start: i > 0 ? half : 0,
    end: i < last ? half : 0,
  );
  // A mouse drag turns a wheel too (a scrollable takes none by default).
  final behavior = ScrollConfiguration.of(context);
  return MediaQuery.withNoTextScaling(
    child: ScrollConfiguration(
      behavior: behavior.copyWith(
        dragDevices: {...behavior.dragDevices, PointerDeviceKind.mouse},
      ),
      child: RawPicker(
        columns: (_) => [
          for (final (i, column) in labels.indexed)
            RawPickerColumn(
              itemCount: column.length,
              itemLabel: (row) => column[row],
              semanticLabel: names[i],
            ),
        ],
        selection: selection,
        onChanged: onChanged,
        itemExtent: _wheelRow,
        visibleItemCount: rows,
        // Flat: no lean and no squeeze, as a list of rows on a page.
        diameterRatio: 1000,
        squeeze: 1,
        semanticLabel: semanticLabel,
        dampingRatio: BrutalMotion.dampingRatio,
        stiffness: BrutalMotion.moveStiffness,
        itemBuilder: (context, row) {
          final layered = DesignStyleOf(layers, {
            if (!enabled) WidgetState.disabled,
          });
          return Padding(
            // Clear of the rules beside the column.
            padding: ruled(row.column),
            child: Center(
              child: Text(
                row.label,
                maxLines: 1,
                style: layered
                    .text(theme.textTheme.label)
                    .copyWith(
                      fontSize: row.selected ? 20 : 16,
                      fontWeight: row.selected
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: !enabled
                          ? c.disabled
                          : row.selected
                          ? layered.foreground ?? c.ink
                          : c.inkMuted,
                    ),
              ),
            ),
          );
        },
        columnBuilder: (context, column, wheel) {
          final layered = DesignStyleOf(layers, column.states);
          final band = enabled
              ? layered.side?.color ?? layered.edge ?? c.ink
              : c.disabled;
          // A rule between two columns is half in each one's reach, so a drag
          // on it turns a wheel; the later column draws it whole, over the
          // half before its start. What a column paints stands clear of it.
          final inset = ruled(column.column);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              // The chosen row's band: two heavy rules.
              Positioned.fill(
                child: Padding(
                  padding: inset,
                  child: Center(
                    child: SizedBox(
                      height: column.itemExtent,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.symmetric(
                            horizontal: BorderSide(
                              color: band,
                              width: theme.borderWidth,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              wheel,
              if (column.column > 0)
                PositionedDirectional(
                  start: -half,
                  top: 0,
                  bottom: 0,
                  width: theme.borderWidth,
                  child: IgnorePointer(child: ColoredBox(color: rule)),
                ),
              if (column.states.contains(WidgetState.focused))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Padding(
                      padding: inset,
                      child: CustomPaint(
                        painter: BrutalInsetFocusPainter(c.ink),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
        layoutBuilder: (context, columns) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (i, column) in columns.indexed)
              if (widths[i] case final width?)
                SizedBox(width: width + ruled(i).horizontal, child: column)
              else
                Expanded(child: column),
          ],
        ),
      ),
    ),
  );
}

/// A flat wheel of [items] in a ruled box: rows that scroll and snap, the
/// chosen one heavy between two rules. The wheel is ui_core's
/// ([RawPicker]): Up and Down move it from the keyboard, Page Up and
/// Down by five, Home and End to the ends, and typing goes to the next item
/// starting with the letters; a key or a new [value] turns it on a spring. A
/// screen reader hears an adjustable value.
///
/// Reads [style]'s `fill` (the box), `edge` (its rule and the band's),
/// `foreground` (the chosen row) and `textStyle` (the rows' family and
/// spacing; the sizes stay), then [BrutalThemeData.wheelPickerStyle]'s.
///
/// ```dart
/// BrutalWheelPicker<int>(items: const [1, 2, 3, 4, 5, 6], value: count, labelOf: (n) => '$n', semanticLabel: 'Tickets', onChanged: (n) => setState(() => count = n))
/// ```
class BrutalWheelPicker<T> extends StatelessWidget {
  /// A wheel over [items].
  const BrutalWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.semanticLabel,
    this.visibleRows = 5,
    this.width = 160,
    this.style,
  });

  /// What may be chosen, top to bottom.
  final List<T> items;

  /// The one chosen.
  final T value;

  /// Called as the wheel settles on another; null disables it.
  final ValueChanged<T>? onChanged;

  /// Each item's words.
  final String Function(T item) labelOf;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How many rows show.
  final int visibleRows;

  /// Its width.
  final double width;

  /// Its style, over [BrutalThemeData.wheelPickerStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final layers = [style, theme.wheelPickerStyle];
    final box = DesignStyleOf(layers, const {});
    return Align(
      alignment: AlignmentDirectional.centerStart,
      widthFactor: 1,
      heightFactor: 1,
      child: SizedBox(
        width: width,
        child: BrutalSurface(
          face: BrutalFace(
            fill: box.fill ?? c.surface,
            border: onChanged == null
                ? c.disabled
                : box.side?.color ?? box.edge ?? c.ink,
            foreground: c.ink,
          ),
          child: _wheels(
            context,
            labels: [
              [for (final i in items) labelOf(i)],
            ],
            names: [semanticLabel],
            widths: const [null],
            selection: [items.indexOf(value).clamp(0, items.length - 1)],
            onChanged: onChanged == null
                ? null
                : (picked) => onChanged!(items[picked.first]),
            rows: visibleRows,
            layers: layers,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<T>('items', items))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(ObjectFlagProperty<String Function(T item)>.has('labelOf', labelOf))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(IntProperty('visibleRows', visibleRows))
      ..add(DoubleProperty('width', width))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A time of day as two flat wheels on a shared rule, hours and minutes
/// (every [minuteInterval] minutes), on a 24-hour clock.
///
/// Reads [style] as [BrutalWheelPicker] does, then
/// [BrutalThemeData.wheelPickerStyle].
///
/// ```dart
/// BrutalTimePicker(value: const BrutalTime(hour: 19, minute: 30), onChanged: (t) => setState(() => doors = t))
/// ```
class BrutalTimePicker extends StatelessWidget {
  /// A time picker at [value].
  const BrutalTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.semanticLabel,
    this.style,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0);

  /// The time.
  final BrutalTime value;

  /// Called as either wheel settles; null disables it.
  final ValueChanged<BrutalTime>? onChanged;

  /// The minutes' step.
  final int minuteInterval;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [BrutalThemeData.wheelPickerStyle].
  final BrutalStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    final layers = [style, theme.wheelPickerStyle];
    final box = DesignStyleOf(layers, const {});
    final rule = enabled ? box.side?.color ?? box.edge ?? c.ink : c.disabled;
    // The wheels' spoken names, in the reader's language.
    final words = RawWidgetsLocalizations.of(context);
    final minutes = [for (var m = 0; m < 60; m += minuteInterval) m];
    String two(int n) => n.toString().padLeft(2, '0');
    final nearest = minutes.lastWhere(
      (m) => m <= value.minute,
      orElse: () => 0,
    );
    return Semantics(
      container: true,
      label: semanticLabel,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        widthFactor: 1,
        heightFactor: 1,
        child: BrutalSurface(
          face: BrutalFace(
            fill: box.fill ?? c.surface,
            border: rule,
            foreground: c.ink,
          ),
          child: _wheels(
            context,
            labels: [
              [for (var h = 0; h < 24; h++) two(h)],
              [for (final m in minutes) two(m)],
            ],
            names: [words.timePickerHourLabel, words.timePickerMinuteLabel],
            widths: const [88, 88],
            selection: [value.hour, minutes.indexOf(nearest)],
            onChanged: enabled
                ? (picked) => onChanged!(
                    BrutalTime(hour: picked[0], minute: minutes[picked[1]]),
                  )
                : null,
            rows: 5,
            layers: layers,
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<BrutalTime>('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<BrutalTime>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(IntProperty('minuteInterval', minuteInterval))
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

/// A colour: a ruled field of its brightness and saturation for the hue,
/// a ruled hue track under it, and a cell of the colour beside its code.
/// Each thumb is a small square in an ink and a paper rule. The arrows move
/// the thumbs.
///
/// Reads [style]'s `edge` (every rule), `fill` (the ground under the
/// tracks) and `textStyle` (the code), then
/// [BrutalThemeData.colorPickerStyle]'s.
///
/// ```dart
/// BrutalColorPicker(value: tint, onChanged: (c) => setState(() => tint = c))
/// ```
class BrutalColorPicker extends StatefulWidget {
  /// A colour picker at [value].
  const BrutalColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
    this.style,
  });

  /// The colour.
  final Color value;

  /// Called as it changes.
  final ValueChanged<Color> onChanged;

  /// Whether it has an opacity track.
  final bool showAlpha;

  /// Its style, over [BrutalThemeData.colorPickerStyle].
  final BrutalStyle? style;

  @override
  State<BrutalColorPicker> createState() => _BrutalColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('value', value))
      ..add(ObjectFlagProperty<ValueChanged<Color>>.has('onChanged', onChanged))
      ..add(FlagProperty('showAlpha', value: showAlpha, ifTrue: 'showAlpha'))
      ..add(
        DiagnosticsProperty<BrutalStyle>('style', style, defaultValue: null),
      );
  }
}

class _BrutalColorPickerState extends State<BrutalColorPicker> {
  late final RawColorController _controller = RawColorController(widget.value)
    ..addListener(_changed);

  void _changed() {
    if (_controller.color != widget.value) {
      widget.onChanged(_controller.color);
    }
  }

  @override
  void didUpdateWidget(BrutalColorPicker old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.color) {
      _controller.value = HSVColor.fromColor(widget.value);
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_changed)
      ..dispose();
    super.dispose();
  }

  Widget _thumb(
    BrutalColors c,
    double w,
    Set<WidgetState> states,
    Color fill,
  ) => Center(
    child: SizedBox.square(
      dimension: 20,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill,
          border: Border.all(color: c.ink, width: w),
          boxShadow: [
            BoxShadow(color: c.paper, spreadRadius: w),
            if (states.contains(WidgetState.focused))
              BoxShadow(
                color: c.ink,
                spreadRadius: w + BrutalMetrics.focusWidth,
              ),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = BrutalTheme.of(context);
    final c = theme.colors;
    final w = theme.borderWidth;
    final layered = DesignStyleOf([
      widget.style,
      theme.colorPickerStyle,
    ], const {});
    final rule = layered.side?.color ?? layered.edge ?? c.ink;
    Widget ruled(Widget child) => BrutalSurface(
      face: BrutalFace(
        fill: layered.fill ?? c.surface,
        border: rule,
        foreground: c.ink,
      ),
      child: child,
    );
    return RawColorPicker(
      controller: _controller,
      showAlpha: widget.showAlpha,
      areaHeight: 180,
      areaBuilder: (context, area) => ruled(
        CustomPaint(painter: _AreaPainter(area.color.hue), size: Size.infinite),
      ),
      areaThumbBuilder: (context, area) =>
          _thumb(c, w, area.states, area.color.toColor()),
      trackBuilder: (context, channel, color) => Center(
        child: SizedBox(
          height: 16,
          child: ruled(
            CustomPaint(
              painter: _TrackPainter(channel, color),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      thumbBuilder: (context, states) =>
          _thumb(c, w, states, _controller.color.withValues(alpha: 1)),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: BrutalSpacing.small),
            part,
          ],
          const SizedBox(height: BrutalSpacing.small),
          ValueListenableBuilder<HSVColor>(
            valueListenable: _controller,
            builder: (context, hsv, _) => Row(
              children: [
                SizedBox.square(
                  dimension: theme.controlHeight,
                  child: BrutalSurface(
                    face: BrutalFace(
                      fill: hsv.toColor(),
                      border: rule,
                      foreground: c.ink,
                    ),
                  ),
                ),
                const SizedBox(width: BrutalSpacing.medium),
                Text(
                  _controller.hex,
                  style: layered
                      .text(theme.textTheme.label)
                      .copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AreaPainter extends CustomPainter {
  _AreaPainter(this.hue);

  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pure = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(colors: [const Color(0xFFFFFFFF), pure])
              .createShader(rect),
      )
      ..drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x00000000), Color(0xFF000000)],
          ).createShader(rect),
      );
  }

  @override
  bool shouldRepaint(_AreaPainter old) => old.hue != hue;
}

class _TrackPainter extends CustomPainter {
  _TrackPainter(this.channel, this.color);

  final RawColorChannel channel;
  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = channel == RawColorChannel.hue
        ? [
            for (var h = 0; h <= 360; h += 60)
              HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
          ]
        : [color.withAlpha(0).toColor(), color.withAlpha(1).toColor()];
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.channel != channel || old.color != color;
}
