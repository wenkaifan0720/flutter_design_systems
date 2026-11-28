part of '../stint_civic.dart';

class _TaskForm extends StatefulWidget {
  const _TaskForm({super.key, required this.service, required this.id});
  final _ServiceState service;
  final String id;
  @override
  State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  StintController get c => widget.service.c;
  late final title = TextEditingController(
    text: c.words.text(c.draft!.task.title),
  );
  late final notes = TextEditingController(
    text: c.words.text(c.draft!.task.notes),
  );
  final fields = {
    for (final f in ['title', 'due', 'project', 'assignee', 'estimate'])
      f: GlobalKey(),
  };
  final focus = {
    for (final f in ['title', 'due', 'project', 'assignee', 'estimate'])
      f: FocusNode(),
  };
  @override
  void dispose() {
    title.dispose();
    notes.dispose();
    for (final f in focus.values) {
      f.dispose();
    }
    super.dispose();
  }

  Future<void> close() async {
    if (await widget.service.canLeave() && mounted) c.openTask(null);
  }

  void reveal(String field) {
    final target = fields[field]?.currentContext;
    if (target != null) Scrollable.ensureVisible(target, alignment: .2);
    focus[field]?.requestFocus();
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
          final w = c.words,
              t = d.task,
              errors = d.submitted ? d.errors(w) : const <String, String>{};
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: CivicPageBody(
              backLink: CivicBackLink(label: w.back, onPressed: close),
              caption: t.id,
              title: w.taskDetail,
              errorSummary: errors.isEmpty
                  ? null
                  : CivicErrorSummary(
                      title: _problem(w),
                      errors: [
                        for (final e in errors.entries)
                          CivicErrorSummaryItem(
                            text: e.value,
                            onPressed: () => reveal(e.key),
                          ),
                      ],
                    ),
              action: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CivicButton(
                    onPressed: d.dirty ? widget.service.save : null,
                    child: Text(w.save),
                  ),
                  // Beside the list, Save scrolled to the end stands above
                  // the pane's notices (64 over a 16 margin); a foot, as
                  // narrower, keeps itself clear.
                  if (!CivicLayout.isApp(MediaQuery.sizeOf(context).width))
                    const ToastClearance(band: 80, after: 64),
                ],
              ),
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: [
                    CivicTextField(
                      key: fields['title'],
                      labelText: w.title,
                      controller: title,
                      focusNode: focus['title'],
                      errorText: errors['title'],
                      onChanged: (v) => d.title(v, w.language),
                    ),
                    CivicTextField(
                      labelText: w.notes,
                      controller: notes,
                      keyboardType: TextInputType.multiline,
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
                        final width = phone
                            ? box.maxWidth
                            : (columns ? (box.maxWidth - 16) / 2 : box.maxWidth)
                                  .clamp(0.0, 320.0);
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            SizedBox(
                              width: width,
                              // One kind of field beside Assignee, which has
                              // to be searchable: Civic's select is a box
                              // with a chevron, its combobox a plain box.
                              child: CivicCombobox<String>(
                                key: fields['project'],
                                labelText: w.project,
                                value: t.project,
                                options: [for (final p in projects) p.id],
                                displayStringForOption: c.projectName,
                                focusNode: focus['project'],
                                errorText: errors['project'],
                                onSelected: (v) =>
                                    d.edit(t.copyWith(project: v)),
                              ),
                            ),
                            SizedBox(
                              width: width,
                              child: CivicCombobox<String>(
                                key: fields['assignee'],
                                labelText: w.assignee,
                                hintText: w.selectPerson,
                                focusNode: focus['assignee'],
                                value: t.assignee,
                                options: [for (final p in team) p.id],
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
                    Focus(
                      key: fields['due'],
                      focusNode: focus['due'],
                      skipTraversal: true,
                      child: _DateAnswer(
                        label: w.due,
                        words: w,
                        date: t.due,
                        incomplete: d.dueIncomplete,
                        error: errors['due'],
                        change: d.setDue,
                      ),
                    ),
                    Focus(
                      key: fields['estimate'],
                      focusNode: focus['estimate'],
                      skipTraversal: true,
                      child: CivicNumberField(
                        labelText: w.estimate,
                        errorText: errors['estimate'],
                        value: t.estimate.toDouble(),
                        min: 5,
                        max: 480,
                        step: 5,
                        fractionDigits: 0,
                        onChanged: (v) =>
                            d.edit(t.copyWith(estimate: v?.toInt() ?? 0)),
                      ),
                    ),
                    _Choices<Priority>(
                      label: w.priority,
                      values: Priority.values,
                      selected: {t.priority},
                      name: w.priorityName,
                      changed: (s) => d.edit(t.copyWith(priority: s.single)),
                    ),
                    _Choices<Label>(
                      label: w.labels,
                      values: Label.values,
                      selected: t.labels,
                      name: w.labelName,
                      many: true,
                      changed: (s) => d.edit(t.copyWith(labels: s)),
                    ),
                    CivicCheckbox(
                      labelText: w.done,
                      value: t.done,
                      onChanged: (v) => d.edit(t.copyWith(done: v)),
                    ),
                    CivicSwitch(
                      labelText: w.reminder,
                      value: t.reminder,
                      onChanged: (v) => d.edit(t.copyWith(reminder: v)),
                    ),
                    if (t.reminder)
                      _TimeAnswer(
                        label: w.reminderTime,
                        minute: t.reminderMinute,
                        change: (v) => d.edit(t.copyWith(reminderMinute: v)),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  );
}
