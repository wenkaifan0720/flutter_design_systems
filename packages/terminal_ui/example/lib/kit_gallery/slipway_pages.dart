/// slipway's screens: home, the runs, a run with its log, a new deploy and
/// the config file.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:terminal_ui/terminal_ui.dart';

import 'kit.dart';
import 'slipway.dart';

/// Two columns split in whole cells: [start] takes [share] of the cells,
/// a cell between, [end] the rest; so the second column's frame stands on
/// the grid, as a terminal's split does.
class CellColumns extends StatelessWidget {
  /// [start] and [end] side by side.
  const CellColumns({
    super.key,
    required this.start,
    required this.end,
    this.share = 0.5,
    this.fill = false,
  });

  /// Whether both columns reach the foot of the room they are given (each a
  /// [PaneColumn], tiled as a terminal's panes are); else each is as tall
  /// as its panes.
  final bool fill;

  /// The first column.
  final Widget start;

  /// The second column.
  final Widget end;

  /// The first column's part of the cells.
  final double share;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    return LayoutBuilder(
      builder: (context, c) {
        final cols = grid.colsIn(c.maxWidth);
        return Row(
          crossAxisAlignment: fill
              ? CrossAxisAlignment.stretch
              : CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: grid.cols(((cols - 1) * share).floor()),
              child: start,
            ),
            SizedBox(width: grid.cellWidth),
            Expanded(child: end),
          ],
        );
      },
    );
  }
}

/// A desk column of panes, top to bottom as [children] give them (their
/// gaps among them): the last reaches the column's foot when they leave
/// room, as a tiled terminal's panes do, so every pane on a desk ends on
/// one line; when they don't, the column scrolls.
class PaneColumn extends StatelessWidget {
  /// The column of [children].
  const PaneColumn({super.key, required this.children});

  /// The panes and the gaps between them.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) => SingleChildScrollView(
      child: _FillLast(foot: c.maxHeight, children: children),
    ),
  );
}

// Its children one under another, as wide as it is; the last one taller,
// down to [foot], where they end above it.
class _FillLast extends MultiChildRenderObjectWidget {
  const _FillLast({required this.foot, required super.children});

  final double foot;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderFillLast(foot);

  @override
  void updateRenderObject(BuildContext context, _RenderFillLast renderObject) {
    renderObject.foot = foot;
  }
}

class _FillLastData extends ContainerBoxParentData<RenderBox> {}

class _RenderFillLast extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _FillLastData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _FillLastData> {
  _RenderFillLast(this._foot);

  double _foot;
  set foot(double value) {
    if (value == _foot) return;
    _foot = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _FillLastData) child.parentData = _FillLastData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    var y = 0.0;
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _FillLastData;
      child.layout(BoxConstraints.tightFor(width: width), parentUsesSize: true);
      if (data.nextSibling == null &&
          _foot.isFinite &&
          y + child.size.height < _foot) {
        child.layout(
          BoxConstraints.tightFor(width: width, height: _foot - y),
          parentUsesSize: true,
        );
      }
      data.offset = Offset(0, y);
      y += child.size.height;
      child = data.nextSibling;
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A screen's scroll: one page margin (a cell across, a line down) round
/// [children], a line between each, at most [cols] cells wide.
class PageScroll extends StatelessWidget {
  /// A scroll of [children].
  const PageScroll({super.key, required this.children, this.cols = 96});

  /// The screen's panes.
  final List<Widget> children;

  /// The widest it reads.
  final int cols;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    // Whole lines of the screen, so its foot cuts between lines.
    return TermWholeLines(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: grid.cellWidth,
          vertical: grid.lineHeight,
        ),
        child: Align(
          alignment: AlignmentDirectional.topStart,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: grid.cols(cols)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) SizedBox(height: grid.lineHeight),
                  children[i],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A sentence as the screen's direction says it: right to left, the
/// screens speak Hebrew, as an app laid out right to left would (an English
/// sentence there ends its punctuation at the wrong side).
String _say(BuildContext context, String english, String hebrew) =>
    Directionality.of(context) == TextDirection.rtl ? hebrew : english;

String _message(Run run, bool rtl) =>
    rtl ? (slipwayHebrewMessages[run.number] ?? run.message) : run.message;

/// A run as a list row: its glyph, number and project, branch and commit
/// (none when [brief]: a narrow pane beside the run's own), and how long
/// it took. [titleCols]: where the branch or message starts.
TermListTile runTile(
  Run run, {
  bool selected = false,
  VoidCallback? onTap,
  bool showMessage = false,
  bool brief = false,
  bool rtl = false,
  int? titleCols,
}) => TermListTile(
  leading: StatusGlyph(run.status),
  title: Text('#${run.number} ${run.project}'),
  subtitle: brief
      ? null
      : Text(
          showMessage ? _message(run, rtl) : '${run.commit} · ${run.branch}',
        ),
  trailing: Text(run.status == RunStatus.running ? run.ago : run.duration),
  selected: selected,
  onTap: onTap,
  titleCols: titleCols,
);

/// The cells a list of [runs] needs for its glyphs and titles, so what
/// follows them starts in one column right after the longest.
int runTitleCols(Iterable<Run> runs) =>
    3 + runs.fold(0, (n, r) => math.max(n, '#${r.number} ${r.project}'.length));

// ---------------------------------------------------------------- home

/// The projects and how their last runs went, with what runs now.
class HomePage extends StatelessWidget {
  /// Home; [onOpenRun] opens a run.
  const HomePage({
    super.key,
    required this.projects,
    required this.runs,
    required this.onOpenRun,
    required this.wide,
  });

  /// Projects available in this session.
  final List<Project> projects;

  /// Current runs, newest first.
  final List<Run> runs;

  /// Opens run number n.
  final ValueChanged<int> onOpenRun;

  /// Whether there is room for two columns.
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final running = runs
        .where((r) => r.status == RunStatus.running)
        .firstOrNull;
    Run last(String project) => runs.firstWhere((r) => r.project == project);

    final now = TermPane(
      title: 'running now',
      trailing: running == null ? '0' : '1',
      child: running == null
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: grid.lineHeight),
              child: const Text('no runs in progress'),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: grid.lineHeight),
                Row(
                  children: [
                    const TermSpinner(semanticLabel: 'running'),
                    SizedBox(width: grid.cellWidth),
                    Expanded(
                      child: Text(
                        '#${running.number} ${running.project} · test',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: grid.cols(2)),
                  child: Text(
                    '${running.branch} · ${running.author}',
                    style: theme.dimStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(height: grid.lineHeight),
                Padding(
                  padding: EdgeInsetsDirectional.only(start: grid.cols(2)),
                  child: LayoutBuilder(
                    builder: (context, c) => TermProgressBar(
                      value: running.progress,
                      cols: (grid.colsIn(c.maxWidth) - 5).clamp(8, 40),
                      semanticLabel: 'run ${running.number}',
                    ),
                  ),
                ),
                SizedBox(height: grid.lineHeight),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TermButton(
                    label: 'watch',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyW),
                    onPressed: () => onOpenRun(running.number),
                  ),
                ),
                SizedBox(height: grid.lineHeight),
              ],
            ),
    );

    final projectPane = TermPane.list(
      title: 'projects',
      trailing: '${projects.length}',
      children: [
        for (final p in projects)
          TermListTile(
            leading: StatusGlyph(last(p.name).status),
            title: Text(p.name),
            subtitle: Text('${p.env} · #${last(p.name).number}'),
            trailing: Text(last(p.name).ago),
            onTap: () => onOpenRun(last(p.name).number),
          ),
      ],
    );

    final failing = runs.where((r) => r.status == RunStatus.failed).toList();
    final attention = TermPane.list(
      title: 'needs a look',
      trailing: '${failing.length}',
      children: [
        for (final run in failing)
          runTile(
            run,
            titleCols: runTitleCols(failing),
            onTap: () => onOpenRun(run.number),
          ),
      ],
    );

    return LayoutBuilder(
      builder: (context, c) {
        // Two columns only where each keeps its words: 90 cells and up.
        if (!wide || grid.colsIn(c.maxWidth) < 90) {
          return PageScroll(children: [now, attention, projectPane]);
        }
        // At a desk the screen has room for what ran lately, by its
        // message: a phone keeps to the three panes above.
        final recent = TermPane.list(
          title: 'recent runs',
          trailing: '${runs.length}',
          children: [
            for (final run in runs)
              runTile(
                run,
                showMessage: true,
                rtl: Directionality.of(context) == TextDirection.rtl,
                titleCols: runTitleCols(runs),
                onTap: () => onOpenRun(run.number),
              ),
          ],
        );
        // Tiled, as the desk is: each column's last pane down to the foot.
        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: grid.cellWidth,
            vertical: grid.lineHeight,
          ),
          child: Align(
            alignment: AlignmentDirectional.topStart,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: grid.cols(160)),
              child: CellColumns(
                share: 0.6,
                fill: true,
                start: PaneColumn(
                  children: [
                    projectPane,
                    SizedBox(height: grid.lineHeight),
                    recent,
                  ],
                ),
                end: PaneColumn(
                  children: [
                    now,
                    SizedBox(height: grid.lineHeight),
                    attention,
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------- runs

const _filters = ['all', 'failed', 'running', 'passed'];

List<Run> _filtered(List<Run> runs, int filter, String? branch, String query) {
  final q = query.trim().toLowerCase();
  bool found(Run r) =>
      q.isEmpty ||
      [
        '#${r.number}',
        r.project,
        r.branch,
        r.commit,
        r.message,
        r.author,
      ].any((words) => words.toLowerCase().contains(q));
  return [
    for (final r in runs)
      if ((filter == 0 ||
              (filter == 1 && r.status == RunStatus.failed) ||
              (filter == 2 && r.status == RunStatus.running) ||
              (filter == 3 && r.status == RunStatus.passed)) &&
          (branch == null || r.branch == branch) &&
          found(r))
        r,
  ];
}

/// The project a mistyped [query] most likely meant, or null.
String? _meant(String query, Iterable<String> projects) {
  final q = query.trim();
  if (q.isEmpty) return null;
  String? best;
  int? score;
  for (final name in projects) {
    final s = designMatchScore(name, q);
    if (s != null && (score == null || s > score)) {
      best = name;
      score = s;
    }
  }
  return best;
}

/// The filters over the runs: the status tabs, a search and the branch,
/// the search and the branch side by side when there is room.
class _RunFilters extends StatelessWidget {
  const _RunFilters({
    required this.filter,
    required this.branch,
    required this.query,
    required this.onFilter,
    required this.onBranch,
  });

  final int filter;
  final String? branch;
  final TextEditingController query;
  final ValueChanged<int> onFilter;
  final ValueChanged<String?> onBranch;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final search = TermTextField(
      controller: query,
      labelText: 'search',
      hintText: 'project, branch or words',
      prompt: '/',
      autocorrect: false,
      textDirection: TextDirection.ltr,
    );
    final branches = TermSelect<String>(
      labelText: 'branch',
      value: branch ?? '',
      items: [
        const TermSelectItem(value: '', label: 'every branch'),
        for (final b in slipwayBranches) TermSelectItem(value: b, label: b),
      ],
      onChanged: (v) => onBranch(v.isEmpty ? null : v),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TermTabBar(tabs: _filters, selectedIndex: filter, onTap: onFilter),
        SizedBox(height: grid.lineHeight),
        LayoutBuilder(
          builder: (context, c) => grid.colsIn(c.maxWidth) >= 64
              ? CellColumns(start: search, end: branches, share: 0.6)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    search,
                    SizedBox(height: grid.lineHeight),
                    branches,
                  ],
                ),
        ),
      ],
    );
  }
}

/// What the runs say when none is left: what to try, and the project a
/// mistyped search most likely meant.
class _NoRuns extends StatelessWidget {
  const _NoRuns({
    required this.query,
    required this.onSearch,
    required this.runs,
  });

  final List<Run> runs;

  final String query;
  final ValueChanged<String> onSearch;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final q = query.trim();
    final meant = _meant(q, runs.map((r) => r.project).toSet());
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: grid.cellWidth),
      child: q.isEmpty
          ? const TermEmptyState(
              title: 'no runs here',
              message: 'try another status or every branch',
            )
          : TermEmptyState(
              title: _say(
                context,
                'no runs match "$q"',
                // The query is isolated, so its quotes stay with it, and
                // whole: a word joiner after each hyphen, so a wrap never
                // breaks `mobile-gatway` into two lines.
                'אין ריצות שתואמות את '
                    '\u2068"${q.replaceAll('-', '-\u2060')}"\u2069',
              ),
              message: meant == null
                  ? _say(
                      context,
                      'try fewer letters, or every branch',
                      'נסו פחות אותיות, או כל הענפים',
                    )
                  : _say(
                      context,
                      'did you mean $meant?',
                      'האם התכוונת ל-$meant?',
                    ),
              action: Wrap(
                spacing: grid.cellWidth,
                runSpacing: grid.lineHeight,
                children: [
                  if (meant != null)
                    TermButton.filled(
                      label: 'search $meant',
                      shortcut: const SingleActivator(LogicalKeyboardKey.enter),
                      onPressed: () => onSearch(meant),
                    ),
                  TermButton(
                    label: 'clear search',
                    shortcut: const SingleActivator(LogicalKeyboardKey.escape),
                    onPressed: () => onSearch(''),
                  ),
                ],
              ),
            ),
    );
  }
}

/// The line over the runs while the server cannot be reached: what is
/// shown instead, and a retry that tries again (a spinner while it does).
class _Offline extends StatelessWidget {
  const _Offline({required this.retrying, required this.onRetry});

  final bool retrying;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => retrying
      ? const TermBanner(
          tone: TermTone.info,
          title: 'retrying',
          message: 'trying the server again',
          action: TermSpinner(semanticLabel: 'retrying'),
        )
      : TermBanner(
          tone: TermTone.error,
          title: 'offline',
          message: _say(
            context,
            'connection lost\u00A0· these runs are from 2 min ago',
            'החיבור אבד\u00A0· הריצות האלה מלפני 2 דקות',
          ),
          action: TermButton(
            label: 'retry',
            shortcut: const SingleActivator(
              LogicalKeyboardKey.keyR,
              control: true,
            ),
            onPressed: onRetry,
          ),
        );
}

/// The runs, filtered by status, a search and the branch; [offline], a
/// line over them says the server cannot be reached.
class RunsPage extends StatefulWidget {
  /// The runs; [onOpenRun] opens one.
  const RunsPage({
    super.key,
    required this.runs,
    required this.onOpenRun,
    this.rtl = false,
    this.query = '',
    this.offline = false,
  });

  /// Opens run number n.
  final ValueChanged<int> onOpenRun;

  /// Whether the words are the Hebrew ones.
  final bool rtl;

  /// The search it opens with.
  final String query;

  /// Whether it opens unable to reach the server.
  final bool offline;

  /// Current runs in the session.
  final List<Run> runs;

  @override
  State<RunsPage> createState() => _RunsPageState();
}

// The offline line's state, shared by the runs page and the desk's runs:
// retry waits, then says the runs are up to date.
mixin _Reconnects<T extends StatefulWidget> on State<T> {
  late bool _offline;
  bool _retrying = false;

  Future<void> _retry() async {
    setState(() => _retrying = true);
    await Future<void>.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;
    setState(() {
      _retrying = false;
      _offline = false;
    });
    TermToaster.show(
      context,
      message: 'connected · the runs are up to date',
      tone: TermTone.success,
    );
  }
}

class _RunsPageState extends State<RunsPage> with _Reconnects {
  int _filter = 0;
  String? _branch;
  late final _query = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    ),
  );

  @override
  void initState() {
    super.initState();
    _offline = widget.offline;
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runs = _filtered(widget.runs, _filter, _branch, _query.text);
    return PageScroll(
      children: [
        if (_offline) _Offline(retrying: _retrying, onRetry: _retry),
        _RunFilters(
          filter: _filter,
          branch: _branch,
          query: _query,
          onFilter: (i) => setState(() => _filter = i),
          onBranch: (b) => setState(() => _branch = b),
        ),
        TermPane.list(
          title: 'runs',
          trailing: '${runs.length}',
          footer: runs.isEmpty || !termKeysShown(context) ? null : '⏎ open',
          children: [
            for (final run in runs)
              runTile(
                run,
                titleCols: runTitleCols(runs),
                onTap: () => widget.onOpenRun(run.number),
              ),
            if (runs.isEmpty)
              _NoRuns(
                runs: widget.runs,
                query: _query.text,
                onSearch: (q) => _query.text = q,
              ),
          ],
        ),
      ],
    );
  }
}

/// A desk's runs: the list, the run and its log side by side, each a pane.
class RunsTiled extends StatefulWidget {
  /// The tiled panes, [selected] open.
  const RunsTiled({
    super.key,
    required this.onCancel,
    required this.onRerun,
    required this.runs,
    required this.selected,
    required this.onSelect,
    this.rtl = false,
    this.paneFocus,
    this.pane,
    this.onDiff,
    this.logQuery = '',
    this.query = '',
    this.offline = false,
  });

  /// Stops an active run and updates the session's history.
  final ValueChanged<Run> onCancel;

  /// Queues another run from this source.
  final ValueChanged<Run> onRerun;

  /// The pane with the keyboard (0 the runs, 1 the run, 2 its log), drawn
  /// in double lines with its chosen row bright; null: none.
  final int? pane;

  /// The log's search it opens with.
  final String logQuery;

  /// The runs' search it opens with.
  final String query;

  /// Whether it opens unable to reach the server.
  final bool offline;

  /// The focus round pane i (0 the runs, 1 the run, 2 its log), for the
  /// desk's switcher; null: none.
  final FocusNode Function(int i)? paneFocus;

  /// Opens the run's change; null: no such key.
  final VoidCallback? onDiff;

  /// The run open in the detail and log panes.
  final int selected;

  /// Opens run number n.
  final ValueChanged<int> onSelect;

  /// Whether the words are the Hebrew ones.
  final bool rtl;

  /// Current runs in the session.
  final List<Run> runs;

  @override
  State<RunsTiled> createState() => _RunsTiledState();
}

class _RunsTiledState extends State<RunsTiled> with _Reconnects {
  int _filter = 0;
  String? _branch;
  late final _query = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    ),
  );

  @override
  void initState() {
    super.initState();
    _offline = widget.offline;
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  // Whether pane i is drawn as the one with the keyboard: true for the
  // switcher's current pane, else as focus says.
  bool? _on(int i) => widget.pane == i ? true : null;

  // Pane i inside the switcher's focus, when there is a switcher.
  Widget _pane(int i, Widget child) {
    final node = widget.paneFocus?.call(i);
    return node == null
        ? child
        : Focus(focusNode: node, skipTraversal: true, child: child);
  }

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final runs = _filtered(widget.runs, _filter, _branch, _query.text);
    final run = widget.runs.firstWhere((r) => r.number == widget.selected);
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: grid.cellWidth,
        vertical: grid.lineHeight,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            // The status tabs' whole row: 1 all … 4 passed.
            width: grid.cols(42),
            child: _pane(
              0,
              PaneColumn(
                children: [
                  if (_offline) ...[
                    _Offline(retrying: _retrying, onRetry: _retry),
                    SizedBox(height: grid.lineHeight),
                  ],
                  _RunFilters(
                    filter: _filter,
                    branch: _branch,
                    query: _query,
                    onFilter: (i) => setState(() => _filter = i),
                    onBranch: (b) => setState(() => _branch = b),
                  ),
                  SizedBox(height: grid.lineHeight),
                  TermPane.list(
                    title: 'runs',
                    trailing: '${runs.length}',
                    focused: _on(0),
                    children: [
                      for (final r in runs)
                        runTile(
                          r,
                          brief: true,
                          selected: r.number == widget.selected,
                          onTap: () => widget.onSelect(r.number),
                        ),
                      if (runs.isEmpty)
                        _NoRuns(
                          runs: widget.runs,
                          query: _query.text,
                          onSearch: (q) => _query.text = q,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: grid.cellWidth),
          SizedBox(
            width: grid.cols(38),
            child: _pane(
              1,
              RunSummary(
                run: run,
                onCancel: widget.onCancel,
                onRerun: widget.onRerun,
                rtl: widget.rtl,
                onDiff: widget.onDiff,
                focused: _on(1),
                fill: true,
              ),
            ),
          ),
          SizedBox(width: grid.cellWidth),
          Expanded(
            child: _pane(
              2,
              LogPane(run: run, query: widget.logQuery, focused: _on(2)),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- one run

/// A run's head (its number, branch, commit, who and how long) and its
/// steps.
class RunSummary extends StatelessWidget {
  /// The summary of [run].
  const RunSummary({
    super.key,
    required this.onCancel,
    required this.onRerun,
    required this.run,
    this.rtl = false,
    this.onDiff,
    this.focused,
    this.fill = false,
  });

  /// Stops an active run and updates the session's history.
  final ValueChanged<Run> onCancel;

  /// Queues another run from this source.
  final ValueChanged<Run> onRerun;

  /// Whether it is a desk column: its steps reach the column's foot and the
  /// column scrolls on its own ([PaneColumn]); else as tall as it is.
  final bool fill;

  /// Whether its summary is drawn as the desk's active pane; null: while
  /// the keyboard is in it. Its steps stay in single lines: one pane on the
  /// screen is the active one.
  final bool? focused;

  /// The run.
  final Run run;

  /// Opens the run's change; null: no such button.
  final VoidCallback? onDiff;

  /// Whether the words are the Hebrew ones.
  final bool rtl;

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final theme = TermTheme.of(context);
    final steps = slipwayStepsOf(run);
    final panes = [
      TermPane(
        title: '#${run.number} ${run.project}',
        trailing: run.status.name,
        // How the run stands, in its tone at a glance.
        trailingColor: switch (run.status) {
          RunStatus.failed => theme.danger,
          RunStatus.running => theme.accent,
          RunStatus.passed => theme.success,
          _ => null,
        },
        focused: focused,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: grid.lineHeight),
            TermDescriptionList(
              items: [
                ('branch', run.branch),
                ('commit', '${run.commit} ${_message(run, rtl)}'),
                ('by', '${run.author} · ${run.trigger} · ${run.ago}'),
                (
                  run.status == RunStatus.running ? 'so far' : 'took',
                  run.duration,
                ),
              ],
            ),
            SizedBox(height: grid.lineHeight),
            Wrap(
              alignment: WrapAlignment.end,
              spacing: grid.cellWidth,
              runSpacing: grid.lineHeight,
              children: [
                if (onDiff != null)
                  TermButton(
                    label: 'the change',
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyD),
                    onPressed: onDiff,
                  ),
                TermButton(
                  label: 'rerun',
                  shortcut: const SingleActivator(LogicalKeyboardKey.keyR),
                  onPressed: () => onRerun(run),
                ),
                if (run.status == RunStatus.running)
                  TermButton(
                    label: 'cancel',
                    isDestructiveAction: true,
                    shortcut: const SingleActivator(LogicalKeyboardKey.keyC),
                    onPressed: () => onCancel(run),
                  ),
              ],
            ),
            SizedBox(height: grid.lineHeight),
          ],
        ),
      ),
      SizedBox(height: grid.lineHeight),
      TermPane.list(
        title: 'steps',
        trailing: '${steps.length}',
        focused: focused == null ? null : false,
        children: [
          for (final s in steps)
            TermListTile(
              leading: StatusGlyph(s.status),
              title: Text(s.name),
              trailing: Text(s.duration),
              selected: s.name == 'test',
              onTap: () {},
            ),
        ],
      ),
    ];
    return fill
        ? PaneColumn(children: panes)
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: panes,
          );
  }
}

/// A run's log: the test step's lines, numbered, with a search that marks
/// each match in inverse video.
class LogPane extends StatefulWidget {
  /// The log of [run].
  const LogPane({
    super.key,
    required this.run,
    this.expand = true,
    this.query = '',
    this.focused,
  });

  /// Whether it is drawn as the desk's active pane; null: while the
  /// keyboard is in it.
  final bool? focused;

  /// The search it opens with.
  final String query;

  /// The run.
  final Run run;

  /// Whether the pane fills its height (a desk's tile) or takes its lines.
  final bool expand;

  @override
  State<LogPane> createState() => _LogPaneState();
}

class _LogPaneState extends State<LogPane> {
  late final _query = TextEditingController.fromValue(
    TextEditingValue(
      text: widget.query,
      selection: TextSelection.collapsed(offset: widget.query.length),
    ),
  );

  @override
  void initState() {
    super.initState();
    _query.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final q = _query.text;
    final log = slipwayLogOf(widget.run);
    var matches = 0;
    if (q.isNotEmpty) {
      for (final line in log) {
        matches += q.allMatches(line).length;
      }
    }
    Color? ink(String line) {
      final t = line.trimLeft();
      if (t.startsWith('✗') ||
          t.startsWith('error') ||
          t.contains('AssertionError')) {
        return theme.danger;
      }
      if (t.startsWith('✓')) {
        return theme.success;
      }
      if (t.startsWith(r'$')) {
        return theme.accent;
      }
      return null;
    }

    // The part of [line] from [start] to [end], the query's matches in
    // inverse video.
    TextSpan spans(String line, int start, int end) {
      final base = TextStyle(color: ink(line));
      final hit = TextStyle(
        color: theme.background,
        backgroundColor: theme.foreground,
      );
      final parts = <TextSpan>[];
      var at = start;
      if (q.isNotEmpty) {
        for (final m in q.allMatches(line)) {
          final a = math.max(m.start, start);
          final b = math.min(m.end, end);
          if (a >= b) continue;
          if (a > at) {
            parts.add(TextSpan(text: line.substring(at, a), style: base));
          }
          parts.add(TextSpan(text: line.substring(a, b), style: hit));
          at = b;
        }
      }
      if (at < end) {
        parts.add(TextSpan(text: line.substring(at, end), style: base));
      }
      return TextSpan(children: parts);
    }

    // A log is a program's output: it runs left to right, its numbers at
    // the left, in a right-to-left app too. A line longer than the pane
    // wraps on the grid, its rows after the first hung in, so the numbers
    // still mark where each line starts. In a narrow pane (a phone at a
    // large text size) the gutter and the hang shrink to a cell each, so a
    // row keeps room for a path.
    final lines = Directionality(
      textDirection: TextDirection.ltr,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cols = grid.colsIn(constraints.maxWidth);
          final narrow = cols < 28;
          final numberCols = narrow ? 2 : 3;
          final gapCols = narrow ? 1 : 2;
          final hangCols = narrow ? 1 : 2;
          final textCols = math.max(cols - numberCols - gapCols, hangCols + 8);
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < log.length; i++)
                MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (row, (start, end)) in logRows(
                        grid,
                        log[i],
                        textCols,
                        textCols - hangCols,
                      ).indexed)
                        SizedBox(
                          height: grid.lineHeight,
                          child: Row(
                            children: [
                              SizedBox(
                                width: grid.cols(numberCols),
                                child: row > 0
                                    ? null
                                    : ExcludeSemantics(
                                        child: Text(
                                          '${i + 1}',
                                          textAlign: TextAlign.end,
                                          style: theme.dimStyle,
                                        ),
                                      ),
                              ),
                              SizedBox(
                                width: grid.cols(
                                  gapCols + (row > 0 ? hangCols : 0),
                                ),
                              ),
                              Flexible(
                                child: Text.rich(
                                  spans(log[i], start, end),
                                  softWrap: false,
                                  maxLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              // A running step's next line, still coming.
              if (widget.run.status == RunStatus.running)
                SizedBox(
                  height: grid.lineHeight,
                  child: Row(
                    children: [
                      SizedBox(width: grid.cols(numberCols + gapCols + 1)),
                      const TermSpinner(semanticLabel: 'running'),
                      Text(' src/auth/token.test.ts', style: theme.dimStyle),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );

    return TermPane(
      title: 'log · test',
      trailing: q.isEmpty ? '${log.length} lines' : '$matches found',
      focused: widget.focused,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: grid.lineHeight),
          TermTextField(
            controller: _query,
            labelText: 'search',
            hintText: 'expect',
            prompt: '/',
            autocorrect: false,
            textDirection: TextDirection.ltr,
          ),
          SizedBox(height: grid.lineHeight),
          // Filling its column, the lines run to the frame (whole lines,
          // the part of one left blank): no blank line after them to read
          // as the log's end.
          if (widget.expand)
            Expanded(
              child: TermWholeLines(child: SingleChildScrollView(child: lines)),
            )
          else ...[
            lines,
            SizedBox(height: grid.lineHeight),
          ],
        ],
      ),
    );
  }
}

/// [line] cut into rows on the cell grid: the first at most [first] cells
/// wide, the rest at most [rest], each ending after its last space past the
/// row's indent or its last `/`, whichever is later, so a word stays whole
/// and a path keeps its parts (`· /work/` then `atlas-api`); a token longer
/// than a row with neither is cut mid-word, as a terminal wraps. Each row is
/// its start and end in [line].
List<(int, int)> logRows(TermGrid grid, String line, int first, int rest) {
  final rows = <(int, int)>[];
  var start = 0;
  var width = first;
  while (start < line.length) {
    var cells = 0;
    var end = start;
    var space = -1;
    var slash = -1;
    var indent = start;
    while (indent < line.length && line.codeUnitAt(indent) == 0x20) {
      indent++;
    }
    while (end < line.length) {
      final unit = line.codeUnitAt(end);
      final size = unit >= 0xD800 && unit <= 0xDBFF && end + 1 < line.length
          ? 2
          : 1;
      final w = (grid.widthOf(line.substring(end, end + size)) / grid.cellWidth)
          .round();
      if (cells + w > width) break;
      cells += w;
      if (unit == 0x20) space = end;
      if (unit == 0x2F) slash = end;
      end += size;
    }
    // The later of the last space and the last slash, so a path after a
    // separator (`· /work/`) keeps its first part with it.
    final at = math.max(
      space > indent ? space : -1,
      slash > indent ? slash : -1,
    );
    if (end < line.length && at >= 0) end = at + 1;
    if (end == start) end = start + 1;
    rows.add((start, end));
    start = end;
    width = rest;
  }
  return rows.isEmpty ? const [(0, 0)] : rows;
}

/// A run on a phone or a tablet: its summary, then its log.
class RunDetailPage extends StatelessWidget {
  /// The page of [run].
  const RunDetailPage({
    super.key,
    required this.onCancel,
    required this.onRerun,
    required this.run,
    this.rtl = false,
    this.onDiff,
  });

  /// Stops an active run and updates the session's history.
  final ValueChanged<Run> onCancel;

  /// Queues another run from this source.
  final ValueChanged<Run> onRerun;

  /// The run.
  final Run run;

  /// Opens the run's change.
  final VoidCallback? onDiff;

  /// Whether the words are the Hebrew ones.
  final bool rtl;

  @override
  Widget build(BuildContext context) => PageScroll(
    children: [
      RunSummary(
        run: run,
        rtl: rtl,
        onDiff: onDiff,
        onCancel: onCancel,
        onRerun: onRerun,
      ),
      LogPane(run: run, expand: false),
    ],
  );
}

// ---------------------------------------------------------------- deploy

/// The new-deploy form: what, where, how, and a y/N before production.
class DeployPage extends StatefulWidget {
  /// The form.
  const DeployPage({
    super.key,
    required this.projects,
    required this.initialBranch,
    required this.initialEnvironment,
    required this.onCancel,
    required this.onDeploy,
  });

  /// Available deployment targets.
  final List<Project> projects;

  /// The most recent branch for the initial project.
  final String initialBranch;

  /// Target chosen by the command that opened this form.
  final String initialEnvironment;

  /// Discards the draft and returns to its origin.
  final VoidCallback onCancel;

  /// Queues a deployment after validation and any production confirmation.
  final void Function(String project, String branch, String environment)
  onDeploy;

  @override
  State<DeployPage> createState() => _DeployPageState();
}

class _DeployPageState extends State<DeployPage> {
  late String _project = widget.projects.first.name;
  late String _env = widget.initialEnvironment;
  final _branchFocus = FocusNode();
  bool _missingBranch = false;
  late final _branch = TextEditingController(text: widget.initialBranch);
  String _strategy = 'rolling';
  bool _migrate = true;
  bool _notify = true;
  bool _skipCache = false;

  @override
  void dispose() {
    _branchFocus.dispose();
    _branch.dispose();
    super.dispose();
  }

  Future<void> _deploy() async {
    final branch = _branch.text.trim();
    if (branch.isEmpty) {
      setState(() => _missingBranch = true);
      _branchFocus.requestFocus();
      return;
    }
    final target = '$_project $branch → $_env';
    if (_env == 'production') {
      final yes = await showTermConfirmDialog(
        context: context,
        title: 'deploy to production',
        message: '$target, $_strategy. people use this one.',
        confirmLabel: 'deploy',
      );
      if (yes != true || !mounted) return;
    }
    widget.onDeploy(_project, branch, _env);
  }

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final wide = MediaQuery.sizeOf(context).width >= 1200;
    // Under touch (a phone) the main action is pinned at the foot, in the
    // thumb's reach, not one scroll below the form.
    final pinned = !wide && !termKeysShown(context);
    Widget gap() => SizedBox(height: grid.lineHeight);
    final actions = Wrap(
      alignment: WrapAlignment.end,
      spacing: grid.cellWidth,
      runSpacing: grid.lineHeight,
      children: [
        TermButton(
          label: 'cancel',
          shortcut: const SingleActivator(LogicalKeyboardKey.escape),
          onPressed: widget.onCancel,
        ),
        TermButton.filled(
          label: 'deploy',
          shortcut: const SingleActivator(LogicalKeyboardKey.enter),
          onPressed: _deploy,
        ),
      ],
    );
    final form = TermPane(
      title: 'new deploy',
      footer: termKeysShown(context) ? '⏎ deploy · esc cancel' : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          gap(),
          TermSelect<String>(
            labelText: 'project',
            value: _project,
            items: [
              for (final p in widget.projects)
                TermSelectItem(value: p.name, label: p.name, detail: p.env),
            ],
            onChanged: (v) => setState(() => _project = v),
          ),
          gap(),
          TermSelect<String>(
            labelText: 'environment',
            value: _env,
            helperText: _env == 'production' ? 'asks y/N before it goes' : null,
            items: const [
              TermSelectItem(value: 'preview', label: 'preview'),
              TermSelectItem(value: 'staging', label: 'staging'),
              TermSelectItem(value: 'production', label: 'production'),
            ],
            onChanged: (v) => setState(() => _env = v),
          ),
          gap(),
          TermTextField(
            controller: _branch,
            labelText: 'branch',
            focusNode: _branchFocus,
            errorText: _missingBranch ? 'enter a branch or commit' : null,
            onChanged: (value) {
              if (_missingBranch && value.trim().isNotEmpty) {
                setState(() => _missingBranch = false);
              }
            },
            prompt: '\u{E0A0}',
            helperText: 'a branch or a commit',
            autocorrect: false,
            textDirection: TextDirection.ltr,
            onSubmitted: (_) => _deploy(),
          ),
          gap(),
          const TermSectionHeader(title: 'strategy'),
          RadioGroup<String>(
            groupValue: _strategy,
            onChanged: (v) => setState(() => _strategy = v!),
            child: RadioGroupKeyboardFix<String>(
              child: Semantics(
                label: 'strategy',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final s in const ['rolling', 'blue-green', 'canary'])
                      TermRadio<String>(value: s, label: s),
                  ],
                ),
              ),
            ),
          ),
          gap(),
          const TermSectionHeader(title: 'options'),
          // A form's options are boxes, ticked now and taken on deploy;
          // a switch acts at once (the config's).
          TermCheckbox(
            value: _migrate,
            label: 'run migrations first',
            onChanged: (v) => setState(() => _migrate = v!),
          ),
          TermCheckbox(
            value: _notify,
            label: 'notify me when it lands',
            onChanged: (v) => setState(() => _notify = v!),
          ),
          TermCheckbox(
            value: _skipCache,
            label: 'build without the cache',
            onChanged: (v) => setState(() => _skipCache = v!),
          ),
          gap(),
          if (!pinned) ...[actions, gap()],
        ],
      ),
    );
    if (pinned) {
      // A terminal program's bottom lines hold its keys; a phone's hold its
      // main action, under a rule, on whole lines (the rule's, half a line
      // round the button), so the form above still ends between rows. The
      // way out is the window list; at 200% two buttons would wrap.
      return Column(
        children: [
          Expanded(child: PageScroll(cols: 64, children: [form])),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: grid.cellWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TermDivider(),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: grid.lineHeight / 2),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TermButton.filled(
                      label: 'deploy',
                      onPressed: _deploy,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
    if (!wide) return PageScroll(cols: 64, children: [form]);
    return PageScroll(
      cols: 160,
      children: [
        CellColumns(
          share: 0.6,
          start: form,
          end: _Plan(env: _env, strategy: _strategy, migrate: _migrate),
        ),
      ],
    );
  }
}

class _Plan extends StatelessWidget {
  const _Plan({
    required this.env,
    required this.strategy,
    required this.migrate,
  });

  final String env;
  final String strategy;
  final bool migrate;

  @override
  Widget build(BuildContext context) {
    final theme = TermTheme.of(context);
    final grid = context.termGrid;
    final steps = [
      'build the image',
      if (migrate) 'run the migrations',
      switch (strategy) {
        'blue-green' => 'start green beside blue',
        'canary' => 'send 5% to the new version',
        _ => 'replace the pods two at a time',
      },
      if (env == 'production') 'wait for your y',
      'switch the traffic',
    ];
    return TermPane(
      title: 'plan',
      trailing: '${steps.length} steps',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(height: grid.lineHeight),
          for (var i = 0; i < steps.length; i++)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: grid.cols(3),
                  child: Text('${i + 1}.', style: theme.dimStyle),
                ),
                Expanded(child: Text(steps[i])),
              ],
            ),
          SizedBox(height: grid.lineHeight),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- config

final _duration = RegExp(r'^\d+(s|m|h)$');

/// The settings, written as the config file they are: keys and values in
/// sections, each value checked as it is typed.
class SettingsPage extends StatefulWidget {
  /// The config file.
  const SettingsPage({
    super.key,
    required this.project,
    required this.runCount,
    required this.onDelete,
    this.askToDelete = false,
  });

  /// Project whose settings are open.
  final Project project;

  /// Archived and current runs belonging to this project.
  final int runCount;

  /// Removes the project and its runs after confirmation.
  final ValueChanged<Project> onDelete;

  /// Whether it opens asking to delete the project (the typed guard).
  final bool askToDelete;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final _name = TextEditingController(text: widget.project.name);
  final _timeout = TextEditingController(text: '30 min');
  String _env = 'staging';
  bool _autoMerge = true;
  bool _review = true;
  bool _onFailure = true;
  bool _onSuccess = false;
  String _channel = 'email';
  // It opens mid-edit: the timeout typed as a person would, which the file
  // does not take, so nothing is saved yet.
  bool _edited = true;

  @override
  void initState() {
    super.initState();
    for (final c in [_name, _timeout]) {
      c.addListener(() => setState(() => _edited = true));
    }
    if (widget.askToDelete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _delete();
      });
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _timeout.dispose();
    super.dispose();
  }

  void _set(VoidCallback change) => setState(() {
    change();
    _edited = true;
  });

  Future<void> _delete() async {
    final name = widget.project.name;
    final count = widget.runCount;
    final yes = await showTermConfirmDialog(
      context: context,
      title: 'delete project',
      message: _say(
        context,
        '$name, its $count runs and their logs go for good.',
        'הפרויקט $name יימחק לתמיד, עם $count הריצות שלו והיומנים שלהן.',
      ),
      confirmLabel: 'delete',
      isDestructiveAction: true,
      typedConfirmation: name,
    );
    if (yes == true && mounted) widget.onDelete(widget.project);
  }

  /// The keys' width: the longest, `require_review`, and a space.
  static const _keyCols = 15;

  /// A key and its control on one config line, the key first, as the file
  /// writes it; where the line has no room, the control with the key after
  /// it, as a form writes it. [word] is the value as the file would hold
  /// it, dim after the control.
  Widget _line(
    String key,
    Widget Function(String? label) control, {
    String? word,
  }) => LayoutBuilder(
    builder: (context, c) {
      final theme = TermTheme.of(context);
      final grid = context.termGrid;
      if (grid.colsIn(c.maxWidth) - _keyCols < 16) return control(key);
      return Row(
        children: [
          SizedBox(
            width: grid.cols(_keyCols),
            child: ExcludeSemantics(child: Text(key)),
          ),
          control(null),
          if (word != null) ...[
            SizedBox(width: grid.cellWidth),
            ExcludeSemantics(child: Text(word, style: theme.dimStyle)),
          ],
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) {
    final grid = context.termGrid;
    final timeoutOk = _duration.hasMatch(_timeout.text.trim());
    Widget gap() => SizedBox(height: grid.lineHeight);
    final save = _edited && timeoutOk
        ? () => setState(() => _edited = false)
        : null;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () =>
            save?.call(),
      },
      child: PageScroll(
        cols: 72,
        children: [
          TermPane(
            title: '~/.slipway/config',
            trailing: _edited ? 'edited' : 'saved',
            footer: termKeysShown(context) ? '^S save' : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                gap(),
                const TermSectionHeader(title: '[project]'),
                // A config value is code: it runs left to right in any
                // language, as a path does.
                TermTextField.inline(
                  controller: _name,
                  labelText: 'name',
                  labelCols: _keyCols - 1,
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                ),
                TermSelect<String>.inline(
                  labelText: 'default_env',
                  labelCols: _keyCols - 1,
                  value: _env,
                  items: const [
                    TermSelectItem(value: 'preview', label: 'preview'),
                    TermSelectItem(value: 'staging', label: 'staging'),
                    TermSelectItem(value: 'production', label: 'production'),
                  ],
                  onChanged: (v) => _set(() => _env = v),
                ),
                gap(),
                const TermSectionHeader(title: '[deploy]'),
                TermTextField.inline(
                  controller: _timeout,
                  labelText: 'timeout',
                  labelCols: _keyCols - 1,
                  hintText: '30m',
                  helperText: 'how long a step may run',
                  errorText: timeoutOk
                      ? null
                      : 'a number and s, m or h: 90s, 30m, 2h',
                  autocorrect: false,
                  textDirection: TextDirection.ltr,
                ),
                _line(
                  'auto_merge',
                  word: '$_autoMerge',
                  (label) => TermSwitch(
                    value: _autoMerge,
                    label: label,
                    semanticLabel: 'auto_merge',
                    onChanged: (v) => _set(() => _autoMerge = v),
                  ),
                ),
                _line(
                  'require_review',
                  word: '$_review',
                  (label) => TermSwitch(
                    value: _review,
                    label: label,
                    semanticLabel: 'require_review',
                    onChanged: (v) => _set(() => _review = v),
                  ),
                ),
                gap(),
                const TermSectionHeader(title: '[notify]'),
                _line(
                  'on_failure',
                  (label) => TermCheckbox(
                    value: _onFailure,
                    label: label,
                    semanticLabel: 'on_failure',
                    onChanged: (v) => _set(() => _onFailure = v!),
                  ),
                ),
                _line(
                  'on_success',
                  (label) => TermCheckbox(
                    value: _onSuccess,
                    label: label,
                    semanticLabel: 'on_success',
                    onChanged: (v) => _set(() => _onSuccess = v!),
                  ),
                ),
                Semantics(
                  container: true,
                  label: 'via',
                  explicitChildNodes: true,
                  child: LayoutBuilder(
                    builder: (context, c) {
                      final radios = RadioGroup<String>(
                        groupValue: _channel,
                        onChanged: (v) => _set(() => _channel = v!),
                        child: RadioGroupKeyboardFix<String>(
                          child: Wrap(
                            spacing: grid.cols(2),
                            children: [
                              for (final c in const ['email', 'webhook'])
                                TermRadio<String>(value: c, label: c),
                            ],
                          ),
                        ),
                      );
                      const key = ExcludeSemantics(child: Text('via'));
                      // The key above its choices where they have no room.
                      if (grid.colsIn(c.maxWidth) - _keyCols < 16) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [key, radios],
                        );
                      }
                      return Row(
                        children: [
                          SizedBox(width: grid.cols(_keyCols), child: key),
                          Expanded(child: radios),
                        ],
                      );
                    },
                  ),
                ),
                gap(),
                Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: TermButton.filled(
                    label: 'save',
                    shortcut: const SingleActivator(
                      LogicalKeyboardKey.keyS,
                      control: true,
                    ),
                    onPressed: save,
                  ),
                ),
                gap(),
              ],
            ),
          ),
          // What cannot be undone stays out of the file, in a pane of its
          // own, away from save.
          TermPane(
            title: 'danger',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                gap(),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: grid.cellWidth,
                  runSpacing: grid.lineHeight,
                  children: [
                    Text(
                      _say(
                        context,
                        'deletes the project, its runs and their logs',
                        'מוחק את הפרויקט, את הריצות שלו ואת היומנים שלהן',
                      ),
                      style: TermTheme.of(context).dimStyle,
                    ),
                    TermButton(
                      label: 'delete project',
                      isDestructiveAction: true,
                      onPressed: _delete,
                    ),
                  ],
                ),
                gap(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
