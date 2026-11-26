part of '../stint_brutal.dart';

extension _Tasks on _StudioState {
  Widget tasks() => NavigatorPopHandler<void>(
    onPopWithResult: (_) => navigator.currentState?.maybePop(),
    // The routes keep nodes of their own, as the app's navigator's do. Under
    // a container that merges, a route's node comes only when a list opens
    // over it, and on the web the field's input moves into it and loses the
    // focus the tap just gave it.
    child: Semantics(
      explicitChildNodes: true,
      child: Navigator(
        key: navigator,
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (ctx, _, _) => ListenableBuilder(
            listenable: c,
            builder: (_, _) => LayoutBuilder(
              builder: (_, panes) {
                // Side by side, each pane has its own toaster: a notice
                // stands in the pane it is about, never across the seam.
                final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
                return RawListDetail<String>(
                  selectedItem: c.draft?.task.id,
                  onSelectedItemChanged: (id) {
                    if (id == null) c.openTask(null);
                  },
                  listWidth: 484,
                  // Beside the detail the list closes on a rule, as the rail does.
                  listBuilder: (ctx) => notices.list(
                    sideBySide: sideBySide,
                    child:
                        RawWindowSizeClass.of(ctx).index >=
                            RawWindowSizeClass.expanded.index
                        ? DecoratedBox(
                            position: DecorationPosition.foreground,
                            decoration: BoxDecoration(
                              border: BorderDirectional(
                                end: BorderSide(
                                  color: ctx.brutalTheme.colors.ink,
                                  width: ctx.brutalTheme.borderWidth,
                                ),
                              ),
                            ),
                            child: taskList(),
                          )
                        : taskList(),
                  ),
                  detailRouteBuilder: (build) =>
                      MaterialPageRoute<void>(builder: build),
                  detailBuilder: (_, id) => notices.detail(
                    sideBySide: sideBySide,
                    child: _Editor(key: ValueKey(id), studio: this, id: id),
                  ),
                  emptyDetailBuilder: (_) => BrutalScreen(
                    topBar: BrutalAppBar(title: w.taskDetail),
                    body: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 24,
                      children: [
                        Visibility(
                          visible: c.hasRowToOpen,
                          child: BrutalStateView(
                            state: BrutalState.empty,
                            icon: const Icon(LucideIcons.mousePointer2),
                            title: w.chooseTask,
                            message: w.chooseTaskHelp,
                          ),
                        ),
                        if (c.state == DataState.ready &&
                            c.openTasks.isNotEmpty)
                          BrutalListGroup(
                            header: w.byProject,
                            children: [
                              for (final p in projects)
                                BrutalListTile(
                                  title: w.text(p.name),
                                  subtitle: w.openTasks,
                                  trailing: Text(
                                    w.number(
                                      c.openTasks
                                          .where((t) => t.project == p.id)
                                          .length,
                                    ),
                                    style:
                                        context.brutalTheme.textTheme.headline,
                                  ),
                                  onTap: () => c.filter((f) {
                                    f.status = TaskStatus.open;
                                    f.project = p.id;
                                  }),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    ),
  );

  Widget taskList() {
    final result = c.visible, f = c.filters;
    final filtered = c.data.tasks.isNotEmpty && f.active;
    return BrutalPullToRefresh(
      onRefresh: c.refresh,
      child: BrutalScreen(
        topBar: bar(w.tasks, refresh: true),
        body: Column(
          key: const ValueKey('task-column'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            BrutalSearchField(
              controller: search,
              hintText: w.search,
              semanticLabel: w.search,
              clearLabel: w.clear,
              onChanged: (q) => c.filter((f) => f.search = q),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                BrutalButton(
                  f.count == 0
                      ? w.filters
                      : '${w.filters} (${w.number(f.count)})',
                  onPressed: filters,
                ),
                BrutalButton(
                  c.selecting ? w.stopSelecting : w.select,
                  onPressed: () => c.toggleSelection(),
                ),
              ],
            ),
            if (c.selecting)
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    w.selected(c.selected.length),
                    style: context.brutalTheme.textTheme.label,
                  ),
                  BrutalIconButton.plain(
                    icon: const Icon(LucideIcons.listChecks),
                    tooltip: w.selectAll,
                    onPressed: c.selectResults,
                  ),
                  if (c.selected.isNotEmpty) actionMenu(c.selected, w.actions),
                ],
              ),
            if (f.count > 0)
              RawChipGroup(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (f.status != TaskStatus.all)
                    filterChip(
                      w.statusName(f.status),
                      () => c.filter((f) => f.status = TaskStatus.all),
                    ),
                  if (f.project.isNotEmpty)
                    filterChip(
                      c.projectName(f.project),
                      () => c.filter((f) => f.project = ''),
                    ),
                  if (f.assignee.isNotEmpty)
                    filterChip(
                      c.personName(f.assignee),
                      () => c.filter((f) => f.assignee = ''),
                    ),
                ],
              ),
            loaded(
              () => result.isEmpty
                  ? BrutalStateView(
                      state: BrutalState.empty,
                      title: filtered ? w.noMatches : w.noTasks,
                      message: filtered ? w.searchHelp : w.allClear,
                      actions: [
                        if (filtered) BrutalButton(w.reset, onPressed: reset),
                      ],
                    )
                  : BrutalListGroup(
                      key: const ValueKey('task-rows'),
                      header: w.totalTasks(result.length),
                      children: [for (final t in result) row(t)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  BrutalChip filterChip(String value, VoidCallback remove) => BrutalChip(
    label: value,
    selected: true,
    icon: LucideIcons.x,
    onSelected: (_) => remove(),
  );
  void reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget row(Task t) {
    final ids = {t.id};
    final tile = BrutalListTile(
      title: w.text(t.title),
      subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
      selected: c.selecting
          ? c.selected.contains(t.id)
          : c.draft?.task.id == t.id,
      onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
      showChevron: false,
    );
    return ColoredBox(
      color: context.brutalTheme.colors.surface,
      child: Row(
        children: [
          Expanded(
            child: c.selecting
                ? tile
                : BrutalSwipeRow(
                    key: ValueKey(t.id),
                    startActions: [
                      BrutalSwipeAction(
                        label: t.done ? w.reopen : w.complete,
                        icon: LucideIcons.check,
                        onPressed: () => change(
                          ids,
                          () => c.changeTasks(ids, done: !t.done),
                        ),
                      ),
                    ],
                    endActions: [
                      BrutalSwipeAction(
                        label: w.delete,
                        icon: LucideIcons.trash2,
                        isDestructiveAction: true,
                        onPressed: () => remove(ids),
                      ),
                    ],
                    child: tile,
                  ),
          ),
          if (c.selecting)
            BrutalCheckbox(
              value: c.selected.contains(t.id),
              semanticLabel: w.text(t.title),
              onChanged: (_) => c.toggleSelection(t.id),
            )
          else
            actionMenu(ids, '${w.actions}${w.dot}${t.id}'),
        ],
      ),
    );
  }

  Future<void> change(Set<String> ids, VoidCallback action) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) action();
  }

  void remove(Set<String> ids) => change(ids, () {
    final removed = c.deleteTasks(ids);
    showBrutalToast(
      notices.forList(context),
      w.deleted,
      actionLabel: w.undo,
      onAction: () => c.undoDelete(removed),
    );
  });

  Widget actionMenu(Set<String> ids, String label) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return BrutalMenu(
      semanticLabel: label,
      alignEnd: true,
      builder: (_, toggle, _) => BrutalIconButton.plain(
        icon: const Icon(LucideIcons.ellipsis),
        tooltip: label,
        onPressed: toggle,
      ),
      items: [
        BrutalMenuItem(
          label: done ? w.reopen : w.complete,
          icon: LucideIcons.check,
          onPressed: () => change(ids, () => c.changeTasks(ids, done: !done)),
        ),
        BrutalMenuItem(
          label: w.move,
          icon: LucideIcons.folderInput,
          onPressed: () async {
            final p = await showBrutalActionSheet<String>(
              context: context,
              title: w.move,
              cancelLabel: w.cancel,
              actions: [
                for (final p in projects)
                  BrutalSheetAction(label: w.text(p.name), value: p.id),
              ],
            );
            if (p != null && mounted) {
              await change(ids, () => c.changeTasks(ids, project: p));
            }
          },
        ),
        BrutalMenuItem(
          label: w.delete,
          icon: LucideIcons.trash2,
          isDestructiveAction: true,
          onPressed: () => remove(ids),
        ),
      ],
    );
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        project = f.project,
        person = f.assignee,
        sort = f.sort;
    await _raise<void>(
      context,
      (ctx) => BrutalSheet(
        title: w.filters,
        onClose: () => Navigator.of(ctx).pop(),
        child: StatefulBuilder(
          builder: (ctx, set) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              BrutalSelect(
                labelText: w.status,
                items: [
                  for (final s in TaskStatus.values)
                    BrutalSelectItem(value: s, label: w.statusName(s)),
                ],
                value: status,
                onChanged: (v) => set(() => status = v),
              ),
              BrutalSelect(
                labelText: w.project,
                items: [
                  BrutalSelectItem(value: '', label: w.all),
                  ...projectItems,
                ],
                value: project,
                onChanged: (v) => set(() => project = v),
              ),
              BrutalSelect(
                labelText: w.assignee,
                items: [
                  BrutalSelectItem(value: '', label: w.all),
                  for (final p in team)
                    BrutalSelectItem(value: p.id, label: w.text(p.name)),
                ],
                value: person,
                onChanged: (v) => set(() => person = v),
              ),
              BrutalSelect(
                labelText: w.sort,
                items: [
                  for (final s in TaskSort.values)
                    BrutalSelectItem(value: s, label: w.sortName(s)),
                ],
                value: sort,
                onChanged: (v) => set(() => sort = v),
              ),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  BrutalButton.filled(
                    w.apply,
                    onPressed: () {
                      c.filter((f) {
                        f.status = status;
                        f.project = project;
                        f.assignee = person;
                        f.sort = sort;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                  BrutalButton(
                    w.reset,
                    onPressed: () {
                      reset();
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<BrutalSelectItem<String>> get projectItems => [
    for (final p in projects)
      BrutalSelectItem(value: p.id, label: w.text(p.name)),
  ];
}

/// A short task sheet (Start a timer, Filters, Add entry): on a phone it
/// rises from the foot, edge to edge; from 600 px it stands framed in the
/// middle of the window, as Commands does, rather than hanging from the
/// window's foot.
Future<T?> _raise<T>(BuildContext context, WidgetBuilder sheet) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showBrutalSheet<T>(context: context, builder: sheet);
  }
  return showBrutalDialog<T>(
    context: context,
    builder: (ctx) => ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 480,
        maxHeight: MediaQuery.sizeOf(ctx).height * 0.8,
      ),
      child: sheet(ctx),
    ),
  );
}
