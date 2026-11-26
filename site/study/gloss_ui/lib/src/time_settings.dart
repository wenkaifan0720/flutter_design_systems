part of '../stint_gloss.dart';

extension _TimeAndSettings on _WorkspaceState {
  Widget time() {
    final week = c.week;
    final days = List.generate(7, (i) => addDays(week, i));
    final entries = c.entriesFor(week);
    final range = w.weekRange(week);
    final summary = GlossCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          Row(
            spacing: 8,
            children: [
              GlossIconButton(
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
              GlossIconButton(
                tooltip: w.nextWeek,
                icon: const Icon(LucideIcons.chevronRightDir),
                onPressed: () => c.shiftWeek(1),
              ),
            ],
          ),
          const GlossEngravedLine(),
          Text(w.weekTotal, style: theme.textTheme.label),
          Text(
            w.duration(c.totalMinutes(week)),
            style: theme.textTheme.display.copyWith(
              color: theme.colors.jadeInk,
            ),
          ),
          // An empty week has nothing to chart: Gloss's axis would count
          // 0 to 1 in tenths with no unit. The empty state says so instead.
          if (entries.isNotEmpty) weekChart(week),
          GlossButton.filled(
            w.addEntry,
            icon: const Icon(LucideIcons.plus, size: 16),
            onPressed: addTime,
          ),
        ],
      ),
    );
    final ledger = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: [
        if (entries.isEmpty)
          GlossStateView(
            state: GlossState.empty,
            title: w.noEntries,
            icon: const Icon(LucideIcons.clock),
          ),
        for (final day in days.reversed)
          if (entries.any((e) => e.date == day))
            GlossWell(
              header: '${w.weekday(day)}${w.dot}${w.shortDate(day)}',
              dividerIndent: 0,
              children: [
                for (final e in entries.where((e) => e.date == day))
                  GlossListTile(
                    title: w.text(e.note),
                    subtitle:
                        '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                    trailingText: w.duration(e.end - e.start),
                  ),
              ],
            ),
      ],
    );
    return GlossScreen(
      topBar: GlossTopBar(title: w.time, actions: [command]),
      // On a desk, Today's margins: the page starts on the strip title's
      // line (the screen's own column began 28 px past it).
      fullBleed: _desk,
      body: _underStrip(
        dataBody(
          () => LayoutBuilder(
            builder: (_, box) => box.maxWidth >= 760
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: [
                      Expanded(flex: 2, child: summary),
                      Expanded(flex: 3, child: ledger),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 18,
                    children: [summary, ledger],
                  ),
          ),
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
    if (saved == true && mounted) showGlossToast(context, w.entrySaved);
  }

  Future<void> signOut() async {
    final yes = await showGlossDialog<bool>(
      context: context,
      builder: (ctx) => GlossDialog(
        title: w.signOutMessage,
        actions: [
          GlossDialogAction(
            label: w.cancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          GlossDialogAction(
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: child,
    );
    final account = GlossWell(
      header: w.account,
      children: [
        GlossListTile(
          leading: GlossAvatar(name: c.personName('maya'), size: 32),
          title: c.personName('maya'),
          subtitle: w.teamName,
        ),
        GlossListTile(
          leading: const Icon(LucideIcons.logOutDir),
          title: w.signOut,
          isDestructiveAction: true,
          // It asks first; it opens no page.
          showChevron: false,
          onTap: signOut,
        ),
      ],
    );
    final prefs = GlossWell(
      header: w.preferences,
      dividerIndent: 0,
      children: [
        field(
          GlossSelect(
            labelText: w.appearance,
            value: p.appearance,
            items: [
              for (final a in Appearance.values)
                GlossSelectItem(value: a, label: w.appearanceName(a)),
            ],
            onChanged: (v) => p.update(() => p.appearance = v),
          ),
        ),
        field(
          GlossSelect<double>(
            labelText: w.textSize,
            value: p.scale ?? 0,
            items: [
              GlossSelectItem(value: 0, label: w.system),
              for (final n in [1.0, 1.5, 2.0])
                GlossSelectItem(value: n, label: w.percent(n)),
            ],
            onChanged: (v) => p.update(() => p.scale = v == 0 ? null : v),
          ),
        ),
        field(
          GlossSelect(
            labelText: w.languageLabel,
            value: p.language,
            items: [
              for (final l in StintLanguage.values)
                GlossSelectItem(value: l, label: l.nativeName),
            ],
            onChanged: (v) => p.update(() => p.language = v),
          ),
        ),
        field(
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 5,
            children: [
              GlossFieldLabel(w.density),
              GlossSegmentedButton(
                selected: p.compact,
                expanded: true,
                semanticLabel: w.density,
                segments: [
                  GlossSegment(value: false, label: w.standard),
                  GlossSegment(value: true, label: w.compact),
                ],
                onChanged: (v) => p.update(() => p.compact = v),
              ),
            ],
          ),
        ),
      ],
    );
    final about = GlossWell(
      header: w.about,
      children: [
        GlossListTile(
          title: w.aboutDetail,
          leading: const Icon(LucideIcons.info),
        ),
      ],
    );
    return GlossScreen(
      topBar: GlossTopBar(title: w.settings, actions: [command]),
      fullBleed: _desk,
      body: _underStrip(
        LayoutBuilder(
          builder: (_, box) => box.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 18,
                        children: [account, about],
                      ),
                    ),
                    Expanded(flex: 3, child: prefs),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 18,
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          GlossDatePicker(
            labelText: w.date,
            value: d.date,
            firstDate: DateTime(2020),
            lastDate: DateTime(2040, 12, 31),
            currentDate: studyToday,
            onChanged: (v) => d.update(() => d.date = calendarDay(v)),
          ),
          GlossWell(
            dividerIndent: 0,
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
            GlossFieldMessage(errorText: error),
          GlossSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                GlossSelectItem(value: p.id, label: w.text(p.name)),
            ],
            onChanged: (v) => d.update(() => d.project = v),
          ),
          GlossTextArea(
            labelText: w.note,
            hintText: w.noteHint,
            errorText: errors['note'],
            minLines: 2,
            maxLines: 5,
            onChanged: (v) => d.update(() => d.note = v),
          ),
          GlossButton.filled(
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
