part of '../stint_material_expressive.dart';

const _symbols = [
  ExpressiveSymbols.clearDay,
  ExpressiveSymbols.checklist,
  ExpressiveSymbols.schedule,
  ExpressiveSymbols.settings,
];

class _WorkspaceState extends State<_Workspace> {
  // The list's and the open task's notices, each in its pane side by side.
  late final notices = PaneNotices(
    (pane) => ExpressiveSnackBarHost(child: pane),
  );
  StintController get c => widget.model;
  StintWords get w => c.words;
  ExpressiveThemeData get theme => context.expressiveTheme;
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
      final result = await showExpressiveDialog<bool>(
        context: context,
        builder: (_) => ExpressiveDialog(
          icon: ExpressiveSymbols.edit,
          title: w.dirty,
          text: w.leaveMessage,
          actions: [
            // Cancel closes with nothing: the task stays open. The kit has no
            // destructive action; Discard is a plain one.
            ExpressiveDialogAction(w.cancel),
            ExpressiveDialogAction(w.discard, value: false),
            ExpressiveDialogAction(w.save, value: true, filled: true),
          ],
        ),
      );
      return mounted && result != null && (!result || c.saveTask());
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
        c.place == Place.tasks &&
        c.draft?.dirty == true &&
        c.saveTask()) {
      releaseSaveFocus();
      showExpressiveSnackBar(notices.forDetail(context), w.saved);
    }
  }

  Widget icon(IconData glyph, String label, VoidCallback action) =>
      ExpressiveTooltip.plain(
        message: label,
        child: ExpressiveIconButton(
          glyph,
          semanticLabel: label,
          onPressed: action,
        ),
      );
  // A phone has no keyboard to press K on: the key shows the look's search
  // glyph there, as the palette searches the app's commands.
  Widget get commandKey => MediaQuery.sizeOf(context).width < 600
      ? icon(ExpressiveSymbols.search, w.commands, palette)
      : icon(
          ExpressiveSymbols.keyboard,
          '${w.commands}  ${modifier}K',
          palette,
        );

  void palette({List<Task>? timerTasks}) {
    if (!c.signedIn || deciding) return;
    final picking = timerTasks != null;
    final title = picking
        ? (c.data.timer == null ? w.startTimer : w.switchTask)
        : w.commands;
    final hint = picking ? w.search : w.findCommand;
    showRawCommandPalette(
      context: context,
      surfaceBuilder: (ctx, child) {
        final picker = picking
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 10,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Semantics(
                              header: true,
                              child: Text(
                                title,
                                style: theme.type.titleLargeEmphasized,
                              ),
                            ),
                            Text(
                              w.totalTasks(timerTasks.length),
                              style: theme.type.labelMedium.copyWith(
                                color: theme.colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      icon(
                        ExpressiveSymbols.close,
                        w.cancel,
                        () => Navigator.of(ctx).pop(),
                      ),
                    ],
                  ),
                  Flexible(child: child),
                ],
              )
            : child;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: ExpressiveCard.elevated(
              padding: const EdgeInsets.all(16),
              child: picker,
            ),
          ),
        );
      },
      palette: (run) => RawCommandPalette(
        semanticLabel: title,
        maxHeight: picking
            ? 7.5 * 56 +
                  14 +
                  MediaQuery.textScalerOf(context)
                          .scale(theme.type.labelLarge.fontSize!) *
                      (theme.type.labelLarge.height ?? 1.43)
            : 360,
        onSelected: run,
        commands: picking
            ? [
                for (final task in timerTasks)
                  RawCommand(
                    label: w.text(task.title),
                    group: c.projectName(task.project),
                    keywords: [c.projectName(task.project)],
                    data: ExpressiveSymbols.description,
                    onPressed: () => c.track(task.id),
                  ),
              ]
            : [
                for (final p in Place.values)
                  RawCommand(
                    label: w.place(p),
                    data: _symbols[p.index],
                    onPressed: () => go(p),
                  ),
                RawCommand(
                  label: w.addEntry,
                  data: ExpressiveSymbols.add,
                  onPressed: addTime,
                ),
                if (c.draft != null)
                  RawCommand(
                    label: w.save,
                    data: ExpressiveSymbols.check,
                    shortcut: '${modifier}S',
                    onPressed: save,
                  ),
              ],
        groupBuilder: (_, group) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
          child: Text(
            group,
            style: theme.type.labelLarge.copyWith(color: theme.colors.primary),
          ),
        ),
        fieldBuilder: (ctx, field) => ExpressiveTextField(
          rounded: true,
          labelText: hint,
          leading: const ExpressiveIcon(ExpressiveSymbols.search),
          controller: field.controller,
          focusNode: field.focusNode,
          onEditingComplete: field.submit,
        ),
        emptyBuilder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(picking ? w.noMatches : w.noCommands),
        ),
        itemBuilder: (ctx, command, states) => ExpressiveListTile(
          title: Text(command.label),
          leading: ExpressiveIcon(command.data! as IconData),
          trailing: command.shortcut == null ? null : Text(command.shortcut!),
          style: picking && states.contains(WidgetState.focused)
              ? const ExpressiveComponentThemeData(
                  shape: WidgetStatePropertyAll(StadiumBorder()),
                )
              : null,
          tileColor: states.contains(WidgetState.focused)
              ? theme.colors.secondaryContainer
              : null,
        ),
      ),
    );
  }

  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => ExpressiveErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      liveRegion: true,
      label: w.loading,
      child: Column(
        spacing: 8,
        children: [
          for (var i = 0; i < 5; i++) const ExpressiveSkeleton(height: 56),
        ],
      ),
    ),
  };

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      if (!c.signedIn) {
        return ExpressiveScaffold(
          title: 'Stint',
          body: ExpressiveEmptyState(
            icon: ExpressiveSymbols.logout,
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onAction: () => c.signIn(true),
          ),
        );
      }
      return ColoredBox(
        color: theme.colors.surface,
        child: RawAdaptiveShell(
          selectedIndex: c.place.index,
          onDestinationSelected: (i) => go(Place.values[i]),
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _symbols[p.index],
              ),
          ],
          destinationBuilder: (ctx, item, d) {
            final side = d.mode == RawNavigationMode.sidebar,
                selected = d.states.contains(WidgetState.selected);
            final col = theme.colors;
            final ink = selected
                ? col.onSecondaryContainer
                : col.onSurfaceVariant;
            final shape = StadiumBorder(
              side: d.states.contains(WidgetState.focused)
                  ? BorderSide(color: col.secondary, width: 3)
                  : BorderSide.none,
            );
            final glyph = ExpressiveIcon(
              item.icon,
              selected: selected,
              color: ink,
              size: 24,
            );
            final indicator = ShapeDecoration(
              shape: shape,
              color: theme.states.composite(
                selected ? col.secondaryContainer : col.surfaceContainerLow,
                ink,
                d.states,
              ),
            );
            if (side) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
                padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 10, 14),
                decoration: indicator,
                child: Row(
                  spacing: 12,
                  children: [
                    glyph,
                    Expanded(
                      child: ExpressiveText(
                        item.label,
                        role: ExpressiveTextRole.label,
                        size: ExpressiveTextSize.large,
                        emphasized: selected,
                        color: ink,
                      ),
                    ),
                  ],
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 3,
                children: [
                  Container(
                    width: 56,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: indicator,
                    child: glyph,
                  ),
                  if (d.mode == RawNavigationMode.bar)
                    ExpressiveText(
                      item.label,
                      role: ExpressiveTextRole.label,
                      emphasized: selected,
                      color: ink,
                      textAlign: TextAlign.center,
                    ),
                ],
              ),
            );
          },
          navigationBuilder: (ctx, nav) {
            final side = nav.mode == RawNavigationMode.sidebar;
            if (nav.mode == RawNavigationMode.bar) {
              return ColoredBox(
                color: theme.colors.surfaceContainerLow,
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      for (final p in Place.values)
                        Expanded(
                          flex: MediaQuery.textScalerOf(ctx).scale(1) > 1.4
                              ? (TextPainter.computeWidth(
                                          text: TextSpan(
                                            text: w.place(p),
                                            style: const TextStyle(
                                              fontSize: 14,
                                            ),
                                          ),
                                          textDirection: Directionality.of(ctx),
                                          textScaler: MediaQuery.textScalerOf(
                                            ctx,
                                          ),
                                        ) +
                                        18)
                                    .ceil()
                              : 1,
                          child: nav.destinations[p.index],
                        ),
                    ],
                  ),
                ),
              );
            }
            return Container(
              width: side ? 228 : 80,
              color: theme.colors.surfaceContainerLow,
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        side ? 22 : 10,
                        24,
                        10,
                        22,
                      ),
                      child: Row(
                        mainAxisAlignment: side
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          _Mark(
                            size: 36,
                            color: theme.colors.primary,
                            child: ExpressiveIcon(
                              ExpressiveSymbols.schedule,
                              color: theme.colors.onPrimary,
                              size: 22,
                            ),
                          ),
                          if (side)
                            const Flexible(
                              child: ExpressiveText(
                                'Stint',
                                role: ExpressiveTextRole.title,
                                size: ExpressiveTextSize.large,
                              ),
                            ),
                        ],
                      ),
                    ),
                    ...nav.destinations,
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

  Widget chart(DateTime week, {double height = 148}) {
    final minutes = c.dailyMinutes(week);
    final direction = Directionality.of(context);
    final rtl = direction == TextDirection.rtl;
    final logicalDays = List.generate(7, (i) => i);
    // The chart paints its bars from the physical left. Keep the day captions
    // and the highlighted Friday in the same physical order as the bars.
    final physicalDays = rtl ? logicalDays.reversed : logicalDays;
    return LayoutBuilder(
      builder: (ctx, box) {
        final widthPerDay = (box.maxWidth - 6 * ExpressiveSpacing.s8) / 7;
        final labels = [
          for (final i in logicalDays) w.weekdayShort(addDays(week, i)),
        ];
        final compact =
            !w.arabic &&
            labels.any(
              (label) =>
                  TextPainter.computeWidth(
                    text: TextSpan(
                      text: label,
                      style: theme.type.labelSmallEmphasized,
                    ),
                    textDirection: direction,
                    textScaler: MediaQuery.textScalerOf(ctx),
                  ) >
                  widthPerDay,
            );
        final todayIndex = rtl
            ? 7 - studyToday.weekday
            : studyToday.weekday - 1;
        // The words' ink is the chart's place's: the card it stands on may
        // set its own (see Time's week card).
        final ink = ctx.expressiveTheme.colors;
        // One form for the week: each day in full where every one fits its
        // column on one line, else all as h:mm, under a caption
        // naming the hours.
        final readings = WeekReadings.fit(
          ctx,
          words: w,
          minutes: minutes,
          style: theme.type.labelSmallEmphasized,
          slot: widthPerDay,
        );
        return Semantics(
          image: true,
          excludeSemantics: true,
          textDirection: direction,
          label: [
            w.logged,
            for (final i in logicalDays)
              '${w.weekdayNames[i]} ${w.duration(minutes[i])}',
          ].join(', '),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 5,
              children: [
                if (readings.compact)
                  Text(
                    w.logged,
                    textDirection: direction,
                    style: theme.type.labelSmall.copyWith(
                      color: ink.onSurfaceVariant,
                    ),
                  ),
                Row(
                  children: [
                    for (final day in physicalDays)
                      Expanded(
                        child: Text(
                          readings.labels[day],
                          maxLines: 1,
                          softWrap: false,
                          textDirection: direction,
                          textAlign: TextAlign.center,
                          style: theme.type.labelSmallEmphasized.copyWith(
                            color: ink.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
                // No tooltip: each day's reading stands over its bar, and
                // the chart's own would write it as a decimal (2.8).
                ExpressiveBarChart(
                  aspectRatio: (box.maxWidth / height).clamp(1.4, 10.0),
                  highlight: week == mondayOf(studyToday) ? todayIndex : null,
                  points: [
                    for (final i in physicalDays)
                      ExpressiveChartPoint(
                        compact ? w.weekdayLetters[i] : labels[i],
                        minutes[i] / 60,
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Columns extends StatelessWidget {
  const _Columns({
    required this.first,
    required this.second,
    this.breakpoint,
    this.matchHeight = false,
  });
  final double? breakpoint;
  final bool matchHeight;
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, box) =>
        box.maxWidth >=
            (breakpoint ??
                670 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.45))
        ? matchHeight
              ? Table(
                  defaultVerticalAlignment:
                      TableCellVerticalAlignment.intrinsicHeight,
                  columnWidths: const {
                    0: FlexColumnWidth(1),
                    1: FixedColumnWidth(16),
                    2: FlexColumnWidth(1),
                  },
                  children: [
                    TableRow(children: [first, const SizedBox(), second]),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Expanded(child: first),
                    Expanded(child: second),
                  ],
                )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [first, second],
          ),
  );
}

class _Mark extends StatelessWidget {
  const _Mark({
    super.key,
    required this.size,
    required this.color,
    required this.child,
  });
  final double size;
  final Color color;
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: ShapeDecoration(
      color: color,
      shape: const ExpressiveMaterialShapeBorder(
        ExpressiveMaterialShape.cookie9Sided,
      ),
    ),
    child: child,
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.label);
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: ExpressiveText(
      label,
      role: ExpressiveTextRole.title,
      size: ExpressiveTextSize.large,
    ),
  );
}
