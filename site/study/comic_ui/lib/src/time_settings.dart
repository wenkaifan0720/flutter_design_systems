part of '../stint_comic.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week,
        entries = c.entriesFor(week),
        dates = entries.map((e) => e.date).toSet();
    return ComicScaffold(
      topBar: ComicAppBar(title: w.time, actions: [commands]),
      body: data(
        () => ComicSections(
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Row(
                  children: [
                    icon(
                      // The arrows point away from the week, in either direction.
                      w.arabic ? ComicGlyphs.arrowRight : ComicGlyphs.arrowLeft,
                      w.previousWeek,
                      () => c.shiftWeek(-1),
                    ),
                    Expanded(
                      child: Semantics(
                        label: w.weekRange(week),
                        excludeSemantics: true,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: LayoutBuilder(
                            builder: (ctx, b) {
                              final full = w.weekRange(week),
                                  style = t.type.title;
                              final size = TextPainter.computeWidth(
                                text: TextSpan(text: full, style: style),
                                textDirection: Directionality.of(ctx),
                                textScaler: MediaQuery.textScalerOf(ctx),
                              );
                              return Text(
                                size <= b.maxWidth
                                    ? full
                                    : w.weekRange(week, compact: true),
                                style: style,
                                textAlign: TextAlign.center,
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    icon(
                      w.arabic ? ComicGlyphs.arrowLeft : ComicGlyphs.arrowRight,
                      w.nextWeek,
                      () => c.shiftWeek(1),
                    ),
                  ],
                ),
              ),
            ),
            _Strip(
              first: ComicPanel(
                caption: w.weekTotal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Text(w.duration(c.totalMinutes(week)), style: t.type.panel),
                    chart(week),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ComicButton.filled(
                        w.addEntry,
                        icon: ComicGlyphs.add,
                        onPressed: addTime,
                      ),
                    ),
                  ],
                ),
              ),
              second: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  ComicSectionHeader(w.entries),
                  if (entries.isEmpty)
                    ComicPanel(child: ComicEmptyState(title: w.noEntries)),
                  for (final day in dates)
                    ComicPanel(
                      caption: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final (i, e)
                              in entries.where((e) => e.date == day).indexed)
                            ComicListTile(
                              title: w.text(e.note),
                              subtitle:
                                  '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                              note: w.duration(e.end - e.start),
                              isFirst: i == 0,
                            ),
                        ],
                      ),
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
    final saved = await _raise<bool>(context, (_) => _Entry(c));
    if (saved == true && mounted) showComicSnackBar(context, w.entrySaved);
  }

  Widget settings() {
    final prefs = c.settings;
    return ComicScaffold(
      topBar: ComicAppBar(title: w.settings, actions: [commands]),
      body: ComicSections(
        children: [
          ComicPanel(
            caption: w.account,
            child: Row(
              spacing: 12,
              children: [
                ComicPerson.seeded(
                  c.personName('maya'),
                  isCurrentUser: true,
                  size: 46,
                ),
                Expanded(
                  child: ComicPanelHead(c.personName('maya'), sub: w.teamName),
                ),
              ],
            ),
          ),
          _Strip(
            first: ComicPanel(
              caption: w.preferences,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  MergeSemantics(
                    child: ComicSelect(
                      labelText: w.appearance,
                      value: prefs.appearance,
                      options: [
                        for (final n in Appearance.values)
                          ComicSelectOption(n, w.appearanceName(n)),
                      ],
                      onChanged: (n) =>
                          prefs.update(() => prefs.appearance = n),
                    ),
                  ),
                  MergeSemantics(
                    child: ComicSelect<double>(
                      labelText: w.textSize,
                      value: prefs.scale ?? 0,
                      options: [
                        ComicSelectOption(0, w.system),
                        for (final n in [1.0, 1.5, 2.0])
                          ComicSelectOption(n, w.percent(n)),
                      ],
                      onChanged: (n) =>
                          prefs.update(() => prefs.scale = n == 0 ? null : n),
                    ),
                  ),
                  MergeSemantics(
                    child: ComicSelect(
                      labelText: w.languageLabel,
                      value: prefs.language,
                      options: [
                        for (final l in StintLanguage.values)
                          ComicSelectOption(l, l.nativeName),
                      ],
                      onChanged: (n) => prefs.update(() => prefs.language = n),
                    ),
                  ),
                  MergeSemantics(
                    child: ComicSelect(
                      labelText: w.density,
                      value: prefs.compact,
                      options: [
                        ComicSelectOption(false, w.standard),
                        ComicSelectOption(true, w.compact),
                      ],
                      onChanged: (n) => prefs.update(() => prefs.compact = n),
                    ),
                  ),
                ],
              ),
            ),
            second: ComicPanel(
              caption: w.about,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Text(w.aboutDetail, style: t.type.body),
                  ComicButton(
                    w.signOut,
                    icon: ComicGlyphs.signOut,
                    onPressed: () async {
                      final yes = await showComicDialog<bool>(
                        context,
                        builder: (ctx) => ComicDialog(
                          title: w.signOut,
                          message: w.signOutMessage,
                          actions: [
                            ComicButton(
                              w.cancel,
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            ComicButton.filled(
                              w.signOut,
                              onPressed: () => Navigator.pop(ctx, true),
                            ),
                          ],
                        ),
                      );
                      if (yes == true && mounted) c.signIn(false);
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
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
          errors = d.submitted ? d.errors(w) : const <String, String>{};
      return _Panel(
        title: w.addEntry,
        onClose: () => Navigator.pop(ctx),
        cancel: w.cancel,
        actions: [
          ComicButton.filled(
            w.addEntry,
            icon: ComicGlyphs.check,
            onPressed: () {
              if (widget.c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            _InkRow(
              title: w.date,
              subtitle: w.shortDate(d.date),
              first: true,
              leading: const Icon(ComicGlyphs.calendar),
              onPressed: () async {
                final date = await _pickDay(
                  ctx,
                  value: d.date,
                  title: w.date,
                  cancel: w.cancel,
                );
                if (mounted && date != null) {
                  d.update(() => d.date = calendarDay(date));
                }
              },
            ),
            _ClockLine(
              label: w.start,
              value: d.start,
              w: w,
              onChanged: (v) => d.update(() => d.start = v),
            ),
            _ClockLine(
              label: w.end,
              value: d.end,
              w: w,
              onChanged: (v) => d.update(() => d.end = v),
            ),
            if (errors['end'] case final err?)
              Semantics(
                liveRegion: true,
                child: Text(err, style: ctx.comicTheme.type.title),
              ),
            MergeSemantics(
              child: ComicSelect(
                labelText: w.project,
                value: d.project,
                options: [
                  for (final p in projects)
                    ComicSelectOption(p.id, w.text(p.name)),
                ],
                onChanged: (v) => d.update(() => d.project = v),
              ),
            ),
            _RequiredField(
              multiline: true,
              submitted: d.submitted,
              label: w.note,
              hint: w.noteHint,
              error: errors['note'],
              onChanged: (v) => d.update(() => d.note = v),
            ),
          ],
        ),
      );
    },
  );
}
