import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:flutter/services.dart';
import 'package:stint_core/stint_core.dart';

part 'src/tasks.dart';
part 'src/today.dart';
part 'src/time.dart';

Future<Widget> openStintCupertino(StintLaunch launch) async =>
    StintCupertino(launch: launch);

class StintCupertino extends StatefulWidget {
  const StintCupertino({
    this.launch = const StintLaunch(),
    this.repository,
    super.key,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintCupertino> createState() => _AppState();
}

class _AppState extends State<StintCupertino> {
  late final c = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  @override
  void dispose() {
    c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c.settings,
    builder: (context, _) {
      final s = c.settings;
      return CupertinoApp(
        title: 'Stint · Cupertino',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalCupertinoLocalizations.delegates,
        supportedLocales: StintLanguage.locales,
        locale: s.language.locale,
        theme: CupertinoThemeData(
          brightness: switch (s.appearance) {
            Appearance.night => Brightness.dark,
            Appearance.day => Brightness.light,
            Appearance.system => null,
          },
          primaryColor: _accent(s.accent),
        ),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: s.scale == null
                ? MediaQuery.textScalerOf(context)
                : TextScaler.linear(s.scale!),
          ),
          child: ColoredBox(
            color: CupertinoColors.systemGroupedBackground.resolveFrom(context),
            child: child!,
          ),
        ),
        home: _Workspace(c),
      );
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace(this.c);
  final StintController c;
  @override
  State<_Workspace> createState() => _Desk();
}

class _Desk extends State<_Workspace> {
  StintController get c => widget.c;
  StintWords get w => c.words;
  final search = TextEditingController();
  List<Task> removed = [];
  bool modal = false;
  static const icons = [
    CupertinoIcons.today,
    CupertinoIcons.check_mark_circled,
    CupertinoIcons.clock,
    CupertinoIcons.settings,
  ];
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Future<bool> mayLeave() async {
    if (c.draft?.dirty != true) return true;
    if (modal) return false;
    modal = true;
    try {
      final choice = await showCupertinoDialog<String>(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: Text(w.dirty),
          content: Text(w.leaveMessage),
          // Three actions stand in a stack, as UIAlertController stacks
          // them: the default first, Cancel at the foot.
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(w.save),
              onPressed: () => Navigator.pop(ctx, 'save'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: Text(w.discard),
              onPressed: () => Navigator.pop(ctx, 'discard'),
            ),
            CupertinoDialogAction(
              child: Text(w.cancel),
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
      return mounted &&
          (choice == 'discard' || choice == 'save' && c.saveTask());
    } finally {
      modal = false;
    }
  }

  Future<void> go(Place p) async {
    if (await mayLeave() && mounted) c.navigate(p);
  }

  Future<void> open(Task t) async {
    if (c.draft?.task.id != t.id && await mayLeave() && mounted) c.openTask(t);
  }

  Future<void> back() async {
    if (await mayLeave() && mounted) c.openTask(null);
  }

  void save() {
    // The key goes as the draft comes clean: focus leaves it first.
    if (c.draft?.dirty == true && c.saveTask()) releaseSaveFocus();
  }

  Future<void> commands() async {
    if (!c.signedIn || modal) return;
    final actions = <String, VoidCallback>{
      for (final p in Place.values) w.place(p): () => go(p),
      w.addEntry: addTime,
      if (c.draft != null) w.save: save,
    };
    final chosen = await _present<String>(
      context,
      height: _Choices.height(actions.length, prompt: true),
      (ctx, scroll) => _Choices<String>(
        title: w.commands,
        prompt: w.findCommand,
        empty: w.noCommands,
        values: {for (final label in actions.keys) label: label},
        scroll: scroll,
      ),
    );
    if (mounted && chosen != null) actions[chosen]?.call();
  }

  Widget data(Widget Function() ready) => switch (c.state) {
    DataState.ready => ready(),
    DataState.loading => Center(
      child: Semantics(
        label: w.loading,
        child: const CupertinoActivityIndicator(radius: 14),
      ),
    ),
    DataState.error => Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 6,
          // A failure says so: its glyph and a headline over the help (two
          // lines of one plain text read as one note).
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_triangle,
              size: 36,
              color: CupertinoColors.systemRed,
            ),
            Text(
              w.loadError,
              textAlign: TextAlign.center,
              style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
            ),
            Text(
              w.retryHelp,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
            ),
            CupertinoButton(onPressed: c.refresh, child: Text(w.retry)),
          ],
        ),
      ),
    ),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final width = MediaQuery.sizeOf(context).width,
          phone = width < 650,
          wide = width >= 1050,
          detail = c.place == Place.tasks && c.draft != null && width < 1050;
      final title = detail ? w.taskDetail : w.place(c.place);
      final background = CupertinoColors.systemGroupedBackground.resolveFrom(
        context,
      );
      if (!c.signedIn) {
        return CupertinoPageScaffold(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(w.signedOut),
                CupertinoButton(
                  onPressed: () => c.signIn(true),
                  child: Text(w.returnToStudio),
                ),
              ],
            ),
          ),
        );
      }
      final body = switch (c.place) {
        Place.today => data(today),
        Place.tasks => data(() => tasks(wide)),
        Place.time => data(time),
        // On the page's start line, where Today, Tasks and Time begin:
        // centred, the column stood 230 px off it beside the sidebar.
        Place.settings => Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: settings(),
          ),
        ),
      };
      return CallbackShortcuts(
        bindings: {
          for (final cmd in [false, true]) ...{
            SingleActivator(LogicalKeyboardKey.keyK, control: !cmd, meta: cmd):
                commands,
            SingleActivator(LogicalKeyboardKey.keyS, control: !cmd, meta: cmd):
                save,
          },
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: c.draft == null,
            onPopInvokedWithResult: (popped, _) {
              if (!popped && c.draft != null) back();
            },
            child: CupertinoPageScaffold(
              backgroundColor: background,
              navigationBar: CupertinoNavigationBar(
                backgroundColor: CupertinoColors.systemBackground.resolveFrom(
                  context,
                ),
                automaticallyImplyLeading: false,
                leading: detail
                    ? CupertinoNavigationBarBackButton(onPressed: back)
                    : null,
                middle: Text(title),
                trailing: _IconButton(
                  w.commands,
                  CupertinoIcons.search,
                  commands,
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          if (!phone && !detail)
                            SizedBox(
                              width: width >= 1050 ? 224 : 160,
                              child: ListView(
                                children: [
                                  CupertinoListSection.insetGrouped(
                                    margin:
                                        const EdgeInsetsDirectional.fromSTEB(
                                          6,
                                          12,
                                          6,
                                          12,
                                        ),
                                    header: Text(w.workspace),
                                    children: [
                                      for (final p in Place.values)
                                        _RowTile(
                                          leading: Icon(icons[p.index]),
                                          title: Text(w.place(p)),
                                          // Lit and said as selected: the
                                          // place that is open.
                                          selected: c.place == p,
                                          onTap: () => go(p),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Expanded(child: body),
                        ],
                      ),
                    ),
                    if (phone && !detail)
                      CupertinoTabBar(
                        inactiveColor: _secondaryInk(context),
                        height:
                            50 +
                            (MediaQuery.textScalerOf(context).scale(13) - 13) *
                                2,
                        currentIndex: c.place.index,
                        onTap: (i) => go(Place.values[i]),
                        items: [
                          for (final p in Place.values)
                            BottomNavigationBarItem(
                              icon: Icon(icons[p.index]),
                              label: w.place(p),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget groupedOverview({
    List<Widget> header = const [],
    required List<Widget> summary,
    required List<Widget> records,
  }) {
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return LayoutBuilder(
      builder: (context, bounds) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ...header,
          if (bounds.maxWidth >= 820)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: column(summary)),
                const SizedBox(width: 8),
                Expanded(flex: 6, child: column(records)),
              ],
            )
          else ...[
            ...summary,
            const SizedBox(height: 8),
            ...records,
          ],
        ],
      ),
    );
  }

  Future<T?> choose<T>(
    String label,
    Map<T, String> choices, {
    T? value,
    bool searchable = false,
  }) => _present<T>(
    context,
    height: _Choices.height(choices.length, prompt: searchable),
    (ctx, scroll) => _Choices<T>(
      title: label,
      values: choices,
      value: value,
      prompt: searchable ? w.selectPerson : null,
      empty: w.noPeople,
      scroll: scroll,
    ),
  );
  Widget settings() {
    final s = c.settings;
    return ListView(
      children: [
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          header: Text(w.preferences),
          children: [
            _SettingRow(w.appearance, w.appearanceName(s.appearance), () async {
              final v = await choose(w.appearance, {
                for (final v in Appearance.values) v: w.appearanceName(v),
              }, value: s.appearance);
              if (mounted && v != null) s.update(() => s.appearance = v);
            }),
            _SettingRow(w.textSize, w.percent(s.scale ?? 1), () async {
              final v = await choose<double>(w.textSize, {
                1: w.percent(1),
                1.5: w.percent(1.5),
                2: w.percent(2),
              }, value: s.scale ?? 1);
              if (mounted && v != null) s.update(() => s.scale = v);
            }),
            _SettingRow(w.languageLabel, s.language.nativeName, () async {
              final v = await choose(w.languageLabel, {
                for (final l in StintLanguage.values) l: l.nativeName,
              }, value: s.language);
              if (mounted && v != null) s.update(() => s.language = v);
            }),
            _RowTile(
              title: Text(w.density),
              // The setting's value, as the rows above show theirs
              // ("Compact" over a switch that was off read as a
              // contradiction).
              subtitle: Text(s.compact ? w.compact : w.standard),
              trailing: CupertinoSwitch(
                value: s.compact,
                onChanged: (v) => s.update(() => s.compact = v),
              ),
            ),
          ],
        ),
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          header: Text(w.account),
          children: [
            _RowTile(
              title: Text(w.text(team.first.name)),
              subtitle: Text(w.teamName),
            ),
            _RowTile(title: Text(w.about), subtitle: Text(w.aboutDetail)),
          ],
        ),
        // Sign out in a group of its own, as Settings sets a destructive
        // act apart from the account's facts.
        CupertinoListSection.insetGrouped(
          hasLeading: false,
          children: [
            _RowTile(
              title: Text(
                w.signOut,
                style: const TextStyle(color: CupertinoColors.systemRed),
              ),
              onTap: () async {
                final yes = await showCupertinoDialog<bool>(
                  context: context,
                  builder: (ctx) => CupertinoAlertDialog(
                    title: Text(w.signOut),
                    content: Text(w.signOutMessage),
                    actions: [
                      // iOS sets the safe way out in bold beside a
                      // destructive act.
                      CupertinoDialogAction(
                        isDefaultAction: true,
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(w.cancel),
                      ),
                      CupertinoDialogAction(
                        isDestructiveAction: true,
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(w.signOut),
                      ),
                    ],
                  ),
                );
                if (mounted && yes == true) c.signIn(false);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow(this.label, this.value, this.tap);
  final String label, value;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => _RowTile(
    title: Text(label),
    subtitle: Text(value),
    trailing: const CupertinoListTileChevron(),
    onTap: tap,
  );
}

class _IconButton extends StatelessWidget {
  const _IconButton(this.label, this.icon, this.tap);
  final String label;
  final IconData icon;
  final VoidCallback tap;
  @override
  Widget build(BuildContext context) => CupertinoButton(
    padding: EdgeInsets.zero,
    onPressed: tap,
    child: Icon(icon, semanticLabel: label),
  );
}

class _Choices<T> extends StatefulWidget {
  const _Choices({
    required this.title,
    required this.values,
    this.subtitles = const {},
    required this.empty,
    this.prompt,
    this.value,
    required this.scroll,
  });
  final String title, empty;
  final String? prompt;
  final Map<T, String> values;
  final Map<T, String> subtitles;
  final T? value;
  final ScrollController? scroll;

  /// The height a form sheet gives [count] choices, so a short list is not
  /// left in a tall, empty sheet.
  static double height(
    int count, {
    bool prompt = false,
    bool subtitles = false,
  }) => 44 + (prompt ? 68 : 0) + 56 + count * (subtitles ? 58 : 44);

  @override
  State<_Choices<T>> createState() => _ChoicesState<T>();
}

class _ChoicesState<T> extends State<_Choices<T>> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final matches = widget.values.entries
        .where(
          (e) => e.value.toLowerCase().contains(query.trim().toLowerCase()),
        )
        .toList();
    return CupertinoPageScaffold(
      // The grouped ground runs to the sheet's foot, under a short list too.
      backgroundColor: CupertinoColors.systemGroupedBackground,
      navigationBar: CupertinoNavigationBar(
        middle: Semantics(
          container: true,
          header: true,
          child: Text(widget.title),
        ),
        leading: Semantics(
          container: true,
          child: CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: Text(CupertinoLocalizations.of(context).cancelButtonLabel),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.prompt != null)
              // On the list's inset-group margins, so the field's edges
              // meet the group's under it.
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: CallbackShortcuts(
                  bindings: {
                    if (matches.length == 1)
                      for (final key in [
                        LogicalKeyboardKey.enter,
                        LogicalKeyboardKey.numpadEnter,
                      ])
                        SingleActivator(key): () =>
                            Navigator.pop(context, matches.single.key),
                  },
                  child: CupertinoSearchTextField(
                    placeholder: widget.prompt,
                    autofocus: true,
                    onChanged: (v) => setState(() => query = v),
                    onSubmitted: (_) {
                      if (matches.length == 1) {
                        Navigator.pop(context, matches.first.key);
                      }
                    },
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                controller: widget.scroll,
                children: [
                  CupertinoListSection.insetGrouped(
                    hasLeading: false,
                    dividerMargin: 20,
                    additionalDividerMargin: 0,
                    children: [
                      if (matches.isEmpty) _RowTile(title: Text(widget.empty)),
                      for (final e in matches)
                        // The check says which is chosen; a screen reader hears it
                        // as selected.
                        Semantics(
                          container: true,
                          selected: e.key == widget.value,
                          child: _RowTile(
                            title: Text(e.value),
                            padding: widget.subtitles.isEmpty
                                ? null
                                : const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 5,
                                  ),
                            subtitle: switch (widget.subtitles[e.key]) {
                              final subtitle? => Text(
                                subtitle,
                                style: TextStyle(color: _secondaryInk(context)),
                              ),
                              null => null,
                            },
                            trailing: e.key == widget.value
                                ? const Icon(CupertinoIcons.check_mark)
                                : null,
                            onTap: () => Navigator.pop(context, e.key),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RowTile extends StatefulWidget {
  const _RowTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.additionalInfo,
    this.rowAction,
    this.padding,
    this.onTap,
    this.checked,
    this.selected = false,
  });
  final Widget title;
  final Widget? subtitle, leading, trailing, additionalInfo, rowAction;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool? checked;
  final bool selected;
  @override
  State<_RowTile> createState() => _RowTileState();
}

class _RowTileState extends State<_RowTile> {
  bool showFocus = false;
  Widget wrap(Widget child) => DefaultTextStyle.merge(
    maxLines: 8,
    overflow: TextOverflow.visible,
    child: child,
  );
  @override
  Widget build(BuildContext context) {
    // An iOS subtitle cell: a secondary line set as Today's rows set it, and
    // room above and below the pair (the base tile gives neither).
    final subtitle = widget.subtitle == null
        ? null
        : DefaultTextStyle.merge(
            style: TextStyle(fontSize: 14, color: _secondaryInk(context)),
            child: wrap(widget.subtitle!),
          );
    final tile = CupertinoListTile(
      padding:
          widget.padding ??
          (subtitle == null
              ? null
              : const EdgeInsetsDirectional.fromSTEB(20, 10, 14, 10)),
      leading: widget.leading,
      title: wrap(widget.title),
      subtitle: subtitle,
      backgroundColor: widget.selected
          ? CupertinoColors.systemFill.resolveFrom(context)
          : null,
      additionalInfo: widget.additionalInfo,
      trailing: widget.rowAction == null
          ? widget.trailing
          : const SizedBox(width: 44),
      onTap: widget.onTap,
    );
    if (widget.onTap == null) return tile;
    final primary = Semantics(
      checked: widget.checked,
      selected: widget.selected ? true : null,
      child: FocusableActionDetector(
        onShowFocusHighlight: (v) => setState(() => showFocus = v),
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
          SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
        },
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap!();
              return null;
            },
          ),
        },
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            border: showFocus
                ? Border.all(
                    color: CupertinoTheme.of(context).primaryColor,
                    width: 2,
                  )
                : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: tile,
        ),
      ),
    );
    final action = widget.rowAction;
    if (action == null) return primary;
    return Stack(
      alignment: AlignmentDirectional.centerEnd,
      children: [
        primary,
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: action,
        ),
      ],
    );
  }
}

/// Whether the window is wide enough for iOS to present sheets as iPad form
/// sheets rather than from the foot of the screen.
bool _wide(BuildContext context) => MediaQuery.sizeOf(context).width >= 650;

/// Presents [builder] the way iOS does at this width: a sheet from the foot on
/// a phone; on a wide window, a form sheet at most 540 wide, centred over the
/// dimmed app and no taller than [height] (its content) needs.
Future<T?> _present<T>(
  BuildContext context,
  Widget Function(BuildContext context, ScrollController? scroll) builder, {
  double height = 620,
}) => _wide(context)
    ? showCupertinoModalPopup<T>(
        context: context,
        builder: (ctx) => _FormSheet(height: height, child: builder(ctx, null)),
      )
    : showCupertinoSheet<T>(context: context, scrollableBuilder: builder);

/// An iPad form sheet: centred, at most 540 wide, its corners rounded.
class _FormSheet extends StatelessWidget {
  const _FormSheet({required this.height, required this.child});
  final double height;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context),
        scale = MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 2.0);
    // The route lays its page on the screen's foot; the sheet stands centred
    // on it, and a press beside the sheet reaches the barrier.
    return SizedBox.fromSize(
      size: size,
      child: Center(
        child: SizedBox(
          width: math.min(540, size.width - 48),
          height: math.min(
            math.min(height * scale, 620.0 * scale),
            size.height - 80,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Cupertino's own system blue, then Stint's five seeds, for a host's
/// palette menu.
final _palettes = StintAccent.palettesAfter(
  const StintPalette('look', CupertinoColors.systemBlue, label: 'Look’s own'),
);

/// The palette's accent; by night a lighter tone of its hue wherever the
/// colour itself would sink into the dark grounds (navy on black), as each
/// of iOS's system colours carries its own dark variant. The look's own
/// blue (null here) is the system's, dark variant and all.
Color? _accent(String? id) {
  final color = StintAccent.values.asNameMap()[id]?.color;
  if (color == null) return null;
  // The night's grouped rows, the lighter of the grounds the accent marks
  // (the page under them is black): words in the accent read there (4.5:1).
  final ground = CupertinoColors.secondarySystemGroupedBackground.darkColor;
  double ratio(Color c) =>
      (c.computeLuminance() + .05) / (ground.computeLuminance() + .05);
  var night = HSLColor.fromColor(color);
  while (ratio(night.toColor()) < 4.5 && night.lightness < 1) {
    night = night.withLightness(math.min(1, night.lightness + .01));
  }
  return CupertinoDynamicColor.withBrightness(
    color: color,
    darkColor: night.toColor(),
  );
}
