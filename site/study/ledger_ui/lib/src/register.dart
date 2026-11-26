part of '../stint_ledger.dart';

enum _TaskAction { toggle, move, delete }

extension _Register on _BookState {
  List<LedgerSelectItem<String>> get projectItems => [
    for (final p in projects)
      LedgerSelectItem(value: p.id, label: w.text(p.name)),
  ];

  Widget register() => NavigatorPopHandler<void>(
    onPopWithResult: (_) => navigator.currentState?.maybePop(),
    // The routes keep nodes of their own, as the app's navigator's do. Under
    // a container that merges, a route's node comes only when a list opens
    // over it, and on the web the field's input moves into it and loses the
    // focus the tap just gave it.
    child: Semantics(
      explicitChildNodes: true,
      child: Navigator(
        key: navigator,
        onGenerateRoute: (_) => PageRouteBuilder<void>(
          transitionDuration: Duration.zero,
          reverseTransitionDuration: Duration.zero,
          pageBuilder: (ctx, _, _) => ListenableBuilder(
            listenable: c,
            builder: (ctx, _) => RawListDetail<String>(
              selectedItem: c.draft?.task.id,
              onSelectedItemChanged: (id) {
                if (id == null) c.openTask(null);
              },
              listWidth: 470,
              listBuilder: (_) => taskRegister(),
              detailRouteBuilder: (build) =>
                  MaterialPageRoute<void>(builder: build),
              detailBuilder: (_, id) =>
                  _Record(key: ValueKey(id), book: this, id: id),
              emptyDetailBuilder: (_) => LedgerScreen(
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 22,
                  children: [
                    // The ask stands only beside a row to open; the projects
                    // stay, as a way back from a search that matched none.
                    if (c.hasRowToOpen) ...[
                      Text(w.chooseTask, style: ink.title),
                      Text(w.chooseTaskHelp, style: ink.body),
                    ],
                    if (c.state == DataState.ready &&
                        c.data.tasks.isNotEmpty) ...[
                      LedgerHead(w.byProject),
                      LedgerRows(
                        children: [
                          for (final p in projects)
                            LedgerRow(
                              title: w.text(p.name),
                              value: Text(
                                w.number(
                                  c.openTasks
                                      .where((t) => t.project == p.id)
                                      .length,
                                ),
                                style: ink.amount,
                              ),
                              subtitle: w.openTasks,
                              onTap: () => c.filter((f) {
                                f.project = p.id;
                                f.status = TaskStatus.open;
                              }),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget taskRegister() {
    final f = c.filters, result = c.visible;
    final top = bar(w.tasks, refresh: true);
    // Beside the side bar the masthead stands where every other page's
    // does (the wide screen's 56 from the start, 40 from the top), so the
    // header holds still between pages; the list keeps 20 to the pane.
    final room = LedgerLayout.isWide(context)
        ? const EdgeInsetsDirectional.fromSTEB(56, 40, 20, 12)
        : const EdgeInsetsDirectional.symmetric(horizontal: 20, vertical: 12);
    final controls = <Widget>[
      // The field holds one control however much is typed. ui_core's
      // field makes one node of a lone entry and splits it once a second
      // control joins; on the web that split set up a new input on the
      // first key, and the keys typed were lost. So the clear key is not
      // in the field: it stands over the field's end, in the glyph's slot,
      // a node of its own after the field's.
      Stack(
        children: [
          LedgerTextField(
            key: const ValueKey('search-tasks'),
            controller: search,
            labelText: w.search,
            textInputAction: TextInputAction.search,
            trailing: CompositedTransformTarget(
              link: searchEnd,
              child: ExcludeSemantics(
                child: f.search.isEmpty
                    ? Icon(
                        LucideIcons.search,
                        color: ink.textSecondary,
                        size: 18,
                      )
                    : SizedBox.square(
                        dimension: LedgerIconButton.sideOf(
                          ink,
                          LedgerIconButtonSize.medium,
                        ),
                      ),
              ),
            ),
            onChanged: (v) => c.filter((f) => f.search = v),
          ),
          if (f.search.isNotEmpty)
            PositionedDirectional(
              top: 0,
              start: 0,
              child: CompositedTransformFollower(
                link: searchEnd,
                targetAnchor: Alignment.center,
                followerAnchor: Alignment.center,
                child: action(LucideIcons.x, w.clear, () {
                  search.clear();
                  c.filter((f) => f.search = '');
                }),
              ),
            ),
        ],
      ),
      Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          LedgerButton(
            f.count == 0 ? w.filters : '${w.filters} (${w.number(f.count)})',
            icon: LucideIcons.listFilter,
            size: LedgerButtonSize.medium,
            onPressed: filter,
          ),
          LedgerButton(
            c.selecting ? w.stopSelecting : w.select,
            size: LedgerButtonSize.medium,
            onPressed: () => c.toggleSelection(),
          ),
        ],
      ),
      if (f.project.isNotEmpty ||
          f.assignee.isNotEmpty ||
          f.status != TaskStatus.all)
        RawChipGroup(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (f.status != TaskStatus.all)
              LedgerChip(
                w.statusName(f.status),
                selected: true,
                onTap: () => c.filter((p) => p.status = TaskStatus.all),
              ),
            if (f.project.isNotEmpty)
              LedgerChip(
                c.projectName(f.project),
                selected: true,
                onTap: () => c.filter((p) => p.project = ''),
              ),
            if (f.assignee.isNotEmpty)
              LedgerChip(
                c.personName(f.assignee),
                selected: true,
                onTap: () => c.filter((p) => p.assignee = ''),
              ),
          ],
        ),
      if (c.selecting)
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(w.selected(c.selected.length), style: ink.meta),
            action(LucideIcons.listChecks, w.selectAll, c.selectResults),
            if (c.selected.isNotEmpty) actions(c.selected, w.actions),
          ],
        ),
    ];
    final matches = f.active && c.data.tasks.isNotEmpty;
    final empty = LedgerEmptyState(
      title: matches ? w.noMatches : w.noTasks,
      body: matches ? w.searchHelp : w.allClear,
      actionLabel: matches ? w.reset : null,
      onActionPressed: matches ? reset : null,
    );
    if (c.state != DataState.ready) {
      return LedgerPullToRefresh(
        onRefresh: c.refresh,
        child: LedgerScreen(
          topBar: top,
          padding: room,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [...controls, load(() => empty)],
          ),
        ),
      );
    }
    // The rows build as they scroll into view. The page keeps the screen's
    // own layout: on a phone the strip stands over the page and the
    // masthead scrolls with it, 28 above the first section; beside a rail
    // or side bar the masthead heads the page. The register ends the
    // shell's reserve under its last row.
    final wide = LedgerLayout.isWide(context);
    final strip = !wide && !LedgerSideInset.besideOf(context);
    return LedgerPullToRefresh(
      onRefresh: c.refresh,
      child: LedgerScreen(
        topBar: LedgerTopBar.none,
        padding: EdgeInsets.zero,
        scrollable: false,
        body: Builder(
          builder: (inner) => Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: room.copyWith(
                        top:
                            room.top +
                            (strip ? LedgerChromeMetrics.topBarHeight : 0),
                        bottom:
                            room.bottom + MediaQuery.paddingOf(inner).bottom,
                      ),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                LedgerBarSlotScope(
                                  slot: LedgerBarSlot.masthead,
                                  child: top,
                                ),
                                if (!wide)
                                  const SizedBox(
                                    height: LedgerChromeMetrics.firstSectionGap,
                                  ),
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  spacing: 14,
                                  children: [
                                    ...controls,
                                    // An empty list stands in the same page
                                    // as a full one, so the search field the
                                    // reader is typing in stays put (rebuilt
                                    // elsewhere, it lost the keys).
                                    if (result.isEmpty)
                                      empty
                                    else
                                      LedgerHead(w.totalTasks(result.length)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          SliverList.separated(
                            itemCount: result.length,
                            itemBuilder: (_, i) => KeyedSubtree(
                              key: ValueKey('task-row-${result[i].id}'),
                              child: taskRow(result[i]),
                            ),
                            separatorBuilder: (_, _) => ColoredBox(
                              color: ink.hairline,
                              child: const SizedBox(
                                height: LedgerLayout.hairline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (strip)
                Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: LedgerBarSlotScope(
                    slot: LedgerBarSlot.strip,
                    child: top,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget taskRow(Task task) {
    final title = w.text(task.title);
    final selected = c.selecting
        ? c.selected.contains(task.id)
        : c.draft?.task.id == task.id;
    return ColoredBox(
      color: selected ? ink.selectedFill : ink.background,
      child: Row(
        children: [
          Expanded(
            child: LedgerRow(
              title: title,
              subtitle:
                  '${c.projectName(task.project)}${w.dot}${w.shortDate(task.due)}',
              semanticLabel:
                  '$title, ${c.projectName(task.project)}, ${w.shortDate(task.due)}',
              onTap: () =>
                  c.selecting ? c.toggleSelection(task.id) : open(task),
            ),
          ),
          if (c.selecting)
            LedgerCheckbox(
              value: selected,
              semanticLabel: title,
              onChanged: (_) => c.toggleSelection(task.id),
            )
          else
            actions({task.id}, '${w.actions}${w.dot}${task.id}'),
        ],
      ),
    );
  }

  Widget actions(Set<String> targets, String label) =>
      action(LucideIcons.ellipsis, label, () async {
        final ids = Set.of(targets);
        final done = c.data.tasks
            .where((t) => ids.contains(t.id))
            .every((t) => t.done);
        final chosen = await showLedgerActionSheet<_TaskAction>(
          context,
          title: label,
          cancelLabel: w.cancel,
          acts: [
            LedgerSheetAct(
              done ? w.reopen : w.complete,
              value: _TaskAction.toggle,
              icon: LucideIcons.check,
            ),
            LedgerSheetAct(
              w.move,
              value: _TaskAction.move,
              icon: LucideIcons.folderInput,
            ),
            LedgerSheetAct(
              w.delete,
              value: _TaskAction.delete,
              icon: LucideIcons.trash2,
              isDestructiveAction: true,
            ),
          ],
        );
        if (chosen == null || !mounted) return;
        if (ids.contains(c.draft?.task.id) && !await mayLeave()) return;
        if (!mounted) return;
        switch (chosen) {
          case _TaskAction.toggle:
            c.changeTasks(ids, done: !done);
          case _TaskAction.move:
            final to = await showLedgerActionSheet<String>(
              context,
              title: w.move,
              cancelLabel: w.cancel,
              acts: [
                for (final p in projects)
                  LedgerSheetAct(w.text(p.name), value: p.id),
              ],
            );
            if (mounted && to != null) c.changeTasks(ids, project: to);
          case _TaskAction.delete:
            final deleted = c.deleteTasks(ids);
            LedgerToast.show(
              context,
              w.deleted,
              actionLabel: w.undo,
              onActionPressed: () => c.undoDelete(deleted),
            );
        }
      });

  void reset() {
    search.clear();
    c.filter((f) => f.reset());
  }

  Future<void> filter() async {
    final f = c.filters;
    var status = f.status,
        project = f.project,
        person = f.assignee,
        sort = f.sort;
    await LedgerSheet.show<void>(
      context,
      title: w.filters,
      builder: (sheet) => [
        StatefulBuilder(
          builder: (ctx, set) => Column(
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
                        child: LedgerSelect(
                          labelText: w.status,
                          value: status,
                          items: [
                            for (final s in TaskStatus.values)
                              LedgerSelectItem(
                                value: s,
                                label: w.statusName(s),
                              ),
                          ],
                          onChanged: (v) => set(() => status = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: LedgerSelect(
                          labelText: w.project,
                          value: project,
                          items: [
                            LedgerSelectItem(value: '', label: w.all),
                            ...projectItems,
                          ],
                          onChanged: (v) => set(() => project = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: LedgerSelect(
                          labelText: w.assignee,
                          value: person,
                          items: [
                            LedgerSelectItem(value: '', label: w.all),
                            for (final p in team)
                              LedgerSelectItem(
                                value: p.id,
                                label: w.text(p.name),
                              ),
                          ],
                          onChanged: (v) => set(() => person = v),
                        ),
                      ),
                      SizedBox(
                        width: width,
                        child: LedgerSelect(
                          labelText: w.sort,
                          value: sort,
                          items: [
                            for (final s in TaskSort.values)
                              LedgerSelectItem(value: s, label: w.sortName(s)),
                          ],
                          onChanged: (v) => set(() => sort = v),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
      foot: (sheet) => [
        LedgerButton(
          w.reset,
          onPressed: () {
            reset();
            Navigator.pop(sheet);
          },
        ),
        LedgerButton.filled(
          w.apply,
          onPressed: () {
            c.filter((f) {
              f.status = status;
              f.project = project;
              f.assignee = person;
              f.sort = sort;
            });
            Navigator.pop(sheet);
          },
        ),
      ],
    );
  }
}
