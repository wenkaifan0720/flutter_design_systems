import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:appliance_ui/appliance_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
    ApplianceDestination(icon: Icons.search, label: 'Search'),
  ];

  @override
  Widget build(BuildContext context) => ApplianceScaffold(
    destinations: destinations,
    selectedIndex: selected,
    onSelected: (next) => setState(() => selected = next),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
