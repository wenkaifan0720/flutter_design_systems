// The navigation: the bar along a phone's foot, the side navigation from
// 600 wide, and the tabs.
import 'package:material_ui/material_ui.dart';
import 'package:civic_ui/civic_ui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../kit.dart';

const _places = [
  CivicNavigationDestination(icon: LucideIcons.house, label: 'Home'),
  CivicNavigationDestination(icon: LucideIcons.fileText, label: 'Applications'),
  CivicNavigationDestination(icon: LucideIcons.search, label: 'Search'),
  CivicNavigationDestination(icon: LucideIcons.circleUser, label: 'Account'),
];

Widget kitNavigationDemo(Brightness brightness) => kitScreen(
  brightness: brightness,
  title: 'Navigation & tabs',
  intro:
      'The places of a service, always named in words. The current one is '
      'in bold ink with a bar in the action colour; the rest are links.',
  sections: const [_Bar(), _Side(), _Tabs(), _Trail()],
);

/// The catalog's picture of the bar: four places, the second current.
Widget kitSpecimenNavigationBar() => CivicNavigationBar(
  destinations: _places,
  selectedIndex: 1,
  onDestinationSelected: (_) {},
);

class _Bar extends StatefulWidget {
  const _Bar();

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> {
  int _index = 1;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Navigation bar',
    caption: 'Along the foot of a phone.',
    children: [
      CivicNavigationBar(
        destinations: _places,
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
      ),
    ],
  );
}

class _Side extends StatefulWidget {
  const _Side();

  @override
  State<_Side> createState() => _SideState();
}

class _SideState extends State<_Side> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Side navigation',
    caption: 'Down the start of the page from 600 wide.',
    children: [
      SizedBox(
        height: 300,
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: CivicSideNavigation(
            destinations: _places,
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
          ),
        ),
      ),
    ],
  );
}

class _Tabs extends StatefulWidget {
  const _Tabs();

  @override
  State<_Tabs> createState() => _TabsState();
}

class _TabsState extends State<_Tabs> {
  int _index = 0;

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Tabs',
    caption: 'Views of one thing.',
    children: [
      CivicTabBar(
        tabs: const ['Details', 'Documents', 'History'],
        selectedIndex: _index,
        onTap: (i) => setState(() => _index = i),
      ),
      Text(
        const [
          'Resident permit for Zone B, sent on 3 November.',
          'Proof of address: tenancy agreement, PDF.',
          'Sent 3 November. In review 4 November.',
        ][_index],
      ),
    ],
  );
}

class _Trail extends StatelessWidget {
  const _Trail();

  @override
  Widget build(BuildContext context) => KitSection(
    title: 'Breadcrumbs',
    caption: 'Where a page sits, above its heading.',
    children: [
      CivicBreadcrumbs(
        items: [
          CivicBreadcrumb(label: 'Home', onPressed: () {}),
          CivicBreadcrumb(label: 'Parking', onPressed: () {}),
          CivicBreadcrumb(label: 'Resident permits', onPressed: () {}),
        ],
      ),
    ],
  );
}
