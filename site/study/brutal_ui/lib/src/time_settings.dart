part of '../stint_brutal.dart';

extension _Timesheet on _StudioState {
  Widget time() {
    final week = c.week;
    final theme = context.brutalTheme, entries = c.entriesFor(week);
    return BrutalScreen(
      topBar: bar(w.time),
      body: loaded(
        () => _Columns(
          first: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Row(
                children: [
                  BrutalIconButton(
                    icon: Icon(
                      w.arabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                    ),
                    tooltip: w.previousWeek,
                    onPressed: () => c.shiftWeek(-1),
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
                            style: theme.textTheme.title,
                          );
                        },
                      ),
                    ),
                  ),
                  BrutalIconButton(
                    icon: Icon(
                      w.arabic ? LucideIcons.arrowLeft : LucideIcons.arrowRight,
                    ),
                    tooltip: w.nextWeek,
                    onPressed: () => c.shiftWeek(1),
                  ),
                ],
              ),
              BrutalBlock(
                lead: true,
                color: theme.colors.blue,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      w.weekTotal.toUpperCase(),
                      style: theme.textTheme.caption.copyWith(
                        color: theme.colors.onBlock,
                      ),
                    ),
                    Text(
                      w.duration(c.totalMinutes(week)),
                      style: theme.textTheme.display.copyWith(
                        color: theme.colors.onBlock,
                      ),
                    ),
                  ],
                ),
              ),
              // An empty week has nothing to chart: Brutal's axes would
              // count 0.0 to 1.0 with no unit. The empty state beside it
              // says so instead.
              if (entries.isNotEmpty) weekChart(week),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: BrutalButton.filled(
                  w.addEntry,
                  icon: const Icon(LucideIcons.plus),
                  onPressed: addEntry,
                ),
              ),
            ],
          ),
          second: entries.isEmpty
              ? BrutalStateView(state: BrutalState.empty, title: w.noEntries)
              : BrutalListGroup(
                  header: w.entries,
                  children: [
                    for (final e in entries)
                      BrutalListTile(
                        title: w.text(e.note),
                        subtitle:
                            '${w.shortDate(e.date)}${w.dot}${w.clock(e.start)}–${w.clock(e.end)}\n${c.projectName(e.project)}${w.dot}${w.duration(e.end - e.start)}',
                      ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> addEntry() async {
    final saved = await _raise<bool>(
      context,
      (ctx) => BrutalSheet(
        title: w.addEntry,
        closeLabel: w.cancel,
        onClose: () => Navigator.pop(ctx),
        child: _Entry(c),
      ),
    );
    if (mounted && saved == true) showBrutalToast(context, w.entrySaved);
  }

  Widget settings() {
    final p = c.settings,
        theme = context.brutalTheme,
        name = w.text(team.first.name);
    return BrutalScreen(
      topBar: bar(w.settings),
      body: _Columns(
        secondFirstOnPhone: true,
        first: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            BrutalBlock(
              lead: true,
              color: theme.colors.violet,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 6,
                children: [
                  Text(
                    w.account.toUpperCase(),
                    style: theme.textTheme.caption.copyWith(
                      color: theme.colors.onBlock,
                    ),
                  ),
                  Text(
                    name,
                    style: theme.textTheme.headline.copyWith(
                      color: theme.colors.onBlock,
                    ),
                  ),
                  Text(
                    w.teamName,
                    style: theme.textTheme.body.copyWith(
                      color: theme.colors.onBlock,
                    ),
                  ),
                ],
              ),
            ),
            BrutalListGroup(
              header: w.about,
              children: [
                BrutalListTile(title: 'Stint', subtitle: w.aboutDetail),
              ],
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: BrutalButton(
                w.signOut,
                isDestructiveAction: true,
                icon: const Icon(LucideIcons.logOutDir),
                onPressed: () async {
                  final yes = await confirm(
                    w.signOutMessage,
                    w.signOut,
                    w.cancel,
                    destructive: true,
                  );
                  if (yes == true && mounted) c.signIn(false);
                },
              ),
            ),
          ],
        ),
        second: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            BrutalSectionHeader(w.preferences),
            BrutalFormField(
              labelText: w.appearance,
              child: BrutalSegmentedButton(
                semanticLabel: w.appearance,
                value: p.appearance,
                segments: [
                  for (final v in Appearance.values)
                    BrutalSegment(value: v, label: w.appearanceName(v)),
                ],
                onChanged: (v) => p.update(() => p.appearance = v),
              ),
            ),
            BrutalSelect(
              labelText: w.textSize,
              value: p.scale ?? 0.0,
              items: [
                BrutalSelectItem(value: 0.0, label: w.system),
                for (final n in {1.0, 1.5, 2.0, ?p.scale}.toList()..sort())
                  BrutalSelectItem(value: n, label: w.percent(n)),
              ],
              onChanged: (v) => p.update(() => p.scale = v == 0 ? null : v),
            ),
            // A select: four languages' names overflow a segmented row on a phone.
            BrutalSelect(
              labelText: w.languageLabel,
              value: p.language,
              items: [
                for (final l in StintLanguage.values)
                  BrutalSelectItem(value: l, label: l.nativeName),
              ],
              onChanged: (v) => p.update(() => p.language = v),
            ),
            BrutalSelect(
              labelText: w.density,
              value: widget.density,
              items: [
                BrutalSelectItem(
                  value: BrutalDensity.standard,
                  label: w.standard,
                ),
                BrutalSelectItem(
                  value: BrutalDensity.comfortable,
                  label: w.comfortable,
                ),
                BrutalSelectItem(
                  value: BrutalDensity.compact,
                  label: w.compact,
                ),
              ],
              onChanged: widget.onDensity,
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry extends StatefulWidget {
  const _Entry(this.c);
  final StintController c;
  @override
  State<_Entry> createState() => _EntryState();
}

class _EntryState extends State<_Entry> {
  late final d = EntryDraft(
    widget.c.week == mondayOf(studyToday) ? studyToday : widget.c.week,
  );
  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final c = widget.c,
          w = c.words,
          errors = d.submitted ? d.errors(w) : const <String, String>{};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          BrutalDatePicker(
            labelText: w.date,
            value: d.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (v) => d.update(() => d.date = calendarDay(v)),
          ),
          BrutalListGroup(
            children: [
              _TimeCell(
                label: w.start,
                minute: d.start,
                words: w,
                onChanged: (v) => d.update(() => d.start = v),
              ),
              _TimeCell(
                label: w.end,
                minute: d.end,
                words: w,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ],
          ),
          if (errors['end'] case final e?) BrutalFieldMessage(errorText: e),
          BrutalSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                BrutalSelectItem(value: p.id, label: w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
            errorText: errors['project'],
          ),
          BrutalTextField(
            labelText: w.note,
            hintText: w.noteHint,
            minLines: 2,
            maxLines: 4,
            errorText: errors['note'],
            onChanged: (v) => d.update(() => d.note = v),
          ),
          BrutalButton.filled(
            w.addEntry,
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
      );
    },
  );
}
