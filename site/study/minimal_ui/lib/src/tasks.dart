part of '../stint_minimal.dart';

extension _TaskList on _WorkspaceState {
  // The detail route belongs to this destination. The shell stays live when
  // the window crosses a breakpoint with a phone editor open.
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
        onGenerateRoute: (_) => MaterialPageRoute<void>(
          builder: (ctx) => ListenableBuilder(
            listenable: c,
            builder: (ctx, _) => _panes(ctx),
          ),
        ),
      ),
    ),
  );
  Widget _panes(BuildContext context) => LayoutBuilder(
    builder: (_, panes) {
      // Side by side, each pane has its own toaster: a notice
      // stands in the pane it is about, never across the seam.
      final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
      return RawListDetail<String>(
        selectedItem: c.draft?.task.id,
        onSelectedItemChanged: (id) {
          if (id == null) c.openTask(null);
        },
        listWidth: 440,
        listBuilder: (_) =>
            notices.list(sideBySide: sideBySide, child: _list()),
        detailRouteBuilder: (builder) =>
            MaterialPageRoute<void>(builder: builder),
        detailBuilder: (_, id) => notices.detail(
          sideBySide: sideBySide,
          child: _TaskEditor(workspace: this, id: id),
        ),
        // The pane keeps its bar with no task open, so the header's rule runs
        // the window's width.
        emptyDetailBuilder: (_) => MinimalScaffold(
          topBar: MinimalAppBar(title: w.taskDetail, large: false),
          scroll: false,
          body: _centred(
            Visibility(
              visible: c.hasRowToOpen,
              child: MinimalEmptyState(
                icon: LucideIcons.mousePointer2,
                title: w.chooseTask,
                body: w.chooseTaskHelp,
              ),
            ),
          ),
        ),
      );
    },
  );

  Widget _filterChip(String label, VoidCallback remove) => MinimalChip(
    label,
    selected: true,
    icon: LucideIcons.x,
    onPressed: remove,
  );
  Widget _list() {
    final result = c.visible, f = c.filters;
    final filtered = c.data.tasks.isNotEmpty && f.active;
    return MinimalRefreshIndicator(
      onRefresh: c.refresh,
      child: MinimalScaffold(
        topBar: MinimalAppBar(
          title: w.tasks,
          // No count over a list that failed to load or is loading.
          subtitle: c.state == DataState.ready
              ? w.totalTasks(result.length)
              : null,
          large: false,
          actions: [
            MinimalTooltip(
              message: w.refresh,
              child: icon(LucideIcons.refreshCw, w.refresh, c.refresh),
            ),
            commandKey,
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 9,
          children: [
            MinimalSearchField(
              hintText: w.search,
              controller: search,
              clearable: true,
              onChanged: (v) => c.filter((f) => f.search = v),
            ),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                MinimalButton(
                  f.count == 0
                      ? w.filters
                      : '${w.filters} (${w.number(f.count)})',
                  icon: LucideIcons.listFilter,
                  variant: MinimalButtonVariant.secondary,
                  onPressed: filterSheet,
                ),
                MinimalButton(
                  c.selecting ? w.stopSelecting : w.select,
                  icon: LucideIcons.listChecks,
                  variant: MinimalButtonVariant.ghost,
                  onPressed: () => c.toggleSelection(),
                ),
              ],
            ),
            if (f.count > 0)
              RawChipGroup(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (f.status != TaskStatus.all)
                    _filterChip(
                      w.statusName(f.status),
                      () => c.filter((f) => f.status = TaskStatus.all),
                    ),
                  if (f.project.isNotEmpty)
                    _filterChip(
                      c.projectName(f.project),
                      () => c.filter((f) => f.project = ''),
                    ),
                  if (f.assignee.isNotEmpty)
                    _filterChip(
                      c.personName(f.assignee),
                      () => c.filter((f) => f.assignee = ''),
                    ),
                ],
              ),
            if (c.selecting)
              Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(w.selected(c.selected.length)),
                  icon(LucideIcons.listChecks, w.selectAll, c.selectResults),
                  if (c.selected.isNotEmpty)
                    MinimalMenu.button(
                      LucideIcons.ellipsis,
                      label: w.actions,
                      items: _items(c.selected),
                    ),
                ],
              ),
            dataBody(
              () => result.isEmpty
                  ? MinimalEmptyState(
                      icon: filtered
                          ? LucideIcons.searchX
                          : LucideIcons.clipboardList,
                      title: filtered ? w.noMatches : w.noTasks,
                      body: filtered ? w.searchHelp : w.allClear,
                      actionLabel: filtered ? w.reset : null,
                      onAction: filtered ? _reset : null,
                    )
                  : MinimalListSection(
                      gutter: false,
                      children: [for (final t in result) _row(t)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget _row(Task t) {
    final ids = {t.id};
    return MinimalMenu(
      trigger: MinimalMenuTrigger.longPress,
      label: w.actions,
      items: _items(ids),
      child: MinimalListTile(
        title: w.text(t.title),
        subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
        selected: c.selecting
            ? c.selected.contains(t.id)
            : c.draft?.task.id == t.id,
        leading: c.selecting
            ? MinimalCheckbox(
                label: w.text(t.title),
                value: c.selected.contains(t.id),
                onChanged: (_) => c.toggleSelection(t.id),
              )
            : Icon(
                t.done ? LucideIcons.circleCheck : LucideIcons.circleDashed,
                size: 17,
                color: context.minimalTheme.mutedForeground,
              ),
        // The ⋯ stands in the row, so a chosen row's wash runs under it.
        trailing: c.selecting
            ? null
            : MinimalMenu.button(
                LucideIcons.ellipsis,
                label: '${w.actions}${w.dot}${t.id}',
                items: _items(ids),
              ),
        onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
      ),
    );
  }

  List<MinimalMenuItem> _items(Set<String> ids) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return [
      MinimalMenuItem(
        done ? w.reopen : w.complete,
        icon: LucideIcons.circleCheck,
        onPressed: () => _act(ids, () => c.changeTasks(ids, done: !done)),
      ),
      MinimalMenuItem(
        w.move,
        icon: LucideIcons.folderInput,
        onPressed: () => moveSheet(ids),
      ),
      MinimalMenuItem(
        w.delete,
        icon: LucideIcons.trash2,
        isDestructiveAction: true,
        onPressed: () => _act(ids, () {
          final lost = c.deleteTasks(ids);
          showMinimalSnackBar(
            notices.forList(context),
            w.deleted,
            actionLabel: w.undo,
            onAction: () => c.undoDelete(lost),
          );
        }),
      ),
    ];
  }

  Future<void> _act(Set<String> ids, VoidCallback perform) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) perform();
  }

  Future<void> moveSheet(Set<String> ids) async {
    final target = await showMinimalBottomSheet<String>(
      context,
      title: w.move,
      builder: (ctx) => MinimalListSection(
        children: [
          for (final p in projects)
            MinimalListTile(
              title: w.text(p.name),
              icon: LucideIcons.folder,
              onTap: () => Navigator.pop(ctx, p.id),
            ),
        ],
      ),
    );
    if (target != null && mounted) {
      await _act(ids, () => c.changeTasks(ids, project: target));
    }
  }

  Future<void> filterSheet() async {
    final f = c.filters;
    var status = f.status, sort = f.sort;
    var project = f.project, person = f.assignee;
    Widget fields(BuildContext ctx) => StatefulBuilder(
      builder: (ctx, change) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          MinimalSelect(
            labelText: w.status,
            value: status,
            options: [
              for (final s in TaskStatus.values)
                MinimalSelectOption(s, w.statusName(s)),
            ],
            onChanged: (v) => change(() => status = v),
          ),
          MinimalSelect(
            labelText: w.project,
            value: project,
            options: [
              MinimalSelectOption('', w.all),
              for (final p in projects)
                MinimalSelectOption(p.id, w.text(p.name)),
            ],
            onChanged: (v) => change(() => project = v),
          ),
          MinimalSelect(
            labelText: w.assignee,
            value: person,
            options: [
              MinimalSelectOption('', w.all),
              for (final p in team) MinimalSelectOption(p.id, w.text(p.name)),
            ],
            onChanged: (v) => change(() => person = v),
          ),
          MinimalSelect(
            labelText: w.sort,
            value: sort,
            options: [
              for (final s in TaskSort.values)
                MinimalSelectOption(s, w.sortName(s)),
            ],
            onChanged: (v) => change(() => sort = v),
          ),
          Wrap(
            spacing: 8,
            children: [
              MinimalButton(
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
              MinimalButton(
                w.reset,
                variant: MinimalButtonVariant.ghost,
                onPressed: () {
                  _reset();
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ],
      ),
    );
    if (MediaQuery.sizeOf(context).width < 600) {
      await showMinimalBottomSheet<void>(
        context,
        title: w.filters,
        builder: fields,
      );
    } else {
      await showMinimalDialog<void>(
        context,
        builder: (ctx) => SizedBox(
          width: MinimalLayout.controlMax + 2 * MinimalChromeMetrics.sheetPad,
          child: MinimalBottomSheet(
            title: w.filters,
            floating: true,
            child: SingleChildScrollView(child: fields(ctx)),
          ),
        ),
      );
    }
  }
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

/// A short task sheet (Add entry, Start a timer): on a phone Minimal's
/// bottom sheet; from 600 px a dialog at the filters' measure, centred in
/// the window as Filters and Sign out are, not riding on its foot.
Future<T?> _raise<T>(
  BuildContext context, {
  required String title,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showMinimalBottomSheet<T>(context, title: title, builder: builder);
  }
  return showMinimalDialog<T>(
    context,
    builder: (ctx) => SizedBox(
      width: MinimalLayout.controlMax + 2 * MinimalChromeMetrics.sheetPad,
      child: MinimalBottomSheet(
        title: title,
        floating: true,
        child: builder(ctx),
      ),
    ),
  );
}
