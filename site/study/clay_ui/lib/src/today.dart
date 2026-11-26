part of '../stint_clay.dart';

extension _Today on _WorkspaceState {
  /// The separator inside a meta line: a middle dot, or in Arabic the Arabic
  /// comma, because a middle dot beside Arabic-Indic figures reads as a zero.
  String get _sep => w.arabic ? '، ' : ' · ';

  /// The separator inside a list or timer meta line. At 200% text such a
  /// line wraps anyway, so its two parts take a line each rather than one
  /// breaking at the separator.
  String get _metaSep =>
      MediaQuery.textScalerOf(context).scale(1) >= 1.5 ? '\n' : _sep;

  Widget today() => ClayScreen(
    topBar: ClayTopBar(title: w.today, actions: [command]),
    fullBleed: _desk,
    body: _underBar(
      dataBody(
        () => LayoutBuilder(
          builder: (ctx, box) {
            final scale = MediaQuery.textScalerOf(ctx).scale(1);
            final wide = box.maxWidth >= 590 * scale;
            // Each activity time keeps its own line wherever a subtitle and
            // its time would not share one: at large text, and in the narrow
            // tablet column, so no row wraps on its own and strands its time.
            final feedWidth = wide
                ? (box.maxWidth - ClaySpacing.large) / 2
                : box.maxWidth;
            final timeSeparator = scale >= 1.5 || feedWidth / scale < 330
                ? '\n'
                : w.arabic
                ? '، '
                : ' · ';
            final tasks = c.todayTasks;
            final plan = _Section(
              key: const ValueKey('today-plan'),
              header: w.todaysPlan,
              rows: [
                if (tasks.isEmpty) ClayListTile(title: w.noTasksToday),
                for (final task in tasks) _planRow(task),
                ClayListTile(
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
            final blocks = _Section(
              key: const ValueKey('today-blocks'),
              header: w.timeBlocks,
              rows: [
                if (entries.isEmpty) ClayListTile(title: w.noBlocks),
                for (final (i, entry) in entries.indexed) _block(entry, i),
                ClayListTile(
                  leading: const Icon(LucideIcons.clock3),
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
                if (upcoming.isEmpty) ClayListTile(title: w.allClear),
                for (final t in upcoming)
                  ClayListTile(
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
            final people = _Section(
              key: const ValueKey('today-team'),
              header: w.teamActivity,
              rows: [
                for (final (i, p) in team.indexed)
                  ClayListTile(
                    leading: ExcludeSemantics(
                      child: ClayAvatar(
                        key: ValueKey('today-team-lead-${p.id}'),
                        name: w.text(p.name),
                        size: 36,
                        tint: _tints[i % _tints.length],
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
                    ClayListTile(title: w.noActivity),
                  for (final (i, event) in c.data.activity.indexed)
                    ClayListTile(
                      leading: Icon(switch (event.kind) {
                        ActivityKind.finished => LucideIcons.check,
                        ActivityKind.started => LucideIcons.play,
                        ActivityKind.commented => LucideIcons.messageCircle,
                        ActivityKind.logged => LucideIcons.clock3,
                      }, key: ValueKey('today-feed-lead-$i')),
                      title: w.eventAction(event, c.personName(event.person)),
                      subtitle:
                          '${w.text(event.subject)}$timeSeparator${w.timeAgo(event.at, time.data!).replaceAll(' ', ' ')}',
                    ),
                ],
              ),
            );
            Widget sections(List<Widget> items) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ClaySpacing.large,
              children: items,
            );
            final timer = _timerCard();
            final week = _weekCard();
            return sections([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ClaySpacing.tight,
                children: [
                  Text(
                    '${w.weekday(studyToday)}$_sep${w.shortDate(studyToday)}',
                    style: theme.textTheme.label.copyWith(
                      color: theme.colors.accentInk,
                    ),
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      w.greeting,
                      style: theme.textTheme.headline.copyWith(
                        color: theme.colors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              if (wide) ...[
                Table(
                  defaultVerticalAlignment:
                      TableCellVerticalAlignment.intrinsicHeight,
                  columnWidths: const {1: FixedColumnWidth(ClaySpacing.large)},
                  children: [
                    TableRow(children: [timer, const SizedBox.shrink(), week]),
                  ],
                ),
                _paired(plan, people, together: tasks.isNotEmpty),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: ClaySpacing.large,
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

  /// Whether the shell stands its sidebar beside Today.
  bool get _desk =>
      MediaQuery.sizeOf(context).width >= ClayMetrics.sidebarBreakpoint;

  /// A page under the desktop top bar: the page's margins, starting on the
  /// bar title's edge and running to its last key, rather than the screen's
  /// own 1080 px column centred in the leftover width.
  Widget _underBar(Widget body) {
    if (!_desk) return body;
    final media = MediaQuery.of(context);
    final margin = ClaySpacing.pageMargin(media.size.width);
    return Align(
      alignment: AlignmentDirectional.topStart,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 1136 + 2 * margin),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            margin,
            ClaySpacing.large,
            margin,
            ClaySpacing.extraLarge + media.padding.bottom,
          ),
          child: body,
        ),
      ),
    );
  }

  /// Two sections side by side: their headings on one line, their slabs at
  /// one height when [together]. A day with nothing due keeps its plan to its
  /// own rows rather than a slab as tall as the team's.
  Widget _paired(_Section first, _Section second, {bool together = true}) {
    // Two one-row tables, not one table of two rows: each row still shares
    // one height across both columns, but in a second table row Flutter's
    // table semantics placed the list rows a header's height below where
    // they paint, so a tap through the semantics tree reached the row above.
    Widget row(Widget a, Widget b, {bool level = true}) => Table(
      defaultVerticalAlignment: level
          ? TableCellVerticalAlignment.intrinsicHeight
          : TableCellVerticalAlignment.top,
      columnWidths: const {1: FixedColumnWidth(ClaySpacing.large)},
      children: [
        TableRow(children: [a, const SizedBox.shrink(), b]),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        row(ClaySectionHeader(first.header), ClaySectionHeader(second.header)),
        row(
          FocusTraversalGroup(child: first.slab(context)),
          second.slab(context),
          level: together,
        ),
      ],
    );
  }

  Future<String?> _showTaskChooser(WidgetBuilder builder) =>
      showClayDialog<String>(context: context, builder: builder);

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
        (dialog) => ClayDialog(
          title: title,
          actions: [
            ClayDialogAction(
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
            fieldBuilder: (_, field) => ClayTextField(
              controller: field.controller,
              focusNode: field.focusNode,
              hintText: w.search,
              semanticLabel: w.search,
              prefixIcon: const Icon(LucideIcons.search),
              onSubmitted: (_) => field.submit(),
            ),
            emptyBuilder: (_) => Padding(
              padding: const EdgeInsets.all(ClaySpacing.medium),
              child: Text(
                w.noMatches,
                style: type.secondary.copyWith(color: colors.inkSecondary),
              ),
            ),
            // The search field keeps the keys; the active result takes the
            // breath of a well a Clay row takes under the pointer.
            itemBuilder: (_, item, states) => ConstrainedBox(
              constraints: BoxConstraints(minHeight: rowHeight),
              child: _ChooserRow(
                label: item.label,
                active: states.contains(WidgetState.focused),
                pressed: states.contains(WidgetState.pressed),
                arabic: w.arabic,
              ),
            ),
            layoutBuilder: (_, field, results) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ClaySpacing.small,
              children: [
                field,
                Flexible(
                  child: ClaySurface(
                    face: ClayFace.well(colors, radius: ClayRadius.control),
                    child: Padding(
                      padding: const EdgeInsets.all(ClaySpacing.tight),
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
                fontSize: 44,
                height: 1.1,
                color: active ? colors.accentInk : colors.inkSecondary,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
      );
    }

    // The timer is a slab of the look's clay; the elapsed time sits in it,
    // and a coral bead lights while it runs.
    final readout = ClaySurface(
      key: const ValueKey('today-timer-well'),
      face: ClayFace.raised(colors, radius: ClayRadius.large),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClaySpacing.roomy,
          ClaySpacing.regular,
          ClaySpacing.roomy,
          ClaySpacing.regular,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          spacing: ClaySpacing.small,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: ClaySpacing.tight,
              children: [
                Row(
                  spacing: ClaySpacing.small,
                  children: [
                    Transform.translate(
                      // Seat the bead on the label's ink, not its line box.
                      offset: Offset(0, (w.arabic ? 1 : 1.5) * scale),
                      child: SizedBox.square(
                        key: const ValueKey('today-timer-lamp'),
                        dimension: 12 * scale.clamp(1, 1.35),
                        child: AnimatedClaySurface(
                          face: active
                              ? ClayFace.raised(
                                  colors,
                                  color: colors.accent,
                                  radius: 8,
                                )
                              : ClayFace.well(colors, radius: 8),
                        ),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        active ? w.runningTimer : w.stoppedTimer,
                        key: const ValueKey('today-timer-label'),
                        style: type.label.copyWith(
                          color: active
                              ? colors.accentInk
                              : colors.inkSecondary,
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
                    style: type.secondary.copyWith(color: colors.inkSecondary),
                  )
                else if (latest != null &&
                    latest.kind == ActivityKind.logged &&
                    latest.person == 'maya')
                  Text(
                    w.eventAction(latest, c.personName(latest.person)),
                    style: type.secondary.copyWith(color: colors.inkSecondary),
                  )
                else if (choices.isEmpty)
                  Text(
                    w.noTimerTasks,
                    style: type.secondary.copyWith(color: colors.inkSecondary),
                  ),
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
        final stop = ClayButton.filled(
          w.stopTimer,
          key: const ValueKey('today-action-first'),
          icon: const Icon(LucideIcons.square),
          onPressed: c.stopTimer,
        );
        final change = ClayButton(
          w.switchTask,
          key: const ValueKey('today-action-last'),
          icon: const Icon(LucideIcons.arrowLeftRight),
          onPressed: choices.isEmpty ? null : pick,
        );
        final buttons = active
            ? StintPair(
                first: stop,
                second: change,
                spacing: ClaySpacing.medium,
                runSpacing: ClaySpacing.small,
              )
            : ClayButton.filled(
                w.startTimer,
                icon: const Icon(LucideIcons.play),
                onPressed: choices.isEmpty ? null : pick,
              );
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ClaySpacing.regular,
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
    Widget stat(String key, String label, String value, ClayTint tint) =>
        ClaySurface(
          key: ValueKey('today-stat-$key'),
          face: ClayFace.raised(
            colors,
            color: colors.tint(tint),
            radius: ClayRadius.large,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: ClaySpacing.regular,
              vertical: ClaySpacing.medium,
            ),
            child: Semantics(
              label: '$label, $value',
              excludeSemantics: true,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: ClaySpacing.tight,
                children: [
                  Text(
                    label,
                    style: type.caption.copyWith(
                      color: colors.onColor(colors.tint(tint)),
                    ),
                  ),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      value,
                      style: type.title.copyWith(
                        color: colors.onColor(colors.tint(tint)),
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
        final chart = _ClayWeek(
          words: w,
          daily: daily,
          narrow: width < 260,
          pastel: _pastelOf(c.settings.presetOf(ClayThemeData.presets)),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ClaySpacing.regular,
          children: [
            Table(
              defaultVerticalAlignment:
                  TableCellVerticalAlignment.intrinsicHeight,
              columnWidths: const {1: FixedColumnWidth(ClaySpacing.medium)},
              children: [
                TableRow(
                  children: [
                    stat('tasks', w.openTasks, count, ClayTint.sky),
                    const SizedBox.shrink(),
                    stat('hours', w.hoursThisWeek, hours, ClayTint.mint),
                  ],
                ),
              ],
            ),
            if (box.hasBoundedHeight)
              Expanded(child: chart)
            else
              SizedBox(
                height:
                    132 * MediaQuery.textScalerOf(ctx).scale(1).clamp(1, 1.5),
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
    final colors = theme.colors;
    return ClayListTile(
      key: ValueKey('plan-${task.id}'),
      title: w.text(task.title),
      subtitle: detail,
      checked: task.done,
      semanticLabel: '${w.text(task.title)}, $detail',
      showChevron: false,
      onTap: () => c.changeTasks([task.id], done: !task.done),
      style: task.done
          ? ClayStyle(
              textStyle: WidgetStatePropertyAll(
                TextStyle(
                  decoration: TextDecoration.lineThrough,
                  color: colors.inkSecondary,
                ),
              ),
            )
          : tracking
          ? ClayStyle(foreground: WidgetStatePropertyAll(colors.accentInk))
          : null,
      leading: ExcludeSemantics(
        child: ClayCheckMark(
          key: ValueKey('today-plan-lead-${task.id}'),
          value: task.done,
          states: const {},
        ),
      ),
    );
  }

  Widget _block(TimeEntry entry, int index) => ClayListTile(
    leading: SizedBox.square(
      key: ValueKey('today-blocks-lead-$index'),
      dimension: 14,
      child: ClaySurface(
        face: ClayFace.raised(
          theme.colors,
          color: theme.colors.tint(_tints[index % _tints.length]),
          radius: 7,
        ),
      ),
    ),
    title: w.text(entry.note),
    subtitle: '${w.timeRange(entry)}$_metaSep${c.projectName(entry.project)}',
  );
}

/// The pastels Clay paints its people and blocks in, in turn.
const _tints = [
  ClayTint.peach,
  ClayTint.sky,
  ClayTint.mint,
  ClayTint.butter,
  ClayTint.lilac,
];

/// A Today section: Clay's slab of rows under its heading, drawn as
/// [ClayGroup] draws it, so a pair can stand its two slabs at one height.
class _Section extends StatelessWidget {
  const _Section({super.key, required this.header, required this.rows});
  final String header;
  final List<Widget> rows;

  /// The slab alone, keyed as the section, for a pair under its own headings.
  Widget slab(BuildContext context) {
    final theme = context.clayTheme;
    final first = rows.firstOrNull;
    final indent = first is ClayListTile && first.leading != null
        ? ClayListTile.leadingExtent
        : ClaySpacing.roomy;
    return ClaySurface(
      key: key,
      face: ClayFace.raised(theme.colors, radius: ClayRadius.large),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, row) in rows.indexed) ...[
            if (i > 0) ClayGroove(indent: indent, endIndent: ClaySpacing.roomy),
            row,
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      ClayGroup(header: header, children: rows);
}

/// The week's hours as clay: each day a well with its hours raised in it,
/// today's in coral.
class _ClayWeek extends StatelessWidget {
  const _ClayWeek({
    required this.words,
    required this.daily,
    required this.narrow,
    required this.pastel,
  });
  final StintWords words;
  final List<int> daily;

  /// The pastel the past days rise in: the palette's own.
  final ClayTint pastel;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final colors = theme.colors, week = mondayOf(studyToday);
    final maximum = daily.fold(480, (a, b) => a > b ? a : b);
    final scale = ((maximum + 479) ~/ 480) * 480;
    return ClaySurface(
      key: const ValueKey('today-chart'),
      face: ClayFace.raised(colors, radius: ClayRadius.large),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ClaySpacing.regular,
          ClaySpacing.medium,
          ClaySpacing.regular,
          ClaySpacing.medium,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: ClaySpacing.tight,
          children: [
            Text(
              words.duration(scale),
              style: theme.textTheme.caption.copyWith(
                color: colors.inkSecondary,
              ),
            ),
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
                          spacing: ClaySpacing.tight + 2,
                          children: [
                            Expanded(
                              child: _DayTrack(
                                key: ValueKey('today-day-slot-$i'),
                                share: minutes / scale,
                                today: addDays(week, i) == studyToday,
                                pastel: pastel,
                              ),
                            ),
                            Text(
                              narrow
                                  ? words.weekdayNarrow(addDays(week, i))
                                  : words.weekdayShort(addDays(week, i)),
                              key: ValueKey('today-day-label-$i'),
                              style: theme.textTheme.caption.copyWith(
                                color: addDays(week, i) == studyToday
                                    ? colors.ink
                                    : colors.inkSecondary,
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
      ),
    );
  }
}

/// One day's track: a soft well, and the day's hours raised in it from the
/// floor. A day with no hours leaves the well empty.
class _DayTrack extends StatelessWidget {
  const _DayTrack({
    super.key,
    required this.share,
    required this.today,
    required this.pastel,
  });
  final double share;
  final bool today;
  final ClayTint pastel;

  @override
  Widget build(BuildContext context) {
    final colors = context.clayTheme.colors;
    return Center(
      child: SizedBox(
        width: 16,
        child: LayoutBuilder(
          builder: (_, box) => ClaySurface(
            face: ClayFace.well(colors, radius: 8),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: share <= 0
                  ? const SizedBox(width: 16)
                  : SizedBox(
                      width: 16,
                      height: (box.maxHeight * share).clamp(16, box.maxHeight),
                      child: ClaySurface(
                        face: ClayFace.raised(
                          colors,
                          color: today ? colors.accent : colors.tint(pastel),
                          radius: 8,
                        ).copyWith(shadowOpacity: 0),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A result in the task chooser: its words, and under the keys or the
/// pointer the breath of a well, with the Enter glyph at its end.
class _ChooserRow extends StatelessWidget {
  const _ChooserRow({
    required this.label,
    required this.active,
    required this.pressed,
    required this.arabic,
  });
  final String label;
  final bool active, pressed, arabic;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final colors = theme.colors;
    final face = ClayFace.flat(
      colors,
      color: active || pressed ? clayChosenFill(colors) : colors.well,
      radius: ClayRadius.control - ClaySpacing.tight,
    ).copyWith(elevation: active ? 0.25 : 0, shadowOpacity: 0);
    return AnimatedClaySurface(
      face: face,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ClaySpacing.medium,
          vertical: ClaySpacing.small,
        ),
        child: Row(
          spacing: ClaySpacing.small,
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.body.copyWith(color: colors.ink),
              ),
            ),
            if (active)
              Icon(
                arabic
                    ? LucideIcons.cornerDownRight
                    : LucideIcons.cornerDownLeft,
                size: 16,
                color: colors.accentInk,
              ),
          ],
        ),
      ),
    );
  }
}

/// The pastel a Clay palette is moulded from: Clay's own clay and peach are
/// peach, lavender is the lilac pastel, the rest bear their pastel's name.
ClayTint _pastelOf(String preset) => switch (preset) {
  'mint' => ClayTint.mint,
  'sky' => ClayTint.sky,
  'butter' => ClayTint.butter,
  'lavender' => ClayTint.lilac,
  _ => ClayTint.peach,
};
