part of '../stint_ledger.dart';

/// Today kept as a day book: the running timer printed on a slip as a
/// receipt's line (the task joined to its elapsed figure by the dot
/// leader), the week on a second slip, and the day's plan, time, team and
/// later work ruled in the page's own sections.
extension _Today on _BookState {
  Widget today() => LedgerScreen(
    // The tab's masthead is the greeting under the day's date, the name in
    // the italic, as Ledger heads a home tab.
    topBar: switch (w.greeting.lastIndexOf(', ')) {
      final at when at > 0 => bar(
        w.greeting.substring(0, at + 1),
        italic: w.greeting.substring(at + 2),
        meta: _date,
      ),
      _ => bar(w.greeting, meta: _date),
    },
    body: load(
      () => LayoutBuilder(
        builder: (ctx, box) {
          final scale = MediaQuery.textScalerOf(ctx).scale(1);
          // Two columns from a tablet's page: the work and its people in
          // the first, the week, the day's time and its log in the second.
          final split = box.maxWidth >= 600 && box.maxWidth / scale >= 560;
          final wide = box.maxWidth >= 900 && box.maxWidth / scale >= 760;
          final gap = wide ? 40.0 : 32.0;
          // Where the second column starts: the slip sets its clock there,
          // over the week's first figure.
          final keyline = (box.maxWidth - gap) / 2 + gap;
          final plan = _plan(), blocks = _blocks(), later = _later();
          final people = _people(), feed = _feed();
          final week = _week();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 24,
            children: [
              _timerSlip(keyline: split ? keyline : null),
              if (split)
                _Columns(
                  gap: gap,
                  spacing: 32,
                  textDirection: Directionality.of(ctx),
                  children: [plan, later, people, week, blocks, feed],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 32,
                  children: [week, plan, blocks, later, people, feed],
                ),
            ],
          );
        },
      ),
    ),
  );

  String get _date => '${w.weekday(studyToday)}$_dot${w.shortDate(studyToday)}';

  /// The mark between two words of a line: the middle dot, but in Arabic
  /// its comma, as the dot would read as the Arabic zero (٠).
  String get _dot => w.arabic ? '، ' : ' · ';

  Widget _timerSlip({double? keyline}) {
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    final motion = LedgerMotion.of(context, LedgerMotion.base);
    Future<void> pick() => showLedgerCommandPalette(
      context,
      hint: w.search,
      commands: [
        for (final item in choices)
          LedgerCommand(
            label: w.text(item.title),
            group: c.projectName(item.project),
            onPressed: () => c.track(item.id),
          ),
      ],
    );

    final title = AnimatedSwitcher(
      duration: motion,
      switchInCurve: LedgerMotion.out,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.centerStart,
        children: [...previous, ?current],
      ),
      child: Text(
        active ? w.text(task.title) : w.chooseTask,
        key: ValueKey(task?.id),
        textWidthBasis: TextWidthBasis.longestLine,
        style: ink.barTitle.colored(
          active ? ink.textPrimary : ink.textSecondary,
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
        child: AnimatedDefaultTextStyle(
          duration: motion,
          curve: LedgerMotion.out,
          style: _clockStyle(active: active),
          child: Text(value, textDirection: TextDirection.ltr, maxLines: 1),
        ),
      );
    }

    final figure = KeyedSubtree(
      key: const ValueKey('today-timer-digits'),
      child: timer == null
          ? reading(c.repository.now())
          : StreamBuilder<DateTime>(
              stream: c.ticks(const Duration(seconds: 1)),
              initialData: c.repository.now(),
              builder: (_, now) => reading(now.data!),
            ),
    );
    final project = Text(
      active
          ? c.projectName(task.project)
          : choices.isEmpty
          ? w.noTimerTasks
          : w.notTracking,
      textWidthBasis: TextWidthBasis.longestLine,
      style: ink.bodySmall.colored(ink.textSecondary),
    );
    List<Widget> keys({required bool expand}) => [
      if (active)
        LedgerButton.ink(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: LucideIcons.square,
          size: LedgerButtonSize.medium,
          expand: expand,
          onPressed: c.stopTimer,
        ),
      if (active)
        LedgerButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          icon: LucideIcons.arrowLeftRight,
          size: LedgerButtonSize.medium,
          expand: expand,
          onPressed: choices.isEmpty ? null : pick,
        )
      else
        LedgerButton.filled(
          w.startTimer,
          key: const ValueKey('today-action-first'),
          icon: LucideIcons.play,
          size: LedgerButtonSize.medium,
          expand: expand,
          onPressed: choices.isEmpty ? null : pick,
        ),
    ];
    // The running record's seal in the second ink: its day, its number and
    // the hour it began. Stopped, it is lifted off and its room closes.
    final seal = AnimatedSize(
      duration: motion,
      curve: LedgerMotion.out,
      alignment: AlignmentDirectional.centerStart,
      child: AnimatedSwitcher(
        duration: motion,
        switchInCurve: LedgerMotion.out,
        child: active
            ? ExcludeSemantics(
                key: ValueKey(task.id),
                child: LedgerSeal(
                  kicker: w.shortDate(studyToday),
                  value: task.id,
                  foot: w.clock(minuteOfDay(timer.start)),
                  tone: LedgerSealTone.plain,
                  size: LedgerSealSize.memo,
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
    // The slip is printed as Ledger prints a page's own record: the
    // guilloche band edge to edge, the kind and the hour in its head, and
    // the slip's side room all round what follows.
    final head = LedgerSlipHead(
      active ? w.runningTimer : w.stoppedTimer,
      timer == null ? '' : w.since(timer.start),
    );
    final side = LedgerLayout.isWide(context) ? 36.0 : 20.0;
    return LedgerSlip(
      key: const ValueKey('today-timer-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LedgerSlipBand(),
          Padding(
            padding: EdgeInsets.fromLTRB(side, 0, side, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                head,
                _timerBody(
                  title: title,
                  project: project,
                  figure: figure,
                  keys: keys,
                  seal: seal,
                  keyline: keyline == null ? null : keyline - side,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _clockStyle({required bool active}) => ink.figureMedium.copyWith(
    color: active ? ink.textPrimary : ink.textTertiary,
    fontFeatures: const [FontFeature.tabularFigures()],
  );

  /// The slip's line: the task, the clock and the keys on one centre line.
  /// From a tablet's width the clock stands where the second column starts,
  /// over the week's first figure; where the keys' words don't fit after
  /// it, the keys take a second line at the slip's end, under the clock. A
  /// phone stacks them, the record's seal pressed by the clock.
  Widget _timerBody({
    required Widget title,
    required Widget project,
    required Widget figure,
    required List<Widget> Function({required bool expand}) keys,
    required Widget seal,
    double? keyline,
  }) => LayoutBuilder(
    builder: (ctx, box) {
      final scale = MediaQuery.textScalerOf(ctx).scale(1);
      final room = box.maxWidth / scale;
      final direction = Directionality.of(ctx);
      final words = KeyedSubtree(
        key: const ValueKey('today-timer-title'),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 4,
          children: [title, project],
        ),
      );
      if (room >= 560) {
        return _Strip(
          keyline: keyline,
          gap: 16,
          air: 24,
          lead: 10,
          textDirection: direction,
          words: words,
          clock: _Nudge(
            _LedgerInk.digits(direction),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: figure,
            ),
          ),
          keys: _Nudge(
            _LedgerInk.controls(direction),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 10,
              children: keys(expand: false),
            ),
          ),
        );
      }
      final buttons = keys(expand: true);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          words,
          const SizedBox(height: 10),
          // At a large text size the figure shrinks to the slip's measure
          // rather than lose its last digits; where there is room the seal
          // is pressed at its end.
          Row(
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: figure,
                ),
              ),
              if (room >= 300) seal,
            ],
          ),
          const SizedBox(height: 14),
          // Two keys share the slip's measure while each one's words fit
          // its half on one line; else, or one key alone, each takes the
          // whole of it.
          if (buttons.length == 2)
            StintPair(first: buttons.first, second: buttons.last, spacing: 10)
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 10,
              children: buttons,
            ),
        ],
      );
    },
  );

  /// The week ruled as the page's other sections are: its two figures,
  /// each in a ruled cell of its own, over the week's bars, and the way on
  /// to the timesheet under them.
  Widget _week() {
    final monday = mondayOf(studyToday);
    final tasks = c.todayTasks;
    final done = tasks.where((t) => t.done).length;
    final todayMinutes = c.dailyMinutes(monday)[studyToday.weekday - 1];
    // A figure's words never part across a line.
    String whole(String figure) => figure.replaceAll(' ', ' ');
    // At a large text size the two figures stand one under the other, each
    // on the column's whole measure.
    final large = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    Widget fact(String key, String label, String value, String note) =>
        DecoratedBox(
          key: ValueKey('today-stat-$key'),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: ink.headRule)),
          ),
          child: Padding(
            // Two in from the rule's ends, so a figure's ink never runs to
            // them.
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 2),
            child: MergeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: w.arabic
                        ? ink.label.copyWith(letterSpacing: 0)
                        : ink.label,
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(value, maxLines: 1, style: ink.figureSmall),
                  ),
                  const SizedBox(height: 4),
                  Text(note, style: ink.bodySmall.colored(ink.textSecondary)),
                ],
              ),
            ),
          ),
        );
    final tasksFact = fact(
      'tasks',
      w.openTasks,
      w.number(c.openTasks.length),
      '${w.today}$_dot${whole(w.progress(done, tasks.length))}',
    );
    final hoursFact = fact(
      'hours',
      w.hoursThisWeek,
      w.duration(c.totalMinutes(monday)),
      '${w.today}$_dot${whole(w.duration(todayMinutes))}',
    );
    return LedgerSection(
      key: const ValueKey('today-week'),
      head: LedgerHead(w.workWeek),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (large)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [tasksFact, hoursFact],
            )
          else
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 24,
                children: [
                  Expanded(child: tasksFact),
                  Expanded(child: hoursFact),
                ],
              ),
            ),
          const SizedBox(height: 24),
          _weekChart(monday),
          const SizedBox(height: 16),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: LedgerMoreLink(w.seeTime, onTap: () => go(Place.time)),
          ),
        ],
      ),
    );
  }

  /// The week's hours drawn as the ledger draws bars: a hatched column in
  /// ink for each day on the floor's rule, Monday first from the reading
  /// start, its key centred under it; a day with none a stub on the floor.
  Widget _weekChart(DateTime monday) {
    final minutes = c.dailyMinutes(monday);
    final most = minutes.fold(60, math.max);
    final today = studyToday.weekday - 1;
    final meta = w.arabic ? ink.meta.copyWith(letterSpacing: 0) : ink.meta;
    final marked = meta.colored(ink.textPrimary);
    const height = 120.0;
    return Semantics(
      image: true,
      excludeSemantics: true,
      label: [
        w.logged,
        for (var i = 0; i < minutes.length; i++)
          '${w.weekday(addDays(monday, i))} ${w.duration(minutes[i])}',
      ].join(', '),
      child: LayoutBuilder(
        builder: (ctx, box) {
          final slot = box.maxWidth / 7;
          final bar = math.min(30.0, slot * 0.56);
          double measure(String text) => TextPainter.computeWidth(
            text: TextSpan(text: text, style: meta),
            textDirection: Directionality.of(ctx),
            textScaler: MediaQuery.textScalerOf(ctx),
          );
          // A key keeps air either side of it.
          bool fits(Iterable<String> words) =>
              words.every((word) => measure(word) <= slot - 12);
          final short = [
            for (var i = 0; i < 7; i++) w.weekdayShort(addDays(monday, i)),
          ];
          final names = fits(short)
              ? short
              : [
                  for (var i = 0; i < 7; i++)
                    w.weekdayNarrow(addDays(monday, i)),
                ];
          // One form for the week: each day in full where every one keeps
          // its air, else all as h:mm, under a caption naming
          // the hours.
          final readings = WeekReadings.fit(
            ctx,
            words: w,
            minutes: minutes,
            style: meta,
            slot: slot - 12,
          );
          final hours = readings.labels;
          final showHours = fits(hours);
          Widget row(List<Widget> cells, {bool floor = false}) => Row(
            crossAxisAlignment: floor
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [for (final cell in cells) Expanded(child: cell)],
          );
          return Column(
            key: const ValueKey('today-chart'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showHours && readings.compact)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(w.logged, style: meta),
                ),
              SizedBox(
                height: height,
                child: row(floor: true, [
                  for (var i = 0; i < 7; i++)
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: minutes[i] == 0
                          ? SizedBox(
                              key: ValueKey('today-day-slot-$i'),
                              width: bar,
                              height: 2,
                              child: ColoredBox(color: ink.textSecondary),
                            )
                          : CustomPaint(
                              key: ValueKey('today-day-slot-$i'),
                              size: Size(
                                bar,
                                math.max(4, height * minutes[i] / most),
                              ),
                              painter: _Hatch(
                                edge: ink.textPrimary,
                                hatch: i == today
                                    ? ink.textPrimary
                                    : ink.textSecondary,
                              ),
                            ),
                    ),
                ]),
              ),
              Container(height: 1, color: ink.headRule),
              const SizedBox(height: 8),
              row([
                for (var i = 0; i < 7; i++)
                  Text(
                    names[i],
                    key: ValueKey('today-day-label-$i'),
                    style: i == today ? marked.medium : meta,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
              ]),
              if (showHours)
                row([
                  for (var i = 0; i < 7; i++)
                    Text(
                      hours[i],
                      style: i == today ? marked : meta,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                    ),
                ]),
            ],
          );
        },
      ),
    );
  }

  Widget _plan() {
    final tasks = c.todayTasks;
    return LedgerSection(
      key: const ValueKey('today-plan'),
      head: LedgerHead(
        w.todaysPlan,
        note: tasks.isEmpty
            ? null
            : w.progress(tasks.where((t) => t.done).length, tasks.length),
      ),
      child: tasks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(w.noTasksToday, style: ink.body),
            )
          : LedgerRows(children: [for (final task in tasks) _planRow(task)]),
    );
  }

  Widget _planRow(Task task) {
    final title = w.text(task.title), project = c.projectName(task.project);
    final motion = LedgerMotion.of(context, LedgerMotion.base);
    final running = c.data.timer?.taskId == task.id;
    return LedgerPressable(
      key: ValueKey('plan-${task.id}'),
      onTap: () => c.changeTasks([task.id], done: !task.done),
      checked: task.done,
      label: [title, project, if (running) w.runningTimer].join(', '),
      child: ColoredBox(
        color: ink.background.withValues(alpha: 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            spacing: 14,
            children: [
              LedgerCheck(
                key: ValueKey('today-plan-lead-${task.id}'),
                value: task.done,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 3,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: motion,
                      curve: LedgerMotion.out,
                      style: ink.rowTitle.copyWith(
                        color: task.done ? ink.textSecondary : ink.textPrimary,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                        decorationColor: ink.textSecondary,
                      ),
                      child: Text(title),
                    ),
                    Text(
                      project,
                      style: ink.bodySmall.colored(ink.textSecondary),
                    ),
                  ],
                ),
              ),
              // The task the timer runs on says so at the row's end, as the
              // ledger marks a live entry: a word ringed in the green, in
              // mono capitals. It moves with a switch and lifts on stop.
              AnimatedSwitcher(
                duration: motion,
                switchInCurve: LedgerMotion.out,
                child: running
                    ? ExcludeSemantics(
                        key: const ValueKey('today-plan-running'),
                        child: LedgerTag(
                          w.runningTimer,
                          tone: LedgerTagTone.unread,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _blocks() {
    final blocks = c.todayBlocks;
    final total = blocks.fold(0, (sum, e) => sum + e.end - e.start);
    final meta = w.arabic ? ink.meta.copyWith(letterSpacing: 0) : ink.meta;
    return LedgerSection(
      key: const ValueKey('today-blocks'),
      head: LedgerHead(
        w.timeBlocks,
        note: blocks.isEmpty ? null : w.duration(total),
      ),
      child: blocks.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(w.noBlocks, style: ink.body),
            )
          : Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              // One entry a block, read in the reader's words.
              child: Semantics(
                container: true,
                label: [
                  for (final e in blocks)
                    '${w.timeRange(e)}, ${w.text(e.note)}, '
                        '${c.projectName(e.project)}, ${w.duration(e.end - e.start)}',
                ].join('. '),
                excludeSemantics: true,
                // The day's blocks on an ink rail, each a dot where it
                // begins: its hours, what was done, its project and length.
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, e) in blocks.indexed)
                      IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          spacing: 14,
                          children: [
                            SizedBox(
                              width: 26,
                              child: CustomPaint(
                                painter: _Rail(
                                  color: ink.textPrimary,
                                  above: i > 0,
                                  below: i < blocks.length - 1,
                                  at: 9,
                                ),
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: SizedBox(
                                      key: ValueKey('today-blocks-lead-$i'),
                                      width: 10,
                                      height: 10,
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          color: ink.textPrimary,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  bottom: i < blocks.length - 1 ? 18 : 0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  spacing: 2,
                                  children: [
                                    Text(w.timeRange(e), style: meta),
                                    Text(w.text(e.note), style: ink.rowTitle),
                                    Text(
                                      // A length never parts across a line.
                                      '${c.projectName(e.project)}$_dot${w.duration(e.end - e.start).replaceAll(' ', ' ')}',
                                      style: ink.bodySmall.colored(
                                        ink.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _later() => LedgerSection(
    key: const ValueKey('today-later'),
    head: LedgerHead(w.laterThisWeek),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (c.laterThisWeek.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(w.allClear, style: ink.body),
          )
        else
          LedgerRows(
            children: [
              for (final t in c.laterThisWeek)
                LedgerRow(
                  // A bullet in the plan's box column: the list's lead, and
                  // its words on the plan's words' edge.
                  leading: SizedBox(
                    width: 26,
                    child: Center(
                      child: SizedBox(
                        key: ValueKey('today-later-lead-${t.id}'),
                        width: 6,
                        height: 6,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: ink.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                  title: w.text(t.title),
                  subtitle: c.projectName(t.project),
                  trailingSubtitle: w.weekday(t.due),
                  semanticLabel:
                      '${w.text(t.title)}, ${c.projectName(t.project)}, ${w.weekday(t.due)}',
                  onTap: () => open(t),
                ),
            ],
          ),
        const SizedBox(height: 16),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: LedgerMoreLink(w.viewTasks, onTap: () => go(Place.tasks)),
        ),
      ],
    ),
  );

  Widget _people() => LedgerSection(
    key: const ValueKey('today-team'),
    head: LedgerHead(w.teamActivity),
    child: LayoutBuilder(
      builder: (ctx, box) => LedgerRows(
        children: [
          for (final person in team)
            LedgerRow(
              leading: LedgerMonogram(
                w.text(person.name),
                key: ValueKey('today-team-lead-${person.id}'),
                size: LedgerMonogramSize.dense,
              ),
              title: w.text(person.name),
              subtitle: switch (c.currentTask(person.id)) {
                final task? => w.text(task.title),
                null => w.notTracking,
              },
              // Their task's project at the row's end, as the plan names it,
              // where the column has room for it on the task's line.
              trailingSubtitle: switch (c.currentTask(person.id)) {
                final task? when box.maxWidth >= 420 => c.projectName(
                  task.project,
                ),
                _ => null,
              },
            ),
        ],
      ),
    ),
  );

  Widget _feed() => LedgerSection(
    key: const ValueKey('today-activity'),
    head: LedgerHead(w.recentActivity),
    child: c.data.activity.isEmpty
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(w.noActivity, style: ink.body),
          )
        : StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, now) => LedgerRows(
              children: [
                for (final (i, e) in c.data.activity.indexed)
                  LedgerRow(
                    leading: LedgerMonogram(
                      c.personName(e.person),
                      key: ValueKey('today-feed-lead-$i'),
                      size: LedgerMonogramSize.dense,
                    ),
                    title: w.eventAction(e, c.personName(e.person)),
                    subtitle: w.text(e.subject),
                    trailingSubtitle: w.timeAgo(e.at, now.data!),
                  ),
              ],
            ),
          ),
  );
}

/// A day's bar as the ledger hatches it: an ink edge and diagonal strokes.
class _Hatch extends CustomPainter {
  const _Hatch({required this.edge, required this.hatch});
  final Color edge, hatch;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRect(rect);
    final strokes = Paint()
      ..color = hatch
      ..strokeWidth = 1;
    for (var x = -size.height; x < size.width; x += 4) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        strokes,
      );
    }
    canvas.restore();
    canvas.drawRect(
      rect.deflate(0.5),
      Paint()
        ..color = edge
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_Hatch old) => old.edge != edge || old.hatch != hatch;
}

/// The time blocks' rail: an ink line through each block's dot, from the
/// block before it to the block after.
class _Rail extends CustomPainter {
  const _Rail({
    required this.color,
    required this.above,
    required this.below,
    required this.at,
  });
  final Color color;
  final bool above, below;
  final double at;

  @override
  void paint(Canvas canvas, Size size) {
    final x = size.width / 2;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.5;
    if (above) canvas.drawLine(Offset(x, 0), Offset(x, at), line);
    if (below) canvas.drawLine(Offset(x, at), Offset(x, size.height), line);
  }

  @override
  bool shouldRepaint(_Rail old) =>
      old.color != color ||
      old.above != above ||
      old.below != below ||
      old.at != at;
}

/// Where a glyph's ink stands inside its advance, against the marks it is
/// lined up with: the clock's figures start on the second column's edge
/// by their ink, and the clock and the keys stand on the task's centre
/// line by theirs, not by their line boxes.
abstract final class _LedgerInk {
  static bool _rtl(TextDirection direction) => direction == TextDirection.rtl;

  /// The Latin figures stand a pixel and a half above their line's middle
  /// and a pixel past their advance's start; the Arabic sit on it, the
  /// last figure's ink (a zero's lozenge) well inside its advance.
  static Offset digits(TextDirection direction) =>
      _rtl(direction) ? const Offset(4.5, 0) : const Offset(-1, 1.5);

  static Offset controls(TextDirection direction) => Offset.zero;
}

/// Today's two equal columns from a tablet's page, [gap] apart: the work and
/// its people (plan, later, team) in the first, the week, the day's time
/// and its log in the second. Each section takes its column's measure and
/// its own height; side by side, two sections' heads share a line or
/// stand a line apart at the least.
class _Columns extends MultiChildRenderObjectWidget {
  const _Columns({
    required this.gap,
    required this.spacing,
    required this.textDirection,
    required super.children,
  }) : assert(children.length == 6);

  final double gap, spacing;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderColumns(gap, spacing, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderColumns r) => r
    ..gap = gap
    ..spacing = spacing
    ..textDirection = textDirection;
}

class _ColumnsData extends ContainerBoxParentData<RenderBox> {}

class _RenderColumns extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _ColumnsData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _ColumnsData> {
  _RenderColumns(this._gap, this._spacing, this._textDirection);

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  double _spacing;
  set spacing(double value) {
    if (value == _spacing) return;
    _spacing = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  // The least two heads stand apart unless level: a line of the page.
  static const _line = 24.0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _ColumnsData) child.parentData = _ColumnsData();
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final measure = (width - _gap) / 2;
    final sections = getChildrenAsList();
    final columns = [sections.sublist(0, 3), sections.sublist(3)];
    for (final column in columns) {
      for (final section in column) {
        section.layout(
          BoxConstraints.tightFor(width: measure),
          parentUsesSize: true,
        );
      }
    }
    final rtl = _textDirection == TextDirection.rtl;
    final x = [rtl ? width - measure : 0.0, rtl ? 0.0 : measure + _gap];
    // Down the two columns at once: a section whose head would fall under
    // a line short of the other column's next is set down to it.
    final next = [0, 0];
    final y = [0.0, 0.0];
    while (next[0] < 3 || next[1] < 3) {
      final a = next[1] >= 3
          ? 0
          : next[0] >= 3
          ? 1
          : y[0] <= y[1]
          ? 0
          : 1;
      final b = 1 - a;
      if (next[b] < 3) {
        final apart = y[b] - y[a];
        if (apart > 1 && apart < _line) y[a] = y[b];
      }
      final section = columns[a][next[a]];
      (section.parentData! as _ColumnsData).offset = Offset(x[a], y[a]);
      y[a] += section.size.height + _spacing;
      next[a]++;
    }
    size = constraints.constrain(Size(width, math.max(y[0], y[1]) - _spacing));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// The timer's strip: the task's words at the start, the clock, and its
/// keys at the end, each on the strip's centre line. The clock stands at
/// [keyline] from the start, [air] after the words, while it fits there
/// (set a little smaller at the least); the keys follow at the strip's end,
/// [air] after the clock, or where they don't fit there take a second line
/// [lead] under the clock, still at the end. Without the keyline the clock follows
/// the words by [gap], and the words give way to the clock and keys,
/// wrapping, rather than either being pushed out.
class _Strip extends MultiChildRenderObjectWidget {
  _Strip({
    required this.keyline,
    required this.gap,
    required this.air,
    required this.lead,
    required this.textDirection,
    required Widget words,
    required Widget clock,
    required Widget keys,
  }) : super(children: [words, clock, keys]);

  final double? keyline;
  final double gap, air, lead;
  final TextDirection textDirection;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderStrip(keyline, gap, air, lead, textDirection);

  @override
  void updateRenderObject(BuildContext context, _RenderStrip r) => r
    ..keyline = keyline
    ..gap = gap
    ..air = air
    ..lead = lead
    ..textDirection = textDirection;
}

class _StripData extends ContainerBoxParentData<RenderBox> {}

class _RenderStrip extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _StripData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _StripData> {
  _RenderStrip(
    this._keyline,
    this._gap,
    this._air,
    this._lead,
    this._textDirection,
  );

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

  double _lead;
  set lead(double value) {
    if (value == _lead) return;
    _lead = value;
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
    // The room after the keyline, without the keys and with them beside
    // the clock.
    final after = keyline == null ? 0.0 : width - keyline;
    final beside = after - _air - k.width;
    bool fits(double room) => keyline != null && room >= c.width * 5 / 6;
    final onGrid = fits(after);
    final under = onGrid && !fits(beside);
    if (onGrid) {
      final room = under ? after : beside;
      if (room < c.width) c = layout(clock, BoxConstraints(maxWidth: room));
    }
    final room = onGrid
        ? keyline! - _air
        : width - _gap - c.width - _air - k.width;
    final t = layout(words, BoxConstraints(maxWidth: math.max(0, room)));
    final line = [t.height, c.height, if (!under) k.height].reduce(math.max);
    // On their own line the keys hang [lead] under the clock where they
    // keep to its column, and otherwise under the whole line.
    final drop = !under
        ? null
        : (k.width <= after ? (line + c.height) / 2 : line) + _lead;
    final size = constraints.constrain(
      Size(width, drop == null ? line : math.max(line, drop + k.height)),
    );
    Offset place(Size child, double start, [double? top]) => Offset(
      _textDirection == TextDirection.rtl
          ? size.width - start - child.width
          : start,
      top ?? (line - child.height) / 2,
    );
    return (
      size: size,
      at: [
        place(t, 0),
        place(c, onGrid ? keyline! : t.width + _gap),
        place(k, size.width - k.width, drop),
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

/// Its child set [offset] from where it lies, as laid out rather than
/// painted through a layer: an ink correction the page's measures see.
class _Nudge extends SingleChildRenderObjectWidget {
  const _Nudge(this.offset, {required super.child});
  final Offset offset;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderNudge(offset);

  @override
  void updateRenderObject(BuildContext context, _RenderNudge r) =>
      r.offset = offset;
}

class _RenderNudge extends RenderShiftedBox {
  _RenderNudge(this._offset) : super(null);

  Offset _offset;
  set offset(Offset value) {
    if (value == _offset) return;
    _offset = value;
    markNeedsLayout();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      child?.getDryLayout(constraints) ?? constraints.smallest;

  @override
  void performLayout() {
    final child = this.child;
    if (child == null) {
      size = constraints.smallest;
      return;
    }
    child.layout(constraints, parentUsesSize: true);
    size = child.size;
    (child.parentData! as BoxParentData).offset = _offset;
  }
}
