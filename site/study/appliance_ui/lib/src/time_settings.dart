part of '../stint_appliance.dart';

extension _TimesheetAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week, entries = c.entriesFor(week);
    final days = List.generate(7, (i) => addDays(week, i));
    Widget weekButton(IconData glyph, String label, int delta) =>
        SizedBox.fromSize(
          size: ApplianceTheme.tapTargets.touch,
          child: keyButton(glyph, label, () => c.shiftWeek(delta)),
        );
    return ApplianceScreen(
      topBar: ApplianceAppBar(title: w.time, actions: [commandKey]),
      body: dataBody(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            AppliancePanel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 13,
                children: [
                  Wrap(
                    spacing: 14,
                    runSpacing: 8,
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _Reading(
                        label: w.weekTotal,
                        value: w.duration(c.totalMinutes(week)),
                      ),
                      ApplianceButton.filled(
                        w.addEntry,
                        icon: const Icon(LucideIcons.plus, size: 16),
                        onPressed: addTime,
                      ),
                    ],
                  ),
                  // An empty week is the chart's idle window, which says so:
                  // seven zero readings drew full bars on a scale from -1h.
                  ApplianceBarChart(
                    labels: [for (final day in days) w.weekdayShort(day)],
                    series: [
                      ApplianceChartSeries(w.logged, [
                        if (entries.isNotEmpty)
                          for (final n in c.dailyMinutes(week)) n / 60,
                      ]),
                    ],
                    emptyLabel: w.noEntries,
                    semanticLabel: w.logged,
                    valueText: (v) => w.duration((v * 60).round()),
                    // The window grows with the reader's text, so the empty
                    // week's words fit at 200%.
                    height:
                        154 +
                        24 *
                            (MediaQuery.textScalerOf(context).scale(1) - 1)
                                .clamp(0.0, 1.0),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    spacing: 8,
                    children: [
                      weekButton(
                        LucideIcons.chevronLeftDir,
                        w.previousWeek,
                        -1,
                      ),
                      Flexible(
                        child: Text(
                          w.weekRange(week, compact: true),
                          style: theme.textTheme.label,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      weekButton(LucideIcons.chevronRightDir, w.nextWeek, 1),
                    ],
                  ),
                ],
              ),
            ),
            for (final day in days.reversed)
              if (entries.any((e) => e.date == day))
                ApplianceListGroup(
                  header: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
                  children: [
                    for (final e in entries.where((e) => e.date == day))
                      ApplianceListTile(
                        title: w.text(e.note),
                        subtitle:
                            '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                        trailingText: w.duration(e.end - e.start),
                      ),
                  ],
                ),
          ],
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await _raise<bool>(
      context: context,
      title: w.addEntry,
      cancel: w.cancel,
      builder: (_) => _EntryForm(c),
    );
    if (saved == true && mounted) showApplianceToast(context, w.entrySaved);
  }

  Widget settings() {
    final p = c.settings;
    return ApplianceScreen(
      topBar: ApplianceAppBar(title: w.settings, actions: [commandKey]),
      // The settings' measure on the page's start line, under the title, as
      // Today's, Tasks' and Time's content (centred, it began at 500).
      body: Align(
        alignment: AlignmentDirectional.topStart,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 15,
            children: [
              ApplianceListGroup(
                header: w.account,
                children: [
                  ApplianceListTile(
                    leading: ApplianceAvatar(name: c.personName('maya')),
                    title: c.personName('maya'),
                    subtitle: w.teamName,
                  ),
                  // Signing out is the account's act, so it stands with the
                  // account, not under About.
                  ApplianceListTile(
                    title: w.signOut,
                    leading: const Icon(LucideIcons.logOutDir),
                    isDestructiveAction: true,
                    // It asks first; it opens no page.
                    showChevron: false,
                    onTap: () async {
                      final yes = await showApplianceDialog<bool>(
                        context: context,
                        builder: (ctx) => ApplianceDialog(
                          title: w.signOut,
                          content: Text(w.signOutMessage),
                          actions: [
                            ApplianceButton(
                              w.cancel,
                              onPressed: () => Navigator.pop(ctx, false),
                            ),
                            ApplianceButton(
                              w.signOut,
                              isDestructiveAction: true,
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
              AppliancePanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    if (MediaQuery.sizeOf(context).width < 600 &&
                        MediaQuery.textScalerOf(context).scale(1) > 1.4)
                      ApplianceSelect(
                        labelText: w.appearance,
                        value: p.appearance,
                        items: [
                          for (final a in Appearance.values)
                            ApplianceSelectItem(
                              value: a,
                              label: w.appearanceName(a),
                            ),
                        ],
                        onChanged: (v) => p.update(() => p.appearance = v),
                      )
                    else ...[
                      ApplianceFieldLabel(w.appearance),
                      ApplianceSegmentedButton(
                        value: p.appearance,
                        semanticLabel: w.appearance,
                        segments: [
                          for (final a in Appearance.values)
                            ApplianceSegment(
                              value: a,
                              label: w.appearanceName(a),
                            ),
                        ],
                        onChanged: (v) => p.update(() => p.appearance = v),
                      ),
                    ],
                    ApplianceSelect<double>(
                      labelText: w.textSize,
                      value: p.scale ?? 0,
                      items: [
                        ApplianceSelectItem(value: 0, label: w.system),
                        for (final n in [1.0, 1.5, 2.0])
                          ApplianceSelectItem(value: n, label: w.percent(n)),
                      ],
                      onChanged: (v) =>
                          p.update(() => p.scale = v == 0 ? null : v),
                    ),
                    ApplianceSelect(
                      labelText: w.languageLabel,
                      value: p.language,
                      items: [
                        for (final l in StintLanguage.values)
                          ApplianceSelectItem(value: l, label: l.nativeName),
                      ],
                      onChanged: (v) => p.update(() => p.language = v),
                    ),
                    ApplianceFieldLabel(w.density),
                    ApplianceSegmentedButton(
                      semanticLabel: w.density,
                      value: p.compact,
                      segments: [
                        ApplianceSegment(value: false, label: w.standard),
                        ApplianceSegment(value: true, label: w.compact),
                      ],
                      onChanged: (v) => p.update(() => p.compact = v),
                    ),
                  ],
                ),
              ),
              ApplianceListGroup(
                header: w.about,
                children: [ApplianceListTile(title: w.aboutDetail)],
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
        spacing: 12,
        children: [
          ApplianceDatePicker(
            labelText: w.date,
            value: d.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (v) => d.update(() => d.date = calendarDay(v)),
          ),
          ApplianceField(
            errorText: errors['end'],
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _TimeWell(
                  label: w.start,
                  minute: d.start,
                  onChanged: (v) => d.update(() => d.start = v),
                ),
                _TimeWell(
                  label: w.end,
                  minute: d.end,
                  onChanged: (v) => d.update(() => d.end = v),
                ),
              ],
            ),
          ),
          ApplianceSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final project in projects)
                ApplianceSelectItem(
                  value: project.id,
                  label: w.text(project.name),
                ),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          ApplianceTextField(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            minLines: 2,
            maxLines: 5,
            onChanged: (v) => d.update(() => d.note = v),
          ),
          ApplianceButton.filled(
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
