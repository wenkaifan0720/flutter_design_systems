part of '../stint_cupertino.dart';

extension _Tasks on _Desk {
  Widget tasks(bool wide) {
    final draft = c.draft;
    final editor = draft == null
        ? Visibility(
            visible: c.hasRowToOpen,
            child: Center(child: Text(w.chooseTask)),
          )
        : _Editor(this, draft, key: ValueKey(draft.task.id));
    if (!wide) return draft == null ? list() : editor;
    return Row(
      children: [
        // One width whether a task is open or not: it narrowed by 28 when
        // one opened, so the list jumped under the pointer.
        SizedBox(width: 342, child: FocusTraversalGroup(child: list())),
        Expanded(child: FocusTraversalGroup(child: editor)),
      ],
    );
  }

  Widget list() {
    final tasks = c.visible;
    return CustomScrollView(
      primary: false,
      slivers: [
        CupertinoSliverRefreshControl(onRefresh: c.refresh),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 0),
            // The clear key stands over the field, a node of its own: the
            // field's own clear key, appearing inside the field's node on
            // the first key, split it in two, and the web set up a new
            // input that dropped the keys and the focus.
            child: Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                CupertinoSearchTextField(
                  controller: search,
                  placeholder: w.search,
                  suffixMode: OverlayVisibilityMode.never,
                  padding: const EdgeInsetsDirectional.fromSTEB(5.5, 8, 30, 8),
                  onChanged: (v) => c.filter((f) => f.search = v),
                ),
                if (search.text.isNotEmpty)
                  Semantics(
                    container: true,
                    label: w.clear,
                    child: CupertinoButton(
                      padding: const EdgeInsetsDirectional.only(end: 5),
                      minimumSize: const Size(30, 30),
                      onPressed: () {
                        search.clear();
                        c.filter((f) => f.search = '');
                      },
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        size: 20,
                        color: _secondaryInk(context),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                CupertinoButton(onPressed: filters, child: Text(w.filters)),
                CupertinoButton(
                  child: Text(c.selecting ? w.stopSelecting : w.select),
                  onPressed: () => c.toggleSelection(),
                ),
                _IconButton(w.refresh, CupertinoIcons.refresh, c.refresh),
              ],
            ),
          ),
        ),
        if (c.selecting)
          SliverToBoxAdapter(
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(w.selected(c.selected.length)),
                CupertinoButton(
                  onPressed: c.selectResults,
                  child: Text(w.selectAll),
                ),
                if (c.selected.isNotEmpty) actions(c.selected),
              ],
            ),
          ),
        if (removed.isNotEmpty)
          SliverToBoxAdapter(
            child: _RowTile(
              title: Text(w.deleted),
              trailing: CupertinoButton(
                onPressed: () {
                  c.undoDelete(removed);
                  removed = [];
                },
                child: Text(w.undo),
              ),
            ),
          ),
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            hasLeading: false,
            margin: EdgeInsets.symmetric(
              horizontal: c.settings.compact ? 8 : 16,
              vertical: c.settings.compact ? 4 : 10,
            ),
            children: [
              if (tasks.isEmpty)
                _RowTile(
                  title: Text(c.data.tasks.isEmpty ? w.noTasks : w.noMatches),
                  subtitle: Text(
                    c.data.tasks.isEmpty ? w.allClear : w.searchHelp,
                  ),
                  onTap: c.filters.active && c.data.tasks.isNotEmpty
                      ? () {
                          search.clear();
                          c.filter((f) => f.reset());
                        }
                      : null,
                ),
              for (final task in tasks)
                _RowTile(
                  title: Text(w.text(task.title)),
                  subtitle: Text(
                    '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due)}',
                  ),
                  additionalInfo: c.selecting
                      ? Icon(
                          c.selected.contains(task.id)
                              ? CupertinoIcons.check_mark_circled_solid
                              : CupertinoIcons.circle,
                        )
                      : null,
                  selected: !c.selecting && c.draft?.task.id == task.id,
                  rowAction: c.selecting ? null : actions({task.id}),
                  onTap: () =>
                      c.selecting ? c.toggleSelection(task.id) : open(task),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        assignee = f.assignee;
    Widget form(BuildContext ctx, ScrollController? scroll) => StatefulBuilder(
      builder: (ctx, change) => CupertinoPageScaffold(
        backgroundColor: CupertinoColors.systemGroupedBackground,
        navigationBar: CupertinoNavigationBar(
          middle: Text(w.filters),
          leading: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(w.cancel),
            onPressed: () => Navigator.pop(ctx),
          ),
          trailing: CupertinoButton(
            padding: EdgeInsets.zero,
            child: Text(w.apply),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ),
        child: SafeArea(
          child: ListView(
            controller: scroll,
            children: [
              CupertinoListSection.insetGrouped(
                hasLeading: false,
                children: [
                  _SettingRow(w.status, w.statusName(status), () async {
                    final v = await choose(w.status, {
                      for (final s in TaskStatus.values) s: w.statusName(s),
                    }, value: status);
                    if (ctx.mounted && v != null) change(() => status = v);
                  }),
                  _SettingRow(
                    w.project,
                    project.isEmpty ? w.all : c.projectName(project),
                    () async {
                      final v = await choose(w.project, {
                        '': w.all,
                        for (final p in projects) p.id: w.text(p.name),
                      }, value: project);
                      if (ctx.mounted && v != null) change(() => project = v);
                    },
                  ),
                  _SettingRow(
                    w.assignee,
                    assignee.isEmpty ? w.all : c.personName(assignee),
                    () async {
                      final v = await choose(
                        w.assignee,
                        {'': w.all, for (final p in team) p.id: w.text(p.name)},
                        value: assignee,
                        searchable: true,
                      );
                      if (ctx.mounted && v != null) {
                        change(() => assignee = v);
                      }
                    },
                  ),
                  _SettingRow(w.sort, w.sortName(sort), () async {
                    final v = await choose(w.sort, {
                      for (final s in TaskSort.values) s: w.sortName(s),
                    }, value: sort);
                    if (ctx.mounted && v != null) change(() => sort = v);
                  }),
                ],
              ),
              CupertinoButton(
                child: Text(w.reset),
                onPressed: () => change(() {
                  status = TaskStatus.all;
                  sort = TaskSort.due;
                  project = '';
                  assignee = '';
                }),
              ),
            ],
          ),
        ),
      ),
    );
    final ok = await _present<bool>(context, height: 420, form);
    if (ok == true && mounted) {
      c.filter((f) {
        f.status = status;
        f.sort = sort;
        f.project = project;
        f.assignee = assignee;
      });
    }
  }

  Future<void> changeRows(Set<String> ids, VoidCallback act) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) act();
  }

  Widget actions(Set<String> ids) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return CupertinoMenuAnchor(
      builder: (ctx, ctrl, _) => _IconButton(
        '${w.actions}${w.dot}${ids.length == 1 ? ids.first : w.number(ids.length)}',
        CupertinoIcons.ellipsis_circle,
        ctrl.open,
      ),
      menuChildren: [
        // A pull-down's items carry their symbol at the trailing end;
        // Delete in the destructive red.
        CupertinoMenuItem(
          trailing: Icon(
            done
                ? CupertinoIcons.arrow_uturn_left
                : CupertinoIcons.checkmark_circle,
          ),
          child: Text(done ? w.reopen : w.complete),
          onPressed: () =>
              changeRows(ids, () => c.changeTasks(ids, done: !done)),
        ),
        CupertinoMenuItem(
          trailing: const Icon(CupertinoIcons.folder),
          child: Text(w.move),
          onPressed: () async {
            final v = await choose(w.project, {
              for (final p in projects) p.id: w.text(p.name),
            });
            if (mounted && v != null) {
              await changeRows(ids, () => c.changeTasks(ids, project: v));
            }
          },
        ),
        CupertinoMenuItem(
          isDestructiveAction: true,
          trailing: const Icon(CupertinoIcons.trash),
          child: Text(w.delete),
          onPressed: () => changeRows(ids, () {
            removed = c.deleteTasks(ids);
          }),
        ),
      ],
    );
  }
}

class _Editor extends StatefulWidget {
  const _Editor(this.desk, this.draft, {super.key});
  final _Desk desk;
  final TaskDraft draft;
  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late final scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  _Desk get desk => widget.desk;
  TaskDraft get draft => widget.draft;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: draft,
    builder: (context, _) {
      final c = desk.c,
          w = c.words,
          t = draft.task,
          errors = draft.submitted ? draft.errors(w) : const <String, String>{};
      return ListView(
        controller: scroll,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.only(bottom: 16),
            hasLeading: false,
            header: Text(t.id),
            children: [
              _Input(
                w.title,
                w.text(t.title),
                (v) => draft.title(v, w.language),
                error: errors['title'],
              ),
              _Input(
                w.notes,
                w.text(t.notes),
                (v) => draft.notes(v, w.language),
                lines: 3,
              ),
              _SettingRow(w.project, c.projectName(t.project), () async {
                final v = await desk.choose(w.project, {
                  for (final p in projects) p.id: w.text(p.name),
                }, value: t.project);
                if (context.mounted && v != null) {
                  draft.edit(t.copyWith(project: v));
                }
              }),
              _SettingRow(w.assignee, c.personName(t.assignee), () async {
                final v = await desk.choose(
                  w.assignee,
                  {for (final p in team) p.id: w.text(p.name)},
                  value: t.assignee,
                  searchable: true,
                );
                if (context.mounted && v != null) {
                  draft.edit(t.copyWith(assignee: v));
                }
              }),
              _SettingRow(w.due, w.shortDate(t.due), () async {
                final v = await _pick(context, w, t.due);
                if (context.mounted && v != null) draft.setDue(v);
              }),
              _Input(
                w.estimate,
                w.number(t.estimate),
                (v) => draft.edit(t.copyWith(estimate: w.parseMinutes(v) ?? 0)),
                numeric: true,
                error: errors['estimate'],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 8,
                    children: [
                      Text(w.priority),
                      CupertinoSlidingSegmentedControl<Priority>(
                        groupValue: t.priority,
                        children: {
                          for (final v in Priority.values)
                            v: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Text(w.priorityName(v)),
                            ),
                        },
                        onValueChanged: (v) {
                          if (v != null) draft.edit(t.copyWith(priority: v));
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.only(bottom: 16),
            header: Text(w.labels),
            hasLeading: false,
            children: [
              for (final l in Label.values)
                _RowTile(
                  title: Text(w.labelName(l)),
                  checked: t.labels.contains(l),
                  trailing: t.labels.contains(l)
                      ? Icon(
                          CupertinoIcons.check_mark,
                          color: CupertinoTheme.of(context).primaryColor,
                        )
                      : null,
                  onTap: () => draft.toggle(l),
                ),
            ],
          ),
          CupertinoListSection.insetGrouped(
            margin: const EdgeInsets.only(bottom: 16),
            hasLeading: false,
            children: [
              _RowTile(
                title: Text(w.done),
                trailing: CupertinoSwitch(
                  value: t.done,
                  onChanged: (v) => draft.edit(t.copyWith(done: v)),
                ),
              ),
              _RowTile(
                title: Text(w.reminder),
                trailing: CupertinoSwitch(
                  value: t.reminder,
                  onChanged: (v) => draft.edit(t.copyWith(reminder: v)),
                ),
              ),
              if (t.reminder)
                _SettingRow(
                  w.reminderTime,
                  w.clock(t.reminderMinute),
                  () async {
                    final v = await _pick(
                      context,
                      w,
                      DateTime(
                        2026,
                        11,
                        20,
                        t.reminderMinute ~/ 60,
                        t.reminderMinute % 60,
                      ),
                      time: true,
                    );
                    if (context.mounted && v != null) {
                      draft.edit(
                        t.copyWith(reminderMinute: v.hour * 60 + v.minute),
                      );
                    }
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: draft.dirty
                ? CupertinoButton.filled(
                    onPressed: desk.save,
                    child: Text(w.save),
                  )
                : Semantics(
                    liveRegion: true,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 6,
                        children: [
                          const Icon(CupertinoIcons.check_mark),
                          Flexible(child: Text(w.saved)),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      );
    },
  );
}

class _Input extends StatefulWidget {
  const _Input(
    this.label,
    this.initial,
    this.edit, {
    this.lines = 1,
    this.numeric = false,
    this.error,
  });
  final String label, initial;
  final String? error;
  final ValueChanged<String> edit;
  final int lines;
  final bool numeric;
  @override
  State<_Input> createState() => _InputState();
}

class _InputState extends State<_Input> {
  late final controller = TextEditingController(text: widget.initial);
  @override
  void didUpdateWidget(_Input oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initial != widget.initial &&
        controller.text != widget.initial) {
      controller.value = TextEditingValue(
        text: widget.initial,
        selection: TextSelection.collapsed(offset: widget.initial.length),
      );
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        // Named once: seen above the field, heard on the field.
        ExcludeSemantics(
          child: Text(
            widget.label,
            style: CupertinoTheme.of(context).textTheme.textStyle.copyWith(
              color: CupertinoColors.secondaryLabel.resolveFrom(context),
            ),
          ),
        ),
        Semantics(
          label: widget.label,
          textField: true,
          child: CupertinoTextField.borderless(
            controller: controller,
            padding: EdgeInsets.zero,
            minLines: widget.lines,
            maxLines: widget.lines == 1 ? 1 : 8,
            keyboardType: widget.numeric ? TextInputType.number : null,
            inputFormatters: widget.numeric
                ? [FilteringTextInputFormatter.allow(RegExp('[0-9٠-٩０-９]'))]
                : null,
            onChanged: widget.edit,
          ),
        ),
        if (widget.error != null)
          Semantics(
            liveRegion: true,
            child: Text(
              widget.error!,
              style: const TextStyle(color: CupertinoColors.systemRed),
            ),
          ),
      ],
    ),
  );
}
