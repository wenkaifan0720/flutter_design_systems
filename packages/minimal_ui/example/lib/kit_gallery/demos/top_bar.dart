/// The header band in each register the route derives, and the screen that
/// mounts it: a root's leading title with its mono meta, a pushed page's
/// back button and parent crumb, the compact title a root can pin, and a
/// pushed screen owning its footer. Each frame stands its page on a real
/// route — a root, or a page pushed over one — so the chrome is derived,
/// never drawn by hand.
library;

import 'package:flutter/material.dart';
import 'package:minimal_ui/minimal_ui.dart';
import 'package:minimal_ui/minimal_host.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

Widget kitTopBarDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Top bar & screen',
  sections: [
    kitSection(
      'Root · title with meta or a range',
      children: [
        KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          page: MinimalAppBar(
            title: 'Today',
            subtitle: 'Fri 28 Aug',
            actions: [
              MinimalIconButton(
                LucideIcons.search,
                label: 'Search',
                onPressed: () {},
              ),
              MinimalIconButton(
                LucideIcons.plus,
                label: 'New habit',
                variant: MinimalIconButtonVariant.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
        KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          page: MinimalAppBar(
            title: 'Orders',
            titleTrailing: MinimalMenu.button(
              LucideIcons.calendarDays,
              text: 'Today',
              label: 'Date range',
              items: [
                MinimalMenuItem('Today', selected: true, onPressed: () {}),
                MinimalMenuItem('Yesterday', onPressed: () {}),
                MinimalMenuItem('This week', onPressed: () {}),
              ],
            ),
            actions: [
              MinimalIconButton(
                LucideIcons.search,
                label: 'Search',
                onPressed: () {},
              ),
              MinimalIconButton(
                LucideIcons.slidersHorizontal,
                label: 'Filters',
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    ),
    kitSection(
      'Pushed · back and breadcrumb',
      children: [
        KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          pushed: true,
          page: MinimalAppBar(
            parent: 'Habits',
            subtitle: 'HAB-4',
            actions: [
              MinimalIconButton(
                LucideIcons.star,
                label: 'Favourite',
                onPressed: () {},
              ),
              MinimalIconButton(
                LucideIcons.ellipsis,
                label: 'More',
                onPressed: () {},
              ),
            ],
          ),
        ),
        const KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          pushed: true,
          page: MinimalAppBar(
            parent: 'Habits',
            title: 'Morning run',
            subtitle: 'HAB-4',
          ),
        ),
        const KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          pushed: true,
          page: MinimalAppBar(title: 'Notifications'),
        ),
        kitNote(
          'The parent crumb leads; the title is the page\'s own name, and a '
          'page that prints its heading in the body leaves it out.',
        ),
      ],
    ),
    kitSection(
      'Compact on a root',
      children: [
        const KitRouteFrame(
          height: MinimalChromeMetrics.barHeight,
          page: MinimalAppBar(
            title: 'Settings',
            subtitle: 'v2.4',
            large: false,
          ),
        ),
      ],
    ),
    kitSection(
      'Screen · pushed, with a footer',
      children: [
        KitRouteFrame(
          // Room for the footer's summary stacking over its act at the
          // largest text.
          height: 290,
          pushed: true,
          page: MinimalScaffold(
            topBar: const MinimalAppBar(parent: 'Habits', subtitle: 'HAB-4'),
            // The footer's act at its end, beside what it commits, as on
            // every footer the gallery docks.
            footer: MinimalActionBar(
              summary: '12d',
              detail: 'Streak · best 21d',
              label: 'Mark done',
              onPressed: () {},
            ),
            body: Builder(
              builder: (context) {
                final t = context.minimalTheme;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Morning run', style: t.h1),
                    const MinimalGap(MinimalSpacing.s4),
                    Text(
                      'Morning run opens with Back already in place.',
                      style: t.bodySmall.c(t.mutedForeground),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        kitNote(
          'Even a page with no bar of its own shows Back, so there is always '
          'a way out.',
        ),
      ],
    ),
  ],
);

// --- catalog specimens -------------------------------------------------------
//
// One configuration each, for the lab's Components pages (metadata.yaml
// `specimens`). The stage (kitSpecimenStage) styles and places them; a
// builder never names a style. A bar is drawn inside its whole screen on a
// real route, so the register it shows is the one the route derives.

/// A root's leading title and meta, with the bar's two actions.
Widget kitSpecimenTopBarRoot() => MinimalScaffold(
  topBar: MinimalAppBar(
    title: 'Today',
    subtitle: 'Fri 28 Aug',
    actions: [
      MinimalIconButton(LucideIcons.search, label: 'Search', onPressed: () {}),
      MinimalIconButton(
        LucideIcons.plus,
        label: 'New habit',
        variant: MinimalIconButtonVariant.primary,
        onPressed: () {},
      ),
    ],
  ),
  body: const SizedBox.shrink(),
);

/// A pushed page: the derived back button, the parent crumb and the
/// title, an overflow menu at the end.
Widget kitSpecimenTopBarPushed() => _SpecimenRoute(
  pushed: true,
  page: MinimalScaffold(
    topBar: MinimalAppBar(
      parent: 'Habits',
      title: 'Morning run',
      subtitle: 'HAB-4',
      actions: [
        MinimalMenu.button(
          LucideIcons.ellipsis,
          label: 'Habit actions',
          items: [
            MinimalMenuItem('Rename', onPressed: () {}),
            MinimalMenuItem('Archive', destructive: true, onPressed: () {}),
          ],
        ),
      ],
    ),
    body: const SizedBox.shrink(),
  ),
);

/// The compact title a root can pin, with nothing at the end.
Widget kitSpecimenTopBarCompactRoot() => const MinimalScaffold(
  topBar: MinimalAppBar(title: 'Settings', subtitle: 'v2.4', large: false),
  body: SizedBox.shrink(),
);

/// A sheet page's header: the context pill, the title and the derived
/// close, on the card over the dimmed page.
Widget kitSpecimenTopBarSheet() => _SpecimenRoute(
  sheet: true,
  page: Builder(
    builder: (context) {
      final t = context.minimalTheme;
      return MinimalScaffold(
        topBar: const MinimalAppBar(title: 'Rename habit', subtitle: 'HAB-4'),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Morning run', style: t.h1),
            const MinimalGap(MinimalSpacing.s4),
            Text(
              'The new name shows everywhere the habit does.',
              style: t.bodySmall.c(t.mutedForeground),
            ),
          ],
        ),
      );
    },
  ),
);

/// A pushed record page that owns its footer: the derived back button,
/// the body's facts, the one action docked on the bottom edge.
Widget kitSpecimenScreenPushed() => _SpecimenRoute(
  pushed: true,
  page: MinimalScaffold(
    topBar: const MinimalAppBar(parent: 'Habits', subtitle: 'HAB-4'),
    footer: MinimalButton(
      'Mark done',
      size: MinimalButtonSize.large,
      expand: true,
      onPressed: () {},
    ),
    body: Builder(
      builder: (context) {
        final t = context.minimalTheme;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Morning run', style: t.h1),
            const MinimalGap(MinimalSpacing.s4),
            Text(
              '5 km before 8, three times a week.',
              style: t.bodySmall.c(t.mutedForeground),
            ),
            const MinimalGap(MinimalSpacing.s16),
            const MinimalDescriptionList(
              properties: [
                MinimalProperty(
                  icon: LucideIcons.circleDot,
                  label: 'Status',
                  value: 'Active',
                  tone: MinimalTone.success,
                ),
                MinimalProperty(
                  icon: LucideIcons.repeat,
                  label: 'Repeats',
                  value: 'Mon, Wed, Fri',
                ),
                MinimalProperty(
                  icon: LucideIcons.bell,
                  label: 'Reminder',
                  value: '07:00',
                  mono: true,
                ),
                MinimalProperty(
                  icon: LucideIcons.flame,
                  label: 'Streak',
                  value: '12d',
                  detail: 'best 21d',
                  mono: true,
                ),
              ],
            ),
          ],
        );
      },
    ),
  ),
);

/// A body that owns the top edge: the hero runs behind the status bar.
Widget kitSpecimenScreenFullBleed() => MinimalScaffold(
  fullBleed: true,
  padding: EdgeInsets.zero,
  body: Builder(
    builder: (context) {
      final t = context.minimalTheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const MinimalMedia(
            MinimalPlaceholderImage(MinimalMediaKind.nature, 3),
            height: 340,
            radius: 0,
          ),
          Padding(
            padding: MinimalInsets.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trail loop', style: t.h1),
                const MinimalGap(MinimalSpacing.s4),
                Text(
                  '8.4 km · 210 m climb · usually 52 min',
                  style: t.mono.c(t.mutedForeground),
                ),
                const MinimalGap(MinimalSpacing.s16),
                Text(
                  'The Sunday long run: the ridge path out, the lake shore '
                  'back. Muddy after rain.',
                  style: t.body,
                ),
              ],
            ),
          ),
        ],
      );
    },
  ),
);

/// A shell-free list with the search floating over the body's foot.
Widget kitSpecimenScreenFloating() => MinimalScaffold(
  topBar: const MinimalAppBar(title: 'Library', subtitle: '128 notes'),
  padding: EdgeInsets.zero,
  // The slot is the bottom-trailing corner; the toolbar search spans the
  // page's measure inside it.
  floating: Builder(
    builder: (context) => SizedBox(
      width: MediaQuery.sizeOf(context).width - 2 * MinimalChromeMetrics.gutter,
      child: const MinimalSearchField(
        hint: 'Search notes',
        presentation: MinimalSearchPresentation.toolbar,
      ),
    ),
  ),
  body: MinimalListSection(
    children: [
      for (final (title, meta) in const [
        ('Stretching routine', '2d'),
        ('Race-day checklist', '5d'),
        ('Knee exercises', '1w'),
        ('Reading list', '2w'),
        ('Trail loop notes', '3w'),
        ('Meal prep', '1mo'),
      ])
        MinimalListTile(
          icon: LucideIcons.fileText,
          title: title,
          meta: meta,
          onTap: () {},
        ),
    ],
  ),
);

/// Stands [page] on a real route — pushed over a blank page, or raised as
/// a sheet page over one — so the chrome it wears is the route's own. The
/// routes are the navigator's initial ones, so they stand already arrived.
class _SpecimenRoute extends StatelessWidget {
  const _SpecimenRoute({
    required this.page,
    this.pushed = false,
    this.sheet = false,
  });

  final Widget page;
  final bool pushed;
  final bool sheet;

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateInitialRoutes: (navigator, _) => [
      MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()),
      if (pushed) MaterialPageRoute<void>(builder: (_) => page),
      if (sheet)
        MinimalBottomSheet.pageRoute<void>(
          context: context,
          builder: (_) => page,
        ),
    ],
  );
}
