import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    NeumorphicNavItem(
      label: 'Home',
      short: 'Home',
      icon: NeumorphicGlyphs.house,
    ),
    NeumorphicNavItem(
      label: 'Search',
      short: 'Search',
      icon: NeumorphicGlyphs.search,
    ),
  ];

  @override
  Widget build(BuildContext context) => NeumorphicScaffold(
    scroll: false,
    rail: [
      for (var i = 0; i < destinations.length; i++)
        NeumorphicRailLink(
          label: destinations[i].label,
          selected: i == selected,
          onPressed: () => setState(() => selected = i),
        ),
    ],
    footer: NeumorphicNavigationBar(
      items: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
