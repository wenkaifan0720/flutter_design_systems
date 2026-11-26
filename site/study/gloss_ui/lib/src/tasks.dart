part of '../stint_gloss.dart';

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
        onGenerateRoute: (_) => _root(
          (ctx) => ListenableBuilder(
            listenable: c,
            builder: (ctx, _) => LayoutBuilder(
              builder: (_, panes) {
                // Side by side, each pane has its own toaster: a notice
                // stands in the pane it is about, never across the seam.
                final sideBySide = PaneNotices.sideBySideAt(panes.maxWidth);
                return RawListDetail<String>(
                  selectedItem: c.draft?.task.id,
                  onSelectedItemChanged: (id) {
                    if (id == null) c.openTask(null);
                  },
                  listWidth: 462,
                  listBuilder: (_) =>
                      notices.list(sideBySide: sideBySide, child: taskList()),
                  detailRouteBuilder: (builder) =>
                      MaterialPageRoute<void>(builder: builder),
                  detailBuilder: (_, id) => notices.detail(
                    sideBySide: sideBySide,
                    child: LayoutBuilder(
                      builder: (ctx, box) => box.maxWidth < 96
                          ? const SizedBox.shrink()
                          : _Editor(key: ValueKey(id), studio: this, id: id),
                    ),
                  ),
                  // The pane keeps its bar with no task open, so the title strip
                  // runs the window's width.
                  emptyDetailBuilder: (_) => GlossScreen(
                    topBar: GlossTopBar(title: w.taskDetail),
                    scroll: false,
                    body: _centred(
                      Visibility(
                        visible: c.hasRowToOpen,
                        child: GlossStateView(
                          state: GlossState.empty,
                          icon: const Icon(LucideIcons.clipboardList),
                          title: w.chooseTask,
                          message: w.chooseTaskHelp,
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

  void reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Widget taskList() {
    final f = c.filters, result = c.visible;
    final noMatches = c.data.tasks.isNotEmpty && f.active;
    final topBar = GlossTopBar(
      title: w.tasks,
      actions: [
        GlossIconButton.plain(
          tooltip: w.refresh,
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: c.refresh,
        ),
        command,
      ],
    );
    final controls = <Widget>[
      GlossSearchField(
        controller: search,
        hintText: w.search,
        semanticLabel: w.search,
        onChanged: (v) => c.filter((f) => f.search = v),
      ),
      Builder(
        builder: (_) {
          final keys = [
            GlossButton(
              f.count == 0 ? w.filters : '${w.filters} (${w.number(f.count)})',
              icon: const Icon(LucideIcons.listFilter, size: 16),
              onPressed: filterSheet,
            ),
            GlossButton(
              c.selecting ? w.stopSelecting : w.select,
              onPressed: () => c.toggleSelection(),
            ),
          ];
          // Side by side while each key's words fit its half on one line.
          return StintPair(first: keys.first, second: keys.last, runSpacing: 6);
        },
      ),
      if (f.count > 0)
        RawChipGroup(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (f.status != TaskStatus.all)
              GlossChip(
                label: w.statusName(f.status),
                selected: true,
                onSelected: (_) => c.filter((f) => f.status = TaskStatus.all),
              ),
            if (f.project.isNotEmpty)
              GlossChip(
                label: c.projectName(f.project),
                selected: true,
                onSelected: (_) => c.filter((f) => f.project = ''),
              ),
            if (f.assignee.isNotEmpty)
              GlossChip(
                label: c.personName(f.assignee),
                selected: true,
                onSelected: (_) => c.filter((f) => f.assignee = ''),
              ),
          ],
        ),
      if (c.selecting)
        RawChipGroup(
          runSpacing: 8,
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            GlossTag(w.selected(c.selected.length)),
            GlossIconButton(
              tooltip: w.selectAll,
              icon: const Icon(LucideIcons.listChecks),
              onPressed: c.selectResults,
            ),
            if (c.selected.isNotEmpty)
              actions(c.selected, w.selected(c.selected.length)),
          ],
        ),
    ];
    final empty = GlossStateView(
      state: GlossState.empty,
      title: noMatches ? w.noMatches : w.noTasks,
      message: noMatches ? w.searchHelp : w.allClear,
      actions: [if (noMatches) GlossButton(w.reset, onPressed: reset)],
    );
    if (c.state != DataState.ready) {
      return GlossPullToRefresh(
        onRefresh: c.refresh,
        child: GlossScreen(
          topBar: topBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [...controls, dataBody(() => empty)],
          ),
        ),
      );
    }
    // The rows build as they scroll into view, in the well the kit presses
    // round a group: its head, its face behind the rows, an engraved line
    // between them, its corners clipping the first and last. The page keeps
    // the screen's own measure, margins and foot.
    final media = MediaQuery.of(context);
    final margin = GlossSpacing.pageMargin(media.size.width);
    final well = GlossFace.well(theme.colors, radius: GlossMetrics.wellRadius);
    const corner = Radius.circular(GlossMetrics.wellRadius);
    return GlossPullToRefresh(
      onRefresh: c.refresh,
      child: GlossScreen(
        topBar: topBar,
        scroll: false,
        fullBleed: true,
        body: LayoutBuilder(
          builder: (_, box) {
            final centred = (box.maxWidth - _pageMeasure) / 2;
            final side = centred > margin ? centred : margin;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    side,
                    GlossSpacing.large,
                    side,
                    GlossSpacing.extraLarge +
                        ShellInsets.of(context) +
                        media.padding.bottom,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 12,
                          children: [
                            ...controls,
                            // An empty list stands in the same page as a
                            // full one, so the search field the reader is
                            // typing in stays put (rebuilt elsewhere, it
                            // would lose the keys on the web).
                            if (result.isEmpty)
                              empty
                            else
                              GlossSectionHeader(w.totalTasks(result.length)),
                          ],
                        ),
                      ),
                      DecoratedSliver(
                        decoration: _WellFace(
                          well,
                          highContrast:
                              MediaQuery.maybeHighContrastOf(context) ?? false,
                        ),
                        sliver: SliverList.builder(
                          itemCount: result.length,
                          itemBuilder: (_, i) => ClipRRect(
                            key: ValueKey('task-well-row-${result[i].id}'),
                            borderRadius: BorderRadius.vertical(
                              top: i == 0 ? corner : Radius.zero,
                              bottom: i == result.length - 1
                                  ? corner
                                  : Radius.zero,
                            ),
                            child: IconTheme.merge(
                              data: IconThemeData(color: well.foreground),
                              child: DefaultTextStyle.merge(
                                style: TextStyle(color: well.foreground),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // The line stops at the well's wall.
                                    if (i > 0)
                                      const GlossEngravedLine(
                                        indent: 0,
                                        endIndent: 2,
                                      ),
                                    _taskRow(result[i]),
                                  ],
                                ),
                              ),
                            ),
                          ),
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

  Widget _taskRow(Task t) {
    final ids = {t.id};
    final selected = c.selecting
        ? c.selected.contains(t.id)
        : c.draft?.task.id == t.id;
    final tile = GlossListTile(
      leading: c.selecting
          ? Icon(selected ? LucideIcons.squareCheck : LucideIcons.square)
          : ExcludeSemantics(
              // 32, so the initials read (at 24 they were 7 px, grey on grey).
              child: GlossAvatar(name: c.personName(t.assignee), size: 32),
            ),
      title: w.text(t.title),
      subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
      selected: selected,
      showChevron: false,
      onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
    );
    // Swipe actions merge their child's semantics. Keep the independent
    // menu bead beside the swipe target so screen readers can open it.
    return Row(
      children: [
        Expanded(
          child: GlossSwipeRow(
            endActions: [
              GlossSwipeAction(
                label: t.done ? w.reopen : w.complete,
                icon: LucideIcons.check,
                onPressed: () =>
                    act(ids, () => c.changeTasks(ids, done: !t.done)),
              ),
              GlossSwipeAction(
                label: w.delete,
                icon: LucideIcons.trash2,
                isDestructiveAction: true,
                onPressed: () => remove(ids),
              ),
            ],
            child: tile,
          ),
        ),
        if (!c.selecting)
          // The bead keeps the tile's own inset from the card's edge.
          Padding(
            padding: const EdgeInsetsDirectional.only(
              end: GlossSpacing.regular,
            ),
            child: actions(ids, t.id),
          ),
      ],
    );
  }

  Widget actions(Set<String> ids, String label) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return GlossMenu(
      alignEnd: true,
      semanticLabel: w.actions,
      items: [
        GlossMenuItem(
          label: done ? w.reopen : w.complete,
          icon: LucideIcons.check,
          onPressed: () => act(ids, () => c.changeTasks(ids, done: !done)),
        ),
        GlossMenuItem(
          label: w.move,
          icon: LucideIcons.folder,
          onPressed: () => move(ids),
        ),
        GlossMenuItem(
          label: w.delete,
          icon: LucideIcons.trash2,
          isDestructiveAction: true,
          onPressed: () => remove(ids),
        ),
      ],
      builder: (_, toggle, _) => GlossIconButton(
        tooltip: '${w.actions}${w.dot}$label',
        icon: const Icon(LucideIcons.ellipsis, size: 16),
        onPressed: toggle,
      ),
    );
  }

  Future<void> act(Set<String> ids, VoidCallback change) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) change();
  }

  void remove(Set<String> ids) => act(ids, () {
    final removed = c.deleteTasks(ids);
    showGlossToast(
      notices.forList(context),
      w.deleted,
      actionLabel: w.undo,
      onAction: () => c.undoDelete(removed),
    );
  });

  Future<void> move(Set<String> ids) async {
    final project = await _raise<String>(
      context: context,
      cancel: w.cancel,
      title: w.move,
      builder: (ctx) => GlossWell(
        children: [
          for (final p in projects)
            GlossListTile(
              title: w.text(p.name),
              onTap: () => Navigator.pop(ctx, p.id),
            ),
        ],
      ),
    );
    if (project != null && mounted) {
      await act(ids, () => c.changeTasks(ids, project: project));
    }
  }

  Future<void> filterSheet() async {
    final f = c.filters;
    var status = f.status, sort = f.sort;
    var project = f.project, assignee = f.assignee;
    await _raise<void>(
      context: context,
      cancel: w.cancel,
      title: w.filters,
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
                      child: GlossSelect(
                        labelText: w.status,
                        value: status,
                        items: [
                          for (final s in TaskStatus.values)
                            GlossSelectItem(value: s, label: w.statusName(s)),
                        ],
                        onChanged: (v) => change(() => status = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: GlossSelect(
                        labelText: w.project,
                        value: project,
                        items: [
                          GlossSelectItem(value: '', label: w.all),
                          for (final p in projects)
                            GlossSelectItem(value: p.id, label: w.text(p.name)),
                        ],
                        onChanged: (v) => change(() => project = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: GlossSelect(
                        labelText: w.assignee,
                        value: assignee,
                        items: [
                          GlossSelectItem(value: '', label: w.all),
                          for (final p in team)
                            GlossSelectItem(value: p.id, label: w.text(p.name)),
                        ],
                        onChanged: (v) => change(() => assignee = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: GlossSelect(
                        labelText: w.sort,
                        value: sort,
                        items: [
                          for (final s in TaskSort.values)
                            GlossSelectItem(value: s, label: w.sortName(s)),
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
              runSpacing: 6,
              children: [
                GlossButton.filled(
                  w.apply,
                  onPressed: () {
                    c.filter((f) {
                      f.status = status;
                      f.sort = sort;
                      f.project = project;
                      f.assignee = assignee;
                    });
                    Navigator.pop(ctx);
                  },
                ),
                GlossButton.text(
                  w.reset,
                  onPressed: () {
                    reset();
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

/// The kit's page measure between its margins.
const double _pageMeasure = 1080;

/// A well's face painted behind a sliver: what [GlossSurface] paints round a
/// box, laid along the rows' whole extent as they scroll.
class _WellFace extends Decoration {
  const _WellFace(this.face, {required this.highContrast});

  final GlossFace face;
  final bool highContrast;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _WellPainter(this);

  @override
  bool operator ==(Object other) =>
      other is _WellFace &&
      other.face == face &&
      other.highContrast == highContrast;

  @override
  int get hashCode => Object.hash(face, highContrast);
}

class _WellPainter extends BoxPainter {
  _WellPainter(this.decoration);

  final _WellFace decoration;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) =>
      paintGlossFace(
        canvas,
        offset & configuration.size!,
        decoration.face,
        highContrast: decoration.highContrast,
      );
}

/// A short task sheet (Filters, Move, Add entry): on a phone Gloss's sheet
/// from the foot; from 600 px a dialog in the middle of the window, as Start
/// a timer and Sign out are, rather than a panel set down on its foot.
Future<T?> _raise<T>({
  required BuildContext context,
  required String title,
  required String cancel,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showGlossSheet<T>(context: context, title: title, builder: builder);
  }
  return showGlossDialog<T>(
    context: context,
    builder: (ctx) => GlossDialog(
      title: title,
      content: builder(ctx),
      actions: [
        GlossDialogAction(label: cancel, onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}
