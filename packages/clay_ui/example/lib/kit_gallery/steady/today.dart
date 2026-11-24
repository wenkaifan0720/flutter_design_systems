/// Steady's Today: the day's ring, then the habits by the time of day,
/// each ticked by its whole row; on a desk, the week beside them.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';
import 'data.dart';
import 'editor.dart';
import 'habits.dart';
import 'log.dart';
import 'steady.dart';

/// Today.
class SteadyToday extends StatelessWidget {
  /// Today's page.
  const SteadyToday({super.key});

  @override
  Widget build(BuildContext context) {
    final frame = SteadyFrame.of(context);
    final theme = context.clayTheme;
    final width = MediaQuery.sizeOf(context).width;
    final active = frame.habits.where((h) => !h.paused).toList();
    final done = active.where((h) => h.done).length;
    final groups = [
      for (final time in SteadyTime.values)
        if (active.any((h) => h.time == time))
          ClayGroup(
            header: time.label,
            children: [
              for (final h in active.where((h) => h.time == time))
                SteadyHabitRow(
                  key: ValueKey('today-${h.id}'),
                  habit: h,
                  onTick: () => frame.tick(h),
                ),
            ],
          ),
    ];
    final ring = _DayCard(done: done, of: active.length);
    final desk = width >= ClayMetrics.sidebarBreakpoint;
    final tablet = width >= ClayMetrics.railBreakpoint && !desk;
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SteadyCheckInRow(),
        for (final g in groups) ...[
          const SizedBox(height: ClaySpacing.regular),
          g,
        ],
      ],
    );
    final banner = switch (frame.sync) {
      SteadySync.synced => null,
      SteadySync.failed || SteadySync.syncing => Padding(
        padding: const EdgeInsets.only(bottom: ClaySpacing.regular),
        child: ClayBanner(
          tone: ClayBannerTone.danger,
          icon: LucideIcons.cloudOff,
          live: true,
          title: 'Sync failed',
          message:
              "Today's ticks are safe on this phone. They go up as soon as "
              'the connection is back.',
          actions: [
            frame.sync == SteadySync.syncing
                ? const ClayButton(
                    'Trying again',
                    icon: ClaySpinner(size: 18),
                    onPressed: null,
                  )
                : ClayButton(
                    'Try again',
                    icon: const Icon(LucideIcons.refreshCw),
                    onPressed: frame.retrySync,
                  ),
          ],
        ),
      ),
    };
    if (active.isEmpty) {
      // Nothing yet: what the place is for, and a way to start in reach of
      // the words (white clay: the coral key stays the chrome's, the same on
      // every page).
      return SteadyPage(
        title: 'Today',
        large: true,
        children: [
          ?banner,
          ClayCard(
            child: ClayStateView(
              state: ClayState.empty,
              icon: LucideIcons.sprout,
              title: 'No habits yet',
              message: frame.habits.isEmpty
                  ? 'Start with one small thing: a glass of water, a short '
                        'walk.'
                  : 'Every habit is paused. Start one again from Habits.',
              actions: [
                frame.habits.isEmpty
                    ? ClayButton(
                        'New habit',
                        icon: const Icon(LucideIcons.plus),
                        onPressed: () => frame.push(const SteadyEditor()),
                      )
                    : ClayButton(
                        'Go to Habits',
                        onPressed: () => frame.go(SteadyPlace.habits),
                      ),
              ],
            ),
          ),
        ],
      );
    }
    return SteadyPage(
      title: 'Today',
      large: true,
      maxWidth: desk ? 1080 : (tablet ? 880 : ClayMetrics.readingWidth),
      actions: [
        ClayIconButton(
          onPressed: () => frame.go(SteadyPlace.habits),
          icon: const Icon(LucideIcons.search),
          tooltip: 'Search habits',
        ),
      ],
      children: [
        ?banner,
        // The day under the title, on its line.
        Padding(
          padding: const EdgeInsets.only(bottom: ClaySpacing.regular),
          child: Text(
            'Thursday, 19 November',
            style: theme.textTheme.body.copyWith(
              color: theme.colors.inkSecondary,
            ),
          ),
        ),
        if (desk || tablet) ...[
          // On a tablet the day spans the top; on a desk it heads the
          // column beside the habits, both columns starting on one line.
          if (tablet) ...[ring, const SizedBox(height: ClaySpacing.small)],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Each column its own Tab group: down one, then the next.
              Expanded(flex: 3, child: FocusTraversalGroup(child: list)),
              const SizedBox(width: ClaySpacing.large),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (desk) ...[
                      ring,
                      const SizedBox(height: ClaySpacing.regular),
                    ],
                    const _WeekCard(),
                  ],
                ),
              ),
            ],
          ),
        ] else ...[
          ring,
          const SizedBox(height: ClaySpacing.small),
          list,
          const SizedBox(height: ClaySpacing.large),
          const _WeekCard(),
        ],
      ],
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.done, required this.of});

  final int done;
  final int of;

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    final left = of - done;
    // The ring beside the words; above them where a line of the words would
    // break beside it (large text on a phone).
    return ClayCard(
      child: KitBeside(
        gap: ClaySpacing.roomy,
        lead: ClayProgressRing(
          value: of == 0 ? 0 : done / of,
          size: 96,
          thickness: 12,
          semanticLabel: 'Habits done today',
          child: Text(
            '$done/$of',
            style: theme.textTheme.title.copyWith(color: c.ink),
          ),
        ),
        words: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              left == 0 ? 'All done. Rest well.' : 'Keep it steady',
              style: theme.textTheme.title.copyWith(color: c.ink),
            ),
            const SizedBox(height: ClaySpacing.tight),
            Text(
              left == 0
                  ? 'Every habit ticked today.'
                  : clayPlural(
                      context,
                      left,
                      one: '1 habit left today',
                      other: '$left habits left today',
                    ),
              style: theme.textTheme.secondary,
            ),
            const SizedBox(height: ClaySpacing.medium),
            Row(
              children: [
                Icon(LucideIcons.flame, size: 18, color: c.accentInk),
                const SizedBox(width: ClaySpacing.tight),
                Flexible(
                  child: Text(
                    '21-day best run',
                    style: theme.textTheme.secondary.copyWith(color: c.ink),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCard extends StatelessWidget {
  const _WeekCard();

  @override
  Widget build(BuildContext context) {
    final theme = context.clayTheme;
    final c = theme.colors;
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const share = [0.8, 1.0, 0.6, 0.8, 0.5, 0.0, 0.0];
    return ClayCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This week',
            style: theme.textTheme.title.copyWith(color: c.ink),
          ),
          Text('74% of habits done', style: theme.textTheme.secondary),
          const SizedBox(height: ClaySpacing.regular),
          SizedBox(
            height: 112,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (i, d) in days.indexed)
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: SteadyBar(share: share[i], today: i == 3),
                          ),
                        ),
                        const SizedBox(height: ClaySpacing.small),
                        Text(
                          d,
                          style: theme.textTheme.caption.copyWith(
                            color: i == 3 ? c.ink : c.inkSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
