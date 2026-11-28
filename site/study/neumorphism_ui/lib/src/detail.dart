part of '../stint_neumorphism.dart';

class _TaskEditor extends StatefulWidget {
  const _TaskEditor({super.key, required this.studio, required this.id});
  final _WorkspaceState studio;
  final String id;
  @override
  State<_TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends State<_TaskEditor> {
  StintController get c => widget.studio.c;
  StintWords get w => c.words;
  late final title = TextEditingController(text: w.text(c.draft!.task.title));
  late final notes = TextEditingController(text: w.text(c.draft!.task.notes));
  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (await widget.studio.mayLeave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      final draft = c.draft;
      if (draft == null || draft.task.id != widget.id) {
        return const SizedBox.shrink();
      }
      return ListenableBuilder(
        listenable: draft,
        builder: (ctx, _) {
          final t = draft.task,
              errors = draft.submitted
                  ? draft.errors(w)
                  : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: NeumorphicScaffold(
              footer: NeumorphicTooltip(
                message: '${widget.studio.modifier}S',
                child: NeumorphicButton.filled(
                  w.save,
                  icon: LucideIcons.check,
                  wide: true,
                  onPressed: draft.dirty ? widget.studio.save : null,
                ),
              ),
              body: NeumorphicSections(
                children: [
                  Row(
                    spacing: 12,
                    children: [
                      NeumorphicBackButton(onPressed: close),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                w.taskDetail,
                                style: NeumorphicTheme.of(ctx).textTheme.title,
                              ),
                            ),
                            Text(
                              t.id,
                              style: NeumorphicTheme.of(ctx).textTheme.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  NeumorphicTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (s) => draft.title(s, w.language),
                  ),
                  NeumorphicTextArea(
                    labelText: w.notes,
                    controller: notes,
                    maxLines: 3,
                    onChanged: (s) => draft.notes(s, w.language),
                  ),
                  NeumorphicCombobox<String>(
                    labelText: w.project,
                    requireSelection: true,
                    errorText: errors['project'],
                    options: [for (final p in projects) p.id],
                    value: t.project,
                    displayStringForOption: c.projectName,
                    onSelected: (p) => draft.edit(t.copyWith(project: p)),
                  ),
                  NeumorphicCombobox<String>(
                    labelText: w.assignee,
                    hintText: w.selectPerson,
                    requireSelection: true,
                    errorText: errors['assignee'],
                    options: [for (final p in team) p.id],
                    value: t.assignee,
                    displayStringForOption: c.personName,
                    onSelected: (p) => draft.edit(t.copyWith(assignee: p)),
                  ),
                  _FieldGroup(
                    label: w.due,
                    error: errors['due'],
                    child: Semantics(
                      label: w.due,
                      child: NeumorphicSelectField(
                        value: w.dueDate(t.due),
                        onPressed: () async {
                          final day = await showNeumorphicDatePicker(
                            ctx,
                            title: w.due,
                            value: t.due,
                            currentDate: studyToday,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040, 12, 31),
                            confirmLabel: w.apply,
                            cancelLabel: w.cancel,
                          );
                          if (day != null &&
                              mounted &&
                              identical(draft, c.draft)) {
                            draft.setDue(day);
                          }
                        },
                      ),
                    ),
                  ),
                  _FieldGroup(
                    label: w.estimate,
                    error: errors['estimate'],
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: NeumorphicNumberField(
                        labelText: w.estimate,
                        value: t.estimate.toDouble(),
                        min: 5,
                        max: 480,
                        step: 5,
                        onChanged: (n) =>
                            draft.edit(t.copyWith(estimate: n?.toInt() ?? 0)),
                      ),
                    ),
                  ),
                  _FieldGroup(
                    label: w.priority,
                    child: NeumorphicSegmentedButton<Priority>(
                      semanticLabel: w.priority,
                      segments: [
                        for (final p in Priority.values)
                          NeumorphicButtonSegment(p, w.priorityName(p)),
                      ],
                      value: t.priority,
                      onChanged: (p) => draft.edit(t.copyWith(priority: p)),
                    ),
                  ),
                  _FieldGroup(
                    label: w.labels,
                    // A group: each chip keeps its own node.
                    group: true,
                    child: RawChipGroup(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final l in Label.values)
                          NeumorphicChip(
                            w.labelName(l),
                            selected: t.labels.contains(l),
                            onPressed: () => draft.toggle(l),
                          ),
                      ],
                    ),
                  ),
                  NeumorphicCard(
                    children: [
                      NeumorphicCheckRow(
                        label: w.done,
                        value: t.done,
                        onChanged: (v) =>
                            draft.edit(t.copyWith(done: v ?? false)),
                      ),
                      NeumorphicSwitchRow(
                        label: w.reminder,
                        value: t.reminder,
                        onChanged: (v) => draft.edit(t.copyWith(reminder: v)),
                      ),
                      if (t.reminder)
                        _ClockSetting(
                          words: w,
                          label: w.reminderTime,
                          minute: t.reminderMinute,
                          onChanged: (n) => draft.edit(
                            draft.task.copyWith(reminderMinute: n),
                          ),
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

class _ClockSetting extends StatelessWidget {
  const _ClockSetting({
    required this.words,
    required this.label,
    required this.minute,
    required this.onChanged,
  });
  final StintWords words;
  final String label;
  final int minute;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Semantics(
      hint: words.clock(minute),
      child: NeumorphicListTile(
        title: label,
        note: words.clock(minute),
        isFirst: true,
        leading: const Icon(LucideIcons.clock3),
        onPressed: () async {
          final time = await showNeumorphicTimePicker(
            context,
            title: label,
            value: NeumorphicTime(minute ~/ 60, minute % 60),
            twentyFour: true,
            minuteStep: 1,
            confirmLabel: words.apply,
            cancelLabel: words.cancel,
          );
          if (time != null && context.mounted) {
            onChanged(time.hour * 60 + time.minute);
          }
        },
      ),
    ),
  );
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({
    required this.label,
    this.error,
    this.group,
    required this.child,
  });
  final String label;
  final String? error;
  final bool? group;
  final Widget child;

  @override
  Widget build(BuildContext context) => NeumorphicFormField(
    labelText: label,
    errorText: error,
    group: group,
    child: child,
  );
}
