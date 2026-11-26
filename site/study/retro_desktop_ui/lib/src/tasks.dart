part of '../stint_retro_desktop.dart';

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
                  listWidth: 456,
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: taskList()),
                  detailRouteBuilder: (builder) =>
                      RetroDesktopPageRoute<void>(builder: builder),
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
                  emptyDetailBuilder: (_) => _Pane(
                    active: false,
                    scroll: false,
                    // The window stands as tall as the list's, its placeholder in
                    // the middle of it.
                    window: RetroDesktopWindow(
                      title: w.taskDetail,
                      icon: RetroDesktopGlyphs.fileText,
                      fills: true,
                      child: _centred(
                        Visibility(
                          visible: c.hasRowToOpen,
                          child: RetroDesktopEmptyState(
                            title: w.chooseTask,
                            message: w.chooseTaskHelp,
                          ),
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
    return _Pane(
      active: c.draft == null,
      window: RetroDesktopWindow(
        title: w.tasks,
        icon: RetroDesktopGlyphs.folder,
        child: data(
          () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 9,
            children: [
              RetroDesktopSearchField(
                hintText: w.search,
                controller: search,
                clearLabel: w.clear,
                onChanged: (s) => c.filter((f) => f.search = s),
              ),
              LayoutBuilder(
                builder: (ctx, b) {
                  final filterName =
                      '${w.filters} (${w.number(c.filters.count)})';
                  final names = c.selecting
                      ? [w.stopSelecting, w.selectAll]
                      : [filterName, w.select];
                  final share = (b.maxWidth - 6) / 2;
                  final stacked = names.any(
                    (name) =>
                        TextPainter.computeWidth(
                              text: TextSpan(
                                text: name,
                                style: desk.textTheme.chrome,
                              ),
                              textDirection: Directionality.of(ctx),
                              textScaler: MediaQuery.textScalerOf(ctx),
                            ) +
                            52 >
                        share,
                  );
                  final actions = [
                    if (!c.selecting)
                      RetroDesktopButton(
                        filterName,
                        wide: true,
                        onPressed: filters,
                      ),
                    RetroDesktopButton(
                      c.selecting ? w.stopSelecting : w.select,
                      wide: true,
                      onPressed: () => c.toggleSelection(),
                    ),
                    if (c.selecting)
                      RetroDesktopButton(
                        w.selectAll,
                        wide: true,
                        onPressed: c.selectResults,
                      ),
                  ];
                  return stacked
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 5,
                          children: actions,
                        )
                      : RetroDesktopEqualRow(
                          flex: List.filled(actions.length, 1),
                          gap: 6,
                          children: actions,
                        );
                },
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      c.selecting
                          ? w.selected(selected.length)
                          : w.totalTasks(rows.length),
                      style: desk.textTheme.sub,
                    ),
                  ),
                  if (c.selecting)
                    rowMenu(selected, w.actions)
                  else
                    _ToolButton(
                      RetroDesktopGlyphs.refresh,
                      label: w.refresh,
                      onPressed: c.refresh,
                    ),
                ],
              ),
              if (rows.isEmpty)
                RetroDesktopEmptyState(
                  title: matches ? w.noMatches : w.noTasks,
                  message: matches ? w.searchHelp : w.allClear,
                  action: matches
                      ? RetroDesktopButton(w.reset, onPressed: resetFilters)
                      : null,
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final task in rows) ...[
                      const RetroDesktopDivider(),
                      ColoredBox(
                        color:
                            selected.contains(task.id) ||
                                c.draft?.task.id == task.id
                            ? desk.colors.highlight
                            : const Color(0x00000000),
                        // The menu button keeps the tile's own inset from the
                        // list's edge.
                        child: Padding(
                          padding: const EdgeInsetsDirectional.only(
                            end: RetroDesktopSpacing.s10,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: RetroDesktopListTile(
                                  isFirst: true,
                                  title: w.text(task.title),
                                  subtitle:
                                      '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due).replaceAll(' ', '\u00a0')}',
                                  selected:
                                      selected.contains(task.id) ||
                                      c.draft?.task.id == task.id,
                                  leading: Icon(
                                    c.selecting
                                        ? (selected.contains(task.id)
                                              ? LucideIcons.squareCheck
                                              : LucideIcons.square)
                                        : (task.done
                                              ? RetroDesktopGlyphs.circleCheck
                                              : RetroDesktopGlyphs.fileText),
                                    size: 17,
                                  ),
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
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget rowMenu(Set<String> ids, String label) => Builder(
    builder: (anchor) => _ToolButton(
      LucideIcons.ellipsis,
      label: label,
      onPressed: ids.isEmpty ? null : () => taskActions(anchor, Set.of(ids)),
    ),
  );

  Future<void> taskActions(BuildContext anchor, Set<String> ids) async {
    final box = anchor.findRenderObject() as RenderBox;
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    final action = await showRetroDesktopMenu<_TaskAction>(
      anchor,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      label: w.actions,
      // Words alone: the menu's mark column holds a check for a chosen row,
      // so Mark done's check glyph there read as done already.
      items: [
        RetroDesktopMenuItem(_TaskAction.done, done ? w.reopen : w.complete),
        RetroDesktopMenuItem(_TaskAction.move, w.move),
        RetroDesktopMenuItem(_TaskAction.delete, w.delete),
      ],
    );
    if (action == null || !mounted) return;
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (!mounted) return;
    switch (action) {
      case _TaskAction.done:
        c.changeTasks(ids, done: !done);
      case _TaskAction.delete:
        final removed = c.deleteTasks(ids);
        showRetroDesktopSnackBar(
          notices.forList(context),
          w.deleted,
          actionLabel: w.undo,
          onAction: () => c.undoDelete(removed),
        );
      case _TaskAction.move:
        final project = await showRetroDesktopDialog<String>(
          context,
          builder: (ctx) => RetroDesktopDialog(
            title: w.move,
            content: [
              for (final p in projects)
                RetroDesktopListTile(
                  isFirst: p == projects.first,
                  title: w.text(p.name),
                  leading: const Icon(RetroDesktopGlyphs.folder),
                  onPressed: () => Navigator.pop(ctx, p.id),
                ),
            ],
          ),
        );
        if (project != null && mounted) c.changeTasks(ids, project: project);
    }
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        assignee = f.assignee;
    await showRetroDesktopBottomSheet<void>(
      context,
      builder: (sheet) => Align(
        alignment: MediaQuery.sizeOf(sheet).width >= 600
            ? Alignment.center
            : Alignment.bottomCenter,
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 390),
          child: StatefulBuilder(
            builder: (_, change) => RetroDesktopBottomSheet(
              title: w.filters,
              actions: [
                RetroDesktopButton(
                  w.reset,
                  onPressed: () {
                    resetFilters();
                    Navigator.pop(sheet);
                  },
                ),
                RetroDesktopButton(
                  w.apply,
                  isDefaultAction: true,
                  onPressed: () {
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
              child: RetroDesktopSections(
                children: [
                  LayoutBuilder(
                    builder: (ctx, box) {
                      final paired =
                          MediaQuery.sizeOf(ctx).width >= 600 &&
                          box.maxWidth /
                                  MediaQuery.textScalerOf(ctx).scale(1) >=
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
                            child: RetroDesktopSelect(
                              labelText: w.status,
                              value: status,
                              options: [
                                for (final s in TaskStatus.values)
                                  RetroDesktopOption(s, w.statusName(s)),
                              ],
                              onChanged: (v) => change(() => status = v),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: RetroDesktopSelect(
                              labelText: w.project,
                              value: project,
                              options: [
                                RetroDesktopOption('', w.all),
                                for (final p in projects)
                                  RetroDesktopOption(p.id, w.text(p.name)),
                              ],
                              onChanged: (v) => change(() => project = v),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: RetroDesktopSelect(
                              labelText: w.assignee,
                              value: assignee,
                              options: [
                                RetroDesktopOption('', w.all),
                                for (final p in team)
                                  RetroDesktopOption(p.id, w.text(p.name)),
                              ],
                              onChanged: (v) => change(() => assignee = v),
                            ),
                          ),
                          SizedBox(
                            width: width,
                            child: RetroDesktopSelect(
                              labelText: w.sort,
                              value: sort,
                              options: [
                                for (final s in TaskSort.values)
                                  RetroDesktopOption(s, w.sortName(s)),
                              ],
                              onChanged: (v) => change(() => sort = v),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Pane extends StatelessWidget {
  const _Pane({
    required this.window,
    this.active = true,
    this.footer,
    this.scroll = true,
  });
  final RetroDesktopWindow window;
  final bool active;
  final Widget? footer;

  /// False: the window fills the pane (its content scrolls itself).
  final bool scroll;
  @override
  Widget build(BuildContext context) => RoutePresentationScope(
    presentation: RoutePresentation.root,
    child: RetroDesktopScaffold(
      fullBleed: true,
      scroll: scroll,
      footer: footer,
      body: Padding(
        padding: EdgeInsets.fromLTRB(
          10,
          MediaQuery.sizeOf(context).width >= 1040 ? 24 : 12,
          10,
          12,
        ),
        child: RetroDesktopWindowScope(
          active: active,
          compact: true,
          child: window,
        ),
      ),
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
