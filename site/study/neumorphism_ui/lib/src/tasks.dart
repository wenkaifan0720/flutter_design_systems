part of '../stint_neumorphism.dart';

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
                  listWidth: 476,
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: taskList()),
                  detailRouteBuilder: (page) =>
                      MaterialPageRoute<void>(builder: page),
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
                  emptyDetailBuilder: (_) => NeumorphicScaffold(
                    scroll: false,
                    body: _centred(
                      SizedBox(
                        width: double.infinity,
                        child: Visibility(
                          visible: c.hasRowToOpen,
                          child: NeumorphicEmptyState(
                            title: w.chooseTask,
                            body: w.chooseTaskHelp,
                            icon: LucideIcons.clipboardList,
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
    final rows = c.visible, selected = c.selected;
    final matches = c.filters.active && c.data.tasks.isNotEmpty;
    final topBar = NeumorphicAppBar(
      title: w.tasks,
      actions: [
        NeumorphicIconButton(
          LucideIcons.refreshCw,
          semanticLabel: w.refresh,
          onPressed: c.refresh,
        ),
        command,
      ],
    );
    final controls = <Widget>[
      NeumorphicSearchField(
        hintText: w.search,
        controller: search,
        clearLabel: w.clear,
        onChanged: (v) => c.filter((f) => f.search = v),
      ),
      Builder(
        builder: (_) {
          List<Widget> keys({required bool wide}) => [
            if (!c.selecting)
              NeumorphicButton(
                '${w.filters} (${w.number(c.filters.count)})',
                icon: LucideIcons.listFilter,
                onPressed: filters,
                wide: wide,
              ),
            NeumorphicButton(
              c.selecting ? w.stopSelecting : w.select,
              icon: LucideIcons.listChecks,
              onPressed: () => c.toggleSelection(),
              wide: wide,
            ),
            if (c.selecting)
              NeumorphicButton(
                w.selectAll,
                onPressed: c.selectResults,
                wide: wide,
              ),
          ];
          // Side by side while each key's words fit its half on one line,
          // measured on the keys at their own width.
          final shown = keys(wide: true), measured = keys(wide: false);
          return StintPair(
            first: shown.first,
            second: shown.last,
            measureFirst: measured.first,
            measureSecond: measured.last,
            spacing: 10,
            runSpacing: 6,
          );
        },
      ),
      if (c.selecting)
        Row(
          children: [
            Expanded(
              child: Text(
                w.selected(selected.length),
                style: plaster.textTheme.title,
              ),
            ),
            rowMenu(selected, w.actions),
          ],
        ),
    ];
    if (c.state != DataState.ready) {
      return NeumorphicScaffold(
        topBar: topBar,
        body: data(() => const SizedBox()),
      );
    }
    // An empty list stands in the same page as a full one, so the search
    // field the reader is typing in stays where it is (rebuilt elsewhere,
    // it would lose the keys on the web).
    final empty = [
      // The empty state is its own well: a raised card around it would
      // frame it twice.
      NeumorphicEmptyState(
        title: matches ? w.noMatches : w.noTasks,
        body: matches ? w.searchHelp : w.allClear,
        icon: matches ? LucideIcons.searchX : LucideIcons.clipboardList,
      ),
      // Under the well's centred words, centred with them.
      if (matches)
        Center(child: NeumorphicButton(w.reset, onPressed: resetFilters)),
    ];
    // The rows build as they scroll into view. The page keeps the
    // scaffold's own layout: its bar and sections 28 apart inside its inset,
    // on the 1264 measure, with the scroll bar only on a desk.
    final t = NeumorphicTheme.of(context);
    final inset = t.desk
        ? const EdgeInsets.fromLTRB(48, 40, 48, 56)
        : const EdgeInsets.fromLTRB(20, 16, 20, 32);
    return NeumorphicScaffold(
      scroll: false,
      fullBleed: true,
      body: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: t.desk),
        child: LayoutBuilder(
          builder: (_, box) {
            final side = math.max(0.0, (box.maxWidth - 1264) / 2);
            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: inset.copyWith(
                    left: inset.left + side,
                    right: inset.right + side,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: NeumorphicColumn(
                          gap: 28,
                          children: [
                            topBar,
                            NeumorphicSections(
                              children: [
                                ...controls,
                                if (rows.isEmpty)
                                  ...empty
                                else
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        w.totalTasks(rows.length),
                                        style: plaster.textTheme.caption,
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      SliverList.builder(
                        itemCount: rows.length,
                        itemBuilder: (_, i) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const NeumorphicDivider(space: 2),
                            _taskRow(rows[i]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // The menu key is the tile's action: a chosen row's band runs to the row's end
  // under it, and the key stays a button of its own.
  Widget _taskRow(Task t) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 14),
    child: NeumorphicListTile(
      isFirst: true,
      title: w.text(t.title),
      subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
      selected: c.selected.contains(t.id) || c.draft?.task.id == t.id,
      leading: Icon(
        c.selecting
            ? (c.selected.contains(t.id)
                  ? LucideIcons.squareCheck
                  : LucideIcons.square)
            : (t.done ? LucideIcons.circleCheck : LucideIcons.circle),
        size: 17,
      ),
      action: rowMenu({t.id}, '${w.actions}${w.dot}${t.id}'),
      onPressed: () => c.selecting ? c.toggleSelection(t.id) : open(t),
    ),
  );

  Widget rowMenu(Set<String> ids, String label) => Builder(
    builder: (anchor) => NeumorphicTooltip(
      message: label,
      child: NeumorphicIconButton(
        LucideIcons.ellipsis,
        semanticLabel: label,
        size: 38,
        onPressed: ids.isEmpty ? null : () => taskActions(anchor, Set.of(ids)),
      ),
    ),
  );

  Future<void> taskActions(BuildContext anchor, Set<String> ids) async {
    final box = anchor.findRenderObject() as RenderBox;
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    final action = await showNeumorphicMenu<_TaskAction>(
      anchor,
      anchor: box.localToGlobal(Offset.zero) & box.size,
      label: w.actions,
      items: [
        NeumorphicMenuItem(
          _TaskAction.done,
          done ? w.reopen : w.complete,
          icon: LucideIcons.check,
        ),
        NeumorphicMenuItem(_TaskAction.move, w.move, icon: LucideIcons.folder),
        NeumorphicMenuItem(
          _TaskAction.delete,
          w.delete,
          icon: LucideIcons.trash2,
          danger: true,
        ),
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
        showNeumorphicSnackBar(
          notices.forList(context),
          message: w.deleted,
          actionLabel: w.undo,
          onAction: () => c.undoDelete(removed),
        );
      case _TaskAction.move:
        final project = await showNeumorphicActionSheet<String>(
          context,
          title: w.move,
          actions: [
            for (final p in projects)
              NeumorphicActionSheetAction(p.id, w.text(p.name)),
          ],
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
    await showNeumorphicBottomSheet<void>(
      context,
      builder: (sheet) => StatefulBuilder(
        builder: (ctx, change) => NeumorphicBottomSheet(
          title: w.filters,
          actions: [
            NeumorphicButton.text(
              w.reset,
              onPressed: () {
                resetFilters();
                Navigator.pop(sheet);
              },
            ),
            NeumorphicButton.filled(
              w.apply,
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
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
                        child: NeumorphicSelect(
                          labelText: w.status,
                          value: status,
                          options: [
                            for (final s in TaskStatus.values)
                              NeumorphicMenuItem(s, w.statusName(s)),
                          ],
                          onChanged: (v) => change(() => status = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: NeumorphicSelect(
                          labelText: w.project,
                          value: project,
                          options: [
                            NeumorphicMenuItem('', w.all),
                            for (final p in projects)
                              NeumorphicMenuItem(p.id, w.text(p.name)),
                          ],
                          onChanged: (v) => change(() => project = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: NeumorphicSelect(
                          labelText: w.assignee,
                          value: assignee,
                          options: [
                            NeumorphicMenuItem('', w.all),
                            for (final p in team)
                              NeumorphicMenuItem(p.id, w.text(p.name)),
                          ],
                          onChanged: (v) => change(() => assignee = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: NeumorphicSelect(
                          labelText: w.sort,
                          value: sort,
                          options: [
                            for (final s in TaskSort.values)
                              NeumorphicMenuItem(s, w.sortName(s)),
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
