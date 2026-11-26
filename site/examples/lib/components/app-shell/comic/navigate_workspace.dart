import 'package:flutter/widgets.dart';
import 'package:comic_ui/comic_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    ComicNavItem(label: 'Home', short: 'Home', icon: ComicGlyphs.house),
    ComicNavItem(label: 'Search', short: 'Search', icon: ComicGlyphs.search),
  ];

  @override
  Widget build(BuildContext context) => ComicScaffold(
    scroll: false,
    footer: ComicNavigationBar(
      destinations: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
