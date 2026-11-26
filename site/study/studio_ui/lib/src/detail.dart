part of '../stint_studio.dart';

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
      final d = c.draft;
      if (d == null || d.task.id != widget.id) return const SizedBox.shrink();
      return ListenableBuilder(
        listenable: d,
        builder: (ctx, _) {
          final t = d.task,
              err = d.submitted ? d.errors(w) : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: StudioScreen(
              topBar: StudioAppBar(
                automaticallyImplyLeading: false,
                title: w.taskDetail,
                leading: StudioIconButton(
                  icon: const Icon(LucideIcons.chevronLeftDir),
                  tooltip: w.back,
                  onPressed: close,
                ),
              ),
              footer: StudioTooltip(
                message: widget.studio.shortcut(LogicalKeyboardKey.keyS),
                child: StudioButton.lit(
                  w.save,
                  icon: const Icon(LucideIcons.check),
                  onPressed: d.dirty ? widget.studio.save : null,
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 14,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: StudioReadout(t.id),
                  ),
                  StudioTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: err['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  StudioTextField(
                    labelText: w.notes,
                    controller: notes,
                    minLines: 3,
                    maxLines: 5,
                    onChanged: (v) => d.notes(v, w.language),
                  ),
                  StudioCombobox<String>(
                    labelText: w.project,
                    options: [for (final p in projects) p.id],
                    labelOf: c.projectName,
                    value: t.project,
                    requireSelection: true,
                    errorText: err['project'],
                    onSelected: (p) => d.edit(t.copyWith(project: p)),
                  ),
                  StudioCombobox<String>(
                    labelText: w.assignee,
                    hintText: w.selectPerson,
                    emptyText: w.noPeople,
                    options: [for (final p in team) p.id],
                    labelOf: c.personName,
                    value: t.assignee,
                    errorText: err['assignee'],
                    onSelected: (p) => d.edit(t.copyWith(assignee: p)),
                  ),
                  StudioDatePicker(
                    labelText: w.due,
                    value: t.due,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2040, 12, 31),
                    currentDate: studyToday,
                    errorText: err['due'],
                    onChanged: d.setDue,
                  ),
                  StudioFormField(
                    labelText: w.estimate,
                    errorText: err['estimate'],
                    mergeSemantics: false,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StudioStepper(
                        value: t.estimate.clamp(5, 480),
                        min: 5,
                        max: 480,
                        step: 5,
                        semanticLabel: w.estimate,
                        decreaseLabel: w.adjust(w.estimate, increase: false),
                        increaseLabel: w.adjust(w.estimate, increase: true),
                        onChanged: (v) => d.edit(t.copyWith(estimate: v)),
                      ),
                    ),
                  ),
                  StudioFormField(
                    labelText: w.priority,
                    mergeSemantics: false,
                    child: _PriorityBank(
                      words: w,
                      value: t.priority,
                      change: (p) => d.edit(t.copyWith(priority: p)),
                    ),
                  ),
                  StudioFormField(
                    labelText: w.labels,
                    mergeSemantics: false,
                    child: RawChipGroup(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final l in Label.values)
                          StudioChip(
                            label: w.labelName(l),
                            selected: t.labels.contains(l),
                            onSelected: (_) => d.toggle(l),
                          ),
                      ],
                    ),
                  ),
                  StudioDisplay(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 5,
                      children: [
                        StudioCheckRow(
                          label: w.done,
                          value: t.done,
                          onChanged: (v) => d.edit(t.copyWith(done: v)),
                        ),
                        const StudioGroove(),
                        StudioListTile.toggle(
                          title: w.reminder,
                          value: t.reminder,
                          onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                        ),
                        if (t.reminder)
                          _ClockSetting(
                            words: w,
                            label: w.reminderTime,
                            minute: t.reminderMinute,
                            onChanged: (v) =>
                                d.edit(d.task.copyWith(reminderMinute: v)),
                          ),
                      ],
                    ),
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
  Widget build(BuildContext context) => StudioListTile(
    title: label,
    subtitle: words.clock(minute),
    leading: const Icon(LucideIcons.clock3),
    semanticLabel: '$label, ${words.clock(minute)}',
    onTap: () async {
      var time = StudioTime(hour: minute ~/ 60, minute: minute % 60);
      final chosen = await showStudioDialog<int>(
        context: context,
        builder: (sheet) => StatefulBuilder(
          builder: (_, change) => StudioDialog(
            title: label,
            content: Center(
              child: StudioTimePicker(
                value: time,
                minuteInterval: 1,
                semanticLabel: label,
                onChanged: (v) => change(() => time = v),
              ),
            ),
            actions: [
              StudioButton.text(
                words.cancel,
                onPressed: () => Navigator.pop(sheet),
              ),
              StudioButton.lit(
                words.apply,
                onPressed: () =>
                    Navigator.pop(sheet, time.hour * 60 + time.minute),
              ),
            ],
          ),
        ),
      );
      if (context.mounted && chosen != null) onChanged(chosen);
    },
  );
}

Future<DateTime?> _pickDay(
  BuildContext context,
  String label,
  DateTime selected,
) => showStudioDialog<DateTime>(
  context: context,
  builder: (sheet) => SingleChildScrollView(
    child: StudioDialog(
      title: label,
      content: StudioCalendar(
        firstDate: DateTime(2020),
        lastDate: DateTime(2040, 12, 31),
        currentDate: studyToday,
        selectedDate: selected,
        autofocus: true,
        onDateChanged: (date) => Navigator.pop(sheet, date),
      ),
    ),
  ),
);

class _PriorityBank extends StatelessWidget {
  const _PriorityBank({
    required this.words,
    required this.value,
    required this.change,
  });
  final StintWords words;
  final Priority value;
  final ValueChanged<Priority> change;
  @override
  Widget build(BuildContext context) => StudioSegmentedButton<Priority>(
    semanticLabel: words.priority,
    value: value,
    expand: true,
    segments: [
      for (final p in Priority.values)
        StudioSegment(value: p, label: words.priorityName(p)),
    ],
    onChanged: change,
  );
}
