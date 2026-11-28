import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => ExpressiveAppShell.branches(
    destinations: const [
      ExpressiveNavItem(ExpressiveSymbols.home, 'Home'),
      ExpressiveNavItem(ExpressiveSymbols.search, 'Search'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const ExpressiveScaffold(
        topBar: ExpressiveAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const ExpressiveScaffold(
        topBar: ExpressiveAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
