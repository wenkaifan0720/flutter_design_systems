import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:gloss_ui/gloss_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => GlossAppShell(
    header: const GlossBrand('Workspace'),
    destinations: const [
      RawNavigationDestination(label: 'Home', icon: Icons.home_outlined),
      RawNavigationDestination(label: 'Search', icon: Icons.search),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const GlossScreen(
        topBar: GlossTopBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const GlossScreen(
        topBar: GlossTopBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
