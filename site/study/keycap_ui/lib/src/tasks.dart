part of '../stint_keycap.dart';

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
                  emptyDetailBuilder: (_) => KeycapScreen(
                    topBar: KeycapAppBar(title: w.taskDetail),
                    scroll: false,
                    body: _centred(
                      Visibility(
                        visible: c.hasRowToOpen,
                        child: KeycapEmptyState(
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
    final topBar = KeycapAppBar(
      title: w.tasks,
      actions: [glyphKey(LucideIcons.refreshCw, w.refresh, c.refresh), command],
    );
    final controls = <Widget>[
      KeycapSearchField(
        controller: search,
        hintText: w.search,
        semanticLabel: w.search,
        onChanged: (v) => c.filter((f) => f.search = v),
      ),
      Builder(
        builder: (_) {
          final keys = [
            KeycapButton(
              icon: const Icon(LucideIcons.listFilter),
              onPressed: filterSheet,
              child: Text(
                f.count == 0
                    ? w.filters
                    : '${w.filters} (${w.number(f.count)})',
              ),
            ),
            KeycapButton(
              icon: Icon(c.selecting ? LucideIcons.x : LucideIcons.squareCheck),
              onPressed: () => c.toggleSelection(),
              child: Text(c.selecting ? w.stopSelecting : w.select),
            ),
          ];
          // Side by side while each key's words fit its half on one line.
          return StintPair(
            first: keys.first,
            second: keys.last,
            spacing: KeycapMetrics.keyGap,
            runSpacing: KeycapSpacing.small,
          );
        },
      ),
      if (f.count > 0)
        RawChipGroup(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (f.status != TaskStatus.all)
              KeycapChip(
                w.statusName(f.status),
                selected: true,
                onSelected: (_) => c.filter((f) => f.status = TaskStatus.all),
              ),
            if (f.project.isNotEmpty)
              KeycapChip(
                c.projectName(f.project),
                selected: true,
                onSelected: (_) => c.filter((f) => f.project = ''),
              ),
            if (f.assignee.isNotEmpty)
              KeycapChip(
                c.personName(f.assignee),
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
            KeycapTag(w.selected(c.selected.length), tone: KeycapTone.info),
            glyphKey(LucideIcons.listChecks, w.selectAll, c.selectResults),
            if (c.selected.isNotEmpty)
              actions(c.selected, w.selected(c.selected.length)),
          ],
        ),
    ];
    final empty = KeycapStatusView(
      status: KeycapStatus.empty,
      icon: noMatches ? LucideIcons.searchX : LucideIcons.partyPopper,
      title: noMatches ? w.noMatches : w.noTasks,
      message: noMatches ? w.searchHelp : w.allClear,
      action: noMatches
          ? KeycapButton(onPressed: reset, child: Text(w.reset))
          : null,
    );
    if (c.state != DataState.ready) {
      return KeycapRefresh(
        onRefresh: c.refresh,
        child: KeycapScreen(
          topBar: topBar,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KeycapSpacing.regular,
            children: [...controls, dataBody(() => empty)],
          ),
        ),
      );
    }
    // The rows build as they scroll into view, each its band of one page
    // well cut into the case: the well's rules between them, its rounded
    // ends round the first and last. The page keeps the screen's margins.
    final media = MediaQuery.of(context);
    final margin = KeycapSpacing.pageMargin(media.size.width);
    return KeycapRefresh(
      onRefresh: c.refresh,
      child: KeycapScreen(
        topBar: topBar,
        scroll: false,
        fullBleed: true,
        body: LayoutBuilder(
          builder: (_, box) {
            final wide = box.maxWidth - 2 * margin > KeycapScreen.pageWidth;
            return CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  // On the bar title's start edge, as the screen sets its
                  // own pages.
                  padding: EdgeInsetsDirectional.fromSTEB(
                    margin,
                    KeycapSpacing.small,
                    wide
                        ? box.maxWidth - margin - KeycapScreen.pageWidth
                        : margin,
                    KeycapSpacing.huge + media.padding.bottom,
                  ),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: KeycapSpacing.regular,
                          children: [
                            ...controls,
                            // An empty list stands in the same page as a
                            // full one, so the search field the reader is
                            // typing in stays put (rebuilt elsewhere, it
                            // would lose the keys on the web).
                            if (result.isEmpty)
                              empty
                            else
                              KeycapSectionHeader(w.totalTasks(result.length)),
                          ],
                        ),
                      ),
                      SliverList.builder(
                        itemCount: result.length,
                        itemBuilder: (_, i) => _WellBand(
                          key: ValueKey('task-well-row-${result[i].id}'),
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
    Widget tile = KeycapListTile(
      leading: ExcludeSemantics(
        child: c.selecting
            ? _Lead(
                child: KeycapToggleKey(
                  theme: theme,
                  states: const {},
                  latched: selected,
                  shape: KeycapToggleShape.square,
                  legend: (color, t) => CustomPaint(
                    size: const Size.square(14),
                    painter: _Tick(t, color),
                  ),
                ),
              )
            : KeycapAvatar(
                name: c.personName(t.assignee),
                slotId: t.assignee,
                size: 36,
              ),
      ),
      title: w.text(t.title),
      // A task's name may take a second line rather than lose its end.
      maxTitleLines: 2,
      subtitle: '${c.projectName(t.project)}${w.dot}${w.shortDate(t.due)}',
      selected: selected,
      showChevron: false,
      onTap: () => c.selecting ? c.toggleSelection(t.id) : open(t),
    );
    if (c.selecting) {
      tile = MergeSemantics(
        child: Semantics(checked: selected, child: tile),
      );
    }
    // Swipe actions merge their child's semantics. Keep the row's own menu
    // key beside the swipe target so screen readers can open it. The chosen
    // row's lit floor runs on under the key, one row to the well's end, as
    // the tile's own floor is lit.
    final lit = theme.colors.pageSelected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      color: selected ? lit : lit.withValues(alpha: 0),
      child: Row(
        children: [
          Expanded(
            child: KeycapSwipeActions(
              endActions: [
                RawSwipeAction(
                  label: t.done ? w.reopen : w.complete,
                  onPressed: () =>
                      act(ids, () => c.changeTasks(ids, done: !t.done)),
                ),
                RawSwipeAction(
                  label: w.delete,
                  destructive: true,
                  onPressed: () => remove(ids),
                ),
              ],
              child: tile,
            ),
          ),
          // The key keeps the row's own inset from the well's end, as the
          // avatar does from its start.
          if (!c.selecting)
            Padding(
              padding: const EdgeInsetsDirectional.only(
                end: KeycapSpacing.regular,
              ),
              child: actions(ids, t.id),
            ),
        ],
      ),
    );
  }

  Widget actions(Set<String> ids, String label) {
    final done = c.data.tasks
        .where((t) => ids.contains(t.id))
        .every((t) => t.done);
    final name = '${w.actions}${w.dot}$label';
    return KeycapMenu(
      semanticLabel: w.actions,
      entries: [
        RawMenuEntry(
          label: done ? w.reopen : w.complete,
          onPressed: () => act(ids, () => c.changeTasks(ids, done: !done)),
        ),
        RawMenuEntry(label: w.move, onPressed: () => move(ids)),
        const RawMenuEntry.divider(),
        // Delete is the loss: its row is printed in the danger ink.
        RawMenuEntry(
          label: w.delete,
          isDestructiveAction: true,
          onPressed: () => remove(ids),
        ),
      ],
      builder: (_, anchor) => KeycapTooltip(
        message: name,
        child: KeycapIconButton(
          icon: const Icon(LucideIcons.ellipsis),
          semanticLabel: name,
          onPressed: anchor.toggle,
        ),
      ),
    );
  }

  Future<void> act(Set<String> ids, VoidCallback change) async {
    if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
    if (mounted) change();
  }

  void remove(Set<String> ids) => act(ids, () {
    final removed = c.deleteTasks(ids);
    showKeycapToast(
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
      builder: (ctx) => KeycapListGroup(
        children: [
          for (final p in projects)
            KeycapListTile(
              leading: _Lead(child: _ProjectCap(project: p.id)),
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
          spacing: KeycapSpacing.large,
          children: [
            LayoutBuilder(
              builder: (ctx, box) {
                final paired =
                    MediaQuery.sizeOf(ctx).width >= 600 &&
                    box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) >= 350;
                const gap = KeycapSpacing.regular;
                final width = paired ? (box.maxWidth - gap) / 2 : box.maxWidth;
                return Wrap(
                  spacing: gap,
                  runSpacing: gap,
                  children: [
                    SizedBox(
                      width: width,
                      child: KeycapSelect(
                        labelText: w.status,
                        value: status,
                        items: [
                          for (final s in TaskStatus.values)
                            KeycapSelectItem(value: s, label: w.statusName(s)),
                        ],
                        onChanged: (v) => change(() => status = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: KeycapSelect(
                        labelText: w.project,
                        value: project,
                        items: [
                          KeycapSelectItem(value: '', label: w.all),
                          for (final p in projects)
                            KeycapSelectItem(
                              value: p.id,
                              label: w.text(p.name),
                            ),
                        ],
                        onChanged: (v) => change(() => project = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: KeycapSelect(
                        labelText: w.assignee,
                        value: assignee,
                        items: [
                          KeycapSelectItem(value: '', label: w.all),
                          for (final p in team)
                            KeycapSelectItem(
                              value: p.id,
                              label: w.text(p.name),
                            ),
                        ],
                        onChanged: (v) => change(() => assignee = v),
                      ),
                    ),
                    SizedBox(
                      width: width,
                      child: KeycapSelect(
                        labelText: w.sort,
                        value: sort,
                        items: [
                          for (final s in TaskSort.values)
                            KeycapSelectItem(value: s, label: w.sortName(s)),
                        ],
                        onChanged: (v) => change(() => sort = v),
                      ),
                    ),
                  ],
                );
              },
            ),
            Wrap(
              spacing: KeycapSpacing.medium,
              runSpacing: KeycapSpacing.small,
              children: [
                KeycapButton.accent(
                  onPressed: () {
                    c.filter((f) {
                      f.status = status;
                      f.sort = sort;
                      f.project = project;
                      f.assignee = assignee;
                    });
                    Navigator.pop(ctx);
                  },
                  child: Text(w.apply),
                ),
                KeycapButton.text(
                  onPressed: () {
                    reset();
                    Navigator.pop(ctx);
                  },
                  child: Text(w.reset),
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

/// One row's band of a page well that runs the whole list. Each band draws
/// the well taller than itself and keeps only its own height of it, so the
/// bands join into one well with its rounded ends only at the first and
/// last, while the rows still build one at a time as they scroll.
class _WellBand extends StatelessWidget {
  const _WellBand({
    super.key,
    required this.first,
    required this.last,
    required this.child,
  });
  final bool first, last;
  final Widget child;

  /// How far the well runs past a band it is cut from: past its corners.
  static const double _reach = 48;

  @override
  Widget build(BuildContext context) => ClipRect(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: first ? 0 : -_reach,
          bottom: last ? 0 : -_reach,
          child: const KeycapWell(page: true),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!first)
              const KeycapDivider(
                indent: KeycapSpacing.regular,
                endIndent: KeycapSpacing.regular,
              ),
            child,
          ],
        ),
      ],
    ),
  );
}

/// A short task sheet (Filters, Move, Add entry): on a phone Keycap's sheet
/// from the keyboard's front edge; from 600 px a dialog in the middle of the
/// window, as Start a timer and Sign out are.
Future<T?> _raise<T>({
  required BuildContext context,
  required String title,
  required String cancel,
  required WidgetBuilder builder,
}) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showKeycapBottomSheet<T>(
      context: context,
      title: title,
      builder: builder,
    );
  }
  return showKeycapDialog<T>(
    context: context,
    builder: (ctx) => KeycapDialog(
      title: title,
      content: builder(ctx),
      actions: [
        KeycapButton.text(
          onPressed: () => Navigator.pop(ctx),
          child: Text(cancel),
        ),
      ],
    ),
  );
}
