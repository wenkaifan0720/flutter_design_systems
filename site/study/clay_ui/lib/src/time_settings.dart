part of '../stint_clay.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week;
    final days = List.generate(7, (i) => addDays(week, i));
    final entries = c.entriesFor(week);
    final range = w.weekRange(week);
    final summary = ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClaySpacing.medium,
        children: [
          Row(
            spacing: ClaySpacing.small,
            children: [
              ClayIconButton(
                tooltip: w.previousWeek,
                icon: const Icon(LucideIcons.chevronLeftDir),
                onPressed: () => c.shiftWeek(-1),
              ),
              Expanded(
                child: Semantics(
                  label: range,
                  child: ExcludeSemantics(
                    child: LayoutBuilder(
                      builder: (ctx, box) {
                        final style = theme.textTheme.label.copyWith(
                          color: theme.colors.ink,
                        );
                        final width = TextPainter.computeWidth(
                          text: TextSpan(text: range, style: style),
                          textDirection: Directionality.of(ctx),
                          textScaler: MediaQuery.textScalerOf(ctx),
                        );
                        final compact = w.weekRange(week, compact: true);
                        return Text(
                          width <= box.maxWidth
                              ? range
                              : compact.replaceFirst(' – ', ' –\n'),
                          style: style,
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                  ),
                ),
              ),
              ClayIconButton(
                tooltip: w.nextWeek,
                icon: const Icon(LucideIcons.chevronRightDir),
                onPressed: () => c.shiftWeek(1),
              ),
            ],
          ),
          const ClayGroove(),
          Text(
            w.weekTotal,
            style: theme.textTheme.label.copyWith(
              color: theme.colors.inkSecondary,
            ),
          ),
          Text(
            w.duration(c.totalMinutes(week)),
            style: theme.textTheme.display.copyWith(
              color: theme.colors.accentInk,
            ),
          ),
          // An empty week has nothing to chart; the empty state beside it
          // says so instead.
          if (entries.isNotEmpty) weekChart(week),
          ClayButton.filled(
            w.addEntry,
            icon: const Icon(LucideIcons.plus),
            onPressed: addTime,
          ),
        ],
      ),
    );
    final ledger = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: ClaySpacing.large,
      children: [
        if (entries.isEmpty)
          ClayCard(
            child: ClayStateView(
              state: ClayState.empty,
              title: w.noEntries,
              icon: LucideIcons.clock,
            ),
          ),
        for (final day in days.reversed)
          if (entries.any((e) => e.date == day))
            ClayGroup(
              header: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
              children: [
                for (final e in entries.where((e) => e.date == day))
                  ClayListTile(
                    title: w.text(e.note),
                    subtitle:
                        '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                    trailingText: w.duration(e.end - e.start),
                  ),
              ],
            ),
      ],
    );
    return ClayScreen(
      topBar: ClayTopBar(title: w.time, actions: [command]),
      fullBleed: _desk,
      body: _underBar(
        dataBody(
          () => LayoutBuilder(
            builder: (_, box) => box.maxWidth >= 760
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: ClaySpacing.large,
                    children: [
                      Expanded(flex: 2, child: summary),
                      Expanded(flex: 3, child: ledger),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: ClaySpacing.large,
                    children: [summary, ledger],
                  ),
          ),
        ),
      ),
    );
  }

  Widget weekChart(DateTime week) {
    final days = List.generate(7, (i) => addDays(week, i));
    final minutes = c.dailyMinutes(week);
    final values = [
      for (final (i, day) in days.indexed)
        '${w.weekday(day)} ${w.duration(minutes[i])}',
    ];
    // The chart's axis type follows the reader's text scale; the chart grows
    // taller only to keep its plot as the labels grow.
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Semantics(
      label: w.logged,
      value: values.join(w.listSeparator),
      child: ExcludeSemantics(
        child: ClayBarChart(
          categories: [for (final day in days) w.weekdayShort(day)],
          series: [
            ClayChartSeries(
              label: w.logged,
              points: [
                for (final (i, m) in minutes.indexed)
                  ClayChartPoint(i.toDouble(), m / 60),
              ],
            ),
          ],
          formatY: (hours) => w.duration((hours * 60).round()),
          semanticLabel: w.logged,
          height: 180.0 * scale.clamp(1.0, 1.6),
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await _raise<bool>(
      context: context,
      cancel: w.cancel,
      title: w.addEntry,
      builder: (_) => _EntrySheet(c),
    );
    if (saved == true && mounted) showClayToast(context, w.entrySaved);
  }

  Future<void> signOut() async {
    final yes = await showClayDialog<bool>(
      context: context,
      builder: (ctx) => ClayDialog(
        title: w.signOutMessage,
        actions: [
          ClayDialogAction(
            label: w.cancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          ClayDialogAction(
            label: w.signOut,
            isDefaultAction: true,
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (yes == true && mounted) c.signIn(false);
  }

  Widget settings() {
    final p = c.settings;
    Widget field(Widget child) => Padding(
      padding: const EdgeInsets.symmetric(
        vertical: ClaySpacing.medium,
        horizontal: ClaySpacing.roomy,
      ),
      child: child,
    );
    final account = ClayGroup(
      header: w.account,
      children: [
        ClayListTile(
          leading: ClayAvatar(name: c.personName('maya'), size: 36),
          title: c.personName('maya'),
          subtitle: w.teamName,
        ),
        ClayListTile(
          leading: const Icon(LucideIcons.logOutDir),
          title: w.signOut,
          isDestructiveAction: true,
          // It asks first; it opens no page.
          showChevron: false,
          onTap: signOut,
        ),
      ],
    );
    final prefs = ClayGroup(
      header: w.preferences,
      dividerIndent: ClaySpacing.roomy,
      children: [
        field(
          ClaySelect(
            labelText: w.appearance,
            value: p.appearance,
            items: [
              for (final a in Appearance.values)
                ClaySelectItem(value: a, label: w.appearanceName(a)),
            ],
            onChanged: (v) => p.update(() => p.appearance = v),
          ),
        ),
        field(
          ClaySelect<double>(
            labelText: w.textSize,
            value: p.scale ?? 0,
            items: [
              ClaySelectItem(value: 0, label: w.system),
              for (final n in [1.0, 1.5, 2.0])
                ClaySelectItem(value: n, label: w.percent(n)),
            ],
            onChanged: (v) => p.update(() => p.scale = v == 0 ? null : v),
          ),
        ),
        field(
          ClaySelect(
            labelText: w.languageLabel,
            value: p.language,
            items: [
              for (final l in StintLanguage.values)
                ClaySelectItem(value: l, label: l.nativeName),
            ],
            onChanged: (v) => p.update(() => p.language = v),
          ),
        ),
        field(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ClaySpacing.small,
            children: [
              ClayFieldLabel(w.density),
              ClaySegmentedButton(
                selected: p.compact,
                expanded: true,
                semanticLabel: w.density,
                segments: [
                  ClaySegment(value: false, label: w.standard),
                  ClaySegment(value: true, label: w.compact),
                ],
                onChanged: (v) => p.update(() => p.compact = v),
              ),
            ],
          ),
        ),
      ],
    );
    final about = ClayGroup(
      header: w.about,
      children: [
        ClayListTile(
          title: w.aboutDetail,
          leading: const Icon(LucideIcons.info),
        ),
      ],
    );
    return ClayScreen(
      topBar: ClayTopBar(title: w.settings, actions: [command]),
      fullBleed: _desk,
      body: _underBar(
        LayoutBuilder(
          builder: (_, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ClaySpacing.large,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: ClaySpacing.large,
                        children: [account, about],
                      ),
                    ),
                    Expanded(flex: 3, child: prefs),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: ClaySpacing.large,
                  children: [account, prefs, about],
                ),
        ),
      ),
    );
  }
}

class _EntrySheet extends StatefulWidget {
  const _EntrySheet(this.model);
  final StintController model;
  @override
  State<_EntrySheet> createState() => _EntrySheetState();
}

class _EntrySheetState extends State<_EntrySheet> {
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
    builder: (ctx, _) {
      final c = widget.model,
          w = c.words,
          errors = d.submitted ? d.errors(w) : const <String, String>{};
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClaySpacing.regular,
        children: [
          ClayDatePicker(
            labelText: w.date,
            value: d.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (v) => d.update(() => d.date = calendarDay(v)),
          ),
          ClayGroup(
            children: [
              _ClockRow(
                words: w,
                label: w.start,
                minute: d.start,
                onChanged: (v) => d.update(() => d.start = v),
              ),
              _ClockRow(
                words: w,
                label: w.end,
                minute: d.end,
                onChanged: (v) => d.update(() => d.end = v),
              ),
            ],
          ),
          if (errors['end'] case final error?)
            ClayFieldMessage(errorText: error),
          ClaySelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                ClaySelectItem(value: p.id, label: w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          ClayTextArea(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            minLines: 2,
            maxLines: 5,
            onChanged: (v) => d.update(() => d.note = v),
          ),
          ClayButton.filled(
            w.addEntry,
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
      );
    },
  );
}
