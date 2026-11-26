part of '../stint_material_expressive.dart';

extension _Today on _WorkspaceState {
  Widget today() => ExpressiveScaffold(
    topBar: ExpressiveAppBar(title: w.today, actions: [commandKey]),
    body: data(
      () => LayoutBuilder(
        builder: (ctx, box) {
          final scale = MediaQuery.textScalerOf(ctx).scale(1);
          final wide = box.maxWidth >= 575 * scale;
          final planLineHeight = scale > 1.3
              ? MediaQuery.textScalerOf(ctx).scale(24)
              : null;
          final plan = c.todayTasks,
              blocks = c.todayBlocks,
              later = c.laterThisWeek;
          final sections = [
            _section(
              w.todaysPlan,
              [
                for (final task in plan)
                  ExpressiveListTile.toggleable(
                    key: ValueKey('plan-${task.id}'),
                    style: ExpressiveComponentThemeData(
                      shape: WidgetStateProperty.resolveWith(
                        (states) =>
                            states.length == 1 &&
                                states.contains(WidgetState.selected)
                            ? RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(
                                    task.id == plan.first.id ? 16 : 4,
                                  ),
                                  bottom: const Radius.circular(4),
                                ),
                              )
                            : null,
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? theme.colors.surfaceContainer
                            : null,
                      ),
                    ),
                    title: Text(
                      w.text(task.title),
                      style: TextStyle(
                        color: task.done ? theme.colors.onSurfaceVariant : null,
                        decoration: task.done
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    // A done row is selected, which would brighten its
                    // project line past the other rows' at night.
                    subtitle: Text(
                      c.projectName(task.project),
                      style: TextStyle(color: theme.colors.onSurfaceVariant),
                    ),
                    value: task.done,
                    onChanged: (done) => c.changeTasks([task.id], done: done),
                    leading: _leading(
                      'plan-lead-${task.id}',
                      SizedBox(
                        height: planLineHeight,
                        child: Center(
                          child: ExpressiveCheckbox.mark(value: task.done),
                        ),
                      ),
                    ),
                    // The task the timer runs on carries the timer in a
                    // filled primary circle, M3's own way to make one glyph
                    // the one that matters.
                    trailing: task.id == c.data.timer?.taskId
                        ? ExpressiveTooltip.plain(
                            message: w.runningTimer,
                            child: SizedBox(
                              height: planLineHeight,
                              // As wide as the mark: a bare Center took the
                              // row's whole width from the title on a phone.
                              child: Center(
                                widthFactor: 1,
                                child: DecoratedBox(
                                  key: const ValueKey('today-plan-running'),
                                  decoration: ShapeDecoration(
                                    color: theme.colors.primary,
                                    shape: const CircleBorder(),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(5),
                                    child: ExpressiveIcon(
                                      ExpressiveSymbols.timer,
                                      size: 18,
                                      color: theme.colors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                        : null,
                    semanticLabel: [
                      w.text(task.title),
                      c.projectName(task.project),
                      if (task.id == c.data.timer?.taskId) w.runningTimer,
                    ].join(', '),
                  ),
                if (plan.isEmpty)
                  ExpressiveListTile(title: Text(w.noTasksToday)),
                ExpressiveListTile(
                  leading: _leading(
                    'plan-lead-all',
                    ExpressiveIcon(
                      ExpressiveSymbols.arrowForward,
                      color: theme.colors.primary,
                    ),
                  ),
                  title: Text(
                    w.viewTasks,
                    style: theme.type.labelLarge.copyWith(
                      color: theme.colors.primary,
                    ),
                  ),
                  onTap: () => go(Place.tasks),
                ),
              ],
              sectionKey: const ValueKey('today-plan'),
              pairedFace: wide && plan.isNotEmpty ? 'plan' : null,
              detail: plan.isEmpty
                  ? null
                  : w.progress(
                      plan.where((task) => task.done).length,
                      plan.length,
                    ),
            ),
            _timeBlocks(blocks),
            _section(w.laterThisWeek, [
              for (final (i, task) in later.indexed)
                ExpressiveListTile(
                  leading: _leading(
                    'later-lead-${task.id}',
                    const ExpressiveIcon(ExpressiveSymbols.calendarToday),
                  ),
                  title: Text(w.text(task.title)),
                  overline:
                      i == 0 ||
                          calendarDay(later[i - 1].due) != calendarDay(task.due)
                      ? Text(w.weekday(task.due))
                      : null,
                  subtitle: Text(c.projectName(task.project)),
                  semanticLabel: [
                    w.text(task.title),
                    c.projectName(task.project),
                    w.weekday(task.due),
                  ].join(', '),
                  onTap: () => open(task),
                ),
              if (later.isEmpty) ExpressiveListTile(title: Text(w.allClear)),
            ]),
          ];
          final people = _section(w.teamActivity, [
            for (final person in team)
              ExpressiveListTile(
                leading: _leading(
                  'team-lead-${person.id}',
                  ExpressiveAvatar(
                    name: w.text(person.name),
                    tone: ExpressiveMediaTone.of(person.name.$1),
                    size: ExpressiveAvatarSize.small,
                  ),
                ),
                title: Text(w.text(person.name)),
                subtitle: Text(switch (c.currentTask(person.id)) {
                  final task? => w.text(task.title),
                  null => w.notTracking,
                }),
              ),
          ], pairedFace: wide && plan.isNotEmpty ? 'team' : null);
          final feed = StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, snapshot) => _section(w.recentActivity, [
              for (final (i, event) in c.data.activity.indexed)
                ExpressiveListTile(
                  leading: _leading(
                    'feed-lead-$i',
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: theme.colors.surfaceContainerHighest,
                        shape: BoxShape.circle,
                      ),
                      child: ExpressiveIcon(
                        switch (event.kind) {
                          ActivityKind.finished =>
                            ExpressiveSymbols.checkCircle,
                          ActivityKind.started => ExpressiveSymbols.playArrow,
                          ActivityKind.commented => ExpressiveSymbols.chat,
                          ActivityKind.logged => ExpressiveSymbols.history,
                        },
                        size: 18,
                        color: theme.colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  overline: Text(w.timeAgo(event.at, snapshot.data!)),
                  title: Text(w.eventAction(event, c.personName(event.person))),
                  subtitle: Text(w.text(event.subject)),
                ),
              if (c.data.activity.isEmpty)
                ExpressiveListTile(title: Text(w.noActivity)),
            ]),
          );
          final hero = _focusPanel();
          final week = _weekPanel();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 20,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}',
                    style: theme.type.labelLarge.copyWith(
                      color: theme.colors.onSurfaceVariant,
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: ExpressiveText(
                      w.greeting,
                      role: ExpressiveTextRole.headline,
                      size: box.maxWidth / scale < 250
                          ? ExpressiveTextSize.small
                          : ExpressiveTextSize.large,
                    ),
                  ),
                ],
              ),
              if (wide) ...[
                _Columns(
                  first: hero,
                  second: week,
                  breakpoint: 0,
                  matchHeight: true,
                ),
                // Levelled only while the plan has rows: an empty plan's
                // two lines would stretch into a slab beside the team.
                _Columns(
                  first: sections.first,
                  second: people,
                  breakpoint: 0,
                  matchHeight: plan.isNotEmpty,
                ),
                _Columns(
                  first: _stack(sections.sublist(1)),
                  second: feed,
                  breakpoint: 0,
                ),
              ] else ...[
                hero,
                week,
                sections.first,
                sections[1],
                people,
                feed,
                sections.last,
              ],
            ],
          );
        },
      ),
    ),
  );

  // A section's count or span sits on its title's baseline, one em after
  // it, and wraps below as a whole when the line is full.
  Widget _sectionTitle(String title, String? detail) => Semantics(
    header: true,
    child: Text.rich(
      TextSpan(
        children: [
          TextSpan(text: title),
          if (detail != null)
            TextSpan(
              text: '\u2003${detail.replaceAll(' ', '\u00a0')}',
              style: theme.type.labelMedium.copyWith(
                color: theme.colors.onSurfaceVariant,
              ),
            ),
        ],
      ),
      style: theme.type.titleLarge.copyWith(color: theme.colors.onSurface),
    ),
  );

  Widget _stack(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 20,
    children: children,
  );

  Widget _section(
    String title,
    List<Widget> rows, {
    String? detail,
    Key? sectionKey,
    String? pairedFace,
  }) => Column(
    key: sectionKey,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: 8,
    children: [
      _sectionTitle(title, detail),
      if (pairedFace == null)
        ExpressiveListSection(children: rows)
      else
        Flexible(
          child: LayoutBuilder(
            builder: (_, room) => ExpressiveListSection(
              key: ValueKey('today-$pairedFace-face'),
              children: [
                ...rows.take(rows.length - 1),
                // The table first measures the list, then gives the final
                // segment enough height to meet the adjacent list's edge.
                Flexible(
                  fit: room.hasBoundedHeight ? FlexFit.tight : FlexFit.loose,
                  child: rows.last,
                ),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _timeBlocks(List<TimeEntry> entries) {
    final colors = theme.colors;
    final rangesOverlap = entries.indexed.any(
      (item) => item.$1 > 0 && item.$2.start < entries[item.$1 - 1].end,
    );
    final first = entries.firstOrNull?.start ?? 0;
    final last = entries.fold(
      first,
      (end, entry) => end > entry.end ? end : entry.end,
    );
    Widget timeBand(int index, TimeEntry entry) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        height: 5,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (entry.start > first) Spacer(flex: entry.start - first),
            Expanded(
              flex: entry.end - entry.start,
              child: ColoredBox(
                key: ValueKey('today-block-band-$index'),
                color: colors.secondary,
              ),
            ),
            if (entry.end < last) Spacer(flex: last - entry.end),
          ],
        ),
      ),
    );
    Widget line({required double top, double? bottom, double? height}) =>
        PositionedDirectional(
          start: 31.5,
          top: top,
          bottom: bottom,
          height: height,
          width: 1,
          child: ColoredBox(color: colors.outlineVariant),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: [
        _sectionTitle(
          w.timeBlocks,
          rangesOverlap ? '${w.clock(first)}–${w.clock(last)}' : null,
        ),
        ExpressiveCard.filled(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // On the card's fill, as the row under it: a tile's own
              // surface left the empty line bare beside it.
              if (entries.isEmpty)
                ExpressiveListTile(
                  tileColor: colors.surfaceContainerHighest,
                  title: Text(w.noBlocks),
                ),
              for (final (i, entry) in entries.indexed)
                Stack(
                  children: [
                    if (i > 0 && entries[i - 1].end == entry.start)
                      line(top: 0, height: 24),
                    if (i + 1 < entries.length &&
                        entry.end == entries[i + 1].start)
                      KeyedSubtree(
                        key: ValueKey('today-link-blocks-lead-$i'),
                        child: line(top: 24, bottom: 0),
                      ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 12,
                        children: [
                          _leading(
                            'blocks-lead-$i',
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.secondaryContainer,
                              ),
                              child: ExpressiveIcon(
                                ExpressiveSymbols.schedule,
                                size: 16,
                                color: colors.onSecondaryContainer,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  w.timeRange(entry),
                                  style: theme.type.labelMedium.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  w.text(entry.note),
                                  style: theme.type.bodyLarge.copyWith(
                                    color: colors.onSurface,
                                  ),
                                ),
                                Text(
                                  c.projectName(entry.project),
                                  style: theme.type.bodyMedium.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                                if (rangesOverlap) timeBand(i, entry),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ExpressiveListTile(
                tileColor: colors.surfaceContainerHighest,
                leading: _leading(
                  'blocks-lead-all',
                  ExpressiveIcon(
                    ExpressiveSymbols.arrowForward,
                    color: theme.colors.primary,
                  ),
                ),
                title: Text(
                  w.seeTime,
                  style: theme.type.labelLarge.copyWith(
                    color: theme.colors.primary,
                  ),
                ),
                onTap: () => go(Place.time),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _leading(String id, Widget mark) => SizedBox(
    width: 32,
    child: Center(
      child: KeyedSubtree(key: ValueKey('today-$id'), child: mark),
    ),
  );

  Widget _focusPanel() {
    final colors = theme.colors, type = theme.type;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = task != null && timer != null;
    final event = c.data.activity.firstOrNull;
    final logged =
        timer == null &&
            event != null &&
            event.person == 'maya' &&
            event.kind == ActivityKind.logged
        ? event
        : null;
    final subject = task?.title ?? logged?.subject;
    final receipt = logged == null
        ? null
        : w.eventAction(logged, c.personName('maya'));
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    final pick = choices.isEmpty ? null : () => palette(timerTasks: choices);
    // The running timer's well: by day the primary container, Expressive's
    // tint for the moment in hand; at night the card's own container washed
    // with the primary as Material's surface tint washes a raised surface
    // (its highest, 14%): the palette's hue, kept deep. The primary
    // container cannot serve at night: the 2025 vibrant and expressive
    // schemes light it for small parts (a FAB), a glare as a card (ember,
    // bloom); the secondary container, another role, turned ember's orange
    // blue. Its words in the surface's ink, its time in the primary.
    final night = theme.brightness == Brightness.dark;
    final fill = !active
        ? colors.surfaceContainerHigh
        : night
        ? Color.alphaBlend(
            colors.primary.withValues(alpha: .14),
            colors.surfaceContainerHigh,
          )
        : colors.primaryContainer;
    final ink = !active
        ? colors.onSurfaceVariant
        : night
        ? colors.onSurface
        : colors.onPrimaryContainer;
    final time = active && night ? colors.primary : ink;
    Widget clock(DateTime now) {
      final reading = w.elapsed(
        timer == null
            ? Duration(minutes: logged?.minutes ?? 0)
            : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        excludeSemantics: true,
        label: receipt ?? w.elapsedLabel(reading),
        child: Text(
          reading,
          key: const ValueKey('today-timer-digits'),
          textDirection: TextDirection.ltr,
          maxLines: 1,
          style: type.displaySmallEmphasized.copyWith(
            color: time,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      );
    }

    final well = ExpressiveSpringColor(
      value: fill,
      motion: ExpressiveMotionKey.fastEffects,
      builder: (_, fill, child) => DecoratedBox(
        key: const ValueKey('today-timer-well'),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Transform.translate(
                      // Centre the mark on the visible status lettering.
                      offset: Offset(
                        0,
                        MediaQuery.textScalerOf(context)
                            .scale(w.arabic ? .5 : 1.5),
                      ),
                      child: _Mark(
                        key: const ValueKey('today-timer-lamp'),
                        size: 30,
                        color: active ? colors.primary : colors.surfaceVariant,
                        child: ExpressiveIcon(
                          ExpressiveSymbols.timer,
                          size: 18,
                          color: active
                              ? colors.onPrimary
                              : colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        active ? w.runningTimer : w.stoppedTimer,
                        key: const ValueKey('today-timer-label'),
                        style: type.labelLarge.copyWith(color: ink),
                      ),
                    ),
                  ],
                ),
                _TrackedSubject(
                  taskId: task?.id,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 4,
                    children: [
                      Text(
                        subject == null ? w.chooseTask : w.text(subject),
                        key: const ValueKey('today-timer-title'),
                        style: type.titleLargeEmphasized.copyWith(color: ink),
                      ),
                      if (active)
                        Text(
                          c.projectName(task.project),
                          style: type.bodyMedium.copyWith(color: ink),
                        )
                      else if (receipt != null)
                        Text(
                          receipt,
                          style: type.bodyMedium.copyWith(color: ink),
                        ),
                      if (!active && choices.isEmpty)
                        Text(
                          w.noTimerTasks,
                          style: type.bodyMedium.copyWith(color: ink),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: timer == null
                      ? clock(c.repository.now())
                      : StreamBuilder<DateTime>(
                          stream: c.ticks(const Duration(seconds: 1)),
                          initialData: c.repository.now(),
                          builder: (_, snapshot) => clock(snapshot.data!),
                        ),
                ),
                if (timer != null)
                  Text(
                    w.since(timer.start),
                    style: type.labelMedium.copyWith(color: ink),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
    return ExpressiveHeroMoment(
      key: const ValueKey('today-timer-card'),
      label: active ? w.runningTimer : w.stoppedTimer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 6,
        children: [
          well,
          Builder(
            builder: (_) {
              final start = ExpressiveFilledButton(
                w.startTimer,
                expand: true,
                icon: ExpressiveSymbols.playArrow,
                onPressed: pick,
              );
              if (!active) return start;
              final stop = ExpressiveFilledButton(
                w.stopTimer,
                key: const ValueKey('today-action-first'),
                expand: true,
                icon: ExpressiveSymbols.stop,
                onPressed: c.stopTimer,
              );
              final change = ExpressiveFilledButton.tonal(
                w.switchTask,
                key: const ValueKey('today-action-last'),
                expand: true,
                icon: ExpressiveSymbols.sync,
                onPressed: pick,
              );
              // Side by side while each key's words fit its half on one line.
              return StintPair(first: stop, second: change, runSpacing: 4);
            },
          ),
        ],
      ),
    );
  }

  Widget _weekPanel() {
    final week = mondayOf(studyToday), colors = theme.colors;
    final daily = c.dailyMinutes(week);
    final peak = daily.fold(1, math.max);
    final type = theme.type;
    Widget stat(String id, String label, String value, TextStyle figure) =>
        DecoratedBox(
          key: ValueKey('today-stat-$id'),
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: type.labelMedium.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(value, style: figure.copyWith(color: colors.onSurface)),
              ],
            ),
          ),
        );
    // The keys beside it stand at the 40dp touch floor with no target below
    // their faces, so the chart ends on their line.
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        LayoutBuilder(
          builder: (ctx, box) {
            final total = w.duration(c.totalMinutes(week));
            final type = theme.type;
            final figure =
                TextPainter.computeWidth(
                      text: TextSpan(
                        text: total,
                        style: type.titleLargeEmphasized,
                      ),
                      textDirection: Directionality.of(ctx),
                      textScaler: MediaQuery.textScalerOf(ctx),
                    ) <=
                    (box.maxWidth - 8) / 2 - 24
                ? type.titleLargeEmphasized
                : type.titleMediumEmphasized;
            return Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.intrinsicHeight,
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FixedColumnWidth(8),
                2: FlexColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    stat(
                      'tasks',
                      w.openTasks,
                      w.number(c.openTasks.length),
                      figure,
                    ),
                    const SizedBox(),
                    stat('hours', w.hoursThisWeek, total, figure),
                  ],
                ),
              ],
            );
          },
        ),
        Flexible(
          fit: FlexFit.loose,
          child: LayoutBuilder(
            builder: (ctx, box) {
              final scaler = MediaQuery.textScalerOf(ctx);
              final scale = scaler.scale(1);
              final slot = (box.maxWidth - 12) / 7;
              final readingStyle = ctx.expressiveTheme.type.labelSmall.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              );
              // One form for the week: each day in full where every one
              // fits its day on one line, else all as h:mm,
              // under a caption naming the hours.
              final readings = WeekReadings.fit(
                ctx,
                words: w,
                minutes: daily,
                style: readingStyle,
                slot: slot - 2,
              );
              final captionLine =
                  scaler.scale(readingStyle.fontSize!) *
                      (readingStyle.height ?? 1.4) +
                  4;
              final height = box.hasBoundedHeight
                  ? box.maxHeight
                  : 76.0 + 34 * scale + (readings.compact ? captionLine : 0);
              final compact = slot < 19 * scale;
              return Semantics(
                image: true,
                excludeSemantics: true,
                label: [
                  w.logged,
                  for (final (i, n) in daily.indexed)
                    '${w.weekdayNames[i]} ${w.duration(n)}',
                ].join(', '),
                child: Container(
                  key: const ValueKey('today-chart'),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 8,
                  ),
                  height: height,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      if (readings.compact)
                        Text(
                          w.logged,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: readingStyle.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final (i, n) in daily.indexed)
                              Expanded(
                                child: ExpressiveTooltip.plain(
                                  message:
                                      '${w.weekdayNames[i]}${w.dot}${w.duration(n)}',
                                  child: _MaterialDay(
                                    day: i,
                                    fraction: n / peak,
                                    reading: readings.labels[i],
                                    tight: readings.compact,
                                    label: compact
                                        ? w.weekdayNarrow(addDays(week, i))
                                        : w.weekdayShort(addDays(week, i)),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MaterialDay extends StatelessWidget {
  const _MaterialDay({
    required this.day,
    required this.fraction,
    required this.label,
    required this.reading,
    required this.tight,
  });
  final int day;
  final double fraction;
  final String label, reading;

  /// Days too narrow for full readings: their names set lighter and closer.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final t = context.expressiveTheme;
    final colors = t.colors;
    final readingStyle = t.type.labelSmall.copyWith(
      color: colors.onSurfaceVariant,
      fontFeatures: [const FontFeature.tabularFigures()],
    );
    final scale = MediaQuery.textScalerOf(context);
    final lineHeight =
        scale.scale(readingStyle.fontSize!) * (readingStyle.height ?? 1.4);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, area) {
              // All seven bars use one scale.
              final space = math.max(2.0, area.maxHeight - lineHeight - 3);
              return ExpressiveSpringValue(
                value: fraction,
                motion: ExpressiveMotionKey.defaultSpatial,
                builder: (_, value, _) => Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      reading,
                      textAlign: TextAlign.center,
                      style: readingStyle,
                      softWrap: false,
                      maxLines: 1,
                    ),
                    const SizedBox(height: 3),
                    Container(
                      key: ValueKey('today-day-slot-$day'),
                      width: (area.maxWidth * .46).clamp(2.0, 32.0),
                      height: (space * value).clamp(2.0, space),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: fraction == 0
                            ? colors.outline
                            : day == studyToday.weekday - 1
                            ? colors.primary
                            : Color.lerp(
                                colors.surfaceContainer,
                                colors.primary,
                                .74,
                              )!,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          key: ValueKey('today-day-label-$day'),
          softWrap: false,
          maxLines: 1,
          style: (tight ? t.type.labelSmall : t.type.labelSmallEmphasized)
              .copyWith(
                letterSpacing: tight ? 0 : null,
                color: colors.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _TrackedSubject extends StatefulWidget {
  const _TrackedSubject({required this.taskId, required this.child});
  final String? taskId;
  final Widget child;
  @override
  State<_TrackedSubject> createState() => _TrackedSubjectState();
}

class _TrackedSubjectState extends State<_TrackedSubject>
    with SingleTickerProviderStateMixin {
  late final ink = AnimationController(vsync: this, value: 1);
  @override
  void didUpdateWidget(_TrackedSubject old) {
    super.didUpdateWidget(old);
    final motion = ExpressiveMotion.of(context);
    if (old.taskId != widget.taskId && !motion.reduceMotion) {
      ink.value = .35;
      ink.springTo(1, motion.fastEffects);
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
