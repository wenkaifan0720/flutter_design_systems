import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;

  @override
  Widget build(BuildContext context) => TermScaffold.branches(
    title: 'workspace',
    destinations: const [
      TermNavigationDestination(label: 'home', glyph: '~'),
      TermNavigationDestination(label: 'search', glyph: '/'),
    ],
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    branches: [
      (context) => const TermScreen(title: 'home', body: Text('home page')),
      (context) => const TermScreen(title: 'search', body: Text('search page')),
    ],
  );
}
