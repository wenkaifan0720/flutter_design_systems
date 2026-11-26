part of '../stint_material_expressive.dart';

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
  late final assignee = TextEditingController(
    text: c.personName(c.draft!.task.assignee),
  );
  late final project = TextEditingController(
    text: c.projectName(c.draft!.task.project),
  );
  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    assignee.dispose();
    project.dispose();
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
            child: ExpressiveScaffold(
              topBar: ExpressiveAppBar(
                title: w.taskDetail,
                leading: studio.icon(
                  ExpressiveSymbols.arrowBack,
                  w.back,
                  close,
                ),
              ),
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 16,
                    children: [
                      ExpressiveText(
                        t.id,
                        role: ExpressiveTextRole.label,
                        color: context.expressiveTheme.colors.primary,
                      ),
                      ExpressiveTextField(
                        labelText: w.title,
                        controller: title,
                        errorText: errors['title'],
                        onChanged: (v) => d.title(v, w.language),
                      ),
                      ExpressiveTextArea(
                        labelText: w.notes,
                        controller: notes,
                        onChanged: (v) => d.notes(v, w.language),
                      ),
                      ExpressiveCombobox<String>(
                        labelText: w.project,
                        semanticLabel: w.project,
                        leading: MediaQuery.textScalerOf(ctx).scale(1) > 1.4
                            ? null
                            : const ExpressiveIcon(ExpressiveSymbols.folder),
                        controller: project,
                        options: [
                          for (final p in projects)
                            ExpressiveSelectOption(p.id, w.text(p.name)),
                        ],
                        errorText: errors['project'],
                        onSelected: (o) => d.edit(t.copyWith(project: o.value)),
                      ),
                      ExpressiveCombobox<String>(
                        labelText: w.assignee,
                        hintText: w.selectPerson,
                        semanticLabel: w.assignee,
                        leading: const ExpressiveIcon(ExpressiveSymbols.person),
                        controller: assignee,
                        options: [
                          for (final p in team)
                            ExpressiveSelectOption(p.id, c.personName(p.id)),
                        ],
                        errorText: errors['assignee'],
                        emptyBuilder: (_) => Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(w.noPeople),
                        ),
                        onSelected: (o) =>
                            d.edit(t.copyWith(assignee: o.value)),
                      ),
                      _DateLine(
                        label: w.due,
                        calendarLabel: w.calendar,
                        value: d.dueIncomplete ? null : t.due,
                        fallback: t.due,
                        onChanged: d.setDue,
                        error: errors['due'],
                      ),
                      _Heading(w.estimate),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ExpressiveNumberField(
                          labelText: w.estimate,
                          value: t.estimate,
                          min: 5,
                          max: 480,
                          step: 5,
                          format: w.number,
                          onChanged: (v) => d.edit(t.copyWith(estimate: v)),
                        ),
                      ),
                      _Heading(w.priority),
                      ExpressiveSegmentedButton(
                        value: t.priority,
                        segments: [
                          for (final p in Priority.values)
                            ExpressiveButtonSegment(p, w.priorityName(p)),
                        ],
                        onChanged: (v) => d.edit(t.copyWith(priority: v)),
                      ),
                      _Heading(w.labels),
                      RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            ExpressiveChip.filter(
                              w.labelName(l),
                              selected: t.labels.contains(l),
                              onPressed: () => d.toggle(l),
                            ),
                        ],
                      ),
                      ExpressiveListSection(
                        children: [
                          ExpressiveCheckboxRow(
                            label: w.done,
                            value: t.done,
                            onChanged: (v) => d.edit(t.copyWith(done: v)),
                          ),
                          ExpressiveSwitchRow(
                            label: w.reminder,
                            value: t.reminder,
                            onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                          ),
                          if (t.reminder)
                            _ClockLine(
                              label: w.reminderTime,
                              value: t.reminderMinute,
                              words: w,
                              onChanged: (v) =>
                                  d.edit(t.copyWith(reminderMinute: v)),
                            ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ExpressiveTooltip.plain(
                              message: '${w.save}  ${studio.modifier}S',
                              child: ExpressiveFilledButton(
                                w.save,
                                icon: ExpressiveSymbols.check,
                                onPressed: d.dirty ? studio.save : null,
                              ),
                            ),
                          ),
                          // Beside the list, Save scrolled to the end stands
                          // above the pane's snack bar (72 with its margins).
                          const ToastClearance(band: 72, after: 8),
                        ],
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

Future<DateTime?> _pickDate(
  BuildContext context,
  String label,
  DateTime date, {
  required String cancel,
}) => _raise<DateTime>(
  context,
  cancel: cancel,
  (ctx) => _Sheet(
    title: label,
    children: [
      ExpressiveCalendar(
        value: date,
        currentDate: studyToday,
        firstDate: DateTime(2020),
        lastDate: DateTime(2040, 12, 31),
        onChanged: (day) => Navigator.pop(ctx, day),
      ),
    ],
  ),
);

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.label,
    required this.calendarLabel,
    required this.value,
    required this.fallback,
    required this.onChanged,
    this.error,
  });
  final String label, calendarLabel;
  final DateTime? value;
  final DateTime fallback;
  final ValueChanged<DateTime?> onChanged;
  final String? error;
  @override
  Widget build(BuildContext context) => ExpressiveDockedDatePicker(
    label: label,
    value: value ?? fallback,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    currentDate: studyToday,
    supportingText: error,
    onChanged: onChanged,
  );
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.label,
    required this.value,
    required this.words,
    required this.onChanged,
  });
  final String label;
  final int value;
  final StintWords words;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => ExpressiveListTile(
    title: Text(label),
    subtitle: Text(words.clock(value)),
    leading: const ExpressiveIcon(ExpressiveSymbols.schedule),
    onTap: () async {
      final time = await showExpressiveTimePicker(
        context: context,
        initialHour: value ~/ 60,
        initialMinute: value % 60,
        is24Hour: true,
        initialMode: ExpressiveTimePickerMode.input,
      );
      if (context.mounted && time != null) {
        onChanged(time.hour * 60 + time.minute);
      }
    },
  );
}
