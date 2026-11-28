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

  @override
  Widget build(BuildContext context) => ApplianceScaffold.branches(
    header: const Text('Workspace'),
    destinations: const [
      ApplianceDestination(icon: Icons.home_outlined, label: 'Home'),
      ApplianceDestination(icon: Icons.search, label: 'Search'),
    ],
    selectedIndex: selected,
    onSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const ApplianceScreen(
        topBar: ApplianceAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const ApplianceScreen(
        topBar: ApplianceAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
