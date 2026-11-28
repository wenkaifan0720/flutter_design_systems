part of '../stint_retro_desktop.dart';

extension _Timesheet on _WorkspaceState {
  Widget dailyChart(DateTime week) {
    final daily = c.dailyMinutes(week),
        days = List.generate(7, (i) => addDays(week, i));
    final spoken = [
      for (var i = 0; i < 7; i++)
        '${w.weekday(days[i])} ${w.duration(daily[i])}',
    ].join(', ');
    return LayoutBuilder(
      builder: (ctx, room) {
        final short =
            room.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 290;
        return RetroDesktopBarChart(
          semanticLabel: w.logged,
          summary: spoken,
          height: 144,
          series: [
            if (daily.any((n) => n > 0))
              RetroDesktopChartSeries(w.logged, [
                for (final n in daily) n / 60,
              ]),
          ],
          labels: [
            for (final d in days)
              short ? w.weekdayShort(d).substring(0, 1) : w.weekdayShort(d),
          ],
          format: (hours) => w.duration((hours * 60).round()),
        );
      },
    );
  }

  Widget weekSwitcher(DateTime week) {
    final full = w.weekRange(week), compact = w.weekRange(week, compact: true);
    return Row(
      spacing: 5,
      children: [
        _ToolButton(
          LucideIcons.chevronLeftDir,
          label: w.previousWeek,
          onPressed: () => c.shiftWeek(-1),
        ),
        Expanded(
          child: Semantics(
            label: full,
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (ctx, room) {
                  final style = desk.textTheme.chrome;
                  final width = TextPainter.computeWidth(
                    text: TextSpan(text: full, style: style),
                    textDirection: Directionality.of(ctx),
                    textScaler: MediaQuery.textScalerOf(ctx),
                  );
                  return Text(
                    width <= room.maxWidth
                        ? full
                        : compact.replaceFirst(' – ', ' –\n'),
                    style: style,
                    textAlign: TextAlign.center,
                  );
                },
              ),
            ),
          ),
        ),
        _ToolButton(
          LucideIcons.chevronRightDir,
          label: w.nextWeek,
          onPressed: () => c.shiftWeek(1),
        ),
      ],
    );
  }

  Widget time() {
    final week = c.week,
        entries = c.entriesFor(week),
        days = List.generate(7, (i) => addDays(week, i));
    return RetroDesktopScaffold(
      body: RetroDesktopDesktop(
        active: w.time,
        tiles: [
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopWindow(
                title: w.time,
                icon: RetroDesktopGlyphs.clock,
                child: data(
                  () => RetroDesktopSections(
                    children: [
                      weekSwitcher(week),
                      _WeekFigure(
                        w.weekTotal,
                        w.duration(c.totalMinutes(week)),
                      ),
                      dailyChart(week),
                      // A phone's block button: German's words need the
                      // window's width on one line.
                      RetroDesktopButton(
                        w.addEntry,
                        icon: RetroDesktopGlyphs.plus,
                        isDefaultAction: true,
                        wide: true,
                        onPressed: addTime,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 7,
            windows: [
              RetroDesktopWindow(
                title: w.entries,
                icon: RetroDesktopGlyphs.fileText,
                padding: const EdgeInsets.all(8),
                child: data(
                  () => entries.isEmpty
                      ? RetroDesktopEmptyState(title: w.noEntries)
                      : RetroDesktopWell(
                          padding: const EdgeInsets.all(8),
                          child: RetroDesktopSections(
                            children: [
                              for (final day in days.reversed)
                                if (entries.any((e) => e.date == day))
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    spacing: 4,
                                    children: [
                                      Text(
                                        '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
                                        style: desk.textTheme.sub,
                                      ),
                                      const RetroDesktopDivider(),
                                      for (final e in entries.where(
                                        (e) => e.date == day,
                                      ))
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 5,
                                          ),
                                          // The entry's length ends its
                                          // title's line, as the week's
                                          // rows end in theirs.
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Row(
                                                spacing: 12,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      w.text(e.note),
                                                      style: desk.textTheme.row,
                                                    ),
                                                  ),
                                                  Text(
                                                    w.duration(e.end - e.start),
                                                    style: desk.textTheme.row,
                                                  ),
                                                ],
                                              ),
                                              Text(
                                                '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                                                style: desk.textTheme.caption,
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                            ],
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await showRetroDesktopBottomSheet<bool>(
      context,
      builder: (_) => _TimeEntry(c),
    );
    if (mounted && saved == true) {
      showRetroDesktopSnackBar(context, w.entrySaved);
    }
  }

  Future<void> signOut() async {
    final confirmed = await showRetroDesktopDialog<bool>(
      context,
      builder: (_) => RetroDesktopDialog(
        // An alert, so the period's caution picture, as the load error
        // carries its stop sign.
        tone: RetroDesktopTone.warning,
        title: w.signOutMessage,
        actions: [
          RetroDesktopDialogAction(w.cancel, value: false),
          RetroDesktopDialogAction(
            w.signOut,
            value: true,
            isDefaultAction: true,
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) c.signIn(false);
  }

  Widget settings() {
    final s = c.settings;
    return RetroDesktopScaffold(
      body: RetroDesktopDesktop(
        active: w.settings,
        phoneOrder: [w.settings, w.account, w.about],
        tiles: [
          RetroDesktopWindowColumn(
            span: 7,
            windows: [
              RetroDesktopWindow(
                title: w.settings,
                icon: LucideIcons.slidersHorizontal,
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopSelect(
                      labelText: w.appearance,
                      value: s.appearance,
                      options: [
                        for (final a in Appearance.values)
                          RetroDesktopOption(a, w.appearanceName(a)),
                      ],
                      onChanged: (a) => s.update(() => s.appearance = a),
                    ),
                    RetroDesktopSelect<double>(
                      labelText: w.textSize,
                      value: s.scale ?? 0,
                      options: [
                        RetroDesktopOption(0, w.system),
                        for (final v in [1.0, 1.5, 2.0])
                          RetroDesktopOption(v, w.percent(v)),
                      ],
                      onChanged: (v) =>
                          s.update(() => s.scale = v == 0 ? null : v),
                    ),
                    RetroDesktopSelect(
                      labelText: w.languageLabel,
                      value: s.language,
                      options: [
                        for (final l in StintLanguage.values)
                          RetroDesktopOption(l, l.nativeName),
                      ],
                      onChanged: (v) => s.update(() => s.language = v),
                    ),
                    RetroDesktopSelect<RetroDesktopDensity>(
                      labelText: w.density,
                      value: desk.density,
                      options: [
                        RetroDesktopOption(
                          RetroDesktopDensity.standard,
                          w.standard,
                        ),
                        RetroDesktopOption(
                          RetroDesktopDensity.comfortable,
                          w.comfortable,
                        ),
                        RetroDesktopOption(
                          RetroDesktopDensity.compact,
                          w.compact,
                        ),
                      ],
                      onChanged: widget.chooseDensity,
                    ),
                  ],
                ),
              ),
            ],
          ),
          RetroDesktopWindowColumn(
            span: 5,
            windows: [
              RetroDesktopWindow(
                title: w.account,
                icon: RetroDesktopGlyphs.user,
                child: RetroDesktopSections(
                  children: [
                    // Who is signed in, on the window's content line as Sign
                    // out and About's words are (a list row's own margin set
                    // the avatar 10 px in from both).
                    Row(
                      spacing: 10,
                      children: [
                        RetroDesktopAvatar(
                          w.mayaInitials,
                          name: c.personName('maya'),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            spacing: 2,
                            children: [
                              Text(
                                c.personName('maya'),
                                style: desk.textTheme.row,
                              ),
                              Text(w.teamName, style: desk.textTheme.meta),
                            ],
                          ),
                        ),
                      ],
                    ),
                    RetroDesktopButton(
                      w.signOut,
                      icon: RetroDesktopGlyphs.signOut,
                      onPressed: signOut,
                    ),
                  ],
                ),
              ),
              RetroDesktopWindow(
                title: w.about,
                icon: RetroDesktopGlyphs.fileText,
                child: Text(w.aboutDetail, style: desk.textTheme.read),
              ),
            ],
          ),
        ],
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
          e = draft.submitted ? draft.errors(w) : const <String, String>{};
      return RetroDesktopBottomSheet(
        title: w.addEntry,
        actions: [
          RetroDesktopButton(
            w.addEntry,
            isDefaultAction: true,
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
        child: RetroDesktopSections(
          children: [
            RetroDesktopListTile(
              title: w.date,
              note: w.shortDate(d.date),
              isFirst: true,
              leading: const Icon(RetroDesktopGlyphs.calendar),
              onPressed: () async {
                final picked = await showRetroDesktopDatePicker(
                  ctx,
                  title: w.date,
                  value: d.date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2040, 12, 31),
                );
                if (mounted && picked != null) {
                  d.update(() => d.date = calendarDay(picked));
                }
              },
            ),
            _ClockSetting(
              words: w,
              label: w.start,
              minute: d.start,
              onChanged: (v) => d.update(() => d.start = v),
            ),
            RetroDesktopFormField(
              errorText: e['end'],
              child: _ClockSetting(
                words: w,
                label: w.end,
                minute: d.end,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ),
            RetroDesktopSelect(
              labelText: w.project,
              value: d.project,
              options: [
                for (final p in projects)
                  RetroDesktopOption(p.id, w.text(p.name)),
              ],
              onChanged: (p) => d.update(() => d.project = p),
            ),
            Semantics(
              container: true,
              child: RetroDesktopTextArea(
                labelText: w.note,
                hintText: w.noteHint,
                errorText: e['note'],
                lines: 2,
                onChanged: (v) => d.update(() => d.note = v),
              ),
            ),
          ],
        ),
      );
    },
  );
}
