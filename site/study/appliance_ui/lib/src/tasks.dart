part of '../stint_appliance.dart';

extension _Jobs on _WorkspaceState {
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
        onGenerateRoute: (_) => _rootPage(
          (ctx) => ListenableBuilder(
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
        listWidth: 458,
        listBuilder: (_) =>
            notices.list(sideBySide: sideBySide, child: _list()),
        detailRouteBuilder: (builder) =>
            MaterialPageRoute<void>(builder: builder),
        detailBuilder: (_, id) => notices.detail(
          sideBySide: sideBySide,
          child: LayoutBuilder(
            builder: (ctx, box) {
              // A route being transferred out of the narrow navigator can receive
              // an empty slot for a frame during a window resize.
              if (box.maxWidth < 96) return const SizedBox.shrink();
              return _TaskEditor(workspace: this, id: id);
            },
          ),
        ),
        // The pane keeps its bar with no task open, so the parting line runs
        // the window's width.
        emptyDetailBuilder: (_) => ApplianceScreen(
          topBar: ApplianceAppBar(title: w.taskDetail),
          scroll: false,
          body: _centred(
            Visibility(
              visible: c.hasRowToOpen,
              child: ApplianceEmptyState(
                title: w.chooseTask,
                message: w.chooseTaskHelp,
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget _filterChip(String label, VoidCallback remove) => ApplianceChip(
    label,
    selected: true,
    onDeleted: remove,
    deleteLabel: w.clear,
  );
  Widget _list() {
    final f = c.filters, result = c.visible;
    final filtered = c.data.tasks.isNotEmpty && f.active;
    return ApplianceRefresh(
      onRefresh: c.refresh,
      child: ApplianceScreen(
        topBar: ApplianceAppBar(
          title: w.tasks,
          actions: [
            keyButton(LucideIcons.refreshCw, w.refresh, c.refresh),
            commandKey,
          ],
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            ApplianceSearchField(
              controller: search,
              hintText: w.search,
              semanticLabel: w.search,
              clearLabel: w.clear,
              onChanged: (v) => c.filter((f) => f.search = v),
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ApplianceButton(
                  f.count == 0
                      ? w.filters
                      : '${w.filters} (${w.number(f.count)})',
                  icon: const Icon(LucideIcons.slidersHorizontal, size: 16),
                  onPressed: filterSheet,
                ),
                ApplianceButton(
                  c.selecting ? w.stopSelecting : w.select,
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
              RawChipGroup(
                runSpacing: 8,
                spacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ApplianceTag(w.selected(c.selected.length)),
                  keyButton(
                    LucideIcons.listChecks,
                    w.selectAll,
                    c.selectResults,
                  ),
                  if (c.selected.isNotEmpty) _menu(c.selected),
                ],
              ),
            dataBody(
              () => result.isEmpty
                  ? ApplianceEmptyState(
                      title: filtered ? w.noMatches : w.noTasks,
                      message: filtered ? w.searchHelp : w.allClear,
                      action: filtered
                          ? ApplianceButton(w.reset, onPressed: _reset)
                          : null,
                    )
                  : ApplianceListGroup(
                      header: w.totalTasks(result.length),
                      children: [for (final task in result) _row(task)],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(Task t) {
    final ids = {t.id};
    final row = ApplianceContextMenu(
      entries: _items(ids),
      semanticLabel: w.actions,
      child: ApplianceListTile(
        title: w.text(t.title),
        subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
        selected: c.selecting
            ? c.selected.contains(t.id)
            : c.draft?.task.id == t.id,
        leading: c.selecting
            ? ApplianceCheckbox(
                value: c.selected.contains(t.id),
                semanticLabel: w.text(t.title),
                onChanged: (_) => c.toggleSelection(t.id),
              )
            : ApplianceAvatar(name: c.personName(t.assignee), size: 30),
        showChevron: false,
        onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
      ),
    );
    if (c.selecting) return row;
    // The ⋯ key stands beside the row, not in its trailing slot: a pressable
    // row merges a control there into its own node, so on the web (whose
    // semantics tree takes the clicks) ⋯ opened the task, not its menu.
    return Row(
      children: [
        Expanded(child: row),
        Padding(
          padding: const EdgeInsetsDirectional.only(
            end: ApplianceSpacing.regular,
          ),
          child: _menu(ids),
        ),
      ],
    );
  }

  Widget _menu(Set<String> ids) => ApplianceMenu(
    entries: _items(ids),
    semanticLabel: w.actions,
    builder: (_, anchor) => ApplianceIconButton(
      icon: const Icon(LucideIcons.ellipsis, size: 17),
      semanticLabel:
          '${w.actions}${w.dot}${ids.length == 1 ? ids.first : w.selected(ids.length)}',
      onPressed: anchor.toggle,
    ),
  );
  List<RawMenuEntry> _items(Set<String> ids) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return [
      RawMenuEntry(
        label: done ? w.reopen : w.complete,
        onPressed: () => _act(ids, () => c.changeTasks(ids, done: !done)),
      ),
      RawMenuEntry(label: w.move, onPressed: () => _move(ids)),
      const RawMenuEntry.divider(),
      RawMenuEntry(
        label: w.delete,
        onPressed: () => _act(ids, () {
          final removed = c.deleteTasks(ids);
          showApplianceToast(
            notices.forList(context),
            w.deleted,
            actionLabel: w.undo,
            onAction: () => c.undoDelete(removed),
          );
        }),
      ),
    ];
  }

  Future<void> _act(Set<String> ids, VoidCallback apply) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) apply();
  }

  Future<void> _move(Set<String> ids) async {
    final project = await _raise<String>(
      context: context,
      title: w.move,
      cancel: w.cancel,
      builder: (ctx) => ApplianceListGroup(
        children: [
          for (final p in projects)
            ApplianceListTile(
              title: w.text(p.name),
              onTap: () => Navigator.pop(ctx, p.id),
            ),
        ],
      ),
    );
    if (project != null && mounted) {
      await _act(ids, () => c.changeTasks(ids, project: project));
    }
  }

  void _reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Future<void> filterSheet() async {
    final f = c.filters;
    var status = f.status, sort = f.sort;
    var project = f.project, person = f.assignee;
    await _raise<void>(
      context: context,
      title: w.filters,
      cancel: w.cancel,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, change) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            LayoutBuilder(
              builder: (ctx, box) {
                final paired =
                    MediaQuery.sizeOf(ctx).width >= 600 &&
                    box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) >= 350;
                const gap = 16.0;
                final width = paired ? (box.maxWidth - gap) / 2 : box.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: ApplianceSelect(
                        labelText: w.status,
                        value: status,
                        items: [
                          for (final s in TaskStatus.values)
                            ApplianceSelectItem(
                              value: s,
                              label: w.statusName(s),
                            ),
                        ],
                        onChanged: (v) => change(() => status = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ApplianceSelect(
                        labelText: w.project,
                        value: project,
                        items: [
                          ApplianceSelectItem(value: '', label: w.all),
                          for (final p in projects)
                            ApplianceSelectItem(
                              value: p.id,
                              label: w.text(p.name),
                            ),
                        ],
                        onChanged: (v) => change(() => project = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ApplianceSelect(
                        labelText: w.assignee,
                        value: person,
                        items: [
                          ApplianceSelectItem(value: '', label: w.all),
                          for (final p in team)
                            ApplianceSelectItem(
                              value: p.id,
                              label: w.text(p.name),
                            ),
                        ],
                        onChanged: (v) => change(() => person = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ApplianceSelect(
                        labelText: w.sort,
                        value: sort,
                        items: [
                          for (final s in TaskSort.values)
                            ApplianceSelectItem(value: s, label: w.sortName(s)),
                        ],
                        onChanged: (v) => change(() => sort = v),
                      ),
                    ),
                  ],
                );
              },
            ),
            Wrap(
              spacing: 8,
              children: [
                ApplianceButton.filled(
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
                ApplianceButton.text(
                  w.reset,
                  onPressed: () {
                    _reset();
                    Navigator.pop(ctx);
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

/// A short task sheet (Start a timer, Filters, Move, Add entry): on a phone
/// it rises from the foot as Appliance's sheet; from 600 px it is a lid in
/// the middle of the screen, as Sign out's is, rather than a phone sheet
/// running off the panel's foot.
Future<T?> _raise<T>({
  required BuildContext context,
  required String title,
  required String cancel,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showApplianceBottomSheet<T>(
      context: context,
      title: title,
      builder: builder,
    );
  }
  return showApplianceDialog<T>(
    context: context,
    builder: (ctx) => ApplianceDialog(
      title: title,
      // The phone sheet's close: a lid with no key but its form's own
      // left only the scrim and Esc to leave it by.
      actions: [ApplianceButton(cancel, onPressed: () => Navigator.pop(ctx))],
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(ctx).height * 0.7,
        ),
        child: SingleChildScrollView(child: builder(ctx)),
      ),
    ),
  );
}
