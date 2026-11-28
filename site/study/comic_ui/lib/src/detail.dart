part of '../stint_comic.dart';

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
  late final title = TextEditingController(text: w.text(c.draft!.task.title)),
      notes = TextEditingController(text: w.text(c.draft!.task.notes));
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
              err = d.submitted ? d.errors(w) : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (p, _) {
              if (!p) close();
            },
            child: ComicScaffold(
              topBar: ComicAppBar(
                title: w.taskDetail,
                leading: studio.icon(ComicGlyphs.back, w.back, close),
              ),
              body: Align(
                alignment: AlignmentDirectional.topStart,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 740),
                  child: ComicSections(
                    children: [
                      ComicPanel(
                        caption: t.id,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [
                            _RequiredField(
                              submitted: d.submitted,
                              label: w.title,
                              controller: title,
                              error: err['title'],
                              onChanged: (v) => d.title(v, w.language),
                            ),
                            ComicTextArea(
                              labelText: w.notes,
                              minLines: 4,
                              maxLines:
                                  MediaQuery.textScalerOf(ctx).scale(1) > 1.5
                                  ? 10
                                  : 4,
                              controller: notes,
                              onChanged: (v) => d.notes(v, w.language),
                            ),
                            // One kind of field beside Assignee, which has
                            // to be searchable: Comic's select ends in a
                            // chevron, its combobox in none.
                            ComicCombobox<String>(
                              labelText: w.project,
                              initialValue: c.projectName(t.project),
                              options: [for (final p in projects) p.id],
                              search: _offer(
                                [for (final p in projects) p.id],
                                c.projectName,
                                c.projectName(t.project),
                              ),
                              displayStringForOption: c.projectName,
                              onSelected: (id) =>
                                  d.edit(t.copyWith(project: id)),
                            ),
                            ComicCombobox<String>(
                              labelText: w.assignee,
                              hintText: w.selectPerson,
                              initialValue: c.personName(t.assignee),
                              options: [for (final p in team) p.id],
                              search: _offer(
                                [for (final p in team) p.id],
                                c.personName,
                                c.personName(t.assignee),
                              ),
                              displayStringForOption: c.personName,
                              onSelected: (id) =>
                                  d.edit(t.copyWith(assignee: id)),
                            ),
                          ],
                        ),
                      ),
                      ComicPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            ComicLabel(w.due),
                            _DateLine(
                              w: w,
                              value: d.dueIncomplete ? null : t.due,
                              fallback: t.due,
                              onChanged: d.setDue,
                            ),
                            if (err['due'] case final error?)
                              Semantics(liveRegion: true, child: Text(error)),
                            ComicLabel(w.estimate),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: ComicNumberField(
                                value: t.estimate,
                                min: 5,
                                max: 480,
                                step: 5,
                                format: w.number,
                                lessLabel: w.adjust(
                                  w.estimate,
                                  increase: false,
                                ),
                                moreLabel: w.adjust(w.estimate, increase: true),
                                onChanged: (v) =>
                                    d.edit(t.copyWith(estimate: v)),
                              ),
                            ),
                            ComicLabel(w.priority),
                            ComicSegmentedButton(
                              semanticLabel: w.priority,
                              segments: [
                                for (final p in Priority.values)
                                  ComicButtonSegment(p, w.priorityName(p)),
                              ],
                              value: t.priority,
                              onChanged: (v) => d.edit(t.copyWith(priority: v)),
                            ),
                            ComicLabel(w.labels),
                            RawChipGroup(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final l in Label.values)
                                  ComicChip.filter(
                                    w.labelName(l),
                                    selected: t.labels.contains(l),
                                    onSelected: (_) => d.toggle(l),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ComicPanel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            ComicCheckRow(
                              label: w.done,
                              value: t.done,
                              onChanged: (v) => d.edit(t.copyWith(done: v)),
                            ),
                            ComicSwitchRow(
                              label: w.reminder,
                              value: t.reminder,
                              onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                            ),
                            if (t.reminder)
                              _ClockLine(
                                label: w.reminderTime,
                                value: t.reminderMinute,
                                w: w,
                                onChanged: (v) =>
                                    d.edit(t.copyWith(reminderMinute: v)),
                              ),
                          ],
                        ),
                      ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _tip(
                          '${w.save}  ${studio.modifier}S',
                          ComicButton.filled(
                            w.save,
                            icon: ComicGlyphs.check,
                            onPressed: () {
                              if (c.saveTask()) {
                                showComicSnackBar(context, w.saved);
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

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.w,
    required this.value,
    required this.fallback,
    required this.onChanged,
  });
  final StintWords w;
  final DateTime? value;
  final DateTime fallback;
  final ValueChanged<DateTime?> onChanged;
  // The caps label above stands with the panel's other labels; the select
  // speaks the same name.
  @override
  Widget build(BuildContext ctx) => ComicSelectField(
    semanticLabel: w.due,
    value: w.dueDate(value ?? fallback),
    onPressed: () async {
      final selected = await _pickDay(
        ctx,
        value: value ?? fallback,
        title: w.due,
        cancel: w.cancel,
      );
      if (ctx.mounted && selected != null) {
        onChanged(calendarDay(selected));
      }
    },
  );
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.label,
    required this.value,
    required this.w,
    required this.onChanged,
  });
  final String label;
  final int value;
  final StintWords w;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext ctx) => _InkRow(
    title: label,
    subtitle: w.clock(value),
    leading: const Icon(ComicGlyphs.time),
    first: true,
    onPressed: () async {
      var hour = value ~/ 60, minute = value % 60;
      final shared = RawWidgetsLocalizations.of(ctx);
      final chosen = await showComicDialog<int>(
        ctx,
        builder: (dialog) => StatefulBuilder(
          builder: (dialog, set) => ComicDialog(
            title: label,
            content: [
              MergeSemantics(
                child: ComicSelect<int>(
                  labelText: shared.timePickerHourLabel,
                  value: hour,
                  options: [
                    for (var n = 0; n < 24; n++)
                      ComicSelectOption(n, w.number(n)),
                  ],
                  onChanged: (n) => set(() => hour = n),
                ),
              ),
              MergeSemantics(
                child: ComicSelect<int>(
                  labelText: shared.timePickerMinuteLabel,
                  value: minute,
                  options: [
                    for (var n = 0; n < 60; n++)
                      ComicSelectOption(n, w.number(n).padLeft(2, w.number(0))),
                  ],
                  onChanged: (n) => set(() => minute = n),
                ),
              ),
            ],
            actions: [
              ComicButton(w.cancel, onPressed: () => Navigator.pop(dialog)),
              ComicButton.filled(
                ComicLocalizations.of(ctx).choose,
                onPressed: () => Navigator.pop(dialog, hour * 60 + minute),
              ),
            ],
          ),
        ),
      );
      if (ctx.mounted && chosen != null) onChanged(chosen);
    },
  );
}

// Keep the field's accessible editing connection intact while correcting a submitted
// error. Chromium replaces Comic's input when its live validation decoration changes.
class _RequiredField extends StatefulWidget {
  const _RequiredField({
    required this.label,
    required this.error,
    required this.onChanged,
    required this.submitted,
    this.controller,
    this.hint,
    this.multiline = false,
  });
  final String label;
  final String? error, hint;
  final TextEditingController? controller;
  final ValueChanged<String> onChanged;
  final bool multiline, submitted;
  @override
  State<_RequiredField> createState() => _RequiredFieldState();
}

class _RequiredFieldState extends State<_RequiredField> {
  late final focus = FocusNode()..addListener(syncError);
  late String? error = widget.error;
  void syncError() {
    if (!focus.hasFocus && error != widget.error) {
      setState(() => error = widget.error);
    }
  }

  @override
  void didUpdateWidget(_RequiredField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.submitted || !focus.hasFocus || widget.error != null) {
      error = widget.error;
    }
  }

  @override
  void dispose() {
    focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.multiline
      ? ComicTextArea(
          labelText: widget.label,
          hintText: widget.hint,
          focusNode: focus,
          errorText: error,
          controller: widget.controller,
          onChanged: widget.onChanged,
        )
      : ComicTextField(
          minLines: 1,
          maxLines: MediaQuery.textScalerOf(context).scale(1) > 1.5 ? 3 : 1,
          textInputAction: TextInputAction.done,
          inputFormatters: [FilteringTextInputFormatter.singleLineFormatter],
          labelText: widget.label,
          hintText: widget.hint,
          focusNode: focus,
          errorText: error,
          controller: widget.controller,
          onChanged: widget.onChanged,
        );
}

/// What a task field's list offers: every option while the field holds the
/// one already chosen (Comic's combobox reads its starting words as typed,
/// and would offer that one alone), else the options whose names match.
Iterable<String> Function(String) _offer(
  List<String> ids,
  String Function(String) name,
  String chosen,
) => (query) {
  final words = query.trim().toLowerCase();
  if (words.isEmpty || words == chosen.toLowerCase()) return ids;
  return ids.where((id) => name(id).toLowerCase().contains(words));
};
