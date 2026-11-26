part of '../stint_brutal.dart';

const _places = [
  LucideIcons.calendarDays,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _Studio extends StatefulWidget {
  const _Studio({
    super.key,
    required this.controller,
    required this.density,
    required this.onDensity,
  });
  final StintController controller;
  final BrutalDensity density;
  final ValueChanged<BrutalDensity> onDensity;
  @override
  State<_Studio> createState() => _StudioState();
}

class _StudioState extends State<_Studio> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => BrutalToaster(child: pane));
  StintController get c => widget.controller;
  StintWords get w => c.words;
  final navigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  bool prompting = false;
  String get modifier =>
      Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<bool?> confirm(
    String question,
    String accept,
    String decline, {
    String? message,
    bool destructive = false,
  }) => showBrutalDialog<bool>(
    context: context,
    builder: (ctx) => BrutalDialog(
      title: question,
      content: message == null ? null : Text(message),
      actions: [
        BrutalDialogAction(
          label: decline,
          onPressed: () => Navigator.pop(ctx, false),
        ),
        BrutalDialogAction(
          label: accept,
          isDefaultAction: true,
          isDestructiveAction: destructive,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    ),
  );

  Future<bool> mayLeave() async {
    if (c.draft?.dirty != true) return true;
    if (prompting) return false;
    prompting = true;
    try {
      // Three cells, the main one last: Discard throws the edits away, in
      // the danger colour.
      final choice = await showBrutalDialog<bool>(
        context: context,
        builder: (ctx) => BrutalDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            BrutalDialogAction(
              label: w.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            BrutalDialogAction(
              label: w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            BrutalDialogAction(
              label: w.save,
              isDefaultAction: true,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      return mounted && choice != null && (!choice || c.saveTask());
    } finally {
      prompting = false;
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
    if (c.signedIn &&
        !prompting &&
        c.place == Place.tasks &&
        c.draft?.dirty == true &&
        c.saveTask()) {
      releaseSaveFocus();
      showBrutalToast(notices.forDetail(context), w.saved);
    }
  }

  Future<void> palette() async {
    if (!c.signedIn || prompting) return;
    final selected = await showBrutalDialog<BrutalCommand>(
      context: context,
      builder: (ctx) => Semantics(
        namesRoute: true,
        label: w.commands,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 460),
          child: BrutalCommandPalette(
            autofocus: true,
            hintText: w.findCommand,
            emptyText: w.noCommands,
            onSelected: (command) => Navigator.pop(ctx, command),
            commands: [
              for (final p in Place.values)
                BrutalCommand(
                  label: w.place(p),
                  icon: _places[p.index],
                  onPressed: () => go(p),
                ),
              BrutalCommand(
                label: w.addEntry,
                icon: LucideIcons.timer,
                onPressed: addEntry,
              ),
              if (c.draft != null)
                BrutalCommand(
                  label: w.save,
                  shortcut: '${modifier}S',
                  onPressed: save,
                ),
            ],
          ),
        ),
      ),
    );
    if (mounted) selected?.onPressed?.call();
  }

  Widget bar(String title, {bool refresh = false}) => BrutalAppBar(
    title: title,
    actions: [
      if (refresh)
        BrutalAppBarAction(
          icon: const Icon(LucideIcons.refreshCw),
          semanticLabel: w.refresh,
          onPressed: c.refresh,
        ),
      // Commands in words on every page, as Today says it: a ⌘ glyph
      // elsewhere, and on a phone, named a key the reader may not have.
      // Where the words would push the page's own title off a phone (large
      // text), the cell takes the search glyph and keeps the name to speak.
      if (_roomForWords)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: BrutalButton.text(w.commands, onPressed: palette),
        )
      else
        BrutalAppBarAction(
          icon: const Icon(LucideIcons.search),
          semanticLabel: w.commands,
          onPressed: palette,
        ),
    ],
  );

  bool get _roomForWords =>
      MediaQuery.sizeOf(context).width /
          MediaQuery.textScalerOf(context).scale(1) >=
      240;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return BrutalScreen(
          body: BrutalStateView(
            state: BrutalState.success,
            title: w.signedOut,
            actions: [
              BrutalButton.filled(
                w.returnToStudio,
                onPressed: () => c.signIn(true),
              ),
            ],
          ),
        );
      }
      return BrutalScaffold(
        brand: LayoutBuilder(
          builder: (ctx, box) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Align(
              alignment: box.maxWidth < 100
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
              child: Semantics(
                header: true,
                label: 'Stint',
                excludeSemantics: true,
                child: Text(
                  box.maxWidth < 100 ? 'S' : 'Stint',
                  style: ctx.brutalTheme.textTheme.title,
                ),
              ),
            ),
          ),
        ),
        destinations: [
          for (final p in Place.values)
            BrutalDestination(icon: _places[p.index], label: w.place(p)),
        ],
        showNavigation: c.draft == null,
        selectedIndex: c.place.index,
        onDestinationSelected: (i) => go(Place.values[i]),
        body: switch (c.place) {
          Place.today => today(),
          Place.tasks => tasks(),
          Place.time => time(),
          Place.settings => settings(),
        },
      );
    },
  );

  Widget loaded(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.loading => Semantics(
      liveRegion: true,
      label: w.loading,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          BrutalSkeleton(height: 54),
          BrutalSkeleton(height: 64),
          BrutalSkeleton(height: 64),
          BrutalSkeleton(height: 64),
        ],
      ),
    ),
    DataState.error => BrutalStateView(
      state: BrutalState.error,
      title: w.loadError,
      message: w.retryHelp,
      actions: [
        BrutalButton.filled(
          RawWidgetsLocalizations.of(context).retryButtonLabel,
          onPressed: c.refresh,
        ),
      ],
    ),
  };

  Widget weekChart(DateTime week) => BrutalBarChart(
    labels: [for (var i = 0; i < 7; i++) w.weekdayShort(addDays(week, i))],
    series: [
      BrutalSeries(w.logged, [
        for (final n in c.dailyMinutes(week)) n / 60,
      ], color: context.brutalTheme.colors.ink),
    ],
    // Hours as the week reads them everywhere (4h, 30m), never a bare or
    // decimal figure.
    valueFormat: RawChartValueFormat.custom(
      (hours, _, _) => w.duration((hours * 60).round()),
    ),
    semanticLabel: w.logged,
    // Its axis counts grow with the reader's text: so does the chart, or
    // at 200% they stand on one another.
    height:
        132 + 56 * (MediaQuery.textScalerOf(context).scale(1) - 1).clamp(0, 1),
  );
}

class _Columns extends StatelessWidget {
  const _Columns({
    required this.first,
    required this.second,
    this.secondFirstOnPhone = false,
  });
  final bool secondFirstOnPhone;
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, box) {
      if (box.maxWidth >=
          780 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.4)) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 32,
          children: [
            Expanded(child: first),
            Expanded(child: second),
          ],
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 24,
        children: secondFirstOnPhone ? [second, first] : [first, second],
      );
    },
  );
}
