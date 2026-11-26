part of '../stint_comic.dart';

const _glyphs = [
  ComicGlyphs.house,
  ComicGlyphs.circleCheck,
  ComicGlyphs.time,
  ComicGlyphs.devices,
];

class _WorkspaceState extends State<_Workspace> {
  StintController get c => widget.model;
  StintWords get w => c.words;
  ComicThemeData get t => context.comicTheme;
  final search = TextEditingController(),
      taskNavigator = GlobalKey<NavigatorState>();
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
      final answer = await showComicDialog<bool>(
        context,
        builder: (ctx) => ComicDialog(
          title: w.dirty,
          message: w.leaveMessage,
          actions: [
            ComicButton(w.cancel, onPressed: () => Navigator.pop(ctx)),
            // Discard throws the edits away: the danger tone.
            ComicButton(
              w.discard,
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(ctx, false),
            ),
            ComicButton.filled(
              w.save,
              onPressed: () => Navigator.pop(ctx, true),
            ),
          ],
        ),
      );
      return mounted && answer != null && (!answer || c.saveTask());
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
      showComicSnackBar(context, w.saved);
    }
  }

  Widget icon(IconData glyph, String label, VoidCallback press) =>
      _tip(label, ComicIconButton(glyph, label: label, onPressed: press));
  Widget get commands =>
      icon(ComicGlyphs.search, '${w.commands}  ${modifier}K', palette);
  void palette() {
    if (!c.signedIn || deciding) return;
    showComicCommand(
      context,
      hintText: w.findCommand,
      label: w.commands,
      commands: [
        for (final p in Place.values)
          RawCommand(
            label: w.place(p),
            data: _glyphs[p.index],
            onPressed: () => go(p),
          ),
        RawCommand(
          label: w.addEntry,
          data: ComicGlyphs.plus,
          onPressed: addTime,
        ),
        if (c.draft != null)
          RawCommand(
            label: w.save,
            data: ComicGlyphs.check,
            shortcut: '${modifier}S',
            onPressed: save,
          ),
      ],
    );
  }

  Widget data(Widget Function() body) => switch (c.state) {
    DataState.ready => body(),
    // In a panel, as the loading state and the empty states stand.
    DataState.error => ComicPanel(
      child: ComicErrorState(
        title: w.loadError,
        message: w.retryHelp,
        onRetry: c.refresh,
      ),
    ),
    DataState.loading => Semantics(
      liveRegion: true,
      excludeSemantics: true,
      label: w.loading,
      child: ComicPanel(
        child: Column(
          spacing: 10,
          children: [
            for (var i = 0; i < 5; i++) const ComicSkeleton(height: 41),
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
        return ComicScaffold(
          topBar: const ComicAppBar(title: 'Stint'),
          body: ComicEmptyState(
            title: w.signedOut,
            action: ComicButton.filled(
              w.returnToStudio,
              onPressed: () => c.signIn(true),
            ),
          ),
        );
      }
      final col = t.colors;
      return ColoredBox(
        color: col.background,
        child: RawAdaptiveShell(
          selectedIndex: c.place.index,
          onDestinationSelected: (i) => go(Place.values[i]),
          showNavigation: c.draft == null,
          destinations: [
            for (final p in Place.values)
              RawNavigationDestination(
                label: w.place(p),
                icon: _glyphs[p.index],
              ),
          ],
          destinationBuilder: (ctx, item, d) {
            final selected = d.states.contains(WidgetState.selected),
                side = d.mode == RawNavigationMode.sidebar,
                phone = d.mode == RawNavigationMode.bar;
            final fill = selected
                ? col.caption
                : d.states.contains(WidgetState.hovered)
                ? col.inset
                : col.card;
            final ink = selected ? col.onCaption : col.text;
            final glyph = Icon(item.icon, size: 22, color: ink);
            final letters = Text(
              item.label,
              style: (side ? t.type.title : t.type.label).copyWith(color: ink),
              textAlign: side ? TextAlign.start : TextAlign.center,
            );
            return Container(
              margin: const EdgeInsets.all(3),
              padding: EdgeInsets.symmetric(
                horizontal: side ? 9 : 2,
                vertical: phone ? 5 : 9,
              ),
              decoration: BoxDecoration(
                color: fill,
                border: Border.all(
                  width: 2,
                  color: d.states.contains(WidgetState.focused)
                      ? col.primaryText
                      : selected
                      ? col.outline
                      : fill,
                ),
              ),
              child: side
                  ? Row(
                      spacing: 10,
                      children: [
                        glyph,
                        Expanded(child: letters),
                      ],
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 2,
                      children: [
                        glyph,
                        // One word per tab: a long one ("Einstellungen")
                        // shrinks to its cell instead of breaking mid-word.
                        if (phone)
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              item.label,
                              maxLines: 1,
                              style: t.type.label.copyWith(color: ink),
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
                  color: col.card,
                  border: Border(top: BorderSide(color: col.outline, width: 2)),
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
                                            style: t.type.label,
                                          ),
                                          textDirection: Directionality.of(ctx),
                                          textScaler: MediaQuery.textScalerOf(
                                            ctx,
                                          ),
                                        ) +
                                        15)
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
                  ? (MediaQuery.textScalerOf(ctx).scale(1) > 1.4 ? 264 : 210)
                  : 66,
              decoration: BoxDecoration(
                color: col.card,
                border: BorderDirectional(
                  end: BorderSide(color: col.outline, width: 2),
                ),
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 18,
                      ),
                      child: side
                          ? ComicLetters('Stint', style: t.type.panel)
                          : Icon(
                              ComicGlyphs.circleCheck,
                              color: col.primaryText,
                              size: 30,
                            ),
                    ),
                    ...nav.destinations,
                    const Spacer(),
                    if (side)
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: ComicIndicia(w.teamName),
                      )
                    else
                      commands,
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
  Widget chart(DateTime week) {
    final minutes = c.dailyMinutes(week);
    final peak = minutes.fold(1, (a, b) => a > b ? a : b);
    final dayStyle = t.type.text(14, 1.2, weight: FontWeight.w700);
    // The readings' column as wide as the widest reading's laid-out line:
    // the web's intrinsic width runs short for Japanese, and an end-aligned
    // reading on one line would lose its last glyph.
    final figures = minutes
        .map((m) => textWidth(context, w.duration(m), dayStyle))
        .fold(0.0, (a, b) => a > b ? a : b);
    return Semantics(
      image: true,
      excludeSemantics: true,
      label: [
        w.logged,
        for (var i = 0; i < minutes.length; i++)
          '${w.weekday(addDays(week, i))} ${w.duration(minutes[i])}',
      ].join(', '),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        columnWidths: {
          0: const IntrinsicColumnWidth(),
          1: const FlexColumnWidth(),
          2: FixedColumnWidth(figures.ceilToDouble() + 1),
        },
        children: [
          for (var i = 0; i < minutes.length; i++)
            TableRow(
              children: [
                Text(w.weekdayShort(addDays(week, i)), style: dayStyle),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  child: ComicBar(
                    value: minutes[i],
                    of: peak,
                    height: 18,
                    ink: addDays(week, i) == studyToday
                        ? ComicBarFill.leading
                        : ComicBarFill.dots,
                  ),
                ),
                Text(
                  w.duration(minutes[i]),
                  style: dayStyle,
                  textAlign: TextAlign.end,
                  softWrap: false,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _Strip extends StatelessWidget {
  const _Strip({required this.first, required this.second});
  final Widget first, second;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final scale = MediaQuery.textScalerOf(context).scale(1).clamp(1, 1.4);
      if (box.maxWidth <= 700 * scale) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [first, second],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 12,
        children: [
          Expanded(flex: 5, child: first),
          Expanded(flex: 6, child: second),
        ],
      );
    },
  );
}

class _InkRow extends StatelessWidget {
  const _InkRow({
    required this.title,
    required this.subtitle,
    required this.first,
    this.leading,
    this.onPressed,
    this.chosen = false,
    this.checked,
  });
  final String title, subtitle;
  final bool first, chosen;
  final bool? checked;
  final Widget? leading;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext ctx) => ComicListTile(
    title: title,
    subtitle: subtitle,
    leading: leading,
    isFirst: first,
    label: '$title, $subtitle',
    selected: checked ?? chosen,
    onPressed: onPressed,
  );
}

Widget _tip(String label, Widget child) =>
    ComicTooltip(message: label, child: child);
