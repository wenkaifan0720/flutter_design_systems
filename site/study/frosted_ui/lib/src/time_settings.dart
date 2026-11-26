part of '../stint_frosted.dart';

extension _Timesheet on _WorkspaceState {
  Widget weekHeader() {
    final range = w.weekRange(c.week),
        compact = w.weekRange(c.week, compact: true);
    Widget arrow(bool previous) => SizedBox.square(
      dimension: 48,
      child: _IconAct(
        size: FrostedIconButtonSize.large,
        icon: previous
            ? LucideIcons.chevronLeftDir
            : LucideIcons.chevronRightDir,
        label: previous ? w.previousWeek : w.nextWeek,
        act: () => c.shiftWeek(previous ? -1 : 1),
      ),
    );
    return Row(
      spacing: 4,
      children: [
        arrow(true),
        Expanded(
          child: Semantics(
            label: range,
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (ctx, b) {
                  final style = glass.textTheme.titleLarge;
                  final measured = TextPainter.computeWidth(
                    text: TextSpan(text: range, style: style),
                    textDirection: Directionality.of(ctx),
                    textScaler: MediaQuery.textScalerOf(ctx),
                  );
                  return Text(
                    measured <= b.maxWidth
                        ? range
                        : compact.replaceFirst(' – ', ' –\n'),
                    textAlign: TextAlign.center,
                    style: style,
                  );
                },
              ),
            ),
          ),
        ),
        arrow(false),
      ],
    );
  }

  Widget time() {
    final days = List.generate(7, (i) => addDays(c.week, i)),
        daily = c.dailyMinutes(c.week),
        rows = c.entriesFor(c.week),
        total = c.totalMinutes(c.week);
    final report = FrostedCard.hero(
      hue: glass.hue(1),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          weekHeader(),
          Text(
            w.weekTotal,
            style: glass.textTheme.labelMedium,
            textAlign: TextAlign.start,
          ),
          hours(total),
          LayoutBuilder(
            builder: (ctx, b) {
              final short =
                  b.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 290;
              final maximum = daily.fold<int>(0, (a, b) => a > b ? a : b);
              final ceiling = (maximum == 0 ? 1 : (maximum / 60).ceil()) * 60;
              return Semantics(
                label: [
                  w.logged,
                  for (final (i, d) in days.indexed)
                    '${w.weekday(d)} ${w.duration(daily[i])}',
                ].join(', '),
                // One instrument for the week in every language and size: the
                // package chart paints no Arabic and crowds at large text, so
                // those had the meters and the rest a gridded chart (three
                // drawings of one week with Today's).
                child: ExcludeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 5,
                    children: [
                      Text(
                        w.duration(ceiling),
                        style: glass.textTheme.labelMedium,
                        textAlign: TextAlign.end,
                      ),
                      const _Hairline(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          for (final (i, day) in days.indexed)
                            Expanded(
                              child: Column(
                                spacing: 7,
                                children: [
                                  Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: RotatedBox(
                                      quarterTurns: 3,
                                      child: SizedBox(
                                        width: 100,
                                        height: 14,
                                        child: FittedBox(
                                          fit: BoxFit.fill,
                                          child: SizedBox(
                                            width: 100,
                                            child: FrostedMeter(
                                              daily[i] / ceiling,
                                              hue: glass.hue(1),
                                              label: w.duration(daily[i]),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    short
                                        ? w.weekdayShort(day).substring(0, 1)
                                        : w.weekdayShort(day),
                                    style: glass.textTheme.labelMedium,
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          FrostedButton(
            w.addEntry,
            icon: LucideIcons.plus,
            onPressed: addTime,
            expand: true,
          ),
        ],
      ),
    );
    final records = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        // FrostedEmptyState is a glass face of its own: one face, not one
        // set in a card.
        if (rows.isEmpty)
          FrostedEmptyState(title: w.noEntries)
        else
          for (final d in days.reversed)
            if (rows.any((e) => e.date == d))
              FrostedCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 10,
                  children: [
                    Text(
                      '${w.weekday(d)}${w.dot}${w.shortDate(d)}',
                      style: glass.textTheme.titleSmall,
                    ),
                    for (final e in rows.where((e) => e.date == d))
                      _RecordRow(
                        leading: projectMark(e.project),
                        title: w.text(e.note),
                        meta:
                            '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                        end: w.duration(e.end - e.start),
                      ),
                  ],
                ),
              ),
      ],
    );
    return page(
      w.time,
      data(
        () => LayoutBuilder(
          builder: (_, b) => b.maxWidth >= 740
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    Expanded(flex: 5, child: report),
                    Expanded(flex: 6, child: records),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [report, records],
                ),
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await FrostedSheet.show<bool>(
      context,
      title: w.addEntry,
      builder: (_) => [_Entry(c)],
    );
    if (mounted && saved == true) FrostedToast.show(context, w.entrySaved);
  }

  Future<void> signOut() async {
    final result = await FrostedDialog.show(
      context,
      title: w.signOutMessage,
      confirmLabel: w.signOut,
      cancelLabel: w.cancel,
      isDestructiveAction: true,
    );
    if (mounted && result == true) c.signIn(false);
  }

  Widget settings() {
    final s = c.settings;
    final preferences = FrostedCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          FrostedCardHeader(w.preferences),
          FrostedSelect(
            labelText: w.appearance,
            value: s.appearance,
            options: [
              for (final a in Appearance.values)
                FrostedSelectOption(a, w.appearanceName(a)),
            ],
            onChanged: (a) => s.update(() => s.appearance = a),
          ),
          FrostedSelect<double>(
            labelText: w.textSize,
            value: s.scale ?? 0,
            options: [
              FrostedSelectOption(0, w.system),
              for (final n in [1.0, 1.5, 2.0])
                FrostedSelectOption(n, w.percent(n)),
            ],
            onChanged: (n) => s.update(() => s.scale = n == 0 ? null : n),
          ),
          FrostedSelect(
            labelText: w.languageLabel,
            value: s.language,
            options: [
              for (final l in StintLanguage.values)
                FrostedSelectOption(l, l.nativeName),
            ],
            onChanged: (v) => s.update(() => s.language = v),
          ),
          FrostedSelect(
            labelText: w.density,
            value: widget.density,
            options: [
              FrostedSelectOption(FrostedDensity.standard, w.standard),
              FrostedSelectOption(
                FrostedDensity.comfortable,
                w.comfortable,
              ),
              FrostedSelectOption(FrostedDensity.compact, w.compact),
            ],
            onChanged: widget.chooseDensity,
          ),
        ],
      ),
    );
    final account = FrostedCard.record(
      hue: glass.hue(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          FrostedCardHeader(w.account),
          FrostedListTile(
            leading: FrostedAvatar(
              w.mayaInitials,
              name: c.personName('maya'),
            ),
            title: c.personName('maya'),
            meta: w.teamName,
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: FrostedButton.glass(
              w.signOut,
              icon: LucideIcons.logOutDir,
              onPressed: signOut,
            ),
          ),
        ],
      ),
    );
    final about = FrostedSettingsGroup(
      title: w.about,
      children: [Text(w.aboutDetail, style: glass.textTheme.bodyMedium)],
    );
    return page(
      w.settings,
      LayoutBuilder(
        builder: (_, b) => b.maxWidth >= 750
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  Expanded(flex: 6, child: preferences),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: [account, about],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [account, preferences, about],
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
      final w = widget.c.words,
          errors = draft.submitted ? draft.errors(w) : const <String, String>{};
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          FrostedSettingsGroup(
            children: [
              FrostedValueRow(
                title: w.date,
                value: w.shortDate(draft.date),
                onPressed: () async {
                  final day = await _datePicker(ctx, w.date, draft.date);
                  if (mounted && day != null) {
                    draft.update(() => draft.date = calendarDay(day));
                  }
                },
              ),
              _TimeRow(
                label: w.start,
                minute: draft.start,
                words: w,
                changed: (v) => draft.update(() => draft.start = v),
              ),
              FrostedFormField(
                errorText: errors['end'],
                mergeSemantics: false,
                child: _TimeRow(
                  label: w.end,
                  minute: draft.end,
                  words: w,
                  changed: (v) => draft.update(() => draft.end = v),
                ),
              ),
            ],
          ),
          FrostedSelect(
            labelText: w.project,
            value: draft.project,
            errorText: errors['project'],
            options: [
              for (final p in projects)
                FrostedSelectOption(p.id, w.text(p.name)),
            ],
            onChanged: (v) => draft.update(() => draft.project = v),
          ),
          Semantics(
            container: true,
            child: FrostedTextArea(
              labelText: w.note,
              hintText: w.noteHint,
              errorText: errors['note'],
              minLines: 2,
              maxLines: 5,
              onChanged: (v) => draft.update(() => draft.note = v),
            ),
          ),
          FrostedButton(
            w.addEntry,
            expand: true,
            onPressed: () {
              if (widget.c.addEntry(draft)) Navigator.pop(ctx, true);
            },
          ),
        ],
      );
    },
  );
}
