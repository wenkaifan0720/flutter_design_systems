part of '../stint_appliance.dart';

extension _Today on _WorkspaceState {
  Widget today() => ApplianceScreen(
    topBar: ApplianceAppBar(title: w.today, actions: [commandKey]),
    body: dataBody(
      () => LayoutBuilder(
        builder: (ctx, box) {
          final width = box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1);
          final week = mondayOf(studyToday);
          final summary = _WeekSummary(
            words: w,
            tasks: c.openTasks.length,
            minutes: c.totalMinutes(week),
            daily: c.dailyMinutes(week),
          );
          final tasks = c.todayTasks;
          final plan = ApplianceListGroup(
            key: const ValueKey('today-plan'),
            header: w.todaysPlan,
            children: [
              if (tasks.isEmpty) ApplianceListTile(title: w.noTasksToday),
              for (final task in tasks) _planKey(task),
              ApplianceListTile(
                key: const ValueKey('today-plan-all'),
                title: w.viewTasks,
                subtitle: tasks.isEmpty
                    ? null
                    : w.progress(
                        tasks.where((t) => t.done).length,
                        tasks.length,
                      ),
                leading: const Icon(
                  LucideIcons.listChecks,
                  key: ValueKey('today-plan-lead-all'),
                ),
                style: const ApplianceStyle(
                  minimumSize: WidgetStatePropertyAll(Size(48, 64)),
                  padding: WidgetStatePropertyAll(
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                ),
                onTap: () => go(Place.tasks),
              ),
            ],
          );
          final blocks = _timelinePlate('blocks', w.timeBlocks, w.noBlocks, [
            for (final e in c.todayBlocks)
              ApplianceTimelineEntry(
                title: w.text(e.note),
                detail: c.projectName(e.project),
                time: w.timeRange(e),
              ),
          ]);
          final later = ApplianceListGroup(
            header: w.laterThisWeek,
            children: [
              for (final task in c.laterThisWeek)
                ApplianceListTile(
                  title: w.text(task.title),
                  subtitle: MediaQuery.textScalerOf(ctx).scale(1) >= 1.6
                      ? '${c.projectName(task.project)}${w.dot}${w.weekday(task.due)}'
                      : c.projectName(task.project),
                  leading: Icon(
                    LucideIcons.calendarDays,
                    key: ValueKey('today-later-lead-${task.id}'),
                  ),
                  trailingText: MediaQuery.textScalerOf(ctx).scale(1) >= 1.6
                      ? null
                      : w.weekday(task.due),
                  onTap: () => open(task),
                ),
              if (c.laterThisWeek.isEmpty) ApplianceListTile(title: w.allClear),
            ],
          );
          final people = ApplianceListGroup(
            header: w.teamActivity,
            children: [for (final p in team) _person(p)],
          );
          final feed = StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, snapshot) =>
                _timelinePlate('feed', w.recentActivity, w.noActivity, [
                  for (final e in c.data.activity)
                    ApplianceTimelineEntry(
                      title: w.eventAction(e, c.personName(e.person)),
                      detail: w.text(e.subject),
                      time: w.timeAgo(e.at, snapshot.data!),
                    ),
                ]),
          );
          Widget column(List<Widget> children) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 16,
            children: children,
          );
          return column([
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}',
                  style: theme.textTheme.legend,
                ),
                Semantics(
                  header: true,
                  child: Text(w.greeting, style: theme.textTheme.title),
                ),
              ],
            ),
            if (width >= 610)
              AppliancePanel(
                key: const ValueKey('today-timer-card'),
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.fill,
                  columnWidths: const {
                    0: FlexColumnWidth(6),
                    1: FixedColumnWidth(20),
                    2: FlexColumnWidth(5),
                  },
                  children: [
                    TableRow(
                      children: [
                        // Let text and font changes set the row's real height.
                        TableCell(
                          verticalAlignment: TableCellVerticalAlignment.top,
                          child: _timerConsole(),
                        ),
                        const SizedBox(),
                        summary,
                      ],
                    ),
                  ],
                ),
              )
            else ...[
              AppliancePanel(
                key: const ValueKey('today-timer-card'),
                child: _timerConsole(),
              ),
              AppliancePanel(child: summary),
            ],
            if (width >= 610)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(flex: 6, child: column([plan, blocks, later])),
                  Expanded(flex: 5, child: column([people, feed])),
                ],
              )
            else ...[
              plan,
              blocks,
              people,
              feed,
              later,
            ],
          ]);
        },
      ),
    ),
  );

  Widget _timerConsole() {
    final colors = theme.colors, type = theme.textTheme;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = task != null && timer != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    Future<void> pick() async {
      final selected = await _raise<String>(
        context: context,
        title: active ? w.switchTask : w.startTimer,
        cancel: w.cancel,
        builder: (ctx) => ApplianceCommandPalette(
          hintText: w.search,
          emptyLabel: w.noMatches,
          commands: [
            for (final item in choices)
              RawCommand(
                label: w.text(item.title),
                group: c.projectName(item.project),
                onPressed: () => Navigator.pop(ctx, item.id),
              ),
          ],
        ),
      );
      if (mounted && selected != null) c.track(selected);
    }

    Widget reading(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: AlignmentDirectional.centerStart,
        child: Semantics(
          identifier: 'stint-elapsed',
          label: w.elapsedLabel(value),
          excludeSemantics: true,
          child: Text(
            value,
            key: const ValueKey('today-timer-digits'),
            textDirection: TextDirection.ltr,
            style: type.display.copyWith(
              fontSize: 44,
              height: 1.05,
              color: colors.onDisplay,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    final well = AnimatedApplianceSurface(
      key: const ValueKey('today-timer-well'),
      face: ApplianceFace.well(colors, fill: colors.display),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 5,
          children: [
            Row(
              spacing: 8,
              children: [
                // The Latin legend's ink sits below its line-box centre.
                Transform.translate(
                  offset: Offset(
                    0,
                    w.arabic ? 0 : MediaQuery.textScalerOf(context).scale(2),
                  ),
                  child: ApplianceLamp(
                    key: const ValueKey('today-timer-lamp'),
                    lit: active,
                    size: 9,
                  ),
                ),
                Flexible(
                  child: Text(
                    active ? w.runningTimer : w.stoppedTimer,
                    key: const ValueKey('today-timer-label'),
                    style: type.legend.copyWith(color: colors.onDisplay),
                  ),
                ),
              ],
            ),
            _TimerDigits(
              taskId: task?.id,
              child: timer == null
                  ? reading(c.repository.now())
                  : StreamBuilder<DateTime>(
                      stream: c.ticks(const Duration(seconds: 1)),
                      initialData: c.repository.now(),
                      builder: (_, snapshot) => reading(snapshot.data!),
                    ),
            ),
            if (timer != null)
              Text(
                w.since(timer.start),
                style: type.secondary.copyWith(color: colors.onDisplay),
              ),
          ],
        ),
      ),
    );
    final buttons = <Widget>[
      if (active)
        ApplianceButton.filled(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: const Icon(LucideIcons.square, size: 14),
          onPressed: c.stopTimer,
        ),
      if (active)
        ApplianceButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          onPressed: choices.isEmpty ? null : pick,
        )
      else
        ApplianceButton.filled(
          w.startTimer,
          key: const ValueKey('today-action-first'),
          icon: const Icon(LucideIcons.play, size: 16),
          onPressed: choices.isEmpty ? null : pick,
        ),
    ];
    // Side by side while each key's words fit its half on one line.
    final keys = active
        ? StintPair(first: buttons.first, second: buttons.last, runSpacing: 6)
        : Row(children: [Expanded(child: buttons.single)]);
    final taskInfo = Column(
      key: const ValueKey('today-timer-title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Text(active ? w.text(task.title) : w.chooseTask, style: type.title),
        if (active)
          Text(c.projectName(task.project), style: type.secondary)
        else if (choices.isEmpty)
          Text(w.noTimerTasks, style: type.secondary),
      ],
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [well, taskInfo, keys],
    );
  }

  Widget _planKey(Task task) {
    final colors = theme.colors;
    final running = c.data.timer?.taskId == task.id;
    return RawButton(
      key: ValueKey('plan-${task.id}'),
      button: false,
      checked: task.done,
      excludeSemantics: true,
      semanticLabel: [
        w.text(task.title),
        c.projectName(task.project),
        if (running) w.runningTimer,
      ].join(', '),
      onPressed: () => c.changeTasks([task.id], done: !task.done),
      builder: (ctx, states, _) {
        final down = task.done || states.contains(WidgetState.pressed);
        final focus = states.contains(WidgetState.focused);
        final face = down
            ? ApplianceFace.keyDown(
                colors,
                radius: ApplianceTheme.of(context).radiusSmallKey,
              )
            : ApplianceFace.key(
                colors,
                radius: ApplianceTheme.of(context).radiusSmallKey,
              );
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            spacing: 12,
            children: [
              AnimatedApplianceSurface(
                key: ValueKey('today-plan-lead-${task.id}'),
                face: face.copyWith(focus: focus ? colors.focus : null),
                child: SizedBox.square(
                  dimension: 24,
                  child: Center(
                    child: task.done
                        ? Icon(LucideIcons.check, size: 16, color: colors.print)
                        : ApplianceLamp(
                            lit: focus || states.contains(WidgetState.hovered),
                            size: 7,
                          ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    Text(
                      w.text(task.title),
                      style: theme.textTheme.body.copyWith(
                        fontWeight: FontWeight.w500,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    Text(
                      c.projectName(task.project),
                      style: theme.textTheme.secondary,
                    ),
                  ],
                ),
              ),
              // The timer's indicator lamp, lit on the task it runs on.
              if (running)
                ApplianceLamp(
                  key: const ValueKey('today-plan-running'),
                  lit: true,
                  size: 9,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _person(Person person) {
    final name = w.text(person.name), task = c.currentTask(person.id);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      child: Row(
        spacing: 8,
        children: [
          ExcludeSemantics(
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.15,
              child: ApplianceAvatar(
                key: ValueKey('today-team-lead-${person.id}'),
                name: name,
                size: 32,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(name, style: theme.textTheme.label),
                Text(
                  task == null ? w.notTracking : w.text(task.title),
                  style: theme.textTheme.secondary,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _timelinePlate(
    String section,
    String title,
    String empty,
    List<ApplianceTimelineEntry> entries,
  ) {
    final type = theme.textTheme;
    Widget timeline(BuildContext context, BoxConstraints box) {
      final stacked =
          box.maxWidth < MediaQuery.textScalerOf(context).scale(230);
      final rtl = Directionality.of(context) == TextDirection.rtl;
      Widget entryRow(int i, ApplianceTimelineEntry entry) {
        final heading = Text(entry.title, style: type.body);
        final time = Text(
          entry.time!,
          style: type.secondary,
          textDirection: section == 'blocks' ? TextDirection.ltr : null,
          textAlign: (rtl != stacked) ? TextAlign.left : TextAlign.right,
          softWrap: false,
        );
        return Semantics(
          container: true,
          excludeSemantics: true,
          label: [entry.time, entry.title, entry.detail].join(', '),
          child: Stack(
            children: [
              if (i < entries.length - 1)
                PositionedDirectional(
                  start: 11,
                  top: 11,
                  bottom: 0,
                  width: 2,
                  child: ColoredBox(color: theme.colors.seamShade),
                ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: i == entries.length - 1 ? 0 : ApplianceSpacing.large,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    SizedBox(
                      width: 24,
                      child: Center(
                        child: Container(
                          key: ValueKey('today-$section-lead-$i'),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colors.face,
                            border: Border.all(
                              color: theme.colors.seamShade,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: const ApplianceLamp(lit: false, size: 10),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (stacked) ...[
                            heading,
                            time,
                          ] else
                            Row(
                              spacing: 8,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Expanded(child: heading),
                                time,
                              ],
                            ),
                          Text(entry.detail!, style: type.secondary),
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

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, entry) in entries.indexed) entryRow(i, entry),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ApplianceSectionHeader(title),
        AppliancePanel(
          child: entries.isEmpty
              ? Text(empty, style: type.body)
              : LayoutBuilder(builder: timeline),
        ),
      ],
    );
  }
}

/// The LCD ink settles when the tracked task changes. Each second otherwise
/// replaces only the digits, leaving the lamp, well and controls at rest.
class _TimerDigits extends StatefulWidget {
  const _TimerDigits({required this.taskId, required this.child});
  final String? taskId;
  final Widget child;
  @override
  State<_TimerDigits> createState() => _TimerDigitsState();
}

class _TimerDigitsState extends State<_TimerDigits>
    with SingleTickerProviderStateMixin {
  late final ink = AnimationController(vsync: this, value: 1);

  @override
  void didUpdateWidget(_TimerDigits oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.taskId != oldWidget.taskId && !rawReduceMotionOf(context)) {
      ink.value = .35;
      ink.springTo(
        1,
        rawSpring(
          dampingRatio: ApplianceMotion.lamp.dampingRatio,
          stiffness: ApplianceMotion.lamp.stiffness,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: ink, child: widget.child);
  @override
  void dispose() {
    ink.dispose();
    super.dispose();
  }
}
