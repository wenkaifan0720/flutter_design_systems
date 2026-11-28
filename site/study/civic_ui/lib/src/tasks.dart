part of '../stint_civic.dart';

enum _Action { status, move, delete }

extension _TasksService on _ServiceState {
  List<CivicSelectItem<String>> get projectOptions => [
    for (final p in projects)
      CivicSelectItem(value: p.id, label: w.text(p.name)),
  ];

  Widget taskService() => NavigatorPopHandler<void>(
    onPopWithResult: (_) => records.currentState?.maybePop(),
    // The routes keep nodes of their own, as the app's navigator's do. Under
    // a container that merges, a route's node comes only when a list opens
    // over it, and on the web the field's input moves into it and loses the
    // focus the tap just gave it.
    child: Semantics(
      explicitChildNodes: true,
      child: Navigator(
        key: records,
        onGenerateRoute: (_) => CivicPageRoute<void>(
          builder: (_) => ListenableBuilder(
            listenable: c,
            builder: (ctx, _) => ColoredBox(
              color: ctx.civicTheme.ground,
              child: LayoutBuilder(
                builder: (_, panes) {
                  // Side by side, each pane has its own toaster: a notice
                  // stands in the pane it is about, never across the seam.
                  final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
                  return RawListDetail<String>(
                    selectedItem: c.draft?.task.id,
                    onSelectedItemChanged: (v) {
                      if (v == null) c.openTask(null);
                    },
                    // The page's margins take 80 of it: at 396 a row's title had
                    // about 250 and most wrapped beside a wider empty pane.
                    listWidth: 460,
                    sideBySide: !CivicLayout.isApp(
                      MediaQuery.sizeOf(ctx).width,
                    ),
                    listBuilder: (_) =>
                        notices.list(sideBySide: sideBySide, child: taskList()),
                    // Beside an empty, unmatched or failed list there is nothing to open.
                    emptyDetailBuilder: (_) => Visibility(
                      visible: c.hasRowToOpen,
                      child: CivicPageBody(
                        title: w.chooseTask,
                        children: [
                          CivicInset(child: Text(w.chooseTaskHelp)),
                          if (c.state == DataState.ready &&
                              c.data.tasks.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            CivicSectionHeader(title: w.byProject),
                            CivicListGroup(
                              children: [
                                for (final p in projects)
                                  CivicListRow(
                                    title: Text(w.text(p.name)),
                                    subtitle: Text(
                                      '${w.openTasks}${w.dot}${w.number(c.openTasks.where((t) => t.project == p.id).length)}',
                                    ),
                                    onTap: () => c.filter((f) {
                                      f.project = p.id;
                                      f.status = TaskStatus.open;
                                    }),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    detailBuilder: (_, id) => notices.detail(
                      sideBySide: sideBySide,
                      child: _TaskForm(
                        key: ValueKey(id),
                        service: this,
                        id: id,
                      ),
                    ),
                    detailRouteBuilder: (build) => CivicPageRoute<void>(
                      builder: (ctx) => ColoredBox(
                        color: ctx.civicTheme.ground,
                        child: build(ctx),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ),
  );

  void reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget taskList() {
    final f = c.filters,
        results = c.visible,
        noMatches = f.active && c.data.tasks.isNotEmpty;
    return CivicPageBody(
      title: w.tasks,
      children: [
        CivicSearchField(
          key: const ValueKey('search-tasks'),
          controller: search,
          labelText: w.search,
          buttonLabel: w.search,
          onSubmitted: (v) => c.filter((f) => f.search = v),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            CivicLink(
              onPressed: filters,
              child: Text(
                f.count == 0
                    ? w.filters
                    : '${w.filters} (${w.number(f.count)})',
              ),
            ),
            CivicLink(
              onPressed: () => c.toggleSelection(),
              child: Text(c.selecting ? w.stopSelecting : w.select),
            ),
            icon(LucideIcons.refreshCw, w.refresh, c.refresh),
          ],
        ),
        if (f.count > 0)
          RawChipGroup(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (f.status != TaskStatus.all)
                CivicTag(label: w.statusName(f.status), tone: CivicTone.info),
              if (f.project.isNotEmpty)
                CivicTag(label: c.projectName(f.project)),
              if (f.assignee.isNotEmpty)
                CivicTag(label: c.personName(f.assignee)),
            ],
          ),
        const SizedBox(height: 20),
        if (c.selecting)
          Wrap(
            spacing: 12,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                w.selected(c.selected.length),
                style: context.civicText.label,
              ),
              CivicLink(onPressed: c.selectResults, child: Text(w.selectAll)),
              if (c.selected.isNotEmpty) actionMenu(c.selected, w.actions),
            ],
          ),
        load(
          () => results.isEmpty
              ? CivicEmptyState(
                  title: noMatches ? w.noMatches : w.noTasks,
                  actions: [
                    if (noMatches)
                      CivicLink(onPressed: reset, child: Text(w.reset)),
                  ],
                  children: [Text(noMatches ? w.searchHelp : w.allClear)],
                )
              : Column(
                  key: const ValueKey('task-rows'),
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CivicListGroup(
                      title: w.totalTasks(results.length),
                      children: [for (final task in results) taskRow(task)],
                    ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget taskRow(Task t) {
    final title = w.text(t.title),
        desc = '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}';
    final selected = c.selecting
        ? c.selected.contains(t.id)
        : c.draft?.task.id == t.id;
    if (c.selecting) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: CivicCheckbox(
          value: selected,
          labelText: title,
          helperText: desc,
          onChanged: (_) => c.toggleSelection(t.id),
        ),
      );
    }
    return ColoredBox(
      color: selected
          ? context.civicTheme.secondaryFill
          : context.civicTheme.background,
      child: Row(
        children: [
          Expanded(
            child: CivicListRow(
              title: Text(title),
              subtitle: Text(desc),
              showChevron: false,
              showRule: false,
              selected: selected,
              semanticLabel:
                  '$title, ${c.projectName(t.project)}, ${w.shortDate(t.due)}',
              onTap: () => record(t),
            ),
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 4),
            child: actionMenu({t.id}, '${w.actions}${w.dot}${t.id}'),
          ),
        ],
      ),
    );
  }

  // The task's lesser actions, in Civic's menu from its ⋯ key; each is also
  // on the task's own page.
  Widget actionMenu(Set<String> targets, String name) {
    final ids = Set.of(targets);
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return CivicMenu<_Action>(
      semanticLabel: name,
      align: RawPopoverAlign.end,
      items: [
        CivicMenuItem(
          value: _Action.status,
          label: done ? w.reopen : w.complete,
          icon: LucideIcons.circleCheck,
        ),
        CivicMenuItem(
          value: _Action.move,
          label: w.move,
          icon: LucideIcons.folderInput,
        ),
        CivicMenuItem(
          value: _Action.delete,
          label: w.delete,
          icon: LucideIcons.trash2,
          isDestructiveAction: true,
          startsGroup: true,
        ),
      ],
      onSelected: (action) => act(ids, done, action),
      builder: (ctx, anchor) => icon(LucideIcons.ellipsis, name, anchor.toggle),
    );
  }

  Future<void> act(Set<String> ids, bool done, _Action action) async {
    if (!mounted) return;
    if (ids.contains(c.draft?.task.id) && !await canLeave()) return;
    if (!mounted) return;
    switch (action) {
      case _Action.status:
        c.changeTasks(ids, done: !done);
      case _Action.move:
        final chosen = await showCivicDialog<String>(
          context: context,
          builder: (ctx) => CivicDialog(
            title: w.move,
            actions: [
              CivicButton.secondary(
                onPressed: () => Navigator.pop(ctx),
                child: Text(w.cancel),
              ),
            ],
            content: CivicListGroup(
              children: [
                for (final p in projects)
                  CivicListRow(
                    title: Text(w.text(p.name)),
                    onTap: () => Navigator.pop(ctx, p.id),
                  ),
              ],
            ),
          ),
        );
        if (chosen != null && mounted) c.changeTasks(ids, project: chosen);
      case _Action.delete:
        final removed = c.deleteTasks(ids);
        CivicToast.show(
          notices.forList(context),
          w.deleted,
          actionLabel: w.undo,
          onActionPressed: () => c.undoDelete(removed),
        );
    }
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        project = f.project,
        assignee = f.assignee,
        order = f.sort;
    final result = await showCivicDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 320 + 4 * CivicSpacing.s32,
            ),
            child: CivicDialog(
              title: w.filters,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [
                  CivicSelect(
                    labelText: w.status,
                    value: status,
                    items: [
                      for (final s in TaskStatus.values)
                        CivicSelectItem(value: s, label: w.statusName(s)),
                    ],
                    onChanged: (v) => set(() => status = v),
                  ),
                  CivicSelect(
                    labelText: w.project,
                    value: project,
                    items: [
                      CivicSelectItem(value: '', label: w.all),
                      ...projectOptions,
                    ],
                    onChanged: (v) => set(() => project = v),
                  ),
                  CivicSelect(
                    labelText: w.assignee,
                    value: assignee,
                    items: [
                      CivicSelectItem(value: '', label: w.all),
                      for (final p in team)
                        CivicSelectItem(value: p.id, label: w.text(p.name)),
                    ],
                    onChanged: (v) => set(() => assignee = v),
                  ),
                  CivicSelect(
                    labelText: w.sort,
                    value: order,
                    items: [
                      for (final s in TaskSort.values)
                        CivicSelectItem(value: s, label: w.sortName(s)),
                    ],
                    onChanged: (v) => set(() => order = v),
                  ),
                ],
              ),
              actions: [
                CivicButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: Text(w.apply),
                ),
                CivicButton.secondary(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(w.cancel),
                ),
                CivicLink(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: Text(w.reset),
                ),
              ],
            ),
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
      f.sort = order;
    });
  }
}
