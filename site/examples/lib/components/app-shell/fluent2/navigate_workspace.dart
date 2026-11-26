import 'package:flutter/widgets.dart';
import 'package:fluent2_design_ui/fluent2_design_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    Fluent2NavItem(Fluent2Icons.home, 'Home'),
    Fluent2NavItem(Fluent2Icons.search, 'Search'),
  ];

  @override
  Widget build(BuildContext context) => Fluent2Scaffold(
    scroll: false,
    footer: Fluent2NavigationBar(
      items: destinations,
      selectedIndex: selected,
      onDestinationSelected: (next) => setState(() => selected = next),
    ),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
