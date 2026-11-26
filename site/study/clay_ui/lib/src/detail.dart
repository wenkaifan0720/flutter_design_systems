part of '../stint_clay.dart';

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
            child: ClayScreen(
              topBar: ClayTopBar(title: w.taskDetail, onBack: close),
              footer: ClayTooltip(
                message: '${widget.studio.modifier}S',
                child: ClayButton.filled(
                  w.save,
                  icon: const Icon(LucideIcons.check),
                  onPressed: d.dirty ? widget.studio.save : null,
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: ClaySpacing.roomy,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: ClayTag(t.id, icon: LucideIcons.hash),
                  ),
                  ClayTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  ClayTextArea(
                    labelText: w.notes,
                    controller: notes,
                    minLines: 3,
                    maxLines: 7,
                    onChanged: (v) => d.notes(v, w.language),
                  ),
                  LayoutBuilder(
                    builder: (ctx, box) {
                      final columns =
                          box.maxWidth >= 560 &&
                          MediaQuery.textScalerOf(ctx).scale(1) < 1.5;
                      // Side by side the pair fills the row, its outer edges
                      // on the Title's; stacked, each takes the row.
                      final width = columns
                          ? (box.maxWidth - ClaySpacing.regular) / 2
                          : box.maxWidth;
                      return Wrap(
                        spacing: ClaySpacing.regular,
                        runSpacing: ClaySpacing.roomy,
                        children: [
                          // Project and Assignee stand side by side, so they
                          // are one kind of field, and the assignee has to be
                          // searchable.
                          SizedBox(
                            width: width,
                            child: ClayCombobox<String>(
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
                            child: ClayCombobox<String>(
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
                  ClayDatePicker(
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
                    spacing: ClaySpacing.small,
                    children: [
                      ClayFieldLabel(w.estimate),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: ClayNumberField(
                          value: t.estimate.clamp(5, 480).toDouble(),
                          min: 5,
                          max: 480,
                          step: 5,
                          width: 112,
                          semanticLabel: w.estimate,
                          onChanged: (n) {
                            if (n != null) {
                              d.edit(t.copyWith(estimate: n.round()));
                            }
                          },
                        ),
                      ),
                      if (errors['estimate'] case final error?)
                        ClayFieldMessage(errorText: error),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: ClaySpacing.small,
                    children: [
                      ClayFieldLabel(w.priority),
                      ClaySegmentedButton(
                        semanticLabel: w.priority,
                        expanded: true,
                        selected: t.priority,
                        segments: [
                          for (final p in Priority.values)
                            ClaySegment(value: p, label: w.priorityName(p)),
                        ],
                        onChanged: (p) => d.edit(t.copyWith(priority: p)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: ClaySpacing.small,
                    children: [
                      ClayFieldLabel(w.labels),
                      RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            ClayChip(
                              label: w.labelName(l),
                              selected: t.labels.contains(l),
                              onSelected: (_) => d.toggle(l),
                            ),
                        ],
                      ),
                    ],
                  ),
                  ClayGroup(
                    children: [
                      // Each row is one target with its control: the words
                      // press it as the box or the switch does.
                      ClayListTile(
                        title: w.done,
                        checked: t.done,
                        showChevron: false,
                        onTap: () => d.edit(t.copyWith(done: !t.done)),
                        trailing: ExcludeSemantics(
                          child: ExcludeFocus(
                            child: ClayCheckbox(
                              value: t.done,
                              onChanged: (v) =>
                                  d.edit(t.copyWith(done: v ?? false)),
                            ),
                          ),
                        ),
                      ),
                      ClayListTile(
                        title: w.reminder,
                        toggled: t.reminder,
                        showChevron: false,
                        onTap: () => d.edit(t.copyWith(reminder: !t.reminder)),
                        trailing: ExcludeSemantics(
                          child: ExcludeFocus(
                            child: ClaySwitch(
                              value: t.reminder,
                              onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                            ),
                          ),
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

/// A row that names a time and opens Clay's time wheels to change it: on a
/// phone in a sheet from the foot, from 600 px in a dialog.
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
  Widget build(BuildContext context) => ClayListTile(
    title: label,
    trailingText: words.clock(minute),
    onTap: () async {
      var chosen = ClayTime(hour: minute ~/ 60, minute: minute % 60);
      Widget wheels(BuildContext ctx) => StatefulBuilder(
        builder: (ctx, change) => Center(
          child: ClayTimePicker(
            value: chosen,
            onChanged: (v) => change(() => chosen = v),
            minuteInterval: 1,
            semanticLabel: label,
          ),
        ),
      );
      final ClayTime? result;
      if (MediaQuery.sizeOf(context).width < 600) {
        result = await showClayBottomSheet<ClayTime>(
          context: context,
          title: label,
          builder: wheels,
          footerBuilder: (ctx) => ClayButton.filled(
            words.apply,
            onPressed: () => Navigator.pop(ctx, chosen),
          ),
        );
      } else {
        result = await showClayDialog<ClayTime>(
          context: context,
          builder: (ctx) => ClayDialog(
            title: label,
            content: wheels(ctx),
            actions: [
              ClayDialogAction(
                label: words.cancel,
                onPressed: () => Navigator.pop(ctx),
              ),
              ClayDialogAction(
                label: words.apply,
                isDefaultAction: true,
                onPressed: () => Navigator.pop(ctx, chosen),
              ),
            ],
          ),
        );
      }
      if (result != null && context.mounted) {
        onChanged(result.hour * 60 + result.minute);
      }
    },
  );
}
