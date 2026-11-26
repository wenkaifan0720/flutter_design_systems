part of '../stint_cupertino.dart';

Color _secondaryInk(BuildContext context) =>
    CupertinoColors.secondaryLabel.resolveFrom(context).withValues(alpha: .8);

extension _Today on _Desk {
  Widget today() {
    final type = CupertinoTheme.of(context).textTheme;
    final muted = _secondaryInk(context);
    final accent = CupertinoTheme.of(context).primaryColor;
    final tasks = c.todayTasks, blocks = c.todayBlocks, later = c.laterThisWeek;
    final plan = _TodayGroup(
      w.todaysPlan,
      key: const ValueKey('today-plan'),
      detail: tasks.isEmpty
          ? null
          : w.progress(tasks.where((t) => t.done).length, tasks.length),
      rows: [
        if (tasks.isEmpty) _empty(w.noTasksToday),
        for (final task in tasks)
          _AgendaRow(
            key: ValueKey('plan-${task.id}'),
            leadKey: ValueKey('today-plan-lead-${task.id}'),
            leading: AnimatedSwitcher(
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 180),
              child: Icon(
                task.done
                    ? CupertinoIcons.check_mark_circled_solid
                    : CupertinoIcons.circle,
                key: ValueKey(task.done),
                color: task.done ? accent : muted,
                size: 26,
              ),
            ),
            title: w.text(task.title),
            subtitle: c.projectName(task.project),
            checked: task.done,
            trailing: c.data.timer?.taskId == task.id
                ? Icon(
                    CupertinoIcons.stopwatch,
                    key: const ValueKey('today-plan-running'),
                    color: CupertinoColors.systemOrange.resolveFrom(context),
                    semanticLabel: w.runningTimer,
                  )
                : null,
            onTap: () => c.changeTasks([task.id], done: !task.done),
          ),
        _AgendaRow(
          leadKey: const ValueKey('today-plan-lead-all'),
          leading: Icon(CupertinoIcons.list_bullet, color: accent),
          title: w.viewTasks,
          link: true,
          onTap: () => go(Place.tasks),
        ),
      ],
    );
    final times = _TodayGroup(
      w.timeBlocks,
      rows: [
        if (blocks.isEmpty) _empty(w.noBlocks),
        for (final (i, entry) in blocks.indexed)
          _AgendaRow(
            leadKey: ValueKey('today-blocks-lead-$i'),
            leading: Icon(CupertinoIcons.clock, color: muted),
            title: w.timeRange(entry),
            subtitle:
                '${w.text(entry.note)}${w.dot}${c.projectName(entry.project)}',
          ),
        _AgendaRow(
          leadKey: ValueKey('today-blocks-lead-${blocks.length}'),
          leading: Icon(CupertinoIcons.calendar, color: accent),
          title: w.seeTime,
          link: true,
          onTap: () => go(Place.time),
        ),
      ],
    );
    final upcoming = _TodayGroup(
      w.laterThisWeek,
      rows: [
        if (later.isEmpty) _empty(w.allClear),
        for (final task in later)
          _AgendaRow(
            leadKey: ValueKey('today-later-lead-${task.id}'),
            leading: Icon(CupertinoIcons.calendar, color: muted),
            title: w.text(task.title),
            subtitle:
                '${w.weekday(task.due)}${w.dot}${c.projectName(task.project)}',
            onTap: () => open(task),
          ),
      ],
    );
    final people = _TodayGroup(
      w.teamActivity,
      rows: [
        for (final person in team)
          _AgendaRow(
            leadKey: ValueKey('today-team-lead-${person.id}'),
            leading: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CupertinoColors.systemGrey5.resolveFrom(context),
              ),
              child: SizedBox.square(
                dimension: 32,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        w
                            .text(person.name)
                            .split(' ')
                            .map((s) => s.characters.first)
                            .join(),
                        style: type.textStyle.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            title: w.text(person.name),
            subtitle: switch (c.currentTask(person.id)) {
              final task? => w.text(task.title),
              null => w.notTracking,
            },
          ),
      ],
    );
    final feed = StreamBuilder<DateTime>(
      stream: c.ticks(const Duration(minutes: 1)),
      initialData: c.repository.now(),
      builder: (context, snapshot) => _TodayGroup(
        w.recentActivity,
        rows: [
          if (c.data.activity.isEmpty) _empty(w.noActivity),
          for (final (i, event) in c.data.activity.indexed)
            _AgendaRow(
              leadKey: ValueKey('today-feed-lead-$i'),
              leading: Icon(switch (event.kind) {
                ActivityKind.finished => CupertinoIcons.check_mark_circled,
                ActivityKind.started => CupertinoIcons.play_circle,
                ActivityKind.commented => CupertinoIcons.chat_bubble,
                ActivityKind.logged => CupertinoIcons.clock,
              }, color: muted),
              title: w.eventAction(event, c.personName(event.person)),
              subtitle:
                  '${w.text(event.subject)}${w.dot}${w.timeAgo(event.at, snapshot.data!).replaceAll(' ', '\u00a0')}',
            ),
        ],
      ),
    );
    Widget groups(List<Widget> items) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 20,
      children: items,
    );
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, size) {
        final inset = size.maxWidth < 800 ? 16.0 : 24.0;
        final width = size.maxWidth - inset * 2;
        final grid = width >= 555 * scale;
        return SizedBox.expand(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(inset, 16, inset, 24),
            child: groups([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(
                    '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}',
                    style: type.textStyle.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: w.arabic ? 1.35 : null,
                      color: muted,
                    ),
                  ),
                  Semantics(
                    container: true,
                    header: true,
                    child: Text(
                      w.greeting,
                      style: type.navLargeTitleTextStyle.copyWith(
                        fontSize: scale > 1.5 && !grid ? 24 : null,
                        height: w.arabic ? 1.35 : null,
                      ),
                    ),
                  ),
                ],
              ),
              _stopwatch(width, scale),
              if (grid) ...[
                // One height while the plan has rows; a day with nothing
                // due keeps its card to its two rows beside the team.
                Table(
                  columnWidths: const {1: FixedColumnWidth(20)},
                  defaultVerticalAlignment: tasks.isEmpty
                      ? TableCellVerticalAlignment.top
                      : TableCellVerticalAlignment.intrinsicHeight,
                  children: [
                    TableRow(children: [plan, const SizedBox.shrink(), people]),
                  ],
                ),
                Row(
                  spacing: 20,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: groups([times, upcoming])),
                    Expanded(child: feed),
                  ],
                ),
              ] else ...[
                plan,
                times,
                upcoming,
                people,
                feed,
              ],
            ]),
          ),
        );
      },
    );
  }

  Widget _empty(String message) =>
      Padding(padding: const EdgeInsets.all(16), child: Text(message));

  Future<void> _chooseTimer(bool running, List<Task> tasks) async {
    final id = await _present<String>(
      context,
      height: _Choices.height(tasks.length, prompt: true, subtitles: true),
      (ctx, scroll) => CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              Navigator.pop(ctx),
        },
        child: _Choices<String>(
          title: running ? w.switchTask : w.startTimer,
          prompt: w.search,
          empty: w.noMatches,
          scroll: scroll,
          values: {for (final task in tasks) task.id: w.text(task.title)},
          subtitles: {
            for (final task in tasks) task.id: c.projectName(task.project),
          },
        ),
      ),
    );
    if (mounted && id != null) c.track(id);
  }

  Widget _stopwatch(double width, double scale) {
    final theme = CupertinoTheme.of(context), type = theme.textTheme.textStyle;
    final muted = _secondaryInk(context);
    final timer = c.data.timer, task = c.currentTask('maya');
    final running = task != null && timer != null;
    final latest = c.data.activity.firstOrNull;
    final receipt =
        !running &&
            latest != null &&
            latest.person == 'maya' &&
            latest.kind == ActivityKind.logged
        ? latest
        : null;
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    final pick = choices.isEmpty ? null : () => _chooseTimer(running, choices);
    const inset = 16.0, gap = 20.0;
    final available = width - 2 * inset;
    final split = available >= 535 * scale;
    final columnWidth = split ? (available - gap) / 2 : available;
    final red = CupertinoColors.systemRed.resolveFrom(context);
    final light = CupertinoTheme.brightnessOf(context) == Brightness.light;
    Color tintedFace(Color hue) => Color.alphaBlend(
      hue.withValues(
        alpha: light
            ? kCupertinoButtonTintedOpacityLight
            : kCupertinoButtonTintedOpacityDark,
      ),
      CupertinoColors.secondarySystemGroupedBackground.resolveFrom(context),
    );
    Color tintedInk(CupertinoDynamicColor hue) => Color.lerp(
      light ? hue.highContrastColor : hue.darkHighContrastColor,
      CupertinoColors.label.resolveFrom(context),
      .30,
    )!;
    final stop = _TintedTimerButton(
      key: const ValueKey('today-action-first'),
      color: tintedFace(red),
      foregroundColor: tintedInk(CupertinoColors.systemRed),
      onPressed: c.stopTimer,
      label: w.stopTimer,
    );
    final change = running
        ? _TintedTimerButton(
            key: const ValueKey('today-action-last'),
            color: tintedFace(theme.primaryColor),
            foregroundColor: tintedInk(CupertinoColors.systemBlue),
            onPressed: pick,
            label: w.switchTask,
          )
        : _buttonFocus(
            CupertinoButton.filled(
              focusColor: theme.primaryColor,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              onPressed: pick,
              child: Text(w.startTimer),
            ),
          );
    final buttons = !running
        ? (choices.isEmpty
              ? Semantics(
                  button: true,
                  enabled: false,
                  label: w.startTimer,
                  excludeSemantics: true,
                  child: change,
                )
              : change)
        : columnWidth < 225 * scale
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
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
    Widget readout(DateTime now) {
      final value = w.elapsed(
        timer == null ? Duration.zero : now.difference(timer.start),
      );
      final saved = receipt == null ? null : w.duration(receipt.minutes);
      return Semantics(
        identifier: 'stint-elapsed',
        label: saved ?? w.elapsedLabel(value),
        excludeSemantics: true,
        child: FittedBox(
          alignment: AlignmentDirectional.centerStart,
          fit: BoxFit.scaleDown,
          child: Text(
            saved ?? value,
            key: const ValueKey('today-timer-digits'),
            textDirection: saved == null ? TextDirection.ltr : null,
            style: type.copyWith(
              fontSize: 46,
              height: 1.12,
              fontWeight: FontWeight.w300,
              letterSpacing: -1.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    final timerColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 12,
      children: [
        Container(
          key: const ValueKey('today-timer-well'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(
              context,
            ),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Row(
                spacing: 6,
                children: [
                  Transform.translate(
                    // The Arabic status line carries more ink above its baseline.
                    offset: Offset(0, w.arabic ? -2 : 0),
                    child: Icon(
                      CupertinoIcons.stopwatch,
                      key: const ValueKey('today-timer-lamp'),
                      color: running
                          ? CupertinoColors.systemOrange.resolveFrom(context)
                          : muted,
                      size: 20,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      running ? w.runningTimer : w.stoppedTimer,
                      key: const ValueKey('today-timer-label'),
                      style: type.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        height: w.arabic ? 1.35 : null,
                      ),
                    ),
                  ),
                ],
              ),
              if (timer == null)
                readout(c.repository.now())
              else
                StreamBuilder<DateTime>(
                  stream: c.ticks(const Duration(seconds: 1)),
                  initialData: c.repository.now(),
                  builder: (context, snapshot) => readout(snapshot.data!),
                ),
              AnimatedSwitcher(
                key: const ValueKey('today-timer-title'),
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                layoutBuilder: (current, previous) => Stack(
                  alignment: AlignmentDirectional.centerStart,
                  children: [...previous, ?current],
                ),
                child: Text(
                  running
                      ? w.text(task.title)
                      : receipt == null
                      ? w.chooseTask
                      : w.text(receipt.subject),
                  key: ValueKey(task?.id),
                  style: type.copyWith(
                    fontWeight: FontWeight.w600,
                    height: w.arabic ? 1.35 : null,
                  ),
                ),
              ),
              if (running)
                Text(
                  '${c.projectName(task.project)}${w.dot}${w.since(timer.start)}',
                  style: type.copyWith(
                    fontSize: 15,
                    color: muted,
                    height: w.arabic ? 1.35 : null,
                  ),
                )
              else if (receipt != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    w.eventAction(receipt, c.personName(receipt.person)),
                    style: type.copyWith(fontSize: 15, color: muted),
                  ),
                ),
              if (!running && choices.isEmpty)
                Text(
                  w.noTimerTasks,
                  style: type.copyWith(fontSize: 15, color: muted),
                ),
            ],
          ),
        ),
        buttons,
      ],
    );
    final week = mondayOf(studyToday);
    Widget reading(String label, String value, Place destination) =>
        MergeSemantics(
          child: Semantics(
            label: label,
            value: value,
            child: _buttonFocus(
              CupertinoButton(
                focusColor: muted,
                key: ValueKey(
                  destination == Place.tasks
                      ? 'today-stat-tasks'
                      : 'today-stat-hours',
                ),
                color: CupertinoColors.tertiarySystemGroupedBackground
                    .resolveFrom(context),
                borderRadius: BorderRadius.circular(9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                alignment: AlignmentDirectional.centerStart,
                onPressed: () => go(destination),
                child: ExcludeSemantics(
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
                          style: type.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: muted,
                            height: w.arabic ? 1.35 : null,
                          ),
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        spacing: 3,
                        children: [
                          Expanded(
                            child: FittedBox(
                              alignment: AlignmentDirectional.centerStart,
                              fit: BoxFit.scaleDown,
                              child: Text(
                                value,
                                maxLines: 1,
                                style: type.copyWith(
                                  fontSize: columnWidth < 340 ? 18 : 23,
                                  fontWeight: FontWeight.w600,
                                  height: w.arabic ? 1.35 : null,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Icon(
                            CupertinoIcons.right_chevron,
                            size: 16,
                            color: muted,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              radius: 9,
            ),
          ),
        );
    final chart = _ActivityChart(c, week, width: columnWidth);
    final weekColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        Table(
          columnWidths: const {1: FixedColumnWidth(8)},
          defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
          children: [
            TableRow(
              children: [
                reading(w.openTasks, w.number(c.openTasks.length), Place.tasks),
                const SizedBox.shrink(),
                reading(
                  w.hoursThisWeek,
                  w.duration(c.totalMinutes(week)),
                  Place.time,
                ),
              ],
            ),
          ],
        ),
        if (split)
          Expanded(child: chart)
        else
          SizedBox(height: 66 + 16 * scale, child: chart),
      ],
    );
    return CupertinoListSection.insetGrouped(
      key: const ValueKey('today-timer-card'),
      margin: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.all(inset),
          child: split
              ? IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: gap,
                    children: [
                      Expanded(child: timerColumn),
                      Expanded(child: weekColumn),
                    ],
                  ),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 16,
                  children: [timerColumn, weekColumn],
                ),
        ),
      ],
    );
  }
}

// Keep Cupertino's native focus shape while limiting its outside stroke to 2 px.
Widget _buttonFocus(Widget button, {double radius = 12}) =>
    ClipPath(clipper: _ButtonFocusClip(radius), child: button);

class _ButtonFocusClip extends CustomClipper<Path> {
  const _ButtonFocusClip(this.radius);
  final double radius;

  @override
  Path getClip(Size size) =>
      RoundedSuperellipseBorder(borderRadius: BorderRadius.circular(radius + 2))
          .getOuterPath((Offset.zero & size).inflate(2));

  @override
  bool shouldReclip(_ButtonFocusClip oldClipper) => radius != oldClipper.radius;
}

class _TintedTimerButton extends StatefulWidget {
  const _TintedTimerButton({
    super.key,
    required this.label,
    required this.color,
    required this.foregroundColor,
    required this.onPressed,
  });
  final String label;
  final Color color, foregroundColor;
  final VoidCallback? onPressed;

  @override
  State<_TintedTimerButton> createState() => _TintedTimerButtonState();
}

class _TintedTimerButtonState extends State<_TintedTimerButton> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    onEnter: (_) => setState(() => hovered = true),
    onExit: (_) => setState(() => hovered = false),
    child: _buttonFocus(
      CupertinoButton(
        focusColor: widget.foregroundColor,
        color: hovered && widget.onPressed != null
            ? Color.alphaBlend(
                widget.foregroundColor.withValues(alpha: .10),
                widget.color,
              )
            : widget.color,
        foregroundColor: widget.foregroundColor,
        pressedOpacity: .86,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        onPressed: widget.onPressed,
        child: Text(widget.label),
      ),
    ),
  );
}

class _ActivityChart extends StatelessWidget {
  const _ActivityChart(this.c, this.week, {required this.width});
  final StintController c;
  final DateTime week;
  final double width;
  @override
  Widget build(BuildContext context) {
    final w = c.words, values = c.dailyMinutes(week);
    final max = values.fold(0, (a, b) => a > b ? a : b);
    final axisMinutes = ((max + 59) ~/ 60) * 60;
    final muted = _secondaryInk(context);
    final accent = CupertinoTheme.of(context).primaryColor;
    final scaler = MediaQuery.textScalerOf(context);
    final labels = [
      for (var i = 0; i < values.length; i++)
        width < 240
            ? w.weekdayNarrow(addDays(week, i))
            : w.weekdayShort(addDays(week, i)),
    ];
    final labelStyle = CupertinoTheme.of(context).textTheme.textStyle
        .copyWith(fontSize: 12, color: muted);
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
      final slotWidth = (width - 12 - scaler.scale(30)) / values.length;
      final ratio = ((slotWidth - 5) / widest).clamp(.01, 1.0);
      labelScaler = TextScaler.linear(requestedSize * ratio / fontSize);
    }
    return Container(
      key: const ValueKey('today-chart'),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemGroupedBackground.resolveFrom(
          context,
        ),
        borderRadius: BorderRadius.circular(9),
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
                color: CupertinoColors.separator.resolveFrom(context),
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
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(fontSize: 12, color: muted),
                    ),
                  ),
                ),
              ),
              for (final (i, value) in values.indexed)
                Expanded(
                  child: Semantics(
                    container: true,
                    label: w.weekday(addDays(week, i)),
                    value: w.duration(value),
                    excludeSemantics: true,
                    child: Column(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: .46,
                              heightFactor: value == 0
                                  ? null
                                  : value / axisMinutes,
                              child: DecoratedBox(
                                key: ValueKey('today-day-slot-$i'),
                                decoration: BoxDecoration(
                                  color: value == 0
                                      ? CupertinoColors.systemGrey2.resolveFrom(
                                          context,
                                        )
                                      : accent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: SizedBox(
                                  height: value == 0 ? 2 : null,
                                  width: double.infinity,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
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

class _TodayGroup extends StatelessWidget {
  const _TodayGroup(this.title, {super.key, required this.rows, this.detail});
  final String title;
  final String? detail;
  final List<Widget> rows;
  @override
  Widget build(BuildContext context) {
    final type = CupertinoTheme.of(context).textTheme.textStyle;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            children: [
              Semantics(
                container: true,
                header: true,
                child: Text(
                  title,
                  style: type.copyWith(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (detail != null)
                Text(
                  detail!,
                  style: type.copyWith(
                    fontSize: 13,
                    color: _secondaryInk(context),
                  ),
                ),
            ],
          ),
        ),
        // Clip the whole inset-grouped surface at its native radius when
        // the paired table cell is taller than the rows inside it.
        Flexible(
          child: ClipRSuperellipse(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            clipBehavior: Clip.hardEdge,
            child: CupertinoListSection.insetGrouped(
              margin: EdgeInsets.zero,
              backgroundColor: CupertinoColors.secondarySystemGroupedBackground,
              clipBehavior: Clip.none,
              dividerMargin: 58,
              additionalDividerMargin: 0,
              children: rows,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgendaRow extends StatelessWidget {
  const _AgendaRow({
    super.key,
    required this.leadKey,
    required this.leading,
    required this.title,
    this.subtitle,
    this.link = false,
    this.checked,
    this.trailing,
    this.onTap,
  });
  final Key leadKey;
  final Widget leading;
  final String title;
  final String? subtitle;
  final bool link;
  final bool? checked;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);
    Widget lines(String value, {TextStyle? style}) => Builder(
      builder: (context) => DefaultTextStyle(
        style: DefaultTextStyle.of(context).style,
        child: Text(
          value,
          style: Directionality.of(context) == TextDirection.rtl
              ? (style ?? const TextStyle()).copyWith(height: 1.35)
              : style,
        ),
      ),
    );
    final tile = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 56),
      child: CupertinoListTile(
        leadingSize: 32,
        leadingToTitle: 12,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ExcludeSemantics(
          child: KeyedSubtree(key: leadKey, child: leading),
        ),
        title: lines(
          title,
          style: TextStyle(
            color: link
                ? theme.primaryColor
                : checked == true
                ? _secondaryInk(context)
                : null,
            decoration: checked == true ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: subtitle == null
            ? null
            : lines(
                subtitle!,
                style: TextStyle(fontSize: 14, color: _secondaryInk(context)),
              ),
        trailing:
            trailing ??
            (onTap != null && checked == null
                ? const CupertinoListTileChevron()
                : null),
      ),
    );
    if (onTap == null) return Semantics(container: true, child: tile);
    return MergeSemantics(
      child: Semantics(
        checked: checked,
        child: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: onTap,
          child: tile,
        ),
      ),
    );
  }
}
