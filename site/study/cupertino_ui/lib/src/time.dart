part of '../stint_cupertino.dart';

class _WeekChart extends StatelessWidget {
  const _WeekChart(this.c, this.week);
  final StintController c;
  final DateTime week;
  @override
  Widget build(BuildContext context) {
    final w = c.words, totals = c.dailyMinutes(week);
    final max = totals.fold(1, (a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final (i, total) in totals.indexed)
          Expanded(
            child: Semantics(
              label: w.shortDate(addDays(week, i)),
              value: w.duration(total),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      w.duration(total),
                      textAlign: TextAlign.center,
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle
                          .copyWith(
                            color: CupertinoColors.label.resolveFrom(context),
                          ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      height: 52,
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          height: total == 0 ? 1 : 52 * total / max,
                          width: 16,
                          decoration: BoxDecoration(
                            color: total == 0
                                ? CupertinoColors.systemGrey4.resolveFrom(
                                    context,
                                  )
                                : CupertinoTheme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      w.weekdayShort(addDays(week, i)),
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .tabLabelTextStyle,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

Future<DateTime?> _pick(
  BuildContext context,
  StintWords w,
  DateTime initial, {
  bool time = false,
}) {
  var value = initial;
  Widget picker(BuildContext ctx) => ColoredBox(
    color: CupertinoColors.systemBackground.resolveFrom(ctx),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CupertinoButton(
                child: Text(w.cancel),
                onPressed: () => Navigator.pop(ctx),
              ),
              CupertinoButton(
                child: Text(w.apply),
                onPressed: () => Navigator.pop(ctx, value),
              ),
            ],
          ),
          SizedBox(
            height: 216,
            child: CupertinoDatePicker(
              mode: time
                  ? CupertinoDatePickerMode.time
                  : CupertinoDatePickerMode.date,
              initialDateTime: initial,
              use24hFormat: true,
              onDateTimeChanged: (v) => value = v,
            ),
          ),
        ],
      ),
    ),
  );
  // A phone takes the wheel from the screen's foot; a wide window, as an iPad
  // does, in a form sheet over the app.
  return showCupertinoModalPopup<DateTime>(
    context: context,
    builder: (ctx) => _wide(ctx)
        ? _FormSheet(height: 216 + 48 + 16, child: picker(ctx))
        : picker(ctx),
  );
}

extension _Time on _Desk {
  Widget time() {
    final week = c.week, entries = c.entriesFor(week), rtl = w.arabic;
    return groupedOverview(
      summary: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
          child: Row(
            children: [
              _IconButton(
                w.previousWeek,
                rtl
                    ? CupertinoIcons.chevron_right
                    : CupertinoIcons.chevron_left,
                () => c.shiftWeek(-1),
              ),
              Expanded(
                child: Text(
                  w.weekRange(week, compact: true),
                  textAlign: TextAlign.center,
                ),
              ),
              _IconButton(
                w.nextWeek,
                rtl
                    ? CupertinoIcons.chevron_left
                    : CupertinoIcons.chevron_right,
                () => c.shiftWeek(1),
              ),
            ],
          ),
        ),
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          header: Text(w.weekTotal),
          children: [
            _RowTile(title: Text(w.duration(c.totalMinutes(week)))),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _WeekChart(c, week),
            ),
          ],
        ),
        // On the inset groups' 20 pt margins, so its edges meet theirs.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: CupertinoButton.filled(
            onPressed: addTime,
            child: Text(w.addEntry),
          ),
        ),
      ],
      records: [
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          header: Text(w.entries),
          children: [
            if (entries.isEmpty) _RowTile(title: Text(w.noEntries)),
            // An iOS subtitle row: the work as the title, its hours and
            // project as one secondary line, the duration as the row's value.
            for (final e in entries)
              _RowTile(
                title: Text(w.text(e.note)),
                subtitle: Text(
                  '${w.clock(e.start)} – ${w.clock(e.end)}${w.dot}'
                  '${c.projectName(e.project)}${w.dot}${w.shortDate(e.date)}',
                ),
                additionalInfo: Text(w.duration(e.end - e.start)),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> addTime() async {
    await _present<void>(
      context,
      height: 560,
      (ctx, scroll) => _Entry(this, scroll),
    );
  }
}

class _Entry extends StatefulWidget {
  const _Entry(this.desk, this.scroll);
  final _Desk desk;
  final ScrollController? scroll;
  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  late final d = EntryDraft(
    addDays(widget.desk.c.week, studyToday.weekday - 1),
  );
  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.desk.w,
        c = widget.desk.c,
        errors = d.submitted ? d.errors(w) : const <String, String>{};
    Future<void> chooseTime(bool start) async {
      final minute = start ? d.start : d.end,
          v = await _pick(
            context,
            w,
            DateTime(
              d.date.year,
              d.date.month,
              d.date.day,
              minute ~/ 60,
              minute % 60,
            ),
            time: true,
          );
      if (mounted && v != null) {
        setState(() {
          final m = v.hour * 60 + v.minute;
          if (start) {
            d.start = m;
          } else {
            d.end = m;
          }
        });
      }
    }

    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Text(w.addEntry),
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => Navigator.pop(context),
          child: Text(w.cancel),
        ),
      ),
      child: SafeArea(
        child: ListView(
          controller: widget.scroll,
          children: [
            CupertinoListSection.insetGrouped(
              hasLeading: false,
              children: [
                _SettingRow(w.date, w.shortDate(d.date), () async {
                  final v = await _pick(context, w, d.date);
                  if (mounted && v != null) setState(() => d.date = v);
                }),
                _SettingRow(w.start, w.clock(d.start), () => chooseTime(true)),
                _SettingRow(w.end, w.clock(d.end), () => chooseTime(false)),
                if (errors['end'] case final error?)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      error,
                      style: const TextStyle(color: CupertinoColors.systemRed),
                    ),
                  ),
                _SettingRow(w.project, c.projectName(d.project), () async {
                  final v = await widget.desk.choose(w.project, {
                    for (final p in projects) p.id: w.text(p.name),
                  }, value: d.project);
                  if (mounted && v != null) setState(() => d.project = v);
                }),
                _Input(
                  w.note,
                  '',
                  (v) => setState(() => d.note = v),
                  lines: 2,
                  error: errors['note'],
                ),
              ],
            ),
            // On the inset group's 20 pt margins, as the page's own key.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: CupertinoButton.filled(
                child: Text(w.addEntry),
                onPressed: () {
                  if (c.addEntry(d)) {
                    Navigator.pop(context);
                  } else {
                    setState(() {});
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
