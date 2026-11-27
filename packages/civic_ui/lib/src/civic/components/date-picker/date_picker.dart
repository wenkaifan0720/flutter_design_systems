import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
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
/// The order and the marks between the parts are the app's locale's, as
/// ui_core's localizations give them
/// (`RawWidgetsLocalizations.dateFieldPattern`; `M/d/y` in American
/// English). An app that writes every date one way gives its own: extend
/// `DefaultRawWidgetsLocalizations`, override `dateFieldPattern` (and
/// `formatMediumDate`), and list its delegate first in
/// `localizationsDelegates`. [exampleOf] and the calendar follow it.
/// [CivicFormat.date] writes the month in words ("27 March 2026"), the same
/// in every locale, so a date it writes never reads as another day.
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
    final framed =
        widget.labelText != null ||
        widget.helperText != null ||
        widget.errorText != null;
    return _CalendarButton(
      label: widget.chooseLabel,
      enabled: change != null,
      // The calendar opens from the whole field, its label and help too, so
      // above the field it stands clear of the label.
      around: (button) {
        // The typed date takes its line's width beside the button, as a
        // text field takes its column's.
        final row = _LevelWrap(
          spacing: CivicSpacing.s8,
          runSpacing: CivicSpacing.s8,
          fillFirst: true,
          slots: [(null, field), (null, button)],
        );
        if (!framed) return row;
        return RawInputDecorator(
          labelText: widget.labelText,
          helperText: widget.helperText,
          errorText: widget.errorText,
          enabled: change != null,
          builder: (context, parts) => CivicFieldFrame(parts: parts),
          child: row,
        );
      },
      builder: (context, close) => CivicCalendar(
        controller: _dates,
        autofocus: true,
        onChanged: (day) {
          close();
          change?.call(day);
        },
      ),
    );
  }
}

/// [around] with a secondary button, a calendar's glyph after its words,
/// that opens [builder]'s calendar of
/// [months] under [around] (the whole field: its label, the typed date and
/// the button, its help), or above it, clear of the label, where below
/// can't hold the months; from its start edge and as wide as the months, floating on the hairline and a soft
/// shadow (by night on the raised band); Escape or a press outside closes
/// it and the focus goes back to the button.
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

  // The calendar's own width at [context]: its months of seven days side by
  // side, each day a finger's floor wide, the gap between them, and the
  // surface's padding.
  double _widthOf(BuildContext context) =>
      months * 7 * RawTapTargets.of(context).touch.width +
      (months - 1) * CivicCalendar.monthGap +
      2 * CivicSpacing.s16;

  @override
  Widget build(BuildContext context) {
    final t = context.civicTheme;
    // By night what floats stands on the raised band, and the calendar on
    // it takes that band for its page.
    final face = t.isDark ? t.surface : t.background;
    return RawPopover(
      semanticLabel: label,
      placement: const RawPopoverPlacement(
        align: RawPopoverAlign.start,
        matchAnchorWidth: false,
        // A month can't shrink: it opens on the side that holds it whole.
        fit: RawPopoverFit.whole,
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
          width: math.min(_widthOf(context), info.maxSize.width),
          child: DecoratedBox(
            decoration: civicFloating(
              face: face,
              hairline: t.rule,
              dark: t.isDark,
              shape: t.shapeScheme.corners.border(RawCorner.small),
            ),
            child: CivicTheme(
              data: t.copyWith(background: face),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(CivicSpacing.s16),
                  child: builder(context, info.close),
                ),
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

  (Widget, Widget) _field(
    BuildContext context,
    String label,
    DateTime? value,
    ValueChanged<DateTime?> set,
  ) {
    final t = context.civicTheme;
    final text = context.civicText;
    return (
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final change = widget.onChanged;
    final wide =
        (MediaQuery.maybeSizeOf(context)?.width ?? 1024) >= CivicLayout.medium;
    final months = wide ? 2 : 1;
    return _CalendarButton(
      label: widget.chooseLabel,
      months: months,
      enabled: change != null,
      // The calendar opens from the whole field, its legend and help too.
      around: (button) => RawInputDecorator(
        labelText: widget.labelText,
        helperText: widget.helperText,
        errorText: widget.errorText,
        enabled: change != null,
        builder: (context, parts) =>
            CivicFieldFrame(parts: parts, isLegend: widget.labelText != null),
        child: _LevelWrap(
          spacing: CivicSpacing.s16,
          runSpacing: CivicSpacing.s12,
          slots: [
            _field(context, widget.startLabel, _start, (d) {
              _start = d;
              _typed();
            }),
            _field(context, widget.endLabel, _end, (d) {
              _end = d;
              _typed();
            }),
            (null, button),
          ],
        ),
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
  }
}

/// Lays out [slots] as a [Wrap] does (side by side while they fit, then on
/// the next line), each slot a control under an optional label (a range's
/// From and To). The controls on one line stand one height, the tallest's,
/// as controls in a row do, under their labels, which stand
/// [CivicSpacing.s4] over them. With [fillFirst], the first control takes
/// the room its line leaves.
class _LevelWrap extends MultiChildRenderObjectWidget {
  _LevelWrap({
    required List<(Widget?, Widget)> slots,
    required this.spacing,
    required this.runSpacing,
    this.fillFirst = false,
  }) : labels = [
         for (final (label, _) in slots) ...[if (label != null) true, false],
       ],
       super(
         children: [
           for (final (label, control) in slots) ...[?label, control],
         ],
       );

  /// Whether each child is a label (true) or a control (false).
  final List<bool> labels;

  final double spacing;
  final double runSpacing;
  final bool fillFirst;

  @override
  _RenderLevelWrap createRenderObject(BuildContext context) => _RenderLevelWrap(
    labels,
    spacing,
    runSpacing,
    Directionality.of(context),
    fillFirst,
  );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderLevelWrap renderObject,
  ) => renderObject
    ..labels = labels
    ..spacing = spacing
    ..runSpacing = runSpacing
    ..direction = Directionality.of(context)
    ..fillFirst = fillFirst;
}

class _LevelParentData extends ContainerBoxParentData<RenderBox> {}

typedef _Slot = ({RenderBox? label, RenderBox control});

class _RenderLevelWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _LevelParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _LevelParentData> {
  _RenderLevelWrap(
    this._labels,
    this._spacing,
    this._runSpacing,
    this._direction,
    this._fillFirst,
  );

  bool _fillFirst;
  set fillFirst(bool v) {
    if (v == _fillFirst) return;
    _fillFirst = v;
    markNeedsLayout();
  }

  List<bool> _labels;
  set labels(List<bool> v) {
    if (listEquals(v, _labels)) return;
    _labels = v;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double v) {
    if (v == _spacing) return;
    _spacing = v;
    markNeedsLayout();
  }

  double _runSpacing;
  set runSpacing(double v) {
    if (v == _runSpacing) return;
    _runSpacing = v;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection v) {
    if (v == _direction) return;
    _direction = v;
    markNeedsLayout();
  }

  static const double _labelGap = CivicSpacing.s4;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _LevelParentData) {
      child.parentData = _LevelParentData();
    }
  }

  List<_Slot> get _slots {
    final out = <_Slot>[];
    RenderBox? label;
    var child = firstChild;
    var i = 0;
    while (child != null) {
      if (i < _labels.length && _labels[i]) {
        label = child;
      } else {
        out.add((label: label, control: child));
        label = null;
      }
      child = childAfter(child);
      i++;
    }
    return out;
  }

  double _slotWidth(_Slot s, double Function(RenderBox) width) =>
      math.max(s.label == null ? 0 : width(s.label!), width(s.control));

  @override
  double computeMinIntrinsicWidth(double height) => _slots.fold(
    0,
    (most, s) => math.max(
      most,
      _slotWidth(s, (b) => b.getMinIntrinsicWidth(double.infinity)),
    ),
  );

  @override
  double computeMaxIntrinsicWidth(double height) {
    final slots = _slots;
    if (slots.isEmpty) return 0;
    return slots.fold<double>(
          0,
          (sum, s) =>
              sum +
              _slotWidth(s, (b) => b.getMaxIntrinsicWidth(double.infinity)),
        ) +
        _spacing * (slots.length - 1);
  }

  @override
  double computeMinIntrinsicHeight(double width) =>
      _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _layout(BoxConstraints(maxWidth: width), dry: true).height;

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _layout(constraints, dry: true);

  @override
  void performLayout() => size = _layout(constraints, dry: false);

  Size _layout(BoxConstraints constraints, {required bool dry}) {
    final slots = _slots;
    if (slots.isEmpty) return constraints.smallest;
    final loose = BoxConstraints(maxWidth: constraints.maxWidth);
    Size measure(RenderBox box, BoxConstraints c) =>
        dry ? box.getDryLayout(c) : (box..layout(c, parentUsesSize: true)).size;
    final labels = [
      for (final s in slots)
        s.label == null ? Size.zero : measure(s.label!, loose),
    ];
    final controls = [for (final s in slots) measure(s.control, loose)];
    final widths = [
      for (var i = 0; i < slots.length; i++)
        math.max(labels[i].width, controls[i].width),
    ];
    // The slots on each line, as a Wrap breaks them.
    final runs = <List<int>>[];
    var x = 0.0;
    for (var i = 0; i < slots.length; i++) {
      if (runs.isEmpty || x + widths[i] > constraints.maxWidth) {
        runs.add([i]);
        x = widths[i] + _spacing;
      } else {
        runs.last.add(i);
        x += widths[i] + _spacing;
      }
    }
    // The first control takes the room its line leaves.
    if (_fillFirst && constraints.hasBoundedWidth && runs.first.first == 0) {
      final line = runs.first;
      final used =
          line.fold<double>(0, (sum, i) => sum + widths[i]) +
          _spacing * (line.length - 1);
      final room = constraints.maxWidth - used;
      if (room > 0) {
        final c = BoxConstraints.tightFor(width: controls[0].width + room);
        controls[0] = measure(slots[0].control, c);
        widths[0] = math.max(labels[0].width, controls[0].width);
      }
    }
    // Each line: the band its labels take, and its controls' one height.
    final bands = [
      for (final run in runs)
        run.fold<double>(
          0,
          (most, i) => slots[i].label == null
              ? most
              : math.max(most, labels[i].height + _labelGap),
        ),
    ];
    final levels = [
      for (final run in runs)
        run.fold<double>(0, (most, i) => math.max(most, controls[i].height)),
    ];
    final widest = runs.fold<double>(
      0,
      (most, run) => math.max(
        most,
        run.fold<double>(0, (sum, i) => sum + widths[i]) +
            _spacing * (run.length - 1),
      ),
    );
    var height = 0.0;
    for (var r = 0; r < runs.length; r++) {
      height += bands[r] + levels[r];
    }
    height += _runSpacing * (runs.length - 1);
    final box = constraints.constrain(Size(widest, height));
    if (dry) return box;
    var y = 0.0;
    for (var r = 0; r < runs.length; r++) {
      var at = 0.0;
      for (final i in runs[r]) {
        final s = slots[i];
        // Every control on the line stands as tall as the tallest.
        if (controls[i].height < levels[r]) {
          s.control.layout(
            BoxConstraints.tightFor(
              width: controls[i].width,
              height: levels[r],
            ),
            parentUsesSize: true,
          );
        }
        // Right to left, a line starts at the box's right edge.
        double start(double width) =>
            _direction == TextDirection.rtl ? box.width - at - width : at;
        (s.control.parentData! as _LevelParentData).offset = Offset(
          start(controls[i].width),
          y + bands[r],
        );
        final label = s.label;
        if (label != null) {
          (label.parentData! as _LevelParentData).offset = Offset(
            start(labels[i].width),
            y + bands[r] - _labelGap - labels[i].height,
          );
        }
        at += widths[i] + _spacing;
      }
      y += bands[r] + levels[r] + _runSpacing;
    }
    return box;
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
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
