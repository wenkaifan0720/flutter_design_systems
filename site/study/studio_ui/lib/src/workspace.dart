part of '../stint_studio.dart';

const _channels = [
  LucideIcons.sun,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.slidersHorizontal,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => StudioToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  StudioThemeData get rack => StudioTheme.of(context);
  final search = TextEditingController(),
      taskNavigator = GlobalKey<NavigatorState>();
  bool asking = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  /// A short form: a bottom sheet on a phone; from 600 px a dialog on the
  /// rack, as the calendar and Sign out are, not a phone sheet on its foot.
  Future<T?> formSheet<T>({
    required String title,
    required WidgetBuilder builder,
  }) => MediaQuery.sizeOf(context).width < 600
      ? showStudioBottomSheet<T>(
          context: context,
          title: title,
          builder: (sheet) => SingleChildScrollView(child: builder(sheet)),
        )
      : showStudioDialog<T>(
          context: context,
          builder: (dialog) => SingleChildScrollView(
            child: StudioDialog(
              title: title,
              content: builder(dialog),
              // The phone sheet's way out, as the task chooser's Cancel.
              actions: [
                StudioButton(w.cancel, onPressed: () => Navigator.pop(dialog)),
              ],
            ),
          ),
        );

  String shortcut(LogicalKeyboardKey key) {
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
      final result = await showStudioDialog<bool>(
        context: context,
        isAlert: true,
        builder: (ctx) => StudioDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            StudioButton.text(w.cancel, onPressed: () => Navigator.pop(ctx)),
            // Discard throws the edits away: lit in the danger colour.
            StudioButton(
              w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            StudioButton.lit(w.save, onPressed: () => Navigator.pop(ctx, true)),
          ],
        ),
      );
      return mounted && result != null && (!result || c.saveTask());
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
      showStudioToast(notices.forDetail(context), w.saved);
    }
  }

  Future<void> palette() async {
    if (!c.signedIn || asking) return;
    final cmd = await showStudioDialog<StudioCommand>(
      context: context,
      builder: (ctx) => StudioDialog(
        title: w.commands,
        content: StudioCommandPalette(
          hint: w.findCommand,
          emptyText: w.noCommands,
          autofocus: true,
          commands: [
            for (final p in Place.values)
              StudioCommand(
                label: w.place(p),
                icon: Icon(_channels[p.index]),
                onPressed: () => go(p),
              ),
            StudioCommand(
              label: w.addEntry,
              icon: const Icon(LucideIcons.plus),
              onPressed: addTime,
            ),
            if (c.draft != null)
              StudioCommand(
                label: w.save,
                shortcut: shortcut(LogicalKeyboardKey.keyS),
                icon: const Icon(LucideIcons.check),
                onPressed: save,
              ),
          ],
          onSelected: (c) => Navigator.pop(ctx, c),
        ),
      ),
    );
    if (mounted) cmd?.onPressed?.call();
  }

  Widget get command => StudioIconButton(
    icon: const Icon(LucideIcons.search),
    tooltip: '${w.commands}${w.dot}${shortcut(LogicalKeyboardKey.keyK)}',
    onPressed: palette,
  );
  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => StudioErrorState(
      title: w.loadError,
      message: w.retryHelp,
      retryLabel: RawWidgetsLocalizations.of(context).retryButtonLabel,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      container: true,
      label: w.loading,
      liveRegion: true,
      child: const StudioDisplay(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [StudioSkeleton(), StudioSkeleton(), StudioSkeleton()],
        ),
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return StudioScreen(
          body: StudioStatusView(
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onAction: () => c.signIn(true),
          ),
        );
      }
      final body = switch (c.place) {
        Place.today => today(),
        Place.tasks => tasks(),
        Place.time => time(),
        Place.settings => settings(),
      };
      if (MediaQuery.sizeOf(ctx).width < StudioMetrics.tablet &&
          MediaQuery.textScalerOf(ctx).scale(1) > 1.5) {
        return RawAdaptiveShell(
          mode: RawNavigationMode.bar,
          selectedIndex: c.place.index,
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _channels[p.index],
              ),
          ],
          onDestinationSelected: (i) => go(Place.values[i]),
          destinationBuilder: (ctx, d, s) {
            final colors = rack.colors,
                selected = s.states.contains(WidgetState.selected);
            final ink = selected ? colors.litLegend : colors.onKey;
            final face = colors.keyFace
                .copyWith(
                  travel: selected || s.states.contains(WidgetState.pressed)
                      ? 1
                      : 0,
                  focus: s.states.contains(WidgetState.focused)
                      ? colors.focusRing
                      : null,
                )
                .backlitIf(colors, selected);
            return AnimatedStudioSurface(
              key: ValueKey(Place.values[s.index]),
              face: face,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3,
                      children: [
                        Icon(d.icon, size: 17, color: ink),
                        StudioLamp(on: selected, size: 5),
                      ],
                    ),
                    Text(
                      d.label,
                      style: rack.textTheme.caption.copyWith(color: ink),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
          navigationBuilder: (ctx, n) => StudioPanel(
            padding: const EdgeInsets.all(4),
            child: SafeArea(
              top: false,
              child: Row(
                spacing: 2,
                children: [
                  for (final p in Place.values)
                    Expanded(
                      flex:
                          (TextPainter.computeWidth(
                                    text: TextSpan(
                                      text: w.place(p),
                                      style: rack.textTheme.caption,
                                    ),
                                    textDirection: Directionality.of(ctx),
                                    textScaler: MediaQuery.textScalerOf(ctx),
                                  ) +
                                  12)
                              .ceil(),
                      child: n.destinations[p.index],
                    ),
                ],
              ),
            ),
          ),
          body: body,
        );
      }
      return StudioAppShell(
        brand: 'Stint',
        tabs: [
          for (final p in Place.values)
            StudioTab(_channels[p.index], w.place(p), ValueKey(p)),
        ],
        selectedIndex: c.place.index,
        onSelected: (i) => go(Place.values[i]),
        showPlaces: c.draft == null,
        child: body,
      );
    },
  );

  /// A rack station under its faceplate bar. [maxWidth] caps the station,
  /// margins included; Today raises it so its grid reaches the bar's command
  /// key at 1440 instead of stopping short of it.
  // Every station shares Today's measure, so at 1440 the rack ends at the
  // command key's edge on each page (Time and Settings stopped 53 px short).
  Widget station(String title, Widget body, {double maxWidth = 1200}) =>
      StudioScreen(
        topBar: StudioAppBar(
          title: title,
          automaticallyImplyLeading: false,
          actions: [command],
        ),
        fullBleed: true,
        body: Align(
          alignment: AlignmentDirectional.topStart,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: StudioSpacing.pageMargin(
                  MediaQuery.sizeOf(context).width,
                ),
                vertical: StudioSpacing.large,
              ),
              child: body,
            ),
          ),
        ),
      );
}

class _Reading extends StatelessWidget {
  const _Reading({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) {
    final t = StudioTheme.of(context);
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 10,
      runSpacing: 4,
      children: [
        Text(
          label,
          style: t.textTheme.label.copyWith(color: t.colors.onDisplay),
        ),
        StudioReadout(value),
      ],
    );
  }
}

/// The stock section legend keeps a single line. Long dates can use two.
class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, bounds) {
      final base = StudioTheme.of(ctx).textTheme.legend;
      final capitals = StudioLegend.hasCapitals(text);
      final style = capitals
          ? base
          : base.copyWith(
              letterSpacing: 0,
              fontSize: (base.fontSize ?? 12) + 1,
            );
      final label = capitals ? text.toUpperCase() : text;
      final width = TextPainter.computeWidth(
        text: TextSpan(text: label, style: style),
        textDirection: Directionality.of(ctx),
        textScaler: MediaQuery.textScalerOf(ctx),
      );
      if (width + StudioSpacing.medium <= bounds.maxWidth) {
        return StudioSectionHeader(text);
      }
      return Semantics(
        header: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: StudioSpacing.small),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Text(label, style: style, semanticsLabel: text),
              const StudioGroove(),
            ],
          ),
        ),
      );
    },
  );
}

class _ConsoleGroup extends StatelessWidget {
  const _ConsoleGroup({
    super.key,
    required this.header,
    required this.children,
    this.dividerIndent = StudioSpacing.regular,
  });
  final String header;
  final List<Widget> children;
  final double dividerIndent;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _ConsoleHeader(header),
      StudioListGroup(dividerIndent: dividerIndent, children: children),
    ],
  );
}
