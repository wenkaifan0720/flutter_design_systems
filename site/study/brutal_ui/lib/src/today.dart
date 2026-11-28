part of '../stint_brutal.dart';

extension _Today on _StudioState {
  // The hard keyboard shadow replaces ink on a raised key and paper on
  // a flat one. Give the orange enough contrast against both surfaces.
  Color _controlSignal(BrutalColors colors) => Color.lerp(
    colors.signal,
    colors.onSignal,
    colors.brightness == Brightness.dark ? .17 : .05,
  )!;

  Widget today() {
    final theme = context.brutalTheme;
    return BrutalScreen(
      topBar: bar(w.today),
      body: loaded(
        () => LayoutBuilder(
          builder: (ctx, space) {
            final scale = MediaQuery.textScalerOf(ctx).scale(1);
            final wide = space.maxWidth / scale >= 540;
            final plan = c.todayTasks;
            final week = mondayOf(studyToday);
            final roster = BrutalListGroup(
              header: w.teamActivity,
              children: [
                for (final person in team)
                  BrutalListTile(
                    leading: ExcludeSemantics(
                      child: MediaQuery.withClampedTextScaling(
                        maxScaleFactor: 1.15,
                        // The tile seats its leading in a 24 square, where
                        // the initials were 6 px specks and Arabic ones ran
                        // past the box: the face stands 32 over that seat,
                        // its words still on the list's line.
                        child: OverflowBox(
                          maxWidth: 32,
                          maxHeight: 32,
                          child: BrutalAvatar(
                            key: ValueKey('today-team-lead-${person.id}'),
                            name: w.text(person.name),
                            // The screen's one colour block is the timer:
                            // the people are white faces on the rule.
                            style: BrutalStyle(
                              fill: WidgetStatePropertyAll(
                                theme.colors.surface,
                              ),
                            ),
                            size: 32,
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
            final agenda = BrutalListGroup(
              key: const ValueKey('today-plan'),
              header: w.todaysPlan,
              children: [
                if (plan.isEmpty)
                  BrutalListTile(title: w.noTasks, subtitle: w.noTasksToday),
                for (final task in plan) _planTask(task),
                BrutalListTile(
                  leading: const Icon(
                    LucideIcons.listChecks,
                    key: ValueKey('today-plan-lead-all'),
                  ),
                  title: w.viewTasks,
                  subtitle: plan.isEmpty
                      ? null
                      : w.progress(
                          plan.where((t) => t.done).length,
                          plan.length,
                        ),
                  onTap: () => go(Place.tasks),
                ),
              ],
            );
            final blocks = BrutalListGroup(
              header: '${w.timeBlocks}${w.dot}${w.teamName}',
              children: [
                if (c.todayBlocks.isEmpty) BrutalListTile(title: w.noBlocks),
                for (final (i, block) in c.todayBlocks.indexed)
                  BrutalListTile(
                    leading: Icon(
                      LucideIcons.clock3,
                      key: ValueKey('today-blocks-lead-$i'),
                    ),
                    title: w.timeRange(block),
                    subtitle:
                        '${w.text(block.note)}${w.dot}${_whole(c.projectName(block.project))}',
                  ),
              ],
            );
            final later = BrutalListGroup(
              header: w.laterThisWeek,
              children: [
                if (c.laterThisWeek.isEmpty) BrutalListTile(title: w.allClear),
                for (final task in c.laterThisWeek)
                  BrutalListTile(
                    leading: Icon(
                      LucideIcons.calendarDays,
                      key: ValueKey('today-later-lead-${task.id}'),
                    ),
                    title: w.text(task.title),
                    subtitle:
                        '${w.weekday(task.due)}${w.dot}${_whole(c.projectName(task.project))}',
                    onTap: () => open(task),
                  ),
              ],
            );
            final feed = StreamBuilder<DateTime>(
              stream: c.ticks(const Duration(minutes: 1)),
              initialData: c.repository.now(),
              builder: (_, snapshot) => BrutalListGroup(
                header: w.recentActivity,
                children: [
                  if (c.data.activity.isEmpty)
                    BrutalListTile(title: w.noActivity),
                  for (final (i, event) in c.data.activity.indexed)
                    BrutalListTile(
                      leading: Icon(switch (event.kind) {
                        ActivityKind.finished => LucideIcons.check,
                        ActivityKind.started => LucideIcons.play,
                        ActivityKind.commented => LucideIcons.messageSquare,
                        ActivityKind.logged => LucideIcons.clock3,
                      }, key: ValueKey('today-feed-lead-$i')),
                      title: w.eventAction(event, c.personName(event.person)),
                      subtitle:
                          '${w.text(event.subject)}${w.dot}${_whole(w.timeAgo(event.at, snapshot.data!))}',
                    ),
                ],
              ),
            );
            Widget stack(List<Widget> sections) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 20,
              children: sections,
            );
            return stack([
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  Text(
                    '${w.weekday(studyToday)}${w.dot}${w.shortDate(studyToday)}'
                        .toUpperCase(),
                    style: theme.textTheme.caption,
                  ),
                  Semantics(
                    header: true,
                    child: Text(
                      w.greeting,
                      style: space.maxWidth / scale < 260
                          ? theme.textTheme.headline
                          : theme.textTheme.display,
                    ),
                  ),
                ],
              ),
              if (wide)
                _BrutalPair(
                  first: _trackingBlock(),
                  second: _weekFigures(week),
                  gap: 24,
                )
              else ...[
                _trackingBlock(),
                _weekFigures(week),
              ],
              if (wide) ...[
                _BrutalPair(first: agenda, second: roster, gap: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    Expanded(child: stack([blocks, later])),
                    Expanded(child: feed),
                  ],
                ),
              ] else ...[
                agenda,
                blocks,
                roster,
                feed,
                later,
              ],
            ]);
          },
        ),
      ),
    );
  }

  Widget _planTask(Task task) {
    final theme = context.brutalTheme, colors = theme.colors;
    final name = w.text(task.title), project = c.projectName(task.project);
    final running = c.data.timer?.taskId == task.id;
    return RawButton(
      key: ValueKey('plan-${task.id}'),
      checked: task.done,
      button: false,
      semanticLabel: [name, project, if (running) w.runningTimer].join(', '),
      excludeSemantics: true,
      onPressed: () => c.changeTasks([task.id], done: !task.done),
      builder: (_, states, _) {
        final depressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        final ticked = task.done != depressed;
        return BrutalListTile(
          title: name,
          subtitle: project,
          // The task the timer runs on says so at its end, as Brutal labels
          // a state: a tag set in paper on ink. On a phone with large text
          // it gives way to the title, never more than a third of the row.
          trailing: running
              ? ConstrainedBox(
                  key: const ValueKey('today-plan-running'),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.sizeOf(context).width / 3,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: BrutalTag(
                      w.runningTimer,
                      tone: BrutalTagTone.strong,
                    ),
                  ),
                )
              : null,
          style: BrutalStyle(
            textStyle: WidgetStatePropertyAll(
              TextStyle(
                decoration: task.done
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ),
          leading: AnimatedBrutalSurface(
            key: ValueKey('today-plan-lead-${task.id}'),
            face: BrutalFace(
              fill: ticked ? colors.ink : colors.surface,
              foreground: ticked ? colors.paper : colors.ink,
              border: colors.ink,
              shadow: focused || states.contains(WidgetState.hovered)
                  ? _controlSignal(colors)
                  : const Color(0x00000000),
              travel: depressed ? 1 : 0,
            ),
            child: Center(
              child: ticked
                  ? Icon(LucideIcons.check, size: 17, color: colors.paper)
                  : null,
            ),
          ),
        );
      },
    );
  }

  Widget _trackingBlock() {
    final theme = context.brutalTheme;
    final type = theme.textTheme,
        timer = c.data.timer,
        task = c.currentTask('maya');
    final active = timer != null && task != null;
    final ink = active ? theme.colors.onBlock : theme.colors.ink;
    final wellColor = active ? theme.colors.lead : theme.colors.surface;
    final lastEntry = c.data.activity.firstOrNull;
    final saved =
        !active &&
            lastEntry != null &&
            lastEntry.person == 'maya' &&
            lastEntry.kind == ActivityKind.logged
        ? lastEntry
        : null;
    final choices = c.openTasks.where((t) => t.id != timer?.taskId).toList();
    final label = active ? w.switchTask : w.startTimer;
    Future<void> pick() async {
      final selected = await _raise<String>(
        context,
        (dialog) => BrutalSheet(
          title: label,
          closeLabel: w.cancel,
          onClose: () => Navigator.pop(dialog),
          child: RawCommandPalette(
            semanticLabel: label,
            commands: [
              for (final item in choices)
                RawCommand(
                  label: w.text(item.title),
                  group: c.projectName(item.project),
                  data: item.id,
                ),
            ],
            onSelected: (command) =>
                Navigator.pop(dialog, command.data! as String),
            fieldBuilder: (_, field) => ListenableBuilder(
              listenable: field.focusNode,
              builder: (_, child) => AnimatedBrutalSurface(
                face: BrutalFace(
                  fill: theme.colors.surface,
                  border: theme.colors.ink,
                  borderWidth: 0,
                  foreground: theme.colors.ink,
                  shadow: field.focusNode.hasFocus
                      ? _controlSignal(theme.colors)
                      : const Color(0x00000000),
                ),
                child: child,
              ),
              // Keep the field's ink edge and let its focus fall down and to
              // the end, on the same hard shadow as the key that opened it.
              child: ClipRect(
                child: BrutalTextField(
                  controller: field.controller,
                  focusNode: field.focusNode,
                  hintText: w.search,
                  semanticLabel: w.search,
                  prefixIcon: const Icon(LucideIcons.search),
                  onEditingComplete: field.submit,
                ),
              ),
            ),
            groupBuilder: (_, group) => Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 4),
              child: Text(group.toUpperCase(), style: type.caption),
            ),
            itemBuilder: (_, command, states) {
              final highlighted = states.contains(WidgetState.focused);
              return BrutalMenuRow(
                label: command.label,
                icon: LucideIcons.play,
                states: {
                  ...states.difference(const {WidgetState.focused}),
                  if (highlighted) WidgetState.selected,
                },
                style: highlighted
                    ? BrutalStyle(
                        fill: WidgetStatePropertyAll(theme.colors.lead),
                      )
                    : null,
              );
            },
            emptyBuilder: (_) => Padding(
              padding: const EdgeInsets.all(12),
              child: Text(w.noMatches, style: type.secondary),
            ),
          ),
        ),
      );
      if (mounted && selected != null) c.track(selected);
    }

    Widget digits(DateTime now) {
      final value = saved == null
          ? w.elapsed(
              timer == null ? Duration.zero : now.difference(timer.start),
            )
          : w.duration(saved.minutes);
      return Semantics(
        identifier: 'stint-elapsed',
        label: saved == null
            ? w.elapsedLabel(value)
            : '${w.entrySaved}, $value',
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            value,
            key: const ValueKey('today-timer-digits'),
            textDirection: saved == null
                ? TextDirection.ltr
                : Directionality.of(context),
            style: type.display.copyWith(
              fontSize: 48,
              height: 1,
              color: ink,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      );
    }

    final status = Row(
      spacing: 8,
      children: [
        SizedBox.square(
          dimension: 12,
          child: AnimatedBrutalSurface(
            key: const ValueKey('today-timer-lamp'),
            face: BrutalFace(
              fill: active ? ink : wellColor,
              border: ink,
              foreground: ink,
            ),
          ),
        ),
        Expanded(
          child: Text(
            (active ? w.runningTimer : w.stoppedTimer).toUpperCase(),
            key: const ValueKey('today-timer-label'),
            style: type.caption.copyWith(color: ink),
          ),
        ),
      ],
    );
    final readout = timer == null
        ? digits(c.repository.now())
        : StreamBuilder<DateTime>(
            stream: c.ticks(const Duration(seconds: 1)),
            initialData: c.repository.now(),
            builder: (_, snapshot) => digits(snapshot.data!),
          );
    Widget key(
      String action,
      String text,
      VoidCallback? press, {
      required bool primary,
    }) => _raisedControl(
      action,
      text,
      press,
      signal: primary,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: theme.controlHeight - 2 * theme.borderWidth,
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Builder(
              builder: (ctx) => Text(
                text,
                textAlign: TextAlign.center,
                style: type.label.copyWith(
                  color: DefaultTextStyle.of(ctx).style.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final startOrSwitch = key(
      active ? 'action-last' : 'action-first',
      label,
      choices.isEmpty ? null : pick,
      primary: !active,
    );
    final stop = key('action-first', w.stopTimer, c.stopTimer, primary: true);
    return Column(
      key: const ValueKey('today-timer-card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      spacing: 16,
      children: [
        _shadowRoom(
          'timer-well',
          BrutalBlock(
            lead: true,
            color: wellColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                status,
                readout,
                Text(
                  active
                      ? w.text(task.title)
                      : saved == null
                      ? w.chooseTask
                      : w.text(saved.subject),
                  key: const ValueKey('today-timer-title'),
                  style: type.title.copyWith(color: ink),
                ),
                if (active)
                  Text(
                    '${_whole(c.projectName(task.project))}${w.dot}${w.since(timer.start)}',
                    style: type.secondary.copyWith(color: ink),
                  )
                else if (saved != null)
                  Text(
                    '${w.entrySaved}${w.dot}${c.personName(saved.person)}',
                    style: type.secondary.copyWith(color: ink),
                  ),
                if (!active && choices.isEmpty)
                  Text(
                    w.noTimerTasks,
                    style: type.secondary.copyWith(color: ink),
                  ),
              ],
            ),
          ),
        ),
        // Side by side while each key's words fit its half on one line.
        if (!active)
          startOrSwitch
        else
          StintPair(first: stop, second: startOrSwitch),
      ],
    );
  }

  // The square face paints its shadow outside its layout bounds. Count that
  // painted area when lining up the keys and figures with the flat chart.
  Widget _shadowRoom(String part, Widget child) {
    final offset = context.brutalTheme.shadowOffset;
    return Padding(
      key: ValueKey('today-$part'),
      padding: EdgeInsetsDirectional.only(end: offset, bottom: offset),
      child: child,
    );
  }

  Widget _raisedControl(
    String part,
    String name,
    VoidCallback? press, {
    required Widget child,
    bool signal = false,
  }) {
    final colors = context.brutalTheme.colors;
    final accent = _controlSignal(colors);
    return _shadowRoom(
      part,
      RawButton(
        onPressed: press,
        semanticLabel: name,
        excludeSemantics: true,
        builder: (context, states, _) {
          final disabled = states.contains(WidgetState.disabled);
          final focus = states.contains(WidgetState.focused);
          final hover = states.contains(WidgetState.hovered);
          // When the action itself is orange, move the signal from the face
          // to the hard focus shadow so its shape stays visible. The face is
          // the signal itself under its own words (onSignal holds 4.5:1 on
          // it); the eased signal is the focus and hover shadow's colour only:
          // by night it lightened a green face under white words to 3.71:1.
          final signalFace = signal && !focus;
          return AnimatedBrutalSurface(
            face: BrutalFace(
              fill: disabled
                  ? colors.surface
                  : signalFace
                  ? colors.signal
                  : colors.surface,
              foreground: disabled
                  ? colors.disabled
                  : signalFace
                  ? colors.onSignal
                  : colors.ink,
              border: disabled ? colors.disabled : colors.ink,
              shadow: disabled
                  ? const Color(0x00000000)
                  : focus
                  ? accent
                  : colors.ink,
              travel: states.contains(WidgetState.pressed)
                  ? 1
                  : hover && !focus
                  ? .5
                  : 0,
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _weekFigures(DateTime week) {
    final theme = context.brutalTheme, type = theme.textTheme;
    final data = c.dailyMinutes(week),
        peak = data.reduce((a, b) => a > b ? a : b);
    final ink = theme.colors.ink;
    final days = [for (var i = 0; i < 7; i++) addDays(week, i)];
    Widget tile(String id, String label, String value, Place place) =>
        _raisedControl(
          'stat-$id',
          '$label, $value',
          () => go(place),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 4,
              children: [
                Text(label.toUpperCase(), style: type.caption),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  // One line when the pair measures the row, as when it is
                  // laid out: a wrapped measure left a taller tile.
                  child: Text(value, style: type.headline, softWrap: false),
                ),
              ],
            ),
          ),
        );
    return LayoutBuilder(
      builder: (ctx, room) {
        final short =
            room.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 260;
        final bars = Row(
          children: [
            for (final (i, day) in days.indexed)
              Expanded(
                child: BrutalTooltip(
                  message: '${w.weekday(day)}${w.dot}${w.duration(data[i])}',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: FractionallySizedBox(
                            widthFactor: .72,
                            heightFactor: data[i] == 0 ? null : data[i] / peak,
                            child: ColoredBox(
                              key: ValueKey('today-day-slot-$i'),
                              color: data[i] == 0
                                  ? ink.withValues(alpha: .4)
                                  : ink,
                              child: SizedBox(height: data[i] == 0 ? 2 : null),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          short ? w.weekdayNarrow(day) : w.weekdayShort(day),
                          key: ValueKey('today-day-label-$i'),
                          style: type.caption.copyWith(color: ink),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
        final body = LayoutBuilder(
          builder: (ctx, area) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 4,
            children: [
              Text(
                peak == 0
                    ? w.noEntries
                    : '${w.logged.toUpperCase()}\u00a0·\u00a0${w.duration(0)}\u2060–\u2060${w.duration(peak)}',
                style: type.caption,
              ),
              if (area.hasBoundedHeight)
                Expanded(child: bars)
              else
                SizedBox(
                  height: 62 + MediaQuery.textScalerOf(ctx).scale(24),
                  child: bars,
                ),
            ],
          ),
        );
        final plot = Semantics(
          image: true,
          excludeSemantics: true,
          label: [
            w.logged,
            for (final (i, day) in days.indexed)
              '${w.weekday(day)} ${w.duration(data[i])}',
          ].join(', '),
          child: BrutalBlock(
            key: const ValueKey('today-chart'),
            // The tiles' inset, so the title starts on their captions' line.
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: body,
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 14,
          children: [
            if (room.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 210)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  tile(
                    'tasks',
                    w.openTasks,
                    w.number(c.openTasks.length),
                    Place.tasks,
                  ),
                  tile(
                    'hours',
                    w.hoursThisWeek,
                    w.duration(c.totalMinutes(week)),
                    Place.time,
                  ),
                ],
              )
            else
              _BrutalPair(
                first: tile(
                  'tasks',
                  w.openTasks,
                  w.number(c.openTasks.length),
                  Place.tasks,
                ),
                second: tile(
                  'hours',
                  w.hoursThisWeek,
                  w.duration(c.totalMinutes(week)),
                  Place.time,
                ),
                gap: 8,
              ),
            if (room.hasBoundedHeight) Expanded(child: plot) else plot,
          ],
        );
      },
    );
  }
}

/// Measure each face at its own width, then give both the height of this row.
class _BrutalPair extends StatelessWidget {
  const _BrutalPair({
    required this.first,
    required this.second,
    required this.gap,
  });
  final Widget first, second;
  final double gap;
  @override
  Widget build(BuildContext context) => Table(
    columnWidths: {1: FixedColumnWidth(gap)},
    defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
    children: [
      TableRow(children: [first, const SizedBox.shrink(), second]),
    ],
  );
}

/// A short name or time kept on one line: a meta line breaks at the dots
/// between its phrases, never inside "Field guide" or "15m ago".
String _whole(String phrase) => phrase.replaceAll(' ', '\u00a0');
