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

  @override
  Widget build(BuildContext context) => CivicAppShell.branches(
    brand: 'Workspace',
    destinations: const [
      CivicNavItem(Icons.home_outlined, 'Home'),
      CivicNavItem(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const CivicScreen(
        topBar: CivicTopBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const CivicScreen(
        topBar: CivicTopBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
