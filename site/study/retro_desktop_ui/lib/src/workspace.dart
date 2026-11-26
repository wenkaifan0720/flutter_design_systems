part of '../stint_retro_desktop.dart';

const _places = [
  RetroDesktopGlyphs.sunrise,
  RetroDesktopGlyphs.folder,
  RetroDesktopGlyphs.clock,
  LucideIcons.slidersHorizontal,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => RetroDesktopToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  RetroDesktopThemeData get desk => RetroDesktopTheme.of(context);
  final taskNavigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  bool asking = false;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String keys(LogicalKeyboardKey key) {
    final apple =
        Theme.of(context).platform == TargetPlatform.macOS ||
        Theme.of(context).platform == TargetPlatform.iOS;
    return rawShortcutLabel(
      context,
      SingleActivator(key, meta: apple, control: !apple),
      appleSymbols: false,
    );
  }

  Future<bool> mayLeave() async {
    if (c.draft?.dirty != true) return true;
    if (asking) return false;
    asking = true;
    try {
      final choice = await showRetroDesktopDialog<bool>(
        context,
        builder: (ctx) => RetroDesktopDialog(
          tone: RetroDesktopTone.warning,
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            RetroDesktopDialogAction<bool>(w.cancel),
            RetroDesktopDialogAction(w.discard, value: false),
            RetroDesktopDialogAction(
              w.save,
              value: true,
              isDefaultAction: true,
            ),
          ],
        ),
      );
      return mounted && choice != null && (!choice || c.saveTask());
    } finally {
      asking = false;
    }
  }

  Future<void> go(Place place) async {
    if (!await mayLeave() || !mounted) return;
    if (c.draft != null) {
      c.openTask(null);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) c.navigate(place);
  }

  Future<void> open(Task task) async {
    if (c.draft?.task.id != task.id && await mayLeave() && mounted) {
      c.openTask(task);
    }
  }

  void save() {
    if (c.signedIn && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      showRetroDesktopSnackBar(notices.forDetail(context), w.saved);
    }
  }

  Future<void> palette() async {
    if (!c.signedIn || asking) return;
    final choice = await showRetroDesktopDialog<RawCommand>(
      context,
      builder: (ctx) => RetroDesktopDialog(
        title: w.commands,
        content: [
          RawCommandPalette(
            semanticLabel: w.commands,
            onSelected: (command) => Navigator.pop(ctx, command),
            commands: [
              for (final p in Place.values)
                RawCommand(
                  label: w.place(p),
                  data: _places[p.index],
                  onPressed: () => go(p),
                ),
              RawCommand(
                label: w.addEntry,
                data: RetroDesktopGlyphs.plus,
                onPressed: addTime,
              ),
              if (c.draft != null)
                RawCommand(
                  label: w.save,
                  data: RetroDesktopGlyphs.check,
                  shortcut: keys(LogicalKeyboardKey.keyS),
                  onPressed: save,
                ),
            ],
            fieldBuilder: (_, f) => RetroDesktopSearchField(
              hintText: w.findCommand,
              clearLabel: w.clear,
              focusNode: f.focusNode,
              controller: f.controller,
              onEditingComplete: f.submit,
            ),
            emptyBuilder: (_) => Text(w.noCommands, style: desk.textTheme.body),
            itemBuilder: (_, command, states) {
              final active = states.contains(WidgetState.focused);
              final ink = active ? desk.colors.onHighlight : desk.colors.text;
              return ColoredBox(
                color: active ? desk.colors.highlight : desk.colors.paper,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  child: Row(
                    spacing: 9,
                    children: [
                      Icon(command.data as IconData?, color: ink, size: 17),
                      Expanded(
                        child: Text(
                          command.label,
                          style: desk.textTheme.row.copyWith(color: ink),
                        ),
                      ),
                      if (command.shortcut != null)
                        Text(
                          command.shortcut!,
                          style: desk.textTheme.meta.copyWith(color: ink),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
    if (mounted) choice?.onPressed?.call();
  }

  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.loading => Semantics(
      liveRegion: true,
      child: RetroDesktopSkeleton(label: w.loading, lines: 5),
    ),
    DataState.error => RetroDesktopErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
  };

  Widget get menuBar => RetroDesktopMenuBar(
    label: w.workspace,
    leading: const ExcludeSemantics(child: RetroDesktopSystemMark()),
    menus: [
      RawMenuEntry(
        label: 'Stint',
        children: [
          for (final p in Place.values)
            RawMenuEntry(
              label: w.place(p),
              checked: c.place == p,
              onPressed: () => go(p),
            ),
        ],
      ),
      RawMenuEntry(
        label: w.file,
        children: [
          RawMenuEntry(label: w.addEntry, onPressed: addTime),
          RawMenuEntry(
            label: w.save,
            shortcut: keys(LogicalKeyboardKey.keyS),
            onPressed: c.draft == null ? null : save,
          ),
          const RawMenuEntry.divider(),
          RawMenuEntry(
            label: w.commands,
            shortcut: keys(LogicalKeyboardKey.keyK),
            onPressed: palette,
          ),
        ],
      ),
    ],
    trailing: RetroDesktopTooltip(
      message: '${w.commands}${w.dot}${keys(LogicalKeyboardKey.keyK)}',
      child: RetroDesktopIconButton(
        RetroDesktopGlyphs.search,
        label: w.commands,
        onPressed: palette,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return RetroDesktopScaffold(
          body: RetroDesktopWindow(
            title: w.signedOut,
            icon: RetroDesktopGlyphs.user,
            child: RetroDesktopButton(
              w.returnToStudio,
              isDefaultAction: true,
              onPressed: () => c.signIn(true),
            ),
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      return RetroDesktopScaffold(
        scroll: false,
        fullBleed: true,
        appBar: menuBar,
        body: RawAdaptiveShell(
          mode: width < 660
              ? RawNavigationMode.bar
              : width < 1040
              ? RawNavigationMode.rail
              : RawNavigationMode.sidebar,
          selectedIndex: c.place.index,
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _places[p.index],
              ),
          ],
          onDestinationSelected: (i) => go(Place.values[i]),
          destinationBuilder: (ctx, d, s) {
            final bar = s.mode == RawNavigationMode.bar,
                rail = s.mode == RawNavigationMode.rail,
                selected = s.states.contains(WidgetState.selected);
            final style = bar ? desk.textTheme.caption : desk.textTheme.row;
            final ink = selected ? desk.colors.onHighlight : desk.colors.text;
            final name = Text(
              d.label,
              style: style.copyWith(color: ink),
              textAlign: bar ? TextAlign.center : TextAlign.start,
            );
            final icon = Icon(d.icon, size: bar ? 17 : 20, color: ink);
            final item = Container(
              key: ValueKey(Place.values[s.index]),
              constraints: const BoxConstraints(minHeight: 44),
              padding: EdgeInsets.symmetric(
                horizontal: bar ? 1 : 6,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: selected ? desk.colors.highlight : desk.colors.paper,
                border: Border.all(
                  width: s.states.contains(WidgetState.focused) ? 2 : 1,
                  color: s.states.contains(WidgetState.focused)
                      ? desk.colors.text
                      : selected
                      ? desk.colors.highlightDark
                      : desk.colors.paper,
                ),
              ),
              child: bar
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [icon, name],
                    )
                  : rail
                  ? icon
                  : Row(
                      spacing: 9,
                      children: [
                        icon,
                        Expanded(child: name),
                      ],
                    ),
            );
            return rail
                ? RetroDesktopTooltip(message: d.label, child: item)
                : item;
          },
          navigationBuilder: (ctx, n) {
            if (n.mode == RawNavigationMode.bar) {
              return RetroDesktopSurface(
                padding: const EdgeInsets.all(3),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      for (final p in Place.values)
                        Expanded(
                          flex:
                              (TextPainter.computeWidth(
                                        text: TextSpan(
                                          text: w.place(p),
                                          style: desk.textTheme.caption,
                                        ),
                                        textDirection: Directionality.of(ctx),
                                        textScaler: MediaQuery.textScalerOf(
                                          ctx,
                                        ),
                                      ) +
                                      16)
                                  .ceil(),
                          child: n.destinations[p.index],
                        ),
                    ],
                  ),
                ),
              );
            }
            final full = n.mode == RawNavigationMode.sidebar;
            return SizedBox(
              width: full ? 220 : 72,
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(
                    full ? 20 : 4,
                    full ? 24 : 12,
                    2,
                    2,
                  ),
                  child: full
                      ? RetroDesktopSurface(
                          padding: const EdgeInsets.all(6),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Semantics(
                                header: true,
                                child: Padding(
                                  padding: const EdgeInsetsDirectional.fromSTEB(
                                    4,
                                    3,
                                    4,
                                    7,
                                  ),
                                  child: Text(
                                    w.workspace,
                                    style: desk.textTheme.chrome,
                                  ),
                                ),
                              ),
                              RetroDesktopWell(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: n.destinations,
                                ),
                              ),
                            ],
                          ),
                        )
                      : RetroDesktopWell(
                          padding: const EdgeInsets.all(2),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: n.destinations,
                          ),
                        ),
                ),
              ),
            );
          },
          body: Semantics(
            container: true,
            child: switch (c.place) {
              Place.today => today(),
              Place.tasks => tasks(),
              Place.time => time(),
              Place.settings => settings(),
            },
          ),
        ),
      );
    },
  );
}

// The flat icon keys carry their name on hover and keyboard focus as well.
class _ToolButton extends StatelessWidget {
  const _ToolButton(this.icon, {required this.label, required this.onPressed});
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => RetroDesktopTooltip(
    message: label,
    child: RetroDesktopIconButton(icon, label: label, onPressed: onPressed),
  );
}

/// The week's total: the page's figure, in a well with its label over it,
/// as Today's Hours this week (a caption's small value at the line's far
/// end read as a footnote).
class _WeekFigure extends StatelessWidget {
  const _WeekFigure(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final t = RetroDesktopTheme.of(context);
    return MergeSemantics(
      child: RetroDesktopWell(
        key: const ValueKey('time-week-total'),
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: t.textTheme.caption),
            Text(value, style: t.textTheme.big),
          ],
        ),
      ),
    );
  }
}
