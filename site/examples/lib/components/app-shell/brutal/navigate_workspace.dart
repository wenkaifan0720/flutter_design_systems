import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:brutal_ui/brutal_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => BrutalAppShell.branches(
    brand: 'Workspace',
    tabs: const [
      BrutalTab(Icons.home_outlined, 'Home'),
      BrutalTab(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const BrutalScreen(body: Center(child: Text('Home page'))),
      (context) => const BrutalScreen(body: Center(child: Text('Search page'))),
    ],
  );
}
