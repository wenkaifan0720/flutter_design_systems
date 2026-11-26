import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:gloss_ui/gloss_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    GlossDestination(icon: Icons.home_outlined, label: 'Home'),
    GlossDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => GlossScaffold(
    destinations: destinations,
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
