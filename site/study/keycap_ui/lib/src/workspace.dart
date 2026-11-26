part of '../stint_keycap.dart';

const _places = [
  LucideIcons.sun,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => KeycapToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  KeycapThemeData get theme => KeycapTheme.of(context);
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
      final choice = await showKeycapDialog<bool>(
        context: context,
        builder: (ctx) => KeycapDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            KeycapButton.text(
              onPressed: () => Navigator.pop(ctx),
              child: Text(w.cancel),
            ),
            // Discard throws the edits away: its legend is printed in the
            // danger ink, on a quiet key.
            KeycapButton(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(w.discard),
            ),
            KeycapButton.accent(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(w.save),
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
      showKeycapToast(notices.forDetail(context), w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || deciding) return;
    showKeycapCommandPalette(
      context: context,
      hintText: w.findCommand,
      emptyLabel: w.noMatches,
      commands: [
        for (final p in Place.values)
          RawCommand(label: w.place(p), onPressed: () => go(p)),
        RawCommand(label: w.addEntry, onPressed: addTime),
        if (c.draft != null)
          RawCommand(label: w.save, shortcut: '${modifier}S', onPressed: save),
      ],
    );
  }

  /// A square key with [glyph] for its legend, named by [label].
  Widget glyphKey(IconData glyph, String label, VoidCallback? action) =>
      KeycapTooltip(
        message: label,
        child: KeycapIconButton(
          icon: Icon(glyph),
          semanticLabel: label,
          onPressed: action,
        ),
      );

  // A phone has no keyboard to press K on: there the key's legend is the
  // search glyph, as the palette searches the app's commands.
  Widget get command => MediaQuery.sizeOf(context).width < 600
      ? glyphKey(LucideIcons.search, w.commands, palette)
      : glyphKey(LucideIcons.command, '${w.commands}  ${modifier}K', palette);

  Widget dataBody(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => KeycapStatusView(
      status: KeycapStatus.error,
      icon: LucideIcons.cloudOff,
      title: w.loadError,
      message: w.retryHelp,
      action: KeycapButton(
        icon: const Icon(LucideIcons.refreshCw),
        onPressed: c.refresh,
        child: Text(RawWidgetsLocalizations.of(context).retryButtonLabel),
      ),
    ),
    // Each coming row a shallow well its shape, cut straight into the case.
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KeycapSpacing.small,
        children: [
          for (var i = 0; i < 4; i++)
            const KeycapSkeleton(height: 56, radius: KeycapMetrics.wellRadius),
        ],
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return KeycapScreen(
          body: KeycapStatusView(
            status: KeycapStatus.success,
            icon: LucideIcons.doorOpen,
            title: w.signedOut,
            action: KeycapButton.accent(
              onPressed: () => c.signIn(true),
              child: Text(w.returnToStudio),
            ),
          ),
        );
      }
      return KeycapScaffold(
        destinations: [
          for (final p in Place.values)
            KeycapDestination(icon: _places[p.index], label: w.place(p)),
        ],
        selectedIndex: c.place.index,
        onDestinationSelected: (i) => go(Place.values[i]),
        showNavigation: c.draft == null,
        header: const _StintMark(),
        // Keycap's one main action is its accent key: a new time entry,
        // from any place. Over the rail a square key, in the side column a
        // key with words.
        action: KeycapTooltip(
          message: w.addEntry,
          child: KeycapIconButton(
            accent: true,
            icon: const Icon(LucideIcons.plus),
            semanticLabel: w.addEntry,
            onPressed: addTime,
          ),
        ),
        wideAction: KeycapButton.accent(
          icon: const Icon(LucideIcons.plus),
          onPressed: addTime,
          child: Text(w.addEntry),
        ),
        sideFooter: KeycapListGroup(
          children: [
            KeycapListTile(
              leading: ExcludeSemantics(
                child: KeycapAvatar(name: c.personName('maya'), size: 36),
              ),
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

/// Stint's mark: a cobalt accent keycap with a timer for its legend, the
/// name printed on the case beside it.
class _StintMark extends StatelessWidget {
  const _StintMark();

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final colors = theme.colors;
    final face = KeycapFace.of(colors.accent, colors);
    return Semantics(
      label: 'Stint',
      header: true,
      excludeSemantics: true,
      child: Row(
        spacing: KeycapSpacing.medium,
        children: [
          SizedBox.square(
            dimension: 40,
            child: KeycapCap(
              face: face,
              walls: KeycapMetrics.walls(40),
              child: Center(
                child: Icon(LucideIcons.timer, size: 18, color: face.legend),
              ),
            ),
          ),
          Flexible(child: Text('Stint', style: theme.textTheme.title)),
        ],
      ),
    );
  }
}
