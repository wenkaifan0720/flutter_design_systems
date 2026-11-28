part of '../stint_frosted.dart';

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.host, required this.id});
  final _WorkspaceState host;
  final String id;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  StintController get c => widget.host.c;
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
    if (await widget.host.mayLeave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (_, _) {
      final d = c.draft;
      if (d == null || d.task.id != widget.id) return const SizedBox.shrink();
      return ListenableBuilder(
        listenable: d,
        builder: (ctx, _) {
          final task = d.task,
              errors = d.submitted ? d.errors(w) : const <String, String>{};
          final theme = ctx.frostedTheme;
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop) close();
            },
            child: RoutePresentationScope(
              presentation: RoutePresentation.pushed,
              child: FrostedScaffold(
                lights: true,
                topBar: FrostedAppBar(
                  title: w.taskDetail,
                  leading: _IconAct(
                    icon: LucideIcons.chevronLeftDir,
                    label: w.back,
                    act: close,
                  ),
                ),
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [
                    FrostedCard.record(
                      hue: theme.hue(widget.host.projectIndex(task.project)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: _Tag(task.id),
                          ),
                          FrostedTextField(
                            labelText: w.title,
                            controller: title,
                            minLines: 1,
                            maxLines: 3,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              FilteringTextInputFormatter.singleLineFormatter,
                            ],
                            errorText: errors['title'],
                            onChanged: (v) => d.title(v, w.language),
                          ),
                          Semantics(
                            container: true,
                            child: FrostedTextArea(
                              labelText: w.notes,
                              controller: notes,
                              errorText: errors['notes'],
                              minLines: 3,
                              maxLines: 9,
                              onChanged: (v) => d.notes(v, w.language),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FrostedCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: [
                          LayoutBuilder(
                            builder: (context, bounds) {
                              final project = FrostedCombobox<String>(
                                labelText: w.project,
                                options: [for (final p in projects) p.id],
                                displayStringForOption: c.projectName,
                                value: task.project,
                                requireSelection: true,
                                errorText: errors['project'],
                                onSelected: (p) =>
                                    d.edit(task.copyWith(project: p)),
                              );
                              final assignee = FrostedCombobox<String>(
                                labelText: w.assignee,
                                hintText: w.selectPerson,
                                options: [for (final person in team) person.id],
                                displayStringForOption: c.personName,
                                value: task.assignee,
                                errorText: errors['assignee'],
                                onSelected: (p) =>
                                    d.edit(task.copyWith(assignee: p)),
                              );
                              // The form can be a narrow pane inside a desktop window.
                              if (bounds.maxWidth /
                                      MediaQuery.textScalerOf(context)
                                          .scale(1) >=
                                  520) {
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 16,
                                  children: [
                                    Expanded(child: project),
                                    Expanded(child: assignee),
                                  ],
                                );
                              }
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 16,
                                children: [project, assignee],
                              );
                            },
                          ),
                          FrostedPickerRow(
                            label: w.due,
                            title: w.dueDate(task.due),
                            trailing: const Icon(
                              LucideIcons.calendarDays,
                              size: 18,
                            ),
                            onPressed: () async {
                              final chosen = await _datePicker(
                                ctx,
                                w.due,
                                task.due,
                              );
                              if (mounted &&
                                  identical(d, c.draft) &&
                                  chosen != null) {
                                d.setDue(chosen);
                              }
                            },
                          ),
                          FrostedFormField(
                            labelText: w.estimate,
                            errorText: errors['estimate'],
                            child: FrostedNumberField(
                              value: task.estimate.clamp(5, 480),
                              min: 5,
                              max: 480,
                              step: 5,
                              labelText: w.estimate,
                              onChanged: (v) =>
                                  d.edit(task.copyWith(estimate: v)),
                            ),
                          ),
                          FrostedFormField(
                            labelText: w.priority,
                            child: FrostedSegmentedButton<Priority>(
                              label: w.priority,
                              value: task.priority,
                              fill: true,
                              segments: [
                                for (final p in Priority.values)
                                  FrostedButtonSegment(p, w.priorityName(p)),
                              ],
                              onChanged: (v) =>
                                  d.edit(task.copyWith(priority: v)),
                            ),
                          ),
                          FrostedFormField(
                            labelText: w.labels,
                            // A group: each chip keeps its own node.
                            mergeSemantics: false,
                            child: RawChipGroup(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final l in Label.values)
                                  FrostedChip(
                                    w.labelName(l),
                                    selected: task.labels.contains(l),
                                    onPressed: () => d.toggle(l),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    FrostedSettingsGroup(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                w.done,
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            FrostedCheckbox(
                              semanticLabel: w.done,
                              value: task.done,
                              onChanged: (v) =>
                                  d.edit(task.copyWith(done: v ?? false)),
                            ),
                          ],
                        ),
                        FrostedSwitchRow(
                          label: w.reminder,
                          value: task.reminder,
                          onChanged: (v) => d.edit(task.copyWith(reminder: v)),
                        ),
                        if (task.reminder)
                          _TimeRow(
                            label: w.reminderTime,
                            minute: task.reminderMinute,
                            words: w,
                            changed: (v) =>
                                d.edit(d.task.copyWith(reminderMinute: v)),
                          ),
                      ],
                    ),
                  ],
                ),
                footer: FrostedTooltip(
                  message: widget.host.shortcut(LogicalKeyboardKey.keyS),
                  child: FrostedButton(
                    w.save,
                    icon: LucideIcons.check,
                    expand: true,
                    onPressed: d.dirty ? widget.host.save : null,
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

Future<DateTime?> _datePicker(
  BuildContext context,
  String label,
  DateTime chosen,
) => showFrostedDatePicker(
  context,
  initialDate: chosen,
  first: DateTime(2020),
  last: DateTime(2040, 12, 31),
  currentDate: studyToday,
  title: label,
);

class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.label,
    required this.minute,
    required this.words,
    required this.changed,
  });
  final String label;
  final int minute;
  final StintWords words;
  final ValueChanged<int> changed;
  @override
  Widget build(BuildContext context) => FrostedValueRow(
    title: label,
    value: words.clock(minute),
    onPressed: () async {
      final chosen = await showFrostedTimePicker(
        context,
        initialTime: FrostedTime(hour: minute ~/ 60, minute: minute % 60),
        title: label,
      );
      if (context.mounted && chosen != null) {
        changed(chosen.hour * 60 + chosen.minute);
      }
    },
  );
}
