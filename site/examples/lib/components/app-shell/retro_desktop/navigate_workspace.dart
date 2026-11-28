import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => RetroDesktopAppShell.branches(
    brand: 'Workspace',
    destinations: const [
      RetroDesktopNavItem(
        label: 'Home',
        short: 'Home',
        icon: RetroDesktopGlyphs.folder,
      ),
      RetroDesktopNavItem(
        label: 'Search',
        short: 'Search',
        icon: RetroDesktopGlyphs.search,
      ),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const RetroDesktopScaffold(
        appBar: RetroDesktopAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const RetroDesktopScaffold(
        appBar: RetroDesktopAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
