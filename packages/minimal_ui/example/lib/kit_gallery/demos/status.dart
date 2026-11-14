/// Status & group headers: the six status glyphs (and one as a live
/// control), dot badges in every tone, group headers static and
/// collapsible, the n-of-m segment bar and a row's inline week of squares.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';

import '../kit.dart';

// A group header inside the padded demo body: the body already carries the
// gutter.
const EdgeInsets _inBody = EdgeInsets.fromLTRB(0, 14, 0, 6);

// The segment bars' figure and noun, one width down the stack (the widest,
// `2/12 weeks missed`), so every bar starts and ends on the same line.
const double _tally = 120;

Widget kitStatusDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Status & group headers',
  sections: [
    kitSection(
      'Status glyphs',
      children: [
        for (final status in MinimalTaskStatus.values) _StatusLine(status),
      ],
    ),
    kitSection(
      'Priority glyphs',
      children: [
        kitRow([
          for (final p in MinimalPriority.values)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                MinimalPriorityIcon(p),
                const MinimalGap(MinimalSpacing.s4),
                kitNote(p.label),
              ],
            ),
        ]),
        kitNote(
          'Priority reads by shape in the quiet ink; only urgent takes the '
          'danger colour, so status keeps the row\'s colour.',
        ),
      ],
    ),
    kitSection(
      'Status as a control',
      children: [
        const _Checklist(),
        kitNote(
          'Tap a glyph to mark the habit done, and again to reopen it. A '
          'paused habit shows its state but cannot be ticked off.',
        ),
      ],
    ),
    kitSection(
      'Badges',
      children: [
        kitRow(const [
          MinimalStatusBadge('Late', tone: MinimalTone.warning),
          MinimalStatusBadge('Baking', tone: MinimalTone.primary),
          MinimalStatusBadge('Ready', tone: MinimalTone.success),
          MinimalStatusBadge('Queued'),
          MinimalStatusBadge('Failed', tone: MinimalTone.destructive),
          // As the orders table wears it: the neutral dot.
          MinimalStatusBadge('Picked up'),
        ]),
        kitNote(
          'Success, warn and danger ink the label; accent and neutral let '
          'the dot alone carry the colour.',
        ),
        kitRow([
          for (final s in MinimalTaskStatus.values)
            MinimalStatusBadge.status(s),
        ]),
      ],
    ),
    kitSection(
      'Group headers',
      // A line first, so the first header is not read as a second gallery
      // heading; each header over its group's rows, as a list holds them.
      children: [
        kitNote(
          "A group's header over its rows: a count, a glyph or a status.",
        ),
        // One list: each header stands on its rows as the collapsible
        // group's does (the section's own gap is for its parts, not rows).
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MinimalSectionHeader('Morning', count: '1/2', padding: _inBody),
            _GroupRow(MinimalTaskStatus.done, 'Meditate', '4d'),
            _GroupRow(MinimalTaskStatus.todo, 'Drink water', '10d'),
            MinimalSectionHeader(
              'In progress',
              count: '1',
              leading: MinimalStatusIcon(MinimalTaskStatus.active, size: 14),
              padding: _inBody,
            ),
            _GroupRow(MinimalTaskStatus.active, 'Practise scales', '6d'),
            MinimalSectionHeader(
              'Last 12 weeks',
              trailing: MinimalStatusBadge(
                'On track',
                tone: MinimalTone.success,
              ),
              padding: _inBody,
            ),
            _GroupRow(MinimalTaskStatus.done, 'Morning run', '72/82'),
          ],
        ),
      ],
    ),
    kitSection('Collapsible group', children: const [_Collapsible()]),
    kitSection(
      'Segment bar',
      children: [
        const _SegmentDemo(),
        kitNote(
          'The tone says what is counted: the accent for a plain tally, '
          'amber for misses. Weekends, 0/0: an empty whole draws one quiet '
          'track. The buttons step the first bar.',
        ),
      ],
    ),
    kitSection('Week dots in rows', children: const [_WeekRows()]),
  ],
);

class _StatusLine extends StatelessWidget {
  const _StatusLine(this.status);

  final MinimalTaskStatus status;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        MinimalStatusIcon(status),
        const MinimalGap(10),
        Expanded(
          child: Text(
            status.label,
            style: t.body.medium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(status.name, style: t.mono.c(t.mutedForeground)),
      ],
    );
  }
}

/// Three habits whose status glyph toggles them done.
class _Checklist extends StatefulWidget {
  const _Checklist();

  @override
  State<_Checklist> createState() => _ChecklistState();
}

class _ChecklistState extends State<_Checklist> {
  final Map<String, bool> _done = {
    'Meditate': true,
    'Morning run': true,
    'Drink water': false,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: t.rule)),
      child: Column(
        children: [
          for (final MapEntry(key: name, value: done) in _done.entries)
            Container(
              height: t.rowHeight,
              decoration: BoxDecoration(border: Border(bottom: t.rule)),
              child: Row(
                children: [
                  MinimalStatusIcon(
                    done ? MinimalTaskStatus.done : MinimalTaskStatus.todo,
                    semanticLabel: name,
                    onPressed: () => setState(() => _done[name] = !done),
                  ),
                  const MinimalGap(10),
                  Expanded(
                    child: Text(
                      name,
                      style: t.body.medium.c(
                        done ? t.mutedForeground : t.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          // A paused habit: its state shows, but it cannot be ticked off.
          // The list's last row draws no rule.
          SizedBox(
            height: t.rowHeight,
            child: Row(
              children: [
                const MinimalStatusIcon(MinimalTaskStatus.paused),
                const MinimalGap(10),
                Expanded(
                  child: Text(
                    'Water the plants',
                    style: t.body.medium.c(t.mutedForeground),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('Paused', style: t.bodySmall.c(t.mutedForeground)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A group that folds its rows away from its header.
class _Collapsible extends StatefulWidget {
  const _Collapsible();

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    const rows = [
      (MinimalTaskStatus.done, 'Journal', '3d'),
      (MinimalTaskStatus.done, 'Read 20 pages', '6d'),
      (MinimalTaskStatus.backlog, 'Stretch before bed', '—'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSectionHeader(
          'Evening',
          count: '2/3',
          expanded: _open,
          onExpansionChanged: (_) => setState(() => _open = !_open),
          padding: _inBody,
        ),
        if (_open)
          for (final (status, name, streak) in rows)
            _GroupRow(status, name, streak),
      ],
    );
  }
}

/// A habit row in a group: its status glyph, its name (muted once done, as
/// every list's ticked rows are) and its streak, ruled at its foot.
class _GroupRow extends StatelessWidget {
  const _GroupRow(this.status, this.name, this.streak);

  final MinimalTaskStatus status;
  final String name;
  final String streak;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Container(
      height: t.rowHeight,
      decoration: BoxDecoration(border: Border(bottom: t.rule)),
      child: Row(
        children: [
          MinimalStatusIcon(status),
          const MinimalGap(10),
          Expanded(
            child: Text(
              name,
              style: t.body.medium.c(
                status == MinimalTaskStatus.done
                    ? t.mutedForeground
                    : t.foreground,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(streak, style: t.mono.c(t.mutedForeground)),
        ],
      ),
    );
  }
}

/// The Today summary line over three other tallies, the bars standing
/// together; the day's count is stepped by hand from the buttons under them.
class _SegmentDemo extends StatefulWidget {
  const _SegmentDemo();

  @override
  State<_SegmentDemo> createState() => _SegmentDemoState();
}

class _SegmentDemoState extends State<_SegmentDemo> {
  int _kept = 3;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSegmentBar(
          value: _kept,
          total: 5,
          label: 'kept',
          labelWidth: _tally,
          showPercent: true,
        ),
        const MinimalGap(MinimalSpacing.s12),
        const MinimalSegmentBar(
          value: 5,
          total: 8,
          tone: MinimalTone.primary,
          label: 'glasses',
          labelWidth: _tally,
          showPercent: true,
        ),
        const MinimalGap(MinimalSpacing.s12),
        const MinimalSegmentBar(
          value: 2,
          total: 12,
          tone: MinimalTone.warning,
          label: 'weeks missed',
          labelWidth: _tally,
          showPercent: true,
        ),
        const MinimalGap(MinimalSpacing.s12),
        const MinimalSegmentBar(
          value: 0,
          total: 0,
          label: 'kept',
          labelWidth: _tally,
          showPercent: true,
        ),
        const MinimalGap(MinimalSpacing.s12),
        kitRow([
          MinimalButton(
            'Undo one',
            size: MinimalButtonSize.small,
            variant: MinimalButtonVariant.secondary,
            onPressed: _kept > 0 ? () => setState(() => _kept -= 1) : null,
          ),
          MinimalButton(
            'Keep one',
            size: MinimalButtonSize.small,
            variant: MinimalButtonVariant.secondary,
            onPressed: _kept < 5 ? () => setState(() => _kept += 1) : null,
          ),
        ]),
      ],
    );
  }
}

class _WeekRows extends StatelessWidget {
  const _WeekRows();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    // Mon..Sun, today is Friday (index 4).
    const habits = [
      (
        MinimalTaskStatus.done,
        'Meditate',
        [false, true, true, true, true, false, false],
        '4d',
      ),
      (
        MinimalTaskStatus.done,
        'Morning run',
        [true, true, true, true, true, false, false],
        '12d',
      ),
      (
        MinimalTaskStatus.todo,
        'Drink water',
        [true, true, true, true, false, false, false],
        '10d',
      ),
      (
        MinimalTaskStatus.paused,
        'Water the plants',
        [false, false, false, false, false, false, false],
        '2d',
      ),
    ];
    return DecoratedBox(
      decoration: BoxDecoration(border: Border(top: t.rule)),
      child: MinimalListSection(
        gutter: false,
        children: [
          for (final (status, name, week, streak) in habits)
            MinimalListTile(
              title: name,
              muted: status != MinimalTaskStatus.todo,
              leading: MinimalStatusIcon(status),
              trailing: MinimalWeekDots(completedDays: week, currentDay: 4),
              meta: streak,
              // The streak's fixed column keeps the dots aligned.
              metaWidth: 30,
            ),
        ],
      ),
    );
  }
}

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style.

/// A group's label and mono count over its full-bleed rows.
Widget kitSpecimenGroupHeaderCount() => const _Body(
  bleed: true,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalSectionHeader('Morning', count: '2/3'),
      MinimalListSection(
        children: [
          MinimalListTile(
            leading: MinimalStatusIcon(MinimalTaskStatus.done),
            title: 'Meditate',
            muted: true,
            meta: '4d',
          ),
          MinimalListTile(
            leading: MinimalStatusIcon(MinimalTaskStatus.todo),
            title: 'Drink water',
            meta: '10d',
          ),
        ],
      ),
    ],
  ),
);

/// A collapsible group led by its status glyph, open over its rows.
Widget kitSpecimenGroupHeaderCollapsible() => _Body(
  bleed: true,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      MinimalSectionHeader(
        'In progress',
        count: '2',
        leading: const MinimalStatusIcon(MinimalTaskStatus.active, size: 14),
        onExpansionChanged: (_) {},
      ),
      const MinimalListSection(
        children: [
          MinimalListTile(
            leading: MinimalStatusIcon(MinimalTaskStatus.active),
            title: 'Ship the reminder fix',
            meta: 'ISS-12',
          ),
          MinimalListTile(
            leading: MinimalStatusIcon(MinimalTaskStatus.active),
            title: 'Streak calendar polish',
            meta: 'ISS-9',
          ),
        ],
      ),
    ],
  ),
);

/// The six states of a piece of work, each glyph with its name.
Widget kitSpecimenStatusIconStates() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Wrap(
      spacing: MinimalSpacing.s16,
      runSpacing: MinimalSpacing.s12,
      children: [
        for (final status in MinimalTaskStatus.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalStatusIcon(status),
              const MinimalGap(MinimalSpacing.s8),
              Text(status.label, style: t.bodySmall),
            ],
          ),
      ],
    );
  },
);

/// The glyph as each row's quick status control: tap to mark done.
Widget kitSpecimenStatusIconControl() => _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: MinimalStatusIcon(
          MinimalTaskStatus.done,
          semanticLabel: 'Meditate',
          onPressed: () {},
        ),
        title: 'Meditate',
        muted: true,
        meta: '4d',
      ),
      MinimalListTile(
        leading: MinimalStatusIcon(
          MinimalTaskStatus.todo,
          semanticLabel: 'Drink water',
          onPressed: () {},
        ),
        title: 'Drink water',
        meta: '10d',
      ),
    ],
  ),
);

/// The five priorities, each glyph with its name.
Widget kitSpecimenPriorityIcons() => Builder(
  builder: (context) {
    final t = context.minimalTheme;
    return Wrap(
      spacing: MinimalSpacing.s16,
      runSpacing: MinimalSpacing.s12,
      children: [
        for (final priority in MinimalPriority.values)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              MinimalPriorityIcon(priority),
              const MinimalGap(MinimalSpacing.s8),
              Text(priority.label, style: t.bodySmall),
            ],
          ),
      ],
    );
  },
);

/// A state that needs attention: the label inked, the border tinted.
Widget kitSpecimenBadgeWarning() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [MinimalStatusBadge('Late', tone: MinimalTone.warning)],
);

/// A finished state in the success tone.
Widget kitSpecimenBadgeSuccess() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [MinimalStatusBadge('Ready', tone: MinimalTone.success)],
);

/// A waiting state: the ink kept, the dot alone carries the colour.
Widget kitSpecimenBadgeNeutral() => const Row(
  mainAxisAlignment: MainAxisAlignment.center,
  children: [MinimalStatusBadge('Queued')],
);

/// Today's summary line: the figure, the segments and the percentage.
Widget kitSpecimenSegmentBarLabelled() => const MinimalSegmentBar(
  value: 3,
  total: 5,
  label: 'kept',
  showPercent: true,
);

/// Five of eight segments in the accent, bare.
Widget kitSpecimenSegmentBarPlain() =>
    const MinimalSegmentBar(value: 5, total: 8, tone: MinimalTone.primary);

/// Each habit row's week before its streak, today hollow.
Widget kitSpecimenWeekDotsRows() => const _Body(
  bleed: true,
  child: MinimalListSection(
    children: [
      MinimalListTile(
        leading: MinimalStatusIcon(MinimalTaskStatus.done),
        title: 'Meditate',
        muted: true,
        trailing: MinimalWeekDots(
          completedDays: [false, true, true, true, true, false, false],
          currentDay: 4,
        ),
        meta: '4d',
        metaWidth: 30,
      ),
      MinimalListTile(
        leading: MinimalStatusIcon(MinimalTaskStatus.done),
        title: 'Morning run',
        muted: true,
        trailing: MinimalWeekDots(
          completedDays: [true, true, true, true, true, false, false],
          currentDay: 4,
        ),
        meta: '12d',
        metaWidth: 30,
      ),
      MinimalListTile(
        leading: MinimalStatusIcon(MinimalTaskStatus.todo),
        title: 'Drink water',
        trailing: MinimalWeekDots(
          completedDays: [true, true, true, true, false, false, false],
          currentDay: 4,
        ),
        meta: '10d',
        metaWidth: 30,
      ),
    ],
  ),
);

/// Lays a specimen out as a scrolling page body does: its own height,
/// however tall the stage — and with [bleed] edge to edge past the stage's
/// gutter, as on a `MinimalScaffold(padding: EdgeInsets.zero)` page.
class _Body extends StatelessWidget {
  const _Body({required this.child, this.bleed = false});

  final Widget child;
  final bool bleed;

  @override
  Widget build(BuildContext context) => UnconstrainedBox(
    constrainedAxis: Axis.horizontal,
    child: !bleed
        ? child
        : LayoutBuilder(
            builder: (context, c) => FractionallySizedBox(
              widthFactor:
                  (c.maxWidth + 2 * MinimalChromeMetrics.gutter) / c.maxWidth,
              child: child,
            ),
          ),
  );
}
