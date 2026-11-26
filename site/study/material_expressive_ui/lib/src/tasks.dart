part of '../stint_material_expressive.dart';

extension _Tasks on _WorkspaceState {
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
          builder: (_) => ListenableBuilder(
            listenable: c,
            builder: (context, _) => LayoutBuilder(
              builder: (_, panes) {
                // Side by side, each pane has a toaster of its own: a notice stands in
                // the pane it is about, never across the seam.
                final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
                return RawListDetail<String>(
                  selectedItem: c.draft?.task.id,
                  onSelectedItemChanged: (id) {
                    if (id == null) c.openTask(null);
                  },
                  listWidth: 462,
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: _taskList()),
                  detailRouteBuilder: (build) =>
                      MaterialPageRoute<void>(builder: build),
                  detailBuilder: (_, id) => notices.detail(
                    sideBySide: sideBySide,
                    child: _Editor(key: ValueKey(id), studio: this, id: id),
                  ),
                  emptyDetailBuilder: (_) => ExpressiveScaffold(
                    topBar: ExpressiveAppBar.none,
                    scroll: false,
                    body: _centred(
                      Visibility(
                        visible: c.hasRowToOpen,
                        child: ExpressiveEmptyState(
                          icon: ExpressiveSymbols.article,
                          title: w.chooseTask,
                          body: w.chooseTaskHelp,
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
    c.filter((v) => v.reset());
  }

  Widget _taskList() {
    final rows = c.visible, f = c.filters;
    return ExpressiveScaffold(
      topBar: ExpressiveAppBar(
        title: w.tasks,
        actions: [
          icon(ExpressiveSymbols.refresh, w.refresh, c.refresh),
          commandKey,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          ExpressiveSearchField(
            hintText: w.search,
            controller: search,
            onChanged: (query) => c.filter((filters) => filters.search = query),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ExpressiveOutlinedButton(
                f.count == 0
                    ? w.filters
                    : '${w.filters} (${w.number(f.count)})',
                icon: ExpressiveSymbols.filterList,
                onPressed: _filters,
              ),
              ExpressiveTextButton(
                c.selecting ? w.stopSelecting : w.select,
                icon: ExpressiveSymbols.checklist,
                onPressed: () => c.toggleSelection(),
              ),
            ],
          ),
          if (c.selecting)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(w.selected(c.selected.length)),
                icon(ExpressiveSymbols.checklist, w.selectAll, c.selectResults),
                if (c.selected.isNotEmpty) _actions(c.selected, w.actions),
              ],
            )
          // No count over a list that failed to load or is loading.
          else if (c.state == DataState.ready)
            ExpressiveText(
              w.totalTasks(rows.length),
              role: ExpressiveTextRole.label,
              color: theme.colors.onSurfaceVariant,
            ),
          data(
            () => rows.isEmpty
                ? ExpressiveEmptyState(
                    icon: ExpressiveSymbols.inbox,
                    title: c.data.tasks.isEmpty ? w.noTasks : w.noMatches,
                    body: c.data.tasks.isEmpty ? w.allClear : w.searchHelp,
                    actionLabel: c.data.tasks.isEmpty ? null : w.reset,
                    onAction: c.data.tasks.isEmpty ? null : resetFilters,
                  )
                : ExpressiveListSection(
                    children: [for (final task in rows) _row(task)],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _row(Task t) {
    final title = Text(w.text(t.title));
    final subtitle = Text(
      '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
    );
    if (c.selecting) {
      final checked = c.selected.contains(t.id);
      return ExpressiveListTile.toggleable(
        key: ValueKey(t.id),
        value: checked,
        title: title,
        subtitle: subtitle,
        leading: ExpressiveIcon(
          checked
              ? ExpressiveSymbols.checkBox
              : ExpressiveSymbols.checkBoxOutlineBlank,
        ),
        onChanged: (_) => c.toggleSelection(t.id),
      );
    }
    // The ⋯ stands beside the row, not in its trailing slot: a pressable
    // row merges a control there into its own node, so on the web (whose
    // semantics tree takes the clicks) ⋯ opened the task, not its menu.
    return Row(
      key: ValueKey(t.id),
      children: [
        Expanded(
          child: ExpressiveListTile.selectable(
            selected: c.draft?.task.id == t.id,
            title: title,
            subtitle: subtitle,
            leading: ExpressiveAvatar(
              name: c.personName(t.assignee),
              size: ExpressiveAvatarSize.small,
            ),
            onTap: () => open(t),
          ),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: _actions({t.id}, '${w.actions}${w.dot}${t.id}'),
        ),
      ],
    );
  }

  Widget _actions(Set<String> ids, String name) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    Future<void> act(VoidCallback perform) async {
      if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
      if (mounted) perform();
    }

    return ExpressiveMenu(
      label: name,
      builder: (ctx, menu) => icon(ExpressiveSymbols.moreVert, name, menu.open),
      entries: [
        ExpressiveMenuItem(
          done ? w.reopen : w.complete,
          icon: ExpressiveSymbols.checkCircle,
          onPressed: () => act(() => c.changeTasks(ids, done: !done)),
        ),
        ExpressiveMenuItem(
          w.move,
          icon: ExpressiveSymbols.folder,
          onPressed: () async {
            final project = await _raise<String>(
              context,
              cancel: w.cancel,
              (ctx) => _Sheet(
                title: w.move,
                children: [
                  ExpressiveListSection(
                    children: [
                      for (final p in projects)
                        ExpressiveListTile(
                          title: Text(w.text(p.name)),
                          leading: const ExpressiveIcon(
                            ExpressiveSymbols.folder,
                          ),
                          onTap: () => Navigator.pop(ctx, p.id),
                        ),
                    ],
                  ),
                ],
              ),
            );
            if (project != null && mounted) {
              await act(() => c.changeTasks(ids, project: project));
            }
          },
        ),
        ExpressiveMenuItem(
          w.delete,
          icon: ExpressiveSymbols.delete,
          onPressed: () => act(() {
            final deleted = c.deleteTasks(ids);
            showExpressiveSnackBar(
              notices.forList(context),
              w.deleted,
              actionLabel: w.undo,
              duration: ExpressiveSnackBarDuration.long,
              onAction: () => c.undoDelete(deleted),
            );
          }),
        ),
      ],
    );
  }

  Future<void> _filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        person = f.assignee;
    await _raise<void>(
      context,
      cancel: w.cancel,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => _Sheet(
          title: w.filters,
          children: [
            LayoutBuilder(
              builder: (ctx, box) {
                final paired =
                    box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) >= 480;
                final gap = ExpressiveSpacing.s16;
                final width = paired ? (box.maxWidth - gap) / 2 : box.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: ExpressiveSelect(
                        labelText: w.status,
                        value: status,
                        options: [
                          for (final s in TaskStatus.values)
                            ExpressiveSelectOption(s, w.statusName(s)),
                        ],
                        onChanged: (v) => set(() => status = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ExpressiveSelect(
                        labelText: w.project,
                        value: project,
                        options: [
                          ExpressiveSelectOption('', w.all),
                          for (final p in projects)
                            ExpressiveSelectOption(p.id, w.text(p.name)),
                        ],
                        onChanged: (v) => set(() => project = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ExpressiveSelect(
                        labelText: w.assignee,
                        value: person,
                        options: [
                          ExpressiveSelectOption('', w.all),
                          for (final p in team)
                            ExpressiveSelectOption(p.id, w.text(p.name)),
                        ],
                        onChanged: (v) => set(() => person = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ExpressiveSelect(
                        labelText: w.sort,
                        value: sort,
                        options: [
                          for (final s in TaskSort.values)
                            ExpressiveSelectOption(s, w.sortName(s)),
                        ],
                        onChanged: (v) => set(() => sort = v),
                      ),
                    ),
                  ],
                );
              },
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ExpressiveFilledButton(
                  w.apply,
                  onPressed: () {
                    c.filter((v) {
                      v.status = status;
                      v.sort = sort;
                      v.project = project;
                      v.assignee = person;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                ExpressiveTextButton(
                  w.reset,
                  onPressed: () {
                    resetFilters();
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

/// A short task's surface: a bottom sheet on a phone; from 600 px a dialog
/// in the middle of the window, not a phone sheet on the window's foot.
/// The dialog keeps the sheet's way out: its own [cancel] action (a sheet
/// is dragged or tapped away).
Future<T?> _raise<T>(
  BuildContext context,
  WidgetBuilder sheet, {
  required String cancel,
}) => _wide(context)
    ? showExpressiveDialog<T>(
        context: context,
        builder: (ctx) => ExpressiveDialog(
          content: SizedBox(width: 480, child: sheet(ctx)),
          actions: [ExpressiveDialogAction(cancel)],
        ),
      )
    : showExpressiveBottomSheet<T>(
        context,
        skipPartiallyExpanded: true,
        builder: sheet,
      );

bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 600;

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children});
  final String title;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    primary: true,
    // In a dialog its own padding holds the content.
    padding: _wide(context)
        ? EdgeInsets.zero
        : const EdgeInsetsDirectional.fromSTEB(20, 4, 20, 24),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [_Heading(title), ...children],
    ),
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
