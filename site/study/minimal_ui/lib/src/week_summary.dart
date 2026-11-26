part of '../stint_minimal.dart';

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.words,
    required this.tasks,
    required this.minutes,
    required this.daily,
    required this.openTasks,
    required this.openTime,
  });
  final StintWords words;
  final int tasks, minutes;
  final List<int> daily;
  final VoidCallback openTasks, openTime;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final room = box.maxWidth / MediaQuery.textScalerOf(context).scale(1);
      final hours = words.duration(minutes);
      final compact = room < 380;
      final stack = room < 230;
      final tiles = [
        MinimalStat(
          key: const ValueKey('today-stat-tasks'),
          label: words.openTasks,
          value: words.number(tasks),
          large: !compact,
          icon: LucideIcons.listChecks,
          onPressed: openTasks,
        ),
        MinimalStat(
          key: const ValueKey('today-stat-hours'),
          label: words.hoursThisWeek,
          value: hours,
          large: !compact,
          icon: LucideIcons.clock3,
          onPressed: openTime,
        ),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          if (stack)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: 8,
              children: tiles,
            )
          else
            Table(
              defaultVerticalAlignment: TableCellVerticalAlignment.fill,
              columnWidths: const {1: FixedColumnWidth(8)},
              children: [
                TableRow(
                  children: [
                    tiles.first,
                    const SizedBox(),
                    // The localized duration can wrap as fallback fonts arrive.
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.top,
                      child: tiles.last,
                    ),
                  ],
                ),
              ],
            ),
          _WeekPlot(words: words, daily: daily, narrow: room < 340),
        ],
      );
    },
  );
}

class _WeekPlot extends StatelessWidget {
  const _WeekPlot({
    required this.words,
    required this.daily,
    required this.narrow,
  });
  final StintWords words;
  final List<int> daily;
  final bool narrow;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final style = t.mono.copyWith(color: t.mutedForeground);
    final peak = daily.fold(0, (a, b) => a > b ? a : b);
    final top = peak == 0 ? 60 : ((peak + 59) ~/ 60) * 60;
    final height = 44.0 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final days = [
      for (var i = 0; i < daily.length; i++) addDays(mondayOf(studyToday), i),
    ];
    // An idle week has no line to draw: a 0 to 1h scale under a flat line
    // in the accent read as a stray underline. It says so, as Time does.
    if (peak == 0) {
      return MinimalCard(
        key: const ValueKey('today-chart'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: SizedBox(
          height: height,
          child: Center(
            child: Text(
              words.noEntries,
              style: t.caption.copyWith(color: t.mutedForeground),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    // Future, unlogged days have an axis position but no observation.
    final lastRecorded = daily.lastIndexWhere((n) => n > 0);
    final end = lastRecorded >= studyToday.weekday
        ? lastRecorded + 1
        : studyToday.weekday;
    return Semantics(
      image: true,
      excludeSemantics: true,
      label: [
        words.hoursThisWeek,
        for (final (i, day) in days.indexed)
          '${words.weekday(day)} ${words.duration(daily[i])}',
      ].join(', '),
      child: MinimalCard(
        key: const ValueKey('today-chart'),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            SizedBox(
              height: height,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(words.duration(top), style: style, softWrap: false),
                  Text(words.duration(0), style: style, softWrap: false),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 3,
                children: [
                  SizedBox(
                    height: height,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final step = box.maxWidth / daily.length;
                        final points = [
                          for (final (i, n) in daily.indexed)
                            Offset(
                              step * ((rtl ? daily.length - 1 - i : i) + .5),
                              height - 3 - (height - 6) * n / top,
                            ),
                        ];
                        return Stack(
                          fit: StackFit.expand,
                          children: [
                            CustomPaint(
                              painter: _WeekLine(
                                points.take(end).toList(),
                                t.primary,
                              ),
                            ),
                            for (final (i, point) in points.indexed)
                              Positioned(
                                left: point.dx - (daily[i] == 0 ? 4 : 2),
                                top: point.dy - (daily[i] == 0 ? .75 : 2),
                                width: daily[i] == 0 ? 8 : 4,
                                height: daily[i] == 0 ? 1.5 : 4,
                                child: DecoratedBox(
                                  key: ValueKey('today-day-slot-$i'),
                                  decoration: BoxDecoration(
                                    shape: daily[i] == 0
                                        ? BoxShape.rectangle
                                        : BoxShape.circle,
                                    color: daily[i] == 0
                                        ? t.mutedForeground
                                        : t.primary,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  Row(
                    children: [
                      for (final (i, day) in days.indexed)
                        Expanded(
                          child: Center(
                            child: Text(
                              narrow
                                  ? words.weekdayNarrow(day)
                                  : words.weekdayShort(day),
                              key: ValueKey('today-day-label-$i'),
                              style: style,
                            ),
                          ),
                        ),
                    ],
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

class _WeekLine extends CustomPainter {
  const _WeekLine(this.points, this.ink);
  final List<Offset> points;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Path()..addPolygon(points, false);
    final fill = Path.from(line)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();
    canvas.drawPath(fill, Paint()..color = ink.withValues(alpha: .1));
    canvas.drawPath(
      line,
      Paint()
        ..color = ink
        ..strokeWidth = MinimalSparkline.stroke
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_WeekLine old) => old.points != points || old.ink != ink;
}
