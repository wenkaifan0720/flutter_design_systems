part of '../stint_gloss.dart';

const _places = [
  LucideIcons.sun,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.settings2,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => GlossToaster(child: pane));
  StintController get c => widget.model;
  StintWords get w => c.words;
  GlossThemeData get theme => GlossTheme.of(context);
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
      final choice = await showGlossDialog<bool>(
        context: context,
        builder: (ctx) => GlossDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            GlossDialogAction(
              label: w.cancel,
              onPressed: () => Navigator.pop(ctx),
            ),
            // Discard throws the edits away.
            GlossDialogAction(
              label: w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            GlossDialogAction(
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
    if (c.signedIn && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      showGlossToast(notices.forDetail(context), w.saved);
    }
  }

  void palette() {
    if (!c.signedIn || deciding) return;
    showGlossCommandPalette(
      context,
      hintText: w.findCommand,
      commands: [
        for (final p in Place.values)
          GlossCommand(
            label: w.place(p),
            icon: _places[p.index],
            onPressed: () => go(p),
          ),
        GlossCommand(
          label: w.addEntry,
          icon: LucideIcons.plus,
          onPressed: addTime,
        ),
        if (c.draft != null)
          GlossCommand(
            label: w.save,
            shortcut: '${modifier}S',
            onPressed: save,
          ),
      ],
    );
  }

  Widget get command => GlossIconButton(
    tooltip: '${w.commands}  ${modifier}K',
    icon: const Icon(LucideIcons.search, size: 18),
    onPressed: palette,
  );

  Widget dataBody(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => GlossStateView(
      state: GlossState.error,
      title: w.loadError,
      message: w.retryHelp,
      actions: [
        GlossButton(
          RawWidgetsLocalizations.of(context).retryButtonLabel,
          onPressed: c.refresh,
        ),
      ],
    ),
    DataState.loading => Semantics(
      label: w.loading,
      liveRegion: true,
      child: GlossWell(
        children: [
          for (var i = 0; i < 4; i++)
            const Padding(
              padding: EdgeInsets.all(16),
              child: GlossSkeleton(height: 25),
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
        return GlossScreen(
          body: GlossStateView(
            state: GlossState.empty,
            title: w.signedOut,
            actions: [
              GlossButton.filled(
                w.returnToStudio,
                onPressed: () => c.signIn(true),
              ),
            ],
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      return RawAdaptiveShell(
        mode: width < GlossMetrics.railBreakpoint
            ? RawNavigationMode.bar
            : width < GlossMetrics.sidebarBreakpoint
            ? RawNavigationMode.rail
            : RawNavigationMode.sidebar,
        showNavigation: c.draft == null,
        destinations: [
          for (final p in Place.values)
            RawNavigationDestination(label: w.place(p), icon: _places[p.index]),
        ],
        selectedIndex: c.place.index,
        onDestinationSelected: (i) => go(Place.values[i]),
        destinationBuilder: (context, item, details) {
          final side = details.mode == RawNavigationMode.sidebar;
          final rail = details.mode == RawNavigationMode.rail;
          final states = details.states;
          final selected = states.contains(WidgetState.selected);
          final colors = theme.colors;
          final ink = selected
              ? side && colors.brightness == Brightness.dark
                    ? colors.ink
                    : colors.jadeInk
              : colors.inkSecondary;
          final glyph = Icon(item.icon, size: 20, color: ink);
          // Words on the bar's chrome are letterpressed, as the package's
          // own bottom bar presses its labels.
          final label = Text(
            item.label,
            style: glossLetterpress(
              (side ? theme.textTheme.label : theme.textTheme.caption).copyWith(
                color: ink,
              ),
              colors,
            ),
            textAlign: side ? TextAlign.start : TextAlign.center,
          );
          final face = side
              ? GlossFace.pearl(colors, radius: 12)
              : GlossFace.well(colors, radius: 14);
          final clear = colors.page.withValues(alpha: 0);
          final active =
              selected ||
              states.contains(WidgetState.pressed) ||
              states.contains(WidgetState.hovered);
          final surface =
              (active
                      ? face
                      : GlossFace(
                          top: clear,
                          middle: clear,
                          bottom: clear,
                          foreground: ink,
                          radius: 14,
                        ))
                  .copyWith(
                    focus: glossFocusOf(
                      colors,
                      focused: states.contains(WidgetState.focused),
                    ),
                  );
          final tile = Padding(
            padding: const EdgeInsets.all(3),
            child: GlossSurface(
              face: surface,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: side ? 12 : 1,
                  vertical: side ? 10 : 6,
                ),
                child: side
                    ? Row(
                        spacing: 12,
                        children: [
                          glyph,
                          Expanded(child: label),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        spacing: 2,
                        children: [glyph, if (!rail) label],
                      ),
              ),
            ),
          );
          return rail ? GlossTooltip(message: item.label, child: tile) : tile;
        },
        navigationBuilder: (context, nav) {
          if (nav.mode == RawNavigationMode.bar) {
            final style = theme.textTheme.caption;
            // Each place's slot is its label plus breathing room. When every
            // slot fits a quarter of the bar the four sit in equal quarters;
            // only a label too long for one (200% text) widens its own.
            final slots = [
              for (final p in Place.values)
                (TextPainter.computeWidth(
                          text: TextSpan(text: w.place(p), style: style),
                          textDirection: Directionality.of(context),
                          textScaler: MediaQuery.textScalerOf(context),
                        ) +
                        18)
                    .ceil(),
            ];
            final quarter = (MediaQuery.sizeOf(context).width - 8) / 4;
            final even = slots.every((slot) => slot <= quarter);
            return GlossBar(
              edge: AxisDirection.up,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      for (final p in Place.values)
                        Expanded(
                          flex: even ? 1 : slots[p.index],
                          child: nav.destinations[p.index],
                        ),
                    ],
                  ),
                ),
              ),
            );
          }
          final side = nav.mode == RawNavigationMode.sidebar;
          return SizedBox(
            width: side ? 240 : 68,
            child: GlossBar(
              // GlossBar reads a side edge in reading order and mirrors it
              // itself: right is the rail's trailing edge, against the page,
              // in Arabic too.
              edge: AxisDirection.right,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: GlossTopBar.height,
                        // The sidebar's wordmark starts on the places' icon
                        // line, 3 px around each plate and 12 px inside it;
                        // the rail's mark sits on its centre line.
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: side ? 15 : 8,
                            end: 8,
                          ),
                          child: Align(
                            alignment: side
                                ? AlignmentDirectional.centerStart
                                : Alignment.center,
                            child: side
                                ? Text(
                                    'Stint',
                                    style: glossLetterpress(
                                      theme.textTheme.title,
                                      theme.colors,
                                    ),
                                  )
                                : Icon(
                                    LucideIcons.timer,
                                    color: theme.colors.jadeInk,
                                  ),
                          ),
                        ),
                      ),
                      const SizedBox(height: GlossSpacing.tight),
                      ...nav.destinations,
                    ],
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
      );
    },
  );

  Widget weekChart(DateTime week) {
    final days = List.generate(7, (i) => addDays(week, i));
    final minutes = c.dailyMinutes(week);
    final labels = [for (final day in days) w.weekdayShort(day)];
    // The week's gel is Today's (jadeInk, the preset's gel where it reads):
    // the chart's own set of gels is fixed green whatever the palette.
    final series = [
      GlossSeries(w.logged, [
        for (final m in minutes) m / 60,
      ], color: GlossTheme.of(context).colors.jadeInk),
    ];
    final values = [
      for (final (i, day) in days.indexed)
        '${w.weekday(day)} ${w.duration(minutes[i])}',
    ];
    // GlossBarChart sizes its axis type by the reader's text scale itself, so
    // the chart only grows taller to keep its plot as the labels grow. (A
    // FittedBox scaled the type a second time: at 2x the day names stood
    // larger than the page's own words.)
    final scale = MediaQuery.textScalerOf(context).scale(12) / 12;
    final height = 155.0 * scale.clamp(1.0, 1.6);
    return Semantics(
      label: w.logged,
      value: values.join(w.listSeparator),
      child: ExcludeSemantics(
        child: GlossBarChart(
          labels: labels,
          series: series,
          // Hours as the week reads them everywhere (4h, 30m), never a bare
          // or decimal figure.
          valueFormat: RawChartValueFormat.custom(
            (hours, _, _) => w.duration((hours * 60).round()),
          ),
          semanticLabel: w.logged,
          height: height,
        ),
      ),
    );
  }
}
