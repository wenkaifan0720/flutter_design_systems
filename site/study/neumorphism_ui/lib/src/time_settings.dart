part of '../stint_neumorphism.dart';

extension _Timesheet on _WorkspaceState {
  Widget time() {
    final week = c.week,
        minutes = c.dailyMinutes(c.week),
        entries = c.entriesFor(c.week);
    final days = List.generate(7, (i) => addDays(week, i));
    final full = w.weekRange(week), compact = w.weekRange(week, compact: true);
    final summary = NeumorphicCard(
      children: [
        Row(
          spacing: 8,
          children: [
            NeumorphicIconButton(
              LucideIcons.chevronLeftDir,
              label: w.previousWeek,
              onPressed: () => c.shiftWeek(-1),
            ),
            Expanded(
              child: Semantics(
                label: full,
                child: ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (ctx, box) {
                      final style = plaster.textTheme.title;
                      final width = TextPainter.computeWidth(
                        text: TextSpan(text: full, style: style),
                        textDirection: Directionality.of(ctx),
                        textScaler: MediaQuery.textScalerOf(ctx),
                      );
                      return Text(
                        width <= box.maxWidth
                            ? full
                            : compact.replaceFirst(' – ', ' –\n'),
                        textAlign: TextAlign.center,
                        style: style,
                      );
                    },
                  ),
                ),
              ),
            ),
            NeumorphicIconButton(
              LucideIcons.chevronRightDir,
              label: w.nextWeek,
              onPressed: () => c.shiftWeek(1),
            ),
          ],
        ),
        NeumorphicStats([
          NeumorphicStat(w.weekTotal, w.duration(c.totalMinutes(week))),
        ]),
        // An empty week has nothing to chart (an axis from 0h to 0h): its
        // total says 0h and the log says so beside it.
        if (minutes.any((m) => m > 0))
          Semantics(
            label: [
              w.logged,
              for (var i = 0; i < 7; i++)
                '${w.weekday(days[i])} ${w.duration(minutes[i])}',
            ].join(', '),
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (ctx, bounds) => NeumorphicColumnBars(
                  values: [for (final n in minutes) n / 60],
                  labels: [
                    for (final day in days)
                      bounds.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) <
                              230
                          ? w.weekdayShort(day).substring(0, 1)
                          : w.weekdayShort(day),
                  ],
                  now: week == mondayOf(studyToday)
                      ? studyToday.weekday - 1
                      : null,
                  nowLabel: w.today,
                  format: (n) => w.duration((n * 60).round()),
                ),
              ),
            ),
          ),
        NeumorphicButton.filled(
          w.addEntry,
          icon: LucideIcons.plus,
          onPressed: addTime,
        ),
      ],
    );
    final log = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (entries.isEmpty)
          NeumorphicEmptyState(title: w.noEntries, icon: LucideIcons.clock3)
        else
          for (final day in days.reversed)
            if (entries.any((e) => e.date == day))
              NeumorphicCard(
                title: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
                children: [
                  NeumorphicTimeline(
                    label: w.entries,
                    stops: [
                      for (final e in entries.where((e) => e.date == day))
                        NeumorphicTimelineStop(
                          title: w.text(e.note),
                          time: '${w.clock(e.start)}–${w.clock(e.end)}',
                          body:
                              '${c.projectName(e.project)}${w.dot}${w.duration(e.end - e.start)}',
                          // A logged entry is done, today's too: the pigment
                          // stays on the chart's today and the one act.
                          state: NeumorphicStepStatus.past,
                        ),
                    ],
                  ),
                ],
              ),
      ],
    );
    return NeumorphicScaffold(
      topBar: NeumorphicAppBar(title: w.time, actions: [command]),
      body: data(
        () => LayoutBuilder(
          builder: (_, b) => b.maxWidth >= 740
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 26,
                  children: [
                    Expanded(flex: 5, child: summary),
                    Expanded(flex: 6, child: log),
                  ],
                )
              : NeumorphicSections(children: [summary, log]),
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await showNeumorphicBottomSheet<bool>(
      context,
      builder: (_) => _TimeEntry(c),
    );
    if (saved == true && mounted) {
      showNeumorphicToast(context, message: w.entrySaved);
    }
  }

  Future<void> signOut() async {
    final confirmed = await showNeumorphicDialog<bool>(
      context,
      builder: (sheet) => NeumorphicDialog(
        title: w.signOutMessage,
        actions: [
          NeumorphicButton(
            w.cancel,
            onPressed: () => Navigator.pop(sheet, false),
          ),
          NeumorphicButton.filled(
            w.signOut,
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(sheet, true),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) c.signIn(false);
  }

  Widget settings() {
    final s = c.settings;
    // The three selects share one measure (as Filters' fill their cells);
    // each shrank to its value, three widths down one column.
    Widget measured(Widget select) => Align(
      alignment: AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: SizedBox(width: double.infinity, child: select),
      ),
    );
    final prefs = NeumorphicCard(
      title: w.preferences,
      children: [
        measured(
          NeumorphicSelect(
            labelText: w.appearance,
            value: s.appearance,
            options: [
              for (final a in Appearance.values)
                NeumorphicMenuItem(a, w.appearanceName(a)),
            ],
            onChanged: (a) => s.update(() => s.appearance = a),
          ),
        ),
        measured(
          NeumorphicSelect<double>(
            labelText: w.textSize,
            value: s.scale ?? 0,
            options: [
              NeumorphicMenuItem(0, w.system),
              for (final v in [1.0, 1.5, 2.0])
                NeumorphicMenuItem(v, w.percent(v)),
            ],
            onChanged: (v) => s.update(() => s.scale = v == 0 ? null : v),
          ),
        ),
        measured(
          NeumorphicSelect(
            labelText: w.languageLabel,
            value: s.language,
            options: [
              for (final l in StintLanguage.values)
                NeumorphicMenuItem(l, l.nativeName),
            ],
            onChanged: (v) => s.update(() => s.language = v),
          ),
        ),
        _FieldGroup(
          label: w.density,
          child: NeumorphicSegmentedButton<bool>(
            label: w.density,
            value: s.compact,
            segments: [
              NeumorphicButtonSegment(false, w.standard),
              NeumorphicButtonSegment(true, w.compact),
            ],
            onChanged: (v) => s.update(() => s.compact = v),
          ),
        ),
      ],
    );
    final profile = NeumorphicCard(
      title: w.account,
      children: [
        NeumorphicListTile(
          title: c.personName('maya'),
          subtitle: w.teamName,
          leading: NeumorphicAvatar(
            w.mayaInitials,
            name: c.personName('maya'),
          ),
          isFirst: true,
        ),
        NeumorphicButton(
          w.signOut,
          icon: LucideIcons.logOutDir,
          onPressed: signOut,
        ),
      ],
    );
    final about = NeumorphicCard(
      title: w.about,
      children: [Text(w.aboutDetail, style: plaster.textTheme.body)],
    );
    return NeumorphicScaffold(
      topBar: NeumorphicAppBar(title: w.settings, actions: [command]),
      body: LayoutBuilder(
        builder: (_, box) => box.maxWidth >= 700
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 26,
                children: [
                  Expanded(flex: 6, child: prefs),
                  Expanded(
                    flex: 5,
                    child: NeumorphicSections(children: [profile, about]),
                  ),
                ],
              )
            : NeumorphicSections(children: [profile, prefs, about]),
      ),
    );
  }
}

class _TimeEntry extends StatefulWidget {
  const _TimeEntry(this.c);
  final StintController c;
  @override
  State<_TimeEntry> createState() => _TimeEntryState();
}

class _TimeEntryState extends State<_TimeEntry> {
  late final draft = EntryDraft(
    widget.c.week == mondayOf(studyToday) ? studyToday : widget.c.week,
  );
  @override
  void dispose() {
    draft.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (ctx, _) {
      final c = widget.c,
          w = c.words,
          d = draft,
          errors = d.submitted ? d.errors(w) : const <String, String>{};
      return NeumorphicBottomSheet(
        title: w.addEntry,
        actions: [
          NeumorphicButton.filled(
            w.addEntry,
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            MergeSemantics(
              child: Semantics(
                hint: w.shortDate(d.date),
                child: NeumorphicListTile(
                  title: w.date,
                  note: w.shortDate(d.date),
                  leading: const Icon(LucideIcons.calendarDays),
                  isFirst: true,
                  onPressed: () async {
                    final picked = await showNeumorphicDatePicker(
                      ctx,
                      title: w.date,
                      value: d.date,
                      currentDate: studyToday,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2040, 12, 31),
                      confirmLabel: w.apply,
                      cancelLabel: w.cancel,
                    );
                    if (picked != null && mounted) {
                      d.update(() => d.date = calendarDay(picked));
                    }
                  },
                ),
              ),
            ),
            _ClockSetting(
              words: w,
              label: w.start,
              minute: d.start,
              onChanged: (n) => d.update(() => d.start = n),
            ),
            NeumorphicFormField(
              errorText: errors['end'],
              child: _ClockSetting(
                words: w,
                label: w.end,
                minute: d.end,
                onChanged: (n) => d.update(() => d.end = n),
              ),
            ),
            NeumorphicSelect(
              labelText: w.project,
              value: d.project,
              options: [
                for (final p in projects)
                  NeumorphicMenuItem(p.id, w.text(p.name)),
              ],
              onChanged: (p) => d.update(() => d.project = p),
            ),
            NeumorphicTextArea(
              labelText: w.note,
              hintText: w.noteHint,
              maxLines: 2,
              errorText: errors['note'],
              onChanged: (v) => d.update(() => d.note = v),
            ),
          ],
        ),
      );
    },
  );
}
