part of '../stint_minimal.dart';

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({required this.workspace, required this.id});
  final _WorkspaceState workspace;
  final String id;
  @override
  State<_TaskEditor> createState() => _EditorState();
}

class _EditorState extends State<_TaskEditor> {
  _WorkspaceState get studio => widget.workspace;
  StintController get c => studio.c;
  StintWords get w => c.words;
  late final TextEditingController title, notes;
  @override
  void initState() {
    super.initState();
    final task = c.draft?.task;
    title = TextEditingController(text: task == null ? '' : w.text(task.title));
    notes = TextEditingController(text: task == null ? '' : w.text(task.notes));
  }

  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (await studio.mayLeave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final draft = c.draft;
      if (draft == null || draft.task.id != widget.id) {
        return const SizedBox.shrink();
      }
      return ListenableBuilder(
        listenable: draft,
        builder: (context, _) {
          final t = draft.task;
          final errors = draft.submitted
              ? draft.errors(w)
              : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) close();
            },
            child: MinimalScaffold(
              topBar: MinimalAppBar(
                title: w.taskDetail,
                subtitle: t.id,
                large: false,
                // Lucide's arrows don't turn with the text, so right to left the
                // back arrow points right.
                leading: studio.icon(
                  w.arabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                  w.back,
                  close,
                ),
              ),
              // Save stands on the page's foot, which Minimal keeps its
              // toasts clear of: Changes saved never covers it.
              footer: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: MinimalButton(
                    w.save,
                    expand: MediaQuery.sizeOf(context).width < 600,
                    onPressed: draft.dirty ? studio.saveShortcut : null,
                  ),
                ),
              ),
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 620),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 14,
                    children: [
                      MinimalTextField(
                        labelText: w.title,
                        controller: title,
                        errorText: errors['title'],
                        onChanged: (v) => draft.title(v, w.language),
                      ),
                      MinimalTextArea(
                        labelText: w.notes,
                        controller: notes,
                        onChanged: (v) => draft.notes(v, w.language),
                      ),
                      // One kind of field for Project and Assignee: Minimal's
                      // select is a short property row, its combobox a
                      // field as wide as Title, and the assignee has to be
                      // searchable.
                      MinimalCombobox<String>(
                        labelText: w.project,
                        value: t.project,
                        options: [for (final p in projects) p.id],
                        displayStringForOption: c.projectName,
                        requireSelection: true,
                        onSelected: (v) => draft.edit(t.copyWith(project: v)),
                      ),
                      MinimalCombobox<String>(
                        labelText: w.assignee,
                        hintText: w.selectPerson,
                        value: t.assignee,
                        options: [for (final p in team) p.id],
                        displayStringForOption: c.personName,
                        requireSelection: true,
                        onSelected: (v) => draft.edit(t.copyWith(assignee: v)),
                      ),
                      _DueField(draft: draft, words: w, error: errors['due']),
                      _FieldLabel(w.estimate),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: MinimalNumberField(
                          labelText: w.estimate,
                          value: t.estimate,
                          min: 5,
                          max: 480,
                          step: 5,
                          format: w.number,
                          onChanged: (v) => draft.edit(t.copyWith(estimate: v)),
                        ),
                      ),
                      _FieldLabel(w.priority),
                      MinimalSegmentedButton(
                        label: w.priority,
                        expand:
                            MediaQuery.textScalerOf(context).scale(1) <= 1.4,
                        segments: [
                          for (final p in Priority.values)
                            MinimalButtonSegment(p, w.priorityName(p)),
                        ],
                        value: t.priority,
                        onChanged: (v) => draft.edit(t.copyWith(priority: v)),
                      ),
                      _FieldLabel(w.labels),
                      RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            MinimalChip(
                              w.labelName(l),
                              selected: t.labels.contains(l),
                              onPressed: () => draft.toggle(l),
                            ),
                        ],
                      ),
                      // The rows stand on the form's keyline, as the date
                      // and time rows above and below them do.
                      MinimalListSection(
                        gutter: false,
                        children: [
                          MinimalListTile(
                            title: w.done,
                            trailing: MinimalCheckbox(
                              label: w.done,
                              value: t.done,
                              onChanged: (v) => draft.edit(t.copyWith(done: v)),
                            ),
                          ),
                          MinimalListTile(
                            title: w.reminder,
                            trailing: MinimalSwitch(
                              label: w.reminder,
                              value: t.reminder,
                              onChanged: (v) =>
                                  draft.edit(t.copyWith(reminder: v)),
                            ),
                          ),
                        ],
                      ),
                      if (t.reminder)
                        MinimalTimePicker(
                          labelText: w.reminderTime,
                          value: atMinute(t.due, t.reminderMinute),
                          onChanged: (v) => draft.edit(
                            t.copyWith(reminderMinute: minuteOfDay(v)),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);
  final String label;
  @override
  Widget build(BuildContext context) =>
      Text(label, style: context.minimalTheme.label);
}

class _DueField extends StatelessWidget {
  const _DueField({required this.draft, required this.words, this.error});
  final TaskDraft draft;
  final StintWords words;
  final String? error;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 4,
    children: [
      MinimalDatePicker(
        labelText: words.due,
        value: draft.task.due,
        mode: MinimalDatePickerMode.date,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040, 12, 31),
        currentDate: studyToday,
        onChanged: draft.setDue,
      ),
      if (error != null) Semantics(liveRegion: true, child: Text(error!)),
    ],
  );
}
