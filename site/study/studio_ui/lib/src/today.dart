part of '../stint_studio.dart';

extension _Today on _WorkspaceState {
  /// The separator inside a meta line: a middle dot, or in Arabic the Arabic
  /// comma, because a middle dot beside Arabic-Indic figures reads as a zero.
  String get _sep => w.arabic ? '، ' : ' · ';

  /// The separator inside a list or timer meta line. At 200% text such a
  /// line wraps anyway, so its two parts take a line each rather than one
  /// breaking at the separator, as the activity feed's times already do.
  String get _metaSep =>
      MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? '\n' : _sep;

  Widget today() => station(
    w.today,
    data(
      () => LayoutBuilder(
        builder: (ctx, bounds) {
          final wide =
              bounds.maxWidth >= 580 * MediaQuery.textScalerOf(ctx).scale(1);
          final avatarSize =
              32.0 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.25);
          final today = c.todayTasks;
          final plan = _ConsoleGroup(
            key: const ValueKey('today-plan'),
            header: w.todaysPlan,
            dividerIndent: 48,
            children: [
              if (today.isEmpty) StudioListTile(title: w.noTasksToday),
              for (final task in today) _planKey(task),
              StudioListTile(
                key: const ValueKey('today-view-tasks'),
                leading: const Icon(
                  LucideIcons.listChecks,
                  key: ValueKey('today-plan-lead-all'),
                  size: 24,
                ),
                title: w.viewTasks,
                subtitle: today.isEmpty
                    ? null
                    : w.progress(
                        today.where((t) => t.done).length,
                        today.length,
                      ),
                onTap: () => go(Place.tasks),
              ),
            ],
          );
          final entries = c.todayBlocks;
          final blocks = _ConsoleGroup(
            key: const ValueKey('today-blocks'),
            header: w.timeBlocks,
            dividerIndent: 48,
            children: [
              if (entries.isEmpty) StudioListTile(title: w.noBlocks),
              for (final (i, entry) in entries.indexed)
                _logLine(
                  mark: 'today-blocks-lead-$i',
                  first: i == 0,
                  last: i == entries.length - 1,
                  stamp: w.timeRange(entry),
                  title: w.text(entry.note),
                  note: c.projectName(entry.project),
                ),
              StudioListTile(
                leading: const Icon(
                  LucideIcons.clock3,
                  key: ValueKey('today-blocks-lead-all'),
                  size: 24,
                ),
                title: w.seeTime,
                onTap: () => go(Place.time),
              ),
            ],
          );
          final upcoming = c.laterThisWeek;
          final later = _ConsoleGroup(
            key: const ValueKey('today-later'),
            header: w.laterThisWeek,
            dividerIndent: 48,
            children: [
              if (upcoming.isEmpty) StudioListTile(title: w.allClear),
              for (final task in upcoming)
                StudioListTile(
                  leading: Icon(
                    LucideIcons.calendarClock,
                    key: ValueKey('today-later-lead-${task.id}'),
                    size: 24,
                  ),
                  title: w.text(task.title),
                  subtitle:
                      '${w.weekday(task.due)}$_metaSep${c.projectName(task.project)}',
                  onTap: () => open(task),
                ),
            ],
          );
          final people = _ConsoleGroup(
            key: const ValueKey('today-team'),
            header: w.teamActivity,
            dividerIndent: 48,
            children: [
              for (final p in team)
                StudioListTile(
                  leading: ExcludeSemantics(
                    child: SizedBox.square(
                      dimension: 24,
                      child: OverflowBox(
                        minWidth: avatarSize,
                        maxWidth: avatarSize,
                        minHeight: avatarSize,
                        maxHeight: avatarSize,
                        child: StudioAvatar(
                          key: ValueKey('today-team-lead-${p.id}'),
                          name: w.text(p.name),
                          size: avatarSize,
                        ),
                      ),
                    ),
                  ),
                  title: w.text(p.name),
                  subtitle: switch (c.currentTask(p.id)) {
                    final task? => w.text(task.title),
                    null => w.notTracking,
                  },
                ),
            ],
          );
          final events = c.data.activity;
          final feed = StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, tick) => _ConsoleGroup(
              key: const ValueKey('today-feed'),
              header: w.recentActivity,
              dividerIndent: 48,
              children: [
                if (events.isEmpty) StudioListTile(title: w.noActivity),
                for (final (i, event) in events.indexed)
                  _logLine(
                    mark: 'today-feed-lead-$i',
                    first: i == 0,
                    last: i == events.length - 1,
                    stamp: w.timeAgo(event.at, tick.data!),
                    title: w.eventAction(event, c.personName(event.person)),
                    note: w.text(event.subject),
                  ),
              ],
            ),
          );
          Widget bank(List<Widget> children) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: StudioSpacing.regular,
            children: children,
          );
          final transport = _transport();
          final meters = _levelBank();
          final contents = bank([
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: StudioSpacing.tight,
              children: [
                StudioLegend(
                  '${w.weekday(studyToday)}$_sep${w.shortDate(studyToday)}',
                  color: rack.colors.legendMuted,
                ),
                Semantics(
                  header: true,
                  child: Text(
                    w.greeting,
                    style: rack.textTheme.headline.copyWith(
                      color: rack.colors.legend,
                    ),
                  ),
                ),
              ],
            ),
            if (wide) ...[
              Table(
                defaultVerticalAlignment:
                    TableCellVerticalAlignment.intrinsicHeight,
                columnWidths: const {1: FixedColumnWidth(20)},
                children: [
                  TableRow(
                    children: [transport, const SizedBox.shrink(), meters],
                  ),
                ],
              ),
              _pairedDisplays(plan, people, level: today.isNotEmpty),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(child: bank([blocks, later])),
                  Expanded(child: feed),
                ],
              ),
            ] else ...[
              transport,
              meters,
              FocusTraversalGroup(child: plan),
              blocks,
              people,
              feed,
              later,
            ],
          ]);
          return contents;
        },
      ),
    ),
  );

  /// The plan and the team side by side, their glass one height while
  /// [level] (the plan has rows): an empty plan's two rows would otherwise
  /// part into a tall, empty pane beside the team.
  Widget _pairedDisplays(
    _ConsoleGroup first,
    _ConsoleGroup second, {
    bool level = true,
  }) {
    Widget glass(_ConsoleGroup group) => StudioDisplay(
      key: group.key,
      padding: const EdgeInsets.all(StudioMetrics.recessInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, row) in group.children.indexed) ...[
            if (index > 0)
              Padding(
                padding: EdgeInsetsDirectional.only(
                  start: group.dividerIndent,
                  end: StudioSpacing.small,
                ),
                child: ColoredBox(
                  color: rack.colors.displayLine,
                  child: const SizedBox(height: 1),
                ),
              ),
            row,
          ],
        ],
      ),
    );
    // Two one-row tables, not one table of two rows: each row still shares
    // one height across both columns, but in a second table row Flutter's
    // table semantics placed the list rows a header's height below where
    // they paint, so a tap through the semantics tree reached the row above.
    Widget row(Widget a, Widget b, {bool level = true}) => Table(
      defaultVerticalAlignment: level
          ? TableCellVerticalAlignment.intrinsicHeight
          : TableCellVerticalAlignment.top,
      columnWidths: const {1: FixedColumnWidth(20)},
      children: [
        TableRow(children: [a, const SizedBox.shrink(), b]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(_ConsoleHeader(first.header), _ConsoleHeader(second.header)),
        row(
          FocusTraversalGroup(child: glass(first)),
          glass(second),
          level: level,
        ),
      ],
    );
  }

  Future<String?> _showTaskChooser(WidgetBuilder builder) {
    final equipment = rack;
    return Navigator.of(context, rootNavigator: true).push<String>(
      RawModalDialogRoute<String>(
        barrierColor: equipment.colors.scrim,
        dampingRatio: StudioMotion.dampingRatio,
        stiffness: StudioMotion.overlayStiffness,
        builder: (dialog, route) => StudioTheme(
          data: equipment,
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.viewInsetsOf(dialog).bottom,
            ),
            child: MediaQuery.removeViewInsets(
              context: dialog,
              removeBottom: true,
              child: SafeArea(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(StudioSpacing.large),
                    child: ScaleTransition(
                      scale: route.animation.drive(
                        Tween<double>(begin: .96, end: 1),
                      ),
                      child: Builder(builder: builder),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _transport() {
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    final colors = rack.colors, type = rack.textTheme;
    final latest = c.data.activity.firstOrNull;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    Future<void> pick() async {
      final title = active ? w.switchTask : w.startTimer;
      final rowHeight = 44.0 * scale.clamp(1, 1.6);
      final id = await _showTaskChooser(
        (dialog) => StudioDialog(
          title: title,
          actions: [
            StudioButton(w.cancel, onPressed: () => Navigator.pop(dialog)),
          ],
          content: RawCommandPalette(
            semanticLabel: title,
            maxHeight: rowHeight * (scale > 1.4 ? 3 : 5),
            commands: [
              for (final item in choices)
                RawCommand(
                  label: w.text(item.title),
                  data: item.id,
                  keywords: [c.projectName(item.project)],
                ),
            ],
            onSelected: (item) => Navigator.pop(dialog, item.data as String),
            fieldBuilder: (_, field) => StudioTextField(
              controller: field.controller,
              focusNode: field.focusNode,
              hintText: w.search,
              semanticLabel: w.search,
              prefixIcon: const Icon(LucideIcons.search),
              onEditingComplete: field.submit,
            ),
            emptyBuilder: (_) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(w.noMatches),
            ),
            itemBuilder: (_, item, states) => StudioMenuRow(
              label: item.label,
              states: states,
              height: rowHeight,
              showLamp: true,
              chosen: states.contains(WidgetState.focused),
            ),
            layoutBuilder: (_, field, results) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                field,
                Flexible(
                  child: StudioDisplay(
                    padding: const EdgeInsets.all(4),
                    child: results,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      if (mounted && id != null) c.track(id);
    }

    Widget clock(DateTime now) {
      final label = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return RepaintBoundary(
        child: Semantics(
          identifier: 'stint-elapsed',
          label: w.elapsedLabel(label),
          excludeSemantics: true,
          child: FittedBox(
            alignment: AlignmentDirectional.centerStart,
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              key: const ValueKey('today-timer-digits'),
              textDirection: TextDirection.ltr,
              style: type.readout.copyWith(
                color: active ? colors.readoutLit : colors.onDisplayMuted,
                fontSize: 46,
                height: 1.1,
              ),
            ),
          ),
        ),
      );
    }

    final display = StudioDisplay(
      key: const ValueKey('today-timer-well'),
      readout: active,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 8,
        children: [
          Row(
            spacing: 8,
            children: [
              StudioLamp(
                key: const ValueKey('today-timer-lamp'),
                on: active,
                size: 8 * scale.clamp(1, 1.5),
              ),
              Flexible(
                child: StudioLegend(
                  active ? w.runningTimer : w.stoppedTimer,
                  key: const ValueKey('today-timer-label'),
                  color: active ? colors.onReadout : colors.onDisplay,
                ),
              ),
            ],
          ),
          timer == null
              ? clock(c.repository.now())
              : StreamBuilder<DateTime>(
                  stream: c.ticks(const Duration(seconds: 1)),
                  initialData: c.repository.now(),
                  builder: (_, tick) => clock(tick.data!),
                ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 2,
            children: [
              TweenAnimationBuilder<Color?>(
                key: ValueKey(task?.id),
                tween: ColorTween(
                  begin: colors.onReadoutMuted,
                  end: active ? colors.onReadout : colors.onDisplay,
                ),
                duration: rawReduceMotionOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 150),
                curve: Curves.easeOut,
                builder: (_, ink, _) => Text(
                  active ? w.text(task.title) : w.chooseTask,
                  key: const ValueKey('today-timer-title'),
                  style: type.title.copyWith(color: ink),
                ),
              ),
              if (active)
                Text(
                  '${c.projectName(task.project)}$_metaSep${w.since(timer.start)}',
                  style: type.secondary.copyWith(color: colors.onReadoutMuted),
                )
              else if (latest != null &&
                  latest.kind == ActivityKind.logged &&
                  latest.person == 'maya')
                Text(
                  w.eventAction(latest, c.personName(latest.person)),
                  style: type.secondary.copyWith(color: colors.onDisplayMuted),
                )
              else if (choices.isEmpty)
                Text(
                  w.noTimerTasks,
                  style: type.secondary.copyWith(color: colors.onReadoutMuted),
                ),
            ],
          ),
        ],
      ),
    );
    final controls = LayoutBuilder(
      builder: (ctx, box) {
        final primary = StudioButton(
          active ? w.stopTimer : w.startTimer,
          key: const ValueKey('today-action-first'),
          icon: Icon(
            active ? LucideIcons.square : LucideIcons.play,
            size: 14 * scale.clamp(1, 1.4),
          ),
          onPressed: active
              ? c.stopTimer
              : choices.isEmpty
              ? null
              : pick,
        );
        final change = StudioButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          onPressed: active && choices.isNotEmpty ? pick : null,
        );
        final keys = box.maxWidth < 242 * scale
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [primary, change],
              )
            : Row(
                spacing: 8,
                children: [
                  Expanded(child: primary),
                  Expanded(child: change),
                ],
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Flexible(
              fit: box.hasBoundedHeight ? FlexFit.tight : FlexFit.loose,
              child: display,
            ),
            keys,
          ],
        );
      },
    );
    return KeyedSubtree(
      key: const ValueKey('today-timer-card'),
      child: StudioPanel(padding: const EdgeInsets.all(12), child: controls),
    );
  }

  Widget _levelBank() {
    final colors = rack.colors,
        type = rack.textTheme,
        week = mondayOf(studyToday);
    final minutes = c.totalMinutes(week), daily = c.dailyMinutes(week);
    Widget counter(String key, String name, String value, String spoken) =>
        StudioDisplay(
          key: ValueKey('today-stat-$key'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Semantics(
            label: '$name, $spoken',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 3,
              children: [
                Text(
                  StudioLegend.hasCapitals(name) ? name.toUpperCase() : name,
                  style: type.legend.copyWith(
                    color: colors.onDisplayMuted,
                    letterSpacing: w.arabic ? 0 : .9,
                  ),
                ),
                FittedBox(
                  alignment: AlignmentDirectional.centerStart,
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: type.readout.copyWith(color: colors.onDisplay),
                  ),
                ),
              ],
            ),
          ),
        );
    final counters = LayoutBuilder(
      builder: (ctx, box) {
        final scale = MediaQuery.textScalerOf(ctx).scale(1);
        final width = box.maxWidth / scale;
        final count = w.number(c.openTasks.length), hours = w.duration(minutes);
        final chart = _WeekMeters(
          words: w,
          minutes: daily,
          shortLabels: width < 230,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 10,
          children: [
            Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.intrinsicHeight,
              columnWidths: const {1: FixedColumnWidth(8)},
              children: [
                TableRow(
                  children: [
                    counter('tasks', w.openTasks, count, count),
                    const SizedBox.shrink(),
                    counter('hours', w.hoursThisWeek, hours, hours),
                  ],
                ),
              ],
            ),
            if (box.hasBoundedHeight)
              Expanded(child: chart)
            else
              SizedBox(height: 106 * scale.clamp(1, 1.5), child: chart),
          ],
        );
      },
    );
    return StudioPanel(padding: const EdgeInsets.all(12), child: counters);
  }

  Widget _planKey(Task task) {
    final colors = rack.colors;
    final tracking = c.data.timer?.taskId == task.id;
    return RawButton(
      key: ValueKey('plan-${task.id}'),
      checked: task.done,
      button: false,
      excludeSemantics: true,
      semanticLabel: [
        w.text(task.title),
        c.projectName(task.project),
        if (tracking) w.runningTimer,
      ].join(', '),
      onPressed: () => c.changeTasks([task.id], done: !task.done),
      builder: (_, states, _) {
        final down = task.done || states.contains(WidgetState.pressed);
        final face = colors.keyFace
            .copyWith(radius: StudioRadii.small, travel: down ? 1 : 0)
            .backlitIf(colors, task.done);
        final light = states.contains(WidgetState.focused);
        return StudioListTile(
          title: w.text(task.title),
          subtitle: tracking
              ? '${c.projectName(task.project)}$_metaSep${w.runningTimer}'
              : c.projectName(task.project),
          style: task.done
              ? StudioStyle(
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: colors.onDisplayMuted,
                    ),
                  ),
                )
              : tracking
              ? StudioStyle(
                  foreground: WidgetStatePropertyAll(colors.litLegend),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          leading: SizedBox.square(
            dimension: 24,
            key: ValueKey('today-plan-lead-${task.id}'),
            child: AnimatedStudioSurface(
              face: light
                  ? face.copyWith(
                      focus: colors.focusRing,
                      rim: colors.focusRing.withValues(alpha: 0),
                    )
                  : face,
              child: task.done
                  ? Icon(LucideIcons.check, size: 17, color: colors.litLegend)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _logLine({
    required String mark,
    required bool first,
    required bool last,
    required String stamp,
    required String title,
    required String note,
  }) {
    final colors = rack.colors, type = rack.textTheme;
    const inset = StudioSpacing.regular - StudioMetrics.recessInset;
    return Semantics(
      container: true,
      label: '$stamp, $title, $note',
      excludeSemantics: true,
      child: Stack(
        children: [
          PositionedDirectional(
            start: inset + 11,
            top: first ? 20 : 0,
            bottom: last ? null : 0,
            height: last ? (first ? 0 : 20) : null,
            width: 2,
            child: ColoredBox(color: colors.displayLine),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: inset,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: StudioSpacing.medium,
              children: [
                SizedBox(
                  width: 24,
                  height: 20,
                  child: Center(
                    child: StudioLamp(key: ValueKey(mark), on: false, size: 9),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 2,
                    children: [
                      Text(
                        stamp,
                        style: type.caption.copyWith(
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      Text(
                        title,
                        style: type.label.copyWith(color: colors.onDisplay),
                      ),
                      Text(note, style: type.secondary),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekMeters extends StatelessWidget {
  const _WeekMeters({
    required this.words,
    required this.minutes,
    required this.shortLabels,
  });
  final StintWords words;
  final List<int> minutes;
  final bool shortLabels;

  @override
  Widget build(BuildContext context) {
    final rack = StudioTheme.of(context), week = mondayOf(studyToday);
    final maximum = minutes.fold(480, (a, b) => a > b ? a : b);
    final scale = ((maximum + 479) ~/ 480) * 480;
    return StudioDisplay(
      key: const ValueKey('today-chart'),
      readout: true,
      // The scale's legend starts on the stat readouts' 10 px text edge.
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      // The scale's rule is the meters' full-scale line: it runs along the
      // foot of its legend and the tubes stand up to it.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            spacing: 6,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                words.duration(scale),
                style: rack.textTheme.caption.copyWith(
                  color: rack.colors.onReadout,
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: rack.colors.onReadoutMuted.withValues(alpha: .3),
                  child: const SizedBox(height: 1),
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, value) in minutes.indexed)
                  Expanded(
                    child: Semantics(
                      label:
                          '${words.weekday(addDays(week, i))}, ${words.duration(value)}',
                      excludeSemantics: true,
                      child: Column(
                        spacing: 4,
                        children: [
                          Expanded(
                            child: Align(
                              alignment: Alignment.bottomCenter,
                              child: value == 0
                                  ? SizedBox(
                                      key: ValueKey('today-day-slot-$i'),
                                      width: 16,
                                      height: 2,
                                      child: ColoredBox(
                                        color: rack.colors.onReadoutMuted
                                            .withValues(alpha: .7),
                                      ),
                                    )
                                  : StudioMeter(
                                      key: ValueKey('today-day-slot-$i'),
                                      level: value / scale,
                                      axis: Axis.vertical,
                                      thickness: 16,
                                      segments: 12,
                                      clip: 1,
                                    ),
                            ),
                          ),
                          Text(
                            shortLabels
                                ? words.weekdayNarrow(addDays(week, i))
                                : words.weekdayShort(addDays(week, i)),
                            key: ValueKey('today-day-label-$i'),
                            style: rack.textTheme.caption.copyWith(
                              color: rack.colors.onReadout,
                            ),
                            maxLines: 1,
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
    );
  }
}
