part of '../stint_appliance.dart';

const _icons = [
  LucideIcons.sun,
  LucideIcons.clipboardList,
  LucideIcons.timer,
  LucideIcons.slidersHorizontal,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => ApplianceToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  ApplianceThemeData get theme => ApplianceTheme.of(context);
  final taskNavigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
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
      final save = await showApplianceDialog<bool>(
        context: context,
        // The keys go in the dialog's own actions, which lay them out as
        // the look does when they don't fit: a Wrap in the content broke
        // them over two rows of different heights on a phone.
        builder: (ctx) => ApplianceDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            ApplianceButton.text(w.cancel, onPressed: () => Navigator.pop(ctx)),
            // Discard throws the edits away: the danger colour.
            ApplianceButton(
              w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            ApplianceButton.filled(
              w.save,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      return mounted && save != null && (!save || c.saveTask());
    } finally {
      deciding = false;
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
      showApplianceToast(notices.forDetail(context), w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || deciding) return;
    showApplianceCommandPalette(
      context: context,
      hint: w.findCommand,
      commands: [
        for (final p in Place.values)
          RawCommand(label: w.place(p), onPressed: () => go(p)),
        RawCommand(label: w.addEntry, onPressed: addTime),
        if (c.draft != null)
          RawCommand(
            label: w.save,
            shortcut: '${modifier}S',
            onPressed: saveShortcut,
          ),
      ],
    );
  }

  Widget keyButton(IconData glyph, String label, VoidCallback? action) =>
      ApplianceTooltip(
        message: label,
        child: ApplianceIconButton(
          icon: Icon(glyph, size: 17),
          semanticLabel: label,
          onPressed: action,
        ),
      );
  // A phone has no keyboard to press K on: the key shows the look's search
  // glyph there, as the palette searches the app's commands.
  Widget get commandKey => MediaQuery.sizeOf(context).width < 600
      ? keyButton(LucideIcons.search, w.commands, palette)
      : keyButton(LucideIcons.command, '${w.commands}  ${modifier}K', palette);
  Widget dataBody(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => ApplianceErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: AppliancePanel(
        child: Column(
          spacing: 12,
          children: List.generate(
            5,
            (_) => const ApplianceSkeleton(height: 24),
          ),
        ),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      if (!c.signedIn) {
        return ApplianceScreen(
          body: ApplianceEmptyState(
            title: w.signedOut,
            action: ApplianceButton.filled(
              w.returnToStudio,
              onPressed: () => c.signIn(true),
            ),
          ),
        );
      }
      final page = switch (c.place) {
        Place.today => today(),
        Place.tasks => tasks(),
        Place.time => time(),
        Place.settings => settings(),
      };
      return _shell(page);
    },
  );

  // One shell owns focus and keeps the task navigator across widths. Its
  // moulded keys grow with the label, including on a phone at double text.
  Widget _shell(Widget page) => RawAdaptiveShell(
    showNavigation: c.draft == null,
    destinations: [
      for (final p in Place.values)
        RawNavigationDestination(label: w.place(p), icon: _icons[p.index]),
    ],
    selectedIndex: c.place.index,
    onDestinationSelected: (i) => go(Place.values[i]),
    destinationBuilder: (ctx, item, details) {
      final side = details.mode == RawNavigationMode.sidebar;
      final active = details.states.contains(WidgetState.selected);
      final down = active || details.states.contains(WidgetState.pressed);
      final colors = theme.colors;
      final face =
          (down ? ApplianceFace.keyDown(colors) : ApplianceFace.key(colors))
              .copyWith(
                focus: details.states.contains(WidgetState.focused)
                    ? colors.focus
                    : null,
              );
      final glyph = Icon(item.icon, size: 17, color: colors.print);
      final lamp = ApplianceLamp(lit: active, size: 6);
      final label = Text(
        item.label,
        textAlign: side ? TextAlign.start : TextAlign.center,
        style: (side ? theme.textTheme.body : theme.textTheme.secondary)
            .copyWith(color: colors.print),
      );
      return Padding(
        padding: const EdgeInsets.all(2),
        child: ApplianceSurface(
          face: face,
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: side ? 10 : 7,
              horizontal: side ? 12 : 3,
            ),
            child: side
                ? Row(
                    spacing: 9,
                    children: [
                      lamp,
                      glyph,
                      Expanded(child: label),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 3,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 5,
                        children: [glyph, lamp],
                      ),
                      if (details.mode == RawNavigationMode.bar) label,
                    ],
                  ),
          ),
        ),
      );
    },
    navigationBuilder: (ctx, nav) {
      if (nav.mode == RawNavigationMode.bar) {
        final scaler = MediaQuery.textScalerOf(ctx);
        int tabFlex(Place place) {
          if (scaler.scale(1) <= 1.4) return 1;
          final labelWidth = TextPainter.computeWidth(
            text: TextSpan(
              text: w.place(place),
              style: theme.textTheme.secondary,
            ),
            textDirection: Directionality.of(ctx),
            textScaler: scaler,
          );
          return (labelWidth + 14).ceil();
        }

        return ApplianceHousing(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                children: [
                  for (final place in Place.values)
                    Expanded(
                      flex: tabFlex(place),
                      child: nav.destinations[place.index],
                    ),
                ],
              ),
            ),
          ),
        );
      }
      final side = nav.mode == RawNavigationMode.sidebar;
      return SizedBox(
        width: side ? 240 : 72,
        child: ApplianceHousing(
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: ApplianceAppBar.height,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: side
                          ? Row(
                              spacing: 9,
                              children: [
                                const ApplianceLamp(lit: true),
                                Flexible(
                                  child: RawCapCenter(
                                    capHeightFactor: theme.capHeightFactor,
                                    child: Text(
                                      'Stint',
                                      style: theme.textTheme.heading.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          : const Icon(LucideIcons.timer),
                    ),
                  ),
                  if (side) ApplianceSectionHeader(w.teamName),
                  ...nav.destinations,
                ],
              ),
            ),
          ),
        ),
      );
    },
    body: Semantics(container: true, child: page),
  );
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: 5,
    children: [
      Text(label, style: ApplianceTheme.of(context).textTheme.legend),
      _Readout(value),
    ],
  );
}

class _Readout extends StatelessWidget {
  const _Readout(this.value);
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = ApplianceTheme.of(context);
    return ApplianceSurface(
      face: ApplianceFace.well(t.colors, fill: t.colors.display),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          value,
          textAlign: TextAlign.center,
          style: t.textTheme.display.copyWith(color: t.colors.onDisplay),
        ),
      ),
    );
  }
}
