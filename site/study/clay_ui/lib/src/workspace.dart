part of '../stint_clay.dart';

const _places = [
  LucideIcons.sun,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => ClayToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  ClayThemeData get theme => ClayTheme.of(context);
  final search = TextEditingController();
  final taskNavigator = GlobalKey<NavigatorState>();
  bool deciding = false;
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
      final choice = await showClayDialog<bool>(
        context: context,
        builder: (ctx) => ClayDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            ClayDialogAction(
              label: w.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            // Discard throws the edits away, in the danger colour.
            ClayDialogAction(
              label: w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            ClayDialogAction(
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

  Future<void> open(Task task) async {
    if (c.draft?.task.id != task.id && await mayLeave() && mounted) {
      c.openTask(task);
    }
  }

  void save() {
    if (c.signedIn &&
        !deciding &&
        c.place == Place.tasks &&
        c.draft?.dirty == true &&
        c.saveTask()) {
      releaseSaveFocus();
      showClayToast(notices.forDetail(context), w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || deciding) return;
    showClayCommandPalette(
      context,
      hintText: w.findCommand,
      commands: [
        for (final p in Place.values)
          ClayCommand(
            label: w.place(p),
            icon: _places[p.index],
            onPressed: () => go(p),
          ),
        ClayCommand(
          label: w.addEntry,
          icon: LucideIcons.plus,
          onPressed: addTime,
        ),
        if (c.draft != null)
          ClayCommand(
            label: w.save,
            icon: LucideIcons.check,
            shortcut: '${modifier}S',
            onPressed: save,
          ),
      ],
    );
  }

  Widget get command => ClayIconButton(
    tooltip: '${w.commands}  ${modifier}K',
    icon: const Icon(LucideIcons.search),
    onPressed: palette,
  );

  Widget dataBody(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => ClayCard(
      child: ClayStateView(
        state: ClayState.error,
        icon: LucideIcons.cloudOff,
        title: w.loadError,
        message: w.retryHelp,
        actions: [
          ClayButton(
            RawWidgetsLocalizations.of(context).retryButtonLabel,
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: c.refresh,
          ),
        ],
      ),
    ),
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: ClayGroup(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: ClaySpacing.roomy,
                vertical: ClaySpacing.regular,
              ),
              child: ClaySkeleton(height: 24),
            ),
        ],
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return ClayScreen(
          body: ClayCard(
            child: ClayStateView(
              state: ClayState.success,
              icon: LucideIcons.doorOpen,
              title: w.signedOut,
              actions: [
                ClayButton.filled(
                  w.returnToStudio,
                  onPressed: () => c.signIn(true),
                ),
              ],
            ),
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      final desk = width >= ClayMetrics.sidebarBreakpoint;
      return ClayScaffold(
        destinations: [
          for (final p in Place.values)
            ClayDestination(icon: _places[p.index], label: w.place(p)),
        ],
        selectedIndex: c.place.index,
        onDestinationSelected: (i) => go(Place.values[i]),
        showNavigation: c.draft == null,
        brand: _StintMark(withName: desk),
        // Clay's one action is the coral ball at the dock's end (on a desk,
        // the coral key under the mark): a new time entry, from any place.
        action: desk
            ? LayoutBuilder(
                builder: (ctx, box) {
                  // The key's words keep to one line: where the plus and
                  // the words together outgrow the side bar (German), the
                  // words stand alone.
                  final theme = ClayTheme.of(ctx);
                  final room =
                      box.maxWidth -
                      theme.density
                          .padding(
                            const EdgeInsets.symmetric(
                              horizontal: ClaySpacing.large,
                            ),
                          )
                          .horizontal;
                  final words = textWidth(
                    ctx,
                    w.addEntry,
                    theme.textTheme.label.copyWith(
                      fontWeight: FontWeight.w600,
                      fontVariations: clayWeight(FontWeight.w600),
                    ),
                  );
                  return ClayButton.filled(
                    w.addEntry,
                    icon: words + 20 + ClaySpacing.small <= room
                        ? const Icon(LucideIcons.plus)
                        : null,
                    onPressed: addTime,
                  );
                },
              )
            : ClayIconButton.filled(
                tooltip: w.addEntry,
                icon: const Icon(LucideIcons.plus),
                onPressed: addTime,
              ),
        sideFooter: ClayGroup(
          children: [
            ClayListTile(
              leading: ClayAvatar(name: c.personName('maya'), size: 36),
              title: c.personName('maya'),
              subtitle: w.teamName,
              showChevron: false,
              semanticLabel: '${w.account}, ${c.personName('maya')}',
              onTap: () => go(Place.settings),
            ),
          ],
        ),
        body: switch (c.place) {
          Place.today => today(),
          Place.tasks => tasks(),
          Place.time => time(),
          Place.settings => settings(),
        },
      );
    },
  );
}

/// Stint's mark: a coral clay ball with a timer pressed in, its name beside
/// it on a desk.
class _StintMark extends StatelessWidget {
  const _StintMark({this.withName = false});
  final bool withName;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final colors = theme.colors;
    final ball = SizedBox.square(
      dimension: 36,
      child: ClaySurface(
        face: ClayFace.raised(colors, color: colors.accent, radius: 18),
        child: Center(
          child: Icon(LucideIcons.timer, size: 19, color: colors.onAccent),
        ),
      ),
    );
    if (!withName) {
      return Semantics(label: 'Stint', header: true, child: ball);
    }
    return Semantics(
      label: 'Stint',
      header: true,
      excludeSemantics: true,
      child: Row(
        spacing: ClaySpacing.medium,
        children: [
          ball,
          Flexible(
            child: Text(
              'Stint',
              style: theme.textTheme.title.copyWith(color: colors.ink),
            ),
          ),
        ],
      ),
    );
  }
}
