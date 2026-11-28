part of '../stint_minimal.dart';

const _icons = [
  LucideIcons.calendarDays,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => MinimalToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  final taskNavigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  bool deciding = false;

  /// The day of a week whose bar was pressed, read out over the chart.
  (DateTime, int)? bar;
  void readBar(DateTime week, int day) => setState(() => bar = (week, day));
  String get modifier =>
      Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<bool> mayLeave() async {
    if (c.draft?.dirty != true) return true;
    if (deciding) return false;
    deciding = true;
    try {
      final choice = await showMinimalDialog<bool>(
        context,
        builder: (ctx) => MinimalDialog(
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            RawDialogAction(
              label: w.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            // Discard throws the edits away, in the destructive fill.
            RawDialogAction(
              label: w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            RawDialogAction(
              label: w.save,
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      return mounted && choice != null && (!choice || c.saveTask());
    } finally {
      deciding = false;
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
    if (c.draft?.task.id == t.id) return;
    if (await mayLeave() && mounted) c.openTask(t);
  }

  void saveShortcut() {
    if (c.signedIn &&
        c.place == Place.tasks &&
        c.draft?.dirty == true &&
        c.saveTask()) {
      releaseSaveFocus();
      showMinimalSnackBar(notices.forDetail(context), w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || deciding) return;
    MinimalCommand.show(
      context,
      title: w.commands,
      hintText: w.findCommand,
      emptyTitle: w.noCommands,
      actions: [
        for (final p in Place.values)
          MinimalCommandItem(
            w.place(p),
            icon: _icons[p.index],
            onSelected: () => go(p),
          ),
        MinimalCommandItem(
          w.addEntry,
          icon: LucideIcons.timer,
          onSelected: addTime,
        ),
        if (c.draft != null)
          MinimalCommandItem(
            w.save,
            shortcut: '${modifier}S',
            onSelected: saveShortcut,
          ),
      ],
    );
  }

  MinimalIconButton icon(IconData glyph, String label, VoidCallback? action) =>
      MinimalIconButton(
        glyph,
        semanticLabel: label,
        onPressed: action,
        variant: MinimalIconButtonVariant.ghost,
      );
  // A phone has no keyboard to press K on: the key shows the look's search
  // glyph there, as the palette searches the app's commands.
  Widget get commandKey => MediaQuery.sizeOf(context).width < 600
      ? MinimalTooltip(
          message: w.commands,
          child: icon(LucideIcons.search, w.commands, palette),
        )
      : MinimalTooltip(
          message: '${w.commands}  ${modifier}K',
          child: icon(LucideIcons.command, w.commands, palette),
        );
  Widget get brand => Builder(
    builder: (context) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const MinimalIconTile(LucideIcons.timer, size: 30),
        const SizedBox(width: 10),
        Flexible(child: Text('Stint', style: context.minimalTheme.h2)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final t = context.minimalTheme;
      if (!c.signedIn) {
        return MinimalScaffold(
          body: MinimalEmptyState(
            icon: LucideIcons.logOutDir,
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onAction: () => c.signIn(true),
          ),
        );
      }
      return ColoredBox(
        color: t.background,
        child: RawAdaptiveShell(
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _icons[p.index],
              ),
          ],
          selectedIndex: c.place.index,
          onDestinationSelected: (i) => go(Place.values[i]),
          destinationBuilder: (ctx, item, details) {
            final selected = details.states.contains(WidgetState.selected);
            final focused = details.states.contains(WidgetState.focused);
            final side = details.mode == RawNavigationMode.sidebar;
            final ink = selected ? t.foreground : t.mutedForeground;
            final glyph = Icon(item.icon, size: 18, color: ink);
            final style = (side ? t.body : t.caption).copyWith(
              color: ink,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            );
            final text = LayoutBuilder(
              builder: (ctx, box) {
                // A tab too narrow for German's 'Zeiterfassung' on one line
                // (a phone at a large text size) names it 'Stunden'; its
                // spoken name stays whole.
                final short =
                    !side &&
                    item.label == w.time &&
                    textWidth(
                          ctx,
                          w.time,
                          style.copyWith(fontWeight: FontWeight.w600),
                        ) >
                        box.maxWidth;
                return Text(
                  short ? w.timeShort : item.label,
                  style: style,
                  textAlign: side ? TextAlign.start : TextAlign.center,
                );
              },
            );
            return Container(
              alignment: side ? AlignmentDirectional.centerStart : null,
              constraints: BoxConstraints(minHeight: side ? 44 : 54),
              padding: EdgeInsets.symmetric(
                horizontal: side ? 12 : 2,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: selected ? t.muted : null,
                border: Border.all(
                  color: focused ? t.ring : t.background.withValues(alpha: 0),
                ),
                borderRadius: BorderRadius.circular(5),
              ),
              child: side
                  ? Row(
                      children: [
                        glyph,
                        const SizedBox(width: 11),
                        Expanded(child: text),
                      ],
                    )
                  : details.mode == RawNavigationMode.bar
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [glyph, const SizedBox(height: 2), text],
                    )
                  : Center(child: glyph),
            );
          },
          navigationBuilder: (ctx, nav) {
            final bar = nav.mode == RawNavigationMode.bar,
                side = nav.mode == RawNavigationMode.sidebar;
            final destinations = nav.destinations;
            final scaler = MediaQuery.textScalerOf(ctx);
            int tabFlex(Place place) {
              if (scaler.scale(1) <= 1.4) return 1;
              final labelWidth = TextPainter.computeWidth(
                text: TextSpan(
                  text: w.place(place),
                  style: t.caption.copyWith(fontWeight: FontWeight.w600),
                ),
                textDirection: Directionality.of(ctx),
                textScaler: scaler,
              );
              return (labelWidth + 8).ceil();
            }

            return Container(
              width: bar
                  ? null
                  : side
                  ? 214 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1.0, 1.4)
                  : 64,
              decoration: BoxDecoration(
                color: t.card,
                border: bar
                    ? Border(top: t.rule)
                    : BorderDirectional(end: t.rule),
              ),
              child: SafeArea(
                child: bar
                    ? Row(
                        children: [
                          for (final place in Place.values)
                            Expanded(
                              flex: tabFlex(place),
                              child: destinations[place.index],
                            ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: side ? 18 : 8,
                              vertical: 22,
                            ),
                            child: side
                                ? brand
                                : const MinimalIconTile(LucideIcons.timer),
                          ),
                          if (side)
                            Padding(
                              padding: const EdgeInsetsDirectional.fromSTEB(
                                18,
                                14,
                                12,
                                8,
                              ),
                              child: Text(
                                w.teamName,
                                style: t.caption.copyWith(
                                  color: t.mutedForeground,
                                ),
                              ),
                            ),
                          for (final d in destinations)
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              child: d,
                            ),
                        ],
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

  Widget dataBody(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: const MinimalSkeleton.text(lines: 6),
    ),
    DataState.error => MinimalErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
  };
}
