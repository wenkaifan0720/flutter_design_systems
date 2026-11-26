part of '../stint_civic.dart';

String _problem(StintWords w) => w.thereIsAProblem;

// Civic's typed day, month and year boxes, and its calendar a press away.
// (CivicDatePicker's date segments still take Control-S and Command-K as
// typing, so a draft could not be saved from its well.)
class _DateAnswer extends StatefulWidget {
  const _DateAnswer({
    super.key,
    required this.label,
    required this.words,
    required this.date,
    required this.change,
    this.incomplete = false,
    this.error,
  });
  final StintWords words;
  final String label;
  final DateTime date;
  final bool incomplete;
  final String? error;
  final ValueChanged<DateTime?> change;
  @override
  State<_DateAnswer> createState() => _DateAnswerState();
}

class _DateAnswerState extends State<_DateAnswer> {
  final day = TextEditingController(),
      month = TextEditingController(),
      year = TextEditingController();

  @override
  void initState() {
    super.initState();
    show(widget.date);
  }

  @override
  void didUpdateWidget(_DateAnswer old) {
    super.didUpdateWidget(old);
    // A day taken from the calendar, or a discarded edit, shows in the boxes.
    if (!widget.incomplete && widget.date != read()) show(widget.date);
  }

  @override
  void dispose() {
    day.dispose();
    month.dispose();
    year.dispose();
    super.dispose();
  }

  void show(DateTime date) {
    final w = widget.words;
    day.text = w.number(date.day);
    month.text = w.number(date.month);
    year.text = w.number(date.year);
  }

  DateTime? read() {
    final l = RawWidgetsLocalizations.of(context);
    final d = l.parseDecimal(day.text)?.toInt(),
        m = l.parseDecimal(month.text)?.toInt(),
        y = l.parseDecimal(year.text)?.toInt();
    if (d == null || m == null || y == null || y < 2020 || y > 2040) {
      return null;
    }
    final date = DateTime(y, m, d);
    return date.day == d && date.month == m ? date : null;
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.words;
    // The calendar stands at the end of the day, month and year boxes.
    return Row(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // The fieldset is as wide as its boxes, so the calendar stands
        // beside the year, not at the far end of the column.
        Flexible(
          child: IntrinsicWidth(
            // The boxes stand in a Wrap, whose widest width leaves out the
            // two gaps between them: counted here, the year keeps its line.
            child: _WrapGaps(
              gaps: 2 * CivicSpacing.s16,
              child: CivicDateInput(
                labelText: widget.label,
                errorText: widget.error,
                dayLabel: w.dayPart,
                monthLabel: w.monthPart,
                yearLabel: w.yearPart,
                dayController: day,
                monthController: month,
                yearController: year,
                onChanged: (_, _) => widget.change(read()),
              ),
            ),
          ),
        ),
        CivicTooltip(
          message: w.calendar,
          excludeFromSemantics: true,
          child: CivicIconButton(
            icon: LucideIcons.calendarDays,
            semanticLabel: w.calendar,
            onPressed: () async {
              final value = await showCivicDialog<DateTime>(
                context: context,
                builder: (ctx) => CivicDialog(
                  title: widget.label,
                  content: _ServiceCalendar(widget.date),
                  // A way out besides a day: the dialog's own Cancel, as
                  // Filters has.
                  actions: [
                    CivicButton.secondary(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(w.cancel),
                    ),
                  ],
                ),
              );
              if (context.mounted && value != null) widget.change(value);
            },
          ),
        ),
      ],
    );
  }
}

class _ServiceCalendar extends StatefulWidget {
  const _ServiceCalendar(this.date);
  final DateTime date;
  @override
  State<_ServiceCalendar> createState() => _ServiceCalendarState();
}

class _ServiceCalendarState extends State<_ServiceCalendar> {
  late final month = RawCalendarController(
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    currentDate: studyToday,
    selectedDate: widget.date,
  );
  @override
  void dispose() {
    month.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CivicCalendar(
    controller: month,
    autofocus: true,
    onChanged: (date) => Navigator.pop(context, date),
  );
}

/// A time of day, in minutes after midnight, typed in its parts.
class _TimeAnswer extends StatelessWidget {
  const _TimeAnswer({
    super.key,
    required this.label,
    required this.minute,
    required this.change,
    this.error,
  });
  final String label;
  final int minute;
  final ValueChanged<int> change;
  final String? error;
  @override
  Widget build(BuildContext context) => CivicTimeInput(
    labelText: label,
    errorText: error,
    alwaysUse24HourFormat: true,
    value: RawTimeOfDay(hour: minute ~/ 60, minute: minute % 60),
    onChanged: (v) {
      if (v != null) change(v.hour * 60 + v.minute);
    },
  );
}

class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.label,
    required this.values,
    required this.selected,
    required this.name,
    required this.changed,
    this.many = false,
  });
  final String label;
  final List<T> values;
  final Set<T> selected;
  final String Function(T) name;
  final ValueChanged<Set<T>> changed;
  final bool many;
  @override
  Widget build(BuildContext context) => many
      ? CivicFieldset(
          labelText: label,
          children: [
            for (final v in values)
              CivicCheckbox(
                labelText: name(v),
                value: selected.contains(v),
                onChanged: (on) => changed(
                  on ?? false ? {...selected, v} : ({...selected}..remove(v)),
                ),
              ),
          ],
        )
      : CivicRadioGroup<T>(
          labelText: label,
          groupValue: selected.firstOrNull,
          onChanged: (v) {
            if (v != null) changed({v});
          },
          children: [
            for (final v in values) CivicRadio<T>(value: v, labelText: name(v)),
          ],
        );
}

/// Adds [gaps] to its child's widest intrinsic width: a Wrap reports the sum
/// of its children's widths without the spacing it sets between them.
class _WrapGaps extends SingleChildRenderObjectWidget {
  const _WrapGaps({required this.gaps, super.child});
  final double gaps;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderWrapGaps(gaps);
  @override
  void updateRenderObject(BuildContext context, _RenderWrapGaps renderObject) =>
      renderObject.gaps = gaps;
}

class _RenderWrapGaps extends RenderProxyBox {
  _RenderWrapGaps(this._gaps);
  double _gaps;
  set gaps(double value) {
    if (value == _gaps) return;
    _gaps = value;
    markNeedsLayout();
  }

  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMaxIntrinsicWidth(height) + _gaps;
}
