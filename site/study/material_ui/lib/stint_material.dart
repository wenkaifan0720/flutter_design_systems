import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:stint_core/stint_core.dart';

part 'src/tasks.dart';
part 'src/today.dart';
part 'src/timesheet.dart';

Future<Widget> openStintMaterial(StintLaunch launch) async =>
    StintMaterial(launch: launch);

class StintMaterial extends StatefulWidget {
  const StintMaterial({
    this.launch = const StintLaunch(),
    this.repository,
    super.key,
  });
  final StintLaunch launch;
  final StintRepository? repository;
  @override
  State<StintMaterial> createState() => _AppState();
}

class _AppState extends State<StintMaterial> {
  late final model = StintController(
    widget.repository ?? widget.launch.createRepository(),
    launch: widget.launch,
    palettes: _palettes,
  )..refresh();
  @override
  void dispose() {
    model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: model.settings,
    builder: (context, _) {
      final s = model.settings;
      ThemeData theme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor:
              StintAccent.values.asNameMap()[s.accent]?.color ?? _own.swatch,
          brightness: brightness,
        ),
        visualDensity: s.compact
            ? VisualDensity.compact
            : VisualDensity.standard,
      );
      return MaterialApp(
        title: 'Stint · Material',
        debugShowCheckedModeBanner: false,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: StintLanguage.locales,
        locale: s.language.locale,
        theme: theme(Brightness.light),
        darkTheme: theme(Brightness.dark),
        themeMode: switch (s.appearance) {
          Appearance.system => ThemeMode.system,
          Appearance.night => ThemeMode.dark,
          Appearance.day => ThemeMode.light,
        },
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: s.scale == null
                ? MediaQuery.textScalerOf(context)
                : TextScaler.linear(s.scale!),
          ),
          child: child!,
        ),
        home: _Workspace(model),
      );
    },
  );
}

class _Workspace extends StatefulWidget {
  const _Workspace(this.model);
  final StintController model;
  @override
  State<_Workspace> createState() => _Desk();
}

class _Desk extends State<_Workspace> {
  StintController get c => widget.model;
  StintWords get w => c.words;
  final search = TextEditingController();
  bool deciding = false;
  static const icons = [
    Icons.today_outlined,
    Icons.task_alt,
    Icons.schedule,
    Icons.settings_outlined,
  ];
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
      final answer = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(w.dirty),
          content: Text(w.leaveMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(w.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(w.discard),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(w.save),
            ),
          ],
        ),
      );
      return mounted && answer != null && (!answer || c.saveTask());
    } finally {
      deciding = false;
    }
  }

  Future<void> go(Place p) async {
    if (await mayLeave() && mounted) c.navigate(p);
  }

  Future<void> open(Task task) async {
    if (c.draft?.task.id != task.id && await mayLeave() && mounted) {
      c.openTask(task);
    }
  }

  Future<void> closeEditor() async {
    if (await mayLeave() && mounted) c.openTask(null);
  }

  void save() {
    if (c.draft?.dirty == true && c.saveTask()) {
      releaseSaveFocus();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(w.saved)));
    }
  }

  Future<void> commands() async {
    if (!c.signedIn || deciding) return;
    final actions = <String, VoidCallback>{
      for (final p in Place.values) w.place(p): () => go(p),
      w.addEntry: addTime,
      if (c.draft != null) w.save: save,
    };
    final selected = await showSearch<String?>(
      context: context,
      delegate: _SearchCommands(actions.keys.toList(), w),
    );
    if (mounted && selected != null) actions[selected]?.call();
  }

  Widget state(Widget Function() body) => switch (c.state) {
    DataState.loading => Center(
      child: CircularProgressIndicator(semanticsLabel: w.loading),
    ),
    // A failure says so: its glyph and headline over the help, the retry
    // under them, not three bare lines run together.
    DataState.error => Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 8,
          children: [
            Icon(
              Icons.cloud_off,
              size: 40,
              color: Theme.of(context).colorScheme.error,
            ),
            Text(
              w.loadError,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            Text(
              w.retryHelp,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(onPressed: c.refresh, child: Text(w.retry)),
          ],
        ),
      ),
    ),
    DataState.ready => body(),
  };
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final width = MediaQuery.sizeOf(context).width,
          phone = width < 650,
          wide = width >= 1000;
      if (!c.signedIn) {
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 12,
              children: [
                Text(w.signedOut),
                FilledButton(
                  onPressed: () => c.signIn(true),
                  child: Text(w.returnToStudio),
                ),
              ],
            ),
          ),
        );
      }
      final detail = c.place == Place.tasks && c.draft != null;
      final editorOnly = detail && !wide;
      final content = switch (c.place) {
        Place.today => state(today),
        Place.tasks => state(() => workspaceTasks(wide)),
        Place.time => state(time),
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
          for (final mod in [false, true]) ...{
            SingleActivator(LogicalKeyboardKey.keyK, control: !mod, meta: mod):
                commands,
            SingleActivator(LogicalKeyboardKey.keyS, control: !mod, meta: mod):
                save,
          },
        },
        child: Focus(
          autofocus: true,
          child: PopScope(
            canPop: !detail,
            onPopInvokedWithResult: (popped, _) {
              if (!popped && detail) closeEditor();
            },
            child: Scaffold(
              appBar: AppBar(
                // M3's small top app bar sets its title on the start line
                // (a Mac browser would otherwise centre it over the rail).
                centerTitle: false,
                automaticallyImplyLeading: false,
                leading: editorOnly ? BackButton(onPressed: closeEditor) : null,
                title: Text(editorOnly ? w.taskDetail : w.place(c.place)),
                actions: [
                  IconButton(
                    tooltip: '${w.commands} · Ctrl/⌘ K',
                    onPressed: commands,
                    icon: const Icon(Icons.search),
                  ),
                ],
              ),
              bottomNavigationBar: phone && !editorOnly
                  ? NavigationBar(
                      selectedIndex: c.place.index,
                      onDestinationSelected: (i) => go(Place.values[i]),
                      destinations: [
                        for (final p in Place.values)
                          NavigationDestination(
                            icon: Icon(icons[p.index]),
                            label: w.place(p),
                          ),
                      ],
                    )
                  : null,
              body: SafeArea(
                child: Row(
                  children: [
                    if (!phone && !editorOnly) ...[
                      NavigationRail(
                        extended: width >= 1250,
                        minExtendedWidth: 184,
                        selectedIndex: c.place.index,
                        onDestinationSelected: (i) => go(Place.values[i]),
                        labelType: width >= 1250
                            ? NavigationRailLabelType.none
                            : NavigationRailLabelType.all,
                        destinations: [
                          for (final p in Place.values)
                            NavigationRailDestination(
                              icon: Icon(icons[p.index]),
                              label: Text(w.place(p)),
                            ),
                        ],
                      ),
                      const VerticalDivider(width: 1),
                    ],
                    Expanded(child: content),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
  Widget heading(String title) => Semantics(
    header: true,
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget overview({
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
        padding: const EdgeInsets.all(20),
        children: [
          ...header,
          if (bounds.maxWidth >= 880)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 4, child: column(summary)),
                const SizedBox(width: 20),
                Expanded(flex: 6, child: column(records)),
              ],
            )
          else ...[
            ...summary,
            const SizedBox(height: 20),
            ...records,
          ],
        ],
      ),
    );
  }

  Widget settings() {
    final s = c.settings;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        heading(w.preferences),
        _Option<Appearance>(w.appearance, s.appearance, {
          for (final a in Appearance.values) a: w.appearanceName(a),
        }, (v) => s.update(() => s.appearance = v)),
        _Option<double>(w.textSize, s.scale ?? 1, {
          1: w.percent(1),
          1.5: w.percent(1.5),
          2: w.percent(2),
        }, (v) => s.update(() => s.scale = v)),
        _Option<StintLanguage>(w.languageLabel, s.language, {
          for (final l in StintLanguage.values) l: l.nativeName,
        }, (v) => s.update(() => s.language = v)),
        SwitchListTile(
          title: Text(w.density),
          // The setting's value, as the selects above show theirs ("Compact"
          // under a switch that was off read as a contradiction).
          subtitle: Text(s.compact ? w.compact : w.standard),
          value: s.compact,
          onChanged: (v) => s.update(() => s.compact = v),
        ),
        const Divider(),
        ListTile(
          // Maya's initial, as Today's Team activity shows her.
          leading: CircleAvatar(
            child: Text(w.text(team.first.name).characters.first),
          ),
          title: Text(w.text(team.first.name)),
          subtitle: Text(w.teamName),
        ),
        ListTile(title: Text(w.about), subtitle: Text(w.aboutDetail)),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            // Material's logout glyph doesn't turn with the text: right to
            // left its arrow pointed back into the words, so it is flipped.
            icon: Transform.flip(
              flipX: w.arabic,
              child: const Icon(Icons.logout),
            ),
            label: Text(w.signOut),
            onPressed: () async {
              final yes = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(w.signOut),
                  content: Text(w.signOutMessage),
                  actions: [
                    TextButton(
                      child: Text(w.cancel),
                      onPressed: () => Navigator.pop(ctx, false),
                    ),
                    FilledButton(
                      child: Text(w.signOut),
                      onPressed: () => Navigator.pop(ctx, true),
                    ),
                  ],
                ),
              );
              if (mounted && yes == true) c.signIn(false);
            },
          ),
        ),
      ],
    );
  }
}

class _Option<T> extends StatelessWidget {
  const _Option(this.label, this.value, this.values, this.apply);
  final String label;
  final T value;
  final Map<T, String> values;
  final ValueChanged<T> apply;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: [
        for (final item in values.entries)
          DropdownMenuItem(value: item.key, child: Text(item.value)),
      ],
      onChanged: (v) {
        if (v != null) apply(v);
      },
    ),
  );
}

class _SearchCommands extends SearchDelegate<String?> {
  _SearchCommands(this.names, this.words)
    : super(searchFieldLabel: words.findCommand);
  final List<String> names;
  final StintWords words;
  @override
  List<Widget> buildActions(BuildContext context) => [
    IconButton(
      tooltip: words.clear,
      onPressed: () => query = '',
      icon: const Icon(Icons.clear),
    ),
  ];
  @override
  Widget buildLeading(BuildContext context) =>
      BackButton(onPressed: () => close(context, null));
  Widget choices(BuildContext context) {
    final matches = names.where(
      (v) => v.toLowerCase().contains(query.trim().toLowerCase()),
    );
    return matches.isEmpty
        ? Center(child: Text(words.noCommands))
        : ListView(
            children: [
              for (final name in matches)
                ListTile(title: Text(name), onTap: () => close(context, name)),
            ],
          );
  }

  @override
  void showResults(BuildContext context) {
    final matches = names
        .where((v) => v.toLowerCase().contains(query.trim().toLowerCase()))
        .toList();
    if (matches.length == 1) {
      close(context, matches.single);
    } else {
      super.showResults(context);
    }
  }

  @override
  Widget buildResults(BuildContext context) => choices(context);
  @override
  Widget buildSuggestions(BuildContext context) => choices(context);
}

/// A short task's surface: a bottom sheet on a phone; from 600 px a dialog
/// in the middle of the window, not a phone sheet rising from its foot.
Future<T?> _raise<T>(BuildContext context, WidgetBuilder body) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: body,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (ctx) => Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        // The sheet's grip stood over its body; the dialog's edge does.
        child: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: body(ctx),
        ),
      ),
    ),
  );
}

/// Material's own seed (the Material 3 baseline's blue in this app), then
/// Stint's five seeds, for a host's palette menu.
const _own = StintPalette('look', Color(0xff415f91), label: 'Look’s own');
final _palettes = StintAccent.palettesAfter(_own);
