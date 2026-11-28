part of '../stint_fluent2_design.dart';

const _places = [
  Fluent2Icons.home,
  Fluent2Icons.taskListLtr,
  Fluent2Icons.clock,
  Fluent2Icons.settings,
];
const _activePlaces = [
  Fluent2Icons.homeFilled,
  Fluent2Icons.taskListLtrFilled,
  Fluent2Icons.clockFilled,
  Fluent2Icons.settingsFilled,
];

class _WorkspaceState extends State<_Workspace> {
  StintController get c => widget.model;
  StintWords get w => c.words;
  Fluent2ThemeData get theme => context.fluent2Theme;
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
      // Fluent2Dialog.confirm asks between two; the dialog itself takes
      // three, the primary last. Discard is the loss: a danger button.
      final save = await Fluent2Dialog.show<bool>(
        context,
        (ctx) => Fluent2Dialog(
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            Fluent2Button(w.cancel, onPressed: () => Navigator.pop(ctx)),
            Fluent2Button(
              w.discard,
              danger: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            Fluent2Button(
              w.save,
              appearance: Fluent2ButtonAppearance.primary,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
        isAlert: true,
      );
      return mounted && save != null && (!save || c.saveTask());
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
      showFluent2Toast(context, w.saved);
    }
  }

  Widget icon(IconData glyph, String label, VoidCallback pressed) => _tip(
    label,
    Fluent2IconButton(glyph, semanticLabel: label, onPressed: pressed),
  );
  Widget get commands =>
      icon(Fluent2Icons.search, '${w.commands}  ${modifier}K', palette);
  Widget _personAvatar(Person person, {double size = 32}) => Fluent2Avatar(
    name: person.name.$1,
    initials: fluent2Initials(w.text(person.name)),
    semanticLabel: w.text(person.name),
    color: Fluent2AvatarColor.colorful,
    size: size,
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
                              child: Text(title, style: theme.subtitle1),
                            ),
                            Text(
                              w.totalTasks(timerTasks.length),
                              style: theme.caption1.c(theme.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      icon(
                        Fluent2Icons.dismiss,
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
            constraints: const BoxConstraints(maxWidth: 520),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: picking ? theme.shadows.shadow28 : null,
              ),
              child: Fluent2Acrylic(
                radius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: picker,
                ),
              ),
            ),
          ),
        );
      },
      palette: (run) => RawCommandPalette(
        semanticLabel: title,
        maxHeight: picking
            ? 9.5 * 44 +
                  14 +
                  MediaQuery.textScalerOf(context)
                          .scale(theme.caption1.fontSize!) *
                      (theme.caption1.height ?? 1.33)
            : 360,
        onSelected: run,
        commands: picking
            ? [
                for (final task in timerTasks)
                  RawCommand(
                    label: w.text(task.title),
                    group: c.projectName(task.project),
                    keywords: [c.projectName(task.project)],
                    data: Fluent2Icons.documentText,
                    onPressed: () => c.track(task.id),
                  ),
              ]
            : [
                for (final p in Place.values)
                  RawCommand(
                    label: w.place(p),
                    data: _places[p.index],
                    onPressed: () => go(p),
                  ),
                RawCommand(
                  label: w.addEntry,
                  data: Fluent2Icons.calendarAdd,
                  onPressed: addTime,
                ),
                if (c.draft != null)
                  RawCommand(
                    label: w.save,
                    data: Fluent2Icons.checkmark,
                    shortcut: '${modifier}S',
                    onPressed: save,
                  ),
              ],
        groupBuilder: (_, group) => Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
          child: Text(
            group,
            style: theme.caption1Strong.c(theme.textSecondary),
          ),
        ),
        fieldBuilder: (ctx, f) => Fluent2SearchBox(
          semanticLabel: hint,
          hintText: hint,
          controller: f.controller,
          focusNode: f.focusNode,
          onSubmitted: (_) => f.submit(),
        ),
        emptyBuilder: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Text(picking ? w.noMatches : w.noCommands),
        ),
        itemBuilder: (ctx, cmd, state) {
          final focused = state.contains(WidgetState.focused);
          final face = Fluent2MenuRowFace(
            label: cmd.label,
            secondary: cmd.shortcut,
            icon: cmd.data! as IconData,
            states: {...state, if (picking && focused) WidgetState.hovered},
            emphasis: focused,
          );
          return picking
              ? ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: face,
                )
              : face;
        },
      ),
    );
  }

  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.error => Fluent2ErrorState(
      title: w.loadError,
      message: w.retryHelp,
      onRetry: c.refresh,
    ),
    DataState.loading => Semantics(
      liveRegion: true,
      label: w.loading,
      excludeSemantics: true,
      child: Fluent2Skeleton(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 8,
          children: [
            for (var i = 0; i < 6; i++) const Fluent2SkeletonItem(size: 44),
          ],
        ),
      ),
    ),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (ctx, _) {
      if (!c.signedIn) {
        return Fluent2Scaffold(
          topBar: const Fluent2AppBar(title: 'Stint'),
          body: Fluent2EmptyState(
            icon: Fluent2Icons.arrowExit,
            title: w.signedOut,
            actionLabel: w.returnToStudio,
            onAction: () => c.signIn(true),
          ),
        );
      }
      return ColoredBox(
        color: theme.background,
        child: RawAdaptiveShell(
          selectedIndex: c.place.index,
          onDestinationSelected: (i) => go(Place.values[i]),
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _places[p.index],
              ),
          ],
          destinationBuilder: (ctx, item, d) {
            final side = d.mode == RawNavigationMode.sidebar;
            final phone = d.mode == RawNavigationMode.bar;
            final active = d.states.contains(WidgetState.selected);
            final glyph = Icon(
              active ? _activePlaces[_places.indexOf(item.icon)] : item.icon,
              size: 21,
              color: active ? theme.accentText : theme.textSecondary,
            );
            final label = Text(
              item.label,
              style: (phone ? theme.caption1 : theme.body1).copyWith(
                color: theme.textPrimary,
                fontWeight: active ? FontWeight.w600 : null,
              ),
              textAlign: phone ? TextAlign.center : null,
            );
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
              padding: EdgeInsets.symmetric(
                horizontal: side ? 12 : 2,
                vertical: phone ? 5 : 10,
              ),
              decoration: BoxDecoration(
                color: active
                    ? theme.colors.neutralBackground3Selected
                    : d.states.contains(WidgetState.hovered)
                    ? theme.colors.subtleBackgroundHover
                    : null,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: d.states.contains(WidgetState.focused)
                      ? theme.focus
                      : const Color(0x00000000),
                  width: 2,
                ),
              ),
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  if (side)
                    Row(
                      spacing: 12,
                      children: [
                        glyph,
                        Expanded(child: label),
                      ],
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 3,
                      children: [glyph, if (phone) label],
                    ),
                  if (active && !phone)
                    PositionedDirectional(
                      start: side ? -10 : 0,
                      top: 2,
                      bottom: 2,
                      child: Container(
                        width: 3,
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
          navigationBuilder: (ctx, nav) {
            final side = nav.mode == RawNavigationMode.sidebar;
            if (nav.mode == RawNavigationMode.bar) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colors.neutralBackground2,
                  border: Border(top: BorderSide(color: theme.border)),
                ),
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
                                            style: theme.caption1.strong,
                                          ),
                                          textDirection: Directionality.of(ctx),
                                          textScaler: MediaQuery.textScalerOf(
                                            ctx,
                                          ),
                                        ) +
                                        16)
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
              width: side
                  ? (MediaQuery.textScalerOf(ctx).scale(1) > 1.4 ? 270 : 226)
                  : 64,
              decoration: BoxDecoration(
                color: theme.colors.neutralBackground3,
                border: BorderDirectional(end: BorderSide(color: theme.border)),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: EdgeInsetsDirectional.fromSTEB(
                        side ? 18 : 8,
                        20,
                        8,
                        16,
                      ),
                      child: Row(
                        mainAxisAlignment: side
                            ? MainAxisAlignment.start
                            : MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          Fluent2IconTile(
                            Fluent2Icons.taskListLtrFilled,
                            size: 32,
                          ),
                          if (side)
                            Flexible(
                              child: Text('Stint', style: theme.subtitle1),
                            ),
                        ],
                      ),
                    ),
                    ...nav.destinations,
                    const Spacer(),
                    if (side)
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: Fluent2ListItem(
                          title: c.personName('maya'),
                          subtitle: w.teamName,
                          leading: _personAvatar(
                            team.firstWhere((p) => p.id == 'maya'),
                          ),
                        ),
                      )
                    else if (c.place != Place.today)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: commands,
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
  Widget chart(DateTime week, {double height = 145}) {
    final values = c.dailyMinutes(week);
    return LayoutBuilder(
      builder: (ctx, box) {
        final compact =
            box.maxWidth / 7 < MediaQuery.textScalerOf(ctx).scale(54);
        final narrowFigures =
            box.maxWidth / 7 < MediaQuery.textScalerOf(ctx).scale(38);
        final peak = values.fold(1, (a, b) => a > b ? a : b).toDouble();
        // One form for the week: each day in full where every one fits its
        // column on one line, else all as h:mm, under a caption
        // naming the hours.
        final readings = WeekReadings.fit(
          ctx,
          words: w,
          minutes: values,
          style: theme.caption1Strong.tabular,
          slot: box.maxWidth / 7 - 4,
        );
        return Semantics(
          image: true,
          excludeSemantics: true,
          label: [
            w.logged,
            for (var i = 0; i < 7; i++)
              '${w.weekdayNames[i]} ${w.duration(values[i])}',
          ].join(', '),
          child: narrowFigures
              ? Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: const {
                    0: IntrinsicColumnWidth(),
                    1: FlexColumnWidth(),
                    2: IntrinsicColumnWidth(),
                  },
                  children: [
                    for (var i = 0; i < values.length; i++)
                      TableRow(
                        children: [
                          Text(
                            w.weekdayShort(addDays(week, i)),
                            style: theme.caption1,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 7,
                            ),
                            child: Fluent2ProgressBar(
                              value: values[i].toDouble(),
                              max: peak,
                            ),
                          ),
                          Text(
                            w.duration(values[i]),
                            style: theme.caption1,
                            textAlign: TextAlign.end,
                          ),
                        ],
                      ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 4,
                  children: [
                    if (readings.compact)
                      Text(
                        w.logged,
                        style: theme.caption1.c(theme.textSecondary),
                      ),
                    Fluent2BarChart(
                      height: height,
                      bars: [
                        for (var i = 0; i < 7; i++)
                          Fluent2Bar(
                            compact && !w.arabic
                                ? w.weekdayLetters[i]
                                : w.weekdayShort(addDays(week, i)),
                            values[i] / 60,
                            // A length, never a clock face: 02:30 over a bar
                            // reads as half past two.
                            valueText: readings.labels[i],
                          ),
                      ],
                    ),
                  ],
                ),
        );
      },
    );
  }
}

Fluent2Hue _hue(String project) => switch (project) {
  'studio' => Fluent2Hue.royalBlue,
  'guide' => Fluent2Hue.darkGreen,
  _ => Fluent2Hue.grape,
};

class _DeskColumns extends StatelessWidget {
  const _DeskColumns({required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (ctx, b) =>
        b.maxWidth > 740 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.3)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 20,
            children: [
              Expanded(flex: 6, child: first),
              Expanded(flex: 5, child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: [first, second],
          ),
  );
}

Widget _tip(String message, Widget child) =>
    Fluent2Tooltip(message: message, child: child);
