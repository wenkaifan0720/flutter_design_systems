import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:clay_ui/clay_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => ClayScaffold.branches(
    destinations: const [
      ClayDestination(icon: Icons.home_outlined, label: 'Home'),
      ClayDestination(icon: Icons.search, label: 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const ClayScreen(
        topBar: ClayTopBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const ClayScreen(
        topBar: ClayTopBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
