/// Clay's chrome: the top bar, the dock, the rail, the sidebar, tabs,
/// wayfinding, the menu bar and the command palette.
library;

import 'package:material_ui/material_ui.dart';
import 'package:clay_ui/clay_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  ClayDestination(icon: LucideIcons.sun, label: 'Today'),
  ClayDestination(icon: LucideIcons.listChecks, label: 'Habits'),
  ClayDestination(icon: LucideIcons.smile, label: 'Mood'),
  ClayDestination(icon: LucideIcons.settings, label: 'Settings'),
];

/// The navigation page.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: const [
    KitSection(
      title: 'Top bar',
      note: 'On the ground: a back ball, the place, its keys.',
      children: [_Bars()],
    ),
    KitSection(
      title: 'Tabs',
      note: 'The current tab rises as a white clay pill.',
      children: [_Tabs()],
    ),
    KitSection(
      title: 'The dock (a phone)',
      note:
          'A floating slab; the current place on a warm pill; the one key '
          'at its end.',
      children: [_Dock()],
    ),
    KitSection(
      title: 'Rail and sidebar',
      note: 'On the ground, the current place rises as white clay.',
      children: [_Side()],
    ),
    KitSection(
      title: 'The scaffold',
      note: 'Dock below 600 px, rail to 1024, sidebar beyond.',
      children: [_Frame()],
    ),
    KitSection(
      title: 'Wayfinding',
      note:
          'Where you are (crumbs), which page (numbered balls in a groove), '
          'which step (balls on a groove) and which slide (dots).',
      children: [_Wayfinding()],
    ),
    KitSection(
      title: 'A menu bar and commands',
      note:
          'Menus on a slab for a desk; a palette that finds any command as '
          'you type.',
      children: [_Commands()],
    ),
  ],
);

class _Bars extends StatelessWidget {
  const _Bars();

  @override
  // The bar on the ground as a screen shows it, its balls' shadows whole.
  Widget build(BuildContext context) => MediaQuery.removePadding(
    context: context,
    removeTop: true,
    child: ClayTopBar(
      title: 'Drink water',
      onBack: () {},
      actions: [
        ClayIconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.pencil),
          tooltip: 'Edit',
        ),
      ],
    ),
  );
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) => ClayTabBar(
    tabs: const ['Week', 'Month', 'Year'],
    selectedIndex: _tab,
    onSelected: (i) => setState(() => _tab = i),
  );
}

class _Dock extends StatefulWidget {
  const _Dock();

  @override
  State<_Dock> createState() => _DockState();
}

class _DockState extends State<_Dock> {
  int _place = 0;

  @override
  Widget build(BuildContext context) => MediaQuery.removePadding(
    context: context,
    removeBottom: true,
    child: ClayNavigationBar(
      destinations: _places,
      selectedIndex: _place,
      onSelected: (i) => setState(() => _place = i),
      action: ClayIconButton.filled(
        onPressed: () {},
        icon: const Icon(LucideIcons.plus),
        tooltip: 'Add habit',
      ),
    ),
  );
}

class _Side extends StatefulWidget {
  const _Side();

  @override
  State<_Side> createState() => _SideState();
}

class _SideState extends State<_Side> {
  int _place = 1;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 380,
    child: MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClayNavigationRail(
            destinations: _places,
            selectedIndex: _place,
            onSelected: (i) => setState(() => _place = i),
          ),
          const SizedBox(width: ClaySpacing.regular),
          Expanded(
            child: SingleChildScrollView(
              child: SizedBox(
                height: 360,
                child: ClaySidebar(
                  destinations: _places,
                  selectedIndex: _place,
                  onSelected: (i) => setState(() => _place = i),
                  header: const Text('Steady'),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Frame extends StatelessWidget {
  const _Frame();

  @override
  // A window on a phone's screen: a groove round it, nothing clipped, so the
  // dock's shadow falls whole over the ground it shares with the page.
  Widget build(BuildContext context) => DecoratedBox(
    position: DecorationPosition.foreground,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(ClayRadius.large),
      border: Border.all(
        color: ClayTheme.of(context).colors.track.withValues(alpha: 0.35),
        width: 1.5,
      ),
    ),
    child: SizedBox(
      height: 300,
      child: MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(size: const Size(390, 300), padding: EdgeInsets.zero),
        child: ClayScaffold(
          topBar: const ClayTopBar(title: 'Today'),
          destinations: _places,
          onSelected: (_) {},
          body: const Center(child: Text('A page')),
        ),
      ),
    ),
  );
}

class _Wayfinding extends StatelessWidget {
  const _Wayfinding();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      ClayBreadcrumb(
        crumbs: [
          ClayCrumb(label: 'Habits', onPressed: () {}),
          ClayCrumb(label: 'Health', onPressed: () {}),
          const ClayCrumb(label: 'Drink water'),
        ],
      ),
      const SizedBox(height: ClaySpacing.large),
      KitLive<int>(
        3,
        (context, p, set) => ClayPagination(page: p, count: 12, onChanged: set),
      ),
      const SizedBox(height: ClaySpacing.large),
      KitLive<int>(
        1,
        (context, step, set) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClayStepProgress(
              steps: const ['Habit', 'Schedule', 'Reminder'],
              current: step,
            ),
            const SizedBox(height: ClaySpacing.regular),
            Row(
              children: [
                ClayButton(
                  'Back',
                  onPressed: step > 0 ? () => set(step - 1) : null,
                ),
                const Spacer(),
                ClayButton.filled(
                  'Next',
                  onPressed: step < 2 ? () => set(step + 1) : null,
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: ClaySpacing.large),
      KitLive<int>(
        1,
        (context, i, set) => ClayPageDots(count: 4, index: i, onChanged: set),
      ),
    ],
  );
}

class _Commands extends StatelessWidget {
  const _Commands();

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      ClayMenuBar(
        menus: [
          ClayMenuBarMenu(
            label: 'Habit',
            items: [
              ClayMenuItem(
                label: 'New habit',
                icon: LucideIcons.plus,
                onPressed: () {},
              ),
              ClayMenuItem(
                label: 'Archive',
                icon: LucideIcons.archive,
                onPressed: () {},
              ),
            ],
          ),
          ClayMenuBarMenu(
            label: 'View',
            items: [
              ClayMenuItem(label: 'Show archived', onPressed: () {}),
              ClayMenuItem(label: 'Group by time of day', onPressed: () {}),
            ],
          ),
        ],
      ),
      const SizedBox(height: ClaySpacing.regular),
      SizedBox(
        height: 340,
        child: ClayCommandPalette(
          hint: 'Type a command',
          commands: [
            ClayCommand(
              label: 'New habit',
              group: 'Habits',
              icon: LucideIcons.plus,
              onPressed: () {},
            ),
            ClayCommand(
              label: 'Log a glass of water',
              group: 'Habits',
              icon: LucideIcons.glassWater,
              keywords: const ['drink'],
              onPressed: () {},
            ),
            ClayCommand(
              label: 'Check in',
              group: 'Today',
              icon: LucideIcons.smilePlus,
              onPressed: () {},
            ),
            ClayCommand(
              label: 'Settings',
              group: 'App',
              icon: LucideIcons.settings,
              onPressed: () {},
            ),
          ],
        ),
      ),
    ],
  );
}
