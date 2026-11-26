part of '../stint_terminal.dart';

/// The timer's keys: Alt+T stops the running timer or starts one, Alt+W
/// switches its task, from any window.
const _timerKey = SingleActivator(LogicalKeyboardKey.keyT, alt: true);
const _switchKey = SingleActivator(LogicalKeyboardKey.keyW, alt: true);

/// Today as a console's home screen: box-drawn panes tiled on the character
/// grid, the running timer's pane across the top split on the same column
/// line as the panes under it, the plan as a checklist, the day's blocks and
/// the team's events as logs, and the next work as a list to open.
extension _ConsoleToday on _ConsoleState {
  List<Task> get _choices => [
    for (final item in c.openTasks)
      if (item.id != c.data.timer?.taskId) item,
  ];

  /// The mark between two words of a line: the middle dot, but in Arabic
  /// its comma, as the dot would read as the Arabic zero (٠).
  String get _dot => w.arabic ? '، ' : ' · ';

  /// The mark of a way on, pointing the way the line reads.
  String get _more => w.arabic ? '‹' : '›';

  bool get _tracking => c.data.timer != null && c.currentTask('maya') != null;

  Future<void> _pick() async {
    if (!c.signedIn || asking || _choices.isEmpty) return;
    await showTermCommandPalette(
      context: context,
      title: _tracking ? w.switchTask : w.startTimer,
      hintText: w.search,
      emptyText: w.noMatches,
      commands: [
        for (final item in _choices)
          RawCommand(
            label: w.text(item.title),
            group: c.projectName(item.project),
            onPressed: () => c.track(item.id),
          ),
      ],
    );
  }

  /// Alt+T: stop what runs, or choose what to start.
  void timerKey() {
    if (!c.signedIn || asking) return;
    _tracking ? c.stopTimer() : _pick();
  }

  /// The keys are written beside what they work from a tablet's width;
  /// a phone has none to press, as its status line shows none.
  bool get _keyed => MediaQuery.sizeOf(context).width >= 600;

  /// Alt+W: switch the running timer's task.
  void switchKey() {
    if (_tracking) _pick();
  }

  Widget home() => _Page(
    children: [
      // On the panes' keyline: two cells in, where their titles stand.
      Builder(
        builder: (ctx) => Padding(
          padding: EdgeInsetsDirectional.only(start: ctx.termGrid.cols(2)),
          child: _Heading(
            w.greeting,
            caption: '${w.weekday(studyToday)}$_dot${w.shortDate(studyToday)}',
          ),
        ),
      ),
      content(
        () => LayoutBuilder(
          builder: (ctx, box) {
            final grid = ctx.termGrid;
            final split = box.maxWidth >= grid.cols(75);
            // One line of air between panes down, two cells across: the
            // half line and half cell each frame keeps outside its rule
            // make both about one line, so the gutters read even.
            final gap = grid.cols(2);
            Widget stack(List<Widget> panes) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: panes,
            );
            final plan = _plan(), blocks = _blocks(), later = _later();
            final week = _week(), people = _people(), feed = _feed();
            return stack([
              _timer(split: split, gap: gap, page: box.maxWidth),
              if (split)
                _Columns(
                  gap: gap,
                  textDirection: Directionality.of(ctx),
                  children: [plan, later, people, week, blocks, feed],
                )
              else ...[
                week,
                plan,
                blocks,
                later,
                people,
                feed,
              ],
            ]);
          },
        ),
      ),
    ],
  );

  Widget _timer({
    required bool split,
    required double gap,
    required double page,
  }) {
    final grid = context.termGrid;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = _choices;
    // The tracked task's lines settle in a terminal's very short fade.
    Widget fade(Widget child) => AnimatedSwitcher(
      duration: rawReduceMotionOf(context) ? Duration.zero : TermMotion.screen,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      child: child,
    );
    // The task's lines: its lamp and name, its project, the hour it began.
    final about = KeyedSubtree(
      key: const ValueKey('today-timer-title'),
      child: fade(
        Column(
          key: ValueKey(task?.id),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? '● ' : '○ ',
                  style: ink.boldStyle.copyWith(
                    color: active ? ink.success : ink.dim,
                  ),
                ),
                Flexible(
                  child: Text(
                    active ? w.text(task.title) : w.chooseTask,
                    textWidthBasis: TextWidthBasis.longestLine,
                    style: ink.boldStyle,
                  ),
                ),
              ],
            ),
            Text(
              active
                  ? c.projectName(task.project)
                  : choices.isEmpty
                  ? w.noTimerTasks
                  : w.notTracking,
              textWidthBasis: TextWidthBasis.longestLine,
              style: ink.dimStyle,
            ),
            if (timer != null) Text(w.since(timer.start), style: ink.dimStyle),
          ],
        ),
      ),
    );
    Widget reading(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        label: w.elapsedLabel(value),
        excludeSemantics: true,
        child: Text(
          value,
          textDirection: TextDirection.ltr,
          maxLines: 1,
          style: ink.displayStyle.copyWith(
            color: active ? ink.foreground : ink.dim,
          ),
        ),
      );
    }

    final figure = KeyedSubtree(
      key: const ValueKey('today-timer-digits'),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: timer == null
            ? reading(c.repository.now())
            : StreamBuilder<DateTime>(
                stream: c.ticks(const Duration(seconds: 1)),
                initialData: c.repository.now(),
                builder: (_, now) => reading(now.data!),
              ),
      ),
    );
    Widget keys({required bool named}) => Wrap(
      spacing: grid.cellWidth,
      children: [
        if (active)
          TermButton.filled(
            key: const ValueKey('today-action-first'),
            label: w.stopTimer,
            shortcut: named ? _timerKey : null,
            onPressed: c.stopTimer,
          ),
        if (active)
          TermButton(
            key: const ValueKey('today-action-last'),
            label: w.switchTask,
            shortcut: named ? _switchKey : null,
            onPressed: choices.isEmpty ? null : _pick,
          )
        else
          TermButton.filled(
            key: const ValueKey('today-action-first'),
            label: w.startTimer,
            shortcut: named ? _timerKey : null,
            onPressed: choices.isEmpty ? null : _pick,
          ),
      ],
    );
    return _pane(
      key: const ValueKey('today-timer-card'),
      title: active ? w.runningTimer : w.stoppedTimer,
      trailing: active ? task.id : null,
      child: !split
          // A phone's column: the task's lines, the clock, its keys.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                about,
                figure,
                keys(named: _keyed),
              ],
            )
          // A strip: the task's lines, the clock and its keys on one centre
          // line. The clock stands on the second column's keyline, over the
          // week's first reading, while it and its keys fit there; on a
          // tablet it follows the task's words two cells on.
          : LayoutBuilder(
              builder: (ctx, inner) {
                double measure(String words, TextStyle style) =>
                    TextPainter.computeWidth(
                      text: TextSpan(text: words, style: style),
                      textDirection: Directionality.of(ctx),
                      textScaler: MediaQuery.textScalerOf(ctx),
                    );
                // The week's first reading inks from its cell's edge, half
                // a cell before where a frame's line would stand.
                final keyline = (page + gap - grid.cellWidth) / 2;
                final clock = measure('00:00:00', ink.displayStyle);
                // A key's face: its words, its brackets and the cells
                // inside them; written keys add a cell and their chord.
                double face(String label, {required bool filled}) =>
                    measure(label, ink.textStyle) + grid.cols(filled ? 2 : 4);
                final faces = active
                    ? face(w.stopTimer, filled: true) +
                          face(w.switchTask, filled: false) +
                          grid.cellWidth
                    : face(w.startTimer, filled: true);
                final chords = active
                    ? measure(
                            ' ${termKeyLabel(_timerKey)} '
                            '${termKeyLabel(_switchKey)}',
                            ink.textStyle,
                          ) +
                          grid.cellWidth
                    : measure(' ${termKeyLabel(_timerKey)}', ink.textStyle);
                final room = inner.maxWidth - keyline - clock - grid.cols(2);
                final named = _keyed && faces + chords <= room;
                final direction = Directionality.of(ctx);
                return _Strip(
                  keyline: keyline,
                  gap: grid.cols(2),
                  air: grid.cols(2),
                  textDirection: direction,
                  words: about,
                  clock: Transform.translate(
                    offset: _TodayInk.digits(direction),
                    child: figure,
                  ),
                  keys: Transform.translate(
                    offset: _TodayInk.controls(direction),
                    child: keys(named: named),
                  ),
                );
              },
            ),
    );
  }

  /// A pane whose words on its border (a count, a length, an id) stay on
  /// the border while they fit it, and otherwise lead its first line, so
  /// they are never pushed past the frame.
  Widget _pane({
    required Key key,
    required String title,
    String? trailing,
    required Widget child,
  }) => LayoutBuilder(
    builder: (ctx, box) {
      final grid = ctx.termGrid;
      // Arabic words are wider than the cells the frame cuts for them, so
      // in Arabic they always lead the first line.
      final fits =
          trailing == null ||
          !w.arabic &&
              grid.cellWidth +
                      TextPainter.computeWidth(
                        text: TextSpan(text: trailing, style: ink.dimStyle),
                        textDirection: Directionality.of(ctx),
                        textScaler: MediaQuery.textScalerOf(ctx),
                      ) <=
                  box.maxWidth - grid.cols(4);
      return TermPane(
        key: key,
        title: title,
        trailing: fits ? trailing : null,
        child: fits
            ? child
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(trailing, style: ink.dimStyle),
                  child,
                ],
              ),
      );
    },
  );

  Widget _week() {
    final week = mondayOf(studyToday);
    final grid = context.termGrid;
    final count = w.number(c.openTasks.length);
    final hours = w.duration(c.totalMinutes(week));
    // A reading: its label over its figure over a rule across its half,
    // set on the pane's keyline as the bars under it are. A box of its own
    // inside the pane would draw a frame in a frame.
    Widget face(
      String key,
      String label,
      String value,
      double labels,
      double figure,
    ) => MergeSemantics(
      key: ValueKey('today-stat-$key'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: labels,
            child: Text(label, style: ink.dimStyle),
          ),
          // A figure set smaller keeps its line, so the readings still
          // share a bottom.
          SizedBox(
            height: figure,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(value, maxLines: 1, style: ink.displayStyle),
            ),
          ),
          const TermDivider(),
        ],
      ),
    );
    // The way on runs line to line as a list's row does, its words on the
    // keyline by its own inset; the readings and bars are set on it.
    return TermPane(
      key: const ValueKey('today-week'),
      title: w.workWeek,
      padding: TermInset.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: grid.cellWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LayoutBuilder(
                  builder: (ctx, box) {
                    final direction = Directionality.of(ctx);
                    final scaler = MediaQuery.textScalerOf(ctx);
                    double width(String text) => TextPainter.computeWidth(
                      text: TextSpan(text: text, style: ink.displayStyle),
                      textDirection: direction,
                      textScaler: scaler,
                    );
                    final half = (box.maxWidth - grid.cellWidth) / 2;
                    double labels(double room) => [w.openTasks, w.hoursThisWeek]
                        .map((label) {
                          final painter = TextPainter(
                            text: TextSpan(text: label, style: ink.dimStyle),
                            textDirection: direction,
                            textScaler: scaler,
                          )..layout(maxWidth: room);
                          final height = painter.height;
                          painter.dispose();
                          return height;
                        })
                        .fold(0, math.max);
                    // Two readings side by side, their labels given one
                    // height so the readings share a top and a bottom line,
                    // a figure too wide for its half set smaller; at a
                    // large text size, where the larger would not fit its
                    // half, one over the other.
                    final large = scaler.scale(1) > 1.3;
                    final line = TextPainter(
                      text: TextSpan(text: hours, style: ink.displayStyle),
                      textDirection: direction,
                      textScaler: scaler,
                      maxLines: 1,
                    )..layout();
                    final figure = line.height;
                    line.dispose();
                    if (large && (width(hours) > half || width(count) > half)) {
                      final whole = labels(box.maxWidth);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          face('tasks', w.openTasks, count, whole, figure),
                          face('hours', w.hoursThisWeek, hours, whole, figure),
                        ],
                      );
                    }
                    final shared = labels(half);
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: grid.cellWidth,
                      children: [
                        Expanded(
                          child: face(
                            'tasks',
                            w.openTasks,
                            count,
                            shared,
                            figure,
                          ),
                        ),
                        Expanded(
                          child: face(
                            'hours',
                            w.hoursThisWeek,
                            hours,
                            shared,
                            figure,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // A line of air between the readings' rules and the bars.
                SizedBox(height: grid.lineHeight),
                _weekChart(week),
              ],
            ),
          ),
          _Line(
            name: w.seeTime,
            mark: _more,
            keys: _keyed ? _windowKeys[Place.time.index] : null,
            onOpen: () => go(Place.time),
          ),
        ],
      ),
    );
  }

  /// The week's hours, set on the Work week pane: a column of eighth-line
  /// blocks for each day, standing on an axis across the pane over its
  /// weekday, Monday first in the line's reading order, with the day's
  /// hours under it.
  Widget _weekChart(DateTime week) {
    final grid = context.termGrid;
    final minutes = c.dailyMinutes(week);
    final most = minutes.fold(60, math.max);
    final today = studyToday.weekday - 1;
    final height = grid.lines(4);
    Widget mark(int i) {
      final eighths = (minutes[i] / most * 32).round();
      return SizedBox(
        key: ValueKey('today-day-slot-$i'),
        width: grid.cols(2),
        height: minutes[i] == 0
            ? grid.lineHeight / 8
            : math.max(1, eighths) * grid.lineHeight / 8,
        child: ColoredBox(
          color: minutes[i] == 0
              ? ink.dim
              : i == today
              ? ink.accent
              : ink.accent.withValues(alpha: 0.7),
        ),
      );
    }

    return Semantics(
      image: true,
      label: chartName(week),
      excludeSemantics: true,
      child: KeyedSubtree(
        key: const ValueKey('today-chart'),
        child: LayoutBuilder(
          builder: (ctx, box) {
            final slot = box.maxWidth / 7;
            // One form for the week, never left out: each day in full where
            // every one fits its column with a cell of air (Arabic's
            // "٢ س ٣٠ د" is eight cells), else all as h:mm under
            // a caption naming the hours.
            final readings = WeekReadings.fit(
              ctx,
              words: w,
              minutes: minutes,
              style: ink.dimStyle,
              slot: slot - grid.cellWidth,
            );
            Widget row(
              List<Widget> cells, {
              CrossAxisAlignment align = CrossAxisAlignment.end,
            }) => Row(
              crossAxisAlignment: align,
              children: [for (final cell in cells) Expanded(child: cell)],
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (readings.compact) Text(w.logged, style: ink.dimStyle),
                // The axis takes its stroke from the bars' room, so the
                // chart keeps to whole lines and the pane to the grid.
                SizedBox(
                  height: height - termStrokeWidth(ink, grid),
                  child: row([
                    for (var i = 0; i < 7; i++)
                      Align(alignment: Alignment.bottomCenter, child: mark(i)),
                  ]),
                ),
                SizedBox(
                  height: termStrokeWidth(ink, grid),
                  child: ColoredBox(color: ink.rule),
                ),
                row([
                  for (var i = 0; i < 7; i++)
                    Text(
                      w.weekdayShort(addDays(week, i)),
                      key: ValueKey('today-day-label-$i'),
                      textAlign: TextAlign.center,
                      style: i == today ? ink.boldStyle : ink.dimStyle,
                    ),
                ]),
                row(align: CrossAxisAlignment.start, [
                  for (final d in readings.labels)
                    Text(
                      d,
                      key: const ValueKey('today-day-hours'),
                      textAlign: TextAlign.center,
                      softWrap: false,
                      style: ink.dimStyle,
                    ),
                ]),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _plan() {
    final tasks = c.todayTasks;
    return _pane(
      key: const ValueKey('today-plan'),
      title: w.todaysPlan,
      trailing: tasks.isEmpty
          ? null
          : w.progress(tasks.where((t) => t.done).length, tasks.length),
      child: tasks.isEmpty
          ? Text(w.noTasksToday, style: ink.dimStyle)
          : LayoutBuilder(
              builder: (ctx, box) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final task in tasks) _planRow(task, box.maxWidth),
                ],
              ),
            ),
    );
  }

  /// A task of the plan: its box, and its words beside it (wrapping
  /// whole where they don't fit one line); pressing the words checks it
  /// too. The box alone is the list's leading mark.
  Widget _planRow(Task task, double width) {
    final grid = context.termGrid;
    final title = w.text(task.title);
    final running = c.data.timer?.taskId == task.id;
    void toggle() => c.changeTasks([task.id], done: !task.done);
    return Column(
      key: ValueKey('plan-${task.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TermCheckbox(
              key: ValueKey('today-plan-lead-${task.id}'),
              value: task.done,
              semanticLabel: [
                title,
                c.projectName(task.project),
                if (running) w.runningTimer,
              ].join(', '),
              style: task.done
                  ? TermStyle(foreground: WidgetStatePropertyAll(ink.dim))
                  : null,
              onChanged: (_) => toggle(),
            ),
            SizedBox(width: grid.cellWidth),
            Expanded(
              child: ExcludeSemantics(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: toggle,
                    child: Text(
                      title,
                      style: task.done ? ink.dimStyle : ink.textStyle,
                    ),
                  ),
                ),
              ),
            ),
            // The task the timer runs on carries the timer's green lamp at
            // the end of its line; it moves with a switch and goes on stop.
            if (running) ...[
              SizedBox(width: grid.cellWidth),
              ExcludeSemantics(
                child: Text(
                  '●',
                  key: const ValueKey('today-plan-running'),
                  style: ink.boldStyle.copyWith(color: ink.success),
                ),
              ),
            ],
          ],
        ),
        // The project stands under the task's words, past the box's four
        // cells: `[x] `.
        Padding(
          padding: EdgeInsetsDirectional.only(start: grid.cols(4)),
          child: ExcludeSemantics(
            child: Text(c.projectName(task.project), style: ink.dimStyle),
          ),
        ),
      ],
    );
  }

  Widget _blocks() {
    final blocks = c.todayBlocks;
    final total = blocks.fold(0, (sum, e) => sum + e.end - e.start);
    return _pane(
      key: const ValueKey('today-blocks'),
      title: w.timeBlocks,
      trailing: blocks.isEmpty ? null : w.duration(total),
      // A log of the day: each block's hours in the first column, what was
      // done beside them, its project after. The hours are its length; the
      // pane's border carries the day's sum.
      child: blocks.isEmpty
          ? Text(w.noBlocks, style: ink.dimStyle)
          : _rows([
              for (final (i, e) in blocks.indexed)
                _Row(
                  // A tree's branches: each block hangs off the pane's
                  // title, the last closing it.
                  mark: switch ((i == blocks.length - 1, w.arabic)) {
                    (false, false) => '├',
                    (true, false) => '└',
                    (false, true) => '┤',
                    (true, true) => '┘',
                  },
                  leadKey: ValueKey('today-blocks-lead-$i'),
                  lead: w.timeRange(e),
                  leadStyle: ink.dimStyle,
                  title: w.text(e.note),
                  meta: c.projectName(e.project),
                ),
            ]),
    );
  }

  /// A list's rows as a console sets them: each title in one column and
  /// its words beside it in the next while both fit whole, or, where they
  /// would be cut, the words under the title on a second line (a finger's
  /// row, whatever the input).
  Widget _rows(List<_Row> rows) => LayoutBuilder(
    builder: (ctx, box) {
      final grid = ctx.termGrid;
      // Measured as set, not counted in cells: Arabic falls back to a face
      // off the grid, and its columns still have to line up.
      double widest(Iterable<(String, TextStyle?)> words) => words.fold(
        0,
        (most, w) => math.max(
          most,
          TextPainter.computeWidth(
            text: TextSpan(text: w.$1, style: ink.textStyle.merge(w.$2)),
            textDirection: Directionality.of(ctx),
            textScaler: MediaQuery.textScalerOf(ctx),
          ),
        ),
      );
      final lead = widest([for (final r in rows) (r.set, r.leadStyle)])
          .ceilToDouble();
      final title = widest([for (final r in rows) (r.title, null)]);
      final meta = widest([
        for (final r in rows)
          if (r.meta case final m?) (m, null),
      ]);
      final titleCols = grid.colsIn(lead + grid.cellWidth + title) + 1;
      final beside =
          grid.cols(titleCols + 3) + meta <= box.maxWidth || meta == 0;
      String named(_Row r) => [r.lead, r.title, ?r.meta]
          .map((words) => words.trim())
          .where((words) => words.isNotEmpty && words != _more)
          .join(', ');
      if (rows.every((r) => r.onTap == null)) {
        return _readRows(rows, box.maxWidth, lead, title, meta, named);
      }
      final tiles = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final r in rows)
            TermListTile(
              leading:
                  r.leading ??
                  _Lead(r.lead, mark: r.leadKey, style: r.leadStyle),
              title: Text(r.title),
              subtitle: r.meta == null ? null : Text(r.meta!),
              titleCols: titleCols,
              onTap: r.onTap,
              semanticLabel: named(r),
            ),
        ],
      );
      if (beside) return tiles;
      return RawTapTargetScope(
        targets: RawTapTargets.of(ctx).copyWith(input: RawInput.touch),
        child: tiles,
      );
    },
  );

  /// A list to read, not to press. Its columns: the lead (a time, two
  /// cells before the title; a block, one), the titles, and the words
  /// after them, which wrap within their column rather than cut.
  /// Where the words have no room beside the title they stand under it,
  /// and where even the title has none beside the lead, the lead stands
  /// over both.
  Widget _readRows(
    List<_Row> rows,
    double width,
    double lead,
    double title,
    double meta,
    String Function(_Row) named,
  ) {
    final grid = context.termGrid;
    final cw = grid.cellWidth;
    final gap = rows.any((r) => r.leading != null) ? cw : cw * 2;
    // The lead stands over its title where the title would not keep one
    // line beside it, rather than wrap and leave a word alone.
    final cramped = lead + gap + title > width;
    final titleBox = grid.cols(grid.colsIn(title) + 1);
    // Beside the title while the words keep a column of their own, 24
    // cells at the least: a task's name, whole. The rule asks nothing of
    // the words themselves, so a list keeps one layout as its rows come
    // and go.
    final beside =
        !cramped && lead + gap + titleBox + cw + grid.cols(24) <= width;
    // Under the title, words that would break leave one alone on a line:
    // the lead stands over the row instead, and the words take the
    // measure from two cells in, whole.
    final over =
        cramped ||
        !beside && meta > width - lead - gap && meta <= width - grid.cols(2);
    Widget words(_Row r) => beside
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: cw,
            children: [
              SizedBox(
                width: titleBox,
                child: Text(r.title, style: ink.textStyle),
              ),
              Expanded(child: Text(r.meta ?? '', style: ink.dimStyle)),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.title, style: ink.textStyle),
              if (r.meta != null) Text(r.meta!, style: ink.dimStyle),
            ],
          );
    Widget mark(_Row r) =>
        r.leading ??
        switch (r.mark) {
          null => Text(r.lead, key: r.leadKey, style: r.leadStyle),
          // The lead wraps after its glyph where a large text size leaves
          // it no line.
          final glyph => Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(glyph, key: r.leadKey, style: ink.dimStyle),
              Flexible(child: Text(' ${r.lead}', style: r.leadStyle)),
            ],
          ),
        };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final r in rows)
          Semantics(
            container: true,
            label: named(r),
            excludeSemantics: true,
            child: over
                // A hanging indent: the words two cells in under their
                // lead, so each row's lead still heads the list's column.
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      mark(r),
                      Padding(
                        padding: EdgeInsetsDirectional.only(
                          start: grid.cols(2),
                        ),
                        child: words(r),
                      ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(width: lead, child: mark(r)),
                      SizedBox(width: gap),
                      Expanded(child: words(r)),
                    ],
                  ),
          ),
      ],
    );
  }

  // Rows that run line to line, their words on the keyline by their own
  // inset.
  Widget _later() => TermPane(
    key: const ValueKey('today-later'),
    title: w.laterThisWeek,
    padding: TermInset.zero,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.laterThisWeek.isEmpty)
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: context.termGrid.cols(1),
            ),
            child: Text(w.allClear, style: ink.dimStyle),
          ),
        _rows([
          for (final t in c.laterThisWeek)
            _Row(
              lead: _more,
              leadKey: ValueKey('today-later-lead-${t.id}'),
              title: w.text(t.title),
              meta: '${c.projectName(t.project)}$_dot${w.weekday(t.due)}',
              onTap: () => open(t),
            ),
        ]),
        // The way on is one line, as the week's own is, whatever the
        // rows above it take.
        _Line(
          name: w.viewTasks,
          mark: _more,
          keys: _keyed ? _windowKeys[Place.tasks.index] : null,
          onOpen: () => go(Place.tasks),
        ),
      ],
    ),
  );

  Widget _people() => TermPane(
    key: const ValueKey('today-team'),
    title: w.teamActivity,
    child: _rows([
      for (final person in team)
        _Row(
          lead: '    ',
          leading: TermAvatar(
            key: ValueKey('today-team-lead-${person.id}'),
            name: w.text(person.name),
          ),
          title: w.text(person.name),
          meta: switch (c.currentTask(person.id)) {
            final task? => w.text(task.title),
            null => w.notTracking,
          },
        ),
    ]),
  );

  Widget _feed() => TermPane(
    key: const ValueKey('today-activity'),
    title: w.recentActivity,
    child: c.data.activity.isEmpty
        ? Text(w.noActivity, style: ink.dimStyle)
        : StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, now) {
              final times = [
                for (final e in c.data.activity) w.timeAgo(e.at, now.data!),
              ];
              final width = times.fold(
                0,
                (most, t) => math.max(most, t.characters.length),
              );
              return _rows([
                for (final (i, e) in c.data.activity.indexed)
                  _Row(
                    // A log's graph: one mark for each event.
                    mark: '*',
                    leadKey: ValueKey('today-feed-lead-$i'),
                    lead: times[i].padRight(width),
                    leadStyle: ink.dimStyle,
                    title: w.eventAction(e, c.personName(e.person)),
                    meta: w.text(e.subject),
                  ),
              ]);
            },
          ),
  );
}

/// One row of a list: its lead (a mark, a time, or the [leading] widget
/// standing in [lead]'s cells), its title and the words beside it.
class _Row {
  const _Row({
    required this.lead,
    required this.title,
    this.mark,
    this.leadKey,
    this.leading,
    this.leadStyle,
    this.meta,
    this.onTap,
  });
  final String lead, title;

  /// A glyph before the lead (a tree's branch, a log's star), the list's
  /// leading mark; where none, the lead itself is.
  final String? mark;

  /// The key on the row's leading mark.
  final Key? leadKey;
  final Widget? leading;
  final TextStyle? leadStyle;
  final String? meta;
  final VoidCallback? onTap;

  /// The lead's cells as set: its mark, a cell, its words.
  String get set => mark == null ? lead : '$mark $lead';
}

/// Today's two columns from a tablet's width: the work and its people
/// (plan, later, team) in the first, the time and its log (week, blocks,
/// activity) in the second. Where the log runs long, the time blocks stand
/// under the plan instead, whichever brings the two columns' bottoms
/// nearer one line. Every pane takes its column's measure and its own
/// height; none is stretched.
class _Columns extends MultiChildRenderObjectWidget {
  const _Columns({
    required this.gap,
    required this.textDirection,
    required super.children,
  }) : assert(children.length == 6);

  final double gap;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderColumns(gap, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderColumns r) => r
    ..gap = gap
    ..textDirection = textDirection;
}

class _ColumnsData extends ContainerBoxParentData<RenderBox> {}

class _RenderColumns extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ColumnsData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ColumnsData> {
  _RenderColumns(this._gap, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  // By the children's order (plan, later, team, week, blocks, activity):
  // the blocks under the week, or under the plan.
  // A line of the grid: the least two titles stand apart unless level.
  static const _line = 24.0;

  static const _arrangements = [
    ([0, 1, 2], [3, 4, 5]),
    ([0, 4, 1, 2], [3, 5]),
  ];

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ColumnsData) child.parentData = _ColumnsData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final measure = (width - _gap) / 2;
    final panes = getChildrenAsList();
    for (final pane in panes) {
      pane.layout(
        BoxConstraints.tightFor(width: measure),
        parentUsesSize: true,
      );
    }
    double height(List<int> column) =>
        column.fold(0, (sum, i) => sum + panes[i].size.height);
    double ragged((List<int>, List<int>) a) =>
        (height(a.$1) - height(a.$2)).abs();
    // The usual order holds unless the other ends the columns a line
    // nearer each other.
    final (
      first,
      second,
    ) = ragged(_arrangements[1]) + 24 < ragged(_arrangements[0])
        ? _arrangements[1]
        : _arrangements[0];
    final rtl = _textDirection == TextDirection.rtl;
    final x = [rtl ? width - measure : 0.0, rtl ? 0.0 : width - measure];
    final columns = [first, second];
    // Side by side, two panes' titles share a line or stand a line apart
    // at the least: down the two columns at once, a pane whose top would
    // fall under a line short of the other column's next is set down to
    // it.
    final next = [0, 0];
    final y = [0.0, 0.0];
    while (next[0] < columns[0].length || next[1] < columns[1].length) {
      final a = next[1] >= columns[1].length
          ? 0
          : next[0] >= columns[0].length
          ? 1
          : y[0] <= y[1]
          ? 0
          : 1;
      final b = 1 - a;
      if (next[b] < columns[b].length) {
        final apart = y[b] - y[a];
        if (apart > 1 && apart < _line) y[a] = y[b];
      }
      final pane = panes[columns[a][next[a]]];
      (pane.parentData! as _ColumnsData).offset = Offset(x[a], y[a]);
      y[a] += pane.size.height;
      next[a]++;
    }
    size = constraints.constrain(Size(width, math.max(y[0], y[1])));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// Where a glyph's ink stands inside its advance, against the marks it is
/// lined up with: the clock's figures start on the second column's
/// keyline by their ink, and the clock and the keys stand on the task's
/// centre line by theirs, not by their line boxes.
abstract final class _TodayInk {
  static bool _rtl(TextDirection direction) => direction == TextDirection.rtl;

  /// The display figures' first ink stands two pixels into its cell; the
  /// last, from the end, a pixel and a half.
  static Offset digits(TextDirection direction) =>
      Offset(_rtl(direction) ? -1.4 : 2, 0);

  /// A key's closing bracket inks the first half of its cell: the keys
  /// move half a cell on, so their ink ends the pane's inset from its rule.
  static Offset controls(TextDirection direction) =>
      Offset(_rtl(direction) ? -4.5 : 4.5, 0);
}

/// The timer's strip: the task's words at the start, the clock, and its
/// keys at the end, each on the strip's centre line. The clock stands at
/// [keyline] from the start while it (set a little smaller at the least)
/// and the keys fit after it, [air] before the keys and after the words;
/// otherwise it follows the words by [gap], and the words give way to the
/// clock and keys, wrapping, rather than either being pushed out.
class _Strip extends MultiChildRenderObjectWidget {
  _Strip({
    required this.keyline,
    required this.gap,
    required this.air,
    required this.textDirection,
    required Widget words,
    required Widget clock,
    required Widget keys,
  }) : super(children: [words, clock, keys]);

  final double? keyline;
  final double gap, air;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStrip(keyline, gap, air, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderStrip r) => r
    ..keyline = keyline
    ..gap = gap
    ..air = air
    ..textDirection = textDirection;
}

class _StripData extends ContainerBoxParentData<RenderBox> {}

class _RenderStrip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StripData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StripData> {
  _RenderStrip(this._keyline, this._gap, this._air, this._textDirection);

  double? _keyline;
  set keyline(double? value) {
    if (value == _keyline) return;
    _keyline = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _air;
  set air(double value) {
    if (value == _air) return;
    _air = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _StripData) child.parentData = _StripData();
  }

  ({Size size, List<Offset> at}) _arrange(
    BoxConstraints constraints,
    ChildLayouter layout,
  ) {
    final words = firstChild!, clock = childAfter(words)!;
    final keys = childAfter(clock)!;
    final width = constraints.maxWidth;
    final loose = BoxConstraints(maxWidth: width);
    final k = layout(keys, loose);
    var c = layout(clock, loose);
    final keyline = _keyline;
    // On the keyline the clock may be set a little smaller, to five sixths
    // at the least, rather than leave it.
    final after = keyline == null ? 0.0 : width - keyline - _air - k.width;
    final onGrid = keyline != null && after >= c.width * 5 / 6;
    if (onGrid && after < c.width) {
      c = layout(clock, BoxConstraints(maxWidth: after));
    }
    final room = onGrid
        ? keyline - _air
        : width - _gap - c.width - _air - k.width;
    final t = layout(words, BoxConstraints(maxWidth: math.max(0, room)));
    final size = constraints.constrain(
      Size(width, [t.height, c.height, k.height].reduce(math.max)),
    );
    Offset place(Size child, double start) => Offset(
      _textDirection == TextDirection.rtl
          ? size.width - start - child.width
          : start,
      (size.height - child.height) / 2,
    );
    return (
      size: size,
      at: [
        place(t, 0),
        place(c, onGrid ? keyline : t.width + _gap),
        place(k, size.width - k.width),
      ],
    );
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      _arrange(constraints, ChildLayoutHelper.dryLayoutChild).size;

  @override
  void performLayout() {
    final arranged = _arrange(constraints, ChildLayoutHelper.layoutChild);
    size = arranged.size;
    var child = firstChild;
    for (final at in arranged.at) {
      (child!.parentData! as _StripData).offset = at;
      child = childAfter(child);
    }
  }

  double _across(double Function(RenderBox) width) {
    var sum = _gap + _air;
    for (final child in getChildrenAsList()) {
      sum += width(child);
    }
    return sum;
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _across((child) => child.getMinIntrinsicWidth(height));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _across((child) => child.getMaxIntrinsicWidth(height));

  @override
  double computeMinIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  double computeMaxIntrinsicHeight(double width) =>
      getDryLayout(BoxConstraints(maxWidth: width)).height;

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A list row's lead, keyed as the list's leading mark where it shows: the
/// tile's hidden copy that keeps its words' indent takes no key.
class _Lead extends StatelessWidget {
  const _Lead(this.lead, {this.mark, this.style});
  final String lead;
  final Key? mark;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final hidden =
        context.findAncestorWidgetOfExactType<Opacity>()?.opacity == 0;
    return Text(lead, key: hidden ? null : mark, style: style);
  }
}
