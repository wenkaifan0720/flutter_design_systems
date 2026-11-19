/// Pickers: a month as `cal` prints it, a date and a range of dates chosen
/// from one under a field, a time typed `hh:mm`, and a colour from an area
/// of half-block cells or the palette's sixteen.
library;

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';

import '../grid.dart';
import '../internal/digits.dart';
import '../internal/field_cursor.dart';
import '../internal/list_open.dart';
import '../internal/menu_marks.dart';
import '../primitives/box.dart';
import '../primitives/control.dart';
import '../primitives/field_frame.dart';
import '../primitives/menu.dart';
import '../style.dart';
import '../theme.dart';
import '../localizations.dart';
import 'button.dart';
import 'pane.dart';
import 'text_field.dart';

/// [date] as a terminal writes one, `2026-11-14`: year, month and day in
/// that order, in [localizations]' digits when given (Arabic's
/// `٢٠٢٦-١١-١٤`), else ASCII.
String termDate(DateTime date, {DesignLocalizations? localizations}) {
  final l = localizations;
  String figure(int n, int width) => l == null
      ? n.toString().padLeft(width, '0')
      : termDigits(l, n, width: width);
  return '${figure(date.year, 4)}-${figure(date.month, 2)}-'
      '${figure(date.day, 2)}';
}

// The date's form in the reader's placeholders: `yyyy-mm-dd`.
String _dateForm(DesignLocalizations l) =>
    '${l.dateFieldYearPlaceholder}-${l.dateFieldMonthPlaceholder}-'
    '${l.dateFieldDayPlaceholder}';

const String _dateHint = 'yyyy-mm-dd';
const String _rangeHint = 'from → to';

/// A month as `cal` prints it: the month's name between `‹` and `›`, the
/// weekdays in two letters, each day in its own cells, the chosen one in
/// inverse video, the keyboard's in brackets, today underlined, a range's
/// days on a shaded ground. The arrows move by a day, Page Up and Down by
/// a month.
///
/// ```dart
/// TermCalendar(controller: calendar, onChanged: (day) => setState(() {}))
/// ```
class TermCalendar extends StatelessWidget {
  /// A calendar over [controller].
  const TermCalendar({
    super.key,
    required this.controller,
    this.onChanged,
    this.months = 1,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// The shown month, the keyboard's day and the selection; the caller's
  /// to dispose.
  final DesignCalendarController controller;

  /// Called with each day chosen.
  final ValueChanged<DateTime>? onChanged;

  /// How many months side by side.
  final int months;

  /// The days' focus; one given is the caller's to dispose.
  final FocusNode? focusNode;

  /// {@macro term.autofocus}
  final bool autofocus;

  /// Overrides, over the theme's [TermThemeData.calendarStyle]: `fill` (a
  /// chosen day), `foreground` (the days) and `edge` (the keyboard's day's
  /// brackets).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final floor = grid.ceil(DesignTapTargets.of(context).floorOn());
    final touch = DesignTapTargets.of(context).inputOn() == DesignInput.touch;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final l = DesignLocalizations.of(context);
    return DesignCalendar(
      controller: controller,
      onChanged: onChanged,
      months: months,
      focusNode: focusNode,
      autofocus: autofocus,
      // Each day owns one seventh of the month. Its block and hit area
      // must stop at that column even when the user's text grows.
      headerBuilder: (context, header) => SizedBox(
        height: floor.height,
        child: Row(
          children: [
            TermIconButton(
              glyph: rtl ? '›' : '‹',
              semanticLabel: l.previousMonthTooltip.toLowerCase(),
              onPressed: header.previous,
            ),
            Expanded(
              child: Center(child: Text(header.label, style: theme.boldStyle)),
            ),
            TermIconButton(
              glyph: rtl ? '‹' : '›',
              semanticLabel: l.nextMonthTooltip.toLowerCase(),
              onPressed: header.next,
            ),
          ],
        ),
      ),
      // The weekdays and the days grow with the reader's text to twice its
      // size, as Material's calendar's do: past that a day's two figures
      // no longer fit its seventh of the month.
      weekdayBuilder: (context, weekday, label) => _daySized(
        (context) => SizedBox(
          height: context.termGrid.lineHeight,
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                label.characters.take(2).toString(),
                style: theme.dimStyle,
              ),
            ),
          ),
        ),
      ),
      dayBuilder: (context, day, states) => _daySized((context) {
        final grid = context.termGrid;
        final own = TermStyleOf([style, theme.calendarStyle], states);
        // The day a waiting range would end on is drawn as a finished
        // range's end is.
        final chosen =
            states.contains(WidgetState.selected) ||
            (day.isPreviewEnd && !day.isRangeStart);
        // The keys' day; in a date field's calendar the pointer opened, its
        // brackets wait for a key ([TermMenuMarks]): the chosen day alone
        // reads current.
        final focused =
            states.contains(WidgetState.focused) &&
            (TermMenuMarks.shownOf(context) ?? true);
        // The band runs unbroken from the start's middle to the end's,
        // across the gaps between the days.
        final banded = day.inRange || day.inPreview;
        final before = banded && !day.isRangeStart;
        final after = banded && !day.isRangeEnd && !day.isPreviewEnd;
        final band = theme.rule.withValues(alpha: 0.35);
        // The keys' day is the cursor: its block in the accent, a pair of
        // brackets cut out of its end cells; on the chosen day, hollow.
        final ink = !day.enabled
            ? theme.rule
            : focused
            ? (chosen ? theme.accent : theme.onAccent)
            : chosen
            ? theme.onAccent
            : day.inMonth
            ? own.foreground ?? theme.foreground
            : theme.dim;
        final ground = chosen ? own.fill ?? theme.accent : null;
        return SizedBox(
          height: touch ? grid.lines(2) : grid.lineHeight,
          child: CustomPaint(
            painter: before || after
                ? _BandPainter(
                    color: band,
                    height: grid.lineHeight,
                    before: before,
                    after: after,
                    textDirection: Directionality.of(context),
                  )
                : null,
            // The day's own block: its number and a cell each side, as a
            // terminal calendar marks it, however wide the column runs.
            child: Center(
              child: SizedBox(
                width: grid.cols(4),
                height: grid.lineHeight,
                child: CustomPaint(
                  painter: focused
                      ? TermBracketPainter(
                          grid: grid,
                          color: theme.onAccent,
                          stroke: termStroke(theme, grid),
                          fill: ground,
                          cursor: 1,
                          cursorColor: own.edge ?? theme.accent,
                          knockout: theme.onAccent,
                          hollow: chosen,
                        )
                      : null,
                  child: ColoredBox(
                    color: focused || ground == null
                        ? const Color(0x00000000)
                        : ground,
                    child: Center(
                      child: Text(
                        termDigits(l, day.date.day).padLeft(2),
                        style: (day.isToday ? theme.boldStyle : theme.textStyle)
                            .copyWith(
                              color: ink,
                              decoration: day.isToday
                                  ? TextDecoration.underline
                                  : null,
                              decorationColor: ink,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('months', months, defaultValue: 1));
  }
}

/// A date chosen under its field: the field in a frame, as a [TermSelect]
/// is, writing the date `2026-11-14`; pressed, a [TermCalendar] opens in
/// place under it, and a day chosen closes it.
///
/// ```dart
/// TermDatePicker(
///   labelText: 'freeze from',
///   value: freeze,
///   firstDate: DateTime(2026),
///   lastDate: DateTime(2027),
///   onChanged: (d) => setState(() => freeze = d),
/// )
/// ```
class TermDatePicker extends StatefulWidget {
  /// A date field over [value].
  const TermDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText = _dateHint,
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
  });

  /// The date chosen, or null.
  final DateTime? value;

  /// Called with the day chosen; null disables it.
  final ValueChanged<DateTime>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// What the date is.
  final String? labelText;

  /// The dim words while none is chosen.
  final String hintText;

  /// Help under the frame.
  final String? helperText;

  /// What is wrong, in place of the help.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// Overrides for the field, over the theme's [TermThemeData.selectStyle];
  /// the calendar reads [TermThemeData.calendarStyle].
  final TermStyle? style;

  @override
  State<TermDatePicker> createState() => _TermDatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value))
      ..add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

class _TermDatePickerState extends State<TermDatePicker> {
  late final DesignCalendarController _calendar = DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    selectedDate: widget.value,
    currentDate: widget.currentDate,
  );

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final l = DesignLocalizations.of(context);
    return _DateField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      words: value == null ? null : termDate(value, localizations: l),
      hintText: widget.hintText == _dateHint ? _dateForm(l) : widget.hintText,
      enabled: widget.onChanged != null,
      style: widget.style,
      // Each opening starts the keys on the chosen day, wherever they were
      // left the last time.
      onOpen: () {
        final day = _calendar.selectedDate;
        if (day != null) _calendar.focus(day);
      },
      calendar: (close, days) => TermCalendar(
        controller: _calendar,
        focusNode: days,
        autofocus: true,
        onChanged: (day) {
          close();
          widget.onChanged?.call(day);
        },
      ),
    );
  }
}

/// A range of dates chosen under its field, `2026-11-02 → 2026-11-09`: the
/// first day pressed is its start, the next its end, the days between
/// shaded as the pointer moves; the end closes it.
///
/// ```dart
/// TermDateRangePicker(
///   labelText: 'window',
///   value: window,
///   firstDate: DateTime(2026),
///   lastDate: DateTime(2027),
///   onChanged: (r) => setState(() => window = r),
/// )
/// ```
class TermDateRangePicker extends StatefulWidget {
  /// A range field over [value].
  const TermDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.hintText = _rangeHint,
    this.helperText,
    this.errorText,
    this.currentDate,
    this.style,
  });

  /// The range chosen, or null.
  final DesignDateRange? value;

  /// Called with the range once its end is chosen; null disables it.
  final ValueChanged<DesignDateRange>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// What the range is.
  final String? labelText;

  /// The dim words while none is chosen.
  final String hintText;

  /// Help under the frame.
  final String? helperText;

  /// What is wrong, in place of the help.
  final String? errorText;

  /// Today; null: the clock's.
  final DateTime? currentDate;

  /// Overrides for the field, over the theme's [TermThemeData.selectStyle];
  /// the calendar reads [TermThemeData.calendarStyle].
  final TermStyle? style;

  @override
  State<TermDateRangePicker> createState() => _TermDateRangePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('labelText', labelText, defaultValue: null));
  }
}

class _TermDateRangePickerState extends State<TermDateRangePicker> {
  late final DesignCalendarController _calendar = DesignCalendarController(
    firstDate: widget.firstDate,
    lastDate: widget.lastDate,
    mode: DesignCalendarMode.range,
    selectedRange: widget.value,
    currentDate: widget.currentDate,
  );

  @override
  void dispose() {
    _calendar.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.value;
    final l = DesignLocalizations.of(context);
    final end = value?.end;
    return _DateField(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      words: value == null || end == null
          ? null
          : '${termDate(value.start, localizations: l)} → '
                '${termDate(end, localizations: l)}',
      range: value == null || end == null
          ? null
          : (
              termDate(value.start, localizations: l),
              termDate(end, localizations: l),
            ),
      hintText: widget.hintText == _rangeHint
          ? '${_dateForm(l)} → ${_dateForm(l)}'
          : widget.hintText,
      enabled: widget.onChanged != null,
      style: widget.style,
      // Each opening starts the keys on the range's first day.
      onOpen: () {
        final start = _calendar.selectedRange?.start;
        if (start != null) _calendar.focus(start);
      },
      calendar: (close, days) => TermCalendar(
        controller: _calendar,
        focusNode: days,
        autofocus: true,
        onChanged: (_) {
          final range = _calendar.selectedRange;
          if (range != null && range.end != null) {
            close();
            widget.onChanged?.call(range);
          }
        },
      ),
    );
  }
}

// A select-like field that opens [calendar] in place under it.
class _DateField extends StatefulWidget {
  const _DateField({
    required this.labelText,
    required this.helperText,
    required this.errorText,
    required this.words,
    this.range,
    required this.hintText,
    required this.enabled,
    required this.style,
    required this.calendar,
    this.onOpen,
  });

  final String? labelText;
  final String? helperText;
  final String? errorText;
  final String? words;
  final (String, String)? range;
  final String hintText;
  final bool enabled;
  final TermStyle? style;
  // The calendar, on [days], its days' focus.
  final Widget Function(VoidCallback close, FocusNode days) calendar;

  // Called as it opens, before the calendar is built.
  final VoidCallback? onOpen;

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  final _focus = FocusNode();
  final _days = FocusNode(debugLabel: 'days');
  final _menu = MenuController();

  @override
  void dispose() {
    _focus.dispose();
    _days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TermMenuMarks.watchInput();
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final enabled = widget.enabled;
    return DesignAnchoredOverlay(
      controller: _menu,
      dampingRatio: TermMotion.reveal.dampingRatio,
      stiffness: TermMotion.reveal.stiffness,
      semanticLabel: widget.labelText,
      onOpenChanged: (open) {
        if (open) widget.onOpen?.call();
      },
      placement: DesignOverlayPlacement(
        gap: 0,
        margin: grid.cellWidth,
        preferredExtent: grid.lines(12),
      ),
      anchorBuilder: (context, anchor) => LayoutBuilder(
        builder: (context, constraints) {
          var words = widget.words ?? widget.hintText;
          final room = math.max(1.0, constraints.maxWidth - grid.cols(6));
          final range = widget.range;
          var lines = 1;
          if (range != null && grid.widthOf(words) > room) {
            final (start, end) = range;
            words = grid.widthOf('→ $end') <= room
                ? '$start\n→ $end'
                : '$start\n→\n$end';
            final text = TextPainter(
              text: TextSpan(text: words, style: theme.textStyle),
              textScaler: MediaQuery.textScalerOf(context),
              textDirection: TextDirection.ltr,
            )..layout(maxWidth: room);
            lines = text.computeLineMetrics().length;
            text.dispose();
          }
          return DesignField(
            labelText: widget.labelText,
            helperText: widget.helperText,
            errorText: widget.errorText,
            enabled: enabled,
            focusNode: _focus,
            builder: (context, parts) => MergeSemantics(
              child: DesignPressable(
                onPressed: enabled ? termOpener(_focus, anchor) : null,
                focusNode: _focus,
                expanded: anchor.isOpen,
                isError: parts.hasError,
                semanticValue: widget.words,
                shortcuts: const {
                  SingleActivator(LogicalKeyboardKey.arrowDown):
                      ActivateIntent(),
                },
                mouseCursor: enabled
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                builder: (context, states, _) {
                  final own = TermStyleOf([
                    widget.style,
                    theme.selectStyle,
                  ], states);
                  // The frame doubles as every field's does; the keys' focus
                  // puts the value line under the cursor, as a select's.
                  return TermStateSprings(
                    pressed: false,
                    focused: states.contains(WidgetState.focused),
                    builder: (context, _, focus) => TermFieldFrame(
                      parts: parts,
                      active:
                          states.contains(WidgetState.focused) || anchor.isOpen,
                      edge: own.edge,
                      lines: lines,
                      child: TermFieldCursor(
                        focus: focus,
                        child: parts.control,
                      ),
                    ),
                  );
                },
              ),
            ),
            child: Builder(
              builder: (context) => Row(
                children: [
                  Expanded(
                    child: Text(
                      words,
                      maxLines: lines,
                      softWrap: lines > 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: TextDirection.ltr,
                      style: widget.words == null
                          ? theme.dimStyle.copyWith(
                              color: TermFieldCursor.inkOf(context, theme.dim),
                            )
                          : theme.textStyle.copyWith(
                              color: TermFieldCursor.inkOf(
                                context,
                                enabled ? theme.foreground : theme.rule,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: grid.cellWidth),
                  ExcludeSemantics(
                    child: Text(
                      '▾',
                      style: theme.textStyle.copyWith(
                        color: TermFieldCursor.inkOf(
                          context,
                          enabled ? theme.accent : theme.rule,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      overlayBuilder: (context, info) {
        final dayWidth = math.max(
          grid.cols(2),
          DesignTapTargets.of(context).floorOn().width,
        );
        final width = math.min(
          info.maxSize.width,
          math.max(info.anchorRect.width, 7 * dayWidth + grid.cols(2)),
        );
        return TermMenuReveal(
          info: info,
          child: SizedBox(
            width: width,
            child: TermPane(
              padding: width - grid.cols(4) < 7 * dayWidth
                  ? TermInset.zero
                  : null,
              raised: true,
              focused: true,
              // The keys on the chosen day (or today) as it opens, not on the
              // month's arrow the overlay focuses first: the date dialog's
              // way. Opened by the pointer, the chosen day alone reads current
              // until a key.
              child: _FocusOnOpen(
                node: _days,
                child: TermMenuMarks(
                  quietFirst: false,
                  child: SingleChildScrollView(
                    child: widget.calendar(info.close, _days),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// Puts the focus on [node] once [child] is up, after the overlay's own move
// of it to the first thing that takes it (which waits for the same frame).
class _FocusOnOpen extends StatefulWidget {
  const _FocusOnOpen({required this.node, required this.child});

  final FocusNode node;
  final Widget child;

  @override
  State<_FocusOnOpen> createState() => _FocusOnOpenState();
}

class _FocusOnOpenState extends State<_FocusOnOpen> {
  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.node.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A time typed as a terminal takes one, `14:30`, on a 24-hour clock: the
/// words checked as they are typed, the arrows stepping it by [step]
/// minutes. Its figures are the reader's digits (Arabic's `١٤:٣٠`), and
/// either theirs or ASCII ones type it.
///
/// ```dart
/// TermTimeField(
///   labelText: 'deploy at',
///   value: const TermTime(hour: 14, minute: 30),
///   onChanged: (t) => setState(() => at = t),
/// )
/// ```
class TermTimeField extends StatefulWidget {
  /// A time field over [value].
  const TermTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText = _timeHelp,
    this.step = 15,
    this.style,
  });

  /// The time, or null.
  final TermTime? value;

  /// Called with each valid time typed or stepped; null disables it.
  final ValueChanged<TermTime>? onChanged;

  /// What the time is.
  final String? labelText;

  /// Help under the frame; by default the times it takes and the keys that
  /// step it, `00:00–23:59 · ↑↓`, in the reader's digits.
  final String? helperText;

  /// How many minutes an arrow steps it.
  final int step;

  /// Overrides for the field, over the theme's
  /// [TermThemeData.textFieldStyle].
  final TermStyle? style;

  @override
  State<TermTimeField> createState() => _TermTimeFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('step', step, defaultValue: 15));
  }
}

const String _timeHelp = '00:00–23:59 · ↑↓';

class _TermTimeFieldState extends State<TermTimeField> {
  final _text = TextEditingController();
  DesignLocalizations? _words;
  String? _error;

  String _write(TermTime? t) {
    final l = _words ?? const DefaultDesignLocalizations();
    return t == null
        ? ''
        : '${termDigits(l, t.hour, width: 2)}:'
              '${termDigits(l, t.minute, width: 2)}';
  }

  TermTime? _read(String text) {
    final l = _words ?? const DefaultDesignLocalizations();
    final m = RegExp(r'^(\d{1,2}):(\d{2})$')
        .firstMatch(termAsciiDigits(l, text.trim()));
    if (m == null) return null;
    final h = int.parse(m.group(1)!);
    final min = int.parse(m.group(2)!);
    if (h > 23 || min > 59) return null;
    return TermTime(hour: h, minute: min);
  }

  // The times it takes, in the reader's digits: `00:00–23:59`.
  String get _range =>
      '${_write(const TermTime(hour: 0, minute: 0))}–'
      '${_write(const TermTime(hour: 23, minute: 59))}';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final l = DesignLocalizations.of(context);
    if (identical(l, _words)) return;
    final shown = _words == null ? widget.value : _read(_text.text);
    _words = l;
    // The same time in the new reader's digits; words that do not read yet
    // stay as typed.
    if (shown != null || _text.text.isEmpty) _text.text = _write(shown);
  }

  @override
  void didUpdateWidget(TermTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _write(widget.value);
    if (widget.value != oldWidget.value && _read(_text.text) != widget.value) {
      _text.text = next;
    }
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _typed(String text) {
    final t = _read(text);
    setState(() => _error = t == null && text.isNotEmpty ? _range : null);
    if (t != null) widget.onChanged?.call(t);
  }

  void _stepBy(int minutes) {
    final now =
        _read(_text.text) ?? widget.value ?? const TermTime(hour: 0, minute: 0);
    var total = (now.hour * 60 + now.minute + minutes) % (24 * 60);
    if (total < 0) total += 24 * 60;
    final t = TermTime(hour: total ~/ 60, minute: total % 60);
    _text.text = _write(t);
    setState(() => _error = null);
    widget.onChanged?.call(t);
  }

  @override
  Widget build(BuildContext context) {
    final l = DesignLocalizations.of(context);
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () =>
            _stepBy(widget.step),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () =>
            _stepBy(-widget.step),
      },
      child: TermTextField(
        controller: _text,
        labelText: widget.labelText,
        helperText: widget.helperText == _timeHelp
            ? '$_range · ↑↓'
            : widget.helperText,
        errorText: _error,
        hintText: '--:--',
        enabled: widget.onChanged != null,
        autocorrect: false,
        textDirection: TextDirection.ltr,
        keyboardType: TextInputType.datetime,
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp('[${termDigitClass(l)}:]')),
          LengthLimitingTextInputFormatter(5),
        ],
        onChanged: _typed,
        style: widget.style,
      ),
    );
  }
}

/// A colour picker drawn in cells: an area of saturation across and
/// brightness up, each cell two half-block pixels as a terminal draws a
/// picture; a hue bar of cells under it; the colour's hex; and the
/// palette's sixteen colours to take one from.
///
/// ```dart
/// TermColorPicker(controller: colour)
/// ```
class TermColorPicker extends StatelessWidget {
  /// A picker over [controller].
  const TermColorPicker({
    super.key,
    required this.controller,
    this.lines = 8,
    this.style,
  });

  /// The colour; the caller's to dispose.
  final DesignColorController controller;

  /// The area's height in lines.
  final int lines;

  /// Overrides, over the theme's [TermThemeData.colorPickerStyle]: `edge`
  /// (the ring on the thumbs and the swatches) and `foreground` (the hex).
  final TermStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final own = TermStyleOf([style, theme.colorPickerStyle], const {});
    final ring = own.edge ?? theme.foreground;
    final p = theme.palette;
    final swatches = [
      p.black,
      p.red,
      p.green,
      p.yellow,
      p.blue,
      p.magenta,
      p.cyan,
      p.white,
      p.brightBlack,
      p.brightRed,
      p.brightGreen,
      p.brightYellow,
      p.brightBlue,
      p.brightMagenta,
      p.brightCyan,
      p.brightWhite,
    ];
    return DesignColorPicker(
      controller: controller,
      areaHeight: grid.lines(lines),
      // The keyboard's focus on the area: the cursor round it, hollow, its
      // first and last columns and its top and bottom rows of half-block
      // pixels, a pair of brackets its height cut out of the columns, as a
      // chosen row's end cells take it; the thumb's brackets go to the
      // cursor too.
      areaBuilder: (context, area) => CustomPaint(
        painter: _HalfBlockArea(grid: grid, hue: area.color.hue),
        foregroundPainter: area.states.contains(WidgetState.focused)
            ? _AreaCursor(
                lineHeight: grid.lineHeight,
                cellWidth: grid.cellWidth,
                color: theme.accent,
                knockout: theme.onAccent,
                stroke: termStroke(theme, grid),
              )
            : null,
        child: const SizedBox.expand(),
      ),
      areaThumbBuilder: (context, area) => _Ring(
        grid: grid,
        color: ring,
        focus: area.states.contains(WidgetState.focused) ? 1 : 0,
        accent: theme.accent,
      ),
      trackBuilder: (context, channel, color) => SizedBox(
        height: grid.lineHeight,
        child: CustomPaint(
          painter: _HueCells(grid: grid, color: color, channel: channel),
        ),
      ),
      thumbBuilder: (context, states) => _Ring(
        grid: grid,
        color: ring,
        focus: states.contains(WidgetState.focused) ? 1 : 0,
        accent: theme.accent,
      ),
      layoutBuilder: (context, parts) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          parts[0],
          SizedBox(height: grid.lineHeight * 0.5),
          for (final part in parts.skip(1)) part,
          SizedBox(height: grid.lineHeight * 0.5),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => Row(
              children: [
                SizedBox(
                  width: grid.cols(4),
                  height: grid.lineHeight,
                  child: ColoredBox(color: controller.color),
                ),
                SizedBox(width: grid.cellWidth),
                Text(
                  controller.hex,
                  textDirection: TextDirection.ltr,
                  style: theme.textStyle.copyWith(
                    color: own.foreground ?? theme.foreground,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: grid.lineHeight * 0.5),
          Wrap(
            children: [
              for (final (i, c) in swatches.indexed)
                TermTapTarget(
                  child: DesignPressable(
                    onPressed: () => controller.color = c,
                    semanticLabel: TermLocalizations.of(context)
                        .paletteColorName(i),
                    mouseCursor: SystemMouseCursors.click,
                    builder: (context, states, _) => SizedBox(
                      width: grid.cols(3),
                      height: grid.lineHeight,
                      // The keyboard's focus: the cursor on the swatch's end
                      // cells, brackets cut out of it, its colour between.
                      child: CustomPaint(
                        foregroundPainter: states.contains(WidgetState.focused)
                            ? TermBracketPainter(
                                grid: grid,
                                color: theme.onAccent,
                                stroke: termStroke(theme, grid),
                                cursor: 1,
                                cursorColor: theme.accent,
                                knockout: theme.onAccent,
                                hollow: true,
                              )
                            : null,
                        child: Padding(
                          padding: EdgeInsetsDirectional.symmetric(
                            horizontal: grid.cellWidth * 0.5,
                          ),
                          child: ColoredBox(color: c),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// The cursor on a colour area, hollow: its first and last columns and its
// top and bottom half-lines in [color], a bracket the area's height cut out
// of each column in [knockout].
class _AreaCursor extends CustomPainter {
  const _AreaCursor({
    required this.lineHeight,
    required this.cellWidth,
    required this.color,
    required this.knockout,
    required this.stroke,
  });

  final double lineHeight;
  final double cellWidth;
  final Color color;
  final Color knockout;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final pixel = lineHeight / 2;
    final ground = Paint()..color = color;
    final ink = Paint()..color = knockout;
    final h = size.height;
    final arm = cellWidth * 0.4;
    final inset = cellWidth * 0.3;
    canvas
      ..drawRect(Rect.fromLTWH(0, 0, cellWidth, h), ground)
      ..drawRect(Rect.fromLTWH(size.width - cellWidth, 0, cellWidth, h), ground)
      ..drawRect(Rect.fromLTWH(0, 0, size.width, pixel), ground)
      ..drawRect(Rect.fromLTWH(0, h - pixel, size.width, pixel), ground);
    void bracket(double x, double dir) {
      final y0 = pixel / 2;
      final y1 = h - y0;
      canvas
        ..drawRect(Rect.fromLTWH(x - stroke / 2, y0, stroke, y1 - y0), ink)
        ..drawRect(Rect.fromLTWH(dir > 0 ? x : x - arm, y0, arm, stroke), ink)
        ..drawRect(
          Rect.fromLTWH(dir > 0 ? x : x - arm, y1 - stroke, arm, stroke),
          ink,
        );
    }

    bracket(inset + stroke / 2, 1);
    bracket(size.width - inset - stroke / 2, -1);
  }

  @override
  bool shouldRepaint(_AreaCursor old) =>
      old.lineHeight != lineHeight ||
      old.cellWidth != cellWidth ||
      old.color != color ||
      old.knockout != knockout ||
      old.stroke != stroke;
}

// The saturation-brightness area for [hue] as cells of two half-block
// pixels each: stepped, as a terminal's picture is.
class _HalfBlockArea extends CustomPainter {
  const _HalfBlockArea({required this.grid, required this.hue});

  final TermGrid grid;
  final double hue;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final half = grid.lineHeight / 2;
    final cols = math.max(1, (size.width / cw).floor());
    final rows = math.max(1, (size.height / half).floor());
    final w = size.width / cols;
    final h = size.height / rows;
    final paint = Paint();
    for (var r = 0; r < rows; r++) {
      final v = rows == 1 ? 1.0 : 1 - r / (rows - 1);
      for (var c = 0; c < cols; c++) {
        final s = cols == 1 ? 1.0 : c / (cols - 1);
        paint.color = HSVColor.fromAHSV(1, hue, s, v).toColor();
        canvas.drawRect(Rect.fromLTWH(c * w, r * h, w + 0.5, h + 0.5), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_HalfBlockArea old) => old.hue != hue || old.grid != grid;
}

// A slider's track: a cell for each step of [channel].
class _HueCells extends CustomPainter {
  const _HueCells({
    required this.grid,
    required this.color,
    required this.channel,
  });

  final TermGrid grid;
  final HSVColor color;
  final DesignColorChannel channel;

  @override
  void paint(Canvas canvas, Size size) {
    final cw = grid.cellWidth;
    final cols = math.max(1, (size.width / cw).floor());
    final w = size.width / cols;
    final paint = Paint();
    final top = size.height * 0.2;
    for (var c = 0; c < cols; c++) {
      final t = cols == 1 ? 0.0 : c / (cols - 1);
      paint.color = channel == DesignColorChannel.alpha
          ? color.withAlpha(t).toColor()
          : HSVColor.fromAHSV(1, t * 360, 1, 1).toColor();
      canvas.drawRect(
        Rect.fromLTWH(c * w, top, w + 0.5, size.height - top * 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HueCells old) =>
      old.color != color || old.channel != channel || old.grid != grid;
}

// A thumb: a cell outlined in [color], doubled in [accent] under focus.
class _Ring extends StatelessWidget {
  const _Ring({
    required this.grid,
    required this.color,
    required this.focus,
    required this.accent,
  });

  final TermGrid grid;
  final Color color;
  final double focus;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    return Center(
      child: SizedBox(
        width: grid.cols(3),
        height: grid.lineHeight,
        child: CustomPaint(
          // The keyboard's focus: the cursor on the brackets' cells, the
          // brackets cut out of it, the colour between them left showing.
          painter: TermBracketPainter(
            grid: grid,
            color: color,
            stroke: termStroke(theme, grid) * 2,
            cursor: focus,
            cursorColor: accent,
            knockout: theme.onAccent,
            hollow: true,
          ),
        ),
      ),
    );
  }
}

// The shade of a range behind one day's cell: from its middle back to the
// cell's start side ([before]) and on to its end side ([after]), a line
// tall, so the days of a range join in one band.
class _BandPainter extends CustomPainter {
  _BandPainter({
    required this.color,
    required this.height,
    required this.before,
    required this.after,
    required this.textDirection,
  });

  final Color color;
  final double height;
  final bool before;
  final bool after;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final top = (size.height - height) / 2;
    final mid = size.width / 2;
    final ltr = textDirection == TextDirection.ltr;
    final paint = Paint()..color = color;
    void span(double a, double b) =>
        canvas.drawRect(Rect.fromLTRB(a, top, b, top + height), paint);
    if (before) ltr ? span(0, mid) : span(mid, size.width);
    if (after) ltr ? span(mid, size.width) : span(0, mid);
  }

  @override
  bool shouldRepaint(_BandPainter old) =>
      old.color != color ||
      old.height != height ||
      old.before != before ||
      old.after != after ||
      old.textDirection != textDirection;
}

/// A time of day as a [TermTimeField] holds one: an [hour] on a 24-hour
/// clock and a [minute], with no date or zone (and no Material type in the
/// look's API).
@immutable
class TermTime {
  /// [hour] from 0 to 23, [minute] from 0 to 59.
  const TermTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The hour, from 0 to 23.
  final int hour;

  /// The minute, from 0 to 59.
  final int minute;

  /// This time with [hour] or [minute] replaced.
  TermTime copyWith({int? hour, int? minute}) =>
      TermTime(hour: hour ?? this.hour, minute: minute ?? this.minute);

  @override
  bool operator ==(Object other) =>
      other is TermTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() =>
      'TermTime(${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')})';
}

/// The most a calendar's day grows with the reader's text.
const double _dayScaleCap = 2;

// [build] under the reader's text scale capped at [_dayScaleCap], its grid
// (`context.termGrid`) capped with it.
Widget _daySized(WidgetBuilder build) => MediaQuery.withClampedTextScaling(
  maxScaleFactor: _dayScaleCap,
  child: Builder(builder: build),
);
