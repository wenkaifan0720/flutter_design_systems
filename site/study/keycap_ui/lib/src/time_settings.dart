part of '../stint_keycap.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week;
    final days = List.generate(7, (i) => addDays(week, i));
    final entries = c.entriesFor(week);
    final range = w.weekRange(week);
    // The week's summary is printed on the case, its chart in a well cut
    // into it: no card round the lot.
    final summary = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KeycapSpacing.medium,
      children: [
        Row(
          spacing: KeycapSpacing.small,
          children: [
            glyphKey(
              LucideIcons.chevronLeftDir,
              w.previousWeek,
              () => c.shiftWeek(-1),
            ),
            Expanded(
              child: Semantics(
                label: range,
                child: ExcludeSemantics(
                  child: LayoutBuilder(
                    builder: (ctx, box) {
                      final style = theme.textTheme.label;
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
            glyphKey(
              LucideIcons.chevronRightDir,
              w.nextWeek,
              () => c.shiftWeek(1),
            ),
          ],
        ),
        const KeycapDivider(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: KeycapSpacing.tight,
          children: [
            Text(w.weekTotal.toUpperCase(), style: theme.textTheme.legend),
            Text(
              w.duration(c.totalMinutes(week)),
              style: theme.textTheme.display.copyWith(
                color: theme.colors.accentInk,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        // An empty week has nothing to chart; the empty state beside it
        // says so instead.
        if (entries.isNotEmpty) weekChart(week),
        KeycapButton.accent(
          icon: const Icon(LucideIcons.plus),
          onPressed: addTime,
          child: Text(w.addEntry),
        ),
      ],
    );
    final ledger = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: KeycapSpacing.large,
      children: [
        if (entries.isEmpty)
          KeycapEmptyState(icon: LucideIcons.clock, title: w.noEntries),
        for (final day in days.reversed)
          if (entries.any((e) => e.date == day))
            KeycapListGroup(
              header: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
              children: [
                for (final e in entries.where((e) => e.date == day))
                  KeycapListTile(
                    leading: _Lead(child: _ProjectCap(project: e.project)),
                    title: w.text(e.note),
                    subtitle:
                        '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                    maxSubtitleLines: 2,
                    trailingText: w.duration(e.end - e.start),
                  ),
              ],
            ),
      ],
    );
    return KeycapScreen(
      topBar: KeycapAppBar(title: w.time, actions: [command]),
      maxWidth: _measure,
      body: dataBody(
        () => LayoutBuilder(
          builder: (_, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: KeycapSpacing.extraLarge,
                  children: [
                    Expanded(flex: 2, child: summary),
                    Expanded(flex: 3, child: ledger),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: KeycapSpacing.large,
                  children: [summary, ledger],
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
    // The chart grows taller only to keep its plot as the labels grow.
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    return Semantics(
      label: w.logged,
      value: values.join(w.listSeparator),
      child: ExcludeSemantics(
        child: KeycapBarChart(
          labels: [for (final day in days) w.weekdayShort(day)],
          series: [
            KeycapChartSeries(w.logged, [for (final m in minutes) m / 60]),
          ],
          valueText: (hours) => w.duration((hours * 60).round()),
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
    if (saved == true && mounted) showKeycapToast(context, w.entrySaved);
  }

  Future<void> signOut() async {
    final yes = await showKeycapDialog<bool>(
      context: context,
      builder: (ctx) => KeycapDialog(
        title: w.signOutMessage,
        actions: [
          KeycapButton.text(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(w.cancel),
          ),
          KeycapButton.accent(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(w.signOut),
          ),
        ],
      ),
    );
    if (yes == true && mounted) c.signIn(false);
  }

  /// A preference row: the value on the small cap at its end; pressed, the
  /// choices as radio keys in a sheet (a dialog from 600), committed with
  /// Apply.
  Widget _choice<T>({
    required String label,
    required T value,
    required List<T> options,
    required String Function(T) labelOf,
    required ValueChanged<T> onChanged,
  }) => KeycapListTile(
    title: label,
    value: labelOf(value),
    onTap: () async {
      final chosen = await _raise<T>(
        context: context,
        cancel: w.cancel,
        title: label,
        builder: (_) => _Pick<T>(
          label: label,
          apply: w.apply,
          options: options,
          labelOf: labelOf,
          initial: value,
        ),
      );
      if (chosen != null && mounted) onChanged(chosen);
    },
  );

  Widget settings() {
    final p = c.settings;
    final account = KeycapListGroup(
      header: w.account,
      children: [
        KeycapListTile(
          leading: ExcludeSemantics(
            child: KeycapAvatar(
              name: c.personName('maya'),
              slotId: 'maya',
              size: 36,
            ),
          ),
          title: c.personName('maya'),
          subtitle: w.teamName,
        ),
        KeycapListTile(
          leading: const Icon(LucideIcons.logOutDir),
          title: w.signOut,
          isDestructiveAction: true,
          // It asks first; it opens no page.
          showChevron: false,
          onTap: signOut,
        ),
      ],
    );
    final prefs = KeycapListGroup(
      header: w.preferences,
      children: [
        _choice<Appearance>(
          label: w.appearance,
          value: p.appearance,
          options: Appearance.values,
          labelOf: w.appearanceName,
          onChanged: (v) => p.update(() => p.appearance = v),
        ),
        _choice<double>(
          label: w.textSize,
          value: p.scale ?? 0,
          options: const [0, 1, 1.5, 2],
          labelOf: (n) => n == 0 ? w.system : w.percent(n),
          onChanged: (v) => p.update(() => p.scale = v == 0 ? null : v),
        ),
        _choice<StintLanguage>(
          label: w.languageLabel,
          value: p.language,
          options: StintLanguage.values,
          labelOf: (l) => l.nativeName,
          onChanged: (v) => p.update(() => p.language = v),
        ),
        _choice<bool>(
          label: w.density,
          value: p.compact,
          options: const [false, true],
          labelOf: (compact) => compact ? w.compact : w.standard,
          onChanged: (v) => p.update(() => p.compact = v),
        ),
      ],
    );
    final shortcuts = KeycapListGroup(
      header: w.commands,
      children: [
        KeycapListTile(
          title: w.findCommand,
          trailing: KeycapShortcut(
            keys: [modifier == '⌘' ? 'Cmd' : 'Ctrl', 'K'],
            semanticLabel: modifier == '⌘' ? 'Command K' : 'Control K',
          ),
        ),
        KeycapListTile(
          title: w.save,
          trailing: KeycapShortcut(
            keys: [modifier == '⌘' ? 'Cmd' : 'Ctrl', 'S'],
            semanticLabel: modifier == '⌘' ? 'Command S' : 'Control S',
          ),
        ),
      ],
    );
    final about = KeycapListGroup(
      header: w.about,
      children: [
        KeycapListTile(
          title: w.aboutDetail,
          maxTitleLines: 3,
          leading: const Icon(LucideIcons.info),
        ),
      ],
    );
    return KeycapScreen(
      topBar: KeycapAppBar(title: w.settings, actions: [command]),
      maxWidth: _measure,
      body: LayoutBuilder(
        builder: (_, box) => box.maxWidth >= 760
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KeycapSpacing.extraLarge,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: KeycapSpacing.large,
                      children: [account, about],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: KeycapSpacing.large,
                      children: [prefs, shortcuts],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: KeycapSpacing.large,
                children: [
                  account,
                  prefs,
                  // A phone has no keyboard to press them on.
                  if (MediaQuery.sizeOf(context).width >= 600) shortcuts,
                  about,
                ],
              ),
      ),
    );
  }
}

/// A preference's choices as radio keys, and Apply under them.
class _Pick<T> extends StatefulWidget {
  const _Pick({
    required this.label,
    required this.apply,
    required this.options,
    required this.labelOf,
    required this.initial,
  });
  final String label, apply;
  final List<T> options;
  final String Function(T) labelOf;
  final T initial;

  @override
  State<_Pick<T>> createState() => _PickState<T>();
}

class _PickState<T> extends State<_Pick<T>> {
  late T chosen = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: KeycapSpacing.large,
    children: [
      KeycapRadioGroup<T>(
        semanticLabel: widget.label,
        options: widget.options,
        groupValue: chosen,
        labelOf: widget.labelOf,
        onChanged: (v) => setState(() => chosen = v),
      ),
      KeycapButton.accent(
        onPressed: () => Navigator.pop(context, chosen),
        child: Text(widget.apply),
      ),
    ],
  );
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
        spacing: KeycapSpacing.regular,
        children: [
          KeycapDatePicker(
            labelText: w.date,
            value: d.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (v) => d.update(() => d.date = calendarDay(v)),
          ),
          KeycapListGroup(
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
            KeycapFieldMessage(errorText: error),
          KeycapSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                KeycapSelectItem(value: p.id, label: w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          KeycapTextField(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            minLines: 2,
            maxLines: 5,
            onChanged: (v) => d.update(() => d.note = v),
          ),
          KeycapButton.accent(
            icon: const Icon(LucideIcons.plus),
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
            child: Text(w.addEntry),
          ),
        ],
      );
    },
  );
}
