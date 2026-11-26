part of '../stint_comic.dart';

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
              listWidth: 470,
              listBuilder: (_) => taskList(),
              detailRouteBuilder: (builder) =>
                  MaterialPageRoute<void>(builder: builder),
              detailBuilder: (_, id) =>
                  _Editor(key: ValueKey(id), studio: this, id: id),
              // The pane keeps its bar with no task open, so the header's rule
              // runs the window's width; its panel stands only beside a row
              // to open.
              emptyDetailBuilder: (_) => ComicScaffold(
                topBar: ComicAppBar(title: w.taskDetail),
                scroll: false,
                body: _centred(
                  Visibility(
                    visible: c.hasRowToOpen,
                    child: SizedBox(
                      width: double.infinity,
                      child: ComicPanel(
                        child: ComicEmptyState(
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
    ),
  );
  void resetFilters() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget taskList() {
    final rows = c.visible;
    return ComicScaffold(
      topBar: ComicAppBar(
        title: w.tasks,
        actions: [icon(ComicGlyphs.refresh, w.refresh, c.refresh), commands],
      ),
      body: ComicSections(
        children: [
          ComicPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                ComicSearchField(
                  name: w.search,
                  hintText: w.search,
                  clearLabel: w.clear,
                  controller: search,
                  onChanged: (v) => c.filter((f) => f.search = v),
                ),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  children: [
                    ComicButton(
                      c.filters.count == 0
                          ? w.filters
                          : '${w.filters} (${w.number(c.filters.count)})',
                      onPressed: filters,
                    ),
                    ComicButton(
                      c.selecting ? w.stopSelecting : w.select,
                      icon: ComicGlyphs.check,
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
                      icon(ComicGlyphs.check, w.selectAll, c.selectResults),
                      if (c.selected.isNotEmpty) actions(c.selected, w.actions),
                    ],
                  ),
              ],
            ),
          ),
          data(
            () => rows.isEmpty
                ? ComicPanel(
                    child: ComicEmptyState(
                      title: c.data.tasks.isEmpty ? w.noTasks : w.noMatches,
                      body: c.data.tasks.isEmpty ? w.allClear : w.searchHelp,
                      action: c.data.tasks.isEmpty
                          ? null
                          : ComicButton(w.reset, onPressed: resetFilters),
                    ),
                  )
                : ComicPanel(
                    caption: w.totalTasks(rows.length),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final (i, task) in rows.indexed)
                          DecoratedBox(
                            position: DecorationPosition.foreground,
                            key: ValueKey(task.id),
                            decoration: BoxDecoration(
                              border: i == 0
                                  ? null
                                  : Border(
                                      top: BorderSide(color: t.colors.divider),
                                    ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _InkRow(
                                    title: w.text(task.title),
                                    subtitle:
                                        '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due)}',
                                    first: true,
                                    checked: c.selecting
                                        ? c.selected.contains(task.id)
                                        : null,
                                    chosen: c.selecting
                                        ? c.selected.contains(task.id)
                                        : c.draft?.task.id == task.id,
                                    leading: c.selecting
                                        ? Icon(
                                            c.selected.contains(task.id)
                                                ? ComicGlyphs.circleCheck
                                                : ComicGlyphs.plus,
                                            color: t.colors.primaryText,
                                          )
                                        : null,
                                    onPressed: c.selecting
                                        ? () => c.toggleSelection(task.id)
                                        : () => open(task),
                                  ),
                                ),
                                if (!c.selecting)
                                  Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 4,
                                    ),
                                    child: actions({
                                      task.id,
                                    }, '${w.actions}${w.dot}${task.id}'),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget actions(Set<String> ids, String name) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return ComicMenuAnchor<String>(
      items: [
        ComicMenuItem(
          'done',
          done ? w.reopen : w.complete,
          icon: ComicGlyphs.check,
        ),
        ComicMenuItem('move', w.move, icon: ComicGlyphs.forward),
        ComicMenuItem('delete', w.delete, icon: ComicGlyphs.delete),
      ],
      builder: (ctx, show) => icon(ComicGlyphs.more, name, show),
      onSelected: (op) async {
        if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
        if (!mounted) return;
        switch (op) {
          case 'done':
            c.changeTasks(ids, done: !done);
          case 'move':
            final dest = await showComicActionSheet<String>(
              context,
              title: w.move,
              cancelLabel: w.cancel,
              actions: [
                for (final p in projects)
                  ComicSheetAction(w.text(p.name), value: p.id),
              ],
            );
            if (dest != null && mounted) c.changeTasks(ids, project: dest);
          case 'delete':
            final deleted = c.deleteTasks(ids);
            showComicSnackBar(
              context,
              w.deleted,
              actionLabel: w.undo,
              onAction: () => c.undoDelete(deleted),
            );
        }
      },
    );
  }

  Future<void> filters() async {
    final f = c.filters;
    var status = f.status,
        sort = f.sort,
        project = f.project,
        person = f.assignee;
    await _raise<void>(
      context,
      (ctx) => StatefulBuilder(
        builder: (ctx, set) => _Panel(
          title: w.filters,
          onClose: () => Navigator.pop(ctx),
          cancel: w.cancel,
          actions: [
            ComicButton(
              w.reset,
              onPressed: () {
                resetFilters();
                Navigator.pop(ctx);
              },
            ),
            ComicButton.filled(
              w.apply,
              onPressed: () {
                c.filter((f) {
                  f.status = status;
                  f.sort = sort;
                  f.project = project;
                  f.assignee = person;
                });
                Navigator.pop(ctx);
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
                        child: MergeSemantics(
                          child: ComicSelect(
                            labelText: w.status,
                            value: status,
                            options: [
                              for (final n in TaskStatus.values)
                                ComicSelectOption(n, w.statusName(n)),
                            ],
                            onChanged: (v) => set(() => status = v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: MergeSemantics(
                          child: ComicSelect(
                            labelText: w.project,
                            value: project,
                            options: [
                              ComicSelectOption('', w.all),
                              for (final p in projects)
                                ComicSelectOption(p.id, w.text(p.name)),
                            ],
                            onChanged: (v) => set(() => project = v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: MergeSemantics(
                          child: ComicSelect(
                            labelText: w.assignee,
                            value: person,
                            options: [
                              ComicSelectOption('', w.all),
                              for (final p in team)
                                ComicSelectOption(p.id, w.text(p.name)),
                            ],
                            onChanged: (v) => set(() => person = v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: MergeSemantics(
                          child: ComicSelect(
                            labelText: w.sort,
                            value: sort,
                            options: [
                              for (final n in TaskSort.values)
                                ComicSelectOption(n, w.sortName(n)),
                            ],
                            onChanged: (v) => set(() => sort = v),
                          ),
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

/// A short task sheet (Filters, Add entry): on a phone it rises from the
/// foot; from 600 px it stands in the middle of the window on its print, as
/// Sign out does, rather than hanging from the window's foot.
Future<T?> _raise<T>(BuildContext context, WidgetBuilder builder) =>
    MediaQuery.sizeOf(context).width < 600
    ? showComicBottomSheet<T>(context, builder: builder)
    : showComicDialog<T>(context, builder: builder);

/// The panel [_raise] shows: Comic's sheet on a phone, its dialog wider.
class _Panel extends StatelessWidget {
  const _Panel({
    required this.title,
    required this.onClose,
    required this.cancel,
    required this.actions,
    required this.child,
  });
  final String title;
  final VoidCallback onClose;

  /// The dialog's way out, where the sheet has its close.
  final String cancel;
  final List<Widget> actions;
  final Widget child;

  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 600
      ? ComicBottomSheet(
          title: title,
          onClose: onClose,
          actions: actions,
          child: child,
        )
      : ComicDialog(
          title: title,
          content: [child],
          actions: [
            ComicButton(cancel, onPressed: onClose),
            ...actions,
          ],
        );
}

/// A day to pick: Comic's date picker. On a phone it rises in the sheet,
/// whose width holds the month's seven 48 px columns; the picker's dialog is
/// narrower there and cut Sunday's column in half.
Future<DateTime?> _pickDay(
  BuildContext context, {
  required DateTime value,
  required String title,
  required String cancel,
}) {
  final first = DateTime(2020), last = DateTime(2040, 12, 31);
  if (MediaQuery.sizeOf(context).width >= 600) {
    return showComicDatePicker(
      context,
      value: value,
      firstDate: first,
      lastDate: last,
      currentDate: studyToday,
      title: title,
      cancelText: cancel,
    );
  }
  var picked = value;
  return showComicBottomSheet<DateTime>(
    context,
    builder: (sheet) => StatefulBuilder(
      builder: (sheet, set) => ComicBottomSheet(
        title: title,
        onClose: () => Navigator.pop(sheet),
        actions: [
          ComicButton.filled(
            ComicLocalizations.of(sheet).choose,
            onPressed: () => Navigator.pop(sheet, picked),
          ),
        ],
        child: ComicDatePicker(
          value: picked,
          firstDate: first,
          lastDate: last,
          currentDate: studyToday,
          onChanged: (day) => set(() => picked = day),
        ),
      ),
    ),
  );
}
