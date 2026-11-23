import 'package:material_ui/material_ui.dart';
import 'package:keycap_ui/keycap_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

/// The places, by width: a row at a phone's foot, a rail, a side column.
Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation',
  sections: [
    const _Bars(),
    ...kitSpecimens(const [
      'Breadcrumb',
      'Pagination',
      'StepProgress',
      'PageDots',
      'MenuBar',
      'Command',
    ]),
  ],
);

const _places = [
  KeycapDestination(icon: LucideIcons.house, label: 'Home'),
  KeycapDestination(icon: LucideIcons.notebookText, label: 'Notes'),
  KeycapDestination(icon: LucideIcons.folder, label: 'Folders'),
  KeycapDestination(icon: LucideIcons.settings, label: 'Settings'),
];

class _Bars extends StatefulWidget {
  const _Bars();

  @override
  State<_Bars> createState() => _BarsState();
}

class _BarsState extends State<_Bars> {
  int _at = 1;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      KitSection(
        title: 'Top bar',
        well: false,
        children: [
          KeycapAppBar(
            title: 'Garden',
            onBack: () {},
            actions: [
              KeycapIconButton(
                icon: const Icon(LucideIcons.share2),
                semanticLabel: 'Share',
                onPressed: () {},
                style: const KeycapStyle(
                  minimumSize: WidgetStatePropertyAll(
                    Size.square(KeycapAppBar.keySide),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: KeycapSpacing.extraLarge),
      KitSection(
        title: 'Places at a phone\'s foot',
        note: 'The current place a modifier key latched under its legend.',
        well: false,
        children: [
          MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: KeycapNavigationBar(
              destinations: _places,
              selectedIndex: _at,
              onDestinationSelected: (i) => setState(() => _at = i),
            ),
          ),
        ],
      ),
      const SizedBox(height: KeycapSpacing.extraLarge),
      KitSection(
        title: 'Rail and side column',
        well: false,
        children: [
          SizedBox(
            height: 340,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MediaQuery.removePadding(
                  context: context,
                  removeTop: true,
                  removeBottom: true,
                  child: KeycapNavigationRail(
                    destinations: _places,
                    selectedIndex: _at,
                    onDestinationSelected: (i) => setState(() => _at = i),
                  ),
                ),
                const SizedBox(width: KeycapSpacing.large),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: true,
                    removeBottom: true,
                    child: KeycapSideNavigation(
                      destinations: _places,
                      selectedIndex: _at,
                      onDestinationSelected: (i) => setState(() => _at = i),
                    ),
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
