/// Clay's pickers: the calendar (days pressed into the clay, the chosen one
/// a coral ball), the date and date-range fields that open it, the wheel (a
/// drum turning in a well over a raised row), the time picker made of
/// wheels, the time field typed in a well, and the colour picker.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'button.dart';
import 'fonts.dart';
import 'internal/corners.dart';
import 'internal/entry_parts.dart';
import 'internal/menu.dart';
import 'internal/words_fit.dart';
import 'select.dart' show ClayMenuReveal;
import 'surface.dart';
import 'theme.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A span of days, both ends counted.
@immutable
class ClayDateRange {
  /// The days from [start] to [end].
  ClayDateRange({required DateTime start, required DateTime end})
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
      other is ClayDateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'ClayDateRange($start – $end)';
}

/// A time of day (hour 0 to 23, minute); the reader's clock writes it with
/// `RawWidgetsLocalizations.of(context).formatTimeOfDay(time)`.
typedef ClayTime = RawTimeOfDay;

// [n] (0 to 99) as two figures in the reader's digits.
String _twoDigits(RawWidgetsLocalizations words, int n) => n < 10
    ? '${words.formatDecimal(0)}${words.formatDecimal(n)}'
    : words.formatDecimal(n);

/// A day's face: a coral ball for a chosen day (or a range's end), else
/// bare clay that dents under the pointer and presses in under a press.
ClayFace _dayFace(
  ClayColors c,
  Set<WidgetState> states, {
  required bool end,
  required double radius,
  Color? fill,
}) {
  final pressed = states.contains(WidgetState.pressed);
  final focus = states.contains(WidgetState.focused) ? 1.0 : 0.0;
  if (end) {
    final colour = fill ?? c.accent;
    return ClayFace.raised(c, color: colour, radius: radius).copyWith(
      elevation: 0.7,
      press: pressed ? 1 : 0,
      focus: focus,
      focusColor: c.onColor(colour),
    );
  }
  final well = ClayFace.well(c, radius: radius);
  final show = pressed
      ? 1.0
      : (states.contains(WidgetState.hovered) ? 0.5 : 0.0);
  return well.copyWith(
    color: well.color.withValues(alpha: well.color.a * show),
    lightOpacity: well.lightOpacity * show,
    shadeOpacity: well.shadeOpacity * show,
    focus: focus,
    focusColor: c.focus,
  );
}

/// A month calendar on clay: the month and its turning keys along the top,
/// the weekdays, the days as figures. The chosen day is a coral ball;
/// today's figure is coral with a dot under it; a range is a pale coral
/// groove between its two balls.
///
/// ```dart
/// ClayCalendar(firstDate: DateTime(2026), lastDate: DateTime(2027), selectedDate: DateTime(2026, 11, 19), onDateChanged: (day) {})
/// ```
class ClayCalendar extends StatefulWidget {
  /// A calendar choosing one day.
  const ClayCalendar({
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

  /// A calendar choosing a span of days: a first press its start, a second
  /// its end.
  const ClayCalendar.range({
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
  final ClayDateRange? selectedRange;

  /// A span chosen (once both ends are); null disables it.
  final ValueChanged<ClayDateRange>? onRangeChanged;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// Whether a day may be chosen; null: all between the bounds.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// How many months show side by side.
  final int months;

  /// Whether it takes the focus once built.
  final bool autofocus;

  /// Its own style, over [ClayThemeData.calendarStyle]: `fill` the chosen
  /// day's ball.
  final ClayStyle? style;

  final bool _range;

  @override
  State<ClayCalendar> createState() => _ClayCalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('selectedDate', selectedDate))
      ..add(DiagnosticsProperty<ClayDateRange>('selectedRange', selectedRange))
      ..add(FlagProperty('range', value: _range, ifTrue: 'range'));
  }
}

// How far a neighbouring month's day stands from the calendar's face: about
// Apple's other-month grey (3.3:1), clear of a faint figure, and less than
// half the month's own days.
const double _outsideDayContrast = 3;

class _ClayCalendarState extends State<ClayCalendar> {
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
  void didUpdateWidget(ClayCalendar old) {
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
      widget.onRangeChanged?.call(ClayDateRange(start: r.start, end: r.end!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final words = RawWidgetsLocalizations.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final layers = [widget.style, theme.calendarStyle];
    // The days' figures grow to twice their size and no further, as
    // Material's day grid caps them on a phone.
    final dayScaler = MediaQuery.textScalerOf(context).clamp(maxScaleFactor: 2);
    // A day is a finger's height at least (the touch floor, on every input,
    // as Material's day grid keeps its cells on a desk); its ball a little
    // less.
    final dayHeight = math.max(
      RawTapTargets.of(context).touch.height,
      dayScaler.scale(15) * 1.4 + 12,
    );
    final dayFontSize = theme.textTheme.body.fontSize ?? 16;
    // The widest day a month shows, in the reader's digits and the chosen
    // day's weight: every day is drawn at the one size that fits it, so 1
    // to 9 stand no bigger than 10 to 31.
    final widestDay = _widestDay(
      context,
      words,
      theme.textTheme.body.copyWith(
        fontWeight: FontWeight.w600,
        fontVariations: clayWeight(FontWeight.w600),
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      dayScaler,
    );
    const turnStyle = ClayStyle(
      minimumSize: WidgetStatePropertyAll(Size(40, 40)),
      iconSize: WidgetStatePropertyAll(18),
    );
    final band = Color.lerp(c.well, c.accent, 0.22)!;
    // A neighbouring month's day: a quiet tone of its own, lifted from the
    // disabled ink to [_outsideDayContrast] on the clay and the ground a
    // calendar sits on, well below the month's own days.
    final outside = RawPalette.readableTone(
      c.inkDisabled,
      on: [c.clay, c.ground],
      ratio: _outsideDayContrast,
    );
    // A month is at most 420 wide (its days at 60).
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth:
            widget.months * 420.0 + (widget.months - 1) * ClaySpacing.large,
      ),
      child: RawCalendarDatePicker(
        controller: _controller,
        months: widget.months,
        autofocus: widget.autofocus,
        onChanged: _changed,
        minDayWidth: 40,
        headerBuilder: (context, header) => Padding(
          padding: const EdgeInsets.only(bottom: ClaySpacing.small),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: ClaySpacing.small,
                  ),
                  child: Text(
                    header.label,
                    style: theme.textTheme.label.copyWith(color: c.ink),
                  ),
                ),
              ),
              ClayIconButton(
                onPressed: header.previous,
                tooltip: words.previousMonthTooltip,
                style: turnStyle,
                icon: Icon(
                  rtl ? LucideIcons.chevronRight : LucideIcons.chevronLeft,
                ),
              ),
              const SizedBox(width: ClaySpacing.small),
              ClayIconButton(
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
        weekdayBuilder: (context, weekday, label) => ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 28),
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.caption.copyWith(
                color: c.inkSecondary,
                fontWeight: FontWeight.w600,
                fontVariations: clayWeight(FontWeight.w600),
              ),
            ),
          ),
        ),
        monthsBuilder: (context, months) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, m) in months.indexed) ...[
              if (i > 0) const SizedBox(width: ClaySpacing.large),
              Expanded(child: m),
            ],
          ],
        ),
        dayBuilder: (context, day, states) {
          final layered = RawStyleOf(layers, states);
          // A waiting range's preview ends as a finished range does: a ball
          // on the day under the pointer (or the keys), the groove stopping
          // at it.
          final end =
              day.isRangeStart ||
              day.isRangeEnd ||
              day.isPreviewEnd ||
              (states.contains(WidgetState.selected) && !widget._range);
          final within = (day.inRange || day.inPreview) && !end;
          final range = _controller.selectedRange;
          final finished =
              widget._range && range?.end != null && range!.start != range.end;
          final bandFrom =
              day.isRangeStart &&
              (finished || (day.inPreview && !day.isPreviewEnd));
          final bandTo =
              (day.isRangeEnd && finished) ||
              (day.isPreviewEnd && !day.isRangeStart);
          final fill = layered.fill ?? c.accent;
          final ink = end
              ? c.onColor(fill)
              : !day.enabled
              ? c.inkDisabled
              // A neighbouring month's day takes a tap: its figure stands in
              // its own quiet tone, as Cupertino draws its secondary days.
              : !day.inMonth
              ? outside
              : day.isToday
              ? c.accentInk
              : c.ink;
          final weight = end || day.isToday ? FontWeight.w600 : FontWeight.w400;
          final ball = dayHeight - 4;
          return LayoutBuilder(
            builder: (context, box) {
              // The ball is as wide as the day, at most [ball]; its figures
              // keep 8 from its sides.
              final side = math.min(ball, math.min(box.maxWidth, dayHeight));
              final scaler = clayScalerToFit(
                dayScaler,
                fontSize: dayFontSize,
                widest: widestDay,
                room: side - 16,
              );
              return SizedBox(
                height: dayHeight,
                child: Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    // A range's groove runs behind its days, end to end; each
                    // day's piece reaches a pixel into its neighbours, so the
                    // days' fractional edges leave no seam.
                    if (within || bandFrom || bandTo)
                      PositionedDirectional(
                        top: 5,
                        bottom: 5,
                        start: bandFrom ? 20 : -1,
                        end: bandTo ? 20 : -1,
                        child: ColoredBox(color: band),
                      ),
                    Center(
                      child: ConstrainedBox(
                        constraints: BoxConstraints.loose(Size.square(ball)),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: AnimatedClaySurface(
                            face: _dayFace(
                              c,
                              states,
                              end: end,
                              radius: ball / 2,
                              fill: fill,
                            ),
                            // At a large text size the figures shrink to keep
                            // inside their ball, all of them alike, so a row's
                            // days never run together on a phone.
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Center(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    // The reader's digits: Arabic-Indic in
                                    // Arabic, as the month is named.
                                    day.label,
                                    maxLines: 1,
                                    softWrap: false,
                                    textScaler: scaler,
                                    style: theme.textTheme.body.copyWith(
                                      color: ink,
                                      fontWeight: weight,
                                      fontVariations: clayWeight(weight),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (day.isToday && !end)
                      Align(
                        alignment: const Alignment(0, 0.8),
                        child: SizedBox.square(
                          dimension: 4,
                          child: DecoratedBox(
                            decoration: ShapeDecoration(
                              shape: const CircleBorder(),
                              color: c.accentInk,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// The widest of a month's days, 1 to 31, as [words] writes them in [style]
// at [scaler].
double _widestDay(
  BuildContext context,
  RawWidgetsLocalizations words,
  TextStyle style,
  TextScaler scaler,
) {
  final painter = TextPainter(
    textDirection: Directionality.of(context),
    textScaler: scaler,
    locale: Localizations.maybeLocaleOf(context),
    maxLines: 1,
  );
  final drawn = DefaultTextStyle.of(context).style.merge(style);
  var widest = 0.0;
  for (var d = 1; d <= 31; d++) {
    painter
      ..text = TextSpan(text: words.formatDecimal(d), style: drawn)
      ..layout();
    widest = math.max(widest, painter.width);
  }
  painter.dispose();
  return widest;
}

/// The well a picker field shows its value in, with a clay ball at its end
/// that opens the picker.
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.anchor,
    required this.text,
    required this.hint,
    required this.icon,
    required this.enabled,
    required this.error,
    required this.semanticLabel,
    required this.styles,
    this.spoken,
  });

  final RawOverlayAnchor anchor;
  final String? text;

  /// What a screen reader hears for [text]; null: [text].
  final String? spoken;
  final String? hint;
  final IconData icon;
  final bool enabled;
  final bool error;
  final String? semanticLabel;
  final List<ClayStyle?> styles;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final height = theme.controlHeight;
    return RawButton(
      onPressed: enabled ? anchor.toggle : null,
      semanticLabel: semanticLabel,
      semanticValue: spoken ?? text,
      expanded: anchor.isOpen,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states, _) {
        final open = anchor.isOpen;
        final pressed = states.contains(WidgetState.pressed);
        final layered = RawStyleOf(styles, states);
        final well = clayEntryFace(
          theme,
          {
            ...states,
            if (open) WidgetState.focused,
            if (error) WidgetState.error,
          },
          fill: layered.fill,
          edge: layered.edge,
          radius: clayCornerRadius(theme, layered, RawCorner.medium),
        );
        final ball = height - 12;
        // Its height is a floor: a date on two lines makes the well taller.
        return ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: AnimatedClaySurface(
            face: well,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsetsDirectional.only(
                      start: ClaySpacing.regular,
                      end: ClaySpacing.small,
                      top: 6,
                      bottom: 6,
                    ),
                    child: RawCapCenter(
                      capHeightFactor: clayCapHeightFactor,
                      // A shown value is said once, as the key's value.
                      child: ExcludeSemantics(
                        excluding: text != null,
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
                                : layered.foreground ?? c.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(end: (height - ball) / 2),
                  child: SizedBox.square(
                    dimension: ball,
                    child: AnimatedClaySurface(
                      face: enabled
                          ? ClayFace.raised(c, radius: ball / 2).copyWith(
                              elevation: 0.7,
                              press: pressed || open ? 1 : 0,
                            )
                          : ClayFace.flat(c, radius: ball / 2),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 18,
                          color: !enabled
                              ? c.inkDisabled
                              : open
                              ? c.accentInk
                              : c.inkSecondary,
                        ),
                      ),
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
}) => ClayFieldDecorator(
  labelText: label,
  helperText: helper,
  errorText: error,
  enabled: enabled,
  child: box,
);

Widget _calendarPanel(BuildContext context, Widget calendar) => ClaySurface(
  face: clayMenuFace(ClayTheme.of(context)),
  child: SingleChildScrollView(
    primary: false,
    padding: const EdgeInsets.all(ClaySpacing.medium),
    child: calendar,
  ),
);

/// A date field that opens a month calendar on clay. Choosing a day closes
/// it and calls [onChanged].
///
/// ```dart
/// ClayDatePicker(labelText: 'Starts on', value: DateTime(2026, 11, 23), firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (day) {})
/// ```
class ClayDatePicker extends StatelessWidget {
  /// A date field at [value].
  const ClayDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
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
  final String? labelText;

  /// What the empty well says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// This field's own style, over [ClayThemeData.datePickerStyle]: `fill`
  /// the well, `edge` its focus rim, `foreground` the date, `shape` its
  /// corners.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final theme = ClayTheme.of(context);
    return _fieldColumn(
      label: labelText,
      enabled: enabled,
      helper: helperText,
      error: errorText,
      box: RawPopover(
        // The open month is named for what it is, not with the field's
        // label: the field already says its label.
        semanticLabel: words.datePickerHelpText,
        // The calendar wants its whole month before it picks a side: low on
        // a phone it opens above the field rather than below in a sliver.
        placement: const RawPopoverPlacement(
          gap: ClaySpacing.small,
          margin: ClaySpacing.small,
          fit: RawPopoverFit.whole,
          matchAnchorWidth: false,
        ),
        dampingRatio: ClayMotion.panelDamping,
        stiffness: ClayMotion.panelStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          // The day as the app's locale writes it ("Oct 2, 2026" in English),
          // said in full.
          text: value == null ? null : words.formatMediumDate(value!),
          spoken: value == null ? null : words.formatFullDate(value!),
          hint: hintText,
          icon: LucideIcons.calendar,
          enabled: enabled,
          error: errorText != null,
          // The field names it by its label; with none, its hint names it.
          semanticLabel: labelText == null ? hintText : null,
          styles: [style, theme.datePickerStyle],
        ),
        overlayBuilder: (context, info) => ClayMenuReveal(
          info: info,
          child: _calendarPanel(
            context,
            ClayCalendar(
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
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

/// A date-range field that opens a calendar: a first day and a last close
/// it and give the span to [onChanged]. Two months side by side where
/// there is room.
///
/// ```dart
/// ClayDateRangePicker(labelText: 'Break', value: null, firstDate: DateTime(2026), lastDate: DateTime(2027), onChanged: (range) {})
/// ```
class ClayDateRangePicker extends StatelessWidget {
  /// A date-range field at [value].
  const ClayDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText,
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
  });

  /// The chosen span.
  final ClayDateRange? value;

  /// A span chosen; null disables it.
  final ValueChanged<ClayDateRange>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The words above the well.
  final String? labelText;

  /// What the empty well says.
  final String? hintText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// This field's own style, over [ClayThemeData.dateRangePickerStyle]:
  /// `fill` the well, `edge` its focus rim, `foreground` the span, `shape`
  /// its corners.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final words = RawWidgetsLocalizations.of(context);
    final enabled = onChanged != null;
    final theme = ClayTheme.of(context);
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return _fieldColumn(
      label: labelText,
      enabled: enabled,
      helper: helperText,
      error: errorText,
      box: RawPopover(
        // The open month is named for what it is, not with the field's
        // label: the field already says its label.
        semanticLabel: words.datePickerHelpText,
        // The calendar wants its whole month before it picks a side: low on
        // a phone it opens above the field rather than below in a sliver.
        placement: const RawPopoverPlacement(
          gap: ClaySpacing.small,
          margin: ClaySpacing.small,
          fit: RawPopoverFit.whole,
          matchAnchorWidth: false,
        ),
        dampingRatio: ClayMotion.panelDamping,
        stiffness: ClayMotion.panelStiffness,
        anchorBuilder: (context, anchor) => _PickerField(
          anchor: anchor,
          text: value == null
              ? null
              : _rangeWords(words, value!, currentDate ?? DateTime.now()),
          hint: hintText,
          icon: LucideIcons.calendarRange,
          enabled: enabled,
          error: errorText != null,
          // The field names it by its label; with none, its hint names it.
          semanticLabel: labelText == null ? hintText : null,
          styles: [style, theme.dateRangePickerStyle],
        ),
        overlayBuilder: (context, info) => ClayMenuReveal(
          info: info,
          child: _calendarPanel(
            context,
            ClayCalendar.range(
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
    properties.add(DiagnosticsProperty<ClayDateRange>('value', value));
  }
}

// A drum's row height: 40, and taller at a large text size, so a row's
// figures keep clear of the next row's.
double _rowHeight(BuildContext context) =>
    math.max(40, MediaQuery.textScalerOf(context).scale(18) * 1.25 + 12);

/// Clay's drums on ui_core's wheel picker: each column turns in the well,
/// its chosen row standing on a raised clay pill across the middle (one
/// pill under every column of a [shared] wheel, read as one row).
Widget _drums(
  BuildContext context, {
  required List<RawPickerColumn> columns,
  required List<int> selection,
  required ValueChanged<List<int>>? onChanged,
  required int rows,
  required double width,
  required bool shared,
  String? semanticLabel,
  Widget Function(BuildContext context, List<Widget> columns)? layout,
  RawStyleOf? layered,
}) {
  final theme = ClayTheme.of(context);
  final c = theme.colors;
  final row = _rowHeight(context);
  return RawPicker(
    columns: (_) => columns,
    selection: selection,
    onChanged: onChanged,
    itemExtent: row,
    visibleItemCount: rows,
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
              ? layered?.foreground ?? c.ink
              : c.inkSecondary,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    ),
    columnBuilder: (context, column, wheel) => SizedBox(
      width: width,
      height: row * rows,
      child: Stack(
        children: [
          // The pill the chosen row stands on: under a shared wheel's
          // columns it is drawn once, round them all; here only its focus.
          Center(
            child: SizedBox(
              width: double.infinity,
              height: row,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClaySpacing.tight,
                ),
                child: AnimatedClaySurface(
                  face: shared
                      ? ClayFace.flat(c, radius: 14).copyWith(
                          color: c.clay.withValues(alpha: 0),
                          shadowOpacity: 0,
                          lightOpacity: 0,
                          shadeOpacity: 0,
                          focus: column.states.contains(WidgetState.focused)
                              ? 1
                              : 0,
                          focusColor: c.focus,
                        )
                      : _pill(c, column.states, layered?.fill),
                ),
              ),
            ),
          ),
          wheel,
        ],
      ),
    ),
  );
}

ClayFace _pill(ClayColors c, Set<WidgetState> states, [Color? fill]) =>
    ClayFace.raised(c, color: fill ?? c.risen, radius: 14).copyWith(
      elevation: 0.6,
      focus: states.contains(WidgetState.focused) ? 1 : 0,
      focusColor: c.focus,
    );

// The drums stand in the middle of their well, however wide it is laid.
// A range in a field: each end as a day and a month, as a calendar writes a
// holiday, so a week fits a phone's well; the year beside each end only when
// the range leaves this year.
String _rangeWords(
  RawWidgetsLocalizations words,
  ClayDateRange range,
  DateTime today,
) {
  final start = range.start;
  final end = range.end;
  if (start.year == today.year && end.year == today.year) {
    return '${words.formatShortMonthDay(start)} – '
        '${words.formatShortMonthDay(end)}';
  }
  return '${words.formatShortMonthDay(start)} ${words.formatYear(start)} – '
      '${words.formatShortMonthDay(end)} ${words.formatYear(end)}';
}

Widget _drumWell(ClayThemeData theme, Widget child) => ClaySurface(
  face: ClayFace.well(theme.colors, radius: theme.shapeScheme.corners.large),
  child: Padding(
    padding: const EdgeInsets.all(ClaySpacing.tight),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(theme.shapeScheme.corners.large - 4),
      // The drums keep their width; in a box narrower than that they draw
      // smaller, whole, rather than run past the well's edge.
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: FittedBox(fit: BoxFit.scaleDown, child: child),
      ),
    ),
  ),
);

/// A wheel: a drum of [items] turning in a well, the chosen one standing on
/// a raised clay pill across the middle. A drag or a fling turns it; Up and
/// Down turn it a row.
///
/// ```dart
/// ClayWheelPicker<int>(items: const [5, 10, 15, 20, 30], value: 10, labelOf: (n) => '$n min', onChanged: (n) {}, semanticLabel: 'Duration')
/// ```
class ClayWheelPicker<T> extends StatelessWidget {
  /// A wheel of [items] at [value].
  const ClayWheelPicker({
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

  /// This wheel's own style, over [ClayThemeData.wheelPickerStyle]: `fill`
  /// the pill the chosen row stands on, `foreground` its words.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final at = math.max(0, items.indexOf(value));
    return _drumWell(
      theme,
      _drums(
        context,
        columns: [
          RawPickerColumn(
            itemCount: items.length,
            itemLabel: (i) => labelOf(items[i]),
            semanticLabel: semanticLabel,
          ),
        ],
        selection: [at],
        rows: visibleRows,
        width: width,
        shared: false,
        layered: RawStyleOf([style, theme.wheelPickerStyle], const {}),
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
/// day, on a 12-hour clock) in one well, the time standing on one pill.
///
/// ```dart
/// ClayTimePicker(value: const ClayTime(hour: 7, minute: 30), onChanged: (time) {})
/// ```
class ClayTimePicker extends StatelessWidget {
  /// A time picker at [value].
  const ClayTimePicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.minuteInterval = 5,
    this.semanticLabel,
    this.style,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0);

  /// The chosen time.
  final ClayTime value;

  /// A time chosen; null disables it.
  final ValueChanged<ClayTime>? onChanged;

  /// The minutes it steps by.
  final int minuteInterval;

  /// What a screen reader calls it.
  final String? semanticLabel;

  /// This picker's own style, over [ClayThemeData.timePickerStyle]: `fill`
  /// the pill the time stands on, `foreground` its figures.
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([style, theme.timePickerStyle], const {});
    final h24 = MediaQuery.maybeAlwaysUse24HourFormatOf(context) ?? false;
    final minutes = [for (var m = 0; m < 60; m += minuteInterval) m];
    final minuteAt = math.max(0, minutes.indexWhere((m) => m >= value.minute));
    final pill = _pill(c, const {}, layered.fill);
    // The colon is read with the time: secondary words, as dark (or as light)
    // as reading on the pill takes, with a little to spare for the light the
    // pill's face catches round it.
    final colon = Text(
      ':',
      style: theme.textTheme.title.copyWith(
        color: RawPalette.readableTone(
          c.inkSecondary,
          on: [pill.color],
          ratio: 4.6,
        ),
      ),
    );
    final words = RawWidgetsLocalizations.of(context);
    final columns = [
      if (h24)
        RawPickerColumn(
          itemCount: 24,
          itemLabel: (h) => _twoDigits(words, h),
          semanticLabel: words.timePickerHourLabel,
        )
      else
        RawPickerColumn(
          itemCount: 12,
          itemLabel: (i) => words.formatDecimal(i + 1),
          semanticLabel: words.timePickerHourLabel,
        ),
      RawPickerColumn(
        itemCount: minutes.length,
        itemLabel: (i) => _twoDigits(words, minutes[i]),
        semanticLabel: words.timePickerMinuteLabel,
      ),
      if (!h24)
        RawPickerColumn(
          itemCount: 2,
          itemLabel: (i) => i == 0
              ? words.anteMeridiemAbbreviation
              : words.postMeridiemAbbreviation,
          semanticLabel: words.timeFieldDayPeriodLabel,
        ),
    ];
    final selection = [
      if (h24) value.hour else value.hourOfPeriod - 1,
      minuteAt,
      if (!h24) value.isPm ? 1 : 0,
    ];
    ClayTime timeOf(List<int> picked) {
      final minute = minutes[picked[1]];
      if (h24) return ClayTime(hour: picked[0], minute: minute);
      final hour = (picked[0] + 1) % 12 + (picked[2] == 1 ? 12 : 0);
      return ClayTime(hour: hour, minute: minute);
    }

    final change = onChanged;
    return _drumWell(
      theme,
      Directionality(
        // A clock reads hour then minute in every language.
        textDirection: TextDirection.ltr,
        child: Stack(
          children: [
            // One pill under the hour, the minute and the half of the day:
            // the time is read as one row.
            Positioned.fill(
              child: Center(
                child: SizedBox(
                  width: double.infinity,
                  height: _rowHeight(context),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: ClaySpacing.tight,
                    ),
                    child: ClaySurface(face: pill),
                  ),
                ),
              ),
            ),
            _drums(
              context,
              columns: columns,
              selection: selection,
              rows: 5,
              // 64 a column, wider at a large text size: its widest figure
              // (AM, PM) keeps 12 clear of each side, inside the pill.
              width: math.max(
                64,
                clayWidestWord(
                      context,
                      [
                        for (final col in columns)
                          for (var i = 0; i < col.itemCount; i++)
                            col.itemLabel(i),
                      ],
                      theme.textTheme.title.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      whole: true,
                    ) +
                    2 * ClaySpacing.medium,
              ),
              shared: true,
              layered: layered,
              semanticLabel: semanticLabel,
              layout: (context, drums) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [drums[0], colon, ...drums.skip(1)],
              ),
              onChanged: change == null
                  ? null
                  : (picked) => change(timeOf(picked)),
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
      ..add(DiagnosticsProperty<ClayTime>('value', value))
      ..add(IntProperty('minuteInterval', minuteInterval));
  }
}

/// A time typed in a well: the hour, the minute (and the half of the day)
/// as segments, each raised on a small pill while the keys are on it. Up
/// and Down step a segment; typing fills it and moves on.
///
/// ```dart
/// ClayTimeField(labelText: 'Remind me at', value: const ClayTime(hour: 7, minute: 30), onChanged: (time) {})
/// ```
class ClayTimeField extends StatelessWidget {
  /// A time field at [value].
  const ClayTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.showSeconds = false,
    this.autofocus = false,
    this.style,
  });

  /// The time; null for none yet.
  final ClayTime? value;

  /// A time typed; null turns the field off.
  final ValueChanged<ClayTime?>? onChanged;

  /// The words above the well.
  final String? labelText;

  /// Help under the well.
  final String? helperText;

  /// What is wrong, under the well.
  final String? errorText;

  /// Whether it takes seconds too.
  final bool showSeconds;

  /// Whether it takes the focus when it first shows.
  final bool autofocus;

  /// This field's own style, over [ClayThemeData.timeFieldStyle].
  final ClayStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final enabled = onChanged != null;
    // The pills, and the well round them, grow by as much as the figures'
    // line grows at a large text size, as a text field's well grows round
    // its words.
    double lineAt(TextScaler scaler) {
      final painter = TextPainter(
        text: TextSpan(text: '0', style: theme.textTheme.body),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
      );
      final line = painter.preferredLineHeight;
      painter.dispose();
      return line;
    }

    final grown = math.max(
      0.0,
      lineAt(MediaQuery.textScalerOf(context)) - lineAt(TextScaler.noScaling),
    );
    final pill = theme.controlHeight - 12 + grown;
    final height = theme.controlHeight + grown;
    return _fieldColumn(
      label: labelText,
      enabled: enabled,
      helper: helperText,
      error: errorText,
      // The well fills its column as every field's does; the time sits at
      // its start and the clock at its end.
      box: RawTimeField(
        value: value,
        onChanged: onChanged,
        showSeconds: showSeconds,
        autofocus: autofocus,
        semanticLabel: labelText,
        frameBuilder: (context, states, segments) {
          final layered = RawStyleOf([style, theme.timeFieldStyle], states);
          return SizedBox(
            height: height,
            child: AnimatedClaySurface(
              face: clayEntryFace(
                theme,
                {...states, if (errorText != null) WidgetState.error},
                fill: layered.fill,
                edge: layered.edge,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: ClaySpacing.tight,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: segments,
                      ),
                    ),
                    const SizedBox(width: ClaySpacing.small),
                    Icon(
                      LucideIcons.clock,
                      size: 18,
                      color: enabled ? c.inkSecondary : c.inkDisabled,
                    ),
                    const SizedBox(width: ClaySpacing.small),
                  ],
                ),
              ),
            ),
          );
        },
        literalBuilder: (context, literal) => Text(
          literal,
          style: theme.textTheme.body.copyWith(color: c.inkSecondary),
        ),
        segmentBuilder: (context, segment) {
          final focused = segment.states.contains(WidgetState.focused);
          // Each segment takes a finger's tap (the touch floor wide, the
          // well's height) round a pill that fits its figures.
          return MouseRegion(
            cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: RawTapTargets.of(context).touch.width,
              ),
              child: SizedBox(
                height: height,
                child: Center(
                  widthFactor: 1,
                  child: SizedBox(
                    height: pill,
                    child: AnimatedClaySurface(
                      face: focused
                          ? _pill(c, const {}).copyWith(radius: 10)
                          : ClayFace.flat(c, radius: 10).copyWith(
                              color: c.clay.withValues(alpha: 0),
                              shadowOpacity: 0,
                              lightOpacity: 0,
                              shadeOpacity: 0,
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: ClaySpacing.small,
                        ),
                        child: Center(
                          widthFactor: 1,
                          child: Text(
                            segment.text,
                            style: theme.textTheme.body.copyWith(
                              color: !enabled
                                  ? c.inkDisabled
                                  : segment.isPlaceholder
                                  ? c.inkSecondary
                                  : c.ink,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
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
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ClayTime>('value', value));
  }
}

/// A colour picker: the hue's shades pressed into a well, grooves for the
/// hue (and the opacity), each with a white clay ball holding the colour,
/// and the colour itself on a raised ball with its hex code.
///
/// ```dart
/// ClayColorPicker(value: const Color(0xFFF08A6B), onChanged: (color) {})
/// ```
class ClayColorPicker extends StatefulWidget {
  /// A colour picker at [value].
  const ClayColorPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.showAlpha = false,
    this.style,
  });

  /// The colour.
  final Color value;

  /// A colour chosen.
  final ValueChanged<Color> onChanged;

  /// Whether the opacity can change.
  final bool showAlpha;

  /// This picker's own style, over [ClayThemeData.colorPickerStyle]: `fill`
  /// the clay its balls are moulded in, `foreground` the hex words.
  final ClayStyle? style;

  @override
  State<ClayColorPicker> createState() => _ClayColorPickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(ColorProperty('value', value))
      ..add(FlagProperty('showAlpha', value: showAlpha, ifTrue: 'alpha'));
  }
}

class _ClayColorPickerState extends State<ClayColorPicker> {
  late final RawColorController _controller = RawColorController(widget.value)
    ..addListener(_changed);

  void _changed() {
    if (_controller.color != widget.value) widget.onChanged(_controller.color);
  }

  @override
  void didUpdateWidget(ClayColorPicker old) {
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

  Widget _ball(
    ClayColors c,
    Set<WidgetState> states,
    Color fill, {
    Color? clay,
  }) => Center(
    child: SizedBox.square(
      dimension: 26,
      child: AnimatedClaySurface(
        face: ClayFace.raised(c, color: clay, radius: 13).copyWith(
          press: states.contains(WidgetState.pressed) ? 1 : 0,
          focus: states.contains(WidgetState.focused) ? 1 : 0,
          focusColor: c.focus,
        ),
        child: Padding(
          padding: const EdgeInsets.all(ClaySpacing.tight),
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
              color: fill,
            ),
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = ClayTheme.of(context);
    final c = theme.colors;
    final layered = RawStyleOf([
      widget.style,
      theme.colorPickerStyle,
    ], const {});
    return RawColorPicker(
      controller: _controller,
      showAlpha: widget.showAlpha,
      areaHeight: 180,
      areaBuilder: (context, area) => ClaySurface(
        face: ClayFace.well(c, radius: theme.shapeScheme.corners.medium),
        child: Padding(
          padding: const EdgeInsets.all(ClaySpacing.tight),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              theme.shapeScheme.corners.medium - 4,
            ),
            child: CustomPaint(
              painter: _AreaPainter(area.color.hue),
              size: Size.infinite,
            ),
          ),
        ),
      ),
      areaThumbBuilder: (context, area) => _ball(
        c,
        area.states,
        area.color.toColor().withValues(alpha: 1),
        clay: layered.fill,
      ),
      trackBuilder: (context, channel, color) => Center(
        child: SizedBox(
          height: 16,
          child: ClaySurface(
            face: ClayFace.well(c, radius: 8),
            child: Padding(
              padding: const EdgeInsets.all(ClaySpacing.hairline),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8 - ClaySpacing.hairline),
                child: CustomPaint(
                  painter: _TrackPainter(channel, color),
                  size: Size.infinite,
                ),
              ),
            ),
          ),
        ),
      ),
      thumbBuilder: (context, states) => _ball(
        c,
        states,
        _controller.color.withValues(alpha: 1),
        clay: layered.fill,
      ),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, part) in parts.indexed) ...[
            if (i > 0) const SizedBox(height: ClaySpacing.medium),
            part,
          ],
          const SizedBox(height: ClaySpacing.medium),
          ValueListenableBuilder<HSVColor>(
            valueListenable: _controller,
            builder: (context, hsv, _) => Row(
              children: [
                SizedBox.square(
                  dimension: 36,
                  child: ClaySurface(
                    face: ClayFace.raised(c, color: hsv.toColor(), radius: 18),
                  ),
                ),
                const SizedBox(width: ClaySpacing.medium),
                Text(
                  _controller.hex,
                  style: theme.textTheme.body.copyWith(
                    color: layered.foreground ?? c.ink,
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

  final RawColorChannel channel;
  final HSVColor color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final colors = switch (channel) {
      RawColorChannel.hue => [
        for (var h = 0; h <= 360; h += 60)
          HSVColor.fromAHSV(1, h.toDouble(), 1, 1).toColor(),
      ],
      RawColorChannel.saturation => [
        color.withSaturation(0).withAlpha(1).toColor(),
        color.withSaturation(1).withAlpha(1).toColor(),
      ],
      RawColorChannel.brightness => [
        const Color(0xFF000000),
        color.withValue(1).withAlpha(1).toColor(),
      ],
      RawColorChannel.alpha => [
        color.withAlpha(0).toColor(),
        color.withAlpha(1).toColor(),
      ],
    };
    if (channel == RawColorChannel.alpha) {
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
