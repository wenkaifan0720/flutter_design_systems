part of '../stint_material.dart';

class _WeekTotals extends StatelessWidget {
  const _WeekTotals(this.c, this.week);
  final StintController c;
  final DateTime week;
  // The figures' column is measured: a face that arrives after the first
  // frame (the web's Arabic fallback, fetched on first use) widens them, so
  // it is measured again then; measured once, Arabic hours wrapped in two.
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: PaintingBinding.instance.systemFonts,
    builder: (context, _) => _totals(context),
  );

  Widget _totals(BuildContext context) {
    final totals = c.dailyMinutes(week), w = c.words;
    final peak = totals.fold(1, (a, b) => a > b ? a : b);
    final durationWidth = totals
        .map(
          (n) => TextPainter.computeWidth(
            text: TextSpan(
              text: w.duration(n),
              style: DefaultTextStyle.of(context).style,
            ),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        )
        .reduce((a, b) => a > b ? a : b)
        .ceilToDouble();
    return Column(
      children: [
        for (final (i, total) in totals.indexed)
          Semantics(
            label: w.shortDate(addDays(week, i)),
            value: w.duration(total),
            excludeSemantics: true,
            child: Row(
              children: [
                SizedBox(
                  width: MediaQuery.textScalerOf(context).scale(32),
                  child: Text(w.weekdayShort(addDays(week, i))),
                ),
                Expanded(child: LinearProgressIndicator(value: total / peak)),
                const SizedBox(width: 8),
                SizedBox(
                  width: durationWidth,
                  child: Text(w.duration(total), textAlign: TextAlign.end),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

extension _Timesheet on _Desk {
  Widget time() {
    final entries = c.entriesFor(c.week);
    return overview(
      summary: [
        Row(
          children: [
            IconButton(
              tooltip: w.previousWeek,
              onPressed: () => c.shiftWeek(-1),
              icon: const BackButtonIcon(),
            ),
            Expanded(
              // The full range where it fits ("Nov 16 – Nov 22", as the
              // other pages date things); the short one where it doesn't.
              child: LayoutBuilder(
                builder: (ctx, box) {
                  final style = Theme.of(ctx).textTheme.titleLarge;
                  final full = w.weekRange(c.week);
                  final fits =
                      TextPainter.computeWidth(
                        text: TextSpan(text: full, style: style),
                        textDirection: Directionality.of(ctx),
                        textScaler: MediaQuery.textScalerOf(ctx),
                      ) <=
                      box.maxWidth;
                  return Text(
                    fits ? full : w.weekRange(c.week, compact: true),
                    textAlign: TextAlign.center,
                    style: style,
                  );
                },
              ),
            ),
            IconButton(
              tooltip: w.nextWeek,
              onPressed: () => c.shiftWeek(1),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
        Card.filled(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 10,
              children: [
                Text(w.weekTotal),
                heading(w.duration(c.totalMinutes(c.week))),
                _WeekTotals(c, c.week),
                FilledButton.icon(
                  onPressed: addTime,
                  icon: const Icon(Icons.add),
                  label: Text(w.addEntry),
                ),
              ],
            ),
          ),
        ),
      ],
      records: [
        // On the line the rows' words start on (ListTile's 16 inset), as a
        // list's subheader stands.
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16),
          child: heading(w.entries),
        ),
        if (entries.isEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 16),
            child: Text(w.noEntries),
          ),
        for (final e in entries)
          ListTile(
            title: Text(w.text(e.note)),
            subtitle: Text(
              '${w.shortDate(e.date)}${w.dot}${c.projectName(e.project)}\n${w.clock(e.start)} – ${w.clock(e.end)}',
            ),
            // The entry's hours in the label style a figure takes (M3's
            // trailing text is the row's smallest; the hours are its key).
            trailing: Text(
              w.duration(e.end - e.start),
              style: Theme.of(context).textTheme.labelLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurface),
            ),
          ),
      ],
    );
  }

  Future<void> addTime() async {
    final draft = EntryDraft(addDays(c.week, studyToday.weekday - 1));
    try {
      final saved = await _raise<bool>(
        context,
        (ctx) => _EntryForm(this, draft),
      );
      if (mounted && saved == true) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(w.entrySaved)));
      }
    } finally {
      draft.dispose();
    }
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm(this.desk, this.draft);
  final _Desk desk;
  final EntryDraft draft;
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  @override
  Widget build(BuildContext context) {
    final c = widget.desk.c,
        w = c.words,
        d = widget.draft,
        errors = d.submitted ? d.errors(w) : const <String, String>{};
    Future<void> pickTime(bool start) async {
      final previous = start ? d.start : d.end;
      final clock = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: previous ~/ 60, minute: previous % 60),
      );
      if (mounted && clock != null) {
        setState(() {
          final minute = clock.hour * 60 + clock.minute;
          if (start) {
            d.start = minute;
          } else {
            d.end = minute;
          }
        });
      }
    }

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        4,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(w.addEntry, style: Theme.of(context).textTheme.headlineSmall),
          ListTile(
            title: Text(w.date),
            subtitle: Text(w.shortDate(d.date)),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
                initialDate: d.date,
                currentDate: studyToday,
              );
              if (mounted && date != null) setState(() => d.date = date);
            },
          ),
          ListTile(
            title: Text(w.start),
            subtitle: Text(w.clock(d.start)),
            onTap: () => pickTime(true),
          ),
          ListTile(
            title: Text(w.end),
            subtitle: Text(w.clock(d.end)),
            onTap: () => pickTime(false),
          ),
          if (errors['end'] case final error?)
            Text(
              error,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          _Option(w.project, d.project, {
            for (final p in projects) p.id: w.text(p.name),
          }, (v) => setState(() => d.project = v)),
          TextField(
            minLines: 2,
            maxLines: 6,
            decoration: InputDecoration(
              labelText: w.note,
              hintText: w.noteHint,
              errorText: errors['note'],
              border: const OutlineInputBorder(),
            ),
            onChanged: (v) => setState(() => d.note = v),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(w.cancel),
              ),
              FilledButton(
                onPressed: () {
                  if (c.addEntry(d)) {
                    Navigator.pop(context, true);
                  } else {
                    setState(() {});
                  }
                },
                child: Text(w.addEntry),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
