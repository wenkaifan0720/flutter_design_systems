part of '../stint_material.dart';

extension _Today on _Desk {
  Widget today() {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final tasks = c.todayTasks, later = c.laterThisWeek;
    final blocks = c.todayBlocks;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final plan = _TodayCard(
      w.todaysPlan,
      key: const ValueKey('today-plan'),
      detail: tasks.isEmpty
          ? null
          : w.progress(tasks.where((t) => t.done).length, tasks.length),
      children: [
        if (tasks.isEmpty) _note(w.noTasksToday),
        for (final task in tasks)
          MergeSemantics(
            key: ValueKey('plan-${task.id}'),
            child: Semantics(
              checked: task.done,
              child: _tile(
                _lead(
                  'plan',
                  task.id,
                  Checkbox(
                    value: task.done,
                    onChanged: (_) =>
                        c.changeTasks([task.id], done: !task.done),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
                w.text(task.title),
                c.projectName(task.project),
                done: task.done,
                trailing: c.data.timer?.taskId == task.id
                    ? Icon(
                        Icons.timer_outlined,
                        key: const ValueKey('today-plan-running'),
                        color: colors.primary,
                        semanticLabel: w.runningTimer,
                      )
                    : null,
                onTap: () => c.changeTasks([task.id], done: !task.done),
              ),
            ),
          ),
        _tile(
          _lead('plan', 'all', const Icon(Icons.list_alt)),
          w.viewTasks,
          null,
          onTap: () => go(Place.tasks),
        ),
      ],
    );
    final schedule = _TodayCard(
      w.timeBlocks,
      children: [
        if (blocks.isEmpty) _note(w.noBlocks),
        for (final (i, entry) in blocks.indexed)
          _tile(
            _lead('blocks', i, Icon(Icons.schedule, color: colors.primary)),
            w.text(entry.note),
            '${w.timeRange(entry)}${w.dot}${c.projectName(entry.project)}',
          ),
        _tile(
          _lead('blocks', blocks.length, const Icon(Icons.calendar_view_week)),
          w.seeTime,
          null,
          onTap: () => go(Place.time),
        ),
      ],
    );
    final upcoming = _TodayCard(
      w.laterThisWeek,
      children: [
        if (later.isEmpty) _note(w.allClear),
        for (final task in later)
          _tile(
            _lead('later', task.id, const Icon(Icons.event_outlined)),
            w.text(task.title),
            '${w.weekday(task.due)}${w.dot}${c.projectName(task.project)}',
            disclose: true,
            onTap: () => open(task),
          ),
      ],
    );
    final roster = _TodayCard(
      w.teamActivity,
      children: [
        for (final (i, person) in team.indexed)
          _tile(
            _lead(
              'team',
              person.id,
              CircleAvatar(
                radius: 17,
                backgroundColor: [
                  colors.primaryContainer,
                  colors.secondaryContainer,
                  colors.tertiaryContainer,
                ][i % 3],
                foregroundColor: [
                  colors.onPrimaryContainer,
                  colors.onSecondaryContainer,
                  colors.onTertiaryContainer,
                ][i % 3],
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(w.text(person.name).characters.first),
                ),
              ),
            ),
            w.text(person.name),
            switch (c.currentTask(person.id)) {
              final task? => w.text(task.title),
              null => w.notTracking,
            },
          ),
      ],
    );
    final feed = StreamBuilder<DateTime>(
      stream: c.ticks(const Duration(minutes: 1)),
      initialData: c.repository.now(),
      builder: (context, snapshot) => _TodayCard(
        w.recentActivity,
        children: [
          if (c.data.activity.isEmpty) _note(w.noActivity),
          for (final (i, event) in c.data.activity.indexed)
            _tile(
              _lead(
                'feed',
                i,
                Icon(switch (event.kind) {
                  ActivityKind.finished => Icons.task_alt,
                  ActivityKind.started => Icons.play_circle_outline,
                  ActivityKind.commented => Icons.chat_bubble_outline,
                  ActivityKind.logged => Icons.history,
                }, color: colors.onSurfaceVariant),
              ),
              w.eventAction(event, c.personName(event.person)),
              '${w.text(event.subject)}${w.dot}${w.timeAgo(event.at, snapshot.data!).replaceAll(' ', '\u00a0')}',
            ),
        ],
      ),
    );
    Widget stack(List<Widget> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 16,
      children: items,
    );
    return LayoutBuilder(
      builder: (context, bounds) {
        final inset = bounds.maxWidth >= 850 ? 28.0 : 16.0;
        final width = bounds.maxWidth - 2 * inset;
        final grid = width >= 555 * scale;
        return SizedBox.expand(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(inset, 12, inset, 24),
            child: stack([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    '${w.teamName}${w.dot}${w.shortDate(studyToday)}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      w.greeting,
                      style: scale > 1.5 && !grid
                          ? theme.textTheme.titleLarge
                          : theme.textTheme.headlineMedium,
                    ),
                  ),
                ],
              ),
              _timerCard(width, scale),
              if (grid) ...[
                // One height while the plan has rows; a day with nothing
                // due keeps its card to its two rows beside the team.
                Table(
                  columnWidths: const {1: FixedColumnWidth(16)},
                  defaultVerticalAlignment: tasks.isEmpty
                      ? TableCellVerticalAlignment.top
                      : TableCellVerticalAlignment.intrinsicHeight,
                  children: [
                    TableRow(children: [plan, const SizedBox.shrink(), roster]),
                  ],
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 16,
                  children: [
                    Expanded(child: stack([schedule, upcoming])),
                    Expanded(child: feed),
                  ],
                ),
              ] else ...[
                plan,
                schedule,
                upcoming,
                roster,
                feed,
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _note(String value) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Text(value),
  );

  Widget _lead(String group, Object id, Widget mark) => SizedBox(
    width: 36,
    child: Center(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: IgnorePointer(
            child: KeyedSubtree(
              key: ValueKey('today-$group-lead-$id'),
              child: mark,
            ),
          ),
        ),
      ),
    ),
  );

  Widget _tile(
    Widget leading,
    String title,
    String? subtitle, {
    bool done = false,
    bool disclose = false,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      child: ListTile(
        textColor: onTap != null && subtitle == null ? colors.primary : null,
        iconColor: onTap != null && subtitle == null ? colors.primary : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        horizontalTitleGap: 12,
        minLeadingWidth: 36,
        minTileHeight: 64,
        leading: leading,
        title: Text(
          title,
          style: TextStyle(
            color: done ? colors.onSurfaceVariant : null,
            decoration: done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: subtitle == null ? null : Text(subtitle),
        trailing:
            trailing ??
            (onTap != null && (subtitle == null || disclose)
                ? const Icon(Icons.chevron_right)
                : null),
        onTap: onTap,
      ),
    );
  }

  Future<void> _pickTimer(bool active, List<Task> choices) async {
    final id = await _raise<String>(
      context,
      (ctx) => _TaskPicker(c, active ? w.switchTask : w.startTimer, choices),
    );
    if (mounted && id != null) c.track(id);
  }

  Widget _timerCard(double width, double scale) {
    final theme = Theme.of(context), colors = theme.colorScheme;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final latest = c.data.activity.firstOrNull;
    final receipt =
        !active &&
            latest != null &&
            latest.person == 'maya' &&
            latest.kind == ActivityKind.logged
        ? latest
        : null;
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    const inset = 20.0, gap = 16.0;
    final inner = width - inset * 2;
    final split = inner >= 545 * scale;
    final columnWidth = split ? (inner - gap) / 2 : inner;
    final pick = choices.isEmpty ? null : () => _pickTimer(active, choices);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final style = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 48)),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? BorderSide(color: colors.primary, width: 2)
            : null,
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
    final stop = FilledButton.icon(
      key: const ValueKey('today-action-first'),
      style: style,
      onPressed: c.stopTimer,
      icon: const Icon(Icons.stop_rounded),
      label: Text(w.stopTimer),
    );
    final change = active
        ? OutlinedButton(
            key: const ValueKey('today-action-last'),
            style: style,
            onPressed: pick,
            child: Text(w.switchTask),
          )
        : FilledButton.icon(
            style: style,
            onPressed: pick,
            icon: const Icon(Icons.play_arrow),
            label: Text(w.startTimer),
          );
    final buttons = !active
        ? change
        : columnWidth < 235 * scale
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [stop, change],
          )
        : IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                Expanded(child: stop),
                Expanded(child: change),
              ],
            ),
          );
    Widget digits(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      final saved = receipt == null ? null : w.duration(receipt.minutes);
      return Semantics(
        identifier: 'stint-elapsed',
        label: saved ?? w.elapsedLabel(value),
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            saved ?? value,
            key: const ValueKey('today-timer-digits'),
            textDirection: saved == null ? TextDirection.ltr : null,
            style: theme.textTheme.displaySmall?.copyWith(
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colors.onSurface,
            ),
          ),
        ),
      );
    }

    final clock = timer == null
        ? digits(c.repository.now())
        : StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(seconds: 1)),
            initialData: c.repository.now(),
            builder: (context, snapshot) => digits(snapshot.data!),
          );
    final timerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 12,
      children: [
        AnimatedContainer(
          key: const ValueKey('today-timer-well'),
          duration: reduceMotion
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: active
                ? colors.primaryContainer
                : colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 3,
            children: [
              Row(
                spacing: 8,
                children: [
                  Icon(
                    Icons.timer_outlined,
                    key: const ValueKey('today-timer-lamp'),
                    size: 20,
                    color: colors.primary,
                  ),
                  Expanded(
                    child: Text(
                      active ? w.runningTimer : w.stoppedTimer,
                      key: const ValueKey('today-timer-label'),
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                      ),
                    ),
                  ),
                ],
              ),
              AnimatedSwitcher(
                key: const ValueKey('today-timer-title'),
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...previous, ?current],
                ),
                child: Text(
                  active
                      ? w.text(task.title)
                      : receipt == null
                      ? w.chooseTask
                      : w.text(receipt.subject),
                  key: ValueKey(task?.id),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
              if (active)
                Text(
                  '${c.projectName(task.project)}${w.dot}${w.since(timer.start)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              else if (receipt != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    w.eventAction(receipt, c.personName(receipt.person)),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              if (!active && choices.isEmpty) Text(w.noTimerTasks),
              clock,
            ],
          ),
        ),
        buttons,
      ],
    );
    final week = mondayOf(studyToday);
    Widget stat(int i, String label, String value) => Expanded(
      child: Semantics(
        container: true,
        excludeSemantics: true,
        label: label,
        value: value,
        child: Container(
          key: ValueKey(i == 0 ? 'today-stat-tasks' : 'today-stat-hours'),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: colors.secondaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.start,
            spacing: 2,
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: scale > 1.5 && columnWidth < 330 * scale
                      ? 32 * scale
                      : 0,
                ),
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
              FittedBox(
                alignment: AlignmentDirectional.centerStart,
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  maxLines: 1,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: columnWidth < 340 ? 18 : null,
                    color: colors.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final chart = _DayBars(c, week, width: columnWidth);
    final stats = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              stat(0, w.openTasks, w.number(c.openTasks.length)),
              stat(1, w.hoursThisWeek, w.duration(c.totalMinutes(week))),
            ],
          ),
        ),
        if (split)
          Expanded(child: chart)
        else
          SizedBox(height: 68 + 16 * scale, child: chart),
      ],
    );
    return Card.filled(
      key: const ValueKey('today-timer-card'),
      semanticContainer: false,
      margin: EdgeInsets.zero,
      color: colors.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(inset),
        child: split
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: gap,
                  children: [
                    Expanded(child: timerColumn),
                    Expanded(child: stats),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [timerColumn, stats],
              ),
      ),
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard(
    this.title, {
    super.key,
    this.detail,
    required this.children,
  });
  final String title;
  final String? detail;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card.outlined(
      semanticContainer: false,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.only(top: 14, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(title, style: theme.textTheme.titleLarge),
                  ),
                  if (detail != null)
                    Text(
                      detail!,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DayBars extends StatelessWidget {
  const _DayBars(this.c, this.week, {required this.width});
  final StintController c;
  final DateTime week;
  final double width;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context), colors = theme.colorScheme, w = c.words;
    final days = c.dailyMinutes(week),
        peak = days.fold(0, (a, b) => a > b ? a : b);
    final axisMinutes = ((peak + 59) ~/ 60) * 60;
    final scaler = MediaQuery.textScalerOf(context);
    final labels = [
      for (var i = 0; i < days.length; i++)
        width < 240
            ? w.weekdayNarrow(addDays(week, i))
            : w.weekdayShort(addDays(week, i)),
    ];
    final labelStyle = theme.textTheme.labelMedium!;
    final fontSize = labelStyle.fontSize!;
    final requestedSize = scaler.scale(fontSize);
    var labelScaler = scaler;
    if (requestedSize > fontSize) {
      final measure = TextPainter(
        textDirection: Directionality.of(context),
        textScaler: scaler,
      );
      var widest = 0.0;
      for (final label in labels) {
        measure.text = TextSpan(text: label, style: labelStyle);
        measure.layout();
        if (measure.width > widest) widest = measure.width;
      }
      measure.dispose();
      final slotWidth = (width - 12 - scaler.scale(30)) / days.length;
      final ratio = ((slotWidth - 5) / widest).clamp(.01, 1.0);
      labelScaler = TextScaler.linear(requestedSize * ratio / fontSize);
    }
    return Container(
      key: const ValueKey('today-chart'),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 5),
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            start: scaler.scale(30),
            end: 0,
            child: SizedBox(
              height: 1,
              child: ColoredBox(
                color: colors.outlineVariant.withValues(alpha: .6),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: MediaQuery.textScalerOf(context).scale(30),
                child: Align(
                  alignment: AlignmentDirectional.topStart,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      w.duration(axisMinutes),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
              for (final (i, n) in days.indexed)
                Expanded(
                  child: Semantics(
                    container: true,
                    label: w.weekday(addDays(week, i)),
                    value: w.duration(n),
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: .58,
                              heightFactor: n == 0 ? null : n / axisMinutes,
                              child: Container(
                                key: ValueKey('today-day-slot-$i'),
                                height: n == 0 ? 2 : null,
                                decoration: BoxDecoration(
                                  color: n == 0
                                      ? colors.outlineVariant
                                      : i == studyToday.weekday - 1
                                      ? colors.primary
                                      : colors.secondary,
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labels[i],
                            textScaler: labelScaler,
                            key: ValueKey('today-day-label-$i'),
                            maxLines: 1,
                            textAlign: TextAlign.center,
                            style: labelStyle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TaskPicker extends StatefulWidget {
  const _TaskPicker(this.c, this.title, this.tasks);
  final StintController c;
  final String title;
  final List<Task> tasks;
  @override
  State<_TaskPicker> createState() => _TaskPickerState();
}

class _TaskPickerState extends State<_TaskPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final c = widget.c, w = c.words;
    final matches = widget.tasks
        .where(
          (t) => w
              .text(t.title)
              .toLowerCase()
              .contains(query.trim().toLowerCase()),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .72,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Semantics(
                          container: true,
                          header: true,
                          child: Text(
                            widget.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ),
                      CloseButton(onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: w.search,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) => setState(() => query = v),
                    onSubmitted: (_) {
                      if (matches.length == 1) {
                        Navigator.pop(context, matches.single.id);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  if (matches.isEmpty) ListTile(title: Text(w.noMatches)),
                  for (final t in matches)
                    ListTile(
                      contentPadding: const EdgeInsetsDirectional.symmetric(
                        horizontal: 20,
                      ),
                      title: Text(w.text(t.title)),
                      subtitle: Text(c.projectName(t.project)),
                      onTap: () => Navigator.pop(context, t.id),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
