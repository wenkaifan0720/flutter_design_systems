import 'package:flutter/widgets.dart';
import 'package:material_expressive_ui/material_expressive_host.dart'
    show NavTab, ExpressiveShellScaffold;
import 'package:material_expressive_ui/material_expressive_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    NavTab(icon: ExpressiveSymbols.home, label: 'Home', location: '/'),
    NavTab(
      icon: ExpressiveSymbols.search,
      label: 'Search',
      location: '/search',
    ),
  ];

  @override
  Widget build(BuildContext context) => ExpressiveShellScaffold(
    tabs: destinations,
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
