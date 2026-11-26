part of '../stint_gloss.dart';

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.studio, required this.id});
  final _WorkspaceState studio;
  final String id;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
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
            child: GlossScreen(
              topBar: GlossTopBar(title: w.taskDetail, onBack: close),
              footer: GlossTooltip(
                message: '${widget.studio.modifier}S',
                child: GlossButton.filled(
                  w.save,
                  icon: const Icon(LucideIcons.check, size: 16),
                  onPressed: d.dirty ? widget.studio.save : null,
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 18,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: GlossTag(t.id),
                  ),
                  GlossTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  GlossTextArea(
                    labelText: w.notes,
                    controller: notes,
                    minLines: 3,
                    maxLines: 7,
                    onChanged: (v) => d.notes(v, w.language),
                  ),
                  LayoutBuilder(
                    builder: (ctx, box) {
                      final phone = MediaQuery.sizeOf(ctx).width < 600;
                      final columns =
                          box.maxWidth >= 600 &&
                          MediaQuery.textScalerOf(ctx).scale(1) < 1.5;
                      // Side by side the pair fills the row, its outer
                      // edges on the Title's and the Due date's; alone a
                      // field keeps Gloss's select measure.
                      final width = phone
                          ? box.maxWidth
                          : columns
                          ? (box.maxWidth - 16) / 2
                          : box.maxWidth.clamp(0.0, GlossSelect.maxWideWidth);
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          // Project and Assignee stand side by side, so
                          // they are one kind of field: Gloss's select ends
                          // in a pearl bead and its combobox in a bare
                          // chevron, and the assignee has to be searchable.
                          SizedBox(
                            width: width,
                            child: GlossCombobox<String>(
                              labelText: w.project,
                              value: t.project,
                              options: [for (final p in projects) p.id],
                              displayStringForOption: c.projectName,
                              requireSelection: true,
                              errorText: errors['project'],
                              onSelected: (v) => d.edit(t.copyWith(project: v)),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: GlossCombobox<String>(
                              labelText: w.assignee,
                              hintText: w.selectPerson,
                              value: t.assignee,
                              options: [for (final p in team) p.id],
                              displayStringForOption: c.personName,
                              requireSelection: true,
                              errorText: errors['assignee'],
                              onSelected: (v) =>
                                  d.edit(t.copyWith(assignee: v)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  GlossDatePicker(
                    labelText: w.due,
                    value: t.due,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040, 12, 31),
                    currentDate: studyToday,
                    errorText: errors['due'],
                    onChanged: d.setDue,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      GlossFieldLabel(w.estimate),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: GlossStepper(
                          value: t.estimate.clamp(5, 480),
                          min: 5,
                          max: 480,
                          step: 5,
                          semanticLabel: w.estimate,
                          format: w.number,
                          onChanged: (n) => d.edit(t.copyWith(estimate: n)),
                        ),
                      ),
                      if (errors['estimate'] case final error?)
                        GlossFieldMessage(errorText: error),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 6,
                    children: [
                      GlossFieldLabel(w.priority),
                      GlossSegmentedButton(
                        semanticLabel: w.priority,
                        expanded: true,
                        selected: t.priority,
                        segments: [
                          for (final p in Priority.values)
                            GlossSegment(value: p, label: w.priorityName(p)),
                        ],
                        onChanged: (p) => d.edit(t.copyWith(priority: p)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 6,
                    children: [
                      GlossFieldLabel(w.labels),
                      RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            GlossChip(
                              label: w.labelName(l),
                              selected: t.labels.contains(l),
                              onSelected: (_) => d.toggle(l),
                            ),
                        ],
                      ),
                    ],
                  ),
                  GlossWell(
                    dividerIndent: 0,
                    children: [
                      GlossListTile(
                        title: w.done,
                        trailing: GlossCheckbox(
                          semanticLabel: w.done,
                          value: t.done,
                          onChanged: (v) =>
                              d.edit(t.copyWith(done: v ?? false)),
                        ),
                      ),
                      GlossListTile(
                        title: w.reminder,
                        trailing: GlossSwitch(
                          semanticLabel: w.reminder,
                          value: t.reminder,
                          onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                        ),
                      ),
                      if (t.reminder)
                        _ClockRow(
                          words: w,
                          label: w.reminderTime,
                          minute: t.reminderMinute,
                          onChanged: (v) =>
                              d.edit(d.task.copyWith(reminderMinute: v)),
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

class _ClockRow extends StatelessWidget {
  const _ClockRow({
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
  Widget build(BuildContext context) => GlossListTile(
    title: label,
    trailingText: words.clock(minute),
    onTap: () async {
      var chosen = GlossTime(hour: minute ~/ 60, minute: minute % 60);
      final result = await showGlossSheet<GlossTime>(
        context: context,
        title: label,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, change) => Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              GlossTimePicker(
                value: chosen,
                onChanged: (v) => change(() => chosen = v),
                minuteInterval: 1,
                semanticLabel: label,
              ),
              GlossButton.filled(
                words.apply,
                onPressed: () => Navigator.pop(ctx, chosen),
              ),
            ],
          ),
        ),
      );
      if (result != null && context.mounted) {
        onChanged(result.hour * 60 + result.minute);
      }
    },
  );
}
