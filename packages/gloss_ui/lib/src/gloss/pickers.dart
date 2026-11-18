/// Gloss's pickers: the calendar (days on porcelain, the chosen one a jade
/// gel bead), the date and date-range fields that open it, the wheel (a
/// glossy drum turning in a well), the time picker built of wheels, and the
/// colour picker.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'fonts.dart';
import 'internal/menu_parts.dart';
import 'popovers.dart';
import 'surface.dart';
import 'text_field.dart';
import 'theme.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A span of days, both ends counted.
@immutable
class GlossDateRange {
  /// The days from [start] to [end].
  GlossDateRange({required DateTime start, required DateTime end})
    : assert(!end.isBefore(start)),
      start = _day(start),
      end = _day(end);

  /// The first day.
  final DateTime start;

  /// The last day.
  final DateTime end;

  /// How many days it spans, both ends counted.
  int get days => end.difference(start).inDays + 1;

  @override
  bool operator ==(Object other) =>
      other is GlossDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'GlossDateRange($start – $end)';
}

/// A time of day, on a 24-hour clock.
@immutable
class GlossTime {
  /// [hour] (0 to 23) and [minute] (0 to 59).
  const GlossTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour, 0 to 23.
  final int hour;

  /// The minute, 0 to 59.
  final int minute;

  /// The time as the reader's clock writes it: 18:30, or 6:30 PM.
  String format(BuildContext context) {
    final h24 = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
    final mm = minute.toString().padLeft(2, '0');
    if (h24) return '${hour.toString().padLeft(2, '0')}:$mm';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:$mm ${hour < 12 ? 'AM' : 'PM'}';
  }

  @override
  bool operator ==(Object other) =>
      other is GlossTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'GlossTime($hour:$minute)';
}

/// A month calendar on porcelain: the month and its turning beads along
/// the top, the weekdays letterpressed, the days as figures. The chosen
/// day is a jade gel bead; today has a jade figure; a range is glazed pale
/// jade between its two gel ends.
///
/// ```dart
/// GlossCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), selectedDate: DateTime(2026, 11, 16), onDateChanged: (day) {})
/// ```
class GlossCalendar extends StatefulWidget {
  /// A calendar choosing one day.
  const GlossCalendar({
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

  /// A calendar choosing a span of days: a first press its start, a
  /// second its end.
  const GlossCalendar.range({
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

  /// A day chosen; null disables it.
  final ValueChanged<DateTime>? onDateChanged;

  /// The chosen span.
  final GlossDateRange? selectedRange;

  /// A span chosen (once both ends are); null disables it.
  final ValueChanged<GlossDateRange>? onRangeChanged;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// Whether a day may be chosen; null: all between the bounds.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// How many months show side by side.
  final int months;

  /// Whether it takes the focus once built.
  final bool autofocus;

  /// Its own style, over [GlossThemeData.calendarStyle].
  final GlossStyle? style;

  final bool _range;

  @override
  State<GlossCalendar> createState() => _GlossCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('selectedDate', selectedDate))
      ..add(DiagnosticsProperty<GlossDateRange>('selectedRange', selectedRange))
      ..add(FlagProperty('range', value: _range, ifTrue: 'range'));
  }
}

class _GlossCalendarState extends State<GlossCalendar> {
  late DesignCalendarController _controller = _make();

  bool get _enabled => widget._range
      ? widget.onRangeChanged != null
      : widget.onDateChanged != null;

  DesignCalendarController _make() => DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: widget._range ? DesignCalendarMode.range : DesignCalendarMode.single,
    selectedDate: widget.selectedDate,
    selectedRange: widget.selectedRange == null
        ? null
        : DesignDateRange(
            widget.selectedRange!.start,
            widget.selectedRange!.end,
          ),
    currentDate: widget.currentDate,
    selectable: (d) =>
        _enabled && (widget.selectableDayPredicate?.call(d) ?? true),
  );

  @override
  void didUpdateWidget(GlossCalendar old) {
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
      widget.onRangeChanged?.call(GlossDateRange(start: r.start, end: r.end!));
    }
  }

  // The days are set in fixed cells, a finger wide: their figures grow
  // with the reader's text up to 1.3x, past that they would run together.
  @override
  Widget build(BuildContext context) => MediaQuery.withClampedTextScaling(
    maxScaleFactor: 1.3,
    child: Builder(builder: _build),
  );

  Widget _build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final words = DesignLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layers = [widget.style, theme.calendarStyle];
    // A day is a finger's height at least (its bead a little less).
    final dayHeight = math.max(
      44.0,
      MediaQuery.textScalerOf(context).scale(15) * 1.4 + 12,
    );
    const turnStyle = GlossStyle(
      minimumSize: WidgetStatePropertyAll(Size(32, 32)),
      iconSize: WidgetStatePropertyAll(18),
    );
    // A month is at most 420 wide (its days at 60), and it lays out where
    // the width is unbounded too (in a row of its own).
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth:
            widget.months * 420.0 + (widget.months - 1) * GlossSpacing.large,
      ),
      child: DesignCalendar(
        controller: _controller,
        months: widget.months,
        autofocus: widget.autofocus,
        onChanged: _changed,
        minDayWidth: 40,
        headerBuilder: (context, header) => Padding(
          padding: const EdgeInsets.only(bottom: GlossSpacing.small),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: GlossSpacing.small,
                  ),
                  child: Text(
                    header.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.label.copyWith(color: c.ink),
                  ),
                ),
              ),
              GlossIconButton(
                onPressed: header.previous,
                tooltip: words.previousMonthTooltip,
                style: turnStyle,
                icon: Icon(
                  rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                ),
              ),
              const SizedBox(width: GlossSpacing.small),
              GlossIconButton(
                onPressed: header.next,
                tooltip: words.nextMonthTooltip,
                style: turnStyle,
                icon: Icon(
                  rtl ? LucideIcons.chevronLeft : LucideIcons.chevronRight,
                ),
              ),
            ],
          ),
        ),
        weekdayBuilder: (context, weekday, label) => SizedBox(
          height: 28,
          child: Center(
            child: Text(
              label,
              style: glossLetterpress(
                theme.textTheme.caption.copyWith(
                  color: c.inkSecondary,
                  fontWeight: FontWeight.w600,
                ),
                c,
              ),
            ),
          ),
        ),
        // Each month's grid shares the width out by day, so each takes its
        // share of the row.
        monthsBuilder: (context, months) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, m) in months.indexed) ...[
              if (i > 0) const SizedBox(width: GlossSpacing.large),
              Expanded(child: m),
            ],
          ],
        ),
        dayBuilder: (context, day, states) {
          final layered = DesignStyleOf(layers, states);
          // A waiting range's preview ends as a finished range does: a bead on
          // the day under the pointer (or the keyboard), the glaze stopping at
          // it.
          final end =
              day.isRangeStart ||
              day.isRangeEnd ||
              day.isPreviewEnd ||
              (states.contains(WidgetState.selected) && !widget._range);
          final within = (day.inRange || day.inPreview) && !end;
          final range = _controller.selectedRange;
          final finished =
              widget._range && range?.end != null && range!.start != range.end;
          final glazeFrom =
              day.isRangeStart &&
              (finished || (day.inPreview && !day.isPreviewEnd));
          final glazeTo =
              (day.isRangeEnd && finished) ||
              (day.isPreviewEnd && !day.isRangeStart);
          final disabled = !day.enabled;
          final light = c.brightness == Brightness.light;
          final glaze = light
              ? const Color(0xFFD9F1E7)
              : const Color(0xFF1E4136);
          var bead = GlossFace.gel(c);
          if (layered.fill != null) bead = bead.glazed(layered.fill!);
          final clear = c.page.withValues(alpha: 0);
          final face = end
              ? bead.copyWith(
                  lift: 0.6,
                  travel: states.contains(WidgetState.pressed) ? 1 : 0,
                )
              : GlossFace(
                  top: clear,
                  middle: clear,
                  bottom: clear,
                  foreground: c.ink,
                );
          final ink = end
              ? c.onJade
              : disabled
              ? c.inkDisabled
              : !day.inMonth
              ? c.inkSecondary.withValues(alpha: 0.6)
              : day.isToday
              ? c.jadeInk
              : c.ink;
          return SizedBox(
            height: dayHeight,
            child: Stack(
              fit: StackFit.expand,
              clipBehavior: Clip.none,
              children: [
                // A range's glaze runs behind its days, from end to end; each
                // day's piece reaches a pixel into its neighbours, so the
                // days' fractional edges leave no seam.
                if (within || glazeFrom || glazeTo)
                  PositionedDirectional(
                    top: 4,
                    bottom: 4,
                    start: glazeFrom ? 20 : -1,
                    end: glazeTo ? 20 : -1,
                    child: ColoredBox(color: glaze),
                  ),
                Center(
                  child: SizedBox.square(
                    dimension: dayHeight - 4,
                    child: AnimatedGlossSurface(
                      face: face.copyWith(
                        foreground: ink,
                        focus: glossFocusOf(
                          c,
                          focused: states.contains(WidgetState.focused),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${day.date.day}',
                          style: theme.textTheme.body.copyWith(
                            color: ink,
                            fontWeight: end || day.isToday
                                ? FontWeight.w600
                                : FontWeight.w400,
                            fontVariations: glossWeightAxis(
                              end || day.isToday
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (day.isToday && !end)
                  Align(
                    alignment: const Alignment(0, 0.78),
                    child: SizedBox.square(
                      dimension: 4,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          color: c.jadeInk,
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
  }
}

/// The well a picker field shows its value in, with a bead at its end that
/// opens the picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.anchor,
    required this.text,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.error,
    required this.semanticLabel,
  });

  final DesignOverlayAnchor anchor;
  final String? text;
  final String? hint;
  final IconData icon;
  final bool enabled;
  final bool error;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    return DesignPressable(
      onPressed: enabled ? anchor.toggle : null,
      semanticLabel: semanticLabel,
      semanticValue: text,
      expanded: anchor.isOpen,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states, _) {
        final open = anchor.isOpen;
        var well = GlossFace.well(c, radius: GlossMetrics.fieldRadius);
        well = well.copyWith(
          lift: enabled ? -1 : -0.45,
          edge: error ? c.danger : null,
          focus: states.contains(WidgetState.focused) || open
              ? (error ? c.danger : c.focus)
              : c.focus.withValues(alpha: 0),
        );
        final bead = height - 14;
        // Its height is a floor: a date on two lines makes the well taller.
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: AnimatedGlossSurface(
            face: well,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: GlossSpacing.regular,
                      end: GlossSpacing.small,
                      top: 6,
                      bottom: 6,
                    ),
                    child: DesignCapCenter(
                      capHeightFactor: glossCapHeightFactor,
                      child: Text(
                        text ?? hint ?? '',
                        // A long date at a large text size takes a second
                        // line rather than losing its month.
                        maxLines:
                            MediaQuery.textScalerOf(context).scale(10) >= 15
                            ? 2
                            : 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.body.copyWith(
                          color: !enabled
                              ? c.inkDisabled
                              : text == null
                              ? c.inkSecondary
                              : c.ink,
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: (height - bead) / 2),
                  child: SizedBox.square(
                    dimension: bead,
                    child: AnimatedGlossSurface(
                      face: enabled
                          ? GlossFace.pearl(c).copyWith(
                              travel:
                                  states.contains(WidgetState.pressed) || open
                                  ? 1
                                  : 0,
                              foreground: open ? c.jadeInk : c.inkSecondary,
                            )
                          : GlossFace.pearlOff(c),
                      child: Center(child: Icon(icon, size: 18)),
                    ),
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

Widget _fieldColumn({
  required String? label,
  required bool enabled,
  required Widget box,
  required String? helper,
  required String? error,
}) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    if (label != null)
      ExcludeSemantics(child: GlossFieldLabel(label, enabled: enabled)),
    box,
    GlossFieldMessage(helper: helper, error: error),
  ],
);

Widget _calendarPanel(BuildContext context, Widget calendar) => GlossSurface(
  face: glossPanelFace(GlossTheme.of(context).colors, radius: 20),
  child: Padding(
    padding: const EdgeInsets.all(GlossSpacing.medium),
    child: calendar,
  ),
);

/// A date field: a well showing the chosen day, which opens a calendar on
/// a porcelain panel under it; a press on a day takes it and closes.
///
/// ```dart
/// GlossDatePicker(label: 'Cook on', value: DateTime(2026, 11, 18), firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (day) {})
/// ```
class GlossDatePicker extends StatelessWidget {
  /// A date field at [value].
  const GlossDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.currentDate,
  });

  /// The chosen day.
  final DateTime? value;

  /// A day chosen; null disables it.
  final ValueChanged<DateTime>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The words above the well.
  final String? label;

  /// What the empty well says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context);
    final enabled = onChanged != null;
    return _fieldColumn(
      label: label,
      enabled: enabled,
      helper: helper,
      error: error,
      box: DesignAnchoredOverlay(
        semanticLabel: label,
        placement: const DesignOverlayPlacement(
          gap: GlossSpacing.small,
          margin: GlossSpacing.small,
          matchAnchorWidth: false,
        ),
        dampingRatio: GlossMotion.panelDamping,
        stiffness: GlossMotion.panelStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          text: value == null ? null : words.formatFullDate(value!),
          hint: hint,
          icon: LucideIcons.calendar,
          enabled: enabled,
          error: error != null,
          semanticLabel: label ?? hint,
        ),
        overlayBuilder: (context, info) => glossPanelArrival(
          info,
          _calendarPanel(
            context,
            GlossCalendar(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedDate: value,
              currentDate: currentDate,
              autofocus: true,
              onDateChanged: (day) {
                info.close();
                onChanged?.call(day);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value))
      ..add(StringProperty('label', label, defaultValue: null));
  }
}

/// A date-range field: a well showing the span, which opens a range
/// calendar; the second day pressed ends the span and closes it.
///
/// ```dart
/// GlossDateRangePicker(label: 'Plan', value: null, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (range) {})
/// ```
class GlossDateRangePicker extends StatelessWidget {
  /// A date-range field at [value].
  const GlossDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.label,
    this.hint,
    this.helper,
    this.error,
    this.currentDate,
  });

  /// The chosen span.
  final GlossDateRange? value;

  /// A span chosen; null disables it.
  final ValueChanged<GlossDateRange>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The words above the well.
  final String? label;

  /// What the empty well says.
  final String? hint;

  /// Help under the well.
  final String? helper;

  /// What is wrong, under the well.
  final String? error;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  @override
  Widget build(BuildContext context) {
    final words = DesignLocalizations.of(context);
    final enabled = onChanged != null;
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return _fieldColumn(
      label: label,
      enabled: enabled,
      helper: helper,
      error: error,
      box: DesignAnchoredOverlay(
        semanticLabel: label,
        placement: const DesignOverlayPlacement(
          gap: GlossSpacing.small,
          margin: GlossSpacing.small,
          matchAnchorWidth: false,
        ),
        dampingRatio: GlossMotion.panelDamping,
        stiffness: GlossMotion.panelStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          text: value == null
              ? null
              : '${words.formatFullDate(value!.start)} – '
                    '${words.formatFullDate(value!.end)}',
          hint: hint,
          icon: LucideIcons.calendarRange,
          enabled: enabled,
          error: error != null,
          semanticLabel: label ?? hint,
        ),
        overlayBuilder: (context, info) => glossPanelArrival(
          info,
          _calendarPanel(
            context,
            GlossCalendar.range(
              firstDate: firstDate,
              lastDate: lastDate,
              selectedRange: value,
              currentDate: currentDate,
              months: wide ? 2 : 1,
              autofocus: true,
              onRangeChanged: (range) {
                info.close();
                onChanged?.call(range);
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<GlossDateRange>('value', value));
  }
}

/// One drum of a wheel: rows on a cylinder turning in a well, the chosen
/// row under a clear lens across its middle.
/// The lens over a drum's chosen row: clear, its rim and the top light's
/// sheen (by night a faint crown light, not a bar).
GlossFace _drumLens(GlossColors c, {bool focused = false}) {
  final light = c.brightness == Brightness.light;
  return GlossFace(
    top: light ? const Color(0x2EFFFFFF) : const Color(0x14FFFFFF),
    middle: const Color(0x00FFFFFF),
    bottom: light ? const Color(0x0F000000) : const Color(0x1A000000),
    edge: light ? const Color(0x33000000) : const Color(0xFF15191D),
    foreground: c.ink,
    lens: light ? 0.7 : 0.3,
    radius: 10,
    focus: focused ? c.focus : c.focus.withValues(alpha: 0),
  );
}

// A drum's row height.
const double _rowHeight = 40;

/// Gloss's drums on ui_core's wheel picker: a glossy drum per column, its
/// rows falling into shadow toward the well's lips, the chosen row under a
/// clear lens. With [sharedLens] one lens spans the columns (a time, read as
/// one row) and each column keeps its own focus ring.
Widget _drums(
  BuildContext context, {
  required List<DesignWheelColumn> columns,
  required List<int> selection,
  required ValueChanged<List<int>>? onChanged,
  required int rows,
  required double width,
  required bool sharedLens,
  String? semanticLabel,
  Widget Function(BuildContext context, List<Widget> columns)? layout,
}) {
  final theme = GlossTheme.of(context);
  final c = theme.colors;
  return DesignWheelPicker(
    columns: (_) => columns,
    selection: selection,
    onChanged: onChanged,
    itemExtent: _rowHeight,
    visibleItemCount: rows,
    // A wide drum: the outer rows lean back without looking squashed.
    diameterRatio: 2.2,
    perspective: 0.004,
    squeeze: 1,
    semanticLabel: semanticLabel,
    layoutBuilder: layout,
    itemBuilder: (context, row) => Center(
      child: Text(
        row.label,
        maxLines: 1,
        style: theme.textTheme.title.copyWith(
          color: !row.enabled
              ? c.inkDisabled
              : row.selected
              ? c.ink
              : c.inkSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
    columnBuilder: (context, column, wheel) {
      final focused = column.states.contains(WidgetState.focused);
      return SizedBox(
        width: width,
        height: _rowHeight * rows,
        child: Stack(
          children: [
            wheel,
            // The lens over the chosen row: clear, its rim and the top
            // light's sheen. It spans the drum's width (a bare surface has
            // no width of its own: centred, it would shrink to a hairline).
            IgnorePointer(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  height: _rowHeight + 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: GlossSpacing.tight,
                    ),
                    child: GlossSurface(
                      face: sharedLens
                          // Under a shared lens, the drum keeps its own
                          // focus ring.
                          ? GlossFace(
                              top: const Color(0x00FFFFFF),
                              middle: const Color(0x00FFFFFF),
                              bottom: const Color(0x00FFFFFF),
                              foreground: c.ink,
                              radius: 10,
                              focus: focused
                                  ? c.focus
                                  : c.focus.withValues(alpha: 0),
                            )
                          : _drumLens(c, focused: focused),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _drumWell(GlossColors c, Widget child) => GlossSurface(
  face: GlossFace.well(c, radius: 18),
  child: Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: GlossSpacing.tight + GlossMetrics.rimRoom,
      vertical: GlossSpacing.tight,
    ),
    child: ClipRRect(borderRadius: BorderRadius.circular(14), child: child),
  ),
);

/// A wheel: a glossy drum of [items] turning in a well, the chosen one
/// under a clear lens across the middle. A drag or a fling turns it; Up and
/// Down turn it a row.
///
/// ```dart
/// GlossWheelPicker<int>(items: const [1, 2, 3, 4, 5, 6], value: 4, labelOf: (n) => '$n', onChanged: (n) {}, semanticLabel: 'Servings')
/// ```
class GlossWheelPicker<T> extends StatelessWidget {
  /// A wheel of [items] at [value].
  const GlossWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.labelOf,
    this.semanticLabel,
    this.visibleRows = 5,
    this.width = 160,
  });

  /// What it offers.
  final List<T> items;

  /// The chosen one.
  final T value;

  /// One chosen; null disables it.
  final ValueChanged<T>? onChanged;

  /// An item's words.
  final String Function(T item) labelOf;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// How many rows show.
  final int visibleRows;

  /// Its width.
  final double width;

  @override
  Widget build(BuildContext context) {
    final c = GlossTheme.of(context).colors;
    final at = math.max(0, items.indexOf(value));
    return _drumWell(
      c,
      _drums(
        context,
        columns: [
          DesignWheelColumn(
            itemCount: items.length,
            itemLabel: (i) => labelOf(items[i]),
            semanticLabel: semanticLabel,
          ),
        ],
        selection: [at],
        rows: visibleRows,
        width: width,
        sharedLens: false,
        layout: (context, columns) => columns.single,
        onChanged: onChanged == null
            ? null
            : (picked) => onChanged!(items[picked.single]),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IntProperty('items', items.length))
      ..add(DiagnosticsProperty<T>('value', value));
  }
}

/// A time picker: drums for the hour and the minute (and the half of the
/// day, on a 12-hour clock) in one well.
///
/// ```dart
/// GlossTimePicker(value: const GlossTime(hour: 18, minute: 30), onChanged: (time) {})
/// ```
class GlossTimePicker extends StatelessWidget {
  /// A time picker at [value].
  const GlossTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.semanticLabel,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0);

  /// The chosen time.
  final GlossTime value;

  /// A time chosen; null disables it.
  final ValueChanged<GlossTime>? onChanged;

  /// The minutes it steps by.
  final int minuteInterval;

  /// What a screen reader calls it.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    final h24 = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
    final minutes = [for (var m = 0; m < 60; m += minuteInterval) m];
    final minuteAt = math.max(0, minutes.indexWhere((m) => m >= value.minute));
    final morning = value.hour < 12;
    final colon = Text(
      ':',
      style: theme.textTheme.title.copyWith(color: c.inkSecondary),
    );
    final columns = [
      if (h24)
        DesignWheelColumn(
          itemCount: 24,
          itemLabel: (h) => h.toString().padLeft(2, '0'),
          semanticLabel: 'Hour',
        )
      else
        DesignWheelColumn(
          itemCount: 12,
          itemLabel: (i) => '${i + 1}',
          semanticLabel: 'Hour',
        ),
      DesignWheelColumn(
        itemCount: minutes.length,
        itemLabel: (i) => minutes[i].toString().padLeft(2, '0'),
        semanticLabel: 'Minute',
      ),
      if (!h24)
        DesignWheelColumn(
          itemCount: 2,
          itemLabel: (i) => const ['AM', 'PM'][i],
          semanticLabel: 'AM or PM',
        ),
    ];
    final selection = [
      if (h24)
        value.hour
      else
        (value.hour % 12 == 0 ? 12 : value.hour % 12) - 1,
      minuteAt,
      if (!h24) morning ? 0 : 1,
    ];
    GlossTime timeOf(List<int> picked) {
      final minute = minutes[picked[1]];
      if (h24) return GlossTime(hour: picked[0], minute: minute);
      final hour = (picked[0] + 1) % 12 + (picked[2] == 1 ? 12 : 0);
      return GlossTime(hour: hour, minute: minute);
    }

    final change = onChanged;
    return _drumWell(
      c,
      Directionality(
        // A clock reads hour then minute in every language.
        textDirection: TextDirection.ltr,
        // One lens across the hour, the minute and the half of the day:
        // the time is read as one row.
        child: Stack(
          children: [
            _drums(
              context,
              columns: columns,
              selection: selection,
              rows: 5,
              width: 64,
              sharedLens: true,
              semanticLabel: semanticLabel,
              layout: (context, drums) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [drums[0], colon, ...drums.skip(1)],
              ),
              onChanged: change == null
                  ? null
                  : (picked) => change(timeOf(picked)),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: _rowHeight + 2,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: GlossSpacing.tight,
                      ),
                      child: GlossSurface(face: _drumLens(c)),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<GlossTime>('value', value))
      ..add(IntProperty('minuteInterval', minuteInterval));
  }
}

/// A colour picker: the saturation and brightness of the hue in a sunken
/// frame, grooves for the hue (and the opacity), each with a clear bead
/// holding the colour, and the colour itself in a bead with its hex code.
///
/// ```dart
/// GlossColorPicker(value: const Color(0xFF1FA77A), onChanged: (color) {})
/// ```
class GlossColorPicker extends StatefulWidget {
  /// A colour picker at [value].
  const GlossColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
  });

  /// The colour.
  final Color value;

  /// A colour chosen.
  final ValueChanged<Color> onChanged;

  /// Whether the opacity can change.
  final bool showAlpha;

  @override
  State<GlossColorPicker> createState() => _GlossColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('value', value))
      ..add(FlagProperty('showAlpha', value: showAlpha, ifTrue: 'alpha'));
  }
}

class _GlossColorPickerState extends State<GlossColorPicker> {
  late final DesignColorController _controller = DesignColorController(
    widget.value,
  )..addListener(_changed);

  void _changed() {
    if (_controller.color != widget.value) widget.onChanged(_controller.color);
  }

  @override
  void didUpdateWidget(GlossColorPicker old) {
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

  Widget _bead(GlossColors c, Set<WidgetState> states, Color fill) => Center(
    child: SizedBox.square(
      dimension: 22,
      child: GlossSurface(
        face: GlossFace.pearl(c).copyWith(
          lift: states.contains(WidgetState.pressed) ? 0.5 : 1,
          focus: glossFocusOf(c, focused: states.contains(WidgetState.focused)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(GlossSpacing.tight),
          child: GlossSurface(
            face: GlossFace(
              top: fill,
              middle: fill,
              bottom: fill,
              foreground: c.ink,
              lens: 0.6,
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final c = theme.colors;
    return DesignColorPicker(
      controller: _controller,
      showAlpha: widget.showAlpha,
      areaHeight: 180,
      areaBuilder: (context, area) => GlossSurface(
        face: GlossFace.well(c, radius: 14),
        child: Padding(
          padding: const EdgeInsets.all(GlossMetrics.frameRim),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: CustomPaint(
              painter: _AreaPainter(area.color.hue),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      areaThumbBuilder: (context, area) =>
          _bead(c, area.states, area.color.toColor().withValues(alpha: 1)),
      trackBuilder: (context, channel, color) => Center(
        child: SizedBox(
          height: 16,
          child: GlossSurface(
            face: GlossFace.well(c),
            child: Padding(
              padding: const EdgeInsets.all(GlossMetrics.rimRoom),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: _TrackPainter(channel, color),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, states) =>
          _bead(c, states, _controller.color.withValues(alpha: 1)),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: GlossSpacing.medium),
            part,
          ],
          const SizedBox(height: GlossSpacing.medium),
          ValueListenableBuilder<HSVColor>(
            valueListenable: _controller,
            builder: (context, hsv, _) => Row(
              children: [
                SizedBox.square(
                  dimension: 36,
                  child: GlossSurface(
                    face: GlossFace(
                      top: hsv.toColor(),
                      middle: hsv.toColor(),
                      bottom: hsv.toColor(),
                      edge: c.pearlEdge,
                      foreground: c.ink,
                      lens: 0.7,
                      lift: 0.6,
                    ),
                  ),
                ),
                const SizedBox(width: GlossSpacing.medium),
                Text(
                  _controller.hex,
                  style: theme.textTheme.body.copyWith(
                    color: c.ink,
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
  _TrackPainter(this.channel, this.color);

  final DesignColorChannel channel;
  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (channel) {
      DesignColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      DesignColorChannel.saturation => [
        color.withSaturation(0).withAlpha(1).toColor(),
        color.withSaturation(1).withAlpha(1).toColor(),
      ],
      DesignColorChannel.brightness => [
        const Color(0xFF000000),
        color.withValue(1).withAlpha(1).toColor(),
      ],
      DesignColorChannel.alpha => [
        color.withAlpha(0).toColor(),
        color.withAlpha(1).toColor(),
      ],
    };
    if (channel == DesignColorChannel.alpha) {
      // A chequer under the opacity, so clear reads as clear.
      const s = 6.0;
      final paint = Paint()..color = const Color(0xFFCCCCCC);
      for (var x = 0.0; x < size.width; x += s) {
        for (var y = 0.0; y < size.height; y += s) {
          if (((x / s).floor() + (y / s).floor()).isEven) {
            canvas.drawRect(Rect.fromLTWH(x, y, s, s), paint);
          }
        }
      }
    }
    canvas.drawRect(
      rect,
      Paint()..shader = LinearGradient(colors: colors).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_TrackPainter old) =>
      old.channel != channel || old.color != color;
}
