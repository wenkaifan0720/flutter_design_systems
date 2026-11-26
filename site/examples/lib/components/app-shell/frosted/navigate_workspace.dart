import 'package:flutter/widgets.dart';
import 'package:frosted_ui/frosted_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    FrostedNavItem(FrostedGlyphs.house, 'Home'),
    FrostedNavItem(FrostedGlyphs.search, 'Search'),
  ];

  @override
  Widget build(BuildContext context) => FrostedScaffold(
    scroll: false,
    footer: FrostedNavigationBar(
      items: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
