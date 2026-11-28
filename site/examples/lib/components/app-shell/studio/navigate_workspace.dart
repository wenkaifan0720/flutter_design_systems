import 'package:flutter/widgets.dart';
import 'package:material_ui/material_ui.dart' show Icons;
import 'package:studio_ui/studio_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => StudioAppShell.branches(
    brand: 'Workspace',
    tabs: const [
      StudioTab(Icons.home_outlined, 'Home'),
      StudioTab(Icons.search, 'Search'),
    ],
    selectedIndex: selected,
    onSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const StudioScreen(
        topBar: StudioAppBar(title: 'Home'),
        body: Center(child: Text('Home page')),
      ),
      (context) => const StudioScreen(
        topBar: StudioAppBar(title: 'Search'),
        body: Center(child: Text('Search page')),
      ),
    ],
  );
}
