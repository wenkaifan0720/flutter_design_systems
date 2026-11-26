part of '../stint_fluent2_design.dart';

extension _Today on _WorkspaceState {
  Widget today() => Fluent2Scaffold(
    topBar: Fluent2AppBar(title: w.today, actions: [commands]),
    body: data(
      () => LayoutBuilder(
        builder: (ctx, box) {
          final wide = box.maxWidth >= MediaQuery.textScalerOf(ctx).scale(580);
          final plan = c.todayTasks,
              blocks = c.todayBlocks,
              later = c.laterThisWeek;
          final agenda = Fluent2ListSection(
            key: const ValueKey('today-plan'),
            title: w.todaysPlan,
            aside: plan.isEmpty
                ? null
                : w.progress(
                    plan.where((task) => task.done).length,
                    plan.length,
                  ),
            rows: [
              for (final task in plan)
                _WorkRow(
                  key: ValueKey('plan-${task.id}'),
                  id: 'plan-lead-${task.id}',
                  title: w.text(task.title),
                  detail: c.projectName(task.project),
                  checked: task.done,
                  lead: _PlanTick(done: task.done),
                  runningLabel: task.id == c.data.timer?.taskId
                      ? w.runningTimer
                      : null,
                  onTap: () => c.changeTasks([task.id], done: !task.done),
                ),
              if (plan.isEmpty) Fluent2ListItem(title: w.noTasksToday),
              _WorkRow(
                id: 'plan-lead-all',
                title: w.viewTasks,
                lead: Icon(
                  Fluent2Icons.arrowRight,
                  size: 20,
                  color: theme.accentText,
                ),
                onTap: () => go(Place.tasks),
              ),
            ],
          );
          final rangesOverlap = blocks.indexed.any(
            (item) => item.$1 > 0 && item.$2.start < blocks[item.$1 - 1].end,
          );
          final first = blocks.firstOrNull?.start ?? 0;
          final last = blocks.fold(
            first,
            (end, entry) => end > entry.end ? end : entry.end,
          );
          final sessions = Fluent2ListSection(
            title: w.timeBlocks,
            aside: rangesOverlap ? '${w.clock(first)}–${w.clock(last)}' : null,
            rows: [
              for (final (i, entry) in blocks.indexed)
                _WorkRow(
                  id: 'blocks-lead-$i',
                  title: w.text(entry.note),
                  detail: c.projectName(entry.project),
                  stamp: w.timeRange(entry),
                  joinsAbove: i > 0 && blocks[i - 1].end == entry.start,
                  joinsBelow:
                      i + 1 < blocks.length && entry.end == blocks[i + 1].start,
                  timeRange: rangesOverlap
                      ? ColoredBox(
                          color: theme.colors.neutralBackground3,
                          child: Row(
                            key: ValueKey('today-block-span-$i'),
                            children: [
                              if (entry.start > first)
                                Spacer(flex: entry.start - first),
                              Expanded(
                                flex: entry.end - entry.start,
                                child: ColoredBox(
                                  key: ValueKey('today-block-band-$i'),
                                  color: theme.accentText,
                                  child: const SizedBox(height: 4),
                                ),
                              ),
                              if (entry.end < last)
                                Spacer(flex: last - entry.end),
                            ],
                          ),
                        )
                      : null,
                  lead: Fluent2IconTile(
                    Fluent2Icons.clock,
                    hue: _hue(entry.project),
                    size: 28,
                  ),
                ),
              if (blocks.isEmpty) Fluent2ListItem(title: w.noBlocks),
              _WorkRow(
                id: 'blocks-lead-all',
                title: w.seeTime,
                lead: Icon(
                  Fluent2Icons.arrowRight,
                  size: 20,
                  color: theme.accentText,
                ),
                onTap: () => go(Place.time),
              ),
            ],
          );
          final upcoming = Fluent2ListSection(
            title: w.laterThisWeek,
            rows: [
              for (final (i, task) in later.indexed)
                _WorkRow(
                  id: 'later-lead-${task.id}',
                  title: w.text(task.title),
                  detail: c.projectName(task.project),
                  stamp:
                      i == 0 ||
                          calendarDay(later[i - 1].due) != calendarDay(task.due)
                      ? w.weekday(task.due)
                      : null,
                  spokenDetail:
                      '${c.projectName(task.project)}, ${w.weekday(task.due)}',
                  lead: Fluent2IconTile(
                    Fluent2Icons.documentText,
                    hue: _hue(task.project),
                    size: 28,
                  ),
                  onTap: () => open(task),
                ),
              if (later.isEmpty) Fluent2ListItem(title: w.allClear),
            ],
          );
          final people = Fluent2ListSection(
            title: w.teamActivity,
            rows: [
              for (final person in team)
                _WorkRow(
                  id: 'team-lead-${person.id}',
                  title: w.text(person.name),
                  detail: switch (c.currentTask(person.id)) {
                    final task? => w.text(task.title),
                    null => w.notTracking,
                  },
                  lead: _personAvatar(person),
                ),
            ],
          );
          final feed = StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, snapshot) => Fluent2ListSection(
              title: w.recentActivity,
              rows: [
                for (final (i, event) in c.data.activity.indexed)
                  _WorkRow(
                    id: 'feed-lead-$i',
                    title: w.eventAction(event, c.personName(event.person)),
                    detail: w.text(event.subject),
                    stamp: w.timeAgo(event.at, snapshot.data!),
                    lead: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: theme.surfaceAlt,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        switch (event.kind) {
                          ActivityKind.finished => Fluent2Icons.checkmarkCircle,
                          ActivityKind.started => Fluent2Icons.play,
                          ActivityKind.commented => Fluent2Icons.comment,
                          ActivityKind.logged => Fluent2Icons.history,
                        },
                        size: 18,
                        color: theme.textSecondary,
                      ),
                    ),
                  ),
                if (c.data.activity.isEmpty)
                  Fluent2ListItem(title: w.noActivity),
              ],
            ),
          );
          Widget stack(List<Widget> sections) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 18,
            children: sections,
          );
          final timer = _session(), week = _weeklyLedger();
          final effectiveWidth =
              box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1);
          final sections = stack([
            if (wide) ...[
              // The plan and the team stand at one height while both have
              // rows to show. A day with nothing due keeps its plate to its
              // two rows, not a tall empty plate beside the team.
              Table(
                defaultVerticalAlignment: plan.isEmpty
                    ? TableCellVerticalAlignment.top
                    : TableCellVerticalAlignment.intrinsicHeight,
                columnWidths: const {1: FixedColumnWidth(20)},
                children: [
                  TableRow(
                    children: [
                      _pairedList(agenda, 'plan'),
                      const SizedBox(),
                      _pairedList(people, 'team'),
                    ],
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 20,
                children: [
                  Expanded(child: stack([sessions, upcoming])),
                  Expanded(child: feed),
                ],
              ),
            ] else ...[
              agenda,
              sessions,
              people,
              feed,
              upcoming,
            ],
          ]);
          return stack([
            Row(
              spacing: 12,
              children: [
                if (effectiveWidth >= 250)
                  ExcludeSemantics(
                    child: _personAvatar(
                      team.firstWhere((p) => p.id == 'maya'),
                      size: 44,
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 2,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          w.greeting,
                          style: effectiveWidth < 250
                              ? theme.title3
                              : effectiveWidth < 440
                              ? theme.title2
                              : theme.title1,
                        ),
                      ),
                      Text(
                        '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}',
                        style: theme.body1.c(theme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Fluent2Card(
              key: const ValueKey('today-timer-card'),
              size: Fluent2CardSize.large,
              children: [
                if (wide)
                  Table(
                    defaultVerticalAlignment:
                        TableCellVerticalAlignment.intrinsicHeight,
                    columnWidths: const {
                      0: FlexColumnWidth(),
                      1: FixedColumnWidth(24),
                      2: FlexColumnWidth(),
                    },
                    children: [
                      TableRow(children: [timer, const SizedBox(), week]),
                    ],
                  )
                else
                  stack([timer, week]),
              ],
            ),
            if (w.arabic)
              Fluent2Theme(
                data: theme.copyWith(typeface: const _SectionTypeface()),
                child: sections,
              )
            else
              sections,
          ]);
        },
      ),
    ),
  );

  Widget _pairedList(Fluent2ListSection section, String id) => Column(
    key: section.key,
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Fluent2SectionHeader(section.title, aside: section.aside),
      Flexible(
        child: LayoutBuilder(
          builder: (_, room) => Fluent2ListGroup(
            key: ValueKey('today-$id-face'),
            children: [
              // The plate takes the height of the taller section when the
              // table supplies it; the last row keeps its own height at the
              // top of what is left, never floating in its middle.
              SizedBox(
                height: room.hasBoundedHeight ? room.maxHeight : null,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final row in section.rows.take(
                      section.rows.length - 1,
                    )) ...[row, const Fluent2Divider()],
                    Flexible(
                      fit: room.hasBoundedHeight
                          ? FlexFit.tight
                          : FlexFit.loose,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [section.rows.last],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );

  Widget _session() {
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
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
    final choices = c.openTasks
        .where((task) => task.id != timer?.taskId)
        .toList();
    final pick = choices.isEmpty ? null : () => palette(timerTasks: choices);
    Widget display(DateTime now) {
      final elapsed = w.elapsed(
        timer == null
            ? Duration(minutes: logged?.minutes ?? 0)
            : now.difference(timer.start),
      );
      return Semantics(
        identifier: 'stint-elapsed',
        label: receipt ?? w.elapsedLabel(elapsed),
        excludeSemantics: true,
        child: Text(
          elapsed,
          key: const ValueKey('today-timer-digits'),
          textDirection: TextDirection.ltr,
          style: _readingStyle(
            context,
            theme.title1,
          ).tabular.copyWith(fontSize: 34, height: 1.15).c(theme.textPrimary),
        ),
      );
    }

    final well = AnimatedContainer(
      key: const ValueKey('today-timer-well'),
      duration: Fluent2Motion.of(context, Fluent2Motion.normal),
      curve: Fluent2Motion.easyEase,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: active ? theme.accentSubtle : theme.surfaceAlt,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Row(
                spacing: 7,
                children: [
                  Transform.translate(
                    // Centre the dot on the visible status lettering.
                    offset: Offset(
                      0,
                      MediaQuery.textScalerOf(context).scale(1) *
                          (w.arabic ? -1 : 1.5),
                    ),
                    child: AnimatedContainer(
                      key: const ValueKey('today-timer-lamp'),
                      duration: Fluent2Motion.of(context, Fluent2Motion.fast),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active ? theme.accentText : theme.textTertiary,
                      ),
                    ),
                  ),
                  Flexible(
                    child: Text(
                      active ? w.runningTimer : w.stoppedTimer,
                      key: const ValueKey('today-timer-label'),
                      style: _readingStyle(
                        context,
                        theme.body1Strong,
                      ).c(active ? theme.accentText : theme.textSecondary),
                    ),
                  ),
                ],
              ),
              FittedBox(
                alignment: AlignmentDirectional.centerStart,
                fit: BoxFit.scaleDown,
                child: timer == null
                    ? display(c.repository.now())
                    : StreamBuilder<DateTime>(
                        stream: c.ticks(const Duration(seconds: 1)),
                        initialData: c.repository.now(),
                        builder: (_, snapshot) => display(snapshot.data!),
                      ),
              ),
              if (timer != null)
                Text(
                  w.since(timer.start),
                  style: theme.caption1.c(theme.textSecondary),
                ),
            ],
          ),
          AnimatedSwitcher(
            duration: Fluent2Motion.of(context, Fluent2Motion.normal),
            switchInCurve: Fluent2Motion.decelerateMid,
            layoutBuilder: (now, old) => Stack(
              alignment: AlignmentDirectional.centerStart,
              children: [...old, ?now],
            ),
            child: Column(
              key: ValueKey(task?.id),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  subject == null ? w.chooseTask : w.text(subject),
                  key: const ValueKey('today-timer-title'),
                  style: theme.subtitle1,
                ),
                if (active)
                  Text(
                    c.projectName(task.project),
                    style: theme.body1.c(theme.textSecondary),
                  )
                else if (receipt != null)
                  Text(receipt, style: theme.body1.c(theme.textSecondary)),
                if (!active && choices.isEmpty)
                  Text(
                    w.noTimerTasks,
                    style: theme.body1.c(theme.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 8,
      children: [
        well,
        LayoutBuilder(
          builder: (ctx, box) {
            final narrow =
                box.maxWidth < MediaQuery.textScalerOf(ctx).scale(192);
            if (!active) {
              final start = Fluent2Button(
                w.startTimer,
                icon: Fluent2Icons.play,
                expand: true,
                appearance: Fluent2ButtonAppearance.primary,
                onPressed: pick,
              );
              // Stopped, the one key stands in Stop's cell, as wide as Stop
              // and where it was (a filling key stops at 320 from 600).
              if (narrow) return start;
              return Row(
                spacing: 8,
                children: [
                  Expanded(child: start),
                  const Expanded(child: SizedBox()),
                ],
              );
            }
            final stop = Fluent2Button(
              w.stopTimer,
              key: const ValueKey('today-action-first'),
              expand: true,
              appearance: Fluent2ButtonAppearance.primary,
              onPressed: c.stopTimer,
            );
            final change = Fluent2Button(
              w.switchTask,
              key: const ValueKey('today-action-last'),
              expand: true,
              onPressed: pick,
            );
            if (narrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 6,
                children: [stop, change],
              );
            }
            return Row(
              spacing: 8,
              children: [
                Expanded(child: stop),
                Expanded(child: change),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _weeklyLedger() {
    final week = mondayOf(studyToday), values = c.dailyMinutes(week);
    const interval = 6 * 60;
    final longest = values.fold(interval, (a, b) => a > b ? a : b);
    final ceiling = ((longest + interval - 1) ~/ interval) * interval;
    Widget metric(String id, String label, String reading, TextStyle figure) =>
        Container(
          key: ValueKey('today-stat-$id'),
          decoration: BoxDecoration(
            color: theme.surfaceAlt,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            spacing: 2,
            children: [
              Text(label, style: theme.caption1Strong.c(theme.textSecondary)),
              Text(reading, style: figure.tabular),
            ],
          ),
        );
    return ColoredBox(
      key: const ValueKey('today-hero-week'),
      color: theme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          LayoutBuilder(
            builder: (ctx, box) {
              final total = w.duration(c.totalMinutes(week));
              final regular = _readingStyle(ctx, theme.title2);
              final figure =
                  TextPainter.computeWidth(
                        text: TextSpan(text: total, style: regular.tabular),
                        textDirection: Directionality.of(ctx),
                        textScaler: MediaQuery.textScalerOf(ctx),
                      ) <=
                      (box.maxWidth - 8) / 2 - 24
                  ? regular
                  : _readingStyle(ctx, theme.subtitle2);
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
                      metric(
                        'tasks',
                        w.openTasks,
                        w.number(c.openTasks.length),
                        figure,
                      ),
                      const SizedBox(),
                      metric('hours', w.hoursThisWeek, total, figure),
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
                final slotWidth = (box.maxWidth - 8) / 7;
                final readingStyle = _readingStyle(ctx, theme.caption1).tabular;
                // One form for the week: each day in full where every one
                // fits its slot on one line, else all as h:mm,
                // under a caption naming the hours.
                final readings = WeekReadings.fit(
                  ctx,
                  words: w,
                  minutes: values,
                  style: readingStyle,
                  slot: slotWidth - 2,
                );
                final captionLine =
                    scaler.scale(readingStyle.fontSize!) *
                        (readingStyle.height ?? 1.4) +
                    4;
                final height = box.hasBoundedHeight
                    ? box.maxHeight
                    : 72.0 + 32 * scale + (readings.compact ? captionLine : 0);
                final compact = slotWidth < 19 * scale;
                return Semantics(
                  image: true,
                  excludeSemantics: true,
                  label: [
                    w.logged,
                    for (final (i, n) in values.indexed)
                      '${w.weekdayNames[i]} ${w.duration(n)}',
                  ].join(', '),
                  child: Container(
                    key: const ValueKey('today-chart'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colors.neutralBackground2,
                      borderRadius: BorderRadius.circular(4),
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
                            style: readingStyle.c(theme.textSecondary),
                          ),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final (i, n) in values.indexed)
                                Expanded(
                                  child: _FluentDay(
                                    index: i,
                                    fraction: n / ceiling,
                                    amount: readings.labels[i],
                                    tight: readings.compact,
                                    caption: compact
                                        ? w.weekdayNarrow(addDays(week, i))
                                        : w.weekdayShort(addDays(week, i)),
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
      ),
    );
  }
}

// Keep Selawik for its own glyphs and use Stint's bundled Arabic face for
// section titles and rows on platforms without a system Arabic fallback.
class _SectionTypeface extends Fluent2Typeface {
  const _SectionTypeface() : super.app(family: Fluent2ThemeData.face);

  @override
  TextStyle style(double size, double line, int weight, Color color) => super
      .style(size, line, weight, color)
      .copyWith(
        fontFamilyFallback: const ['packages/stint_fluent2_design/StintArabic'],
      );
}

class _WorkRow extends StatelessWidget {
  const _WorkRow({
    super.key,
    required this.id,
    required this.lead,
    required this.title,
    this.detail,
    this.stamp,
    this.timeRange,
    this.runningLabel,
    this.spokenDetail,
    this.checked,
    this.onTap,
    this.joinsAbove = false,
    this.joinsBelow = false,
  });
  final String id, title;
  final String? detail, stamp, runningLabel, spokenDetail;
  final Widget lead;
  final Widget? timeRange;
  final bool? checked;
  final VoidCallback? onTap;
  final bool joinsAbove, joinsBelow;

  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final ink = checked == true ? t.textSecondary : t.textPrimary;
    // A paired list gives its last row the height left in the card. The icon
    // and text stay one centred group there, like the rows above them.
    final face = Stack(
      alignment: AlignmentDirectional.centerStart,
      children: [
        if (joinsAbove || joinsBelow)
          PositionedDirectional(
            start: 31,
            top: 0,
            bottom: 0,
            width: 1,
            child: Column(
              children: [
                Expanded(
                  child: ColoredBox(
                    color: joinsAbove ? t.border : const Color(0x00000000),
                    child: const SizedBox.expand(),
                  ),
                ),
                Expanded(
                  child: ColoredBox(
                    key: joinsBelow ? ValueKey('today-link-$id') : null,
                    color: joinsBelow ? t.border : const Color(0x00000000),
                    child: const SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 32,
                child: Center(
                  child: ExcludeSemantics(
                    child: KeyedSubtree(
                      key: ValueKey('today-$id'),
                      child: lead,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 1,
                  children: [
                    if (stamp != null)
                      Text(
                        stamp!,
                        style: t.caption1.tabular.c(t.textSecondary),
                      ),
                    Text(
                      title,
                      style: t.body1Strong
                          .c(ink)
                          .copyWith(
                            decoration: checked == true
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                    ),
                    if (detail != null)
                      Text(detail!, style: t.caption1.c(t.textSecondary)),
                    if (timeRange != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: timeRange,
                      ),
                  ],
                ),
              ),
              // The task the timer runs on says so at the row's end, as
              // Fluent marks a status: a brand-tinted badge with the clock.
              if (runningLabel case final label?)
                ExcludeSemantics(
                  key: const ValueKey('today-plan-running'),
                  // On a phone with large text it gives way to the title,
                  // never more than a third of the row.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.sizeOf(context).width / 3,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Fluent2LabelBadge(
                        label: label,
                        icon: Fluent2Icons.clock,
                        appearance: Fluent2BadgeAppearance.tint,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
    if (onTap == null) return face;
    return Fluent2Pressable(
      onPressed: onTap,
      label: [title, ?(spokenDetail ?? detail), ?runningLabel].join(', '),
      checked: checked,
      padded: false,
      builder: (ctx, states) => AnimatedContainer(
        duration: Fluent2Motion.of(ctx, Fluent2Motion.fast),
        curve: Fluent2Motion.easyEase,
        constraints: BoxConstraints(
          minHeight: Fluent2ListItem.minHeightOf(ctx),
        ),
        alignment: AlignmentDirectional.centerStart,
        color: states.press.pick(
          t.colors.subtleBackground,
          t.colors.subtleBackgroundHover,
          t.colors.subtleBackgroundPressed,
        ),
        child: face,
      ),
    );
  }
}

class _PlanTick extends StatelessWidget {
  const _PlanTick({required this.done});
  final bool done;
  @override
  Widget build(BuildContext context) {
    final colors = context.fluent2Theme.colors;
    return AnimatedContainer(
      width: 18,
      height: 18,
      duration: Fluent2Motion.of(context, Fluent2Motion.fast),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        color: done
            ? colors.compoundBrandBackground
            : colors.transparentBackground,
        border: Border.all(
          color: done
              ? colors.compoundBrandBackground
              : colors.neutralStrokeAccessible,
        ),
      ),
      child: done
          ? Icon(
              Fluent2Icons.checkmark12Filled,
              size: 12,
              color: colors.neutralForegroundInverted,
            )
          : null,
    );
  }
}

TextStyle _readingStyle(BuildContext context, TextStyle style) =>
    Localizations.localeOf(context).languageCode == 'ar'
    ? style.copyWith(fontFamily: 'StintArabic', package: 'stint_fluent2_design')
    : style;

class _FluentDay extends StatelessWidget {
  const _FluentDay({
    required this.index,
    required this.fraction,
    required this.caption,
    required this.amount,
    required this.tight,
  });
  final int index;
  final double fraction;
  final String caption, amount;

  /// Whether the week's readings are too wide in full: the day's words step
  /// down a size with them.
  final bool tight;
  @override
  Widget build(BuildContext context) {
    final t = context.fluent2Theme;
    final captionStyle = _readingStyle(
      context,
      tight ? t.caption2 : t.caption1,
    );
    final ink = fraction == 0
        ? Color.lerp(t.surface, t.textSecondary, .58)!
        : index == studyToday.weekday - 1
        ? t.accentText
        : Color.lerp(t.surface, t.accentText, .78)!;
    final scale = MediaQuery.textScalerOf(context);
    final lineHeight =
        scale.scale(captionStyle.fontSize!) * (captionStyle.height ?? 1.4);
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (_, area) {
              final space = (area.maxHeight - lineHeight - 5).clamp(
                2.0,
                area.maxHeight,
              );
              return Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    amount,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    softWrap: false,
                    style: captionStyle.tabular.c(t.textSecondary),
                  ),
                  const SizedBox(height: 3),
                  AnimatedContainer(
                    key: ValueKey('today-day-slot-$index'),
                    duration: Fluent2Motion.of(context, Fluent2Motion.normal),
                    curve: Fluent2Motion.decelerateMid,
                    width: (area.maxWidth * .5).clamp(2.0, 26.0),
                    height: (space * fraction).clamp(2.0, space),
                    decoration: BoxDecoration(
                      color: ink,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(3),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 5),
        Text(
          caption,
          key: ValueKey('today-day-label-$index'),
          softWrap: false,
          maxLines: 1,
          style: captionStyle.c(t.textSecondary),
        ),
      ],
    );
  }
}
