import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:minimal_ui/minimal_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    MinimalNavItem(Icons.home_outlined, 'Home'),
    MinimalNavItem(Icons.search, 'Search'),
  ];

  @override
  Widget build(BuildContext context) => MinimalScaffold(
    scroll: false,
    footer: MinimalNavigationBar(
      items: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
