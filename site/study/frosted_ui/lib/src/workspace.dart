part of '../stint_frosted.dart';

const _places = [
  LucideIcons.sunMedium,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings,
];
const _projectIcons = [
  LucideIcons.panelsTopLeft,
  LucideIcons.bookOpen,
  LucideIcons.shapes,
];

class _WorkspaceState extends State<_Workspace> {
  StintController get c => widget.c;
  StintWords get w => c.words;
  FrostedThemeData get glass => context.frostedTheme;
  final search = TextEditingController();
  final taskNavigator = GlobalKey<NavigatorState>();
  bool asking = false;
  // The task Today's stopped timer would start, once the reader chooses one.
  String? queued;
  void queue(String id) => setState(() => queued = id);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String shortcut(LogicalKeyboardKey key) {
    final platform = Theme.of(context).platform;
    final apple =
        platform == TargetPlatform.macOS || platform == TargetPlatform.iOS;
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
      final choice = await showFrostedDialog<bool>(
        context,
        builder: (ctx) => FrostedDialog(
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            FrostedButton(
              w.save,
              onPressed: () => Navigator.pop(ctx, true),
              expand: true,
            ),
            // Discard throws the edits away: the danger-tinted glass.
            FrostedButton.destructive(
              w.discard,
              onPressed: () => Navigator.pop(ctx, false),
              expand: true,
            ),
            FrostedButton.glass(
              w.cancel,
              onPressed: () => Navigator.pop(ctx),
              expand: true,
            ),
          ],
        ),
      );
      return mounted && choice != null && (!choice || c.saveTask());
    } finally {
      asking = false;
    }
  }

  Future<void> go(Place p) async {
    if (!await mayLeave() || !mounted) return;
    if (c.draft != null) {
      c.openTask(null);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) c.navigate(p);
  }

  Future<void> open(Task task) async {
    if (c.draft?.task.id != task.id && await mayLeave() && mounted) {
      c.openTask(task);
    }
  }

  void save() {
    if (c.signedIn && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      FrostedToast.show(context, w.saved);
    }
  }

  Future<void> commands() async {
    if (!c.signedIn || asking) return;
    await FrostedCommand.show(
      context,
      commands: [
        for (final p in Place.values)
          RawCommand(label: w.place(p), onPressed: () => go(p)),
        RawCommand(label: w.addEntry, onPressed: addTime),
        if (c.draft != null) RawCommand(label: w.save, onPressed: save),
      ],
      hintText: w.findCommand,
    );
  }

  // A phone has no keyboard to press K on: the key shows the look's search
  // glyph there, as the palette searches the app's commands.
  Widget get command => MediaQuery.sizeOf(context).width < 600
      ? _IconAct(icon: LucideIcons.search, label: w.commands, act: commands)
      : _IconAct(
          icon: LucideIcons.command,
          label: '${w.commands}${w.dot}${shortcut(LogicalKeyboardKey.keyK)}',
          act: commands,
        );
  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => FrostedErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      container: true,
      label: w.loading,
      liveRegion: true,
      child: const FrostedCard(child: FrostedSkeleton.text(lines: 4)),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return FrostedScaffold(
          topBar: FrostedAppBar.none,
          body: FrostedEmptyState(
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onAction: () => c.signIn(true),
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      final mode = width < 600
          ? RawNavigationMode.bar
          : width < 1024
          ? RawNavigationMode.rail
          : RawNavigationMode.sidebar;
      final bar = mode == RawNavigationMode.bar,
          rail = mode == RawNavigationMode.rail;
      final theme = glass, colors = theme.colorScheme;
      final pane = switch (c.place) {
        Place.today => today(),
        Place.tasks => tasks(),
        Place.time => time(),
        Place.settings => settings(),
      };
      return Stack(
        fit: StackFit.expand,
        children: [
          const FrostedBackdropView(),
          RawAdaptiveShell(
            mode: mode,
            selectedIndex: c.place.index,
            showNavigation: !bar || c.draft == null,
            onDestinationSelected: (i) => go(Place.values[i]),
            destinations: [
              for (final p in Place.values)
                RawNavigationDestination(
                  label: w.place(p),
                  icon: _places[p.index],
                ),
            ],
            destinationBuilder: (ctx, d, state) {
              final selected = state.states.contains(WidgetState.selected);
              final ink = selected ? colors.textPrimary : colors.textSecondary,
                  focus = state.states.contains(WidgetState.focused);
              final icon = Icon(d.icon, size: bar ? 19 : 21, color: ink);
              final label = Text(
                d.label,
                textAlign: bar ? TextAlign.center : TextAlign.start,
                style:
                    (bar
                            ? theme.textTheme.labelMedium
                            : theme.textTheme.bodyMedium)
                        .copyWith(
                          color: ink,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
              );
              final face = Container(
                key: ValueKey(Place.values[state.index]),
                constraints: BoxConstraints(minHeight: bar ? 52 : 46),
                padding: EdgeInsets.symmetric(
                  horizontal: bar
                      ? 1
                      : rail
                      ? 7
                      : 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: selected
                      ? theme.glass.navCurrent
                      : state.states.contains(WidgetState.hovered)
                      ? theme.glass.wash
                      : null,
                  borderRadius: BorderRadius.circular(bar ? 16 : 24),
                  border: Border.all(
                    color: focus
                        ? colors.textPrimary
                        : selected
                        ? theme.glass.rim
                        : const Color(0x00000000),
                    width: focus ? 2 : 1,
                  ),
                ),
                child: bar
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Center(child: icon),
                          label,
                        ],
                      )
                    : rail
                    ? Center(child: icon)
                    : Row(
                        spacing: 10,
                        children: [
                          icon,
                          Expanded(child: label),
                        ],
                      ),
              );
              return rail
                  ? FrostedTooltip(message: d.label, child: face)
                  : face;
            },
            navigationBuilder: (ctx, n) {
              if (bar) {
                return SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 5,
                    ),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.glass.fill,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: theme.glass.rim),
                        boxShadow: theme.shadows.raised,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(3),
                        child: IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 2,
                            children: [
                              for (final p in Place.values)
                                Expanded(
                                  flex:
                                      (TextPainter.computeWidth(
                                                text: TextSpan(
                                                  text: w.place(p),
                                                  style: theme
                                                      .textTheme
                                                      .labelMedium
                                                      .copyWith(
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                ),
                                                textDirection:
                                                    Directionality.of(ctx),
                                                textScaler:
                                                    MediaQuery.textScalerOf(
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
                      ),
                    ),
                  ),
                );
              }
              return Container(
                width: rail ? 76 : 232,
                color: theme.glass.sidebar,
                padding: EdgeInsets.symmetric(
                  horizontal: rail ? 8 : 14,
                  vertical: 26,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 5,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        start: rail ? 0 : 12,
                        bottom: 18,
                      ),
                      child: rail
                          ? const Icon(LucideIcons.layers3)
                          : Row(
                              spacing: 10,
                              children: [
                                const Icon(LucideIcons.layers3),
                                Flexible(
                                  child: Text(
                                    'Stint',
                                    style: theme.textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                    ),
                    ...n.destinations,
                  ],
                ),
              );
            },
            body: Semantics(container: true, child: pane),
          ),
        ],
      );
    },
  );

  Widget page(
    String title,
    Widget body, {
    String? caption,
    List<Widget>? actions,
  }) => FrostedScaffold(
    lights: true,
    topBar: title == w.greeting
        ? FrostedAppBar.greeting(
            title: title,
            subtitle: caption,
            actions: actions ?? [command],
          )
        : FrostedAppBar(
            title: title,
            caption: caption,
            actions: actions ?? [command],
          ),
    body: Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1140),
        child: body,
      ),
    ),
  );
  int projectIndex(String id) {
    final i = projects.indexWhere((p) => p.id == id);
    return i < 0 ? 0 : i;
  }

  Widget projectMark(String id) {
    final i = projectIndex(id);
    return FrostedIconMark(
      _projectIcons[i],
      hue: glass.hue(i),
      size: FrostedMarkSize.small,
    );
  }

  Widget hours(int minutes) => Text(
    w.duration(minutes),
    style: glass.textTheme.displaySmall,
    textAlign: TextAlign.start,
  );
}

class _Tag extends StatelessWidget {
  const _Tag(this.label);
  final String label;
  @override
  Widget build(BuildContext context) {
    if (MediaQuery.textScalerOf(context).scale(1) <= 1) {
      return FrostedTag(label);
    }
    final t = context.frostedTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.glass.wash,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(label, style: t.textTheme.labelSmall),
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.title,
    required this.meta,
    required this.leading,
    this.end,
    this.selected = false,
    this.onPressed,
  });
  final String title, meta;
  final Widget leading;

  /// The figure at the row's end: an entry's length.
  final String? end;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => FrostedListTile(
    title: title,
    meta: meta,
    leading: leading,
    trailing: end == null
        ? null
        : Text(end!, style: FrostedTheme.of(context).textTheme.bodyMedium),
    selected: selected,
    titleLines: 8,
    onPressed: onPressed,
  );
}

class _IconAct extends StatelessWidget {
  const _IconAct({
    required this.icon,
    required this.label,
    required this.act,
    this.size = FrostedIconButtonSize.regular,
  });
  final FrostedIconButtonSize size;
  final IconData icon;
  final String label;
  final VoidCallback? act;
  @override
  Widget build(BuildContext context) {
    return FrostedTooltip(
      message: label,
      child: FrostedIconButton(
        icon,
        semanticLabel: label,
        onPressed: act,
        size: size,
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions(this.items, {this.primaryLast = false});
  final List<(String, VoidCallback)> items;
  final bool primaryLast;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, b) {
      final style = ctx.frostedTheme.textTheme.labelLarge;
      final share = (b.maxWidth - 8 * (items.length - 1)) / items.length;
      final stack = items.any(
        (a) =>
            TextPainter.computeWidth(
                  text: TextSpan(text: a.$1, style: style),
                  textDirection: Directionality.of(ctx),
                  textScaler: MediaQuery.textScalerOf(ctx),
                ) +
                40 >
            share,
      );
      final acts = [
        for (final (i, a) in items.indexed)
          if (primaryLast && i == items.length - 1)
            FrostedButton(a.$1, onPressed: a.$2, expand: true)
          else
            FrostedButton.glass(a.$1, onPressed: a.$2, expand: true),
      ];
      return stack
          ? Column(
              spacing: 8,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: acts,
            )
          : Row(
              spacing: 8,
              children: [for (final act in acts) Expanded(child: act)],
            );
    },
  );
}
