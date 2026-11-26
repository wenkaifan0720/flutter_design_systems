part of '../stint_studio.dart';

enum _TaskAction { done, move, delete }

extension _TaskDesk on _WorkspaceState {
  Widget tasks() => NavigatorPopHandler<void>(
    onPopWithResult: (_) => taskNavigator.currentState?.maybePop(),
    // The routes keep nodes of their own, as the app's navigator's do. Under
    // a container that merges, a route's node comes only when a list opens
    // over it, and on the web the field's input moves into it and loses the
    // focus the tap just gave it.
    child: Semantics(
      explicitChildNodes: true,
      child: Navigator(
        key: taskNavigator,
        onGenerateRoute: (_) => _root(
          (_) => ListenableBuilder(
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
                  listWidth: 454,
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: taskList()),
                  detailRouteBuilder: (builder) =>
                      MaterialPageRoute<void>(builder: builder),
                  detailBuilder: (_, id) => notices.detail(
                    sideBySide: sideBySide,
                    child: LayoutBuilder(
                      builder: (_, box) => box.maxWidth < 96
                          ? const SizedBox.shrink()
                          : _TaskEditor(
                              key: ValueKey(id),
                              studio: this,
                              id: id,
                            ),
                    ),
                  ),
                  // The status view is a pane of glass of its own: one pane, set
                  // in the middle of the metal.
                  // Its bar stays, so the header runs the window's width.
                  emptyDetailBuilder: (_) => StudioScreen(
                    topBar: StudioAppBar(
                      automaticallyImplyLeading: false,
                      title: w.taskDetail,
                    ),
                    scroll: false,
                    body: _centred(
                      Visibility(
                        visible: c.hasRowToOpen,
                        child: StudioStatusView(
                          title: w.chooseTask,
                          message: w.chooseTaskHelp,
                          icon: const Icon(LucideIcons.clipboardList),
                        ),
                      ),
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
  void resetFilters() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget taskList() {
    final rows = c.visible,
        selected = c.selected,
        matches = c.filters.active && c.data.tasks.isNotEmpty;
    return StudioScreen(
      topBar: StudioAppBar(
        title: w.tasks,
        automaticallyImplyLeading: false,
        actions: [
          StudioIconButton(
            icon: const Icon(LucideIcons.refreshCw),
            tooltip: w.refresh,
            onPressed: c.refresh,
          ),
          command,
        ],
      ),
      body: data(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            StudioSearchField(
              controller: search,
              hintText: w.search,
              clearLabel: w.clear,
              semanticLabel: w.search,
              onChanged: (v) => c.filter((f) => f.search = v),
            ),
            _Keys(
              actions: [
                if (!c.selecting)
                  (
                    label: '${w.filters} (${w.number(c.filters.count)})',
                    act: filters,
                  ),
                (
                  label: c.selecting ? w.stopSelecting : w.select,
                  act: () => c.toggleSelection(),
                ),
                if (c.selecting) (label: w.selectAll, act: c.selectResults),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.selecting
                        ? w.selected(selected.length)
                        : w.totalTasks(rows.length),
                    style: rack.textTheme.label.copyWith(
                      color: rack.colors.legend,
                    ),
                  ),
                ),
                if (c.selecting) rowMenu(selected, w.actions),
              ],
            ),
            // The status view is a pane of glass of its own: one pane, not
            // one set in a display.
            if (rows.isEmpty)
              StudioStatusView(
                title: matches ? w.noMatches : w.noTasks,
                message: matches ? w.searchHelp : w.allClear,
                actionLabel: matches ? w.reset : null,
                onAction: matches ? resetFilters : null,
              )
            else
              StudioDisplay(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final t in rows) ...[
                      const StudioGroove(),
                      Builder(
                        builder: (context) {
                          final selected =
                              c.selected.contains(t.id) ||
                              c.draft?.task.id == t.id;
                          final colors = rack.colors;
                          return Semantics(
                            selected: selected,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: selected
                                    ? Color.alphaBlend(
                                        colors.indicator.withValues(alpha: .12),
                                        colors.display,
                                      )
                                    : null,
                                border: BorderDirectional(
                                  start: BorderSide(
                                    width: 3,
                                    color: selected
                                        ? colors.litLegend
                                        : Colors.transparent,
                                  ),
                                ),
                              ),
                              child: Padding(
                                // The menu key stands as far in from the
                                // panel's edge as the row's mark does.
                                padding: const EdgeInsetsDirectional.only(
                                  start: 3,
                                  end:
                                      3 +
                                      StudioSpacing.regular -
                                      StudioMetrics.recessInset,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: StudioListTile(
                                        title: w.text(t.title),
                                        subtitle:
                                            '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due).replaceAll(' ', '\u00a0')}',
                                        leading: c.selecting
                                            ? Icon(
                                                c.selected.contains(t.id)
                                                    ? LucideIcons.squareCheck
                                                    : LucideIcons.square,
                                                size: 18,
                                              )
                                            : StudioLamp(on: !t.done),
                                        showChevron: false,
                                        onTap: () => c.selecting
                                            ? c.toggleSelection(t.id)
                                            : open(t),
                                      ),
                                    ),
                                    rowMenu({
                                      t.id,
                                    }, '${w.actions}${w.dot}${t.id}'),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget rowMenu(Set<String> ids, String label) {
    final complete = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return StudioMenu(
      semanticLabel: label,
      alignEnd: true,
      items: [
        StudioMenuItem(
          label: complete ? w.reopen : w.complete,
          icon: const Icon(LucideIcons.check),
          onPressed: () => taskAction(Set.of(ids), _TaskAction.done, complete),
        ),
        StudioMenuItem(
          label: w.move,
          icon: const Icon(LucideIcons.folder),
          onPressed: () => taskAction(Set.of(ids), _TaskAction.move, complete),
        ),
        StudioMenuItem(
          label: w.delete,
          icon: const Icon(LucideIcons.trash2),
          isDestructiveAction: true,
          onPressed: () =>
              taskAction(Set.of(ids), _TaskAction.delete, complete),
        ),
      ],
      builder: (_, toggle, expanded) => StudioIconButton(
        icon: const Icon(LucideIcons.ellipsis),
        selected: expanded,
        tooltip: label,
        onPressed: ids.isEmpty ? null : toggle,
      ),
    );
  }

  Future<void> taskAction(
    Set<String> ids,
    _TaskAction operation,
    bool done,
  ) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (!mounted) return;
    switch (operation) {
      case _TaskAction.done:
        c.changeTasks(ids, done: !done);
      case _TaskAction.delete:
        final removed = c.deleteTasks(ids);
        showStudioToast(
          notices.forList(context),
          w.deleted,
          actionLabel: w.undo,
          onAction: () => c.undoDelete(removed),
        );
      case _TaskAction.move:
        final project = await showStudioActionSheet<String>(
          context: context,
          title: w.move,
          cancelLabel: w.cancel,
          actions: [
            for (final p in projects)
              StudioSheetAction(
                value: p.id,
                label: w.text(p.name),
                icon: const Icon(LucideIcons.folder),
              ),
          ],
        );
        if (mounted && project != null) c.changeTasks(ids, project: project);
    }
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        assignee = f.assignee;
    await formSheet<void>(
      title: w.filters,
      builder: (sheet) => StatefulBuilder(
        builder: (_, change) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            StudioSelect(
              labelText: w.status,
              value: status,
              items: [
                for (final s in TaskStatus.values)
                  StudioSelectItem(value: s, label: w.statusName(s)),
              ],
              onChanged: (v) => change(() => status = v),
            ),
            StudioSelect(
              labelText: w.project,
              value: project,
              items: [
                StudioSelectItem(value: '', label: w.all),
                for (final p in projects)
                  StudioSelectItem(value: p.id, label: w.text(p.name)),
              ],
              onChanged: (v) => change(() => project = v),
            ),
            StudioSelect(
              labelText: w.assignee,
              value: assignee,
              items: [
                StudioSelectItem(value: '', label: w.all),
                for (final p in team)
                  StudioSelectItem(value: p.id, label: w.text(p.name)),
              ],
              onChanged: (v) => change(() => assignee = v),
            ),
            StudioSelect(
              labelText: w.sort,
              value: sort,
              items: [
                for (final s in TaskSort.values)
                  StudioSelectItem(value: s, label: w.sortName(s)),
              ],
              onChanged: (v) => change(() => sort = v),
            ),
            _Keys(
              litLast: true,
              actions: [
                (
                  label: w.reset,
                  act: () {
                    resetFilters();
                    Navigator.pop(sheet);
                  },
                ),
                (
                  label: w.apply,
                  act: () {
                    c.filter((f) {
                      f.status = status;
                      f.sort = sort;
                      f.project = project;
                      f.assignee = assignee;
                    });
                    Navigator.pop(sheet);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Keys extends StatelessWidget {
  const _Keys({required this.actions, this.litLast = false});
  final List<({String label, VoidCallback act})> actions;
  final bool litLast;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, b) {
      final t = StudioTheme.of(ctx);
      final share = (b.maxWidth - 6 * (actions.length - 1)) / actions.length;
      final stack = actions.any(
        (a) =>
            TextPainter.computeWidth(
                  text: TextSpan(text: a.label, style: t.textTheme.label),
                  textDirection: Directionality.of(ctx),
                  textScaler: MediaQuery.textScalerOf(ctx),
                ) +
                48 >
            share,
      );
      final keys = [
        for (final (i, a) in actions.indexed)
          if (litLast && i == actions.length - 1)
            StudioButton.lit(a.label, onPressed: a.act)
          else
            StudioButton(a.label, onPressed: a.act),
      ];
      return stack
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: keys,
            )
          : Row(
              spacing: 6,
              children: [for (final key in keys) Expanded(child: key)],
            );
    },
  );
}

/// Stands the empty detail pane's placeholder in the middle of the pane, both
/// ways, and scrolls it when the pane is shorter than it.
Widget _centred(Widget child) => LayoutBuilder(
  builder: (_, box) => SingleChildScrollView(
    child: ConstrainedBox(
      constraints: BoxConstraints(minHeight: box.maxHeight),
      child: Center(child: child),
    ),
  ),
);
