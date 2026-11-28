part of '../stint_clay.dart';

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
                  // The pane keeps its bar with no task open, so the bar runs the
                  // window's width.
                  emptyDetailBuilder: (_) => ClayScreen(
                    topBar: ClayTopBar(title: w.taskDetail),
                    scroll: false,
                    body: _centred(
                      Visibility(
                        visible: c.hasRowToOpen,
                        child: ClayStateView(
                          state: ClayState.empty,
                          icon: LucideIcons.clipboardList,
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
    final topBar = ClayTopBar(
      title: w.tasks,
      actions: [
        ClayIconButton(
          tooltip: w.refresh,
          icon: const Icon(LucideIcons.refreshCw),
          onPressed: c.refresh,
        ),
        command,
      ],
    );
    final controls = <Widget>[
      ClaySearchField(
        controller: search,
        hintText: w.search,
        semanticLabel: w.search,
        onChanged: (v) => c.filter((f) => f.search = v),
      ),
      Builder(
        builder: (_) {
          final keys = [
            ClayButton(
              f.count == 0 ? w.filters : '${w.filters} (${w.number(f.count)})',
              icon: const Icon(LucideIcons.listFilter),
              onPressed: filterSheet,
            ),
            ClayButton(
              c.selecting ? w.stopSelecting : w.select,
              icon: Icon(c.selecting ? LucideIcons.x : LucideIcons.squareCheck),
              onPressed: () => c.toggleSelection(),
            ),
          ];
          // Side by side while each key's words fit its half on one line.
          return StintPair(
            first: keys.first,
            second: keys.last,
            spacing: ClaySpacing.medium,
            runSpacing: ClaySpacing.small,
          );
        },
      ),
      if (f.count > 0)
        RawChipGroup(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (f.status != TaskStatus.all)
              ClayChip(
                label: w.statusName(f.status),
                selected: true,
                onSelected: (_) => c.filter((f) => f.status = TaskStatus.all),
              ),
            if (f.project.isNotEmpty)
              ClayChip(
                label: c.projectName(f.project),
                selected: true,
                onSelected: (_) => c.filter((f) => f.project = ''),
              ),
            if (f.assignee.isNotEmpty)
              ClayChip(
                label: c.personName(f.assignee),
                selected: true,
                onSelected: (_) => c.filter((f) => f.assignee = ''),
              ),
          ],
        ),
      if (c.selecting)
        RawChipGroup(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ClayTag(w.selected(c.selected.length), tone: ClayTagTone.accent),
            ClayIconButton(
              tooltip: w.selectAll,
              icon: const Icon(LucideIcons.listChecks),
              onPressed: c.selectResults,
            ),
            if (c.selected.isNotEmpty)
              actions(c.selected, w.selected(c.selected.length)),
          ],
        ),
    ];
    final empty = ClayCard(
      child: ClayStateView(
        state: ClayState.empty,
        icon: noMatches ? LucideIcons.searchX : LucideIcons.partyPopper,
        title: noMatches ? w.noMatches : w.noTasks,
        message: noMatches ? w.searchHelp : w.allClear,
        actions: [if (noMatches) ClayButton(w.reset, onPressed: reset)],
      ),
    );
    if (c.state != DataState.ready) {
      return ClayPullToRefresh(
        onRefresh: c.refresh,
        child: ClayScreen(
          topBar: topBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ClaySpacing.regular,
            children: [...controls, dataBody(() => empty)],
          ),
        ),
      );
    }
    // The rows build as they scroll into view, each its band of one clay
    // slab: the slab's grooves between them, its rounded ends round the first
    // and last. The page keeps the screen's own measure, margins and foot.
    final media = MediaQuery.of(context);
    final margin = ClaySpacing.pageMargin(media.size.width);
    return ClayPullToRefresh(
      onRefresh: c.refresh,
      child: ClayScreen(
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
                    ClaySpacing.large,
                    side,
                    ClaySpacing.extraLarge + media.padding.bottom,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: ClaySpacing.regular,
                          children: [
                            ...controls,
                            // An empty list stands in the same page as a
                            // full one, so the search field the reader is
                            // typing in stays put (rebuilt elsewhere, it
                            // would lose the keys on the web).
                            if (result.isEmpty)
                              empty
                            else
                              ClaySectionHeader(w.totalTasks(result.length)),
                          ],
                        ),
                      ),
                      SliverList.builder(
                        itemCount: result.length,
                        itemBuilder: (_, i) => _SlabBand(
                          key: ValueKey('task-slab-row-${result[i].id}'),
                          first: i == 0,
                          last: i == result.length - 1,
                          child: _taskRow(result[i]),
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
    final tile = ClayListTile(
      leading: c.selecting
          ? ExcludeSemantics(
              child: ClayCheckMark(value: selected, states: const {}),
            )
          : ExcludeSemantics(
              child: ClayAvatar(
                name: c.personName(t.assignee),
                size: 36,
                tint:
                    _tints[team.indexWhere((p) => p.id == t.assignee) %
                        _tints.length],
              ),
            ),
      title: w.text(t.title),
      subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
      // The tile's own chosen plate, its words in the chosen row's colours.
      selected: selected,
      checked: c.selecting ? selected : null,
      showChevron: false,
      onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
    );
    // Swipe actions merge their child's semantics. Keep the row's own menu
    // ball beside the swipe target so screen readers can open it.
    return Row(
      children: [
        Expanded(
          child: ClaySwipeRow(
            endActions: [
              ClaySwipeAction(
                label: t.done ? w.reopen : w.complete,
                icon: LucideIcons.check,
                onPressed: () =>
                    act(ids, () => c.changeTasks(ids, done: !t.done)),
              ),
              ClaySwipeAction(
                label: w.delete,
                icon: LucideIcons.trash2,
                isDestructiveAction: true,
                onPressed: () => remove(ids),
              ),
            ],
            child: Semantics(selected: selected, child: tile),
          ),
        ),
        if (!c.selecting)
          Padding(
            padding: const EdgeInsetsDirectional.only(end: ClaySpacing.small),
            child: actions(ids, t.id),
          ),
      ],
    );
  }

  Widget actions(Set<String> ids, String label) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    return ClayMenu(
      alignEnd: true,
      semanticLabel: w.actions,
      items: [
        ClayMenuItem(
          label: done ? w.reopen : w.complete,
          icon: done ? LucideIcons.rotateCcw : LucideIcons.check,
          onPressed: () => act(ids, () => c.changeTasks(ids, done: !done)),
        ),
        ClayMenuItem(
          label: w.move,
          icon: LucideIcons.folderInput,
          onPressed: () => move(ids),
        ),
        ClayMenuItem(
          label: w.delete,
          icon: LucideIcons.trash2,
          isDestructiveAction: true,
          onPressed: () => remove(ids),
        ),
      ],
      builder: (_, toggle, _) => ClayIconButton.plain(
        tooltip: '${w.actions}${w.dot}$label',
        icon: const Icon(LucideIcons.ellipsis),
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
    showClayToast(
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
      builder: (ctx) => ClayGroup(
        children: [
          for (final (i, p) in projects.indexed)
            ClayListTile(
              leading: ClayIconTile(
                tint: _tints[i % _tints.length],
                child: const Icon(LucideIcons.folder),
              ),
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
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ClaySpacing.large,
          children: [
            LayoutBuilder(
              builder: (ctx, box) {
                final paired =
                    MediaQuery.sizeOf(ctx).width >= 600 &&
                    box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) >= 350;
                const gap = ClaySpacing.regular;
                final width = paired ? (box.maxWidth - gap) / 2 : box.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: ClaySelect(
                        labelText: w.status,
                        value: status,
                        items: [
                          for (final s in TaskStatus.values)
                            ClaySelectItem(value: s, label: w.statusName(s)),
                        ],
                        onChanged: (v) => change(() => status = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ClaySelect(
                        labelText: w.project,
                        value: project,
                        items: [
                          ClaySelectItem(value: '', label: w.all),
                          for (final p in projects)
                            ClaySelectItem(value: p.id, label: w.text(p.name)),
                        ],
                        onChanged: (v) => change(() => project = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ClaySelect(
                        labelText: w.assignee,
                        value: assignee,
                        items: [
                          ClaySelectItem(value: '', label: w.all),
                          for (final p in team)
                            ClaySelectItem(value: p.id, label: w.text(p.name)),
                        ],
                        onChanged: (v) => change(() => assignee = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: ClaySelect(
                        labelText: w.sort,
                        value: sort,
                        items: [
                          for (final s in TaskSort.values)
                            ClaySelectItem(value: s, label: w.sortName(s)),
                        ],
                        onChanged: (v) => change(() => sort = v),
                      ),
                    ),
                  ],
                );
              },
            ),
            Wrap(
              spacing: ClaySpacing.medium,
              runSpacing: ClaySpacing.small,
              children: [
                ClayButton.filled(
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
                ClayButton.text(
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

/// The screen's page measure between its margins.
const double _pageMeasure = 1080;

/// One row's band of a clay slab that runs the whole list. Each band paints
/// the slab taller than itself and keeps only its own height of it, so the
/// bands join into one slab with its rounded ends and shadow only at the
/// first and last, while the rows still build one at a time as they scroll.
class _SlabBand extends StatelessWidget {
  const _SlabBand({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });
  final bool first, last;
  final Widget child;

  /// How far the slab runs past a band it is cut from: past its corners and
  /// the soft edge of its shadow.
  static const double _reach = 72;

  @override
  Widget build(BuildContext context) {
    final colors = context.clayTheme.colors;
    return ClipRect(
      clipper: _BandClip(first: first, last: last, reach: _reach),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: first ? 0 : -_reach,
            bottom: last ? 0 : -_reach,
            child: ClaySurface(
              face: ClayFace.raised(
                colors,
                radius: context.clayTheme.shapeScheme.corners.large,
              ),
            ),
          ),
          IconTheme.merge(
            data: IconThemeData(color: colors.inkSecondary),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!first)
                  const ClayGroove(
                    indent: ClayListTile.leadingExtent,
                    endIndent: ClaySpacing.roomy,
                  ),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuts a band out of the slab across its height only: the shadow at its
/// sides stays, and at the first and last band the slab's ends and the
/// shadow under them.
class _BandClip extends CustomClipper<Rect> {
  const _BandClip({
    required this.first,
    required this.last,
    required this.reach,
  });
  final bool first, last;
  final double reach;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
    -reach,
    first ? -reach : 0,
    size.width + reach,
    last ? size.height + reach : size.height,
  );

  @override
  bool shouldReclip(_BandClip old) =>
      old.first != first || old.last != last || old.reach != reach;
}

/// A short task sheet (Filters, Move, Add entry): on a phone Clay's sheet
/// from the foot; from 600 px a dialog in the middle of the window, as Start
/// a timer and Sign out are, rather than a panel set down on its foot.
Future<T?> _raise<T>({
  required BuildContext context,
  required String title,
  required String cancel,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showClayBottomSheet<T>(
      context: context,
      title: title,
      builder: builder,
    );
  }
  return showClayDialog<T>(
    context: context,
    builder: (ctx) => ClayDialog(
      title: title,
      content: builder(ctx),
      actions: [
        ClayDialogAction(label: cancel, onPressed: () => Navigator.pop(ctx)),
      ],
    ),
  );
}
