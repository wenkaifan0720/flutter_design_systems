import 'package:flutter/widgets.dart';
import 'package:neumorphism_ui/neumorphism_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => NeumorphicAppShell(
    header: const NeumorphicBrandRow('Workspace'),
    destinations: const [
      RawNavigationDestination(label: 'Home', icon: NeumorphicGlyphs.house),
      RawNavigationDestination(label: 'Search', icon: NeumorphicGlyphs.search),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const NeumorphicScaffold(
        topBar: NeumorphicAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const NeumorphicScaffold(
        topBar: NeumorphicAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
