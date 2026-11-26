import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:civic_ui/civic_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    CivicNavigationDestination(icon: Icons.home_outlined, label: 'Home'),
    CivicNavigationDestination(icon: Icons.search, label: 'Search'),
  ];
  void selectPage(int index) => setState(() => selected = index);

  @override
  Widget build(BuildContext context) => CivicScaffold(
    navigationBar: CivicNavigationBar(
      destinations: destinations,
      selectedIndex: selected,
      onDestinationSelected: selectPage,
    ),
    sideNavigation: CivicSideNavigation(
      destinations: destinations,
      selectedIndex: selected,
      onDestinationSelected: selectPage,
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
