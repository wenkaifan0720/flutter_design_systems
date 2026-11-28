part of '../stint_material_expressive.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week, entries = c.entriesFor(week), colors = theme.colors;
    final range = w.weekRange(week);
    final days = entries.map((e) => e.date).toSet();
    return ExpressiveScaffold(
      topBar: ExpressiveAppBar(title: w.time, actions: [commandKey]),
      body: data(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 20,
          children: [
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 540),
                child: Row(
                  children: [
                    icon(
                      // The arrows point away from the week; the symbols turn
                      // with the text direction on their own.
                      ExpressiveSymbols.chevronLeft,
                      w.previousWeek,
                      () => c.shiftWeek(-1),
                    ),
                    Expanded(
                      child: Semantics(
                        label: range,
                        excludeSemantics: true,
                        child: LayoutBuilder(
                          builder: (ctx, box) {
                            final width = TextPainter.computeWidth(
                              text: TextSpan(
                                text: range,
                                style: theme.type.titleLarge,
                              ),
                              textDirection: Directionality.of(ctx),
                              textScaler: MediaQuery.textScalerOf(ctx),
                            );
                            final condensed = w.weekRange(week, compact: true);
                            return ExpressiveText(
                              width <= box.maxWidth ? range : condensed,
                              role: ExpressiveTextRole.title,
                              size: ExpressiveTextSize.large,
                              textAlign: TextAlign.center,
                            );
                          },
                        ),
                      ),
                    ),
                    icon(
                      ExpressiveSymbols.chevronRight,
                      w.nextWeek,
                      () => c.shiftWeek(1),
                    ),
                  ],
                ),
              ),
            ),
            _Columns(
              first: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.secondaryContainer,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    ExpressiveText(
                      w.weekTotal,
                      role: ExpressiveTextRole.label,
                      color: colors.onSecondaryContainer,
                    ),
                    ExpressiveText(
                      w.duration(c.totalMinutes(week)),
                      role: ExpressiveTextRole.display,
                      size: ExpressiveTextSize.small,
                      color: colors.onSecondaryContainer,
                    ),
                    // The chart stands on the card's secondaryContainer: its
                    // words take the container's own ink, as Material pairs
                    // them, and today's bar keeps primary.
                    ExpressiveTheme(
                      data: theme.copyWith(
                        colors: colors.copyWith(
                          onSurface: colors.onSecondaryContainer,
                          onSurfaceVariant: colors.onSecondaryContainer,
                        ),
                      ),
                      child: chart(week),
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: ExpressiveFilledButton(
                        w.addEntry,
                        icon: ExpressiveSymbols.add,
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
                  _Heading(w.entries),
                  if (entries.isEmpty)
                    ExpressiveEmptyState(
                      icon: ExpressiveSymbols.schedule,
                      title: w.noEntries,
                    ),
                  for (final date in days)
                    ExpressiveListSection(
                      header: '${w.weekday(date)}${w.dot}${w.shortDate(date)}',
                      children: [
                        for (final e in entries.where((e) => e.date == date))
                          ExpressiveListTile(
                            title: Text(w.text(e.note)),
                            subtitle: Text(
                              '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                            ),
                            // The entry's hours at its end in the label
                            // style a figure takes (M3's trailing text is
                            // the row's smallest; the hours are its key).
                            trailing: Text(
                              w.duration(e.end - e.start),
                              style: theme.type.labelLarge.copyWith(
                                color: theme.colors.onSurface,
                              ),
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
    final saved = await _raise<bool>(
      context,
      (_) => _Entry(c),
      cancel: w.cancel,
    );
    if (saved == true && mounted) showExpressiveSnackBar(context, w.entrySaved);
  }

  Widget settings() {
    final prefs = c.settings;
    return ExpressiveScaffold(
      topBar: ExpressiveAppBar(title: w.settings, actions: [commandKey]),
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 2 * _settingsColumn + 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [
              ExpressiveListSection(
                children: [
                  ExpressiveListTile(
                    title: Text(c.personName('maya')),
                    subtitle: Text(w.teamName),
                    leading: ExpressiveAvatar(name: c.personName('maya')),
                  ),
                ],
              ),
              _Heading(w.preferences),
              _Columns(
                breakpoint: 2 * _settingsColumn + 16,
                first: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    ExpressiveSelect(
                      labelText: w.appearance,
                      value: prefs.appearance,
                      options: [
                        for (final a in Appearance.values)
                          ExpressiveSelectOption(a, w.appearanceName(a)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.appearance = v),
                    ),
                    ExpressiveSelect<double>(
                      labelText: w.textSize,
                      value: prefs.scale ?? 0,
                      options: [
                        ExpressiveSelectOption(0, w.system),
                        for (final n in [1.0, 1.5, 2.0])
                          ExpressiveSelectOption(n, w.percent(n)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.scale = v == 0 ? null : v),
                    ),
                  ],
                ),
                second: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    ExpressiveSelect(
                      labelText: w.languageLabel,
                      value: prefs.language,
                      options: [
                        for (final l in StintLanguage.values)
                          ExpressiveSelectOption(l, l.nativeName),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.language = v),
                    ),
                    ExpressiveSelect(
                      labelText: w.density,
                      value: prefs.compact,
                      options: [
                        ExpressiveSelectOption(false, w.standard),
                        ExpressiveSelectOption(true, w.compact),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.compact = v),
                    ),
                  ],
                ),
              ),
              ExpressiveListSection(
                children: [
                  ExpressiveListTile(
                    title: Text(w.about),
                    subtitle: Text(w.aboutDetail),
                    leading: const ExpressiveIcon(ExpressiveSymbols.info),
                  ),
                ],
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExpressiveOutlinedButton(
                  w.signOut,
                  icon: ExpressiveSymbols.logout,
                  onPressed: () async {
                    final yes = await showExpressiveDialog<bool>(
                      context: context,
                      builder: (_) => ExpressiveDialog(
                        icon: ExpressiveSymbols.logout,
                        title: w.signOut,
                        text: w.signOutMessage,
                        actions: [
                          ExpressiveDialogAction(w.cancel, value: false),
                          ExpressiveDialogAction(
                            w.signOut,
                            value: true,
                            filled: true,
                          ),
                        ],
                      ),
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
      return _Sheet(
        title: w.addEntry,
        children: [
          ExpressiveListSection(
            children: [
              ExpressiveListTile(
                title: Text(w.date),
                subtitle: Text(w.shortDate(d.date)),
                leading: const ExpressiveIcon(ExpressiveSymbols.calendarMonth),
                onTap: () async {
                  final date = await _pickDate(
                    ctx,
                    w.date,
                    d.date,
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
                words: w,
                onChanged: (v) => d.update(() => d.start = v),
              ),
              _ClockLine(
                label: w.end,
                value: d.end,
                words: w,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ],
          ),
          if (errors['end'] case final error?)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: ctx.expressiveTheme.colors.error),
              ),
            ),
          ExpressiveSelect(
            labelText: w.project,
            value: d.project,
            options: [
              for (final p in projects)
                ExpressiveSelectOption(p.id, w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          ExpressiveTextArea(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            onChanged: (v) => d.update(() => d.note = v),
          ),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ExpressiveFilledButton(
              w.addEntry,
              icon: ExpressiveSymbols.check,
              onPressed: () {
                if (widget.c.addEntry(d)) Navigator.pop(ctx, true);
              },
            ),
          ),
        ],
      );
    },
  );
}

// A settings column: two of them, 16 apart, stand side by side.
const double _settingsColumn = 320;
