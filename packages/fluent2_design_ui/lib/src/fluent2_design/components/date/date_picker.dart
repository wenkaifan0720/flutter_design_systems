import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart' show MaterialLocalizations;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../../icons.dart';
import '../../internal/cap_label.dart';
import '../../internal/measure.dart';
import '../../internal/well.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../input/field_core.dart';
import '../pressable/pressable.dart';
import '../sheet.dart';

// The calendar's own idea of a day: midnight, local, as its controller holds one.
DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

double _dayGrowth(BuildContext context) {
  final style = context.fluent2Theme.body1Strong;
  final size = style.fontSize!;
  return math.max(0, MediaQuery.textScalerOf(context).scale(size) - size) *
      (style.height ?? 1);
}

/// A month calendar with a single selected date and optional marked days.
///
/// Arrow keys move by a day or week. Home and End move to the ends of the
/// week. Page Up and Page Down change the month, or the year with Shift.
/// Enter or Space selects the focused day.
///
/// ```dart
/// Fluent2Calendar(value: due, marks: {DateTime(2026, 11, 12)}, onChanged: (d) => setState(() => due = d))
/// ```
class Fluent2Calendar extends StatefulWidget {
  /// A month calendar showing [value].
  const Fluent2Calendar({
    required this.value,
    this.onChanged,
    this.month,
    this.today,
    this.firstDate,
    this.lastDate,
    this.marks = const {},
    this.showAdjacent = true,
    this.focusNode,
    super.key,
  });

  /// The selected day, or null for an empty selection.
  final DateTime? value;

  /// Called when the user selects a day. A null callback disables selection.
  final ValueChanged<DateTime>? onChanged;

  /// The initial month. Defaults to the month of [value] or [today].
  final DateTime? month;

  /// The date highlighted as today. Defaults to the current date.
  final DateTime? today;

  /// The earliest day that can be picked; null sets no bound.
  final DateTime? firstDate;

  /// The latest day that can be picked; null sets no bound.
  final DateTime? lastDate;

  /// Dates shown with a dot below the day number.
  final Set<DateTime> marks;

  /// Draw the last and next months' days round the month.
  final bool showAdjacent;

  /// The focus node for the day grid. The calendar supplies one when omitted.
  final FocusNode? focusNode;

  @override
  State<Fluent2Calendar> createState() => _Fluent2CalendarState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>?>.has('onChanged', onChanged),
      )
      ..add(DiagnosticsProperty<DateTime>('month', month, defaultValue: null))
      ..add(DiagnosticsProperty<DateTime>('today', today, defaultValue: null))
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
      ..add(IterableProperty<DateTime>('marks', marks, defaultValue: const {}))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(
        FlagProperty(
          'showAdjacent',
          value: showAdjacent,
          ifFalse: 'showAdjacent: false',
        ),
      );
  }
}

class _Fluent2CalendarState extends State<Fluent2Calendar> {
  late DesignCalendarController _cal = _make();

  // A calendar with no onChanged only shows: nothing in it can be chosen.
  static bool _never(DateTime _) => false;

  DesignCalendarController _make({DateTime? month}) => DesignCalendarController(
    firstDate: widget.firstDate ?? DateTime(1900),
    lastDate: widget.lastDate ?? DateTime(2199, 12, 31),
    initialMonth: month ?? widget.month,
    selectedDate: widget.value,
    currentDate: widget.today,
    selectable: widget.onChanged == null ? _never : null,
  );

  bool _inBounds(DateTime d) =>
      (widget.firstDate == null || !d.isBefore(_day(widget.firstDate!))) &&
      (widget.lastDate == null || !d.isAfter(_day(widget.lastDate!)));

  @override
  void didUpdateWidget(Fluent2Calendar old) {
    super.didUpdateWidget(old);
    final bounds =
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate ||
        old.today != widget.today ||
        (old.onChanged == null) != (widget.onChanged == null);
    final value = widget.value;
    final held = _cal.selectedDate;
    final drifted = value == null
        ? held != null
        : held == null || _day(value) != held;
    if (!bounds && !drifted) return;
    // The grid lets go of the old model as it rebuilds; free it after.
    final before = _cal;
    WidgetsBinding.instance.addPostFrameCallback((_) => before.dispose());
    if (drifted && value != null) {
      // A day chosen from outside: show its month, the keyboard on it.
      _cal = _make();
    } else {
      _cal = _make(month: before.month)..focus(before.focusedDay);
    }
  }

  @override
  void dispose() {
    _cal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final words = MaterialLocalizations.of(context);
    final wide = Fluent2Layout.popsOver(context);
    final marks = {for (final m in widget.marks) _day(m)};
    final change = widget.onChanged;
    String dayLabel(DateTime d) {
      final full = words.formatFullDate(d);
      return marks.contains(_day(d)) ? '$full, marked' : full;
    }

    // Under a finger a day is a whole target (48) square where seven fit,
    // else its seventh of the room: a day never reaches into its
    // neighbour's, where a tap would go to the wrong day.
    final touch = Fluent2Layout.padded(context);
    const target = Fluent2Layout.touchHitTarget;
    // The month buttons come before the grid, as they stand over it (the
    // grid's one focus spans the header too, so reading order alone would
    // put it first).
    Widget first(Widget button) =>
        FocusTraversalOrder(order: const NumericFocusOrder(0), child: button);
    return LayoutBuilder(
      builder: (context, box) {
        final room = box.maxWidth.isFinite ? box.maxWidth : 7 * 40.0;
        // A whole even number of pixels, so the disc and its day's number
        // sit on whole pixels in it rather than straddling one.
        double even(double v) => (v / 2).floorToDouble() * 2;
        final growth = _dayGrowth(context);
        final usualCell = touch
            ? math.min(target, even(room / 7))
            : wide
            ? 32.0
            : even((room / 7).clamp(32.0, 44.0));
        final cell = even(math.min(room / 7, usualCell + growth));
        final disc = math.max(
          0.0,
          math.min(cell - 4, (wide && !touch ? 28.0 : 40.0) + growth),
        );
        return FocusTraversalGroup(
          policy: OrderedTraversalPolicy(),
          child: SizedBox(
            width: cell * 7,
            child: FocusTraversalOrder(
              order: const NumericFocusOrder(1),
              child: DesignCalendar(
                controller: _cal,
                focusNode: widget.focusNode,
                // The week starts where the app's localizations say
                // (DesignLocalizations.firstDayOfWeek; English is Sunday).
                showOutsideDays: widget.showAdjacent,
                onChanged: change == null
                    ? null
                    : (day) => change(_cal.selectedDate ?? day),
                monthLabel: words.formatMonthYear,
                dayLabel: dayLabel,
                weekdayLabel: (weekday) => words.narrowWeekdays[weekday % 7],
                headerBuilder: (context, h) => Padding(
                  padding: const EdgeInsets.only(bottom: Fluent2Spacing.s),
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            start: Fluent2Spacing.xs,
                          ),
                          child: Text(h.label, style: t.body1Strong),
                        ),
                      ),
                      first(
                        Fluent2IconButton(
                          Fluent2Icons.arrowUp,
                          label: DesignLocalizations.of(context)
                              .previousMonthTooltip,
                          size: Fluent2ButtonSize.small,
                          onPressed: h.previous,
                        ),
                      ),
                      const SizedBox(width: Fluent2Spacing.xs),
                      first(
                        Fluent2IconButton(
                          Fluent2Icons.arrowDown,
                          label: DesignLocalizations.of(context)
                              .nextMonthTooltip,
                          size: Fluent2ButtonSize.small,
                          onPressed: h.next,
                        ),
                      ),
                    ],
                  ),
                ),
                weekdayBuilder: (context, weekday, label) => Padding(
                  padding: const EdgeInsets.only(bottom: Fluent2Spacing.xs),
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: t.caption1Strong.c(c.neutralForeground2),
                  ),
                ),
                dayBuilder: (context, day, states) => _Day(
                  day: day,
                  states: states,
                  cell: cell,
                  disc: disc,
                  marked: marks.contains(day.date),
                  live: change == null ? _inBounds(day.date) : day.enabled,
                  shows: change == null,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One day's circle for the kit's grid: [live] is whether it can be chosen
/// (or, in a calendar that only [shows], whether it is in bounds).
class _Day extends StatelessWidget {
  const _Day({
    required this.day,
    required this.states,
    required this.cell,
    required this.disc,
    required this.marked,
    required this.live,
    required this.shows,
  });

  final DesignCalendarDay day;
  final Set<WidgetState> states;
  final double cell;
  final double disc;
  final bool marked;
  final bool live;
  final bool shows;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final date = day.date;
    final outside = !day.inMonth;
    final isToday = day.isToday;
    final chosen = day.selected;
    final press = shows ? Fluent2Press.rest : states.press;
    final off = !live;
    final Color fill;
    final Color ink;
    if (isToday && !off) {
      fill = press.pick(
        c.brandBackground,
        c.brandBackgroundHover,
        c.brandBackgroundPressed,
      );
      ink = c.neutralForegroundOnBrand;
    } else if (chosen && !off) {
      // The tint a shade deeper where the page would swallow it.
      fill = fluent2BrandWell(t, press);
      ink = c.brandForeground2;
    } else {
      fill = press.pick(
        c.transparentBackground,
        fluent2Step(t, c.subtleBackgroundHover),
        fluent2Step(t, c.subtleBackgroundPressed),
        c.transparentBackground,
      );
      ink = off
          ? c.neutralForegroundDisabled
          : outside
          ? c.neutralForeground3
          : c.neutralForeground1;
    }
    final type = (isToday || chosen) ? t.body1Strong : t.body1;
    return SizedBox(
      width: cell,
      height: cell,
      child: Center(
        child: Container(
          width: disc,
          height: disc,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: chosen && isToday
                ? Border.all(color: c.neutralForegroundOnBrand)
                : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Text(
                '${date.day}',
                maxLines: 1,
                softWrap: false,
                style: type.c(ink).tabular,
              ),
              if (marked)
                Positioned(
                  bottom: disc * 0.12,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isToday
                          ? c.neutralForegroundOnBrand
                          : off
                          ? c.neutralForegroundDisabled
                          : c.brandForeground1,
                    ),
                  ),
                ),
              // The kit's grid holds the keyboard; the day it is on wears
              // the ring.
              if (states.contains(WidgetState.focused))
                Positioned.fill(
                  child: IgnorePointer(
                    child: Fluent2FocusRing(radius: disc / 2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A date field that opens a [Fluent2Calendar].
///
/// The field displays the formatted [value] or its [hint] when empty. A
/// desktop or tablet opens a popover with keyboard focus in the calendar.
/// Escape closes the popover and returns focus to the field. A touch phone
/// opens a bottom sheet titled [label]. Selecting a day calls [onChanged]
/// and closes the calendar. A null callback disables the field.
///
/// ```dart
/// Fluent2DatePicker(label: 'Due date', value: due, onChanged: (d) => setState(() => due = d))
/// ```
class Fluent2DatePicker extends StatefulWidget {
  /// A date field showing [value] that opens a calendar.
  const Fluent2DatePicker({
    required this.value,
    required this.onChanged,
    this.label,
    this.hint,
    this.firstDate,
    this.lastDate,
    this.today,
    this.format,
    this.appearance = Fluent2InputAppearance.outline,
    this.size = Fluent2InputSize.medium,
    this.invalid = false,
    this.focusNode,
    this.autofocus = false,
    this.style,
    super.key,
  });

  /// This field's own look, slot by slot, over the text field theme
  /// ([Fluent2ThemeData.textFieldTheme]): the slots [Fluent2FieldFrame]
  /// names.
  final Fluent2Style? style;

  /// The chosen day; null shows the hint.
  final DateTime? value;

  /// Called with the day the user picks; null puts it out of use.
  final ValueChanged<DateTime>? onChanged;

  /// What a screen reader calls the field; null reads the surrounding form
  /// field's label.
  final String? label;

  /// The words before a date is chosen; null is "Select a date..." in the
  /// app's language.
  final String? hint;

  /// The earliest day that can be picked; null sets no bound.
  final DateTime? firstDate;

  /// The latest day that can be picked; null sets no bound.
  final DateTime? lastDate;

  /// The day the calendar marks as today; null is the clock's.
  final DateTime? today;

  /// The words for a date; null is the locale's short date (Nov 4, 2026).
  final String Function(DateTime date)? format;

  /// {@macro fluent2.appearance}
  final Fluent2InputAppearance appearance;

  /// Fluent's `size`: how large it is drawn.
  final Fluent2InputSize size;

  /// {@template fluent2.invalid}
  /// Whether it shows Fluent's invalid state, its edge in the danger colour.
  /// {@endtemplate}
  final bool invalid;

  /// {@macro fluent2.focusNode}
  final FocusNode? focusNode;

  /// {@macro fluent2.autofocus}
  final bool autofocus;

  @override
  State<Fluent2DatePicker> createState() => _Fluent2DatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<Fluent2Style>('style', style, defaultValue: null),
    );
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>?>.has('onChanged', onChanged),
      )
      ..add(StringProperty('label', label, defaultValue: null))
      ..add(StringProperty('hint', hint, defaultValue: null))
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
      ..add(DiagnosticsProperty<DateTime>('today', today, defaultValue: null))
      ..add(
        ObjectFlagProperty<String Function(DateTime date)?>.has(
          'format',
          format,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputAppearance>(
          'appearance',
          appearance,
          defaultValue: Fluent2InputAppearance.outline,
        ),
      )
      ..add(
        EnumProperty<Fluent2InputSize>(
          'size',
          size,
          defaultValue: Fluent2InputSize.medium,
        ),
      )
      ..add(FlagProperty('invalid', value: invalid, ifTrue: 'invalid'))
      ..add(
        DiagnosticsProperty<FocusNode>(
          'focusNode',
          focusNode,
          defaultValue: null,
        ),
      )
      ..add(FlagProperty('autofocus', value: autofocus, ifTrue: 'autofocus'));
  }
}

class _Fluent2DatePickerState extends State<Fluent2DatePicker> {
  final _portal = OverlayPortalController();
  final _gridFocus = FocusNode(debugLabel: 'date picker calendar');
  FocusNode? _ownFocus;
  FocusNode get _focus =>
      widget.focusNode ?? (_ownFocus ??= FocusNode(debugLabel: 'date picker'));

  @override
  void dispose() {
    _gridFocus.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  String? get _name =>
      widget.label ?? Fluent2FieldScope.maybeOf(context)?.label;

  String get _hint =>
      widget.hint ?? Fluent2Localizations.of(context).selectADate;

  void _pick(DateTime d) {
    if (_portal.isShowing) setState(_portal.hide);
    _focus.requestFocus();
    widget.onChanged?.call(d);
  }

  Future<void> _open() async {
    if (Fluent2Layout.popsOver(context)) {
      if (_portal.isShowing) {
        setState(_portal.hide);
      } else {
        setState(_portal.show);
        _gridFocus.requestFocus();
      }
      return;
    }
    final picked = await Fluent2Sheet.show<DateTime>(
      context,
      title: _name ?? Fluent2Localizations.of(context).chooseDate,
      builder: (sheetContext) => [
        Center(
          child: Fluent2Calendar(
            value: widget.value,
            today: widget.today,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            onChanged: (d) => Navigator.of(sheetContext).pop(d),
          ),
        ),
      ],
    );
    if (mounted && picked != null) widget.onChanged?.call(picked);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final c = t.colors;
    final live = widget.onChanged != null;
    final m = Fluent2FieldMetrics.of(widget.size);
    final value = widget.value;
    final words = value == null
        ? null
        : widget.format?.call(value) ??
              MaterialLocalizations.of(context).formatShortDate(value);
    final type = Fluent2FieldMetrics.typeOf(t, widget.size);
    final open = _portal.isShowing;
    // From 600 it keeps its own width, as a select does: its words (the
    // hint, or a long date) with its room and glyph, at least 250.
    final content =
        2 +
        m.combined +
        fluent2WordsWidth(context, [
          _hint,
          ?words,
          MaterialLocalizations.of(context)
              .formatShortDate(DateTime(2026, 12, 28)),
        ], type) +
        m.inner +
        m.gap +
        m.glyph +
        m.root;
    return fluent2KeepsOwnWidth(
      context,
      content: content,
      child: Fluent2FieldPopover(
        controller: _portal,
        width: 7 * (32 + _dayGrowth(context)) + 2 * Fluent2Spacing.m + 2,
        onDismiss: () => setState(_portal.hide),
        popover: (context) => Fluent2PopoverSurface(
          padding: const EdgeInsets.all(Fluent2Spacing.m),
          child: CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.escape): () {
                setState(_portal.hide);
                _focus.requestFocus();
              },
            },
            // In a window too short for the whole month (a tablet on its
            // side, its touch-tall header), the calendar scrolls rather
            // than run past the popover.
            child: SingleChildScrollView(
              child: Fluent2Calendar(
                focusNode: _gridFocus,
                value: widget.value,
                today: widget.today,
                firstDate: widget.firstDate,
                lastDate: widget.lastDate,
                onChanged: _pick,
              ),
            ),
          ),
        ),
        child: DesignTapTarget(
          minSize: Fluent2Layout.tapFloorOf(context),
          child: Fluent2FieldButton(
            autofocus: widget.autofocus,
            onOpen: live ? _open : null,
            label: _name ?? _hint,
            value: words,
            hint: Fluent2Localizations.of(context).opensCalendar,
            expanded: open,
            focusNode: _focus,
            builder: (context, focused, pressed) => Fluent2FieldFrame(
              appearance: widget.appearance,
              style: widget.style,
              focused: focused || open,
              enabled: live,
              pressed: pressed,
              invalid:
                  widget.invalid ||
                  (Fluent2FieldScope.maybeOf(context)?.invalid ?? false),
              cursor: SystemMouseCursors.click,
              minHeight: m.height,
              padding: EdgeInsetsDirectional.only(
                start: m.combined,
                end: m.root,
              ),
              child: Row(
                spacing: m.gap,
                children: [
                  Expanded(
                    child: Padding(
                      padding: EdgeInsetsDirectional.only(end: m.inner),
                      child: fluent2CapCentred(
                        Text(
                          words ?? _hint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: type.c(
                            !live
                                ? c.neutralForegroundDisabled
                                : words == null
                                ? fluent2PlaceholderInk(t, widget.appearance)
                                : c.neutralForeground1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Icon(
                    Fluent2Icons.calendarLtr,
                    size: m.glyph,
                    color: live
                        ? c.neutralForeground3
                        : c.neutralForegroundDisabled,
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
