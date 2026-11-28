part of '../stint_fluent2_design.dart';

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.studio, required this.id});
  final _WorkspaceState studio;
  final String id;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  _WorkspaceState get studio => widget.studio;
  StintController get c => studio.c;
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
    if (await studio.mayLeave() && mounted) c.openTask(null);
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
          final t = d.task,
              errors = d.submitted ? d.errors(w) : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) close();
            },
            child: Fluent2Scaffold(
              topBar: Fluent2AppBar(
                title: w.taskDetail,
                leading: studio.icon(Fluent2Icons.arrowLeft, w.back, close),
              ),
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 20,
                    children: [
                      Row(
                        spacing: 8,
                        children: [
                          Fluent2IconTile(
                            Fluent2Icons.documentTextFilled,
                            hue: _hue(t.project),
                            size: 28,
                          ),
                          Expanded(
                            child: Text(
                              t.id,
                              style: ctx.fluent2Theme.subtitle2,
                            ),
                          ),
                        ],
                      ),
                      Fluent2FormSection(
                        children: [
                          Fluent2FormField(
                            labelText: w.title,
                            required: true,
                            validationMessage: errors['title'],
                            validationState: errors['title'] == null
                                ? null
                                : Fluent2ValidationState.error,
                            child: Fluent2TextField(
                              controller: title,
                              invalid: errors['title'] != null,
                              onChanged: (v) => d.title(v, w.language),
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.notes,
                            child: Fluent2TextArea(
                              controller: notes,
                              onChanged: (v) => d.notes(v, w.language),
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.project,
                            child: Fluent2Select(
                              value: t.project,
                              options: [
                                for (final p in projects)
                                  Fluent2Option(p.id, w.text(p.name)),
                              ],
                              onChanged: (v) => d.edit(t.copyWith(project: v)),
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.assignee,
                            child: Fluent2Combobox(
                              value: t.assignee,
                              hintText: w.selectPerson,
                              empty: w.noPeople,
                              options: [
                                for (final person in team)
                                  Fluent2Option(person.id, w.text(person.name)),
                              ],
                              onChanged: (id) =>
                                  d.edit(t.copyWith(assignee: id)),
                            ),
                          ),
                        ],
                      ),
                      Fluent2FormSection(
                        children: [
                          Fluent2FormField(
                            labelText: w.due,
                            validationMessage: errors['due'],
                            validationState: errors['due'] == null
                                ? null
                                : Fluent2ValidationState.error,
                            child: Fluent2DatePicker(
                              semanticLabel: w.due,
                              value: t.due,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2040, 12, 31),
                              today: studyToday,
                              invalid: errors['due'] != null,
                              onChanged: d.setDue,
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.estimate,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Fluent2SpinButton(
                                value: t.estimate,
                                min: 5,
                                max: 480,
                                step: 5,
                                format: w.number,
                                onChanged: (v) =>
                                    d.edit(t.copyWith(estimate: v.toInt())),
                              ),
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.priority,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Fluent2SegmentedButton(
                                semanticLabel: w.priority,
                                value: t.priority,
                                segments: [
                                  for (final p in Priority.values)
                                    Fluent2ButtonSegment(p, w.priorityName(p)),
                                ],
                                onChanged: (v) =>
                                    d.edit(t.copyWith(priority: v)),
                              ),
                            ),
                          ),
                          Fluent2FormField(
                            labelText: w.labels,
                            child: Fluent2TagGroup<Label>(
                              semanticLabel: w.labels,
                              multiple: true,
                              selected: t.labels,
                              items: [
                                for (final l in Label.values)
                                  Fluent2TagItem(
                                    l,
                                    w.labelName(l),
                                    dismissible: false,
                                  ),
                              ],
                              onSelectionChanged: (set) =>
                                  d.edit(t.copyWith(labels: set)),
                            ),
                          ),
                          Fluent2Checkbox(
                            label: w.done,
                            value: t.done,
                            onChanged: (v) => d.edit(t.copyWith(done: v)),
                          ),
                          Fluent2Switch(
                            label: w.reminder,
                            value: t.reminder,
                            onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                          ),
                          if (t.reminder)
                            Fluent2FormField(
                              labelText: w.reminderTime,
                              child: _ClockField(
                                label: w.reminderTime,
                                value: t.reminderMinute,
                                onChanged: (v) =>
                                    d.edit(t.copyWith(reminderMinute: v)),
                              ),
                            ),
                        ],
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: Fluent2Tooltip(
                          message: '${w.save}  ${studio.modifier}S',
                          child: Fluent2Button(
                            w.save,
                            appearance: Fluent2ButtonAppearance.primary,
                            icon: Fluent2Icons.checkmark,
                            onPressed: () {
                              if (c.saveTask()) {
                                showFluent2Toast(context, w.saved);
                              }
                            },
                          ),
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

class _ClockField extends StatelessWidget {
  const _ClockField({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext ctx) {
    final words = StintWords(
      StintLanguage.forCode(Localizations.localeOf(ctx).languageCode),
    );
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Fluent2Button(
        words.clock(value),
        icon: Fluent2Icons.clock,
        semanticLabel: words.clock(value),
        onPressed: () async {
          var hour = value ~/ 60, minute = value % 60;
          final controls = Fluent2Localizations.of(ctx);
          final result = await showFluent2Dialog<int>(
            ctx,
            builder: (dialog) => StatefulBuilder(
              builder: (dialog, set) => Fluent2Dialog(
                title: label,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 12,
                  children: [
                    Fluent2FormField(
                      labelText: controls.hour,
                      child: Fluent2Select<int>(
                        value: hour,
                        options: [
                          for (var n = 0; n < 24; n++)
                            Fluent2Option(
                              n,
                              words.number(n).padLeft(2, words.number(0)),
                            ),
                        ],
                        onChanged: (n) => set(() => hour = n),
                      ),
                    ),
                    Fluent2FormField(
                      labelText: controls.minute,
                      child: Fluent2Select<int>(
                        value: minute,
                        options: [
                          for (var n = 0; n < 60; n++)
                            Fluent2Option(
                              n,
                              words.number(n).padLeft(2, words.number(0)),
                            ),
                        ],
                        onChanged: (n) => set(() => minute = n),
                      ),
                    ),
                  ],
                ),
                actions: [
                  Fluent2Button(
                    words.cancel,
                    onPressed: () => Navigator.pop(dialog),
                  ),
                  Fluent2Button(
                    RawWidgetsLocalizations.of(dialog).okButtonLabel,
                    appearance: Fluent2ButtonAppearance.primary,
                    onPressed: () => Navigator.pop(dialog, hour * 60 + minute),
                  ),
                ],
              ),
            ),
          );
          if (ctx.mounted && result != null) onChanged(result);
        },
      ),
    );
  }
}
