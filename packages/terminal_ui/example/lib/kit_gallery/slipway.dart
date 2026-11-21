/// slipway, Terminal's example app: a small team's deploy console. Its
/// own navigation (the window list at a phone's foot, the side pane at a
/// desk, Alt and a digit from the keyboard), the title line and the status
/// line, round its screens.
library;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'kit.dart';
import 'slipway_more.dart';
import 'slipway_pages.dart';

/// Where slipway opens: a destination, or one of its everyday screens in
/// a particular state.
enum SlipwayPlace {
  /// The projects and their last runs.
  home,

  /// The runs, filtered (at a desk, the tiled panes).
  runs,

  /// One run: its steps and its log.
  run,

  /// The new-deploy form.
  deploy,

  /// The config file.
  settings,

  /// The runs, the command palette open over them, `dep` typed.
  palette,

  /// Run #1481's change, as a diff.
  diff,

  /// The runs searched for a project that is not there, the server out of
  /// reach.
  search,

  /// The config file, asking to delete the project: type its name.
  confirm,

  /// The desk's tiled panes, the keyboard in the log, `token` searched.
  desk,
}

/// slipway in [brightness], laid out [direction], opening at [place].
Widget slipwayApp(
  Brightness brightness, {
  TextDirection? direction,
  SlipwayPlace place = SlipwayPlace.home,
  TermThemeData? theme,
}) => kitApp(
  brightness: brightness,
  direction: direction,
  theme: theme,
  home: SlipwayShell(place: place),
);

/// slipway's frame: the title line, its navigation, the status line, and
/// the screen at [place].
class SlipwayShell extends StatefulWidget {
  /// The shell, opening at [place].
  const SlipwayShell({
    super.key,
    this.place = SlipwayPlace.home,
    this.initialRun,
    this.onExit,
  });

  /// The run selected in the overview.
  final int? initialRun;

  /// Where it opens.
  final SlipwayPlace place;

  /// Called by the title line's back key; null: no back key.
  final VoidCallback? onExit;

  @override
  State<SlipwayShell> createState() => _SlipwayShellState();
}

const _destinations = [
  TermNavigationDestination(
    label: 'home',
    glyph: '~',
    shortcut: SingleActivator(LogicalKeyboardKey.digit1, alt: true),
  ),
  TermNavigationDestination(
    label: 'runs',
    glyph: '#',
    shortcut: SingleActivator(LogicalKeyboardKey.digit2, alt: true),
  ),
  TermNavigationDestination(
    label: 'deploy',
    glyph: '↑',
    shortcut: SingleActivator(LogicalKeyboardKey.digit3, alt: true),
  ),
  TermNavigationDestination(
    label: 'config',
    glyph: '=',
    shortcut: SingleActivator(LogicalKeyboardKey.digit4, alt: true),
  ),
];

const _deskPanes = ['runs', 'run', 'log'];

class _SlipwayShellState extends State<SlipwayShell> {
  late int _tab = switch (widget.place) {
    SlipwayPlace.home => 0,
    SlipwayPlace.runs ||
    SlipwayPlace.run ||
    SlipwayPlace.palette ||
    SlipwayPlace.diff ||
    SlipwayPlace.search ||
    SlipwayPlace.desk => 1,
    SlipwayPlace.deploy => 2,
    SlipwayPlace.settings || SlipwayPlace.confirm => 3,
  };
  late int? _openRun =
      widget.initialRun ??
      switch (widget.place) {
        SlipwayPlace.run || SlipwayPlace.diff || SlipwayPlace.desk => 1481,
        _ => null,
      };
  // A desk opens a run that is still going: the failing one is already in
  // its runs' tiles.
  late int _deskRun =
      widget.initialRun ?? (widget.place == SlipwayPlace.run ? 1482 : 1481);
  final _runs = [...slipwayRuns];
  final _projects = [...slipwayProjects];
  int _nextRun = 1490;
  String _environment = 'staging';
  int _draft = 0;
  int? _beforeDeploy;

  // The sidebar takes 27 cells. The three panes need 42, 38 and at
  // least 22 cells, plus four cells for the margins and column gaps.
  bool _tilesFit(BuildContext context) =>
      context.termGrid.colsIn(MediaQuery.sizeOf(context).width) >= 133;
  late bool _diff = widget.place == SlipwayPlace.diff;
  // Away from a desk, the desk's place is its log pane alone, searched.
  late bool _logOnly = widget.place == SlipwayPlace.desk;
  // The place's own state shows once; a destination chosen after it opens
  // plain.
  late SlipwayPlace? _staged = widget.place;

  @override
  void initState() {
    super.initState();
    if (widget.place == SlipwayPlace.palette) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _commands(query: 'dep');
      });
    }
  }

  void _go(int tab, {String environment = 'staging'}) => setState(() {
    if (tab == 2) {
      if (_tab != 2) _beforeDeploy = _tab;
      _environment = environment;
      _draft++;
      _tab = tab;
      return;
    }
    _tab = tab;
    _openRun = null;
    _diff = false;
    _logOnly = false;
    _staged = null;
  });

  void _discardDeploy() {
    final origin = _beforeDeploy;
    if (origin != null) {
      setState(() => _tab = origin);
    } else if (widget.onExit != null) {
      widget.onExit!();
    } else {
      _go(1);
    }
  }

  void _open(int run) => setState(() {
    if (!_runs.any((entry) => entry.number == run)) return;
    _tab = 1;
    _openRun = run;
    _deskRun = run;
    _diff = false;
    _logOnly = false;
    _staged = null;
  });

  void _showDiff(int run) => setState(() {
    _tab = 1;
    _openRun = run;
    _deskRun = run;
    _diff = true;
    _logOnly = false;
    _staged = null;
  });

  void _deleteProject(Project project) {
    setState(() {
      _projects.removeWhere((p) => p.name == project.name);
      _runs.removeWhere((r) => r.project == project.name);
      _tab = 0;
      _openRun = null;
      _deskRun = _runs.firstOrNull?.number ?? 0;
      _diff = false;
      _logOnly = false;
      _staged = null;
      _beforeDeploy = null;
    });
    TermToaster.show(
      context,
      message: '${project.name} deleted',
      tone: TermTone.warning,
    );
  }

  void _cancelRun(Run run) {
    final index = _runs.indexWhere((r) => r.number == run.number);
    if (index < 0 || _runs[index].status != RunStatus.running) return;
    setState(
      () => _runs[index] = (
        number: run.number,
        project: run.project,
        branch: run.branch,
        commit: run.commit,
        message: run.message,
        author: run.author,
        status: RunStatus.canceled,
        duration: run.duration,
        ago: 'now',
        trigger: run.trigger,
        progress: run.progress,
      ),
    );
    TermToaster.show(context, message: 'run #${run.number} canceled');
  }

  void _queue(
    String project,
    String branch, {
    String? environment,
    Run? rerun,
  }) {
    final source =
        rerun ??
        _runs
            .where((r) => r.project == project && r.branch == branch)
            .firstOrNull;
    final number = _nextRun++;
    final message = environment == null
        ? rerun!.message
        : 'deploy to $environment';
    setState(
      () => _runs.insert(0, (
        number: number,
        project: project,
        branch: branch,
        commit: source?.commit ?? 'awaiting checkout',
        message: message,
        author: 'you',
        status: RunStatus.queued,
        duration: '–',
        ago: 'now',
        trigger: 'manual',
        progress: null,
      )),
    );
    TermToaster.show(
      context,
      message: environment == null
          ? 'rerun #$number queued from #${rerun!.number}'
          : 'deploy #$number queued: $project $branch → $environment',
      tone: TermTone.success,
      actionLabel: 'watch',
      onAction: () => _open(number),
    );
  }

  void _rerun(Run run) => _queue(run.project, run.branch, rerun: run);

  // The palette: everything the keys and the panes do, by name.
  Future<void> _commands({String? query}) {
    RawCommand go(int i, String words) => RawCommand(
      label: words,
      group: 'go',
      shortcut: termKeyLabel(_destinations[i].shortcut!),
      onPressed: () => _go(i),
    );
    final project = _projects.first.name;
    final failed = _runs.where((r) => r.number == 1481).firstOrNull;
    return showTermCommandPalette(
      context: context,
      initialQuery: query,
      commands: [
        go(0, 'go home'),
        go(1, 'go to the runs'),
        go(2, 'new deploy'),
        go(3, 'open the config'),
        for (final r in _runs.take(4))
          RawCommand(
            label: 'open run #${r.number} ${r.project}',
            group: 'runs',
            keywords: [r.branch, r.message],
            onPressed: () => _open(r.number),
          ),
        if (failed != null)
          RawCommand(
            label: 'show the change in #1481',
            group: 'runs',
            keywords: const ['diff', 'fix/flaky-auth'],
            onPressed: () => _showDiff(1481),
          ),
        if (failed != null)
          RawCommand(
            label: 'rerun #1481',
            group: 'runs',
            onPressed: () => _rerun(failed),
          ),
        RawCommand(
          label: 'deploy $project to staging',
          group: 'deploy',
          keywords: const ['ship', 'release'],
          onPressed: () => _go(2),
        ),
        RawCommand(
          label: 'deploy $project to production',
          group: 'deploy',
          keywords: const ['ship', 'release'],
          onPressed: () => _go(2, environment: 'production'),
        ),
        const RawCommand(
          label: 'roll back production',
          group: 'deploy',
          enabled: false,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_projects.isEmpty) {
      return SafeArea(
        child: Center(
          child: TermEmptyState(
            title: 'no projects',
            message: 'all projects and their runs have been deleted',
            action: widget.onExit == null
                ? null
                : TermButton(
                    label: 'back to overview',
                    onPressed: widget.onExit,
                  ),
          ),
        ),
      );
    }
    final desk = _tilesFit(context);
    if (desk && _tab == 1 && !_diff) {
      return DeskPanes(
        panes: _deskPanes,
        initial: switch (_staged) {
          SlipwayPlace.desk => 2,
          SlipwayPlace.run => 1,
          _ => 0,
        },
        initialControl: _staged == SlipwayPlace.desk,
        builder: (context, focusOf, current) =>
            _frame(context, paneFocus: focusOf, pane: current),
      );
    }
    return _frame(context);
  }

  Widget _frame(
    BuildContext context, {
    FocusNode Function(int i)? paneFocus,
    int? pane,
  }) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final width = MediaQuery.sizeOf(context).width;
    final phone = width < 600 || grid.colsIn(width) < 64;
    final desk = _tilesFit(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final run = _runs.firstWhere(
      (r) => r.number == (desk && !_diff ? _deskRun : _openRun ?? _deskRun),
    );

    final Widget page = switch (_tab) {
      0 => HomePage(
        projects: _projects,
        runs: _runs,
        onOpenRun: _open,
        wide: !phone,
      ),
      1 when _diff => DiffPage(run: run),
      1 when desk => RunsTiled(
        runs: _runs,
        onCancel: _cancelRun,
        onRerun: _rerun,
        selected: _deskRun,
        onSelect: (n) => setState(() {
          _deskRun = n;
          if (_openRun != null) _openRun = n;
        }),
        rtl: rtl,
        paneFocus: paneFocus,
        pane: pane,
        onDiff: () => _showDiff(_deskRun),
        logQuery: _staged == SlipwayPlace.desk ? 'token' : '',
        query: _staged == SlipwayPlace.search ? 'mobile-gatway' : '',
        offline: _staged == SlipwayPlace.search,
      ),
      1 when _logOnly => PageScroll(
        children: [LogPane(run: run, expand: false, query: 'token')],
      ),
      1 when _openRun != null => RunDetailPage(
        run: run,
        onCancel: _cancelRun,
        onRerun: _rerun,
        rtl: rtl,
        onDiff: () => _showDiff(run.number),
      ),
      1 => RunsPage(
        runs: _runs,
        onOpenRun: _open,
        rtl: rtl,
        query: _staged == SlipwayPlace.search ? 'mobile-gatway' : '',
        offline: _staged == SlipwayPlace.search,
      ),
      2 => DeployPage(
        key: ValueKey(_draft),
        projects: _projects,
        initialBranch: _runs
            .firstWhere((r) => r.project == _projects.first.name)
            .branch,
        initialEnvironment: _environment,
        onCancel: _discardDeploy,
        onDeploy: (project, branch, environment) =>
            _queue(project, branch, environment: environment),
      ),
      _ => SettingsPage(
        key: ValueKey(_projects.first.name),
        project: _projects.first,
        runCount:
            _projects.first.runs +
            _runs
                .where(
                  (r) => r.number >= 1490 && r.project == _projects.first.name,
                )
                .length,
        onDelete: _deleteProject,
        askToDelete: _staged == SlipwayPlace.confirm,
      ),
    };

    final path = [
      _destinations[_tab].label,
      if (_tab == 1 && (_openRun != null || desk)) '#${run.number}',
      if (_tab == 1 && _diff) 'change',
      if (_tab == 1 && _logOnly && !desk) 'log',
    ].join(' › ');

    VoidCallback? backTo;
    String? backWords;
    if (_tab == 1 && (_diff || _logOnly && !desk)) {
      backTo = () => setState(() {
        _diff = false;
        _logOnly = false;
      });
      backWords = 'back to run #${run.number}';
    } else if (_tab == 1 && _openRun != null && !desk) {
      backTo = () => setState(() => _openRun = null);
      backWords = 'back to runs';
    } else if (widget.onExit != null) {
      backTo = widget.onExit;
      backWords = 'back to the overview';
    }
    final back = backTo == null
        ? null
        : TermIconButton(
            glyph: rtl ? '→' : '←',
            semanticLabel: backWords!,
            onPressed: backTo,
          );

    final bindings = <ShortcutActivator, VoidCallback>{
      if (_tab == 2)
        const SingleActivator(LogicalKeyboardKey.escape): _discardDeploy,
      for (var i = 0; i < _destinations.length; i++)
        _destinations[i].shortcut!: () => _go(i),
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): _commands,
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): _commands,
    };

    final top = TermTopBar(
      leading: back,
      title: 'slipway',
      subtitle: path,
      actions: [
        TermIconButton(
          glyph: '>',
          semanticLabel: 'commands',
          onPressed: _commands,
        ),
      ],
    );

    final failing = _runs.where((r) => r.status == RunStatus.failed).length;
    final running = _runs.where((r) => r.status == RunStatus.running).length;
    final passing = _runs.where((r) => r.status == RunStatus.passed).length;
    // Where it is and how it stands: the project and its branch (the open
    // run's, while one is on the screen), and its runs.
    final inRun = _tab == 1 && (_openRun != null || desk);
    final project = inRun ? run.project : _projects.first.name;
    final branch = inRun ? run.branch : 'main';
    final standing = [
      TermStatusSegment(project),
      TermStatusSegment('\u{E0A0} $branch', semanticLabel: 'branch $branch'),
      TermStatusSegment(
        '✓$passing',
        color: theme.success,
        semanticLabel: '$passing passing',
      ),
      TermStatusSegment(
        '✗$failing',
        color: theme.danger,
        semanticLabel: '$failing failing',
      ),
      TermStatusSegment(
        '●$running',
        color: theme.accent,
        semanticLabel: '$running running',
      ),
    ];

    Widget body;
    if (phone) {
      // A phone ends in its status line too, over the windows a thumb
      // switches between; its keys are the buttons, so it names none.
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          Expanded(child: page),
          TermStatusLine(
            mode: _destinations[_tab].label.toUpperCase(),
            segments: standing,
          ),
          TermNavigationBar(
            destinations: _destinations,
            selectedIndex: _tab,
            onDestinationSelected: _go,
          ),
        ],
      );
    } else {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          top,
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsetsDirectional.only(
                    start: grid.cellWidth,
                    top: grid.lineHeight,
                    bottom: grid.lineHeight,
                  ),
                  child: SizedBox(
                    width: grid.cols(desk ? 26 : 22),
                    child: TermSideBar(
                      title: 'harbor',
                      destinations: _destinations,
                      selectedIndex: _tab,
                      onDestinationSelected: _go,
                    ),
                  ),
                ),
                Expanded(child: page),
              ],
            ),
          ),
          TermStatusLine(
            mode: _destinations[_tab].label.toUpperCase(),
            segments: [
              if (pane != null) ...deskSegments(theme, _deskPanes, pane),
              ...standing,
            ],
            keys: [
              if (pane != null) (keys: '[ ]', label: 'pane'),
              (keys: '^K', label: 'commands'),
              (keys: 'M-1…4', label: 'go'),
            ],
          ),
        ],
      );
    }

    return CallbackShortcuts(
      bindings: bindings,
      child: Focus(autofocus: true, child: SafeArea(child: body)),
    );
  }
}

/// A run's status as a glyph in its tone, a spinner while it runs; a
/// screen reader hears the status's word.
class StatusGlyph extends StatelessWidget {
  /// The glyph for [status].
  const StatusGlyph(this.status, {super.key});

  /// The status shown.
  final RunStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    if (status == RunStatus.running) {
      return const TermSpinner(semanticLabel: 'running');
    }
    final color = switch (status) {
      RunStatus.passed => theme.success,
      RunStatus.failed => theme.danger,
      RunStatus.queued => theme.dim,
      RunStatus.canceled => theme.dim,
      RunStatus.running => theme.accent,
    };
    return Semantics(
      label: status.name,
      excludeSemantics: true,
      child: Text(status.glyph, style: theme.boldStyle.copyWith(color: color)),
    );
  }
}
