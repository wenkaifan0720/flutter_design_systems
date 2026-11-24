/// Date and time fields, headless: a date or a time typed segment by
/// segment (month, day, year; hour, minute, AM/PM) in the reader's order,
/// digits and words, the segments and the text between them the look's.
///
/// [RawDateField] and [RawTimeField] lay their segments out in the
/// locale's pattern (CLDR's: `M/d/y`, `d.M.y`, `y/M/d`; `h:mm a`, `HH:mm`,
/// `a h:mm`), each segment a tab stop and an adjustable node a screen reader
/// steps. Digits fill a segment and move on when no further digit fits;
/// the keys step, clear and move between segments; a phone's keyboard types
/// into them through one text input the field holds.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'internal/announce.dart';
import 'internal/segments.dart';
import 'localizations.dart';

/// A time of day with no date: an hour (0–23), a minute and a second.
///
/// ui_core's own, as Flutter's `TimeOfDay` is Material's; a time field
/// ([RawTimeField]) takes and gives one.
///
/// ```dart
/// Text(RawWidgetsLocalizations.of(context).formatTimeOfDay(const RawTimeOfDay(hour: 15, minute: 5)))
/// ```
@immutable
class RawTimeOfDay implements Comparable<RawTimeOfDay> {
  /// The time [hour]:[minute]:[second].
  const RawTimeOfDay({
    required this.hour,
    required this.minute,
    this.second = 0,
  }) : assert(hour >= 0 && hour < 24, 'an hour is 0 to 23'),
       assert(minute >= 0 && minute < 60, 'a minute is 0 to 59'),
       assert(second >= 0 && second < 60, 'a second is 0 to 59');

  /// [time]'s hour, minute and second.
  RawTimeOfDay.fromDateTime(DateTime time)
    : hour = time.hour,
      minute = time.minute,
      second = time.second;

  /// The hour, 0 to 23.
  final int hour;

  /// The minute, 0 to 59.
  final int minute;

  /// The second, 0 to 59.
  final int second;

  /// The hour on a 12-hour clock, 1 to 12.
  int get hourOfPeriod => hour % 12 == 0 ? 12 : hour % 12;

  /// Whether it is after noon (12:00 to 23:59).
  bool get isPm => hour >= 12;

  /// This time with the given parts changed.
  RawTimeOfDay replacing({int? hour, int? minute, int? second}) => RawTimeOfDay(
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    second: second ?? this.second,
  );

  /// Whether it comes before [other] in the day.
  bool isBefore(RawTimeOfDay other) => compareTo(other) < 0;

  /// Whether it comes after [other] in the day.
  bool isAfter(RawTimeOfDay other) => compareTo(other) > 0;

  int get _seconds => (hour * 60 + minute) * 60 + second;

  @override
  int compareTo(RawTimeOfDay other) => _seconds.compareTo(other._seconds);

  @override
  bool operator ==(Object other) =>
      other is RawTimeOfDay && other._seconds == _seconds;

  @override
  int get hashCode => _seconds.hashCode;

  @override
  String toString() {
    String two(int n) => n.toString().padLeft(2, '0');
    return 'RawTimeOfDay(${two(hour)}:${two(minute)}:${two(second)})';
  }
}

/// The kinds of segment a date or a time field is typed in.
enum RawDateSegmentType {
  /// The year.
  year,

  /// The month, typed as its number.
  month,

  /// The day of the month.
  day,

  /// The hour, on the field's clock (1–12, or 0–23).
  hour,

  /// The minute.
  minute,

  /// The second.
  second,

  /// AM or PM, on a 12-hour clock.
  dayPeriod,
}

/// One segment of a [RawDateField] or [RawTimeField], as the look
/// paints it.
@immutable
class RawDateSegmentDetails {
  /// A segment's details.
  const RawDateSegmentDetails({
    required this.type,
    required this.text,
    required this.isPlaceholder,
    required this.states,
  });

  /// What it holds.
  final RawDateSegmentType type;

  /// Its text: the value in the reader's digits ("07", "2026", "PM"), what
  /// has been typed so far, or, when [isPlaceholder], the empty segment's
  /// letters ("mm", "dd", "yyyy"; "––" for a time's).
  final String text;

  /// Whether it holds nothing yet, and [text] is its placeholder.
  final bool isPlaceholder;

  /// Its states: [WidgetState.focused] while it has the focus,
  /// [WidgetState.disabled] when the field takes no input,
  /// [WidgetState.error] when the field's value is out of range.
  final Set<WidgetState> states;
}

/// Paints one segment of a date or time field. A segment is a tap target:
/// a look gives its face the floor ([TapTargetPadding]).
typedef RawDateSegmentBuilder = Widget Function(
  BuildContext context,
  RawDateSegmentDetails details,
);

/// Paints the text between a field's segments ("/", ".", ":", Japanese's
/// year mark U+5E74).
typedef RawDateLiteralBuilder = Widget Function(
  BuildContext context,
  String literal,
);

/// Frames a date or time field's laid-out [segments] (its box, its focus
/// ring); [states] are the field's: focused (a segment has the focus),
/// hovered, disabled, error.
typedef RawDateFieldFrameBuilder = Widget Function(
  BuildContext context,
  Set<WidgetState> states,
  Widget segments,
);

/// A date typed in segments, in the reader's order: [value] is a calendar
/// day (its time ignored), null when empty; [onChanged] gets the day once
/// every segment holds one, and null when one is cleared.
///
/// The segments follow [RawWidgetsLocalizations.dateFieldPattern] (month, day,
/// year in English; day, month, year in German; year first in Japanese),
/// the text between them the locale's. A day past the month's end moves
/// back to its last day when the month or the year changes. Outside
/// [firstDate] and [lastDate] the segments carry [WidgetState.error], the
/// field reads as invalid and says so ([RawWidgetsLocalizations.dateOutOfRangeLabel]),
/// and the value still comes through.
///
/// Keys, on a segment (each a tab stop): digits type, Up and Down step it
/// (wrapping 12 on to 1), Home and End its least and greatest, Backspace
/// clears it and then moves back, Left and Right move as drawn, a typed
/// separator moves on, Enter calls [onEditingComplete].
///
/// ```dart
/// RawDateField(value: DateTime(2026, 11, 16), onChanged: (day) {}, segmentBuilder: (context, details) => Text(details.text))
/// ```
class RawDateField extends StatefulWidget {
  /// A date field showing [value].
  const RawDateField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segmentBuilder,
    this.literalBuilder,
    this.frameBuilder,
    this.firstDate,
    this.lastDate,
    this.semanticLabel,
    this.autofocus = false,
    this.onEditingComplete,
  });

  /// The day shown; null, empty.
  final DateTime? value;

  /// Called with the day once every segment holds one, and with null when a
  /// segment is cleared.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<DateTime?>? onChanged;

  /// Paints a segment.
  final RawDateSegmentBuilder segmentBuilder;

  /// Paints the text between segments; null: a [Text].
  final RawDateLiteralBuilder? literalBuilder;

  /// Frames the laid-out segments; null: the segments alone.
  final RawDateFieldFrameBuilder? frameBuilder;

  /// The first day in range; null: none before is out of range.
  final DateTime? firstDate;

  /// The last day in range; null: none after is out of range.
  final DateTime? lastDate;

  /// What a screen reader calls the field ("Date of birth"); null: nothing.
  final String? semanticLabel;

  /// Whether the first segment takes focus when it first shows.
  final bool autofocus;

  /// Called on Enter (and a phone keyboard's Done), never on a submit:
  /// a field commits as the web's Enter keeps typing.
  final VoidCallback? onEditingComplete;

  @override
  State<RawDateField> createState() => _DesignDateFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawDateSegmentBuilder>.has(
          'segmentBuilder',
          segmentBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawDateLiteralBuilder>.has(
          'literalBuilder',
          literalBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawDateFieldFrameBuilder>.has(
          'frameBuilder',
          frameBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(DiagnosticsProperty<DateTime>('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime?>>.has('onChanged', onChanged),
      )
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
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

/// A time of day typed in segments, on the reader's clock: [value] the
/// time, null when empty; [onChanged] gets it once every segment holds one,
/// and null when one is cleared.
///
/// The segments follow [RawWidgetsLocalizations.timeFieldPattern]: hour,
/// minute and AM/PM in English; a 24-hour clock in German, or wherever
/// [alwaysUse24HourFormat] (by default the platform's setting,
/// `MediaQuery.alwaysUse24HourFormatOf`) says so; seconds when
/// [showSeconds]. AM/PM takes the first letter of either word, and Up and
/// Down swap it. The keys are [RawDateField]'s.
///
/// ```dart
/// RawTimeField(value: const RawTimeOfDay(hour: 9, minute: 30), onChanged: (time) {}, segmentBuilder: (context, details) => Text(details.text))
/// ```
class RawTimeField extends StatefulWidget {
  /// A time field showing [value].
  const RawTimeField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.segmentBuilder,
    this.literalBuilder,
    this.frameBuilder,
    this.showSeconds = false,
    this.alwaysUse24HourFormat,
    this.semanticLabel,
    this.autofocus = false,
    this.onEditingComplete,
  });

  /// The time shown; null, empty.
  final RawTimeOfDay? value;

  /// Called with the time once every segment holds one, and with null when
  /// a segment is cleared.
  ///
  /// {@macro design.nullDisables}
  final ValueChanged<RawTimeOfDay?>? onChanged;

  /// Paints a segment.
  final RawDateSegmentBuilder segmentBuilder;

  /// Paints the text between segments; null: a [Text].
  final RawDateLiteralBuilder? literalBuilder;

  /// Frames the laid-out segments; null: the segments alone.
  final RawDateFieldFrameBuilder? frameBuilder;

  /// Whether it has a seconds segment. Defaults to false.
  final bool showSeconds;

  /// Whether the clock runs 0–23 with no AM/PM; null: the platform's
  /// setting where it is on, else the locale's clock.
  final bool? alwaysUse24HourFormat;

  /// What a screen reader calls the field ("Start time"); null: nothing.
  final String? semanticLabel;

  /// Whether the first segment takes focus when it first shows.
  final bool autofocus;

  /// Called on Enter (and a phone keyboard's Done).
  final VoidCallback? onEditingComplete;

  @override
  State<RawTimeField> createState() => _DesignTimeFieldState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        ObjectFlagProperty<RawDateSegmentBuilder>.has(
          'segmentBuilder',
          segmentBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawDateLiteralBuilder>.has(
          'literalBuilder',
          literalBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<RawDateFieldFrameBuilder>.has(
          'frameBuilder',
          frameBuilder,
        ),
      )
      ..add(
        ObjectFlagProperty<VoidCallback>.has(
          'onEditingComplete',
          onEditingComplete,
        ),
      )
      ..add(DiagnosticsProperty<RawTimeOfDay>('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<RawTimeOfDay?>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(
        FlagProperty(
          'showSeconds',
          value: showSeconds,
          ifTrue: 'showSeconds',
          defaultValue: false,
        ),
      )
      ..add(
        DiagnosticsProperty<bool>(
          'alwaysUse24HourFormat',
          alwaysUse24HourFormat,
          defaultValue: null,
        ),
      )
      ..add(StringProperty('semanticLabel', semanticLabel, defaultValue: null))
      ..add(
        FlagProperty(
          'autofocus',
          value: autofocus,
          ifTrue: 'autofocus',
          defaultValue: false,
        ),
      );
  }
}

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class _DesignDateFieldState extends _SegmentedFieldState<RawDateField> {
  bool _wasOutOfRange = false;

  @override
  bool get enabled => widget.onChanged != null;
  @override
  bool get autofocus => widget.autofocus;
  @override
  String? get semanticLabel => widget.semanticLabel;
  @override
  VoidCallback? get onEditingComplete => widget.onEditingComplete;
  @override
  RawDateSegmentBuilder get segmentBuilder => widget.segmentBuilder;
  @override
  RawDateLiteralBuilder? get literalBuilder => widget.literalBuilder;
  @override
  RawDateFieldFrameBuilder? get frameBuilder => widget.frameBuilder;

  @override
  String patternOf(RawWidgetsLocalizations l) => l.dateFieldPattern;

  @override
  void load() {
    final v = widget.value;
    values
      ..[RawDateSegmentType.year] = v?.year
      ..[RawDateSegmentType.month] = v?.month
      ..[RawDateSegmentType.day] = v?.day;
  }

  @override
  void didUpdateWidget(RawDateField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final v = widget.value;
    final day = v == null ? null : _dateOnly(v);
    if (oldWidget.value != v && day != _composed()) {
      load();
      sent = day;
    }
  }

  DateTime? _composed() {
    final y = values[RawDateSegmentType.year];
    final m = values[RawDateSegmentType.month];
    final d = values[RawDateSegmentType.day];
    if (y == null || m == null || d == null) return null;
    if (d > daysInMonth(y, m)) return null;
    return DateTime(y, m, d);
  }

  @override
  Object? compose() => _composed();

  @override
  void send(Object? value) => widget.onChanged?.call(value as DateTime?);

  @override
  int maxOf(PatternPart part) => segmentMax(
    part.letter,
    year: values[RawDateSegmentType.year],
    month: values[RawDateSegmentType.month],
  );

  @override
  void settle(RawDateSegmentType changed) {
    // A day past the month's end moves back to its last day (iOS's rule).
    if (changed == RawDateSegmentType.day) return;
    final m = values[RawDateSegmentType.month];
    final d = values[RawDateSegmentType.day];
    if (m == null || d == null) return;
    final last = daysInMonth(values[RawDateSegmentType.year], m);
    if (d > last) values[RawDateSegmentType.day] = last;
  }

  bool get _outOfRange {
    final day = _composed();
    if (day == null) return false;
    final first = widget.firstDate;
    final last = widget.lastDate;
    return (first != null && day.isBefore(_dateOnly(first))) ||
        (last != null && day.isAfter(_dateOnly(last)));
  }

  @override
  bool get hasError => _outOfRange;

  @override
  void afterChange() {
    final out = _outOfRange;
    if (out && !_wasOutOfRange) {
      rawAnnounce(
        context,
        RawWidgetsLocalizations.of(context).dateOutOfRangeLabel,
      );
    }
    _wasOutOfRange = out;
  }

  @override
  String? fieldValue(RawWidgetsLocalizations l) {
    final day = _composed();
    return day == null ? null : l.formatFullDate(day);
  }

  @override
  int stepFrom(PatternPart part, int delta) {
    final type = part.type!;
    final v = values[type];
    if (v == null) {
      if (type == RawDateSegmentType.year) {
        return (widget.firstDate ?? widget.lastDate ?? DateTime.now()).year;
      }
      return delta > 0 ? segmentMin(part.letter) : maxOf(part);
    }
    return stepSegment(
      v,
      delta,
      segmentMin(part.letter),
      maxOf(part),
      wrap: type != RawDateSegmentType.year,
    );
  }

  @override
  String spoken(PatternPart part, int value, RawWidgetsLocalizations l) =>
      part.type == RawDateSegmentType.month
      ? l.formatMonth(DateTime(2000, value))
      : digitsOf(l, value);
}

class _DesignTimeFieldState extends _SegmentedFieldState<RawTimeField> {
  // The clock the hour is held on: its pattern letter.
  String _clock = 'h';

  @override
  bool get enabled => widget.onChanged != null;
  @override
  bool get autofocus => widget.autofocus;
  @override
  String? get semanticLabel => widget.semanticLabel;
  @override
  VoidCallback? get onEditingComplete => widget.onEditingComplete;
  @override
  RawDateSegmentBuilder get segmentBuilder => widget.segmentBuilder;
  @override
  RawDateLiteralBuilder? get literalBuilder => widget.literalBuilder;
  @override
  RawDateFieldFrameBuilder? get frameBuilder => widget.frameBuilder;

  @override
  String patternOf(RawWidgetsLocalizations l) => l.timeFieldPattern(
    alwaysUse24HourFormat:
        widget.alwaysUse24HourFormat ??
        MediaQuery.alwaysUse24HourFormatOf(context),
    showSeconds: widget.showSeconds,
  );

  @override
  void patternChanged(List<PatternPart> parts) {
    final clock =
        parts
            .where((p) => p.type == RawDateSegmentType.hour)
            .firstOrNull
            ?.letter ??
        'H';
    if (clock == _clock) return;
    // The hour moves to the new clock through a 24-hour one.
    final hour = _hour24();
    _clock = clock;
    _setHour(hour);
  }

  bool get _twelve => _clock == 'h' || _clock == 'K';

  // The hour on a 24-hour clock, from the held clock (AM when not chosen).
  int? _hour24() {
    final h = values[RawDateSegmentType.hour];
    if (h == null) return null;
    final pm = values[RawDateSegmentType.dayPeriod] == 1;
    return switch (_clock) {
      'h' => h % 12 + (pm ? 12 : 0),
      'K' => h + (pm ? 12 : 0),
      'k' => h % 24,
      _ => h,
    };
  }

  void _setHour(int? hour) {
    if (hour == null) {
      values[RawDateSegmentType.hour] = null;
      return;
    }
    values[RawDateSegmentType.hour] = switch (_clock) {
      'h' => hour % 12 == 0 ? 12 : hour % 12,
      'K' => hour % 12,
      'k' => hour == 0 ? 24 : hour,
      _ => hour,
    };
    if (_twelve) values[RawDateSegmentType.dayPeriod] = hour >= 12 ? 1 : 0;
  }

  @override
  void load() {
    final v = widget.value;
    _setHour(v?.hour);
    if (v == null) values[RawDateSegmentType.dayPeriod] = null;
    values
      ..[RawDateSegmentType.minute] = v?.minute
      ..[RawDateSegmentType.second] = v?.second;
  }

  @override
  void didUpdateWidget(RawTimeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && widget.value != _composed()) {
      load();
      sent = widget.value;
    }
  }

  RawTimeOfDay? _composed() {
    final hour = _hour24();
    final minute = values[RawDateSegmentType.minute];
    if (hour == null || minute == null) return null;
    if (_twelve && values[RawDateSegmentType.dayPeriod] == null) return null;
    final second = widget.showSeconds
        ? values[RawDateSegmentType.second]
        : (values[RawDateSegmentType.second] ?? 0);
    if (second == null) return null;
    return RawTimeOfDay(hour: hour, minute: minute, second: second);
  }

  @override
  Object? compose() => _composed();

  @override
  void send(Object? value) => widget.onChanged?.call(value as RawTimeOfDay?);

  @override
  int maxOf(PatternPart part) => segmentMax(part.letter);

  @override
  int stepFrom(PatternPart part, int delta) {
    final v = values[part.type!];
    final min = segmentMin(part.letter);
    final max = maxOf(part);
    if (v == null) return delta > 0 ? min : max;
    return stepSegment(v, delta, min, max);
  }

  @override
  String spoken(PatternPart part, int value, RawWidgetsLocalizations l) =>
      part.type == RawDateSegmentType.dayPeriod
      ? (value == 0 ? l.anteMeridiemAbbreviation : l.postMeridiemAbbreviation)
      : digitsOf(l, value);

  @override
  String? fieldValue(RawWidgetsLocalizations l) {
    final time = _composed();
    if (time == null) return null;
    return l.formatTimeOfDay(
      time,
      alwaysUse24HourFormat: !_twelve,
      showSeconds: widget.showSeconds,
    );
  }
}

// The machinery both fields share: the segments from the locale's pattern,
// their focus, the keys, typing (the keyboard's keys, or a phone's keyboard
// through one text input), the semantics and the layout.
abstract class _SegmentedFieldState<W extends StatefulWidget> extends State<W>
    implements TextInputClient {
  /// Each segment's value, on its own scale (a 12-hour hour 1–12, AM 0).
  final Map<RawDateSegmentType, int?> values = {};

  /// The value last sent to (or taken from) the parent.
  Object? sent;

  final Map<RawDateSegmentType, FocusNode> _nodes = {};
  List<PatternPart> _parts = const [];
  String? _pattern;
  RawDateSegmentType? _focused;
  // The digits typed into the focused segment since it took the focus.
  String _typed = '';
  bool _hovered = false;
  TextInputConnection? _connection;

  // A phone keyboard edits two invisible characters: fewer is a Backspace,
  // more is typing.
  static const TextEditingValue _idle = TextEditingValue(
    text: '​​',
    selection: TextSelection.collapsed(offset: 2),
  );

  bool get enabled;
  bool get autofocus;
  String? get semanticLabel;
  VoidCallback? get onEditingComplete;
  RawDateSegmentBuilder get segmentBuilder;
  RawDateLiteralBuilder? get literalBuilder;
  RawDateFieldFrameBuilder? get frameBuilder;
  bool get hasError => false;

  String patternOf(RawWidgetsLocalizations l);
  void patternChanged(List<PatternPart> parts) {}
  void load();
  Object? compose();
  void send(Object? value);
  int maxOf(PatternPart part);
  int stepFrom(PatternPart part, int delta);
  void settle(RawDateSegmentType changed) {}
  void afterChange() {}
  String spoken(PatternPart part, int value, RawWidgetsLocalizations l);
  String? fieldValue(RawWidgetsLocalizations l);

  Iterable<PatternPart> get _segments => _parts.where((p) => p.type != null);

  @override
  void initState() {
    super.initState();
    load();
    sent = compose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _readPattern();
  }

  @override
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);
    _readPattern();
    if (!enabled) {
      _closeInput();
      for (final node in _nodes.values) {
        if (node.hasFocus) node.unfocus();
      }
    }
  }

  void _readPattern() {
    final pattern = patternOf(RawWidgetsLocalizations.of(context));
    if (pattern == _pattern) return;
    _pattern = pattern;
    _parts = parsePattern(pattern);
    patternChanged(_parts);
    for (final part in _segments) {
      _nodes.putIfAbsent(part.type!, () {
        final node = FocusNode(debugLabel: 'date segment ${part.type!.name}');
        node.addListener(() => _focusChanged(part.type!, node));
        return node;
      });
    }
  }

  @override
  void dispose() {
    _closeInput();
    for (final node in _nodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  PatternPart _part(RawDateSegmentType type) =>
      _segments.firstWhere((p) => p.type == type);

  // Digits in the reader's script, ungrouped ("2026", not "2,026").
  String digitsOf(RawWidgetsLocalizations l, int value, {int width = 1}) {
    final zero = l.formatDecimal(0).codeUnitAt(0);
    return String.fromCharCodes(
      value
          .toString()
          .padLeft(width, '0')
          .codeUnits
          .map((c) => zero + c - 0x30),
    );
  }

  // A typed digit's value: ASCII or the reader's; null when not a digit.
  int? _digit(String character, RawWidgetsLocalizations l) {
    if (character.length != 1) return null;
    final c = character.codeUnitAt(0);
    if (c >= 0x30 && c <= 0x39) return c - 0x30;
    final d = c - l.formatDecimal(0).codeUnitAt(0);
    return d >= 0 && d <= 9 ? d : null;
  }

  void _focusChanged(RawDateSegmentType type, FocusNode node) {
    if (!mounted) return;
    if (node.hasFocus) {
      if (_focused != type) {
        final left = _focused;
        _focused = type;
        _typed = '';
        if (left != null) _commit(left);
        _openInput();
      }
    } else if (_focused == type) {
      _focused = null;
      _typed = '';
      _commit(type);
      // Focus moved on within the field, or left it.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _focused == null) _closeInput();
      });
    }
    setState(() {});
  }

  // A segment left with a number below its least (a month's "0") is empty;
  // a year typed in part is taken as typed.
  void _commit(RawDateSegmentType type) {
    final part = _segments.where((p) => p.type == type).firstOrNull;
    if (part == null) return;
    final v = values[type];
    if (v != null && v < segmentMin(part.letter)) values[type] = null;
    _changed(type);
  }

  // After [type] changed: the other segments settle, the parent hears of a
  // new whole value (not while a year is half typed).
  void _changed(RawDateSegmentType type) {
    settle(type);
    final yearPending =
        _focused == RawDateSegmentType.year &&
        _typed.isNotEmpty &&
        _typed.length < 4;
    if (!yearPending) {
      final now = compose();
      if (now != sent) {
        sent = now;
        send(now);
      }
    }
    afterChange();
    setState(() {});
  }

  void _set(RawDateSegmentType type, int? value) {
    values[type] = value;
    _changed(type);
  }

  void _focus(RawDateSegmentType type) => _nodes[type]?.requestFocus();

  // The segment after (or before) [type] in the pattern.
  RawDateSegmentType? _beside(RawDateSegmentType type, int way) {
    final list = _segments.map((p) => p.type!).toList();
    final i = list.indexOf(type) + way;
    return i >= 0 && i < list.length ? list[i] : null;
  }

  void _advance(RawDateSegmentType type) {
    final next = _beside(type, 1);
    if (next != null) _focus(next);
  }

  // The segment drawn nearest [type] to the right (or left).
  RawDateSegmentType? _drawnBeside(RawDateSegmentType type, bool right) {
    Offset? centre(RawDateSegmentType t) {
      final box = _nodes[t]?.context?.findRenderObject();
      if (box is! RenderBox || !box.hasSize) return null;
      return box.localToGlobal(box.size.center(Offset.zero));
    }

    final from = centre(type);
    if (from == null) return null;
    RawDateSegmentType? best;
    var bestDx = double.infinity;
    for (final p in _segments) {
      final c = centre(p.type!);
      if (c == null || p.type == type) continue;
      final dx = right ? c.dx - from.dx : from.dx - c.dx;
      if (dx > 0 && dx < bestDx) {
        bestDx = dx;
        best = p.type;
      }
    }
    return best;
  }

  KeyEventResult _onKey(RawDateSegmentType type, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!enabled || _isShortcut) return KeyEventResult.ignored;
    final part = _part(type);
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(part, 1);
    } else if (key == LogicalKeyboardKey.arrowDown) {
      _step(part, -1);
    } else if (key == LogicalKeyboardKey.home) {
      _typed = '';
      _set(type, segmentMin(part.letter));
    } else if (key == LogicalKeyboardKey.end) {
      _typed = '';
      _set(type, maxOf(part));
    } else if (key == LogicalKeyboardKey.arrowLeft ||
        key == LogicalKeyboardKey.arrowRight) {
      final to = _drawnBeside(type, key == LogicalKeyboardKey.arrowRight);
      if (to != null) _focus(to);
    } else if (key == LogicalKeyboardKey.backspace) {
      _backspace(type);
    } else if (key == LogicalKeyboardKey.delete) {
      _typed = '';
      _set(type, null);
    } else if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter) {
      _done();
    } else {
      final character = event.character;
      if (character == null || character.isEmpty) {
        return KeyEventResult.ignored;
      }
      if (character.codeUnitAt(0) < 0x20) return KeyEventResult.ignored;
      _type(type, character);
    }
    return KeyEventResult.handled;
  }

  // A key pressed with Control, Meta or Alt held is a shortcut (Control-S,
  // Command-K, Control-Z), not typing, and goes on to the shortcuts above
  // the field. AltGr, which types characters on many layouts, is not one:
  // AltGraph itself, or right Alt with Control as Windows reports it.
  static bool get _isShortcut {
    final keys = HardwareKeyboard.instance;
    final altGr =
        keys.isLogicalKeyPressed(LogicalKeyboardKey.altGraph) ||
        (defaultTargetPlatform == TargetPlatform.windows &&
            keys.isLogicalKeyPressed(LogicalKeyboardKey.altRight) &&
            keys.isControlPressed);
    if (altGr) return false;
    return keys.isControlPressed || keys.isMetaPressed || keys.isAltPressed;
  }

  void _step(PatternPart part, int delta) {
    _typed = '';
    _set(part.type!, stepFrom(part, delta));
  }

  void _backspace(RawDateSegmentType type) {
    if (values[type] != null || _typed.isNotEmpty) {
      _typed = '';
      _set(type, null);
      return;
    }
    final before = _beside(type, -1);
    if (before != null) _focus(before);
  }

  void _done() {
    final type = _focused;
    if (type != null) {
      _typed = '';
      _commit(type);
    }
    onEditingComplete?.call();
  }

  // A character typed into [type]: a digit, AM/PM's letter, a separator.
  void _type(RawDateSegmentType type, String character) {
    final l = RawWidgetsLocalizations.of(context);
    final part = _part(type);
    if (type == RawDateSegmentType.dayPeriod) {
      // The first letter where the two words differ: a, p; the second of
      // Japanese's two (U+5348 U+524D and U+5348 U+5F8C share the first);
      // and a and p in any language.
      final am = l.anteMeridiemAbbreviation.toLowerCase();
      final pm = l.postMeridiemAbbreviation.toLowerCase();
      var at = 0;
      while (at < am.length && at < pm.length && am[at] == pm[at]) {
        at++;
      }
      final c = character.toLowerCase();
      final int? period;
      if (c == 'a' || (at < am.length && c == am[at])) {
        period = 0;
      } else if (c == 'p' || (at < pm.length && c == pm[at])) {
        period = 1;
      } else {
        period = null;
      }
      if (period != null) {
        _set(type, period);
        _advance(type);
      }
      return;
    }
    final digit = _digit(character, l);
    if (digit != null) {
      final typed = typeDigit(
        _typed,
        digit,
        min: segmentMin(part.letter),
        max: maxOf(part),
        digits: segmentDigits(part.letter),
      );
      _typed = typed.typed;
      values[type] = typed.value;
      if (typed.advance) {
        _typed = '';
        _commit(type);
        _advance(type);
      } else {
        _changed(type);
      }
      return;
    }
    // A separator moves on from a segment that holds a value.
    final i = _parts.indexOf(part);
    final after = i + 1 < _parts.length ? _parts[i + 1].literal ?? '' : '';
    if (values[type] != null &&
        (after.contains(character) || '/.-:, '.contains(character))) {
      _typed = '';
      _commit(type);
      _advance(type);
    }
  }

  // ---- A phone's keyboard: one text input while a segment has the focus.

  TextInputConfiguration get _configuration => TextInputConfiguration(
    inputType: _focused == RawDateSegmentType.dayPeriod
        ? TextInputType.text
        : TextInputType.number,
    inputAction: TextInputAction.done,
    autocorrect: false,
    enableSuggestions: false,
  );

  void _openInput() {
    if (!enabled) return;
    if (_connection?.attached ?? false) {
      _connection!
        ..updateConfig(_configuration)
        ..setEditingState(_idle)
        ..show();
      return;
    }
    _connection = TextInput.attach(this, _configuration)
      ..setEditingState(_idle)
      ..show();
  }

  void _closeInput() {
    _connection?.close();
    _connection = null;
  }

  @override
  TextEditingValue get currentTextEditingValue => _idle;

  @override
  AutofillScope? get currentAutofillScope => null;

  @override
  void updateEditingValue(TextEditingValue value) {
    final type = _focused;
    if (type == null || value.text == _idle.text) return;
    if (value.text.length < _idle.text.length) {
      _backspace(type);
    } else {
      final typed = value.text.replaceAll('​', '');
      for (final character in typed.split('')) {
        final at = _focused;
        if (at == null) break;
        _type(at, character);
      }
    }
    _connection?.setEditingState(_idle);
  }

  @override
  void performAction(TextInputAction action) => _done();

  @override
  void connectionClosed() => _connection = null;

  @override
  bool onFocusReceived() => false;

  @override
  void performPrivateCommand(String action, Map<String, dynamic> data) {}

  @override
  void updateFloatingCursor(RawFloatingCursorPoint point) {}

  @override
  void showAutocorrectionPromptRect(int start, int end) {}

  @override
  void insertTextPlaceholder(Size size) {}

  @override
  void removeTextPlaceholder() {}

  @override
  void showToolbar() {}

  @override
  void didChangeInputControl(
    TextInputControl? oldControl,
    TextInputControl? newControl,
  ) {}

  @override
  void performSelector(String selectorName) {}

  @override
  void insertContent(KeyboardInsertedContent content) {}

  // ---- Building.

  String _placeholder(RawDateSegmentType type, RawWidgetsLocalizations l) =>
      switch (type) {
        RawDateSegmentType.year => l.dateFieldYearPlaceholder,
        RawDateSegmentType.month => l.dateFieldMonthPlaceholder,
        RawDateSegmentType.day => l.dateFieldDayPlaceholder,
        _ => '––',
      };

  String _label(RawDateSegmentType type, RawWidgetsLocalizations l) =>
      switch (type) {
        RawDateSegmentType.year => l.dateFieldYearLabel,
        RawDateSegmentType.month => l.dateFieldMonthLabel,
        RawDateSegmentType.day => l.dateFieldDayLabel,
        RawDateSegmentType.hour => l.timePickerHourLabel,
        RawDateSegmentType.minute => l.timePickerMinuteLabel,
        RawDateSegmentType.second => l.timeFieldSecondLabel,
        RawDateSegmentType.dayPeriod => l.timeFieldDayPeriodLabel,
      };

  String _text(PatternPart part, RawWidgetsLocalizations l) {
    final type = part.type!;
    if (_focused == type && _typed.isNotEmpty) {
      return digitsOf(l, int.parse(_typed), width: _typed.length);
    }
    final v = values[type]!;
    if (type == RawDateSegmentType.dayPeriod) {
      return v == 0 ? l.anteMeridiemAbbreviation : l.postMeridiemAbbreviation;
    }
    return digitsOf(l, v, width: part.width >= 2 ? 2 : 1);
  }

  Widget _segment(
    BuildContext context,
    PatternPart part,
    RawWidgetsLocalizations l,
  ) {
    final type = part.type!;
    final value = values[type];
    final empty = value == null && !(_focused == type && _typed.isNotEmpty);
    final node = _nodes[type]!;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && node.hasFocus) WidgetState.focused,
      if (hasError) WidgetState.error,
    };
    final up = enabled ? stepFrom(part, 1) : null;
    final down = enabled ? stepFrom(part, -1) : null;
    String say(int v) => spoken(part, v, l);
    void tap() {
      if (!enabled) return;
      if (node.hasFocus) {
        _openInput();
      } else {
        node.requestFocus();
      }
    }

    final face = segmentBuilder(
      context,
      RawDateSegmentDetails(
        type: type,
        text: empty ? _placeholder(type, l) : _text(part, l),
        isPlaceholder: empty,
        states: states,
      ),
    );
    return Semantics(
      container: true,
      label: _label(type, l),
      value: value == null ? l.emptyValueLabel : say(value),
      increasedValue: up == null ? null : say(up),
      decreasedValue: down == null ? null : say(down),
      onIncrease: up == null ? null : () => _step(part, 1),
      onDecrease: down == null ? null : () => _step(part, -1),
      onTap: enabled ? tap : null,
      enabled: enabled,
      child: Focus(
        focusNode: node,
        canRequestFocus: enabled,
        skipTraversal: !enabled,
        autofocus: autofocus && part == _segments.first,
        onKeyEvent: (_, event) => _onKey(type, event),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          excludeFromSemantics: true,
          onTap: enabled ? tap : null,
          child: ExcludeSemantics(child: face),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = RawWidgetsLocalizations.of(context);
    var order = 0.0;
    Widget part(PatternPart p) {
      if (p.literal != null) {
        return ExcludeSemantics(
          child: literalBuilder?.call(context, p.literal!) ?? Text(p.literal!),
        );
      }
      return FocusTraversalOrder(
        order: NumericFocusOrder(order++),
        child: _segment(context, p, l),
      );
    }

    final built = [for (final p in _parts) part(p)];
    // The segments lie on one line when they fit, and wrap between parts
    // when the frame is narrower: each segment kept with the text after it
    // ("16 /", "11 /", "2026"), so that no line starts with a separator.
    // Right to left, a run of digits still reads left to right
    // ("16.11.2026", "3:05"), as the bidi algorithm reads a number, and
    // wraps the same way within itself, its lines kept to the right as the
    // field's are; a run with text after it keeps to one line with that
    // text.
    final rtl = Directionality.of(context) == TextDirection.rtl;
    bool text(int i) => _parts[i].literal != null;
    Widget row(List<Widget> children, [TextDirection? direction]) =>
        children.length == 1
        ? children.single
        : Row(
            mainAxisSize: MainAxisSize.min,
            textDirection: direction,
            children: children,
          );
    Widget wrap(
      List<Widget> children, [
      TextDirection? direction,
      WrapAlignment alignment = WrapAlignment.start,
    ]) => Wrap(
      textDirection: direction,
      alignment: alignment,
      runAlignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: children,
    );
    Widget kept(List<int> parts, [TextDirection? direction]) =>
        row([for (final i in parts) built[i]], direction);
    final segments = rtl
        ? wrap([
            for (final runs in unbreakable(
              numberRuns(_parts),
              (run) => run.length == 1 && text(run.single),
            ))
              if (runs case [final run] when run.length > 1)
                wrap(
                  [
                    for (final parts in unbreakable(run, text))
                      kept(parts, TextDirection.ltr),
                  ],
                  TextDirection.ltr,
                  WrapAlignment.end,
                )
              else
                row([
                  for (final run in runs)
                    run.length == 1
                        ? built[run.single]
                        : kept(run, TextDirection.ltr),
                ]),
          ])
        : wrap([
            for (final parts in unbreakable([
              for (var i = 0; i < _parts.length; i++) i,
            ], text))
              kept(parts),
          ]);
    final focused = _focused != null;
    final states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (enabled && focused) WidgetState.focused,
      if (enabled && _hovered) WidgetState.hovered,
      if (hasError) WidgetState.error,
    };
    final value = fieldValue(l);
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: semanticLabel,
      value: value,
      hint: hasError ? l.dateOutOfRangeLabel : null,
      validationResult: hasError
          ? SemanticsValidationResult.invalid
          : SemanticsValidationResult.none,
      child: FocusTraversalGroup(
        policy: OrderedTraversalPolicy(),
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            // A tap off the segments goes to the first empty one, or the
            // first.
            onTap: enabled
                ? () {
                    if (_focused != null) return;
                    final first = _segments.firstWhere(
                      (p) => values[p.type!] == null,
                      orElse: () => _segments.first,
                    );
                    _focus(first.type!);
                  }
                : null,
            child: frameBuilder?.call(context, states, segments) ?? segments,
          ),
        ),
      ),
    );
  }
}
