part of '../stint_appliance.dart';

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
            child: ApplianceScreen(
              topBar: ApplianceAppBar(title: w.taskDetail, onBack: close),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  AppliancePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 13,
                      children: [
                        Text(t.id, style: studio.theme.textTheme.legend),
                        ApplianceTextField(
                          labelText: w.title,
                          controller: title,
                          errorText: errors['title'],
                          onChanged: (v) => draft.title(v, w.language),
                        ),
                        ApplianceTextField(
                          labelText: w.notes,
                          controller: notes,
                          minLines: 3,
                          maxLines: 8,
                          onChanged: (v) => draft.notes(v, w.language),
                        ),
                        // One kind of field for Project and Assignee:
                        // Appliance's select is a short raised key, its
                        // combobox a recessed field as wide as Title, and
                        // the assignee has to be searchable.
                        ApplianceCombobox<String>(
                          labelText: w.project,
                          value: t.project,
                          options: [for (final p in projects) p.id],
                          displayStringForOption: c.projectName,
                          requireSelection: true,
                          onSelected: (v) => draft.edit(t.copyWith(project: v)),
                        ),
                        ApplianceCombobox<String>(
                          labelText: w.assignee,
                          hintText: w.selectPerson,
                          value: t.assignee,
                          options: [for (final p in team) p.id],
                          displayStringForOption: c.personName,
                          emptyLabel: w.noPeople,
                          requireSelection: true,
                          onSelected: (v) =>
                              draft.edit(t.copyWith(assignee: v)),
                        ),
                      ],
                    ),
                  ),
                  AppliancePanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 10,
                      children: [
                        _DueField(draft: draft, words: w, error: errors['due']),
                        ApplianceField(
                          labelText: w.estimate,
                          errorText: errors['estimate'],
                          child: ApplianceStepper(
                            value: t.estimate.clamp(5, 480),
                            min: 5,
                            max: 480,
                            step: 5,
                            semanticLabel: w.estimate,
                            decreaseLabel: w.decrease,
                            increaseLabel: w.increase,
                            onChanged: (v) =>
                                draft.edit(t.copyWith(estimate: v)),
                          ),
                        ),
                        ApplianceFieldLabel(w.priority),
                        ApplianceSegmentedButton(
                          semanticLabel: w.priority,
                          expand: true,
                          segments: [
                            for (final p in Priority.values)
                              ApplianceSegment(
                                value: p,
                                label: w.priorityName(p),
                              ),
                          ],
                          value: t.priority,
                          onChanged: (v) => draft.edit(t.copyWith(priority: v)),
                        ),
                        ApplianceFieldLabel(w.labels),
                        RawChipGroup(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final l in Label.values)
                              ApplianceChip(
                                w.labelName(l),
                                selected: t.labels.contains(l),
                                onSelected: (_) => draft.toggle(l),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ApplianceListGroup(
                    children: [
                      ApplianceListTile(
                        title: w.done,
                        trailing: ApplianceCheckbox(
                          value: t.done,
                          semanticLabel: w.done,
                          onChanged: (v) =>
                              draft.edit(t.copyWith(done: v ?? false)),
                        ),
                      ),
                      ApplianceListTile(
                        title: w.reminder,
                        trailing: ApplianceSwitch(
                          value: t.reminder,
                          semanticLabel: w.reminder,
                          onChanged: (v) => draft.edit(t.copyWith(reminder: v)),
                        ),
                      ),
                      if (t.reminder)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal:
                                ApplianceListTile.keyInset +
                                ApplianceSpacing.medium,
                            vertical: ApplianceSpacing.medium,
                          ),
                          child: _TimeWell(
                            label: w.reminderTime,
                            minute: t.reminderMinute,
                            onChanged: (v) =>
                                draft.edit(t.copyWith(reminderMinute: v)),
                          ),
                        ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: ApplianceButton.filled(
                          w.save,
                          onPressed: draft.dirty ? studio.saveShortcut : null,
                        ),
                      ),
                      // Beside the list, Save scrolled to the end stands
                      // above the pane's notices (52 over a 16 margin).
                      const ToastClearance(band: 68, after: 48),
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

class _TimeWell extends StatelessWidget {
  const _TimeWell({
    required this.label,
    required this.minute,
    required this.onChanged,
  });
  final String label;
  final int minute;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: 5,
    children: [
      ApplianceFieldLabel(label),
      ApplianceTimePicker(
        semanticLabel: label,
        value: RawTimeOfDay(hour: minute ~/ 60, minute: minute % 60),
        onChanged: (v) => onChanged(v.hour * 60 + v.minute),
      ),
    ],
  );
}

class _DueField extends StatelessWidget {
  const _DueField({required this.draft, required this.words, this.error});
  final TaskDraft draft;
  final StintWords words;
  final String? error;

  @override
  Widget build(BuildContext context) => ApplianceDatePicker(
    labelText: words.due,
    value: draft.task.due,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    currentDate: studyToday,
    errorText: error,
    onChanged: draft.setDue,
  );
}
