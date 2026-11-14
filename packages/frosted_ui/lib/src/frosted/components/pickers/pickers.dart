import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../chrome_metrics.dart';
import '../../glyphs.dart';
import '../../internal/face.dart';
import '../../internal/styled.dart';
import '../../internal/hit_slop.dart';
import '../../internal/key_focus.dart';
import '../../localizations.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../forms/forms.dart';
import '../pressable/pressable.dart';
import '../raise/raise.dart';
import '../../internal/dim.dart';

import 'package:ui_core/ui_core.dart';

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
  String format(BuildContext context) {
    final words = FrostedLocalizations.of(context);
    if (_use24(context)) {
      return '${_two(hour)}:${_two(minute)}';
    }
    final h = hour % 12 == 0 ? 12 : hour % 12;
    return '$h:${_two(minute)} ${hour < 12 ? words.am : words.pm}';
  }

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
/// turns it a row. A disabled option stands faded and is never handed over.
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
          _Wheel<T>(
            options: options,
            value: value,
            label: label,
            onChanged: onChanged,
            looping: looping,
          ),
        ],
      ),
    );
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

class _Wheel<T> extends StatefulWidget {
  const _Wheel({
    required this.options,
    required this.value,
    required this.label,
    required this.onChanged,
    required this.looping,
    this.align = Alignment.center,
  });

  final List<FrostedSelectOption<T>> options;
  final T value;
  final String label;
  final ValueChanged<T>? onChanged;
  final bool looping;
  final Alignment align;

  @override
  State<_Wheel<T>> createState() => _WheelState<T>();
}

class _WheelState<T> extends State<_Wheel<T>> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(initialItem: _indexOf(widget.value));
  late int _index = _indexOf(widget.value);

  int _indexOf(T value) {
    final i = widget.options.indexWhere((o) => o.value == value);
    return i < 0 ? 0 : i;
  }

  int get _count => widget.options.length;

  @override
  void didUpdateWidget(_Wheel<T> old) {
    super.didUpdateWidget(old);
    final want = _indexOf(widget.value);
    if (want != _index % _count) {
      _index = want;
      if (_controller.hasClients) _controller.jumpToItem(want);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _settle(int raw) {
    final i = raw % _count;
    setState(() => _index = i);
    final option = widget.options[i];
    if (option.enabled && option.value != widget.value) {
      widget.onChanged?.call(option.value);
    }
  }

  int? _step(int by) {
    final next = _index + by;
    if (widget.looping) return next % _count;
    if (next < 0 || next >= _count) return null;
    return next;
  }

  void _turn(int by) {
    final next = _step(by);
    if (next == null) return;
    final motion = FrostedMotion.of(context);
    if (motion.moves) {
      _controller.animateToItem(
        _controller.selectedItem + by,
        duration: motion.fast,
        curve: motion.curve,
      );
    } else {
      _controller.jumpToItem(_controller.selectedItem + by);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final live = widget.onChanged != null && _count > 0;
    final up = _step(-1);
    final down = _step(1);
    final style = t.textTheme.bodyLarge.line(_wheelRow / 2);
    Widget row(int i) {
      final option = widget.options[i];
      final chosen = i == _index;
      Widget words = Text(
        option.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.ellipsis,
        style: chosen
            ? style.semibold.c(t.colorScheme.textPrimary)
            : style.c(t.colorScheme.textSecondary),
      );
      words = FrostedDim(off: !option.enabled, child: words);
      return Align(
        alignment: widget.align,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: FrostedSpacing.s12),
          child: words,
        ),
      );
    }

    final wheel = ShaderMask(
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
      // A wheel shows where it stands by its band: no scrollbar, which a
      // desktop's scroll behaviour would raise under a resting pointer.
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListWheelScrollView.useDelegate(
          controller: _controller,
          itemExtent: _wheelRow,
          diameterRatio: 1.6,
          perspective: 0.004,
          squeeze: 1,
          physics: live
              ? const FixedExtentScrollPhysics()
              : const NeverScrollableScrollPhysics(),
          onSelectedItemChanged: (i) => setState(() => _index = i % _count),
          childDelegate: widget.looping
              ? ListWheelChildLoopingListDelegate(
                  children: [for (var i = 0; i < _count; i++) row(i)],
                )
              : ListWheelChildBuilderDelegate(
                  childCount: _count,
                  builder: (context, i) => row(i),
                ),
        ),
      ),
    );

    final settled = NotificationListener<ScrollEndNotification>(
      onNotification: (_) {
        _settle(_controller.selectedItem);
        return false;
      },
      child: wheel,
    );

    final current = _count == 0 ? '' : widget.options[_index].label;
    return Semantics(
      container: true,
      label: widget.label,
      value: current,
      increasedValue: down == null ? null : widget.options[down].label,
      decreasedValue: up == null ? null : widget.options[up].label,
      onIncrease: live && down != null ? () => _turn(1) : null,
      onDecrease: live && up != null ? () => _turn(-1) : null,
      child: ExcludeSemantics(
        child: FrostedKeyFocus(
          enabled: live,
          radius: FrostedCorners.r12,
          keys: {
            if (up != null) LogicalKeyboardKey.arrowUp: () => _turn(-1),
            if (down != null) LogicalKeyboardKey.arrowDown: () => _turn(1),
          },
          child: FrostedDim(off: widget.onChanged == null, child: settled),
        ),
      ),
    );
  }
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

    final hours = h24
        ? [for (var h = 0; h < 24; h++) FrostedSelectOption(h, _two(h))]
        : [for (var h = 1; h <= 12; h++) FrostedSelectOption(h % 12, '$h')];
    final hourWheel = _Wheel<int>(
      label: words.hour,
      looping: true,
      align: AlignmentDirectional.centerEnd.resolve(Directionality.of(context)),
      options: hours,
      value: h24 ? now.hour : now.hour % 12,
      onChanged: change == null
          ? null
          : (h) => set(
              now.copyWith(hour: h24 ? h : h + (now.hour >= 12 ? 12 : 0)),
            ),
    );
    final minuteWheel = _Wheel<int>(
      label: words.minute,
      looping: true,
      align: AlignmentDirectional.centerStart.resolve(
        Directionality.of(context),
      ),
      options: [
        for (var m = 0; m < 60; m += minuteInterval)
          FrostedSelectOption(m, _two(m)),
      ],
      value: minute,
      onChanged: change == null ? null : (m) => set(now.copyWith(minute: m)),
    );
    final halfWheel = _Wheel<bool>(
      label: '${words.am} / ${words.pm}',
      looping: false,
      options: [
        FrostedSelectOption(false, words.am),
        FrostedSelectOption(true, words.pm),
      ],
      value: now.hour >= 12,
      onChanged: change == null
          ? null
          : (pm) => set(now.copyWith(hour: now.hour % 12 + (pm ? 12 : 0))),
    );
    // At most 360 wide, at the start of a wider field: the hour, the minute
    // and the half of the day stay together on one short band.
    final picker = SizedBox(
      height: _wheelRow * _wheelRows,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _WheelBand(t: t),
          Row(
            children: [
              Expanded(child: hourWheel),
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
              Expanded(child: minuteWheel),
              if (!h24) Expanded(child: halfWheel),
            ],
          ),
        ],
      ),
    );
    return picker;
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
/// hairline ring, a day outside [first] to [last] faded and inert. Each day
/// is a button read as its full date; the month's name is announced as it
/// turns. [showFrostedDatePicker] raises it in a card with Cancel and OK.
///
/// ```dart
/// FrostedDatePicker(value: due, first: DateTime(2026), last: DateTime(2027, 12, 31), onChanged: (d) => setState(() => due = d))
/// ```
class FrostedDatePicker extends StatefulWidget {
  /// A month standing on [value] (or today's month).
  const FrostedDatePicker({
    this.value,
    this.onChanged,
    this.first,
    this.last,
    this.currentDate,
    super.key,
  });

  /// The chosen day.
  final DateTime? value;

  /// Hands over the day pressed; null leaves the days inert.
  final ValueChanged<DateTime>? onChanged;

  /// The earliest day that can be chosen; null sets no floor.
  final DateTime? first;

  /// The latest day that can be chosen; null sets no ceiling.
  final DateTime? last;

  /// Today, for its ring; null asks the device's clock.
  final DateTime? currentDate;

  @override
  State<FrostedDatePicker> createState() => _FrostedDatePickerState();
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
    final first = widget.first;
    final last = widget.last;
    if (first != null && day.isBefore(_day(first))) return false;
    if (last != null && day.isAfter(_day(last))) return false;
    return true;
  }

  void _go(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final words = FrostedLocalizations.of(context);
    final today = _day(widget.currentDate ?? DateTime.now());
    final first = widget.first;
    final last = widget.last;
    final canBack = first == null || _month.isAfter(_monthOf(first));
    final canOn = last == null || _month.isBefore(_monthOf(last));
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead =
        (_month.weekday - DesignLocalizations.of(context).firstDayOfWeek) % 7;
    final title = '${words.monthName(_month.month)} ${_month.year}';

    Widget step(IconData glyph, String label, VoidCallback? go) =>
        FrostedHitSlop(
          child: FrostedPressable(
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
          DesignLocalizations.of(context).previousMonthTooltip,
          canBack ? () => _go(-1) : null,
        ),
        step(
          FrostedGlyphs.forward,
          DesignLocalizations.of(context).nextMonthTooltip,
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
                  DesignLocalizations.of(context).formatShortWeekday(
                    (DesignLocalizations.of(context).firstDayOfWeek - 1 + i) %
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
          child: FrostedFace(
            material: FrostedMaterial.paint,
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
                ? s.edge ?? t.colorScheme.borderStrong
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
        label: words.fullDate(day),
        selected: chosen,
        radius: dayCorner,
        shape: dayCut,
        builder: (context, states, _) => draw(states),
      );
    }

    final rows = <Widget>[];
    for (var start = 1 - lead; start <= days; start += 7) {
      rows.add(
        SizedBox(
          height: 44,
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
      rows.add(const SizedBox(height: 44));
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
                ...rows,
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
          first: first,
          last: last,
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
                      DesignLocalizations.of(context).cancelButtonLabel,
                      expand: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Expanded(
                    child: FrostedButton(
                      DesignLocalizations.of(context).okButtonLabel,
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
