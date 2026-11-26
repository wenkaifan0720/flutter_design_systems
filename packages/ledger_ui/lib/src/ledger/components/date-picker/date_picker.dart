import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:ui_core/ui_core.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../chrome_metrics.dart';
import '../../format.dart';
import '../../internal/state_face.dart';
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
/// ledger's hand. [LedgerDatePickerPresentation.compact] prints the [labelText] on
/// the dot leader to the value in mono pills (`Nov 4, 2026`, `7:40 PM`), each
/// raising its own picker in a sheet that commits on Done;
/// [LedgerDatePickerPresentation.inline] is the month itself: its name in the
/// serif with the two ringed arrows, the weekdays in the small capitals, the
/// days in 44 point cells with the chosen one struck on the ink and [currentDate]
/// ringed, closed on the accountant's double rule;
/// [LedgerDatePickerPresentation.wheel] is the day, or the hour, the minute and
/// AM or PM, as flat columns of figures that settle between two ink rules, as a
/// ledger's column stands (never curved away like a drum). From 600 the month
/// and the wheels stand at most 416 across (a desktop sheet's width), at the
/// start of their slot; on a sheet's card they span the card. A day outside [firstDate] and [lastDate] is faint and takes
/// no press, and every change is kept inside them. Weeks start on Monday.
/// In English it writes as above; in another language, the days, months,
/// clock and figures are that language's, in its order and its digits, from
/// ui_core's [RawWidgetsLocalizations] (`٢٠ نوفمبر ٢٠٢٦`, `٠٩:٣٠`, `20. Nov. 2026`).
/// Nothing here reads the clock: pass [currentDate] to have it ringed. A null
/// [onChanged] dims the whole picker and holds it. Each wheel is an adjustable
/// value for a screen reader, and each day a button named by its full date.
///
/// ```dart
/// LedgerDatePicker(labelText: 'Due', value: due, mode: LedgerDatePickerMode.dateAndTime, onChanged: setDue)
/// ```
class LedgerDatePicker extends StatefulWidget {
  /// A picker named [labelText] showing [value].
  const LedgerDatePicker({
    required this.value,
    required this.onChanged,
    this.labelText = 'Date',
    this.mode = LedgerDatePickerMode.date,
    this.presentation = LedgerDatePickerPresentation.compact,
    this.firstDate,
    this.lastDate,
    this.currentDate,
    this.use24hFormat = false,
    super.key,
  });

  /// The day and time chosen.
  final DateTime value;

  /// Told the new value; null holds the picker and dims it.
  final ValueChanged<DateTime>? onChanged;

  /// What the picker is of: the compact line's words, its pills' and its
  /// wheels' spoken names and its sheet's title.
  final String labelText;

  /// Whether it sets the day, the time or both.
  final LedgerDatePickerMode mode;

  /// How it stands.
  final LedgerDatePickerPresentation presentation;

  /// The earliest day that may be chosen.
  final DateTime? firstDate;

  /// The latest day that may be chosen.
  final DateTime? lastDate;

  /// The day the calendar rings; none when null.
  final DateTime? currentDate;

  /// Whether the clock is read on the twenty-four hour face, as it is anyway
  /// where the reader's language reads one (German's 21:05).
  final bool use24hFormat;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<DateTime>('value', value))
      ..add(
        ObjectFlagProperty<ValueChanged<DateTime>>.has('onChanged', onChanged),
      )
      ..add(StringProperty('labelText', labelText))
      ..add(EnumProperty<LedgerDatePickerMode>('mode', mode))
      ..add(
        EnumProperty<LedgerDatePickerPresentation>(
          'presentation',
          presentation,
        ),
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
      )
      ..add(
        FlagProperty(
          'use24hFormat',
          value: use24hFormat,
          ifTrue: 'use24hFormat',
        ),
      );
  }

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
      title: widget.labelText,
      builder: (sheetContext) => [
        ValueListenableBuilder<DateTime>(
          valueListenable: draft,
          builder: (context, value, _) => LedgerDatePicker(
            value: value,
            labelText: widget.labelText,
            mode: part,
            presentation: part == LedgerDatePickerMode.date
                ? LedgerDatePickerPresentation.inline
                : LedgerDatePickerPresentation.wheel,
            firstDate: widget.firstDate,
            lastDate: widget.lastDate,
            currentDate: widget.currentDate,
            use24hFormat: widget.use24hFormat,
            onChanged: (next) => draft.value = next,
          ),
        ),
      ],
      foot: (sheetContext) => [
        LedgerButton.filled(
          RawWidgetsLocalizations.of(sheetContext).doneButtonLabel,
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
              today: widget.currentDate,
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
    // column spreads its days 150 apart. On a sheet's card the card is their
    // measure, as it is its acts': the month, its arrows and its rule span
    // the card under the title's rule (a tablet's 640 sheet, not 416 of it).
    final measured =
        widget.presentation != LedgerDatePickerPresentation.compact &&
        MediaQuery.sizeOf(context).width >= LedgerLayout.measuredFrom &&
        !LedgerSheetShell.around(context);
    return Opacity(
      opacity: live ? 1 : LedgerChromeMetrics.disabledOpacity,
      child: Semantics(
        container: true,
        label: widget.labelText,
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
    final dates = _Dates.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _lineGap),
      child: LedgerLeaderLine(
        centred: true,
        start: Text(widget.labelText, style: t.rowTitle.colored(t.textPrimary)),
        end: Wrap(
          alignment: WrapAlignment.end,
          spacing: _gap / 2,
          children: [
            // Each pill is named by the picker's label and read as its value:
            // the day or the clock in the reader's words.
            if (_hasDate)
              _Pill(
                dates.day(v),
                label: widget.labelText,
                onTap: live ? () => _raise(LedgerDatePickerMode.date) : null,
              ),
            if (_hasTime)
              _Pill(
                dates.clock(v, use24h: widget.use24hFormat),
                label: widget.labelText,
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

/// The picker's days, months, clock and figures in the reader's language. In
/// English, as Ledger writes them ([LedgerFormat]: "Nov 20, 2026", "Friday,
/// November 20, 2026", "MO", "9:05 PM"); in another, from ui_core's
/// [RawWidgetsLocalizations]: its month and day with its year (the year first
/// where the language marks it, "2026年11月20日"), its full date, its weekday
/// letters, its clock and its digits.
class _Dates {
  _Dates.of(BuildContext context)
    : _words = RawWidgetsLocalizations.of(context),
      _english =
          (Localizations.maybeLocaleOf(context)?.languageCode ?? 'en') == 'en';

  final RawWidgetsLocalizations _words;
  final bool _english;

  /// A day with its year, as a pill prints it: "Nov 20, 2026",
  /// "٢٠ نوفمبر ٢٠٢٦", "20. Nov. 2026", "2026年11月20日".
  String day(DateTime d) {
    if (_english) return LedgerFormat.date(d, showYear: true);
    final monthDay = _words.formatShortMonthDay(d);
    final year = _words.formatYear(d);
    // A year with its mark leads (Japanese's and Chinese's U+5E74 joined,
    // Korean's spaced); a month that leads takes a comma before the year.
    if (!_figures.hasMatch(year)) {
      return year.endsWith('\u5E74') ? '$year$monthDay' : '$year $monthDay';
    }
    return _leadingFigure.hasMatch(monthDay)
        ? '$monthDay $year'
        : '$monthDay, $year';
  }

  /// A day in full, as a calendar's day is read: "Friday, November 20, 2026".
  String longDay(DateTime d) =>
      _english ? LedgerFormat.longDate(d) : _words.formatFullDate(d);

  /// A month and its year, a calendar's title: "November 2026".
  String month(DateTime d) => _english
      ? LedgerFormat.month(d, showYear: true)
      : _words.formatMonthYear(d);

  /// A weekday's head over a calendar's column, in capitals: "MO".
  String weekdayHead(int weekday) => _english
      ? _englishHeads[weekday - 1]
      : _words.formatShortWeekday(weekday).toUpperCase();

  /// A day on a wheel: "Fri, Nov 20", with its year "Fri, Nov 20, 2026".
  String wheelDay(DateTime d, {required bool year}) {
    if (_english) {
      return LedgerFormat.date(d, showWeekday: true, showYear: year);
    }
    final weekday = _words.formatShortWeekday(d.weekday);
    final date = year ? day(d) : _words.formatShortMonthDay(d);
    return '$weekday${_words.listSeparator}$date';
  }

  /// The clock on its twelve-hour face, or on twenty-four with [use24h]:
  /// "9:05 PM", "09:30", "٠٩:٣٠".
  String clock(DateTime d, {required bool use24h}) {
    if (_english && !use24h) return LedgerFormat.time(d);
    return _words.formatTimeOfDay(
      RawTimeOfDay.fromDateTime(d),
      alwaysUse24HourFormat: use24h,
    );
  }

  /// Whether the clock stands on its twenty-four-hour face: when [use24h]
  /// asks, or where the language's own clock is one.
  bool twentyFour({required bool use24h}) =>
      use24h || (!_english && _words.timeFieldPattern().contains('H'));

  /// A whole number in the language's digits: "20", "٢٠".
  String figure(int n) => _english ? '$n' : _words.formatDecimal(n);

  /// A number of two digits, a clock's minute: "05", "٠٥".
  String twoFigures(int n) => n < 10 ? figure(0) + figure(n) : figure(n);

  /// Morning's or afternoon's mark: "AM", "PM".
  String period({required bool pm}) => _english
      ? (pm ? 'PM' : 'AM')
      : (pm
            ? _words.postMeridiemAbbreviation
            : _words.anteMeridiemAbbreviation);

  /// The day wheel's spoken name.
  String get dayLabel => _english ? 'Day' : _words.dateFieldDayLabel;

  /// The hour wheel's spoken name.
  String get hourLabel => _english ? 'Hour' : _words.timePickerHourLabel;

  /// The minute wheel's spoken name.
  String get minuteLabel => _english ? 'Minute' : _words.timePickerMinuteLabel;

  /// The AM or PM wheel's spoken name.
  String get periodLabel =>
      _english ? 'AM or PM' : _words.timeFieldDayPeriodLabel;

  static const List<String> _englishHeads = [
    'MO',
    'TU',
    'WE',
    'TH',
    'FR',
    'SA',
    'SU',
  ];

  static final RegExp _figures = RegExp(r'^\p{Nd}+$', unicode: true);
  static final RegExp _leadingFigure = RegExp(r'^\p{Nd}', unicode: true);
}

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// A value pill of the compact line: the mono words on the raised paper in a
/// ring, 32 tall, laid out at the tap floor round it.
class _Pill extends StatelessWidget {
  const _Pill(this.text, {required this.label, required this.onTap});

  final String text;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return TapTargetPadding(
      child: LedgerPressable(
        onTap: onTap,
        label: label,
        value: text,
        radius: t.controlRadius,
        child: Container(
          constraints: const BoxConstraints(minHeight: _height),
          padding: const EdgeInsets.symmetric(horizontal: _pad),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(t.controlRadius),
            border: Border.all(color: t.border),
          ),
          child: Center(
            widthFactor: 1,
            heightFactor: 1,
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: t.pill.sized(_words).colored(t.textPrimary),
            ),
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

  @override
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    final dates = _Dates.of(context);
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
                // The month's name wraps at the reader's larger text, never
                // cut short.
                child: Text(
                  dates.month(_month),
                  style: t.barTitle.colored(t.textPrimary),
                ),
              ),
            ),
            LedgerIconButton.outlined(
              LucideIcons.chevronLeft,
              semanticLabel: RawWidgetsLocalizations.of(context)
                  .previousMonthTooltip,
              size: LedgerIconButtonSize.small,
              // Both on the reading end, so the last stands on the keyline.
              tapAlignment: AlignmentDirectional.centerEnd,
              onPressed: canBack ? () => _step(-1) : null,
            ),
            LedgerIconButton.outlined(
              LucideIcons.chevronRight,
              semanticLabel: RawWidgetsLocalizations.of(context)
                  .nextMonthTooltip,
              size: LedgerIconButtonSize.small,
              tapAlignment: AlignmentDirectional.centerEnd,
              onPressed: canOn ? () => _step(1) : null,
            ),
          ],
        ),
        const SizedBox(height: _headFoot),
        ExcludeSemantics(
          child: Row(
            children: [
              for (
                var weekday = DateTime.monday;
                weekday <= DateTime.sunday;
                weekday++
              )
                Expanded(
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        dates.weekdayHead(weekday),
                        maxLines: 1,
                        style: t.tag.colored(t.textTertiary),
                      ),
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
                Expanded(child: _cell(t, dates, r * 7 + c - lead + 1, length)),
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

  Widget _cell(LedgerThemeData t, _Dates dates, int n, int length) {
    final floor = RawTapTargets.of(context).floorOn().height;
    if (n < 1 || n > length) return SizedBox(height: floor);
    final d = DateTime(_month.year, _month.month, n);
    final chosen = _same(d, widget.value);
    final ringed = widget.today != null && _same(d, widget.today!);
    final open = _inRange(d);
    return LayoutBuilder(
      builder: (context, box) {
        final mark = LedgerChromeMetrics.calendarDayDiameter(
          box.maxWidth,
          MediaQuery.textScalerOf(context).scale(t.amount.fontSize!),
        );
        return SizedBox(
          height: math.max(floor, mark + 4),
          child: Center(
            child: TapTargetPadding(
              child: LedgerPressable(
                onTap: open ? () => widget.onPick(d) : null,
                label: dates.longDay(d),
                selected: chosen,
                radius: mark / 2,
                child: Container(
                  width: mark,
                  height: mark,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: chosen ? t.surfaceInverse : null,
                    border: ringed && !chosen
                        ? Border.all(color: t.textPrimary, width: _ring)
                        : null,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      dates.figure(n),
                      maxLines: 1,
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
          ),
        );
      },
    );
  }

  // DERIVED (the source lists dates, it does not pick them): a day's cell is
  // the tap floor's target round a 36 mark, the head 12 over the weekdays.
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
    final dates = _Dates.of(context);
    // On the twenty-four-hour face when asked, or where the reader's clock
    // is one (German's 21:05), as the pill prints it.
    final h24 = dates.twentyFour(use24h: use24h);
    final pm = value.hour >= 12;
    final twelve = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final gap = shrink ? 0.0 : _gap;
    // The hour, the colon and the minute read left to right in either
    // direction ("9 : 30"); AM or PM stands at the reading end.
    final clock = <Widget>[
      _Wheel(
        label: dates.hourLabel,
        count: h24 ? 24 : 12,
        index: h24 ? value.hour : twelve - 1,
        text: (i) => h24 ? dates.twoFigures(i) : dates.figure(i + 1),
        width: _digits,
        onIndex: (i) => onChanged(
          h24
              ? _at(i, value.minute)
              : _at((i + 1) % 12 + (pm ? 12 : 0), value.minute),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: LedgerSpacing.s2),
        // The wheels' figures keep their size in their rows; so does the
        // colon between them.
        child: Text(
          ':',
          textScaler: TextScaler.noScaling,
          style: t.figureSmall.sized(24).line(24),
        ),
      ),
      _Wheel(
        label: dates.minuteLabel,
        count: 60,
        index: value.minute,
        text: dates.twoFigures,
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
      if (!h24)
        _Wheel(
          label: dates.periodLabel,
          count: 2,
          index: pm ? 1 : 0,
          text: (i) => dates.period(pm: i == 1),
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
    final dates = _Dates.of(context);
    return _Wheel(
      label: dates.dayLabel,
      count: count,
      index: at,
      text: (i) => dates.wheelDay(dayAt(i), year: year),
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
/// The column is ui_core's [RawPicker]: a tab stop and one adjustable
/// value to a screen reader, the arrows, Page Up and Down, Home and End and
/// typing turning it on ui_core's spring, a fling settling on a row; the
/// keyboard's focus draws Ledger's double rule under it.
class _Wheel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final t = context.ledgerTheme;
    return SizedBox(
      width: width,
      child: RawPicker(
        columns: (_) => [
          RawPickerColumn(
            itemCount: count,
            itemLabel: text,
            semanticLabel: label,
          ),
        ],
        selection: [index.clamp(0, count - 1)],
        onChanged: (selection) => onIndex(selection.first),
        itemExtent: _item,
        visibleItemCount: _shown,
        diameterRatio: _flat,
        perspective: _perspective,
        squeeze: 1,
        overAndUnderCenterOpacity: _fade,
        itemBuilder: (context, row) => Center(
          child: Text(
            row.label,
            maxLines: 1,
            softWrap: false,
            textScaler: TextScaler.noScaling,
            style: t.amount
                .sized(_words)
                .colored(row.selected ? t.textPrimary : t.textTertiary),
          ),
        ),
        columnBuilder: (context, column, wheel) => LedgerStateFace(
          states: column.states,
          radius: t.smallRadius,
          sinks: false,
          child: Stack(
            children: [
              wheel,
              // The rules at the wheel's middle: the column is as tall as
              // the wheel, but ui_core lays it out unbounded.
              Positioned.fill(
                child: Center(
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
  static const double _words = 17;
  static const double _flat = 1000;
  static const double _perspective = .002;
  static const double _fade = .45;
}
