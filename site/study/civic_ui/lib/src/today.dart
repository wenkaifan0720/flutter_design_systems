part of '../stint_civic.dart';

extension _TodayService on _ServiceState {
  // Shape an Arabic title and its spaces in the same bundled face.
  TextStyle _rowTitle([TextDecoration? decoration]) => TextStyle(
    fontFamily: w.arabic ? 'NotoSansArabic' : null,
    package: w.arabic ? civicFontPackage : null,
    decoration: decoration,
  );

  Widget overview() {
    final width = MediaQuery.sizeOf(context).width;
    final end = CivicLayout.isApp(width)
        ? 0.0
        : CivicLayout.frameInset(width) - CivicLayout.marginFor(width);
    return Padding(
      padding: EdgeInsetsDirectional.only(end: end),
      child: CivicPageBody(
        caption:
            '${w.today}${w.dot}${w.weekday(studyToday)} ${w.shortDate(studyToday)}',
        title: w.greeting,
        maxWidth: CivicLayout.maxContentWidth,
        children: [
          load(
            () => LayoutBuilder(
              builder: (ctx, box) {
                final effective =
                    box.maxWidth / MediaQuery.textScalerOf(ctx).scale(1);
                final wide = effective >= 480;
                final tasks = c.todayTasks,
                    blocks = c.todayBlocks,
                    later = c.laterThisWeek;
                Widget rowLead(String group, Object id, Widget mark) =>
                    SizedBox(
                      width: CivicMetrics.box,
                      child: Center(
                        child: ExcludeSemantics(
                          child: KeyedSubtree(
                            key: ValueKey('today-$group-lead-$id'),
                            child: mark,
                          ),
                        ),
                      ),
                    );
                // The row's disclosure arrow uses the reader's text scaler.
                // Keep the arrow secondary at large type and give the words
                // the full setting, so long task names keep their measure.
                final wordScale = MediaQuery.textScalerOf(ctx);
                Widget linkRow(
                  Widget leading,
                  String title,
                  String? detail,
                  VoidCallback open, {
                  bool textLink = false,
                }) => MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.25,
                  child: CivicListRow(
                    leading: leading,
                    title: Text(
                      title,
                      textScaler: wordScale,
                      style: _rowTitle(
                        textLink ? TextDecoration.underline : null,
                      ),
                    ),
                    subtitle: detail == null
                        ? null
                        : Text(detail, textScaler: wordScale),
                    // A linked title is a link: the action's blue.
                    style: textLink
                        ? CivicStyle(
                            foreground: WidgetStatePropertyAll(
                              ctx.civicTheme.action,
                            ),
                          )
                        : null,
                    showChevron: !textLink,
                    onTap: open,
                  ),
                );
                final plan = <Widget>[
                  if (tasks.isEmpty)
                    CivicListRow(
                      title: Text(w.noTasks),
                      subtitle: Text(w.noTasksToday),
                    ),
                  for (final task in tasks) _planOption(task),
                  linkRow(
                    rowLead('plan', 'all', const Icon(LucideIcons.listChecks)),
                    w.viewTasks,
                    tasks.isEmpty
                        ? null
                        : w.progress(
                            tasks.where((t) => t.done).length,
                            tasks.length,
                          ),
                    () => enter(Place.tasks),
                    textLink: !CivicLayout.isApp(width),
                  ),
                ];
                final people = <Widget>[
                  for (final person in team)
                    CivicListRow(
                      leading: rowLead(
                        'team',
                        person.id,
                        CivicAvatar(name: w.text(person.name), size: 36),
                      ),
                      title: Text(w.text(person.name), style: _rowTitle()),
                      subtitle: Text(switch (c.currentTask(person.id)) {
                        final task? => w.text(task.title),
                        null => w.notTracking,
                      }),
                    ),
                ];
                if (wide && tasks.length + 1 == team.length) {
                  final colWidth = (box.maxWidth - 24) / 2;
                  for (final (i, member) in team.indexed) {
                    final task = i < tasks.length ? tasks[i] : null;
                    final teammateTask = c.currentTask(member.id);
                    final personHeight = _registerHeight(
                      colWidth,
                      w.text(member.name),
                      teammateTask == null
                          ? w.notTracking
                          : w.text(teammateTask.title),
                    );
                    final taskHeight = _registerHeight(
                      colWidth,
                      task == null ? w.viewTasks : w.text(task.title),
                      task == null
                          ? w.progress(
                              tasks.where((t) => t.done).length,
                              tasks.length,
                            )
                          : c.projectName(task.project),
                      opens: task == null && CivicLayout.isApp(width),
                      marked: task != null && c.data.timer?.taskId == task.id,
                    );
                    final size = BoxConstraints(
                      minHeight: personHeight > taskHeight
                          ? personHeight
                          : taskHeight,
                    );
                    plan[i] = ConstrainedBox(constraints: size, child: plan[i]);
                    people[i] = ConstrainedBox(
                      constraints: size,
                      child: people[i],
                    );
                  }
                }
                final times = _section(w.timeBlocks, [
                  if (blocks.isEmpty) CivicListRow(title: Text(w.noBlocks)),
                  for (final (i, entry) in blocks.indexed)
                    CivicListRow(
                      leading: rowLead(
                        'blocks',
                        i,
                        const Icon(LucideIcons.clock3),
                      ),
                      title: Text(w.timeRange(entry)),
                      subtitle: Text(
                        '${w.text(entry.note)}\n${c.projectName(entry.project)}',
                      ),
                    ),
                ], scope: w.teamName);
                final upcoming = _section(w.laterThisWeek, [
                  if (later.isEmpty) CivicListRow(title: Text(w.allClear)),
                  for (final task in later)
                    linkRow(
                      rowLead(
                        'later',
                        task.id,
                        const Icon(LucideIcons.calendarDays),
                      ),
                      w.text(task.title),
                      '${w.weekday(task.due)}${w.dot}${_whole(c.projectName(task.project))}',
                      () => record(task),
                      // The site (from 1024) links its titles; the app's
                      // rows keep their chevrons and plain titles.
                      textLink: !CivicLayout.isApp(width),
                    ),
                ]);
                final feed = StreamBuilder<DateTime>(
                  stream: c.ticks(const Duration(minutes: 1)),
                  initialData: c.repository.now(),
                  builder: (_, snapshot) => _section(w.recentActivity, [
                    if (c.data.activity.isEmpty)
                      CivicListRow(title: Text(w.noActivity)),
                    for (final (i, event) in c.data.activity.indexed)
                      CivicListRow(
                        leading: rowLead(
                          'feed',
                          i,
                          Icon(switch (event.kind) {
                            ActivityKind.logged => LucideIcons.clock3,
                            ActivityKind.commented => LucideIcons.messageCircle,
                            ActivityKind.finished => LucideIcons.circleCheck,
                            ActivityKind.started => LucideIcons.play,
                          }),
                        ),
                        title: Text(
                          w.eventAction(event, c.personName(event.person)),
                        ),
                        subtitle: Text(
                          '${w.text(event.subject)}\n${w.timeAgo(event.at, snapshot.data!)}',
                        ),
                      ),
                  ]),
                );
                Widget sections(List<Widget> items) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 24,
                  children: items,
                );
                return sections([
                  CivicCard(
                    key: const ValueKey('today-timer-card'),
                    child: LayoutBuilder(
                      builder: (ctx, room) {
                        final timer = _timeRecord(
                          room.maxWidth /
                              MediaQuery.textScalerOf(ctx).scale(1) /
                              (wide ? 2 : 1),
                        );
                        final summary = _weeklyRecord();
                        return wide
                            ? _CivicColumns(
                                start: timer,
                                end: summary,
                                gutter: 24,
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                spacing: 24,
                                children: [timer, summary],
                              );
                      },
                    ),
                  ),
                  if (wide) ...[
                    _CivicColumns(
                      start: _section(w.todaysPlan, plan),
                      end: _section(w.teamActivity, people),
                      gutter: 24,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 24,
                      children: [
                        Expanded(child: sections([times, upcoming])),
                        Expanded(child: feed),
                      ],
                    ),
                  ] else ...[
                    _section(w.todaysPlan, plan),
                    times,
                    _section(w.teamActivity, people),
                    feed,
                    upcoming,
                  ],
                ]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String name, List<Widget> rows, {String? scope}) => Column(
    key: name == w.todaysPlan ? const ValueKey('today-plan') : null,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      CivicSectionHeader(
        title: name,
        action: scope == null
            ? null
            : Text(scope, style: context.civicText.bodySmall),
      ),
      CivicListGroup(children: rows),
    ],
  );

  // Keep the two native lists in reading order. Give corresponding rows
  // the same minimum height, including the actual wrapping of both labels.
  double _registerHeight(
    double width,
    String title,
    String detail, {
    bool opens = false,
    bool marked = false,
  }) {
    final text = context.civicText, scaler = MediaQuery.textScalerOf(context);
    final wordsWidth =
        width -
        2 * CivicSpacing.s16 -
        CivicMetrics.box -
        CivicSpacing.s12 -
        (opens
            ? scaler.clamp(maxScaleFactor: 1.25).scale(24) + CivicSpacing.s12
            : 0);
    Size measure(String value, TextStyle style, [double beside = 0]) {
      final painter = TextPainter(
        text: TextSpan(text: value, style: style),
        textDirection: Directionality.of(context),
        locale: Localizations.localeOf(context),
        textScaler: scaler,
      )..layout(maxWidth: wordsWidth - beside);
      final size = painter.size;
      painter.dispose();
      return size;
    }

    final titleStyle = text.label.merge(_rowTitle());
    if (!marked) {
      return (measure(title, titleStyle).height +
                  CivicSpacing.s4 +
                  measure(detail, text.bodySmall).height)
              .clamp(CivicMetrics.controlHeight, double.infinity) +
          2 * CivicSpacing.s16;
    }
    // The running task's tag stands as CivicListRow stands a status: beside
    // the words on a row at least 440 wide (at the body's size) where it takes
    // at most 0.4 of the row and the title and meta line each keep one line
    // beside it; otherwise on its own line under the title, 8 round it.
    final tag = _runningTagSize();
    final room = wordsWidth - tag.width - CivicSpacing.s12;
    bool oneLine(String value, TextStyle style) =>
        measure(value, style, wordsWidth - room).height <=
        measure('M', style).height;
    final stacks =
        wordsWidth / (scaler.scale(16) / 16) < 440 ||
        tag.width > wordsWidth * 0.4 ||
        !oneLine(title, titleStyle) ||
        !oneLine(detail, text.bodySmall);
    final words = stacks
        ? measure(title, titleStyle).height +
              CivicSpacing.s8 +
              tag.height +
              CivicSpacing.s8 +
              measure(detail, text.bodySmall).height
        : measure(title, titleStyle, wordsWidth - room).height +
              CivicSpacing.s4 +
              measure(detail, text.bodySmall, wordsWidth - room).height;
    return words.clamp(CivicMetrics.controlHeight, double.infinity) +
        2 * CivicSpacing.s16;
  }

  /// The size of the plan's running-timer tag, as CivicTag pads its words.
  Size _runningTagSize() {
    final painter = TextPainter(
      text: TextSpan(
        text: w.runningTimer,
        style: context.civicText.bodySmall.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.25,
        ),
      ),
      textDirection: Directionality.of(context),
      locale: Localizations.localeOf(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final size = painter.size;
    painter.dispose();
    return Size(
      size.width + 2 * CivicSpacing.s8,
      size.height + 2 * CivicSpacing.s4,
    );
  }

  Widget _planOption(Task task) {
    void toggle() => c.changeTasks([task.id], done: !task.done);
    final title = Text(
      w.text(task.title),
      style: _rowTitle(
        task.done ? TextDecoration.lineThrough : TextDecoration.none,
      ),
    );
    // The wording and the native checkbox activate the same option. The
    // checkbox owns keyboard focus and the whole row has one checked state.
    // The row says that state, the checkbox's focus and takes the tap itself:
    // a CivicListRow keeps its leading out of the row's semantics, the
    // checkbox with it.
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      child: Builder(
        builder: (context) => MergeSemantics(
          key: ValueKey('plan-${task.id}'),
          child: Semantics(
            checked: task.done,
            focusable: true,
            focused: Focus.of(context).hasFocus,
            onTap: toggle,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: toggle,
              excludeFromSemantics: true,
              child: CivicListRow(
                leading: SizedBox(
                  width: CivicMetrics.box,
                  child: CivicCheckbox(
                    key: ValueKey('today-plan-lead-${task.id}'),
                    value: task.done,
                    onChanged: (_) => toggle(),
                  ),
                ),
                title: title,
                subtitle: Text(c.projectName(task.project)),
                // The task the timer runs on says so in words, as Civic says a
                // status: a tag at the row's end, as a task list marks the step
                // in progress.
                trailing: c.data.timer?.taskId == task.id
                    ? CivicTag(
                        key: const ValueKey('today-plan-running'),
                        label: w.runningTimer,
                        tone: CivicTone.info,
                      )
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _timeRecord(double measure) {
    final t = context.civicTheme, text = context.civicText;
    final timer = c.data.timer, task = c.currentTask('maya');
    final active = task != null && timer != null;
    final lastEntry = c.data.activity.firstOrNull;
    final saved =
        !active &&
            lastEntry != null &&
            lastEntry.person == 'maya' &&
            lastEntry.kind == ActivityKind.logged
        ? lastEntry
        : null;
    final choices = c.openTasks
        .where((item) => item.id != timer?.taskId)
        .toList();
    final label = active ? w.switchTask : w.startTimer;
    Future<void> pick() async {
      Widget list(BuildContext dialog) => RawCommandPalette(
        semanticLabel: label,
        commands: [
          for (final item in choices)
            RawCommand(
              label: w.text(item.title),
              group: c.projectName(item.project),
              data: item.id,
            ),
        ],
        onSelected: (command) => Navigator.pop(dialog, command.data! as String),
        fieldBuilder: (_, field) => CivicTextField(
          labelText: w.search,
          helperText: active
              ? w.timeSavedBeforeSwitch(w.text(task.title))
              : null,
          controller: field.controller,
          focusNode: field.focusNode,
          onEditingComplete: field.submit,
        ),
        groupBuilder: (_, group) => Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(group, style: text.label),
        ),
        itemBuilder: (_, command, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: states.contains(WidgetState.focused)
                ? t.secondaryFill
                : t.background,
            border: BorderDirectional(
              start: BorderSide(
                color: states.contains(WidgetState.focused)
                    ? t.action
                    : t.background,
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              spacing: 12,
              children: [
                Expanded(child: Text(command.label, style: text.body)),
                Icon(
                  LucideIcons.play,
                  size: 16,
                  color: t.action,
                  semanticLabel: w.startTimer,
                ),
              ],
            ),
          ),
        ),
        emptyBuilder: (_) => Text(w.noMatches, style: text.body),
      );
      // On a phone a sheet from the foot; from 600 px a dialog in the middle
      // of the window, as Move and Filters are.
      final selected = MediaQuery.sizeOf(context).width < 600
          ? await showCivicBottomSheet<String>(
              context: context,
              title: label,
              builder: list,
            )
          : await showCivicDialog<String>(
              context: context,
              builder: (dialog) => CivicDialog(
                title: label,
                content: list(dialog),
                actions: [
                  CivicButton.secondary(
                    onPressed: () => Navigator.pop(dialog),
                    child: Text(w.cancel),
                  ),
                ],
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
            style: text.headingL.copyWith(
              fontSize: 36,
              height: 1.12,
              fontFeatures: const [FontFeature.tabularFigures()],
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
            builder: (_, snapshot) => digits(snapshot.data!),
          );
    // At night both the action blue and the focus yellow are light. Carry
    // the button's blue edge around the resting face. Civic's focus flood
    // then replaces that edge as well as the seat beneath the label.
    final primarySide = t.isDark
        ? WidgetStatePropertyAll(BorderSide(color: t.actionEdge, width: 2))
        : null;
    final switchAction = CivicButton.secondary(
      key: const ValueKey('today-action-last'),
      style: const CivicStyle(
        padding: WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
      expand: true,
      onPressed: choices.isEmpty ? null : pick,
      child: Text(label),
    );
    final stop = CivicButton(
      key: const ValueKey('today-action-first'),
      style: CivicStyle(
        side: primarySide,
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        ),
      ),
      expand: true,
      onPressed: c.stopTimer,
      child: Text(w.stopTimer),
    );
    final well = ColoredBox(
      key: const ValueKey('today-timer-well'),
      color: t.surface,
      child: CivicInset(
        style: CivicStyle(
          edge: WidgetStatePropertyAll(active ? t.action : t.rule),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: _TimerNotice(
            taskId: timer?.taskId,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 4,
              children: [
                Text(
                  active ? w.runningTimer : w.stoppedTimer,
                  style: text.label.copyWith(
                    color: active ? t.action : t.textSecondary,
                  ),
                ),
                clock,
                Text(
                  active
                      ? w.text(task.title)
                      : saved == null
                      ? w.chooseTask
                      : w.text(saved.subject),
                  key: const ValueKey('today-timer-title'),
                  style: text.headingS,
                ),
                if (active)
                  Text(
                    '${_whole(c.projectName(task.project))}${w.dot}${w.since(timer.start)}',
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  )
                else if (saved != null)
                  Text(
                    '${w.entrySaved}${w.dot}${c.personName(saved.person)}',
                    style: text.bodySmall.copyWith(color: t.textSecondary),
                  ),
                if (!active && choices.isEmpty)
                  Text(w.noTimerTasks, style: text.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
    // Beside the week's figures the row sets the height: the well takes what
    // the row leaves, so the gap above the actions stays 16. The row first
    // measures the record unbounded, where the well keeps its own height
    // (flex 0). One parent either way, so the ticking clock is never rebuilt
    // onto a stream it already holds.
    return LayoutBuilder(
      builder: (_, room) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          Expanded(flex: room.hasBoundedHeight ? 1 : 0, child: well),
          if (!active)
            CivicButton(
              style: CivicStyle(side: primarySide),
              expand: true,
              onPressed: choices.isEmpty ? null : pick,
              child: Text(label),
            )
          else
            // Side by side while each key's words fit its half on one line.
            StintPair(first: stop, second: switchAction),
        ],
      ),
    );
  }

  Widget _weeklyRecord() {
    final t = context.civicTheme, text = context.civicText;
    final monday = mondayOf(studyToday), minutes = c.dailyMinutes(monday);
    final peak = minutes.fold(0, (a, b) => a > b ? a : b);
    final days = [for (var i = 0; i < 7; i++) addDays(monday, i)];
    Widget figure(String id, String caption, String value, Place page) =>
        DecoratedBox(
          key: ValueKey('today-stat-$id'),
          decoration: BoxDecoration(
            color: t.surface,
            border: Border(top: BorderSide(color: t.rule, width: 2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              spacing: 4,
              children: [
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: CivicLink(
                    onPressed: () => enter(page),
                    semanticLabel: '$caption, $value',
                    textStyle: text.bodySmall.copyWith(color: t.action),
                    child: Text(caption),
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  // One line when the pair measures the row, as when it is
                  // laid out: a wrapped measure left a taller tile.
                  child: Text(value, style: text.headingM, softWrap: false),
                ),
              ],
            ),
          ),
        );
    return LayoutBuilder(
      builder: (ctx, room) {
        final short =
            room.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 268;
        final bars = Row(
          children: [
            for (final (i, date) in days.indexed)
              Expanded(
                child: CivicTooltip(
                  message:
                      '${w.weekday(date)}${w.dot}${w.duration(minutes[i])}',
                  excludeFromSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: 4,
                    children: [
                      Expanded(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border(bottom: BorderSide(color: t.rule)),
                          ),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: FractionallySizedBox(
                              widthFactor: .52,
                              heightFactor: minutes[i] > 0
                                  ? minutes[i] / peak
                                  : null,
                              child: ColoredBox(
                                key: ValueKey('today-day-slot-$i'),
                                color: minutes[i] == 0
                                    ? t.textSecondary
                                    : t.action,
                                child: SizedBox(
                                  height: minutes[i] == 0 ? 2 : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          short ? w.weekdayNarrow(date) : w.weekdayShort(date),
                          key: ValueKey('today-day-label-$i'),
                          style: text.bodySmall.copyWith(
                            color: t.textSecondary,
                          ),
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
                    : '${w.logged}\u00a0·\u00a0${w.duration(0)}\u2060–\u2060${w.duration(peak)}',
                style: text.bodySmall.copyWith(color: t.textSecondary),
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
        final chart = Semantics(
          image: true,
          excludeSemantics: true,
          label: [
            w.hoursThisWeek,
            for (final (i, date) in days.indexed)
              '${w.weekday(date)} ${w.duration(minutes[i])}',
          ].join(', '),
          child: ColoredBox(
            key: const ValueKey('today-chart'),
            color: t.surface,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: body,
            ),
          ),
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          spacing: 16,
          children: [
            if (room.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 210)
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 8,
                children: [
                  figure(
                    'tasks',
                    w.openTasks,
                    w.number(c.openTasks.length),
                    Place.tasks,
                  ),
                  figure(
                    'hours',
                    w.hoursThisWeek,
                    w.duration(c.totalMinutes(monday)),
                    Place.time,
                  ),
                ],
              )
            else
              _CivicColumns(
                start: figure(
                  'tasks',
                  w.openTasks,
                  w.number(c.openTasks.length),
                  Place.tasks,
                ),
                end: figure(
                  'hours',
                  w.hoursThisWeek,
                  w.duration(c.totalMinutes(monday)),
                  Place.time,
                ),
                gutter: 8,
              ),
            if (room.hasBoundedHeight) Expanded(child: chart) else chart,
          ],
        );
      },
    );
  }
}

class _CivicColumns extends StatelessWidget {
  const _CivicColumns({
    required this.start,
    required this.end,
    required this.gutter,
  });
  final Widget start, end;
  final double gutter;
  @override
  Widget build(BuildContext context) => Table(
    columnWidths: {1: FixedColumnWidth(gutter)},
    defaultVerticalAlignment: TableCellVerticalAlignment.intrinsicHeight,
    children: [
      TableRow(children: [start, const SizedBox.shrink(), end]),
    ],
  );
}

/// Civic lets the wording settle on its inset rule after a change of task.
/// Ordinary clock ticks leave the ink at rest.
class _TimerNotice extends StatefulWidget {
  const _TimerNotice({required this.taskId, required this.child});
  final String? taskId;
  final Widget child;
  @override
  State<_TimerNotice> createState() => _TimerNoticeState();
}

class _TimerNoticeState extends State<_TimerNotice>
    with SingleTickerProviderStateMixin {
  late final ink = AnimationController(vsync: this, value: 1);
  @override
  void didUpdateWidget(_TimerNotice old) {
    super.didUpdateWidget(old);
    if (old.taskId == widget.taskId || rawReduceMotionOf(context)) return;
    ink.value = .55;
    ink.springTo(
      1,
      rawSpring(
        dampingRatio: CivicMotion.state.dampingRatio,
        stiffness: CivicMotion.state.stiffness,
      ),
    );
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

/// A short name or time kept on one line: a meta line breaks at the dots
/// between its phrases, never inside "Field guide" or "15m ago".
String _whole(String phrase) => phrase.replaceAll(' ', '\u00a0');
