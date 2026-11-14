/// Stats, progress, charts: stat tiles and their height-matched row, the
/// slim progress bar in every tone, the bars chart (static and readable
/// bar by bar) and the sparkline in its registers.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

// Morning run, August: minutes out the door per weekday this week, and the
// kept count per week of the month.
const List<String> _days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
const List<double> _minutes = [32, 28, 41, 0, 36, 54, 22];
const List<double> _keptByWeek = [4, 5, 6, 5, 7, 6, 6, 5];
const List<double> _pace = [6.4, 6.3, 6.5, 6.1, 6.0, 6.2, 5.9, 5.8, 5.9, 5.7];

/// A week of meditation, in minutes a day.
const List<double> _meditated = [10, 10, 12, 15, 12, 14, 14];

Widget kitStatsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Stats, progress, charts',
  sections: [
    kitSection(
      'Stat row',
      children: [
        const MinimalStatRow(
          children: [
            MinimalStat(
              label: 'Streak',
              value: '12d',
              delta: '3d',
              detail: 'best 21d',
              icon: LucideIcons.flame,
            ),
            MinimalStat(
              label: 'August',
              value: '23/28',
              detail: 'days kept',
              icon: LucideIcons.calendarCheck,
            ),
          ],
        ),
        kitNote(
          'Tiles in a row match heights even when one carries a delta and '
          'its neighbour does not.',
        ),
      ],
    ),
    kitSection(
      'Large figure, with a trend',
      children: const [
        MinimalStat(
          label: 'Kept this month',
          value: '82%',
          delta: '6%',
          detail: 'vs July',
          spark: [61, 64, 70, 68, 73, 77, 75, 82],
          large: true,
        ),
      ],
    ),
    kitSection(
      'Direction and goodness',
      children: [
        const MinimalStatRow(
          children: [
            MinimalStat(
              label: 'Missed',
              value: '5',
              delta: '2',
              deltaUp: false,
              deltaGood: true,
              detail: 'vs July',
            ),
            MinimalStat(
              label: 'Avg start',
              value: '07:18',
              delta: '9',
              deltaGood: false,
              detail: 'min later',
            ),
          ],
        ),
        kitNote(
          'The arrow says which way the number moved; the colour says '
          'whether that is good.',
        ),
      ],
    ),
    kitSection('Tappable tile', children: const [_RangeTile()]),
    kitSection('Progress', children: const [_ProgressDemo()]),
    kitSection(
      'Bars chart',
      children: [
        const _BarsDemo(),
        kitNote('Tap a bar to read it out; the full ink follows.'),
      ],
    ),
    kitSection(
      'Bars without labels',
      children: const [
        MinimalBarChart(
          _keptByWeek,
          height: 56,
          semanticLabel: 'Days kept per week',
        ),
      ],
    ),
    kitSection(
      'Empty series',
      children: [
        const _EmptyBars(),
        kitNote(
          'Empty: the plot keeps its place and says why, as the line chart '
          'does.',
        ),
      ],
    ),
    kitSection('Sparklines', children: const [_Sparklines()]),
  ],
);

/// A week with no runs: the bars chart's baseline and days, and in the
/// plot over them the reason, worded as the line chart words its own.
class _EmptyBars extends StatelessWidget {
  const _EmptyBars();

  static const double _plot = 48;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Stack(
      children: [
        const MinimalBarChart(
          [0, 0, 0, 0, 0, 0, 0],
          labels: _days,
          height: _plot,
          semanticLabel: 'No runs this week',
        ),
        // The chart already names it to a screen reader.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: _plot,
          child: ExcludeSemantics(
            child: Center(
              child: Text(
                'No runs this week',
                style: t.bodySmall.c(t.mutedForeground),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A tile that flips between this week and this month when tapped.
class _RangeTile extends StatefulWidget {
  const _RangeTile();

  @override
  State<_RangeTile> createState() => _RangeTileState();
}

class _RangeTileState extends State<_RangeTile> {
  bool _month = false;

  @override
  Widget build(BuildContext context) {
    return MinimalStat(
      label: _month ? 'Kept · August' : 'Kept · this week',
      value: _month ? '23/28' : '5/7',
      delta: _month ? '4' : '1',
      detail: _month ? 'vs July' : 'vs last week',
      icon: LucideIcons.repeat,
      onPressed: () => setState(() => _month = !_month),
    );
  }
}

/// Progress bars in every tone, one of them stepped by hand.
class _ProgressDemo extends StatefulWidget {
  const _ProgressDemo();

  @override
  State<_ProgressDemo> createState() => _ProgressDemoState();
}

class _ProgressDemoState extends State<_ProgressDemo> {
  int _pages = 12;

  static const int _goal = 20;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    Widget line(String label, String figure, Widget bar) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: t.bodySmall,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const MinimalGap(MinimalSpacing.s8),
            Text(figure, style: t.mono.c(t.mutedForeground)),
          ],
        ),
        const MinimalGap(6),
        bar,
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        line(
          'Read 20 pages',
          '$_pages/$_goal',
          MinimalLinearProgressIndicator(
            value: _pages / _goal,
            tone: _pages >= _goal ? MinimalTone.success : MinimalTone.primary,
            label: 'Read 20 pages',
          ),
        ),
        const MinimalGap(MinimalSpacing.s8),
        kitRow([
          MinimalButton(
            'Less',
            icon: LucideIcons.minus,
            size: MinimalButtonSize.small,
            variant: MinimalButtonVariant.secondary,
            onPressed: _pages > 0 ? () => setState(() => _pages -= 4) : null,
          ),
          MinimalButton(
            'More',
            icon: LucideIcons.plus,
            size: MinimalButtonSize.small,
            variant: MinimalButtonVariant.secondary,
            onPressed: _pages < _goal
                ? () => setState(() => _pages += 4)
                : null,
          ),
        ]),
        const MinimalGap(MinimalSpacing.s16),
        line(
          'Drink water · goal met',
          '8/8',
          const MinimalLinearProgressIndicator(
            value: 1,
            label: 'Drink water',
            tone: MinimalTone.success,
          ),
        ),
        const MinimalGap(MinimalSpacing.s12),
        line(
          'Reminder quota',
          '43/50',
          const MinimalLinearProgressIndicator(
            value: 0.86,
            label: 'Reminder quota',
            tone: MinimalTone.warning,
          ),
        ),
        const MinimalGap(MinimalSpacing.s12),
        line(
          'Storage',
          '1.94 of 2 GB',
          const MinimalLinearProgressIndicator(
            value: 0.97,
            label: 'Storage',
            tone: MinimalTone.destructive,
          ),
        ),
        const MinimalGap(MinimalSpacing.s12),
        line(
          'Not started',
          '0%',
          const MinimalLinearProgressIndicator(value: 0, label: 'Not started'),
        ),
        const MinimalGap(MinimalSpacing.s12),
        line(
          'Neutral, thicker',
          '40%',
          const MinimalLinearProgressIndicator(
            value: 0.4,
            label: 'Neutral',
            tone: MinimalTone.neutral,
            height: 6,
          ),
        ),
      ],
    );
  }
}

/// A week of run minutes, read out bar by bar.
class _BarsDemo extends StatefulWidget {
  const _BarsDemo();

  @override
  State<_BarsDemo> createState() => _BarsDemoState();
}

class _BarsDemoState extends State<_BarsDemo> {
  int? _picked;

  static const List<String> _names = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final i = _picked ?? _minutes.indexOf(54);
    final total = _minutes.fold<double>(0, (a, b) => a + b).toInt();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${_names[i]} · ', style: t.h3),
                    TextSpan(text: '${_minutes[i].toInt()}', style: t.figure),
                    TextSpan(text: ' min', style: t.h3.c(t.mutedForeground)),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '$total', style: t.mono.c(t.mutedForeground)),
                  const TextSpan(text: ' min this week'),
                ],
              ),
              style: t.caption,
            ),
          ],
        ),
        const MinimalGap(MinimalSpacing.s12),
        MinimalBarChart(
          _minutes,
          labels: _days,
          height: 96,
          highlight: _picked,
          onBarPressed: (index) => setState(() => _picked = index),
          semanticLabel: 'Morning run minutes this week',
        ),
      ],
    );
  }
}

class _Sparklines extends StatelessWidget {
  const _Sparklines();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    Widget row(String name, String figure, Widget spark) => Container(
      height: t.rowHeight,
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              name,
              style: t.body.medium,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(width: 88, child: spark),
          const MinimalGap(MinimalSpacing.s12),
          SizedBox(
            width: 56,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerEnd,
              child: Text(figure, style: t.mono.c(t.mutedForeground)),
            ),
          ),
        ],
      ),
    );
    // An option the rows above do not take: its words over a row's spark.
    Widget option(String words, Widget spark) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(words, style: t.caption),
        const MinimalGap(MinimalSpacing.s8),
        SizedBox(width: 88, child: spark),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The wide one is named as the rows are, its figure at its end.
        Row(
          children: [
            Expanded(child: Text('Sessions, ten weeks', style: t.body.medium)),
            Text('27', style: t.mono.c(t.mutedForeground)),
          ],
        ),
        const MinimalGap(MinimalSpacing.s8),
        const MinimalSparkline(
          [12, 15, 14, 18, 17, 21, 19, 24, 23, 27],
          height: 48,
          semanticLabel: 'Sessions, rising',
        ),
        const MinimalGap(MinimalSpacing.s12),
        DecoratedBox(
          decoration: BoxDecoration(border: Border(top: t.rule)),
          child: Column(
            children: [
              row(
                'Morning run',
                '5:42',
                MinimalSparkline(_pace, height: 20, color: t.success),
              ),
              // One drawing down the list: each its line, its area and
              // today's dot; only the tone tells the rows apart.
              row(
                'Meditate',
                '14m',
                const MinimalSparkline(_meditated, height: 20),
              ),
              row(
                'Screen time',
                '3h 10m',
                MinimalSparkline(
                  const [2.1, 2.4, 2.2, 2.8, 3.0, 2.9, 3.2],
                  height: 20,
                  color: t.destructive,
                ),
              ),
            ],
          ),
        ),
        const MinimalGap(MinimalSpacing.s16),
        // The options, each under the words that name it.
        Wrap(
          spacing: MinimalSpacing.s32,
          runSpacing: MinimalSpacing.s16,
          children: [
            option(
              'Line only, no area',
              const MinimalSparkline(_meditated, height: 20, area: false),
            ),
            option(
              'No dot on the last day',
              const MinimalSparkline(_meditated, height: 20, endDot: false),
            ),
          ],
        ),
      ],
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// One figure on its tile: the label, the mono value, a rising delta.
Widget kitSpecimenStatTileDelta() => const MinimalStat(
  label: 'Streak',
  value: '12d',
  delta: '3d',
  detail: 'best 21d',
  icon: LucideIcons.flame,
);

/// The large figure with its trend line.
Widget kitSpecimenStatTileLarge() => const MinimalStat(
  label: 'Kept this month',
  value: '82%',
  delta: '6%',
  detail: 'vs July',
  spark: [61, 64, 70, 68, 73, 77, 75, 82],
  large: true,
);

/// Two tiles side by side, matched in height.
Widget kitSpecimenStatRowPair() => const MinimalStatRow(
  children: [
    MinimalStat(
      label: 'Missed',
      value: '5',
      delta: '2',
      deltaUp: false,
      deltaGood: true,
      detail: 'vs July',
    ),
    MinimalStat(
      label: 'August',
      value: '23/28',
      detail: 'days kept',
      icon: LucideIcons.calendarCheck,
    ),
  ],
);

/// A back office's headline numbers as one strip: a trend, a count, and
/// the alarm figure in warn.
Widget kitSpecimenKpiStripDay() => const MinimalStatRow.joined(
  children: [
    MinimalStat(
      label: 'Revenue',
      value: '€1,284',
      delta: '12%',
      detail: 'vs last Fri',
      spark: [6, 11, 4, 14, 18, 13, 22],
      weight: 1.3,
    ),
    MinimalStat(label: 'Orders', value: '38', detail: '6 open'),
    MinimalStat(
      label: 'Late',
      value: '2',
      detail: '18 min oldest',
      tone: MinimalTone.warning,
    ),
  ],
);

/// A goal in flight under its label and mono count.
Widget kitSpecimenProgressBarGoal() => const _ProgressLine(
  'Read 20 pages',
  '12/20',
  MinimalLinearProgressIndicator(value: 0.6, label: 'Read 20 pages'),
);

/// A goal met, in the success tone.
Widget kitSpecimenProgressBarMet() => const _ProgressLine(
  'Drink water · goal met',
  '8/8',
  MinimalLinearProgressIndicator(
    value: 1,
    label: 'Drink water',
    tone: MinimalTone.success,
  ),
);

/// A week of minutes, the best day in the full ink.
Widget kitSpecimenBarsChartWeek() => const MinimalBarChart(
  _minutes,
  labels: _days,
  semanticLabel: 'Minutes run per day',
);

/// A series' shape with no axes, ending on today's dot.
Widget kitSpecimenSparklinePace() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text('PACE · LAST 10 RUNS', style: t.label)),
            Text('5:42 /km', style: t.mono.c(t.mutedForeground)),
          ],
        ),
        const MinimalGap(MinimalSpacing.s8),
        const MinimalSparkline(_pace, semanticLabel: 'Pace over ten runs'),
      ],
    );
  },
);

/// A progress bar under its label and mono figure.
class _ProgressLine extends StatelessWidget {
  const _ProgressLine(this.label, this.figure, this.bar);

  final String label;
  final String figure;
  final Widget bar;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: t.bodySmall, maxLines: 1)),
            const MinimalGap(MinimalSpacing.s8),
            Text(figure, style: t.mono.c(t.mutedForeground)),
          ],
        ),
        const MinimalGap(6),
        bar,
      ],
    );
  }
}
