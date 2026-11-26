part of '../stint_terminal.dart';

class _Editor extends StatefulWidget {
  const _Editor({super.key, required this.console, required this.id});
  final _ConsoleState console;
  final String id;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  StintController get c => widget.console.c;
  late final title = TextEditingController(
    text: c.words.text(c.draft!.task.title),
  );
  final titleFocus = FocusNode();
  TaskDraft? rejectedTitle;
  @override
  void initState() {
    super.initState();
    titleFocus.addListener(releaseTitleError);
  }

  void releaseTitleError() {
    if (!titleFocus.hasFocus && rejectedTitle != null) {
      setState(() => rejectedTitle = null);
    }
  }

  late final notes = TextEditingController(
    text: c.words.text(c.draft!.task.notes),
  );
  @override
  void dispose() {
    titleFocus.removeListener(releaseTitleError);
    titleFocus.dispose();
    title.dispose();
    notes.dispose();
    super.dispose();
  }

  Future<void> close() async {
    if (await widget.console.leave() && mounted) c.openTask(null);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      final draft = c.draft;
      if (draft == null || draft.task.id != widget.id) {
        return const SizedBox.shrink();
      }
      return ListenableBuilder(
        listenable: draft,
        builder: (ctx, _) {
          final t = draft.task,
              w = c.words,
              g = ctx.termGrid,
              err = {
                if (draft.submitted) ...draft.errors(w),
                if (identical(rejectedTitle, draft) && titleFocus.hasFocus)
                  'title': w.titleError,
              };
          return PopScope<Object?>(
            canPop: false,
            onPopInvokedWithResult: (popped, _) {
              if (!popped) close();
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _Page(
                    children: [
                      Row(
                        children: [
                          widget.console.act(
                            w.arabic ? '→' : '←',
                            w.back,
                            close,
                          ),
                          SizedBox(width: g.cellWidth),
                          // The id is the pane's title, cut into its top
                          // line below; over the heading too it was printed
                          // twice, and the back key stood between two lines.
                          Expanded(child: _Heading(w.taskDetail)),
                        ],
                      ),
                      if (err.isNotEmpty) _Errors(err),
                      TermPane(
                        key: ValueKey(t.id),
                        title: t.id,
                        padding:
                            MediaQuery.sizeOf(ctx).width < 600 &&
                                MediaQuery.textScalerOf(ctx).scale(1) > 1.45
                            ? TermInset.zero
                            : null,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: g.lineHeight / 2,
                          children: [
                            _InputValidation(
                              error: err['title'],
                              child: TermTextField(
                                labelText: w.title,
                                lines:
                                    MediaQuery.textScalerOf(ctx).scale(1) > 1.45
                                    ? 3
                                    : 1,
                                textInputAction: TextInputAction.done,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter
                                      .singleLineFormatter,
                                ],
                                controller: title,
                                focusNode: titleFocus,
                                errorText: err['title'],
                                onChanged: (v) {
                                  // Keep the rejected field and its terminal banner in place until
                                  // the user finishes correcting it.
                                  if (err.containsKey('title') &&
                                      titleFocus.hasFocus) {
                                    rejectedTitle = draft;
                                  }
                                  draft.title(v, w.language);
                                },
                              ),
                            ),
                            TermTextField(
                              labelText: w.notes,
                              controller: notes,
                              lines: 4,
                              keyboardType: TextInputType.multiline,
                              onChanged: (v) => draft.notes(v, w.language),
                            ),
                            TermSelect(
                              labelText: w.project,
                              value: t.project,
                              items: widget.console.projectChoices,
                              errorText: err['project'],
                              onChanged: (v) =>
                                  draft.edit(t.copyWith(project: v)),
                            ),
                            TermSelect(
                              labelText: w.assignee,
                              value: t.assignee,
                              items: [
                                for (final p in team)
                                  TermSelectItem(
                                    value: p.id,
                                    label: w.text(p.name),
                                  ),
                              ],
                              errorText: err['assignee'],
                              onChanged: (v) =>
                                  draft.edit(t.copyWith(assignee: v)),
                            ),
                            _DateLine(
                              label: w.due,
                              words: w,
                              value: t.due,
                              change: draft.setDue,
                              missing: draft.dueIncomplete,
                              error: err['due'],
                            ),
                            _Field(
                              w.estimate,
                              child: TermNumberField(
                                value: t.estimate.clamp(5, 480),
                                min: 5,
                                max: 480,
                                step: 5,
                                semanticLabel: w.estimate,
                                onChanged: (v) =>
                                    draft.edit(t.copyWith(estimate: v)),
                              ),
                            ),
                            _Field(
                              w.priority,
                              child: TermToggleGroup<Priority>(
                                options: Priority.values,
                                selected: {t.priority},
                                onSelectionChanged: (v) =>
                                    draft.edit(t.copyWith(priority: v.single)),
                                labelOf: w.priorityName,
                                semanticLabel: w.priority,
                              ),
                            ),
                            _Field(
                              w.labels,
                              child: RawChipGroup(
                                spacing: g.cellWidth,
                                runSpacing: 8,
                                children: [
                                  for (final l in Label.values)
                                    TermChip(
                                      label: w.labelName(l),
                                      selected: t.labels.contains(l),
                                      onSelected: (_) => draft.toggle(l),
                                    ),
                                ],
                              ),
                            ),
                            TermCheckbox(
                              label: w.done,
                              value: t.done,
                              onChanged: (v) => draft.edit(t.copyWith(done: v)),
                            ),
                            TermSwitch(
                              label: w.reminder,
                              value: t.reminder,
                              onChanged: (v) =>
                                  draft.edit(t.copyWith(reminder: v)),
                            ),
                            if (t.reminder)
                              _ClockLine(
                                label: w.reminderTime,
                                words: w,
                                minute: t.reminderMinute,
                                change: (v) =>
                                    draft.edit(t.copyWith(reminderMinute: v)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // The foot (the rule and Save) kept clear: toasts stand above it.
                RawToasterKeepClear(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const TermDivider(),
                      Padding(
                        padding: EdgeInsetsDirectional.symmetric(
                          horizontal: g.cellWidth,
                          vertical: 4,
                        ),
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TermButton.filled(
                            label: w.save,
                            onPressed: draft.dirty ? widget.console.save : null,
                            shortcut: SingleActivator(
                              LogicalKeyboardKey.keyS,
                              control:
                                  Theme.of(ctx).platform !=
                                  TargetPlatform.macOS,
                              meta:
                                  Theme.of(ctx).platform ==
                                  TargetPlatform.macOS,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _Field extends StatelessWidget {
  const _Field(this.label, {required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: TermTheme.of(context).dimStyle),
      child,
    ],
  );
}

/// Keep the editable subtree stable when a long validation message clears.
class _InputValidation extends StatelessWidget {
  const _InputValidation({required this.error, required this.child});
  final String? error;
  final Widget child;
  @override
  Widget build(BuildContext ctx) => Semantics(
    hint: error,
    validationResult: error == null
        ? SemanticsValidationResult.none
        : SemanticsValidationResult.invalid,
    child: child,
  );
}

class _Errors extends StatelessWidget {
  const _Errors(this.errors);
  final Map<String, String> errors;
  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    liveRegion: true,
    label: errors.values.join(' '),
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final message in errors.values)
            TermBanner(message: message, tone: TermTone.error),
        ],
      ),
    ),
  );
}

class _DateLine extends StatelessWidget {
  const _DateLine({
    required this.label,
    required this.words,
    required this.value,
    required this.change,
    this.missing = false,
    this.error,
  });
  final String label;
  final StintWords words;
  final DateTime value;
  final ValueChanged<DateTime?> change;
  final bool missing;
  final String? error;
  @override
  Widget build(BuildContext ctx) => TermDatePicker(
    labelText: label,
    value: value,
    firstDate: DateTime(2020),
    lastDate: DateTime(2040, 12, 31),
    currentDate: studyToday,
    errorText: error,
    onChanged: change,
  );
}

class _ClockLine extends StatelessWidget {
  const _ClockLine({
    required this.label,
    required this.words,
    required this.minute,
    required this.change,
  });
  final String label;
  final StintWords words;
  final int minute;
  final ValueChanged<int> change;
  @override
  Widget build(BuildContext ctx) {
    final value = TermTime(hour: minute ~/ 60, minute: minute % 60);
    void changed(TermTime v) => change(v.hour * 60 + v.minute);
    // The field's own help line is English; other languages go without it.
    return words.language != StintLanguage.en
        ? TermTimeField(
            labelText: label,
            value: value,
            helperText: null,
            onChanged: changed,
          )
        : TermTimeField(labelText: label, value: value, onChanged: changed);
  }
}
