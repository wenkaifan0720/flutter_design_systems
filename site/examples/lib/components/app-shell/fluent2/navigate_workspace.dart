import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => Fluent2AppShell.branches(
    header: const Text('Workspace'),
    destinations: const [
      Fluent2NavItem(Icons.home_outlined, 'Home'),
      Fluent2NavItem(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const Fluent2Scaffold(
        topBar: Fluent2AppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const Fluent2Scaffold(
        topBar: Fluent2AppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
