part of '../stint_neumorphism.dart';

// Today in plaster: the running timer is a raised slab with its reading pressed
// into a well, the week's figures and days sit in wells beside it, and every
// list stands on one leading slot, so checks, marks, icons and the timeline's
// dots share a centre down a card and across the page.

/// The leading slot every Today list stands on, and the gap after it.
const double _slot = 44, _slotGap = 14;

/// The columns of the wide page: the timer and the plan on the start side.
const _columns = [6, 5];
const double _columnGap = 26;

extension _Today on _WorkspaceState {
  Widget today() {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return NeumorphicScaffold(
      topBar: NeumorphicAppBar(
        title: w.greeting,
        subtitle:
            '${w.weekday(studyToday)}${_dot(w)}${w.shortDate(studyToday)}',
        actions: [command],
      ),
      body: data(
        () => LayoutBuilder(
          builder: (_, box) {
            final width = box.maxWidth / scale;
            // Two even columns on a tablet; the timer's side leads on a desktop.
            final columns = width >= 900 ? _columns : const [1, 1];
            final timer = _timerCard();
            final plan = _planCard();
            final team = _teamCard(), blocks = _blocksCard();
            final feed = _feedCard(), later = _laterCard();
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
                _weekCard(),
                plan,
                later,
                blocks,
                team,
                feed,
              ]);
            }
            return stack([
              // The timer beside the week, one slab's height: the reading's
              // well and the figures on one top line, the acts and the days on
              // one foot.
              _EvenRow(
                flex: columns,
                gap: _columnGap,
                children: [timer, _weekCard(beside: true)],
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
    );
  }

  // The timer: its reading in a well, the task under it, the two acts filling
  // the slab's width. Beside the week the task takes the slack, so the acts
  // stand on the slab's foot with the week's chart.
  Widget _timerCard() {
    final t = plaster, colors = t.colors, type = t.textTheme;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    void pick() => showNeumorphicCommand(
      context,
      hint: w.search,
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
    final motion = NeumorphicMotion.of(context);

    Widget reading(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        label: w.elapsedLabel(value),
        excludeSemantics: true,
        child: LayoutBuilder(
          // The reading grows with its well, from the look's figure up to half
          // again, so a wide well holds a reading and not a strip of floor.
          builder: (ctx, box) => FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              value,
              key: const ValueKey('today-timer-digits'),
              textDirection: TextDirection.ltr,
              style: type.figure.tabular.copyWith(
                fontSize:
                    (box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) * .15)
                        .clamp(48.0, 72.0),
                height: 1.1,
                color: active ? colors.ink : colors.inkTertiary,
              ),
            ),
          ),
        ),
      );
    }

    final well = NeumorphicWell(
      key: const ValueKey('today-timer-well'),
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 4,
        children: [
          Row(
            children: [
              // The LED lights while the clock runs; off, its lamp stays as a
              // quiet dot, so the words keep their place and the eye its mark.
              // The Latin label's ink sits below its line's centre, so the lamp
              // steps down to meet it.
              Transform.translate(
                offset: Offset(
                  0,
                  w.arabic ? 0 : MediaQuery.textScalerOf(context).scale(2),
                ),
                child: SizedBox.square(
                  key: const ValueKey('today-timer-lamp'),
                  dimension: 10,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 8,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.quiet,
                          ),
                        ),
                      ),
                      AnimatedOpacity(
                        opacity: active ? 1 : 0,
                        duration: motion.state,
                        child: const NeumorphicLed(size: 8),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  active ? w.runningTimer : w.stoppedTimer,
                  key: const ValueKey('today-timer-label'),
                  style: type.micro.copyWith(
                    color: active ? colors.accentInk : colors.inkTertiary,
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
            style: type.caption,
          ),
        ],
      ),
    );
    final about = Align(
      alignment: AlignmentDirectional.topStart,
      child: AnimatedSwitcher(
        duration: motion.move,
        switchInCurve: motion.enter,
        switchOutCurve: motion.exit,
        layoutBuilder: (current, previous) => Stack(
          alignment: AlignmentDirectional.topStart,
          children: [...previous, ?current],
        ),
        child: Column(
          key: ValueKey(task?.id),
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 2,
          children: [
            // Stopped, the picker names what to do; the line speaks only when
            // there is nothing to start.
            if (active) ...[
              Text(
                w.text(task.title),
                key: const ValueKey('today-timer-title'),
                style: type.value,
              ),
              Text(c.projectName(task.project), style: type.caption),
            ] else ...[
              // Stopped, the slab keeps the day's count where the task stood.
              Text(w.today, style: type.micro),
              Text(w.duration(trackedToday), style: type.value.tabular),
              if (choices.isEmpty) Text(w.noTimerTasks, style: type.caption),
            ],
          ],
        ),
      ),
    );
    final acts = <Widget>[
      if (active) ...[
        NeumorphicButton.filled(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: LucideIcons.square,
          wide: true,
          alignment: AlignmentDirectional.center,
          onPressed: c.stopTimer,
        ),
        NeumorphicButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          icon: LucideIcons.arrowLeftRight,
          wide: true,
          alignment: AlignmentDirectional.center,
          onPressed: choices.isEmpty ? null : pick,
        ),
      ] else ...[
        // A field to choose in is pressed in: the plaster's place to type.
        if (next != null)
          NeumorphicCombobox<String>(
            key: const ValueKey('today-timer-choice'),
            labelText: w.chooseTask,
            options: [for (final item in choices) item.id],
            displayStringForOption: (id) => w.text(byId[id]!.title),
            value: next.id,
            requireSelection: true,
            onSelected: queue,
          ),
        NeumorphicButton.filled(
          w.startTimer,
          key: const ValueKey('today-action-last'),
          icon: LucideIcons.play,
          wide: true,
          alignment: AlignmentDirectional.center,
          onPressed: next == null ? null : () => c.track(next.id),
        ),
      ],
    ];
    final buttons = LayoutBuilder(
      builder: (ctx, box) {
        // Two parts share the slab's width until either label would wrap.
        final style = type.body.copyWith(fontWeight: FontWeight.w600);
        final need = [
          for (final label in [w.stopTimer, w.switchTask, w.startTimer])
            TextPainter.computeWidth(
              text: TextSpan(text: label, style: style),
              textDirection: Directionality.of(ctx),
              textScaler: MediaQuery.textScalerOf(ctx),
            ),
        ].reduce(math.max);
        final Widget row;
        if (acts.length == 1) {
          row = acts.single;
        } else if ((box.maxWidth - 12) / 2 < need + 64 ||
            // The picker holds a task's title: under 200 it would hold a
            // fragment, so it takes the row and the act goes under it.
            (!active && (box.maxWidth - 12) / 2 < 200)) {
          row = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: acts,
          );
        } else {
          // The picker's name stands over its field, so the field and the
          // act share a foot.
          row = Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: 12,
            children: [for (final act in acts) Expanded(child: act)],
          );
        }
        // The acts change places in a cross-fade.
        return AnimatedSwitcher(
          duration: motion.state,
          layoutBuilder: (current, previous) => Stack(
            alignment: AlignmentDirectional.bottomStart,
            children: [...previous, ?current],
          ),
          child: KeyedSubtree(key: ValueKey(active), child: row),
        );
      },
    );
    return NeumorphicCard(
      key: const ValueKey('today-timer-card'),
      children: [
        well,
        NeumorphicGrow(child: about),
        buttons,
      ],
    );
  }

  // The week: the open tasks and the hours as two equal readouts in wells over
  // the days, which take the height left.
  Widget _weekCard({bool beside = false}) {
    final type = plaster.textTheme;
    final week = mondayOf(studyToday);
    Widget readout(String key, String label, String value, String spoken) =>
        Expanded(
          child: Semantics(
            container: true,
            label: spoken,
            excludeSemantics: true,
            child: NeumorphicWell(
              key: ValueKey(key),
              small: true,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 2,
                children: [
                  Text(label, style: type.micro),
                  Text(value, style: type.value.tabular),
                ],
              ),
            ),
          ),
        );
    final count = w.number(c.openTasks.length);
    final hours = w.duration(c.totalMinutes(week));
    final readouts = [
      readout('today-stat-tasks', w.openTasks, count, '${w.openTasks}, $count'),
      readout(
        'today-stat-hours',
        w.hoursThisWeek,
        hours,
        '${w.hoursThisWeek}, $hours',
      ),
    ];
    // The widest word a readout holds, with its padding.
    double need(BuildContext ctx) {
      double measure(String text, TextStyle style) => TextPainter.computeWidth(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(ctx),
        textScaler: MediaQuery.textScalerOf(ctx),
      );
      return [
            measure(w.openTasks, type.micro),
            measure(w.hoursThisWeek, type.micro),
            measure(count, type.value.tabular),
            measure(hours, type.value.tabular),
          ].reduce(math.max) +
          28;
    }

    return NeumorphicCard(
      key: const ValueKey('today-week'),
      gap: 12,
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
                    for (final r in readouts) Row(children: [r]),
                  ],
                )
              : Row(spacing: 12, children: readouts),
        ),
        NeumorphicGrow(
          child: _DayColumns(
            key: const ValueKey('today-chart'),
            minutes: c.dailyMinutes(week),
            days: [for (var i = 0; i < 7; i++) addDays(week, i)],
            today: studyToday.weekday - 1,
            words: w,
            natural: beside ? 96 : 150,
          ),
        ),
      ],
    );
  }

  Widget _planCard() {
    final tasks = c.todayTasks;
    final done = tasks.where((t) => t.done).length;
    return NeumorphicCard(
      key: const ValueKey('today-plan'),
      title: w.todaysPlan,
      children: [
        _Rows([
          if (tasks.isEmpty)
            _Line(
              lead: const Icon(LucideIcons.calendarCheck, size: 20),
              title: w.noTasksToday,
            ),
          for (final task in tasks) _planRow(task),
          _Line(
            key: const ValueKey('today-plan-all'),
            lead: const Icon(
              LucideIcons.listChecks,
              key: ValueKey('today-plan-lead-all'),
              size: 20,
            ),
            title: w.viewTasks,
            note: tasks.isEmpty ? null : w.progress(done, tasks.length),
            onPressed: () => go(Place.tasks),
          ),
        ]),
      ],
    );
  }

  Widget _planRow(Task task) {
    return _Line(
      key: ValueKey('plan-${task.id}'),
      checked: task.done,
      // The check is the row's picture: the row is the one control, and the
      // check moves in its own motion.
      // The kit stands a check's face on the start of its target; the
      // picture keeps the face alone so it centres on the slot, the target
      // reaching on past it unseen.
      lead: SizedBox.square(
        dimension: 28,
        child: OverflowBox(
          maxWidth: 64,
          maxHeight: 64,
          alignment: AlignmentDirectional.centerStart,
          child: KeyedSubtree(
            key: ValueKey('today-plan-lead-${task.id}'),
            child: ExcludeFocus(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: NeumorphicRoundCheckbox(
                    value: task.done,
                    onChanged: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      title: w.text(task.title),
      note: c.projectName(task.project),
      done: task.done,
      live: c.data.timer?.taskId == task.id ? w.runningTimer : null,
      onPressed: () => c.changeTasks([task.id], done: !task.done),
    );
  }

  Widget _teamCard() => NeumorphicCard(
    key: const ValueKey('today-team'),
    title: w.teamActivity,
    children: [
      _Rows([
        for (final person in team)
          Builder(
            builder: (_) {
              final name = w.text(person.name), task = c.currentTask(person.id);
              return _Line(
                // The cap grows round its initials at a larger text size.
                lead: NeumorphicMonogram(
                  _initials(name),
                  key: ValueKey('today-team-lead-${person.id}'),
                  led: task != null,
                ),
                title: name,
                note: task == null ? w.notTracking : w.text(task.title),
              );
            },
          ),
      ]),
    ],
  );

  Widget _blocksCard() {
    final blocks = c.todayBlocks;
    return NeumorphicCard(
      key: const ValueKey('today-blocks'),
      title: w.timeBlocks,
      children: [
        if (blocks.isEmpty)
          Text(w.noBlocks, style: plaster.textTheme.caption)
        else
          _Timeline(
            section: 'blocks',
            label: w.timeBlocks,
            stops: [
              for (final e in blocks)
                (
                  time: w.timeRange(e),
                  title: w.text(e.note),
                  body:
                      '${c.projectName(e.project)}${_dot(w)}${w.duration(e.end - e.start)}',
                  live: false,
                ),
            ],
          ),
      ],
    );
  }

  Widget _feedCard() => NeumorphicCard(
    key: const ValueKey('today-activity'),
    title: w.recentActivity,
    children: [
      StreamBuilder<DateTime>(
        stream: c.ticks(const Duration(minutes: 1)),
        initialData: c.repository.now(),
        builder: (_, now) => c.data.activity.isEmpty
            ? Text(w.noActivity, style: plaster.textTheme.caption)
            : _Timeline(
                section: 'feed',
                label: w.recentActivity,
                stops: [
                  for (final (i, e) in c.data.activity.indexed)
                    (
                      time: w.timeAgo(e.at, now.data!),
                      title: w.eventAction(e, c.personName(e.person)),
                      body: w.text(e.subject),
                      live: i == 0,
                    ),
                ],
              ),
      ),
    ],
  );

  Widget _laterCard() {
    final later = c.laterThisWeek;
    return NeumorphicCard(
      key: const ValueKey('today-later'),
      title: w.laterThisWeek,
      children: [
        _Rows([
          if (later.isEmpty)
            _Line(
              lead: const Icon(LucideIcons.calendarCheck, size: 20),
              title: w.allClear,
            ),
          for (final task in later)
            _Line(
              // The day it is due, as a date on a raised cap; its whole name
              // leads the note (a short one is a letter in Arabic, as an hour
              // is).
              lead: ExcludeSemantics(
                child: NeumorphicMonogram(
                  w.number(task.due.day),
                  key: ValueKey('today-later-lead-${task.id}'),
                ),
              ),
              title: w.text(task.title),
              note:
                  '${w.weekday(task.due)}${_dot(w)}${c.projectName(task.project)}',
              trailing: w.duration(task.estimate),
              onPressed: () => open(task),
            ),
        ]),
      ],
    );
  }
}

/// The mark between two facts on one line: a middle dot, or in Arabic the
/// comma, as a dot beside Arabic figures reads as a zero.
String _dot(StintWords w) => w.arabic ? '، ' : ' · ';

String _initials(String name) => name
    .split(' ')
    .where((part) => part.isNotEmpty)
    .take(2)
    .map((part) => String.fromCharCode(part.runes.first))
    .join();

/// Rows of one list, each under the look's one rule but the first.
class _Rows extends StatelessWidget {
  const _Rows(this.rows);
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final (i, row) in rows.indexed)
        NeumorphicRuled(rule: i > 0, child: row),
    ],
  );
}

/// One Today row: its mark centred in the leading slot, its words on the
/// title edge after it, an optional figure at its end. With [onPressed] the
/// whole row is one target that presses in, as the kit's list rows do.
class _Line extends StatelessWidget {
  const _Line({
    super.key,
    required this.lead,
    required this.title,
    this.note,
    this.trailing,
    this.onPressed,
    this.checked,
    this.done = false,
    this.live,
  });
  final Widget lead;
  final String title;
  final String? note, trailing;

  /// What the lamp at the row's end says when the row is live: the one task
  /// the timer runs on.
  final String? live;
  final VoidCallback? onPressed;
  final bool? checked;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final t = NeumorphicTheme.of(context), colors = t.colors;
    final motion = NeumorphicMotion.of(context);
    // Large type folds the end word under the note, so the title keeps the
    // row's width.
    final folds =
        trailing != null && MediaQuery.textScalerOf(context).scale(1) >= 1.6;
    Widget row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 64),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
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
                spacing: 1,
                children: [
                  AnimatedDefaultTextStyle(
                    duration: motion.state,
                    style: t.textTheme.title.copyWith(
                      color: done ? colors.inkTertiary : colors.ink,
                      decoration: done
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      decorationColor: colors.inkTertiary,
                    ),
                    child: Text(title),
                  ),
                  if (note != null && live != null)
                    // The lit lamp and its words follow the note, in the
                    // pigment, so the note keeps the title's edge; with no
                    // room beside the note (large text) the lamp wraps under.
                    Wrap(
                      spacing: 10,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(note!, style: t.textTheme.caption),
                        NeumorphicStatus(
                          live!,
                          key: const ValueKey('today-plan-running'),
                          live: true,
                        ),
                      ],
                    )
                  else if (note != null)
                    Text(note!, style: t.textTheme.caption),
                  if (folds) Text(trailing!, style: t.textTheme.micro.tabular),
                ],
              ),
            ),
            if (trailing != null && !folds) ...[
              const SizedBox(width: 12),
              Text(trailing!, style: t.textTheme.micro.tabular),
            ],
          ],
        ),
      ),
    );
    if (onPressed == null) {
      return MergeSemantics(child: row);
    }
    return NeumorphicTap(
      onPressed: onPressed,
      checked: checked,
      button: checked == null,
      semanticLabel: [title, ?note, ?trailing, ?live].join(', '),
      shape: t.shapes.corner(NeumorphicRadii.control),
      faceOutset: const EdgeInsets.symmetric(horizontal: 12),
      child: row,
    );
  }
}

typedef _Stop = ({String time, String title, String body, bool live});

/// The look's timeline on Today's leading slot and in its rows' rhythm: an
/// engraved line down the slot's middle joining a dot for each stop, the
/// latest in the pigment, the words on the title edge and the time at the end.
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
    final t = NeumorphicTheme.of(context), colors = t.colors;
    final flat = NeumorphicFlatScope.of(context);
    const dot = 14.0;
    TextStyle timeStyle(bool live) => t.textTheme.micro.tabular.copyWith(
      color: live ? colors.accentInk : colors.inkTertiary,
    );
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
            t.textTheme.title,
            timeStyle(false),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, stop) in stops.indexed)
                MergeSemantics(
                  child: CustomPaint(
                    painter: _RailPainter(
                      colors: colors,
                      flat: flat,
                      above: i > 0,
                      below: i < stops.length - 1,
                      clear: dot / 2 + 3,
                      rtl: Directionality.of(context) == TextDirection.rtl,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 64),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Row(
                          children: [
                            SizedBox(
                              width: _slot,
                              child: Center(
                                child: SizedBox.square(
                                  key: ValueKey('today-$section-lead-$i'),
                                  dimension: dot,
                                  child: CustomPaint(
                                    painter: _DotPainter(
                                      colors,
                                      live: stop.live,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: _slotGap),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 1,
                                children: [
                                  Text(stop.title, style: t.textTheme.title),
                                  Text(stop.body, style: t.textTheme.caption),
                                  if (under)
                                    Text(
                                      stop.time,
                                      style: timeStyle(stop.live),
                                    ),
                                ],
                              ),
                            ),
                            if (!under) ...[
                              const SizedBox(width: 12),
                              Text(stop.time, style: timeStyle(stop.live)),
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

/// A stop's dot: the pigment with a lit centre for the latest, quiet ink for
/// the rest, as the kit's timeline draws them.
class _DotPainter extends CustomPainter {
  const _DotPainter(this.colors, {required this.live});
  final NeumorphicColors colors;
  final bool live;
  @override
  void paint(Canvas canvas, Size size) {
    final mid = size.center(Offset.zero);
    if (live) {
      canvas.drawCircle(mid, 7, Paint()..color = colors.accent);
      canvas.drawCircle(mid, 2.5, Paint()..color = colors.onAccent);
    } else {
      canvas.drawCircle(mid, 5, Paint()..color = colors.inkTertiary);
    }
  }

  @override
  bool shouldRepaint(_DotPainter old) =>
      old.colors != colors || old.live != live;
}

/// The engraved line through a stop: a crease and its lit edge on end, broken
/// round the dot.
class _RailPainter extends CustomPainter {
  const _RailPainter({
    required this.colors,
    required this.flat,
    required this.above,
    required this.below,
    required this.clear,
    required this.rtl,
  });
  final NeumorphicColors colors;
  final bool flat, above, below, rtl;
  final double clear;

  @override
  void paint(Canvas canvas, Size size) {
    final x = (rtl ? size.width - _slot / 2 : _slot / 2).roundToDouble();
    final mid = size.height / 2;
    void line(double from, double to) {
      if (to <= from) return;
      canvas.drawRect(
        Rect.fromLTWH(x - 1, from, 1, to - from),
        Paint()..color = flat ? colors.quiet : colors.crease,
      );
      if (!flat) {
        canvas.drawRect(
          Rect.fromLTWH(x, from, 1, to - from),
          Paint()..color = colors.rim,
        );
      }
    }

    if (above) line(0, mid - clear);
    if (below) line(mid + clear, size.height);
  }

  @override
  bool shouldRepaint(_RailPainter old) =>
      old.colors != colors ||
      old.flat != flat ||
      old.above != above ||
      old.below != below ||
      old.clear != clear ||
      old.rtl != rtl;
}

/// The week's days in a well: a column for each, today's in the pigment, the
/// days to come a quiet mark on the floor. Every day keeps its slot, and its
/// name stands centred under it: the short name while it fits, its letter
/// when it doesn't. Unbounded, it stands [natural] tall; given a height, it
/// fills it.
class _DayColumns extends StatefulWidget {
  const _DayColumns({
    super.key,
    required this.minutes,
    required this.days,
    required this.today,
    required this.words,
    required this.natural,
  });
  final List<int> minutes;
  final List<DateTime> days;
  final int today;
  final StintWords words;
  final double natural;

  @override
  State<_DayColumns> createState() => _DayColumnsState();
}

class _DayColumnsState extends State<_DayColumns>
    with SingleTickerProviderStateMixin {
  late final grow = AnimationController(vsync: this, value: 1);
  late List<double> from = _values, to = _values;
  List<double> get _values => [for (final m in widget.minutes) m / 60];

  @override
  void didUpdateWidget(_DayColumns old) {
    super.didUpdateWidget(old);
    if (!listEquals(old.minutes, widget.minutes)) {
      from = [
        for (var i = 0; i < 7; i++)
          lerpDouble(from[i], to[i], grow.value) ?? to[i],
      ];
      to = _values;
      final motion = NeumorphicMotion.of(context);
      grow
        ..duration = motion.move
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
    final t = NeumorphicTheme.of(context), w = widget.words;
    final scaler = MediaQuery.textScalerOf(context);
    final style = t.textTheme.micro;
    final flat = NeumorphicFlatScope.of(context);
    const inset = EdgeInsets.fromLTRB(12, 14, 12, 10);
    return LayoutBuilder(
      builder: (ctx, box) {
        final slot = (box.maxWidth - inset.horizontal) / 7;
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
            child: NeumorphicWell(
              padding: inset,
              child: AnimatedBuilder(
                animation: grow,
                builder: (_, _) {
                  final values = [
                    for (var i = 0; i < 7; i++)
                      lerpDouble(
                        from[i],
                        to[i],
                        Curves.easeOutCubic.transform(grow.value),
                      )!,
                  ];
                  final top = values.fold<double>(1, math.max);
                  // Each day a slot of its own, its column over its name, so
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
                                  painter: _ColumnPainter(
                                    colors: t.colors,
                                    flat: flat,
                                    value: values[i],
                                    top: top,
                                    live: i == widget.today,
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
                                        color: t.colors.accentInk,
                                        fontWeight: FontWeight.w800,
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

/// One day's column, raised a little off the well's floor, today's in the
/// pigment; with nothing logged, a short groove on the floor.
class _ColumnPainter extends CustomPainter {
  const _ColumnPainter({
    required this.colors,
    required this.flat,
    required this.value,
    required this.top,
    required this.live,
  });
  final NeumorphicColors colors;
  final bool flat, live;
  final double value, top;

  @override
  void paint(Canvas canvas, Size size) {
    // A short chart thins its bars, so a low day still reads as a bar.
    final bar = math.min(
      math.min(size.width * .44, 20.0),
      math.max(10.0, size.height * .16),
    );
    final cx = size.width / 2;
    if (value <= 0) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, size.height - 2),
            width: bar,
            height: 4,
          ),
          const Radius.circular(2),
        ),
        Paint()..color = colors.quiet,
      );
      return;
    }
    final h = math.max(bar, size.height * value / top);
    final rect = Rect.fromLTWH(cx - bar / 2, size.height - h, bar, h);
    final shape = RRect.fromRectAndRadius(rect, Radius.circular(bar / 2));
    if (!flat) {
      // Raised a little off the well's floor: a lit edge above, a shade below.
      canvas.drawRRect(
        shape.shift(const Offset(-1.5, -1.5)),
        Paint()
          ..color = colors.highlightSoft
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
      canvas.drawRRect(
        shape.shift(const Offset(1.5, 1.5)),
        Paint()
          ..color = colors.shadow
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
    canvas.drawRRect(
      shape,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: live
              ? [colors.accent, colors.accent]
              : [colors.barStart, colors.barEnd],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ColumnPainter old) =>
      old.colors != colors ||
      old.flat != flat ||
      old.value != value ||
      old.top != top ||
      old.live != live;
}

/// Cards side by side on the page's columns. Each is laid out at its column's
/// width, and with [even] all of them then take the tallest one's height, so a
/// row of cards shares a top and a foot. A card given that height can hand the
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
    // Whole pixels, so a card's edge never lands between two.
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
