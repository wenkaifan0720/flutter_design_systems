part of '../stint_minimal.dart';

extension _Today on _WorkspaceState {
  Widget today() {
    final t = context.minimalTheme;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    final narrowType = MediaQuery.sizeOf(context).width / scale < 275;
    return MinimalScaffold(
      topBar: MinimalAppBar(
        title: w.today,
        subtitle: narrowType ? null : w.teamName,
        large: false,
        actions: [commandKey],
      ),
      body: dataBody(
        () => LayoutBuilder(
          builder: (ctx, box) {
            final wide =
                box.maxWidth >= 610 * MediaQuery.textScalerOf(ctx).scale(1);
            final week = mondayOf(studyToday);
            final stats = _WeekSummary(
              words: w,
              tasks: c.openTasks.length,
              minutes: c.totalMinutes(week),
              daily: c.dailyMinutes(week),
              openTasks: () => go(Place.tasks),
              openTime: () => go(Place.time),
            );
            final tasks = c.todayTasks;
            final plan = MinimalSection(
              key: const ValueKey('today-plan'),
              title: w.todaysPlan,
              count: tasks.isEmpty
                  ? null
                  : w.progress(tasks.where((t) => t.done).length, tasks.length),
              child: tasks.isEmpty
                  ? Text(w.noTasksToday, style: t.body)
                  : MinimalListSection(
                      gutter: false,
                      children: [for (final task in tasks) _planRow(task)],
                    ),
            );
            final blocks = MinimalSection(
              title: w.timeBlocks,
              child: _timeline('blocks', w.noBlocks, [
                for (final e in c.todayBlocks)
                  (w.timeRange(e), w.text(e.note), c.projectName(e.project)),
              ]),
            );
            final later = MinimalSection(
              title: w.laterThisWeek,
              actionLabel: narrowType ? null : w.viewTasks,
              onAction: () => go(Place.tasks),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (c.laterThisWeek.isEmpty)
                    Text(w.allClear, style: t.body)
                  else
                    MinimalListSection(
                      gutter: false,
                      children: [
                        for (final task in c.laterThisWeek)
                          _laterRow(
                            task,
                            stacked:
                                scale >= MinimalChromeMetrics.rowStackScale,
                          ),
                      ],
                    ),
                  if (narrowType)
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: MinimalButton(
                        w.viewTasks,
                        variant: MinimalButtonVariant.secondary,
                        onPressed: () => go(Place.tasks),
                      ),
                    ),
                ],
              ),
            );
            final people = MinimalSection(
              title: w.teamActivity,
              child: MinimalListSection(
                gutter: false,
                children: [for (final person in team) _personRow(person)],
              ),
            );
            final feed = MinimalSection(
              title: w.recentActivity,
              child: StreamBuilder<DateTime>(
                stream: c.ticks(const Duration(minutes: 1)),
                initialData: c.repository.now(),
                builder: (_, snapshot) => _timeline('feed', w.noActivity, [
                  for (final event in c.data.activity)
                    (
                      w.timeAgo(event.at, snapshot.data!),
                      w.eventAction(event, c.personName(event.person)),
                      w.text(event.subject),
                    ),
                ]),
              ),
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
                    style: t.mono.copyWith(color: t.mutedForeground),
                  ),
                  Semantics(
                    header: true,
                    child: Text(w.greeting, style: t.display),
                  ),
                ],
              ),
              _timerHero(),
              if (wide)
                _todayColumns(
                  column([plan, blocks, later]),
                  column([stats, people, feed]),
                )
              else ...[
                stats,
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
  }

  Widget _todayColumns(
    Widget leading,
    Widget trailing, {
    CrossAxisAlignment alignment = CrossAxisAlignment.start,
  }) => Row(
    crossAxisAlignment: alignment,
    spacing: 32,
    children: [
      Expanded(flex: 6, child: leading),
      Expanded(flex: 5, child: trailing),
    ],
  );

  Widget _timerHero() {
    final t = context.minimalTheme;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    Future<void> pick() async {
      final selected = await _raise<String>(
        context,
        title: active ? w.switchTask : w.startTimer,
        builder: (ctx) => ScrollConfiguration(
          behavior: _TaskPickerScroll(t.textTertiary),
          child: MinimalCommand(
            hintText: w.search,
            emptyTitle: w.noMatches,
            actions: [
              for (final item in choices)
                MinimalCommandItem(
                  w.text(item.title),
                  detail: c.projectName(item.project),
                  onSelected: () => Navigator.pop(ctx, item.id),
                ),
            ],
          ),
        ),
      );
      if (mounted && selected != null) c.track(selected);
    }

    final info = Column(
      key: const ValueKey('today-timer-title'),
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 4,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 7,
          children: [
            AnimatedContainer(
              duration: context.minimalStill
                  ? Duration.zero
                  : MinimalMotion.base,
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Running is a state, said in ink (the accent is the act's).
                color: active ? t.foreground : t.mutedForeground,
              ),
            ),
            Flexible(
              child: Text(
                active ? w.runningTimer : w.stoppedTimer,
                style: t.label.copyWith(
                  color: active ? t.foreground : t.mutedForeground,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        AnimatedSwitcher(
          duration: context.minimalStill ? Duration.zero : MinimalMotion.base,
          switchInCurve: MinimalMotion.out,
          child: Text(
            active ? w.text(task.title) : w.chooseTask,
            key: ValueKey(task?.id),
            style: t.h2,
          ),
        ),
        if (active)
          Text(
            c.projectName(task.project),
            style: t.bodySmall.copyWith(color: t.mutedForeground),
          )
        else if (choices.isEmpty)
          Text(w.noTimerTasks, style: t.bodySmall),
      ],
    );
    Widget clock(DateTime now) {
      final reading = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return Column(
        key: const ValueKey('today-timer-digits'),
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Semantics(
            identifier: 'stint-elapsed',
            label: w.elapsedLabel(reading),
            excludeSemantics: true,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                reading,
                textDirection: TextDirection.ltr,
                style: t.mono.copyWith(
                  fontSize: 36,
                  height: 1.1,
                  letterSpacing: -1.5,
                  fontWeight: FontWeight.w500,
                  color: active ? t.foreground : t.mutedForeground,
                ),
              ),
            ),
          ),
          if (timer != null)
            Text(
              w.since(timer.start),
              style: t.caption.copyWith(color: t.mutedForeground),
            ),
        ],
      );
    }

    final clockFace = timer == null
        ? clock(c.repository.now())
        : StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(seconds: 1)),
            initialData: c.repository.now(),
            builder: (_, snapshot) => clock(snapshot.data!),
          );
    // Balance the ink of the mono numerals and caption against the key faces.
    final display = Padding(
      padding: const EdgeInsets.only(bottom: 1.5),
      child: clockFace,
    );
    final controls = Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        MinimalButton(
          active ? w.stopTimer : w.startTimer,
          key: const ValueKey('today-action-first'),
          icon: active ? LucideIcons.square : LucideIcons.play,
          onPressed: active
              ? c.stopTimer
              : choices.isEmpty
              ? null
              : pick,
        ),
        if (active)
          MinimalButton(
            w.switchTask,
            key: const ValueKey('today-action-last'),
            icon: LucideIcons.arrowLeftRight,
            variant: MinimalButtonVariant.secondary,
            onPressed: choices.isEmpty ? null : pick,
          ),
      ],
    );
    return MinimalCard(
      key: const ValueKey('today-timer-card'),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: LayoutBuilder(
        builder: (ctx, box) {
          final width = box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1);
          const inset = 20.0;
          if (width >= 900) {
            return _todayColumns(
              Padding(
                padding: const EdgeInsetsDirectional.only(start: inset),
                child: info,
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(end: inset),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  spacing: 8,
                  children: [
                    Flexible(child: display),
                    controls,
                  ],
                ),
              ),
              alignment: CrossAxisAlignment.center,
            );
          }
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: inset),
            child: width >= 600
                ? Row(
                    spacing: 16,
                    children: [
                      Expanded(
                        child: Row(
                          spacing: 16,
                          children: [
                            Flexible(child: info),
                            display,
                          ],
                        ),
                      ),
                      controls,
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 12,
                    children: [info, display, controls],
                  ),
          );
        },
      ),
    );
  }

  Widget _timeline(
    String section,
    String empty,
    List<(String, String, String)> rows,
  ) {
    final t = context.minimalTheme;
    if (rows.isEmpty) return Text(empty, style: t.bodySmall);
    final scaler = MediaQuery.textScalerOf(context);
    final stacked = scaler.scale(1) >= MinimalChromeMetrics.rowStackScale;
    final rtl = Directionality.of(context) == TextDirection.rtl;
    Widget row(int i, (String, String, String) item) {
      final (time, title, detail) = item;
      final stamp = Text(
        time,
        key: ValueKey('today-$section-lead-$i'),
        textDirection: section == 'blocks' ? TextDirection.ltr : null,
        textAlign: stacked
            ? (rtl ? TextAlign.right : TextAlign.left)
            : TextAlign.center,
        style: t.mono.copyWith(color: t.mutedForeground),
      );
      final event = Text.rich(
        TextSpan(
          children: [
            TextSpan(text: title),
            TextSpan(
              text: ' · $detail',
              style: t.bodySmall.copyWith(color: t.mutedForeground),
            ),
          ],
        ),
        style: t.bodySmall,
      );
      return Semantics(
        container: true,
        excludeSemantics: true,
        label: '$time, $title, $detail',
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: stacked
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [stamp, event],
                )
              : Row(
                  spacing: 10,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    SizedBox(width: scaler.scale(92), child: stamp),
                    Expanded(child: event),
                  ],
                ),
        ),
      );
    }

    return MinimalListSection(
      gutter: false,
      children: [for (final (i, item) in rows.indexed) row(i, item)],
    );
  }

  Widget _laterRow(Task task, {required bool stacked}) {
    final t = context.minimalTheme;
    final mark = MinimalIcon(
      LucideIcons.calendarDays,
      size: 16,
      key: ValueKey('today-later-lead-${task.id}'),
    );
    final title = w.text(task.title),
        project = c.projectName(task.project),
        due = w.weekday(task.due);
    if (!stacked) {
      return MinimalListTile(
        title: title,
        subtitle: project,
        meta: due,
        leading: mark,
        onTap: () => open(task),
      );
    }
    return MinimalPressable(
      onPressed: () => open(task),
      semanticLabel: '$title, $project, $due',
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          spacing: 10,
          children: [
            mark,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: t.body.copyWith(fontWeight: FontWeight.w500),
                  ),
                  Text(
                    '$project${w.dot}$due',
                    style: t.caption.copyWith(color: t.mutedForeground),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _planRow(Task task) {
    final t = context.minimalTheme;
    final running = c.data.timer?.taskId == task.id;
    return MinimalPressable(
      key: ValueKey('plan-${task.id}'),
      onPressed: () => c.changeTasks([task.id], done: !task.done),
      checked: task.done,
      semanticLabel: [
        w.text(task.title),
        c.projectName(task.project),
        if (running) w.runningTimer,
      ].join(', '),
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            spacing: 12,
            children: [
              MinimalCheckMark(
                key: ValueKey('today-plan-lead-${task.id}'),
                value: task.done,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 2,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: context.minimalStill
                          ? Duration.zero
                          : MinimalMotion.fast,
                      style: t.body.copyWith(
                        fontWeight: FontWeight.w500,
                        color: task.done ? t.mutedForeground : t.foreground,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                      child: Text(w.text(task.title)),
                    ),
                    Wrap(
                      spacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          c.projectName(task.project),
                          style: t.caption.copyWith(color: t.mutedForeground),
                        ),
                        // The task the timer runs on says so as the timer
                        // does: its dot and words, after the project.
                        if (running)
                          Text.rich(
                            key: const ValueKey('today-plan-running'),
                            TextSpan(
                              children: [
                                WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: Padding(
                                    padding: const EdgeInsetsDirectional.only(
                                      end: 6,
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: t.foreground,
                                      ),
                                      child: const SizedBox.square(
                                        dimension: 6,
                                      ),
                                    ),
                                  ),
                                ),
                                TextSpan(text: w.runningTimer),
                              ],
                            ),
                            style: t.caption.medium.c(t.foreground),
                          ),
                      ],
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

  Widget _personRow(Person person) {
    final t = context.minimalTheme;
    final name = w.text(person.name), task = c.currentTask(person.id);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        spacing: 10,
        children: [
          ExcludeSemantics(
            child: MinimalAvatar(
              name,
              key: ValueKey('today-team-lead-${person.id}'),
              size: 32,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 2,
              children: [
                Text(name, style: t.body.copyWith(fontWeight: FontWeight.w500)),
                Text(
                  task == null ? w.notTracking : w.text(task.title),
                  style: t.caption.copyWith(color: t.mutedForeground),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskPickerScroll extends MinimalScrollBehavior {
  const _TaskPickerScroll(super.thumb);

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => axisDirectionToAxis(details.direction) == Axis.vertical
      ? RawScrollbar(
          controller: details.controller,
          thumbColor: thumb,
          thumbVisibility: true,
          thickness: 3,
          radius: const Radius.circular(3),
          mainAxisMargin: 4,
          crossAxisMargin: 2,
          child: child,
        )
      : super.buildScrollbar(context, child, details);
}
