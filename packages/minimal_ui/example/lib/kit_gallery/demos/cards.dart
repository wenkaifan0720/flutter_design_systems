/// Cards & sections: the one container Minimal allows — a hairline on the
/// surface, never a shadow — in its plain, flat (the quiet panel),
/// tappable and selected registers, a card holding a row group, and the
/// section header (uppercase label, mono count, a text action) that gives a
/// page its rhythm — standing on the ground, not in a card.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitCardsDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Cards & sections',
  sections: [
    kitSection('Card', children: const [_HabitCard()]),
    kitSection(
      'Flat panel',
      children: [
        const _StreakPanel(),
        kitNote('The quiet panel: a strip of facts that belong together.'),
      ],
    ),
    kitSection('Tappable & selected', children: const [_PlanPicker()]),
    kitSection('Rows in a card', children: const [_HabitSettings()]),
    kitSection(
      'Section',
      children: [
        // A line first, so the section's own caps header below is not read
        // as a second gallery heading.
        kitNote(
          'A region on the page: its caps header, with a count or a text '
          'action at the end, over its rows.',
        ),
        const _SectionSpecimens(),
        // One header act, in two states on purpose: live, and waiting.
        kitNote(
          'Activity\'s View all is live. Notes has nothing to export yet, '
          'so its Export shows disabled.',
        ),
      ],
    ),
    kitSection(
      'Empty',
      children: [
        // A line first, so the section's own caps header below is not read
        // as a second gallery heading.
        kitNote(
          'An empty section keeps its header and says why in the space its '
          'rows would take.',
        ),
        // On the ground, as the sections with rows above.
        MinimalSection(
          title: 'Weekends',
          count: '0',
          child: MinimalEmptyState(
            icon: LucideIcons.calendarOff,
            title: 'Nothing on weekends',
            body: 'Habits you schedule for Saturday or Sunday show here.',
            actionLabel: 'Add a habit',
            onAction: () {},
          ),
        ),
      ],
    ),
  ],
);

/// The plain card: a habit's summary with its actions.
class _HabitCard extends StatelessWidget {
  const _HabitCard();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const MinimalStatusIcon(MinimalTaskStatus.done),
              const MinimalGap(MinimalSpacing.s8),
              Expanded(
                child: Text(
                  'Morning run',
                  style: t.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text('HAB-4', style: t.mono.c(t.mutedForeground)),
            ],
          ),
          const MinimalGap(MinimalSpacing.s4),
          Text(
            'Out the door before 8. Any distance counts.',
            style: t.bodySmall.c(t.mutedForeground),
          ),
          const MinimalGap(MinimalSpacing.s12),
          Wrap(
            spacing: MinimalSpacing.s8,
            runSpacing: MinimalSpacing.s8,
            children: [
              MinimalButton(
                'Undo today',
                variant: MinimalButtonVariant.secondary,
                size: MinimalButtonSize.small,
                onPressed: () {},
              ),
              MinimalButton(
                'Open',
                variant: MinimalButtonVariant.ghost,
                size: MinimalButtonSize.small,
                icon: LucideIcons.arrowUpRightDir,
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A card holding a row group: the habit's settings, the words in the
/// proportional ink and only the figures in mono.
class _HabitSettings extends StatelessWidget {
  const _HabitSettings();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return MinimalListSection(
      inset: true,
      children: [
        MinimalListTile(
          icon: LucideIcons.repeat,
          title: 'Repeats',
          trailing: Text('Every day', style: t.bodySmall.c(t.mutedForeground)),
          chevron: true,
          onTap: () {},
        ),
        MinimalListTile(
          icon: LucideIcons.bell,
          title: 'Reminder',
          meta: '07:00',
          chevron: true,
          onTap: () {},
        ),
        const MinimalListTile(
          icon: LucideIcons.flame,
          title: 'Streak',
          subtitle: 'Best 21d',
          meta: '12d',
        ),
      ],
    );
  }
}

/// The flat panel: three facts side by side on the quiet fill, or one under
/// another when a figure would not print whole in its third (a large text
/// size on a phone). A figure is never scaled down to fit.
class _StreakPanel extends StatelessWidget {
  const _StreakPanel();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final facts = [
      ('Streak', '12d', 'best 21d'),
      ('August', '23/28', 'days kept'),
      ('Started', MinimalFormat.isoDate(DateTime(2026, 6, 2)), 'day one'),
    ];
    Widget fact((String, String, String) f) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          f.$1.toUpperCase(),
          style: t.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const MinimalGap(MinimalSpacing.s4),
        Text(f.$2, style: t.figure),
        Text(
          f.$3,
          style: t.caption,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
    return MinimalCard(
      flat: true,
      padding: MinimalInsets.all12,
      child: LayoutBuilder(
        builder: (context, c) {
          final scaler = MediaQuery.textScalerOf(context);
          final direction = Directionality.of(context);
          double width(String figure) {
            final painter = TextPainter(
              text: TextSpan(text: figure, style: t.figure),
              textScaler: scaler,
              textDirection: direction,
              maxLines: 1,
            )..layout();
            final w = painter.width;
            painter.dispose();
            return w;
          }

          final third = (c.maxWidth - 2 * MinimalSpacing.s12) / 3;
          if (facts.every((f) => width(f.$2) <= third)) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (i, f) in facts.indexed) ...[
                  if (i > 0) const MinimalGap(MinimalSpacing.s12),
                  Expanded(child: fact(f)),
                ],
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, f) in facts.indexed) ...[
                if (i > 0) const MinimalGap(MinimalSpacing.s12),
                fact(f),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Three tappable cards, one selected: a reminder-time picker.
class _PlanPicker extends StatefulWidget {
  const _PlanPicker();

  @override
  State<_PlanPicker> createState() => _PlanPickerState();
}

class _PlanPickerState extends State<_PlanPicker> {
  static const _options = [
    ('Morning', '07:00', 'Before the day starts', LucideIcons.sunrise),
    ('Evening', '21:30', 'Wind down before bed', LucideIcons.moon),
    ('No reminder', '—', 'Check in when you like', LucideIcons.bellOff),
  ];

  int _picked = 1;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, (name, time, detail, icon)) in _options.indexed) ...[
          if (i > 0) const MinimalGap(MinimalSpacing.s8),
          MinimalCard(
            selected: i == _picked,
            padding: MinimalInsets.horizontal12Vertical8,
            onPressed: () => setState(() => _picked = i),
            child: Row(
              children: [
                // The choice is said in ink and weight, never the accent.
                MinimalIcon(
                  icon,
                  color: i == _picked ? t.foreground : t.mutedForeground,
                ),
                const MinimalGap(MinimalSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: i == _picked ? t.body.semibold : t.body.medium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        detail,
                        style: t.caption,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const MinimalGap(MinimalSpacing.s8),
                Text(time, style: t.mono.c(t.mutedForeground)),
              ],
            ),
          ),
        ],
        const MinimalGap(MinimalSpacing.s8),
        kitNote(
          'Reminder: ${_options[_picked].$1} — tap a card to choose. '
          'Every option announces whether it is the selected one; the '
          'chosen one wears an ink hairline.',
        ),
      ],
    );
  }
}

/// Section headers as they stand on a page: rows under a header, a count
/// with a text action, a disabled action — on the ground, never in a card.
class _SectionSpecimens extends StatefulWidget {
  const _SectionSpecimens();

  @override
  State<_SectionSpecimens> createState() => _SectionSpecimensState();
}

class _SectionSpecimensState extends State<_SectionSpecimens> {
  bool _all = false;

  static const _log = [
    ('28 Aug 07:12', 'Marked done'),
    ('27 Aug 07:40', 'Marked done · note added'),
    ('26 Aug 06:58', 'Marked done'),
    ('19 Aug 20:15', 'Reminder moved to 07:00'),
    ('18 Aug 07:05', 'Marked done'),
    ('17 Aug 07:31', 'Marked done'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    final shown = (_all ? _log : _log.take(3)).toList();
    // Sections stand on the ground and keep the page's measure: the rows,
    // the log and the notes alike. No card around any of them.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        MinimalSection(
          title: 'Morning',
          count: '2/3',
          child: MinimalListSection(
            gutter: false,
            children: [
              const MinimalListTile(
                leading: MinimalStatusIcon(MinimalTaskStatus.done),
                title: 'Meditate',
                muted: true,
                meta: '4d',
              ),
              const MinimalListTile(
                leading: MinimalStatusIcon(MinimalTaskStatus.done),
                title: 'Morning run',
                muted: true,
                meta: '12d',
              ),
              const MinimalListTile(
                leading: MinimalStatusIcon(MinimalTaskStatus.todo),
                title: 'Drink water',
                meta: '10d',
              ),
            ],
          ),
        ),
        MinimalSection(
          title: 'Activity',
          count: '${_log.length}',
          actionLabel: _all ? 'Show less' : 'View all',
          onAction: () => setState(() => _all = !_all),
          child: Column(
            children: [
              for (final (i, (time, what)) in shown.indexed)
                Container(
                  padding: MinimalInsets.vertical8,
                  // A list's last row draws no rule, as the rows above.
                  decoration: i == shown.length - 1
                      ? null
                      : BoxDecoration(border: Border(bottom: t.rule)),
                  // The stamps are one length in tabular mono, so they line
                  // up as a column at any text scale.
                  child: MinimalMetaRow(
                    leading: Text(time, softWrap: false),
                    middle: Text(what),
                  ),
                ),
            ],
          ),
        ),
        // Nothing to export yet: the action shows disabled and the line
        // under it is a hint in the quiet ink, not content.
        MinimalSection(
          title: 'Notes',
          actionLabel: 'Export',
          child: Text(
            'Add a note to export this habit\'s history.',
            style: t.bodySmall.c(t.mutedForeground),
          ),
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

/// The plain card: a habit's summary and its two small actions.
Widget kitSpecimenCardPanel() =>
    const MinimalCard(semanticLabel: 'Morning run', child: _CardSummary());

/// The quiet panel: three facts side by side on the well's fill.
Widget kitSpecimenCardFlat() => const MinimalCard(
  flat: true,
  padding: MinimalInsets.all12,
  child: _CardFacts(),
);

/// Tappable cards of a choice, the picked one selected.
Widget kitSpecimenCardSelected() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    MinimalCard(
      selected: true,
      padding: MinimalInsets.horizontal12Vertical8,
      onPressed: () {},
      child: const _CardOption(
        LucideIcons.sunrise,
        'Morning',
        'Before the day starts',
        '07:00',
        picked: true,
      ),
    ),
    const MinimalGap(MinimalSpacing.s8),
    MinimalCard(
      selected: false,
      padding: MinimalInsets.horizontal12Vertical8,
      onPressed: () {},
      child: const _CardOption(
        LucideIcons.moon,
        'Evening',
        'Wind down before bed',
        '21:30',
      ),
    ),
  ],
);

/// A region with its mono count and a text action on the header's end.
Widget kitSpecimenSectionAction() => _Body(
  child: Builder(
    builder: (context) {
      final t = context.minimalTheme;
      return MinimalSection(
        title: 'Activity',
        count: '6',
        actionLabel: 'View all',
        onAction: () {},
        child: Column(
          children: [
            for (final (time, what) in const [
              ('28 Aug 07:12', 'Marked done'),
              ('27 Aug 07:40', 'Marked done · note added'),
              ('26 Aug 06:58', 'Marked done'),
            ])
              Container(
                padding: MinimalInsets.vertical8,
                decoration: BoxDecoration(border: Border(bottom: t.rule)),
                child: MinimalMetaRow(
                  leading: Text(time, softWrap: false),
                  middle: Text(what),
                ),
              ),
          ],
        ),
      );
    },
  ),
);

/// Full-bleed rows under a header set on the gutter.
Widget kitSpecimenSectionRows() => const _Body(
  bleed: true,
  child: MinimalSection(
    title: 'Morning',
    count: '2/3',
    gutter: true,
    child: MinimalListSection(
      children: [
        MinimalListTile(
          leading: MinimalStatusIcon(MinimalTaskStatus.done),
          title: 'Meditate',
          muted: true,
          meta: '4d',
        ),
        MinimalListTile(
          leading: MinimalStatusIcon(MinimalTaskStatus.done),
          title: 'Morning run',
          muted: true,
          meta: '12d',
        ),
        MinimalListTile(
          leading: MinimalStatusIcon(MinimalTaskStatus.todo),
          title: 'Drink water',
          meta: '10d',
        ),
      ],
    ),
  ),
);

/// A habit's summary: its state, name and id, a line of detail, actions.
class _CardSummary extends StatelessWidget {
  const _CardSummary();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const MinimalStatusIcon(MinimalTaskStatus.done),
            const MinimalGap(MinimalSpacing.s8),
            Expanded(
              child: Text(
                'Morning run',
                style: t.h3,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text('HAB-4', style: t.mono.c(t.mutedForeground)),
          ],
        ),
        const MinimalGap(MinimalSpacing.s4),
        Text(
          'Out the door before 8. Any distance counts.',
          style: t.bodySmall.c(t.mutedForeground),
        ),
        const MinimalGap(MinimalSpacing.s12),
        Wrap(
          spacing: MinimalSpacing.s8,
          runSpacing: MinimalSpacing.s8,
          children: [
            MinimalButton(
              'Undo today',
              variant: MinimalButtonVariant.secondary,
              size: MinimalButtonSize.small,
              onPressed: () {},
            ),
            MinimalButton(
              'Open',
              variant: MinimalButtonVariant.ghost,
              size: MinimalButtonSize.small,
              icon: LucideIcons.arrowUpRightDir,
              onPressed: () {},
            ),
          ],
        ),
      ],
    );
  }
}

/// Three facts on the quiet panel.
class _CardFacts extends StatelessWidget {
  const _CardFacts();

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    Widget fact(String label, String value, String detail) => Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: t.label, maxLines: 1),
          const MinimalGap(MinimalSpacing.s4),
          Text(value, style: t.figure, maxLines: 1),
          Text(detail, style: t.caption, maxLines: 1),
        ],
      ),
    );
    return Row(
      children: [
        fact('Streak', '12d', 'best 21d'),
        const MinimalGap(MinimalSpacing.s12),
        fact('August', '23/28', 'days kept'),
        const MinimalGap(MinimalSpacing.s12),
        fact('Started', '2026-06-02', 'day one'),
      ],
    );
  }
}

/// One option of a card choice: its glyph, name, detail and time.
class _CardOption extends StatelessWidget {
  const _CardOption(
    this.icon,
    this.name,
    this.detail,
    this.time, {
    this.picked = false,
  });

  final IconData icon;
  final String name;
  final String detail;
  final String time;
  final bool picked;

  @override
  Widget build(BuildContext context) {
    final t = context.minimalTheme;
    return Row(
      children: [
        MinimalIcon(icon, color: picked ? t.foreground : t.mutedForeground),
        const MinimalGap(MinimalSpacing.s12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: picked ? t.body.semibold : t.body.medium,
                maxLines: 1,
              ),
              Text(detail, style: t.caption, maxLines: 1),
            ],
          ),
        ),
        const MinimalGap(MinimalSpacing.s8),
        Text(time, style: t.mono.c(t.mutedForeground)),
      ],
    );
  }
}

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
