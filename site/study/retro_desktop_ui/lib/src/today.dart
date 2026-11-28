part of '../stint_retro_desktop.dart';

/// Today as a desktop: the Today window in front (greeting, the stopwatch and
/// the week), the day's windows tiled beneath it. On a desk the desktop tiles
/// them on its 12 columns; a tablet lays the same windows in two columns
/// (one under 840); a phone stacks them with Today first.
extension _Today on _WorkspaceState {
  Widget today() {
    final week = mondayOf(studyToday);
    final hero = RetroDesktopWindow(
      key: const ValueKey('today-hero'),
      title: w.today,
      icon: _places[0],
      // Arabic parts the day from the date with its own comma: a dot reads
      // as its zero.
      info: '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}',
      child: data(() => _hero(week)),
    );
    final tasks = c.todayTasks;
    Widget list(Key key, List<Widget> rows, String empty) => RetroDesktopWell(
      key: key,
      child: rows.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(RetroDesktopSpacing.s10),
              child: Text(empty, style: desk.textTheme.body),
            )
          : RetroDesktopList(children: rows),
    );
    final plan = RetroDesktopWindow(
      key: const ValueKey('today-plan-window'),
      title: w.todaysPlan,
      icon: RetroDesktopGlyphs.listChecks,
      status: [
        if (tasks.isNotEmpty)
          w.progress(tasks.where((t) => t.done).length, tasks.length),
      ],
      statusAction: RetroDesktopButton(
        w.viewTasks,
        key: const ValueKey('today-view-tasks'),
        onPressed: () => go(Place.tasks),
      ),
      child: data(
        () => list(const ValueKey('today-plan'), [
          for (final (i, task) in tasks.indexed) _planRow(task, first: i == 0),
        ], w.noTasksToday),
      ),
    );
    final blocks = RetroDesktopWindow(
      key: const ValueKey('today-blocks'),
      title: w.timeBlocks,
      icon: RetroDesktopGlyphs.clock,
      child: data(
        () => list(const ValueKey('today-block-list'), [
          for (final (i, e) in c.todayBlocks.indexed)
            RetroDesktopListTile(
              key: ValueKey('block-${e.id}'),
              title: w.text(e.note),
              subtitle: c.projectName(e.project),
              trailing: Text(w.timeRange(e), style: desk.textTheme.meta),
              semanticLabel:
                  '${w.text(e.note)}, ${c.projectName(e.project)}, ${w.timeRange(e)}',
              isFirst: i == 0,
              leading: Icon(
                RetroDesktopGlyphs.clock,
                key: ValueKey('today-blocks-lead-$i'),
              ),
            ),
        ], w.noBlocks),
      ),
    );
    final later = RetroDesktopWindow(
      key: const ValueKey('today-later'),
      title: w.laterThisWeek,
      icon: RetroDesktopGlyphs.calendarDays,
      child: data(
        () => list(const ValueKey('today-later-list'), [
          for (final (i, task) in c.laterThisWeek.indexed)
            RetroDesktopListTile(
              key: ValueKey('later-${task.id}'),
              title: w.text(task.title),
              subtitle: c.projectName(task.project),
              trailing: Text(w.weekday(task.due), style: desk.textTheme.meta),
              semanticLabel:
                  '${w.text(task.title)}, ${c.projectName(task.project)}, ${w.weekday(task.due)}',
              leading: Icon(
                RetroDesktopGlyphs.fileText,
                key: ValueKey('today-later-lead-${task.id}'),
              ),
              isFirst: i == 0,
              onPressed: () => open(task),
            ),
        ], w.allClear),
      ),
    );
    final people = RetroDesktopWindow(
      key: const ValueKey('today-team'),
      title: w.teamActivity,
      icon: RetroDesktopGlyphs.contacts,
      child: data(
        () => list(const ValueKey('today-team-list'), [
          for (final (i, person) in team.indexed)
            _person(person, first: i == 0),
        ], w.noActivity),
      ),
    );
    final feed = RetroDesktopWindow(
      key: const ValueKey('today-feed'),
      title: w.recentActivity,
      icon: RetroDesktopGlyphs.notifications,
      // The well is the window's own child, so it stands flush like the
      // others; each age ticks by itself.
      child: data(
        () => list(const ValueKey('today-feed-list'), [
          for (final (i, e) in c.data.activity.indexed)
            RetroDesktopListTile(
              title: w.eventAction(e, c.personName(e.person)),
              subtitle: w.text(e.subject),
              trailing: StreamBuilder<DateTime>(
                stream: c.ticks(const Duration(minutes: 1)),
                initialData: c.repository.now(),
                builder: (_, now) => Text(
                  w.timeAgo(e.at, now.data!),
                  style: desk.textTheme.meta,
                ),
              ),
              isFirst: i == 0,
              leading: ExcludeSemantics(
                child: RetroDesktopAvatar(
                  _initials(c.personName(e.person)),
                  key: ValueKey('today-feed-lead-$i'),
                  name: c.personName(e.person),
                  size: 32,
                ),
              ),
            ),
        ], w.noActivity),
      ),
    );
    final width = MediaQuery.sizeOf(context).width;
    final Widget page;
    if (desk.desk) {
      page = RetroDesktopDesktop(
        active: w.today,
        tiles: [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [hero],
            under: [
              RetroDesktopWindowColumn(
                span: 7,
                windows: [plan, blocks, people],
              ),
              RetroDesktopWindowColumn(span: 5, windows: [later, feed]),
            ],
          ),
        ],
      );
    } else if (width >= 600) {
      // A tablet: the desktop's own tiling starts at 1024, so Today lays the
      // same windows under the one in front: from 840 in two columns, the
      // day's and the rest; narrower in one, where two would wrap every row.
      Widget window(Widget child, {bool active = false}) =>
          RetroDesktopWindowScope(active: active, compact: false, child: child);
      final two = width >= 840;
      page = Padding(
        padding: const EdgeInsets.fromLTRB(
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s12,
          RetroDesktopSpacing.s20,
        ),
        child: RetroDesktopColumn(
          gap: 12,
          children: [
            window(hero, active: true),
            if (!two)
              for (final each in [plan, blocks, later, people, feed])
                window(each),
            // Both columns end on one line: the last window of each takes
            // the slack, as the desktop's own tiling does.
            if (two)
              RetroDesktopEqualRow(
                flex: const [1, 1],
                gap: 12,
                children: [
                  RetroDesktopColumn(
                    gap: 12,
                    children: [
                      window(plan),
                      window(blocks),
                      RetroDesktopGrow(child: window(people)),
                    ],
                  ),
                  RetroDesktopColumn(
                    gap: 12,
                    children: [
                      window(later),
                      RetroDesktopGrow(child: window(feed)),
                    ],
                  ),
                ],
              ),
          ],
        ),
      );
    } else {
      page = RetroDesktopDesktop(
        active: w.today,
        phoneOrder: [
          w.today,
          w.todaysPlan,
          w.timeBlocks,
          w.laterThisWeek,
          w.teamActivity,
          w.recentActivity,
        ],
        tiles: [
          RetroDesktopWindowColumn(
            span: 12,
            windows: [hero, plan, blocks, later, people, feed],
          ),
        ],
      );
    }
    return RetroDesktopScaffold(
      body: page,
      fullBleed: !desk.desk && width >= 600,
    );
  }

  /// The front window's content: the greeting over the stopwatch and the
  /// week. Wide, the two stand as columns on one top line and one bottom line;
  /// the chart takes whatever height the stopwatch leaves it.
  Widget _hero(DateTime week) => LayoutBuilder(
    builder: (ctx, box) {
      final scale = MediaQuery.textScalerOf(ctx).scale(1);
      final wide = box.maxWidth / scale >= 560;
      const gap = RetroDesktopSpacing.s16;
      final timerWidth = wide ? (box.maxWidth - gap) * 4 / 11 : box.maxWidth;
      final timer = _stopwatch(timerWidth, grow: wide);
      final summary = _week(
        week,
        grow: wide,
        width: wide ? (box.maxWidth - gap) * 7 / 11 : box.maxWidth,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: RetroDesktopSpacing.s12,
        children: [
          Semantics(
            header: true,
            child: Text(w.greeting, style: desk.textTheme.head),
          ),
          if (wide)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: gap,
                children: [
                  Expanded(flex: 4, child: timer),
                  Expanded(flex: 7, child: summary),
                ],
              ),
            )
          else ...[
            timer,
            summary,
          ],
        ],
      );
    },
  );

  Widget _stopwatch(double width, {required bool grow}) {
    final colors = desk.colors;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    Future<void> pick() async {
      final choice = await showRetroDesktopDialog<String>(
        context,
        builder: (ctx) => RetroDesktopDialog(
          title: active ? w.switchTask : w.startTimer,
          content: [
            RawCommandPalette(
              semanticLabel: active ? w.switchTask : w.startTimer,
              onSelected: (command) => Navigator.pop(ctx, command.data),
              commands: [
                for (final item in choices)
                  RawCommand(
                    label: w.text(item.title),
                    group: c.projectName(item.project),
                    data: item.id,
                  ),
              ],
              fieldBuilder: (_, f) => RetroDesktopSearchField(
                hintText: w.search,
                clearLabel: w.clear,
                focusNode: f.focusNode,
                controller: f.controller,
                onEditingComplete: f.submit,
              ),
              emptyBuilder: (_) =>
                  Text(w.noMatches, style: desk.textTheme.body),
              itemBuilder: (_, command, states) {
                final lit = states.contains(WidgetState.focused);
                final ink = lit ? colors.onHighlight : colors.text;
                return ColoredBox(
                  color: lit ? colors.highlight : colors.paper,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    child: Row(
                      spacing: 9,
                      children: [
                        Icon(RetroDesktopGlyphs.fileText, color: ink, size: 17),
                        Expanded(
                          child: Text(
                            command.label,
                            style: desk.textTheme.row.copyWith(color: ink),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
          actions: [
            RetroDesktopButton(w.cancel, onPressed: () => Navigator.pop(ctx)),
          ],
        ),
      );
      if (mounted && choice != null) c.track(choice);
    }

    // The readout fills its well: the digits are set as large as the well's
    // width holds, up to the system face's display size.
    const wellPad = RetroDesktopSpacing.s10;
    final probe = TextPainter.computeWidth(
      text: TextSpan(
        text: w.elapsed(Duration.zero),
        style: desk.textTheme.pixel(48, 48),
      ),
      textDirection: TextDirection.ltr,
    );
    final digitSize = ((width - 2 * wellPad - 4) / probe * 48)
        .clamp(30.0, desk.desk ? 96.0 : 72.0)
        .floorToDouble();
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
            textScaler: TextScaler.noScaling,
            style: desk.textTheme.pixel(
              digitSize,
              digitSize,
              color: active ? colors.text : colors.textSecondary,
            ),
          ),
        ),
      );
    }

    final well = RetroDesktopWell(
      key: const ValueKey('today-timer-well'),
      padding: const EdgeInsets.fromLTRB(wellPad, 8, wellPad, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: RetroDesktopSpacing.s4,
        children: [
          Row(
            spacing: RetroDesktopSpacing.s6,
            children: [
              // The period's busy pointer: a watch while the clock runs.
              Icon(
                active ? RetroDesktopGlyphs.time : RetroDesktopGlyphs.clock,
                size: 16,
                color: active ? colors.highlight : colors.textSecondary,
              ),
              Expanded(
                child: Text(
                  active ? w.runningTimer : w.stoppedTimer,
                  style: desk.textTheme.caption,
                ),
              ),
            ],
          ),
          if (timer == null)
            reading(c.repository.now())
          else
            StreamBuilder<DateTime>(
              stream: c.ticks(const Duration(seconds: 1)),
              initialData: c.repository.now(),
              builder: (_, snapshot) => reading(snapshot.data!),
            ),
          Text(
            timer == null ? w.notTracking : w.since(timer.start),
            style: desk.textTheme.meta,
          ),
        ],
      ),
    );
    final name = Column(
      key: const ValueKey('today-timer-title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: RetroDesktopSpacing.s2,
      children: [
        Text(
          active ? w.text(task.title) : w.chooseTask,
          style: active ? desk.textTheme.sub : desk.textTheme.body,
        ),
        // Stopped, the project's line is held empty, so the window and the
        // ones under it keep their height when the timer stops.
        if (active)
          Text(c.projectName(task.project), style: desk.textTheme.meta)
        else
          Visibility(
            visible: choices.isEmpty,
            maintainSize: true,
            maintainAnimation: true,
            maintainState: true,
            child: Text(
              w.noTimerTasks,
              style: desk.textTheme.meta,
              maxLines: choices.isEmpty ? null : 1,
            ),
          ),
      ],
    );
    final buttons = [
      if (active) ...[
        RetroDesktopButton(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          wide: true,
          size: RetroDesktopButtonSize.large,
          isDefaultAction: true,
          onPressed: c.stopTimer,
        ),
        RetroDesktopButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          wide: true,
          size: RetroDesktopButtonSize.large,
          onPressed: choices.isEmpty ? null : pick,
        ),
      ] else ...[
        RetroDesktopButton(
          w.startTimer,
          key: const ValueKey('today-action-first'),
          wide: true,
          size: RetroDesktopButtonSize.large,
          isDefaultAction: true,
          onPressed: choices.isEmpty ? null : pick,
        ),
        // Stopped, time can still be logged by hand: the second key keeps
        // the row two keys wide, as the look holds one key at its words.
        RetroDesktopButton(
          w.addEntry,
          key: const ValueKey('today-action-last'),
          wide: true,
          size: RetroDesktopButtonSize.large,
          onPressed: addTime,
        ),
      ],
    ];
    // Both keys share the well's width while their words fit on one line.
    final words = active
        ? [w.stopTimer, w.switchTask]
        : [w.startTimer, w.addEntry];
    final widest = words
        .map(
          (word) => TextPainter.computeWidth(
            text: TextSpan(text: word, style: desk.textTheme.chrome),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          ),
        )
        .fold(0.0, math.max);
    final share =
        (width - RetroDesktopSpacing.s8 * (words.length - 1)) / words.length;
    final keys = widest + 40 > share
        ? Column(
            key: const ValueKey('timer-keys'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: RetroDesktopSpacing.s8,
            children: buttons,
          )
        : Row(
            key: const ValueKey('timer-keys'),
            spacing: RetroDesktopSpacing.s8,
            children: [for (final b in buttons) Expanded(child: b)],
          );
    // The well opens the column, on the week's top line; the task's words
    // under it; the keys close it, on the chart's bottom line.
    return Column(
      key: const ValueKey('today-timer-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: RetroDesktopSpacing.s10,
      children: [well, name, if (grow) const Spacer(), keys],
    );
  }

  Widget _week(DateTime week, {required bool grow, required double width}) {
    final readings = [
      ('today-stat-tasks', w.openTasks, w.number(c.openTasks.length)),
      ('today-stat-hours', w.hoursThisWeek, w.duration(c.totalMinutes(week))),
    ];
    // Words too long for half the measure (large text on a phone) stack the
    // two tiles, each the chart's width, rather than wrap them word by word.
    final scaler = MediaQuery.textScalerOf(context);
    double span(String text, TextStyle style) => TextPainter.computeWidth(
      text: TextSpan(text: text, style: style),
      textDirection: Directionality.of(context),
      textScaler: scaler,
    );
    final half = (width - RetroDesktopSpacing.s8) / 2 - 22;
    final stack =
        scaler.scale(1) >= 1.5 &&
        readings.any(
          (r) =>
              span(r.$2, desk.textTheme.caption) > half ||
              span(r.$3, desk.textTheme.big) > half,
        );
    // Two equal tiles, the label at the top, the value under it; a long
    // value wraps between its number-and-unit pairs inside its tile.
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
    Widget tile((String, String, String) r) => RetroDesktopWell(
      key: ValueKey(r.$1),
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            slot(r.$2, (x) => x.$2, desk.textTheme.caption),
            slot(r.$3, (x) => x.$3, desk.textTheme.big),
          ],
        ),
      ),
    );
    final Widget tiles = stack
        ? Column(
            key: const ValueKey('today-stats'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: RetroDesktopSpacing.s8,
            children: [for (final r in readings) tile(r)],
          )
        : Row(
            key: const ValueKey('today-stats'),
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: RetroDesktopSpacing.s8,
            children: [for (final r in readings) Expanded(child: tile(r))],
          );
    final least =
        150.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.5);
    final chart = _AtLeast(height: least, child: _dayChart(week));
    return Column(
      key: const ValueKey('today-week'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: RetroDesktopSpacing.s10,
      children: [
        tiles,
        if (grow) Expanded(child: chart) else chart,
      ],
    );
  }

  /// The week on the machine: seven hatched columns in a well, today's in
  /// the highlight, a day with nothing logged a dashed rest on the floor.
  /// Each day's name stands centred under its own column; single letters
  /// (the reader's) where the names would crowd.
  Widget _dayChart(DateTime week) {
    final colors = desk.colors;
    final daily = c.dailyMinutes(week),
        days = List.generate(7, (i) => addDays(week, i));
    final most = (daily.fold(60, math.max) / 60).ceil() * 60;
    final scaler = MediaQuery.textScalerOf(context);
    return RetroDesktopWell(
      key: const ValueKey('today-chart'),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
      child: Semantics(
        container: true,
        label: w.logged,
        value: [
          for (var i = 0; i < 7; i++)
            '${w.weekday(days[i])} ${w.duration(daily[i])}',
        ].join(', '),
        excludeSemantics: true,
        child: LayoutBuilder(
          builder: (ctx, box) {
            final short = box.maxWidth / scaler.scale(1) < 7 * 40;
            final bar = math.min(28.0, box.maxWidth / 7 - 12).floorToDouble();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: RetroDesktopSpacing.s4,
              children: [
                Expanded(
                  child: RetroDesktopPixelPaint(
                    painter: _Floor(colors.text),
                    // The columns stand on the floor's line.
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 1),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < 7; i++)
                            Expanded(
                              child: LayoutBuilder(
                                builder: (_, room) {
                                  final lit = days[i] == studyToday;
                                  final share = daily[i] / most;
                                  return Align(
                                    alignment: Alignment.bottomCenter,
                                    child: SizedBox(
                                      key: ValueKey('today-day-slot-$i'),
                                      width: bar,
                                      height: daily[i] == 0
                                          ? 3
                                          : math.max(
                                              4.0,
                                              (share * room.maxHeight)
                                                  .floorToDouble(),
                                            ),
                                      child: RetroDesktopPixelPaint(
                                        painter: _DayBar(
                                          colors,
                                          today: lit,
                                          rest: daily[i] == 0,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                    ),
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
                            // The look's day-bar names: mono, today's
                            // in ink and bold.
                            style: desk.textTheme.mono(
                              11,
                              13,
                              weight: days[i] == studyToday
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                              color: days[i] == studyToday
                                  ? colors.text
                                  : colors.textTertiary,
                            ),
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
    );
  }

  String _initials(String name) => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part.characters.first)
      .join();

  Widget _person(Person person, {required bool first}) {
    final name = w.text(person.name), task = c.currentTask(person.id);
    return RetroDesktopListTile(
      key: ValueKey('person-${person.id}'),
      title: name,
      subtitle: task == null ? w.notTracking : w.text(task.title),
      isFirst: first,
      leading: ExcludeSemantics(
        child: RetroDesktopAvatar(
          _initials(name),
          key: ValueKey('today-team-lead-${person.id}'),
          name: name,
          size: 32,
        ),
      ),
    );
  }

  /// A plan row: the look's checkbox at the list's leading column, the
  /// whole row the one control that ticks it. The task the timer runs on
  /// carries the busy watch at its end.
  Widget _planRow(Task task, {required bool first}) {
    final title = w.text(task.title), done = task.done;
    final running = c.data.timer?.taskId == task.id;
    return MergeSemantics(
      child: Semantics(
        checked: done,
        child: RetroDesktopListTile(
          key: ValueKey('plan-${task.id}'),
          title: title,
          subtitle: c.projectName(task.project),
          semanticLabel: [
            title,
            c.projectName(task.project),
            if (running) w.runningTimer,
          ].join(', '),
          isFirst: first,
          // The task the timer runs on says so at the row's end, as the desk
          // labels a state: a tag with the clock glyph and its words.
          // On a phone with large text it gives way to the title, never more
          // than a third of the row.
          trailing: running
              ? ConstrainedBox(
                  key: const ValueKey('today-plan-running'),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 3,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RetroDesktopTag(
                      w.runningTimer,
                      icon: RetroDesktopGlyphs.time,
                    ),
                  ),
                )
              : null,
          onPressed: () => c.changeTasks([task.id], done: !done),
          leading: ExcludeFocus(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: RetroDesktopCheckbox(
                  key: ValueKey('today-plan-lead-${task.id}'),
                  value: done,
                  semanticLabel: title,
                  onChanged: (_) {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Reports [height] as its intrinsic height, so a row of columns can be
/// measured around a part that has none of its own (a chart that reads its
/// width), then gives that part whatever height the row settles on.
class _AtLeast extends SingleChildRenderObjectWidget {
  const _AtLeast({required this.height, required super.child});
  final double height;
  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderAtLeast(height);
  @override
  void updateRenderObject(BuildContext context, _RenderAtLeast renderObject) =>
      renderObject.least = height;
}

class _RenderAtLeast extends RenderProxyBox {
  _RenderAtLeast(this._least);
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
    final height = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : _least;
    child!.layout(
      BoxConstraints.tightFor(width: constraints.maxWidth, height: height),
      parentUsesSize: true,
    );
    size = constraints.constrain(child!.size);
  }
}

/// A day's column as the look hatches one: today in the highlight's
/// stripes, the rest in the hatch, each outlined but for its foot; a day
/// with nothing logged a dashed rest on the floor.
class _DayBar extends RetroDesktopPixelPainter {
  const _DayBar(this.c, {required this.today, required this.rest});
  final RetroDesktopColors c;
  final bool today, rest;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) {
    final r = px.snap(Offset.zero & s);
    if (r.width <= 0 || r.height <= 0) return;
    if (rest) {
      // Dashes of 2 with gaps of 2, as many as fit, centred on the column so
      // the rest stands under its day's name.
      final count = ((r.width + 2) / 4).floor();
      final start = (r.left + (r.width - (count * 4 - 2)) / 2).roundToDouble();
      for (var i = 0; i < count; i++) {
        px.fill(
          Rect.fromLTWH(start + i * 4, r.bottom - 2, 2, 2),
          c.textTertiary,
        );
      }
      return;
    }
    if (today) {
      px.diagonal(r, 6, 3, c.highlight, between: c.highlightDark);
    } else {
      px.diagonal(r, 3, 1, c.hatch);
    }
    final line = today ? c.outline : c.text;
    final w = px.hairX, h = px.hair;
    px.fillExact(r.left, r.top, r.right, r.top + h, line);
    px.fillExact(r.left, r.top, r.left + w, r.bottom, line);
    px.fillExact(r.right - w, r.top, r.right, r.bottom, line);
  }

  @override
  bool shouldRepaint(_DayBar o) =>
      o.c != c || o.today != today || o.rest != rest;
}

/// The chart's floor: one line of ink along the foot of the plot.
class _Floor extends RetroDesktopPixelPainter {
  const _Floor(this.color);
  final Color color;
  @override
  void paint(RetroDesktopPixelGrid px, Size s) =>
      px.fillExact(0, s.height - px.hair, s.width, s.height, color);

  @override
  bool shouldRepaint(_Floor o) => o.color != color;
}
