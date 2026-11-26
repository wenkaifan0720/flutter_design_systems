part of '../stint_terminal.dart';

class _Console extends StatefulWidget {
  const _Console({super.key, required this.state});
  final StintController state;
  @override
  State<_Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<_Console> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => TermToaster(child: pane));
  StintController get c => widget.state;
  StintWords get w => c.words;
  TermThemeData get ink => TermTheme.of(context);
  final navigator = GlobalKey<NavigatorState>();
  final query = TextEditingController();
  bool asking = false;
  @override
  void dispose() {
    query.dispose();
    super.dispose();
  }

  String get mod =>
      Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';
  Future<bool> leave() async {
    if (c.draft?.dirty != true) return true;
    if (asking) return false;
    asking = true;
    try {
      final answer = await showTermDialog<bool>(
        context: context,
        semanticLabel: w.dirty,
        builder: (ctx) => TermDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            TermButton(label: w.cancel, onPressed: () => Navigator.pop(ctx)),
            // Discard throws the edits away: the danger ink.
            TermButton(
              label: w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            TermButton.filled(
              label: w.save,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      return mounted && answer != null && (!answer || c.saveTask());
    } finally {
      asking = false;
    }
  }

  Future<void> go(Place place) async {
    if (!c.signedIn || !await leave() || !mounted) return;
    if (c.draft != null) {
      c.openTask(null);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) c.navigate(place);
  }

  Future<void> open(Task task) async {
    if (task.id != c.draft?.task.id && await leave() && mounted) {
      c.openTask(task);
    }
  }

  void save() {
    if (c.signedIn && !asking && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      TermToaster.show(
        notices.forDetail(context),
        message: w.saved,
        tone: TermTone.success,
      );
    }
  }

  Future<void> commands() async {
    if (!c.signedIn || asking) return;
    await showTermCommandPalette(
      context: context,
      title: w.commands,
      hintText: w.findCommand,
      emptyText: w.noCommands,
      commands: [
        for (final p in Place.values)
          RawCommand(
            label: w.place(p),
            shortcut: termKeyLabel(_windowKeys[p.index]),
            onPressed: () => go(p),
          ),
        RawCommand(label: w.addEntry, onPressed: addEntry),
        if (c.draft != null)
          RawCommand(label: w.save, shortcut: '${mod}S', onPressed: save),
      ],
    );
  }

  Widget act(String glyph, String name, VoidCallback? press) => TermTooltip(
    message: name,
    child: TermIconButton(glyph: glyph, semanticLabel: name, onPressed: press),
  );
  Widget content(Widget Function() ready) => switch (c.state) {
    DataState.error => TermStatusView(
      status: TermStatus.error,
      title: w.loadError,
      message: w.retryHelp,
      action: TermButton(
        label: RawWidgetsLocalizations.of(context).retryButtonLabel,
        onPressed: c.refresh,
      ),
    ),
    DataState.loading => TermSkeleton(lines: 6, semanticLabel: w.loading),
    DataState.ready => ready(),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      final width = MediaQuery.sizeOf(ctx).width;
      final phone = width < 600;
      final enlarged = MediaQuery.textScalerOf(ctx).scale(1) > 1.45;
      const glyphs = ['~', '#', '◷', '='];
      final grid = ctx.termGrid;
      // Each native window occupies two inset cells, its number, colon, name
      // and mark. The name is measured as it is set: a name in a fallback
      // face (Arabic) is not as wide as its count of cells.
      final namedWindows = Place.values.fold(
        0.0,
        (sum, p) =>
            sum + textWidth(ctx, w.place(p), ink.textStyle) + grid.cols(5),
      );
      final reflow = phone && c.signedIn && namedWindows > width;
      final body = Semantics(
        container: true,
        explicitChildNodes: true,
        child: !c.signedIn
            ? _Page(
                children: [
                  TermEmptyState(
                    title: w.signedOut,
                    action: TermButton.filled(
                      label: w.returnToStudio,
                      onPressed: () => c.signIn(true),
                    ),
                  ),
                ],
              )
            : switch (c.place) {
                Place.today => home(),
                Place.tasks => queue(),
                Place.time => workLog(),
                Place.settings => configuration(),
              },
      );
      return TermScaffold(
        title: w.workspace,
        selectedIndex: c.place.index,
        onDestinationSelected: (i) => go(Place.values[i]),
        destinations: [
          if (c.signedIn && !reflow)
            for (final p in Place.values)
              TermNavigationDestination(
                label: w.place(p),
                glyph: glyphs[p.index],
                shortcut: _windowKeys[p.index],
              ),
        ],
        topBar: TermTopBar(
          title: 'stint',
          subtitle: c.signedIn && !(enlarged && phone)
              ? w.place(c.place)
              : null,
          actions: [
            if (c.signedIn) act('>', '${w.commands} ${mod}K', commands),
          ],
        ),
        statusLine: !c.signedIn || reflow
            ? null
            : TermStatusLine(
                mode: w.place(c.place).toUpperCase(),
                segments: [TermStatusSegment(c.draft?.task.id ?? w.teamName)],
                keys: [if (!phone) (keys: '${mod}K', label: w.commands)],
              ),
        body: reflow
            ? RawAdaptiveShell(
                mode: RawNavigationMode.bar,
                selectedIndex: c.place.index,
                onDestinationSelected: (i) => go(Place.values[i]),
                destinations: [
                  for (final p in Place.values)
                    RawNavigationDestination(
                      label: w.place(p),
                      icon: const IconData(0x20),
                    ),
                ],
                navigationBuilder: (ctx, nav) => ColoredBox(
                  color: ink.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < nav.destinations.length; i += 2)
                        Row(
                          children: [
                            for (final cell in nav.destinations.skip(i).take(2))
                              Expanded(child: cell),
                          ],
                        ),
                    ],
                  ),
                ),
                destinationBuilder: (ctx, dest, state) {
                  final selected = state.states.contains(WidgetState.selected);
                  final focused = state.states.contains(WidgetState.focused);
                  final fg = selected ? ink.background : ink.foreground;
                  return Container(
                    constraints: const BoxConstraints(minHeight: 44),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: selected ? ink.foreground : ink.surface,
                      border: Border.all(
                        color: focused ? ink.accent : ink.rule,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            w.number(state.index + 1),
                            style: ink.textStyle.copyWith(
                              color: selected ? fg : ink.accent,
                            ),
                          ),
                          SizedBox(width: ctx.termGrid.cellWidth / 2),
                          Flexible(
                            child: Text(
                              dest.label,
                              style: ink.textStyle.copyWith(color: fg),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                body: body,
              )
            : body,
      );
    },
  );

  String chartName(DateTime date) {
    final minutes = c.dailyMinutes(date);
    return '${w.logged}. ${[for (var i = 0; i < 7; i++) '${w.weekday(addDays(date, i))} ${w.duration(minutes[i])}'].join(', ')}';
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.value, {this.caption});
  final String value;
  final String? caption;
  @override
  Widget build(BuildContext ctx) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (caption != null) Text(caption!, style: TermTheme.of(ctx).dimStyle),
      Semantics(
        header: true,
        child: Text(value, style: TermTheme.of(ctx).boldStyle),
      ),
    ],
  );
}

class _Page extends StatelessWidget {
  const _Page({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext ctx) {
    final grid = ctx.termGrid;
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
        horizontal: grid.cellWidth,
        vertical: grid.lineHeight / 2,
      ),
      child: Column(
        spacing: grid.lineHeight * .65,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _Tiles extends StatelessWidget {
  const _Tiles({required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext ctx) => LayoutBuilder(
    builder: (ctx, box) {
      final gap = ctx.termGrid.cellWidth;
      if (box.maxWidth < ctx.termGrid.cols(75)) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: gap,
          children: [first, second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: gap,
        children: [
          Expanded(child: first),
          Expanded(child: second),
        ],
      );
    },
  );
}

class _Line extends StatelessWidget {
  const _Line({
    required this.name,
    this.meta,
    required this.mark,
    required this.onOpen,
    this.selected = false,
    this.accessibleName,
    this.keys,
    this.titleCols,
    this.action,
  });
  final String name, mark;
  final String? meta;

  /// The row's menu key or its selection box, on the chosen bar.
  final Widget? action;

  /// The cells the mark and name take before [meta]'s column; the tile's
  /// three fifths when null.
  final int? titleCols;

  /// The key that does the same, written at the row's end.
  final SingleActivator? keys;
  final bool selected;
  final VoidCallback onOpen;
  final String? accessibleName;
  @override
  Widget build(BuildContext ctx) => TermListTile(
    leading: Text(mark),
    title: Text(name),
    subtitle: meta == null ? null : Text(meta!),
    titleCols: titleCols,
    trailing: keys == null || !termKeysShown(ctx)
        ? null
        : Text(termKeyLabel(keys!)),
    selected: selected,
    onTap: onOpen,
    semanticLabel: accessibleName ?? (meta == null ? name : '$name, $meta'),
    action: action,
  );
}
