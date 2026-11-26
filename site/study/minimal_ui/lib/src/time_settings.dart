part of '../stint_minimal.dart';

extension _TimeAndPreferences on _WorkspaceState {
  Widget time() {
    final week = c.week, entries = c.entriesFor(week);
    final daily = c.dailyMinutes(week);
    final pressed = bar?.$1 == week ? bar!.$2 : null;
    final today = week == mondayOf(studyToday) ? studyToday.weekday - 1 : null;
    final lit =
        pressed ??
        today ??
        daily.indexOf(daily.reduce((a, b) => a > b ? a : b));
    final chart = MinimalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Text(w.weekTotal, style: context.minimalTheme.label),
          Text(
            w.duration(c.totalMinutes(week)),
            style: context.minimalTheme.display,
          ),
          // One day's figure, on a line of its own at any text size: the
          // bar pressed, else today's, else the week's longest.
          Text(
            '${w.weekday(addDays(week, lit))}${w.dot}${w.duration(daily[lit])}',
            style: context.minimalTheme.label.copyWith(
              color: context.minimalTheme.mutedForeground,
            ),
          ),
          MinimalBarChart(
            [for (final n in daily) n / 60],
            labels: [
              for (var i = 0; i < 7; i++) w.weekdayShort(addDays(week, i)),
            ],
            semanticLabel: w.logged,
            format: (hours) => w.duration((hours * 60).round()),
            highlight: lit,
            onBarPressed: (i) => readBar(week, i),
          ),
        ],
      ),
    );
    final log = MinimalSection(
      title: w.entries,
      child: entries.isEmpty
          ? MinimalEmptyState(icon: LucideIcons.timer, title: w.noEntries)
          : MinimalListSection(
              children: [
                for (final e in entries)
                  MinimalListTile(
                    title: w.text(e.note),
                    subtitle:
                        '${w.shortDate(e.date)}${w.dot}${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                    meta: w.duration(e.end - e.start),
                  ),
              ],
            ),
    );
    return MinimalScaffold(
      topBar: MinimalAppBar(title: w.time, actions: [commandKey]),
      body: dataBody(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 18,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              runSpacing: 7,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // The arrows point away from the week: Lucide's glyphs
                    // don't turn with the text, so right to left they swap.
                    icon(
                      w.arabic
                          ? LucideIcons.chevronRight
                          : LucideIcons.chevronLeft,
                      w.previousWeek,
                      () => c.shiftWeek(-1),
                    ),
                    Text(
                      '${w.shortDate(week)} – ${w.shortDate(addDays(week, 6))}',
                      style: context.minimalTheme.h3,
                    ),
                    icon(
                      w.arabic
                          ? LucideIcons.chevronLeft
                          : LucideIcons.chevronRight,
                      w.nextWeek,
                      () => c.shiftWeek(1),
                    ),
                  ],
                ),
                MinimalButton(
                  w.addEntry,
                  icon: LucideIcons.plus,
                  onPressed: addTime,
                ),
              ],
            ),
            LayoutBuilder(
              builder: (ctx, box) =>
                  box.maxWidth >= 800 * MediaQuery.textScalerOf(ctx).scale(1)
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 20,
                      children: [
                        Expanded(flex: 2, child: chart),
                        Expanded(flex: 3, child: log),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 20,
                      children: [chart, log],
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
      title: w.addEntry,
      builder: (_) => SingleChildScrollView(child: _EntryForm(c)),
    );
    if (saved == true && mounted) showMinimalSnackBar(context, w.entrySaved);
  }

  Widget settings() {
    final prefs = c.settings, t = context.minimalTheme;
    return MinimalScaffold(
      topBar: MinimalAppBar(title: w.settings, actions: [commandKey]),
      // On the page's start line, as the task form stands.
      body: Align(
        alignment: AlignmentDirectional.topStart,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 22,
            children: [
              MinimalListSection(
                children: [
                  MinimalListTile(
                    leading: MinimalAvatar(c.personName('maya'), size: 36),
                    title: c.personName('maya'),
                    subtitle: w.teamName,
                  ),
                ],
              ),
              MinimalSection(
                title: w.preferences,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    MinimalSelect(
                      labelText: w.appearance,
                      value: prefs.appearance,
                      options: [
                        for (final a in Appearance.values)
                          MinimalSelectOption(a, w.appearanceName(a)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.appearance = v),
                    ),
                    MinimalSelect<double>(
                      labelText: w.textSize,
                      value: prefs.scale ?? 0,
                      options: [
                        MinimalSelectOption(0, w.system),
                        for (final n in [1.0, 1.5, 2.0])
                          MinimalSelectOption(n, w.percent(n)),
                      ],
                      onChanged: (v) =>
                          prefs.update(() => prefs.scale = v == 0 ? null : v),
                    ),
                    // A select, as every other preference in the group.
                    MinimalSelect(
                      labelText: w.languageLabel,
                      value: prefs.language,
                      options: [
                        for (final l in StintLanguage.values)
                          MinimalSelectOption(l, l.nativeName),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.language = v),
                    ),
                    MinimalSelect(
                      labelText: w.density,
                      value: prefs.compact,
                      options: [
                        MinimalSelectOption(false, w.standard),
                        MinimalSelectOption(true, w.compact),
                      ],
                      onChanged: (v) => prefs.update(() => prefs.compact = v),
                    ),
                  ],
                ),
              ),
              MinimalSection(
                title: w.about,
                child: Text(w.aboutDetail, style: t.body),
              ),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MinimalButton(
                  w.signOut,
                  icon: LucideIcons.logOutDir,
                  variant: MinimalButtonVariant.secondary,
                  onPressed: () async {
                    final yes = await showMinimalDialog<bool>(
                      context,
                      builder: (_) => MinimalDialog(
                        title: w.signOutMessage,
                        confirmLabel: w.signOut,
                        cancelLabel: w.cancel,
                        destructive: true,
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

class _EntryForm extends StatefulWidget {
  const _EntryForm(this.model);
  final StintController model;
  @override
  State<_EntryForm> createState() => _EntryState();
}

class _EntryState extends State<_EntryForm> {
  late final d = EntryDraft(
    widget.model.week == mondayOf(studyToday) ? studyToday : widget.model.week,
  );
  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: d,
    builder: (context, _) {
      final c = widget.model,
          w = c.words,
          errors = d.submitted ? d.errors(w) : const <String, String>{};
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          // The same date row as the task's due date: its label on the
          // start/end times' edge, the date in the form's own format.
          MinimalDatePicker(
            labelText: w.date,
            value: d.date,
            mode: MinimalDatePickerMode.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (day) => d.update(() => d.date = calendarDay(day)),
          ),
          MinimalTimePicker(
            labelText: w.start,
            value: atMinute(d.date, d.start),
            onChanged: (v) => d.update(() => d.start = minuteOfDay(v)),
          ),
          MinimalTimePicker(
            labelText: w.end,
            value: atMinute(d.date, d.end),
            onChanged: (v) => d.update(() => d.end = minuteOfDay(v)),
          ),
          if (errors['end'] case final error?)
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: context.minimalTheme.body.copyWith(
                  color: context.minimalTheme.destructive,
                ),
              ),
            ),
          MinimalSelect(
            labelText: w.project,
            value: d.project,
            options: [
              for (final p in projects)
                MinimalSelectOption(p.id, w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          MinimalTextArea(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            onChanged: (v) => d.update(() => d.note = v),
          ),
          MinimalButton(
            w.addEntry,
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(context, true);
            },
          ),
        ],
      );
    },
  );
}
