import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/hit_slop.dart';
import '../../theme.dart';
import '../button/button.dart';
import '../icon-button/icon_button.dart';
import '../money/money.dart';
import '../pressable/pressable.dart';
import '../sheet.dart';

/// What a [LedgerDatePicker] sets: the day, the time of day, or both.
enum LedgerDatePickerMode {
  /// The day.
  date,

  /// The time of day.
  time,

  /// The day and the time of day.
  dateAndTime,
}

/// How a [LedgerDatePicker] stands: [compact] a line on the dot leader whose
/// value pills raise the picker in a sheet; [inline] the month's calendar on
/// the page (with the time's wheels under it for a date and a time); [wheel]
/// scrolling columns alone.
enum LedgerDatePickerPresentation {
  /// A line on the dot leader whose value pills raise the picker in a sheet.
  compact,

  /// The month's calendar on the page, the time's wheels under it.
  inline,

  /// Scrolling columns alone.
  wheel,
}

/// A day and a time of day chosen from a calendar or from wheels, in the
/// ledger's hand. [compact] prints the [label] on the dot leader to the value
/// in mono pills (`Nov 4, 2026`, `7:40 PM`), each raising its own picker in a
/// sheet that commits on Done; [inline] is the month itself: its name in the
/// serif with the two ringed arrows, the weekdays in the small capitals, the
/// days in 44 point cells with the chosen one struck on the ink and [today]
/// ringed, closed on the accountant's double rule; [wheel] is the day, or the
/// hour, the minute and AM or PM, as flat columns of figures that settle
/// between two ink rules, as a ledger's column stands (never curved away like
/// a drum). From 600 the month and the wheels stand at most 416 across (their
/// sheet's width), at the start of their slot. A day outside [firstDate] and
/// [lastDate] is faint and takes no press,
/// and every change is kept inside them. Weeks start on Monday. Nothing here
/// reads the clock: pass [today] to have it ringed. A null [onChanged]
/// dims the whole picker and holds it. Each wheel is an adjustable value for
/// a screen reader, and each day a button named by its full date.
///
/// ```dart
/// LedgerDatePicker(label: 'Due', value: due, mode: LedgerDatePickerMode.dateAndTime, onChanged: setDue)
/// ```
class LedgerDatePicker extends StatefulWidget {
  /// A picker named [label] showing [value].
  const LedgerDatePicker({
    required this.value,
    required this.onChanged,
    this.label = 'Date',
    this.mode = LedgerDatePickerMode.date,
    this.presentation = LedgerDatePickerPresentation.compact,
    this.firstDate,
    this.lastDate,
    this.today,
    this.use24hFormat = false,
    super.key,
  });

  /// The day and time chosen.
  final DateTime value;

  /// Told the new value; null holds the picker and dims it.
  final ValueChanged<DateTime>? onChanged;

  /// What the picker is of: the compact line's words and its sheet's title.
  final String label;

  /// Whether it sets the day, the time or both.
  final LedgerDatePickerMode mode;

  /// How it stands.
  final LedgerDatePickerPresentation presentation;

  /// The earliest day that may be chosen.
  final DateTime? firstDate;

  /// The latest day that may be chosen.
  final DateTime? lastDate;

  /// The day the calendar rings; none when null.
  final DateTime? today;

  /// Whether the clock is read on the twenty-four hour face.
  final bool use24hFormat;

  @override
  State<LedgerDatePicker> createState() => _LedgerDatePickerState();
}

class _LedgerDatePickerState extends State<LedgerDatePicker> {
  /// Where an unbounded day wheel is centred: the value it started on, so a
  /// change never moves the window under the finger.
  late final DateTime _anchor = _day(widget.value);

  bool get _hasDate => widget.mode != LedgerDatePickerMode.time;
  bool get _hasTime => widget.mode != LedgerDatePickerMode.date;

  /// [v] moved inside [LedgerDatePicker.firstDate] and
  /// [LedgerDatePicker.lastDate], its time of day kept.
  DateTime _kept(DateTime v) {
    final first = widget.firstDate;
    final last = widget.lastDate;
    var day = _day(v);
    if (first != null && day.isBefore(_day(first))) day = _day(first);
    if (last != null && day.isAfter(_day(last))) day = _day(last);
    return DateTime(day.year, day.month, day.day, v.hour, v.minute);
  }

  void _set(DateTime v) => widget.onChanged?.call(_kept(v));

  Future<void> _raise(LedgerDatePickerMode part) async {
    final draft = ValueNotifier<DateTime>(widget.value);
    final picked = await LedgerSheet.show<DateTime>(
      context,
      title: widget.label,
      builder: (sheetContext) => [
        ValueListenableBuilder<DateTime>(
          valueListenable: draft,
          builder: (context, value, _) => LedgerDatePicker(
            value: value,
            label: widget.label,
            mode: part,
            presentation: part == LedgerDatePickerMode.date
                ? LedgerDatePickerPresentation.inline
                : LedgerDatePickerPresentation.wheel,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            today: widget.today,
            use24hFormat: widget.use24hFormat,
            onChanged: (next) => draft.value = next,
          ),
        ),
      ],
      foot: (sheetContext) => [
        LedgerButton.filled(
          'Done',
          expand: true,
          onPressed: () => Navigator.of(sheetContext).pop(draft.value),
        ),
      ],
    );
    draft.dispose();
    if (picked != null && mounted) _set(picked);
  }

  @override
  Widget build(BuildContext context) {
    final live = widget.onChanged != null;
    final body = switch (widget.presentation) {
      LedgerDatePickerPresentation.compact => _compact(context),
      LedgerDatePickerPresentation.inline => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: _gap,
        children: [
          if (_hasDate)
            _Calendar(
              value: widget.value,
              today: widget.today,
              first: widget.firstDate,
              last: widget.lastDate,
              onPick: (day) => _set(
                DateTime(
                  day.year,
                  day.month,
                  day.day,
                  widget.value.hour,
                  widget.value.minute,
                ),
              ),
            ),
          if (_hasTime)
            _Clock(
              value: widget.value,
              use24h: widget.use24hFormat,
              onChanged: _set,
            ),
        ],
      ),
      LedgerDatePickerPresentation.wheel => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: _gap / 2,
        children: [
          if (_hasDate)
            Expanded(
              child: _DayWheel(
                value: widget.value,
                anchor: _anchor,
                first: widget.firstDate,
                last: widget.lastDate,
                year: !_hasTime,
                onChanged: _set,
              ),
            ),
          if (_hasTime)
            _hasDate
                ? _Clock(
                    value: widget.value,
                    use24h: widget.use24hFormat,
                    onChanged: _set,
                    shrink: true,
                  )
                : Expanded(
                    child: _Clock(
                      value: widget.value,
                      use24h: widget.use24hFormat,
                      onChanged: _set,
                    ),
                  ),
        ],
      ),
    };
    // From 600 the month and the wheels stand at the width their own sheet
    // gives them, at the start of their slot: a calendar across a desktop
    // column spreads its days 150 apart.
    final measured =
        widget.presentation != LedgerDatePickerPresentation.compact &&
        MediaQuery.sizeOf(context).width >= LedgerLayout.measuredFrom;
    return Opacity(
      opacity: live ? 1 : LedgerChromeMetrics.disabledOpacity,
      child: Semantics(
        container: true,
        label: widget.label,
        child: measured
            ? Align(
                alignment: AlignmentDirectional.topStart,
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _measure),
                  child: body,
                ),
              )
            : body,
      ),
    );
  }

  // A sheet's width on the desktop less its paper at each side (480 - 2 x 32).
  static const double _measure =
      LedgerChromeMetrics.dialogWidth - 2 * LedgerChromeMetrics.dialogPad;

  Widget _compact(BuildContext context) {
    final t = context.ledgerTheme;
    final live = widget.onChanged != null;
    final v = widget.value;
    final clock = widget.use24hFormat
        ? '${v.hour.toString().padLeft(2, '0')}:${v.minute.toString().padLeft(2, '0')}'
        : LedgerFormat.time(v);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _lineGap),
      child: LedgerLeaderLine(
        centred: true,
        start: Text(
          widget.label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
          style: t.rowTitle.colored(t.textPrimary),
        ),
        end: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: _gap / 2,
          children: [
            if (_hasDate)
              _Pill(
                LedgerFormat.date(v, showYear: true),
                label: '${widget.label} date',
                onTap: live ? () => _raise(LedgerDatePickerMode.date) : null,
              ),
            if (_hasTime)
              _Pill(
                clock,
                label: '${widget.label} time',
                onTap: live ? () => _raise(LedgerDatePickerMode.time) : null,
              ),
          ],
        ),
      ),
    );
  }

  // DERIVED (the source picks dates on a keypad of chips): the calendar and
  // its time 12 apart, the pills 8 apart, the compact line 6 above and under.
  static const double _gap = 12;
  static const double _lineGap = 6;
}

bool _same(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A value pill of the compact line: the mono words on the raised paper in a
/// ring, 32 tall with the 44 point target round it.
class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.label, required this.onTap});

  final String text;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return LedgerHitSlop(
      child: LedgerPressable(
        onTap: onTap,
        label: label,
        value: text,
        radius: t.controlRadius,
        child: Container(
          height: _height,
          padding: const EdgeInsets.symmetric(horizontal: _pad),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.controlRadius),
            border: Border.all(color: t.border),
          ),
          child: Text(
            text,
            maxLines: 1,
            softWrap: false,
            style: t.pill.sized(_words).colored(t.textPrimary),
          ),
        ),
      ),
    );
  }

  static const double _height = 32;
  static const double _pad = 12;
  static const double _words = 13;
}

/// The month on the page: its name and the ringed arrows, the weekdays, the
/// days in rows of seven, the double rule under them.
class _Calendar extends StatefulWidget {
  const _Calendar({
    required this.value,
    required this.today,
    required this.first,
    required this.last,
    required this.onPick,
  });

  final DateTime value;
  final DateTime? today;
  final DateTime? first;
  final DateTime? last;
  final ValueChanged<DateTime> onPick;

  @override
  State<_Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<_Calendar> {
  late DateTime _month = DateTime(widget.value.year, widget.value.month);

  @override
  void didUpdateWidget(_Calendar old) {
    super.didUpdateWidget(old);
    // A value that moves to another month brings the calendar with it.
    if (old.value.year != widget.value.year ||
        old.value.month != widget.value.month) {
      _month = DateTime(widget.value.year, widget.value.month);
    }
  }

  void _step(int by) =>
      setState(() => _month = DateTime(_month.year, _month.month + by));

  bool _inRange(DateTime d) =>
      (widget.first == null || !d.isBefore(_day(widget.first!))) &&
      (widget.last == null || !d.isAfter(_day(widget.last!)));

  static const List<String> _heads = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final first = widget.first;
    final last = widget.last;
    final canBack =
        first == null ||
        !DateTime(_month.year, _month.month, 0).isBefore(_day(first));
    final canOn =
        last == null ||
        !DateTime(_month.year, _month.month + 1).isAfter(_day(last));
    final lead = _month.weekday - 1;
    final length = DateTime(_month.year, _month.month + 1, 0).day;
    final rows = ((lead + length) / 7).ceil();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          spacing: _arrowGap,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                liveRegion: true,
                child: Text(
                  LedgerFormat.month(_month, showYear: true),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.barTitle.colored(t.textPrimary),
                ),
              ),
            ),
            LedgerIconButton.outlined(
              LucideIcons.chevronLeft,
              semanticLabel: DesignLocalizations.of(context)
                  .previousMonthTooltip,
              size: LedgerIconButtonSize.small,
              onPressed: canBack ? () => _step(-1) : null,
            ),
            LedgerIconButton.outlined(
              LucideIcons.chevronRight,
              semanticLabel: DesignLocalizations.of(context).nextMonthTooltip,
              size: LedgerIconButtonSize.small,
              onPressed: canOn ? () => _step(1) : null,
            ),
          ],
        ),
        const SizedBox(height: _headFoot),
        // The weekdays keep their size with a large text, as the day figures
        // under them do in their marks: a grid of the month, each day spoken
        // whole by its date.
        ExcludeSemantics(
          child: Row(
            children: [
              for (final head in _heads)
                Expanded(
                  child: Center(
                    child: Text(
                      head,
                      textScaler: TextScaler.noScaling,
                      style: t.tag.colored(t.textTertiary),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: _weekFoot),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(child: _cell(t, r * 7 + c - lead + 1, length)),
            ],
          ),
        const SizedBox(height: _ruleTop),
        ExcludeSemantics(
          child: Container(
            height: LedgerChromeMetrics.doubleRule,
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: t.headRule),
                bottom: BorderSide(color: t.headRule),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cell(LedgerThemeData t, int n, int length) {
    if (n < 1 || n > length) return const SizedBox(height: _cell44);
    final d = DateTime(_month.year, _month.month, n);
    final chosen = _same(d, widget.value);
    final ringed = widget.today != null && _same(d, widget.today!);
    final open = _inRange(d);
    return SizedBox(
      height: _cell44,
      child: Center(
        child: LedgerHitSlop(
          child: LedgerPressable(
            onTap: open ? () => widget.onPick(d) : null,
            label: LedgerFormat.longDate(d),
            selected: chosen,
            radius: _mark / 2,
            child: Container(
              width: _mark,
              height: _mark,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: chosen ? t.surfaceInverse : null,
                border: ringed && !chosen
                    ? Border.all(color: t.textPrimary, width: _ring)
                    : null,
              ),
              child: Text(
                '$n',
                textScaler: TextScaler.noScaling,
                style: t.amount.colored(
                  chosen
                      ? t.textInverse
                      : open
                      ? t.textPrimary
                      : t.textFaint,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // DERIVED (the source lists dates, it does not pick them): a day's cell is
  // the 44 point target round a 36 mark, the head 12 over the weekdays.
  static const double _cell44 = LedgerLayout.minHitTarget;
  static const double _mark = 36;
  static const double _ring = 1.25;
  static const double _arrowGap = 8;
  static const double _headFoot = 12;
  static const double _weekFoot = 4;
  static const double _ruleTop = 8;
}

/// The time of day as wheels: the hour, the minute and (on the twelve hour
/// face) AM or PM, the colon between hour and minute.
class _Clock extends StatelessWidget {
  const _Clock({
    required this.value,
    required this.use24h,
    required this.onChanged,
    this.shrink = false,
  });

  final DateTime value;
  final bool use24h;
  final ValueChanged<DateTime> onChanged;

  /// Whether it takes only the room its wheels need (beside a day wheel).
  final bool shrink;

  DateTime _at(int hour, int minute) =>
      DateTime(value.year, value.month, value.day, hour, minute);

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final pm = value.hour >= 12;
    final twelve = value.hour % 12 == 0 ? 12 : value.hour % 12;
    String two(int i) => i.toString().padLeft(2, '0');
    final gap = shrink ? 0.0 : _gap;
    // The hour, the colon and the minute read left to right in either
    // direction ("9 : 30"); AM or PM stands at the reading end.
    final clock = <Widget>[
      _Wheel(
        label: 'Hour',
        count: use24h ? 24 : 12,
        index: use24h ? value.hour : twelve - 1,
        text: (i) => use24h ? two(i) : '${i + 1}',
        width: _digits,
        onIndex: (i) => onChanged(
          use24h
              ? _at(i, value.minute)
              : _at((i + 1) % 12 + (pm ? 12 : 0), value.minute),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        // The wheels' figures keep their size in their rows; so does the
        // colon between them.
        child: Text(
          ':',
          textScaler: TextScaler.noScaling,
          style: t.figureSmall.sized(24).line(24),
        ),
      ),
      _Wheel(
        label: 'Minute',
        count: 60,
        index: value.minute,
        text: two,
        width: _digits,
        onIndex: (i) => onChanged(_at(value.hour, i)),
      ),
    ];
    final wheels = <Widget>[
      Row(
        mainAxisSize: MainAxisSize.min,
        textDirection: TextDirection.ltr,
        spacing: gap,
        children: clock,
      ),
      if (!use24h)
        _Wheel(
          label: 'AM or PM',
          count: 2,
          index: pm ? 1 : 0,
          text: (i) => i == 0 ? 'AM' : 'PM',
          width: _meridiem,
          onIndex: (i) =>
              onChanged(_at(value.hour % 12 + (i == 1 ? 12 : 0), value.minute)),
        ),
    ];
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: gap,
      children: wheels,
    );
  }

  static const double _digits = 56;
  static const double _meridiem = 64;
  static const double _gap = 4;
}

/// The day as a wheel: one item a day from [first] to [last], or a year
/// either side of [anchor] without them.
class _DayWheel extends StatelessWidget {
  const _DayWheel({
    required this.value,
    required this.anchor,
    required this.first,
    required this.last,
    required this.year,
    required this.onChanged,
  });

  final DateTime value;
  final DateTime anchor;
  final DateTime? first;
  final DateTime? last;

  /// Whether each day is named with its year (a wheel with no time beside it).
  final bool year;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final from = first == null
        ? DateTime(anchor.year, anchor.month, anchor.day - _window)
        : _day(first!);
    final to = last == null
        ? DateTime(anchor.year, anchor.month, anchor.day + _window)
        : _day(last!);
    final count = to.difference(from).inDays + 1;
    final at = _day(value).difference(from).inDays.clamp(0, count - 1);
    DateTime dayAt(int i) => DateTime(from.year, from.month, from.day + i);
    return _Wheel(
      label: 'Day',
      count: count,
      index: at,
      text: (i) =>
          LedgerFormat.date(dayAt(i), showWeekday: true, showYear: year),
      onIndex: (i) {
        final d = dayAt(i);
        onChanged(DateTime(d.year, d.month, d.day, value.hour, value.minute));
      },
    );
  }

  static const int _window = 366;
}

/// One scrolling column, flat on the paper: [count] items of [text] settling
/// between two ink rules, the chosen one in the ink and the rest in the faint.
/// It is one adjustable value to a screen reader and answers the arrow keys.
class _Wheel extends StatefulWidget {
  const _Wheel({
    required this.label,
    required this.count,
    required this.index,
    required this.text,
    required this.onIndex,
    this.width,
  });

  final String label;
  final int count;
  final int index;
  final String Function(int index) text;
  final ValueChanged<int> onIndex;

  /// Null takes the room the wheel is given.
  final double? width;

  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> {
  late final FixedExtentScrollController _scroll = FixedExtentScrollController(
    initialItem: widget.index,
  );

  @override
  void didUpdateWidget(_Wheel old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    // Moved from outside (the other wheel clamped it): bring this one along
    // once the frame is built.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          _scroll.hasClients &&
          _scroll.selectedItem != widget.index) {
        _scroll.jumpToItem(widget.index);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _go(int to) {
    final next = to.clamp(0, widget.count - 1);
    if (next == widget.index) return;
    if (!LedgerMotion.isReduced(context) && _scroll.hasClients) {
      _scroll.animateToItem(
        next,
        duration: LedgerMotion.base,
        curve: LedgerMotion.out,
      );
    } else {
      widget.onIndex(next);
    }
  }

  KeyEventResult _key(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final by = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowDown => 1,
      LogicalKeyboardKey.pageUp => -_page,
      LogicalKeyboardKey.pageDown => _page,
      _ => 0,
    };
    if (by == 0) return KeyEventResult.ignored;
    _go(widget.index + by);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final here = widget.index;
    return Semantics(
      container: true,
      label: widget.label,
      value: widget.text(here),
      increasedValue: here + 1 < widget.count ? widget.text(here + 1) : null,
      decreasedValue: here > 0 ? widget.text(here - 1) : null,
      onIncrease: here + 1 < widget.count ? () => _go(here + 1) : null,
      onDecrease: here > 0 ? () => _go(here - 1) : null,
      child: Focus(
        onKeyEvent: _key,
        child: SizedBox(
          width: widget.width,
          height: _item * _shown,
          child: Stack(
            children: [
              ExcludeSemantics(
                child: ListWheelScrollView.useDelegate(
                  controller: _scroll,
                  itemExtent: _item,
                  diameterRatio: _flat,
                  perspective: _perspective,
                  overAndUnderCenterOpacity: _fade,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: widget.onIndex,
                  childDelegate: ListWheelChildBuilderDelegate(
                    childCount: widget.count,
                    builder: (context, i) => Center(
                      child: Text(
                        widget.text(i),
                        maxLines: 1,
                        softWrap: false,
                        textScaler: TextScaler.noScaling,
                        style: t.amount
                            .sized(_words)
                            .colored(
                              i == here ? t.textPrimary : t.textTertiary,
                            ),
                      ),
                    ),
                  ),
                ),
              ),
              Center(
                child: IgnorePointer(
                  child: Container(
                    height: _item,
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: t.headRule),
                        bottom: BorderSide(color: t.headRule),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // DERIVED (the source picks nothing on a wheel): five 40 point rows, the
  // chosen one between two ink rules, the others fading to .45; the column
  // stands flat (a wheel so wide its rows never visibly curve: paper does not
  // bend into a drum).
  static const double _item = 40;
  static const int _shown = 5;
  static const int _page = 5;
  static const double _words = 17;
  static const double _flat = 1000;
  static const double _perspective = .002;
  static const double _fade = .45;
}
