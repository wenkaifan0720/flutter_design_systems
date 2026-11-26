part of '../stint_neumorphism.dart';

const _destinations = [
  LucideIcons.sun,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => NeumorphicToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  NeumorphicThemeData get plaster => NeumorphicTheme.of(context);
  final taskNavigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  bool asking = false;
  // The task Today's stopped timer would start, once the reader chooses one.
  String? queued;
  void queue(String id) => setState(() => queued = id);
  String get modifier =>
      Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<bool> mayLeave() async {
    if (c.draft?.dirty != true) return true;
    if (asking) return false;
    asking = true;
    try {
      final save = await showNeumorphicDialog<bool>(
        context,
        builder: (sheet) => NeumorphicDialog(
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            NeumorphicButton.text(
              w.cancel,
              onPressed: () => Navigator.pop(sheet),
            ),
            // Discard throws the edits away: the warning mark.
            NeumorphicButton(
              w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(sheet, false),
            ),
            NeumorphicButton.filled(
              w.save,
              onPressed: () => Navigator.pop(sheet, true),
            ),
          ],
        ),
      );
      return mounted && save != null && (!save || c.saveTask());
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

  Future<void> open(Task t) async {
    if (c.draft?.task.id != t.id && await mayLeave() && mounted) c.openTask(t);
  }

  void save() {
    if (c.signedIn && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      showNeumorphicToast(notices.forDetail(context), message: w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || asking) return;
    showNeumorphicCommand(
      context,
      hint: w.findCommand,
      commands: [
        for (final p in Place.values)
          RawCommand(
            label: w.place(p),
            data: _destinations[p.index],
            onPressed: () => go(p),
          ),
        RawCommand(
          label: w.addEntry,
          data: LucideIcons.plus,
          onPressed: addTime,
        ),
        if (c.draft != null)
          RawCommand(label: w.save, shortcut: '${modifier}S', onPressed: save),
      ],
    );
  }

  // A phone has no keyboard to press K on: the key shows the look's search
  // glyph there, as the palette searches the app's commands.
  Widget get command {
    final phone = MediaQuery.sizeOf(context).width < 600;
    return NeumorphicTooltip(
      message: phone ? w.commands : '${modifier}K',
      child: NeumorphicIconButton(
        phone ? LucideIcons.search : LucideIcons.command,
        label: w.commands,
        onPressed: palette,
      ),
    );
  }

  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => NeumorphicErrorState(
      title: w.loadError,
      message: w.retryHelp,
      retryLabel: RawWidgetsLocalizations.of(context).retryButtonLabel,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: const NeumorphicCard(
        children: [
          NeumorphicSkeleton.row(),
          NeumorphicSkeleton.row(),
          NeumorphicSkeleton.row(),
        ],
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return NeumorphicScaffold(
          body: NeumorphicCard(
            title: w.signedOut,
            children: [
              NeumorphicButton.filled(
                w.returnToStudio,
                onPressed: () => c.signIn(true),
              ),
            ],
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      return ColoredBox(
        color: plaster.colors.ground,
        child: RawAdaptiveShell(
          mode: width < 660
              ? RawNavigationMode.bar
              : width < 1040
              ? RawNavigationMode.rail
              : RawNavigationMode.sidebar,
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _destinations[p.index],
              ),
          ],
          selectedIndex: c.place.index,
          onDestinationSelected: (i) => go(Place.values[i]),
          destinationBuilder: (ctx, d, state) {
            final side = state.mode == RawNavigationMode.sidebar,
                rail = state.mode == RawNavigationMode.rail;
            final selected = state.states.contains(WidgetState.selected),
                focused = state.states.contains(WidgetState.focused);
            final ink = selected
                ? plaster.colors.accentInk
                : plaster.colors.ink;
            final icon = Icon(d.icon, size: 20, color: ink);
            final name = Text(
              d.label,
              style: (side ? plaster.textTheme.body : plaster.textTheme.micro)
                  .copyWith(color: ink),
              textAlign: side ? TextAlign.start : TextAlign.center,
            );
            final inside = ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: side ? 13 : 2,
                  vertical: 7,
                ),
                child: side
                    ? Row(
                        spacing: 12,
                        children: [
                          icon,
                          Expanded(child: name),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 3,
                        children: [icon, if (!rail) name],
                      ),
              ),
            );
            final face =
                focused ||
                    selected ||
                    state.states.contains(WidgetState.pressed)
                ? NeumorphicSurface(
                    cast: focused
                        ? NeumorphicSurfaceLevel.part
                        : NeumorphicSurfaceLevel.groove,
                    states: state.states,
                    radius: 12,
                    child: inside,
                  )
                : inside;
            return rail
                ? NeumorphicTooltip(message: d.label, child: face)
                : face;
          },
          navigationBuilder: (ctx, nav) {
            if (nav.mode == RawNavigationMode.bar) {
              return NeumorphicSlab(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
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
                                          style: plaster.textTheme.micro,
                                        ),
                                        textDirection: Directionality.of(ctx),
                                        textScaler: MediaQuery.textScalerOf(
                                          ctx,
                                        ),
                                      ) +
                                      18)
                                  .ceil(),
                          child: nav.destinations[p.index],
                        ),
                    ],
                  ),
                ),
              );
            }
            final full = nav.mode == RawNavigationMode.sidebar;
            return SizedBox(
              width: full ? 238 : 76,
              child: NeumorphicSlab(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 18,
                ),
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 8,
                    children: [
                      if (full)
                        const Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: 10,
                            bottom: 18,
                          ),
                          child: NeumorphicBrandRow(
                            'Stint',
                            mark: Icon(LucideIcons.layers),
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(bottom: 18),
                          child: Icon(LucideIcons.layers),
                        ),
                      ...nav.destinations,
                    ],
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
