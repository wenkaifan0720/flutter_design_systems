import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => FrostedAppShell(
    header: const FrostedWordmark('Workspace'),
    destinations: const [
      RawNavigationDestination(label: 'Home', icon: FrostedGlyphs.house),
      RawNavigationDestination(label: 'Search', icon: FrostedGlyphs.search),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const FrostedScaffold(
        topBar: FrostedAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const FrostedScaffold(
        topBar: FrostedAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
