import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => ComicAppShell.branches(
    brand: 'Workspace',
    destinations: const [
      ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
      ComicNavItem(label: 'Search', short: 'Search', icon: ComicGlyphs.search),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const ComicScaffold(body: Center(child: Text('Home page'))),
      (context) =>
          const ComicScaffold(body: Center(child: Text('Search page'))),
    ],
  );
}
