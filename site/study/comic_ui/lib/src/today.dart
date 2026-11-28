part of '../stint_comic.dart';

/// Today as a comic page: a splash tier (the running timer beside the week),
/// then a tier of two columns of panels (the plan, the day's blocks and the
/// team; what comes later and what happened) that start and end on one line.
extension _Today on _WorkspaceState {
  Widget today() {
    final week = mondayOf(studyToday);
    return ComicScaffold(
      topBar: ComicAppBar(title: w.today, actions: [commands]),
      body: data(() {
        final across = t.window != RawWindowSizeClass.compact;
        final gutter = across ? 16.0 : 10.0;
        // A desk gives the timer and the plan the wider share; a tablet halves.
        final spans = t.desk ? const [7, 5] : const [1, 1];
        final tasks = c.todayTasks;
        final plan = ComicPanel(
          key: const ValueKey('today-plan'),
          caption: w.todaysPlan,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (tasks.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: ComicSpace.close),
                  child: Text(w.noTasksToday, style: t.type.body),
                ),
              for (final (i, task) in tasks.indexed)
                _PlanRow(
                  key: ValueKey('plan-${task.id}'),
                  lead: ValueKey('today-plan-lead-${task.id}'),
                  title: w.text(task.title),
                  subtitle: c.projectName(task.project),
                  done: task.done,
                  first: i == 0,
                  running: c.data.timer?.taskId == task.id
                      ? w.runningTimer
                      : null,
                  onChanged: (done) => c.changeTasks([task.id], done: done),
                ),
              _PlanRow(
                key: const ValueKey('today-view-tasks'),
                lead: const ValueKey('today-plan-lead-all'),
                title: w.viewTasks,
                subtitle: tasks.isEmpty
                    ? null
                    : w.progress(
                        tasks.where((t) => t.done).length,
                        tasks.length,
                      ),
                first: tasks.isEmpty,
                mark: ComicGlyphs.forward,
                onPressed: () => go(Place.tasks),
              ),
            ],
          ),
        );
        final people = ComicPanel(
          key: const ValueKey('today-team'),
          caption: w.teamActivity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, person) in team.indexed) _person(person, i == 0),
            ],
          ),
        );
        final blocks = ComicPanel(
          key: const ValueKey('today-blocks'),
          caption: w.timeBlocks,
          child: c.todayBlocks.isEmpty
              ? Text(w.noBlocks, style: t.type.body)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, e) in c.todayBlocks.indexed)
                      ComicListTile(
                        key: ValueKey('block-${e.id}'),
                        title: w.text(e.note),
                        subtitle: c.projectName(e.project),
                        trailing: Text(w.timeRange(e), style: t.type.data),
                        semanticLabel:
                            '${w.text(e.note)}, ${c.projectName(e.project)}, ${w.timeRange(e)}',
                        isFirst: i == 0,
                        leading: _lead(
                          Icon(
                            ComicGlyphs.time,
                            key: ValueKey('today-blocks-lead-$i'),
                            size: 22,
                            color: t.colors.text,
                          ),
                        ),
                      ),
                  ],
                ),
        );
        final later = ComicPanel(
          key: const ValueKey('today-later'),
          caption: w.laterThisWeek,
          child: c.laterThisWeek.isEmpty
              ? Text(w.allClear, style: t.type.body)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, task) in c.laterThisWeek.indexed)
                      ComicListTile(
                        key: ValueKey('later-${task.id}'),
                        title: w.text(task.title),
                        subtitle: c.projectName(task.project),
                        trailing: Text(w.weekday(task.due), style: t.type.data),
                        semanticLabel:
                            '${w.text(task.title)}, ${c.projectName(task.project)}, ${w.weekday(task.due)}',
                        isFirst: i == 0,
                        leading: _lead(
                          Icon(
                            ComicGlyphs.calendar,
                            key: ValueKey('today-later-lead-${task.id}'),
                            size: 22,
                            color: t.colors.text,
                          ),
                        ),
                        onPressed: () => open(task),
                      ),
                  ],
                ),
        );
        final feed = ComicPanel(
          key: const ValueKey('today-feed'),
          caption: w.recentActivity,
          child: StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, now) => c.data.activity.isEmpty
                ? Text(w.noActivity, style: t.type.body)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, e) in c.data.activity.indexed)
                        ComicListTile(
                          title: w.eventAction(e, c.personName(e.person)),
                          subtitle: w.text(e.subject),
                          trailing: Text(
                            w.timeAgo(e.at, now.data!),
                            style: t.type.data,
                          ),
                          isFirst: i == 0,
                          leading: _lead(
                            ExcludeSemantics(
                              child: ComicPerson.seeded(
                                c.personName(e.person),
                                key: ValueKey('today-feed-lead-$i'),
                                size: 30,
                                isCurrentUser: e.person == 'maya',
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        );
        return ComicColumn(
          gap: gutter,
          children: [
            _greeting(),
            ComicTier(
              key: const ValueKey('today-hero'),
              spans: spans,
              phone: ComicTierLayout.stack,
              children: [_timerPanel(), _weekPanel(week)],
            ),
            // Below the splash, from 840 wide, two columns that start and end
            // on one line: the day's plan, its blocks and the team; what comes
            // later and what happened. The shorter column's last panel takes
            // the few pixels between them. Narrower, two columns would wrap
            // every row, so the panels stand in one: the day, then the rest.
            if (t.window.index < RawWindowSizeClass.expanded.index)
              ComicColumn(
                gap: gutter,
                children: [plan, blocks, later, people, feed],
              )
            else
              ComicTier(
                spans: spans,
                phone: ComicTierLayout.stack,
                children: [
                  ComicColumn(
                    gap: gutter,
                    children: [
                      plan,
                      blocks,
                      ComicGrow(child: people),
                    ],
                  ),
                  ComicColumn(
                    gap: gutter,
                    children: [
                      later,
                      ComicGrow(child: feed),
                    ],
                  ),
                ],
              ),
          ],
        );
      }),
    );
  }

  /// The page opens on narration: the day in a caption, the greeting lettered
  /// under it as the page's title. Nobody in the panel says it, so no
  /// balloon. Arabic parts the day from the date with its own comma, as a dot
  /// reads as its zero.
  Widget _greeting() => Column(
    key: const ValueKey('today-greeting'),
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: ComicSpace.close,
    children: [
      ComicCaption(
        '${w.weekday(studyToday)}${w.dot}'
        '${w.shortDate(studyToday)}',
        free: true,
        tight: true,
      ),
      Semantics(header: true, child: Text(w.greeting, style: t.type.panel)),
    ],
  );

  Widget _timerPanel() {
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    void pick() => showComicCommand(
      context,
      label: active ? w.switchTask : w.startTimer,
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

    final info = Column(
      key: const ValueKey('today-timer-title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ComicSpace.tight,
      children: [
        Text(
          active ? w.text(task.title) : w.chooseTask,
          style: active ? t.type.item : t.type.body,
        ),
        // Stopped, the project's line is held empty, so the panel and the
        // page under it keep their height when the timer stops.
        if (active)
          Text(c.projectName(task.project), style: t.type.meta)
        else
          Visibility(
            visible: choices.isEmpty,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              w.noTimerTasks,
              style: t.type.meta,
              maxLines: choices.isEmpty ? null : 1,
            ),
          ),
      ],
    );
    // A running clock is lit in the narrator's fill, its ink the caption's.
    final ink = active ? t.colors.onCaption : t.colors.text;
    Widget reading(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        label: w.elapsedLabel(value),
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            key: const ValueKey('today-timer-digits'),
            textDirection: TextDirection.ltr,
            style: t.type.hero.copyWith(
              fontSize: t.desk ? 88 : 60,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    final well = ComicWell(
      key: const ValueKey('today-timer-well'),
      lamp: active,
      padding: const EdgeInsets.fromLTRB(
        ComicSpace.near,
        ComicSpace.close,
        ComicSpace.near,
        ComicSpace.close,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Inked(
            taskId: task?.id,
            child: timer == null
                ? reading(c.repository.now())
                : StreamBuilder<DateTime>(
                    stream: c.ticks(const Duration(seconds: 1)),
                    initialData: c.repository.now(),
                    builder: (_, snapshot) => reading(snapshot.data!),
                  ),
          ),
          Text(
            timer == null ? w.notTracking : w.since(timer.start),
            style: t.type.label.copyWith(color: ink),
          ),
        ],
      ),
    );
    final buttons = [
      if (active) ...[
        ComicButton.filled(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          wide: true,
          onPressed: c.stopTimer,
        ),
        ComicButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          wide: true,
          onPressed: choices.isEmpty ? null : pick,
        ),
      ] else ...[
        ComicButton.filled(
          w.startTimer,
          key: const ValueKey('today-action-first'),
          wide: true,
          onPressed: choices.isEmpty ? null : pick,
        ),
        // Stopped, time can still be logged by hand: the second key keeps
        // the row two keys wide, as the look holds one key at its words.
        ComicButton(
          w.addEntry,
          key: const ValueKey('today-action-last'),
          wide: true,
          onPressed: addTime,
        ),
      ],
    ];
    // Two keys share the well's width while both words fit on one line; else
    // they stack, each the well's width, so a row never holds two heights.
    final keys = LayoutBuilder(
      key: const ValueKey('timer-keys'),
      builder: (ctx, box) {
        final words = active
            ? [w.stopTimer, w.switchTask]
            : [w.startTimer, w.addEntry];
        final widest = words
            .map(
              (word) => TextPainter.computeWidth(
                text: TextSpan(text: word.toUpperCase(), style: t.type.button),
                textDirection: Directionality.of(ctx),
                textScaler: MediaQuery.textScalerOf(ctx),
              ),
            )
            .fold(0.0, math.max);
        final share =
            (box.maxWidth - ComicSpace.near * (words.length - 1)) /
            words.length;
        if (widest + 2 * ComicSpace.room + 8 > share) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ComicSpace.close,
            children: buttons,
          );
        }
        return Row(
          spacing: ComicSpace.near,
          children: [for (final b in buttons) Expanded(child: b)],
        );
      },
    );
    // The well opens the panel on the week's top line, the task's words
    // under it; the keys close it on the chart's bottom line.
    return ComicPanel(
      key: const ValueKey('today-timer-card'),
      caption: active ? w.runningTimer : w.stoppedTimer,
      child: ComicColumn(
        gap: ComicSpace.near,
        children: [
          well,
          info,
          const ComicGrow(child: SizedBox.shrink()),
          keys,
        ],
      ),
    );
  }

  Widget _weekPanel(DateTime week) {
    final readings = [
      ('today-stat-tasks', w.openTasks, w.number(c.openTasks.length)),
      ('today-stat-hours', w.hoursThisWeek, w.duration(c.totalMinutes(week))),
    ];
    final valueStyle = t.type.number(28);
    // On a phone, words too long for half the panel (large text) stack the
    // two tiles, each the chart's width, rather than wrap them word by word.
    final scaler = MediaQuery.textScalerOf(context);
    double span(String text, TextStyle style) => TextPainter.computeWidth(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    );
    final half = (MediaQuery.sizeOf(context).width - 100) / 2;
    final stack =
        t.window == RawWindowSizeClass.compact &&
        scaler.scale(1) >= 1.5 &&
        readings.any(
          (r) =>
              span(r.$2.toUpperCase(), t.type.label) > half ||
              span(r.$3, valueStyle) > half,
        );
    // Two tiles of one width fill the chart's measure, the label at the top
    // and the figure under it; a long figure wraps between its number-and-
    // unit pairs inside its tile.
    // Each slot is as tall as the taller of the two tiles' words in it, so
    // both tiles stand one height and the figures on one line however the
    // labels or a figure wrap, measured by the tiles' own layout.
    Widget slot(
      String own,
      String Function((String, String, String)) of,
      TextStyle style,
    ) => Stack(
      children: [
        for (final other in readings)
          if (!stack && of(other) != own)
            Visibility(
              visible: false,
              maintainSize: true,
              maintainAnimation: true,
              maintainState: true,
              child: Text(of(other), style: style),
            ),
        Text(own, style: style),
      ],
    );
    Widget tile((String, String, String) reading) {
      final (key, label, value) = reading;
      return ComicWell(
        key: ValueKey(key),
        child: MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ComicSpace.fine,
            children: [
              slot(
                label.toUpperCase(),
                (x) => x.$2.toUpperCase(),
                t.type.label,
              ),
              slot(value, (x) => x.$3, valueStyle),
            ],
          ),
        ),
      );
    }

    return ComicPanel(
      key: const ValueKey('today-week'),
      caption: w.workWeek,
      child: ComicColumn(
        gap: ComicSpace.near,
        children: [
          if (stack)
            Column(
              key: const ValueKey('today-stats'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ComicSpace.near,
              children: [for (final r in readings) tile(r)],
            )
          else
            Row(
              key: const ValueKey('today-stats'),
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ComicSpace.near,
              children: [for (final r in readings) Expanded(child: tile(r))],
            ),
          ComicGrow(child: _dayChart(week)),
        ],
      ),
    );
  }

  /// Seven of the look's bars stood on end in a well, Monday to Sunday, each
  /// day's name centred under its own bar: today's in solid ink, the rest
  /// in dots, a day with nothing logged a bare track. Single letters (the
  /// reader's) where the names would crowd.
  Widget _dayChart(DateTime week) {
    final minutes = c.dailyMinutes(week);
    final whole = (minutes.fold(60, math.max) / 60).ceil() * 60;
    final style = t.type.text(14, 1.2, weight: FontWeight.w700);
    final scaler = MediaQuery.textScalerOf(context);
    final days = [for (var i = 0; i < 7; i++) addDays(week, i)];
    double measure(String text) => TextPainter.computeWidth(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    ).ceilToDouble();
    final line = (TextPainter(
      text: TextSpan(text: w.weekdayShort(days.first), style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    )..layout()).height.ceilToDouble();
    return ComicWell(
      key: const ValueKey('today-chart'),
      child: Semantics(
        image: true,
        excludeSemantics: true,
        label: [
          w.logged,
          for (var i = 0; i < 7; i++)
            '${w.weekday(days[i])} ${w.duration(minutes[i])}',
        ].join(', '),
        child: _Least(
          height: 120 + ComicSpace.close + line,
          child: LayoutBuilder(
            builder: (ctx, box) {
              final slot = box.maxWidth / 7;
              final short =
                  days
                          .map((d) => measure(w.weekdayShort(d)))
                          .fold(0.0, math.max) +
                      6 >
                  slot;
              final thick = slot >= 34 ? 22.0 : 18.0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: ComicSpace.close,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = 0; i < 7; i++)
                          Expanded(
                            child: Center(
                              child: SizedBox(
                                key: ValueKey('today-day-slot-$i'),
                                width: thick,
                                // The bar fills from its foot in either
                                // reading direction.
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: RotatedBox(
                                    quarterTurns: 3,
                                    child: ComicBar(
                                      value: minutes[i],
                                      of: whole,
                                      height: thick,
                                      ink: days[i] == studyToday
                                          ? ComicBarFill.leading
                                          : ComicBarFill.dots,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      for (var i = 0; i < 7; i++)
                        Expanded(
                          child: Center(
                            child: Text(
                              short
                                  ? w.weekdayNarrow(days[i])
                                  : w.weekdayShort(days[i]),
                              key: ValueKey('today-day-label-$i'),
                              maxLines: 1,
                              softWrap: false,
                              style: style,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  /// Every list's mark stands centred in the plan box's measure, so the words
  /// of every panel in a column start on one line.
  Widget _lead(Widget mark) => SizedBox(
    width: _boxMeasure,
    child: Center(child: mark),
  );

  Widget _person(Person person, bool first) {
    final name = w.text(person.name), task = c.currentTask(person.id);
    return ComicListTile(
      key: ValueKey('person-${person.id}'),
      title: name,
      subtitle: task == null ? w.notTracking : w.text(task.title),
      isFirst: first,
      leading: _lead(
        ExcludeSemantics(
          child: ComicPerson.seeded(
            name,
            key: ValueKey('today-team-lead-${person.id}'),
            size: 30,
            isCurrentUser: person.id == 'maya',
          ),
        ),
      ),
    );
  }
}

/// The width a [ComicCheckbox] draws at, which the plan's box column holds.
const double _boxMeasure = 32;

/// A plan row: the whole row ticks its task, in a list tile's rhythm (2 above
/// the first row, 11 round the rest) so it pairs with the roster beside it.
/// With [mark] it opens a place instead, the mark centred in the box column.
/// The task the timer runs on carries the timer's glyph at its end, and says
/// so as [running].
class _PlanRow extends StatelessWidget {
  const _PlanRow({
    super.key,
    required this.lead,
    required this.title,
    this.subtitle,
    required this.first,
    this.done = false,
    this.onChanged,
    this.mark,
    this.onPressed,
    this.running,
  });

  /// The key on the leading mark: the box, or the place's glyph.
  final Key lead;
  final String title;
  final String? subtitle;
  final bool first, done;
  final ValueChanged<bool>? onChanged;
  final IconData? mark;
  final VoidCallback? onPressed;

  /// The running timer's name, when this row's task is the one it times.
  final String? running;

  @override
  Widget build(BuildContext context) {
    final t = ComicTheme.of(context);
    // The box drawn without a target of its own: the row is the control.
    final box = RawTapTargetScope(
      targets: const RawTapTargets(touch: Size.zero, pointer: Size.zero),
      child: ExcludeFocus(
        child: IgnorePointer(
          child: ExcludeSemantics(
            child: ComicCheckbox(
              key: mark == null ? lead : null,
              semanticLabel: title,
              value: done,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    final leading = mark == null
        ? box
        : Stack(
            alignment: Alignment.center,
            children: [
              Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: box,
              ),
              Icon(mark, key: lead, size: 22, color: t.colors.text),
            ],
          );
    final face = Padding(
      padding: EdgeInsets.only(top: first ? 2 : 11, bottom: 11),
      child: Row(
        children: [
          leading,
          const SizedBox(width: ComicSpace.near),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: ComicMotion.of(context).state,
                  style: t.type.title.copyWith(
                    color: done ? t.colors.textSecondary : t.colors.text,
                    decoration: done
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationThickness: 2,
                  ),
                  child: Text(title),
                ),
                if (subtitle case final line?) Text(line, style: t.type.meta),
              ],
            ),
          ),
          // The task the timer runs on carries the timer's own caption: the
          // narrator's yellow box, its words in ink.
          if (running != null) ...[
            const SizedBox(width: ComicSpace.close),
            // On a phone with large text it gives way to the title, never
            // more than a third of the row.
            ConstrainedBox(
              key: const ValueKey('today-plan-running'),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.sizeOf(context).width / 3,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: ComicTag(
                  running!,
                  tone: ComicSpeaker.narrator,
                  icon: ComicGlyphs.time,
                ),
              ),
            ),
          ],
        ],
      ),
    );
    return ComicRuled(
      rule: !first,
      child: mark == null
          ? ComicPressable(
              button: false,
              checked: done,
              semanticLabel: [title, ?subtitle, ?running].join(', '),
              onPressed: onChanged == null ? null : () => onChanged!(!done),
              child: face,
            )
          : ComicPressable(
              semanticLabel: title,
              value: subtitle,
              onPressed: onPressed,
              child: face,
            ),
    );
  }
}

/// A new task inks in: the digits press onto the page and settle, on the
/// look's state motion; Reduce Motion cuts.
class _Inked extends StatefulWidget {
  const _Inked({required this.taskId, required this.child});
  final String? taskId;
  final Widget child;
  @override
  State<_Inked> createState() => _InkedState();
}

class _InkedState extends State<_Inked> with SingleTickerProviderStateMixin {
  late final ink = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(_Inked old) {
    super.didUpdateWidget(old);
    final motion = ComicMotion.of(context);
    if (widget.taskId != old.taskId && motion.raise > Duration.zero) {
      ink
        ..duration = motion.raise
        ..forward(from: 0);
    }
  }

  @override
  void dispose() {
    ink.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = ComicMotion.of(context).enter;
    return AnimatedBuilder(
      animation: ink,
      builder: (_, child) => Transform.scale(
        scale: .82 + .18 * curve.transform(ink.value),
        alignment: AlignmentDirectional.centerStart.resolve(
          Directionality.of(context),
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

/// Reports [height] as its own height, so a tier can measure a panel round
/// a part that reads its width (a chart), then gives that part whatever
/// height the tier settles on.
class _Least extends SingleChildRenderObjectWidget {
  const _Least({required this.height, required super.child});
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) => _RenderLeast(height);
  @override
  void updateRenderObject(BuildContext context, _RenderLeast renderObject) =>
      renderObject.least = height;
}

class _RenderLeast extends RenderProxyBox {
  _RenderLeast(this._least);
  double _least;
  set least(double value) {
    if (value == _least) return;
    _least = value;
    markNeedsLayout();
  }

  @override
  double computeMinIntrinsicHeight(double width) => _least;
  @override
  double computeMaxIntrinsicHeight(double width) => _least;
  @override
  double computeMinIntrinsicWidth(double height) => 0;
  @override
  double computeMaxIntrinsicWidth(double height) => 0;
  @override
  Size computeDryLayout(BoxConstraints constraints) =>
      constraints.constrain(Size(constraints.maxWidth, _least));

  @override
  void performLayout() {
    child!.layout(
      BoxConstraints.tightFor(
        width: constraints.maxWidth,
        height: constraints.constrainHeight(_least),
      ),
      parentUsesSize: true,
    );
    size = constraints.constrain(child!.size);
  }
}
