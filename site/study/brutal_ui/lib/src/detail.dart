part of '../stint_brutal.dart';

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.studio, required this.id});
  final _StudioState studio;
  final String id;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  StintController get c => widget.studio.c;
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
    if (await widget.studio.mayLeave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (_, _) {
      final d = c.draft, w = c.words;
      if (d == null || d.task.id != widget.id) return const SizedBox.shrink();
      return ListenableBuilder(
        listenable: d,
        builder: (ctx, _) {
          final t = d.task,
              errors = d.submitted ? d.errors(w) : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: BrutalScreen(
              topBar: BrutalAppBar(
                title: w.taskDetail,
                leading: BrutalAppBarAction(
                  icon: Icon(
                    w.arabic ? LucideIcons.arrowRight : LucideIcons.arrowLeft,
                  ),
                  semanticLabel: w.back,
                  onPressed: close,
                ),
              ),
              footer: BrutalButton.filled(
                w.save,
                onPressed: d.dirty ? widget.studio.save : null,
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: BrutalTag(t.id),
                  ),
                  BrutalTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  BrutalTextField(
                    labelText: w.notes,
                    controller: notes,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (v) => d.notes(v, w.language),
                  ),
                  LayoutBuilder(
                    builder: (ctx, box) {
                      final phone = MediaQuery.sizeOf(ctx).width < 600;
                      final columns =
                          box.maxWidth >= 600 &&
                          MediaQuery.textScalerOf(ctx).scale(1) < 1.5;
                      final width = phone
                          ? box.maxWidth
                          : (columns ? (box.maxWidth - 16) / 2 : box.maxWidth)
                                .clamp(0.0, BrutalSelect.maxWideWidth);
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          SizedBox(
                            width: width,
                            // One kind of field beside Assignee, which has
                            // to be searchable: Brutal's select ends in a
                            // solid triangle, its combobox in two chevrons.
                            child: BrutalCombobox<String>(
                              labelText: w.project,
                              options: [for (final p in projects) p.id],
                              value: t.project,
                              displayStringForOption: c.projectName,
                              errorText: errors['project'],
                              onSelected: (v) => d.edit(t.copyWith(project: v)),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: BrutalCombobox<String>(
                              labelText: w.assignee,
                              hintText: w.selectPerson,
                              emptyText: w.noPeople,
                              options: [for (final p in team) p.id],
                              value: t.assignee,
                              displayStringForOption: c.personName,
                              errorText: errors['assignee'],
                              onSelected: (v) =>
                                  d.edit(t.copyWith(assignee: v)),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  _Due(draft: d, words: w, error: errors['due']),
                  BrutalFormField(
                    labelText: w.estimate,
                    errorText: errors['estimate'],
                    // The stepper's keys keep their own nodes, so a screen
                    // reader's tap on one reaches it.
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: BrutalStepper(
                        value: t.estimate,
                        min: 5,
                        max: 480,
                        semanticLabel: w.estimate,
                        onChanged: (v) => d.edit(t.copyWith(estimate: v)),
                      ),
                    ),
                  ),
                  BrutalFormField(
                    labelText: w.priority,
                    child: BrutalSegmentedButton(
                      semanticLabel: w.priority,
                      value: t.priority,
                      segments: [
                        for (final p in Priority.values)
                          BrutalSegment(value: p, label: w.priorityName(p)),
                      ],
                      onChanged: (v) => d.edit(t.copyWith(priority: v)),
                    ),
                  ),
                  BrutalFormField(
                    labelText: w.labels,
                    child: RawChipGroup(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final l in Label.values)
                          BrutalChip(
                            label: w.labelName(l),
                            selected: t.labels.contains(l),
                            onSelected: (_) => d.toggle(l),
                          ),
                      ],
                    ),
                  ),
                  BrutalListGroup(
                    children: [
                      BrutalListTile(
                        title: w.done,
                        trailing: BrutalCheckbox(
                          semanticLabel: w.done,
                          value: t.done,
                          onChanged: (v) => d.edit(t.copyWith(done: v)),
                        ),
                      ),
                      BrutalListTile(
                        title: w.reminder,
                        trailing: BrutalSwitch(
                          semanticLabel: w.reminder,
                          value: t.reminder,
                          onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                        ),
                      ),
                      if (t.reminder)
                        _TimeCell(
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

class _Due extends StatelessWidget {
  const _Due({required this.draft, required this.words, this.error});
  final TaskDraft draft;
  final StintWords words;
  final String? error;

  @override
  Widget build(BuildContext context) => BrutalDatePicker(
    labelText: words.due,
    value: draft.task.due,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    currentDate: studyToday,
    errorText: error,
    onChanged: draft.setDue,
  );
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({
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
  Widget build(BuildContext context) => BrutalListTile(
    title: label,
    trailingText: words.clock(minute),
    onTap: () async {
      var current = BrutalTime(hour: minute ~/ 60, minute: minute % 60);
      final time = await showBrutalBottomSheet<BrutalTime>(
        context: context,
        title: label,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, set) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (final hour in [true, false])
                    Builder(
                      builder: (ctx) {
                        final controls = RawWidgetsLocalizations.of(ctx);
                        final label = hour
                            ? controls.timePickerHourLabel
                            : controls.timePickerMinuteLabel;
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            BrutalFieldLabel(label),
                            BrutalWheelPicker<int>(
                              semanticLabel: label,
                              width: 100,
                              items: List.generate(hour ? 24 : 60, (i) => i),
                              value: hour ? current.hour : current.minute,
                              labelOf: (n) =>
                                  words.number(n).padLeft(2, words.number(0)),
                              onChanged: (n) => set(
                                () => current = BrutalTime(
                                  hour: hour ? n : current.hour,
                                  minute: hour ? current.minute : n,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                ],
              ),
              BrutalButton.filled(
                RawWidgetsLocalizations.of(ctx).doneButtonLabel,
                onPressed: () => Navigator.pop(ctx, current),
              ),
            ],
          ),
        ),
      );
      if (context.mounted && time != null) {
        onChanged(time.hour * 60 + time.minute);
      }
    },
  );
}
