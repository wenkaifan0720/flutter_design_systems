part of '../stint_retro_desktop.dart';

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
  late final title = TextEditingController(text: w.text(c.draft!.task.title)),
      notes = TextEditingController(text: w.text(c.draft!.task.notes));
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
              e = draft.submitted ? draft.errors(w) : const <String, String>{};
          final desk = RetroDesktopTheme.of(ctx).desk;
          final save = RetroDesktopTooltip(
            message: widget.studio.keys(LogicalKeyboardKey.keyS),
            child: RetroDesktopButton(
              w.save,
              wide: !desk,
              isDefaultAction: true,
              onPressed: draft.dirty ? widget.studio.save : null,
            ),
          );
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: _Pane(
              // On a phone Save stands in the page's foot strip; on the desk
              // that strip runs under the whole pane, past the window's
              // frame, so Save closes the window's form as a dialog's
              // default button does.
              footer: desk ? null : save,
              window: RetroDesktopWindow(
                title: w.taskDetail,
                onClose: close,
                info: t.id,
                infoEnd: c.projectName(t.project),
                icon: RetroDesktopGlyphs.fileText,
                child: RetroDesktopSections(
                  children: [
                    RetroDesktopTextField(
                      labelText: w.title,
                      controller: title,
                      errorText: e['title'],
                      onChanged: (v) => draft.title(v, w.language),
                    ),
                    Semantics(
                      container: true,
                      child: RetroDesktopTextArea(
                        labelText: w.notes,
                        controller: notes,
                        lines: 3,
                        onChanged: (v) => draft.notes(v, w.language),
                      ),
                    ),
                    RetroDesktopCombobox<String>(
                      labelText: w.project,
                      requireSelection: true,
                      options: [for (final p in projects) p.id],
                      value: t.project,
                      displayString: c.projectName,
                      errorText: e['project'],
                      onSelected: (p) => draft.edit(t.copyWith(project: p)),
                    ),
                    RetroDesktopCombobox<String>(
                      labelText: w.assignee,
                      hintText: w.selectPerson,
                      requireSelection: true,
                      options: [for (final p in team) p.id],
                      value: t.assignee,
                      displayString: c.personName,
                      errorText: e['assignee'],
                      onSelected: (p) => draft.edit(t.copyWith(assignee: p)),
                    ),
                    RetroDesktopFormField(
                      errorText: e['due'],
                      child: RetroDesktopListTile(
                        title: w.due,
                        note: w.dueDate(t.due),
                        isFirst: true,
                        leading: const Icon(RetroDesktopGlyphs.calendar),
                        onPressed: () async {
                          final day = await showRetroDesktopDatePicker(
                            ctx,
                            title: w.due,
                            value: t.due,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2040, 12, 31),
                          );
                          if (day != null &&
                              mounted &&
                              identical(c.draft, draft)) {
                            draft.setDue(day);
                          }
                        },
                      ),
                    ),
                    _FieldGroup(
                      label: w.estimate,
                      error: e['estimate'],
                      child: RetroDesktopNumberField(
                        labelText: w.estimate,
                        value: t.estimate,
                        min: 5,
                        max: 480,
                        step: 5,
                        onChanged: (v) => draft.edit(t.copyWith(estimate: v)),
                      ),
                    ),
                    RetroDesktopSegmentedButton<Priority>(
                      label: w.priority,
                      value: t.priority,
                      segments: [
                        for (final p in Priority.values)
                          RetroDesktopButtonSegment(p, w.priorityName(p)),
                      ],
                      onChanged: (p) => draft.edit(t.copyWith(priority: p)),
                    ),
                    _FieldGroup(
                      label: w.labels,
                      child: RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            RetroDesktopChip(
                              w.labelName(l),
                              selected: t.labels.contains(l),
                              filter: true,
                              onPressed: () => draft.toggle(l),
                            ),
                        ],
                      ),
                    ),
                    const RetroDesktopDivider.etched(),
                    RetroDesktopCheckRow(
                      label: w.done,
                      value: t.done,
                      onChanged: (v) => draft.edit(t.copyWith(done: v)),
                    ),
                    // An on/off on the period's form is a check box, as
                    // Done's above it: one kind of control, not two.
                    RetroDesktopCheckRow(
                      label: w.reminder,
                      value: t.reminder,
                      onChanged: (v) => draft.edit(t.copyWith(reminder: v)),
                    ),
                    if (t.reminder)
                      _ClockSetting(
                        words: w,
                        label: w.reminderTime,
                        minute: t.reminderMinute,
                        onChanged: (n) =>
                            draft.edit(draft.task.copyWith(reminderMinute: n)),
                      ),
                    if (desk)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: save,
                          ),
                          // Beside the list, Save scrolled to the end stands
                          // above the pane's notices (80 over a 16 margin).
                          const ToastClearance(band: 96, after: 27),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

class _FieldGroup extends StatelessWidget {
  const _FieldGroup({required this.label, this.error, required this.child});
  final String label;
  final String? error;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      RetroDesktopFormField(labelText: label, errorText: error, child: child);
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
  Widget build(BuildContext context) => RetroDesktopListTile(
    isFirst: true,
    title: label,
    note: words.clock(minute),
    leading: const Icon(RetroDesktopGlyphs.clock),
    onPressed: () async {
      final picked = await showRetroDesktopTimePicker(
        context,
        title: label,
        value: RetroDesktopTime(minute ~/ 60, minute % 60),
        use24Hour: true,
      );
      if (context.mounted && picked != null) {
        onChanged(picked.hour * 60 + picked.minute);
      }
    },
  );
}
