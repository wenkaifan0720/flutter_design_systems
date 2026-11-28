part of '../stint_fluent2_design.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week, entries = c.entriesFor(week);
    final days = entries.map((e) => e.date).toSet();
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(title: w.time, actions: [commands]),
      body: data(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Row(
                  children: [
                    icon(
                      // The arrows point away from the week, in either
                      // direction: the glyphs turn with the text direction
                      // themselves (matchTextDirection), so they are named
                      // once; swapped here as well, in Arabic they pointed in.
                      Fluent2Icons.chevronLeft,
                      w.previousWeek,
                      () => c.shiftWeek(-1),
                    ),
                    Expanded(
                      child: Semantics(
                        label: w.weekRange(week),
                        excludeSemantics: true,
                        child: LayoutBuilder(
                          builder: (ctx, box) {
                            final style = theme.subtitle1;
                            final full = w.weekRange(week);
                            final width = TextPainter.computeWidth(
                              text: TextSpan(text: full, style: style),
                              textDirection: Directionality.of(ctx),
                              textScaler: MediaQuery.textScalerOf(ctx),
                            );
                            return Text(
                              width <= box.maxWidth
                                  ? full
                                  : w.weekRange(week, compact: true),
                              style: style,
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                    icon(
                      Fluent2Icons.chevronRight,
                      w.nextWeek,
                      () => c.shiftWeek(1),
                    ),
                  ],
                ),
              ),
            ),
            _DeskColumns(
              first: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Fluent2Card(
                    children: [
                      Fluent2CardHeader(
                        header: w.weekTotal,
                        image: const Fluent2IconTile(Fluent2Icons.clock),
                      ),
                      Text(
                        w.duration(c.totalMinutes(week)),
                        style: theme.title1,
                      ),
                      // An empty week has nothing to chart: its total says
                      // 0h and Time entries says so below.
                      if (entries.isNotEmpty) chart(week),
                      Fluent2CardFooter(
                        children: [
                          Fluent2Button(
                            w.addEntry,
                            appearance: Fluent2ButtonAppearance.primary,
                            icon: Fluent2Icons.add,
                            onPressed: addTime,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Fluent2ListSection(
                    title: w.byProject,
                    rows: [
                      for (final p in projects)
                        Fluent2ListItem(
                          title: w.text(p.name),
                          leading: Fluent2IconTile(
                            Fluent2Icons.folderFilled,
                            hue: _hue(p.id),
                            size: 28,
                          ),
                          subtitle: w.duration(
                            entries
                                .where((e) => e.project == p.id)
                                .fold<int>(
                                  0,
                                  (sum, e) => sum + e.end - e.start,
                                ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              second: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Fluent2SectionHeader(w.entries),
                  if (entries.isEmpty)
                    Fluent2EmptyState(
                      title: w.noEntries,
                      icon: Fluent2Icons.clock,
                    ),
                  for (final date in days)
                    Fluent2ListGroup(
                      title: '${w.weekday(date)}${w.dot}${w.shortDate(date)}',
                      children: [
                        for (final e in entries.where((e) => e.date == date))
                          Fluent2ListItem(
                            title: w.text(e.note),
                            subtitle:
                                '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                            value: w.duration(e.end - e.start),
                            leading: Fluent2IconTile(
                              Fluent2Icons.clock,
                              hue: _hue(e.project),
                              size: 28,
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await _drawer<bool>(context, (ctx) => _Entry(c));
    if (saved == true && mounted) showFluent2Toast(context, w.entrySaved);
  }

  Widget settings() {
    final prefs = c.settings;
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(title: w.settings, actions: [commands]),
      // On the title's start line, not centred beside it.
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              Fluent2ListGroup(
                title: w.account,
                children: [
                  Fluent2ListItem(
                    title: c.personName('maya'),
                    subtitle: w.teamName,
                    // The avatar every other place draws for Maya: its colour
                    // from her name's one spelling, not the Arabic one.
                    leading: _personAvatar(
                      team.firstWhere((p) => p.id == 'maya'),
                      size: 44,
                    ),
                  ),
                ],
              ),
              Fluent2FormSection(
                title: w.preferences,
                children: [
                  Fluent2FormField(
                    labelText: w.appearance,
                    child: Fluent2Select(
                      value: prefs.appearance,
                      options: [
                        for (final a in Appearance.values)
                          Fluent2Option(a, w.appearanceName(a)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.appearance = v),
                    ),
                  ),
                  Fluent2FormField(
                    labelText: w.textSize,
                    child: Fluent2Select<double>(
                      value: prefs.scale ?? 0,
                      options: [
                        Fluent2Option(0, w.system),
                        for (final n in [1.0, 1.5, 2.0])
                          Fluent2Option(n, w.percent(n)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.scale = v == 0 ? null : v),
                    ),
                  ),
                  Fluent2FormField(
                    labelText: w.languageLabel,
                    child: Fluent2Select(
                      value: prefs.language,
                      options: [
                        for (final l in StintLanguage.values)
                          Fluent2Option(l, l.nativeName),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.language = v),
                    ),
                  ),
                  Fluent2FormField(
                    labelText: w.density,
                    child: Fluent2Select(
                      value: prefs.compact,
                      options: [
                        Fluent2Option(false, w.standard),
                        Fluent2Option(true, w.compact),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.compact = v),
                    ),
                  ),
                ],
              ),
              Fluent2ListGroup(
                title: w.about,
                children: [
                  Fluent2ListItem(
                    title: 'Stint',
                    subtitle: w.aboutDetail,
                    icon: Fluent2Icons.info,
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Fluent2Button(
                  w.signOut,
                  icon: Fluent2Icons.arrowExit,
                  onPressed: () async {
                    final yes = await Fluent2Dialog.confirm(
                      context,
                      title: w.signOut,
                      message: w.signOutMessage,
                      confirmLabel: w.signOut,
                      cancelLabel: w.cancel,
                    );
                    if (yes == true && mounted) c.signIn(false);
                  },
                ),
              ),
            ],
          ),
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
      final w = widget.c.words,
          errors = d.submitted
              ? d.errors(widget.c.words)
              : const <String, String>{};
      return Fluent2Sheet(
        title: w.addEntry,
        actions: [
          Fluent2Button(
            w.addEntry,
            appearance: Fluent2ButtonAppearance.primary,
            icon: Fluent2Icons.add,
            onPressed: () {
              if (widget.c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
        child: Fluent2FormSection(
          children: [
            Fluent2FormField(
              labelText: w.date,
              child: Fluent2DatePicker(
                value: d.date,
                onChanged: (v) => d.update(() => d.date = calendarDay(v)),
                today: studyToday,
                format: w.shortDate,
              ),
            ),
            Fluent2FormField(
              labelText: w.start,
              child: _ClockField(
                label: w.start,
                value: d.start,
                onChanged: (v) => d.update(() => d.start = v),
              ),
            ),
            Fluent2FormField(
              labelText: w.end,
              validationMessage: errors['end'],
              validationState: errors['end'] == null
                  ? null
                  : Fluent2ValidationState.error,
              child: _ClockField(
                label: w.end,
                value: d.end,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ),
            Fluent2FormField(
              labelText: w.project,
              child: Fluent2Select(
                value: d.project,
                options: [
                  for (final p in projects) Fluent2Option(p.id, w.text(p.name)),
                ],
                onChanged: (v) => d.update(() => d.project = v),
              ),
            ),
            Fluent2FormField(
              labelText: w.note,
              validationMessage: errors['note'],
              validationState: errors['note'] == null
                  ? null
                  : Fluent2ValidationState.error,
              child: Fluent2TextArea(
                hintText: w.noteHint,
                invalid: errors['note'] != null,
                onChanged: (v) => d.update(() => d.note = v),
              ),
            ),
          ],
        ),
      );
    },
  );
}
