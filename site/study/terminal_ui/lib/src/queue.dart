part of '../stint_terminal.dart';

extension _Queue on _ConsoleState {
  List<TermSelectItem<String>> get projectChoices => [
    for (final p in projects)
      TermSelectItem(value: p.id, label: w.text(p.name)),
  ];
  Widget filterTag(
    String label,
    VoidCallback clear, {
    TermTone tone = TermTone.neutral,
  }) => TermTag(label: label, tone: tone, onDeleted: clear);
  Widget queue() => NavigatorPopHandler<void>(
    onPopWithResult: (_) => navigator.currentState?.maybePop(),
    // The routes keep nodes of their own, as the app's navigator's do. Under
    // a container that merges, a route's node comes only when a list opens
    // over it, and on the web the field's input moves into it and loses the
    // focus the tap just gave it.
    child: Semantics(
      explicitChildNodes: true,
      child: Navigator(
        key: navigator,
        onGenerateRoute: (_) => TermPageRoute<void>(
          builder: (ctx) => ListenableBuilder(
            listenable: c,
            builder: (ctx, _) => LayoutBuilder(
              builder: (_, panes) {
                // Side by side, each pane has its own toaster: a notice
                // stands in the pane it is about, never across the seam.
                final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
                return RawListDetail<String>(
                  sideBySide: MediaQuery.sizeOf(ctx).width >= 1100,
                  // At 1380 and up the list takes a row's whole line: the title in
                  // its 30 cells (the longest, 27, and its mark) and the project
                  // and date beside it (24), neither cut. At 520 the row's three
                  // fifths cut both.
                  listWidth: MediaQuery.sizeOf(ctx).width >= 1380 ? 600 : 320,
                  selectedItem: c.draft?.task.id,
                  onSelectedItemChanged: (id) {
                    if (id == null) c.openTask(null);
                  },
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: queueList()),
                  detailBuilder: (_, id) => notices.detail(
                    sideBySide: sideBySide,
                    child: _Editor(key: ValueKey(id), console: this, id: id),
                  ),
                  detailRouteBuilder: (build) =>
                      TermPageRoute<void>(builder: build),
                  emptyDetailBuilder: (_) => _Page(
                    children: [
                      // The ask stands only beside a row to open; with none, its
                      // pane is left out rather than drawn as an empty box one
                      // line tall.
                      if (c.hasRowToOpen)
                        TermPane(
                          title: w.taskDetail,
                          child: TermEmptyState(
                            glyph: '>',
                            title: w.chooseTask,
                            message: w.chooseTaskHelp,
                          ),
                        ),
                      if (c.state == DataState.ready && c.data.tasks.isNotEmpty)
                        TermPane(
                          title: w.byProject,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final p in projects)
                                _Line(
                                  name: w.text(p.name),
                                  meta:
                                      '${w.number(c.openTasks.where((t) => t.project == p.id).length)}${w.dot}${w.openTasks}',
                                  mark: '#',
                                  onOpen: () => c.filter((f) {
                                    f.status = TaskStatus.open;
                                    f.project = p.id;
                                  }),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
  void reset() {
    query.clear();
    c.filter((f) => f.reset());
  }

  Widget queueList() {
    final f = c.filters,
        list = c.visible,
        empty = f.active && c.data.tasks.isNotEmpty;
    return TermPullToRefresh(
      onRefresh: c.refresh,
      child: _Page(
        children: [
          _Heading(w.tasks),
          TermTextField(
            key: const ValueKey('search-tasks'),
            labelText: w.search,
            prompt: '/',
            controller: query,
            textInputAction: TextInputAction.search,
            onChanged: (v) => c.filter((f) => f.search = v),
          ),
          Wrap(
            spacing: context.termGrid.cellWidth,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              TermButton(
                label: f.count == 0
                    ? w.filters
                    : '${w.filters} (${w.number(f.count)})',
                onPressed: filterQueue,
              ),
              TermButton(
                label: c.selecting ? w.stopSelecting : w.select,
                onPressed: () => c.toggleSelection(),
              ),
              TermButton(label: w.refresh, onPressed: c.refresh),
            ],
          ),
          if (f.count > 0)
            RawChipGroup(
              spacing: context.termGrid.cellWidth,
              runSpacing: 8,
              children: [
                if (f.status != TaskStatus.all)
                  filterTag(
                    w.statusName(f.status),
                    () => c.filter((v) => v.status = TaskStatus.all),
                    tone: TermTone.info,
                  ),
                if (f.project.isNotEmpty)
                  filterTag(
                    c.projectName(f.project),
                    () => c.filter((v) => v.project = ''),
                  ),
                if (f.assignee.isNotEmpty)
                  filterTag(
                    c.personName(f.assignee),
                    () => c.filter((v) => v.assignee = ''),
                  ),
              ],
            ),
          if (c.selecting)
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(w.selected(c.selected.length), style: ink.boldStyle),
                TermLink(label: w.selectAll, onPressed: c.selectResults),
                if (c.selected.isNotEmpty) menu(c.selected, w.actions),
              ],
            ),
          content(
            () => list.isEmpty
                ? TermPane(
                    child: TermEmptyState(
                      title: empty ? w.noMatches : w.noTasks,
                      message: empty ? w.searchHelp : w.allClear,
                      action: empty
                          ? TermButton(label: w.reset, onPressed: reset)
                          : null,
                    ),
                  )
                : TermPane(
                    key: const ValueKey('task-rows'),
                    title: w.totalTasks(list.length),
                    padding: TermInset.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, t) in list.indexed) ...[
                          if (i > 0) const TermDivider(),
                          row(t),
                        ],
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget row(Task t) {
    final title = w.text(t.title),
        meta = '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}';
    return _Line(
      name: title,
      meta: meta,
      mark: t.done ? '✓' : '·',
      titleCols: MediaQuery.sizeOf(context).width >= 1380 ? 30 : null,
      onOpen: () => c.selecting ? c.toggleSelection(t.id) : open(t),
      selected: c.selecting
          ? c.selected.contains(t.id)
          : c.draft?.task.id == t.id,
      accessibleName:
          '$title, ${c.projectName(t.project)}, ${w.shortDate(t.due)}',
      action: c.selecting
          ? TermCheckbox(
              value: c.selected.contains(t.id),
              semanticLabel: title,
              onChanged: (_) => c.toggleSelection(t.id),
            )
          : menu({t.id}, '${w.actions}${w.dot}${t.id}'),
    );
  }

  Widget menu(Set<String> targets, String name) {
    final ids = Set.of(targets),
        done = c.data.tasks
            .where((t) => targets.contains(t.id))
            .every((t) => t.done);
    Future<bool> mayChange() async =>
        !ids.contains(c.draft?.task.id) || await leave();
    return TermMenu(
      semanticLabel: name,
      anchorBuilder: (ctx, a) => act('⋯', name, a.toggle),
      items: [
        TermMenuItem(
          label: done ? w.reopen : w.complete,
          onPressed: () async {
            if (await mayChange() && mounted) c.changeTasks(ids, done: !done);
          },
        ),
        TermMenuItem(
          label: w.move,
          onPressed: () async {
            if (!await mayChange() || !mounted) return;
            final project = await showTermActionSheet<String>(
              context: context,
              title: w.move,
              cancelLabel: w.cancel,
              actions: [
                for (final p in projects)
                  TermSheetAction(value: p.id, label: w.text(p.name)),
              ],
            );
            if (mounted && project != null) {
              c.changeTasks(ids, project: project);
            }
          },
        ),
        TermMenuItem(
          label: w.delete,
          isDestructiveAction: true,
          onPressed: () async {
            if (!await mayChange() || !mounted) return;
            final deleted = c.deleteTasks(ids);
            TermToaster.show(
              notices.forList(context),
              message: w.deleted,
              actionLabel: w.undo,
              onAction: () => c.undoDelete(deleted),
              duration: const Duration(seconds: 8),
            );
          },
        ),
      ],
    );
  }

  Future<void> filterQueue() async {
    final f = c.filters;
    var status = f.status,
        project = f.project,
        assignee = f.assignee,
        sort = f.sort;
    final result = await _raise<bool>(
      context: context,
      semanticLabel: w.filters,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => _Panel(
          title: w.filters,
          footer: 'Esc${w.dot}${w.cancel}',
          actions: [
            TermButton.filled(
              label: w.apply,
              onPressed: () => Navigator.pop(ctx, true),
            ),
            TermButton(
              label: w.reset,
              onPressed: () => Navigator.pop(ctx, false),
            ),
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              TermSelect.inline(
                labelCols: 11,
                labelText: w.status,
                value: status,
                items: [
                  for (final s in TaskStatus.values)
                    TermSelectItem(value: s, label: w.statusName(s)),
                ],
                onChanged: (v) => set(() => status = v),
              ),
              TermSelect.inline(
                labelCols: 11,
                labelText: w.project,
                value: project,
                items: [
                  TermSelectItem(value: '', label: w.all),
                  ...projectChoices,
                ],
                onChanged: (v) => set(() => project = v),
              ),
              TermSelect.inline(
                labelCols: 11,
                labelText: w.assignee,
                value: assignee,
                items: [
                  TermSelectItem(value: '', label: w.all),
                  for (final p in team)
                    TermSelectItem(value: p.id, label: w.text(p.name)),
                ],
                onChanged: (v) => set(() => assignee = v),
              ),
              TermSelect.inline(
                labelCols: 11,
                labelText: w.sort,
                value: sort,
                items: [
                  for (final s in TaskSort.values)
                    TermSelectItem(value: s, label: w.sortName(s)),
                ],
                onChanged: (v) => set(() => sort = v),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || result == null) return;
    if (!result) {
      reset();
      return;
    }
    c.filter((f) {
      f.status = status;
      f.project = project;
      f.assignee = assignee;
      f.sort = sort;
    });
  }
}
