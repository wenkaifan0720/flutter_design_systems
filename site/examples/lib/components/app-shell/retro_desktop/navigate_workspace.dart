import 'package:flutter/widgets.dart';
import 'package:retro_desktop_ui/retro_desktop_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
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
  ];

  @override
  Widget build(BuildContext context) => RetroDesktopScaffold(
    scroll: false,
    footer: RetroDesktopNavigationBar(
      items: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
