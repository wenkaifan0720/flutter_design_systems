import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../internal/field_frame.dart';
import '../../internal/paint.dart';
import '../../internal/segment_well.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../calendar/calendar.dart';

// A date's caller reads the range it holds; a time's caller, the time.
export 'package:ui_core/ui_core.dart' show RawTimeOfDay;

/// A day typed or chosen: the date typed in the field's well in the
/// reader's order (day, month and year where they write it so), with a
/// "Choose date" button beside it that opens a [CivicCalendar] under it.
/// Typing is quickest for a date someone knows; the calendar helps with
/// one they need to see (an appointment, a start date).
///
/// [value] in, [onChanged] out: the day once every part is typed or a day
/// is chosen, null when a part is cleared. Days before [firstDate] or after
/// [lastDate] can't be chosen, and a typed one shows the well's error edge.
/// The calendar opens on the day typed; Escape closes it and the focus goes
/// back to the button.
///
/// Reads [CivicStyle] as the text field does for the well (its `style:`,
/// then [CivicThemeData.textFieldStyle]); the calendar reads
/// [CivicThemeData.calendarStyle].
///
/// ```dart
/// CivicDatePicker(
///   labelText: 'When do you want the permit to start?',
///   helperText:
///       'For example, ${CivicDatePicker.exampleOf(context, DateTime(2026, 3, 27))}',
///   value: start,
///   firstDate: DateTime(2026),
///   lastDate: DateTime(2026, 12, 31),
///   onChanged: (day) => setState(() => start = day),
/// )
/// ```
class CivicDatePicker extends StatefulWidget {
  /// A date picker.
  const CivicDatePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.helperText,
    this.errorText,
    this.chooseLabel = 'Choose date',
    this.autofocus = false,
    this.style,
  });

  /// The day; null, none.
  final DateTime? value;

  /// Called with the day as it is typed whole or chosen, null when a part
  /// is cleared; null disables the picker.
  final ValueChanged<DateTime?>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The question.
  final String? labelText;

  /// An example of the answer, written as the field writes a date
  /// ([exampleOf]).
  final String? helperText;

  /// What to fix; null while the day is fine.
  final String? errorText;

  /// The words on the button that opens the calendar.
  final String chooseLabel;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the well's look.
  final CivicStyle? style;

  /// [day] written as the date fields at [context] write it: the reader's
  /// order and separators and figures ("3/27/2026" in English, "27/3/2026"
  /// in Arabic's digits), for the example in a field's hint.
  static String exampleOf(BuildContext context, DateTime day) {
    final words = RawWidgetsLocalizations.of(context);
    final pattern = words.dateFieldPattern;
    final out = StringBuffer();
    var i = 0;
    while (i < pattern.length) {
      final c = pattern[i];
      if (c == "'") {
        final end = pattern.indexOf("'", i + 1);
        if (end == i + 1) {
          out.write("'");
        } else {
          out.write(pattern.substring(i + 1, end < 0 ? pattern.length : end));
        }
        i = end < 0 ? pattern.length : end + 1;
        continue;
      }
      var j = i;
      while (j < pattern.length && pattern[j] == c) {
        j++;
      }
      out.write(switch (c) {
        'y' => words.formatYear(day),
        'M' || 'L' => words.formatDecimal(day.month),
        'd' => words.formatDecimal(day.day),
        _ => pattern.substring(i, j),
      });
      i = j;
    }
    return out.toString();
  }

  @override
  State<CivicDatePicker> createState() => _CivicDatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime?>>.has('onChanged', onChanged),
      )
      ..add(DiagnosticsProperty<DateTime>('firstDate', firstDate))
      ..add(DiagnosticsProperty<DateTime>('lastDate', lastDate))
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(StringProperty('errorText', errorText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicDatePickerState extends State<CivicDatePicker> {
  late RawCalendarController _dates = _make();

  RawCalendarController _make() {
    final value = widget.value;
    final inRange =
        value != null &&
        !value.isBefore(widget.firstDate) &&
        !value.isAfter(widget.lastDate);
    return RawCalendarController(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      selectedDate: inRange ? value : null,
      initialMonth: inRange ? value : null,
    );
  }

  @override
  void didUpdateWidget(CivicDatePicker old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value ||
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate) {
      _dates.dispose();
      _dates = _make();
    }
  }

  @override
  void dispose() {
    _dates.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final change = widget.onChanged;
    final hasError = widget.errorText != null;
    final field = RawDateField(
      value: widget.value,
      onChanged: change,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      semanticLabel: widget.labelText,
      autofocus: widget.autofocus,
      segmentBuilder: (context, details) => CivicDateSegment(details: details),
      literalBuilder: civicSegmentLiteral,
      frameBuilder: (context, states, segments) => civicSegmentWell(
        context,
        states,
        segments,
        styles: [widget.style, t.textFieldStyle],
        isError: hasError,
      ),
    );
    final row = _CalendarButton(
      label: widget.chooseLabel,
      enabled: change != null,
      around: (button) => Wrap(
        spacing: CivicSpacing.s8,
        runSpacing: CivicSpacing.s8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [field, button],
      ),
      builder: (context, close) => CivicCalendar(
        controller: _dates,
        autofocus: true,
        onChanged: (day) {
          close();
          change?.call(day);
        },
      ),
    );
    if (widget.labelText == null &&
        widget.helperText == null &&
        widget.errorText == null) {
      return row;
    }
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: change != null,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: row,
    );
  }
}

/// [around] with a secondary button, a calendar's glyph after its words,
/// that opens [builder]'s calendar of [months] under [around] (the typed
/// date and the button), from its start edge and as wide as the months,
/// floating on the hairline and a soft shadow; Escape or a press outside
/// closes it and the focus goes back to the button.
class _CalendarButton extends StatelessWidget {
  const _CalendarButton({
    required this.label,
    required this.builder,
    required this.around,
    this.months = 1,
    this.enabled = true,
  });

  final String label;
  final Widget Function(BuildContext context, VoidCallback close) builder;
  final Widget Function(Widget button) around;
  final int months;
  final bool enabled;

  // The calendar's own width: its months of seven days side by side, the
  // gap between them, and the surface's padding.
  double get _width =>
      months * 7 * CivicCalendar.dayWidth +
      (months - 1) * CivicCalendar.monthGap +
      2 * CivicSpacing.s16;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    return RawPopover(
      semanticLabel: label,
      placement: const RawPopoverPlacement(
        align: RawPopoverAlign.start,
        matchAnchorWidth: false,
        preferredExtent: 380,
        gap: CivicSpacing.s8,
      ),
      anchorBuilder: (context, anchor) => around(
        CivicButton.secondary(
          onPressed: enabled ? anchor.toggle : null,
          icon: LucideIcons.calendarDays,
          expand: false,
          child: Text(label),
        ),
      ),
      overlayBuilder: (context, info) => FadeTransition(
        opacity: info.animation,
        child: SizedBox(
          width: math.min(_width, info.maxSize.width),
          child: DecoratedBox(
            decoration: civicFloating(
              face: t.background,
              hairline: t.rule,
              dark: t.isDark,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(CivicSpacing.s16),
                child: builder(context, info.close),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A range of days typed or chosen: a From and a To date, each typed in
/// its well, and a button that opens a calendar of two months (one on a
/// phone) where the first press chooses the start and the second the end.
///
/// [value] in, [onChanged] out: the range once both ends are typed or
/// chosen (an end before the start swaps them), null when a part is
/// cleared.
///
/// Reads [CivicStyle] as the text field does for the wells (its `style:`,
/// then [CivicThemeData.textFieldStyle]); the calendar reads
/// [CivicThemeData.calendarStyle].
///
/// ```dart
/// CivicDateRangePicker(
///   labelText: 'When will your visitor stay?',
///   value: stay,
///   firstDate: DateTime(2026),
///   lastDate: DateTime(2026, 12, 31),
///   onChanged: (range) => setState(() => stay = range),
/// )
/// ```
class CivicDateRangePicker extends StatefulWidget {
  /// A date range picker.
  const CivicDateRangePicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.labelText,
    this.helperText,
    this.errorText,
    this.startLabel = 'From',
    this.endLabel = 'To',
    this.chooseLabel = 'Choose dates',
    this.style,
  });

  /// The range; null, none.
  final RawDateRange? value;

  /// Called with the range once both ends are set, null when one is
  /// cleared; null disables the picker.
  final ValueChanged<RawDateRange?>? onChanged;

  /// The first day it offers.
  final DateTime firstDate;

  /// The last day it offers.
  final DateTime lastDate;

  /// The question.
  final String? labelText;

  /// An example of the answer.
  final String? helperText;

  /// What to fix; null while the range is fine.
  final String? errorText;

  /// The first date's label.
  final String startLabel;

  /// The second date's label.
  final String endLabel;

  /// The words on the button that opens the calendar.
  final String chooseLabel;

  /// Overrides for the wells' look.
  final CivicStyle? style;

  @override
  State<CivicDateRangePicker> createState() => _CivicDateRangePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawDateRange>('value', value, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawDateRange?>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}

class _CivicDateRangePickerState extends State<CivicDateRangePicker> {
  late RawCalendarController _dates;
  DateTime? _start;
  DateTime? _end;

  RawCalendarController _make() {
    final value = widget.value;
    _start = value?.start;
    _end = value?.end;
    return RawCalendarController(
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
      mode: RawCalendarMode.range,
      selectedRange: value,
      initialMonth: value?.start,
    );
  }

  @override
  void initState() {
    super.initState();
    _dates = _make();
  }

  @override
  void didUpdateWidget(CivicDateRangePicker old) {
    super.didUpdateWidget(old);
    if (old.value?.start != widget.value?.start ||
        old.value?.end != widget.value?.end ||
        old.firstDate != widget.firstDate ||
        old.lastDate != widget.lastDate) {
      _dates.dispose();
      _dates = _make();
    }
  }

  @override
  void dispose() {
    _dates.dispose();
    super.dispose();
  }

  void _typed() {
    final start = _start;
    final end = _end;
    final change = widget.onChanged;
    if (change == null) return;
    if (start == null || end == null) {
      if (widget.value != null) change(null);
      return;
    }
    change(
      end.isBefore(start) ? RawDateRange(end, start) : RawDateRange(start, end),
    );
  }

  Widget _field(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> set,
  ) {
    final t = context.civicTheme;
    final text = context.civicText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: CivicSpacing.s4,
      children: [
        ExcludeSemantics(
          child: Text(label, style: text.body.copyWith(color: t.textPrimary)),
        ),
        RawDateField(
          value: value,
          onChanged: widget.onChanged == null ? null : set,
          firstDate: widget.firstDate,
          lastDate: widget.lastDate,
          // The field says the question once; each end says only its own
          // name (From, To).
          semanticLabel: label,
          segmentBuilder: (context, details) =>
              CivicDateSegment(details: details),
          literalBuilder: civicSegmentLiteral,
          frameBuilder: (context, states, segments) => civicSegmentWell(
            context,
            states,
            segments,
            styles: [widget.style, t.textFieldStyle],
            isError: widget.errorText != null,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.onChanged;
    final wide =
        (MediaQuery.maybeSizeOf(context)?.width ?? 1024) >= CivicLayout.medium;
    final months = wide ? 2 : 1;
    final row = _CalendarButton(
      label: widget.chooseLabel,
      months: months,
      enabled: change != null,
      around: (button) => Wrap(
        spacing: CivicSpacing.s16,
        runSpacing: CivicSpacing.s12,
        crossAxisAlignment: WrapCrossAlignment.end,
        children: [
          _field(context, widget.startLabel, _start, (d) {
            _start = d;
            _typed();
          }),
          _field(context, widget.endLabel, _end, (d) {
            _end = d;
            _typed();
          }),
          button,
        ],
      ),
      builder: (context, close) => CivicCalendar(
        controller: _dates,
        months: months,
        autofocus: true,
        onChanged: (_) {
          final range = _dates.selectedRange;
          final end = range?.end;
          if (range != null && end != null) {
            close();
            change?.call(range);
          }
        },
      ),
    );
    return RawInputDecorator(
      labelText: widget.labelText,
      helperText: widget.helperText,
      errorText: widget.errorText,
      enabled: change != null,
      builder: (context, parts) =>
          CivicFieldFrame(parts: parts, isLegend: widget.labelText != null),
      child: row,
    );
  }
}

/// A time of day typed: the hour and the minute (and, on a 12-hour clock,
/// AM or PM) in the field's well, in the reader's order. Each part takes
/// figures and moves on when it is whole; the arrow keys step the part
/// that has the focus. A time is quicker typed than chosen from a list.
///
/// [value] in, [onChanged] out: the time once every part holds one, null
/// when one is cleared.
///
/// Reads [CivicStyle] as the text field does for the well: its `style:`,
/// then [CivicThemeData.textFieldStyle].
///
/// ```dart
/// CivicTimeInput(
///   labelText: 'What time will you arrive?',
///   helperText: 'For example, 9:30 AM',
///   value: arrival,
///   onChanged: (time) => setState(() => arrival = time),
/// )
/// ```
class CivicTimeInput extends StatelessWidget {
  /// A time input.
  const CivicTimeInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.labelText,
    this.helperText,
    this.errorText,
    this.alwaysUse24HourFormat,
    this.autofocus = false,
    this.style,
  });

  /// The time; null, none.
  final RawTimeOfDay? value;

  /// Called with the time once every part holds one, null when one is
  /// cleared; null disables the input.
  final ValueChanged<RawTimeOfDay?>? onChanged;

  /// The question.
  final String? labelText;

  /// An example of the answer.
  final String? helperText;

  /// What to fix; null while the time is fine.
  final String? errorText;

  /// Whether the clock runs 0 to 23; null: the platform's or the locale's.
  final bool? alwaysUse24HourFormat;

  /// {@macro civic.autofocus}
  final bool autofocus;

  /// Overrides for the well's look.
  final CivicStyle? style;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    final field = Align(
      alignment: AlignmentDirectional.centerStart,
      child: RawTimeField(
        value: value,
        onChanged: onChanged,
        alwaysUse24HourFormat: alwaysUse24HourFormat,
        semanticLabel: labelText,
        autofocus: autofocus,
        segmentBuilder: (context, details) =>
            CivicDateSegment(details: details),
        literalBuilder: civicSegmentLiteral,
        frameBuilder: (context, states, segments) => civicSegmentWell(
          context,
          states,
          segments,
          styles: [style, t.textFieldStyle],
          isError: errorText != null,
        ),
      ),
    );
    if (labelText == null && helperText == null && errorText == null) {
      return field;
    }
    return RawInputDecorator(
      labelText: labelText,
      helperText: helperText,
      errorText: errorText,
      enabled: onChanged != null,
      builder: (context, parts) => CivicFieldFrame(parts: parts),
      child: field,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<RawTimeOfDay>('value', value, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<RawTimeOfDay?>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(StringProperty('labelText', labelText, defaultValue: null))
      ..add(
        DiagnosticsProperty<CivicStyle>('style', style, defaultValue: null),
      );
  }
}
