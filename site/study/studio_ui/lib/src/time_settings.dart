part of '../stint_studio.dart';

extension _TimeConsole on _WorkspaceState {
  Widget weekSwitch() {
    final full = w.weekRange(c.week),
        compact = w.weekRange(c.week, compact: true);
    return Row(
      spacing: 6,
      children: [
        StudioTransportKey(
          icon: const Icon(LucideIcons.chevronLeftDir),
          tooltip: w.previousWeek,
          size: 48,
          onPressed: () => c.shiftWeek(-1),
        ),
        Expanded(
          child: Semantics(
            label: full,
            child: ExcludeSemantics(
              child: LayoutBuilder(
                builder: (ctx, b) {
                  final style = rack.textTheme.title.copyWith(
                    color: rack.colors.onDisplay,
                  );
                  final width = TextPainter.computeWidth(
                    text: TextSpan(text: full, style: style),
                    textDirection: Directionality.of(ctx),
                    textScaler: MediaQuery.textScalerOf(ctx),
                  );
                  return Text(
                    width <= b.maxWidth
                        ? full
                        : compact.replaceFirst(' – ', ' –\n'),
                    textAlign: TextAlign.center,
                    style: style,
                  );
                },
              ),
            ),
          ),
        ),
        StudioTransportKey(
          icon: const Icon(LucideIcons.chevronRightDir),
          tooltip: w.nextWeek,
          size: 48,
          onPressed: () => c.shiftWeek(1),
        ),
      ],
    );
  }

  Widget time() {
    final week = c.week,
        daily = c.dailyMinutes(c.week),
        entries = c.entriesFor(c.week),
        days = List.generate(7, (i) => addDays(week, i));
    final deck = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        StudioDisplay(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              weekSwitch(),
              const StudioGroove(),
              _Reading(
                label: w.weekTotal,
                value: w.duration(c.totalMinutes(week)),
              ),
            ],
          ),
        ),
        LayoutBuilder(
          builder: (ctx, b) {
            final short =
                b.maxWidth / MediaQuery.textScalerOf(ctx).scale(1) < 290;
            final read = [
              w.logged,
              for (var i = 0; i < 7; i++)
                '${w.weekday(days[i])} ${w.duration(daily[i])}',
            ].join(', ');
            return Semantics(
              label: read,
              child: ExcludeSemantics(
                // The week reads on the rack's own meters in every language:
                // Studio's chart paints no Arabic glyphs yet, so Arabic had
                // the meters and English a gridded web chart (with a 0.0 to
                // 1.0 axis over an empty week): two instruments for one week.
                child: _DailyMeters(
                  words: w,
                  days: days,
                  minutes: daily,
                  short: short,
                ),
              ),
            );
          },
        ),
        StudioButton.lit(
          w.addEntry,
          icon: const Icon(LucideIcons.plus),
          onPressed: addTime,
        ),
      ],
    );
    final log = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 15,
      children: [
        // The status view is a pane of glass of its own: one pane, not one
        // set in a display.
        if (entries.isEmpty)
          StudioStatusView(
            title: w.noEntries,
            icon: const Icon(LucideIcons.clock3),
          )
        else
          for (final d in days.reversed)
            if (entries.any((e) => e.date == d))
              _ConsoleGroup(
                header: '${w.weekday(d)}${w.dot}${w.shortDate(d)}',
                dividerIndent: 0,
                children: [
                  for (final e in entries.where((e) => e.date == d))
                    StudioListTile(
                      title: w.text(e.note),
                      subtitle:
                          '${w.clock(e.start)}–${w.clock(e.end)}${w.dot}${c.projectName(e.project)}',
                      trailingText: w.duration(e.end - e.start),
                      showChevron: false,
                    ),
                ],
              ),
      ],
    );
    return station(
      w.time,
      data(
        () => LayoutBuilder(
          builder: (_, b) => b.maxWidth >= 740
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 24,
                  children: [
                    Expanded(flex: 5, child: deck),
                    Expanded(flex: 6, child: log),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 18,
                  children: [deck, log],
                ),
        ),
      ),
    );
  }

  Future<void> addTime() async {
    final saved = await formSheet<bool>(
      title: w.addEntry,
      builder: (_) => _TimeEntry(c),
    );
    if (mounted && saved == true) showStudioToast(context, w.entrySaved);
  }

  Future<void> signOut() async {
    final confirmed = await showStudioDialog<bool>(
      context: context,
      isAlert: true,
      builder: (ctx) => StudioDialog(
        title: w.signOutMessage,
        actions: [
          StudioButton.text(
            w.cancel,
            onPressed: () => Navigator.pop(ctx, false),
          ),
          StudioButton(
            w.signOut,
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );
    if (mounted && confirmed == true) c.signIn(false);
  }

  Widget settings() {
    final s = c.settings;
    final prefs = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 12,
      children: [
        _ConsoleHeader(w.preferences),
        StudioSelect(
          labelText: w.appearance,
          value: s.appearance,
          items: [
            for (final a in Appearance.values)
              StudioSelectItem(value: a, label: w.appearanceName(a)),
          ],
          onChanged: (v) => s.update(() => s.appearance = v),
        ),
        StudioSelect<double>(
          labelText: w.textSize,
          value: s.scale ?? 0,
          items: [
            StudioSelectItem(value: 0, label: w.system),
            for (final v in [1.0, 1.5, 2.0])
              StudioSelectItem(value: v, label: w.percent(v)),
          ],
          onChanged: (v) => s.update(() => s.scale = v == 0 ? null : v),
        ),
        StudioSelect(
          labelText: w.languageLabel,
          value: s.language,
          items: [
            for (final l in StintLanguage.values)
              StudioSelectItem(value: l, label: l.nativeName),
          ],
          onChanged: (v) => s.update(() => s.language = v),
        ),
        StudioSelect<StudioDensity>(
          labelText: w.density,
          value: rack.density,
          items: [
            StudioSelectItem(value: StudioDensity.standard, label: w.standard),
            StudioSelectItem(
              value: StudioDensity.comfortable,
              label: w.comfortable,
            ),
            StudioSelectItem(value: StudioDensity.compact, label: w.compact),
          ],
          onChanged: widget.chooseDensity,
        ),
      ],
    );
    final account = _ConsoleGroup(
      header: w.account,
      children: [
        StudioListTile(
          title: c.personName('maya'),
          subtitle: w.teamName,
          leading: StudioAvatar(name: c.personName('maya'), size: 36),
        ),
        StudioListTile(
          title: w.signOut,
          leading: const Icon(LucideIcons.logOutDir),
          isDestructiveAction: true,
          showChevron: false,
          onTap: signOut,
        ),
      ],
    );
    final about = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ConsoleHeader(w.about),
        StudioDisplay(
          child: Text(
            w.aboutDetail,
            style: rack.textTheme.body.copyWith(color: rack.colors.onDisplay),
          ),
        ),
      ],
    );
    return station(
      w.settings,
      LayoutBuilder(
        builder: (_, room) => room.maxWidth >= 720
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: [
                  Expanded(flex: 6, child: prefs),
                  Expanded(
                    flex: 5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 20,
                      children: [account, about],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 16,
                children: [account, prefs, about],
              ),
      ),
    );
  }
}

/// Seven level meters on the signal glass, with scalable, localized dial markings.
class _TimeEntry extends StatefulWidget {
  const _TimeEntry(this.c);
  final StintController c;
  @override
  State<_TimeEntry> createState() => _TimeEntryState();
}

class _TimeEntryState extends State<_TimeEntry> {
  late final d = EntryDraft(
    widget.c.week == mondayOf(studyToday) ? studyToday : widget.c.week,
  );
  @override
  void dispose() {
    d.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: d,
    builder: (ctx, _) {
      final c = widget.c,
          w = c.words,
          e = d.submitted ? d.errors(w) : const <String, String>{};
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 10,
        children: [
          if (w.arabic || MediaQuery.textScalerOf(ctx).scale(1) > 1)
            StudioFormField(
              labelText: w.date,
              mergeSemantics: false,
              child: StudioListTile(
                leading: const Icon(LucideIcons.calendarDays),
                title: RawWidgetsLocalizations.of(ctx).formatFullDate(d.date),
                semanticLabel:
                    '${w.date}, ${RawWidgetsLocalizations.of(ctx).formatFullDate(d.date)}',
                onTap: () async {
                  final day = await _pickDay(ctx, w.date, d.date);
                  if (mounted && day != null) {
                    d.update(() => d.date = calendarDay(day));
                  }
                },
              ),
            )
          else
            StudioDatePicker(
              labelText: w.date,
              value: d.date,
              firstDate: DateTime(2020),
              lastDate: DateTime(2040, 12, 31),
              currentDate: studyToday,
              onChanged: (day) => d.update(() => d.date = calendarDay(day)),
            ),
          StudioDisplay(
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ClockSetting(
                  words: w,
                  label: w.start,
                  minute: d.start,
                  onChanged: (n) => d.update(() => d.start = n),
                ),
                const StudioGroove(),
                StudioFormField(
                  errorText: e['end'],
                  mergeSemantics: false,
                  child: _ClockSetting(
                    words: w,
                    label: w.end,
                    minute: d.end,
                    onChanged: (n) => d.update(() => d.end = n),
                  ),
                ),
              ],
            ),
          ),
          StudioSelect(
            labelText: w.project,
            value: d.project,
            items: [
              for (final p in projects)
                StudioSelectItem(value: p.id, label: w.text(p.name)),
            ],
            onChanged: (p) => d.update(() => d.project = p),
          ),
          StudioTextField(
            labelText: w.note,
            hintText: w.noteHint,
            minLines: 2,
            maxLines: 4,
            errorText: e['note'],
            onChanged: (v) => d.update(() => d.note = v),
          ),
          StudioButton.lit(
            w.addEntry,
            onPressed: () {
              if (c.addEntry(d)) Navigator.pop(ctx, true);
            },
          ),
        ],
      );
    },
  );
}

class _DailyMeters extends StatelessWidget {
  const _DailyMeters({
    required this.words,
    required this.days,
    required this.minutes,
    required this.short,
  });
  final StintWords words;
  final List<DateTime> days;
  final List<int> minutes;
  final bool short;
  @override
  Widget build(BuildContext context) {
    final t = StudioTheme.of(context);
    final label = t.textTheme.caption.copyWith(color: t.colors.onReadout);
    // A working day's eight hours full scale, as Today's meters read the
    // same week (scaled to its peak, Thursday's 4h was full here and half
    // there, and an empty week ran 0h to 1h).
    final peak = minutes.fold<int>(480, (p, v) => v > p ? v : p);
    final ceiling = ((peak + 479) ~/ 480) * 480;
    Widget each(Widget Function(int i) cell, {CrossAxisAlignment? align}) =>
        Row(
          crossAxisAlignment: align ?? CrossAxisAlignment.center,
          children: [for (var i = 0; i < 7; i++) Expanded(child: cell(i))],
        );
    // The figures and days grow with the reader's text to 1.3 times, as the
    // looks' own chart labels do, and stand in rows of their own, so the
    // meters start on one line however a figure wraps.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: StudioDisplay(
        readout: true,
        padding: const EdgeInsets.all(10),
        child: LayoutBuilder(
          builder: (ctx, box) {
            // One form for the week: each day in full where every one fits
            // its column on one line, else all as h:mm; the
            // caption names the hours either way.
            final readings = WeekReadings.fit(
              ctx,
              words: words,
              minutes: minutes,
              style: label,
              slot: box.maxWidth / 7 - 2,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 6,
              children: [
                Text(
                  '${words.logged}${words.dot}${words.duration(0)}–${words.duration(ceiling)}',
                  style: label,
                ),
                each(
                  (i) => Text(
                    readings.labels[i],
                    style: label,
                    textAlign: TextAlign.center,
                    softWrap: false,
                    maxLines: 1,
                  ),
                  align: CrossAxisAlignment.end,
                ),
                each(
                  (i) => Center(
                    child: SizedBox(
                      height: 102,
                      child: StudioMeter(
                        axis: Axis.vertical,
                        thickness: 20,
                        level: minutes[i] / ceiling,
                        clip: 1,
                        segments: 20,
                      ),
                    ),
                  ),
                ),
                each(
                  (i) => Text(
                    short
                        ? words.weekdayShort(days[i]).substring(0, 1)
                        : words.weekdayShort(days[i]),
                    style: label,
                    textAlign: TextAlign.center,
                  ),
                  align: CrossAxisAlignment.start,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
