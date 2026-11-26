import 'package:flutter/widgets.dart';
import 'package:terminal_ui/terminal_ui.dart';

class NavigateWorkspace extends StatefulWidget {
  const NavigateWorkspace({super.key});
  @override
  State<NavigateWorkspace> createState() => _NavigateWorkspaceState();
}

class _NavigateWorkspaceState extends State<NavigateWorkspace> {
  int selected = 0;
  static const destinations = [
    TermNavigationDestination(label: 'Home', glyph: '#'),
    TermNavigationDestination(label: 'Search', glyph: '?'),
  ];

  @override
  Widget build(BuildContext context) => TermScaffold(
    destinations: destinations,
    selectedIndex: selected,
    onDestinationSelected: (next) => setState(() => selected = next),
    body: Center(child: Text(selected == 0 ? 'Home page' : 'Search page')),
  );
}
