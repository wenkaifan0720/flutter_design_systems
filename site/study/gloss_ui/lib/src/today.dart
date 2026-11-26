part of '../stint_gloss.dart';

extension _Today on _WorkspaceState {
  /// The separator inside a meta line: a middle dot, or in Arabic the Arabic
  /// comma, because a middle dot beside Arabic-Indic figures reads as a zero.
  String get _sep => w.arabic ? '، ' : ' · ';

  /// The separator inside a list or timer meta line. At 200% text such a
  /// line wraps anyway, so its two parts take a line each rather than one
  /// breaking at the separator, as the activity feed's times already do.
  String get _metaSep =>
      MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? '\n' : _sep;

  Widget today() => GlossScreen(
    topBar: GlossTopBar(title: w.today, actions: [command]),
    fullBleed: _desk,
    body: _underStrip(
      dataBody(
        () => LayoutBuilder(
          builder: (ctx, box) {
            final wide =
                box.maxWidth >= 590 * MediaQuery.textScalerOf(ctx).scale(1);
            final avatarSize =
                32.0 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.25);
            // Each activity time keeps its own line wherever a subtitle and its
            // time would not share one: at large text, and in the narrow
            // tablet column, so no row wraps on its own and strands its time.
            final textScale = MediaQuery.textScalerOf(ctx).scale(1);
            final feedWidth = wide
                ? (box.maxWidth - GlossSpacing.large) / 2
                : box.maxWidth;
            final timeSeparator =
                textScale >= 1.5 || feedWidth / textScale < 330
                ? '\n'
                : w.arabic
                ? '\u060c\u00a0'
                : '\u00a0·\u00a0';
            final tasks = c.todayTasks;
            final plan = GlossWell(
              key: const ValueKey('today-plan'),
              header: w.todaysPlan,
              dividerIndent: GlossListTile.leadingExtent,
              children: [
                if (tasks.isEmpty) GlossListTile(title: w.noTasksToday),
                for (final task in tasks) _planRow(task),
                GlossListTile(
                  leading: const Icon(
                    LucideIcons.listChecks,
                    key: ValueKey('today-plan-lead-all'),
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
            final blocks = GlossWell(
              key: const ValueKey('today-blocks'),
              header: w.timeBlocks,
              dividerIndent: GlossListTile.leadingExtent,
              children: [
                if (entries.isEmpty) GlossListTile(title: w.noBlocks),
                for (final (i, entry) in entries.indexed)
                  _block(entry, i, entries.length),
                GlossListTile(
                  leading: const Icon(
                    LucideIcons.clock3,
                    key: ValueKey('today-blocks-lead-all'),
                  ),
                  title: w.seeTime,
                  onTap: () => go(Place.time),
                ),
              ],
            );
            final upcoming = c.laterThisWeek;
            final later = GlossWell(
              key: const ValueKey('today-later'),
              header: w.laterThisWeek,
              dividerIndent: GlossListTile.leadingExtent,
              children: [
                if (upcoming.isEmpty) GlossListTile(title: w.allClear),
                for (final t in upcoming)
                  GlossListTile(
                    leading: Icon(
                      LucideIcons.calendarDays,
                      key: ValueKey('today-later-lead-${t.id}'),
                    ),
                    title: w.text(t.title),
                    subtitle:
                        '${w.weekday(t.due)}$_metaSep${c.projectName(t.project)}',
                    onTap: () => open(t),
                  ),
              ],
            );
            final people = GlossWell(
              key: const ValueKey('today-team'),
              header: w.teamActivity,
              dividerIndent: GlossListTile.leadingExtent,
              children: [
                for (final p in team)
                  GlossListTile(
                    leading: ExcludeSemantics(
                      child: SizedBox.square(
                        dimension: 24,
                        child: OverflowBox(
                          minWidth: avatarSize,
                          maxWidth: avatarSize,
                          minHeight: avatarSize,
                          maxHeight: avatarSize,
                          child: GlossAvatar(
                            key: ValueKey('today-team-lead-${p.id}'),
                            name: w.text(p.name),
                            size: avatarSize,
                            style: GlossStyle(
                              foreground: WidgetStatePropertyAll(
                                theme.colors.ink,
                              ),
                            ),
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
            final feed = StreamBuilder<DateTime>(
              stream: c.ticks(const Duration(minutes: 1)),
              initialData: c.repository.now(),
              builder: (_, time) => GlossWell(
                key: const ValueKey('today-feed'),
                header: w.recentActivity,
                dividerIndent: GlossListTile.leadingExtent,
                children: [
                  if (c.data.activity.isEmpty)
                    GlossListTile(title: w.noActivity),
                  for (final (i, event) in c.data.activity.indexed)
                    GlossListTile(
                      leading: Icon(
                        switch (event.kind) {
                          ActivityKind.finished => LucideIcons.check,
                          ActivityKind.started => LucideIcons.play,
                          ActivityKind.commented => LucideIcons.messageCircle,
                          ActivityKind.logged => LucideIcons.clock3,
                        },
                        key: ValueKey('today-feed-lead-$i'),
                        size: 18,
                      ),
                      title: w.eventAction(event, c.personName(event.person)),
                      subtitle:
                          '${w.text(event.subject)}$timeSeparator${w.timeAgo(event.at, time.data!).replaceAll(' ', '\u00a0')}',
                    ),
                ],
              ),
            );
            Widget sections(List<Widget> items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: GlossSpacing.large,
              children: items,
            );
            final timer = _timerCard();
            final week = _weekCard();
            return sections([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    '${w.weekday(studyToday)}$_sep${w.shortDate(studyToday)}',
                    style: theme.textTheme.label.copyWith(
                      color: theme.colors.jadeInk,
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(w.greeting, style: theme.textTheme.headline),
                  ),
                ],
              ),
              if (wide) ...[
                Table(
                  defaultVerticalAlignment:
                      TableCellVerticalAlignment.intrinsicHeight,
                  columnWidths: const {1: FixedColumnWidth(24)},
                  children: [
                    TableRow(children: [timer, const SizedBox.shrink(), week]),
                  ],
                ),
                _pairedWells(plan, people, together: tasks.isNotEmpty),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: GlossSpacing.large,
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
    ),
  );

  /// Whether the shell stands its sidebar beside Today, with no bottom bar.
  bool get _desk =>
      MediaQuery.sizeOf(context).width >= GlossMetrics.sidebarBreakpoint;

  /// Today's grid under the desktop title strip: the page's margins, starting
  /// on the title's edge. The screen's 1080 px reading column would centre it
  /// in the leftover width at 1440, 28 px in from the title and short of the
  /// command; here it runs from the one to the other, up to 1136 px. Narrower
  /// layouts keep the screen's own column, which their width already fills.
  Widget _underStrip(Widget body) {
    if (!_desk) return body;
    final media = MediaQuery.of(context);
    final margin = GlossSpacing.pageMargin(media.size.width);
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1136 + 2 * margin),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margin,
            GlossSpacing.large,
            margin,
            GlossSpacing.extraLarge + media.padding.bottom,
          ),
          child: body,
        ),
      ),
    );
  }

  /// [together]: the two wells stand at one height. A day with nothing due
  /// keeps its plan to its own two rows rather than spreading them, a lone
  /// engraved line between, down a well as tall as the team's.
  Widget _pairedWells(
    GlossWell first,
    GlossWell second, {
    bool together = true,
  }) {
    Widget floor(GlossWell well) => GlossSurface(
      key: well.key,
      face: GlossFace.well(theme.colors, radius: GlossMetrics.wellRadius),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(GlossMetrics.wellRadius),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final (index, row) in well.children.indexed) ...[
              if (index > 0)
                GlossEngravedLine(
                  indent: well.dividerIndent ?? GlossListTile.leadingExtent,
                  endIndent: 2,
                ),
              row,
            ],
          ],
        ),
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
      columnWidths: const {1: FixedColumnWidth(GlossSpacing.large)},
      children: [
        TableRow(children: [a, const SizedBox.shrink(), b]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(
          GlossSectionHeader(first.header!),
          GlossSectionHeader(second.header!),
        ),
        row(
          FocusTraversalGroup(child: floor(first)),
          floor(second),
          level: together,
        ),
      ],
    );
  }

  Future<String?> _showTaskChooser(WidgetBuilder builder) {
    final porcelain = theme;
    return Navigator.of(context, rootNavigator: true).push<String>(
      RawModalDialogRoute<String>(
        barrierColor: porcelain.colors.scrim,
        dampingRatio: GlossMotion.panelDamping,
        stiffness: GlossMotion.panelStiffness,
        builder: (dialog, route) => GlossTheme(
          data: porcelain,
          child: ScaleTransition(
            scale: route.animation.drive(Tween<double>(begin: .96, end: 1)),
            child: Builder(builder: builder),
          ),
        ),
      ),
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
      final rowHeight = 48.0 * scale.clamp(1, 1.6);
      final id = await _showTaskChooser(
        (dialog) => GlossDialog(
          title: title,
          actions: [
            GlossDialogAction(
              label: w.cancel,
              onPressed: () => Navigator.pop(dialog),
            ),
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
            fieldBuilder: (_, field) => GlossTextField(
              controller: field.controller,
              focusNode: field.focusNode,
              hintText: w.search,
              semanticLabel: w.search,
              prefixIcon: const Icon(LucideIcons.search),
              onSubmitted: (_) => field.submit(),
            ),
            emptyBuilder: (_) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(w.noMatches),
            ),
            itemBuilder: (_, item, states) => GlossMenuRow(
              label: item.label,
              trailing: states.contains(WidgetState.focused)
                  ? Icon(
                      w.arabic
                          ? LucideIcons.cornerDownRight
                          : LucideIcons.cornerDownLeft,
                      size: 16,
                      color: colors.jadeInk,
                    )
                  : null,
              // The search well has keyboard focus. The active result has a
              // pearl plate, like the pointer's current row in a Gloss menu.
              states: {
                if (states.contains(WidgetState.focused)) WidgetState.hovered,
                if (states.contains(WidgetState.pressed)) WidgetState.pressed,
              },
              style: GlossStyle(
                minimumSize: WidgetStatePropertyAll(Size(0, rowHeight)),
              ),
            ),
            layoutBuilder: (_, field, results) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: [
                field,
                Flexible(
                  child: GlossSurface(
                    face: GlossFace.well(colors, radius: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: results,
                    ),
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
                fontSize: 43,
                height: 1.12,
                color: active ? colors.jadeInk : colors.inkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
    }

    final readout = GlossSurface(
      key: const ValueKey('today-timer-well'),
      face: GlossFace.well(colors, radius: GlossMetrics.wellRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: 8,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Row(
                  spacing: 8,
                  children: [
                    Transform.translate(
                      // Align the bead with the ink in the native label face.
                      offset: Offset(0, (w.arabic ? 1 : 2.5) * scale),
                      child: SizedBox.square(
                        key: const ValueKey('today-timer-lamp'),
                        dimension: 10 * scale.clamp(1, 1.35),
                        child: AnimatedGlossSurface(
                          face: active
                              ? GlossFace.gel(colors)
                              : GlossFace.well(colors),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        active ? w.runningTimer : w.stoppedTimer,
                        key: const ValueKey('today-timer-label'),
                        style: type.label.copyWith(
                          color: active ? colors.jadeInk : colors.inkSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                TweenAnimationBuilder<Color?>(
                  key: ValueKey(task?.id),
                  tween: ColorTween(
                    begin: colors.inkSecondary,
                    end: colors.ink,
                  ),
                  duration: rawReduceMotionOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 180),
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
      ),
    );
    return LayoutBuilder(
      key: const ValueKey('today-timer-card'),
      builder: (ctx, box) {
        final stop = GlossButton.filled(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: Icon(LucideIcons.square, size: 14 * scale.clamp(1, 1.4)),
          onPressed: c.stopTimer,
        );
        final change = GlossButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          onPressed: choices.isEmpty ? null : pick,
        );
        final buttons = active
            ? StintPair(first: stop, second: change)
            : GlossButton.filled(
                w.startTimer,
                icon: const Icon(LucideIcons.play, size: 16),
                onPressed: choices.isEmpty ? null : pick,
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
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
    final colors = theme.colors, type = theme.textTheme;
    Widget stat(String key, String label, String value, String spoken) =>
        GlossSurface(
          key: ValueKey('today-stat-$key'),
          face: GlossFace.well(colors, radius: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Semantics(
              label: '$label, $spoken',
              excludeSemantics: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 3,
                children: [
                  Text(label, style: type.caption),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      style: type.title.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return LayoutBuilder(
      builder: (ctx, box) {
        final width = box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1);
        final count = w.number(c.openTasks.length), hours = w.duration(minutes);
        final chart = _JadeWeek(
          words: w,
          daily: daily,
          shortLabels: width < 230,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 12,
          children: [
            Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.intrinsicHeight,
              columnWidths: const {1: FixedColumnWidth(8)},
              children: [
                TableRow(
                  children: [
                    stat('tasks', w.openTasks, count, count),
                    const SizedBox.shrink(),
                    stat('hours', w.hoursThisWeek, hours, hours),
                  ],
                ),
              ],
            ),
            if (box.hasBoundedHeight)
              Expanded(child: chart)
            else
              SizedBox(
                height:
                    94 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.5),
                child: chart,
              ),
          ],
        );
      },
    );
  }

  Widget _planRow(Task task) {
    final tracking = c.data.timer?.taskId == task.id;
    final project = c.projectName(task.project);
    final detail = tracking ? '$project$_metaSep${w.runningTimer}' : project;
    return RawButton(
      key: ValueKey('plan-${task.id}'),
      checked: task.done,
      button: false,
      excludeSemantics: true,
      semanticLabel: '${w.text(task.title)}, $detail',
      onPressed: () => c.changeTasks([task.id], done: !task.done),
      builder: (_, states, _) {
        final colors = theme.colors;
        final face = GlossFace.well(colors, radius: 6).copyWith(
          edge: Color.lerp(
            colors.well,
            colors.inkSecondary,
            colors.brightness == Brightness.dark ? .64 : .52,
          ),
        );
        return GlossListTile(
          title: w.text(task.title),
          subtitle: detail,
          style: task.done
              ? GlossStyle(
                  textStyle: WidgetStatePropertyAll(
                    TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: colors.inkSecondary,
                    ),
                  ),
                )
              : tracking
              ? GlossStyle(
                  foreground: WidgetStatePropertyAll(colors.jadeInk),
                  textStyle: const WidgetStatePropertyAll(
                    TextStyle(fontWeight: FontWeight.w600),
                  ),
                )
              : null,
          leading: AnimatedGlossSurface(
            key: ValueKey('today-plan-lead-${task.id}'),
            face: face.copyWith(
              travel: task.done || states.contains(WidgetState.pressed) ? 1 : 0,
              focus: glossFocusOf(
                colors,
                focused: states.contains(WidgetState.focused),
              ),
            ),
            child: SizedBox.square(
              dimension: 24,
              child: task.done
                  ? Icon(LucideIcons.check, size: 17, color: colors.jadeInk)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _block(TimeEntry entry, int index, int count) {
    final colors = theme.colors;
    return Stack(
      children: [
        PositionedDirectional(
          start: GlossSpacing.regular + 11,
          top: 0,
          bottom: 0,
          width: 2,
          child: Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: index > 0 ? colors.hairline : const Color(0x00000000),
                  child: const SizedBox.expand(),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: index + 1 < count
                      ? colors.hairline
                      : const Color(0x00000000),
                  child: const SizedBox.expand(),
                ),
              ),
            ],
          ),
        ),
        GlossListTile(
          leading: SizedBox.square(
            key: ValueKey('today-blocks-lead-$index'),
            dimension: 13,
            child: GlossSurface(
              face: GlossFace.pearl(colors).copyWith(lift: 0, lens: .12),
            ),
          ),
          title: w.text(entry.note),
          subtitle:
              '${w.timeRange(entry)}$_metaSep${c.projectName(entry.project)}',
        ),
      ],
    );
  }
}

class _JadeWeek extends StatelessWidget {
  const _JadeWeek({
    required this.words,
    required this.daily,
    required this.shortLabels,
  });
  final StintWords words;
  final List<int> daily;
  final bool shortLabels;

  @override
  Widget build(BuildContext context) {
    final theme = GlossTheme.of(context);
    final colors = theme.colors, week = mondayOf(studyToday);
    final maximum = daily.fold(480, (a, b) => a > b ? a : b);
    final scale = ((maximum + 479) ~/ 480) * 480;
    return GlossSurface(
      key: const ValueKey('today-chart'),
      face: GlossFace.well(colors, radius: GlossMetrics.wellRadius),
      child: Padding(
        // The day labels' ink sits as far above the floor as the scale's
        // ink sits below the rim, and the scale starts on the stat wells'
        // 12 px text edge above it.
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 3,
          children: [
            Text(
              words.duration(scale),
              style: theme.textTheme.caption.copyWith(
                color: colors.inkSecondary,
              ),
            ),
            Expanded(
              child: DecoratedBox(
                key: const ValueKey('today-chart-plot'),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: colors.hairline)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final (i, minutes) in daily.indexed)
                      Expanded(
                        child: Semantics(
                          label:
                              '${words.weekday(addDays(week, i))}, ${words.duration(minutes)}',
                          excludeSemantics: true,
                          child: Column(
                            spacing: 4,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: FractionallySizedBox(
                                    widthFactor: .55,
                                    heightFactor: minutes == 0
                                        ? null
                                        : minutes / scale,
                                    child: SizedBox(
                                      key: ValueKey('today-day-slot-$i'),
                                      height: minutes == 0
                                          ? 2
                                          : double.infinity,
                                      child: minutes == 0
                                          ? DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: colors.inkSecondary
                                                    .withValues(alpha: .65),
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                              ),
                                            )
                                          : DecoratedBox(
                                              decoration: BoxDecoration(
                                                color: colors.jadeInk,
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              Text(
                                shortLabels
                                    ? words.weekdayNarrow(addDays(week, i))
                                    : words.weekdayShort(addDays(week, i)),
                                key: ValueKey('today-day-label-$i'),
                                style: theme.textTheme.caption,
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
