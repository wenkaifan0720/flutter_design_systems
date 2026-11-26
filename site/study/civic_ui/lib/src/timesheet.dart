part of '../stint_civic.dart';

extension _HoursAndSettings on _ServiceState {
  Widget timePage() {
    final start = c.week, entries = c.entriesFor(start);
    final days = <DateTime, List<TimeEntry>>{};
    for (final entry in entries) {
      (days[entry.date] ??= []).add(entry);
    }
    return CivicPageBody(
      title: w.time,
      children: [
        load(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              LayoutBuilder(
                builder: (ctx, box) {
                  final visible = w
                      .weekRange(start, compact: box.maxWidth < 530)
                      .split(' – ')
                      .map((date) => date.replaceAll(' ', '\u00a0'))
                      .join(' – ');
                  return Row(
                    children: [
                      icon(
                        w.arabic
                            ? LucideIcons.chevronRight
                            : LucideIcons.chevronLeft,
                        w.previousWeek,
                        () => c.shiftWeek(-1),
                      ),
                      Expanded(
                        child: Text(
                          visible,
                          semanticsLabel: w.weekRange(start),
                          textAlign: TextAlign.center,
                          style: ctx.civicText.headingM,
                        ),
                      ),
                      icon(
                        w.arabic
                            ? LucideIcons.chevronLeft
                            : LucideIcons.chevronRight,
                        w.nextWeek,
                        () => c.shiftWeek(1),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              CivicSummaryCard(
                title: w.weekTotal,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      w.duration(c.totalMinutes(start)),
                      style: context.civicText.headingL,
                    ),
                    const SizedBox(height: 16),
                    chart(start),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CivicButton(
                  icon: LucideIcons.plus,
                  onPressed: newEntry,
                  child: Text(w.addEntry),
                ),
              ),
              const SizedBox(height: 32),
              CivicSectionHeader(title: w.entries),
              if (entries.isEmpty) CivicEmptyState(title: w.noEntries),
              for (final day in days.entries) ...[
                Text(
                  '${w.weekday(day.key)}${w.dot}${w.shortDate(day.key)}',
                  style: context.civicText.label,
                ),
                const SizedBox(height: 8),
                CivicListGroup(
                  children: [
                    for (final e in day.value)
                      CivicListRow(
                        title: Text(w.text(e.note)),
                        subtitle: Text(
                          '${c.projectName(e.project)}${w.dot}${w.clock(e.start)}–${w.clock(e.end)}',
                        ),
                        trailing: Text(w.duration(e.end - e.start)),
                        showChevron: false,
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<void> newEntry() async {
    if (!c.signedIn) return;
    final saved = await Navigator.of(context, rootNavigator: true).push(
      CivicSheetPage<bool>(child: _EntryPage(controller: c))
          .createRoute(context),
    );
    if (saved == true && mounted) CivicToast.show(context, w.entrySaved);
  }

  Widget settingsPage() {
    final p = c.settings;
    return CivicPageBody(
      title: w.settings,
      children: [
        CivicSectionHeader(title: w.preferences),
        CivicRadioGroup<Appearance>(
          labelText: w.appearance,
          groupValue: p.appearance,
          onChanged: (v) {
            if (v != null) p.update(() => p.appearance = v);
          },
          children: [
            for (final a in Appearance.values)
              CivicRadio(value: a, labelText: w.appearanceName(a)),
          ],
        ),
        const SizedBox(height: 24),
        CivicSelect<double>(
          labelText: w.textSize,
          value: p.scale ?? 0,
          items: [
            CivicSelectItem(value: 0, label: w.system),
            for (final s in {1.0, 1.5, 2.0, ?p.scale}.toList()..sort())
              CivicSelectItem(value: s, label: w.percent(s)),
          ],
          onChanged: (s) => p.update(() => p.scale = s == 0 ? null : s),
        ),
        const SizedBox(height: 24),
        CivicRadioGroup<StintLanguage>(
          labelText: w.languageLabel,
          groupValue: p.language,
          onChanged: (v) {
            if (v != null) p.update(() => p.language = v);
          },
          children: [
            for (final l in StintLanguage.values)
              CivicRadio(value: l, labelText: l.nativeName),
          ],
        ),
        const SizedBox(height: 32),
        CivicSummaryCard(
          title: w.about,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(w.aboutDetail),
              CivicSummaryList(
                rows: [
                  CivicSummaryRow(
                    label: w.account,
                    value: Text(c.personName(team.first.id)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: CivicLink(onPressed: signOut, child: Text(w.signOut)),
        ),
      ],
    );
  }

  Future<void> signOut() async {
    final yes = await showCivicDialog<bool>(
      context: context,
      builder: (ctx) => CivicDialog(
        title: w.signOut,
        content: Text(w.signOutMessage),
        actions: [
          CivicButton(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(w.signOut),
          ),
          CivicLink(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(w.cancel),
          ),
        ],
      ),
    );
    if (yes == true && mounted) c.signIn(false);
  }
}

class _EntryPage extends StatefulWidget {
  const _EntryPage({required this.controller});
  final StintController controller;
  @override
  State<_EntryPage> createState() => _EntryPageState();
}

class _EntryPageState extends State<_EntryPage> {
  late final entry = EntryDraft(
    widget.controller.week == mondayOf(studyToday)
        ? studyToday
        : widget.controller.week,
  );
  final anchors = {
    for (final label in ['date', 'end', 'project', 'note']) label: GlobalKey(),
  };
  final noteFocus = FocusNode();
  bool incomplete = false;
  @override
  void dispose() {
    entry.dispose();
    noteFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: entry,
    builder: (ctx, _) {
      final c = widget.controller, w = c.words;
      final errors = {
        if (entry.submitted) ...entry.errors(w),
        if (entry.submitted && incomplete) 'date': w.dateError,
      };
      return CivicScaffold(
        // The service's header, and the question page's back link above
        // the question (a back arrow beside the service's name read as
        // "Back to Stint"), as the task form has it.
        topBar: const CivicTopBar(
          title: 'Stint',
          emblem: Icon(LucideIcons.clipboardList),
        ),
        body: CivicPageBody(
          backLink: CivicBackLink(
            label: w.back,
            onPressed: () => Navigator.pop(ctx),
          ),
          title: w.addEntry,
          errorSummary: errors.isEmpty
              ? null
              : CivicErrorSummary(
                  title: _problem(w),
                  errors: [
                    for (final e in errors.entries)
                      CivicErrorSummaryItem(
                        text: e.value,
                        onPressed: () {
                          final target = anchors[e.key]?.currentContext;
                          if (target != null) {
                            Scrollable.ensureVisible(target, alignment: .25);
                          }
                          if (e.key == 'note') noteFocus.requestFocus();
                        },
                      ),
                  ],
                ),
          action: CivicButton(
            onPressed: () {
              if (incomplete) {
                entry.validate(w);
                return;
              }
              if (c.addEntry(entry)) Navigator.pop(ctx, true);
            },
            child: Text(w.addEntry),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: [
                _DateAnswer(
                  key: anchors['date'],
                  label: w.date,
                  words: w,
                  date: entry.date,
                  incomplete: incomplete,
                  error: errors['date'],
                  change: (v) => entry.update(() {
                    incomplete = v == null;
                    if (v != null) entry.date = v;
                  }),
                ),
                _TimeAnswer(
                  label: w.start,
                  minute: entry.start,
                  change: (v) => entry.update(() => entry.start = v),
                ),
                _TimeAnswer(
                  key: anchors['end'],
                  label: w.end,
                  minute: entry.end,
                  error: errors['end'],
                  change: (v) => entry.update(() => entry.end = v),
                ),
                CivicSelect(
                  key: anchors['project'],
                  labelText: w.project,
                  value: entry.project,
                  errorText: errors['project'],
                  items: [
                    for (final p in projects)
                      CivicSelectItem(value: p.id, label: w.text(p.name)),
                  ],
                  onChanged: (v) => entry.update(() => entry.project = v),
                ),
                CivicTextField(
                  key: anchors['note'],
                  labelText: w.note,
                  focusNode: noteFocus,
                  hintText: w.noteHint,
                  errorText: errors['note'],
                  minLines: 2,
                  maxLines: 5,
                  onChanged: (v) => entry.update(() => entry.note = v),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
