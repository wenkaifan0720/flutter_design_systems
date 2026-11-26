part of '../stint_keycap.dart';

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
            child: KeycapScreen(
              topBar: KeycapAppBar(title: w.taskDetail, onBack: close),
              maxWidth: KeycapMetrics.readingWidth,
              // Save is the page's accent key, at its foot.
              footer: KeycapTooltip(
                message: '${widget.studio.modifier}S',
                child: KeycapButton.accent(
                  icon: const Icon(LucideIcons.check),
                  onPressed: d.dirty ? widget.studio.save : null,
                  child: Text(w.save),
                ),
              ),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: KeycapSpacing.large,
                children: [
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: KeycapTag(t.id, icon: LucideIcons.hash),
                  ),
                  KeycapTextField(
                    labelText: w.title,
                    controller: title,
                    errorText: errors['title'],
                    onChanged: (v) => d.title(v, w.language),
                  ),
                  KeycapTextField(
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
                          ? (box.maxWidth - KeycapSpacing.regular) / 2
                          : box.maxWidth;
                      return Wrap(
                        spacing: KeycapSpacing.regular,
                        runSpacing: KeycapSpacing.large,
                        children: [
                          // Project and Assignee stand side by side, so they
                          // are one kind of field, and the assignee has to be
                          // searchable.
                          SizedBox(
                            width: width,
                            child: KeycapCombobox<String>(
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
                            child: KeycapCombobox<String>(
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
                  KeycapDatePicker(
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
                    children: [
                      ExcludeSemantics(child: KeycapFieldLabel(w.estimate)),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: KeycapStepper(
                          value: t.estimate.clamp(5, 480).toDouble(),
                          min: 5,
                          max: 480,
                          step: 5,
                          semanticLabel: w.estimate,
                          onChanged: (n) {
                            if (n != null) {
                              d.edit(t.copyWith(estimate: n.round()));
                            }
                          },
                        ),
                      ),
                      if (errors['estimate'] case final error?)
                        KeycapFieldMessage(errorText: error),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ExcludeSemantics(child: KeycapFieldLabel(w.priority)),
                      KeycapSegmentedButton<Priority>(
                        semanticLabel: w.priority,
                        expand: true,
                        selected: {t.priority},
                        segments: [
                          for (final p in Priority.values)
                            KeycapSegment(value: p, label: w.priorityName(p)),
                        ],
                        onSelectionChanged: (p) =>
                            d.edit(t.copyWith(priority: p.first)),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ExcludeSemantics(child: KeycapFieldLabel(w.labels)),
                      RawChipGroup(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in Label.values)
                            KeycapChip(
                              w.labelName(l),
                              selected: t.labels.contains(l),
                              onSelected: (_) => d.toggle(l),
                            ),
                        ],
                      ),
                    ],
                  ),
                  KeycapListGroup(
                    children: [
                      // The row is one target with its key: its words press
                      // the box as the box does.
                      MergeSemantics(
                        child: Semantics(
                          checked: t.done,
                          child: KeycapListTile(
                            title: w.done,
                            showChevron: false,
                            onTap: () => d.edit(t.copyWith(done: !t.done)),
                            trailing: ExcludeSemantics(
                              child: ExcludeFocus(
                                child: KeycapCheckbox(
                                  value: t.done,
                                  onChanged: (v) =>
                                      d.edit(t.copyWith(done: v ?? false)),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      KeycapSwitchListTile(
                        title: w.reminder,
                        value: t.reminder,
                        onChanged: (v) => d.edit(t.copyWith(reminder: v)),
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

/// A row that holds a time on the small cap at its end and, pressed, opens
/// Keycap's time picker to change it: on a phone in a sheet from the foot,
/// from 600 px in a dialog.
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
  Widget build(BuildContext context) => KeycapListTile(
    title: label,
    value: words.clock(minute),
    onTap: () async {
      var chosen = RawTimeOfDay(hour: minute ~/ 60, minute: minute % 60);
      Widget picker(BuildContext ctx) => StatefulBuilder(
        builder: (ctx, change) => KeycapTimePicker(
          labelText: label,
          value: chosen,
          minuteStep: 1,
          onChanged: (v) => change(() => chosen = v),
        ),
      );
      final RawTimeOfDay? result;
      if (MediaQuery.sizeOf(context).width < 600) {
        result = await showKeycapBottomSheet<RawTimeOfDay>(
          context: context,
          title: label,
          builder: picker,
          footer: [
            Builder(
              builder: (ctx) => KeycapButton.accent(
                onPressed: () => Navigator.pop(ctx, chosen),
                child: Text(words.apply),
              ),
            ),
          ],
        );
      } else {
        result = await showKeycapDialog<RawTimeOfDay>(
          context: context,
          builder: (ctx) => KeycapDialog(
            title: label,
            content: picker(ctx),
            actions: [
              KeycapButton.text(
                onPressed: () => Navigator.pop(ctx),
                child: Text(words.cancel),
              ),
              KeycapButton.accent(
                onPressed: () => Navigator.pop(ctx, chosen),
                child: Text(words.apply),
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
