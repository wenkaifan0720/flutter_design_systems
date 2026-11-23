import 'package:material_ui/material_ui.dart';
import 'package:studio_ui/studio_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  StudioDestination(icon: Icon(LucideIcons.house), label: 'Home'),
  StudioDestination(icon: Icon(LucideIcons.libraryBig), label: 'Library'),
  StudioDestination(icon: Icon(LucideIcons.mic), label: 'Record'),
  StudioDestination(
    icon: Icon(LucideIcons.slidersHorizontal),
    label: 'Settings',
  ),
];

/// The faceplate bar, tabs, the key-bank bar, the rail and the side panel.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: [
    KitSection(
      title: 'Tabs',
      note: 'Engraved legends; the chosen one lit, a bar of light sliding under it.',
      children: [
        kitState<int>(
          0,
          (context, i, set) => StudioTabBar(
            tabs: const ['Notes', 'Chapters', 'Transcript'],
            selectedIndex: i,
            onChanged: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Key bank',
      note: 'A phone\'s places: latching keys in a recess, the chosen one in with its lamp lit.',
      children: [
        kitState<int>(
          1,
          (context, i, set) => StudioNavigationBar(
            destinations: _places,
            selectedIndex: i,
            onDestinationSelected: set,
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Rail and side panel',
      note: 'From 600 px a vertical bank; from 1024 a column of keys in a recess, the chosen one latched in and lit.',
      children: [
        // Side by side where both fit; on a phone the panel stands under
        // the rail, whole (it is 248 px wide).
        kitState<int>(
          0,
          (context, i, set) => LayoutBuilder(
            builder: (context, box) {
              final rail = StudioNavigationRail(
                destinations: _places,
                selectedIndex: i,
                onDestinationSelected: set,
              );
              final panel = StudioSideNavigation(
                destinations: _places,
                selectedIndex: i,
                onDestinationSelected: set,
                header: const Text('Roomtone'),
              );
              if (box.maxWidth >=
                  StudioNavigationRail.width +
                      StudioSpacing.regular +
                      StudioSideNavigation.width) {
                return SizedBox(
                  height: 340,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      rail,
                      const SizedBox(width: StudioSpacing.regular),
                      panel,
                    ],
                  ),
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 340, child: rail),
                  const SizedBox(height: StudioSpacing.regular),
                  SizedBox(height: 340, child: panel),
                ],
              );
            },
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Breadcrumb',
      note: 'Where you are, as legends parted by small wedges.',
      children: [
        Builder(
          builder: (context) => StudioBreadcrumb(
            crumbs: [
              StudioCrumb(
                'Library',
                onPressed: () => kitFeedback(context, 'Library'),
              ),
              StudioCrumb(
                'Night Desk',
                onPressed: () => kitFeedback(context, 'Night Desk'),
              ),
              const StudioCrumb('Episode 12'),
            ],
          ),
        ),
      ],
    ),
    KitSection(
      title: 'Pages and steps',
      note:
          'A readout between skip keys; lamps on an engraved line; page lamps.',
      children: [
        kitState<int>(
          3,
          (context, v, set) =>
              StudioPagination(page: v, pageCount: 12, onChanged: set),
        ),
        const StudioStepProgress(
          steps: ['Record', 'Edit', 'Master', 'Publish'],
          currentStep: 1,
        ),
        kitState<int>(
          1,
          (context, v, set) =>
              StudioPageDots(count: 4, index: v, onChanged: set),
        ),
      ],
    ),
    KitSection(
      title: 'Menu bar',
      note: 'Legends along a strip; each opens its list under glass.',
      children: [
        Builder(
          builder: (context) => StudioMenuBar(
            menus: [
              StudioMenuBarMenu('Episode', [
                StudioMenuItem(
                  label: 'New',
                  shortcut: 'Ctrl N',
                  onPressed: () => kitFeedback(context, 'New episode'),
                ),
                StudioMenuItem(
                  label: 'Import…',
                  onPressed: () => kitFeedback(context, 'Import'),
                ),
              ]),
              StudioMenuBarMenu('Edit', [
                StudioMenuItem(
                  label: 'Undo',
                  shortcut: 'Ctrl Z',
                  onPressed: () => kitFeedback(context, 'Undone'),
                ),
              ]),
              StudioMenuBarMenu('View', [
                StudioMenuItem(
                  label: 'Show levels',
                  onPressed: () => kitFeedback(context, 'Levels'),
                ),
              ]),
            ],
          ),
        ),
      ],
    ),
  ],
);
