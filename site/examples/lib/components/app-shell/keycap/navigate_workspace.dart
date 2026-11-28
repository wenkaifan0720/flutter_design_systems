import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:keycap_ui/keycap_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => KeycapScaffold.branches(
    header: const Text('Workspace'),
    destinations: const [
      KeycapDestination(icon: Icons.home_outlined, label: 'Home'),
      KeycapDestination(icon: Icons.search, label: 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const KeycapScreen(body: Center(child: Text('Home page'))),
      (context) => const KeycapScreen(body: Center(child: Text('Search page'))),
    ],
  );
}
