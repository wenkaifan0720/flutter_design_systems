/// Studio's pickers, each read off glass or set with metal: [StudioCalendar]
/// (a month on a glass panel, the chosen day lit in a slot),
/// [StudioDatePicker] and [StudioDateRangePicker] (a window that opens one),
/// [StudioWheelPicker] and [StudioTimePicker] (thumbwheel drums behind a
/// readout window), [StudioColorPicker], [StudioRangeFader] (a fader with two
/// caps), [StudioChip], [StudioRating] (a row of lamps) and [StudioFileDrop]
/// (a tray to drop files on).
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kTouchSlop;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'internal/control_light.dart';

import 'button.dart';
import 'controls.dart';
import 'internal/focus_light.dart';
import 'select.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

Color _ring(StudioColors c, Set<WidgetState> states) =>
    states.contains(WidgetState.focused)
    ? c.focusRing
    : c.focusRing.withValues(alpha: 0);

List<Shadow>? _glow(Color light, bool on) =>
    on ? [Shadow(color: light.withValues(alpha: 0.5), blurRadius: 6)] : null;

/// A span of days, [start] to [end], both in it.
///
/// ```dart
/// StudioDateRange(start: DateTime(2026, 11, 14), end: DateTime(2026, 11, 16))
/// ```
@immutable
class StudioDateRange {
  /// The days from [start] to [end].
  const StudioDateRange({required this.start, required this.end});

  /// Its first day.
  final DateTime start;

  /// Its last day.
  final DateTime end;

  @override
  bool operator ==(Object other) =>
      other is StudioDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'StudioDateRange($start – $end)';
}

/// A time of day, on a 24-hour clock.
///
/// ```dart
/// const StudioTime(hour: 19, minute: 30)
/// ```
@immutable
class StudioTime {
  /// [hour]:[minute].
  const StudioTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// 0 to 23.
  final int hour;

  /// 0 to 59.
  final int minute;

  /// As a readout shows it: `19:30`.
  String get readout =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is StudioTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'StudioTime($readout)';
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A month on a glass panel: the month's name and two small keys to turn
/// it over the weekdays' print, the days' figures under them. The chosen
/// day sits in a slot pressed into the glass with its figure lit; today
/// has a small lamp under its figure. [StudioCalendar.range] takes a first
/// and a last day, the days between lit dimmer on one band.
///
/// Built on ui_core's RawCalendarDatePicker: the arrows walk the days, Page Up and
/// Page Down the months, Enter takes a day. A null callback disables it.
///
/// Reads [style]'s `fill` (the glass), then [StudioThemeData.calendarStyle].
///
/// ```dart
/// StudioCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), selectedDate: day, onDateChanged: (d) => setState(() => day = d))
/// ```
class StudioCalendar extends StatefulWidget {
  /// A calendar that takes one day.
  const StudioCalendar({
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

  /// A calendar that takes a span of days, over [months] months side by
  /// side.
  const StudioCalendar.range({
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

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The chosen day.
  final DateTime? selectedDate;

  /// Called with the day taken; null disables it.
  final ValueChanged<DateTime>? onDateChanged;

  /// The chosen span.
  final StudioDateRange? selectedRange;

  /// Called with a span once its last day is taken; null disables it.
  final ValueChanged<StudioDateRange>? onRangeChanged;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// Whether a day may be taken.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// How many months show side by side.
  final int months;

  /// {@macro design.autofocus}
  final bool autofocus;

  /// Its style, over [StudioThemeData.calendarStyle].
  final StudioStyle? style;

  final bool _range;

  @override
  State<StudioCalendar> createState() => _StudioCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('selectedDate', selectedDate))
      ..add(
        DiagnosticsProperty<StudioDateRange>('selectedRange', selectedRange),
      )
      ..add(FlagProperty('range', value: _range, ifTrue: 'range'));
  }
}

// A day's row grows with its figure at large text, never under 40, nor under
// a finger's floor where a finger reaches it.
double _dayHeight(BuildContext context) => math.max(
  math.max(40.0, DesignTapTargets.of(context).floorOn().height),
  MediaQuery.textScalerOf(context).scale(15) * 20 / 15 + 12,
);

class _StudioCalendarState extends State<StudioCalendar> {
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
  void didUpdateWidget(StudioCalendar old) {
    super.didUpdateWidget(old);
    final rebuilt =
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old._range != widget._range ||
        (old.onDateChanged == null) != (widget.onDateChanged == null) ||
        (old.onRangeChanged == null) != (widget.onRangeChanged == null);
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
      widget.onRangeChanged?.call(StudioDateRange(start: r.start, end: r.end!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final t = theme.textTheme;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layers = [widget.style, theme.calendarStyle];
    final frame = DesignStyleOf(layers, const {});
    final dayHeight = _dayHeight(context);
    final night = c.brightness == Brightness.dark;
    Widget turn(IconData icon, String label, VoidCallback? onPressed) =>
        ExcludeSemantics(
          excluding: false,
          child: StudioIconButton(
            icon: Transform.flip(flipX: rtl, child: Icon(icon)),
            tooltip: label,
            onPressed: onPressed,
          ),
        );
    final body = Padding(
      padding: const EdgeInsets.all(StudioSpacing.small),
      child: RawCalendarDatePicker(
        controller: _controller,
        months: widget.months,
        autofocus: widget.autofocus,
        onChanged: _changed,
        headerBuilder: (context, header) => Padding(
          padding: const EdgeInsets.only(bottom: StudioSpacing.small),
          child: Row(
            children: [
              turn(
                LucideIcons.chevronLeft,
                words.previousMonthTooltip,
                header.previous,
              ),
              Expanded(
                child: Center(
                  child: Text(
                    header.label,
                    maxLines: 1,
                    style: t.label.copyWith(
                      color: c.onDisplay,
                      fontWeight: FontWeight.w600,
                    ),
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
        ),
        weekdayBuilder: (context, weekday, label) => SizedBox(
          height: 28,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: t.caption.copyWith(
                color: c.onDisplayMuted,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        dayBuilder: (context, day, states) {
          final pressed = states.contains(WidgetState.pressed);
          final focused = states.contains(WidgetState.focused);
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
          // A chosen day is lit in its slot: by day the slot glows amber
          // under a dark figure, by night its figure glows amber in the
          // dark glass. Both read at 4.5:1 and more.
          final lit = end && day.enabled;
          final Color figures;
          if (!day.enabled) {
            figures = end ? c.onDisplayMuted : c.disabled;
          } else if (end) {
            figures = night ? c.indicator : c.onIndicator;
          } else if (middle) {
            figures = night
                ? Color.lerp(c.onDisplay, c.indicator, 0.6)!
                : c.onDisplay;
          } else {
            figures = day.inMonth
                ? layered.foreground ?? c.onDisplay
                : c.onDisplayMuted;
          }
          final band = ColoredBox(
            color: Color.lerp(c.displayLow, c.shadow, 0.05)!,
          );
          // The span's band runs from one end's slot to the other's: whole
          // under a day inside it, half under an end, toward the span.
          final Widget? span = !widget._range || !(day.inRange || day.inPreview)
              ? null
              : middle
              ? band
              : day.isRangeStart && (day.isRangeEnd || day.isPreviewEnd)
              ? null
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: day.isRangeStart
                      ? [const Spacer(), Expanded(child: band)]
                      : [Expanded(child: band), const Spacer()],
                );
          return SizedBox(
            height: dayHeight,
            child: Stack(
              children: [
                if (span != null)
                  Positioned.fill(top: 3, bottom: 3, child: span),
                // A day's slot keeps a key's proportions however wide the
                // month is spread.
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, room) => Center(
                      child: SizedBox(
                        width: math.min(room.maxWidth, dayHeight + 12),
                        height: room.maxHeight,
                        child: Padding(
                          padding: const EdgeInsets.all(StudioSpacing.hair),
                          child: StudioFocusLight(
                            edge: focused
                                ? c.focusRing
                                : c.focusRing.withValues(alpha: 0),
                            radius: StudioRadii.small,
                            child: AnimatedStudioSurface(
                              stiffness: StudioMotion.lampStiffness,
                              face: StudioFace(
                                fill: lit
                                    ? Color.lerp(
                                        c.display,
                                        c.indicator,
                                        night ? 0.08 : 0.42,
                                      )!
                                    : Color.lerp(c.displayLow, c.shadow, 0.06)!,
                                fillLow: lit
                                    ? Color.lerp(
                                        c.displayLow,
                                        c.indicator,
                                        night ? 0.04 : 0.3,
                                      )!
                                    : Color.lerp(c.display, c.shadow, 0.03)!,
                                depth: StudioDepth.sunk,
                                radius: StudioRadii.small,
                                rim: c.indicator.withValues(
                                  alpha: lit && !night && !focused ? 0.75 : 0,
                                ),
                                presence: end || pressed || focused ? 1 : 0,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        words.formatDecimal(day.date.day),
                                        maxLines: 1,
                                        softWrap: false,
                                        style: layered
                                            .text(
                                              t.readout.copyWith(
                                                fontSize: 15,
                                                height: 20 / 15,
                                              ),
                                            )
                                            .copyWith(
                                              color: figures,
                                              fontWeight: end || day.isToday
                                                  ? FontWeight.w700
                                                  : FontWeight.w500,
                                              shadows: _glow(
                                                figures,
                                                lit && night,
                                              ),
                                            ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 4,
                                    child: day.isToday
                                        ? StudioLamp(on: !end, size: 4)
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
    // In a date field's popover the bezel is its glass: one frame.
    if (context.getInheritedWidgetOfExactType<_InPopover>() != null) {
      return frame.fill == null
          ? body
          : DecoratedBox(
              decoration: BoxDecoration(
                color: frame.fill,
                borderRadius: BorderRadius.circular(
                  StudioRadii.bank - StudioMetrics.recessInset,
                ),
              ),
              child: body,
            );
    }
    return StudioSurface(
      face: c.displayFace.copyWith(radius: StudioRadii.bank, fill: frame.fill),
      child: body,
    );
  }
}

// Marks a calendar inside a date field's popover, which frames it.
class _InPopover extends InheritedWidget {
  const _InPopover({required super.child});

  @override
  bool updateShouldNotify(_InPopover old) => false;
}

// The window a date or time picker shows its value in: StudioSelect's
// window, a glyph at its end, its rim lit while its panel is open.
class _PickerWindow extends StatelessWidget {
  const _PickerWindow({
    required this.anchor,
    required this.text,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.error,
    required this.semanticLabel,
  });

  final DesignOverlayAnchor? anchor;
  final String? text;
  final String hint;
  final IconData icon;
  final bool enabled;
  final bool error;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final open = anchor?.isOpen ?? false;
    return RawButton(
      onPressed: anchor?.toggle,
      expanded: anchor?.isOpen,
      semanticLabel: semanticLabel,
      semanticValue: text,
      excludeSemantics: true,
      builder: (context, states, _) {
        final pressed = enabled && states.contains(WidgetState.pressed);
        final hovered = enabled && states.contains(WidgetState.hovered);
        final now = {...states, if (open) WidgetState.focused};
        final layered = DesignStyleOf([theme.textFieldStyle], now);
        final face = layered.on(
          c.displayFace.copyWith(
            radius: StudioRadii.key,
            // Focused, the light round the window is its one edge.
            rim: error
                ? c.danger
                : c.indicator.withValues(
                    alpha: states.contains(WidgetState.focused)
                        ? 0
                        : open || pressed
                        ? 0.9
                        : hovered
                        ? 0.45
                        : 0,
                  ),
            fill: !enabled
                ? Color.lerp(c.display, c.panelLow, 0.4)
                : pressed
                ? Color.lerp(c.display, c.indicator, 0.18)
                : hovered
                ? Color.lerp(c.display, c.indicator, 0.06)
                : null,
          ),
        );
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: theme.controlHeight),
          // Focused, the window's edge lights amber: no ring round it.
          child: StudioFocusLight(
            edge: _ring(c, states),
            radius: face.radius,
            child: AnimatedStudioSurface(
              face: face,
              stiffness: StudioMotion.lampStiffness,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: StudioSpacing.medium + 2,
                  end: StudioSpacing.medium,
                  top: StudioSpacing.tight,
                  bottom: StudioSpacing.tight,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: DesignCapCenter(
                        capHeightFactor: theme.capHeightFactor,
                        child: Text(
                          text ?? hint,
                          style: theme.textTheme.body.copyWith(
                            color: !enabled
                                ? c.onDisplayMuted
                                : text == null
                                ? c.onDisplayMuted
                                : c.onDisplay,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: StudioSpacing.small),
                    Icon(
                      icon,
                      size: StudioIconSizes.medium,
                      color: !enabled
                          ? c.disabled
                          : open
                          ? c.litLegend
                          : c.onDisplayMuted,
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
}

Widget _labelled(
  Widget box, {
  String? label,
  String? helper,
  String? error,
  required bool enabled,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (label != null)
      ExcludeSemantics(child: StudioFieldLabel(label, enabled: enabled)),
    box,
    StudioFieldMessage(helper: helper, error: error),
  ],
);

// A calendar's popover under its field. It opens on the side with room for
// a whole month (its header, weekdays and six weeks at the reader's text
// size) and scrolls when neither side has that much.
RawPopoverPlacement _calendarPlacement(BuildContext context) =>
    RawPopoverPlacement(
      gap: StudioSpacing.tight,
      margin: StudioSpacing.small,
      matchAnchorWidth: false,
      preferredExtent:
          StudioTheme.of(context).controlHeight +
          28 +
          6 * _dayHeight(context) +
          3 * StudioSpacing.small +
          2 * StudioMetrics.recessInset,
    );

// The least width a month needs: seven 40 px days inside the bezel.
const double _calendarFloor =
    7 * 40 + 2 * (StudioSpacing.small + StudioMetrics.recessInset);

// The widest a month spreads: seven days at a key's widest slot inside the
// bezel (about 390 px, more as the text grows), so the week still scans.
double _calendarCap(BuildContext context) =>
    7 * (_dayHeight(context) + 12) +
    2 * (StudioSpacing.small + StudioMetrics.recessInset);

// A calendar's popover: as wide as its field, edge to edge, up to a month's
// comfortable width; under a narrower field it keeps a month's width, and
// under a wider one the comfortable width, from the field's leading edge.
// Never wider than the screen allows.
Widget _panel(BuildContext context, RawPopoverInfo info, Widget child) =>
    FadeTransition(
      opacity: info.animation,
      child: SizedBox(
        width: math.min(
          info.maxSize.width,
          info.anchorRect.width.clamp(_calendarFloor, _calendarCap(context)),
        ),
        child: StudioListBezel(
          child: _InPopover(child: SingleChildScrollView(child: child)),
        ),
      ),
    );

/// A date field: a glass window showing the chosen day (or [hint]) with a
/// calendar glyph at its end; a press opens a [StudioCalendar] under it,
/// and taking a day closes it.
///
/// A null [onChanged] disables it.
///
/// ```dart
/// StudioDatePicker(label: 'Release date', value: day, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (d) => setState(() => day = d))
/// ```
class StudioDatePicker extends StatelessWidget {
  /// A date field at [value].
  const StudioDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint = 'Choose a day',
    this.helper,
    this.error,
    this.currentDate,
    this.style,
  });

  /// The chosen day.
  final DateTime? value;

  /// Called with the day taken; null disables it.
  final ValueChanged<DateTime>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The label above it.
  final String? label;

  /// What it says while empty.
  final String hint;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// The calendar's style.
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final text = value == null ? null : words.formatFullDate(value!);
    return _labelled(
      !enabled
          ? _PickerWindow(
              anchor: null,
              text: text,
              hint: hint,
              icon: LucideIcons.calendar,
              enabled: false,
              error: error != null,
              semanticLabel: label,
            )
          : RawPopover(
              semanticLabel: label,
              placement: _calendarPlacement(context),
              dampingRatio: StudioMotion.dampingRatio,
              stiffness: StudioMotion.overlayStiffness,
              anchorBuilder: (context, anchor) => _PickerWindow(
                anchor: anchor,
                text: text,
                hint: hint,
                icon: LucideIcons.calendar,
                enabled: true,
                error: error != null,
                semanticLabel: label,
              ),
              overlayBuilder: (context, info) => _panel(
                context,
                info,
                StudioCalendar(
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
      label: label,
      helper: helper,
      error: error,
      enabled: enabled,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// A span field: a glass window showing the first and last days (or
/// [hint]); a press opens a range [StudioCalendar] under it, which closes
/// once the last day is taken.
///
/// A null [onChanged] disables it.
///
/// ```dart
/// StudioDateRangePicker(label: 'Recording days', value: span, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (r) => setState(() => span = r))
/// ```
class StudioDateRangePicker extends StatelessWidget {
  /// A span field at [value].
  const StudioDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint = 'Choose the days',
    this.helper,
    this.error,
    this.currentDate,
    this.style,
  });

  /// The chosen span.
  final StudioDateRange? value;

  /// Called with the span taken; null disables it.
  final ValueChanged<StudioDateRange>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The label above it.
  final String? label;

  /// What it says while empty.
  final String hint;

  /// A note under it.
  final String? helper;

  /// What is wrong, under it.
  final String? error;

  /// Today; the clock's when null.
  final DateTime? currentDate;

  /// The calendar's style.
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final text = value == null
        ? null
        : '${words.formatFullDate(value!.start)} – '
              '${words.formatFullDate(value!.end)}';
    return _labelled(
      !enabled
          ? _PickerWindow(
              anchor: null,
              text: text,
              hint: hint,
              icon: LucideIcons.calendarRange,
              enabled: false,
              error: error != null,
              semanticLabel: label,
            )
          : RawPopover(
              semanticLabel: label,
              placement: _calendarPlacement(context),
              dampingRatio: StudioMotion.dampingRatio,
              stiffness: StudioMotion.overlayStiffness,
              anchorBuilder: (context, anchor) => _PickerWindow(
                anchor: anchor,
                text: text,
                hint: hint,
                icon: LucideIcons.calendarRange,
                enabled: true,
                error: error != null,
                semanticLabel: label,
              ),
              overlayBuilder: (context, info) => _panel(
                context,
                info,
                StudioCalendar.range(
                  firstDate: firstDate,
                  lastDate: lastDate,
                  selectedRange: value,
                  currentDate: currentDate,
                  autofocus: true,
                  style: style,
                  onRangeChanged: (r) {
                    info.close();
                    onChanged?.call(r);
                  },
                ),
              ),
            ),
      label: label,
      helper: helper,
      error: error,
      enabled: enabled,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<StudioDateRange>(
          'value',
          value,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

// A drum's row, and how many rows show through the housing.
const double _drumRow = 36;
const int _drumRows = 5;

// Studio's thumbwheel drums on ui_core's wheel picker: the labels on a drum
// turning behind the window, the row in the window lit, the drum's curve
// fading its rows into the housing above and below the window. A drum with
// the keyboard lights its window's rim.
Widget _drums(
  BuildContext context, {
  required List<RawPickerColumn> columns,
  required List<int> selection,
  required ValueChanged<List<int>>? onChanged,
  required double width,
  String? semanticLabel,
  Widget Function(BuildContext context, List<Widget> columns)? layout,
}) {
  final theme = StudioTheme.of(context);
  final c = theme.colors;
  final enabled = onChanged != null;
  return RawPicker(
    columns: (_) => columns,
    selection: selection,
    onChanged: onChanged,
    itemExtent: _drumRow,
    visibleItemCount: _drumRows,
    // The drum's shape as it was: a wide drum, its outer rows leaning back.
    diameterRatio: 1.4,
    perspective: 0.004,
    squeeze: 1,
    dampingRatio: StudioMotion.dampingRatio,
    stiffness: StudioMotion.moveStiffness,
    semanticLabel: semanticLabel,
    layoutBuilder:
        layout ??
        (context, columns) =>
            Row(mainAxisSize: MainAxisSize.min, children: columns),
    itemBuilder: (context, row) {
      final here = row.selected;
      final light = !enabled || !row.enabled
          ? c.disabled
          : here
          ? c.readoutLit
          : c.onReadout.withValues(alpha: 0.55);
      return Center(
        child: Text(
          row.label,
          maxLines: 1,
          style: theme.textTheme.readout.copyWith(
            fontSize: here ? 20 : 17,
            color: light,
            shadows: c.litReadout ? null : _glow(light, here && enabled),
          ),
        ),
      );
    },
    columnBuilder: (context, column, wheel) {
      final focused =
          column.states.contains(WidgetState.focused) &&
          FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
      return SizedBox(
        width: width,
        height: _drumRow * _drumRows,
        child: Stack(
          children: [
            // The window's slot across the middle, its rim lit while the
            // drum has the keyboard.
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  height: _drumRow,
                  child: AnimatedStudioSurface(
                    stiffness: StudioMotion.lampStiffness,
                    face: StudioFace(
                      fill: Color.lerp(c.readout, c.shadow, 0.1)!,
                      fillLow: c.readout,
                      depth: StudioDepth.sunk,
                      radius: StudioRadii.small,
                      focus: focused
                          ? c.focusRing
                          : c.focusRing.withValues(alpha: 0),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
              ),
            ),
            // The drum's curve: its rows fade away into the housing above
            // and below the window. The rows fade, not the housing: its wall
            // and its lip's shade stay whole.
            Positioned.fill(
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0xFF000000),
                    Color(0xFF000000),
                    Color(0x00000000),
                  ],
                  stops: [0, 0.32, 0.68, 1],
                ).createShader(bounds),
                child: wheel,
              ),
            ),
          ],
        ),
      );
    },
  );
}

// The dark housing a drum or two turn in.
Widget _housing(StudioColors c, Widget child) => StudioSurface(
  face: c.readoutFace.copyWith(radius: StudioRadii.bank),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(StudioRadii.bank),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.small),
      child: child,
    ),
  ),
);

/// A thumbwheel: a drum of [items] turning behind a dark readout window,
/// the one in the window lit in the indicator. Drag or flick it; it
/// settles on a row. The arrows step it while it has the keyboard; a screen
/// reader steps it as a value.
///
/// A null [onChanged] disables it.
///
/// ```dart
/// StudioWheelPicker<int>(items: const [1, 2, 3, 4], value: takes, labelOf: (n) => '$n', semanticLabel: 'Takes', onChanged: (n) => setState(() => takes = n))
/// ```
class StudioWheelPicker<T> extends StatelessWidget {
  /// A wheel at [value].
  const StudioWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.semanticLabel,
    this.width = 120,
  });

  /// What it offers, in order.
  final List<T> items;

  /// The one in the window.
  final T value;

  /// Called as it settles; null disables it.
  final ValueChanged<T>? onChanged;

  /// Each item's words.
  final String Function(T item) labelOf;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    final change = onChanged;
    return _housing(
      c,
      _drums(
        context,
        columns: [
          RawPickerColumn(
            itemCount: items.length,
            itemLabel: (i) => labelOf(items[i]),
            semanticLabel: semanticLabel,
          ),
        ],
        selection: [math.max(0, items.indexOf(value))],
        width: width,
        onChanged: change == null ? null : (s) => change(items[s.first]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(IntProperty('items', items.length));
  }
}

/// A time: two thumbwheels, the hours and the minutes, in one dark housing
/// with a lit colon between them, on a 24-hour clock. [minuteInterval]
/// steps the minutes. The hours stand on the left in either direction, as a
/// clock reads, and the arrows and Tab follow them.
///
/// A null [onChanged] disables it.
///
/// ```dart
/// StudioTimePicker(value: const StudioTime(hour: 19, minute: 30), onChanged: (t) => setState(() => start = t))
/// ```
class StudioTimePicker extends StatelessWidget {
  /// A time picker at [value].
  const StudioTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.semanticLabel,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0);

  /// The time.
  final StudioTime value;

  /// Called as either wheel settles; null disables it.
  final ValueChanged<StudioTime>? onChanged;

  /// The minutes' step.
  final int minuteInterval;

  /// What a screen reader calls it; each drum adds its own word, "Hour" or
  /// "Minute" in the reader's language.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    final minutes = [for (var m = 0; m < 60; m += minuteInterval) m];
    // Two figures in the reader's digits (Arabic-Indic in Arabic), and each
    // drum named in the reader's words: "Hour", "Minute", after the
    // picker's own name when it has one.
    final words = RawWidgetsLocalizations.of(context);
    String named(String drum) => semanticLabel == null
        ? drum
        : '$semanticLabel${words.listSeparator}$drum';
    String two(int n) => n < 10
        ? '${words.formatDecimal(0)}${words.formatDecimal(n)}'
        : words.formatDecimal(n);
    return _housing(
      c,
      // Hours then minutes, left to right, in a right-to-left language too,
      // as Material's time picker keeps them.
      Directionality(
        textDirection: TextDirection.ltr,
        child: _drums(
          context,
          semanticLabel: semanticLabel,
          columns: [
            RawPickerColumn(
              itemCount: 24,
              itemLabel: two,
              semanticLabel: named(words.timePickerHourLabel),
            ),
            RawPickerColumn(
              itemCount: minutes.length,
              itemLabel: (i) => two(minutes[i]),
              semanticLabel: named(words.timePickerMinuteLabel),
            ),
          ],
          selection: [value.hour, math.max(0, minutes.indexOf(value.minute))],
          width: 64,
          onChanged: change == null
              ? null
              : (s) => change(StudioTime(hour: s[0], minute: minutes[s[1]])),
          // The two drums with a lit colon between them.
          layout: (context, drums) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              drums[0],
              ExcludeSemantics(
                child: Text(
                  ':',
                  style: theme.textTheme.readout.copyWith(
                    fontSize: 20,
                    color: change == null ? c.disabled : c.readoutLit,
                    shadows: c.litReadout
                        ? null
                        : _glow(c.indicator, change != null),
                  ),
                ),
              ),
              drums[1],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<StudioTime>('value', value));
  }
}

/// A colour: a glass window of its brightness and saturation for the hue,
/// a slot of hues under it (and of opacity, with [showAlpha]), and a lens
/// of the colour beside its code in a readout. Each thumb is a small metal
/// ring. The arrows move the thumbs.
///
/// Built on ui_core's RawColorPicker.
///
/// ```dart
/// StudioColorPicker(value: tint, onChanged: (c) => setState(() => tint = c))
/// ```
class StudioColorPicker extends StatefulWidget {
  /// A colour picker at [value].
  const StudioColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
  });

  /// The colour.
  final Color value;

  /// Called as it changes.
  final ValueChanged<Color> onChanged;

  /// Whether it has an opacity slot.
  final bool showAlpha;

  @override
  State<StudioColorPicker> createState() => _StudioColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(ColorProperty('value', value));
  }
}

class _StudioColorPickerState extends State<StudioColorPicker> {
  late final RawColorController _controller = RawColorController(widget.value)
    ..addListener(_changed);

  void _changed() {
    if (_controller.color != widget.value) widget.onChanged(_controller.color);
  }

  @override
  void didUpdateWidget(StudioColorPicker old) {
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

  Widget _thumb(StudioColors c, Set<WidgetState> states, Color fill) => Center(
    child: SizedBox.square(
      dimension: 22,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(color: c.cap, width: 4),
          boxShadow: [
            BoxShadow(
              color: c.shadow.withValues(alpha: 0.5),
              blurRadius: 3,
              offset: const Offset(0, 1),
            ),
            if (states.contains(WidgetState.focused))
              BoxShadow(color: c.focusRing, spreadRadius: 3),
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    // The picture in its window is concentric with it: the window's radius
    // less the lip round it.
    const lip = StudioMetrics.recessInset - 1;
    Widget window(Widget child, double radius) => StudioSurface(
      face: c.recessFace.copyWith(radius: radius),
      child: Padding(
        padding: const EdgeInsets.all(lip),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius - lip),
          child: child,
        ),
      ),
    );
    return RawColorPicker(
      controller: _controller,
      showAlpha: widget.showAlpha,
      areaHeight: 180,
      areaBuilder: (context, area) => window(
        CustomPaint(painter: _AreaPainter(area.color.hue), size: Size.infinite),
        StudioRadii.key,
      ),
      areaThumbBuilder: (context, area) =>
          _thumb(c, area.states, area.color.toColor().withValues(alpha: 1)),
      trackBuilder: (context, channel, color) => Center(
        child: SizedBox(
          height: 16,
          child: window(
            CustomPaint(
              painter: _TrackPainter(channel, color, c.cap, c.capLow),
              size: Size.infinite,
            ),
            8,
          ),
        ),
      ),
      thumbBuilder: (context, states) =>
          _thumb(c, states, _controller.color.withValues(alpha: 1)),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: StudioSpacing.small),
            part,
          ],
          const SizedBox(height: StudioSpacing.medium),
          ValueListenableBuilder<HSVColor>(
            valueListenable: _controller,
            builder: (context, hsv, _) => Row(
              children: [
                SizedBox.square(
                  dimension: theme.controlHeight,
                  child: StudioSurface(
                    face: c.recessFace.copyWith(
                      radius: theme.controlHeight / 2,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(StudioMetrics.recessInset),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: hsv.toColor(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: StudioSpacing.medium),
                // At large text the readout steps down to fit beside the
                // swatch.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: StudioReadout(_controller.hex, minWidth: 104),
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
    canvas
      ..drawRect(
        rect,
        Paint()
          ..shader = LinearGradient(
            colors: [
              const Color(0xFFFFFFFF),
              HSVColor.fromAHSV(1, hue, 1, 1).toColor(),
            ],
          ).createShader(rect),
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
  _TrackPainter(this.channel, this.color, this.check, this.checkLow);

  final RawColorChannel channel;
  final HSVColor color;
  final Color check;
  final Color checkLow;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final List<Color> colors;
    switch (channel) {
      case RawColorChannel.hue:
        colors = [
          for (var h = 0; h <= 360; h += 60)
            HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
        ];
      case RawColorChannel.saturation:
        colors = [
          color.withSaturation(0).withAlpha(1).toColor(),
          color.withSaturation(1).withAlpha(1).toColor(),
        ];
      case RawColorChannel.brightness:
        colors = [
          const Color(0xFF000000),
          color.withValue(1).withAlpha(1).toColor(),
        ];
      case RawColorChannel.alpha:
        // A check under the opacity, so its fall reads.
        const cell = 4.0;
        for (var x = 0.0; x < size.width; x += cell) {
          for (var y = 0.0; y < size.height; y += cell) {
            final odd = ((x / cell).floor() + (y / cell).floor()).isOdd;
            canvas.drawRect(
              Rect.fromLTWH(x, y, cell, cell),
              Paint()..color = odd ? check : checkLow,
            );
          }
        }
        colors = [color.withAlpha(0).toColor(), color.withAlpha(1).toColor()];
    }
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.channel != channel ||
      old.color != color ||
      old.check != check ||
      old.checkLow != checkLow;
}

/// The two ends of a [StudioRangeFader].
///
/// ```dart
/// const StudioRangeValues(10, 40)
/// ```
@immutable
class StudioRangeValues {
  /// [start] to [end].
  const StudioRangeValues(this.start, this.end);

  /// The lower end.
  final double start;

  /// The upper end.
  final double end;

  @override
  bool operator ==(Object other) =>
      other is StudioRangeValues && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'StudioRangeValues($start, $end)';
}

/// A fader with two caps on one slot, the slot lit between them: a span
/// (a clip's in and out, a range of lengths). Drag either cap; the arrows
/// step the one with the keyboard. [startLabel] and [endLabel] name the
/// caps to a screen reader.
///
/// Built on ui_core's RawRangeSlider. A null [onChanged] disables it.
///
/// ```dart
/// StudioRangeFader(values: const StudioRangeValues(10, 40), max: 60, startLabel: 'Shortest', endLabel: 'Longest', onChanged: (v) => setState(() => lengths = v))
/// ```
class StudioRangeFader extends StatelessWidget {
  /// A range fader at [values].
  const StudioRangeFader({
    super.key,
    required this.values,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.divisions,
    this.startLabel,
    this.endLabel,
    this.semanticFormatter,
    this.style,
  });

  /// The span.
  final StudioRangeValues values;

  /// Called as a cap moves; null disables it.
  final ValueChanged<StudioRangeValues>? onChanged;

  /// Its least value.
  final double min;

  /// Its greatest value.
  final double max;

  /// How many steps it moves in.
  final int? divisions;

  /// The lower cap's name.
  final String? startLabel;

  /// The upper cap's name.
  final String? endLabel;

  /// How a screen reader says a value.
  final String Function(double value)? semanticFormatter;

  /// Its style, over [StudioThemeData.faderStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final change = onChanged;
    final lit =
        DesignStyleOf([style, theme.faderStyle], const {}).fill ?? c.indicator;
    const cap = StudioFader.cap;
    return RawRangeSlider(
      values: RawRangeValues(values.start, values.end),
      onChanged: change == null
          ? null
          : (v) => change(StudioRangeValues(v.start, v.end)),
      min: min,
      max: max,
      divisions: divisions,
      startLabel: startLabel,
      endLabel: endLabel,
      semanticFormatterCallback: semanticFormatter,
      thumbSize: Size(cap.width + 8, 44),
      trackBuilder: (context, track) => SizedBox(
        height: StudioFader.slot,
        child: CustomPaint(
          painter: _RangeSlotPainter(
            start: track.start,
            end: track.end,
            light: StudioLight.of(context),
            lit: lit,
            enabled: track.enabled,
            rtl: Directionality.of(context) == TextDirection.rtl,
            ratio: MediaQuery.maybeDevicePixelRatioOf(context) ?? 1,
          ),
          size: Size.infinite,
        ),
      ),
      thumbBuilder: (context, index, states) {
        final enabled = !states.contains(WidgetState.disabled);
        final held =
            states.contains(WidgetState.pressed) ||
            states.contains(WidgetState.dragged);
        return Center(
          child: SizedBox(
            width: cap.width,
            height: cap.height,
            child: StudioSurface(
              face: StudioFace(
                fill: enabled ? c.cap : Color.lerp(c.cap, c.panelLow, 0.4)!,
                fillLow: enabled
                    ? c.capLow
                    : Color.lerp(c.capLow, c.panelLow, 0.4)!,
                depth: StudioDepth.raised,
                radius: StudioRadii.cap,
                travel: held ? 0.5 : 0,
                brushed: true,
                focus: _ring(c, states),
              ),
              child: Center(
                child: Container(
                  width: 2,
                  height: cap.height - 10,
                  color: enabled ? c.legend : c.disabled,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DoubleProperty('start', values.start))
      ..add(DoubleProperty('end', values.end))
      ..add(
        FlagProperty('enabled', value: onChanged != null, ifFalse: 'disabled'),
      );
  }
}

class _RangeSlotPainter extends CustomPainter {
  _RangeSlotPainter({
    required this.start,
    required this.end,
    required this.light,
    required this.lit,
    required this.enabled,
    required this.rtl,
    required this.ratio,
  });

  final double start;
  final double end;
  final StudioLight light;
  final Color lit;
  final bool enabled;
  final bool rtl;
  final double ratio;

  @override
  void paint(Canvas canvas, Size size) {
    final c = light.colors;
    final slot = Rect.fromLTWH(
      -StudioFader.slot / 2,
      0,
      size.width + StudioFader.slot,
      size.height,
    );
    paintStudioFace(
      canvas,
      slot,
      StudioFace(
        fill: c.slot,
        fillLow: Color.lerp(c.slot, c.shadow, 0.3)!,
        depth: StudioDepth.sunk,
        radius: StudioFader.slot / 2,
      ),
      light,
      ratio: ratio,
    );
    double x(double f) => (rtl ? 1 - f : f) * size.width;
    final a = math.min(x(start), x(end));
    final b = math.max(x(start), x(end));
    if (b - a < 0.5) return;
    final rr = RRect.fromRectAndRadius(
      Rect.fromLTRB(a, 1, b, size.height - 1),
      const Radius.circular(StudioFader.slot / 2),
    );
    final strength = enabled ? 1.0 : 0.3;
    canvas
      ..drawRRect(
        rr,
        Paint()
          ..color = lit.withValues(alpha: 0.5 * strength)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      )
      ..drawRRect(rr, Paint()..color = lit.withValues(alpha: strength));
  }

  @override
  bool shouldRepaint(_RangeSlotPainter old) =>
      old.start != start ||
      old.end != end ||
      old.light != light ||
      old.lit != lit ||
      old.enabled != enabled ||
      old.rtl != rtl ||
      old.ratio != ratio;
}

/// A chip: a small latching key with its lamp. Pressed in, it stays down
/// with its lamp lit (a filter that is on); pressed again, it comes up.
/// Given [onDeleted], it carries a cross at its end that removes it (a
/// value you chose).
///
/// A null [onSelected] makes it a plain plate, not a key; with
/// [enabled] false it dims.
///
/// Reads [style]'s `fill`, `foreground`, `minimumSize` (its height) and
/// `textStyle` in its states, selected among them, then
/// [StudioThemeData.chipStyle].
///
/// ```dart
/// StudioChip(label: 'Interviews', selected: interviews, onSelected: (on) => setState(() => interviews = on))
/// ```
class StudioChip extends StatelessWidget {
  /// A chip reading [label].
  const StudioChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onSelected,
    this.onDeleted,
    this.icon,
    this.enabled = true,
    this.deleteLabel = 'Remove',
    this.style,
  });

  /// Its legend.
  final String label;

  /// Whether it is latched in.
  final bool selected;

  /// Called with its next state; null for a chip that does not latch.
  final ValueChanged<bool>? onSelected;

  /// Removes it; null for no cross.
  final VoidCallback? onDeleted;

  /// A glyph before the legend.
  final Widget? icon;

  /// Whether it can be pressed.
  final bool enabled;

  /// The cross's name ("Remove Interviews").
  final String deleteLabel;

  /// Its style, over [StudioThemeData.chipStyle].
  final StudioStyle? style;

  /// Its height.
  static const double height = 32;

  // The cross's width on the face.
  static const double _cross = 28;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final latching = onSelected != null;
    final rest = DesignStyleOf(
      [style, theme.chipStyle],
      {if (selected) WidgetState.selected, if (!enabled) WidgetState.disabled},
    );
    final faceHeight = rest.minimumSize?.height ?? height;
    Widget body(Set<WidgetState> states) {
      final layered = DesignStyleOf(
        [style, theme.chipStyle],
        {...states, if (selected) WidgetState.selected},
      );
      final disabled = states.contains(WidgetState.disabled);
      final ink =
          layered.foreground ??
          (disabled
              ? c.disabled
              : selected
              ? c.litLegend
              : c.onKey);
      final face = layered.on(
        c.keyFace.copyWith(
          radius: StudioRadii.small,
          travel: selected || states.contains(WidgetState.pressed) ? 1 : 0,
          fill: disabled
              ? Color.lerp(c.key, c.panelLow, 0.5)
              : states.contains(WidgetState.pressed)
              ? Color.lerp(c.key, c.keyLow, 0.24)
              : null,
          foreground: ink,
          // Focus lights the rim, selected or not: the lamp means selected,
          // and a half-lit lamp would read as half selected.
          rim: studioLitFocus(c, states, lit: true),
        ),
      );
      return SizedBox(
        height: layered.minimumSize?.height ?? height,
        child: AnimatedStudioSurface(
          face: face,
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: StudioSpacing.small + StudioSpacing.hair,
              end: onDeleted == null ? StudioSpacing.medium : 0,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (latching) ...[
                  StudioControlLamp(
                    on: selected && !disabled,
                    states: states.difference(const {WidgetState.focused}),
                    size: 6,
                  ),
                  const SizedBox(width: StudioSpacing.small),
                ],
                if (icon != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(size: 16, color: ink),
                    child: icon!,
                  ),
                  const SizedBox(width: StudioSpacing.tight),
                ],
                DesignCapCenter(
                  capHeightFactor: theme.capHeightFactor,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.secondary
                        .copyWith(
                          color: ink,
                          // One weight latched or not: a latch never
                          // moves what stands beside it.
                          fontWeight: FontWeight.w500,
                        )
                        .merge(layered.textStyle),
                  ),
                ),
                if (onDeleted != null) const SizedBox(width: _cross),
              ],
            ),
          ),
        ),
      );
    }

    final Widget chip = latching
        ? RawButton(
            onPressed: enabled ? () => onSelected!(!selected) : null,
            semanticLabel: label,
            selected: selected,
            semanticSelected: selected,
            excludeSemantics: onDeleted == null,
            builder: (context, states, _) =>
                TapTargetPadding(child: body(states)),
          )
        : Semantics(
            label: label,
            enabled: enabled,
            child: body({if (!enabled) WidgetState.disabled}),
          );
    if (onDeleted == null) return chip;
    // The chip stands in a row as tall as a finger's floor, and its cross's
    // target is the whole floor-wide square at its end, over the cross and
    // the end of its words.
    final floor = DesignTapTargets.of(context).floorOn();
    final crossInk =
        rest.foreground ??
        (!enabled
            ? c.disabled
            : selected
            ? c.litLegend
            : c.onKey);
    return SizedBox(
      height: math.max(faceHeight, floor.height),
      child: Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [
          chip,
          PositionedDirectional(
            top: 0,
            bottom: 0,
            end: 0,
            width: math.max(_cross, floor.width),
            child: RawButton(
              onPressed: enabled ? onDeleted : null,
              semanticLabel: '$deleteLabel $label',
              builder: (context, cross, _) => Align(
                alignment: AlignmentDirectional.centerEnd,
                child: SizedBox(
                  width: _cross,
                  height: faceHeight,
                  child: Icon(
                    LucideIcons.x,
                    size: StudioIconSizes.small,
                    color: cross.contains(WidgetState.pressed)
                        ? c.dangerLegend
                        : crossInk,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(StringProperty('label', label))
      ..add(FlagProperty('selected', value: selected, ifTrue: 'selected'))
      ..add(FlagProperty('enabled', value: enabled, ifFalse: 'disabled'));
  }
}

/// A score out of [max]: a row of star lenses, the ones up to [value]
/// lit in the indicator, the rest dark glass. Each lens is a key that
/// sets the score; the arrows step it. A null [onChanged] makes it a
/// readout only.
///
/// Reads [style]'s `fill` (a lit lens) and `minimumSize` (a lens's side),
/// then [StudioThemeData.ratingStyle].
///
/// ```dart
/// StudioRating(value: stars, semanticLabel: 'Your rating', onChanged: (v) => setState(() => stars = v))
/// ```
class StudioRating extends StatefulWidget {
  /// A rating at [value].
  const StudioRating({
    super.key,
    required this.value,
    required this.onChanged,
    this.max = 5,
    this.semanticLabel,
    this.style,
  });

  /// The score, 0 to [max].
  final int value;

  /// Called with the score a lens sets; null makes it read only.
  final ValueChanged<int>? onChanged;

  /// The most it can be.
  final int max;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// Its style, over [StudioThemeData.ratingStyle].
  final StudioStyle? style;

  @override
  State<StudioRating> createState() => _StudioRatingState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('value', value))
      ..add(IntProperty('max', max));
  }
}

class _StudioRatingState extends State<StudioRating> {
  // Where a pointer went down on a lens, and whether it has since moved
  // into a drag: a press without a drag on the last lens lit takes it back.
  Offset? _down;
  bool _moved = false;

  // The lens a finger holds, pressed in under it (ui_core's rating is
  // pressed only while dragged; a drag presses the lens at the score).
  int? _held;

  void _changed(double score) {
    final change = widget.onChanged;
    final next = score.round().clamp(0, widget.max);
    if (change == null || next == widget.value) return;
    change(next);
  }

  void _hold(int? i) {
    if (_held != i) setState(() => _held = i);
  }

  Widget _takeBack(int i, Widget lens) => Listener(
    onPointerDown: (e) {
      _down = e.position;
      _moved = false;
      _hold(i);
    },
    onPointerMove: (e) {
      final down = _down;
      if (down != null && (e.position - down).distance > kTouchSlop) {
        _moved = true;
        _hold(null);
      }
    },
    onPointerUp: (_) {
      // ui_core's press leaves the score already set alone (it runs after
      // this, on the score before the page's rebuild).
      if (_down != null && !_moved && widget.value == i + 1) _changed(i * 1.0);
      _down = null;
      _hold(null);
    },
    onPointerCancel: (_) {
      _down = null;
      _hold(null);
    },
    child: lens,
  );

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final value = widget.value.clamp(0, widget.max);
    final dead = widget.onChanged == null;
    final frame = DesignStyleOf([widget.style, theme.ratingStyle], const {});
    final side = frame.minimumSize?.height ?? 32.0;
    final light = frame.fill ?? c.indicator;
    Widget lens(int i, Set<WidgetState> states) {
      final on = i < value;
      // One tab stop: the focus ring and a drag's press stand on the lens at
      // the score (the first, at none).
      final here = i == math.max(0, value - 1);
      final pressed =
          _held == i || (here && states.contains(WidgetState.pressed));
      // A rating that takes no score has its lenses dead: the unlit stars
      // in the disabled ink, the lit ones dimmed and without their glow.
      // By night an unlit star is dark glass whose edge catches the light,
      // at 3:1 on the metal, as an unlit lamp's bezel does.
      final edged = !on && !dead && c.brightness == Brightness.dark;
      final star = on
          ? dead
                ? Color.lerp(light, c.disabled, 0.6)!
                : light
          : dead
          ? c.disabled
          : edged
          ? Color.lerp(c.lampOff, const Color(0xFF000000), 0.35)!
          : c.lampOff;
      return SizedBox.square(
        dimension: side,
        child: AnimatedStudioSurface(
          stiffness: StudioMotion.lampStiffness,
          face: c.recessFace.copyWith(
            radius: side / 2,
            presence: pressed ? 1 : 0,
            focus: here ? _ring(c, states) : _ring(c, const {}),
          ),
          child: Center(
            child: CustomPaint(
              size: Size.square(side * 0.6),
              painter: _StarPainter(
                star,
                glow: on && !dead,
                edge: edged ? c.lampEdge : null,
              ),
            ),
          ),
        ),
      );
    }

    return RawRating(
      value: value.toDouble(),
      itemCount: widget.max,
      onChanged: dead ? null : _changed,
      // No onChanged: a readout of a score, read as a value, not disabled.
      readOnly: dead,
      semanticLabel: widget.semanticLabel,
      // The lenses light only when given: a hovering pointer previews
      // nothing, as before.
      itemBuilder: (context, item) {
        // The same room for a dead lens as a live one: a rating that stops
        // taking a score keeps its place.
        final cell = TapTargetPadding(
          child: Padding(
            padding: const EdgeInsets.all(StudioSpacing.hair),
            child: lens(item.index, item.states),
          ),
        );
        return dead ? cell : _takeBack(item.index, cell);
      },
      layoutBuilder: (context, items) =>
          Row(mainAxisSize: MainAxisSize.min, children: items),
    );
  }
}

/// A file a [StudioFileDrop] holds.
///
/// ```dart
/// const StudioFile(name: 'take-3.wav', bytes: 48200000, progress: 0.4)
/// ```
@immutable
class StudioFile {
  /// A file called [name], [bytes] long.
  const StudioFile({required this.name, required this.bytes, this.progress});

  /// Its name.
  final String name;

  /// Its size.
  final int bytes;

  /// How much of it has gone up, 0 to 1; null once it is up (or before it
  /// starts).
  final double? progress;

  /// Its size as a person reads it: `48.2 MB`.
  String get size {
    if (bytes < 1000) return '$bytes B';
    if (bytes < 1000000) return '${(bytes / 1000).toStringAsFixed(0)} kB';
    if (bytes < 1000000000) return '${(bytes / 1000000).toStringAsFixed(1)} MB';
    return '${(bytes / 1000000000).toStringAsFixed(2)} GB';
  }
}

/// A tray to put files in: a recess in the metal with an engraved dashed
/// edge, what it takes printed in it and a key that opens the chooser.
/// The files below it each show a row with its size, a fine meter while it
/// goes up, and a key that takes it out.
///
/// Studio does not read the platform's files: [onChoose] does (with
/// `file_selector` or the like) and hands them back in [files]. A null
/// [onChoose] disables it.
///
/// Reads [style]'s `fill` (the tray), then [StudioThemeData.fileDropStyle].
///
/// ```dart
/// StudioFileDrop(label: 'Audio', hint: 'WAV or MP3, up to 500 MB', files: files, onChoose: pick, onRemove: (f) => setState(() => files.remove(f)))
/// ```
class StudioFileDrop extends StatelessWidget {
  /// A tray holding [files].
  const StudioFileDrop({
    super.key,
    required this.onChoose,
    this.files = const [],
    this.onRemove,
    this.label,
    this.hint,
    this.error,
    this.chooseLabel = 'Choose a file',
    this.removeLabel = 'Remove',
    this.multiple = true,
    this.style,
  });

  /// Whether it takes more than one file. Taking one (a cover, an avatar),
  /// the file in it stands in the tray's place until it is taken out.
  final bool multiple;

  /// Opens the chooser; null disables it.
  final VoidCallback? onChoose;

  /// The files in it.
  final List<StudioFile> files;

  /// Takes one out; null keeps them.
  final ValueChanged<StudioFile>? onRemove;

  /// The label above it.
  final String? label;

  /// What it takes, printed in the tray.
  final String? hint;

  /// What is wrong (it would not go up), under it.
  final String? error;

  /// The chooser key's legend.
  final String chooseLabel;

  /// A remove key's name ("Remove take-3.wav").
  final String removeLabel;

  /// Its style, over [StudioThemeData.fileDropStyle].
  final StudioStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final enabled = onChoose != null;
    final frame = DesignStyleOf(
      [style, theme.fileDropStyle],
      {
        if (!enabled) WidgetState.disabled,
        if (error != null) WidgetState.error,
      },
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          ExcludeSemantics(child: StudioFieldLabel(label!, enabled: enabled)),
        // The drop is a pane of glass with a cut edge: what lands on it is
        // read there.
        if (multiple || files.isEmpty)
          StudioSurface(
            face: c.displayFace.copyWith(
              radius: StudioRadii.bank,
              fill: frame.fill,
            ),
            child: CustomPaint(
              painter: _DashedEdge(
                error != null ? c.danger : c.groove,
                c.edgeLight,
              ),
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.large),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.upload,
                      size: StudioIconSizes.large,
                      color: enabled ? c.onDisplayMuted : c.disabled,
                    ),
                    if (hint != null) ...[
                      const SizedBox(height: StudioSpacing.small),
                      Text(
                        hint!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.secondary.copyWith(
                          color: enabled ? c.onDisplayMuted : c.disabled,
                        ),
                      ),
                    ],
                    const SizedBox(height: StudioSpacing.medium),
                    StudioButton(
                      chooseLabel,
                      icon: const Icon(LucideIcons.folderOpen),
                      onPressed: onChoose,
                    ),
                  ],
                ),
              ),
            ),
          ),
        StudioFieldMessage(error: error),
        for (final f in files) ...[
          const SizedBox(height: StudioSpacing.small),
          _FileRow(
            file: f,
            removeLabel: '$removeLabel ${f.name}',
            onRemove: onRemove == null ? null : () => onRemove!(f),
          ),
        ],
      ],
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('files', files.length))
      ..add(FlagProperty('multiple', value: multiple, ifFalse: 'one file'))
      ..add(
        FlagProperty('enabled', value: onChoose != null, ifFalse: 'disabled'),
      );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.removeLabel,
    required this.onRemove,
  });

  final StudioFile file;
  final String removeLabel;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = StudioTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final progress = file.progress;
    return StudioSurface(
      face: c.displayFace.copyWith(radius: StudioRadii.key),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          start: StudioSpacing.medium,
          end: StudioSpacing.small,
          top: StudioSpacing.small,
          bottom: StudioSpacing.small,
        ),
        child: Row(
          children: [
            Icon(
              _fileGlyph(file.name),
              size: StudioIconSizes.regular,
              color: c.onDisplayMuted,
            ),
            const SizedBox(width: StudioSpacing.medium),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    file.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.body.copyWith(color: c.onDisplay),
                  ),
                  Text(
                    progress == null
                        ? file.size
                        : '${file.size} · ${words.formatPercent(progress)}',
                    style: theme.textTheme.caption.copyWith(
                      color: c.onDisplayMuted,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(height: StudioSpacing.tight),
                    Semantics(
                      value: '${(progress * 100).round()}%',
                      child: _Bar(progress: progress),
                    ),
                  ],
                ],
              ),
            ),
            if (onRemove != null)
              StudioIconButton(
                icon: const Icon(LucideIcons.x),
                tooltip: removeLabel,
                onPressed: onRemove,
                style: StudioStyle(fill: WidgetStatePropertyAll(c.display)),
              ),
          ],
        ),
      ),
    );
  }
}

// A fine lit bar in a slot: how far a file has gone up.
class _Bar extends StatelessWidget {
  const _Bar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final c = StudioTheme.of(context).colors;
    return SizedBox(
      height: 4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.slot,
          borderRadius: BorderRadius.circular(2),
        ),
        child: FractionallySizedBox(
          alignment: AlignmentDirectional.centerStart,
          widthFactor: progress.clamp(0, 1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.indicator,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: c.indicator.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedEdge extends CustomPainter {
  _DashedEdge(this.groove, this.light);

  final Color groove;
  final Color light;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(StudioSpacing.small);
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          rect,
          const Radius.circular(StudioRadii.bank - StudioSpacing.small),
        ),
      );
    final dashed = Path();
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        dashed.addPath(metric.extractPath(d, d + 5), Offset.zero);
      }
    }
    canvas
      ..drawPath(
        dashed.shift(const Offset(0, 1)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = light,
      )
      ..drawPath(
        dashed,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = groove,
      );
  }

  @override
  bool shouldRepaint(_DashedEdge old) =>
      old.groove != groove || old.light != light;
}

// A five-pointed lens, lit or dark; lit, it gives off its light.
class _StarPainter extends CustomPainter {
  _StarPainter(this.color, {required this.glow, this.edge});

  final Color color;
  final bool glow;

  /// The outline drawn round the glass, if any.
  final Color? edge;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final centre = size.center(Offset.zero);
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? r : r * 0.45;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final p = centre + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    if (glow) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
    canvas.drawPath(path, Paint()..color = color);
    final edge = this.edge;
    if (edge != null) {
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeJoin = StrokeJoin.round
          ..color = edge,
      );
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) =>
      old.color != color || old.glow != glow || old.edge != edge;
}

// A file's glyph by its kind, read from its name's extension.
IconData _fileGlyph(String name) {
  final dot = name.lastIndexOf('.');
  final kind = dot < 0 ? '' : name.substring(dot + 1).toLowerCase();
  return switch (kind) {
    'mp3' ||
    'wav' ||
    'aac' ||
    'm4a' ||
    'flac' ||
    'ogg' ||
    'aif' ||
    'aiff' => LucideIcons.fileAudio,
    'jpg' ||
    'jpeg' ||
    'png' ||
    'gif' ||
    'webp' ||
    'heic' ||
    'svg' => LucideIcons.fileImage,
    'mp4' || 'mov' || 'webm' || 'mkv' => LucideIcons.fileVideo,
    'txt' || 'md' || 'pdf' || 'doc' || 'docx' || 'rtf' => LucideIcons.fileText,
    _ => LucideIcons.file,
  };
}
