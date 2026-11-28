part of '../stint_frosted.dart';

// Today on glass: the running timer is the record's hero tile, its wash in the
// tracked project's hue; the week's figures and days stand on a plain tile
// beside it; every list stands on one leading slot of the look's 32 marks, so
// project marks, monograms, the timeline's dots and the one icon share a
// centre down a tile and across the page.

/// The leading slot every Today list stands on, and the gap after it.
const double _slot = 32, _slotGap = 12;

/// The columns of the wide page: the timer and the plan on the start side.
const _columns = [6, 5];
const double _columnGap = 20;

extension _Today on _WorkspaceState {
  Widget today() {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return page(
      w.greeting,
      data(
        () => LayoutBuilder(
          builder: (_, box) {
            final width = box.maxWidth / scale;
            final columns = width >= 900 ? _columns : const [1, 1];
            final timer = _timerTile();
            final plan = _planTile(), team = _teamTile();
            final blocks = _blocksTile(), feed = _feedTile();
            final later = _laterTile();
            Widget stack(List<Widget> children) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: _columnGap,
              children: children,
            );
            if (width < 600) {
              // One column in the wide page's reading order: the plan and
              // the days ahead, then the day's blocks, the team and the feed.
              return stack([
                timer,
                _weekTile(),
                plan,
                later,
                blocks,
                team,
                feed,
              ]);
            }
            return stack([
              // The timer beside the week, one plate's height: the reading and
              // the figures on one top line, the acts and the days on one foot.
              _EvenRow(
                flex: columns,
                gap: _columnGap,
                children: [timer, _weekTile(beside: true)],
              ),
              // Under them two columns, each at its own height: today's tasks,
              // its blocks and who is on what; the days ahead and the feed.
              _EvenRow(
                flex: columns,
                gap: _columnGap,
                even: false,
                children: [
                  stack([plan, blocks, team]),
                  stack([later, feed]),
                ],
              ),
            ]);
          },
        ),
      ),
      caption: '${w.today}${_dot(w)}${w.shortDate(studyToday)}',
    );
  }

  // The timer: the reading in a well, the task under it, the two acts filling
  // the tile's width. Beside the week the task takes the slack, so the acts
  // stand on the tile's foot with the week's days.
  Widget _timerTile() {
    final t = glass, type = t.textTheme, ink = t.colorScheme;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final hue = t.hue(projectIndex(task?.project ?? projects.first.id));
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    void pick() => FrostedCommand.show(
      context,
      hintText: w.search,
      commands: [
        for (final item in choices)
          RawCommand(
            label: w.text(item.title),
            group: c.projectName(item.project),
            onPressed: () => c.track(item.id),
          ),
      ],
    );
    // Stopped, the next task waits in a picker beside the act that starts it:
    // the one the reader chose, else the plan's first open task.
    final byId = {for (final item in choices) item.id: item};
    final next =
        byId[queued] ??
        c.todayTasks
            .where((t) => !t.done && byId.containsKey(t.id))
            .firstOrNull ??
        choices.firstOrNull;
    final trackedToday = c.dailyMinutes(
      mondayOf(studyToday),
    )[studyToday.weekday - 1];
    final motion = FrostedMotion.of(context);

    Widget reading(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        label: w.elapsedLabel(value),
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (ctx, box) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              key: const ValueKey('today-timer-digits'),
              textDirection: TextDirection.ltr,
              style: type.displayLarge.tabular.copyWith(
                letterSpacing: 0,
                fontSize:
                    (box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) * .15)
                        .clamp(44.0, 68.0),
                height: 1.1,
                color: active ? ink.textPrimary : ink.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    final readout = _Well(
      key: const ValueKey('today-timer-well'),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Row(
            spacing: 8,
            children: [
              // The live dot: the tracked project's hue while the clock runs,
              // fading to a quiet dot when it stops.
              SizedBox.square(
                key: const ValueKey('today-timer-lamp'),
                dimension: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    DecoratedBox(
                      decoration: ShapeDecoration(
                        shape: const CircleBorder(),
                        color: ink.textTertiary.withValues(alpha: .5),
                      ),
                    ),
                    AnimatedOpacity(
                      opacity: active ? 1 : 0,
                      duration: motion.base,
                      curve: motion.curve,
                      child: DecoratedBox(
                        decoration: ShapeDecoration(
                          shape: const CircleBorder(),
                          gradient: hue.band,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Text(
                  active ? w.runningTimer : w.stoppedTimer,
                  key: const ValueKey('today-timer-label'),
                  style: type.labelMedium.copyWith(
                    color: active ? hue.ink : ink.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          timer == null
              ? reading(c.repository.now())
              : StreamBuilder<DateTime>(
                  stream: c.ticks(const Duration(seconds: 1)),
                  initialData: c.repository.now(),
                  builder: (_, snapshot) => reading(snapshot.data!),
                ),
          Text(
            timer == null ? w.notTracking : w.since(timer.start),
            style: type.bodySmall,
          ),
        ],
      ),
    );

    final about = AnimatedSwitcher(
      duration: motion.base,
      switchInCurve: motion.curve,
      switchOutCurve: motion.curve,
      layoutBuilder: (current, previous) => Stack(
        alignment: AlignmentDirectional.topStart,
        children: [...previous, ?current],
      ),
      // Stopped, the picker names what to do; the line speaks only when
      // there is nothing to start.
      child: active
          ? Row(
              key: ValueKey(task.id),
              spacing: _slotGap,
              children: [
                projectMark(task.project),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        w.text(task.title),
                        key: const ValueKey('today-timer-title'),
                        style: type.titleLarge,
                      ),
                      Text(c.projectName(task.project), style: type.bodyMedium),
                    ],
                  ),
                ),
              ],
            )
          // Stopped, the tile keeps the day's count where the task stood.
          : Row(
              key: const ValueKey('stopped'),
              spacing: _slotGap,
              children: [
                const FrostedIconMark(
                  LucideIcons.timer,
                  size: FrostedMarkSize.small,
                  quiet: true,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.today, style: type.labelMedium),
                      Text(
                        w.duration(trackedToday),
                        style: type.titleLarge.tabular,
                      ),
                      if (choices.isEmpty)
                        Text(w.noTimerTasks, style: type.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
    );
    final acts = <Widget>[
      if (active) ...[
        FrostedButton(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: LucideIcons.square,
          expand: true,
          onPressed: c.stopTimer,
        ),
        FrostedButton.glass(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          icon: LucideIcons.arrowLeftRight,
          expand: true,
          // A pane of light glass beside the ink act: its lit hairline
          // draws the whole capsule, so the two keys read one width.
          style: FrostedStyle(edge: WidgetStatePropertyAll(t.glass.wellEdge)),
          onPressed: choices.isEmpty ? null : pick,
        ),
      ] else ...[
        // Choosing is glass: the picker is a field's well beside the ink act.
        if (next != null)
          FrostedCombobox<String>(
            key: const ValueKey('today-timer-choice'),
            labelText: w.chooseTask,
            options: [for (final item in choices) item.id],
            displayStringForOption: (id) => w.text(byId[id]!.title),
            value: next.id,
            requireSelection: true,
            onSelected: queue,
          ),
        FrostedButton(
          w.startTimer,
          key: const ValueKey('today-action-last'),
          icon: LucideIcons.play,
          expand: true,
          onPressed: next == null ? null : () => c.track(next.id),
        ),
      ],
    ];
    final buttons = LayoutBuilder(
      builder: (ctx, box) {
        final Widget row;
        if (acts.length == 1) {
          row = acts.single;
        } else if (active) {
          // Stop and Switch share the line as the look's own row of acts
          // does: a key's word and glyph may take its inset down to the
          // face's floor, still centred, and the two stack only when a word
          // would not stand whole in its half. Guessed from the label's
          // type with the whole inset, the rule sat within two pixels of a
          // 390 phone's half, and the palettes' tracking (0 to 0.2 a
          // letter) tipped it: opal side by side, the other five stacked.
          row = StintPair(
            first: _WholeWords(child: acts.first),
            second: _WholeWords(child: acts.last),
            spacing: 10,
          );
        } else if ((box.maxWidth - 10) / 2 <
                TextPainter.computeWidth(
                      text: TextSpan(
                        text: w.startTimer,
                        style: type.labelLarge,
                      ),
                      textDirection: Directionality.of(ctx),
                      textScaler: MediaQuery.textScalerOf(ctx),
                    ) +
                    72 ||
            // The picker holds a task's title: under 200 it would hold a
            // fragment, so it takes the row and the act goes under it.
            (!active && (box.maxWidth - 10) / 2 < 200)) {
          row = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 10,
            children: acts,
          );
        } else {
          // The picker's name stands over its well, so the well and the act
          // share a foot.
          row = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 10,
            children: [for (final act in acts) Expanded(child: act)],
          );
        }
        // The acts change places in a cross-fade.
        return AnimatedSwitcher(
          duration: motion.base,
          switchInCurve: motion.curve,
          switchOutCurve: motion.curve,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(key: ValueKey(active), child: row),
        );
      },
    );
    return FrostedCard.record(
      key: const ValueKey('today-timer-card'),
      hue: hue,
      child: _Fill(spacing: 18, grow: 1, children: [readout, about, buttons]),
    );
  }

  // The week: the open tasks and the hours as two equal figures over the
  // days, which take the height left.
  Widget _weekTile({bool beside = false}) {
    final t = glass, type = t.textTheme;
    final week = mondayOf(studyToday);
    Widget figure(String key, String label, String value) => Expanded(
      child: Semantics(
        container: true,
        label: '$label, $value',
        excludeSemantics: true,
        child: _Well(
          key: ValueKey(key),
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              Text(label, style: type.labelMedium),
              Text(value, style: type.titleLarge.tabular),
            ],
          ),
        ),
      ),
    );
    final count = w.number(c.openTasks.length);
    final hours = w.duration(c.totalMinutes(week));
    final figures = [
      figure('today-stat-tasks', w.openTasks, count),
      figure('today-stat-hours', w.hoursThisWeek, hours),
    ];
    // The widest word a figure holds, with its padding.
    double need(BuildContext ctx) {
      double measure(String text, TextStyle style) => TextPainter.computeWidth(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(ctx),
        textScaler: MediaQuery.textScalerOf(ctx),
      );
      return [
            measure(w.openTasks, type.labelMedium),
            measure(w.hoursThisWeek, type.labelMedium),
            measure(count, type.titleLarge.tabular),
            measure(hours, type.titleLarge.tabular),
          ].reduce(math.max) +
          28;
    }

    return FrostedCard(
      key: const ValueKey('today-week'),
      child: _Fill(
        spacing: 12,
        grow: 1,
        children: [
          LayoutBuilder(
            // Side by side, each wrapping inside its own face; stacked only
            // when enlarged type would cut one.
            builder: (ctx, box) =>
                MediaQuery.textScalerOf(ctx).scale(1) > 1 &&
                    (box.maxWidth - 12) / 2 < need(ctx)
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 12,
                    children: [
                      for (final f in figures) Row(children: [f]),
                    ],
                  )
                : Row(spacing: 12, children: figures),
          ),
          _DayBars(
            key: const ValueKey('today-chart'),
            minutes: c.dailyMinutes(week),
            days: [for (var i = 0; i < 7; i++) addDays(week, i)],
            today: studyToday.weekday - 1,
            words: w,
            hue: t.hues.iris,
            natural: beside ? 96 : 150,
          ),
        ],
      ),
    );
  }

  Widget _tile(String key, String title, Widget body, {Widget? end}) =>
      FrostedCard(
        key: ValueKey(key),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Row(
              children: [
                Expanded(child: FrostedCardHeader(title)),
                ?end,
              ],
            ),
            body,
          ],
        ),
      );

  Widget _planTile() {
    final tasks = c.todayTasks;
    final done = tasks.where((t) => t.done).length;
    return _tile(
      'today-plan',
      w.todaysPlan,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tasks.isEmpty)
            _Line(
              lead: FrostedIconMark(
                LucideIcons.calendarCheck,
                size: FrostedMarkSize.small,
                quiet: true,
              ),
              title: w.noTasksToday,
            ),
          for (final task in tasks)
            _Line(
              key: ValueKey('plan-${task.id}'),
              lead: KeyedSubtree(
                key: ValueKey('today-plan-lead-${task.id}'),
                child: projectMark(task.project),
              ),
              title: w.text(task.title),
              meta: c.projectName(task.project),
              // The task the timer runs on says so as the timer does: its
              // live dot in the project's hue, and the words in its ink.
              live: c.data.timer?.taskId == task.id
                  ? _LiveMark(
                      key: const ValueKey('today-plan-running'),
                      hue: context.frostedTheme.hue(projectIndex(task.project)),
                      label: w.runningTimer,
                    )
                  : null,
              spoken: c.data.timer?.taskId == task.id ? w.runningTimer : null,
              done: task.done,
              checked: task.done,
              onPressed: () => c.changeTasks([task.id], done: !task.done),
            ),
          _Line(
            key: const ValueKey('today-plan-all'),
            lead: FrostedIconMark(
              LucideIcons.listChecks,
              key: const ValueKey('today-plan-lead-all'),
              size: FrostedMarkSize.small,
              quiet: true,
            ),
            title: w.viewTasks,
            meta: tasks.isEmpty ? null : w.progress(done, tasks.length),
            end: SizedBox(
              width: FrostedChromeMetrics.check,
              child: Icon(
                LucideIcons.chevronRightDir,
                size: 18,
                color: glass.colorScheme.textSecondary,
              ),
            ),
            onPressed: () => go(Place.tasks),
          ),
        ],
      ),
    );
  }

  Widget _teamTile() => _tile(
    'today-team',
    w.teamActivity,
    Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, person) in team.indexed)
          Builder(
            builder: (_) {
              final name = w.text(person.name), task = c.currentTask(person.id);
              return _Line(
                lead: FrostedMonogram(
                  name,
                  key: ValueKey('today-team-lead-${person.id}'),
                  hue: glass.hue(i + 2),
                  size: FrostedMarkSize.small,
                ),
                title: name,
                meta: task == null ? w.notTracking : w.text(task.title),
              );
            },
          ),
      ],
    ),
  );

  Widget _blocksTile() {
    final blocks = c.todayBlocks;
    return _tile(
      'today-blocks',
      w.timeBlocks,
      blocks.isEmpty
          ? Text(w.noBlocks, style: glass.textTheme.bodyMedium)
          : _Timeline(
              section: 'blocks',
              label: w.timeBlocks,
              stops: [
                for (final e in blocks)
                  (
                    title: w.text(e.note),
                    meta:
                        '${c.projectName(e.project)}${_dot(w)}${w.duration(e.end - e.start)}',
                    time: w.timeRange(e),
                    hue: glass.hue(projectIndex(e.project)),
                    current: false,
                  ),
              ],
            ),
    );
  }

  Widget _feedTile() => _tile(
    'today-activity',
    w.recentActivity,
    StreamBuilder<DateTime>(
      stream: c.ticks(const Duration(minutes: 1)),
      initialData: c.repository.now(),
      builder: (_, now) => c.data.activity.isEmpty
          ? Text(w.noActivity, style: glass.textTheme.bodyMedium)
          : _Timeline(
              section: 'feed',
              label: w.recentActivity,
              stops: [
                for (final (i, e) in c.data.activity.indexed)
                  (
                    title: w.eventAction(e, c.personName(e.person)),
                    meta: w.text(e.subject),
                    time: w.timeAgo(e.at, now.data!),
                    hue: glass.hue(
                      team.indexWhere((p) => p.id == e.person) + 2,
                    ),
                    current: i == 0,
                  ),
              ],
            ),
    ),
  );

  Widget _laterTile() {
    final later = c.laterThisWeek;
    return _tile(
      'today-later',
      w.laterThisWeek,
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (later.isEmpty)
            _Line(
              lead: FrostedIconMark(
                LucideIcons.calendarCheck,
                size: FrostedMarkSize.small,
                quiet: true,
              ),
              title: w.allClear,
            ),
          for (final task in later)
            _Line(
              lead: KeyedSubtree(
                key: ValueKey('today-later-lead-${task.id}'),
                child: projectMark(task.project),
              ),
              title: w.text(task.title),
              meta: c.projectName(task.project),
              end: Text(
                w.weekday(task.due),
                style: glass.textTheme.bodySmall.tabular,
              ),
              endFolds: true,
              onPressed: () => open(task),
            ),
        ],
      ),
    );
  }
}

/// A column whose [grow] child takes the height left when the column is
/// given a height, and stands at its own height when it isn't.
class _Fill extends StatelessWidget {
  const _Fill({required this.children, required this.grow, this.spacing = 0});
  final List<Widget> children;
  final int grow;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: box.hasBoundedHeight ? MainAxisSize.max : MainAxisSize.min,
      spacing: spacing,
      children: [
        for (final (i, child) in children.indexed)
          i == grow
              ? Flexible(
                  flex: box.hasBoundedHeight ? 1 : 0,
                  fit: FlexFit.tight,
                  child: child,
                )
              : child,
      ],
    ),
  );
}

/// One Today row: its mark centred in the leading slot, its words on the
/// title edge after it, an optional end. With [onPressed] the whole row is
/// one target; with [checked] it is a check row, its check at the end as the
/// look's check rows keep it.
class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.lead,
    required this.title,
    this.meta,
    this.end,
    this.live,
    this.spoken,
    this.onPressed,
    this.checked,
    this.done = false,
    this.endFolds = false,
  });
  final Widget lead;
  final String title;
  final String? meta;
  final Widget? end;

  /// A mark set after [meta] on its line, folding under it when the line is
  /// full: the timer's dot and words on the task it runs on.
  final Widget? live;

  /// What [end] or [live] says to a screen reader, after the words.
  final String? spoken;

  /// Whether large type folds [end] under the words, so the title keeps the
  /// row's width.
  final bool endFolds;
  final VoidCallback? onPressed;
  final bool? checked;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme, ink = t.colorScheme;
    final motion = FrostedMotion.of(context);
    final checked = this.checked;
    final folds =
        end != null &&
        endFolds &&
        MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: _slot,
              child: Center(child: lead),
            ),
            const SizedBox(width: _slotGap),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: motion.base,
                    curve: motion.curve,
                    style: t.textTheme.titleMedium.copyWith(
                      color: done ? ink.textSecondary : ink.textPrimary,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: ink.textSecondary,
                    ),
                    child: Text(title),
                  ),
                  if (meta != null && live != null)
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(meta!, style: t.textTheme.bodyMedium),
                        live!,
                      ],
                    )
                  else if (meta != null)
                    Text(meta!, style: t.textTheme.bodyMedium),
                  if (folds) end!,
                ],
              ),
            ),
            if (end != null && !folds) ...[const SizedBox(width: 12), end!],
            if (checked != null) ...[
              const SizedBox(width: 12),
              // The check is the row's picture: the row is the control.
              // The kit stands the disc on the start of its target; the
              // picture keeps the disc alone so the end column shares a
              // centre with the row that opens the list.
              SizedBox.square(
                dimension: FrostedChromeMetrics.check,
                child: OverflowBox(
                  maxWidth: 64,
                  maxHeight: 64,
                  alignment: AlignmentDirectional.centerStart,
                  child: ExcludeFocus(
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: FrostedCheckbox(
                          value: checked,
                          semanticLabel: title,
                          onChanged: (_) {},
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
    if (onPressed == null) return MergeSemantics(child: row);
    return FrostedPressable(
      onPressed: onPressed,
      role: checked == null ? FrostedPressRole.link : FrostedPressRole.control,
      checked: checked,
      semanticLabel: [title, ?meta, ?spoken].join(', '),
      radius: FrostedCorners.r10,
      ringInsets: const EdgeInsets.symmetric(horizontal: -8),
      ringInside: true,
      child: row,
    );
  }
}

/// The timer's live dot and words, as the readout's header draws them, set on
/// a plan row's second line.
class _LiveMark extends StatelessWidget {
  const _LiveMark({super.key, required this.hue, required this.label});
  final FrostedHue hue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    return Text.rich(
      TextSpan(
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(end: 6),
              child: SizedBox.square(
                dimension: 8,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: const CircleBorder(),
                    gradient: hue.band,
                  ),
                ),
              ),
            ),
          ),
          TextSpan(text: label),
        ],
      ),
      // The meta line's own size and weight, in the project's ink: the words
      // stand level with the project's name, by day and by night.
      style: t.textTheme.bodyMedium.copyWith(color: hue.ink),
    );
  }
}

typedef _Stop = ({
  String title,
  String meta,
  String time,
  FrostedHue hue,
  bool current,
});

/// The look's timeline on Today's leading slot and in its rows' rhythm: a
/// hairline down the slot's middle joining a dot in each moment's hue, the
/// words after it on the title edge and the time at the row's end. The
/// current moment's words stand a weight heavier.
class _Timeline extends StatelessWidget {
  const _Timeline({
    required this.section,
    required this.label,
    required this.stops,
  });
  final String section, label;
  final List<_Stop> stops;

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme, type = t.textTheme;
    const dot = 10.0;
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      child: LayoutBuilder(
        builder: (context, box) {
          final under = _timesUnder(
            context,
            box.maxWidth,
            [for (final stop in stops) (stop.title, stop.time)],
            type.titleMedium.semibold,
            type.bodySmall.tabular,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, stop) in stops.indexed)
                Semantics(
                  container: true,
                  label: [stop.title, stop.meta, stop.time].join(', '),
                  selected: stop.current,
                  excludeSemantics: true,
                  child: CustomPaint(
                    painter: _RailPainter(
                      line: t.colorScheme.border,
                      above: i > 0,
                      below: i < stops.length - 1,
                      clear: dot / 2 + 3,
                      rtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 56),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            SizedBox(
                              width: _slot,
                              child: Center(
                                child: SizedBox.square(
                                  key: ValueKey('today-$section-lead-$i'),
                                  dimension: dot,
                                  child: DecoratedBox(
                                    decoration: ShapeDecoration(
                                      shape: const CircleBorder(),
                                      color: _figure(stop.hue, .6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: _slotGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    stop.title,
                                    style: stop.current
                                        ? type.titleMedium.semibold
                                        : type.titleMedium,
                                  ),
                                  Text(stop.meta, style: type.bodyMedium),
                                  if (under)
                                    Text(
                                      stop.time,
                                      style: type.bodySmall.tabular,
                                    ),
                                ],
                              ),
                            ),
                            if (!under) ...[
                              const SizedBox(width: 12),
                              Text(stop.time, style: type.bodySmall.tabular),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// Whether a timeline's times stand under its words: when a title would
/// wrap only because its time stands beside it, every time goes under, so
/// the rows keep one shape.
bool _timesUnder(
  BuildContext context,
  double width,
  Iterable<(String, String)> rows,
  TextStyle title,
  TextStyle time,
) {
  final scaler = MediaQuery.textScalerOf(context);
  final direction = Directionality.of(context);
  double measure(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: direction,
      textScaler: scaler,
      maxLines: 1,
    )..layout();
    final size = painter.width;
    painter.dispose();
    return size;
  }

  final words = width - _slot - _slotGap;
  return rows.any(
    (row) => measure(row.$1, title) + 12 + measure(row.$2, time) > words,
  );
}

class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.line,
    required this.above,
    required this.below,
    required this.clear,
    required this.rtl,
  });
  final Color line;
  final bool above, below, rtl;
  final double clear;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (rtl ? size.width - _slot / 2 : _slot / 2).roundToDouble() + .5;
    final mid = size.height / 2;
    final paint = Paint()
      ..color = line
      ..strokeWidth = 1;
    if (above) canvas.drawLine(Offset(x, 0), Offset(x, mid - clear), paint);
    if (below) {
      canvas.drawLine(Offset(x, mid + clear), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.line != line ||
      old.above != above ||
      old.below != below ||
      old.clear != clear ||
      old.rtl != rtl;
}

/// The week's days as pill bars of one hue's light: today's in its full light,
/// the days before at less, the days to come a faint dot on the floor. Every
/// day keeps its slot, its name centred under it: the short name while it
/// fits, its letter when it doesn't. Unbounded, it stands [natural] tall;
/// given a height, it fills it.
class _DayBars extends StatefulWidget {
  const _DayBars({
    super.key,
    required this.minutes,
    required this.days,
    required this.today,
    required this.words,
    required this.hue,
    required this.natural,
  });
  final List<int> minutes;
  final List<DateTime> days;
  final int today;
  final StintWords words;
  final FrostedHue hue;
  final double natural;

  @override
  State<_DayBars> createState() => _DayBarsState();
}

class _DayBarsState extends State<_DayBars>
    with SingleTickerProviderStateMixin {
  late final grow = AnimationController(vsync: this, value: 1);
  late List<double> from = _values, to = _values;
  List<double> get _values => [for (final m in widget.minutes) m / 60];

  @override
  void didUpdateWidget(_DayBars old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.minutes, widget.minutes)) {
      final motion = FrostedMotion.of(context);
      from = [
        for (var i = 0; i < 7; i++)
          lerpDouble(from[i], to[i], motion.curve.transform(grow.value))!,
      ];
      to = _values;
      grow
        ..duration = motion.slow
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    grow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme, w = widget.words;
    final scaler = MediaQuery.textScalerOf(context);
    final style = t.textTheme.labelSmall;
    final motion = FrostedMotion.of(context);
    const inset = EdgeInsets.fromLTRB(10, 14, 10, 10);
    return LayoutBuilder(
      builder: (ctx, box) {
        final slot = (box.maxWidth - inset.horizontal - 2) / 7;
        double measure(String text) => TextPainter.computeWidth(
          text: TextSpan(text: text, style: style),
          textDirection: Directionality.of(ctx),
          textScaler: scaler,
        );
        final narrow = widget.days.any(
          (d) => measure(w.weekdayShort(d)) > slot - 6,
        );
        final labels = [
          for (final d in widget.days)
            narrow ? w.weekdayNarrow(d) : w.weekdayShort(d),
        ];
        final height = box.hasBoundedHeight
            ? box.maxHeight
            : widget.natural * scaler.scale(1).clamp(1.0, 1.4);
        return Semantics(
          container: true,
          label: [
            w.hoursThisWeek,
            for (var i = 0; i < 7; i++)
              '${w.weekday(widget.days[i])} ${w.duration(widget.minutes[i])}',
          ].join(', '),
          excludeSemantics: true,
          child: SizedBox(
            height: height,
            child: _Well(
              padding: inset,
              child: AnimatedBuilder(
                animation: grow,
                builder: (_, _) {
                  final values = [
                    for (var i = 0; i < 7; i++)
                      lerpDouble(
                        from[i],
                        to[i],
                        motion.curve.transform(grow.value),
                      )!,
                  ];
                  final top = values.fold<double>(1, math.max);
                  // Each day a slot of its own, its mark over its name, so
                  // the two share a centre in either direction.
                  return Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            spacing: 8,
                            children: [
                              Expanded(
                                child: CustomPaint(
                                  key: ValueKey('today-day-slot-$i'),
                                  size: Size.infinite,
                                  painter: _BarPainter(
                                    hue: widget.hue,
                                    floor: t.colorScheme.border,
                                    empty: t.colorScheme.textTertiary,
                                    value: values[i],
                                    top: top,
                                    lit: i == widget.today,
                                  ),
                                ),
                              ),
                              Text(
                                labels[i],
                                key: ValueKey('today-day-label-$i'),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: i == widget.today
                                    ? style.copyWith(
                                        color: t.colorScheme.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      )
                                    : style,
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

/// One day's mark: a pill bar of the hue's light (today's in full, the days
/// before at half) or, with nothing logged, a faint dot, over its share of
/// the floor's hairline.
class _BarPainter extends CustomPainter {
  const _BarPainter({
    required this.hue,
    required this.floor,
    required this.empty,
    required this.value,
    required this.top,
    required this.lit,
  });
  final FrostedHue hue;
  final Color floor, empty;
  final double value, top;
  final bool lit;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = math.min(size.width * .46, 22.0);
    final cx = size.width / 2;
    canvas.drawLine(
      Offset(0, size.height - .5),
      Offset(size.width, size.height - .5),
      Paint()..color = floor,
    );
    if (value <= 0) {
      canvas.drawCircle(
        Offset(cx, size.height - 4),
        2.5,
        Paint()..color = empty.withValues(alpha: .45),
      );
      return;
    }
    final h = math.max(bar, (size.height - 2) * value / top);
    final rect = Rect.fromLTWH(cx - bar / 2, size.height - 2 - h, bar, h);
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(bar / 2)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: lit
              ? [_figure(hue, .8), hue.ink]
              : [_figure(hue, .55), _figure(hue, .6)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.hue != hue ||
      old.floor != floor ||
      old.empty != empty ||
      old.value != value ||
      old.top != top ||
      old.lit != lit;
}

/// Tiles side by side on the page's columns. Each is laid out at its column's
/// width, and with [even] all of them then take the tallest one's height, so a
/// row of tiles shares a top and a foot. A tile given that height can hand the
/// slack to a part of its own (the timer's words, the week's days).
class _EvenRow extends MultiChildRenderObjectWidget {
  const _EvenRow({
    required this.flex,
    required this.gap,
    this.even = true,
    required super.children,
  });
  final List<int> flex;
  final double gap;
  final bool even;

  @override
  _RenderEvenRow createRenderObject(BuildContext context) =>
      _RenderEvenRow(flex, gap, even, Directionality.of(context));

  // A card given the row's height lays out as its own boundary, so a card
  // that grows (a new time block) never tells the row. Each rebuild of the
  // page measures the row again.
  @override
  void updateRenderObject(BuildContext context, _RenderEvenRow row) => row
    ..flex = flex
    ..gap = gap
    ..even = even
    ..direction = Directionality.of(context)
    ..markNeedsLayout();
}

class _EvenRowData extends ContainerBoxParentData<RenderBox> {}

class _RenderEvenRow extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EvenRowData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EvenRowData> {
  _RenderEvenRow(this._flex, this._gap, this._even, this._direction);

  List<int> _flex;
  set flex(List<int> value) {
    if (listEquals(value, _flex)) return;
    _flex = value;
    markNeedsLayout();
  }

  double _gap;
  set gap(double value) {
    if (value == _gap) return;
    _gap = value;
    markNeedsLayout();
  }

  bool _even;
  set even(bool value) {
    if (value == _even) return;
    _even = value;
    markNeedsLayout();
  }

  TextDirection _direction;
  set direction(TextDirection value) {
    if (value == _direction) return;
    _direction = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EvenRowData) child.parentData = _EvenRowData();
  }

  List<double> _widths(double width) {
    final total = _flex.fold<int>(0, (a, b) => a + b);
    final room = width - _gap * (_flex.length - 1);
    // Whole pixels, so a tile's edge never lands between two.
    final widths = [for (final f in _flex) (room * f / total).floorToDouble()];
    widths[0] += room - widths.fold<double>(0, (a, b) => a + b);
    return widths;
  }

  @override
  double computeMinIntrinsicHeight(double width) {
    final widths = _widths(width);
    var tallest = 0.0, i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      tallest = math.max(tallest, child.getMinIntrinsicHeight(widths[i++]));
    }
    return tallest;
  }

  @override
  double computeMaxIntrinsicHeight(double width) =>
      computeMinIntrinsicHeight(width);

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final widths = _widths(constraints.maxWidth);
    var tallest = 0.0, i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      tallest = math.max(
        tallest,
        child.getDryLayout(BoxConstraints.tightFor(width: widths[i++])).height,
      );
    }
    return constraints.constrain(Size(constraints.maxWidth, tallest));
  }

  @override
  void performLayout() {
    final width = constraints.maxWidth;
    final widths = _widths(width);
    var tallest = 0.0, i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      child.layout(
        BoxConstraints.tightFor(width: widths[i++]),
        parentUsesSize: true,
      );
      tallest = math.max(tallest, child.size.height);
    }
    var x = 0.0;
    i = 0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      if (_even) {
        child.layout(
          BoxConstraints.tightFor(width: widths[i], height: tallest),
          parentUsesSize: true,
        );
      }
      (child.parentData! as _EvenRowData).offset = Offset(
        _direction == TextDirection.rtl ? width - x - widths[i] : x,
        0,
      );
      x += widths[i++] + _gap;
    }
    size = constraints.constrain(Size(width, tallest));
  }

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

/// A figure's well: the look's recessed glass, a step darker than its tile
/// with a shade along its top inside edge, and the lit rim a field's well
/// wears round it.
class _Well extends StatelessWidget {
  const _Well({super.key, required this.padding, required this.child});
  final EdgeInsets padding;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final t = context.frostedTheme;
    final corner = BorderRadius.circular(FrostedCorners.r14);
    return DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        border: Border.all(color: t.glass.wellEdge),
        borderRadius: corner,
      ),
      child: FrostedSurface(
        material: FrostedMaterial.well,
        borderRadius: corner,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// A hue's mark as a figure: [ink] of the way from its pastel to its ink.
Color _figure(FrostedHue hue, double ink) => Color.lerp(hue.a, hue.ink, ink)!;

/// The mark between two facts on one line: a middle dot, or in Arabic the
/// comma, as a dot beside Arabic figures reads as a zero.
String _dot(StintWords w) => w.arabic ? '، ' : ' · ';

/// Hands a [StintPair] its key's least width with the words whole: the
/// word and glyph and the face's floor either side, the inset spilled (a
/// [FrostedButton]'s least intrinsic width), so the pair sets the keys side
/// by side wherever the look's own row of acts would.
class _WholeWords extends SingleChildRenderObjectWidget {
  const _WholeWords({required super.child});

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderWholeWords();
}

class _RenderWholeWords extends RenderProxyBox {
  @override
  double computeMaxIntrinsicWidth(double height) =>
      super.computeMinIntrinsicWidth(height);
}
