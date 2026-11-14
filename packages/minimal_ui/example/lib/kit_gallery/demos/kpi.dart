/// KPIs & heatmap: the back office's KPI strip (three cells, two, four
/// tappable ones, deltas good and bad) and the contribution heatmap
/// (twelve weeks with today outlined, half a year shrunk to fit with its
/// key, and an empty record).
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';

import '../kit.dart';

/// Morning run's last twelve weeks, Monday first, today the Friday of the
/// last week: the same seeded record the reference mockup draws.
List<int> _record({int weeks = 12, int seed = 7}) {
  var s = seed;
  double next() {
    s = (s * 9301 + 49297) % 233280;
    return s / 233280;
  }

  return [
    for (var w = 0; w < weeks; w++)
      for (var d = 0; d < 7; d++)
        if (w < weeks - 1 || d < 4)
          switch (next()) {
            < .15 => 0,
            < .45 => 1,
            _ => 2,
          }
        else if (w == weeks - 1 && d == 4)
          2,
  ];
}

Widget kitKpiDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'KPIs & heatmap',
  sections: [
    kitSection(
      'KPI strip',
      children: const [
        MinimalStatRow.joined(
          children: [
            MinimalStat(
              label: 'Revenue',
              value: '€1,284',
              delta: '12%',
              detail: 'vs last Fri',
              spark: [6, 11, 4, 14, 18, 13, 22],
            ),
            MinimalStat(label: 'Orders', value: '38', detail: '6 open'),
            MinimalStat(
              label: 'Late',
              value: '2',
              // Short enough for the narrowest cell at the largest text.
              detail: 'oldest 18m',
              tone: MinimalTone.warning,
            ),
          ],
        ),
      ],
    ),
    kitSection(
      'Two cells',
      children: const [
        MinimalStatRow.joined(
          children: [
            MinimalStat(
              label: 'Kept · August',
              value: '23/28',
              delta: '4',
              detail: 'vs July',
            ),
            MinimalStat(
              label: 'Best streak',
              value: '21d',
              detail: 'Morning run',
            ),
          ],
        ),
      ],
    ),
    kitSection('Tappable cells', children: const [_FilterStrip()]),
    kitSection(
      'Deltas that are bad news',
      children: [
        const MinimalStatRow.joined(
          children: [
            MinimalStat(
              label: 'Avg prep',
              value: '14m',
              delta: '2m',
              deltaUp: false,
              deltaGood: true,
              detail: 'faster',
            ),
            MinimalStat(
              label: 'Refunds',
              value: '€38',
              delta: '€12',
              deltaGood: false,
              spark: [8, 12, 10, 18, 22, 26, 38],
            ),
            MinimalStat(
              label: 'Failed',
              value: '2',
              tone: MinimalTone.destructive,
              detail: 'payments',
            ),
          ],
        ),
        kitNote(
          'The delta colours by goodness, the value by alarm: a figure that '
          'is itself the problem takes the warn or danger ink.',
        ),
      ],
    ),
    kitSection(
      'Twelve weeks, today outlined',
      children: [
        Builder(
          builder: (context) {
            final t = context.minimalTheme;
            final record = _record();
            final kept = record.where((l) => l > 0).length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The habit and its tally on one line at the grid's start,
                // so the count stands by its small grid and the section's
                // eyebrow stays the only caps heading. The future days are
                // blank, so the record's own length is the whole: the tally
                // and the heatmap's announcement agree.
                Wrap(
                  spacing: MinimalSpacing.s8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('Morning run', style: t.bodySmall.c(t.foreground)),
                    Text(
                      '$kept/${record.length}',
                      style: t.mono.c(t.mutedForeground),
                    ),
                  ],
                ),
                const MinimalGap(MinimalSpacing.s8),
                MinimalHeatmap(
                  levels: record,
                  weeks: 12,
                  today: record.length - 1,
                ),
              ],
            );
          },
        ),
      ],
    ),
    kitSection(
      'Half a year, with its key',
      children: [
        Builder(
          builder: (context) {
            final record = _record(weeks: 30, seed: 11);
            return MinimalHeatmap(
              levels: record,
              weeks: 30,
              today: record.length - 1,
              legend: true,
            );
          },
        ),
        kitNote(
          'Thirty weeks keep their cells where they fit; in a narrower '
          'column the cells shrink so the whole half year still shows.',
        ),
      ],
    ),
    kitSection(
      'Empty record',
      children: [
        MinimalHeatmap(levels: List<int>.filled(26, 0), weeks: 4, today: 25),
        kitNote('Stretch before bed, four weeks in: no day kept yet.'),
      ],
    ),
  ],
);

/// Four count cells that pick which orders the list below shows.
class _FilterStrip extends StatefulWidget {
  const _FilterStrip();

  @override
  State<_FilterStrip> createState() => _FilterStripState();
}

class _FilterStripState extends State<_FilterStrip> {
  String _showing = 'Open';

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    MinimalStat cell(String label, String value, {MinimalTone? tone}) =>
        MinimalStat(
          label: label,
          value: value,
          tone: tone,
          selected: _showing == label,
          onPressed: () => setState(() => _showing = label),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalStatRow.joined(
          children: [
            cell('Open', '6'),
            cell('Ready', '9'),
            cell('Done', '23'),
            cell('Late', '2', tone: MinimalTone.warning),
          ],
        ),
        const MinimalGap(MinimalSpacing.s8),
        Text(
          'Showing $_showing orders. Tap a cell to filter.',
          style: t.bodySmall.c(t.mutedForeground),
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

/// Twelve weeks of a habit, today outlined.
Widget kitSpecimenHeatmapWeeks() {
  final record = _record();
  return MinimalHeatmap(
    levels: record,
    weeks: 12,
    today: record.length - 1,
    semanticLabel: 'Morning run, last 12 weeks',
  );
}

/// Half a year shrunk to fit the width, with its key.
Widget kitSpecimenHeatmapLegend() {
  final record = _record(weeks: 26, seed: 11);
  return MinimalHeatmap(
    levels: record,
    weeks: 26,
    today: record.length - 1,
    legend: true,
    semanticLabel: 'Morning run, last 26 weeks',
  );
}
