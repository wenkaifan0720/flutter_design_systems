import 'package:material_ui/material_ui.dart';
import 'package:brutal_ui/brutal_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  BrutalDestination(icon: LucideIcons.house, label: 'Home'),
  BrutalDestination(icon: LucideIcons.calendarDays, label: 'Events'),
  BrutalDestination(icon: LucideIcons.ticket, label: 'Tickets'),
  BrutalDestination(icon: LucideIcons.settings, label: 'Settings'),
];

/// The chrome: the top bar with its cells, tabs, the three ways between an
/// app's places, each drawn at its width, and the ways through a long path:
/// a trail, pages, steps, dots, a menu bar and a command palette.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: const [_Navigation(), _Wayfinding()],
);

class _Navigation extends StatefulWidget {
  const _Navigation();

  @override
  State<_Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<_Navigation> {
  int _place = 1;
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.brutalTheme.colors;
    // A frame [inside] tall within its rules.
    Widget framed(double inside, Widget child) => SizedBox(
      height: inside + 2 * BrutalMetrics.borderWidth,
      child: BrutalSurface(
        face: BrutalFace(fill: c.paper, border: c.ink, foreground: c.ink),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          removeBottom: true,
          child: child,
        ),
      ),
    );
    Widget framedBar(PreferredSizeWidget bar) =>
        framed(bar.preferredSize.height, bar);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KitSection(
          title: 'Top bar',
          note: 'A back cell, the title, square action cells, each on a rule.',
          children: [
            framedBar(
              BrutalAppBar(
                title: 'Event',
                onBack: () {},
                actions: [
                  BrutalAppBarAction(
                    icon: const Icon(LucideIcons.heart),
                    semanticLabel: 'Save',
                    onPressed: () {},
                  ),
                  BrutalAppBarAction(
                    icon: const Icon(LucideIcons.share2),
                    semanticLabel: 'Share',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
            framedBar(const BrutalAppBar(title: 'Tickets', large: true)),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Tabs',
          note: 'The chosen tab stands on a heavy bar.',
          children: [
            BrutalTabBar(
              tabs: const ['Upcoming', 'Past'],
              selectedIndex: _tab,
              onTap: (i) => setState(() => _tab = i),
              expand: true,
            ),
            BrutalTabBar(
              tabs: const ['All', 'Music', 'Talks', 'Film'],
              selectedIndex: _tab.clamp(0, 3),
              onTap: (i) => setState(() => _tab = i),
              expand: false,
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Bottom bar (under 600)',
          note: 'Equal cells on rules; the chosen one filled with ink.',
          children: [
            framed(
              66,
              BrutalNavigationBar(
                destinations: _places,
                selectedIndex: _place,
                onDestinationSelected: (i) => setState(() => _place = i),
              ),
            ),
          ],
        ),
        const SizedBox(height: BrutalSpacing.extraLarge),
        KitSection(
          title: 'Rail (600 to 1024) and side list (past 1024)',
          children: [
            framed(
              416,
              Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  BrutalNavigationRail(
                    leading: Text(
                      'A',
                      style: context.brutalTheme.textTheme.title,
                    ),
                    destinations: _places,
                    selectedIndex: _place,
                    onDestinationSelected: (i) => setState(() => _place = i),
                  ),
                  Expanded(
                    child: BrutalSideNavigation(
                      header: const Text('ADMIT'),
                      destinations: _places,
                      selectedIndex: _place,
                      onDestinationSelected: (i) => setState(() => _place = i),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

const _commands = [
  BrutalCommand(
    label: 'Find an event',
    group: 'Go to',
    icon: LucideIcons.search,
    shortcut: '/',
    onPressed: _noop,
  ),
  BrutalCommand(
    label: 'Your tickets',
    group: 'Go to',
    icon: LucideIcons.ticket,
    onPressed: _noop,
  ),
  BrutalCommand(
    label: 'Settings',
    group: 'Go to',
    icon: LucideIcons.settings,
    shortcut: 'Ctrl ,',
    onPressed: _noop,
  ),
  BrutalCommand(
    label: 'Add to calendar',
    group: 'Do',
    icon: LucideIcons.calendarPlus,
    keywords: ['ics', 'remind'],
    onPressed: _noop,
  ),
  BrutalCommand(label: 'Transfer a ticket', group: 'Do', onPressed: null),
];

void _noop() {}

class _Wayfinding extends StatefulWidget {
  const _Wayfinding();

  @override
  State<_Wayfinding> createState() => _WayfindingState();
}

class _WayfindingState extends State<_Wayfinding> {
  int _page = 4;
  int _step = 1;
  int _dot = 0;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Breadcrumb',
        note: 'Links on slashes; where you are stands bold.',
        children: [
          BrutalBreadcrumb(
            crumbs: [
              BrutalCrumb('Events', onPressed: () {}),
              BrutalCrumb('Friday', onPressed: () {}),
              const BrutalCrumb('Low Tide'),
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Pages',
        note: 'Square cells on rules; the page you are on is ink.',
        children: [
          BrutalPagination(
            page: _page,
            pageCount: 12,
            onPageChanged: (p) => setState(() => _page = p),
          ),
          const BrutalPagination(page: 1, pageCount: 3, onPageChanged: null),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Steps',
        note:
            'Done steps are ink with a tick; the one you are on stands on '
            'a bar.',
        children: [
          BrutalStepProgress(
            steps: const ['Seats', 'Details', 'Pay', 'Done'],
            currentStep: _step,
          ),
          Row(
            children: [
              BrutalButton(
                'Back',
                onPressed: _step == 0 ? null : () => setState(() => _step--),
              ),
              const SizedBox(width: BrutalSpacing.small),
              BrutalButton.filled(
                'Next',
                onPressed: _step == 3 ? null : () => setState(() => _step++),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Page dots',
        note: 'Squares; the page you are on is a bar.',
        children: [
          BrutalPageDots(
            pageCount: 5,
            page: _dot,
            onPageChanged: (i) => setState(() => _dot = i),
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Menu bar',
        note:
            'A ruled bar of cells; the open one is ink, its menu under it. '
            'Arrow keys walk the bar and the menus.',
        children: [
          BrutalMenuBar(
            menus: [
              BrutalMenuBarMenu('File', [
                BrutalMenuItem(
                  label: 'New event',
                  shortcut: 'Ctrl N',
                  onPressed: () {},
                ),
                BrutalMenuItem(
                  label: 'Export',
                  icon: LucideIcons.download,
                  onPressed: () {},
                ),
              ]),
              BrutalMenuBarMenu('Edit', [
                BrutalMenuItem(
                  label: 'Duplicate',
                  shortcut: 'Ctrl D',
                  onPressed: () {},
                ),
                BrutalMenuItem(
                  label: 'Delete',
                  isDestructiveAction: true,
                  onPressed: () {},
                ),
              ]),
              BrutalMenuBarMenu('View', [
                BrutalMenuItem(label: 'Week', onPressed: () {}),
                BrutalMenuItem(label: 'Month', onPressed: () {}),
              ]),
            ],
          ),
        ],
      ),
      const SizedBox(height: BrutalSpacing.extraLarge),
      KitSection(
        title: 'Command palette',
        note:
            'Type to narrow; arrows move, Enter runs. It stands in a page '
            'or opens over one.',
        children: [
          const SizedBox(
            height: 340,
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: BrutalCommandPalette(commands: _commands),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: BrutalButton(
              'Open the palette',
              icon: const Icon(LucideIcons.command),
              onPressed: () =>
                  showBrutalCommandPalette(context, commands: _commands),
            ),
          ),
        ],
      ),
    ],
  );
}

Widget kitSpecimenAppBar() => Builder(
  builder: (context) => BrutalAppBar(
    title: 'Low Tide',
    onBack: () => kitFeedback(context, 'Back to the week.'),
    actions: [
      BrutalAppBarAction(
        icon: const Icon(LucideIcons.share2),
        semanticLabel: 'Share',
        onPressed: () => kitFeedback(context, 'Link copied.'),
      ),
      BrutalAppBarAction(
        icon: const Icon(LucideIcons.heart),
        semanticLabel: 'Save',
        onPressed: () => kitFeedback(context, 'Saved.'),
      ),
    ],
  ),
);

Widget kitSpecimenNavigationBar() => kitState(
  0,
  (context, index, change) => BrutalNavigationBar(
    destinations: _places,
    selectedIndex: index,
    onDestinationSelected: change,
  ),
);

Widget kitSpecimenNavigationRail() => kitState(
  1,
  (context, index, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(
      height: 400,
      child: BrutalNavigationRail(
        destinations: _places,
        selectedIndex: index,
        onDestinationSelected: change,
      ),
    ),
  ),
);

Widget kitSpecimenSideNavigation() => kitState(
  2,
  (context, index, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: SizedBox(
      height: 400,
      width: 280,
      child: BrutalSideNavigation(
        destinations: _places,
        selectedIndex: index,
        onDestinationSelected: change,
      ),
    ),
  ),
);

Widget kitSpecimenScaffold() => kitState(
  1,
  (context, index, change) => BrutalScaffold(
    appBar: const BrutalAppBar(title: 'Events'),
    destinations: _places,
    selectedIndex: index,
    onDestinationSelected: change,
    body: ListView(
      padding: const EdgeInsets.all(BrutalSpacing.regular),
      children: [
        const BrutalSectionHeader('This week'),
        for (final (title, place) in const [
          ('Low Tide', 'The Shed, Friday'),
          ('Paper Walls', 'Dock 4, Saturday'),
          ('Night Garden', 'Glasshouse, Saturday'),
        ])
          BrutalListTile(
            title: title,
            subtitle: place,
            showChevron: true,
            onTap: () => kitFeedback(context, '$title opens here.'),
          ),
      ],
    ),
  ),
);

Widget kitSpecimenTabBar() => kitState(
  0,
  (context, index, change) => BrutalTabBar(
    tabs: const ['Upcoming', 'Past', 'Saved'],
    selectedIndex: index,
    onTap: change,
  ),
);

Widget kitSpecimenBreadcrumb() => Builder(
  builder: (context) => BrutalBreadcrumb(
    crumbs: [
      BrutalCrumb(
        'Events',
        onPressed: () => kitFeedback(context, 'Back to events.'),
      ),
      BrutalCrumb(
        'The Shed',
        onPressed: () => kitFeedback(context, 'Back to the venue.'),
      ),
      const BrutalCrumb('Low Tide'),
    ],
  ),
);

Widget kitSpecimenPagination() => kitState(
  2,
  (context, page, change) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: BrutalPagination(page: page, pageCount: 8, onPageChanged: change),
  ),
);

Widget kitSpecimenStepProgress() => const BrutalStepProgress(
  steps: ['Seats', 'Details', 'Pay'],
  currentStep: 1,
);

Widget kitSpecimenPageDots() => kitState(
  1,
  (context, index, change) => Center(
    child: BrutalPageDots(pageCount: 4, page: index, onPageChanged: change),
  ),
);

Widget kitSpecimenMenuBar() => Builder(
  builder: (context) => BrutalMenuBar(
    menus: [
      BrutalMenuBarMenu('File', [
        BrutalMenuItem(
          label: 'New event',
          onPressed: () => kitFeedback(context, 'A new event.'),
        ),
      ]),
      BrutalMenuBarMenu('Edit', [
        BrutalMenuItem(
          label: 'Undo',
          onPressed: () => kitFeedback(context, 'Undone.'),
        ),
      ]),
      BrutalMenuBarMenu('View', [
        BrutalMenuItem(
          label: 'By week',
          onPressed: () => kitFeedback(context, 'By week.'),
        ),
      ]),
    ],
  ),
);

Widget kitSpecimenCommandPalette() => const SizedBox(
  height: 360,
  child: BrutalCommandPalette(commands: _commands),
);
