part of '../stint_ledger.dart';

class _Record extends StatefulWidget {
  const _Record({super.key, required this.book, required this.id});
  final _BookState book;
  final String id;
  @override
  State<_Record> createState() => _RecordState();
}

class _RecordState extends State<_Record> {
  StintController get c => widget.book.c;
  late final title = TextEditingController(
    text: c.words.text(c.draft!.task.title),
  );
  late final notes = TextEditingController(
    text: c.words.text(c.draft!.task.notes),
  );
  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (await widget.book.mayLeave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      final d = c.draft;
      if (d == null || d.task.id != widget.id) return const SizedBox.shrink();
      return ListenableBuilder(
        listenable: d,
        builder: (ctx, _) {
          final w = c.words, t = d.task, ink = ctx.ledgerTheme;
          final errors = d.submitted ? d.errors(w) : const <String, String>{};
          final largePhone =
              MediaQuery.sizeOf(ctx).width < 600 &&
              MediaQuery.textScalerOf(ctx).scale(1) > 1.4;
          final back = widget.book.action(LucideIcons.arrowLeft, w.back, close);
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: LedgerScreen.form(
              // On a desk the wide screen's room, as the empty pane and every
              // page keep (its 20 ran the rules to the window's edge and set
              // the header 24 above the list's).
              padding: LedgerLayout.isWide(ctx)
                  ? const EdgeInsetsDirectional.fromSTEB(56, 40, 56, 24)
                  : const EdgeInsetsDirectional.fromSTEB(20, 16, 20, 24),
              topBar: largePhone
                  ? LedgerTopBar.none
                  : LedgerTopBar(
                      title: w.taskDetail,
                      meta: t.id,
                      leading: back,
                    ),
              // On a desk Save keeps to its words at the start, clear of
              // the notices standing at the end.
              footer: LedgerButton.filled(
                w.save,
                expand: !LedgerLayout.isWide(ctx),
                onPressed: d.dirty ? widget.book.save : null,
              ),
              body: _FormColumn(
                children: [
                  if (largePhone) ...[
                    Row(
                      children: [
                        back,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Semantics(
                            header: true,
                            child: Text(w.taskDetail, style: ink.sheetTitle),
                          ),
                        ),
                      ],
                    ),
                    const LedgerDivider(strong: true),
                  ],
                  if (errors.isNotEmpty) _Errors(errors.values),
                  LedgerTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  LedgerTextArea(
                    labelText: w.notes,
                    controller: notes,
                    minLines: 3,
                    maxLines: 8,
                    onChanged: (v) => d.notes(v, w.language),
                  ),
                  // The short fields keep Ledger's field measure, as its
                  // stepper does: Project and Assignee are one field twice.
                  LedgerLayout.measured(
                    ctx,
                    LedgerCombobox<String>(
                      labelText: w.project,
                      options: [for (final p in projects) p.id],
                      value: t.project,
                      displayStringForOption: c.projectName,
                      requireSelection: true,
                      errorText: errors['project'],
                      onSelected: (v) => d.edit(t.copyWith(project: v)),
                    ),
                  ),
                  LedgerLayout.measured(
                    ctx,
                    LedgerCombobox<String>(
                      labelText: w.assignee,
                      hintText: w.selectPerson,
                      options: [for (final p in team) p.id],
                      value: t.assignee,
                      displayStringForOption: c.personName,
                      requireSelection: true,
                      errorText: errors['assignee'],
                      onSelected: (v) => d.edit(t.copyWith(assignee: v)),
                    ),
                  ),
                  LedgerLayout.measured(
                    ctx,
                    _DateLine(
                      words: w,
                      label: w.due,
                      date: t.due,
                      incomplete: d.dueIncomplete,
                      error: errors['due'],
                      change: d.setDue,
                    ),
                  ),
                  // Ledger's field stepper writes its own label and error.
                  LedgerStepper(
                    size: LedgerStepperSize.field,
                    labelText: w.estimate,
                    errorText: errors['estimate'],
                    value: t.estimate,
                    min: 5,
                    max: 480,
                    step: 5,
                    lowerLabel: w.adjust(w.estimate, increase: false),
                    raiseLabel: w.adjust(w.estimate, increase: true),
                    onChanged: (v) =>
                        d.edit(t.copyWith(estimate: v.round().clamp(5, 480))),
                  ),
                  LedgerField(
                    labelText: w.priority,
                    child: LedgerSegmentedControl(
                      value: t.priority,
                      options: Priority.values,
                      labelOf: w.priorityName,
                      onChanged: (v) => d.edit(t.copyWith(priority: v)),
                    ),
                  ),
                  LedgerField(
                    labelText: w.labels,
                    child: RawChipGroup(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final l in Label.values)
                          LedgerChip(
                            w.labelName(l),
                            selected: t.labels.contains(l),
                            onTap: () => d.toggle(l),
                          ),
                      ],
                    ),
                  ),
                  LedgerRows(
                    children: [
                      LedgerCheckbox(
                        value: t.done,
                        label: w.done,
                        semanticLabel: w.done,
                        onChanged: (v) => d.edit(t.copyWith(done: v)),
                      ),
                      LedgerToggleRow(
                        title: w.reminder,
                        value: t.reminder,
                        onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                      ),
                      if (t.reminder)
                        _ClockLine(
                          label: w.reminderTime,
                          minute: t.reminderMinute,
                          words: w,
                          onChanged: (v) =>
                              d.edit(t.copyWith(reminderMinute: v)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Stint's form column: 20 between its fields, the 16 a [LedgerField]
/// keeps above its label and the 6 under its control counted in.
class _FormColumn extends StatelessWidget {
  const _FormColumn({required this.children});
  final List<Widget> children;
  static const double _gap = 20;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0)
          SizedBox(
            height:
                (_gap -
                        (child is LedgerField ? LedgerSpacing.s16 : 0) -
                        (children[i - 1] is LedgerField ? LedgerSpacing.s6 : 0))
                    .clamp(0, _gap)
                    .toDouble(),
          ),
        child,
      ],
    ],
  );
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.words,
    required this.label,
    required this.date,
    required this.change,
    this.error,
    this.incomplete = false,
  });
  final StintWords words;
  final String label;
  final DateTime date;
  final ValueChanged<DateTime?> change;
  final String? error;
  final bool incomplete;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 6,
    children: [
      LedgerDatePicker(
        labelText: label,
        value: date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040, 12, 31),
        currentDate: studyToday,
        onChanged: change,
      ),
      if (error case final e?)
        Semantics(
          liveRegion: true,
          child: Text(
            e,
            style: context.ledgerTheme.bodySmall.copyWith(
              color: context.ledgerTheme.danger,
            ),
          ),
        ),
    ],
  );
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.label,
    required this.minute,
    required this.words,
    required this.onChanged,
  });
  final String label;
  final int minute;
  final StintWords words;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => LedgerDatePicker(
    labelText: label,
    value: DateTime(2000, 1, 1, minute ~/ 60, minute % 60),
    mode: LedgerDatePickerMode.time,
    use24hFormat: true,
    onChanged: (v) => onChanged(v.hour * 60 + v.minute),
  );
}

class _Errors extends StatelessWidget {
  const _Errors(this.messages);
  final Iterable<String> messages;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: messages.join(' '),
    excludeSemantics: true,
    child: LedgerBanner(
      title: messages.first,
      text: messages.length > 1 ? messages.skip(1).join(' ') : null,
      tone: LedgerBannerTone.wrong,
    ),
  );
}
