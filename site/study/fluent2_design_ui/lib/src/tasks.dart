part of '../stint_fluent2_design.dart';

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
            builder: (ctx, _) => RawListDetail<String>(
              selectedItem: c.draft?.task.id,
              onSelectedItemChanged: (id) {
                if (id == null) c.openTask(null);
              },
              listWidth: 458,
              listBuilder: (_) => taskList(),
              detailRouteBuilder: (build) =>
                  MaterialPageRoute<void>(builder: build),
              detailBuilder: (_, id) =>
                  _Editor(key: ValueKey(id), studio: this, id: id),
              emptyDetailBuilder: (_) => Fluent2Scaffold(
                topBar: Fluent2AppBar.none,
                scroll: false,
                body: _centred(
                  Visibility(
                    visible: c.hasRowToOpen,
                    child: Fluent2EmptyState(
                      title: w.chooseTask,
                      body: w.chooseTaskHelp,
                      icon: Fluent2Icons.documentText,
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
    c.filter((v) => v.reset());
  }

  Widget taskList() {
    final tasks = c.visible;
    return Fluent2Scaffold(
      topBar: Fluent2AppBar(
        title: w.tasks,
        actions: [
          icon(Fluent2Icons.arrowClockwise, w.refresh, c.refresh),
          commands,
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          Fluent2SearchBox(
            hintText: w.search,
            semanticLabel: w.search,
            controller: search,
            onChanged: (q) => c.filter((f) => f.search = q),
            onClear: () => c.filter((f) => f.search = ''),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Fluent2Button(
                c.filters.count == 0
                    ? w.filters
                    : '${w.filters} (${w.number(c.filters.count)})',
                icon: Fluent2Icons.filter,
                onPressed: filters,
              ),
              Fluent2Button(
                c.selecting ? w.stopSelecting : w.select,
                appearance: Fluent2ButtonAppearance.subtle,
                icon: Fluent2Icons.taskListLtr,
                onPressed: () => c.toggleSelection(),
              ),
            ],
          ),
          if (c.selecting)
            Wrap(
              spacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(w.selected(c.selected.length), style: theme.body1.strong),
                icon(Fluent2Icons.checkmark, w.selectAll, c.selectResults),
                if (c.selected.isNotEmpty) actions(c.selected, w.actions),
              ],
            ),
          data(
            () => tasks.isEmpty
                ? Fluent2EmptyState(
                    title: c.data.tasks.isEmpty ? w.noTasks : w.noMatches,
                    body: c.data.tasks.isEmpty ? w.allClear : w.searchHelp,
                    actionLabel: c.data.tasks.isEmpty ? null : w.reset,
                    onAction: c.data.tasks.isEmpty ? null : resetFilters,
                  )
                : Fluent2ListGroup(
                    title: w.totalTasks(tasks.length),
                    children: [
                      for (final t in tasks)
                        Fluent2ListItem(
                          key: ValueKey(t.id),
                          title: w.text(t.title),
                          subtitle:
                              '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
                          leading: c.selecting
                              ? null
                              : Fluent2IconTile(
                                  Fluent2Icons.documentTextFilled,
                                  hue: _hue(t.project),
                                  size: 32,
                                ),
                          checked: c.selecting
                              ? c.selected.contains(t.id)
                              : null,
                          onChanged: c.selecting
                              ? (_) => c.toggleSelection(t.id)
                              : null,
                          selected: c.draft?.task.id == t.id,
                          onTap: c.selecting ? null : () => open(t),
                          action: c.selecting
                              ? null
                              : actions({t.id}, '${w.actions}${w.dot}${t.id}'),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget actions(Set<String> ids, String name) => Builder(
    builder: (anchor) => icon(Fluent2Icons.moreHorizontal, name, () async {
      final done = c.data.tasks
          .where((t) => ids.contains(t.id))
          .every((t) => t.done);
      final act = await showFluent2Menu<String>(
        context,
        anchor: anchor,
        semanticLabel: name,
        items: [
          Fluent2MenuItem(
            'done',
            done ? w.reopen : w.complete,
            icon: Fluent2Icons.checkmarkCircle,
          ),
          Fluent2MenuItem('move', w.move, icon: Fluent2Icons.folder),
          Fluent2MenuItem(
            'delete',
            w.delete,
            icon: Fluent2Icons.delete,
            danger: true,
          ),
        ],
      );
      if (act == null || !mounted) return;
      if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
      if (!mounted) return;
      switch (act) {
        case 'done':
          c.changeTasks(ids, done: !done);
        case 'move':
          final dest = await showFluent2ActionSheet<String>(
            context,
            title: w.move,
            cancelLabel: w.cancel,
            actions: [
              for (final p in projects)
                Fluent2ActionSheetAction(
                  p.id,
                  w.text(p.name),
                  icon: Fluent2Icons.folder,
                ),
            ],
          );
          if (mounted && dest != null) c.changeTasks(ids, project: dest);
        case 'delete':
          final deleted = c.deleteTasks(ids);
          showFluent2Toast(
            context,
            w.deleted,
            actionLabel: w.undo,
            onAction: () => c.undoDelete(deleted),
          );
      }
    }),
  );
  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        person = f.assignee;
    await _drawer<void>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => Fluent2Sheet(
          title: w.filters,
          actions: [
            Fluent2Button(
              w.reset,
              onPressed: () {
                resetFilters();
                Navigator.pop(ctx);
              },
            ),
            Fluent2Button(
              w.apply,
              appearance: Fluent2ButtonAppearance.primary,
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
          ],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: [
              Fluent2FormField(
                labelText: w.status,
                child: Fluent2Select(
                  value: status,
                  options: [
                    for (final n in TaskStatus.values)
                      Fluent2Option(n, w.statusName(n)),
                  ],
                  onChanged: (v) => set(() => status = v),
                ),
              ),
              Fluent2FormField(
                labelText: w.project,
                child: Fluent2Select(
                  value: project,
                  options: [
                    Fluent2Option('', w.all),
                    for (final p in projects)
                      Fluent2Option(p.id, w.text(p.name)),
                  ],
                  onChanged: (v) => set(() => project = v),
                ),
              ),
              Fluent2FormField(
                labelText: w.assignee,
                child: Fluent2Select(
                  value: person,
                  options: [
                    Fluent2Option('', w.all),
                    for (final p in team) Fluent2Option(p.id, w.text(p.name)),
                  ],
                  onChanged: (v) => set(() => person = v),
                ),
              ),
              Fluent2FormField(
                labelText: w.sort,
                child: Fluent2Select(
                  value: sort,
                  options: [
                    for (final n in TaskSort.values)
                      Fluent2Option(n, w.sortName(n)),
                  ],
                  onChanged: (v) => set(() => sort = v),
                ),
              ),
            ],
          ),
        ),
      ),
      width: MediaQuery.textScalerOf(context).scale(1) > 1.3 ? 460 : 380,
    );
  }
}

Future<T?> _drawer<T>(
  BuildContext context,
  WidgetBuilder content, {
  double width = 480,
}) => MediaQuery.sizeOf(context).width >= 760
    ? showFluent2Sheet<T>(
        context,
        width: width,
        builder: (ctx, _) => content(ctx),
      )
    : showFluent2BottomSheet<T>(context, builder: content);

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
