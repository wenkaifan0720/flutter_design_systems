part of '../stint_ledger.dart';

extension _TimesAndPreferences on _BookState {
  Widget timesheet() {
    final week = c.week;
    final entries = c.entriesFor(week);
    return LedgerScreen(
      topBar: bar(w.time),
      body: load(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 24,
          children: [
            Row(
              children: [
                action(
                  LucideIcons.chevronLeft,
                  w.previousWeek,
                  () => c.shiftWeek(-1),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: LayoutBuilder(
                      builder: (ctx, box) {
                        final range = w.weekRange(
                          week,
                          compact: box.maxWidth < 320,
                        );
                        return Text(
                          range
                              .split(' – ')
                              .map((date) => date.replaceAll(' ', '\u00a0'))
                              .join(' – '),
                          semanticsLabel: w.weekRange(week),
                          textAlign: TextAlign.center,
                          style: ink.barTitle,
                        );
                      },
                    ),
                  ),
                ),
                action(
                  LucideIcons.chevronRight,
                  w.nextWeek,
                  () => c.shiftWeek(1),
                ),
              ],
            ),
            _Spread(
              main: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  LedgerHead(w.weekTotal),
                  Text(
                    w.duration(c.totalMinutes(week)),
                    style: ink.figureMedium,
                  ),
                  chart(week),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: LedgerButton.filled(
                      w.addEntry,
                      icon: LucideIcons.plus,
                      onPressed: addEntry,
                    ),
                  ),
                ],
              ),
              side: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  LedgerHead(w.entries),
                  // The empty card keeps the 14 the week total's figure
                  // stands below its head: flush, it sat on the head's words.
                  if (entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: LedgerEmptyState(title: w.noEntries),
                    ),
                  for (var i = 0; i < entries.length; i++) ...[
                    if (i == 0 || entries[i - 1].date != entries[i].date)
                      Padding(
                        padding: const EdgeInsets.only(top: 18),
                        child: Text(
                          '${w.weekday(entries[i].date)}${w.dot}${w.shortDate(entries[i].date)}'
                              .toUpperCase(),
                          style: ink.meta,
                        ),
                      ),
                    LedgerRow(
                      title: w.text(entries[i].note),
                      subtitle: c.projectName(entries[i].project),
                      trailingSubtitle:
                          '${w.clock(entries[i].start)}–${w.clock(entries[i].end)}',
                      value: Text(
                        w.duration(entries[i].end - entries[i].start),
                        style: ink.amount,
                      ),
                    ),
                    const LedgerDivider(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addEntry() async {
    final yes = await LedgerSheet.show<bool>(
      context,
      title: w.addEntry,
      builder: (sheet) => [_EntryForm(c)],
    );
    if (yes == true && mounted) LedgerToast.show(context, w.entrySaved);
  }

  Widget preferences() {
    final p = c.settings;
    return LedgerScreen(
      topBar: bar(w.settings),
      body: _Spread(
        main: _FormColumn(
          children: [
            LedgerHead(w.preferences),
            LedgerField(
              labelText: w.appearance,
              child: LedgerSegmentedControl<Appearance>(
                options: Appearance.values,
                value: p.appearance,
                labelOf: w.appearanceName,
                onChanged: (v) => p.update(() => p.appearance = v),
              ),
            ),
            LedgerSelect(
              labelText: w.textSize,
              items: [
                LedgerSelectItem(value: 0.0, label: w.system),
                for (final v in {1.0, 1.5, 2.0, ?p.scale}.toList()..sort())
                  LedgerSelectItem(value: v, label: w.percent(v)),
              ],
              value: p.scale ?? 0,
              onChanged: (v) => p.update(() => p.scale = v == 0 ? null : v),
            ),
            // A select: four languages' names overflow a segmented row on a phone.
            LedgerSelect(
              labelText: w.languageLabel,
              items: [
                for (final l in StintLanguage.values)
                  LedgerSelectItem(value: l, label: l.nativeName),
              ],
              value: p.language,
              onChanged: (v) => p.update(() => p.language = v),
            ),
            LedgerSelect(
              labelText: w.density,
              value: widget.density,
              onChanged: widget.onDensity,
              items: [
                LedgerSelectItem(
                  value: LedgerDensity.standard,
                  label: w.standard,
                ),
                LedgerSelectItem(
                  value: LedgerDensity.comfortable,
                  label: w.comfortable,
                ),
                LedgerSelectItem(
                  value: LedgerDensity.compact,
                  label: w.compact,
                ),
              ],
            ),
          ],
        ),
        side: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 22,
          children: [
            LedgerSlip(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  LedgerHead(w.account),
                  Text(w.text(team.first.name), style: ink.sheetTitle),
                  Text(w.teamName, style: ink.meta),
                ],
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: LedgerButton(
                w.signOut,
                isDestructiveAction: true,
                icon: LucideIcons.logOutDir,
                onPressed: () async {
                  final yes = await LedgerDialog.show(
                    context,
                    title: w.signOutMessage,
                    type: LedgerDialogType.destructive,
                    confirmLabel: w.signOut,
                    cancelLabel: w.cancel,
                  );
                  if (mounted && yes == true) c.signIn(false);
                },
              ),
            ),
            LedgerSlip(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  LedgerHead(w.about),
                  Text(w.aboutDetail, style: ink.body),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryForm extends StatefulWidget {
  const _EntryForm(this.c);
  final StintController c;
  @override
  State<_EntryForm> createState() => _EntryFormState();
}

class _EntryFormState extends State<_EntryForm> {
  late final d = EntryDraft(
    widget.c.week == mondayOf(studyToday) ? studyToday : widget.c.week,
  );
  bool missingDate = false;
  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final c = widget.c, w = c.words;
      final errors = d.submitted ? d.errors(w) : const <String, String>{};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 18,
        children: [
          if (errors.isNotEmpty) _Errors(errors.values),
          _DateLine(
            label: w.date,
            date: d.date,
            incomplete: missingDate,
            error: d.submitted && missingDate ? w.dateError : null,
            words: w,
            change: (date) => d.update(() {
              missingDate = date == null;
              if (date != null) d.date = calendarDay(date);
            }),
          ),
          LedgerRows(
            children: [
              _ClockLine(
                label: w.start,
                minute: d.start,
                words: w,
                onChanged: (v) => d.update(() => d.start = v),
              ),
              _ClockLine(
                label: w.end,
                minute: d.end,
                words: w,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ],
          ),
          if (errors['end'] case final e?)
            Semantics(
              liveRegion: true,
              child: Text(
                e,
                style: context.ledgerTheme.bodySmall.copyWith(
                  color: context.ledgerTheme.danger,
                ),
              ),
            ),
          LedgerSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                LedgerSelectItem(value: p.id, label: w.text(p.name)),
            ],
            errorText: errors['project'],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          LedgerTextArea(
            labelText: w.note,
            hintText: w.noteHint,
            minLines: 2,
            maxLines: 5,
            errorText: errors['note'],
            onChanged: (v) => d.update(() => d.note = v),
          ),
          LedgerButton.filled(
            w.addEntry,
            expand: true,
            onPressed: () {
              if (missingDate) {
                d.validate(w);
                return;
              }
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
      );
    },
  );
}
