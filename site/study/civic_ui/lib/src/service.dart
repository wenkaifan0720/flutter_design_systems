part of '../stint_civic.dart';

class _Service extends StatefulWidget {
  const _Service({super.key, required this.controller});
  final StintController controller;
  @override
  State<_Service> createState() => _ServiceState();
}

class _ServiceState extends State<_Service> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices((pane) => CivicToaster(child: pane));
  StintController get c => widget.controller;
  StintWords get w => c.words;
  final records = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  bool confirming = false;
  String get modifier =>
      Theme.of(context).platform == TargetPlatform.macOS ? '⌘' : 'Ctrl+';
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<bool> canLeave() async {
    if (c.draft?.dirty != true) return true;
    if (confirming) return false;
    confirming = true;
    try {
      final result = await showCivicDialog<bool>(
        context: context,
        builder: (dialog) => CivicDialog(
          title: w.dirty,
          content: Text(w.leaveMessage),
          actions: [
            CivicButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: Text(w.save),
            ),
            // Discard throws the edits away: the error colour.
            CivicButton.secondary(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialog, false),
              child: Text(w.discard),
            ),
            CivicLink(
              onPressed: () => Navigator.pop(dialog),
              child: Text(w.cancel),
            ),
          ],
        ),
      );
      return mounted && result != null && (!result || c.saveTask());
    } finally {
      confirming = false;
    }
  }

  Future<void> enter(Place p) async {
    if (!await canLeave() || !mounted) return;
    if (c.draft != null) {
      c.openTask(null);
      await WidgetsBinding.instance.endOfFrame;
    }
    if (mounted) c.navigate(p);
  }

  Future<void> record(Task t) async {
    if (c.draft?.task.id != t.id && await canLeave() && mounted) c.openTask(t);
  }

  void save() {
    if (c.signedIn && !confirming && c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      CivicToast.show(notices.forDetail(context), w.saved);
    }
  }

  Future<void> commands() async {
    if (!c.signedIn || confirming) return;
    await showCivicCommandPalette(
      context: context,
      labelText: w.findCommand,
      commands: [
        for (final p in Place.values)
          RawCommand(label: w.place(p), onPressed: () => enter(p)),
        RawCommand(label: w.addEntry, onPressed: newEntry),
        if (c.draft != null)
          RawCommand(label: w.save, shortcut: '${modifier}S', onPressed: save),
      ],
    );
  }

  Widget icon(IconData glyph, String name, VoidCallback? press) => CivicTooltip(
    message: name,
    excludeFromSemantics: true,
    child: CivicIconButton(
      key: ValueKey(name),
      icon: glyph,
      semanticLabel: name,
      onPressed: press,
    ),
  );
  Widget load(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => CivicErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
    DataState.loading => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CivicLoadingState(label: w.loading),
        ExcludeSemantics(
          child: CivicListGroup(
            children: [
              for (final fraction in [.72, .55, .65])
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: FractionallySizedBox(
                      widthFactor: fraction,
                      child: ColoredBox(
                        color: context.civicTheme.rule,
                        child: const SizedBox(
                          height: 14,
                          width: double.infinity,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    ),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      final places = [
        LucideIcons.layoutGrid,
        LucideIcons.listChecks,
        LucideIcons.clock3,
        LucideIcons.settings,
      ];
      return CivicScaffold(
        skipLinkLabel: w.skipToContent,
        topBar: CivicTopBar(
          title: 'Stint',
          emblem: const Icon(LucideIcons.clipboardList),
          actions: [
            // Commands in words on every page, as Today says it (a ⌘ glyph
            // elsewhere, and on a phone, named a key the reader may not
            // have). The bar lets its actions overhang its end by 12 so an
            // icon's glyph, centred in its target, stands on the frame's
            // line. Words have no such margin: end them on the line.
            if (c.signedIn)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  end: CivicSpacing.s12,
                ),
                child: CivicLink(
                  onPressed: commands,
                  style: CivicStyle(
                    foreground: WidgetStatePropertyAll(
                      CivicTopBar.onBandOf(ctx.civicTheme),
                    ),
                  ),
                  child: Text(w.commands),
                ),
              ),
          ],
        ),
        body: !c.signedIn
            ? CivicPageBody(
                title: w.signedOut,
                children: [
                  CivicButton.start(
                    onPressed: () => c.signIn(true),
                    child: Text(w.returnToStudio),
                  ),
                ],
              )
            : Padding(
                padding: EdgeInsetsDirectional.only(
                  start: CivicLayout.isApp(MediaQuery.sizeOf(ctx).width)
                      ? 0
                      : CivicLayout.navigationOffset(
                          MediaQuery.sizeOf(ctx).width,
                        ),
                ),
                child: CivicShellFrame(
                  destinations: [
                    for (final p in Place.values)
                      CivicNavItem(places[p.index], w.place(p)),
                  ],
                  selectedIndex: c.place.index,
                  onDestinationSelected: (i) => enter(Place.values[i]),
                  showPlaces:
                      c.draft == null ||
                      MediaQuery.sizeOf(ctx).width >= CivicLayout.medium,
                  child: Semantics(
                    container: true,
                    explicitChildNodes: true,
                    child: switch (c.place) {
                      Place.today => overview(),
                      Place.tasks => taskService(),
                      Place.time => timePage(),
                      Place.settings => settingsPage(),
                    },
                  ),
                ),
              ),
      );
    },
  );

  Widget chart(DateTime week) {
    final minutes = c.dailyMinutes(week);
    final max = minutes.fold(60, (a, b) => a > b ? a : b);
    final theme = context.civicTheme;
    final names = [
      for (var i = 0; i < 7; i++)
        '${w.weekday(addDays(week, i))} ${w.duration(minutes[i])}',
    ];
    // Place the seven columns in reading order and give the complete values as a single graphic.
    return Semantics(
      image: true,
      label: '${w.logged}. ${names.join(', ')}',
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (ctx, space) {
          final scaler = MediaQuery.textScalerOf(ctx);
          final style = ctx.civicText.bodySmall;
          // Readings stand over columns a seventh wide, all in one form:
          // each day in full where every one fits its column, else all as
          // h:mm, under a caption naming the hours. Where even
          // those don't fit, or at a large text size on a narrow screen,
          // the days go in rows.
          final column = space.maxWidth / 7 - 6;
          final readings = WeekReadings.fit(
            ctx,
            words: w,
            minutes: minutes,
            style: style,
            slot: column,
          );
          final large =
              scaler.scale(1) > 1.5 && space.maxWidth < 500 ||
              readings.labels.any((s) => textWidth(ctx, s, style) > column);
          if (large) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < 7; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 76,
                          child: Text(
                            w.weekdayShort(addDays(week, i)),
                            style: ctx.civicText.bodySmall,
                          ),
                        ),
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: FractionallySizedBox(
                              widthFactor: minutes[i] / max,
                              child: ColoredBox(
                                color: theme.action,
                                child: const SizedBox(
                                  height: 8,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          flex: 2,
                          child: Align(
                            alignment: AlignmentDirectional.centerEnd,
                            child: Text(
                              w.duration(minutes[i]),
                              textAlign: TextAlign.end,
                              style: ctx.civicText.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            );
          }
          final bars = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var i = 0; i < 7; i++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          readings.labels[i],
                          textAlign: TextAlign.center,
                          style: style,
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            width: 32,
                            height: minutes[i] == 0 ? 1 : minutes[i] / max * 60,
                            color: minutes[i] == 0 ? theme.rule : theme.action,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          w.weekdayShort(addDays(week, i)),
                          textAlign: TextAlign.center,
                          style: ctx.civicText.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
          if (!readings.compact) return bars;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              Text(
                w.logged,
                style: style.copyWith(color: context.civicTheme.textSecondary),
              ),
              bars,
            ],
          );
        },
      ),
    );
  }
}
