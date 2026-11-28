part of '../stint_ledger.dart';

const _marks = [
  LucideIcons.bookOpen,
  LucideIcons.listChecks,
  LucideIcons.clock3,
  LucideIcons.slidersHorizontal,
];

class _Book extends StatefulWidget {
  const _Book({
    super.key,
    required this.controller,
    required this.density,
    required this.onDensity,
  });
  final StintController controller;
  final LedgerDensity density;
  final ValueChanged<LedgerDensity> onDensity;
  @override
  State<_Book> createState() => _BookState();
}

class _BookState extends State<_Book> {
  StintController get c => widget.controller;
  StintWords get w => c.words;
  LedgerThemeData get ink => context.ledgerTheme;
  final navigator = GlobalKey<NavigatorState>();
  final search = TextEditingController();
  // Where the search's clear key stands: over the field's end, outside it.
  final searchEnd = LayerLink();
  bool asking = false;
  String get mod =>
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
      // LedgerDialog takes two acts, so it asks only whether to discard:
      // Save stays on the form.
      final discard = await LedgerDialog.show(
        context,
        title: w.dirty,
        body: w.discardMessage,
        type: LedgerDialogType.destructive,
        confirmLabel: w.discard,
        cancelLabel: w.keepEditing,
      );
      return mounted && discard == true;
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

  Future<void> open(Task t) async {
    if (c.draft?.task.id != t.id && await mayLeave() && mounted) c.openTask(t);
  }

  void save() {
    if (c.signedIn &&
        !asking &&
        c.place == Place.tasks &&
        c.draft?.dirty == true &&
        c.saveTask()) {
      releaseSaveFocus();
      LedgerToast.show(context, w.saved);
    }
  }

  Future<void> palette() async {
    if (!c.signedIn || asking) return;
    await showLedgerCommandPalette(
      context,
      hint: w.findCommand,
      commands: [
        for (final place in Place.values)
          LedgerCommand(label: w.place(place), onPressed: () => go(place)),
        LedgerCommand(label: w.addEntry, onPressed: addEntry),
        if (c.draft != null)
          LedgerCommand(label: w.save, shortcut: '${mod}S', onPressed: save),
      ],
    );
  }

  Widget action(IconData icon, String label, VoidCallback? press) =>
      LedgerTooltip(
        message: label,
        child: LedgerIconButton.outlined(
          icon,
          key: ValueKey(label),
          semanticLabel: '',
          onPressed: press,
        ),
      );
  Widget wordmark({bool rail = false, bool homeLink = false}) {
    final mark = ExcludeSemantics(
      child: rail
          ? const LedgerBrandMark(size: 30)
          : LedgerWordmark(
              'Stint',
              size: homeLink
                  ? LedgerWordmarkSize.large
                  : LedgerWordmarkSize.regular,
            ),
    );
    if (!homeLink) return Semantics(label: 'Stint', child: mark);
    return LedgerPressable(
      onTap: () => go(Place.today),
      role: LedgerPressRole.link,
      semanticLabel: 'Stint, ${w.today}',
      excludeChild: true,
      child: TapTargetPadding(child: mark),
    );
  }

  Widget sideNavigation(
    RawNavigationMode mode,
    List<LedgerNavItem> items,
    ValueChanged<int> choose,
  ) {
    final rail = mode == RawNavigationMode.rail;
    return SizedBox(
      width: rail ? LedgerSideBar.railWidth : LedgerSideBar.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: ink.sideBarFill,
              border: BorderDirectional(end: BorderSide(color: ink.border)),
            ),
            padding: EdgeInsetsDirectional.fromSTEB(
              rail ? 0 : 32,
              24,
              rail ? 0 : 18,
              0,
            ),
            alignment: rail
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: wordmark(rail: rail, homeLink: true),
          ),
          Expanded(
            child: LedgerSideBar(
              items: items,
              selectedIndex: c.place.index,
              onDestinationSelected: choose,
              extended: !rail,
            ),
          ),
        ],
      ),
    );
  }

  Widget bar(
    String title, {
    bool refresh = false,
    String? meta,
    String? italic,
  }) => Builder(
    builder: (ctx) {
      final narrow = MediaQuery.sizeOf(ctx).width < 600;
      final strip = LedgerBarSlotScope.of(ctx) == LedgerBarSlot.strip;
      final actions = <Widget>[
        if (strip || !narrow) ...[
          if (refresh) action(LucideIcons.rotateCw, w.refresh, c.refresh),
          // A phone has no keyboard to press K on: the key shows the search
          // glyph there, as the palette searches the app's commands.
          narrow
              ? action(LucideIcons.search, w.commands, palette)
              : action(LucideIcons.command, '${w.commands}  ${mod}K', palette),
        ],
      ];
      if (strip && narrow) {
        return Container(
          height: 60,
          decoration: BoxDecoration(
            color: ink.topBarFill,
            border: Border(bottom: BorderSide(color: ink.hairline)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          // The keys stand apart, as the masthead's do on a desk.
          child: Row(
            children: [
              wordmark(),
              const Spacer(),
              Row(
                mainAxisSize: MainAxisSize.min,
                spacing: LedgerChromeMetrics.deskToolsGap,
                children: actions,
              ),
            ],
          ),
        );
      }
      return LedgerTopBar(
        title: title,
        titleItalic: italic,
        meta: meta ?? w.teamName,
        actions: actions,
      );
    },
  );

  Widget load(Widget Function() content) => switch (c.state) {
    DataState.ready => content(),
    DataState.loading => Semantics(
      liveRegion: true,
      label: w.loading,
      child: const LedgerSkeleton(lines: 6),
    ),
    DataState.error => LedgerEmptyState(
      title: w.loadError,
      body: w.retryHelp,
      actionLabel: RawWidgetsLocalizations.of(context).retryButtonLabel,
      onActionPressed: c.refresh,
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return LedgerScreen(
          body: LedgerEmptyState(
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onActionPressed: () => c.signIn(true),
          ),
        );
      }
      final width = MediaQuery.sizeOf(ctx).width;
      final mode = width < LedgerAppShell.railFrom
          ? RawNavigationMode.bar
          : width < LedgerLayout.wide
          ? RawNavigationMode.rail
          : RawNavigationMode.sidebar;
      final items = [
        for (final p in Place.values)
          LedgerNavItem(_marks[p.index], w.place(p)),
      ];
      void choose(int i) => go(Place.values[i]);
      return RawAdaptiveShell(
        mode: mode,
        showNavigation: mode != RawNavigationMode.bar || c.draft == null,
        destinations: [
          for (final item in items)
            RawNavigationDestination(label: item.label, icon: item.icon),
        ],
        selectedIndex: c.place.index,
        onDestinationSelected: choose,
        destinationBuilder: (ctx, _, d) =>
            LedgerShellFace(index: d.index, states: d.states),
        navigationBuilder: (ctx, d) => LedgerShellDestinations(
          destinations: d.destinations,
          child: mode == RawNavigationMode.bar
              ? LedgerNavBar(
                  items: items,
                  selectedIndex: c.place.index,
                  onDestinationSelected: choose,
                )
              : sideNavigation(mode, items, choose),
        ),
        body: Semantics(
          container: true,
          explicitChildNodes: true,
          child: LedgerSideInset(
            inset: 0,
            beside: mode != RawNavigationMode.bar,
            child: switch (c.place) {
              Place.today => today(),
              Place.tasks => register(),
              Place.time => timesheet(),
              Place.settings => preferences(),
            },
          ),
        ),
      );
    },
  );

  Widget chart(DateTime week, {double height = 128}) {
    final minutes = c.dailyMinutes(week);
    final current = week == mondayOf(studyToday);
    final today = studyToday.weekday - 1;
    final peak = minutes.fold(60, (a, b) => a > b ? a : b);
    final keys = [
      for (var i = 0; i < minutes.length; i++) w.weekdayShort(addDays(week, i)),
    ];
    // The mono's tracking is for Latin capitals; Arabic letters keep their
    // joins.
    final meta = w.arabic ? ink.meta.copyWith(letterSpacing: 0) : ink.meta;
    final marked = meta.colored(ink.textPrimary);
    return Semantics(
      image: true,
      excludeSemantics: true,
      label: [
        w.logged,
        for (var i = 0; i < minutes.length; i++)
          '${w.weekday(addDays(week, i))} ${w.duration(minutes[i])}',
      ].join(', '),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The week runs Monday to Sunday from the reading start, the
          // plot mirrored whole in Arabic so its last (solid) bar is still
          // Sunday's; today's key is inked, not coloured as if chosen.
          Transform.flip(
            flipX: w.arabic,
            child: LedgerMonthBars(
              values: [for (final n in minutes) n.toDouble()],
              high: peak.toDouble(),
              tone: LedgerBarTone.ink,
              height: height,
              semanticLabel: w.logged,
            ),
          ),
          // Every day keeps its slot, its key centred under its bar: the
          // short name while it fits the slot, its first letter when not,
          // and the day's hours under it only while every figure fits.
          LayoutBuilder(
            builder: (ctx, box) {
              final slot = box.maxWidth / minutes.length;
              double measure(String text) => TextPainter.computeWidth(
                text: TextSpan(text: text, style: meta),
                textDirection: Directionality.of(ctx),
                textScaler: MediaQuery.textScalerOf(ctx),
              );
              // A key keeps air either side of it: a third of a short
              // name's width, so neighbours never run together.
              bool fits(Iterable<String> words) =>
                  words.every((word) => measure(word) <= slot - 12);
              final names = fits(keys)
                  ? keys
                  : [for (final k in keys) k.characters.first];
              final hours = [for (final n in minutes) w.duration(n)];
              final showHours = fits(hours);
              return Row(
                key: const ValueKey('week-chart-days'),
                children: [
                  for (var i = 0; i < minutes.length; i++)
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            names[i],
                            style: current && i == today ? marked.medium : meta,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                          ),
                          if (showHours)
                            Text(
                              hours[i],
                              style: current && i == today ? marked : meta,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                            ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Spread extends StatelessWidget {
  const _Spread({required this.main, required this.side});
  final Widget main, side;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, space) {
      if (space.maxWidth < 820) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 28,
          children: [main, side],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 40,
        children: [
          Expanded(flex: 3, child: main),
          Expanded(flex: 2, child: side),
        ],
      );
    },
  );
}
