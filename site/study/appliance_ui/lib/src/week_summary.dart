part of '../stint_appliance.dart';

Size _labelSize(
  BuildContext context,
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: text,
      style: DefaultTextStyle.of(context).style.merge(style),
    ),
    textDirection: Directionality.of(context),
    locale: Localizations.maybeLocaleOf(context),
    textScaler: MediaQuery.textScalerOf(context),
  )..layout(maxWidth: maxWidth);
  final size = painter.size;
  painter.dispose();
  return size;
}

class _WeekSummary extends StatelessWidget {
  const _WeekSummary({
    required this.words,
    required this.tasks,
    required this.minutes,
    required this.daily,
  });
  final StintWords words;
  final int tasks, minutes;
  final List<int> daily;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (_, box) => ListenableBuilder(
      // A newly loaded fallback font changes the widths of labels and time units.
      listenable: PaintingBinding.instance.systemFonts,
      builder: (context, _) => _layout(context, box),
    ),
  );

  Widget _layout(BuildContext context, BoxConstraints box) {
    final theme = ApplianceTheme.of(context);
    final valueStyle = theme.textTheme.display.copyWith(
      color: theme.colors.onDisplay,
    );
    final hours = words.duration(minutes);
    const gap = 10.0;
    final tileWidth = (box.maxWidth - gap) / 2;
    final inset = tileWidth >= 150 ? 16.0 : 10.0;
    final room = tileWidth - 2 * inset;
    final count = words.number(tasks);
    final legend = theme.textTheme.legend.copyWith(
      color: theme.colors.onDisplay,
    );
    final labelHeight = [words.openTasks, words.hoursThisWeek]
        .map((s) => _labelSize(context, s, legend, maxWidth: room).height)
        .reduce((a, b) => a > b ? a : b);
    // Hours and minutes can occupy two lines. A number and its unit stay
    // together, including Arabic's nonbreaking space.
    final widestPart = [count, ...hours.split(' ')]
        .map((s) => _labelSize(context, s, valueStyle).width.ceilToDouble())
        .reduce((a, b) => a > b ? a : b);
    final valueWidth = room > widestPart ? room : widestPart;
    Widget tile(String id, String label, String value) {
      return ApplianceSurface(
        key: ValueKey('today-stat-$id'),
        face: ApplianceFace.well(theme.colors, fill: theme.colors.display),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: inset, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              ExcludeSemantics(
                child: SizedBox(
                  height: labelHeight,
                  child: Text(label, style: legend),
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                  width: valueWidth,
                  child: Text(
                    value,
                    style: valueStyle,
                    semanticsLabel: '$label, $value',
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final chart = _DayChart(words: words, daily: daily);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: gap,
      children: [
        Table(
          defaultVerticalAlignment: TableCellVerticalAlignment.fill,
          columnWidths: const {1: FixedColumnWidth(gap)},
          children: [
            TableRow(
              children: [
                tile('tasks', words.openTasks, count),
                const SizedBox(),
                TableCell(
                  verticalAlignment: TableCellVerticalAlignment.top,
                  child: tile('hours', words.hoursThisWeek, hours),
                ),
              ],
            ),
          ],
        ),
        if (box.hasBoundedHeight)
          Expanded(child: chart)
        else
          SizedBox(
            height: 108 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
            child: chart,
          ),
      ],
    );
  }
}

/// A seven-position LCD scale. Bars, rest marks and legends use the chart's
/// band centres, including when its reading direction changes.
/// Every k-th of [ticks], from the first, so their labels stand at least
/// [gap] apart: a short plot (the stopped timer's row) counts every other
/// hour, not six labels a line apart.
List<(T, double)> _spaced<T>(List<(T, double)> ticks, double gap) {
  if (ticks.length < 3) return ticks;
  final apart = (ticks[1].$2 - ticks[0].$2).abs();
  final every = apart <= 0 ? 1 : (gap / apart).ceil().clamp(1, ticks.length);
  return [
    for (var i = 0; i < ticks.length; i++)
      if (i % every == 0) ticks[i],
  ];
}

class _DayChart extends StatelessWidget {
  const _DayChart({required this.words, required this.daily});
  final StintWords words;
  final List<int> daily;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    // A short plot (the stopped timer's row) counts its hours in two steps,
    // not five a line apart.
    builder: (context, box) =>
        _chart(context, !box.hasBoundedHeight || box.maxHeight >= 100 ? 4 : 2),
  );

  Widget _chart(BuildContext context, int count) {
    final theme = ApplianceTheme.of(context);
    final colors = theme.colors;
    final ink = colors.onDisplay;
    // The bar's colour is the package chart's (Time's): on the day's pale
    // LCD the signal's nearest tone that stands 3:1 there, the signal itself
    // on the night's glass.
    final trace = colors.display.computeLuminance() > 0.4
        ? RawPalette.readableTone(colors.signal, on: [colors.display], ratio: 3)
        : colors.signal;
    final axis = theme.textTheme.legend.copyWith(
      color: ink.withValues(alpha: .78),
    );
    final week = mondayOf(studyToday);
    final days = [for (var i = 0; i < daily.length; i++) addDays(week, i)];
    final labels = days.map(words.weekdayShort).toList();
    final widestLabel = labels
        .map((s) => _labelSize(context, s, axis).width)
        .reduce((a, b) => a > b ? a : b);
    final line = _labelSize(context, words.number(0), axis).height;
    final peak = daily.fold(0, (a, b) => a > b ? a : b);
    String duration(double value) => words.duration((value * 60).round());
    final yScale = RawLinearScale.nice(
      min: 0,
      max: peak / 60,
      start: 0,
      end: 1,
      tickCount: count,
      includeZero: true,
    );
    final gutter =
        yScale
            .ticks(RawWidgetsLocalizations.of(context), count: count)
            .map(
              (tick) => _labelSize(context, duration(tick.value), axis).width,
            )
            .reduce((a, b) => a > b ? a : b) +
        8;
    return RawChart(
      semanticLabel: words.hoursThisWeek,
      xAxis: RawChartXAxis.band,
      categories: days.map(words.weekday).toList(),
      series: [
        RawChartSeries(
          label: words.logged,
          points: [
            for (final (i, n) in daily.indexed)
              RawChartPoint(i.toDouble(), n / 60),
          ],
        ),
      ],
      tickCount: count,
      padding: EdgeInsetsDirectional.fromSTEB(
        12 + gutter,
        10 + line / 2,
        12,
        12 + line,
      ),
      formatX: (x) => words.weekday(days[x.round()]),
      formatY: duration,
      builder: (context, chart) {
        final plot = chart.plotArea;
        final step = (chart.x as RawBandScale).step.abs();
        final selected = chart.active?.index;
        final rtl = Directionality.of(context) == TextDirection.rtl;
        final focused = chart.states.contains(WidgetState.focused);
        final readoutAtStart =
            selected != null &&
            (chart.x.map(selected.toDouble()) > plot.center.dx) != rtl;
        final face = ApplianceFace.well(colors, fill: colors.display);
        // An empty week has no scale to read: the chart's own runs from -1h
        // to 1h round zero. It shows the zero line alone, on the floor where
        // the idle bars stand.
        final ticks = peak == 0
            ? [
                for (final tick in chart.yTicks)
                  if (tick.value == 0) (tick, plot.bottom),
              ]
            : _spaced([
                for (final tick in chart.yTicks) (tick, tick.position),
              ], line * 1.6);
        return ApplianceSurface(
          key: const ValueKey('today-chart'),
          face: focused ? face.copyWith(focus: colors.focus) : face,
          child: Stack(
            children: [
              // An idle week says so over its floor, as Time's window does.
              if (peak == 0)
                Positioned(
                  left: plot.left,
                  width: plot.width,
                  top: plot.top,
                  height: plot.height,
                  child: Center(
                    child: Text(
                      words.noEntries,
                      style: axis,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              for (final (tick, at) in ticks) ...[
                Positioned(
                  left: plot.left,
                  width: plot.width,
                  top: at - .5,
                  height: 1,
                  child: ColoredBox(color: ink.withValues(alpha: .14)),
                ),
                PositionedDirectional(
                  start: 4,
                  width: 12 + gutter - 10,
                  top: at - line / 2,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Text(tick.label, style: axis, softWrap: false),
                  ),
                ),
              ],
              for (final (i, point) in chart.series.single.points.indexed) ...[
                Positioned(
                  left: chart.x.map(point.x) - step * .34,
                  width: step * .68,
                  bottom: chart.size.height - plot.bottom,
                  height: daily[i] == 0
                      ? 2
                      : (plot.bottom - chart.y.map(point.y!)).clamp(
                          1.0,
                          plot.height,
                        ),
                  child: DecoratedBox(
                    key: ValueKey('today-day-slot-$i'),
                    decoration: BoxDecoration(
                      color: daily[i] == 0
                          ? ink.withValues(alpha: .32)
                          : trace.withValues(
                              alpha: selected == null || selected == i
                                  ? 1
                                  : .48,
                            ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(2),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: chart.x.map(point.x) - step / 2,
                  width: step,
                  bottom: 6,
                  child: Center(
                    child: Text(
                      widestLabel + 8 <= step
                          ? labels[i]
                          : words.weekdayNarrow(days[i]),
                      key: ValueKey('today-day-label-$i'),
                      style: axis,
                      maxLines: 1,
                    ),
                  ),
                ),
              ],
              if (selected != null)
                PositionedDirectional(
                  start: readoutAtStart ? 12 + gutter : null,
                  end: readoutAtStart ? null : 12,
                  top: 5,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.display,
                      border: Border.all(color: colors.seamShade),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Text(
                        '${words.weekday(days[selected])}${words.dot}${words.duration(daily[selected])}',
                        style: theme.textTheme.secondary.copyWith(color: ink),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
