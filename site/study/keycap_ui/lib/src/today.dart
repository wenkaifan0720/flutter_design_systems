part of '../stint_keycap.dart';

extension _Today on _WorkspaceState {
  /// The separator inside a meta line: a middle dot, or in Arabic the Arabic
  /// comma, because a middle dot beside Arabic-Indic figures reads as a zero.
  String get _sep => w.arabic ? '، ' : ' · ';

  /// The separator inside a list or timer meta line. At 200% text such a
  /// line wraps anyway, so its two parts take a line each rather than one
  /// breaking at the separator.
  String get _metaSep =>
      MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? '\n' : _sep;

  Widget today() => KeycapScreen(
    topBar: KeycapAppBar(title: w.today, actions: [command]),
    maxWidth: _measure,
    body: dataBody(
      () => LayoutBuilder(
        builder: (ctx, box) {
          final scale = MediaQuery.textScalerOf(ctx).scale(1);
          final wide = box.maxWidth >= 590 * scale;
          // Each activity time keeps its own line wherever a subtitle and
          // its time would not share one: at large text, and in the narrow
          // tablet column, so no row wraps on its own and strands its time.
          final feedWidth = wide
              ? (box.maxWidth - KeycapSpacing.large) / 2
              : box.maxWidth;
          final timeSeparator = scale >= 1.5 || feedWidth / scale < 330
              ? '\n'
              : _sep;
          final tasks = c.todayTasks;
          final plan = _Section(
            key: const ValueKey('today-plan'),
            header: w.todaysPlan,
            rows: [
              if (tasks.isEmpty) KeycapListTile(title: w.noTasksToday),
              for (final task in tasks) _planRow(task),
              KeycapListTile(
                leading: const _Lead(
                  key: ValueKey('today-plan-lead-all'),
                  child: Icon(LucideIcons.listChecks),
                ),
                title: w.viewTasks,
                subtitle: tasks.isEmpty
                    ? null
                    : w.progress(
                        tasks.where((t) => t.done).length,
                        tasks.length,
                      ),
                onTap: () => go(Place.tasks),
              ),
            ],
          );
          final entries = c.todayBlocks;
          final blocks = _Section(
            key: const ValueKey('today-blocks'),
            header: w.timeBlocks,
            rows: [
              if (entries.isEmpty) KeycapListTile(title: w.noBlocks),
              for (final (i, entry) in entries.indexed) _block(entry, i),
              KeycapListTile(
                leading: const _Lead(child: Icon(LucideIcons.clock3)),
                title: w.seeTime,
                onTap: () => go(Place.time),
              ),
            ],
          );
          final upcoming = c.laterThisWeek;
          final later = _Section(
            key: const ValueKey('today-later'),
            header: w.laterThisWeek,
            rows: [
              if (upcoming.isEmpty) KeycapListTile(title: w.allClear),
              for (final t in upcoming)
                KeycapListTile(
                  leading: _Lead(
                    key: ValueKey('today-later-lead-${t.id}'),
                    child: const Icon(LucideIcons.calendarDays),
                  ),
                  title: w.text(t.title),
                  subtitle:
                      '${w.weekday(t.due)}$_metaSep${c.projectName(t.project)}',
                  maxSubtitleLines: 2,
                  onTap: () => open(t),
                ),
            ],
          );
          final people = _Section(
            key: const ValueKey('today-team'),
            header: w.teamActivity,
            rows: [
              for (final p in team)
                KeycapListTile(
                  leading: ExcludeSemantics(
                    child: KeycapAvatar(
                      key: ValueKey('today-team-lead-${p.id}'),
                      name: w.text(p.name),
                      slotId: p.id,
                      size: 36,
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
          final feed = StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(minutes: 1)),
            initialData: c.repository.now(),
            builder: (_, time) => _Section(
              key: const ValueKey('today-feed'),
              header: w.recentActivity,
              rows: [
                if (c.data.activity.isEmpty)
                  KeycapListTile(title: w.noActivity),
                for (final (i, event) in c.data.activity.indexed)
                  KeycapListTile(
                    leading: _Lead(
                      key: ValueKey('today-feed-lead-$i'),
                      child: Icon(switch (event.kind) {
                        ActivityKind.finished => LucideIcons.check,
                        ActivityKind.started => LucideIcons.play,
                        ActivityKind.commented => LucideIcons.messageCircle,
                        ActivityKind.logged => LucideIcons.clock3,
                      }),
                    ),
                    title: w.eventAction(event, c.personName(event.person)),
                    subtitle:
                        '${w.text(event.subject)}$timeSeparator${w.timeAgo(event.at, time.data!).replaceAll(' ', ' ')}',
                    maxSubtitleLines: 3,
                  ),
              ],
            ),
          );
          Widget sections(List<Widget> items) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KeycapSpacing.large,
            children: items,
          );
          final timer = _timerCard();
          final week = _weekCard();
          return sections([
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: KeycapSpacing.tight,
              children: [
                Text(
                  '${w.weekday(studyToday)}$_sep${w.shortDate(studyToday)}'
                      .toUpperCase(),
                  style: theme.textTheme.legend,
                ),
                Semantics(
                  header: true,
                  child: Text(w.greeting, style: theme.textTheme.display),
                ),
              ],
            ),
            if (wide) ...[
              Table(
                defaultVerticalAlignment:
                    TableCellVerticalAlignment.intrinsicHeight,
                columnWidths: const {1: FixedColumnWidth(KeycapSpacing.large)},
                children: [
                  TableRow(children: [timer, const SizedBox.shrink(), week]),
                ],
              ),
              _paired(plan, people, together: tasks.isNotEmpty),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: KeycapSpacing.large,
                children: [
                  Expanded(child: sections([blocks, later])),
                  Expanded(child: feed),
                ],
              ),
            ] else ...[
              timer,
              week,
              FocusTraversalGroup(child: plan),
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

  /// Two sections side by side: their headings on one line, their wells at
  /// one height when [together]. A day with nothing due keeps its plan to its
  /// own rows rather than a well as tall as the team's.
  Widget _paired(_Section first, _Section second, {bool together = true}) {
    // Two one-row tables, not one table of two rows: each row still shares
    // one height across both columns, but in a second table row Flutter's
    // table semantics placed the list rows a header's height below where
    // they paint, so a tap through the semantics tree reached the row above.
    Widget row(Widget a, Widget b, {bool level = true}) => Table(
      defaultVerticalAlignment: level
          ? TableCellVerticalAlignment.intrinsicHeight
          : TableCellVerticalAlignment.top,
      columnWidths: const {1: FixedColumnWidth(KeycapSpacing.large)},
      children: [
        TableRow(children: [a, const SizedBox.shrink(), b]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          KeycapSectionHeader(first.header),
          KeycapSectionHeader(second.header),
        ),
        row(
          FocusTraversalGroup(child: first.well()),
          second.well(),
          level: together,
        ),
      ],
    );
  }

  Widget _timerCard() {
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = timer != null && task != null;
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    final colors = theme.colors, type = theme.textTheme;
    final latest = c.data.activity.firstOrNull;
    final scale = MediaQuery.textScalerOf(context).scale(1);
    Future<void> pick() async {
      final title = active ? w.switchTask : w.startTimer;
      final id = await showKeycapDialog<String>(
        context: context,
        builder: (dialog) => KeycapDialog(
          title: title,
          actions: [
            KeycapButton.text(
              onPressed: () => Navigator.pop(dialog),
              child: Text(w.cancel),
            ),
          ],
          content: Semantics(
            label: title,
            child: KeycapCommandPalette(
              autofocus: true,
              hintText: w.search,
              emptyLabel: w.noMatches,
              maxHeight: 52 * scale.clamp(1, 1.6) * (scale > 1.4 ? 3 : 5),
              commands: [
                for (final item in choices)
                  RawCommand(
                    label: w.text(item.title),
                    data: item.id,
                    keywords: [c.projectName(item.project)],
                  ),
              ],
              onSelected: (item) => Navigator.pop(dialog, item.data as String),
            ),
          ),
        ),
      );
      if (mounted && id != null) c.track(id);
    }

    Widget clock(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      return RepaintBoundary(
        child: Semantics(
          identifier: 'stint-elapsed',
          label: w.elapsedLabel(value),
          excludeSemantics: true,
          child: FittedBox(
            alignment: AlignmentDirectional.centerStart,
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              key: const ValueKey('today-timer-digits'),
              textDirection: TextDirection.ltr,
              style: type.display.copyWith(
                fontSize: 44,
                height: 1.1,
                color: active ? colors.accentInk : colors.inkMuted,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
    }

    // The timer is read off the page well's floor, as a keyboard's lock
    // lights are read off its case: the light is lit while it runs.
    final readout = KeycapWell(
      key: const ValueKey('today-timer-well'),
      page: true,
      padding: const EdgeInsets.all(KeycapSpacing.regular),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: KeycapSpacing.small,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: KeycapSpacing.tight,
            children: [
              Row(
                spacing: KeycapSpacing.small,
                children: [
                  _LockLight(
                    key: const ValueKey('today-timer-lamp'),
                    lit: active,
                    size: 8 * scale.clamp(1, 1.35),
                  ),
                  Flexible(
                    child: Text(
                      (active ? w.runningTimer : w.stoppedTimer).toUpperCase(),
                      key: const ValueKey('today-timer-label'),
                      style: type.legend.copyWith(
                        color: active ? colors.accentInk : colors.inkMuted,
                      ),
                    ),
                  ),
                ],
              ),
              TweenAnimationBuilder<Color?>(
                key: ValueKey(task?.id),
                tween: ColorTween(begin: colors.inkMuted, end: colors.ink),
                duration: rawReduceMotionOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                builder: (_, ink, _) => Text(
                  active ? w.text(task.title) : w.chooseTask,
                  key: const ValueKey('today-timer-title'),
                  style: type.heading.copyWith(color: ink),
                ),
              ),
              if (active)
                Text(
                  '${c.projectName(task.project)}$_metaSep${w.since(timer.start)}',
                  style: type.secondary,
                )
              else if (latest != null &&
                  latest.kind == ActivityKind.logged &&
                  latest.person == 'maya')
                Text(
                  w.eventAction(latest, c.personName(latest.person)),
                  style: type.secondary,
                )
              else if (choices.isEmpty)
                Text(w.noTimerTasks, style: type.secondary),
            ],
          ),
          timer == null
              ? clock(c.repository.now())
              : StreamBuilder<DateTime>(
                  stream: c.ticks(const Duration(seconds: 1)),
                  initialData: c.repository.now(),
                  builder: (_, time) => clock(time.data!),
                ),
        ],
      ),
    );
    return LayoutBuilder(
      key: const ValueKey('today-timer-card'),
      builder: (ctx, box) {
        // Stop is the accent key, the one main action while the clock runs;
        // Switch task is an alpha key beside it.
        final stop = KeycapButton.accent(
          key: const ValueKey('today-action-first'),
          icon: const Icon(LucideIcons.square),
          onPressed: c.stopTimer,
          child: Text(w.stopTimer),
        );
        final change = KeycapButton(
          key: const ValueKey('today-action-last'),
          icon: const Icon(LucideIcons.arrowLeftRight),
          onPressed: choices.isEmpty ? null : pick,
          child: Text(w.switchTask),
        );
        final buttons = active
            ? StintPair(
                first: stop,
                second: change,
                spacing: KeycapMetrics.keyGap,
                runSpacing: KeycapSpacing.small,
              )
            : KeycapButton.accent(
                icon: const Icon(LucideIcons.play),
                onPressed: choices.isEmpty ? null : pick,
                child: Text(w.startTimer),
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KeycapSpacing.medium,
          children: [
            Flexible(
              fit: box.hasBoundedHeight ? FlexFit.tight : FlexFit.loose,
              child: readout,
            ),
            buttons,
          ],
        );
      },
    );
  }

  Widget _weekCard() {
    final monday = mondayOf(studyToday);
    final minutes = c.totalMinutes(monday), daily = c.dailyMinutes(monday);
    return LayoutBuilder(
      builder: (ctx, box) {
        final scale = MediaQuery.textScalerOf(ctx).scale(1);
        final width = box.maxWidth / scale;
        final count = w.number(c.openTasks.length), hours = w.duration(minutes);
        // Each reading is a tall key with two legends, as a keycap prints a
        // symbol over its letter: the measure at its top, the figure at its
        // foot. Pressed, it opens the place the figure comes from.
        final open = KeycapLegendKey(
          key: const ValueKey('today-stat-tasks'),
          icon: const Icon(LucideIcons.listChecks),
          legend: w.openTasks,
          subLegend: count,
          semanticLabel: '${w.openTasks}, $count',
          onPressed: () => go(Place.tasks),
        );
        final logged = KeycapLegendKey(
          key: const ValueKey('today-stat-hours'),
          icon: const Icon(LucideIcons.clock3),
          legend: w.hoursThisWeek,
          subLegend: hours,
          semanticLabel: '${w.hoursThisWeek}, $hours',
          onPressed: () => go(Place.time),
        );
        final chart = _KeycapWeek(words: w, daily: daily, narrow: width < 260);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: KeycapSpacing.medium,
          children: [
            // Two keys of one row; at large text in a phone's column each
            // takes the row, so neither legend is cut.
            if (scale >= 1.5 && width < 300)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: KeycapMetrics.keyGap,
                children: [open, logged],
              )
            else
              // A legend that takes a second line grows its key; the other
              // key of the row stands as tall.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: KeycapMetrics.keyGap,
                  children: [
                    Expanded(child: open),
                    Expanded(child: logged),
                  ],
                ),
              ),
            if (box.hasBoundedHeight)
              Expanded(child: chart)
            else
              SizedBox(height: 136 * scale.clamp(1, 1.5), child: chart),
          ],
        );
      },
    );
  }

  Widget _planRow(Task task) {
    final tracking = c.data.timer?.taskId == task.id;
    final project = c.projectName(task.project);
    final title = w.text(task.title);
    return MergeSemantics(
      key: ValueKey('plan-${task.id}'),
      child: Semantics(
        checked: task.done,
        child: KeycapListTile(
          title: title,
          subtitle: project,
          semanticLabel: tracking
              ? '$title, $project, ${w.runningTimer}'
              : '$title, $project',
          showChevron: false,
          onTap: () => c.changeTasks([task.id], done: !task.done),
          style: task.done
              ? KeycapStyle(
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: theme.colors.inkMuted,
                    ),
                  ),
                )
              : null,
          leading: ExcludeSemantics(
            child: _Lead(
              key: ValueKey('today-plan-lead-${task.id}'),
              child: KeycapToggleKey(
                theme: theme,
                states: const {},
                latched: task.done,
                shape: KeycapToggleShape.square,
                legend: (color, t) => CustomPaint(
                  size: const Size.square(14),
                  painter: _Tick(t, color),
                ),
              ),
            ),
          ),
          // The running task's own lock light, lit at the row's end.
          trailing: tracking
              ? const _LockLight(
                  key: ValueKey('today-plan-running'),
                  lit: true,
                  size: 8,
                )
              : null,
        ),
      ),
    );
  }

  Widget _block(TimeEntry entry, int index) => KeycapListTile(
    leading: _Lead(
      key: ValueKey('today-blocks-lead-$index'),
      child: _ProjectCap(project: entry.project),
    ),
    title: w.text(entry.note),
    subtitle: '${w.timeRange(entry)}$_metaSep${c.projectName(entry.project)}',
    maxSubtitleLines: 2,
  );
}

/// The widest Today, Time and Settings stand under their top bar.
const double _measure = 1136;

/// A row's leading mark, centred in a square of one width, so a section's
/// glyphs and caps share their centre line.
class _Lead extends StatelessWidget {
  const _Lead({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      SizedBox.square(dimension: 24, child: Center(child: child));
}

/// A small cap in the plastic of a project's role in the colourway: the
/// open studio in the accent, the field guide in the modifier, the
/// workshops in the alpha.
class _ProjectCap extends StatelessWidget {
  const _ProjectCap({required this.project});
  final String project;

  @override
  Widget build(BuildContext context) {
    final colors = KeycapTheme.of(context).colors;
    final cap = switch (projects.indexWhere((p) => p.id == project) % 3) {
      0 => colors.accent,
      1 => colors.modifier,
      _ => colors.alpha,
    };
    return SizedBox.square(
      dimension: 16,
      child: KeycapCap(
        face: KeycapFace.of(
          cap,
          colors,
        ).copyWith(radius: KeycapMetrics.smallKeyRadius - 2),
        walls: KeycapMetrics.walls(16),
      ),
    );
  }
}

/// A keyboard's lock light: dark while off; lit in the accent, glowing
/// faintly round itself, while its timer runs.
class _LockLight extends StatelessWidget {
  const _LockLight({super.key, required this.lit, required this.size});
  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = KeycapTheme.of(context).colors;
    return AnimatedContainer(
      duration: rawReduceMotionOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? colors.accent.top : colors.wellPressed,
        border: Border.all(color: lit ? colors.accent.wall : colors.edge),
        boxShadow: [
          if (lit)
            BoxShadow(
              color: colors.accent.top.withValues(alpha: 0.45),
              blurRadius: size,
            ),
        ],
      ),
    );
  }
}

/// A tick drawn in as it fades, the toggle key's legend.
class _Tick extends CustomPainter {
  _Tick(this.t, this.color);
  final double t;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final paint = Paint()
      ..color = color.withValues(alpha: color.a * t)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.14, size.height * 0.52)
        ..lineTo(size.width * 0.40, size.height * 0.76)
        ..lineTo(size.width * 0.86, size.height * 0.26),
      paint,
    );
  }

  @override
  bool shouldRepaint(_Tick old) => old.t != t || old.color != color;
}

/// A Today section: its rows in one page well under their printed heading,
/// as [KeycapListGroup] sets them, so a pair can stand its two wells at one
/// height.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.header, required this.rows});
  final String header;
  final List<Widget> rows;

  /// The well alone, keyed as the section, for a pair under its own
  /// headings.
  Widget well() => KeycapWell(
    key: key,
    page: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, row) in rows.indexed) ...[
          if (i > 0)
            const KeycapDivider(
              indent: KeycapSpacing.regular,
              endIndent: KeycapSpacing.regular,
            ),
          row,
        ],
      ],
    ),
  );

  @override
  Widget build(BuildContext context) =>
      KeycapListGroup(header: header, children: rows);
}

/// The week's hours in a well cut into the case: each day a slot, its hours
/// risen in it in the modifier plastic, today's in the accent.
class _KeycapWeek extends StatelessWidget {
  const _KeycapWeek({
    required this.words,
    required this.daily,
    required this.narrow,
  });
  final StintWords words;
  final List<int> daily;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final theme = KeycapTheme.of(context);
    final colors = theme.colors, week = mondayOf(studyToday);
    final maximum = daily.fold(480, (a, b) => a > b ? a : b);
    final scale = ((maximum + 479) ~/ 480) * 480;
    return KeycapWell(
      key: const ValueKey('today-chart'),
      padding: const EdgeInsets.fromLTRB(
        KeycapSpacing.regular,
        KeycapSpacing.medium,
        KeycapSpacing.regular,
        KeycapSpacing.medium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: KeycapSpacing.tight,
        children: [
          Text(words.duration(scale), style: theme.textTheme.legend),
          Expanded(
            child: Row(
              key: const ValueKey('today-chart-plot'),
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (i, minutes) in daily.indexed)
                  Expanded(
                    child: Semantics(
                      label:
                          '${words.weekday(addDays(week, i))}, ${words.duration(minutes)}',
                      excludeSemantics: true,
                      child: Column(
                        spacing: KeycapSpacing.small,
                        children: [
                          Expanded(
                            child: _DaySlot(
                              key: ValueKey('today-day-slot-$i'),
                              share: minutes / scale,
                              today: addDays(week, i) == studyToday,
                            ),
                          ),
                          Text(
                            (narrow
                                ? words.weekdayNarrow(addDays(week, i))
                                : words.weekdayShort(addDays(week, i))),
                            key: ValueKey('today-day-label-$i'),
                            style: theme.textTheme.legend.copyWith(
                              letterSpacing: 0,
                              color: addDays(week, i) == studyToday
                                  ? colors.ink
                                  : colors.inkMuted,
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

/// One day's slot: a narrow groove in the well's floor, its hours risen in
/// it from the foot. A day with no hours leaves the groove empty.
class _DaySlot extends StatelessWidget {
  const _DaySlot({super.key, required this.share, required this.today});
  final double share;
  final bool today;

  static const double _width = 14;

  @override
  Widget build(BuildContext context) {
    final colors = KeycapTheme.of(context).colors;
    final plastic = today ? colors.accent : colors.modifier;
    // The hours read as data on the slot's floor (3:1, a chart's marks):
    // the modifier's grey stood at the floor's own tone (1.1:1) and retro's
    // orange at 1.2:1 by day, so each plastic keeps its hue at a tone that
    // reads, and a cap that reads already keeps its own colours. Today
    // stands out by the accent's hue, the past days by their grey.
    final top = RawPalette.readableTone(
      plastic.top,
      on: [colors.wellPressed],
      ratio: 3,
    );
    final front = top == plastic.top
        ? plastic.front
        : Color.alphaBlend(const Color(0x33000000), top);
    const radius = BorderRadius.all(Radius.circular(4));
    return Center(
      child: SizedBox(
        width: _width,
        child: LayoutBuilder(
          builder: (_, box) => DecoratedBox(
            decoration: BoxDecoration(
              color: colors.wellPressed,
              borderRadius: radius,
              border: Border.all(color: colors.hairline),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: share <= 0
                  ? const SizedBox(width: _width)
                  // The risen hours show the plastic's top and, at their
                  // foot, a band of its front wall, as a cap's front shows.
                  : ClipRRect(
                      borderRadius: radius,
                      child: SizedBox(
                        width: _width,
                        height: (box.maxHeight * share).clamp(
                          _width,
                          box.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: ColoredBox(color: top)),
                            SizedBox(
                              height: 3,
                              child: ColoredBox(color: front),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
