part of '../stint_terminal.dart';

extension _ConsoleTime on _ConsoleState {
  Widget workLog() {
    final days = <DateTime, List<TimeEntry>>{}, week = c.week;
    for (final e in c.entriesFor(week)) {
      (days[e.date] ??= []).add(e);
    }
    return _Page(
      children: [
        _Heading(w.time),
        LayoutBuilder(
          builder: (ctx, box) {
            final text = w
                .weekRange(week, compact: box.maxWidth < 580)
                .split(' – ')
                .map((date) => date.replaceAll(' ', '\u00a0'))
                .join(' – ');
            // The keys stand beside the week they step, on the page's start
            // line: spread to the window's edges they stood 1,160 px apart.
            return Align(
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                spacing: ctx.termGrid.cellWidth,
                children: [
                  act(
                    w.arabic ? '→' : '←',
                    w.previousWeek,
                    () => c.shiftWeek(-1),
                  ),
                  Flexible(
                    child: Text(
                      text,
                      semanticsLabel: w.weekRange(week),
                      textAlign: TextAlign.center,
                      style: ink.boldStyle,
                    ),
                  ),
                  act(w.arabic ? '←' : '→', w.nextWeek, () => c.shiftWeek(1)),
                ],
              ),
            );
          },
        ),
        content(
          () => _Tiles(
            first: TermPane(
              title: w.weekTotal,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    w.duration(c.totalMinutes(week)),
                    style: ink.displayStyle,
                  ),
                  const SizedBox(height: 8),
                  bars(week),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TermButton.filled(
                      label: w.addEntry,
                      onPressed: addEntry,
                    ),
                  ),
                ],
              ),
            ),
            second: TermPane(
              title: w.entries,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (days.isEmpty)
                    TermEmptyState(title: w.noEntries)
                  else
                    for (final day in days.entries) ...[
                      _Heading(
                        '${w.weekday(day.key)}${w.dot}${w.shortDate(day.key)}',
                      ),
                      for (final e in day.value)
                        Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: context.termGrid.cellWidth,
                            bottom: 6,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.text(e.note), style: ink.boldStyle),
                              Text(
                                '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${w.duration(e.end - e.start)}',
                                style: ink.textStyle,
                              ),
                              Text(
                                c.projectName(e.project),
                                style: ink.dimStyle,
                              ),
                            ],
                          ),
                        ),
                      const TermDivider(),
                    ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget bars(DateTime week) {
    final mins = c.dailyMinutes(week), t = ink;
    final grid = context.termGrid;
    final max = mins.fold(60, (a, b) => a > b ? a : b);
    // The figures' column is as wide as the widest figure's line, measured:
    // on the web a figure's intrinsic width runs short where its line takes
    // a fallback face (Japanese), and its end stood past the pane's rule.
    final figures =
        grid.cellWidth +
        mins.fold(
          0.0,
          (widest, m) =>
              math.max(widest, textWidth(context, w.duration(m), t.textStyle)),
        );
    return Semantics(
      image: true,
      label: chartName(week),
      excludeSemantics: true,
      child: Table(
        columnWidths: {
          0: const IntrinsicColumnWidth(),
          1: const FlexColumnWidth(),
          2: FixedColumnWidth(figures),
        },
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        children: [
          for (var i = 0; i < 7; i++)
            TableRow(
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(end: grid.cellWidth),
                  child: Text(
                    w.weekdayShort(addDays(week, i)),
                    style: t.dimStyle,
                  ),
                ),
                LayoutBuilder(
                  builder: (_, box) => Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TermProgressBar(
                      value: mins[i] / max,
                      cols: grid.colsIn(box.maxWidth),
                      showPercent: false,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: grid.cellWidth),
                  // Its column is as wide as its widest figure: a figure
                  // never breaks across lines (Arabic's did at 390).
                  // Its ink may stand past its advance (an Arabic digit's
                  // hook in the fallback face): shown, not cut.
                  child: Text(
                    w.duration(mins[i]),
                    textAlign: TextAlign.end,
                    softWrap: false,
                    overflow: TextOverflow.visible,
                    style: t.textStyle,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> addEntry() async {
    if (!c.signedIn) return;
    final saved = await _raise<bool>(
      context: context,
      semanticLabel: w.addEntry,
      builder: (ctx) => _Entry(c),
    );
    if (mounted && saved == true) {
      TermToaster.show(context, message: w.entrySaved, tone: TermTone.success);
    }
  }

  Widget configuration() {
    final p = c.settings;
    final grid = context.termGrid;
    // On the start line beside the side bar, as Today's, Tasks' and Time's
    // headings stand (centred, it floated with its title mid-page).
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: grid.cols(66)),
        child: _Page(
          children: [
            _Heading(w.settings),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: grid.cellWidth,
              children: [
                TermPane(
                  title: w.preferences,
                  child: Column(
                    spacing: 12,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TermSelect.inline(
                        labelCols: 12,
                        labelText: w.appearance,
                        value: p.appearance,
                        items: [
                          for (final a in Appearance.values)
                            TermSelectItem(
                              value: a,
                              label: w.appearanceName(a),
                            ),
                        ],
                        onChanged: (v) => p.update(() => p.appearance = v),
                      ),
                      TermSelect<double>.inline(
                        labelCols: 12,
                        labelText: w.textSize,
                        value: p.scale ?? 0,
                        items: [
                          TermSelectItem(value: 0, label: w.system),
                          for (final s in {
                            1.0,
                            1.5,
                            2.0,
                            ?p.scale,
                          }.toList()..sort())
                            TermSelectItem(value: s, label: w.percent(s)),
                        ],
                        onChanged: (v) =>
                            p.update(() => p.scale = v == 0 ? null : v),
                      ),
                      TermSelect<StintLanguage>.inline(
                        labelCols: 12,
                        labelText: w.languageLabel,
                        value: p.language,
                        items: [
                          for (final l in StintLanguage.values)
                            TermSelectItem(value: l, label: l.nativeName),
                        ],
                        onChanged: (v) => p.update(() => p.language = v),
                      ),
                      TermSelect<bool>.inline(
                        labelCols: 12,
                        labelText: w.density,
                        value: p.compact,
                        items: [
                          TermSelectItem(value: false, label: w.standard),
                          TermSelectItem(value: true, label: w.compact),
                        ],
                        onChanged: (v) => p.update(() => p.compact = v),
                      ),
                    ],
                  ),
                ),
                TermPane(
                  title: w.account,
                  child: Column(
                    spacing: 8,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.personName(team.first.id), style: ink.boldStyle),
                      Text(w.teamName, style: ink.dimStyle),
                      TermButton(
                        label: w.signOut,
                        isDestructiveAction: true,
                        onPressed: signOut,
                      ),
                    ],
                  ),
                ),
                TermPane(title: w.about, child: Text(w.aboutDetail)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> signOut() async {
    final sheet = MediaQuery.sizeOf(context).width < 600;
    Widget ownQuestion(BuildContext ctx) {
      final actions = [
        TermButton(label: w.cancel, onPressed: () => Navigator.pop(ctx, false)),
        TermButton.filled(
          label: w.signOut,
          isDestructiveAction: true,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ];
      final question = Text(w.signOutMessage);
      final footer = 'Esc${w.dot}${w.cancel}';
      return sheet
          ? TermSheet(
              title: w.signOut,
              footer: footer,
              actions: actions,
              child: question,
            )
          : TermDialog(
              title: w.signOut,
              footer: footer,
              actions: actions,
              content: question,
            );
    }

    final bool? yes;
    // The look's own confirm dialog footers in English; the other
    // languages build the same question with their own words.
    if (w.language == StintLanguage.en) {
      yes = await showTermConfirmDialog(
        context: context,
        title: w.signOut,
        message: w.signOutMessage,
        confirmLabel: w.signOut,
        cancelLabel: w.cancel,
        isDestructiveAction: true,
      );
    } else if (sheet) {
      yes = await showTermSheet<bool>(
        context: context,
        semanticLabel: w.signOut,
        isAlert: true,
        barrierDismissible: true,
        builder: ownQuestion,
      );
    } else {
      yes = await showTermDialog<bool>(
        context: context,
        semanticLabel: w.signOut,
        isAlert: true,
        barrierDismissible: true,
        builder: ownQuestion,
      );
    }
    if (yes == true && mounted) c.signIn(false);
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
  late final note = TextEditingController(text: d.note);
  // A failed submission stays in the sheet until the next submission. Moving
  // focus from an input to Add entry must not move the button under the pointer.
  Map<String, String> errors = {};
  bool missing = false;
  @override
  void dispose() {
    note.dispose();
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext ctx) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final w = widget.c.words;
      return _Panel(
        title: w.addEntry,
        footer: 'Esc${w.dot}${w.cancel}',
        actions: [
          TermButton.filled(
            label: w.addEntry,
            onPressed: () {
              if (!missing && widget.c.addEntry(d)) {
                Navigator.pop(ctx, true);
                return;
              }
              setState(
                () =>
                    errors = {...d.errors(w), if (missing) 'date': w.dateError},
              );
            },
          ),
          TermButton(label: w.cancel, onPressed: () => Navigator.pop(ctx)),
        ],
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            if (errors.isNotEmpty) _Errors(errors),
            _DateLine(
              label: w.date,
              words: w,
              value: d.date,
              missing: missing,
              error: errors['date'],
              change: (v) => d.update(() {
                missing = v == null;
                if (v != null) d.date = v;
              }),
            ),
            _ClockLine(
              label: w.start,
              words: w,
              minute: d.start,
              change: (v) => d.update(() => d.start = v),
            ),
            _ClockLine(
              label: w.end,
              words: w,
              minute: d.end,
              change: (v) => d.update(() => d.end = v),
            ),
            if (errors['end'] case final error?)
              Text(
                error,
                style: TermTheme.of(ctx).textStyle
                    .copyWith(color: TermTheme.of(ctx).danger),
              ),
            TermSelect(
              labelText: w.project,
              value: d.project,
              items: [
                for (final p in projects)
                  TermSelectItem(value: p.id, label: w.text(p.name)),
              ],
              onChanged: (v) => d.update(() => d.project = v),
            ),
            _InputValidation(
              error: errors['note'],
              child: TermTextField(
                controller: note,
                labelText: w.note,
                hintText: w.noteHint,
                lines: 2,
                errorText: errors['note'],
                onChanged: (v) => d.update(() => d.note = v),
              ),
            ),
          ],
        ),
      );
    },
  );
}
