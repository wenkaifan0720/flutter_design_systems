part of '../stint_frosted.dart';

enum _TaskAction { done, move, delete }

extension _TaskPages on _WorkspaceState {
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
        onGenerateRoute: (settings) => PageRouteBuilder<void>(
          settings: settings,
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (_, _, _) => ListenableBuilder(
            listenable: c,
            builder: (_, _) => RawListDetail<String>(
              selectedItem: c.draft?.task.id,
              onSelectedItemChanged: (id) {
                if (id == null) c.openTask(null);
              },
              listWidth: 478,
              listBuilder: (_) => list(),
              detailRouteBuilder: (builder) =>
                  MaterialPageRoute<void>(builder: builder),
              detailBuilder: (_, id) => LayoutBuilder(
                builder: (_, b) => b.maxWidth < 96
                    ? const SizedBox.shrink()
                    : _Editor(key: ValueKey(id), host: this, id: id),
              ),
              emptyDetailBuilder: (_) => FrostedScaffold(
                lights: true,
                topBar: FrostedAppBar.none,
                scroll: false,
                // The empty state is a pane of glass of its own: no card round it.
                body: _centred(
                  SizedBox(
                    width: double.infinity,
                    child: Visibility(
                      visible: c.hasRowToOpen,
                      child: FrostedEmptyState(
                        title: w.chooseTask,
                        body: w.chooseTaskHelp,
                      ),
                    ),
                  ),
                ),
              ),
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

  Widget list() {
    final rows = c.visible, ids = c.selected;
    return page(
      w.tasks,
      data(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            FrostedSearchField(
              hintText: w.titleOrId,
              labelText: w.search,
              clearLabel: w.clear,
              controller: search,
              // The field's own clear empties it (and says so through
              // onChanged): a button, where an onClear made it a link.
              onChanged: (v) => c.filter((f) => f.search = v),
            ),
            _Actions([
              if (!c.selecting)
                ('${w.filters} (${w.number(c.filters.count)})', filters),
              (
                c.selecting ? w.stopSelecting : w.select,
                () => c.toggleSelection(),
              ),
              if (c.selecting) (w.selectAll, c.selectResults),
            ]),
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.selecting
                        ? w.selected(ids.length)
                        : w.totalTasks(rows.length),
                    style: glass.textTheme.labelMedium,
                  ),
                ),
                if (c.selecting) rowMenu(ids, w.actions),
              ],
            ),
            // FrostedEmptyState is a glass face of its own: one face, not
            // one set in a card.
            if (rows.isEmpty)
              FrostedEmptyState(
                title: c.filters.active && c.data.tasks.isNotEmpty
                    ? w.noMatches
                    : w.noTasks,
                body: c.filters.active && c.data.tasks.isNotEmpty
                    ? w.searchHelp
                    : w.allClear,
                // Clearing filters can't help an empty workspace.
                actionLabel: c.filters.active && c.data.tasks.isNotEmpty
                    ? w.reset
                    : null,
                onAction: c.filters.active && c.data.tasks.isNotEmpty
                    ? resetFilters
                    : null,
              )
            else
              FrostedCard(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final task in rows) ...[
                      _Hairline(key: ValueKey('rule-${task.id}')),
                      // The row's end keeps the inset its start has, so the
                      // menu button and its focus ring stay inside the card.
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          spacing: FrostedChromeMetrics.rowGap,
                          children: [
                            Expanded(
                              child: _RecordRow(
                                title: w.text(task.title),
                                meta:
                                    '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due).replaceAll(' ', '\u00a0')}',
                                leading: c.selecting
                                    ? Icon(
                                        ids.contains(task.id)
                                            ? LucideIcons.squareCheck
                                            : LucideIcons.square,
                                      )
                                    : projectMark(task.project),
                                selected:
                                    ids.contains(task.id) ||
                                    c.draft?.task.id == task.id,
                                onPressed: () => c.selecting
                                    ? c.toggleSelection(task.id)
                                    : open(task),
                              ),
                            ),
                            rowMenu({
                              task.id,
                            }, '${w.actions}${w.dot}${task.id}'),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
      actions: [
        _IconAct(icon: LucideIcons.refreshCw, label: w.refresh, act: c.refresh),
        command,
      ],
    );
  }

  Widget rowMenu(Set<String> selection, String name) => Builder(
    builder: (anchor) => _IconAct(
      icon: LucideIcons.ellipsis,
      label: name,
      act: selection.isEmpty
          ? null
          : () async {
              final ids = Set.of(selection),
                  done = c.data.tasks
                      .where((t) => selection.contains(t.id))
                      .every((t) => t.done);
              final item = await FrostedMenu.show<_TaskAction>(
                anchor,
                semanticLabel: name,
                items: [
                  FrostedMenuItem(
                    _TaskAction.done,
                    done ? w.reopen : w.complete,
                  ),
                  FrostedMenuItem(_TaskAction.move, w.move),
                  FrostedMenuItem(_TaskAction.delete, w.delete),
                ],
              );
              if (item == null || !mounted) return;
              if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
              if (!mounted) return;
              switch (item) {
                case _TaskAction.done:
                  c.changeTasks(ids, done: !done);
                case _TaskAction.delete:
                  final removed = c.deleteTasks(ids);
                  FrostedToast.show(
                    context,
                    w.deleted,
                    actionLabel: w.undo,
                    onAction: () => c.undoDelete(removed),
                  );
                case _TaskAction.move:
                  final project = await FrostedSheet.show<String>(
                    context,
                    title: w.move,
                    builder: (ctx) => [
                      for (final p in projects)
                        FrostedListTile(
                          title: w.text(p.name),
                          leading: projectMark(p.id),
                          onPressed: () => Navigator.pop(ctx, p.id),
                        ),
                    ],
                  );
                  if (mounted && project != null) {
                    c.changeTasks(ids, project: project);
                  }
              }
            },
    ),
  );
  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        project = f.project,
        assignee = f.assignee,
        sort = f.sort;
    await FrostedSheet.show<void>(
      context,
      title: w.filters,
      builder: (sheet) => [
        StatefulBuilder(
          builder: (_, change) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              LayoutBuilder(
                builder: (ctx, box) {
                  final paired =
                      MediaQuery.sizeOf(ctx).width >= 600 &&
                      box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) >=
                          350;
                  const gap = 16.0;
                  final width = paired
                      ? (box.maxWidth - gap) / 2
                      : box.maxWidth;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: width,
                        child: FrostedSelect(
                          labelText: w.status,
                          value: status,
                          options: [
                            for (final s in TaskStatus.values)
                              FrostedSelectOption(s, w.statusName(s)),
                          ],
                          onChanged: (v) => change(() => status = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FrostedSelect(
                          labelText: w.project,
                          value: project,
                          options: [
                            FrostedSelectOption('', w.all),
                            for (final p in projects)
                              FrostedSelectOption(p.id, w.text(p.name)),
                          ],
                          onChanged: (v) => change(() => project = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FrostedSelect(
                          labelText: w.assignee,
                          value: assignee,
                          options: [
                            FrostedSelectOption('', w.all),
                            for (final person in team)
                              FrostedSelectOption(
                                person.id,
                                w.text(person.name),
                              ),
                          ],
                          onChanged: (v) => change(() => assignee = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: FrostedSelect(
                          labelText: w.sort,
                          value: sort,
                          options: [
                            for (final s in TaskSort.values)
                              FrostedSelectOption(s, w.sortName(s)),
                          ],
                          onChanged: (v) => change(() => sort = v),
                        ),
                      ),
                    ],
                  );
                },
              ),
              _Actions([
                (
                  w.reset,
                  () {
                    resetFilters();
                    Navigator.pop(sheet);
                  },
                ),
                (
                  w.apply,
                  () {
                    c.filter((f) {
                      f.status = status;
                      f.project = project;
                      f.assignee = assignee;
                      f.sort = sort;
                    });
                    Navigator.pop(sheet);
                  },
                ),
              ], primaryLast: true),
            ],
          ),
        ),
      ],
    );
  }
}

class _Hairline extends StatelessWidget {
  const _Hairline({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 1,
    child: ColoredBox(color: context.frostedTheme.colorScheme.border),
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
