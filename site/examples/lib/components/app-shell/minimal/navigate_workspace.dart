import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:minimal_ui/minimal_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => MinimalAppShell.branches(
    header: const Text('Workspace'),
    destinations: const [
      MinimalNavItem(Icons.home_outlined, 'Home'),
      MinimalNavItem(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const MinimalScaffold(
        topBar: MinimalAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const MinimalScaffold(
        topBar: MinimalAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
