import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../internal/panel.dart' show frostedRingFor;
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../forms/forms.dart';
import '../pressable/pressable.dart';
import '../raise/raise.dart';
import '../../internal/dim.dart';

import 'package:ui_core/ui_core.dart';

import '../../internal/shared_words.dart';

// ---------------------------------------------------------------------------
// Time of day
// ---------------------------------------------------------------------------

/// A time of day, hour and minute on the 24-hour clock, owing nothing to a
/// platform's design library.
///
/// ```dart
/// const FrostedTime(hour: 9, minute: 30)
/// ```
@immutable
class FrostedTime {
  /// [hour] 0 to 23 and [minute] 0 to 59.
  const FrostedTime({required this.hour, required this.minute})
    : assert(hour >= 0 && hour < 24),
      assert(minute >= 0 && minute < 60);

  /// The wall-clock time of [value].
  factory FrostedTime.fromDateTime(DateTime value) =>
      FrostedTime(hour: value.hour, minute: value.minute);

  /// The time now, on this device's clock.
  factory FrostedTime.now() => FrostedTime.fromDateTime(DateTime.now());

  /// The hour, 0 to 23.
  final int hour;

  /// The minute, 0 to 59.
  final int minute;

  /// This time with [hour] or [minute] changed.
  FrostedTime copyWith({int? hour, int? minute}) =>
      FrostedTime(hour: hour ?? this.hour, minute: minute ?? this.minute);

  /// The time in the installed words: 9:30 AM, or 09:30 where the platform
  /// or the words keep the 24-hour clock.
  String format(BuildContext context) =>
      FrostedSharedWords.of(context).time(hour, minute, use24: _use24(context));

  @override
  bool operator ==(Object other) =>
      other is FrostedTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => 'FrostedTime(${_two(hour)}:${_two(minute)})';
}

String _two(int n) => n.toString().padLeft(2, '0');

bool _use24(BuildContext context) =>
    MediaQuery.maybeAlwaysUse24HourFormatOf(context) ??
    FrostedLocalizations.of(context).alwaysUse24HourFormat;

// ---------------------------------------------------------------------------
// Wheel
// ---------------------------------------------------------------------------

// The wheel's row and the rows it shows.
const double _wheelRow = 40;
const int _wheelRows = 5;

/// A drum of [options] turned by a drag, a fling, a wheel or the arrow keys
/// (Cupertino's picker): the chosen row on a band of the brighter glass
/// with its hairline edge and rim, the rows above and below it receding and
/// fading to nothing. It settles on a row and hands over that row's value.
/// Read aloud as an adjustable value named [label]: a swipe up or down
/// turns it a row. A disabled option stands faded and the wheel turns past
/// it. ui_core's [RawPicker] is the behaviour: the arrows, Page Up
/// and Down, Home and End, and typing a row's first letters turn it on a
/// spring, and a row crossing the band ticks.
///
/// ```dart
/// FrostedWheelPicker<int>(label: 'Guests', options: [for (var n = 1; n <= 12; n++) FrostedSelectOption(n, '$n')], value: guests, onChanged: (v) => setState(() => guests = v))
/// ```
class FrostedWheelPicker<T> extends StatelessWidget {
  /// A wheel over [options], standing on [value].
  const FrostedWheelPicker({
    required this.options,
    required this.value,
    required this.label,
    this.onChanged,
    this.looping = false,
    this.width,
    super.key,
  });

  /// The rows, top to bottom.
  final List<FrostedSelectOption<T>> options;

  /// The value the wheel stands on.
  final T value;

  /// What a screen reader calls the wheel.
  final String label;

  /// Hands over the value the wheel settles on; null leaves it inert.
  final ValueChanged<T>? onChanged;

  /// Whether the last row runs on into the first.
  final bool looping;

  /// The wheel's width; null fills what it is given.
  final double? width;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return SizedBox(
      width: width,
      height: _wheelRow * _wheelRows,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _WheelBand(t: t),
          _wheels(
            context,
            live: onChanged != null,
            columns: [
              RawPickerColumn(
                itemCount: options.length,
                itemLabel: (i) => options[i].label,
                semanticLabel: label,
                isItemEnabled: (i) => options[i].enabled,
                looping: looping,
              ),
            ],
            selection: [_indexOf(value)],
            onChanged: (picked) {
              final option = options[picked.first];
              if (option.enabled && option.value != value) {
                onChanged?.call(option.value);
              }
            },
          ),
        ],
      ),
    );
  }

  int _indexOf(T value) {
    final i = options.indexWhere((o) => o.value == value);
    return i < 0 ? 0 : i;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(IterableProperty<FrostedSelectOption<T>>('options', options))
      ..add(DiagnosticsProperty<T>('value', value))
      ..add(StringProperty('label', label))
      ..add(ObjectFlagProperty<ValueChanged<T>>.has('onChanged', onChanged))
      ..add(FlagProperty('looping', value: looping, ifTrue: 'looping'))
      ..add(DoubleProperty('width', width, defaultValue: null));
  }
}

/// The band the chosen row of a wheel stands on.
class _WheelBand extends StatelessWidget {
  const _WheelBand({required this.t});

  final FrostedThemeData t;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: SizedBox(
      height: _wheelRow,
      width: double.infinity,
      child: Builder(
        builder: (context) {
          // The time picker's theme style dresses the band the chosen row
          // stands in: its fill, edge or side and shape.
          final s = FrostedStyleLayers(null, t.components.timePicker);
          final cut = s.shape;
          final (edge, edges) = s.edgeOf(t.glass.edge, FrostedStrokes.regular);
          return FrostedFace(
            material: FrostedMaterial.paint,
            radius: BorderRadius.circular(
              FrostedStyleLayers.radiusOf(cut, _wheelRow, FrostedCorners.r12),
            ),
            shape: cut,
            color: s.fill ?? t.glass.fillHigh,
            edge: edge,
            edges: edges,
            sheen: t.glass.rim,
          );
        },
      ),
    ),
  );
}

/// Frosted's wheels on ui_core's [RawPicker] (the turning, its
/// settling and its spring, the keys, a screen reader's steps, the haptic
/// tick): [columns] standing on [selection], each row in the body type (the
/// chosen one in the 600 ink), the rows above and below receding and fading
/// to nothing on Frosted's drum, a column's focus ring at the band's
/// radius. [align] places a column's rows (centred when null); [layout]
/// lays the columns out (a row of equal ones when null). Inert, and dimmed,
/// unless [live].
Widget _wheels(
  BuildContext context, {
  required bool live,
  required List<RawPickerColumn> columns,
  required List<int> selection,
  required ValueChanged<List<int>> onChanged,
  Alignment Function(int column)? align,
  Widget Function(BuildContext context, List<Widget> columns)? layout,
}) {
  final t = context.frostedTheme;
  final style = t.textTheme.bodyLarge.line(_wheelRow / 2);
  return FrostedDim(
    off: !live,
    child: RawPicker(
      columns: (_) => columns,
      selection: selection,
      onChanged: live && columns.every((c) => c.itemCount > 0)
          ? onChanged
          : null,
      itemExtent: _wheelRow,
      visibleItemCount: _wheelRows,
      diameterRatio: 1.6,
      perspective: 0.004,
      squeeze: 1,
      layoutBuilder: layout,
      itemBuilder: (context, row) => Align(
        alignment: align?.call(row.column) ?? Alignment.center,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.s12),
          child: FrostedDim(
            off: !row.enabled && live,
            child: Text(
              row.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.ellipsis,
              style: row.selected
                  ? style.semibold.c(t.colorScheme.textPrimary)
                  : style.c(t.colorScheme.textSecondary),
            ),
          ),
        ),
      ),
      columnBuilder: (context, column, wheel) => frostedRingFor(
        column.states,
        ShaderMask(
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
            stops: [0, 0.3, 0.7, 1],
          ).createShader(bounds),
          child: wheel,
        ),
        radius: FrostedCorners.r12,
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Time picker
// ---------------------------------------------------------------------------

/// A time of day on wheels (Cupertino's time picker, `showTimePicker`'s
/// role): the hour, the minute and, on the 12-hour clock, the half of the
/// day, side by side on one band of the brighter glass. Each wheel is read
/// aloud as an adjustable value (Hour, Minute) and turns with the arrow
/// keys once focused. [minuteInterval] steps the minutes (5 shows :00,
/// :05 …). [showFrostedTimePicker] raises it in a card with Cancel and OK.
///
/// ```dart
/// FrostedTimePicker(value: alarm, onChanged: (v) => setState(() => alarm = v))
/// ```
class FrostedTimePicker extends StatelessWidget {
  /// A picker standing on [value] (midnight when null).
  const FrostedTimePicker({
    this.value,
    this.onChanged,
    this.minuteInterval = 1,
    super.key,
  }) : assert(minuteInterval > 0 && 60 % minuteInterval == 0);

  /// The time it stands on.
  final FrostedTime? value;

  /// Hands over the time once a wheel settles; null leaves it inert.
  final ValueChanged<FrostedTime>? onChanged;

  /// The step between the minutes shown.
  final int minuteInterval;

  @override
  Widget build(BuildContext context) => Align(
    // The block stands at the line's start in the page's own direction
    // (inside the island it stood at the left of a right-to-left page); its
    // wheels read left to right, as figures do in any language.
    alignment: AlignmentDirectional.centerStart,
    heightFactor: 1,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Builder(builder: _ltrBuild),
      ),
    ),
  );

  Widget _ltrBuild(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final now = value ?? const FrostedTime(hour: 0, minute: 0);
    final h24 = _use24(context);
    final change = onChanged;
    final minute = now.minute - now.minute % minuteInterval;
    void set(FrostedTime next) => change?.call(next);

    // The hour's row i: 1 to 12 on the 12-hour clock (12 first is midnight
    // and noon), 00 to 23 on the 24-hour one.
    final hourIndex = h24 ? now.hour : (now.hour % 12 + 11) % 12;
    // Frosted's own words where an app gives them; left at English, the
    // shared ones ui_core speaks in the reader's language.
    final shared = RawWidgetsLocalizations.of(context);
    const english = FrostedLocalizationsEn();
    String say(String own, String plain, String theirs) =>
        own == plain ? theirs : own;
    final hourName = say(words.hour, english.hour, shared.timePickerHourLabel);
    final minuteName = say(
      words.minute,
      english.minute,
      shared.timePickerMinuteLabel,
    );
    final am = say(words.am, english.am, shared.anteMeridiemAbbreviation);
    final pm = say(words.pm, english.pm, shared.postMeridiemAbbreviation);
    final halves = [am, pm];
    final wheels = _wheels(
      context,
      live: change != null,
      columns: [
        RawPickerColumn(
          itemCount: h24 ? 24 : 12,
          itemLabel: (i) => h24 ? _two(i) : '${i + 1}',
          semanticLabel: hourName,
          looping: true,
        ),
        RawPickerColumn(
          itemCount: 60 ~/ minuteInterval,
          itemLabel: (i) => _two(i * minuteInterval),
          semanticLabel: minuteName,
          looping: true,
        ),
        if (!h24)
          RawPickerColumn(
            itemCount: 2,
            itemLabel: (i) => halves[i],
            semanticLabel: words.am == english.am && words.pm == english.pm
                ? shared.timeFieldDayPeriodLabel
                : '$am / $pm',
          ),
      ],
      selection: [
        hourIndex,
        minute ~/ minuteInterval,
        if (!h24) now.hour >= 12 ? 1 : 0,
      ],
      onChanged: (picked) {
        final pm = h24 ? false : picked[2] == 1;
        final hour = h24 ? picked[0] : (picked[0] + 1) % 12 + (pm ? 12 : 0);
        final next = FrostedTime(
          hour: hour,
          minute: picked[1] * minuteInterval,
        );
        if (next != now) set(next);
      },
      // The hour's figures end at the colon and the minute's start after it.
      align: (column) => switch (column) {
        0 => Alignment.centerRight,
        1 => Alignment.centerLeft,
        _ => Alignment.center,
      },
      layout: (context, columns) => Row(
        children: [
          Expanded(child: columns[0]),
          SizedBox(
            width: FrostedSpacing.s8,
            child: Center(
              child: ExcludeSemantics(
                child: Text(
                  ':',
                  style: t.textTheme.bodyLarge.semibold.c(
                    t.colorScheme.textPrimary,
                  ),
                ),
              ),
            ),
          ),
          Expanded(child: columns[1]),
          if (columns.length > 2) Expanded(child: columns[2]),
        ],
      ),
    );
    // At most 360 wide, at the start of a wider field: the hour, the minute
    // and the half of the day stay together on one short band.
    final picker = SizedBox(
      height: _wheelRow * _wheelRows,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _WheelBand(t: t),
          wheels,
        ],
      ),
    );
    return picker;
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(
        DiagnosticsProperty<FrostedTime>('value', value, defaultValue: null),
      )
      ..add(
        ObjectFlagProperty<ValueChanged<FrostedTime>>.has(
          'onChanged',
          onChanged,
        ),
      )
      ..add(IntProperty('minuteInterval', minuteInterval, defaultValue: 1));
  }
}

/// Raises a [FrostedTimePicker] in a card over the whole app, standing on
/// [initialTime] (now, when null), and completes with the time chosen: null
/// when cancelled or dismissed. The same role as `showTimePicker`.
///
/// ```dart
/// final time = await showFrostedTimePicker(context, initialTime: alarm);
/// ```
Future<FrostedTime?> showFrostedTimePicker(
  BuildContext context, {
  FrostedTime? initialTime,
  int minuteInterval = 1,
  String? title,
}) {
  var chosen = initialTime ?? FrostedTime.now();
  chosen = chosen.copyWith(
    minute: chosen.minute - chosen.minute % minuteInterval,
  );
  return showFrostedDialog<FrostedTime>(
    context,
    builder: (dialogContext) => _PickerCard(
      title: title ?? FrostedLocalizations.of(dialogContext).selectTime,
      onDone: () => Navigator.of(dialogContext).pop(chosen),
      child: StatefulBuilder(
        builder: (context, setState) => FrostedTimePicker(
          value: chosen,
          minuteInterval: minuteInterval,
          onChanged: (v) => setState(() => chosen = v),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Date picker
// ---------------------------------------------------------------------------

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _monthOf(DateTime d) => DateTime(d.year, d.month);
bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// A month of days to choose one from (`CalendarDatePicker`): the month's
/// name between a step back and a step on, the weekdays' two letters in the
/// quiet caption, then the days in rows of seven from the words' first day
/// of the week. The chosen day stands on the ink act's light, today in a
/// hairline ring, a day outside [firstDate] to [lastDate] faded and inert. Each day
/// is a button read as its full date; the month's name is announced as it
/// turns. [showFrostedDatePicker] raises it in a card with Cancel and OK.
///
/// ```dart
/// FrostedDatePicker(value: due, firstDate: DateTime(2026), lastDate: DateTime(2027, 12, 31), onChanged: (d) => setState(() => due = d))
/// ```
class FrostedDatePicker extends StatefulWidget {
  /// A month standing on [value] (or today's month).
  const FrostedDatePicker({
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.currentDate,
    super.key,
  });

  /// The chosen day.
  final DateTime? value;

  /// Hands over the day pressed; null leaves the days inert.
  final ValueChanged<DateTime>? onChanged;

  /// The earliest day that can be chosen; null sets no floor.
  final DateTime? firstDate;

  /// The latest day that can be chosen; null sets no ceiling.
  final DateTime? lastDate;

  /// Today, for its ring; null asks the device's clock.
  final DateTime? currentDate;

  @override
  State<FrostedDatePicker> createState() => _FrostedDatePickerState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value, defaultValue: null))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
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
      ..add(
        DiagnosticsProperty<DateTime>(
          'currentDate',
          currentDate,
          defaultValue: null,
        ),
      );
  }
}

class _FrostedDatePickerState extends State<FrostedDatePicker> {
  late DateTime _month = _monthOf(
    widget.value ?? widget.currentDate ?? DateTime.now(),
  );

  @override
  void didUpdateWidget(FrostedDatePicker old) {
    super.didUpdateWidget(old);
    final v = widget.value;
    if (v != null && v != old.value && _monthOf(v) != _month) {
      _month = _monthOf(v);
    }
  }

  bool _allowed(DateTime day) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    if (first != null && day.isBefore(_day(first))) return false;
    if (last != null && day.isAfter(_day(last))) return false;
    return true;
  }

  void _go(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final today = _day(widget.currentDate ?? DateTime.now());
    final first = widget.firstDate;
    final last = widget.lastDate;
    final canBack = first == null || _month.isAfter(_monthOf(first));
    final canOn = last == null || _month.isBefore(_monthOf(last));
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead =
        (_month.weekday - RawWidgetsLocalizations.of(context).firstDayOfWeek) %
        7;
    final shared = FrostedSharedWords.of(context);
    final title = shared.monthYear(_month);

    Widget step(IconData glyph, String label, VoidCallback? go) =>
        FrostedPressable(
          onPressed: go,
          label: label,
          radius: 18,
          child: SizedBox.square(
            dimension: 36,
            child: FrostedDim(
              off: go == null,
              child: Icon(
                glyph,
                size: FrostedChromeMetrics.pickerGlyph + 2,
                color: t.colorScheme.textPrimary,
              ),
            ),
          ),
        );

    final head = Row(
      children: [
        Expanded(
          child: Semantics(
            liveRegion: true,
            header: true,
            // On the column's edge, as the field labels above it are.
            child: Text(
              title,
              style: t.textTheme.labelLarge.c(t.colorScheme.textPrimary),
            ),
          ),
        ),
        step(
          FrostedGlyphs.chevronLeft,
          RawWidgetsLocalizations.of(context).previousMonthTooltip,
          canBack ? () => _go(-1) : null,
        ),
        step(
          FrostedGlyphs.forward,
          RawWidgetsLocalizations.of(context).nextMonthTooltip,
          canOn ? () => _go(1) : null,
        ),
      ],
    );

    final weekdays = ExcludeSemantics(
      child: Row(
        children: [
          for (var i = 0; i < 7; i++)
            Expanded(
              child: Center(
                child: Text(
                  RawWidgetsLocalizations.of(context).formatShortWeekday(
                    (RawWidgetsLocalizations.of(context).firstDayOfWeek -
                                1 +
                                i) %
                            7 +
                        1,
                  ),
                  style: t.textTheme.labelMedium,
                ),
              ),
            ),
        ],
      ),
    );

    // The date picker's theme style dresses the day cells: fill (selected
    // for the chosen day), words, edge (today's ring) or side, overlay and
    // shape, each per state.
    final dayStyle = FrostedStyleLayers(null, t.components.datePicker);
    final dayCut = dayStyle.cut(FrostedCorners.full);
    final dayCorner = FrostedStyleLayers.radiusOf(dayCut, 38, 19);
    Widget cell(int n) {
      final day = DateTime(_month.year, _month.month, n);
      final allowed = _allowed(day);
      final chosen = widget.value != null && _sameDay(widget.value!, day);
      final isToday = _sameDay(today, day);
      final change = widget.onChanged;
      final ink = chosen
          ? t.colorScheme.onButton
          : isToday
          ? t.colorScheme.textPrimary
          : t.colorScheme.textSecondary;
      Widget draw(Set<WidgetState> states) {
        final s = dayStyle.at(states);
        final fill = s.fill;
        final side = s.side;
        Widget face = SizedBox.square(
          dimension: 38,
          // Today, not chosen, is by day a small bead of glass in a field's
          // language (a well, its rim the lit hairline), its number in the
          // ink: never a dark ring. By night its light ring.
          child: FrostedFace(
            material: isToday && !chosen && fill == null && !t.isDark
                ? FrostedMaterial.well
                : FrostedMaterial.paint,
            radius: BorderRadius.circular(dayCorner),
            shape: dayCut,
            color: fill,
            gradients: chosen && fill == null
                ? [t.colorScheme.buttonFill]
                : const [],
            wash: s.overlay,
            edge: side?.color,
            edges: EdgeInsets.all(side?.width ?? FrostedStrokes.regular),
            sheen: chosen ? t.colorScheme.buttonSheen : null,
            shadows: chosen ? t.shadows.button : const [],
            ring: isToday && !chosen && side == null
                ? s.edge ?? frostedLitEdge(t, t.colorScheme.borderStrong)
                : null,
            child: Center(
              child: Text(
                '$n',
                style: s.words(
                  (chosen || isToday
                          ? t.textTheme.labelLarge.semibold
                          : t.textTheme.labelLarge)
                      .c(ink)
                      .tabular,
                ),
              ),
            ),
          ),
        );
        face = FrostedDim(off: !allowed, child: face);
        return Center(child: face);
      }

      return FrostedPressable(
        onPressed: allowed && change != null ? () => change(day) : null,
        label: shared.fullDate(day),
        selected: chosen,
        radius: dayCorner,
        shape: dayCut,
        builder: (context, states, _) => draw(states),
      );
    }

    // A day's row is the touch target tall (48 under a finger, 44 under a
    // pointer, never under the source's 44); the rows close up by what the
    // target adds, so the days keep their pitch and the card its height.
    final row = math.max(
      FrostedChromeMetrics.pickerDayRow,
      FrostedBreakpoints.hitTargetOf(context),
    );
    final rowGap = math.max(
      0.0,
      FrostedSpacing.s4 - (row - FrostedChromeMetrics.pickerDayRow),
    );
    final rows = <Widget>[];
    for (var start = 1 - lead; start <= days; start += 7) {
      rows.add(
        SizedBox(
          height: row,
          child: Row(
            children: [
              for (var n = start; n < start + 7; n++)
                Expanded(child: n < 1 || n > days ? const SizedBox() : cell(n)),
            ],
          ),
        ),
      );
    }
    // Six rows always, so the card keeps its height month to month.
    while (rows.length < 6) {
      rows.add(SizedBox(height: row));
    }

    // A month stands at most 400 wide, at the start of a wider field, as
    // the calendar's does.
    return Align(
      alignment: AlignmentDirectional.centerStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Semantics(
          container: true,
          explicitChildNodes: true,
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: FrostedSpacing.s4,
              children: [
                head,
                const SizedBox(height: FrostedSpacing.s4),
                weekdays,
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: rowGap,
                  children: rows,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Raises a [FrostedDatePicker] in a card over the whole app, standing on
/// [initialDate] (today, when null), and completes with the day chosen:
/// null when cancelled or dismissed; [currentDate] is the day ringed as
/// today (the clock's, when null). The same role as `showDatePicker`.
///
/// ```dart
/// final day = await showFrostedDatePicker(context, initialDate: due, first: DateTime(2026), last: DateTime(2027, 12, 31));
/// ```
Future<DateTime?> showFrostedDatePicker(
  BuildContext context, {
  DateTime? initialDate,
  DateTime? first,
  DateTime? last,
  DateTime? currentDate,
  String? title,
}) {
  var chosen = initialDate == null ? null : _day(initialDate);
  return showFrostedDialog<DateTime>(
    context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => _PickerCard(
        title: title ?? FrostedLocalizations.of(dialogContext).selectDate,
        onDone: chosen == null
            ? null
            : () => Navigator.of(dialogContext).pop(chosen),
        child: FrostedDatePicker(
          value: chosen,
          firstDate: first,
          lastDate: last,
          currentDate: currentDate,
          onChanged: (d) => setState(() => chosen = d),
        ),
      ),
    ),
  );
}

/// The card a picker is raised in: the dialog's face, 360 at most, the
/// [title] over the picker, Cancel and OK at its foot.
class _PickerCard extends StatelessWidget {
  const _PickerCard({
    required this.title,
    required this.onDone,
    required this.child,
  });

  final String title;
  final VoidCallback? onDone;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: FrostedFace(
          material: FrostedMaterial.slab,
          radius: BorderRadius.circular(FrostedChromeMetrics.sheetWideRadius),
          edge: t.glass.sheetEdge,
          sheen: t.glass.rim,
          shadows: t.shadows.dialog,
          clipChild: true,
          padding: const EdgeInsets.all(FrostedSpacing.s16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: FrostedSpacing.s16,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: t.textTheme.titleLarge),
              ),
              child,
              Row(
                spacing: FrostedSpacing.s8,
                children: [
                  Expanded(
                    child: FrostedButton.glass(
                      RawWidgetsLocalizations.of(context).cancelButtonLabel,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: FrostedButton(
                      RawWidgetsLocalizations.of(context).okButtonLabel,
                      expand: true,
                      onPressed: onDone,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
